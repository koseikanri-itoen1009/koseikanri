CREATE OR REPLACE PACKAGE BODY APPS.XXCCP009A16C
AS
/*****************************************************************************************
 *
 * Package Name     :  XXCCP009A16C(body)
 * Description      : GL�C���^�[�t�F�[�X�G���[���m
 * Version          : 1.0
 * Program List
 * ------------------------- ------------------------------------------------------------
 *  Name                      Description
 * ------------------------- ------------------------------------------------------------
 *  submain                  ���C�������v���V�[�W��
 *  main                     �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2019/02/27    1.0   SCSK���h�i     �V�K�쐬
 *
 *****************************************************************************************/
--
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --�x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --�ُ�:2
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gn_target_cnt    NUMBER;                    -- �Ώی���
  gn_error_cnt     NUMBER;                    -- �G���[����
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
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  -- �A�v���P�[�V�����Z�k��
  cv_appl_short_name_xxccp  CONSTANT VARCHAR2(10) := 'XXCCP';
  -- �p�b�P�[�W��
  cv_pkg_name               CONSTANT VARCHAR2(20) := 'XXCCP009A16C';
  cv_appl_short_name CONSTANT VARCHAR2(10)    := 'XXCCP';        -- �A�h�I���F���ʁEIF�̈�
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  --==================================================
  -- �O���[�o���J�[�\��
  --==================================================
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf           OUT    VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT    VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT    VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'submain';            -- �v���O������
    cv_set_of_bks_id    CONSTANT VARCHAR2(30)  := 'GL_SET_OF_BKS_ID';   -- ��v����ID
--
    cv_code_ef01               CONSTANT VARCHAR2(4)   := 'EF01';
    cv_code_ef02               CONSTANT VARCHAR2(4)   := 'EF02';
    cv_code_ef03               CONSTANT VARCHAR2(4)   := 'EF03';
    cv_code_ef04               CONSTANT VARCHAR2(4)   := 'EF04';
    cv_msg_ef01                CONSTANT VARCHAR2(200) := '��vFF�L�����G���[';
    cv_msg_ef02                CONSTANT VARCHAR2(200) := '��vFF�]�L���G���[';
    cv_msg_ef03                CONSTANT VARCHAR2(200) := '��vFF�g�p�s�G���[';
    cv_msg_ef04                CONSTANT VARCHAR2(200) := '�����ȉ�vFF�G���[';
    cv_msg_others              CONSTANT VARCHAR2(200) := '���̑��G���[';
--
    cv_token_request_id        CONSTANT VARCHAR2(9)   := '�v��ID�F ';
    cv_token_date_created      CONSTANT VARCHAR2(9)   := '�쐬���F ';
    cv_token_accounting_date   CONSTANT VARCHAR2(13)  := '�d��v����F ';
    cv_token_source            CONSTANT VARCHAR2(15)  := '�d��\�[�X���F ';
    cv_token_category          CONSTANT VARCHAR2(15)  := '�d��J�e�S���F ';
    cv_token_status            CONSTANT VARCHAR2(13)  := '�X�e�[�^�X�F ';
    cv_token_kugiri1           CONSTANT VARCHAR2(2)   := '�A';
    cv_token_kugiri2           CONSTANT VARCHAR2(1)   := ' ';
    cv_token_kugiri3           CONSTANT VARCHAR2(1)   := ')';
--
    cv_msg_no_parameter CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90008';  -- �p�����[�^�Ȃ�
    cv_msg_profile_err  CONSTANT VARCHAR2(100) := '�v���t�@�C������GL��v����ID�̎擾�Ɏ��s���܂����B';
--
    cv_status_new                CONSTANT VARCHAR2(3)   := 'NEW';      -- �X�e�[�^�X NEW
    cv_closing_status_open       CONSTANT VARCHAR2(1)   := 'O';        -- ��v���Ԃ̃X�e�[�^�X(�I�[�v��)
    cv_appl_shrt_name_gl         CONSTANT VARCHAR2(5)   := 'SQLGL';    -- �A�v���P�[�V�����Z�k��(��ʉ�v)
    cn_before_2months            CONSTANT NUMBER        := -2;         -- �Q�����O
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf        VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode       VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg        VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    ln_set_of_bks_id NUMBER           := 0;    -- �v���t�@�C���l�F��v����ID
--
    ln_glif_err_cnt  NUMBER           := 0;    -- GL�C���^�[�t�F�[�X�G���[�f�[�^����
    lv_err_msg       VARCHAR2(200)    := NULL; -- �G���[���b�Z�[�W�i�[�ϐ�
    lv_out_msg       VARCHAR2(2000)   := NULL; -- �o�͕�����i�[�p�ϐ�
--
  --==================================================
  -- ���[�J���J�[�\��
  --==================================================
    CURSOR gl_interface_err_cur
    IS
      SELECT gi.request_id             AS request_id            -- �F�v��ID
            ,gi.date_created           AS date_created          -- �F�쐬��
            ,gi.accounting_date        AS accounting_date       -- �F�d��v���
            ,gi.user_je_source_name    AS user_je_source_name   -- �F�d��\�[�X��
            ,gi.user_je_category_name  AS user_je_category_name -- �F�d��J�e�S��
            ,gi.status                 AS status                -- �F�X�e�[�^�X
      FROM   gl_interface              gi                       -- �FGL�C���^�[�t�F�[�X
      WHERE 1=1
      AND    gi.status          <> cv_status_new
      AND    gi.set_of_books_id =  ln_set_of_bks_id
      AND    gi.accounting_date >= ( SELECT ADD_MONTHS ( MIN( gps.start_date ), cn_before_2months ) AS min_start_date_before_2months   -- �F��v���ԍŏ��J�n���Q�����O
                                     FROM   gl_period_statuses   gps   -- ��v���ԃe�[�u��
                                           ,fnd_application      fa    -- �A�v���P�[�V����
                                     WHERE  gps.set_of_books_id        = ln_set_of_bks_id
                                     AND    gps.application_id         = fa.application_id
                                     AND    gps.closing_status         = cv_closing_status_open
                                     AND    fa.application_short_name  = cv_appl_shrt_name_gl
                                   )
      ORDER BY gi.request_id, gi.date_created, gi.accounting_date, gi.user_je_source_name, gi.user_je_category_name, gi.status
    ;
    gl_interface_err_rec gl_interface_err_cur%ROWTYPE;
--
--###########################  �Œ蕔 END   ####################################
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
    -- ***************************************
--
    --���[�J���ϐ�������
    lv_err_msg         := NULL;
    lv_out_msg         := NULL;
    ln_glif_err_cnt    := 0;
--
    --==============================================================
    -- �u�R���J�����g���̓p�����[�^�Ȃ��v���b�Z�[�W���o��
    --==============================================================
    gv_out_msg := xxccp_common_pkg.get_msg(iv_application  => cv_appl_short_name
                                          ,iv_name         => cv_msg_no_parameter
                                          );
    FND_FILE.PUT_LINE(which  => FND_FILE.LOG
                     ,buff   => gv_out_msg
                     );
    -- ��s�o��
    FND_FILE.PUT_LINE(which  => FND_FILE.LOG
                     ,buff   => NULL
                     );
--
    -- �v���t�@�C������GL��v����ID�擾
    ln_set_of_bks_id := TO_NUMBER(FND_PROFILE.VALUE( cv_set_of_bks_id ));
    -- �擾�G���[��
    IF ( ln_set_of_bks_id IS NULL ) THEN
      lv_errbuf := cv_msg_profile_err;
      RAISE global_api_expt;
    END IF;
--
    --�G���[�f�[�^�̑��݊m�F
    SELECT COUNT( gi.status )  AS err_cnt            -- �F�G���[����
    INTO   ln_glif_err_cnt
    FROM   gl_interface gi
    WHERE 1=1
    AND    gi.status          <> cv_status_new
    AND    gi.set_of_books_id =  ln_set_of_bks_id
    AND    gi.accounting_date >= ( SELECT ADD_MONTHS ( MIN( gps.start_date ), cn_before_2months ) AS min_start_date_before_2months   -- �F��v���ԍŏ��J�n���Q�����O
                                   FROM   gl_period_statuses   gps   -- ��v���ԃe�[�u��
                                         ,fnd_application      fa    -- �A�v���P�[�V����
                                   WHERE  gps.set_of_books_id        = ln_set_of_bks_id
                                   AND    gps.application_id         = fa.application_id
                                   AND    gps.closing_status         = cv_closing_status_open
                                   AND    fa.application_short_name  = cv_appl_shrt_name_gl
                                 );
--
    BEGIN
      IF ln_glif_err_cnt > 0 THEN
        --GL�C���^�[�t�F�[�X�G���[��0�����傫���ꍇ�A�x���I���Ƃ��A�G���[���b�Z�[�W���o�͂���B
        ov_retcode := cv_status_warn;
        FOR gl_interface_err_rec IN gl_interface_err_cur LOOP
          --�G���[���b�Z�[�W���Z�b�g
          IF gl_interface_err_rec.status = cv_code_ef01 THEN
            lv_err_msg  := cv_msg_ef01;
          ELSIF gl_interface_err_rec.status = cv_code_ef02 THEN
            lv_err_msg  := cv_msg_ef02;
          ELSIF gl_interface_err_rec.status = cv_code_ef03 THEN
            lv_err_msg  := cv_msg_ef03;
          ELSIF gl_interface_err_rec.status = cv_code_ef04 THEN
            lv_err_msg  := cv_msg_ef04;
          ELSE
            lv_err_msg  := cv_msg_others;
          END IF;
--
          --�o�͕�����쐬
          lv_out_msg := cv_token_request_id                                                                 ; -- �v��ID(����)
          lv_out_msg := lv_out_msg || gl_interface_err_rec.request_id                                       ; -- �v��ID
          lv_out_msg := lv_out_msg ||  cv_token_kugiri1 ;
          lv_out_msg := lv_out_msg || cv_token_date_created                                                 ; -- �쐬��(����)
          lv_out_msg := lv_out_msg || TO_CHAR( gl_interface_err_rec.date_created, 'YYYY/MM/DD HH24:MI:SS' ) ; -- �쐬��
          lv_out_msg := lv_out_msg || cv_token_kugiri1 ;
          lv_out_msg := lv_out_msg || cv_token_accounting_date                                              ; -- �d��v���(����)
          lv_out_msg := lv_out_msg || TO_CHAR( gl_interface_err_rec.accounting_date, 'YYYY/MM/DD' )         ; -- �d��v���
          lv_out_msg := lv_out_msg || cv_token_kugiri1 ;
          lv_out_msg := lv_out_msg || cv_token_source                                                       ; -- �d��\�[�X��(����)
          lv_out_msg := lv_out_msg || gl_interface_err_rec.user_je_source_name                              ; -- �d��\�[�X��
          lv_out_msg := lv_out_msg || cv_token_kugiri1 ;
          lv_out_msg := lv_out_msg || cv_token_category                                                     ; -- �d��J�e�S��(����)
          lv_out_msg := lv_out_msg || gl_interface_err_rec.user_je_category_name                            ; -- �d��J�e�S��
          lv_out_msg := lv_out_msg || cv_token_kugiri1 ;
          lv_out_msg := lv_out_msg || cv_token_status                                                       ; -- �ð��(����)
          lv_out_msg := lv_out_msg || gl_interface_err_rec.status                                           ; -- �ð������
          lv_out_msg := lv_out_msg || cv_token_kugiri2 ;
          lv_out_msg := lv_out_msg || lv_err_msg                                                            ; -- �ð����
--
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_out_msg
          );
          --�����J�E���g
          gn_target_cnt      := gn_target_cnt + 1;
          gn_error_cnt       := gn_error_cnt  + 1;
        END LOOP;
      ELSE
      --GL�C���^�[�t�F�[�X�G���[��0���̏ꍇ�A����I���Ƃ���B
        ov_retcode := cv_status_normal;
        --�����J�E���g
        gn_target_cnt      := 0;
        gn_error_cnt       := 0;
      END IF;
--
    END;
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
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--
--####################################  �Œ蕔 END   ##########################################
--
  END submain;
--
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf              OUT    VARCHAR2,       --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode             OUT    VARCHAR2        --   ���^�[���E�R�[�h    --# �Œ� #
  )
--
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
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- �X�L�b�v�������b�Z�[�W
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_msg_err_end     CONSTANT VARCHAR2(100) := '�������G���[�I�����܂����B';     -- �G���[�I�����b�Z�[�W
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    --
  BEGIN
--
    -- ===============================================
    -- ��������
    -- ===============================================
    --
    -- 1.�ϐ�������
    gn_target_cnt := 0;
    gn_error_cnt  := 0;
--
      -- ===============================================
      -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
      -- ===============================================
      submain(
         lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
      --�Ώی����N���A
      gn_target_cnt := 0;
      --�G���[����
      gn_error_cnt  := 1;
    END IF;
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --�I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_normal_msg
                     );
    ELSIF(lv_retcode = cv_status_warn) THEN
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_warn_msg
                     );
    ELSIF(lv_retcode = cv_status_error) THEN
      gv_out_msg := cv_msg_err_end;
    END IF;
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
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
END XXCCP009A16C;
/
