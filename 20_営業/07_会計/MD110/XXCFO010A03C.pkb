CREATE OR REPLACE PACKAGE BODY XXCFO010A03C
AS
/*************************************************************************
 * Copyright(c)SCSK Corporation, 2015. All rights reserved.
 * 
 * Package Name    : XXCFO010A03C
 * Description     : GLIF�O���[�vID�X�V
 * MD.050          : MD050_CFO_010_A03_GLIF�O���[�vID�X�V
 * MD.070          : MD050_CFO_010_A03_GLIF�O���[�vID�X�V
 * Version         : 1.0
 * 
 * Program List
 * --------------- ---- ----- --------------------------------------------
 *  Name           Type  Ret   Description
 * --------------- ---- ----- --------------------------------------------
 *  init              P        ��������(A-1)
 *  upd_group_id      P        �O���[�vID�X�V(A-2)
 *  submain           P        ���C�������v���V�[�W��
 *  main              P        �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 * 
 * Change Record
 * ------------- ----- ------------- -------------------------------------
 *  Date          Ver.  Editor        Description
 * ------------- ----- ------------- -------------------------------------
 *  2015-09-01    1.0  SCSK ���H���O  ����쐬
 ************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --�x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --�ُ�:2
  --WHO�J����
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    --PROGRAM_UPDATE_DATE
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
  gn_target_cnt    NUMBER;                    -- �Ώی���
  gn_normal_cnt    NUMBER;                    -- ���팏��
  gn_error_cnt     NUMBER;                    -- �G���[����
  gn_warn_cnt      NUMBER;                    -- �X�L�b�v����
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
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFO010A03C';     -- �p�b�P�[�W��
  cv_msg_kbn_cmn     CONSTANT VARCHAR2(5)   := 'XXCMN';            -- �A�h�I���F�}�X�^�E�o���E���ʂ̃A�v���P�[�V�����Z�k��
  cv_msg_kbn_cfo     CONSTANT VARCHAR2(5)   := 'XXCFO';            -- �A�h�I���F��v�E�A�h�I���̈�̃A�v���P�[�V�����Z�k��
--
  -- ���b�Z�[�W�ԍ�
  cv_msg_010a03_001  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00001';  -- �v���t�@�C���擾�G���[���b�Z�[�W
  cv_msg_010a03_002  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00004';  -- �Ώۃf�[�^�Ȃ����b�Z�[�W
  cv_msg_010a03_003  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00020';  -- �f�[�^�X�V�G���[���b�Z�[�W
  cv_msg_010a03_004  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00051';  -- �p�����[�^�o�̓��b�Z�[�W
  cv_msg_010a03_005  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00052';  -- �O���[�vID�X�V�������b�Z�[�W
  cv_msg_010a03_006  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00019';  -- �f�[�^���b�N�G���[���b�Z�[�W
--
  -- �g�[�N��
  cv_tkn_param1      CONSTANT VARCHAR2(20) := 'PARAM1';            -- �p�����[�^1
  cv_tkn_param2      CONSTANT VARCHAR2(20) := 'PARAM2';            -- �p�����[�^2
  cv_tkn_prof        CONSTANT VARCHAR2(20) := 'PROF_NAME';         -- �v���t�@�C����
  cv_tkn_table       CONSTANT VARCHAR2(20) := 'TABLE';             -- �e�[�u����
  cv_tkn_errmsg      CONSTANT VARCHAR2(20) := 'ERRMSG';            -- �G���[���e
  cv_tkn_group_id    CONSTANT VARCHAR2(20) := 'GROUP_ID';          -- �O���[�vID
--
  -- �v���t�@�C��
  cv_set_of_bks_id        CONSTANT VARCHAR2(30) := 'GL_SET_OF_BKS_ID';            -- ��v����ID
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_set_of_bks_id        NUMBER;                                  -- �v���t�@�C���l�F��v����ID
  gt_group_id0            gl_interface.group_id%TYPE;              -- �X�V��O���[�vID0
  gt_group_id1            gl_interface.group_id%TYPE;              -- �X�V��O���[�vID1
  gt_group_id2            gl_interface.group_id%TYPE;              -- �X�V��O���[�vID2
  gt_group_id3            gl_interface.group_id%TYPE;              -- �X�V��O���[�vID3
  gt_group_id4            gl_interface.group_id%TYPE;              -- �X�V��O���[�vID4
  gn_upd_cnt0             NUMBER;                                  -- �X�V��O���[�vID0�̌���
  gn_upd_cnt1             NUMBER;                                  -- �X�V��O���[�vID1�̌���
  gn_upd_cnt2             NUMBER;                                  -- �X�V��O���[�vID2�̌���
  gn_upd_cnt3             NUMBER;                                  -- �X�V��O���[�vID3�̌���
  gn_upd_cnt4             NUMBER;                                  -- �X�V��O���[�vID4�̌���
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_je_source_name  IN  VARCHAR2,  -- �d��\�[�X��
    iv_group_id        IN  VARCHAR2,  -- �O���[�vID
    ov_errbuf          OUT VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
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
    lv_param_msg                VARCHAR2(5000);                         -- �p�����[�^�o�͗p
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
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
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --==============================================================
    -- �p�����[�^�o��
    --==============================================================
    --���b�Z�[�W�ҏW
    lv_param_msg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_msg_kbn_cfo              -- �A�v���P�[�V����
                      , iv_name          => cv_msg_010a03_004           -- ���b�Z�[�W�R�[�h
                      , iv_token_name1   => cv_tkn_param1               -- �g�[�N���R�[�h�P
                      , iv_token_value1  => iv_je_source_name           -- �d��\�[�X��
                      , iv_token_name2   => cv_tkn_param2               -- �g�[�N���R�[�h�Q
                      , iv_token_value2  => iv_group_id                 -- �O���[�vID
                    );
    -- ���O
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_param_msg
    );
--
    -- �v���t�@�C������GL��v����ID�擾
    gn_set_of_bks_id := TO_NUMBER(FND_PROFILE.VALUE( cv_set_of_bks_id ));
    -- �擾�G���[��
    IF ( gn_set_of_bks_id IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_010a03_001 -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof       -- �g�[�N��'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name( cv_set_of_bks_id ))
                                                                       -- GL��v����ID
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : upd_group_id
   * Description      : �O���[�vID�X�V(A-2)
   ***********************************************************************************/
  PROCEDURE upd_group_id(
    iv_je_source_name  IN  VARCHAR2,  -- �d��\�[�X��
    iv_group_id        IN  VARCHAR2,  -- �O���[�vID
    ov_errbuf          OUT VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_group_id'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
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
    cv_status_new         CONSTANT VARCHAR2(20) := 'NEW';                        -- �X�e�[�^�X:NEW
    cv_gl_interface_name  CONSTANT VARCHAR2(30) := 'GL�C���^�t�F�[�X�e�[�u��';   -- �G���[���b�Z�[�W�p�e�[�u����
    cv_number_0           CONSTANT VARCHAR2(1)  := '0';                          -- �O���[�vID����0�쐬�p
    cv_number_1           CONSTANT VARCHAR2(1)  := '1';                          -- �O���[�vID����1�쐬�p
    cv_number_2           CONSTANT VARCHAR2(1)  := '2';                          -- �O���[�vID����2�쐬�p
    cv_number_3           CONSTANT VARCHAR2(1)  := '3';                          -- �O���[�vID����3�쐬�p
    cv_number_4           CONSTANT VARCHAR2(1)  := '4';                          -- �O���[�vID����4�쐬�p
--
    -- *** ���[�J���ϐ� ***
    lv_param_msg                VARCHAR2(5000);                   -- �p�����[�^�o�͗p
    ln_group_id                 NUMBER;                           -- �O���[�vID�i���l�^�ϊ��p�j
--
    -- *** ���[�J���E�J�[�\�� ***
    -- GL�C���^�t�F�[�X�e�[�u���̃��b�N�p�J�[�\��
    CURSOR  gl_interface_lock_cur
    IS
      SELECT gi.rowid         row_id
      FROM   gl_interface        gi
      WHERE  gi.user_je_source_name = iv_je_source_name
      AND    gi.group_id            = ln_group_id
      AND    gi.set_of_books_id     = gn_set_of_bks_id
      AND    gi.status              = cv_status_new
      FOR UPDATE NOWAIT
      ;
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �O���[�vID�̌^��ϊ�
    ln_group_id := TO_NUMBER(iv_group_id);
--
    -- 1.�Ώۃf�[�^�����̎擾
    SELECT COUNT(gi.group_id)   target_cnt  -- �Ώی���
    INTO   gn_target_cnt
    FROM   gl_interface   gi                -- GLIF
    WHERE  gi.user_je_source_name = iv_je_source_name
    AND    gi.group_id            = ln_group_id
    AND    gi.set_of_books_id     = gn_set_of_bks_id
    AND    gi.status              = cv_status_new
    ;
--
    -- �Ώۃf�[�^���Ȃ��ꍇ
    IF ( gn_target_cnt = 0 ) THEN
      lv_param_msg := xxccp_common_pkg.get_msg(
                         iv_application   => cv_msg_kbn_cfo              -- 'XXCFO'
                       , iv_name          => cv_msg_010a03_002           -- �Ώۃf�[�^�Ȃ����b�Z�[�W
                     );
      -- ���O
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_param_msg
      );
      ov_retcode := cv_status_warn;
    -- �Ώۃf�[�^������ꍇ
    ELSIF ( gn_target_cnt > 0 ) THEN
      -- 2.�Ώۃf�[�^�̃��b�N���擾
      BEGIN
        -- ���b�N�p�J�[�\�����I�[�v������
        OPEN gl_interface_lock_cur;
        -- �J�[�\�����N���[�Y����
        CLOSE   gl_interface_lock_cur;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo        -- 'XXCFO'
                                                        ,cv_msg_010a03_006     -- �f�[�^���b�N�G���[���b�Z�[�W
                                                        ,cv_tkn_table          -- �g�[�N��'TABLE'
                                                        ,cv_gl_interface_name  -- GL�C���^�t�F�[�X�e�[�u��
                                                        )
                               ,1
                               ,5000);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
--
      BEGIN
        -- 3.�O���[�vID�̍X�V
        UPDATE gl_interface        gi
        SET    gi.group_id = TO_NUMBER( TO_CHAR( gi.group_id ) ||                                            -- �O���[�vID
                                        TO_CHAR( MOD( TO_NUMBER( TO_CHAR( gi.accounting_date, 'DD') ), 5 ) ) -- �v����̓���5�Ŋ������]��
                                      )
        WHERE  gi.user_je_source_name = iv_je_source_name
        AND    gi.group_id            = ln_group_id
        AND    gi.set_of_books_id     = gn_set_of_bks_id
        AND    gi.status              = cv_status_new
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo        -- 'XXCFO'
                                                        ,cv_msg_010a03_003     -- �f�[�^�X�V�G���[���b�Z�[�W
                                                        ,cv_tkn_table          -- �g�[�N��'TABLE'
                                                        ,cv_gl_interface_name  -- GL�C���^�t�F�[�X�e�[�u��
                                                        ,cv_tkn_errmsg         -- �g�[�N��'ERRMSG'
                                                        ,SQLERRM               -- SQL�G���[���b�Z�[�W
                                                        )
                               ,1
                               ,5000);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
--
      -- 4.�X�V��̊e�O���[�vID�̌������擾
      -- �X�V��̊e�O���[�vID
      gt_group_id0 := TO_NUMBER( iv_group_id || cv_number_0);   -- ����0�ɍX�V�����O���[�vID
      gt_group_id1 := TO_NUMBER( iv_group_id || cv_number_1);   -- ����1�ɍX�V�����O���[�vID
      gt_group_id2 := TO_NUMBER( iv_group_id || cv_number_2);   -- ����2�ɍX�V�����O���[�vID
      gt_group_id3 := TO_NUMBER( iv_group_id || cv_number_3);   -- ����3�ɍX�V�����O���[�vID
      gt_group_id4 := TO_NUMBER( iv_group_id || cv_number_4);   -- ����4�ɍX�V�����O���[�vID
--
      -- �@������0�̃O���[�vID�̌������擾
      SELECT COUNT(gi.group_id)   target_cnt  -- �Ώی���
      INTO   gn_upd_cnt0
      FROM   gl_interface   gi                -- GLIF
      WHERE  gi.user_je_source_name = iv_je_source_name
      AND    gi.group_id            = gt_group_id0
      AND    gi.set_of_books_id     = gn_set_of_bks_id
      AND    gi.status              = cv_status_new
      ;
--
      -- �A������1�̃O���[�vID�̌������擾
      SELECT COUNT(gi.group_id)   target_cnt  -- �Ώی���
      INTO   gn_upd_cnt1
      FROM   gl_interface   gi                -- GLIF
      WHERE  gi.user_je_source_name = iv_je_source_name
      AND    gi.group_id            = gt_group_id1
      AND    gi.set_of_books_id     = gn_set_of_bks_id
      AND    gi.status              = cv_status_new
      ;
--
      -- �B������2�̃O���[�vID�̌������擾
      SELECT COUNT(gi.group_id)   target_cnt  -- �Ώی���
      INTO   gn_upd_cnt2
      FROM   gl_interface   gi                -- GLIF
      WHERE  gi.user_je_source_name = iv_je_source_name
      AND    gi.group_id            = gt_group_id2
      AND    gi.set_of_books_id     = gn_set_of_bks_id
      AND    gi.status              = cv_status_new
      ;
--
      -- �C������3�̃O���[�vID�̌������擾
      SELECT COUNT(gi.group_id)   target_cnt  -- �Ώی���
      INTO   gn_upd_cnt3
      FROM   gl_interface   gi                -- GLIF
      WHERE  gi.user_je_source_name = iv_je_source_name
      AND    gi.group_id            = gt_group_id3
      AND    gi.set_of_books_id     = gn_set_of_bks_id
      AND    gi.status              = cv_status_new
      ;
--
      -- �D������4�̃O���[�vID�̌������擾
      SELECT COUNT(gi.group_id)   target_cnt  -- �Ώی���
      INTO   gn_upd_cnt4
      FROM   gl_interface   gi                -- GLIF
      WHERE  gi.user_je_source_name = iv_je_source_name
      AND    gi.group_id            = gt_group_id4
      AND    gi.set_of_books_id     = gn_set_of_bks_id
      AND    gi.status              = cv_status_new
      ;
--
      -- �X�V�����̍��v���擾
      gn_normal_cnt := gn_upd_cnt0 + gn_upd_cnt1 + gn_upd_cnt2 + gn_upd_cnt3 + gn_upd_cnt4;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
      --��O�������A�J�[�\�����I�[�v������Ă����ꍇ�A�J�[�\�����N���[�Y����B
      IF ( gl_interface_lock_cur%ISOPEN ) THEN
        CLOSE   gl_interface_lock_cur;
      END IF;
  END upd_group_id;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_je_source_name  IN  VARCHAR2,  -- �d��\�[�X��
    iv_group_id        IN  VARCHAR2,  -- �O���[�vID
    ov_errbuf          OUT VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������
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
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
    gn_upd_cnt0   := 0;
    gn_upd_cnt1   := 0;
    gn_upd_cnt2   := 0;
    gn_upd_cnt3   := 0;
    gn_upd_cnt4   := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- =====================================================
    --  ��������(A-1)
    -- =====================================================
    init(
       iv_je_source_name     -- �d��\�[�X��
      ,iv_group_id           -- �O���[�vID
      ,lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  �O���[�vID�X�V(A-2)
    -- =====================================================
    upd_group_id(
       iv_je_source_name     -- �d��\�[�X��
      ,iv_group_id           -- �O���[�vID
      ,lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      ov_retcode := lv_retcode;
    END IF;
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
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
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
    errbuf             OUT VARCHAR2,      -- �G���[�E���b�Z�[�W  --# �Œ� #
    retcode            OUT VARCHAR2,      -- ���^�[���E�R�[�h    --# �Œ� #
    iv_je_source_name  IN  VARCHAR2,      -- �d��\�[�X��
    iv_group_id        IN  VARCHAR2       -- �O���[�vID
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
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- �X�L�b�v�������b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
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
       ov_retcode => lv_retcode
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
       iv_je_source_name   -- �d��\�[�X��
      ,iv_group_id         -- �O���[�vID
      ,lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- ��v�`�[���W���F�ُ�I�����̌����ݒ�
    IF (lv_retcode = cv_status_error) THEN
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
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
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    -- ����������I���̏ꍇ
    IF ( lv_retcode = cv_status_normal ) THEN
      -- ������0�̃O���[�vID�̌������o��
      IF ( gn_upd_cnt0 > 0 ) THEN
        gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cfo
                        ,iv_name         => cv_msg_010a03_005
                        ,iv_token_name1  => cv_tkn_group_id
                        ,iv_token_value1 => TO_CHAR(gt_group_id0)
                        ,iv_token_name2  => cv_cnt_token
                        ,iv_token_value2 => TO_CHAR(gn_upd_cnt0)
                       );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
      END IF;
      --
      -- ������1�̃O���[�vID�̌������o��
      IF ( gn_upd_cnt1 > 0 ) THEN
        gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cfo
                        ,iv_name         => cv_msg_010a03_005
                        ,iv_token_name1  => cv_tkn_group_id
                        ,iv_token_value1 => TO_CHAR(gt_group_id1)
                        ,iv_token_name2  => cv_cnt_token
                        ,iv_token_value2 => TO_CHAR(gn_upd_cnt1)
                       );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
      END IF;
      --
      -- ������2�̃O���[�vID�̌������o��
      IF ( gn_upd_cnt2 > 0 ) THEN
        gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cfo
                        ,iv_name         => cv_msg_010a03_005
                        ,iv_token_name1  => cv_tkn_group_id
                        ,iv_token_value1 => TO_CHAR(gt_group_id2)
                        ,iv_token_name2  => cv_cnt_token
                        ,iv_token_value2 => TO_CHAR(gn_upd_cnt2)
                       );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
      END IF;
      --
      -- ������3�̃O���[�vID�̌������o��
      IF ( gn_upd_cnt3 > 0 ) THEN
        gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cfo
                        ,iv_name         => cv_msg_010a03_005
                        ,iv_token_name1  => cv_tkn_group_id
                        ,iv_token_value1 => TO_CHAR(gt_group_id3)
                        ,iv_token_name2  => cv_cnt_token
                        ,iv_token_value2 => TO_CHAR(gn_upd_cnt3)
                       );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
      END IF;
      --
      -- ������4�̃O���[�vID�̌������o��
      IF ( gn_upd_cnt4 > 0 ) THEN
        gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cfo
                        ,iv_name         => cv_msg_010a03_005
                        ,iv_token_name1  => cv_tkn_group_id
                        ,iv_token_value1 => TO_CHAR(gt_group_id4)
                        ,iv_token_name2  => cv_cnt_token
                        ,iv_token_value2 => TO_CHAR(gn_upd_cnt4)
                       );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
      END IF;
      --
    END IF;
    --
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
       which  => FND_FILE.OUTPUT
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
END XXCFO010A03C;
/
