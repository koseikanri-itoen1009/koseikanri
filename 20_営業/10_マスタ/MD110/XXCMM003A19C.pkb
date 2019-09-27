CREATE OR REPLACE PACKAGE BODY APPS.XXCMM003A19C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2009. All rights reserved.
 *
 * Package Name     : XXCMM003A19C(body)
 * Description      : HHT�A�gIF�f�[�^�쐬
 * MD.050           : MD050_CMM_003_A19_HHT�n�A�gIF�f�[�^�쐬
 * Version          : 1.15
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  file_open              �t�@�C���I�[�v������(A-2)
 *  output_cust_data       �����Ώۃf�[�^���o����(A-3)�E���o���o�͏���(A-4)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��(A-5 �I������)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/02/24    1.0   Takuya Kaihara   �V�K�쐬
 *  2009/03/09    1.1   Takuya Kaihara   �v���t�@�C���l���ʉ�
 *  2009/04/13    1.2   Yutaka.Kuboshima ��QT1_0499,T1_0509�̑Ή�
 *  2009/04/28    1.3   Yutaka.Kuboshima ��QT1_0831�̑Ή�
 *  2009/06/09    1.4   Yutaka.Kuboshima ��QT1_1364�̑Ή�
 *  2009/08/24    1.5   Yutaka.Kuboshima �����e�X�g��Q0000487�̑Ή�
 *  2009/11/23    1.6   Yutaka.Kuboshima ��QE_�{��_00329�̑Ή�
 *  2009/12/06    1.7   Yutaka.Kuboshima ��QE_�{�ғ�_00327�̑Ή�
 *  2009/12/09    1.8   Yutaka.Kuboshima ��QE_�{�ғ�_00371�̑Ή�
 *  2011/03/07    1.9   Naoki.Horigome   ��QE_�{�ғ�_05329�̑Ή�
 *  2011/05/16    1.10  Shigeto.Niki     ��QE_�{�ғ�_07429�̑Ή�
 *  2011/10/18    1.11  Yasuhiro.Horikawa ��QE_�{�ғ�_08440�̑Ή�
 *  2013/07/25    1.12  Shigeto.Niki     ��QE_�{�ғ�_10904�̑Ή�(����ő��őΉ�)
 *  2013/09/18    1.12  Shigeto.Niki     ��QE_�{�ғ�_10904�̍đΉ�(����ő��őΉ�)
 *  2017/08/29    1.13  Shigeto.Niki     ��QE_�{�ғ�_14486�̑Ή�
 *  2019/07/30    1.14  N.Koyama         ��QE_�{�ғ�_15472�̒ǉ��Ή�
 *  2019/09/26    1.15  N.Koyama         ��QE_�{�ғ�_15949�̑Ή�
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
  no_date_expt                   EXCEPTION; --�Ώۃf�[�^0��
  fclose_err_expt                EXCEPTION; --�t�@�C���N���[�Y�G���[
  write_failure_expt             EXCEPTION; --CSV�f�[�^�o�̓G���[
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                CONSTANT VARCHAR2(12)  := 'XXCMM003A19C';                 --�p�b�P�[�W��
  cv_comma                   CONSTANT VARCHAR2(2)   := ',';
  cv_dqu                     CONSTANT VARCHAR2(2)   := '"';                            --�����񊇂�
  cv_date_null               CONSTANT VARCHAR2(2)   := '';                             --�󕶎�
  cv_hur_sps                 CONSTANT VARCHAR2(2)   := ' ';                            --���p�X�y�[�X
  cv_hur_sls                 CONSTANT VARCHAR2(2)   := '/';                            --���p�X���b�V��
--
  cv_fnd_month               CONSTANT VARCHAR2(10)  := 'YYYYMM';                       --���t����(MONTH)
  cv_fnd_date                CONSTANT VARCHAR2(10)  := 'YYYYMMDD';                     --���t����
  cv_fnd_slash_date          CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';                   --���t����(YYYY/MM/DD)
  cv_fnd_sytem_date          CONSTANT VARCHAR2(25)  := 'YYYY/MM/DD HH24:MI:SS';        --�V�X�e�����t
-- 2009/08/24 Ver1.5 add start by Yutaka.Kuboshima
  cv_fnd_max_date            CONSTANT VARCHAR2(20)  := 'YYYYMMDDHH24MISS';             --���t����(�N���������b)
-- 2009/08/24 Ver1.5 add end by Yutaka.Kuboshima
  cv_trunc_dd                CONSTANT VARCHAR2(2)   := 'DD';                           --���t����(DD)
  cv_trunc_mm                CONSTANT VARCHAR2(2)   := 'MM';                           --���t����(MM)
  cv_proc_date_from          CONSTANT VARCHAR2(50)  := '�ŏI�X�V���i�J�n�j';           --�ŏI�X�V���i�J�n�j
  cv_proc_date_to            CONSTANT VARCHAR2(50)  := '�ŏI�X�V���i�I���j';           --�ŏI�X�V���i�I���j
--
  --���b�Z�[�W
  cv_file_name_msg           CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-05102';             --�t�@�C�����m�[�g
  cv_parameter_msg           CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00038';             --���̓p�����[�^�m�[�g
  cv_no_data_msg             CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00301';             --�Ώۃf�[�^����
--
  --�G���[���b�Z�[�W
  cv_profile_err_msg         CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00002';             --�v���t�@�C���擾�G���[
  cv_file_path_invalid_msg   CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00003';             --�t�@�C���p�X�s���G���[
  cv_write_err_msg           CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00009';             --CSV�f�[�^�o�̓G���[
-- 2009/04/13 Ver1.2 add start by Yutaka.Kuboshima
  cv_exist_err_msg           CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00010';             --CSV�t�@�C�����݃`�F�b�N
-- 2009/04/13 Ver1.2 add end by Yutaka.Kuboshima
  cv_emsg_file_close         CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00489';             --�t�@�C���N���[�Y�G���[
  cv_term_spec_msg           CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00343';             --���Ԏw��G���[
  --�g�[�N��
  cv_ng_profile              CONSTANT VARCHAR2(10)  := 'NG_PROFILE';                   --�v���t�@�C���擾���s�g�[�N��
  cv_file_name               CONSTANT VARCHAR2(10)  := 'FILE_NAME';                    --�t�@�C�����g�[�N��
  cv_ng_word                 CONSTANT VARCHAR2(7)   := 'NG_WORD';                      --CSV�o�̓G���[�g�[�N���ENG_WORD
  cv_ng_data                 CONSTANT VARCHAR2(7)   := 'NG_DATA';                      --CSV�o�̓G���[�g�[�N���ENG_DATA
  cv_param                   CONSTANT VARCHAR2(5)   := 'PARAM';                        --�p�����[�^�g�[�N��
  cv_value                   CONSTANT VARCHAR2(5)   := 'VALUE';                        --�p�����[�^�l�g�[�N��
  cv_sqlerrm                 CONSTANT VARCHAR2(10)  := 'SQLERRM';                      --�l�g�[�N��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_process_date     VARCHAR2(20);          --�Ɩ����t
-- 2009/08/24 Ver1.5 add start by Yutaka.Kuboshima
  gd_process_date     DATE;                  --�Ɩ����t
-- 2009/08/24 Ver1.5 add end by Yutaka.Kuboshima
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_proc_date_from  IN  VARCHAR2,     --   �R���J�����g�E�p�����[�^������(FROM)
    iv_proc_date_to    IN  VARCHAR2,     --   �R���J�����g�E�p�����[�^������(TO)
    ov_errbuf          OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    cv_out_file_dir  CONSTANT VARCHAR2(30) := 'XXCMM1_HHT_OUT_DIR';           --XXCMM:HHT(OUTBOUND)�A�g�pCSV�t�@�C���o�͐�
    cv_out_file_file CONSTANT VARCHAR2(30) := 'XXCMM1_003A19_OUT_FILE_FIL';   --XXCMM: HHT�n�A�gIF�f�[�^�쐬�pCSV�t�@�C����
    cv_invalid_path  CONSTANT VARCHAR2(25) := 'CSV�o�̓f�B���N�g��';          --�v���t�@�C���擾���s�i�f�B���N�g���j
    cv_invalid_name  CONSTANT VARCHAR2(20) := 'CSV�o�̓t�@�C����';            --�v���t�@�C���擾���s�i�t�@�C�����j
--
    -- *** ���[�J���ϐ� ***
-- 2009/04/13 Ver1.2 add start by Yutaka.Kuboshima
    lv_file_chk     BOOLEAN;
    ln_file_size    NUMBER;
    ln_block_size   NUMBER;
-- 2009/4/13 Ver1.2 add end by Yutaka.Kuboshima
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
-- 2009/04/13 Ver1.2 add start by Yutaka.Kuboshima
    -- �t�@�C�����݃`�F�b�N
    UTL_FILE.FGETATTR(gv_out_file_dir, gv_out_file_file, lv_file_chk, ln_file_size, ln_block_size);
    IF (lv_file_chk) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                            cv_exist_err_msg);
      lv_errbuf := lv_errmsg;
      RAISE init_err_expt;
    END IF;
-- 2009/4/13 Ver1.2 add end by Yutaka.Kuboshima
--
    -- �Ɩ����t�擾����
    gv_process_date := TO_CHAR(xxccp_common_pkg2.get_process_date, cv_fnd_date);
-- 2009/08/24 Ver1.5 add start by Yutaka.Kuboshima
    gd_process_date := TO_DATE(gv_process_date, cv_fnd_date);
-- 2009/08/24 Ver1.5 add end by Yutaka.Kuboshima
--
    -- �p�����[�^�`�F�b�N
    IF ( NVL(REPLACE(iv_proc_date_from, cv_hur_sls, cv_date_null), gv_process_date) > NVL(REPLACE(iv_proc_date_to, cv_hur_sls, cv_date_null), gv_process_date) ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                            cv_term_spec_msg);
      lv_errbuf := lv_errmsg;
      RAISE init_err_expt;
    END IF;
  EXCEPTION
    WHEN init_err_expt THEN                           --*** ����������O ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      --����������O���A�Ώی����A�G���[������0���Œ�Ƃ���
      gn_target_cnt := 0;
      gn_error_cnt  := 0;
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
        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
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
      --�t�@�C���I�[�v���G���[���A�Ώی����A�G���[������0���Œ�Ƃ���
      gn_target_cnt := 0;
      gn_error_cnt  := 0;
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
   * Procedure Name   : output_cust_data
   * Description      : �����Ώۃf�[�^���o����(A-3)�E���o���o�͏���(A-4)
   ***********************************************************************************/
  PROCEDURE output_cust_data(
    iv_proc_date_from       IN  VARCHAR2,               --   �R���J�����g�E�p�����[�^������(FROM)
    iv_proc_date_to         IN  VARCHAR2,               --   �R���J�����g�E�p�����[�^������(TO)
    io_file_handler         IN  UTL_FILE.FILE_TYPE,     --   �t�@�C���n���h��
    ov_errbuf               OUT VARCHAR2,               --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode              OUT VARCHAR2,               --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg               OUT VARCHAR2)               --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'output_cust_data'; -- �v���O������
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
--
    --*** ���[�J���萔 ***
    cv_eff_last_date      CONSTANT VARCHAR2(15)     := '99991231';                --�L����_��
    cv_language_ja        CONSTANT VARCHAR2(2)      := 'JA';                      --����(���{��)
    cv_enabled_flag       CONSTANT VARCHAR2(1)      := 'Y';                       --�g�p�\�t���O
    cv_a_flag             CONSTANT VARCHAR2(1)      := 'A';                       --�L���t���O
    cv_gyotai_syo         CONSTANT VARCHAR2(25)     := 'XXCMM_CUST_GYOTAI_SHO';   --�Ƒԕ���(������)
    cv_hht_syohi          CONSTANT VARCHAR2(30)     := 'XXCOS1_CONSUMPTION_TAX_CLASS'; --HHT����ŋ敪
    cv_bill_to            CONSTANT VARCHAR2(7)      := 'BILL_TO';                 --�g�p�ړI�E������
    cv_other_to           CONSTANT VARCHAR2(8)      := 'OTHER_TO';                --�g�p�ړI�E�o�א�
-- 2009/04/13 Ver1.2 add start by Yutaka.Kuboshima
    cv_base               CONSTANT VARCHAR2(2)      := '1';                       --�ڋq�敪(���_)
-- 2009/04/13 Ver1.2 add end by Yutaka.Kuboshima
    cv_cust_cd            CONSTANT VARCHAR2(2)      := '10';                      --�ڋq�敪(�ڋq)
    cv_ucust_cd           CONSTANT VARCHAR2(2)      := '12';                      --�ڋq�敪(��l�ڋq)
    cv_round_cd           CONSTANT VARCHAR2(2)      := '15';                      --�ڋq�敪(�X�܉c��)
    cv_plan_cd            CONSTANT VARCHAR2(2)      := '17';                      --�ڋq�敪(�v�旧�ėp)
    cv_mc_sts             CONSTANT VARCHAR2(2)      := '20';                      --�ڋq�X�e�[�^�X(MC)
    cv_vd_24              CONSTANT VARCHAR2(2)      := '24';                      --�t���T�[�r�X(����)VD
    cv_vd_25              CONSTANT VARCHAR2(2)      := '25';                      --�t���T�[�r�XVD
    cv_vd_26              CONSTANT VARCHAR2(2)      := '26';                      --�[�iVD
    cv_in_21              CONSTANT VARCHAR2(2)      := '21';                      --�C���V���b�v
    cv_vd_27              CONSTANT VARCHAR2(2)      := '27';                      --����VD
    cv_vd_11              CONSTANT VARCHAR2(2)      := '11';                      --VD
    cv_pay_tm             CONSTANT VARCHAR2(8)      := '00_00_00';                --�x������
    cv_oj_party           CONSTANT VARCHAR2(5)      := 'PARTY';                   --�m�[�g�E�R�[�h
-- 2009/04/13 Ver1.2 add start by Yutaka.Kuboshima
    cv_dept_div_mult      CONSTANT VARCHAR2(2)      := '1';                       --�S�ݓXHHT�敪(���_��)
-- 2009/04/13 Ver1.2 add end by Yutaka.Kuboshima
--
    cv_cdvd_code          CONSTANT VARCHAR2(1)      := '0';                       --�J�[�h�x���_�敪
    cv_null_code          CONSTANT VARCHAR2(1)      := '0';                       --HHT����(NULL)
    cv_zr_sts             CONSTANT VARCHAR2(1)      := '0';                       --�X�e�[�^�X�u0�v
    cv_on_sts             CONSTANT VARCHAR2(1)      := '1';                       --�X�e�[�^�X�u1�v
    cv_tw_sts             CONSTANT VARCHAR2(1)      := '2';                       --�X�e�[�^�X�u2�v
    cv_th_sts             CONSTANT VARCHAR2(1)      := '3';                       --�X�e�[�^�X�u3�v
    cv_err_cust_code_msg  CONSTANT VARCHAR2(20)     := '�ڋq�R�[�h';              --CSV�o�̓G���[������
    cn_note_lenb          CONSTANT NUMBER           := 2000;                      --�m�[�g����l
    cv_ver_line           CONSTANT VARCHAR2(1)      := '|';                       --�c�_
    cv_null_sts           CONSTANT VARCHAR2(1)      := NULL;                      --NULL�f�[�^
--
-- 2009/06/09 Ver1.4 add start by Yutaka.Kuboshima
    cv_single_byte_err1   CONSTANT VARCHAR2(30)    := '�ݶ��װ';                --���p�G���[���̃_�~�[�l1
    cv_single_byte_err2   CONSTANT VARCHAR2(30)    := '99-9999-9999';           --���p�G���[���̃_�~�[�l2
-- 2009/06/09 Ver1.4 add end by Yutaka.Kuboshima
--
-- 2009/08/24 Ver1.5 add start by Yutaka.Kuboshima
    cv_min_time           CONSTANT VARCHAR2(7)      := '000000';                  --�����b�ŏ�
    cv_max_time           CONSTANT VARCHAR2(7)      := '235959';                  --�����b�ő�
-- 2009/08/24 Ver1.5 add end by Yutaka.Kuboshima
    -- *** ���[�J���ϐ� ***
    lv_output_str                  VARCHAR2(4095)   := NULL;                      --�o�͕�����i�[�p�ϐ�
    ln_output_cnt                  NUMBER           := 0;                         --�o�͌���
    lv_coordinated_date            VARCHAR2(30)     := NULL;                      --�A�g���t�擾
    lv_note_work                   VARCHAR2(5000)   := NULL;                      --�m�[�g��Ɨp�ϐ�
    lv_note_str                    VARCHAR2(5000)   := NULL;                      --�m�[�g
--
-- 2009/06/09 Ver1.4 add start by Yutaka.Kuboshima
    lv_customer_name               VARCHAR2(1500);                              --�ڋq����
    lv_customer_name_kana          VARCHAR2(1500);                              --�ڋq���J�i
    lv_address1                    VARCHAR2(1500);                              --�Z���P
    lv_address_lines_phonetic      VARCHAR2(1500);                              --�d�b�ԍ�
-- 2009/06/09 Ver1.4 add end by Yutaka.Kuboshima
--
-- 2009/08/24 Ver1.5 add start by Yutaka.Kuboshima
    ld_proc_date_from              DATE;                                        --�p�����[�^������(FROM)
    ld_proc_date_to                DATE;                                        --�p�����[�^������(TO)
    ld_process_date_next_f         DATE;                                        --���Ɩ����P��
    ld_process_date_next_l         DATE;                                        --���Ɩ����ŏI��
-- 2009/08/24 Ver1.5 add end by Yutaka.Kuboshima
-- Ver1.15 add Start
    lt_tax_rounding_rule    xxcos_cust_hierarchy_v.bill_tax_round_rule%TYPE;
-- Ver1.15 add End
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
-- 2009/08/24 Ver1.5 add start by Yutaka.Kuboshima
    -- �����A�g�Ώیڋq�擾�J�[�\��
    CURSOR def_cust_cur(p_proc_date_from IN DATE,
                        p_proc_date_to   IN DATE)
    IS
      SELECT /*+ FIRST_ROWS INDEX(hca hz_cust_accounts_u1) */
             hca.cust_account_id customer_id
      FROM   hz_cust_accounts hca
            ,( -- �ڋq�}�X�^
               SELECT hca1.cust_account_id customer_id
               FROM   hz_cust_accounts hca1
-- 2009/12/07 Ver1.8 E_�{�ғ�_00371 modify start by Yutaka.Kuboshima
--               WHERE  hca1.last_update_date BETWEEN p_proc_date_from AND p_proc_date_to
               WHERE  hca1.last_update_date BETWEEN p_proc_date_from AND p_proc_date_to + 1
-- 2009/12/07 Ver1.8 E_�{�ғ�_00371 modify start by Yutaka.Kuboshima
               UNION
               -- �ڋq�ǉ����}�X�^
               SELECT xca2.customer_id customer_id
               FROM   xxcmm_cust_accounts xca2
-- 2009/12/07 Ver1.8 E_�{�ғ�_00371 modify start by Yutaka.Kuboshima
--               WHERE  xca2.last_update_date BETWEEN p_proc_date_from AND p_proc_date_to
               WHERE  xca2.last_update_date BETWEEN p_proc_date_from AND p_proc_date_to + 1
-- 2009/12/07 Ver1.8 E_�{�ғ�_00371 modify start by Yutaka.Kuboshima
               UNION
               -- �p�[�e�B�}�X�^
               SELECT /*+ INDEX(hca3 hz_cust_accounts_n2) */
                      hca3.cust_account_id customer_id
               FROM   hz_cust_accounts hca3
                     ,hz_parties hp3
               WHERE  hca3.party_id = hp3.party_id
-- 2009/12/07 Ver1.8 E_�{�ғ�_00371 modify start by Yutaka.Kuboshima
--                 AND  hp3.last_update_date BETWEEN p_proc_date_from AND p_proc_date_to
                 AND  hp3.last_update_date BETWEEN p_proc_date_from AND p_proc_date_to + 1
-- 2009/12/07 Ver1.8 E_�{�ғ�_00371 modify start by Yutaka.Kuboshima
               UNION
               -- �ڋq�g�p�ړI�}�X�^
               SELECT hcas4.cust_account_id customer_id
               FROM   hz_cust_acct_sites hcas4
                     ,hz_cust_site_uses  hcsu4
               WHERE  hcas4.cust_acct_site_id = hcsu4.cust_acct_site_id
-- 2009/12/07 Ver1.8 E_�{�ғ�_00371 modify start by Yutaka.Kuboshima
--                 AND  hcsu4.last_update_date BETWEEN p_proc_date_from AND p_proc_date_to
                 AND  hcsu4.last_update_date BETWEEN p_proc_date_from AND p_proc_date_to + 1
-- 2009/12/07 Ver1.8 E_�{�ғ�_00371 modify start by Yutaka.Kuboshima
               UNION
               -- �ڋq���Ə��}�X�^
               SELECT /*+ INDEX(hca5 hz_cust_accounts_n2) */
                      hca5.cust_account_id customer_id
               FROM   hz_cust_accounts hca5
                     ,hz_parties hp5
                     ,hz_party_sites hps5
                     ,hz_locations hl5
               WHERE  hca5.party_id = hp5.party_id
                 AND  hp5.party_id  = hps5.party_id
                 AND  hps5.location_id = hl5.location_id
-- 2009/12/07 Ver1.8 E_�{�ғ�_00371 modify start by Yutaka.Kuboshima
--                 AND  hl5.last_update_date BETWEEN p_proc_date_from AND p_proc_date_to
                 AND  hl5.last_update_date BETWEEN p_proc_date_from AND p_proc_date_to + 1
-- 2009/12/07 Ver1.8 E_�{�ғ�_00371 modify start by Yutaka.Kuboshima
               UNION
               -- �x�������}�X�^
               SELECT /*+ FIRST_ROWS */
                      hcas6.cust_account_id customer_id
               FROM   hz_cust_acct_sites hcas6
                     ,hz_cust_site_uses  hcsu6
                     ,ra_terms           rt6
               WHERE  hcas6.cust_acct_site_id = hcsu6.cust_acct_site_id
                 AND  hcsu6.payment_term_id = rt6.term_id
-- 2009/12/07 Ver1.8 E_�{�ғ�_00371 modify start by Yutaka.Kuboshima
--                 AND  rt6.last_update_date BETWEEN p_proc_date_from AND p_proc_date_to
                 AND  rt6.last_update_date BETWEEN p_proc_date_from AND p_proc_date_to + 1
-- 2009/12/07 Ver1.8 E_�{�ғ�_00371 modify start by Yutaka.Kuboshima
               UNION
               -- �g�D�g���v���t�@�C���}�X�^
               SELECT hca7.cust_account_id customer_id
               FROM   hz_cust_accounts hca7
                     ,hz_parties hp7
                     ,hz_organization_profiles hop7
                     ,hz_org_profiles_ext_vl hopev7
               WHERE  hca7.party_id = hp7.party_id
                 AND  hp7.party_id  = hop7.party_id
                 AND  hop7.organization_profile_id = hopev7.organization_profile_id
-- 2009/12/06 Ver1.7 ��QE_�{�ғ�_00327 add start by Yutaka.Kuboshima
                 AND  hop7.effective_end_date IS NULL
-- 2009/12/06 Ver1.7 ��QE_�{�ғ�_00327 add end by Yutaka.Kuboshima
-- 2009/12/07 Ver1.8 E_�{�ғ�_00371 modify start by Yutaka.Kuboshima
--                 AND  hopev7.last_update_date BETWEEN p_proc_date_from AND p_proc_date_to
                 AND  hopev7.last_update_date BETWEEN p_proc_date_from AND p_proc_date_to + 1
-- 2009/12/07 Ver1.8 E_�{�ғ�_00371 modify start by Yutaka.Kuboshima
-- 2009/12/06 Ver1.7 ��QE_�{�ғ�_00327 add start by Yutaka.Kuboshima
-- �S���c�ƈ��A���[�g�̗L���J�n����
-- �ŏI�X�V��(�J�n) + 1 <= �L���J�n�� <= �ŏI�X�V��(�I��)�̗����t�̏ꍇ���Ώۃf�[�^�Ƃ���悤�ɏC��
               UNION
               -- �S���c�ƈ�
               SELECT hca8.cust_account_id customer_id
               FROM   hz_cust_accounts hca8
                     ,hz_parties hp8
                     ,hz_organization_profiles hop8
                     ,hz_org_profiles_ext_vl hopev8
                     ,ego_resource_agv era8
               WHERE  hca8.party_id = hp8.party_id
                 AND  hp8.party_id  = hop8.party_id
                 AND  hop8.organization_profile_id = hopev8.organization_profile_id
                 AND  hopev8.extension_id = era8.extension_id
                 AND  hop8.effective_end_date IS NULL
                 AND  hopev8.d_ext_attr1 BETWEEN (p_proc_date_from + 1) AND xxccp_common_pkg2.get_working_day(p_proc_date_to, 1)
               UNION
               -- ���[�g
               SELECT hca9.cust_account_id customer_id
               FROM   hz_cust_accounts hca9
                     ,hz_parties hp9
                     ,hz_organization_profiles hop9
                     ,hz_org_profiles_ext_vl hopev9
                     ,ego_route_agv era9
               WHERE  hca9.party_id = hp9.party_id
                 AND  hp9.party_id  = hop9.party_id
                 AND  hop9.organization_profile_id = hopev9.organization_profile_id
                 AND  hopev9.extension_id = era9.extension_id
                 AND  hop9.effective_end_date IS NULL
                 AND  hopev9.d_ext_attr3 BETWEEN (p_proc_date_from + 1) AND xxccp_common_pkg2.get_working_day(p_proc_date_to, 1)
-- 2009/12/06 Ver1.7 ��QE_�{�ғ�_00327 add end by Yutaka.Kuboshima
             ) def
      WHERE  hca.cust_account_id = def.customer_id
      ORDER BY hca.account_number;
--
-- 2009/08/24 Ver1.5 add end by Yutaka.Kuboshima
    -- HHT�A�gIF�f�[�^�쐬�J�[�\��
-- 2009/08/24 Ver1.5 modify start by Yutaka.Kuboshima
-- �Y��SQL��啝���C
-- �����A�g�����ڋq���ɒ��o����l�ɏC��
--    CURSOR cust_data_cur
--    IS
--      SELECT hca.account_number                                          account_number,              --�ڋq�R�[�h
--             hp.party_name                                               party_name,                  --�ڋq����
--             flvctc.lookup_code                                          tax_div,                     --����ŋ敪
--             DECODE( xca.business_low_type, cv_vd_24, cv_on_sts, cv_vd_25, cv_on_sts, cv_vd_26, cv_tw_sts, cv_null_sts, cv_date_null, cv_zr_sts )  vd_contract_form, --�x���_�_��`��
--             DECODE(rt.name, cv_pay_tm, cv_on_sts, cv_null_sts, cv_date_null, cv_th_sts )           mode_div,           --�ԗl�敪
--             xca.final_tran_date                                         final_tran_date,             --�ŏI�����
--             xca.final_call_date                                         final_call_date,             --�ŏI�K���
--             DECODE( xca.business_low_type, cv_in_21, cv_on_sts, cv_vd_27, cv_tw_sts, cv_null_sts, cv_date_null, cv_zr_sts )  entrust_dest_flg, --�a���攻��t���O
--             DECODE( flvgs.attribute1, cv_vd_11, cv_on_sts, cv_null_sts, cv_date_null, cv_zr_sts )  vd_cust_class_cd,   --VD�ڋq�敪
--             hp.duns_number_c                                            duns_number_c,               --�ڋq�X�e�[�^�X�R�[�h
--             xca.change_amount                                           change_amount,               --��K
--             hp.organization_name_phonetic                               org_name_phonetic,           --�ڋq���J�i
--             hl.city || hl.address1 || hl.address2                       address1,                    --�Z���P
--             hl.address_lines_phonetic                                   address_lines_phonetic,      --�d�b�ԍ�
--             xca.sale_base_code                                          sale_base_code,              --���㋒�_�R�[�h
--             xca.past_sale_base_code                                     past_sale_base_code,         --�O�����㋒�_�R�[�h
--             xca.rsv_sale_base_code                                      rsv_sale_base_code,          --�\�񔄏㋒�_�R�[�h
--             xca.rsv_sale_base_act_date                                  rsv_sale_base_act_date,      --�\�񔄏㋒�_�L���J�n��
--             hopera.resource_no                                          resource_no,                 --�S���c�ƈ��R�[�h
--             hopero.route_no                                             route_no,                    --���[�g�R�[�h
--             hca.cust_account_id                                         cust_account_id,             --�ڋqID
--             hca.party_id                                                party_id,                    --�p�[�e�BID
--             hca.customer_class_code                                     customer_class_code,         --�ڋq�敪
--             hopera2.resource_no                                         next_resource_no,            --�����S���c�ƈ��R�[�h
--             hopera2.resource_s_date                                     next_resource_s_date,        --�����S���c�ƈ��K�p��
--             hopero2.route_no                                            next_route_no,               --�\�񃋁[�g�R�[�h
--             hopero2.route_s_date                                        next_route_s_date            --�\�񃋁[�g�R�[�h�K�p��
--      FROM   hz_cust_accounts          hca,      --�ڋq�}�X�^
--             hz_locations              hl,       --�ڋq���Ə��}�X�^
--             hz_cust_site_uses         hcsu,     --�ڋq�g�p�ړI�}�X�^
--             xxcmm_cust_accounts       xca,      --�ڋq�ǉ����}�X�^
--             hz_party_sites            hps,      --�p�[�e�B�T�C�g�}�X�^
--             hz_cust_acct_sites        hcas,     --�ڋq���ݒn�}�X�^
--             hz_parties                hp,       --�p�[�e�B�}�X�^
--             ra_terms                  rt,       --�x�������}�X�^
----
--             (SELECT lookup_code    lookup_code,
--                     attribute1     attribute1
--             FROM    fnd_lookup_values flvs
--             WHERE   flvs.language     = cv_language_ja
--             AND     flvs.lookup_type  = cv_gyotai_syo
--             AND     flvs.enabled_flag = cv_enabled_flag) flvgs,    --�N�C�b�N�R�[�h_�Q�ƃR�[�h(�Ƒ�(������))
----
--             (SELECT flvc.lookup_code    lookup_code,
--                     flvc.attribute3     attribute3
--             FROM    fnd_lookup_values flvc
--             WHERE   flvc.language     = cv_language_ja
--             AND     flvc.lookup_type  = cv_hht_syohi
--             AND     flvc.enabled_flag = cv_enabled_flag) flvctc,   --�N�C�b�N�R�[�h_�Q�ƃR�[�h(HHT����ŋ敪)
----
--             (SELECT hopviw1.party_id            party_id,
--                     erea.resource_no            resource_no,
--                     erea.resource_s_date        resource_s_date,
--                     hopev.last_update_date      last_update_date
---- 2009/04/28 Ver1.3 modify start by Yutaka.Kuboshima
----             FROM    hz_cust_accounts            hcaviw1,   --�ڋq�}�X�^
--             FROM    hz_parties                  hcaviw1,   --�p�[�e�B�}�X�^
---- 2009/04/28 Ver1.3 modify end by Yutaka.Kuboshima
--                     hz_organization_profiles    hopviw1,   --�g�D�v���t�@�C���}�X�^
--                     ego_resource_agv            erea,      --�g�D�v���t�@�C���g���}�X�^(�c�ƈ�)
--                     hz_org_profiles_ext_vl      hopev
--             WHERE   (TO_DATE(gv_process_date, cv_fnd_date) + 1
--                     BETWEEN NVL(TRUNC(erea.resource_s_date, cv_trunc_dd), TO_DATE(gv_process_date, cv_fnd_date) + 1)
--                     AND     NVL(TRUNC(erea.resource_e_date, cv_trunc_dd), TO_DATE(cv_eff_last_date, cv_fnd_date)))
--             AND     hcaviw1.party_id  = hopviw1.party_id
--             AND     erea.extension_id = hopev.extension_id
--             AND     hopviw1.organization_profile_id = erea.organization_profile_id
--             AND     erea.extension_id = (SELECT erearow1.extension_id
--                                         FROM    hz_organization_profiles      hoprow1,       --�g�D�v���t�@�C���}�X�^
--                                                 ego_resource_agv              erearow1       --�g�D�v���t�@�C���g���}�X�^(�c�ƈ�)
--                                         WHERE   (TO_DATE(gv_process_date, cv_fnd_date) + 1
--                                                 BETWEEN NVL(TRUNC(erearow1.resource_s_date, cv_trunc_dd), TO_DATE(gv_process_date, cv_fnd_date) + 1)
--                                                 AND     NVL(TRUNC(erearow1.resource_e_date, cv_trunc_dd), TO_DATE(cv_eff_last_date, cv_fnd_date)))
--                                         AND     hcaviw1.party_id            = hoprow1.party_id
--                                         AND     hoprow1.organization_profile_id = erearow1.organization_profile_id
--                                         AND     ROWNUM = 1 ))  hopera, --�g�D�v���t�@�C��(�S���c�ƈ�)
----
--             (SELECT hopnm.party_id              party_id,
--                     hopev.last_update_date      last_update_date,
--                     ereanm.resource_no          resource_no,
--                     ereanm.resource_s_date      resource_s_date
---- 2009/04/28 Ver1.3 modify start by Yutaka.Kuboshima
----             FROM    hz_cust_accounts            hcanm,     --�ڋq�}�X�^
--             FROM    hz_parties                  hcanm,     --�p�[�e�B�}�X�^
---- 2009/04/28 Ver1.3 modify end by Yutaka.Kuboshima
--                     hz_organization_profiles    hopnm,     --�g�D�v���t�@�C���}�X�^
--                     ego_resource_agv            ereanm,    --�g�D�v���t�@�C���g���}�X�^(�c�ƈ�)
--                     hz_org_profiles_ext_vl      hopev
--             WHERE   NVL(TRUNC(ereanm.resource_s_date, cv_trunc_dd), TO_DATE(gv_process_date, cv_fnd_date) + 1)
--                     BETWEEN TRUNC(ADD_MONTHS(TO_DATE(gv_process_date, cv_fnd_date) + 1, 1), cv_trunc_mm)
--                     AND     LAST_DAY(ADD_MONTHS(TO_DATE(gv_process_date, cv_fnd_date) + 1, 1))
--             AND     hopnm.party_id                = hcanm.party_id
--             AND     ereanm.extension_id           = hopev.extension_id
--             AND     hopnm.organization_profile_id = ereanm.organization_profile_id
--             AND     ereanm.extension_id = (SELECT erevw.extension_id
--                                           FROM    (SELECT  erea.extension_id           extension_id,
--                                                            erea.resource_no            resource_no,
--                                                            erea.resource_s_date        resource_s_date,
--                                                            hop.party_id                party_id
--                                                   FROM     hz_organization_profiles    hop,       --�g�D�v���t�@�C���}�X�^
--                                                            ego_resource_agv            erea       --�g�D�v���t�@�C���g���}�X�^(�c�ƈ�)
--                                                   WHERE    NVL(TRUNC(erea.resource_s_date, cv_trunc_dd), TO_DATE(gv_process_date, cv_fnd_date) + 1)
--                                                            BETWEEN TRUNC(ADD_MONTHS(TO_DATE(gv_process_date, cv_fnd_date) + 1, 1), cv_trunc_mm)
--                                                            AND     LAST_DAY(ADD_MONTHS(TO_DATE(gv_process_date, cv_fnd_date) + 1, 1))
--                                                   AND      hop.organization_profile_id = erea.organization_profile_id
--                                                   ORDER BY erea.resource_s_date) erevw,
--                                                   hz_organization_profiles  hopex
--                                           WHERE  hopex.party_id = erevw.party_id
--                                           AND    hopnm.party_id = hopex.party_id
--                                           AND    ROWNUM = 1))   hopera2,  --�g�D�v���t�@�C���}�X�^(�����S���c�ƈ�)
----
--             (SELECT hopviw2.party_id            party_id,
--                     eroa.route_no               route_no,
--                     eroa.route_s_date           route_s_date,
--                     hopev2.last_update_date     last_update_date
---- 2009/04/28 Ver1.3 modify start by Yutaka.Kuboshima
----             FROM    hz_cust_accounts            hcaviw2,   --�ڋq�}�X�^
--             FROM    hz_parties                  hcaviw2,   --�p�[�e�B�}�X�^
---- 2009/04/28 Ver1.3 modify end by Yutaka.Kuboshima
--                     hz_organization_profiles    hopviw2,   --�g�D�v���t�@�C���}�X�^
--                     ego_route_agv               eroa,      --�g�D�v���t�@�C���g���}�X�^(���[�g)
--                     hz_org_profiles_ext_vl      hopev2
--             WHERE   (TO_DATE(gv_process_date, cv_fnd_date) + 1
--                     BETWEEN NVL(TRUNC(eroa.route_s_date, cv_trunc_dd), TO_DATE(gv_process_date, cv_fnd_date) + 1)
--                     AND     NVL(TRUNC(eroa.route_e_date, cv_trunc_dd), TO_DATE(cv_eff_last_date, cv_fnd_date)))
--             AND     hcaviw2.party_id  = hopviw2.party_id
--             AND     eroa.extension_id = hopev2.extension_id
--             AND     hopviw2.organization_profile_id = eroa.organization_profile_id
--             AND     eroa.extension_id = (SELECT eroarow2.extension_id
--                                         FROM    hz_organization_profiles      hoprow2,       --�g�D�v���t�@�C���}�X�^
--                                                 ego_route_agv                 eroarow2       --�g�D�v���t�@�C���g���}�X�^(���[�g)
--                                         WHERE   (TO_DATE(gv_process_date, cv_fnd_date) + 1
--                                                 BETWEEN NVL(TRUNC(eroarow2.route_s_date, cv_trunc_dd), TO_DATE(gv_process_date, cv_fnd_date) + 1)
--                                                 AND     NVL(TRUNC(eroarow2.route_e_date, cv_trunc_dd), TO_DATE(cv_eff_last_date, cv_fnd_date)))
--                                         AND     hcaviw2.party_id  = hoprow2.party_id
--                                         AND     hoprow2.organization_profile_id = eroarow2.organization_profile_id
--                                         AND     ROWNUM = 1 ))  hopero,  --�g�D�v���t�@�C��(���[�g)
----
--             (SELECT hopnm.party_id              party_id,
--                     hopev.last_update_date      last_update_date,
--                     ereanm.route_no             route_no,
--                     ereanm.route_s_date         route_s_date
---- 2009/04/28 Ver1.3 modify start by Yutaka.Kuboshima
----             FROM    hz_cust_accounts            hcanm,     --�ڋq�}�X�^
--             FROM    hz_parties                  hcanm,     --�p�[�e�B�}�X�^
---- 2009/04/28 Ver1.3 modify end by Yutaka.Kuboshima
--                     hz_organization_profiles    hopnm,     --�g�D�v���t�@�C���}�X�^
--                     ego_route_agv               ereanm,    --�g�D�v���t�@�C���g���}�X�^(�c�ƈ�)
--                     hz_org_profiles_ext_vl      hopev
--             WHERE   NVL(TRUNC(ereanm.route_s_date, cv_trunc_dd), TO_DATE(gv_process_date, cv_fnd_date) + 1)
--                     BETWEEN TRUNC(ADD_MONTHS(TO_DATE(gv_process_date, cv_fnd_date) + 1, 1), cv_trunc_mm)
--                     AND     LAST_DAY(ADD_MONTHS(TO_DATE(gv_process_date, cv_fnd_date) + 1, 1))
--             AND     hopnm.party_id                = hcanm.party_id
--             AND     ereanm.extension_id           = hopev.extension_id
--             AND     hopnm.organization_profile_id = ereanm.organization_profile_id
--             AND     ereanm.extension_id = (SELECT erevw.extension_id
--                                           FROM    (SELECT  erea.extension_id           extension_id,
--                                                            erea.route_no               route_no,
--                                                            erea.route_s_date           route_s_date,
--                                                            hop.party_id                party_id
--                                                   FROM     hz_organization_profiles    hop,       --�g�D�v���t�@�C���}�X�^
--                                                            ego_route_agv               erea       --�g�D�v���t�@�C���g���}�X�^(�c�ƈ�)
--                                                   WHERE    NVL(TRUNC(erea.route_s_date, cv_trunc_dd), TO_DATE(gv_process_date, cv_fnd_date) + 1)
--                                                            BETWEEN TRUNC(ADD_MONTHS(TO_DATE(gv_process_date, cv_fnd_date) + 1, 1), cv_trunc_mm)
--                                                            AND     LAST_DAY(ADD_MONTHS(TO_DATE(gv_process_date, cv_fnd_date) + 1, 1))
--                                                   AND      hop.organization_profile_id = erea.organization_profile_id
--                                                   ORDER BY erea.route_s_date) erevw,
--                                                   hz_organization_profiles  hopex
--                                           WHERE  hopex.party_id = erevw.party_id
--                                           AND    hopnm.party_id = hopex.party_id
--                                           AND    ROWNUM = 1))   hopero2   --�g�D�v���t�@�C���}�X�^(�������[�g)
----
--      WHERE  (hca.customer_class_code  IN ( cv_cust_cd, cv_ucust_cd, cv_round_cd, cv_plan_cd )
--      OR     (hca.customer_class_code  IS NULL
--      AND    hp.duns_number_c = cv_mc_sts))
--      AND    ((TRUNC(hca.last_update_date, cv_trunc_dd)      --�ڋq�}�X�^
--             BETWEEN NVL(TO_DATE(REPLACE(iv_proc_date_from, cv_hur_sls, cv_date_null), cv_fnd_date), TO_DATE(gv_process_date, cv_fnd_date ) )
--             AND     NVL(TO_DATE(REPLACE(iv_proc_date_to, cv_hur_sls, cv_date_null), cv_fnd_date), TO_DATE(gv_process_date, cv_fnd_date ) ) )
--      OR     (TRUNC(xca.last_update_date, cv_trunc_dd)      --�ڋq�ǉ����}�X�^
--             BETWEEN NVL(TO_DATE(REPLACE(iv_proc_date_from, cv_hur_sls, cv_date_null), cv_fnd_date), TO_DATE(gv_process_date, cv_fnd_date ) )
--             AND     NVL(TO_DATE(REPLACE(iv_proc_date_to, cv_hur_sls, cv_date_null), cv_fnd_date), TO_DATE(gv_process_date, cv_fnd_date ) ) )
--      OR     (TRUNC(hl.last_update_date, cv_trunc_dd)      --�ڋq���Ə��}�X�^
--             BETWEEN NVL(TO_DATE(REPLACE(iv_proc_date_from, cv_hur_sls, cv_date_null), cv_fnd_date), TO_DATE(gv_process_date, cv_fnd_date ) )
--             AND     NVL(TO_DATE(REPLACE(iv_proc_date_to, cv_hur_sls, cv_date_null), cv_fnd_date), TO_DATE(gv_process_date, cv_fnd_date ) ) )
--      OR     (TRUNC(hp.last_update_date, cv_trunc_dd)      --�p�[�e�B�}�X�^
--             BETWEEN NVL(TO_DATE(REPLACE(iv_proc_date_from, cv_hur_sls, cv_date_null), cv_fnd_date), TO_DATE(gv_process_date, cv_fnd_date ) )
--             AND     NVL(TO_DATE(REPLACE(iv_proc_date_to, cv_hur_sls, cv_date_null), cv_fnd_date), TO_DATE(gv_process_date, cv_fnd_date ) ) )
--      OR     (TRUNC(hcsu.last_update_date, cv_trunc_dd)      --�ڋq�g�p�ړI�}�X�^
--             BETWEEN NVL(TO_DATE(REPLACE(iv_proc_date_from, cv_hur_sls, cv_date_null), cv_fnd_date), TO_DATE(gv_process_date, cv_fnd_date ) )
--             AND     NVL(TO_DATE(REPLACE(iv_proc_date_to, cv_hur_sls, cv_date_null), cv_fnd_date), TO_DATE(gv_process_date, cv_fnd_date ) ) )
--      OR     (TRUNC(rt.last_update_date, cv_trunc_dd)      --�x�������}�X�^
--             BETWEEN NVL(TO_DATE(REPLACE(iv_proc_date_from, cv_hur_sls, cv_date_null), cv_fnd_date), TO_DATE(gv_process_date, cv_fnd_date ) )
--             AND     NVL(TO_DATE(REPLACE(iv_proc_date_to, cv_hur_sls, cv_date_null), cv_fnd_date), TO_DATE(gv_process_date, cv_fnd_date ) ) )
--      OR     (TRUNC(hopera.last_update_date, cv_trunc_dd)      --�g�D�v���t�@�C��(�c�ƈ�)
--             BETWEEN NVL(TO_DATE(REPLACE(iv_proc_date_from, cv_hur_sls, cv_date_null), cv_fnd_date), TO_DATE(gv_process_date, cv_fnd_date ) )
--             AND     NVL(TO_DATE(REPLACE(iv_proc_date_to, cv_hur_sls, cv_date_null), cv_fnd_date), TO_DATE(gv_process_date, cv_fnd_date ) ) )
--      OR     (TRUNC(hopera2.last_update_date, cv_trunc_dd)      --�g�D�v���t�@�C��(�����c�ƈ�)
--             BETWEEN NVL(TO_DATE(REPLACE(iv_proc_date_from, cv_hur_sls, cv_date_null), cv_fnd_date), TO_DATE(gv_process_date, cv_fnd_date ) )
--             AND     NVL(TO_DATE(REPLACE(iv_proc_date_to, cv_hur_sls, cv_date_null), cv_fnd_date), TO_DATE(gv_process_date, cv_fnd_date ) ) )
--      OR     (TRUNC(hopero.last_update_date, cv_trunc_dd)      --�g�D�v���t�@�C��(���[�g)
--             BETWEEN NVL(TO_DATE(REPLACE(iv_proc_date_from, cv_hur_sls, cv_date_null), cv_fnd_date), TO_DATE(gv_process_date, cv_fnd_date ) )
--             AND     NVL(TO_DATE(REPLACE(iv_proc_date_to, cv_hur_sls, cv_date_null), cv_fnd_date), TO_DATE(gv_process_date, cv_fnd_date ) ) )
--      OR     (TRUNC(hopero2.last_update_date, cv_trunc_dd)      --�g�D�v���t�@�C��(�������[�g)
--             BETWEEN NVL(TO_DATE(REPLACE(iv_proc_date_from, cv_hur_sls, cv_date_null), cv_fnd_date), TO_DATE(gv_process_date, cv_fnd_date ) )
--             AND     NVL(TO_DATE(REPLACE(iv_proc_date_to, cv_hur_sls, cv_date_null), cv_fnd_date), TO_DATE(gv_process_date, cv_fnd_date ) ) ) )
--      AND    xca.tax_div            = flvctc.attribute3 (+)        --����ŋ敪
--      AND    hca.party_id           = hopera.party_id (+)          --�ڋq�}�X�^           = �g�D�v���g���}�X�^�F�p�[�e�BID(�c��)
--      AND    hca.party_id           = hopera2.party_id (+)         --�ڋq�}�X�^           = �g�D�v���g���}�X�^�F�p�[�e�BID(�����c��)
--      AND    hca.party_id           = hopero.party_id (+)          --�ڋq�}�X�^           = �g�D�v���g���}�X�^�F�p�[�e�BID(���[�g)
--      AND    hca.party_id           = hopero2.party_id (+)         --�ڋq�}�X�^           = �g�D�v���g���}�X�^�F�p�[�e�BID(�������[�g)
--      AND    hca.cust_account_id    = xca.customer_id              --�ڋq�}�X�^           = �ڋq�ǉ����}�X�^�F�ڋqID
--      AND    hca.party_id           = hp.party_id                  --�ڋq�}�X�^           = �p�[�e�B�}�X�^    �F�p�[�e�BID
--      AND    hps.location_id        = hl.location_id               --�p�[�e�B�T�C�g�}�X�^ = ���Ə��}�X�^      �F���P�[�V����ID
--      AND    hca.cust_account_id    = hcas.cust_account_id         --�ڋq�}�X�^           = �ڋq���ݒn�}�X�^  �F�ڋqID
--      AND    hcas.cust_acct_site_id = hcsu.cust_acct_site_id       --�ڋq���ݒn�}�X�^     = �g�p�ړI�}�X�^    �F�ڋq�T�C�gID
--      AND    xca.business_low_type  = flvgs.lookup_code (+)        --LOOKUP_�Q��(�Ƒԏ�)  = �ڋq�ǉ����}�X�^: �Ƒԕ���(������)
--      AND    hcsu.payment_term_id   = rt.term_id (+)               --�g�p�ړI�}�X�^       = �x�������}�X�^    : �x������ID
--      AND    hcsu.site_use_code     IN ( cv_bill_to, cv_other_to ) --�g�p�ړI�}�X�^(������E���̑�)
--      AND    hcsu.status            = cv_a_flag
--      AND    hl.location_id         = (SELECT MIN(hpsiv.location_id)
--                                      FROM    hz_cust_acct_sites     hcasiv,
--                                              hz_party_sites         hpsiv
--                                      WHERE   hcasiv.cust_account_id = hca.cust_account_id
--                                      AND     hcasiv.party_site_id   = hpsiv.party_site_id
--                                      AND     hpsiv.status           = cv_a_flag)      --���P�[�V����ID�̍ŏ��l
---- 2009/04/28 Ver1.3 add start by Yutaka.Kuboshima
--      AND    hp.party_id            = hps.party_id
--      AND    hcas.party_site_id     = hps.party_site_id
---- 2009/04/28 Ver1.3 add end by Yutaka.Kuboshima
--      ORDER BY hca.account_number;
--
-- �� modify start
    -- HHT�A�gIF�f�[�^�쐬�J�[�\��
    CURSOR cust_data_cur(p_customer_id         IN NUMBER,
                         p_process_date_next_f IN DATE,
                         p_process_date_next_l IN DATE)
    IS
      SELECT /*+ FIRST_ROWS */
             hca.account_number                                          account_number,              --�ڋq�R�[�h
             hp.party_name                                               party_name,                  --�ڋq����
-- Ver1.12 mod start
--             flvctc.lookup_code                                          tax_div,                     --����ŋ敪
             flvctc.attribute1                                           tax_div,                     --����ŋ敪
-- Ver1.12 mod end
             DECODE( xca.business_low_type, cv_vd_24, cv_on_sts, cv_vd_25, cv_on_sts, cv_vd_26, cv_tw_sts, cv_null_sts, cv_date_null, cv_zr_sts )  vd_contract_form, --�x���_�_��`��
             DECODE( rt.name, cv_pay_tm, cv_on_sts, cv_null_sts, cv_date_null, cv_th_sts )           mode_div,           --�ԗl�敪
             xca.final_tran_date                                         final_tran_date,             --�ŏI�����
             xca.final_call_date                                         final_call_date,             --�ŏI�K���
             DECODE( xca.business_low_type, cv_in_21, cv_on_sts, cv_vd_27, cv_tw_sts, cv_null_sts, cv_date_null, cv_zr_sts )  entrust_dest_flg, --�a���攻��t���O
             DECODE( flvgs.attribute1, cv_vd_11, cv_on_sts, cv_null_sts, cv_date_null, cv_zr_sts )  vd_cust_class_cd,   --VD�ڋq�敪
-- 2011/05/16 Ver1.10 E_�{�ғ�_07429 add start by Shigeto.Niki
             xca.longitude                                               vendor_offset_time,          --���̋@�I�t�Z�b�g����
-- 2011/05/16 Ver1.10 E_�{�ғ�_07429 add end by Shigeto.Niki
-- Ver1.13 add start
             xca.business_low_type                                       business_low_type,           --�ƑԃR�[�h
-- Ver1.13 add end
-- Ver1.14 add start
             hcsu.tax_rounding_rule                                      tax_rounding_rule,           --�ŋ��[������
-- Ver1.14 add end
             hp.duns_number_c                                            duns_number_c,               --�ڋq�X�e�[�^�X�R�[�h
             xca.change_amount                                           change_amount,               --��K
             hp.organization_name_phonetic                               org_name_phonetic,           --�ڋq���J�i
             hl.city || hl.address1 || hl.address2                       address1,                    --�Z���P
             hl.address_lines_phonetic                                   address_lines_phonetic,      --�d�b�ԍ�
             xca.sale_base_code                                          sale_base_code,              --���㋒�_�R�[�h
             xca.past_sale_base_code                                     past_sale_base_code,         --�O�����㋒�_�R�[�h
             xca.rsv_sale_base_code                                      rsv_sale_base_code,          --�\�񔄏㋒�_�R�[�h
             xca.rsv_sale_base_act_date                                  rsv_sale_base_act_date,      --�\�񔄏㋒�_�L���J�n��
             hopera.resource_no                                          resource_no,                 --�S���c�ƈ��R�[�h
             hopero.route_no                                             route_no,                    --���[�g�R�[�h
             hca.cust_account_id                                         cust_account_id,             --�ڋqID
             hca.party_id                                                party_id,                    --�p�[�e�BID
             hca.customer_class_code                                     customer_class_code,         --�ڋq�敪
             hopera2.resource_no                                         next_resource_no,            --�����S���c�ƈ��R�[�h
             hopera2.resource_s_date                                     next_resource_s_date,        --�����S���c�ƈ��K�p��
             hopero2.route_no                                            next_route_no,               --�\�񃋁[�g�R�[�h
             hopero2.route_s_date                                        next_route_s_date            --�\�񃋁[�g�R�[�h�K�p��
      FROM   hz_cust_accounts          hca,      --�ڋq�}�X�^
             hz_locations              hl,       --�ڋq���Ə��}�X�^
             hz_cust_site_uses         hcsu,     --�ڋq�g�p�ړI�}�X�^
             xxcmm_cust_accounts       xca,      --�ڋq�ǉ����}�X�^
             hz_party_sites            hps,      --�p�[�e�B�T�C�g�}�X�^
             hz_cust_acct_sites        hcas,     --�ڋq���ݒn�}�X�^
             hz_parties                hp,       --�p�[�e�B�}�X�^
             ra_terms                  rt,       --�x�������}�X�^
--
             (SELECT flvs.lookup_code    lookup_code,
                     flvs.attribute1     attribute1
             FROM    fnd_lookup_values flvs
             WHERE   flvs.language     = cv_language_ja
             AND     flvs.lookup_type  = cv_gyotai_syo
             AND     flvs.enabled_flag = cv_enabled_flag) flvgs,    --�N�C�b�N�R�[�h_�Q�ƃR�[�h(�Ƒ�(������))
--
-- Ver1.12 mod start
--             (SELECT flvc.lookup_code    lookup_code,
             (SELECT flvc.attribute1     attribute1,  -- ����ŋ敪
-- Ver1.12 mod end
                     flvc.attribute3     attribute3
             FROM    fnd_lookup_values flvc
             WHERE   flvc.language     = cv_language_ja
             AND     flvc.lookup_type  = cv_hht_syohi
-- Ver1.12 add start
-- Ver1.12 mod start
--             AND     gd_process_date BETWEEN flvc.start_date_active
             AND     (gd_process_date + 1) BETWEEN flvc.start_date_active
-- Ver1.12 mod end
                                     AND NVL(flvc.end_date_active, TO_DATE(cv_eff_last_date, cv_fnd_date))
-- Ver1.12 add end
             AND     flvc.enabled_flag = cv_enabled_flag) flvctc,   --�N�C�b�N�R�[�h_�Q�ƃR�[�h(HHT����ŋ敪)
--
             -- �g�D�v���t�@�C���g���}�X�^�̌������폜
             -- ���t���ڂ̌�����
             (SELECT hopviw1.party_id            party_id,
                     erea.resource_no            resource_no,
                     erea.resource_s_date        resource_s_date
             FROM    hz_parties                  hcaviw1,   --�p�[�e�B�}�X�^
                     hz_organization_profiles    hopviw1,   --�g�D�v���t�@�C���}�X�^
                     ego_resource_agv            erea       --�g�D�v���t�@�C���g���}�X�^(�c�ƈ�)
             WHERE   (gd_process_date + 1) BETWEEN erea.resource_s_date AND NVL(erea.resource_e_date, TO_DATE(cv_eff_last_date, cv_fnd_date))
             AND     hcaviw1.party_id  = hopviw1.party_id
             AND     hopviw1.organization_profile_id = erea.organization_profile_id
-- 2009/11/23 Ver1.6 add start by Yutaka.Kuboshima
             AND     hopviw1.effective_end_date IS NULL
-- 2009/11/23 Ver1.6 add end by Yutaka.Kuboshima
             AND     erea.extension_id = (SELECT  erearow1.extension_id
                                          FROM    hz_organization_profiles      hoprow1,       --�g�D�v���t�@�C���}�X�^
                                                  ego_resource_agv              erearow1       --�g�D�v���t�@�C���g���}�X�^(�c�ƈ�)
                                          WHERE   (gd_process_date + 1) BETWEEN erearow1.resource_s_date AND NVL(erearow1.resource_e_date, TO_DATE(cv_eff_last_date, cv_fnd_date))
                                          AND     hcaviw1.party_id            = hoprow1.party_id
                                          AND     hoprow1.organization_profile_id = erearow1.organization_profile_id
-- 2009/11/23 Ver1.6 add start by Yutaka.Kuboshima
                                          AND     hoprow1.effective_end_date IS NULL
-- 2009/11/23 Ver1.6 add end by Yutaka.Kuboshima
                                          AND     ROWNUM = 1 ))  hopera, --�g�D�v���t�@�C��(�S���c�ƈ�)
--
             -- �g�D�v���t�@�C���g���}�X�^�̌������폜
             -- ���t���ڂ̌�����
             (SELECT hopnm.party_id              party_id,
                     ereanm.resource_no          resource_no,
                     ereanm.resource_s_date      resource_s_date
             FROM    hz_parties                  hcanm,     --�p�[�e�B�}�X�^
                     hz_organization_profiles    hopnm,     --�g�D�v���t�@�C���}�X�^
                     ego_resource_agv            ereanm     --�g�D�v���t�@�C���g���}�X�^(�c�ƈ�)
             WHERE   ereanm.resource_s_date BETWEEN p_process_date_next_f AND p_process_date_next_l
             AND     hopnm.party_id                = hcanm.party_id
             AND     hopnm.organization_profile_id = ereanm.organization_profile_id
-- 2009/11/23 Ver1.6 add start by Yutaka.Kuboshima
             AND     hopnm.effective_end_date IS NULL
-- 2009/11/23 Ver1.6 add end by Yutaka.Kuboshima
             AND     ereanm.extension_id = (SELECT erevw.extension_id
                                            FROM   (SELECT   erea.extension_id           extension_id,
                                                             hop.party_id                party_id
                                                    FROM     hz_organization_profiles    hop,       --�g�D�v���t�@�C���}�X�^
                                                             ego_resource_agv            erea       --�g�D�v���t�@�C���g���}�X�^(�c�ƈ�)
                                                    WHERE    erea.resource_s_date BETWEEN p_process_date_next_f AND p_process_date_next_l
                                                    AND      hop.organization_profile_id = erea.organization_profile_id
-- 2009/11/23 Ver1.6 add start by Yutaka.Kuboshima
                                                    AND      hop.effective_end_date IS NULL
-- 2009/11/23 Ver1.6 add end by Yutaka.Kuboshima
                                                    ORDER BY erea.resource_s_date) erevw
                                            WHERE  hopnm.party_id = erevw.party_id
                                            AND    ROWNUM = 1))   hopera2,  --�g�D�v���t�@�C���}�X�^(�����S���c�ƈ�)
--
             -- �g�D�v���t�@�C���g���}�X�^�̌������폜
             -- ���t���ڂ̌�����
             (SELECT hopviw2.party_id            party_id,
                     eroa.route_no               route_no,
                     eroa.route_s_date           route_s_date
             FROM    hz_parties                  hcaviw2,   --�p�[�e�B�}�X�^
                     hz_organization_profiles    hopviw2,   --�g�D�v���t�@�C���}�X�^
                     ego_route_agv               eroa       --�g�D�v���t�@�C���g���}�X�^(���[�g)
             WHERE   (gd_process_date + 1) BETWEEN eroa.route_s_date AND NVL(eroa.route_e_date, TO_DATE(cv_eff_last_date, cv_fnd_date))
             AND     hcaviw2.party_id  = hopviw2.party_id
             AND     hopviw2.organization_profile_id = eroa.organization_profile_id
-- 2009/11/23 Ver1.6 add start by Yutaka.Kuboshima
             AND     hopviw2.effective_end_date IS NULL
-- 2009/11/23 Ver1.6 add end by Yutaka.Kuboshima
             AND     eroa.extension_id = (SELECT  eroarow2.extension_id
                                          FROM    hz_organization_profiles      hoprow2,       --�g�D�v���t�@�C���}�X�^
                                                  ego_route_agv                 eroarow2       --�g�D�v���t�@�C���g���}�X�^(���[�g)
                                          WHERE   (gd_process_date + 1) BETWEEN eroarow2.route_s_date AND NVL(eroarow2.route_e_date, TO_DATE(cv_eff_last_date, cv_fnd_date))
                                          AND     hcaviw2.party_id  = hoprow2.party_id
                                          AND     hoprow2.organization_profile_id = eroarow2.organization_profile_id
-- 2009/11/23 Ver1.6 add start by Yutaka.Kuboshima
                                          AND     hoprow2.effective_end_date IS NULL
-- 2009/11/23 Ver1.6 add end by Yutaka.Kuboshima
                                          AND     ROWNUM = 1 ))  hopero,  --�g�D�v���t�@�C��(���[�g)
--
             -- �g�D�v���t�@�C���g���}�X�^�̌������폜
             -- ���t���ڂ̌�����
             (SELECT hopnm.party_id              party_id,
                     ereanm.route_no             route_no,
                     ereanm.route_s_date         route_s_date
             FROM    hz_parties                  hcanm,     --�p�[�e�B�}�X�^
                     hz_organization_profiles    hopnm,     --�g�D�v���t�@�C���}�X�^
                     ego_route_agv               ereanm     --�g�D�v���t�@�C���g���}�X�^(�c�ƈ�)
             WHERE   ereanm.route_s_date BETWEEN p_process_date_next_f AND p_process_date_next_l
             AND     hopnm.party_id                = hcanm.party_id
             AND     hopnm.organization_profile_id = ereanm.organization_profile_id
-- 2009/11/23 Ver1.6 add start by Yutaka.Kuboshima
             AND     hopnm.effective_end_date IS NULL
-- 2009/11/23 Ver1.6 add end by Yutaka.Kuboshima
             AND     ereanm.extension_id = (SELECT erevw.extension_id
                                            FROM  (SELECT   erea.extension_id           extension_id,
                                                            hop.party_id                party_id
                                                   FROM     hz_organization_profiles    hop,       --�g�D�v���t�@�C���}�X�^
                                                            ego_route_agv               erea       --�g�D�v���t�@�C���g���}�X�^(�c�ƈ�)
                                                   WHERE    erea.route_s_date BETWEEN p_process_date_next_f AND p_process_date_next_l
                                                   AND      hop.organization_profile_id = erea.organization_profile_id
-- 2009/11/23 Ver1.6 add start by Yutaka.Kuboshima
                                                   AND      hop.effective_end_date IS NULL
                                                   ORDER BY erea.route_s_date) erevw
-- 2009/11/23 Ver1.6 add end by Yutaka.Kuboshima
                                            WHERE  hopnm.party_id = erevw.party_id
                                            AND    ROWNUM = 1))   hopero2   --�g�D�v���t�@�C���}�X�^(�������[�g)
--
      -- �������o�������SQL�Ɉړ�
      WHERE  (hca.customer_class_code  IN ( cv_cust_cd, cv_ucust_cd, cv_round_cd, cv_plan_cd )
      OR     (hca.customer_class_code  IS NULL
      AND    hp.duns_number_c = cv_mc_sts))
      AND    xca.tax_div            = flvctc.attribute3 (+)        --����ŋ敪
      AND    hca.party_id           = hopera.party_id (+)          --�ڋq�}�X�^           = �g�D�v���g���}�X�^�F�p�[�e�BID(�c��)
      AND    hca.party_id           = hopera2.party_id (+)         --�ڋq�}�X�^           = �g�D�v���g���}�X�^�F�p�[�e�BID(�����c��)
      AND    hca.party_id           = hopero.party_id (+)          --�ڋq�}�X�^           = �g�D�v���g���}�X�^�F�p�[�e�BID(���[�g)
      AND    hca.party_id           = hopero2.party_id (+)         --�ڋq�}�X�^           = �g�D�v���g���}�X�^�F�p�[�e�BID(�������[�g)
      AND    hca.cust_account_id    = xca.customer_id              --�ڋq�}�X�^           = �ڋq�ǉ����}�X�^�F�ڋqID
      AND    hca.party_id           = hp.party_id                  --�ڋq�}�X�^           = �p�[�e�B�}�X�^    �F�p�[�e�BID
      AND    hps.location_id        = hl.location_id               --�p�[�e�B�T�C�g�}�X�^ = ���Ə��}�X�^      �F���P�[�V����ID
      AND    hca.cust_account_id    = hcas.cust_account_id         --�ڋq�}�X�^           = �ڋq���ݒn�}�X�^  �F�ڋqID
      AND    hcas.cust_acct_site_id = hcsu.cust_acct_site_id       --�ڋq���ݒn�}�X�^     = �g�p�ړI�}�X�^    �F�ڋq�T�C�gID
      AND    xca.business_low_type  = flvgs.lookup_code (+)        --LOOKUP_�Q��(�Ƒԏ�)  = �ڋq�ǉ����}�X�^: �Ƒԕ���(������)
      AND    hcsu.payment_term_id   = rt.term_id (+)               --�g�p�ړI�}�X�^       = �x�������}�X�^    : �x������ID
-- 2011/03/07 Ver1.9 E_�{�ғ�_05329 modify start by Naoki.Horigome
--      AND    hcsu.site_use_code     IN ( cv_bill_to, cv_other_to ) --�g�p�ړI�}�X�^(������E���̑�)
      --�ڋq�敪(�ڋq)�A�ڋq�敪(��l�ڋq)�̏ꍇ�́A�g�p�ړI(������j�𒊏o
      AND    ((NVL(hca.customer_class_code, cv_cust_cd) IN (cv_cust_cd, cv_ucust_cd)
      AND    hcsu.site_use_code          = cv_bill_to)
      --�ڋq�敪(�X�܉c��)�A�ڋq�敪(�v�旧�ėp)�̏ꍇ�́A�g�p�ړI(���̑��j�𒊏o
      OR     (NVL(hca.customer_class_code, cv_cust_cd)  IN (cv_round_cd, cv_plan_cd)
      AND    hcsu.site_use_code          = cv_other_to))
-- 2011/03/07 Ver1.9 E_�{�ғ�_05329 modify end by Naoki.Horigome
      AND    hcsu.status            = cv_a_flag
      AND    hl.location_id         = (SELECT MIN(hpsiv.location_id)
                                      FROM    hz_cust_acct_sites     hcasiv,
                                              hz_party_sites         hpsiv
                                      WHERE   hcasiv.cust_account_id = hca.cust_account_id
                                      AND     hcasiv.party_site_id   = hpsiv.party_site_id
                                      AND     hpsiv.status           = cv_a_flag)      --���P�[�V����ID�̍ŏ��l
      AND    hp.party_id            = hps.party_id
      AND    hcas.party_site_id     = hps.party_site_id
      AND    hca.cust_account_id    = p_customer_id;
--
-- 2009/08/24 Ver1.5 modify end by Yutaka.Kuboshima
--
    --�m�[�g�J�[�\��
    CURSOR note_data_cur(p_party_id IN NUMBER)
    IS
      SELECT REPLACE(jnt.notes, CHR(10), cv_date_null)  notes,  --�m�[�g
             jnt.last_update_date             last_update_date  --�ŏI�X�V��
      FROM   jtf_notes_b   jnb,                                 --�m�[�g�}�X�^
             jtf_notes_tl  jnt                                  --�m�[�g���e�}�X�^
      WHERE  jnb.jtf_note_id = jnt.jtf_note_id
      AND    jnb.source_object_id = p_party_id
      AND    jnb.source_object_code = cv_oj_party
      AND    jnt.language = cv_language_ja
      ORDER BY jnb.jtf_note_id DESC;
--
-- 2009/04/13 Ver1.2 add start by Yutaka.Kuboshima
    -- ���_�����J�[�\��
    CURSOR serch_base_cur(p_sale_base_code IN VARCHAR2)
    IS
      SELECT xca.management_base_code management_base_code, -- �Ǘ������_�R�[�h
             xca.dept_hht_div         dept_hht_div          -- �S�ݓXHHT�敪
      FROM hz_cust_accounts    hca,                         -- �ڋq�}�X�^
           xxcmm_cust_accounts xca                          -- �ڋq�ǉ����}�X�^
      WHERE hca.cust_account_id     = xca.customer_id
        AND hca.customer_class_code = cv_base
        AND hca.account_number      = p_sale_base_code;
-- 2009/04/13 Ver1.2 add end by Yutaka.Kuboshima
-- 2009/08/24 Ver1.5 add start by Yutaka.Kuboshima
    -- �����A�g�Ώیڋq�擾�J�[�\�����R�[�h�^
    def_cust_rec def_cust_cur%ROWTYPE;
-- 2009/08/24 Ver1.5 add end by Yutaka.Kuboshima
    -- HHT�A�gIF�f�[�^�쐬�J�[�\�����R�[�h�^
    cust_data_rec cust_data_cur%ROWTYPE;
    -- �m�[�g�J�[�\�����R�[�h�^
    note_data_rec note_data_cur%ROWTYPE;
-- 2009/04/13 Ver1.2 add start by Yutaka.Kuboshima
    serch_base_rec serch_base_cur%ROWTYPE;
-- 2009/04/13 Ver1.2 add end by Yutaka.Kuboshima
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
    --�X�V�����̎擾
    lv_coordinated_date := TO_CHAR(sysdate, cv_fnd_sytem_date);
--
-- 2009/08/24 Ver1.5 modify start by Yutaka.Kuboshima
-- �f�[�^�擾�����啝���C
-- �����A�g�����ڋq���ɒ��o����l�ɏC��
--    --HHT�A�gIF�f�[�^�쐬�J�[�\�����[�v
--    << cust_for_loop >>
--    FOR cust_data_rec IN cust_data_cur
--    LOOP
--      --�m�[�g���t��
--      << note_for_loop >>
--      FOR  note_data_rec IN note_data_cur(cust_data_rec.party_id)
--      LOOP
--        lv_note_work := TO_CHAR(note_data_rec.last_update_date, cv_fnd_slash_date) || cv_hur_sps || note_data_rec.notes;
--        --�m�[�g��2000�o�C�g�ɒB�������_�ŏ����𒆒f����B
--        IF ( LENGTHB(lv_note_str || lv_note_work) <= cn_note_lenb ) THEN
--          lv_note_str := lv_note_str || lv_note_work || cv_ver_line;
--        ELSE
--          EXIT;
--        END IF;
--      END LOOP note_for_loop;
--      --�c���폜
--      lv_note_str := SUBSTRB(lv_note_str, 1, LENGTHB(lv_note_str) - 1);
----
---- 2009/04/13 Ver1.2 add start by Yutaka.Kuboshima
--      -- ���㋒�_�ɐݒ肳��Ă��鋒�_���������܂��B
--      OPEN serch_base_cur(cust_data_rec.sale_base_code);
--      FETCH serch_base_cur INTO serch_base_rec;
--      CLOSE serch_base_cur;
--      -- ���㋒�_�ɐݒ肳��Ă���S�ݓXHHT�敪'1'�̏ꍇ
--      IF (NVL(serch_base_rec.dept_hht_div, 0) = cv_dept_div_mult) THEN
--        -- ���㋒�_�R�[�h���Ǘ������_�R�[�h�ɐݒ�
--        cust_data_rec.sale_base_code      := serch_base_rec.management_base_code;
--      END IF;
--      -- �ϐ�������
--      serch_base_rec := NULL;
--      -- �O�����㋒�_�ɐݒ肳��Ă��鋒�_���������܂��B
--      OPEN serch_base_cur(cust_data_rec.past_sale_base_code);
--      FETCH serch_base_cur INTO serch_base_rec;
--      CLOSE serch_base_cur;
--      -- �O�����㋒�_�ɐݒ肳��Ă���S�ݓXHHT�敪'1'�̏ꍇ
--      IF (NVL(serch_base_rec.dept_hht_div, 0) = cv_dept_div_mult) THEN
--        -- �O�����㋒�_�R�[�h���Ǘ������_�R�[�h�ɐݒ�
--        cust_data_rec.past_sale_base_code := serch_base_rec.management_base_code;
--      END IF;
--      -- �ϐ�������
--      serch_base_rec := NULL;
--      -- �\�񔄏㋒�_�ɐݒ肳��Ă��鋒�_���������܂��B
--      OPEN serch_base_cur(cust_data_rec.rsv_sale_base_code);
--      FETCH serch_base_cur INTO serch_base_rec;
--      CLOSE serch_base_cur;
--      -- �\�񔄏㋒�_�ɐݒ肳��Ă���S�ݓXHHT�敪'1'�̏ꍇ
--      IF (NVL(serch_base_rec.dept_hht_div, 0) = cv_dept_div_mult) THEN
--        -- �\�񔄏㋒�_�R�[�h���Ǘ������_�R�[�h�ɐݒ�
--        cust_data_rec.rsv_sale_base_code  := serch_base_rec.management_base_code;
--      END IF;
--      -- �ϐ�������
--      serch_base_rec := NULL;
---- 2009/04/13 Ver1.2 add end by Yutaka.Kuboshima
--      -- ===============================
--      -- �o�͒l�ݒ�
--      -- ===============================
---- 2009/06/09 Ver1.4 add start by Yutaka.Kuboshima
--      -- �ڋq���̐ݒ�
--      lv_customer_name            := xxcso_util_common_pkg.conv_multi_byte(cust_data_rec.party_name);
--      -- �ڋq���J�i�ݒ�
--      lv_customer_name_kana       := xxccp_common_pkg.chg_double_to_single_byte(cust_data_rec.org_name_phonetic);
--      -- ���p�ϊ��s���������݂���ꍇ
--      IF (LENGTH(lv_customer_name_kana) <> LENGTHB(lv_customer_name_kana)) THEN
--        lv_customer_name_kana := cv_single_byte_err1;
--      END IF;
--      -- �Z���P�ݒ�
--      lv_address1                 := xxcso_util_common_pkg.conv_multi_byte(cust_data_rec.address1);
--      -- �d�b�ԍ��ݒ�
--      lv_address_lines_phonetic   := xxccp_common_pkg.chg_double_to_single_byte(cust_data_rec.address_lines_phonetic);
--      -- ���p�ϊ��s���������݂���ꍇ
--      IF (LENGTH(lv_address_lines_phonetic) <> LENGTHB(lv_address_lines_phonetic)) THEN
--        lv_address_lines_phonetic := cv_single_byte_err2;
--      END IF;
---- 2009/06/09 Ver1.4 add end by Yutaka.Kuboshima
--      --�o�͕�����쐬
--      lv_output_str := lv_output_str || cv_dqu   || NVL(SUBSTRB(cust_data_rec.account_number, 1, 9), cv_date_null)                    || cv_dqu;  --�ڋq�R�[�h
---- 2009/06/09 Ver1.4 modify start by Yutaka.Kuboshima
----      lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.party_name, 1, 50), cv_date_null)             || cv_dqu;  --�ڋq����
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(lv_customer_name, 1, 50), cv_date_null)                     || cv_dqu;  --�ڋq����
---- 2009/06/09 Ver1.4 modify start by Yutaka.Kuboshima
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.tax_div, 1, 1), cv_date_null)                 || cv_dqu;  --����ŋ敪
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.vd_contract_form, 1, 1), cv_date_null)        || cv_dqu;  --�x���_�_��`��
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.mode_div, 1, 1), cv_date_null)                || cv_dqu;  --�ԗl�敪
--      lv_output_str := lv_output_str || cv_comma || NVL(TO_CHAR(cust_data_rec.final_tran_date, cv_fnd_date), cv_null_code);                       --�ŏI�����
--      lv_output_str := lv_output_str || cv_comma || NVL(TO_CHAR(cust_data_rec.final_call_date, cv_fnd_date), cv_null_code);                       --�ŏI�K���
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.entrust_dest_flg, 1, 1), cv_date_null)        || cv_dqu;  --�a���攻��t���O
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cv_cdvd_code, 1, 1), cv_date_null)                          || cv_dqu;  --�J�[�h�x���_�敪
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.vd_cust_class_cd, 1, 1), cv_date_null)        || cv_dqu;  --�u�c�ڋq�敪
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.duns_number_c, 1, 2), cv_date_null)           || cv_dqu;  --�ڋq�X�e�[�^�X�R�[�h
--      lv_output_str := lv_output_str || cv_comma || SUBSTRB(NVL(TO_CHAR(cust_data_rec.change_amount), cv_null_code), 1, 5);                       --��K
---- 2009/06/09 Ver1.4 modify start by Yutaka.Kuboshima
----      lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.org_name_phonetic, 1, 30), cv_date_null)      || cv_dqu;  --�ڋq���J�i
----      lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.address1, 1, 60), cv_date_null)               || cv_dqu;  --�Z���P
----      lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.address_lines_phonetic, 1, 15), cv_date_null) || cv_dqu;  --�d�b�ԍ�
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(lv_customer_name_kana, 1, 30), cv_date_null)                || cv_dqu;  --�ڋq���J�i
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(lv_address1, 1, 60), cv_date_null)                          || cv_dqu;  --�Z���P
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(lv_address_lines_phonetic, 1, 15), cv_date_null)            || cv_dqu;  --�d�b�ԍ�
---- 2009/06/09 Ver1.4 modify start by Yutaka.Kuboshima
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(lv_note_str, 1, 2000), cv_date_null)                        || cv_dqu;  --�m�[�g
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.sale_base_code, 1, 4), cv_date_null)          || cv_dqu;  --���㋒�_�R�[�h
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.past_sale_base_code, 1, 4), cv_date_null)     || cv_dqu;  --�O�����㋒�_�R�[�h
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.rsv_sale_base_code, 1, 4), cv_date_null)      || cv_dqu;  --�\�񔄏㋒�_�R�[�h
--      lv_output_str := lv_output_str || cv_comma || NVL(TO_CHAR(cust_data_rec.rsv_sale_base_act_date, cv_fnd_date), cv_null_code);                --�\�񔄏㋒�_�L���J�n��
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.resource_no, 1, 5), cv_date_null)             || cv_dqu;  --�S���c�ƈ��R�[�h
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.next_resource_no, 1, 5), cv_date_null)        || cv_dqu;  --�����S���c�ƈ��R�[�h
--      lv_output_str := lv_output_str || cv_comma || NVL(TO_CHAR(cust_data_rec.next_resource_s_date, cv_fnd_month), cv_null_code);                 --�����S���c�ƈ��K�p��
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.route_no, 1, 7), cv_date_null)                || cv_dqu;  --���[�g�R�[�h
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.next_route_no, 1, 7), cv_date_null)           || cv_dqu;  --�\�񃋁[�g�R�[�h
--      lv_output_str := lv_output_str || cv_comma || NVL(TO_CHAR(cust_data_rec.next_route_s_date, cv_fnd_month), cv_null_code);                    --�\�񃋁[�g�R�[�h�K�p��
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.customer_class_code, 1, 2), cv_date_null)     || cv_dqu;  --�ڋq�敪
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(lv_coordinated_date, cv_date_null)                                  || cv_dqu;  --�X�V����
----
--      --������o��
--      BEGIN
--        --CSV�t�@�C���o��
--        UTL_FILE.PUT_LINE(io_file_handler,lv_output_str);
--        --�R���J�����g�o��
--        --FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_output_str);
--      EXCEPTION
--        WHEN UTL_FILE.WRITE_ERROR THEN  --*** �t�@�C���������݃G���[ ***
--          lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
--                                                cv_write_err_msg,
--                                                cv_ng_word,
--                                                cv_err_cust_code_msg,
--                                                cv_ng_data,
--                                                cust_data_rec.account_number);
--          lv_errbuf  := lv_errmsg;
--        RAISE write_failure_expt;
--      END;
--      --�o�͌����J�E���g
--      ln_output_cnt := ln_output_cnt + 1;
----
--      --�ϐ�������
--      lv_output_str := NULL;
--      lv_note_str   := NULL;
---- 2009/06/09 Ver1.4 add start by Yutaka.Kuboshima
--      lv_customer_name          := NULL;
--      lv_customer_name_kana     := NULL;
--      lv_address1               := NULL;
--      lv_address_lines_phonetic := NULL;
---- 2009/06/09 Ver1.4 add end by Yutaka.Kuboshima
----
--    END LOOP cust_for_loop;
--
--  ��modify start
    -- �p�����[�^������(FROM)
    -- '000000'��t����'YYYYMMDDHH24MISS'�^�ɕϊ�
    ld_proc_date_from := TO_DATE(NVL(REPLACE(iv_proc_date_from, cv_hur_sls, cv_date_null), gv_process_date ) || cv_min_time, cv_fnd_max_date);
    -- �p�����[�^������(TO)
    -- '235959'��t����'YYYYMMDDHH24MISS'�^�ɕϊ�
    ld_proc_date_to   := TO_DATE(NVL(REPLACE(iv_proc_date_to, cv_hur_sls, cv_date_null), gv_process_date ) || cv_max_time, cv_fnd_max_date);
    -- ���Ɩ����P��
    ld_process_date_next_f := TRUNC(ADD_MONTHS(gd_process_date + 1, 1), cv_trunc_mm);
    -- ���Ɩ����ŏI��
    ld_process_date_next_l := LAST_DAY(ADD_MONTHS(gd_process_date + 1, 1));
    --�����ΏۘA�g�ڋq�擾�J�[�\�����[�v
    << def_cust_loop >>
    FOR def_cust_rec IN def_cust_cur(ld_proc_date_from,
                                     ld_proc_date_to)
    LOOP
      --HHT�A�gIF�f�[�^�쐬�J�[�\�����[�v
      << cust_for_loop >>
      FOR cust_data_rec IN cust_data_cur(def_cust_rec.customer_id,
                                         ld_process_date_next_f,
                                         ld_process_date_next_l)
      LOOP
        --�m�[�g���t��
        << note_for_loop >>
        FOR  note_data_rec IN note_data_cur(cust_data_rec.party_id)
        LOOP
          lv_note_work := TO_CHAR(note_data_rec.last_update_date, cv_fnd_slash_date) || cv_hur_sps || note_data_rec.notes;
          --�m�[�g��2000�o�C�g�ɒB�������_�ŏ����𒆒f����B
          IF ( LENGTHB(lv_note_str || lv_note_work) <= cn_note_lenb ) THEN
            lv_note_str := lv_note_str || lv_note_work || cv_ver_line;
          ELSE
            EXIT;
          END IF;
        END LOOP note_for_loop;
        --�c���폜
        lv_note_str := SUBSTRB(lv_note_str, 1, LENGTHB(lv_note_str) - 1);
--
        -- ���㋒�_�ɐݒ肳��Ă��鋒�_���������܂��B
        OPEN serch_base_cur(cust_data_rec.sale_base_code);
        FETCH serch_base_cur INTO serch_base_rec;
        CLOSE serch_base_cur;
        -- ���㋒�_�ɐݒ肳��Ă���S�ݓXHHT�敪'1'�̏ꍇ
        IF (NVL(serch_base_rec.dept_hht_div, 0) = cv_dept_div_mult) THEN
          -- ���㋒�_�R�[�h���Ǘ������_�R�[�h�ɐݒ�
          cust_data_rec.sale_base_code      := serch_base_rec.management_base_code;
        END IF;
        -- �ϐ�������
        serch_base_rec := NULL;
        -- �O�����㋒�_�ɐݒ肳��Ă��鋒�_���������܂��B
        OPEN serch_base_cur(cust_data_rec.past_sale_base_code);
        FETCH serch_base_cur INTO serch_base_rec;
        CLOSE serch_base_cur;
        -- �O�����㋒�_�ɐݒ肳��Ă���S�ݓXHHT�敪'1'�̏ꍇ
        IF (NVL(serch_base_rec.dept_hht_div, 0) = cv_dept_div_mult) THEN
          -- �O�����㋒�_�R�[�h���Ǘ������_�R�[�h�ɐݒ�
          cust_data_rec.past_sale_base_code := serch_base_rec.management_base_code;
        END IF;
        -- �ϐ�������
        serch_base_rec := NULL;
        -- �\�񔄏㋒�_�ɐݒ肳��Ă��鋒�_���������܂��B
        OPEN serch_base_cur(cust_data_rec.rsv_sale_base_code);
        FETCH serch_base_cur INTO serch_base_rec;
        CLOSE serch_base_cur;
        -- �\�񔄏㋒�_�ɐݒ肳��Ă���S�ݓXHHT�敪'1'�̏ꍇ
        IF (NVL(serch_base_rec.dept_hht_div, 0) = cv_dept_div_mult) THEN
          -- �\�񔄏㋒�_�R�[�h���Ǘ������_�R�[�h�ɐݒ�
          cust_data_rec.rsv_sale_base_code  := serch_base_rec.management_base_code;
        END IF;
-- Ver1.15 Add Start
        -- �ڋq�K�w�r���[���[�������敪���擾
        lt_tax_rounding_rule := NULL;
        BEGIN
          SELECT xchv.bill_tax_round_rule                                      tax_rounding_rule           --�ŋ��[������
          INTO   lt_tax_rounding_rule
          FROM   xxcos_cust_hierarchy_v xchv
          WHERE  xchv.ship_account_id = def_cust_rec.customer_id
          ;
          cust_data_rec.tax_rounding_rule := lt_tax_rounding_rule;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
             NULL;
          -- ���̑���O
          WHEN OTHERS THEN
            RAISE global_api_others_expt;
        END;
-- Ver1.15 Add End
        -- �ϐ�������
        serch_base_rec := NULL;
        -- ===============================
        -- �o�͒l�ݒ�
        -- ===============================
        -- �ڋq���̐ݒ�
        lv_customer_name            := xxcso_util_common_pkg.conv_multi_byte(cust_data_rec.party_name);
        -- �ڋq���J�i�ݒ�
        lv_customer_name_kana       := xxccp_common_pkg.chg_double_to_single_byte(cust_data_rec.org_name_phonetic);
        -- ���p�ϊ��s���������݂���ꍇ
        IF (LENGTH(lv_customer_name_kana) <> LENGTHB(lv_customer_name_kana)) THEN
          lv_customer_name_kana := cv_single_byte_err1;
        END IF;
        -- �Z���P�ݒ�
        lv_address1                 := xxcso_util_common_pkg.conv_multi_byte(cust_data_rec.address1);
        -- �d�b�ԍ��ݒ�
        lv_address_lines_phonetic   := xxccp_common_pkg.chg_double_to_single_byte(cust_data_rec.address_lines_phonetic);
        -- ���p�ϊ��s���������݂���ꍇ
        IF (LENGTH(lv_address_lines_phonetic) <> LENGTHB(lv_address_lines_phonetic)) THEN
          lv_address_lines_phonetic := cv_single_byte_err2;
        END IF;
        --�o�͕�����쐬
        lv_output_str := lv_output_str || cv_dqu   || NVL(SUBSTRB(cust_data_rec.account_number, 1, 9), cv_date_null)                    || cv_dqu;  --�ڋq�R�[�h
-- 2011/10/18 Ver1.11 E_�{�ғ�_08440 mod start by Yasuhiro.Horikawa
--        lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(lv_customer_name, 1, 50), cv_date_null)                     || cv_dqu;  --�ڋq����
        lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(lv_customer_name, 1, 100), cv_date_null)                     || cv_dqu;  --�ڋq����
-- 2011/10/18 Ver1.11 E_�{�ғ�_08440 mod end by Yasuhiro.Horikawa
        lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.tax_div, 1, 1), cv_date_null)                 || cv_dqu;  --����ŋ敪
        lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.vd_contract_form, 1, 1), cv_date_null)        || cv_dqu;  --�x���_�_��`��
        lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.mode_div, 1, 1), cv_date_null)                || cv_dqu;  --�ԗl�敪
        lv_output_str := lv_output_str || cv_comma || NVL(TO_CHAR(cust_data_rec.final_tran_date, cv_fnd_date), cv_null_code);                       --�ŏI�����
        lv_output_str := lv_output_str || cv_comma || NVL(TO_CHAR(cust_data_rec.final_call_date, cv_fnd_date), cv_null_code);                       --�ŏI�K���
        lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.entrust_dest_flg, 1, 1), cv_date_null)        || cv_dqu;  --�a���攻��t���O
        lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cv_cdvd_code, 1, 1), cv_date_null)                          || cv_dqu;  --�J�[�h�x���_�敪
        lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.vd_cust_class_cd, 1, 1), cv_date_null)        || cv_dqu;  --�u�c�ڋq�敪
        lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.duns_number_c, 1, 2), cv_date_null)           || cv_dqu;  --�ڋq�X�e�[�^�X�R�[�h
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(NVL(TO_CHAR(cust_data_rec.change_amount), cv_null_code), 1, 5);                       --��K
        lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(lv_customer_name_kana, 1, 30), cv_date_null)                || cv_dqu;  --�ڋq���J�i
        lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(lv_address1, 1, 60), cv_date_null)                          || cv_dqu;  --�Z���P
        lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(lv_address_lines_phonetic, 1, 15), cv_date_null)            || cv_dqu;  --�d�b�ԍ�
        lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(lv_note_str, 1, 2000), cv_date_null)                        || cv_dqu;  --�m�[�g
        lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.sale_base_code, 1, 4), cv_date_null)          || cv_dqu;  --���㋒�_�R�[�h
        lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.past_sale_base_code, 1, 4), cv_date_null)     || cv_dqu;  --�O�����㋒�_�R�[�h
        lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.rsv_sale_base_code, 1, 4), cv_date_null)      || cv_dqu;  --�\�񔄏㋒�_�R�[�h
        lv_output_str := lv_output_str || cv_comma || NVL(TO_CHAR(cust_data_rec.rsv_sale_base_act_date, cv_fnd_date), cv_null_code);                --�\�񔄏㋒�_�L���J�n��
        lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.resource_no, 1, 5), cv_date_null)             || cv_dqu;  --�S���c�ƈ��R�[�h
        lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.next_resource_no, 1, 5), cv_date_null)        || cv_dqu;  --�����S���c�ƈ��R�[�h
        lv_output_str := lv_output_str || cv_comma || NVL(TO_CHAR(cust_data_rec.next_resource_s_date, cv_fnd_month), cv_null_code);                 --�����S���c�ƈ��K�p��
        lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.route_no, 1, 7), cv_date_null)                || cv_dqu;  --���[�g�R�[�h
        lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.next_route_no, 1, 7), cv_date_null)           || cv_dqu;  --�\�񃋁[�g�R�[�h
        lv_output_str := lv_output_str || cv_comma || NVL(TO_CHAR(cust_data_rec.next_route_s_date, cv_fnd_month), cv_null_code);                    --�\�񃋁[�g�R�[�h�K�p��
        lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.customer_class_code, 1, 2), cv_date_null)     || cv_dqu;  --�ڋq�敪
        lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(lv_coordinated_date, cv_date_null)                                  || cv_dqu;  --�X�V����
-- 2011/05/16 Ver1.10 E_�{�ғ�_07429 add start by Shigeto.Niki
        lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.vendor_offset_time, 1, 4), cv_date_null)      || cv_dqu;  --���̋@�I�t�Z�b�g����
-- 2011/05/16 Ver1.10 E_�{�ғ�_07429 add end by Shigeto.Niki
-- Ver1.13 add start
        lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.business_low_type, 1, 2), cv_date_null)       || cv_dqu;  --�ƑԃR�[�h
-- Ver1.13 add end
-- Ver1.14 add start
        lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.tax_rounding_rule, 1, 7), cv_date_null)       || cv_dqu;  --�ŋ��[������
-- Ver1.14 add end
--
        --������o��
        BEGIN
          --CSV�t�@�C���o��
          UTL_FILE.PUT_LINE(io_file_handler,lv_output_str);
          --�R���J�����g�o��
          --FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_output_str);
        EXCEPTION
          WHEN UTL_FILE.WRITE_ERROR THEN  --*** �t�@�C���������݃G���[ ***
            lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                                  cv_write_err_msg,
                                                  cv_ng_word,
                                                  cv_err_cust_code_msg,
                                                  cv_ng_data,
                                                  cust_data_rec.account_number);
            lv_errbuf  := lv_errmsg;
          RAISE write_failure_expt;
        END;
        --�o�͌����J�E���g
        ln_output_cnt := ln_output_cnt + 1;
--
        --�ϐ�������
        lv_output_str := NULL;
        lv_note_str   := NULL;
        lv_customer_name          := NULL;
        lv_customer_name_kana     := NULL;
        lv_address1               := NULL;
        lv_address_lines_phonetic := NULL;
--
      END LOOP cust_for_loop;
    END LOOP def_cust_loop;
-- 2009/08/24 Ver1.5 modify end by Yutaka.Kuboshima
--
    gn_target_cnt := ln_output_cnt;
    gn_normal_cnt := ln_output_cnt;
--
    --�Ώۃf�[�^0��
    IF (ln_output_cnt = 0) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                            cv_no_data_msg);
      lv_errbuf := lv_errmsg;
      RAISE no_date_expt;
    END IF;
--
  EXCEPTION
    WHEN no_date_expt THEN                             --*** �Ώۃf�[�^�Ȃ� (����I��) ***
      ov_retcode := cv_status_normal;
      --�Ώۃf�[�^��0���̎��A������0���Œ�Ƃ���
      gn_target_cnt := 0;
      gn_error_cnt  := 0;
      --�R���J�����g�o��
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_errmsg);
      --���O�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf
      );
    WHEN write_failure_expt THEN                       --*** CSV�f�[�^�o�̓G���[ ***
-- 2009/04/13 Ver1.2 add start by Yutaka.Kuboshima
      IF (serch_base_cur%ISOPEN) THEN
        CLOSE serch_base_cur;
      END IF;
-- 2009/04/13 Ver1.2 add end by Yutaka.Kuboshima
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      --�Ώۃf�[�^��0���̎��A�G���[������0���Œ�Ƃ���
      gn_target_cnt := 0;
      gn_error_cnt  := 0;
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
  END output_cust_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_proc_date_from         IN  VARCHAR2,     --�R���J�����g�E�p�����[�^������(FROM)
    iv_proc_date_to           IN  VARCHAR2,     --�R���J�����g�E�p�����[�^������(TO)
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
    gn_target_cnt     := 0;
    gn_normal_cnt     := 0;
    gn_error_cnt      := 0;
    gn_warn_cnt       := 0;
--
    --�p�����[�^�o��
    --�V�K�o�^�����͍X�V���i�J�n�j
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_xxcmm_msg_kbn
                    ,iv_name         => cv_parameter_msg
                    ,iv_token_name1  => cv_param
                    ,iv_token_value1 => cv_proc_date_from
                    ,iv_token_name2  => cv_value
                    ,iv_token_value2 => iv_proc_date_from
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --�V�K�o�^�����͍X�V���i�I���j
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_xxcmm_msg_kbn
                    ,iv_name         => cv_parameter_msg
                    ,iv_token_name1  => cv_param
                    ,iv_token_value1 => cv_proc_date_to
                    ,iv_token_name2  => cv_value
                    ,iv_token_value2 => iv_proc_date_to
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -- ===============================
    -- ��������(A-1)
    -- ===============================
    init(
      iv_proc_date_from   -- �R���J�����g�E�p�����[�^������(FROM)
      ,iv_proc_date_to    -- �R���J�����g�E�p�����[�^������(TO)
      ,lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    --���������G���[���͏����𒆒f
    IF (lv_retcode = cv_status_error) THEN
      --�G���[����
      RAISE global_process_expt;
    END IF;
--
    --I/F�t�@�C�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_xxccp_msg_kbn
                    ,iv_name         => cv_file_name_msg
                    ,iv_token_name1  => cv_file_name
                    ,iv_token_value1 => gv_out_file_file
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
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
    output_cust_data(
      iv_proc_date_from        -- �R���J�����g�E�p�����[�^������(FROM)
      ,iv_proc_date_to         -- �R���J�����g�E�p�����[�^������(TO)
      ,lf_file_handler         -- �t�@�C���n���h��
      ,lv_errbuf               -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode              -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- ===============================
    -- �I������(A-5)
    -- ===============================
    BEGIN
      -- �t�@�C���N���[�Y����
      IF (UTL_FILE.IS_OPEN(lf_file_handler)) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(lf_file_handler);
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        IF (lv_retcode = cv_status_error) THEN
          -- �R���J�����g���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_errbuf --�G���[���b�Z�[�W
          );
        END IF;
        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_emsg_file_close,
                                              cv_sqlerrm,
                                              SQLERRM);
        lv_errbuf := lv_errmsg;
        RAISE fclose_err_expt;
    END;
    IF (lv_retcode = cv_status_error) THEN
      -- �G���[����
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    WHEN fclose_err_expt THEN                           --*** �t�@�C���N���[�Y�G���[ ***
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
    retcode                   OUT VARCHAR2,     --���^�[���E�R�[�h    --# �Œ� #
    iv_proc_date_from         IN  VARCHAR2,     -- �R���J�����g�E�p�����[�^������(FROM)
    iv_proc_date_to           IN  VARCHAR2      -- �R���J�����g�E�p�����[�^������(TO)
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
      iv_proc_date_from          --�R���J�����g�E�p�����[�^������(FROM)
      ,iv_proc_date_to           --�R���J�����g�E�p�����[�^������(TO)
      ,lv_errbuf                 --�G���[�E���b�Z�[�W           --# �Œ� #
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
END XXCMM003A19C;
/
