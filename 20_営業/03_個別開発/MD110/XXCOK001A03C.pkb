CREATE OR REPLACE PACKAGE BODY XXCOK001A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK001A03C_pkg(body)
 * Description      : �c�ƃV�X�e���\�z�v���W�F�N�g
 * MD.050           : �A�h�I���F�ڋq�ڍs����I/F�t�@�C���쐬 �̔����� MD050_COK_001_A03
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  dlt_data_p             �p�[�W����(A-2)
 *  upd_unconfirmed_data_p ���m��f�[�^���(A-3)
 *  get_cust_shift_info_p  �A�g�Ώیڋq�ڍs���擾(A-4)
 *  open_file_p            �t�@�C���I�[�v��(A-5)
 *  create_flat_file_p     �t���b�g�t�@�C���쐬(A-6)
 *  close_file_p           �t�@�C���N���[�Y(A-7)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/10/31    1.0   K.Suenaga        �V�K�쐬
 *  2009/02/02    1.1   K.Suenaga        [��QCOK_001]��o�b�`�Ή�/�c�ƒP��ID�ǉ�
 *  2009/02/05    1.2   K.Suenaga        [��QCOK_009]�N�C�b�N�R�[�h�r���[�ɗL�����E�������̔����ǉ�
 *                                                    �f�B���N�g���p�X�̏o�͕��@��ύX
 *
 *****************************************************************************************/
  -- ===============================
  -- �O���[�o���萔
  -- ===============================
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1)    := xxccp_common_pkg.set_status_normal; -- ����:0
  cv_status_warn            CONSTANT VARCHAR2(1)    := xxccp_common_pkg.set_status_warn;   --�x��:1
  cv_status_error           CONSTANT VARCHAR2(1)    := xxccp_common_pkg.set_status_error;  -- �ُ�:2
  --WHO�J����
  cn_created_by              CONSTANT NUMBER        := fnd_global.user_id;         --CREATED_BY
  cd_creation_date           CONSTANT DATE          := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by         CONSTANT NUMBER        := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date        CONSTANT DATE          := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login       CONSTANT NUMBER        := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id              CONSTANT NUMBER        := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id  CONSTANT NUMBER        := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id              CONSTANT NUMBER        := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date     CONSTANT DATE          := SYSDATE;                    --PROGRAM_UPDATE_DATE  
  --�p�b�P�[�W��
  cv_pkg_name               CONSTANT VARCHAR2(100)  := 'XXCOK001A03C';             -- �p�b�P�[�W��
  --�v���t�@�C��
  cv_org_id                 CONSTANT VARCHAR2(10)   := 'ORG_ID';                   -- �c�ƒP��ID  
  cv_comp_code              CONSTANT VARCHAR2(50)   := 'XXCOK1_AFF1_COMPANY_CODE'; -- ��ЃR�[�h�̃v���t�@�C��
  cv_cust_keep_period       CONSTANT VARCHAR2(50)   := 'XXCOK1_CUST_KEEP_PERIOD';  -- �ێ����Ԃ̃v���t�@�C��
  cv_cust_dire_path         CONSTANT VARCHAR2(50)   := 'XXCOK1_CUST_DIRE_PATH';    -- �f�B���N�g���p�X�̃v���t�@�C��
  cv_cust_file_name         CONSTANT VARCHAR2(50)   := 'XXCOK1_CUST_FILE_NAME';    -- �t�@�C���p�X�̃v���t�@�C��
  --�g�[�N����
  cv_profile_token          CONSTANT VARCHAR2(15)   := 'PROFILE';                  -- �v���t�@�C���̃g�[�N����
  cv_dire_name_token        CONSTANT VARCHAR2(15)   := 'DIRECTORY';                -- �f�B���N�g���̃g�[�N����
  cv_file_name_token        CONSTANT VARCHAR2(15)   := 'FILE_NAME';                -- �t�@�C���̃g�[�N����
  cv_count_token            CONSTANT VARCHAR2(50)   := 'COUNT';                    -- ���������̃g�[�N����
  cv_process_flag_token     CONSTANT VARCHAR2(12)   := 'PROCESS_FLAG';             -- ���͍��ڂ̋N���敪�̃g�[�N����
  --���b�Z�[�W
  cv_operation_date         CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-00028';         -- �Ɩ��������t�擾�G���[
  cv_profile_err_msg        CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-00003';         -- �v���t�@�C���擾�G���[
  cv_dire_name_msg          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-00067';         -- �f�B���N�g�������b�Z�[�W�o��
  cv_file_name_msg          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-00006';         -- �t�@�C�������b�Z�[�W�o��
  cv_lock_err_msg           CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-00064';         -- �ڋq�ڍs��񃍃b�N�擾�G���[
  cv_dlt_err_msg            CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10058';         -- �폜�����G���[
  cv_upd_err_msg            CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10059';         -- ���m��f�[�^��������G���[
  cv_target_count_err_msg   CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10096';         -- �Ώی����Ȃ��G���[ 
  cv_file_err_msg           CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-00009';         -- �t�@�C�����݃`�F�b�N�G���[
  cv_target_count_msg       CONSTANT VARCHAR2(50)   := 'APP-XXCCP1-90000';         -- �Ώی������b�Z�[�W
  cv_normal_count_msg       CONSTANT VARCHAR2(50)   := 'APP-XXCCP1-90001';         -- �����������b�Z�[�W
  cv_err_count_msg          CONSTANT VARCHAR2(50)   := 'APP-XXCCP1-90002';         -- �G���[�������b�Z�[�W
  cv_normal_msg             CONSTANT VARCHAR2(50)   := 'APP-XXCCP1-90004';         -- ����I�����b�Z�[�W
  cv_commit_msg             CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10383';         -- �G���[�R�~�b�g���b�Z�[�W
  cv_err_msg                CONSTANT VARCHAR2(50)   := 'APP-XXCCP1-90006';         -- �G���[�I���S���[���o�b�N���b�Z�[�W
  cv_00078_msg              CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-00078';         -- �V�X�e���ғ����擾�G���[���b�Z�[�W
  cv_00076_msg              CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-00076';         -- �N���敪�o�͗p���b�Z�[�W
  --�A�v���P�[�V�����Z�k��
  cv_appli_xxcok_name       CONSTANT VARCHAR2(15)   := 'XXCOK';                    -- �A�v���P�[�V�����Z�k��
  cv_appli_xxccp_name       CONSTANT VARCHAR2(50)   := 'XXCCP';                    -- �A�v���P�[�V�����Z�k��
  --�X�e�[�^�X
  cv_input_status           CONSTANT VARCHAR2(1)    := 'I';                        -- ���͒��̃X�e�[�^�X
  cv_cancel_status          CONSTANT VARCHAR2(1)    := 'C';                        -- ����̃X�e�[�^�X
  --�ڍs�敪
  cv_shift_type             CONSTANT VARCHAR2(1)    := '1';                        -- �ڍs�敪�̔N���萔
  --�N���敪
  cv_normal_type            CONSTANT VARCHAR2(1)    := '1';                        -- �N���敪��"1"(�ʏ�N��)
-- �t���O
  cv_commit_flag            CONSTANT VARCHAR2(1)    := '1';                        -- �G���[�t���O
  --�Q�ƃ^�C�v
  cv_cust_shift_status      CONSTANT VARCHAR2(50)   := 'XXCOK1_CUST_SHIFT_STATUS'; -- �ڋq�ڍs�X�e�[�^�X�̒萔
  cv_shift_divide           CONSTANT VARCHAR2(50)   := 'XXCOK1_SHIFT_DIVIDE';      -- �ڍs�����̒萔
  --�L��
  cv_slash                  CONSTANT VARCHAR2(1)    := '/';                        -- �X���b�V��
  cv_msg_double             CONSTANT VARCHAR2(1)    := '"';                        -- �_�u���R�[�e�[�V����  
  cv_msg_comma              CONSTANT VARCHAR2(1)    := ',';                        -- �J���}
  cv_msg_part               CONSTANT VARCHAR2(3)    := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3)    := '.';
--
  cv_open_mode              CONSTANT VARCHAR2(1)    := 'w';
  cn_max_linesize           CONSTANT BINARY_INTEGER := 32767;
  --�ғ����擾�֐�
  cn_cal_type_one           CONSTANT NUMBER         := 1;                         -- �J�����_�[�敪=1(�V�X�e���J�����_)
  cn_aft                    CONSTANT NUMBER         := 2;                         -- �����敪"2"(��)
  cn_plus_days              CONSTANT NUMBER         := 1;                         -- ����
  -- ===============================
  -- �O���[�o���ϐ�
  -- ===============================
  gn_target_cnt     NUMBER             DEFAULT NULL;                  -- �Ώی���
  gn_normal_cnt     NUMBER             DEFAULT NULL;                  -- ���팏��
  gn_error_cnt      NUMBER             DEFAULT NULL;                  -- �G���[����
  gd_system_date    DATE               DEFAULT NULL;                  -- �V�X�e�����t�̃O���[�o���ϐ�
  gd_operation_date DATE               DEFAULT NULL;                  -- �Ɩ��������t�̃O���[�o���ϐ�
  gv_comp_code      VARCHAR2(50)       DEFAULT NULL;                  -- ��ЃR�[�h�̃O���[�o���ϐ�
  gn_keep_period    NUMBER             DEFAULT NULL;                  -- �ێ����Ԃ̃O���[�o���ϐ�
  gv_cust_dire_path VARCHAR2(50)       DEFAULT NULL;                  -- �f�B���N�g���p�X�̃O���[�o���ϐ�
  gv_cust_file_name VARCHAR2(50)       DEFAULT NULL;                  -- �t�@�C���p�X�̃O���[�o���ϐ�
  g_open_file       UTL_FILE.FILE_TYPE DEFAULT NULL;                  -- �I�[�v���t�@�C���n���h���̕ϐ�
  gv_commit_flag    VARCHAR2(50)       DEFAULT '0' ;                  -- �G���[�t���O�̕ϐ�
  gn_org_id         NUMBER             DEFAULT NULL;                  -- �c�ƒP��ID
  -- ===============================
  -- �O���[�o���J�[�\��
  -- ===============================
  CURSOR g_cust_cur
  IS
    SELECT xcsi.cust_shift_id                AS cust_shift_id           -- �ڋq�ڍs���ID
         , xcsi.cust_code                    AS cust_code               -- �ڋq�R�[�h
         , xcsi.prev_base_code               AS prev_base_code          -- ���S�����_�R�[�h
         , xcsi.new_base_code                AS new_base_code           -- �V�S�����_�R�[�h
         , xcsi.cust_shift_date              AS cust_shift_date         -- �ڋq�ڍs��
         , xcsi.target_acctg_year            AS target_acctg_year       -- �Ώۉ�v�N�x
         , xcsi.emp_code                     AS emp_code                -- ���͎҃R�[�h
         , xcsi.input_date                   AS input_date              -- ���͓�
         , xlv1.attribute1                   AS base_divide_status_code -- ���_�����ڍs���X�e�[�^�X�R�[�h
         , xlv2.attribute1                   AS shift_section_type      -- �N���ڍs�敪
         , hl.address3                       AS section_code            -- �s���n��R�[�h
    FROM   xxcok_cust_shift_info             xcsi                       -- �ڋq�ڍs���e�[�u��
         , hz_cust_accounts                  hca                        -- �ڋq�}�X�^
         , hz_cust_acct_sites_all            hcas                       -- �ڋq���ݒn�}�X�^
         , hz_party_sites                    hps                        -- �p�[�e�B�T�C�g�}�X�^
         , hz_locations                      hl                         -- �ڋq���Ə��}�X�^
         , xxcok_lookups_v                   xlv1                       -- �N�C�b�N�R�[�h�r���[
         , xxcok_lookups_v                   xlv2                       -- �N�C�b�N�R�[�h�r���[2
    WHERE  xcsi.cust_code                  = hca.account_number
    AND    xcsi.shift_type                 = cv_shift_type
    AND    xcsi.status                    <> cv_cancel_status
    AND    xlv1.lookup_type                = cv_cust_shift_status
    AND    xlv2.lookup_type                = cv_shift_divide
    AND    xcsi.status                     = xlv1.lookup_code
    AND    xcsi.shift_type                 = xlv2.lookup_code
    AND    hcas.cust_account_id            = hca.cust_account_id
    AND    hcas.party_site_id              = hps.party_site_id
    AND    hl.location_id                  = hps.location_id
    AND    hcas.org_id                     = gn_org_id
    AND    TRUNC( gd_operation_date ) BETWEEN xlv1.start_date_active
                              AND NVL( xlv1.end_date_active, TRUNC( gd_operation_date ) )
    AND    TRUNC( gd_operation_date ) BETWEEN xlv2.start_date_active
                              AND NVL( xlv2.end_date_active, TRUNC( gd_operation_date ) )
    ;
--
  TYPE g_cust_ttype IS TABLE OF g_cust_cur%ROWTYPE;
  g_cust_tab g_cust_ttype;
  -- ===============================
  -- �O���[�o����O
  -- ===============================
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
  --*** ���b�N�G���[ ***
  lock_expt EXCEPTION;
  PRAGMA EXCEPTION_INIT( lock_expt, -54 );
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf  OUT VARCHAR2                         -- �G���[�E���b�Z�[�W
  , ov_retcode OUT VARCHAR2                         -- ���^�[���E�R�[�h
  , ov_errmsg  OUT VARCHAR2                         -- ���[�U�[�E�G���[�E���b�Z�[�W 
  , iv_process_flag IN VARCHAR2                     -- ���͍��ڂ̋N���敪�p�����[�^
  )
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf         VARCHAR2(5000) DEFAULT NULL;  -- �G���[�E���b�Z�[�W
    lv_retcode        VARCHAR2(1)    DEFAULT NULL;  -- ���^�[���E�R�[�h
    lv_errmsg         VARCHAR2(5000) DEFAULT NULL;  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lb_retcode        BOOLEAN        DEFAULT NULL;  -- ���b�Z�[�W�o�͊֐��̖߂�l
    lv_out_msg        VARCHAR2(100)  DEFAULT NULL;  -- ���b�Z�[�W�o�͕ϐ�
    lv_token_value    VARCHAR2(100)  DEFAULT NULL;  -- �g�[�N���o�����[�̕ϐ�
    -- ===============================
    -- ���[�J����O
    -- ===============================
    operation_date_expt EXCEPTION;                  -- �Ɩ��������t�擾�G���[
    get_profile_expt    EXCEPTION;                  -- �v���t�@�C���擾�G���[
    system_operation_date_expt EXCEPTION;           -- �V�X�e���ғ����擾�G���[
--
  BEGIN
    ov_retcode := cv_status_normal;
    --==============================================================
    --���̓p�����[�^�̋N���敪�̍��ڂ����b�Z�[�W�o��
    --==============================================================
    lv_out_msg := xxccp_common_pkg.get_msg(
                    cv_appli_xxcok_name
                  , cv_00076_msg
                  , cv_process_flag_token
                  , iv_process_flag
                  );
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.OUTPUT    -- �o�͋敪
                  , lv_out_msg         -- ���b�Z�[�W
                  , 1                  -- ���s
                  );
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.LOG       -- �o�͋敪
                  , lv_out_msg         -- ���b�Z�[�W
                  , 1                  -- ���s
                  );
    --==============================================================
    --�V�X�e�����t���擾
    --==============================================================
    gd_system_date := SYSDATE;
    --==============================================================
    --�Ɩ��������t���擾
    --==============================================================
    gd_operation_date := xxccp_common_pkg2.get_process_date;
--
    IF ( gd_operation_date IS NULL ) THEN
      RAISE operation_date_expt;
    END IF;
    --==============================================================
    --�N���敪���ʏ�N���̏ꍇ�A�V�X�e���ғ����擾���Ɩ��������t�Ƃ���
    --==============================================================
    IF( iv_process_flag = cv_normal_type ) THEN
      gd_operation_date := xxcok_common_pkg.get_operating_day_f(
                             gd_operation_date    -- ��L�Ŏ擾�����Ɩ��������t
                           , cn_plus_days         -- ����(1)
                           , cn_aft               -- �����敪(2)
                           , cn_cal_type_one      -- �J�����_�[�敪=1(�V�X�e���J�����_)
                           );
    END IF;
--
    IF ( gd_operation_date IS NULL ) THEN
      RAISE system_operation_date_expt;
    END IF;
    --==============================================================
    --�J�X�^���v���t�@�C�����v���t�@�C�����擾
    --==============================================================
    gn_org_id         := TO_NUMBER(FND_PROFILE.VALUE( cv_org_id           ));    -- �c�ƒP��ID
    gv_comp_code      := FND_PROFILE.VALUE( cv_comp_code                   );    -- ��ЃR�[�h
    gn_keep_period    := TO_NUMBER(FND_PROFILE.VALUE( cv_cust_keep_period ));    -- �ێ�����
    gv_cust_dire_path := FND_PROFILE.VALUE( cv_cust_dire_path              );    -- �f�B���N�g���p�X
    gv_cust_file_name := FND_PROFILE.VALUE( cv_cust_file_name              );    -- �t�@�C����
--
    IF(gn_org_id IS NULL ) THEN
      lv_token_value  := cv_org_id;
      RAISE get_profile_expt;
    ELSIF( gv_comp_code IS NULL ) THEN
      lv_token_value  := cv_comp_code;
      RAISE get_profile_expt;
    ELSIF( gn_keep_period IS NULL ) THEN
      lv_token_value  := cv_cust_keep_period;
      RAISE get_profile_expt;
    ELSIF( gv_cust_dire_path IS NULL ) THEN
      lv_token_value  := cv_cust_dire_path;
      RAISE get_profile_expt;
    ELSIF( gv_cust_file_name IS NULL ) THEN
      lv_token_value  := cv_cust_file_name;
      RAISE get_profile_expt;
    END IF;
    --===============================================================
    --�f�B���N�g�����E�t�@�C���������b�Z�[�W�o��
    --===============================================================
    lv_out_msg   := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_dire_name_msg
                    , cv_dire_name_token
                    , xxcok_common_pkg.get_directory_path_f( gv_cust_dire_path )
                    );
    lb_retcode   := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- �o�͋敪
                    , lv_out_msg         -- ���b�Z�[�W
                    , 0                  -- ���s
                    );
    lv_out_msg   := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_file_name_msg
                    , cv_file_name_token
                    , gv_cust_file_name
                    );
    lb_retcode   := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- �o�͋敪
                    , lv_out_msg         -- ���b�Z�[�W
                    , 1                  -- ���s
                    );
--
  EXCEPTION
    -- *** �Ɩ��������t�擾�G���[ ***
    WHEN operation_date_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_operation_date
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- �o�͋敪
                    , lv_out_msg         -- ���b�Z�[�W
                    , 0                  -- ���s
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    WHEN system_operation_date_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_00078_msg
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- �o�͋敪
                    , lv_out_msg         -- ���b�Z�[�W
                    , 0                  -- ���s
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** �v���t�@�C���擾�G���[ ***
    WHEN get_profile_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_profile_err_msg
                    , cv_profile_token
                    , lv_token_value
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- �o�͋敪
                    , lv_out_msg         -- ���b�Z�[�W
                    , 0                  -- ���s
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END init;
--
  /**********************************************************************************
   * Procedure Name   : dlt_data_p
   * Description      : �p�[�W����(A-2)
   ***********************************************************************************/
  PROCEDURE dlt_data_p(
    ov_errbuf  OUT VARCHAR2                               -- �G���[�E���b�Z�[�W
  , ov_retcode OUT VARCHAR2                               -- ���^�[���E�R�[�h
  , ov_errmsg  OUT VARCHAR2                               -- ���[�U�[�E�G���[�E���b�Z�[�W 
  )
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'dlt_data_p'; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL;               -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1)    DEFAULT NULL;               -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL;               -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg VARCHAR2(100)  DEFAULT NULL;               -- ���b�Z�[�W�o�͕ϐ�
    lb_retcode BOOLEAN        DEFAULT NULL;               -- ���b�Z�[�W�o�͊֐��̖߂�l
    ld_months  DATE           DEFAULT NULL;               -- �i�[���[�J���ϐ�
    --==============================================================
    --���b�N�擾�p�J�[�\��
    --==============================================================
    CURSOR l_dlt_cur(
      id_months IN DATE
    )
    IS
      SELECT 'X'
      FROM   xxcok_cust_shift_info xcsi
      WHERE  xcsi.cust_shift_date <= id_months
      FOR UPDATE OF xcsi.cust_shift_id NOWAIT;
--
  BEGIN
--
    ov_retcode := cv_status_normal;
--
    ld_months := ADD_MONTHS(
                   gd_operation_date
                 , - gn_keep_period
                 );
--
    OPEN  l_dlt_cur(
            ld_months
          );
    CLOSE l_dlt_cur;
    --=============================================================
    --�ڋq�ڍs���e�[�u���̍폜����
    --=============================================================
    BEGIN
--
      DELETE
      FROM   xxcok_cust_shift_info   xcsi
      WHERE  xcsi.cust_shift_date <= ld_months;
--
    EXCEPTION
      -- *** �폜�����G���[ ***
      WHEN OTHERS THEN
        lv_out_msg := xxccp_common_pkg.get_msg(
                        cv_appli_xxcok_name
                      , cv_dlt_err_msg
                      );
        lb_retcode := xxcok_common_pkg.put_message_f( 
                        FND_FILE.OUTPUT    -- �o�͋敪
                      , lv_out_msg         -- ���b�Z�[�W
                      , 0                  -- ���s
                      );
        ov_errmsg  := NULL;
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
        ov_retcode := cv_status_error;
    END;
--
  EXCEPTION
    -- *** �ڋq�ڍs��񃍃b�N�擾�G���[ ***
    WHEN lock_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_lock_err_msg
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- �o�͋敪
                    , lv_out_msg         -- ���b�Z�[�W
                    , 0                  -- ���s
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf    := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode   := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf    := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode   := cv_status_error;
  END dlt_data_p;
--
  /**********************************************************************************
   * Procedure Name   : upd_unconfirmed_data_p
   * Description      : ���m��f�[�^���(A-3)
   ***********************************************************************************/
  PROCEDURE upd_unconfirmed_data_p(
    ov_errbuf  OUT VARCHAR2                                           -- �G���[�E���b�Z�[�W
  , ov_retcode OUT VARCHAR2                                           -- ���^�[���E�R�[�h
  , ov_errmsg  OUT VARCHAR2                                           -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_unconfirmed_data_p'; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL;                           -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1)    DEFAULT NULL;                           -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL;                           -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg VARCHAR2(100)  DEFAULT NULL;                           -- ���b�Z�[�W�o�͕ϐ�
    lb_retcode BOOLEAN        DEFAULT NULL;                           -- ���b�Z�[�W�o�͊֐��̖߂�l
    --==============================================================
    --���b�N�擾�p�J�[�\��
    --==============================================================
    CURSOR l_upd_cur
    IS
      SELECT 'X'
      FROM   xxcok_cust_shift_info xcsi
      WHERE  xcsi.cust_shift_date <= gd_operation_date
      AND    xcsi.status           = cv_input_status
      FOR UPDATE OF xcsi.cust_shift_id NOWAIT;
--
  BEGIN
--
    ov_retcode := cv_status_normal;
--
    OPEN  l_upd_cur;
    CLOSE l_upd_cur;
    --=============================================================
    --�ڋq�ڍs���e�[�u���̍X�V����
    --=============================================================
    BEGIN
--
      UPDATE xxcok_cust_shift_info          xcsi
      SET    xcsi.status                  = cv_cancel_status          -- �X�e�[�^�X(���)
           , xcsi.last_updated_by         = cn_last_updated_by        -- ���O�C�����[�U�[ID
           , xcsi.last_update_date        = SYSDATE                   -- �V�X�e�����t
           , xcsi.last_update_login       = cn_last_update_login      -- ���O�C��ID
           , xcsi.request_id              = cn_request_id             -- �R���J�����g�v��ID
           , xcsi.program_application_id  = cn_program_application_id -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
           , xcsi.program_id              = cn_program_id             -- �R���J�����g�E�v���O����ID
           , xcsi.program_update_date     = SYSDATE                   -- �V�X�e�����t
      WHERE  xcsi.cust_shift_date        <= gd_operation_date
      AND    xcsi.status                  = cv_input_status;
--
    EXCEPTION
      -- *** ���m��f�[�^��������G���[ ***
      WHEN OTHERS THEN
        lv_out_msg   := xxccp_common_pkg.get_msg(
                          cv_appli_xxcok_name
                        , cv_upd_err_msg
                        );
        lb_retcode   := xxcok_common_pkg.put_message_f( 
                          FND_FILE.OUTPUT    -- �o�͋敪
                        , lv_out_msg         -- ���b�Z�[�W
                        , 0                  -- ���s
                        );
        ov_errmsg    := NULL;
        ov_errbuf    := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
        ov_retcode   := cv_status_error;
    END;
--
  EXCEPTION
    -- *** �ڋq�ڍs��񃍃b�N�擾�G���[ ***
    WHEN lock_expt THEN
      lv_out_msg   := xxccp_common_pkg.get_msg(
                        cv_appli_xxcok_name
                      , cv_lock_err_msg
                      );
      lb_retcode   := xxcok_common_pkg.put_message_f( 
                        FND_FILE.OUTPUT    -- �o�͋敪
                      , lv_out_msg         -- ���b�Z�[�W
                      , 0                  -- ���s
                      );
      ov_errmsg    := NULL;
      ov_errbuf    := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg, 1, 5000 );
      ov_retcode   := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf    := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode   := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf    := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode   := cv_status_error;
  END upd_unconfirmed_data_p;
--
  /**********************************************************************************
   * Procedure Name   : get_cust_shift_info_p
   * Description      : �A�g�Ώیڋq�ڍs���擾(A-4)
   ***********************************************************************************/
  PROCEDURE get_cust_shift_info_p(
    ov_errbuf  OUT VARCHAR2                                          -- �G���[�E���b�Z�[�W
  , ov_retcode OUT VARCHAR2                                          -- ���^�[���E�R�[�h
  , ov_errmsg  OUT VARCHAR2                                          -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_cust_shift_info_p'; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL;                          -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1)    DEFAULT NULL;                          -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL;                          -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg VARCHAR2(100)  DEFAULT NULL;                          -- ���b�Z�[�W�o�͕ϐ�
    lb_retcode BOOLEAN        DEFAULT NULL;                          -- ���b�Z�[�W�o�͊֐��̖߂�l
    -- ===============================
    -- ���[�J����O
    -- ===============================
    target_data_expt EXCEPTION;                                      -- �Ώی��������G���[
--
  BEGIN
--
    ov_retcode := cv_status_normal;
--
    OPEN  g_cust_cur;
    FETCH g_cust_cur BULK COLLECT INTO g_cust_tab;
    CLOSE g_cust_cur;
--
    --==============================================================
    --�Ώی����Ȃ��`�F�b�N
    --==============================================================
    IF( g_cust_tab.COUNT = 0 ) THEN
      RAISE target_data_expt;
    END IF;
--
  EXCEPTION
    -- *** �Ώی����Ȃ��G���[ ***
    WHEN target_data_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_target_count_err_msg
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- �o�͋敪
                    , lv_out_msg         -- ���b�Z�[�W
                    , 0                  -- ���s
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END get_cust_shift_info_p;
--
  /**********************************************************************************
   * Procedure Name   : open_file_p
   * Description      : �t�@�C���I�[�v��(A-5)
   ***********************************************************************************/
  PROCEDURE open_file_p(
    ov_errbuf  OUT VARCHAR2                                -- �G���[�E���b�Z�[�W
  , ov_retcode OUT VARCHAR2                                -- ���^�[���E�R�[�h
  , ov_errmsg  OUT VARCHAR2                                -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'open_file_p'; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf      VARCHAR2(5000) DEFAULT NULL;            -- �G���[�E���b�Z�[�W
    lv_retcode     VARCHAR2(1)    DEFAULT NULL;            -- ���^�[���E�R�[�h
    lv_errmsg      VARCHAR2(5000) DEFAULT NULL;            -- ���[�U�[�E�G���[�E���b�Z�[�W
    lb_retcode     BOOLEAN        DEFAULT NULL;            -- ���b�Z�[�W�o�͊֐��̖߂�l
    lv_out_msg     VARCHAR2(100)  DEFAULT NULL;            -- ���b�Z�[�W�o�͕ϐ�
    ln_file_length NUMBER         DEFAULT NULL;            -- �t�@�C���̒����̕ϐ�
    ln_block_size  NUMBER         DEFAULT NULL;            -- �u���b�N�T�C�Y�̕ϐ�
    lb_fexists     BOOLEAN        DEFAULT NULL;            -- BOOLEAN�^
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    --=============================================================
    --�t�@�C���̑��݃`�F�b�N
    --=============================================================
    UTL_FILE.FGETATTR(
      location    =>  gv_cust_dire_path
    , filename    =>  gv_cust_file_name
    , fexists     =>  lb_fexists
    , file_length =>  ln_file_length
    , block_size  =>  ln_block_size
    );
--
    IF( lb_fexists = TRUE ) THEN
      -- *** �t�@�C�����݃`�F�b�N�G���[ ***
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_file_err_msg
                    , cv_file_name_token
                    , gv_cust_file_name
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- �o�͋敪
                    , lv_out_msg         -- ���b�Z�[�W
                    , 0                  -- ���s
                    );
      RAISE global_api_expt;
    END IF;
    --=============================================================
    --�t�@�C���̃I�[�v��
    --=============================================================
    g_open_file := UTL_FILE.FOPEN(
                     gv_cust_dire_path
                   , gv_cust_file_name
                   , cv_open_mode
                   , cn_max_linesize
                   );
--
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg    := lv_errmsg;
      ov_errbuf    := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode   := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf    := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode   := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf    := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode   := cv_status_error;
  END open_file_p;
--
  /**********************************************************************************
   * Procedure Name   : create_flat_file_p
   * Description      : �t���b�g�t�@�C���쐬(A-6)
   ***********************************************************************************/
  PROCEDURE create_flat_file_p(
    ov_errbuf  OUT VARCHAR2                                       -- �G���[�E���b�Z�[�W
  , ov_retcode OUT VARCHAR2                                       -- ���^�[���E�R�[�h
  , ov_errmsg  OUT VARCHAR2                                       -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_flat_file_p'; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf            VARCHAR2(5000) DEFAULT NULL;             -- �G���[�E���b�Z�[�W
    lv_retcode           VARCHAR2(1)    DEFAULT NULL;             -- ���^�[���E�R�[�h
    lv_errmsg            VARCHAR2(5000) DEFAULT NULL;             -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg           VARCHAR2(100)  DEFAULT NULL;             -- ���b�Z�[�W�o�͕ϐ�
    lb_retcode           BOOLEAN        DEFAULT NULL;             -- ���b�Z�[�W�o�͊֐��̖߂�l
    lv_flat              VARCHAR2(1500) DEFAULT NULL;             -- �t���b�g�t�@�C���i�[�ϐ�
    lv_cust_shift_id     VARCHAR2(100)  DEFAULT NULL;             -- �ڋq�ڍs���ID�̕ϐ�
    lv_cust_shift_date   VARCHAR2(100)  DEFAULT NULL;             -- �ڋq�ڍs���̕ϐ�
    lv_input_date        VARCHAR2(100)  DEFAULT NULL;             -- ���͓��̕ϐ�
    lv_system_date       VARCHAR2(100)  DEFAULT NULL;             -- �V�X�e�����t�̕ϐ�
    lv_target_acctg_year VARCHAR2(100)  DEFAULT NULL;             -- �Ώۉ�v�N�x
--
  BEGIN
    ov_retcode := cv_status_normal;
--
    --==============================================================
    --�Ώی����J�E���g
    --==============================================================
    gn_target_cnt := g_cust_tab.COUNT;
    --===============================================================
    --���[�v�J�n
    --===============================================================
    <<out_file_loop>>
    FOR i IN 1 .. g_cust_tab.COUNT LOOP
      lv_cust_shift_id     := TO_CHAR( g_cust_tab(i).cust_shift_id               );
      lv_cust_shift_date   := TO_CHAR( g_cust_tab(i).cust_shift_date, 'YYYYMMDD' );
      lv_input_date        := TO_CHAR( g_cust_tab(i).input_date, 'YYYYMMDD'      );
      lv_system_date       := TO_CHAR( gd_system_date, 'YYYYMMDDHH24MISS'        );
      lv_target_acctg_year := TO_CHAR( g_cust_tab(i).target_acctg_year           );
--
      lv_flat := (
        cv_msg_double || gv_comp_code                          || cv_msg_double || cv_msg_comma ||
        cv_msg_double || lv_cust_shift_id                      || cv_msg_double || cv_msg_comma ||
        cv_msg_double || g_cust_tab(i).cust_code               || cv_msg_double || cv_msg_comma ||
        cv_msg_double || g_cust_tab(i).prev_base_code          || cv_msg_double || cv_msg_comma ||
        cv_msg_double || g_cust_tab(i).new_base_code           || cv_msg_double || cv_msg_comma ||
        cv_msg_double || g_cust_tab(i).section_code            || cv_msg_double || cv_msg_comma ||
                         lv_cust_shift_date                    || cv_msg_comma  ||
                         lv_input_date                         || cv_msg_comma  ||
        cv_msg_double || g_cust_tab(i).emp_code                || cv_msg_double || cv_msg_comma ||
        cv_msg_double || lv_target_acctg_year                  || cv_msg_double || cv_msg_comma ||
        cv_msg_double || g_cust_tab(i).shift_section_type      || cv_msg_double || cv_msg_comma ||
        cv_msg_double || g_cust_tab(i).base_divide_status_code || cv_msg_double || cv_msg_comma ||
                         lv_system_date
      );
      --==============================================================
      --�t���b�g�t�@�C�����쐬
      --==============================================================
      UTL_FILE.PUT_LINE(
        file   => g_open_file
      , buffer => lv_flat
      );
--
      --==============================================================
      --���������J�E���g
      --==============================================================
      gn_normal_cnt := gn_normal_cnt + 1;
--
    END LOOP out_file_loop;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf    := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode   := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf    := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode   := cv_status_error;
  END create_flat_file_p;
--
  /**********************************************************************************
   * Procedure Name   : close_file_p
   * Description      : �t�@�C���N���[�Y(A-7)
   ***********************************************************************************/
  PROCEDURE close_file_p(
    ov_errbuf  OUT VARCHAR2                                 -- �G���[�E���b�Z�[�W
  , ov_retcode OUT VARCHAR2                                 -- ���^�[���E�R�[�h
  , ov_errmsg  OUT VARCHAR2                                 -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'close_file_p'; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1)    DEFAULT NULL;                 -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg VARCHAR2(100)  DEFAULT NULL;                 -- ���b�Z�[�W�o�͕ϐ�
    lb_retcode BOOLEAN        DEFAULT NULL;                 -- ���b�Z�[�W�o�͊֐��̖߂�l
--
  BEGIN
    ov_retcode := cv_status_normal;
    --==============================================================
    --�I�[�v���E�t�@�C�����t�@�C���E�n���h�������ʂ��Ă��邩�e�X�g
    --==============================================================
    IF( UTL_FILE.IS_OPEN( g_open_file ) ) THEN
      --==============================================================
      --�t�@�C���̃N���[�Y
      --==============================================================
      UTL_FILE.FCLOSE(
        file => g_open_file
      );
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf    := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode   := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf    := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode   := cv_status_error;
  END close_file_p;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf  OUT VARCHAR2                            -- �G���[�E���b�Z�[�W
  , ov_retcode OUT VARCHAR2                            -- ���^�[���E�R�[�h
  , ov_errmsg  OUT VARCHAR2                            -- ���[�U�[�E�G���[�E���b�Z�[�W
  , iv_process_flag IN VARCHAR2                        -- ���͍��ڂ̋N���敪�p�����[�^
  )
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL;            -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1)    DEFAULT NULL;            -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL;            -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg VARCHAR2(100)  DEFAULT NULL;            -- ���b�Z�[�W�o�͕ϐ�
    lb_retcode BOOLEAN        DEFAULT NULL;            -- ���b�Z�[�W�o�͊֐��̖߂�l
    -- ===============================
    -- ���[�J����O
    -- ===============================
    file_close_expt EXCEPTION;
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    --==============================================================
    --�O���[�o���ϐ��̏�����
    --==============================================================
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    --===============================================================
    --init�̌Ăяo��
    --===============================================================
    init(
      ov_errbuf  => lv_errbuf                          -- �G���[�E���b�Z�[�W
    , ov_retcode => lv_retcode                         -- ���^�[���E�R�[�h
    , ov_errmsg  => lv_errmsg                          -- ���[�U�[�E�G���[�E���b�Z�[�W
    , iv_process_flag => iv_process_flag               -- ���͍��ڂ̋N���敪�p�����[�^
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --==============================================================
    --�p�[�W�����Ăяo��
    --==============================================================
    dlt_data_p(
      ov_errbuf  => lv_errbuf                          -- �G���[�E���b�Z�[�W
    , ov_retcode => lv_retcode                         -- ���^�[���E�R�[�h
    , ov_errmsg  => lv_errmsg                          -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --==============================================================
    --���m��f�[�^����Ăяo��
    --==============================================================
    upd_unconfirmed_data_p(
      ov_errbuf  => lv_errbuf                          -- �G���[�E���b�Z�[�W
    , ov_retcode => lv_retcode                         -- ���^�[���E�R�[�h
    , ov_errmsg  => lv_errmsg                          -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --=============================================================
    --�R�~�b�g
    --=============================================================
    COMMIT;
--
    gv_commit_flag := cv_commit_flag;
    --==============================================================
    --�A�g�Ώیڋq�ڍs���擾�̌Ăяo��
    --==============================================================
    get_cust_shift_info_p(
      ov_errbuf  => lv_errbuf                          -- �G���[�E���b�Z�[�W
    , ov_retcode => lv_retcode                         -- ���^�[���E�R�[�h
    , ov_errmsg  => lv_errmsg                          -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --==============================================================
    --�t�@�C���I�[�v���Ăяo��
    --==============================================================
    open_file_p(
      ov_errbuf  => lv_errbuf                          -- �G���[�E���b�Z�[�W
    , ov_retcode => lv_retcode                         -- ���^�[���E�R�[�h
    , ov_errmsg  => lv_errmsg                          -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --==============================================================
    --�t���b�g�t�@�C���쐬�̌Ăяo��
    --==============================================================
    create_flat_file_p(
      ov_errbuf  => lv_errbuf                          -- �G���[�E���b�Z�[�W
    , ov_retcode => lv_retcode                         -- ���^�[���E�R�[�h
    , ov_errmsg  => lv_errmsg                          -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --==============================================================
    --�t�@�C���N���[�Y�Ăяo��
    --==============================================================
    close_file_p(
      ov_errbuf  => lv_errbuf                          -- �G���[�E���b�Z�[�W
    , ov_retcode => lv_retcode                         -- ���^�[���E�R�[�h
    , ov_errmsg  => lv_errmsg                          -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE file_close_expt;
    END IF;
--
  EXCEPTION
    WHEN file_close_expt THEN
      ov_errmsg    := lv_errmsg;
      ov_errbuf    := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode   := cv_status_error;
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg    := lv_errmsg;
      ov_errbuf    := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode   := cv_status_error;
      close_file_p(
        ov_errbuf   => lv_errbuf                       -- �G���[�E���b�Z�[�W
      , ov_retcode  => lv_retcode                      -- ���^�[���E�R�[�h
      , ov_errmsg   => lv_errmsg                       -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf    := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode   := cv_status_error;
      close_file_p(
        ov_errbuf   => lv_errbuf                       -- �G���[�E���b�Z�[�W
      , ov_retcode  => lv_retcode                      -- ���^�[���E�R�[�h
      , ov_errmsg   => lv_errmsg                       -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf    := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode   := cv_status_error;
      close_file_p(
        ov_errbuf   => lv_errbuf                       -- �G���[�E���b�Z�[�W
      , ov_retcode  => lv_retcode                      -- ���^�[���E�R�[�h
      , ov_errmsg   => lv_errmsg                       -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
  PROCEDURE main(
    errbuf  OUT VARCHAR2                                              -- �G���[�E���b�Z�[�W
  , retcode OUT VARCHAR2                                              -- ���^�[���E�R�[�h
  , iv_process_flag IN VARCHAR2                                       -- ���͍��ڂ̋N���敪�p�����[�^
  )
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'main';             -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;                      -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)    DEFAULT NULL;                      -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;                      -- ���[�U�[�E�G���[�E���b�Z�[�W
    lb_retcode      BOOLEAN        DEFAULT NULL;                      -- ���b�Z�[�W�o�͊֐��̖߂�l
    lv_out_msg      VARCHAR2(100)  DEFAULT NULL;                      -- ���b�Z�[�W�ϐ�
    lv_message_code VARCHAR2(100)  DEFAULT NULL;                      -- ���b�Z�[�W�R�[�h
    lv_commit_code  VARCHAR2(100)  DEFAULT NULL;                      -- �R�~�b�g���b�Z�[�W�R�[�h
  BEGIN
    --==============================================================
    --�R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    --==============================================================
    xxccp_common_pkg.put_log_header(
      ov_retcode => lv_retcode
    , ov_errbuf  => lv_errbuf
    , ov_errmsg  => lv_errmsg
    );
--
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.OUTPUT    -- �o�͋敪
                  , NULL               -- ���b�Z�[�W
                  , 1                  -- ���s
                  );
--
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    --==============================================================
    --submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    --==============================================================
    submain(
      ov_errbuf  => lv_errbuf                               -- �G���[�E���b�Z�[�W
    , ov_retcode => lv_retcode                              -- ���^�[���E�R�[�h
    , ov_errmsg  => lv_errmsg                               -- ���[�U�[�E�G���[�E���b�Z�[�W
    , iv_process_flag => iv_process_flag                    -- ���͍��ڂ̋N���敪�p�����[�^
    );
    --==============================================================
    --�G���[�o��
    --==============================================================
    IF ( lv_retcode = cv_status_error ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- �o�͋敪
                    , lv_errmsg          -- ���b�Z�[�W
                    , 1                  -- ���s
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.LOG       -- �o�͋敪
                    , lv_errbuf          -- ���b�Z�[�W
                    , 0                  -- ���s
                    );
    END IF;
    --==============================================================
    --�Ώی����o��
    --==============================================================
    IF( lv_retcode = cv_status_error ) THEN
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
--
    lv_out_msg := xxccp_common_pkg.get_msg(
                    cv_appli_xxccp_name
                  , cv_target_count_msg
                  , cv_count_token
                  , TO_CHAR( gn_target_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.OUTPUT    -- �o�͋敪
                  , lv_out_msg         -- ���b�Z�[�W
                  , 0                  -- ���s
                  );
    --==============================================================
    --���������o��
    --==============================================================
    lv_out_msg := xxccp_common_pkg.get_msg(
                    cv_appli_xxccp_name
                  , cv_normal_count_msg
                  , cv_count_token
                  , TO_CHAR( gn_normal_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.OUTPUT    -- �o�͋敪
                  , lv_out_msg         -- ���b�Z�[�W
                  , 0                  -- ���s
                  );
    --==============================================================
    --�G���[�����o��
    --==============================================================
    lv_out_msg := xxccp_common_pkg.get_msg(
                    cv_appli_xxccp_name
                  , cv_err_count_msg
                  , cv_count_token
                  , TO_CHAR( gn_error_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.OUTPUT    -- �o�͋敪
                  , lv_out_msg         -- ���b�Z�[�W
                  , 0                  -- ���s
                  );
    --==============================================================
    --�I�����b�Z�[�W
    --==============================================================
    IF( lv_retcode     = cv_status_normal ) THEN
      lv_message_code  := cv_normal_msg;
      retcode          := cv_status_normal;
      lv_out_msg       := xxccp_common_pkg.get_msg(
                            cv_appli_xxccp_name
                          , lv_message_code
                          );
    ELSIF( ( lv_retcode  = cv_status_error )
      AND ( gv_commit_flag = cv_commit_flag ) ) THEN
        lv_commit_code   := cv_commit_msg;
        retcode          := cv_status_error;
        lv_out_msg       := xxccp_common_pkg.get_msg(
                              cv_appli_xxcok_name
                            , lv_commit_code
                            );
    ELSIF( lv_retcode  = cv_status_error ) THEN
      lv_message_code  := cv_err_msg;
      retcode          := cv_status_error;
      lv_out_msg       := xxccp_common_pkg.get_msg(
                            cv_appli_xxccp_name
                          , lv_message_code
                          );
    END IF;
--
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.OUTPUT    -- �o�͋敪
                  , lv_out_msg         -- ���b�Z�[�W
                  , 0                  -- ���s
                  );
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ROLLBACK;
      errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ROLLBACK;
      errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ROLLBACK;
      errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      retcode := cv_status_error;
  END main;
END XXCOK001A03C;
/