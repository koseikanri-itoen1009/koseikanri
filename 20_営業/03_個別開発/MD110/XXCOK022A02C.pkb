CREATE OR REPLACE PACKAGE BODY XXCOK022A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK022A02C(body)
 * Description      : �c�ƃV�X�e���\�z�v���W�F�N�g
 * MD.050           : �A�h�I���F�̎�̋��\�Z�f�[�^�t�@�C���쐬 �̔����� MD050_COK_022_A02
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  get_target_account_p   �����Ώۉ�v�N�x�擾(A-2)
 *  open_file_p            �t�@�C���I�[�v��(A-3)
 *  get_budget_info_p      �A�g�Ώ۔̎�̋��\�Z���擾(A-4)
 *  create_flat_file_p     �t���b�g�t�@�C���쐬(A-5)/�A�g�σf�[�^�X�e�[�^�X�X�V(A-6)
 *  close_file_p           �t�@�C���N���[�Y(A-7)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/20    1.0   K.Suenaga        �V�K�쐬
 *  2009/02/05    1.1   K.Suenaga        [��QCOK_010]�f�B���N�g���p�X�̏o�͕��@��ύX
 *
 *****************************************************************************************/
  -- ===============================
  -- �O���[�o���萔
  -- ===============================
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn            CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_warn;   --�x��:1
  cv_status_error           CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_error;  --�ُ�:2
  --WHO�J����
  cn_created_by             CONSTANT NUMBER       := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE         := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER       := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE         := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER       := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER       := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER       := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER       := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE         := SYSDATE;                    --PROGRAM_UPDATE_DATE  
  --�L��
  cv_msg_double             CONSTANT VARCHAR2(1)    := '"';                          -- �_�u���R�[�e�[�V����
  cv_msg_comma              CONSTANT VARCHAR2(1)    := ',';                          -- �J���}
  cv_slash                  CONSTANT VARCHAR2(1)    := '/';                          -- �X���b�V��
  cv_msg_part               CONSTANT VARCHAR2(3)    := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3)    := '.';
  --�p�b�P�[�W��
  cv_pkg_name               CONSTANT VARCHAR2(100)  := 'XXCOK022A02C';               -- �p�b�P�[�W��
  --�A�v���P�[�V�����Z�k��
  cv_appli_xxccp_name       CONSTANT VARCHAR2(10)   := 'XXCCP';                      -- �A�v���P�[�V�����Z�k��
  cv_appli_xxcok_name       CONSTANT VARCHAR2(10)   := 'XXCOK';                      -- �A�v���P�[�V�����Z�k��
  cv_appli_sqlgl_name       CONSTANT VARCHAR2(10)   := 'SQLGL';                      -- �A�v���P�[�V�����Z�k��
  --���b�Z�[�W
  cv_concurrent_msg         CONSTANT VARCHAR2(100)  := 'APP-XXCCP1-90008';           -- �R���J�����g���̓p�����[�^�Ȃ�
  cv_profile_msg            CONSTANT VARCHAR2(100)  := 'APP-XXCOK1-00003';           -- �v���t�@�C���擾�G���[
  cv_dire_name_msg          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-00067';           -- �f�B���N�g�������b�Z�[�W�o��
  cv_file_name_msg          CONSTANT VARCHAR2(100)  := 'APP-XXCOK1-00006';           -- �t�@�C�������b�Z�[�W�o��
  cv_close_status_msg       CONSTANT VARCHAR2(100)  := 'APP-XXCOK1-00057';           -- �I�[�v����v���Ԏ擾�G���[
  cv_effective_msg          CONSTANT VARCHAR2(100)  := 'APP-XXCOK1-00059';           -- �L����v���Ԏ擾�G���[
  cv_file_err_msg           CONSTANT VARCHAR2(100)  := 'APP-XXCOK1-00009';           -- �t�@�C�����݃`�F�b�N�G���[
  cv_lock_err_msg           CONSTANT VARCHAR2(100)  := 'APP-XXCOK1-10178';           -- ���b�N�G���[���b�Z�[�W
  cv_status_err_msg         CONSTANT VARCHAR2(100)  := 'APP-XXCOK1-10180';           -- �A�g�σf�[�^�X�e�[�^�X�X�V�G���[
  cv_target_rec_msg         CONSTANT VARCHAR2(100)  := 'APP-XXCCP1-90000';           -- �Ώی������b�Z�[�W
  cv_success_rec_msg        CONSTANT VARCHAR2(100)  := 'APP-XXCCP1-90001';           -- �����������b�Z�[�W
  cv_error_rec_msg          CONSTANT VARCHAR2(100)  := 'APP-XXCCP1-90002';           -- �G���[�������b�Z�[�W
  cv_normal_msg             CONSTANT VARCHAR2(100)  := 'APP-XXCCP1-90004';           -- ����I�����b�Z�[�W
  cv_error_msg              CONSTANT VARCHAR2(100)  := 'APP-XXCCP1-90006';           -- �G���[�I���S���[���o�b�N
  --�g�[�N��
  cv_company_token          CONSTANT VARCHAR2(100)  := 'COMPANY_CODE';               -- ��ЃR�[�h
  cv_budget_token           CONSTANT VARCHAR2(100)  := 'BUDGET_YEAR';                -- �\�Z�N�x
  cv_location_token         CONSTANT VARCHAR2(100)  := 'LOCATION_CODE';              -- ���_�R�[�h
  cv_corporate_token        CONSTANT VARCHAR2(100)  := 'CORPORATE_CODE';             -- ��ƃR�[�h
  cv_store_token            CONSTANT VARCHAR2(100)  := 'STORE_CODE';                 -- �≮������R�[�h
  cv_account_token          CONSTANT VARCHAR2(100)  := 'ACCOUNT_CODE';               -- ����ȖڃR�[�h
  cv_sub_token              CONSTANT VARCHAR2(100)  := 'SUB_CODE';                   -- �⏕�ȖڃR�[�h
  cv_profile_token          CONSTANT VARCHAR2(100)  := 'PROFILE';                    -- �v���t�@�C����
  cv_dire_name_token        CONSTANT VARCHAR2(15)   := 'DIRECTORY';                  -- �f�B���N�g����
  cv_file_token             CONSTANT VARCHAR2(100)  := 'FILE_NAME';                  -- �t�@�C����
  cv_cnt_token              CONSTANT VARCHAR2(10)   := 'COUNT';                      -- �������b�Z�[�W�p�g�[�N����
  --�v���t�@�C��
  cv_set_of_bks_id          CONSTANT VARCHAR2(100)  := 'GL_SET_OF_BKS_ID';           -- ��v����ID
  cv_bm_dire_path           CONSTANT VARCHAR2(100)  := 'XXCOK1_BM_BUDGET_DIRE_PATH'; -- �̎�̋��\�Z�f�B���N�g���p�X
  cv_bm_file_name           CONSTANT VARCHAR2(100)  := 'XXCOK1_BM_BUDGET_FILE_NAME'; -- �̎�̋��\�Z�t�@�C����
  --�t���O
  cv_adjustment_flag        CONSTANT VARCHAR2(1)    := 'N';                          -- �����t���O
  --�X�e�[�^�X
  cv_open_status            CONSTANT VARCHAR2(1)    := 'O';                          -- �X�e�[�^�X
  cv_unsettled_status       CONSTANT VARCHAR2(1)    := '0';                          -- �X�e�[�^�X(���n�A�g����)
  cv_settled_status         CONSTANT VARCHAR2(1)    := '1';                          -- �X�e�[�^�X(���n�A�g��)
--
  cv_open_mode              CONSTANT VARCHAR2(1)    := 'w';
  cn_max_linesize           CONSTANT BINARY_INTEGER := 32767;
  -- ===============================
  -- �O���[�o���ϐ�
  -- ===============================
  gn_target_cnt           NUMBER             DEFAULT NULL;   -- �Ώی���
  gn_normal_cnt           NUMBER             DEFAULT NULL;   -- ���팏��
  gn_error_cnt            NUMBER             DEFAULT NULL;   -- �G���[����
  gn_warn_cnt             NUMBER             DEFAULT NULL;   -- �X�L�b�v����
  gv_set_of_bks_id        VARCHAR2(100)      DEFAULT NULL;   -- ��v����ID�ϐ�
  gv_bm_dire_path         VARCHAR2(100)      DEFAULT NULL;   -- �̎�̋��f�B���N�g���p�X�ϐ�
  gv_bm_file_name         VARCHAR2(100)      DEFAULT NULL;   -- �̎�̋��t�@�C�����ϐ�
  gn_account_year         NUMBER             DEFAULT NULL;   -- �I�[�v����v�N���ϐ�
  gn_target_account_year  NUMBER             DEFAULT NULL;   -- �����Ώۉ�v�N�x�ϐ�
  g_open_file             UTL_FILE.FILE_TYPE DEFAULT NULL;   -- �I�[�v���t�@�C���n���h���̕ϐ�
  gd_system_date          DATE               DEFAULT NULL;   -- �V�X�e�����t�̕ϐ�
  -- ===============================
  -- �O���[�o���J�[�\��
  -- ===============================
  CURSOR g_bm_support_budget_cur
  IS
    SELECT xbsb.bm_support_budget_id AS bm_support_budget_id -- �̎�̋��\�ZID
         , xbsb.company_code         AS company_code         -- ��ЃR�[�h
         , xbsb.budget_year          AS budget_year          -- �\�Z�N�x
         , xbsb.base_code            AS base_code            -- ���_�R�[�h
         , xbsb.corp_code            AS corp_code            -- ��ƃR�[�h
         , xbsb.sales_outlets_code   AS sales_outlets_code   -- �≮������R�[�h
         , xbsb.acct_code            AS acct_code            -- ����ȖڃR�[�h
         , xbsb.sub_acct_code        AS sub_acct_code        -- �⏕�ȖڃR�[�h
         , xbsb.target_month         AS target_month         -- ���x
         , xbsb.budget_amt           AS budget_amt           -- �\�Z���z
    FROM   xxcok_bm_support_budget      xbsb                 -- �̎�̋��\�Z�e�[�u��
    WHERE  xbsb.budget_year           = gn_target_account_year
    AND    xbsb.info_interface_status = cv_unsettled_status;
--
  TYPE g_bm_support_budget_ttype IS TABLE OF g_bm_support_budget_cur%ROWTYPE;
  g_bm_support_budget_tab g_bm_support_budget_ttype;
  -- ===============================
  -- �O���[�o����O
  -- ===============================
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION;
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
--
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
  )
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf        VARCHAR2(5000) DEFAULT NULL;   -- �G���[�E���b�Z�[�W
    lv_retcode       VARCHAR2(1)    DEFAULT NULL;   -- ���^�[���E�R�[�h
    lv_errmsg        VARCHAR2(5000) DEFAULT NULL;   -- ���[�U�[�E�G���[�E���b�Z�[�W
    lb_retcode       BOOLEAN        DEFAULT NULL;   -- ���b�Z�[�W�o�͊֐��̖߂�l
    lv_out_msg       VARCHAR2(5000) DEFAULT NULL;   -- ���b�Z�[�W�o�͕ϐ�
    lv_profile       VARCHAR2(100)  DEFAULT NULL;   -- �v���t�@�C���i�[�ϐ�
    -- ===============================
    -- ���[�J����O
    -- ===============================
    profile_expt     EXCEPTION;                     -- �v���t�@�C���擾�G���[
--
  BEGIN
    ov_retcode := cv_status_normal;
    --==============================================================
    --�R���J�����g���̓p�����[�^�Ȃ����ڂ����b�Z�[�W�o��
    --==============================================================
    lv_out_msg := xxccp_common_pkg.get_msg(
                    cv_appli_xxccp_name
                  , cv_concurrent_msg
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
    --�v���t�@�C�����擾
    --==============================================================
    gv_set_of_bks_id := FND_PROFILE.VALUE( cv_set_of_bks_id ); -- ��v����ID
    gv_bm_dire_path  := FND_PROFILE.VALUE( cv_bm_dire_path  ); -- �̎�̋��f�B���N�g���p�X
    gv_bm_file_name  := FND_PROFILE.VALUE( cv_bm_file_name  ); -- �̎�̋��t�@�C����
--
    IF( gv_set_of_bks_id IS NULL ) THEN
      lv_profile := cv_set_of_bks_id;
      RAISE profile_expt;
    END IF;
--
    IF( gv_bm_dire_path IS NULL ) THEN
      lv_profile := cv_bm_dire_path;
      RAISE profile_expt;
    END IF;
--
    IF( gv_bm_file_name IS NULL ) THEN
      lv_profile := cv_bm_file_name;
      RAISE profile_expt;
    END IF;
    --===============================================================
    --�f�B���N�g�����E�t�@�C���������b�Z�[�W�o��
    --===============================================================
    lv_out_msg   := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_dire_name_msg
                    , cv_dire_name_token
                    , xxcok_common_pkg.get_directory_path_f( gv_bm_dire_path )
                    );
    lb_retcode   := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- �o�͋敪
                    , lv_out_msg         -- ���b�Z�[�W
                    , 0                  -- ���s
                    );
    lv_out_msg   := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_file_name_msg
                    , cv_file_token
                    , gv_bm_file_name
                    );
    lb_retcode   := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- �o�͋敪
                    , lv_out_msg         -- ���b�Z�[�W
                    , 1                  -- ���s
                    );
--
  EXCEPTION
    -- *** �v���t�@�C���擾�G���[ ***
    WHEN profile_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_profile_msg
                    , cv_profile_token
                    , lv_profile
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
   * Procedure Name   : get_target_account_p
   * Description      : �����Ώۉ�v�N�x�擾(A-2)
   ***********************************************************************************/
  PROCEDURE get_target_account_p(
    ov_errbuf  OUT VARCHAR2                                            -- �G���[�E���b�Z�[�W
  , ov_retcode OUT VARCHAR2                                            -- ���^�[���E�R�[�h
  , ov_errmsg  OUT VARCHAR2                                            -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_target_account_p'; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL;                            -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1)    DEFAULT NULL;                            -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL;                            -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg VARCHAR2(5000) DEFAULT NULL;                            -- ���b�Z�[�W�o�͕ϐ�
    lb_retcode BOOLEAN        DEFAULT NULL;                            -- ���b�Z�[�W�o�͊֐��̖߂�l
    -- ===============================
    -- ���[�J����O
    -- ===============================
    close_status_expt EXCEPTION;                                       -- �I�[�v����v�N�x�擾�G���[
    effective_expt    EXCEPTION;                                       -- �L����v���Ԏ擾�G���[
--
  BEGIN
    ov_retcode := cv_status_normal;
    --==============================================================
    --��v�N�����擾
    --==============================================================
    SELECT COUNT(*)
    INTO   gn_account_year
    FROM(
      SELECT   gps.period_year                                   -- �I�[�v����v�N��
      FROM     gl_period_statuses           gps
             , fnd_application              fa
      WHERE    gps.application_id         = fa.application_id
      AND      gps.set_of_books_id        = gv_set_of_bks_id
      AND      fa.application_short_name  = cv_appli_sqlgl_name
      AND      gps.adjustment_period_flag = cv_adjustment_flag
      AND      gps.closing_status         = cv_open_status
      GROUP BY gps.period_year
    );
    --==============================================================
    --��v�N����1�̏ꍇ�A�I�[�v�����Ă����v�N�x�̗��N�������ΏۂƂ���
    --==============================================================
    IF( gn_account_year = 1 ) THEN
      SELECT   gps.period_year + 1                               -- �����Ώۉ�v�N�x
      INTO     gn_target_account_year
      FROM     gl_period_statuses           gps
             , fnd_application              fa
      WHERE    gps.application_id         = fa.application_id
      AND      gps.set_of_books_id        = gv_set_of_bks_id
      AND      fa.application_short_name  = cv_appli_sqlgl_name
      AND      gps.adjustment_period_flag = cv_adjustment_flag
      AND      gps.closing_status         = cv_open_status
      GROUP BY gps.period_year;
    --==============================================================
    --��v�N����2�̏ꍇ�A�傫�����̔N�x�������ΏۂƂ���
    --==============================================================
    ELSIF( gn_account_year = 2 ) THEN
      SELECT MAX( period_year )
      INTO   gn_target_account_year
      FROM( 
        SELECT   gps.period_year                                 -- �����Ώۉ�v�N�x
        FROM     gl_period_statuses           gps
               , fnd_application              fa
        WHERE    gps.application_id         = fa.application_id
        AND      gps.set_of_books_id        = gv_set_of_bks_id
        AND      fa.application_short_name  = cv_appli_sqlgl_name
        AND      gps.adjustment_period_flag = cv_adjustment_flag
        AND      gps.closing_status         = cv_open_status
        GROUP BY gps.period_year
      );
    --==============================================================
    --��v���Ԃ̃X�e�[�^�X���I�[�v�����Ă��Ȃ����A�G���[�Ƃ��ď���
    --==============================================================
    ELSIF( gn_account_year = 0 ) THEN
      RAISE close_status_expt;
    --==============================================================
    --��v�N������L�ȊO�̏ꍇ�A�G���[�Ƃ��ď���
    --==============================================================
    ELSE
      RAISE effective_expt;
    END IF;
--
  EXCEPTION
    -- *** �I�[�v����v���Ԏ擾�G���[ ***
    WHEN close_status_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_close_status_msg
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- �o�͋敪
                    , lv_out_msg         -- ���b�Z�[�W
                    , 0                  -- ���s
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** �L����v���Ԏ擾�G���[ ***
    WHEN effective_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_effective_msg
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
  END get_target_account_p;
--
  /**********************************************************************************
   * Procedure Name   : open_file_p
   * Description      : �t�@�C���I�[�v��(A-3)
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
    lv_out_msg     VARCHAR2(5000) DEFAULT NULL;            -- ���b�Z�[�W�o�͕ϐ�
    lb_retcode     BOOLEAN        DEFAULT NULL;            -- ���b�Z�[�W�o�͊֐��̖߂�l
    lb_fexists     BOOLEAN        DEFAULT NULL;            -- BOOLEAN�̕ϐ�
    ln_file_length NUMBER         DEFAULT NULL;            -- �t�@�C���̒����ϐ�
    ln_block_size  NUMBER         DEFAULT NULL;            -- �u���b�N�T�C�Y�ϐ�
    -- ===============================
    -- ���[�J����O
    -- ===============================
    file_expt      EXCEPTION;                              -- �t�@�C�����݃`�F�b�N�G���[
--
  BEGIN
    ov_retcode := cv_status_normal;
    --=============================================================
    --�t�@�C���̑��݃`�F�b�N
    --=============================================================
    UTL_FILE.FGETATTR(
      location    =>  gv_bm_dire_path                      -- �f�B���N�g���p�X
    , filename    =>  gv_bm_file_name                      -- �t�@�C����
    , fexists     =>  lb_fexists                           -- �t�@�C���̑���
    , file_length =>  ln_file_length                       -- �t�@�C���̒���
    , block_size  =>  ln_block_size                        -- �u���b�N�T�C�Y
    );
--
    IF( lb_fexists = TRUE ) THEN
    -- *** �t�@�C�����݃`�F�b�N�G���[ ***
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_file_err_msg
                    , cv_file_token
                    , gv_bm_file_name
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
                     gv_bm_dire_path                       -- �f�B���N�g���p�X
                   , gv_bm_file_name                       -- �t�@�C����
                   , cv_open_mode                          -- ���[�h
                   , cn_max_linesize                       -- �ő啶����
                   );
--
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf ,1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END open_file_p;
--
  /**********************************************************************************
   * Procedure Name   : get_budget_info_p
   * Description      : �A�g�Ώ۔̎�̋��\�Z���擾(A-4)
   ***********************************************************************************/
  PROCEDURE get_budget_info_p(
    ov_errbuf  OUT VARCHAR2                                      -- �G���[�E���b�Z�[�W
  , ov_retcode OUT VARCHAR2                                      -- ���^�[���E�R�[�h
  , ov_errmsg  OUT VARCHAR2                                      -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_budget_info_p'; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL;                      -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1)    DEFAULT NULL;                      -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL;                      -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg VARCHAR2(5000) DEFAULT NULL;                      -- ���b�Z�[�W�o�͕ϐ�
    lb_retcode BOOLEAN        DEFAULT NULL;                      -- ���b�Z�[�W�o�͊֐��̖߂�l
--
  BEGIN
    ov_retcode := cv_status_normal;
--
    OPEN  g_bm_support_budget_cur;
    FETCH g_bm_support_budget_cur BULK COLLECT INTO g_bm_support_budget_tab;
    CLOSE g_bm_support_budget_cur;
    --==============================================================
    --�Ώی����J�E���g
    --==============================================================
    gn_target_cnt := g_bm_support_budget_tab.COUNT;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END get_budget_info_p;
--
  /**********************************************************************************
   * Procedure Name   : create_flat_file_p
   * Description      : �t���b�g�t�@�C���쐬(A-5)/�A�g�σf�[�^�X�e�[�^�X�X�V(A-6)
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
    lv_errbuf             VARCHAR2(5000) DEFAULT NULL;            -- �G���[�E���b�Z�[�W
    lv_retcode            VARCHAR2(1)    DEFAULT NULL;            -- ���^�[���E�R�[�h
    lv_errmsg             VARCHAR2(5000) DEFAULT NULL;            -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg            VARCHAR2(5000) DEFAULT NULL;            -- ���b�Z�[�W�o�͕ϐ�
    lb_retcode            BOOLEAN        DEFAULT NULL;            -- ���b�Z�[�W�o�͊֐��̖߂�l
    lv_flat               VARCHAR2(1000) DEFAULT NULL;            -- �t���b�g�t�@�C���쐬�ϐ�
    lv_budget_year        VARCHAR2(100)  DEFAULT NULL;            -- �\�Z�N�x�ϊ��ϐ�
    lv_target_month       VARCHAR2(100)  DEFAULT NULL;            -- ���x�ϊ��ϐ�
    lv_budget_amt         VARCHAR2(100)  DEFAULT NULL;            -- �\�Z���z�ϊ��ϐ�
    lv_system_date        VARCHAR2(100)  DEFAULT NULL;            -- �V�X�e�����t�ϊ��ϐ�
    lv_company_code       VARCHAR2(100)  DEFAULT NULL;            -- ��ЃR�[�h�̕ϐ�
    lv_base_code          VARCHAR2(100)  DEFAULT NULL;            -- ���_�R�[�h�̕ϐ�
    lv_corp_code          VARCHAR2(100)  DEFAULT NULL;            -- ��ƃR�[�h�̕ϐ�
    lv_sales_outlets_code VARCHAR2(100)  DEFAULT NULL;            -- �≮������R�[�h�̕ϐ�
    lv_acct_code          VARCHAR2(100)  DEFAULT NULL;            -- ����ȖڃR�[�h�̕ϐ�
    lv_sub_acct_code      VARCHAR2(100)  DEFAULT NULL;            -- �⏕�ȖڃR�[�h�̕ϐ�
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    upd_expt EXCEPTION;
    --==============================================================
    --���b�N�擾�p�J�[�\��
    --==============================================================
    CURSOR l_upd_cur(
             in_bm_support_budget_id IN NUMBER
           )
    IS
      SELECT 'X'
      FROM   xxcok_bm_support_budget xbsb
      WHERE  xbsb.bm_support_budget_id = in_bm_support_budget_id
      FOR UPDATE OF xbsb.bm_support_budget_id NOWAIT;
--
  BEGIN
    ov_retcode := cv_status_normal;
    --===============================================================
    --���[�v�J�n
    --===============================================================
    <<file_loop>>
    FOR i IN 1 .. g_bm_support_budget_tab.COUNT LOOP
      lv_company_code       := g_bm_support_budget_tab(i).company_code;
      lv_budget_year        := g_bm_support_budget_tab(i).budget_year;
      lv_base_code          := g_bm_support_budget_tab(i).base_code;
      lv_corp_code          := g_bm_support_budget_tab(i).corp_code;
      lv_sales_outlets_code := g_bm_support_budget_tab(i).sales_outlets_code;
      lv_acct_code          := g_bm_support_budget_tab(i).acct_code;
      lv_sub_acct_code      := g_bm_support_budget_tab(i).sub_acct_code;
      lv_target_month       := g_bm_support_budget_tab(i).target_month;
      lv_budget_amt         := g_bm_support_budget_tab(i).budget_amt;
      lv_system_date        := TO_CHAR( gd_system_date, 'YYYYMMDDHH24MISS' );
--
      lv_flat := (
        cv_msg_double || lv_company_code       || cv_msg_double || cv_msg_comma ||     -- ��ЃR�[�h
                         lv_budget_year        || cv_msg_comma  ||                     -- �\�Z�N�x
        cv_msg_double || lv_base_code          || cv_msg_double || cv_msg_comma ||     -- ���_�R�[�h
        cv_msg_double || lv_corp_code          || cv_msg_double || cv_msg_comma ||     -- ��ƃR�[�h
        cv_msg_double || lv_sales_outlets_code || cv_msg_double || cv_msg_comma ||     -- �≮������R�[�h
        cv_msg_double || lv_acct_code          || cv_msg_double || cv_msg_comma ||     -- ����ȖڃR�[�h
        cv_msg_double || lv_sub_acct_code      || cv_msg_double || cv_msg_comma ||     -- �⏕�ȖڃR�[�h
                         lv_target_month       || cv_msg_comma  ||                     -- ���x
                         lv_budget_amt         || cv_msg_comma  ||                     -- �\�Z���z
                         lv_system_date                                                -- �V�X�e�����t
      );
      --==============================================================
      --�t���b�g�t�@�C�����쐬
      --==============================================================
      UTL_FILE.PUT_LINE(
        file   => g_open_file           -- �t�@�C���n���h��
      , buffer => lv_flat               -- �e�L�X�g�o�b�t�@
      );
      --==============================================================
      --�A�g�σf�[�^�X�e�[�^�X�X�V
      --==============================================================
    OPEN  l_upd_cur(
            g_bm_support_budget_tab(i).bm_support_budget_id
          );
    CLOSE l_upd_cur;
    BEGIN
      UPDATE xxcok_bm_support_budget       xbsb
      SET    xbsb.info_interface_status  = cv_settled_status         -- ���n�A�g�X�e�[�^�X
           , xbsb.last_updated_by        = cn_last_updated_by        -- ���O�C�����[�U�[ID
           , xbsb.last_update_date       = SYSDATE                   -- �V�X�e�����t
           , xbsb.last_update_login      = cn_last_update_login      -- ���O�C��ID
           , xbsb.request_id             = cn_request_id             -- �R���J�����g�v��ID
           , xbsb.program_application_id = cn_program_application_id -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
           , xbsb.program_id             = cn_program_id             -- �R���J�����g�E�v���O����ID
           , xbsb.program_update_date    = SYSDATE                   -- �V�X�e�����t
      WHERE  xbsb.bm_support_budget_id   = g_bm_support_budget_tab(i).bm_support_budget_id;
    EXCEPTION
      WHEN OTHERS THEN
        -- *** �A�g�σf�[�^�X�e�[�^�X�X�V�G���[ ***
        lv_out_msg := xxccp_common_pkg.get_msg(
                        cv_appli_xxcok_name
                      , cv_status_err_msg
                      , cv_company_token
                      , lv_company_code          -- ��ЃR�[�h
                      , cv_budget_token
                      , lv_budget_year           -- �\�Z�N�x
                      , cv_location_token
                      , lv_base_code             -- ���_�R�[�h
                      , cv_corporate_token
                      , lv_corp_code             -- ��ƃR�[�h
                      , cv_store_token
                      , lv_sales_outlets_code    -- �≮������R�[�h
                      , cv_account_token
                      , lv_acct_code             -- ����ȖڃR�[�h
                      , cv_sub_token
                      , lv_sub_acct_code         -- �⏕�ȖڃR�[�h
                      );
        lb_retcode := xxcok_common_pkg.put_message_f( 
                        FND_FILE.OUTPUT    -- �o�͋敪
                      , lv_out_msg         -- ���b�Z�[�W
                      , 0                  -- ���s
                      );
        ov_errmsg  := NULL;
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      RAISE upd_expt;
    END;
    --==============================================================
    --���������J�E���g
    --==============================================================
    gn_normal_cnt := gn_normal_cnt + 1;
--
    END LOOP file_loop;
--
  EXCEPTION
    -- *** ���b�N�G���[���b�Z�[�W ***
    WHEN lock_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_lock_err_msg
                    , cv_company_token
                    , lv_company_code          -- ��ЃR�[�h
                    , cv_budget_token
                    , lv_budget_year           -- �\�Z�N�x
                    , cv_location_token
                    , lv_base_code             -- ���_�R�[�h
                    , cv_corporate_token
                    , lv_corp_code             -- ��ƃR�[�h
                    , cv_store_token
                    , lv_sales_outlets_code    -- �≮������R�[�h
                    , cv_account_token
                    , lv_acct_code             -- ����ȖڃR�[�h
                    , cv_sub_token
                    , lv_sub_acct_code         -- �⏕�ȖڃR�[�h
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- �o�͋敪
                    , lv_out_msg         -- ���b�Z�[�W
                    , 0                  -- ���s
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** �A�g�σf�[�^�X�e�[�^�X�X�V�G���[ ***
    WHEN upd_expt THEN
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
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
    -- ���[�J���萔
    -- ===============================
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1)    DEFAULT NULL;                 -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg VARCHAR2(5000)  DEFAULT NULL;                 -- ���b�Z�[�W�o�͕ϐ�
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
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
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
    lv_out_msg VARCHAR2(5000)  DEFAULT NULL;            -- ���b�Z�[�W�o�͕ϐ�
    lb_retcode BOOLEAN        DEFAULT NULL;            -- ���b�Z�[�W�o�͊֐��̖߂�l
    -- ===============================
    -- ���[�J����O
    -- ===============================
    file_close_expt EXCEPTION;                         -- �t�@�C���N���[�Y�G���[
--
  BEGIN
    ov_retcode := cv_status_normal;
    --==============================================================
    --�O���[�o���ϐ��̏�����
    --==============================================================
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
    --===============================================================
    --init�̌Ăяo��(��������(A-1))
    --===============================================================
    init(
      ov_errbuf  => lv_errbuf                          -- �G���[�E���b�Z�[�W
    , ov_retcode => lv_retcode                         -- ���^�[���E�R�[�h
    , ov_errmsg  => lv_errmsg                          -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --===============================================================
    --get_target_account_p�̌Ăяo��(�����Ώۉ�v�N�x�擾(A-2))
    --===============================================================
    get_target_account_p(
      ov_errbuf  => lv_errbuf                          -- �G���[�E���b�Z�[�W
    , ov_retcode => lv_retcode                         -- ���^�[���E�R�[�h
    , ov_errmsg  => lv_errmsg                          -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --===============================================================
    --open_file_p�̌Ăяo��(�t�@�C���I�[�v��(A-3))
    --===============================================================
    open_file_p(
      ov_errbuf  => lv_errbuf                          -- �G���[�E���b�Z�[�W
    , ov_retcode => lv_retcode                         -- ���^�[���E�R�[�h
    , ov_errmsg  => lv_errmsg                          -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --===============================================================
    --get_budget_info_p�̌Ăяo��(�A�g�Ώ۔̎�̋��\�Z���擾(A-4))
    --===============================================================
    get_budget_info_p(
      ov_errbuf  => lv_errbuf                          -- �G���[�E���b�Z�[�W
    , ov_retcode => lv_retcode                         -- ���^�[���E�R�[�h
    , ov_errmsg  => lv_errmsg                          -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    IF( gn_target_cnt > 0 ) THEN
      --===============================================================
      --create_flat_file_p�̌Ăяo��(�t���b�g�t�@�C���쐬(A-5))
      --===============================================================
      create_flat_file_p(
        ov_errbuf  => lv_errbuf                        -- �G���[�E���b�Z�[�W
      , ov_retcode => lv_retcode                       -- ���^�[���E�R�[�h
      , ov_errmsg  => lv_errmsg                        -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      IF( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
    --===============================================================
    --close_file_p�̌Ăяo��(�t�@�C���N���[�Y(A-7))
    --===============================================================
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
    -- *** �t�@�C���N���[�Y�G���[ ***
    WHEN file_close_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;      
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      close_file_p(
        ov_errbuf   => lv_errbuf                       -- �G���[�E���b�Z�[�W
      , ov_retcode  => lv_retcode                      -- ���^�[���E�R�[�h
      , ov_errmsg   => lv_errmsg                       -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
      close_file_p(
        ov_errbuf   => lv_errbuf                       -- �G���[�E���b�Z�[�W
      , ov_retcode  => lv_retcode                      -- ���^�[���E�R�[�h
      , ov_errmsg   => lv_errmsg                       -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
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
    errbuf  OUT VARCHAR2                                             -- �G���[�E���b�Z�[�W
  , retcode OUT VARCHAR2                                             -- ���^�[���E�R�[�h  
  )
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf          VARCHAR2(5000) DEFAULT NULL;                  -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1)    DEFAULT NULL;                  -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000) DEFAULT NULL;                  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg         VARCHAR2(5000)  DEFAULT NULL;                  -- ���b�Z�[�W�o�͕ϐ�
    lb_retcode         BOOLEAN        DEFAULT NULL;                  -- ���b�Z�[�W�o�͊֐��̖߂�l
    lv_message_code    VARCHAR2(100)  DEFAULT NULL;                  -- �I�����b�Z�[�W�R�[�h
--
  BEGIN
    --===============================================================
    --�R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    --===============================================================
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
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    --===============================================================
    --submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    --===============================================================
    submain(
      ov_errbuf  => lv_errbuf          -- �G���[�E���b�Z�[�W
    , ov_retcode => lv_retcode         -- ���^�[���E�R�[�h
    , ov_errmsg  => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    --===============================================================
    --�G���[�o��
    --===============================================================
    IF( lv_retcode = cv_status_error ) THEN
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
    --===============================================================
    --�Ώی����o��
    --===============================================================
    IF( lv_retcode = cv_status_error ) THEN
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
    lv_out_msg := xxccp_common_pkg.get_msg(
                    cv_appli_xxccp_name
                  , cv_target_rec_msg
                  , cv_cnt_token
                  , TO_CHAR( gn_target_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.OUTPUT    -- �o�͋敪
                  , lv_out_msg         -- ���b�Z�[�W
                  , 0                  -- ���s
                  );
    --===============================================================
    --���������o��
    --===============================================================
    lv_out_msg := xxccp_common_pkg.get_msg(
                    cv_appli_xxccp_name
                  , cv_success_rec_msg
                  , cv_cnt_token
                  , TO_CHAR( gn_normal_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.OUTPUT    -- �o�͋敪
                  , lv_out_msg         -- ���b�Z�[�W
                  , 0                  -- ���s
                  );
    --===============================================================
    --�G���[�����o��
    --===============================================================
    lv_out_msg := xxccp_common_pkg.get_msg(
                    cv_appli_xxccp_name
                  , cv_error_rec_msg
                  , cv_cnt_token
                  , TO_CHAR( gn_error_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.OUTPUT    -- �o�͋敪
                  , lv_out_msg         -- ���b�Z�[�W
                  , 0                  -- ���s
                  );
    --===============================================================
    --�I�����b�Z�[�W
    --===============================================================
    IF( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
      retcode         := cv_status_normal;
    ELSIF( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
      retcode         := cv_status_error;
    END IF;
    --
    lv_out_msg := xxccp_common_pkg.get_msg(
                    cv_appli_xxccp_name
                  , lv_message_code
                  );
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
END XXCOK022A02C;
/