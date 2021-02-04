CREATE OR REPLACE PACKAGE BODY APPS.XXCCP011A02C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCCP011A02C(body)
 * Description      : �V�[�P���X�X�V(�ėp��)
 * MD.050           : 
 * Version          : 1.0
 *
 * Program List
 * ------------------------- ------------------------------------------------------------
 *  Name                      Description
 * ------------------------- ------------------------------------------------------------
 *  submain                   ���C�������v���V�[�W��
 *  main                      �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                            �I������
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2021/02/02    1.0   N.Koyama         main�V�K�쐬
 *
 *****************************************************************************************/
  -- ===============================================
  -- �O���[�o���萔
  -- ===============================================
  -- �p�b�P�[�W��
  cv_pkg_name                 CONSTANT VARCHAR2(20)   :=  'XXCCP011A02C';
--
  -- �A�v���P�[�V�����Z�k��
  cv_appl_name_xxccp          CONSTANT VARCHAR2(10)   :=  'XXCCP';
--
  -- �X�e�[�^�X
  cv_status_normal            CONSTANT VARCHAR2(1)    :=  xxccp_common_pkg.set_status_normal; -- ����:0
  cv_status_warn              CONSTANT VARCHAR2(1)    :=  xxccp_common_pkg.set_status_warn;   -- �x��:1
  cv_status_error             CONSTANT VARCHAR2(1)    :=  xxccp_common_pkg.set_status_error;  -- �ُ�:2
--
  -- ���b�Z�[�W
  cv_msg_xxccp_90004          CONSTANT VARCHAR2(30)   :=  'APP-XXCCP1-90004';  -- ����I��
  cv_msg_xxccp_90005          CONSTANT VARCHAR2(30)   :=  'APP-XXCCP1-90005';  -- �x���I��
  cv_msg_xxccp_90006          CONSTANT VARCHAR2(30)   :=  'APP-XXCCP1-90006';  -- �G���[�I���S���[���o�b�N
--
  -- �g�[�N��
--
  -- �Z�p���[�^
  cv_msg_part                 CONSTANT VARCHAR2(3)    :=  ' : ';
  cv_msg_cont                 CONSTANT VARCHAR2(1)    :=  '.';
  cv_empty                    CONSTANT VARCHAR2(1)    :=  '';
--
  -- ���̑��萔
  cv_space                    CONSTANT VARCHAR2(1)    :=  ' ';                 -- ���p�X�y�[�X
  --
  -- ===============================================
  -- �O���[�o���ϐ�
  -- ===============================================
--
  -- ===============================================
  -- �O���[�o���J�[�\��
  -- ===============================================
--
  -- ===============================================
  -- ���ʗ�O
  -- ===============================================
  --*** ���������ʗ�O ***
  global_process_expt             EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt                 EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt          EXCEPTION;
  --
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_seq_name      IN  VARCHAR2      --   �V�[�P���X��
   ,ov_errbuf        OUT VARCHAR2
   ,ov_retcode       OUT VARCHAR2
   ,ov_errmsg        OUT VARCHAR2
  )
  IS
    -- ===============================================
    -- �Œ胍�[�J���萔
    -- ===============================================
    cv_prg_name  CONSTANT VARCHAR2(30) := 'submain';
--
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;
    lv_outmsg       VARCHAR2(5000) DEFAULT NULL;  -- �o�͗p���b�Z�[�W
    --
    ln_sequence_nextval   NUMBER; -- �V�[�P���X�l�i�[�p
    lt_cache_size         dba_sequences.cache_size%TYPE;                   -- �L���b�V���T�C�Y
    lv_sequence_name      dba_sequences.sequence_name%TYPE;                -- �V�[�P���X��
    lv_sql_stmt           VARCHAR2(32767)  DEFAULT NULL;                   -- ���ISQL�p������
--
    -- ===============================================
    -- ���[�J����O
    -- ===============================================
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    lv_sequence_name := UPPER(iv_seq_name);
    -- ===============================================
    -- ���̓p�����[�^�̏o��
    -- ===============================================
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => '�ΏۃV�[�P���X:' || iv_seq_name
    );
    -- ��s���o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => cv_space
    );
--
    -- ===============================================
    -- �V�[�P���X���擾
    -- ===============================================
    BEGIN
      SELECT ds.cache_size       AS cache_size -- �L���b�V���T�C�Y
      INTO   lt_cache_size
      FROM   dba_sequences ds  -- �V�[�P���X���
      WHERE  ds.sequence_name = lv_sequence_name -- �V�[�P���X��
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �擾�ł��Ȃ������ꍇ
        lv_errbuf := '�w�肵���V�[�P���X�����݂��܂���B';
        RAISE global_process_expt;
    END;
    -- �L���b�V���T�C�Y���o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '�L���b�V���T�C�Y:' || lt_cache_size
    );
    -- ��s���o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => cv_space
    );
    -- =======================================================
    -- ���ISQL���̍쐬(���ݒl�擾)
    -- =======================================================
    lv_sql_stmt := ( 'SELECT ' || lv_sequence_name || '.NEXTVAL sequence_num FROM DUAL' );
    -- =======================================================
    -- ===============================================
    -- �V�[�P���X���ݒl�擾
    -- ===============================================
    -- ���ISQL���̎��s
    -- =======================================================
    EXECUTE IMMEDIATE lv_sql_stmt INTO ln_sequence_nextval;
--
    -- �X�V�O�V�[�P���X�l���o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '�X�V�O�̒l:' || ln_sequence_nextval
    );
    -- =======================================================
    -- ���ISQL���̍쐬(�J�E���g�A�b�v)
    -- =======================================================
    lv_sql_stmt := ( 'SELECT ' || lv_sequence_name || '.NEXTVAL sequence_num FROM DUAL' );
    -- =======================================================
    <<seq_loop>>
    FOR i IN 1 .. ( lt_cache_size ) LOOP
      -- �V�[�P���X�A�b�v
    -- ===============================================
    -- ���ISQL���̎��s
    -- =======================================================
      EXECUTE IMMEDIATE lv_sql_stmt INTO ln_sequence_nextval;
    END LOOP seq_loop;
--
    -- �X�V��V�[�P���X�l���o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '�X�V��̒l:' || ln_sequence_nextval
    );    
--
  EXCEPTION
    -- *** ���������ʗ�O ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errmsg  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
  PROCEDURE main(
    errbuf        OUT VARCHAR2
   ,retcode       OUT VARCHAR2
   ,iv_seq_name       VARCHAR2          --   �X�V�V�[�P���X
  )
  IS
--
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name      CONSTANT VARCHAR2(30)  := 'main';  -- �v���O������
--
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf        VARCHAR2(5000) DEFAULT NULL;              -- �G���[���b�Z�[�W
    lv_retcode       VARCHAR2(1)    DEFAULT cv_status_normal;  -- ���^�[���R�[�h
    lv_errmsg        VARCHAR2(5000) DEFAULT NULL;              -- ���[�U�[�G���[���b�Z�[�W
    lv_outmsg        VARCHAR2(5000) DEFAULT NULL;              -- ���b�Z�[�W�ϐ�
    lv_message_code  VARCHAR2(100)  DEFAULT NULL;              -- ���b�Z�[�W�R�[�h
--
  BEGIN
    -- ===============================================
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    -- ===============================================
    xxccp_common_pkg.put_log_header(
      ov_retcode => lv_retcode
    , ov_errbuf  => lv_errbuf
    , ov_errmsg  => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      iv_seq_name     => iv_seq_name
    , ov_errbuf       => lv_errbuf
    , ov_retcode      => lv_retcode
    , ov_errmsg       => lv_errmsg
    );
--
    -- ============================
    --  �G���[�o��
    -- ============================
    IF ( lv_retcode = cv_status_error ) THEN
      -- �G���[���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
       ,buff   => lv_errbuf
      );
      -- ��s���o��
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => cv_space
      );
--
    END IF;
--
    -- ============================
    --  ��s�o��
    -- ============================
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => ''
    );
--
    -- ============================
    -- �����I�����b�Z�[�W�o��
    -- ============================
    IF ( lv_retcode    = cv_status_normal ) THEN
      lv_message_code := cv_msg_xxccp_90004;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_msg_xxccp_90005;
    ELSE
      lv_message_code := cv_msg_xxccp_90006;
    END IF;
    lv_outmsg    := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxccp
                    , iv_name         => lv_message_code
                    );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => lv_outmsg
    );
--
    -- ===============================================
    -- �X�e�[�^�X�Z�b�g
    -- ===============================================
    retcode := lv_retcode;
--
    -- ===============================================
    -- �I���X�e�[�^�X�G���[���A���[���o�b�N
    -- ===============================================
    IF ( retcode = cv_status_error ) THEN
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
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
END XXCCP011A02C;
/