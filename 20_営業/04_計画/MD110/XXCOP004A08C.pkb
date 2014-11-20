CREATE OR REPLACE PACKAGE BODY APPS.XXCOP004A08C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOP004A08C(body)
 * Description      : �A�b�v���[�h�t�@�C������̓o�^�i�i�ڃR�[�h�W��}�X�^�j
 * MD.050           : MD050_COP_004_A08_�A�b�v���[�h�t�@�C������̓o�^�i�i�ڃR�[�h�W��}�X�^�j
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  del_mst_sum_item_code  �i�ڃR�[�h�W��}�X�^�폜����(A-2)
 *  get_file_upload_data   �t�@�C���A�b�v���[�h�f�[�^�擾����(A-3)
 *  chk_validate_item      �Ó����`�F�b�N����(A-4)
 *  ins_mst_sum_item_code  �i�ڃR�[�h�W��}�X�^�o�^����(A-5)
 *  del_file_upload_data   �t�@�C���A�b�v���[�h�f�[�^�폜����(A-6)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                           �I������(A-7)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2013/10/31    1.0   K.Nakamura       �V�K�쐬
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
  global_lock_expt          EXCEPTION; -- ���b�N��O
  global_chk_item_expt      EXCEPTION; -- �Ó����`�F�b�N��O
--
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                 CONSTANT VARCHAR2(20) := 'XXCOP004A08C';     -- �p�b�P�[�W��
  -- �A�v���P�[�V�����Z�k��
  cv_application              CONSTANT VARCHAR2(5)  := 'XXCOP';            -- �A�v���P�[�V����
  -- �v���t�@�C��
  cv_master_org_id            CONSTANT VARCHAR2(30) := 'XXCMN_MASTER_ORG_ID';     -- �}�X�^�g�DID
  cv_policy_group_code        CONSTANT VARCHAR2(30) := 'XXCMN_POLICY_GROUP_CODE'; -- �J�e�S���Z�b�g��(����Q�R�[�h)
  -- �N�C�b�N�R�[�h
  cv_mst_group_item           CONSTANT VARCHAR2(30) := 'XXCOP1_MST_GROUP_ITEM';  -- �i�ڃR�[�h�W��}�X�^���ڃ`�F�b�N
  cv_use_kbn                  CONSTANT VARCHAR2(30) := 'XXCOP1_USE_KBN';         -- �g�p�敪
  cv_file_upload_obj          CONSTANT VARCHAR2(30) := 'XXCCP1_FILE_UPLOAD_OBJ'; -- �t�@�C���A�b�v���[�h���
  -- ���b�Z�[�W
  cv_msg_xxcop_00002          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00002'; -- �v���t�@�C���l�擾���s�G���[
  cv_msg_xxcop_00006          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00006'; -- �N�C�b�N�R�[�h�擾�G���[���b�Z�[�W
  cv_msg_xxcop_00007          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00007'; -- �e�[�u�����b�N�G���[���b�Z�[�W
  cv_msg_xxcop_00014          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00014'; -- �S�����_�Ȃ�
  cv_msg_xxcop_00027          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00027'; -- �o�^�����G���[���b�Z�[�W
  cv_msg_xxcop_00032          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00032'; -- �A�b�v���[�hIF�擾�G���[���b�Z�[�W
  cv_msg_xxcop_00036          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00036'; -- �A�b�v���[�h�t�@�C���o�̓��b�Z�[�W
  cv_msg_xxcop_00042          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00042'; -- �폜�����G���[���b�Z�[�W
  cv_msg_xxcop_00065          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00065'; -- �Ɩ����t�擾�G���[���b�Z�[�W
  cv_msg_xxcop_00069          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00069'; -- �t�H�[�}�b�g�`�F�b�N�G���[
  cv_msg_xxcop_00070          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00070'; -- �s���`�F�b�N�G���[
  cv_msg_xxcop_00072          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00072'; -- �S�����_�`�F�b�N�G���[
  cv_msg_xxcop_00078          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00078'; -- ��s���b�Z�[�W
  cv_msg_xxcop_10059          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-10059'; -- �W��R�[�h���݃`�F�b�N�G���[
  cv_msg_xxcop_10060          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-10060'; -- �i�ڃR�[�h���݃`�F�b�N�G���[
  cv_msg_xxcop_10061          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-10061'; -- CSV���d���`�F�b�N�G���[1
  cv_msg_xxcop_10062          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-10062'; -- CSV���d���`�F�b�N�G���[2
  cv_msg_xxcop_10063          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-10063'; -- �i�ڃR�[�h�W��}�X�^���݃`�F�b�N�G���[
  cv_msg_xxcop_10067          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-10067'; -- �g�p�敪���݃G���[
  cv_msg_xxcop_10070          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-10070'; -- �g�p�敪�`�F�b�N�G���[
  cv_msg_xxcop_10071          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-10071'; -- ����Q�R�[�h�������`�F�b�N�G���[
  -- �g�[�N���l
  cv_msg_xxcop_00079          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00079'; -- �t�@�C���A�b�v���[�hIF�\
  cv_msg_xxcop_00083          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00083'; -- �i�ڃR�[�h�W��}�X�^
  -- �g�[�N���R�[�h
  cv_tkn_errmsg               CONSTANT VARCHAR2(20) := 'ERRMSG';           -- �G���[���b�Z�[�W
  cv_tkn_fileid               CONSTANT VARCHAR2(20) := 'FILEID';           -- �t�@�C��ID
  cv_tkn_file_id              CONSTANT VARCHAR2(20) := 'FILE_ID';          -- �t�@�C��ID
  cv_tkn_file                 CONSTANT VARCHAR2(20) := 'FILE';             -- �t�@�C������
  cv_tkn_file_name            CONSTANT VARCHAR2(20) := 'FILE_NAME';        -- �t�@�C������
  cv_tkn_format               CONSTANT VARCHAR2(20) := 'FORMAT';           -- �t�H�[�}�b�g�p�^�[��
  cv_tkn_format_ptn           CONSTANT VARCHAR2(20) := 'FORMAT_PTN';       -- �t�H�[�}�b�g�p�^�[��
  cv_tkn_item                 CONSTANT VARCHAR2(20) := 'ITEM';             -- ����
  cv_tkn_profile              CONSTANT VARCHAR2(20) := 'PROF_NAME';        -- �v���t�@�C��
  cv_tkn_row                  CONSTANT VARCHAR2(20) := 'ROW';              -- �s��
  cv_tkn_table                CONSTANT VARCHAR2(20) := 'TABLE';            -- �e�[�u����
  cv_tkn_upload_object        CONSTANT VARCHAR2(20) := 'UPLOAD_OBJECT';    -- �t�@�C���A�b�v���[�h����
  cv_tkn_user                 CONSTANT VARCHAR2(20) := 'USER';             -- ���[�UID
  cv_tkn_value                CONSTANT VARCHAR2(20) := 'VALUE';            -- ���ڒl
  cv_tkn_value1               CONSTANT VARCHAR2(20) := 'VALUE1';           -- ���ڒl
  cv_tkn_value2               CONSTANT VARCHAR2(20) := 'VALUE2';           -- ���ڒl
  cv_tkn_value3               CONSTANT VARCHAR2(20) := 'VALUE3';           -- ���ڒl
  cv_tkn_value4               CONSTANT VARCHAR2(20) := 'VALUE4';           -- ���ڒl
  --
  cv_flag_y                   CONSTANT VARCHAR2(1)  := 'Y';                -- 'Y'
  ct_lang                     CONSTANT fnd_lookup_values.language%TYPE
                                                    := USERENV('LANG');    -- ����
  -- ������
  cv_comma                    CONSTANT VARCHAR2(1)  := ',';                -- ������؂�
  cv_dobule_quote             CONSTANT VARCHAR2(1)  := '"';                -- ��������
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ���ڃ`�F�b�N�i�[���R�[�h
  TYPE g_chk_item_rtype IS RECORD(
      meaning                 fnd_lookup_values.meaning%TYPE    -- ���ږ���
    , attribute1              fnd_lookup_values.attribute1%TYPE -- ���ڂ̒���
    , attribute2              fnd_lookup_values.attribute2%TYPE -- ���ڂ̒����i�����_�ȉ��j
    , attribute3              fnd_lookup_values.attribute3%TYPE -- �K�{�t���O
    , attribute4              fnd_lookup_values.attribute4%TYPE -- ����
  );
  -- �e�[�u���^�C�v
  TYPE g_chk_item_ttype       IS TABLE OF g_chk_item_rtype INDEX BY PLS_INTEGER;
  -- �e�[�u���^
  gt_file_data_all            xxccp_common_pkg2.g_file_data_tbl; -- �ϊ���VARCHAR2�f�[�^
  gt_csv_tab                  xxcop_common_pkg.g_char_ttype;     -- �������ʁi�������菜����j
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_base_code                VARCHAR2(4)                                 DEFAULT NULL;  -- �S�����_�R�[�h
  gv_tkn_1                    VARCHAR2(5000)                              DEFAULT NULL;  -- �G���[���b�Z�[�W�p�g�[�N��1
  gn_delete_cnt               NUMBER                                      DEFAULT 0;     -- �폜����
  gn_insert_cnt               NUMBER                                      DEFAULT 0;     -- �o�^����
  gn_item_cnt                 NUMBER                                      DEFAULT 0;     -- CSV���ڐ�
  gn_record_cnt               NUMBER                                      DEFAULT 0;     -- CSV���R�[�h�J�E���^
  gd_process_date             DATE                                        DEFAULT NULL;  -- �Ɩ����t
  gb_crowd_class_code_flag    BOOLEAN                                     DEFAULT FALSE; -- ����Q�R�[�h�������`�F�b�N�t���O
  gt_master_org_id            mtl_parameters.organization_id%TYPE         DEFAULT NULL;  -- �}�X�^�g�DID
  gt_policy_group_code        mtl_category_sets_vl.category_set_name%TYPE DEFAULT NULL;  -- �J�e�S���Z�b�g��(����Q�R�[�h)
  gt_upload_name              fnd_lookup_values.meaning%TYPE              DEFAULT NULL;  -- �t�@�C���A�b�v���[�h����
  gt_use_kbn                  fnd_lookup_values.lookup_code%TYPE          DEFAULT NULL;  -- �g�p�敪
  -- �e�[�u���ϐ�
  g_chk_item_tab              g_chk_item_ttype;                                 -- ���ڃ`�F�b�N
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
      iv_file_id IN  VARCHAR2 -- �t�@�C��ID
    , iv_format  IN  VARCHAR2 -- �t�H�[�}�b�g�p�^�[��
    , ov_errbuf  OUT VARCHAR2 -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode OUT VARCHAR2 -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg  OUT VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- *** ���[�J���ϐ� ***
    lt_file_name              xxccp_mrp_file_ul_interface.file_name%TYPE;     -- �t�@�C����
    lt_upload_date            xxccp_mrp_file_ul_interface.creation_date%TYPE; -- �A�b�v���[�h����
--
    -- *** ���[�J���J�[�\�� ***
    -- ���ڃ`�F�b�N�J�[�\��
    CURSOR chk_item_cur
    IS
      SELECT flv.meaning       AS meaning     -- ���ږ���
           , flv.attribute1    AS attribute1  -- ���ڂ̒���
           , flv.attribute2    AS attribute2  -- ���ڂ̒����i�����_�ȉ��j
           , flv.attribute3    AS attribute3  -- �K�{�t���O
           , flv.attribute4    AS attribute4  -- ����
      FROM   fnd_lookup_values flv
      WHERE  flv.lookup_type  = cv_mst_group_item
      AND    gd_process_date BETWEEN NVL( flv.start_date_active, gd_process_date )
                             AND     NVL( flv.end_date_active, gd_process_date )
      AND    flv.enabled_flag = cv_flag_y
      AND    flv.language     = ct_lang
      ORDER BY flv.lookup_code
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
    --==============================================================
    -- 1�D�t�@�C���A�b�v���[�h�e�[�u�����擾
    --==============================================================
    xxcop_common_pkg.get_upload_table_info(
        in_file_id     => TO_NUMBER(iv_file_id) -- �t�@�C��ID
      , iv_format      => iv_format             -- �t�H�[�}�b�g�p�^�[��
      , ov_upload_name => gt_upload_name        -- �t�@�C���A�b�v���[�h����
      , ov_file_name   => lt_file_name          -- �t�@�C����
      , od_upload_date => lt_upload_date        -- �A�b�v���[�h����
      , ov_retcode     => lv_retcode            -- ���^�[���R�[�h
      , ov_errbuf      => lv_errbuf             -- �G���[�E���b�Z�[�W
      , ov_errmsg      => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      -- �A�b�v���[�hIF���擾�G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_msg_xxcop_00032 -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_fileid      -- �g�[�N���R�[�h1
                     , iv_token_value1 => iv_file_id         -- �g�[�N���l1
                     , iv_token_name2  => cv_tkn_format      -- �g�[�N���R�[�h2
                     , iv_token_value2 => iv_format          -- �g�[�N���l2
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 2�D�R���J�����g���̓p�����[�^���b�Z�[�W�o��
    --==============================================================
    lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application       -- �A�v���P�[�V�����Z�k��
                   , iv_name         => cv_msg_xxcop_00036   -- ���b�Z�[�W�R�[�h
                   , iv_token_name1  => cv_tkn_file_id       -- �g�[�N���R�[�h1
                   , iv_token_value1 => iv_file_id           -- �g�[�N���l1
                   , iv_token_name2  => cv_tkn_format_ptn    -- �g�[�N���R�[�h2
                   , iv_token_value2 => iv_format            -- �g�[�N���l2
                   , iv_token_name3  => cv_tkn_upload_object -- �g�[�N���R�[�h3
                   , iv_token_value3 => gt_upload_name       -- �g�[�N���l3
                   , iv_token_name4  => cv_tkn_file_name     -- �g�[�N���R�[�h4
                   , iv_token_value4 => lt_file_name         -- �g�[�N���l4
                 );
    -- ���b�Z�[�W�o��
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
      , buff  => lv_errmsg
    );
    FND_FILE.PUT_LINE(
        which => FND_FILE.LOG
      , buff  => lv_errmsg
    );
    -- ��s�o��
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
      , buff  => ''
    );
    FND_FILE.PUT_LINE(
        which => FND_FILE.LOG
      , buff  => ''
    );
--
    --==============================================================
    -- 3�D�Ɩ����t�擾
    --==============================================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    -- �Ɩ����t���擾�ł��Ȃ��ꍇ
    IF ( gd_process_date IS NULL ) THEN
      -- �Ɩ����t�擾�G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application => cv_application     -- �A�v���P�[�V�����Z�k��
                     , iv_name        => cv_msg_xxcop_00065 -- ���b�Z�[�W�R�[�h
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 4�D�v���t�@�C���F�}�X�^�g�DID�擾
    --==============================================================
      BEGIN
        gt_master_org_id := fnd_profile.value(cv_master_org_id);
      EXCEPTION
        WHEN OTHERS THEN
          gt_master_org_id := NULL;
      END;
      -- �v���t�@�C���F�}�X�^�g�DID���擾�o���Ȃ��ꍇ
      IF ( gt_master_org_id IS NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                      , iv_name         => cv_msg_xxcop_00002 -- ���b�Z�[�W�R�[�h
                      , iv_token_name1  => cv_tkn_profile     -- �g�[�N���R�[�h1
                      , iv_token_value1 => cv_master_org_id   -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
    --==============================================================
    -- 5�D�v���t�@�C���F�J�e�S���Z�b�g��(����Q�R�[�h)�擾
    --==============================================================
      BEGIN
        gt_policy_group_code := fnd_profile.value(cv_policy_group_code);
      EXCEPTION
        WHEN OTHERS THEN
          gt_policy_group_code := NULL;
      END;
      -- �v���t�@�C���F�J�e�S���Z�b�g��(����Q�R�[�h)���擾�o���Ȃ��ꍇ
      IF ( gt_policy_group_code IS NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application       -- �A�v���P�[�V�����Z�k��
                      , iv_name         => cv_msg_xxcop_00002   -- ���b�Z�[�W�R�[�h
                      , iv_token_name1  => cv_tkn_profile       -- �g�[�N���R�[�h1
                      , iv_token_value1 => cv_policy_group_code -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
    --==============================================================
    -- 6�D�N�C�b�N�R�[�h(���ڃ`�F�b�N�p��`���)�擾
    --==============================================================
    -- �J�[�\���I�[�v��
    OPEN chk_item_cur;
    -- �f�[�^�̈ꊇ�擾
    FETCH chk_item_cur BULK COLLECT INTO g_chk_item_tab;
    -- �J�[�\���N���[�Y
    CLOSE chk_item_cur;
    -- �N�C�b�N�R�[�h(���ڃ`�F�b�N�p��`���)���擾�ł��Ȃ��ꍇ
    IF ( g_chk_item_tab.COUNT = 0 ) THEN
      -- �N�C�b�N�R�[�h�擾�G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_msg_xxcop_00006 -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_value       -- �g�[�N���R�[�h1
                     , iv_token_value1 => cv_mst_group_item  -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 7�D�N�C�b�N�R�[�h(���ڃ`�F�b�N�p��`���)���R�[�h�����擾
    --==============================================================
    gn_item_cnt := g_chk_item_tab.COUNT;
--
    --==============================================================
    -- 8�D�N�C�b�N�R�[�h(�g�p�敪)���ݒ肳��Ă��邩�`�F�b�N
    --==============================================================
    BEGIN
      SELECT flv.lookup_code   AS use_kbn
      INTO   gt_use_kbn
      FROM   fnd_lookup_values flv
      WHERE  flv.lookup_type  = cv_use_kbn
      AND    gd_process_date BETWEEN NVL( flv.start_date_active, gd_process_date )
                             AND     NVL( flv.end_date_active, gd_process_date )
      AND    flv.enabled_flag = cv_flag_y
      AND    flv.language     = ct_lang
      AND    ROWNUM           = 1
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- �N�C�b�N�R�[�h�擾�G���[���b�Z�[�W
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_msg_xxcop_00006 -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_value       -- �g�[�N���R�[�h1
                       , iv_token_value1 => cv_use_kbn         -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --==============================================================
    -- 9�D�S�����_�擾
    --==============================================================
    gv_base_code := xxcop_common_pkg.get_charge_base_code(
                        in_user_id     => cn_last_updated_by -- ���[�U�[ID
                      , id_target_date => gd_process_date    -- �Ώۓ�
                    );
    -- ���_�R�[�h���擾�ł��Ȃ��ꍇ
    IF ( gv_base_code IS NULL ) THEN
      -- �S�����_�Ȃ��G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_msg_xxcop_00014 -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_user        -- �g�[�N���R�[�h1
                     , iv_token_value1 => cn_last_updated_by -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 10�D�S�����_�̎g�p�敪�擾
    --==============================================================
    BEGIN
      SELECT flv.lookup_code   AS use_kbn -- �g�p�敪
      INTO   gt_use_kbn
      FROM   fnd_lookup_values flv
      WHERE  flv.lookup_type  = cv_use_kbn
      AND    flv.meaning      = gv_base_code -- �S�����_�R�[�h
      AND    gd_process_date BETWEEN NVL( flv.start_date_active, gd_process_date )
                             AND     NVL( flv.end_date_active, gd_process_date )
      AND    flv.enabled_flag = cv_flag_y
      AND    flv.language     = ct_lang
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- �g�p�敪���݃G���[���b�Z�[�W
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_msg_xxcop_10067 -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_value1      -- �g�[�N���R�[�h1
                       , iv_token_value1 => cv_use_kbn         -- �g�[�N���l1
                       , iv_token_name2  => cv_tkn_value2      -- �g�[�N���R�[�h2
                       , iv_token_value2 => gv_base_code       -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
  EXCEPTION
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
      IF ( chk_item_cur%ISOPEN ) THEN
        CLOSE chk_item_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : del_mst_sum_item_code
   * Description      : �i�ڃR�[�h�W��}�X�^�폜����(A-2)
   ***********************************************************************************/
  PROCEDURE del_mst_sum_item_code(
      ov_errbuf  OUT VARCHAR2 -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode OUT VARCHAR2 -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg  OUT VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_mst_sum_item_code'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    -- *** ���[�J���J�[�\�� ***
    -- ���b�N�J�[�\��
    CURSOR lock_cur
    IS
      SELECT 1                         AS dummy -- �_�~�[�l
      FROM   xxcop_mst_group_item_code xmsic    -- �i�ڃR�[�h�W��}�X�^
      WHERE  xmsic.use_kbn = gt_use_kbn         -- �g�p�敪
      FOR UPDATE NOWAIT
    ;
    --
    TYPE l_lock_type IS TABLE OF lock_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    l_lock_tab                l_lock_type;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    -- 1�D���b�N�擾
    --==============================================================
    BEGIN
      -- �I�[�v��
      OPEN lock_cur;
      -- �t�F�b�`
      FETCH lock_cur BULK COLLECT INTO l_lock_tab;
      -- �N���[�Y
      CLOSE lock_cur;
      --
    EXCEPTION
      -- ���b�N�擾���ł��Ȃ��ꍇ
      WHEN global_lock_expt THEN
        -- �g�[�N���l�擾
        gv_tkn_1  := xxccp_common_pkg.get_msg( cv_application, cv_msg_xxcop_00083 );
        -- �e�[�u�����b�N�G���[���b�Z�[�W
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_msg_xxcop_00007 -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_table       -- �g�[�N���R�[�h1
                       , iv_token_value1 => gv_tkn_1           -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- �f�[�^�����݂���ꍇ
    IF ( l_lock_tab.COUNT > 0 ) THEN
      --==============================================================
      -- 2�D�i�ڃR�[�h�W��}�X�^�폜
      --==============================================================
      BEGIN
        DELETE FROM xxcop_mst_group_item_code xmsic -- �i�ڃR�[�h�W��}�X�^
        WHERE       xmsic.use_kbn = gt_use_kbn      -- �g�p�敪
        ;
        -- �폜����
        gn_delete_cnt := SQL%ROWCOUNT;
        --
      EXCEPTION
        -- �폜�Ɏ��s�����ꍇ
        WHEN OTHERS THEN
          -- �g�[�N���l�擾
          gv_tkn_1  := xxccp_common_pkg.get_msg( cv_application, cv_msg_xxcop_00083 );
          -- �폜�����G���[���b�Z�[�W
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                         , iv_name         => cv_msg_xxcop_00042 -- ���b�Z�[�W�R�[�h
                         , iv_token_name1  => cv_tkn_table       -- �g�[�N���R�[�h1
                         , iv_token_value1 => gv_tkn_1           -- �g�[�N���l1
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END del_mst_sum_item_code;
--
  /**********************************************************************************
   * Procedure Name   : get_file_upload_data
   * Description      : �t�@�C���A�b�v���[�h�f�[�^�擾����(A-3)
   ***********************************************************************************/
  PROCEDURE get_file_upload_data(
      iv_file_id IN  VARCHAR2 -- �t�@�C��ID
    , ov_errbuf  OUT VARCHAR2 -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode OUT VARCHAR2 -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg  OUT VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_file_upload_data'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    --==============================================================
    -- 1�DBLOB�f�[�^�ϊ�����
    --==============================================================
    xxccp_common_pkg2.blob_to_varchar2(
        in_file_id   => TO_NUMBER(iv_file_id) -- �t�@�C��ID
      , ov_file_data => gt_file_data_all      -- �ϊ���VARCHAR2�f�[�^
      , ov_errbuf    => lv_errbuf             -- �G���[�E���b�Z�[�W
      , ov_retcode   => lv_retcode            -- ���^�[���E�R�[�h
      , ov_errmsg    => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W 
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_file_upload_data;
--
  /**********************************************************************************
   * Procedure Name   : chk_validate_item
   * Description      : �Ó����`�F�b�N����(A-4)
   ***********************************************************************************/
  PROCEDURE chk_validate_item(
      ov_errbuf  OUT VARCHAR2 -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode OUT VARCHAR2 -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg  OUT VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_validate_item'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    lv_crowd_class_code_sum   VARCHAR2(4);                    -- ����Q�R�[�h�i�W��R�[�h�p�j
    lv_crowd_class_code_item  VARCHAR2(4);                    -- ����Q�R�[�h�i�i�ڃR�[�h�p�j
    ln_chk_cnt                NUMBER;                         -- �`�F�b�N�p����
    lb_item_check_flag        BOOLEAN;                        -- ���ڃ`�F�b�N�t���O
    lt_meaning                fnd_lookup_values.meaning%TYPE; -- ���e
    lt_csv_tab                xxcop_common_pkg.g_char_ttype;  -- ��������
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
    lv_crowd_class_code_sum  := NULL;  -- ����Q�R�[�h�i�W��R�[�h�p�j
    lv_crowd_class_code_item := NULL;  -- ����Q�R�[�h�i�i�ڃR�[�h�p�j
    ln_chk_cnt               := 0;     -- �`�F�b�N�p����
    lb_item_check_flag       := FALSE; -- ���ڃ`�F�b�N�t���O
    lt_meaning               := NULL;  -- ���e
    lt_csv_tab.DELETE;                 -- ��������
    gt_csv_tab.DELETE;                 -- �������ʁi�������菜����j
--
    --==============================================================
    -- 1�DCSV�����񕪊�
    --==============================================================
    -- CSV��������
    xxcop_common_pkg.char_delim_partition(
        iv_char    => gt_file_data_all(gn_record_cnt) -- �Ώە�����
      , iv_delim   => cv_comma                        -- �f���~�^
      , o_char_tab => lt_csv_tab                      -- ��������
      , ov_retcode => lv_retcode                      -- ���^�[���R�[�h
      , ov_errbuf  => lv_errbuf                       -- �G���[�E���b�Z�[�W
      , ov_errmsg  => lv_errmsg                       -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    --
    -- �Ώی����ێ��iCSV�̍sNo�Ƃ��Ă��g�p�j
    gn_target_cnt := gn_target_cnt + 1;
    --
    -- �S�Ă̍��ڂ����ݒ�̏ꍇ
    IF ( TRIM( REPLACE( REPLACE( gt_file_data_all(gn_record_cnt), cv_comma, NULL ), cv_dobule_quote, NULL ) ) IS NULL ) THEN
      -- ��s���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_msg_xxcop_00078 -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_row         -- �g�[�N���R�[�h1
                     , iv_token_value1 => gn_target_cnt      -- �g�[�N���l1
                   );
      -- �Ó����`�F�b�N��O
      RAISE global_chk_item_expt;
    END IF;
    --
    -- ���ڐ����قȂ�ꍇ
    IF ( gn_item_cnt <> lt_csv_tab.COUNT ) THEN
      -- �t�H�[�}�b�g�`�F�b�N�G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_msg_xxcop_00069 -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_row         -- �g�[�N���R�[�h1
                     , iv_token_value1 => gn_target_cnt      -- �g�[�N���l1
                     , iv_token_name2  => cv_tkn_file        -- �g�[�N���R�[�h2
                     , iv_token_value2 => gt_upload_name     -- �g�[�N���l2
                   );
      -- �Ó����`�F�b�N��O
      RAISE global_chk_item_expt;
    END IF;
    --
    --==============================================================
    -- 2�D���ڃ`�F�b�N
    --==============================================================
    -- ���ڃ`�F�b�N���[�v
    << item_check_loop >>
    FOR i IN g_chk_item_tab.FIRST .. g_chk_item_tab.COUNT LOOP
      --
      -- �������肪���݂���ꍇ�͍폜
      gt_csv_tab(i) := TRIM( REPLACE( lt_csv_tab(i), cv_dobule_quote, NULL ) );
      --
      -- ���ڃ`�F�b�N���ʊ֐�
      xxccp_common_pkg2.upload_item_check(
          iv_item_name    => g_chk_item_tab(i).meaning    -- ���ږ���
        , iv_item_value   => gt_csv_tab(i)                -- ���ڂ̒l
        , in_item_len     => g_chk_item_tab(i).attribute1 -- ���ڂ̒���
        , in_item_decimal => g_chk_item_tab(i).attribute2 -- ���ڂ̒���(�����_�ȉ�)
        , iv_item_nullflg => g_chk_item_tab(i).attribute3 -- �K�{�t���O
        , iv_item_attr    => g_chk_item_tab(i).attribute4 -- ���ڑ���
        , ov_errbuf       => lv_errbuf                    -- �G���[�E���b�Z�[�W           --# �Œ� #
        , ov_retcode      => lv_retcode                   -- ���^�[���E�R�[�h             --# �Œ� #
        , ov_errmsg       => lv_errmsg                    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      -- ���^�[���R�[�h������ȊO�̏ꍇ
      IF ( lv_retcode <> cv_status_normal ) THEN
        -- �s���`�F�b�N�G���[���b�Z�[�W
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application            -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_msg_xxcop_00070        -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_row                -- �g�[�N���R�[�h1
                       , iv_token_value1 => gn_target_cnt             -- �g�[�N���l1
                       , iv_token_name2  => cv_tkn_item               -- �g�[�N���R�[�h2
                       , iv_token_value2 => g_chk_item_tab(i).meaning -- �g�[�N���l2
                       , iv_token_name3  => cv_tkn_value              -- �g�[�N���R�[�h3
                       , iv_token_value3 => gt_csv_tab(i)             -- �g�[�N���l3
                       , iv_token_name4  => cv_tkn_errmsg             -- �g�[�N���R�[�h3
                       , iv_token_value4 => lv_errmsg                 -- �g�[�N���l3
                     );
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT
          , buff  => lv_errmsg
        );
        -- ���ڃ`�F�b�N�G���[����̃t���O�ύX
        lb_item_check_flag := TRUE;
      END IF;
      --
    END LOOP item_check_loop;
    --
    -- ���ڃ`�F�b�N�ŃG���[�̏ꍇ
    IF ( lb_item_check_flag = TRUE ) THEN
      -- �Ó����`�F�b�N��O
      RAISE global_chk_item_expt;
    END IF;
    --
--
    --==============================================================
    -- 3�D�W��R�[�h�}�X�^���݃`�F�b�N
    --==============================================================
    BEGIN
      SELECT mcsv_ccc.crowd_class_code AS crowd_class_code -- ����Q�R�[�h
      INTO   lv_crowd_class_code_sum
      FROM   ic_item_mst_b             iimb -- OPM�i��
           , mtl_system_items_b        msib -- Disc�i��
           , ( SELECT gic.item_id            AS item_id
                    , mcv.segment1           AS crowd_class_code
               FROM   gmi_item_categories    gic
                    , mtl_category_sets_vl   mcsv
                    , mtl_categories_vl      mcv
               WHERE  gic.category_set_id    = mcsv.category_set_id
               AND    mcsv.category_set_name = gt_policy_group_code
               AND    gic.category_id        = mcv.category_id
             ) mcsv_ccc  -- �C�����C���r���[_����Q�R�[�h
      WHERE  iimb.item_id         = mcsv_ccc.item_id(+)
      AND    iimb.item_no         = msib.segment1
      AND    iimb.item_no         = gt_csv_tab(1)
      AND    msib.organization_id = gt_master_org_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �W��R�[�h�}�X�^���݃`�F�b�N�G���[���b�Z�[�W
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_msg_xxcop_10059 -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_row         -- �g�[�N���R�[�h1
                       , iv_token_value1 => gn_target_cnt      -- �g�[�N���l1
                       , iv_token_name2  => cv_tkn_value       -- �g�[�N���R�[�h2
                       , iv_token_value2 => gt_csv_tab(1)      -- �g�[�N���l2
                     );
        -- �Ó����`�F�b�N��O
        RAISE global_chk_item_expt;
    END;
--
    --==============================================================
    -- 4�D�i�ڃR�[�h�}�X�^���݃`�F�b�N
    --==============================================================
    BEGIN
      SELECT mcsv_ccc.crowd_class_code AS crowd_class_code -- ����Q�R�[�h
      INTO   lv_crowd_class_code_item
      FROM   ic_item_mst_b             iimb -- OPM�i��
           , mtl_system_items_b        msib -- Disc�i��
           , ( SELECT gic.item_id            AS item_id
                    , mcv.segment1           AS crowd_class_code
               FROM   gmi_item_categories    gic
                    , mtl_category_sets_vl   mcsv
                    , mtl_categories_vl      mcv
               WHERE  gic.category_id        = mcv.category_id
               AND    gic.category_set_id    = mcsv.category_set_id
               AND    mcsv.category_set_name = gt_policy_group_code
             ) mcsv_ccc  -- �C�����C���r���[_����Q�R�[�h
      WHERE  iimb.item_id         = mcsv_ccc.item_id(+)
      AND    iimb.item_no         = msib.segment1
      AND    iimb.item_no         = gt_csv_tab(3)
      AND    msib.organization_id = gt_master_org_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �i�ڃR�[�h�}�X�^���݃`�F�b�N�G���[���b�Z�[�W
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_msg_xxcop_10060 -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_row         -- �g�[�N���R�[�h1
                       , iv_token_value1 => gn_target_cnt      -- �g�[�N���l1
                       , iv_token_name2  => cv_tkn_value       -- �g�[�N���R�[�h2
                       , iv_token_value2 => gt_csv_tab(3)      -- �g�[�N���l2
                     );
        -- �Ó����`�F�b�N��O
        RAISE global_chk_item_expt;
    END;
--
    --==============================================================
    -- 5�D�g�p�敪�������`�F�b�N
    --==============================================================
    -- �g�p�敪�����O�C�����[�U�[�̎g�p�敪�Ƒ��Ⴗ��ꍇ
    IF ( gt_csv_tab(5) <> gt_use_kbn ) THEN
      -- ���b�Z�[�W�p�̎g�p�敪���擾
      BEGIN
        SELECT flv.meaning       AS meaning -- �g�p�����R�[�h
        INTO   lt_meaning
        FROM   fnd_lookup_values flv
        WHERE  flv.lookup_type  = cv_use_kbn
        AND    flv.lookup_code  = gt_csv_tab(5)
        AND    gd_process_date BETWEEN NVL( flv.start_date_active, gd_process_date )
                               AND     NVL( flv.end_date_active, gd_process_date )
        AND    flv.enabled_flag = cv_flag_y
        AND    flv.language     = ct_lang
        ;
      EXCEPTION
        -- �擾�ł��Ȃ��ꍇ
        WHEN NO_DATA_FOUND THEN
          -- ���b�Z�[�W�\���̂��߂̎擾�ł��邽�߁A�G���[�ɂ��Ȃ�
          NULL;
      END;
      -- �g�p�敪�`�F�b�N�G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_msg_xxcop_10070 -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_row         -- �g�[�N���R�[�h1
                     , iv_token_value1 => gn_target_cnt      -- �g�[�N���l1
                     , iv_token_name2  => cv_tkn_value1      -- �g�[�N���R�[�h2
                     , iv_token_value2 => gt_csv_tab(5)      -- �g�[�N���l2
                     , iv_token_name3  => cv_tkn_value2      -- �g�[�N���R�[�h3
                     , iv_token_value3 => lt_meaning         -- �g�[�N���l3
                     , iv_token_name4  => cv_tkn_value3      -- �g�[�N���R�[�h4
                     , iv_token_value4 => gv_base_code       -- �g�[�N���l4
                   );
      -- �Ó����`�F�b�N��O
      RAISE global_chk_item_expt;
    END IF;
--
    --==============================================================
    -- 6�DCSV�t�@�C�������R�[�h�d���`�F�b�N�i�W��R�[�h�E�i�ڃR�[�h�j
    --==============================================================
    SELECT COUNT(1)                  AS cnt      -- �`�F�b�N�p����
    INTO   ln_chk_cnt
    FROM   xxcop_mst_group_item_code xmsic       -- �i�ڃR�[�h�W��}�X�^
    WHERE  xmsic.group_item_code = gt_csv_tab(1) -- �W��R�[�h
    AND    xmsic.item_code       = gt_csv_tab(3) -- �i�ڃR�[�h
    AND    xmsic.use_kbn         = gt_use_kbn    -- �g�p�敪
    ;
    -- �������擾���ꂽ�ꍇ
    IF ( ln_chk_cnt > 0 ) THEN
      -- �f�[�^�d���G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_msg_xxcop_10061 -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_row         -- �g�[�N���R�[�h1
                     , iv_token_value1 => gn_target_cnt      -- �g�[�N���l1
                     , iv_token_name2  => cv_tkn_value1      -- �g�[�N���R�[�h2
                     , iv_token_value2 => gt_csv_tab(1)      -- �g�[�N���l2
                     , iv_token_name3  => cv_tkn_value2      -- �g�[�N���R�[�h3
                     , iv_token_value3 => gt_csv_tab(3)      -- �g�[�N���l3
                   );
      -- �Ó����`�F�b�N��O
      RAISE global_chk_item_expt;
    END IF;
--
    --==============================================================
    -- 7�DCSV�t�@�C�������R�[�h�d���`�F�b�N�i�i�ڃR�[�h�j
    --==============================================================
    SELECT COUNT(1)                  AS cnt -- �`�F�b�N�p����
    INTO   ln_chk_cnt
    FROM   xxcop_mst_group_item_code xmsic  -- �i�ڃR�[�h�W��}�X�^
    WHERE  xmsic.item_code = gt_csv_tab(3)  -- �i�ڃR�[�h
    AND    xmsic.use_kbn   = gt_use_kbn     -- �g�p�敪
    ;
    -- �������擾���ꂽ�ꍇ
    IF ( ln_chk_cnt > 0 ) THEN
      -- �f�[�^�d���G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_msg_xxcop_10062 -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_row         -- �g�[�N���R�[�h1
                     , iv_token_value1 => gn_target_cnt      -- �g�[�N���l1
                     , iv_token_name2  => cv_tkn_value1      -- �g�[�N���R�[�h2
                     , iv_token_value2 => gt_csv_tab(3)      -- �g�[�N���l2
                   );
      -- �Ó����`�F�b�N��O
      RAISE global_chk_item_expt;
    END IF;
--
    --==============================================================
    -- 8�D�i�ڃR�[�h�W��}�X�^���݃`�F�b�N�i�i�ڃR�[�h�j
    --==============================================================
    SELECT COUNT(1)                  AS cnt -- �`�F�b�N�p����
    INTO   ln_chk_cnt
    FROM   xxcop_mst_group_item_code xmsic  -- �i�ڃR�[�h�W��}�X�^
    WHERE  xmsic.item_code = gt_csv_tab(3)  -- �i�ڃR�[�h
    ;
    -- �������擾���ꂽ�ꍇ
    IF ( ln_chk_cnt > 0 ) THEN
      -- �f�[�^�d���G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_msg_xxcop_10063 -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_row         -- �g�[�N���R�[�h1
                     , iv_token_value1 => gn_target_cnt      -- �g�[�N���l1
                     , iv_token_name2  => cv_tkn_value1      -- �g�[�N���R�[�h2
                     , iv_token_value2 => gt_csv_tab(1)      -- �g�[�N���l2
                     , iv_token_name3  => cv_tkn_value2      -- �g�[�N���R�[�h3
                     , iv_token_value3 => gt_csv_tab(3)      -- �g�[�N���l3
                     , iv_token_name4  => cv_tkn_value3      -- �g�[�N���R�[�h3
                     , iv_token_value4 => gt_csv_tab(5)      -- �g�[�N���l3
                   );
      -- �Ó����`�F�b�N��O
      RAISE global_chk_item_expt;
    END IF;
--
    --==============================================================
    -- 9�D����Q�R�[�h�������`�F�b�N
    --==============================================================
    -- ����Q�R�[�h�̓�3�������Ⴗ��ꍇ
    -- �܂��͐���Q�R�[�h�i�W��R�[�h�j��NULL�̏ꍇ
    -- �܂��͐���Q�R�[�h�i�i�ڃR�[�h�j��NULL�̏ꍇ
    IF ( ( SUBSTRB(lv_crowd_class_code_sum, 1, 3) <> SUBSTRB(lv_crowd_class_code_item, 1, 3) )
      OR ( lv_crowd_class_code_sum IS NULL )
      OR ( lv_crowd_class_code_item IS NULL ) )
    THEN
      -- ����Q�R�[�h�������`�F�b�N�G���[���b�Z�[�W
      -- �����̃`�F�b�N�G���[�͓o�^�Ώۂł���A�x���I������
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application           -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_msg_xxcop_10071       -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_row               -- �g�[�N���R�[�h1
                     , iv_token_value1 => gn_target_cnt            -- �g�[�N���l1
                     , iv_token_name2  => cv_tkn_value1            -- �g�[�N���R�[�h2
                     , iv_token_value2 => gt_csv_tab(1)            -- �g�[�N���l2
                     , iv_token_name3  => cv_tkn_value2            -- �g�[�N���R�[�h3
                     , iv_token_value3 => lv_crowd_class_code_sum  -- �g�[�N���l3
                     , iv_token_name4  => cv_tkn_value3            -- �g�[�N���R�[�h4
                     , iv_token_value4 => gt_csv_tab(3)            -- �g�[�N���l4
                     , iv_token_name5  => cv_tkn_value4            -- �g�[�N���R�[�h5
                     , iv_token_value5 => lv_crowd_class_code_item -- �g�[�N���l5
                   );
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
          which => FND_FILE.OUTPUT
        , buff  => lv_errmsg
      );
      -- ����Q�R�[�h�`�F�b�N�t���OON
      gb_crowd_class_code_flag := TRUE;
    END IF;
--
  EXCEPTION
--
    -- �Ó����`�F�b�N��O�n���h��
    WHEN global_chk_item_expt THEN
      -- 2.���ڃ`�F�b�N�G���[�̓��b�Z�[�W�o�͍ς̂��߁A����ȊO�̏ꍇ�Ƀ��b�Z�[�W�o��
      IF ( lb_item_check_flag = FALSE ) THEN
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT
          , buff  => lv_errmsg
        );
      END IF;
      --
      -- �x�������ݒ�
      gn_warn_cnt := gn_warn_cnt + 1;
      -- ���^�[���E�R�[�h���x���ݒ�
      ov_retcode := cv_status_warn;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_validate_item;
--
  /**********************************************************************************
   * Procedure Name   : ins_mst_sum_item_code
   * Description      : �i�ڃR�[�h�W��}�X�^�o�^����(A-5)
   ***********************************************************************************/
  PROCEDURE ins_mst_sum_item_code(
      ov_errbuf  OUT VARCHAR2 -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode OUT VARCHAR2 -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg  OUT VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_mst_sum_item_code'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    --==============================================================
    -- 1. �o�^����
    --==============================================================
    BEGIN
      INSERT INTO xxcop_mst_group_item_code(
          group_item_code           -- �W��R�[�h
        , group_item_name           -- �W��R�[�h�i�ږ�
        , item_code                 -- �i�ڃR�[�h
        , item_name                 -- �i�ږ�
        , use_kbn                   -- �g�p�敪
        , created_by                -- �쐬��
        , creation_date             -- �쐬��
        , last_updated_by           -- �ŏI�X�V��
        , last_update_date          -- �ŏI�X�V��
        , last_update_login         -- �ŏI�X�V���O�C��
        , request_id                -- �v��ID
        , program_application_id    -- �v���O�����A�v���P�[�V����ID
        , program_id                -- �v���O����ID
        , program_update_date       -- �v���O�����X�V��
      ) VALUES (
          gt_csv_tab(1)             -- �W��R�[�h
        , gt_csv_tab(2)             -- �W��R�[�h�i�ږ�
        , gt_csv_tab(3)             -- �i�ڃR�[�h
        , gt_csv_tab(4)             -- �i�ږ�
        , gt_csv_tab(5)             -- �g�p�敪
        , cn_created_by             -- �쐬��
        , cd_creation_date          -- �쐬��
        , cn_last_updated_by        -- �ŏI�X�V��
        , cd_last_update_date       -- �ŏI�X�V��
        , cn_last_update_login      -- �ŏI�X�V���O�C��
        , cn_request_id             -- �v��ID
        , cn_program_application_id -- �v���O�����A�v���P�[�V����ID
        , cn_program_id             -- �v���O����ID
        , cd_program_update_date    -- �v���O�����X�V��
      );
      -- �o�^����
      gn_insert_cnt := gn_insert_cnt + 1;
      --
    EXCEPTION
      WHEN OTHERS THEN
        -- �g�[�N���l�擾
        gv_tkn_1  := xxccp_common_pkg.get_msg( cv_application, cv_msg_xxcop_00083 );
        -- �o�^�����G���[���b�Z�[�W
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_msg_xxcop_00027 -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_table       -- �g�[�N���R�[�h1
                       , iv_token_value1 => gv_tkn_1           -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_mst_sum_item_code;
--
  /**********************************************************************************
   * Procedure Name   : del_file_upload_data
   * Description      : �t�@�C���A�b�v���[�h�f�[�^�폜����(A-6)
   ***********************************************************************************/
  PROCEDURE del_file_upload_data(
      iv_file_id IN  VARCHAR2 -- �t�@�C��ID
    , ov_errbuf  OUT VARCHAR2 -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode OUT VARCHAR2 -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg  OUT VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_file_upload_data'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    --==============================================================
    -- 1. �t�@�C���A�b�v���[�h�폜
    --==============================================================
    --�t�@�C���A�b�v���[�h�e�[�u���f�[�^�폜����
    xxcop_common_pkg.delete_upload_table(
        in_file_id => TO_NUMBER(iv_file_id) -- �t�@�C��ID
      , ov_retcode => lv_retcode            -- ���^�[���E�R�[�h
      , ov_errbuf  => lv_errbuf             -- �G���[�E���b�Z�[�W
      , ov_errmsg  => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    --
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- �g�[�N���l�擾
      gv_tkn_1  := xxccp_common_pkg.get_msg( cv_application, cv_msg_xxcop_00079 );
      -- �폜�����G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_msg_xxcop_00042 -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_table       -- �g�[�N���R�[�h1
                     , iv_token_value1 => gv_tkn_1           -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END del_file_upload_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
      ov_errbuf  OUT VARCHAR2 -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode OUT VARCHAR2 -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg  OUT VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    , iv_file_id IN  VARCHAR2 -- �t�@�C��ID
    , iv_format  IN  VARCHAR2 -- �t�H�[�}�b�g�p�^�[��
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
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt  := 0;
    gn_delete_cnt  := 0;
    gn_insert_cnt  := 0;
    gn_warn_cnt    := 0;
    gn_error_cnt   := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================================
    -- ��������(A-1)
    -- ===============================================
    init(
        iv_file_id => iv_file_id -- �t�@�C��ID
      , iv_format  => iv_format  -- �t�H�[�}�b�g�p�^�[��
      , ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W
      , ov_retcode => lv_retcode -- ���^�[���E�R�[�h
      , ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- �i�ڃR�[�h�W��}�X�^�폜����(A-2)
    -- ===============================================
    del_mst_sum_item_code(
        ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W
      , ov_retcode => lv_retcode -- ���^�[���E�R�[�h
      , ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W 
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- �t�@�C���A�b�v���[�h�f�[�^�擾����(A-3)
    -- ===============================================
    get_file_upload_data(
        iv_file_id => iv_file_id -- �t�@�C��ID
      , ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W
      , ov_retcode => lv_retcode -- ���^�[���E�R�[�h
      , ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W 
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- �i�ڃR�[�h�W��}�X�^�o�^���[�v
    << ins_loop >>
    FOR i IN gt_file_data_all.FIRST .. gt_file_data_all.COUNT LOOP
      -- �J�E���^
      gn_record_cnt := gn_record_cnt + 1;
      --
      -- ===============================================
      -- �Ó����`�F�b�N����(A-4)
      -- ===============================================
      chk_validate_item(
          ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W
        , ov_retcode => lv_retcode -- ���^�[���E�R�[�h
        , ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
      --
      -- �Ó����`�F�b�N������̃��R�[�h�͓o�^
      --                 �x���̃��R�[�h�̓X�L�b�v
      IF ( lv_retcode = cv_status_normal ) THEN
        -- ===============================================
        -- �i�ڃR�[�h�W��}�X�^�o�^����(A-5)
        -- ===============================================
        ins_mst_sum_item_code(
            ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W
          , ov_retcode => lv_retcode -- ���^�[���E�R�[�h
          , ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
        --
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
    --
    END LOOP ins_loop;
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
      errbuf     OUT VARCHAR2 -- �G���[�E���b�Z�[�W #�Œ�#
    , retcode    OUT VARCHAR2 -- ���^�[���E�R�[�h   #�Œ�#
    , iv_file_id IN  VARCHAR2 -- �t�@�C��ID
    , iv_format  IN  VARCHAR2 -- �t�H�[�}�b�g�p�^�[��
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
    -- �A�v���P�[�V�����Z�k��
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�h�I���F���ʁEIF�̈�
    -- ���b�Z�[�W
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
    cv_msg_xxcop_00090 CONSTANT VARCHAR2(16)  := 'APP-XXCOP1-00090'; -- �폜�������b�Z�[�W
    cv_msg_xxcop_00091 CONSTANT VARCHAR2(16)  := 'APP-XXCOP1-00091'; -- �o�^�������b�Z�[�W
    cv_msg_xxcop_00093 CONSTANT VARCHAR2(16)  := 'APP-XXCOP1-00093'; -- �x���������b�Z�[�W
    -- �g�[�N��
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
--
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
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
        ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode => lv_retcode -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      , iv_file_id => iv_file_id -- �t�@�C��ID
      , iv_format  => iv_format  -- �t�H�[�}�b�g�p�^�[��
    );
--
    --�G���[�o��
    IF ( lv_retcode = cv_status_error ) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf
      );
      -- �G���[����ROLLBACK
      ROLLBACK;
      -- �G���[�����ݒ�
      gn_error_cnt := 1;
    END IF;
--
    -- ===============================================
    -- �t�@�C���A�b�v���[�h�f�[�^�폜����(A-6)
    -- ===============================================
    del_file_upload_data(
        iv_file_id => iv_file_id -- �t�@�C��ID
      , ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W
      , ov_retcode => lv_retcode -- ���^�[���E�R�[�h
      , ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W 
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000)
      );
      -- �G���[����ROLLBACK
      ROLLBACK;
      -- �G���[�����ݒ�
      gn_error_cnt := 1;
    END IF;
    -- �t�@�C���A�b�v���[�h�f�[�^�폜���COMMIT
    COMMIT;
--
    -- �G���[���������݂���ꍇ
    IF ( gn_error_cnt > 0 ) THEN
      -- �G���[���̌����ݒ�
      gn_target_cnt  := 0;
      gn_delete_cnt  := 0;
      gn_insert_cnt  := 0;
      gn_warn_cnt    := 0;
      -- �I���X�e�[�^�X���G���[�ɂ���
      lv_retcode := cv_status_error;
    -- �G���[�ȊO�ŁA�x�����������݂���ꍇ�܂��͐���Q�R�[�h�������`�F�b�N�ŃG���[�̏ꍇ
    ELSIF ( ( gn_warn_cnt > 0 ) OR ( gb_crowd_class_code_flag = TRUE ) ) THEN
      -- �I���X�e�[�^�X���x���ɂ���
      lv_retcode := cv_status_warn;
    -- �G���[�����A�x�����������݂��Ȃ��ꍇ
    ELSE
      -- �I���X�e�[�^�X�𐳏�ɂ���
      lv_retcode := cv_status_normal;
    END IF;
--
    -- ��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --
    -- �Ώی����o��
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
    -- �폜�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_msg_xxcop_00090
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_delete_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    -- �o�^�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_msg_xxcop_00091
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_insert_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    -- �x�������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_msg_xxcop_00093
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    -- �G���[�����o��
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
    -- �I�����b�Z�[�W
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF ( lv_retcode = cv_status_error ) THEN
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
    -- �X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    -- �I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
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
END XXCOP004A08C;
/
