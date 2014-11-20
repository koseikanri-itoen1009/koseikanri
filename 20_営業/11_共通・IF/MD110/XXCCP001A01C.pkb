CREATE OR REPLACE PACKAGE BODY APPS.XXCCP001A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCCP001A01C(spec)
 * Description      : �Ɩ����t�Ɖ�X�V
 * MD.050           : MD050_CCP_001_A01_�Ɩ����t�X�V�Ɖ�
 * Version          : 1.02
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  con_get_process_date   �Ɩ����t�Ɖ��(A-2)
 *  update_process_date    �Ɩ����t�X�V����(A-3)
 *  insert_process_date    �Ɩ����t�o�^����(A-4)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��(�㏈��)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/10    1.00  �n�Ӓ���         �V�K�쐬
 *  2009/05/01    1.01  Masayuki.Sano    ��Q�ԍ�T1_0910�Ή�(�X�L�[�}���t��)
 *  2009/06/01    1.02  Masayuki.Sano    ��Q�ԍ�T1_1276�Ή�(�R���J�����g����O�o�͑Ή�)
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn            CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_warn;   --�x��:1
  cv_status_error           CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_error;  --�ُ�:2
  cv_appl_short_name        CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�h�I���F���ʁEIF�̈�
  --WHO�J����
  cn_created_by             CONSTANT NUMBER        := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE          := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER        := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE          := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER        := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER        := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER        := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER        := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE          := SYSDATE;                    --PROGRAM_UPDATE_DATE
