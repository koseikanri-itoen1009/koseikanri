CREATE OR REPLACE PACKAGE BODY XXCMM003A18C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2009. All rights reserved.
 *
 * Package Name     : XXCMM003A18C(body)
 * Description      : ���n�A�gIF�f�[�^�쐬
 * MD.050           : MD050_CMM_003_A18_���n�A�gIF�f�[�^�쐬
 * Version          : 1.7
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  file_open              �t�@�C���I�[�v������(A-2)
 *  output_cust_data       �����Ώۃf�[�^���o����(A-3)�ECSV�t�@�C���o�͏���(A-4)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��(A-5 �I������)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/28    1.0   Takuya Kaihara   �V�K�쐬
 *  2009/02/23    1.1   Takuya Kaihara   �t�@�C���N���[�Y�����C��
 *  2009/03/09    1.2   Takuya Kaihara   �v���t�@�C���l���ʉ�
 *  2009/05/12    1.3   Yutaka.Kuboshima ��QT1_0176,T1_0831�̑Ή�
 *  2009/05/21    1.4   Yutaka.Kuboshima ��QT1_1131�̑Ή�
 *  2009/05/29    1.5   Yutaka.Kuboshima ��QT1_1263�̑Ή�
 *  2009/06/09    1.6   Yutaka.Kuboshima ��QT1_1364�̑Ή�
 *  2009/09/30    1.7   Yutaka.Kuboshima ��Q0001350�̑Ή�
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
  no_date_err_expt               EXCEPTION; --�Ώۃf�[�^0��
  write_failure_expt             EXCEPTION; --CSV�f�[�^�o�̓G���[
  fclose_err_expt                EXCEPTION; --�t�@�C���N���[�Y�G���[
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                CONSTANT VARCHAR2(12)  := 'XXCMM003A18C';      --�p�b�P�[�W��
  cv_comma                   CONSTANT VARCHAR2(1)   := ',';
  cv_dqu                     CONSTANT VARCHAR2(1)   := '"';                 --�����񊇂�
--
  cv_trans_date              CONSTANT VARCHAR2(20)  := 'YYYYMMDDHH24MISS';  --�A�g���t����
  cv_fnd_date                CONSTANT VARCHAR2(10)  := 'YYYYMMDD';          --���t����
  cv_fnd_slash_date          CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';        --���t����(YYYY/MM/DD)
--
  --���b�Z�[�W
  cv_file_name_msg           CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-05102';  --�t�@�C�����m�[�g
  cv_no_parameter            CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90008';  -- �R���J�����g���̓p�����[�^�Ȃ�
--
  --�G���[���b�Z�[�W
  cv_profile_err_msg         CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00002';  --�v���t�@�C���擾�G���[
  cv_file_path_invalid_msg   CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00003';  --�t�@�C���p�X�s���G���[
  cv_exist_err_msg           CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00010';  --CSV�t�@�C�����݃`�F�b�N
  cv_write_err_msg           CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00009';  --CSV�f�[�^�o�̓G���[
  cv_no_data_err_msg         CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00001';  --�Ώۃf�[�^����
  cv_file_close_err_msg      CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00489';  --�t�@�C���N���[�Y�G���[
  --�g�[�N��
  cv_ng_profile              CONSTANT VARCHAR2(10)  := 'NG_PROFILE';        --�v���t�@�C���擾���s�g�[�N��
  cv_file_name               CONSTANT VARCHAR2(9)   := 'FILE_NAME';         --�t�@�C�����g�[�N��
  cv_sqlerrm                 CONSTANT VARCHAR2(9)   := 'SQLERRM';           --�t�@�C���N���[�Y
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_process_date VARCHAR2(20);
  gn_nodate_err   NUMBER;
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
    cv_out_file_dir  CONSTANT VARCHAR2(30) := 'XXCMM1_JYOHO_OUT_DIR';         --XXCMM:���n(OUTBOUND)�A�g�pCSV�t�@�C���o�͐�
    cv_out_file_file CONSTANT VARCHAR2(30) := 'XXCMM1_003A18_OUT_FILE_FIL';   --XXCMM: ���n�A�gIF�f�[�^�쐬�pCSV�t�@�C����
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
    IF (lv_file_chk) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                            cv_exist_err_msg);
      lv_errbuf := lv_errmsg;
      RAISE init_err_expt;
    END IF;
--
    -- �Ɩ����t�擾����
    gv_process_date := TO_CHAR(xxccp_common_pkg2.get_process_date, cv_fnd_date);
--
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
      --�t�@�C���I�[�v���G���[���A�Ώی����A�G���[������1���Œ�Ƃ���
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
   * Description      : �����Ώۃf�[�^���o����(A-3)�ECSV�t�@�C���o�͏���(A-4)
   ***********************************************************************************/
  PROCEDURE output_cust_data(
    io_file_handler         IN OUT UTL_FILE.FILE_TYPE,  --   �t�@�C���n���h��
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
    -- *** ���[�J���萔 ***
    cv_bill_to            CONSTANT VARCHAR2(7)     := 'BILL_TO';                --�g�p�ړI�E������
    cv_ship_to            CONSTANT VARCHAR2(7)     := 'SHIP_TO';                --�g�p�ړI�E�o�א�
    cv_cust_base          CONSTANT VARCHAR2(1)     := '1';                      --�ڋq�敪�E���_
    cv_edi_mult           CONSTANT VARCHAR2(2)     := '18';                     --�ڋq�敪�E�d�c�h�`�F�[���X
    cv_dep_dist           CONSTANT VARCHAR2(2)     := '19';                     --�ڋq�敪�E�S�ݓX�`��
    cv_eff_last_date      CONSTANT VARCHAR2(15)    := '99991231';               --�L����_��
    cv_y_flag             CONSTANT VARCHAR2(1)     := 'Y';                      --�L���t���OY
    cv_a_flag             CONSTANT VARCHAR2(1)     := 'A';                      --�L���t���OA
    cv_language_ja        CONSTANT VARCHAR2(2)     := 'JA';                     --����(���{��)
    cv_gyotai_syo         CONSTANT VARCHAR2(30)    := 'XXCMM_CUST_GYOTAI_SHO';  --�Ƒ�(������)
    cv_gyotai_chu         CONSTANT VARCHAR2(30)    := 'XXCMM_CUST_GYOTAI_CHU';  --�Ƒ�(������)
    cv_gyotai_dai         CONSTANT VARCHAR2(30)    := 'XXCMM_CUST_GYOTAI_DAI';  --�Ƒ�(�啪��)
    cv_zero_data          CONSTANT VARCHAR2(1)     := '0';                      --�T�C�g���l
-- 2009/05/12 Ver1.3 ��QT1_0176 add start by Yutaka.Kuboshima
    cv_organization       CONSTANT VARCHAR2(30)    := 'ORGANIZATION';           --�I�u�W�F�N�g�^�C�v(�g�D)
    cv_yosin_kbn          CONSTANT VARCHAR2(2)     := '13';                     --�ڋq�敪�E�^�M�Ǘ���ڋq
    cv_urikake_kbn        CONSTANT VARCHAR2(2)     := '14';                     --�ڋq�敪�E���|�Ǘ���ڋq
    cv_seisan_ou          CONSTANT VARCHAR2(20)    := 'ITOE-OU-MFG';            --�c�ƒP��(���YOU)
    cv_site_use_code      CONSTANT VARCHAR2(20)    := 'SITE_USE_CODE';          --�Q�ƃ^�C�v(�g�p�ړI)
    cv_other_to           CONSTANT VARCHAR2(10)    := 'OTHER_TO';               --�g�p�ړI�E���̑�
-- 2009/05/12 Ver1.3 ��QT1_0176 add end by Yutaka.Kuboshima
--
    cv_comp_code          CONSTANT VARCHAR2(3)     := '001';                    --��ЃR�[�h
    cv_auto_ex_flag       CONSTANT VARCHAR2(1)     := '2';                      --�����o�W�t���O�E�֘A�ڋq
    cv_ng_word            CONSTANT VARCHAR2(7)     := 'NG_WORD';                --CSV�o�̓G���[�g�[�N���ENG_WORD
    cv_ng_data            CONSTANT VARCHAR2(7)     := 'NG_DATA';                --CSV�o�̓G���[�g�[�N���ENG_DATA
    cv_err_cust_code_msg  CONSTANT VARCHAR2(20)    := '�ڋq�R�[�h';             --CSV�o�̓G���[������
--
-- 2009/06/09 Ver1.6 add start by Yutaka.Kuboshima
    cv_single_byte_err1   CONSTANT VARCHAR2(30)    := '�ݶ��װ';                --���p�G���[���̃_�~�[�l1
    cv_single_byte_err2   CONSTANT VARCHAR2(30)    := '99-9999-9999';           --���p�G���[���̃_�~�[�l2
-- 2009/06/09 Ver1.6 add end by Yutaka.Kuboshima
--
    -- *** ���[�J���ϐ� ***
    lv_header_str                  VARCHAR2(2000)  := NULL;                     --�w�b�_���b�Z�[�W�i�[�p�ϐ�
    lv_output_str                  VARCHAR2(4095)  := NULL;                     --�o�͕�����i�[�p�ϐ�
    ln_output_cnt                  NUMBER          := 0;                        --�o�͌���
    lv_coordinated_date            VARCHAR2(30)    := NULL;                     --�A�g���t�擾
    lv_relate_cust_class           VARCHAR2(30)    := NULL;                     --�֘A����
--
    lv_bill_number                 hz_cust_accounts.account_number%TYPE;        --�ڋq�R�[�h(A3-2)
    ln_bill_cust_id                hz_cust_accounts.cust_account_id%TYPE;       --�ڋqID(A3-2)
    lv_bill_location               hz_cust_site_uses.location%TYPE;             --���Ə�(A3-2)
    lv_pay_account_num             hz_cust_accounts.account_number%TYPE;        --�ڋq�R�[�h(A3-3-1)
    ln_pay_cust_account_id         hz_cust_accounts.cust_account_id%TYPE;       --�ڋqID(A3-3-1)
    lv_par_account_num             hz_cust_accounts.account_number%TYPE;        --�ڋq�R�[�h(A3-3-2)
    lv_relate_account_num          hz_cust_accounts.account_number%TYPE;        --�ڋq�R�[�h(A3-3-2)
--
-- 2009/06/09 Ver1.6 add start by Yutaka.Kuboshima
    lv_customer_name               VARCHAR2(1500);                               --�ڋq����
    lv_customer_name_kana          VARCHAR2(1500);                               --�ڋq���J�i
    lv_customer_name_ryaku         VARCHAR2(1500);                               --�ڋq������
    lv_state                       VARCHAR2(1500);                               --�s���{��
    lv_city                        VARCHAR2(1500);                               --�s�E��
    lv_address1                    VARCHAR2(1500);                               --�Z���P
    lv_address2                    VARCHAR2(1500);                               --�Z���Q
    lv_fax                         VARCHAR2(1500);                               --FAX�ԍ�
    lv_address_lines_phonetic      VARCHAR2(1500);                              --�d�b�ԍ�
    lv_manager_name                VARCHAR2(1500);                              --�X����
    lv_rest_emp_name               VARCHAR2(1500);                              --�S���ҋx��
    lv_mc_conf_info                VARCHAR2(1500);                              --MC:�������
    lv_mc_business_talk_details    VARCHAR2(1500);                              --MC:���k�o��
-- 2009/06/09 Ver1.6 add end by Yutaka.Kuboshima
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- ���n�A�gIF�f�[�^�쐬�J�[�\��
    CURSOR cust_data_cur
    IS
      SELECT  hca.account_number                             account_number,              --�ڋq�R�[�h
              hp.party_number                                party_number,                --�p�[�e�B�ԍ�
              hp.party_name                                  party_name,                  --�ڋq����
              hopera.resource_no                             resource_no,                 --�S���c�ƈ��R�[�h
              xca.sale_base_code                             sale_base_code,              --���㋒�_�R�[�h
              xca.past_sale_base_code                        past_charge_base_code,       --�S�����_�R�[�h(��)
              hopera.resource_s_date                         resource_s_date,             --�S���ύX��
              xca.cnvs_business_person                       cnvs_business_person,        --�l���c�ƈ��R�[�h
              xca.cnvs_base_code                             cnvs_base_code,              --�l�����_�R�[�h
              xca.intro_business_person                      intro_business_person,       --�Љ�c�ƈ��R�[�h
              xca.intro_base_code                            intro_base_code,             --�Љ�_�R�[�h
              hopero.route_no                                route_no,                    --���[�g�m�n
              xca.business_low_type                          business_low_type,           --�Ƒԑ啪��
              flvgc.lookup_code                              lookup_code_c,               --�ƑԒ�����
              flvgd.lookup_code                              lookup_code_s,               --�Ƒԏ�����
              xca.delivery_form                              delivery_form,               --�z���`��
              xca.establishment_location                     establishment_location,      --�ݒu���P�[�V����
              xca.open_close_div                             open_close_div,              --�I�[�v���E�N���[�Y
              hp.duns_number_c                               duns_number_c,               --�ڋq�X�e�[�^�X�R�[�h
              hp.attribute5                                  mc_importance_deg,           --�l�b�d�v�x
              hp.attribute4                                  mc_hot_deg,                  --�l�b�g�n�s�x
              LPAD(TO_CHAR(rtmin.due_months_forward),2,cv_zero_data)  due_months_forward, --�T�C�g
              hca.creation_date                              creation_date,               --�o�^��
              xca.start_tran_date                            start_tran_date,             --����J�n��
              xca.new_point                                  new_point,                   --�V�K�|�C���g
              xca.stop_approval_reason                       stop_approval_reason,        --���~���R�敪
              xca.stop_approval_date                         stop_approval_date,          --���~�N����
              hca.account_name                               account_name,                --�ڋq������
              hp.organization_name_phonetic                  organization_name_phonetic,  --�ڋq���J�i
              xca.receiv_base_code                           receiv_base_code,            --�������_�R�[�h
              xca.bill_base_code                             bill_base_code,              --�������_(����)�R�[�h
              rtsum.name                                     termtl_name,                 --�x������(�����E�����E�T�C�g)
              xca.delivery_chain_code                        delivery_chain_code,         --�[�i�`�F�[���b�c
              xca.sales_chain_code                           sales_chain_code,            --�̔��`�F�[���b�c
              xca.intro_chain_code1                          intro_chain_code1,           --�Љ�p�P
              xca.intro_chain_code2                          intro_chain_code2,           --�Љ�p�Q
              xca.policy_chain_code                          policy_chain_code,           --�c�Ɛ����p
              xca.store_code                                 store_code,                  --�X�܃R�[�h
              xca.tax_div                                    tax_div,                     --����ŋ敪
-- 2009/10/01 Ver1.7 ��Q0001350 modify start by Yutaka.Kuboshima
--              hcsu.attribute1                                invoice_class,               --���������s�敪
              xca.invoice_printing_unit                      invoice_printing_unit,       --����������P��
-- 2009/10/01 Ver1.7 ��Q0001350 modify end by Yutaka.Kuboshima
              hcsu.attribute7                                invoice_process_class,       --���������敪
              hca.account_number                             corporate_number,            --�@�l�R�[�h
              xmc.base_code                                  base_code,                   --�{���S�����_�R�[�h
              xmc.credit_limit                               credit_limit,                --�^�M���x�g
              xca.vist_target_div                            vist_target_div,             --�K��Ώۋ敪
              hca.customer_class_code                        customer_class_code,         --�ڋq�敪
              xca.cnvs_date                                  cnvs_date,                   --�ڋq�l����
              xca.final_tran_date                            final_tran_date,             --�ŏI�����
              xca.final_call_date                            final_call_date,             --�ŏI�K���
              xca.change_amount                              change_amount,               --�ޑK
              xca.torihiki_form                              torihiki_form,               --����`��
              hl.postal_code                                 postal_code,                 --�X�֔ԍ�
              hl.state                                       state,                       --�s���{��
              hl.city                                        city,                        --�s�E��
              hl.address1                                    address1,                    --�Z��1
              hl.address2                                    address2,                    --�Z��2
              hl.address3                                    address3,                    --�n��R�[�h
              hl.address_lines_phonetic                      address_lines_phonetic,      --�d�b�ԍ�
              xca.cust_store_name                            cust_store_name,             --�ڋq�X�ܖ���
              xca.torihikisaki_code                          torihikisaki_code,           --�����R�[�h
              xca.industry_div                               industry_div,                --�Ǝ�
              xca.selling_transfer_div                       selling_transfer_div,        --������ѐU��
              xca.center_edi_div                             center_edi_div,              --�Z���^�[EDI�敪
              xca.past_sale_base_code                        past_sale_base_code,         --�O�����㋒�_�R�[�h
              xca.rsv_sale_base_act_date                     rsv_sale_base_act_date,      --�\�񔄏㋒�_�L���J�n��
              xca.rsv_sale_base_code                         rsv_sale_base_code,          --�\�񔄏㋒�_�R�[�h
              xca.delivery_base_code                         delivery_base_code,          --�[�i���_�R�[�h
              xca.sales_head_base_code                       sales_head_base_code,        --�̔���{���S�����_
              xca.vendor_machine_number                      vendor_machine_number,       --�����̔��@�ԍ�
              xca.rate                                       rate,                        --�����u�c�|��
              xca.conclusion_day1                            conclusion_day1,             --�����v�Z���ߓ��P
              xca.conclusion_day2                            conclusion_day2,             --�����v�Z���ߓ��Q
              xca.conclusion_day3                            conclusion_day3,             --�����v�Z���ߓ��R
              xca.contractor_supplier_code                   contractor_supplier_code,    --�_��Ҏd����R�[�h
              xca.bm_pay_supplier_code1                      bm_pay_supplier_code1,       --�Љ�҂a�l�x���d����R�[�h�P
              xca.bm_pay_supplier_code2                      bm_pay_supplier_code2,       --�Љ�҂a�l�x���d����R�[�h�Q
              xca.wholesale_ctrl_code                        wholesale_ctrl_code,         --�≮�Ǘ��R�[�h
              xca.ship_storage_code                          ship_storage_code,           --�o�׌��ۊǏꏊ(EDI)
              xca.chain_store_code                           chain_store_code,            --�`�F�[���X�R�[�h(EDI)
              xca.delivery_order                             delivery_order,              --�z����(EDI�j
              xca.edi_district_code                          edi_district_code,           --EDI�n��R�[�h(EDI)
              xca.edi_district_name                          edi_district_name,           --EDI�n�於(EDI�j
              xca.edi_district_kana                          edi_district_kana,           --EDI�n�於�J�i(EDI)
              xca.tsukagatazaiko_div                         tsukagatazaiko_div,          --�ʉߍ݌Ɍ^�敪(EDI)
              xca.handwritten_slip_div                       handwritten_slip_div,        --EDI�菑�`�[�`���敪
              xca.deli_center_code                           deli_center_code,            --EDI�[�i�Z���^�[�R�[�h
              xca.deli_center_name                           deli_center_name,            --EDI�[�i�Z���^�[��
              xca.edi_forward_number                         edi_forward_number,          --EDI�`���ǔ�
-- 2009/05/12 Ver1.3 ��QT1_0176 modify start by Yutaka.Kuboshima
--              arvw.name                                      receipt_methods_name,        --�x�����@��
--              hcsu.site_use_code                             site_use_code,               --�g�p�ړI
              TO_MULTI_BYTE(arvw.name)                       receipt_methods_name,        --�x�����@��
              flvsuc.meaning                                 site_use_code,               --�g�p�ړI
-- 2009/05/12 Ver1.3 ��QT1_0176 modify end by Yutaka.Kuboshima
              rtsum2.name                                    payment_term2,               --��2�x������
              rtsum3.name                                    payment_term3,               --��3�x������
              hcsu.attribute4                                ar_invoice_code,             --���|�R�[�h�P(������)
              hcsu.attribute5                                ar_location_code,            --���|�R�[�h�Q(���Ə�)
              hcsu.attribute6                                ar_others_code,              --���|�R�[�h�R(���̑�)
              hcsu.attribute8                                invoice_sycle,               --���������s�T�C�N��
              hp.attribute1                                  manager_name,                --�X����
              hp.attribute3                                  rest_emp_name,               --�S���ҋx��
              hp.attribute6                                  mc_conf_info,                --MC:�������
              hp.attribute7                                  mc_business_talk_details,    --MC:���k�o��
              hps.party_site_number                          party_site_number,           --�p�[�e�B�T�C�g�ԍ�
              xca.established_site_name                      established_site_name,       --�ݒu�於
              hp.attribute2                                  emp_number,                  --�Ј���
              hopero.route_s_date                            route_s_date,                --�K�p�J�n��(���[�g�m�n)
              xca.latitude                                   latitude,                    --�ܓx
              xca.longitude                                  longitude,                   --�o�x
              xmc.decide_div                                 decide_div,                  --����敪
              xca.new_point_div                              new_point_div,               --�V�K�|�C���g�敪
              xca.receiv_discount_rate                       receiv_discount_rate,        --�����l����
              xca.vist_untarget_date                         vist_untarget_date,          --�ڋq�ΏۊO�ύX��
              xca.party_representative_name                  party_representative_name,   --��\�Җ��i�����j
              xca.party_emp_name                             party_emp_name,              --�S���ҁi�����j
              xca.operation_div                              operation_div,               --�I�y���[�V�����敪
              xca.child_dept_shop_code                       child_dept_shop_code,        --�S�ݓX�`��R�[�h
              xca.past_customer_status                       past_customer_status,        --�O���ڋq�X�e�[�^�X
              xca.past_final_tran_date                       past_final_tran_date,        --�O���ŏI�����
              hca.cust_account_id                            cust_account_id,             --�ڋqID
-- 2009/05/12 Ver1.3 ��QT1_0831 add start by Yutaka.Kuboshima
              hp.party_id                                    party_id,                    --�p�[�e�BID
              hl.address4                                    address4,                    --FAX�ԍ�
              hcp.cons_inv_flag                              cons_inv_flag,               --�ꊇ���������s�t���O
              TO_MULTI_BYTE(aah.hierarchy_name)              hierarchy_name,              --����|����������Z�b�g��
              xmc.approval_date                              approval_date,               --���ٓ��t
              xmc.tdb_code                                   tbd_code,                    --TDB�R�[�h
              hcsu.price_list_id                             price_list_id,               --���i�\
              hcsu.tax_header_level_flag                     tax_header_level_flag,       --�ŋ�-�v�Z
              hcsu.tax_rounding_rule                         tax_rounding_rule,           --�ŋ�-�[������
              xca.cust_update_flag                           cust_update_flag,            --�V�K/�X�V�t���O
              xca.edi_item_code_div                          edi_item_code_div,           --EDI�A�g�i�ڃR�[�h�敪
              xca.edi_chain_code                             edi_chain_code,              --�`�F�[���X�R�[�h(EDI)�y�e���R�[�h�p�z
              xca.parnt_dept_shop_code                       parnt_dept_shop_code,        --�S�ݓX�`��R�[�h�y�e���R�[�h�p�z
              xca.card_company_div                           card_company_div,            --�J�[�h��Ћ敪
              xca.card_company                               card_company,                --�J�[�h��ЃR�[�h
-- 2009/05/12 Ver1.3 ��QT1_0831 add end by Yutaka.Kuboshima
-- 2009/09/30 Ver1.7 ��Q0001350 add start by Yutaka.Kuboshima
              xca.invoice_code                               invoice_code,                --�������p�R�[�h
              xca.enclose_invoice_code                       enclose_invoice_code         --�����������p�R�[�h
-- 2009/09/30 Ver1.7 ��Q0001350 add end by Yutaka.Kuboshima
      FROM    hz_cust_accounts              hca,                      --�ڋq�}�X�^
              hz_locations                  hl,                       --�ڋq���Ə��}�X�^
              hz_cust_site_uses             hcsu,                     --�ڋq�g�p�ړI�}�X�^
              hz_parties                    hp,                       --�p�[�e�B�}�X�^
              hz_party_sites                hps,                      --�p�[�e�B�T�C�g�}�X�^
              xxcmm_cust_accounts           xca,                      --�ڋq�ǉ����}�X�^
              xxcmm_mst_corporate           xmc,                      --�ڋq�@�l���}�X�^
              hz_cust_acct_sites            hcas,                     --�ڋq���ݒn�}�X�^
              ra_terms                      rtsum,
              ra_terms                      rtsum2,
              ra_terms                      rtsum3,
-- 2009/05/12 Ver1.3 ��QT1_0831 add start by Yutaka.Kuboshima
              hz_customer_profiles          hcp,                      --�ڋq�v���t�@�C���}�X�^
              ar_autocash_hierarchies       aah,                      --���������K�w�}�X�^
-- 2009/05/12 Ver1.3 ��QT1_0831 add end by Yutaka.Kuboshima
              (SELECT lookup_code           lookup_code,
                      attribute1            attribute1
              FROM    fnd_lookup_values flvs
              WHERE   language     = cv_language_ja
              AND     lookup_type  = cv_gyotai_syo
              AND     enabled_flag = cv_y_flag)    flvgs,            --�N�C�b�N�R�[�h_�Q�ƃR�[�h(�Ƒ�(������))
              (SELECT lookup_code           lookup_code,
                      attribute1            attribute1
              FROM    fnd_lookup_values flvs
              WHERE   language     = cv_language_ja
              AND     lookup_type  = cv_gyotai_chu
              AND     enabled_flag = cv_y_flag)    flvgc,            --�N�C�b�N�R�[�h_�Q�ƃR�[�h(�Ƒ�(������))
              (SELECT lookup_code           lookup_code
              FROM    fnd_lookup_values flvs
              WHERE   language     = cv_language_ja
              AND     lookup_type  = cv_gyotai_dai
              AND     enabled_flag = cv_y_flag)    flvgd,            --�N�C�b�N�R�[�h_�Q�ƃR�[�h(�Ƒ�(�啪��))
--
-- 2009/05/12 Ver1.3 ��QT1_0176 add start by Yutaka.Kuboshima
              (SELECT lookup_code           lookup_code,
                      meaning               meaning
              FROM    fnd_lookup_values flvs
              WHERE   language     = cv_language_ja
              AND     lookup_type  = cv_site_use_code
              AND     enabled_flag = cv_y_flag)    flvsuc,           --�N�C�b�N�R�[�h_�Q�ƃR�[�h(�g�p�ړI)
-- 2009/05/12 Ver1.3 ��QT1_0176 add end by Yutaka.Kuboshima
              (SELECT armvw.name            name,
                     rcrmvw.customer_id     customer_id
              FROM   ar_receipt_methods            armvw,    --AR�x�����@�}�X�^
                     ra_cust_receipt_methods       rcrmvw,   --�x�����@���}�X�^
                     hz_cust_site_uses             hcsuvw    --�ڋq�g�p�ړI�}�X�^
              WHERE  (rcrmvw.primary_flag = cv_y_flag
                     AND TO_DATE(gv_process_date, cv_fnd_slash_date)
                     BETWEEN rcrmvw.start_date
                     AND NVL(rcrmvw.end_date, TO_DATE(cv_eff_last_date, cv_fnd_slash_date)))
              AND    armvw.receipt_method_id = rcrmvw.receipt_method_id         --AR�x�����@ = �x�����@���F�x�����@ID
              AND    hcsuvw.site_use_id      = rcrmvw.site_use_id)  arvw,       --�g�p�ړI   = �x�����@���F�ڋq���ݒn�g�pID
--
             (SELECT   hopviw1.party_id              party_id,
                       ereaviw.resource_no           resource_no,
                       ereaviw.resource_s_date       resource_s_date
-- 2009/05/12 Ver1.3 ��QT1_0831 modify start by Yutaka.Kuboshima
--              FROM     hz_cust_accounts              hcaviw1,   --�ڋq�}�X�^
              FROM     hz_parties                    hcaviw1,   --�p�[�e�B�}�X�^
-- 2009/05/12 Ver1.3 ��QT1_0831 modify end by Yutaka.Kuboshima
                       hz_organization_profiles      hopviw1,   --�g�D�v���t�@�C���}�X�^
                       ego_resource_agv              ereaviw    --�g�D�v���t�@�C���g���}�X�^(�c�ƈ�)
              WHERE   (TO_DATE(gv_process_date, cv_fnd_slash_date)
                       BETWEEN NVL(ereaviw.resource_s_date, TO_DATE(gv_process_date, cv_fnd_slash_date))
                       AND     NVL(ereaviw.resource_e_date, TO_DATE(cv_eff_last_date, cv_fnd_date)))
              AND      hcaviw1.party_id  = hopviw1.party_id
              AND      hopviw1.organization_profile_id = ereaviw.organization_profile_id
              AND      ereaviw.extension_id            = (SELECT   erearow1.extension_id
                                                          FROM     hz_organization_profiles      hoprow1,       --�g�D�v���t�@�C���}�X�^
                                                                   ego_resource_agv              erearow1       --�g�D�v���t�@�C���g���}�X�^(�c�ƈ�)
                                                          WHERE   (TO_DATE(gv_process_date, cv_fnd_slash_date)
                                                                   BETWEEN NVL(erearow1.resource_s_date, TO_DATE(gv_process_date, cv_fnd_slash_date))
                                                                   AND     NVL(erearow1.resource_e_date, TO_DATE(cv_eff_last_date, cv_fnd_date)))
                                                          AND      hcaviw1.party_id            = hoprow1.party_id
                                                          AND      hoprow1.organization_profile_id = erearow1.organization_profile_id
                                                          AND      ROWNUM = 1 ))  hopera, --�g�D�v���t�@�C��(�S���c�ƈ�)
--
             (SELECT hopviw2.party_id              party_id,
                     eroaviw.route_no              route_no,
                     eroaviw.route_s_date          route_s_date
-- 2009/05/12 Ver1.3 ��QT1_0831 modify start by Yutaka.Kuboshima
--              FROM     hz_cust_accounts              hcaviw2,   --�ڋq�}�X�^
              FROM     hz_parties                    hcaviw2,   --�p�[�e�B�}�X�^
-- 2009/05/12 Ver1.3 ��QT1_0831 modify end by Yutaka.Kuboshima
                     ego_route_agv                 eroaviw,                --�g�D�v���t�@�C���g���}�X�^(���[�g)
                     hz_organization_profiles      hopviw2                 --�g�D�v���t�@�C���}�X�^
              WHERE   (TO_DATE(gv_process_date, cv_fnd_slash_date)
                      BETWEEN NVL(eroaviw.route_s_date, TO_DATE(gv_process_date, cv_fnd_slash_date))
                      AND     NVL(eroaviw.route_e_date, TO_DATE(cv_eff_last_date, cv_fnd_slash_date)))
              AND     hcaviw2.party_id  = hopviw2.party_id
              AND     hopviw2.organization_profile_id = eroaviw.organization_profile_id
              AND     eroaviw.extension_id            = (SELECT  eroarow2.extension_id
                                                         FROM    ego_route_agv                 eroarow2,               --�g�D�v���t�@�C���g���}�X�^(���[�g)
                                                                 hz_organization_profiles      hoprow2                 --�g�D�v���t�@�C���}�X�^
                                                         WHERE   (TO_DATE(gv_process_date, cv_fnd_slash_date)
                                                                 BETWEEN NVL(eroarow2.route_s_date, TO_DATE(gv_process_date, cv_fnd_slash_date))
                                                                 AND     NVL(eroarow2.route_e_date, TO_DATE(cv_eff_last_date, cv_fnd_slash_date)))
                                                         AND     hcaviw2.party_id  = hoprow2.party_id
                                                         AND     hoprow2.organization_profile_id = eroarow2.organization_profile_id
                                                         AND     ROWNUM = 1 ))  hopero, --�g�D�v���t�@�C��(���[�g)
--
              (SELECT MIN(rtlmon.due_months_forward)  due_months_forward,
                     rtmon.term_id                    term_id
              FROM   ra_terms              rtmon,                         --�x�������}�X�^
                     ra_terms_lines        rtlmon                         --�x���������׃}�X�^
              WHERE rtmon.term_id             = rtlmon.term_id            --�x������ = �x���������ׁF�x������ID
              GROUP BY rtmon.term_id) rtmin
--
-- 2009/05/12 Ver1.3 ��QT1_0176 modify start by Yutaka.Kuboshima
--      WHERE   (hca.customer_class_code NOT IN ( cv_cust_base, cv_edi_mult, cv_dep_dist )  --�ڋq�敪(���_,�`�F�[��,�S�ݓX�ȊO)
--      OR      hca.customer_class_code IS NULL)                             --�ڋq�敪NULL
      WHERE   (hca.customer_class_code <> cv_cust_base                     --�ڋq�敪(���_)�ȊO
      OR      hca.customer_class_code IS NULL)                             --�ڋq�敪NULL
-- 2009/05/12 Ver1.3 ��QT1_0176 modify end by Yutaka.Kuboshima
      AND     hca.cust_account_id         = xca.customer_id (+)            --�ڋq = �ڋq�ǉ��F�ڋqID
      AND     hca.cust_account_id         = xmc.customer_id (+)            --�ڋq = �ڋq�@�l�F�ڋqID
      AND     flvgs.attribute1            = flvgc.lookup_code (+)          --�N�C�b�NS = �N�C�b�NC
      AND     flvgc.attribute1            = flvgd.lookup_code (+)          --�N�C�b�NC = �N�C�b�ND
      AND     xca.business_low_type       = flvgs.lookup_code (+)          --�ڋq�ǉ��F�Ƒԕ��� = �N�C�b�NS
      AND     hca.cust_account_id         = arvw.customer_id (+)           --�ڋq = �x�����@���F�ڋqID
      AND     hca.party_id                = hopera.party_id (+)            --�ڋq = �g�D�F�p�[�e�BID(�c��)
      AND     hca.party_id                = hopero.party_id (+)            --�ڋq = �g�D�F�p�[�e�BID(���[�g)
      AND     hca.party_id                = hp.party_id                    --�ڋq = �p�[�e�B�F�p�[�e�BID
      AND     hps.location_id             = hl.location_id                 --�p�[�e�B�T�C�g = ���Ə��F���P�[�V����ID
      AND     hcas.cust_acct_site_id      = hcsu.cust_acct_site_id         --���ݒn = �g�p�ړI�F�ڋq�T�C�gID
      AND     hp.party_id                 = hps.party_id                   --�p�[�e�B = �p�[�e�B�T�C�g�F�p�[�e�BID
      AND     hps.party_site_id           = hcas.party_site_id             --�p�[�e�B�T�C�g = �ڋq���ݒn�F�p�[�e�B�T�C�gID
      AND     hca.cust_account_id         = hcas.cust_account_id           --�ڋq = �ڋq���ݒn�F�ڋqID
-- 2009/05/12 Ver1.3 ��QT1_0176 modify start by Yutaka.Kuboshima
--      AND     hcsu.site_use_code          = cv_bill_to                     --�g�p�ړI = ������
      AND     hcsu.site_use_code         IN (cv_bill_to, cv_other_to)      --�g�p�ړI = ������ OR ���̑�
-- 2009/05/12 Ver1.3 ��QT1_0176 modify end by Yutaka.Kuboshima
      AND     hcsu.payment_term_id        = rtmin.term_id (+)              --�g�p�ړI = �x�������F�x������,�x������ID
      AND     hcsu.payment_term_id        = rtsum.term_id (+)              --�x������(�����E�����E�T�C�g)
      AND     hcsu.attribute2             = rtsum2.term_id (+)             --��Q�x������
      AND     hcsu.attribute3             = rtsum3.term_id (+)             --��R�x������
      AND     hl.location_id              = (SELECT MIN(hpsiv.location_id)
                                            FROM   hz_cust_acct_sites hcasiv,
                                                   hz_party_sites     hpsiv
                                            WHERE  hcasiv.cust_account_id = hca.cust_account_id
                                            AND    hcasiv.party_site_id   = hpsiv.party_site_id
                                            AND    hpsiv.status             = cv_a_flag)      --���P�[�V����ID�̍ŏ��l
-- 2009/05/12 Ver1.3 ��QT1_0176 add start by Yutaka.Kuboshima
      AND     hcsu.site_use_id              = hcp.site_use_id(+)
      AND     hcp.autocash_hierarchy_id     = aah.autocash_hierarchy_id(+)
      AND     hcsu.site_use_code            = flvsuc.lookup_code(+)
-- 2009/05/12 Ver1.3 ��QT1_0176 add end by Yutaka.Kuboshima
-- 2009/05/21 Ver1.4 ��QT1_1131 add start by Yutaka.Kuboshima
      AND     hcsu.status                   = cv_a_flag
-- 2009/05/21 Ver1.4 ��QT1_1131 add end by Yutaka.Kuboshima
      ORDER BY hca.account_number;
--
    -- �ڋq�ꊇ�X�V���J�[�\�����R�[�h�^
    cust_data_rec cust_data_cur%ROWTYPE;
--
-- 2009/05/12 Ver1.3 ��QT1_0176 add start by Yutaka.Kuboshima
    -- �֘A�ڋq�擾�J�[�\��
    CURSOR cust_acct_relate_cur(p_cust_account_id IN NUMBER)
    IS
      SELECT hcar.attribute1    attribute1,
             hca.account_number account_number,
             hp.party_name      party_name
      FROM hz_cust_accounts hca,
           hz_parties hp,
           hz_cust_acct_relate hcar
      WHERE hca.party_id                 = hp.party_id
        AND hca.cust_account_id          = hcar.cust_account_id
        AND hcar.related_cust_account_id = p_cust_account_id
        AND hca.customer_class_code      = cv_urikake_kbn
        AND hcar.status                  = cv_a_flag
        AND ROWNUM = 1;
    -- �֘A�ڋq���J�[�\�����R�[�h�^
    cust_acct_relate_rec cust_acct_relate_cur%ROWTYPE;
--
    -- ���YOU���ڋq���ݒn�擾�J�[�\��
    CURSOR mfg_cust_acct_site_cur(p_cust_account_id IN NUMBER)
    IS
      SELECT hcasa.attribute18 attribute18
      FROM hz_cust_acct_sites_all hcasa,
           hr_operating_units hou
      WHERE hcasa.org_id          = hou.organization_id
        AND hcasa.cust_account_id = p_cust_account_id
        AND hou.name              = cv_seisan_ou
        AND ROWNUM = 1;
    -- ���YOU���ڋq���ݒn�擾�J�[�\�����R�[�h�^
    mfg_cust_acct_site_rec mfg_cust_acct_site_cur%ROWTYPE;
--
    -- �p�[�e�B�֘A�擾�J�[�\��
    CURSOR hz_relationships_cur(p_party_id IN NUMBER)
    IS
      SELECT hca.account_number account_number,
             hp.party_name      party_name
      FROM hz_cust_accounts hca,
           hz_parties hp,
           hz_relationships hr
      WHERE hca.party_id            = hp.party_id
        AND hp.party_id             = hr.subject_id
        AND hr.object_type          = cv_organization
        AND hr.object_id            = p_party_id
        AND hca.customer_class_code = cv_yosin_kbn
        AND hr.status               = cv_a_flag
        AND ROWNUM = 1;
    -- �p�[�e�B�֘A�擾�J�[�\�����R�[�h�^
    hz_relationships_rec hz_relationships_cur%ROWTYPE;
-- 2009/05/12 Ver1.3 ��QT1_0176 add end by Yutaka.Kuboshima
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --�A�g���t�̎擾
    lv_coordinated_date := TO_CHAR(sysdate, cv_trans_date);
--
    --�ڋq�ꊇ�X�V���J�[�\�����[�v
    << cust_for_loop >>
    FOR cust_data_rec IN cust_data_cur
    LOOP
      -- ===============================
      -- ������ڋq�̎擾
      -- ===============================
      BEGIN
        --������̌ڋq���擾
        SELECT hca.account_number                 account_number,             --�ڋq�R�[�h
               hca.cust_account_id                cust_account_id,            --�ڋqID
               hcsu.location                      location                    --���Ə�
        INTO   lv_bill_number,
               ln_bill_cust_id,
               lv_bill_location
        FROM   hz_cust_accounts                   hca,                        --�ڋq�}�X�^
               hz_cust_acct_sites                 hcas,                       --�ڋq���ݒn�}�X�^
               hz_cust_site_uses                  hcsu,                       --�ڋq�g�p�ړI�}�X�^
               hz_party_sites                     hps,                        --�p�[�e�B�T�C�g�}�X�^
               hz_locations                       hl                          --�ڋq���Ə��}�X�^
        WHERE  hcas.cust_acct_site_id = hcsu.cust_acct_site_id                --�ڋq�T�C�gID
        AND    hca.cust_account_id    = hcas.cust_account_id                  --�ڋqID
        AND    hcsu.site_use_code     = cv_bill_to
        AND    hps.location_id        = hl.location_id
        AND    hps.party_site_id      = hcas.party_site_id
        AND    hcsu.site_use_id = (SELECT hcsun.bill_to_site_use_id
                                  FROM    hz_cust_accounts        hcan,       --�ڋq�}�X�^
                                          hz_cust_acct_sites      hcasn,      --�ڋq���ݒn�}�X�^
                                          hz_cust_site_uses       hcsun,      --�ڋq�g�p�ړI�}�X�^
                                          hz_party_sites          hpsn,       --�p�[�e�B�T�C�g�}�X�^
                                          hz_locations            hln         --�ڋq���Ə��}�X�^
                                  WHERE   hcan.account_number     = cust_data_rec.account_number
                                  AND     hcasn.cust_acct_site_id = hcsun.cust_acct_site_id
                                  AND     hcan.cust_account_id    = hcasn.cust_account_id
                                  AND     hcsun.site_use_code     = cv_ship_to
                                  AND     hpsn.location_id        = hln.location_id
                                  AND     hpsn.party_site_id      = hcasn.party_site_id
-- 2009/05/21 Ver1.4 ��QT1_1131 add start by Yutaka.Kuboshima
                                  AND     hcsun.status            = cv_a_flag
-- 2009/05/21 Ver1.4 ��QT1_1131 add end by Yutaka.Kuboshima
                                  AND     hln.location_id         = (SELECT MIN(hpsiva.location_id)
                                                                    FROM    hz_cust_acct_sites hcasiva,
                                                                            hz_party_sites     hpsiva
                                                                    WHERE  hcasiva.cust_account_id = hcan.cust_account_id
                                                                    AND    hcasiva.party_site_id   = hpsiva.party_site_id
                                                                    AND    hpsiva.status           = cv_a_flag))      --���P�[�V����ID�̍ŏ��l
-- 2009/05/21 Ver1.4 ��QT1_1131 add start by Yutaka.Kuboshima
        AND     hcsu.status            = cv_a_flag
-- 2009/05/21 Ver1.4 ��QT1_1131 add end by Yutaka.Kuboshima
        AND     hl.location_id         = (SELECT MIN(hpsiv.location_id)
                                         FROM   hz_cust_acct_sites hcasiv,
                                                hz_party_sites     hpsiv
                                         WHERE  hcasiv.cust_account_id = hca.cust_account_id
                                         AND    hcasiv.party_site_id   = hpsiv.party_site_id
                                         AND    hpsiv.status             = cv_a_flag);      --���P�[�V����ID�̍ŏ��l
      EXCEPTION
        --*** �Ώۃ��R�[�h�Ȃ��G���[ ***
        WHEN NO_DATA_FOUND THEN
          lv_bill_number   := NULL;
          ln_bill_cust_id  := NULL;
          lv_bill_location := NULL;
        WHEN TOO_MANY_ROWS THEN
          RAISE;
        WHEN OTHERS THEN
          RAISE;
      END;
--
      --
      -- ===============================
      -- ������ڋq�̎擾
      -- ===============================
      BEGIN
        --�R�D������̌ڋq���擾���܂��B
        --�@�ڋq�R�[�h�E�ڋqID�𒊏o���܂��B
        SELECT hca.account_number                 account_number,                           --�ڋq�R�[�h
               hca.cust_account_id                cust_account_id,                          --�ڋqID
               hcara.attribute1                   attribute1                                --�֘A�ڋq
        INTO   lv_pay_account_num,
               ln_pay_cust_account_id,
               lv_relate_cust_class
        FROM   hz_cust_accounts                   hca,                                      --�ڋq�}�X�^
               hz_cust_acct_relate                hcara                                     --�֘A�ڋq�}�X�^
        WHERE  hcara.related_cust_account_id = cust_data_rec.cust_account_id
        AND    hcara.cust_account_id         = ln_bill_cust_id
        AND    hca.cust_account_id           = hcara.cust_account_id;
      EXCEPTION
        --*** �Ώۃ��R�[�h�Ȃ��G���[ ***
        WHEN NO_DATA_FOUND THEN
          lv_pay_account_num     := NULL;
          ln_pay_cust_account_id := NULL;
          lv_relate_cust_class   := NULL;
        WHEN TOO_MANY_ROWS THEN
          RAISE;
        WHEN OTHERS THEN
          RAISE;
      END;
--
      IF (lv_pay_account_num IS NOT NULL) THEN
        BEGIN
          --�A �@�ŌڋqID���擾�ł����ꍇ�A�e�̌ڋqID�𒊏o���܂��B
          SELECT hca.account_number                 account_number                            --�ڋq�R�[�h
          INTO   lv_par_account_num
          FROM   hz_cust_accounts                   hca,                                      --�ڋq�}�X�^
                 hz_cust_acct_relate                hcara                                     --�֘A�ڋq�}�X�^
          WHERE  hcara.related_cust_account_id = ln_pay_cust_account_id
          AND    hca.cust_account_id           = hcara.cust_account_id
          AND    hcara.attribute1              = cv_auto_ex_flag;
        EXCEPTION
          --*** �Ώۃ��R�[�h�Ȃ��G���[ ***
          WHEN NO_DATA_FOUND THEN
            lv_par_account_num := NULL;
          WHEN TOO_MANY_ROWS THEN
            RAISE;
          WHEN OTHERS THEN
            RAISE;
        END;
--
        IF (lv_par_account_num IS NOT NULL) THEN
          lv_pay_account_num := lv_par_account_num;
        ELSIF (lv_par_account_num IS NULL AND NVL(lv_relate_cust_class, '0') <> cv_auto_ex_flag) THEN
          lv_pay_account_num := NULL;
        END IF;
      END IF;
--
-- 2009/05/12 Ver1.3 ��QT1_0176 add start by Yutaka.Kuboshima
      -- �֘A�ڋq���擾
      OPEN cust_acct_relate_cur(cust_data_rec.cust_account_id);
      FETCH cust_acct_relate_cur INTO cust_acct_relate_rec;
      CLOSE cust_acct_relate_cur;
      -- ���YOU���ڋq���ݒn���擾
      OPEN mfg_cust_acct_site_cur(cust_data_rec.cust_account_id);
      FETCH mfg_cust_acct_site_cur INTO mfg_cust_acct_site_rec;
      CLOSE mfg_cust_acct_site_cur;
      -- �p�[�e�B�֘A���擾
      OPEN hz_relationships_cur(cust_data_rec.party_id);
      FETCH hz_relationships_cur INTO hz_relationships_rec;
      CLOSE hz_relationships_cur;
-- 2009/05/12 Ver1.3 ��QT1_0176 add end by Yutaka.Kuboshima
      -- ===============================
      -- �o�͒l�ݒ�
      -- ===============================--
--
-- 2009/06/09 Ver1.6 add start by Yutaka.Kuboshima
      -- �ڋq���̐ݒ�
      lv_customer_name            := xxcso_util_common_pkg.conv_multi_byte(cust_data_rec.party_name);
      -- �ڋq���J�i�ݒ�
      lv_customer_name_kana       := xxccp_common_pkg.chg_double_to_single_byte(cust_data_rec.organization_name_phonetic);
      -- ���p�ϊ��s���������݂���ꍇ
      IF (LENGTH(lv_customer_name_kana) <> LENGTHB(lv_customer_name_kana)) THEN
        lv_customer_name_kana := cv_single_byte_err1;
      END IF;
      -- �ڋq�����̐ݒ�
      lv_customer_name_ryaku      := xxcso_util_common_pkg.conv_multi_byte(cust_data_rec.account_name);
      -- �s���{���ݒ�
      lv_state                    := xxcso_util_common_pkg.conv_multi_byte(cust_data_rec.state);
      -- �s�E��ݒ�
      lv_city                     := xxcso_util_common_pkg.conv_multi_byte(cust_data_rec.city);
      -- �Z���P�ݒ�
      lv_address1                 := xxcso_util_common_pkg.conv_multi_byte(cust_data_rec.address1);
      -- �Z���Q�ݒ�
      lv_address2                 := xxcso_util_common_pkg.conv_multi_byte(cust_data_rec.address2);
      -- FAX�ݒ�
      lv_fax                      := xxccp_common_pkg.chg_double_to_single_byte(cust_data_rec.address4);
      -- ���p�ϊ��s���������݂���ꍇ
      IF (LENGTH(lv_fax) <> LENGTHB(lv_fax)) THEN
        lv_fax := cv_single_byte_err2;
      END IF;
      -- �d�b�ԍ��ݒ�
      lv_address_lines_phonetic   := xxccp_common_pkg.chg_double_to_single_byte(cust_data_rec.address_lines_phonetic);
      -- ���p�ϊ��s���������݂���ꍇ
      IF (LENGTH(lv_address_lines_phonetic) <> LENGTHB(lv_address_lines_phonetic)) THEN
        lv_address_lines_phonetic := cv_single_byte_err2;
      END IF;
      -- �X�����ݒ�
      lv_manager_name             := xxcso_util_common_pkg.conv_multi_byte(cust_data_rec.manager_name);
      -- �S���ҋx���ݒ�
      lv_rest_emp_name            := xxcso_util_common_pkg.conv_multi_byte(cust_data_rec.rest_emp_name);
      -- MC:�������ݒ�
      lv_mc_conf_info             := xxcso_util_common_pkg.conv_multi_byte(cust_data_rec.mc_conf_info);
      -- MC:���k�o�ܐݒ�
      lv_mc_business_talk_details := xxcso_util_common_pkg.conv_multi_byte(cust_data_rec.mc_business_talk_details);
-- 2009/06/09 Ver1.6 add end by Yutaka.Kuboshima
      --�o�͕�����쐬
      lv_output_str := cv_dqu        || cv_comp_code || cv_dqu;                                                                    --��ЃR�[�h
      lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.account_number, 1, 9);                                   --�ڋq�R�[�h
      lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.party_number, 1, 10);                                    --�p�[�e�B�ԍ�
-- 2009/06/09 Ver1.6 modify start by Yutaka.Kuboshima
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.party_name, 1, 100)                || cv_dqu;  --�ڋq����
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(lv_customer_name, 1, 100)                        || cv_dqu;  --�ڋq����
-- 2009/06/09 Ver1.6 modify end by Yutaka.Kuboshima
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.resource_no, 1, 5)                 || cv_dqu;  --�S���c�ƈ��R�[�h
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.sale_base_code, 1, 4)              || cv_dqu;  --���㋒�_�R�[�h
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.past_charge_base_code, 1, 4)       || cv_dqu;  --�S�����_�R�[�h(��)
      lv_output_str := lv_output_str || cv_comma || TO_CHAR(cust_data_rec.resource_s_date, cv_fnd_date);                           --�S���ύX��
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.cnvs_business_person, 1, 5)        || cv_dqu;  --�l���c�ƈ��R�[�h
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.cnvs_base_code, 1, 4)              || cv_dqu;  --�l�����_�R�[�h
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.intro_business_person, 1, 5)       || cv_dqu;  --�Љ�c�ƈ��R�[�h
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.intro_base_code, 1, 4)             || cv_dqu;  --�Љ�_�R�[�h
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.route_no, 1, 7)                    || cv_dqu;  --���[�gNo
-- 2009/05/29 Ver1.5 modify start by Yutaka.Kuboshima
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.business_low_type, 1, 2)           || cv_dqu;  --�Ƒԑ啪��
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.lookup_code_s, 1, 2)               || cv_dqu;  --�Ƒԑ啪��
-- 2009/05/29 Ver1.5 modify end by Yutaka.Kuboshima
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.lookup_code_c, 1, 2)               || cv_dqu;  --�ƑԒ�����
-- 2009/05/29 Ver1.5 modify start by Yutaka.Kuboshima
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.lookup_code_s, 1, 2)               || cv_dqu;  --�Ƒԏ�����
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.business_low_type, 1, 2)           || cv_dqu;  --�Ƒԏ�����
-- 2009/05/29 Ver1.5 modify end by Yutaka.Kuboshima
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.delivery_form, 1, 1)               || cv_dqu;  --�z���`��
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.establishment_location, 1, 2)      || cv_dqu;  --�ݒu���P�[�V����
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.open_close_div, 1, 1)              || cv_dqu;  --�I�[�v���E�N���[�Y
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.duns_number_c, 1, 2)               || cv_dqu;  --�ڋq�X�e�[�^�X�R�[�h
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.mc_Importance_deg, 1, 1)           || cv_dqu;  --�l�b�d�v�x
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.mc_hot_deg, 1, 1)                  || cv_dqu;  --�l�b�g�n�s�x
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.due_months_forward, 1, 2)          || cv_dqu;  --�T�C�g
      lv_output_str := lv_output_str || cv_comma || TO_CHAR(cust_data_rec.creation_date, cv_fnd_date);                             --�o�^��
      lv_output_str := lv_output_str || cv_comma || TO_CHAR(cust_data_rec.start_tran_date, cv_fnd_date);                           --����J�n��
      lv_output_str := lv_output_str || cv_comma || cv_dqu || cv_auto_ex_flag                                          || cv_dqu;  --�����o�W�t���O
      lv_output_str := lv_output_str || cv_comma || SUBSTRB(TO_CHAR(cust_data_rec.new_point), 1, 3);                               --�V�K�|�C���g
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.stop_approval_reason, 1, 1)        || cv_dqu;  --���~���R�敪
      lv_output_str := lv_output_str || cv_comma || TO_CHAR(cust_data_rec.stop_approval_date, cv_fnd_date);                        --���~�N����
-- 2009/06/09 Ver1.6 modify start by Yutaka.Kuboshima
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.account_name, 1, 80)               || cv_dqu;  --�ڋq������
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.organization_name_phonetic, 1, 50) || cv_dqu;  --�ڋq���J�i
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(lv_customer_name_ryaku, 1, 80)                   || cv_dqu;  --�ڋq������
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(lv_customer_name_kana, 1, 50)                    || cv_dqu;  --�ڋq���J�i
-- 2009/06/09 Ver1.6 modify end by Yutaka.Kuboshima
      lv_output_str := lv_output_str || cv_comma || SUBSTRB(lv_pay_account_num, 1, 9);                                             --���|�R�[�h�`�i�����ڋq�j
      lv_output_str := lv_output_str || cv_comma || SUBSTRB(lv_bill_number, 1, 9);                                                 --���|�R�[�h�a�i�����ڋq�j
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.receiv_base_code, 1, 4)            || cv_dqu;  --�������_�R�[�h
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.bill_base_code, 1, 4)              || cv_dqu;  --�������_�i����j�R�[�h
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.termtl_name, 1, 8)                 || cv_dqu;  --�x�������i�����E�����E�T�C�g�j
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.delivery_chain_code, 1, 9)         || cv_dqu;  --�[�i�`�F�[���b�c
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.sales_chain_code, 1, 9)            || cv_dqu;  --�̔��`�F�[���b�c
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.intro_chain_code1, 1, 30)          || cv_dqu;  --�Љ�p�P
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.intro_chain_code2, 1, 30)          || cv_dqu;  --�Љ�p�Q
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.policy_chain_code, 1, 30)          || cv_dqu;  --�c�Ɛ����p
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.store_code, 1, 10)                 || cv_dqu;  --�X�܃R�[�h
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.tax_div, 1, 1)                     || cv_dqu;  --����ŋ敪
-- 2009/10/01 Ver1.7 ��Q0001350 modify start by Yutaka.Kuboshima
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.invoice_class, 1, 1)               || cv_dqu;  --���������s�敪
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.invoice_printing_unit, 1, 1) || cv_dqu;        --����������P��
-- 2009/10/01 Ver1.7 ��Q0001350 modify end by Yutaka.Kuboshima
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.invoice_process_class, 1, 1)       || cv_dqu;  --���������敪
      lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.corporate_number, 1, 9);                                 --�@�l�R�[�h
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.base_code, 1, 4)                   || cv_dqu;  --�{���S�����_�R�[�h
      lv_output_str := lv_output_str || cv_comma || SUBSTRB(TO_CHAR(cust_data_rec.credit_limit), 1, 9);                            --�^�M���x�g
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.vist_target_div, 1, 1)             || cv_dqu;  --�K��Ώۋ敪
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.customer_class_code, 1, 2)         || cv_dqu;  --�ڋq�敪
      lv_output_str := lv_output_str || cv_comma || TO_CHAR(cust_data_rec.cnvs_date, cv_fnd_date);                                 --�ڋq�l����
      lv_output_str := lv_output_str || cv_comma || TO_CHAR(cust_data_rec.final_tran_date, cv_fnd_date);                           --�ŏI�����
      lv_output_str := lv_output_str || cv_comma || TO_CHAR(cust_data_rec.final_call_date, cv_fnd_date);                           --�ŏI�K���
      lv_output_str := lv_output_str || cv_comma || SUBSTRB(TO_CHAR(cust_data_rec.change_amount), 1, 4);                           --�ޑK
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.torihiki_form, 1, 1)               || cv_dqu;  --����`��
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.postal_code, 1, 7)                 || cv_dqu;  --�X�֔ԍ�
-- 2009/06/09 Ver1.6 modify start by Yutaka.Kuboshima
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.state, 1, 30)                      || cv_dqu;  --�s���{��
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.city, 1, 30)                       || cv_dqu;  --�s�E��
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.address1, 1, 240)                  || cv_dqu;  --�Z��1
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.address2, 1, 240)                  || cv_dqu;  --�Z��2
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(lv_state, 1, 30)                                 || cv_dqu;  --�s���{��
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(lv_city, 1, 30)                                  || cv_dqu;  --�s�E��
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(lv_address1, 1, 240)                             || cv_dqu;  --�Z��1
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(lv_address2, 1, 240)                             || cv_dqu;  --�Z��2
-- 2009/06/09 Ver1.6 modify end by Yutaka.Kuboshima
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.address3, 1, 5)                    || cv_dqu;  --�n��R�[�h
-- 2009/06/09 Ver1.6 modify start by Yutaka.Kuboshima
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.address_lines_phonetic, 1, 30)     || cv_dqu;  --�d�b�ԍ�
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(lv_address_lines_phonetic, 1, 30)                || cv_dqu;  --�d�b�ԍ�
-- 2009/06/09 Ver1.6 modify end by Yutaka.Kuboshima
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.cust_store_name, 1, 30)            || cv_dqu;  --�ڋq�X�ܖ���
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.torihikisaki_code, 1, 8)           || cv_dqu;  --�����R�[�h
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.industry_div, 1, 2)                || cv_dqu;  --�Ǝ�
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.selling_transfer_div, 1, 1)        || cv_dqu;  --������ѐU��
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.center_edi_div, 1, 1)              || cv_dqu;  --�Z���^�[EDI�敪
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.past_sale_base_code, 1, 4)         || cv_dqu;  --�O�����㋒�_�R�[�h
      lv_output_str := lv_output_str || cv_comma || TO_CHAR(cust_data_rec.rsv_sale_base_act_date, cv_fnd_date);                    --�\�񔄏㋒�_�L���J�n��
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.rsv_sale_base_code, 1, 4)          || cv_dqu;  --�\�񔄏㋒�_�R�[�h
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.delivery_base_code, 1, 4)          || cv_dqu;  --�[�i���_�R�[�h
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.sales_head_base_code, 1, 4)        || cv_dqu;  --�̔���{���S�����_
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.vendor_machine_number, 1, 30)      || cv_dqu;  --�����̔��@�ԍ�
      lv_output_str := lv_output_str || cv_comma || SUBSTRB(TO_CHAR(cust_data_rec.rate), 1, 4);                                    --�����u�c�|��
      lv_output_str := lv_output_str || cv_comma || SUBSTRB(TO_CHAR(cust_data_rec.conclusion_day1), 1, 2);                         --�����v�Z���ߓ��P
      lv_output_str := lv_output_str || cv_comma || SUBSTRB(TO_CHAR(cust_data_rec.conclusion_day2), 1, 2);                         --�����v�Z���ߓ��Q
      lv_output_str := lv_output_str || cv_comma || SUBSTRB(TO_CHAR(cust_data_rec.conclusion_day3), 1, 2);                         --�����v�Z���ߓ��R
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.contractor_supplier_code, 1, 9)    || cv_dqu;  --�_��Ҏd����R�[�h
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.bm_pay_supplier_code1, 1, 9)       || cv_dqu;  --�Љ�҂a�l�x���d����R�[�h�P
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.bm_pay_supplier_code2, 1, 9)       || cv_dqu;  --�Љ�҂a�l�x���d����R�[�h�Q
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.wholesale_ctrl_code, 1, 9)         || cv_dqu;  --�≮�Ǘ��R�[�h�i�����Ə��}�X�^�̎��Ə��j
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.ship_storage_code, 1, 10)          || cv_dqu;  --�o�׌��ۊǏꏊ�iEDI�j
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.chain_store_code, 1, 4)            || cv_dqu;  --�`�F�[���X�R�[�h�iEDI�j
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.delivery_order, 1, 14)             || cv_dqu;  --�z�����iEDI�j
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.edi_district_code, 1, 8)           || cv_dqu;  --EDI�n��R�[�h�iEDI�j
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.edi_district_name, 1, 40)          || cv_dqu;  --EDI�n�於�iEDI�j
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.edi_district_kana, 1, 20)          || cv_dqu;  --EDI�n�於�J�i�iEDI�j
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.tsukagatazaiko_div, 1, 2)          || cv_dqu;  --�ʉߍ݌Ɍ^�敪�iEDI�j
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.handwritten_slip_div, 1, 1)        || cv_dqu;  --EDI�菑�`�[�`���敪
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.deli_center_code, 1, 8)            || cv_dqu;  --EDI�[�i�Z���^�[�R�[�h
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.deli_center_name, 1, 20)           || cv_dqu;  --EDI�[�i�Z���^�[��
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.edi_forward_number, 1, 2)          || cv_dqu;  --EDI�`���ǔ�
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.receipt_methods_name, 1, 50)       || cv_dqu;  --�x�����@��
      lv_output_str := lv_output_str || cv_comma || SUBSTRB(lv_bill_location, 1, 9);                                               --�����掖�Ə�
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.site_use_code, 1, 20)              || cv_dqu;  --�g�p�ړI
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.payment_term2, 1, 8)               || cv_dqu;  --��2�x������
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.payment_term3, 1, 8)               || cv_dqu;  --��3�x������
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.ar_invoice_code, 1, 12)            || cv_dqu;  --���|�R�[�h�P�i�������j
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.ar_location_code, 1, 12)           || cv_dqu;  --���|�R�[�h�Q�i���Ə��j
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.ar_others_code, 1, 12)             || cv_dqu;  --���|�R�[�h�R�i���̑��j
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.invoice_sycle, 1, 1)               || cv_dqu;  --���������s�T�C�N��
-- 2009/06/09 Ver1.6 modify start by Yutaka.Kuboshima
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.manager_name, 1, 150)              || cv_dqu;  --�X����
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.rest_emp_name, 1, 150)             || cv_dqu;  --�S���ҋx��
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.mc_conf_info, 1, 150)              || cv_dqu;  --MC:�������
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.mc_business_talk_details, 1, 150)  || cv_dqu;  --MC:���k�o��
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(lv_manager_name, 1, 150)                         || cv_dqu;  --�X����
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(lv_rest_emp_name, 1, 150)                        || cv_dqu;  --�S���ҋx��
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(lv_mc_conf_info, 1, 150)                         || cv_dqu;  --MC:�������
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(lv_mc_business_talk_details, 1, 150)             || cv_dqu;  --MC:���k�o��
-- 2009/06/09 Ver1.6 modify end by Yutaka.Kuboshima
      lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.party_site_number, 1, 32);                               --�p�[�e�B�T�C�g�ԍ�
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.established_site_name, 1, 30)      || cv_dqu;  --�ݒu�於
      lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.emp_number, 1, 15);                                      --�Ј���
      lv_output_str := lv_output_str || cv_comma || TO_CHAR(cust_data_rec.route_s_date, cv_fnd_date);                              --�K�p�J�n���i���[�g�m�n�j
      lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.latitude, 1, 10);                                        --�ܓx
      lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.longitude, 1, 10);                                       --�o�x
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.decide_div, 1, 1)                  || cv_dqu;  --����敪
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.new_point_div, 1, 1)               || cv_dqu;  --�V�K�|�C���g�敪
      lv_output_str := lv_output_str || cv_comma || SUBSTRB(TO_CHAR(cust_data_rec.receiv_discount_rate), 1, 4);                         --�����l����
      lv_output_str := lv_output_str || cv_comma || TO_CHAR(cust_data_rec.vist_untarget_date, cv_fnd_date);                        --�ڋq�ΏۊO�ύX��
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.party_representative_name, 1, 20)  || cv_dqu;  --��\�Җ��i�����j
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.party_emp_name, 1, 20)             || cv_dqu;  --�S���ҁi�����j
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.operation_div, 1, 1)               || cv_dqu;  --�I�y���[�V�����敪
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.child_dept_shop_code, 1, 3)        || cv_dqu;  --�S�ݓX�`��R�[�h
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.past_customer_status, 1, 2)        || cv_dqu;  --�O���ڋq�X�e�[�^�X
      lv_output_str := lv_output_str || cv_comma || TO_CHAR(cust_data_rec.past_final_tran_date, cv_fnd_date);                      --�O���ŏI�����
-- 2009/05/12 Ver1.3 ��QT1_0176 add start by Yutaka.Kuboshima
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(hz_relationships_rec.party_name, 1, 100) || cv_dqu;          --�^�M�Ǘ���ڋq����
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(hz_relationships_rec.account_number, 1, 9) || cv_dqu;        --�^�M�Ǘ���ڋq�ԍ�
-- 2009/06/09 Ver1.6 modify start by Yutaka.Kuboshima
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.address4, 1, 30) || cv_dqu;                    --�Z��4(FAX�ԍ�)
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(lv_fax, 1, 30) || cv_dqu;                                    --�Z��4(FAX�ԍ�)
-- 2009/06/09 Ver1.6 modify end by Yutaka.Kuboshima
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.cons_inv_flag, 1, 1) || cv_dqu;                --�ꊇ���������s�t���O
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.hierarchy_name, 1, 30) || cv_dqu;              --����|����������Z�b�g��
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(mfg_cust_acct_site_rec.attribute18, 1, 9) || cv_dqu;         --�z����R�[�h
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_acct_relate_rec.party_name, 1, 100) || cv_dqu;          --�֘A�ڋq����(�e)
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_acct_relate_rec.account_number, 1, 9) || cv_dqu;        --�֘A�ڋq�ԍ�(�e)
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_acct_relate_rec.attribute1, 1, 1) || cv_dqu;            --�֘A����
      lv_output_str := lv_output_str || cv_comma || TO_CHAR(cust_data_rec.approval_date, cv_fnd_date);                             --���ٓ��t
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.tbd_code, 1, 12) || cv_dqu;                    --TDB�R�[�h
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(TO_CHAR(cust_data_rec.price_list_id), 1, 50) || cv_dqu;      --���i�\
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.tax_header_level_flag, 1, 1) || cv_dqu;        --�ŋ��|�v�Z
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.tax_rounding_rule, 1, 7) || cv_dqu;            --�ŋ��|�[������
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.cust_update_flag, 1, 1) || cv_dqu;             --�V�K/�X�V�t���O
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.edi_item_code_div, 1, 1) || cv_dqu;            --EDI�A�g�i�ڃR�[�h�敪
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.edi_chain_code, 1, 4) || cv_dqu;               --�`�F�[���X�R�[�h(EDI)�y�e���R�[�h�p�z
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.parnt_dept_shop_code, 1, 3) || cv_dqu;         --�S�ݓX�`��R�[�h�y�e���R�[�h�p�z
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.card_company_div, 1, 1) || cv_dqu;             --�J�[�h��Ћ敪
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.card_company, 1, 9) || cv_dqu;                 --�J�[�h��ЃR�[�h
-- 2009/05/12 Ver1.3 ��QT1_0176 add end by Yutaka.Kuboshima
-- 2009/09/30 Ver1.7 ��Q0001350 add start by Yutaka.Kuboshima
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.invoice_code, 1, 9) || cv_dqu;                 --�������p�R�[�h
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.enclose_invoice_code, 1, 9) || cv_dqu;         --�����������p�R�[�h
-- 2009/09/30 Ver1.7 ��Q0001350 add end by Yutaka.Kuboshima
      lv_output_str := lv_output_str || cv_comma || lv_coordinated_date;                                                           --�A�g����
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
      lv_output_str           := NULL;
-- 2009/05/12 Ver1.3 ��QT1_0176 add start by Yutaka.Kuboshima
      cust_acct_relate_rec    := NULL;
      mfg_cust_acct_site_rec  := NULL;
      hz_relationships_rec    := NULL;
-- 2009/05/12 Ver1.3 ��QT1_0176 add end by Yutaka.Kuboshima
-- 2009/06/09 Ver1.6 add start by Yutaka.Kuboshima
      lv_customer_name            := NULL;
      lv_customer_name_kana       := NULL;
      lv_customer_name_ryaku      := NULL;
      lv_state                    := NULL;
      lv_city                     := NULL;
      lv_address1                 := NULL;
      lv_address2                 := NULL;
      lv_fax                      := NULL;
      lv_address_lines_phonetic   := NULL;
      lv_manager_name             := NULL;
      lv_rest_emp_name            := NULL;
      lv_mc_conf_info             := NULL;
      lv_mc_business_talk_details := NULL;
-- 2009/06/09 Ver1.6 add end by Yutaka.Kuboshima
--
    END LOOP cust_for_loop;
--
    gn_target_cnt := ln_output_cnt;
    gn_normal_cnt := ln_output_cnt;
--
    --�Ώۃf�[�^0���G���[
    IF (ln_output_cnt = 0) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                            cv_no_data_err_msg);
      lv_errbuf := lv_errmsg;
      RAISE no_date_err_expt;
    END IF;
--
  EXCEPTION
    WHEN no_date_err_expt THEN                         --*** �Ώۃf�[�^�Ȃ��G���[ ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      gn_nodate_err := 1;
      --�Ώۃf�[�^��0���̎��A�G���[������0���Œ�Ƃ���
      gn_target_cnt := 0;
      gn_error_cnt  := 0;
    WHEN write_failure_expt THEN                       --*** CSV�f�[�^�o�̓G���[ ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      --CSV�f�[�^�o�̓G���[���A�Ώی����A�G���[������0���Œ�Ƃ���
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
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
    gn_nodate_err := 0;
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
       lf_file_handler         -- �t�@�C���n���h��
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
                                              cv_file_close_err_msg,
                                              cv_sqlerrm,
                                              SQLERRM);
        lv_errbuf := lv_errmsg;
        RAISE fclose_err_expt;
    END;
    IF (lv_retcode = cv_status_error) THEN
      -- �Ώۃf�[�^�Ȃ��G���[�̏ꍇ�A�t�@�C�����폜���܂�
      IF ( gn_nodate_err = 1 ) THEN
        -- �t�@�C���폜
        UTL_FILE.FREMOVE(gv_out_file_dir, gv_out_file_file);
      END IF;
      -- �G���[����
      RAISE global_process_expt;
    END IF;
--
/*
    --�t�@�C���N���[�Y����
    IF (UTL_FILE.IS_OPEN(lf_file_handler)) THEN
      --�t�@�C���N���[�Y
      UTL_FILE.FCLOSE(lf_file_handler);
    END IF;
    IF (lv_retcode = cv_status_error) THEN
      --�G���[����
      RAISE global_process_expt;
    END IF;
*/
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
    -- ���̓p�����[�^�Ȃ����b�Z�[�W�o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                  iv_application  => gv_xxccp_msg_kbn
                 ,iv_name         => cv_no_parameter
                 );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    -- ��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
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
END XXCMM003A18C;
/
