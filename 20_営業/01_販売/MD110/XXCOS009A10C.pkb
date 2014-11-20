CREATE OR REPLACE PACKAGE BODY APPS.XXCOS009A10C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOS009A10C(body)
 * Description      : �󒍈ꗗ���󒍃G���[���X�g���s
 * MD.050           : MD050_COS_009_A10_�󒍈ꗗ���󒍃G���[���X�g���s
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  exe_xxcos009a01r       �󒍈ꗗ���X�g���s����(A-2)
 *  exe_xxcos010a05r_1     �󒍃G���[���X�g�i�󒍁j���s����(A-3)
 *  exe_xxcos010a05r_2     �󒍃G���[���X�g�i�[�i�m��j���s����(A-4)
 *  func_wait_for_request  �R���J�����g�I���ҋ@�����֐�
 *  wait_for_request       �R���J�����g�I���ҋ@����(A-5)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                         �I������(A-6)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012/12/20    1.0   K.Nakamura       main�V�K�쐬
 *
 *****************************************************************************************/
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
  cv_pkg_name                 CONSTANT VARCHAR2(20) := 'XXCOS009A10C';            -- �p�b�P�[�W��
  -- �A�v���P�[�V�����Z�k��
  cv_application              CONSTANT VARCHAR2(5)  := 'XXCOS';                   -- �A�v���P�[�V����
  cv_appl_short_name          CONSTANT VARCHAR2(5)  := 'XXCCP';                   -- �A�h�I���F���ʁEIF�̈�
  -- �v���t�@�C��
  cv_interval                 CONSTANT VARCHAR2(30) := 'XXCOS1_INTERVAL_XXCOS009A10C'; -- XXCOS:�ҋ@�Ԋu�i�󒍈ꗗ���󒍃G���[���X�g���s�j
  cv_max_wait                 CONSTANT VARCHAR2(30) := 'XXCOS1_MAX_WAIT_XXCOS009A10C'; -- XXCOS:�ő�ҋ@���ԁi�󒍈ꗗ���󒍃G���[���X�g���s�j
  -- �R���J�����g����
  cv_xxcos009a012r            CONSTANT VARCHAR2(20) := 'XXCOS009A012R';           -- �󒍈ꗗ���X�g�iEDI�p�j�i�V�K�j
  cv_xxcos010a052r            CONSTANT VARCHAR2(20) := 'XXCOS010A052R';           -- �󒍃G���[���X�g
  -- �R���J�����gdev�X�e�[�^�X
  cv_dev_status_normal        CONSTANT VARCHAR2(10) := 'NORMAL';                  -- '����'
  cv_dev_status_warn          CONSTANT VARCHAR2(10) := 'WARNING';                 -- '�x��'
  -- ���b�Z�[�W
  cv_msg_xxcos_00004          CONSTANT VARCHAR2(16) := 'APP-XXCOS1-00004';        -- �v���t�@�C���擾�G���[
  cv_msg_xxcos_00005          CONSTANT VARCHAR2(16) := 'APP-XXCOS1-00005';        -- ���t�t�]�G���[
  cv_msg_xxcos_14551          CONSTANT VARCHAR2(16) := 'APP-XXCOS1-14551';        -- �󒍈ꗗ���X�g
  cv_msg_xxcos_14552          CONSTANT VARCHAR2(16) := 'APP-XXCOS1-14552';        -- �󒍃G���[���X�g�i�󒍁j
  cv_msg_xxcos_14553          CONSTANT VARCHAR2(16) := 'APP-XXCOS1-14553';        -- �󒍃G���[���X�g�i�[�i�m��j
  cv_msg_xxcos_14554          CONSTANT VARCHAR2(16) := 'APP-XXCOS1-14554';        -- �G���[���X�g�pEDI��M��(FROM)
  cv_msg_xxcos_14555          CONSTANT VARCHAR2(16) := 'APP-XXCOS1-14555';        -- �G���[���X�g�pEDI��M��(TO)
  cv_msg_xxcos_14556          CONSTANT VARCHAR2(16) := 'APP-XXCOS1-14556';        -- �p�����[�^�o�̓��b�Z�[�W
  cv_msg_xxcos_14557          CONSTANT VARCHAR2(16) := 'APP-XXCOS1-14557';        -- �R���J�����g�N���G���[���b�Z�[�W
  cv_msg_xxcos_14558          CONSTANT VARCHAR2(16) := 'APP-XXCOS1-14558';        -- �ҋ@���Ԍo�߃��b�Z�[�W
  cv_msg_xxcos_14559          CONSTANT VARCHAR2(16) := 'APP-XXCOS1-14559';        -- �R���J�����g����I�����b�Z�[�W
  cv_msg_xxcos_14560          CONSTANT VARCHAR2(16) := 'APP-XXCOS1-14560';        -- �R���J�����g�x���I�����b�Z�[�W
  cv_msg_xxcos_14561          CONSTANT VARCHAR2(16) := 'APP-XXCOS1-14561';        -- �R���J�����g�G���[�I�����b�Z�[�W
  cv_msg_xxcos_14562          CONSTANT VARCHAR2(16) := 'APP-XXCOS1-14562';        -- �G���[�I�����b�Z�[�W
  -- �g�[�N���R�[�h
  cv_tkn_param1               CONSTANT VARCHAR2(20) := 'PARAM1';                  -- �p�����[�^���P
  cv_tkn_param2               CONSTANT VARCHAR2(20) := 'PARAM2';                  -- �p�����[�^���Q
  cv_tkn_param3               CONSTANT VARCHAR2(20) := 'PARAM3';                  -- �p�����[�^���R
  cv_tkn_param4               CONSTANT VARCHAR2(20) := 'PARAM4';                  -- �p�����[�^���S
  cv_tkn_param5               CONSTANT VARCHAR2(20) := 'PARAM5';                  -- �p�����[�^���T
  cv_tkn_param6               CONSTANT VARCHAR2(20) := 'PARAM6';                  -- �p�����[�^���U
  cv_tkn_param7               CONSTANT VARCHAR2(20) := 'PARAM7';                  -- �p�����[�^���V
  cv_tkn_date_from            CONSTANT VARCHAR2(20) := 'DATE_FROM';               -- �p�����[�^FROM
  cv_tkn_date_to              CONSTANT VARCHAR2(20) := 'DATE_TO';                 -- �p�����[�^TO
  cv_tkn_profile              CONSTANT VARCHAR2(20) := 'PROFILE';                 -- �v���t�@�C������
  cv_tkn_conc_name            CONSTANT VARCHAR2(20) := 'CONC_NAME';               -- �R���J�����g����
  cv_tkn_request_id           CONSTANT VARCHAR2(20) := 'REQUEST_ID';              -- �v��ID
  -- �G���[���X�g���
  cv_err_list_type_01         CONSTANT VARCHAR2(2)  := '01';                      -- ��
  cv_err_list_type_02         CONSTANT VARCHAR2(2)  := '02';                      -- �[�i�m��
  -- ���t����
  cv_yyyymmdd                 CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';              -- YYYY/MM/DD�^
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_retcode                  VARCHAR2(1)  DEFAULT cv_status_normal; -- �e�R���J�����g�p���^�[���R�[�h
  gv_msg_xxcos_14551          VARCHAR2(30) DEFAULT NULL;             -- �󒍈ꗗ���X�g
  gv_msg_xxcos_14552          VARCHAR2(30) DEFAULT NULL;             -- �󒍃G���[���X�g�i�󒍁j
  gv_msg_xxcos_14553          VARCHAR2(30) DEFAULT NULL;             -- �󒍃G���[���X�g�i�[�i�m��j
  gn_interval                 NUMBER       DEFAULT NULL;             -- �R���J�����g�Ď��Ԋu
  gn_max_wait                 NUMBER       DEFAULT NULL;             -- �R���J�����g�Ď��ő厞��
  gn_request_id1              NUMBER       DEFAULT NULL;             -- �󒍈ꗗ���X�g�̗v��ID
  gn_request_id2              NUMBER       DEFAULT NULL;             -- �󒍃G���[���X�g�i�󒍁j�̗v��ID
  gn_request_id3              NUMBER       DEFAULT NULL;             -- �󒍃G���[���X�g�i�[�i�m��j�̗v��ID
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_order_source             IN  VARCHAR2, -- �󒍃\�[�X
    iv_delivery_base_code       IN  VARCHAR2, -- �[�i���_�R�[�h
    iv_output_type              IN  VARCHAR2, -- �o�͋敪
    iv_output_quantity_type     IN  VARCHAR2, -- �o�͐��ʋ敪
    iv_request_type             IN  VARCHAR2, -- �Ĕ��s�敪
    iv_edi_received_date_from   IN  VARCHAR2, -- �G���[���X�g�pEDI��M��(FROM)
    iv_edi_received_date_to     IN  VARCHAR2, -- �G���[���X�g�pEDI��M��(TO)
    ov_errbuf                   OUT VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                  OUT VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                   OUT VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- *** ���[�J���ϐ� ***
    lv_param_msg                VARCHAR2(5000); -- �p�����[�^�o�͗p
    lv_out_msg1                 VARCHAR2(40);   -- �o�͗p����
    lv_out_msg2                 VARCHAR2(40);   -- �o�͗p����
    ld_edi_received_date_from   DATE;           -- �G���[���X�g�pEDI��M��(FROM)
    ld_edi_received_date_to     DATE;           -- �G���[���X�g�pEDI��M��(TO)
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    -- �p�����[�^�o��
    --==============================================================
    --���b�Z�[�W�ҏW
    lv_param_msg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_application              -- �A�v���P�[�V����
                      , iv_name          => cv_msg_xxcos_14556          -- ���b�Z�[�W�R�[�h
                      , iv_token_name1   => cv_tkn_param1               -- �g�[�N���R�[�h�P
                      , iv_token_value1  => iv_order_source             -- �󒍃\�[�X
                      , iv_token_name2   => cv_tkn_param2               -- �g�[�N���R�[�h�Q
                      , iv_token_value2  => iv_delivery_base_code       -- �[�i���_�R�[�h
                      , iv_token_name3   => cv_tkn_param3               -- �g�[�N���R�[�h�R
                      , iv_token_value3  => iv_output_type              -- �o�͋敪
                      , iv_token_name4   => cv_tkn_param4               -- �g�[�N���R�[�h�S
                      , iv_token_value4  => iv_output_quantity_type     -- �o�͐��ʋ敪
                      , iv_token_name5   => cv_tkn_param5               -- �g�[�N���R�[�h�T
                      , iv_token_value5  => iv_request_type             -- �Ĕ��s�敪
                      , iv_token_name6   => cv_tkn_param6               -- �g�[�N���R�[�h�U
                      , iv_token_value6  => iv_edi_received_date_from   -- �G���[���X�g�pEDI��M��(FROM)
                      , iv_token_name7   => cv_tkn_param7               -- �g�[�N���R�[�h�V
                      , iv_token_value7  => iv_edi_received_date_to     -- �G���[���X�g�pEDI��M��(TO)
                    );
    -- �o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_param_msg
    );
    -- �o�͋�s
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    -- ���O
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_param_msg
    );
    -- ���O��s
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    -- DATE�^�ϊ�
    ld_edi_received_date_from := TO_DATE( iv_edi_received_date_from, cv_yyyymmdd );
    ld_edi_received_date_to   := TO_DATE( iv_edi_received_date_to, cv_yyyymmdd );
    -- ���t�t�]�`�F�b�N
    IF ( ld_edi_received_date_from > ld_edi_received_date_to ) THEN
      lv_out_msg1 := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_msg_xxcos_14554 -- ���b�Z�[�W�R�[�h
                     );
      lv_out_msg2 := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_msg_xxcos_14555 -- ���b�Z�[�W�R�[�h
                     );
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_msg_xxcos_00005 -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_date_from   -- �g�[�N���R�[�h�P
                     , iv_token_value1 => lv_out_msg1        -- �G���[���X�g�pEDI��M��(FROM)
                     , iv_token_name2  => cv_tkn_date_to     -- �g�[�N���R�[�h�Q
                     , iv_token_value2 => lv_out_msg2        -- �G���[���X�g�pEDI��M��(TO)
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- �v���t�@�C���̎擾
    --==================================
    BEGIN
      -- XXCOS:�ҋ@�Ԋu�i�󒍈ꗗ���󒍃G���[���X�g���s�j
      gn_interval := TO_NUMBER(FND_PROFILE.VALUE( cv_interval ));
      -- �v���t�@�C���l�`�F�b�N
      IF ( gn_interval IS NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application      -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_msg_xxcos_00004  -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_profile      -- �g�[�N���R�[�h1
                       , iv_token_value1 => cv_interval         -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application      -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_msg_xxcos_00004  -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_profile      -- �g�[�N���R�[�h1
                       , iv_token_value1 => cv_interval         -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
    --
    BEGIN
      -- XXCOS:�ő�ҋ@���ԁi�󒍈ꗗ���󒍃G���[���X�g���s�j
      gn_max_wait := TO_NUMBER(FND_PROFILE.VALUE( cv_max_wait ));
      -- �v���t�@�C���l�`�F�b�N
      IF ( gn_max_wait IS NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application      -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_msg_xxcos_00004  -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_profile      -- �g�[�N���R�[�h1
                       , iv_token_value1 => cv_max_wait         -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application      -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_msg_xxcos_00004  -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_profile      -- �g�[�N���R�[�h1
                       , iv_token_value1 => cv_max_wait         -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- �Œ蕶��
    gv_msg_xxcos_14551 := xxccp_common_pkg.get_msg(
                              iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                            , iv_name         => cv_msg_xxcos_14551 -- ���b�Z�[�W�R�[�h
                          );
    gv_msg_xxcos_14552 := xxccp_common_pkg.get_msg(
                              iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                            , iv_name         => cv_msg_xxcos_14552 -- ���b�Z�[�W�R�[�h
                          );
    gv_msg_xxcos_14553 := xxccp_common_pkg.get_msg(
                              iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                            , iv_name         => cv_msg_xxcos_14553 -- ���b�Z�[�W�R�[�h
                          );
--
  EXCEPTION
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
   * Procedure Name   : exe_xxcos009a01r
   * Description      : �󒍈ꗗ���X�g���s����(A-2)
   ***********************************************************************************/
  PROCEDURE exe_xxcos009a01r(
    iv_order_source             IN  VARCHAR2, -- �󒍃\�[�X
    iv_delivery_base_code       IN  VARCHAR2, -- �[�i���_�R�[�h
    iv_output_type              IN  VARCHAR2, -- �o�͋敪
    iv_output_quantity_type     IN  VARCHAR2, -- �o�͐��ʋ敪
    ov_errbuf                   OUT VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                  OUT VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                   OUT VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'exe_xxcos009a01r'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
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
    --==============================================================
    -- �R���J�����g���s
    --==============================================================
    gn_request_id1 := fnd_request.submit_request(
                          application => cv_application              -- �A�v���P�[�V�����Z�k��
                        , program     => cv_xxcos009a012r            -- �R���J�����g�v���O������
                        , description => NULL                        -- �E�v
                        , start_time  => NULL                        -- �J�n����
                        , sub_request => FALSE                       -- �T�u�v��
                        , argument1   => iv_order_source             -- �󒍃\�[�X
                        , argument2   => iv_delivery_base_code       -- �[�i���_�R�[�h
                        , argument3   => NULL                        -- �󒍓�(FROM)
                        , argument4   => NULL                        -- �󒍓�(TO)
                        , argument5   => NULL                        -- �o�ח\���(FROM)
                        , argument6   => NULL                        -- �o�ח\���(TO)
                        , argument7   => NULL                        -- �[�i�\���(FROM)
                        , argument8   => NULL                        -- �[�i�\���(TO)
                        , argument9   => NULL                        -- ���͎҃R�[�h
                        , argument10  => NULL                        -- �o�א�R�[�h
                        , argument11  => NULL                        -- �ۊǏꏊ
                        , argument12  => NULL                        -- �󒍔ԍ�
                        , argument13  => iv_output_type              -- �o�͋敪
                        , argument14  => NULL                        -- �`�F�[���X�R�[�h
                        , argument15  => NULL                        -- ��M��(FROM)
                        , argument16  => NULL                        -- ��M��(TO)
                        , argument17  => NULL                        -- �[�i��(FROM)
                        , argument18  => NULL                        -- �[�i��(TO)
                        , argument19  => NULL                        -- �X�e�[�^�X
                        , argument20  => iv_output_quantity_type     -- �o�͐��ʋ敪
                      );
    -- ����ȊO�̏ꍇ
    IF ( gn_request_id1 = 0 ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_msg_xxcos_14557 -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_conc_name   -- �g�[�N���R�[�h�P
                     , iv_token_value1 => gv_msg_xxcos_14551 -- �󒍈ꗗ���X�g
                   );
      lv_errbuf := lv_errmsg;
      --
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      --�P�s���s
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000)
      );
      --�P�s���s
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => ''
      );
      -- �e�R���J�����g�p���^�[���R�[�h
      gv_retcode := cv_status_error;
    END IF;
--
    -- �R�~�b�g���s
    COMMIT;
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END exe_xxcos009a01r;
--
  /**********************************************************************************
   * Procedure Name   : exe_xxcos010a05r_1
   * Description      : �󒍃G���[���X�g�i�󒍁j���s����(A-3)
   ***********************************************************************************/
  PROCEDURE exe_xxcos010a05r_1(
    iv_delivery_base_code       IN  VARCHAR2, -- �[�i���_�R�[�h
    iv_request_type             IN  VARCHAR2, -- �Ĕ��s�敪
    iv_edi_received_date_from   IN  VARCHAR2, -- �G���[���X�g�pEDI��M��(FROM)
    iv_edi_received_date_to     IN  VARCHAR2, -- �G���[���X�g�pEDI��M��(TO)
    ov_errbuf                   OUT VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                  OUT VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                   OUT VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'exe_xxcos010a05r_1'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
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
    --==============================================================
    -- �R���J�����g���s
    --==============================================================
    gn_request_id2 := fnd_request.submit_request(
                          application => cv_application            -- �A�v���P�[�V�����Z�k��
                        , program     => cv_xxcos010a052r          -- �R���J�����g�v���O������
                        , description => gv_msg_xxcos_14552        -- �E�v
                        , start_time  => NULL                      -- �J�n����
                        , sub_request => FALSE                     -- �T�u�v��
                        , argument1   => cv_err_list_type_01       -- �G���[���X�g���
                        , argument2   => iv_request_type           -- �Ĕ��s�敪
                        , argument3   => iv_delivery_base_code     -- ���_�R�[�h
                        , argument4   => NULL                      -- �`�F�[���X�R�[�h
                        , argument5   => iv_edi_received_date_from -- EDI��M��(FROM)
                        , argument6   => iv_edi_received_date_to   -- EDI��M��(TO)
                      );
    -- ����ȊO�̏ꍇ
    IF ( gn_request_id2 = 0 ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_msg_xxcos_14557 -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_conc_name   -- �g�[�N���R�[�h�P
                     , iv_token_value1 => gv_msg_xxcos_14552 -- �󒍃G���[���X�g�i�󒍁j
                   );
      lv_errbuf := lv_errmsg;
      --
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      --�P�s���s
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000)
      );
      --�P�s���s
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => ''
      );
      -- �e�R���J�����g�p���^�[���R�[�h
      gv_retcode := cv_status_error;
    END IF;
--
    -- �R�~�b�g���s
    COMMIT;
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END exe_xxcos010a05r_1;
--
  /**********************************************************************************
   * Procedure Name   : exe_xxcos010a05r_2
   * Description      : �󒍃G���[���X�g�i�[�i�m��j���s����(A-4)
   ***********************************************************************************/
  PROCEDURE exe_xxcos010a05r_2(
    iv_delivery_base_code       IN  VARCHAR2, -- �[�i���_�R�[�h
    iv_request_type             IN  VARCHAR2, -- �Ĕ��s�敪
    iv_edi_received_date_from   IN  VARCHAR2, -- �G���[���X�g�pEDI��M��(FROM)
    iv_edi_received_date_to     IN  VARCHAR2, -- �G���[���X�g�pEDI��M��(TO)
    ov_errbuf                   OUT VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                  OUT VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                   OUT VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'exe_xxcos010a05r_2'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
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
    --==============================================================
    -- �R���J�����g���s
    --==============================================================
    gn_request_id3 := fnd_request.submit_request(
                          application => cv_application            -- �A�v���P�[�V�����Z�k��
                        , program     => cv_xxcos010a052r          -- �R���J�����g�v���O������
                        , description => gv_msg_xxcos_14553        -- �E�v
                        , start_time  => NULL                      -- �J�n����
                        , sub_request => FALSE                     -- �T�u�v��
                        , argument1   => cv_err_list_type_02       -- �G���[���X�g���
                        , argument2   => iv_request_type           -- �Ĕ��s�敪
                        , argument3   => iv_delivery_base_code     -- ���_�R�[�h
                        , argument4   => NULL                      -- �`�F�[���X�R�[�h
                        , argument5   => iv_edi_received_date_from -- EDI��M��(FROM)
                        , argument6   => iv_edi_received_date_to   -- EDI��M��(TO)
                      );
    -- ����ȊO�̏ꍇ
    IF ( gn_request_id3 = 0 ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_msg_xxcos_14557 -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_conc_name   -- �g�[�N���R�[�h�P
                     , iv_token_value1 => gv_msg_xxcos_14553 -- �󒍃G���[���X�g�i�[�i�m��j
                   );
      lv_errbuf := lv_errmsg;
      --
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      --�P�s���s
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000)
      );
      --�P�s���s
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => ''
      );
      -- �e�R���J�����g�p���^�[���R�[�h
      gv_retcode := cv_status_error;
    END IF;
--
    -- �R�~�b�g���s
    COMMIT;
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END exe_xxcos010a05r_2;
--
  /**********************************************************************************
   * Procedure Name   : func_wait_for_request
   * Description      : �R���J�����g�I���ҋ@�����֐�
   ***********************************************************************************/
  PROCEDURE func_wait_for_request(
    iv_msg_code                 IN  VARCHAR2, -- �R���J�����g��
    in_request_id               IN  NUMBER,   -- �v��ID
    ov_errbuf                   OUT VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                  OUT VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                   OUT VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'func_wait_for_request'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    -- *** ���[�J���ϐ� ***
    lb_wait_request           BOOLEAN        DEFAULT TRUE;
    lv_phase                  VARCHAR2(50)   DEFAULT NULL;
    lv_status                 VARCHAR2(50)   DEFAULT NULL;
    lv_dev_phase              VARCHAR2(50)   DEFAULT NULL;
    lv_dev_status             VARCHAR2(50)   DEFAULT NULL;
    lv_message                VARCHAR2(5000) DEFAULT NULL;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    -- �R���J�����g�v���ҋ@
    --==============================================================
    lb_wait_request := fnd_concurrent.wait_for_request(
                           request_id => in_request_id -- �v��ID
                         , interval   => gn_interval   -- �R���J�����g�Ď��Ԋu
                         , max_wait   => gn_max_wait   -- �R���J�����g�Ď��ő厞��
                         , phase      => lv_phase      -- �v���t�F�[�Y
                         , status     => lv_status     -- �v���X�e�[�^�X
                         , dev_phase  => lv_dev_phase  -- �v���t�F�[�Y�R�[�h
                         , dev_status => lv_dev_status -- �v���X�e�[�^�X�R�[�h
                         , message    => lv_message    -- �������b�Z�[�W
                       );
    -- �߂�l��FALSE�̏ꍇ
    IF ( lb_wait_request = FALSE ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                     , iv_name         => cv_msg_xxcos_14558
                     , iv_token_name1  => cv_tkn_conc_name
                     , iv_token_value1 => iv_msg_code
                     , iv_token_name2  => cv_tkn_request_id
                     , iv_token_value2 => TO_CHAR(in_request_id)
                   );
      lv_errbuf := lv_errmsg;
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      --�P�s���s
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000)
      );
      --�P�s���s
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => ''
      );
      -- �e�R���J�����g�p���^�[���R�[�h
      gv_retcode := cv_status_error;
    ELSE
      -- ����I�����b�Z�[�W�o��
      IF ( lv_dev_status = cv_dev_status_normal ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_xxcos_14559
                       , iv_token_name1  => cv_tkn_conc_name
                       , iv_token_value1 => iv_msg_code
                       , iv_token_name2  => cv_tkn_request_id
                       , iv_token_value2 => TO_CHAR(in_request_id)
                     );
      -- �x���I�����b�Z�[�W�o��
      ELSIF ( lv_dev_status = cv_dev_status_warn ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_xxcos_14560
                       , iv_token_name1  => cv_tkn_conc_name
                       , iv_token_value1 => iv_msg_code
                       , iv_token_name2  => cv_tkn_request_id
                       , iv_token_value2 => TO_CHAR(in_request_id)
                     );
        -- �e�R���J�����g�p���^�[���R�[�h�i���ɃG���[�̏ꍇ�͂��̂܂܁j
        IF ( gv_retcode = cv_status_normal ) THEN
          gv_retcode := cv_status_warn;
        END IF;
      -- �G���[�I�����b�Z�[�W�o��
      ELSE
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_xxcos_14561
                       , iv_token_name1  => cv_tkn_conc_name
                       , iv_token_value1 => iv_msg_code
                       , iv_token_name2  => cv_tkn_request_id
                       , iv_token_value2 => TO_CHAR(in_request_id)
                     );
        lv_errbuf := lv_errmsg;
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000)
        );
        --�P�s���s
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => ''
        );
        -- �e�R���J�����g�p���^�[���R�[�h
        gv_retcode := cv_status_error;
      END IF;
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      --�P�s���s
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
    END IF;
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END func_wait_for_request;
--
  /**********************************************************************************
   * Procedure Name   : wait_for_request
   * Description      : �R���J�����g�I���ҋ@����(A-5)
   ***********************************************************************************/
  PROCEDURE wait_for_request(
    ov_errbuf                   OUT VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                  OUT VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                   OUT VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'wait_for_request'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
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
    --==============================================================
    -- �R���J�����g�v���ҋ@�i�󒍈ꗗ���X�g�j
    --==============================================================
    -- �R���J�����g���s���G���[�ł͖����ꍇ
    IF ( gn_request_id1 <> 0 ) THEN
      func_wait_for_request(
          gv_msg_xxcos_14551 -- �R���J�����g��
        , gn_request_id1     -- �v��ID
        , lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
        , lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
        , lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
    END IF;
--
    --==============================================================
    -- �R���J�����g�v���ҋ@�i�󒍃G���[���X�g�i�󒍁j�j
    --==============================================================
    -- �R���J�����g���s���G���[�ł͖����ꍇ
    IF ( gn_request_id2 <> 0 ) THEN
      func_wait_for_request(
          gv_msg_xxcos_14552 -- �R���J�����g��
        , gn_request_id2     -- �v��ID
        , lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
        , lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
        , lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
    END IF;
--
    --==============================================================
    -- �R���J�����g�v���ҋ@�i�󒍃G���[���X�g�i�[�i�m��j�j
    --==============================================================
    -- �R���J�����g���s���G���[�ł͖����ꍇ
    IF ( gn_request_id3 <> 0 ) THEN
      func_wait_for_request(
          gv_msg_xxcos_14553 -- �R���J�����g��
        , gn_request_id3     -- �v��ID
        , lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
        , lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
        , lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
    END IF;
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END wait_for_request;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_order_source             IN  VARCHAR2, -- �󒍃\�[�X
    iv_delivery_base_code       IN  VARCHAR2, -- �[�i���_�R�[�h
    iv_output_type              IN  VARCHAR2, -- �o�͋敪
    iv_output_quantity_type     IN  VARCHAR2, -- �o�͐��ʋ敪
    iv_request_type             IN  VARCHAR2, -- �Ĕ��s�敪
    iv_edi_received_date_from   IN  VARCHAR2, -- �G���[���X�g�pEDI��M��(FROM)
    iv_edi_received_date_to     IN  VARCHAR2, -- �G���[���X�g�pEDI��M��(TO)
    ov_errbuf                   OUT VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                  OUT VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                   OUT VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- ��������(A-1)
    -- ===============================
    init(
        iv_order_source             -- �󒍃\�[�X
      , iv_delivery_base_code       -- �[�i���_�R�[�h
      , iv_output_type              -- �o�͋敪
      , iv_output_quantity_type     -- �o�͐��ʋ敪
      , iv_request_type             -- �Ĕ��s�敪
      , iv_edi_received_date_from   -- �G���[���X�g�pEDI��M��(FROM)
      , iv_edi_received_date_to     -- �G���[���X�g�pEDI��M��(TO)
      , lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
      , lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
      , lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �󒍈ꗗ���X�g���s����(A-2)
    -- ===============================
    exe_xxcos009a01r(
        iv_order_source             -- �󒍃\�[�X
      , iv_delivery_base_code       -- �[�i���_�R�[�h
      , iv_output_type              -- �o�͋敪
      , iv_output_quantity_type     -- �o�͐��ʋ敪
      , lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
      , lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
      , lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- ===============================
    -- �󒍃G���[���X�g�i�󒍁j���s����(A-3)
    -- ===============================
    exe_xxcos010a05r_1(
        iv_delivery_base_code       -- �[�i���_�R�[�h
      , iv_request_type             -- �Ĕ��s�敪
      , iv_edi_received_date_from   -- �G���[���X�g�pEDI��M��(FROM)
      , iv_edi_received_date_to     -- �G���[���X�g�pEDI��M��(TO)
      , lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
      , lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
      , lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- ===============================
    -- �󒍃G���[���X�g�i�[�i�m��j���s����(A-4)
    -- ===============================
    exe_xxcos010a05r_2(
        iv_delivery_base_code       -- �[�i���_�R�[�h
      , iv_request_type             -- �Ĕ��s�敪
      , iv_edi_received_date_from   -- �G���[���X�g�pEDI��M��(FROM)
      , iv_edi_received_date_to     -- �G���[���X�g�pEDI��M��(TO)
      , lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
      , lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
      , lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- ===============================
    -- �R���J�����g�I���ҋ@����(A-5)
    -- ===============================
    wait_for_request(
        lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
      , lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
      , lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
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
    errbuf                      OUT VARCHAR2, -- �G���[���b�Z�[�W #�Œ�#
    retcode                     OUT VARCHAR2, -- �G���[�R�[�h     #�Œ�#
    iv_order_source             IN  VARCHAR2, -- �󒍃\�[�X
    iv_delivery_base_code       IN  VARCHAR2, -- �[�i���_�R�[�h
    iv_output_type              IN  VARCHAR2, -- �o�͋敪
    iv_output_quantity_type     IN  VARCHAR2, -- �o�͐��ʋ敪
    iv_request_type             IN  VARCHAR2, -- �Ĕ��s�敪
    iv_edi_received_date_from   IN  VARCHAR2, -- �G���[���X�g�pEDI��M��(FROM)
    iv_edi_received_date_to     IN  VARCHAR2  -- �G���[���X�g�pEDI��M��(TO)
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
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
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
        iv_order_source             -- �󒍃\�[�X
      , iv_delivery_base_code       -- �[�i���_�R�[�h
      , iv_output_type              -- �o�͋敪
      , iv_output_quantity_type     -- �o�͐��ʋ敪
      , iv_request_type             -- �Ĕ��s�敪
      , iv_edi_received_date_from   -- �G���[���X�g�pEDI��M��(FROM)
      , iv_edi_received_date_to     -- �G���[���X�g�pEDI��M��(TO)
      , lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
      , lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
      , lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF ( lv_retcode = cv_status_error ) THEN
      -- �o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      -- �o�͋�s
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
      -- ���O
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf
      );
      -- ���O��s
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => ''
      );
      --  �I���X�e�[�^�X
      gv_retcode := lv_retcode;
      --
    END IF;
--
    -- �I�����b�Z�[�W
    IF ( gv_retcode = cv_status_normal ) THEN
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_normal_msg
                     );
    ELSIF( gv_retcode = cv_status_warn ) THEN
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_warn_msg
                     );
    ELSIF( gv_retcode = cv_status_error ) THEN
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_xxcos_14562
                     );
    END IF;
    --
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --�X�e�[�^�X�Z�b�g
    retcode := gv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
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
END XXCOS009A10C;
/
