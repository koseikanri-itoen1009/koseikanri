CREATE OR REPLACE PACKAGE BODY XXCMM003A28C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2009. All rights reserved.
 *
 * Package Name     : XXCMM003A28C(body)
 * Description      : �ڋq�ꊇ�X�V�p�b�r�u�_�E�����[�h
 * MD.050           : MD050_CMM_003_A28_�ڋq�ꊇ�X�V�pCSV�_�E�����[�h
 * Version          : 1.6
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  file_open              �t�@�C���I�[�v������(A-2)
 *  output_cust_data       �����Ώۃf�[�^���o����(A-3)�E���o���o�͏���(A-4)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/07    1.0   ���� �S��        �V�K�쐬
 *  2009/03/09    1.1   ���� �S��        �t�@�C���o�͐�v���t�@�C�����̕ύX
 *  2009/10/08    1.2   �m�� �d�l        ��QI_E_542�AE_T3_00469�Ή�
 *  2009/10/20    1.3   �v�ۓ� �L        ��Q0001350�Ή�
 *  2010/04/16    1.4   �v�ۓ� �L        ��QE_�{�ғ�_02295�Ή� �o�׌��ۊǏꏊ�̍��ڒǉ�
 *  2011/11/28    1.5   �E �a�d          ��QE_�{�ғ�_07553�Ή� EDI�֘A�̍��ڒǉ�
 *  2012/03/13    1.6   �m�� �d�l        ��QE_�{�ғ�_009272�Ή� �K��Ώۋ敪�̍��ڒǉ�
 *                                                               ��񗓂��ŏI���ڂɏC��
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
  gv_org_id        NUMBER(15)   :=  fnd_global.org_id; --org_id
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
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                CONSTANT VARCHAR2(12)  := 'XXCMM003A28C';      --�p�b�P�[�W��
  cv_comma                   CONSTANT VARCHAR2(1)   := ',';
  --
  cv_header_str_msg          CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00332';            --CSV�t�@�C���w�b�_������
  cv_no_data_msg             CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00301';            --�Ώۃf�[�^0�����b�Z�[�W
  cv_parameter_msg           CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00038';            --���̓p�����[�^�m�[�g
  cv_file_name_msg           CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-05102';            --�t�@�C�����m�[�g
  cv_param                   CONSTANT VARCHAR2(5)   := 'PARAM';                       --�p�����[�^�g�[�N��
  cv_value                   CONSTANT VARCHAR2(5)   := 'VALUE';                       --�p�����[�^�l�g�[�N��
  cv_cust_class              CONSTANT VARCHAR2(8)   := '�ڋq�敪';                    --�p�����[�^�E�ڋq�敪
  cv_ar_invoice_code         CONSTANT VARCHAR2(22)  := '���|�R�[�h�P�i�������j';      --�p�����[�^�E���|�R�[�h�P
  cv_ar_location_code        CONSTANT VARCHAR2(22)  := '���|�R�[�h�Q�i���Ə��j';      --�p�����[�^�E���|�R�[�h�Q
  cv_ar_others_code          CONSTANT VARCHAR2(22)  := '���|�R�[�h�R�i���̑��j';      --�p�����[�^�E���|�R�[�h�R
  cv_kigyou_code             CONSTANT VARCHAR2(10)  := '��ƃR�[�h';                  --�p�����[�^�E��ƃR�[�h
  cv_sales_chain_code        CONSTANT VARCHAR2(26)  := '�`�F�[���X�R�[�h�i�̔���j';  --�p�����[�^�E�`�F�[���X�R�[�h�i�̔���j
  cv_delivery_chain_code     CONSTANT VARCHAR2(26)  := '�`�F�[���X�R�[�h�i�[�i��j';  --�p�����[�^�E�`�F�[���X�R�[�h�i�[�i��j
  cv_policy_chain_code       CONSTANT VARCHAR2(26)  := '�`�F�[���X�R�[�h�i�����p�j';  --�p�����[�^�E�`�F�[���X�R�[�h�i�����p�j
  cv_chain_store_code        CONSTANT VARCHAR2(26)  := '�`�F�[���X�R�[�h�i�d�c�h�j';  --�p�����[�^�E�`�F�[���X�R�[�h�i�d�c�h�j
  cv_gyotai_sho              CONSTANT VARCHAR2(14)  := '�Ƒԁi�����ށj';              --�p�����[�^�E�Ƒԁi�����ށj
  cv_chiku_code              CONSTANT VARCHAR2(10)  := '�n��R�[�h';                  --�p�����[�^�E�n��R�[�h
  cv_file_name               CONSTANT VARCHAR2(9)   := 'FILE_NAME';                   --�t�@�C�����g�[�N��
--
  --�G���[���b�Z�[�W
  cv_profile_err_msg         CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00002';  --�v���t�@�C���擾�G���[
  cv_file_path_err_msg       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00004';  --�t�@�C���p�XNULL�G���[
  cv_file_name_err_msg       CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-10104';  --�t�@�C����NULL�G���[
  cv_file_path_invalid_msg   CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00003';  --�t�@�C���p�X�s���G���[
  cv_file_access_denied_msg  CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-10110';  --�t�@�C���A�N�Z�X�����G���[
  cv_write_err_msg           CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00009';  --CSV�f�[�^�o�̓G���[
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
-- 2009/10/08 Ver1.2 add start by Shigeto.Niki
  gv_process_date           VARCHAR2(8);                                               -- �Ɩ����t(YYYYMMDD)
-- 2009/10/08 Ver1.2 add end by Shigeto.Niki
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
--ver.1.1 2009/03/09 modify start
--    cv_out_file_dir  CONSTANT VARCHAR2(26) := 'XXCMM1_003A28_OUT_FILE_DIR';   -- XXCMM:�ڋq�ꊇ�X�V�pCSV�t�@�C���o�͐�v���t�@�C����
    cv_out_file_dir  CONSTANT VARCHAR2(26) := 'XXCMM1_TMP_OUT';               -- XXCMM:�ڋq�ꊇ�X�V�pCSV�t�@�C���o�͐�v���t�@�C����
--ver.1.1 2009/03/09 modify end
    cv_out_file_file CONSTANT VARCHAR2(27) := 'XXCMM1_003A28_OUT_FILE_FILE';  -- XXCMM:�ڋq�ꊇ�X�V�pCSV�t�@�C�����v���t�@�C����
    cv_ng_profile    CONSTANT VARCHAR2(10) := 'NG_PROFILE';                   -- �v���t�@�C���擾���s�g�[�N��
    cv_invalid_path  CONSTANT VARCHAR2(19) := 'CSV�o�̓f�B���N�g��';          -- �v���t�@�C���擾���s�i�f�B���N�g���j
    cv_invalid_name  CONSTANT VARCHAR2(17) := 'CSV�o�̓t�@�C����';            -- �v���t�@�C���擾���s�i�t�@�C�����j
--
    -- *** ���[�J���ϐ� ***
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
-- 2009/10/08 Ver1.2 add start by Shigeto.Niki
      -- �Ɩ����t��YYYYMMDD�`���Ŏ擾���܂�
      gv_process_date := TO_CHAR(xxccp_common_pkg2.get_process_date,'YYYYMMDD');
-- 2009/10/08 Ver1.2 add end by Shigeto.Niki
--
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
    cn_record_byte CONSTANT NUMBER      := 2047;  --�t�@�C���ǂݍ��ݕ�����
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
      --�A�N�Z�X�����G���[
      WHEN UTL_FILE.ACCESS_DENIED THEN
        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxccp_msg_kbn,
                                              cv_file_access_denied_msg);
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
      gn_target_cnt := 1;
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
   * Procedure Name   : output_cust_data
   * Description      : �����Ώۃf�[�^���o����(A-3)�E���o���o�͏���(A-4)
   ***********************************************************************************/
  PROCEDURE output_cust_data(
    if_file_handler         IN  UTL_FILE.FILE_TYPE,  --   �t�@�C���n���h��
    iv_customer_class       IN  VARCHAR2,            --   �ڋq�敪
    iv_ar_invoice_grp_code  IN  VARCHAR2,            --   ���|�R�[�h�P�i�������j
    iv_ar_location_code     IN  VARCHAR2,            --   ���|�R�[�h�Q�i���Ə��j
    iv_ar_others_code       IN  VARCHAR2,            --   ���|�R�[�h�R�i���̑��j
    iv_kigyou_code          IN  VARCHAR2,            --   ��ƃR�[�h
    iv_sales_chain_code     IN  VARCHAR2,            --   �`�F�[���X�R�[�h�i�̔���j
    iv_delivery_chain_code  IN  VARCHAR2,            --   �`�F�[���X�R�[�h�i�[�i��j
    iv_policy_chain_code    IN  VARCHAR2,            --   �`�F�[���X�R�[�h�i�����p�j
    iv_chain_store_edi      IN  VARCHAR2,            --   �`�F�[���X�R�[�h�i�d�c�h�j
    iv_gyotai_sho           IN  VARCHAR2,            --   �Ƒԁi�����ށj
    iv_chiku_code           IN  VARCHAR2,            --   �n��R�[�h
    ov_errbuf               OUT VARCHAR2,            --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode              OUT VARCHAR2,            --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg               OUT VARCHAR2)            --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
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
    cv_other_to           CONSTANT VARCHAR2(8)     := 'OTHER_TO';               --�g�p�ړI�E���̑�
    cv_aff_dept           CONSTANT VARCHAR2(15)    := 'XX03_DEPARTMENT';        --AFF����}�X�^�Q�ƃ^�C�v
    cv_chain_code         CONSTANT VARCHAR2(16)    := 'XXCMM_CHAIN_CODE';       --�Q�ƃR�[�h�F�`�F�[���X�Q�ƃ^�C�v
    cv_null_x             CONSTANT VARCHAR2(1)     := 'X';                      --NVL�p�_�~�[������
    cn_zero               CONSTANT NUMBER(1)       := 0;                        --NVL�p�_�~�[���l
    cv_customer           CONSTANT VARCHAR2(2)     := '10';                     --�ڋq�敪�E�ڋq
    cv_su_customer        CONSTANT VARCHAR2(2)     := '12';                     --�ڋq�敪�E��l�ڋq
    cv_trust_corp         CONSTANT VARCHAR2(2)     := '13';                     --�ڋq�敪�E�@�l�Ǘ���
    cv_ar_manage          CONSTANT VARCHAR2(2)     := '14';                     --�ڋq�敪�E���|�Ǘ���ڋq
-- 2009/10/20 Ver1.3 add start by Y.Kuboshima
    cv_kyoten_kbn         CONSTANT VARCHAR2(2)     := '1';                      --�ڋq�敪�E���_
    cv_tenpo_kbn          CONSTANT VARCHAR2(2)     := '15';                     --�ڋq�敪�E�X�܉c��
    cv_tonya_kbn          CONSTANT VARCHAR2(2)     := '16';                     --�ڋq�敪�E�≮������
    cv_keikaku_kbn        CONSTANT VARCHAR2(2)     := '17';                     --�ڋq�敪�E�v�旧�ėl
    cv_seikyusho_kbn      CONSTANT VARCHAR2(2)     := '20';                     --�ڋq�敪�E�������p
    cv_tokatu_kbn         CONSTANT VARCHAR2(2)     := '21';                     --�ڋq�敪�E�����������p
    cv_language_ja        CONSTANT VARCHAR2(2)     := 'JA';                     --����E���{��
    cv_ship_to            CONSTANT VARCHAR2(7)     := 'SHIP_TO';                --�g�p�ړI�E�o�א�
    cv_list_type_prl      CONSTANT VARCHAR2(3)     := 'PRL';                    --���i�\���X�g�^�C�v�EPRL
    cv_a_flag             CONSTANT VARCHAR2(2)     := 'A';                      --�X�e�[�^�X�EA
-- 2009/10/20 Ver1.3 add end by Y.Kuboshima
    cv_yes_output         CONSTANT VARCHAR2(1)     := 'Y';                      --�o�͗L���E�L
    cv_no_output          CONSTANT VARCHAR2(1)     := 'N';                      --�o�͗L���E��
    cv_corp_no_data       CONSTANT VARCHAR2(20)    := '�ڋq�@�l��񖢓o�^�B';   --�ڋq�@�l��񖢐ݒ�
    cv_addon_cust_no_data CONSTANT VARCHAR2(20)    := '�ڋq�ǉ���񖢓o�^�B';   --�ڋq�ǉ���񖢐ݒ�
    cv_sales_base_class   CONSTANT VARCHAR2(1)     := '1';                      --�ڋq�敪�E���_
    cv_ng_word            CONSTANT VARCHAR2(7)     := 'NG_WORD';                --CSV�o�̓G���[�g�[�N���ENG_WORD
    cv_err_cust_code_msg  CONSTANT VARCHAR2(16)    := '�G���[�ڋq�R�[�h';       --CSV�o�̓G���[������
    cv_ng_data            CONSTANT VARCHAR2(7)     := 'NG_DATA';                --CSV�o�̓G���[�g�[�N���ENG_DATA
--
    -- *** ���[�J���ϐ� ***
    lv_header_str                  VARCHAR2(2000)  := NULL;                     --�w�b�_���b�Z�[�W�i�[�p�ϐ�
    lv_output_str                  VARCHAR2(2047)  := NULL;                     --�o�͕�����i�[�p�ϐ�
    ln_output_cnt                  NUMBER          := 0;                        --�o�͌���
    lv_sales_kigyou_code           fnd_flex_values.attribute1%TYPE;             --��ƃR�[�h�i�̔���j�i�[�p�ϐ�
    lv_delivery_kigyou_code        fnd_flex_values.attribute1%TYPE;             --��ƃR�[�h�i�[�i��j�i�[�p�ϐ�
    lv_output_excute               VARCHAR2(1)     := 'Y';                      --�o�͗L��
    ln_credit_limit                xxcmm_mst_corporate.credit_limit%TYPE;       --�ڋq�@�l���.�^�M���x�z
    lv_decide_div                  xxcmm_mst_corporate.decide_div%TYPE;         --�ڋq�@�l���.����敪
    lv_information                 VARCHAR2(100)   := NULL;
    lv_sales_base_name             VARCHAR2(50)    := NULL;
    lv_payment_term                VARCHAR2(100)   := NULL;                     --���[�J���ϐ��E�x������
    lv_payment_term_second         VARCHAR2(100)   := NULL;                     --���[�J���ϐ��E��2�x������
    lv_payment_term_third          VARCHAR2(100)   := NULL;                     --���[�J���ϐ��E��3�x������
-- 2009/10/20 Ver1.3 add start by Y.Kuboshima
    lv_price_list                  qp_list_headers_tl.name%TYPE;                --���[�J���ϐ��E���i�\
-- 2009/10/20 Ver1.3 add end by Y.Kuboshima
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- �ڋq�ꊇ�X�V���J�[�\��
    CURSOR cust_data_cur
    IS
      SELECT   hca.cust_account_id                    customer_id,          --�ڋq�h�c
               hca.customer_class_code                customer_class_code,  --�ڋq�敪
               hca.account_number                     customer_code,        --�ڋq�R�[�h
               hp.party_name                          customer_name,        --�ڋq����
               hp.organization_name_phonetic          customer_name_kana,   --�ڋq���̃J�i
               hca.account_name                       customer_name_ryaku,  --����
               hl.postal_code                         postal_code,          --�X�֔ԍ�
               hl.state                               state,                --�s���{��
               hl.city                                city,                 --�s�E��
               hl.address1                            address1,             --�Z��1
               hl.address2                            address2,             --�Z��2
               hl.address3                            address3,             --�n��R�[�h
               hcsu.payment_term_id                   payment_term_id,      --�x������
               hcsu.attribute2                        payment_term_second,  --��2�x������
               hcsu.attribute3                        payment_term_third,   --��3�x������
-- 2009/10/20 Ver1.3 modify start by Y.Kuboshima
--               hcsu.attribute1                        invoice_class,        --���������s�敪
               xca.invoice_printing_unit              invoice_class,        --����������P��
-- 2009/10/20 Ver1.3 modify end by Y.Kuboshima
               hcsu.attribute8                        invoice_sycle,        --���������s�T�C�N��
               hcsu.attribute7                        invoice_form,         --�������o�͌`��
               hcsu.attribute4                        ar_invoice_code,      --���|�R�[�h�P�i�������j
               hcsu.attribute5                        ar_location_code,     --���|�R�[�h�Q�i���Ə��j
               hcsu.attribute6                        ar_others_code,       --���|�R�[�h�R�i���̑��j
-- 2009/10/08 Ver1.2 modify start by Shigeto.Niki
--                CONCAT(ff.attribute7, ff.attribute6)   main_base_code,       --�{���R�[�h
               -- �ŐV�{���R�[�h���擾
               CASE
                 WHEN (ff.attribute6 <= gv_process_date) THEN ff.attribute9  --�V�{���R�[�h
                 ELSE                                         ff.attribute7  --���{���R�[�h
               END                                AS  main_base_code,       --�{���R�[�h
-- 2009/10/08 Ver1.2 modify end by Shigeto.Niki
               xca.customer_id                        addon_customer_id,    --�ڋq�ǉ����.�ڋq�h�c
               xca.sale_base_code                     sale_base_code,       --���㋒�_�R�[�h
               hp.duns_number_c                       customer_status,      --�ڋq�X�e�[�^�X
               xca.stop_approval_reason               approval_reason,      --���~���R
               xca.stop_approval_date                 approval_date,        --���~���ϓ�
               xca.sales_chain_code                   sales_chain_code,     --�`�F�[���X�R�[�h�i�̔���j
               xca.delivery_chain_code                delivery_chain_code,  --�`�F�[���X�R�[�h�i�[�i��j
               xca.policy_chain_code                  policy_chain_code,    --�`�F�[���X�R�[�h�i�c�Ɛ����p�j
               xca.chain_store_code                   chain_store_code,     --�`�F�[���X�R�[�h�i�d�c�h�j
               xca.store_code                         store_code,           --�X�܃R�[�h
               xca.business_low_type                  business_low_type     --�Ƒԁi�����ށj
-- 2009/10/20 Ver1.3 add start by Y.Kuboshima
              ,xca.invoice_code                       invoice_code          --�������p�R�[�h
              ,xca.industry_div                       industry_div          --�Ǝ�
              ,xca.bill_base_code                     bill_base_code        --�������_
              ,xca.receiv_base_code                   receiv_base_code      --�������_
              ,xca.delivery_base_code                 delivery_base_code    --�[�i���_
              ,xca.selling_transfer_div               selling_transfer_div  --������ѐU��
              ,xca.card_company                       card_company          --�J�[�h���
              ,xca.wholesale_ctrl_code                wholesale_ctrl_code   --�≮�Ǘ��R�[�h
              ,hcas.cust_acct_site_id                 cust_acct_site_id     --�ڋq���ݒn�h�c
-- 2009/10/20 Ver1.3 add end by Y.Kuboshima
-- 2010/04/16 Ver1.4 E_�{�ғ�_02295 add start by Y.Kuboshima
              ,xca.ship_storage_code                  ship_storage_code     --�o�׌��ۊǏꏊ
-- 2010/04/16 Ver1.4 E_�{�ғ�_02295 add end by Y.Kuboshima
-- 2011/11/28 Ver1.5 add start by K.Kubo
              ,xca.delivery_order                     delivery_order        --�z�����iEDI�j
              ,xca.edi_district_code                  edi_district_code     --EDI�n��R�[�h�iEDI)
              ,xca.edi_district_name                  edi_district_name     --EDI�n�於�iEDI�j
              ,xca.edi_district_kana                  edi_district_kana     --EDI�n�於�J�i�iEDI�j
              ,xca.tsukagatazaiko_div                 tsukagatazaiko_div    --�ʉߍ݌Ɍ^�敪�iEDI�j
              ,xca.deli_center_code                   deli_center_code      --EDI�[�i�Z���^�[�R�[�h
              ,xca.deli_center_name                   deli_center_name      --EDI�[�i�Z���^�[��
              ,xca.edi_forward_number                 edi_forward_number    --EDI�`���ǔ�
              ,xca.cust_store_name                    cust_store_name       --�ڋq�X�ܖ���
              ,xca.torihikisaki_code                  torihikisaki_code     --�����R�[�h
-- 2011/11/28 Ver1.5 add end by K.Kubo
-- 2012/03/13 Ver1.6 E_�{�ғ�_09272 add start by S.Niki
              ,xca.vist_target_div                    vist_target_div       --�K��Ώۋ敪
-- 2012/03/13 Ver1.6 E_�{�ғ�_09272 add end by S.Niki
      FROM     hz_cust_accounts     hca,
               hz_cust_acct_sites   hcas,
               hz_cust_site_uses    hcsu,
               hz_parties           hp,
               hz_party_sites       hps,
               hz_locations         hl,
               xxcmm_cust_accounts  xca,
               (SELECT ffv.flex_value fv,
                       ffv.attribute6 attribute6,
-- 2009/10/08 Ver1.2 add start by Shigeto.Niki
                       ffv.attribute9 attribute9,
-- 2009/10/08 Ver1.2 add end by Shigeto.Niki
                       ffv.attribute7 attribute7
                FROM   fnd_flex_value_sets  ffvs,
                       fnd_flex_values      ffv
                WHERE  ffvs.flex_value_set_name = cv_aff_dept
                AND    ffvs.flex_value_set_id   = ffv.flex_value_set_id
               ) ff
      WHERE    hca.customer_class_code   = NVL(iv_customer_class, hca.customer_class_code)
      AND      hca.cust_account_id       = hcas.cust_account_id
      AND      hcas.cust_acct_site_id    = hcsu.cust_acct_site_id
      AND      ((hcsu.site_use_code      = cv_bill_to
               AND hca.customer_class_code IN (cv_customer, cv_su_customer, cv_ar_manage))
      OR       (hcsu.site_use_code       = cv_other_to
               AND hca.customer_class_code NOT IN (cv_customer, cv_su_customer, cv_ar_manage)))
      AND      hca.party_id              = hp.party_id
      AND      hp.party_id               = hps.party_id
      AND      hps.location_id           = hl.location_id
      AND      xca.customer_id (+)       = hca.cust_account_id
      AND      ff.fv (+)                 = NVL(xca.sale_base_code, cv_null_x)
      AND      (hcsu.attribute4          = iv_ar_invoice_grp_code OR iv_ar_invoice_grp_code IS NULL)
      AND      (hcsu.attribute5          = iv_ar_location_code    OR iv_ar_location_code    IS NULL)
      AND      (hcsu.attribute6          = iv_ar_others_code      OR iv_ar_others_code      IS NULL)
-- 2009/10/20 Ver1.3 modify start by Y.Kuboshima
--      AND      (((hca.customer_class_code IN (cv_customer, cv_ar_manage)) AND (xca.sales_chain_code    = iv_sales_chain_code))
--      OR       (iv_sales_chain_code    IS NULL))
--      AND      (((hca.customer_class_code IN (cv_customer, cv_ar_manage)) AND (xca.delivery_chain_code = iv_delivery_chain_code))
--      OR       (iv_delivery_chain_code IS NULL))
      -- �ڋq�敪'12','15','16'�ǉ�
      AND      (((hca.customer_class_code IN (cv_customer, cv_su_customer, cv_ar_manage, cv_tenpo_kbn, cv_tonya_kbn))
        AND      (xca.sales_chain_code    = iv_sales_chain_code))
      OR       (iv_sales_chain_code    IS NULL))
      -- �ڋq�敪'12','15','16'�ǉ�
      AND      (((hca.customer_class_code IN (cv_customer, cv_su_customer, cv_ar_manage, cv_tenpo_kbn, cv_tonya_kbn))
        AND      (xca.delivery_chain_code = iv_delivery_chain_code))
      OR       (iv_delivery_chain_code IS NULL))
-- 2009/10/20 Ver1.3 modify end by Y.Kuboshima
      AND      (((hca.customer_class_code IN (cv_customer, cv_ar_manage)) AND (xca.policy_chain_code   = iv_policy_chain_code))
      OR       (iv_policy_chain_code   IS NULL))
      AND      (((hca.customer_class_code IN (cv_customer, cv_ar_manage)) AND (xca.chain_store_code    = iv_chain_store_edi))
      OR       (iv_chain_store_edi     IS NULL))
      AND      ((xca.business_low_type   = iv_gyotai_sho) OR (iv_gyotai_sho IS NULL))
      AND      ((hl.address3             = iv_chiku_code) OR (iv_chiku_code IS NULL))
      AND      hcas.org_id = gv_org_id
      AND      hcsu.org_id = gv_org_id
      AND      hcas.party_site_id        = hps.party_site_id
      AND      hps.location_id           = (SELECT MIN(hpsiv.location_id)
                                            FROM   hz_cust_acct_sites hcasiv,
                                                   hz_party_sites     hpsiv
                                            WHERE  hcasiv.cust_account_id = hca.cust_account_id
                                            AND    hcasiv.party_site_id   = hpsiv.party_site_id)
-- 2009/10/20 Ver1.3 add start by Y.Kuboshima
      AND      hca.customer_class_code <> cv_kyoten_kbn
      AND      hcsu.status               = cv_a_flag
-- 2009/10/20 Ver1.3 add end by Y.Kuboshima
      ORDER BY main_base_code, customer_code
      ;
--
    -- �ڋq�ꊇ�X�V���J�[�\�����R�[�h�^
    cust_data_rec cust_data_cur%ROWTYPE;
--
    -- ��ƃR�[�h�擾�J�[�\��
    CURSOR get_kigyou_cur(
      iv_chain_code  IN VARCHAR2)
    IS
      SELECT flvv.attribute1       kigyou_code
      FROM   fnd_lookup_values_vl  flvv
      WHERE  flvv.lookup_type = cv_chain_code
      AND    flvv.lookup_code = iv_chain_code
      ;
    -- ��ƃR�[�h�擾�J�[�\�����R�[�h�^
    get_kigyou_rec get_kigyou_cur%ROWTYPE;
--
    -- ���㋒�_���̎擾�J�[�\��
    CURSOR get_sales_base_name_cur(
      iv_base_code  IN VARCHAR2)
    IS
      SELECT hp.party_name     sales_base_name
      FROM   hz_cust_accounts  hca,
             hz_parties        hp
      WHERE  hca.party_id            = hp.party_id
      AND    hca.customer_class_code = cv_sales_base_class
      AND    hca.account_number      = iv_base_code
      ;
    -- ���㋒�_���̎擾�J�[�\�����R�[�h�^
    get_sales_base_name_rec get_sales_base_name_cur%ROWTYPE;
--
    -- �x�������擾�J�[�\��
    CURSOR get_payment_term_cur(
      iv_payment_term_id IN VARCHAR2)
    IS
      SELECT rt.name     payment_name
      FROM   ra_terms    rt
      WHERE  rt.term_id  = iv_payment_term_id
      ;
    -- �x�������`�F�b�N�J�[�\�����R�[�h�^
    get_payment_term_rec  get_payment_term_cur%ROWTYPE;
--
-- 2009/10/20 Ver1.3 add start by Y.Kuboshima
    -- ���i�\�擾�J�[�\��
    CURSOR get_price_list_cur(
      in_cust_acct_site_id IN NUMBER)
    IS
      SELECT qlht.name price_list
      FROM   hz_cust_site_uses  hcsu
            ,qp_list_headers_tl qlht
            ,qp_list_headers_b  qlhb
      WHERE  hcsu.price_list_id     = qlhb.list_header_id
      AND    qlht.list_header_id    = qlhb.list_header_id
      AND    qlht.source_lang       = cv_language_ja
      AND    qlht.language          = cv_language_ja
      AND    qlhb.orig_org_id       = fnd_global.org_id
      AND    qlhb.list_type_code    = cv_list_type_prl
      AND    hcsu.site_use_code     = cv_ship_to
      AND    hcsu.cust_acct_site_id = in_cust_acct_site_id
      ;
    -- ���i�\�`�F�b�N�J�[�\�����R�[�h�^
    get_price_list_rec  get_price_list_cur%ROWTYPE;
-- 2009/10/20 Ver1.3 add end by Y.Kuboshima
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    lv_header_str := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_header_str_msg);
    UTL_FILE.PUT_LINE(if_file_handler,lv_header_str);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_header_str);
--
    --�ڋq�ꊇ�X�V���J�[�\�����[�v
    << cust_for_loop >>
    FOR cust_data_rec IN cust_data_cur
    LOOP
      IF (iv_kigyou_code IS NOT NULL) THEN
        --��ƃR�[�h���͎��͔���O�̃��R�[�h�͏o�͂��Ȃ�
        lv_output_excute := cv_no_output;
      END IF;
      -- ===============================
      -- ��ƃR�[�h�擾�E�p�����[�^�`�F�b�N
      -- ===============================
      IF   (cust_data_rec.customer_class_code = cv_customer
        OR  cust_data_rec.customer_class_code = cv_ar_manage
-- 2009/10/20 Ver1.3 add start by Y.Kuboshima
        OR  cust_data_rec.customer_class_code = cv_su_customer
        OR  cust_data_rec.customer_class_code = cv_tenpo_kbn
        OR  cust_data_rec.customer_class_code = cv_tonya_kbn)
-- 2009/10/20 Ver1.3 add end by Y.Kuboshima
      THEN
        IF (cust_data_rec.sales_chain_code IS NOT NULL) THEN
          << sales_kigyou_loop >>
          FOR get_kigyou_rec IN get_kigyou_cur( cust_data_rec.sales_chain_code )
          LOOP
            lv_sales_kigyou_code := get_kigyou_rec.kigyou_code;
          END LOOP sales_kigyou_loop;
        END IF;
        IF (cust_data_rec.delivery_chain_code IS NOT NULL) THEN
          << delivery_kigyou_loop >>
          FOR get_kigyou_rec IN get_kigyou_cur( cust_data_rec.delivery_chain_code )
          LOOP
            lv_delivery_kigyou_code := get_kigyou_rec.kigyou_code;
          END LOOP delivery_kigyou_loop;
        END IF;
        IF    (iv_kigyou_code = lv_sales_kigyou_code)
          OR  (iv_kigyou_code = lv_delivery_kigyou_code)
        THEN
          lv_output_excute := cv_yes_output;
        END IF;
      END IF;
--
      --��ƃR�[�h�`�F�b�N�̏o�͎��s���肪Y�̂Ƃ��̂݁A�o�͕�������쐬�A�o��
      IF (lv_output_excute = cv_yes_output) THEN
--
        --�ڋq�敪���@�l�Ǘ���ڋq�̏ꍇ
        IF (cust_data_rec.customer_class_code = cv_trust_corp) THEN
          -- ===============================
          -- �ڋq�@�l���}�X�^�擾
          -- ===============================
          BEGIN
            SELECT xmc.credit_limit  credit_limit,
                   xmc.decide_div    decide_div
            INTO   ln_credit_limit,
                   lv_decide_div
            FROM   xxcmm_mst_corporate xmc
            WHERE  xmc.customer_id = cust_data_rec.customer_id;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              lv_information := cv_corp_no_data;
          END;
        END IF;
--
-- 2009/10/20 Ver1.3 add start by Y.Kuboshima
        --�ڋq�敪'10','12'�̏ꍇ
        IF (cust_data_rec.customer_class_code IN (cv_customer, cv_su_customer)) THEN
          -- ===============================
          -- ���i�\�}�X�^�擾
          -- ===============================
          << price_list_loop >>
          FOR get_price_list_rec IN get_price_list_cur( cust_data_rec.cust_acct_site_id )
          LOOP
            lv_price_list := get_price_list_rec.price_list;
          END LOOP price_list_loop;
        END IF;
-- 2009/10/20 Ver1.3 add end by Y.Kuboshima
        -- ===============================
        -- �o�͒l�ݒ�
        -- ===============================
        --�ڋq�ǉ���񖢐ݒ莞�A��񗓂ɕ����ǉ�
        IF (cust_data_rec.addon_customer_id IS NULL) THEN
          lv_information := lv_information || cv_addon_cust_no_data;
        END IF;
--
        --�ڋq�敪�ɂ���āA���荀�ڂ�NULL�ݒ�
        IF   (cust_data_rec.customer_class_code <> cv_customer
          AND cust_data_rec.customer_class_code <> cv_su_customer
          AND cust_data_rec.customer_class_code <> cv_ar_manage)
        THEN
          cust_data_rec.ar_invoice_code      := NULL;
          cust_data_rec.ar_location_code     := NULL;
          cust_data_rec.ar_others_code       := NULL;
-- 2009/10/20 Ver1.3 delete start by Y.Kuboshima
--          cust_data_rec.invoice_class        := NULL;
-- 2009/10/20 Ver1.3 delete end by Y.Kuboshima
          cust_data_rec.invoice_sycle        := NULL;
          cust_data_rec.invoice_form         := NULL;
          cust_data_rec.payment_term_id      := NULL;
          cust_data_rec.payment_term_second  := NULL;
          cust_data_rec.payment_term_third   := NULL;
        END IF;
        IF   (cust_data_rec.customer_class_code <> cv_customer
          AND cust_data_rec.customer_class_code <> cv_ar_manage)
        THEN
-- 2009/10/20 Ver1.3 delete start by Y.Kuboshima
--          cust_data_rec.sales_chain_code     := NULL;
--          lv_sales_kigyou_code               := NULL;
--          cust_data_rec.delivery_chain_code  := NULL;
--          lv_delivery_kigyou_code            := NULL;
-- 2009/10/20 Ver1.3 delete end by Y.Kuboshima
          cust_data_rec.policy_chain_code    := NULL;
          cust_data_rec.chain_store_code     := NULL;
          cust_data_rec.store_code           := NULL;
        END IF;
        --
-- 2009/10/20 Ver1.3 add start by Y.Kuboshima
        -- �ڋq�敪'10','12','14','15','16'�ȊO�̏ꍇ
        IF (cust_data_rec.customer_class_code NOT IN (cv_customer, cv_su_customer, cv_ar_manage, cv_tenpo_kbn, cv_tonya_kbn)) THEN
          -- �`�F�[���X�R�[�h�i�̔���j,��ƃR�[�h�i�̔���j,�`�F�[���X�R�[�h�i�[�i��j,��ƃR�[�h�i�[�i��j��NULL���Z�b�g
          cust_data_rec.sales_chain_code     := NULL;
          lv_sales_kigyou_code               := NULL;
          cust_data_rec.delivery_chain_code  := NULL;
          lv_delivery_kigyou_code            := NULL;
        END IF;
        --
        -- �ڋq�敪'10','12','13','14','15','16','17'�ȊO�̏ꍇ
        IF (cust_data_rec.customer_class_code NOT IN (cv_customer, cv_su_customer, cv_trust_corp, cv_ar_manage, cv_tenpo_kbn, cv_tonya_kbn, cv_keikaku_kbn)) THEN
          -- �Ƒ�(������),�Ǝ�,������ѐU��,�≮�Ǘ��R�[�h��NULL���Z�b�g
          cust_data_rec.business_low_type    := NULL;
          cust_data_rec.industry_div         := NULL;
          cust_data_rec.selling_transfer_div := NULL;
          cust_data_rec.wholesale_ctrl_code  := NULL;
-- 2010/04/16 Ver1.4 E_�{�ғ�_02295 add start by Y.Kuboshima
          cust_data_rec.ship_storage_code    := NULL;
-- 2010/04/16 Ver1.4 E_�{�ғ�_02295 add end by Y.Kuboshima
        END IF;
        --
        -- �ڋq�敪'10','12','14','20','21'�ȊO�̏ꍇ
        IF (cust_data_rec.customer_class_code NOT IN (cv_customer, cv_su_customer, cv_ar_manage, cv_seikyusho_kbn, cv_tokatu_kbn)) THEN
          -- �������_��NULL���Z�b�g
          cust_data_rec.bill_base_code       := NULL;
        END IF;
        --
        -- �ڋq�敪'10','12','14'�ȊO�̏ꍇ
        IF (cust_data_rec.customer_class_code NOT IN (cv_customer, cv_su_customer, cv_ar_manage)) THEN
          -- �������_,�[�i���_��NULL���Z�b�g
          cust_data_rec.receiv_base_code     := NULL;
          cust_data_rec.delivery_base_code   := NULL;
        END IF;
        --
        -- �ڋq�敪'10'�ȊO�̏ꍇ
        IF (cust_data_rec.customer_class_code <> cv_customer) THEN
          -- �J�[�h���,�������p�R�[�h��NULL���Z�b�g
          cust_data_rec.card_company         := NULL;
          cust_data_rec.invoice_code         := NULL;
        END IF;
        --
-- 2009/10/20 Ver1.3 add end by Y.Kuboshima
--
        --���㋒�_���̎擾
        << seles_base_name_loop >>
        FOR get_sales_base_name_rec IN get_sales_base_name_cur( cust_data_rec.sale_base_code )
        LOOP
          lv_sales_base_name := get_sales_base_name_rec.sales_base_name;
        END LOOP seles_base_name_loop;
--
      --�ڋq�敪'10'(�ڋq)�A'12'(��l�ڋq)�A'14'(���|�Ǘ���ڋq)�̂Ƃ��̂݁A�x�������E��2�x�������E��3�x�������擾�E�ݒ�
      IF (cust_data_rec.customer_class_code   = cv_customer)
        OR (cust_data_rec.customer_class_code = cv_su_customer)
        OR (cust_data_rec.customer_class_code = cv_ar_manage) THEN
        --�x�������擾
        << get_payment_term_loop >>
        FOR get_payment_term_rec IN get_payment_term_cur( cust_data_rec.payment_term_id )
        LOOP
          lv_payment_term := get_payment_term_rec.payment_name;
        END LOOP get_payment_term_loop;
        --��2�x�������擾
        << get_payment_term_loop >>
        FOR get_payment_term_rec IN get_payment_term_cur( cust_data_rec.payment_term_second )
        LOOP
          lv_payment_term_second := get_payment_term_rec.payment_name;
        END LOOP get_payment_term_loop;
        --��3�x�������擾
        << get_payment_term_loop >>
        FOR get_payment_term_rec IN get_payment_term_cur( cust_data_rec.payment_term_third )
        LOOP
          lv_payment_term_third := get_payment_term_rec.payment_name;
        END LOOP get_payment_term_loop;
      END IF;
--
        --�o�͕�����쐬
        lv_output_str := SUBSTRB(cust_data_rec.customer_class_code,1,2);                               --�ڋq�敪
-- 2009/10/08 Ver1.2 modify start by Shigeto.Niki        
--        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.main_base_code,1,7);       --�{���R�[�h
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.main_base_code,1,6);       --�{���R�[�h
-- 2009/10/08 Ver1.2 modify end by Shigeto.Niki
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.sale_base_code,1,4);       --���㋒�_�R�[�h
        lv_output_str := lv_output_str || cv_comma || lv_sales_base_name;                              --���㋒�_����
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.customer_code,1,9);        --�ڋq�R�[�h
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.customer_name,1,100);      --�ڋq����
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.customer_name_kana,1,50);  --�ڋq���̃J�i
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.customer_name_ryaku,1,80); --����
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.customer_status,1,2);      --�ڋq�X�e�[�^�X
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.approval_reason,1,1);      --���~���ϗ��R
        lv_output_str := lv_output_str || cv_comma || TO_CHAR(cust_data_rec.approval_date,'YYYY/MM/DD');  --���~���ϓ�
        lv_output_str := lv_output_str || cv_comma || TO_CHAR(ln_credit_limit);                        --�^�M���x�z
        lv_output_str := lv_output_str || cv_comma || lv_decide_div;                                   --����敪
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.ar_invoice_code,1,12);     --���|�R�[�h�P�i�������j
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.ar_location_code,1,12);    --���|�R�[�h�Q�i���Ə��j
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.ar_others_code,1,12);      --���|�R�[�h�R�i���̑��j
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.invoice_class,1,1);        --����������敪
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.invoice_sycle,1,1);        --���������s�T�C�N��
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.invoice_form,1,1);         --�������o�͌`��
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(lv_payment_term,1,8);                    --�x������
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(lv_payment_term_second,1,8);             --��2�x������
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(lv_payment_term_third,1,8);              --��3�x������
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.sales_chain_code,1,9);     --�`�F�[���X�R�[�h�i�̔���j
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(lv_sales_kigyou_code,1,6);               --��ƃR�[�h�i�̔���j
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.delivery_chain_code,1,9);  --�`�F�[���X�R�[�h�i�[�i��j
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(lv_delivery_kigyou_code,1,6);            --��ƃR�[�h�i�[�i��j
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.policy_chain_code,1,30);   --�`�F�[���X�R�[�h�i�c�Ɛ����p�j
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.chain_store_code,1,4);     --�`�F�[���X�R�[�h�i�d�c�h�j
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.store_code,1,10);          --�X�܃R�[�h
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.business_low_type,1,2);    --�Ƒԁi�����ށj
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.postal_code,1,7);          --�X�֔ԍ�
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.state,1,30);               --�s���{��
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.city,1,30);                --�s�E��
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.address1,1,240);           --�Z��1
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.address2,1,240);           --�Z��2
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.address3,1,5);             --�n��R�[�h
-- 2009/10/20 Ver1.3 add start by Y.Kuboshima
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.invoice_code,1,9);         --�������p�R�[�h
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.industry_div,1,2);         --�Ǝ�
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.bill_base_code,1,4);       --�������_
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.receiv_base_code,1,4);     --�������_
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.delivery_base_code,1,4);   --�[�i���_
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.selling_transfer_div,1,4); --������ѐU��
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.card_company,1,9);         --�J�[�h���
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.wholesale_ctrl_code,1,9);  --�≮�Ǘ��R�[�h
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(lv_price_list,1,240);                    --���i�\
-- 2009/10/20 Ver1.3 add end by Y.Kuboshima
-- 2010/04/16 Ver1.4 E_�{�ғ�_02295 add start by Y.Kuboshima
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.ship_storage_code,1,10);   --�o�׌��ۊǏꏊ
-- 2010/04/16 Ver1.4 E_�{�ғ�_02295 add end by Y.Kuboshima
-- 2012/03/13 Ver1.6 E_�{�ғ�_09272 del start by S.Niki
--        lv_output_str := lv_output_str || cv_comma || SUBSTRB(lv_information,1,100);                   --���
-- 2012/03/13 Ver1.6 E_�{�ғ�_09272 del end by S.Niki
-- 2011/11/28 Ver1.5 add start by K.Kubo
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.delivery_order,1,14);      --�z�����iEDI�j
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.edi_district_code,1,8);    --EDI�n��R�[�h�iEDI)
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.edi_district_name,1,40);   --EDI�n�於�iEDI�j
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.edi_district_kana,1,20);   --EDI�n�於�J�i�iEDI�j
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.tsukagatazaiko_div,1,2);   --�ʉߍ݌Ɍ^�敪�iEDI�j
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.deli_center_code,1,8);     --EDI�[�i�Z���^�[�R�[�h
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.deli_center_name,1,20);    --EDI�[�i�Z���^�[��
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.edi_forward_number,1,2);   --EDI�`���ǔ�
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.cust_store_name,1,30);     --�ڋq�X�ܖ���
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.torihikisaki_code,1,8);    --�����R�[�h
-- 2011/11/28 Ver1.5 add end by K.Kubo
-- 2012/03/13 Ver1.6 E_�{�ғ�_09272 add start by S.Niki
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.vist_target_div,1,1);      --�K��Ώۋ敪
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(lv_information,1,100);                   --���
-- 2012/03/13 Ver1.6 E_�{�ғ�_09272 add end by S.Niki
--
        --������o��
        BEGIN
          --csv�t�@�C���o��
          UTL_FILE.PUT_LINE(if_file_handler,lv_output_str);
          --�R���J�����g�o��
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_output_str);
        EXCEPTION
          WHEN UTL_FILE.WRITE_ERROR THEN  --*** �t�@�C���������݃G���[ ***
            lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                                  cv_write_err_msg,
                                                  cv_ng_word,
                                                  cv_err_cust_code_msg,
                                                  cv_ng_data,
                                                  cust_data_rec.customer_code);
            lv_errbuf  := lv_errmsg;
          RAISE write_failure_expt;
        END;
        --�o�͌����J�E���g
        ln_output_cnt := ln_output_cnt + 1;
      END IF;
--
      --�ϐ�������
      lv_output_str           := NULL;
      lv_sales_kigyou_code    := NULL;
      lv_delivery_kigyou_code := NULL;
      lv_output_excute        := cv_yes_output;
      ln_credit_limit         := NULL;
      lv_decide_div           := NULL;
      lv_information          := NULL;
      lv_sales_base_name      := NULL;
      lv_payment_term         := NULL;
      lv_payment_term_second  := NULL;
      lv_payment_term_third   := NULL;
-- 2009/10/20 Ver1.3 add start by Y.Kuboshima
      lv_price_list           := NULL;
-- 2009/10/20 Ver1.3 add end by Y.Kuboshima
--
    END LOOP cust_for_loop;
--
    gn_target_cnt := ln_output_cnt;
    gn_normal_cnt := ln_output_cnt;
--
    --�Ώۃf�[�^0�����A���b�Z�[�W���o�͂�RAISE����B��G���[����
    IF (ln_output_cnt = 0) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                            cv_no_data_msg);
      lv_errbuf := lv_errmsg;
      --csv�t�@�C���o��
      UTL_FILE.PUT_LINE(if_file_handler,'');
      UTL_FILE.PUT_LINE(if_file_handler,lv_errmsg);
      --�R���J�����g�o��
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      RAISE no_date_err_expt;
    END IF;
--
  EXCEPTION
    WHEN no_date_err_expt THEN                         --*** �Ώۃf�[�^0�� ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_normal;
    WHEN write_failure_expt THEN                       --*** CSV�f�[�^�o�̓G���[ ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      --CSV�f�[�^�o�̓G���[���A�Ώی����A�G���[������1���Œ�Ƃ���
      gn_target_cnt := 1;
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
  END output_cust_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_customer_class         IN  VARCHAR2,     --�ڋq�敪
    iv_ar_invoice_grp_code    IN  VARCHAR2,     --���|�R�[�h�P�i�������j
    iv_ar_location_code       IN  VARCHAR2,     --���|�R�[�h�Q�i���Ə��j
    iv_ar_others_code         IN  VARCHAR2,     --���|�R�[�h�R�i���̑��j
    iv_kigyou_code            IN  VARCHAR2,     --��ƃR�[�h
    iv_sales_chain_code       IN  VARCHAR2,     --�`�F�[���X�R�[�h�i�̔���j
    iv_delivery_chain_code    IN  VARCHAR2,     --�`�F�[���X�R�[�h�i�[�i��j
    iv_policy_chain_code      IN  VARCHAR2,     --�`�F�[���X�R�[�h�i�����p�j
    iv_chain_store_edi        IN  VARCHAR2,     --�`�F�[���X�R�[�h�i�d�c�h�j
    iv_gyotai_sho             IN  VARCHAR2,     --�Ƒԁi�����ށj
    iv_chiku_code             IN  VARCHAR2,     --�n��R�[�h
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
--
    --�p�����[�^�o��
    --�ڋq�敪
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_xxcmm_msg_kbn
                    ,iv_name         => cv_parameter_msg
                    ,iv_token_name1  => cv_param
                    ,iv_token_value1 => cv_cust_class
                    ,iv_token_name2  => cv_value
                    ,iv_token_value2 => iv_customer_class
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --���|�R�[�h�P
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_xxcmm_msg_kbn
                    ,iv_name         => cv_parameter_msg
                    ,iv_token_name1  => cv_param
                    ,iv_token_value1 => cv_ar_invoice_code
                    ,iv_token_name2  => cv_value
                    ,iv_token_value2 => iv_ar_invoice_grp_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --���|�R�[�h�Q
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_xxcmm_msg_kbn
                    ,iv_name         => cv_parameter_msg
                    ,iv_token_name1  => cv_param
                    ,iv_token_value1 => cv_ar_location_code
                    ,iv_token_name2  => cv_value
                    ,iv_token_value2 => iv_ar_location_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --���|�R�[�h�R
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_xxcmm_msg_kbn
                    ,iv_name         => cv_parameter_msg
                    ,iv_token_name1  => cv_param
                    ,iv_token_value1 => cv_ar_others_code
                    ,iv_token_name2  => cv_value
                    ,iv_token_value2 => iv_ar_others_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --��ƃR�[�h
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_xxcmm_msg_kbn
                    ,iv_name         => cv_parameter_msg
                    ,iv_token_name1  => cv_param
                    ,iv_token_value1 => cv_kigyou_code
                    ,iv_token_name2  => cv_value
                    ,iv_token_value2 => iv_kigyou_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --�`�F�[���X�R�[�h�i�̔���j
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_xxcmm_msg_kbn
                    ,iv_name         => cv_parameter_msg
                    ,iv_token_name1  => cv_param
                    ,iv_token_value1 => cv_sales_chain_code
                    ,iv_token_name2  => cv_value
                    ,iv_token_value2 => iv_sales_chain_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --�`�F�[���X�R�[�h�i�[�i��j
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_xxcmm_msg_kbn
                    ,iv_name         => cv_parameter_msg
                    ,iv_token_name1  => cv_param
                    ,iv_token_value1 => cv_delivery_chain_code
                    ,iv_token_name2  => cv_value
                    ,iv_token_value2 => iv_delivery_chain_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --�`�F�[���X�R�[�h�i�����p�j
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_xxcmm_msg_kbn
                    ,iv_name         => cv_parameter_msg
                    ,iv_token_name1  => cv_param
                    ,iv_token_value1 => cv_policy_chain_code
                    ,iv_token_name2  => cv_value
                    ,iv_token_value2 => iv_policy_chain_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --�`�F�[���X�R�[�h�i�d�c�h�j
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_xxcmm_msg_kbn
                    ,iv_name         => cv_parameter_msg
                    ,iv_token_name1  => cv_param
                    ,iv_token_value1 => cv_chain_store_code
                    ,iv_token_name2  => cv_value
                    ,iv_token_value2 => iv_chain_store_edi
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --�Ƒԁi�����ށj
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_xxcmm_msg_kbn
                    ,iv_name         => cv_parameter_msg
                    ,iv_token_name1  => cv_param
                    ,iv_token_value1 => cv_gyotai_sho
                    ,iv_token_name2  => cv_value
                    ,iv_token_value2 => iv_gyotai_sho
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --�n��R�[�h
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_xxcmm_msg_kbn
                    ,iv_name         => cv_parameter_msg
                    ,iv_token_name1  => cv_param
                    ,iv_token_value1 => cv_chiku_code
                    ,iv_token_name2  => cv_value
                    ,iv_token_value2 => iv_chiku_code
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
      ,iv_customer_class       -- �ڋq�敪
      ,iv_ar_invoice_grp_code  -- ���|�R�[�h�P�i�������j
      ,iv_ar_location_code     -- ���|�R�[�h�Q�i���Ə��j
      ,iv_ar_others_code       -- ���|�R�[�h�R�i���̑��j
      ,iv_kigyou_code          -- ��ƃR�[�h
      ,iv_sales_chain_code     -- �`�F�[���X�R�[�h�i�̔���j
      ,iv_delivery_chain_code  -- �`�F�[���X�R�[�h�i�[�i��j
      ,iv_policy_chain_code    -- �`�F�[���X�R�[�h�i�����p�j
      ,iv_chain_store_edi      -- �`�F�[���X�R�[�h�i�d�c�h�j
      ,iv_gyotai_sho           -- �Ƒԁi�����ށj
      ,iv_chiku_code           -- �n��R�[�h
      ,lv_errbuf               -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode              -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- ===============================
    -- �I������(A-5)
    -- ===============================
    --�t�@�C���N���[�Y����
    IF (UTL_FILE.IS_OPEN(lf_file_handler)) THEN
      --�t�@�C���N���[�Y
      UTL_FILE.FCLOSE(lf_file_handler);
    END IF;
    IF (lv_retcode = cv_status_error) THEN
      --�G���[����
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
    iv_customer_class         IN  VARCHAR2,     --�ڋq�敪
    iv_ar_invoice_grp_code    IN  VARCHAR2,     --���|�R�[�h�P�i�������j
    iv_ar_location_code       IN  VARCHAR2,     --���|�R�[�h�Q�i���Ə��j
    iv_ar_others_code         IN  VARCHAR2,     --���|�R�[�h�R�i���̑��j
    iv_kigyou_code            IN  VARCHAR2,     --��ƃR�[�h
    iv_sales_chain_code       IN  VARCHAR2,     --�`�F�[���X�R�[�h�i�̔���j
    iv_delivery_chain_code    IN  VARCHAR2,     --�`�F�[���X�R�[�h�i�[�i��j
    iv_policy_chain_code      IN  VARCHAR2,     --�`�F�[���X�R�[�h�i�����p�j
    iv_chain_store_edi        IN  VARCHAR2,     --�`�F�[���X�R�[�h�i�d�c�h�j
    iv_gyotai_sho             IN  VARCHAR2,     --�Ƒԁi�����ށj
    iv_chiku_code             IN  VARCHAR2      --�n��R�[�h
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
       iv_customer_class         --�ڋq�敪
      ,iv_ar_invoice_grp_code    --���|�R�[�h�P�i�������j
      ,iv_ar_location_code       --���|�R�[�h�Q�i���Ə��j
      ,iv_ar_others_code         --���|�R�[�h�R�i���̑��j
      ,iv_kigyou_code            --��ƃR�[�h
      ,iv_sales_chain_code       --�`�F�[���X�R�[�h�i�̔���j
      ,iv_delivery_chain_code    --�`�F�[���X�R�[�h�i�[�i��j
      ,iv_policy_chain_code      --�`�F�[���X�R�[�h�i�����p�j
      ,iv_chain_store_edi        --�`�F�[���X�R�[�h�i�d�c�h�j
      ,iv_gyotai_sho             --�Ƒԁi�����ށj
      ,iv_chiku_code             --�n��R�[�h
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
END XXCMM003A28C;
/
