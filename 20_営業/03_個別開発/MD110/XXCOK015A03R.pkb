CREATE OR REPLACE PACKAGE BODY XXCOK015A03R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK015A03R(body)
 * Description      : �x����̌ڋq���⍇�����������ꍇ�A
 *                    ��������ʂ̋��z���󎚂��ꂽ�x���ē�����������܂��B
 * MD.050           : �x���ē�������i���ׁj MD050_COK_015_A03
 * Version          : 1.3
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  delete_xrbpd         ���[�N�e�[�u���f�[�^�폜(A-7)
 *  start_svf            SVF�N��(A-6)
 *  update_xrbpd         �x���ē����i���ׁj���[���[�N�e�[�u���X�V(A-5)
 *  get_xrbpd            ���[�N�e�[�u���x���斈�W��f�[�^�擾(A-4)
 *  insert_xrbpd         �f�[�^�擾(A-2)�E���[�N�e�[�u���f�[�^�o�^(A-3)
 *  init                 ��������(A-1)
 *  main                 �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/13    1.0   K.Yamaguchi      �V�K�쐬
 *  2009/02/18    1.1   K.Yamaguchi      [��QCOK_045] �ŐV�̎d����T�C�g�����擾����悤�ύX
 *                                                     ���̓p�����[�^�̏�����ύX�iYYYYMM => YYYY/MM�j
 *  2009/03/03    1.2   M.Hiruta         [��QCOK_067] �e��敪�擾���@�ύX
 *  2009/05/11    1.3   K.Yamaguchi      [��QT1_0841] �x���z�i�ō��j�̎擾���@��ύX
 *                                       [��QT1_0866] �{�U�i�ē�������j�̏ꍇ�̒��o������ύX
 *
 *****************************************************************************************/
  --==================================================
  -- �O���[�o���萔
  --==================================================
  -- �p�b�P�[�W��
  cv_pkg_name                      CONSTANT VARCHAR2(20)    := 'XXCOK015A03R';
  -- �A�v���P�[�V�����Z�k��
  cv_appl_short_name_cok           CONSTANT VARCHAR2(10)    := 'XXCOK';
  cv_appl_short_name_ccp           CONSTANT VARCHAR2(10)    := 'XXCCP';
  -- �X�e�[�^�X�E�R�[�h
  cv_status_normal                 CONSTANT VARCHAR2(1)     := xxccp_common_pkg.set_status_normal;  -- ����:0
  cv_status_warn                   CONSTANT VARCHAR2(1)     := xxccp_common_pkg.set_status_warn;    -- �x��:1
  cv_status_error                  CONSTANT VARCHAR2(1)     := xxccp_common_pkg.set_status_error;   -- �ُ�:2
  -- WHO�J����
  cn_created_by                    CONSTANT NUMBER          := fnd_global.user_id;          -- CREATED_BY
  cn_last_updated_by               CONSTANT NUMBER          := fnd_global.user_id;          -- LAST_UPDATED_BY
  cn_last_update_login             CONSTANT NUMBER          := fnd_global.login_id;         -- LAST_UPDATE_LOGIN
  cn_request_id                    CONSTANT NUMBER          := fnd_global.conc_request_id;  -- REQUEST_ID
  cn_program_application_id        CONSTANT NUMBER          := fnd_global.prog_appl_id;     -- PROGRAM_APPLICATION_ID
  cn_program_id                    CONSTANT NUMBER          := fnd_global.conc_program_id;  -- PROGRAM_ID
  -- ���b�Z�[�W�R�[�h
  cv_msg_ccp_90000                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90000';        -- �Ώی���
  cv_msg_ccp_90001                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90001';        -- ��������
  cv_msg_ccp_90002                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90002';        -- �G���[����
  cv_msg_ccp_90004                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90004';        -- ����I��
  cv_msg_ccp_90006                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90006';        -- �G���[�I���S���[���o�b�N
  cv_msg_cok_00003                 CONSTANT VARCHAR2(20)    := 'APP-XXCOK1-00003';
  cv_msg_cok_00028                 CONSTANT VARCHAR2(20)    := 'APP-XXCOK1-00028';
  cv_msg_cok_00085                 CONSTANT VARCHAR2(20)    := 'APP-XXCOK1-00085';
  cv_msg_cok_00086                 CONSTANT VARCHAR2(20)    := 'APP-XXCOK1-00086';
  cv_msg_cok_00087                 CONSTANT VARCHAR2(20)    := 'APP-XXCOK1-00087';
  cv_msg_cok_00040                 CONSTANT VARCHAR2(20)    := 'APP-XXCOK1-00040';
  cv_msg_cok_10309                 CONSTANT VARCHAR2(20)    := 'APP-XXCOK1-10309';
  -- �g�[�N��
  cv_tkn_errmsg                    CONSTANT VARCHAR2(30)    := 'ERRMSG';
  cv_tkn_profile                   CONSTANT VARCHAR2(30)    := 'PROFILE';
  cv_tkn_count                     CONSTANT VARCHAR2(30)    := 'COUNT';
  cv_tkn_base_code                 CONSTANT VARCHAR2(30)    := 'BASE_CODE';
  cv_tkn_target_ym                 CONSTANT VARCHAR2(30)    := 'TARGET_YM';
  cv_tkn_vendor_code               CONSTANT VARCHAR2(30)    := 'VENDOR_CODE';
  -- �Z�p���[�^
  cv_msg_part                      CONSTANT VARCHAR2(3)     := ' : ';
  cv_msg_cont                      CONSTANT VARCHAR2(3)     := '.';
  -- �v���t�@�C���E�I�v�V������
  cv_profile_name_01               CONSTANT VARCHAR2(50)    := 'XXCOK1_PAY_GUIDE_PROMPT_BM';   -- XXCOK:�x���ē���_�̔��萔�����o��
  cv_profile_name_02               CONSTANT VARCHAR2(50)    := 'XXCOK1_PAY_GUIDE_PROMPT_EP';   -- XXCOK:�x���ē���_�d�C�����o��
  cv_profile_name_03               CONSTANT VARCHAR2(50)    := 'ORG_ID';                       -- MO: �c�ƒP��
  -- �Q�ƃ^�C�v��
-- Start 2009/03/03 M.Hiruta
--  cv_lookup_type_01                CONSTANT VARCHAR2(30)    := 'XXCMM_YOKI_KUBUN';    -- �e��敪
  cv_lookup_type_01                CONSTANT VARCHAR2(30)    := 'XXCSO1_SP_RULE_BOTTLE'; -- �e��敪
-- End   2009/03/03 M.Hiruta
  cv_lookup_type_02                CONSTANT VARCHAR2(30)    := 'XXCOK1_BM_CALC_TYPE';   -- �̎�v�Z����
  -- ���ʊ֐����b�Z�[�W�o�͋敪
  cv_which_log                     CONSTANT VARCHAR2(10)    := 'LOG';
  -- SVF�N���p�����[�^
  cv_file_id                       CONSTANT VARCHAR2(20)    := 'XXCOK015A03R';       -- ���[ID
  cv_output_mode                   CONSTANT VARCHAR2(1)     := '1';                  -- �o�͋敪(PDF�o��)
  cv_extension                     CONSTANT VARCHAR2(10)    := '.pdf';               -- �o�̓t�@�C�����g���q(PDF�o��)
  cv_frm_file                      CONSTANT VARCHAR2(20)    := 'XXCOK015A03S.xml';   -- �t�H�[���l���t�@�C����
  cv_vrq_file                      CONSTANT VARCHAR2(20)    := 'XXCOK015A03S.vrq';   -- �N�G���[�l���t�@�C����
  -- �����t�H�[�}�b�g
  cv_format_fxrrrrmm               CONSTANT VARCHAR2(50)    := 'FXRRRR/MM';
  cv_format_fxrrrrmmdd             CONSTANT VARCHAR2(50)    := 'FXRRRRMMDD';
  cv_format_date                   CONSTANT VARCHAR2(50)    := 'RRRR"�N"MM"��"DD"��"';
  cv_format_ee_month               CONSTANT VARCHAR2(50)    := 'EERR"�N"MM"����"';
  cv_format_ee_date                CONSTANT VARCHAR2(50)    := 'EERR"�N"MM"��"DD"��"';
  -- �e����T�|�[�g�p�����[�^
  cv_nls_param                     CONSTANT VARCHAR2(50)    := 'nls_calendar=''japanese imperial''';
  -- BM�x���敪
  cv_bm_type_1                     CONSTANT VARCHAR2(1)     := '1';                  -- �{�U�i�ē��L�j
  cv_bm_type_2                     CONSTANT VARCHAR2(1)     := '2';                  -- �{�U�i�ē����j
  cv_bm_type_3                     CONSTANT VARCHAR2(1)     := '3';                  -- AP�x��
  cv_bm_type_4                     CONSTANT VARCHAR2(1)     := '4';                  -- �����x��
  --==================================================
  -- �O���[�o���ϐ�
  --==================================================
  -- �J�E���^
  gn_target_cnt                    NUMBER        DEFAULT 0;      -- �Ώی���
  gn_normal_cnt                    NUMBER        DEFAULT 0;      -- ���팏��
  gn_error_cnt                     NUMBER        DEFAULT 0;      -- �ُ팏��
  -- ���̓p�����[�^
  gv_param_base_code               VARCHAR2(4)   DEFAULT NULL;  -- �⍇����
  gv_param_target_ym               VARCHAR2(7)   DEFAULT NULL;  -- �ē������s�N��
  gv_param_vendor_code             VARCHAR2(9)   DEFAULT NULL;  -- �x����
  -- ���������擾�l
  gd_process_date                  DATE          DEFAULT NULL;   -- �Ɩ��������t
  gn_org_id                        NUMBER        DEFAULT NULL;   -- �c�ƒP��ID
  gv_prompt_bm                     VARCHAR2(100) DEFAULT NULL;   -- �x���ē���_�̔��萔�����o��
  gv_prompt_ep                     VARCHAR2(100) DEFAULT NULL;   -- �x���ē���_�d�C�����o��
  --==================================================
  -- �O���[�o���J�[�\��
  --==================================================
  CURSOR g_summary_cur IS
    SELECT xrbpd.payment_code                     AS payment_code
         , SUM( xrbpd.selling_amt )               AS selling_amt_sum
         , gv_prompt_bm                           AS bm_index_1
         , SUM( CASE
                WHEN xrbpd.calc_type <> 50 THEN
                  xrbpd.backmargin
                END
           )                                      AS bm_amt_1
         , gv_prompt_ep                           AS bm_index_2
         , SUM( CASE
                WHEN xrbpd.calc_type = 50 THEN
                  xrbpd.backmargin
                END
           )                                      AS bm_amt_2
         , SUM( xrbpd.payment_amt_tax )           AS payment_amt_tax
         , MAX( xrbpd.closing_date )              AS closing_date
         , MIN( xrbpd.term_from_wk )              AS term_from
         , MAX( xrbpd.term_to_wk )                AS term_to
         , MAX( xrbpd.payment_date_wk )           AS payment_date
    FROM xxcok_rep_bm_pg_detail    xrbpd
    WHERE xrbpd.request_id = cn_request_id
    GROUP BY xrbpd.payment_code
  ;
  --==================================================
  -- �O���[�o���R���N�V�����^�ϐ�
  --==================================================
  TYPE g_summary_ttype             IS TABLE OF g_summary_cur%ROWTYPE INDEX BY BINARY_INTEGER;
  g_summary_tab                    g_summary_ttype;
  --==================================================
  -- ���ʗ�O
  --==================================================
  --*** ���������ʗ�O ***
  global_process_expt              EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt                  EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt           EXCEPTION;
  --==================================================
  -- ��O
  --==================================================
  --*** �G���[�I�� ***
  error_proc_expt                  EXCEPTION;
--
  /**********************************************************************************
   * Procedure Name   : delete_xrbpd
   * Description      : ���[�N�e�[�u���f�[�^�폜(A-7)
   ***********************************************************************************/
  PROCEDURE delete_xrbpd(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'delete_xrbpd';     -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
    --==================================================
    -- ���[�J���J�[�\��
    --==================================================
    CURSOR lock_xrbpd_cur
    IS
      SELECT 'X'
      FROM xxcok_rep_bm_pg_detail  xrbpd
      WHERE xrbpd.request_id = cn_request_id
      FOR UPDATE OF xrbpd.payment_code NOWAIT
    ;
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- ���b�N�擾
    --==================================================
    OPEN  lock_xrbpd_cur;
    CLOSE lock_xrbpd_cur;
    --==================================================
    -- ���[�N�e�[�u���f�[�^�폜
    --==================================================
    DELETE
    FROM xxcok_rep_bm_pg_detail  xrbpd
    WHERE xrbpd.request_id = cn_request_id
    ;
    --==================================================
    -- ���������擾
    --==================================================
    gn_target_cnt := SQL%ROWCOUNT;
    gn_normal_cnt := SQL%ROWCOUNT;
    --==================================================
    -- �o�̓p�����[�^�ݒ�
    --==================================================
    ov_retcode := lv_end_retcode;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END delete_xrbpd;
--
  /**********************************************************************************
   * Procedure Name   : start_svf
   * Description      : SVF�N��(A-6)
   ***********************************************************************************/
  PROCEDURE start_svf(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'start_svf';     -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
    lv_date                        VARCHAR2(8)    DEFAULT NULL;                 -- �o�̓t�@�C�����p���t
    lv_file_name                   VARCHAR2(100)  DEFAULT NULL;                 -- �o�̓t�@�C����
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- �V�X�e�����t�^�ϊ�
    --==================================================
    lv_date := TO_CHAR( SYSDATE, 'YYYYMMDD' );
    --==================================================
    -- �o�̓t�@�C����(���[ID + YYYYMMDD + �v��ID)
    --==================================================
    lv_file_name := cv_file_id
                 || TO_CHAR( SYSDATE, cv_format_fxrrrrmmdd )
                 || TO_CHAR( cn_request_id )
                 || cv_extension
                 ;
    --==================================================
    -- SVF�R���J�����g�N��
    --==================================================
    xxccp_svfcommon_pkg.submit_svf_request(
      ov_errbuf                => lv_errbuf                 -- �G���[�o�b�t�@
    , ov_retcode               => lv_retcode                -- ���^�[���R�[�h
    , ov_errmsg                => lv_errmsg                 -- �G���[���b�Z�[�W
    , iv_conc_name             => cv_pkg_name               -- �R���J�����g��
    , iv_file_name             => lv_file_name              -- �o�̓t�@�C����
    , iv_file_id               => cv_file_id                -- ���[ID
    , iv_output_mode           => cv_output_mode            -- �o�͋敪
    , iv_frm_file              => cv_frm_file               -- �t�H�[���l���t�@�C����
    , iv_vrq_file              => cv_vrq_file               -- �N�G���[�l���t�@�C����
    , iv_org_id                => NULL                      -- ORG_ID
    , iv_user_name             => fnd_global.user_name      -- ���O�C���E���[�U��
    , iv_resp_name             => fnd_global.resp_name      -- ���O�C���E���[�U�E�Ӗ�
    , iv_doc_name              => NULL                      -- ������
    , iv_printer_name          => NULL                      -- �v�����^��
    , iv_request_id            => TO_CHAR( cn_request_id )  -- �v��ID
    , iv_nodata_msg            => NULL                      -- �f�[�^�Ȃ����b�Z�[�W
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_cok
                    , iv_name         => cv_msg_cok_00040
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_outmsg
                    , in_new_line => 0
                    );
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐���O ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END start_svf;
--
  /**********************************************************************************
   * Procedure Name   : update_xrbpd
   * Description      : �x���ē����i���ׁj���[���[�N�e�[�u���X�V(A-5)
   ***********************************************************************************/
  PROCEDURE update_xrbpd(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'update_xrbpd';     -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
    --==================================================
    -- ���[�J����O
    --==================================================
    --*** �G���[�I�� ***
    error_proc_expt                EXCEPTION;
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- �x���斈�W��f�[�^���������[�v
    --==================================================
    << g_summary_tab_loop >>
    FOR i IN 1 .. g_summary_tab.COUNT LOOP
      --==================================================
      -- ���[���[�N�e�[�u���X�V
      --==================================================
      UPDATE xxcok_rep_bm_pg_detail     xrbpd
      SET xrbpd.selling_amt_sum    = g_summary_tab(i).selling_amt_sum
        , xrbpd.bm_index_1         = CASE
                                     WHEN g_summary_tab(i).bm_amt_1 > 0 THEN
                                       g_summary_tab(i).bm_index_1
                                     ELSE
                                       g_summary_tab(i).bm_index_2
                                     END
        , xrbpd.bm_amt_1           = CASE
                                     WHEN g_summary_tab(i).bm_amt_1 > 0 THEN
                                       g_summary_tab(i).bm_amt_1
                                     ELSE
                                       g_summary_tab(i).bm_amt_2
                                     END
        , xrbpd.bm_index_2         = CASE
                                     WHEN g_summary_tab(i).bm_amt_1 > 0
                                      AND g_summary_tab(i).bm_amt_2 > 0 THEN
                                       g_summary_tab(i).bm_index_2
                                     ELSE
                                       NULL
                                     END
        , xrbpd.bm_amt_2           = CASE
                                     WHEN g_summary_tab(i).bm_amt_1 > 0
                                      AND g_summary_tab(i).bm_amt_2 > 0 THEN
                                       g_summary_tab(i).bm_amt_2
                                     ELSE
                                       NULL
                                     END
        , xrbpd.payment_amt_tax    = g_summary_tab(i).payment_amt_tax
        , xrbpd.target_month       = TO_CHAR( g_summary_tab(i).closing_date
                                            , cv_format_ee_month
                                            , cv_nls_param )
        , xrbpd.term_from          = TO_CHAR( g_summary_tab(i).term_from
                                            , cv_format_ee_date
                                            , cv_nls_param )
        , xrbpd.term_to            = TO_CHAR( g_summary_tab(i).term_to
                                            , cv_format_ee_date
                                            , cv_nls_param )
        , xrbpd.payment_date       = TO_CHAR( g_summary_tab(i).payment_date
                                            , cv_format_ee_date
                                            , cv_nls_param )
      WHERE xrbpd.request_id       = cn_request_id
        AND xrbpd.payment_code     = g_summary_tab(i).payment_code
      ;
    END LOOP;
    --==================================================
    -- �o�̓p�����[�^�ݒ�
    --==================================================
    ov_retcode := lv_end_retcode;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END update_xrbpd;
--
  /**********************************************************************************
   * Procedure Name   : get_xrbpd
   * Description      : ���[�N�e�[�u���x���斈�W��f�[�^�擾(A-4)
   ***********************************************************************************/
  PROCEDURE get_xrbpd(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'get_xrbpd';        -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
    --==================================================
    -- ���[�J����O
    --==================================================
    --*** �G���[�I�� ***
    error_proc_expt                EXCEPTION;
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- �x���斈�W��f�[�^�擾
    --==================================================
    OPEN  g_summary_cur;
    FETCH g_summary_cur BULK COLLECT INTO g_summary_tab;
    CLOSE g_summary_cur;
    --==================================================
    -- �o�̓p�����[�^�ݒ�
    --==================================================
    ov_retcode := lv_end_retcode;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END get_xrbpd;
--
  /**********************************************************************************
   * Procedure Name   : insert_xrbpd
   * Description      : �f�[�^�擾(A-2)�E���[�N�e�[�u���f�[�^�o�^(A-3)
   ***********************************************************************************/
  PROCEDURE insert_xrbpd(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'insert_xrbpd';     -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- �{�U�i�ē��L�j
    --==================================================
    INSERT INTO xxcok_rep_bm_pg_detail(
      payment_code                     -- �x����R�[�h
    , publication_date                 -- ���s��
    , payment_zip_code                 -- �x����X�֔ԍ�
    , payment_addr_1                   -- �x����Z��1
    , payment_addr_2                   -- �x����Z��2
    , payment_name_1                   -- �x���戶��1
    , payment_name_2                   -- �x���戶��2
    , contact_base                     -- �n��R�[�h�i�A���拒�_�j
    , contact_base_code                -- �A���拒�_�R�[�h
    , contact_base_name                -- �A���拒�_��
    , contact_addr_1                   -- �A����Z��1
    , contact_addr_2                   -- �A����Z��2
    , contact_phone_no                 -- �A����d�b�ԍ�
    , selling_amt_sum                  -- �̔����z���v
    , bm_index_1                       -- ���v���o��1
    , bm_amt_1                         -- ���v�萔��1
    , bm_index_2                       -- ���v���o��2
    , bm_amt_2                         -- ���v�萔��2
    , payment_amt_tax                  -- �x�����z�i�ō��j
    , closing_date                     -- ���ߓ�
    , term_from_wk                     -- �Ώۊ��ԁiFrom�j_���[�N
    , term_to_wk                       -- �Ώۊ��ԁiTo�j_���[�N
    , payment_date_wk                  -- ���x����_���[�N
    , cust_code                        -- �ڋq�R�[�h
    , cust_name                        -- �ڋq��
    , selling_base                     -- �n��R�[�h�i����v�㋒�_�j
    , selling_base_code                -- ����v�㋒�_�R�[�h
    , selling_base_name                -- ����v�㋒�_��
    , calc_type                        -- �v�Z����
    , calc_type_sort                   -- �v�Z�����\�[�g��
    , container_type_code              -- �e��敪�R�[�h
    , selling_price                    -- ����
    , detail_name                      -- ���ז�
    , selling_amt                      -- �̔����z
    , selling_qty                      -- �̔�����
    , backmargin                       -- �̔��萔��
    , created_by                       -- �쐬��
    , creation_date                    -- �쐬��
    , last_updated_by                  -- �ŏI�X�V��
    , last_update_date                 -- �ŏI�X�V��
    , last_update_login                -- �ŏI�X�V���O�C��
    , request_id                       -- �v��ID
    , program_application_id           -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
    , program_id                       -- �R���J�����g�E�v���O����ID
    , program_update_date              -- �v���O�����X�V��
    )
    SELECT xbb.supplier_code                                    AS payment_code
         , TO_CHAR( SYSDATE, cv_format_date )                   AS publication_date
         , pvsa.zip                                             AS payment_zip_code
         , pvsa.state || pvsa.city || pvsa.address_line1        AS payment_addr_1
         , pvsa.address_line2                                   AS payment_addr_2
         , SUBSTR( pv.vendor_name,  1, 15 )                     AS payment_name_1
         , SUBSTR( pv.vendor_name, 16     )                     AS payment_name_2
         , hca2.contact_area_code                               AS contact_base
         , hca2.contact_code                                    AS contact_base_code
         , hca2.contact_name                                    AS contact_base_name
         , hca2.contact_address1                                AS contact_addr_1
         , hca2.contact_address2                                AS contact_addr_2
         , hca2.contact_phone_num                               AS contact_phone_no
         , NULL                                                 AS selling_amt_sum
         , NULL                                                 AS bm_index_1
         , NULL                                                 AS bm_amt_1
         , NULL                                                 AS bm_index_2
         , NULL                                                 AS bm_amt_2
-- 2009/05/11 Ver.1.3 [��QT1_0841] SCS K.Yamaguchi REPAIR START
--         , SUM( xbb.expect_payment_amt_tax )                    AS payment_amt_tax
         , SUM( NVL( xcbs.cond_bm_amt_tax,  0 )
              + NVL( xcbs.electric_amt_tax, 0 ) )               AS payment_amt_tax
-- 2009/05/11 Ver.1.3 [��QT1_0841] SCS K.Yamaguchi REPAIR END
         , MAX( xbb.closing_date )                              AS target_month
         , MIN( xcbs.calc_target_period_from)                   AS term_from
         , MAX( xcbs.calc_target_period_to )                    AS term_to
         , MAX( xbb.expect_payment_date )                       AS payment_date
         , xcbs.delivery_cust_code                              AS cust_code
         , hca1.cust_name                                       AS cust_name
         , hca3.base_area_code                                  AS selling_base
         , xcbs.base_code                                       AS selling_base_code
         , hca3.base_name                                       AS selling_base_name
         , xcbs.calc_type                                       AS calc_type
         , flv2.calc_type_sort                                  AS calc_type_sort
         , flv1.container_type_code                             AS container_type_code
         , xcbs.selling_price                                   AS selling_price
         ,    flv2.line_name
           || CASE xcbs.calc_type
              WHEN '10' THEN
                TO_CHAR( xcbs.selling_price )
              WHEN '20' THEN
                flv1.container_type_name
              END                                               AS detail_name
         , SUM( xcbs.selling_amt_tax )                          AS selling_amt
         , SUM( xcbs.delivery_qty )                             AS selling_qty
         , SUM( CASE xcbs.calc_type
                WHEN '10' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '20' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '30' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '40' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '50' THEN
                  xcbs.electric_amt_tax
                END
           )                                                    AS backmargin
         , cn_created_by                                        AS created_by
         , SYSDATE                                              AS creation_date
         , cn_last_updated_by                                   AS last_updated_by
         , SYSDATE                                              AS last_update_date
         , cn_last_update_login                                 AS last_update_login
         , cn_request_id                                        AS request_id
         , cn_program_application_id                            AS program_application_id
         , cn_program_id                                        AS program_id
         , SYSDATE                                              AS program_update_date
    FROM xxcok_cond_bm_support    xcbs -- �����ʔ̎�̋��e�[�u��
       , xxcok_backmargin_balance xbb  -- �̎�c���e�[�u��
       , po_vendors               pv   -- �d����}�X�^
       , po_vendor_sites_all      pvsa -- �d����T�C�g�}�X�^
       , ( SELECT hca.account_number             AS cust_code
                , hp.party_name                  AS cust_name
           FROM hz_cust_accounts            hca       -- �ڋq�}�X�^
              , hz_parties                  hp        -- �p�[�e�B�}�X�^
           WHERE hca.party_id        = hp.party_id
         )                        hca1
       , ( SELECT hca.account_number             AS contact_code
                , hp.party_name                  AS contact_name
                , hl.address3                    AS contact_area_code
                ,    hl.state
                  || hl.city 
                  || hl.address1                 AS contact_address1
                , hl.address2                    AS contact_address2
                , hl.address_lines_phonetic      AS contact_phone_num
           FROM hz_cust_accounts            hca       -- �ڋq�}�X�^
              , hz_cust_acct_sites_all      hcasa     -- �ڋq���ݒn�}�X�^
              , hz_parties                  hp        -- �p�[�e�B�}�X�^
              , hz_party_sites              hps       -- �p�[�e�B�T�C�g�}�X�^
              , hz_locations                hl        -- �ڋq���Ə��}�X�^
           WHERE hca.cust_account_id = hcasa.cust_account_id
             AND hca.party_id        = hp.party_id
             AND hcasa.party_site_id = hps.party_site_id
             AND hps.location_id     = hl.location_id
             AND hcasa.org_id        = gn_org_id
         )                        hca2
       , ( SELECT hca.account_number             AS base_code
                , hp.party_name                  AS base_name
                , hl.address3                    AS base_area_code
           FROM hz_cust_accounts            hca       -- �ڋq�}�X�^
              , hz_cust_acct_sites_all      hcasa     -- �ڋq���ݒn�}�X�^
              , hz_parties                  hp        -- �p�[�e�B�}�X�^
              , hz_party_sites              hps       -- �p�[�e�B�T�C�g�}�X�^
              , hz_locations                hl        -- �ڋq���Ə��}�X�^
           WHERE hca.cust_account_id = hcasa.cust_account_id
             AND hca.party_id        = hp.party_id
             AND hcasa.party_site_id = hps.party_site_id
             AND hps.location_id     = hl.location_id
             AND hcasa.org_id        = gn_org_id
         )                        hca3
-- Start 2009/03/03 M.Hiruta
--       , ( SELECT flv.lookup_code                AS container_type_code
       , ( SELECT flv.attribute1                 AS container_type_code
-- End   2009/03/03 M.Hiruta
                , flv.meaning                    AS container_type_name
           FROM fnd_lookup_values           flv       -- �N�C�b�N�R�[�h
           WHERE flv.lookup_type     = cv_lookup_type_01
             AND flv.language        = USERENV( 'LANG' )
         )                        flv1
       , ( SELECT flv.lookup_code                AS calc_type
                , flv.attribute1                 AS line_name
                , flv.attribute2                 AS calc_type_sort
           FROM fnd_lookup_values           flv       -- �N�C�b�N�R�[�h
           WHERE flv.lookup_type     = cv_lookup_type_02
             AND flv.language        = USERENV( 'LANG' )
         )                        flv2
    WHERE xcbs.base_code               = xbb.base_code
      AND xcbs.delivery_cust_code      = xbb.cust_code
      AND xcbs.supplier_code           = xbb.supplier_code
      AND xcbs.closing_date            = xbb.closing_date
      AND xcbs.expect_payment_date     = xbb.expect_payment_date
      AND xcbs.base_code               = hca3.base_code
      AND xcbs.delivery_cust_code      = hca1.cust_code
      AND xcbs.supplier_code           = pv.segment1
      AND pv.vendor_id                 = pvsa.vendor_id
      AND ( pvsa.inactive_date         > gd_process_date OR pvsa.inactive_date IS NULL )
      AND pvsa.attribute5              = hca2.contact_code
      AND xcbs.container_type_code     = flv1.container_type_code(+)
      AND xcbs.calc_type               = flv2.calc_type
      AND pvsa.org_id                  = gn_org_id
      AND pvsa.attribute4              = cv_bm_type_1
      AND pvsa.attribute5              = gv_param_base_code
-- 2009/05/11 Ver.1.3 [��QT1_0866] SCS K.Yamaguchi REPAIR START
--      AND xbb.publication_date   BETWEEN TO_DATE( gv_param_target_ym, cv_format_fxrrrrmm )
--                                     AND LAST_DAY( TO_DATE( gv_param_target_ym, cv_format_fxrrrrmm ) )
      AND (    (     xbb.fb_interface_status      = '0'
                 AND xbb.fb_interface_date       IS NULL
                 AND xbb.publication_date   BETWEEN TO_DATE( gv_param_target_ym, cv_format_fxrrrrmm )
                                                AND LAST_DAY( TO_DATE( gv_param_target_ym, cv_format_fxrrrrmm ) )
               )
            OR
               (     xbb.fb_interface_status      = '1'
                 AND xbb.fb_interface_date  BETWEEN TO_DATE( gv_param_target_ym, cv_format_fxrrrrmm )
                                                AND LAST_DAY( TO_DATE( gv_param_target_ym, cv_format_fxrrrrmm ) )
               )
          )
-- 2009/05/11 Ver.1.3 [��QT1_0866] SCS K.Yamaguchi REPAIR END
      AND xbb.supplier_code            = NVL( gv_param_vendor_code, xbb.supplier_code )
    GROUP BY xbb.supplier_code
           , pvsa.zip
           , pvsa.state || pvsa.city || pvsa.address_line1
           , pvsa.address_line2
           , SUBSTR( pv.vendor_name,  1, 15 )
           , SUBSTR( pv.vendor_name, 16     )
           , hca2.contact_area_code
           , hca2.contact_code
           , hca2.contact_name
           , hca2.contact_address1
           , hca2.contact_address2
           , hca2.contact_phone_num
           , xcbs.delivery_cust_code
           , hca1.cust_name
           , hca3.base_area_code
           , xcbs.base_code
           , hca3.base_name
           , xcbs.calc_type
           , flv2.calc_type_sort
           , flv1.container_type_code
           , xcbs.selling_price
           ,    flv2.line_name
             || CASE xcbs.calc_type
                WHEN '10' THEN
                  TO_CHAR( xcbs.selling_price )
                WHEN '20' THEN
                  flv1.container_type_name
                END
    ;
    --==================================================
    -- �{�U�i�ē����j
    --==================================================
    INSERT INTO xxcok_rep_bm_pg_detail(
      payment_code                     -- �x����R�[�h
    , publication_date                 -- ���s��
    , payment_zip_code                 -- �x����X�֔ԍ�
    , payment_addr_1                   -- �x����Z��1
    , payment_addr_2                   -- �x����Z��2
    , payment_name_1                   -- �x���戶��1
    , payment_name_2                   -- �x���戶��2
    , contact_base                     -- �n��R�[�h�i�A���拒�_�j
    , contact_base_code                -- �A���拒�_�R�[�h
    , contact_base_name                -- �A���拒�_��
    , contact_addr_1                   -- �A����Z��1
    , contact_addr_2                   -- �A����Z��2
    , contact_phone_no                 -- �A����d�b�ԍ�
    , selling_amt_sum                  -- �̔����z���v
    , bm_index_1                       -- ���v���o��1
    , bm_amt_1                         -- ���v�萔��1
    , bm_index_2                       -- ���v���o��2
    , bm_amt_2                         -- ���v�萔��2
    , payment_amt_tax                  -- �x�����z�i�ō��j
    , closing_date                     -- ���ߓ�
    , term_from_wk                     -- �Ώۊ��ԁiFrom�j_���[�N
    , term_to_wk                       -- �Ώۊ��ԁiTo�j_���[�N
    , payment_date_wk                  -- ���x����_���[�N
    , cust_code                        -- �ڋq�R�[�h
    , cust_name                        -- �ڋq��
    , selling_base                     -- �n��R�[�h�i����v�㋒�_�j
    , selling_base_code                -- ����v�㋒�_�R�[�h
    , selling_base_name                -- ����v�㋒�_��
    , calc_type                        -- �v�Z����
    , calc_type_sort                   -- �v�Z�����\�[�g��
    , container_type_code              -- �e��敪�R�[�h
    , selling_price                    -- ����
    , detail_name                      -- ���ז�
    , selling_amt                      -- �̔����z
    , selling_qty                      -- �̔�����
    , backmargin                       -- �̔��萔��
    , created_by                       -- �쐬��
    , creation_date                    -- �쐬��
    , last_updated_by                  -- �ŏI�X�V��
    , last_update_date                 -- �ŏI�X�V��
    , last_update_login                -- �ŏI�X�V���O�C��
    , request_id                       -- �v��ID
    , program_application_id           -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
    , program_id                       -- �R���J�����g�E�v���O����ID
    , program_update_date              -- �v���O�����X�V��
    )
    SELECT xbb.supplier_code                                    AS payment_code
         , TO_CHAR( SYSDATE, cv_format_date )                   AS publication_date
         , pvsa.zip                                             AS payment_zip_code
         , pvsa.state || pvsa.city || pvsa.address_line1        AS payment_addr_1
         , pvsa.address_line2                                   AS payment_addr_2
         , SUBSTR( pv.vendor_name,  1, 15 )                     AS payment_name_1
         , SUBSTR( pv.vendor_name, 16     )                     AS payment_name_2
         , hca2.contact_area_code                               AS contact_base
         , hca2.contact_code                                    AS contact_base_code
         , hca2.contact_name                                    AS contact_base_name
         , hca2.contact_address1                                AS contact_addr_1
         , hca2.contact_address2                                AS contact_addr_2
         , hca2.contact_phone_num                               AS contact_phone_no
         , NULL                                                 AS selling_amt_sum
         , NULL                                                 AS bm_index_1
         , NULL                                                 AS bm_amt_1
         , NULL                                                 AS bm_index_2
         , NULL                                                 AS bm_amt_2
-- 2009/05/11 Ver.1.3 [��QT1_0841] SCS K.Yamaguchi REPAIR START
--         , SUM( xbb.expect_payment_amt_tax )                    AS payment_amt_tax
         , SUM( NVL( xcbs.cond_bm_amt_tax,  0 )
              + NVL( xcbs.electric_amt_tax, 0 ) )               AS payment_amt_tax
-- 2009/05/11 Ver.1.3 [��QT1_0841] SCS K.Yamaguchi REPAIR END
         , MAX( xbb.closing_date )                              AS target_month
         , MIN( xcbs.calc_target_period_from)                   AS term_from
         , MAX( xcbs.calc_target_period_to )                    AS term_to
         , MAX( xbb.expect_payment_date )                       AS payment_date
         , xcbs.delivery_cust_code                              AS cust_code
         , hca1.cust_name                                       AS cust_name
         , hca3.base_area_code                                  AS selling_base
         , xcbs.base_code                                       AS selling_base_code
         , hca3.base_name                                       AS selling_base_name
         , xcbs.calc_type                                       AS calc_type
         , flv2.calc_type_sort                                  AS calc_type_sort
         , flv1.container_type_code                             AS container_type_code
         , xcbs.selling_price                                   AS selling_price
         ,    flv2.line_name
           || CASE xcbs.calc_type
              WHEN '10' THEN
                TO_CHAR( xcbs.selling_price )
              WHEN '20' THEN
                flv1.container_type_name
              END                                               AS detail_name
         , SUM( xcbs.selling_amt_tax )                          AS selling_amt
         , SUM( xcbs.delivery_qty )                             AS selling_qty
         , SUM( CASE xcbs.calc_type
                WHEN '10' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '20' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '30' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '40' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '50' THEN
                  xcbs.electric_amt_tax
                END
           )                                                    AS backmargin
         , cn_created_by                                        AS created_by
         , SYSDATE                                              AS creation_date
         , cn_last_updated_by                                   AS last_updated_by
         , SYSDATE                                              AS last_update_date
         , cn_last_update_login                                 AS last_update_login
         , cn_request_id                                        AS request_id
         , cn_program_application_id                            AS program_application_id
         , cn_program_id                                        AS program_id
         , SYSDATE                                              AS program_update_date
    FROM xxcok_cond_bm_support    xcbs -- �����ʔ̎�̋��e�[�u��
       , xxcok_backmargin_balance xbb  -- �̎�c���e�[�u��
       , po_vendors               pv   -- �d����}�X�^
       , po_vendor_sites_all      pvsa -- �d����T�C�g�}�X�^
       , ( SELECT hca.account_number             AS cust_code
                , hp.party_name                  AS cust_name
           FROM hz_cust_accounts            hca       -- �ڋq�}�X�^
              , hz_parties                  hp        -- �p�[�e�B�}�X�^
           WHERE hca.party_id        = hp.party_id
         )                        hca1
       , ( SELECT hca.account_number             AS contact_code
                , hp.party_name                  AS contact_name
                , hl.address3                    AS contact_area_code
                ,    hl.state
                  || hl.city
                  || hl.address1                 AS contact_address1
                , hl.address2                    AS contact_address2
                , hl.address_lines_phonetic      AS contact_phone_num
           FROM hz_cust_accounts            hca       -- �ڋq�}�X�^
              , hz_cust_acct_sites_all      hcasa     -- �ڋq���ݒn�}�X�^
              , hz_parties                  hp        -- �p�[�e�B�}�X�^
              , hz_party_sites              hps       -- �p�[�e�B�T�C�g�}�X�^
              , hz_locations                hl        -- �ڋq���Ə��}�X�^
           WHERE hca.cust_account_id = hcasa.cust_account_id
             AND hca.party_id        = hp.party_id
             AND hcasa.party_site_id = hps.party_site_id
             AND hps.location_id     = hl.location_id
             AND hcasa.org_id        = gn_org_id
         )                        hca2
       , ( SELECT hca.account_number             AS base_code
                , hp.party_name                  AS base_name
                , hl.address3                    AS base_area_code
           FROM hz_cust_accounts            hca       -- �ڋq�}�X�^
              , hz_cust_acct_sites_all      hcasa     -- �ڋq���ݒn�}�X�^
              , hz_parties                  hp        -- �p�[�e�B�}�X�^
              , hz_party_sites              hps       -- �p�[�e�B�T�C�g�}�X�^
              , hz_locations                hl        -- �ڋq���Ə��}�X�^
           WHERE hca.cust_account_id = hcasa.cust_account_id
             AND hca.party_id        = hp.party_id
             AND hcasa.party_site_id = hps.party_site_id
             AND hps.location_id     = hl.location_id
             AND hcasa.org_id        = gn_org_id
         )                        hca3
-- Start 2009/03/03 M.Hiruta
--       , ( SELECT flv.lookup_code                AS container_type_code
       , ( SELECT flv.attribute1                 AS container_type_code
-- End   2009/03/03 M.Hiruta
               , flv.meaning                     AS container_type_name
           FROM fnd_lookup_values           flv       -- �N�C�b�N�R�[�h
           WHERE flv.lookup_type     = cv_lookup_type_01
             AND flv.language        = USERENV( 'LANG' )
         )                        flv1
       , ( SELECT flv.lookup_code                AS calc_type
                , flv.attribute1                 AS line_name
                , flv.attribute2                 AS calc_type_sort
           FROM fnd_lookup_values           flv       -- �N�C�b�N�R�[�h
           WHERE flv.lookup_type     = cv_lookup_type_02
             AND flv.language        = USERENV( 'LANG' )
         )                        flv2
    WHERE xcbs.base_code               = xbb.base_code
      AND xcbs.delivery_cust_code      = xbb.cust_code
      AND xcbs.supplier_code           = xbb.supplier_code
      AND xcbs.closing_date            = xbb.closing_date
      AND xcbs.expect_payment_date     = xbb.expect_payment_date
      AND xcbs.base_code               = hca3.base_code
      AND xcbs.delivery_cust_code      = hca1.cust_code
      AND xcbs.supplier_code           = pv.segment1
      AND pv.vendor_id                 = pvsa.vendor_id
      AND ( pvsa.inactive_date         > gd_process_date OR pvsa.inactive_date IS NULL )
      AND pvsa.attribute5              = hca2.contact_code
      AND xcbs.container_type_code     = flv1.container_type_code(+)
      AND xcbs.calc_type               = flv2.calc_type
      AND pvsa.org_id                  = gn_org_id
      AND pvsa.attribute4              = cv_bm_type_2
      AND pvsa.attribute5              = gv_param_base_code
      AND xbb.fb_interface_date  BETWEEN TO_DATE( gv_param_target_ym, cv_format_fxrrrrmm )
                                      AND LAST_DAY( TO_DATE( gv_param_target_ym, cv_format_fxrrrrmm ) )
      AND xbb.supplier_code            = NVL( gv_param_vendor_code, xbb.supplier_code )
-- 2009/05/11 Ver.1.3 [��QT1_0866] SCS K.Yamaguchi REPAIR START
--      AND xbb.edi_interface_status     = '1'
      AND xbb.fb_interface_status      = '1'
-- 2009/05/11 Ver.1.3 [��QT1_0866] SCS K.Yamaguchi REPAIR END
    GROUP BY xbb.supplier_code
           , pvsa.zip
           , pvsa.state || pvsa.city || pvsa.address_line1
           , pvsa.address_line2
           , SUBSTR( pv.vendor_name,  1, 15 )
           , SUBSTR( pv.vendor_name, 16     )
           , hca2.contact_area_code
           , hca2.contact_code
           , hca2.contact_name
           , hca2.contact_address1
           , hca2.contact_address2
           , hca2.contact_phone_num
           , xcbs.delivery_cust_code
           , hca1.cust_name
           , hca3.base_area_code
           , xcbs.base_code
           , hca3.base_name
           , xcbs.calc_type
           , flv2.calc_type_sort
           , flv1.container_type_code
           , xcbs.selling_price
           ,    flv2.line_name
             || CASE xcbs.calc_type
                WHEN '10' THEN
                  TO_CHAR( xcbs.selling_price )
                WHEN '20' THEN
                  flv1.container_type_name
                END
    ;
    --==================================================
    -- AP�x��
    --==================================================
    INSERT INTO xxcok_rep_bm_pg_detail(
      payment_code                     -- �x����R�[�h
    , publication_date                 -- ���s��
    , payment_zip_code                 -- �x����X�֔ԍ�
    , payment_addr_1                   -- �x����Z��1
    , payment_addr_2                   -- �x����Z��2
    , payment_name_1                   -- �x���戶��1
    , payment_name_2                   -- �x���戶��2
    , contact_base                     -- �n��R�[�h�i�A���拒�_�j
    , contact_base_code                -- �A���拒�_�R�[�h
    , contact_base_name                -- �A���拒�_��
    , contact_addr_1                   -- �A����Z��1
    , contact_addr_2                   -- �A����Z��2
    , contact_phone_no                 -- �A����d�b�ԍ�
    , selling_amt_sum                  -- �̔����z���v
    , bm_index_1                       -- ���v���o��1
    , bm_amt_1                         -- ���v�萔��1
    , bm_index_2                       -- ���v���o��2
    , bm_amt_2                         -- ���v�萔��2
    , payment_amt_tax                  -- �x�����z�i�ō��j
    , closing_date                     -- ���ߓ�
    , term_from_wk                     -- �Ώۊ��ԁiFrom�j_���[�N
    , term_to_wk                       -- �Ώۊ��ԁiTo�j_���[�N
    , payment_date_wk                  -- ���x����_���[�N
    , cust_code                        -- �ڋq�R�[�h
    , cust_name                        -- �ڋq��
    , selling_base                     -- �n��R�[�h�i����v�㋒�_�j
    , selling_base_code                -- ����v�㋒�_�R�[�h
    , selling_base_name                -- ����v�㋒�_��
    , calc_type                        -- �v�Z����
    , calc_type_sort                   -- �v�Z�����\�[�g��
    , container_type_code              -- �e��敪�R�[�h
    , selling_price                    -- ����
    , detail_name                      -- ���ז�
    , selling_amt                      -- �̔����z
    , selling_qty                      -- �̔�����
    , backmargin                       -- �̔��萔��
    , created_by                       -- �쐬��
    , creation_date                    -- �쐬��
    , last_updated_by                  -- �ŏI�X�V��
    , last_update_date                 -- �ŏI�X�V��
    , last_update_login                -- �ŏI�X�V���O�C��
    , request_id                       -- �v��ID
    , program_application_id           -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
    , program_id                       -- �R���J�����g�E�v���O����ID
    , program_update_date              -- �v���O�����X�V��
    )
    SELECT xbb.supplier_code                                    AS payment_code
         , TO_CHAR( SYSDATE, cv_format_date )                   AS publication_date
         , pvsa.zip                                             AS payment_zip_code
         , pvsa.state || pvsa.city || pvsa.address_line1        AS payment_addr_1
         , pvsa.address_line2                                   AS payment_addr_2
         , SUBSTR( pv.vendor_name,  1, 15 )                     AS payment_name_1
         , SUBSTR( pv.vendor_name, 16     )                     AS payment_name_2
         , hca3.base_area_code                                  AS contact_base
         , hca3.base_code                                       AS contact_base_code
         , hca3.base_name                                       AS contact_base_name
         , hca3.base_address1                                   AS contact_addr_1
         , hca3.base_address2                                   AS contact_addr_2
         , hca3.base_phone_num                                  AS contact_phone_no
         , NULL                                                 AS selling_amt_sum
         , NULL                                                 AS bm_index_1
         , NULL                                                 AS bm_amt_1
         , NULL                                                 AS bm_index_2
         , NULL                                                 AS bm_amt_2
-- 2009/05/11 Ver.1.3 [��QT1_0841] SCS K.Yamaguchi REPAIR START
--         , SUM( xbb.expect_payment_amt_tax )                    AS payment_amt_tax
         , SUM( NVL( xcbs.cond_bm_amt_tax,  0 )
              + NVL( xcbs.electric_amt_tax, 0 ) )               AS payment_amt_tax
-- 2009/05/11 Ver.1.3 [��QT1_0841] SCS K.Yamaguchi REPAIR END
         , MAX( xbb.closing_date )                              AS target_month
         , MIN( xcbs.calc_target_period_from)                   AS term_from
         , MAX( xcbs.calc_target_period_to )                    AS term_to
         , MAX( xbb.expect_payment_date )                       AS payment_date
         , xcbs.delivery_cust_code                              AS cust_code
         , hca1.cust_name                                       AS cust_name
         , hca3.base_area_code                                  AS selling_base
         , xcbs.base_code                                       AS selling_base_code
         , hca3.base_name                                       AS selling_base_name
         , xcbs.calc_type                                       AS calc_type
         , flv2.calc_type_sort                                  AS calc_type_sort
         , flv1.container_type_code                             AS container_type_code
         , xcbs.selling_price                                   AS selling_price
         ,    flv2.line_name
           || CASE xcbs.calc_type
              WHEN '10' THEN
                TO_CHAR( xcbs.selling_price )
              WHEN '20' THEN
                flv1.container_type_name
              END                                               AS detail_name
         , SUM( xcbs.selling_amt_tax )                          AS selling_amt
         , SUM( xcbs.delivery_qty )                             AS selling_qty
         , SUM( CASE xcbs.calc_type
                WHEN '10' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '20' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '30' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '40' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '50' THEN
                  xcbs.electric_amt_tax
                END
           )                                                    AS backmargin
         , cn_created_by                                        AS created_by
         , SYSDATE                                              AS creation_date
         , cn_last_updated_by                                   AS last_updated_by
         , SYSDATE                                              AS last_update_date
         , cn_last_update_login                                 AS last_update_login
         , cn_request_id                                        AS request_id
         , cn_program_application_id                            AS program_application_id
         , cn_program_id                                        AS program_id
         , SYSDATE                                              AS program_update_date
    FROM xxcok_cond_bm_support    xcbs -- �����ʔ̎�̋��e�[�u��
       , xxcok_backmargin_balance xbb  -- �̎�c���e�[�u��
       , po_vendors               pv   -- �d����}�X�^
       , po_vendor_sites_all      pvsa -- �d����T�C�g�}�X�^
       , ( SELECT hca.account_number             AS cust_code
                , hp.party_name                  AS cust_name
           FROM hz_cust_accounts            hca       -- �ڋq�}�X�^
              , hz_parties                  hp        -- �p�[�e�B�}�X�^
           WHERE hca.party_id        = hp.party_id
         )                        hca1
       , ( SELECT hca.account_number             AS base_code
                , hp.party_name                  AS base_name
                , hl.address3                    AS base_area_code
                ,    hl.state
                  || hl.city
                  || hl.address1                 AS base_address1
                , hl.address2                    AS base_address2
                , hl.address_lines_phonetic      AS base_phone_num
           FROM hz_cust_accounts            hca       -- �ڋq�}�X�^
              , hz_cust_acct_sites_all      hcasa     -- �ڋq���ݒn�}�X�^
              , hz_parties                  hp        -- �p�[�e�B�}�X�^
              , hz_party_sites              hps       -- �p�[�e�B�T�C�g�}�X�^
              , hz_locations                hl        -- �ڋq���Ə��}�X�^
           WHERE hca.cust_account_id = hcasa.cust_account_id
             AND hca.party_id        = hp.party_id
             AND hcasa.party_site_id = hps.party_site_id
             AND hps.location_id     = hl.location_id
             AND hcasa.org_id        = gn_org_id
         )                        hca3
-- Start 2009/03/03 M.Hiruta
--       , ( SELECT flv.lookup_code                AS container_type_code
       , ( SELECT flv.attribute1                 AS container_type_code
-- End   2009/03/03 M.Hiruta
                , flv.meaning                    AS container_type_name
           FROM fnd_lookup_values           flv       -- �N�C�b�N�R�[�h
           WHERE flv.lookup_type     = cv_lookup_type_01
             AND flv.language        = USERENV( 'LANG' )
         )                        flv1
       , ( SELECT flv.lookup_code                AS calc_type
                , flv.attribute1                 AS line_name
                , flv.attribute2                 AS calc_type_sort
           FROM fnd_lookup_values           flv       -- �N�C�b�N�R�[�h
           WHERE flv.lookup_type     = cv_lookup_type_02
             AND flv.language        = USERENV( 'LANG' )
         )                        flv2
    WHERE xcbs.base_code               = xbb.base_code
      AND xcbs.delivery_cust_code      = xbb.cust_code
      AND xcbs.supplier_code           = xbb.supplier_code
      AND xcbs.closing_date            = xbb.closing_date
      AND xcbs.expect_payment_date     = xbb.expect_payment_date
      AND xcbs.base_code               = hca3.base_code
      AND xcbs.delivery_cust_code      = hca1.cust_code
      AND xcbs.supplier_code           = pv.segment1
      AND pv.vendor_id                 = pvsa.vendor_id
      AND ( pvsa.inactive_date         > gd_process_date OR pvsa.inactive_date IS NULL )
      AND xcbs.container_type_code     = flv1.container_type_code(+)
      AND xcbs.calc_type               = flv2.calc_type
      AND pvsa.org_id                  = gn_org_id
      AND pvsa.attribute4              = cv_bm_type_3
      AND xbb.base_code                = gv_param_base_code
      AND xbb.balance_cancel_date BETWEEN TO_DATE( gv_param_target_ym, cv_format_fxrrrrmm )
                                      AND LAST_DAY( TO_DATE( gv_param_target_ym, cv_format_fxrrrrmm ) )
      AND xbb.supplier_code            = NVL( gv_param_vendor_code, xbb.supplier_code )
      AND xbb.expect_payment_amt_tax   = 0
      AND xbb.payment_amt_tax          > 0
    GROUP BY xbb.supplier_code
           , pvsa.zip
           , pvsa.state || pvsa.city || pvsa.address_line1
           , pvsa.address_line2
           , SUBSTR( pv.vendor_name,  1, 15 )
           , SUBSTR( pv.vendor_name, 16     )
           , hca3.base_code
           , hca3.base_name
           , hca3.base_area_code
           , hca3.base_address1
           , hca3.base_address2
           , hca3.base_phone_num
           , xcbs.delivery_cust_code
           , hca1.cust_name
           , hca3.base_area_code
           , xcbs.base_code
           , hca3.base_name
           , xcbs.calc_type
           , flv2.calc_type_sort
           , flv1.container_type_code
           , xcbs.selling_price
           ,    flv2.line_name
             || CASE xcbs.calc_type
                WHEN '10' THEN
                  TO_CHAR( xcbs.selling_price )
                WHEN '20' THEN
                  flv1.container_type_name
                END
    ;
    --==================================================
    -- �����x��
    --==================================================
    INSERT INTO xxcok_rep_bm_pg_detail(
      payment_code                     -- �x����R�[�h
    , publication_date                 -- ���s��
    , payment_zip_code                 -- �x����X�֔ԍ�
    , payment_addr_1                   -- �x����Z��1
    , payment_addr_2                   -- �x����Z��2
    , payment_name_1                   -- �x���戶��1
    , payment_name_2                   -- �x���戶��2
    , contact_base                     -- �n��R�[�h�i�A���拒�_�j
    , contact_base_code                -- �A���拒�_�R�[�h
    , contact_base_name                -- �A���拒�_��
    , contact_addr_1                   -- �A����Z��1
    , contact_addr_2                   -- �A����Z��2
    , contact_phone_no                 -- �A����d�b�ԍ�
    , selling_amt_sum                  -- �̔����z���v
    , bm_index_1                       -- ���v���o��1
    , bm_amt_1                         -- ���v�萔��1
    , bm_index_2                       -- ���v���o��2
    , bm_amt_2                         -- ���v�萔��2
    , payment_amt_tax                  -- �x�����z�i�ō��j
    , closing_date                     -- ���ߓ�
    , term_from_wk                     -- �Ώۊ��ԁiFrom�j_���[�N
    , term_to_wk                       -- �Ώۊ��ԁiTo�j_���[�N
    , payment_date_wk                  -- ���x����_���[�N
    , cust_code                        -- �ڋq�R�[�h
    , cust_name                        -- �ڋq��
    , selling_base                     -- �n��R�[�h�i����v�㋒�_�j
    , selling_base_code                -- ����v�㋒�_�R�[�h
    , selling_base_name                -- ����v�㋒�_��
    , calc_type                        -- �v�Z����
    , calc_type_sort                   -- �v�Z�����\�[�g��
    , container_type_code              -- �e��敪�R�[�h
    , selling_price                    -- ����
    , detail_name                      -- ���ז�
    , selling_amt                      -- �̔����z
    , selling_qty                      -- �̔�����
    , backmargin                       -- �̔��萔��
    , created_by                       -- �쐬��
    , creation_date                    -- �쐬��
    , last_updated_by                  -- �ŏI�X�V��
    , last_update_date                 -- �ŏI�X�V��
    , last_update_login                -- �ŏI�X�V���O�C��
    , request_id                       -- �v��ID
    , program_application_id           -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
    , program_id                       -- �R���J�����g�E�v���O����ID
    , program_update_date              -- �v���O�����X�V��
    )
    SELECT xbb.supplier_code                                    AS payment_code
         , TO_CHAR( SYSDATE, cv_format_date )                   AS publication_date
         , pvsa.zip                                             AS payment_zip_code
         , pvsa.state || pvsa.city || pvsa.address_line1        AS payment_addr_1
         , pvsa.address_line2                                   AS payment_addr_2
         , SUBSTR( pv.vendor_name,  1, 15 )                     AS payment_name_1
         , SUBSTR( pv.vendor_name, 16     )                     AS payment_name_2
         , hca3.base_area_code                                  AS contact_base
         , hca3.base_code                                       AS contact_base_code
         , hca3.base_name                                       AS contact_base_name
         , hca3.base_address1                                   AS contact_addr_1
         , hca3.base_address2                                   AS contact_addr_2
         , hca3.base_phone_num                                  AS contact_phone_no
         , NULL                                                 AS selling_amt_sum
         , NULL                                                 AS bm_index_1
         , NULL                                                 AS bm_amt_1
         , NULL                                                 AS bm_index_2
         , NULL                                                 AS bm_amt_2
-- 2009/05/11 Ver.1.3 [��QT1_0841] SCS K.Yamaguchi REPAIR START
--         , SUM( xbb.expect_payment_amt_tax )                    AS payment_amt_tax
         , SUM( NVL( xcbs.cond_bm_amt_tax,  0 )
              + NVL( xcbs.electric_amt_tax, 0 ) )               AS payment_amt_tax
-- 2009/05/11 Ver.1.3 [��QT1_0841] SCS K.Yamaguchi REPAIR END
         , MAX( xbb.closing_date )                              AS target_month
         , MIN( xcbs.calc_target_period_from)                   AS term_from
         , MAX( xcbs.calc_target_period_to )                    AS term_to
         , MAX( xbb.expect_payment_date )                       AS payment_date
         , xcbs.delivery_cust_code                              AS cust_code
         , hca1.cust_name                                       AS cust_name
         , hca3.base_area_code                                  AS selling_base
         , xcbs.base_code                                       AS selling_base_code
         , hca3.base_name                                       AS selling_base_name
         , xcbs.calc_type                                       AS calc_type
         , flv2.calc_type_sort                                  AS calc_type_sort
         , flv1.container_type_code                             AS container_type_code
         , xcbs.selling_price                                   AS selling_price
         ,    flv2.line_name
           || CASE xcbs.calc_type
              WHEN '10' THEN
                TO_CHAR( xcbs.selling_price )
              WHEN '20' THEN
                flv1.container_type_name
              END                                               AS detail_name
         , SUM( xcbs.selling_amt_tax )                          AS selling_amt
         , SUM( xcbs.delivery_qty )                             AS selling_qty
         , SUM( CASE xcbs.calc_type
                WHEN '10' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '20' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '30' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '40' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '50' THEN
                  xcbs.electric_amt_tax
                END
           )                                                    AS backmargin
         , cn_created_by                                        AS created_by
         , SYSDATE                                              AS creation_date
         , cn_last_updated_by                                   AS last_updated_by
         , SYSDATE                                              AS last_update_date
         , cn_last_update_login                                 AS last_update_login
         , cn_request_id                                        AS request_id
         , cn_program_application_id                            AS program_application_id
         , cn_program_id                                        AS program_id
         , SYSDATE                                              AS program_update_date
    FROM xxcok_cond_bm_support    xcbs -- �����ʔ̎�̋��e�[�u��
       , xxcok_backmargin_balance xbb  -- �̎�c���e�[�u��
       , po_vendors               pv   -- �d����}�X�^
       , po_vendor_sites_all      pvsa -- �d����T�C�g�}�X�^
       , ( SELECT hca.account_number             AS cust_code
                , hp.party_name                  AS cust_name
           FROM hz_cust_accounts            hca       -- �ڋq�}�X�^
              , hz_parties                  hp        -- �p�[�e�B�}�X�^
           WHERE hca.party_id        = hp.party_id
         )                        hca1
       , ( SELECT hca.account_number             AS base_code
                , hp.party_name                  AS base_name
                , hl.address3                    AS base_area_code
                ,    hl.state 
                  || hl.city
                  || hl.address1                 AS base_address1
                , hl.address2                    AS base_address2
                , hl.address_lines_phonetic      AS base_phone_num
           FROM hz_cust_accounts            hca       -- �ڋq�}�X�^
              , hz_cust_acct_sites_all      hcasa     -- �ڋq���ݒn�}�X�^
              , hz_parties                  hp        -- �p�[�e�B�}�X�^
              , hz_party_sites              hps       -- �p�[�e�B�T�C�g�}�X�^
              , hz_locations                hl        -- �ڋq���Ə��}�X�^
           WHERE hca.cust_account_id = hcasa.cust_account_id
             AND hca.party_id        = hp.party_id
             AND hcasa.party_site_id = hps.party_site_id
             AND hps.location_id     = hl.location_id
             AND hcasa.org_id        = gn_org_id
         )                        hca3
-- Start 2009/03/03 M.Hiruta
--       , ( SELECT flv.lookup_code                AS container_type_code
       , ( SELECT flv.attribute1                 AS container_type_code
-- End   2009/03/03 M.Hiruta
                , flv.meaning                    AS container_type_name
           FROM fnd_lookup_values           flv       -- �N�C�b�N�R�[�h
           WHERE flv.lookup_type     = cv_lookup_type_01
             AND flv.language        = USERENV( 'LANG' )
         )                        flv1
       , ( SELECT flv.lookup_code                AS calc_type
                , flv.attribute1                 AS line_name
                , flv.attribute2                 AS calc_type_sort
           FROM fnd_lookup_values           flv       -- �N�C�b�N�R�[�h
           WHERE flv.lookup_type     = cv_lookup_type_02
             AND flv.language        = USERENV( 'LANG' )
         )                        flv2
    WHERE xcbs.base_code               = xbb.base_code
      AND xcbs.delivery_cust_code      = xbb.cust_code
      AND xcbs.supplier_code           = xbb.supplier_code
      AND xcbs.closing_date            = xbb.closing_date
      AND xcbs.expect_payment_date     = xbb.expect_payment_date
      AND xcbs.base_code               = hca3.base_code
      AND xcbs.delivery_cust_code      = hca1.cust_code
      AND xcbs.supplier_code           = pv.segment1
      AND pv.vendor_id                 = pvsa.vendor_id
      AND ( pvsa.inactive_date         > gd_process_date OR pvsa.inactive_date IS NULL )
      AND xcbs.container_type_code     = flv1.container_type_code(+)
      AND xcbs.calc_type               = flv2.calc_type
      AND pvsa.org_id                  = gn_org_id
      AND pvsa.attribute4              = cv_bm_type_4
      AND xbb.base_code                = gv_param_base_code
      AND xbb.publication_date   BETWEEN TO_DATE( gv_param_target_ym, cv_format_fxrrrrmm )
                                     AND LAST_DAY( TO_DATE( gv_param_target_ym, cv_format_fxrrrrmm ) )
      AND xbb.supplier_code            = NVL( gv_param_vendor_code, xbb.supplier_code )
    GROUP BY xbb.supplier_code
           , pvsa.zip
           , pvsa.state || pvsa.city || pvsa.address_line1
           , pvsa.address_line2
           , SUBSTR( pv.vendor_name,  1, 15 )
           , SUBSTR( pv.vendor_name, 16     )
           , hca3.base_code
           , hca3.base_name
           , hca3.base_area_code
           , hca3.base_address1
           , hca3.base_address2
           , hca3.base_phone_num
           , xcbs.delivery_cust_code
           , hca1.cust_name
           , hca3.base_area_code
           , xcbs.base_code
           , hca3.base_name
           , xcbs.calc_type
           , flv2.calc_type_sort
           , flv1.container_type_code
           , xcbs.selling_price
           ,    flv2.line_name
             || CASE xcbs.calc_type
                WHEN '10' THEN
                  TO_CHAR( xcbs.selling_price )
                WHEN '20' THEN
                  flv1.container_type_name
                END
    ;
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END insert_xrbpd;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  , iv_base_code                   IN  VARCHAR2        -- �⍇����
  , iv_target_ym                   IN  VARCHAR2        -- �ē������s�N��
  , iv_vendor_code                 IN  VARCHAR2        -- �x����
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'init';             -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
    ld_chk_date                    DATE           DEFAULT NULL;                 -- ���t�^�`�F�b�N�p�ϐ�
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- �v���O�������͍��ڂ��o��
    --==================================================
    -- �⍇��
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application          => cv_appl_short_name_cok
                  , iv_name                 => cv_msg_cok_00087
                  , iv_token_name1          => cv_tkn_base_code
                  , iv_token_value1         => iv_base_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                => FND_FILE.LOG
                  , iv_message              => lv_outmsg
                  , in_new_line             => 0
                  );
    -- �ē������s�N��
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application          => cv_appl_short_name_cok
                  , iv_name                 => cv_msg_cok_00085
                  , iv_token_name1          => cv_tkn_target_ym
                  , iv_token_value1         => iv_target_ym
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                => FND_FILE.LOG
                  , iv_message              => lv_outmsg
                  , in_new_line             => 0
                  );
    -- �x����
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application          => cv_appl_short_name_cok
                  , iv_name                 => cv_msg_cok_00086
                  , iv_token_name1          => cv_tkn_vendor_code
                  , iv_token_value1         => iv_vendor_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                => FND_FILE.LOG
                  , iv_message              => lv_outmsg
                  , in_new_line             => 1
                  );
    --==================================================
    -- �Ɩ��������t�擾
    --==================================================
    gd_process_date := TRUNC( xxccp_common_pkg2.get_process_date );
    IF( gd_process_date IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00028
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.LOG
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- �ē������s�N���^�`�F�b�N
    --==================================================
    BEGIN
      ld_chk_date := TO_DATE( iv_target_ym, cv_format_fxrrrrmm );
    EXCEPTION
      WHEN OTHERS THEN
        lv_outmsg  := xxccp_common_pkg.get_msg(
                        iv_application          => cv_appl_short_name_cok
                      , iv_name                 => cv_msg_cok_10309
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which                => FND_FILE.LOG
                      , iv_message              => lv_outmsg
                      , in_new_line             => 0
                      );
        RAISE error_proc_expt;
    END;
    --==================================================
    -- �v���t�@�C���擾(MO: �c�ƒP��)
    --==================================================
    gn_org_id := TO_NUMBER( FND_PROFILE.VALUE( cv_profile_name_03 ) );
    IF( gn_org_id IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_03
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.LOG
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- �v���t�@�C���擾(�x���ē���_�̔��萔�����o��)
    --==================================================
    gv_prompt_bm := FND_PROFILE.VALUE( cv_profile_name_01 );
    IF( gv_prompt_bm IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_01
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.LOG
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- �v���t�@�C���擾(�x���ē���_�d�C�����o��)
    --==================================================
    gv_prompt_ep := FND_PROFILE.VALUE( cv_profile_name_02 );
    IF( gv_prompt_ep IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_02
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.LOG
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    gv_param_base_code   := iv_base_code;
    gv_param_target_ym   := iv_target_ym;
    gv_param_vendor_code := iv_vendor_code;
    --==================================================
    -- �o�̓p�����[�^�ݒ�
    --==================================================
    ov_retcode := lv_end_retcode;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
--
  EXCEPTION
    -- *** �G���[�I�� ***
    WHEN error_proc_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  , iv_base_code                   IN  VARCHAR2        -- �⍇����
  , iv_target_ym                   IN  VARCHAR2        -- �ē������s�N��
  , iv_vendor_code                 IN  VARCHAR2        -- �x����
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'submain';          -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- ��������(A-1)
    --==================================================
    init(
      ov_errbuf               => lv_errbuf             -- �G���[�E���b�Z�[�W
    , ov_retcode              => lv_retcode            -- ���^�[���E�R�[�h
    , ov_errmsg               => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W
    , iv_base_code            => iv_base_code          -- �⍇����
    , iv_target_ym            => iv_target_ym          -- �ē������s�N��
    , iv_vendor_code          => iv_vendor_code        -- �x����
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --==================================================
    -- �f�[�^�擾(A-2)�E���[�N�e�[�u���f�[�^�o�^(A-3)
    --==================================================
    insert_xrbpd(
      ov_errbuf               => lv_errbuf                -- �G���[�E���b�Z�[�W
    , ov_retcode              => lv_retcode               -- ���^�[���E�R�[�h
    , ov_errmsg               => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --==================================================
    -- ���[�N�e�[�u���x���斈�W��f�[�^�擾(A-4)
    --==================================================
    get_xrbpd(
      ov_errbuf               => lv_errbuf                -- �G���[�E���b�Z�[�W
    , ov_retcode              => lv_retcode               -- ���^�[���E�R�[�h
    , ov_errmsg               => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --==================================================
    -- �x���ē����i���ׁj���[���[�N�e�[�u���X�V(A-5)
    --==================================================
    update_xrbpd(
      ov_errbuf               => lv_errbuf                -- �G���[�E���b�Z�[�W
    , ov_retcode              => lv_retcode               -- ���^�[���E�R�[�h
    , ov_errmsg               => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --==================================================
    -- �m��
    --==================================================
    COMMIT;
    --==================================================
    -- SVF�N��(A-6)
    --==================================================
    start_svf(
      ov_errbuf   => lv_errbuf   -- �G���[�E���b�Z�[�W
    , ov_retcode  => lv_retcode  -- ���^�[���E�R�[�h
    , ov_errmsg   => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --==================================================
    -- ���[�N�e�[�u���f�[�^�폜(A-7)
    --==================================================
    delete_xrbpd(
      ov_errbuf               => lv_errbuf                -- �G���[�E���b�Z�[�W
    , ov_retcode              => lv_retcode               -- ���^�[���E�R�[�h
    , ov_errmsg               => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --==================================================
    -- �o�̓p�����[�^�ݒ�
    --==================================================
    ov_retcode := lv_end_retcode;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
--
  EXCEPTION
    -- *** ���������ʗ�O ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
  PROCEDURE main(
    errbuf                         OUT VARCHAR2        -- �G���[���b�Z�[�W
  , retcode                        OUT VARCHAR2        -- �G���[�R�[�h
  , iv_base_code                   IN  VARCHAR2        -- �⍇����
  , iv_target_ym                   IN  VARCHAR2        -- �ē������s�N��
  , iv_vendor_code                 IN  VARCHAR2        -- �x����
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'main';             -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lv_message_code                VARCHAR2(100)  DEFAULT NULL;                 -- �I�����b�Z�[�W�R�[�h
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
--
  BEGIN
    --==================================================
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    --==================================================
    xxccp_common_pkg.put_log_header(
      ov_retcode              => lv_retcode
    , ov_errbuf               => lv_errbuf
    , ov_errmsg               => lv_errmsg
    , iv_which                => cv_which_log
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    --==================================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    --==================================================
    submain(
      ov_errbuf               => lv_errbuf             -- �G���[�E���b�Z�[�W
    , ov_retcode              => lv_retcode            -- ���^�[���E�R�[�h
    , ov_errmsg               => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W
    , iv_base_code            => iv_base_code          -- �⍇����
    , iv_target_ym            => iv_target_ym          -- �ē������s�N��
    , iv_vendor_code          => iv_vendor_code        -- �x����
    );
    --==================================================
    -- �G���[�o��
    --==================================================
    IF( lv_retcode = cv_status_error ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                 => FND_FILE.LOG   -- �o�͋敪
                    , iv_message               => lv_errmsg      -- ���b�Z�[�W
                    , in_new_line              => 0              -- ���s
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                 => FND_FILE.LOG
                    , iv_message               => lv_errbuf
                    , in_new_line              => 1
                    );
    END IF;
    --==================================================
    -- �Ώی����o��
    --==================================================
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appl_short_name_ccp
                  , iv_name                  => cv_msg_ccp_90000
                  , iv_token_name1           => cv_tkn_count
                  , iv_token_value1          => TO_CHAR( gn_target_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.LOG
                  , iv_message               => lv_outmsg
                  , in_new_line              => 0
                  );
    --==================================================
    -- ���������o��(�G���[�����̏ꍇ�A��������:0�� �G���[����:1��  �Ώی���0���̏ꍇ�A��������:0��)
    --==================================================
    IF( lv_retcode = cv_status_error ) THEN
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    ELSE
      IF( gn_target_cnt = 0 ) THEN
        gn_normal_cnt := 0;
      END IF;
    END IF;
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appl_short_name_ccp
                  , iv_name                  => cv_msg_ccp_90001
                  , iv_token_name1           => cv_tkn_count
                  , iv_token_value1          => TO_CHAR( gn_normal_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.LOG
                  , iv_message               => lv_outmsg
                  , in_new_line              => 0
                  );
    --==================================================
    -- �G���[�����o��
    --==================================================
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appl_short_name_ccp
                  , iv_name                  => cv_msg_ccp_90002
                  , iv_token_name1           => cv_tkn_count
                  , iv_token_value1          => TO_CHAR( gn_error_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.LOG
                  , iv_message               => lv_outmsg
                  , in_new_line              => 1
                  );
    --==================================================
    -- �����I�����b�Z�[�W�o��
    --==================================================
    IF( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_msg_ccp_90004;
    ELSE
      lv_message_code := cv_msg_ccp_90006;
    END IF;
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appl_short_name_ccp
                  , iv_name                  => lv_message_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.LOG
                  , iv_message               => lv_outmsg
                  , in_new_line              => 0
                  );
    --==================================================
    -- �X�e�[�^�X�Z�b�g
    --==================================================
    retcode := lv_retcode;
    --==================================================
    -- �I���X�e�[�^�X�G���[���A���[���o�b�N
    --==================================================
    IF( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐���O ***
    WHEN global_api_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
END XXCOK015A03R;
/
