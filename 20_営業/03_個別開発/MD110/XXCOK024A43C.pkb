CREATE OR REPLACE PACKAGE BODY APPS.XXCOK024A43C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2022. All rights reserved.
 *
 * Package Name     : XXCOK024A43C (body)
 * Description      : ���������ς�AR������͓`�[������ɁA�����ς̍T���f�[�^���J�����܂��B
 * MD.050           : �������E��������������� MD050_COK_024_A43
 * Version          : 1.1
 * Program List
 * ----------------------------------------------------------------------------------------
 *  Name                    Description
 * ----------------------------------------------------------------------------------------
 *  init                    A-1.��������
 *  cancel_deduction        A-3.���������̎������(A-2.AR������͏�񒊏o���܂�)
 *  update_recon_head       A-4.�T�������w�b�_�[���X�V
 *  update_sales_deduction  A-5.�̔��T�����X�V
 *  update_sales_dedu_ctrl  A-6.�̔��T���Ǘ����X�V
 *  submain                 ���C�������v���V�[�W��
 *  main                    �R���J�����g���s�t�@�C���o�^�v���V�[�W��(A-7.�I���������܂�)
 *
 * Change Record
 * ------------- -------------------------------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- -------------------------------------------------------------------------
 *  2022/11/07    1.0   R.Oikawa         �V�K�쐬
 *  2024/03/12    1.1   SCSK Y.Koh       [E_�{�ғ�_19496] �O���[�v��Г����Ή�
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
  cv_pkg_name                   CONSTANT VARCHAR2(20) := 'XXCOK024A43C';                   -- �p�b�P�[�W��
  -- �A�v���P�[�V�����Z�k��
  cv_xxccp_appl_name            CONSTANT VARCHAR2(10) := 'XXCCP';                          -- ���ʗ̈�Z�k�A�v����
  cv_xxcok_short_nm             CONSTANT VARCHAR2(10) := 'XXCOK';                          -- �ʊJ���̈�Z�k�A�v����
  cv_appl_name_sqlgl            CONSTANT VARCHAR2(10) := 'SQLGL';
  -- ���b�Z�[�W����
  cv_msg_cok_10592              CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10592';               -- �O�񏈗����擾�G���[
  cv_msg_cok_10732              CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10732';               -- ���b�N�G���[���b�Z�[�W
  cv_msg_cok_10852              CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10852';               -- ��������(�T�������w�b�_�[���)���b�Z�[�W
  cv_msg_cok_10853              CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10853';               -- ��������(AR������͖���)���b�Z�[�W
  cv_msg_ccp_90000              CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90000';               -- �Ώی������b�Z�[�W
  cv_msg_ccp_90002              CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90002';               -- �G���[�������b�Z�[�W
  cv_msg_ccp_90004              CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90004';               -- ����I�����b�Z�[�W
  cv_msg_ccp_90005              CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90005';               -- �x���I�����b�Z�[�W
  cv_msg_ccp_90006              CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90006';               -- �G���[�I���S���[���o�b�N
  --���b�Z�[�W������
  cv_msg_cok_10854              CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOK1-10854'; -- �T�������w�b�_�[���(���b�Z�[�W������)
  cv_msg_cok_10855              CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOK1-10855'; -- �̔��T�����(���b�Z�[�W������)
  cv_msg_cok_10856              CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOK1-10856'; -- AR������͖���(���b�Z�[�W������)
  -- �g�[�N��
  cv_profile_token              CONSTANT VARCHAR2(20) := 'PROFILE';                        -- �v���t�@�C���̃g�[�N����
  cv_cnt_token                  CONSTANT VARCHAR2(20) := 'COUNT';                          -- �������b�Z�[�W�p
  cv_tkn_table                  CONSTANT VARCHAR2(20) := 'TABLE';                          -- �e�[�u����
--
  -- �t���O
  cv_y                          CONSTANT VARCHAR2(1)  := 'Y';                              -- �l:Y
  cv_n                          CONSTANT VARCHAR2(1)  := 'N';                              -- �l:N
  -- �T�������w�b�_�[���
  cv_recon_status_cancel        CONSTANT VARCHAR2(2)  := 'CD';                             -- �����
  -- AR�������
  cv_ar_status_appr             CONSTANT VARCHAR2(2)  := '80';                             -- ���F��
  -- �������E���������t���O
  cv_ar_flag_recon              CONSTANT VARCHAR2(1)  := 'Y';                              -- ������
  cv_ar_flag_cancel             CONSTANT VARCHAR2(1)  := 'C';                              -- �����
  -- �̔��T�����
  cv_source_cate                CONSTANT VARCHAR2(1)  := 'D';                              -- �쐬���敪�F���z����
  cv_status_cancel              CONSTANT VARCHAR2(1)  := 'C';                              -- �����
  cv_cancel_flag_y              CONSTANT VARCHAR2(1)  := 'Y';                              -- �����
  -- �̔��T���A�g�Ǘ����
  cv_ar_input_flag              CONSTANT VARCHAR2(1)  := 'R';                              -- AR������͏��
  -- �`�[���
-- 2024/03/12 Ver1.1 DEL Start
--  cv_slip_type_80300            CONSTANT VARCHAR2(5)  := '80300';                          -- �������E
-- 2024/03/12 Ver1.1 DEL End
  -- �J�����_�[�I�[�v��
  cv_open                       CONSTANT VARCHAR2(1)  := 'O';                              -- �I�[�v��
  -- �J�����_�[���t
  cd_minend_date                CONSTANT DATE         := TO_DATE('2010/01/01','YYYY/MM/DD'); -- �ŏ��I�[�v�����t
  --�v���t�@�C��
  cv_set_of_bks_id              CONSTANT VARCHAR2(20) := 'GL_SET_OF_BKS_ID';              -- ��v����ID
-- 2024/03/12 Ver1.1 DEL Start
--  cv_trans_type_name_var_cons   CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOK1_RA_TRX_TYPE_VARIABLE_CONS'; -- ����^�C�v��
-- 2024/03/12 Ver1.1 DEL End
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
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
  -- ���팏��
  gn_recon_headt_normal_cnt     NUMBER;                                               -- ��������(�T�������w�b�_�[���)
  gn_receivable_normal_cnt      NUMBER;                                               -- ��������(AR������͖���)
  -- GL�L����
  gd_cancel_gl_date             DATE;                                                 -- ���GL�L����
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
    -- 1.����̏����������擾
    -- ============================================================
    gd_this_process_date  := SYSDATE;           -- ���񏈗�����
--
    -- ============================================================
    -- 2.�O��̏����������擾
    -- ============================================================
    BEGIN
    --
      SELECT  xsdc.last_cooperation_date    AS last_cooperation_date
      INTO    gd_last_process_date                -- �O�񏈗�����
      FROM    xxcok_sales_deduction_control xsdc  -- �̔��T���A�g�Ǘ����
      WHERE   xsdc.control_flag = cv_ar_input_flag
      ;
    --
    EXCEPTION
      WHEN  OTHERS THEN
        -- �O�񏈗����擾�G���[���b�Z�[�W
        lv_errmsg :=  xxccp_common_pkg.get_msg( cv_xxcok_short_nm
                                               ,cv_msg_cok_10592
                                               );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ============================================================
    -- 3.AR������̓J�����_�[��OPEN���擾
    -- ============================================================
    SELECT  MIN( gps.end_date ) cancel_gl_date
    INTO    gd_cancel_gl_date
    FROM    gl_period_statuses  gps
           ,fnd_application     fa
    WHERE   fa.application_short_name    =   cv_appl_name_sqlgl
    AND     gps.application_id           =   fa.application_id
    AND     gps.set_of_books_id          =   FND_PROFILE.VALUE( cv_set_of_bks_id )
    AND     gps.end_date                 >=  cd_minend_date
    AND     gps.adjustment_period_flag   =   cv_n
    AND     NVL(gps.attribute4, cv_open) =   cv_open
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : update_recon_head
   * Description      : A-4.�T�������w�b�_�[���X�V
   ***********************************************************************************/
  PROCEDURE update_recon_head(
                  iv_recon_slip_num IN  xxcok_deduction_recon_head.recon_slip_num%TYPE   -- �x���`�[�ԍ�
                 ,id_approval_date  IN  xxcok_deduction_recon_head.approval_date%TYPE    -- ���F��
                 ,ov_errbuf         OUT VARCHAR2      --   �G���[�E���b�Z�[�W            --# �Œ� #
                 ,ov_retcode        OUT VARCHAR2      --   ���^�[���E�R�[�h              --# �Œ� #
                 ,ov_errmsg         OUT VARCHAR2 )    --   ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_recon_head';              -- �v���O������
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
    --==============================================================
    --���b�N�擾�p�J�[�\��
    --==============================================================
    CURSOR recon_head_cur(
      iv_recon_slip_num IN xxcok_deduction_recon_head.recon_slip_num%TYPE
    )
    IS
      SELECT xdrh.recon_slip_num     AS recon_slip_num
      FROM   xxcok_deduction_recon_head xdrh
      WHERE  xdrh.recon_slip_num    = iv_recon_slip_num     -- �x���`�[�ԍ�
      FOR UPDATE OF xdrh.recon_slip_num NOWAIT
      ;
--
  BEGIN
--
--############################  �Œ�X�e�[�^�X�������� START  ############################
--
    ov_retcode  := cv_status_normal;
--
--#############################  �Œ�X�e�[�^�X�������� END  #############################
--
    OPEN  recon_head_cur(
            iv_recon_slip_num => iv_recon_slip_num
          );
    CLOSE recon_head_cur;
    --==================================
    -- �T�������w�b�_���X�V
    --==================================
    UPDATE  xxcok_deduction_recon_head xdrh
    SET     xdrh.recon_status            = cv_recon_status_cancel        -- �����X�e�[�^�X�i����ςɍX�V�j
           ,xdrh.cancellation_date       = id_approval_date              -- �����
           ,xdrh.cancel_gl_date          = DECODE(xdrh.gl_if_flag, cv_n, xdrh.gl_date
                                             , gd_cancel_gl_date)        -- ���GL�L����
           ,xdrh.last_updated_by         = cn_last_updated_by            -- �ŏI�X�V��
           ,xdrh.last_update_date        = cd_last_update_date           -- �ŏI�X�V��
           ,xdrh.last_update_login       = cn_last_update_login          -- �ŏI�X�V���O�C��
           ,xdrh.request_id              = cn_request_id                 -- �v��ID
           ,xdrh.program_application_id  = cn_program_application_id     -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
           ,xdrh.program_id              = cn_program_id                 -- �R���J�����g�E�v���O����ID
           ,xdrh.program_update_date     = cd_program_update_date        -- �v���O�����X�V��
    WHERE   xdrh.recon_slip_num          = iv_recon_slip_num             -- �x���`�[�ԍ�
    ;
--
    -- �T�������w�b�_�̍X�V����
    gn_recon_headt_normal_cnt := gn_recon_headt_normal_cnt + SQL%ROWCOUNT;
--
  EXCEPTION
--
    -- ���b�N�G���[
    WHEN lock_expt THEN
      -- �J�[�\���N���[�Y
      IF ( recon_head_cur%ISOPEN ) THEN
        CLOSE recon_head_cur;
      END IF;
      -- ���b�N�G���[���b�Z�[�W
      lv_errmsg      := xxccp_common_pkg.get_msg( iv_application   => cv_xxcok_short_nm
                                                 ,iv_name          => cv_msg_cok_10732
                                                 ,iv_token_name1   => cv_tkn_table
                                                 ,iv_token_value1  => cv_msg_cok_10854            -- ������u�T�������w�b�_�[���v
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
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
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
--#################################  �Œ��O������ END  #################################
--
  END update_recon_head;
--
  /**********************************************************************************
   * Procedure Name   : update_sales_deduction
   * Description      : A-5.�̔��T�����X�V
   ***********************************************************************************/
  PROCEDURE update_sales_deduction(
                  iv_recon_slip_num IN  xxcok_sales_deduction.recon_slip_num%TYPE        -- �x���`�[�ԍ�
                 ,ov_errbuf         OUT VARCHAR2      --   �G���[�E���b�Z�[�W            --# �Œ� #
                 ,ov_retcode        OUT VARCHAR2      --   ���^�[���E�R�[�h              --# �Œ� #
                 ,ov_errmsg         OUT VARCHAR2 )    --   ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_sales_deduction';              -- �v���O������
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
    -- *** ���[�J����O ***
    lock_expt       EXCEPTION;
    PRAGMA EXCEPTION_INIT(lock_expt, -54);                  -- ���b�N�G���[
--
    -- *** ���[�J���E�J�[�\�� ***
    --==============================================================
    --���b�N�擾�p�J�[�\��
    --==============================================================
    CURSOR sales_deduction_cur(
      iv_recon_slip_num IN xxcok_deduction_recon_head.recon_slip_num%TYPE
    )
    IS
      SELECT xsd.recon_slip_num    AS recon_slip_num
      FROM   xxcok_sales_deduction xsd
      WHERE  xsd.recon_slip_num    = iv_recon_slip_num     -- �x���`�[�ԍ�
      FOR UPDATE OF xsd.recon_slip_num NOWAIT
      ;
--
  BEGIN
--
--############################  �Œ�X�e�[�^�X�������� START  ############################
--
    ov_retcode  := cv_status_normal;
--
--#############################  �Œ�X�e�[�^�X�������� END  #############################
--
    OPEN  sales_deduction_cur(
            iv_recon_slip_num => iv_recon_slip_num
          );
    CLOSE sales_deduction_cur;
    --==================================
    -- �T���f�[�^
    -- �̔��T�������X�V
    --==================================
    UPDATE xxcok_sales_deduction xsd
    SET    xsd.recon_slip_num          = NULL                          -- �x���`�[�ԍ�
          ,xsd.carry_payment_slip_num  = NULL                          -- �J�z���x���`�[�ԍ�
          ,xsd.last_updated_by         = cn_last_updated_by            -- �ŏI�X�V��
          ,xsd.last_update_date        = cd_last_update_date           -- �ŏI�X�V��
          ,xsd.last_update_login       = cn_last_update_login          -- �ŏI�X�V���O�C��
          ,xsd.request_id              = cn_request_id                 -- �v��ID
          ,xsd.program_application_id  = cn_program_application_id     -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          ,xsd.program_id              = cn_program_id                 -- �R���J�����g�E�v���O����ID
          ,xsd.program_update_date     = cd_program_update_date        -- �v���O�����X�V��
    WHERE  xsd.recon_slip_num          = iv_recon_slip_num             -- �x���`�[�ԍ�
    AND    xsd.source_category        != cv_source_cate                -- �쐬���敪
    ;
--
    --==================================
    -- �T���f�[�^�i���z�j
    -- �̔��T�������X�V
    --==================================
    UPDATE xxcok_sales_deduction xsd
    SET    xsd.status                  = cv_status_cancel              -- �X�e�[�^�X
          ,xsd.recovery_del_date       = SYSDATE                       -- ���J�o���f�[�^�폜�����t
          ,xsd.recovery_del_request_id = fnd_global.conc_request_id    -- ���J�o���f�[�^�폜���v��ID
          ,xsd.cancel_flag             = cv_cancel_flag_y              -- ����t���O
          ,xsd.last_updated_by         = cn_last_updated_by            -- �ŏI�X�V��
          ,xsd.last_update_date        = cd_last_update_date           -- �ŏI�X�V��
          ,xsd.last_update_login       = cn_last_update_login          -- �ŏI�X�V���O�C��
          ,xsd.request_id              = cn_request_id                 -- �v��ID
          ,xsd.program_application_id  = cn_program_application_id     -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          ,xsd.program_id              = cn_program_id                 -- �R���J�����g�E�v���O����ID
          ,xsd.program_update_date     = cd_program_update_date        -- �v���O�����X�V��
    WHERE  xsd.recon_slip_num          = iv_recon_slip_num             -- �x���`�[�ԍ�
    AND    xsd.source_category         = cv_source_cate                -- �쐬���敪
    ;
--
  EXCEPTION
--
    -- ���b�N�G���[
    WHEN lock_expt THEN
      -- �J�[�\���N���[�Y
      IF ( sales_deduction_cur%ISOPEN ) THEN
        CLOSE sales_deduction_cur;
      END IF;
      -- ���b�N�G���[���b�Z�[�W
      lv_errmsg      := xxccp_common_pkg.get_msg( iv_application   => cv_xxcok_short_nm
                                                 ,iv_name          => cv_msg_cok_10732
                                                 ,iv_token_name1   => cv_tkn_table
                                                 ,iv_token_value1  => cv_msg_cok_10855            -- ������u�̔��T�����v
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
      IF ( sales_deduction_cur%ISOPEN ) THEN
        CLOSE sales_deduction_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\���N���[�Y
      IF ( sales_deduction_cur%ISOPEN ) THEN
        CLOSE sales_deduction_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\���N���[�Y
      IF ( sales_deduction_cur%ISOPEN ) THEN
        CLOSE sales_deduction_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���N���[�Y
      IF ( sales_deduction_cur%ISOPEN ) THEN
        CLOSE sales_deduction_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--#################################  �Œ��O������ END  #################################
--
  END update_sales_deduction;
--
  /**********************************************************************************
   * Procedure Name   : cancel_deduction
   * Description      : A-3.���������̎������
   ***********************************************************************************/
  PROCEDURE cancel_deduction(
                  ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
                 ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
                 ,ov_errmsg     OUT VARCHAR2 )   --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'cancel_deduction';                    -- �v���O������
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
--
    -- *** ���[�J���E�J�[�\�� ***
    -- ===============================
    -- A-2�DAR������͏�񒊏o
    -- ===============================
    CURSOR get_receivable_slips_cur
    IS
      SELECT  xrss.receivable_num || '-' || xrsl.line_number   AS receivable_num     -- �x���`�[�ԍ�
             ,xrsl.receivable_line_id                          AS receivable_line_id -- ����ID
             ,TRUNC(xrsc.approval_date)                        AS approval_date      -- ���F��
      FROM    xx03.xx03_receivable_slips xrsc                                        -- AR������̓w�b�_(���)
             ,xx03.xx03_receivable_slips_line xrslc                                  -- AR���喾��(���)
             ,xx03.xx03_receivable_slips xrss                                        -- AR������̓w�b�_(��)
             ,xx03.xx03_receivable_slips_line xrsl                                   -- AR������͖���(��)
      WHERE   xrsc.orig_invoice_num      = xrss.receivable_num                       -- �x���`�[�ԍ�(���Ǝ��)
      AND     xrsc.org_id                = xrss.org_id                               -- �g�DID(���Ǝ��)
      AND     xrsc.receivable_id         = xrslc.receivable_id                       -- �`�[ID(���)
      AND     xrslc.line_number          = xrsl.line_number                          -- ���הԍ�(���Ǝ��)
      AND     xrss.receivable_id         = xrsl.receivable_id                        -- �`�[ID(��)
-- 2024/03/12 Ver1.1 DEL Start
--      AND     xrsc.slip_type             = cv_slip_type_80300                        -- �`�[���
-- 2024/03/12 Ver1.1 DEL End
      AND     xrsc.orig_invoice_num IS NOT NULL                                      -- �C�����`�[�ԍ�
      AND     xrsc.wf_status             = cv_ar_status_appr                         -- �X�e�[�^�X�i���F�ρj
      AND     xrsc.approval_date         > gd_last_process_date                      -- ���F��(�O�񏈗�����)
      AND     xrsc.approval_date        <= gd_this_process_date                      -- ���F��(���񏈗�����)
      AND     NVL(xrsl.attribute8 ,cv_n) = cv_ar_flag_recon                          -- �������E���������t���O
      FOR UPDATE OF xrsl.receivable_line_id NOWAIT
      ;
    -- �J�[�\�����R�[�h�^
    get_receivable_slips_rec  get_receivable_slips_cur%ROWTYPE;
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
    -- �J�[�\���擾
    <<cancel_loop>>
    FOR get_receivable_slips_rec IN get_receivable_slips_cur LOOP
      -- �Ώی����J�E���g
      gn_target_cnt := gn_target_cnt + 1;
--
      -- ===============================
      -- A-4.�T�������w�b�_�[���X�V
      -- ===============================
      update_recon_head(
            iv_recon_slip_num => get_receivable_slips_rec.receivable_num        -- �x���`�[�ԍ�
           ,id_approval_date  => get_receivable_slips_rec.approval_date         -- ���F��
           ,ov_errbuf         => lv_errbuf                                      -- �G���[�E���b�Z�[�W           -- # �Œ� #
           ,ov_retcode        => lv_retcode                                     -- ���^�[���E�R�[�h             -- # �Œ� #
           ,ov_errmsg         => lv_errmsg                                      -- ���[�U�[�E�G���[�E���b�Z�[�W -- # �Œ� #
      );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- A-5.�̔��T�����X�V
      -- ===============================
      update_sales_deduction(
            iv_recon_slip_num => get_receivable_slips_rec.receivable_num        -- �x���`�[�ԍ�
           ,ov_errbuf         => lv_errbuf                                      -- �G���[�E���b�Z�[�W           -- # �Œ� #
           ,ov_retcode        => lv_retcode                                     -- ���^�[���E�R�[�h             -- # �Œ� #
           ,ov_errmsg         => lv_errmsg                                      -- ���[�U�[�E�G���[�E���b�Z�[�W -- # �Œ� #
      );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- AR������͖��׍X�V
      -- ===============================
      BEGIN
        -- AR������͖��ׂ��X�V
        UPDATE xx03.xx03_receivable_slips_line xrsl
        SET    xrsl.attribute8               = cv_ar_flag_cancel             -- �������E���������t���O
              ,xrsl.last_updated_by          = cn_last_updated_by            -- �ŏI�X�V��
              ,xrsl.last_update_date         = cd_last_update_date           -- �ŏI�X�V��
              ,xrsl.last_update_login        = cn_last_update_login          -- �ŏI�X�V���O�C��
              ,xrsl.request_id               = cn_request_id                 -- �v��ID
              ,xrsl.program_application_id   = cn_program_application_id     -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
              ,xrsl.program_id               = cn_program_id                 -- �R���J�����g�E�v���O����ID
              ,xrsl.program_update_date      = cd_program_update_date        -- �v���O�����X�V��
        WHERE  xrsl.receivable_line_id       = get_receivable_slips_rec.receivable_line_id
        ;
        -- AR������͖��׍X�V�̍X�V����
        gn_receivable_normal_cnt := gn_receivable_normal_cnt + SQL%ROWCOUNT;
--
      END;
--
    END LOOP cancel_loop;
--
  EXCEPTION
    -- ���b�N�G���[
    WHEN lock_expt THEN
      -- ���b�N�G���[���b�Z�[�W
      lv_errmsg      := xxccp_common_pkg.get_msg( iv_application   => cv_xxcok_short_nm
                                                 ,iv_name          => cv_msg_cok_10732
                                                 ,iv_token_name1   => cv_tkn_table
                                                 ,iv_token_value1  => cv_msg_cok_10856            -- ������uAR������͖��ׁv
                                                 );
      lv_errbuf      := lv_errmsg;
      ov_errmsg      := lv_errmsg;
      ov_errbuf      := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode     := cv_status_error;
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
--#################################  �Œ��O������ END  #################################
--
  END cancel_deduction;
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
    WHERE   xsdc.control_flag             = cv_ar_input_flag
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
    gn_target_cnt                 := 0;                   -- �Ώی���
    gn_recon_headt_normal_cnt     := 0;                   -- ��������(�T�������w�b�_�[���)
    gn_receivable_normal_cnt      := 0;                   -- ��������(AR������͖���)
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
    -- A-3.���������̎������
    -- ===============================
    cancel_deduction(
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
    -- A-6.�I������
    -- ===============================
--
    -- �G���[�������̌����ݒ�
    IF (lv_retcode = cv_status_error) THEN
      gn_target_cnt             := 0;
      gn_recon_headt_normal_cnt := 0;
      gn_receivable_normal_cnt  := 0;
      gn_error_cnt              := 1;
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
    -- �Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxccp_appl_name
                                           ,iv_name         => cv_msg_ccp_90000
                                           ,iv_token_name1  => cv_cnt_token
                                           ,iv_token_value1 => TO_CHAR ( gn_target_cnt )
                                           );
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => gv_out_msg
    );
    -- ���������o��(�T�������w�b�_�[���)
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                           ,iv_name         => cv_msg_cok_10852
                                           ,iv_token_name1  => cv_cnt_token
                                           ,iv_token_value1 => TO_CHAR ( gn_recon_headt_normal_cnt )
                                           );
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => gv_out_msg
    );
    -- ���������o��(AR������͖���)
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                           ,iv_name         => cv_msg_cok_10853
                                           ,iv_token_name1  => cv_cnt_token
                                           ,iv_token_value1 => TO_CHAR ( gn_receivable_normal_cnt )
                                           );
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => gv_out_msg
    );
    -- �G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxccp_appl_name
                                           ,iv_name         => cv_msg_ccp_90002
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
      lv_message_code := cv_msg_ccp_90004;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_msg_ccp_90005;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_msg_ccp_90006;
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
END XXCOK024A43C;
/
