CREATE OR REPLACE PACKAGE BODY APPS.XXCOS005A11C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2022. All rights reserved.
 *
 * Package Name     : XXCOS005A11C (body)
 * Description      : CSV�f�[�^�A�b�v���[�h�i���i�\�j
 * MD.050           : CSV�f�[�^�A�b�v���[�h�i���i�\�j MD050_COS_005_A11
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
 *  data_insert            ���i�\���f����                (A-6)
 *                         �I������                      (A-7)
 * ---------------------- ----------------------------------------------------------
 *  submain                �T�u���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 * ---------------------- ----------------------------------------------------------
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2022/09/16    1.0   R.Oikawa         �V�K�쐬
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
  cv_pkg_name                    CONSTANT VARCHAR2(128) := 'XXCOS005A11C';      -- �p�b�P�[�W��
  --�A�v���P�[�V�����Z�k��
  ct_xxcos_appl_short_name       CONSTANT fnd_application.application_short_name%TYPE  := 'XXCOS'; -- �̕��Z�k�A�v����
  ct_xxccp_appl_short_name       CONSTANT fnd_application.application_short_name%TYPE  := 'XXCCP'; -- ����
  --�v���t�@�C��
  ct_prof_org_id                 CONSTANT fnd_profile_options.profile_option_name%TYPE := 'ORG_ID';                    -- �c�ƒP��
  ct_inv_org_code                CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOI1_ORGANIZATION_CODE';  -- �݌ɑg�D�R�[�h
  ct_prof_min_date               CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_MIN_DATE';           -- XXCOS:MIN���t
  ct_prof_max_date               CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_MAX_DATE';           -- XXCOS:MAX���t
  --�N�C�b�N�R�[�h�^�C�v
  ct_lookup_type_upload_name     CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCCP1_FILE_UPLOAD_OBJ';             -- �t�@�C���A�b�v���[�h���}�X�^
  ct_lookup_type_all_base        CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCOS1_005A11_ALL_BASE_CD';          -- ���i�\�A�b�v���[�h�S���_�Ώ�
  --�N�C�b�N�R�[�h
  ct_lang                        CONSTANT fnd_lookup_values.language%TYPE := USERENV('LANG'); -- ����R�[�h
  --������
  cv_str_file_id                 CONSTANT VARCHAR2(128) := 'FILE_ID';             -- FILE_ID
  cv_format                      CONSTANT VARCHAR2(10)  := 'FM00000';             -- �sNo�o��
  --�t�H�[�}�b�g
  cv_msg_part                    CONSTANT VARCHAR2(3)   := ' : ';
  cv_msg_cont                    CONSTANT VARCHAR2(3)   := '.';
  cv_c_kanma                     CONSTANT VARCHAR2(1)   := ',';                     -- �J���}
  cn_c_header                    CONSTANT NUMBER        := 16;                      -- ���ڐ�
  cv_yyyy_mm_dd                  CONSTANT VARCHAR2(30)  := 'YYYY/MM/DD';            --YYYY/MM/DD�^
  cv_yyyy_mm_ddhh24miss          CONSTANT VARCHAR2(30)  := 'YYYY/MM/DD HH24:MI:SS'; --YYYY/MM/DD HH24:MI:SS�^
  --�t�@�C�����C�A�E�g
  cn_proc_kbn                    CONSTANT NUMBER        := 1;                     -- �����敪
  cn_name                        CONSTANT NUMBER        := 2;                     -- ����
  cn_active_flag                 CONSTANT NUMBER        := 3;                     -- �L��
  cn_description                 CONSTANT NUMBER        := 4;                     -- �E�v
  cn_rounding_factor             CONSTANT NUMBER        := 5;                     -- �ۂߏ�����
  cn_date_from                   CONSTANT NUMBER        := 6;                     -- �L����(From)
  cn_date_to                     CONSTANT NUMBER        := 7;                     -- �L����(To)
  cn_comments                    CONSTANT NUMBER        := 8;                     -- ����
  cn_attribute1                  CONSTANT NUMBER        := 9;                     -- ���L���_
  cn_product_attr_value          CONSTANT NUMBER        := 10;                    -- ���i�l
  cn_product_uom_code            CONSTANT NUMBER        := 11;                    -- �P��
  cn_primary_uom_flag            CONSTANT NUMBER        := 12;                    -- ��P��
  cn_operand                     CONSTANT NUMBER        := 13;                    -- �l
  cn_start_date_active           CONSTANT NUMBER        := 14;                    -- �J�n��
  cn_end_date_active             CONSTANT NUMBER        := 15;                    -- �I����
  cn_product_precedence          CONSTANT NUMBER        := 16;                    -- �D��
  --�ėp
  cv_y                           CONSTANT VARCHAR2(10)  := 'Y';                   -- �ėp�FY
  cv_n                           CONSTANT VARCHAR2(10)  := 'N';                   -- �ėp�FN
  cv_i                           CONSTANT VARCHAR2(10)  := 'I';                   -- �ėp�FI(�o�^)
  cv_u                           CONSTANT VARCHAR2(10)  := 'U';                   -- �ėp�FU(�X�V)
--
  --���b�Z�[�W
  ct_msg_cos_00001   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00001'; -- ���b�N�G���[
  ct_msg_cos_00003   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00003'; -- �Ώۃf�[�^�����G���[
  ct_msg_cos_00004   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00004'; -- �v���t�@�C���擾�G���[
  ct_msg_cos_00012   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00012'; -- �f�[�^�폜�G���[���b�Z�[�W
  ct_msg_cos_00013   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00013'; -- �f�[�^���o�G���[���b�Z�[�W
  ct_msg_cos_00014   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00014'; -- �Ɩ����t�擾�G���[
  ct_msg_cos_10024   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10024'; -- �݌ɑg�DID�擾�G���[���b�Z�[�W
  ct_msg_cos_10181   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10181'; -- ���_���ݒ�G���[
  ct_msg_cos_11289   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-11289'; -- �t�H�[�}�b�g�p�^�[�����b�Z�[�W
  ct_msg_cos_11290   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-11290'; -- CSV�t�@�C�������b�Z�[�W
  ct_msg_cos_11293   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-11293'; -- �t�@�C���A�b�v���[�h���̎擾�G���[
  ct_msg_cos_11294   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-11294'; -- CSV�t�@�C�����擾�G���[
  ct_msg_cos_11295   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-11295'; -- �t�@�C�����R�[�h�s��v�G���[���b�Z�[�W
  ct_msg_cos_15151   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15151'; -- �K�{�`�F�b�N�G���[
  ct_msg_cos_15365   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15365'; -- �����敪�G���[
  ct_msg_cos_15366   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15366'; -- �L���s���G���[
  ct_msg_cos_15367   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15367'; -- ���l�G���[
  ct_msg_cos_15368   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15368'; -- �ۂߏ�����s���G���[
  ct_msg_cos_15369   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15369'; -- ���t�����G���[
  ct_msg_cos_15370   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15370'; -- ���t�t�]�G���[
  ct_msg_cos_15371   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15371'; -- ���L���_�}�X�^���݃G���[
  ct_msg_cos_15372   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15372'; -- �i�ڃ}�X�^���݃G���[
  ct_msg_cos_15373   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15373'; -- �P�ʃ}�X�^���݃G���[
  ct_msg_cos_15374   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15374'; -- ��P�ʕs���G���[
  ct_msg_cos_15375   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15375'; -- ���L���_�Z�L�����e�B�G���[
  ct_msg_cos_15376   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15376'; -- �l�s���G���[
  ct_msg_cos_15377   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15377'; -- �c�ƒP�ʃZ�L�����e�B�G���[
  ct_msg_cos_15378   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15378'; -- �d���G���[(�t�@�C����)
  ct_msg_cos_15379   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15379'; -- �d���G���[(�o�^��)
  ct_msg_cos_15380   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15380'; -- �X�V�ΏۂȂ��G���[
  ct_msg_cos_15381   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15381'; -- �ꎞ�\�o�^�G���[
  ct_msg_cos_15382   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15382'; -- API�o�^�G���[
  --���b�Z�[�W������
  ct_msg_cos_11282   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-11282'; -- �t�@�C���A�b�v���[�hIF(���b�Z�[�W������)
  ct_msg_cos_11636   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-11636'; -- ����(���b�Z�[�W������)
  ct_msg_cos_15152   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15152'; -- �����敪(���b�Z�[�W������)
  ct_msg_cos_15356   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15356'; -- �ۂߏ�����(���b�Z�[�W������)
  ct_msg_cos_15357   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15357'; -- ���L���_(���b�Z�[�W������)
  ct_msg_cos_15358   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15358'; -- ���i�l(���b�Z�[�W������)
  ct_msg_cos_15359   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15359'; -- �P��(���b�Z�[�W������)
  ct_msg_cos_15360   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15360'; -- �l(���b�Z�[�W������)
  ct_msg_cos_15361   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15361'; -- �L����FROM(���b�Z�[�W������)
  ct_msg_cos_15362   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15362'; -- �L����TO(���b�Z�[�W������)
  ct_msg_cos_15363   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15363'; -- �J�n��(���b�Z�[�W������)
  ct_msg_cos_15364   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15364'; -- �I����(���b�Z�[�W������)
  ct_msg_cos_15383   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15383'; -- �D��(���b�Z�[�W������)
  --�g�[�N��
  cv_tkn_profile                 CONSTANT VARCHAR2(512) := 'PROFILE';            -- �v���t�@�C����
  cv_tkn_table                   CONSTANT VARCHAR2(512) := 'TABLE';              -- �e�[�u����
  cv_tkn_key_data                CONSTANT VARCHAR2(512) := 'KEY_DATA';           -- �L�[���e���R�����g
  cv_tkn_proc_kbn                CONSTANT VARCHAR2(512) := 'PROC_KBN';           -- �����敪
  cv_tkn_line_no                 CONSTANT VARCHAR2(512) := 'LINE_NO';            -- �s�ԍ�
  cv_tkn_item                    CONSTANT VARCHAR2(512) := 'ITEM';               -- ����
  cv_tkn_item2                   CONSTANT VARCHAR2(512) := 'ITEM2';              -- ����2
  cv_tkn_item_code               CONSTANT VARCHAR2(512) := 'ITEM_CODE';          -- �i�ڃR�[�h
  cv_tkn_date                    CONSTANT VARCHAR2(512) := 'DATE';               -- ���t
  cv_tkn_date_from               CONSTANT VARCHAR2(512) := 'DATE_FROM';          -- ����(From)
  cv_tkn_date_to                 CONSTANT VARCHAR2(512) := 'DATE_TO';            -- ����(To)
  cv_tkn_start_date              CONSTANT VARCHAR2(512) := 'START_DATE';         -- �J�n��
  cv_tkn_start_date2             CONSTANT VARCHAR2(512) := 'START_DATE2';        -- �J�n��
  cv_tkn_end_date                CONSTANT VARCHAR2(512) := 'END_DATE';           -- �I����
  cv_tkn_end_date2               CONSTANT VARCHAR2(512) := 'END_DATE2';          -- �I����
  cv_tkn_table_name              CONSTANT VARCHAR2(512) := 'TABLE_NAME';         -- �e�[�u����
  cv_tkn_err_msg                 CONSTANT VARCHAR2(512) := 'ERR_MSG';            -- �G���[���b�Z�[�W
  cv_tkn_data                    CONSTANT VARCHAR2(512) := 'DATA';               -- ���R�[�h�f�[�^
  cv_tkn_param1                  CONSTANT VARCHAR2(512) := 'PARAM1';             -- �p�����[�^
  cv_tkn_param2                  CONSTANT VARCHAR2(512) := 'PARAM2';             -- �p�����[�^
  cv_tkn_param3                  CONSTANT VARCHAR2(512) := 'PARAM3';             -- �p�����[�^
  cv_tkn_param4                  CONSTANT VARCHAR2(512) := 'PARAM4';             -- �p�����[�^
  cv_tkn_active_flag             CONSTANT VARCHAR2(512) := 'ACTIVE_FLAG';        -- �L��
  cv_tkn_value                   CONSTANT VARCHAR2(512) := 'VALUE';              -- ����
  cv_tkn_rounding                CONSTANT VARCHAR2(512) := 'ROUNDING';           -- �ۂߏ�����
  cv_tkn_base_code               CONSTANT VARCHAR2(512) := 'BASE_CODE';          -- ���_
  cv_tkn_uom_code                CONSTANT VARCHAR2(512) := 'UOM_CODE';           -- �P��
  cv_tkn_uom_flag                CONSTANT VARCHAR2(512) := 'UOM_FLAG';           -- ��P��
  cv_tkn_name                    CONSTANT VARCHAR2(512) := 'NAME';               -- ����
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
  gv_all_base_flg                 VARCHAR2(1);                                        -- ���i�\�S���_�L���t���O
  gn_get_counter_data             NUMBER;                                             -- �f�[�^��
  gv_login_user_base_code         xxcos_login_own_base_info_v.base_code%TYPE;         -- ���O�C�����[�U���_
  gd_min_date                     DATE;                                               -- MIN���t
  gd_max_date                     DATE;                                               -- MAX���t
  --
  g_item_work_tab                 g_var2_ttype;                                       -- ���i�\�f�[�^(����������)
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
    --========================================
    -- MIN���t�擾����
    --========================================
    gd_min_date := FND_DATE.STRING_TO_DATE( FND_PROFILE.VALUE( ct_prof_min_date ), cv_yyyy_mm_dd );
    IF ( gd_min_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name
                    ,iv_name         => ct_msg_cos_00004   -- �v���t�@�C���擾�G���[
                    ,iv_token_name1  => cv_tkn_profile
                    ,iv_token_value1 => ct_prof_min_date
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- MAX���t�擾����
    --========================================
    gd_max_date := FND_DATE.STRING_TO_DATE( FND_PROFILE.VALUE( ct_prof_max_date ), cv_yyyy_mm_dd );
    IF ( gd_max_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name
                    ,iv_name         => ct_msg_cos_00004   -- �v���t�@�C���擾�G���[
                    ,iv_token_name1  => cv_tkn_profile
                    ,iv_token_value1 => ct_prof_max_date
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --===============================
    -- ���O�C�����[�U���_�擾
    --===============================
    BEGIN
      SELECT xlob.base_code  AS base_code        -- ���_�R�[�h
      INTO   gv_login_user_base_code
      FROM   xxcos_login_own_base_info_v xlob    -- ���O�C�����[�U�����_�r���[
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => ct_xxcos_appl_short_name
                      ,iv_name         => ct_msg_cos_10181   -- ���_���ݒ�G���[���b�Z�[�W
                       );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
    --===============================
    -- �S���_�X�V�Ώۂ����f
    --===============================
    BEGIN
      SELECT  cv_y    AS  cv_y                -- �S���_�X�V�Ώ�
      INTO    gv_all_base_flg
      FROM    fnd_lookup_values_vl    flv     -- �Q�ƃR�[�h
      WHERE   flv.lookup_type                            =  ct_lookup_type_all_base
      AND     flv.lookup_code                            =  gv_login_user_base_code
      AND     TRUNC(NVL(flv.start_date_active, SYSDATE)) <= TRUNC(SYSDATE)
      AND     TRUNC(NVL(flv.end_date_active, SYSDATE))   >= TRUNC(SYSDATE)
      AND     flv.enabled_flag                           =  cv_y
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        gv_all_base_flg := cv_n;
    END;

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
    -- ���i�\�f�[�^�擾
    --==================================
    xxccp_common_pkg2.blob_to_varchar2(
      in_file_id   => in_file_id         -- file_id
     ,ov_file_data => g_upload_if_tab    -- ���i�\�f�[�^(�z��^)
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
   * Procedure Name   : ins_work_table
   * Description      : �ꎞ�\�o�^����(A-5)
   ***********************************************************************************/
  PROCEDURE ins_work_table(
    in_line_no              IN  NUMBER          -- �sNo
   ,in_list_header_id       IN  NUMBER          -- �w�b�_�[ID
   ,in_list_line_id         IN  NUMBER          -- ����ID
   ,in_product_attr_value   IN  NUMBER          -- ���i�l
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
      INSERT INTO xxcos_tmp_price_lists(
         line_no                      -- �sNo
        ,proc_kbn                     -- �����敪
        ,name                         -- ����
        ,active_flag                  -- �L��
        ,description                  -- �E�v
        ,rounding_factor              -- �ۂߏ�����
        ,start_date_active_h          -- �L����FROM
        ,end_date_active_h            -- �L����TO
        ,comments                     -- ����
        ,base_code                    -- ���L���_
        ,product_attr_value           -- ���i�l
        ,product_uom_code             -- �P��
        ,primary_uom_flag             -- ��P��
        ,operand                      -- �l
        ,start_date_active_l          -- �J�n��
        ,end_date_active_l            -- �I����
        ,product_precedence           -- �D��
        ,list_header_id               -- �w�b�_�[ID
        ,list_line_id                 -- ����ID
      )VALUES(
        in_line_no                                                                      -- �sNo
        ,g_item_work_tab(in_line_no)(cn_proc_kbn)                                       -- �����敪
        ,g_item_work_tab(in_line_no)(cn_name)                                           -- ����
        ,g_item_work_tab(in_line_no)(cn_active_flag)                                    -- �L��
        ,g_item_work_tab(in_line_no)(cn_description)                                    -- �E�v
        ,TO_NUMBER( g_item_work_tab(in_line_no)(cn_rounding_factor))                    -- �ۂߏ�����
        ,TO_DATE( g_item_work_tab(in_line_no)(cn_date_from), cv_yyyy_mm_dd )            -- �L����FROM
        ,TO_DATE( g_item_work_tab(in_line_no)(cn_date_to), cv_yyyy_mm_dd )              -- �L����TO
        ,g_item_work_tab(in_line_no)(cn_comments)                                       -- ����
        ,g_item_work_tab(in_line_no)(cn_attribute1)                                     -- ���L���_
        ,TO_CHAR(in_product_attr_value)                                                 -- ���i�l
        ,g_item_work_tab(in_line_no)(cn_product_uom_code)                               -- �P��
        ,g_item_work_tab(in_line_no)(cn_primary_uom_flag)                               -- ��P��
        ,TO_NUMBER( g_item_work_tab(in_line_no)(cn_operand))                            -- �l
        ,TO_DATE( g_item_work_tab(in_line_no)(cn_start_date_active), cv_yyyy_mm_dd )    -- �J�n��
        ,TO_DATE( g_item_work_tab(in_line_no)(cn_end_date_active), cv_yyyy_mm_dd )      -- �I����
        ,TO_NUMBER( g_item_work_tab(in_line_no)(cn_product_precedence))                 -- �D��
        ,in_list_header_id                                                              -- �w�b�_�[ID
        ,in_list_line_id                                                                -- ����ID
      );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => ct_xxcos_appl_short_name
                      ,iv_name         => ct_msg_cos_15381   -- �ꎞ�\�o�^�G���[
                      ,iv_token_name1  => cv_tkn_line_no
                      ,iv_token_value1 => TO_CHAR( in_line_no, cv_format ) -- �sNo
                      ,iv_token_name2  => cv_tkn_err_msg
                      ,iv_token_value2 => SQLERRM    -- �G���[���e
                     );
        lv_errbuf := lv_errmsg;
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
  END ins_work_table;
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
    lv_status                      VARCHAR2(1);      -- �I���X�e�[�^�X
    ln_cnt                         NUMBER;           -- ����
    ln_chk_cnt                     NUMBER;           -- �`�F�b�N����
    ln_number                      NUMBER;           -- ���l�`�F�b�N�p
    lt_inventory_item_id           mtl_system_items_b.inventory_item_id%TYPE;         -- �i��ID
    lt_orig_org_id                 qp_list_headers_b.orig_org_id%TYPE;                -- �c�ƒP��
    lt_header_base_code            qp_list_headers_b.attribute1%TYPE;                 -- ���_�R�[�h(�o�^�f�[�^)
    lt_list_header_id              qp_list_headers_tl.list_header_id%TYPE;            -- �w�b�_ID
    lt_list_line_id                qp_list_lines.list_line_id%TYPE;                   -- ����ID
    lt_base_code                   xxcmm_cust_accounts.customer_code%TYPE;            -- �����_
    lt_attribute1                  fnd_flex_values_vl.flex_value%TYPE;                -- ���L���_
    lt_uom_code                    mtl_units_of_measure_tl.uom_code%TYPE;             -- �P��
    ld_start_date_active_h         xxcos_tmp_price_lists.start_date_active_h%TYPE;    -- �L����FROM
    ld_end_date_active_h           xxcos_tmp_price_lists.end_date_active_h%TYPE;      -- �L����TO
    ld_start_date_active_l         xxcos_tmp_price_lists.start_date_active_l%TYPE;    -- �J�n��
    ld_end_date_active_l           xxcos_tmp_price_lists.end_date_active_l%TYPE;      -- �I����
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
    ln_cnt                 := 0;
    ln_chk_cnt             := 0;
    ln_number              := 0;
    lt_inventory_item_id   := NULL;
    ld_start_date_active_h := NULL;
    ld_end_date_active_h   := NULL;
    ld_start_date_active_l := NULL;
    ld_end_date_active_l   := NULL;
--
    --===============================
    -- �K�{�`�F�b�N
    --===============================
    -- �����敪
    IF ( g_item_work_tab(in_cnt)(cn_proc_kbn) IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => ct_xxcos_appl_short_name
                    ,iv_name          => ct_msg_cos_15151             -- �K�{�`�F�b�N�G���[
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
    -- ����
    IF ( g_item_work_tab(in_cnt)(cn_name) IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => ct_xxcos_appl_short_name
                    ,iv_name          => ct_msg_cos_15151             -- �K�{�`�F�b�N�G���[
                    ,iv_token_name1   => cv_tkn_line_no
                    ,iv_token_value1  => TO_CHAR( in_cnt, cv_format ) -- �sNo
                    ,iv_token_name2   => cv_tkn_item
                    ,iv_token_value2  => ct_msg_cos_11636             -- ����(���b�Z�[�W������)
                   );
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => lv_errmsg
      );
      lv_status := cv_status_warn;
    END IF;
--
    -- �ۂߏ�����
    IF ( g_item_work_tab(in_cnt)(cn_rounding_factor) IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => ct_xxcos_appl_short_name
                    ,iv_name          => ct_msg_cos_15151             -- �K�{�`�F�b�N�G���[
                    ,iv_token_name1   => cv_tkn_line_no
                    ,iv_token_value1  => TO_CHAR( in_cnt, cv_format ) -- �sNo
                    ,iv_token_name2   => cv_tkn_item
                    ,iv_token_value2  => ct_msg_cos_15356             -- �ۂߏ�����(���b�Z�[�W������)
                   );
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => lv_errmsg
      );
      lv_status := cv_status_warn;
    END IF;
--
    -- ���L���_
    IF ( g_item_work_tab(in_cnt)(cn_attribute1) IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => ct_xxcos_appl_short_name
                    ,iv_name          => ct_msg_cos_15151             -- �K�{�`�F�b�N�G���[
                    ,iv_token_name1   => cv_tkn_line_no
                    ,iv_token_value1  => TO_CHAR( in_cnt, cv_format ) -- �sNo
                    ,iv_token_name2   => cv_tkn_item
                    ,iv_token_value2  => ct_msg_cos_15357             -- ���L���_(���b�Z�[�W������)
                   );
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => lv_errmsg
      );
      lv_status := cv_status_warn;
    END IF;
--
    -- ���i�l
    IF ( g_item_work_tab(in_cnt)(cn_product_attr_value) IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => ct_xxcos_appl_short_name
                    ,iv_name          => ct_msg_cos_15151             -- �K�{�`�F�b�N�G���[
                    ,iv_token_name1   => cv_tkn_line_no
                    ,iv_token_value1  => TO_CHAR( in_cnt, cv_format ) -- �sNo
                    ,iv_token_name2   => cv_tkn_item
                    ,iv_token_value2  => ct_msg_cos_15358             -- ���i�l(���b�Z�[�W������)
                   );
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => lv_errmsg
      );
      lv_status := cv_status_warn;
    END IF;
--
    -- �P��
    IF ( g_item_work_tab(in_cnt)(cn_product_uom_code) IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => ct_xxcos_appl_short_name
                    ,iv_name          => ct_msg_cos_15151             -- �K�{�`�F�b�N�G���[
                    ,iv_token_name1   => cv_tkn_line_no
                    ,iv_token_value1  => TO_CHAR( in_cnt, cv_format ) -- �sNo
                    ,iv_token_name2   => cv_tkn_item
                    ,iv_token_value2  => ct_msg_cos_15359             -- �P��(���b�Z�[�W������)
                   );
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => lv_errmsg
      );
      lv_status := cv_status_warn;
    END IF;
--
    -- �l
    IF ( g_item_work_tab(in_cnt)(cn_operand) IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => ct_xxcos_appl_short_name
                    ,iv_name          => ct_msg_cos_15151             -- �K�{�`�F�b�N�G���[
                    ,iv_token_name1   => cv_tkn_line_no
                    ,iv_token_value1  => TO_CHAR( in_cnt, cv_format ) -- �sNo
                    ,iv_token_name2   => cv_tkn_item
                    ,iv_token_value2  => ct_msg_cos_15360             -- �l(���b�Z�[�W������)
                   );
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => lv_errmsg
      );
      lv_status := cv_status_warn;
    END IF;
--
    --===============================
    -- ���͒l�`�F�b�N
    --===============================
    -- �����敪���ݒ肳��Ă���ꍇ
    IF ( g_item_work_tab(in_cnt)(cn_proc_kbn) IS NOT NULL ) THEN
      --===============================
      -- �����敪�`�F�b�N
      --===============================
      -- I:�o�^ U:�X�V �ȊO�̏ꍇ�̓G���[
      IF ( g_item_work_tab(in_cnt)(cn_proc_kbn) NOT IN (cv_i, cv_u) ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => ct_xxcos_appl_short_name
                      ,iv_name          => ct_msg_cos_15365 -- �����敪�G���[
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
    -- �L�����ݒ肳��Ă���ꍇ
    IF ( g_item_work_tab(in_cnt)(cn_active_flag) IS NOT NULL ) THEN
      --===============================
      -- �L���`�F�b�N
      --===============================
      -- �uY�v,�uN�v�ȊO�̏ꍇ�̓G���[
      IF ( g_item_work_tab(in_cnt)(cn_active_flag) NOT IN (cv_y, cv_n) ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => ct_xxcos_appl_short_name
                      ,iv_name          => ct_msg_cos_15366 -- �L���s���G���[
                      ,iv_token_name1   => cv_tkn_line_no
                      ,iv_token_value1  => TO_CHAR( in_cnt, cv_format ) -- �sNo
                      ,iv_token_name2   => cv_tkn_active_flag
                      ,iv_token_value2  => g_item_work_tab(in_cnt)(cn_active_flag) -- �L��
                     );
        FND_FILE.PUT_LINE(
          which => FND_FILE.OUTPUT
         ,buff  => lv_errmsg
        );
        lv_status := cv_status_warn;
      END IF;
    ELSE
      -- ���ݒ�́uY�v��ݒ�
      g_item_work_tab(in_cnt)(cn_active_flag) := cv_y;
    END IF;
--
    -- �ۂߏ����悪�ݒ肳��Ă���ꍇ
    IF (  g_item_work_tab(in_cnt)(cn_rounding_factor) IS NOT NULL ) THEN
      --===============================
      -- ���l�`���`�F�b�N
      --===============================
      BEGIN
        -- ���l�`���`�F�b�N
        ln_number := TO_NUMBER( g_item_work_tab(in_cnt)(cn_rounding_factor) );
--
        --===============================
        -- �ۂߏ�����s���`�F�b�N
        --===============================
        IF ( g_item_work_tab(in_cnt)(cn_rounding_factor) < -3 ) THEN
          -- �ۂߏ�����s���G���[
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => ct_xxcos_appl_short_name
                        ,iv_name          => ct_msg_cos_15368  -- �ۂߏ�����s���G���[
                        ,iv_token_name1   => cv_tkn_line_no
                        ,iv_token_value1  => TO_CHAR( in_cnt, cv_format ) -- �sNo
                        ,iv_token_name2   => cv_tkn_rounding
                        ,iv_token_value2  => g_item_work_tab(in_cnt)(cn_rounding_factor) -- �ۂߏ�����
                       );
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT
           ,buff  => lv_errmsg
          );
          lv_status := cv_status_warn;
        END IF;
--
      EXCEPTION
        WHEN OTHERS THEN
          -- ���l�`���G���[
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => ct_xxcos_appl_short_name
                        ,iv_name          => ct_msg_cos_15367  -- ���l�`���G���[
                        ,iv_token_name1   => cv_tkn_line_no
                        ,iv_token_value1  => TO_CHAR( in_cnt, cv_format ) -- �sNo
                        ,iv_token_name2   => cv_tkn_item
                        ,iv_token_value2  => ct_msg_cos_15356             -- �ۂߏ�����(���b�Z�[�W������)
                        ,iv_token_name3   => cv_tkn_item2
                        ,iv_token_value3  => ct_msg_cos_15356             -- �ۂߏ�����(���b�Z�[�W������)
                        ,iv_token_name4   => cv_tkn_value
                        ,iv_token_value4  => g_item_work_tab(in_cnt)(cn_rounding_factor) -- �ۂߏ�����
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
    -- �L����(FROM)���ݒ肳��Ă���ꍇ
    IF (  g_item_work_tab(in_cnt)(cn_date_from) IS NOT NULL ) THEN
      --===============================
      -- ���t�`���`�F�b�N
      --===============================
      BEGIN
         ld_start_date_active_h := TO_DATE( g_item_work_tab(in_cnt)(cn_date_from), cv_yyyy_mm_dd );
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => ct_xxcos_appl_short_name
                        ,iv_name          => ct_msg_cos_15369             -- ���t�����G���[
                        ,iv_token_name1   => cv_tkn_line_no
                        ,iv_token_value1  => TO_CHAR( in_cnt, cv_format ) -- �sNo
                        ,iv_token_name2   => cv_tkn_item
                        ,iv_token_value2  => ct_msg_cos_15361             -- �L����FROM(���b�Z�[�W������)
                        ,iv_token_name3   => cv_tkn_item2
                        ,iv_token_value3  => ct_msg_cos_15361             -- �L����FROM(���b�Z�[�W������)
                        ,iv_token_name4   => cv_tkn_date
                        ,iv_token_value4  => g_item_work_tab(in_cnt)(cn_date_from) -- �L����(FROM)
                       );
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT
           ,buff  => lv_errmsg
          );
          lv_status := cv_status_warn;
          ld_start_date_active_h := NULL;
      END;
    END IF;
--
    -- �L����(TO)���ݒ肳��Ă���ꍇ
    IF (  g_item_work_tab(in_cnt)(cn_date_to) IS NOT NULL ) THEN
      --===============================
      -- ���t�`���`�F�b�N
      --===============================
      BEGIN
         ld_end_date_active_h := TO_DATE( g_item_work_tab(in_cnt)(cn_date_to), cv_yyyy_mm_dd );
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => ct_xxcos_appl_short_name
                        ,iv_name          => ct_msg_cos_15369                    -- ���t�����G���[
                        ,iv_token_name1   => cv_tkn_line_no
                        ,iv_token_value1  => TO_CHAR( in_cnt, cv_format )        -- �sNo
                        ,iv_token_name2   => cv_tkn_item
                        ,iv_token_value2  => ct_msg_cos_15362                    -- �L����TO(���b�Z�[�W������)
                        ,iv_token_name3   => cv_tkn_item2
                        ,iv_token_value3  => ct_msg_cos_15362                    -- �L����TO(���b�Z�[�W������)
                        ,iv_token_name4   => cv_tkn_date
                        ,iv_token_value4  => g_item_work_tab(in_cnt)(cn_date_to) -- �L����(TO)
                       );
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT
           ,buff  => lv_errmsg
          );
          lv_status := cv_status_warn;
          ld_end_date_active_h := NULL;
      END;
    END IF;
--
    IF (  ld_start_date_active_h IS NOT NULL
      AND ld_end_date_active_h IS NOT NULL ) THEN
       --===============================
       -- ���t�t�]�`�F�b�N
       --===============================
       IF ( ld_start_date_active_h > ld_end_date_active_h ) THEN
         lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => ct_xxcos_appl_short_name
                       ,iv_name          => ct_msg_cos_15370                      -- ���t�t�]�G���[
                       ,iv_token_name1   => cv_tkn_line_no
                       ,iv_token_value1  => TO_CHAR( in_cnt, cv_format )          -- �sNo
                       ,iv_token_name2   => cv_tkn_start_date
                       ,iv_token_value2  => ct_msg_cos_15361                      -- �L����FROM(���b�Z�[�W������)
                       ,iv_token_name3   => cv_tkn_end_date
                       ,iv_token_value3  => ct_msg_cos_15362                      -- �L����TO(���b�Z�[�W������)
                       ,iv_token_name4   => cv_tkn_start_date2
                       ,iv_token_value4  => ct_msg_cos_15361                      -- �L����FROM(���b�Z�[�W������)
                       ,iv_token_name5   => cv_tkn_date_from
                       ,iv_token_value5  => g_item_work_tab(in_cnt)(cn_date_from) -- �L����(FROM)
                       ,iv_token_name6   => cv_tkn_end_date2
                       ,iv_token_value6  => ct_msg_cos_15362                      -- �L����TO(���b�Z�[�W������)
                       ,iv_token_name7   => cv_tkn_date_to
                       ,iv_token_value7  => g_item_work_tab(in_cnt)(cn_date_to)   -- �L����(TO)
                      );
         FND_FILE.PUT_LINE(
           which => FND_FILE.OUTPUT
          ,buff  => lv_errmsg
         );
         lv_status := cv_status_warn;
       END IF;
    END IF;
--
    -- ���L���_���ݒ肳��Ă���ꍇ
    IF ( g_item_work_tab(in_cnt)(cn_attribute1) IS NOT NULL ) THEN
      --===============================
      -- ����}�X�^���݃`�F�b�N
      --===============================
      BEGIN
        SELECT ffvv.flex_value      AS flex_value     -- ���_�R�[�h
        INTO   lt_attribute1
        FROM   fnd_flex_values_vl ffvv,
               fnd_flex_value_sets ffvs
        WHERE  ffvs.flex_value_set_name = 'XX03_DEPARTMENT'
        AND    ffvs.flex_value_set_id   = ffvv.flex_value_set_id
        AND    ffvv.summary_flag        = cv_n
        AND    ffvv.enabled_flag        = cv_y
        AND    TRUNC(SYSDATE) BETWEEN NVL( ffvv.start_date_active, TRUNC(SYSDATE)) AND NVL(ffvv.end_date_active, TRUNC(SYSDATE))
        AND    ffvv.flex_value          = g_item_work_tab(in_cnt)(cn_attribute1) -- ���L���_
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => ct_xxcos_appl_short_name
                        ,iv_name          => ct_msg_cos_15371                        -- ���L���_�}�X�^���݃G���[
                        ,iv_token_name1   => cv_tkn_line_no
                        ,iv_token_value1  => TO_CHAR( in_cnt, cv_format )            -- �sNo
                        ,iv_token_name2   => cv_tkn_base_code
                        ,iv_token_value2  => g_item_work_tab(in_cnt)(cn_attribute1)  -- ���L���_
                       );
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT
           ,buff  => lv_errmsg
          );
          lv_status := cv_status_warn;
      END;
    END IF;
--
    -- ���i�l���ݒ肳��Ă���ꍇ
    IF ( g_item_work_tab(in_cnt)(cn_product_attr_value) IS NOT NULL ) THEN
      --===============================
      -- �i�ڃ}�X�^���݃`�F�b�N
      --===============================
      BEGIN
        SELECT msiv.inventory_item_id     AS inventory_item_id              -- �i��ID
        INTO   lt_inventory_item_id
        FROM   mtl_system_items_vl msiv
        WHERE  msiv.segment1        = g_item_work_tab(in_cnt)(cn_product_attr_value) -- ���i�l
        AND    msiv.organization_id = gn_inv_org_id
        AND    msiv.enabled_flag    = cv_y
        AND    ( NVL( customer_order_flag, cv_y ) = cv_y )
        AND    TO_DATE(SYSDATE, cv_yyyy_mm_ddhh24miss) BETWEEN  NVL(TRUNC( msiv.start_date_active),TO_DATE(SYSDATE, cv_yyyy_mm_ddhh24miss)) 
                   AND    NVL(TRUNC( msiv.end_date_active), TO_DATE(SYSDATE, cv_yyyy_mm_ddhh24miss)) 
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => ct_xxcos_appl_short_name
                        ,iv_name          => ct_msg_cos_15372                               -- �i�ڃ}�X�^���݃G���[
                        ,iv_token_name1   => cv_tkn_line_no
                        ,iv_token_value1  => TO_CHAR( in_cnt, cv_format )                   -- �sNo
                        ,iv_token_name2   => cv_tkn_item_code
                        ,iv_token_value2  => g_item_work_tab(in_cnt)(cn_product_attr_value) -- ���i�l
                       );
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT
           ,buff  => lv_errmsg
          );
          lv_status := cv_status_warn;
      END;
    END IF;
--
    -- �P�ʂ��ݒ肳��Ă���ꍇ
    IF ( g_item_work_tab(in_cnt)(cn_product_uom_code) IS NOT NULL ) THEN
      --===============================
      -- �P�ʃ}�X�^���݃`�F�b�N
      --===============================
      BEGIN
        SELECT  miuv.uom_code            AS uom_code                                   -- �P��
        INTO    lt_uom_code
        FROM    mtl_item_uoms_view  miuv
        WHERE   miuv.organization_id   = gn_inv_org_id
        AND     miuv.inventory_item_id = lt_inventory_item_id
        AND     miuv.uom_code          = g_item_work_tab(in_cnt)(cn_product_uom_code)  -- �P��
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => ct_xxcos_appl_short_name
                        ,iv_name          => ct_msg_cos_15373                               -- �P�ʃ}�X�^���݃G���[
                        ,iv_token_name1   => cv_tkn_line_no
                        ,iv_token_value1  => TO_CHAR( in_cnt, cv_format )                   -- �sNo
                        ,iv_token_name2   => cv_tkn_uom_code
                        ,iv_token_value2  => g_item_work_tab(in_cnt)(cn_product_uom_code)   -- �P��
                       );
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT
           ,buff  => lv_errmsg
          );
          lv_status := cv_status_warn;
      END;
    END IF;
--
    -- ��P�ʂ��uY�v�A�uNULL�v�ȊO�̏ꍇ
    IF ( g_item_work_tab(in_cnt)(cn_primary_uom_flag) IS NOT NULL
      AND  g_item_work_tab(in_cnt)(cn_primary_uom_flag) != cv_y ) THEN
      --===============================
      -- ��P�ʃ`�F�b�N
      --===============================
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => ct_xxcos_appl_short_name
                    ,iv_name          => ct_msg_cos_15374                             -- ��P�ʕs���G���[
                    ,iv_token_name1   => cv_tkn_line_no
                    ,iv_token_value1  => TO_CHAR( in_cnt, cv_format )                 -- �sNo
                    ,iv_token_name2   => cv_tkn_uom_flag
                    ,iv_token_value2  => g_item_work_tab(in_cnt)(cn_primary_uom_flag) -- ��P��
                   );
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => lv_errmsg
      );
      lv_status := cv_status_warn;
    END IF;
--
    -- �l���ݒ肳��Ă���ꍇ
    IF (  g_item_work_tab(in_cnt)(cn_operand) IS NOT NULL ) THEN
      --===============================
      -- ���l�`���`�F�b�N
      --===============================
      BEGIN
        -- ���l�`���`�F�b�N
        ln_number := TO_NUMBER( g_item_work_tab(in_cnt)(cn_operand) );
--
        --===============================
        -- �l�s���`�F�b�N
        --===============================
        IF (  ln_number < 0 ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => ct_xxcos_appl_short_name
                        ,iv_name          => ct_msg_cos_15376                      -- �l�s���G���[
                        ,iv_token_name1   => cv_tkn_line_no
                        ,iv_token_value1  => TO_CHAR( in_cnt, cv_format )          -- �sNo
                        ,iv_token_name2   => cv_tkn_value
                        ,iv_token_value2  => g_item_work_tab(in_cnt)(cn_operand)   -- �l
                       );
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT
           ,buff  => lv_errmsg
          );
          lv_status := cv_status_warn;
        END IF;
--
      EXCEPTION
        WHEN OTHERS THEN
          -- ���l�`���G���[
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => ct_xxcos_appl_short_name
                        ,iv_name          => ct_msg_cos_15367                    -- ���l�`���G���[
                        ,iv_token_name1   => cv_tkn_line_no
                        ,iv_token_value1  => TO_CHAR( in_cnt, cv_format )        -- �sNo
                        ,iv_token_name2   => cv_tkn_item
                        ,iv_token_value2  => ct_msg_cos_15360                    -- �l(���b�Z�[�W������)
                        ,iv_token_name3   => cv_tkn_item2
                        ,iv_token_value3  => ct_msg_cos_15360                    -- �l(���b�Z�[�W������)
                        ,iv_token_name4   => cv_tkn_value
                        ,iv_token_value4  => g_item_work_tab(in_cnt)(cn_operand) -- �l
                       );
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT
           ,buff  => lv_errmsg
          );
          lv_status := cv_status_warn;
      END;
    END IF;
--
    -- �J�n�����ݒ肳��Ă���ꍇ
    IF (  g_item_work_tab(in_cnt)(cn_start_date_active) IS NOT NULL ) THEN
      --===============================
      -- ���t�`���`�F�b�N
      --===============================
      BEGIN
         ld_start_date_active_l := TO_DATE( g_item_work_tab(in_cnt)(cn_start_date_active), cv_yyyy_mm_dd );
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => ct_xxcos_appl_short_name
                        ,iv_name          => ct_msg_cos_15369                              -- ���t�����G���[
                        ,iv_token_name1   => cv_tkn_line_no
                        ,iv_token_value1  => TO_CHAR( in_cnt, cv_format )                  -- �sNo
                        ,iv_token_name2   => cv_tkn_item
                        ,iv_token_value2  => ct_msg_cos_15363                              -- �J�n��(���b�Z�[�W������)
                        ,iv_token_name3   => cv_tkn_item2
                        ,iv_token_value3  => ct_msg_cos_15363                              -- �J�n��(���b�Z�[�W������)
                        ,iv_token_name4   => cv_tkn_date
                        ,iv_token_value4  => g_item_work_tab(in_cnt)(cn_start_date_active) -- �J�n��
                       );
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT
           ,buff  => lv_errmsg
          );
          lv_status := cv_status_warn;
          ld_start_date_active_l := NULL;
      END;
    END IF;
--
    -- �I�������ݒ肳��Ă���ꍇ
    IF (  g_item_work_tab(in_cnt)(cn_end_date_active) IS NOT NULL ) THEN
      --===============================
      -- ���t�`���`�F�b�N
      --===============================
      BEGIN
         ld_end_date_active_l := TO_DATE( g_item_work_tab(in_cnt)(cn_end_date_active), cv_yyyy_mm_dd );
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => ct_xxcos_appl_short_name
                        ,iv_name          => ct_msg_cos_15369                             -- ���t�����G���[
                        ,iv_token_name1   => cv_tkn_line_no
                        ,iv_token_value1  => TO_CHAR( in_cnt, cv_format )                 -- �sNo
                        ,iv_token_name2   => cv_tkn_item
                        ,iv_token_value2  => ct_msg_cos_15364                             -- �I����(���b�Z�[�W������)
                        ,iv_token_name3   => cv_tkn_item2
                        ,iv_token_value3  => ct_msg_cos_15364                             -- �I����(���b�Z�[�W������)
                        ,iv_token_name4   => cv_tkn_date
                        ,iv_token_value4  => g_item_work_tab(in_cnt)(cn_end_date_active)  -- �I����
                       );
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT
           ,buff  => lv_errmsg
          );
          lv_status  := cv_status_warn;
          ld_end_date_active_l := NULL;
      END;
    END IF;
--
    IF (  ld_start_date_active_l IS NOT NULL
      AND ld_end_date_active_l IS NOT NULL ) THEN
       --===============================
       -- ���t�t�]�`�F�b�N
       --===============================
       IF ( ld_start_date_active_l > ld_end_date_active_l ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => ct_xxcos_appl_short_name
                      ,iv_name          => ct_msg_cos_15370                              -- ���t�t�]�G���[
                      ,iv_token_name1   => cv_tkn_line_no
                      ,iv_token_value1  => TO_CHAR( in_cnt, cv_format )                  -- �sNo
                      ,iv_token_name2   => cv_tkn_start_date
                      ,iv_token_value2  => ct_msg_cos_15363                              -- �J�n��(���b�Z�[�W������)
                      ,iv_token_name3   => cv_tkn_end_date
                      ,iv_token_value3  => ct_msg_cos_15364                              -- �I����(���b�Z�[�W������)
                      ,iv_token_name4   => cv_tkn_start_date2
                      ,iv_token_value4  => ct_msg_cos_15363                              -- �J�n��(���b�Z�[�W������)
                      ,iv_token_name5   => cv_tkn_date_from
                      ,iv_token_value5  => g_item_work_tab(in_cnt)(cn_start_date_active) -- �J�n��
                      ,iv_token_name6   => cv_tkn_end_date2
                      ,iv_token_value6  => ct_msg_cos_15364                              -- �I����(���b�Z�[�W������)
                      ,iv_token_name7   => cv_tkn_date_to
                      ,iv_token_value7  => g_item_work_tab(in_cnt)(cn_end_date_active)   -- �I����
                     );
        FND_FILE.PUT_LINE(
          which => FND_FILE.OUTPUT
         ,buff  => lv_errmsg
        );
        lv_status := cv_status_warn;
       END IF;
    END IF;
--
    -- �D�悪�ݒ肳��Ă���ꍇ
    IF (  g_item_work_tab(in_cnt)(cn_product_precedence) IS NOT NULL ) THEN
      --===============================
      -- ���l�`���`�F�b�N
      --===============================
      BEGIN
        -- ���l�`���`�F�b�N
        ln_number := TO_NUMBER( g_item_work_tab(in_cnt)(cn_product_precedence) );
      EXCEPTION
        WHEN OTHERS THEN
          -- ���l�`���G���[
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => ct_xxcos_appl_short_name
                        ,iv_name          => ct_msg_cos_15367                               -- ���l�`���G���[
                        ,iv_token_name1   => cv_tkn_line_no
                        ,iv_token_value1  => TO_CHAR( in_cnt, cv_format )                   -- �sNo
                        ,iv_token_name2   => cv_tkn_item
                        ,iv_token_value2  => ct_msg_cos_15383                               -- �D��(���b�Z�[�W������)
                        ,iv_token_name3   => cv_tkn_item2
                        ,iv_token_value3  => ct_msg_cos_15383                               -- �D��(���b�Z�[�W������)
                        ,iv_token_name4   => cv_tkn_value
                        ,iv_token_value4  => g_item_work_tab(in_cnt)(cn_product_precedence) -- �D��
                       );
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT
           ,buff  => lv_errmsg
          );
          lv_status := cv_status_warn;
      END;
    END IF;
--
    --===============================
    -- �w�b�_ID,ORG_ID�擾
    --===============================
    BEGIN
      SELECT qlht.list_header_id    AS list_header_id,      -- �w�b�_�[ID
             qlhb.orig_org_id       AS orig_org_id,         -- ORG_ID
             qlhb.attribute1        AS base_code            -- ���_
      INTO   lt_list_header_id,
             lt_orig_org_id,
             lt_header_base_code
      FROM   qp_list_headers_tl qlht,
             qp_list_headers_b  qlhb
      WHERE  qlht.name     = g_item_work_tab(in_cnt)(cn_name)
      AND    qlht.language = ct_lang
      AND    qlht.list_header_id = qlhb.list_header_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lt_list_header_id   := NULL;
        lt_orig_org_id      := NULL;
        lt_header_base_code := NULL;
    END;
--
    -- �����敪���uI���o�^�v
    IF ( g_item_work_tab(in_cnt)(cn_proc_kbn) = cv_i ) THEN
      --===============================
      -- �d���`�F�b�N(�t�@�C����)
      --===============================
      SELECT COUNT(1) AS cnt
      INTO   ln_chk_cnt
      FROM   xxcos_tmp_price_lists  xtpl     -- ���i�\�ꎞ�\
      WHERE  xtpl.name                = g_item_work_tab(in_cnt)(cn_name)                  -- ����
      AND    xtpl.product_attr_value  = lt_inventory_item_id                              -- ���i�l(�i��ID)
      AND    xtpl.product_uom_code    = g_item_work_tab(in_cnt)(cn_product_uom_code)      -- �P��
      AND    ( NVL( ld_start_date_active_l, gd_min_date)  BETWEEN NVL( xtpl.start_date_active_l, gd_min_date) AND NVL( xtpl.end_date_active_l,gd_max_date)   -- �J�n��
               OR NVL( ld_end_date_active_l,gd_max_date)  BETWEEN NVL( xtpl.start_date_active_l, gd_min_date) AND NVL( xtpl.end_date_active_l,gd_max_date)   -- �I����
             OR ( NVL( xtpl.start_date_active_l, gd_min_date)  BETWEEN NVL( ld_start_date_active_l, gd_min_date) AND NVL( ld_end_date_active_l,gd_max_date)  -- �J�n��
               OR NVL( xtpl.end_date_active_l,gd_max_date)     BETWEEN NVL( ld_start_date_active_l, gd_min_date) AND NVL( ld_end_date_active_l,gd_max_date)) -- �I����
             )
      ;
--
      IF ( ln_chk_cnt > 0 ) THEN
          -- �d���G���[(�t�@�C����)
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => ct_xxcos_appl_short_name
                        ,iv_name          => ct_msg_cos_15378                               -- �d���G���[(�t�@�C����)
                        ,iv_token_name1   => cv_tkn_line_no
                        ,iv_token_value1  => TO_CHAR( in_cnt, cv_format )                   -- �sNo
                        ,iv_token_name2   => cv_tkn_name
                        ,iv_token_value2  => g_item_work_tab(in_cnt)(cn_name)               -- ����
                        ,iv_token_name3   => cv_tkn_item_code
                        ,iv_token_value3  => g_item_work_tab(in_cnt)(cn_product_attr_value) -- ���i�l
                        ,iv_token_name4   => cv_tkn_uom_code
                        ,iv_token_value4  => g_item_work_tab(in_cnt)(cn_product_uom_code)   -- �P��
                        ,iv_token_name5   => cv_tkn_start_date
                        ,iv_token_value5  => g_item_work_tab(in_cnt)(cn_start_date_active)  -- �J�n��
                        ,iv_token_name6   => cv_tkn_end_date
                        ,iv_token_value6  => g_item_work_tab(in_cnt)(cn_end_date_active)    -- �I����
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
      --===============================
      -- �d���G���[(�o�^��)
      --===============================
      SELECT COUNT(1) AS cnt
      INTO   ln_chk_cnt
      FROM   qp_list_lines         line,
             qp_pricing_attributes attr
      WHERE  line.list_header_id      = lt_list_header_id
      AND    line.list_header_id      = attr.list_header_id
      AND    line.list_line_id        = attr.list_line_id
      AND    attr.product_attr_value  = lt_inventory_item_id                              -- ���i�l(�i��ID)
      AND    attr.product_uom_code    = g_item_work_tab(in_cnt)(cn_product_uom_code)      -- �P��
      AND    ( NVL( ld_start_date_active_l, gd_min_date)  BETWEEN NVL( line.start_date_active, gd_min_date) AND NVL( line.end_date_active,gd_max_date)   -- �J�n��
               OR NVL( ld_end_date_active_l,gd_max_date)  BETWEEN NVL( line.start_date_active, gd_min_date) AND NVL( line.end_date_active,gd_max_date)   -- �I����
             OR ( NVL( line.start_date_active, gd_min_date)  BETWEEN NVL( ld_start_date_active_l, gd_min_date) AND NVL( ld_end_date_active_l,gd_max_date)  -- �J�n��
               OR NVL( line.end_date_active,gd_max_date)     BETWEEN NVL( ld_start_date_active_l, gd_min_date) AND NVL( ld_end_date_active_l,gd_max_date)) -- �I����
             )
      ;
--
      -- ���i�\�ɑ��݂��Ă���
      IF ( ln_chk_cnt > 0 ) THEN
        -- �ϐ�������
        ln_chk_cnt := 0;
--
        -- ���i�\�ꎞ�\�ɍX�V�f�[�^�����݂��邩
        SELECT COUNT(1) AS cnt
        INTO   ln_chk_cnt
        FROM   xxcos_tmp_price_lists  xtpl     -- ���i�\�ꎞ�\
        WHERE  xtpl.proc_kbn            = cv_u                                              -- �����敪
        AND    xtpl.name                = g_item_work_tab(in_cnt)(cn_name)                  -- ����
        AND    xtpl.product_attr_value  = lt_inventory_item_id                              -- ���i�l(�i��ID)
        AND    xtpl.product_uom_code    = g_item_work_tab(in_cnt)(cn_product_uom_code)      -- �P��
        ;
--
        IF ( ln_chk_cnt = 0) THEN
          -- ���i�\�ꎞ�\�Ɋ��Ԃ��X�V����f�[�^�����݂��Ȃ�
          -- �d���G���[(�o�^��)
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => ct_xxcos_appl_short_name
                        ,iv_name          => ct_msg_cos_15379                               -- �d���G���[(�o�^��)
                        ,iv_token_name1   => cv_tkn_line_no
                        ,iv_token_value1  => TO_CHAR( in_cnt, cv_format )                   -- �sNo
                        ,iv_token_name2   => cv_tkn_name
                        ,iv_token_value2  => g_item_work_tab(in_cnt)(cn_name)               -- ����
                        ,iv_token_name3   => cv_tkn_item_code
                        ,iv_token_value3  => g_item_work_tab(in_cnt)(cn_product_attr_value) -- ���i�l
                        ,iv_token_name4   => cv_tkn_uom_code
                        ,iv_token_value4  => g_item_work_tab(in_cnt)(cn_product_uom_code)   -- �P��
                        ,iv_token_name5   => cv_tkn_start_date
                        ,iv_token_value5  => g_item_work_tab(in_cnt)(cn_start_date_active)  -- �J�n��
                        ,iv_token_name6   => cv_tkn_end_date
                        ,iv_token_value6  => g_item_work_tab(in_cnt)(cn_end_date_active)    -- �I����
                       );
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT
           ,buff  => lv_errmsg
          );
          lv_status := cv_status_warn;
        END IF;
      END IF;
--
    -- �����敪���uU���X�V�v
    ELSIF ( g_item_work_tab(in_cnt)(cn_proc_kbn) = cv_u ) THEN
      --===============================
      -- �X�V�Ώۃ`�F�b�N
      --===============================
      -- �X�V�Ώۂ̖���ID�擾
      BEGIN
        SELECT line.list_line_id     AS list_line_id
        INTO   lt_list_line_id
        FROM   qp_list_lines         line,
               qp_pricing_attributes attr
        WHERE  line.list_header_id                       = lt_list_header_id
        AND    line.list_header_id                       = attr.list_header_id
        AND    line.list_line_id                         = attr.list_line_id
        AND    attr.product_attr_value                   = lt_inventory_item_id                          -- ���i�l(�i��ID)
        AND    attr.product_uom_code                     = g_item_work_tab(in_cnt)(cn_product_uom_code)  -- �P��
        AND    NVL( line.start_date_active, gd_min_date) = NVL( ld_start_date_active_l, gd_min_date)     -- �J�n��
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- �X�V�ΏۂȂ��G���[
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => ct_xxcos_appl_short_name
                        ,iv_name          => ct_msg_cos_15380                               -- �X�V�ΏۂȂ��G���[
                        ,iv_token_name1   => cv_tkn_line_no
                        ,iv_token_value1  => TO_CHAR( in_cnt, cv_format )                   -- �sNo
                        ,iv_token_name2   => cv_tkn_name
                        ,iv_token_value2  => g_item_work_tab(in_cnt)(cn_name)               -- ����
                        ,iv_token_name3   => cv_tkn_item_code
                        ,iv_token_value3  => g_item_work_tab(in_cnt)(cn_product_attr_value) -- ���i�l
                        ,iv_token_name4   => cv_tkn_uom_code
                        ,iv_token_value4  => g_item_work_tab(in_cnt)(cn_product_uom_code)   -- �P��
                       );
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT
           ,buff  => lv_errmsg
          );
          lv_status := cv_status_warn;
      END;
--
      --===============================
      -- �c�ƒP�ʃZ�L�����e�B�`�F�b�N
      --===============================
      -- �c�ƒP��(OU)���قȂ��Ă���
      IF ( gn_org_id <> lt_orig_org_id ) THEN
        -- �c�ƒP�ʃZ�L�����e�B�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => ct_xxcos_appl_short_name
                      ,iv_name          => ct_msg_cos_15377                -- �c�ƒP�ʃZ�L�����e�B�G���[
                      ,iv_token_name1   => cv_tkn_line_no
                      ,iv_token_value1  => TO_CHAR( in_cnt, cv_format )    -- �sNo
                     );
        FND_FILE.PUT_LINE(
          which => FND_FILE.OUTPUT
         ,buff  => lv_errmsg
        );
        lv_status := cv_status_warn;
      END IF;
--
      --===============================
      -- �X�V�Z�L�����e�B�`�F�b�N(���_)
      --===============================
      -- �S���_�ΏۈȊO�̏ꍇ
      IF ( gv_all_base_flg = cv_n ) THEN
        -- ���L���_�Ǝ����_���Ⴄ�ꍇ
        IF ( gv_login_user_base_code <> g_item_work_tab(in_cnt)(cn_attribute1) ) THEN
            -- ���O�C�����[�U���Ǘ������_
          BEGIN
            SELECT  xlbiv.base_code   AS base_code      -- ���_�R�[�h
            INTO    lt_base_code
            FROM    xxcos_login_base_info_v xlbiv
            WHERE   xlbiv.base_code   = lt_header_base_code  -- ���L���_�R�[�h
            ;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              -- ���L���_�Z�L�����e�B�G���[
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application   => ct_xxcos_appl_short_name
                            ,iv_name          => ct_msg_cos_15375                        -- ���L���_�Z�L�����e�B�G���[
                            ,iv_token_name1   => cv_tkn_line_no
                            ,iv_token_value1  => TO_CHAR( in_cnt, cv_format )            -- �sNo
                            ,iv_token_name2   => cv_tkn_base_code
                            ,iv_token_value2  => g_item_work_tab(in_cnt)(cn_attribute1)  -- ���L���_�R�[�h
                           );
              FND_FILE.PUT_LINE(
                which => FND_FILE.OUTPUT
               ,buff  => lv_errmsg
              );
              lv_status := cv_status_warn;
          END;
        END IF;
      END IF;
    END IF;
--
    -- �G���[���������Ă��Ȃ��ꍇ
    IF ( lv_status = cv_status_normal ) THEN
      --==================================
      -- �ꎞ�\�o�^����(A-5)
      --==================================
      ins_work_table(
        in_line_no              => in_cnt                  -- �sNo
       ,in_list_header_id       => lt_list_header_id       -- �w�b�_�[ID
       ,in_list_line_id         => lt_list_line_id         -- ����ID
       ,in_product_attr_value   => lt_inventory_item_id    -- ���i�l
       ,ov_errbuf               => lv_errbuf               -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode              => lv_retcode              -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg               => lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
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
  /**********************************************************************************
   * Procedure Name   : data_insert
   * Description      : ���i�\���f����(A-6)
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
    cv_list_type_code              VARCHAR2(3)   := 'PRL';
    cv_currency_code               VARCHAR2(3)   := 'JPY';
    cv_context                     VARCHAR2(4)   := '2424';
    cv_list_line_type_code         VARCHAR2(3)   := 'PLL';
    cv_arithmetic_operator         VARCHAR2(10)  := 'UNIT_PRICE';
    cv_product_attribute_context   VARCHAR2(4)   := 'ITEM';
    cv_product_attribute           VARCHAR2(18)  := 'PRICING_ATTRIBUTE1';
    cv_excluder_flag               VARCHAR2(1)   := 'N';
    cv_encoded                     VARCHAR2(1)   := 'F';
    cn_api_version_number          NUMBER        := 1;
    cn_index                       NUMBER        := 1;
--
    -- *** ���[�J���ϐ� ***
    ln_chk_cnt                     NUMBER;          -- �`�F�b�N����
    ln_del_cnt                     NUMBER;          -- �폜����
    lv_message                     VARCHAR2(32765); -- ���b�Z�[�W
    lv_status                      VARCHAR2(1);     -- �X�e�[�^�X
    lv_pre_status                  VARCHAR2(1);     -- �O���R�[�h�X�e�[�^�X
    lv_return_status               VARCHAR2(1);
    lv_msg_data                    VARCHAR2(2000);
    ln_msg_count                   NUMBER;
    lv_operation_header            VARCHAR2(10);    -- �������[�h(�w�b�_�[)
    lv_operation_line              VARCHAR2(10);    -- �������[�h(����)
    lv_operation_attr              VARCHAR2(10);    -- �������[�h(�A�g���r���[�g)
    lt_list_header_id              qp_list_headers_tl.list_header_id%TYPE;           -- �w�b�_�[ID
    lt_list_line_id                qp_list_lines.list_line_id%TYPE;                  -- ����ID
    lt_pricing_attribute_id        qp_pricing_attributes.pricing_attribute_id%TYPE;  -- ����ID
    --API Specific Parameters.
    lt_price_list_rec              qp_price_list_pub.price_list_rec_type;
    lt_price_list_line_tbl         qp_price_list_pub.price_list_line_tbl_type;
    lt_pricing_attr_tbl            qp_price_list_pub.pricing_attr_tbl_type;
    lt_ppr_price_list_rec          qp_price_list_pub.price_list_rec_type;
    lt_price_list_val_rec          qp_price_list_pub.price_list_val_rec_type;
    lt_ppr_price_list_line_tbl     qp_price_list_pub.price_list_line_tbl_type;
    lt_price_list_line_val_tbl     qp_price_list_pub.price_list_line_val_tbl_type;
    lt_qualifiers_tbl              qp_qualifier_rules_pub.qualifiers_tbl_type;
    lt_qualifiers_val_tbl          qp_qualifier_rules_pub.qualifiers_val_tbl_type;
    lt_ppr_pricing_attr_tbl        qp_price_list_pub.pricing_attr_tbl_type;
    lt_pricing_attr_val_tbl        qp_price_list_pub.pricing_attr_val_tbl_type;
    -- *** ���[�J���E�J�[�\�� ***
--
    -- ���i�\�ꎞ�\�擾�J�[�\��
    CURSOR get_price_lists_cur
    IS
      SELECT 
             xtpl.line_no                AS line_no              -- �sNo
            ,xtpl.proc_kbn               AS proc_kbn             -- �����敪
            ,xtpl.name                   AS name                 -- ����
            ,xtpl.active_flag            AS active_flag          -- �L��
            ,xtpl.description            AS description          -- �E�v
            ,xtpl.rounding_factor        AS rounding_factor      -- �ۂߏ�����
            ,xtpl.start_date_active_h    AS start_date_active_h  -- �L����FROM
            ,xtpl.end_date_active_h      AS end_date_active_h    -- �L����TO
            ,xtpl.comments               AS comments             -- ����
            ,xtpl.base_code              AS base_code            -- ���L���_
            ,xtpl.product_attr_value     AS product_attr_value   -- ���i�l
            ,xtpl.product_uom_code       AS product_uom_code     -- �P��
            ,xtpl.primary_uom_flag       AS primary_uom_flag     -- ��P��
            ,xtpl.operand                AS operand              -- �l
            ,xtpl.start_date_active_l    AS start_date_active_l  -- �J�n��
            ,xtpl.end_date_active_l      AS end_date_active_l    -- �I����
            ,xtpl.product_precedence     AS product_precedence   -- �D��
            ,xtpl.list_header_id         AS list_header_id       -- �w�b�_�[ID
            ,xtpl.list_line_id           AS list_line_id         -- ����ID
      FROM   xxcos_tmp_price_lists  xtpl                         -- ���i�\�ꎞ�\
      ORDER BY
             xtpl.line_no                                        -- �sNo
      ;
--
    -- �J�[�\�����R�[�h�^
    get_price_lists_rec  get_price_lists_cur%ROWTYPE;
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
--
    -- �J�[�\���擾
    <<main_loop>>
    FOR get_price_lists_rec IN get_price_lists_cur LOOP
--
      -- �ϐ�������
      lv_status  := cv_status_normal; -- �X�e�[�^�X
      ln_chk_cnt := 0;  -- �`�F�b�N����
      ln_del_cnt := 0;  -- �폜����
--
      IF ( get_price_lists_rec.proc_kbn = cv_i ) THEN
        --===============================
        -- �w�b�_ID�擾
        --===============================
        BEGIN
          SELECT qlht.list_header_id    AS list_header_id      -- �w�b�_�[ID
          INTO   lt_list_header_id
          FROM   qp_list_headers_tl qlht
          WHERE  qlht.name        = get_price_lists_rec.name   -- ����
          AND    qlht.language    = ct_lang
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            lt_list_header_id := NULL;
        END;
--
        IF ( lt_list_header_id IS NULL ) THEN
          --  �w�b�_�[�A���גǉ�
          lv_operation_header        := qp_globals.g_opr_create;                  -- �������[�h(�w�b�_�[)
          lv_operation_line          := qp_globals.g_opr_create;                  -- �������[�h(����)
          lv_operation_attr          := qp_globals.g_opr_create;                  -- �������[�h(�A�g���r���[�g)
          --
          lt_list_header_id          := fnd_api.g_miss_num;                       -- �w�b�_�[ID
          lt_list_line_id            := fnd_api.g_miss_num;                       -- ����ID
          lt_pricing_attribute_id    := fnd_api.g_miss_num;                       -- ����ID
        ELSE
          -- �w�b�_�[�o�^�ςŖ��גǉ�
          lv_operation_header        := qp_globals.g_opr_update;                  -- �������[�h(�w�b�_�[)
          lv_operation_line          := qp_globals.g_opr_create;                  -- �������[�h(����)
          lv_operation_attr          := qp_globals.g_opr_create;                  -- �������[�h(�A�g���r���[�g)
          --
          lt_list_line_id            := fnd_api.g_miss_num;                       -- ����ID
          lt_pricing_attribute_id    := fnd_api.g_miss_num;                       -- ����ID
        END IF;
      ELSIF ( get_price_lists_rec.proc_kbn = cv_u ) THEN
        lv_operation_header          := qp_globals.g_opr_update;                  -- �������[�h(�w�b�_�[)
        lv_operation_line            := qp_globals.g_opr_update;                  -- �������[�h(����)
        lv_operation_attr            := qp_globals.g_opr_update;                  -- �������[�h(�A�g���r���[�g)
        --
        lt_list_header_id            := get_price_lists_rec.list_header_id;       -- �w�b�_�[ID
        lt_list_line_id              := get_price_lists_rec.list_line_id;         -- ����ID
      END IF;
--
      -- Price List Header
      lt_price_list_rec.list_header_id                           := lt_list_header_id;
      lt_price_list_rec.name                                     := get_price_lists_rec.name;
      lt_price_list_rec.list_type_code                           := cv_list_type_code;
      lt_price_list_rec.description                              := get_price_lists_rec.description;
      lt_price_list_rec.currency_code                            := cv_currency_code;
      lt_price_list_rec.rounding_factor                          := get_price_lists_rec.rounding_factor;
      lt_price_list_rec.comments                                 := get_price_lists_rec.comments;
      lt_price_list_rec.end_date_active                          := get_price_lists_rec.end_date_active_h;
      lt_price_list_rec.start_date_active                        := get_price_lists_rec.start_date_active_h;
      lt_price_list_rec.active_flag                              := get_price_lists_rec.active_flag;
      lt_price_list_rec.attribute1                               := get_price_lists_rec.base_code;
      lt_price_list_rec.context                                  := cv_context;
      lt_price_list_rec.operation                                := lv_operation_header;
      -- Price List Line
      lt_price_list_line_tbl( cn_index ).list_line_id            := lt_list_line_id;
      lt_price_list_line_tbl( cn_index ).list_line_type_code     := cv_list_line_type_code;
      lt_price_list_line_tbl( cn_index ).operation               := lv_operation_line;
      lt_price_list_line_tbl( cn_index ).operand                 := get_price_lists_rec.operand;
      lt_price_list_line_tbl( cn_index ).arithmetic_operator     := cv_arithmetic_operator;
      lt_price_list_line_tbl( cn_index ).end_date_active         := get_price_lists_rec.end_date_active_l;
      lt_price_list_line_tbl( cn_index ).start_date_active       := get_price_lists_rec.start_date_active_l;
      lt_price_list_line_tbl( cn_index ).primary_uom_flag        := get_price_lists_rec.primary_uom_flag;
      lt_price_list_line_tbl( cn_index ).product_precedence      := get_price_lists_rec.product_precedence;
--
      IF ( get_price_lists_rec.proc_kbn = cv_i ) THEN
        -- Product Attributes
        lt_pricing_attr_tbl( cn_index ).pricing_attribute_id       := lt_pricing_attribute_id;
        lt_pricing_attr_tbl( cn_index ).list_line_id               := lt_list_line_id;
        lt_pricing_attr_tbl( cn_index ).product_attribute_context  := cv_product_attribute_context;
        lt_pricing_attr_tbl( cn_index ).product_attribute          := cv_product_attribute;
        lt_pricing_attr_tbl( cn_index ).product_attr_value         := get_price_lists_rec.product_attr_value;
        lt_pricing_attr_tbl( cn_index ).product_uom_code           := get_price_lists_rec.product_uom_code;
        lt_pricing_attr_tbl( cn_index ).excluder_flag              := cv_excluder_flag;
        lt_pricing_attr_tbl( cn_index ).attribute_grouping_no      := fnd_api.g_miss_num;
        lt_pricing_attr_tbl( cn_index ).price_list_line_index      := cn_index;
        lt_pricing_attr_tbl( cn_index ).operation                  := lv_operation_attr;
      END IF;
--
      -- Call QP_PRICE_LIST_PUB.PROCESS_PRICE_LIST API
      qp_price_list_pub.process_price_list(
        p_api_version_number            => cn_api_version_number
      , p_init_msg_list                 => fnd_api.g_false
      , p_return_values                 => fnd_api.g_false
      , p_commit                        => fnd_api.g_false
      , x_return_status                 => lv_retcode
      , x_msg_count                     => ln_msg_count
      , x_msg_data                      => lv_msg_data
      , p_price_list_rec                => lt_price_list_rec
      , p_price_list_line_tbl           => lt_price_list_line_tbl
      , p_pricing_attr_tbl              => lt_pricing_attr_tbl
      , x_price_list_rec                => lt_ppr_price_list_rec
      , x_price_list_val_rec            => lt_price_list_val_rec
      , x_price_list_line_tbl           => lt_ppr_price_list_line_tbl
      , x_price_list_line_val_tbl       => lt_price_list_line_val_tbl
      , x_qualifiers_tbl                => lt_qualifiers_tbl
      , x_qualifiers_val_tbl            => lt_qualifiers_val_tbl
      , x_pricing_attr_tbl              => lt_ppr_pricing_attr_tbl
      , x_pricing_attr_val_tbl          => lt_pricing_attr_val_tbl
      );
      -- API���G���[
      IF ( ln_msg_count > 0 ) THEN
        FOR l_index IN 1..ln_msg_count LOOP
         lv_msg_data := SUBSTRB( oe_msg_pub.get( p_msg_index => l_index
                                                ,p_encoded   => cv_encoded
                                               ),1 ,2000
                                );
         --
         lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => ct_xxcos_appl_short_name
                       ,iv_name         => ct_msg_cos_15382                                  -- �ꎞ�\�o�^�G���[
                       ,iv_token_name1  => cv_tkn_line_no
                       ,iv_token_value1 => TO_CHAR( get_price_lists_rec.line_no, cv_format ) -- �sNo
                       ,iv_token_name2  => cv_tkn_err_msg
                       ,iv_token_value2 => lv_msg_data                                       -- �G���[���e
                      );
         lv_errbuf := lv_errmsg;
         RAISE global_api_expt;
        END LOOP;
      END IF;
--
      -- �z��̃N���A
      lt_price_list_rec.list_header_id     := NULL;
      lt_price_list_rec.name               := NULL;
      lt_price_list_rec.description        := NULL;
      lt_price_list_rec.rounding_factor    := NULL;
      lt_price_list_rec.comments           := NULL;
      lt_price_list_rec.end_date_active    := NULL;
      lt_price_list_rec.start_date_active  := NULL;
      lt_price_list_rec.active_flag        := NULL;
      lt_price_list_rec.attribute1         := NULL;
      lt_price_list_line_tbl.DELETE;
      lt_pricing_attr_tbl.DELETE;
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
      --==================================
      -- �t�@�C���A�b�v���[�hIF�f�[�^�폜����
      --==================================
      BEGIN
        DELETE FROM xxccp_mrp_file_ul_interface xmfui
        WHERE xmfui.file_id = in_get_file_id
        ;
        COMMIT;
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
          lv_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
          RAISE global_process_expt;
      END;
--
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
      --==================================
      -- ���i�\���f����(A-6)
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
END XXCOS005A11C;
/
