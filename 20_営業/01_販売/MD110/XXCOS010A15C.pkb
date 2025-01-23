CREATE OR REPLACE PACKAGE BODY XXCOS010A15C
AS
/*************************************************************************
 * Copyright(c)SCSK Corporation, 2024. All rights reserved.
 * 
 * Package Name    : XXCOS010A15C(body)
 * Description     : PaaS���הԍ��A�g����
 * MD.050          : T_MD050_COS_010_A15_PaaS���הԍ��A�g����
 * Version         : 1.0
 * 
 * Program List
 * -------------------- -----------------------------------------------------
 *  Name                Description
 * -------------------- -----------------------------------------------------
 *  init                ��������(A-1)
 *  update_order_line   �󒍖��ׂ̍X�V����(A-3)
 *  update_mng_tbl      �Ǘ��e�[�u���X�V����(A-4)
 *  submain             ���C�������v���V�[�W��
 *  main                �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 * 
 * Change Record
 * ------------- ----- ------------- -------------------------------------
 *  Date          Ver.  Editor        Description
 * ------------- ----- ------------- -------------------------------------
 *  2024-10-08    1.0   Y.Ooyama      ����쐬
 *
 ************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; -- ����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   -- �x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  -- �ُ�:2
  --WHO�J����
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;                 -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                            -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;                -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id;         -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;            -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id;         -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                            -- PROGRAM_UPDATE_DATE
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
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  -- ���b�N�G���[
  lock_expt EXCEPTION;
  PRAGMA EXCEPTION_INIT( lock_expt, -54 );
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(15) := 'XXCOS010A15C';        -- �p�b�P�[�W��
  -- �A�v���P�[�V�����Z�k��
  cv_appl_xxcos      CONSTANT VARCHAR2(5)  := 'XXCOS';               -- �A�h�I���F�̔��̈�
  -- �A�g�����Ǘ��e�[�u������
  cv_func_id         CONSTANT VARCHAR2(15) := 'XXCOS010A15C';        -- �@�\ID
  -- ���b�Z�[�W
  cv_msg_cos1_00001  CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00001';    -- ���b�N�G���[���b�Z�[�W
  cv_msg_cos1_16001  CONSTANT VARCHAR2(20) := 'APP-XXCOS1-16001';    -- �O�񏈗������擾�G���[���b�Z�[�W
  cv_msg_cos1_16002  CONSTANT VARCHAR2(20) := 'APP-XXCOS1-16002';    -- ���������o�̓��b�Z�[�W
  cv_msg_cos1_00011  CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00011';    -- �X�V�G���[���b�Z�[�W
  -- �g�[�N�����b�Z�[�W
  cv_msg_cos1_11524  CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11524';    -- �󒍖���
  cv_msg_cos1_16010  CONSTANT VARCHAR2(20) := 'APP-XXCOS1-16010';    -- �A�g�����Ǘ��e�[�u��
  cv_msg_cos1_10258  CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10258';    -- �󒍖���ID
  -- �g�[�N��
  cv_tkn_date1       CONSTANT VARCHAR2(20) := 'DATE1';               -- ����1
  cv_tkn_date2       CONSTANT VARCHAR2(20) := 'DATE2';               -- ����2
  cv_tkn_count       CONSTANT VARCHAR2(20) := 'COUNT';               -- ����
  cv_tkn_table       CONSTANT VARCHAR2(20) := 'TABLE';               -- �e�[�u����
  cv_tkn_table_nm    CONSTANT VARCHAR2(20) := 'TABLE_NAME';          -- �e�[�u����
  cv_tkn_key_data    CONSTANT VARCHAR2(20) := 'KEY_DATA';            -- �L�[�f�[�^
  -- ����������
  cv_datetime_fmt    CONSTANT VARCHAR2(21) := 'YYYY/MM/DD HH24:MI:SS';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_cur_proc_date            DATE;               -- ���񏈗�����
  gd_pre_proc_date            DATE;               -- �O�񏈗�����
--
  -- ==============================
  -- ���[�U�[��`�O���[�o���J�[�\��
  -- ==============================
--
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
      ov_errbuf               OUT VARCHAR2     -- �G���[�E���b�Z�[�W            # �Œ� #
    , ov_retcode              OUT VARCHAR2     -- ���^�[���E�R�[�h              # �Œ� #
    , ov_errmsg               OUT VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W  # �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf    VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode   VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg    VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- *** ���[�J���ϐ� ***
    -- *** ���[�J���E�J�[�\�� ***
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
    ----------------------------------------------
    -- ���񏈗��������擾
    ----------------------------------------------
    gd_cur_proc_date := SYSDATE;
    --
    ----------------------------------------------
    -- �O�񏈗��������擾
    ----------------------------------------------
    BEGIN
      SELECT
          xipm.pre_process_date          -- �O�񏈗�����
      INTO
          gd_pre_proc_date
      FROM
          xxccp_if_process_mng  xipm     -- �A�g�����Ǘ��e�[�u��
      WHERE
          xipm.function_id = cv_func_id  -- �@�\ID
      FOR UPDATE NOWAIT
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �f�[�^���擾�ł��Ȃ��ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_xxcos             -- �A�v���P�[�V�����Z�k���FXXCOS
                       , iv_name         => cv_msg_cos1_16001         -- ���b�Z�[�W���F�O�񏈗������擾�G���[���b�Z�[�W
                     );
        lv_errbuf  := lv_errmsg;
        RAISE global_process_expt;
      WHEN lock_expt THEN
        -- ���b�N�Ɏ��s�����ꍇ
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_xxcos             -- �A�v���P�[�V�����Z�k���FXXCOS
                       , iv_name         => cv_msg_cos1_00001         -- ���b�Z�[�W���F���b�N�G���[���b�Z�[�W
                       , iv_token_name1  => cv_tkn_table              -- �g�[�N����1�FTABLE
                       , iv_token_value1 => cv_msg_cos1_16010         -- �g�[�N���l1�F�A�g�����Ǘ��e�[�u��
                      );
        lv_errbuf  := lv_errmsg;
        RAISE global_process_expt;
    END;
    --
    ----------------------------------------------
    -- ���������o�̓��b�Z�[�W���o��
    ----------------------------------------------
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_xxcos                -- �A�v���P�[�V�����Z�k���FXXCOS
                    , iv_name         => cv_msg_cos1_16002            -- ���b�Z�[�W���F���������o�̓��b�Z�[�W
                    , iv_token_name1  => cv_tkn_date1                 -- �g�[�N����1�FDATE1
                    , iv_token_value1 => TO_CHAR(
                                             gd_pre_proc_date
                                           , cv_datetime_fmt
                                         )                            -- �g�[�N���l1�F�O�񏈗�����
                    , iv_token_name2  => cv_tkn_date2                 -- �g�[�N����2�FDATE2
                    , iv_token_value2 => TO_CHAR(
                                             gd_cur_proc_date
                                           , cv_datetime_fmt
                                         )                            -- �g�[�N���l2�F���񏈗�����
                  );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    -- ��s�}��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
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
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
--
  /**********************************************************************************
   * Procedure Name   : update_order_line
   * Description      : �󒍖��ׂ̍X�V����(A-3)
   ***********************************************************************************/
  PROCEDURE update_order_line(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_order_line';       -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    lt_lock_line_id           oe_order_lines_all.line_id%TYPE;   -- ���b�N����ID
    lv_key_info               VARCHAR2(50);                      -- �L�[��� (�󒍖���ID = XXXXX)
    --
    -- *** ���[�J���E�J�[�\�� ***
    ----------------------------------------------
    -- �󒍖��הԍ��A�g�f�[�^���o�J�[�\��
    ----------------------------------------------
    -- ���󒍖��הԍ��A�g�}�e�r���[�ɂ́A���L�ɑ�������������܂܂�Ă��܂��B
    --   �󒍖��הԍ��A�g�}�e�r���[�DCREATION_DATE�i�쐬���j >= �u�O�񏈗������v�iPaaS���הԍ��A�g�����j - 9/24
    CURSOR get_line_cur
    IS
      SELECT
          oola.line_id                   AS line_id             -- ����ID
        , xolnim.line_number_paas        AS line_number_paas    -- PAAS�󒍖��הԍ�
      FROM
          xxcos_order_line_number_if_mv  xolnim                 -- �󒍖��הԍ��A�g�}�e�r���[
        , oe_order_headers_all           ooha                   -- �󒍃w�b�_
        , oe_order_lines_all             oola                   -- �󒍖���
      WHERE
          xolnim.order_number_ebs  = ooha.order_number
      AND ooha.header_id           = oola.header_id
      AND xolnim.line_number_ebs   = oola.line_number
      AND xolnim.creation_date     < gd_cur_proc_date - 9/24    -- �쐬�� < ���񏈗�����(JST->UTC)
      ORDER BY
          xolnim.order_number_ebs  ASC                          -- EBS�󒍔ԍ�(����)
        , xolnim.line_number_ebs   ASC                          -- EBS�󒍖��הԍ�(����)
    ;
    --
    -- *** ���[�J���E���R�[�h ***
    -- �󒍖��הԍ��A�g�f�[�^���o�J�[�\���E���R�[�h
    l_get_line_rec        get_line_cur%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    ----------------------------------------------
    -- �󒍖��הԍ��A�g�f�[�^���o(A-2)
    ----------------------------------------------
    -- �J�[�\���I�[�v��
    OPEN get_line_cur;
    <<get_line_loop>>
    LOOP
      --
      FETCH get_line_cur INTO l_get_line_rec;
      EXIT WHEN get_line_cur%NOTFOUND;
      --
      -- �󒍖��הԍ��A�g�f�[�^�̒��o�������J�E���g�A�b�v
      gn_target_cnt := gn_target_cnt + 1;
      --
      ----------------------------------------------
      -- �󒍖��ׂ̍X�V����
      ----------------------------------------------
      BEGIN
        -- ���b�N
        SELECT
            oola.line_id        AS line_id   -- ����ID
        INTO
            lt_lock_line_id
        FROM
            oe_order_lines_all  oola         -- �󒍖���
        WHERE
            oola.line_id        = l_get_line_rec.line_id
        FOR UPDATE NOWAIT
        ;
        --
        -- �X�V
        UPDATE
            oe_order_lines_all  oola  -- �󒍖���
        SET
            oola.global_attribute8       = l_get_line_rec.line_number_paas     -- PAAS�󒍖��הԍ�
          , oola.last_updated_by         = cn_last_updated_by                  -- �ŏI�X�V��
          , oola.last_update_date        = cd_last_update_date                 -- �ŏI�X�V��
          , oola.last_update_login       = cn_last_update_login                -- �ŏI�X�V���O�C��
          , oola.request_id              = cn_request_id                       -- �v��ID
          , oola.program_application_id  = cn_program_application_id           -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          , oola.program_id              = cn_program_id                       -- �R���J�����g�E�v���O����ID
          , oola.program_update_date     = cd_program_update_date              -- �v���O�����X�V��
        WHERE
            oola.line_id                 = l_get_line_rec.line_id              -- ����ID
        ;
        --
        -- �󒍖��ׂ̍X�V�������J�E���g�A�b�v
        gn_normal_cnt := gn_normal_cnt + 1;
      --
      EXCEPTION
        WHEN lock_expt THEN
          -- ���b�N�Ɏ��s�����ꍇ
          lv_errmsg  := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_xxcos           -- �A�v���P�[�V�����Z�k���FXXCOS
                         , iv_name         => cv_msg_cos1_00001       -- ���b�Z�[�W���F���b�N�G���[���b�Z�[�W
                         , iv_token_name1  => cv_tkn_table            -- �g�[�N����1�FTABLE
                         , iv_token_value1 => cv_msg_cos1_11524       -- �g�[�N���l1�F�󒍖���
                        );
          lv_errbuf  := lv_errmsg;
          RAISE global_process_expt;
        WHEN OTHERS THEN
          -- �X�V�Ɏ��s�����ꍇ
          -- �L�[��񐶐�
          lv_key_info := xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_xxcos         -- �A�v���P�[�V�����Z�k���FXXCOS
                           , iv_name         => cv_msg_cos1_10258     -- ���b�Z�[�W���F�󒍖���ID
                         );
          lv_key_info := lv_key_info || ' = ' || TO_CHAR(l_get_line_rec.line_id);
          --
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_xxcos           -- �A�v���P�[�V�����Z�k���FXXCOS
                         , iv_name         => cv_msg_cos1_00011       -- ���b�Z�[�W���F�X�V�G���[���b�Z�[�W
                         , iv_token_name1  => cv_tkn_table_nm         -- �g�[�N����1�FTABLE_NAME
                         , iv_token_value1 => cv_msg_cos1_11524       -- �g�[�N���l1�F�󒍖���
                         , iv_token_name2  => cv_tkn_key_data         -- �g�[�N����2�FKEY_DATA
                         , iv_token_value2 => lv_key_info             -- �g�[�N���l2�F�L�[���
                       );
          lv_errbuf  := lv_errmsg;
          RAISE global_process_expt;
      END;
    --
    END LOOP get_line_loop;
    --
    -- ���o�J�[�\���N���[�Y
    CLOSE get_line_cur;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- ���o�J�[�\���N���[�Y
      IF ( get_line_cur%ISOPEN ) THEN
        CLOSE get_line_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- ���o�J�[�\���N���[�Y
      IF ( get_line_cur%ISOPEN ) THEN
        CLOSE get_line_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- ���o�J�[�\���N���[�Y
      IF ( get_line_cur%ISOPEN ) THEN
        CLOSE get_line_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- ���o�J�[�\���N���[�Y
      IF ( get_line_cur%ISOPEN ) THEN
        CLOSE get_line_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END update_order_line;
--
--
  /**********************************************************************************
   * Procedure Name   : update_mng_tbl
   * Description      : �Ǘ��e�[�u���X�V����(A-4)
   ***********************************************************************************/
  PROCEDURE update_mng_tbl(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_mng_tbl';       -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    -- *** ���[�J���E�J�[�\�� ***
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
    ----------------------------------------------
    -- �A�g�����Ǘ��e�[�u���̍X�V
    ----------------------------------------------
    BEGIN
      -- �X�V
      UPDATE
          xxccp_if_process_mng  xipm    -- �A�g�����Ǘ��e�[�u��
      SET
          xipm.pre_process_date       = gd_cur_proc_date              -- �O�񏈗����� = A-1�Ŏ擾�������񏈗�����
        , xipm.last_updated_by        = cn_last_updated_by            -- �ŏI�X�V��
        , xipm.last_update_date       = cd_last_update_date           -- �ŏI�X�V��
        , xipm.last_update_login      = cn_last_update_login          -- �ŏI�X�V���O�C��
        , xipm.request_id             = cn_request_id                 -- �v��ID
        , xipm.program_application_id = cn_program_application_id     -- �v���O�����A�v���P�[�V����ID
        , xipm.program_id             = cn_program_id                 -- �v���O����ID
        , xipm.program_update_date    = cd_program_update_date        -- �v���O�����X�V��
      WHERE
          xipm.function_id            = cv_func_id                    -- �@�\ID
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- �X�V�Ɏ��s�����ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_xxcos             -- �A�v���P�[�V�����Z�k���FXXCOS
                       , iv_name         => cv_msg_cos1_00011         -- ���b�Z�[�W���F�X�V�G���[���b�Z�[�W
                       , iv_token_name1  => cv_tkn_table_nm           -- �g�[�N����1�FTABLE_NAME
                       , iv_token_value1 => cv_msg_cos1_16010         -- �g�[�N���l1�F�A�g�����Ǘ��e�[�u��
                       , iv_token_name2  => cv_tkn_key_data           -- �g�[�N����2�FKEY_DATA
                       , iv_token_value2 => NULL                      -- �g�[�N���l2�FNULL
                     );
        lv_errbuf  := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
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
--
--#####################################  �Œ蕔 END   ##########################################
--
  END update_mng_tbl;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
      ov_errbuf               OUT VARCHAR2     -- �G���[�E���b�Z�[�W            # �Œ� #
    , ov_retcode              OUT VARCHAR2     -- ���^�[���E�R�[�h              # �Œ� #
    , ov_errmsg               OUT VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W  # �Œ� #
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
    -- *** ���[�J���ϐ� ***
    -- *** ���[�J���E�J�[�\�� ***
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
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
    --
    -- ======================================================
    --  ��������(A-1)
    -- ======================================================
    init(
        ov_errbuf        => lv_errbuf        -- �G���[�E���b�Z�[�W
      , ov_retcode       => lv_retcode       -- ���^�[���E�R�[�h
      , ov_errmsg        => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- ======================================================
    --  �󒍖��ׂ̍X�V����(A-3)
    --  ���󒍖��הԍ��A�g�f�[�^���o(A-2)�܂�
    -- ======================================================
    update_order_line(
        ov_errbuf        => lv_errbuf        -- �G���[�E���b�Z�[�W
      , ov_retcode       => lv_retcode       -- ���^�[���E�R�[�h
      , ov_errmsg        => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- ======================================================
    --  �Ǘ��e�[�u���X�V����(A-4)
    -- ======================================================
    update_mng_tbl(
        ov_errbuf        => lv_errbuf        -- �G���[�E���b�Z�[�W
      , ov_retcode       => lv_retcode       -- ���^�[���E�R�[�h
      , ov_errmsg        => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
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
--####################################  �Œ蕔 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
      errbuf                  OUT VARCHAR2      -- �G���[�E���b�Z�[�W   # �Œ� #
    , retcode                 OUT VARCHAR2      -- ���^�[���E�R�[�h     # �Œ� #
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
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�h�I���F���ʁEIF�̈�
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
--    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- �X�L�b�v�������b�Z�[�W
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
      , ov_errbuf  => lv_errbuf
      , ov_errmsg  => lv_errmsg
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
        lv_errbuf                -- �G���[�E���b�Z�[�W            # �Œ� #
      , lv_retcode               -- ���^�[���E�R�[�h              # �Œ� #
      , lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W  # �Œ� #
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      -- �G���[����
      gn_normal_cnt := 0;                 -- ��������
      gn_error_cnt  := 1;                 -- �G���[����
      --
      -- �G���[���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => lv_errbuf --�G���[���b�Z�[�W
      );
      -- ��s�}��
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => ''
      );
    END IF;
    --
    --------------------------
    -- ���ʌ������o��
    --------------------------
    -- �Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_target_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_target_cnt)
                  );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --
    -- ���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_success_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_normal_cnt)
                  );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_error_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_error_cnt)
                  );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
--    --�X�L�b�v�����o��
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_appl_short_name
--                    , iv_name         => cv_skip_rec_msg
--                    , iv_token_name1  => cv_cnt_token
--                    , iv_token_value1 => TO_CHAR(gn_warn_cnt)
--                  );
--    FND_FILE.PUT_LINE(
--        which  => FND_FILE.OUTPUT
--      , buff   => gv_out_msg
--    );
    --
    --------------------------
    -- �I�����b�Z�[�W
    --------------------------
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => lv_message_code
                  );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    -- �X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    -- �I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF ( retcode = cv_status_error ) THEN
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
END XXCOS010A15C;
/
