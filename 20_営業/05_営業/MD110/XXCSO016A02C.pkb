CREATE OR REPLACE PACKAGE BODY XXCSO016A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO016A02C(body)
 * Description      : �c�ƈ��}�X�^�f�[�^�����n�V�X�e���ɑ��M���邽�߂�
 *                    CSV�t�@�C�����쐬���܂��B
 * MD.050           : MD050_CSO_016_A02_���n-EBS�C���^�[�t�F�[�X�F
 *                    (OUT)�c�ƈ��}�X�^
 * Version          : 1.3
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  get_profile_info       �v���t�@�C���l�擾(A-2)
 *  open_csv_file          �c�ƈ��}�X�^���CSV�t�@�C���I�[�v��(A-3)
 *  get_prsn_cnnct_data    �c�ƈ��}�X�^�֘A��񒊏o����(A-5)
 *  create_csv_rec         �c�ƈ��}�X�^CSV�o��(A-6)
 *  close_csv_file         �c�ƈ��}�X�^���CSV�t�@�C���N���[�Y����(A-7)
 *  submain                ���C�������v���V�[�W��
 *                           �c�ƈ��}�X�^��񒊏o����(A-4)
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                           �I������ (A-8)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-11-26    1.0   Kazuyo.Hosoi     �V�K�쐬
 *  2009-02-26    1.1   K.Sai            ���r���[���ʔ��f
 *  2009-03-26    1.2   M.Maruyama      �yST��QT01_208�z�f�[�^�擾�������\�[�X�֘A�}�X�^�r���[�ɕύX
 *  2009-04-16    1.3   K.Satomura      �yST��QT01_0172�z�c�ƈ����́A�c�ƈ����́i�J�i�j��S�p�u��
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
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCSO016A02C';  -- �p�b�P�[�W��
  cv_app_name            CONSTANT VARCHAR2(5)   := 'XXCSO';         -- �A�v���P�[�V�����Z�k��
  -- ���b�Z�[�W�R�[�h
  cv_tkn_number_01       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00011';  -- �Ɩ��������t�擾�G���[
  cv_tkn_number_02       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00014';  -- �v���t�@�C���擾�G���[
  cv_tkn_number_03       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00015';  -- CSV�t�@�C���I�[�v���G���[
  cv_tkn_number_04       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00016';  -- �f�[�^���o�G���[
  cv_tkn_number_05       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00018';  -- CSV�t�@�C���N���[�Y�G���[
  cv_tkn_number_06       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00019';  -- CSV�t�@�C���o�̓G���[���b�Z�[�W(�c�ƈ��}�X�^)
  cv_tkn_number_07       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00123';  -- CSV�t�@�C���c���G���[���b�Z�[�W
  cv_tkn_number_08       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00152';  -- �C���^�[�t�F�[�X�t�@�C����
  cv_tkn_number_09       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00224';  -- CSV�t�@�C���o��0���G���[���b�Z�[�W
  cv_tkn_number_10       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90008';  -- �R���J�����g���̓p�����[�^�Ȃ�
  -- �g�[�N���R�[�h
  cv_tkn_errmsg          CONSTANT VARCHAR2(20) := 'ERR_MSG';
  cv_tkn_errmessage      CONSTANT VARCHAR2(20) := 'ERR_MESSAGE'; 
  cv_tkn_prof_nm         CONSTANT VARCHAR2(20) := 'PROF_NAME';
  cv_tkn_csv_loc         CONSTANT VARCHAR2(20) := 'CSV_LOCATION';
  cv_tkn_csv_fnm         CONSTANT VARCHAR2(20) := 'CSV_FILE_NAME';
  cv_tkn_prcss_nm        CONSTANT VARCHAR2(20) := 'PROCESSING_NAME';
  cv_tkn_slspsn_cd       CONSTANT VARCHAR2(20) := 'SALESPARSON_CD';
  cv_sls_pttn            CONSTANT VARCHAR2(20) := 'SALES_PATTERN';
  cv_grp_cd              CONSTANT VARCHAR2(20) := 'GROUP_CD';
  cv_base_cd             CONSTANT VARCHAR2(20) := 'BASE_CODE';
--
  cb_true                 CONSTANT BOOLEAN := TRUE;
  cn_name_lengthb         CONSTANT NUMBER := 20;  -- ���A����؂�o�C�g��
  -- DEBUG_LOG�p���b�Z�[�W
  cv_debug_msg1          CONSTANT VARCHAR2(200) := '<< �V�X�e�����t�擾���� >>';
  cv_debug_msg2          CONSTANT VARCHAR2(200) := 'od_sysdate = ';
  cv_debug_msg3          CONSTANT VARCHAR2(200) := '<< �Ɩ��������t�擾���� >>';
  cv_debug_msg4          CONSTANT VARCHAR2(200) := 'ld_process_date = ';
  cv_debug_msg5          CONSTANT VARCHAR2(200) := '<< �v���t�@�C���l�擾���� >>';
  cv_debug_msg6          CONSTANT VARCHAR2(200) := 'lv_company_cd = ';
  cv_debug_msg7          CONSTANT VARCHAR2(200) := 'lv_csv_dir    = ';
  cv_debug_msg8          CONSTANT VARCHAR2(200) := 'lv_csv_nm     = ';
  cv_debug_msg9          CONSTANT VARCHAR2(200) := '<< CSV�t�@�C�����I�[�v�����܂��� >>' ;
  cv_debug_msg10         CONSTANT VARCHAR2(200) := '<< CSV�t�@�C�����N���[�Y���܂��� >>' ;
  cv_debug_msg11         CONSTANT VARCHAR2(200) := '<< ���[���o�b�N���܂��� >>' ;
  cv_debug_msg_fnm       CONSTANT VARCHAR2(200) := 'filename = ';
  cv_debug_msg_fcls      CONSTANT VARCHAR2(200) := '<< ��O��������CSV�t�@�C�����N���[�Y���܂��� >>';
  cv_debug_msg_copn      CONSTANT VARCHAR2(200) := '<< �J�[�\�����I�[�v�����܂��� >>';
  cv_debug_msg_ccls1     CONSTANT VARCHAR2(200) := '<< �J�[�\�����N���[�Y���܂��� >>';
  cv_debug_msg_ccls2     CONSTANT VARCHAR2(200) := '<< ��O�������ŃJ�[�\�����N���[�Y���܂��� >>';
  cv_debug_msg_err1      CONSTANT VARCHAR2(200) := 'file_err_expt';
  cv_debug_msg_err2      CONSTANT VARCHAR2(200) := 'global_api_expt';
  cv_debug_msg_err3      CONSTANT VARCHAR2(200) := 'global_api_others_expt';
  cv_debug_msg_err4      CONSTANT VARCHAR2(200) := 'others��O';
  cv_debug_msg_err5      CONSTANT VARCHAR2(200) := 'no_data_expt';
  cv_debug_msg_err6      CONSTANT VARCHAR2(200) := 'global_process_expt';
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
     company_cd         VARCHAR2(3)                                                        -- ��ЃR�[�h
    ,employee_number    per_people_f.employee_number%TYPE                                  -- �c�ƈ��R�[�h
    ,base_code          VARCHAR2(150)                                                      -- ���_�R�[�h
    /* 2009.04.16 K.Satomura T1_0172�Ή� START */
    --,person_name        VARCHAR2(42)                                                       -- �c�ƈ�����
    --,person_name_kana   VARCHAR2(42)                                                       -- �c�ƈ�����(�J�i)
    ,person_name        VARCHAR2(40)                                                       -- �c�ƈ�����
    ,person_name_kana   VARCHAR2(40)                                                       -- �c�ƈ�����(�J�i)
    /* 2009.04.16 K.Satomura T1_0172�Ή� END */
    ,business_form      jtf_rs_resource_extns.attribute10%TYPE                             -- �c�ƌ`��
    ,group_leader_flag  jtf_rs_group_members.attribute1%TYPE                               -- �O���[�v���敪
    ,group_cd           jtf_rs_group_members.attribute2%TYPE                               -- �O���[�v�R�[�h
    ,cprtn_date         DATE                                                               -- �A�g����
    ,resource_id        jtf_rs_resource_extns.resource_id%TYPE                             -- ���\�[�XID
  );
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     od_sysdate          OUT DATE             -- �V�X�e�����t
    ,od_process_date     OUT DATE             -- �Ɩ��������t
    ,ov_errbuf           OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'init';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';   -- �A�v���P�[�V�����Z�k��
    -- *** ���[�J���ϐ� ***
    lv_noprm_msg     VARCHAR2(5000);  -- �R���J�����g���̓p�����[�^�Ȃ����b�Z�[�W�i�[�p
    ld_process_date  DATE;            -- �Ɩ��������t�i�[�p
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
    -- =================================
    -- ���̓p�����[�^�Ȃ����b�Z�[�W�o�� 
    -- =================================
    lv_noprm_msg   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name           --�A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_10             --���b�Z�[�W�R�[�h
                      );
    --���b�Z�[�W�o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''           || CHR(10) ||   -- ��s�̑}��
                 lv_noprm_msg || CHR(10) ||
                 ''                           -- ��s�̑}��
    );
    -- =====================
    -- �Ɩ��������t�擾���� 
    -- =====================
    od_process_date := xxccp_common_pkg2.get_process_date;
    -- *** DEBUG_LOG ***
    -- �擾�����Ɩ��������t�����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg3 || CHR(10) ||
                 cv_debug_msg4 || TO_CHAR(od_process_date,'yyyy/mm/dd hh24:mi:ss') || CHR(10) ||
                 ''
    );
--
    -- �Ɩ��������t�擾�Ɏ��s�����ꍇ
    IF (od_process_date IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_01             --���b�Z�[�W�R�[�h
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    END IF;
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
   * Procedure Name   : get_profile_info
   * Description      : �v���t�@�C���l�擾(A-2)
   ***********************************************************************************/
  PROCEDURE get_profile_info(
     ov_company_cd     OUT NOCOPY VARCHAR2  -- ��ЃR�[�h�i�Œ�l001�j
    ,ov_csv_dir        OUT NOCOPY VARCHAR2  -- CSV�t�@�C���o�͐�
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
    -- �v���t�@�C����
    -- XXCSO:���n�A�g�p��ЃR�[�h
    cv_prfnm_cmp_cd         CONSTANT VARCHAR2(30)   := 'XXCSO1_INFO_OUT_COMPANY_CD';
    -- XXCSO:���n�A�g�pCSV�t�@�C���o�͐�
    cv_prfnm_csv_dir        CONSTANT VARCHAR2(30)   := 'XXCSO1_INFO_OUT_CSV_DIR';
    -- XXCSO:���n�A�g�pCSV�t�@�C����(�c�ƈ��}�X�^)
    cv_prfnm_csv_sls_prsn   CONSTANT VARCHAR2(30)   := 'XXCSO1_INFO_OUT_CSV_SLS_PRSN';
--
    -- *** ���[�J���ϐ� ***
    -- �v���t�@�C���l�擾�߂�l�i�[�p
    lv_company_cd               VARCHAR2(2000);      -- ��ЃR�[�h�i�Œ�l001�j
    lv_csv_dir                  VARCHAR2(2000);      -- CSV�t�@�C���o�͐�
    lv_csv_nm                   VARCHAR2(2000);      -- CSV�t�@�C����
    -- �v���t�@�C���l�擾���s�� �g�[�N���l�i�[�p
    lv_tkn_value                VARCHAR2(1000);
    -- �擾�f�[�^���b�Z�[�W�o�͗p
    lv_msg                      VARCHAR2(5000);
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
                    name => cv_prfnm_csv_dir
                   ,val  => lv_csv_dir
                   ); -- CSV�t�@�C���o�͐�
    FND_PROFILE.GET(
                    name => cv_prfnm_csv_sls_prsn
                   ,val  => lv_csv_nm
                   ); -- CSV�t�@�C����
    -- *** DEBUG_LOG ***
    -- �擾�����v���t�@�C���l�����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg5  || CHR(10) ||
                 cv_debug_msg6  || lv_company_cd || CHR(10) ||
                 cv_debug_msg7  || lv_csv_dir    || CHR(10) ||
                 cv_debug_msg8  || lv_csv_nm     || CHR(10) ||
                 ''
    );
--
    -- �擾����CSV�t�@�C���������b�Z�[�W�o�͂���
    lv_msg := xxccp_common_pkg.get_msg(
                 iv_application  => cv_app_name           --�A�v���P�[�V�����Z�k��
                ,iv_name         => cv_tkn_number_08      --���b�Z�[�W�R�[�h
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
    -- CSV�t�@�C���o�͐�擾���s��
    ELSIF (lv_csv_dir IS NULL) THEN
      lv_tkn_value := cv_prfnm_csv_dir;
    -- CSV�t�@�C�����擾���s��
    ELSIF (lv_csv_nm IS NULL) THEN
      lv_tkn_value := cv_prfnm_csv_sls_prsn;
    END IF;
    -- �G���[���b�Z�[�W�擾
    IF (lv_tkn_value) IS NOT NULL THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_02             --���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_prof_nm               --�g�[�N���R�[�h1
                    ,iv_token_value1 => lv_tkn_value                 --�g�[�N���l1
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    END IF;
--
    -- �擾�����v���t�@�C���l��OUT�p�����[�^�ɐݒ�
    ov_company_cd     :=  lv_company_cd;       -- ��ЃR�[�h�i�Œ�l001�j
    ov_csv_dir        :=  lv_csv_dir;          -- CSV�t�@�C���o�͐�
    ov_csv_nm         :=  lv_csv_nm;           -- CSV�t�@�C����
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
  END get_profile_info;
--
  /**********************************************************************************
   * Procedure Name   : open_csv_file
   * Description      : �c�ƈ��}�X�^���CSV�t�@�C���I�[�v��(A-3)
   ***********************************************************************************/
  PROCEDURE open_csv_file(
     iv_csv_dir        IN  VARCHAR2         -- CSV�t�@�C���o�͐�
    ,iv_csv_nm         IN  VARCHAR2         -- CSV�t�@�C����
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
       location    => iv_csv_dir
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
                    ,iv_name         => cv_tkn_number_07             --���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_csv_loc               --�g�[�N���R�[�h1
                    ,iv_token_value1 => iv_csv_dir                   --�g�[�N���l1
                    ,iv_token_name2  => cv_tkn_csv_fnm               --�g�[�N���R�[�h2
                    ,iv_token_value2 => iv_csv_nm                    --�g�[�N���l2
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
                         location   => iv_csv_dir
                        ,filename   => iv_csv_nm
                        ,open_mode  => cv_w
                      );
    -- *** DEBUG_LOG ***
    -- �t�@�C���I�[�v���������Ƃ����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg9    || CHR(10)   ||
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
                      ,iv_token_value1 => iv_csv_dir           --�g�[�N���l1
                      ,iv_token_name2  => cv_tkn_csv_fnm       --�g�[�N���R�[�h2
                      ,iv_token_value2 => iv_csv_nm            --�g�[�N���l2
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE file_err_expt;
    END;
  EXCEPTION
    -- *** �t�@�C��������O�n���h�� ***
    WHEN file_err_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file => gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file => gf_file_hand
        );
--
      -- *** DEBUG_LOG ***
      -- �t�@�C���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err1 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_csv_nm   || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
--
      -- *** DEBUG_LOG ***
      -- �t�@�C���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err2 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_csv_nm   || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
--
      -- *** DEBUG_LOG ***
      -- �t�@�C���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_csv_nm   || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
--
      -- *** DEBUG_LOG ***
      -- �t�@�C���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err4 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_csv_nm   || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END open_csv_file;
--
  /* 2009/03/26 M.Maruyama ST0156�Ή� START */
  --/**********************************************************************************
  -- * Procedure Name   : get_prsn_cnnct_data
  -- * Description      : �c�ƈ��}�X�^�֘A��񒊏o����(A-5)
  -- ***********************************************************************************/
  --PROCEDURE get_prsn_cnnct_data(
  --   io_person_data_rec IN OUT NOCOPY g_get_data_rtype -- �c�ƈ��}�X�^���
  --  ,id_process_date    IN     DATE                    -- �Ɩ��������t
  --  ,ov_errbuf          OUT    NOCOPY VARCHAR2         -- �G���[�E���b�Z�[�W            --# �Œ� #
  --  ,ov_retcode         OUT    NOCOPY VARCHAR2         -- ���^�[���E�R�[�h              --# �Œ� #
  --  ,ov_errmsg          OUT    NOCOPY VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  --)
  --IS
  --  -- ===============================
  --  -- �Œ胍�[�J���萔
  --  -- ===============================
  --  cv_prg_name   CONSTANT VARCHAR2(100) := 'get_prsn_cnnct_data';  -- �v���O������
----
----#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
----
  --  lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
  --  lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
  --  lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
----
----###########################  �Œ蕔 END   ####################################
----
  --  -- ===============================
  --  -- ���[�U�[�錾��
  --  -- ===============================
  --  -- *** ���[�J���萔 ***
  --  cv_no               CONSTANT VARCHAR2(1)   :=  'N';
  --  cv_processing_name  CONSTANT VARCHAR2(100) :=  '�c�ƈ��}�X�^�֘A���';
  --  -- *** ���[�J���ϐ� ***
  --  --�擾�f�[�^�i�[�p
  --  lt_attribute1  jtf_rs_group_members.attribute1%TYPE;    -- �O���[�v���敪
  --  lt_attribute2  jtf_rs_group_members.attribute2%TYPE;    -- �O���[�v�R�[�h
  --  ld_date        DATE;                                    -- �Ɩ��������t�i�[�p('yyyymmdd'�`��)
  --  -- *** ���[�J���E��O ***
  --  error_expt      EXCEPTION;            -- �f�[�^���o�G���[��O
----
  --BEGIN
----
----##################  �Œ�X�e�[�^�X�������� START   ###################
----
  --  ov_retcode := cv_status_normal;
----
----###########################  �Œ蕔 END   ############################
----
  ---- �Ɩ��������t��'yyyymmdd'�`���Ŋi�[
  --ld_date := TRUNC(id_process_date);
  --  -- ============================
  --  -- �c�ƈ��}�X�^�֘A��񒊏o����
  --  -- ============================
  --  BEGIN
  --    SELECT  jrgm.attribute1   --�O���[�v���敪
  --           ,jrgm.attribute2   --�O���[�v�R�[�h
  --    INTO    lt_attribute1
  --           ,lt_attribute2
  --    FROM    jtf_rs_group_members  jrgm    -- ���\�[�X�O���[�v�����o�[�e�[�u��
  --           ,jtf_rs_groups_b       jrgb    -- ���\�[�X�O���[�v�e�[�u��
  --    WHERE  jrgm.resource_id   = io_person_data_rec.resource_id
  --      AND  jrgm.group_id      = jrgb.group_id
  --      AND  jrgb.attribute1    = io_person_data_rec.base_code
  --      AND  jrgm.delete_flag   = cv_no
  --      AND  NVL(jrgb.start_date_active,ld_date) <= ld_date
  --      AND  NVL(jrgb.end_date_active,ld_date) >= ld_date
  --    ;
  --  EXCEPTION
  --    WHEN NO_DATA_FOUND THEN
  --      -- �f�[�^�����݂��Ȃ��ꍇ��NULL��ݒ�
  --      lt_attribute1 := NULL;
  --      lt_attribute2 := NULL;
  --    WHEN OTHERS THEN
  --      lv_errmsg := xxccp_common_pkg.get_msg(
  --                        iv_application  => cv_app_name                           -- �A�v���P�[�V�����Z�k��
  --                       ,iv_name         => cv_tkn_number_04                      -- ���b�Z�[�W�R�[�h
  --                       ,iv_token_name1  => cv_tkn_prcss_nm                       -- �g�[�N���l1
  --                       ,iv_token_value1 => cv_processing_name                    -- �G���[����������
  --                       ,iv_token_name2  => cv_tkn_errmessage                     -- �g�[�N���R�[�h2
  --                       ,iv_token_value2 => SQLERRM                               -- SQL�G���[���b�Z�[�W
  --                    );
  --      lv_errbuf  := lv_errmsg||SQLERRM;
  --      RAISE error_expt;
  --  END;
  --  -- �擾�����l��OUT�p�����[�^�ɐݒ�
  --  io_person_data_rec.group_leader_flag := lt_attribute1; --�O���[�v���敪
  --  io_person_data_rec.group_cd          := lt_attribute2; --�O���[�v�R�[�h
----
  --EXCEPTION
----
  ---- *** �f�[�^���o��O�n���h�� ***
  --  WHEN error_expt THEN
  --    ov_errmsg  := lv_errmsg;
  --    ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
  --    ov_retcode := cv_status_error;
----
----#################################  �Œ��O������ START   ####################################
----
  --  -- *** ���ʊ֐���O�n���h�� ***
  --  WHEN global_api_expt THEN
  --    ov_errmsg  := lv_errmsg;
  --    ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
  --    ov_retcode := cv_status_error;
  --  -- *** ���ʊ֐�OTHERS��O�n���h�� ***
  --  WHEN global_api_others_expt THEN
  --    ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
  --    ov_retcode := cv_status_error;
  --  -- *** OTHERS��O�n���h�� ***
  --  WHEN OTHERS THEN
  --    ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
  --    ov_retcode := cv_status_error;
----
----#####################################  �Œ蕔 END   ##########################################
----
  --END get_prsn_cnnct_data;
----
  /* 2009/03/26 M.Maruyama ST0156�Ή� END */
  /**********************************************************************************
   * Procedure Name   : create_csv_rec
   * Description      : �c�ƈ��}�X�^CSV�o��(A-6)
   ***********************************************************************************/
  PROCEDURE create_csv_rec(
     i_person_data_rec   IN  g_get_data_rtype    -- �c�ƈ��}�X�^���
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
    cv_sep_com         CONSTANT VARCHAR2(1)  := ',';
    cv_sep_wquot       CONSTANT VARCHAR2(1)  := '"';
--
    -- *** ���[�J���ϐ� ***
    lv_data            VARCHAR2(5000);   -- �ҏW�f�[�^�i�[
--
    -- *** ���[�J���E���R�[�h ***
    l_person_data_rec  g_get_data_rtype; -- IN�p�����[�^.�c�ƈ��ʌv�撊�o�f�[�^�i�[
    -- *** ���[�J����O ***
    file_put_line_expt   EXCEPTION;      -- �f�[�^�o�͏�����O
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
    l_person_data_rec := i_person_data_rec; -- �c�ƈ��ʌv�撊�o�f�[�^
--
    -- ======================
    -- CSV�o�͏��� 
    -- ======================
    BEGIN
      -- �f�[�^�쐬
      lv_data := cv_sep_wquot || l_person_data_rec.company_cd || cv_sep_wquot                 -- ��ЃR�[�h
        || cv_sep_com || cv_sep_wquot || l_person_data_rec.employee_number   || cv_sep_wquot  -- �c�ƈ��R�[�h
        || cv_sep_com || cv_sep_wquot || l_person_data_rec.base_code         || cv_sep_wquot  -- ���_�R�[�h
        || cv_sep_com || cv_sep_wquot || l_person_data_rec.person_name       || cv_sep_wquot  -- �c�ƈ�����
        || cv_sep_com || cv_sep_wquot || l_person_data_rec.person_name_kana  || cv_sep_wquot  -- �c�ƈ������i�J�i�j
        || cv_sep_com || cv_sep_wquot || l_person_data_rec.business_form     || cv_sep_wquot  -- �c�ƌ`��
        || cv_sep_com || cv_sep_wquot || l_person_data_rec.group_leader_flag || cv_sep_wquot  -- �O���[�v���敪
        || cv_sep_com || l_person_data_rec.group_cd                                           -- �O���[�v�R�[�h
        || cv_sep_com || TO_CHAR(l_person_data_rec.cprtn_date, 'yyyymmddhh24miss')            -- �A�g����
      ;
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
                       iv_application  => cv_app_name                     --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_06                --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_slspsn_cd                --�g�[�N���R�[�h1
                      ,iv_token_value1 => l_person_data_rec.company_cd    --�g�[�N���l1
                      ,iv_token_name2  => cv_base_cd                      --�g�[�N���R�[�h2
                      ,iv_token_value2 => l_person_data_rec.base_code     --�g�[�N���l2
                      ,iv_token_name3  => cv_sls_pttn                     --�g�[�N���R�[�h3
                      ,iv_token_value3 => l_person_data_rec.business_form --�g�[�N���l3
                      ,iv_token_name4  => cv_grp_cd                       --�g�[�N���R�[�h4
                      ,iv_token_value4 => l_person_data_rec.group_cd      --�g�[�N���l4
                      ,iv_token_name5  => cv_tkn_errmsg                   --�g�[�N���R�[�h4
                      ,iv_token_value5 => SQLERRM                         --�g�[�N���l4
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE file_put_line_expt;
    END;
--
  EXCEPTION
    -- *** �t�@�C��������O�n���h�� ***
    WHEN file_put_line_expt THEN
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
   * Description      : �c�ƈ��}�X�^���CSV�t�@�C���N���[�Y����(A-7)
   ***********************************************************************************/
  PROCEDURE close_csv_file(
     iv_csv_dir        IN  VARCHAR2         -- CSV�t�@�C���o�͐�
    ,iv_csv_nm         IN  VARCHAR2         -- CSV�t�@�C����
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
      ,buff   => cv_debug_msg10    || CHR(10)   ||
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
                      ,iv_token_value1 => iv_csv_dir                   --�g�[�N���l1
                      ,iv_token_name2  => cv_tkn_csv_fnm               --�g�[�N���R�[�h2
                      ,iv_token_value2 => iv_csv_nm                    --�g�[�N���l2
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE file_err_expt;
    END;
  EXCEPTION
    -- *** �t�@�C��������O�n���h�� ***
    WHEN file_err_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file => gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file => gf_file_hand
        );
--
      -- *** DEBUG_LOG ***
      -- �t�@�C���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err1 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_csv_nm   || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file => gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
--
      -- *** DEBUG_LOG ***
      -- �t�@�C���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err2 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_csv_nm   || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file => gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
--
      -- *** DEBUG_LOG ***
      -- �t�@�C���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_csv_nm   || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file => gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file => gf_file_hand
        );
      -- *** DEBUG_LOG ***
      -- �t�@�C���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err4 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_csv_nm   || CHR(10) ||
                   ''
      );
      END IF;
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
     ov_errbuf           OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'submain';     -- �v���O������
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
      cv_space        CONSTANT VARCHAR2(2) := '�@';       -- �S�p�X�y�[�X
      cv_category     CONSTANT VARCHAR2(8) := 'EMPLOYEE'; -- ���o�����J�e�S���[�ɓ��Ă�l
    -- *** ���[�J���ϐ� ***
    -- OUT�p�����[�^�i�[�p
    ld_sysdate      DATE;           -- �V�X�e�����t
    ld_process_date DATE;           -- �Ɩ��������t
    ln_year         NUMBER;         -- �f�[�^���o�p�����[�^(�N�x)
    lv_company_cd   VARCHAR2(2000); -- ��ЃR�[�h�i�Œ�l001�j
    lv_csv_dir      VARCHAR2(2000); -- CSV�t�@�C���o�͐�
    lv_csv_nm       VARCHAR2(2000); -- CSV�t�@�C����
    lv_cntrbt_sls   VARCHAR2(2000); -- �v������̒l(�Œ�l15000)
    -- �t�@�C���I�[�v���m�F�߂�l�i�[
    lb_fopn_retcd   BOOLEAN;
    -- �Ɩ��������t�i�[�p('yyyymmdd'�`��)
    ld_date         DATE;
--
    -- *** ���[�J���E�J�[�\�� ***
  /* 2009/03/26 M.Maruyama ST0156�Ή� START */
    CURSOR get_person_data_cur
    IS
      SELECT  xrrv.employee_number employee_number  -- �c�ƈ��R�[�h
             ,( CASE
                 WHEN TO_DATE(xrrv.issue_date, 'yyyy/mm/dd') <= ld_date THEN
                   xrrv.work_dept_code_new          -- �Ζ��n���_�R�[�h(�V)
                 WHEN TO_DATE(xrrv.issue_date, 'yyyy/mm/dd')  > ld_date THEN
                   xrrv.work_dept_code_old          -- �Ζ��n���_�R�[�h(��)
                 WHEN xrrv.issue_date IS NULL THEN
                   xrrv.work_dept_code_old          -- �Ζ��n���_�R�[�h(��)
                 END
              )  base_code                          -- ���_�R�[�h
             /* 2009.04.16 K.Satomura T1_0172�Ή� START */
             --,SUBSTRB(xrrv.last_name,1,cn_name_lengthb) || cv_space ||
             --  SUBSTRB(xrrv.first_name,1,cn_name_lengthb)  person_name            -- �c�ƈ�����
             --,SUBSTRB(xrrv.last_name_kana,1,cn_name_lengthb) || cv_space ||
             --  SUBSTRB(xrrv.first_name_kana,1,cn_name_lengthb)  person_name_kana  -- �c�ƈ������i�J�i�j
             ,SUBSTRB(xxcso_util_common_pkg.conv_multi_byte(
                SUBSTRB(xrrv.last_name,1,cn_name_lengthb) || cv_space || SUBSTRB(xrrv.first_name,1,cn_name_lengthb)
             ),1,40) person_name -- �c�ƈ�����
             ,SUBSTRB(xxcso_util_common_pkg.conv_multi_byte(
                SUBSTRB(xrrv.last_name_kana,1,cn_name_lengthb) || cv_space || SUBSTRB(xrrv.first_name_kana,1,cn_name_lengthb)
             ),1,40) person_name_kana -- �c�ƈ������i�J�i�j
             /* 2009.04.16 K.Satomura T1_0172�Ή� END */
             ,xrrv.sales_style  sales_style         -- �c�ƌ`��
             ,xrrv.resource_id  resource_id         -- ���\�[�XID
             ,( CASE
                 WHEN TO_DATE(xrrv.issue_date, 'yyyy/mm/dd') <= ld_date THEN
                   xrrv.group_leader_flag_new       -- �O���[�v���敪(�V)
                 WHEN TO_DATE(xrrv.issue_date, 'yyyy/mm/dd')  > ld_date THEN
                   xrrv.group_leader_flag_old       -- �O���[�v���敪(��)
                 WHEN xrrv.issue_date IS NULL THEN
                   xrrv.group_leader_flag_old       -- �O���[�v���敪(��)
                 END
              )  group_leader_flag                  -- �O���[�v���敪
             ,( CASE
                 WHEN TO_DATE(xrrv.issue_date, 'yyyy/mm/dd') <= ld_date THEN
                   xrrv.group_number_new            -- �O���[�v�ԍ�(�V)
                 WHEN TO_DATE(xrrv.issue_date, 'yyyy/mm/dd')  > ld_date THEN
                   xrrv.group_number_old            -- �O���[�v�ԍ�(��)
                 WHEN xrrv.issue_date IS NULL THEN
                   xrrv.group_number_old            -- �O���[�v�ԍ�(��)
                 END
              )  group_number                       -- �O���[�v�ԍ�
      FROM   xxcso_resource_relations_v xrrv        -- ���\�[�X�֘A�}�X�^�r���[
      WHERE  xrrv.employee_start_date <= ld_date
        AND  xrrv.employee_end_date   >= ld_date
        AND  xrrv.assign_start_date   <= ld_date
        AND  xrrv.assign_end_date     >= ld_date
        AND  xrrv.resource_start_date <= ld_date
        AND  NVL(xrrv.resource_end_date,ld_date)     >= ld_date
        AND  NVL(xrrv.start_date_active_new,ld_date) <= ld_date
        AND  NVL(xrrv.end_date_active_new,ld_date)   >= ld_date
        AND  NVL(xrrv.start_date_active_old,ld_date) <= ld_date
        AND  NVL(xrrv.end_date_active_old,ld_date)   >= ld_date
      ;
    --CURSOR get_person_data_cur
    --IS
    --  SELECT  papf.employee_number  employee_number                    -- �c�ƈ��R�[�h
    --         ,( CASE
    --             WHEN TO_DATE(paaf.ass_attribute2, 'yyyy/mm/dd') <= ld_date THEN
    --               paaf.ass_attribute3  -- �Ζ��n���_�R�[�h(�V)
    --             WHEN TO_DATE(paaf.ass_attribute2, 'yyyy/mm/dd')  > ld_date THEN
    --               paaf.ass_attribute4  -- �Ζ��n���_�R�[�h(��)
    --             WHEN paaf.ass_attribute2 IS NULL THEN
    --               paaf.ass_attribute4  -- �Ζ��n���_�R�[�h(��)
    --             END
    --          )  base_code                                            -- ���_�R�[�h
    --         ,SUBSTRB(papf.per_information18,1,cn_name_lengthb) || cv_space ||
    --           SUBSTRB(papf.per_information19,1,cn_name_lengthb)  person_name     -- �c�ƈ�����
    --         ,SUBSTRB(papf.last_name,1,cn_name_lengthb) || cv_space ||
    --           SUBSTRB(papf.first_name,1,cn_name_lengthb)  person_name_kana       -- �c�ƈ������i�J�i�j
    --         ,jrre.attribute1    business_form                         -- �c�ƌ`��
    --         ,jrre.resource_id  resource_id                            -- ���\�[�XID
    --  FROM   per_people_f           papf                        -- �]�ƈ��}�X�^
    --        ,per_assignments_f      paaf                        -- �]�ƈ��}�X�^�A�T�C�����g
    --        ,jtf_rs_resource_extns  jrre                        -- ���\�[�X�e�[�u��
    --  WHERE  jrre.category  = cv_category
    --    AND  jrre.source_id = papf.person_id
    --    AND  papf.person_id = paaf.person_id
    --    AND  papf.effective_start_date <= ld_date
    --    AND  papf.effective_end_date   >= ld_date
    --    AND  paaf.effective_start_date <= ld_date
    --    AND  paaf.effective_end_date   >= ld_date
    --    AND  jrre.start_date_active    <= ld_date
    --    AND  NVL(jrre.end_date_active,ld_date) >= ld_date
    --  ;
  /* 2009/03/26 M.Maruyama ST0156�Ή� END */
--
    -- *** ���[�J���E���R�[�h ***
    l_get_person_data_rec   get_person_data_cur%ROWTYPE;
    l_get_data_rec          g_get_data_rtype;
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
--
    -- ========================================
    -- A-1.�������� 
    -- ========================================
    init(
       od_sysdate      => ld_sysdate          -- �V�X�e�����t
      ,od_process_date => ld_process_date     -- �Ɩ��������t
      ,ov_errbuf       => lv_errbuf           -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode      => lv_retcode          -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg       => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
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
      ,ov_csv_dir     => lv_csv_dir     -- CSV�t�@�C���o�͐�
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
    -- A-3.�c�ƈ��}�X�^���CSV�t�@�C���I�[�v��
    -- =================================================
    open_csv_file(
       iv_csv_dir   => lv_csv_dir   -- CSV�t�@�C���o�͐�
      ,iv_csv_nm    => lv_csv_nm    -- CSV�t�@�C����
      ,ov_errbuf    => lv_errbuf    -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode   => lv_retcode   -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg    => lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- A-4.�c�ƈ��}�X�^��񒊏o����
    -- ========================================
    -- �Ɩ��������t��'yyyymmdd'�`���Ŋi�[
    ld_date := TRUNC(ld_process_date);
    -- �J�[�\���I�[�v��
    OPEN get_person_data_cur;
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
      FETCH get_person_data_cur INTO l_get_person_data_rec;
      -- �����Ώی����i�[
      gn_target_cnt := get_person_data_cur%ROWCOUNT;
--
      EXIT WHEN get_person_data_cur%NOTFOUND
      OR  get_person_data_cur%ROWCOUNT = 0;
      -- ���R�[�h�ϐ�������
      l_get_data_rec := NULL;
      -- �擾�f�[�^���i�[
      l_get_data_rec.company_cd        := lv_company_cd;                            -- ��ЃR�[�h
      l_get_data_rec.employee_number   := l_get_person_data_rec.employee_number;    -- �c�ƈ��R�[�h
      l_get_data_rec.base_code         := l_get_person_data_rec.base_code;          -- ���_�R�[�h
      l_get_data_rec.person_name       := l_get_person_data_rec.person_name;        -- �c�ƈ�����
      l_get_data_rec.person_name_kana  := l_get_person_data_rec.person_name_kana;   -- �c�ƈ�����(�J�i)
  /* 2009/03/26 M.Maruyama ST0156�Ή� START */
      --l_get_data_rec.business_form     := l_get_person_data_rec.business_form;    -- �c�ƌ`��
      l_get_data_rec.business_form     := l_get_person_data_rec.sales_style;        -- �c�ƌ`��
  /* 2009/03/26 M.Maruyama ST0156�Ή� END */
      l_get_data_rec.cprtn_date        := ld_sysdate;                               -- �A�g����
      l_get_data_rec.resource_id       := l_get_person_data_rec.resource_id;        -- ���\�[�XID
  /* 2009/03/26 M.Maruyama ST0156�Ή� START */
      l_get_data_rec.group_leader_flag := l_get_person_data_rec.group_leader_flag;  -- �O���[�v���敪
      l_get_data_rec.group_cd          := l_get_person_data_rec.group_number;       -- �O���[�v�ԍ�
--
      ---- ========================================
      ---- A-5.�c�ƈ��}�X�^�֘A��񒊏o����
      ---- ========================================
      --get_prsn_cnnct_data(
      --   io_person_data_rec => l_get_data_rec   --�c�ƈ��}�X�^���
      --  ,id_process_date    => ld_process_date  -- �Ɩ��������t
      --  ,ov_errbuf          => lv_errbuf        -- �G���[�E���b�Z�[�W            --# �Œ� #
      --  ,ov_retcode         => lv_retcode       -- ���^�[���E�R�[�h              --# �Œ� #
      --  ,ov_errmsg          => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
      --);
--    --
      --IF (lv_retcode = cv_status_error) THEN
      --  RAISE global_process_expt;
      --END IF;
  /* 2009/03/26 M.Maruyama ST0156�Ή� END */
--
      -- ========================================
      -- A-6.�c�ƈ��}�X�^CSV�o��
      -- ========================================
      create_csv_rec(
        i_person_data_rec  =>  l_get_data_rec   --�c�ƈ��}�X�^���
       ,ov_errbuf          =>  lv_errbuf        -- �G���[�E���b�Z�[�W            --# �Œ� #
       ,ov_retcode         =>  lv_retcode       -- ���^�[���E�R�[�h              --# �Œ� #
       ,ov_errmsg          =>  lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
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
    -- �J�[�\���N���[�Y
    CLOSE get_person_data_cur;
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
                    ,iv_name         => cv_tkn_number_09             --���b�Z�[�W�R�[�h
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE no_data_expt;
    END IF;
--
    -- ========================================
    -- CSV�t�@�C���N���[�Y (A-7) 
    -- ========================================
    close_csv_file(
       iv_csv_dir   => lv_csv_dir   -- CSV�t�@�C���o�͐�
      ,iv_csv_nm    => lv_csv_nm    -- CSV�t�@�C����
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
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file => gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file => gf_file_hand
        );
      -- *** DEBUG_LOG ***
      -- �t�@�C���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err5 || cv_msg_part ||
                   cv_debug_msg_fnm  || lv_csv_nm   || CHR(10) ||
                   ''
      );
      END IF;
--
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (get_person_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_person_data_cur;
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
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- �G���[�����J�E���g
      gn_error_cnt := gn_error_cnt + 1;
--
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file => gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file => gf_file_hand
        );
      -- *** DEBUG_LOG ***
      -- �t�@�C���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err6 || cv_msg_part ||
                   cv_debug_msg_fnm  || lv_csv_nm   || CHR(10) ||
                   ''
      );
      END IF;
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (get_person_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_person_data_cur;
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
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �G���[�����J�E���g
      gn_error_cnt := gn_error_cnt + 1;
--
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file => gf_file_hand
        );
      -- *** DEBUG_LOG ***
      -- �t�@�C���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || cv_msg_part ||
                   cv_debug_msg_fnm  || lv_csv_nm   || CHR(10) ||
                   ''
      );
      END IF;
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (get_person_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_person_data_cur;
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
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      -- *** DEBUG_LOG ***
      -- �t�@�C���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err4 || cv_msg_part ||
                   cv_debug_msg_fnm  || lv_csv_nm   || CHR(10) ||
                   ''
      );
      END IF;
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (get_person_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_person_data_cur;
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
     errbuf        OUT NOCOPY VARCHAR2    --   �G���[�E���b�Z�[�W  --# �Œ� #
    ,retcode       OUT NOCOPY VARCHAR2 )  --   ���^�[���E�R�[�h    --# �Œ� #
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
       ov_errbuf   => lv_errbuf          -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode  => lv_retcode         -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg   => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
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
    -- A-8.�I������ 
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
        ,buff   => cv_debug_msg11 || CHR(10) ||
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
        ,buff   => cv_debug_msg11 || CHR(10) ||
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
        ,buff   => cv_debug_msg11 || CHR(10) ||
                   ''
      );
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCSO016A02C;
/
