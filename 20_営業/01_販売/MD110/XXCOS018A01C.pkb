CREATE OR REPLACE PACKAGE BODY APPS.XXCOS018A01C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2016. All rights reserved.
 *
 * Package Name     : XXCOS018A01C(body)
 * Description      : CSV�f�[�^�A�b�v���[�h�i�̔����сj
 * MD.050           : MD050_COS_018_A01_CSV�f�[�^�A�b�v���[�h�i�̔����сj
 * Version          : 1.6
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  get_upload_data        �t�@�C���A�b�v���[�hIF�擾(A-2)
 *  del_upload_data        �f�[�^�폜����(A-3)
 *  split_sales_data       �̔����уf�[�^�̍��ڕ�������(A-4)
 *  item_check             ���ڃ`�F�b�N(A-5)
 *  get_master_data        �}�X�^���̎擾����(A-6)
 *  security_check         �Z�L�����e�B�`�F�b�N����(A-7)
 *  set_sales_bp_data      �����̔����уf�[�^�ݒ菈��(A-8)
 *  set_sales_data         �̔����уf�[�^�ݒ菈��(A-9)
 *  ins_sales_bp_data      �����̔����уf�[�^�o�^����(A-10)
 *  ins_sales_data         �̔����уf�[�^�o�^����(A-11)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                         �I������(A-12)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2016/11/01    1.0   S.Niki           �V�K�쐬
 *  2016/12/19    1.1   S.Niki           E_�{�ғ�_13879�ǉ��Ή�
 *  2019/06/20    1.2   S.Kuwako         E_�{�ғ�_15472�y���ŗ��Ή�
 *  2019/07/25    1.3   N.Koyama         E_�{�ғ�_15472�y���ŗ��Ή�(��Q�Ή�)
 *  2019/11/06    1.4   Y.Ohishi         E_�{�ғ�_15850VD�ϑ��̔����уA�b�v���[�h�̌����ɂ���
 *  2021/10/27    1.5   Y.Shoji          E_�{�ғ�_17406VD�ϑ��̔����уA�b�v���[�h�̔[�i�`�[�ԍ��̃`�F�b�N�ɂ���
 *  2024/09/17    1.6   M.Akachi         E_�{�ғ�_20181�Ή�
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
  global_proc_date_err_expt         EXCEPTION;    -- �Ɩ����t�擾��O�n���h��
  global_get_profile_expt           EXCEPTION;    -- �v���t�@�C���擾��O�n���h��
  global_get_org_id_expt            EXCEPTION;    -- �݌ɑg�DID�擾��O�n���h��
  global_get_file_id_lock_expt      EXCEPTION;    -- �t�@�C��ID�̎擾�n���h��
  global_get_file_id_data_expt      EXCEPTION;    -- �t�@�C��ID�̎擾�n���h��
  global_get_f_uplod_name_expt      EXCEPTION;    -- �t�@�C���A�b�v���[�h���̂̎擾�n���h��
  global_get_f_csv_name_expt        EXCEPTION;    -- CSV�t�@�C�����̎擾�n���h��
  global_get_upload_data_expt       EXCEPTION;    -- �̔����я��f�[�^�擾�n���h��
  global_cut_sales_data_expt        EXCEPTION;    -- �t�@�C�����R�[�h���ڐ��s��v�n���h��
  global_item_check_expt            EXCEPTION;    -- ���ڃ`�F�b�N�n���h��
  global_security_check_expt        EXCEPTION;    -- �Z�L�����e�B�`�F�b�N�G���[�n���h��
  global_ins_sales_data_expt        EXCEPTION;    -- ���R�[�h�o�^��O�n���h��
  global_del_sales_data_expt        EXCEPTION;    -- ���R�[�h�폜��O�n���h��
-- Ver.1.4 ADD START
  global_get_open_period_expt       EXCEPTION;    -- �݌ɃI�[�v����v���Ԏ擾��O�n���h��
-- Ver.1.4 ADD END
--
  global_data_lock_expt             EXCEPTION;    -- �f�[�^���b�N��O
  PRAGMA EXCEPTION_INIT( global_data_lock_expt, -54 );
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  --�v���O��������
  cv_pkg_name                       CONSTANT VARCHAR2(100) := 'XXCOS018A01C';   --�p�b�P�[�W��
  --�A�v���P�[�V�����Z�k��
  cv_xxcos_appl_short_name          CONSTANT VARCHAR2(100) := 'XXCOS';          --�̕��Z�k�A�v����
  cv_xxccp_appl_short_name          CONSTANT VARCHAR2(100) := 'XXCCP';          --����
--
  --���b�Z�[�W
  cv_msg_get_f_uplod_name           CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-11293';    --�t�@�C���A�b�v���[�h���̎擾�G���[
  cv_msg_get_f_csv_name             CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-11294';    --CSV�t�@�C�����擾�G���[
  cv_msg_get_rep_h1                 CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-11289';    --�t�H�[�}�b�g�p�^�[�����b�Z�[�W
  cv_msg_get_rep_h2                 CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-11290';    --CSV�t�@�C�������b�Z�[�W
  cv_msg_process_date_err           CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00014';    --�Ɩ����t�擾�G���[
  cv_msg_get_profile_err            CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00004';    --�v���t�@�C���擾�G���[
  cv_msg_get_org_id_err             CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00091';    --�݌ɑg�DID�擾�G���[���b�Z�[�W
  cv_msg_get_data_err               CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00013';    --�f�[�^���o�G���[���b�Z�[�W
  cv_msg_get_lock_err               CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00001';    --���b�N�G���[
  cv_msg_insert_data_err            CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00010';    --�f�[�^�o�^�G���[���b�Z�[�W
  cv_msg_delete_data_err            CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00012';    --�f�[�^�폜�G���[���b�Z�[�W
  cv_msg_chk_rec_err                CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-11295';    --�t�@�C�����R�[�h�s��v�G���[���b�Z�[�W
  cv_msg_get_format_err             CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15101';    --���ڃt�H�[�}�b�g�G���[���b�Z�[�W
  cv_msg_mst_chk_err                CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15102';    --�}�X�^�`�F�b�N�G���[���b�Z�[�W
  cv_msg_dlv_date_chk_err           CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15103';    --�[�i���������t�G���[���b�Z�[�W
  cv_msg_cust_sts_err               CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15104';    --�ڋq�X�e�[�^�X�G���[���b�Z�[�W
  cv_msg_sale_base_code_err         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15105';    --�ڋq�̔��㋒�_�R�[�h�G���[���b�Z�[�W
  cv_msg_null_or_get_data_err       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15106';    --���ݒ�܂��͎擾�G���[���b�Z�[�W
  cv_msg_sales_target_chk_err       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15108';    --����Ώۋ敪�G���[���b�Z�[�W
  cv_msg_item_sts_err               CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15109';    --�i�ڃX�e�[�^�X�G���[���b�Z�[�W
  cv_msg_security_chk_err           CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15110';    --�Z�L�����e�B�`�F�b�N�G���[���b�Z�[�W
  cv_msg_req_cond_err               CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15117';    --�����t���K�{�`�F�b�N�G���[���b�Z�[�W
  cv_msg_overlap_err                CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15118';    --�d�����R�[�h�擾�G���[���b�Z�[�W
  cv_msg_bp_com_code_err            CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15120';    --�����R�[�h�G���[���b�Z�[�W
  cv_msg_get_h_count                CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-11287';    --�������b�Z�[�W
-- Ver.1.2 ADD START
  cv_msg_common_pkg_err             CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15123';    --���ʊ֐��G���[���b�Z�[�W
-- Ver.1.2 ADD END
-- Ver.1.4 ADD START
  cv_msg_get_open_period_err        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15124';    --�݌ɉ�v���ԃI�[�v�����Ԏ擾�G���[
  cv_msg_dlv_date_chk_err_2         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15125';    --�[�i���I�[�v����v���ԊO�G���[
-- Ver.1.4 ADD END
-- Ver.1.5 ADD START
  cv_msg_inv_num_multi_cust_err     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15354';    --�[�i�`�[�ԍ��E�����ڋq�`�F�b�N�G���[
-- Ver.1.5 ADD END
--
  --���b�Z�[�W�p������
  cv_msg_file_up_load               CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-11282';    --�t�@�C���A�b�v���[�hIF
  cv_msg_salse_unit                 CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00047';    --MO:�c�ƒP��
  cv_get_bks_id                     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00060';    --GL��v����ID
  cv_msg_max_date                   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00056';    --XXCOS:MAX���t
  cv_msg_org_code                   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00048';    --XXCOI:�݌ɑg�D�R�[�h
-- Ver.1.1 ADD START
  cv_msg_bp_sales_dlv_ptn_cls       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15122';    --XXCOS:�����̔����уf�[�^�쐬�p�[�i�`�ԋ敪
-- Ver.1.1 ADD END
  cv_msg_cust_mst                   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00049';    --�ڋq�}�X�^
  cv_msg_lkp_code                   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00046';    --�N�C�b�N�R�[�h
  cv_msg_base_code                  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00055';    --���_�R�[�h
  cv_msg_cd_sale_cls                CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10042';    --�J�[�h���敪
  cv_msg_employee_code              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-14360';    --�S���c�ƈ�
  cv_msg_tax_class                  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00189';    --����ŋ敪
  cv_msg_tax_view                   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00190';    --�����view
  cv_msg_tax_rate                   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10175';    --����ŗ�
  cv_msg_offset_cust_code           CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15107';    --���E�p�ڋq�R�[�h
  cv_msg_item_mst                   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00050';    --�i�ڃ}�X�^
  cv_msg_sales_head                 CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00086';    --�̔����уw�b�_
  cv_msg_sales_line                 CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00087';    --�̔����і���
  cv_msg_data_created               CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15111';    --�f�[�^�쐬����
  cv_msg_sales_bp                   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15112';    --�����̔�����
  cv_msg_cust_code                  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15113';    --�ɓ����ڋq�R�[�h
  cv_msg_bp_cust_code               CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15114';    --�����ڋq�R�[�h
  cv_msg_item_code                  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15115';    --�ɓ����i���R�[�h
  cv_msg_bp_item_code               CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15116';    --�����i���R�[�h
  cv_msg_bp_company_code            CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15119';    --�����R�[�h
  cv_msg_bp_item_mst                CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15121';    --�����i�ڃA�h�I��
--
  --�g�[�N��
  cv_tkn_file_id                    CONSTANT VARCHAR2(50)  := 'FILE_ID ';            --�t�@�C��ID
  cv_tkn_profile                    CONSTANT VARCHAR2(30)  := 'PROFILE';             --�v���t�@�C����
  cv_tkn_org_code                   CONSTANT VARCHAR2(30)  := 'ORG_CODE_TOK';        --�݌ɑg�D�R�[�h
  cv_tkn_table                      CONSTANT VARCHAR2(30)  := 'TABLE';               --�e�[�u����
  cv_tkn_key_data                   CONSTANT VARCHAR2(30)  := 'KEY_DATA';            --�L�[���
  cv_tkn_table_name                 CONSTANT VARCHAR2(30)  := 'TABLE_NAME';          --�e�[�u����
  cv_tkn_data                       CONSTANT VARCHAR2(30)  := 'DATA';                --���R�[�h�f�[�^
  cv_tkn_param1                     CONSTANT VARCHAR2(30)  := 'PARAM1';              --�p�����[�^1
  cv_tkn_param2                     CONSTANT VARCHAR2(30)  := 'PARAM2';              --�p�����[�^2
  cv_tkn_param3                     CONSTANT VARCHAR2(30)  := 'PARAM3';              --�p�����[�^3
  cv_tkn_param4                     CONSTANT VARCHAR2(30)  := 'PARAM4';              --�p�����[�^4
-- Ver.1.5 ADD START
  cv_tkn_param5                     CONSTANT VARCHAR2(30)  := 'PARAM5';              --�p�����[�^5
-- Ver.1.5 ADD END
  cv_tkn_column                     CONSTANT VARCHAR2(30)  := 'COLUMN';              --���ږ�
-- Ver.1.2 ADD START
  cv_tkn_common                     CONSTANT VARCHAR2(30)  := 'LINE_NO';             --�s�ԍ�
  cv_tkn_common_name                CONSTANT VARCHAR2(30)  := 'FUNC_NAME';           --���ʊ֐���
  cv_tkn_common_info                CONSTANT VARCHAR2(30)  := 'INFO';
-- Ver.1.2 ADD END
--
  --�v���t�@�C��
  cv_prf_org_id                     CONSTANT VARCHAR2(50)  := 'ORG_ID';                      --MO:�c�ƒP��
  cv_prf_bks_id                     CONSTANT VARCHAR2(50)  := 'GL_SET_OF_BKS_ID';            --GL��v����ID
  cv_prf_max_date                   CONSTANT VARCHAR2(50)  := 'XXCOS1_MAX_DATE';             --XXCOS:MAX���t
  cv_prf_org_code                   CONSTANT VARCHAR2(50)  := 'XXCOI1_ORGANIZATION_CODE';    --XXCOI:�݌ɑg�D�R�[�h
-- Ver.1.1 ADD START
  cv_prf_bp_sales_dlv_ptn_cls       CONSTANT VARCHAR2(50)  := 'XXCOS1_BP_SALES_DLV_PTN_CLS'; --XXCOS:�����̔����уf�[�^�쐬�p�[�i�`�ԋ敪
-- Ver.1.1 ADD END
--
  --�N�C�b�N�R�[�h
  cv_look_file_upload_obj           CONSTANT VARCHAR2(50)  := 'XXCCP1_FILE_UPLOAD_OBJ';           --�t�@�C���A�b�v���[�h�I�u�W�F�N�g
  cv_look_card_sale_class           CONSTANT VARCHAR2(50)  := 'XXCOS1_CARD_SALE_CLASS';           --�J�[�h���敪
  cv_look_cus_sts                   CONSTANT VARCHAR2(50)  := 'XXCOS1_CUS_STATUS_MST_001_A01';    --�ڋq�X�e�[�^�X
  cv_look_cus_sts_a01               CONSTANT VARCHAR2(50)  := 'XXCOS_001_A01_%';                  --�ڋq�X�e�[�^�X�F�R�[�h
  cv_look_tax_class                 CONSTANT VARCHAR2(50)  := 'XXCOS1_TAX_CLASS';                 --����ŋ敪
  cv_look_item_status               CONSTANT VARCHAR2(50)  := 'XXCOS1_ITEM_STATUS_MST_001_A01';   --�i�ڃX�e�[�^�X
  cv_look_item_sts_a01              CONSTANT VARCHAR2(50)  := 'XXCOS_001_A01_%';                  --�i�ڃX�e�[�^�X�F�R�[�h
--
  cv_comma                          CONSTANT VARCHAR2(1)   := ',';         --��؂蕶��
  cv_dobule_quote                   CONSTANT VARCHAR2(1)   := '"';         --���蕶��
  cv_line_feed                      CONSTANT VARCHAR2(1)   := CHR(10);     --���s�R�[�h
  cn_c_header                       CONSTANT NUMBER        := 15;          --�t�@�C�����ڐ�
  cn_begin_line                     CONSTANT NUMBER        := 2;           --�ŏ��̍s
  cn_line_zero                      CONSTANT NUMBER        := 0;           --0�s
  cn_item_header                    CONSTANT NUMBER        := 1;           --���ږ�
  cv_msg_comma                      CONSTANT VARCHAR2(2)   := '�A';        --���b�Z�[�W�p��؂蕶��
  ct_user_lang                      CONSTANT fnd_lookup_values.language%TYPE
                                                           := USERENV( 'LANG' );
-- Ver.1.4 ADD START
  cv_minus                          CONSTANT VARCHAR2(1)   := '-';         -- �}�C�i�X�L��
  cv_y_flag                         CONSTANT VARCHAR2(100) := 'Y';         -- �t���O�l:Y
  cn_no_1                          CONSTANT NUMBER        := 1;           -- ���l�P

-- Ver.1.4 ADD END
--
  --CSV���C�A�E�g�i���C�A�E�g�������`�j
  cn_bp_company_code                CONSTANT NUMBER        := 1;           --�����R�[�h
  cn_dlv_inv_num                    CONSTANT NUMBER        := 2;           --�[�i�`�[�ԍ�
  cn_base_code                      CONSTANT NUMBER        := 3;           --���_�R�[�h
  cn_delivery_date                  CONSTANT NUMBER        := 4;           --�[�i��
  cn_card_sale_class                CONSTANT NUMBER        := 5;           --�J�[�h���敪
  cn_cust_code                      CONSTANT NUMBER        := 6;           --�ɓ����ڋq�R�[�h
  cn_bp_cust_code                   CONSTANT NUMBER        := 7;           --�����ڋq�R�[�h
  cn_tax_class                      CONSTANT NUMBER        := 8;           --����ŋ敪
  cn_line_number                    CONSTANT NUMBER        := 9;           --���הԍ�
  cn_item_code                      CONSTANT NUMBER        := 10;          --�ɓ����i���R�[�h
  cn_bp_item_code                   CONSTANT NUMBER        := 11;          --�����i���R�[�h
  cn_dlv_qty                        CONSTANT NUMBER        := 12;          --����
  cn_unit_price                     CONSTANT NUMBER        := 13;          --���P��
  cn_cash_and_card                  CONSTANT NUMBER        := 14;          --�����E�J�[�h���p�z
  cn_data_created                   CONSTANT NUMBER        := 15;          --�f�[�^�쐬����
--
  --���ڒ��i�e���ڂ̍��ڒ����`�j
  cn_bp_company_code_length         CONSTANT NUMBER        := 9;           --�����R�[�h
  cn_dlv_inv_num_length             CONSTANT NUMBER        := 9;           --�[�i�`�[�ԍ�
  cn_base_code_length               CONSTANT NUMBER        := 4;           --���_�R�[�h
  cn_delivery_date_length           CONSTANT NUMBER        := 8;           --�[�i��
  cn_card_sale_class_length         CONSTANT NUMBER        := 1;           --�J�[�h���敪
  cn_cust_code_length               CONSTANT NUMBER        := 9;           --�ɓ����ڋq�R�[�h
  cn_bp_cust_code_length            CONSTANT NUMBER        := 15;          --�����ڋq�R�[�h
  cn_tax_class_length               CONSTANT NUMBER        := 1;           --����ŋ敪
  cn_line_number_length             CONSTANT NUMBER        := 2;           --���הԍ�
  cn_item_code_length               CONSTANT NUMBER        := 7;           --�ɓ����i���R�[�h
  cn_bp_item_code_length            CONSTANT NUMBER        := 15;          --�����i���R�[�h
-- Ver.1.6 Mod Start
--  cn_dlv_qty_length                 CONSTANT NUMBER        := 5;           --����
---- Ver.1.4 ADD START
--  cn_dlv_qty_length_minus           CONSTANT NUMBER        := 6;           --���ʁi�}�C�i�X�j
---- Ver.1.4 ADD END
  cn_dlv_qty_length                 CONSTANT NUMBER        := 6;           --����
  cn_dlv_qty_length_minus           CONSTANT NUMBER        := 7;           --���ʁi�}�C�i�X�j
-- Ver.1.6 Mod End
  cn_dlv_qty_point                  CONSTANT NUMBER        := 2;           --���ʁi�����_�ȉ��j
  cn_unit_price_length              CONSTANT NUMBER        := 7;           --���P��
  cn_cash_and_card_length           CONSTANT NUMBER        := 11;          --�����E�J�[�h���p�z
  cn_data_created_length            CONSTANT NUMBER        := 19;          --�f�[�^�쐬����
  cn_priod                          CONSTANT NUMBER        := 0;           --�����_�ȉ���0�̏ꍇ�ɃZ�b�g
--
  --�ڋq�敪
  cv_cust_class_base                CONSTANT VARCHAR2(1)   := '1';         --���_
  cv_cust_class_cust                CONSTANT VARCHAR2(2)   := '10';        --�ڋq
  cv_cust_class_user                CONSTANT VARCHAR2(2)   := '12';        --��l
--
  --����Ώۋ敪
  cv_sales_target_off               CONSTANT VARCHAR2(1)   := '0';         --����ΏۊO
--
  --���E�p�ڋq�敪
  cv_offset_cust_div_on             CONSTANT VARCHAR2(1)   := '1';         --���E�p�ڋq
--
  --�[�i�`�[�敪
  cv_dlv_inv_cls_dlv                CONSTANT VARCHAR2(1)   := '1';         --�[�i
--
  --����敪
  cv_sales_class_vd                 CONSTANT VARCHAR2(1)   := '3';         --VD����
--
  --�쐬���敪
  cv_create_cls_sls_upload          CONSTANT VARCHAR2(1)   := '0';         --CSV�f�[�^�A�b�v���[�h�i�̔����сj
--
  --����ŋ敪
  cv_tax_class_tax                  CONSTANT VARCHAR(10)   := '0';         --��ې�
  cv_tax_class_out                  CONSTANT VARCHAR(10)   := '1';         --�O��
  cv_tax_class_ins_slip             CONSTANT VARCHAR(10)   := '2';         --���Łi�`�[�ېŁj
  cv_tax_class_ins_bid              CONSTANT VARCHAR(10)   := '3';         --���Łi�P�����݁j
--
  --�[�������敪
  cv_tax_rounding_rule_up           CONSTANT VARCHAR2(10)  := 'UP';        --�؂�グ
  cv_tax_rounding_rule_down         CONSTANT VARCHAR2(10)  := 'DOWN';      --�؂�̂�
  cv_tax_rounding_rule_nearest      CONSTANT VARCHAR2(10)  := 'NEAREST';   --�l�̌ܓ�
--
  --�ڋq�i��
  cv_cust_item_def_level            CONSTANT VARCHAR2(1)   := '1';         --�ڋq�i�ځF��`���x��
  cv_inactive_flag_no               CONSTANT VARCHAR2(1)   := 'N';         --�ڋq�i�ځF�L��
--
  --���t�t�H�[�}�b�g
  cv_fmt_std                        CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';
  cv_fmt_hh24miss                   CONSTANT VARCHAR2(21)  := 'YYYY/MM/DD HH24:MI:SS';
  cv_fmt_mm                         CONSTANT VARCHAR2(2)   := 'MM';
--
  --�ԍ��t���O
  cv_red_black_flag_r               CONSTANT VARCHAR2(1)   := '0';         --��
  cv_red_black_flag_b               CONSTANT VARCHAR2(1)   := '1';         --��
--
  --�L���t���O
  cv_enabled_flag_y                 CONSTANT VARCHAR2(1)   := 'Y';         --�L��
--
  --�����σt���O
  cv_complete_flag_y                CONSTANT VARCHAR2(1)   := 'Y';         --������
  cv_complete_flag_n                CONSTANT VARCHAR2(1)   := 'N';         --������
  cv_complete_flag_s                CONSTANT VARCHAR2(1)   := 'S';         --�ΏۊO
--
  --HHT��M�t���O
  cv_hht_rcv_flag_n                 CONSTANT VARCHAR2(1)   := 'N';         --HHT��M�O
--
  --�_�~�[���z
  cn_amt_dummy                      CONSTANT NUMBER(1)     := 0;           --�_�~�[���z
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  --�̔����уf�[�^ BLOB�^
  gt_sales_data                     xxccp_common_pkg2.g_file_data_tbl;
--
  TYPE gt_var_data1                 IS TABLE OF VARCHAR(32767) INDEX BY BINARY_INTEGER;        --1�����z��
  TYPE gt_var_data2                 IS TABLE OF gt_var_data1 INDEX BY BINARY_INTEGER;          --2�����z��
  gr_sales_work_data                gt_var_data2;                                              --�����p�ϐ�
--
  TYPE g_tab_sales_head_rec         IS TABLE OF xxcos_sales_exp_headers%ROWTYPE  INDEX BY PLS_INTEGER;  --�̔����уw�b�_
  TYPE g_tab_sales_line_rec         IS TABLE OF xxcos_sales_exp_lines%ROWTYPE    INDEX BY PLS_INTEGER;  --�̔����і���
  TYPE g_tab_sales_bp_rec           IS TABLE OF xxcos_sales_bus_partners%ROWTYPE INDEX BY PLS_INTEGER;  --�����̔�����
  TYPE g_tab_login_base_info_rec    IS TABLE OF VARCHAR(10)                      INDEX BY PLS_INTEGER;  --�����_
--
  gr_sales_head_data1               g_tab_sales_head_rec;            --�̔����уw�b�_
  gr_sales_line_data1               g_tab_sales_line_rec;            --�̔����і���
  gr_sales_head_data2               g_tab_sales_head_rec;            --�̔����уw�b�_�i���E�j
  gr_sales_line_data2               g_tab_sales_line_rec;            --�̔����і��ׁi���E�j
  gr_sales_bp_data                  g_tab_sales_bp_rec;              --�����̔�����
  gr_g_login_base_info              g_tab_login_base_info_rec;       --�����_
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_upload_file_name               VARCHAR2(128);                                      --�t�@�C���A�b�v���[�h����
  gv_csv_file_name                  VARCHAR2(256);                                      --CSV�t�@�C����
  gd_process_date                   DATE;                                               --�Ɩ����t
  gt_file_id                        xxccp_mrp_file_ul_interface.file_id%TYPE;           --�t�@�C��ID
--
  --�V�[�P���X�p
  gt_sales_exp_header_id1           xxcos_sales_exp_headers.sales_exp_header_id%TYPE;   --�̔����уw�b�_ID
  gt_sales_exp_header_id2           xxcos_sales_exp_headers.sales_exp_header_id%TYPE;   --�̔����уw�b�_ID�i���E�j
  gt_sales_exp_line_id1             xxcos_sales_exp_lines.sales_exp_line_id%TYPE;       --�̔����і���ID
  gt_sales_exp_line_id2             xxcos_sales_exp_lines.sales_exp_line_id%TYPE;       --�̔����і���ID�i���E�j
  gt_dlv_invoice_number_os          xxcos_sales_exp_headers.dlv_invoice_number%TYPE;    --�����[�i�`�[�ԍ�
--
  --���z���v�p
  gt_sale_amount_sum                xxcos_sales_exp_headers.sale_amount_sum%TYPE;       --������z���v
  gt_pure_amount_sum                xxcos_sales_exp_headers.pure_amount_sum%TYPE;       --�{�̋��z���v
  gt_tax_amount_sum                 xxcos_sales_exp_headers.tax_amount_sum%TYPE;        --����ŋ��z���v
--
  --�v���t�@�C���l�i�[�p
  gv_salse_unit                     VARCHAR2(50);                --�c�ƒP��ID
  gn_bks_id                         NUMBER;                      --��v����ID
  gd_max_date                       DATE;                        --MAX���t
  gv_org_code                       VARCHAR2(50);                --�݌ɑg�D�R�[�h
  gn_org_id                         NUMBER;                      --�݌ɑg�DID
-- Ver.1.1 ADD START
  gv_prf_bp_sales_dlv_ptn_cls       VARCHAR2(50);                --�����̔����уf�[�^�쐬�p�[�i�`�ԋ敪
-- Ver.1.1 ADD END
--
  --�J�E���^������p
  gn_get_counter_data               NUMBER;                                             --�f�[�^��
  gn_hed_cnt1                       NUMBER;                                             --�w�b�_�J�E���^�[
  gn_line_cnt1                      NUMBER;                                             --���׃J�E���^�[
  gn_hed_cnt2                       NUMBER;                                             --�w�b�_�J�E���^�[
  gn_line_cnt2                      NUMBER;                                             --���׃J�E���^�[
  gn_bp_cnt                         NUMBER;                                             --�����̔����уJ�E���^�[
  gn_hed_suc_cnt                    NUMBER;                                             --�����w�b�_�J�E���^�[
  gn_line_suc_cnt                   NUMBER;                                             --�������׃J�E���^�[
  gt_bp_com_code                    xxcos_sales_bus_partners.bp_company_code%TYPE;      --������ЃR�[�h
  gt_dlv_inv_num                    xxcos_sales_bus_partners.dlv_invoice_number%TYPE;   --�[�i�`�[�ԍ�
-- Ver.1.5 ADD START
  gt_pre_dlv_inv_num                xxcos_sales_exp_headers.dlv_invoice_number%TYPE;    --�O���R�[�h�E�[�i�`�[�ԍ�
  gt_pre_customer_code              xxcos_sales_exp_headers.ship_to_customer_code%TYPE; --�O���R�[�h�E�ڋq�R�[�h
-- Ver.1.5 ADD END
-- Ver.1.4 ADD START
--
  -- �I�[�v����v���Ԋi�[�p
  gd_start_date                     DATE;                        -- �J�n��
-- Ver.1.4 ADD END
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     iv_get_format     IN  VARCHAR2  -- ���̓t�H�[�}�b�g�p�^�[��
    ,in_file_id        IN  NUMBER    -- �t�@�C��ID
    ,ov_errbuf     OUT VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode    OUT VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg     OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_key_info      VARCHAR2(5000);  --key���
    lv_max_date      VARCHAR2(5000);  --MAX���t
    lv_tab_name      VARCHAR2(500);   --�e�[�u����
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR get_login_base_cur
    IS
      SELECT lbi.base_code   AS base_code
        FROM xxcos_login_base_info_v lbi   --���O�C�����[�U���_�r���[
      ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ****************************
    -- ***  ���̓p�����[�^�o��  ***
    -- ****************************
--
    ------------------------------------
    --�t�@�C���A�b�v���[�h���̎擾
    ------------------------------------
    BEGIN
      SELECT flv.meaning    AS upload_file_name
        INTO gv_upload_file_name
        FROM fnd_lookup_types  flt    --�N�C�b�N�^�C�v
            ,fnd_application   fa     --�A�v���P�[�V����
            ,fnd_lookup_values flv    --�N�C�b�N�R�[�h
       WHERE flt.lookup_type            = flv.lookup_type
         AND fa.application_short_name  = cv_xxccp_appl_short_name
         AND flt.application_id         = fa.application_id
         AND flt.lookup_type            = cv_look_file_upload_obj
         AND flv.lookup_code            = iv_get_format
         AND flv.language               = ct_user_lang
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE global_get_f_uplod_name_expt;
    END;
--
    ------------------------------------
    --CSV�t�@�C�����擾
    ------------------------------------
    BEGIN
      SELECT xmf.file_name  AS csv_file_name
        INTO gv_csv_file_name
        FROM xxccp_mrp_file_ul_interface xmf  --�t�@�C���A�b�v���[�hIF
       WHERE xmf.file_id = in_file_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      RAISE global_get_f_csv_name_expt;
    END;
--
    ------------------------------------
    --�p�����[�^�o��
    ------------------------------------
    --�R���J�����g�v���O�������͍��ڂ̏o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                   iv_application   => cv_xxcos_appl_short_name
                  ,iv_name          => cv_msg_get_rep_h1
                  ,iv_token_name1   => cv_tkn_param1                 --�p�����[�^�P
                  ,iv_token_value1  => in_file_id                    --�t�@�C��ID
                  ,iv_token_name2   => cv_tkn_param2                 --�p�����[�^�Q
                  ,iv_token_value2  => iv_get_format                 --�t�H�[�}�b�g�p�^�[��
                 );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --�A�b�v���[�h�t�@�C�����̏o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                   iv_application   => cv_xxcos_appl_short_name
                  ,iv_name          => cv_msg_get_rep_h2
                  ,iv_token_name1   => cv_tkn_param3                 --�t�@�C���A�b�v���[�h����(���b�Z�[�W������)
                  ,iv_token_value1  => gv_upload_file_name           --�t�@�C���A�b�v���[�h����
                  ,iv_token_name2   => cv_tkn_param4                 --CSV�t�@�C����(���b�Z�[�W������)
                  ,iv_token_value2  => gv_csv_file_name              --CSV�t�@�C����
                 );
    --
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --1�s��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => NULL
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
--
    -- **********************
    -- ***  �Ɩ����t�擾  ***
    -- **********************
--
    gd_process_date := xxccp_common_pkg2.get_process_date;
    -- �Ɩ����t���擾�ł��Ȃ��ꍇ
    IF ( gd_process_date IS NULL ) THEN
      RAISE global_proc_date_err_expt;
    END IF;
--
    -- ****************************
    -- ***  �v���t�@�C���l�擾  ***
    -- ****************************
--
    ------------------------------------
    -- MO:�c�ƒP��
    ------------------------------------
    gv_salse_unit := FND_PROFILE.VALUE( cv_prf_org_id );
    -- �v���t�@�C���l���擾�ł��Ȃ��ꍇ
    IF ( gv_salse_unit IS NULL ) THEN
      --�L�[���̕ҏW����
      lv_key_info := xxccp_common_pkg.get_msg(
                       iv_application => cv_xxcos_appl_short_name
                      ,iv_name        => cv_msg_salse_unit
                     );
      RAISE global_get_profile_expt;
    END IF;
--
    ------------------------------------
    -- ��v����ID
    ------------------------------------
    gn_bks_id := TO_NUMBER( FND_PROFILE.VALUE( cv_prf_bks_id ) );
    -- �v���t�@�C���l���擾�ł��Ȃ��ꍇ
    IF ( gn_bks_id IS NULL ) THEN
      --�L�[���̕ҏW����
      lv_key_info := xxccp_common_pkg.get_msg(
                       iv_application => cv_xxcos_appl_short_name
                      ,iv_name        => cv_get_bks_id
                     );
      RAISE global_get_profile_expt;
    END IF;
--
    ------------------------------------
    -- XXCOS:MAX���t
    ------------------------------------
    lv_max_date := FND_PROFILE.VALUE( cv_prf_max_date );
    -- �v���t�@�C���l���擾�ł��Ȃ��ꍇ
    IF ( lv_max_date IS NULL ) THEN
      --�L�[���̕ҏW����
      lv_key_info := xxccp_common_pkg.get_msg(
                       iv_application => cv_xxcos_appl_short_name
                      ,iv_name        => cv_msg_max_date
                     );
      RAISE global_get_profile_expt;
    END IF;
    -- ���t�^�ɕϊ�
    gd_max_date := TO_DATE( lv_max_date, cv_fmt_std );
--
    ------------------------------------
    -- XXCOI:�݌ɑg�D�R�[�h
    ------------------------------------
    gv_org_code := FND_PROFILE.VALUE( cv_prf_org_code );
    -- �v���t�@�C���l���擾�ł��Ȃ��ꍇ
    IF ( gv_org_code IS NULL ) THEN
      --�L�[���̕ҏW����
      lv_key_info := xxccp_common_pkg.get_msg(
                       iv_application => cv_xxcos_appl_short_name
                      ,iv_name        => cv_msg_org_code
                     );
      RAISE global_get_profile_expt;
    END IF;
-- Ver.1.1 ADD START
--
    ------------------------------------
    -- XXCOS:�����̔����уf�[�^�쐬�p�[�i�`�ԋ敪
    ------------------------------------
    gv_prf_bp_sales_dlv_ptn_cls := FND_PROFILE.VALUE( cv_prf_bp_sales_dlv_ptn_cls );
    -- �v���t�@�C���l���擾�ł��Ȃ��ꍇ
    IF ( gv_prf_bp_sales_dlv_ptn_cls IS NULL ) THEN
      --�L�[���̕ҏW����
      lv_key_info := xxccp_common_pkg.get_msg(
                       iv_application => cv_xxcos_appl_short_name
                      ,iv_name        => cv_msg_bp_sales_dlv_ptn_cls
                     );
      RAISE global_get_profile_expt;
    END IF;
-- Ver.1.1 ADD END
--
    -- ************************
    -- ***  �݌ɑg�DID�擾  ***
    -- ************************
--
    gn_org_id := xxcoi_common_pkg.get_organization_id( gv_org_code );
    -- �݌ɑg�DID�擾�G���[�̏ꍇ
    IF ( gn_org_id IS NULL ) THEN
      RAISE global_get_org_id_expt;
    END IF;
--
    -- ********************
    -- ***  �����_�擾  ***
    -- ********************
--
    OPEN  get_login_base_cur;
    -- �o���N�t�F�b�`
    FETCH get_login_base_cur BULK COLLECT INTO gr_g_login_base_info;
    -- �J�[�\��CLOSE
    CLOSE get_login_base_cur;
-- Ver.1.4 ADD START
--
    -- **********************************
    -- ***  �݌ɃI�[�v����v���Ԏ擾  ***
    -- **********************************
--
    BEGIN
      SELECT  MIN(oap.period_start_date)          start_date
      INTO    gd_start_date
      FROM    org_acct_periods      oap
      WHERE   oap.open_flag       = cv_y_flag
      AND     oap.organization_id = gn_org_id
      ;
      IF ( gd_start_date IS NULL ) THEN
        RAISE global_get_open_period_expt;
      END IF;
    END;
-- Ver.1.4 ADD END
--
  EXCEPTION
--
    --*** �t�@�C���A�b�v���[�h���̎擾�n���h�� ***
    WHEN global_get_f_uplod_name_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_appl_short_name
                    ,iv_name         => cv_msg_get_f_uplod_name
                    ,iv_token_name1  => cv_tkn_key_data
                    ,iv_token_value1 => iv_get_format
                  );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
    --*** CSV�t�@�C�����擾�n���h�� ***
    WHEN global_get_f_csv_name_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_appl_short_name
                    ,iv_name         => cv_msg_get_f_csv_name
                    ,iv_token_name1  => cv_tkn_key_data
                    ,iv_token_value1 => in_file_id
                  );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** �Ɩ����t�擾��O�n���h�� ***
    WHEN global_proc_date_err_expt THEN
      ov_errmsg  :=  xxccp_common_pkg.get_msg(
                       iv_application   =>  cv_xxcos_appl_short_name
                      ,iv_name          =>  cv_msg_process_date_err
                     );
      ov_errbuf   :=  SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode  :=  cv_status_error;
--
    --*** �v���t�@�C���擾��O�n���h�� ***
    WHEN global_get_profile_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_appl_short_name
                    ,iv_name         => cv_msg_get_profile_err
                    ,iv_token_name1  => cv_tkn_profile
                    ,iv_token_value1 => lv_key_info
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
    --*** �݌ɑg�DID�擾��O�n���h�� ***
    WHEN global_get_org_id_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_appl_short_name
                    ,iv_name         => cv_msg_get_org_id_err
                    ,iv_token_name1  => cv_tkn_org_code
                    ,iv_token_value1 => gv_org_code
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
-- Ver.1.4 ADD START
--
    --*** �݌ɃI�[�v����v���Ԏ擾��O�n���h�� ***
    WHEN global_get_open_period_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_appl_short_name
                    ,iv_name         => cv_msg_get_open_period_err
                    ,iv_token_name1  => cv_prf_org_id
                    ,iv_token_value1 => gn_org_id
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
-- Ver.1.4 ADD END
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
   * Procedure Name   : get_upload_data
   * Description      : �t�@�C���A�b�v���[�hIF�擾(A-2)
   ***********************************************************************************/
   PROCEDURE get_upload_data (
     in_file_id            IN  NUMBER       -- FILE_ID
    ,on_get_counter_data   OUT NUMBER       -- �f�[�^��
    ,ov_errbuf     OUT VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode    OUT VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg     OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
   )
   IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_upload_data'; -- �v���O������
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
    lv_key_info   VARCHAR2(5000);  --key���
    lv_tab_name   VARCHAR2(500);   --�e�[�u����
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
    ------------------------------------
    -- ���b�N�擾
    ------------------------------------
    BEGIN
    --
      SELECT xmf.file_id   AS file_id
        INTO gt_file_id
        FROM xxccp_mrp_file_ul_interface xmf  --�t�@�C���A�b�v���[�hIF
       WHERE xmf.file_id = in_file_id   --�t�@�C��ID
      FOR UPDATE NOWAIT;
    --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        --�L�[���̕ҏW����
        lv_tab_name := xxccp_common_pkg.get_msg(
                         iv_application => cv_xxcos_appl_short_name
                        ,iv_name        => cv_msg_file_up_load
                       );
        RAISE global_get_file_id_data_expt;
      --*** ���b�N�擾�G���[�n���h�� ***
      WHEN global_data_lock_expt THEN
        --�L�[���̕ҏW����
        lv_tab_name := xxccp_common_pkg.get_msg(
                                 iv_application => cv_xxcos_appl_short_name
                                ,iv_name        => cv_msg_file_up_load
                               );
        RAISE global_data_lock_expt;
    END;
--
    ------------------------------------
    -- �̔����я��f�[�^�擾
    ------------------------------------
    xxccp_common_pkg2.blob_to_varchar2(
      in_file_id   => in_file_id           -- �t�@�C���h�c
     ,ov_file_data => gt_sales_data        -- �̔����я��f�[�^(�z��^)
     ,ov_errbuf    => lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode   => lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg    => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --�߂�l�`�F�b�N
    IF ( lv_retcode = cv_status_error ) THEN
      --�L�[���̕ҏW����
      lv_tab_name := xxccp_common_pkg.get_msg(
                       iv_application => cv_xxcos_appl_short_name
                      ,iv_name        => cv_msg_file_up_load
                     );
      RAISE global_get_upload_data_expt;
    END IF;
    --
    -- �̔����я��f�[�^�̎擾���ł��Ȃ��ꍇ�̃G���[�ҏW
    IF ( gt_sales_data.LAST < cn_begin_line ) THEN
      --�L�[���̕ҏW����
      lv_tab_name := xxccp_common_pkg.get_msg(
                       iv_application => cv_xxcos_appl_short_name
                      ,iv_name        => cv_msg_file_up_load
                     );
      RAISE global_get_upload_data_expt;
    END IF;
--
    ------------------------------------
    -- �f�[�^�������̎擾
    ------------------------------------
    --�f�[�^������
    on_get_counter_data := gt_sales_data.COUNT;
    gn_target_cnt       := gt_sales_data.COUNT - 1;
--
  EXCEPTION
--
    --*** �̔����я��f�[�^�擾�n���h�� ***
    WHEN global_get_upload_data_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_appl_short_name
                    ,iv_name         => cv_msg_get_data_err
                    ,iv_token_name1  => cv_tkn_table_name
                    ,iv_token_value1 => lv_tab_name
                    ,iv_token_name2  => cv_tkn_key_data
                    ,iv_token_value2 => in_file_id
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
    --*** �t�@�C��ID�擾�n���h�� ***
    WHEN global_get_file_id_data_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_appl_short_name
                    ,iv_name         => cv_msg_get_data_err
                    ,iv_token_name1  => cv_tkn_table_name
                    ,iv_token_value1 => lv_tab_name
                    ,iv_token_name2  => cv_tkn_key_data
                    ,iv_token_value2 => in_file_id
                  );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
    --*** ���b�N�擾�G���[�n���h�� ***
    WHEN global_data_lock_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_appl_short_name
                    ,iv_name         => cv_msg_get_lock_err
                    ,iv_token_name1  => cv_tkn_table
                    ,iv_token_value1 => lv_tab_name
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
  END get_upload_data;
--
  /**********************************************************************************
   * Procedure Name   : del_upload_data
   * Description      : �f�[�^�폜����(A-3)
   ***********************************************************************************/
  PROCEDURE del_upload_data(
     in_file_id    IN  NUMBER   -- 1.FILE_ID
    ,ov_errbuf     OUT VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode    OUT VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg     OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_upload_data'; -- �v���O������
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
    lv_tab_name   VARCHAR2(100);    --�e�[�u����
    lv_key_info   VARCHAR2(100);    --�L�[���
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
    -- ************************************
    -- ***  �̔����я��f�[�^�폜����  ***
    -- ************************************
--
    BEGIN
      DELETE
        FROM xxccp_mrp_file_ul_interface xmf  --�t�@�C���A�b�v���[�hIF
       WHERE xmf.file_id = in_file_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        --�L�[���̕ҏW����
        lv_tab_name := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcos_appl_short_name
                       ,iv_name         => cv_msg_file_up_load
                     );
        lv_key_info := SQLERRM;
        RAISE global_del_sales_data_expt;
    END;
--
  EXCEPTION
--
    --*** ���R�[�h�폜��O�n���h�� ***
    WHEN global_del_sales_data_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_appl_short_name
                    ,iv_name         => cv_msg_delete_data_err
                    ,iv_token_name1  => cv_tkn_table_name
                    ,iv_token_value1 => lv_tab_name
                    ,iv_token_name2  => cv_tkn_key_data
                    ,iv_token_value2 => lv_key_info
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
  END del_upload_data;
--
  /**********************************************************************************
   * Procedure Name   : split_sales_data
   * Description      : �̔����уf�[�^�̍��ڕ�������(A-4)
   ***********************************************************************************/
  PROCEDURE split_sales_data(
     in_cnt        IN  NUMBER    -- �f�[�^��
    ,ov_errbuf     OUT VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode    OUT VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg     OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'split_sales_data'; -- �v���O������
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
--
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_rec_data     VARCHAR2(32765);
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
    <<get_sales_item_loop>>
    FOR i IN 1 .. in_cnt LOOP
--
      ------------------------------------
      -- �S���ڐ��`�F�b�N
      ------------------------------------
      IF ( ( NVL( LENGTH( gt_sales_data(i) ), 0 )
           - NVL( LENGTH( REPLACE( gt_sales_data(i), cv_comma, NULL ) ), 0 ) ) <> ( cn_c_header - 1 ) )
      THEN
        --�G���[
        lv_rec_data := gt_sales_data(i);
        RAISE global_cut_sales_data_expt;
      END IF;
      --�J��������
      FOR j IN 1 .. cn_c_header LOOP
--
        ------------------------------------
        -- ���ڕ���
        ------------------------------------
        gr_sales_work_data(i)(j) := TRIM( REPLACE( xxccp_common_pkg.char_delim_partition(
                                                     iv_char     => gt_sales_data(i)
                                                    ,iv_delim    => cv_comma
                                                    ,in_part_num => j
                                          ) ,cv_dobule_quote, NULL )
                                    );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_api_expt;
        END IF;
      END LOOP;
--
    END LOOP get_sales_item_loop;
--
  EXCEPTION
--
    -- *** �t�@�C�����R�[�h���ڐ��s��v�n���h�� ***
    WHEN global_cut_sales_data_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_appl_short_name
                    ,iv_name         => cv_msg_chk_rec_err
                    ,iv_token_name1  => cv_tkn_data
                    ,iv_token_value1 => lv_rec_data
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
  END split_sales_data;
--
  /**********************************************************************************
   * Procedure Name   : item_check
   * Description      : ���ڃ`�F�b�N(A-5)
   ***********************************************************************************/
  PROCEDURE item_check(
     in_cnt                   IN  NUMBER    -- �f�[�^�J�E���^
    ,ov_bp_company_code       OUT VARCHAR2  -- �����R�[�h
    ,ov_dlv_inv_num           OUT VARCHAR2  -- �[�i�`�[�ԍ�
    ,ov_base_code             OUT VARCHAR2  -- ���_�R�[�h
    ,od_delivery_date         OUT DATE      -- �[�i��
    ,ov_card_sale_class       OUT VARCHAR2  -- �J�[�h���敪
    ,ov_customer_code         OUT VARCHAR2  -- �ɓ����ڋq�R�[�h
    ,ov_bp_customer_code      OUT VARCHAR2  -- �����ڋq�R�[�h
    ,ov_tax_class             OUT VARCHAR2  -- ����ŋ敪
    ,on_line_number           OUT NUMBER    -- ���הԍ�
    ,ov_item_code             OUT VARCHAR2  -- �ɓ����i���R�[�h
    ,ov_bp_item_code          OUT VARCHAR2  -- �����i���R�[�h
    ,on_dlv_qty               OUT NUMBER    -- ����
    ,on_unit_price            OUT NUMBER    -- ���P��
    ,on_cash_and_card         OUT NUMBER    -- �����E�J�[�h���p�z
    ,od_data_created          OUT DATE      -- �f�[�^�쐬����
    ,ov_errbuf     OUT VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode    OUT VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg     OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'item_check'; -- �v���O������
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
    lv_err_msg         VARCHAR2(32767);  --�G���[���b�Z�[�W
    ld_data_created    DATE;             --�f�[�^�쐬����
-- Ver.1.4 ADD START
    ln_dlv_qty_length  NUMBER;           --���ʍ��ڒ�
-- Ver.1.4 ADD END
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
    --������
    lv_err_msg := NULL;
--
    -- **********************
    -- ***  �����R�[�h  ***
    -- **********************
--
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_sales_work_data(cn_item_header)(cn_bp_company_code)     -- 1.���ږ���
     ,iv_item_value   => gr_sales_work_data(in_cnt)(cn_bp_company_code)             -- 2.���ڂ̒l
     ,in_item_len     => cn_bp_company_code_length                                  -- 3.���ڂ̒���
     ,in_item_decimal => cn_priod                                                   -- 4.���ڂ̒���(�����_�ȉ�)
     ,iv_item_nullflg => xxccp_common_pkg2.gv_null_ng                               -- 5.�K�{�t���O
     ,iv_item_attr    => xxccp_common_pkg2.gv_attr_num                              -- 6.���ڑ���
     ,ov_errbuf       => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode      => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg       => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    --���[�j���O
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => cv_xxcos_appl_short_name
                     ,iv_name          => cv_msg_get_format_err
                     ,iv_token_name1   => cv_tkn_param1                                             --�p�����[�^1(�g�[�N��)
                     ,iv_token_value1  => in_cnt                                                    --�s�ԍ�
                     ,iv_token_name2   => cv_tkn_param2                                             --�p�����[�^2(�g�[�N��)
                     ,iv_token_value2  => gr_sales_work_data(in_cnt)(cn_dlv_inv_num)                --�[�i�`�[�ԍ�
                     ,iv_token_name3   => cv_tkn_param3                                             --�p�����[�^3(�g�[�N��)
                     ,iv_token_value3  => gr_sales_work_data(in_cnt)(cn_line_number)                --�sNo
                     ,iv_token_name4   => cv_tkn_column                                             --���ږ�(�g�[�N��)
                     ,iv_token_value4  => gr_sales_work_data(cn_item_header)(cn_bp_company_code)    --�����R�[�h
                    ) || cv_line_feed;
    --���ʊ֐��G���[
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --����I��
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --�l��ԋp
      ov_bp_company_code := gr_sales_work_data(in_cnt)(cn_bp_company_code);
    END IF;
--
    -- **********************
    -- ***  �[�i�`�[�ԍ�  ***
    -- **********************
--
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_sales_work_data(cn_item_header)(cn_dlv_inv_num)         -- 1.���ږ���
     ,iv_item_value   => gr_sales_work_data(in_cnt)(cn_dlv_inv_num)                 -- 2.���ڂ̒l
     ,in_item_len     => cn_dlv_inv_num_length                                      -- 3.���ڂ̒���
     ,in_item_decimal => cn_priod                                                   -- 4.���ڂ̒���(�����_�ȉ�)
     ,iv_item_nullflg => xxccp_common_pkg2.gv_null_ng                               -- 5.�K�{�t���O
     ,iv_item_attr    => xxccp_common_pkg2.gv_attr_num                              -- 6.���ڑ���
     ,ov_errbuf       => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode      => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg       => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    --���[�j���O
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => cv_xxcos_appl_short_name
                     ,iv_name          => cv_msg_get_format_err
                     ,iv_token_name1   => cv_tkn_param1                                             --�p�����[�^1(�g�[�N��)
                     ,iv_token_value1  => in_cnt                                                    --�s�ԍ�
                     ,iv_token_name2   => cv_tkn_param2                                             --�p�����[�^2(�g�[�N��)
                     ,iv_token_value2  => gr_sales_work_data(in_cnt)(cn_dlv_inv_num)                --�[�i�`�[�ԍ�
                     ,iv_token_name3   => cv_tkn_param3                                             --�p�����[�^3(�g�[�N��)
                     ,iv_token_value3  => gr_sales_work_data(in_cnt)(cn_line_number)                --�sNo
                     ,iv_token_name4   => cv_tkn_column                                             --���ږ�(�g�[�N��)
                     ,iv_token_value4  => gr_sales_work_data(cn_item_header)(cn_dlv_inv_num)        --�[�i�`�[�ԍ�
                    ) || cv_line_feed;
    --���ʊ֐��G���[
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --����I��
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --�l��ԋp
      ov_dlv_inv_num := gr_sales_work_data(in_cnt)(cn_dlv_inv_num);
    END IF;
--
    -- ********************
    -- ***  ���_�R�[�h  ***
    -- ********************
--
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_sales_work_data(cn_item_header)(cn_base_code)           -- 1.���ږ���
     ,iv_item_value   => gr_sales_work_data(in_cnt)(cn_base_code)                   -- 2.���ڂ̒l
     ,in_item_len     => cn_base_code_length                                        -- 3.���ڂ̒���
     ,in_item_decimal => NULL                                                       -- 4.���ڂ̒���(�����_�ȉ�)
     ,iv_item_nullflg => xxccp_common_pkg2.gv_null_ng                               -- 5.�K�{�t���O
     ,iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2                              -- 6.���ڑ���
     ,ov_errbuf       => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode      => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg       => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    --���[�j���O
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => cv_xxcos_appl_short_name
                     ,iv_name          => cv_msg_get_format_err
                     ,iv_token_name1   => cv_tkn_param1                                             --�p�����[�^1(�g�[�N��)
                     ,iv_token_value1  => in_cnt                                                    --�s�ԍ�
                     ,iv_token_name2   => cv_tkn_param2                                             --�p�����[�^2(�g�[�N��)
                     ,iv_token_value2  => gr_sales_work_data(in_cnt)(cn_dlv_inv_num)                --�[�i�`�[�ԍ�
                     ,iv_token_name3   => cv_tkn_param3                                             --�p�����[�^3(�g�[�N��)
                     ,iv_token_value3  => gr_sales_work_data(in_cnt)(cn_line_number)                --�sNo
                     ,iv_token_name4   => cv_tkn_column                                             --���ږ�(�g�[�N��)
                     ,iv_token_value4  => gr_sales_work_data(cn_item_header)(cn_base_code)          --���_�R�[�h
                    ) || cv_line_feed;
    --���ʊ֐��G���[
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --����I��
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --�l��ԋp
      ov_base_code := gr_sales_work_data(in_cnt)(cn_base_code);
    END IF;
--
    -- ****************
    -- ***  �[�i��  ***
    -- ****************
--
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_sales_work_data(cn_item_header)(cn_delivery_date)       -- 1.���ږ���
     ,iv_item_value   => gr_sales_work_data(in_cnt)(cn_delivery_date)               -- 2.���ڂ̒l
     ,in_item_len     => cn_delivery_date_length                                    -- 3.���ڂ̒���
     ,in_item_decimal => NULL                                                       -- 4.���ڂ̒���(�����_�ȉ�)
     ,iv_item_nullflg => xxccp_common_pkg2.gv_null_ng                               -- 5.�K�{�t���O
     ,iv_item_attr    => xxccp_common_pkg2.gv_attr_dat                              -- 6.���ڑ���
     ,ov_errbuf       => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode      => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg       => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    --���[�j���O
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => cv_xxcos_appl_short_name
                     ,iv_name          => cv_msg_get_format_err
                     ,iv_token_name1   => cv_tkn_param1                                             --�p�����[�^1(�g�[�N��)
                     ,iv_token_value1  => in_cnt                                                    --�s�ԍ�
                     ,iv_token_name2   => cv_tkn_param2                                             --�p�����[�^2(�g�[�N��)
                     ,iv_token_value2  => gr_sales_work_data(in_cnt)(cn_dlv_inv_num)                --�[�i�`�[�ԍ�
                     ,iv_token_name3   => cv_tkn_param3                                             --�p�����[�^3(�g�[�N��)
                     ,iv_token_value3  => gr_sales_work_data(in_cnt)(cn_line_number)                --�sNo
                     ,iv_token_name4   => cv_tkn_column                                             --���ږ�(�g�[�N��)
                     ,iv_token_value4  => gr_sales_work_data(cn_item_header)(cn_delivery_date)      --�[�i��
                    ) || cv_line_feed;
    --���ʊ֐��G���[
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --����I��
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --�l��ԋp
      od_delivery_date := TO_DATE( gr_sales_work_data(in_cnt)(cn_delivery_date) ,cv_fmt_std );
    END IF;
--
    -- **********************
    -- ***  �J�[�h���敪  ***
    -- **********************
--
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_sales_work_data(cn_item_header)(cn_card_sale_class)     -- 1.���ږ���
     ,iv_item_value   => gr_sales_work_data(in_cnt)(cn_card_sale_class)             -- 2.���ڂ̒l
     ,in_item_len     => cn_card_sale_class_length                                  -- 3.���ڂ̒���
     ,in_item_decimal => NULL                                                       -- 4.���ڂ̒���(�����_�ȉ�)
     ,iv_item_nullflg => xxccp_common_pkg2.gv_null_ng                               -- 5.�K�{�t���O
     ,iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2                              -- 6.���ڑ���
     ,ov_errbuf       => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode      => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg       => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    --���[�j���O
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => cv_xxcos_appl_short_name
                     ,iv_name          => cv_msg_get_format_err
                     ,iv_token_name1   => cv_tkn_param1                                             --�p�����[�^1(�g�[�N��)
                     ,iv_token_value1  => in_cnt                                                    --�s�ԍ�
                     ,iv_token_name2   => cv_tkn_param2                                             --�p�����[�^2(�g�[�N��)
                     ,iv_token_value2  => gr_sales_work_data(in_cnt)(cn_dlv_inv_num)                --�[�i�`�[�ԍ�
                     ,iv_token_name3   => cv_tkn_param3                                             --�p�����[�^3(�g�[�N��)
                     ,iv_token_value3  => gr_sales_work_data(in_cnt)(cn_line_number)                --�sNo
                     ,iv_token_name4   => cv_tkn_column                                             --���ږ�(�g�[�N��)
                     ,iv_token_value4  => gr_sales_work_data(cn_item_header)(cn_card_sale_class)    --�J�[�h���敪
                    ) || cv_line_feed;
    --���ʊ֐��G���[
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --����I��
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --�l��ԋp
      ov_card_sale_class := gr_sales_work_data(in_cnt)(cn_card_sale_class);
    END IF;
--
    -- **************************
    -- ***  �ɓ����ڋq�R�[�h  ***
    -- **************************
--
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_sales_work_data(cn_item_header)(cn_cust_code)           -- 1.���ږ���
     ,iv_item_value   => gr_sales_work_data(in_cnt)(cn_cust_code)                   -- 2.���ڂ̒l
     ,in_item_len     => cn_cust_code_length                                        -- 3.���ڂ̒���
     ,in_item_decimal => NULL                                                       -- 4.���ڂ̒���(�����_�ȉ�)
     ,iv_item_nullflg => xxccp_common_pkg2.gv_null_ok                               -- 5.�K�{�t���O
     ,iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2                              -- 6.���ڑ���
     ,ov_errbuf       => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode      => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg       => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    --���[�j���O
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => cv_xxcos_appl_short_name
                     ,iv_name          => cv_msg_get_format_err
                     ,iv_token_name1   => cv_tkn_param1                                             --�p�����[�^1(�g�[�N��)
                     ,iv_token_value1  => in_cnt                                                    --�s�ԍ�
                     ,iv_token_name2   => cv_tkn_param2                                             --�p�����[�^2(�g�[�N��)
                     ,iv_token_value2  => gr_sales_work_data(in_cnt)(cn_dlv_inv_num)                --�[�i�`�[�ԍ�
                     ,iv_token_name3   => cv_tkn_param3                                             --�p�����[�^3(�g�[�N��)
                     ,iv_token_value3  => gr_sales_work_data(in_cnt)(cn_line_number)                --�sNo
                     ,iv_token_name4   => cv_tkn_column                                             --���ږ�(�g�[�N��)
                     ,iv_token_value4  => gr_sales_work_data(cn_item_header)(cn_cust_code)          --�ɓ����ڋq�R�[�h
                    ) || cv_line_feed;
    --���ʊ֐��G���[
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --����I��
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --�l��ԋp
      ov_customer_code := gr_sales_work_data(in_cnt)(cn_cust_code);
    END IF;
--
    -- **************************
    -- ***  �����ڋq�R�[�h  ***
    -- **************************
--
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_sales_work_data(cn_item_header)(cn_bp_cust_code)        -- 1.���ږ���
     ,iv_item_value   => gr_sales_work_data(in_cnt)(cn_bp_cust_code)                -- 2.���ڂ̒l
     ,in_item_len     => cn_bp_cust_code_length                                     -- 3.���ڂ̒���
     ,in_item_decimal => NULL                                                       -- 4.���ڂ̒���(�����_�ȉ�)
     ,iv_item_nullflg => xxccp_common_pkg2.gv_null_ok                               -- 5.�K�{�t���O
     ,iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2                              -- 6.���ڑ���
     ,ov_errbuf       => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode      => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg       => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    --���[�j���O
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => cv_xxcos_appl_short_name
                     ,iv_name          => cv_msg_get_format_err
                     ,iv_token_name1   => cv_tkn_param1                                             --�p�����[�^1(�g�[�N��)
                     ,iv_token_value1  => in_cnt                                                    --�s�ԍ�
                     ,iv_token_name2   => cv_tkn_param2                                             --�p�����[�^2(�g�[�N��)
                     ,iv_token_value2  => gr_sales_work_data(in_cnt)(cn_dlv_inv_num)                --�[�i�`�[�ԍ�
                     ,iv_token_name3   => cv_tkn_param3                                             --�p�����[�^3(�g�[�N��)
                     ,iv_token_value3  => gr_sales_work_data(in_cnt)(cn_line_number)                --�sNo
                     ,iv_token_name4   => cv_tkn_column                                             --���ږ�(�g�[�N��)
                     ,iv_token_value4  => gr_sales_work_data(cn_item_header)(cn_bp_cust_code)       --�����ڋq�R�[�h
                    ) || cv_line_feed;
    --���ʊ֐��G���[
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --����I��
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --�l��ԋp
      ov_bp_customer_code:= gr_sales_work_data(in_cnt)(cn_bp_cust_code);
    END IF;
--
    -- ********************
    -- ***  ����ŋ敪  ***
    -- ********************
--
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_sales_work_data(cn_item_header)(cn_tax_class)           -- 1.���ږ���
     ,iv_item_value   => gr_sales_work_data(in_cnt)(cn_tax_class)                   -- 2.���ڂ̒l
     ,in_item_len     => cn_tax_class_length                                        -- 3.���ڂ̒���
     ,in_item_decimal => NULL                                                       -- 4.���ڂ̒���(�����_�ȉ�)
     ,iv_item_nullflg => xxccp_common_pkg2.gv_null_ng                               -- 5.�K�{�t���O
     ,iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2                              -- 6.���ڑ���
     ,ov_errbuf       => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode      => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg       => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    --���[�j���O
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => cv_xxcos_appl_short_name
                     ,iv_name          => cv_msg_get_format_err
                     ,iv_token_name1   => cv_tkn_param1                                             --�p�����[�^1(�g�[�N��)
                     ,iv_token_value1  => in_cnt                                                    --�s�ԍ�
                     ,iv_token_name2   => cv_tkn_param2                                             --�p�����[�^2(�g�[�N��)
                     ,iv_token_value2  => gr_sales_work_data(in_cnt)(cn_dlv_inv_num)                --�[�i�`�[�ԍ�
                     ,iv_token_name3   => cv_tkn_param3                                             --�p�����[�^3(�g�[�N��)
                     ,iv_token_value3  => gr_sales_work_data(in_cnt)(cn_line_number)                --�sNo
                     ,iv_token_name4   => cv_tkn_column                                             --���ږ�(�g�[�N��)
                     ,iv_token_value4  => gr_sales_work_data(cn_item_header)(cn_tax_class)          --����ŋ敪
                    ) || cv_line_feed;
    --���ʊ֐��G���[
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --����I��
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --�l��ԋp
      ov_tax_class := gr_sales_work_data(in_cnt)(cn_tax_class);
    END IF;
--
    -- ******************
    -- ***  ���הԍ�  ***
    -- ******************
--
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_sales_work_data(cn_item_header)(cn_line_number)         -- 1.���ږ���
     ,iv_item_value   => gr_sales_work_data(in_cnt)(cn_line_number)                 -- 2.���ڂ̒l
     ,in_item_len     => cn_line_number_length                                      -- 3.���ڂ̒���
     ,in_item_decimal => cn_priod                                                   -- 4.���ڂ̒���(�����_�ȉ�)
     ,iv_item_nullflg => xxccp_common_pkg2.gv_null_ng                               -- 5.�K�{�t���O
     ,iv_item_attr    => xxccp_common_pkg2.gv_attr_num                              -- 6.���ڑ���
     ,ov_errbuf       => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode      => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg       => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    --���[�j���O
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => cv_xxcos_appl_short_name
                     ,iv_name          => cv_msg_get_format_err
                     ,iv_token_name1   => cv_tkn_param1                                             --�p�����[�^1(�g�[�N��)
                     ,iv_token_value1  => in_cnt                                                    --�s�ԍ�
                     ,iv_token_name2   => cv_tkn_param2                                             --�p�����[�^2(�g�[�N��)
                     ,iv_token_value2  => gr_sales_work_data(in_cnt)(cn_dlv_inv_num)                --�[�i�`�[�ԍ�
                     ,iv_token_name3   => cv_tkn_param3                                             --�p�����[�^3(�g�[�N��)
                     ,iv_token_value3  => gr_sales_work_data(in_cnt)(cn_line_number)                --�sNo
                     ,iv_token_name4   => cv_tkn_column                                             --���ږ�(�g�[�N��)
                     ,iv_token_value4  => gr_sales_work_data(cn_item_header)(cn_line_number)        --���הԍ�
                    ) || cv_line_feed;
    --���ʊ֐��G���[
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --����I��
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --�l��ԋp
      on_line_number := gr_sales_work_data(in_cnt)(cn_line_number);
    END IF;
--
    -- **************************
    -- ***  �ɓ����i���R�[�h  ***
    -- **************************
--
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_sales_work_data(cn_item_header)(cn_item_code)           -- 1.���ږ���
     ,iv_item_value   => gr_sales_work_data(in_cnt)(cn_item_code)                   -- 2.���ڂ̒l
     ,in_item_len     => cn_item_code_length                                        -- 3.���ڂ̒���
     ,in_item_decimal => NULL                                                       -- 4.���ڂ̒���(�����_�ȉ�)
     ,iv_item_nullflg => xxccp_common_pkg2.gv_null_ok                               -- 5.�K�{�t���O
     ,iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2                              -- 6.���ڑ���
     ,ov_errbuf       => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode      => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg       => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    --���[�j���O
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => cv_xxcos_appl_short_name
                     ,iv_name          => cv_msg_get_format_err
                     ,iv_token_name1   => cv_tkn_param1                                             --�p�����[�^1(�g�[�N��)
                     ,iv_token_value1  => in_cnt                                                    --�s�ԍ�
                     ,iv_token_name2   => cv_tkn_param2                                             --�p�����[�^2(�g�[�N��)
                     ,iv_token_value2  => gr_sales_work_data(in_cnt)(cn_dlv_inv_num)                --�[�i�`�[�ԍ�
                     ,iv_token_name3   => cv_tkn_param3                                             --�p�����[�^3(�g�[�N��)
                     ,iv_token_value3  => gr_sales_work_data(in_cnt)(cn_line_number)                --�sNo
                     ,iv_token_name4   => cv_tkn_column                                             --���ږ�(�g�[�N��)
                     ,iv_token_value4  => gr_sales_work_data(cn_item_header)(cn_item_code)          --�ɓ����i���R�[�h
                    ) || cv_line_feed;
    --���ʊ֐��G���[
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --����I��
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --�l��ԋp
      ov_item_code := gr_sales_work_data(in_cnt)(cn_item_code);
    END IF;
--
    -- **************************
    -- ***  �����i���R�[�h  ***
    -- **************************
--
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_sales_work_data(cn_item_header)(cn_bp_item_code)        -- 1.���ږ���
     ,iv_item_value   => gr_sales_work_data(in_cnt)(cn_bp_item_code)                -- 2.���ڂ̒l
     ,in_item_len     => cn_bp_cust_code_length                                     -- 3.���ڂ̒���
     ,in_item_decimal => NULL                                                       -- 4.���ڂ̒���(�����_�ȉ�)
     ,iv_item_nullflg => xxccp_common_pkg2.gv_null_ok                               -- 5.�K�{�t���O
     ,iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2                              -- 6.���ڑ���
     ,ov_errbuf       => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode      => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg       => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    --���[�j���O
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => cv_xxcos_appl_short_name
                     ,iv_name          => cv_msg_get_format_err
                     ,iv_token_name1   => cv_tkn_param1                                             --�p�����[�^1(�g�[�N��)
                     ,iv_token_value1  => in_cnt                                                    --�s�ԍ�
                     ,iv_token_name2   => cv_tkn_param2                                             --�p�����[�^2(�g�[�N��)
                     ,iv_token_value2  => gr_sales_work_data(in_cnt)(cn_dlv_inv_num)                --�[�i�`�[�ԍ�
                     ,iv_token_name3   => cv_tkn_param3                                             --�p�����[�^3(�g�[�N��)
                     ,iv_token_value3  => gr_sales_work_data(in_cnt)(cn_line_number)                --�sNo
                     ,iv_token_name4   => cv_tkn_column                                             --���ږ�(�g�[�N��)
                     ,iv_token_value4  => gr_sales_work_data(cn_item_header)(cn_bp_item_code)       --�����i���R�[�h
                    ) || cv_line_feed;
    --���ʊ֐��G���[
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --����I��
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --�l��ԋp
      ov_bp_item_code := gr_sales_work_data(in_cnt)(cn_bp_item_code);
    END IF;
--
    -- **************
    -- ***  ����  ***
    -- **************
--
-- Ver.1.4 ADD START
    IF ( SUBSTR(gr_sales_work_data(in_cnt)(cn_dlv_qty),cn_no_1,cn_no_1) = cv_minus ) THEN
      ln_dlv_qty_length := cn_dlv_qty_length_minus;
    ELSE
      ln_dlv_qty_length := cn_dlv_qty_length;
    END IF;
--
-- Ver.1.4 ADD END
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_sales_work_data(cn_item_header)(cn_dlv_qty)             -- 1.���ږ���
     ,iv_item_value   => gr_sales_work_data(in_cnt)(cn_dlv_qty)                     -- 2.���ڂ̒l
-- Ver.1.4 MOD START
--     ,in_item_len     => cn_dlv_qty_length                                          -- 3.���ڂ̒���
     ,in_item_len     => ln_dlv_qty_length                                          -- 3.���ڂ̒���
-- Ver.1.4 MOD END
     ,in_item_decimal => cn_dlv_qty_point                                           -- 4.���ڂ̒���(�����_�ȉ�)
     ,iv_item_nullflg => xxccp_common_pkg2.gv_null_ng                               -- 5.�K�{�t���O
     ,iv_item_attr    => xxccp_common_pkg2.gv_attr_num                              -- 6.���ڑ���
     ,ov_errbuf       => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode      => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg       => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    --���[�j���O
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => cv_xxcos_appl_short_name
                     ,iv_name          => cv_msg_get_format_err
                     ,iv_token_name1   => cv_tkn_param1                                             --�p�����[�^1(�g�[�N��)
                     ,iv_token_value1  => in_cnt                                                    --�s�ԍ�
                     ,iv_token_name2   => cv_tkn_param2                                             --�p�����[�^2(�g�[�N��)
                     ,iv_token_value2  => gr_sales_work_data(in_cnt)(cn_dlv_inv_num)                --�[�i�`�[�ԍ�
                     ,iv_token_name3   => cv_tkn_param3                                             --�p�����[�^3(�g�[�N��)
                     ,iv_token_value3  => gr_sales_work_data(in_cnt)(cn_line_number)                --�sNo
                     ,iv_token_name4   => cv_tkn_column                                             --���ږ�(�g�[�N��)
                     ,iv_token_value4  => gr_sales_work_data(cn_item_header)(cn_dlv_qty)            --����
                    ) || cv_line_feed;
    --���ʊ֐��G���[
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --����I��
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --�l��ԋp
      on_dlv_qty := gr_sales_work_data(in_cnt)(cn_dlv_qty);
    END IF;
--
    -- ****************
    -- ***  ���P��  ***
    -- ****************
--
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_sales_work_data(cn_item_header)(cn_unit_price)          -- 1.���ږ���
     ,iv_item_value   => gr_sales_work_data(in_cnt)(cn_unit_price)                  -- 2.���ڂ̒l
     ,in_item_len     => cn_unit_price_length                                       -- 3.���ڂ̒���
     ,in_item_decimal => cn_priod                                                   -- 4.���ڂ̒���(�����_�ȉ�)
     ,iv_item_nullflg => xxccp_common_pkg2.gv_null_ng                               -- 5.�K�{�t���O
     ,iv_item_attr    => xxccp_common_pkg2.gv_attr_num                              -- 6.���ڑ���
     ,ov_errbuf       => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode      => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg       => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    --���[�j���O
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => cv_xxcos_appl_short_name
                     ,iv_name          => cv_msg_get_format_err
                     ,iv_token_name1   => cv_tkn_param1                                             --�p�����[�^1(�g�[�N��)
                     ,iv_token_value1  => in_cnt                                                    --�s�ԍ�
                     ,iv_token_name2   => cv_tkn_param2                                             --�p�����[�^2(�g�[�N��)
                     ,iv_token_value2  => gr_sales_work_data(in_cnt)(cn_dlv_inv_num)                --�[�i�`�[�ԍ�
                     ,iv_token_name3   => cv_tkn_param3                                             --�p�����[�^3(�g�[�N��)
                     ,iv_token_value3  => gr_sales_work_data(in_cnt)(cn_line_number)                --�sNo
                     ,iv_token_name4   => cv_tkn_column                                             --���ږ�(�g�[�N��)
                     ,iv_token_value4  => gr_sales_work_data(cn_item_header)(cn_unit_price)         --���P��
                    ) || cv_line_feed;
    --���ʊ֐��G���[
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --����I��
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --�l��ԋp
      on_unit_price := gr_sales_work_data(in_cnt)(cn_unit_price);
    END IF;
--
    -- ****************************
    -- ***  �����E�J�[�h���p�z  ***
    -- ****************************
--
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_sales_work_data(cn_item_header)(cn_cash_and_card)       -- 1.���ږ���
     ,iv_item_value   => gr_sales_work_data(in_cnt)(cn_cash_and_card)               -- 2.���ڂ̒l
     ,in_item_len     => cn_cash_and_card_length                                    -- 3.���ڂ̒���
     ,in_item_decimal => cn_priod                                                   -- 4.���ڂ̒���(�����_�ȉ�)
     ,iv_item_nullflg => xxccp_common_pkg2.gv_null_ng                               -- 5.�K�{�t���O
     ,iv_item_attr    => xxccp_common_pkg2.gv_attr_num                              -- 6.���ڑ���
     ,ov_errbuf       => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode      => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg       => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    --���[�j���O
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => cv_xxcos_appl_short_name
                     ,iv_name          => cv_msg_get_format_err
                     ,iv_token_name1   => cv_tkn_param1                                             --�p�����[�^1(�g�[�N��)
                     ,iv_token_value1  => in_cnt                                                    --�s�ԍ�
                     ,iv_token_name2   => cv_tkn_param2                                             --�p�����[�^2(�g�[�N��)
                     ,iv_token_value2  => gr_sales_work_data(in_cnt)(cn_dlv_inv_num)                --�[�i�`�[�ԍ�
                     ,iv_token_name3   => cv_tkn_param3                                             --�p�����[�^3(�g�[�N��)
                     ,iv_token_value3  => gr_sales_work_data(in_cnt)(cn_line_number)                --�sNo
                     ,iv_token_name4   => cv_tkn_column                                             --���ږ�(�g�[�N��)
                     ,iv_token_value4  => gr_sales_work_data(cn_item_header)(cn_cash_and_card)      --�����E�J�[�h���p�z
                    ) || cv_line_feed;
    --���ʊ֐��G���[
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --����I��
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --�l��ԋp
      on_cash_and_card := gr_sales_work_data(in_cnt)(cn_cash_and_card);
    END IF;
--
    -- ************************
    -- ***  �f�[�^�쐬����  ***
    -- ************************
--
    IF ( gr_sales_work_data(in_cnt)(cn_data_created) IS NULL ) THEN
      --NULL�̏ꍇ�G���[
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => cv_xxcos_appl_short_name
                     ,iv_name          => cv_msg_get_format_err
                     ,iv_token_name1   => cv_tkn_param1                                             --�p�����[�^1(�g�[�N��)
                     ,iv_token_value1  => in_cnt                                                    --�s�ԍ�
                     ,iv_token_name2   => cv_tkn_param2                                             --�p�����[�^2(�g�[�N��)
                     ,iv_token_value2  => gr_sales_work_data(in_cnt)(cn_dlv_inv_num)                --�[�i�`�[�ԍ�
                     ,iv_token_name3   => cv_tkn_param3                                             --�p�����[�^3(�g�[�N��)
                     ,iv_token_value3  => gr_sales_work_data(in_cnt)(cn_line_number)                --�sNo
                     ,iv_token_name4   => cv_tkn_column                                             --���ږ�(�g�[�N��)
                     ,iv_token_value4  => gr_sales_work_data(cn_item_header)(cn_data_created)       --�f�[�^�쐬����
                    ) || cv_line_feed;
    ELSE
      --���t�^�ȊO�̏ꍇ�G���[
      BEGIN
        ld_data_created := TO_DATE( gr_sales_work_data(in_cnt)(cn_data_created) ,cv_fmt_hh24miss );
        --�l��ԋp
        od_data_created := ld_data_created;
      EXCEPTION
        -- *** ���ڃ`�F�b�N�G���[�n���h�� ***
        WHEN OTHERS THEN
          lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                          iv_application   => cv_xxcos_appl_short_name
                         ,iv_name          => cv_msg_get_format_err
                         ,iv_token_name1   => cv_tkn_param1                                             --�p�����[�^1(�g�[�N��)
                         ,iv_token_value1  => in_cnt                                                    --�s�ԍ�
                         ,iv_token_name2   => cv_tkn_param2                                             --�p�����[�^2(�g�[�N��)
                         ,iv_token_value2  => gr_sales_work_data(in_cnt)(cn_dlv_inv_num)                --�[�i�`�[�ԍ�
                         ,iv_token_name3   => cv_tkn_param3                                             --�p�����[�^3(�g�[�N��)
                         ,iv_token_value3  => gr_sales_work_data(in_cnt)(cn_line_number)                --�sNo
                         ,iv_token_name4   => cv_tkn_column                                             --���ږ�(�g�[�N��)
                         ,iv_token_value4  => gr_sales_work_data(cn_item_header)(cn_data_created)       --�f�[�^�쐬����
                        ) || cv_line_feed;
      END;
    END IF;
--
    --���[�j���O���b�Z�[�W�m�F
    IF ( lv_err_msg IS NULL ) THEN
      NULL;
    ELSE
      RAISE global_item_check_expt;
    END IF;
--
  EXCEPTION
--
    -- *** ���ڃ`�F�b�N�G���[�n���h�� ***
    WHEN global_item_check_expt THEN
      ov_errmsg := RTRIM(lv_err_msg, cv_line_feed);
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
  END item_check;
--
  /**********************************************************************************
   * Procedure Name   : get_master_data
   * Description      : �}�X�^���̎擾����(A-6)
   ***********************************************************************************/
  PROCEDURE get_master_data(
     in_cnt                     IN  NUMBER      -- �f�[�^�J�E���^
    ,iv_bp_company_code         IN  VARCHAR2    -- �����R�[�h
    ,iv_dlv_inv_num             IN  VARCHAR2    -- �[�i�`�[�ԍ�
    ,iv_base_code               IN  VARCHAR2    -- ���_�R�[�h
    ,id_delivery_date           IN  DATE        -- �[�i��
    ,iv_card_sale_class         IN  VARCHAR2    -- �J�[�h���敪
    ,iv_customer_code           IN  VARCHAR2    -- �ɓ����ڋq�R�[�h
    ,iv_bp_customer_code        IN  VARCHAR2    -- �����ڋq�R�[�h
    ,iv_tax_class               IN  VARCHAR2    -- ����ŋ敪
    ,in_line_number             IN  NUMBER      -- ���הԍ�
    ,iv_item_code               IN  VARCHAR2    -- �ɓ����i���R�[�h
    ,iv_bp_item_code            IN  VARCHAR2    -- �����i���R�[�h
    ,ov_sales_base_code         OUT VARCHAR2    -- ���㋒�_�R�[�h
    ,ov_receiv_base_code        OUT VARCHAR2    -- �������_�R�[�h
    ,ov_bill_tax_round_rule     OUT VARCHAR2    -- �ŋ��|�[������
    ,ov_conv_customer_code      OUT VARCHAR2    -- �ϊ���ڋq�R�[�h
    ,ov_offset_cust_code        OUT VARCHAR2    -- ���E�p�ڋq�R�[�h
    ,ov_employee_number         OUT VARCHAR2    -- �S���c�ƈ�
    ,ov_cust_gyotai_sho         OUT VARCHAR2    -- �Ƒԁi�����ށj
    ,on_tax_rate                OUT NUMBER      -- ����ŗ�
    ,ov_tax_code                OUT VARCHAR2    -- �ŋ��R�[�h
    ,ov_consumption_tax_class   OUT VARCHAR2    -- ����ŋ敪
    ,ov_conv_item_code          OUT VARCHAR2    -- �ϊ���i�ڃR�[�h
    ,ov_uom_code                OUT VARCHAR2    -- ��P��
    ,on_business_cost           OUT NUMBER      -- �c�ƌ���
    ,ov_item_status             OUT VARCHAR2    -- �i�ڃX�e�[�^�X
    ,ov_errbuf     OUT VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode    OUT VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg     OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_master_data'; -- �v���O������
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
-- Ver.1.2 ADD START
    cv_common_pkg_name             CONSTANT VARCHAR2(128) := 'XXCOS_COMMON_PKG.GET_TAX_RATE_INFO';   --���ʊ֐���
    cv_view_name                   CONSTANT VARCHAR2(30)  := 'XXCOS_REDUCED_TAX_RATE_V';             --XXCOS�i�ڕʏ���ŗ��r���[
    cv_tax_view_txt                CONSTANT VARCHAR2(100) := 'XXCOS_TAX_V';
    cv_tax_class_txt               CONSTANT VARCHAR2(100) := 'TAX_CLASS';                            
-- Ver.1.2 ADD END
--
    -- *** ���[�J���ϐ� ***
    lv_bp_company_code             VARCHAR2(9);      --�����R�[�h
    lv_base_code                   VARCHAR2(4);      --���_�R�[�h
    lv_card_sale_class             VARCHAR2(1);      --�J�[�h���敪
    lv_customer_status             VARCHAR2(2);      --�ڋq�X�e�[�^�X
    lv_tax_class                   VARCHAR2(1);      --����ŋ敪
    ld_process_month               DATE;             --�Ɩ����t��
    ld_delivery_month              DATE;             --�[�i��
    lv_customer_code               VARCHAR2(9);      --�ڋq�R�[�h
    lv_customer_status_chk         VARCHAR2(2);      --�ڋq�X�e�[�^�X_�`�F�b�N�p
    lv_item_code                   VARCHAR2(7);      --�i���R�[�h
    lv_sales_target                VARCHAR2(1);      --����Ώۋ敪
    lv_item_status                 VARCHAR2(2);      --�i�ڃX�e�[�^�X
-- Ver.1.2 ADD START
    lv_class_for_variable_tax      VARCHAR2(4);      -- �y���ŗ��p�Ŏ��
    lv_tax_name                    VARCHAR2(80);     -- �ŗ��L�[����
    lv_tax_description             VARCHAR2(240);    -- �E�v
    lv_tax_histories_code          VARCHAR2(80);     -- ����ŗ����R�[�h
    lv_tax_histories_description   VARCHAR2(240);    -- ����ŗ��𖼏�
    ld_tax_start_date              DATE;             -- �ŗ��L�[_�J�n��
    ld_tax_end_date                DATE;             -- �ŗ��L�[_�I����
    ld_tax_start_date_histories    DATE;             -- ����ŗ���_�J�n��
    ld_tax_end_date_histories      DATE;             -- ����ŗ���_�I����
    lv_tax_class_suppliers_outside VARCHAR2(150);    -- �ŋ敪_�d���O��
    lv_tax_class_suppliers_inside  VARCHAR2(150);    -- �ŋ敪_�d������
    lv_tax_class_sales_outside     VARCHAR2(150);    -- �ŋ敪_����O��
    lv_tax_class_sales_inside      VARCHAR2(150);    -- �ŋ敪_�������
-- Ver.1.2 ADD END
--
    lv_tab_name                    VARCHAR2(100);    --�e�[�u����
    lv_col_name                    VARCHAR2(100);    --���ږ�
    lv_key_info1                   VARCHAR2(100);    --key���1
    lv_key_info2                   VARCHAR2(100);    --key���2
    lv_key_info                    VARCHAR2(200);    --key���
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
    -- �Ɩ����t�����Z�b�g
    ld_process_month  := TRUNC( gd_process_date ,cv_fmt_mm );
    -- �[�i�����Z�b�g
    ld_delivery_month := TRUNC( id_delivery_date ,cv_fmt_mm );
--
    -- **********************
    -- ***  �����R�[�h  ***
    -- **********************
--
    BEGIN
      SELECT xca.customer_code  AS bp_company_code
        INTO lv_bp_company_code
        FROM xxcmm_cust_accounts xca       --�ڋq�ǉ����
       WHERE xca.customer_code    = iv_bp_company_code
         AND xca.offset_cust_div  = cv_offset_cust_div_on  --���E�p�ڋq
      ;
    EXCEPTION
      -- *** �擾�G���[�n���h�� ***
      WHEN NO_DATA_FOUND THEN
        --�L�[���̕ҏW����
        lv_tab_name := xxccp_common_pkg.get_msg(
                         iv_application => cv_xxcos_appl_short_name
                        ,iv_name        => cv_msg_cust_mst                       --�ڋq�}�X�^
                       );
        lv_col_name := xxccp_common_pkg.get_msg(
                         iv_application => cv_xxcos_appl_short_name
                        ,iv_name        => cv_msg_bp_company_code                --�����R�[�h
                       );
        --
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_xxcos_appl_short_name
                      ,iv_name          => cv_msg_mst_chk_err
                      ,iv_token_name1   => cv_tkn_param1                         --�p�����[�^1(�g�[�N��)
                      ,iv_token_value1  => in_cnt                                --�s�ԍ�
                      ,iv_token_name2   => cv_tkn_param2                         --�p�����[�^2(�g�[�N��)
                      ,iv_token_value2  => iv_dlv_inv_num                        --�[�i�`�[�ԍ�
                      ,iv_token_name3   => cv_tkn_param3                         --�p�����[�^3(�g�[�N��)
                      ,iv_token_value3  => in_line_number                        --�sNo
                      ,iv_token_name4   => cv_tkn_table                          --�e�[�u����(�g�[�N��)
                      ,iv_token_value4  => lv_tab_name                           --�e�[�u����
                      ,iv_token_name5   => cv_tkn_column                         --���ږ�(�g�[�N��)
                      ,iv_token_value5  => lv_col_name                           --���ږ�
                      ,iv_token_name6   => cv_tkn_param4                         --�p�����[�^4(�g�[�N��)
                      ,iv_token_value6  => iv_bp_company_code                    --�����R�[�h
                     );
        --
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
        );
        ov_retcode := cv_status_warn;
    END;
--
    -- ********************
    -- ***  ���_�R�[�h  ***
    -- ********************
--
    BEGIN
      SELECT hca.account_number  AS base_code
        INTO lv_base_code
        FROM hz_cust_accounts hca       --�ڋq�}�X�^
       WHERE hca.customer_class_code = cv_cust_class_base
         AND hca.account_number      = iv_base_code
      ;
    EXCEPTION
      -- *** �擾�G���[�n���h�� ***
      WHEN NO_DATA_FOUND THEN
        --�L�[���̕ҏW����
        lv_tab_name := xxccp_common_pkg.get_msg(
                         iv_application => cv_xxcos_appl_short_name
                        ,iv_name        => cv_msg_cust_mst                       --�ڋq�}�X�^
                       );
        lv_col_name := xxccp_common_pkg.get_msg(
                         iv_application => cv_xxcos_appl_short_name
                        ,iv_name        => cv_msg_base_code                      --���_�R�[�h
                       );
        --
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_xxcos_appl_short_name
                      ,iv_name          => cv_msg_mst_chk_err
                      ,iv_token_name1   => cv_tkn_param1                         --�p�����[�^1(�g�[�N��)
                      ,iv_token_value1  => in_cnt                                --�s�ԍ�
                      ,iv_token_name2   => cv_tkn_param2                         --�p�����[�^2(�g�[�N��)
                      ,iv_token_value2  => iv_dlv_inv_num                        --�[�i�`�[�ԍ�
                      ,iv_token_name3   => cv_tkn_param3                         --�p�����[�^3(�g�[�N��)
                      ,iv_token_value3  => in_line_number                        --�sNo
                      ,iv_token_name4   => cv_tkn_table                          --�e�[�u����(�g�[�N��)
                      ,iv_token_value4  => lv_tab_name                           --�e�[�u����
                      ,iv_token_name5   => cv_tkn_column                         --���ږ�(�g�[�N��)
                      ,iv_token_value5  => lv_col_name                           --���ږ�
                      ,iv_token_name6   => cv_tkn_param4                         --�p�����[�^4(�g�[�N��)
                      ,iv_token_value6  => iv_base_code                          --���_�R�[�h
                     );
        --
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
        );
        ov_retcode := cv_status_warn;
    END;
--
    -- ****************
    -- ***  �[�i��  ***
    -- ****************
--
    --�[�i�����Ɩ����t�̏ꍇ�́A�[�i���������t�G���[
    IF ( id_delivery_date > gd_process_date ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_xxcos_appl_short_name
                    ,iv_name          => cv_msg_dlv_date_chk_err
                    ,iv_token_name1   => cv_tkn_param1                            --�p�����[�^1(�g�[�N��)
                    ,iv_token_value1  => in_cnt                                   --�s�ԍ�
                    ,iv_token_name2   => cv_tkn_param2                            --�p�����[�^2(�g�[�N��)
                    ,iv_token_value2  => iv_dlv_inv_num                           --�[�i�`�[�ԍ�
                    ,iv_token_name3   => cv_tkn_param3                            --�p�����[�^3(�g�[�N��)
                    ,iv_token_value3  => in_line_number                           --�sNo
                    ,iv_token_name4   => cv_tkn_param4                            --�p�����[�^4(�g�[�N��)
                    ,iv_token_value4  => TO_CHAR( id_delivery_date ,cv_fmt_std )  --�[�i��
                   );
      --
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      ov_retcode := cv_status_warn;
    END IF;
-- Ver.1.4 ADD START
--
    --�[�i�����L���J�n���̏ꍇ�́A�[�i���I�[�v����v���ԊO�G���[�G���[
    IF ( id_delivery_date < gd_start_date ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_xxcos_appl_short_name
                    ,iv_name          => cv_msg_dlv_date_chk_err_2
                    ,iv_token_name1   => cv_tkn_param1                            --�p�����[�^1(�g�[�N��)
                    ,iv_token_value1  => in_cnt                                   --�s�ԍ�
                    ,iv_token_name2   => cv_tkn_param2                            --�p�����[�^2(�g�[�N��)
                    ,iv_token_value2  => iv_dlv_inv_num                           --�[�i�`�[�ԍ�
                    ,iv_token_name3   => cv_tkn_param3                            --�p�����[�^3(�g�[�N��)
                    ,iv_token_value3  => in_line_number                           --�sNo
                    ,iv_token_name4   => cv_tkn_param4                            --�p�����[�^4(�g�[�N��)
                    ,iv_token_value4  => TO_CHAR( id_delivery_date ,cv_fmt_std )  --�[�i��
                   );
      --
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      ov_retcode := cv_status_warn;
    END IF;
-- Ver.1.4 ADD END
--
    -- **********************
    -- ***  �J�[�h���敪  ***
    -- **********************
--
    BEGIN
      SELECT flv.lookup_code  AS card_sale_class
        INTO lv_card_sale_class
        FROM fnd_lookup_values flv
       WHERE flv.language     = ct_user_lang
         AND flv.lookup_type  = cv_look_card_sale_class
         AND flv.lookup_code  = iv_card_sale_class
         AND gd_process_date >= NVL( flv.start_date_active ,gd_process_date )
         AND gd_process_date <= NVL( flv.end_date_active ,gd_max_date )
         AND flv.enabled_flag = cv_enabled_flag_y
      ;
    EXCEPTION
      -- *** �擾�G���[�n���h�� ***
      WHEN NO_DATA_FOUND THEN
        --�L�[���̕ҏW����
        lv_tab_name := xxccp_common_pkg.get_msg(
                         iv_application => cv_xxcos_appl_short_name
                        ,iv_name        => cv_msg_lkp_code                       --�N�C�b�N�R�[�h
                       );
        lv_col_name := xxccp_common_pkg.get_msg(
                         iv_application => cv_xxcos_appl_short_name
                        ,iv_name        => cv_msg_cd_sale_cls                    --�J�[�h���敪
                       );
        --
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_xxcos_appl_short_name
                      ,iv_name          => cv_msg_mst_chk_err
                      ,iv_token_name1   => cv_tkn_param1                         --�p�����[�^1(�g�[�N��)
                      ,iv_token_value1  => in_cnt                                --�s�ԍ�
                      ,iv_token_name2   => cv_tkn_param2                         --�p�����[�^2(�g�[�N��)
                      ,iv_token_value2  => iv_dlv_inv_num                        --�[�i�`�[�ԍ�
                      ,iv_token_name3   => cv_tkn_param3                         --�p�����[�^3(�g�[�N��)
                      ,iv_token_value3  => in_line_number                        --�sNo
                      ,iv_token_name4   => cv_tkn_table                          --�e�[�u����(�g�[�N��)
                      ,iv_token_value4  => lv_tab_name                           --�e�[�u����
                      ,iv_token_name5   => cv_tkn_column                         --���ږ�(�g�[�N��)
                      ,iv_token_value5  => lv_col_name                           --���ږ�
                      ,iv_token_name6   => cv_tkn_param4                         --�p�����[�^4(�g�[�N��)
                      ,iv_token_value6  => iv_card_sale_class                    --�J�[�h���敪
                     );
        --
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
        );
        ov_retcode := cv_status_warn;
    END;
--
    -- ********************************************
    -- ***  �ɓ����ڋq�R�[�h�^�����ڋq�R�[�h  ***
    -- ********************************************
--
    --�ɓ����ڋq�R�[�h���ݒ肳��Ă���ꍇ
    IF ( iv_customer_code IS NOT NULL ) THEN
--
      --�ɓ����ڋq�R�[�h�����̂܂܃Z�b�g
      lv_customer_code := iv_customer_code;
--
    --�����ڋq�R�[�h���ݒ肳��Ă���ꍇ
    ELSIF ( iv_bp_customer_code IS NOT NULL ) THEN
--
      ------------------------------------
      -- �ɓ����ڋq�R�[�h�擾
      ------------------------------------
      BEGIN
        SELECT /*+ INDEX(xca XXCMM_CUST_ACCOUNTS_N27) */
               xca.customer_code     AS customer_code    -- �ɓ����ڋq�R�[�h
          INTO lv_customer_code
          FROM xxcmm_cust_accounts    xca   -- �ڋq�ǉ����
         WHERE xca.bp_customer_code = iv_bp_customer_code
        ;
      EXCEPTION
        -- *** �擾�G���[�n���h�� ***
        WHEN NO_DATA_FOUND THEN
          --�L�[���̕ҏW����
          lv_tab_name := xxccp_common_pkg.get_msg(
                           iv_application => cv_xxcos_appl_short_name
                          ,iv_name        => cv_msg_cust_mst                       --�ڋq�}�X�^
                         );
          lv_col_name := xxccp_common_pkg.get_msg(
                           iv_application => cv_xxcos_appl_short_name
                          ,iv_name        => cv_msg_bp_cust_code                   --�����ڋq�R�[�h
                         );
          --
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => cv_xxcos_appl_short_name
                        ,iv_name          => cv_msg_null_or_get_data_err
                        ,iv_token_name1   => cv_tkn_param1                         --�p�����[�^1(�g�[�N��)
                        ,iv_token_value1  => in_cnt                                --�s�ԍ�
                        ,iv_token_name2   => cv_tkn_param2                         --�p�����[�^2(�g�[�N��)
                        ,iv_token_value2  => iv_dlv_inv_num                        --�[�i�`�[�ԍ�
                        ,iv_token_name3   => cv_tkn_param3                         --�p�����[�^3(�g�[�N��)
                        ,iv_token_value3  => in_line_number                        --�sNo
                        ,iv_token_name4   => cv_tkn_table                          --�e�[�u����(�g�[�N��)
                        ,iv_token_value4  => lv_tab_name                           --�ڋq�}�X�^
                        ,iv_token_name5   => cv_tkn_column                         --���ږ�(�g�[�N��)
                        ,iv_token_value5  => lv_col_name                           --�����ڋq�R�[�h
                       );
          --
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
          );
          ov_retcode := cv_status_warn;
        --
        -- *** ���������R�[�h���݃G���[�n���h�� ***
        WHEN TOO_MANY_ROWS THEN
            --�L�[���̕ҏW����
            lv_tab_name := xxccp_common_pkg.get_msg(
                             iv_application => cv_xxcos_appl_short_name
                            ,iv_name        => cv_msg_cust_mst                     --�ڋq�}�X�^
                           );
            lv_col_name := xxccp_common_pkg.get_msg(
                             iv_application => cv_xxcos_appl_short_name
                            ,iv_name        => cv_msg_bp_cust_code                 --�����ڋq�R�[�h
                           );
            --
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application   => cv_xxcos_appl_short_name
                          ,iv_name          => cv_msg_overlap_err
                          ,iv_token_name1   => cv_tkn_param1                       --�p�����[�^1(�g�[�N��)
                          ,iv_token_value1  => in_cnt                              --�s�ԍ�
                          ,iv_token_name2   => cv_tkn_param2                       --�p�����[�^2(�g�[�N��)
                          ,iv_token_value2  => iv_dlv_inv_num                      --�[�i�`�[�ԍ�
                          ,iv_token_name3   => cv_tkn_param3                       --�p�����[�^3(�g�[�N��)
                          ,iv_token_value3  => in_line_number                      --�sNo
                          ,iv_token_name4   => cv_tkn_table                        --�e�[�u����(�g�[�N��)
                          ,iv_token_value4  => lv_tab_name                         --�e�[�u����
                          ,iv_token_name5   => cv_tkn_column                       --���ږ�(�g�[�N��)
                          ,iv_token_value5  => lv_col_name                         --���ږ�
                          ,iv_token_name6   => cv_tkn_param4                       --�p�����[�^4(�g�[�N��)
                          ,iv_token_value6  => iv_bp_customer_code                 --�����ڋq�R�[�h
                         );
            --
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
            );
            ov_retcode := cv_status_warn;
      END;
--
    --��L�ȊO�̏ꍇ�́A�����t���K�{�`�F�b�N�G���[
    ELSE
--
      --�L�[���̕ҏW����
      lv_key_info1 := xxccp_common_pkg.get_msg(
                        iv_application => cv_xxcos_appl_short_name
                       ,iv_name        => cv_msg_cust_code                     --�ɓ����ڋq�R�[�h
                      );
      lv_key_info2 := xxccp_common_pkg.get_msg(
                        iv_application => cv_xxcos_appl_short_name
                       ,iv_name        => cv_msg_bp_cust_code                  --�����ڋq�R�[�h
                      );
      lv_key_info  := lv_key_info1 || cv_msg_comma || lv_key_info2;
      --
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_xxcos_appl_short_name
                    ,iv_name          => cv_msg_req_cond_err
                    ,iv_token_name1   => cv_tkn_param1                         --�p�����[�^1(�g�[�N��)
                    ,iv_token_value1  => in_cnt                                --�s�ԍ�
                    ,iv_token_name2   => cv_tkn_param2                         --�p�����[�^2(�g�[�N��)
                    ,iv_token_value2  => iv_dlv_inv_num                        --�[�i�`�[�ԍ�
                    ,iv_token_name3   => cv_tkn_param3                         --�p�����[�^3(�g�[�N��)
                    ,iv_token_value3  => in_line_number                        --�sNo
                    ,iv_token_name4   => cv_tkn_key_data                       --�L�[���(�g�[�N��)
                    ,iv_token_value4  => lv_key_info                           --�L�[���
                   );
      --
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      ov_retcode := cv_status_warn;
--
    END IF;
--
-- Ver.1.5 ADD START
    -- �O���R�[�h�Ɣ[�i�`�[�ԍ��������ŁA�ڋq�R�[�h���Ⴄ�ꍇ�̓G���[�Ƃ���B
    IF (  in_cnt > 2
      AND gt_pre_dlv_inv_num   =  iv_dlv_inv_num
      AND gt_pre_customer_code <> lv_customer_code ) THEN
--
      lv_errmsg := xxccp_common_pkg.get_msg(
              iv_application   => cv_xxcos_appl_short_name
             ,iv_name          => cv_msg_inv_num_multi_cust_err              --�[�i�`�[�ԍ��E�����ڋq�`�F�b�N�G���[
             ,iv_token_name1   => cv_tkn_param1                              --�p�����[�^1(�g�[�N��)
             ,iv_token_value1  => in_cnt                                     --�s�ԍ�
             ,iv_token_name2   => cv_tkn_param2                              --�p�����[�^2(�g�[�N��)
             ,iv_token_value2  => iv_dlv_inv_num                             --�[�i�`�[�ԍ�
             ,iv_token_name3   => cv_tkn_param3                              --�p�����[�^3(�g�[�N��)
             ,iv_token_value3  => in_line_number                             --���הԍ�
             ,iv_token_name4   => cv_tkn_param4                              --�p�����[�^4(�g�[�N��)
             ,iv_token_value4  => iv_customer_code                           --�ɓ����ڋq�R�[�h
             ,iv_token_name5   => cv_tkn_param5                              --�p�����[�^5(�g�[�N��)
             ,iv_token_value5  => iv_bp_customer_code                        --�����ڋq�R�[�h
            );
--
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      ov_retcode := cv_status_warn;
    END IF;
--
    -- �`�F�b�N��Ɍ����R�[�h�l��O���R�[�h�l�Ƃ��Đݒ�
    gt_pre_dlv_inv_num   := iv_dlv_inv_num;
    gt_pre_customer_code := lv_customer_code;
--
-- Ver.1.5 ADD END
    --�ɓ����ڋq�R�[�h���擾�ł���ꍇ
    IF ( lv_customer_code IS NOT NULL ) THEN
--
      ------------------------------------
      -- �ڋq�}�X�^���擾
      ------------------------------------
      BEGIN
        SELECT hca.account_number          AS conv_customer_code    -- �ϊ���ڋq�R�[�h
              ,CASE
                 WHEN ld_process_month > ld_delivery_month THEN
                   xca.past_sale_base_code
                 ELSE
                   xca.sale_base_code
               END                         AS sales_base_code       -- ���㋒�_�R�[�h
              ,xch.cash_receiv_base_code   AS cash_receiv_base_code -- �������_�R�[�h
              ,xch.bill_tax_round_rule     AS bill_tax_round_rule   -- �ŋ��|�[������
              ,xca.offset_cust_code        AS offset_cust_code      -- ���E�p�ڋq�R�[�h
              ,xca.business_low_type       AS cust_gyotai_sho       -- �Ƒԁi�����ށj
              ,hp.duns_number_c            AS customer_status       -- �ڋq�X�e�[�^�X
          INTO ov_conv_customer_code
              ,ov_sales_base_code
              ,ov_receiv_base_code
              ,ov_bill_tax_round_rule
              ,ov_offset_cust_code
              ,ov_cust_gyotai_sho
              ,lv_customer_status
          FROM hz_cust_accounts       hca   -- �ڋq�}�X�^
              ,hz_parties             hp    -- �p�[�e�B
              ,xxcmm_cust_accounts    xca   -- �ڋq�ǉ����
              ,xxcos_cust_hierarchy_v xch   -- �ڋq�K�w�r���[
         WHERE hca.party_id            = hp.party_id
           AND hca.cust_account_id     = xca.customer_id
           AND xch.ship_account_number = hca.account_number
           AND hca.customer_class_code IN ( cv_cust_class_cust   --�ڋq
                                          , cv_cust_class_user   --��l
                                          )
           AND hca.account_number      = lv_customer_code
        ;
      EXCEPTION
        -- *** �擾�G���[�n���h�� ***
        WHEN NO_DATA_FOUND THEN
          --�L�[���̕ҏW����
          lv_tab_name := xxccp_common_pkg.get_msg(
                           iv_application => cv_xxcos_appl_short_name
                          ,iv_name        => cv_msg_cust_mst                       --�ڋq�}�X�^
                         );
          lv_col_name := xxccp_common_pkg.get_msg(
                           iv_application => cv_xxcos_appl_short_name
                          ,iv_name        => cv_msg_cust_code                      --�ɓ����ڋq�R�[�h
                         );
          --
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => cv_xxcos_appl_short_name
                        ,iv_name          => cv_msg_mst_chk_err
                        ,iv_token_name1   => cv_tkn_param1                         --�p�����[�^1(�g�[�N��)
                        ,iv_token_value1  => in_cnt                                --�s�ԍ�
                        ,iv_token_name2   => cv_tkn_param2                         --�p�����[�^2(�g�[�N��)
                        ,iv_token_value2  => iv_dlv_inv_num                        --�[�i�`�[�ԍ�
                        ,iv_token_name3   => cv_tkn_param3                         --�p�����[�^3(�g�[�N��)
                        ,iv_token_value3  => in_line_number                        --�sNo
                        ,iv_token_name4   => cv_tkn_table                          --�e�[�u����(�g�[�N��)
                        ,iv_token_value4  => lv_tab_name                           --�e�[�u����
                        ,iv_token_name5   => cv_tkn_column                         --���ږ�(�g�[�N��)
                        ,iv_token_value5  => lv_col_name                           --���ږ�
                        ,iv_token_name6   => cv_tkn_param4                         --�p�����[�^4(�g�[�N��)
                        ,iv_token_value6  => lv_customer_code                      --�ɓ����ڋq�R�[�h
                       );
          --
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
          );
          ov_retcode := cv_status_warn;
      END;
--
    END IF;
--
    --�ϊ���ڋq�R�[�h���擾�ł���ꍇ
    IF ( ov_conv_customer_code IS NOT NULL ) THEN
--
      ------------------------------------
      -- �ڋq�X�e�[�^�X�`�F�b�N
      ------------------------------------
      BEGIN
        SELECT flv.meaning   AS customer_status
          INTO lv_customer_status_chk
          FROM fnd_lookup_values flv
         WHERE flv.language     = ct_user_lang
           AND flv.lookup_type  = cv_look_cus_sts
           AND flv.lookup_code  LIKE cv_look_cus_sts_a01
           AND flv.meaning      = lv_customer_status
           AND gd_process_date >= NVL( flv.start_date_active ,gd_process_date )
           AND gd_process_date <= NVL( flv.end_date_active ,gd_max_date )
           AND flv.enabled_flag = cv_enabled_flag_y
        ;
      EXCEPTION
        -- *** �擾�G���[�n���h�� ***
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => cv_xxcos_appl_short_name
                        ,iv_name          => cv_msg_cust_sts_err
                        ,iv_token_name1   => cv_tkn_param1                         --�p�����[�^1(�g�[�N��)
                        ,iv_token_value1  => in_cnt                                --�s�ԍ�
                        ,iv_token_name2   => cv_tkn_param2                         --�p�����[�^2(�g�[�N��)
                        ,iv_token_value2  => iv_dlv_inv_num                        --�[�i�`�[�ԍ�
                        ,iv_token_name3   => cv_tkn_param3                         --�p�����[�^3(�g�[�N��)
                        ,iv_token_value3  => in_line_number                        --�sNo
                        ,iv_token_name4   => cv_tkn_param4                         --�p�����[�^4(�g�[�N��)
                        ,iv_token_value4  => ov_conv_customer_code                 --�ϊ���ڋq�R�[�h
                        ,iv_token_name5   => cv_tkn_key_data                       --�L�[���(�g�[�N��)
                        ,iv_token_value5  => lv_customer_status                    --�ڋq�X�e�[�^�X
                       );
          --
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
          );
          ov_retcode := cv_status_warn;
      END;
--
      ------------------------------------
      -- ���㋒�_�R�[�h�`�F�b�N
      ------------------------------------
      -- ���_�R�[�h���擾�ł���ꍇ
      IF ( lv_base_code IS NOT NULL ) THEN
        --���_�R�[�h�Ɣ��㋒�_�R�[�h���s��v�̏ꍇ�̓G���[
        IF ( lv_base_code != ov_sales_base_code ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => cv_xxcos_appl_short_name
                        ,iv_name          => cv_msg_sale_base_code_err
                        ,iv_token_name1   => cv_tkn_param1                         --�p�����[�^1(�g�[�N��)
                        ,iv_token_value1  => in_cnt                                --�s�ԍ�
                        ,iv_token_name2   => cv_tkn_param2                         --�p�����[�^2(�g�[�N��)
                        ,iv_token_value2  => iv_dlv_inv_num                        --�[�i�`�[�ԍ�
                        ,iv_token_name3   => cv_tkn_param3                         --�p�����[�^3(�g�[�N��)
                        ,iv_token_value3  => in_line_number                        --�sNo
                        ,iv_token_name4   => cv_tkn_param4                         --�p�����[�^4(�g�[�N��)
                        ,iv_token_value4  => ov_conv_customer_code                 --�ϊ���ڋq�R�[�h
                        ,iv_token_name5   => cv_tkn_key_data                       --�L�[���(�g�[�N��)
                        ,iv_token_value5  => ov_sales_base_code                    --���㋒�_�R�[�h
                       );
          --
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
          );
          ov_retcode := cv_status_warn;
        END IF;
--
      END IF;
--
      ------------------------------------
      -- ���E�p�ڋq�R�[�h�`�F�b�N
      ------------------------------------
      --���E�p�ڋq�R�[�h��NULL�̏ꍇ�̓G���[
      IF ( ov_offset_cust_code IS NULL ) THEN
        --�L�[���̕ҏW����
        lv_tab_name := xxccp_common_pkg.get_msg(
                         iv_application => cv_xxcos_appl_short_name
                        ,iv_name        => cv_msg_cust_mst                       --�ڋq�}�X�^
                       );
        lv_col_name := xxccp_common_pkg.get_msg(
                         iv_application => cv_xxcos_appl_short_name
                        ,iv_name        => cv_msg_offset_cust_code               --���E�p�ڋq�R�[�h
                       );
        --
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_xxcos_appl_short_name
                      ,iv_name          => cv_msg_null_or_get_data_err
                      ,iv_token_name1   => cv_tkn_param1                         --�p�����[�^1(�g�[�N��)
                      ,iv_token_value1  => in_cnt                                --�s�ԍ�
                      ,iv_token_name2   => cv_tkn_param2                         --�p�����[�^2(�g�[�N��)
                      ,iv_token_value2  => iv_dlv_inv_num                        --�[�i�`�[�ԍ�
                      ,iv_token_name3   => cv_tkn_param3                         --�p�����[�^3(�g�[�N��)
                      ,iv_token_value3  => in_line_number                        --�sNo
                      ,iv_token_name4   => cv_tkn_table                          --�e�[�u����(�g�[�N��)
                      ,iv_token_value4  => lv_tab_name                           --�ڋq�}�X�^
                      ,iv_token_name5   => cv_tkn_column                         --���ږ�(�g�[�N��)
                      ,iv_token_value5  => lv_col_name                           --���E�p�ڋq�R�[�h
                     );
        --
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
        );
        ov_retcode := cv_status_warn;
--
      ELSE
--
        ------------------------------------
        -- �����R�[�h�`�F�b�N
        ------------------------------------
        --�����R�[�h�Ƒ��E�p�ڋq�R�[�h���s��v�̏ꍇ�̓G���[
        IF ( lv_bp_company_code != ov_offset_cust_code ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => cv_xxcos_appl_short_name
                        ,iv_name          => cv_msg_bp_com_code_err
                        ,iv_token_name1   => cv_tkn_param1                         --�p�����[�^1(�g�[�N��)
                        ,iv_token_value1  => in_cnt                                --�s�ԍ�
                        ,iv_token_name2   => cv_tkn_param2                         --�p�����[�^2(�g�[�N��)
                        ,iv_token_value2  => iv_dlv_inv_num                        --�[�i�`�[�ԍ�
                        ,iv_token_name3   => cv_tkn_param3                         --�p�����[�^3(�g�[�N��)
                        ,iv_token_value3  => in_line_number                        --�sNo
                        ,iv_token_name4   => cv_tkn_param4                         --�p�����[�^4(�g�[�N��)
                        ,iv_token_value4  => lv_bp_company_code                    --�����R�[�h
                        ,iv_token_name5   => cv_tkn_key_data                       --�L�[���(�g�[�N��)
                        ,iv_token_value5  => ov_offset_cust_code                   --���E�p�ڋq�R�[�h
                       );
          --
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
          );
          ov_retcode := cv_status_warn;
        END IF;
--
      END IF;
--
      ------------------------------------
      -- �S���c�ƈ��擾
      ------------------------------------
      BEGIN
        SELECT xsv.employee_number  AS employee_number
          INTO ov_employee_number
          FROM xxcos_salesreps_v  xsv    --�S���c�ƈ��r���[
         WHERE xsv.account_number = ov_conv_customer_code
           AND id_delivery_date  >= NVL( xsv.effective_start_date ,id_delivery_date )
           AND id_delivery_date  <= NVL( xsv.effective_end_date ,gd_max_date )
        ;
      EXCEPTION
        -- *** �擾�G���[�n���h�� ***
        WHEN NO_DATA_FOUND THEN
          --�L�[���̕ҏW����
          lv_tab_name := xxccp_common_pkg.get_msg(
                           iv_application => cv_xxcos_appl_short_name
                          ,iv_name        => cv_msg_cust_mst                       --�ڋq�}�X�^
                         );
          lv_col_name := xxccp_common_pkg.get_msg(
                           iv_application => cv_xxcos_appl_short_name
                          ,iv_name        => cv_msg_employee_code                  --�S���c�ƈ�
                         );
          --
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => cv_xxcos_appl_short_name
                        ,iv_name          => cv_msg_null_or_get_data_err
                        ,iv_token_name1   => cv_tkn_param1                         --�p�����[�^1(�g�[�N��)
                        ,iv_token_value1  => in_cnt                                --�s�ԍ�
                        ,iv_token_name2   => cv_tkn_param2                         --�p�����[�^2(�g�[�N��)
                        ,iv_token_value2  => iv_dlv_inv_num                        --�[�i�`�[�ԍ�
                        ,iv_token_name3   => cv_tkn_param3                         --�p�����[�^3(�g�[�N��)
                        ,iv_token_value3  => in_line_number                        --�sNo
                        ,iv_token_name4   => cv_tkn_table                          --�e�[�u����(�g�[�N��)
                        ,iv_token_value4  => lv_tab_name                           --�ڋq�}�X�^
                        ,iv_token_name5   => cv_tkn_column                         --���ږ�(�g�[�N��)
                        ,iv_token_value5  => lv_col_name                           --�S���c�ƈ�
                       );
          --
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
          );
          ov_retcode := cv_status_warn;
        --
        -- *** ���������R�[�h���݃G���[�n���h�� ***
        WHEN TOO_MANY_ROWS THEN
            --�L�[���̕ҏW����
            lv_tab_name := xxccp_common_pkg.get_msg(
                             iv_application => cv_xxcos_appl_short_name
                            ,iv_name        => cv_msg_cust_mst                     --�ڋq�}�X�^
                           );
            lv_col_name := xxccp_common_pkg.get_msg(
                             iv_application => cv_xxcos_appl_short_name
                            ,iv_name        => cv_msg_employee_code                --�S���c�ƈ�
                           );
            --
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application   => cv_xxcos_appl_short_name
                          ,iv_name          => cv_msg_overlap_err
                          ,iv_token_name1   => cv_tkn_param1                       --�p�����[�^1(�g�[�N��)
                          ,iv_token_value1  => in_cnt                              --�s�ԍ�
                          ,iv_token_name2   => cv_tkn_param2                       --�p�����[�^2(�g�[�N��)
                          ,iv_token_value2  => iv_dlv_inv_num                      --�[�i�`�[�ԍ�
                          ,iv_token_name3   => cv_tkn_param3                       --�p�����[�^3(�g�[�N��)
                          ,iv_token_value3  => in_line_number                      --�sNo
                          ,iv_token_name4   => cv_tkn_table                        --�e�[�u����(�g�[�N��)
                          ,iv_token_value4  => lv_tab_name                         --�e�[�u����
                          ,iv_token_name5   => cv_tkn_column                       --���ږ�(�g�[�N��)
                          ,iv_token_value5  => lv_col_name                         --���ږ�
                          ,iv_token_name6   => cv_tkn_param4                       --�p�����[�^4(�g�[�N��)
                          ,iv_token_value6  => NULL                                --�S���c�ƈ�
                         );
            --
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
            );
            ov_retcode := cv_status_warn;
      END;
--
    END IF;
--
-- Ver.1.2 DEL START
    -- ********************
    -- ***  ����ŋ敪  ***
    -- ********************
--
--    BEGIN
--      SELECT flv.attribute1   AS tax_class
--        INTO lv_tax_class
--        FROM fnd_lookup_values flv
--       WHERE flv.language     = ct_user_lang
--         AND flv.lookup_type  = cv_look_tax_class
--         AND flv.attribute1   = iv_tax_class
--         AND gd_process_date >= NVL( flv.start_date_active ,gd_process_date )
--         AND gd_process_date <= NVL( flv.end_date_active ,gd_max_date )
--         AND flv.enabled_flag = cv_enabled_flag_y
--      ;
--    EXCEPTION
--     -- *** �擾�G���[�n���h�� ***
--      WHEN NO_DATA_FOUND THEN
--       --�L�[���̕ҏW����
--        lv_tab_name := xxccp_common_pkg.get_msg(
--                         iv_application => cv_xxcos_appl_short_name
--                        ,iv_name        => cv_msg_lkp_code                       --�N�C�b�N�R�[�h
--                       );
--        lv_col_name := xxccp_common_pkg.get_msg(
--                         iv_application => cv_xxcos_appl_short_name
--                        ,iv_name        => cv_msg_tax_class                      --����ŋ敪
--                       );
--        --
--        lv_errmsg := xxccp_common_pkg.get_msg(
--                       iv_application   => cv_xxcos_appl_short_name
--                      ,iv_name          => cv_msg_mst_chk_err
--                      ,iv_token_name1   => cv_tkn_param1                         --�p�����[�^1(�g�[�N��)
--                      ,iv_token_value1  => in_cnt                                --�s�ԍ�
--                      ,iv_token_name2   => cv_tkn_param2                         --�p�����[�^2(�g�[�N��)
--                      ,iv_token_value2  => iv_dlv_inv_num                        --�[�i�`�[�ԍ�
--                      ,iv_token_name3   => cv_tkn_param3                         --�p�����[�^3(�g�[�N��)
--                      ,iv_token_value3  => in_line_number                        --�sNo
--                      ,iv_token_name4   => cv_tkn_table                          --�e�[�u����(�g�[�N��)
--                      ,iv_token_value4  => lv_tab_name                           --�e�[�u����
--                      ,iv_token_name5   => cv_tkn_column                         --���ږ�(�g�[�N��)
--                      ,iv_token_value5  => lv_col_name                           --���ږ�
--                      ,iv_token_name6   => cv_tkn_param4                         --�p�����[�^4(�g�[�N��)
--                      ,iv_token_value6  => iv_tax_class                          --����ŋ敪
--                     );
--        --
--        FND_FILE.PUT_LINE(
--          which  => FND_FILE.OUTPUT
--         ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
--        );
--        ov_retcode := cv_status_warn;
--    END;
--
--    --����ŋ敪���擾�ł���ꍇ
--    IF ( lv_tax_class IS NOT NULL ) THEN
--
--      ------------------------------------
--      -- ����ŏ��擾
--      ------------------------------------
--      BEGIN
--        SELECT xtv.tax_rate   AS tax_rate                -- ����ŗ�
--              ,xtv.tax_code   AS tax_code                -- ����ŃR�[�h
--              ,xtv.tax_class  AS consumption_tax_class   -- �̔����јA�g����ŋ敪
--          INTO on_tax_rate
--              ,ov_tax_code
--              ,ov_consumption_tax_class
--          FROM xxcos_tax_v  xtv   -- �����view
--         WHERE xtv.hht_tax_class     = lv_tax_class
--           AND xtv.set_of_books_id   = gn_bks_id
--           AND id_delivery_date     >= NVL( xtv.start_date_active ,id_delivery_date )
--           AND id_delivery_date     <= NVL( xtv.end_date_active ,gd_max_date )
--        ;
--      EXCEPTION
--        -- *** �擾�G���[�n���h�� ***
--        WHEN NO_DATA_FOUND THEN
--          --�L�[���̕ҏW����
--          lv_tab_name := xxccp_common_pkg.get_msg(
--                           iv_application => cv_xxcos_appl_short_name
--                          ,iv_name        => cv_msg_tax_view                       --�����view
--                         );
--          lv_col_name := xxccp_common_pkg.get_msg(
--                           iv_application => cv_xxcos_appl_short_name
--                          ,iv_name        => cv_msg_tax_rate                       --����ŗ�
--                         );
--          --
--          lv_errmsg := xxccp_common_pkg.get_msg(
--                         iv_application   => cv_xxcos_appl_short_name
--                        ,iv_name          => cv_msg_null_or_get_data_err
--                        ,iv_token_name1   => cv_tkn_param1                         --�p�����[�^1(�g�[�N��)
--                       ,iv_token_value1  => in_cnt                                --�s�ԍ�
--                        ,iv_token_name2   => cv_tkn_param2                         --�p�����[�^2(�g�[�N��)
--                        ,iv_token_value2  => iv_dlv_inv_num                        --�[�i�`�[�ԍ�
--                        ,iv_token_name3   => cv_tkn_param3                         --�p�����[�^3(�g�[�N��)
--                        ,iv_token_value3  => in_line_number                        --�sNo
--                        ,iv_token_name4   => cv_tkn_table                          --�e�[�u����(�g�[�N��)
--                        ,iv_token_value4  => lv_tab_name                           --�e�[�u����
--                        ,iv_token_name5   => cv_tkn_column                         --���ږ�(�g�[�N��)
--                        ,iv_token_value5  => lv_col_name                           --���ږ�
--                       );
--          --
--          FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--           ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
--          );
--          ov_retcode := cv_status_warn;
--      END;
--
--    END IF;
--
-- Ver.1.2 DEL END
--
  -- ********************************************
  -- ***  �ɓ����i���R�[�h�^�����i���R�[�h  ***
  -- ********************************************
--
    --�ɓ����i���R�[�h���ݒ肳��Ă���ꍇ
    IF ( iv_item_code IS NOT NULL ) THEN
--
      --�ɓ����i���R�[�h�����̂܂܃Z�b�g
      lv_item_code := iv_item_code;
--
    --�����i���R�[�h���ݒ肳��Ă���ꍇ
    ELSIF ( iv_bp_item_code IS NOT NULL ) THEN
--
      --�����R�[�h���擾�ł���ꍇ
      IF ( lv_bp_company_code IS NOT NULL ) THEN
--
        --�����R�[�h�`�F�b�N��OK�̏ꍇ
        IF ( lv_bp_company_code = ov_offset_cust_code ) THEN
--
          ------------------------------------
          -- �ɓ����i���R�[�h�擾
          ------------------------------------
          BEGIN
            SELECT xbpi.item_code    AS item_code  -- �ɓ����i���R�[�h
              INTO lv_item_code
              FROM xxcmm_bus_partner_items   xbpi   -- �����i�ڃA�h�I��
             WHERE xbpi.bp_company_code  = lv_bp_company_code
               AND xbpi.bp_item_code     = iv_bp_item_code
               AND xbpi.enabled_flag     = cv_enabled_flag_y
            ;
          EXCEPTION
            -- *** �擾�G���[�n���h�� ***
            WHEN NO_DATA_FOUND THEN
              --�L�[���̕ҏW����
              lv_tab_name := xxccp_common_pkg.get_msg(
                               iv_application => cv_xxcos_appl_short_name
                              ,iv_name        => cv_msg_bp_item_mst                    --�����i�ڃA�h�I��
                             );
              lv_col_name := xxccp_common_pkg.get_msg(
                               iv_application => cv_xxcos_appl_short_name
                              ,iv_name        => cv_msg_bp_item_code                   --�����i���R�[�h
                             );
              --
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application   => cv_xxcos_appl_short_name
                            ,iv_name          => cv_msg_mst_chk_err
                            ,iv_token_name1   => cv_tkn_param1                         --�p�����[�^1(�g�[�N��)
                            ,iv_token_value1  => in_cnt                                --�s�ԍ�
                            ,iv_token_name2   => cv_tkn_param2                         --�p�����[�^2(�g�[�N��)
                            ,iv_token_value2  => iv_dlv_inv_num                        --�[�i�`�[�ԍ�
                            ,iv_token_name3   => cv_tkn_param3                         --�p�����[�^3(�g�[�N��)
                            ,iv_token_value3  => in_line_number                        --�sNo
                            ,iv_token_name4   => cv_tkn_table                          --�e�[�u����(�g�[�N��)
                            ,iv_token_value4  => lv_tab_name                           --�e�[�u����
                            ,iv_token_name5   => cv_tkn_column                         --���ږ�(�g�[�N��)
                            ,iv_token_value5  => lv_col_name                           --���ږ�
                            ,iv_token_name6   => cv_tkn_param4                         --�p�����[�^4(�g�[�N��)
                            ,iv_token_value6  => iv_bp_item_code                       --�����i���R�[�h
                           );
              --
              FND_FILE.PUT_LINE(
                which  => FND_FILE.OUTPUT
               ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
              );
              ov_retcode := cv_status_warn;
          END;
--
        END IF;
--
      END IF;
--
    --��L�ȊO�̏ꍇ�́A�����t���K�{�`�F�b�N�G���[
    ELSE
--
      --�L�[���̕ҏW����
      lv_key_info1 := xxccp_common_pkg.get_msg(
                        iv_application => cv_xxcos_appl_short_name
                       ,iv_name        => cv_msg_item_code                     --�ɓ����i���R�[�h
                      );
      lv_key_info2 := xxccp_common_pkg.get_msg(
                        iv_application => cv_xxcos_appl_short_name
                       ,iv_name        => cv_msg_bp_item_code                  --�����i���R�[�h
                      );
      lv_key_info  := lv_key_info1 || cv_msg_comma || lv_key_info2;
      --
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_xxcos_appl_short_name
                    ,iv_name          => cv_msg_req_cond_err
                    ,iv_token_name1   => cv_tkn_param1                         --�p�����[�^1(�g�[�N��)
                    ,iv_token_value1  => in_cnt                                --�s�ԍ�
                    ,iv_token_name2   => cv_tkn_param2                         --�p�����[�^2(�g�[�N��)
                    ,iv_token_value2  => iv_dlv_inv_num                        --�[�i�`�[�ԍ�
                    ,iv_token_name3   => cv_tkn_param3                         --�p�����[�^3(�g�[�N��)
                    ,iv_token_value3  => in_line_number                        --�sNo
                    ,iv_token_name4   => cv_tkn_key_data                       --�L�[���(�g�[�N��)
                    ,iv_token_value4  => lv_key_info                           --�L�[���
                   );
      --
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      ov_retcode := cv_status_warn;
--
    END IF;
--
    --�ɓ����i���R�[�h���擾�ł���ꍇ
    IF ( lv_item_code IS NOT NULL ) THEN
--
      ------------------------------------
      -- �i�ڃ}�X�^���擾
      ------------------------------------
      BEGIN
        SELECT iimb.item_no                  AS conv_item_code  -- �ϊ���i���R�[�h
              ,msib.primary_unit_of_measure  AS uom_code        -- ��P��
              ,CASE
                 WHEN TO_DATE( iimb.attribute9, cv_fmt_std ) > id_delivery_date THEN
                   TO_NUMBER(iimb.attribute7)  -- �c�ƌ���(��)
                 ELSE
                   TO_NUMBER(iimb.attribute8)  -- �c�ƌ���(�V)
               END                           AS business_cost   -- �c�ƌ���
              ,iimb.attribute26              AS sales_target    -- ����Ώۋ敪
              ,ximb.item_status              AS item_status     -- �i�ڃX�e�[�^�X
          INTO ov_conv_item_code
              ,ov_uom_code
              ,on_business_cost
              ,lv_sales_target
              ,lv_item_status
          FROM ic_item_mst_b         iimb   -- OPM�i�ڃ}�X�^
              ,mtl_system_items_b    msib   -- DISC�i�ڃ}�X�^
              ,xxcmm_system_items_b  ximb   -- DISC�i�ڃA�h�I��
         WHERE iimb.item_no          = msib.segment1
           AND msib.organization_id  = gn_org_id
           AND iimb.item_no          = ximb.item_code
           AND iimb.item_no          = lv_item_code
        ;
      EXCEPTION
        -- *** �擾�G���[�n���h�� ***
        WHEN NO_DATA_FOUND THEN
          --�L�[���̕ҏW����
          lv_tab_name := xxccp_common_pkg.get_msg(
                           iv_application => cv_xxcos_appl_short_name
                          ,iv_name        => cv_msg_item_mst                       --�i�ڃ}�X�^
                         );
          lv_col_name := xxccp_common_pkg.get_msg(
                           iv_application => cv_xxcos_appl_short_name
                          ,iv_name        => cv_msg_item_code                      --�ɓ����i���R�[�h
                         );
          --
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => cv_xxcos_appl_short_name
                        ,iv_name          => cv_msg_mst_chk_err
                        ,iv_token_name1   => cv_tkn_param1                         --�p�����[�^1(�g�[�N��)
                        ,iv_token_value1  => in_cnt                                --�s�ԍ�
                        ,iv_token_name2   => cv_tkn_param2                         --�p�����[�^2(�g�[�N��)
                        ,iv_token_value2  => iv_dlv_inv_num                        --�[�i�`�[�ԍ�
                        ,iv_token_name3   => cv_tkn_param3                         --�p�����[�^3(�g�[�N��)
                        ,iv_token_value3  => in_line_number                        --�sNo
                        ,iv_token_name4   => cv_tkn_table                          --�e�[�u����(�g�[�N��)
                        ,iv_token_value4  => lv_tab_name                           --�e�[�u����
                        ,iv_token_name5   => cv_tkn_column                         --���ږ�(�g�[�N��)
                        ,iv_token_value5  => lv_col_name                           --���ږ�
                        ,iv_token_name6   => cv_tkn_param4                         --�p�����[�^4(�g�[�N��)
                        ,iv_token_value6  => lv_item_code                          --�ɓ����i���R�[�h
                       );
          --
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
          );
          ov_retcode := cv_status_warn;
      END;
--
    END IF;
--
    --�ϊ���i���R�[�h���擾�ł���ꍇ
    IF ( ov_conv_item_code IS NOT NULL ) THEN
--
      ------------------------------------
      -- ����Ώۋ敪�`�F�b�N
      ------------------------------------
      --����ΏۊO�̏ꍇ�̓G���[
      IF ( lv_sales_target = cv_sales_target_off ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_xxcos_appl_short_name
                      ,iv_name          => cv_msg_sales_target_chk_err
                      ,iv_token_name1   => cv_tkn_param1                         --�p�����[�^1(�g�[�N��)
                      ,iv_token_value1  => in_cnt                                --�s�ԍ�
                      ,iv_token_name2   => cv_tkn_param2                         --�p�����[�^2(�g�[�N��)
                      ,iv_token_value2  => iv_dlv_inv_num                        --�[�i�`�[�ԍ�
                      ,iv_token_name3   => cv_tkn_param3                         --�p�����[�^3(�g�[�N��)
                      ,iv_token_value3  => in_line_number                        --�sNo
                      ,iv_token_name4   => cv_tkn_param4                         --�p�����[�^4(�g�[�N��)
                      ,iv_token_value4  => ov_conv_item_code                     --�ϊ���i���R�[�h
                      ,iv_token_name5   => cv_tkn_key_data                       --�L�[���(�g�[�N��)
                      ,iv_token_value5  => lv_sales_target                       --����Ώۋ敪
                     );
        --
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
        );
        ov_retcode := cv_status_warn;
      END IF;
--
      ------------------------------------
      -- �i�ڃX�e�[�^�X�`�F�b�N
      ------------------------------------
      BEGIN
        SELECT flv.meaning  AS item_status
          INTO ov_item_status
          FROM fnd_lookup_values flv
         WHERE flv.language     = ct_user_lang
           AND flv.lookup_type  = cv_look_item_status
           AND flv.lookup_code  LIKE cv_look_item_sts_a01
           AND flv.meaning      = lv_item_status
           AND gd_process_date >= NVL( flv.start_date_active ,gd_process_date )
           AND gd_process_date <= NVL( flv.end_date_active ,gd_max_date )
           AND flv.enabled_flag = cv_enabled_flag_y
        ;
      EXCEPTION
        -- *** �擾�G���[�n���h�� ***
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => cv_xxcos_appl_short_name
                        ,iv_name          => cv_msg_item_sts_err
                        ,iv_token_name1   => cv_tkn_param1                         --�p�����[�^1(�g�[�N��)
                        ,iv_token_value1  => in_cnt                                --�s�ԍ�
                        ,iv_token_name2   => cv_tkn_param2                         --�p�����[�^2(�g�[�N��)
                        ,iv_token_value2  => iv_dlv_inv_num                        --�[�i�`�[�ԍ�
                        ,iv_token_name3   => cv_tkn_param3                         --�p�����[�^3(�g�[�N��)
                        ,iv_token_value3  => in_line_number                        --�sNo
                        ,iv_token_name4   => cv_tkn_param4                         --�p�����[�^4(�g�[�N��)
                        ,iv_token_value4  => ov_conv_item_code                     --�ϊ���i���R�[�h
                        ,iv_token_name5   => cv_tkn_key_data                       --�L�[���(�g�[�N��)
                        ,iv_token_value5  => lv_item_status                        --�i�ڃX�e�[�^�X
                       );
          --
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
          );
          ov_retcode := cv_status_warn;
      END;
--
    END IF;
--
-- Ver.1.2 ADD START
    -- ********************
    -- ***  ����ŋ敪  ***
    -- ********************
--
    BEGIN
      SELECT flv.attribute1   AS tax_class
        INTO lv_tax_class
        FROM fnd_lookup_values flv
       WHERE flv.language     = ct_user_lang
         AND flv.lookup_type  = cv_look_tax_class
         AND flv.attribute1   = iv_tax_class
         AND gd_process_date >= NVL( flv.start_date_active ,gd_process_date )
         AND gd_process_date <= NVL( flv.end_date_active ,gd_max_date )
         AND flv.enabled_flag = cv_enabled_flag_y
      ;
    EXCEPTION
     -- *** �擾�G���[�n���h�� ***
      WHEN NO_DATA_FOUND THEN
        --�L�[���̕ҏW����
        lv_tab_name := xxccp_common_pkg.get_msg(
                         iv_application => cv_xxcos_appl_short_name
                        ,iv_name        => cv_msg_lkp_code                       --�N�C�b�N�R�[�h
                       );
        lv_col_name := xxccp_common_pkg.get_msg(
                         iv_application => cv_xxcos_appl_short_name
                        ,iv_name        => cv_msg_tax_class                      --����ŋ敪
                       );
        --
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_xxcos_appl_short_name
                      ,iv_name          => cv_msg_mst_chk_err
                      ,iv_token_name1   => cv_tkn_param1                         --�p�����[�^1(�g�[�N��)
                      ,iv_token_value1  => in_cnt                                --�s�ԍ�
                      ,iv_token_name2   => cv_tkn_param2                         --�p�����[�^2(�g�[�N��)
                      ,iv_token_value2  => iv_dlv_inv_num                        --�[�i�`�[�ԍ�
                      ,iv_token_name3   => cv_tkn_param3                         --�p�����[�^3(�g�[�N��)
                      ,iv_token_value3  => in_line_number                        --�sNo
                      ,iv_token_name4   => cv_tkn_table                          --�e�[�u����(�g�[�N��)
                      ,iv_token_value4  => lv_tab_name                           --�e�[�u����
                      ,iv_token_name5   => cv_tkn_column                         --���ږ�(�g�[�N��)
                      ,iv_token_value5  => lv_col_name                           --���ږ�
                      ,iv_token_name6   => cv_tkn_param4                         --�p�����[�^4(�g�[�N��)
                      ,iv_token_value6  => iv_tax_class                          --����ŋ敪
                     );
        --
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg           --���[�U�[�E�G���[���b�Z�[�W
        );
        ov_retcode := cv_status_warn;
    END;
--
    --����ŋ敪���擾�ł���ꍇ
    IF ( lv_tax_class IS NOT NULL ) THEN
--
      ------------------------------------
      -- ����ŏ��擾
      ------------------------------------
      BEGIN
        -- ����ŋ敪����ېłł���ꍇ
        IF ( lv_tax_class = cv_tax_class_tax ) THEN
           SELECT xtv.tax_rate   AS tax_rate                -- ����ŗ�
                 ,xtv.tax_code   AS tax_code                -- ����ŃR�[�h
           INTO   on_tax_rate
                 ,ov_tax_code
           FROM   xxcos_tax_v  xtv
           WHERE  xtv.hht_tax_class  = cv_tax_class_tax
           AND xtv.set_of_books_id   = gn_bks_id
           AND id_delivery_date     >= NVL( xtv.start_date_active ,id_delivery_date )
           AND id_delivery_date     <= NVL( xtv.end_date_active ,gd_max_date )
           ;
-- Ver.1.3 INS START
           lv_retcode := cv_status_normal;
-- Ver.1.3 INS START
        -- 
        ELSE
        
          -- �i�ڕʏ���ŗ��擾�֐��R�[��
          xxcos_common_pkg.get_tax_rate_info(
            iv_item_code                    => ov_conv_item_code               -- �ϊ���i�ڃR�[�h
           ,id_base_date                    => id_delivery_date                -- ����i�[�i���j
           ,ov_class_for_variable_tax       => lv_class_for_variable_tax       -- �y���ŗ��p�Ŏ��
           ,ov_tax_name                     => lv_tax_name                     -- �ŗ��L�[����
           ,ov_tax_description              => lv_tax_description              -- �E�v
           ,ov_tax_histories_code           => lv_tax_histories_code           -- ����ŗ����R�[�h
           ,ov_tax_histories_description    => lv_tax_histories_description    -- ����ŗ��𖼏�
           ,od_start_date                   => ld_tax_start_date               -- �ŗ��L�[_�J�n��
           ,od_end_date                     => ld_tax_end_date                 -- �ŗ��L�[_�I����
           ,od_start_date_histories         => ld_tax_start_date_histories     -- ����ŗ���_�J�n��
           ,od_end_date_histories           => ld_tax_end_date_histories       -- ����ŗ���_�I����
           ,on_tax_rate                     => on_tax_rate                     -- �ŗ�
           ,ov_tax_class_suppliers_outside  => lv_tax_class_suppliers_outside  -- �ŋ敪_�d���O��
           ,ov_tax_class_suppliers_inside   => lv_tax_class_suppliers_inside   -- �ŋ敪_�d������
           ,ov_tax_class_sales_outside      => lv_tax_class_sales_outside      -- �ŋ敪_����O��
           ,ov_tax_class_sales_inside       => lv_tax_class_sales_inside       -- �ŋ敪_�������
           ,ov_errbuf                       => lv_errbuf                       -- �G���[�E���b�Z�[�W�G���[       #�Œ�#
           ,ov_retcode                      => lv_retcode                      -- ���^�[���E�R�[�h               #�Œ�#
           ,ov_errmsg                       => lv_errmsg                       -- ���[�U�[�E�G���[�E���b�Z�[�W   #�Œ�#
          );
          
        -- �ŋ��R�[�h�ݒ�
           CASE lv_tax_class WHEN cv_tax_class_out      THEN                 -- �O�ł̏ꍇ
                               ov_tax_code  := lv_tax_class_sales_outside;
                             WHEN cv_tax_class_ins_slip THEN                 -- ���Łi�`�[�ېŁj
                               ov_tax_code  := lv_tax_class_sales_inside;
                             WHEN cv_tax_class_ins_bid  THEN                 -- ���Łi�P�����݁j
                               ov_tax_code  := lv_tax_class_sales_inside;
                             ELSE NULL;
           END CASE;
          
        END IF;
        
        -- �߂�l�`�F�b�N(���ʊ֐�)
        IF ( lv_retcode = cv_status_error ) THEN
          --�G���[���b�Z�[�W�̕ҏW����
          lv_errmsg   := xxccp_common_pkg.get_msg(
                           iv_application   => cv_xxcos_appl_short_name
                          ,iv_name          => cv_msg_common_pkg_err
                          ,iv_token_name1   => cv_tkn_common
                          ,iv_token_value1  => in_cnt                                --�s�ԍ�
                          ,iv_token_name2   => cv_tkn_common_name
                          ,iv_token_value2  => cv_common_pkg_name                    --���ʊ֐���
                          ,iv_token_name3   => cv_tkn_common_info
                          ,iv_token_value3  => lv_errmsg                             --���ʊ֐��G���[���b�Z�[�W
                          );
          
          RAISE global_api_expt;
        
        ELSIF ( lv_retcode = cv_status_warn ) THEN
          --�L�[���̕ҏW����
          SELECT dtc.comments     AS view_name
          INTO   lv_tab_name
          FROM   dba_tab_comments  dtc
          WHERE  dtc.table_name = cv_view_name                           --XXCOS�i�ڕʏ���ŗ��r���[
          ;
          
          lv_col_name := xxccp_common_pkg.get_msg(
                           iv_application => cv_xxcos_appl_short_name
                          ,iv_name        => cv_msg_tax_rate                       --����ŗ�
                         );
--
          lv_errmsg   := xxccp_common_pkg.get_msg(
                           iv_application   => cv_xxcos_appl_short_name
                          ,iv_name          => cv_msg_null_or_get_data_err
                          ,iv_token_name1   => cv_tkn_param1                         --�p�����[�^1(�g�[�N��)
                          ,iv_token_value1  => in_cnt                                --�s�ԍ�
                          ,iv_token_name2   => cv_tkn_param2                         --�p�����[�^2(�g�[�N��)
                          ,iv_token_value2  => iv_dlv_inv_num                        --�[�i�`�[�ԍ�
                          ,iv_token_name3   => cv_tkn_param3                         --�p�����[�^3(�g�[�N��)
                          ,iv_token_value3  => in_line_number                        --�sNo
                          ,iv_token_name4   => cv_tkn_table                          --�e�[�u����(�g�[�N��)
                          ,iv_token_value4  => lv_tab_name                           --�e�[�u����
                          ,iv_token_name5   => cv_tkn_column                         --���ږ�(�g�[�N��)
                          ,iv_token_value5  => lv_col_name                           --���ږ�
                         );
--
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg                                                      --���[�U�[�E�G���[���b�Z�[�W
          );
          
          ov_retcode := cv_status_warn;
        
        END IF;
--
      EXCEPTION
        -- *** �擾�G���[�n���h�� ***
        WHEN NO_DATA_FOUND THEN
          --�L�[���̕ҏW����
          lv_tab_name := xxccp_common_pkg.get_msg(
                           iv_application => cv_xxcos_appl_short_name
                          ,iv_name        => cv_msg_lkp_code                       --�����view
                         );
          lv_col_name := xxccp_common_pkg.get_msg(
                           iv_application => cv_xxcos_appl_short_name
                          ,iv_name        => cv_msg_tax_rate                       --����ŗ�
                         );
          --
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => cv_xxcos_appl_short_name
                        ,iv_name          => cv_msg_null_or_get_data_err
                        ,iv_token_name1   => cv_tkn_param1                         --�p�����[�^1(�g�[�N��)
                        ,iv_token_value1  => in_cnt                                --�s�ԍ�
                        ,iv_token_name2   => cv_tkn_param2                         --�p�����[�^2(�g�[�N��)
                        ,iv_token_value2  => iv_dlv_inv_num                        --�[�i�`�[�ԍ�
                        ,iv_token_name3   => cv_tkn_param3                         --�p�����[�^3(�g�[�N��)
                        ,iv_token_value3  => in_line_number                        --�sNo
                        ,iv_token_name4   => cv_tkn_table                          --�e�[�u����(�g�[�N��)
                        ,iv_token_value4  => lv_tab_name                           --�e�[�u����
                        ,iv_token_name5   => cv_tkn_column                         --���ږ�(�g�[�N��)
                        ,iv_token_value5  => lv_col_name                           --���ږ�
                       );
          --
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
          );
          ov_retcode := cv_status_warn;
      END;
--
      BEGIN
        
        -- �i�ڕʏ���ŗ��擾�֐��Ōx���܂��ُ͈킪�������Ă��Ȃ��ꍇ
        IF ( lv_retcode NOT IN ( cv_status_error,cv_status_warn )) THEN
          -- �̔����јA�g����ŋ敪�̎擾
          SELECT xtv.tax_class  AS consumption_tax_class   -- �̔����јA�g����ŋ敪
            INTO ov_consumption_tax_class
            FROM xxcos_tax_v  xtv                          -- �����view
           WHERE xtv.hht_tax_class     = lv_tax_class
             AND xtv.set_of_books_id   = gn_bks_id
-- Ver.1.3 Del START
--             AND xtv.tax_rate          = on_tax_rate
-- Ver.1.3 Del END
             AND id_delivery_date     >= NVL( xtv.start_date_active ,id_delivery_date )
             AND id_delivery_date     <= NVL( xtv.end_date_active ,gd_max_date )
          ;
          
        END IF;
--
      EXCEPTION
        -- *** �擾�G���[�n���h�� ***
        WHEN NO_DATA_FOUND THEN
          --�L�[���̕ҏW����
          lv_tab_name := xxccp_common_pkg.get_msg(
                           iv_application => cv_xxcos_appl_short_name
                          ,iv_name        => cv_msg_lkp_code                       --�����view
                         );

          SELECT  dcc.comments       AS col_coment     -- ���ږ�
            INTO  lv_col_name
            FROM  dba_col_comments  dcc
           WHERE  dcc.table_name = cv_tax_view_txt
             AND  dcc.column_name = cv_tax_class_txt                                    --�̔����јA�g����ŋ敪
           ;
--
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => cv_xxcos_appl_short_name
                        ,iv_name          => cv_msg_null_or_get_data_err
                        ,iv_token_name1   => cv_tkn_param1                         --�p�����[�^1(�g�[�N��)
                        ,iv_token_value1  => in_cnt                                --�s�ԍ�
                        ,iv_token_name2   => cv_tkn_param2                         --�p�����[�^2(�g�[�N��)
                        ,iv_token_value2  => iv_dlv_inv_num                        --�[�i�`�[�ԍ�
                        ,iv_token_name3   => cv_tkn_param3                         --�p�����[�^3(�g�[�N��)
                        ,iv_token_value3  => in_line_number                        --�sNo
                        ,iv_token_name4   => cv_tkn_table                          --�e�[�u����(�g�[�N��)
                        ,iv_token_value4  => lv_tab_name                           --�e�[�u����
                        ,iv_token_name5   => cv_tkn_column                         --���ږ�(�g�[�N��)
                        ,iv_token_value5  => lv_col_name                           --���ږ�
                       );
          --
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
          );
          ov_retcode := cv_status_warn;
--
      END;
--
    END IF;
-- Ver.1.2 ADD START
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
  END get_master_data;
--
  /**********************************************************************************
   * Procedure Name   : security_check
   * Description      : �Z�L�����e�B�`�F�b�N����(A-7)
   ***********************************************************************************/
  PROCEDURE security_check(
     in_cnt                IN  NUMBER    -- �f�[�^�J�E���^
    ,iv_dlv_inv_num        IN  VARCHAR2  -- �[�i�`�[�ԍ�
    ,in_line_number        IN  NUMBER    -- ���הԍ�
    ,iv_customer_code      IN  VARCHAR2  -- �ڋq�R�[�h
    ,iv_sales_base_code    IN VARCHAR2   -- ���㋒�_�R�[�h
    ,ov_errbuf     OUT VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode    OUT VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg     OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'security_check'; -- �v���O������
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
    lv_key_info    VARCHAR2(5000);  --key���
    ln_flg         NUMBER;          --���[�J���t���O
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
    -- ������
    ln_flg := 0;
--
    <<sec_chk_loop>>
    FOR i IN 1 .. gr_g_login_base_info.COUNT LOOP
      IF ( gr_g_login_base_info(i) = iv_sales_base_code ) THEN
        ln_flg := 1;
      END IF;
    END LOOP sec_chk_loop;
--
    --���㋒�_�R�[�h�Ǝ����_�����Ⴀ��ꍇ
    IF ( ln_flg = 0 ) THEN
      RAISE global_security_check_expt;
    END IF;
--
  EXCEPTION
    -- *** �Z�L�����e�B�`�F�b�N�G���[�n���h�� ***
    WHEN global_security_check_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_xxcos_appl_short_name
                    ,iv_name          => cv_msg_security_chk_err
                    ,iv_token_name1   => cv_tkn_param1                         --�p�����[�^1(�g�[�N��)
                    ,iv_token_value1  => in_cnt                                --�s�ԍ�
                    ,iv_token_name2   => cv_tkn_param2                         --�p�����[�^2(�g�[�N��)
                    ,iv_token_value2  => iv_dlv_inv_num                        --�[�i�`�[�ԍ�
                    ,iv_token_name3   => cv_tkn_param3                         --�p�����[�^3(�g�[�N��)
                    ,iv_token_value3  => in_line_number                        --�sNo
                    ,iv_token_name4   => cv_tkn_param4                         --�p�����[�^4(�g�[�N��)
                    ,iv_token_value4  => iv_customer_code                      --�ϊ���ڋq�R�[�h
                    ,iv_token_name5   => cv_tkn_key_data                       --�L�[���(�g�[�N��)
                    ,iv_token_value5  => iv_sales_base_code                    --���㋒�_�R�[�h
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
  END security_check;
--
  /**********************************************************************************
   * Procedure Name   : set_sales_bp_data
   * Description      : �����̔����уf�[�^�ݒ菈��(A-8)
   ***********************************************************************************/
  PROCEDURE set_sales_bp_data(
     in_cnt                     IN  NUMBER      -- �f�[�^�J�E���^
    ,iv_bp_company_code         IN  VARCHAR2    -- �����R�[�h
    ,iv_dlv_inv_num             IN  VARCHAR2    -- �[�i�`�[�ԍ�
    ,iv_base_code               IN  VARCHAR2    -- ���_�R�[�h
    ,id_delivery_date           IN  DATE        -- �[�i��
    ,iv_card_sale_class         IN  VARCHAR2    -- �J�[�h���敪
    ,iv_customer_code           IN  VARCHAR2    -- �ɓ����ڋq�R�[�h
    ,iv_bp_customer_code        IN  VARCHAR2    -- �����ڋq�R�[�h
    ,iv_tax_class               IN  VARCHAR2    -- ����ŋ敪
    ,in_line_number             IN  NUMBER      -- ���הԍ�
    ,iv_item_code               IN  VARCHAR2    -- �ɓ����i���R�[�h
    ,iv_bp_item_code            IN  VARCHAR2    -- �����i���R�[�h
    ,in_dlv_qty                 IN  NUMBER      -- ����
    ,in_unit_price              IN  NUMBER      -- ���P��
    ,in_cash_and_card           IN  NUMBER      -- �����E�J�[�h���p�z
    ,id_data_created            IN  DATE        -- �f�[�^�쐬����
    ,iv_conv_customer_code      IN  VARCHAR2    -- �ϊ���ڋq�R�[�h
    ,iv_offset_cust_code        IN  VARCHAR2    -- ���E�p�ڋq�R�[�h
    ,iv_employee_number         IN  VARCHAR2    -- �S���c�ƈ�
    ,iv_conv_item_code          IN  VARCHAR2    -- �ϊ���i���R�[�h
    ,iv_item_status             IN  VARCHAR2    -- �i�ڃX�e�[�^�X
    ,ov_errbuf     OUT VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode    OUT VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg     OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_sales_bp_data'; -- �v���O������
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
    --�V�[�P���X�p
    lt_sales_bus_partners_id   xxcos_sales_bus_partners.sales_bus_partners_id%TYPE;     --�����̔�����ID
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
    ------------------------------------
    -- �����̔�����ID�擾
    ------------------------------------
    SELECT xxcos_sales_bus_partners_s01.NEXTVAL  AS sales_bus_partners_id
      INTO lt_sales_bus_partners_id
      FROM DUAL
    ;
    --�J�E���g
    gn_bp_cnt := gn_bp_cnt + 1;
--
  -- **************************************
  -- ***  �����̔����уf�[�^�ݒ菈��  ***
  -- **************************************
--
    gr_sales_bp_data(gn_bp_cnt).sales_bus_partners_id             := lt_sales_bus_partners_id;    --�����̔�����ID
    gr_sales_bp_data(gn_bp_cnt).bp_company_code                   := iv_bp_company_code;          --�����R�[�h
    gr_sales_bp_data(gn_bp_cnt).dlv_invoice_number                := iv_dlv_inv_num;              --�[�i�`�[�ԍ�
    gr_sales_bp_data(gn_bp_cnt).base_code                         := iv_base_code;                --���_�R�[�h
    gr_sales_bp_data(gn_bp_cnt).delivery_date                     := id_delivery_date;            --�[�i��
    gr_sales_bp_data(gn_bp_cnt).card_sale_class                   := iv_card_sale_class;          --�J�[�h���敪
    gr_sales_bp_data(gn_bp_cnt).customer_code                     := iv_customer_code;            --�ɓ����ڋq�R�[�h
    gr_sales_bp_data(gn_bp_cnt).bp_customer_code                  := iv_bp_customer_code;         --�����ڋq�R�[�h
    gr_sales_bp_data(gn_bp_cnt).tax_class                         := iv_tax_class;                --����ŋ敪
    gr_sales_bp_data(gn_bp_cnt).line_number                       := in_line_number;              --���הԍ�
    gr_sales_bp_data(gn_bp_cnt).item_code                         := iv_item_code;                --�ɓ����i���R�[�h
    gr_sales_bp_data(gn_bp_cnt).bp_item_code                      := iv_bp_item_code;             --�����i���R�[�h
    gr_sales_bp_data(gn_bp_cnt).dlv_qty                           := in_dlv_qty;                  --����
    gr_sales_bp_data(gn_bp_cnt).unit_price                        := in_unit_price;               --���P��
    gr_sales_bp_data(gn_bp_cnt).cash_and_card                     := in_cash_and_card;            --�����E�J�[�h���p�z
    gr_sales_bp_data(gn_bp_cnt).data_created                      := id_data_created;             --�f�[�^�쐬����
    gr_sales_bp_data(gn_bp_cnt).conv_customer_code                := iv_conv_customer_code;       --�ϊ���ڋq�R�[�h
    gr_sales_bp_data(gn_bp_cnt).offset_cust_code                  := iv_offset_cust_code;         --���E�p�ڋq�R�[�h
    gr_sales_bp_data(gn_bp_cnt).employee_number                   := iv_employee_number;          --�S���c�ƈ�
    gr_sales_bp_data(gn_bp_cnt).conv_item_code                    := iv_conv_item_code;           --�ϊ���i���R�[�h
    gr_sales_bp_data(gn_bp_cnt).item_status                       := iv_item_status;              --�i�ڃX�e�[�^�X
    gr_sales_bp_data(gn_bp_cnt).csv_file_name                     := gv_csv_file_name;            --CSV�t�@�C����
    gr_sales_bp_data(gn_bp_cnt).created_by                        := cn_created_by;               --�쐬��
    gr_sales_bp_data(gn_bp_cnt).creation_date                     := cd_creation_date;            --�쐬��
    gr_sales_bp_data(gn_bp_cnt).last_updated_by                   := cn_last_updated_by;          --�ŏI�X�V��
    gr_sales_bp_data(gn_bp_cnt).last_update_date                  := cd_last_update_date;         --�ŏI�X�V��
    gr_sales_bp_data(gn_bp_cnt).last_update_login                 := cn_last_update_login;        --�ŏI�X�V۸޲�
    gr_sales_bp_data(gn_bp_cnt).request_id                        := cn_request_id;               --�v��ID
    gr_sales_bp_data(gn_bp_cnt).program_application_id            := cn_program_application_id;   --�ݶ��ĥ��۸��ѥ���ع����ID
    gr_sales_bp_data(gn_bp_cnt).program_id                        := cn_program_id;               --�ݶ��ĥ��۸���ID
    gr_sales_bp_data(gn_bp_cnt).program_update_date               := cd_program_update_date;      --��۸��эX�V��
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
  END set_sales_bp_data;
--
  /**********************************************************************************
   * Procedure Name   : set_sales_data
   * Description      : �̔����уf�[�^�ݒ菈��(A-9)
   ***********************************************************************************/
  PROCEDURE set_sales_data(
     in_cnt                     IN  NUMBER      -- �f�[�^�J�E���^
    ,iv_bp_company_code         IN  VARCHAR2    -- �����R�[�h
    ,iv_dlv_inv_num             IN  VARCHAR2    -- �[�i�`�[�ԍ�
    ,iv_base_code               IN  VARCHAR2    -- ���_�R�[�h
    ,id_delivery_date           IN  DATE        -- �[�i��
    ,iv_card_sale_class         IN  VARCHAR2    -- �J�[�h���敪
    ,iv_customer_code           IN  VARCHAR2    -- �ڋq�R�[�h
    ,iv_tax_class               IN  VARCHAR2    -- ����ŋ敪
    ,in_line_number             IN  NUMBER      -- ���הԍ�
    ,iv_item_code               IN  VARCHAR2    -- �i���R�[�h
    ,in_dlv_qty                 IN  NUMBER      -- ����
    ,in_unit_price              IN  NUMBER      -- ���P��
    ,iv_sales_base_code         IN  VARCHAR2    -- ���㋒�_�R�[�h
    ,iv_receiv_base_code        IN  VARCHAR2    -- �������_�R�[�h
    ,iv_bill_tax_round_rule     IN  VARCHAR2    -- �ŋ��|�[������
    ,iv_offset_cust_code        IN  VARCHAR2    -- ���E�p�ڋq�R�[�h
    ,iv_results_employee_code   IN  VARCHAR2    -- ���ьv��҃R�[�h
    ,iv_cust_gyotai_sho         IN  VARCHAR2    -- �Ƒԁi�����ށj
    ,in_tax_rate                IN  NUMBER      -- ����ŗ�
    ,iv_tax_code                IN  VARCHAR2    -- �ŋ��R�[�h
    ,iv_consumption_tax_class   IN  VARCHAR2    -- ����ŋ敪
    ,iv_uom_code                IN  VARCHAR2    -- ��P��
    ,in_business_cost           IN  NUMBER      -- �c�ƌ���
    ,in_cash_and_card           IN  NUMBER      -- �����E�J�[�h���p�z
    ,ov_errbuf     OUT VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode    OUT VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg     OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_sales_data'; -- �v���O������
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
    ln_tax_data               NUMBER;                                                  --�ō��z�v�Z�p
    lt_sale_amount            xxcos_sales_exp_lines.sale_amount%TYPE;                  --������z
    lt_stand_unit_price_excl  xxcos_sales_exp_lines.standard_unit_price_excluded%TYPE; --�Ŕ���P��
    lt_pure_amount            xxcos_sales_exp_lines.pure_amount%TYPE;                  --�{�̋��z
    lt_tax_amount             xxcos_sales_exp_lines.tax_amount%TYPE;                   --����ŋ��z
    ln_amount                 NUMBER;                                                  --���z�v�Z�p�ϐ�
    lt_red_black_flag1        xxcos_sales_exp_lines.red_black_flag%TYPE;               --�ԍ��t���O
    lt_red_black_flag2        xxcos_sales_exp_lines.red_black_flag%TYPE;               --�ԍ��t���O�i���E�j
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
    -- ���[�J���ϐ��̏�����
    ln_tax_data               := 0;   --�ō��z�v�Z�p
    lt_sale_amount            := 0;   --������z
    lt_stand_unit_price_excl  := 0;   --�Ŕ���P��
    lt_pure_amount            := 0;   --�{�̋��z
    lt_tax_amount             := 0;   --����ŋ��z
--
    --���񃌃R�[�h�A�܂��͑O���R�[�h�Ǝ����R�[�h���[�i�`�[�ԍ����قȂ�ꍇ
    IF ( gt_bp_com_code IS NULL ) OR
       ( gt_bp_com_code != iv_bp_company_code ) OR
       ( gt_dlv_inv_num != iv_dlv_inv_num ) THEN
--
      --���z���v�̏�����
      gt_sale_amount_sum  := 0;  --������z���v
      gt_pure_amount_sum  := 0;  --�{�̋��z���v
      gt_tax_amount_sum   := 0;  --����ŋ��z���v
      ------------------------------------
      -- �̔����уw�b�_ID�擾
      ------------------------------------
      SELECT xxcos_sales_exp_headers_s01.NEXTVAL  AS sales_exp_header_id1
        INTO gt_sales_exp_header_id1
        FROM DUAL
      ;
      --
      SELECT xxcos_sales_exp_headers_s01.NEXTVAL  AS sales_exp_header_id2
        INTO gt_sales_exp_header_id2
        FROM DUAL
      ;
      --�w�b�_�J�E���g
      gn_hed_cnt1 := gn_hed_cnt1 + 1;
      gn_hed_cnt2 := gn_hed_cnt2 + 1;
--
      ------------------------------------
      -- �����[�i�`�[�ԍ��擾
      ------------------------------------
      SELECT xxcos_dlv_inv_num_os_s01.NEXTVAL  AS dlv_invoice_number_os
        INTO gt_dlv_invoice_number_os
        FROM DUAL
      ;
    END IF;
--
    ------------------------------------
    -- �̔����і���ID�擾
    ------------------------------------
    SELECT xxcos_sales_exp_lines_s01.NEXTVAL  AS sales_exp_line_id1
      INTO gt_sales_exp_line_id1
      FROM DUAL
    ;
    --
    SELECT xxcos_sales_exp_lines_s01.NEXTVAL  AS sales_exp_line_id2
      INTO gt_sales_exp_line_id2
      FROM DUAL
    ;
    --���׃J�E���g
    gn_line_cnt1 := gn_line_cnt1 + 1;
    gn_line_cnt2 := gn_line_cnt2 + 1;
--
    ------------------------------------
    --���׋��z�Z�o
    ------------------------------------
    --�ō��z�v�Z�p�ϐ��̃Z�b�g
    ln_tax_data := ( ( 100 + in_tax_rate ) / 100 );
--
    --����ŋ敪���u��ېŁv�̏ꍇ
    IF ( iv_tax_class = cv_tax_class_tax ) THEN
      --�y������z�z
      lt_sale_amount           := TRUNC( in_unit_price * in_dlv_qty );
      --�y�Ŕ���P���z
      lt_stand_unit_price_excl := in_unit_price;
      --�y�{�̋��z�z
      lt_pure_amount           := TRUNC( in_unit_price * in_dlv_qty );
      --�y����ŋ��z�z
      lt_tax_amount            := 0;
--
    --����ŋ敪���u�O�Łv�̏ꍇ
    ELSIF ( iv_tax_class = cv_tax_class_out ) THEN
--
      --�y������z�z
      lt_sale_amount           := TRUNC( in_unit_price * in_dlv_qty );
      --�y�Ŕ���P���z
      lt_stand_unit_price_excl := in_unit_price;
      --�y�{�̋��z�z
      lt_pure_amount           := TRUNC( in_unit_price * in_dlv_qty );
      --�y����ŋ��z�z
      lt_tax_amount            := ROUND( lt_pure_amount * ( ln_tax_data - 1 ) );
--
    --����ŋ敪���u���Łi�`�[�ېŁj�v�̏ꍇ
    ELSIF ( iv_tax_class = cv_tax_class_ins_slip ) THEN
--
      --�y������z�z
      lt_sale_amount           := TRUNC( in_unit_price * in_dlv_qty );
      --�y�Ŕ���P���z
      lt_stand_unit_price_excl := in_unit_price;
      --�y�{�̋��z�z
      lt_pure_amount           := TRUNC( in_unit_price * in_dlv_qty );
      --�y����ŋ��z�z
      lt_tax_amount            := ROUND( lt_pure_amount * ( ln_tax_data - 1 ) );
--
    --����ŋ敪���u���Łi�P�����݁j�v�̏ꍇ
    ELSIF ( iv_tax_class = cv_tax_class_ins_bid ) THEN
--
      --�y������z�z
      lt_sale_amount           := TRUNC( in_unit_price * in_dlv_qty );
      --�y�Ŕ���P���z
      lt_stand_unit_price_excl := ROUND( ( in_unit_price / ( 100 + in_tax_rate ) * 100 ) , 2 );
      --�y�{�̋��z�z
      --�{�̋��z�i���j
      ln_amount := ( in_unit_price * in_dlv_qty ) - ( ( in_unit_price * in_dlv_qty ) / ln_tax_data );
      --�{�̋��z�i���j�ɒ[��������ꍇ
      IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
        --�[�������敪���u�؂�グ�v�̏ꍇ
        IF ( iv_bill_tax_round_rule = cv_tax_rounding_rule_up ) THEN
          IF ( SIGN (ln_amount) <> -1 ) THEN
            lt_pure_amount     := TRUNC( ( in_unit_price * in_dlv_qty ) - ( TRUNC( ln_amount ) + 1 ) );
          ELSE
            lt_pure_amount     := TRUNC( ( in_unit_price * in_dlv_qty ) - ( TRUNC( ln_amount ) - 1 ) );
          END IF;
        --�[�������敪���u�؂�̂āv�̏ꍇ
        ELSIF ( iv_bill_tax_round_rule = cv_tax_rounding_rule_down ) THEN
          lt_pure_amount       := TRUNC( ( in_unit_price * in_dlv_qty ) - TRUNC( ln_amount ) );
        --�[�������敪���u�l�̌ܓ��v�̏ꍇ
        ELSIF ( iv_bill_tax_round_rule = cv_tax_rounding_rule_nearest ) THEN
          lt_pure_amount       := TRUNC( ( in_unit_price * in_dlv_qty ) - ROUND( ln_amount ) );
        END IF;
      --�{�̋��z�i���j�ɒ[�����Ȃ��ꍇ
      ELSE
        lt_pure_amount         := TRUNC( ( in_unit_price * in_dlv_qty ) - ln_amount );
      END IF;
      --�y����ŋ��z�z
      --����ŋ��z�i���j
      ln_amount := ( ( in_unit_price * in_dlv_qty ) /  ( ln_tax_data * 100 ) ) * in_tax_rate;
      --����ŋ��z�i���j�ɒ[��������ꍇ
      IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
        --�[�������敪���u�؂�グ�v�̏ꍇ
        IF ( iv_bill_tax_round_rule = cv_tax_rounding_rule_up ) THEN
          IF ( SIGN (ln_amount) <> -1 ) THEN
            lt_tax_amount      := TRUNC( ln_amount ) + 1;
          ELSE
            lt_tax_amount      := TRUNC( ln_amount ) - 1;
          END IF;
        --�[�������敪���u�؂�̂āv�̏ꍇ
        ELSIF ( iv_bill_tax_round_rule = cv_tax_rounding_rule_down ) THEN
          lt_tax_amount        := TRUNC( ln_amount );
        --�[�������敪���u�l�̌ܓ��v�̏ꍇ
        ELSIF ( iv_bill_tax_round_rule = cv_tax_rounding_rule_nearest ) THEN
          lt_tax_amount        := ROUND( ln_amount );
        END IF;
      --����ŋ��z�i���j�ɒ[�����Ȃ��ꍇ
      ELSE
        lt_tax_amount          := ln_amount;
      END IF;
--
    END IF;
--
    ------------------------------------
    --���׋��z���v
    ------------------------------------
    gt_sale_amount_sum         := gt_sale_amount_sum + lt_sale_amount;     --������z���v
    gt_pure_amount_sum         := gt_pure_amount_sum + lt_pure_amount;     --�{�̋��z���v
    gt_tax_amount_sum          := gt_tax_amount_sum  + lt_tax_amount;      --����ŋ��z���v
--
    ------------------------------------
    --�ԍ��t���O����
    ------------------------------------
    IF ( in_dlv_qty < 0 ) THEN
      lt_red_black_flag1       := cv_red_black_flag_r;  --�ԍ��t���O
      lt_red_black_flag2       := cv_red_black_flag_b;  --�ԍ��t���O�i���E�j
    ELSE
      lt_red_black_flag1       := cv_red_black_flag_b;  --�ԍ��t���O
      lt_red_black_flag2       := cv_red_black_flag_r;  --�ԍ��t���O�i���E�j
    END IF;
--
  -- ************************************
  -- ***  �̔����і��׃f�[�^�ݒ菈��  ***
  -- ************************************
--
    gr_sales_line_data1(gn_line_cnt1).sales_exp_line_id              := gt_sales_exp_line_id1;       --�̔����і���ID
    gr_sales_line_data1(gn_line_cnt1).sales_exp_header_id            := gt_sales_exp_header_id1;     --�̔����уw�b�_ID
    gr_sales_line_data1(gn_line_cnt1).dlv_invoice_number             := iv_dlv_inv_num;              --�[�i�`�[�ԍ�
    gr_sales_line_data1(gn_line_cnt1).dlv_invoice_line_number        := in_line_number;              --�[�i���הԍ�
    gr_sales_line_data1(gn_line_cnt1).order_invoice_line_number      := NULL;                        --�������הԍ�
    gr_sales_line_data1(gn_line_cnt1).sales_class                    := cv_sales_class_vd;           --����敪�FVD����
-- Ver.1.1 MOD START
--    gr_sales_line_data1(gn_line_cnt1).delivery_pattern_class         := NULL;                        --�[�i�`�ԋ敪
    gr_sales_line_data1(gn_line_cnt1).delivery_pattern_class         := gv_prf_bp_sales_dlv_ptn_cls; --�[�i�`�ԋ敪
-- Ver.1.1 MOD END
    gr_sales_line_data1(gn_line_cnt1).red_black_flag                 := lt_red_black_flag1;          --�ԍ��t���O
    gr_sales_line_data1(gn_line_cnt1).item_code                      := iv_item_code;                --�i�ڃR�[�h
    gr_sales_line_data1(gn_line_cnt1).dlv_qty                        := in_dlv_qty;                  --�[�i����
    gr_sales_line_data1(gn_line_cnt1).standard_qty                   := in_dlv_qty;                  --�����
    gr_sales_line_data1(gn_line_cnt1).dlv_uom_code                   := iv_uom_code;                 --�[�i�P��
    gr_sales_line_data1(gn_line_cnt1).standard_uom_code              := iv_uom_code;                 --��P��
    gr_sales_line_data1(gn_line_cnt1).dlv_unit_price                 := in_unit_price;               --�[�i�P��
    gr_sales_line_data1(gn_line_cnt1).standard_unit_price_excluded   := lt_stand_unit_price_excl;    --�Ŕ���P��
    gr_sales_line_data1(gn_line_cnt1).standard_unit_price            := in_unit_price;               --��P��
    gr_sales_line_data1(gn_line_cnt1).business_cost                  := in_business_cost;            --�c�ƌ���
    gr_sales_line_data1(gn_line_cnt1).sale_amount                    := lt_sale_amount;              --������z
    gr_sales_line_data1(gn_line_cnt1).pure_amount                    := lt_pure_amount;              --�{�̋��z
    gr_sales_line_data1(gn_line_cnt1).tax_amount                     := lt_tax_amount;               --����ŋ��z
-- Ver.1.2 ADD START
    gr_sales_line_data1(gn_line_cnt1).tax_code                       := iv_tax_code;                 --�ŋ��R�[�h
    gr_sales_line_data1(gn_line_cnt1).tax_rate                       := in_tax_rate;                 --����ŗ�
-- Ver.1.2 ADD END
    gr_sales_line_data1(gn_line_cnt1).cash_and_card                  := in_cash_and_card;            --�����E�J�[�h���p�z
    gr_sales_line_data1(gn_line_cnt1).ship_from_subinventory_code    := NULL;                        --�o�׌��ۊǏꏊ
    gr_sales_line_data1(gn_line_cnt1).delivery_base_code             := iv_sales_base_code;          --�[�i���_�R�[�h
    gr_sales_line_data1(gn_line_cnt1).hot_cold_class                 := NULL;                        --�g���b
    gr_sales_line_data1(gn_line_cnt1).column_no                      := NULL;                        --�R����No
    gr_sales_line_data1(gn_line_cnt1).sold_out_class                 := NULL;                        --���؋敪
    gr_sales_line_data1(gn_line_cnt1).sold_out_time                  := NULL;                        --���؎���
    gr_sales_line_data1(gn_line_cnt1).to_calculate_fees_flag         := cv_complete_flag_n;          --�萔���v�Z�C���^�t�F�[�X�σt���O�FN
    gr_sales_line_data1(gn_line_cnt1).unit_price_mst_flag            := cv_complete_flag_s;          --�P���}�X�^�쐬�σt���O�FS
    gr_sales_line_data1(gn_line_cnt1).inv_interface_flag             := cv_complete_flag_s;          --INV�C���^�t�F�[�X�σt���O�FS
    gr_sales_line_data1(gn_line_cnt1).goods_prod_cls                 := NULL;                        --�i�ڋ敪
    gr_sales_line_data1(gn_line_cnt1).created_by                     := cn_created_by;               --�쐬��
    gr_sales_line_data1(gn_line_cnt1).creation_date                  := cd_creation_date;            --�쐬��
    gr_sales_line_data1(gn_line_cnt1).last_updated_by                := cn_last_updated_by;          --�ŏI�X�V��
    gr_sales_line_data1(gn_line_cnt1).last_update_date               := cd_last_update_date;         --�ŏI�X�V��
    gr_sales_line_data1(gn_line_cnt1).last_update_login              := cn_last_update_login;        --�ŏI�X�V۸޲�
    gr_sales_line_data1(gn_line_cnt1).request_id                     := cn_request_id;               --�v��ID
    gr_sales_line_data1(gn_line_cnt1).program_application_id         := cn_program_application_id;   --�ݶ��ĥ��۸��ѥ���ع����ID
    gr_sales_line_data1(gn_line_cnt1).program_id                     := cn_program_id;               --�ݶ��ĥ��۸���ID
    gr_sales_line_data1(gn_line_cnt1).program_update_date            := cd_program_update_date;      --��۸��эX�V��
--
  -- ********************************************
  -- ***  �̔����і��׃f�[�^�i���E�j�ݒ菈��  ***
  -- ********************************************
--
    gr_sales_line_data2(gn_line_cnt2).sales_exp_line_id              := gt_sales_exp_line_id2;       --�̔����і���ID�i���E�j
    gr_sales_line_data2(gn_line_cnt2).sales_exp_header_id            := gt_sales_exp_header_id2;     --�̔����уw�b�_ID�i���E�j
    gr_sales_line_data2(gn_line_cnt2).dlv_invoice_number             := gt_dlv_invoice_number_os;    --�[�i�`�[�ԍ�
    gr_sales_line_data2(gn_line_cnt2).dlv_invoice_line_number        := in_line_number;              --�[�i���הԍ�
    gr_sales_line_data2(gn_line_cnt2).order_invoice_line_number      := NULL;                        --�������הԍ�
    gr_sales_line_data2(gn_line_cnt2).sales_class                    := cv_sales_class_vd;           --����敪�FVD����
-- Ver.1.1 MOD START
--    gr_sales_line_data2(gn_line_cnt2).delivery_pattern_class         := NULL;                        --�[�i�`�ԋ敪
    gr_sales_line_data2(gn_line_cnt2).delivery_pattern_class         := gv_prf_bp_sales_dlv_ptn_cls; --�[�i�`�ԋ敪
-- Ver.1.1 MOD END
    gr_sales_line_data2(gn_line_cnt2).red_black_flag                 := lt_red_black_flag2;          --�ԍ��t���O
    gr_sales_line_data2(gn_line_cnt2).item_code                      := iv_item_code;                --�i�ڃR�[�h
    gr_sales_line_data2(gn_line_cnt2).dlv_qty                        := in_dlv_qty * -1;             --�[�i����
    gr_sales_line_data2(gn_line_cnt2).standard_qty                   := in_dlv_qty * -1;             --�����
    gr_sales_line_data2(gn_line_cnt2).dlv_uom_code                   := iv_uom_code;                 --�[�i�P��
    gr_sales_line_data2(gn_line_cnt2).standard_uom_code              := iv_uom_code;                 --��P��
    gr_sales_line_data2(gn_line_cnt2).dlv_unit_price                 := in_unit_price;               --�[�i�P��
    gr_sales_line_data2(gn_line_cnt2).standard_unit_price_excluded   := lt_stand_unit_price_excl;    --�Ŕ���P��
    gr_sales_line_data2(gn_line_cnt2).standard_unit_price            := in_unit_price;               --��P��
    gr_sales_line_data2(gn_line_cnt2).business_cost                  := in_business_cost;            --�c�ƌ���
    gr_sales_line_data2(gn_line_cnt2).sale_amount                    := lt_sale_amount * -1;         --������z
    gr_sales_line_data2(gn_line_cnt2).pure_amount                    := lt_pure_amount * -1;         --�{�̋��z
    gr_sales_line_data2(gn_line_cnt2).tax_amount                     := lt_tax_amount * -1;          --����ŋ��z
-- Ver.1.2 ADD START
    gr_sales_line_data2(gn_line_cnt2).tax_code                       := iv_tax_code;                 --�ŋ��R�[�h
    gr_sales_line_data2(gn_line_cnt2).tax_rate                       := in_tax_rate;                 --����ŗ�
-- Ver.1.2 ADD END
    gr_sales_line_data2(gn_line_cnt2).cash_and_card                  := in_cash_and_card;            --�����E�J�[�h���p�z
    gr_sales_line_data2(gn_line_cnt2).ship_from_subinventory_code    := NULL;                        --�o�׌��ۊǏꏊ
    gr_sales_line_data2(gn_line_cnt2).delivery_base_code             := iv_sales_base_code;          --�[�i���_�R�[�h
    gr_sales_line_data2(gn_line_cnt2).hot_cold_class                 := NULL;                        --�g���b
    gr_sales_line_data2(gn_line_cnt2).column_no                      := NULL;                        --�R����No
    gr_sales_line_data2(gn_line_cnt2).sold_out_class                 := NULL;                        --���؋敪
    gr_sales_line_data2(gn_line_cnt2).sold_out_time                  := NULL;                        --���؎���
    gr_sales_line_data2(gn_line_cnt2).to_calculate_fees_flag         := cv_complete_flag_y;          --�萔���v�Z�C���^�t�F�[�X�σt���O�FY
    gr_sales_line_data2(gn_line_cnt2).unit_price_mst_flag            := cv_complete_flag_s;          --�P���}�X�^�쐬�σt���O�FS
    gr_sales_line_data2(gn_line_cnt2).inv_interface_flag             := cv_complete_flag_s;          --INV�C���^�t�F�[�X�σt���O�FS
    gr_sales_line_data2(gn_line_cnt2).goods_prod_cls                 := NULL;                        --�i�ڋ敪
    gr_sales_line_data2(gn_line_cnt2).created_by                     := cn_created_by;               --�쐬��
    gr_sales_line_data2(gn_line_cnt2).creation_date                  := cd_creation_date;            --�쐬��
    gr_sales_line_data2(gn_line_cnt2).last_updated_by                := cn_last_updated_by;          --�ŏI�X�V��
    gr_sales_line_data2(gn_line_cnt2).last_update_date               := cd_last_update_date;         --�ŏI�X�V��
    gr_sales_line_data2(gn_line_cnt2).last_update_login              := cn_last_update_login;        --�ŏI�X�V۸޲�
    gr_sales_line_data2(gn_line_cnt2).request_id                     := cn_request_id;               --�v��ID
    gr_sales_line_data2(gn_line_cnt2).program_application_id         := cn_program_application_id;   --�ݶ��ĥ��۸��ѥ���ع����ID
    gr_sales_line_data2(gn_line_cnt2).program_id                     := cn_program_id;               --�ݶ��ĥ��۸���ID
    gr_sales_line_data2(gn_line_cnt2).program_update_date            := cd_program_update_date;      --��۸��эX�V��
--
    --���񃌃R�[�h�A�܂��͑O���R�[�h�Ǝ����R�[�h���[�i�`�[�ԍ����قȂ�ꍇ
    IF ( gt_bp_com_code IS NULL ) OR
       ( gt_bp_com_code != iv_bp_company_code ) OR
       ( gt_dlv_inv_num != iv_dlv_inv_num ) THEN
--
  -- **************************************
  -- ***  �̔����уw�b�_�f�[�^�ݒ菈��  ***
  -- **************************************
--
      gr_sales_head_data1(gn_hed_cnt1).sales_exp_header_id           := gt_sales_exp_header_id1;     --�̔����уw�b�_ID
      gr_sales_head_data1(gn_hed_cnt1).dlv_invoice_number            := iv_dlv_inv_num;              --�[�i�`�[�ԍ�
      gr_sales_head_data1(gn_hed_cnt1).order_invoice_number          := NULL;                        --�����`�[�ԍ�
      gr_sales_head_data1(gn_hed_cnt1).order_number                  := NULL;                        --�󒍔ԍ�
      gr_sales_head_data1(gn_hed_cnt1).order_no_hht                  := NULL;                        --��No�iHHT)
      gr_sales_head_data1(gn_hed_cnt1).digestion_ln_number           := NULL;                        --�[�i�`�[�ԍ��}��
      gr_sales_head_data1(gn_hed_cnt1).order_connection_number       := NULL;                        --�󒍊֘A�ԍ�
      gr_sales_head_data1(gn_hed_cnt1).dlv_invoice_class             := cv_dlv_inv_cls_dlv;          --�[�i�`�[�敪�F�[�i
      gr_sales_head_data1(gn_hed_cnt1).cancel_correct_class          := NULL;                        --����E�����敪
      gr_sales_head_data1(gn_hed_cnt1).input_class                   := NULL;                        --���͋敪
      gr_sales_head_data1(gn_hed_cnt1).cust_gyotai_sho               := iv_cust_gyotai_sho;          --�Ƒԏ�����
      gr_sales_head_data1(gn_hed_cnt1).delivery_date                 := id_delivery_date;            --�[�i��
      gr_sales_head_data1(gn_hed_cnt1).orig_delivery_date            := id_delivery_date;            --�I���W�i���[�i��
      gr_sales_head_data1(gn_hed_cnt1).inspect_date                  := id_delivery_date;            --������
      gr_sales_head_data1(gn_hed_cnt1).orig_inspect_date             := id_delivery_date;            --�I���W�i��������
      gr_sales_head_data1(gn_hed_cnt1).ship_to_customer_code         := iv_customer_code;            --�ڋq�y�[�i��z
      gr_sales_head_data1(gn_hed_cnt1).consumption_tax_class         := iv_consumption_tax_class;    --����ŋ敪
      gr_sales_head_data1(gn_hed_cnt1).tax_code                      := iv_tax_code;                 --�ŋ��R�[�h
      gr_sales_head_data1(gn_hed_cnt1).tax_rate                      := in_tax_rate;                 --����ŗ�
      gr_sales_head_data1(gn_hed_cnt1).results_employee_code         := iv_results_employee_code;    --���ьv��҃R�[�h
      gr_sales_head_data1(gn_hed_cnt1).sales_base_code               := iv_sales_base_code;          --���㋒�_�R�[�h
      gr_sales_head_data1(gn_hed_cnt1).receiv_base_code              := iv_receiv_base_code;         --�������_�R�[�h
      gr_sales_head_data1(gn_hed_cnt1).order_source_id               := NULL;                        --�󒍃\�[�XID
      gr_sales_head_data1(gn_hed_cnt1).card_sale_class               := iv_card_sale_class;          --�J�[�h���敪
      gr_sales_head_data1(gn_hed_cnt1).invoice_class                 := NULL;                        --�`�[�敪
      gr_sales_head_data1(gn_hed_cnt1).invoice_classification_code   := NULL;                        --�`�[���ރR�[�h
      gr_sales_head_data1(gn_hed_cnt1).change_out_time_100           := NULL;                        --��K�؂ꎞ�ԂP�O�O�~
      gr_sales_head_data1(gn_hed_cnt1).change_out_time_10            := NULL;                        --��K�؂ꎞ�ԂP�O�~
      gr_sales_head_data1(gn_hed_cnt1).ar_interface_flag             := cv_complete_flag_s;          --AR�C���^�t�F�[�X�σt���O�FS
      gr_sales_head_data1(gn_hed_cnt1).gl_interface_flag             := cv_complete_flag_s;          --GL�C���^�t�F�[�X�σt���O�FS
      gr_sales_head_data1(gn_hed_cnt1).dwh_interface_flag            := cv_complete_flag_n;          --���V�X�e���C���^�t�F�[�X�σt���O�FN
      gr_sales_head_data1(gn_hed_cnt1).edi_interface_flag            := cv_complete_flag_s;          --EDI���M�ς݃t���O�FS
      gr_sales_head_data1(gn_hed_cnt1).edi_send_date                 := NULL;                        --EDI���M����
      gr_sales_head_data1(gn_hed_cnt1).hht_dlv_input_date            := NULL;                        --HHT�[�i���͓���
      gr_sales_head_data1(gn_hed_cnt1).dlv_by_code                   := NULL;                        --�[�i�҃R�[�h
      gr_sales_head_data1(gn_hed_cnt1).create_class                  := cv_create_cls_sls_upload;    --�쐬���敪�FCSV�f�[�^�A�b�v���[�h�i�̔����сj
      gr_sales_head_data1(gn_hed_cnt1).business_date                 := gd_process_date;             --�o�^�Ɩ����t
      gr_sales_head_data1(gn_hed_cnt1).head_sales_branch             := NULL;                        --�Ǌ����_
      gr_sales_head_data1(gn_hed_cnt1).item_sales_send_flag          := cv_complete_flag_y;          --���i�ʔ̔����ё��M�σt���O�FY
      gr_sales_head_data1(gn_hed_cnt1).item_sales_send_date          := gd_process_date;             --���i�ʔ̔����ё��M��
      gr_sales_head_data1(gn_hed_cnt1).total_sales_amt               := cn_amt_dummy;                --���̔����z
      gr_sales_head_data1(gn_hed_cnt1).cash_total_sales_amt          := cn_amt_dummy;                --��������g�[�^���̔����z
      gr_sales_head_data1(gn_hed_cnt1).ppcard_total_sales_amt        := cn_amt_dummy;                --PP�J�[�h�g�[�^���̔����z
      gr_sales_head_data1(gn_hed_cnt1).idcard_total_sales_amt        := cn_amt_dummy;                --ID�J�[�h�g�[�^���̔����z
      gr_sales_head_data1(gn_hed_cnt1).hht_received_flag             := cv_hht_rcv_flag_n;           --HHT��M�t���O
      gr_sales_head_data1(gn_hed_cnt1).created_by                    := cn_created_by;               --�쐬��
      gr_sales_head_data1(gn_hed_cnt1).creation_date                 := cd_creation_date;            --�쐬��
      gr_sales_head_data1(gn_hed_cnt1).last_updated_by               := cn_last_updated_by;          --�ŏI�X�V��
      gr_sales_head_data1(gn_hed_cnt1).last_update_date              := cd_last_update_date;         --�ŏI�X�V��
      gr_sales_head_data1(gn_hed_cnt1).last_update_login             := cn_last_update_login;        --�ŏI�X�V۸޲�
      gr_sales_head_data1(gn_hed_cnt1).request_id                    := cn_request_id;               --�v��ID
      gr_sales_head_data1(gn_hed_cnt1).program_application_id        := cn_program_application_id;   --�ݶ��ĥ��۸��ѥ���ع����ID
      gr_sales_head_data1(gn_hed_cnt1).program_id                    := cn_program_id;               --�ݶ��ĥ��۸���ID
      gr_sales_head_data1(gn_hed_cnt1).program_update_date           := cd_program_update_date;      --��۸��эX�V��
--
  -- **********************************************
  -- ***  �̔����уw�b�_�f�[�^�i���E�j�ݒ菈��  ***
  -- **********************************************
--
      gr_sales_head_data2(gn_hed_cnt2).sales_exp_header_id           := gt_sales_exp_header_id2;     --�̔����уw�b�_ID�i���E�j
      gr_sales_head_data2(gn_hed_cnt2).dlv_invoice_number            := gt_dlv_invoice_number_os;    --�[�i�`�[�ԍ�
      gr_sales_head_data2(gn_hed_cnt2).order_invoice_number          := NULL;                        --�����`�[�ԍ�
      gr_sales_head_data2(gn_hed_cnt2).order_number                  := NULL;                        --�󒍔ԍ�
      gr_sales_head_data2(gn_hed_cnt2).order_no_hht                  := NULL;                        --��No�iHHT)
      gr_sales_head_data2(gn_hed_cnt2).digestion_ln_number           := NULL;                        --�[�i�`�[�ԍ��}��
      gr_sales_head_data2(gn_hed_cnt2).order_connection_number       := NULL;                        --�󒍊֘A�ԍ�
      gr_sales_head_data2(gn_hed_cnt2).dlv_invoice_class             := cv_dlv_inv_cls_dlv;          --�[�i�`�[�敪�F�[�i
      gr_sales_head_data2(gn_hed_cnt2).cancel_correct_class          := NULL;                        --����E�����敪
      gr_sales_head_data2(gn_hed_cnt2).input_class                   := NULL;                        --���͋敪
      gr_sales_head_data2(gn_hed_cnt2).cust_gyotai_sho               := iv_cust_gyotai_sho;          --�Ƒԏ�����
      gr_sales_head_data2(gn_hed_cnt2).delivery_date                 := id_delivery_date;            --�[�i��
      gr_sales_head_data2(gn_hed_cnt2).orig_delivery_date            := id_delivery_date;            --�I���W�i���[�i��
      gr_sales_head_data2(gn_hed_cnt2).inspect_date                  := id_delivery_date;            --������
      gr_sales_head_data2(gn_hed_cnt2).orig_inspect_date             := id_delivery_date;            --�I���W�i��������
      gr_sales_head_data2(gn_hed_cnt2).ship_to_customer_code         := iv_offset_cust_code;         --�ڋq�y�[�i��z
      gr_sales_head_data2(gn_hed_cnt2).consumption_tax_class         := iv_consumption_tax_class;    --����ŋ敪
      gr_sales_head_data2(gn_hed_cnt2).tax_code                      := iv_tax_code;                 --�ŋ��R�[�h
      gr_sales_head_data2(gn_hed_cnt2).tax_rate                      := in_tax_rate;                 --����ŗ�
      gr_sales_head_data2(gn_hed_cnt2).results_employee_code         := iv_results_employee_code;    --���ьv��҃R�[�h
      gr_sales_head_data2(gn_hed_cnt2).sales_base_code               := iv_sales_base_code;          --���㋒�_�R�[�h
      gr_sales_head_data2(gn_hed_cnt2).receiv_base_code              := iv_receiv_base_code;         --�������_�R�[�h
      gr_sales_head_data2(gn_hed_cnt2).order_source_id               := NULL;                        --�󒍃\�[�XID
      gr_sales_head_data2(gn_hed_cnt2).card_sale_class               := iv_card_sale_class;          --�J�[�h���敪
      gr_sales_head_data2(gn_hed_cnt2).invoice_class                 := NULL;                        --�`�[�敪
      gr_sales_head_data2(gn_hed_cnt2).invoice_classification_code   := NULL;                        --�`�[���ރR�[�h
      gr_sales_head_data2(gn_hed_cnt2).change_out_time_100           := NULL;                        --��K�؂ꎞ�ԂP�O�O�~
      gr_sales_head_data2(gn_hed_cnt2).change_out_time_10            := NULL;                        --��K�؂ꎞ�ԂP�O�~
      gr_sales_head_data2(gn_hed_cnt2).ar_interface_flag             := cv_complete_flag_s;          --AR�C���^�t�F�[�X�σt���O�FS
      gr_sales_head_data2(gn_hed_cnt2).gl_interface_flag             := cv_complete_flag_s;          --GL�C���^�t�F�[�X�σt���O�FS
      gr_sales_head_data2(gn_hed_cnt2).dwh_interface_flag            := cv_complete_flag_n;          --���V�X�e���C���^�t�F�[�X�σt���O�FN
      gr_sales_head_data2(gn_hed_cnt2).edi_interface_flag            := cv_complete_flag_s;          --EDI���M�ς݃t���O�FS
      gr_sales_head_data2(gn_hed_cnt2).edi_send_date                 := NULL;                        --EDI���M����
      gr_sales_head_data2(gn_hed_cnt2).hht_dlv_input_date            := NULL;                        --HHT�[�i���͓���
      gr_sales_head_data2(gn_hed_cnt2).dlv_by_code                   := NULL;                        --�[�i�҃R�[�h
      gr_sales_head_data2(gn_hed_cnt2).create_class                  := cv_create_cls_sls_upload;    --�쐬���敪�FCSV�f�[�^�A�b�v���[�h�i�̔����сj
      gr_sales_head_data2(gn_hed_cnt2).business_date                 := gd_process_date;             --�o�^�Ɩ����t
      gr_sales_head_data2(gn_hed_cnt2).head_sales_branch             := NULL;                        --�Ǌ����_
      gr_sales_head_data2(gn_hed_cnt2).item_sales_send_flag          := cv_complete_flag_y;          --���i�ʔ̔����ё��M�σt���O�FY
      gr_sales_head_data2(gn_hed_cnt2).item_sales_send_date          := gd_process_date;             --���i�ʔ̔����ё��M��
      gr_sales_head_data2(gn_hed_cnt2).total_sales_amt               := cn_amt_dummy;                --���̔����z
      gr_sales_head_data2(gn_hed_cnt2).cash_total_sales_amt          := cn_amt_dummy;                --��������g�[�^���̔����z
      gr_sales_head_data2(gn_hed_cnt2).ppcard_total_sales_amt        := cn_amt_dummy;                --PP�J�[�h�g�[�^���̔����z
      gr_sales_head_data2(gn_hed_cnt2).idcard_total_sales_amt        := cn_amt_dummy;                --ID�J�[�h�g�[�^���̔����z
      gr_sales_head_data2(gn_hed_cnt2).hht_received_flag             := cv_hht_rcv_flag_n;           --HHT��M�t���O
      gr_sales_head_data2(gn_hed_cnt2).created_by                    := cn_created_by;               --�쐬��
      gr_sales_head_data2(gn_hed_cnt2).creation_date                 := cd_creation_date;            --�쐬��
      gr_sales_head_data2(gn_hed_cnt2).last_updated_by               := cn_last_updated_by;          --�ŏI�X�V��
      gr_sales_head_data2(gn_hed_cnt2).last_update_date              := cd_last_update_date;         --�ŏI�X�V��
      gr_sales_head_data2(gn_hed_cnt2).last_update_login             := cn_last_update_login;        --�ŏI�X�V۸޲�
      gr_sales_head_data2(gn_hed_cnt2).request_id                    := cn_request_id;               --�v��ID
      gr_sales_head_data2(gn_hed_cnt2).program_application_id        := cn_program_application_id;   --�ݶ��ĥ��۸��ѥ���ع����ID
      gr_sales_head_data2(gn_hed_cnt2).program_id                    := cn_program_id;               --�ݶ��ĥ��۸���ID
      gr_sales_head_data2(gn_hed_cnt2).program_update_date           := cd_program_update_date;      --��۸��эX�V��
--
    END IF;
--
    ------------------------------------
    --���׋��z���v���Z�b�g
    ------------------------------------
    --�̔����уf�[�^
    gr_sales_head_data1(gn_hed_cnt1).sale_amount_sum                 := gt_sale_amount_sum;          --������z���v
    gr_sales_head_data1(gn_hed_cnt1).pure_amount_sum                 := gt_pure_amount_sum;          --�{�̋��z���v
    gr_sales_head_data1(gn_hed_cnt1).tax_amount_sum                  := gt_tax_amount_sum;           --����ŋ��z���v
    --�̔����уf�[�^�i���E�j
    gr_sales_head_data2(gn_hed_cnt2).sale_amount_sum                 := gt_sale_amount_sum * -1;     --������z���v
    gr_sales_head_data2(gn_hed_cnt2).pure_amount_sum                 := gt_pure_amount_sum * -1;     --�{�̋��z���v
    gr_sales_head_data2(gn_hed_cnt2).tax_amount_sum                  := gt_tax_amount_sum * -1;      --����ŋ��z���v
--
    --�ꎞ�i�[�p�ϐ��ɃZ�b�g
    gt_bp_com_code := iv_bp_company_code;
    gt_dlv_inv_num := iv_dlv_inv_num;
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
  END set_sales_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_sales_bp_data
   * Description      : �����̔����уf�[�^�o�^����(A-10)
   ***********************************************************************************/
  PROCEDURE ins_sales_bp_data(
     ov_errbuf     OUT VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode    OUT VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg     OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_sales_bp_data'; -- �v���O������
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
    ln_i          NUMBER;           --�J�E���^
    lv_tab_name   VARCHAR2(100);    --�e�[�u����
    ln_cnt        NUMBER;
    lv_key_info   VARCHAR2(100);    --�L�[���
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
    -- ********************************
    -- ***  �����̔����ѓo�^����  ***
    -- ********************************
--
    BEGIN
      FORALL ln_i in 1..gr_sales_bp_data.COUNT SAVE EXCEPTIONS
        INSERT INTO xxcos_sales_bus_partners
          VALUES gr_sales_bp_data(ln_i)
        ;
      --�����J�E���g
      gn_hed_suc_cnt := SQL%ROWCOUNT;
    EXCEPTION
      WHEN OTHERS THEN
        --�L�[���̕ҏW����
        lv_tab_name := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcos_appl_short_name
                       ,iv_name         => cv_msg_sales_bp
                     );
        lv_key_info := SQLERRM;
       RAISE global_ins_sales_data_expt;
     END;
--
  EXCEPTION
    -- *** ���R�[�h�o�^��O�n���h�� ***
    WHEN global_ins_sales_data_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application        => cv_xxcos_appl_short_name
                     ,iv_name               => cv_msg_insert_data_err
                     ,iv_token_name1        => cv_tkn_table_name
                     ,iv_token_value1       => lv_tab_name
                     ,iv_token_name2        => cv_tkn_key_data
                     ,iv_token_value2       => lv_key_info
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
  END ins_sales_bp_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_sales_data
   * Description      : �̔����уf�[�^�o�^����(A-11)
   ***********************************************************************************/
  PROCEDURE ins_sales_data(
     ov_errbuf     OUT VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode    OUT VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg     OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_sales_data'; -- �v���O������
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
    ln_i          NUMBER;           --�J�E���^
    lv_tab_name   VARCHAR2(100);    --�e�[�u����
    ln_cnt        NUMBER;
    lv_key_info   VARCHAR2(100);    --�L�[���
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
    -- ****************************************
    -- ***  �̔����уw�b�_�e�[�u���o�^����  ***
    -- ****************************************
--
    BEGIN
      FORALL ln_i IN 1..gr_sales_head_data1.COUNT SAVE EXCEPTIONS
        INSERT INTO xxcos_sales_exp_headers
          VALUES gr_sales_head_data1(ln_i)
        ;
      --�����J�E���g
      gn_hed_suc_cnt := SQL%ROWCOUNT;
    EXCEPTION
      WHEN OTHERS THEN
        --�L�[���̕ҏW����
        lv_tab_name := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcos_appl_short_name
                       ,iv_name         => cv_msg_sales_head
                     );
        lv_key_info := SQLERRM;
       RAISE global_ins_sales_data_expt;
     END;
--
    -- **************************************
    -- ***  �̔����і��׃e�[�u���o�^����  ***
    -- **************************************
--
    BEGIN
      FORALL ln_i IN 1..gr_sales_line_data1.COUNT
        INSERT INTO xxcos_sales_exp_lines
          VALUES gr_sales_line_data1(ln_i)
        ;
      --�����J�E���g
      gn_line_suc_cnt := SQL%ROWCOUNT;
    EXCEPTION
      WHEN OTHERS THEN
        --�L�[���̕ҏW����
        lv_tab_name := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcos_appl_short_name
                       ,iv_name         => cv_msg_sales_line
                     );
        lv_key_info := SQLERRM;
       RAISE global_ins_sales_data_expt;
    END;
--
    -- ************************************************
    -- ***  �̔����уw�b�_�e�[�u���o�^�����i���E�j  ***
    -- ************************************************
--
    BEGIN
      FORALL ln_i IN 1..gr_sales_head_data2.COUNT SAVE EXCEPTIONS
        INSERT INTO xxcos_sales_exp_headers
          VALUES gr_sales_head_data2(ln_i)
        ;
      --�����J�E���g
      gn_hed_suc_cnt := SQL%ROWCOUNT;
    EXCEPTION
      WHEN OTHERS THEN
        --�L�[���̕ҏW����
        lv_tab_name := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcos_appl_short_name
                       ,iv_name         => cv_msg_sales_head
                     );
        lv_key_info := SQLERRM;
       RAISE global_ins_sales_data_expt;
     END;
--
    -- **********************************************
    -- ***  �̔����і��׃e�[�u���o�^�����i���E�j  ***
    -- **********************************************
--
    BEGIN
      FORALL ln_i IN 1..gr_sales_line_data2.COUNT
        INSERT INTO xxcos_sales_exp_lines
          VALUES gr_sales_line_data2(ln_i)
        ;
      --�����J�E���g
      gn_line_suc_cnt := SQL%ROWCOUNT;
    EXCEPTION
      WHEN OTHERS THEN
        --�L�[���̕ҏW����
        lv_tab_name := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcos_appl_short_name
                       ,iv_name         => cv_msg_sales_line
                     );
        lv_key_info := SQLERRM;
       RAISE global_ins_sales_data_expt;
    END;
--
  EXCEPTION
    -- *** ���R�[�h�o�^��O�n���h�� ***
    WHEN global_ins_sales_data_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application        => cv_xxcos_appl_short_name
                     ,iv_name               => cv_msg_insert_data_err
                     ,iv_token_name1        => cv_tkn_table_name
                     ,iv_token_value1       => lv_tab_name
                     ,iv_token_name2        => cv_tkn_key_data
                     ,iv_token_value2       => lv_key_info
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
  END ins_sales_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
     in_get_file_id    IN  NUMBER    -- �t�@�C��ID
    ,iv_get_format_pat IN  VARCHAR2  -- �t�H�[�}�b�g�p�^�[��
    ,ov_errbuf     OUT VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode    OUT VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg     OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    ln_cnt           NUMBER;        -- �J�E���^
    lv_ret_status    VARCHAR2(1);   -- ���^�[���E�X�e�[�^�X
--
    --�擾�l�̊i�[�ϐ�
    lv_bp_company_code        VARCHAR2(9);                                         -- �����R�[�h
    lt_dlv_inv_num            xxcos_sales_exp_headers.dlv_invoice_number%TYPE;     -- �[�i�`�[�ԍ�
    lt_base_code              xxcos_sales_exp_headers.sales_base_code%TYPE;        -- ���_�R�[�h
    lt_delivery_date          xxcos_sales_exp_headers.delivery_date%TYPE;          -- �[�i��
    lt_card_sale_class        xxcos_sales_exp_headers.card_sale_class%TYPE;        -- �J�[�h���敪
    lt_customer_code          xxcos_sales_exp_headers.ship_to_customer_code%TYPE;  -- �ɓ����ڋq�R�[�h
    lv_bp_customer_code       VARCHAR2(15);                                        -- �����ڋq�R�[�h
    lt_conv_customer_code     xxcos_sales_exp_headers.ship_to_customer_code%TYPE;  -- �ϊ���ڋq�R�[�h
    lt_tax_class              xxcos_sales_exp_headers.consumption_tax_class%TYPE;  -- ����ŋ敪
    lt_line_number            xxcos_sales_exp_lines.dlv_invoice_line_number%TYPE;  -- ���הԍ�
    lt_item_code              xxcos_sales_exp_lines.item_code%TYPE;                -- �ɓ����i���R�[�h
    lv_bp_item_code           VARCHAR2(15);                                        -- �����i���R�[�h
    lt_conv_item_code         xxcos_sales_exp_lines.item_code%TYPE;                -- �ϊ���i���R�[�h
    lv_item_status            VARCHAR2(2);                                         -- �i�ڃX�e�[�^�X
    lt_dlv_qty                xxcos_sales_exp_lines.dlv_qty%TYPE;                  -- ����
    lt_unit_price             xxcos_sales_exp_lines.dlv_unit_price%TYPE;           -- ���P��
    lt_cash_and_card          xxcos_sales_exp_lines.cash_and_card%TYPE;            -- �����E�J�[�h���p�z
    lt_sales_base_code        xxcos_sales_exp_headers.sales_base_code%TYPE;        -- ���㋒�_�R�[�h
    lt_receiv_base_code       xxcos_sales_exp_headers.receiv_base_code%TYPE;       -- �������_�R�[�h
    lt_bill_tax_round_rule    xxcos_cust_hierarchy_v.bill_tax_round_rule%TYPE;     -- �ŋ��|�[������
    lt_offset_cust_code       xxcos_sales_exp_headers.ship_to_customer_code%TYPE;  -- ���E�p�ڋq�R�[�h
    lt_results_employee_code  xxcos_sales_exp_headers.results_employee_code%TYPE;  -- ���ьv��҃R�[�h
    lt_cust_gyotai_sho        xxcos_sales_exp_headers.cust_gyotai_sho%TYPE;        -- �Ƒԁi�����ށj
    lt_tax_rate               xxcos_sales_exp_headers.tax_rate%TYPE;               -- ����ŗ�
    lt_tax_code               xxcos_sales_exp_headers.tax_code%TYPE;               -- �ŋ��R�[�h
    lt_consumption_tax_class  xxcos_sales_exp_headers.consumption_tax_class%TYPE;  -- ����ŋ敪
    lt_uom_code               xxcos_sales_exp_lines.standard_uom_code%TYPE;        -- ��P��
    lt_business_cost          xxcos_sales_exp_lines.business_cost%TYPE;            -- �c�ƌ���
    ld_data_created           DATE;                                                -- �f�[�^�쐬����
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
    --�O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    --�J�E���^
    gn_get_counter_data      := 0;     --�f�[�^��
    gn_hed_cnt1              := 0;     --�w�b�_�J�E���^�[
    gn_line_cnt1             := 0;     --���׃J�E���^�[
    gn_hed_cnt2              := 0;     --�w�b�_�J�E���^�[
    gn_line_cnt2             := 0;     --���׃J�E���^�[
    gn_bp_cnt                := 0;     --�����̔����уJ�E���^�[
    gn_hed_suc_cnt           := 0;     --�����w�b�_�J�E���^�[
    gn_line_suc_cnt          := 0;     --�������׃J�E���^�[
--
    --�擾����
    gt_sales_exp_header_id1  := NULL;  --�̔����уw�b�_ID
    gt_sales_exp_header_id2  := NULL;  --�̔����уw�b�_ID�i���E�j
    gt_sales_exp_line_id1    := NULL;  --�̔����і���ID
    gt_sales_exp_line_id2    := NULL;  --�̔����і���ID�i���E�j
    gt_dlv_invoice_number_os := NULL;  --�����[�i�`�[�ԍ�
    gt_sale_amount_sum       := 0;     --������z���v
    gt_pure_amount_sum       := 0;     --�{�̋��z���v
    gt_tax_amount_sum        := 0;     --����ŋ��z���v
--
    --���[�J���ϐ��̏�����
    ln_cnt        := 0;
    lv_ret_status := cv_status_normal;
--
    -- ===============================================
    -- ��������(A-1)
    -- ===============================================
    init(
      iv_get_format => iv_get_format_pat -- �t�H�[�}�b�g�p�^�[��
     ,in_file_id    => in_get_file_id    -- �t�@�C��ID
     ,ov_errbuf     => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- �t�@�C���A�b�v���[�hIF�擾(A-2)
    -- ===============================================
    get_upload_data(
      in_file_id           => in_get_file_id       -- FILE_ID
     ,on_get_counter_data  => gn_get_counter_data  -- �f�[�^��
     ,ov_errbuf            => lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode           => lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg            => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- �f�[�^�폜����(A-3)
    -- ===============================================
    del_upload_data(
      in_file_id  => in_get_file_id   -- �t�@�C��ID
     ,ov_errbuf   => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode  => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg   => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      --�R�~�b�g
      COMMIT;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- �̔����уf�[�^�̍��ڕ�������(A-4)
    -- ===============================================
    split_sales_data(
      in_cnt            => gn_get_counter_data  -- �f�[�^��
     ,ov_errbuf         => lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode        => lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg         => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    --������
    gt_bp_com_code  := NULL;
    gt_dlv_inv_num  := NULL;
    gn_hed_cnt1     := 0;
    gn_line_cnt1    := 0;
    gn_hed_cnt2     := 0;
    gn_line_cnt2    := 0;
--
    FOR i IN cn_begin_line .. gn_get_counter_data LOOP
--
      -- ===============================================
      -- ���ڃ`�F�b�N(A-5)
      -- ===============================================
      item_check(
        in_cnt               => i                    -- �f�[�^�J�E���^
       ,ov_bp_company_code   => lv_bp_company_code   -- �����R�[�h
       ,ov_dlv_inv_num       => lt_dlv_inv_num       -- �[�i�`�[�ԍ�
       ,ov_base_code         => lt_base_code         -- ���_�R�[�h
       ,od_delivery_date     => lt_delivery_date     -- �[�i��
       ,ov_card_sale_class   => lt_card_sale_class   -- �J�[�h���敪
       ,ov_customer_code     => lt_customer_code     -- �ɓ����ڋq�R�[�h
       ,ov_bp_customer_code  => lv_bp_customer_code  -- �����ڋq�R�[�h
       ,ov_tax_class         => lt_tax_class         -- ����ŋ敪
       ,on_line_number       => lt_line_number       -- ���הԍ�
       ,ov_item_code         => lt_item_code         -- �ɓ����i���R�[�h
       ,ov_bp_item_code      => lv_bp_item_code      -- �����i���R�[�h
       ,on_dlv_qty           => lt_dlv_qty           -- ����
       ,on_unit_price        => lt_unit_price        -- ���P��
       ,on_cash_and_card     => lt_cash_and_card     -- �����E�J�[�h���p�z
       ,od_data_created      => ld_data_created      -- �f�[�^�쐬����
       ,ov_errbuf            => lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode           => lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg            => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      ELSIF ( lv_retcode = cv_status_warn ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        --���[�j���O�ێ�
        lv_ret_status := cv_status_warn;
        --�����o��
        FND_FILE.PUT_LINE(
          which => FND_FILE.OUTPUT
         ,buff  => lv_errmsg
        );
      END IF;
--
      IF ( lv_retcode = cv_status_normal ) THEN
        -- ===============================================
        -- �}�X�^���̎擾����(A-6)
        -- ===============================================
        get_master_data(
          in_cnt                     => i                         -- �f�[�^�J�E���^
         ,iv_bp_company_code         => lv_bp_company_code        -- �����R�[�h
         ,iv_dlv_inv_num             => lt_dlv_inv_num            -- �[�i�`�[�ԍ�
         ,iv_base_code               => lt_base_code              -- ���_�R�[�h
         ,id_delivery_date           => lt_delivery_date          -- �[�i��
         ,iv_card_sale_class         => lt_card_sale_class        -- �J�[�h���敪
         ,iv_customer_code           => lt_customer_code          -- �ɓ����ڋq�R�[�h
         ,iv_bp_customer_code        => lv_bp_customer_code       -- �����ڋq�R�[�h
         ,iv_tax_class               => lt_tax_class              -- ����ŋ敪
         ,in_line_number             => lt_line_number            -- ���הԍ�
         ,iv_item_code               => lt_item_code              -- �ɓ����i���R�[�h
         ,iv_bp_item_code            => lv_bp_item_code           -- �����i���R�[�h
         ,ov_sales_base_code         => lt_sales_base_code        -- ���㋒�_�R�[�h
         ,ov_receiv_base_code        => lt_receiv_base_code       -- �������_�R�[�h
         ,ov_bill_tax_round_rule     => lt_bill_tax_round_rule    -- �ŋ��|�[������
         ,ov_conv_customer_code      => lt_conv_customer_code     -- �ϊ���ڋq�R�[�h
         ,ov_offset_cust_code        => lt_offset_cust_code       -- ���E�p�ڋq�R�[�h
         ,ov_employee_number         => lt_results_employee_code  -- �S���c�ƈ�
         ,ov_cust_gyotai_sho         => lt_cust_gyotai_sho        -- �Ƒԁi�����ށj
         ,on_tax_rate                => lt_tax_rate               -- ����ŗ�
         ,ov_tax_code                => lt_tax_code               -- �ŋ��R�[�h
         ,ov_consumption_tax_class   => lt_consumption_tax_class  -- ����ŋ敪
         ,ov_conv_item_code          => lt_conv_item_code         -- �ϊ���i�ڃR�[�h
         ,ov_uom_code                => lt_uom_code               -- ��P��
         ,on_business_cost           => lt_business_cost          -- �c�ƌ���
         ,ov_item_status             => lv_item_status            -- �i�ڃX�e�[�^�X
         ,ov_errbuf                  => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode                 => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg                  => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        ELSIF ( lv_retcode = cv_status_warn ) THEN
          gn_error_cnt := gn_error_cnt + 1;
          --���[�j���O�ێ�
          lv_ret_status := cv_status_warn;
        END IF;
      END IF;
--
      IF ( lv_retcode = cv_status_normal ) THEN
        -- ===============================================
        -- �Z�L�����e�B�`�F�b�N����(A-7)
        -- ===============================================
        security_check(
          in_cnt                     => i                         -- �f�[�^�J�E���^
         ,iv_dlv_inv_num             => lt_dlv_inv_num            -- �[�i�`�[�ԍ�
         ,in_line_number             => lt_line_number            -- ���הԍ�
         ,iv_customer_code           => lt_conv_customer_code     -- �ϊ���ڋq�R�[�h
         ,iv_sales_base_code         => lt_sales_base_code        -- ���㋒�_�R�[�h
         ,ov_errbuf                  => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode                 => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg                  => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        ELSIF ( lv_retcode = cv_status_warn ) THEN
          gn_error_cnt := gn_error_cnt + 1;
          --���[�j���O�ێ�
          lv_ret_status := cv_status_warn;
          --�����o��
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT
           ,buff  => lv_errmsg
          );
        END IF;
      END IF;
--
      IF ( lv_ret_status = cv_status_normal ) THEN
--
        -- ===============================================
        -- �����̔����уf�[�^�ݒ菈��(A-8)
        -- ===============================================
        set_sales_bp_data(
          in_cnt                     => i                         -- �f�[�^�J�E���^
         ,iv_bp_company_code         => lv_bp_company_code        -- �����R�[�h
         ,iv_dlv_inv_num             => lt_dlv_inv_num            -- �[�i�`�[�ԍ�
         ,iv_base_code               => lt_base_code              -- ���_�R�[�h
         ,id_delivery_date           => lt_delivery_date          -- �[�i��
         ,iv_card_sale_class         => lt_card_sale_class        -- �J�[�h���敪
         ,iv_customer_code           => lt_customer_code          -- �ɓ����ڋq�R�[�h
         ,iv_bp_customer_code        => lv_bp_customer_code       -- �����ڋq�R�[�h
         ,iv_tax_class               => lt_tax_class              -- ����ŋ敪
         ,in_line_number             => lt_line_number            -- ���הԍ�
         ,iv_item_code               => lt_item_code              -- �ɓ����i���R�[�h
         ,iv_bp_item_code            => lv_bp_item_code           -- �����i���R�[�h
         ,in_dlv_qty                 => lt_dlv_qty                -- ����
         ,in_unit_price              => lt_unit_price             -- ���P��
         ,in_cash_and_card           => lt_cash_and_card          -- �����E�J�[�h���p�z
         ,id_data_created            => ld_data_created           -- �f�[�^�쐬����
         ,iv_conv_customer_code      => lt_conv_customer_code     -- �ϊ���ڋq�R�[�h
         ,iv_offset_cust_code        => lt_offset_cust_code       -- ���E�p�ڋq�R�[�h
         ,iv_employee_number         => lt_results_employee_code  -- �S���c�ƈ�
         ,iv_conv_item_code          => lt_conv_item_code         -- �ϊ���i���R�[�h
         ,iv_item_status             => lv_item_status            -- �i�ڃX�e�[�^�X
         ,ov_errbuf                  => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode                 => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg                  => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
        -- ===============================================
        -- �̔����уf�[�^�ݒ菈��(A-9)
        -- ===============================================
        set_sales_data(
          in_cnt                     => i                         -- �f�[�^�J�E���^
         ,iv_bp_company_code         => lv_bp_company_code        -- �����R�[�h
         ,iv_dlv_inv_num             => lt_dlv_inv_num            -- �[�i�`�[�ԍ�
         ,iv_base_code               => lt_base_code              -- ���_�R�[�h
         ,id_delivery_date           => lt_delivery_date          -- �[�i��
         ,iv_card_sale_class         => lt_card_sale_class        -- �J�[�h���敪
         ,iv_customer_code           => lt_conv_customer_code     -- �ϊ���ڋq�R�[�h
         ,iv_tax_class               => lt_tax_class              -- ����ŋ敪
         ,in_line_number             => lt_line_number            -- ���הԍ�
         ,iv_item_code               => lt_conv_item_code         -- �ϊ���i���R�[�h
         ,in_dlv_qty                 => lt_dlv_qty                -- ����
         ,in_unit_price              => lt_unit_price             -- ���P��
         ,iv_sales_base_code         => lt_sales_base_code        -- ���㋒�_�R�[�h
         ,iv_receiv_base_code        => lt_receiv_base_code       -- �������_�R�[�h
         ,iv_bill_tax_round_rule     => lt_bill_tax_round_rule    -- �ŋ��|�[������
         ,iv_offset_cust_code        => lt_offset_cust_code       -- ���E�p�ڋq�R�[�h
         ,iv_results_employee_code   => lt_results_employee_code  -- ���ьv��҃R�[�h
         ,iv_cust_gyotai_sho         => lt_cust_gyotai_sho        -- �Ƒԁi�����ށj
         ,in_tax_rate                => lt_tax_rate               -- ����ŗ�
         ,iv_tax_code                => lt_tax_code               -- �ŋ��R�[�h
         ,iv_consumption_tax_class   => lt_consumption_tax_class  -- ����ŋ敪
         ,iv_uom_code                => lt_uom_code               -- ��P��
         ,in_business_cost           => lt_business_cost          -- �c�ƌ���
         ,in_cash_and_card           => lt_cash_and_card          -- �����E�J�[�h���p�z
         ,ov_errbuf                  => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode                 => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg                  => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
      END IF;
--
    END LOOP;
--
  -- ********************************
  -- ***  �̔����уf�[�^�o�^����  ***
  -- ********************************
--
    --LOOP���ŃG���[���Ȃ��ꍇ
    IF ( lv_ret_status = cv_status_normal ) THEN
      -- ===============================================
      -- �����̔����уf�[�^�o�^����(A-10)
      -- ===============================================
      ins_sales_bp_data(
        ov_errbuf         => lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================================
      -- �̔����уf�[�^�o�^����(A-11)
      -- ===============================================
      ins_sales_data(
        ov_errbuf         => lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    --LOOP�̃G���[�X�e�[�^�X���m�[�}���łȂ��ꍇ(���[�j���O)
    IF ( lv_ret_status != cv_status_normal ) THEN
      ov_retcode := lv_ret_status;
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
    errbuf            OUT VARCHAR2  -- �G���[�E���b�Z�[�W  --# �Œ� #
   ,retcode           OUT VARCHAR2  -- ���^�[���E�R�[�h    --# �Œ� #
   ,in_get_file_id    IN  NUMBER    -- �t�@�C��ID
   ,iv_get_format_pat IN  VARCHAR2  -- �t�H�[�}�b�g�p�^�[��
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
    -- submain�̌Ăяo��(���ۂ̏�����submain�ōs��)
    -- ===============================================
    submain(
      in_get_file_id     -- �t�@�C��ID
     ,iv_get_format_pat  -- �t�H�[�}�b�g�p�^�[��
     ,lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
     ,lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ===============================================
    -- �I������(A-12)
    -- ===============================================
    --�G���[������
    IF ( lv_retcode = cv_status_error ) THEN
      --�G���[���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
      --�G���[�����ݒ�
      gn_target_cnt   := 0;
      gn_hed_suc_cnt  := 0;
      gn_line_suc_cnt := 0;
      gn_error_cnt    := 1;
      --�G���[����ROLLBACK
      ROLLBACK;
    END IF;
--
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
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_appl_short_name
                    ,iv_name         => cv_msg_get_h_count
                    ,iv_token_name1  => cv_tkn_param1
                    ,iv_token_value1 => TO_CHAR(gn_hed_suc_cnt)
                    ,iv_token_name2  => cv_tkn_param2
                    ,iv_token_value2 => TO_CHAR(gn_line_suc_cnt)
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
--
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
END XXCOS018A01C;
/
