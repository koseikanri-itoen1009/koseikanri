CREATE OR REPLACE PACKAGE BODY APPS.XXCOK024A06C_2
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2021. All rights reserved.
 *
 * Package Name     : XXCOK024A06C_2 (body)
 * Description      : �̔��T���f�[�^GL�A�g�����ɌĂяo������
 * MD.050           : �̔��T���f�[�^GL�A�g MD050_COK_024_A06
 * Version          : 1.0
 * Program List
 * ----------------------------------------------------------------------------------------
 *  Name                   Description
 * ----------------------------------------------------------------------------------------
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��(�I���������܂�)
 *
 * Change Record
 * ------------- -------------------------------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- -------------------------------------------------------------------------
 *  2021/06/24    1.0   H.Futamura       �V�K�쐬
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
  gv_out_msg       VARCHAR2(2000);                       -- �o�̓��b�Z�[�W
  gn_normal_cnt    NUMBER   DEFAULT 0;                   -- �R���J�����g��������
  gn_target_cnt    NUMBER   DEFAULT 0;                   -- ��������
  gn_error_cnt     NUMBER   DEFAULT 0;                   -- �R���J�����g�G���[����
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
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--###############################  �Œ苤�ʗ�O�錾�� END  ###############################
--
  gd_process_date           DATE     DEFAULT NULL;   -- �Ɩ��������t
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  -- �p�b�P�[�W��
  cv_pkg_name               CONSTANT VARCHAR2(20)  := 'XXCOK024A06C_2';               -- �p�b�P�[�W��
  -- �A�v���P�[�V�����Z�k��
  cv_xxcok_short_nm         CONSTANT VARCHAR2(10)  := 'XXCOK';                        -- �ʊJ���̈�Z�k�A�v����
  cv_xxccp_short_nm         CONSTANT VARCHAR2(10)  := 'XXCCP';                        -- ���ʁEIF�̈�Z�k�A�v����
  -- ���b�Z�[�W����
  cv_process_date_msg       CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-00028';             -- �Ɩ����t�擾�G���[
  -- �N�C�b�N�R�[�h
  cv_lookup_dedu_code       CONSTANT VARCHAR2(30)  := 'XXCOK1_DEDUCTION_DATA_TYPE';   -- �T���f�[�^���
  -- �L���t���O
  cv_yes                    CONSTANT VARCHAR2(1)   := 'Y';
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : �T�u���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain( ov_errbuf    OUT VARCHAR2             --   �G���[�E���b�Z�[�W           --# �Œ� #
                   , ov_retcode   OUT VARCHAR2             --   ���^�[���E�R�[�h             --# �Œ� #
                   , ov_errmsg    OUT VARCHAR2 )           --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain';                -- �v���O������
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
    cv_program                  CONSTANT VARCHAR2(20) := 'XXCOK024A06C'; -- �R���J�����g:�̔��T���f�[�^GL�A�g
    cb_sub_request              CONSTANT BOOLEAN      := FALSE;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- GL�A�g�p���������s�O���[�v�擾���[�N�e�[�u��
    TYPE gr_deductions_para_group_rec IS RECORD(
        para_group        fnd_lookup_values_vl.attribute13%TYPE             -- GL�A�g�p���������s�O���[�v
    );
  -- GL�A�g�p���������s�O���[�v�擾
    TYPE g_deductions_para_group_ttype  IS TABLE OF gr_deductions_para_group_rec INDEX BY BINARY_INTEGER;
      g_deductions_para_group_tab        g_deductions_para_group_ttype;
--
    -- *** ���[�J���ϐ� ***
    ln_request_id            NUMBER;
--
    -- *** ���[�J����O ***
    submit_err_expt          EXCEPTION;
--
    -- *** ���[�J���E�J�[�\�� ***
    --GL�A�g�p���������s�O���[�v�擾
    CURSOR deductions_para_group_cur
    IS
      SELECT  distinct flvv.attribute13 para_group
      FROM    fnd_lookup_values_vl flvv
      WHERE   flvv.lookup_type   = cv_lookup_dedu_code
      AND     flvv.enabled_flag  = cv_yes
      AND     NVL( flvv.start_date_active, gd_process_date ) <= gd_process_date
      AND     NVL( flvv.end_date_active,   gd_process_date ) >= gd_process_date
      ORDER BY flvv.attribute13
      ;
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
    --==================================
    -- �P�D�Ɩ����t�擾
    --==================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
--
    -- �Ɩ����t�擾�G���[�̏ꍇ�̓G���[
    IF ( gd_process_date IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_xxcok_short_nm
                                            , cv_process_date_msg
                                             );
      lv_errbuf  := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --�J�[�\���I�[�v��
    OPEN  deductions_para_group_cur;
    FETCH deductions_para_group_cur BULK COLLECT INTO g_deductions_para_group_tab;
    CLOSE deductions_para_group_cur;
--
    -- �Ώی����J�E���g
    gn_target_cnt := g_deductions_para_group_tab.COUNT;
--
    <<para_group_loop>>
    FOR i IN 1..g_deductions_para_group_tab.COUNT LOOP
      --==================================
      -- �Q�D�̔��T���f�[�^GL�A�g�N��
      --==================================
      ln_request_id := fnd_request.submit_request(
                         application  => cv_xxcok_short_nm,
                         program      => cv_program,
                         description  => NULL,
                         start_time   => NULL,
                         sub_request  => cb_sub_request,
                         argument1    => g_deductions_para_group_tab( i ).para_group -- ���s�O���[�v
                       );
      --�R���J�����g�N���̂��߃R�~�b�g
      COMMIT;
      -- ���������J�E���g
      gn_normal_cnt := gn_normal_cnt + 1;
    END LOOP para_group_loop;
--
  EXCEPTION
--
--################################  �Œ��O������ START  ################################
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
      IF (deductions_para_group_cur %ISOPEN)THEN
        CLOSE deductions_para_group_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--#################################  �Œ��O������ END  #################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main( errbuf      OUT VARCHAR2               -- �G���[�E���b�Z�[�W  --# �Œ� #
                , retcode     OUT VARCHAR2 )             -- ���^�[���E�R�[�h    --# �Œ� #
                
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';              -- �v���O������
--
    cv_xxccp_appl_name CONSTANT VARCHAR2(10)  := 'XXCCP';             -- ���ʗ̈�Z�k�A�v����
    cv_target_rec_msg  CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90000';  -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90001';  -- �o�^�������b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(20)  := 'COUNT';             -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90004';  -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90005';  -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-10008';  -- �G���[�I�����b�Z�[�W
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
--####################################  �Œ蕔 START  ####################################
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
        ov_retcode => lv_retcode
      , ov_errbuf  => lv_errbuf
      , ov_errmsg  => lv_errmsg
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
    submain( ov_errbuf  => lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
           , ov_retcode => lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
           , ov_errmsg  => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
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
    -- �I������
    -- ===============================
    --��s�}��
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
      , buff  => ''
    );
--
    --�����Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxccp_appl_name
                                          , iv_name         => cv_target_rec_msg
                                          , iv_token_name1  => cv_cnt_token
                                          , iv_token_value1 => TO_CHAR ( gn_target_cnt )
                                          );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --�o�^�����o��
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxccp_appl_name
                                          , iv_name         => cv_success_rec_msg
                                          , iv_token_name1  => cv_cnt_token
                                          , iv_token_value1 => TO_CHAR ( gn_normal_cnt )
                                          );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --�I�����b�Z�[�W
    IF ( lv_retcode    = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
--
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application => cv_xxccp_appl_name
                                          , iv_name        => lv_message_code
                                          );
--
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
      , buff  => gv_out_msg
    );
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    ELSE
      COMMIT;
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
  END main;
--
--#####################################  �Œ蕔 END  #####################################
--
END XXCOK024A06C_2;
/
