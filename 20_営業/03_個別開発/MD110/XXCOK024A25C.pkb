CREATE OR REPLACE PACKAGE BODY APPS.XXCOK024A25C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A25C (body)
 * Description      : AP������͂̓`�[�̃X�e�[�^�X�ɏ]���A
 *                  : �T���z�̎x�� (AP�x��) ��ʂ̏����X�e�[�^�X���X�V���܂��B
 * MD.050           : AP������͘A�g MD050_COK_024_A25
 * Version          : 1.2
 * Program List
 * ----------------------------------------------------------------------------------------
 *  Name                    Description
 * ----------------------------------------------------------------------------------------
 *  init                    A-1.��������
 *  get_recon_header        A-2.�T�������w�b�_�[��񒊏o
 *  status_reflect_rej_appr A-3.�X�e�[�^�X���f���� (�p���E���F)
 *  get_cancel_slip         A-4.����`�[���o
 *  status_reflect_cancel   A-5.�X�e�[�^�X���f���� (���)
 *  update_sales_dedu_ctrl  A-6.�̔��T���Ǘ����X�V
 *  submain                 ���C�������v���V�[�W��
 *  main                    �R���J�����g���s�t�@�C���o�^�v���V�[�W��(A-7.�I���������܂�)
 *
 * Change Record
 * ------------- -------------------------------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- -------------------------------------------------------------------------
 *  2020/05/15    1.0   M.Sato           �V�K�쐬
 *  2021/09/27    1.1   K.Yoshikawa      E_�{�ғ�_17557
 *  2022/04/19    1.2   SCSK Y.Koh       E_�{�ғ�_18172  �T���x���`�[������̍��z
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
  cv_pkg_name              CONSTANT VARCHAR2(20) := 'XXCOK024A25C';                   -- �p�b�P�[�W��
  -- �A�v���P�[�V�����Z�k��
  cv_xxccp_appl_name       CONSTANT VARCHAR2(10) := 'XXCCP';                          -- ���ʗ̈�Z�k�A�v����
  cv_xxcok_short_nm        CONSTANT VARCHAR2(10) := 'XXCOK';                          -- �ʊJ���̈�Z�k�A�v����
  -- ���b�Z�[�W����
  cv_last_process_msg      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10592';               -- �O�񏈗����擾�G���[
  cv_table_lock_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10632';               -- ���b�N�G���[���b�Z�[�W
  cv_target_rej_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10712';               -- �Ώی���(�p��)���b�Z�[�W
  cv_target_app_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10713';               -- �Ώی���(���F)���b�Z�[�W
  cv_target_canc_msg       CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10714';               -- �Ώی���(���)���b�Z�[�W
  cv_success_rej_msg       CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10715';               -- ��������(�p��)���b�Z�[�W
  cv_success_app_msg       CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10716';               -- ��������(���F)���b�Z�[�W
  cv_success_canc_msg      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10717';               -- ��������(���)���b�Z�[�W
  cv_error_rec_msg         CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90002';               -- �G���[�������b�Z�[�W
  cv_normal_msg            CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90004';               -- ����I�����b�Z�[�W
  cv_warn_msg              CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90005';               -- �x���I�����b�Z�[�W
  cv_error_msg             CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90006';               -- �G���[�I���S���[���o�b�N
  -- �g�[�N��
  cv_cnt_token             CONSTANT VARCHAR2(20) := 'COUNT';                          -- �������b�Z�[�W�p�g�[�N��
  -- �t���O�E�敪�萔
  cv_y_flag                CONSTANT VARCHAR2(1)  := 'Y';                              -- �t���O�l:Y
  -- �̔��T���A�g�Ǘ����
  cv_ap_input_flag         CONSTANT VARCHAR2(1)  := 'P';                              -- AP������͏��
  -- �T�������w�b�_�[���
  cv_interface_div         CONSTANT VARCHAR2(2)  := 'AP';                             -- AP�x��
  cv_recon_status_transmit CONSTANT VARCHAR2(2)  := 'SD';                             -- ���M��
  cv_recon_status_deleted  CONSTANT VARCHAR2(2)  := 'DD';                             -- �폜��
  cv_recon_status_appr     CONSTANT VARCHAR2(2)  := 'AD';                             -- ���F��
  cv_recon_status_cancel   CONSTANT VARCHAR2(2)  := 'CD';                             -- �����
  -- AP�������
  cv_ap_status_reject      CONSTANT VARCHAR2(2)  := '10';                             -- �p��
  cv_ap_status_appr        CONSTANT VARCHAR2(2)  := '80';                             -- ���F��
  cv_slip_type             CONSTANT VARCHAR2(10) := '30000';                          -- �̔��T��
  -- �̔��T�����
  cv_source_cate           CONSTANT VARCHAR2(1)  := 'D';                              -- �쐬���敪�F���z����
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �T�������w�b�_���o���R�[�h�^��`
  TYPE g_recon_header_rtype IS RECORD(
       recon_head_id       xxcok_deduction_recon_head.deduction_recon_head_id%TYPE    -- �T�������w�b�_�[ID
      ,recon_slip_num      xxcok_deduction_recon_head.recon_slip_num%TYPE             -- �x���`�[�ԍ�
  );
  -- �T�������w�b�_���o���[�N�e�[�u���^��`
  TYPE g_recon_head_ttype IS TABLE OF g_recon_header_rtype INDEX BY BINARY_INTEGER;
  -- �T�������w�b�_���o�e�[�u���^�ϐ�
  g_recon_head_tbl         g_recon_head_ttype;                                        -- �T�������w�b�_���o
--
  -- AP������͒��o���R�[�h�^��`
  TYPE g_ap_input_rtype IS RECORD(
       status              xx03_payment_slips.wf_status%TYPE                          -- �X�e�[�^�X
      ,approval_date       xx03_payment_slips.approval_date%TYPE                      -- ���F��
      ,approver            per_all_people_f.employee_number%TYPE                      -- ���F��
  );
  -- AP������͒��o���[�N�e�[�u���^��`
  TYPE g_ap_input_ttype IS TABLE OF g_ap_input_rtype INDEX BY BINARY_INTEGER;
  -- AP������͒��o�e�[�u���^�ϐ�
  g_ap_input_tbl           g_ap_input_ttype;                                          -- AP������̓X�e�[�^�X���o
--
  -- ����`�[���o�^��`
  TYPE g_cancel_slip_rtype IS RECORD(
       recon_slip_num      xx03_payment_slips.description%TYPE                        -- �x���`�[�ԍ�
      ,approval_date       xx03_payment_slips.approval_date%TYPE                      -- ���F��
  );
  -- ����`�[���o���[�N�e�[�u���^��`
  TYPE g_cancel_slip_ttype IS TABLE OF g_cancel_slip_rtype INDEX BY BINARY_INTEGER;
  -- ����`�[���o�e�[�u���^�ϐ�
  g_cancel_slip_tbl        g_cancel_slip_ttype;                                       -- ����`�[���o
--
  -- ===============================
  -- ���[�U�[��`�O���[�o�����R�[�h
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- �����擾
  gd_last_process_date          DATE;                                                 -- �O�񏈗�����
  gd_this_process_date          DATE;                                                 -- ���񏈗�����
-- 2022/04/19 Ver1.2 ADD Start
  gd_cancel_gl_date             DATE;                                                 -- ���GL�L����
-- 2022/04/19 Ver1.2 ADD End
  -- �Ώی���
  gn_reject_target_cnt          NUMBER;                                               -- �Ώی���(�p��)
  gn_approval_target_cnt        NUMBER;                                               -- �Ώی���(���F)
  gn_cancel_target_cnt          NUMBER;                                               -- �Ώی���(���)
  -- ���팏��
  gn_reject_normal_cnt          NUMBER;                                               -- ��������(�p��)
  gn_approval_normal_cnt        NUMBER;                                               -- ��������(���F)
  gn_cancel_normal_cnt          NUMBER;                                               -- ��������(���)
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
    -- 1.�O��̏����������擾
    -- ============================================================
    BEGIN
    --
      SELECT  xsdc.last_cooperation_date    AS last_cooperation_date
      INTO    gd_last_process_date                -- �O�񏈗�����
      FROM    xxcok_sales_deduction_control xsdc  -- �̔��T���A�g�Ǘ����
      WHERE   xsdc.control_flag             = cv_ap_input_flag
      ;
    --
    EXCEPTION
      WHEN  OTHERS THEN
        -- �O�񏈗����擾�G���[���b�Z�[�W
        lv_errmsg :=  xxccp_common_pkg.get_msg( cv_xxcok_short_nm
                                               ,cv_last_process_msg
                                               );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
    END;
    -- ============================================================
    -- 2.����̏����������擾
    -- ============================================================
    gd_this_process_date  := SYSDATE;           -- ���񏈗�����
-- 2022/04/19 Ver1.2 ADD Start
    -- ============================================================
    -- 3.AP������̓J�����_�[��OPEN���擾
    -- ============================================================
    SELECT
        MIN(gps.end_date)
    INTO
        gd_cancel_gl_date
    FROM
        gl_period_statuses  gps ,
        fnd_application     fa
    WHERE
        fa.application_short_name   =   'SQLGL'
    and gps.application_id          =   fa.application_id
    and gps.set_of_books_id         =   FND_PROFILE.VALUE('GL_SET_OF_BKS_ID')
    and gps.end_date                >=  TO_DATE('2010/01/01','YYYY/MM/DD')
    and gps.adjustment_period_flag  =   'N'
    and NVL(gps.attribute1,'O')     =   'O';
-- 2022/04/19 Ver1.2 ADD End
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
   * Procedure Name   : status_reflect_rej_appr
   * Description      : A-3.�X�e�[�^�X���f���� (�p���E���F)
   ***********************************************************************************/
  PROCEDURE status_reflect_rej_appr(
                  ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
                 ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
                 ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                 ,in_get_cnt    IN  NUMBER   )   --   ���f������
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'status_reflect_rej_appr';             -- �v���O������
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
    ln_request_id               NUMBER;                                     -- �߂�l�F�v��ID
    -- *** ���[�J����O ***
--
    -- *** ���[�J���E�J�[�\�� ***
    -- AP������͒��o�J�[�\��
    CURSOR ap_input_cur
    IS
      SELECT xps.wf_status                AS status                         -- �X�e�[�^�X
            ,xps.approval_date            AS approval_date                  -- ���F��
            ,papf.employee_number         AS approver                       -- ���F��
      FROM   xx03_payment_slips           xps                               -- AP�������
            ,per_all_people_f             papf                              -- �]�ƈ�
      WHERE  xps.description              = g_recon_head_tbl(in_get_cnt).recon_slip_num
      AND    xps.wf_status               != cv_ap_status_reject
      AND    xps.orig_invoice_num         IS NULL
      AND    papf.person_id(+)            = xps.approver_person_id
      AND    TRUNC( SYSDATE )       BETWEEN papf.effective_start_date(+)
                                        AND papf.effective_end_date(+)
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
    -- �����Ώۓ`�[��AP������̓X�e�[�^�X���擾
    -- ============================================================
    -- �J�[�\���I�[�v��
    OPEN  ap_input_cur;
    -- �f�[�^�擾
    FETCH ap_input_cur BULK COLLECT INTO g_ap_input_tbl;
    -- �J�[�\���N���[�Y
    CLOSE ap_input_cur;
--
    -- �擾������0���̏ꍇ
    IF ( g_ap_input_tbl.COUNT = 0 ) THEN
      -- �Ώی���(�p��)���C���N�������g
      gn_reject_target_cnt := gn_reject_target_cnt + 1;
      -- �T�������w�b�_�[���̃X�e�[�^�X���u�폜�ρv�ɍX�V
      UPDATE  xxcok_deduction_recon_head   xdrh                             -- �T�������w�b�_�[���
      SET     xdrh.recon_status            = cv_recon_status_deleted        -- �����X�^�[�^�X
             ,xdrh.last_updated_by         = cn_last_updated_by             -- �ŏI�X�V��
             ,xdrh.last_update_date        = cd_last_update_date            -- �ŏI�X�V��
             ,xdrh.last_update_login       = cn_last_update_login           -- �ŏI�X�V���O�C��
             ,xdrh.request_id              = cn_request_id                  -- �v��ID
             ,xdrh.program_application_id  = cn_program_application_id      -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
             ,xdrh.program_id              = cn_program_id                  -- �R���J�����g�E�v���O����ID
             ,xdrh.program_update_date     = cd_program_update_date         -- �v���O�����X�V��
      WHERE   xdrh.deduction_recon_head_id = g_recon_head_tbl(in_get_cnt).recon_head_id
      ;
      -- �Y���x���̍T���f�[�^���J��
      UPDATE  xxcok_sales_deduction        xsd                              -- �̔��T�����
      SET     xsd.recon_slip_num           = NULL                           -- �x���`�[�ԍ�
             ,xsd.carry_payment_slip_num   = NULL                           -- �J�z���x���`�[�ԍ�
             ,xsd.last_updated_by          = cn_last_updated_by             -- �ŏI�X�V��
             ,xsd.last_update_date         = cd_last_update_date            -- �ŏI�X�V��
             ,xsd.last_update_login        = cn_last_update_login           -- �ŏI�X�V���O�C��
             ,xsd.request_id               = cn_request_id                  -- �v��ID
             ,xsd.program_application_id   = cn_program_application_id      -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
             ,xsd.program_id               = cn_program_id                  -- �R���J�����g�E�v���O����ID
             ,xsd.program_update_date      = cd_program_update_date         -- �v���O�����X�V��
      WHERE   xsd.recon_slip_num           = g_recon_head_tbl(in_get_cnt).recon_slip_num
      ;
      -- ��������(�p��)���C���N�������g
      gn_reject_normal_cnt := gn_reject_normal_cnt + 1;
--
    -- �擾�X�e�[�^�X�����F�ς̏ꍇ
    ELSIF ( g_ap_input_tbl(1).status = cv_ap_status_appr ) THEN
      -- �Ώی���(���F)���C���N�������g
      gn_approval_target_cnt := gn_approval_target_cnt + 1;
      -- �T�������w�b�_�[���̃X�e�[�^�X���u���F�ρv�ɍX�V
      UPDATE  xxcok_deduction_recon_head   xdrh                             -- �T�������w�b�_�[���
      SET     xdrh.recon_status            = cv_recon_status_appr           -- �����X�^�[�^�X
             ,xdrh.approval_date           = TRUNC( g_ap_input_tbl(1).approval_date )
                                                                            -- ���F��
             ,xdrh.approver                = g_ap_input_tbl(1).approver     -- ���F��
             ,xdrh.ap_ar_if_flag           = cv_y_flag                      -- AP/AR�A�g�t���O
             ,xdrh.last_updated_by         = cn_last_updated_by             -- �ŏI�X�V��
             ,xdrh.last_update_date        = cd_last_update_date            -- �ŏI�X�V��
             ,xdrh.last_update_login       = cn_last_update_login           -- �ŏI�X�V���O�C��
             ,xdrh.request_id              = cn_request_id                  -- �v��ID
             ,xdrh.program_application_id  = cn_program_application_id      -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
             ,xdrh.program_id              = cn_program_id                  -- �R���J�����g�E�v���O����ID
             ,xdrh.program_update_date     = cd_program_update_date         -- �v���O�����X�V��
      WHERE   xdrh.deduction_recon_head_id = g_recon_head_tbl(in_get_cnt).recon_head_id
      ;
      -- ��������(���F)���C���N�������g
      gn_approval_normal_cnt := gn_approval_normal_cnt + 1;
      -- �T���f�[�^���z���z���������s
      XXCOK024A19C.main( lv_errbuf
                        ,lv_retcode
                        ,lv_errmsg
                        ,g_recon_head_tbl(in_get_cnt).recon_slip_num
                        );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
  EXCEPTION
--
--################################  �Œ��O������ START  ################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- �J�[�\���N���[�Y
      IF ( ap_input_cur%ISOPEN ) THEN
        CLOSE ap_input_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\���N���[�Y
      IF ( ap_input_cur%ISOPEN ) THEN
        CLOSE ap_input_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���N���[�Y
      IF ( ap_input_cur%ISOPEN ) THEN
        CLOSE ap_input_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ END  #################################
--
  END status_reflect_rej_appr;
--
  /**********************************************************************************
   * Procedure Name   : get_recon_header
   * Description      : A-2.�T�������w�b�_�[��񒊏o
   ***********************************************************************************/
  PROCEDURE get_recon_header(
                  ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
                 ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
                 ,ov_errmsg     OUT VARCHAR2 )   --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_recon_header';                    -- �v���O������
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
    lock_expt       EXCEPTION;
    PRAGMA EXCEPTION_INIT(lock_expt, -54);                  -- ���b�N�G���[
    -- *** ���[�J���E�J�[�\�� ***
    -- �T�������w�b�_���o�J�[�\��
    CURSOR recon_head_cur
    IS
      SELECT xdrh.deduction_recon_head_id  AS recon_head_id           -- �T�������w�b�_�[ID
            ,xdrh.recon_slip_num           AS recon_slip_num          -- �x���`�[�ԍ�
      FROM   xxcok_deduction_recon_head    xdrh                       -- �T�������w�b�_�[���
      WHERE  xdrh.interface_div            = cv_interface_div
      AND    xdrh.recon_status             = cv_recon_status_transmit
      FOR UPDATE OF xdrh.deduction_recon_head_id NOWAIT
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
    -- �����Ώۏ����w�b�_���擾
    -- ============================================================
    -- �J�[�\���I�[�v��
    OPEN  recon_head_cur;
    -- �f�[�^�擾
    FETCH recon_head_cur BULK COLLECT INTO g_recon_head_tbl;
    -- �J�[�\���N���[�Y
    CLOSE recon_head_cur;
--
    -- �T�������w�b�_�̒��o������0���ȏ�̏ꍇ
    IF ( g_recon_head_tbl.COUNT > 0 ) THEN
      -- ���o�������X�e�[�^�X���f���������s
      <<reflect_rej_appr_loop>>
      FOR ln_get_cnt IN 1..g_recon_head_tbl.COUNT LOOP
        -- ===============================
        -- A-3.�X�e�[�^�X���f���� (�p���E���F)
        -- ===============================
        status_reflect_rej_appr(
            ov_errbuf   => lv_errbuf            -- �G���[�E���b�Z�[�W           -- # �Œ� #
           ,ov_retcode  => lv_retcode           -- ���^�[���E�R�[�h             -- # �Œ� #
           ,ov_errmsg   => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W -- # �Œ� #
           ,in_get_cnt  => ln_get_cnt           -- ���f������
        );
      END LOOP reflect_rej_appr_loop;
    END IF;
--
  EXCEPTION
    -- ���b�N�G���[
    WHEN lock_expt THEN
      -- �J�[�\���N���[�Y
      IF ( recon_head_cur%ISOPEN ) THEN
        CLOSE recon_head_cur;
      END IF;
      -- ���b�N�G���[���b�Z�[�W
      lv_errmsg      := xxccp_common_pkg.get_msg( cv_xxcok_short_nm
                                                 ,cv_table_lock_msg
                                                 );
      lv_errbuf      := lv_errmsg;
      ov_errmsg      := lv_errmsg;
      ov_errbuf      := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode     := cv_status_error;
--################################  �Œ��O������ START  ################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- �J�[�\���N���[�Y
      IF ( recon_head_cur%ISOPEN ) THEN
        CLOSE recon_head_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\���N���[�Y
      IF ( recon_head_cur%ISOPEN ) THEN
        CLOSE recon_head_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���N���[�Y
      IF ( recon_head_cur%ISOPEN ) THEN
        CLOSE recon_head_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ END  #################################
--
  END get_recon_header;
--
  /**********************************************************************************
   * Procedure Name   : get_cancel_slip
   * Description      : A-4.����`�[���o
   ***********************************************************************************/
  PROCEDURE get_cancel_slip(
                  ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
                 ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
                 ,ov_errmsg     OUT VARCHAR2 )   --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_cancel_slip';                     -- �v���O������
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
    -- ����`�[���o�J�[�\��
    CURSOR cancel_slip_cur
    IS
      SELECT xpss.description       AS recon_slip_num       -- �x���`�[�ԍ�
            ,xpsc.approval_date     AS approval_date        -- ���F��
      FROM   xx03_payment_slips     xpss,                   -- AP�������(���`�[)
             xx03_payment_slips     xpsc                    -- AP�������(����`�[)
      WHERE  xpsc.slip_type         =   cv_slip_type
      AND    xpsc.wf_status         =   cv_ap_status_appr
-- 2021/09/27 Ver1.1 MOD Start
--      AND    xpsc.last_update_date  >   gd_last_process_date
--      AND    xpsc.last_update_date  <=  gd_this_process_date
      AND    xpsc.approval_date  >   gd_last_process_date
      AND    xpsc.approval_date  <=  gd_this_process_date
-- 2021/09/27 Ver1.1 MOD End
      AND    xpss.invoice_num       =   xpsc.orig_invoice_num
      AND    xpss.org_id            =   xpsc.org_id
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
    OPEN  cancel_slip_cur;
    -- �f�[�^�擾
    FETCH cancel_slip_cur BULK COLLECT INTO g_cancel_slip_tbl;
    -- �J�[�\���N���[�Y
    CLOSE cancel_slip_cur;
    -- �Ώی���(���)�ɒ��o�������i�[
    gn_cancel_target_cnt := g_cancel_slip_tbl.COUNT;
--
  EXCEPTION
--################################  �Œ��O������ START  ################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- �J�[�\���N���[�Y
      IF ( cancel_slip_cur%ISOPEN ) THEN
        CLOSE cancel_slip_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\���N���[�Y
      IF ( cancel_slip_cur%ISOPEN ) THEN
        CLOSE cancel_slip_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���N���[�Y
      IF ( cancel_slip_cur%ISOPEN ) THEN
        CLOSE cancel_slip_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ END  #################################
--
  END get_cancel_slip;
--
  /**********************************************************************************
   * Procedure Name   : status_reflect_cancel
   * Description      : A-5.�X�e�[�^�X���f���� (���)
   ***********************************************************************************/
  PROCEDURE status_reflect_cancel(
                  ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
                 ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
                 ,ov_errmsg     OUT VARCHAR2 )   --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'status_reflect_cancel';               -- �v���O������
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
    <<reflect_cancel_loop>>
    FOR ln_get_cnt IN 1..g_cancel_slip_tbl.COUNT LOOP
      BEGIN
        -- �T�������w�b�_�[���b�N����
        SELECT 1  AS dummy
        INTO   ln_dummy
        FROM   xxcok_deduction_recon_head    xdrh                       -- �T�������w�b�_�[���
        WHERE  xdrh.recon_slip_num           = g_cancel_slip_tbl(ln_get_cnt).recon_slip_num
        FOR UPDATE OF xdrh.deduction_recon_head_id NOWAIT
        ;
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
      BEGIN
        -- �̔��T����񃍃b�N����
        SELECT 1  AS dummy
        INTO   ln_dummy
        FROM   xxcok_sales_deduction         xsd                        -- �̔��T�����
        WHERE  xsd.recon_slip_num            = g_cancel_slip_tbl(ln_get_cnt).recon_slip_num
        FOR UPDATE OF xsd.sales_deduction_id NOWAIT
        ;
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
      -- �T�������w�b�_�[���̏����X�e�[�^�X���X�V
      UPDATE  xxcok_deduction_recon_head   xdrh                             -- �T�������w�b�_�[���
      SET     xdrh.recon_status            = cv_recon_status_cancel         -- �����X�^�[�^�X
             ,xdrh.cancellation_date       = TRUNC( g_cancel_slip_tbl(ln_get_cnt).approval_date )
                                                                            -- �����
-- 2022/04/19 Ver1.2 ADD Start
             ,xdrh.cancel_gl_date          = DECODE(xdrh.gl_if_flag, 'N', xdrh.gl_date, gd_cancel_gl_date)
                                                                            -- ���GL�L����
-- 2022/04/19 Ver1.2 ADD End
             ,xdrh.last_updated_by         = cn_last_updated_by             -- �ŏI�X�V��
             ,xdrh.last_update_date        = cd_last_update_date            -- �ŏI�X�V��
             ,xdrh.last_update_login       = cn_last_update_login           -- �ŏI�X�V���O�C��
             ,xdrh.request_id              = cn_request_id                  -- �v��ID
             ,xdrh.program_application_id  = cn_program_application_id      -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
             ,xdrh.program_id              = cn_program_id                  -- �R���J�����g�E�v���O����ID
             ,xdrh.program_update_date     = cd_program_update_date         -- �v���O�����X�V��
      WHERE   xdrh.recon_slip_num          = g_cancel_slip_tbl(ln_get_cnt).recon_slip_num
      ;
      -- ��������(���)���C���N�������g
      gn_cancel_normal_cnt := gn_cancel_normal_cnt + 1;
--
      -- �Y���x���̍��z�����f�[�^������ςɍX�V
      UPDATE  xxcok_sales_deduction        xsd                              -- �̔��T�����
      SET     xsd.status                   = 'C'                            -- �X�e�[�^�X
             ,xsd.recovery_del_date        = SYSDATE                        -- ���J�o���f�[�^�폜�����t
             ,xsd.cancel_flag              = cv_y_flag                      -- ����t���O
             ,xsd.last_updated_by          = cn_last_updated_by             -- �ŏI�X�V��
             ,xsd.last_update_date         = cd_last_update_date            -- �ŏI�X�V��
             ,xsd.last_update_login        = cn_last_update_login           -- �ŏI�X�V���O�C��
             ,xsd.request_id               = cn_request_id                  -- �v��ID
             ,xsd.program_application_id   = cn_program_application_id      -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
             ,xsd.program_id               = cn_program_id                  -- �R���J�����g�E�v���O����ID
             ,xsd.program_update_date      = cd_program_update_date         -- �v���O�����X�V��
      WHERE   xsd.recon_slip_num           = g_cancel_slip_tbl(ln_get_cnt).recon_slip_num
      AND     xsd.source_category          = cv_source_cate
      ;
--
      -- �Y���x���̍T���f�[�^���J��
      UPDATE  xxcok_sales_deduction        xsd                              -- �̔��T�����
      SET     xsd.recon_slip_num           = NULL                           -- �x���`�[�ԍ�
             ,xsd.carry_payment_slip_num   = NULL                           -- �J�z���x���`�[�ԍ�
             ,xsd.last_updated_by          = cn_last_updated_by             -- �ŏI�X�V��
             ,xsd.last_update_date         = cd_last_update_date            -- �ŏI�X�V��
             ,xsd.last_update_login        = cn_last_update_login           -- �ŏI�X�V���O�C��
             ,xsd.request_id               = cn_request_id                  -- �v��ID
             ,xsd.program_application_id   = cn_program_application_id      -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
             ,xsd.program_id               = cn_program_id                  -- �R���J�����g�E�v���O����ID
             ,xsd.program_update_date      = cd_program_update_date         -- �v���O�����X�V��
      WHERE   xsd.recon_slip_num           = g_cancel_slip_tbl(ln_get_cnt).recon_slip_num
      AND     xsd.status                   = 'N'
      ;
    END LOOP reflect_cancel_loop;
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
  END status_reflect_cancel;
--
  /**********************************************************************************
   * Procedure Name   : update_sales_dedu_ctrl
   * Description      : A-6.�̔��T���Ǘ����X�V
   ***********************************************************************************/
  PROCEDURE update_sales_dedu_ctrl(
                  ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
                 ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
                 ,ov_errmsg     OUT VARCHAR2 )   --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_sales_dedu_ctrl';              -- �v���O������
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
    -- �̔��T���A�g�Ǘ����̍ŏI�A�g�������X�V
    UPDATE  xxcok_sales_deduction_control xsdc                            -- �̔��T���A�g�Ǘ����
    SET     xsdc.last_cooperation_date    = gd_this_process_date          -- �ŏI�A�g����
           ,xsdc.last_updated_by          = cn_last_updated_by            -- �ŏI�X�V��
           ,xsdc.last_update_date         = cd_last_update_date           -- �ŏI�X�V��
           ,xsdc.last_update_login        = cn_last_update_login          -- �ŏI�X�V���O�C��
           ,xsdc.request_id               = cn_request_id                 -- �v��ID
           ,xsdc.program_application_id   = cn_program_application_id     -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
           ,xsdc.program_id               = cn_program_id                 -- �R���J�����g�E�v���O����ID
           ,xsdc.program_update_date      = cd_program_update_date        -- �v���O�����X�V��
    WHERE   xsdc.control_flag             = cv_ap_input_flag
    ;
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
  END update_sales_dedu_ctrl;
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
    gn_reject_target_cnt          := 0;                   -- �Ώی���(�p��)
    gn_approval_target_cnt        := 0;                   -- �Ώی���(���F)
    gn_cancel_target_cnt          := 0;                   -- �Ώی���(���)
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
    -- A-2.�T�������w�b�_�[��񒊏o
    -- ===============================
    get_recon_header(
        ov_errbuf  => lv_errbuf            -- �G���[�E���b�Z�[�W           -- # �Œ� #
       ,ov_retcode => lv_retcode           -- ���^�[���E�R�[�h             -- # �Œ� #
       ,ov_errmsg  => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W -- # �Œ� #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-4.����`�[���o
    -- ===============================
    get_cancel_slip(
        ov_errbuf  => lv_errbuf          -- �G���[�E���b�Z�[�W           -- # �Œ� #
       ,ov_retcode => lv_retcode         -- ���^�[���E�R�[�h             -- # �Œ� #
       ,ov_errmsg  => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W -- # �Œ� #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ����`�[���o�̌�����1���ȏ�̏ꍇ
    IF ( g_cancel_slip_tbl.COUNT > 0 ) THEN
      -- ===============================
      -- A-5.�X�e�[�^�X���f���� (���)
      -- ===============================
      status_reflect_cancel(
          ov_errbuf  => lv_errbuf          -- �G���[�E���b�Z�[�W           -- # �Œ� #
         ,ov_retcode => lv_retcode         -- ���^�[���E�R�[�h             -- # �Œ� #
         ,ov_errmsg  => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W -- # �Œ� #
      );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- ===============================
    -- A-6.�̔��T���Ǘ����X�V
    -- ===============================
    update_sales_dedu_ctrl(
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
    -- A-7.�I������
    -- ===============================
--
    -- �G���[�������̌����ݒ�
    IF (lv_retcode = cv_status_error) THEN
      gn_reject_target_cnt   := 0;
      gn_approval_target_cnt := 0;
      gn_cancel_target_cnt   := 0;
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
    -- ���������o��(�p��)
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
END XXCOK024A25C;
/
