CREATE OR REPLACE PACKAGE BODY XXCFF019A02C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2017. All rights reserved.
 *
 * Package Name     : XXCFF019A02C(body)
 * Description      : IFRS�䒠�ꊇ�ǉ�
 * MD.050           : MD050_CFF_019_A02_IFRS�䒠�ꊇ�ǉ�
 * Version          : 1.0
 *
 * Program List
 * ----------------------------- ----------------------------------------------------------
 *  Name                          Description
 * ----------------------------- ----------------------------------------------------------
 *  init                          ��������                                  (A-1)
 *  get_profile_values            �v���t�@�C���l�擾                        (A-2)
 *  chk_period                    ��v���ԃ`�F�b�N                          (A-3)
 *  get_exec_date                 ���s�����擾                              (A-4)
 *  get_ifrs_fa_add_data          IFRS�䒠�o�^�f�[�^���o                    (A-5)
 *  upd_ifrs_sets                 IFRS�䒠�A�g�Z�b�g�X�V                    (A-6)
 *  submain                       ���C�������v���V�[�W��
 *  main                          �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2017/11/13    1.0   SCSK�O�c         �V�K�쐬
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
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
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
  --*** ��v���ԃ`�F�b�N�G���[
  chk_period_expt           EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  data_lock_expt            EXCEPTION;        -- ���R�[�h���b�N�G���[
  PRAGMA EXCEPTION_INIT(data_lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name         CONSTANT VARCHAR2(100):= 'XXCFF019A02C'; -- �p�b�P�[�W��
--
  -- ***�A�v���P�[�V�����Z�k��
  cv_msg_kbn_cff      CONSTANT VARCHAR2(5)  := 'XXCFF';
--
  -- ***���b�Z�[�W��(�{��)
  cv_msg_019a02_m_010 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00020'; -- �v���t�@�C���擾�G���[
  cv_msg_019a02_m_011 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00037'; -- ��v���ԃ`�F�b�N�G���[
  cv_msg_019a02_m_013 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00262'; -- IFRS�䒠�ꊇ�o�^�쐬���b�Z�[�W
  cv_msg_019a02_m_014 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00263'; -- IFRS�䒠�ꊇ�o�^�G���[
  cv_msg_019a02_m_017 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00165'; -- �擾�Ώۃf�[�^�������b�Z�[�W
  cv_msg_019a02_m_018 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00268'; -- ���Y�J�e�S�����擾�G���[
  cv_msg_019a02_m_019 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00007'; -- ���b�N�G���[
  -- ***���b�Z�[�W��(�g�[�N��)
  cv_msg_019a02_t_010 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50228'; -- XXCFF:�䒠���_�Œ莑�Y�䒠
  cv_msg_019a02_t_011 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50314'; -- XXCFF:�䒠���_IFRS�䒠
  cv_msg_019a02_t_012 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50315'; -- �Œ莑�Y�䒠���
  cv_msg_019a02_t_013 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50316'; -- IFRS�䒠�A�g�Z�b�g
  cv_msg_019a02_t_014 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50318'; -- XXCFF:IFRS���p���@
--
  -- ***�g�[�N����
  cv_tkn_prof         CONSTANT VARCHAR2(20) := 'PROF_NAME';
  cv_tkn_asset_number CONSTANT VARCHAR2(20) := 'ASSET_NUMBER';
  cv_tkn_bk_type      CONSTANT VARCHAR2(20) := 'BOOK_TYPE_CODE';
  cv_tkn_period       CONSTANT VARCHAR2(20) := 'PERIOD_NAME';
  cv_tkn_get_data     CONSTANT VARCHAR2(20) := 'GET_DATA';
  cv_tkn_category     CONSTANT VARCHAR2(20) := 'CATEGORY';
  cv_tkn_table_name   CONSTANT VARCHAR2(20) := 'TABLE_NAME';
--
  -- ***�v���t�@�C��
  cv_fixed_asset_register   CONSTANT VARCHAR2(30) := 'XXCFF1_FIXED_ASSET_REGISTER';       -- �䒠���_�Œ莑�Y�䒠
  cv_fixed_ifrs_asset_regi  CONSTANT VARCHAR2(35) := 'XXCFF1_FIXED_IFRS_ASSET_REGISTER';  -- �䒠���_IFRS�䒠
  cv_cat_deprn_ifrs         CONSTANT VARCHAR2(30) := 'XXCFF1_CAT_DEPRN_IFRS';             -- IFRS���p���@
--
  -- ***�t�@�C���o��
  cv_file_type_out   CONSTANT VARCHAR2(10) := 'OUTPUT'; -- ���b�Z�[�W�o��
  cv_file_type_log   CONSTANT VARCHAR2(10) := 'LOG';    -- ���O�o��
--
  cv_haifun          CONSTANT VARCHAR2(1)  := '-';      -- -(�n�C�t��)
  cn_zero_0          CONSTANT NUMBER       := 0;        -- ���l�[��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ***�o���N�t�F�b�`�p��`
  -- IFRS�䒠�ꊇ�o�^�Ώۃf�[�^���R�[�h�^
  TYPE g_ifrs_fa_add_rtype IS RECORD(
    description                 fa_additions_tl.description%TYPE,                   -- �E�v
    date_placed_in_service      fa_books.date_placed_in_service%TYPE,               -- ���Ƌ��p��
    original_cost               fa_books.original_cost%TYPE,                        -- �����擾���z
    fixed_assets_units          fa_additions_b.current_units%TYPE,                  -- �P�ʐ���
    location_id                 fa_distribution_history.location_id%TYPE,           -- ���Ə��t���b�N�X�t�B�[���hCCID
    depreciate_flag             fa_books.depreciate_flag%TYPE,                      -- ���p��v��t���O
    parent_asset_id             fa_additions_b.parent_asset_id%TYPE,                -- �e���YID
    asset_key_ccid              fa_additions_b.asset_key_ccid%TYPE,                 -- ���Y�L�[CCID
    asset_type                  fa_additions_b.asset_type%TYPE,                     -- ���Y�^�C�v
    attribute1                  fa_additions_b.attribute1%TYPE,                     -- DFF1�i�X�V�p���Ƌ��p���j
    attribute2                  fa_additions_b.attribute2%TYPE,                     -- DFF2�i�擾���j
    attribute3                  fa_additions_b.attribute3%TYPE,                     -- DFF3�i�\���j
    attribute4                  fa_additions_b.attribute4%TYPE,                     -- DFF4�i�זځj
    attribute5                  fa_additions_b.attribute5%TYPE,                     -- DFF5�i���k�L�^�E�T�������j
    attribute6                  fa_additions_b.attribute6%TYPE,                     -- DFF6�i���k�T���z�j
    attribute7                  fa_additions_b.attribute7%TYPE,                     -- DFF7�i���k��擾���i�j
    attribute8                  fa_additions_b.attribute8%TYPE,                     -- DFF8�i���Y�O���[�v�ԍ��j
    attribute9                  fa_additions_b.attribute9%TYPE,                     -- DFF9�i�����v�Z���ԗ����j
    attribute10                 fa_additions_b.attribute10%TYPE,                    -- DFF10�i�_�񖾍ד���ID�j
    attribute11                 fa_additions_b.attribute11%TYPE,                    -- DFF11�i���[�X���Y��ʁj
    attribute12                 fa_additions_b.attribute12%TYPE,                    -- DFF12�i�J���Z�O�����g�j
    attribute13                 fa_additions_b.attribute13%TYPE,                    -- DFF13�i�ʐρj
    attribute14                 fa_additions_b.attribute14%TYPE,                    -- DFF14�i���̋@��������ID�j
    attribute15                 fa_additions_b.attribute15%TYPE,                    -- DFF15�iIFRS�ϗp�N���j
    attribute16                 fa_additions_b.attribute16%TYPE,                    -- DFF16�iIFRS���p�j
    attribute17                 fa_additions_b.attribute17%TYPE,                    -- DFF17�i�s���Y�擾�Łj
    attribute18                 fa_additions_b.attribute18%TYPE,                    -- DFF18�i�ؓ��R�X�g�j
    attribute19                 fa_additions_b.attribute19%TYPE,                    -- DFF19�i���̑��j
    attribute20                 fa_additions_b.attribute20%TYPE,                    -- DFF20�iIFRS���Y�Ȗځj
    attribute21                 fa_additions_b.attribute21%TYPE,                    -- DFF21�i�C���N�����j
    asset_number                fa_additions_b.asset_number%TYPE,                   -- ���Y�ԍ�
    fc_segment1                 fa_categories.segment1%TYPE,                        -- ���Y�J�e�S��-���
    fc_segment2                 fa_categories.segment2%TYPE,                        -- ���Y�J�e�S��-�\�����p
    fc_segment3                 fa_categories.segment3%TYPE,                        -- ���Y�J�e�S��-���Y����
    fc_segment4                 fa_categories.segment4%TYPE,                        -- ���Y�J�e�S��-���p�Ȗ�
    fc_segment5                 fa_categories.segment5%TYPE,                        -- ���Y�J�e�S��-�ϗp�N��
    fc_segment7                 fa_categories.segment7%TYPE,                        -- ���Y�J�e�S��-���[�X���
    gcc_segment1                gl_code_combinations.segment1%TYPE,                 -- ���
    gcc_segment2                gl_code_combinations.segment2%TYPE,                 -- ����
    gcc_segment4                gl_code_combinations.segment4%TYPE,                 -- �⏕�Ȗ�
    gcc_segment5                gl_code_combinations.segment5%TYPE,                 -- �ڋq
    gcc_segment6                gl_code_combinations.segment6%TYPE,                 -- ���
    gcc_segment7                gl_code_combinations.segment7%TYPE,                 -- �\���P
    gcc_segment8                gl_code_combinations.segment8%TYPE                  -- �\���Q
  );
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- ***�o���N�t�F�b�`�p��`
  -- IFRS�䒠�ꊇ�o�^�Ώۃf�[�^���R�[�h�z��
  TYPE g_ifrs_fa_add_ttype IS TABLE OF g_ifrs_fa_add_rtype
  INDEX BY BINARY_INTEGER;
--
  g_ifrs_fa_add_tab         g_ifrs_fa_add_ttype;  -- IFRS�䒠�ꊇ�ǉ��Ώۃf�[�^
--
  -- �����l���
  g_init_rec  xxcff_common1_pkg.init_rtype;
--
  -- �p�����[�^��v���Ԗ�
  gv_period_name            VARCHAR2(100);
--
  -- ���s����
  gt_exec_date  xxcff_ifrs_sets.exec_date%TYPE;
--
  -- ***�v���t�@�C���l
  gv_fixed_asset_register   VARCHAR2(100);  -- �䒠���_�Œ莑�Y�䒠
  gv_fixed_ifrs_asset_regi  VARCHAR2(100);  -- �䒠���_IFRS�䒠
  gv_cat_deprn_ifrs         VARCHAR2(100);  -- IFRS���p���@
--
  -- �Z�O�����g�l�z��(EBS�W���֐�fnd_flex_ext�p)
  g_segments_tab  fnd_flex_ext.segmentarray;
--
  -- ***��������
  -- IFRS�䒠�ꊇ�ǉ������ɂ����錏��
  gn_ifrs_fa_add_target_cnt NUMBER;     -- �Ώی���
  gn_loop_cnt               NUMBER;     -- LOOP��
  gn_ifrs_fa_add_normal_cnt NUMBER;     -- ���팏��
  gn_ifrs_fa_add_err_cnt    NUMBER;     -- �G���[����
--
  /**********************************************************************************
   * Procedure Name   : upd_ifrs_sets
   * Description      : IFRS�䒠�A�g�Z�b�g�X�V (A-6)
   ***********************************************************************************/
  PROCEDURE upd_ifrs_sets(
    ov_errbuf      OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_ifrs_sets'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    UPDATE xxcff_ifrs_sets  xis       -- IFRS�䒠�A�g�Z�b�g
    SET    xis.exec_date              = cd_last_update_date         -- ���s����
          ,xis.last_updated_by        = cn_last_updated_by          -- �ŏI�X�V��
          ,xis.last_update_date       = cd_last_update_date         -- �ŏI�X�V��
          ,xis.last_update_login      = cn_last_update_login        -- �ŏI�X�V���O�C��ID
          ,xis.request_id             = cn_request_id               -- �v��ID
          ,xis.program_application_id = cn_program_application_id   -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          ,xis.program_id             = cn_program_id               -- �R���J�����g�E�v���O����ID
          ,xis.program_update_date    = cd_program_update_date      -- �v���O�����X�V��
    WHERE  xis.exec_id                = cv_pkg_name                 -- ����ID
    ;
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
  END upd_ifrs_sets;
--
  /**********************************************************************************
   * Procedure Name   : get_ifrs_fa_add_data
   * Description      : IFRS�䒠�o�^�f�[�^���o(A-5)
   ***********************************************************************************/
  PROCEDURE get_ifrs_fa_add_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name           CONSTANT VARCHAR2(100) := 'get_ifrs_fa_add_data'; -- �v���O������
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
    -- *** ���[�J���萔 ***
    cn_segment_count      CONSTANT NUMBER := 8;                             -- �Z�O�����g��
    cv_tran_type_add      CONSTANT VARCHAR2(8)   := 'ADDITION';             -- ����^�C�v�R�[�h(�ǉ�)
    cv_lang               CONSTANT fa_additions_tl.language%TYPE := USERENV( 'LANG' );      -- ����
    cv_value_zero         CONSTANT VARCHAR2(1)   := '0';                    -- �����[��
    cv_posting_status     CONSTANT VARCHAR2(4)   := 'POST';                 -- �]�L�X�e�[�^�X(POST)
    cv_queue_name         CONSTANT VARCHAR2(4)   := 'POST';                 -- �L���[��(POST)
--
    -- *** ���[�J���ϐ� ***
    lv_warnmsg            VARCHAR2(5000);                                         -- �x�����b�Z�[�W
    lb_ret                BOOLEAN;                                                -- �֐����^�[���R�[�h
    --
    lt_segment1           fa_categories.segment1%TYPE;                            -- ���
    lt_segment2           fa_categories.segment2%TYPE;                            -- �\�����p
    lt_segment3           fa_categories.segment3%TYPE;                            -- ���Y����
    lt_segment4           fa_categories.segment4%TYPE;                            -- ���p�Ȗ�
    lt_segment5           fa_categories.segment5%TYPE;                            -- �ϗp�N��
    lt_segment6           fa_categories.segment6%TYPE;                            -- ���p���@
    lt_segment7           fa_categories.segment7%TYPE;                            -- ���[�X���
    lt_asset_category_id  fa_mass_additions.asset_category_id%TYPE;               -- ���Y�J�e�S��CCID
    lt_deprn_ccid         fa_mass_additions.expense_code_combination_id%TYPE;     -- �������p���CCID
    lt_fixed_assets_cost  fa_mass_additions.fixed_assets_cost%TYPE;               -- �擾���z
    lt_payables_cost      fa_mass_additions.payables_cost%TYPE;                   -- ���Y�����擾���z
    lv_category           VARCHAR2(216);                                          -- �J�e�S���l
    lt_deprn_expense_acct fa_category_books.deprn_expense_acct%TYPE;              -- �������p���
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �Œ莑�Y�䒠�J�[�\��
    CURSOR ifrs_fa_add_cur
    IS
      SELECT  fat.description             AS description              -- �E�v
             ,fb.date_placed_in_service   AS date_placed_in_service   -- ���Ƌ��p��
             ,fb.original_cost            AS original_cost            -- �����擾���z
             ,fab.current_units           AS fixed_assets_units       -- �P�ʐ���
             ,fdh.location_id             AS location_id              -- ���Ə��t���b�N�X�t�B�[���hCCID
             ,fb.depreciate_flag          AS depreciate_flag          -- ���p��v��t���O
             ,fab.parent_asset_id         AS parent_asset_id          -- �e���YID
             ,fab.asset_key_ccid          AS asset_key_ccid           -- ���Y�L�[CCID
             ,fab.asset_type              AS asset_type               -- ���Y�^�C�v
             ,fab.attribute1              AS attribute1               -- DFF1�i�X�V�p���Ƌ��p���j
             ,fab.attribute2              AS attribute2               -- DFF2�i�擾���j
             ,fab.attribute3              AS attribute3               -- DFF3�i�\���j
             ,fab.attribute4              AS attribute4               -- DFF4�i�זځj
             ,fab.attribute5              AS attribute5               -- DFF5�i���k�L�^�E�T�������j
             ,fab.attribute6              AS attribute6               -- DFF6�i���k�T���z�j
             ,fab.attribute7              AS attribute7               -- DFF7�i���k��擾���i�j
             ,fab.attribute8              AS attribute8               -- DFF8�i���Y�O���[�v�ԍ��j
             ,fab.attribute9              AS attribute9               -- DFF9�i�����v�Z���ԗ����j
             ,fab.attribute10             AS attribute10              -- DFF10�i�_�񖾍ד���ID�j
             ,fab.attribute11             AS attribute11              -- DFF11�i���[�X���Y��ʁj
             ,fab.attribute12             AS attribute12              -- DFF12�i�J���Z�O�����g�j
             ,fab.attribute13             AS attribute13              -- DFF13�i�ʐρj
             ,fab.attribute14             AS attribute14              -- DFF14�i���̋@��������ID�j
             ,fab.attribute15             AS attribute15              -- DFF15�iIFRS�ϗp�N���j
             ,fab.attribute16             AS attribute16              -- DFF16�iIFRS���p�j
             ,fab.attribute17             AS attribute17              -- DFF17�i�s���Y�擾�Łj
             ,fab.attribute18             AS attribute18              -- DFF18�i�ؓ��R�X�g�j
             ,fab.attribute19             AS attribute19              -- DFF19�i���̑��j
             ,fab.attribute20             AS attribute20              -- DFF20�iIFRS���Y�Ȗځj
             ,fab.attribute21             AS attribute21              -- DFF21�i�C���N�����j
             ,fab.asset_number            AS asset_number             -- ���Y�ԍ�
             ,fc.segment1                 AS fc_segment1              -- ���Y�J�e�S��-���
             ,fc.segment2                 AS fc_segment2              -- ���Y�J�e�S��-�\�����p
             ,fc.segment3                 AS fc_segment3              -- ���Y�J�e�S��-���Y����
             ,fc.segment4                 AS fc_segment4              -- ���Y�J�e�S��-���p�Ȗ�
             ,fc.segment5                 AS fc_segment5              -- ���Y�J�e�S��-�ϗp�N��
             ,fc.segment7                 AS fc_segment7              -- ���Y�J�e�S��-���[�X���
             ,gcc.segment1                AS gcc_segment1             -- ���
             ,gcc.segment2                AS gcc_segment2             -- ����
             ,gcc.segment4                AS gcc_segment4             -- �⏕�Ȗ�
             ,gcc.segment5                AS gcc_segment5             -- �ڋq
             ,gcc.segment6                AS gcc_segment6             -- ���
             ,gcc.segment7                AS gcc_segment7             -- �\���P
             ,gcc.segment8                AS gcc_segment8             -- �\���Q
      FROM    fa_books                  fb        -- ���Y�䒠���
             ,fa_additions_b            fab       -- ���Y�ڍ׏��
             ,fa_additions_tl           fat       -- ���Y�E�v���
             ,fa_distribution_history   fdh       -- ���Y�����������
             ,fa_categories             fc        -- ���Y�J�e�S��
             ,gl_code_combinations      gcc       -- GL����Ȗ�
      WHERE   fb.book_type_code             = gv_fixed_asset_register   -- ���Y�䒠��
      AND     fb.transaction_header_id_in   IN (
                                                SELECT  fth.transaction_header_id   AS trans_header_id  -- �L������w�b�_ID
                                                FROM    fa_transaction_headers fth
                                                WHERE   fth.transaction_type_code = cv_tran_type_add    -- ����^�C�v�R�[�h
                                                AND     fth.book_type_code        = fb.book_type_code   -- ���Y�䒠��
                                                AND     fth.asset_id              = fab.asset_id        -- ���YID
                                                AND     fth.date_effective        > gt_exec_date
                                               )
      AND     fab.asset_id                  = fat.asset_id
      AND     fat.language                  = cv_lang
      AND     fab.asset_id                  = fdh.asset_id
      AND     fb.book_type_code             = fdh.book_type_code
      AND     fdh.transaction_header_id_out IS NULL
      AND     fab.asset_category_id         = fc.category_id
      AND     fdh.code_combination_id       = gcc.code_combination_id
      AND     NOT EXISTS (
                SELECT 1
                FROM   fa_additions_b  ifrs_fab
                WHERE  ifrs_fab.attribute22 = fab.asset_number
                         )
      ;
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --==============================================================
    --���C���f�[�^���o
    --==============================================================
    -- �J�[�\���I�[�v��
    OPEN ifrs_fa_add_cur;
    -- �f�[�^�̈ꊇ�擾
    FETCH ifrs_fa_add_cur BULK COLLECT INTO  g_ifrs_fa_add_tab;
    -- �J�[�\���N���[�Y
    CLOSE ifrs_fa_add_cur;
    -- �Ώی����̎擾
    gn_ifrs_fa_add_target_cnt := g_ifrs_fa_add_tab.COUNT;
--
    -- �V�K�o�^�Ώی�����0���̏ꍇ
    IF ( gn_ifrs_fa_add_target_cnt = cn_zero_0 ) THEN
      --���b�Z�[�W�̐ݒ�
      lv_warnmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                     ,cv_msg_019a02_m_017  -- �擾�Ώۃf�[�^����
                                                     ,cv_tkn_get_data      -- �g�[�N��'GET_DATA'
                                                     ,cv_msg_019a02_t_012) -- �Œ莑�Y�䒠���
                                                     ,1
                                                     ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG  --���O(�V�X�e���Ǘ��җp���b�Z�[�W)�o��
        ,buff   => lv_warnmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
        ,buff   => lv_warnmsg
      );
    END IF;
--
    -- LOOP��������
    gn_loop_cnt := 0;
--
    -- ***************************************
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
    --==============================================================
    --���C�����[�v����
    --==============================================================
    <<ifrs_fa_add_loop>>
    FOR ln_loop_cnt IN 1 .. gn_ifrs_fa_add_target_cnt LOOP
--
      -- LOOP���擾
      gn_loop_cnt := ln_loop_cnt;
--
      -- �ȉ��̕ϐ�������������
      lt_asset_category_id  := NULL;    -- ���Y�J�e�S��CCID
      lt_deprn_ccid         := NULL;    -- �������p���CCID
      lt_fixed_assets_cost  := NULL;    -- �擾���z
      lt_payables_cost      := NULL;    -- ���Y�����擾���z
      lv_category           := NULL;    -- �J�e�S���l
      lt_deprn_expense_acct := NULL;    -- �������p���
--
      -- ���ʊ֐� ���Y�J�e�S���`�F�b�N��IN�p�����[�^(segment1�`7)�̒l��ݒ�
      lt_segment1 := g_ifrs_fa_add_tab(ln_loop_cnt).fc_segment1;  -- ���
      lt_segment2 := g_ifrs_fa_add_tab(ln_loop_cnt).fc_segment2;  -- �\�����p
      --
      -- ���Y����
      -- DFF20�iIFRS���Y�Ȗځj�ɒl���ݒ肳��Ă���ꍇ
      IF (g_ifrs_fa_add_tab(ln_loop_cnt).attribute20 IS NOT NULL) THEN
        lt_segment3 := g_ifrs_fa_add_tab(ln_loop_cnt).attribute20;  -- DFF20�iIFRS���Y�Ȗځj
      ELSE
        lt_segment3 := g_ifrs_fa_add_tab(ln_loop_cnt).fc_segment3;  -- ���Y�J�e�S��-���Y����
      END IF;
      --
      lt_segment4 := g_ifrs_fa_add_tab(ln_loop_cnt).fc_segment4;    -- ���p�Ȗ�
      --
      -- �ϗp�N��
      -- DFF15�iIFRS�ϗp�N���j�ɒl���ݒ肳��Ă���ꍇ
      IF (g_ifrs_fa_add_tab(ln_loop_cnt).attribute15 IS NOT NULL) THEN
        lt_segment5 := g_ifrs_fa_add_tab(ln_loop_cnt).attribute15;  -- DFF15�iIFRS�ϗp�N���j
      ELSE
        lt_segment5 := g_ifrs_fa_add_tab(ln_loop_cnt).fc_segment5;  -- ���Y�J�e�S��-�ϗp�N��
      END IF;
      --
      -- ���p���@
      -- DFF16�iIFRS���p�j�ɒl���ݒ肳��Ă���ꍇ
      IF (g_ifrs_fa_add_tab(ln_loop_cnt).attribute16 IS NOT NULL) THEN
        lt_segment6 := g_ifrs_fa_add_tab(ln_loop_cnt).attribute16;  -- DFF16�iIFRS���p�j
      ELSE
        lt_segment6 := gv_cat_deprn_ifrs;                           -- IFRS���p���@
      END IF;
      --
      lt_segment7 := g_ifrs_fa_add_tab(ln_loop_cnt).fc_segment7;    -- ���[�X���
--
      --==============================================================
      -- ���Y�J�e�S��CCID�擾 (A-5-1)
      --==============================================================
      xxcff_common1_pkg.chk_fa_category(
         iv_segment1      => lt_segment1            -- ���
        ,iv_segment2      => lt_segment2            -- �\�����p
        ,iv_segment3      => lt_segment3            -- ���Y����
        ,iv_segment4      => lt_segment4            -- ���p�Ȗ�
        ,iv_segment5      => lt_segment5            -- �ϗp�N��
        ,iv_segment6      => lt_segment6            -- ���p���@
        ,iv_segment7      => lt_segment7            -- ���[�X���
        ,on_category_id   => lt_asset_category_id   -- ���Y�J�e�S��CCID
        ,ov_errbuf        => lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,ov_retcode       => lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg        => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode <> ov_retcode) THEN
        RAISE global_api_expt;
      END IF;
--
      -- �Z�O�����g�l�z��ݒ�
      g_segments_tab(1) := g_ifrs_fa_add_tab(ln_loop_cnt).gcc_segment1;       -- SEG1:���
      g_segments_tab(2) := g_ifrs_fa_add_tab(ln_loop_cnt).gcc_segment2;       -- SEG2:����
      g_segments_tab(4) := g_ifrs_fa_add_tab(ln_loop_cnt).gcc_segment4;       -- SEG4:�⏕�Ȗ�
      g_segments_tab(5) := g_ifrs_fa_add_tab(ln_loop_cnt).gcc_segment5;       -- SEG5:�ڋq
      g_segments_tab(6) := g_ifrs_fa_add_tab(ln_loop_cnt).gcc_segment6;       -- SEG6:���
      g_segments_tab(7) := g_ifrs_fa_add_tab(ln_loop_cnt).gcc_segment7;       -- SEG7:�\���P
      g_segments_tab(8) := g_ifrs_fa_add_tab(ln_loop_cnt).gcc_segment8;       -- SEG8:�\���Q
      --
      --==============================================================
      -- ���Y�J�e�S�����擾 (A-5-2)
      --==============================================================
      BEGIN
        SELECT  fcb.deprn_expense_acct  AS deprn_expense_acct
        INTO    lt_deprn_expense_acct
        FROM    fa_category_books  fcb
        WHERE   fcb.category_id    = lt_asset_category_id         -- �J�e�S��ID
        AND     fcb.book_type_code = gv_fixed_ifrs_asset_regi     -- ���Y�䒠��
        ;
      EXCEPTION
        -- ���Y�J�e�S���䒠�}�X�^�̎擾�������[�����̏ꍇ
        WHEN NO_DATA_FOUND THEN
          -- ���Y�J�e�S���l�ݒ�
          lv_category := lt_segment1 || cv_haifun || lt_segment2 || cv_haifun ||
                         lt_segment3 || cv_haifun || lt_segment4 || cv_haifun ||
                         lt_segment5 || cv_haifun || lt_segment6 || cv_haifun || lt_segment7;
          --
          -- �G���[���b�Z�[�W���Z�b�g
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff             -- XXCFF
                                                        ,cv_msg_019a02_m_018        -- ���Y�J�e�S�����擾�G���[
                                                        ,cv_tkn_category            -- �g�[�N��'CATEGORY'
                                                        ,lv_category                -- �J�e�S���g�ݍ��킹
                                                        ,cv_tkn_bk_type             -- �g�[�N��'BOOK_TYPE_CODE'
                                                        ,gv_fixed_ifrs_asset_regi)  -- ���Y�䒠��
                                                        ,1
                                                        ,5000);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
      g_segments_tab(3) := lt_deprn_expense_acct;       -- SEG3:����Ȗ�
--
      --==============================================================
      -- �������p���CCID�擾(A-5-3)
      --==============================================================
      -- CCID�擾�֐��Ăяo��
      lb_ret := fnd_flex_ext.get_combination_id(
                   application_short_name  => g_init_rec.gl_application_short_name -- �A�v���P�[�V�����Z�k��(GL)
                  ,key_flex_code           => g_init_rec.id_flex_code              -- �L�[�t���b�N�X�R�[�h
                  ,structure_number        => g_init_rec.chart_of_accounts_id      -- ����Ȗڑ̌n�ԍ�
                  ,validation_date         => g_init_rec.process_date              -- ���t�`�F�b�N
                  ,n_segments              => cn_segment_count                     -- �Z�O�����g��
                  ,segments                => g_segments_tab                       -- �Z�O�����g�l�z��
                  ,combination_id          => lt_deprn_ccid                        -- CCID(�������p���CCID)
                  );
      IF NOT lb_ret THEN
        lv_errmsg := fnd_flex_ext.get_message;
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
      -- �o�^�p���ڒl�ݒ�
      lt_fixed_assets_cost := NVL(g_ifrs_fa_add_tab(ln_loop_cnt).original_cost, cn_zero_0) + 
                              TO_NUMBER(NVL(g_ifrs_fa_add_tab(ln_loop_cnt).attribute17, cv_value_zero)) + 
                              TO_NUMBER(NVL(g_ifrs_fa_add_tab(ln_loop_cnt).attribute18, cv_value_zero)) + 
                              TO_NUMBER(NVL(g_ifrs_fa_add_tab(ln_loop_cnt).attribute19, cv_value_zero));  -- �擾���z
      lt_payables_cost := lt_fixed_assets_cost;                                                   -- ���Y�����擾���z
--
      --==============================================================
      -- �ǉ�OIF�o�^ (A-5-4)
      --==============================================================
      INSERT INTO fa_mass_additions(
         mass_addition_id               -- �ǉ�OIF����ID
        ,asset_number                   -- ���Y�ԍ�
        ,description                    -- �E�v
        ,asset_category_id              -- ���Y�J�e�S��CCID
        ,book_type_code                 -- �䒠
        ,date_placed_in_service         -- ���Ƌ��p��
        ,fixed_assets_cost              -- �擾���z
        ,payables_units                 -- AP����
        ,fixed_assets_units             -- �P�ʐ���
        ,expense_code_combination_id    -- �������p���CCID
        ,location_id                    -- ���Ə��t���b�N�X�t�B�[���hCCID
        ,last_update_date               -- �ŏI�X�V��
        ,last_updated_by                -- �ŏI�X�V��
        ,posting_status                 -- �]�L�X�e�[�^�X
        ,queue_name                     -- �L���[��
        ,payables_cost                  -- ���Y�����擾���z
        ,depreciate_flag                -- ���p��v��t���O
        ,parent_asset_id                -- �e���YID
        ,asset_key_ccid                 -- ���Y�L�[CCID
        ,asset_type                     -- ���Y�^�C�v
        ,created_by                     -- �쐬��ID
        ,creation_date                  -- �쐬��
        ,last_update_login              -- �ŏI�X�V���O�C��ID
        ,attribute1                     -- DFF1�i�X�V�p���Ƌ��p���j
        ,attribute2                     -- DFF2�i�擾���j
        ,attribute3                     -- DFF3�i�\���j
        ,attribute4                     -- DFF4�i�זځj
        ,attribute5                     -- DFF5�i���k�L�^�E�T�������j
        ,attribute6                     -- DFF6�i���k�T���z�j
        ,attribute7                     -- DFF7�i���k��擾���i�j
        ,attribute8                     -- DFF8�i���Y�O���[�v�ԍ��j
        ,attribute9                     -- DFF9�i�����v�Z���ԗ����j
        ,attribute10                    -- DFF10�i�_�񖾍ד���ID�j
        ,attribute11                    -- DFF11�i���[�X���Y��ʁj
        ,attribute12                    -- DFF12�i�J���Z�O�����g�j
        ,attribute13                    -- DFF13�i�ʐρj
        ,attribute14                    -- DFF14�i���̋@��������ID�j
        ,attribute15                    -- DFF15�iIFRS�ϗp�N���j
        ,attribute16                    -- DFF16�iIFRS���p�j
        ,attribute17                    -- DFF17�i�s���Y�擾�Łj
        ,attribute18                    -- DFF18�i�ؓ��R�X�g�j
        ,attribute19                    -- DFF19�i���̑��j
        ,attribute20                    -- DFF20�iIFRS���Y�Ȗځj
        ,attribute21                    -- DFF21�i�C���N�����j
        ,attribute22                    -- DFF22�i�Œ莑�Y���Y�ԍ��j
      ) VALUES (
         fa_mass_additions_s.NEXTVAL                                -- �ǉ�OIF����ID
        ,NULL                                                       -- ���Y�ԍ�
        ,g_ifrs_fa_add_tab(ln_loop_cnt).description                 -- �E�v
        ,lt_asset_category_id                                       -- ���Y�J�e�S��CCID
        ,gv_fixed_ifrs_asset_regi                                   -- �䒠
        ,g_ifrs_fa_add_tab(ln_loop_cnt).date_placed_in_service      -- ���Ƌ��p��
        ,lt_fixed_assets_cost                                       -- �擾���z
        ,g_ifrs_fa_add_tab(ln_loop_cnt).fixed_assets_units          -- AP����
        ,g_ifrs_fa_add_tab(ln_loop_cnt).fixed_assets_units          -- �P�ʐ���
        ,lt_deprn_ccid                                              -- �������p���CCID
        ,g_ifrs_fa_add_tab(ln_loop_cnt).location_id                 -- ���Ə��t���b�N�X�t�B�[���hCCID
        ,cd_last_update_date                                        -- �ŏI�X�V��
        ,cn_last_updated_by                                         -- �ŏI�X�V��
        ,cv_posting_status                                          -- �]�L�X�e�[�^�X
        ,cv_queue_name                                              -- �L���[��
        ,lt_payables_cost                                           -- ���Y�����擾���z
        ,g_ifrs_fa_add_tab(ln_loop_cnt).depreciate_flag             -- ���p��v��t���O
        ,g_ifrs_fa_add_tab(ln_loop_cnt).parent_asset_id             -- �e���YID
        ,g_ifrs_fa_add_tab(ln_loop_cnt).asset_key_ccid              -- ���Y�L�[CCID
        ,g_ifrs_fa_add_tab(ln_loop_cnt).asset_type                  -- ���Y�^�C�v
        ,cn_created_by                                              -- �쐬��ID
        ,cd_creation_date                                           -- �쐬��
        ,cn_last_update_login                                       -- �ŏI�X�V���O�C��ID
        ,g_ifrs_fa_add_tab(ln_loop_cnt).attribute1                  -- DFF1�i�X�V�p���Ƌ��p���j
        ,g_ifrs_fa_add_tab(ln_loop_cnt).attribute2                  -- DFF2�i�擾���j
        ,g_ifrs_fa_add_tab(ln_loop_cnt).attribute3                  -- DFF3�i�\���j
        ,g_ifrs_fa_add_tab(ln_loop_cnt).attribute4                  -- DFF4�i�זځj
        ,g_ifrs_fa_add_tab(ln_loop_cnt).attribute5                  -- DFF5�i���k�L�^�E�T������
        ,g_ifrs_fa_add_tab(ln_loop_cnt).attribute6                  -- DFF6�i���k�T���z�j
        ,g_ifrs_fa_add_tab(ln_loop_cnt).attribute7                  -- DFF7�i���k��擾���i�j
        ,g_ifrs_fa_add_tab(ln_loop_cnt).attribute8                  -- DFF8�i���Y�O���[�v�ԍ��j
        ,g_ifrs_fa_add_tab(ln_loop_cnt).attribute9                  -- DFF9�i�����v�Z���ԗ����j
        ,g_ifrs_fa_add_tab(ln_loop_cnt).attribute10                 -- DFF10�i�_�񖾍ד���ID�j
        ,g_ifrs_fa_add_tab(ln_loop_cnt).attribute11                 -- DFF11�i���[�X���Y��ʁj
        ,g_ifrs_fa_add_tab(ln_loop_cnt).attribute12                 -- DFF12�i�J���Z�O�����g�j 
        ,g_ifrs_fa_add_tab(ln_loop_cnt).attribute13                 -- DFF13�i�ʐρj 
        ,g_ifrs_fa_add_tab(ln_loop_cnt).attribute14                 -- DFF14�i���̋@��������ID�j
        ,g_ifrs_fa_add_tab(ln_loop_cnt).attribute15                 -- DFF15�iIFRS�ϗp�N���j 
        ,g_ifrs_fa_add_tab(ln_loop_cnt).attribute16                 -- DFF16�iIFRS���p�j 
        ,g_ifrs_fa_add_tab(ln_loop_cnt).attribute17                 -- DFF17�i�s���Y�擾�Łj 
        ,g_ifrs_fa_add_tab(ln_loop_cnt).attribute18                 -- DFF18�i�ؓ��R�X�g�j 
        ,g_ifrs_fa_add_tab(ln_loop_cnt).attribute19                 -- DFF19�i���̑��j 
        ,g_ifrs_fa_add_tab(ln_loop_cnt).attribute20                 -- DFF20�iIFRS���Y�Ȗځj 
        ,g_ifrs_fa_add_tab(ln_loop_cnt).attribute21                 -- DFF21�i�C���N�����j 
        ,g_ifrs_fa_add_tab(ln_loop_cnt).asset_number                -- DFF22�i�Œ莑�Y���Y�ԍ��j
      );
--
      -- IFRS�䒠�ꊇ�ǉ����팏���J�E���g
      gn_ifrs_fa_add_normal_cnt := gn_ifrs_fa_add_normal_cnt + 1;
--
    END LOOP ifrs_fa_add_loop;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\���N���[�Y
      IF (ifrs_fa_add_cur%ISOPEN) THEN
        CLOSE ifrs_fa_add_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\���N���[�Y
      IF (ifrs_fa_add_cur%ISOPEN) THEN
        CLOSE ifrs_fa_add_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���N���[�Y
      IF (ifrs_fa_add_cur%ISOPEN) THEN
        CLOSE ifrs_fa_add_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_ifrs_fa_add_data;
--
  /**********************************************************************************
   * Procedure Name   : get_exec_date
   * Description      : ���s�����擾 (A-4)
   ***********************************************************************************/
  PROCEDURE get_exec_date(
    ov_errbuf      OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_exec_date'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    BEGIN
      SELECT  xis.exec_date AS exec_date  -- ���s����
      INTO    gt_exec_date
      FROM    xxcff_ifrs_sets  xis        -- IFRS�䒠�A�g�Z�b�g
      WHERE   xis.exec_id = cv_pkg_name
      FOR UPDATE NOWAIT
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                      ,cv_msg_019a02_m_017  -- �擾�Ώۃf�[�^����
                                                      ,cv_tkn_get_data      -- �g�[�N��'GET_DATA'
                                                      ,cv_msg_019a02_t_013) -- IFRS�䒠�A�g�Z�b�g
                                                      ,1
                                                      ,5000);
        lv_errbuf := lv_errmsg;
        --
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_errmsg  := lv_errmsg;
        ov_retcode := cv_status_error;
      --
      WHEN data_lock_expt THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                      ,cv_msg_019a02_m_019  -- ���b�N�G���[
                                                      ,cv_tkn_table_name    -- �g�[�N��'TABLE_NAME'
                                                      ,cv_msg_019a02_t_013) -- IFRS�䒠�A�g�Z�b�g
                                                      ,1
                                                      ,5000);
        lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
        --
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_errmsg  := lv_errmsg;
        ov_retcode := cv_status_error;
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
  END get_exec_date;
--
  /**********************************************************************************
   * Procedure Name   : chk_period
   * Description      : ��v���ԃ`�F�b�N(A-3)
   ***********************************************************************************/
  PROCEDURE chk_period(
    ov_errbuf      OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_period'; -- �v���O������
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
    cv_yes                CONSTANT VARCHAR2(1) := 'Y';
--
    -- *** ���[�J���ϐ� ***
    lt_deprn_run          fa_deprn_periods.deprn_run%TYPE := NULL;  -- �������p���s�t���O
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    BEGIN
      -- ��v���ԃ`�F�b�N
      SELECT  fdp.deprn_run        AS deprn_run   -- �������p���s�t���O
      INTO    lt_deprn_run
      FROM    fa_deprn_periods  fdp               -- �������p����
      WHERE   fdp.book_type_code    = gv_fixed_ifrs_asset_regi
      AND     fdp.period_name       = gv_period_name
      AND     fdp.period_close_date IS NULL
      ;
    EXCEPTION
      -- ��v���Ԃ̎擾�������[�����̏ꍇ
      WHEN NO_DATA_FOUND THEN
        RAISE chk_period_expt;
    END;
--
    -- �������p�����s����Ă���ꍇ
    IF lt_deprn_run = cv_yes THEN
      RAISE chk_period_expt;
    END IF;
--
  EXCEPTION
    -- *** ��v���ԃ`�F�b�N�G���[�n���h�� ***
    WHEN chk_period_expt THEN
      -- �G���[���b�Z�[�W���Z�b�g
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff            -- XXCFF
                                                    ,cv_msg_019a02_m_011       -- ��v���ԃ`�F�b�N�G���[
                                                    ,cv_tkn_bk_type            -- �g�[�N��'BOOK_TYPE_CODE'
                                                    ,gv_fixed_ifrs_asset_regi  -- ���Y�䒠��
                                                    ,cv_tkn_period             -- �g�[�N��'PERIOD_NAME'
                                                    ,gv_period_name)           -- ��v���Ԗ�
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      --
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_errmsg := lv_errmsg;
      -- �I���X�e�[�^�X�̓G���[�Ƃ���
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
  END chk_period;
--
  /**********************************************************************************
   * Procedure Name   : get_profile_values
   * Description      : �v���t�@�C���擾����(A-2)
   ***********************************************************************************/
  PROCEDURE get_profile_values(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_profile_values'; -- �v���O������
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
    -- XXCFF:�䒠���_�Œ莑�Y�䒠
    gv_fixed_asset_register := FND_PROFILE.VALUE(cv_fixed_asset_register);
    IF (gv_fixed_asset_register IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_019a02_m_010  -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_019a02_t_010) -- XXCFF:�䒠���_�Œ莑�Y�䒠
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:�䒠���_IFRS�䒠
    gv_fixed_ifrs_asset_regi := FND_PROFILE.VALUE(cv_fixed_ifrs_asset_regi);
    IF (gv_fixed_ifrs_asset_regi IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_019a02_m_010  -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_019a02_t_011) -- XXCFF:�䒠���_IFRS�䒠
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:IFRS���p���@
    gv_cat_deprn_ifrs := FND_PROFILE.VALUE(cv_cat_deprn_ifrs);
    IF (gv_cat_deprn_ifrs IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_019a02_m_010  -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_019a02_t_014) -- XXCFF:IFRS���p���@
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
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
  END get_profile_values;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �����l���̎擾
    xxcff_common1_pkg.init(
       or_init_rec => g_init_rec           -- �����l���
      ,ov_errbuf   => lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode  => lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg   => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> ov_retcode) THEN
      RAISE global_api_expt;
    END IF;
--
    -- �R���J�����g�p�����[�^�l�o��(�o�͂̕\��)
    xxcff_common1_pkg.put_log_param(
       iv_which         => cv_file_type_out    -- �o�͋敪
      ,ov_errbuf        => lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode       => lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg        => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> ov_retcode) THEN
      RAISE global_api_expt;
    END IF;
--
    -- �R���J�����g�p�����[�^�l�o��(���O)
    xxcff_common1_pkg.put_log_param(
       iv_which         => cv_file_type_log    -- �o�͋敪
      ,ov_errbuf        => lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode       => lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg        => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> ov_retcode) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** ���ʊ֐��R�����g ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
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
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_period_name  IN  VARCHAR2,     -- 1.��v���Ԗ�
    ov_errbuf       OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain';      -- �v���O������
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
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- IN�p�����[�^(��v���Ԗ�)���O���[�o���ϐ��ɐݒ�
    gv_period_name := iv_period_name;
--
    -- ===============================
    -- �������� (A-1)
    -- ===============================
    init(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �v���t�@�C���l�擾 (A-2)
    -- ===============================
    get_profile_values(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- ��v���ԃ`�F�b�N (A-3)
    -- ===============================
    chk_period(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- ���s�����擾 (A-4)
    -- =========================================
    get_exec_date(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- IFRS�䒠�o�^�f�[�^���o (A-5)
    -- =========================================
    get_ifrs_fa_add_data(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- IFRS�䒠�A�g�Z�b�g�X�V(A-6)
    -- =========================================
    upd_ifrs_sets(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
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
    errbuf         OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode        OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_period_name IN  VARCHAR2       --   1.��v���Ԗ�
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
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
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
    -- �O���[�o���ϐ��̏�����
    gn_ifrs_fa_add_target_cnt := 0;
    gn_ifrs_fa_add_normal_cnt := 0;
    gn_ifrs_fa_add_err_cnt    := 0;
    --
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       iv_period_name -- ��v���Ԗ�
      ,lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
  /**********************************************************************************
   * Description      : �I������(A-7)
   ***********************************************************************************/
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      -- ���팏����0�ɐݒ�
      gn_ifrs_fa_add_normal_cnt := cn_zero_0;
      -- �G���[������+1�X�V
      gn_ifrs_fa_add_err_cnt := gn_ifrs_fa_add_err_cnt + 1;
      --
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
      -- �Ώی������J�E���g����Ă���ꍇ
      IF ( gn_ifrs_fa_add_target_cnt > 0 ) THEN
        -- IFRS�䒠�ꊇ�o�^�G���[�̌Œ莑�Y�䒠�����o�͂���
        gv_out_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff         -- XXCFF
                                                       ,cv_msg_019a02_m_014    -- IFRS�䒠�ꊇ�o�^�G���[
                                                       ,cv_tkn_asset_number    -- �g�[�N��'ASSET_NUMBER'
                                                       ,g_ifrs_fa_add_tab(gn_loop_cnt).asset_number)
                                                                               -- ���Y�ԍ�
                                                       ,1
                                                       ,2000);
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
      END IF;
    -- �Ώی�����0���������ꍇ
    ELSIF ( gn_ifrs_fa_add_target_cnt = cn_zero_0 ) THEN
      -- �X�e�[�^�X���x���ɂ���
      lv_retcode := cv_status_warn;
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    --===============================================================
    --IFRS�䒠�ꊇ�o�^�����ɂ����錏���o��
    --===============================================================
    --IFRS�䒠�쐬���b�Z�[�W�o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cff
                    ,iv_name         => cv_msg_019a02_m_013
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_ifrs_fa_add_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_ifrs_fa_add_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_ifrs_fa_add_err_cnt)
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
END XXCFF019A02C;
/
