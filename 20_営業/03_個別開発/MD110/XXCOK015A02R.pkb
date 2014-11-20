CREATE OR REPLACE PACKAGE BODY XXCOK015A02R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK015A02R(body)
 * Description      : �萔���������x������ۂ̎x���ē����i�̎����t���j��
 *                    �e����v�㋒�_�ň�����܂��B
 * MD.050           : �x���ē�������i�̎����t���j MD050_COK_015_A02
 * Version          : 1.4
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  update_xbb           �̎�c�����X�V(A-6)
 *  delete_xrbpr         ���[�N�e�[�u���f�[�^�폜(A-5)
 *  start_svf            SVF�N��(A-4)
 *  insert_xrbpr         �f�[�^�擾(A-2)�E���[�N�e�[�u���f�[�^�o�^(A-3)
 *  init                 ��������(A-1)
 *  main                 �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/20    1.0   K.Yamaguchi      �V�K�쐬
 *  2009/02/18    1.1   K.Suenaga        [��QCOK_044]�ŐV�̎d����T�C�g�����擾�E�X�V����
 *  2009/05/29    1.2   K.Yamaguchi      [��QT1_1261]�̎�c���e�[�u���X�V���ڒǉ�
 *  2009/09/10    1.3   S.Moriyama       [��Q0000060]�Z���̌����ύX�Ή�
 *  2009/10/14    1.4   S.Moriyama       [�ύX�˗�I_E_573]�d���於�́A�Z���̐ݒ���e�ύX�Ή�
 *
 *****************************************************************************************/
  --==================================================
  -- �O���[�o���萔
  --==================================================
  -- �p�b�P�[�W��
  cv_pkg_name                      CONSTANT VARCHAR2(20)    := 'XXCOK015A02R';
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
  cv_msg_ccp_90005                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90005';        -- �x���I��
  cv_msg_ccp_90006                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90006';        -- �G���[�I���S���[���o�b�N
  cv_msg_cok_00003                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00003';
  cv_msg_cok_00028                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00028';
  cv_msg_cok_00040                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00040';
  cv_msg_cok_00074                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00074';
  cv_msg_cok_00086                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00086';
  cv_msg_cok_00088                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00088';
  cv_msg_cok_10102                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10102';
  -- �g�[�N��
  cv_tkn_count                     CONSTANT VARCHAR2(30)    := 'COUNT';
  cv_tkn_errmsg                    CONSTANT VARCHAR2(30)    := 'ERRMSG';
  cv_tkn_profile                   CONSTANT VARCHAR2(30)    := 'PROFILE';
  cv_tkn_selling_base_code         CONSTANT VARCHAR2(30)    := 'SELLING_BASE_CODE';
  cv_tkn_fix_flag                  CONSTANT VARCHAR2(30)    := 'FIX_FLAG';
  cv_tkn_vendor_code               CONSTANT VARCHAR2(30)    := 'VENDOR_CODE';
  -- �Z�p���[�^
  cv_msg_part                      CONSTANT VARCHAR2(3)     := ' : ';
  cv_msg_cont                      CONSTANT VARCHAR2(3)     := '.';
  -- �v���t�@�C���E�I�v�V������
  cv_profile_name_01               CONSTANT VARCHAR2(50)    := 'XXCOK1_PAY_GUIDE_PROMPT_BM';   -- XXCOK:�x���ē���_�̔��萔�����o��
  cv_profile_name_02               CONSTANT VARCHAR2(50)    := 'XXCOK1_PAY_GUIDE_PROMPT_EP';   -- XXCOK:�x���ē���_�d�C�����o��
  cv_profile_name_03               CONSTANT VARCHAR2(50)    := 'ORG_ID';                       -- MO: �c�ƒP��
  -- �Q�ƃ^�C�v��
  cv_lookup_type_01                CONSTANT VARCHAR2(30)    := 'XXCMM_YOKI_KUBUN';    -- �e��敪
  cv_lookup_type_02                CONSTANT VARCHAR2(30)    := 'XXCOK1_BM_CALC_TYPE'; -- �̎�v�Z����
  -- ���ʊ֐����b�Z�[�W�o�͋敪
  cv_which_log                     CONSTANT VARCHAR2(10)    := 'LOG';
  -- SVF�N���p�����[�^
  cv_file_id                       CONSTANT VARCHAR2(20)    := 'XXCOK015A02R';       -- ���[ID
  cv_output_mode                   CONSTANT VARCHAR2(1)     := '1';                  -- �o�͋敪(PDF�o��)
  cv_extension                     CONSTANT VARCHAR2(10)    := '.pdf';               -- �o�̓t�@�C�����g���q(PDF�o��)
  cv_frm_file                      CONSTANT VARCHAR2(20)    := 'XXCOK015A02S.xml';   -- �t�H�[���l���t�@�C����
  cv_vrq_file                      CONSTANT VARCHAR2(20)    := 'XXCOK015A02S.vrq';   -- �N�G���[�l���t�@�C����
  -- �����t�H�[�}�b�g
  cv_format_fxrrrrmm               CONSTANT VARCHAR2(50)    := 'FXRRRRMM';
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
  -- ���̓p�����[�^�E�x���m��
  cv_param_fix_flag_y              CONSTANT VARCHAR2(5)     := 'Yes';
  cv_param_fix_flag_n              CONSTANT VARCHAR2(5)     := 'No';
-- 2009/05/29 Ver.1.2 [��QT1_1261] SCS K.Yamaguchi ADD START
  -- �A�g�X�e�[�^�X
  cv_if_status_processed           CONSTANT VARCHAR2(1)     := '1';
-- 2009/05/29 Ver.1.2 [��QT1_1261] SCS K.Yamaguchi ADD END
  --==================================================
  -- �O���[�o���ϐ�
  --==================================================
  -- �J�E���^
  gn_target_cnt                    NUMBER        DEFAULT 0;      -- �Ώی���
  gn_normal_cnt                    NUMBER        DEFAULT 0;      -- ���팏��
  gn_error_cnt                     NUMBER        DEFAULT 0;      -- �ُ팏��
  -- ���̓p�����[�^
  gv_param_base_code               VARCHAR2(4)   DEFAULT NULL;  -- ����v�㋒�_
  gv_param_fix_flag                VARCHAR2(7)   DEFAULT NULL;  -- �x���m��
  gv_param_vendor_code             VARCHAR2(9)   DEFAULT NULL;  -- �x����
  -- ���������擾�l
  gd_process_date                  DATE          DEFAULT NULL;   -- �Ɩ��������t
  gn_org_id                        NUMBER        DEFAULT NULL;   -- �c�ƒP��ID
  gv_prompt_bm                     VARCHAR2(100) DEFAULT NULL;   -- �x���ē���_�̔��萔�����o��
  gv_prompt_ep                     VARCHAR2(100) DEFAULT NULL;   -- �x���ē���_�d�C�����o��
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
   * Procedure Name   : update_xbb
   * Description      : �̎�c�����X�V(A-6)
   ***********************************************************************************/
  PROCEDURE update_xbb(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'update_xbb';     -- �v���O������
    cv_n                           CONSTANT VARCHAR2(1)  := 'N';
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
    CURSOR lock_xbb_cur IS
      SELECT xbb.bm_balance_id
      FROM xxcok_backmargin_balance     xbb  -- �̎�c���e�[�u��
         , po_vendors                   pv   -- �d����}�X�^
         , po_vendor_sites_all          pvsa -- �d����T�C�g�}�X�^
      WHERE xbb.supplier_code                = pv.segment1
        AND pv.vendor_id                     = pvsa.vendor_id
        AND xbb.expect_payment_amt_tax       > 0
        AND xbb.resv_flag                   IS NULL
        AND xbb.publication_date            IS NULL
        AND pvsa.hold_all_payments_flag      = cv_n
        AND pvsa.org_id                      = gn_org_id
        AND pvsa.attribute4                  = cv_bm_type_4
        AND xbb.base_code                    = gv_param_base_code
        AND xbb.supplier_code                = gv_param_vendor_code
        AND ( pvsa.inactive_date             < gd_process_date OR pvsa.inactive_date IS NULL )
      FOR UPDATE OF xbb.bm_balance_id NOWAIT
    ;
    TYPE l_lock_xbb_ttype          IS TABLE OF xxcok_backmargin_balance.bm_balance_id%TYPE INDEX BY BINARY_INTEGER;
    l_lock_xbb_tab                 l_lock_xbb_ttype;
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- ���b�N�E�X�V�Ώ۔̎�c��ID�擾
    --==================================================
    OPEN  lock_xbb_cur;
    FETCH lock_xbb_cur BULK COLLECT INTO l_lock_xbb_tab;
    CLOSE lock_xbb_cur;
    IF( l_lock_xbb_tab.COUNT = 0 ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_cok
                    , iv_name         => cv_msg_cok_10102
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_outmsg
                    , in_new_line => 0
                    );
      lv_end_retcode := cv_status_warn;
    ELSE
      --==================================================
      -- �̎�c���e�[�u���X�V
      --==================================================
      FORALL i IN 1 .. l_lock_xbb_tab.COUNT
      UPDATE xxcok_backmargin_balance     xbb  -- �̎�c���e�[�u��
      SET payment_amt_tax            = expect_payment_amt_tax    -- �x���z�i�ō��j
        , expect_payment_amt_tax     = 0                         -- �x���\��z�i�ō��j
        , publication_date           = gd_process_date           -- �ē���������
-- 2009/05/29 Ver.1.2 [��QT1_1261] SCS K.Yamaguchi ADD START
        , fb_interface_status        = cv_if_status_processed    -- �A�g�X�e�[�^�X�i�{�U�pFB�j
        , fb_interface_date          = gd_process_date           -- �A�g���i�{�U�pFB�j
        , edi_interface_status       = cv_if_status_processed    -- �A�g�X�e�[�^�X�iEDI�x���ē����j
        , edi_interface_date         = gd_process_date           -- �A�g���iEDI�x���ē����j
        , gl_interface_status        = cv_if_status_processed    -- �A�g�X�e�[�^�X�iGL�j
        , gl_interface_date          = gd_process_date           -- �A�g���iGL�j
        , balance_cancel_date        = gd_process_date           -- �c�������
-- 2009/05/29 Ver.1.2 [��QT1_1261] SCS K.Yamaguchi ADD END
        , last_updated_by            = cn_last_updated_by
        , last_update_date           = SYSDATE
        , last_update_login          = cn_last_update_login
        , request_id                 = cn_request_id
        , program_application_id     = cn_program_application_id
        , program_id                 = cn_program_id
        , program_update_date        = SYSDATE
      WHERE xbb.bm_balance_id = l_lock_xbb_tab(i)
      ;
    END IF;
    gn_target_cnt := l_lock_xbb_tab.COUNT;
    gn_normal_cnt := gn_target_cnt;
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
  END update_xbb;
--
  /**********************************************************************************
   * Procedure Name   : delete_xrbpr
   * Description      : ���[�N�e�[�u���f�[�^�폜(A-5)
   ***********************************************************************************/
  PROCEDURE delete_xrbpr(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'delete_xrbpr';     -- �v���O������
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
      FROM xxcok_rep_bm_pg_receipt xrbpr
      WHERE xrbpr.request_id = cn_request_id
      FOR UPDATE OF xrbpr.payment_code NOWAIT
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
    FROM xxcok_rep_bm_pg_receipt   xrbpr
    WHERE xrbpr.request_id = cn_request_id
    ;
    --==================================================
    -- ���������擾
    --==================================================
    gn_target_cnt := SQL%ROWCOUNT;
    gn_normal_cnt := gn_target_cnt;
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
  END delete_xrbpr;
--
  /**********************************************************************************
   * Procedure Name   : start_svf
   * Description      : SVF�N��(A-4)
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
   * Procedure Name   : insert_xrbpr
   * Description      : �f�[�^�擾(A-2)�E���[�N�e�[�u���f�[�^�o�^(A-3)
   ***********************************************************************************/
  PROCEDURE insert_xrbpr(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'insert_xrbpr';     -- �v���O������
    cv_n                           CONSTANT VARCHAR2(1)  := 'N';
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
    -- ���[�N�e�[�u���f�[�^�o�^
    --==================================================
    INSERT INTO xxcok_rep_bm_pg_receipt(
      payment_code                      -- �x����R�[�h
    , publication_date                  -- ���s��
    , payment_zip_code                  -- �x����X�֔ԍ�
    , payment_addr_1                    -- �x����Z��1
    , payment_addr_2                    -- �x����Z��2
    , payment_name_1                    -- �x���戶��1
    , payment_name_2                    -- �x���戶��2
    , contact_base_section_code         -- �n��R�[�h�i�A���拒�_�j
    , contact_base_code                 -- �A���拒�_�R�[�h
    , contact_base_name                 -- �A���拒�_��
    , contact_addr_1                    -- �A����Z��1
    , contact_addr_2                    -- �A����Z��2
    , contact_phone_no                  -- �A����d�b�ԍ�
    , target_month                      -- �N����
    , closing_date                      -- ���ߓ�
    , selling_amt_sum                   -- �̔����z���v
    , bm_index_1                        -- ���v���o��1
    , bm_amt_1                          -- ���v�萔��1
    , bm_index_2                        -- ���v���o��2
    , bm_amt_2                          -- ���v�萔��2
    , payment_amt_tax                   -- �x�����z�i�ō��j
    , created_by                        -- �쐬��
    , creation_date                     -- �쐬��
    , last_updated_by                   -- �ŏI�X�V��
    , last_update_date                  -- �ŏI�X�V��
    , last_update_login                 -- �ŏI�X�V���O�C��
    , request_id                        -- �v��ID
    , program_application_id            -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
    , program_id                        -- �R���J�����g�E�v���O����ID
    , program_update_date               -- �v���O�����X�V��
    )
    SELECT payment_code                 AS payment_code
         , TO_CHAR( gd_process_date
                  , cv_format_date  )   AS publication_date
         , payment_zip_code             AS payment_zip_code
         , payment_addr_1               AS payment_addr_1
         , payment_addr_2               AS payment_addr_2
         , payment_name_1               AS payment_name_1
         , payment_name_2               AS payment_name_2
         , contact_base_section_code    AS contact_base_section_code
         , contact_base_code            AS contact_base_code
         , contact_base_name            AS contact_base_name
         , contact_addr_1               AS contact_addr_1
         , contact_addr_2               AS contact_addr_2
         , contact_phone_no             AS contact_phone_no
         , TO_CHAR( closing_date
                  , cv_format_ee_month
                  , cv_nls_param )      AS target_month
         , closing_date                 AS closing_date
         , selling_amt_sum              AS selling_amt_sum
         , CASE
           WHEN backmargin > 0 THEN
             gv_prompt_bm
           ELSE
             gv_prompt_ep
           END                          AS bm_index_1
         , CASE
           WHEN backmargin > 0 THEN
             backmargin
           ELSE
             electric_amt
           END                          AS bm_amt_1
         , CASE
           WHEN backmargin   > 0
            AND electric_amt > 0 THEN
             gv_prompt_ep
           END                          AS bm_index_2
         , CASE
           WHEN backmargin   > 0
            AND electric_amt > 0 THEN
             electric_amt
           END                          AS bm_amt_2
         , payment_amt_tax              AS payment_amt_tax
         , cn_created_by                AS created_by
         , SYSDATE                      AS creation_date
         , cn_last_updated_by           AS last_updated_by
         , SYSDATE                      AS last_update_date
         , cn_last_update_login         AS last_update_login
         , cn_request_id                AS request_id
         , cn_program_application_id    AS program_application_id
         , cn_program_id                AS program_id
         , SYSDATE                      AS program_update_date
    FROM ( SELECT xbb.supplier_code                                   AS payment_code
-- 2009/10/14 Ver.1.4 [�ύX�˗�I_E_573] SCS S.Moriyama UPD START
---- 2009/09/10 Ver.1.3 [��Q0000060] SCS S.Moriyama UPD START
----                , pvsa.zip                                            AS payment_zip_code
----                , pvsa.state || pvsa.city || pvsa.address_line1       AS payment_addr_1
----                , pvsa.address_line2                                  AS payment_addr_2
----                , SUBSTR( pv.vendor_name,  1, 15 )                    AS payment_name_1
----                , SUBSTR( pv.vendor_name, 16     )                    AS payment_name_2
--                , SUBSTRB( pvsa.zip , 1 , 8 )                         AS payment_zip_code
--                , SUBSTR( pvsa.city  || pvsa.address_line1
--                                     || pvsa.address_line2 , 1 , 20 ) AS payment_addr_1
--                , SUBSTR( pvsa.city  || pvsa.address_line1
--                                     || pvsa.address_line2 , 21, 20 ) AS payment_addr_2
--                , SUBSTR( pv.vendor_name,  1, 20 )                    AS payment_name_1
--                , SUBSTR( pv.vendor_name, 21, 20 )                    AS payment_name_2
---- 2009/09/10 Ver.1.3 [��Q0000060] SCS S.Moriyama UPD END
--                , hca.base_area_code                                  AS contact_base_section_code
--                , hca.base_code                                       AS contact_base_code
---- 2009/09/10 Ver.1.3 [��Q0000060] SCS S.Moriyama UPD START
----                , hca.base_name                                       AS contact_base_name
----                , hca.base_address1                                   AS contact_addr_1
----                , hca.base_address2                                   AS contact_addr_2
----                , hca.base_phone_num                                  AS contact_phone_no
--                , SUBSTR( hca.base_name , 1 , 20 )                    AS contact_base_name
--                , SUBSTR( hca.base_address1 , 1 , 20 )                AS contact_addr_1
--                , SUBSTR( hca.base_address1 , 21, 20 )                AS contact_addr_2
--                , SUBSTRB( hca.base_phone_num , 1 ,15 )               AS contact_phone_no
---- 2009/09/10 Ver.1.3 [��Q0000060] SCS S.Moriyama UPD END
--                , MAX( xbb.closing_date )                             AS closing_date
--                , SUM( xbb.selling_amt_tax )                          AS selling_amt_sum
--                , SUM(   NVL( xbb.backmargin    , 0 )
--                       + NVL( xbb.backmargin_tax, 0 )
--                  )                                                   AS backmargin
--                , SUM(   NVL( xbb.electric_amt    , 0 )
--                       + NVL( xbb.electric_amt_tax, 0 )
--                  )                                                   AS electric_amt
--                , SUM( xbb.expect_payment_amt_tax )                   AS payment_amt_tax
--           FROM xxcok_backmargin_balance     xbb  -- �̎�c���e�[�u��
--              , po_vendors                   pv   -- �d����}�X�^
--              , po_vendor_sites_all          pvsa -- �d����T�C�g�}�X�^
--              , ( SELECT hca.account_number            AS base_code
--                       , hp.party_name                 AS base_name
--                       , hl.address3                   AS base_area_code
---- 2009/09/10 Ver.1.3 [��Q0000060] SCS S.Moriyama UPD START
----                       ,    hl.state
----                         || hl.city
----                         || hl.address1                AS base_address1
----                       , hl.address2                   AS base_address2
--                       ,    hl.city
--                         || hl.address1
--                         || hl.address2                  AS base_address1
---- 2009/09/10 Ver.1.3 [��Q0000060] SCS S.Moriyama UPD END
--                       , hl.address_lines_phonetic     AS base_phone_num
--                  FROM hz_cust_accounts           hca       -- �ڋq�}�X�^
--                     , hz_cust_acct_sites_all     hcasa     -- �ڋq���ݒn�}�X�^
--                     , hz_parties                 hp        -- �p�[�e�B�}�X�^
--                     , hz_party_sites             hps       -- �p�[�e�B�T�C�g�}�X�^
--                     , hz_locations               hl        -- �ڋq���Ə��}�X�^
--                  WHERE hca.cust_account_id  = hcasa.cust_account_id
--                    AND hca.party_id         = hp.party_id
--                    AND hcasa.party_site_id  = hps.party_site_id
--                    AND hps.location_id      = hl.location_id
--                    AND hcasa.org_id        = gn_org_id
--                )                            hca
--           WHERE xbb.base_code                    = hca.base_code
--             AND xbb.supplier_code                = pv.segment1
--             AND pv.vendor_id                     = pvsa.vendor_id
--             AND pvsa.org_id                      = gn_org_id
--             AND pvsa.attribute4                  = cv_bm_type_4
--             AND xbb.expect_payment_amt_tax       > 0
--             AND xbb.payment_amt_tax              = 0
--             AND xbb.resv_flag                   IS NULL
--             AND xbb.publication_date            IS NULL
--             AND pvsa.hold_all_payments_flag      = cv_n
--             AND xbb.base_code                    = gv_param_base_code
--             AND xbb.supplier_code                = NVL( gv_param_vendor_code, xbb.supplier_code )
--             AND ( pvsa.inactive_date             < gd_process_date OR pvsa.inactive_date IS NULL )
--           GROUP BY xbb.supplier_code
--                  , pvsa.zip
---- 2009/09/10 Ver.1.3 [��Q0000060] SCS S.Moriyama UPD START
----                  , pvsa.state || pvsa.city || pvsa.address_line1
----                  , pvsa.address_line2
----                  , SUBSTR( pv.vendor_name,  1, 15 )
----                  , SUBSTR( pv.vendor_name, 16     )
--                  , pvsa.city || pvsa.address_line1 || pvsa.address_line2
--                  , SUBSTR( pv.vendor_name,  1, 20 )
--                  , SUBSTR( pv.vendor_name, 21, 20 )
---- 2009/09/10 Ver.1.3 [��Q0000060] SCS S.Moriyama UPD END
--                  , hca.base_code
--                  , hca.base_name
--                  , hca.base_area_code
--                  , hca.base_address1
---- 2009/09/10 Ver.1.3 [��Q0000060] SCS S.Moriyama DEL START
----                  , hca.base_address2
---- 2009/09/10 Ver.1.3 [��Q0000060] SCS S.Moriyama DEL END
--                  , hca.base_phone_num
--         )
                , SUBSTRB( pvsa.zip , 1 , 8 )                         AS payment_zip_code
                , SUBSTR( pvsa.address_line1
                          || pvsa.address_line2 , 1 , 20 )            AS payment_addr_1
                , SUBSTR( pvsa.address_line1
                          || pvsa.address_line2 , 21, 20 )            AS payment_addr_2
                , SUBSTR( pvsa.attribute1,  1, 20 )                   AS payment_name_1
                , SUBSTR( pvsa.attribute1, 21, 20 )                   AS payment_name_2
                , hca.base_area_code                                  AS contact_base_section_code
                , hca.base_code                                       AS contact_base_code
                , SUBSTR( hca.base_name , 1 , 20 )                    AS contact_base_name
                , SUBSTR( hca.base_address1 , 1 , 20 )                AS contact_addr_1
                , SUBSTR( hca.base_address1 , 21, 20 )                AS contact_addr_2
                , SUBSTRB( hca.base_phone_num , 1 ,15 )               AS contact_phone_no
                , MAX( xbb.closing_date )                             AS closing_date
                , SUM( xbb.selling_amt_tax )                          AS selling_amt_sum
                , SUM(   NVL( xbb.backmargin    , 0 )
                       + NVL( xbb.backmargin_tax, 0 )
                  )                                                   AS backmargin
                , SUM(   NVL( xbb.electric_amt    , 0 )
                       + NVL( xbb.electric_amt_tax, 0 )
                  )                                                   AS electric_amt
                , SUM( xbb.expect_payment_amt_tax )                   AS payment_amt_tax
           FROM xxcok_backmargin_balance     xbb  -- �̎�c���e�[�u��
              , po_vendors                   pv   -- �d����}�X�^
              , po_vendor_sites_all          pvsa -- �d����T�C�g�}�X�^
              , ( SELECT hca.account_number            AS base_code
                       , hp.party_name                 AS base_name
                       , hl.address3                   AS base_area_code
                       ,    hl.city
                         || hl.address1
                         || hl.address2                AS base_address1
                       , hl.address_lines_phonetic     AS base_phone_num
                  FROM hz_cust_accounts           hca       -- �ڋq�}�X�^
                     , hz_cust_acct_sites_all     hcasa     -- �ڋq���ݒn�}�X�^
                     , hz_parties                 hp        -- �p�[�e�B�}�X�^
                     , hz_party_sites             hps       -- �p�[�e�B�T�C�g�}�X�^
                     , hz_locations               hl        -- �ڋq���Ə��}�X�^
                  WHERE hca.cust_account_id  = hcasa.cust_account_id
                    AND hca.party_id         = hp.party_id
                    AND hcasa.party_site_id  = hps.party_site_id
                    AND hps.location_id      = hl.location_id
                    AND hcasa.org_id        = gn_org_id
                )                            hca
           WHERE xbb.base_code                    = hca.base_code
             AND xbb.supplier_code                = pv.segment1
             AND pv.vendor_id                     = pvsa.vendor_id
             AND pvsa.org_id                      = gn_org_id
             AND pvsa.attribute4                  = cv_bm_type_4
             AND xbb.expect_payment_amt_tax       > 0
             AND xbb.payment_amt_tax              = 0
             AND xbb.resv_flag                   IS NULL
             AND xbb.publication_date            IS NULL
             AND pvsa.hold_all_payments_flag      = cv_n
             AND xbb.base_code                    = gv_param_base_code
             AND xbb.supplier_code                = NVL( gv_param_vendor_code, xbb.supplier_code )
             AND ( pvsa.inactive_date             < gd_process_date OR pvsa.inactive_date IS NULL )
           GROUP BY xbb.supplier_code
                  , pvsa.zip
                  , pvsa.address_line1 || pvsa.address_line2
                  , SUBSTR( pvsa.attribute1,  1, 20 )
                  , SUBSTR( pvsa.attribute1, 21, 20 )
                  , hca.base_code
                  , hca.base_name
                  , hca.base_area_code
                  , hca.base_address1
                  , hca.base_phone_num
         )
-- 2009/10/14 Ver.1.4 [�ύX�˗�I_E_573] SCS S.Moriyama UPD END
    ;
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
  END insert_xrbpr;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  , iv_base_code                   IN  VARCHAR2        -- ����v�㋒�_
  , iv_fix_flag                    IN  VARCHAR2        -- �x���m��
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
    -- ����v�㋒�_
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application          => cv_appl_short_name_cok
                  , iv_name                 => cv_msg_cok_00074
                  , iv_token_name1          => cv_tkn_selling_base_code
                  , iv_token_value1         => iv_base_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                => FND_FILE.LOG
                  , iv_message              => lv_outmsg
                  , in_new_line             => 0
                  );
    -- �x���m��
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application          => cv_appl_short_name_cok
                  , iv_name                 => cv_msg_cok_00088
                  , iv_token_name1          => cv_tkn_fix_flag
                  , iv_token_value1         => iv_fix_flag
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
    gv_param_fix_flag    := iv_fix_flag;
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
  , iv_base_code                   IN  VARCHAR2        -- ����v�㋒�_
  , iv_fix_flag                    IN  VARCHAR2        -- �x���m��
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
    , iv_base_code            => iv_base_code          -- ����v�㋒�_
    , iv_fix_flag             => iv_fix_flag           -- �x���m��
    , iv_vendor_code          => iv_vendor_code        -- �x����
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --==================================================
    -- �x���m��FNo
    --==================================================
    IF( gv_param_fix_flag = cv_param_fix_flag_n ) THEN
      --==================================================
      -- �f�[�^�擾(A-2)�E���[�N�e�[�u���f�[�^�o�^(A-3)
      --==================================================
      insert_xrbpr(
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
      -- SVF�N��(A-4)
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
      -- ���[�N�e�[�u���f�[�^�폜(A-5)
      --==================================================
      delete_xrbpr(
        ov_errbuf               => lv_errbuf                -- �G���[�E���b�Z�[�W
      , ov_retcode              => lv_retcode               -- ���^�[���E�R�[�h
      , ov_errmsg               => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      IF( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    --==================================================
    -- �x���m��FYes
    --==================================================
    ELSIF( gv_param_fix_flag = cv_param_fix_flag_y ) THEN
      --==================================================
      -- �̎�c�����X�V(A-6)
      --==================================================
      update_xbb(
        ov_errbuf               => lv_errbuf                -- �G���[�E���b�Z�[�W
      , ov_retcode              => lv_retcode               -- ���^�[���E�R�[�h
      , ov_errmsg               => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      IF( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      ELSIF( lv_retcode = cv_status_warn ) THEN
        lv_end_retcode := cv_status_warn;
      END IF;
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
  , iv_base_code                   IN  VARCHAR2        -- ����v�㋒�_
  , iv_fix_flag                    IN  VARCHAR2        -- �x���m��
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
    , iv_base_code            => iv_base_code          -- ����v�㋒�_
    , iv_fix_flag             => iv_fix_flag           -- �x���m��
    , iv_vendor_code          => iv_vendor_code        -- �x����
    );
    --==================================================
    -- �G���[�o��
    --==================================================
    IF( lv_retcode <> cv_status_normal ) THEN
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
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_msg_ccp_90005;
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
END XXCOK015A02R;
/
