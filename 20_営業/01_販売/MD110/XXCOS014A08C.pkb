CREATE OR REPLACE PACKAGE BODY XXCOS014A08C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS014A08C (body)
 * Description      : CSV�f�[�^�A�b�v���[�h(�l����`�Ǘ��䒠)
 * MD.050           : CSV�f�[�^�A�b�v���[�h(�l����`�Ǘ��䒠)(MD050_COS_014_A08)
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-0)
 *  get_upload_file_data   �t�@�C���A�b�v���[�hIF�f�[�^�̎擾(A-1)
 *  delete_upload_file     �t�@�C���A�b�v���[�hIF�f�[�^�̍폜(A-2)
 *  init_2                 ��������(A-3)
 *  divide_register_data   �l����`�Ǘ��䒠�f�[�^�̍��ڕ�������(A-4)
 *  check_validate_item    ���ڃ`�F�b�N(A-5)
 *  ins_rep_form_register  �l����`�Ǘ��䒠�}�X�^�o�^����(A-6)
 *  submain                ���C�������v���V�[�W��
 *  main                   �I������(A-7)
 *                         �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/1/13    1.0   T.Oura           �V�K�쐬
 *  2009/2/12    1.1   T.Nakamura       [��QCOS_061] ���b�Z�[�W�o�́A���O�o�͂ւ̏o�͓��e�̒ǉ��E�C��
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
  ct_process_date           CONSTANT DATE        := TRUNC(xxccp_common_pkg2.get_process_date);  -- �Ɩ����t
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
  lock_expt                 EXCEPTION;       -- ���b�N�G���[
  PRAGMA EXCEPTION_INIT( lock_expt, -54 );
  get_data_expt             EXCEPTION;       -- �f�[�^���o�G���[
  delete_data_expt          EXCEPTION;       -- �f�[�^�폜�G���[
  no_data_expt              EXCEPTION;       -- �Ώۃf�[�^�Ȃ��G���[
  unique_restrict_expt      EXCEPTION;       -- ��Ӑ���G���[
  PRAGMA EXCEPTION_INIT( unique_restrict_expt, -1);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCOS014A08C';               -- �p�b�P�[�W��
  cv_application            CONSTANT VARCHAR2(5)   := 'XXCOS';                      -- �A�v���P�[�V������
  -- �v���t�@�C��
  cv_cmn_rep_chain_code     CONSTANT VARCHAR2(100) := 'XXCOS1_CMN_REP_CHAIN_CODE';
  -- �G���[�R�[�h
  cv_msg_COS_00001          CONSTANT VARCHAR2(100)  := 'APP-XXCOS1-00001';       -- ���b�N�G���[���b�Z�[�W
  cv_msg_COS_00013          CONSTANT VARCHAR2(100)  := 'APP-XXCOS1-00013';       -- �f�[�^���o�G���[���b�Z�[�W
  cv_msg_COS_00012          CONSTANT VARCHAR2(100)  := 'APP-XXCOS1-00012';       -- �f�[�^�폜�G���[���b�Z�[�W
  cv_msg_COS_00003          CONSTANT VARCHAR2(100)  := 'APP-XXCOS1-00003';       -- �Ώۃf�[�^�Ȃ����b�Z�[�W
  cv_msg_COS_13251          CONSTANT VARCHAR2(100)  := 'APP-XXCOS1-13251';       -- �t�H�[�}�b�g�G���[���b�Z�[�W
  cv_msg_COS_13254          CONSTANT VARCHAR2(100)  := 'APP-XXCOS1-13254';       -- �K�{���̓G���[���b�Z�[�W
  cv_msg_COS_13255          CONSTANT VARCHAR2(100)  := 'APP-XXCOS1-13255';       -- �}�X�^���o�^�G���[���b�Z�[�W
  cv_msg_COS_13256          CONSTANT VARCHAR2(100)  := 'APP-XXCOS1-13256';       -- �f�t�H���g���[�t���O���͒l�G���[���b�Z�[�W
  cv_msg_COS_13257          CONSTANT VARCHAR2(100)  := 'APP-XXCOS1-13257';       -- �f�t�H���g���[�t���O�d���G���[���b�Z�[�W
  cv_msg_COS_13258          CONSTANT VARCHAR2(100)  := 'APP-XXCOS1-13258';       -- �[�i�����s�t���O�ݒ菇�����̓G���[���b�Z�[�W
  cv_msg_COS_13259          CONSTANT VARCHAR2(100)  := 'APP-XXCOS1-13259';       -- �[�i�����s�t���O�ݒ菇���͒l�G���[���b�Z�[�W
  cv_msg_COS_13260          CONSTANT VARCHAR2(100)  := 'APP-XXCOS1-13260';       -- �[�i�����s�t���O�ݒ菇�d���G���[
  cv_msg_COS_13261          CONSTANT VARCHAR2(100)  := 'APP-XXCOS1-13261';       -- �������߃G���[���b�Z�[�W
  cv_msg_COS_13253          CONSTANT VARCHAR2(100)  := 'APP-XXCOS1-13253';       -- ��Ӑ���G���[���b�Z�[�W
  cv_msg_COS_00010          CONSTANT VARCHAR2(100)  := 'APP-XXCOS1-00010';       -- �f�[�^�o�^�G���[���b�Z�[�W
  cv_msg_CCP_90000          CONSTANT VARCHAR2(100)  := 'APP-XXCCP1-90000';       -- �Ώی������b�Z�[�W
  cv_msg_CCP_90001          CONSTANT VARCHAR2(100)  := 'APP-XXCCP1-90001';       -- �����������b�Z�[�W
  cv_msg_CCP_90002          CONSTANT VARCHAR2(100)  := 'APP-XXCCP1-90002';       -- �G���[�������b�Z�[�W
  cv_msg_CCP_90004          CONSTANT VARCHAR2(100)  := 'APP-XXCCP1-90004';       -- ����I�����b�Z�[�W
  cv_msg_CCP_90005          CONSTANT VARCHAR2(100)  := 'APP-XXCCP1-90005';       -- �x���I�����b�Z�[�W
  cv_msg_CCP_90006          CONSTANT VARCHAR2(100)  := 'APP-XXCCP1-90006';       -- �G���[�I���S���[���o�b�N���b�Z�[�W
  cv_msg_COS_13262          CONSTANT VARCHAR2(100)  := 'APP-XXCOS1-13262';       -- �p�����[�^�o�̓��b�Z�[�W
  -- �g�[�N��
  cv_tkn_table              CONSTANT VARCHAR2(20)   := 'TABLE';                  -- �e�[�u����
  cv_tkn_row                CONSTANT VARCHAR2(20)   := 'ROW';                    -- CSV�t�@�C���̍s��
  cv_tkn_column             CONSTANT VARCHAR2(20)   := 'COLUMN';                 -- �e�[�u����
  cv_tkn_value              CONSTANT VARCHAR2(20)   := 'VALUE';                  -- �l
  cv_tkn_value2             CONSTANT VARCHAR2(20)   := 'VALUE2';                 -- �l
  cv_tkn_value3             CONSTANT VARCHAR2(20)   := 'VALUE3';                 -- �l
  cv_tkn_report_type        CONSTANT VARCHAR2(20)   := 'REPORT_TYPE';            -- ���[��ʃR�[�h
  cv_tkn_chain_code         CONSTANT VARCHAR2(20)   := 'CHAIN_CODE';             -- �`�F�[���X�R�[�h
  cv_tkn_flag_order         CONSTANT VARCHAR2(20)   := 'FLAG_ORDER';             -- �[�i�����s�t���O�ݒ菇
  cv_tkn_input_byte         CONSTANT VARCHAR2(20)   := 'INPUT_BYTE';             -- ���͌���
  cv_tkn_max_byte           CONSTANT VARCHAR2(20)   := 'MAX_BYTE';               -- ���͉\�ő包��
  cv_tkn_table_name         CONSTANT VARCHAR2(20)   := 'TABLE_NAME';             -- �e�[�u����
  cv_tkn_key_data           CONSTANT VARCHAR2(20)   := 'KEY_DATA';               -- �G���[�������̃L�[���
  cv_tkn_count              CONSTANT VARCHAR2(20)   := 'COUNT';                  -- �f�[�^����
  cv_tkn_param1             CONSTANT VARCHAR2(20)   := 'PARAM1';                 -- ���̓p�����[�^1
  cv_tkn_param2             CONSTANT VARCHAR2(20)   := 'PARAM2';                 -- ���̓p�����[�^2
  -- �g�[�N��������
  cv_mrp_file_ul_if_tab     CONSTANT VARCHAR2(100)  := 'APP-XXCOS1-13263';       -- '�t�@�C���A�b�v���[�hIF'
  cv_report_form_reg_tab    CONSTANT VARCHAR2(100)  := 'APP-XXCOS1-13264';       -- '�l����`�Ǘ��䒠�}�X�^'
  cv_chain_code             CONSTANT VARCHAR2(100)  := 'APP-XXCOS1-13265';       -- '�`�F�[���X�R�[�h'
  cv_data_type_code         CONSTANT VARCHAR2(100)  := 'APP-XXCOS1-13266';       -- '���[��ʃR�[�h'
  cv_report_code            CONSTANT VARCHAR2(100)  := 'APP-XXCOS1-13267';       -- '���[�R�[�h'
  cv_report_name            CONSTANT VARCHAR2(100)  := 'APP-XXCOS1-13268';       -- '���[�l��'
  cv_info_class_name        CONSTANT VARCHAR2(100)  := 'APP-XXCOS1-13269';       -- '���敪����'
  cv_data_type_code_tab     CONSTANT VARCHAR2(100)  := 'APP-XXCOS1-13270';       -- '�f�[�^��R�[�h�}�X�^'
  cv_cust_accoun_tab        CONSTANT VARCHAR2(100)  := 'APP-XXCOS1-13271';       -- '�ڋq�}�X�^'
  -- ���̑�
  cv_file_id                CONSTANT VARCHAR2(100)  := 'FILE_ID';          -- �t�@�C��ID
  cn_header_row_num         CONSTANT NUMBER         := 1;                  -- �w�b�_�[�s��
  cv_delim                  CONSTANT VARCHAR2(1)    := ',';                -- �f���~�^����(�J���})
  cn_column_num             CONSTANT NUMBER         := 8;                  -- ���ڐ�
  cv_line_number            CONSTANT VARCHAR2(100)  := '�s��';             -- �s��
  cv_line_num_cnt           CONSTANT VARCHAR2(100)  := '�s��';             -- �s��
  cv_data_type_code_2       CONSTANT VARCHAR2(100)  := 'XXCOS1_DATA_TYPE_CODE';
                                                                           -- �f�[�^��R�[�h
  cv_tkn_max_byte_4         CONSTANT VARCHAR2(100)  := 4;                  -- �ő�o�C�g���u4�v
  cv_tkn_max_byte_40        CONSTANT VARCHAR2(100)  := 40;                 -- �ő�o�C�g���u40�v
  cv_default_rep_flag_y     CONSTANT VARCHAR2(100)  := 'Y';                -- �f�t�H���g�t���O�uY�v
  cv_default_rep_flag_n     CONSTANT VARCHAR2(100)  := 'N';                -- �f�t�H���g�t���O�uN�v
  cv_control_flag_y         CONSTANT VARCHAR2(100)  := 'Y';                -- �ďo�͐���t���O�uY�v
  cv_chain                  CONSTANT VARCHAR2(100)  := 18;                 -- �`�F�[���X
  cv_error_flag_y           CONSTANT VARCHAR2(100)  := 'Y';                -- �G���[�t���O�uY�v
  cv_delim_7                CONSTANT VARCHAR2(100)  := 7;                  -- �J���}�̐��u7�v
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  --�l����`�Ǘ��䒠���ڃ��C�A�E�g���R�[�h�^
  TYPE g_sourcing_rule_data_rtype IS RECORD (
    chain_code               VARCHAR2(32767)
  , data_type_code           VARCHAR2(32767)
  , report_code              VARCHAR2(32767)
  , report_name              VARCHAR2(32767)
  , info_class               VARCHAR2(32767)
  , info_class_name          VARCHAR2(32767)
  , publish_flag_seq         VARCHAR2(32767)
  , default_report_flag      VARCHAR2(32767)
  );
  --�l����`�Ǘ��䒠���ڃ��C�A�E�g�R���N�V�����^
  TYPE g_sourcing_rule_data_ttype IS TABLE OF g_sourcing_rule_data_rtype
    INDEX BY BINARY_INTEGER;
  -- �l����`�Ǘ��䒠�f�[�^�i�o�^�p�f�[�^�j
  g_ins_data                 g_sourcing_rule_data_ttype;
  -- BLOB�^
  g_rep_form_register_data   xxccp_common_pkg2.g_file_data_tbl;
  --
  TYPE g_var1_ttype IS TABLE OF VARCHAR(32767) INDEX BY BINARY_INTEGER;
  TYPE g_var2_ttype IS TABLE OF g_var1_ttype INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- �v���t�@�C��
  gv_cmn_rep_chain_code       VARCHAR2(100);
  -- ���̑�
  gn_get_counter_data         NUMBER;         -- �擾�f�[�^����
  g_rep_form_reg              g_var2_ttype;   -- �l����`�Ǘ��䒠�f�[�^(����������)
  gn_i                        NUMBER;         -- �C���f�b�N�X(�f�[�^��)
  gn_j                        NUMBER;         -- �C���f�b�N�X(���ڐ�)
  gn_error_flag               VARCHAR2(10);   -- �G���[�t���O
--
--
  /**********************************************************************************
   * Procedure Name   : proc_msg_output
   * Description      : ���b�Z�[�W�A���O�o��
   ***********************************************************************************/
  PROCEDURE proc_msg_output(
    iv_program      IN  VARCHAR2,            -- �v���O������
    iv_message      IN  VARCHAR2)            -- ���[�U�[�E�G���[���b�Z�[�W
  IS
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
    -- ���b�Z�[�W�o��
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT,
      buff   => iv_message
    );
--
    -- ���O���b�Z�[�W����
    lv_errbuf := SUBSTRB( cv_pkg_name||cv_msg_cont||iv_program||cv_msg_part||iv_message, 1, 5000 );
--
    -- ���O�o��
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG,
      buff   => lv_errbuf
    );
--
  END proc_msg_output;
--
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-0)
   ***********************************************************************************/
  PROCEDURE init(
    in_file_id    IN  NUMBER,       -- 1.�t�@�C��ID
    iv_format     IN  VARCHAR2,     -- 2.�t�H�[�}�b�g�p�^�[��
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
-- 2009/02/12 T.Nakamura Ver.1.1 add start
    --�󔒍s�̏o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
-- 2009/02/12 T.Nakamura Ver.1.1 add end
    -- ================================
    -- �R���J�����g���̓p�����[�^�o��
    -- ================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                   , iv_name         => cv_msg_COS_13262
                   , iv_token_name1  => cv_tkn_param1
                   , iv_token_value1 => TO_CHAR( in_file_id )
                   , iv_token_name2  => cv_tkn_param2
                   , iv_token_value2 => iv_format
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
-- 2009/02/12 T.Nakamura Ver.1.1 add start
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
-- 2009/02/12 T.Nakamura Ver.1.1 add end
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
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
  END init;
--
--
  /**********************************************************************************
   * Procedure Name   : get_upload_file_data
   * Description      : �t�@�C���A�b�v���[�hIF�f�[�^�̎擾(A-1)
   ***********************************************************************************/
  PROCEDURE get_upload_file_data(
    in_file_id    IN  NUMBER,       -- 1.�t�@�C��ID
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_upload_file_data'; -- �v���O������
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
    lv_file_name     VARCHAR2(100);       -- �t�@�C����
    ln_created_by    NUMBER;              -- �쐬��
    ld_creation_date DATE;                -- �쐬��
    lv_key_info      VARCHAR2(5000);      -- �ҏW���ꂽ�L�[���
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
    -- ================================
    -- �t�@�C���A�b�v���[�hIF�̃��b�N
    -- ================================
    BEGIN
--
      SELECT  xmfui.file_name                     -- �t�@�C����
            , xmfui.created_by                    -- �쐬��
            , xmfui.creation_date                 -- �쐬��
      INTO    lv_file_name
            , ln_created_by
            , ld_creation_date
      FROM    xxccp_mrp_file_ul_interface xmfui   -- �t�@�C���A�b�v���[�hIF
      WHERE   xmfui.file_id = in_file_id
      FOR UPDATE NOWAIT;
--
    EXCEPTION
      -- ���b�N�G���[
      WHEN lock_expt THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_COS_00001
                       , iv_token_name1  => cv_tkn_table
                       , iv_token_value1 => cv_mrp_file_ul_if_tab
                      );
        lv_errbuf  := lv_errmsg;
        RAISE global_api_expt;
--
      -- �f�[�^���o�G���[
      WHEN OTHERS THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_COS_00013
                       , iv_token_name1  => cv_tkn_table_name
                       , iv_token_value1 => cv_mrp_file_ul_if_tab
                       , iv_token_name2  => cv_tkn_key_data
                       , iv_token_value2 => NULL
                      );
        lv_errbuf  := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- =========================================
    -- �t�@�C���A�b�v���[�hIF�̃f�[�^�擾
    -- =========================================
    --BLOB�f�[�^�ϊ�
    xxccp_common_pkg2.blob_to_varchar2(
       in_file_id   => in_file_id                -- �t�@�C��ID
     , ov_file_data => g_rep_form_register_data  -- �l����`�Ǘ��䒠�f�[�^
     , ov_errbuf    => lv_errbuf                 -- �G���[�E���b�Z�[�W           --# �Œ� #
     , ov_retcode   => lv_retcode                -- ���^�[���E�R�[�h             --# �Œ� #
     , ov_errmsg    => lv_errmsg                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- ���^�[���R�[�h������łȂ��ꍇ
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- �L�[���ҏW
      xxcos_common_pkg.makeup_key_info(
         ov_errbuf      => lv_errbuf,            -- �G���[�E���b�Z�[�W
         ov_retcode     => lv_retcode,           -- ���^�[���R�[�h
         ov_errmsg      => lv_errmsg,            -- ���[�U�E�G���[�E���b�Z�[�W
         ov_key_info    => lv_key_info,          -- �ҏW���ꂽ�L�[���
         iv_item_name1  => cv_file_id,           -- ���ږ���1('FILE_ID')
         iv_data_value1 => TO_CHAR( in_file_id ) -- �f�[�^�̒l1(���̓p�����[�^�̃t�@�C��ID)
       );
--
      lv_errbuf  := lv_errmsg;
      RAISE get_data_expt;
--
    -- ���^�[���R�[�h������ŁA�f�[�^������1���ȉ��̏ꍇ
    ELSE
--
     IF ( g_rep_form_register_data.COUNT <= cn_header_row_num ) THEN
       RAISE no_data_expt;
     END IF;
--
   END IF;
--
   -- �Ώی���
   gn_get_counter_data := g_rep_form_register_data.COUNT;
   gn_target_cnt       := g_rep_form_register_data.COUNT - 1;
--
  EXCEPTION
--
    -- �Ώۃf�[�^�Ȃ��G���[
    WHEN no_data_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application
                      , iv_name         => cv_msg_COS_00003
                     );
      lv_errbuf  := lv_errmsg;
      -- ���O�o��
      proc_msg_output( cv_prg_name, lv_errbuf );
      -- �I���X�e�[�^�X���x���ɐݒ�
      ov_retcode := cv_status_warn;
--
    -- �f�[�^���o�G���[
    WHEN get_data_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application
                      , iv_name         => cv_msg_COS_00013
                      , iv_token_name1  => cv_tkn_table_name
                      , iv_token_value1 => cv_mrp_file_ul_if_tab
                      , iv_token_name2  => cv_tkn_key_data
                      , iv_token_value2 => lv_key_info
                     );
      lv_errbuf  := lv_errmsg;
      -- ���O�o��
      proc_msg_output( cv_prg_name, lv_errbuf );
      -- �I���X�e�[�^�X���G���[�ɐݒ�
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
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
  END get_upload_file_data;
--
--
  /**********************************************************************************
   * Procedure Name   : delete_upload_filenit
   * Description      : �t�@�C���A�b�v���[�hIF�f�[�^�̍폜(A-2)
   ***********************************************************************************/
  PROCEDURE delete_upload_filenit(
    in_file_id    IN  NUMBER,       -- 1.�t�@�C��ID
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_upload_filenit'; -- �v���O������
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
    -- =======================================
    -- �t�@�C���A�b�v���[�hIF�f�[�^�̍폜
    -- =======================================
    BEGIN
      DELETE xxccp_mrp_file_ul_interface xmfui   -- �t�@�C���A�b�v���[�hIF
      WHERE  xmfui.file_id = in_file_id;
--
    EXCEPTION
      -- �f�[�^�폜�G���[
      WHEN OTHERS THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_COS_00012
                       , iv_token_name1  => cv_tkn_table_name
                       , iv_token_value1 => cv_mrp_file_ul_if_tab
                       , iv_token_name2  => cv_tkn_key_data
                       , iv_token_value2 => NULL
                      );
        lv_errbuf  := lv_errmsg;
        RAISE global_api_expt;
    END;
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
  END delete_upload_filenit;
--
--
  /**********************************************************************************
   * Procedure Name   : init_2
   * Description      : ��������(A-3)
   ***********************************************************************************/
  PROCEDURE init_2(
    in_file_id    IN  NUMBER,       -- 1.�t�@�C��ID
    iv_format     IN  VARCHAR2,     -- 2.�t�H�[�}�b�g�p�^�[��
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init_2'; -- �v���O������
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
    lv_chain_code           VARCHAR2(100);
    lv_data_type_code       VARCHAR2(100);
    lv_report_code          VARCHAR2(100);
    lv_report_name          VARCHAR2(100);
    lv_info_class           VARCHAR2(100);
    lv_info_class_name      VARCHAR2(100);
    lv_publish_flag_seq     VARCHAR2(100);
    lv_default_report_flag  VARCHAR2(100);
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
    -- ================================
    -- �l����`�Ǘ��䒠�}�X�^�̃��b�N
    -- ================================
    BEGIN
      LOCK TABLE xxcos_report_forms_register IN EXCLUSIVE MODE NOWAIT;
--
    EXCEPTION
      WHEN lock_expt THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_COS_00001
                       , iv_token_name1  => cv_tkn_table
                       , iv_token_value1 => cv_report_form_reg_tab
                      );
        lv_errbuf  := lv_errmsg;
        RAISE global_api_expt;
--
      -- �f�[�^���o�G���[
      WHEN OTHERS THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_COS_00013
                       , iv_token_name1  => cv_tkn_table_name
                       , iv_token_value1 => cv_report_form_reg_tab
                       , iv_token_name2  => cv_tkn_key_data
                       , iv_token_value2 => NULL
                      );
        lv_errbuf  := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- =====================================
    -- �l����`�Ǘ��䒠�}�X�^�f�[�^�̍폜
    -- =====================================
    BEGIN
      DELETE xxcos_report_forms_register xrfr;   -- �l����`�Ǘ��䒠�}�X�^
--
    EXCEPTION
      -- �f�[�^�폜�G���[
      WHEN OTHERS THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_COS_00012
                       , iv_token_name1  => cv_tkn_table_name
                       , iv_token_value1 => cv_report_form_reg_tab
                       , iv_token_name2  => cv_tkn_key_data
                       , iv_token_value2 => NULL
                      );
        lv_errbuf  := lv_errmsg;
        -- ���[���o�b�N
        ROLLBACK;
        RAISE global_api_expt;
    END;
--
    -- ======================
    -- �v���t�@�C���̎擾
    -- ======================
    gv_cmn_rep_chain_code := fnd_profile.value(cv_cmn_rep_chain_code);
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
  END init_2;
--
--
  /**********************************************************************************
   * Procedure Name   : divide_register_data
   * Description      : �l����`�Ǘ��䒠�f�[�^�̍��ڕ�������(A-4)
   ***********************************************************************************/
  PROCEDURE divide_register_data(
    in_index      IN  NUMBER,    -- 1.�C���f�b�N�X
    ov_errbuf     OUT VARCHAR2,  --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,  --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'divide_register_data'; -- �v���O������
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
    cn_chain_code          CONSTANT NUMBER := 1;   -- �`�F�[���X�R�[�h(���ڇ�)
    cn_data_type_code      CONSTANT NUMBER := 2;   -- ���[��ʃR�[�h(���ڇ�)
    cn_report_code         CONSTANT NUMBER := 3;   -- ���[�R�[�h(���ڇ�)
    cn_report_name         CONSTANT NUMBER := 4;   -- ���[�l��(���ڇ�)
    cn_info_class          CONSTANT NUMBER := 5;   -- ���敪(���ڇ�)
    cn_info_class_name     CONSTANT NUMBER := 6;   -- ���敪����(���ڇ�)
    cn_publish_flag_seq    CONSTANT NUMBER := 7;   -- �[�i�����s�t���O����(���ڇ�)
    cn_default_report_flag CONSTANT NUMBER := 8;   -- �f�t�H���g���[�t���O(���ڇ�)
--
    -- *** ���[�J���ϐ� ***
    lv_delim_count         VARCHAR2(100);
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
    -- �ϐ��ɑ��
    gn_i := in_index;
--
    -- �J���}�̐��ɂ�鍀�ڃ`�F�b�N
    lv_delim_count := LENGTHB ( g_rep_form_register_data(gn_i) ) 
                        - LENGTHB ( REPLACE ( g_rep_form_register_data(gn_i), ',' ) );
--
    -- ======================
    -- �t�H�[�}�b�g�`�F�b�N
    -- ======================
    -- �J���}�̐����u7�v�ł͂Ȃ��ꍇ
    IF ( lv_delim_count <> cv_delim_7 ) THEN
      -- �t�H�[�}�b�g�`�F�b�N�G���[���b�Z�[�W�o��
      lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application
                        , iv_name         => cv_msg_COS_13251
                        , iv_token_name1  => cv_tkn_row
                        , iv_token_value1 => gn_i
                       );
      lv_errbuf  := lv_errmsg;
      -- ���O�o��
      proc_msg_output( cv_prg_name, lv_errbuf );
      -- �I���X�e�[�^�X���ُ�ɐݒ�
      ov_retcode := cv_status_error;
--
    ELSE
      -- ===============
      -- ���ڕ�������
      -- ===============
      --�J��������
      <<get_divide_col_loop>>
      FOR j IN 1 .. cn_column_num LOOP
--
        -------------
        -- ���ڕ���
        -------------
        g_rep_form_reg(gn_i)(j) := xxccp_common_pkg.char_delim_partition(
                                        iv_char     => g_rep_form_register_data(gn_i),
                                        iv_delim    => cv_delim,
                                        in_part_num => j
                                      );
--
      END LOOP get_divide_col_loop;
--
      -- ���ڕ��������f�[�^�̑��
      g_ins_data(gn_i).chain_code           := g_rep_form_reg(gn_i)(cn_chain_code);           -- �`�F�[���X�R�[�h(���ڇ�1)
      g_ins_data(gn_i).data_type_code       := g_rep_form_reg(gn_i)(cn_data_type_code);       -- ���[��ʃR�[�h(���ڇ�2)
      g_ins_data(gn_i).report_code          := g_rep_form_reg(gn_i)(cn_report_code);          -- ���[�R�[�h(���ڇ�3)
      g_ins_data(gn_i).report_name          := g_rep_form_reg(gn_i)(cn_report_name);          -- ���[�l��(���ڇ�4)
      g_ins_data(gn_i).info_class           := g_rep_form_reg(gn_i)(cn_info_class);           -- ���敪(���ڇ�5)
      g_ins_data(gn_i).info_class_name      := g_rep_form_reg(gn_i)(cn_info_class_name);      -- ���敪����(���ڇ�6)
      g_ins_data(gn_i).publish_flag_seq     := g_rep_form_reg(gn_i)(cn_publish_flag_seq);     -- �[�i�����s�t���O����(���ڇ�7)
      g_ins_data(gn_i).default_report_flag  := g_rep_form_reg(gn_i)(cn_default_report_flag);  -- �f�t�H���g���[�t���O(���ڇ�8)
--
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
  END divide_register_data;
--
--
  /**********************************************************************************
   * Procedure Name   : check_validate_item
   * Description      : ���ڃ`�F�b�N(A-5)
   ***********************************************************************************/
  PROCEDURE check_validate_item(
    in_index      IN  NUMBER,       -- 1.�C���f�b�N�X
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_validate_item'; -- �v���O������
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
    cn_1       CONSTANT NUMBER := 1;
    cn_100     CONSTANT NUMBER := 100;
    cn_decimal CONSTANT NUMBER := 1.1;
--
    -- *** ���[�J���ϐ� ***
    lv_data_type_code       VARCHAR2(200);
    lv_output_control_flag  VARCHAR2(200);
    lv_chain_store_code     VARCHAR2(200);
    lv_rep_form_cnt         VARCHAR2(200);
--
    lb_on      BOOLEAN := TRUE;
    lb_off     BOOLEAN := FALSE;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    -- ���ڃ`�F�b�N���R�[�h�^
    TYPE check_rtype IS RECORD (
      notnull_chk_chain         BOOLEAN := lb_on   -- �K�{�`�F�b�N(�`�F�[���X�R�[�h)
    , notnull_chk_report_type   BOOLEAN := lb_on   -- �K�{�`�F�b�N(���[��ʃR�[�h)
    , notnull_chk_report_code   BOOLEAN := lb_on   -- �K�{�`�F�b�N(���[�R�[�h)
    , notnull_chk_report_form   BOOLEAN := lb_on   -- �K�{�`�F�b�N(���[�l��)
    , length_chk_report_code    BOOLEAN := lb_on   -- �����`�F�b�N(���[�R�[�h)
    , length_chk_report_form    BOOLEAN := lb_on   -- �����`�F�b�N(���[�l��)
    , length_chk_info_div_name  BOOLEAN := lb_on   -- �����`�F�b�N(���敪����)
    , master_chk_customer       BOOLEAN := lb_on   -- �}�X�^�`�F�b�N(�ڋq�}�X�^)
    , master_chk_report_type    BOOLEAN := lb_on   -- �}�X�^�`�F�b�N(�f�[�^��}�X�^)
    , value_chk_default_flag    BOOLEAN := lb_on   -- ���͒l�`�F�b�N(�f�t�H���g���[�t���O)
    , dup_chk_default_flag      BOOLEAN := lb_on   -- �d���`�F�b�N(�f�t�H���g���[�t���O)
    , notnull_chk_publish_no    BOOLEAN := lb_on   -- �K�{�`�F�b�N(�[�i�����s�t���O����)
    , range_chk_publish_no      BOOLEAN := lb_on   -- �͈̓`�F�b�N(�[�i�����s�t���O����)
    , dup_chk_publish_no        BOOLEAN := lb_on   -- �d���`�F�b�N(�[�i�����s�t���O����)
    );
--
    -- ���ڃ`�F�b�N���R�[�h
    chk_rec        check_rtype;
    chk_rec_init   check_rtype;
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
    -- �ϐ��ɑ��
    gn_i := in_index;
--
    -- ���ڃ`�F�b�N���R�[�h�̏�����
    chk_rec  := chk_rec_init;
--
    -- =============
    -- �K�{�`�F�b�N
    -- =============
    -- �`�F�[���X�R�[�h�K�{�`�F�b�N
    IF ( chk_rec.notnull_chk_chain ) THEN
      -- �`�F�[���X�R�[�h�����ݒ�̏ꍇ
      IF ( g_ins_data(gn_i).chain_code IS NULL ) THEN
        -- ���b�Z�[�W�o��
        lv_errmsg  := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application
                          , iv_name         => cv_msg_COS_13254
                          , iv_token_name1  => cv_tkn_row
                          , iv_token_value1 => gn_i
                          , iv_token_name2  => cv_tkn_column
                          , iv_token_value2 => cv_chain_code    -- �`�F�[���X�R�[�h
                         );
        lv_errbuf  := lv_errmsg;
        -- ���O�o��
        proc_msg_output( cv_prg_name, lv_errbuf );
        -- �I���X�e�[�^�X���ُ�ɐݒ�
        ov_retcode := cv_status_error;
--
        chk_rec.master_chk_customer  := lb_off;  -- �ڋq�}�X�^�}�X�^�`�F�b�N���{�Ȃ�
        chk_rec.dup_chk_default_flag := lb_off;  -- �f�t�H���g���[�t���O�d���`�F�b�N���{�Ȃ�
        chk_rec.dup_chk_publish_no   := lb_off;  -- �[�t�����s�t���O�ݒ菇�̏d���`�F�b�N���{�Ȃ�
      END IF;
    END IF;
--
    -- ���[��ʃR�[�h�K�{�`�F�b�N
    IF ( chk_rec.notnull_chk_report_type ) THEN
      -- ���[��ʃR�[�h�����ݒ�̏ꍇ
      IF ( g_ins_data(gn_i).data_type_code IS NULL ) THEN
        -- ���b�Z�[�W�o��
        lv_errmsg  := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application
                          , iv_name         => cv_msg_COS_13254
                          , iv_token_name1  => cv_tkn_row
                          , iv_token_value1 => gn_i
                          , iv_token_name2  => cv_tkn_column
                          , iv_token_value2 => cv_data_type_code    -- ���[��ʃR�[�h
                         );
        lv_errbuf  := lv_errmsg;
        -- ���O�o��
        proc_msg_output( cv_prg_name, lv_errbuf );
        -- �I���X�e�[�^�X���ُ�ɐݒ�
        ov_retcode := cv_status_error;
--
        chk_rec.master_chk_report_type  := lb_off;  -- �f�[�^��R�[�h�}�X�^�`�F�b�N���{�Ȃ�
        chk_rec.dup_chk_default_flag    := lb_off;  -- �f�t�H���g���[�t���O�̏d���`�F�b�N���{�Ȃ�
        chk_rec.notnull_chk_publish_no  := lb_off;  -- �[�t�����s�t���O�ݒ菇�̕K�{�`�F�b�N���{�Ȃ�
        chk_rec.dup_chk_publish_no      := lb_off;  -- �[�t�����s�t���O�ݒ菇�̏d���`�F�b�N���{�Ȃ�
      END IF;
    END IF;
--
    -- ���[�R�[�h�K�{�`�F�b�N
    IF ( chk_rec.notnull_chk_report_code ) THEN
      -- ���[�R�[�h�����ݒ�̏ꍇ
      IF ( g_ins_data(gn_i).report_code IS NULL ) THEN
        -- ���b�Z�[�W�o��
        lv_errmsg  := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application
                          , iv_name         => cv_msg_COS_13254
                          , iv_token_name1  => cv_tkn_row
                          , iv_token_value1 => gn_i
                          , iv_token_name2  => cv_tkn_column
                          , iv_token_value2 => cv_report_code     -- ���[�R�[�h
                         );
        lv_errbuf  := lv_errmsg;
        -- ���O�o��
        proc_msg_output( cv_prg_name, lv_errbuf );
        -- �I���X�e�[�^�X���ُ�ɐݒ�
        ov_retcode := cv_status_error;
--
        chk_rec.length_chk_report_code   := lb_off;  -- ���[�R�[�h�̌����`�F�b�N���{�Ȃ�
      END IF;
    END IF;
--
    -- ���[�l���K�{�`�F�b�N
    IF ( chk_rec.notnull_chk_report_form ) THEN
      -- ���[�l�������ݒ�̏ꍇ
      IF ( g_ins_data(gn_i).report_name IS NULL ) THEN
        -- ���b�Z�[�W�o��
        lv_errmsg  := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application
                          , iv_name         => cv_msg_COS_13254
                          , iv_token_name1  => cv_tkn_row
                          , iv_token_value1 => gn_i
                          , iv_token_name2  => cv_tkn_column
                          , iv_token_value2 => cv_report_name     -- ���[�l��
                         );
        lv_errbuf  := lv_errmsg;
        -- ���O�o��
        proc_msg_output( cv_prg_name, lv_errbuf );
        -- �I���X�e�[�^�X���ُ�ɐݒ�
        ov_retcode := cv_status_error;
--
        chk_rec.length_chk_report_form   := lb_off;  -- ���[�l���̌����`�F�b�N���{�Ȃ�
       END IF;
    END IF;
--
    -- ================
    -- �����`�F�b�N
    -- ================
    -- ���[�R�[�h�����`�F�b�N
    IF ( chk_rec.length_chk_report_code ) THEN
      -- ���[�R�[�h��4�o�C�g�𒴂���ꍇ
      IF ( LENGTHB ( g_ins_data(gn_i).report_code ) > cv_tkn_max_byte_4  ) THEN
        -- ���b�Z�[�W�o��
        lv_errmsg  := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application
                          , iv_name         => cv_msg_COS_13261
                          , iv_token_name1  => cv_tkn_row
                          , iv_token_value1 => gn_i
                          , iv_token_name2  => cv_tkn_column
                          , iv_token_value2 => cv_report_code                           -- ���[�R�[�h
                          , iv_token_name3  => cv_tkn_input_byte
                          , iv_token_value3 => LENGTHB ( g_ins_data(gn_i).report_code ) -- �o�C�g��
                          , iv_token_name4  => cv_tkn_max_byte
                          , iv_token_value4 => cv_tkn_max_byte_4                        -- �ő�o�C�g��
                         );
        lv_errbuf  := lv_errmsg;
        -- ���O�o��
        proc_msg_output( cv_prg_name, lv_errbuf );
        -- �I���X�e�[�^�X���ُ�ɐݒ�
        ov_retcode := cv_status_error;
       END IF;
    END IF;
--
    -- ���[�l�������`�F�b�N
    IF ( chk_rec.length_chk_report_form ) THEN
      -- ���[�l����40�o�C�g�𒴂���ꍇ
      IF ( LENGTHB ( g_ins_data(gn_i).report_name ) > cv_tkn_max_byte_40  ) THEN
        -- ���b�Z�[�W�o��
        lv_errmsg  := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application
                          , iv_name         => cv_msg_COS_13261
                          , iv_token_name1  => cv_tkn_row
                          , iv_token_value1 => gn_i
                          , iv_token_name2  => cv_tkn_column
                          , iv_token_value2 => cv_report_name                           -- ���[�l��
                          , iv_token_name3  => cv_tkn_input_byte
                          , iv_token_value3 => LENGTHB ( g_ins_data(gn_i).report_name ) -- �o�C�g��
                          , iv_token_name4  => cv_tkn_max_byte
                          , iv_token_value4 => cv_tkn_max_byte_40                       -- �ő�o�C�g��
                         );
        lv_errbuf  := lv_errmsg;
        -- ���O�o��
        proc_msg_output( cv_prg_name, lv_errbuf );
        -- �I���X�e�[�^�X���ُ�ɐݒ�
        ov_retcode := cv_status_error;
      END IF;
    END IF;
--
    -- ���敪���̌����`�F�b�N
    IF ( chk_rec.length_chk_info_div_name ) THEN
      -- ���敪���̂�40�o�C�g�𒴂���ꍇ
      IF ( LENGTHB ( g_ins_data(gn_i).info_class_name ) > cv_tkn_max_byte_40  ) THEN
        -- ���b�Z�[�W�o��
        lv_errmsg  := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application
                          , iv_name         => cv_msg_COS_13261
                          , iv_token_name1  => cv_tkn_row
                          , iv_token_value1 => gn_i
                          , iv_token_name2  => cv_tkn_column
                          , iv_token_value2 => cv_info_class_name                           -- ���敪����
                          , iv_token_name3  => cv_tkn_input_byte
                          , iv_token_value3 => LENGTHB ( g_ins_data(gn_i).info_class_name ) -- �o�C�g��
                          , iv_token_name4  => cv_tkn_max_byte
                          , iv_token_value4 => cv_tkn_max_byte_40                           -- �ő�o�C�g��
                         );
        lv_errbuf  := lv_errmsg;
        -- ���O�o��
        proc_msg_output( cv_prg_name, lv_errbuf );
        -- �I���X�e�[�^�X���ُ�ɐݒ�
        ov_retcode := cv_status_error;
      END IF;
    END IF;
--
    -- ====================
    -- �}�X�^�`�F�b�N
    -- ====================
    -- �ڋq�}�X�^�`�F�b�N
    IF ( chk_rec.master_chk_customer ) THEN
      -- �l����`�Ǘ��䒠�f�[�^.�`�F�[���X�R�[�h��A-3�Ŏ擾�����v���t�@�C���łȂ��ꍇ
      IF ( g_ins_data(gn_i).chain_code <> gv_cmn_rep_chain_code ) THEN
--
        BEGIN
          SELECT   xca.chain_store_code  chain_store_code     -- �`�F�[���X�R�[�h
          INTO     lv_chain_store_code
          FROM     xxcmm_cust_accounts   xca                  -- �A�J�E���g�E�A�h�I��
                 , hz_cust_accounts      hca                  -- �ڋq�}�X�^
          WHERE    xca.chain_store_code     =  g_ins_data(gn_i).chain_code
          AND      hca.cust_account_id      =  xca.customer_id
          AND      hca.customer_class_code  =  cv_chain;      -- �`�F�[���X
--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- ���b�Z�[�W�o��
            lv_errmsg  := xxccp_common_pkg.get_msg(
                                iv_application  => cv_application
                              , iv_name         => cv_msg_COS_13255
                              , iv_token_name1  => cv_tkn_row
                              , iv_token_value1 => gn_i
                              , iv_token_name2  => cv_tkn_value
                              , iv_token_value2 => g_ins_data(gn_i).chain_code    -- �`�F�[���X�R�[�h
                              , iv_token_name3  => cv_tkn_table
                              , iv_token_value3 => cv_cust_accoun_tab             -- �ڋq�}�X�^
                             );
            lv_errbuf  := lv_errmsg;
            -- ���O�o��
            proc_msg_output( cv_prg_name, lv_errbuf );
            -- �I���X�e�[�^�X���ُ�ɐݒ�
            ov_retcode := cv_status_error;
        END;
--
      END IF;
    END IF;
--
    -- �f�[�^��R�[�h�}�X�^�`�F�b�N
    IF ( chk_rec.master_chk_report_type ) THEN
--
      BEGIN
        SELECT   dtcm.lookup_code   data_type_code          -- �f�[�^��R�[�h
               , dtcm.attribute5    output_control_flag     -- �ďo�͐���t���O
        INTO     lv_data_type_code
               , lv_output_control_flag
        FROM     xxcos_lookup_values_v  dtcm                -- �f�[�^��R�[�h�}�X�^
        WHERE    dtcm.lookup_type  =  cv_data_type_code_2
        AND      dtcm.meaning      =  g_ins_data(gn_i).data_type_code
        AND      ct_process_date
          BETWEEN dtcm.start_date_active
          AND     NVL(dtcm.end_date_active, ct_process_date);
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- ���b�Z�[�W�o��
          lv_errmsg  := xxccp_common_pkg.get_msg(
                              iv_application  => cv_application
                            , iv_name         => cv_msg_COS_13255
                            , iv_token_name1  => cv_tkn_row
                            , iv_token_value1 => gn_i
                            , iv_token_name2  => cv_tkn_value
                            , iv_token_value2 => g_ins_data(gn_i).data_type_code    -- ���[��ʃR�[�h
                            , iv_token_name3  => cv_tkn_table
                            , iv_token_value3 => cv_data_type_code_tab              -- �f�[�^��R�[�h�}�X�^
                           );
          lv_errbuf  := lv_errmsg;
          -- ���O�o��
          proc_msg_output( cv_prg_name, lv_errbuf );
          -- �I���X�e�[�^�X���ُ�ɐݒ�
          ov_retcode := cv_status_error;
          chk_rec.dup_chk_default_flag     := lb_off;  -- �f�t�H���g���[�t���O�̏d���`�F�b�N���{�Ȃ�
          chk_rec.notnull_chk_publish_no   := lb_off;  -- �[�t�����s�t���O�ݒ菇�̕K�{�`�F�b�N���{�Ȃ�
          chk_rec.dup_chk_publish_no       := lb_off;  -- �[�t�����s�t���O�ݒ菇�̏d���`�F�b�N���{�Ȃ�
      END;
    END IF;
--
    -- ====================================
    -- �f�t�H���g���[�t���O���͒l�`�F�b�N
    -- ====================================
    -- �f�t�H���g���[�t���O�����ݒ�̏ꍇ
    IF ( g_ins_data(gn_i).default_report_flag IS NULL ) THEN
      chk_rec.dup_chk_default_flag   := lb_off;  -- �f�t�H���g���[�t���O�̏d���`�F�b�N���{�Ȃ�
--
    -- �f�t�H���g���[�t���O�����ݒ�ȊO�̏ꍇ
    ELSE
      IF ( chk_rec.value_chk_default_flag ) THEN
        -- �f�t�H���g���[�t���O���uY�v�uN�v�ȊO�̏ꍇ
        IF ( ( g_ins_data(gn_i).default_report_flag <> cv_default_rep_flag_y )
          AND ( g_ins_data(gn_i).default_report_flag <> cv_default_rep_flag_n ) )
        THEN
          -- ���b�Z�[�W�o��
          lv_errmsg  := xxccp_common_pkg.get_msg(
                              iv_application  => cv_application
                            , iv_name         => cv_msg_COS_13256
                            , iv_token_name1  => cv_tkn_row
                            , iv_token_value1 => gn_i
                           );
          lv_errbuf  := lv_errmsg;
          -- ���O�o��
          proc_msg_output( cv_prg_name, lv_errbuf );
          -- �I���X�e�[�^�X���ُ�ɐݒ�
          ov_retcode := cv_status_error;
--
        chk_rec.dup_chk_default_flag     := lb_off;  -- �f�t�H���g���[�t���O�̏d���`�F�b�N���{�Ȃ�
--
        END IF;
      END IF;
    END IF;
--
    -- ====================================
    -- �f�t�H���g���[�t���O�d���`�F�b�N
    -- ====================================
    IF ( chk_rec.dup_chk_default_flag ) THEN
      -- �l����`�Ǘ��䒠�f�[�^.�f�t�H���g���[�t���O���uY�v�ł���ꍇ
      IF ( g_ins_data(gn_i).default_report_flag = cv_default_rep_flag_y ) THEN
--
        BEGIN
          SELECT   COUNT(*)                             -- ����
          INTO     lv_rep_form_cnt
          FROM     xxcos_report_forms_register  xrfr     -- �l����`�Ǘ��䒠�}�X�^
          WHERE    xrfr.chain_code           =  g_ins_data(gn_i).chain_code
          AND      xrfr.data_type_code       =  g_ins_data(gn_i).data_type_code
          AND      xrfr.default_report_flag  =  g_ins_data(gn_i).default_report_flag;
        END;
--
        -- ��L���ʂ�1���ȏ㑶�݂���ꍇ
        IF ( lv_rep_form_cnt >= 1 ) THEN
          -- ���b�Z�[�W�o��
          lv_errmsg  := xxccp_common_pkg.get_msg(
                              iv_application  => cv_application
                            , iv_name         => cv_msg_COS_13257
                            , iv_token_name1  => cv_tkn_row
                            , iv_token_value1 => gn_i
                            , iv_token_name2  => cv_tkn_report_type
                            , iv_token_value2 => g_ins_data(gn_i).data_type_code    -- ���[��ʃR�[�h
                            , iv_token_name3  => cv_tkn_chain_code
                            , iv_token_value3 => g_ins_data(gn_i).chain_code        -- �`�F�[���X�R�[�h
                           );
          lv_errbuf  := lv_errmsg;
          -- ���O�o��
          proc_msg_output( cv_prg_name, lv_errbuf );
          -- �I���X�e�[�^�X���ُ�ɐݒ�
          ov_retcode := cv_status_error;
        END IF;
      END IF;
    END IF;
--
    -- ====================================
    -- �[�i�����s�t���O�ݒ菇�K�{�`�F�b�N
    -- ====================================
    IF ( chk_rec.notnull_chk_publish_no ) THEN
      -- �ďo�͐���t���O���uY�v�ŗl����`�Ǘ��䒠�f�[�^.�[�i�����s�t���O�������͂̏ꍇ
      IF ( ( lv_output_control_flag = cv_control_flag_y )
        AND ( g_ins_data(gn_i).publish_flag_seq IS NULL) )
      THEN
        -- ���b�Z�[�W�o��
        lv_errmsg  := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application
                          , iv_name         => cv_msg_COS_13258
                          , iv_token_name1  => cv_tkn_row
                          , iv_token_value1 => gn_i
                          , iv_token_name2  => cv_tkn_report_type
                          , iv_token_value2 => g_ins_data(gn_i).data_type_code  -- ���[��ʃR�[�h
                         );
        lv_errbuf  := lv_errmsg;
        -- ���O�o��
        proc_msg_output( cv_prg_name, lv_errbuf );
        -- �I���X�e�[�^�X���ُ�ɐݒ�
        ov_retcode := cv_status_error;
--
        chk_rec.range_chk_publish_no     := lb_off;  -- �[�i�����s�t���O�ݒ菇�͈̔̓`�F�b�N���{�Ȃ�
        chk_rec.dup_chk_publish_no       := lb_off;  -- �[�t�����s�t���O�ݒ菇�̏d���`�F�b�N���{�Ȃ�
      END IF;
    END IF;
--
    -- ========================================
    -- �[�i�����s�t���O�ݒ菇�͈̔̓`�F�b�N
    -- ========================================
    IF ( chk_rec.range_chk_publish_no ) THEN
      -- �l����`�Ǘ��䒠�f�[�^.�[�i�����s�t���O�ݒ菇��1�`100�̐����łȂ��ꍇ
      IF ( ( g_ins_data(gn_i).publish_flag_seq <  cn_1 )
        OR ( g_ins_data(gn_i).publish_flag_seq >  cn_100 )
        OR ( g_ins_data(gn_i).publish_flag_seq = cn_decimal / ROUND( cn_decimal ) ) )
      THEN
        -- ���b�Z�[�W�o��
        lv_errmsg  := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application
                          , iv_name         => cv_msg_COS_13259
                          , iv_token_name1  => cv_tkn_row
                          , iv_token_value1 => gn_i
                         );
        lv_errbuf  := lv_errmsg;
        -- ���O�o��
        proc_msg_output( cv_prg_name, lv_errbuf );
        -- �I���X�e�[�^�X���ُ�ɐݒ�
        ov_retcode := cv_status_error;
--
        chk_rec.dup_chk_publish_no       := lb_off;  -- �[�t�����s�t���O�ݒ菇�̏d���`�F�b�N���{�Ȃ�
      END IF;
    END IF;
--
    -- ========================================
    -- �[�i�����s�t���O�ݒ菇�̏d���`�F�b�N
    -- ========================================
    IF ( chk_rec.dup_chk_publish_no ) THEN
      -- �l����`�Ǘ��䒠�f�[�^.�[�i�����s�t���O�ݒ菇�����͂���Ă���ꍇ
      IF ( g_ins_data(gn_i).publish_flag_seq IS NOT NULL ) THEN
--
        BEGIN
          SELECT   COUNT(*)                          -- ����
          INTO     lv_rep_form_cnt
          FROM     xxcos_report_forms_register  xrfr  -- �l����`�Ǘ��䒠�}�X�^
          WHERE    xrfr.chain_code           =  g_ins_data(gn_i).chain_code
          AND      xrfr.data_type_code       =  g_ins_data(gn_i).data_type_code
          AND      xrfr.publish_flag_seq     =  g_ins_data(gn_i).publish_flag_seq;
        END;
--
        -- ��L���ʂ�1���ȏ㑶�݂���ꍇ
        IF ( lv_rep_form_cnt >= 1 ) THEN
          -- ���b�Z�[�W�o��
          lv_errmsg  := xxccp_common_pkg.get_msg(
                              iv_application  => cv_application
                            , iv_name         => cv_msg_COS_13260
                            , iv_token_name1  => cv_tkn_row
                            , iv_token_value1 => gn_i
                            , iv_token_name2  => cv_tkn_chain_code
                            , iv_token_value2 => g_ins_data(gn_i).chain_code          -- �`�F�[���X�R�[�h
                            , iv_token_name3  => cv_tkn_flag_order
                            , iv_token_value3 => g_ins_data(gn_i).publish_flag_seq    -- �[�i�����s�t���O����
                           );
          lv_errbuf  := lv_errmsg;
          -- ���O�o��
          proc_msg_output( cv_prg_name, lv_errbuf );
          -- �I���X�e�[�^�X���ُ�ɐݒ�
          ov_retcode := cv_status_error;
        END IF;
      END IF;
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
  END check_validate_item;
--
--
  /**********************************************************************************
   * Procedure Name   : ins_rep_form_register
   * Description      : �l����`�Ǘ��䒠�}�X�^�o�^����(A-6)
   ***********************************************************************************/
  PROCEDURE ins_rep_form_register(
    ov_errbuf     OUT VARCHAR2,                           --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,                           --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)                           --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_rep_form_register'; -- �v���O������
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
    lv_key_info      VARCHAR2(5000);      -- �ҏW���ꂽ�L�[���
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
    -- =============================
    -- �l����`�Ǘ��䒠�}�X�^�o�^
    -- =============================
    BEGIN
      INSERT INTO xxcos_report_forms_register(
          chain_code                             -- �`�F�[���X�R�[�h
        , data_type_code                         -- ���[��ʃR�[�h
        , report_code                            -- ���[�R�[�h
        , report_name                            -- ���[�l��
        , info_class                             -- ���敪
        , info_class_name                        -- ���敪����
        , publish_flag_seq                       -- �[�i�����s�t���O����
        , default_report_flag                    -- �f�t�H���g���[�t���O
        , created_by                             -- �쐬��
        , creation_date                          -- �쐬��
        , last_updated_by                        -- �ŏI�X�V��
        , last_update_date                       -- �ŏI�X�V��
        , last_update_login                      -- �ŏI�X�V���O�C��
        , request_id                             -- �v��ID
        , program_application_id                 -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        , program_id                             -- �R���J�����g�E�v���O����ID
        , program_update_date                    -- �v���O�����X�V��
      )
      VALUES(
          g_ins_data(gn_i).chain_code            -- �`�F�[���X�R�[�h
        , g_ins_data(gn_i).data_type_code        -- ���[��ʃR�[�h
        , g_ins_data(gn_i).report_code           -- ���[�R�[�h
        , g_ins_data(gn_i).report_name           -- ���[�l��
        , g_ins_data(gn_i).info_class            -- ���敪
        , g_ins_data(gn_i).info_class_name       -- ���敪����
        , g_ins_data(gn_i).publish_flag_seq      -- �[�i�����s�t���O����
        , g_ins_data(gn_i).default_report_flag   -- �f�t�H���g���[�t���O
        , cn_created_by                          -- �쐬��
        , cd_creation_date                       -- �쐬��
        , cn_last_updated_by                     -- �ŏI�X�V��
        , cd_last_update_date                    -- �ŏI�X�V��
        , cn_last_update_login                   -- �ŏI�X�V���O�C��
        , cn_request_id                          -- �v��ID
        , cn_program_application_id              -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        , cn_program_id                          -- �R���J�����g�E�v���O����ID
        , cd_program_update_date                 -- �v���O�����X�V��
      );
--
    EXCEPTION
--
      -- ��Ӑ���G���[�ƂȂ����ꍇ
      WHEN unique_restrict_expt THEN
        -- ���b�Z�[�W�o��
        lv_errmsg  := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application
                          , iv_name         => cv_msg_COS_13253
                          , iv_token_name1  => cv_tkn_row
                          , iv_token_value1 => gn_i
                          , iv_token_name2  => cv_tkn_value
                          , iv_token_value2 => g_ins_data(gn_i).chain_code
                          , iv_token_name3  => cv_tkn_value2
                          , iv_token_value3 => g_ins_data(gn_i).data_type_code
                          , iv_token_name4  => cv_tkn_value3
                          , iv_token_value4 => g_ins_data(gn_i).report_code
                         );
        lv_errbuf  := lv_errmsg;
        -- ���O�o��
        proc_msg_output( cv_prg_name, lv_errbuf );
        -- �I���X�e�[�^�X���ُ�ɐݒ�
        ov_retcode := cv_status_error;
--
      -- ��Ӑ���G���[�ȊO�œo�^�����s�����ꍇ
      WHEN OTHERS THEN
        -- �L�[���ҏW
        xxcos_common_pkg.makeup_key_info(
          ov_errbuf      => lv_errbuf,                 -- �G���[�E���b�Z�[�W
          ov_retcode     => lv_retcode,                -- ���^�[���R�[�h
          ov_errmsg      => lv_errmsg,                 -- ���[�U�E�G���[�E���b�Z�[�W
          ov_key_info    => lv_key_info,               -- �ҏW���ꂽ�L�[���
          iv_item_name1  => cv_line_number,            -- ���ږ���1('�s��')
          iv_data_value1 => gn_i || cv_line_num_cnt    -- �f�[�^�̒l1(�s��)
        );
--
        -- ���b�Z�[�W�o��
        lv_errmsg  := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application
                          , iv_name         => cv_msg_COS_00010
                          , iv_token_name1  => cv_tkn_table_name
                          , iv_token_value1 => cv_report_form_reg_tab
                          , iv_token_name2  => cv_tkn_key_data
                          , iv_token_value2 => lv_key_info
                         );
        lv_errbuf  := lv_errmsg;
        -- ���O�o��
        proc_msg_output( cv_prg_name, lv_errbuf );
        -- �I���X�e�[�^�X���ُ�ɐݒ�
        ov_retcode := cv_status_error;
--
    END;
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
  END ins_rep_form_register;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    in_file_id    IN  NUMBER,       -- 1.�t�@�C��ID
    iv_format     IN  VARCHAR2,     -- 2.�t�H�[�}�b�g�p�^�[��
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    gn_target_cnt       := 0;
    gn_normal_cnt       := 0;
    gn_error_cnt        := 0;
    gn_warn_cnt         := 0;
    gn_get_counter_data := 0;
    gn_error_flag       := 'N';
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============
    -- ��������(A-0)
    -- ===============
    init(
      in_file_id => in_file_id,         -- �t�@�C��ID
      iv_format  => iv_format,          -- �t�H�[�}�b�g�p�^�[��
      ov_errbuf  => lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode => lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg  => lv_errmsg );        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- �G���[�̏ꍇ
    IF ( lv_retcode = cv_status_error ) THEN
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
      ov_errmsg  := lv_errmsg;
      RETURN;
    END IF;
--
    -- ==========================================
    -- �t�@�C���A�b�v���[�hIF�f�[�^�̎擾(A-1)
    -- ==========================================
    get_upload_file_data(
      in_file_id  => in_file_id,         -- �t�@�C��ID
      ov_errbuf   => lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode  => lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg   => lv_errmsg );        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- �G���[�̏ꍇ
    IF ( lv_retcode != cv_status_normal ) THEN
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
      ov_errmsg  := lv_errmsg;
      RETURN;
    END IF;
--
    -- ==========================================
    -- �t�@�C���A�b�v���[�hIF�f�[�^�̍폜(A-2)
    -- ==========================================
    delete_upload_filenit(
      in_file_id => in_file_id,         -- �t�@�C��ID
      ov_errbuf  => lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode => lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg  => lv_errmsg );        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- �G���[�̏ꍇ
    IF ( lv_retcode = cv_status_error ) THEN
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
      ov_errmsg  := lv_errmsg;
      RETURN;
    END IF;
--
    -- �R�~�b�g���s
    COMMIT;
--
    -- ===============
    -- ��������(A-3)
    -- ===============
    init_2(
      in_file_id => in_file_id,         -- �t�@�C��ID
      iv_format  => iv_format,          -- �t�H�[�}�b�g�p�^�[��
      ov_errbuf  => lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode => lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg  => lv_errmsg );        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- �G���[�̏ꍇ
    IF ( lv_retcode = cv_status_error ) THEN
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
      ov_errmsg  := lv_errmsg;
      RETURN;
    END IF;
--
  -- ���[�v����
  <<main_loop>>
  FOR gn_i IN 2 .. gn_get_counter_data LOOP
    -- ===========================================
    -- �l����`�Ǘ��䒠�f�[�^�̍��ڕ�������(A-4)
    -- ===========================================
    divide_register_data(
      in_index   => gn_i,               -- �C���f�b�N�X
      ov_errbuf  => lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode => lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg  => lv_errmsg );        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- ���^�[���R�[�h������̏ꍇ�̂݁A�ȉ��̏��������s
      IF ( lv_retcode = cv_status_normal ) THEN
--
        -- =====================
        -- ���ڃ`�F�b�N(A-5)
        -- =====================
        check_validate_item(
          in_index   => gn_i,               -- �C���f�b�N�X
          ov_errbuf  => lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
          ov_retcode => lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
          ov_errmsg  => lv_errmsg );        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        -- �G���[�̏ꍇ
        IF ( lv_retcode = cv_status_error ) THEN
          gn_error_flag := cv_error_flag_y;  -- �G���[�t���O�uY�v��ݒ�
          ov_errbuf     := lv_errbuf;
          ov_retcode    := lv_retcode;
          ov_errmsg     := lv_errmsg;
        END IF;
--
        -- ���^�[���R�[�h������̏ꍇ�̂݁A�ȉ��̏��������s
        IF ( lv_retcode = cv_status_normal ) THEN
--
          -- ========================================
          -- �l����`�Ǘ��䒠�}�X�^�o�^����(A-6)
          -- ========================================
          ins_rep_form_register(
            ov_errbuf  => lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
            ov_retcode => lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
            ov_errmsg  => lv_errmsg );        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
          -- �G���[�̏ꍇ
          IF ( lv_retcode = cv_status_error ) THEN
            gn_error_flag := cv_error_flag_y;  -- �G���[�t���O�uY�v��ݒ�
            ov_errbuf     := lv_errbuf;
            ov_retcode    := lv_retcode;
            ov_errmsg     := lv_errmsg;
          END IF;
--
        END IF;
      -- ���^�[���R�[�h������ȊO�̏ꍇ
      ELSE
        gn_error_flag := cv_error_flag_y;  -- �G���[�t���O�uY�v��ݒ�
        ov_errbuf     := lv_errbuf;
        ov_retcode    := lv_retcode;
        ov_errmsg     := lv_errmsg;
--
      END IF;
--
    END LOOP main_loop;
--
    -- �G���[���Ȃ��ꍇ�A�R�~�b�g�����s
    IF ( gn_error_flag != cv_error_flag_y ) THEN
      COMMIT;
--
    -- �G���[������ꍇ�A���[���o�b�N�����s
    ELSE
      ROLLBACK;
--
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
    in_file_id    IN  NUMBER,        -- 1.�t�@�C��ID
    iv_format     IN  VARCHAR2       -- 2.�t�H�[�}�b�g�p�^�[��
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
       in_file_id     -- 1.�t�@�C��ID
      ,iv_format      -- 2.�t�H�[�}�b�g�p�^�[��
      ,lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );    
--
    --�G���[�o�́u�x���v���umain�Ń��b�Z�[�W���o�́v����v���̂���ꍇ
    IF (lv_retcode != cv_status_normal) THEN
-- 2009/02/19 T.Nakamura Ver.1.1 mod start
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
-- 2009/02/19 T.Nakamura Ver.1.1 mod end
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
      gn_normal_cnt := 0;
      gn_error_cnt  := gn_target_cnt;
-- 2009/02/12 T.Nakamura Ver.1.1 mod start
--    END IF;
--    --
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
    IF ( lv_retcode = cv_status_normal ) THEN
      gn_normal_cnt := gn_target_cnt;
    END IF;
    --
    gv_out_msg    := xxccp_common_pkg.get_msg(
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
    gv_out_msg   := xxccp_common_pkg.get_msg(
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
END XXCOS014A08C;
/
