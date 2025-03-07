CREATE OR REPLACE PACKAGE BODY APPS.XXCOK024A48C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A48C (body)
 * Description      : ERP CLOUD�̔��|/�������������̃X�e�[�^�X�ɏ]���A
 *                  : �T���z�̎x�� (AP�x��) ��ʂ̏����X�e�[�^�X���X�V���܂��B
 * MD.050           : �T���x�����F�X�e�[�^�X���f MD050_COK_024_A48
 * Version          : 1.0
 * Program List
 * ----------------------------------------------------------------------------------------
 *  Name                    Description
 * ----------------------------------------------------------------------------------------
 *  init                    A-1.��������
 *  get_recon_status        A-2.�T���x���X�e�[�^�X���o
 *  update_recon_status     A-3.�X�e�[�^�X���f����
 *  submain                 ���C�������v���V�[�W��
 *  main                    �R���J�����g���s�t�@�C���o�^�v���V�[�W��(A-4.�I���������܂�)
 *
 * Change Record
 * ------------- -------------------------------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- -------------------------------------------------------------------------
 *  2024/11/28    1.0   Y.Koh            �V�K�쐬
 *
 *****************************************************************************************/
--
--###########################  �Œ�O���[�o���萔�錾�� START  ###########################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; -- ����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   -- �x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  -- �ُ�:2
  --WHO�J����
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;                 -- CREATED_BY
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;                 -- LAST_UPDATED_BY
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;                -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id;         -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;            -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id;         -- PROGRAM_ID
  cd_creation_date          CONSTANT DATE        := SYSDATE;                            -- CREATION_DATE
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                            -- LAST_UPDATE_DATE
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                            -- PROGRAM_UPDATE_DATE
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--############################  �Œ�O���[�o���萔�錾�� END  ############################
--
--###########################  �Œ�O���[�o���ϐ��錾�� START  ###########################
--
  gv_out_msg       VARCHAR2(2000);            -- �o�̓��b�Z�[�W
  gn_target_cnt    NUMBER;                    -- �Ώی���
  gn_normal_cnt    NUMBER;                    -- ���팏��
  gn_error_cnt     NUMBER;                    -- �G���[����
  gn_warn_cnt      NUMBER;                    -- �X�L�b�v����
--
--############################  �Œ�O���[�o���ϐ��錾�� END  ############################
--
--##############################  �Œ苤�ʗ�O�錾�� START  ##############################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION;
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
--
--###############################  �Œ苤�ʗ�O�錾�� END  ###############################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  -- �p�b�P�[�W��
  cv_pkg_name               CONSTANT VARCHAR2(20) := 'XXCOK024A48C';                    -- �p�b�P�[�W��
  -- �A�v���P�[�V�����Z�k��
  cv_xxccp_appl_name        CONSTANT VARCHAR2(10) := 'XXCCP';                           -- ���ʗ̈�Z�k�A�v����
  cv_xxcok_short_nm         CONSTANT VARCHAR2(10) := 'XXCOK';                           -- �ʊJ���̈�Z�k�A�v����
  -- ���b�Z�[�W����
  cv_table_lock_msg         CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10632';                -- ���b�N�G���[���b�Z�[�W
  cv_target_err_msg         CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10881';                -- �Ώی���(�C���|�[�g�G���[)���b�Z�[�W
  cv_target_new_msg         CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10882';                -- �Ώی���(�V�K)���b�Z�[�W
  cv_target_rej_msg         CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10712';                -- �Ώی���(�p��)���b�Z�[�W
  cv_target_app_msg         CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10713';                -- �Ώی���(���F)���b�Z�[�W
  cv_target_canc_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10714';                -- �Ώی���(���)���b�Z�[�W
  cv_success_err_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10883';                -- ��������(�C���|�[�g�G���[)���b�Z�[�W
  cv_success_new_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10884';                -- ��������(�V�K)���b�Z�[�W
  cv_success_rej_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10715';                -- ��������(�p��)���b�Z�[�W
  cv_success_app_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10716';                -- ��������(���F)���b�Z�[�W
  cv_success_canc_msg       CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10717';                -- ��������(���)���b�Z�[�W
  cv_error_rec_msg          CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90002';                -- �G���[�������b�Z�[�W
  cv_normal_msg             CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90004';                -- ����I�����b�Z�[�W
  cv_warn_msg               CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90005';                -- �x���I�����b�Z�[�W
  cv_error_msg              CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90006';                -- �G���[�I���S���[���o�b�N
  -- �g�[�N��
  cv_cnt_token              CONSTANT VARCHAR2(20) := 'COUNT';                           -- �������b�Z�[�W�p�g�[�N��
  -- �t���O�E�敪�萔
  cv_y_flag                 CONSTANT VARCHAR2(1)  := 'Y';                               -- �t���O�l:Y
  cv_n_flag                 CONSTANT VARCHAR2(1)  := 'N';                               -- �t���O�l:N
  cv_new_flag               CONSTANT VARCHAR2(1)  := 'N';                               -- �t���O�l:NEW
  -- �T���x���X�e�[�^�X
  cv_ap_status_e            CONSTANT VARCHAR2(1)  := 'E';                               -- �C���|�[�g�G���[
  cv_ap_status_n            CONSTANT VARCHAR2(1)  := 'N';                               -- �V�K
  cv_ap_status_d            CONSTANT VARCHAR2(1)  := 'D';                               -- �۔F
  cv_ap_status_a            CONSTANT VARCHAR2(1)  := 'A';                               -- ���F
  cv_ap_status_c            CONSTANT VARCHAR2(1)  := 'C';                               -- ���
  -- �T�������w�b�_�[���
  cv_recon_status_eg        CONSTANT VARCHAR2(2)  := 'EG';                              -- ���͒�
  cv_recon_status_sd        CONSTANT VARCHAR2(2)  := 'SD';                              -- ���M��
  cv_recon_status_dd        CONSTANT VARCHAR2(2)  := 'DD';                              -- �폜��
  cv_recon_status_ad        CONSTANT VARCHAR2(2)  := 'AD';                              -- ���F��
  cv_recon_status_cd        CONSTANT VARCHAR2(2)  := 'CD';                              -- �����
  -- �̔��T�����
  cv_source_cate            CONSTANT VARCHAR2(1)  := 'D';                               -- �쐬���敪�F���z����
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ����`�[���o�^��`
  TYPE g_recon_status_rtype IS RECORD(
       recon_status_id      xxcok_deduction_recon_status.recon_status_id%TYPE           -- �T���x���X�e�[�^�XID
      ,recon_slip_num       xxcok_deduction_recon_status.recon_slip_num%TYPE            -- �x���`�[�ԍ�
      ,status               xxcok_deduction_recon_status.status%TYPE                    -- �X�e�[�^�X
      ,approval_date        xxcok_deduction_recon_status.approval_date%TYPE             -- ���F��
      ,approver             per_all_people_f.employee_number%TYPE                       -- ���F��
      ,cancellation_date    xxcok_deduction_recon_status.cancellation_date%TYPE         -- �����
  );
  -- ����`�[���o���[�N�e�[�u���^��`
  TYPE g_recon_status_ttype IS TABLE OF g_recon_status_rtype INDEX BY BINARY_INTEGER;
  -- ����`�[���o�e�[�u���^�ϐ�
  g_recon_status_tbl    g_recon_status_ttype;                                           -- ����`�[���o
--
  -- ===============================
  -- ���[�U�[��`�O���[�o�����R�[�h
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- �����擾
  gd_cancel_gl_date         DATE;                                                       -- ���GL�L����
  -- �Ώی���
  gn_err_target_cnt         NUMBER;                                                     -- �Ώی���(�C���|�[�g�G���[)
  gn_new_target_cnt         NUMBER;                                                     -- �Ώی���(�V�K)
  gn_reject_target_cnt      NUMBER;                                                     -- �Ώی���(�p��)
  gn_approval_target_cnt    NUMBER;                                                     -- �Ώی���(���F)
  gn_cancel_target_cnt      NUMBER;                                                     -- �Ώی���(���)
  -- ���팏��
  gn_err_normal_cnt         NUMBER;                                                     -- ��������(�C���|�[�g�G���[)
  gn_new_normal_cnt         NUMBER;                                                     -- ��������(�V�K)
  gn_reject_normal_cnt      NUMBER;                                                     -- ��������(�p��)
  gn_approval_normal_cnt    NUMBER;                                                     -- ��������(���F)
  gn_cancel_normal_cnt      NUMBER;                                                     -- ��������(���)
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���J�[�\��
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : A-1.��������
   ***********************************************************************************/
  PROCEDURE init( ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W            --# �Œ� #
                 ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h              --# �Œ� #
                 ,ov_errmsg     OUT VARCHAR2 )   --   ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init';                                 -- �v���O������
--
--############################  �Œ胍�[�J���ϐ��錾�� START  ############################
--
    lv_errbuf  VARCHAR2(5000);       -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);          -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);       -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#############################  �Œ胍�[�J���ϐ��錾�� END  #############################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J����O ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--############################  �Œ�X�e�[�^�X�������� START  ############################
--
    ov_retcode  := cv_status_normal;
--
--#############################  �Œ�X�e�[�^�X�������� END  #############################
--
    -- ============================================================
    -- 1.AP�J�����_�[��OPEN���擾
    -- ============================================================
    SELECT
        MIN(gps.end_date) cancel_gl_date
    INTO
        gd_cancel_gl_date
    FROM
        gl_period_statuses  gps ,
        fnd_application     fa
    WHERE
        fa.application_short_name   =   'SQLAP'
    and gps.application_id          =   fa.application_id
    and gps.set_of_books_id         =   FND_PROFILE.VALUE('GL_SET_OF_BKS_ID')
    and CLOSING_STATUS              =   'O';
--
  EXCEPTION
--
--################################  �Œ��O������ START  ################################
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--#################################  �Œ��O������ END  #################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_recon_status
   * Description      : A-2.�T���x���X�e�[�^�X���o
   ***********************************************************************************/
  PROCEDURE get_recon_status(
                  ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
                 ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
                 ,ov_errmsg     OUT VARCHAR2 )   --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_recon_status';                -- �v���O������
--
--############################  �Œ胍�[�J���ϐ��錾�� START  ############################
--
    lv_errbuf  VARCHAR2(5000);       -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);          -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);       -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#############################  �Œ胍�[�J���ϐ��錾�� END  #############################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J����O ***
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �T���x���X�e�[�^�X
    CURSOR recon_status_cur
    IS
      SELECT  xdrs.recon_status_id    AS  recon_status_id   , -- �T���x���X�e�[�^�XID
              xdrs.recon_slip_num     AS  recon_slip_num    , -- �x���`�[�ԍ�
              xdrs.status             AS  status            , -- �X�e�[�^�X
              xdrs.approval_date      AS  approval_date     , -- ���F��
              papf.employee_number    AS  approver          , -- ���F��
              xdrs.cancellation_date  AS  cancellation_date   -- �����
      FROM    per_all_people_f        papf,                   -- �]�ƈ�
              fnd_user                fu  ,                   -- ���[�U�[
              xxcok_deduction_recon_status    xdrs            -- �T���x���X�e�[�^�X�e�[�u��
      WHERE   xdrs.processed_flag = cv_n_flag                 -- �����σt���O
      AND     fu.user_name(+)     = xdrs.approver
      AND     papf.PERSON_ID(+)   = fu.EMPLOYEE_ID
      AND     trunc(sysdate)      between papf.EFFECTIVE_START_DATE(+)  and papf.EFFECTIVE_END_DATE(+)
      ORDER BY recon_status_id
      ;
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--############################  �Œ�X�e�[�^�X�������� START  ############################
--
    ov_retcode  := cv_status_normal;
--
--#############################  �Œ�X�e�[�^�X�������� END  #############################
--
    -- ============================================================
    -- ����`�[���擾
    -- ============================================================
    -- �J�[�\���I�[�v��
    OPEN  recon_status_cur;
    -- �f�[�^�擾
    FETCH recon_status_cur BULK COLLECT INTO g_recon_status_tbl;
    -- �J�[�\���N���[�Y
    CLOSE recon_status_cur;
--
  EXCEPTION
--################################  �Œ��O������ START  ################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- �J�[�\���N���[�Y
      IF ( recon_status_cur%ISOPEN ) THEN
        CLOSE recon_status_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\���N���[�Y
      IF ( recon_status_cur%ISOPEN ) THEN
        CLOSE recon_status_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���N���[�Y
      IF ( recon_status_cur%ISOPEN ) THEN
        CLOSE recon_status_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ END  #################################
--
  END get_recon_status;
--
  /**********************************************************************************
   * Procedure Name   : update_recon_status
   * Description      : A-3.�X�e�[�^�X���f����
   ***********************************************************************************/
  PROCEDURE update_recon_status(
                  ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
                 ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
                 ,ov_errmsg     OUT VARCHAR2 )   --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_recon_status';             -- �v���O������
--
--############################  �Œ胍�[�J���ϐ��錾�� START  ############################
--
    lv_errbuf  VARCHAR2(5000);       -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);          -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);       -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#############################  �Œ胍�[�J���ϐ��錾�� END  #############################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_dummy            NUMBER;
    -- *** ���[�J����O ***
    lock_expt       EXCEPTION;
    PRAGMA EXCEPTION_INIT(lock_expt, -54);                  -- ���b�N�G���[
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--############################  �Œ�X�e�[�^�X�������� START  ############################
--
    ov_retcode  := cv_status_normal;
--
--#############################  �Œ�X�e�[�^�X�������� END  #############################
--
    -- ����`�[���o�������X�e�[�^�X���f���������s
    <<update_recon_status_loop>>
    FOR ln_get_cnt IN 1..g_recon_status_tbl.COUNT LOOP
--
      BEGIN
--
        -- �T�������w�b�_�[���b�N����
        SELECT 1  AS dummy
        INTO   ln_dummy
        FROM   xxcok_deduction_recon_head    xdrh -- �T�������w�b�_�[���
        WHERE  xdrh.recon_slip_num           = g_recon_status_tbl(ln_get_cnt).recon_slip_num
        FOR UPDATE OF xdrh.deduction_recon_head_id NOWAIT
        ;
--
        -- �̔��T����񃍃b�N����
        SELECT 1  AS dummy
        INTO   ln_dummy
        FROM   xxcok_sales_deduction         xsd  -- �̔��T�����
        WHERE  xsd.recon_slip_num            = g_recon_status_tbl(ln_get_cnt).recon_slip_num
        FOR UPDATE OF xsd.sales_deduction_id NOWAIT
        ;
--
      EXCEPTION
        -- ���b�N�G���[
        WHEN lock_expt THEN
          -- ���b�N�G���[���b�Z�[�W
          lv_errmsg      := xxccp_common_pkg.get_msg( cv_xxcok_short_nm
                                                     ,cv_table_lock_msg
                                                     );
          lv_errbuf      := lv_errmsg;
          ov_errmsg      := lv_errmsg;
          ov_errbuf      := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
          ov_retcode     := cv_status_error;
          RAISE global_process_expt;
        WHEN OTHERS THEN
          NULL;
      END;
--
      IF    g_recon_status_tbl(ln_get_cnt).status  = cv_ap_status_e  THEN -- �C���|�[�g�G���[
--
        -- �Ώی���(�C���|�[�g�G���[)���C���N�������g
        gn_err_target_cnt := gn_err_target_cnt + 1;
--
        -- �T�������w�b�_�[���̏����X�e�[�^�X���X�V
        UPDATE  xxcok_deduction_recon_head   xdrh                                           -- �T�������w�b�_�[���
        SET     xdrh.recon_status           = cv_recon_status_eg                          , -- �����X�^�[�^�X
                ap_ar_if_flag               = cv_n_flag                                   , -- AP/AR�A�g�t���O
                xdrh.last_updated_by        = cn_last_updated_by                          , -- �ŏI�X�V��
                xdrh.last_update_date       = cd_last_update_date                         , -- �ŏI�X�V��
                xdrh.last_update_login      = cn_last_update_login                        , -- �ŏI�X�V���O�C��
                xdrh.request_id             = cn_request_id                               , -- �v��ID
                xdrh.program_application_id = cn_program_application_id                   , -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
                xdrh.program_id             = cn_program_id                               , -- �R���J�����g�E�v���O����ID
                xdrh.program_update_date    = cd_program_update_date                        -- �v���O�����X�V��
        WHERE   xdrh.recon_slip_num         = g_recon_status_tbl(ln_get_cnt).recon_slip_num
        ;
--
        -- ��������(�C���|�[�g�G���[)���C���N�������g
        gn_err_normal_cnt := gn_err_normal_cnt + 1;
--
      ELSIF g_recon_status_tbl(ln_get_cnt).status  = cv_ap_status_n  THEN -- �V�K
--
        -- �Ώی���(�V�K)���C���N�������g
        gn_new_target_cnt := gn_new_target_cnt + 1;
--
        -- �T�������w�b�_�[���̏����X�e�[�^�X���X�V
        UPDATE  xxcok_deduction_recon_head   xdrh                                           -- �T�������w�b�_�[���
        SET     xdrh.recon_status           = cv_recon_status_sd                          , -- �����X�^�[�^�X
                xdrh.last_updated_by        = cn_last_updated_by                          , -- �ŏI�X�V��
                xdrh.last_update_date       = cd_last_update_date                         , -- �ŏI�X�V��
                xdrh.last_update_login      = cn_last_update_login                        , -- �ŏI�X�V���O�C��
                xdrh.request_id             = cn_request_id                               , -- �v��ID
                xdrh.program_application_id = cn_program_application_id                   , -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
                xdrh.program_id             = cn_program_id                               , -- �R���J�����g�E�v���O����ID
                xdrh.program_update_date    = cd_program_update_date                        -- �v���O�����X�V��
        WHERE   xdrh.recon_slip_num         = g_recon_status_tbl(ln_get_cnt).recon_slip_num
        ;
--
        -- ��������(�V�K)���C���N�������g
        gn_new_normal_cnt := gn_new_normal_cnt + 1;
--
      ELSIF g_recon_status_tbl(ln_get_cnt).status  = cv_ap_status_d  THEN -- �p��
--
        -- �Ώی���(�p��)���C���N�������g
        gn_reject_target_cnt := gn_reject_target_cnt + 1;
--
        -- �T�������w�b�_�[���̏����X�e�[�^�X���X�V
        UPDATE  xxcok_deduction_recon_head   xdrh                                           -- �T�������w�b�_�[���
        SET     xdrh.recon_status           = cv_recon_status_dd                          , -- �����X�^�[�^�X
                xdrh.last_updated_by        = cn_last_updated_by                          , -- �ŏI�X�V��
                xdrh.last_update_date       = cd_last_update_date                         , -- �ŏI�X�V��
                xdrh.last_update_login      = cn_last_update_login                        , -- �ŏI�X�V���O�C��
                xdrh.request_id             = cn_request_id                               , -- �v��ID
                xdrh.program_application_id = cn_program_application_id                   , -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
                xdrh.program_id             = cn_program_id                               , -- �R���J�����g�E�v���O����ID
                xdrh.program_update_date    = cd_program_update_date                        -- �v���O�����X�V��
        WHERE   xdrh.recon_slip_num         = g_recon_status_tbl(ln_get_cnt).recon_slip_num
        ;
--
        -- �Y���x���̍T���f�[�^���J��
        UPDATE  xxcok_sales_deduction        xsd                                            -- �̔��T�����
        SET     xsd.recon_slip_num           = NULL                                       , -- �x���`�[�ԍ�
                xsd.carry_payment_slip_num   = NULL                                       , -- �J�z���x���`�[�ԍ�
                xsd.last_updated_by          = cn_last_updated_by                         , -- �ŏI�X�V��
                xsd.last_update_date         = cd_last_update_date                        , -- �ŏI�X�V��
                xsd.last_update_login        = cn_last_update_login                       , -- �ŏI�X�V���O�C��
                xsd.request_id               = cn_request_id                              , -- �v��ID
                xsd.program_application_id   = cn_program_application_id                  , -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
                xsd.program_id               = cn_program_id                              , -- �R���J�����g�E�v���O����ID
                xsd.program_update_date      = cd_program_update_date                       -- �v���O�����X�V��
        WHERE   xsd.recon_slip_num           = g_recon_status_tbl(ln_get_cnt).recon_slip_num
        AND     xsd.status                   = cv_new_flag
        ;
--
        -- ��������(�p��)���C���N�������g
        gn_reject_normal_cnt := gn_reject_normal_cnt + 1;
--
      ELSIF g_recon_status_tbl(ln_get_cnt).status  = cv_ap_status_a  THEN -- ���F
--
        -- �Ώی���(���F)���C���N�������g
        gn_approval_target_cnt := gn_approval_target_cnt + 1;
--
        -- �T�������w�b�_�[���̏����X�e�[�^�X���X�V
        UPDATE  xxcok_deduction_recon_head   xdrh                                           -- �T�������w�b�_�[���
        SET     xdrh.recon_status           = cv_recon_status_ad                          , -- �����X�^�[�^�X
                approval_date               = g_recon_status_tbl(ln_get_cnt).approval_date, -- ���F��
                approver                    = g_recon_status_tbl(ln_get_cnt).approver     , -- ���F��
                xdrh.last_updated_by        = cn_last_updated_by                          , -- �ŏI�X�V��
                xdrh.last_update_date       = cd_last_update_date                         , -- �ŏI�X�V��
                xdrh.last_update_login      = cn_last_update_login                        , -- �ŏI�X�V���O�C��
                xdrh.request_id             = cn_request_id                               , -- �v��ID
                xdrh.program_application_id = cn_program_application_id                   , -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
                xdrh.program_id             = cn_program_id                               , -- �R���J�����g�E�v���O����ID
                xdrh.program_update_date    = cd_program_update_date                        -- �v���O�����X�V��
        WHERE   xdrh.recon_slip_num         = g_recon_status_tbl(ln_get_cnt).recon_slip_num
        ;
--
        -- �T���f�[�^���z���z���������s
        XXCOK024A19C.main( lv_errbuf
                          ,lv_retcode
                          ,lv_errmsg
                          ,g_recon_status_tbl(ln_get_cnt).recon_slip_num
                          );
--
        IF ( lv_retcode = cv_status_error ) THEN
          lv_errmsg :=  '���z���z����:'  ||  lv_errmsg;
          RAISE global_process_expt;
        END IF;
--
        -- ��������(���F)���C���N�������g
        gn_approval_normal_cnt := gn_approval_normal_cnt + 1;
--
      ELSIF g_recon_status_tbl(ln_get_cnt).status  = cv_ap_status_c  THEN -- ���
--
        -- �Ώی���(���)���C���N�������g
        gn_cancel_target_cnt := gn_cancel_target_cnt + 1;
--
        -- �T�������w�b�_�[���̏����X�e�[�^�X���X�V
        UPDATE  xxcok_deduction_recon_head   xdrh                                           -- �T�������w�b�_�[���
        SET     xdrh.recon_status           = DECODE(xdrh.recon_status, cv_recon_status_ad, cv_recon_status_cd, cv_recon_status_dd)
                                                                                          , -- �����X�^�[�^�X
                xdrh.cancellation_date      = DECODE(xdrh.recon_status, cv_recon_status_ad, g_recon_status_tbl(ln_get_cnt).cancellation_date, xdrh.cancellation_date)
                                                                                          , -- �����
                xdrh.cancel_gl_date         = DECODE(xdrh.recon_status, cv_recon_status_ad, DECODE(xdrh.gl_if_flag, cv_n_flag, xdrh.gl_date, gd_cancel_gl_date), xdrh.cancel_gl_date)
                                                                                          , -- ���GL�L����
                xdrh.last_updated_by        = cn_last_updated_by                          , -- �ŏI�X�V��
                xdrh.last_update_date       = cd_last_update_date                         , -- �ŏI�X�V��
                xdrh.last_update_login      = cn_last_update_login                        , -- �ŏI�X�V���O�C��
                xdrh.request_id             = cn_request_id                               , -- �v��ID
                xdrh.program_application_id = cn_program_application_id                   , -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
                xdrh.program_id             = cn_program_id                               , -- �R���J�����g�E�v���O����ID
                xdrh.program_update_date    = cd_program_update_date                        -- �v���O�����X�V��
        WHERE   xdrh.recon_slip_num         = g_recon_status_tbl(ln_get_cnt).recon_slip_num
        ;
--
        -- �Y���x���̍��z�����f�[�^������ςɍX�V
        UPDATE  xxcok_sales_deduction        xsd                                            -- �̔��T�����
        SET     xsd.status                   = 'C'                                        , -- �X�e�[�^�X
                xsd.recovery_del_date        = SYSDATE                                    , -- ���J�o���f�[�^�폜�����t
                xsd.cancel_flag              = cv_y_flag                                  , -- ����t���O
                xsd.last_updated_by          = cn_last_updated_by                         , -- �ŏI�X�V��
                xsd.last_update_date         = cd_last_update_date                        , -- �ŏI�X�V��
                xsd.last_update_login        = cn_last_update_login                       , -- �ŏI�X�V���O�C��
                xsd.request_id               = cn_request_id                              , -- �v��ID
                xsd.program_application_id   = cn_program_application_id                  , -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
                xsd.program_id               = cn_program_id                              , -- �R���J�����g�E�v���O����ID
                xsd.program_update_date      = cd_program_update_date                       -- �v���O�����X�V��
        WHERE   xsd.recon_slip_num           = g_recon_status_tbl(ln_get_cnt).recon_slip_num
        AND     xsd.source_category          = cv_source_cate
        ;
--
        -- �Y���x���̍T���f�[�^���J��
        UPDATE  xxcok_sales_deduction        xsd                                            -- �̔��T�����
        SET     xsd.recon_slip_num           = NULL                                       , -- �x���`�[�ԍ�
                xsd.carry_payment_slip_num   = NULL                                       , -- �J�z���x���`�[�ԍ�
                xsd.last_updated_by          = cn_last_updated_by                         , -- �ŏI�X�V��
                xsd.last_update_date         = cd_last_update_date                        , -- �ŏI�X�V��
                xsd.last_update_login        = cn_last_update_login                       , -- �ŏI�X�V���O�C��
                xsd.request_id               = cn_request_id                              , -- �v��ID
                xsd.program_application_id   = cn_program_application_id                  , -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
                xsd.program_id               = cn_program_id                              , -- �R���J�����g�E�v���O����ID
                xsd.program_update_date      = cd_program_update_date                       -- �v���O�����X�V��
        WHERE   xsd.recon_slip_num           = g_recon_status_tbl(ln_get_cnt).recon_slip_num
        AND     xsd.status                   = cv_new_flag
        ;
--
        -- ��������(���)���C���N�������g
        gn_cancel_normal_cnt := gn_cancel_normal_cnt + 1;
--
      END IF;
--
      -- �T���x���X�e�[�^�X�e�[�u���̏����σt���O���X�V
      UPDATE  xxcok_deduction_recon_status  xdrs                                            -- �T���x���X�e�[�^�X�e�[�u��
      SET     xdrs.processed_flag         = cv_y_flag                                     , -- �����σt���O
              xdrs.last_updated_by        = cn_last_updated_by                            , -- �ŏI�X�V��
              xdrs.last_update_date       = cd_last_update_date                           , -- �ŏI�X�V��
              xdrs.last_update_login      = cn_last_update_login                          , -- �ŏI�X�V���O�C��
              xdrs.request_id             = cn_request_id                                 , -- �v��ID
              xdrs.program_application_id = cn_program_application_id                     , -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
              xdrs.program_id             = cn_program_id                                 , -- �R���J�����g�E�v���O����ID
              xdrs.program_update_date    = cd_program_update_date                          -- �v���O�����X�V��
      WHERE   xdrs.recon_status_id        = g_recon_status_tbl(ln_get_cnt).recon_status_id
      ;
--
    END LOOP update_recon_status_loop;
--
  EXCEPTION
--
--################################  �Œ��O������ START  ################################
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--#################################  �Œ��O������ END  #################################
--
  END update_recon_status;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : �T�u���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain( ov_errbuf       OUT VARCHAR2          --   �G���[�E���b�Z�[�W           --# �Œ� #
                    ,ov_retcode      OUT VARCHAR2          --   ���^�[���E�R�[�h             --# �Œ� #
                    ,ov_errmsg       OUT VARCHAR2 )        --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain';                                       -- �v���O������
--
--############################  �Œ胍�[�J���ϐ��錾�� START  ############################
--
    lv_errbuf  VARCHAR2(5000);                                        -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);                                           -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END  #####################################
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
    -- <�J�[�\����>
--
    -- <�J�[�\����>���R�[�h�^
--
  BEGIN
--
--############################  �Œ�X�e�[�^�X�������� START  ############################
--
    ov_retcode := cv_status_normal;
--
--#####################################  �Œ蕔 END  #####################################
--
    -- �O���[�o���ϐ��̏�����
    gn_error_cnt                  := 0;                   -- �G���[����
    gn_err_target_cnt             := 0;                   -- �Ώی���(�C���|�[�g�G���[)
    gn_new_target_cnt             := 0;                   -- �Ώی���(�V�K)
    gn_reject_target_cnt          := 0;                   -- �Ώی���(�p��)
    gn_approval_target_cnt        := 0;                   -- �Ώی���(���F)
    gn_cancel_target_cnt          := 0;                   -- �Ώی���(���)
    gn_err_normal_cnt             := 0;                   -- ��������(�C���|�[�g�G���[)
    gn_new_normal_cnt             := 0;                   -- ��������(�V�K)
    gn_reject_normal_cnt          := 0;                   -- ��������(�p��)
    gn_approval_normal_cnt        := 0;                   -- ��������(���F)
    gn_cancel_normal_cnt          := 0;                   -- ��������(���)
--
    -- ===============================
    -- A-1.��������
    -- ===============================
    init( ov_errbuf  => lv_errbuf          -- �G���[�E���b�Z�[�W           -- # �Œ� #
         ,ov_retcode => lv_retcode         -- ���^�[���E�R�[�h             -- # �Œ� #
         ,ov_errmsg  => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W -- # �Œ� #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-2.�T���x���X�e�[�^�X���o
    -- ===============================
    get_recon_status(
        ov_errbuf  => lv_errbuf          -- �G���[�E���b�Z�[�W           -- # �Œ� #
       ,ov_retcode => lv_retcode         -- ���^�[���E�R�[�h             -- # �Œ� #
       ,ov_errmsg  => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W -- # �Œ� #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-3.�X�e�[�^�X���f����
    -- ===============================
    update_recon_status(
        ov_errbuf  => lv_errbuf          -- �G���[�E���b�Z�[�W           -- # �Œ� #
       ,ov_retcode => lv_retcode         -- ���^�[���E�R�[�h             -- # �Œ� #
       ,ov_errmsg  => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W -- # �Œ� #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
--
--################################  �Œ��O������ START  ################################
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
--#####################################  �Œ蕔 END  #####################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
--
  PROCEDURE main( errbuf           OUT VARCHAR2               -- �G���[�E���b�Z�[�W  --# �Œ� #
                 ,retcode          OUT VARCHAR2      )        -- ���^�[���E�R�[�h    --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';                             -- �v���O������
--
--############################  �Œ胍�[�J���ϐ��錾�� START  ############################
--
    lv_errbuf          VARCHAR2(5000);      -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);         -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000);      -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code    VARCHAR2(100);       -- �I�����b�Z�[�W�R�[�h
--
--#####################################  �Œ蕔 END  #####################################
--
  BEGIN
--
--####################################  �Œ蕔 START  ####################################--
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
--
--#####################################  �Œ蕔 END  #####################################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain( ov_errbuf        => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
            ,ov_retcode       => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
            ,ov_errmsg        => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
--
    -- ===============================
    -- A-4.�I������
    -- ===============================
--
    -- �G���[�������̌����ݒ�
    IF (lv_retcode = cv_status_error) THEN
      gn_err_target_cnt      := 0;
      gn_new_target_cnt      := 0;
      gn_reject_target_cnt   := 0;
      gn_approval_target_cnt := 0;
      gn_cancel_target_cnt   := 0;
      gn_err_normal_cnt      := 0;
      gn_new_normal_cnt      := 0;
      gn_reject_normal_cnt   := 0;
      gn_approval_normal_cnt := 0;
      gn_cancel_normal_cnt   := 0;
      gn_error_cnt           := 1;
    END IF;
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error ) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg                --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf                --�G���[���b�Z�[�W
      );
    END IF;
--
    -- ===============================
    -- 1.�����������b�Z�[�W�o��
    -- ===============================
    -- �Ώی����o��(�C���|�[�g�G���[)
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                           ,iv_name         => cv_target_err_msg
                                           ,iv_token_name1  => cv_cnt_token
                                           ,iv_token_value1 => TO_CHAR ( gn_err_target_cnt )
                                           );
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => gv_out_msg
    );
    -- �Ώی����o��(�V�K)
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                           ,iv_name         => cv_target_new_msg
                                           ,iv_token_name1  => cv_cnt_token
                                           ,iv_token_value1 => TO_CHAR ( gn_new_target_cnt )
                                           );
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => gv_out_msg
    );
    -- �Ώی����o��(�p��)
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                           ,iv_name         => cv_target_rej_msg
                                           ,iv_token_name1  => cv_cnt_token
                                           ,iv_token_value1 => TO_CHAR ( gn_reject_target_cnt )
                                           );
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => gv_out_msg
    );
    -- �Ώی����o��(���F)
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                           ,iv_name         => cv_target_app_msg
                                           ,iv_token_name1  => cv_cnt_token
                                           ,iv_token_value1 => TO_CHAR ( gn_approval_target_cnt )
                                           );
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => gv_out_msg
    );
    -- �Ώی����o��(���)
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                           ,iv_name         => cv_target_canc_msg
                                           ,iv_token_name1  => cv_cnt_token
                                           ,iv_token_value1 => TO_CHAR ( gn_cancel_target_cnt )
                                           );
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => gv_out_msg
    );
--
    -- ���������o��(�C���|�[�g�G���[)
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                           ,iv_name         => cv_success_err_msg
                                           ,iv_token_name1  => cv_cnt_token
                                           ,iv_token_value1 => TO_CHAR ( gn_err_normal_cnt )
                                           );
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => gv_out_msg
    );
    -- ���������o��(���F)
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                           ,iv_name         => cv_success_new_msg
                                           ,iv_token_name1  => cv_cnt_token
                                           ,iv_token_value1 => TO_CHAR ( gn_new_normal_cnt )
                                           );
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => gv_out_msg
    );
    -- ���������o��(�V�K)
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                           ,iv_name         => cv_success_rej_msg
                                           ,iv_token_name1  => cv_cnt_token
                                           ,iv_token_value1 => TO_CHAR ( gn_reject_normal_cnt )
                                           );
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => gv_out_msg
    );
    -- ���������o��(���F)
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                           ,iv_name         => cv_success_app_msg
                                           ,iv_token_name1  => cv_cnt_token
                                           ,iv_token_value1 => TO_CHAR ( gn_approval_normal_cnt )
                                           );
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => gv_out_msg
    );
    -- ���������o��(���)
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                           ,iv_name         => cv_success_canc_msg
                                           ,iv_token_name1  => cv_cnt_token
                                           ,iv_token_value1 => TO_CHAR ( gn_cancel_normal_cnt )
                                           );
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => gv_out_msg
    );
    -- �G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxccp_appl_name
                                           ,iv_name         => cv_error_rec_msg
                                           ,iv_token_name1  => cv_cnt_token
                                           ,iv_token_value1 => TO_CHAR ( gn_error_cnt )
                                           );
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => gv_out_msg
    );
--
    -- ===============================
    -- 2.�����I�����b�Z�[�W
    -- ===============================
    IF ( lv_retcode    = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
--
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application => cv_xxccp_appl_name
                                           ,iv_name        => lv_message_code
                                           );
--
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => gv_out_msg
    );
--
    -- �X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    -- �I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
--
--################################  �Œ��O������ START  ################################
--
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
--
--#####################################  �Œ蕔 END  #####################################
--
  END main;
--
END XXCOK024A48C;
/
