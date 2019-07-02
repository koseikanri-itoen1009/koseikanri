CREATE OR REPLACE PACKAGE BODY XXCSO019A13C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2018. All rights reserved.
 *
 * Package Name     : XXCSO019A13C(body)
 * Description      : ���[�gNo�^�c�ƈ��ꊇ�X�V�A�b�v���[�h
 * MD.050           : ���Ϗ��A�b�v���[�h MD050_CSO_017_A07
 * Version          : 1.1
 *
 * Program List
 * ------------------------- ----------------------------------------------------------
 *  Name                      Description
 * ------------------------- ----------------------------------------------------------
 *  init                      ��������(A-1)
 *  get_upload_data           �t�@�C���A�b�v���[�hIF�f�[�^���o(A-2)
 *  get_check_spec            ���̓f�[�^�`�F�b�N�d�l�擾(A-3)
 *  fnc_check_data            ���̓f�[�^�`�F�b�N����(A-4)
 *  check_input_data          ���̓f�[�^�`�F�b�N(A-5)
 *  ins_route_emp_upload_work ���[�gNo�^�c�ƈ��A�b�v���[�h���ԃe�[�u���o�^(A-6)
 *  check_business_data       �Ɩ��G���[�`�F�b�N(A-7)
 *  reflect_route_emp         ���[�gNo�^�c�ƒS���X�V���f����(A-8)
 *  delete_file_ul_if         �t�@�C���A�b�v���[�hIF�f�[�^�폜(A-9)
 *  submain                   ���C�������v���V�[�W��
 *  main                      �R���J�����g���s�t�@�C���o�^�v���V�[�W���E�I������(A-10)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2018/04/19    1.0   K.Kiriu          �V�K�쐬(E_�{�ғ�_14722)
 *  2019/04/25    1.1   T.Kawaguchi      E_�{�ғ�_15683�y�c�Ɓz���[�g�ꊇ�X�V��Q�Ή�
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
  gn_warn_cnt      NUMBER;                    -- �x������
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
  global_lock_expt                EXCEPTION;  -- ���b�N��O
--
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                         CONSTANT VARCHAR2(100) := 'XXCSO019A13C';      -- �p�b�P�[�W��
--
  cv_app_name                         CONSTANT VARCHAR2(30)  := 'XXCSO';             -- �A�v���P�[�V�����Z�k��
--
  -- ���b�Z�[�W
  cv_msg_file_id                      CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00271';  -- �t�@�C��ID
  cv_msg_fmt_ptn                      CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00275';  -- �t�H�[�}�b�g�p�^�[��
  cv_msg_param_required               CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00325';  -- �p�����[�^�K�{�G���[
  cv_input_param_nm_file_id           CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00673';  -- �����i�t�@�C��ID�j
  cv_input_param_nm_fmt_ptn           CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00674';  -- �����i�t�H�[�}�b�g�p�^�[���j
  cv_msg_err_param_valuel             CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00252';  -- �p�����[�^�Ó����`�F�b�N�G���[
  cv_msg_err_get_data_ul              CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00274';  -- �f�[�^���o�G���[
  cv_msg_file_ul_name                 CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00276';  -- �t�@�C���A�b�v���[�h����
  cv_msg_file_name                    CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00152';  -- CSV�t�@�C����
  cv_msg_err_get_lock                 CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00278';  -- ���b�N�G���[
  cv_msg_err_get_data                 CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00554';  -- �f�[�^���o�G���[
  cv_msg_err_get_proc_date            CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00011';  -- �Ɩ��������t�擾�G���[
  cv_msg_err_get_profile              CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00014';  -- �v���t�@�C���擾�G���[
  cv_msg_err_no_data                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00399';  -- �Ώی���0�����b�Z�[�W
  cv_msg_err_file_fmt                 CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00846';  -- ���[�gNo�^�c�ƈ�CSV�t�H�[�}�b�g�G���[���b�Z�[�W
  cv_msg_err_get_user_base            CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00847';  -- �������_�擾�G���[���b�Z�[�W
  cv_msg_err_get_base                 CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00848';  -- ���_�擾�G���[���b�Z�[�W
  cv_tbl_nm_file_ul_if                CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00676';  -- �����i�t�@�C���A�b�v���[�hIF�j
  cv_msg_err_required                 CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00403';  -- �K�{���ڃG���[�i�����s�j
  cv_msg_err_no_ref_method            CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00849';  -- ���f���@�`�F�b�N�G���[���b�Z�[�W
  cv_msg_err_ins_data                 CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00471';  -- �f�[�^�o�^�G���[
  cv_tbl_nm_work                      CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00850';  -- �����i���[�gNo�^�c�ƈ��A�b�v���[�h���ԃe�[�u���j
  cv_msg_err_invalid                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00622';  -- �^�E�����`�F�b�N�G���[���b�Z�[�W
  cv_msg_err_dup_cust                 CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00851';  -- �ڋq�d���G���[���b�Z�[�W
  cv_msg_err_no_cust                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00852';  -- �ڋq�擾�G���[���b�Z�[�W
  cv_msg_err_class_status             CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00853';  -- �ڋq�敪�E�X�e�[�^�X�ΏۊO�G���[���b�Z�[�W
  cv_msg_err_cust_resouce             CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00854';  -- �ڋq�S���擾�G���[���b�Z�[�W
  cv_msg_err_dup_resouce              CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00855';  -- �S���c�ƈ��d���G���[���b�Z�[�W
  cv_msg_err_no_update                CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00856';  -- �X�V���e�Ȃ��G���[���b�Z�[�W
  cv_msg_err_route_chack              CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00857';  -- ���[�gNo�Ó����`�F�b�N�G���[
  cv_msg_err_reflect_method           CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00858';  -- ���f���@�w��G���[
  cv_msg_err_cust_inadequacy          CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00861';  -- �ڋq�ݒ�s���G���[
  cv_route_date                       CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00859';  -- �����i�V���[�gNo�j
  cv_emp_date                         CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00860';  -- �����i�V�S���j
  cv_msg_err_security                 CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00862';  -- �ڋq�Z�L�����e�B�G���[
  cv_msg_immediate                    CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00863';  -- �����i�����j
  cv_msg_reservation                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00864';  -- �����i�\��j
  cv_msg_err_emp_base                 CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00865';  -- �S���Z�L�����e�B�G���[
  cv_msg_err_trgt_emp_base            CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00871';  -- ���S���擾�G���[
  cv_msg_err_payment_cust_route       CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00866';  -- ���|���Ǘ���ڋq���[�gNo�ݒ�G���[
  cv_msg_err_payment_reflect          CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00867';  -- ���|���Ǘ���ڋq���f���@�G���[
  cv_msg_err_payment_emp              CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00869';  -- ���|���Ǘ���ڋq�V�S���K�{�G���[
  cv_msg_err_payment_base             CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00868';  -- ���|���Ǘ���ڋq�����K�{�G���[
  cv_msg_err_common_pkg               CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00870';  -- ���[�gNo�^�S���c�Ƌ��ʊ֐��G���[���b�Z�[�W
  cv_msg_insert                       CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00702';  -- �����i�o�^�j
  cv_msg_err_del_data                 CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00872';  -- �f�[�^�폜�G���[
  cv_msg_err_lock_data                CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00874';  -- ���b�N�G���[
  cv_msg_table_hopeb                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00875';  -- ����(�g�D�v���t�@�C���g���j
  cv_msg_trgt_route_date              CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00876';  -- ����(���S���j
  cv_msg_trgt_emp_date                CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00877';  -- ����(�����[�gNo�j
  cv_msg_delete                       CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00879';  -- �����i�폜�j
  cv_msg_err_no_base                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00880';  -- �������_�ݒ�Ȃ��G���[���b�Z�[�W
  cv_msg_err_rcv_security             CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00881';  -- �ڋq�Z�L�����e�B�G���[�i���|���Ǘ���j
  cv_msg_err_rcv_emp_base             CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00882';  -- �S���Z�L�����e�B�G���[�i���|���Ǘ���j
--
  --���b�Z�[�W�g�[�N��
  cv_tkn_file_id                      CONSTANT VARCHAR2(7)   := 'FILE_ID';
  cv_tkn_fmt_ptn                      CONSTANT VARCHAR2(14)  := 'FORMAT_PATTERN';
  cv_tkn_param_name                   CONSTANT VARCHAR2(10)  := 'PARAM_NAME';
  cv_tkn_item                         CONSTANT VARCHAR2(4)   := 'ITEM';
  cv_tkn_file_ul_name                 CONSTANT VARCHAR2(16)  := 'UPLOAD_FILE_NAME';
  cv_tkn_file_name                    CONSTANT VARCHAR2(13)  := 'CSV_FILE_NAME';
  cv_tkn_table                        CONSTANT VARCHAR2(5)   := 'TABLE';
  cv_tkn_err_msg                      CONSTANT VARCHAR2(7)   := 'ERR_MSG';
  cv_tkn_profile_name                 CONSTANT VARCHAR2(9)   := 'PROF_NAME';
  cv_tkn_column                       CONSTANT VARCHAR2(6)   := 'COLUMN';
  cv_tkn_index                        CONSTANT VARCHAR2(5)   := 'INDEX';
  cv_tkn_data_div_val                 CONSTANT VARCHAR2(12)  := 'DATA_DIV_VAL';
  cv_tkn_error_message                CONSTANT VARCHAR2(13)  := 'ERROR_MESSAGE';
  cv_tkn_action                       CONSTANT VARCHAR2(6)   := 'ACTION';
  cv_tkn_account                      CONSTANT VARCHAR2(11)  := 'ACCOUNT_NUM';
  cv_tkn_class                        CONSTANT VARCHAR2(5)   := 'CLASS';
  cv_tkn_status                       CONSTANT VARCHAR2(6)   := 'STATUS';
  cv_tkn_route                        CONSTANT VARCHAR2(5)   := 'ROUTE';
  cv_tkn_data_div                     CONSTANT VARCHAR2(8)   := 'DATA_DIV';
  cv_tkn_base_code                    CONSTANT VARCHAR2(9)   := 'BASE_CODE';
  cv_tkn_emp_code                     CONSTANT VARCHAR2(9)   := 'EMP_CODE';
--
  -- �����_�Z�L�����e�B
  cv_no_security                      CONSTANT VARCHAR2(1)   := '1'; -- �Z�L�����e�B�Ȃ�
  -- �ڋq�敪
  cv_base                             CONSTANT VARCHAR2(1)   := '1'; -- ���_
  -- �Q�ƃ^�C�v
  cv_lkup_file_ul_obj                 CONSTANT VARCHAR2(22)  := 'XXCCP1_FILE_UPLOAD_OBJ';      -- �t�@�C���A�b�v���[�hOBJ
  cv_lkup_route_mgr_cust_class        CONSTANT VARCHAR2(27)  := 'XXCSO1_ROUTE_MGR_CUST_CLASS'; -- ���[�gNo�Ǘ��Ώیڋq
  -- �v���t�@�C��
  cv_security_019_a09                 CONSTANT VARCHAR2(23)  := 'XXCSO1_SECURITY_019_A09';     -- XXCSO:���[�gNo�^�S���c�ƈ��ꊇ�X�V�Z�L�����e�B
  -- CSV�t�@�C���w�b�_�s
  cn_header_rec                       CONSTANT NUMBER        := 1;
  -- CSV�t�@�C���̍��ڈʒu
  cn_col_pos_cust_div                 CONSTANT NUMBER        := 1;   -- �ڋq�敪
  cn_col_pos_cust_code                CONSTANT NUMBER        := 2;   -- �ڋq�R�[�h
  cn_col_pos_cust_name                CONSTANT NUMBER        := 3;   -- �ڋq��
  cn_col_pos_now_emp                  CONSTANT NUMBER        := 4;   -- ���S��
  cn_col_pos_now_route                CONSTANT NUMBER        := 5;   -- �����[�gNo
  cn_col_pos_new_emp                  CONSTANT NUMBER        := 6;   -- �V�S��
  cn_col_pos_new_route                CONSTANT NUMBER        := 7;   -- �V���[�gNo
  cn_col_pos_reflect_method           CONSTANT NUMBER        := 8;   -- ���f���@
  -- CSV�t�@�C���̍��ڒ�
  cn_col_length_cust_code             CONSTANT NUMBER        := 9;   -- �ڋq�R�[�h
  cn_col_length_new_emp               CONSTANT NUMBER        := 5;   -- �V�S��
  cn_col_length_new_route             CONSTANT NUMBER        := 7;   -- �V���[�gNo
  cn_col_length_reflect_method        CONSTANT NUMBER        := 1;   -- ���f���@
  -- ���f���@
  cv_immediate                        CONSTANT VARCHAR2(1)   := '1'; -- ����
  cv_reservation                      CONSTANT VARCHAR2(1)   := '2'; -- �\��
  -- �폜
  cv_delete                           CONSTANT VARCHAR2(1)   := '-'; -- �폜
  -- �쐬�E�X�V�A�폜�敪
  cv_ins_upd                          CONSTANT VARCHAR2(1)   := 'I'; -- �쐬�E�X�V
  cv_del                              CONSTANT VARCHAR2(1)   := 'D'; -- �폜
  -- �ėp
  cv_lang                             CONSTANT VARCHAR2(2)   := USERENV('LANG');  -- ����
  cv_enabled                          CONSTANT VARCHAR2(1)   := 'Y';              -- �L��
  cv_month_format                     CONSTANT VARCHAR2(2)   := 'MM';             -- ���t�t�H�[�}�b�g(��)
  cv_yes                              CONSTANT VARCHAR2(1)   := 'Y';              -- yes
  cv_no                               CONSTANT VARCHAR2(1)   := 'N';              -- no
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ���[�U�[�̎����_�R�[�h
  TYPE gt_base_code_ttype IS TABLE OF hz_cust_accounts.account_number%TYPE INDEX BY BINARY_INTEGER;
  gt_base_code_tab  gt_base_code_ttype;
  -- �A�b�v���[�h�f�[�^�����擾�p
  TYPE gt_col_data_ttype  IS TABLE OF VARCHAR(1000)     INDEX BY BINARY_INTEGER;  --1�����z��i���ځj
  TYPE gt_rec_data_ttype  IS TABLE OF gt_col_data_ttype INDEX BY BINARY_INTEGER;  --2�����z��i���R�[�h�j�i���ځj
  -- ���[�gNo/�c�ƒS�����f�f�[�^�擾�v
  TYPE gt_ref_route_emp_rtype IS RECORD(
     line_no                     xxcso_tmp_rtn_rsrc_work.line_no%TYPE              -- �s�ԍ�
    ,account_number              xxcso_tmp_rtn_rsrc_work.account_number%TYPE       -- �ڋq�R�[�h
    ,new_employee_number         xxcso_tmp_rtn_rsrc_work.new_employee_number%TYPE  -- �V�S��
    ,new_employee_date           DATE                                              -- �V�S���K�p�J�n��
    ,trgt_resource_id            hz_org_profiles_ext_b.extension_id%TYPE           -- �V�S���g��ID
    ,next_resource_id            hz_org_profiles_ext_b.extension_id%TYPE           -- ���S���g��ID
    ,new_route_no                xxcso_tmp_rtn_rsrc_work.new_route_no%TYPE         -- �V���[�gNo
    ,new_route_date              DATE                                              -- �V���[�gNo�K�p�J�n��
    ,trgt_route_id               hz_org_profiles_ext_b.extension_id%TYPE           -- �V���[�gNo�g��ID
    ,next_route_id               hz_org_profiles_ext_b.extension_id%TYPE           -- �����[�gNo�g��ID
    ,employee_change_flag        VARCHAR2(1)                                       -- �S���ύX�t���O
    ,route_no_change_flag        VARCHAR2(1)                                       -- ���[�gNo�ύX�t���O
  );
  TYPE gt_ref_route_emp_ttype IS TABLE OF gt_ref_route_emp_rtype INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_process_date        DATE;                             -- �Ɩ��������t
  gd_first_day_date      DATE;                             -- �Ɩ��������t�P��
  gd_next_month_date     DATE;                             -- �Ɩ��������t����1��
  gv_security_019_a09    VARCHAR2(1);                      -- ���[�gNo�^�S���c�ƈ��ꊇ�X�V�Z�L�����e�B
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     iv_file_id    IN  VARCHAR2  -- 1.�t�@�C��ID
    ,iv_fmt_ptn    IN  VARCHAR2  -- 2.�t�H�[�}�b�g�p�^�[��
    ,on_file_id    OUT NUMBER    -- 3.�t�@�C��ID�i�^�ϊ���j
    ,ov_errbuf     OUT VARCHAR2  --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode    OUT VARCHAR2  --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg     OUT VARCHAR2  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
--
    -- *** ���[�J���ϐ� ***
    lv_msg           VARCHAR2(5000);                              -- ���b�Z�[�W
    lt_file_ul_name  fnd_lookup_values.meaning%TYPE;              -- �t�@�C���A�b�v���[�h����
    lt_file_name     xxccp_mrp_file_ul_interface.file_name%TYPE;  -- CSV�t�@�C����
    lt_base_code     hz_cust_accounts.account_number%TYPE;        -- ���[�U�[�������_
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==================================================
    -- 1.�p�����[�^�o��
    --==================================================
    -- �t�@�C��ID���b�Z�[�W
    lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name
                   ,iv_name         => cv_msg_file_id
                   ,iv_token_name1  => cv_tkn_file_id
                   ,iv_token_value1 => iv_file_id
                 );
    -- �t�@�C��ID���b�Z�[�W�o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg
    );
--
    -- �t�H�[�}�b�g�p�^�[�����b�Z�[�W
    lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name
                   ,iv_name         => cv_msg_fmt_ptn
                   ,iv_token_name1  => cv_tkn_fmt_ptn
                   ,iv_token_value1 => iv_fmt_ptn
                 );
    -- �t�H�[�}�b�g�p�^�[�����b�Z�[�W�o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg
    );
--
    --==================================================
    -- 2.�p�����[�^�̃`�F�b�N
    --==================================================
    -- �p�����[�^�D�t�@�C��ID�̕K�{���̓`�F�b�N
    IF (iv_file_id IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_param_required
                     ,iv_token_name1  => cv_tkn_param_name
                     ,iv_token_value1 => cv_input_param_nm_file_id
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �p�����[�^�D�t�@�C��ID�̌^�`�F�b�N(���l�^�ɕϊ��ł��Ȃ��ꍇ�̓G���[)
    IF (NOT xxcop_common_pkg.chk_number_format(iv_file_id)) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_err_param_valuel
                     ,iv_token_name1  => cv_tkn_item
                     ,iv_token_value1 => cv_input_param_nm_file_id
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �t�@�C��ID�̌^�ϊ�
    on_file_id := TO_NUMBER(iv_file_id);
--
    -- �p�����[�^�D�t�H�[�}�b�g�p�^�[���̕K�{���̓`�F�b�N
    IF (iv_fmt_ptn IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_param_required
                     ,iv_token_name1  => cv_tkn_param_name
                     ,iv_token_value1 => cv_input_param_nm_fmt_ptn
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --==================================================
    -- 3.�Ɩ����t�̎擾
    --==================================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    --�Ɩ��������t�擾�`�F�b�N
    IF (gd_process_date IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_err_get_proc_date
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �Ɩ����t�̂P�����擾
    gd_first_day_date   := TRUNC(gd_process_date, cv_month_format );
    -- �Ɩ����t�̗���1�����擾
    gd_next_month_date  := TRUNC( ADD_MONTHS( gd_process_date, 1 ), cv_month_format );
--
    --==================================================
    -- 4.�t�@�C���A�b�v���[�h���E�t�@�C�����̏o��
    --==================================================
    BEGIN
      -- �t�@�C���A�b�v���[�h����
      SELECT flv.meaning  meaning
      INTO   lt_file_ul_name
      FROM   fnd_lookup_values flv
      WHERE  flv.lookup_type  = cv_lkup_file_ul_obj
      AND    flv.lookup_code  = iv_fmt_ptn
      AND    flv.language     = cv_lang
      AND    flv.enabled_flag = cv_enabled
      AND    gd_process_date  BETWEEN flv.start_date_active
                              AND     NVL(flv.end_date_active, gd_process_date)
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_err_get_data_ul
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
    -- �t�@�C���A�b�v���[�h���̃��b�Z�[�W
    lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name
                   ,iv_name         => cv_msg_file_ul_name
                   ,iv_token_name1  => cv_tkn_file_ul_name
                   ,iv_token_value1 => TO_CHAR(lt_file_ul_name)
                 );
    -- �t�@�C���A�b�v���[�h���̃��b�Z�[�W�o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg
    );
--
    BEGIN
      --CSV�t�@�C����
      SELECT xmfui.file_name file_name
      INTO   lt_file_name
      FROM   xxccp_mrp_file_ul_interface xmfui
      WHERE  xmfui.file_id = on_file_id
      FOR UPDATE NOWAIT
      ;
      -- CSV�t�@�C�������b�Z�[�W
      lv_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_file_name
                     ,iv_token_name1  => cv_tkn_file_name
                     ,iv_token_value1 => lt_file_name
                   );
      -- CSV�t�@�C�������b�Z�[�W�o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_msg
      );
      --��s�}��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
    EXCEPTION
      WHEN global_lock_expt THEN -- ���b�N�擾���s
        --���b�N�G���[���b�Z�[�W
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_err_get_lock
                       ,iv_token_name1  => cv_tkn_table
                       ,iv_token_value1 => cv_tbl_nm_file_ul_if
                       ,iv_token_name2  => cv_tkn_err_msg
                       ,iv_token_value2 => SQLERRM
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      WHEN OTHERS THEN
        --�f�[�^���o�G���[���b�Z�[�W
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_err_get_data
                       ,iv_token_name1  => cv_tkn_table
                       ,iv_token_value1 => cv_tbl_nm_file_ul_if
                       ,iv_token_name2  => cv_tkn_file_id
                       ,iv_token_value2 => on_file_id
                       ,iv_token_name3  => cv_tkn_err_msg
                       ,iv_token_value3 => SQLERRM
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    --==================================================
    -- 5.�v���t�@�C���I�v�V�����̎擾
    --==================================================
    -- XXCSO:���[�gNo�^�S���c�ƈ��ꊇ�X�V�Z�L�����e�B
    gv_security_019_a09 := FND_PROFILE.VALUE(cv_security_019_a09);
    IF ( gv_security_019_a09 IS NULL ) THEN
      -- �v���t�@�C���擾�`�F�b�N
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_err_get_profile
                     ,iv_token_name1  => cv_tkn_profile_name
                     ,iv_token_value1 => cv_security_019_a09
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --==================================================
    -- 6.�����_�̎擾(�����_�Z�L�����e�B�L��̏ꍇ)
    --==================================================
    IF ( gv_security_019_a09 <> cv_no_security ) THEN
      -- ���[�U�[�̎����_�擾(���\�[�X���擾)
      BEGIN
        SELECT xxcso_util_common_pkg.get_rs_base_code(
                  xrv.resource_id
                 ,gd_process_date
               ) base_code
        INTO   lt_base_code
        FROM   xxcso_resources_v2 xrv
        WHERE  xrv.user_id = cn_created_by
        ;
      EXCEPTION
        WHEN OTHERS THEN
          -- ���[�U�[�̎����_�擾���s
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_err_get_user_base
                         ,iv_token_name1  => cv_tkn_err_msg
                         ,iv_token_value1 => SQLERRM
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
--
      -- �擾�����������_��NULL�łȂ����`�F�b�N
      IF ( lt_base_code IS NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_err_no_base
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
--
      -- �����_�i�Ǘ����̏ꍇ�A�z���̋��_���܂ށj���擾
      BEGIN
        SELECT xcav.account_number base_code
        BULK COLLECT INTO
               gt_base_code_tab
        FROM   xxcso_cust_accounts_v xcav
        WHERE  xcav.customer_class_code = cv_base
        AND    xcav.account_number      = lt_base_code
        UNION
        SELECT xcav.account_number base_code
        FROM   xxcso_cust_accounts_v xcav
        WHERE  xcav.customer_class_code  = cv_base
        AND    xcav.management_base_code = lt_base_code
        ;
      EXCEPTION
        WHEN OTHERS THEN
          -- ���_�擾���s
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_err_get_base
                         ,iv_token_name1  => cv_tkn_err_msg
                         ,iv_token_value1 => SQLERRM
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    END IF;
--
  EXCEPTION
    --*** �����G���[��O ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
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
   * Description      : �t�@�C���A�b�v���[�hIF�f�[�^���o(A-2)
   ***********************************************************************************/
  PROCEDURE get_upload_data(
     in_file_id            IN  NUMBER             -- 1.�t�@�C��ID
    ,ot_route_emp_data_tab OUT gt_rec_data_ttype  --   ���[�gNo/�c�ƈ��f�[�^�z��
    ,ov_errbuf             OUT VARCHAR2           --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode            OUT VARCHAR2           --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg             OUT VARCHAR2           --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    cv_col_separator     CONSTANT VARCHAR2(10) := ',';  -- ���ڋ�ؕ���
    cn_csv_file_col_num  CONSTANT NUMBER       := 8;    -- CSV�t�@�C�����ڐ�
--
     -- *** ���[�J���ϐ� ***
    ln_col_num           NUMBER;
    ln_line_cnt          NUMBER;
    ln_column_cnt        NUMBER;
--
    -- *** ���[�J���E���R�[�h ***
    l_file_data_tab      xxccp_common_pkg2.g_file_data_tbl;  -- �s�P�ʃf�[�^�i�[�p�z��
    l_route_emp_data_tab gt_rec_data_ttype;                  -- ���[�gNo�^�c�ƈ��f�[�^�p�z��
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- BLOB�f�[�^�ϊ��֐��ɂ��s�P�ʃf�[�^�𒊏o
    xxccp_common_pkg2.blob_to_varchar2(
       in_file_id   => in_file_id       -- �t�@�C��ID
      ,ov_file_data => l_file_data_tab  -- �t�@�C���f�[�^
      ,ov_errbuf    => lv_errbuf        -- �G���[�E���b�Z�[�W            -- # �Œ� #
      ,ov_retcode   => lv_retcode       -- ���^�[���E�R�[�h              -- # �Œ� #
      ,ov_errmsg    => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      -- �f�[�^���o�G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_err_get_data
                     ,iv_token_name1  => cv_tkn_table
                     ,iv_token_value1 => cv_tbl_nm_file_ul_if
                     ,iv_token_name2  => cv_tkn_file_id
                     ,iv_token_value2 => in_file_id
                     ,iv_token_name3  => cv_tkn_err_msg
                     ,iv_token_value3 => lv_errbuf
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    IF (l_file_data_tab.COUNT - cn_header_rec <= 0) THEN
      -- �w�b�_�s���������f�[�^��0�s�̏ꍇ�A�Ώی���0�����b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_err_no_data
                   );
      -- �Ώی���0�����b�Z�[�W�o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      gn_warn_cnt := 0;
      ov_retcode  := cv_status_warn;
      -- �f�[�^�����̂��߈ȉ��̏����͍s��Ȃ��B
      RETURN;
    END IF;
--
    gn_target_cnt := l_file_data_tab.COUNT - cn_header_rec;
--
    <<line_data_loop>>
    FOR ln_line_cnt IN 1 .. l_file_data_tab.COUNT LOOP
      -- ���ڐ��擾
      ln_col_num := NVL(LENGTH(l_file_data_tab(ln_line_cnt)), 0)
                      - NVL(LENGTH(REPLACE(l_file_data_tab(ln_line_cnt), cv_col_separator, NULL)), 0) + 1;
      -- ���ڐ��`�F�b�N
      IF (ln_col_num <> cn_csv_file_col_num) THEN
        -- ���[�gNo�^�c�ƈ�CSV�t�H�[�}�b�g�G���[���b�Z�[�W
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_err_file_fmt
                       ,iv_token_name1  => cv_tkn_index
                       ,iv_token_value1 => ln_line_cnt - 1
                     );
        -- �G���[���b�Z�[�W�o��
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
--
        gn_warn_cnt := gn_warn_cnt + 1;
        ov_retcode  := cv_status_warn;
      ELSE
        <<column_loop>>
        FOR ln_column_cnt IN 1 .. cn_csv_file_col_num LOOP
          --���ڕ���
          l_route_emp_data_tab(ln_line_cnt)(ln_column_cnt) := xxccp_common_pkg.char_delim_partition(
                                                                 iv_char     => l_file_data_tab(ln_line_cnt)
                                                                ,iv_delim    => cv_col_separator
                                                                ,in_part_num => ln_column_cnt
                                                              );
        END LOOP column_loop;
      END IF;
    END LOOP line_loop;
--
    -- �����f�[�^�̕ԋp
    ot_route_emp_data_tab := l_route_emp_data_tab;
--
  EXCEPTION
      --*** �����G���[��O ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
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
   * Procedure Name   : get_check_spec
   * Description      : ���̓f�[�^�`�F�b�N�d�l�擾(A-3)
   ***********************************************************************************/
  PROCEDURE get_check_spec(
     in_col_pos         IN  NUMBER    -- 1.���ڈʒu
    ,ov_check           OUT VARCHAR2  --   �`�F�b�N�v��
    ,ov_allow_null      OUT VARCHAR2  --   NULL����
    ,on_length          OUT NUMBER    --   ���ڒ�
    ,ov_errbuf          OUT VARCHAR2  --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode         OUT VARCHAR2  --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg          OUT VARCHAR2  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_check_spec'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    CASE in_col_pos
    WHEN cn_col_pos_cust_div THEN
      -- �ڋq�敪�`�F�b�N�d�l(�`�F�b�N�s�v)
      ov_check          := cv_no;
    WHEN cn_col_pos_cust_code THEN
      -- �ڋq�R�[�h�`�F�b�N�d�l
      ov_check          := cv_yes;
      ov_allow_null     := xxccp_common_pkg2.gv_null_ng;
      on_length         := cn_col_length_cust_code;
    WHEN cn_col_pos_cust_name THEN
      -- �ڋq���`�F�b�N�d�l�i�`�F�b�N�s�v�j
      ov_check          := cv_no;
    WHEN cn_col_pos_now_emp THEN
       -- ���S���`�F�b�N�d�l(�`�F�b�N�s�v)
      ov_check          := cv_no;
    WHEN cn_col_pos_now_route THEN
       -- �����[�gNo�`�F�b�N�d�l(�`�F�b�N�s�v)
      ov_check          := cv_no;
    WHEN cn_col_pos_new_emp THEN
       -- �V�S���`�F�b�N�d�l
      ov_check          := cv_yes;
      ov_allow_null     := xxccp_common_pkg2.gv_null_ok;
      on_length         := cn_col_length_new_emp;
    WHEN cn_col_pos_new_route THEN
       -- �V���[�gNo�`�F�b�N�d�l
      ov_check          := cv_yes;
      ov_allow_null     := xxccp_common_pkg2.gv_null_ok;
      on_length         := cn_col_length_new_route;
    WHEN cn_col_pos_reflect_method THEN
       -- ���f���@�`�F�b�N�d�l
      ov_check          := cv_yes;
      ov_allow_null     := xxccp_common_pkg2.gv_null_ng;
      on_length         := cn_col_length_reflect_method;
    END CASE;
--
  EXCEPTION
    --*** �����G���[��O ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
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
  END get_check_spec;
--
  /**********************************************************************************
   * Procedure Name   : fnc_check_data
   * Description      : ���̓f�[�^�`�F�b�N����(A-4)
   ***********************************************************************************/
  PROCEDURE fnc_check_data(
     in_line_cnt        IN  NUMBER    -- 1.�s�ԍ�
    ,iv_column          IN  VARCHAR2  -- 2.���ږ�
    ,iv_col_val         IN  VARCHAR2  -- 3.���ڒl
    ,iv_allow_null      IN  VARCHAR2  -- 4.�K�{�`�F�b�N
    ,in_length          IN  NUMBER    -- 6.���ڒ�
    ,ov_errbuf          OUT VARCHAR2  --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode         OUT VARCHAR2  --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg          OUT VARCHAR2  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'fnc_check_data'; -- �v���O������
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
    lv_warn_flag  VARCHAR2(1);  -- �x���L��t���O
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
    lv_warn_flag := cv_no;
--
    IF (iv_allow_null = xxccp_common_pkg2.gv_null_ng) THEN
      -- �K�{���̓`�F�b�N
      IF (iv_col_val IS NULL) THEN
        -- �K�{���ڃG���[�i�����s�j
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_err_required
                       ,iv_token_name1  => cv_tkn_column
                       ,iv_token_value1 => iv_column
                       ,iv_token_name2  => cv_tkn_index
                       ,iv_token_value2 => in_line_cnt
                     );
        -- �K�{���ڃG���[�i�����s�j�G���[���b�Z�[�W�o��
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        lv_warn_flag  := cv_yes;
      END IF;
    END IF;
--
    IF ( iv_col_val IS NOT NULL ) THEN
      -- �����`�F�b�N
      -- ���ʊ֐��u���ڃ`�F�b�N�v�ɂă`�F�b�N
      xxccp_common_pkg2.upload_item_check(
         iv_item_name    => iv_column                     -- 1.���ږ���(���{�ꖼ)
        ,iv_item_value   => iv_col_val                    -- 2.���ڂ̒l
        ,in_item_len     => in_length                     -- 3.���ڂ̒���
        ,in_item_decimal => NULL                          -- 4.���ڂ̒���(�����_�ȉ�)
        ,iv_item_nullflg => xxccp_common_pkg2.gv_null_ok  -- 5.�K�{�t���O
        ,iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2 -- 6.���ڑ���
        ,ov_errbuf       => lv_errbuf                     --   �G���[�E���b�Z�[�W           --# �Œ� #
        ,ov_retcode      => lv_retcode                    --   ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg       => lv_errmsg                     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode <> cv_status_normal) THEN
        -- �^�E�����`�F�b�N�G���[���b�Z�[�W
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_err_invalid
                       ,iv_token_name1  => cv_tkn_column
                       ,iv_token_value1 => iv_column
                       ,iv_token_name2  => cv_tkn_index
                       ,iv_token_value2 => in_line_cnt
                     );
        -- �^�E�����`�F�b�N�G���[���b�Z�[�W�o��
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        lv_warn_flag  := cv_yes;
      END IF;
    END IF;
--
    -- �X�e�[�^�X�̐ݒ�
    IF ( lv_warn_flag = cv_yes ) THEN
      ov_retcode   := cv_status_warn;
    END IF;
--
  EXCEPTION
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
  END fnc_check_data;
--
  /**********************************************************************************
   * Procedure Name   : check_input_data
   * Description      : ���̓f�[�^�`�F�b�N(A-5)
   ***********************************************************************************/
  PROCEDURE check_input_data(
     iv_fmt_ptn             IN  VARCHAR2           -- 1.�t�H�[�}�b�g�p�^�[��
    ,it_route_emp_data_tab  IN  gt_rec_data_ttype  -- 2.���[�gNo�^�c�ƈ��f�[�^�z��
    ,ov_errbuf              OUT VARCHAR2           --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode             OUT VARCHAR2           --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg              OUT VARCHAR2           --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_input_data'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    ln_line_cnt    NUMBER;          -- ���R�[�h�P�ʔz��Y����
    ln_col_cnt     NUMBER;          -- ���ڒP�ʔz��Y����
    lv_allow_null  VARCHAR2(30);    -- NULL����
    ln_length      NUMBER;          -- ���ڒ�
    lv_check       VARCHAR2(1);     -- �`�F�b�N�v��
    lv_warn_flag   VARCHAR2(1);     -- �x���L��t���O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���R�[�h�P�ʂ̃��[�v
    <<chk_line_loop>>
    FOR ln_line_cnt IN 2 .. it_route_emp_data_tab.COUNT LOOP
      -- ���ڒP�ʂ̃��[�v
      <<chk_col_loop>>
      FOR ln_col_cnt IN 1 .. it_route_emp_data_tab(ln_line_cnt).COUNT LOOP
--
        -- ������
        lv_allow_null := NULL;  -- NULL����
        ln_length     := NULL;  -- ���ڒ�
        lv_check      := NULL;  -- �`�F�b�N�v��
        lv_warn_flag  := cv_no; -- �x���L��t���O
--
        -- ===============================
        -- ���̓f�[�^�`�F�b�N�d�l�擾(A-3)
        -- ===============================
        get_check_spec(
           in_col_pos     => ln_col_cnt    -- ���ڈʒu
          ,ov_check       => lv_check      -- �`�F�b�N�v��
          ,ov_allow_null  => lv_allow_null -- NULL����
          ,on_length      => ln_length     -- ���ڒ�
          ,ov_errbuf      => lv_errbuf
          ,ov_retcode     => lv_retcode
          ,ov_errmsg      => lv_errmsg
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
        -- �`�F�b�N���K�v�ȏꍇ�̂ݏ���
        IF ( lv_check = cv_yes ) THEN
          -- ===============================
          -- ���̓f�[�^�`�F�b�N����(A-4)
          -- ===============================
          fnc_check_data(
             in_line_cnt       => ln_line_cnt - 1
            ,iv_column         => it_route_emp_data_tab(cn_header_rec)(ln_col_cnt)
            ,iv_col_val        => it_route_emp_data_tab(ln_line_cnt)(ln_col_cnt)
            ,iv_allow_null     => lv_allow_null
            ,in_length         => ln_length
            ,ov_errbuf         => lv_errbuf
            ,ov_retcode        => lv_retcode
            ,ov_errmsg         => lv_errmsg
          );
          IF (lv_retcode = cv_status_warn) THEN
            lv_warn_flag := cv_yes;
          ELSIF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
--
        IF ( ln_col_cnt = cn_col_pos_reflect_method ) THEN
          -- ���f���@�́A�l�̓��e���`�F�b�N
          IF (
               ( it_route_emp_data_tab(ln_line_cnt)(ln_col_cnt) <> cv_immediate )   -- ����
               AND
               ( it_route_emp_data_tab(ln_line_cnt)(ln_col_cnt) <> cv_reservation ) -- �\��
             )
          THEN
            -- �f�[�^�敪�`�F�b�N�G���[���b�Z�[�W
            lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_app_name
                            ,iv_name         => cv_msg_err_no_ref_method
                            ,iv_token_name1  => cv_tkn_data_div_val
                            ,iv_token_value1 => it_route_emp_data_tab(ln_line_cnt)(ln_col_cnt)
                            ,iv_token_name2  => cv_tkn_index
                            ,iv_token_value2 => ln_line_cnt - 1
                          );
            -- �f�[�^�敪�`�F�b�N�G���[���b�Z�[�W�o��
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
            lv_warn_flag := cv_yes;
          END IF;
--
        END IF;
--
        -- �X�e�[�^�X�E�x�������ݒ�
        IF ( lv_warn_flag = cv_yes ) THEN
          ov_retcode  := cv_status_warn;
          gn_warn_cnt := gn_warn_cnt + 1;
        END IF;
--
      END LOOP chk_col_loop;
--
    END LOOP chk_line_loop;
--
  EXCEPTION
    -- *** �����G���[��O ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
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
  END check_input_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_route_emp_upload_work
   * Description      : ���[�gNo�^�c�ƈ��A�b�v���[�h���ԃe�[�u���o�^(A-6)
   ***********************************************************************************/
  PROCEDURE ins_route_emp_upload_work(
     in_file_id             IN  NUMBER             -- 1.�t�@�C��ID
    ,it_route_emp_data_tab  IN  gt_rec_data_ttype  -- 2.���[�gNo�^�c�ƈ��f�[�^�z��v
    ,ov_errbuf              OUT VARCHAR2           --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode             OUT VARCHAR2           --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg              OUT VARCHAR2           --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_route_emp_upload_work'; -- �v���O������
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
    ln_line_cnt  NUMBER;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    <<ins_line_loop>>
    FOR ln_line_cnt IN 2 .. it_route_emp_data_tab.COUNT LOOP
      BEGIN
        INSERT INTO xxcso_tmp_rtn_rsrc_work(
           file_id
          ,line_no
          ,account_number
          ,new_route_no
          ,new_employee_number
          ,reflect_method
        ) VALUES (
           in_file_id
          ,ln_line_cnt - 1
          ,it_route_emp_data_tab(ln_line_cnt)(cn_col_pos_cust_code)
          ,it_route_emp_data_tab(ln_line_cnt)(cn_col_pos_new_route)
          ,it_route_emp_data_tab(ln_line_cnt)(cn_col_pos_new_emp)
          ,it_route_emp_data_tab(ln_line_cnt)(cn_col_pos_reflect_method)
        );
      EXCEPTION
        WHEN OTHERS THEN
          -- �f�[�^�o�^�G���[���b�Z�[�W
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_err_ins_data
                         ,iv_token_name1  => cv_tkn_action
                         ,iv_token_value1 => cv_tbl_nm_work
                         ,iv_token_name2  => cv_tkn_error_message
                         ,iv_token_value2 => SQLERRM
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    END LOOP ins_line_loop;
--
  EXCEPTION
    --*** �����G���[��O ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
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
  END ins_route_emp_upload_work;
--
  /**********************************************************************************
   * Procedure Name   : check_business_data
   * Description      : �Ɩ��G���[�`�F�b�N(A-7)
   ***********************************************************************************/
  PROCEDURE check_business_data(
     in_file_id                 IN  NUMBER                   -- 1.�t�@�C��ID
    ,ot_ref_route_emp_data_tab  OUT gt_ref_route_emp_ttype   --   ���[�gNo/�c�ƒS�����f�f�[�^
    ,ov_errbuf                  OUT VARCHAR2                 --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode                 OUT VARCHAR2                 --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg                  OUT VARCHAR2                 --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_business_data'; -- �v���O������
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
    cv_00                      CONSTANT VARCHAR2(2) := '00';                      -- �_�~�[�ڋq�敪
    cv_dummy                   CONSTANT VARCHAR2(1) := '#';                       -- �V�S���E�V���[�g��NULL�̏ꍇ�̃_�~�[�l
--
    -- *** ���[�J���ϐ� ***
    ln_cust_cnt                NUMBER;                                            -- �ڋq�d���`�F�b�N�p
    lt_cust_account_id         hz_cust_accounts.cust_account_id%TYPE;             -- �ڋq���i�ڋqID�j
    lt_customer_class_code     hz_cust_accounts.customer_class_code%TYPE;         -- �ڋq���i�ڋq�敪)
    lt_customer_status         hz_parties.duns_number_c%TYPE;                     -- �ڋq���i�ڋq�X�e�[�^�X)
    lt_sale_base_code          xxcmm_cust_accounts.sale_base_code%TYPE;           -- �ڋq���i���㋒�_)
    lt_rsv_sale_base_code      xxcmm_cust_accounts.rsv_sale_base_code%TYPE;       -- �ڋq���i�\�񔄏㋒�_)
    lt_rsv_sale_base_act_date  xxcmm_cust_accounts.rsv_sale_base_act_date%TYPE;   -- �ڋq���i�\�񔄏㋒�_�L���J�n��)
    lt_receiv_base_code        xxcmm_cust_accounts.receiv_base_code%TYPE;         -- �ڋq���i�������_�R�[�h)
    lt_receiv_cust_flag        fnd_lookup_values_vl.attribute1%TYPE;              -- ���|���Ǘ���ڋq�t���O
    lt_trgt_resource           hz_org_profiles_ext_b.c_ext_attr1%TYPE;            -- ���S��(DB)
    lt_next_resource           hz_org_profiles_ext_b.c_ext_attr1%TYPE;            -- �V�S��(DB)
    lt_next_resource_id        hz_org_profiles_ext_b.extension_id%TYPE;           -- �V�S���g��ID(DB)
    lt_trgt_resource_id        hz_org_profiles_ext_b.extension_id%TYPE;           -- ���S���g��ID(DB)
    lt_next_route              hz_org_profiles_ext_b.c_ext_attr1%TYPE;            -- �V���[�gNo(DB)
    lt_next_route_id           hz_org_profiles_ext_b.extension_id%TYPE;           -- �V���[�gNo�g��ID(DB)
    lt_trgt_route_id           hz_org_profiles_ext_b.extension_id%TYPE;           -- �����[�gNo�g��ID(DB)
    ln_trgt_resource_cnt       NUMBER;                                            -- �ڋq�S������
    ln_next_resource_cnt       NUMBER;                                            -- �ڋq�S�������i�������j
    lv_err_msg                 VARCHAR2(5000);                                    -- �G���[���e�i���ʊ֐��j
    lt_check_base_code         xxcmm_cust_accounts.sale_base_code%TYPE;           -- �`�F�b�N�p���_
    ld_judgment_date           DATE;                                              -- ������t
    ld_reflect_emp_date        DATE;                                              -- ���f���i�S���j
    ld_reflect_route_date      DATE;                                              -- ���f���i���[�g�j
    lv_check_flag              VARCHAR2(1);                                       -- �Z�L�����e�B�`�F�b�N�p�t���O
    lv_message_code            VARCHAR2(30);                                      -- ���b�Z�[�W�R�[�h
    lv_check_emp_flag          VARCHAR2(1);                                       -- �c�ƈ��������_�`�F�b�N�p�t���O
    lv_warn_flag               VARCHAR2(1);                                       -- �x���L��t���O
    lv_emp_change_flag         VARCHAR2(1);                                       -- �V�S���ύX�t���O
    lv_route_change_flag       VARCHAR2(1);                                       -- �V���[�gNo�ύX�t���O
    ln_ref_cnt                 NUMBER := 0;                                       -- ���f�p�̔z��Y����
--
    -- *** ���[�J���E�J�[�\�� ***
    -- ���[�gNo�^�c�ƈ��A�b�v���[�h���ԃe�[�u���擾
    CURSOR route_emp_upload_work_cur
    IS
      SELECT  xtrrw.line_no              line_no
             ,xtrrw.account_number       account_number
             ,xtrrw.new_route_no         new_route_no
             ,xtrrw.new_employee_number  new_employee_number
             ,xtrrw.reflect_method       reflect_method
      FROM    xxcso_tmp_rtn_rsrc_work xtrrw
      WHERE   xtrrw.file_id = in_file_id
      ORDER BY
              xtrrw.line_no
      ;
    -- �S���̃Z�L�����e�B�`�F�b�N�p
    CURSOR emp_base_code_cur(
        iv_employee_number VARCHAR2
       ,iv_base_code       VARCHAR2
       ,id_reflect_date    DATE
    )
    IS
      SELECT cv_yes emp_check
      FROM   xxcso_resources_v2 xrv2
      WHERE  xrv2.employee_number = iv_employee_number
      AND    xxcso_util_common_pkg.get_rs_base_code(
                xrv2.resource_id
               ,id_reflect_date
             ) = iv_base_code
      ;
--
    -- *** ���[�J���E���R�[�h ***
    route_emp_upload_work_rec  route_emp_upload_work_cur%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    <<business_data_check_loop>>
    FOR route_emp_upload_work_rec IN route_emp_upload_work_cur LOOP
--
      -- ������
      ln_cust_cnt                := 0;      -- �ڋq�d���`�F�b�N�p
      lt_cust_account_id         := NULL;   -- �ڋq���i�ڋqID�j
      lt_customer_class_code     := NULL;   -- �ڋq���i�ڋq�敪)
      lt_customer_status         := NULL;   -- �ڋq���i�ڋq�X�e�[�^�X)
      lt_sale_base_code          := NULL;   -- �ڋq���i���㋒�_)
      lt_rsv_sale_base_code      := NULL;   -- �ڋq���i�\�񔄏㋒�_)
      lt_rsv_sale_base_act_date  := NULL;   -- �ڋq���i�\�񔄏㋒�_�L���J�n��)
      lt_receiv_base_code        := NULL;   -- �ڋq���i�������_�R�[�h)
      lt_receiv_cust_flag        := cv_no;  -- ���|���Ǘ���ڋq�t���O
      lt_trgt_resource           := NULL;   -- ���S��(DB)
      lt_next_resource_id        := NULL;   -- �V�S���g��ID(DB)
      lt_trgt_resource_id        := NULL;   -- ���S���g��ID(DB)
      lt_next_resource           := NULL;   -- �V�S��(DB)
      lt_next_route              := NULL;   -- �V���[�gNo(DB)
      lt_next_route_id           := NULL;   -- �V���[�gNo�g��ID(DB)
      lt_trgt_route_id           := NULL;   -- �����[�gNo�g��ID(DB)
      ln_trgt_resource_cnt       := 0;      -- �ڋq�S������
      ln_next_resource_cnt       := 0;      -- �ڋq�S�������i�������j
      lv_err_msg                 := NULL;   -- �G���[���e�i���ʊ֐��j
      lt_check_base_code         := NULL;   -- �`�F�b�N�p���_
      ld_judgment_date           := NULL;   -- ������t
      ld_reflect_emp_date        := NULL;   -- ���f��(�S��)
      ld_reflect_route_date      := NULL;   -- ���f��(���[�g)
      lv_check_flag              := cv_no;  -- �Z�L�����e�B�`�F�b�N�p�t���O
      lv_message_code            := NULL;   -- ���b�Z�[�W�R�[�h
      lv_check_emp_flag          := cv_no;  -- �c�ƈ��������_�`�F�b�N�p�t���O
      lv_warn_flag               := cv_no;  -- �x���L��t���O
      lv_emp_change_flag         := cv_no;  -- �V�S���ύX�t���O
      lv_route_change_flag       := cv_no;  -- �V���[�gNo�ύX�t���O
--
      --==================================================
      -- 2.�X�V�Ώۂ̃`�F�b�N
      --==================================================
      IF (
           ( route_emp_upload_work_rec.new_route_no IS NULL )
           AND
           ( route_emp_upload_work_rec.new_employee_number IS NULL )
         )
      THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_err_no_update
                       ,iv_token_name1  => cv_tkn_account
                       ,iv_token_value1 => route_emp_upload_work_rec.account_number
                       ,iv_token_name2  => cv_tkn_index
                       ,iv_token_value2 => route_emp_upload_work_rec.line_no
                     );
        -- �X�V���e�Ȃ��G���[���b�Z�[�W�o��
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        lv_warn_flag := cv_yes;
      END IF;
--
      --==================================================
      -- 3.����t�@�C�����A�ڋq�d���`�F�b�N
      --==================================================
      SELECT COUNT(1)
      INTO   ln_cust_cnt
      FROM   xxcso_tmp_rtn_rsrc_work xtrrw
      WHERE  xtrrw.file_id        = in_file_id
      AND    xtrrw.account_number = route_emp_upload_work_rec.account_number -- ����ڋq
      AND    xtrrw.line_no       <> route_emp_upload_work_rec.line_no        -- ���g�ȊO�̍s
      ;
      -- 0�ȊO�̏ꍇ
      IF ( ln_cust_cnt <> 0 ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_err_dup_cust
                       ,iv_token_name1  => cv_tkn_account
                       ,iv_token_value1 => route_emp_upload_work_rec.account_number
                       ,iv_token_name2  => cv_tkn_index
                       ,iv_token_value2 => route_emp_upload_work_rec.line_no
                     );
        -- �ڋq�d���G���[���b�Z�[�W�o��
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        lv_warn_flag := cv_yes;
      END IF;
--
      --==================================================
      -- 4.�ڋq�}�X�^�̃`�F�b�N
      --==================================================
      -- 4-1.�}�X�^�̎擾
      BEGIN
        SELECT  hca.cust_account_id         cust_account_id         -- �ڋqID
               ,hca.customer_class_code     customer_class_code     -- �ڋq�敪
               ,hp.duns_number_c            customer_status         -- �ڋq�X�e�[�^�X
               ,xca.sale_base_code          sale_base_code          -- ���㋒�_
               ,xca.rsv_sale_base_code      rsv_sale_base_code      -- �\�񔄏㋒�_
               ,xca.rsv_sale_base_act_date  rsv_sale_base_act_date  -- �\�񔄏㋒�_�L���J�n��
               ,xca.receiv_base_code        receiv_base_code        -- �������_
        INTO    lt_cust_account_id
               ,lt_customer_class_code
               ,lt_customer_status
               ,lt_sale_base_code
               ,lt_rsv_sale_base_code
               ,lt_rsv_sale_base_act_date
               ,lt_receiv_base_code
        FROM    hz_cust_accounts    hca
               ,hz_parties          hp
               ,xxcmm_cust_accounts xca
        WHERE   hca.account_number  = route_emp_upload_work_rec.account_number
        AND     hca.party_id        = hp.party_id
        AND     hca.cust_account_id = xca.customer_id(+)
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_err_no_cust
                         ,iv_token_name1  => cv_tkn_account
                         ,iv_token_value1 => route_emp_upload_work_rec.account_number
                         ,iv_token_name2  => cv_tkn_index
                         ,iv_token_value2 => route_emp_upload_work_rec.line_no
                       );
          -- �ڋq�擾�G���[���b�Z�[�W�o��
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          lv_warn_flag := cv_yes;
      END;
--
      -- 4-2.�ڋq�敪�E�ڋq�X�e�[�^�X���Ώۂ��`�F�b�N
      BEGIN
        SELECT flvv.attribute1 receiv_cust_flag
        INTO   lt_receiv_cust_flag
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type     = cv_lkup_route_mgr_cust_class
        AND    flvv.lookup_code     = NVL( lt_customer_class_code, cv_00) || '-' || lt_customer_status
        AND    gd_process_date      BETWEEN flvv.start_date_active
                                    AND     NVL( flvv.end_date_active, gd_process_date )
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_err_class_status
                         ,iv_token_name1  => cv_tkn_account
                         ,iv_token_value1 => route_emp_upload_work_rec.account_number
                         ,iv_token_name2  => cv_tkn_class
                         ,iv_token_value2 => lt_customer_class_code
                         ,iv_token_name3  => cv_tkn_status
                         ,iv_token_value3 => lt_customer_status
                         ,iv_token_name4  => cv_tkn_index
                         ,iv_token_value4 => route_emp_upload_work_rec.line_no
                       );
          -- �ڋq�敪�E�X�e�[�^�X�ΏۊO�G���[���b�Z�[�W�o��
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          lv_warn_flag := cv_yes;
      END;
--
      --==================================================
      -- 5.���[�gNo�^�S���c�Ƃ̃`�F�b�N
      --==================================================
      -- 5-1.���[�gNo�^�S���c�Ǝ擾
      BEGIN
        SELECT  xrrv.trgt_resource                 trgt_resource                -- ���S��
               ,xrrv.next_resource                 next_resource                -- �V�S��
               ,xrrv.next_resource_extension_id    next_resource_extension_id   -- �V�S���g��ID
               ,xrrv.trgt_resource_extension_id    trgt_route_no_extension_id   -- ���S���g��ID
               ,xrrv.next_route_no                 next_route                   -- �V���[�gNo
               ,xrrv.next_route_no_extension_id    next_route_no_extension_id   -- �V���[�gNo�g��ID
               ,xrrv.trgt_route_no_extension_id    trgt_route_no_extension_id   -- �����[�gNo�g��ID
               ,xrrv.trgt_resource_cnt             trgt_resource_cnt            -- �ڋq�S���Ґ�
               ,xrrv.next_resource_cnt             next_resource_cnt            -- �ڋq�S���Ґ��i�������j
        INTO    lt_trgt_resource
               ,lt_next_resource
               ,lt_next_resource_id
               ,lt_trgt_resource_id
               ,lt_next_route
               ,lt_next_route_id
               ,lt_trgt_route_id
               ,ln_trgt_resource_cnt
               ,ln_next_resource_cnt
        FROM    xxcso_rtn_rsrc_v xrrv
        WHERE   xrrv.cust_account_id = lt_cust_account_id
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_err_cust_resouce
                         ,iv_token_name1  => cv_tkn_account
                         ,iv_token_value1 => route_emp_upload_work_rec.account_number
                         ,iv_token_name2  => cv_tkn_err_msg
                         ,iv_token_value2 => SQLERRM
                         ,iv_token_name3  => cv_tkn_index
                         ,iv_token_value3 => route_emp_upload_work_rec.line_no
                       );
          -- �ڋq�S���擾�G���[���b�Z�[�W�o��
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          lv_warn_flag := cv_yes;
      END;
--
      -- 5-2.�Ώۂ̌ڋq�ɂ��āA�����O�Ɋ��ɏd�����Ă��Ȃ����Ƃ��`�F�b�N
      if ( ln_trgt_resource_cnt > 1 OR ln_next_resource_cnt > 1) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_err_dup_resouce
                         ,iv_token_name1  => cv_tkn_account
                         ,iv_token_value1 => route_emp_upload_work_rec.account_number
                         ,iv_token_name2  => cv_tkn_index
                         ,iv_token_value2 => route_emp_upload_work_rec.line_no
                       );
          -- �ڋq�S���擾�G���[���b�Z�[�W�o��
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          lv_warn_flag := cv_yes;
      END IF;
--
      -- 5-3.�V�S�����u-�v(�폜)�ŁA�\��łȂ��ꍇ
      IF (
           ( route_emp_upload_work_rec.new_employee_number = cv_delete )
           AND
           ( route_emp_upload_work_rec.reflect_method <> cv_reservation )
         ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_err_reflect_method
                       ,iv_token_name1  => cv_tkn_column
                       ,iv_token_value1 => cv_emp_date
                       ,iv_token_name2  => cv_tkn_account
                       ,iv_token_value2 => route_emp_upload_work_rec.account_number
                       ,iv_token_name3  => cv_tkn_index
                       ,iv_token_value3 => route_emp_upload_work_rec.line_no
                     );
        -- ���f���@�w��G���[���b�Z�[�W�o��
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        lv_warn_flag := cv_yes;
      END IF;
--
      --------------------------
      -- 6.���|�Ǘ��ڋq�ȊO
      --------------------------
      IF ( lt_receiv_cust_flag = cv_no ) THEN
--
         -- 6-1.���[�gNo�̃`�F�b�N(���[�gNo��NOT NULL)
         IF ( route_emp_upload_work_rec.new_route_no IS NOT NULL ) THEN
--
           -- 6-1-1.���[�gNo���폜�ȊO
           IF ( route_emp_upload_work_rec.new_route_no <> cv_delete ) THEN
             -- ROUTE�֘A���ʊ֐��ɂ��Ó����`�F�b�N
             IF ( xxcso_route_common_pkg.validate_route_no(
                    route_emp_upload_work_rec.new_route_no
                   ,lv_err_msg ) = FALSE ) THEN
               lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_app_name
                              ,iv_name         => cv_msg_err_route_chack
                              ,iv_token_name1  => cv_tkn_account
                              ,iv_token_value1 => route_emp_upload_work_rec.account_number
                              ,iv_token_name2  => cv_tkn_route
                              ,iv_token_value2 => route_emp_upload_work_rec.new_route_no
                              ,iv_token_name3  => cv_tkn_err_msg
                              ,iv_token_value3 => lv_err_msg
                              ,iv_token_name4  => cv_tkn_index
                              ,iv_token_value4 => route_emp_upload_work_rec.line_no
                            );
               -- ���[�gNo�Ó����`�F�b�N�G���[���b�Z�[�W�o��
               fnd_file.put_line(
                  which  => FND_FILE.OUTPUT
                 ,buff   => lv_errmsg
               );
               lv_warn_flag := cv_yes;
             END IF;
           -- 6-2.���[�gNo���폜�̏ꍇ
           ELSE
             -- ���f���@���\��łȂ��ꍇ
             IF ( route_emp_upload_work_rec.reflect_method <> cv_reservation ) THEN
               lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_app_name
                              ,iv_name         => cv_msg_err_reflect_method
                              ,iv_token_name1  => cv_tkn_column
                              ,iv_token_value1 => cv_route_date
                              ,iv_token_name2  => cv_tkn_account
                              ,iv_token_value2 => route_emp_upload_work_rec.account_number
                              ,iv_token_name3  => cv_tkn_index
                              ,iv_token_value3 => route_emp_upload_work_rec.line_no
                            );
               -- ���f���@�w��G���[���b�Z�[�W�o��
               fnd_file.put_line(
                  which  => FND_FILE.OUTPUT
                 ,buff   => lv_errmsg
               );
               lv_warn_flag := cv_yes;
             END IF;
           END IF;
         END IF;
--
         -------------------------------------------------
         -- 6-3.���㋒�_�E�\�񔄏㋒�_�Ɣ��肷����t�̔���
         -------------------------------------------------
         -- 6-3-1.����
         IF ( route_emp_upload_work_rec.reflect_method = cv_immediate ) THEN
           -- �ڋq�̔��㋒�_
           lt_check_base_code := lt_sale_base_code;
           -- ������͋Ɩ����t
           ld_judgment_date   := gd_process_date;
           -- ���b�Z�[�W�R�[�h����
           lv_message_code    := cv_msg_immediate;
         -- 6-3-2.�\��
         ELSE
           -- �@.����1�� < �\��� OR �\���NULL
           IF (
                ( lt_rsv_sale_base_act_date IS NULL )
                OR
                ( gd_next_month_date < lt_rsv_sale_base_act_date )
              ) THEN
             -- �ڋq�̔��㋒�_
             lt_check_base_code := lt_sale_base_code;
-- Ver1.1 Mod Start
             -- ������͋Ɩ����t����1��
--             ld_judgment_date   := gd_process_date;
             ld_judgment_date   := gd_next_month_date;
-- Ver1.1 Mod End
           -- �A.����1�� >= �\���
           ELSE
             -- �ڋq�̗\�񔄏㋒�_
             lt_check_base_code := lt_rsv_sale_base_code;
             -- ������͋Ɩ����t����1��
             ld_judgment_date   := gd_next_month_date;
           END IF;
           -- ���b�Z�[�W�R�[�h�\��
           lv_message_code    := cv_msg_reservation;
         END IF;
--
         -- 6-4.�ڋq�̔��㋒�_�E�\�񔄏㋒�_��NULL�A���A���S����NULL�łȂ����`�F�b�N�i�ڋq�̒l���X�g�̃`�F�b�N�j
         IF (
              ( lt_check_base_code IS NULL )
              AND
              ( lt_trgt_resource IS NULL )
            ) THEN
           lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name
                          ,iv_name         => cv_msg_err_cust_inadequacy
                          ,iv_token_name1  => cv_tkn_account
                          ,iv_token_value1 => route_emp_upload_work_rec.account_number
                          ,iv_token_name2  => cv_tkn_index
                          ,iv_token_value2 => route_emp_upload_work_rec.line_no
                        );
           -- �ڋq�ݒ�s���G���[���b�Z�[�W�o��
           fnd_file.put_line(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_errmsg
           );
           lv_warn_flag := cv_yes;
         END IF;
--
         -- 6-5.���㋒�_�i�\�񔄏㋒�_�j��NULL�łȂ��ꍇ
         IF ( lt_check_base_code IS NOT NULL ) THEN
           -- 6-5-1.�Z�L�����e�B����
           IF ( gv_security_019_a09 <> cv_no_security ) THEN
             -- �@.��������_�Ŕ��㋒�_�i�\�񔄏㋒�_�j�����s�҂̎����_�łȂ����`�F�b�N�i�ڋq�Ǝ��s�҂̃`�F�b�N�j
             << base_chk >>
             FOR i IN 1.. gt_base_code_tab.COUNT LOOP
               -- ���s�҂̎����_�ł��邩�`�F�b�N
               IF ( gt_base_code_tab(i) = lt_check_base_code ) THEN
                 lv_check_flag := cv_yes;
               END IF;
             END LOOP base_chk;
             -- �`�F�b�N�t���O��Y�łȂ��ꍇ
             IF ( lv_check_flag <> cv_yes ) THEN
               lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_app_name
                              ,iv_name         => cv_msg_err_security
                              ,iv_token_name1  => cv_tkn_data_div
                              ,iv_token_value1 => lv_message_code
                              ,iv_token_name2  => cv_tkn_account
                              ,iv_token_value2 => route_emp_upload_work_rec.account_number
                              ,iv_token_name3  => cv_tkn_base_code
                              ,iv_token_value3 => lt_check_base_code
                              ,iv_token_name4  => cv_tkn_index
                              ,iv_token_value4 => route_emp_upload_work_rec.line_no
                            );
               -- �ڋq�Z�L�����e�B�G���[���b�Z�[�W�o��
               fnd_file.put_line(
                  which  => FND_FILE.OUTPUT
                 ,buff   => lv_errmsg
               );
               lv_warn_flag := cv_yes;
             END IF;
           END IF;
--
           -- 6-5-2.�Z�L�����e�B����E�Ȃ�����
           -- �V�S�����u-�v�ȊO
           IF ( route_emp_upload_work_rec.new_employee_number <> cv_delete ) THEN
             -- ���㋒�_�i�\�񔄏㋒�_�j����������_�ł̐V�S���̏������_���������`�F�b�N�i�ڋq�ƐV�S���̃`�F�b�N�j
             OPEN emp_base_code_cur(
                route_emp_upload_work_rec.new_employee_number   -- �V�S��
               ,lt_check_base_code                              -- ���㋒�_�i�\�񔄏㋒�_�j
               ,ld_judgment_date                                -- ���f��
             );
             FETCH emp_base_code_cur INTO lv_check_emp_flag;
             CLOSE emp_base_code_cur;
             -- �c�ƈ��������_�`�F�b�N�p�t���O���uY�v�łȂ��ꍇ
             IF ( lv_check_emp_flag <> cv_yes ) THEN
               lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_app_name
                              ,iv_name         => cv_msg_err_emp_base
                              ,iv_token_name1  => cv_tkn_data_div
                              ,iv_token_value1 => lv_message_code
                              ,iv_token_name2  => cv_tkn_account
                              ,iv_token_value2 => route_emp_upload_work_rec.account_number
                              ,iv_token_name3  => cv_tkn_base_code
                              ,iv_token_value3 => lt_check_base_code
                              ,iv_token_name4  => cv_tkn_index
                              ,iv_token_value4 => route_emp_upload_work_rec.line_no
                            );
                 -- �S���Z�L�����e�B�G���[���b�Z�[�W�o��
                 fnd_file.put_line(
                    which  => FND_FILE.OUTPUT
                   ,buff   => lv_errmsg
                 );
                 lv_warn_flag := cv_yes;
             END IF;
           END IF;
         -- 6-6.���㋒�_�E�\�񔄏㋒�_��NULL�̏ꍇ
         ELSE
             -- 6-6-1.���s�����_�̌��S���̏������_���擾
             BEGIN
               SELECT xxcso_util_common_pkg.get_rs_base_code(
                         xrv2.resource_id
                        ,gd_process_date
                      ) trgt_emp_base
               INTO   lt_check_base_code
               FROM   xxcso_resources_v2 xrv2
               WHERE  xrv2.employee_number = lt_trgt_resource
               ;
             EXCEPTION
               WHEN OTHERS THEN
                 lv_errmsg := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_app_name
                                ,iv_name         => cv_msg_err_trgt_emp_base
                                ,iv_token_name1  => cv_tkn_account
                                ,iv_token_value1 => route_emp_upload_work_rec.account_number
                                ,iv_token_name2  => cv_tkn_emp_code
                                ,iv_token_value2 => lt_trgt_resource
                                ,iv_token_name3  => cv_tkn_err_msg
                                ,iv_token_value3 => SQLERRM
                                ,iv_token_name4  => cv_tkn_index
                                ,iv_token_value4 => route_emp_upload_work_rec.line_no
                              );
                 -- ���S���擾�G���[���b�Z�[�W�o��
                 fnd_file.put_line(
                    which  => FND_FILE.OUTPUT
                   ,buff   => lv_errmsg
                 );
                 lv_warn_flag := cv_yes;
             END;
--
             -- 6-6-2.�Z�L�����e�B����
             IF ( gv_security_019_a09 <> cv_no_security ) THEN
               -- �@.���S���̏������_�����s�����_�̎��s�҂̎����_�łȂ��i�ڋq�Ǝ��s�҂̃`�F�b�N�j
               << base_chk2 >>
               FOR i IN 1.. gt_base_code_tab.COUNT LOOP
                 -- ���S���̏������_�����s�҂̎����_�ł��邩�`�F�b�N
                 IF ( gt_base_code_tab(i) = lt_check_base_code ) THEN
                   lv_check_flag := cv_yes;
                 END IF;
               END LOOP base_chk2;
               -- �`�F�b�N�t���O���uY�v�łȂ��ꍇ
               IF ( lv_check_flag <> cv_yes ) THEN
                 lv_errmsg := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_app_name
                                ,iv_name         => cv_msg_err_security
                                ,iv_token_name1  => cv_tkn_data_div
                                ,iv_token_value1 => lv_message_code
                                ,iv_token_name2  => cv_tkn_account
                                ,iv_token_value2 => route_emp_upload_work_rec.account_number
                                ,iv_token_name3  => cv_tkn_base_code
                                ,iv_token_value3 => lt_check_base_code
                                ,iv_token_name4  => cv_tkn_index
                                ,iv_token_value4 => route_emp_upload_work_rec.line_no
                              );
                 -- �ڋq�Z�L�����e�B�G���[���b�Z�[�W�o��
                 fnd_file.put_line(
                    which  => FND_FILE.OUTPUT
                   ,buff   => lv_errmsg
                 );
                 lv_warn_flag := cv_yes;
               END IF;
             END IF;
--
             -- 6-6-2.�Z�L�����e�B����E�Ȃ�����
             -- �V�S�����u-�v�ȊO
             IF ( route_emp_upload_work_rec.new_employee_number <> cv_delete ) THEN
               -- �@.���S���̏������_����������_�ł̐V�S���̏������_���������`�F�b�N�i�ڋq�ƐV�S���̃`�F�b�N�j
               OPEN emp_base_code_cur(
                       route_emp_upload_work_rec.new_employee_number   -- �V�S��
                      ,lt_check_base_code                              -- ���S���̋��_
                      ,ld_judgment_date                                -- ���f��
                    );
               FETCH emp_base_code_cur INTO lv_check_emp_flag;
               CLOSE emp_base_code_cur;
               -- �c�ƈ��������_�`�F�b�N�p�t���O���uY�v�łȂ��ꍇ
               IF ( lv_check_emp_flag <> cv_yes ) THEN
                 lv_errmsg := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_app_name
                                ,iv_name         => cv_msg_err_emp_base
                                ,iv_token_name1  => cv_tkn_data_div
                                ,iv_token_value1 => lv_message_code
                                ,iv_token_name2  => cv_tkn_account
                                ,iv_token_value2 => route_emp_upload_work_rec.account_number
                                ,iv_token_name3  => cv_tkn_base_code
                                ,iv_token_value3 => lt_check_base_code
                                ,iv_token_name4  => cv_tkn_index
                                ,iv_token_value4 => route_emp_upload_work_rec.line_no
                              );
                 -- �S���Z�L�����e�B�G���[���b�Z�[�W�o��
                 fnd_file.put_line(
                    which  => FND_FILE.OUTPUT
                   ,buff   => lv_errmsg
                 );
                 lv_warn_flag := cv_yes;
               END IF;
             END IF;
           END IF;
      --------------------------
      -- 7.���|�Ǘ��ڋq
      --------------------------
      ELSE
--
         -- ������̐ݒ�
         ld_judgment_date := gd_process_date; -- �Ɩ����t
--
         -- 7-1.�V���[�gNo��NOT NULL�̏ꍇ
         IF ( route_emp_upload_work_rec.new_route_no IS NOT NULL ) THEN
           lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name
                        ,iv_name         => cv_msg_err_payment_cust_route
                        ,iv_token_name1  => cv_tkn_account
                        ,iv_token_value1 => route_emp_upload_work_rec.account_number
                        ,iv_token_name2  => cv_tkn_index
                        ,iv_token_value2 => route_emp_upload_work_rec.line_no
                      );
           -- ���|���Ǘ���ڋq���[�gNo�ݒ�G���[���b�Z�[�W�o��
           fnd_file.put_line(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_errmsg
           );
           lv_warn_flag := cv_yes;
         END IF;
         -- 7-2.�\�񔽉f�̏ꍇ
         IF ( route_emp_upload_work_rec.reflect_method = cv_reservation ) THEN
           lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name
                        ,iv_name         => cv_msg_err_payment_reflect
                        ,iv_token_name1  => cv_tkn_account
                        ,iv_token_value1 => route_emp_upload_work_rec.account_number
                        ,iv_token_name2  => cv_tkn_index
                        ,iv_token_value2 => route_emp_upload_work_rec.line_no
                      );
           -- ���|���Ǘ���ڋq���f���@�G�����b�Z�[�W�o��
           fnd_file.put_line(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_errmsg
           );
           lv_warn_flag := cv_yes;
         END IF;
         -- 7-3.�������_��NULL�̏ꍇ
         IF ( lt_receiv_base_code IS NULL ) THEN
           lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name
                        ,iv_name         => cv_msg_err_payment_base
                        ,iv_token_name1  => cv_tkn_account
                        ,iv_token_value1 => route_emp_upload_work_rec.account_number
                        ,iv_token_name2  => cv_tkn_index
                        ,iv_token_value2 => route_emp_upload_work_rec.line_no
                      );
           -- ���|���Ǘ���ڋq�����K�{�G���[���b�Z�[�W�o��
           fnd_file.put_line(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_errmsg
           );
           lv_warn_flag := cv_yes;
         END IF;
         -- 7-4.�V�S����NULL�̏ꍇ
         IF ( route_emp_upload_work_rec.new_employee_number IS NULL ) THEN
           lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name
                        ,iv_name         => cv_msg_err_payment_emp
                        ,iv_token_name1  => cv_tkn_account
                        ,iv_token_value1 => route_emp_upload_work_rec.account_number
                        ,iv_token_name2  => cv_tkn_index
                        ,iv_token_value2 => route_emp_upload_work_rec.line_no
                      );
           -- ���|���Ǘ���ڋq�V�S���K�{�G���[���b�Z�[�W�o��
           fnd_file.put_line(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_errmsg
           );
           lv_warn_flag := cv_yes;
         END IF;
--
         -- 7-5.�Z�L�����e�B����
         IF ( gv_security_019_a09 <> cv_no_security ) THEN
           -- 7-5-1.�������_�����s���_���s�҂̎����_�łȂ��i�ڋq�Ǝ��s�҂̃`�F�b�N�j
           << base_chk3 >>
           FOR i IN 1.. gt_base_code_tab.COUNT LOOP
             -- ���S���̏������_�����s�҂̎����_�ł��邩�`�F�b�N
             IF ( gt_base_code_tab(i) = lt_receiv_base_code ) THEN
               lv_check_flag := cv_yes;
             END IF;
           END LOOP base_chk3;
           -- �`�F�b�N�t���O���uY�v�łȂ��ꍇ
           IF ( lv_check_flag <> cv_yes ) THEN
             lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_app_name
                            ,iv_name         => cv_msg_err_rcv_security
                            ,iv_token_name1  => cv_tkn_account
                            ,iv_token_value1 => route_emp_upload_work_rec.account_number
                            ,iv_token_name2  => cv_tkn_base_code
                            ,iv_token_value2 => lt_receiv_base_code
                            ,iv_token_name3  => cv_tkn_index
                            ,iv_token_value3 => route_emp_upload_work_rec.line_no
                          );
             -- �ڋq�Z�L�����e�B�G���[���b�Z�[�W�o��
             fnd_file.put_line(
                which  => FND_FILE.OUTPUT
               ,buff   => lv_errmsg
             );
             lv_warn_flag := cv_yes;
           END IF;
         END IF;
         -- 7-6.�Z�L�����e�B����E�Ȃ�����
         -- �V�S�����u-�v�ȊO
         IF ( route_emp_upload_work_rec.new_employee_number <> cv_delete ) THEN
           -- 7-6-1.�ڋq�̓������_�ƋƖ����t�̐V�S���̏������_���������i�ڋq�ƐV�S���̃`�F�b�N�j
           OPEN emp_base_code_cur(
                   route_emp_upload_work_rec.new_employee_number   -- �V�S��
                  ,lt_receiv_base_code                             -- �������_
                  ,ld_judgment_date                                -- ���f��(�Ɩ����t)
                );
           FETCH emp_base_code_cur INTO lv_check_emp_flag;
           CLOSE emp_base_code_cur;
           -- �c�ƈ��������_�`�F�b�N�p�t���O���uY�v�łȂ��ꍇ
           IF ( lv_check_emp_flag <> cv_yes ) THEN
             lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_app_name
                            ,iv_name         => cv_msg_err_rcv_emp_base
                            ,iv_token_name1  => cv_tkn_account
                            ,iv_token_value1 => route_emp_upload_work_rec.account_number
                            ,iv_token_name2  => cv_tkn_base_code
                            ,iv_token_value2 => lt_receiv_base_code
                            ,iv_token_name3  => cv_tkn_index
                            ,iv_token_value3 => route_emp_upload_work_rec.line_no
                          );
             -- �S���Z�L�����e�B�G���[���b�Z�[�W�o��
             fnd_file.put_line(
                which  => FND_FILE.OUTPUT
               ,buff   => lv_errmsg
             );
             lv_warn_flag := cv_yes;
           END IF;
         END IF;
      END IF;
--
      -----------------------
      -- 8.�z��ҏW
      -----------------------
      IF ( lv_warn_flag = cv_no ) THEN
        -- �V�S��(CSV)���u-�v(�폜)
        IF ( route_emp_upload_work_rec.new_employee_number = cv_delete ) THEN
          -- �폜
          lv_emp_change_flag := cv_del;
        -- �V�S��(CSV)��NULL
        ELSIF ( route_emp_upload_work_rec.new_employee_number IS NULL) THEN
          -- �ύX�Ȃ�
          lv_emp_change_flag := cv_no;
        ELSE
          -- �V�S��(CSV)�ƐV�S��(DB)�̃f�[�^������
          IF ( route_emp_upload_work_rec.new_employee_number = NVL( lt_next_resource, cv_dummy ) ) THEN
            -- �ύX�Ȃ�
            lv_emp_change_flag := cv_no;
          -- �V�S��(CSV)�ƐV�S��(DB)�̃f�[�^���قȂ�
          ELSIF ( route_emp_upload_work_rec.new_employee_number <> NVL( lt_next_resource, cv_dummy ) ) THEN
            -- �쐬�E�X�V
            lv_emp_change_flag := cv_ins_upd;
          END IF;
        END IF;
--
        -- �V�S��(CSV)���u-�v(�폜)
        IF ( route_emp_upload_work_rec.new_route_no = cv_delete ) THEN
          -- �폜
          lv_route_change_flag := cv_del;
        -- �V�S��(CSV)��NULL
        ELSIF ( route_emp_upload_work_rec.new_route_no IS NULL) THEN
          -- �ύX�Ȃ�
          lv_route_change_flag := cv_no;
        ELSE
          -- �V�S��(CSV)�ƐV�S��(DB)�̃f�[�^������
          IF ( route_emp_upload_work_rec.new_route_no = NVL( lt_next_route, cv_dummy ) ) THEN
            -- �ύX�Ȃ�
            lv_route_change_flag := cv_no;
          -- �V�S��(CSV)�ƐV�S��(DB)�̃f�[�^���قȂ�
          ELSIF ( route_emp_upload_work_rec.new_route_no <> NVL( lt_next_route, cv_dummy ) ) THEN
            -- �쐬�E�X�V
            lv_route_change_flag := cv_ins_upd;
          END IF;
        END IF;
--
        -- ���f���̕ҏW
        -- ����
        IF ( route_emp_upload_work_rec.reflect_method = cv_immediate ) THEN
          ld_reflect_emp_date   := gd_process_date;    -- �Ɩ����t
          ld_reflect_route_date := gd_first_day_date;  -- �Ɩ����t1��
        -- �\��
        ELSE
          ld_reflect_emp_date   := gd_next_month_date; -- �Ɩ�����1��
          ld_reflect_route_date := gd_next_month_date; -- �Ɩ�����1��
        END IF;
--
        -- 8-2.�ҏW�̌��ʁA�X�V�s�v�ȃf�[�^�̃`�F�b�N
        IF (
             ( lv_emp_change_flag = cv_no )
             AND
             ( lv_route_change_flag = cv_no )
           ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_err_no_update
                         ,iv_token_name1  => cv_tkn_account
                         ,iv_token_value1 => route_emp_upload_work_rec.account_number
                         ,iv_token_name2  => cv_tkn_index
                         ,iv_token_value2 => route_emp_upload_work_rec.line_no
                       );
          -- �X�V���e�Ȃ��G���[���b�Z�[�W���b�Z�[�W�o��
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          lv_warn_flag := cv_yes;
        END IF;
      END IF;
--
      IF ( lv_warn_flag = cv_no ) THEN
        -- 8-3.�z��̕ҏW
        ln_ref_cnt := ln_ref_cnt + 1;
        ot_ref_route_emp_data_tab(ln_ref_cnt).line_no               := route_emp_upload_work_rec.line_no;
        ot_ref_route_emp_data_tab(ln_ref_cnt).account_number        := route_emp_upload_work_rec.account_number;
        ot_ref_route_emp_data_tab(ln_ref_cnt).new_employee_number   := route_emp_upload_work_rec.new_employee_number;
        ot_ref_route_emp_data_tab(ln_ref_cnt).new_employee_date     := ld_reflect_emp_date;
        ot_ref_route_emp_data_tab(ln_ref_cnt).trgt_resource_id      := lt_trgt_resource_id;
        ot_ref_route_emp_data_tab(ln_ref_cnt).next_resource_id      := lt_next_resource_id;
        ot_ref_route_emp_data_tab(ln_ref_cnt).new_route_no          := route_emp_upload_work_rec.new_route_no;
        ot_ref_route_emp_data_tab(ln_ref_cnt).new_route_date        := ld_reflect_route_date;
        ot_ref_route_emp_data_tab(ln_ref_cnt).trgt_route_id         := lt_trgt_route_id;
        ot_ref_route_emp_data_tab(ln_ref_cnt).next_route_id         := lt_next_route_id;
        ot_ref_route_emp_data_tab(ln_ref_cnt).employee_change_flag  := lv_emp_change_flag;
        ot_ref_route_emp_data_tab(ln_ref_cnt).route_no_change_flag  := lv_route_change_flag;
      ELSE
        -- 1���ł��x�������݂���ꍇ�A�������ʂ��x���ɂ���
        ov_retcode  := cv_status_warn;
        gn_warn_cnt := gn_warn_cnt + 1;
      END IF;
--
    END LOOP business_data_check_loop;
--
  EXCEPTION
    --*** �����G���[��O ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
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
  END check_business_data;
--
  /**********************************************************************************
   * Procedure Name   : reflect_route_emp
   * Description      : ���[�gNo�^�c�ƒS�����f����(A-8)
   ***********************************************************************************/
  PROCEDURE reflect_route_emp(
     it_ref_route_emp_data_tab  IN  gt_ref_route_emp_ttype -- 1.���[�gNo/�c�ƒS�����f�f�[�^
    ,ov_errbuf                  OUT VARCHAR2               --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode                 OUT VARCHAR2               --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg                  OUT VARCHAR2               --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'reflect_route_emp'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- *** ���[�J���ϐ� ***
    lv_warn_flag               VARCHAR2(1);   -- �x���L��t���O
    lv_message_code            VARCHAR2(30);  -- ���b�Z�[�W�R�[�h
--
    -- *** ���[�J���J�[�\�� ***
    -- �g�D�v���t�@�C���g���̃��b�N�p�J�[�\��
    CURSOR ext_b_lock_cur(
      it_lock_id hz_org_profiles_ext_b.extension_id%TYPE
    )
    IS
      SELECT cv_yes lock_data
      FROM   hz_org_profiles_ext_b hopeb
      WHERE  hopeb.extension_id = it_lock_id
      FOR UPDATE OF
             hopeb.extension_id NOWAIT
    ;
--
    -- *** ���[�J�����R�[�h ***
    ext_b_lock_rec ext_b_lock_cur%ROWTYPE;
--
    -- *** ���[�J����O ***
    local_lock_expt EXCEPTION;  -- ���b�N��O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    << reflect_loop >>
    FOR i IN 1.. it_ref_route_emp_data_tab.COUNT LOOP
--
      BEGIN
        -- ������
        lv_warn_flag := cv_no;
--
        --==================================================
        -- ���b�N����
        --==================================================
        IF (
             ( it_ref_route_emp_data_tab(i).employee_change_flag <> cv_no )
             AND
             ( it_ref_route_emp_data_tab(i).trgt_resource_id IS NOT NULL )
           ) THEN
          -- ���b�Z�[�W�R�[�h�ݒ�
          lv_message_code := cv_msg_trgt_route_date;
          -- 1-1.���S���̃��b�N
          BEGIN
            OPEN  ext_b_lock_cur( it_ref_route_emp_data_tab(i).trgt_resource_id );
            FETCH ext_b_lock_cur INTO ext_b_lock_rec;
            CLOSE ext_b_lock_cur;
          EXCEPTION
            WHEN global_lock_expt THEN
              RAISE local_lock_expt;
          END;
        END IF;
--
        IF (
             ( it_ref_route_emp_data_tab(i).employee_change_flag <> cv_no )
             AND
             ( it_ref_route_emp_data_tab(i).next_resource_id IS NOT NULL )
           ) THEN
          -- ���b�Z�[�W�R�[�h�ݒ�
          lv_message_code := cv_emp_date;
          -- 1-2.�V�S���̃��b�N
          BEGIN
            OPEN  ext_b_lock_cur( it_ref_route_emp_data_tab(i).next_resource_id );
            FETCH ext_b_lock_cur INTO ext_b_lock_rec;
            CLOSE ext_b_lock_cur;
          EXCEPTION
            WHEN global_lock_expt THEN
              RAISE local_lock_expt;
          END;
        END IF;
--
        IF (
             ( it_ref_route_emp_data_tab(i).route_no_change_flag <> cv_no )
             AND
             ( it_ref_route_emp_data_tab(i).trgt_route_id IS NOT NULL )
           ) THEN
          -- ���b�Z�[�W�R�[�h�ݒ�
          lv_message_code := cv_msg_trgt_emp_date;
          -- 1-3.�����[�gNo�̃��b�N
          BEGIN
            OPEN  ext_b_lock_cur( it_ref_route_emp_data_tab(i).trgt_route_id );
            FETCH ext_b_lock_cur INTO ext_b_lock_rec;
            CLOSE ext_b_lock_cur;
          EXCEPTION
            WHEN global_lock_expt THEN
              RAISE local_lock_expt;
          END;
        END IF;
--
        IF (
             ( it_ref_route_emp_data_tab(i).route_no_change_flag <> cv_no )
             AND
             ( it_ref_route_emp_data_tab(i).next_route_id IS NOT NULL )
           ) THEN
          -- ���b�Z�[�W�R�[�h�ݒ�
          lv_message_code := cv_route_date;
          -- 1-4.�V���[�gNo�̃��b�N
          BEGIN
            OPEN  ext_b_lock_cur( it_ref_route_emp_data_tab(i).next_route_id );
            FETCH ext_b_lock_cur INTO ext_b_lock_rec;
            CLOSE ext_b_lock_cur;
          EXCEPTION
            WHEN global_lock_expt THEN
              RAISE local_lock_expt;
          END;
        END IF;
--
        -- �Z�[�u�|�C���g�̔��s
        SAVEPOINT line_save;
--
        --==================================================
        -- �c�ƒS���A���[�gNo�̔��f
        --==================================================
        IF ( it_ref_route_emp_data_tab(i).employee_change_flag = cv_ins_upd ) THEN
--
          -- 1-5.�S���̓o�^�E�X�V
          xxcso_rtn_rsrc_pkg.regist_resource_no(
             iv_account_number    => it_ref_route_emp_data_tab(i).account_number
            ,iv_resource_no       => it_ref_route_emp_data_tab(i).new_employee_number
            ,id_start_date        => it_ref_route_emp_data_tab(i).new_employee_date
            ,ov_errbuf            => lv_errbuf
            ,ov_retcode           => lv_retcode
            ,ov_errmsg            => lv_errmsg
           );
          IF ( lv_retcode <> cv_status_normal ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name
                           ,iv_name         => cv_msg_err_common_pkg
                           ,iv_token_name1  => cv_tkn_column
                           ,iv_token_value1 => cv_emp_date
                           ,iv_token_name2  => cv_tkn_action
                           ,iv_token_value2 => cv_msg_insert
                           ,iv_token_name3  => cv_tkn_account
                           ,iv_token_value3 => it_ref_route_emp_data_tab(i).account_number
                           ,iv_token_name4  => cv_tkn_err_msg
                           ,iv_token_value4 => lv_errbuf
                           ,iv_token_name5  => cv_tkn_index
                           ,iv_token_value5 => it_ref_route_emp_data_tab(i).line_no
                         );
            -- ���[�gNo�^�S���c�Ƌ��ʊ֐��G���[���b�Z�[�W�o��
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
            lv_warn_flag  := cv_yes;
          END IF;
        ELSIF ( it_ref_route_emp_data_tab(i).employee_change_flag = cv_del ) THEN
          -- 1-6.�S���̍폜
          xxcso_rtn_rsrc_pkg.unregist_resource_no(
             iv_account_number    => it_ref_route_emp_data_tab(i).account_number
            ,iv_resource_no       => NULL
            ,id_start_date        => it_ref_route_emp_data_tab(i).new_employee_date
            ,ov_errbuf            => lv_errbuf
            ,ov_retcode           => lv_retcode
            ,ov_errmsg            => lv_errmsg
          );
          IF ( lv_retcode <> cv_status_normal ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name
                           ,iv_name         => cv_msg_err_common_pkg
                           ,iv_token_name1  => cv_tkn_column
                           ,iv_token_value1 => cv_emp_date
                           ,iv_token_name2  => cv_tkn_action
                           ,iv_token_value2 => cv_msg_delete
                           ,iv_token_name3  => cv_tkn_account
                           ,iv_token_value3 => it_ref_route_emp_data_tab(i).account_number
                           ,iv_token_name4  => cv_tkn_err_msg
                           ,iv_token_value4 => lv_errbuf
                           ,iv_token_name5  => cv_tkn_index
                           ,iv_token_value5 => it_ref_route_emp_data_tab(i).line_no
                         );
            -- ���[�gNo�^�S���c�Ƌ��ʊ֐��G���[���b�Z�[�W�o��
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
            lv_warn_flag  := cv_yes;
          END IF;
        END IF;
--
        IF ( it_ref_route_emp_data_tab(i).route_no_change_flag = cv_ins_upd ) THEN
          -- 1-7.���[�gNo�̓o�^�E�X�V
          xxcso_rtn_rsrc_pkg.regist_route_no(
             iv_account_number    => it_ref_route_emp_data_tab(i).account_number
            ,iv_route_no          => it_ref_route_emp_data_tab(i).new_route_no
            ,id_start_date        => it_ref_route_emp_data_tab(i).new_route_date
            ,ov_errbuf            => lv_errbuf
            ,ov_retcode           => lv_retcode
            ,ov_errmsg            => lv_errmsg
          );
          IF ( lv_retcode <> cv_status_normal ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name
                           ,iv_name         => cv_msg_err_common_pkg
                           ,iv_token_name1  => cv_tkn_column
                           ,iv_token_value1 => cv_route_date
                           ,iv_token_name2  => cv_tkn_action
                           ,iv_token_value2 => cv_msg_insert
                           ,iv_token_name3  => cv_tkn_account
                           ,iv_token_value3 => it_ref_route_emp_data_tab(i).account_number
                           ,iv_token_name4  => cv_tkn_err_msg
                           ,iv_token_value4 => lv_errbuf
                           ,iv_token_name5  => cv_tkn_index
                           ,iv_token_value5 => it_ref_route_emp_data_tab(i).line_no
                         );
            -- ���[�gNo�^�S���c�Ƌ��ʊ֐��G���[���b�Z�[�W�o��
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
            lv_warn_flag  := cv_yes;
          END IF;
        ELSIF ( it_ref_route_emp_data_tab(i).route_no_change_flag = cv_del ) THEN
          -- 1-8.���[�gNo�̍폜
          xxcso_rtn_rsrc_pkg.unregist_route_no(
             iv_account_number    => it_ref_route_emp_data_tab(i).account_number
            ,iv_route_no          => NULL
            ,id_start_date        => it_ref_route_emp_data_tab(i).new_route_date
            ,ov_errbuf            => lv_errbuf
            ,ov_retcode           => lv_retcode
            ,ov_errmsg            => lv_errmsg
          );
          IF ( lv_retcode <> cv_status_normal ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name
                           ,iv_name         => cv_msg_err_common_pkg
                           ,iv_token_name1  => cv_tkn_column
                           ,iv_token_value1 => cv_route_date
                           ,iv_token_name2  => cv_tkn_action
                           ,iv_token_value2 => cv_msg_delete
                           ,iv_token_name3  => cv_tkn_account
                           ,iv_token_value3 => it_ref_route_emp_data_tab(i).account_number
                           ,iv_token_name4  => cv_tkn_err_msg
                           ,iv_token_value4 => lv_errbuf
                           ,iv_token_name5  => cv_tkn_index
                           ,iv_token_value5 => it_ref_route_emp_data_tab(i).line_no
                         );
            -- ���[�gNo�^�S���c�Ƌ��ʊ֐��G���[���b�Z�[�W�o��
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
            lv_warn_flag  := cv_yes;
          END IF;
        END IF;
--
        -- �����J�E���g
        IF ( lv_warn_flag = cv_no ) THEN
          -- ��������
          gn_normal_cnt := gn_normal_cnt + 1;
        ELSE
          -- ���[���o�b�N
          ROLLBACK TO SAVEPOINT line_save;
          -- �x������
          gn_warn_cnt   := gn_warn_cnt + 1;
          ov_retcode    := cv_status_warn;
        END IF;
--
      EXCEPTION
        -- ���b�N�G���[��O
        WHEN local_lock_expt THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_err_lock_data
                         ,iv_token_name1  => cv_tkn_table
                         ,iv_token_value1 => cv_msg_table_hopeb
                         ,iv_token_name2  => cv_tkn_column
                         ,iv_token_value2 => lv_message_code
                         ,iv_token_name3  => cv_tkn_account
                         ,iv_token_value3 => it_ref_route_emp_data_tab(i).account_number
                         ,iv_token_name4  => cv_tkn_index
                         ,iv_token_value4 => it_ref_route_emp_data_tab(i).line_no
                       );
          -- ���b�N�G���[���b�Z�[�W�o��
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          -- �x������
          gn_warn_cnt   := gn_warn_cnt + 1;
          ov_retcode    := cv_status_warn;
      END;
--
    END LOOP reflect_loop;
--
  EXCEPTION
    --*** �����G���[��O ***
    WHEN global_process_expt THEN
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
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
  END reflect_route_emp;
--
  /**********************************************************************************
   * Procedure Name   : delete_file_ul_if
   * Description      : �t�@�C���A�b�v���[�hIF�f�[�^�폜(A-9)
   ***********************************************************************************/
  PROCEDURE delete_file_ul_if(
    in_file_id    IN  NUMBER,    -- �t�@�C��ID
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_file_ul_if'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
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
      DELETE FROM xxccp_mrp_file_ul_interface xmfui
      WHERE xmfui.file_id = in_file_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- �f�[�^�폜�G���[���b�Z�[�W
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_err_del_data
                       ,iv_token_name1  => cv_tkn_table
                       ,iv_token_value1 => cv_tbl_nm_file_ul_if
                       ,iv_token_name2  => cv_tkn_error_message
                       ,iv_token_value2 => SQLERRM
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
    WHEN global_process_expt THEN                           --*** �����G���[��O ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
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
  END delete_file_ul_if;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_file_id    IN  VARCHAR2,  -- 1.�t�@�C��ID
    iv_fmt_ptn    IN  VARCHAR2,  -- 2.�t�H�[�}�b�g�p�^�[��
    ov_errbuf     OUT VARCHAR2,  --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,  --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
--
    -- *** ���[�J���ϐ� ***
    lt_route_emp_data_tab         gt_rec_data_ttype;
    lt_ref_route_emp_data_tab     gt_ref_route_emp_ttype;
    ln_file_id                    NUMBER;
    lv_warn_flag                  VARCHAR2(1);  -- �x���L��t���O
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
    -- ���[�U�[�ϐ��̏�����
    lv_warn_flag  := cv_no;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    --==================================================
    -- A-1.��������
    --==================================================
    init(
       iv_file_id => iv_file_id  -- �t�@�C��ID
      ,iv_fmt_ptn => iv_fmt_ptn  -- �t�H�[�}�b�g�p�^�[��
      ,on_file_id => ln_file_id  -- �t�@�C��ID(�ϊ���)
      ,ov_errbuf  => lv_errbuf   -- �G���[�E���b�Z�[�W
      ,ov_retcode => lv_retcode  -- ���^�[���E�R�[�h
      ,ov_errmsg  => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W 
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    --==================================================
    -- A-2.�t�@�C���A�b�v���[�hIF�f�[�^���o
    --==================================================
    get_upload_data(
       in_file_id             => ln_file_id
      ,ot_route_emp_data_tab  => lt_route_emp_data_tab
      ,ov_errbuf              => lv_errbuf
      ,ov_retcode             => lv_retcode
      ,ov_errmsg              => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      ov_retcode := lv_retcode;
    END IF;
--
    -- ���펞�݈̂ȉ������s
    IF ( lv_retcode = cv_status_normal ) THEN
      --==================================================
      -- A-5.���̓f�[�^�`�F�b�N
      --==================================================
      check_input_data(
         iv_fmt_ptn             => iv_fmt_ptn
        ,it_route_emp_data_tab  => lt_route_emp_data_tab
        ,ov_errbuf              => lv_errbuf
        ,ov_retcode             => lv_retcode
        ,ov_errmsg              => lv_errmsg
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      ELSIF ( lv_retcode = cv_status_warn ) THEN
        lv_warn_flag := cv_yes;
      END IF;
    -- A-2.�Ōx���̏ꍇ���ȉ����������Ȃ�
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_warn_flag := cv_yes;
    END IF;
--
    -- ���펞�݈̂ȉ������s
    IF ( lv_warn_flag = cv_no ) THEN
      --==================================================
      -- A-6.���[�gNo�^�c�ƈ��A�b�v���[�h���ԃe�[�u���o�^
      --==================================================
      ins_route_emp_upload_work(
         in_file_id             => ln_file_id
        ,it_route_emp_data_tab  => lt_route_emp_data_tab
        ,ov_errbuf              => lv_errbuf
        ,ov_retcode             => lv_retcode
        ,ov_errmsg              => lv_errmsg
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      --==================================================
      -- A-7.�Ɩ��G���[�`�F�b�N
      --==================================================
      check_business_data(
         in_file_id                 => ln_file_id
        ,ot_ref_route_emp_data_tab  => lt_ref_route_emp_data_tab
        ,ov_errbuf                  => lv_errbuf
        ,ov_retcode                 => lv_retcode
        ,ov_errmsg                  => lv_errmsg
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      ELSIF ( lv_retcode = cv_status_warn ) THEN
        lv_warn_flag := cv_yes;
      END IF;
--
      --==================================================
      -- A-8.���[�gNo�^�c�ƒS�����f����
      --==================================================
      reflect_route_emp(
         it_ref_route_emp_data_tab => lt_ref_route_emp_data_tab
        ,ov_errbuf                 => lv_errbuf
        ,ov_retcode                => lv_retcode
        ,ov_errmsg                 => lv_errmsg
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      ELSIF ( lv_retcode = cv_status_warn ) THEN
        lv_warn_flag := cv_yes;
      END IF;
    END IF;
--
    --==================================================
    -- A-9.�t�@�C���A�b�v���[�hIF�f�[�^�폜
    --==================================================
    delete_file_ul_if(
       in_file_id => ln_file_id
      ,ov_errbuf  => lv_errbuf
      ,ov_retcode => lv_retcode
      ,ov_errmsg  => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- �x���̐ݒ�
    IF ( lv_warn_flag = cv_yes ) THEN
     ov_retcode := cv_status_warn;
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
    errbuf        OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_file_id    IN  VARCHAR2,      -- 1.�t�@�C��ID
    iv_fmt_ptn    IN  VARCHAR2       -- 2.�t�H�[�}�b�g�p�^�[��
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
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code    VARCHAR2(100);   -- �I�����b�Z�[�W�R�[�h
--
    -- ���[�U�[�E���[�J���萔
    cv_warn_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-00001'; -- �x���������b�Z�[�W
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
       iv_file_id
      ,iv_fmt_ptn
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
      gn_error_cnt  := gn_error_cnt + 1;
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_warn_cnt   := 0;
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
    --�x�������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_warn_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
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
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
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
END XXCSO019A13C;
/
