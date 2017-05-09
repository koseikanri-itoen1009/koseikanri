CREATE OR REPLACE PACKAGE BODY APPS.XXCOS003A08C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2017. All rights reserved.
 *
 * Package Name     : XXCOS003A08C (body)
 * Description      : CSV�f�[�^�A�b�v���[�h�i�������i�\�j
 * MD.050           : CSV�f�[�^�A�b�v���[�h�i�������i�\�j MD050_COS_003_A08
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������                      (A-1)
 *  get_if_data            �t�@�C���A�b�v���[�hIF�擾    (A-2)
 *  item_split             ���ڕ�������                  (A-3)
 *  item_check             ���ڃ`�F�b�N                  (A-4)
 *  ins_work_table         �ꎞ�\�o�^����                (A-5)
 *  data_insert            �������i�\���f����            (A-6)
 *                         �I������                      (A-7)
 * ---------------------- ----------------------------------------------------------
 *  submain                �T�u���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 * ---------------------- ----------------------------------------------------------
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2017/04/14    1.0   S.Yamashita      �V�K�쐬
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
  gn_target_cnt    NUMBER;                    -- �Ώی���
  gn_normal_cnt    NUMBER;                    -- ���팏��
  gn_error_cnt     NUMBER;                    -- �G���[����
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
  --*** �����Ώۃf�[�^���b�N��O ***
  global_data_lock_expt          EXCEPTION;
  PRAGMA EXCEPTION_INIT( global_data_lock_expt, -54 );
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  --�v���O��������
  cv_pkg_name                    CONSTANT VARCHAR2(128) := 'XXCOS003A08C';      -- �p�b�P�[�W��
  --�A�v���P�[�V�����Z�k��
  ct_xxcos_appl_short_name       CONSTANT fnd_application.application_short_name%TYPE  := 'XXCOS'; -- �̕��Z�k�A�v����
  ct_xxccp_appl_short_name       CONSTANT fnd_application.application_short_name%TYPE  := 'XXCCP'; -- ����
  --�v���t�@�C��
  ct_prof_org_id                 CONSTANT fnd_profile_options.profile_option_name%TYPE := 'ORG_ID';                    -- �c�ƒP��
  ct_inv_org_code                CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOI1_ORGANIZATION_CODE';  -- �݌ɑg�D�R�[�h
  ct_prof_all_spl_enable_flg     CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_ALL_SPL_ENABLE_FLG'; -- �������i�\�S���_�L���t���O
  --�N�C�b�N�R�[�h�^�C�v
  ct_lookup_type_cust_status     CONSTANT fnd_lookup_values.lookup_code%TYPE := 'XXCOS1_CUS_STATUS_MST_001_A01';      -- �ڋq�X�e�[�^�X�`�F�b�N�p
  ct_lookup_type_upload_name     CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCCP1_FILE_UPLOAD_OBJ';             -- �t�@�C���A�b�v���[�h���}�X�^
  --�N�C�b�N�R�[�h
  cv_lookup_code_a01             CONSTANT VARCHAR2(30)  := 'XXCOS_001_A01_%';                 -- �ڋq�X�e�[�^�X�`�F�b�N�p
  ct_lang                        CONSTANT fnd_lookup_values.language%TYPE := USERENV('LANG'); -- ����R�[�h
  --������
  cv_str_file_id                 CONSTANT VARCHAR2(128) := 'FILE_ID';             -- FILE_ID
  cv_format                      CONSTANT VARCHAR2(10)  := 'FM00000';             -- �sNo�o��
--
  cv_c_kanma                     CONSTANT VARCHAR2(1)   := ',';                   -- �J���}
  cn_c_header                    CONSTANT NUMBER        := 8;                     -- ���ڐ�
--
  cn_proc_kbn                    CONSTANT NUMBER        := 1;                     -- �����敪
  cn_cust_code                   CONSTANT NUMBER        := 2;                     -- �ڋq�R�[�h
  cn_cust_name                   CONSTANT NUMBER        := 3;                     -- �ڋq��
  cn_item_code                   CONSTANT NUMBER        := 4;                     -- �i�ڃR�[�h
  cn_item_name                   CONSTANT NUMBER        := 5;                     -- �i�ږ�
  cn_price                       CONSTANT NUMBER        := 6;                     -- ���i
  cn_date_from                   CONSTANT NUMBER        := 7;                     -- ����(From)
  cn_date_to                     CONSTANT NUMBER        := 8;                     -- ����(To)
  cn_cust_id                     CONSTANT NUMBER        := 9;                     -- �ڋqID
  cn_item_id                     CONSTANT NUMBER        := 10;                    -- �i��ID
--
  cv_y                           CONSTANT VARCHAR2(10)  := 'Y';                   -- �ėp�FY
  cv_n                           CONSTANT VARCHAR2(10)  := 'N';                   -- �ėp�FN
  cv_i                           CONSTANT VARCHAR2(10)  := 'I';                   -- �ėp�FI(�o�^)
  cv_d                           CONSTANT VARCHAR2(10)  := 'D';                   -- �ėp�FD(�폜)
--
  --���b�Z�[�W
  ct_msg_cos_00012   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00012'; -- �f�[�^�폜�G���[���b�Z�[�W
  ct_msg_cos_00014   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00014'; -- �Ɩ����t�擾�G���[
  ct_msg_cos_11289   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-11289'; -- �t�H�[�}�b�g�p�^�[�����b�Z�[�W
  ct_msg_cos_11293   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-11293'; -- �t�@�C���A�b�v���[�h���̎擾�G���[
  ct_msg_cos_11294   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-11294'; -- CSV�t�@�C�����擾�G���[
  ct_msg_cos_00001   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00001'; -- ���b�N�G���[
  ct_msg_cos_11290   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-11290'; -- CSV�t�@�C�������b�Z�[�W
  ct_msg_cos_00004   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00004'; -- �v���t�@�C���擾�G���[
  ct_msg_cos_10024   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10024'; -- �݌ɑg�DID�擾�G���[���b�Z�[�W
  ct_msg_cos_00013   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00013'; -- �f�[�^���o�G���[���b�Z�[�W
  ct_msg_cos_00003   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00003'; -- �Ώۃf�[�^�����G���[
  ct_msg_cos_11295   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-11295'; -- �t�@�C�����R�[�h�s��v�G���[���b�Z�[�W
  ct_msg_cos_15151   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15151'; -- �K�{�`�F�b�N�G���[
  ct_msg_cos_15153   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15153'; -- ���i���ݒ�G���[
  ct_msg_cos_15154   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15154'; -- �ڋq�R�[�h�s���G���[
  ct_msg_cos_15155   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15155'; -- �ڋq�X�e�[�^�X�s���G���[
  ct_msg_cos_15156   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15156'; -- �ڋq�敪�s���G���[
  ct_msg_cos_15157   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15157'; -- �i�ڃR�[�h�s���G���[
  ct_msg_cos_15158   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15158'; -- �ڋq�Z�L�����e�B�G���[
  ct_msg_cos_15159   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15159'; -- ���t�t�]�G���[
  ct_msg_cos_15160   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15160'; -- �ꎞ�\�o�^�G���[
  ct_msg_cos_15161   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15161'; -- �����敪�E���ԏd���G���[
  ct_msg_cos_15162   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15162'; -- �������i�\�폜�G���[
  ct_msg_cos_15163   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15163'; -- �������i�\�o�^�G���[
  ct_msg_cos_15164   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15164'; -- �폜�ΏۂȂ��G���[
  ct_msg_cos_15165   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15165'; -- �������i�\�o�^�σG���[
  ct_msg_cos_15166   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15166'; -- �����敪�G���[
  ct_msg_cos_15167   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15167'; -- ���l�`���G���[
  ct_msg_cos_15168   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15168'; -- �������i�\�ڋq�o�^�σG���[
  ct_msg_cos_15169   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15169'; -- ���i��񖢐ݒ背�R�[�h�o�^�σG���[
  ct_msg_cos_15170   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15170'; -- ���t�`���G���[
  --���b�Z�[�W������
  ct_msg_cos_11282   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-11282'; -- �t�@�C���A�b�v���[�hIF(���b�Z�[�W������)
  ct_msg_cos_15152   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15152'; -- �����敪(���b�Z�[�W������)
  ct_msg_cos_00053   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00053'; -- �ڋq�R�[�h(���b�Z�[�W������)
  --�g�[�N��
  cv_tkn_profile                 CONSTANT VARCHAR2(512) := 'PROFILE';            -- �v���t�@�C����
  cv_tkn_table                   CONSTANT VARCHAR2(512) := 'TABLE';              -- �e�[�u����
  cv_tkn_key_data                CONSTANT VARCHAR2(512) := 'KEY_DATA';           -- �L�[���e���R�����g
  cv_tkn_proc_kbn                CONSTANT VARCHAR2(512) := 'PROC_KBN';           -- �����敪
  cv_tkn_line_no                 CONSTANT VARCHAR2(512) := 'LINE_NO';            -- �s�ԍ�
  cv_tkn_item                    CONSTANT VARCHAR2(512) := 'ITEM';               -- ����
  cv_tkn_item_code               CONSTANT VARCHAR2(512) := 'ITEM_CODE';          -- �i�ڃR�[�h
  cv_tkn_date_from               CONSTANT VARCHAR2(512) := 'DATE_FROM';          -- ����(From)
  cv_tkn_date_to                 CONSTANT VARCHAR2(512) := 'DATE_TO';            -- ����(To)
  cv_tkn_price                   CONSTANT VARCHAR2(512) := 'PRICE';              -- ���i
  cv_tkn_cust_code               CONSTANT VARCHAR2(512) := 'CUST_CODE';          -- �ڋq�R�[�h
  cv_tkn_cust_status             CONSTANT VARCHAR2(512) := 'CUST_STATUS';        -- �ڋq�X�e�[�^�X
  cv_tkn_table_name              CONSTANT VARCHAR2(512) := 'TABLE_NAME';         -- �e�[�u����
  cv_tkn_err_msg                 CONSTANT VARCHAR2(512) := 'ERR_MSG';            -- �G���[���b�Z�[�W
  cv_tkn_data                    CONSTANT VARCHAR2(512) := 'DATA';               -- ���R�[�h�f�[�^
  cv_tkn_param1                  CONSTANT VARCHAR2(512) := 'PARAM1';             -- �p�����[�^
  cv_tkn_param2                  CONSTANT VARCHAR2(512) := 'PARAM2';             -- �p�����[�^
  cv_tkn_param3                  CONSTANT VARCHAR2(512) := 'PARAM3';             -- �p�����[�^
  cv_tkn_param4                  CONSTANT VARCHAR2(512) := 'PARAM4';             -- �p�����[�^
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
    -- BLOB�^
  g_upload_if_tab   xxccp_common_pkg2.g_file_data_tbl;
  --
  TYPE g_var1_ttype IS TABLE OF VARCHAR(32767) INDEX BY BINARY_INTEGER;
  TYPE g_var2_ttype IS TABLE OF g_var1_ttype INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_process_date                 DATE;                                               -- �Ɩ����t
  gv_inv_org_code                 VARCHAR2(128);                                      -- �݌ɑg�D�R�[�h
  gn_org_id                       NUMBER;                                             -- �c�ƒP��
  gn_inv_org_id                   NUMBER;                                             -- �݌ɑg�DID
  gv_all_base_flg                 VARCHAR2(1);                                        -- �������i�\�S���_�L���t���O
  gn_get_counter_data             NUMBER;                                             -- �f�[�^��
  --
  g_item_work_tab                 g_var2_ttype;   -- �������i�\�f�[�^(����������)
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    in_file_id    IN  NUMBER    -- FILE_ID
   ,iv_get_format IN  VARCHAR2  -- ���̓t�H�[�}�b�g�p�^�[��
   ,ov_errbuf     OUT NOCOPY VARCHAR2  -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT NOCOPY VARCHAR2  -- 2.���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT NOCOPY VARCHAR2  -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- *** ���[�J���ϐ� ***
    lt_meaning               fnd_lookup_values.meaning%TYPE;             -- �t�@�C���A�b�v���[�h����
    lt_csv_file_name         xxccp_mrp_file_ul_interface.file_name%TYPE; -- CSV�t�@�C������
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
    --==================================
    --  �Ɩ����t�擾
    --==================================
    gd_process_date := TRUNC( xxccp_common_pkg2.get_process_date );
    IF ( gd_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name
                    ,iv_name         => ct_msg_cos_00014   -- �Ɩ����t�擾�G���[
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- �p�����[�^�o��
    --==================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                   iv_application   => ct_xxcos_appl_short_name
                  ,iv_name          => ct_msg_cos_11289        -- �t�H�[�}�b�g�p�^�[�����b�Z�[�W
                  ,iv_token_name1   => cv_tkn_param1           -- �p�����[�^�P
                  ,iv_token_value1  => TO_CHAR( in_file_id )   -- �t�@�C��ID
                  ,iv_token_name2   => cv_tkn_param2           -- �p�����[�^�Q
                  ,iv_token_value2  => iv_get_format           -- �t�H�[�}�b�g�p�^�[��
                  );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
     ,buff   => gv_out_msg
    );
--
    --==================================
    -- �t�@�C���A�b�v���[�h���̎擾
    --==================================
    BEGIN
      SELECT flv.meaning AS meaning
      INTO   lt_meaning
      FROM   fnd_lookup_values flv
      WHERE  flv.lookup_type    = ct_lookup_type_upload_name
      AND    flv.lookup_code    = iv_get_format
      AND    flv.enabled_flag   = cv_y
      AND    flv.language       = ct_lang
      AND  NVL(flv.start_date_active, gd_process_date) <= gd_process_date
      AND  NVL(flv.end_date_active, gd_process_date)   >= gd_process_date
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => ct_xxcos_appl_short_name
                      ,iv_name         => ct_msg_cos_11293   -- �t�@�C���A�b�v���[�h���̎擾�G���[
                      ,iv_token_name1  => cv_tkn_key_data
                      ,iv_token_value1 => iv_get_format
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --==================================
    -- CSV�t�@�C�����̎擾(���b�N�擾)
    --==================================
    BEGIN
      SELECT xmfui.file_name AS file_name
      INTO   lt_csv_file_name
      FROM   xxccp_mrp_file_ul_interface  xmfui
      WHERE  xmfui.file_id = in_file_id
      FOR UPDATE NOWAIT
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => ct_xxcos_appl_short_name
                      ,iv_name         => ct_msg_cos_11294   -- CSV�t�@�C�����擾�G���[
                      ,iv_token_name1  => cv_tkn_key_data
                      ,iv_token_value1 => TO_CHAR( in_file_id )
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN global_data_lock_expt THEN
        -- ���b�N�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => ct_xxcos_appl_short_name
                      ,iv_name         => ct_msg_cos_00001     -- ���b�N�G���[
                      ,iv_token_name1  => cv_tkn_table
                      ,iv_token_value1 => ct_msg_cos_11282
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --==================================
    -- �t�@�C�����̏o��
    --==================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application   => ct_xxcos_appl_short_name
                   ,iv_name          => ct_msg_cos_11290         -- CSV�t�@�C�������b�Z�[�W
                   ,iv_token_name1   => cv_tkn_param3            -- �t�@�C���A�b�v���[�h����(���b�Z�[�W������)
                   ,iv_token_value1  => lt_meaning               -- �t�@�C���A�b�v���[�h����
                   ,iv_token_name2   => cv_tkn_param4            -- CSV�t�@�C����(���b�Z�[�W������)
                   ,iv_token_value2  => lt_csv_file_name         -- CSV�t�@�C����
                  );
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
    --==================================
    -- �c�ƒP�ʂ̎擾
    --==================================
    gn_org_id := FND_PROFILE.VALUE( ct_prof_org_id );
    IF ( gn_org_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name
                    ,iv_name         => ct_msg_cos_00004   -- �v���t�@�C���擾�G���[
                    ,iv_token_name1  => cv_tkn_profile
                    ,iv_token_value1 => ct_prof_org_id
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- XXCOI:�݌ɑg�D�R�[�h�̎擾
    --==================================
    gv_inv_org_code := FND_PROFILE.VALUE( ct_inv_org_code );
    IF ( gv_inv_org_code IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name
                    ,iv_name         => ct_msg_cos_00004   -- �v���t�@�C���擾�G���[
                    ,iv_token_name1  => cv_tkn_profile
                    ,iv_token_value1 => ct_inv_org_code
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- �݌ɑg�DID�̎擾
    --==================================
    gn_inv_org_id := xxcoi_common_pkg.get_organization_id(
                             iv_organization_code => gv_inv_org_code
                           );
    IF ( gn_inv_org_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name
                    ,iv_name         => ct_msg_cos_10024   -- �݌ɑg�DID�擾�G���[���b�Z�[�W
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- XXCOS:�������i�\�S���_�L���t���O�̎擾
    --==================================
    gv_all_base_flg := FND_PROFILE.VALUE( ct_prof_all_spl_enable_flg );
    IF ( gv_all_base_flg IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name
                    ,iv_name         => ct_msg_cos_00004   -- �v���t�@�C���擾�G���[
                    ,iv_token_name1  => cv_tkn_profile
                    ,iv_token_value1 => ct_prof_all_spl_enable_flg
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
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
   * Procedure Name   : get_if_data
   * Description      : �t�@�C���A�b�v���[�hIF�擾(A-2)
   ***********************************************************************************/
  PROCEDURE get_if_data (
    in_file_id          IN  NUMBER          -- file_id
   ,ov_errbuf           OUT NOCOPY VARCHAR2 -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode          OUT NOCOPY VARCHAR2 -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg           OUT NOCOPY VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_if_data'; -- �v���O������
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
    lv_key_info               VARCHAR2(5000); -- key���
--
    -- *** ���[�J���E�J�[�\�� ***
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
    --==================================
    -- �������i�\�f�[�^�擾
    --==================================
    xxccp_common_pkg2.blob_to_varchar2(
      in_file_id   => in_file_id         -- file_id
     ,ov_file_data => g_upload_if_tab    -- �������i�\�f�[�^(�z��^)
     ,ov_errbuf    => lv_errbuf          -- �G���[�E���b�Z�[�W            --# �Œ� #
     ,ov_retcode   => lv_retcode         -- ���^�[���E�R�[�h              --# �Œ� #
     ,ov_errmsg    => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
    -- �G���[�̏ꍇ
    IF ( lv_retcode = cv_status_error ) THEN
      --�L�[���
      xxcos_common_pkg.makeup_key_info(
        ov_errbuf      => lv_errbuf      -- �G���[�E���b�Z�[�W
       ,ov_retcode     => lv_retcode     -- ���^�[���R�[�h
       ,ov_errmsg      => lv_errmsg      -- ���[�U�E�G���[�E���b�Z�[�W
       ,ov_key_info    => lv_key_info    -- �ҏW���ꂽ�L�[���
       ,iv_item_name1  => cv_str_file_id
       ,iv_data_value1 => TO_CHAR( in_file_id )
      );
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name
                    ,iv_name         => ct_msg_cos_00013   -- �f�[�^���o�G���[���b�Z�[�W
                    ,iv_token_name1  => cv_tkn_table_name
                    ,iv_token_value1 => ct_msg_cos_11282   -- �t�@�C���A�b�v���[�hIF(���b�Z�[�W������)
                    ,iv_token_name2  => cv_tkn_key_data
                    ,iv_token_value2 => lv_key_info
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- �f�[�^�����̐ݒ�
    --==================================
    gn_get_counter_data := g_upload_if_tab.COUNT;
    gn_target_cnt       := g_upload_if_tab.COUNT - 1;
--
    --==================================
    -- �t�@�C���A�b�v���[�hIF�f�[�^�폜����
    --==================================
    BEGIN
      DELETE FROM xxccp_mrp_file_ul_interface xmfui
      WHERE xmfui.file_id = in_file_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => ct_xxcos_appl_short_name
                      ,iv_name         => ct_msg_cos_00012   -- �f�[�^�폜�G���[���b�Z�[�W
                      ,iv_token_name1  => cv_tkn_table_name
                      ,iv_token_value1 => ct_msg_cos_11282   -- �t�@�C���A�b�v���[�hIF(���b�Z�[�W������)
                      ,iv_token_name2  => cv_tkn_key_data
                      ,iv_token_value2 => NULL
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
  COMMIT;
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
  END get_if_data;
--
  /**********************************************************************************
   * Procedure Name   : item_split
   * Description      : ���ڕ�������(A-3)
   ***********************************************************************************/
  PROCEDURE item_split(
    ov_errbuf         OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode        OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg         OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'item_split'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    -- *** ���[�J���E�J�[�\�� ***
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
    -- �f�[�^�擾���[�v
    <<get_if_row_loop>>
    FOR i IN 2 .. gn_get_counter_data LOOP
    --
      --==================================
      -- ���ڐ��`�F�b�N
      --==================================
      -- �J���}�̐������ڐ�-1�ł��邱�Ƃ��m�F
      IF ( (LENGTH( g_upload_if_tab(i) ) - LENGTH( REPLACE( g_upload_if_tab(i), cv_c_kanma, NULL ))) <> ( cn_c_header - 1 ) ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => ct_xxcos_appl_short_name
                      ,iv_name         => ct_msg_cos_11295  -- �t�@�C�����R�[�h�s��v�G���[���b�Z�[�W
                      ,iv_token_name1  => cv_tkn_data
                      ,iv_token_value1 => g_upload_if_tab(i)
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
      --�J�����������[�v
      <<get_if_col_loop>>
      FOR j IN 1 .. cn_c_header LOOP
        --==================================
        -- ���ڕ���
        --==================================
        g_item_work_tab(i)(j) := xxccp_common_pkg.char_delim_partition(
                                   iv_char     => g_upload_if_tab(i)
                                  ,iv_delim    => cv_c_kanma
                                  ,in_part_num => j
                                 );
      END LOOP get_if_col_loop;
--
    END LOOP get_if_row_loop;
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
  END item_split;
--
  /**********************************************************************************
   * Procedure Name   : item_check
   * Description      : ���ڃ`�F�b�N(A-4)
   ***********************************************************************************/
  PROCEDURE item_check(
    in_cnt                  IN  NUMBER   -- ���[�v�J�E���^
   ,ov_errbuf               OUT NOCOPY VARCHAR2 -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode              OUT NOCOPY VARCHAR2 -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg               OUT NOCOPY VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- *** ���[�J���ϐ� ***
    lv_status            VARCHAR2(1);      -- �I���X�e�[�^�X
    ln_cnt               NUMBER;           -- ����
    ln_number            NUMBER;           -- ���l�`�F�b�N�p
    ld_date              DATE;             -- ���t�`�F�b�N�p
    lt_item_code         mtl_system_items_b.segment1%TYPE;      -- �i�ڃR�[�h
--
    -- *** ���[�J���E�J�[�\�� ***
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
    lv_status  := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ������
    ln_cnt       := 0;
    ln_number    := 0;
    ld_date      := NULL;
    lt_item_code := NULL;
--
    --===============================
    -- �K�{�`�F�b�N
    --===============================
    -- �����敪
    IF ( g_item_work_tab(in_cnt)(cn_proc_kbn) IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => ct_xxcos_appl_short_name
                    ,iv_name          => ct_msg_cos_15151  -- �K�{�`�F�b�N�G���[
                    ,iv_token_name1   => cv_tkn_line_no
                    ,iv_token_value1  => TO_CHAR( in_cnt, cv_format ) -- �sNo
                    ,iv_token_name2   => cv_tkn_item
                    ,iv_token_value2  => ct_msg_cos_15152             -- �����敪(���b�Z�[�W������)
                   );
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => lv_errmsg
      );
      lv_status := cv_status_warn;
    END IF;
--
    -- �ڋq�R�[�h
    IF ( g_item_work_tab(in_cnt)(cn_cust_code) IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => ct_xxcos_appl_short_name
                    ,iv_name          => ct_msg_cos_15151  -- �K�{�`�F�b�N�G���[
                    ,iv_token_name1   => cv_tkn_line_no
                    ,iv_token_value1  => TO_CHAR( in_cnt, cv_format ) -- �sNo
                    ,iv_token_name2   => cv_tkn_item
                    ,iv_token_value2  => ct_msg_cos_00053             -- �ڋq�R�[�h(���b�Z�[�W������)
                   );
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => lv_errmsg
      );
      lv_status := cv_status_warn;
    END IF;
--
    -- ���i���
    -- ���i��񂪑S��NULL�A�܂��͑S�Đݒ肳��Ă���ꍇ�̂ݐ���Ƃ���
    IF ( (  g_item_work_tab(in_cnt)(cn_item_code)  IS NULL   -- �i�ڃR�[�h
        AND g_item_work_tab(in_cnt)(cn_date_from)  IS NULL   -- ����(From)
        AND g_item_work_tab(in_cnt)(cn_date_to)    IS NULL   -- ����(To)
        AND g_item_work_tab(in_cnt)(cn_price)      IS NULL   -- ���i
         )
      OR
         (  g_item_work_tab(in_cnt)(cn_item_code) IS NOT NULL   -- �i�ڃR�[�h
        AND g_item_work_tab(in_cnt)(cn_date_from) IS NOT NULL   -- ����(From)
        AND g_item_work_tab(in_cnt)(cn_date_to)   IS NOT NULL   -- ����(To)
        AND g_item_work_tab(in_cnt)(cn_price)     IS NOT NULL   -- ���i
         )
    )
    THEN
      NULL;
--
    -- ���i���̈ꕔ���ݒ肳��Ă���ꍇ
    ELSE
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => ct_xxcos_appl_short_name
                    ,iv_name          => ct_msg_cos_15153 -- ���i���ݒ�G���[
                    ,iv_token_name1   => cv_tkn_line_no
                    ,iv_token_value1  => TO_CHAR( in_cnt, cv_format )          -- �sNo
                    ,iv_token_name2   => cv_tkn_cust_code
                    ,iv_token_value2  => g_item_work_tab(in_cnt)(cn_cust_code) -- �ڋq�R�[�h
                    ,iv_token_name3   => cv_tkn_item_code
                    ,iv_token_value3  => g_item_work_tab(in_cnt)(cn_item_code) -- �i�ڃR�[�h
                    ,iv_token_name4   => cv_tkn_price
                    ,iv_token_value4  => g_item_work_tab(in_cnt)(cn_price)     -- ���i
                    ,iv_token_name5   => cv_tkn_date_from
                    ,iv_token_value5  => g_item_work_tab(in_cnt)(cn_date_from) -- ����(From)
                    ,iv_token_name6   => cv_tkn_date_to
                    ,iv_token_value6  => g_item_work_tab(in_cnt)(cn_date_to)   -- ����(To)

                   );
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => lv_errmsg
      );
      lv_status := cv_status_warn;
    END IF;
--
    -- �����敪���ݒ肳��Ă���ꍇ
    IF ( g_item_work_tab(in_cnt)(cn_proc_kbn) IS NOT NULL ) THEN
      --===============================
      -- �����敪�`�F�b�N
      --===============================
      -- I:�o�^ D:�폜 �ȊO�̏ꍇ�̓G���[
      IF ( g_item_work_tab(in_cnt)(cn_proc_kbn) NOT IN (cv_i, cv_d) ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => ct_xxcos_appl_short_name
                      ,iv_name          => ct_msg_cos_15166 -- �����敪�G���[
                      ,iv_token_name1   => cv_tkn_line_no
                      ,iv_token_value1  => TO_CHAR( in_cnt, cv_format ) -- �sNo
                      ,iv_token_name2   => cv_tkn_proc_kbn
                      ,iv_token_value2  => g_item_work_tab(in_cnt)(cn_proc_kbn) -- �����敪
                     );
        FND_FILE.PUT_LINE(
          which => FND_FILE.OUTPUT
         ,buff  => lv_errmsg
        );
        lv_status := cv_status_warn;
      END IF;
    END IF;
--
    -- �ڋq�R�[�h���ݒ肳��Ă���ꍇ
    IF ( g_item_work_tab(in_cnt)(cn_cust_code) IS NOT NULL ) THEN
      --===============================
      -- �ڋq�R�[�h�����`�F�b�N
      --===============================
      IF ( LENGTHB(g_item_work_tab(in_cnt)(cn_cust_code)) <> 9 ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => ct_xxcos_appl_short_name
                      ,iv_name          => ct_msg_cos_15154 -- �ڋq�R�[�h�s���G���[
                      ,iv_token_name1   => cv_tkn_line_no
                      ,iv_token_value1  => TO_CHAR( in_cnt, cv_format ) -- �sNo
                      ,iv_token_name2   => cv_tkn_cust_code
                      ,iv_token_value2  => g_item_work_tab(in_cnt)(cn_cust_code) -- �ڋq�R�[�h
                     );
        FND_FILE.PUT_LINE(
          which => FND_FILE.OUTPUT
         ,buff  => lv_errmsg
        );
        lv_status := cv_status_warn;
      END IF;
--
    END IF;
--
    -- �i�ڃR�[�h���ݒ肳��Ă���ꍇ
    IF ( g_item_work_tab(in_cnt)(cn_item_code) IS NOT NULL ) THEN
      --===============================
      -- �i�ڃ}�X�^���݃`�F�b�N
      --===============================
      BEGIN
        SELECT  msib.segment1                     AS item_code
               ,TO_CHAR( msib.inventory_item_id ) AS item_id
        INTO    lt_item_code
               ,g_item_work_tab(in_cnt)(cn_item_id)
        FROM    mtl_system_items_b   msib    -- DISC�i�ڃ}�X�^
        WHERE   msib.organization_id  = gn_inv_org_id
        AND     msib.segment1         = g_item_work_tab(in_cnt)(cn_item_code) -- �i�ڃR�[�h
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => ct_xxcos_appl_short_name
                        ,iv_name          => ct_msg_cos_15157 -- �i�ڃR�[�h�s���G���[
                        ,iv_token_name1   => cv_tkn_line_no
                        ,iv_token_value1  => TO_CHAR( in_cnt, cv_format ) -- �sNo
                        ,iv_token_name2   => cv_tkn_item_code
                        ,iv_token_value2  => g_item_work_tab(in_cnt)(cn_item_code) -- �i�ڃR�[�h
                       );
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT
           ,buff  => lv_errmsg
          );
          lv_status := cv_status_warn;
      END;
    ELSE
      -- �i�ڃR�[�h��NULL�̏ꍇ�́A�i��ID��NULL���Z�b�g
      g_item_work_tab(in_cnt)(cn_item_id) := NULL;
    END IF;
--
    -- ���i���ݒ肳��Ă���ꍇ
    IF (  g_item_work_tab(in_cnt)(cn_price) IS NOT NULL ) THEN
      --===============================
      -- ���l�`���`�F�b�N
      --===============================
      BEGIN
        -- ���l�`���`�F�b�N
        ln_number := TO_NUMBER( g_item_work_tab(in_cnt)(cn_price), 'FM9999.99' );
        -- �͈̓`�F�b�N
        IF ( ln_number <= 0 ) THEN
          RAISE VALUE_ERROR;
        END IF;
      EXCEPTION
        WHEN VALUE_ERROR THEN
          -- ���l�`���G���[
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => ct_xxcos_appl_short_name
                        ,iv_name          => ct_msg_cos_15167  -- ���l�`���G���[
                        ,iv_token_name1   => cv_tkn_line_no
                        ,iv_token_value1  => TO_CHAR( in_cnt, cv_format ) -- �sNo
                        ,iv_token_name2   => cv_tkn_price
                        ,iv_token_value2  => g_item_work_tab(in_cnt)(cn_price) -- ���i
                       );
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT
           ,buff  => lv_errmsg
          );
          lv_status := cv_status_warn;
      END;
--
    END IF;
--
    -- ����(From)�A����(To)���ݒ肳��Ă���ꍇ
    IF (  g_item_work_tab(in_cnt)(cn_date_from) IS NOT NULL
      AND g_item_work_tab(in_cnt)(cn_date_to)   IS NOT NULL )
    THEN
      --===============================
      -- ���t�`���`�F�b�N
      --===============================
      BEGIN
         ld_date := TO_DATE( g_item_work_tab(in_cnt)(cn_date_from), 'YYYY/MM/DD' );
         ld_date := TO_DATE( g_item_work_tab(in_cnt)(cn_date_to)  , 'YYYY/MM/DD' );
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => ct_xxcos_appl_short_name
                        ,iv_name          => ct_msg_cos_15170
                        ,iv_token_name1   => cv_tkn_line_no
                        ,iv_token_value1  => TO_CHAR( in_cnt, cv_format )          -- �sNo
                        ,iv_token_name2   => cv_tkn_date_from
                        ,iv_token_value2  => g_item_work_tab(in_cnt)(cn_date_from) -- ����(From)
                        ,iv_token_name3   => cv_tkn_date_to
                        ,iv_token_value3  => g_item_work_tab(in_cnt)(cn_date_to)   -- ����(To)
                       );
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT
           ,buff  => lv_errmsg
          );
          lv_status := cv_status_warn;
      END;
--
      -- ���t�`���G���[���������Ă��Ȃ��ꍇ
      IF (lv_status = cv_status_normal ) THEN
        --===============================
        -- ���t�t�]�`�F�b�N
        --===============================
        IF ( TO_DATE( g_item_work_tab(in_cnt)(cn_date_from), 'YYYY/MM/DD' )
               > TO_DATE( g_item_work_tab(in_cnt)(cn_date_to), 'YYYY/MM/DD' ) )
        THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => ct_xxcos_appl_short_name
                        ,iv_name          => ct_msg_cos_15159
                        ,iv_token_name1   => cv_tkn_line_no
                        ,iv_token_value1  => TO_CHAR( in_cnt, cv_format )          -- �sNo
                        ,iv_token_name2   => cv_tkn_date_from
                        ,iv_token_value2  => g_item_work_tab(in_cnt)(cn_date_from) -- ����(From)
                        ,iv_token_name3   => cv_tkn_date_to
                        ,iv_token_value3  => g_item_work_tab(in_cnt)(cn_date_to)   -- ����(To)
                       );
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT
           ,buff  => lv_errmsg
          );
          lv_status := cv_status_warn;
        END IF;
      END IF;
    END IF;
--
    IF ( lv_status = cv_status_warn ) THEN
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
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
--
  /**********************************************************************************
   * Procedure Name   : ins_work_table
   * Description      : �ꎞ�\�o�^����(A-5)
   ***********************************************************************************/
  PROCEDURE ins_work_table(
    in_cnt                  IN  NUMBER   -- ���[�v�J�E���^
   ,ov_errbuf               OUT NOCOPY VARCHAR2 -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode              OUT NOCOPY VARCHAR2 -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg               OUT NOCOPY VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_work_table'; -- �v���O������
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
    -- *** ���[�J���E�J�[�\�� ***
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
    --==================================
    -- �ꎞ�\�o�^
    --==================================
    BEGIN
      INSERT INTO xxcos_tmp_sale_plice_lists(
        line_no         -- �sNo
       ,proc_kbn        -- �����敪
       ,customer_code   -- �ڋq�R�[�h
       ,item_id         -- �i��ID
       ,item_code       -- �i�ڃR�[�h
       ,price           -- ���i
       ,date_from       -- ����(From)
       ,date_to         -- ����(To)
      )VALUES(
        in_cnt                                             -- �sNo
       ,g_item_work_tab(in_cnt)(cn_proc_kbn)               -- �����敪
       ,g_item_work_tab(in_cnt)(cn_cust_code)              -- �ڋq�R�[�h
       ,TO_NUMBER( g_item_work_tab(in_cnt)(cn_item_id) )   -- �i��ID
       ,g_item_work_tab(in_cnt)(cn_item_code)              -- �i�ڃR�[�h
       ,TO_NUMBER( g_item_work_tab(in_cnt)(cn_price) )     -- ���i
       ,TO_DATE( g_item_work_tab(in_cnt)(cn_date_from), 'YYYY/MM/DD' ) -- ����(From)
       ,TO_DATE( g_item_work_tab(in_cnt)(cn_date_to)  , 'YYYY/MM/DD' ) -- ����(To)
      );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => ct_xxcos_appl_short_name
                      ,iv_name         => ct_msg_cos_15160   -- �ꎞ�\�o�^�G���[
                      ,iv_token_name1  => cv_tkn_line_no
                      ,iv_token_value1 => TO_CHAR( in_cnt, cv_format ) -- �sNo
                      ,iv_token_name2  => cv_tkn_err_msg
                      ,iv_token_value2 => SQLERRM    -- �G���[���e
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--*********** 2010/02/12 2.0 T.Nakano ADD End   ********** --
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
  END ins_work_table;
--
--
  /**********************************************************************************
   * Procedure Name   : data_insert
   * Description      : �������i�\���f����(A-6)
   ***********************************************************************************/
  PROCEDURE data_insert(
    ov_errbuf         OUT NOCOPY VARCHAR2 -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode        OUT NOCOPY VARCHAR2 -- 2.���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg         OUT NOCOPY VARCHAR2 -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'data_insert'; -- �v���O������
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
    cv_ship_to                VARCHAR2(10) := 'SHIP_TO'; -- �o�א�
    -- *** ���[�J���ϐ� ***
    ln_chk_cnt                NUMBER;          -- �`�F�b�N����
    ln_del_cnt                NUMBER;          -- �폜����
    lv_message                VARCHAR2(32765); -- ���b�Z�[�W
    lv_status                 VARCHAR2(1);     -- �X�e�[�^�X
    lv_pre_status             VARCHAR2(1);     -- �O���R�[�h�X�e�[�^�X
    ln_sale_price_lists_s01   NUMBER;          -- �������i�\�V�[�P���X
    lt_pre_cust_code          hz_cust_accounts.account_number%TYPE;   -- �ڋq�R�[�h(�O���R�[�h)
    lt_customer_id            hz_cust_accounts.cust_account_id%TYPE;  -- �ڋqID
    -- *** ���[�J���E�J�[�\�� ***
--
    -- �������i�\�ꎞ�\�擾�J�[�\��
    CURSOR get_sale_price_lists_cur
    IS
      SELECT xtspl.line_no       AS line_no       -- �sNo
            ,xtspl.proc_kbn      AS proc_kbn      -- �����敪
            ,xtspl.customer_code AS customer_code -- �ڋq�R�[�h
            ,xtspl.item_id       AS item_id       -- �i��ID
            ,xtspl.item_code     AS item_code     -- �i�ڃR�[�h
            ,xtspl.price         AS price         -- ���i
            ,xtspl.date_from     AS date_from     -- ����(From)
            ,xtspl.date_to       AS date_to       -- ����(To)
      FROM   xxcos_tmp_sale_plice_lists  xtspl    -- �������i�\�ꎞ�\
      ORDER BY
             xtspl.proc_kbn      -- �����敪
            ,xtspl.customer_code -- �ڋq�R�[�h
    ;
--
    -- �J�[�\�����R�[�h�^
    get_sale_price_lists_rec  get_sale_price_lists_cur%ROWTYPE;
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
    lv_status  := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �ϐ�������
    lv_pre_status    := cv_status_normal;
    lt_pre_cust_code := NULL;
    lt_customer_id   := NULL;
--
    -- �J�[�\���擾
    <<main_loop>>
    FOR get_sale_price_lists_rec IN get_sale_price_lists_cur LOOP
--
      -- �ϐ�������
      lv_status  := cv_status_normal; -- �X�e�[�^�X
      ln_chk_cnt := 0;  -- �`�F�b�N����
      ln_del_cnt := 0;  -- �폜����
--
      -- 1���R�[�h�ځA�܂��͑O���R�[�h�ƌڋq���قȂ�ꍇ
      IF ( (lt_pre_cust_code IS NULL) OR (lt_pre_cust_code <> get_sale_price_lists_rec.customer_code) ) THEN
        --===============================
        -- �ڋq�}�X�^���݃`�F�b�N
        --===============================
        BEGIN
          SELECT hca.cust_account_id  AS csut_account_id -- �ڋqID
          INTO   lt_customer_id
          FROM   hz_cust_accounts       hca
          WHERE  hca.account_number = get_sale_price_lists_rec.customer_code -- �ڋq�R�[�h
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application   => ct_xxcos_appl_short_name
                          ,iv_name          => ct_msg_cos_15154 -- �ڋq�R�[�h�s���G���[
                          ,iv_token_name1   => cv_tkn_line_no
                          ,iv_token_value1  => TO_CHAR( get_sale_price_lists_rec.line_no, cv_format ) -- �sNo
                          ,iv_token_name2   => cv_tkn_cust_code
                          ,iv_token_value2  => get_sale_price_lists_rec.customer_code -- �ڋq�R�[�h
                         );
            FND_FILE.PUT_LINE(
              which => FND_FILE.OUTPUT
             ,buff  => lv_errmsg
            );
            lv_status := cv_status_warn;
        END;
--
        -- �ڋq�R�[�h��ێ�
        lt_pre_cust_code := get_sale_price_lists_rec.customer_code;
--
        -- �ڋq�G���[���������Ă��Ȃ��ꍇ
        IF ( lv_status = cv_status_normal ) THEN
--
          -- �����敪���uI�F�o�^�v�̏ꍇ
          IF ( get_sale_price_lists_rec.proc_kbn = cv_i ) THEN
            --===============================
            -- �ڋq�X�e�[�^�X�`�F�b�N
            --===============================
            -- �ڋq�X�e�[�^�X�`�F�b�N�p�̃N�C�b�N�R�[�h�ɑ��݂��邩�m�F
            SELECT COUNT (1) AS cnt
            INTO   ln_chk_cnt
            FROM   hz_cust_accounts   hca
                  ,hz_parties         hp
                  ,fnd_lookup_values  flv
            WHERE  hca.party_id       = hp.party_id
            AND    hca.account_number = get_sale_price_lists_rec.customer_code -- �ڋq�R�[�h
            AND    flv.lookup_type    = ct_lookup_type_cust_status
            AND    flv.lookup_code LIKE cv_lookup_code_a01
            AND    flv.language       = ct_lang
            AND    gd_process_date   >= NVL( flv.start_date_active ,gd_process_date )
            AND    gd_process_date   <= NVL( flv.end_date_active   ,gd_process_date )
            AND    flv.enabled_flag   = cv_y
            AND    flv.meaning        = hp.duns_number_c
            ;
--
            IF ( ln_chk_cnt = 0 ) THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application   => ct_xxcos_appl_short_name
                            ,iv_name          => ct_msg_cos_15155 -- �ڋq�X�e�[�^�X�s���G���[
                            ,iv_token_name1   => cv_tkn_line_no
                            ,iv_token_value1  => TO_CHAR( get_sale_price_lists_rec.line_no, cv_format ) -- �sNo
                            ,iv_token_name2   => cv_tkn_cust_code
                            ,iv_token_value2  => get_sale_price_lists_rec.customer_code   -- �ڋq�R�[�h
                           );
              FND_FILE.PUT_LINE(
                which => FND_FILE.OUTPUT
               ,buff  => lv_errmsg
              );
              lv_status := cv_status_warn;
            END IF;
          END IF;
--
          --===============================
          -- �ڋq�敪�`�F�b�N
          --===============================
          ln_chk_cnt := 0;
--
          SELECT COUNT(1) AS cnt
          INTO   ln_chk_cnt
          FROM   hz_cust_accounts hca
                ,hz_cust_acct_sites_all hcas
                ,hz_cust_site_uses_all  hcsu
          WHERE  hcas.cust_account_id   = hca.cust_account_id
          AND    hcas.org_id            = gn_org_id
          AND    hcsu.cust_acct_site_id = hcas.cust_acct_site_id
          AND    hcsu.org_id            = hcas.org_id
          AND    hcsu.site_use_code     = cv_ship_to        -- �o�א�
          AND    hca.account_number     = get_sale_price_lists_rec.customer_code -- �ڋq�R�[�h
          ;
          IF ( ln_chk_cnt = 0 ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application   => ct_xxcos_appl_short_name
                          ,iv_name          => ct_msg_cos_15156 -- �ڋq�敪�s���G���[
                          ,iv_token_name1   => cv_tkn_line_no
                          ,iv_token_value1  => TO_CHAR( get_sale_price_lists_rec.line_no, cv_format ) -- �sNo
                          ,iv_token_name2   => cv_tkn_cust_code
                          ,iv_token_value2  => get_sale_price_lists_rec.customer_code -- �ڋq�R�[�h
                         );
            FND_FILE.PUT_LINE(
              which => FND_FILE.OUTPUT
             ,buff  => lv_errmsg
            );
            lv_status := cv_status_warn;
          END IF;
--
          --===============================
          -- �ڋq�Z�L�����e�B�`�F�b�N
          --===============================
          -- �v���t�@�C���u�������i�\�S���_�L���t���O�v��N�̏ꍇ
          IF ( gv_all_base_flg = cv_n ) THEN
            ln_chk_cnt := 0;
--
            SELECT COUNT(1) AS cnt
            INTO   ln_chk_cnt
            FROM   xxcmm_cust_accounts     xca  -- �ڋq�ǉ����
                  ,xxcos_login_base_info_v xlbi -- ���O�C�����[�U���_�r���[
            WHERE  xca.customer_code = get_sale_price_lists_rec.customer_code
            AND   (   xlbi.base_code = xca.sale_base_code
                   OR xlbi.base_code = xca.delivery_base_code
                   OR xlbi.base_code = xca.sales_head_base_code
                  )
            ;
            IF ( ln_chk_cnt = 0 ) THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application   => ct_xxcos_appl_short_name
                            ,iv_name          => ct_msg_cos_15158 -- �ڋq�Z�L�����e�B�G���[
                            ,iv_token_name1   => cv_tkn_line_no
                            ,iv_token_value1  => TO_CHAR( get_sale_price_lists_rec.line_no, cv_format ) -- �sNo
                            ,iv_token_name2   => cv_tkn_cust_code
                            ,iv_token_value2  => get_sale_price_lists_rec.customer_code -- �ڋq�R�[�h
                           );
              FND_FILE.PUT_LINE(
                which => FND_FILE.OUTPUT
               ,buff  => lv_errmsg
              );
              lv_status := cv_status_warn;
            END IF;
          END IF;
        END IF;
      ELSE
        -- �O���R�[�h�Ɠ���ڋq�̏ꍇ
        IF( lv_pre_status = cv_status_warn ) THEN
          lv_status := cv_status_warn;
        END IF;
      END IF;
--
      -- �ڋq�`�F�b�N�ŃG���[���������Ă��Ȃ��ꍇ
      IF ( lv_status = cv_status_normal ) THEN
        -- �X�e�[�^�X�ݒ�
        lv_pre_status := cv_status_normal;
--
        --==================================
        -- �����敪�E���ԏd���`�F�b�N
        --==================================
        ln_chk_cnt := 0;
--
        IF ( get_sale_price_lists_rec.item_id IS NULL ) THEN
--
          -- ���i���NULL�̏ꍇ�A�����敪�A�ڋq���d������ꍇ�̓G���[
          SELECT COUNT(1) AS cnt
          INTO   ln_chk_cnt
          FROM   xxcos_tmp_sale_plice_lists  xtspl    -- �������i�\�ꎞ�\
          WHERE  xtspl.proc_kbn      = get_sale_price_lists_rec.proc_kbn     -- �����敪
          AND    xtspl.customer_code = get_sale_price_lists_rec.customer_code  -- �ڋq�R�[�h
          ;
        ELSE
          -- ���i���NULL�łȂ��ꍇ
          IF ( get_sale_price_lists_rec.proc_kbn = cv_d ) THEN
            -- �폜�̏ꍇ
            SELECT COUNT(1) AS cnt
            INTO   ln_chk_cnt
            FROM   xxcos_tmp_sale_plice_lists  xtspl    -- �������i�\�ꎞ�\
            WHERE  xtspl.proc_kbn      = get_sale_price_lists_rec.proc_kbn      -- �����敪
            AND    xtspl.customer_code = get_sale_price_lists_rec.customer_code -- �ڋq�R�[�h
            AND    xtspl.item_id       = get_sale_price_lists_rec.item_id       -- �i��ID
            AND    xtspl.date_from     = get_sale_price_lists_rec.date_from     -- ����(From)
            AND    xtspl.date_to       = get_sale_price_lists_rec.date_to       -- ����(To)
            ;
          ELSE
            -- �o�^�̏ꍇ
            SELECT COUNT(1) AS cnt
            INTO   ln_chk_cnt
            FROM   xxcos_tmp_sale_plice_lists  xtspl     -- �������i�\�ꎞ�\
            WHERE  xtspl.proc_kbn      = get_sale_price_lists_rec.proc_kbn      -- �����敪
            AND    xtspl.customer_code = get_sale_price_lists_rec.customer_code -- �ڋq�R�[�h
            AND  ( xtspl.item_id IS NULL                 -- ���i���NULL�̏ꍇ
              OR ( xtspl.item_id IS NOT NULL             -- ���i���NULL�łȂ��ꍇ
                   AND xtspl.item_id = get_sale_price_lists_rec.item_id       -- �i��ID
                   AND (
                         (   get_sale_price_lists_rec.date_from  BETWEEN xtspl.date_from AND xtspl.date_to  -- ����(From)
                          OR get_sale_price_lists_rec.date_to    BETWEEN xtspl.date_from AND xtspl.date_to) -- ����(To)
                      OR (   xtspl.date_from  BETWEEN get_sale_price_lists_rec.date_from AND get_sale_price_lists_rec.date_to  -- ����(From)
                          OR xtspl.date_to    BETWEEN get_sale_price_lists_rec.date_from AND get_sale_price_lists_rec.date_to) -- ����(To)
                       )
                 )
                 )
            ;
          END IF;
        END IF;
--
        -- �d�����R�[�h�����݂���ꍇ
        IF ( ln_chk_cnt <> 1 ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => ct_xxcos_appl_short_name
                        ,iv_name          => ct_msg_cos_15161  -- �����敪�E���ԏd���G���[
                        ,iv_token_name1   => cv_tkn_line_no
                        ,iv_token_value1  => TO_CHAR( get_sale_price_lists_rec.line_no, cv_format ) -- �sNo
                        ,iv_token_name2   => cv_tkn_proc_kbn
                        ,iv_token_value2  => get_sale_price_lists_rec.proc_kbn         -- �����敪
                        ,iv_token_name3   => cv_tkn_cust_code
                        ,iv_token_value3  => get_sale_price_lists_rec.customer_code    -- �ڋq�R�[�h
                        ,iv_token_name4   => cv_tkn_item_code
                        ,iv_token_value4  => get_sale_price_lists_rec.item_code        -- �i�ڃR�[�h
                        ,iv_token_name5   => cv_tkn_price
                        ,iv_token_value5  => TO_CHAR( get_sale_price_lists_rec.price ) -- ���i
                        ,iv_token_name6   => cv_tkn_date_from
                        ,iv_token_value6  => TO_CHAR( get_sale_price_lists_rec.date_from, 'YYYY/MM/DD' ) -- ����(From)
                        ,iv_token_name7   => cv_tkn_date_to
                        ,iv_token_value7  => TO_CHAR( get_sale_price_lists_rec.date_to  , 'YYYY/MM/DD' ) -- ����(To)
                       );
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT
           ,buff  => lv_errmsg
          );
          lv_status := cv_status_warn;
        END IF;
--
        -- �G���[���������Ă��Ȃ��ꍇ
        IF ( lv_status = cv_status_normal ) THEN
          --==================================
          -- �������i�\���f
          --==================================
          -- �폜�̏ꍇ
          IF ( get_sale_price_lists_rec.proc_kbn = cv_d ) THEN
--
            BEGIN
              -- �������i�\�폜
              DELETE FROM xxcos_sale_price_lists xspl  -- �������i�\
              WHERE  lt_customer_id = xspl.customer_id  -- �ڋqID
              AND  ((get_sale_price_lists_rec.item_id IS NULL                 -- ���i���NULL�̏ꍇ
                     AND xspl.item_id           IS NULL  -- �i��ID
                     AND xspl.start_date_active IS NULL  -- ����(From)
                     AND xspl.end_date_active   IS NULL  -- ����(To)
                    )
                OR ( get_sale_price_lists_rec.item_id IS NOT NULL             -- ���i���NULL�łȂ��ꍇ
                     AND get_sale_price_lists_rec.item_id   = xspl.item_id            -- �i��ID
                     AND get_sale_price_lists_rec.date_from = xspl.start_date_active  -- ����(From)
                     AND get_sale_price_lists_rec.date_to   = xspl.end_date_active    -- ����(To)
                   )
                   )
              ;
              -- �폜������ێ�
              ln_del_cnt := SQL%ROWCOUNT;
--
            EXCEPTION
              WHEN OTHERS THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => ct_xxcos_appl_short_name
                              ,iv_name         => ct_msg_cos_15162   -- �������i�\�폜�G���[
                              ,iv_token_name1  => cv_tkn_line_no
                              ,iv_token_value1 => TO_CHAR( get_sale_price_lists_rec.line_no, cv_format ) -- �sNo
                              ,iv_token_name2  => cv_tkn_err_msg
                              ,iv_token_value2 => SQLERRM    -- �G���[���e
                             );
                lv_errbuf := lv_errmsg;
                RAISE global_api_expt;
            END;
--
            -- �폜������0���̏ꍇ
            IF (ln_del_cnt = 0) THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application   => ct_xxcos_appl_short_name
                            ,iv_name          => ct_msg_cos_15164  -- �폜�ΏۂȂ��G���[
                            ,iv_token_name1   => cv_tkn_line_no
                            ,iv_token_value1  => TO_CHAR( get_sale_price_lists_rec.line_no, cv_format ) -- �sNo
                            ,iv_token_name2   => cv_tkn_proc_kbn
                            ,iv_token_value2  => get_sale_price_lists_rec.proc_kbn         -- �����敪
                            ,iv_token_name3   => cv_tkn_cust_code
                            ,iv_token_value3  => get_sale_price_lists_rec.customer_code    -- �ڋq�R�[�h
                            ,iv_token_name4   => cv_tkn_item_code
                            ,iv_token_value4  => get_sale_price_lists_rec.item_code        -- �i�ڃR�[�h
                            ,iv_token_name5   => cv_tkn_price
                            ,iv_token_value5  => TO_CHAR( get_sale_price_lists_rec.price ) -- ���i
                            ,iv_token_name6   => cv_tkn_date_from
                            ,iv_token_value6  => TO_CHAR( get_sale_price_lists_rec.date_from, 'YYYY/MM/DD' ) -- ����(From)
                            ,iv_token_name7   => cv_tkn_date_to
                            ,iv_token_value7  => TO_CHAR( get_sale_price_lists_rec.date_to  , 'YYYY/MM/DD' ) -- ����(To)
                           );
              FND_FILE.PUT_LINE(
                which => FND_FILE.OUTPUT
               ,buff  => lv_errmsg
              );
              lv_status := cv_status_warn;
            END IF;
--
          -- �o�^�̏ꍇ
          ELSE
            --==================================
            -- �������i�\�d���`�F�b�N
            --==================================
            -- ���i���NULL�̏ꍇ
            IF ( get_sale_price_lists_rec.item_id IS NULL ) THEN
              -- ����ڋq�̃��R�[�h�����݂���ꍇ
              SELECT COUNT(1) AS cnt
              INTO   ln_chk_cnt
              FROM   xxcos_sale_price_lists  xspl -- �������i�\
              WHERE  xspl.customer_id = lt_customer_id -- �ڋqID
              ;
--
              IF ( ln_chk_cnt <> 0 ) THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application   => ct_xxcos_appl_short_name
                              ,iv_name          => ct_msg_cos_15168  -- �������i�\�ڋq�o�^�σG���[
                              ,iv_token_name1   => cv_tkn_line_no
                              ,iv_token_value1  => TO_CHAR( get_sale_price_lists_rec.line_no, cv_format ) -- �sNo
                              ,iv_token_name2   => cv_tkn_proc_kbn
                              ,iv_token_value2  => get_sale_price_lists_rec.proc_kbn      -- �����敪
                              ,iv_token_name3   => cv_tkn_cust_code
                              ,iv_token_value3  => get_sale_price_lists_rec.customer_code -- �ڋq�R�[�h
                             );
                FND_FILE.PUT_LINE(
                  which => FND_FILE.OUTPUT
                 ,buff  => lv_errmsg
                );
                lv_status := cv_status_warn;
              END IF;
            ELSE
            -- ���i���NULL�łȂ��ꍇ
              -- ���i���NULL�̃��R�[�h�����ɑ��݂���ꍇ
              SELECT COUNT(1) AS cnt
              INTO   ln_chk_cnt
              FROM   xxcos_sale_price_lists xspl    -- �������i�\
              WHERE  xspl.customer_id = lt_customer_id -- �ڋqID
              AND    xspl.item_id     IS NULL                                -- �i��ID
              ;
--
              IF ( ln_chk_cnt <> 0 ) THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application   => ct_xxcos_appl_short_name
                              ,iv_name          => ct_msg_cos_15169  -- ���i��񖢐ݒ背�R�[�h�o�^�σG���[
                              ,iv_token_name1   => cv_tkn_line_no
                              ,iv_token_value1  => TO_CHAR( get_sale_price_lists_rec.line_no, cv_format ) -- �sNo
                              ,iv_token_name2   => cv_tkn_proc_kbn
                              ,iv_token_value2  => get_sale_price_lists_rec.proc_kbn      -- �����敪
                              ,iv_token_name3   => cv_tkn_cust_code
                              ,iv_token_value3  => get_sale_price_lists_rec.customer_code -- �ڋq�R�[�h
                               );
                FND_FILE.PUT_LINE(
                  which => FND_FILE.OUTPUT
                 ,buff  => lv_errmsg
                );
                lv_status := cv_status_warn;
              END IF;
--
              -- �ϐ�������
              ln_chk_cnt := 0;
--
              -- ���Ԃ��d�����郌�R�[�h�����݂���ꍇ
              SELECT COUNT(1) AS cnt
              INTO   ln_chk_cnt
              FROM   xxcos_sale_price_lists  xspl    -- �������i�\
              WHERE  xspl.customer_id       = lt_customer_id   -- �ڋqID
              AND    xspl.item_id           = get_sale_price_lists_rec.item_id       -- �i��ID
              AND  (
                     (  get_sale_price_lists_rec.date_from BETWEEN xspl.start_date_active AND xspl.end_date_active   -- ����(From)
                     OR get_sale_price_lists_rec.date_to   BETWEEN xspl.start_date_active AND xspl.end_date_active   -- ����(To)
                     )
                 OR  (  xspl.start_date_active BETWEEN get_sale_price_lists_rec.date_from AND get_sale_price_lists_rec.date_to -- ����(From)
                     OR xspl.end_date_active   BETWEEN get_sale_price_lists_rec.date_from AND get_sale_price_lists_rec.date_to  -- ����(To)
                     )
                   )
              ;
--
              IF ( ln_chk_cnt <> 0 ) THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application   => ct_xxcos_appl_short_name
                              ,iv_name          => ct_msg_cos_15165  -- �������i�\�o�^�σG���[
                              ,iv_token_name1   => cv_tkn_line_no
                              ,iv_token_value1  => TO_CHAR( get_sale_price_lists_rec.line_no, cv_format ) -- �sNo
                              ,iv_token_name2   => cv_tkn_proc_kbn
                              ,iv_token_value2  => get_sale_price_lists_rec.proc_kbn         -- �����敪
                              ,iv_token_name3   => cv_tkn_cust_code
                              ,iv_token_value3  => get_sale_price_lists_rec.customer_code    -- �ڋq�R�[�h
                              ,iv_token_name4   => cv_tkn_item_code
                              ,iv_token_value4  => get_sale_price_lists_rec.item_code        -- �i�ڃR�[�h
                              ,iv_token_name5   => cv_tkn_price
                              ,iv_token_value5  => TO_CHAR( get_sale_price_lists_rec.price ) -- ���i
                              ,iv_token_name6   => cv_tkn_date_from
                              ,iv_token_value6  => TO_CHAR( get_sale_price_lists_rec.date_from, 'YYYY/MM/DD' ) -- ����(From)
                              ,iv_token_name7   => cv_tkn_date_to
                              ,iv_token_value7  => TO_CHAR( get_sale_price_lists_rec.date_to  , 'YYYY/MM/DD' ) -- ����(To)
                             );
                FND_FILE.PUT_LINE(
                  which => FND_FILE.OUTPUT
                 ,buff  => lv_errmsg
                );
                lv_status := cv_status_warn;
--
              END IF;
            END IF;
--
            -- �G���[���������Ă��Ȃ��ꍇ
            IF ( lv_status = cv_status_normal ) THEN
--
              BEGIN
                -- �������i�\�o�^
                INSERT INTO xxcos_sale_price_lists(
                  sale_price_list_id     -- �������i�\ID
                 ,customer_id            -- �ڋqID
                 ,item_id                -- �i��ID
                 ,price                  -- ���i
                 ,start_date_active      -- �L���J�n��
                 ,end_date_active        -- �L���I����
                 ,created_by             -- �쐬��
                 ,creation_date          -- �쐬��
                 ,last_updated_by        -- �ŏI�X�V��
                 ,last_update_date       -- �ŏI�X�V��
                 ,last_update_login      -- �ŏI�X�V���O�C��
                 ,request_id             -- �v��ID
                 ,program_application_id -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
                 ,program_id             -- �R���J�����g�E�v���O����ID
                 ,program_update_date    -- �v���O�����X�V��
                )VALUES(
                  xxcos_sale_price_lists_s01.NEXTVAL   -- �������i�\ID
                 ,lt_customer_id                       -- �ڋqID
                 ,get_sale_price_lists_rec.item_id     -- �i��ID
                 ,get_sale_price_lists_rec.price       -- ���i
                 ,get_sale_price_lists_rec.date_from   -- �L���J�n��
                 ,get_sale_price_lists_rec.date_to     -- �L���J�n��
                 ,cn_created_by                        -- �쐬��
                 ,cd_creation_date                     -- �쐬��
                 ,cn_last_updated_by                   -- �ŏI�X�V��
                 ,cd_last_update_date                  -- �ŏI�X�V��
                 ,cn_last_update_login                 -- �ŏI�X�V���O�C��
                 ,cn_request_id                        -- �v��ID
                 ,cn_program_application_id            -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
                 ,cn_program_id                        -- �R���J�����g�E�v���O����ID
                 ,cd_program_update_date               -- �v���O�����X�V��
                );
              EXCEPTION
                WHEN OTHERS THEN
                  lv_errmsg := xxccp_common_pkg.get_msg(
                                 iv_application  => ct_xxcos_appl_short_name
                                ,iv_name         => ct_msg_cos_15163   -- �������i�\�o�^�G���[
                                ,iv_token_name1  => cv_tkn_line_no
                                ,iv_token_value1 => TO_CHAR( get_sale_price_lists_rec.line_no, cv_format ) -- �sNo
                                ,iv_token_name2  => cv_tkn_err_msg
                                ,iv_token_value2 => SQLERRM    -- �G���[���e
                               );
                  lv_errbuf := lv_errmsg;
                  RAISE global_api_expt;
              END;
            END IF;
          END IF;
        END IF;
      ELSE
        -- �ڋq�`�F�b�N�G���[���������Ă���ꍇ
        lv_pre_status := cv_status_warn;
      END IF;
--
      IF ( lv_status = cv_status_warn ) THEN
        -- �G���[�����J�E���g
        gn_error_cnt := gn_error_cnt + 1;
        -- �X�e�[�^�X�F�x��
        ov_retcode := cv_status_warn;
      ELSIF ( lv_status = cv_status_normal ) THEN
        -- ���������J�E���g
        gn_normal_cnt := gn_normal_cnt + 1;
      END IF;
--
    END LOOP main_loop;
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
  END data_insert;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : �T�u���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    in_get_file_id    IN  NUMBER,   -- 1.<file_id>
    iv_get_format_pat IN  VARCHAR2, -- 2.<�t�H�[�}�b�g�p�^�[��>
    ov_errbuf         OUT NOCOPY VARCHAR2, -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT NOCOPY VARCHAR2, -- 2.���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT NOCOPY VARCHAR2) -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_temp_status           VARCHAR2(1);    -- �I���X�e�[�^�X�i�P���R�[�h���p�j
    lv_status                VARCHAR2(1);    -- �I���X�e�[�^�X�i���R�[�h�S�̗p�j
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode      := cv_status_normal;
    lv_temp_status  := cv_status_normal;
    lv_status       := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt  := 0;
    gn_normal_cnt  := 0;
    gn_error_cnt   := 0;
--
    --==================================
    -- ��������(A-1)
    --==================================
    init(
      in_file_id    => in_get_file_id    -- FILE_ID
     ,iv_get_format => iv_get_format_pat -- �t�H�[�}�b�g�p�^�[��
     ,ov_errbuf     => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    --==================================
    -- �t�@�C���A�b�v���[�hIF�擾(A-2)
    --==================================
    get_if_data (
      in_file_id          => in_get_file_id      -- FILE_ID
     ,ov_errbuf           => lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode          => lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg           => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    --==================================
    -- �Ώۃf�[�^���݃`�F�b�N
    --==================================
    IF ( g_upload_if_tab.COUNT < 2 ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name
                    ,iv_name         => ct_msg_cos_00003   -- �Ώۃf�[�^�����G���[
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --==================================
    -- ���ڕ�������(A-3)
    --==================================
    item_split(
      ov_errbuf         => lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode        => lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg         => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    <<item_check_loop>>
    FOR i IN 2 .. gn_get_counter_data LOOP
      --==================================
      -- ���ڃ`�F�b�N(A-4)
      --==================================
      item_check(
        in_cnt                  => i                       -- ���[�v�J�E���^
       ,ov_errbuf               => lv_errbuf               -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode              => lv_retcode              -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg               => lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      ELSIF ( lv_retcode = cv_status_warn ) THEN
        -- �G���[�����J�E���g
        gn_error_cnt := gn_error_cnt + 1;
        -- �X�e�[�^�X�ێ�
        lv_temp_status := cv_status_warn;
      END IF;
    END LOOP item_check_loop;
--
    -- �G���[���������Ă��Ȃ��ꍇ
    IF ( lv_temp_status = cv_status_normal ) THEN
--
      <<ins_work_table_loop>>
      FOR i IN 2 .. gn_get_counter_data LOOP
        --==================================
        -- �ꎞ�\�o�^����(A-5)
        --==================================
        ins_work_table(
          in_cnt                  => i                       -- ���[�v�J�E���^
         ,ov_errbuf               => lv_errbuf               -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode              => lv_retcode              -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg               => lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
      END LOOP ins_work_table_loop;
--
      --==================================
      -- �������i�\���f����(A-6)
      --==================================
      data_insert(
        ov_errbuf                   => lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode                  => lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg                   => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      ELSIF ( lv_retcode = cv_status_warn ) THEN
        -- �X�e�[�^�X�ێ�
        lv_temp_status := cv_status_warn;
      END IF;
--
    END IF;
--
    -- �x���G���[���������Ă���ꍇ
    IF ( lv_temp_status = cv_status_warn ) THEN
      --��s�}��
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => NULL
      );
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
    errbuf            OUT NOCOPY VARCHAR2  --   �G���[�E���b�Z�[�W  --# �Œ� #
   ,retcode           OUT NOCOPY VARCHAR2  --   ���^�[���E�R�[�h    --# �Œ� #
--    ��IN �����Ұ�������ꍇ�͓K�X�ҏW���ĉ������B
   ,in_get_file_id    IN  NUMBER    --   file_id
   ,iv_get_format_pat IN  VARCHAR2  --   �t�H�[�}�b�g�p�^�[��
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
    cv_prg_name         CONSTANT VARCHAR2(100) := 'main';             -- �v���O������
--
    cv_appl_short_name  CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�h�I���F���ʁEIF�̈�
    cv_target_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_skip_rec_msg     CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- �X�L�b�v�������b�Z�[�W
    cv_cnt_token        CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg         CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
    cv_log_header_out   CONSTANT VARCHAR2(6)   := 'OUTPUT';           -- �R���J�����g�w�b�_���b�Z�[�W�o�͐�F�o��
    cv_log_header_log   CONSTANT VARCHAR2(6)   := 'LOG';              -- �R���J�����g�w�b�_���b�Z�[�W�o�͐�F���O(���[�̂�)
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
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo��(���ۂ̏�����submain�ōs��)
    -- ===============================================
    submain(
      in_get_file_id     -- file_id
     ,iv_get_format_pat  -- �t�H�[�}�b�g�p�^�[��
     ,lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
     ,lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
--###########################  �Œ蕔 START   #####################################################
--
    IF ( lv_retcode = cv_status_error ) THEN
      --�G���[�̏ꍇ
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
--
      -- �G���[���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
       ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    ELSIF( lv_retcode = cv_status_warn ) THEN
      -- �x���̏ꍇ�i�`�F�b�N�G���[���������Ă���ꍇ�j
      gn_normal_cnt := 0;
      lv_retcode := cv_status_error;
    END IF;
--
    --��s�}��
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
     ,buff   => NULL
    );
--
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name,
                    iv_name         => cv_target_rec_msg,
                    iv_token_name1  => cv_cnt_token,
                    iv_token_value1 => TO_CHAR( gn_target_cnt )
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
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT,
      buff   => NULL
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
END XXCOS003A08C;
/
