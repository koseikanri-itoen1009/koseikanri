CREATE OR REPLACE PACKAGE BODY xxcmm003a36c
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2009. All rights reserved.
 *
 * Package Name     : XXCMM003A36C(body)
 * Description      : �e���}�X�^�A�gIF�f�[�^�쐬
 * MD.050           : MD050_CMM_003_A36_�e���}�X�^�A�gIF�f�[�^�쐬
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  file_open              �t�@�C���I�[�v������(A-2)
 *  write_csv              CSV�t�@�C���o�͏���(A-4)
 *  output_mst_data        �����Ώۃf�[�^���o����(A-3)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��(A-5 �I������)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/02/12    1.0   Akinori Takeshita   �V�K�쐬
 *  2009-03-09    1.1   Yutaka.Kuboshima    �t�@�C���o�͐�̃v���t�@�C���̕ύX
 *  2009-04-02    1.2   Yutaka.Kuboshima    ��QT1_0182�AT1_0254�̑Ή�
 *  2009-04-15    1.3   Yutaka.Kuboshima    ��QT1_0577�̑Ή�
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn            CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_warn;   --�x��:1
  cv_status_error           CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_error;  --�ُ�:2
  --WHO�J����
  cn_created_by             CONSTANT NUMBER       := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE         := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER       := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE         := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER       := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER       := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER       := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER       := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE         := SYSDATE;                    --PROGRAM_UPDATE_DATE
--
  gv_xxcmm_msg_kbn          CONSTANT VARCHAR2(5)  := 'XXCMM'; --���b�Z�[�W�敪
  gv_xxccp_msg_kbn          CONSTANT VARCHAR2(5)  := 'XXCCP'; --���b�Z�[�W�敪
--
  cv_msg_part               CONSTANT VARCHAR2(3)  := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3)  := '.';
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
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_out_file_dir  VARCHAR2(100);
  gv_out_file_file VARCHAR2(100);
-- 2009/04/02 Ver1.2 add start by Yutaka.Kuboshima
  gd_process_date  DATE;
-- 2009/04/02 Ver1.2 add end by Yutaka.Kuboshima
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
  init_err_expt                  EXCEPTION; --���������G���[
  fopen_err_expt                 EXCEPTION; --�t�@�C���I�[�v���G���[
  no_date_err_expt               EXCEPTION; --�Ώۃf�[�^0��
  write_failure_expt             EXCEPTION; --CSV�f�[�^�o�̓G���[
  fclose_err_expt                EXCEPTION; --�t�@�C���N���[�Y�G���[
  
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                CONSTANT VARCHAR2(12)  := 'XXCMM003A36C';      --�p�b�P�[�W��
  cv_comma                   CONSTANT VARCHAR2(1)   := ',';
  cv_dqu                     CONSTANT VARCHAR2(1)   := '"';                 --�����񊇂�
--
  --���b�Z�[�W
  cv_header_str_msg          CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00341';  --CSV�t�@�C���w�b�_������
  cv_file_name_msg           CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-05102';  -- �t�@�C�����m�[�g  
--
  --�G���[���b�Z�[�W
  cv_profile_err_msg         CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00002';  --�v���t�@�C���擾�G���[
  cv_file_path_invalid_msg   CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00003';  --�t�@�C���p�X�s���G���[
  cv_file_path_null_msg      CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00004';  --�t�@�C���p�XNULL�G���[
  cv_file_name_null_msg      CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00006';  --�t�@�C����NULL�G���[
  cv_exist_err_msg           CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00010';  --CSV�t�@�C�����݃`�F�b�N
  cv_write_err_msg           CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00009';  --CSV�f�[�^�o�̓G���[
  cv_no_data_err_msg         CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00329';  --�Q�ƃR�[�h�擾�G���[
  cv_no_mst_data_err_msg     CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00330';  --�}�X�^�f�[�^�Ȃ�
  cv_file_close_err_msg      CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00489';  --�t�@�C���N���[�Y�G���[
  --�g�[�N��
  cv_ng_profile              CONSTANT VARCHAR2(10)  := 'NG_PROFILE';        -- �v���t�@�C���擾���s�g�[�N��
  cv_sqlerrm                 CONSTANT VARCHAR2(10)  := 'SQLERRM';           -- �t�@�C���N���[�Y�G���[�g�[�N��
  cv_tkn_filename            CONSTANT VARCHAR2(10)  := 'FILE_NAME';         -- �t�@�C����
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
-- 2009/03/09 modify start
--    cv_out_file_dir  CONSTANT VARCHAR2(30) := 'XXCMM1_003A36_OUT_FILE_DIR';   --XXCMM:�e���}�X�^�A�gIF�f�[�^�쐬�pCSV�t�@�C���o�͐�
    cv_out_file_dir  CONSTANT VARCHAR2(30) := 'XXCMM1_JYOHO_OUT_DIR';         --XXCMM:���n(OUTBOUND)�A�g�pCSV�t�@�C���o�͐�
-- 2009/03/09 modify end
    cv_out_file_file CONSTANT VARCHAR2(30) := 'XXCMM1_003A36_OUT_FILE_FIL';   --XXCMM:�e���}�X�^�A�gIF�f�[�^�쐬�pCSV�t�@�C����
    cv_invalid_path  CONSTANT VARCHAR2(25) := 'CSV�o�̓f�B���N�g��';          --�v���t�@�C���擾���s�i�f�B���N�g���j
    cv_invalid_name  CONSTANT VARCHAR2(20) := 'CSV�o�̓t�@�C����';            --�v���t�@�C���擾���s�i�t�@�C�����j
--
    -- *** ���[�J���ϐ� ***
    lv_file_chk     BOOLEAN;
    ln_file_size    NUMBER;
    ln_block_size   NUMBER;
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
    --CSV�o�̓f�B���N�g�����v���t�@�C�����擾�B���s���̓G���[
    gv_out_file_dir := FND_PROFILE.VALUE(cv_out_file_dir);
    IF (gv_out_file_dir IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                            cv_profile_err_msg,
                                            cv_ng_profile,
                                            cv_invalid_path);
      lv_errbuf := lv_errmsg;
      RAISE init_err_expt;
    END IF;
--
    --CSV�o�̓t�@�C�������v���t�@�C�����擾�B���s���̓G���[
    gv_out_file_file := FND_PROFILE.VALUE(cv_out_file_file);
    IF (gv_out_file_file IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                            cv_profile_err_msg,
                                            cv_ng_profile,
                                            cv_invalid_name);
      lv_errbuf := lv_errmsg;
      RAISE init_err_expt;
    END IF;
--
    --�t�@�C�����݃`�F�b�N
    UTL_FILE.FGETATTR(gv_out_file_dir, gv_out_file_file, lv_file_chk, ln_file_size, ln_block_size);
    IF lv_file_chk THEN
      lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                            cv_exist_err_msg);
      lv_errbuf := lv_errmsg;
      RAISE init_err_expt;
    END IF;
--
-- 2009/04/02 Ver1.2 add start by Yutaka.Kuboshima
    --�Ɩ����t�擾
    gd_process_date := xxccp_common_pkg2.get_process_date;
-- 2009/04/02 Ver1.2 add end by Yutaka.Kuboshima
  EXCEPTION
    WHEN init_err_expt THEN                           --*** ����������O ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      --����������O���A�Ώی����A�G���[������1���Œ�Ƃ���
      gn_target_cnt := 1;
      gn_error_cnt  := 1;
--
--#################################  �Œ��O������ START   ####################################
--
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
   * Description      : �t�@�C���I�[�v������(A-2)
   ***********************************************************************************/
  PROCEDURE file_open(
    of_file_handler OUT UTL_FILE.FILE_TYPE,  --   �t�@�C���n���h��
    ov_errbuf       OUT VARCHAR2,            --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode      OUT VARCHAR2,            --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg       OUT VARCHAR2)            --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'file_open'; -- �v���O������
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
    cn_record_byte CONSTANT NUMBER      := 4095;  --�t�@�C���ǂݍ��ݕ�����
    cv_file_mode   CONSTANT VARCHAR2(1) := 'W';   --�������݃��[�h�ŊJ��
--
    -- *** ���[�J���ϐ� ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    BEGIN
      --�t�@�C���I�[�v��
      of_file_handler := UTL_FILE.FOPEN(gv_out_file_dir,
                                        gv_out_file_file,
                                        cv_file_mode,
                                        cn_record_byte);
    EXCEPTION
      --�t�@�C���p�X�G���[
      WHEN UTL_FILE.INVALID_PATH THEN
        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxccp_msg_kbn,
                                              cv_file_path_invalid_msg);
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
      --�t�@�C���I�[�v���G���[���A�Ώی����A�x�������ƁA�G���[������1���Œ�Ƃ���
      gn_target_cnt := 1;
      gn_warn_cnt := 1;
      gn_error_cnt  := 1;
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
  END file_open;
--
  /**********************************************************************************
   * Procedure Name   : write_csv
   * Description      : CSV�o��
   ***********************************************************************************/
  PROCEDURE write_csv(
    ref_type         IN  VARCHAR2,            --   �Q�ƃ^�C�v
    ref_code         IN  VARCHAR2,            --   �Q�ƃR�[�h
    ref_name         IN  VARCHAR2,            --   ����
    pt_ref_type      IN  VARCHAR2,            --   �e�Q�ƃ^�C�v
    pt_ref_code      IN  VARCHAR2,            --   �e�Q�ƃR�[�h
    if_file_handler  IN  UTL_FILE.FILE_TYPE,  --   �t�@�C���n���h��
    ov_errbuf        OUT VARCHAR2,            --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode       OUT VARCHAR2,            --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg        OUT VARCHAR2)            --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #      
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'write_csv'; -- �v���O������
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
    cn_record_byte       CONSTANT NUMBER          := 4095;                --�t�@�C���ǂݍ��ݕ�����
    cv_file_mode         CONSTANT VARCHAR2(1)     := 'W';                 --�������݃��[�h�ŊJ��
    cv_ng_word           CONSTANT VARCHAR2(7)     := 'NG_WORD';           --CSV�o�̓G���[�g�[�N���ENG_WORD
    cv_ng_data           CONSTANT VARCHAR2(7)     := 'NG_DATA';           --CSV�o�̓G���[�g�[�N���ENG_DATA
    cv_err_ref_type_msg  CONSTANT VARCHAR2(20)    := '�Q�ƃ^�C�v';        --CSV�o�̓G���[������
    cv_comp_code         CONSTANT VARCHAR2(3)     := '001';               --��ЃR�[�h
--
    -- *** ���[�J���ϐ� ***
    lv_output_str        VARCHAR2(4095)           := NULL;                --�o�͕�����i�[�p�ϐ�
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    BEGIN

      --������o��    
      lv_output_str := cv_dqu        || cv_comp_code || cv_dqu;                       --��ЃR�[�h
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(ref_type, 1, 30) || cv_dqu;     --�Q�ƃ^�C�v
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(ref_code, 1, 30) || cv_dqu;     --�Q�ƃR�[�h
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(ref_name, 1, 80) || cv_dqu;     --����
-- 2009/04/15 Ver1.3 modify start by Yutaka.Kuboshima
-- 2009/04/02 Ver1.2 modify start by Yutaka.Kuboshima
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(pt_ref_type, 1, 30) || cv_dqu;  --�e�Q�ƃ^�C�v
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(pt_ref_code, 1, 30) || cv_dqu;  --�e�Q�ƃR�[�h
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(pt_ref_code, 1, 30) || cv_dqu;  --�e�Q�ƃR�[�h
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(pt_ref_type, 1, 30) || cv_dqu;  --�e�Q�ƃ^�C�v
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(pt_ref_type, 1, 30) || cv_dqu;  --�e�Q�ƃ^�C�v
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(pt_ref_code, 1, 30) || cv_dqu;  --�e�Q�ƃR�[�h
-- 2009/04/02 Ver1.2 modify end by Yutaka.Kuboshima
-- 2009/04/15 Ver1.3 modify end by Yutaka.Kuboshima
      --CSV�t�@�C���o��
      UTL_FILE.PUT_LINE(if_file_handler,lv_output_str);

    EXCEPTION
      WHEN UTL_FILE.WRITE_ERROR THEN  --*** �t�@�C���������݃G���[ ***
        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_write_err_msg,
                                              cv_ng_word,
                                              cv_err_ref_type_msg,
                                              cv_ng_data,
                                              ref_type);
        lv_errbuf  := lv_errmsg;
        RAISE write_failure_expt;

      WHEN OTHERS THEN
        RAISE;
    END;
--
  EXCEPTION
    WHEN write_failure_expt THEN       --*** �t�@�C���������݃G���[ ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END write_csv;
--
  /**********************************************************************************
   * Procedure Name   : output_mst_data
   * Description      : �����Ώۃf�[�^���o����(A-3)�ECSV�t�@�C���o�͏���(A-4)
   ***********************************************************************************/
  PROCEDURE output_mst_data(
    if_file_handler         IN  UTL_FILE.FILE_TYPE,  --   �t�@�C���n���h��
    ov_errbuf               OUT VARCHAR2,            --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode              OUT VARCHAR2,            --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg               OUT VARCHAR2)            --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'output_mst_data'; -- �v���O������
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
    cv_y_flag             CONSTANT VARCHAR2(1)     := 'Y';                      --�L���t���OY
    cv_language_ja        CONSTANT VARCHAR2(2)     := 'JA';                     --����(���{��)
--
    cv_auto_ex_flag       CONSTANT VARCHAR2(1)     := '2';                      --�����o�W�t���O�E�֘A�ڋq
    cv_ng_word            CONSTANT VARCHAR2(7)     := 'NG_WORD';                --CSV�o�̓G���[�g�[�N���ENG_WORD
    cv_ng_data            CONSTANT VARCHAR2(7)     := 'NG_DATA';                --CSV�o�̓G���[�g�[�N���ENG_DATA
    cv_lookup_type        CONSTANT VARCHAR2(11)    := 'LOOKUP_TYPE';            --���o�f�[�^�擾�G���[�g�[�N��
    cv_ng_table           CONSTANT VARCHAR2(5)     := 'TABLE';                  --�}�X�^�f�[�^�擾�G���[�g�[�N��
    cv_err_cust_code_msg  CONSTANT VARCHAR2(20)    := '�ڋq�R�[�h';             --CSV�o�̓G���[������
-- 2009/04/02 Ver1.2 add start by Yutaka.Kuboshima
    cv_max_date           CONSTANT VARCHAR2(8)     := '99991231';               --MAX���t
    cv_date_format        CONSTANT VARCHAR2(8)     := 'YYYYMMDD';               --���t����
-- 2009/04/02 Ver1.2 add end by Yutaka.Kuboshima
--
    -- *** ���[�J���ϐ� ***
    lv_header_str                  VARCHAR2(2000)  := NULL;                     --�w�b�_���b�Z�[�W�i�[�p�ϐ�
    ln_output_cnt                  NUMBER          := 0;                        --�o�͌���
    ln_warn_cnt                    NUMBER          := 0;                        --�x������
    ln_data_cnt                    NUMBER          := 0;                        --�o�̓f�[�^����
--
  BEGIN

    --�t�@�C���w�b�_�[�o��
    lv_header_str := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_header_str_msg);

    -- ===============================
    -- 1.�Q�ƃR�[�h���̎擾
    -- ===============================
    --1-1.�C���X�^���X�^�C�v�擾
    DECLARE

      CURSOR lookup_cur IS
                            SELECT
                                   lookup_type AS lv_ref_type 
                                  ,lookup_code AS lv_ref_code 
                                  ,meaning     AS lv_ref_name                                 
                                  ,NULL        AS lv_pt_ref_type
                                  ,NULL        AS lv_pt_ref_code
                            FROM  fnd_lookup_values
                            WHERE language = cv_language_ja
                            AND   lookup_type = 'CSI_INST_TYPE_CODE'
                            AND   enabled_flag = cv_y_flag
                            ORDER BY lookup_code;

      lookup_rec lookup_cur%ROWTYPE;

    BEGIN

      OPEN lookup_cur;

        << lookup_loop >>
        LOOP

          FETCH lookup_cur INTO lookup_rec;
          EXIT WHEN lookup_cur%NOTFOUND;

            -- �t�@�C���o��
           write_csv(
               lookup_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,lookup_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,lookup_rec.lv_ref_name     -- ����
              ,lookup_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,lookup_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
           );

          --�J�[�\���J�E���g
          ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE lookup_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'CSI_INST_TYPE_CODE');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;
        
      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;

      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-2.�ڋq�敪�擾
    DECLARE

      CURSOR custkbn_cur IS
                             SELECT
                                    lookup_type AS lv_ref_type 
                                   ,lookup_code AS lv_ref_code 
                                   ,meaning     AS lv_ref_name                                 
                                   ,NULL        AS lv_pt_ref_type
                                   ,NULL        AS lv_pt_ref_code
                             FROM  fnd_lookup_values
                             WHERE language = cv_language_ja 
-- 2009/04/02 Ver1.2 modify start by Yutaka.Kuboshima
--                             AND   lookup_type = 'CUSTOMER_CLASS'
                             AND   lookup_type = 'CUSTOMER CLASS'
-- 2009/04/02 Ver1.2 modify end by Yutaka.Kuboshima
                             AND   enabled_flag = cv_y_flag
                             ORDER BY lookup_code;

      custkbn_rec custkbn_cur%ROWTYPE;

    BEGIN

      OPEN custkbn_cur;

        << custkbn_loop >>
        LOOP

          FETCH custkbn_cur INTO custkbn_rec;
          EXIT WHEN custkbn_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               custkbn_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,custkbn_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,custkbn_rec.lv_ref_name     -- ����
              ,custkbn_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,custkbn_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE custkbn_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
-- 2009/04/02 Ver1.2 modify start by Yutaka.Kuboshima
--                                              'CUSTOMER_CLASS');
                                              'CUSTOMER CLASS');
-- 2009/04/02 Ver1.2 modify end by Yutaka.Kuboshima
        ov_retcode := cv_status_warn;
                                              
        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-3.���ʋ敪�擾
    DECLARE

      CURSOR gender_cur IS
                            SELECT
                                   lookup_type AS lv_ref_type 
                                  ,lookup_code AS lv_ref_code 
                                  ,meaning     AS lv_ref_name                                 
                                  ,NULL        AS lv_pt_ref_type     
                                  ,NULL        AS lv_pt_ref_code
                            FROM  fnd_lookup_values
                            WHERE language = cv_language_ja
                            AND   lookup_type = 'PQH_GENDER'
                            AND   enabled_flag = cv_y_flag
                            ORDER BY lookup_code;

      gender_rec gender_cur%ROWTYPE;

    BEGIN

      OPEN gender_cur;

        << gender_loop >>
        LOOP

          FETCH gender_cur INTO gender_rec;
          EXIT WHEN gender_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               gender_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,gender_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,gender_rec.lv_ref_name     -- ����
              ,gender_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,gender_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE gender_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'PQH_GENDER');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-4.���[�X��ЃR�[�h�擾
    DECLARE

      CURSOR lease_cur IS
                           SELECT
                                  lookup_type AS lv_ref_type 
                                 ,lookup_code AS lv_ref_code 
-- 2009/04/02 Ver1.2 modify start by Yutaka.Kuboshima
--                                 ,meaning     AS lv_ref_name                                 
                                 ,description AS lv_ref_name
-- 2009/04/02 Ver1.2 modify end by Yutaka.Kuboshima
                                 ,NULL        AS lv_pt_ref_type
                                 ,NULL        AS lv_pt_ref_code
                           FROM  fnd_lookup_values
                           WHERE language = cv_language_ja 
                           AND   lookup_type = 'XXCFF1_LEASE_COMPANY'
                           AND   enabled_flag = cv_y_flag
                           ORDER BY lookup_code;

      lease_rec lease_cur%ROWTYPE;

    BEGIN

      OPEN lease_cur;

        << lease_loop >>
        LOOP

          FETCH lease_cur INTO lease_rec;
          EXIT WHEN lease_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               lease_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,lease_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,lease_rec.lv_ref_name     -- ����
              ,lease_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,lease_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE lease_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCFF1_LEASE_COMPANY');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-5.�ă��[�X�敪�擾
    DECLARE

      CURSOR leasekbn_cur IS
                              SELECT
                                     lookup_type AS lv_ref_type
                                    ,lookup_code AS lv_ref_code
-- 2009/04/02 Ver1.2 modify start by Yutaka.Kuboshima
--                                    ,meaning     AS lv_ref_name                                 
                                    ,description AS lv_ref_name
-- 2009/04/02 Ver1.2 modify end by Yutaka.Kuboshima
                                    ,NULL        AS lv_pt_ref_type
                                    ,NULL        AS lv_pt_ref_code
                              FROM  fnd_lookup_values
                              WHERE language = cv_language_ja 
                              AND   lookup_type = 'XXCFF1_LEASE_TYPE'
                              AND   enabled_flag = cv_y_flag
                              ORDER BY lookup_code;

      leasekbn_rec leasekbn_cur%ROWTYPE;

    BEGIN

      OPEN leasekbn_cur;

        << leasekbn_loop >>
        LOOP

          FETCH leasekbn_cur INTO leasekbn_rec;
          EXIT WHEN leasekbn_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               leasekbn_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,leasekbn_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,leasekbn_rec.lv_ref_name     -- ����
              ,leasekbn_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,leasekbn_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE leasekbn_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCFF1_LEASE_TYPE');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-6.�Z���^�[EDI�敪�擾
    DECLARE

      CURSOR edikbn_cur IS
                            SELECT  
                                   lookup_type AS lv_ref_type 
                                  ,lookup_code AS lv_ref_code 
                                  ,meaning     AS lv_ref_name                                 
                                  ,NULL        AS lv_pt_ref_type
                                  ,NULL        AS lv_pt_ref_code
                            FROM  fnd_lookup_values
                            WHERE language = cv_language_ja 
                            AND   lookup_type = 'XXCMM_CUST_CENTER_EDI_KBN'
                            AND   enabled_flag = cv_y_flag
                            ORDER BY lookup_code;

      edikbn_rec edikbn_cur%ROWTYPE;

    BEGIN

      OPEN edikbn_cur;

        << edikbn_loop >>
        LOOP

          FETCH edikbn_cur INTO edikbn_rec;
          EXIT WHEN edikbn_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               edikbn_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,edikbn_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,edikbn_rec.lv_ref_name     -- ����
              ,edikbn_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,edikbn_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE edikbn_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_CUST_CENTER_EDI_KBN');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-7.�n��R�[�h�擾
    DECLARE

      CURSOR chikucode_cur IS
                               SELECT  
                                      lookup_type AS lv_ref_type 
                                     ,lookup_code AS lv_ref_code 
                                     ,meaning     AS lv_ref_name                                 
                                     ,NULL        AS lv_pt_ref_type
                                     ,NULL        AS lv_pt_ref_code
                               FROM  fnd_lookup_values
                               WHERE language = cv_language_ja 
                               AND   lookup_type = 'XXCMM_CUST_CHIKU_CODE'
                               AND   enabled_flag = cv_y_flag
                               ORDER BY lookup_code;

      chikucode_rec chikucode_cur%ROWTYPE;

    BEGIN

      OPEN chikucode_cur;

        << chikucode_loop >>
        LOOP

          FETCH chikucode_cur INTO chikucode_rec;
          EXIT WHEN chikucode_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               chikucode_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,chikucode_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,chikucode_rec.lv_ref_name     -- ����
              ,chikucode_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,chikucode_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE chikucode_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_CUST_CHIKU_CODE');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-8.���~���R�敪�擾
    DECLARE

      CURSOR chushi_cur IS
                            SELECT  
                                   lookup_type AS lv_ref_type 
                                  ,lookup_code AS lv_ref_code 
                                  ,meaning     AS lv_ref_name                                 
                                  ,NULL        AS lv_pt_ref_type
                                  ,NULL        AS lv_pt_ref_code
                            FROM  fnd_lookup_values
                            WHERE language = cv_language_ja 
                            AND   lookup_type = 'XXCMM_CUST_CHUSHI_RIYU'
                            AND   enabled_flag = cv_y_flag
                            ORDER BY lookup_code;

      chushi_rec chushi_cur%ROWTYPE;

    BEGIN

      OPEN chushi_cur;

        << chushi_loop >>
        LOOP

          FETCH chushi_cur INTO chushi_rec;
          EXIT WHEN chushi_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               chushi_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,chushi_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,chushi_rec.lv_ref_name     -- ����
              ,chushi_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,chushi_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE chushi_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_CUST_CHUSHI_RIYU');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-9.�Ɩ������ގ擾
    DECLARE

      CURSOR chu_gyotai_cur IS
                                SELECT
                                       lookup_type AS lv_ref_type 
                                      ,lookup_code AS lv_ref_code 
                                      ,meaning     AS lv_ref_name                                 
-- 2009/04/02 Ver1.2 modify start by Yutaka.Kuboshima
--                                      ,NULL        AS lv_pt_ref_type
--                                      ,NULL        AS lv_pt_ref_code
                                      ,'XXCMM_CUST_GYOTAI_DAI' AS lv_pt_ref_type
                                      ,attribute1              AS lv_pt_ref_code
-- 2009/04/02 Ver1.2 modify end by Yutaka.Kuboshima
                                FROM  fnd_lookup_values
                                WHERE language = cv_language_ja 
                                AND   lookup_type = 'XXCMM_CUST_GYOTAI_CHU'
                                AND   enabled_flag = cv_y_flag
                                ORDER BY lookup_code;

      chu_gyotai_rec chu_gyotai_cur%ROWTYPE;
     
    BEGIN

      OPEN chu_gyotai_cur;

        << chu_gyotai_loop >>
        LOOP

          FETCH chu_gyotai_cur INTO chu_gyotai_rec;
          EXIT WHEN chu_gyotai_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               chu_gyotai_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,chu_gyotai_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,chu_gyotai_rec.lv_ref_name     -- ����
              ,chu_gyotai_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,chu_gyotai_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE chu_gyotai_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_CUST_GYOTAI_CHU');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-10.�Ƒԑ啪�ގ擾
    DECLARE

      CURSOR dai_gyotai_cur IS
                                SELECT  
                                       lookup_type AS lv_ref_type 
                                      ,lookup_code AS lv_ref_code 
                                      ,meaning     AS lv_ref_name                                 
                                      ,NULL        AS lv_pt_ref_type
                                      ,NULL        AS lv_pt_ref_code
                                FROM  fnd_lookup_values
                                WHERE language = cv_language_ja 
                                AND   lookup_type = 'XXCMM_CUST_GYOTAI_DAI'
                                AND   enabled_flag = cv_y_flag
                                ORDER BY lookup_code;

      dai_gyotai_rec dai_gyotai_cur%ROWTYPE;

    BEGIN

      OPEN dai_gyotai_cur;

        << dai_gyotai_loop >>
        LOOP

          FETCH dai_gyotai_cur INTO dai_gyotai_rec;
          EXIT WHEN dai_gyotai_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               dai_gyotai_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,dai_gyotai_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,dai_gyotai_rec.lv_ref_name     -- ����
              ,dai_gyotai_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,dai_gyotai_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE dai_gyotai_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_CUST_GYOTAI_DAI');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-11.�Ǝ�擾
    DECLARE

      CURSOR gyoshu_cur IS
                          SELECT
                                 lookup_type AS lv_ref_type 
                                ,lookup_code AS lv_ref_code 
                                ,meaning     AS lv_ref_name                                 
                                ,NULL        AS lv_pt_ref_type     
                                ,NULL        AS lv_pt_ref_code
                          FROM  fnd_lookup_values
                          WHERE language = cv_language_ja
                          AND   lookup_type = 'XXCMM_CUST_GYOTAI_KBN'
                          AND   enabled_flag = cv_y_flag
                          ORDER BY lookup_code;

      gyoshu_rec gyoshu_cur%ROWTYPE;

    BEGIN

      OPEN gyoshu_cur;

        << gyoshu_loop >>
        LOOP

          FETCH gyoshu_cur INTO gyoshu_rec;
          EXIT WHEN gyoshu_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               gyoshu_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,gyoshu_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,gyoshu_rec.lv_ref_name     -- ����
              ,gyoshu_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,gyoshu_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE gyoshu_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_CUST_GYOTAI_KBN');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-12.�Ƒԏ����ގ擾
    DECLARE

      CURSOR sho_gyotai_cur IS
                                SELECT
                                       lookup_type AS lv_ref_type 
                                      ,lookup_code AS lv_ref_code 
                                      ,meaning     AS lv_ref_name                                 
-- 2009/04/02 Ver1.2 modify start by Yutaka.Kuboshima
--                                      ,NULL        AS lv_pt_ref_type
--                                      ,NULL        AS lv_pt_ref_code
                                      ,'XXCMM_CUST_GYOTAI_CHU' AS lv_pt_ref_type
                                      ,attribute1              AS lv_pt_ref_code
-- 2009/04/02 Ver1.2 modify end by Yutaka.Kuboshima
                                FROM  fnd_lookup_values
                                WHERE language = cv_language_ja 
                                AND   lookup_type = 'XXCMM_CUST_GYOTAI_SHO'
                                AND   enabled_flag = cv_y_flag
                                ORDER BY lookup_code;

      sho_gyotai_rec sho_gyotai_cur%ROWTYPE;

    BEGIN

      OPEN sho_gyotai_cur;

        << sho_gyotai_loop >>
        LOOP

          FETCH sho_gyotai_cur INTO sho_gyotai_rec;
          EXIT WHEN sho_gyotai_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               sho_gyotai_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,sho_gyotai_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,sho_gyotai_rec.lv_ref_name     -- ����
              ,sho_gyotai_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,sho_gyotai_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE sho_gyotai_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_CUST_GYOTAI_SHO');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-13.�z���`�Ԏ擾
    DECLARE

      CURSOR haisou_cur IS
                            SELECT
                                   lookup_type AS lv_ref_type
                                  ,lookup_code AS lv_ref_code 
                                  ,meaning     AS lv_ref_name                                 
                                  ,NULL        AS lv_pt_ref_type
                                  ,NULL        AS lv_pt_ref_code
                            FROM  fnd_lookup_values
                            WHERE language = cv_language_ja 
                            AND   lookup_type = 'XXCMM_CUST_HAISO_KETAI'
                            AND   enabled_flag = cv_y_flag
                            ORDER BY lookup_code;

      haisou_rec haisou_cur%ROWTYPE;

    BEGIN

      OPEN haisou_cur;

        << haisou_loop >>
        LOOP

          FETCH haisou_cur INTO haisou_rec;
          EXIT WHEN haisou_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               haisou_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,haisou_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,haisou_rec.lv_ref_name     -- ����
              ,haisou_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,haisou_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE haisou_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_CUST_HAISO_KETAI');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;
      
    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-14.�K��Ώۋ敪�擾
    DECLARE

      CURSOR houmon_target_cur IS
                                   SELECT  
                                          lookup_type AS lv_ref_type 
                                         ,lookup_code AS lv_ref_code 
                                         ,meaning     AS lv_ref_name                                 
                                         ,NULL        AS lv_pt_ref_type     
                                         ,NULL        AS lv_pt_ref_code
                                   FROM  fnd_lookup_values
                                   WHERE language = cv_language_ja 
                                   AND   lookup_type = 'XXCMM_CUST_HOMON_TAISYO_KBN'
                                   AND   enabled_flag = cv_y_flag
                                   ORDER BY lookup_code;

      houmon_target_rec houmon_target_cur%ROWTYPE;

    BEGIN

      OPEN houmon_target_cur;

        << houmon_target_loop >>
        LOOP

          FETCH houmon_target_cur INTO houmon_target_rec;
          EXIT WHEN houmon_target_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               houmon_target_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,houmon_target_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,houmon_target_rec.lv_ref_name     -- ����
              ,houmon_target_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,houmon_target_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE houmon_target_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_CUST_HOMON_TAISYO_KBN');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-15.�ڋq�X�e�[�^�X�擾
    DECLARE

      CURSOR cust_status_cur IS
                                 SELECT
                                        lookup_type AS lv_ref_type 
                                       ,lookup_code AS lv_ref_code 
                                       ,meaning     AS lv_ref_name                                 
                                       ,NULL        AS lv_pt_ref_type
                                       ,NULL        AS lv_pt_ref_code
                                 FROM  fnd_lookup_values
                                 WHERE language = cv_language_ja 
                                 AND   lookup_type = 'XXCMM_CUST_KOKYAKU_STATUS'
                                 AND   enabled_flag = cv_y_flag
                                 ORDER BY lookup_code;

      cust_status_rec cust_status_cur%ROWTYPE;

    BEGIN

      OPEN cust_status_cur;

        << cust_status_loop >>
        LOOP

          FETCH cust_status_cur INTO cust_status_rec;
          EXIT WHEN cust_status_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               cust_status_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,cust_status_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,cust_status_rec.lv_ref_name     -- ����
              ,cust_status_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,cust_status_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE cust_status_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_CUST_KOKYAKU_STATUS');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-16.MCHOT�擾
    DECLARE

      CURSOR mchot_cur IS
                           SELECT
                                  lookup_type AS lv_ref_type 
                                 ,lookup_code AS lv_ref_code 
                                 ,meaning     AS lv_ref_name                                 
                                 ,NULL        AS lv_pt_ref_type
                                 ,NULL        AS lv_pt_ref_code
                           FROM  fnd_lookup_values
                           WHERE language = cv_language_ja
                           AND   lookup_type = 'XXCMM_CUST_MCHOTDO'
                           AND   enabled_flag = cv_y_flag
                           ORDER BY lookup_code;

      mchot_rec mchot_cur%ROWTYPE;

    BEGIN

      OPEN mchot_cur;

        << mchot_loop >>
        LOOP

          FETCH mchot_cur INTO mchot_rec;
          EXIT WHEN mchot_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               mchot_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,mchot_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,mchot_rec.lv_ref_name     -- ����
              ,mchot_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,mchot_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE mchot_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_CUST_MCHOTDO');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;    

    --1-17.MC�d�v�x�擾
    DECLARE

      CURSOR mc_jyuyou_cur IS
                               SELECT 
                                      lookup_type AS lv_ref_type 
                                     ,lookup_code AS lv_ref_code 
                                     ,meaning     AS lv_ref_name                                 
                                     ,NULL        AS lv_pt_ref_type
                                     ,NULL        AS lv_pt_ref_code
                               FROM  fnd_lookup_values
                               WHERE language = cv_language_ja
                               AND   lookup_type = 'XXCMM_CUST_MCJUYODO'
                               AND   enabled_flag = cv_y_flag
                               ORDER BY lookup_code;

      mc_jyuyou_rec mc_jyuyou_cur%ROWTYPE;

    BEGIN

      OPEN mc_jyuyou_cur;

        << mc_jyuyou_loop >>
        LOOP

          FETCH mc_jyuyou_cur INTO mc_jyuyou_rec;
          EXIT WHEN mc_jyuyou_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               mc_jyuyou_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,mc_jyuyou_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,mc_jyuyou_rec.lv_ref_name     -- ����
              ,mc_jyuyou_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,mc_jyuyou_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE mc_jyuyou_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_CUST_MCJUYODO');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;    

    --1-18.�I�[�v���E�N���[�Y�擾
    DECLARE

      CURSOR open_close_cur IS
                                SELECT  
                                       lookup_type AS lv_ref_type 
                                      ,lookup_code AS lv_ref_code 
                                      ,meaning     AS lv_ref_name                                 
                                      ,NULL        AS lv_pt_ref_type
                                      ,NULL        AS lv_pt_ref_code
                                FROM  fnd_lookup_values
                                WHERE language = cv_language_ja
                                AND   lookup_type = 'XXCMM_CUST_OPEN_CLOSE_KBN'
                                AND   enabled_flag = cv_y_flag
                                ORDER BY lookup_code;

      open_close_rec open_close_cur%ROWTYPE;

    BEGIN

      OPEN open_close_cur;

        << open_close_loop >>
        LOOP

          FETCH open_close_cur INTO open_close_rec;
          EXIT WHEN open_close_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               open_close_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,open_close_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,open_close_rec.lv_ref_name     -- ����
              ,open_close_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,open_close_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE open_close_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_CUST_OPEN_CLOSE_KBN');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-19.���������s�敪�擾
    DECLARE

      CURSOR invoice_cur IS
                             SELECT
                                    lookup_type AS lv_ref_type 
                                   ,lookup_code AS lv_ref_code 
                                   ,meaning     AS lv_ref_name                                 
                                   ,NULL        AS lv_pt_ref_type
                                   ,NULL        AS lv_pt_ref_code
                             FROM  fnd_lookup_values
                             WHERE language = cv_language_ja 
                             AND   lookup_type = 'XXCMM_CUST_SEKYUSYO_HAKKO_KBN'
                             AND   enabled_flag = cv_y_flag
                             ORDER BY lookup_code;

      invoice_rec invoice_cur%ROWTYPE;

    BEGIN

      OPEN invoice_cur;

        << invoice_loop >>
        LOOP

          FETCH invoice_cur INTO invoice_rec;
          EXIT WHEN invoice_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               invoice_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,invoice_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,invoice_rec.lv_ref_name     -- ����
              ,invoice_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,invoice_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE invoice_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_CUST_SEKYUSYO_HAKKO_KBN');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-20.���������敪�擾
    DECLARE

      CURSOR seikyuu_syori_cur IS
                                   SELECT 
                                          lookup_type AS lv_ref_type 
                                         ,lookup_code AS lv_ref_code 
                                         ,meaning     AS lv_ref_name                                 
                                         ,NULL        AS lv_pt_ref_type
                                         ,NULL        AS lv_pt_ref_code
                                   FROM  fnd_lookup_values
                                   WHERE language = cv_language_ja 
                                   AND   lookup_type = 'XXCMM_CUST_SEKYUSYO_SHUT_KSK'
                                   AND   enabled_flag = cv_y_flag
                                   ORDER BY lookup_code;

     seikyuu_syori_rec seikyuu_syori_cur%ROWTYPE;

    BEGIN

      OPEN seikyuu_syori_cur;

        << seikyuu_syori_loop >>
        LOOP

          FETCH seikyuu_syori_cur INTO seikyuu_syori_rec;
          EXIT WHEN seikyuu_syori_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               seikyuu_syori_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,seikyuu_syori_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,seikyuu_syori_rec.lv_ref_name     -- ����
              ,seikyuu_syori_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,seikyuu_syori_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE seikyuu_syori_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_CUST_SEKYUSYO_SHUT_KSK');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-21.�V�K�|�C���g�敪�擾
    DECLARE

      CURSOR new_point_cur IS
                               SELECT 
                                      lookup_type AS lv_ref_type
                                     ,lookup_code AS lv_ref_code 
                                     ,meaning     AS lv_ref_name                                 
                                     ,NULL        AS lv_pt_ref_type     
                                     ,NULL        AS lv_pt_ref_code
                               FROM  fnd_lookup_values
                               WHERE language = cv_language_ja 
                               AND   lookup_type = 'XXCMM_CUST_SHINKI_POINT_KBN'
                               AND   enabled_flag = cv_y_flag
                               ORDER BY lookup_code;

      new_point_rec new_point_cur%ROWTYPE;

    BEGIN

      OPEN new_point_cur;

        << new_point_loop >>
        LOOP

          FETCH new_point_cur INTO new_point_rec;
          EXIT WHEN new_point_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               new_point_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,new_point_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,new_point_rec.lv_ref_name     -- ����
              ,new_point_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,new_point_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE new_point_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_CUST_SHINKI_POINT_KBN');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-22.����敪�擾
    DECLARE

      CURSOR judge_cur IS
                           SELECT 
                                  lookup_type AS lv_ref_type 
                                 ,lookup_code AS lv_ref_code 
                                 ,meaning     AS lv_ref_name                                 
                                 ,NULL        AS lv_pt_ref_type
                                 ,NULL        AS lv_pt_ref_code
                           FROM  fnd_lookup_values
                           WHERE language = cv_language_ja 
                           AND   lookup_type = 'XXCMM_CUST_SOHYO_KBN'
                           AND   enabled_flag = cv_y_flag
                           ORDER BY lookup_code;

      judge_rec judge_cur%ROWTYPE;

    BEGIN

      OPEN judge_cur;

        << judge_loop >>
        LOOP

          FETCH judge_cur INTO judge_rec;
          EXIT WHEN judge_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               judge_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,judge_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,judge_rec.lv_ref_name     -- ����
              ,judge_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,judge_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE judge_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_CUST_SOHYO_KBN');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-23.EDI�菑�`�[�`���擾
    DECLARE

      CURSOR tegaki_den_cur IS
                                SELECT 
                                       lookup_type AS lv_ref_type 
                                      ,lookup_code AS lv_ref_code 
                                      ,meaning     AS lv_ref_name                                 
                                      ,NULL        AS lv_pt_ref_type
                                      ,NULL        AS lv_pt_ref_code
                                FROM  fnd_lookup_values
                                WHERE language = cv_language_ja 
                                AND   lookup_type = 'XXCMM_CUST_TEGAKI_DENSOU_KBN'
                                AND   enabled_flag = cv_y_flag
                                ORDER BY lookup_code;

      tegaki_den_rec tegaki_den_cur%ROWTYPE;

    BEGIN

      OPEN tegaki_den_cur;

        << tegaki_loop >>
        LOOP

          FETCH tegaki_den_cur INTO tegaki_den_rec;
          EXIT WHEN tegaki_den_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               tegaki_den_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,tegaki_den_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,tegaki_den_rec.lv_ref_name     -- ����
              ,tegaki_den_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,tegaki_den_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE tegaki_den_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_CUST_TEGAKI_DENSOU_KBN');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-24.����`�Ԏ擾
    DECLARE

      CURSOR torihiki_cur IS
                              SELECT  
                                     lookup_type AS lv_ref_type 
                                    ,lookup_code AS lv_ref_code 
                                    ,meaning     AS lv_ref_name                                 
                                    ,NULL        AS lv_pt_ref_type
                                    ,NULL        AS lv_pt_ref_code
                              FROM  fnd_lookup_values
                              WHERE language = cv_language_ja 
                              AND   lookup_type = 'XXCMM_CUST_TORIHIKI_KETAI'
                              AND   enabled_flag = cv_y_flag
                              ORDER BY lookup_code;

      torihiki_rec torihiki_cur%ROWTYPE;

    BEGIN

      OPEN torihiki_cur;

        << torihiki_loop >>
        LOOP

          FETCH torihiki_cur INTO torihiki_rec;
          EXIT WHEN torihiki_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               torihiki_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,torihiki_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,torihiki_rec.lv_ref_name     -- ����
              ,torihiki_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,torihiki_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE torihiki_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_CUST_TORIHIKI_KETAI');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-25.�ʉߍ݌Ɍ^�敪�擾
    DECLARE

      CURSOR tuuka_zaiko_cur IS
                                 SELECT 
                                        lookup_type AS lv_ref_type 
                                       ,lookup_code AS lv_ref_code 
                                       ,meaning     AS lv_ref_name                                 
                                       ,NULL        AS lv_pt_ref_type     
                                       ,NULL        AS lv_pt_ref_code
                                 FROM  fnd_lookup_values
                                 WHERE language = cv_language_ja 
                                 AND   lookup_type = 'XXCMM_CUST_TSUKAGATAZAIKO_KBN'
                                 AND   enabled_flag = cv_y_flag
                                 ORDER BY lookup_code;

      tuuka_zaiko_rec tuuka_zaiko_cur%ROWTYPE;

    BEGIN

      OPEN tuuka_zaiko_cur;

        << tuuka_zaiko_loop >>
        LOOP

          FETCH tuuka_zaiko_cur INTO tuuka_zaiko_rec;
          EXIT WHEN tuuka_zaiko_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               tuuka_zaiko_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,tuuka_zaiko_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,tuuka_zaiko_rec.lv_ref_name     -- ����
              ,tuuka_zaiko_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,tuuka_zaiko_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE tuuka_zaiko_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_CUST_TSUKAGATAZAIKO_KBN');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-26.������ѐU�擾
    DECLARE

      CURSOR uriage_jisseki_cur IS
                                    SELECT 
                                           lookup_type AS lv_ref_type 
                                          ,lookup_code AS lv_ref_code 
                                          ,meaning     AS lv_ref_name                                 
                                          ,NULL        AS lv_pt_ref_type
                                          ,NULL        AS lv_pt_ref_code
                                    FROM  fnd_lookup_values
                                    WHERE language = cv_language_ja 
                                    AND   lookup_type = 'XXCMM_CUST_URIAGE_JISSEKI_FURI'
                                    AND   enabled_flag = cv_y_flag
                                    ORDER BY lookup_code;

      uriage_jisseki_rec uriage_jisseki_cur%ROWTYPE;

    BEGIN

      OPEN uriage_jisseki_cur;

        << uriage_jisseki_loop >>
        LOOP

          FETCH uriage_jisseki_cur INTO uriage_jisseki_rec;
          EXIT WHEN uriage_jisseki_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               uriage_jisseki_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,uriage_jisseki_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,uriage_jisseki_rec.lv_ref_name     -- ����
              ,uriage_jisseki_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,uriage_jisseki_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE uriage_jisseki_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_CUST_URIAGE_JISSEKI_FURI');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-27.������ѐU�擾
    DECLARE

      CURSOR secchi_loca_cur IS
                                 SELECT 
                                        lookup_type AS lv_ref_type
                                       ,lookup_code AS lv_ref_code
                                       ,meaning     AS lv_ref_name                                 
                                       ,NULL        AS lv_pt_ref_type
                                       ,NULL        AS lv_pt_ref_code
                                 FROM  fnd_lookup_values
                                 WHERE language = cv_language_ja 
                                 AND   lookup_type = 'XXCMM_CUST_VD_SECCHI_BASYO'
                                 AND   enabled_flag = cv_y_flag
                                 ORDER BY lookup_code;

      secchi_loca_rec secchi_loca_cur%ROWTYPE;

    BEGIN

      OPEN secchi_loca_cur;

        << secchi_loop >>
        LOOP

          FETCH secchi_loca_cur INTO secchi_loca_rec;
          EXIT WHEN secchi_loca_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               secchi_loca_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,secchi_loca_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,secchi_loca_rec.lv_ref_name     -- ����
              ,secchi_loca_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,secchi_loca_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE secchi_loca_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_CUST_VD_SECCHI_BASYO');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-28.�c�ƌ`�Ԏ擾
    DECLARE

      CURSOR eigyo_keitai_cur IS
                                  SELECT 
                                         lookup_type AS lv_ref_type 
                                        ,lookup_code AS lv_ref_code 
                                        ,meaning     AS lv_ref_name                                 
                                        ,NULL        AS lv_pt_ref_type
                                        ,NULL        AS lv_pt_ref_code
                                  FROM  fnd_lookup_values
                                  WHERE language = cv_language_ja 
                                  AND   lookup_type = 'XXCMM_EIGYOKETAI'
                                  AND   enabled_flag = cv_y_flag
                                  ORDER BY lookup_code;

      eigyo_keitai_rec eigyo_keitai_cur%ROWTYPE;

    BEGIN

      OPEN eigyo_keitai_cur;

        << eigyo_keitai_loop >>
        LOOP

          FETCH eigyo_keitai_cur INTO eigyo_keitai_rec;
          EXIT WHEN eigyo_keitai_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               eigyo_keitai_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,eigyo_keitai_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,eigyo_keitai_rec.lv_ref_name     -- ����
              ,eigyo_keitai_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,eigyo_keitai_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE eigyo_keitai_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_EIGYOKETAI');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-29.���������s�T�C�N���擾
    DECLARE

      CURSOR invoice_cycle_cur IS
                                   SELECT 
                                          lookup_type AS lv_ref_type 
                                         ,lookup_code AS lv_ref_code 
                                         ,meaning     AS lv_ref_name                                 
                                         ,NULL        AS lv_pt_ref_type
                                         ,NULL        AS lv_pt_ref_code
                                   FROM  fnd_lookup_values
                                   WHERE language = cv_language_ja
                                   AND   lookup_type = 'XXCMM_INVOICE_ISSUE_CYCLE'
                                   AND   enabled_flag = cv_y_flag
                                   ORDER BY lookup_code;

      invoice_cycle_rec invoice_cycle_cur%ROWTYPE;

    BEGIN

      OPEN invoice_cycle_cur;

        << invoice_loop >>
        LOOP

          FETCH invoice_cycle_cur INTO invoice_cycle_rec;
          EXIT WHEN invoice_cycle_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               invoice_cycle_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,invoice_cycle_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,invoice_cycle_rec.lv_ref_name     -- ����
              ,invoice_cycle_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,invoice_cycle_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE invoice_cycle_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_INVOICE_ISSUE_CYCLE');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-30.�o���Q�擾
    DECLARE

      CURSOR keirigun_cur IS
                              SELECT 
                                     lookup_type AS lv_ref_type 
                                    ,lookup_code AS lv_ref_code 
                                    ,meaning     AS lv_ref_name                                 
                                    ,NULL        AS lv_pt_ref_type
                                    ,NULL        AS lv_pt_ref_code
                              FROM  fnd_lookup_values
                              WHERE language = cv_language_ja 
                              AND   lookup_type = 'XXCMM_ITM_KERIGUN'
                              AND   enabled_flag = cv_y_flag
                              ORDER BY lookup_code;

      keirigun_rec keirigun_cur%ROWTYPE;

    BEGIN

      OPEN keirigun_cur;

        << keirigun_loop >>
        LOOP

          FETCH keirigun_cur INTO keirigun_rec;
          EXIT WHEN keirigun_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               keirigun_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,keirigun_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,keirigun_rec.lv_ref_name     -- ����
              ,keirigun_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,keirigun_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE keirigun_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_ITM_KERIGUN');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-31.�e��Q�R�[�h�擾
    DECLARE

      CURSOR youkigun_cur IS
                              SELECT 
                                     lookup_type AS lv_ref_type 
                                    ,lookup_code AS lv_ref_code 
                                    ,meaning     AS lv_ref_name                                 
                                    ,NULL        AS lv_pt_ref_type
                                    ,NULL        AS lv_pt_ref_code
                              FROM  fnd_lookup_values
                              WHERE language = cv_language_ja 
                              AND   lookup_type = 'XXCMM_ITM_YOKIGUN'
                              AND   enabled_flag = cv_y_flag
                              ORDER BY lookup_code;

      youkigun_rec youkigun_cur%ROWTYPE;
     
    BEGIN

      OPEN youkigun_cur;

        << youkigun_loop >>
        LOOP

          FETCH youkigun_cur INTO youkigun_rec;
          EXIT WHEN youkigun_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               youkigun_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,youkigun_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,youkigun_rec.lv_ref_name     -- ����
              ,youkigun_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,youkigun_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE youkigun_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_ITM_YOKIGUN');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-32.�≮�Ǘ��R�[�h�擾
    DECLARE

      CURSOR tonya_cur IS
                           SELECT 
                                  lookup_type AS lv_ref_type 
                                 ,lookup_code AS lv_ref_code 
                                 ,meaning     AS lv_ref_name                                 
                                 ,NULL        AS lv_pt_ref_type
                                 ,NULL        AS lv_pt_ref_code
                           FROM  fnd_lookup_values
                           WHERE language = cv_language_ja
                           AND   lookup_type = 'XXCMM_TONYA_CODE'
                           AND   enabled_flag = cv_y_flag
                           ORDER BY lookup_code;

      tonya_rec tonya_cur%ROWTYPE;

    BEGIN

      OPEN tonya_cur;

        << tonya_loop >>
        LOOP

          FETCH tonya_cur INTO tonya_rec;
          EXIT WHEN tonya_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               tonya_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,tonya_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,tonya_rec.lv_ref_name     -- ����
              ,tonya_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,tonya_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE tonya_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_TONYA_CODE');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-33.�v�Z����-�e��敪�擾
    DECLARE

      CURSOR youkikbn_cur IS
                              SELECT 
                                     lookup_type AS lv_ref_type 
                                    ,lookup_code AS lv_ref_code 
                                    ,meaning     AS lv_ref_name
                                    ,NULL        AS lv_pt_ref_type
                                    ,NULL        AS lv_pt_ref_code
                              FROM  fnd_lookup_values
                              WHERE language = cv_language_ja 
                              AND   lookup_type = 'XXCMM_YOKI_KUBUN'
                              AND   enabled_flag = cv_y_flag
                              ORDER BY lookup_code;

      youkikbn_rec youkikbn_cur%ROWTYPE;

    BEGIN

      OPEN youkikbn_cur;

        << youkikbn_loop >>
        LOOP

          FETCH youkikbn_cur INTO youkikbn_rec;
          EXIT WHEN youkikbn_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               youkikbn_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,youkikbn_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,youkikbn_rec.lv_ref_name     -- ����
              ,youkikbn_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,youkikbn_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE youkikbn_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_YOKI_KUBUN');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-34.�Ј��E�O���ϑ��敪�擾
    DECLARE

      CURSOR emp_class_cur IS
                               SELECT
                                      lookup_type AS lv_ref_type
                                     ,lookup_code AS lv_ref_code 
                                     ,meaning     AS lv_ref_name                                 
                                     ,NULL        AS lv_pt_ref_type     
                                     ,NULL        AS lv_pt_ref_code
                               FROM  fnd_lookup_values
                               WHERE language = cv_language_ja 
                               AND   lookup_type = 'XXCMN_EMPLOYEE_CLASS'
                               AND   enabled_flag = cv_y_flag
                               ORDER BY lookup_code;

      emp_class_rec emp_class_cur%ROWTYPE;

    BEGIN

      OPEN emp_class_cur;

        << emp_class_loop >>
        LOOP

          FETCH emp_class_cur INTO emp_class_rec;
          EXIT WHEN emp_class_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               emp_class_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,emp_class_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,emp_class_rec.lv_ref_name     -- ����
              ,emp_class_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,emp_class_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE emp_class_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMN_EMPLOYEE_CLASS');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-35.�ۊǏꏊ�敪�擾
    DECLARE

      CURSOR hokankbn_cur IS 
                              SELECT 
                                     lookup_type AS lv_ref_type 
                                    ,lookup_code AS lv_ref_code 
                                    ,meaning     AS lv_ref_name                                 
                                    ,NULL        AS lv_pt_ref_type
                                    ,NULL        AS lv_pt_ref_code
                              FROM  fnd_lookup_values
                              WHERE language = cv_language_ja 
                              AND   lookup_type = 'XXCOI_SECINV_HOKANBASYO_KUBUN'
                              AND   enabled_flag = cv_y_flag
                              ORDER BY lookup_code;

      hokankbn_rec hokankbn_cur%ROWTYPE;

    BEGIN

      OPEN hokankbn_cur;

        << hokankbn_loop >>
        LOOP

          FETCH hokankbn_cur INTO hokankbn_rec;
          EXIT WHEN hokankbn_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               hokankbn_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,hokankbn_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,hokankbn_rec.lv_ref_name     -- ����
              ,hokankbn_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,hokankbn_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE hokankbn_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCOI_SECINV_HOKANBASYO_KUBUN');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-36.�v�Z�����擾
    DECLARE

      CURSOR calc_type_cur IS
                               SELECT 
                                      lookup_type AS lv_ref_type 
                                     ,lookup_code AS lv_ref_code 
                                     ,meaning     AS lv_ref_name                                 
                                     ,NULL        AS lv_pt_ref_type     
                                     ,NULL        AS lv_pt_ref_code
                               FROM  fnd_lookup_values
                               WHERE language = cv_language_ja 
                               AND   lookup_type = 'XXCOK1_BM_CALC_TYPE'
                               AND   enabled_flag = cv_y_flag
                               ORDER BY lookup_code;

      calc_type_rec calc_type_cur%ROWTYPE;

    BEGIN

      OPEN calc_type_cur;

        << calc_type_loop >>
        LOOP

          FETCH calc_type_cur INTO calc_type_rec;
          EXIT WHEN calc_type_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               calc_type_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,calc_type_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,calc_type_rec.lv_ref_name     -- ����
              ,calc_type_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,calc_type_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE calc_type_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCOK1_BM_CALC_TYPE');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-37.���_�����ڍs���X�e�[�^�X�擾
    DECLARE

      CURSOR shift_status_cur IS
                                  SELECT 
                                         lookup_type AS lv_ref_type 
                                        ,lookup_code AS lv_ref_code 
                                        ,meaning     AS lv_ref_name                                 
                                        ,NULL        AS lv_pt_ref_type     
                                        ,NULL        AS lv_pt_ref_code
                                  FROM  fnd_lookup_values
                                  WHERE language = cv_language_ja 
                                  AND   lookup_type = 'XXCOK1_CUST_SHIFT_STATUS'
                                  AND   enabled_flag = cv_y_flag
                                  ORDER BY lookup_code;

      shift_status_rec shift_status_cur%ROWTYPE;

    BEGIN

      OPEN shift_status_cur;

        << shift_status_loop >>
        LOOP

          FETCH shift_status_cur INTO shift_status_rec;
          EXIT WHEN shift_status_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               shift_status_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,shift_status_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,shift_status_rec.lv_ref_name     -- ����
              ,shift_status_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,shift_status_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE shift_status_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCOK1_CUST_SHIFT_STATUS');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-38.�N���ڍs�敪�擾
    DECLARE

      CURSOR annual_kbn_cur IS
                                SELECT 
                                       lookup_type AS lv_ref_type 
                                      ,lookup_code AS lv_ref_code 
                                      ,meaning     AS lv_ref_name                                 
                                      ,NULL        AS lv_pt_ref_type
                                      ,NULL        AS lv_pt_ref_code
                                FROM  fnd_lookup_values
                                WHERE language = cv_language_ja 
                                AND   lookup_type = 'XXCOK1_SHIFT_DIVIDE'
                                AND   enabled_flag = cv_y_flag
                                ORDER BY lookup_code;

      annual_kbn_rec annual_kbn_cur%ROWTYPE;

    BEGIN

      OPEN annual_kbn_cur;

        << annual_kbn_loop >>
        LOOP

          FETCH annual_kbn_cur INTO annual_kbn_rec;
          EXIT WHEN annual_kbn_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               annual_kbn_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,annual_kbn_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,annual_kbn_rec.lv_ref_name     -- ����
              ,annual_kbn_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,annual_kbn_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE annual_kbn_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCOK1_SHIFT_DIVIDE');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-39.�J�[�h����敪�擾
    DECLARE

      CURSOR card_sale_cur IS
                               SELECT
                                      lookup_type AS lv_ref_type 
                                     ,lookup_code AS lv_ref_code
                                     ,meaning     AS lv_ref_name                                 
                                     ,NULL        AS lv_pt_ref_type     
                                     ,NULL        AS lv_pt_ref_code
                               FROM  fnd_lookup_values
                               WHERE language = cv_language_ja
                               AND   lookup_type = 'XXCOS1_CARD_SALE_CLASS'
                               AND   enabled_flag = cv_y_flag
                               ORDER BY lookup_code;

      card_sale_rec card_sale_cur%ROWTYPE;

    BEGIN

      OPEN card_sale_cur;

        << card_sale_loop >>
        LOOP

          FETCH card_sale_cur INTO card_sale_rec;
          EXIT WHEN card_sale_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               card_sale_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,card_sale_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,card_sale_rec.lv_ref_name     -- ����
              ,card_sale_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,card_sale_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE card_sale_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCOS1_CARD_SALE_CLASS');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-40.�[�i�`�Ԏ擾
    DECLARE

      CURSOR dliy_pattn_cur IS
                                SELECT 
                                       lookup_type AS lv_ref_type 
                                      ,lookup_code AS lv_ref_code 
                                      ,meaning     AS lv_ref_name                                 
                                      ,NULL        AS lv_pt_ref_type
                                      ,NULL        AS lv_pt_ref_code
                                FROM  fnd_lookup_values
                                WHERE language = cv_language_ja
                                AND   lookup_type = 'XXCOS1_DELIVERY_PATTERN'
                                AND   enabled_flag = cv_y_flag
                                ORDER BY lookup_code;

      dliy_pattn_rec dliy_pattn_cur%ROWTYPE;

    BEGIN

      OPEN dliy_pattn_cur;

        << dliy_pattn_loop >>
        LOOP

          FETCH dliy_pattn_cur INTO dliy_pattn_rec;
          EXIT WHEN dliy_pattn_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               dliy_pattn_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,dliy_pattn_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,dliy_pattn_rec.lv_ref_name     -- ����
              ,dliy_pattn_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,dliy_pattn_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE dliy_pattn_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCOS1_DELIVERY_PATTERN');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-41.HC�敪�擾
    DECLARE

      CURSOR hckbn_cur IS
                           SELECT 
                                  lookup_type AS lv_ref_type 
                                 ,lookup_code AS lv_ref_code 
                                 ,meaning     AS lv_ref_name                                 
                                 ,NULL        AS lv_pt_ref_type     
                                 ,NULL        AS lv_pt_ref_code
                           FROM  fnd_lookup_values
                           WHERE language = cv_language_ja 
                           AND   lookup_type = 'XXCOS1_HC_CLASS'
                           AND   enabled_flag = cv_y_flag
                           ORDER BY lookup_code;

      hckbn_rec hckbn_cur%ROWTYPE;

    BEGIN

      OPEN hckbn_cur;

        << hckbn_loop >>
        LOOP

          FETCH hckbn_cur INTO hckbn_rec;
          EXIT WHEN hckbn_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               hckbn_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,hckbn_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,hckbn_rec.lv_ref_name     -- ����
              ,hckbn_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,hckbn_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE hckbn_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCOS1_HC_CLASS');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-42.����敪�擾
    DECLARE

      CURSOR salekbn_cur IS
                             SELECT 
                                    lookup_type AS lv_ref_type 
                                   ,lookup_code AS lv_ref_code
                                   ,meaning     AS lv_ref_name                                 
                                   ,NULL        AS lv_pt_ref_type
                                   ,NULL        AS lv_pt_ref_code
                             FROM  fnd_lookup_values
                             WHERE language = cv_language_ja 
                             AND   lookup_type = 'XXCOS1_SALE_CLASS'
                             AND   enabled_flag = cv_y_flag
                             ORDER BY lookup_code;

      salekbn_rec salekbn_cur%ROWTYPE;

    BEGIN

      OPEN salekbn_cur;

        << salekbn_loop >>
        LOOP

          FETCH salekbn_cur INTO salekbn_rec;
          EXIT WHEN salekbn_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               salekbn_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,salekbn_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,salekbn_rec.lv_ref_name     -- ����
              ,salekbn_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,salekbn_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE salekbn_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCOS1_SALE_CLASS');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;    

    --1-43.����ԕi�敪�擾
    DECLARE

      CURSOR sales_return_cur IS 
                                  SELECT 
                                         lookup_type AS lv_ref_type 
                                        ,lookup_code AS lv_ref_code 
                                        ,meaning     AS lv_ref_name                                 
                                        ,NULL        AS lv_pt_ref_type     
                                        ,NULL        AS lv_pt_ref_code
                                  FROM  fnd_lookup_values
                                  WHERE language = cv_language_ja 
                                  AND   lookup_type = 'XXCOS1_SALES_RETURN_CLASS'
                                  AND   enabled_flag = cv_y_flag
                                  ORDER BY lookup_code;

      sales_return_rec sales_return_cur%ROWTYPE;
     
    BEGIN

      OPEN sales_return_cur;

        << sales_return >>
        LOOP

          FETCH sales_return_cur INTO sales_return_rec;
          EXIT WHEN sales_return_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               sales_return_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,sales_return_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,sales_return_rec.lv_ref_name     -- ����
              ,sales_return_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,sales_return_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE sales_return_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCOS1_SALES_RETURN_CLASS');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-44.�l���E�Љ�敪�擾
    DECLARE

      CURSOR kakutoku_kbn_cur IS
                                  SELECT 
                                         lookup_type AS lv_ref_type 
                                        ,lookup_code AS lv_ref_code 
                                        ,meaning     AS lv_ref_name                                 
                                        ,NULL        AS lv_pt_ref_type
                                        ,NULL        AS lv_pt_ref_code
                                  FROM  fnd_lookup_values
                                  WHERE language = cv_language_ja 
                                  AND   lookup_type = 'XXCSM1_ACQ_INTR_EMP_KBN'
                                  AND   enabled_flag = cv_y_flag
                                  ORDER BY lookup_code;

      kakutoku_kbn_rec kakutoku_kbn_cur%ROWTYPE;

    BEGIN

      OPEN kakutoku_kbn_cur;

        << kakutoku_loop >>
        LOOP

          FETCH kakutoku_kbn_cur INTO kakutoku_kbn_rec;
          EXIT WHEN kakutoku_kbn_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               kakutoku_kbn_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,kakutoku_kbn_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,kakutoku_kbn_rec.lv_ref_name     -- ����
              ,kakutoku_kbn_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,kakutoku_kbn_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE kakutoku_kbn_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSM1_ACQ_INTR_EMP_KBN');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;
    
    --1-45.���i(�Q)�敪�擾
    DECLARE

      CURSOR goods_grp_cur IS
                               SELECT 
                                      lookup_type AS lv_ref_type 
                                     ,lookup_code AS lv_ref_code 
                                     ,meaning     AS lv_ref_name                                 
                                     ,NULL        AS lv_pt_ref_type
                                     ,NULL        AS lv_pt_ref_code
                               FROM  fnd_lookup_values
                               WHERE language = cv_language_ja
                               AND   lookup_type = 'XXCSM1_ITEMGROUP_KBN'
                               AND   enabled_flag = cv_y_flag
                               ORDER BY lookup_code;

      goods_grp_rec goods_grp_cur%ROWTYPE;

    BEGIN

      OPEN goods_grp_cur;

        << goods_loop >>
        LOOP

          FETCH goods_grp_cur INTO goods_grp_rec;
          EXIT WHEN goods_grp_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               goods_grp_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,goods_grp_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,goods_grp_rec.lv_ref_name     -- ����
              ,goods_grp_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,goods_grp_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE goods_grp_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSM1_ITEMGROUP_KBN');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-46.����敪�擾
    DECLARE

      CURSOR news_kbn_cur IS
                              SELECT 
                                     lookup_type AS lv_ref_type 
                                    ,lookup_code AS lv_ref_code 
                                    ,meaning     AS lv_ref_name                                 
                                    ,NULL        AS lv_pt_ref_type     
                                    ,NULL        AS lv_pt_ref_code
                              FROM  fnd_lookup_values
                              WHERE language = cv_language_ja
                              AND   lookup_type = 'XXCSM1_NEWS_ITEM_KBN'
                              AND   enabled_flag = cv_y_flag
                              ORDER BY lookup_code;

      news_kbn_rec news_kbn_cur%ROWTYPE;

    BEGIN

      OPEN news_kbn_cur;

        << news_kbn_loop >>
        LOOP

          FETCH news_kbn_cur INTO news_kbn_rec;
          EXIT WHEN news_kbn_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               news_kbn_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,news_kbn_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,news_kbn_rec.lv_ref_name     -- ����
              ,news_kbn_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,news_kbn_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE news_kbn_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSM1_NEWS_ITEM_KBN');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-47.�|�C���g�敪�擾
    DECLARE

      CURSOR point_kbn_cur IS
                               SELECT 
                                      lookup_type AS lv_ref_type 
                                     ,lookup_code AS lv_ref_code 
                                     ,meaning     AS lv_ref_name                                 
                                     ,NULL        AS lv_pt_ref_type
                                     ,NULL        AS lv_pt_ref_code
                               FROM  fnd_lookup_values
                               WHERE language = cv_language_ja 
                               AND   lookup_type = 'XXCSM1_POINT_DATA_KBN'
                               AND   enabled_flag = cv_y_flag
                               ORDER BY lookup_code;

      point_kbn_rec point_kbn_cur%ROWTYPE;

    BEGIN

      OPEN point_kbn_cur;

        << point_kbn_loop >>
        LOOP

          FETCH point_kbn_cur INTO point_kbn_rec;
          EXIT WHEN point_kbn_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               point_kbn_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,point_kbn_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,point_kbn_rec.lv_ref_name     -- ����
              ,point_kbn_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,point_kbn_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE point_kbn_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSM1_POINT_DATA_KBN');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-48.�������[�J�[�擾
    DECLARE

      CURSOR maker_kbn_cur IS
                               SELECT 
                                      lookup_type AS lv_ref_type 
                                     ,lookup_code AS lv_ref_code 
                                     ,meaning     AS lv_ref_name                                 
                                     ,NULL        AS lv_pt_ref_type     
                                     ,NULL        AS lv_pt_ref_code
                               FROM  fnd_lookup_values
                               WHERE language = cv_language_ja 
                               AND   lookup_type = 'XXCSO_CSI_MAKER_CODE'
                               AND   enabled_flag = cv_y_flag
                               ORDER BY lookup_code;

      maker_kbn_rec maker_kbn_cur%ROWTYPE;

    BEGIN

      OPEN maker_kbn_cur;

        << maker_kbn >>
        LOOP

          FETCH maker_kbn_cur INTO maker_kbn_rec;
          EXIT WHEN maker_kbn_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               maker_kbn_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,maker_kbn_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,maker_kbn_rec.lv_ref_name     -- ����
              ,maker_kbn_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,maker_kbn_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE maker_kbn_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSO_CSI_MAKER_CODE');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-49.����@�敪�擾
    DECLARE

      CURSOR tokushuki_cur IS
                               SELECT 
                                      lookup_type AS lv_ref_type 
                                     ,lookup_code AS lv_ref_code 
                                     ,meaning     AS lv_ref_name                                 
                                     ,NULL        AS lv_pt_ref_type
                                     ,NULL        AS lv_pt_ref_code
                               FROM  fnd_lookup_values
                               WHERE language = cv_language_ja 
                               AND   lookup_type = 'XXCSO_CSI_TOKUSHUKI'
                               AND   enabled_flag = cv_y_flag
                               ORDER BY lookup_code;

      tokushuki_rec tokushuki_cur%ROWTYPE;

    BEGIN

      OPEN tokushuki_cur;

        << tokushuki_loop >>
        LOOP

          FETCH tokushuki_cur INTO tokushuki_rec;
          EXIT WHEN tokushuki_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               tokushuki_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,tokushuki_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,tokushuki_rec.lv_ref_name     -- ����
              ,tokushuki_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,tokushuki_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE tokushuki_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSO_CSI_TOKUSHUKI');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-50.�K��敪�擾
    DECLARE

      CURSOR houmon_kbn_cur IS
                                SELECT 
                                       lookup_type AS lv_ref_type 
                                      ,lookup_code AS lv_ref_code 
                                      ,meaning     AS lv_ref_name                                 
                                      ,NULL        AS lv_pt_ref_type
                                      ,NULL        AS lv_pt_ref_code
                                FROM  fnd_lookup_values
                                WHERE language = cv_language_ja 
-- 2009/04/02 Ver1.2 modify start by Yutaka.Kuboshima
--                                AND   lookup_type = 'XXCSO1_ASN_HOUMON_KUBUN'
                                AND   lookup_type = 'XXCSO_ASN_HOUMON_KUBUN'
-- 2009/04/02 Ver1.2 modify end by Yutaka.Kuboshima
                                AND   enabled_flag = cv_y_flag
                                ORDER BY lookup_code;

      houmon_kbn_rec houmon_kbn_cur%ROWTYPE;

    BEGIN

      OPEN houmon_kbn_cur;

        << houmon_kbn_loop >>
        LOOP

          FETCH houmon_kbn_cur INTO houmon_kbn_rec;
          EXIT WHEN houmon_kbn_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               houmon_kbn_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,houmon_kbn_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,houmon_kbn_rec.lv_ref_name     -- ����
              ,houmon_kbn_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,houmon_kbn_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE houmon_kbn_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
-- 2009/04/02 Ver1.2 modify start by Yutaka.Kuboshima
--                                              'XXCSO1_ASN_HOUMON_KUBUN');
                                              'XXCSO_ASN_HOUMON_KUBUN');
-- 2009/04/02 Ver1.2 modify end by Yutaka.Kuboshima
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-51.�Y��ړ��敪�擾
    DECLARE

      CURSOR csi_job_kbn_cur IS
                                 SELECT 
                                        lookup_type AS lv_ref_type 
                                       ,lookup_code AS lv_ref_code 
                                       ,meaning     AS lv_ref_name                                 
                                       ,NULL        AS lv_pt_ref_type
                                       ,NULL        AS lv_pt_ref_code
                                 FROM  fnd_lookup_values
                                 WHERE language = cv_language_ja
                                 AND   lookup_type = 'XXCSO1_CSI_JOB_KBN'
                                 AND   enabled_flag = cv_y_flag
                                 ORDER BY lookup_code;

      csi_job_kbn_rec csi_job_kbn_cur%ROWTYPE;

    BEGIN

      OPEN csi_job_kbn_cur;

        << csi_job_loop >>
        LOOP

          FETCH csi_job_kbn_cur INTO csi_job_kbn_rec;
          EXIT WHEN csi_job_kbn_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               csi_job_kbn_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,csi_job_kbn_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,csi_job_kbn_rec.lv_ref_name     -- ����
              ,csi_job_kbn_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,csi_job_kbn_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE csi_job_kbn_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSO1_CSI_JOB_KBN');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-52.�ŏI�ݒu�敪�擾
    DECLARE

      CURSOR csi_job_kbn2_cur IS
                                  SELECT 
                                         lookup_type AS lv_ref_type 
                                        ,lookup_code AS lv_ref_code 
                                        ,meaning     AS lv_ref_name                                 
                                        ,NULL        AS lv_pt_ref_type
                                        ,NULL        AS lv_pt_ref_code
                                  FROM  fnd_lookup_values
                                  WHERE language = cv_language_ja
                                  AND   lookup_type = 'XXCSO1_CSI_JOB_KBN2'
                                  AND   enabled_flag = cv_y_flag
                                  ORDER BY lookup_code;

     csi_job_kbn2_rec csi_job_kbn2_cur%ROWTYPE;

    BEGIN

      OPEN csi_job_kbn2_cur;

        << csi_job_kbn2 >>
        LOOP

          FETCH csi_job_kbn2_cur INTO csi_job_kbn2_rec;
          EXIT WHEN csi_job_kbn2_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               csi_job_kbn2_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,csi_job_kbn2_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,csi_job_kbn2_rec.lv_ref_name     -- ����
              ,csi_job_kbn2_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,csi_job_kbn2_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE csi_job_kbn2_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSO1_CSI_JOB_KBN2');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-53.�@���ԂP(�ғ����)�擾
    DECLARE

      CURSOR final_setubi_cur IS
                                  SELECT 
                                         lookup_type AS lv_ref_type 
                                        ,lookup_code AS lv_ref_code 
                                        ,meaning     AS lv_ref_name                                 
                                        ,NULL        AS lv_pt_ref_type     
                                        ,NULL        AS lv_pt_ref_code
                                  FROM  fnd_lookup_values
                                  WHERE language = cv_language_ja 
                                  AND   lookup_type = 'XXCSO1_CSI_JOTAI_KBN1'
                                  AND   enabled_flag = cv_y_flag
                                  ORDER BY lookup_code;

      final_setubi_rec final_setubi_cur%ROWTYPE;

    BEGIN

      OPEN final_setubi_cur;

        << final_setubi_loop >>
        LOOP

          FETCH final_setubi_cur INTO final_setubi_rec;
          EXIT WHEN final_setubi_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               final_setubi_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,final_setubi_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,final_setubi_rec.lv_ref_name     -- ����
              ,final_setubi_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,final_setubi_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE final_setubi_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSO1_CSI_JOTAI_KBN1');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-54.�@���ԂQ(��ԏڍ�)�擾
    DECLARE

      CURSOR final_setubi2_cur IS
                                   SELECT 
                                          lookup_type AS lv_ref_type 
                                         ,lookup_code AS lv_ref_code 
                                         ,meaning     AS lv_ref_name                                 
                                         ,NULL        AS lv_pt_ref_type     
                                         ,NULL        AS lv_pt_ref_code
                                   FROM  fnd_lookup_values
                                   WHERE language = cv_language_ja 
                                   AND   lookup_type = 'XXCSO1_CSI_JOTAI_KBN2'
                                   AND   enabled_flag = cv_y_flag
                                   ORDER BY lookup_code;

      final_setubi2_rec final_setubi2_cur%ROWTYPE;

    BEGIN

      OPEN final_setubi2_cur;

        << final_setubi2_loop >>
        LOOP

          FETCH final_setubi2_cur INTO final_setubi2_rec;
          EXIT WHEN final_setubi2_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               final_setubi2_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,final_setubi2_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,final_setubi2_rec.lv_ref_name     -- ����
              ,final_setubi2_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,final_setubi2_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE final_setubi2_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSO1_CSI_JOTAI_KBN2');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-55.�@���ԂR(�p�����)�擾
    DECLARE

      CURSOR final_setubi3_cur IS
                                   SELECT 
                                          lookup_type AS lv_ref_type 
                                         ,lookup_code AS lv_ref_code 
                                         ,meaning     AS lv_ref_name                                 
                                         ,NULL        AS lv_pt_ref_type
                                         ,NULL        AS lv_pt_ref_code
                                   FROM  fnd_lookup_values
                                   WHERE language = cv_language_ja 
                                   AND   lookup_type = 'XXCSO1_CSI_JOTAI_KBN3'
                                   AND   enabled_flag = cv_y_flag
                                   ORDER BY lookup_code;

      final_setubi3_rec final_setubi3_cur%ROWTYPE;

    BEGIN

      OPEN final_setubi3_cur;

        << final_setubi3_loop >>
        LOOP

          FETCH final_setubi3_cur INTO final_setubi3_rec;
          EXIT WHEN final_setubi3_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               final_setubi3_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,final_setubi3_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,final_setubi3_rec.lv_ref_name     -- ����
              ,final_setubi3_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,final_setubi3_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE final_setubi3_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSO1_CSI_JOTAI_KBN3');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-56.�]�������敪�擾
    DECLARE

      CURSOR csi_kanryo_cur IS
                                SELECT 
                                       lookup_type AS lv_ref_type 
                                      ,lookup_code AS lv_ref_code 
                                      ,meaning     AS lv_ref_name                                 
                                      ,NULL        AS lv_pt_ref_type
                                      ,NULL        AS lv_pt_ref_code
                                FROM  fnd_lookup_values
                                WHERE language = cv_language_ja 
                                AND   lookup_type = 'XXCSO1_CSI_KANRYO_KBN'
                                AND   enabled_flag = cv_y_flag
                                ORDER BY lookup_code;

      csi_kanryo_rec csi_kanryo_cur%ROWTYPE;

    BEGIN

      OPEN csi_kanryo_cur;

        << csi_kanryo_loop >>
        LOOP

          FETCH csi_kanryo_cur INTO csi_kanryo_rec;
          EXIT WHEN csi_kanryo_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               csi_kanryo_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,csi_kanryo_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,csi_kanryo_rec.lv_ref_name     -- ����
              ,csi_kanryo_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,csi_kanryo_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE csi_kanryo_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSO1_CSI_KANRYO_KBN');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-57.�ŏI��Ɛi���敪�擾
    DECLARE

      CURSOR sintyoku_kbn_cur IS
                                  SELECT 
                                         lookup_type AS lv_ref_type 
                                        ,lookup_code AS lv_ref_code 
                                        ,meaning     AS lv_ref_name                                 
                                        ,NULL        AS lv_pt_ref_type
                                        ,NULL        AS lv_pt_ref_code
                                  FROM  fnd_lookup_values
                                  WHERE language = cv_language_ja 
                                  AND   lookup_type = 'XXCSO1_CSI_SINTYOKU_KBN'
                                  AND   enabled_flag = cv_y_flag
                                  ORDER BY lookup_code;

      sintyoku_kbn_rec sintyoku_kbn_cur%ROWTYPE;

    BEGIN

      OPEN sintyoku_kbn_cur;

        << sintyoku_loop >>
        LOOP

          FETCH sintyoku_kbn_cur INTO sintyoku_kbn_rec;
          EXIT WHEN sintyoku_kbn_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               sintyoku_kbn_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,sintyoku_kbn_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,sintyoku_kbn_rec.lv_ref_name     -- ����
              ,sintyoku_kbn_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,sintyoku_kbn_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE sintyoku_kbn_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSO1_CSI_SINTYOKU_KBN');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-58.�ŏI�ݒu�i���敪�擾
    DECLARE

      CURSOR sintyoku_kbn2_cur IS
                                   SELECT 
                                          lookup_type AS lv_ref_type 
                                         ,lookup_code AS lv_ref_code 
                                         ,meaning     AS lv_ref_name                                 
                                         ,NULL        AS lv_pt_ref_type     
                                         ,NULL        AS lv_pt_ref_code
                                   FROM  fnd_lookup_values
                                   WHERE language = cv_language_ja
                                   AND   lookup_type = 'XXCSO1_CSI_SINTYOKU_KBN2'
                                   AND   enabled_flag = cv_y_flag
                                   ORDER BY lookup_code;

      sintyoku_kbn2_rec sintyoku_kbn2_cur%ROWTYPE;

    BEGIN

      OPEN sintyoku_kbn2_cur;

        << sintyoku_kbn2_loop >>
        LOOP

          FETCH sintyoku_kbn2_cur INTO sintyoku_kbn2_rec;
          EXIT WHEN sintyoku_kbn2_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               sintyoku_kbn2_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,sintyoku_kbn2_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,sintyoku_kbn2_rec.lv_ref_name     -- ����
              ,sintyoku_kbn2_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,sintyoku_kbn2_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE sintyoku_kbn2_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSO1_CSI_SINTYOKU_KBN2');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-59.�]���p���󋵃t���O�擾
    DECLARE

      CURSOR tenhai_flg_cur IS
                                SELECT 
                                       lookup_type AS lv_ref_type
                                      ,lookup_code AS lv_ref_code
                                      ,meaning     AS lv_ref_name
                                      ,NULL        AS lv_pt_ref_type
                                      ,NULL        AS lv_pt_ref_code
                                FROM  fnd_lookup_values
                                WHERE language = cv_language_ja 
                                AND   lookup_type = 'XXCSO1_CSI_TENHAI_FLG'
                                AND   enabled_flag = cv_y_flag
                                ORDER BY lookup_code;

      tenhai_flg_rec tenhai_flg_cur%ROWTYPE;
     
    BEGIN

      OPEN tenhai_flg_cur;

        << tenhai_loop >>
        LOOP

          FETCH tenhai_flg_cur INTO tenhai_flg_rec;
          EXIT WHEN tenhai_flg_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               tenhai_flg_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,tenhai_flg_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,tenhai_flg_rec.lv_ref_name     -- ����
              ,tenhai_flg_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,tenhai_flg_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE tenhai_flg_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSO1_CSI_TENHAI_FLG');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-60.�L���K��敪�擾
    DECLARE

      CURSOR visit_kbn_cur IS
                               SELECT 
                                      lookup_type AS lv_ref_type 
                                     ,lookup_code AS lv_ref_code 
                                     ,meaning     AS lv_ref_name                                 
                                     ,NULL        AS lv_pt_ref_type
                                     ,NULL        AS lv_pt_ref_code
                               FROM  fnd_lookup_values
                               WHERE language = cv_language_ja 
                               AND   lookup_type = 'XXCSO1_EFFECTIVE_VISIT_CL'
                               AND   enabled_flag = cv_y_flag
                               ORDER BY lookup_code;

      visit_kbn_rec visit_kbn_cur%ROWTYPE;

    BEGIN

      OPEN visit_kbn_cur;

        << visit_kbn_loop >>
        LOOP

          FETCH visit_kbn_cur INTO visit_kbn_rec;
          EXIT WHEN visit_kbn_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               visit_kbn_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,visit_kbn_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,visit_kbn_rec.lv_ref_name     -- ����
              ,visit_kbn_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,visit_kbn_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE visit_kbn_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSO1_EFFECTIVE_VISIT_CL');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;    

    --1-61.�p���t���O�擾
    DECLARE

      CURSOR haiki_kbn_cur IS
                               SELECT 
                                      lookup_type AS lv_ref_type 
                                     ,lookup_code AS lv_ref_code 
                                     ,meaning     AS lv_ref_name                                 
                                     ,NULL        AS lv_pt_ref_type
                                     ,NULL        AS lv_pt_ref_code
                               FROM  fnd_lookup_values
                               WHERE language = cv_language_ja
                               AND   lookup_type = 'XXCSO1_HAIKI_FLG'
                               AND   enabled_flag = cv_y_flag
                               ORDER BY lookup_code;

      haiki_kbn_rec haiki_kbn_cur%ROWTYPE;

    BEGIN

      OPEN haiki_kbn_cur;

        << haiki_kbn_loop >>
        LOOP

          FETCH haiki_kbn_cur INTO haiki_kbn_rec;
          EXIT WHEN haiki_kbn_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               haiki_kbn_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,haiki_kbn_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,haiki_kbn_rec.lv_ref_name     -- ����
              ,haiki_kbn_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,haiki_kbn_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE haiki_kbn_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSO1_HAIKI_FLG');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-62.IB��ƃf�[�^�폜�t���O�擾
    DECLARE

      CURSOR sakujyo_kbn_cur IS
                                 SELECT 
                                        lookup_type AS lv_ref_type 
                                       ,lookup_code AS lv_ref_code 
                                       ,meaning     AS lv_ref_name                                 
                                       ,NULL        AS lv_pt_ref_type     
                                       ,NULL        AS lv_pt_ref_code
                                 FROM  fnd_lookup_values
                                 WHERE language = cv_language_ja
                                 AND   lookup_type = 'XXCSO1_IB_IBWRK_SAKUJYO_FLG'
                                 AND   enabled_flag = cv_y_flag
                                 ORDER BY lookup_code;

      sakujyo_kbn_rec sakujyo_kbn_cur%ROWTYPE;

    BEGIN

      OPEN sakujyo_kbn_cur;

        << sakujyo_kbn_loop >>
        LOOP

          FETCH sakujyo_kbn_cur INTO sakujyo_kbn_rec;
          EXIT WHEN sakujyo_kbn_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               sakujyo_kbn_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,sakujyo_kbn_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,sakujyo_kbn_rec.lv_ref_name     -- ����
              ,sakujyo_kbn_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,sakujyo_kbn_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE sakujyo_kbn_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSO1_IB_IBWRK_SAKUJYO_FLG');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;


    --1-63.�X�e�[�^�X�擾
    DECLARE

      CURSOR inst_status_cur IS
                                 SELECT 
                                        lookup_type AS lv_ref_type
                                       ,lookup_code AS lv_ref_code 
                                       ,meaning     AS lv_ref_name                                 
                                       ,NULL AS lv_pt_ref_type     
                                       ,NULL        AS lv_pt_ref_code
                                 FROM  fnd_lookup_values
                                 WHERE language = cv_language_ja
                                 AND   lookup_type = 'XXCSO1_INSTANCE_STATUS'
                                 AND    enabled_flag = cv_y_flag
                                 ORDER BY lookup_code;

      inst_status_rec inst_status_cur%ROWTYPE;

    BEGIN

      OPEN inst_status_cur;

        << inst_status_loop >>
        LOOP

          FETCH inst_status_cur INTO inst_status_rec;
          EXIT WHEN inst_status_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               inst_status_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,inst_status_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,inst_status_rec.lv_ref_name     -- ����
              ,inst_status_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,inst_status_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE inst_status_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSO1_INSTANCE_STATUS');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-64.���ϋ敪�擾
    DECLARE

      CURSOR quote_kbn_cur IS
                               SELECT  
                                      lookup_type AS lv_ref_type 
                                     ,lookup_code AS lv_ref_code 
                                     ,meaning     AS lv_ref_name                                 
                                     ,NULL        AS lv_pt_ref_type     
                                     ,NULL        AS lv_pt_ref_code
                               FROM  fnd_lookup_values
                               WHERE language = cv_language_ja 
                               AND   lookup_type = 'XXCSO1_QUOTE_DIVISION'
                               AND   enabled_flag = cv_y_flag
                               ORDER BY lookup_code;

      quote_kbn_rec quote_kbn_cur%ROWTYPE;

    BEGIN

      OPEN quote_kbn_cur;

        << quote_kbn_loop >>
        LOOP

          FETCH quote_kbn_cur INTO quote_kbn_rec;
          EXIT WHEN quote_kbn_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               quote_kbn_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,quote_kbn_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,quote_kbn_rec.lv_ref_name     -- ����
              ,quote_kbn_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,quote_kbn_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE quote_kbn_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSO1_QUOTE_DIVISION');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-65.���σX�e�[�^�X�R�[�h�擾
    DECLARE

      CURSOR quote_status_cur IS
                                  SELECT 
                                         lookup_type AS lv_ref_type 
                                        ,lookup_code AS lv_ref_code 
                                        ,meaning     AS lv_ref_name                                 
                                        ,NULL        AS lv_pt_ref_type     
                                        ,NULL        AS lv_pt_ref_code
                                  FROM  fnd_lookup_values
                                  WHERE language = cv_language_ja
                                  AND   lookup_type = 'XXCSO1_QUOTE_STATUS'
                                  AND   enabled_flag = cv_y_flag
                                  ORDER BY lookup_code;

      quote_status_rec quote_status_cur%ROWTYPE;

    BEGIN

      OPEN quote_status_cur;

        << quote_status_loop >>
        LOOP

          FETCH quote_status_cur INTO quote_status_rec;
          EXIT WHEN quote_status_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               quote_status_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,quote_status_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,quote_status_rec.lv_ref_name     -- ����
              ,quote_status_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,quote_status_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE quote_status_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSO1_QUOTE_STATUS');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-66.���ώ�ގ擾
    DECLARE

      CURSOR quote_type_cur IS
                                SELECT 
                                       lookup_type AS lv_ref_type 
                                      ,lookup_code AS lv_ref_code 
                                      ,meaning     AS lv_ref_name                                 
                                      ,NULL        AS lv_pt_ref_type     
                                      ,NULL        AS lv_pt_ref_code
                                FROM  fnd_lookup_values
                                WHERE language = cv_language_ja 
                                AND   lookup_type = 'XXCSO1_QUOTE_TYPE'
                                AND   enabled_flag = cv_y_flag
                                ORDER BY lookup_code;

      quote_type_rec quote_type_cur%ROWTYPE;

    BEGIN

      OPEN quote_type_cur;

        << quote_type_loop >>
        LOOP

          FETCH quote_type_cur INTO quote_type_rec;
          EXIT WHEN quote_type_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               quote_type_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,quote_type_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,quote_type_rec.lv_ref_name     -- ����
              ,quote_type_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,quote_type_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE quote_type_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSO1_QUOTE_TYPE');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-67.�ŏI�������e�擾
    DECLARE

      CURSOR sagyo_lvl_cur IS
                               SELECT 
                                      lookup_type AS lv_ref_type 
                                     ,lookup_code AS lv_ref_code 
                                     ,meaning     AS lv_ref_name                                 
                                     ,NULL        AS lv_pt_ref_type
                                     ,NULL        AS lv_pt_ref_code
                               FROM  fnd_lookup_values
                               WHERE language = cv_language_ja
                               AND   lookup_type = 'XXCSO1_SAGYO_LEVEL'
                               AND   enabled_flag = cv_y_flag
                               ORDER BY lookup_code;

      sagyo_lvl_rec sagyo_lvl_cur%ROWTYPE;

    BEGIN

      OPEN sagyo_lvl_cur;

        << sagyo_lvl_loop >>
        LOOP

          FETCH sagyo_lvl_cur INTO sagyo_lvl_rec;
          EXIT WHEN sagyo_lvl_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               sagyo_lvl_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,sagyo_lvl_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,sagyo_lvl_rec.lv_ref_name     -- ����
              ,sagyo_lvl_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,sagyo_lvl_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE sagyo_lvl_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSO1_SAGYO_LEVEL');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-68.���Y�敪�擾
    DECLARE

      CURSOR seisan_kbn_cur IS
                                SELECT 
                                       lookup_type AS lv_ref_type 
                                      ,lookup_code AS lv_ref_code
                                      ,meaning     AS lv_ref_name                                 
                                      ,NULL        AS lv_pt_ref_type
                                      ,NULL        AS lv_pt_ref_code
                                FROM  fnd_lookup_values
                                WHERE language = cv_language_ja
                                AND   lookup_type = 'XXCSO1_SHISAN_KBN'
                                AND   enabled_flag = cv_y_flag
                                ORDER BY lookup_code;

      seisan_kbn_rec seisan_kbn_cur%ROWTYPE;

    BEGIN

      OPEN seisan_kbn_cur;

        << seisan_kbn_loop >>
        LOOP

          FETCH seisan_kbn_cur INTO seisan_kbn_rec;
          EXIT WHEN seisan_kbn_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               seisan_kbn_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,seisan_kbn_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,seisan_kbn_rec.lv_ref_name     -- ����
              ,seisan_kbn_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,seisan_kbn_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE seisan_kbn_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSO1_SHISAN_KBN');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-69.��Ɖ�ЃR�[�h�擾
    DECLARE

      CURSOR syozoku_mst_cur IS
-- 2009/04/03 Ver1.2 modify start by Yutaka.Kuboshima
--                                 SELECT 
--                                        lookup_type AS lv_ref_type 
--                                       ,lookup_code AS lv_ref_code 
--                                       ,meaning     AS lv_ref_name                                 
--                                       ,NULL        AS lv_pt_ref_type
--                                       ,NULL        AS lv_pt_ref_code
                                 SELECT DISTINCT
                                        lookup_type AS lv_ref_type
                                       ,attribute1  AS lv_ref_code
                                       ,attribute6  AS lv_ref_name
                                       ,NULL        AS lv_pt_ref_type
                                       ,NULL        AS lv_pt_ref_code
-- 2009/04/03 Ver1.2 modify end by Yutaka.Kuboshima
                                 FROM  fnd_lookup_values
                                 WHERE language = cv_language_ja
                                 AND   lookup_type = 'XXCSO1_SYOZOKU_MST'
                                 AND   enabled_flag = cv_y_flag
-- 2009/04/03 Ver1.2 modify start by Yutaka.Kuboshima
--                                 ORDER BY lookup_code;
                                 ORDER BY attribute1;
-- 2009/04/03 Ver1.2 modify end by Yutaka.Kuboshima
      syozoku_mst_rec syozoku_mst_cur%ROWTYPE;
     
    BEGIN

      OPEN syozoku_mst_cur;

        << syozoku_mst_loop >>
        LOOP

          FETCH syozoku_mst_cur INTO syozoku_mst_rec;
          EXIT WHEN syozoku_mst_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               syozoku_mst_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,syozoku_mst_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,syozoku_mst_rec.lv_ref_name     -- ����
              ,syozoku_mst_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,syozoku_mst_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE syozoku_mst_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSO1_SYOZOKU_MST');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-70.���Ə��R�[�h�擾
    DECLARE

      CURSOR jigyosyo_cur IS
                              SELECT 
                                     lookup_type AS lv_ref_type 
-- 2009/04/03 Ver1.2 modify start by Yutaka.Kuboshima
--                                    ,lookup_code AS lv_ref_code 
--                                    ,meaning     AS lv_ref_name                                 
                                    ,attribute2  AS lv_ref_code
                                    ,attribute7  AS lv_ref_name
-- 2009/04/03 Ver1.2 modify end by Yutaka.Kuboshima
                                    ,'XXCSO1_SYOZOKU_MST_DFF1' AS lv_pt_ref_type     
                                    ,attribute1  AS lv_pt_ref_code
                              FROM  fnd_lookup_values
                              WHERE language = cv_language_ja
                              AND   lookup_type = 'XXCSO1_SYOZOKU_MST'
                              AND   enabled_flag = cv_y_flag
                              ORDER BY lookup_code;

     jigyosyo_rec jigyosyo_cur%ROWTYPE;

    BEGIN

      OPEN jigyosyo_cur;

        << jigyosyo_loop >>
        LOOP

          FETCH jigyosyo_cur INTO jigyosyo_rec;
          EXIT WHEN jigyosyo_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               jigyosyo_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,jigyosyo_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,jigyosyo_rec.lv_ref_name     -- ����
              ,jigyosyo_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,jigyosyo_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE jigyosyo_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSO1_SYOZOKU_MST');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-71.�^�X�N�e�[�u���폜�t���O�擾
    DECLARE

      CURSOR task_del_cur IS 
                              SELECT  
                                     lookup_type AS lv_ref_type 
                                    ,lookup_code AS lv_ref_code 
                                    ,meaning     AS lv_ref_name                                 
                                    ,NULL        AS lv_pt_ref_type
                                    ,NULL        AS lv_pt_ref_code
                              FROM  fnd_lookup_values
                              WHERE language = cv_language_ja 
                              AND   lookup_type = 'XXCSO1_TASK_DELETE_FLG'
                              AND   enabled_flag = cv_y_flag
                              ORDER BY lookup_code;

      task_del_rec task_del_cur%ROWTYPE;

    BEGIN

      OPEN task_del_cur;

        << task_del_loop >>
        LOOP

          FETCH task_del_cur INTO task_del_rec;
          EXIT WHEN task_del_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               task_del_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,task_del_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,task_del_rec.lv_ref_name     -- ����
              ,task_del_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,task_del_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE task_del_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSO1_TASK_DELETE_FLG');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-72.�X�[���i�ŋ敪�擾
    DECLARE

      CURSOR tax_div_cur IS 
                             SELECT 
                                    lookup_type AS lv_ref_type 
                                   ,lookup_code AS lv_ref_code 
                                   ,meaning     AS lv_ref_name                                 
                                   ,NULL        AS lv_pt_ref_type     
                                   ,NULL        AS lv_pt_ref_code
                             FROM  fnd_lookup_values
                             WHERE language = cv_language_ja
                             AND   lookup_type = 'XXCSO1_TAX_DIVISION'
                             AND   enabled_flag = cv_y_flag
                             ORDER BY lookup_code;

      tax_div_rec tax_div_cur%ROWTYPE;
     
    BEGIN

      OPEN tax_div_cur;

        << tax_div_loop >>
        LOOP

          FETCH tax_div_cur INTO tax_div_rec;
          EXIT WHEN tax_div_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               tax_div_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,tax_div_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,tax_div_rec.lv_ref_name     -- ����
              ,tax_div_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,tax_div_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE tax_div_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSO1_TAX_DIVISION');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-73.�]���p���ƎҎ擾
    DECLARE

      CURSOR tenhai_tan_cur IS
                                SELECT 
                                       lookup_type AS lv_ref_type 
                                      ,lookup_code AS lv_ref_code 
                                      ,meaning     AS lv_ref_name                                 
                                      ,NULL        AS lv_pt_ref_type
                                      ,NULL        AS lv_pt_ref_code
                                FROM  fnd_lookup_values
                                WHERE language = cv_language_ja
                                AND   lookup_type = 'XXCSO1_TENHAI_TANTO'
                                AND   enabled_flag = cv_y_flag
                                ORDER BY lookup_code;

      tenhai_tan_rec tenhai_tan_cur%ROWTYPE;

    BEGIN

      OPEN tenhai_tan_cur;

        << tenhai_tan_loop >>
        LOOP

          FETCH tenhai_tan_cur INTO tenhai_tan_rec;
          EXIT WHEN tenhai_tan_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               tenhai_tan_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,tenhai_tan_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,tenhai_tan_rec.lv_ref_name     -- ����
              ,tenhai_tan_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,tenhai_tan_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE tenhai_tan_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSO1_TENHAI_TANTO');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-74.�P���敪�擾
    DECLARE

      CURSOR unit_price_cur IS
                                SELECT 
                                       lookup_type AS lv_ref_type
                                      ,lookup_code AS lv_ref_code
                                      ,meaning     AS lv_ref_name                                 
                                      ,NULL        AS lv_pt_ref_type     
                                      ,NULL        AS lv_pt_ref_code
                                FROM  fnd_lookup_values
                                WHERE language = cv_language_ja
                                AND   lookup_type = 'XXCSO1_UNIT_PRICE_DIVISION'
                                AND   enabled_flag = cv_y_flag
                                ORDER BY lookup_code;

      unit_price_rec unit_price_cur%ROWTYPE;
     
    BEGIN

      OPEN unit_price_cur;

        << unit_price_loop >>
        LOOP

          FETCH unit_price_cur INTO unit_price_rec;
          EXIT WHEN unit_price_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               unit_price_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,unit_price_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,unit_price_rec.lv_ref_name     -- ����
              ,unit_price_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,unit_price_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE unit_price_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSO1_UNIT_PRICE_DIVISION');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;
    
    --1-75.���ЃR�[�h�P�擾
    DECLARE

      CURSOR tasya_code_cur IS
                                SELECT 
                                       lookup_type AS lv_ref_type 
                                      ,lookup_code AS lv_ref_code 
                                      ,meaning     AS lv_ref_name                                 
                                      ,NULL        AS lv_pt_ref_type
                                      ,NULL        AS lv_pt_ref_code
                                FROM  fnd_lookup_values
                                WHERE language = cv_language_ja
                                AND   lookup_type = 'XXCSO1_VEN_TASYA_CODE'
                                AND   enabled_flag = cv_y_flag
                                ORDER BY lookup_code;

      tasya_code_rec tasya_code_cur%ROWTYPE;
     
    BEGIN

      OPEN tasya_code_cur;

        << tasya_code_loop >>
        LOOP

          FETCH tasya_code_cur INTO tasya_code_rec;
          EXIT WHEN tasya_code_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               tasya_code_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,tasya_code_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,tasya_code_rec.lv_ref_name     -- ����
              ,tasya_code_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,tasya_code_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE tasya_code_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSO1_VEN_TASYA_CODE');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-76.��ƈ˗����t���O�擾
    DECLARE

      CURSOR req_code_cur IS
                              SELECT 
                                     lookup_type AS lv_ref_type 
                                    ,lookup_code AS lv_ref_code 
                                    ,meaning     AS lv_ref_name                                 
                                    ,NULL        AS lv_pt_ref_type     
                                    ,NULL        AS lv_pt_ref_code
                              FROM  fnd_lookup_values
                              WHERE language = cv_language_ja
                              AND   lookup_type = 'XXCSO1_WK_REQ_FLG'
                              AND   enabled_flag = cv_y_flag
                              ORDER BY lookup_code;

      req_code_rec req_code_cur%ROWTYPE;
     
    BEGIN

      OPEN req_code_cur;

        << req_code_loop >>
        LOOP

          FETCH req_code_cur INTO req_code_rec;
          EXIT WHEN req_code_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               req_code_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,req_code_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,req_code_rec.lv_ref_name     -- ����
              ,req_code_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,req_code_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE req_code_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSO1_WK_REQ_FLG');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-77.���[�X�敪�擾
    DECLARE

      CURSOR req_code_cur IS
                              SELECT 
                                     lookup_type AS lv_ref_type 
                                    ,lookup_code AS lv_ref_code 
                                    ,meaning     AS lv_ref_name                                 
                                    ,NULL        AS lv_pt_ref_type     
                                    ,NULL        AS lv_pt_ref_code
                              FROM  fnd_lookup_values
                              WHERE language = cv_language_ja
                              AND   lookup_type = 'XXCSO1_LEASE_KBN'
                              AND   enabled_flag = cv_y_flag
                              ORDER BY lookup_code;

      req_code_rec req_code_cur%ROWTYPE;
     
    BEGIN

      OPEN req_code_cur;

        << req_code_loop >>
        LOOP

          FETCH req_code_cur INTO req_code_rec;
          EXIT WHEN req_code_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               req_code_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,req_code_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,req_code_rec.lv_ref_name     -- ����
              ,req_code_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,req_code_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE req_code_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSO1_LEASE_KBN');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    -- ===============================
    -- 2.�i�ڃJ�e�S���̎擾
    -- =============================== 
    DECLARE

      CURSOR hinmoku_cat_cur IS
                                 SELECT
                                        DECODE(mtl_set_tl.category_set_name
                                              ,'����Q�R�[�h'
                                              ,'CATEGORY_SEISAKUGUN'
                                              ,'���i���i�敪' 
                                              ,'CATEGORY_SYOHIN_KBN'
                                        )                  AS lv_ref_type
                                       ,mtl_b.segment1     AS lv_ref_code
                                       ,mtl_tl.description AS lv_ref_name
                                       ,NULL               AS lv_pt_ref_type       
                                       ,NULL               AS lv_pt_ref_code
                                FROM   mtl_categories_b mtl_b           
                                      ,mtl_category_sets_b mtl_set
                                      ,mtl_category_sets_tl mtl_set_tl
                                      ,mtl_categories_tl mtl_tl
                                WHERE mtl_set_tl.category_set_id = mtl_set.category_set_id
                                AND   mtl_set.structure_id = mtl_b.structure_id
                                AND   mtl_tl.category_id = mtl_b.category_id
                                AND   mtl_set_tl.language = cv_language_ja
                                AND   mtl_tl.language = cv_language_ja
                                AND   mtl_set_tl.category_set_name IN ('����Q�R�[�h', '���i���i�敪')
                                ORDER BY mtl_set_tl.category_set_name
-- 2009/04/02 Ver1.2 modify start by Yutaka.Kuboshima
--                                        ,mtl_b.attribute1;
                                        ,mtl_b.segment1;
-- 2009/04/02 Ver1.2 modify end by Yutaka.Kuboshima
      hinmoku_cat_rec hinmoku_cat_cur%ROWTYPE;
     
    BEGIN

      OPEN hinmoku_cat_cur;

        << hinmoku_cat_loop >>
        LOOP

          FETCH hinmoku_cat_cur INTO hinmoku_cat_rec;
          EXIT WHEN hinmoku_cat_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               hinmoku_cat_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,hinmoku_cat_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,hinmoku_cat_rec.lv_ref_name     -- ����
              ,hinmoku_cat_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,hinmoku_cat_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE hinmoku_cat_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_mst_data_err_msg,
                                              cv_ng_table,
                                              'MTL_CATEGORIES_B');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    -- ===============================
    -- 3.�x�������}�X�^�̎擾
    -- ===============================
    DECLARE

      CURSOR shiharai_mst_cur IS
                                  SELECT  
                                          'RA_TERMS_TL' AS lv_ref_type
                                         ,name          AS lv_ref_code
                                         ,description   AS lv_ref_name
                                         ,NULL          AS lv_pt_ref_type      
                                         ,NULL          AS lv_pt_ref_code
                                  FROM   ra_terms_tl
                                  WHERE  language = cv_language_ja
-- 2009/04/02 Ver1.2 modify start by Yutaka.Kuboshima
--                                  ORDER BY description;
                                  ORDER BY name;
-- 2009/04/02 Ver1.2 modify end by Yutaka.Kuboshima
      shiharai_mst_rec shiharai_mst_cur%ROWTYPE;

    BEGIN

      OPEN shiharai_mst_cur;

        << shiharai_mst_loop >>
        LOOP

          FETCH shiharai_mst_cur INTO shiharai_mst_rec;
          EXIT WHEN shiharai_mst_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               shiharai_mst_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,shiharai_mst_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,shiharai_mst_rec.lv_ref_name     -- ����
              ,shiharai_mst_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,shiharai_mst_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE shiharai_mst_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_mst_data_err_msg,
                                              cv_ng_table,
                                              'RA_TERM_TL');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    -- ===============================
    -- 4.�`�F�[���X(EDI)�̎擾
    -- ===============================
    DECLARE

      CURSOR edi_chain_cur IS
                               SELECT
                                       'EDI_CHAIN_CODE'      AS lv_ref_type
                                      ,xxcust.edi_chain_code AS lv_ref_code
                                      ,hzcust.account_name   AS lv_ref_name
                                      ,NULL                  AS lv_pt_ref_type
                                      ,NULL                  AS lv_pt_ref_code
                               FROM    xxcmm_cust_accounts xxcust
                                      ,hz_cust_accounts hzcust
                               WHERE  hzcust.cust_account_id = xxcust.customer_id
                               AND    hzcust.customer_class_code = '18'
                               AND    xxcust.edi_chain_code IS NOT NULL
                               ORDER BY xxcust.edi_chain_code;

      edi_chain_rec edi_chain_cur%ROWTYPE;

    BEGIN

      OPEN edi_chain_cur;

        << edi_chain_loop >>
        LOOP

          FETCH edi_chain_cur INTO edi_chain_rec;
          EXIT WHEN edi_chain_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               edi_chain_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,edi_chain_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,edi_chain_rec.lv_ref_name     -- ����
              ,edi_chain_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,edi_chain_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE edi_chain_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_mst_data_err_msg,
                                              cv_ng_table,
                                              'HZ_CUST_ACCOUNTS');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    -- ===============================
    -- 5.�S�ݓX�`��̎擾
    -- ===============================
    DECLARE

      CURSOR depart_cur IS
                            SELECT 
                                   'HYAKKATENDENKU_CODE'          AS  lv_ref_type
                                  ,cmm_cust.parnt_dept_shop_code  AS  lv_ref_code
                                  ,hz_cust.ACCOUNT_NAME           AS  lv_ref_name
                                  ,NULL                           AS  lv_pt_ref_type
                                  ,NULL                           AS  lv_pt_ref_code
                            FROM   hz_cust_accounts  hz_cust
                                  ,xxcmm_cust_accounts cmm_cust
                            WHERE hz_cust.CUST_ACCOUNT_ID = cmm_cust.CUSTOMER_ID
                            AND   hz_cust.CUSTOMER_CLASS_CODE = '19'
                            AND   cmm_cust.parnt_dept_shop_code IS NOT NULL
                            ORDER BY cmm_cust.parnt_dept_shop_code;

      depart_rec depart_cur%ROWTYPE;

    BEGIN

      OPEN depart_cur;

        << depart_loop >>
        LOOP

          FETCH depart_cur INTO depart_rec;
          EXIT WHEN depart_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               depart_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,depart_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,depart_rec.lv_ref_name     -- ����
              ,depart_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,depart_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE depart_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_mst_data_err_msg,
                                              cv_ng_table,
                                              'HYAKKATENDENKU_CODE');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    -- ===============================
    -- 6.OPM�ۊǏꏊ�}�X�^���擾
    -- ===============================
    DECLARE

      CURSOR opm_loc_cur IS
-- 2009/04/03 Ver1.2 modify start by Yutaka.Kuboshima
--                             SELECT  
--                                    'MTL_ITEM_LOCATIONS'   AS lv_ref_type 
--                                   ,inventory_location_id  AS lv_ref_code
--                                   ,description            AS lv_ref_name
--                                   ,NULL                   AS lv_pt_ref_type
--                                   ,NULL                   AS lv_pt_ref_code
--                            FROM   mtl_item_locations
--                            ORDER BY inventory_location_id;
                             SELECT  
                                    'IC_WHSE_MST'          AS lv_ref_type 
                                   ,whse_code              AS lv_ref_code
                                   ,whse_name              AS lv_ref_name
                                   ,NULL                   AS lv_pt_ref_type
                                   ,NULL                   AS lv_pt_ref_code
                            FROM   ic_whse_mst
                            ORDER BY whse_code;
-- 2009/04/03 Ver1.2 modify end by Yutaka.Kuboshima

      opm_loc_rec opm_loc_cur%ROWTYPE;

    BEGIN

      OPEN opm_loc_cur;

        << opm_loc_loop >>
        LOOP

          FETCH opm_loc_cur INTO opm_loc_rec;
          EXIT WHEN opm_loc_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               opm_loc_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,opm_loc_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,opm_loc_rec.lv_ref_name     -- ����
              ,opm_loc_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,opm_loc_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE opm_loc_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_mst_data_err_msg,
                                              cv_ng_table,
                                              'MTL_ITEM_LOCATIONS');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    -- ===============================
    -- 7.�d����}�X�^�擾
    -- ===============================
    DECLARE

      CURSOR vendor_cur IS
                            SELECT  
                                    'PO_VENDORS'  AS lv_ref_type 
-- 2009/04/02 Ver1.2 modify start by Yutaka.Kuboshima
--                                   ,vendor_id     AS lv_ref_code  
                                   ,segment1      AS lv_ref_code  
-- 2009/04/02 Ver1.2 modify end by Yutaka.Kuboshima
                                   ,vendor_name   AS lv_ref_name
                                   ,NULL          AS lv_pt_ref_type  
                                   ,NULL          AS lv_pt_ref_code
                            FROM   po_vendors
-- 2009/04/02 Ver1.2 modify start by Yutaka.Kuboshima
--                            ORDER BY vendor_id;
                            ORDER BY segment1;
-- 2009/04/02 Ver1.2 modify end by Yutaka.Kuboshima

      vendor_rec vendor_cur%ROWTYPE;

    BEGIN

      OPEN vendor_cur;

        << vendor_loop >>
        LOOP

          FETCH vendor_cur INTO vendor_rec;
          EXIT WHEN vendor_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               vendor_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,vendor_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,vendor_rec.lv_ref_name     -- ����
              ,vendor_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,vendor_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE vendor_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_mst_data_err_msg,
                                              cv_ng_table,
                                              'PO_VEDORS');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    -- ===============================
    -- 8.�ŋ��}�X�^�擾
    -- ===============================
    DECLARE

      CURSOR tax_cur IS
                         SELECT
                                'AR_VAT_TAX_ALL_B'  AS lv_ref_type 
                               ,tax_code            AS lv_ref_code
                               ,description         AS lv_ref_name
                               ,NULL                AS lv_pt_ref_type
                               ,NULL  AS lv_pt_ref_code
                        FROM   ar_vat_tax_all_b
                        WHERE  enabled_flag = cv_y_flag
-- 2009/04/02 Ver1.2 add start by Yutaka.Kuboshima
                        AND    gd_process_date BETWEEN start_date AND NVL(end_date, TO_DATE(cv_max_date, cv_date_format))
-- 2009/04/02 Ver1.2 add end by Yutaka.Kuboshima
                        ORDER BY tax_code;

      tax_rec tax_cur%ROWTYPE;

    BEGIN

      OPEN tax_cur;

        << tax_loop >>
        LOOP

          FETCH tax_cur INTO tax_rec;
          EXIT WHEN tax_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               tax_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,tax_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,tax_rec.lv_ref_name     -- ����
              ,tax_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,tax_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE tax_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_mst_data_err_msg,
                                              cv_ng_table,
                                              'AR_VAT_TAX_ALL_B');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    -- ===============================
    -- 9.AFF����Ȗڎ擾
    -- ===============================
    DECLARE

      CURSOR aff_kamoku_cur IS
                                SELECT 
                                       fndsets.flex_value_set_name  AS lv_ref_type 
                                      ,fnd.flex_value               AS lv_ref_code
                                      ,fndtl.description            AS lv_ref_name
                                      ,NULL                         AS lv_pt_ref_type  
                                      ,NULL                         AS lv_pt_ref_code
                                FROM   fnd_flex_value_sets fndsets
                                      ,fnd_flex_values fnd 
                                      ,fnd_flex_values_tl fndtl
                                WHERE fnd.flex_value_set_id = fndsets.flex_value_set_id
                                AND   fndtl.flex_value_id = fnd.flex_value_id
                                AND   fndtl.language = cv_language_ja
                                AND   fnd.enabled_flag = cv_y_flag
                                AND   fndsets.flex_value_set_name = 'XX03_ACCOUNT'
                                ORDER BY fnd.flex_value;
                        
      aff_kamoku_rec aff_kamoku_cur%ROWTYPE;

    BEGIN

      OPEN aff_kamoku_cur;

        << aff_kamoku_loop >>
        LOOP

          FETCH aff_kamoku_cur INTO aff_kamoku_rec;
          EXIT WHEN aff_kamoku_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               aff_kamoku_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,aff_kamoku_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,aff_kamoku_rec.lv_ref_name     -- ����
              ,aff_kamoku_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,aff_kamoku_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE aff_kamoku_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_mst_data_err_msg,
                                              cv_ng_table,
                                              'AFF����Ȗ�');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    -- ===============================
    -- 10.AFF����/���ގ擾
    -- ===============================
    DECLARE

      CURSOR aff_meisai_cur IS
                                SELECT
                                       DISTINCT fndsets.flex_value_set_name  AS lv_ref_type 
                                      ,fnd.flex_value     AS lv_ref_code
                                      ,fndtl.description  AS lv_ref_name
                                      ,'XX03_ACCOUNT'     AS lv_pt_ref_type  
                                      ,fnd.parent_flex_value_low  AS lv_pt_ref_code
                                FROM    fnd_flex_value_sets fndsets
                                      ,fnd_flex_values fnd
                                      ,fnd_flex_values_tl fndtl
                                WHERE fnd.flex_value_set_id = fndsets.flex_value_set_id
                                AND   fndtl.flex_value_id = fnd.flex_value_id
                                AND   fndtl.language = cv_language_ja  
                                AND   fnd.enabled_flag = cv_y_flag
                                AND   fndsets.flex_value_set_name = 'XX03_SUB_ACCOUNT'
                                ORDER BY fnd.flex_value;
                        
      aff_meisai_rec aff_meisai_cur%ROWTYPE;

    BEGIN

      OPEN aff_meisai_cur;

        << aff_meisai_loop >>
        LOOP

          FETCH aff_meisai_cur INTO aff_meisai_rec;
          EXIT WHEN aff_meisai_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               aff_meisai_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,aff_meisai_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,aff_meisai_rec.lv_ref_name     -- ����
              ,aff_meisai_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,aff_meisai_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE aff_meisai_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_mst_data_err_msg,
                                              cv_ng_table,
                                              'AFF����/����');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    -- ===============================
    -- 11.�ʏ�E���ѐU�֋敪�̎擾
    -- ===============================
    DECLARE

      CURSOR furikae_kbn_cur IS
                                 SELECT 
                                        fndsets.flex_value_set_name  AS lv_ref_type 
                                       ,fnd.flex_value               AS lv_ref_code
                                       ,fndtl.description            AS lv_ref_name
                                       ,NULL                         AS lv_pt_ref_type  
                                       ,NULL                         AS lv_pt_ref_code
                                 FROM   fnd_flex_value_sets fndsets
                                       ,fnd_flex_values fnd
                                       ,fnd_flex_values_tl fndtl
                                 WHERE fnd.flex_value_set_id = fndsets.flex_value_set_id
                                 AND   fndtl.flex_value_id = fnd.flex_value_id
                                 AND   fndtl.language = cv_language_ja  
                                 AND   fnd.enabled_flag = cv_y_flag
                                 AND   fndsets.flex_value_set_name = 'XXCFO1_NORM_TRNSFER_TYPE'
                                 ORDER BY fnd.flex_value;
                        
      furikae_kbn_rec furikae_kbn_cur%ROWTYPE;

    BEGIN

      OPEN furikae_kbn_cur;

        << furikae_kbn_loop >>
        LOOP

          FETCH furikae_kbn_cur INTO furikae_kbn_rec;
          EXIT WHEN furikae_kbn_cur%NOTFOUND;

            -- �t�@�C���o��
            write_csv(
               furikae_kbn_rec.lv_ref_type     -- �Q�ƃ^�C�v
              ,furikae_kbn_rec.lv_ref_code     -- �Q�ƃR�[�h
              ,furikae_kbn_rec.lv_ref_name     -- ����
              ,furikae_kbn_rec.lv_pt_ref_type  -- �e�Q�ƃ^�C�v
              ,furikae_kbn_rec.lv_pt_ref_code  -- �e�Q�ƃR�[�h
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --�J�[�\���J�E���g
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE furikae_kbn_cur;

      --�Q�ƃR�[�h�擾�G���[
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_mst_data_err_msg,
                                              cv_ng_table,
                                              '�ʏ���сE�U�֋敪');
        ov_retcode := cv_status_warn;

        --�x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --�x���J�E���g�A�b�v
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --�o�͌����J�E���g
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --�o�͌����J�E���g���O���[�o���ϐ���
    gn_target_cnt := ln_output_cnt;
    gn_warn_cnt := ln_warn_cnt;
    gn_normal_cnt := ln_output_cnt;

--
  EXCEPTION
    WHEN write_failure_expt THEN                       --*** CSV�f�[�^�o�̓G���[ ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      --CSV�f�[�^�o�̓G���[���A�Ώی����A�x�������ƁA�G���[������1���Œ�Ƃ���
      gn_target_cnt := 1;
      gn_warn_cnt := 1;
      gn_error_cnt  := 1;
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
  END output_mst_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf                 OUT VARCHAR2,     --�G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                OUT VARCHAR2,     --���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                 OUT VARCHAR2)     --���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lf_file_handler   UTL_FILE.FILE_TYPE;  --�t�@�C���n���h��
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
    gn_warn_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    -- ===============================
    -- ��������(A-1)
    -- ===============================
    init(
       lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    --���������G���[���͏����𒆒f
    IF (lv_retcode = cv_status_error) THEN
      --�G���[����
      RAISE global_process_expt;
    END IF;
    -- ===============================
    -- �R���J�����g���b�Z�[�W�o��
    -- ===============================
    --IF�t�@�C�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                  iv_application  => gv_xxccp_msg_kbn
                 ,iv_name         => cv_file_name_msg
                 ,iv_token_name1  => cv_tkn_filename
                 ,iv_token_value1 => gv_out_file_file
                );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -- ===============================
    -- �t�@�C���I�[�v������(A-2)
    -- ===============================
    file_open(
       lf_file_handler    -- �t�@�C���n���h��
      ,lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --�G���[����
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �����Ώۃf�[�^���o����(A-3)�E���o���o�͏���(A-4)
    -- ===============================
    output_mst_data(
       lf_file_handler         -- �t�@�C���n���h��
      ,lv_errbuf               -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode              -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- ===============================
    -- �I������(A-5)
    -- ===============================
    BEGIN

      --�t�@�C���N���[�Y����
      IF (UTL_FILE.IS_OPEN(lf_file_handler)) THEN
        --�t�@�C���N���[�Y
        UTL_FILE.FCLOSE(lf_file_handler);
      END IF;

    EXCEPTION

     WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_file_close_err_msg,
                                              cv_sqlerrm,
                                              SQLERRM);
        lv_errbuf := lv_errmsg;
        --�t�@�C���N���[�Y�G���[����
        RAISE fclose_err_expt;

    END;
    
    IF (lv_retcode = cv_status_warn) THEN
      ov_retcode := cv_status_warn;
    ELSIF (lv_retcode = cv_status_error) THEN
      --�G���[����
      RAISE global_process_expt;
    END IF;

--
  EXCEPTION
    WHEN fclose_err_expt THEN                         --*** �t�@�C���N���[�Y�G���[ ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;  
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
    errbuf                    OUT VARCHAR2,     --�G���[�E���b�Z�[�W  --# �Œ� #
    retcode                   OUT VARCHAR2      --���^�[���E�R�[�h    --# �Œ� #
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
       lv_errbuf                 --�G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode                --���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg                 --���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
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
    --�x�������o��
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
END xxcmm003a36c;
/
