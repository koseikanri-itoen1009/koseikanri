CREATE OR REPLACE PACKAGE BODY XXCFF019A03C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2017. All rights reserved.
 *
 * Package Name     : XXCFF019A03C(body)
 * Description      : IFRS�䒠�U��
 * MD.050           : MD050_CFF_019_A03_IFRS�䒠�U��
 * Version          : 1.0
 *
 * Program List
 * ----------------------------- ----------------------------------------------------------
 *  Name                          Description
 * ----------------------------- ----------------------------------------------------------
 *  init                          ��������                                  (A-1)
 *  get_profile_values            �v���t�@�C���l�擾                        (A-2)
 *  chk_period                    ��v���ԃ`�F�b�N                          (A-3)
 *  get_ifrs_fa_trans_data        IFRS�䒠�U�փf�[�^���o                    (A-5)
 *  submain                       ���C�������v���V�[�W��
 *  main                          �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2017/09/15    1.0   SCSK�O�c         �V�K�쐬
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --�x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --�ُ�:2
  --WHO�J����
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;                 --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                            --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;                 --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                            --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;                --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id;         --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;            --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id;         --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                            --PROGRAM_UPDATE_DATE
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
  cv_pkg_name         CONSTANT VARCHAR2(100):= 'XXCFF019A03C'; -- �p�b�P�[�W��
  --
  -- ***�A�v���P�[�V�����Z�k��
  cv_msg_kbn_cff      CONSTANT VARCHAR2(5)  := 'XXCFF';
  --
  -- ***���b�Z�[�W��(�{��)
  cv_msg_019a03_m_010 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00020'; -- �v���t�@�C���擾�G���[
  cv_msg_019a03_m_011 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00037'; -- ��v���ԃ`�F�b�N�G���[
  cv_msg_019a03_m_013 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00272'; -- �U�֍쐬���b�Z�[�W
  cv_msg_019a03_m_014 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00273'; -- IFRS�䒠�U�֓o�^�G���[
  cv_msg_019a03_m_015 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00165'; -- �擾�Ώۃf�[�^�������b�Z�[�W
  cv_msg_019a03_m_016 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00007'; -- ���b�N�G���[
  cv_msg_019a03_m_017 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00277'; -- IFRS�䒠�U�փX�L�b�v���b�Z�[�W
  --
  -- ***���b�Z�[�W��(�g�[�N��)
  cv_msg_019a03_t_010 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50228'; -- XXCFF:�䒠���_�Œ莑�Y�䒠
  cv_msg_019a03_t_011 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50314'; -- XXCFF:�䒠���_IFRS�䒠
  cv_msg_019a03_t_012 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50316'; -- IFRS�䒠�A�g�Z�b�g
  cv_msg_019a03_t_013 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50322'; -- ���Y�䒠���
  --
  -- ***�g�[�N����
  cv_tkn_prof           CONSTANT VARCHAR2(20) := 'PROF_NAME';
  cv_tkn_bk_type        CONSTANT VARCHAR2(20) := 'BOOK_TYPE_CODE';
  cv_tkn_period         CONSTANT VARCHAR2(20) := 'PERIOD_NAME';
  cv_tkn_get_data       CONSTANT VARCHAR2(20) := 'GET_DATA';
  cv_tkn_table_name     CONSTANT VARCHAR2(20) := 'TABLE_NAME';
  cv_tkn_asset_number1  CONSTANT VARCHAR2(20) := 'ASSET_NUMBER1';
  cv_tkn_asset_number2  CONSTANT VARCHAR2(20) := 'ASSET_NUMBER2';
  --
  -- ***�v���t�@�C��
  cv_fixed_asset_register   CONSTANT VARCHAR2(30) := 'XXCFF1_FIXED_ASSET_REGISTER';       -- �䒠���_�Œ莑�Y�䒠
  cv_fixed_ifrs_asset_regi  CONSTANT VARCHAR2(35) := 'XXCFF1_FIXED_IFRS_ASSET_REGISTER';  -- �䒠���_IFRS�䒠
  --
  -- ***�t�@�C���o��
  cv_file_type_out    CONSTANT VARCHAR2(10) := 'OUTPUT'; -- ���b�Z�[�W�o��
  cv_file_type_log    CONSTANT VARCHAR2(10) := 'LOG';    -- ���O�o��
  --
  cv_haifun           CONSTANT VARCHAR2(1)  := '-';      -- -(�n�C�t��)
  cn_zero             CONSTANT NUMBER       := 0;        -- ���l�[��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ***�o���N�t�F�b�`�p��`
  -- IFRS�䒠�U�֑Ώۃf�[�^���R�[�h�^
  TYPE g_ifrs_fa_trans_rtype IS RECORD(
    asset_number                fa_additions_b.asset_number%TYPE,                     -- ���Y�ԍ�
    transaction_date_entered    fa_transaction_headers.transaction_date_entered%TYPE, -- �U�֓�
    current_units               fa_additions_b.current_units%TYPE,                    -- �P�ʐ���
    gcc_segment1                gl_code_combinations.segment1%TYPE,                   -- �������p��_���
    gcc_segment2                gl_code_combinations.segment2%TYPE,                   -- �������p��_����
    gcc_segment5                gl_code_combinations.segment5%TYPE,                   -- �������p��_�ڋq
    location_id                 fa_distribution_history.location_id%TYPE,             -- ���P�[�V����ID
    fl_segment1                 fa_locations.segment1%TYPE,                           -- ���Ə�_�\���n
    fl_segment2                 fa_locations.segment2%TYPE,                           -- ���Ə�_�Ǘ�����
    fl_segment3                 fa_locations.segment3%TYPE,                           -- ���Ə�_���Ə�
    fl_segment4                 fa_locations.segment4%TYPE,                           -- ���Ə�_�ꏊ
    fl_segment5                 fa_locations.segment5%TYPE,                           -- ���Ə�_�{��/�H��敪
    ifrs_asset_number           fa_additions_b.asset_number%TYPE,                     -- IFRS_���Y�ԍ�
    ifrs_gcc_segment1           gl_code_combinations.segment1%TYPE,                   -- IFRS_�������p��_���
    ifrs_gcc_segment2           gl_code_combinations.segment2%TYPE,                   -- IFRS_�������p��_����
    ifrs_gcc_segment3           gl_code_combinations.segment3%TYPE,                   -- IFRS_�������p��_�Ǘ��Ȗ�
    ifrs_gcc_segment4           gl_code_combinations.segment4%TYPE,                   -- IFRS_�������p��_�⏕�Ȗ�
    ifrs_gcc_segment5           gl_code_combinations.segment5%TYPE,                   -- IFRS_�������p��_�ڋq
    ifrs_gcc_segment6           gl_code_combinations.segment6%TYPE,                   -- IFRS_�������p��_���
    ifrs_gcc_segment7           gl_code_combinations.segment7%TYPE,                   -- IFRS_�������p��_�\��1
    ifrs_gcc_segment8           gl_code_combinations.segment8%TYPE,                   -- IFRS_�������p��_�\��2
    ifrs_location_id            fa_distribution_history.location_id%TYPE              -- IFRS_���P�[�V����ID
  );
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- ***�o���N�t�F�b�`�p��`
  -- IFRS�䒠�U�֑Ώۃf�[�^���R�[�h�z��
  TYPE g_ifrs_fa_trans_ttype IS TABLE OF g_ifrs_fa_trans_rtype
  INDEX BY BINARY_INTEGER;
--
  g_ifrs_fa_trans_tab         g_ifrs_fa_trans_ttype;  -- IFRS�䒠�U�֑Ώۃf�[�^
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
--
  -- �Z�O�����g�l�z��(EBS�W���֐�fnd_flex_ext�p)
  g_segments_tab  fnd_flex_ext.segmentarray;
--
  -- ***��������
  -- IFRS�䒠�U�֏����ɂ����錏��
  gn_ifrs_fa_trans_target_cnt NUMBER;     -- �Ώی���
  gn_loop_cnt                 NUMBER;     -- LOOP��
  gn_ifrs_fa_trans_normal_cnt NUMBER;     -- ���팏��
  gn_ifrs_fa_trans_err_cnt    NUMBER;     -- �G���[����
  gn_skip_cnt                 NUMBER;     -- SKIP��
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
   * Procedure Name   : get_ifrs_fa_trans_data
   * Description      : IFRS�䒠�U�փf�[�^���o(A-5)
   ***********************************************************************************/
  PROCEDURE get_ifrs_fa_trans_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'get_ifrs_fa_trans_data'; -- �v���O������
    cv_flg_yes              CONSTANT VARCHAR2(1)   := 'Y';                      -- �t���OYes
    cv_flg_no               CONSTANT VARCHAR2(1)   := 'N';                      -- �t���ONo
    cv_pending              CONSTANT VARCHAR2(7)   := 'PENDING';                -- �X�e�[�^�X(PENDING)
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
    cn_segment_count CONSTANT NUMBER := 8; -- �Z�O�����g��
--
    -- *** ���[�J���ϐ� ***
    lv_warnmsg            VARCHAR2(5000);                           -- �x�����b�Z�[�W
    lb_ret                BOOLEAN;                                  -- �֐����^�[���R�[�h
    --
    lv_ins_flg            VARCHAR2(1);                              -- �o�^�t���O
    lt_ifrs_gcc_segment1  gl_code_combinations.segment1%TYPE;       -- IFRS_�������p��_���
    lt_ifrs_gcc_segment2  gl_code_combinations.segment2%TYPE;       -- IFRS_�������p��_����
    lt_ifrs_gcc_segment3  gl_code_combinations.segment3%TYPE;       -- IFRS_�������p��_�Ǘ��Ȗ�
    lt_ifrs_gcc_segment4  gl_code_combinations.segment4%TYPE;       -- IFRS_�������p��_�⏕�Ȗ�
    lt_ifrs_gcc_segment5  gl_code_combinations.segment5%TYPE;       -- IFRS_�������p��_�ڋq
    lt_ifrs_gcc_segment6  gl_code_combinations.segment6%TYPE;       -- IFRS_�������p��_���
    lt_ifrs_gcc_segment7  gl_code_combinations.segment7%TYPE;       -- IFRS_�������p��_�\���P
    lt_ifrs_gcc_segment8  gl_code_combinations.segment8%TYPE;       -- IFRS_�������p��_�\���Q
    lt_ifrs_fl_segment1   fa_locations.segment1%TYPE;               -- IFRS_���Ə�_�\���n
    lt_ifrs_fl_segment2   fa_locations.segment2%TYPE;               -- IFRS_���Ə�_�Ǘ�����
    lt_ifrs_fl_segment3   fa_locations.segment3%TYPE;               -- IFRS_���Ə�_���Ə�
    lt_ifrs_fl_segment4   fa_locations.segment4%TYPE;               -- IFRS_���Ə�_�ꏊ
    lt_ifrs_fl_segment5   fa_locations.segment5%TYPE;               -- IFRS_���Ə�_�{��/�H��敪
    --
    lt_deprn_ccid         fa_mass_additions.expense_code_combination_id%TYPE;     -- �������p���CCID
    lt_deprn_expense_acct fa_category_books.deprn_expense_acct%TYPE;              -- �������p���
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- �Œ莑�Y�䒠�J�[�\��
    CURSOR ifrs_fa_trans_cur
    IS
      SELECT  fab.asset_number              AS asset_number               -- ���Y�ԍ�
             ,fth.transaction_date_entered  AS transaction_date_entered   -- �U�֓�
             ,fab.current_units             AS current_units              -- �P�ʐ���
             ,gcc.segment1                  AS gcc_segment1               -- �������p��_���
             ,gcc.segment2                  AS gcc_segment2               -- �������p��_����
             ,gcc.segment5                  AS gcc_segment5               -- �������p��_�ڋq
             ,fdh.location_id               AS location_id                -- ���P�[�V����ID
             ,fl.segment1                   AS fl_segment1                -- ���Ə�_�\���n
             ,fl.segment2                   AS fl_segment2                -- ���Ə�_�Ǘ�����
             ,fl.segment3                   AS fl_segment3                -- ���Ə�_���Ə�
             ,fl.segment4                   AS fl_segment4                -- ���Ə�_�ꏊ
             ,fl.segment5                   AS fl_segment5                -- ���Ə�_�{��/�H��敪
             ,ifrs_d.ifrs_asset_number      AS ifrs_asset_number          -- IFRS_���Y�ԍ�
             ,ifrs_d.ifrs_gcc_segment1      AS ifrs_gcc_segment1          -- IFRS_�������p��_���
             ,ifrs_d.ifrs_gcc_segment2      AS ifrs_gcc_segment2          -- IFRS_�������p��_����
             ,ifrs_d.ifrs_gcc_segment3      AS ifrs_gcc_segment3          -- IFRS_�������p��_�Ǘ��Ȗ�
             ,ifrs_d.ifrs_gcc_segment4      AS ifrs_gcc_segment4          -- IFRS_�������p��_�⏕�Ȗ�
             ,ifrs_d.ifrs_gcc_segment5      AS ifrs_gcc_segment5          -- IFRS_�������p��_�ڋq
             ,ifrs_d.ifrs_gcc_segment6      AS ifrs_gcc_segment6          -- IFRS_�������p��_���
             ,ifrs_d.ifrs_gcc_segment7      AS ifrs_gcc_segment7          -- IFRS_�������p��_�\��1
             ,ifrs_d.ifrs_gcc_segment8      AS ifrs_gcc_segment8          -- IFRS_�������p��_�\��2
             ,ifrs_d.ifrs_location_id       AS ifrs_location_id           -- IFRS_���P�[�V����ID
      FROM    fa_distribution_history   fdh   -- ���Y�����������
             ,fa_additions_b            fab   -- ���Y�ڍ׏��
             ,fa_transaction_headers    fth   -- ���Y����w�b�_
             ,gl_code_combinations      gcc   -- GL����Ȗ�
             ,fa_locations              fl    -- ���Ə��}�X�^
             ,(SELECT  fab2.attribute22     AS attribute22            -- IFRS_DFF22(�Œ莑�Y���Y�ԍ�)
                      ,fab2.asset_number    AS ifrs_asset_number      -- IFRS_���Y�ԍ�
                      ,gcc2.segment1        AS ifrs_gcc_segment1      -- IFRS_�������p��_���
                      ,gcc2.segment2        AS ifrs_gcc_segment2      -- IFRS_�������p��_����
                      ,gcc2.segment3        AS ifrs_gcc_segment3      -- IFRS_�������p��_�Ǘ��Ȗ�
                      ,gcc2.segment4        AS ifrs_gcc_segment4      -- IFRS_�������p��_�⏕�Ȗ�
                      ,gcc2.segment5        AS ifrs_gcc_segment5      -- IFRS_�������p��_�ڋq
                      ,gcc2.segment6        AS ifrs_gcc_segment6      -- IFRS_�������p��_���
                      ,gcc2.segment7        AS ifrs_gcc_segment7      -- IFRS_�������p��_�\��1
                      ,gcc2.segment8        AS ifrs_gcc_segment8      -- IFRS_�������p��_�\��2
                      ,fdh2.location_id     AS ifrs_location_id       -- IFRS_���P�[�V����ID
               FROM    fa_distribution_history   fdh2   -- ���Y�����������
                      ,fa_additions_b            fab2   -- ���Y�ڍ׏��
                      ,gl_code_combinations      gcc2   -- GL����Ȗ�
               WHERE   1 = 1  
               AND     fdh2.book_type_code            = gv_fixed_ifrs_asset_regi
               AND     fdh2.transaction_header_id_out IS NULL
               AND     fdh2.asset_id                  = fab2.asset_id
               AND     fdh2.code_combination_id       = gcc2.code_combination_id
              ) ifrs_d
      WHERE   1 = 1
      AND     fdh.book_type_code            = gv_fixed_asset_register   -- ���Y�䒠��
      AND     fdh.transaction_header_id_out IS NULL
      AND     fdh.date_effective            > gt_exec_date
      AND     fdh.asset_id                  = fab.asset_id              -- ���YID
      AND     fdh.code_combination_id       = gcc.code_combination_id   -- ����Ȗ�CCID
      AND     fdh.location_id               = fl.location_id            -- ���P�[�V����ID
      AND     fdh.transaction_header_id_in  = fth.transaction_header_id 
      AND    (SELECT COUNT(fdh3.distribution_id)
              FROM   fa_distribution_history fdh3
              WHERE  fdh3.book_type_code = fdh.book_type_code
              AND    fdh3.asset_id       = fdh.asset_id ) >= 2
      AND     ifrs_d.attribute22 = fab.asset_number
      ;
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
    OPEN ifrs_fa_trans_cur;
    -- �f�[�^�̈ꊇ�擾
    FETCH ifrs_fa_trans_cur BULK COLLECT INTO  g_ifrs_fa_trans_tab;
    -- �J�[�\���N���[�Y
    CLOSE ifrs_fa_trans_cur;
    -- �Ώی����̎擾
    gn_ifrs_fa_trans_target_cnt := g_ifrs_fa_trans_tab.COUNT;
--
    -- �U�֑Ώی�����0���̏ꍇ
    IF ( gn_ifrs_fa_trans_target_cnt = cn_zero ) THEN
      --���b�Z�[�W�̐ݒ�
      lv_warnmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                     ,cv_msg_019a03_m_015  -- �擾�Ώۃf�[�^����
                                                     ,cv_tkn_get_data      -- �g�[�N��'GET_DATA'
                                                     ,cv_msg_019a03_t_013) -- ���Y�䒠���
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
    -- LOOP���A���팏���A�X�L�b�v����������
    gn_loop_cnt := 0;
    gn_ifrs_fa_trans_normal_cnt := 0;
    gn_skip_cnt := 0;
--
    -- ***************************************
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
    --==============================================================
    --���C�����[�v����
    --==============================================================
    <<ifrs_fa_add_loop>>
    FOR ln_loop_cnt IN 1 .. gn_ifrs_fa_trans_target_cnt LOOP
--
      -- LOOP���擾
      gn_loop_cnt := ln_loop_cnt;
--
      -- �ȉ��̕ϐ�������������
      lv_ins_flg            := cv_flg_no;   -- �o�^�t���O
      lt_ifrs_gcc_segment1  := NULL;        -- �������p��_���
      lt_ifrs_gcc_segment2  := NULL;        -- �������p��_����
      lt_ifrs_gcc_segment3  := NULL;        -- �������p��_�Ǘ��Ȗ�
      lt_ifrs_gcc_segment4  := NULL;        -- �������p��_�⏕�Ȗ�
      lt_ifrs_gcc_segment5  := NULL;        -- �������p��_�ڋq
      lt_ifrs_gcc_segment6  := NULL;        -- �������p��_���
      lt_ifrs_gcc_segment7  := NULL;        -- �������p��_�\���P
      lt_ifrs_gcc_segment8  := NULL;        -- �������p��_�\���Q
      --
      lt_ifrs_fl_segment1   := NULL;        -- ���Ə�_�\���n
      lt_ifrs_fl_segment2   := NULL;        -- ���Ə�_�Ǘ�����
      lt_ifrs_fl_segment3   := NULL;        -- ���Ə�_���Ə�
      lt_ifrs_fl_segment4   := NULL;        -- ���Ə�_�ꏊ
      lt_ifrs_fl_segment5   := NULL;        -- ���Ə�_�{��/�H��敪
--
      --==============================================================
      -- �������p������ (��ЁA����A�ڋq)�A���Ə����`�F�b�N(A-5-1)
      --==============================================================
      -- ���Ə����
      IF (g_ifrs_fa_trans_tab(ln_loop_cnt).location_id <> g_ifrs_fa_trans_tab(ln_loop_cnt).ifrs_location_id) THEN
        lv_ins_flg := cv_flg_yes;   -- �o�^�t���O = Y
      END IF;
      lt_ifrs_fl_segment1 := g_ifrs_fa_trans_tab(ln_loop_cnt).fl_segment1;          -- IFRS_���Ə�_�\���n
      lt_ifrs_fl_segment2 := g_ifrs_fa_trans_tab(ln_loop_cnt).fl_segment2;          -- IFRS_���Ə�_�Ǘ�����
      lt_ifrs_fl_segment3 := g_ifrs_fa_trans_tab(ln_loop_cnt).fl_segment3;          -- IFRS_���Ə�_���Ə�
      lt_ifrs_fl_segment4 := g_ifrs_fa_trans_tab(ln_loop_cnt).fl_segment4;          -- IFRS_���Ə�_�ꏊ
      lt_ifrs_fl_segment5 := g_ifrs_fa_trans_tab(ln_loop_cnt).fl_segment5;          -- IFRS_���Ə�_�{��/�H��敪
      --
      -- �������p��_��ЁA����
      IF ( (g_ifrs_fa_trans_tab(ln_loop_cnt).gcc_segment1 <> g_ifrs_fa_trans_tab(ln_loop_cnt).ifrs_gcc_segment1) OR
           (g_ifrs_fa_trans_tab(ln_loop_cnt).gcc_segment2 <> g_ifrs_fa_trans_tab(ln_loop_cnt).ifrs_gcc_segment2) OR
           (g_ifrs_fa_trans_tab(ln_loop_cnt).gcc_segment5 <> g_ifrs_fa_trans_tab(ln_loop_cnt).ifrs_gcc_segment5) ) THEN
        lv_ins_flg := cv_flg_yes;   -- �o�^�t���O = Y
        --
        IF (g_ifrs_fa_trans_tab(ln_loop_cnt).gcc_segment1 <> g_ifrs_fa_trans_tab(ln_loop_cnt).ifrs_gcc_segment1) THEN
          g_segments_tab(1) := g_ifrs_fa_trans_tab(ln_loop_cnt).gcc_segment1;        -- SEG1:���
        ELSE
          g_segments_tab(1) := g_ifrs_fa_trans_tab(ln_loop_cnt).ifrs_gcc_segment1;   -- SEG1:���
        END IF;
        --
        IF (g_ifrs_fa_trans_tab(ln_loop_cnt).gcc_segment2 <> g_ifrs_fa_trans_tab(ln_loop_cnt).ifrs_gcc_segment2) THEN
          g_segments_tab(2) := g_ifrs_fa_trans_tab(ln_loop_cnt).gcc_segment2;        -- SEG2:����
        ELSE
          g_segments_tab(2) := g_ifrs_fa_trans_tab(ln_loop_cnt).ifrs_gcc_segment2;   -- SEG2:����
        END IF;
        --
        g_segments_tab(3)   := g_ifrs_fa_trans_tab(ln_loop_cnt).ifrs_gcc_segment3;   -- SEG3:�Ǘ��Ȗ�
        g_segments_tab(4)   := g_ifrs_fa_trans_tab(ln_loop_cnt).ifrs_gcc_segment4;   -- SEG4:�⏕�Ȗ�
        --
        IF (g_ifrs_fa_trans_tab(ln_loop_cnt).gcc_segment5 <> g_ifrs_fa_trans_tab(ln_loop_cnt).ifrs_gcc_segment5) THEN
          g_segments_tab(5) := g_ifrs_fa_trans_tab(ln_loop_cnt).gcc_segment5;        -- SEG5:�ڋq
        ELSE
          g_segments_tab(5) := g_ifrs_fa_trans_tab(ln_loop_cnt).ifrs_gcc_segment5;   -- SEG5:�ڋq
        END IF;
        --
        g_segments_tab(6)   := g_ifrs_fa_trans_tab(ln_loop_cnt).ifrs_gcc_segment6;   -- SEG6:���
        g_segments_tab(7)   := g_ifrs_fa_trans_tab(ln_loop_cnt).ifrs_gcc_segment7;   -- SEG7:�\���P
        g_segments_tab(8)   := g_ifrs_fa_trans_tab(ln_loop_cnt).ifrs_gcc_segment8;   -- SEG8:�\���Q
        --
        --==============================================================
        -- �������p���CCID�擾(A-5-2)
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
        lt_ifrs_gcc_segment1 := g_segments_tab(1);      -- �������p��_���
        lt_ifrs_gcc_segment2 := g_segments_tab(2);      -- �������p��_����
        lt_ifrs_gcc_segment3 := g_segments_tab(3);      -- �������p��_�Ǘ��Ȗ�
        lt_ifrs_gcc_segment4 := g_segments_tab(4);      -- �������p��_�⏕�Ȗ�
        lt_ifrs_gcc_segment5 := g_segments_tab(5);      -- �������p��_�ڋq
        lt_ifrs_gcc_segment6 := g_segments_tab(6);      -- �������p��_���
        lt_ifrs_gcc_segment7 := g_segments_tab(7);      -- �������p��_�\���P
        lt_ifrs_gcc_segment8 := g_segments_tab(8);      -- �������p��_�\���Q
      ELSE
        lt_ifrs_gcc_segment1 := g_ifrs_fa_trans_tab(ln_loop_cnt).ifrs_gcc_segment1;      -- �������p��_���
        lt_ifrs_gcc_segment2 := g_ifrs_fa_trans_tab(ln_loop_cnt).ifrs_gcc_segment2;      -- �������p��_����
        lt_ifrs_gcc_segment3 := g_ifrs_fa_trans_tab(ln_loop_cnt).ifrs_gcc_segment3;      -- �������p��_�Ǘ��Ȗ�
        lt_ifrs_gcc_segment4 := g_ifrs_fa_trans_tab(ln_loop_cnt).ifrs_gcc_segment4;      -- �������p��_�⏕�Ȗ�
        lt_ifrs_gcc_segment5 := g_ifrs_fa_trans_tab(ln_loop_cnt).ifrs_gcc_segment5;      -- �������p��_�ڋq
        lt_ifrs_gcc_segment6 := g_ifrs_fa_trans_tab(ln_loop_cnt).ifrs_gcc_segment6;      -- �������p��_���
        lt_ifrs_gcc_segment7 := g_ifrs_fa_trans_tab(ln_loop_cnt).ifrs_gcc_segment7;      -- �������p��_�\���P
        lt_ifrs_gcc_segment8 := g_ifrs_fa_trans_tab(ln_loop_cnt).ifrs_gcc_segment8;      -- �������p��_�\���Q
      END IF;
      --
      IF (lv_ins_flg = cv_flg_yes) THEN   -- �o�^�t���O = Y
        --==============================================================
        -- �U��OIF�o�^ (A-5-3)
        --==============================================================
        INSERT INTO xx01_transfer_oif(
           transfer_oif_id                -- �U��OIF����ID
          ,book_type_code                 -- �䒠
          ,asset_number                   -- ���Y�ԍ�
          ,created_by                     -- �쐬��ID
          ,creation_date                  -- �쐬��
          ,last_updated_by                -- �ŏI�X�V��
          ,last_update_date               -- �ŏI�X�V��
          ,last_update_login              -- �ŏI�X�V���O�C��ID
          ,request_id                     -- ���N�G�X�gID
          ,program_application_id         -- �A�v���P�[�V����ID
          ,program_id                     -- �v���O����ID
          ,program_update_date            -- �v���O�����ŏI�X�V��
          ,transaction_date_entered       -- �U�֓�
          ,transaction_units              -- �P�ʕύX
          ,posting_flag                   -- �]�L�`�F�b�N�t���O
          ,status                         -- �X�e�[�^�X
          ,segment1                       -- �������p���Z�O�����g1
          ,segment2                       -- �������p���Z�O�����g2
          ,segment3                       -- �������p���Z�O�����g3
          ,segment4                       -- �������p���Z�O�����g4
          ,segment5                       -- �������p���Z�O�����g5
          ,segment6                       -- �������p���Z�O�����g6
          ,segment7                       -- �������p���Z�O�����g7
          ,segment8                       -- �������p���Z�O�����g8
          ,loc_segment1                   -- ���Ə��t���b�N�X�t�B�[���h1
          ,loc_segment2                   -- ���Ə��t���b�N�X�t�B�[���h2
          ,loc_segment3                   -- ���Ə��t���b�N�X�t�B�[���h3
          ,loc_segment4                   -- ���Ə��t���b�N�X�t�B�[���h4
          ,loc_segment5                   -- ���Ə��t���b�N�X�t�B�[���h5
        ) VALUES (
           xx01_transfer_oif_s.NEXTVAL                                -- �U��OIF����ID
          ,gv_fixed_ifrs_asset_regi                                   -- IFRS�䒠
          ,g_ifrs_fa_trans_tab(ln_loop_cnt).ifrs_asset_number         -- ���Y�ԍ�
          ,cn_created_by                                              -- �쐬��ID
          ,cd_creation_date                                           -- �쐬��
          ,cn_last_updated_by                                         -- �ŏI�X�V��
          ,cd_last_update_date                                        -- �ŏI�X�V��
          ,cn_last_update_login                                       -- �ŏI�X�V���O�C��ID
          ,cn_request_id                                              -- �v��ID
          ,cn_program_application_id                                  -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          ,cn_program_id                                              -- �R���J�����g�E�v���O����ID
          ,cd_program_update_date                                     -- �v���O�����X�V��
          ,g_ifrs_fa_trans_tab(ln_loop_cnt).transaction_date_entered  -- �U�֓�
          ,g_ifrs_fa_trans_tab(ln_loop_cnt).current_units             -- �P�ʕύX
          ,cv_flg_yes                                                 -- �]�L�`�F�b�N�t���O(�Œ�lY)
          ,cv_pending                                                 -- �X�e�[�^�X(PENDING)
          ,lt_ifrs_gcc_segment1                                       -- �������p���Z�O�����g1
          ,lt_ifrs_gcc_segment2                                       -- �������p���Z�O�����g2
          ,lt_ifrs_gcc_segment3                                       -- �������p���Z�O�����g3
          ,lt_ifrs_gcc_segment4                                       -- �������p���Z�O�����g4
          ,lt_ifrs_gcc_segment5                                       -- �������p���Z�O�����g5
          ,lt_ifrs_gcc_segment6                                       -- �������p���Z�O�����g6
          ,lt_ifrs_gcc_segment7                                       -- �������p���Z�O�����g7
          ,lt_ifrs_gcc_segment8                                       -- �������p���Z�O�����g8
          ,lt_ifrs_fl_segment1                                        -- ���Ə��t���b�N�X�t�B�[���h1
          ,lt_ifrs_fl_segment2                                        -- ���Ə��t���b�N�X�t�B�[���h2
          ,lt_ifrs_fl_segment3                                        -- ���Ə��t���b�N�X�t�B�[���h3
          ,lt_ifrs_fl_segment4                                        -- ���Ə��t���b�N�X�t�B�[���h4
          ,lt_ifrs_fl_segment5                                        -- ���Ə��t���b�N�X�t�B�[���h5
        );
        --
        -- IFRS�䒠�U�֐��팏���J�E���g
        gn_ifrs_fa_trans_normal_cnt := gn_ifrs_fa_trans_normal_cnt + 1;
      ELSE
        gn_skip_cnt := gn_skip_cnt + 1;
        --
        lv_warnmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff         -- XXCFF
                                                       ,cv_msg_019a03_m_017    -- IFRS�䒠�U�փX�L�b�v���b�Z�[�W
                                                       ,cv_tkn_asset_number1   -- �g�[�N��'ASSET_NUMBER1'
                                                       ,g_ifrs_fa_trans_tab(gn_loop_cnt).asset_number
                                                                               -- �Œ莑�Y�䒠�̎��Y�ԍ�
                                                       ,cv_tkn_asset_number2   -- �g�[�N��'ASSET_NUMBER2'
                                                       ,g_ifrs_fa_trans_tab(gn_loop_cnt).ifrs_asset_number)
                                                                               -- IFRS�䒠�̎��Y�ԍ�
                                                       ,1
                                                       ,5000);
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_warnmsg
        );
      END IF;
--
    END LOOP ifrs_fa_add_loop;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\���N���[�Y
      IF (ifrs_fa_trans_cur%ISOPEN) THEN
        CLOSE ifrs_fa_trans_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\���N���[�Y
      IF (ifrs_fa_trans_cur%ISOPEN) THEN
        CLOSE ifrs_fa_trans_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���N���[�Y
      IF (ifrs_fa_trans_cur%ISOPEN) THEN
        CLOSE ifrs_fa_trans_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_ifrs_fa_trans_data;
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
                                                      ,cv_msg_019a03_m_015  -- �擾�Ώۃf�[�^����
                                                      ,cv_tkn_get_data      -- �g�[�N��'GET_DATA'
                                                      ,cv_msg_019a03_t_012) -- IFRS�䒠�A�g�Z�b�g
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
                                                      ,cv_msg_019a03_m_016  -- ���b�N�G���[
                                                      ,cv_tkn_table_name    -- �g�[�N��'TABLE_NAME'
                                                      ,cv_msg_019a03_t_012) -- IFRS�䒠�A�g�Z�b�g
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
                                                    ,cv_msg_019a03_m_011       -- ��v���ԃ`�F�b�N�G���[
                                                    ,cv_tkn_bk_type            -- �g�[�N��'BOOK_TYPE_CODE'
                                                    ,gv_fixed_ifrs_asset_regi  -- ���Y�䒠��
                                                    ,cv_tkn_period             -- �g�[�N��'PERIOD_NAME'
                                                    ,gv_period_name)           -- ��v���Ԗ�
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      --
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- XXCFF:�䒠���_�Œ莑�Y�䒠
    gv_fixed_asset_register := FND_PROFILE.VALUE(cv_fixed_asset_register);
    IF (gv_fixed_asset_register IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_019a03_m_010  -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_019a03_t_010) -- XXCFF:�䒠���_�Œ莑�Y�䒠
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
                                                    ,cv_msg_019a03_m_010  -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_019a03_t_011) -- XXCFF:�䒠���_IFRS�䒠
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
    -- IFRS�䒠�U�փf�[�^���o (A-5)
    -- =========================================
    get_ifrs_fa_trans_data(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- A-5���G���[�̏ꍇ
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
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- �X�L�b�v�������b�Z�[�W
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
    gn_ifrs_fa_trans_target_cnt := 0;
    gn_ifrs_fa_trans_normal_cnt := 0;
    gn_ifrs_fa_trans_err_cnt    := 0;
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
      gn_ifrs_fa_trans_normal_cnt := cn_zero;
      -- �G���[������+1�X�V
      gn_ifrs_fa_trans_err_cnt := gn_ifrs_fa_trans_err_cnt + 1;
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
      IF ( gn_ifrs_fa_trans_target_cnt > 0 ) THEN
        -- IFRS�䒠�U�փG���[�̌Œ莑�Y�䒠�����o�͂���
        gv_out_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff         -- XXCFF
                                                       ,cv_msg_019a03_m_014    -- IFRS�䒠�U�֓o�^�G���[
                                                       ,cv_tkn_asset_number1   -- �g�[�N��'ASSET_NUMBER1'
                                                       ,g_ifrs_fa_trans_tab(gn_loop_cnt).asset_number
                                                                               -- �Œ莑�Y�䒠�̎��Y�ԍ�
                                                       ,cv_tkn_asset_number2   -- �g�[�N��'ASSET_NUMBER2'
                                                       ,g_ifrs_fa_trans_tab(gn_loop_cnt).ifrs_asset_number)
                                                                               -- IFRS�䒠�̎��Y�ԍ�
                                                       ,1
                                                       ,2000);
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
      END IF;
    -- �Ώی�����0���܂���SKIP����1���ȏ�̏ꍇ
    ELSIF (( gn_ifrs_fa_trans_target_cnt = cn_zero ) OR ( gn_skip_cnt > cn_zero)) THEN
      -- �X�e�[�^�X���x���ɂ���
      lv_retcode := cv_status_warn;
    END IF;
    --
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    --===============================================================
    --IFRS�䒠�U�֏����ɂ����錏���o��
    --===============================================================
    --IFRS�䒠�U�֍쐬���b�Z�[�W�o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cff
                    ,iv_name         => cv_msg_019a03_m_013
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
                    ,iv_token_value1 => TO_CHAR(gn_ifrs_fa_trans_target_cnt)
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
                    ,iv_token_value1 => TO_CHAR(gn_ifrs_fa_trans_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_skip_cnt)
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
                    ,iv_token_value1 => TO_CHAR(gn_ifrs_fa_trans_err_cnt)
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
END XXCFF019A03C;
/
