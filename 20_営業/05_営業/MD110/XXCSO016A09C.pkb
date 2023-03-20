CREATE OR REPLACE PACKAGE BODY XXCSO016A09C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2022. All rights reserved.
 *
 * Package Name     : XXCSO016A09C(body)
 * Description      : ���̋@�ڋq�ʎx���Ǘ������n�V�X�e���֘A�g���邽�߂�
 *                    �b�r�u�t�@�C�����쐬���܂��B
 * MD.050           : MD050_CSO_016_A09_���n-EBS�C���^�[�t�F�[�X�F
 *                    (OUT)���̋@�ڋq�ʎx���Ǘ�
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   �������� (A-1)
 *  get_profile_info       �v���t�@�C���l�擾 (A-2)
 *  open_csv_file          ���̋@�ڋq�ʎx���Ǘ��f�[�^CSV�t�@�C���I�[�v�� (A-3)
 *  create_csv_rec         ���̋@�ڋq�ʎx���Ǘ��f�[�^CSV�o�� (A-5)
 *  close_csv_file         CSV�t�@�C���N���[�Y����   (A-6)
 *  submain                ���C�������v���V�[�W��
 *                           ���̋@�ڋq�ʎx���Ǘ����o (A-4)
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                           �I������ (A-7)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2022-08-25    1.0   Kodai.Tomie     �V�K�쐬 E_�{�ғ�_18060
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
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCSO016A09C';  -- �p�b�P�[�W��
  cv_app_name            CONSTANT VARCHAR2(5)   := 'XXCSO';         -- �A�v���P�[�V�����Z�k��
  -- ���b�Z�[�W�R�[�h
  cv_tkn_number_01       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00014';  -- �v���t�@�C���擾�G���[
  cv_tkn_number_02       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00123';  -- CSV�t�@�C���c���G���[���b�Z�[�W
  cv_tkn_number_03       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00015';  -- CSV�t�@�C���I�[�v���G���[
  cv_tkn_number_04       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00923';  -- CSV�t�@�C���o�̓G���[(���̋@�ڋq�ʎx���Ǘ�)
  cv_tkn_number_05       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00018';  -- CSV�t�@�C���N���[�Y�G���[
  cv_tkn_number_06       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00152';  -- �C���^�[�t�F�[�X�t�@�C����
  cv_tkn_number_07       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00224';  -- CSV�t�@�C���o��0���G���[���b�Z�[�W
  cv_tkn_number_08       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00924';  -- �p�����[�^�Ώ۔N��(From)
  cv_tkn_number_09       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00925';  -- �p�����[�^�Ώ۔N��(To)
  -- �g�[�N���R�[�h
  cv_tkn_errmsg           CONSTANT VARCHAR2(20) := 'ERR_MSG';
  cv_tkn_prof_nm          CONSTANT VARCHAR2(20) := 'PROF_NAME';
  cv_tkn_csv_loc          CONSTANT VARCHAR2(20) := 'CSV_LOCATION';
  cv_tkn_csv_fnm          CONSTANT VARCHAR2(20) := 'CSV_FILE_NAME';
  cv_tkn_acc_num          CONSTANT VARCHAR2(20) := 'ACCOUNT_NUMBER';
  cv_tkn_target_from      CONSTANT VARCHAR2(20) := 'TARGET_FROM';
  cv_tkn_target_to        CONSTANT VARCHAR2(20) := 'TARGET_TO';
  -- �f�B���N�g���I�u�W�F�N�g
  cv_csv_dir              CONSTANT VARCHAR(200) :='XXCSO_INFO_OUT_CSV_DIR'; --���n�A�g�pCSV�t�@�C���o�͐�
--
  cb_true                 CONSTANT BOOLEAN := TRUE;
  -- DEBUG_LOG�p���b�Z�[�W
  cv_debug_msg1           CONSTANT VARCHAR2(200) := '<< �V�X�e�����t�擾���� >>';
  cv_debug_msg2           CONSTANT VARCHAR2(200) := 'od_sysdate = ';
  cv_debug_msg3           CONSTANT VARCHAR2(200) := '<< �v���t�@�C���l�擾���� >>';
  cv_debug_msg4           CONSTANT VARCHAR2(200) := 'lv_company_cd = ';
  cv_debug_msg5           CONSTANT VARCHAR2(200) := 'lv_csv_nm     = ';
  cv_debug_msg6           CONSTANT VARCHAR2(200) := '<< CSV�t�@�C�����I�[�v�����܂��� >>' ;
  cv_debug_msg7           CONSTANT VARCHAR2(200) := '<< CSV�t�@�C�����N���[�Y���܂��� >>' ;
  cv_debug_msg8           CONSTANT VARCHAR2(200) := '<< ���[���o�b�N���܂��� >>' ;
  cv_debug_msg_fnm        CONSTANT VARCHAR2(200) := 'filename = ';
  cv_debug_msg_fcls       CONSTANT VARCHAR2(200) := '<< ��O��������CSV�t�@�C�����N���[�Y���܂��� >>';
  cv_debug_msg_copn       CONSTANT VARCHAR2(200) := '<< �J�[�\�����I�[�v�����܂��� >>';
  cv_debug_msg_ccls1      CONSTANT VARCHAR2(200) := '<< �J�[�\�����N���[�Y���܂��� >>';
  cv_debug_msg_ccls2      CONSTANT VARCHAR2(200) := '<< ��O�������ŃJ�[�\�����N���[�Y���܂��� >>';
  cv_debug_msg_err1       CONSTANT VARCHAR2(200) := 'file_err_expt';
  cv_debug_msg_err2       CONSTANT VARCHAR2(200) := 'global_api_expt';
  cv_debug_msg_err3       CONSTANT VARCHAR2(200) := 'global_api_others_expt';
  cv_debug_msg_err4       CONSTANT VARCHAR2(200) := 'others��O';
  cv_debug_msg_err5       CONSTANT VARCHAR2(200) := 'no_data_expt';
  cv_debug_msg_err6       CONSTANT VARCHAR2(200) := 'global_process_expt';
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- �t�@�C���E�n���h���̐錾
  gf_file_hand    UTL_FILE.FILE_TYPE;
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- CSV�o�̓f�[�^�i�[�p���R�[�h�^��`
  TYPE g_get_data_rtype IS RECORD(
    company_cd       VARCHAR2(3),                               -- ��ЃR�[�h
    base_code        xxcso_cust_pay_mng.base_code%TYPE,         -- ���_�R�[�h
    account_number   xxcso_cust_pay_mng.account_number%TYPE,    -- �ڋq�R�[�h
    plan_actual_kbn  xxcso_cust_pay_mng.plan_actual_kbn%TYPE,   -- �\���敪
    data_kbn         xxcso_cust_pay_mng.data_kbn%TYPE,          -- �f�[�^�敪
    payment_date     xxcso_cust_pay_mng.payment_date%TYPE,      -- �N��
    acct_code        xxcso_cust_pay_mng.acct_code%TYPE,         -- ����Ȗ�
    acct_name        xxcso_cust_pay_mng.acct_name%TYPE,         -- ����Ȗږ�
    sub_acct_code    xxcso_cust_pay_mng.sub_acct_code%TYPE,     -- �⏕�Ȗ�
    sub_acct_name    xxcso_cust_pay_mng.sub_acct_name%TYPE,     -- �⏕�Ȗږ�
    payment_amt      xxcso_cust_pay_mng.payment_amt%TYPE,       -- ���z
    cprtn_date       DATE                                       -- �A�g����
  );
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : �������� (A-1)
   ***********************************************************************************/
  PROCEDURE init(
     iv_target_yyyymm_from IN  VARCHAR2         -- �p�����[�^�Ώ۔N��(From)
    ,iv_target_yyyymm_to   IN  VARCHAR2         -- �p�����[�^�Ώ۔N��(To)
    ,od_sysdate            OUT DATE             -- �V�X�e�����t
    ,ov_errbuf             OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode            OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg             OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'init';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';   -- �A�v���P�[�V�����Z�k��
    -- *** ���[�J���ϐ� ***
    -- ���b�Z�[�W�o�͗p
    lv_msg_from     VARCHAR2(5000);
    lv_msg_to       VARCHAR2(5000);
    lv_noprm_msg    VARCHAR2(4000);  -- �R���J�����g���̓p�����[�^�Ȃ����b�Z�[�W�i�[�p
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===========================
    -- �N���p�����[�^���b�Z�[�W�o��
    -- ===========================
    -- ��s�̑}��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    lv_msg_from := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name           --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_08      --���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_target_from    --�g�[�N���R�[�h1
                    ,iv_token_value1 => iv_target_yyyymm_from --�g�[�N���l1
                   );
    lv_msg_to := xxccp_common_pkg.get_msg(
                   iv_application  => cv_app_name           --�A�v���P�[�V�����Z�k��
                  ,iv_name         => cv_tkn_number_09      --���b�Z�[�W�R�[�h
                  ,iv_token_name1  => cv_tkn_target_to      --�g�[�N���R�[�h1
                  ,iv_token_value1 => iv_target_yyyymm_to   --�g�[�N���l1
                 );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg_from
    );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg_to
    );
    -- ===========================
    -- �V�X�e�����t�擾���� 
    -- ===========================
    od_sysdate := SYSDATE;
    -- *** DEBUG_LOG ***
    -- �擾�����V�X�e�����t�����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg1  || CHR(10) ||
                 cv_debug_msg2  || TO_CHAR(od_sysdate,'yyyy/mm/dd hh24:mi:ss') || CHR(10) ||
                 ''
    );
--
  EXCEPTION
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
   * Procedure Name   : get_profile_info
   * Description      : �v���t�@�C���l�擾 (A-2)
   ***********************************************************************************/
  PROCEDURE get_profile_info(
     ov_company_cd     OUT NOCOPY VARCHAR2  -- ��ЃR�[�h�i�Œ�l001�j
    ,ov_csv_nm         OUT NOCOPY VARCHAR2  -- CSV�t�@�C����
    ,ov_errbuf         OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode        OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg         OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_profile_info';  -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- �v���t�@�C����
    -- XXCSO:���n�A�g�p��ЃR�[�h
    cv_prfnm_cmp_cd           CONSTANT VARCHAR2(40)   := 'XXCSO1_INFO_OUT_COMPANY_CD';
    -- XXCSO:���n�A�g�pCSV�t�@�C����(���̋@�ڋq�ʎx���Ǘ�)
    cv_prfnm_csv_cust_pay_mng CONSTANT VARCHAR2(40)   := 'XXCSO1_INFO_OUT_CSV_CUST_PAY_MNG';
--
    -- *** ���[�J���ϐ� ***
    -- �v���t�@�C���l�擾�߂�l�i�[�p
    lv_company_cd               VARCHAR2(2000);      -- ��ЃR�[�h�i�Œ�l001�j
    lv_csv_nm                   VARCHAR2(2000);      -- CSV�t�@�C����
    -- �v���t�@�C���l�擾���s�� �g�[�N���l�i�[�p
    lv_tkn_value                VARCHAR2(1000);
    -- �擾�f�[�^���b�Z�[�W�o�͗p
    lv_msg                      VARCHAR2(4000);
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- =======================
    -- �ϐ����������� 
    -- =======================
    lv_tkn_value := NULL;
--
    -- =======================
    -- �v���t�@�C���l�擾���� 
    -- =======================
    FND_PROFILE.GET(
                    name => cv_prfnm_cmp_cd
                   ,val  => lv_company_cd
                   ); -- ��ЃR�[�h�i�Œ�l001�j
    FND_PROFILE.GET(
                    name => cv_prfnm_csv_cust_pay_mng
                   ,val  => lv_csv_nm
                   ); -- CSV�t�@�C����
    -- *** DEBUG_LOG ***
    -- �擾�����v���t�@�C���l�����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg3  || CHR(10) ||
                 cv_debug_msg4  || lv_company_cd || CHR(10) ||
                 cv_debug_msg5 || lv_csv_nm     || CHR(10) ||
                 ''
    );
--
    -- �擾����CSV�t�@�C���������b�Z�[�W�o�͂���
    lv_msg := xxccp_common_pkg.get_msg(
                 iv_application  => cv_app_name           --�A�v���P�[�V�����Z�k��
                ,iv_name         => cv_tkn_number_06      --���b�Z�[�W�R�[�h
                ,iv_token_name1  => cv_tkn_csv_fnm        --�g�[�N���R�[�h1
                ,iv_token_value1 => lv_csv_nm             --�g�[�N���l1
              );
    --���b�Z�[�W�o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg || CHR(10) ||
                 ''                   -- ��s�̑}��
    );
--
    -- �v���t�@�C���l�擾�Ɏ��s�����ꍇ
    -- ��ЃR�[�h�擾���s��
    IF (lv_company_cd IS NULL) THEN
      lv_tkn_value := cv_prfnm_cmp_cd;
    -- CSV�t�@�C�����擾���s��
    ELSIF (lv_csv_nm IS NULL) THEN
      lv_tkn_value := cv_prfnm_csv_cust_pay_mng;
    END IF;
    -- �G���[���b�Z�[�W�擾
    IF (lv_tkn_value) IS NOT NULL THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_01             --���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_prof_nm               --�g�[�N���R�[�h1
                    ,iv_token_value1 => lv_tkn_value                 --�g�[�N���l1
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    END IF;
--
    -- �擾�����v���t�@�C���l��OUT�p�����[�^�ɐݒ�
    ov_company_cd     :=  lv_company_cd;       -- ��ЃR�[�h�i�Œ�l001�j
    ov_csv_nm         :=  lv_csv_nm;           -- CSV�t�@�C����
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
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
  END get_profile_info;
--
  /**********************************************************************************
   * Procedure Name   : open_csv_file
   * Description      : ���̋@�ڋq�ʎx���Ǘ��f�[�^CSV�t�@�C���I�[�v�� (A-3)
   ***********************************************************************************/
  PROCEDURE open_csv_file(
     iv_csv_nm         IN  VARCHAR2         -- CSV�t�@�C����
    ,ov_errbuf         OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode        OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg         OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'open_csv_file';  -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_w            CONSTANT VARCHAR2(1) := 'w';
--
    -- *** ���[�J���ϐ� ***
    -- �t�@�C�����݃`�F�b�N�߂�l�p
    lb_retcd        BOOLEAN;
    ln_file_size    NUMBER;
    ln_block_size   NUMBER;
    -- �t�@�C���I�[�v���m�F�߂�l�i�[
    lb_fopn_retcd   BOOLEAN;
    -- *** ���[�J����O ***
    file_err_expt   EXCEPTION;  -- �t�@�C��������O
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ========================
    -- CSV�t�@�C�����݃`�F�b�N 
    -- ========================
    UTL_FILE.FGETATTR(
       location    => cv_csv_dir
      ,filename    => iv_csv_nm
      ,fexists     => lb_retcd
      ,file_length => ln_file_size
      ,block_size  => ln_block_size
    );
--
    -- ���łɃt�@�C�������݂����ꍇ
    IF (lb_retcd = cb_true) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_02             --���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_csv_loc               --�g�[�N���R�[�h1
                    ,iv_token_value1 => cv_csv_dir                   --�g�[�N���l1
                    ,iv_token_name2  => cv_tkn_csv_fnm               --�g�[�N���R�[�h1
                    ,iv_token_value2 => iv_csv_nm                    --�g�[�N���l1
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE file_err_expt;
    END IF;
--
    -- ========================
    -- CSV�t�@�C���I�[�v�� 
    -- ========================
    BEGIN
      -- �t�@�C���I�[�v��
      gf_file_hand := UTL_FILE.FOPEN(
                         location   => cv_csv_dir
                        ,filename   => iv_csv_nm
                        ,open_mode  => cv_w
                      );
    -- *** DEBUG_LOG ***
    -- �t�@�C���I�[�v���������Ƃ����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg6   || CHR(10)   ||
                 cv_debug_msg_fnm || iv_csv_nm || CHR(10) ||
                 ''
    );
    EXCEPTION
      WHEN UTL_FILE.INVALID_PATH       OR       -- �t�@�C���p�X�s���G���[
           UTL_FILE.INVALID_MODE       OR       -- open_mode�p�����[�^�s���G���[
           UTL_FILE.INVALID_OPERATION  OR       -- �I�[�v���s�\�G���[
           UTL_FILE.INVALID_MAXLINESIZE  THEN   -- MAX_LINESIZE�l�����G���[
        -- �G���[���b�Z�[�W�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name          --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_03     --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_csv_loc       --�g�[�N���R�[�h1
                      ,iv_token_value1 => cv_csv_dir           --�g�[�N���l1
                      ,iv_token_name2  => cv_tkn_csv_fnm       --�g�[�N���R�[�h1
                      ,iv_token_value2 => iv_csv_nm            --�g�[�N���l1
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE file_err_expt;
    END;
  EXCEPTION
    -- *** �t�@�C��������O�n���h�� ***
    WHEN file_err_expt THEN
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END open_csv_file;
--
  /**********************************************************************************
   * Procedure Name   : create_csv_rec
   * Description      : ���̋@�ڋq�ʎx���Ǘ��f�[�^CSV�o�� (A-5)
   ***********************************************************************************/
  PROCEDURE create_csv_rec(
     ir_xcpm_data        IN  g_get_data_rtype    -- ���̋@�ڋq�ʎx���Ǘ����o�f�[�^
    ,ov_errbuf           OUT NOCOPY VARCHAR2     -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2     -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'create_csv_rec';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_sep_com       CONSTANT VARCHAR2(1)  := ',';
    cv_sep_wquot     CONSTANT VARCHAR2(1)  := '"';
--
    -- *** ���[�J���ϐ� ***
    lv_data          VARCHAR2(4000);  -- �ҏW�f�[�^�i�[
--
    -- *** ���[�J���E���R�[�h ***
    l_xcpm_data_rec g_get_data_rtype;  -- IN�p�����[�^.���̋@�ڋq�ʎx���Ǘ��f�[�^�i�[
    lv_company_cd    VARCHAR2(2000);   -- IN�p�����[�^.��ЃR�[�h�i�[
    ld_sysdate       DATE;             -- IN�p�����[�^.�V�X�e�����t�i�[
    -- *** ���[�J����O ***
    file_put_line_expt   EXCEPTION;    -- �f�[�^�o�͏�����O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- IN�p�����[�^�����R�[�h�ϐ��Ɋi�[
    l_xcpm_data_rec := ir_xcpm_data; -- ���̋@�ڋq�ʎx���Ǘ����o�f�[�^
--
    -- ======================
    -- CSV�o�͏��� 
    -- ======================
    BEGIN
--
      -- �f�[�^�쐬
      lv_data :=         cv_sep_wquot || l_xcpm_data_rec.company_cd                              || cv_sep_wquot    -- ��ЃR�[�h
        || cv_sep_com || cv_sep_wquot || l_xcpm_data_rec.base_code                               || cv_sep_wquot    -- ���_�R�[�h
        || cv_sep_com || cv_sep_wquot || l_xcpm_data_rec.account_number                          || cv_sep_wquot    -- �ڋq�R�[�h
        || cv_sep_com || cv_sep_wquot || l_xcpm_data_rec.plan_actual_kbn                         || cv_sep_wquot    -- �\���敪
        || cv_sep_com || cv_sep_wquot || l_xcpm_data_rec.data_kbn                                || cv_sep_wquot    -- �f�[�^�敪
        || cv_sep_com || cv_sep_wquot || l_xcpm_data_rec.payment_date                            || cv_sep_wquot    -- �N��
        || cv_sep_com || cv_sep_wquot || l_xcpm_data_rec.acct_code                               || cv_sep_wquot    -- ����Ȗ�
        || cv_sep_com || cv_sep_wquot || l_xcpm_data_rec.acct_name                               || cv_sep_wquot    -- ����Ȗږ�
        || cv_sep_com || cv_sep_wquot || l_xcpm_data_rec.sub_acct_code                           || cv_sep_wquot    -- �⏕�Ȗ�
        || cv_sep_com || cv_sep_wquot || l_xcpm_data_rec.sub_acct_name                           || cv_sep_wquot    -- �⏕�Ȗږ�
        || cv_sep_com || TO_CHAR(l_xcpm_data_rec.payment_amt)                                                       -- ���z
        || cv_sep_com || cv_sep_wquot || TO_CHAR(l_xcpm_data_rec.cprtn_date, 'yyyymmddhh24miss') || cv_sep_wquot;   -- �A�g����
--
      -- �f�[�^�o��
      UTL_FILE.PUT_LINE(
        file   => gf_file_hand
       ,buffer => lv_data
      );
--
    EXCEPTION
      WHEN UTL_FILE.INVALID_FILEHANDLE OR     -- �t�@�C���E�n���h�������G���[
           UTL_FILE.INVALID_OPERATION  OR     -- �I�[�v���s�\�G���[
           UTL_FILE.WRITE_ERROR  THEN         -- �����ݑ��쒆�I�y���[�e�B���O�G���[
        -- �G���[���b�Z�[�W�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                    --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_04               --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_acc_num                 --�g�[�N���R�[�h1
                      ,iv_token_value1 => l_xcpm_data_rec.account_number --�g�[�N���l1
                      ,iv_token_name2  => cv_tkn_errmsg                  --�g�[�N���R�[�h2
                      ,iv_token_value2 => SQLERRM                        --�g�[�N���l2
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE file_put_line_expt;
    END;
--
  EXCEPTION
    -- *** �t�@�C��������O�n���h�� ***
    WHEN file_put_line_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END create_csv_rec;
--
  /**********************************************************************************
   * Procedure Name   : close_csv_file
   * Description      : CSV�t�@�C���N���[�Y���� (A-6)
   ***********************************************************************************/
  PROCEDURE close_csv_file(
     iv_csv_nm         IN  VARCHAR2         -- CSV�t�@�C����
    ,ov_errbuf         OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode        OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg         OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'close_csv_file';  -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    -- �t�@�C���I�[�v���m�F�߂�l�i�[
    lb_fopn_retcd   BOOLEAN;
    -- *** ���[�J����O ***
    file_err_expt   EXCEPTION;  -- �t�@�C��������O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================
    -- CSV�t�@�C���N���[�Y 
    -- ====================
    BEGIN
      UTL_FILE.FCLOSE(
        file => gf_file_hand
      );
    -- *** DEBUG_LOG ***
    -- �t�@�C���N���[�Y�������Ƃ����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg7   || CHR(10)   ||
                 cv_debug_msg_fnm || iv_csv_nm || CHR(10) ||
                 ''
    );
    EXCEPTION
      WHEN UTL_FILE.WRITE_ERROR          OR     -- �I�y���[�e�B���O�V�X�e���G���[
           UTL_FILE.INVALID_FILEHANDLE   THEN   -- �t�@�C���E�n���h�������G���[
        -- �G���[���b�Z�[�W�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_05             --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_csv_loc               --�g�[�N���R�[�h1
                      ,iv_token_value1 => cv_csv_dir                   --�g�[�N���l1
                      ,iv_token_name2  => cv_tkn_csv_fnm               --�g�[�N���R�[�h1
                      ,iv_token_value2 => iv_csv_nm                    --�g�[�N���l1
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE file_err_expt;
    END;
  EXCEPTION
    -- *** �t�@�C��������O�n���h�� ***
    WHEN file_err_expt THEN
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END close_csv_file;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   ***********************************************************************************/
  PROCEDURE submain(
     iv_target_yyyymm_from IN  VARCHAR2          -- �p�����[�^�Ώ۔N��(From)
    ,iv_target_yyyymm_to   IN  VARCHAR2          -- �p�����[�^�Ώ۔N��(To)
    ,ov_errbuf             OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode            OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg             OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'submain';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    -- OUT�p�����[�^�i�[�p
    lv_target_yyyymm_from VARCHAR2(2000); -- �p�����[�^�Ώ۔N��(From)
    lv_target_yyyymm_to   VARCHAR2(2000); -- �p�����[�^�Ώ۔N��(To)
    ld_sysdate            DATE          ; -- �V�X�e�����t
    lv_company_cd         VARCHAR2(2000); -- ��ЃR�[�h�i�Œ�l001�j
    lv_csv_nm             VARCHAR2(2000); -- CSV�t�@�C����
    -- �t�@�C���I�[�v���m�F�߂�l�i�[
    lb_fopn_retcd         BOOLEAN       ;
    -- ���b�Z�[�W�o�͗p
    lv_msg                VARCHAR2(2000);
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR xcpm_data_cur
    IS
    SELECT xca.sale_base_code                      AS  base_code                  --���_�R�[�h
          ,xcpm.account_number                     AS  account_number             --�ڋq�R�[�h
          ,xcpm.plan_actual_kbn                    AS  plan_actual_kbn            --�\���敪
          ,xcpm.data_kbn                           AS  data_kbn                   --�f�[�^�敪
          ,xcpm.payment_date                       AS  payment_date               --�N��
          ,xcpm.acct_code                          AS  acct_code                  --����Ȗ�
          ,xcpm.acct_name                          AS  acct_name                  --����Ȗږ�
          ,xcpm.sub_acct_code                      AS  sub_acct_code              --�⏕�Ȗ�
          ,xcpm.sub_acct_name                      AS  sub_acct_name              --�⏕�Ȗږ�
          ,xcpm.payment_amt                        AS  payment_amt                --���z
    FROM   xxcso_cust_pay_mng      xcpm    --���̋@�ڋq�x���Ǘ����e�[�u��
          ,xxcmm_cust_accounts     xca     --�ڋq�ǉ����
    WHERE xcpm.account_number = xca.customer_code(+)
    AND   NVL(TO_DATE(lv_target_yyyymm_from,'YYYYMM'),TO_DATE('000101','YYYYMM')) <=  TO_DATE(xcpm.payment_date,'YYYYMM')
    AND   NVL(TO_DATE(lv_target_yyyymm_to,'YYYYMM')  ,TO_DATE('999912','YYYYMM')) >=  TO_DATE(xcpm.payment_date,'YYYYMM')
    AND   xcpm.send_flag = '0' -- 0�F���M�Ώ�
    ;
--
    -- *** ���[�J���E���R�[�h ***
    l_xcpm_data_rec   xcpm_data_cur%ROWTYPE;
    l_get_data_rec     g_get_data_rtype;
    -- *** ���[�J����O ***
    no_data_expt       EXCEPTION;
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
    --IN�p�����[�^�i�[
    lv_target_yyyymm_from := iv_target_yyyymm_from; -- �p�����[�^�Ώ۔N��(From)
    lv_target_yyyymm_to   := iv_target_yyyymm_to;   -- �p�����[�^�Ώ۔N��(To)
--
    -- ========================================
    -- A-1.�������� 
    -- ========================================
    init(
       iv_target_yyyymm_from  => lv_target_yyyymm_from        -- �p�����[�^�Ώ۔N��(From)
      ,iv_target_yyyymm_to    => lv_target_yyyymm_to          -- �p�����[�^�Ώ۔N��(To)
      ,od_sysdate             => ld_sysdate                   -- �V�X�e�����t
      ,ov_errbuf              => lv_errbuf                    -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode             => lv_retcode                   -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg              => lv_errmsg                    -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
--
    -- ========================================
    -- A-2.�v���t�@�C���l�擾 
    -- ========================================
    get_profile_info(
       ov_company_cd  => lv_company_cd  -- ��ЃR�[�h�i�Œ�l001�j
      ,ov_csv_nm      => lv_csv_nm      -- CSV�t�@�C����
      ,ov_errbuf      => lv_errbuf      -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode     => lv_retcode     -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg      => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
--
    -- =================================================
    -- A-3.���̋@�ڋq�ʎx���Ǘ��f�[�^CSV�t�@�C���I�[�v�� 
    -- =================================================
    open_csv_file(
       iv_csv_nm    => lv_csv_nm    -- CSV�t�@�C����
      ,ov_errbuf    => lv_errbuf    -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode   => lv_retcode   -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg    => lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
--
    -- ========================================
    -- A-4.���̋@�ڋq�ʎx���Ǘ����o 
    -- ========================================
--
    -- �J�[�\���I�[�v��
    OPEN xcpm_data_cur;
    -- *** DEBUG_LOG ***
    -- �J�[�\���I�[�v���������Ƃ����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg_copn || CHR(10) ||
                 ''
    );
--
    <<get_data_loop>>
    LOOP
      FETCH xcpm_data_cur INTO l_xcpm_data_rec;
--
      EXIT WHEN xcpm_data_cur%NOTFOUND;
      -- ���R�[�h�ϐ�������
      l_get_data_rec := NULL;
      -- �擾�f�[�^���i�[
      l_get_data_rec.company_cd                   := lv_company_cd;                     -- ��ЃR�[�h
      l_get_data_rec.base_code                    := l_xcpm_data_rec.base_code;         -- ���_�R�[�h
      l_get_data_rec.account_number               := l_xcpm_data_rec.account_number;    -- �ڋq�R�[�h
      l_get_data_rec.plan_actual_kbn              := l_xcpm_data_rec.plan_actual_kbn;   -- �\���敪
      l_get_data_rec.data_kbn                     := l_xcpm_data_rec.data_kbn;          -- �f�[�^�敪
      l_get_data_rec.payment_date                 := l_xcpm_data_rec.payment_date;      -- �N��
      l_get_data_rec.acct_code                    := l_xcpm_data_rec.acct_code;         -- ����Ȗ�
      l_get_data_rec.acct_name                    := l_xcpm_data_rec.acct_name;         -- ����Ȗږ�
      l_get_data_rec.sub_acct_code                := l_xcpm_data_rec.sub_acct_code;     -- �⏕�Ȗ�
      l_get_data_rec.sub_acct_name                := l_xcpm_data_rec.sub_acct_name;     -- �⏕�Ȗږ�
      l_get_data_rec.payment_amt                  := l_xcpm_data_rec.payment_amt;       -- ���z
      l_get_data_rec.cprtn_date                   := ld_sysdate;                        -- �A�g����
--
      -- ========================================
      -- A-5.���̋@�ڋq�ʎx���Ǘ��f�[�^CSV�o�� 
      -- ========================================
      create_csv_rec(
        ir_xcpm_data   =>  l_get_data_rec        -- ���̋@�ڋq�ʎx���Ǘ��f�[�^
       ,ov_errbuf      =>  lv_errbuf             -- �G���[�E���b�Z�[�W
       ,ov_retcode     =>  lv_retcode            -- ���^�[���E�R�[�h
       ,ov_errmsg      =>  lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      --
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
      -- ���팏���J�E���g�A�b�v
      gn_normal_cnt := gn_normal_cnt + 1;
--
    END LOOP get_data_loop;
--
    -- �����Ώی����i�[
    gn_target_cnt := xcpm_data_cur%ROWCOUNT;
    -- �J�[�\���N���[�Y
    CLOSE xcpm_data_cur;
    -- *** DEBUG_LOG ***
    -- �J�[�\���N���[�Y�������Ƃ����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg_ccls1 || CHR(10) ||
                 ''
    );
--
    -- �����Ώی�����0���̏ꍇ
    IF (gn_target_cnt = 0) THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_07             --���b�Z�[�W�R�[�h
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE no_data_expt;
    END IF;
--
    -- ========================================
    -- CSV�t�@�C���N���[�Y (A-6) 
    -- ========================================
    close_csv_file(
       iv_csv_nm    => lv_csv_nm    -- CSV�t�@�C����
      ,ov_errbuf    => lv_errbuf    -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode   => lv_retcode   -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg    => lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    -- *** �����Ώۃf�[�^0����O�n���h�� ***
    WHEN no_data_expt THEN
      -- �G���[�����J�E���g
      gn_error_cnt := gn_error_cnt + 1;
--
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (xcpm_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE xcpm_data_cur;
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err5 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- �G���[�����J�E���g
      gn_error_cnt := gn_error_cnt + 1;
--
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (xcpm_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE xcpm_data_cur;
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err6 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �G���[�����J�E���g
      gn_error_cnt := gn_error_cnt + 1;
--
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (xcpm_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE xcpm_data_cur;
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �G���[�����J�E���g
      gn_error_cnt := gn_error_cnt + 1;
--
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (xcpm_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE xcpm_data_cur;
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err4 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END submain;
--
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
     errbuf           OUT NOCOPY VARCHAR2    --   �G���[�E���b�Z�[�W  --# �Œ� #
    ,retcode          OUT NOCOPY VARCHAR2    --   ���^�[���E�R�[�h    --# �Œ� #
    ,iv_target_yyyymm_from    IN  VARCHAR2   --   �Ώ۔N��(From)
    ,iv_target_yyyymm_to      IN  VARCHAR2   --   �Ώ۔N��(To)
     )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- �v���O������
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
    lv_errbuf          VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
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
       iv_target_yyyymm_from => iv_target_yyyymm_from
      ,iv_target_yyyymm_to   => iv_target_yyyymm_to
      ,ov_errbuf             => lv_errbuf               -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode            => lv_retcode              -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg             => lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
       --�G���[�o��
       fnd_file.put_line(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg                  --���[�U�[�E�G���[���b�Z�[�W
       );
       fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => cv_pkg_name||cv_msg_cont||
                    cv_prg_name||cv_msg_part||
                    lv_errbuf                  --�G���[���b�Z�[�W
       );
    END IF;
--
    -- =======================
    -- A-7.�I������ 
    -- =======================
    --��s�̏o��
    fnd_file.put_line(
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
    fnd_file.put_line(
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
    fnd_file.put_line(
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
    fnd_file.put_line(
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
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
      -- *** DEBUG_LOG ***
      -- ���[���o�b�N�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg8 || CHR(10) ||
                   ''
      );
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      retcode := cv_status_error;
      ROLLBACK;
      -- *** DEBUG_LOG ***
      -- ���[���o�b�N�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg8 || CHR(10) ||
                   ''
      );
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
      -- *** DEBUG_LOG ***
      -- ���[���o�b�N�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg8 || CHR(10) ||
                   ''
      );
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCSO016A09C;
/
