CREATE OR REPLACE PACKAGE BODY APPS.XXCCP400A01C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2015. All rights reserved.
 *
 * Package Name     : XXCCP400A01C(body)
 * Description      : �R���J�����g���ʔ���
 * Version          : 1.0
 *
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
 *  2015/08/25    1.0   N.Koyama         [E_�{�ғ�_13287]�V�K�쐬
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --�x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --�ُ�:2
--
--
  cv_msg_part                CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont                CONSTANT VARCHAR2(3) := '.';
  gv_out_msg                VARCHAR2(2000);
  --��O
  global_api_others_expt    EXCEPTION;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCCP400A01C';                 -- �v���O������
  cv_normal                 CONSTANT VARCHAR2(1)   := 'C';             -- ����
  cv_worn                   CONSTANT VARCHAR2(1)   := 'G';             -- �x��
  cv_err                    CONSTANT VARCHAR2(1)   := 'E';             -- �G���[
  cv_y                      CONSTANT VARCHAR2(1)   := 'Y';             -- Yes
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE submain(
    iv_check_group IN  VARCHAR2,     --   1.�`�F�b�N�ΏۃO���[�v�R�[�h
    ov_errbuf      OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
--
  IS
--
    --�Œ�ϐ�
    lv_errbuf                 VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode                VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg                 VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    --�ΏۃR���J�����g���ʎ擾�J�[�\��
    CURSOR data_cur
    IS
      SELECT fcr.request_id                                                   AS request_id, 
             fcp.concurrent_program_name                                      AS program_short_name,
             flv.meaning                                                      AS program_name,
             fcr.status_code                                                  AS status_code,
             DECODE(fcr.status_code,'C','����','G','�x��','E','�G���[','X','�I��','D','�����',NULL) AS status_name,
             flv.attribute1                                                   AS normal_check,
             flv.attribute2                                                   AS worn_check,
             flv.attribute3                                                   AS err_check
        FROM applsys.fnd_concurrent_programs    fcp,
             applsys.fnd_concurrent_requests    fcr,
             applsys.fnd_lookup_values          flv
       WHERE fcp.application_id                   = fcr.program_application_id 
         AND fcp.concurrent_program_id            = fcr.concurrent_program_id 
         AND fcr.request_date                    >= TRUNC(SYSDATE)                  -- �{����AM00:00����
         AND fcr.request_date                     < TRUNC(SYSDATE) + 0.25           -- �{����AM06:00�܂�
         AND flv.lookup_type                      = 'XXCCP1_STATUS_CHECK_CONC1'
         AND flv.lookup_code                   LIKE iv_check_group || '%'
         AND flv.description                      = fcp.concurrent_program_name
         AND flv.language    = 'JA'
         AND flv.enabled_flag = 'Y'
         AND    TRUNC(SYSDATE) BETWEEN TRUNC(flv.start_date_active) 
                                 AND     NVL(flv.end_date_active, TRUNC(SYSDATE))
         AND ((flv.attribute6 IS NOT NULL
         AND   flv.attribute6 = fcr.argument1)
          OR  (flv.attribute6 IS NULL))
         AND ((flv.attribute7 IS NOT NULL
         AND   flv.attribute7 = fcr.argument2)
          OR  (flv.attribute7 IS NULL))
         AND ((flv.attribute8 IS NOT NULL
         AND   flv.attribute8 = fcr.argument3)
          OR  (flv.attribute8 IS NULL))
         AND ((flv.attribute9 IS NOT NULL
         AND   flv.attribute9 = fcr.argument4)
          OR  (flv.attribute9 IS NULL))
         AND ((flv.attribute10 IS NOT NULL
         AND   flv.attribute10 = fcr.argument5)
          OR  (flv.attribute10 IS NULL))
         AND ((flv.attribute11 IS NOT NULL
         AND   flv.attribute11 = fcr.argument6)
          OR  (flv.attribute11 IS NULL))
         AND ((flv.attribute12 IS NOT NULL
         AND   flv.attribute12 = fcr.argument7)
          OR  (flv.attribute12 IS NULL))
         AND ((flv.attribute13 IS NOT NULL
         AND   flv.attribute13 = fcr.argument8)
          OR  (flv.attribute13 IS NULL))
         AND ((flv.attribute14 IS NOT NULL
         AND   flv.attribute14 = fcr.argument9)
          OR  (flv.attribute14 IS NULL))
         AND ((flv.attribute15 IS NOT NULL
         AND   flv.attribute15 = fcr.argument10)
          OR  (flv.attribute15 IS NULL))
       ORDER BY fcr.request_id
      ;
--
    data_rec data_cur%ROWTYPE;
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- �p�����[�^�o��
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG
     ,buff   => '�`�F�b�N�ΏۃO���[�v�R�[�h: ' || iv_check_group
    );
    -- ��s�o��
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG
     ,buff   => NULL
    );
--
    --�Ώۃf�[�^���o
    OPEN data_cur;
    LOOP
      FETCH data_cur INTO data_rec;
      EXIT WHEN data_cur%NOTFOUND;
--
      gv_out_msg := '�v��ID:'|| data_rec.request_id || ' ' || data_rec.program_short_name || ' ' || data_rec.program_name || ' ��' || data_rec.status_name || '�I�����܂����B';
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => gv_out_msg
      );
      --�I���X�e�[�^�X����
      CASE data_rec.status_code
      -- ���펞�G���[�I��
        WHEN cv_normal THEN
          IF ( data_rec.normal_check = cv_y ) THEN
            ov_retcode := cv_status_error;
          END IF;
      -- �x�����G���[�I��
        WHEN cv_worn THEN
          IF ( data_rec.worn_check = cv_y ) THEN
            ov_retcode := cv_status_error;
          END IF;          
      -- �G���[���G���[�I��
        WHEN cv_err THEN
          IF ( data_rec.err_check = cv_y ) THEN
            ov_retcode := cv_status_error;
          END IF;
      END CASE;
--
    END LOOP;
--
    CLOSE data_cur;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SQLERRM;
      ov_retcode := cv_status_error;
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf          OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode         OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_check_group  IN  VARCHAR2       -- 1.�`�F�b�N�ΏۃO���[�v�R�[�h
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
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main'; -- �v���O������
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�h�I���F���ʁEIF�̈�
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
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
       iv_which   => 'LOG'
      ,ov_retcode => lv_retcode
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
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       iv_check_group  -- 1.�`�F�b�N�ΏۃO���[�v�R�[�h
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
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
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
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
END XXCCP400A01C;
/
