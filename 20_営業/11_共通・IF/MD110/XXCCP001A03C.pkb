CREATE OR REPLACE PACKAGE BODY APPS.XXCCP001A03C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCCP001A03C(body)
 * Description      : WF�s���󒍖��׌��m���ΏۊO�X�V
 * MD.070           : WF�s���󒍖��׌��m���ΏۊO�X�V (MD070_IPO_CCP_001_A03)
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2020/12/03    1.0   N.Koyama         [E_�{�ғ�_16819]�V�K�쐬
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  gv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
  gv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --�x��:1
  gv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --�ُ�:2
--
  gv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg                VARCHAR2(2000);
  gn_target_cnt             NUMBER;                    -- �Ώی���
  gn_update_cnt             NUMBER;                    -- �X�V����
  gn_error_cnt              NUMBER;                    -- �G���[����
  gn_warn_cnt               NUMBER;                    -- �x������
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
  gv_appl_short_name_xxccp  CONSTANT VARCHAR2(10)    := 'XXCCP';
  -- �p�b�P�[�W��
  gv_pkg_name               CONSTANT VARCHAR2(100)   := 'XXCCP001A03C';      -- �p�b�P�[�W��
  gv_appl_short_name        CONSTANT VARCHAR2(10)    := 'XXCCP';             -- �A�h�I���F���ʁEIF�̈�
--
  gv_0                      CONSTANT VARCHAR2(1)     := '0';                 -- ���O�o�͂̂�
  gv_1                      CONSTANT VARCHAR2(1)     := '1';                 -- ���O�o�͂���уf�[�^�X�V
  gv_flag_p                 CONSTANT VARCHAR2(1)     := 'P';                 -- �t���O�uP�v
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  --===============================================================
  -- �O���[�o����O
  --===============================================================
  lock_expt             EXCEPTION;      -- ���b�N(�r�W�[)�G���[
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_exe_mode           IN  VARCHAR2      --   ���s���[�h
   ,in_back_num           IN  NUMBER        --   �Ώ�FROM��
   ,ov_errbuf             OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode            OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg             OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'submain';   -- �v���O������
    cv_item_type            CONSTANT VARCHAR2(100) := 'OEOL';
    cv_entered              CONSTANT VARCHAR2(100) := 'ENTERED';
    cv_booked               CONSTANT VARCHAR2(100) := 'BOOKED';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_exe_mode           VARCHAR2(1);                             -- ���s���[�h
    ln_max_line_id        NUMBER;                                  -- �ő�󒍖���ID
    ln_go_back_count      NUMBER;                                  -- �Ώ�FROM��
    ln_order_number       oe_order_headers_all.order_number%TYPE;  -- �󒍔ԍ�
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- WF�s���󒍖��׃��R�[�h�擾
    CURSOR main_cur
    IS
--  WF�s���󒍖���
      SELECT ooha.header_id    header_id,      -- �󒍃w�b�_�[ID
             ooha.order_number order_number,   -- �󒍔ԍ�
             oola.line_id      line_id,        -- �󒍖���ID
             oola.line_number  line_number     -- �󒍖��הԍ�
        FROM apps.oe_order_headers_all ooha,
             apps.oe_order_lines_all oola
       WHERE 1=1
         AND ooha.header_id = oola.header_id
         AND oola.line_id  >= ( ln_max_line_id - ln_go_back_count )
         AND oola.flow_status_code IN ( cv_entered, cv_booked )
         AND NOT EXISTS (
                          SELECT 1
                            FROM apps.wf_item_activity_statuses wias
                           WHERE wias.item_type = cv_item_type
                             AND wias.item_key  = TO_CHAR( oola.line_id )
                        )
      ;
--
    -- �󒍖��ׁi�r���j
    CURSOR order_lines_lock_cur(
      in_header_id IN NUMBER   -- 1.�󒍃w�b�_�[ID
    ) IS
      SELECT  oola.header_id           header_id   -- �󒍃w�b�_�[ID
        FROM  apps.oe_order_lines_all  oola
       WHERE  oola.header_id = in_header_id
      FOR UPDATE OF oola.header_id NOWAIT
      ;
--
    -- ���C���J�[�\�����R�[�h�^
    main_rec               main_cur%ROWTYPE;
    -- �󒍖��ׁi�r���j�J�[�\�����R�[�h�^
    order_lines_lock_rec   order_lines_lock_cur%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �O���[�o���ϐ��̏�����
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
    gn_update_cnt := 0;
--
    -- ===============================
    -- init��
    -- ===============================
--
    -- IN�p�����[�^��ϐ��ɑޔ�
    lv_exe_mode      := iv_exe_mode;
    ln_go_back_count := in_back_num;
--
    -- �ϐ�������
    ln_order_number := 0;
--
    -- �p�����[�^�F���s���[�h
    IF ( lv_exe_mode = gv_0 ) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => '���s���[�h�F0�i���O�o�͂̂݁j'
          );
    ELSIF ( lv_exe_mode = gv_1 ) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => '���s���[�h�F1�i���O�o�͂���уf�[�^�X�V�j'
          );
    END IF;
--
    -- �p�����[�^�F�͈�FROM
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '�͈�FROM�F ' || TO_CHAR( ln_go_back_count )
        );
--
    -- �����_�̍ő�󒍖���ID
    SELECT MAX(ola.line_id)  max_line_id
      INTO ln_max_line_id
      FROM oe_order_lines_all ola
    ;
--
    -- �����ID
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '�����ID�F ' || TO_CHAR( ln_max_line_id - ln_go_back_count )
        );
    -- �ő喾��ID
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '�ő喾��ID�F ' || TO_CHAR( ln_max_line_id )
        );
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    -- ===============================
    -- ������
    -- ===============================
--
    -- �f�[�^���o��
    FOR main_rec IN main_cur LOOP
      -- �X�V�Ώۂ̎󒍔ԍ��A�󒍖��הԍ����o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => '�󒍔ԍ� �F ' || main_rec.order_number  || ' �󒍖��הԍ� �F ' || main_rec.line_number || ' ��WF�̕R�����s���ł��B'
          );
--
      -- �Ώۃf�[�^������ꍇ�͌x���I��
      ov_retcode  := gv_status_warn;
      gn_warn_cnt := gn_warn_cnt + 1;
--
      -- �X�V����̏ꍇ
      IF ( lv_exe_mode = gv_1 ) THEN
        BEGIN
--
          -- �r������
          OPEN order_lines_lock_cur(
            main_rec.header_id    -- 1.�󒍃w�b�_�[ID
          );
          FETCH order_lines_lock_cur INTO order_lines_lock_rec;
          CLOSE order_lines_lock_cur;
--
          UPDATE apps.oe_order_lines_all oola
             SET oola.global_attribute5 = gv_flag_p  -- �̔����јA�g�σt���O
           WHERE oola.header_id = main_rec.header_id
          ;
--
          IF ( ln_order_number <> main_rec.order_number ) THEN
            -- �X�V�Ώۂ̎󒍔ԍ��A���א����o��
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => '�󒍔ԍ� �F ' || main_rec.order_number || ' �̑S���ׂ̔̔����э쐬�σt���O���X�V���܂����B���א� �F ' || SQL%ROWCOUNT
                );
--
            -- �X�V�����J�E���g
            gn_update_cnt := gn_update_cnt + SQL%ROWCOUNT;
--
          END IF;
--
          -- �󒍔ԍ��ޔ�
          ln_order_number  := main_rec.order_number;
--
          COMMIT;
--
        EXCEPTION
          WHEN lock_expt THEN  -- �e�[�u�����b�N�G���[
            IF ( order_lines_lock_cur%ISOPEN ) THEN
              -- �J�[�\���̃N���[�Y
              CLOSE order_lines_lock_cur;
            END IF;
--
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => '���̃��[�U�[�ɂ��g�p���ł��B�󒍔ԍ� �F ' || main_rec.order_number || ' �󒍖��הԍ� �F ' || main_rec.line_number
                );
--
            ov_retcode   := gv_status_error;
            gn_error_cnt := gn_error_cnt + 1;
            ROLLBACK;
          WHEN OTHERS THEN
            IF ( order_lines_lock_cur%ISOPEN ) THEN
              -- �J�[�\���̃N���[�Y
              CLOSE order_lines_lock_cur;
            END IF;
--
            ov_errbuf    := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
            ov_retcode   := gv_status_error;
            gn_error_cnt := gn_error_cnt + 1;
            ROLLBACK;
        END;
      END IF;
--
    END LOOP;
--
    IF ( gn_error_cnt > 0 ) THEN
      ov_retcode := gv_status_error;
    END IF;
--
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
      -- �J�[�\���̃N���[�Y�������ɋL�q����
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--####################################  �Œ蕔 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf                OUT VARCHAR2      --   �G���[�E���b�Z�[�W  --# �Œ� #
   ,retcode               OUT VARCHAR2      --   ���^�[���E�R�[�h    --# �Œ� #
   ,iv_exe_mode           IN  VARCHAR2      --   ���s���[�h
   ,in_back_num           IN  NUMBER        --   �Ώ�FROM��
  )
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
    cv_warn_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-00001'; -- �x���������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-10008'; -- �G���[�I���S���[���o�b�N
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
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
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       iv_exe_mode                              -- ���s���[�h
      ,in_back_num                                 -- �Ώ�FROM��
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = gv_status_error) THEN
      --��s�}��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => ''
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
--
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --�x�������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_appl_short_name
                    ,iv_name         => cv_warn_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --�X�V�����o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '�X�V����  �F  ' || TO_CHAR(gn_update_cnt) || ' ��'
    );
--
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_appl_short_name
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
    IF (lv_retcode = gv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = gv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = gv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCCP001A03C;
/