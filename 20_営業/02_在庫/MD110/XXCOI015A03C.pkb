CREATE OR REPLACE PACKAGE BODY APPS.XXCOI015A03C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2016. All rights reserved.
 *
 * Package Name     : XXCOI015A03C(body)
 * Description      : ���ގ���V�[�P���X�X�V
 * MD.050           : 
 * Version          : 1.0
 *
 * Program List
 * ------------------------- ------------------------------------------------------------
 *  Name                      Description
 * ------------------------- ------------------------------------------------------------
 *  upd_sequence              ���ގ���V�[�P���X�X�V(A-2)
 *  init                      ��������(A-1)
 *  submain                   ���C�������v���V�[�W��
 *  main                      �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                            �I������(A-3)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2016/11/15    1.0   S.Yamashita      main�V�K�쐬
 *
 *****************************************************************************************/
  -- ===============================================
  -- �O���[�o���萔
  -- ===============================================
  -- �p�b�P�[�W��
  cv_pkg_name                 CONSTANT VARCHAR2(20)   :=  'XXCOI015A03C';
--
  -- �A�v���P�[�V�����Z�k��
  cv_appl_name_xxcoi          CONSTANT VARCHAR2(10)   :=  'XXCOI';
  cv_appl_name_xxccp          CONSTANT VARCHAR2(10)   :=  'XXCCP';
--
  -- �X�e�[�^�X
  cv_status_normal            CONSTANT VARCHAR2(1)    :=  xxccp_common_pkg.set_status_normal; -- ����:0
  cv_status_warn              CONSTANT VARCHAR2(1)    :=  xxccp_common_pkg.set_status_warn;   -- �x��:1
  cv_status_error             CONSTANT VARCHAR2(1)    :=  xxccp_common_pkg.set_status_error;  -- �ُ�:2
--
  -- WHO�J����
  cn_created_by               CONSTANT NUMBER         :=  fnd_global.user_id;          -- CREATED_BY
  cn_last_updated_by          CONSTANT NUMBER         :=  fnd_global.user_id;          -- LAST_UPDATED_BY
  cn_last_update_login        CONSTANT NUMBER         :=  fnd_global.login_id;         -- LAST_UPDATE_LOGIN
  cn_request_id               CONSTANT NUMBER         :=  fnd_global.conc_request_id;  -- REQUEST_ID
  cn_program_application_id   CONSTANT NUMBER         :=  fnd_global.prog_appl_id;     -- PROGRAM_APPLICATION_ID
  cn_program_id               CONSTANT NUMBER         :=  fnd_global.conc_program_id;  -- PROGRAM_ID
--
  -- ���b�Z�[�W
  cv_msg_xxccp_90000          CONSTANT VARCHAR2(30)   :=  'APP-XXCCP1-90000';  -- �Ώی���
  cv_msg_xxccp_90001          CONSTANT VARCHAR2(30)   :=  'APP-XXCCP1-90001';  -- ��������
  cv_msg_xxccp_90002          CONSTANT VARCHAR2(30)   :=  'APP-XXCCP1-90002';  -- �G���[����
  cv_msg_xxccp_90003          CONSTANT VARCHAR2(30)   :=  'APP-XXCCP1-90003';  -- �x������
  cv_msg_xxccp_90004          CONSTANT VARCHAR2(30)   :=  'APP-XXCCP1-90004';  -- ����I��
  cv_msg_xxccp_90005          CONSTANT VARCHAR2(30)   :=  'APP-XXCCP1-90005';  -- �x���I��
  cv_msg_xxccp_90006          CONSTANT VARCHAR2(30)   :=  'APP-XXCCP1-90006';  -- �G���[�I���S���[���o�b�N
--
  cv_msg_xxcoi_10387          CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-10387';  -- �R���J�����g���̓p�����[�^�Ȃ����b�Z�[�W
  cv_msg_xxcoi_10724          CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-10724';  -- ���ID�擾�G���[���b�Z�[�W
  cv_msg_xxcoi_10725          CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-10725';  -- ���ގ���V�[�P���X���擾�G���[���b�Z�[�W
--
  -- �g�[�N��
  cv_token_count              CONSTANT VARCHAR2(20)   :=  'COUNT';
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
  gn_target_cnt               NUMBER  DEFAULT 0;     -- �Ώی���
  gn_normal_cnt               NUMBER  DEFAULT 0;     -- �X�V����
  gn_error_cnt                NUMBER  DEFAULT 0;     -- �G���[����
  gn_warn_cnt                 NUMBER  DEFAULT 0;     -- �x������
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
   * Procedure Name   : upd_sequence
   * Description      : ���ގ���V�[�P���X�X�V(A-2)
   ***********************************************************************************/
  PROCEDURE upd_sequence(
    ov_errbuf   OUT VARCHAR2
  , ov_retcode  OUT VARCHAR2
  , ov_errmsg   OUT VARCHAR2
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name           CONSTANT VARCHAR2(30) := 'upd_sequence';  -- �v���O������
    cv_pgsname_a09c       CONSTANT VARCHAR2(30) := 'XXCOI006A09C';  -- �f�[�^�A�g����e�[�u���p�v���O������
    cv_sequence_name      CONSTANT VARCHAR2(50) := 'MTL_MATERIAL_TRANSACTIONS_S';   -- �ΏۃV�[�P���X��
--
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf             VARCHAR2(5000) DEFAULT NULL;                              -- �G���[�E���b�Z�[�W
    lv_retcode            VARCHAR2(1)    DEFAULT cv_status_normal;                  -- ���^�[���E�R�[�h
    lv_errmsg             VARCHAR2(5000) DEFAULT NULL;                              -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg             VARCHAR2(5000) DEFAULT NULL;                              -- �o�͗p���b�Z�[�W
--
    ln_sequence_nextval   NUMBER; -- �V�[�P���X�l�i�[�p
    lt_max_transaction_id mtl_material_transactions.transaction_id%TYPE;   -- ���ގ��ID(�ő�l)
    lt_cache_size         dba_sequences.cache_size%TYPE;                   -- �L���b�V���T�C�Y
--
  BEGIN
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================================
    -- ���ގ��ID(�ő�l)�擾
    -- ===============================================
    BEGIN
      SELECT  xcc.transaction_id    AS transaction_id    -- ���ID
      INTO    lt_max_transaction_id
      FROM    xxcoi_cooperation_control   xcc         -- �f�[�^�A�g����e�[�u��
      WHERE   xcc.program_short_name = cv_pgsname_a09c
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
         -- �擾�ł��Ȃ������ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcoi
                       , iv_name         => cv_msg_xxcoi_10724  -- ���ID�擾�G���[���b�Z�[�W
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ===============================================
    -- �V�[�P���X���擾
    -- ===============================================
    BEGIN
      SELECT ds.cache_size       AS cache_size -- �L���b�V���T�C�Y
      INTO   lt_cache_size
      FROM   dba_sequences ds  -- �V�[�P���X���
      WHERE  ds.sequence_name = cv_sequence_name -- ���ގ���V�[�P���X
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �擾�ł��Ȃ������ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcoi
                       , iv_name         => cv_msg_xxcoi_10725  -- ���ގ���V�[�P���X���擾�G���[���b�Z�[�W
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ##### debug log #####
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   =>               '##### debug log #####'
                 || CHR(10) || 'max_transaction_id : ' || lt_max_transaction_id
                 || CHR(10) || 'cache_size         : ' || lt_cache_size
    );
--
    -- ===============================================
    -- �V�[�P���X���ݒl�擾
    -- ===============================================
    SELECT mtl_material_transactions_s.NEXTVAL AS sequence_nextval
    INTO   ln_sequence_nextval
    FROM   dual
    ;
--
    -- ##### debug log #####
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => 'Before sequence_val  : ' || ln_sequence_nextval
    );
--
    -- ���ގ��ID(�ő�l)�����V�[�P���X���ݒl���������ꍇ
    IF ( lt_max_transaction_id > ln_sequence_nextval ) THEN
--
      -- �Ώی����J�E���g
      gn_target_cnt := gn_target_cnt + 1;
--
      <<seq_loop>>
      FOR i IN 1 .. ( lt_cache_size ) LOOP
        -- �V�[�P���X�X�V
        SELECT mtl_material_transactions_s.NEXTVAL AS sequence_nextval
        INTO   ln_sequence_nextval
        FROM   dual
        ;
      END LOOP seq_loop;
--
      -- ���������J�E���g
      gn_normal_cnt := gn_normal_cnt + 1;
--
    END IF;
--
    -- ##### debug log #####
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => 'After sequence_val   : ' || ln_sequence_nextval
    );
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_outmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
--
--#####################################  �Œ蕔 END   ##########################################
--
  END upd_sequence;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf   OUT VARCHAR2
   ,ov_retcode  OUT VARCHAR2
   ,ov_errmsg   OUT VARCHAR2
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(30) := 'init';  -- �v���O������
--
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf      VARCHAR2(5000) DEFAULT NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode     VARCHAR2(1)    DEFAULT cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg      VARCHAR2(5000) DEFAULT NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg      VARCHAR2(5000) DEFAULT NULL;              -- �o�͗p���b�Z�[�W
--
  BEGIN
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================================
    -- ���̓p�����[�^�̏o��
    -- ===============================================
    lv_outmsg    := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcoi
                    ,iv_name         => cv_msg_xxcoi_10387
                   );
    --
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_outmsg
    );
    -- ��s���o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => cv_space
    );
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_outmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf        OUT VARCHAR2
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
    -- ===============================================
    -- ���[�J����O
    -- ===============================================
--
  BEGIN
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================================
    -- ��������(A-1)
    -- ===============================================
    init(
      ov_errbuf   => lv_errbuf
     ,ov_retcode  => lv_retcode
     ,ov_errmsg   => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- ���ގ���V�[�P���X�X�V(A-2)
    -- ===============================================
    upd_sequence(
      ov_errbuf       => lv_errbuf
     ,ov_retcode      => lv_retcode
     ,ov_errmsg       => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
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
      ov_errbuf       => lv_errbuf
    , ov_retcode      => lv_retcode
    , ov_errmsg       => lv_errmsg
    );
--
    -- ===============================================
    -- �I������(A-3)
    -- ===============================================
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
      -- �G���[�����J�E���g
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
--
    END IF;
--
    -- ============================
    --  �Ώی����o��
    -- ============================
    lv_outmsg    := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxccp
                    , iv_name         => cv_msg_xxccp_90000
                    , iv_token_name1  => cv_token_count
                    , iv_token_value1 => TO_CHAR( gn_target_cnt )
                    );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => lv_outmsg
    );
--
    -- ============================
    --  ���������o��
    -- ============================
    lv_outmsg    := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxccp
                    , iv_name         => cv_msg_xxccp_90001
                    , iv_token_name1  => cv_token_count
                    , iv_token_value1 => TO_CHAR( gn_normal_cnt )
                    );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => lv_outmsg
    );
--
    -- ============================
    --  �G���[�����o��
    -- ============================
    lv_outmsg    := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxccp
                    , iv_name         => cv_msg_xxccp_90002
                    , iv_token_name1  => cv_token_count
                    , iv_token_value1 => TO_CHAR( gn_error_cnt )
                    );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => lv_outmsg
    );
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
END XXCOI015A03C;
/