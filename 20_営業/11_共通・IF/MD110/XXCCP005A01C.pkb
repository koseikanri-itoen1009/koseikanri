CREATE OR REPLACE PACKAGE BODY APPS.XXCCP005A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCCP005A01C(body)
 * Description      : ���V�X�e�������IF�t�@�C���ɂ�����A�w�b�_�E�t�b�^�폜���܂��B
 * MD.050           : MD050_CCP_005_A01_IF�t�@�C���w�b�_�E�t�b�^�폜����
 * Version          : 1.4
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  file_open              �t�@�C���I�[�v������(A-2,A-5)
 *  file_close             �t�@�C���N���[�Y����(A-4,A-7)
 *  file_read              �t�@�C���ǂݍ��ݏ���(A-3)
 *  file_write             �t�@�C���������ݏ���(A-6)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-11-21    1.0   Yutaka.Kuboshima �V�K�쐬
 *  2008-12-01    1.1   Yutaka.Kuboshima �X�L�b�v�����o�͏�����ǉ�
 *  2009-02-25    1.2   T.Matsumoto      �t�@�C���ǂݍ��ݎ��̕�����o�b�t�@���s���b��Ή�(2047 �� 30000)
 *  2009-02-26    1.3   T.Matsumoto      �o�̓��O�s���Ή�
 *  2009-05-01    1.4   Masayuki.Sano    ��Q�ԍ�T1_0910�Ή�(�X�L�[�}���t��)
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --�ُ�:2
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
  init_err_expt             EXCEPTION;     -- ���������G���[
  fopen_err_expt            EXCEPTION;     -- �t�@�C���I�[�v���G���[
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name          CONSTANT VARCHAR2(100) := 'XXCCP005A01C';      -- �p�b�P�[�W��
--
  gv_cnst_msg_kbn      CONSTANT VARCHAR2(5)   := 'XXCCP';             -- ���b�Z�[�W�敪
--
  --�G���[���b�Z�[�W
  gv_cnst_msg_if_proh  CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-10101';  -- �v���t�@�C���擾�G���[(�w�b�_)
  gv_cnst_msg_if_prod  CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-10102';  -- �v���t�@�C���擾�G���[(�f�[�^)
  gv_cnst_msg_if_prof  CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-10103';  -- �v���t�@�C���擾�G���[(�t�b�^)
  gv_cnst_msg_if_para1 CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-10104';  -- ���͍���NULL�G���[(�t�@�C����)
  gv_cnst_msg_if_para2 CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-10105';  -- ���͍���NULL�G���[(����V�X�e����)
  gv_cnst_msg_if_para3 CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-10106';  -- ���͍���NULL�G���[(�t�@�C���f�B���N�g��)
  gv_cnst_msg_if_para4 CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-10107';  -- ���͍��ڕs���G���[(����V�X�e����)
  gv_cnst_msg_if_para5 CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-10108';  -- ���͍��ڕs���G���[(�t�@�C����)
  gv_cnst_msg_if_para6 CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-10109';  -- ���͍��ڕs���G���[(�t�@�C���f�B���N�g��)
  gv_cnst_msg_if_acc   CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-10110';  -- �t�@�C���A�N�Z�X�����G���[
  --�R���J�����g���b�Z�[�W
  gv_cnst_msg_if_ifna  CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-05101';  -- �����Ώۃt�@�C�������b�Z�[�W
  gv_cnst_msg_if_fnam  CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-05102';  -- �t�@�C�������b�Z�[�W
  gv_cnst_msg_if_osys  CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-05103';  -- ����V�X�e�������b�Z�[�W
  gv_cnst_msg_if_fdir  CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-05104';  -- �t�@�C���f�B���N�g�����b�Z�[�W
  --�g�[�N��
  gv_cnst_tkn_fname    CONSTANT VARCHAR2(15)  := 'FILE_NAME';         -- �g�[�N��(�t�@�C����)
  gv_cnst_tkn_osystem  CONSTANT VARCHAR2(15)  := 'OTHER_SYSTEM';      -- �g�[�N��(����V�X�e����)
  gv_cnst_tkn_fdir     CONSTANT VARCHAR2(15)  := 'FILE_DIR';          -- �g�[�N��(�t�@�C���f�B���N�g��)
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
-- 2009/02/25 v1.2 �t�@�C���ǂݍ��ݎ��̕�����o�b�t�@���s���b��Ή� T.Matsumoto MOD.START
--  TYPE g_file_data_ttype IS TABLE OF VARCHAR2(2047) INDEX BY BINARY_INTEGER;  -- �t�@�C���f�[�^���i�[����z��
  TYPE g_file_data_ttype IS TABLE OF VARCHAR2(30000) INDEX BY BINARY_INTEGER;  -- �t�@�C���f�[�^���i�[����z��
-- 2009/02/25 v1.2 �t�@�C���ǂݍ��ݎ��̕�����o�b�t�@���s���b��Ή� T.Matsumoto MOD.END
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_if_header   VARCHAR2(10);  -- IF���R�[�h�敪_�w�b�_
  gv_if_data     VARCHAR2(10);  -- IF���R�[�h�敪_�f�[�^
  gv_if_footer   VARCHAR2(10);  -- IF���R�[�h�敪_�t�b�^
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_file_name    IN  VARCHAR2,     --   �t�@�C����
    iv_other_system IN  VARCHAR2,     --   ����V�X�e����
    iv_file_dir     IN  VARCHAR2,     --   �t�@�C���f�B���N�g��
    ov_errbuf       OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    cv_if_header    CONSTANT VARCHAR2(50) := 'XXCCP1_IF_HEADER';  -- �v���t�@�C����(IF���R�[�h�敪�w�b�_)
    cv_if_data      CONSTANT VARCHAR2(50) := 'XXCCP1_IF_DATA';    -- �v���t�@�C����(IF���R�[�h�敪�f�[�^)
    cv_if_footer    CONSTANT VARCHAR2(50) := 'XXCCP1_IF_FOOTER';  -- �v���t�@�C����(IF���R�[�h�敪�t�b�^)
    cv_para_osystem CONSTANT VARCHAR2(5)  := 'EDI';               -- ����V�X�e����
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
    --IF���R�[�h�敪_�w�b�_�擾
    gv_if_header := FND_PROFILE.VALUE(cv_if_header);
    --IF���R�[�h�敪_�w�b�_�`�F�b�N
    IF (gv_if_header IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(gv_cnst_msg_kbn,
                                            gv_cnst_msg_if_proh);
      lv_errbuf := lv_errmsg;
      RAISE init_err_expt;
    END IF;
    --IF���R�[�h�敪_�f�[�^�擾
    gv_if_data := FND_PROFILE.VALUE(cv_if_data);
    --IF���R�[�h�敪_�f�[�^�`�F�b�N
    IF (gv_if_data IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(gv_cnst_msg_kbn,
                                            gv_cnst_msg_if_prod);
      lv_errbuf := lv_errmsg;
      RAISE init_err_expt;
    END IF;
    --IF���R�[�h�敪_�t�b�^�擾
    gv_if_footer := FND_PROFILE.VALUE(cv_if_footer);
    --IF���R�[�h�敪_�t�b�^�`�F�b�N
    IF (gv_if_footer IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(gv_cnst_msg_kbn,
                                            gv_cnst_msg_if_prof);
      lv_errbuf := lv_errmsg;
      RAISE init_err_expt;
    END IF;
    --�t�@�C����NULL�`�F�b�N
    IF (iv_file_name IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(gv_cnst_msg_kbn,
                                            gv_cnst_msg_if_para1);
      lv_errbuf := lv_errmsg;
      RAISE init_err_expt;
    END IF;
    --����V�X�e����NULL�`�F�b�N
    IF (iv_other_system IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(gv_cnst_msg_kbn,
                                            gv_cnst_msg_if_para2);
      lv_errbuf := lv_errmsg;
      RAISE init_err_expt;
    END IF;
    --�t�@�C���f�B���N�g��NULL�`�F�b�N
    IF (iv_file_dir IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(gv_cnst_msg_kbn,
                                            gv_cnst_msg_if_para3);
      lv_errbuf := lv_errmsg;
      RAISE init_err_expt;
    END IF;
    --����V�X�e�����s���`�F�b�N
    IF (iv_other_system <> cv_para_osystem) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(gv_cnst_msg_kbn,
                                            gv_cnst_msg_if_para4);
      lv_errbuf := lv_errmsg;
      RAISE init_err_expt;
    END IF;
--
  EXCEPTION
    WHEN init_err_expt THEN                           --*** ���������G���[ ***
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
   * Procedure Name   : file_open
   * Description      : �t�@�C���I�[�v������(A-2,A-5)
   ***********************************************************************************/
  PROCEDURE file_open(
    iv_file_name    IN  VARCHAR2,            --   �t�@�C����
    iv_file_dir     IN  VARCHAR2,            --   �t�@�C���f�B���N�g��
    iv_file_mode    IN  VARCHAR2,            --   �t�@�C�����[�h(R:�ǂݎ�� W:��������)
    of_file_handler OUT UTL_FILE.FILE_TYPE,  --   �t�@�C���n���h��
    ov_errbuf       OUT VARCHAR2,            --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT VARCHAR2,            --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT VARCHAR2)            --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'file_open'; -- �v���O������
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
-- 2009/02/25 v1.2 �t�@�C���ǂݍ��ݎ��̕�����o�b�t�@���s���b��Ή� T.Matsumoto MOD.START 
--    cn_record_byte CONSTANT NUMBER := 2047;  --�t�@�C���ǂݍ��ݕ�����
    cn_record_byte CONSTANT NUMBER := 30000;  --�t�@�C���ǂݍ��ݕ�����
-- 2009/02/25 v1.2 �t�@�C���ǂݍ��ݎ��̕�����o�b�t�@���s���b��Ή� T.Matsumoto MOD.END
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
    BEGIN
      --�t�@�C���I�[�v��
      of_file_handler := UTL_FILE.FOPEN(iv_file_dir,
                                        iv_file_name,
                                        iv_file_mode,
                                        cn_record_byte);
    EXCEPTION
      --�t�@�C�����G���[
      WHEN UTL_FILE.INVALID_FILENAME THEN
        lv_errmsg := xxccp_common_pkg.get_msg(gv_cnst_msg_kbn,
                                              gv_cnst_msg_if_para5);
        lv_errbuf := lv_errmsg;
        RAISE fopen_err_expt;
      --�t�@�C���p�X�G���[
      WHEN UTL_FILE.INVALID_PATH THEN
        lv_errmsg := xxccp_common_pkg.get_msg(gv_cnst_msg_kbn,
                                              gv_cnst_msg_if_para6);
        lv_errbuf := lv_errmsg;
        RAISE fopen_err_expt;
      --�A�N�Z�X�����G���[
      WHEN UTL_FILE.ACCESS_DENIED THEN
        lv_errmsg := xxccp_common_pkg.get_msg(gv_cnst_msg_kbn,
                                              gv_cnst_msg_if_acc);
        lv_errbuf := lv_errmsg;
        RAISE fopen_err_expt;
      WHEN OTHERS THEN
        RAISE;
    END;
--
  EXCEPTION
    WHEN fopen_err_expt THEN                           --*** �t�@�C���I�[�v���G���[ ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END file_open;
--
  /**********************************************************************************
   * Procedure Name   : file_close
   * Description      : �t�@�C���N���[�Y����(A-4,A-7)
   ***********************************************************************************/
  PROCEDURE file_close(
    iof_file_handler IN OUT UTL_FILE.FILE_TYPE, --   �t�@�C���n���h��
-- 2009/02/26 v1.3 �o�̓��O�s���Ή� T.Matsumoto MOD.START
--    ov_errbuf           OUT VARCHAR2,           --   �G���[�E���b�Z�[�W           --# �Œ� #
--    ov_retcode          OUT VARCHAR2,           --   ���^�[���E�R�[�h             --# �Œ� #
--    ov_errmsg           OUT VARCHAR2)           --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    ov_errbuf        IN OUT VARCHAR2,           --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       IN OUT VARCHAR2,           --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        IN OUT VARCHAR2)           --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
-- 2009/02/26 v1.3 �o�̓��O�s���Ή� T.Matsumoto MOD.END
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'file_close'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    --��
    iof_file_handler_test UTL_FILE.FILE_TYPE ;
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
-- 2009/02/26 v1.3 �o�̓��O�s���Ή� T.Matsumoto DEL.START
--    ov_retcode := cv_status_normal;
-- 2009/02/26 v1.3 �o�̓��O�s���Ή� T.Matsumoto DEL.END
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --�t�@�C���N���[�Y
    UTL_FILE.FCLOSE(iof_file_handler);
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
-- 2009/02/26 v1.3 �o�̓��O�s���Ή� T.Matsumoto MOD.START
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_errbuf  := SUBSTRB(ov_errbuf || cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
-- 2009/02/26 v1.3 �o�̓��O�s���Ή� T.Matsumoto MOD.END
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
-- 2009/02/26 v1.3 �o�̓��O�s���Ή� T.Matsumoto MOD.START
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_errbuf  := ov_errbuf || cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
-- 2009/02/26 v1.3 �o�̓��O�s���Ή� T.Matsumoto MOD.END
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
-- 2009/02/26 v1.3 �o�̓��O�s���Ή� T.Matsumoto MOD.START
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_errbuf  := ov_errbuf || cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
-- 2009/02/26 v1.3 �o�̓��O�s���Ή� T.Matsumoto MOD.END
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END file_close;
--
  /**********************************************************************************
   * Procedure Name   : file_read
   * Description      : �t�@�C���ǂݍ��ݏ���(A-3)
   ***********************************************************************************/
  PROCEDURE file_read(
    if_file_handler  IN  UTL_FILE.FILE_TYPE, --   �t�@�C���n���h��
    o_file_data_tab  OUT g_file_data_ttype,  --   �t�@�C���f�[�^
    ov_errbuf        OUT VARCHAR2,           --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode       OUT VARCHAR2,           --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg        OUT VARCHAR2)           --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'file_read'; -- �v���O������
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
-- 2009/02/25 v1.2 �t�@�C���ǂݍ��ݎ��̕�����o�b�t�@���s���b��Ή� T.Matsumoto MOD.START
--    lv_data  VARCHAR2(2047);  --�t�@�C���f�[�^
    lv_data  VARCHAR2(30000);  --�t�@�C���f�[�^
-- 2009/02/25 v1.2 �t�@�C���ǂݍ��ݎ��̕�����o�b�t�@���s���b��Ή� T.Matsumoto MOD.END
    ln_cnt   NUMBER;          --�z��̓Y��
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
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
--
    --������
    lv_data := NULL;
    ln_cnt  := 1;
    BEGIN
    --���[�v����
      <<file_read>>
      LOOP
        UTL_FILE.GET_LINE(if_file_handler,lv_data);
        IF (SUBSTR(lv_data,1,1) = gv_if_data) THEN
          --�z��Ɋi�[
          o_file_data_tab(ln_cnt) := lv_data;
          ln_cnt := ln_cnt + 1;
        END IF;
        --�Ώی����J�E���g
        gn_target_cnt := gn_target_cnt + 1;
      END LOOP file_read;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
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
  END file_read;
--
  /**********************************************************************************
   * Procedure Name   : file_write
   * Description      : �t�@�C���������ݏ���(A-6)
   ***********************************************************************************/
  PROCEDURE file_write(
    if_file_handler IN  UTL_FILE.FILE_TYPE,  --   �t�@�C���n���h��
    i_file_data_tab IN  g_file_data_ttype,   --   �t�@�C���f�[�^
    ov_errbuf       OUT VARCHAR2,            --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode      OUT VARCHAR2,            --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg       OUT VARCHAR2)            --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'file_write'; -- �v���O������
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
    ln_cnt   NUMBER;          --�z��̓Y��
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
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
--
    --������
    ln_cnt  := 1;
    BEGIN
      --���[�v����
      <<file_write>>
      LOOP
        --�t�@�C����������
        UTL_FILE.PUT_LINE(if_file_handler,SUBSTR(i_file_data_tab(ln_cnt),2));
        --�z��Y���J�E���g
        ln_cnt        := ln_cnt + 1;
        --���������J�E���g
        gn_normal_cnt := gn_normal_cnt + 1;
      END LOOP file_write;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
    --�X�L�b�v�����J�E���g
    gn_warn_cnt := gn_target_cnt - gn_normal_cnt;
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
  END file_write;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_file_name    IN  VARCHAR2,     --   �t�@�C����
    iv_other_system IN  VARCHAR2,     --   ����V�X�e����
    iv_file_dir     IN  VARCHAR2,     --   �t�@�C���f�B���N�g��
    ov_errbuf       OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    cv_file_mode_r    CONSTANT VARCHAR2(1) := 'R';   -- �t�@�C�����[�h(�ǂݍ���)
    cv_file_mode_w    CONSTANT VARCHAR2(1) := 'W';   -- �t�@�C�����[�h(��������)
--
    -- *** ���[�J���ϐ� ***
    lf_file_handler   UTL_FILE.FILE_TYPE;            -- �t�@�C���n���h��
    l_file_data_tab   g_file_data_ttype;             -- �t�@�C���f�[�^���i�[����z��
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
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- <��������>
    -- ===============================
    init(
      iv_file_name,      -- �t�@�C����
      iv_other_system,   -- ����V�X�e����
      iv_file_dir,       -- �t�@�C���f�B���N�g��
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- <�t�@�C���I�[�v������>
    -- ===============================
    file_open(
      iv_file_name,      -- �t�@�C����
      iv_file_dir,       -- �t�@�C���f�B���N�g��
      cv_file_mode_r,    -- �t�@�C�����[�h
      lf_file_handler,   -- �t�@�C���n���h��
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- <�t�@�C���ǂݍ��ݏ���>
    -- ===============================
    file_read(
      lf_file_handler,   -- �t�@�C���n���h��
      l_file_data_tab,   -- �t�@�C���f�[�^
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = cv_status_error) THEN
      --�t�@�C���N���[�Y����
      IF (UTL_FILE.IS_OPEN(lf_file_handler)) THEN
        -- ===============================
        -- <�t�@�C���N���[�Y����>
        -- ===============================
        file_close(
          lf_file_handler,   -- �t�@�C���n���h��
          lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      END IF;
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- <�t�@�C���N���[�Y����>
    -- ===============================
    file_close(
      lf_file_handler,   -- �t�@�C���n���h��
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- <�t�@�C���I�[�v������>
    -- ===============================
    file_open(
      iv_file_name,      -- �t�@�C����
      iv_file_dir,       -- �t�@�C���f�B���N�g��
      cv_file_mode_w,    -- �t�@�C�����[�h
      lf_file_handler,   -- �t�@�C���n���h��
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- <�t�@�C���������ݏ���>
    -- ===============================
    file_write(
      lf_file_handler,   -- �t�@�C���n���h��
      l_file_data_tab,   -- �t�@�C���f�[�^
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = cv_status_error) THEN
      --�t�@�C���N���[�Y����
      IF (UTL_FILE.IS_OPEN(lf_file_handler)) THEN
        -- ===============================
        -- <�t�@�C���N���[�Y����>
        -- ===============================
        file_close(
          lf_file_handler,   -- �t�@�C���n���h��
          lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      END IF;
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- <�t�@�C���N���[�Y����>
    -- ===============================
    file_close(
      lf_file_handler,   -- �t�@�C���n���h��
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
--
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
    errbuf          OUT    VARCHAR2,         --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode         OUT    VARCHAR2,         --   ���^�[���E�R�[�h    --# �Œ� #
    iv_file_name    IN     VARCHAR2,         --   �t�@�C����
    iv_other_system IN     VARCHAR2,         --   ����V�X�e����
    iv_file_dir     IN     VARCHAR2          --   �t�@�C���f�B���N�g��
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
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    cv_if_error_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-10008'; -- �G���[�I�����b�Z�[�W
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
       iv_file_name     -- �t�@�C����
      ,iv_other_system  -- ����V�X�e����
      ,iv_file_dir      -- �t�@�C���f�B���N�g��
      ,lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --���̓p�����[�^�o��
    --�t�@�C����
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => xxccp_common_pkg.get_msg(gv_cnst_msg_kbn,
                                          gv_cnst_msg_if_fnam,
                                          gv_cnst_tkn_fname,
                                          iv_file_name)
    );
    --����V�X�e����
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => xxccp_common_pkg.get_msg(gv_cnst_msg_kbn,
                                          gv_cnst_msg_if_osys,
                                          gv_cnst_tkn_osystem,
                                          iv_other_system)
    );
    --�t�@�C���f�B���N�g��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => xxccp_common_pkg.get_msg(gv_cnst_msg_kbn,
                                          gv_cnst_msg_if_fdir,
                                          gv_cnst_tkn_fdir,
                                          iv_file_dir)
    );
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --I/F�t�@�C�����o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => xxccp_common_pkg.get_msg(gv_cnst_msg_kbn,
                                          gv_cnst_msg_if_ifna,
                                          gv_cnst_tkn_fname,
                                          iv_file_name)
    );
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
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
    --�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
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
      lv_message_code := cv_if_error_msg;
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
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCCP005A01C;
/
