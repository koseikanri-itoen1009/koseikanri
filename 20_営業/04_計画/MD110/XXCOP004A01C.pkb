CREATE OR REPLACE PACKAGE BODY XXCOP004A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOP004A01C(body)
 * Description      : �A�b�v���[�h�t�@�C������̓o�^(���[�t�ցj
 * MD.050           : �A�b�v���[�h�t�@�C������̓o�^(���[�t�ցj MD050_COP_004_A01
 * Version          : 1.1
 *
 * Program List
 * ----------------------   ----------------------------------------------------------
 *  Name                     Description
 * ----------------------   ----------------------------------------------------------
 *  chk_parameter_p          �p�����[�^�Ó����`�F�b�N(A-2)
 *  get_format_pattern_p     �N�C�b�N�R�[�h�擾(���[�t��CSV�t�@�C���̃t�H�[�}�b�g)(A-3)
 *  get_file_ul_interface_p  �t�@�C���A�b�v���[�hI/F�e�[�u���f�[�^���o(A-4)
 *  chk_validate_data_f      �f�[�^�Ó����`�F�b�N(A-5)
 *  chk_exist_forecast_p     ����v��f�[�^�o�^�`�F�b�N(A-6)
 *  reg_leaf_data_p          ���[�t�փf�[�^�o�^�E�폜(A-7)
 *  judge_result_p           �������e����(A-8)
 *  output_report_p          �A�b�v���[�h���e�̏o��(A-11)
 *  submain                  ���C�������v���V�[�W��
 *  main                     �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/05    1.0  SCS.Tsubomatsu   �V�K�쐬
 *  2009/04/28    1.1  SCS.Kikuchi      T1_0645�Ή�
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
  expt_XXCOP004A01          EXCEPTION;     -- <��O�̃R�����g>
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCOP004A01C';           -- �p�b�P�[�W��
  cv_date_format1           CONSTANT VARCHAR2(8)   := 'YYYYMMDD';               -- ���t�t�H�[�}�b�g
  cv_date_format2           CONSTANT VARCHAR2(21)  := 'YYYY/MM/DD HH24:MI:SS';  -- ���t�t�H�[�}�b�g
  cv_date_format3           CONSTANT VARCHAR2(6)   := 'YYYYMM';                 -- ���t�t�H�[�}�b�g
  cv_sep                    CONSTANT VARCHAR2(1)   := ',';                      -- CSV��؂蕶��(�J���})
  cv_customer_class_code    CONSTANT VARCHAR2(1)   := '1';                      -- �ڋq�}�X�^.�ڋq�敪(1:���_)
  cn_bucket_type            CONSTANT NUMBER        := 1;                        -- ���vAPI�o�P�b�g�^�C�v(1:Days)
  cv_mfds_attribute1        CONSTANT VARCHAR2(2)   := '01';                     -- �t�H�[�L���X�g��.FORECAST����
  cv_first_day              CONSTANT VARCHAR2(2)   := '01';                     -- ������
  cv_prod_class_code        CONSTANT VARCHAR2(1)   := '1';                      -- ���i�敪(1:���[�t)
  -- �p�����[�^
  cv_param_file_id          CONSTANT VARCHAR2(40)  := '�t�@�C��ID';             -- �t�@�C��ID
  cv_param_format_pattern   CONSTANT VARCHAR2(40)  := '�t�H�[�}�b�g�p�^�[��';   -- �t�H�[�}�b�g�p�^�[��
  -- �v���t�@�C��
  cv_master_org_id          CONSTANT VARCHAR2(19)  := 'XXCMN_MASTER_ORG_ID';    -- �}�X�^�g�DID
  cv_master_org_id_name     CONSTANT VARCHAR2(100) := 'XXCMN:�}�X�^�g�D';       -- �}�X�^�g�DID
--20090428_Ver1.1_T1_0645_SCS.Kikuchi_ADD_START
  cv_sales_org_code         CONSTANT VARCHAR2(30)  := 'XXCOP1_SALES_ORG_CODE';  -- �c�Ƒg�D
  cv_sales_org_code_name    CONSTANT VARCHAR2(100) := 'XXCOP:�c�Ƒg�D';         -- �c�Ƒg�DID
  cv_item_org_code          CONSTANT VARCHAR2(100) := '�g�D�R�[�h';
--20090428_Ver1.1_T1_0645_SCS.Kikuchi_ADD_END
  -- �N�C�b�N�R�[�h
  cv_lookup_type            CONSTANT VARCHAR2(21)  := 'XXCOP1_FORMAT_PATTERN';  -- �N�C�b�N�R�[�h�^�C�v
  cv_flv_enabled_flag       CONSTANT VARCHAR2(1)   := 'Y';                      -- �g�p�\
  -- ��������
  cv_result_insert          CONSTANT VARCHAR2(100) := '(�o�^)';
  cv_result_update          CONSTANT VARCHAR2(100) := '(�X�V)';
  cv_result_delete          CONSTANT VARCHAR2(100) := '(�폜)';
  -- �������ʃ��|�[�g���o��
  cv_title_upload_ok        CONSTANT VARCHAR2(40)  := '�捞�����f�[�^';
  cv_title_upload_ng        CONSTANT VARCHAR2(40)  := '�捞���s�f�[�^';
  -- ���b�Z�[�W�E�A�v���P�[�V�������i�A�h�I���F�̕��E�v��̈�j
  cv_msg_application        CONSTANT VARCHAR2(100) := 'XXCOP';
  -- ���b�Z�[�W��
  cv_message_00002          CONSTANT VARCHAR2(16)  := 'APP-XXCOP1-00002';
  cv_message_00005          CONSTANT VARCHAR2(16)  := 'APP-XXCOP1-00005';
  cv_message_00006          CONSTANT VARCHAR2(16)  := 'APP-XXCOP1-00006';
  cv_message_00007          CONSTANT VARCHAR2(16)  := 'APP-XXCOP1-00007';
  cv_message_00008          CONSTANT VARCHAR2(16)  := 'APP-XXCOP1-00008';
  cv_message_00009          CONSTANT VARCHAR2(16)  := 'APP-XXCOP1-00009';
  cv_message_00010          CONSTANT VARCHAR2(16)  := 'APP-XXCOP1-00010';
  cv_message_00011          CONSTANT VARCHAR2(16)  := 'APP-XXCOP1-00011';
  cv_message_00012          CONSTANT VARCHAR2(16)  := 'APP-XXCOP1-00012';
  cv_message_00013          CONSTANT VARCHAR2(16)  := 'APP-XXCOP1-00013';
  cv_message_00031          CONSTANT VARCHAR2(16)  := 'APP-XXCOP1-00031';
  cv_message_00036          CONSTANT VARCHAR2(16)  := 'APP-XXCOP1-00036';
  cv_message_00046          CONSTANT VARCHAR2(16)  := 'APP-XXCOP1-00046';
  cv_message_10002          CONSTANT VARCHAR2(16)  := 'APP-XXCOP1-10002';
  cv_message_10003          CONSTANT VARCHAR2(16)  := 'APP-XXCOP1-10003';
  cv_message_10004          CONSTANT VARCHAR2(16)  := 'APP-XXCOP1-10004';
  cv_message_10036          CONSTANT VARCHAR2(16)  := 'APP-XXCOP1-10036';
  -- ���b�Z�[�W�g�[�N��
  cv_message_00002_token_1  CONSTANT VARCHAR2(9)   := 'PROF_NAME';
  cv_message_00005_token_1  CONSTANT VARCHAR2(9)   := 'PARAMETER';
  cv_message_00005_token_2  CONSTANT VARCHAR2(5)   := 'VALUE';
  cv_message_00006_token_1  CONSTANT VARCHAR2(5)   := 'VALUE';
  cv_message_00007_token_1  CONSTANT VARCHAR2(5)   := 'TABLE';
  cv_message_00009_token_1  CONSTANT VARCHAR2(4)   := 'ITEM';
  cv_message_00010_token_1  CONSTANT VARCHAR2(4)   := 'ITEM';
  cv_message_00011_token_1  CONSTANT VARCHAR2(4)   := 'ITEM';
  cv_message_00012_token_1  CONSTANT VARCHAR2(4)   := 'ITEM';
  cv_message_00013_token_1  CONSTANT VARCHAR2(4)   := 'ITEM';
  cv_message_00013_token_2  CONSTANT VARCHAR2(5)   := 'VALUE';
  cv_message_00013_token_3  CONSTANT VARCHAR2(5)   := 'TABLE';
  cv_message_00036_token_1  CONSTANT VARCHAR2(7)   := 'FILE_ID';
  cv_message_00036_token_2  CONSTANT VARCHAR2(10)  := 'FORMAT_PTN';
  cv_message_00036_token_3  CONSTANT VARCHAR2(13)  := 'UPLOAD_OBJECT';
  cv_message_00036_token_4  CONSTANT VARCHAR2(9)   := 'FILE_NAME';
  cv_message_00046_token_1  CONSTANT VARCHAR2(4)   := 'ITEM';
  cv_message_10002_token_1  CONSTANT VARCHAR2(5)   := 'TABLE';
  cv_message_10002_token_2  CONSTANT VARCHAR2(5)   := 'STORE';
  cv_message_10002_token_3  CONSTANT VARCHAR2(8)   := 'LOCATION';
  cv_message_10002_token_4  CONSTANT VARCHAR2(6)   := 'YYYYMM';
  cv_message_10003_token_1  CONSTANT VARCHAR2(5)   := 'TABLE';
  cv_message_10003_token_2  CONSTANT VARCHAR2(5)   := 'STORE';
  cv_message_10003_token_3  CONSTANT VARCHAR2(8)   := 'LOCATION';
  cv_message_10003_token_4  CONSTANT VARCHAR2(6)   := 'YYYYMM';
  cv_message_10003_token_5  CONSTANT VARCHAR2(4)   := 'DATE';
  cv_message_10004_token_1  CONSTANT VARCHAR2(4)   := 'DATE';
  cv_message_10031_token_1  CONSTANT VARCHAR2(5)   := 'TABLE';
  cv_message_10031_token_2  CONSTANT VARCHAR2(7)   := 'FILE_ID';
  -- �e�[�u����
  cv_table_xldos            CONSTANT VARCHAR2(100) := '���[�t�փf�[�^�A�h�I���e�[�u��';
  cv_table_hca              CONSTANT VARCHAR2(100) := '�ڋq�}�X�^';
  cv_table_mil              CONSTANT VARCHAR2(100) := 'OPM�ۊǏꏊ�}�X�^';
--20090428_Ver1.1_T1_0645_SCS.Kikuchi_ADD_START
  cv_table_mp               CONSTANT VARCHAR2(100) := '�g�D�p�����[�^';
--20090428_Ver1.1_T1_0645_SCS.Kikuchi_ADD_END

  -- ����
  cn_len_code               CONSTANT NUMBER        := 4;    -- ���_�A�o�בq��
  cn_len_target_month       CONSTANT NUMBER        := 6;    -- �Ώ۔N��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_param_file_id          VARCHAR2(30);   --   �p�����[�^.FILE_ID
  gv_param_format_pattern   VARCHAR2(30);   --   �p�����[�^.�t�H�[�}�b�g�E�p�^�[��
  gn_param_file_id          NUMBER;         --   �p�����[�^.FILE_ID
  gn_param_format_pattern   NUMBER;         --   �p�����[�^.�t�H�[�}�b�g�E�p�^�[��
  gn_org_id                 NUMBER;         --   �g�DID
  gv_upload_name            fnd_lookup_values.meaning%TYPE;                         -- �t�@�C���A�b�v���[�h����
  gv_file_name              xxccp_mrp_file_ul_interface.file_name%TYPE;             -- �t�@�C����
  gd_upload_date            xxccp_mrp_file_ul_interface.creation_date%TYPE;         -- �A�b�v���[�h����

--20090428_Ver1.1_T1_0645_SCS.Kikuchi_ADD_START
  gv_sales_org_code         mtl_parameters.organization_code%type;
  gn_sales_org_id           mtl_parameters.organization_id%type;
--20090428_Ver1.1_T1_0645_SCS.Kikuchi_ADD_END
--
  -- ===============================
  -- ���[�U�[��`�O���[�o��TABLE�^
  -- ===============================
  TYPE g_day_of_service_ttype IS TABLE OF VARCHAR2(2)     INDEX BY BINARY_INTEGER;    -- �h�����N�֓��t(�ő�20��)
--  TYPE g_warning_msg_ttype    IS TABLE OF VARCHAR2(4096)  INDEX BY BINARY_INTEGER;    -- �x�����b�Z�[�W
  TYPE g_error_msg_ttype      IS TABLE OF VARCHAR2(4096)  INDEX BY BINARY_INTEGER;    -- �G���[���b�Z�[�W(�����s�̏ꍇ����)
  TYPE g_result_ttype         IS TABLE OF VARCHAR2(10)    INDEX BY BINARY_INTEGER;    -- ��������( (�o�^),(�X�V),(�폜) �̉��ꂩ)
--
  -- ===============================
  -- ���[�U�[��`�O���[�o��RECORD�^
  -- ===============================
  TYPE g_ifdata_rtype IS RECORD (
    whse_code             VARCHAR2(4)             -- �o�בq��
   ,base_code             VARCHAR2(4)             -- ���_
   ,target_month          VARCHAR2(6)             -- �Ώ۔N��
   ,day_of_service_tab    g_day_of_service_ttype  -- �h�����N�֓��t
  );
--
  /**********************************************************************************
   * Procedure Name   : chk_parameter_p
   * Description      : A-2.�p�����[�^�Ó����`�F�b�N
   ***********************************************************************************/
  PROCEDURE chk_parameter_p(
    ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2)    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_parameter_p'; -- �v���O������
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
    lv_tkn_parameter  VARCHAR2(100);  -- ���b�Z�[�W�ɓn��TOKEN(��PARAMETER)
    lv_tkn_item       VARCHAR2(100);  -- ���b�Z�[�W�ɓn��TOKEN(��ITEM)
    ln_dummy          NUMBER;         -- NUMBER�^�ϊ��p�_�~�[
--
    -- *** ���[�J���E���[�U��`��O ***
    chk_parameter_expt EXCEPTION;
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
    --�p�����[�^.FILE_ID��NUMBER�^�`�F�b�N
    --==============================================================
    BEGIN
      lv_tkn_parameter  := cv_param_file_id;
      lv_tkn_item       := gv_param_file_id;
      -- NULL�̏ꍇ�͗�O�������s��
      IF ( gv_param_file_id IS NULL ) THEN
        RAISE chk_parameter_expt;
      END IF;
      -- NUMBER�^�ɕϊ����Ċi�[
      gn_param_file_id := TO_NUMBER( gv_param_file_id );
    EXCEPTION
      WHEN OTHERS THEN
        -- NUMBER�^�ϊ��G���[�̏ꍇ�͗�O�������s��
        RAISE chk_parameter_expt;
    END;
--
    --==============================================================
    --�p�����[�^.�t�H�[�}�b�g�p�^�[����NUMBER�^�`�F�b�N
    --==============================================================
    BEGIN
      lv_tkn_parameter  := cv_param_format_pattern;
      lv_tkn_item       := gv_param_format_pattern;
      -- NULL�̏ꍇ�͗�O�������s��
      IF ( gv_param_format_pattern IS NULL ) THEN
        RAISE chk_parameter_expt;
      END IF;
      -- NUMBER�^�ɕϊ����Ċi�[
      gn_param_format_pattern := TO_NUMBER( gv_param_format_pattern );
    EXCEPTION
      WHEN OTHERS THEN
        -- NUMBER�^�ϊ��G���[�̏ꍇ�͗�O�������s��
        RAISE chk_parameter_expt;
    END;
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- *** �p�����[�^�`�F�b�N�G���[ ***
    WHEN chk_parameter_expt THEN
      ov_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_application
                      ,iv_name         => cv_message_00005
                      ,iv_token_name1  => cv_message_00005_token_1
                      ,iv_token_value1 => lv_tkn_parameter
                      ,iv_token_name2  => cv_message_00005_token_2
                      ,iv_token_value2 => lv_tkn_item
                     );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
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
  END chk_parameter_p;
--
  /**********************************************************************************
   * Procedure Name   : get_format_pattern_p
   * Description      : A-3.�N�C�b�N�R�[�h�擾(���[�t��CSV�t�@�C���̃t�H�[�}�b�g)
   ***********************************************************************************/
  PROCEDURE get_format_pattern_p(
    iv_file_format OUT VARCHAR2    --   �t�H�[�}�b�g�E�p�^�[��
   ,ov_errbuf      OUT VARCHAR2    --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode     OUT VARCHAR2    --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg      OUT VARCHAR2)   --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_format_pattern_p'; -- �v���O������
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
    lv_description  fnd_lookup_values.description%TYPE;
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
    --�N�C�b�N�R�[�h�̎擾
    --==============================================================
    SELECT flv.description description
    INTO   iv_file_format
    FROM   fnd_lookup_values flv
    WHERE  flv.lookup_type  = cv_lookup_type
    AND    flv.lookup_code  = gv_param_format_pattern
    AND    flv.language     = USERENV( 'LANG' )
    AND    flv.enabled_flag = cv_flv_enabled_flag
    AND    NVL( flv.start_date_active, SYSDATE ) <= TRUNC( SYSDATE )
    AND    NVL( flv.end_date_active, SYSDATE ) >= TRUNC( SYSDATE )
    ;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN  --*** �Y���f�[�^�Ȃ� ***
      ov_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_application
                      ,iv_name         => cv_message_00006
                      ,iv_token_name1  => cv_message_00006_token_1
                      ,iv_token_value1 => cv_lookup_type
                     );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
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
  END get_format_pattern_p;
--
  /**********************************************************************************
   * Procedure Name   : get_file_ul_interface_p
   * Description      : A-4.�t�@�C���A�b�v���[�hI/F�e�[�u���f�[�^���o
   ***********************************************************************************/
  PROCEDURE get_file_ul_interface_p(
    o_ifdata_tab   OUT xxccp_common_pkg2.g_file_data_tbl   --   PL/SQL�\�FI/F�e�[�u���f�[�^
   ,ov_errbuf      OUT VARCHAR2                            --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode     OUT VARCHAR2                            --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg      OUT VARCHAR2)                           --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_file_ul_interface_p'; -- �v���O������
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
    --�t�@�C���A�b�v���[�hI/F�e�[�u���̏��擾
    --==============================================================
    xxcop_common_pkg.get_upload_table_info(
       in_file_id      => gn_param_file_id          -- �t�@�C��ID
      ,iv_format       => gn_param_format_pattern   -- �t�H�[�}�b�g�p�^�[��
      ,ov_upload_name  => gv_upload_name            -- �t�@�C���A�b�v���[�h����
      ,ov_file_name    => gv_file_name              -- �t�@�C����
      ,od_upload_date  => gd_upload_date            -- �A�b�v���[�h����
      ,ov_retcode      => lv_retcode                -- ���^�[���R�[�h
      ,ov_errbuf       => lv_errbuf                 -- �G���[�E���b�Z�[�W
      ,ov_errmsg       => lv_errmsg                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
--
    --==============================================================
    --���ʊ֐����g�p���A�t�@�C���A�b�v���[�hI/F�e�[�u���̃f�[�^���s�P�ʂŎ擾����
    --==============================================================
    xxccp_common_pkg2.blob_to_varchar2(
      gn_param_file_id            -- �t�@�C���h�c
     ,o_ifdata_tab                -- �ϊ���VARCHAR2�f�[�^
     ,lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
     ,lv_errmsg);                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --�擾�����f�[�^��1�s�ڂ̓^�C�g���s�̂��ߔj������
    --==============================================================
    IF ( o_ifdata_tab.COUNT > 0 ) THEN
      o_ifdata_tab.DELETE( o_ifdata_tab.FIRST );
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
  END get_file_ul_interface_p;
--
  /**********************************************************************************
   * Procedure Name   : chk_validate_data_f
   * Description      : A-5.�f�[�^�Ó����`�F�b�N
   ***********************************************************************************/
  PROCEDURE chk_validate_data_f(
    iv_file_format      IN  VARCHAR2                              --   �t�@�C���t�H�[�}�b�g
   ,i_ifdata_tab        IN  xxccp_common_pkg2.g_file_data_tbl     --   PL/SQL�\�FI/F�e�[�u���f�[�^
   ,in_ifdata_tab_idx   IN  NUMBER                                --   PL/SQL�\�FI/F�e�[�u���f�[�^�̃C���f�b�N�X�ԍ�
   ,o_csv_div_data_tab  OUT xxcop_common_pkg.g_char_ttype         --   PL/SQL�\�FCSV�v�f
   ,o_ifdata_rec        OUT g_ifdata_rtype                        --   ���R�[�h�F�t�@�C���A�b�v���[�hI/F�e�[�u���v�f
   ,io_error_msg_tab    IN  OUT    g_error_msg_ttype              --   PL/SQL�\�F�G���[���b�Z�[�W
   ,ov_errbuf           OUT VARCHAR2                              --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode          OUT VARCHAR2                              --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg           OUT VARCHAR2)                             --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_validate_data_f'; -- �v���O������
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
    ln_dummy            NUMBER;               -- �����ANUMBER�^�m�F�p
    ld_dummy            DATE;                 -- DATE�^�m�F�p
    ln_index            NUMBER := 0;          -- CSV�C���f�b�N�X
    lv_tkn_item         VARCHAR2(100);        -- ���b�Z�[�W�ɓn��TOKEN(��ITEM)
    lv_tkn_value        VARCHAR2(100);        -- ���b�Z�[�W�ɓn��TOKEN(��VALUE)
    lb_blank_day        BOOLEAN := FALSE;     -- 1-20�֓��t��Null���o�t���O
    lv_date             VARCHAR2(8);          -- DATE�^�`�F�b�N�p
    ld_work_day         DATE;                 -- �ғ����`�F�b�N�p
--
    -- *** ���[�J��TABLE�^ ***
    TYPE l_csv_item_name_ttype    IS TABLE OF VARCHAR2(20) INDEX BY BINARY_INTEGER;   -- CSV�v�f���Ƃ̖���
--
    -- *** ���[�J��PL/SQL�\ ***
    l_csv_item_name_tab   l_csv_item_name_ttype;          -- CSV�v�f���Ƃ̖���
    l_file_format_tab     xxcop_common_pkg.g_char_ttype;  -- �t�@�C���t�H�[�}�b�g
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
    --CSV�v�f���Ƃ̖��̐ݒ�
    --==============================================================
    l_csv_item_name_tab( 1 ) := '�o�בq��';
    l_csv_item_name_tab( 2 ) := '���_';
    l_csv_item_name_tab( 3 ) := '�Ώ۔N��';
--
    <<csv_item_name_loop>>
    FOR i IN 1..20 LOOP
      l_csv_item_name_tab( i + 3 ) := i || '�֓��t';
    END LOOP csv_item_name_loop;
--
    --==============================================================
    --�f�[�^�̃J���}��؂�
    --==============================================================
    xxcop_common_pkg.char_delim_partition(
      iv_char       => i_ifdata_tab( in_ifdata_tab_idx )   -- �Ώە�����
     ,iv_delim      => cv_sep                              -- �f���~�^
     ,o_char_tab    => o_csv_div_data_tab                  -- ��������
     ,ov_retcode    => lv_retcode                          -- ���^�[���R�[�h
     ,ov_errbuf     => lv_errbuf                           -- �G���[�E���b�Z�[�W
     ,ov_errmsg     => lv_errmsg                           -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    -- �e�v�f�̃g�������s��
    <<trim_loop>>
    FOR i IN o_csv_div_data_tab.FIRST..o_csv_div_data_tab.LAST LOOP
      o_csv_div_data_tab( i ) := LTRIM( RTRIM( o_csv_div_data_tab( i ) ) );
    END LOOP trim_loop;
--
    --==============================================================
    --�t�@�C���t�H�[�}�b�g�������`�F�b�N
    --==============================================================
    -- �t�@�C���t�H�[�}�b�g�̃J���}��؂���s��
    xxcop_common_pkg.char_delim_partition(
      iv_char       => iv_file_format                      -- �Ώە�����
     ,iv_delim      => cv_sep                              -- �f���~�^
     ,o_char_tab    => l_file_format_tab                   -- ��������
     ,ov_retcode    => lv_retcode                          -- ���^�[���R�[�h
     ,ov_errbuf     => lv_errbuf                           -- �G���[�E���b�Z�[�W
     ,ov_errmsg     => lv_errmsg                           -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    -- �t�@�C���t�H�[�}�b�g�̗v�f���ƁuPL/SQL�\�FCSV�v�f�v�̗v�f�����قȂ�ꍇ�̓G���[�Ƃ���
    IF ( l_file_format_tab.COUNT <> o_csv_div_data_tab.COUNT ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_application
                      ,iv_name         => cv_message_00008
                     );
      IF ( ov_retcode = cv_status_normal ) THEN
        io_error_msg_tab( in_ifdata_tab_idx ) := lv_errmsg;
      ELSE
        io_error_msg_tab( in_ifdata_tab_idx ) := io_error_msg_tab( in_ifdata_tab_idx ) || CHR(13) || CHR(10) || lv_errmsg;
      END IF;
      ov_retcode := cv_status_warn;
      -- �㑱�̃`�F�b�N�͍s��Ȃ�
      RETURN;
    END IF;
--
    --==============================================================
    --�K�{���ڃ`�F�b�N
    --==============================================================
    <<check_not_null_loop>>
    -- PL/SQL�\�FCSV�v�f�̏o�ɑq�ɁA���_�A�Ώ۔N��(1-3�Ԗ�)�ɂ��ĕK�{�`�F�b�N���s��
    FOR i IN 1..3 LOOP
      -- �v�f���󔒂̏ꍇ�̓G���[�Ƃ���
      IF ( o_csv_div_data_tab( i ) IS NULL ) THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_application
                        ,iv_name         => cv_message_00009
                        ,iv_token_name1  => cv_message_00009_token_1
                        ,iv_token_value1 => l_csv_item_name_tab( i )
                       );
        IF ( ov_retcode = cv_status_normal ) THEN
          io_error_msg_tab( in_ifdata_tab_idx ) := lv_errmsg;
        ELSE
          io_error_msg_tab( in_ifdata_tab_idx ) := io_error_msg_tab( in_ifdata_tab_idx ) || CHR(13) || CHR(10) || lv_errmsg;
        END IF;
        ov_retcode := cv_status_warn;
      END IF;
    END LOOP check_not_null_loop;
--
    --==============================================================
    --1-20�֓��̓`�F�b�N
    --==============================================================
    <<check_input_day_loop>>
    -- PL/SQL�\�FCSV�v�f�̏o�ɑq�ɁA���_�A�Ώ۔N��(1-3�Ԗ�)�ɂ��ĕK�{�`�F�b�N���s��
    FOR i IN 4..23 LOOP
      -- �v�f��Null�̏ꍇ��Null���o�t���O���Z�b�g
      IF ( o_csv_div_data_tab( i ) IS NULL ) THEN
        lb_blank_day := TRUE;
--
      -- �v�f��Null�łȂ��ꍇ
      ELSE
        IF lb_blank_day THEN
          -- ����Null���������Ă���ꍇ�̓G���[�i���Ԃ̏ȗ��͕s�j
          lv_errmsg  := xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_application
                          ,iv_name         => cv_message_10036
                         );
          IF ( ov_retcode = cv_status_normal ) THEN
            io_error_msg_tab( in_ifdata_tab_idx ) := lv_errmsg;
          ELSE
            io_error_msg_tab( in_ifdata_tab_idx ) := io_error_msg_tab( in_ifdata_tab_idx ) || CHR(13) || CHR(10) || lv_errmsg;
          END IF;
          ov_retcode := cv_status_warn;
          -- ���[�v�𔲂���
          EXIT check_input_day_loop;
        END IF;
      END IF;
    END LOOP check_input_day_loop;
--
    --==============================================================
    --�ڋq�}�X�^���݃`�F�b�N
    --==============================================================
    -- ���_���󔒂łȂ��ꍇ�̂݃`�F�b�N�ΏۂƂ���
    IF ( o_csv_div_data_tab( 2 ) IS NOT NULL ) THEN
      SELECT COUNT( 'X' )
      INTO   ln_dummy
      FROM   hz_cust_accounts hca   -- �ڋq�}�X�^
      WHERE  hca.customer_class_code = cv_customer_class_code
      AND    hca.account_number      = o_csv_div_data_tab( 2 )
      ;
      -- ���_���ڋq�}�X�^�ɑ��݂��Ȃ��ꍇ�̓G���[�Ƃ���
      IF ( ln_dummy = 0 ) THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_application
                        ,iv_name         => cv_message_00013
                        ,iv_token_name1  => cv_message_00013_token_1
                        ,iv_token_value1 => l_csv_item_name_tab( 2 )
                        ,iv_token_name2  => cv_message_00013_token_2
                        ,iv_token_value2 => o_csv_div_data_tab( 2 )
                        ,iv_token_name3  => cv_message_00013_token_3
                        ,iv_token_value3 => cv_table_hca
                       );
        IF ( ov_retcode = cv_status_normal ) THEN
          io_error_msg_tab( in_ifdata_tab_idx ) := lv_errmsg;
        ELSE
          io_error_msg_tab( in_ifdata_tab_idx ) := io_error_msg_tab( in_ifdata_tab_idx ) || CHR(13) || CHR(10) || lv_errmsg;
        END IF;
        ov_retcode := cv_status_warn;
      END IF;
    END IF;
--
    --==============================================================
    --OPM�ۊǏꏊ�}�X�^���݃`�F�b�N
    --==============================================================
    -- �o�בq�ɂ��󔒂łȂ��ꍇ�̂݃`�F�b�N�ΏۂƂ���
    IF ( o_csv_div_data_tab( 1 ) IS NOT NULL ) THEN
      SELECT COUNT( 'X' )
      INTO   ln_dummy
      FROM   ic_whse_mst               iwm      -- OPM�q�Ƀ}�X�^
            ,hr_all_organization_units haou     -- �݌ɑg�D�}�X�^
            ,mtl_item_locations        mil      -- OPM�ۊǏꏊ�}�X�^
      WHERE  iwm.mtl_organization_id =   haou.organization_id
      AND    haou.organization_id    =   mil.organization_id
      AND    haou.date_from          <=  TRUNC(SYSDATE)
      AND   ( ( haou.date_to IS NULL ) OR ( haou.date_to >= TRUNC( SYSDATE ) ) )
      AND    mil.disable_date        IS NULL
      AND    mil.segment1            =   o_csv_div_data_tab( 1 )
      ;
      -- �o�בq�ɂ�OPM�ۊǏꏊ�}�X�^�ɑ��݂��Ȃ��ꍇ�̓G���[�Ƃ���
      IF ( ln_dummy = 0 ) THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_application
                        ,iv_name         => cv_message_00013
                        ,iv_token_name1  => cv_message_00013_token_1
                        ,iv_token_value1 => l_csv_item_name_tab( 1 )
                        ,iv_token_name2  => cv_message_00013_token_2
                        ,iv_token_value2 => o_csv_div_data_tab( 1 )
                        ,iv_token_name3  => cv_message_00013_token_3
                        ,iv_token_value3 => cv_table_mil
                       );
        IF ( ov_retcode = cv_status_normal ) THEN
          io_error_msg_tab( in_ifdata_tab_idx ) := lv_errmsg;
        ELSE
          io_error_msg_tab( in_ifdata_tab_idx ) := io_error_msg_tab( in_ifdata_tab_idx ) || CHR(13) || CHR(10) || lv_errmsg;
        END IF;
        ov_retcode := cv_status_warn;
      END IF;
    END IF;
--
    --==============================================================
    --NUMBER�^�`�F�b�N
    --==============================================================
    <<check_numeric_loop>>
    -- PL/SQL�\�FCSV�v�f�̑Ώ۔N���A1-20�֓��t(3-23�Ԗ�)�ɂ��ĕK�{�`�F�b�N���s��
    FOR i IN 3..23 LOOP
      -- �v�f���󔒂łȂ��ꍇ�̂݃`�F�b�N�ΏۂƂ���
      IF ( o_csv_div_data_tab( i ) IS NOT NULL ) THEN
        -- NUMBER�^�ɕϊ��ł��Ȃ��ꍇ�̓G���[�Ƃ���
        IF ( xxcop_common_pkg.chk_number_format( o_csv_div_data_tab( i ) ) = FALSE ) THEN
          lv_errmsg  := xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_application
                          ,iv_name         => cv_message_00010
                          ,iv_token_name1  => cv_message_00010_token_1
                          ,iv_token_value1 => l_csv_item_name_tab( i )
                         );
          IF ( ov_retcode = cv_status_normal ) THEN
            io_error_msg_tab( in_ifdata_tab_idx ) := lv_errmsg;
          ELSE
            io_error_msg_tab( in_ifdata_tab_idx ) := io_error_msg_tab( in_ifdata_tab_idx ) || CHR(13) || CHR(10) || lv_errmsg;
          END IF;
          ov_retcode := cv_status_warn;
        END IF;
      END IF;
    END LOOP check_numeric_loop;
--
    --==============================================================
    --DATE�^�`�F�b�N�E�ғ����`�F�b�N
    --==============================================================
    -- PL/SQL�\�FCSV�v�f�̑Ώ۔N���ɂ��Ēl�`�F�b�N���s���i�Ώ۔N�����󔒂łȂ��ANUMBER�^�̏ꍇ�̂݁j
    IF  ( o_csv_div_data_tab( 3 ) IS NOT NULL )
    AND ( xxcop_common_pkg.chk_number_format( o_csv_div_data_tab( 3 ) ) )
    THEN
      -- 6���ȊO�̏ꍇ�ADATE�^�ɕϊ��ł��Ȃ��ꍇ�̓G���[�Ƃ���
      IF ( LENGTHB( o_csv_div_data_tab( 3 ) ) <> cn_len_target_month )
      OR ( xxcop_common_pkg.chk_date_format( o_csv_div_data_tab( 3 ), cv_date_format3 ) = FALSE )
      THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_application
                        ,iv_name         => cv_message_00011
                        ,iv_token_name1  => cv_message_00011_token_1
                        ,iv_token_value1 => l_csv_item_name_tab( 3 )
                       );
        IF ( ov_retcode = cv_status_normal ) THEN
          io_error_msg_tab( in_ifdata_tab_idx ) := lv_errmsg;
        ELSE
          io_error_msg_tab( in_ifdata_tab_idx ) := io_error_msg_tab( in_ifdata_tab_idx ) || CHR(13) || CHR(10) || lv_errmsg;
        END IF;
        ov_retcode := cv_status_warn;
      END IF;
    END IF;
--
    -- �Ώ۔N�����󔒂łȂ�NUMBER�^����DATE�^�̏ꍇ�̂�
    IF  ( o_csv_div_data_tab( 3 ) IS NOT NULL )
    AND ( xxcop_common_pkg.chk_number_format( o_csv_div_data_tab( 3 ) ) )
    AND ( xxcop_common_pkg.chk_date_format( o_csv_div_data_tab( 3 ), cv_date_format3 ) )
    THEN
--
      <<check_isdate_loop>>
      -- PL/SQL�\�FCSV�v�f�̑Ώ۔N����1-20�֓��t(4-23�Ԗ�)�ɂ��Ēl�`�F�b�N���s��
      FOR i IN 4..23 LOOP
        -- �v�f���󔒂łȂ�NUMBER�^�̏ꍇ�̂݃`�F�b�N�ΏۂƂ���
        IF  ( o_csv_div_data_tab( i ) IS NOT NULL )
        AND ( xxcop_common_pkg.chk_number_format( o_csv_div_data_tab( i ) ) )
        THEN
          -- �Ώ۔N���{���֓��t�𕶎���Ƃ��ĕۑ�
          lv_date := o_csv_div_data_tab( 3 ) || LPAD( o_csv_div_data_tab( i ), 2, '0' );
          -- DATE�^�ɕϊ��ł��Ȃ��ꍇ�̓G���[�Ƃ���
          IF ( xxcop_common_pkg.chk_date_format( lv_date, cv_date_format1 ) = FALSE ) THEN
            lv_errmsg  := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_application
                            ,iv_name         => cv_message_00011
                            ,iv_token_name1  => cv_message_00011_token_1
                            ,iv_token_value1 => l_csv_item_name_tab( i )
                           );
            IF ( ov_retcode = cv_status_normal ) THEN
              io_error_msg_tab( in_ifdata_tab_idx ) := lv_errmsg;
            ELSE
              io_error_msg_tab( in_ifdata_tab_idx ) := io_error_msg_tab( in_ifdata_tab_idx ) || CHR(13) || CHR(10) || lv_errmsg;
            END IF;
            ov_retcode := cv_status_warn;
--
          -- DATE�^�ɕϊ��ł����ꍇ
          ELSE
            -- �Ώ۔N���{���֓��t�𕶎���Ƃ��ĕۑ�
            ld_work_day := TO_DATE( o_csv_div_data_tab( 3 ) || LPAD( o_csv_div_data_tab( i ), 2, '0' ), cv_date_format1 );
            -- �ғ����łȂ��ꍇ�̓G���[�Ƃ���
            IF ( ld_work_day <> mrp_calendar.next_work_day(
--20090428_Ver1.1_T1_0645_SCS.Kikuchi_MOD_START
--                                  arg_org_id  => gn_org_id
                                  arg_org_id  => gn_sales_org_id
--20090428_Ver1.1_T1_0645_SCS.Kikuchi_MOD_END
                                 ,arg_bucket  => cn_bucket_type
                                 ,arg_date    => ld_work_day ) )
            THEN
              lv_errmsg  := xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_application
                              ,iv_name         => cv_message_00046
                              ,iv_token_name1  => cv_message_00046_token_1
                              ,iv_token_value1 => l_csv_item_name_tab( i )
                             );
              IF ( ov_retcode = cv_status_normal ) THEN
                io_error_msg_tab( in_ifdata_tab_idx ) := lv_errmsg;
              ELSE
                io_error_msg_tab( in_ifdata_tab_idx ) := io_error_msg_tab( in_ifdata_tab_idx ) || CHR(13) || CHR(10) || lv_errmsg;
              END IF;
              ov_retcode := cv_status_warn;
            END IF;
          END IF;
--
        END IF;
      END LOOP check_isdate_loop;
--
    END IF;
--
    --==============================================================
    --�T�C�Y�`�F�b�N
    --==============================================================
    <<check_size_loop>>
    -- PL/SQL�\�FCSV�v�f�̏o�בq�ɁA���_(1-2�Ԗ�)�ɂ��ĕK�{�`�F�b�N���s��
    FOR i IN 1..2 LOOP
      -- �v�f��4�o�C�g�łȂ��ꍇ�̓G���[�Ƃ���
      IF ( LENGTHB( o_csv_div_data_tab( i ) ) <> cn_len_code ) THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_application
                        ,iv_name         => cv_message_00012
                        ,iv_token_name1  => cv_message_00012_token_1
                        ,iv_token_value1 => l_csv_item_name_tab( i )
                       );
        IF ( ov_retcode = cv_status_normal ) THEN
          io_error_msg_tab( in_ifdata_tab_idx ) := lv_errmsg;
        ELSE
          io_error_msg_tab( in_ifdata_tab_idx ) := io_error_msg_tab( in_ifdata_tab_idx ) || CHR(13) || CHR(10) || lv_errmsg;
        END IF;
        ov_retcode := cv_status_warn;
      END IF;
    END LOOP check_size_loop;
--
    -- �`�F�b�N�G���[�����������ꍇ�̓��R�[�h�ւ̊i�[���s�킸�I������
    IF ( ov_retcode <> cv_status_normal ) THEN
      RETURN;
    END IF;
--
    --==============================================================
    --���R�[�h�ւ̊i�[
    --==============================================================
    o_ifdata_rec.whse_code             := o_csv_div_data_tab( 1 );  -- �o�בq��
    o_ifdata_rec.base_code             := o_csv_div_data_tab( 2 );  -- ���_
    o_ifdata_rec.target_month          := o_csv_div_data_tab( 3 );  -- �Ώ۔N��
--
    <<day_of_service_loop>>
    FOR i IN 4..23 LOOP
      o_ifdata_rec.day_of_service_tab( i - 3 ) := LPAD( o_csv_div_data_tab( i ), 2, '0' );  -- 1-20�֓��t
    END LOOP day_of_service_loop;
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
  END chk_validate_data_f;
--
  /**********************************************************************************
   * Procedure Name   : chk_exist_forecast_p
   * Description      : A-6.����v��f�[�^�o�^�`�F�b�N
   ***********************************************************************************/
  PROCEDURE chk_exist_forecast_p(
    i_ifdata_rec        IN  g_ifdata_rtype                        --   ���R�[�h�F�t�@�C���A�b�v���[�hI/F�e�[�u���v�f
   ,in_ifdata_tab_idx   IN  NUMBER                                --   PL/SQL�\�FI/F�e�[�u���f�[�^�̃C���f�b�N�X�ԍ�
   ,io_error_msg_tab    IN  OUT g_error_msg_ttype                 --   PL/SQL�\�F�G���[���b�Z�[�W
   ,ov_errbuf           OUT VARCHAR2                              --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode          OUT VARCHAR2                              --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg           OUT VARCHAR2)                             --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_exist_forecast_p'; -- �v���O������
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
    lb_delete           BOOLEAN := TRUE;      -- �폜�t���O(1-20�ւ��S��Null�̏ꍇ��TRUE)
    ln_dummy            NUMBER;               -- �����ANUMBER�^�m�F�p
    lv_tkn_item         VARCHAR2(100);        -- ���b�Z�[�W�ɓn��TOKEN(��ITEM)
    lv_tkn_value        VARCHAR2(100);        -- ���b�Z�[�W�ɓn��TOKEN(��VALUE)
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
    --1-20�֓��̓`�F�b�N
    --==============================================================
    <<check_input_day_loop>>
    FOR i IN 1..20 LOOP
      IF ( i_ifdata_rec.day_of_service_tab( i ) IS NOT NULL ) THEN
        lb_delete := FALSE;
        EXIT check_input_day_loop;
      END IF;
    END LOOP check_input_day_loop;
--
    -- 1-20�ւ��S��Null�̏ꍇ�̓`�F�b�N���s��Ȃ�
    IF ( lb_delete ) THEN
      RETURN;
    END IF;
--
    --==============================================================
    --����v��f�[�^�o�^�`�F�b�N
    --==============================================================
    SELECT COUNT( 'X' )
    INTO   ln_dummy
    FROM   mrp_forecast_designators mfds    -- �t�H�[�L���X�g��
          ,mrp_forecast_dates mfdt          -- �t�H�[�L���X�g���t
          ,xxcop_item_categories1_v xicv    -- �v��_�i�ڃJ�e�S���r���[1
    WHERE  mfds.attribute3 = i_ifdata_rec.base_code
    AND    mfds.attribute2 = i_ifdata_rec.whse_code
    AND    mfds.attribute1 = cv_mfds_attribute1
    AND    mfds.organization_id = gn_org_id
    AND    mfds.organization_id = mfdt.organization_id
    AND    mfds.forecast_designator = mfdt.forecast_designator
    AND    mfdt.forecast_date BETWEEN TO_DATE(i_ifdata_rec.target_month || cv_first_day, cv_date_format1 )
                              AND     LAST_DAY( TO_DATE(i_ifdata_rec.target_month, cv_date_format3 ) )
    AND    mfdt.inventory_item_id = xicv.inventory_item_id
    AND    xicv.prod_class_code = cv_prod_class_code
    ;
    -- �Y���f�[�^�����݂���ꍇ�̓G���[���b�Z�[�W��ݒ�
    IF ( ln_dummy > 0 ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_application
                      ,iv_name         => cv_message_10004
                      ,iv_token_name1  => cv_message_10004_token_1
                      ,iv_token_value1 => i_ifdata_rec.target_month
                     );
      IF ( ov_retcode = cv_status_normal ) THEN
        io_error_msg_tab( in_ifdata_tab_idx ) := lv_errmsg;
      ELSE
        io_error_msg_tab( in_ifdata_tab_idx ) := io_error_msg_tab( in_ifdata_tab_idx ) || 
                                                 CHR(13) || CHR(10) || lv_errmsg;
      END IF;
      ov_retcode := cv_status_warn;
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
  END chk_exist_forecast_p;
--
  /**********************************************************************************
   * Procedure Name   : reg_leaf_data_p
   * Description      : A-7.���[�t�փf�[�^�o�^�E�폜
   ***********************************************************************************/
  PROCEDURE reg_leaf_data_p(
    i_ifdata_rec        IN  g_ifdata_rtype                 --   �t�@�C���A�b�v���[�hI/F�e�[�u���v�f
   ,on_delete_count     OUT NUMBER                         --   �폜����
   ,on_insert_count     OUT NUMBER                         --   �o�^����
   ,ov_errbuf           OUT VARCHAR2                       --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode          OUT VARCHAR2                       --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg           OUT VARCHAR2)                      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'reg_leaf_data_p'; -- �v���O������
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
    lv_tkn_item         VARCHAR2(100);        -- ���b�Z�[�W�ɓn��TOKEN(��ITEM)
    lv_tkn_value        VARCHAR2(100);        -- ���b�Z�[�W�ɓn��TOKEN(��VALUE)
    lv_tkn_table        VARCHAR2(100);        -- ���b�Z�[�W�ɓn��TOKEN(��TABLE)
    lv_tkn_store        VARCHAR2(100);        -- ���b�Z�[�W�ɓn��TOKEN(��STORE)
    lv_tkn_location     VARCHAR2(100);        -- ���b�Z�[�W�ɓn��TOKEN(��LOCATION)
    lv_tkn_yyyymm       VARCHAR2(100);        -- ���b�Z�[�W�ɓn��TOKEN(��YYYYMM)
    lr_xldos_rowid      ROWID;                -- ���[�t�փf�[�^�A�h�I���e�[�u��.ROWID
--
    -- *** ���[�J��TABLE�^ ***
    TYPE l_xldow_rowid_ttype      IS TABLE OF ROWID INDEX BY BINARY_INTEGER;    -- ���[�t�փf�[�^�A�h�I���e�[�u��.ROWID
--
    -- *** ���[�J��PL/SQL�\ ***
    l_xldow_rowid_tab   l_xldow_rowid_ttype;  -- ���[�t�փf�[�^�A�h�I���e�[�u��.ROWID
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
    -- �ϐ��̏�����
    on_delete_count := 0;
    on_insert_count := 0;
--
    --==============================================================
    --�Ώۃ��R�[�h�̃��b�N
    --==============================================================
    BEGIN
      SELECT xldos.ROWID
      BULK COLLECT
      INTO   l_xldow_rowid_tab
      FROM   xxcop_leaf_day_of_service xldos
      WHERE  xldos.whse_code    = i_ifdata_rec.whse_code
      AND    xldos.base_code    = i_ifdata_rec.base_code
      AND    xldos.target_month = i_ifdata_rec.target_month
      FOR UPDATE NOWAIT
      ;
    EXCEPTION
      WHEN OTHERS THEN
        ov_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_application
                        ,iv_name         => cv_message_00007
                        ,iv_token_name1  => cv_message_00007_token_1
                        ,iv_token_value1 => cv_table_xldos
                       );
        ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
        ov_retcode := cv_status_error;                                            --# �C�� #
        RETURN;
    END;
--
    --==============================================================
    --�Ώۃ��R�[�h�̍폜
    --==============================================================
    BEGIN
      DELETE xxcop_leaf_day_of_service xldos
      WHERE  xldos.whse_code    = i_ifdata_rec.whse_code
      AND    xldos.base_code    = i_ifdata_rec.base_code
      AND    xldos.target_month = i_ifdata_rec.target_month
      ;
      -- �폜�������擾
      on_delete_count := SQL%ROWCOUNT;
    EXCEPTION
      WHEN OTHERS THEN
        ov_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_application
                        ,iv_name         => cv_message_10002
                        ,iv_token_name1  => cv_message_10002_token_1
                        ,iv_token_value1 => cv_table_xldos
                        ,iv_token_name2  => cv_message_10002_token_2
                        ,iv_token_value2 => i_ifdata_rec.whse_code
                        ,iv_token_name3  => cv_message_10002_token_3
                        ,iv_token_value3 => i_ifdata_rec.base_code
                        ,iv_token_name4  => cv_message_10002_token_4
                        ,iv_token_value4 => i_ifdata_rec.target_month
                       );
        ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
        ov_retcode := cv_status_error;                                            --# �C�� #
        RETURN;
    END;
--
    --==============================================================
    --���[�t�֕\�f�[�^�A�h�I���e�[�u���ւ̓o�^
    --==============================================================
    <<reg_leaf_day_loop>>
    FOR i IN 1..20 LOOP
      -- 1-20�֓��t��Null�łȂ��ꍇ�̂ݓo�^����
      IF ( i_ifdata_rec.day_of_service_tab( i ) IS NOT NULL ) THEN
        BEGIN
          INSERT INTO xxcop_leaf_day_of_service (
            whse_code                     -- �o�ɑq��
           ,base_code                     -- ���_
           ,target_month                  -- �Ώ۔N��
           ,day_of_service                -- ��
           ,created_by                    -- �쐬��
           ,creation_date                 -- �쐬��
           ,last_updated_by               -- �ŏI�X�V��
           ,last_update_date              -- �ŏI�X�V��
           ,last_update_login             -- �ŏI�X�V���O�C��
           ,request_id                    -- �v��ID
           ,program_application_id        -- �v���O�����A�v���P�[�V����ID
           ,program_id                    -- �v���O����ID
           ,program_update_date           -- �v���O�����X�V��
          ) VALUES (
            i_ifdata_rec.whse_code                  -- �o�ɑq��
           ,i_ifdata_rec.base_code                  -- ���_
           ,i_ifdata_rec.target_month               -- �Ώ۔N��
           ,i_ifdata_rec.day_of_service_tab( i )    -- ��
           ,cn_created_by                           -- �쐬��
           ,cd_creation_date                        -- �쐬��
           ,cn_last_updated_by                      -- �ŏI�X�V��
           ,cd_last_update_date                     -- �ŏI�X�V��
           ,cn_last_update_login                    -- �ŏI�X�V���O�C��
           ,cn_request_id                           -- �v��ID
           ,cn_program_application_id               -- �v���O�����A�v���P�[�V����ID
           ,cn_program_id                           -- �v���O����ID
           ,cd_program_update_date                  -- �v���O�����X�V��
          )
          ;
        EXCEPTION
          WHEN OTHERS THEN
            ov_errmsg  := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_application
                            ,iv_name         => cv_message_10003
                            ,iv_token_name1  => cv_message_10003_token_1
                            ,iv_token_value1 => cv_table_xldos
                            ,iv_token_name2  => cv_message_10003_token_2
                            ,iv_token_value2 => i_ifdata_rec.whse_code
                            ,iv_token_name3  => cv_message_10003_token_3
                            ,iv_token_value3 => i_ifdata_rec.base_code
                            ,iv_token_name4  => cv_message_10003_token_4
                            ,iv_token_value4 => i_ifdata_rec.target_month
                            ,iv_token_name5  => cv_message_10003_token_5
                            ,iv_token_value5 => i_ifdata_rec.day_of_service_tab( i )
                           );
            ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
            ov_retcode := cv_status_error;                                            --# �C�� #
            RETURN;
        END;
        -- �o�^�������J�E���g
        on_insert_count := on_insert_count + 1;
      END IF;
    END LOOP reg_leaf_day_loop;
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
  END reg_leaf_data_p;
--
  /**********************************************************************************
   * Procedure Name   : judge_result_p
   * Description      : A-8.�������e����
   ***********************************************************************************/
  PROCEDURE judge_result_p(
    in_delete_count     IN  NUMBER                                --   �폜����
   ,in_insert_count     IN  NUMBER                                --   �o�^����
   ,in_ifdata_tab_idx   IN  NUMBER                                --   PL/SQL�\�FI/F�e�[�u���f�[�^�̃C���f�b�N�X�ԍ�
   ,io_result_tab       IN  OUT g_result_ttype                    --   PL/SQL�\�F��������
   ,ov_errbuf           OUT VARCHAR2                              --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode          OUT VARCHAR2                              --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg           OUT VARCHAR2)                             --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'judge_result_p'; -- �v���O������
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
    --�������ʂ̔���
    --==============================================================
    -- �o�^������1�ȏ�̏ꍇ
    IF ( in_insert_count > 0 ) THEN
      -- �폜������1�ȏ�̏ꍇ
      IF ( in_delete_count > 0 ) THEN
        io_result_tab( in_ifdata_tab_idx ) := cv_result_update;  -- �X�V
      ELSE
        io_result_tab( in_ifdata_tab_idx ) := cv_result_insert;  -- �o�^
      END IF;
--
    -- �o�^������0�̏ꍇ
    ELSE
      io_result_tab( in_ifdata_tab_idx ) := cv_result_delete;  -- �폜
    END IF;
--
  EXCEPTION
--
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
  END judge_result_p;
--
  /**********************************************************************************
   * Procedure Name   : output_report_p
   * Description      : A-11.�A�b�v���[�h���e�̏o��
   ***********************************************************************************/
  PROCEDURE output_report_p(
    i_ifdata_tab        IN xxccp_common_pkg2.g_file_data_tbl      --   PL/SQL�\�FI/F�e�[�u���f�[�^
   ,i_error_msg_tab     IN g_error_msg_ttype                      --   PL/SQL�\�F�G���[���b�Z�[�W
--   ,i_warning_msg_tab   IN g_warning_msg_ttype                    --   PL/SQL�\�F�x�����b�Z�[�W
   ,i_result_tab        IN g_result_ttype                         --   PL/SQL�\�F��������
   ,iv_retcode          IN VARCHAR2                               --   ���^�[���E�R�[�h
   ,iv_errmsg           IN VARCHAR2                               --   ���[�U�[�E�G���[�E���b�Z�[�W(�Q�Ɨp)
   ,iv_notice           IN VARCHAR2                               --   �t�@�C���A�b�v���[�hI/F�e�[�u���폜���̃G���[
   ,ov_errbuf           OUT VARCHAR2                              --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode          OUT VARCHAR2                              --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg           OUT VARCHAR2)                             --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_report_p'; -- �v���O������
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
    ln_loop             NUMBER;               -- ���[�v�ϐ�
    ln_dummy            NUMBER;               -- �����ANUMBER�^�m�F�p
    lv_tkn_item         VARCHAR2(100);        -- ���b�Z�[�W�ɓn��TOKEN(��ITEM)
    lv_tkn_value        VARCHAR2(100);        -- ���b�Z�[�W�ɓn��TOKEN(��VALUE)
    lv_conc_name        fnd_concurrent_programs.concurrent_program_name%TYPE;   -- �R���J�����g��
    lv_report           VARCHAR2(4096);       -- �o�͕�����
    lv_warn_msg_wk      VARCHAR2(4096);       -- �x�����b�Z�[�W�ҏW�p
    lv_error_msg_wk     VARCHAR2(4096);       -- �G���[���b�Z�[�W�ҏW�p
--    lv_finish_msg       VARCHAR2(40);         -- �I�����b�Z�[�W
    lv_crlf             VARCHAR2(2) := CHR(13) || CHR(10);  -- ���s�R�[�h
--
    -- *** ���[�J��TABLE�^ ***
    TYPE l_report_ttype IS TABLE OF VARCHAR2(4096) INDEX BY BINARY_INTEGER;  -- �o�͕�����
--
    -- *** ���[�J��PL/SQL�\ ***
    l_report_tab  l_report_ttype;   -- �o�͕�����
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
    --�w�b�_����ݒ�
    --==============================================================
    -- �o�͕�������Z�b�g
    l_report_tab( l_report_tab.COUNT + 1 ) := '';
    l_report_tab( l_report_tab.COUNT + 1 ) := xxccp_common_pkg.get_msg(
                                                iv_application  => cv_msg_application
                                               ,iv_name         => cv_message_00036
                                               ,iv_token_name1  => cv_message_00036_token_1
                                               ,iv_token_value1 => gn_param_file_id
                                               ,iv_token_name2  => cv_message_00036_token_2
                                               ,iv_token_value2 => gn_param_format_pattern
                                               ,iv_token_name3  => cv_message_00036_token_3
                                               ,iv_token_value3 => gv_upload_name
                                               ,iv_token_name4  => cv_message_00036_token_4
                                               ,iv_token_value4 => gv_file_name
                                              );
--
    --==============================================================
    --�捞�����܂��͎捞���s�f�[�^��ݒ�
    --==============================================================
    -- PL/SQL�\�FI/F�e�[�u���f�[�^�����݂���ꍇ�̂ݎ��s
    IF ( i_ifdata_tab.COUNT > 0 ) THEN
      -- PL/SQL�\�F�G���[���b�Z�[�W�����݂��Ȃ��ꍇ
      IF ( i_error_msg_tab.COUNT = 0 ) THEN
        --==============================================================
        --�捞�����f�[�^���o��
        --==============================================================
        -- ���o����ݒ�
        l_report_tab( l_report_tab.COUNT + 1 ) := '';
        l_report_tab( l_report_tab.COUNT + 1 ) := cv_title_upload_ok;
--
        -- �捞�����f�[�^��ݒ�iPL/SQL�\�F�������ʂ̌������J��Ԃ��j
        ln_loop := 0;
        <<set_upload_ok_loop>>
        WHILE ( ln_loop < i_result_tab.LAST ) LOOP
          -- PL/SQL�\�̎��̃��R�[�h�ֈړ�
          ln_loop := i_result_tab.NEXT( ln_loop );
--
          lv_report := LPAD( ( ln_loop - i_result_tab.FIRST + 1 ), 5 );   -- ���R�[�h�ԍ��i�擪���p�X�y�[�X���߂�5���ɕҏW�j
          lv_report := lv_report || ' ' || i_result_tab( ln_loop );       -- PL/SQL�\�F��������
          lv_report := lv_report || ' ' || i_ifdata_tab( ln_loop );       -- PL/SQL�\�FI/F�e�[�u���f�[�^
          l_report_tab( l_report_tab.COUNT + 1 ) := lv_report;
----
--          -- PL/SQL�\�F�x�����b�Z�[�W�i�Y������C���f�b�N�X�����݂���ꍇ�̂݁j
--          IF ( i_warning_msg_tab.EXISTS( ln_loop ) ) THEN
--            -- PL/SQL�\�F�x�����b�Z�[�W��ҏW�i�s���Ƃɐ擪�ɔ��p�X�y�[�X6����t�^�j
--            lv_warn_msg_wk := REPLACE( i_warning_msg_tab( ln_loop ), lv_crlf, lv_crlf || RPAD( ' ', 6 ) );
--            lv_warn_msg_wk := RPAD( ' ', 6 ) || lv_warn_msg_wk;
--            l_report_tab( l_report_tab.COUNT + 1 ) := lv_warn_msg_wk;
--          END IF;
        END LOOP set_upload_ok_loop;
--
      -- PL/SQL�\�F�G���[���b�Z�[�W�����݂���ꍇ
      ELSE
        --==============================================================
        --�捞���s�f�[�^���o��
        --==============================================================
        -- ���o����ݒ�
        l_report_tab( l_report_tab.COUNT + 1 ) := '';
        l_report_tab( l_report_tab.COUNT + 1 ) := cv_title_upload_ng;
--
        -- �捞���s�f�[�^��ݒ�iPL/SQL�\�F�G���[���b�Z�[�W�̌������J��Ԃ��j
        ln_loop := 0;
        <<set_upload_ng_loop>>
        WHILE ( ln_loop < i_error_msg_tab.LAST ) LOOP
          -- PL/SQL�\�̎��̃��R�[�h�ֈړ�
          ln_loop := i_error_msg_tab.NEXT( ln_loop );
--
          lv_report := LPAD( ( ln_loop - i_ifdata_tab.FIRST + 1 ), 5 );   -- ���R�[�h�ԍ��i�擪���p�X�y�[�X���߂�5���ɕҏW�j
          lv_report := lv_report || ' ' || i_ifdata_tab( ln_loop );       -- PL/SQL�\�FI/F�e�[�u���f�[�^
--
          -- PL/SQL�\�F�G���[���b�Z�[�W��ҏW�i�s���Ƃɐ擪�ɔ��p�X�y�[�X6����t�^�j
          lv_error_msg_wk := REPLACE( i_error_msg_tab( ln_loop ), lv_crlf, lv_crlf || RPAD( ' ', 6 ) );
          lv_error_msg_wk := RPAD( ' ', 6 ) || lv_error_msg_wk;
--
          lv_report := lv_report || lv_crlf || lv_error_msg_wk;  -- PL/SQL�\�F�G���[���b�Z�[�W
          l_report_tab( l_report_tab.COUNT + 1 ) := lv_report;
        END LOOP set_upload_ng_loop;
--
      END IF;
--
    END IF;
--
    --==============================================================
    --�G���[���b�Z�[�W�̐ݒ�
    --==============================================================
    IF ( iv_errmsg IS NOT NULL ) THEN
      l_report_tab( l_report_tab.COUNT + 1 ) := iv_errmsg;
    END IF;
--
    IF ( iv_notice IS NOT NULL ) THEN
      l_report_tab( l_report_tab.COUNT + 1 ) := iv_notice;
    END IF;
--
    --==============================================================
    --�������b�Z�[�W�̐ݒ�
    --==============================================================
    -- ���^�[���R�[�h���u�G���[�v�łȂ��ꍇ
    IF ( iv_retcode <> cv_status_error ) THEN
      -- �e����������ݒ�
      gn_normal_cnt    := gn_target_cnt;
      gn_error_cnt     := 0;
    -- ���^�[���R�[�h���u�G���[�v�̏ꍇ
    ELSE
      -- �e����������ݒ�
      gn_normal_cnt    := 0;
      gn_error_cnt     := i_error_msg_tab.COUNT;
    END IF;
--
    --==============================================================
    --�������ʃ��|�[�g�ւ̏o��
    --==============================================================
    ln_loop := 0;
    <<output_report_loop>>
    WHILE ( ln_loop < l_report_tab.LAST ) LOOP
      -- PL/SQL�\�̎��̃��R�[�h�ֈړ�
      ln_loop := l_report_tab.NEXT( ln_loop );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => l_report_tab( ln_loop )
      );
    END LOOP output_report_loop;
    -- PL/SQL�\�F�o�͕�����̏�����
    l_report_tab.DELETE;
--
    --==============================================================
    --���O�ւ̏o��
    --==============================================================
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => xxccp_common_pkg.get_msg(
                   iv_application  => cv_msg_application
                  ,iv_name         => cv_message_00036
                  ,iv_token_name1  => cv_message_00036_token_1
                  ,iv_token_value1 => gn_param_file_id
                  ,iv_token_name2  => cv_message_00036_token_2
                  ,iv_token_value2 => gn_param_format_pattern
                  ,iv_token_name3  => cv_message_00036_token_3
                  ,iv_token_value3 => gv_upload_name
                  ,iv_token_name4  => cv_message_00036_token_4
                  ,iv_token_value4 => gv_file_name
                 )
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
  END output_report_p;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT VARCHAR2,    --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,    --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_errmsg2 VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W(�A�b�v���[�h���e�̏o��)
    lv_notice  VARCHAR2(5000);  -- �t�@�C���A�b�v���[�hI/F�e�[�u���폜���̃G���[(���^�[���E�R�[�h�ɂ͔��f�����Ȃ�)
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    lv_file_format      VARCHAR2(256);    -- �t�@�C���t�H�[�}�b�g
    ln_delete_count     NUMBER;           -- �폜����
    ln_insert_count     NUMBER;           -- �o�^����
    ln_ifdata_tab_idx   NUMBER;           -- PL/SQL�\�FI/F�e�[�u���f�[�^�̃C���f�b�N�X�ԍ�
    ln_A_1_error_cnt    NUMBER := 0;      -- A-1�G���[����
--
    -- *** ���[�J�����R�[�h ***
    l_ifdata_rec           g_ifdata_rtype;  -- �t�@�C���A�b�v���[�hI/F�e�[�u���v�f
--
    -- *** ���[�J��PL/SQL�\ ***
    l_csv_div_data_tab     xxcop_common_pkg.g_char_ttype;       -- CSV�v�f
    l_ifdata_tab           xxccp_common_pkg2.g_file_data_tbl;   -- I/F�e�[�u���f�[�^
--    l_warning_msg_tab      g_warning_msg_ttype;                 -- �x�����b�Z�[�W
    l_error_msg_tab        g_error_msg_ttype;                   -- �G���[���b�Z�[�W�F�����s�̏ꍇ����
    l_result_tab           g_result_ttype;                      -- �������ʁF(�o�^),(�X�V),(�폜)�̉��ꂩ
--
    -- *** ���[�J���E���[�U��`��O ***
    submain_expt EXCEPTION;
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
    BEGIN
--
      -- ===============================
      -- A-2.�p�����[�^�Ó����`�F�b�N
      -- ===============================
      chk_parameter_p(
        lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE submain_expt;
      END IF;
--
      -- ===============================
      -- A-1.�g�DID�̎擾
      -- ===============================
      BEGIN
        gn_org_id := TO_NUMBER( FND_PROFILE.VALUE( cv_master_org_id ) );  -- �}�X�^�i�ڑg�DID(�Œ�l:113)
      EXCEPTION
        WHEN OTHERS THEN
          gn_org_id := NULL;
      END;
--
      -- �v���t�@�C������}�X�^�i�ڑg�DID���擾�o���Ȃ��A�܂��͐��l�łȂ��ꍇ
      IF ( gn_org_id IS NULL ) THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_application
                        ,iv_name         => cv_message_00002
                        ,iv_token_name1  => cv_message_00002_token_1
                        ,iv_token_value1 => cv_master_org_id_name
                       );
        lv_retcode := cv_status_error;
        ln_A_1_error_cnt := 1;
        RAISE submain_expt;
      END IF;
--20090428_Ver1.1_T1_0645_SCS.Kikuchi_ADD_START
      -- ===============================
      --  �c�Ƒg�D�R�[�h�̎擾
      -- ===============================
      BEGIN
        gv_sales_org_code := fnd_profile.value(cv_sales_org_code);
      EXCEPTION
        WHEN OTHERS THEN
          gv_sales_org_code := NULL;
      END;
      -- �v���t�@�C���F�c�Ƒg�D���擾�o���Ȃ��ꍇ
      IF ( gv_sales_org_code IS NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_application
                      ,iv_name         => cv_message_00002
                      ,iv_token_name1  => cv_message_00002_token_1
                      ,iv_token_value1 => cv_sales_org_code_name
                     );
        lv_retcode   := cv_status_error;
        ln_A_1_error_cnt := 1;
        RAISE submain_expt;
      END IF;
      -- ===============================
      --  �c�Ƒg�DID�̎擾
      -- ===============================
      BEGIN
        SELECT organization_id
        INTO   gn_sales_org_id
        FROM   mtl_parameters
        WHERE  organization_code = gv_sales_org_code
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          gn_sales_org_id := NULL;
      END;
      -- �c�Ƒg�DID���擾�o���Ȃ��ꍇ
      IF ( gn_sales_org_id IS NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_application
                      ,iv_name         => cv_message_00013
                      ,iv_token_name1  => cv_message_00013_token_1
                      ,iv_token_value1 => cv_item_org_code
                      ,iv_token_name2  => cv_message_00013_token_2
                      ,iv_token_value2 => gv_sales_org_code
                      ,iv_token_name3  => cv_message_00013_token_3
                      ,iv_token_value3 => cv_table_mp
                     );
        lv_retcode   := cv_status_error;
        ln_A_1_error_cnt := 1;
        RAISE submain_expt;
      END IF;
--20090428_Ver1.1_T1_0645_SCS.Kikuchi_ADD_END
--
      -- ===============================
      -- A-3.�N�C�b�N�R�[�h�擾(���[�t��CSV�t�@�C���̃t�H�[�}�b�g)
      -- ===============================
      get_format_pattern_p(
        lv_file_format              -- �t�@�C���t�H�[�}�b�g
       ,lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
       ,lv_errmsg);                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE submain_expt;
      END IF;
--
      -- ===============================
      -- A-4.�t�@�C���A�b�v���[�hI/F�e�[�u���f�[�^���o
      -- ===============================
      get_file_ul_interface_p(
        l_ifdata_tab                -- PL/SQL�\�FI/F�e�[�u���f�[�^
       ,lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
       ,lv_errmsg);                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE submain_expt;
      END IF;
--
      -- ===============================
      -- Loop-1.I/F�e�[�u���Ώۃf�[�^
      -- ===============================
      -- I/F�e�[�u���Ώۃf�[�^�����݂���ꍇ�̂�
      IF ( l_ifdata_tab.COUNT > 0 ) THEN
        <<ul_interface_loop>>
        FOR ln_ifdata_tab_idx IN l_ifdata_tab.FIRST..l_ifdata_tab.LAST LOOP
--
          -- �󔒍s�͓ǂݔ�΂�
          IF ( l_ifdata_tab( ln_ifdata_tab_idx ) IS NOT NULL ) THEN
            -- �����������J�E���g
            gn_target_cnt := gn_target_cnt + 1;
            -- ===============================
            -- A-5.�f�[�^�Ó����`�F�b�N
            -- ===============================
            chk_validate_data_f(
              lv_file_format              -- �t�@�C���t�H�[�}�b�g
             ,l_ifdata_tab                -- PL/SQL�\�FI/F�e�[�u���f�[�^
             ,ln_ifdata_tab_idx           -- PL/SQL�\�FI/F�e�[�u���f�[�^�̃C���f�b�N�X�ԍ�
             ,l_csv_div_data_tab          -- PL/SQL�\�FCSV�v�f
             ,l_ifdata_rec                -- ���R�[�h�F�t�@�C���A�b�v���[�hI/F�e�[�u���v�f
             ,l_error_msg_tab             -- PL/SQL�\�F�G���[���b�Z�[�W
             ,lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
             ,lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
             ,lv_errmsg);                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
            IF ( lv_retcode = cv_status_warn ) THEN
              -- �`�F�b�N�G���[�̏ꍇ�͏I���X�e�[�^�X���u�G���[�v�Ƃ��A�����𑱍s����
              ov_retcode := cv_status_error;
            ELSIF ( lv_retcode = cv_status_error ) THEN
              -- ����ȊO�̃G���[�̏ꍇ�͏����𒆒f����
              RAISE submain_expt;
            END IF;
--
            -- A-5.�f�[�^�Ó����`�F�b�N�̏I���X�e�[�^�X���u����v�̏ꍇ�̂�
            IF ( lv_retcode = cv_status_normal ) THEN
--
              -- ===============================
              -- A-6.����v��f�[�^�o�^�`�F�b�N
              -- ===============================
              chk_exist_forecast_p(
                l_ifdata_rec                -- ���R�[�h�F�t�@�C���A�b�v���[�hI/F�e�[�u���v�f
               ,ln_ifdata_tab_idx           -- PL/SQL�\�FI/F�e�[�u���f�[�^�̃C���f�b�N�X�ԍ�
               ,l_error_msg_tab             -- PL/SQL�\�F�G���[���b�Z�[�W
               ,lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
               ,lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
               ,lv_errmsg);                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
              IF ( lv_retcode = cv_status_warn ) THEN
                -- �`�F�b�N�G���[�̏ꍇ�͏I���X�e�[�^�X���u�G���[�v�Ƃ��A�����𑱍s����
                ov_retcode := cv_status_error;
              ELSIF ( lv_retcode = cv_status_error ) THEN
                -- ����ȊO�̃G���[�̏ꍇ�͏����𒆒f����
                RAISE submain_expt;
              END IF;
--
            END IF;
--
            -- �I���X�e�[�^�X���u�G���[�v�ȊO�̏ꍇ�̂�
            IF ( ov_retcode <> cv_status_error ) THEN
--
              -- ===============================
              -- A-7.���[�t�փf�[�^�o�^�E�폜
              -- ===============================
              reg_leaf_data_p(
                l_ifdata_rec                -- �t�@�C���A�b�v���[�hI/F�e�[�u���v�f
               ,ln_delete_count             -- �폜����
               ,ln_insert_count             -- �o�^����
               ,lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
               ,lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
               ,lv_errmsg);                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
              IF ( lv_retcode <> cv_status_normal ) THEN
                RAISE submain_expt;
              END IF;
--
              -- ===============================
              -- A-8.�������e����
              -- ===============================
              judge_result_p(
                ln_delete_count             -- �폜����
               ,ln_insert_count             -- �o�^����
               ,ln_ifdata_tab_idx           -- PL/SQL�\�FI/F�e�[�u���f�[�^�̃C���f�b�N�X�ԍ�
               ,l_result_tab                -- PL/SQL�\�F��������
               ,lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
               ,lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
               ,lv_errmsg);                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
              IF ( lv_retcode <> cv_status_normal ) THEN
                RAISE submain_expt;
              END IF;
--
            END IF;
          END IF;
        END LOOP ul_interface_loop;
      END IF;
--
    EXCEPTION
      WHEN submain_expt THEN
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_error;
        -- PL/SQL�\�̍폜
        l_ifdata_tab.DELETE;
--        l_warning_msg_tab.DELETE;
        l_error_msg_tab.DELETE;
        l_result_tab.DELETE;
    END;
--
    -- ===============================
    -- A-9.�g�����U�N�V�����̊m��
    -- ===============================
    IF ( ov_retcode = cv_status_error ) THEN
      -- �I���X�e�[�^�X���u�G���[�v�̏ꍇ�̓��[���o�b�N����
      ROLLBACK;
    ELSE
      -- �I���X�e�[�^�X���u�G���[�v�ȊO�̏ꍇ�̓R�~�b�g����
      COMMIT;
    END IF;
--
    
    -- ===============================
    -- A-10.�t�@�C���A�b�v���[�hI/F�e�[�u���̍폜
    -- ===============================
    xxcop_common_pkg.delete_upload_table(
      in_file_id   => gn_param_file_id            -- �t�@�C���h�c
     ,ov_retcode   => lv_retcode                  -- ���^�[���R�[�h
     ,ov_errbuf    => lv_errbuf                   -- �G���[�E���b�Z�[�W
     ,ov_errmsg    => lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
--
    -- �߂�l������łȂ��ꍇ�i��ov_retcode�͕ύX���Ȃ��j
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- ���b�N�G���[�ȊO�̏ꍇ�i���b�N�G���[�͋��ʊ֐�����APP-XXCOP1-00007�o�͍ς݁j
      IF ( lv_errbuf IS NOT NULL ) THEN
        lv_notice  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_application
                        ,iv_name         => cv_message_00031
                        ,iv_token_name1  => cv_message_10031_token_1
                        ,iv_token_value1 => '�t�@�C���A�b�v���[�hI/F�e�[�u��'
                        ,iv_token_name2  => cv_message_10031_token_2
                        ,iv_token_value2 => gn_param_file_id
                       );
      END IF;
    ELSE
      COMMIT;
    END IF;
--
    -- ===============================
    -- A-11.�A�b�v���[�h���e�̏o��
    -- ===============================
    output_report_p(
      l_ifdata_tab                -- PL/SQL�\�FI/F�e�[�u���f�[�^
     ,l_error_msg_tab             -- PL/SQL�\�F�G���[���b�Z�[�W
--     ,l_warning_msg_tab           -- PL/SQL�\�F�x�����b�Z�[�W
     ,l_result_tab                -- PL/SQL�\�F��������
     ,ov_retcode                  -- ���^�[���E�R�[�h
     ,lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W(�Q�Ɨp)
     ,lv_notice                   -- �t�@�C���A�b�v���[�hI/F�e�[�u���폜���̃G���[
     ,lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
     ,lv_errmsg2);                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--

    gn_error_cnt := gn_error_cnt + ln_A_1_error_cnt;
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
      -- �J�[�\���̃N���[�Y�������ɋL�q����
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
    errbuf            OUT VARCHAR2,    --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode           OUT VARCHAR2,    --   ���^�[���E�R�[�h    --# �Œ� #
    in_file_id        IN  VARCHAR2,    --   FILE_ID
    in_format_pattern IN  VARCHAR2     --   �t�H�[�}�b�g�E�p�^�[��
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
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- �v���O������
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
    -- �p�����[�^�̊i�[
    -- ===============================================
    gv_param_file_id        := in_file_id;
    gv_param_format_pattern := in_format_pattern;
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
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
--    --�X�L�b�v�����o��
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_appl_short_name
--                    ,iv_name         => cv_skip_rec_msg
--                    ,iv_token_name1  => cv_cnt_token
--                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
--                   );
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT
--      ,buff   => gv_out_msg
--    );
--    --
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
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCOP004A01C;
/