--
  cv_msg_part               CONSTANT VARCHAR2(3)   := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3)   := '.';
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
  parameter_error_expt   EXCEPTION;
  get_process_error_expt EXCEPTION;
  get_profile_error      EXCEPTION;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCCP001A01C'; -- �p�b�P�[�W��
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     ov_errbuf       OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode      OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg       OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    ,iv_handle_area  IN  VARCHAR2     --   �����敪
    ,iv_process_date IN  VARCHAR2)    --   �Ɩ����t
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name      CONSTANT VARCHAR2(100) := 'init';             -- �v���O������
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
    cv_profile_name1  CONSTANT VARCHAR2(100) := 'XXCCP1_HANDLE_AREA';   --�����敪
    cv_profile_name2  CONSTANT VARCHAR2(100) := 'XXCCP1_PROCESS_DATE';  --�Ɩ����t
    cv_message_name1  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-10015';     --���̓p�����[�^�G���[���b�Z�[�W
    cv_message_name2  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-10016';     --�v���t�@�C���擾�G���[���b�Z�[�W
    cv_token_name1    CONSTANT VARCHAR2(100) := 'ITEM';                 --�g�[�N����
--
    -- *** ���[�J���ϐ� ***
    lv_profile        VARCHAR2(100);  --���̓p�����[�^�o�͗p�ϐ�
    lv_profile1       VARCHAR2(100);  --���̓p�����[�^�o�͗p�ϐ�
    lv_profile2       VARCHAR2(100);  --���̓p�����[�^�o�͗p�ϐ�
    ld_process_date   VARCHAR2(100);  --���̓p�����[�^�o�͗p�ϐ�
--
  BEGIN
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
-- 2009/06/01 Ver1.02 Add Start
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
-- 2009/06/01 Ver1.02 Add End
    lv_profile1 := FND_PROFILE.VALUE(cv_profile_name1);
    IF (lv_profile1 IS NULL) THEN
      RAISE get_profile_error;
    END IF;
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_profile1||cv_msg_part||iv_handle_area
    );
-- 2009/06/01 Ver1.02 Add Start
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_profile1||cv_msg_part||iv_handle_area
    );
-- 2009/06/01 Ver1.02 Add End
    lv_profile2 := FND_PROFILE.VALUE(cv_profile_name2);
    IF (lv_profile2 IS NULL) THEN
      RAISE get_profile_error;
    END IF;
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_profile2||cv_msg_part||iv_process_date
    );
-- 2009/06/01 Ver1.02 Add Start
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_profile2||cv_msg_part||iv_process_date
    );
-- 2009/06/01 Ver1.02 Add End
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
-- 2009/06/01 Ver1.02 Add Start
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
-- 2009/06/01 Ver1.02 Add End
    IF (iv_handle_area NOT IN ('1','2'))
      OR (iv_handle_area IS NULL) THEN
        lv_profile := lv_profile1;
        RAISE parameter_error_expt;
    ELSIF (iv_handle_area = 1)
      AND (iv_process_date IS NOT NULL) THEN
        BEGIN
        ld_process_date := TO_DATE(iv_process_date,'YYYYMMDD');
      --
        EXCEPTION
          WHEN OTHERS THEN
            lv_profile := lv_profile2;
            RAISE parameter_error_expt;
        END;
    END IF;
    ov_retcode := cv_status_normal;
  --
  EXCEPTION
    WHEN parameter_error_expt THEN
      --�u���̓p�����[�^�G���[���b�Z�[�W�v�擾
      -- ITEM�̒l���s���ł��B
      lv_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_message_name1
                      ,iv_token_name1  => cv_token_name1
                      ,iv_token_value1 => lv_profile
                    );
      lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
    WHEN get_profile_error THEN
      --�u�v���t�@�C���擾�G���[���b�Z�[�W�v�擾
      --�v���t�@�C���̎擾�Ɏ��s���܂����B
      lv_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_message_name2
                    );
      lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
--
--#################################  �Œ��O������ START   ####################################
--
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
   * Procedure Name   : con_get_process_date
   * Description      : �Ɩ����t�Q�Ə���(A-2)
   ***********************************************************************************/
  PROCEDURE con_get_process_date(
    iv_handle_area  IN  VARCHAR2      --   �����敪
   ,ov_errbuf       OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode      OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg       OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
   ,ov_process_date OUT VARCHAR2)     --   �Ɩ����t
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_process_date'; -- �v���O������
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
    cv_message_name    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-10013'; --�Q�ƈُ�G���[���b�Z�[�W
    cv_token_name      VARCHAR2(100) := 'RTNCD';                     --�g�[�N����
    cn_process_date_id NUMBER        := 1;                           --�Ɩ����t�e�[�u����L�[
--
    -- *** ���[�J���ϐ� ***
    lv_output DATE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    SELECT process_date
    INTO   lv_output
    FROM   xxccp_process_dates
    WHERE  process_date_id = cn_process_date_id
    ;
    ov_process_date :=lv_output;
--
  EXCEPTION
--
    WHEN NO_DATA_FOUND THEN
      IF (iv_handle_area = '2') THEN
      --�Q�ƈُ�G���[���b�Z�[�W
      --�Ɩ����t�̎擾�Ɏ��s���܂����B�i���^�[���R�[�h�F�u  �v�j
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name
                        ,iv_name         => cv_message_name
                        ,iv_token_name1  => cv_token_name
                        ,iv_token_value1 => SQLCODE
                      );
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
        ov_retcode := cv_status_error;
      ELSIF (iv_handle_area = '1') THEN
        ov_process_date := NULL;
      END IF;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END con_get_process_date;
--
  /**********************************************************************************
   * Procedure Name   : update_process_date
   * Description      : �Ɩ����t�X�V����(A-3)
   ***********************************************************************************/
  PROCEDURE update_process_date(
    iv_process_date IN  VARCHAR2      --   ���̓p�����[�^�F�Ɩ����t
   ,ov_errbuf       OUT VARCHAR2      --   �G���[�E���b�Z�[�W                  --# �Œ� #
   ,ov_retcode      OUT VARCHAR2      --   ���^�[���E�R�[�h                    --# �Œ� #
   ,ov_errmsg       OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_process_date'; -- �v���O������
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
    -- *** ���[�J���萔 ***
    cv_profile_name   VARCHAR2(100) := 'XXCCP1_PROCESS_DATE';  --�Ɩ����t
    cv_message_name   VARCHAR2(100) := 'APP-XXCCP1-10012';     --�X�V�ُ�G���[���b�Z�[�W
    cv_message_name2  VARCHAR2(100) := 'APP-XXCCP1-30001';     --�X�V����I�����b�Z�[�W
    cv_token_name1    VARCHAR2(100) := 'DATE';                 --�g�[�N����
    cv_token_name2    VARCHAR2(100) := 'RTNCD';                --�g�[�N���l
--
    -- *** ���[�J���ϐ� ***
    ld_process_date DATE;  --�Ɩ����t�i�[�p�ϐ�
    lv_message      VARCHAR2(1000);
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    IF (iv_process_date IS NULL) THEN
      ld_process_date := TRUNC(SYSDATE,'DD');
    ELSIF (iv_process_date IS NOT NULL) THEN
      ld_process_date := TO_DATE(iv_process_date,'YYYYMMDD');
    END IF;
    --
    UPDATE xxccp.xxccp_process_dates
    SET
      process_date           = ld_process_date
     ,last_updated_by        = cn_last_updated_by
     ,last_update_date       = cd_last_update_date
     ,last_update_login      = cn_last_update_login
     ,request_id             = cn_request_id
     ,program_application_id = cn_program_application_id
     ,program_id             = cn_program_id
     ,program_update_date    = cd_program_update_date
    WHERE
      process_date_id = 1;
    --
    lv_message := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name
                       ,iv_name         => cv_message_name2
                       ,iv_token_name1  => cv_token_name1
                       ,iv_token_value1 => TO_CHAR(ld_process_date,'YYYY/MM/DD')
                    );
    --
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_message
    );
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      --�X�V�ُ�G���[���b�Z�[�W
      --�Ɩ����t�̍X�V�Ɏ��s���܂����B�i���^�[���R�[�h�F�u RTNCD �v�j
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name
                       ,iv_name         => cv_message_name
                       ,iv_token_name1  => cv_token_name2
                       ,iv_token_value1 => SQLCODE
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END update_process_date;
--
  /**********************************************************************************
   * Procedure Name   : insert_process_date
   * Description      : �Ɩ����t�o�^����(A-4)
   ***********************************************************************************/
  PROCEDURE insert_process_date(
     iv_process_date IN  VARCHAR2      --   �Ɩ����t
    ,ov_errbuf       OUT VARCHAR2      --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ,ov_retcode      OUT VARCHAR2      --   ���^�[���E�R�[�h                    --# �Œ� #
    ,ov_errmsg       OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_process_date'; -- �v���O������
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
    -- *** ���[�J���萔 ***
    cv_profile_name    VARCHAR2(100) := 'XXCCP1_PROCESS_DATE';  --�Ɩ����t
    cv_message_name    VARCHAR2(100) := 'APP-XXCCP1-10017';     --�o�^�ُ�G���[���b�Z�[�W
    cv_message_name2   VARCHAR2(100) := 'APP-XXCCP1-30002';     --�o�^����I�����b�Z�[�W
    cv_token_name1     VARCHAR2(100) := 'DATE';                 --�g�[�N����
    cv_token_name2     VARCHAR2(100) := 'RTNCD';                --�g�[�N����
    cn_process_date_id NUMBER        := 1;                      --�Ɩ����t�e�[�u����L�[
--
    -- *** ���[�J���ϐ� ***
    ld_process_date DATE;           --�Ɩ����t�i�[�p�ϐ�
    lv_message      VARCHAR2(1000); --���b�Z�[�W�o�͗p�ϐ�
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    IF (iv_process_date IS NULL) THEN
      ld_process_date := TRUNC(SYSDATE,'DD');
    ELSIF (iv_process_date IS NOT NULL) THEN
      ld_process_date := TO_DATE(iv_process_date,'YYYYMMDD');
    END IF;
    --
    INSERT INTO xxccp.xxccp_process_dates(
       process_date_id
      ,process_date
      ,created_by
      ,creation_date
      ,last_updated_by
      ,last_update_date
      ,last_update_login
      ,request_id
      ,program_application_id
      ,program_id
      ,program_update_date
    )VALUES(
       cn_process_date_id
      ,ld_process_date
      ,cn_created_by
      ,cd_creation_date
      ,cn_last_updated_by
      ,cd_last_update_date
      ,cn_last_update_login
      ,cn_request_id
      ,cn_program_application_id
      ,cn_program_id
      ,cd_program_update_date
    );
    --
    lv_message := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name
                       ,iv_name         => cv_message_name2
                       ,iv_token_name1  => cv_token_name1
                       ,iv_token_value1 => TO_CHAR(ld_process_date,'YYYY/MM/DD')
                    );
    --
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_message
    );
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      --�o�^�ُ�G���[���b�Z�[�W
      --�Ɩ����t�̓o�^�Ɏ��s���܂����B�i���^�[���R�[�h�F�u RTNCD �v�j
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name
                       ,iv_name         => cv_message_name
                       ,iv_token_name1  => cv_token_name2
                       ,iv_token_value1 => SQLCODE
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END insert_process_date;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
     iv_handle_area  IN  VARCHAR2
    ,iv_process_date IN  VARCHAR2
    ,ov_errbuf       OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode      OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg       OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'submain';              --�v���O������
    cv_profile_name2  CONSTANT VARCHAR2(100) := 'XXCCP1_HANDLE_AREA';   --�����敪
    cv_message_name1  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-10015';     --���̓p�����[�^�G���[���b�Z�[�W
    cv_token_name1    CONSTANT VARCHAR2(100) := 'ITEM';                 --�g�[�N����
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf        VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode       VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg        VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_handle_area   VARCHAR2(100);
    lv_process_date  VARCHAR2(100);
    lv_process_date2 DATE;
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
    lv_handle_area  := iv_handle_area;
    lv_process_date := iv_process_date;
    --(�������Ăяo��)
    init(lv_errbuf         --   �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode        --   ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg         --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        ,lv_handle_area
        ,lv_process_date);
    IF (lv_retcode = cv_status_normal) THEN
      con_get_process_date(
             lv_handle_area
            ,lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
            ,lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
            ,lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            ,lv_process_date2
      );
      IF (iv_handle_area = '2') THEN
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => TO_CHAR(lv_process_date2,'YYYY/MM/DD')
        );
      ELSIF (iv_handle_area = '1') THEN
        IF (lv_process_date2 IS NOT NULL) THEN
        update_process_date(
              iv_process_date
             ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
             ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
             ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        ELSE
        insert_process_date(
              iv_process_date
             ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
             ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
             ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        END IF;
      END IF;
    END IF;
--
    ov_errbuf  := lv_errbuf;
    ov_retcode := lv_retcode;
    ov_errmsg  := lv_errmsg;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
--
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
    errbuf          OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode         OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_handle_area  IN  VARCHAR2,      --   �����敪
    iv_process_date IN  VARCHAR2       --   �Ɩ����t
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
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
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
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
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
       iv_handle_area
      ,iv_process_date
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    gn_target_cnt := gn_target_cnt + 1;
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    ELSE
      gn_normal_cnt := gn_normal_cnt + 1;
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
    --�I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
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
END XXCCP001A01C;
/
