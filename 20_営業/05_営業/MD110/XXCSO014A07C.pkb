CREATE OR REPLACE PACKAGE BODY APPS.XXCSO014A07C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO014A07C(body)
 * Description      : �K��敪�}�X�^��HHT�ɑ��M���邽�߂� 
 *                    CSV�t�@�C�����쐬���܂��B
 * MD.050           : MD050_CSO_014_A07_HHT-EBS�C���^�[�t�F�[�X�F
 *                    (OUT)�K��敪�}�X�^_Draft2.0C
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   �������� (A-1)
 *  get_profile_info       �v���t�@�C���l�擾 (A-2)
 *  open_csv_file          CSV�t�@�C���I�[�v�� (A-3)
 *  create_csv_rec         �K��\��f�[�^CSV�o�� (A-5) 
 *  close_csv_file         CSV�t�@�C���N���[�Y (A-6) 
 *  submain                ���C�������v���V�[�W��
 *                           �Ώۃf�[�^�擾���� (A-4)
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                           �I������ (A-7)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-11-28    1.0   Seirin.Kin        �V�K�쐬
 *  2009-01-28    1.0   Kenji.Sai         �f�[�^���o����L���N���A�K��敪�̏����ɏC��
 *  2009-03-18    1.1   Kazuo.Satomura    ��Q�Ή�(�s�ID60)
 *                                        �E�ŏI�X�V���̏����C��
 *                                        �E�K����e�̃o�C�g���C��
 *  2009-05-01    1.2   Tomoko.Mori      T1_0897�Ή�
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
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCSO014A07C';   -- �p�b�P�[�W��
  cv_app_name            CONSTANT VARCHAR2(5)   := 'XXCSO';          -- �A�v���P�[�V�����Z�k��
--
  -- ���b�Z�[�W�R�[�h
  cv_tkn_number_01    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00011';  -- �Ɩ��������t�擾�G���[
  cv_tkn_number_02    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00014';  -- �v���t�@�C���擾�G���[
  cv_tkn_number_03    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00015';  -- CSV�t�@�C���I�[�v���G���[
  cv_tkn_number_04    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00018';  -- CSV�t�@�C���N���[�Y�G���[
  cv_tkn_number_05    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00123';  -- CSV�t�@�C���c���G���[
  cv_tkn_number_06    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00141';  -- �f�[�^���o�G���[
  cv_tkn_number_07    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00245';  -- CSV�t�@�C���o�̓G���[
  cv_tkn_number_08    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00152';  -- �C���^�t�@�[�X�t�@�C����
  cv_tkn_number_09    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00224';  -- CSV�t�@�C���o��0���G���[
--
  -- �g�[�N���R�[�h
  cv_tkn_prof_nm          CONSTANT VARCHAR2(20) := 'PROF_NAME';
  cv_tkn_errmsg           CONSTANT VARCHAR2(20) := 'ERR_MESSAGE';
  cv_tkn_message          CONSTANT VARCHAR2(20) := 'MESSAGE';
  cv_tkn_value            CONSTANT VARCHAR2(20) := 'VALUE';
  cv_tkn_status           CONSTANT VARCHAR2(20) := 'STATUS';
  cv_tkn_csv_location     CONSTANT VARCHAR2(20) := 'CSV_LOCATION';
  cv_tkn_csv_fnm          CONSTANT VARCHAR2(20) := 'CSV_FILE_NAME';
  cv_tkn_csv_loc          CONSTANT VARCHAR2(20) := 'CSV_LOCATION';
  cv_tkn_ym               CONSTANT VARCHAR2(20) := 'YEAR_MONTH';
  cv_tkn_lookup_code      CONSTANT VARCHAR2(20) := 'LOOKUP_CODE';
  cv_tkn_tbl              CONSTANT VARCHAR2(20) := 'TABLE';
  cv_tkn_cnt              CONSTANT VARCHAR2(20) := 'COUNT';
  cv_tkn_meaning          CONSTANT VARCHAR2(20) := 'MEANING';
  cv_tkn_date_next        CONSTANT VARCHAR2(20) := 'DATE_NEXT_MONTH';
--
  cb_true                 CONSTANT BOOLEAN := TRUE;
  cb_false                CONSTANT BOOLEAN := FALSE;
--
  -- DEBUG_LOG�p���b�Z�[�W
  cv_debug_msg1           CONSTANT VARCHAR2(200) := '<< �v���t�@�C���l: >>';
  cv_debug_msg2           CONSTANT VARCHAR2(200) := '�t�@�C���o�͐� : ';
  cv_debug_msg3           CONSTANT VARCHAR2(200) := '�t�@�C���� : ';
  cv_debug_msg4           CONSTANT VARCHAR2(200) := 'CSV�t�@�C�����I�[�v�����܂����B';
  cv_debug_msg5           CONSTANT VARCHAR2(200) := '<< CSV�t�@�C�����N���[�Y���܂��� >>' ;
  cv_debug_msg6           CONSTANT VARCHAR2(200) := '�K��敪�F';
  cv_debug_msg7           CONSTANT VARCHAR2(200) := '�K����e�F';
  cv_debug_msg8           CONSTANT VARCHAR2(200) := '�ŏI�X�V���F';
  cv_debug_msg9           CONSTANT VARCHAR2(200) := '�L���N���F';
  cv_debug_msg_fcls       CONSTANT VARCHAR2(200) := '<< ��O��������CSV�t�@�C�����N���[�Y���܂��� >>';
  cv_debug_msg_fnm        CONSTANT VARCHAR2(200) := 'filename = ';
  cv_debug_msg_err1       CONSTANT VARCHAR2(200) := 'file_err_expt';
  cv_debug_msg_err2       CONSTANT VARCHAR2(200) := 'global_api_expt';
  cv_debug_msg_err3       CONSTANT VARCHAR2(200) := 'global_api_others_expt';
  cv_debug_msg_err4       CONSTANT VARCHAR2(200) := 'others��O';
  cv_debug_msg_err5       CONSTANT VARCHAR2(200) := 'no_data_expt';
  cv_debug_msg_err6       CONSTANT VARCHAR2(200) := 'global_process_expt';
  cv_debug_msg_err7       CONSTANT VARCHAR2(200) := '<< ��O�������J�[�\�����N���[�Y���܂��� >>' ;
  cv_debug_msg_err8       CONSTANT VARCHAR2(200) := '<< �֐��Ŏ擾���ꂽ�Ɩ��������F>>' ;
  cv_debug_msg_ccls1      CONSTANT VARCHAR2(200) := '<< �J�[�\�����N���[�Y���܂��� >>';
--  
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- �t�@�C���E�n���h���̐錾
  gf_file_hand       UTL_FILE.FILE_TYPE;
--
  gd_process_date    DATE;            --�Ɩ��������i�[
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �擾���i�[���R�[�h�^��`
--
  -- �K��敪���i�[���R�[�h�^��`
  TYPE g_get_data_rec IS RECORD(
    lookup_code       fnd_lookup_values_vl.lookup_code%TYPE,
    meaning           fnd_lookup_values_vl.meaning%TYPE,
    last_update_date  fnd_lookup_values_vl.last_update_date%TYPE,
    year_month        VARCHAR2(6)
  );
--
  /***********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_process_date     IN         VARCHAR2,     -- �Ɩ��������擾
    ov_errbuf           OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'init';              -- �v���O������

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
    
    cv_tkn_number_10        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00012';  -- ���t�����G���[���b�Z�[�W
    cv_tkn_number_17        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00147';  -- �p�����[�^������


    -- *** ���[�J���ϐ� ***
    ld_process_date DATE;             -- �Ɩ��������t�i�[�p
    lv_noprm_msg    VARCHAR2(4000);   -- �R���J�����g���̓p�����[�^�Ȃ����b�Z�[�W�i�[�p
    lb_boolean      BOOLEAN;          -- �Ɩ��������`�F�b�N�֐�RETURN�l���i�[
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
    -- �Ɩ��������t�擾���� 
    -- ===========================
    -- ���b�Z�[�W�o��
    lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name              --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_17         --���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_value             --�g�[�N���R�[�h1
                    ,iv_token_value1 => iv_process_date          --�g�[�N���l1
                   );
    fnd_file.put_line(
          which  => FND_FILE.OUTPUT,
          buff   => ''      || CHR(10) ||     -- ��s�̑}��
                  lv_errmsg || CHR(10) ||
                   ''                         -- ��s�̑}��
        );
    IF (iv_process_date IS NULL) THEN
      ld_process_date := xxccp_common_pkg2.get_process_date;       -- �֐��ŋƖ����������擾
      -- �Ɩ��������t�擾�Ɏ��s�����ꍇ
      IF (ld_process_date IS NULL) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name              --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_01         --���b�Z�[�W�R�[�h
                   );
        lv_errbuf := lv_errmsg ;
        RAISE global_api_expt;
      END IF;
      -- *** DEBUG_LOG ***
      -- �擾�����Ɩ������������O�o��
      fnd_file.put_line(
        which  => FND_FILE.LOG
       ,buff   => cv_debug_msg_err8  || ld_process_date ||
                ''
      );
    ELSE
      lb_boolean := xxcso_util_common_pkg.check_date(
        iv_process_date,
        'YYYYMMDD'
        );
      IF ( lb_boolean = FALSE ) THEN
        lv_noprm_msg   := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                 -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_10            -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_value                -- �g�[�N���R�[�h1
                         ,iv_token_value1 => iv_process_date             -- �Ɩ�������
                         ,iv_token_name2  => cv_tkn_status               -- �g�[�N���R�[�h2
                         ,iv_token_value2 => 'FALSE'                     -- ���^�[���X�e�[�^�X
                         ,iv_token_name3  => cv_tkn_message              -- �g�[�N���R�[�h3
                         ,iv_token_value3 => SQLERRM                     -- SQLERRM
                        );
        -- ���b�Z�[�W�o��
        fnd_file.put_line(
          which  => FND_FILE.OUTPUT,
          buff   => ''           || CHR(10) ||     -- ��s�̑}��
                  lv_noprm_msg || CHR(10) ||
                   ''                            -- ��s�̑}��
        );
        RAISE global_api_expt;
      END IF;
      ld_process_date := TO_DATE(iv_process_date,'YYYYMMDD');
    END IF;
--
   
    -- �Ɩ��������t���O���o���ϐ��ɐݒ�
    gd_process_date        := ld_process_date;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_profile_info
   * Description      : �v���t�@�C���l�擾 (A-2)
  ***********************************************************************************/
   PROCEDURE get_profile_info(
    ov_csv_dir        OUT NOCOPY VARCHAR2  -- CSV�t�@�C���o�͐�
   ,ov_csv_nm         OUT NOCOPY VARCHAR2  -- CSV�t�@�C����
   ,ov_errbuf         OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W            --# �Œ� #
   ,ov_retcode        OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h              --# �Œ� #
   ,ov_errmsg         OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
  -- ===============================
  -- �Œ胍�[�J���萔
  -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'get_profile_info';     -- �v���O������
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
    cv_csv_dir        CONSTANT VARCHAR2(30)   := 'XXCSO1_HHT_OUT_CSV_DIR';
    -- CSV�t�@�C���o�͐�
    cv_csv_sls_mng    CONSTANT VARCHAR2(30)   := 'XXCSO1_HHT_OUT_CSV_HOUMON_KBN';
    -- �v���t�@�C����
  -- *** ���[�J���ϐ� ***    
    lv_csv_dir        VARCHAR2(2000);   -- CSV�t�@�C���o�͐�
    lv_csv_nm         VARCHAR2(2000);   -- CSV�t�@�C����
    lv_msg            VARCHAR2(4000);   -- �擾�f�[�^���b�Z�[�W�o�͗p
    lv_tkn_value      VARCHAR2(1000);   -- �v���t�@�C���l�擾���s�� �g�[�N���l�i�[�p   
  --
  BEGIN
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################

    -- ====================
    -- �ϐ����������� 
    -- ====================
    lv_tkn_value := NULL;
--
    -- =======================
    -- �v���t�@�C���l�擾���� 
    -- =======================
    FND_PROFILE.GET(
                    cv_csv_dir
                   ,lv_csv_dir
                   ); -- CSV�t�@�C���o�͐�
    FND_PROFILE.GET(
                    cv_csv_sls_mng
                   ,lv_csv_nm
                   ); -- CSV�t�@�C����
    -- *** DEBUG_LOG ***
    -- �擾�����v���t�@�C���l�����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg1  || CHR(10) ||
                 cv_debug_msg2  || lv_csv_dir || CHR(10) ||
                 cv_debug_msg3  || lv_csv_nm  || CHR(10) ||
                 ''
    );
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
    -- �v���t�@�C���l�擾�Ɏ��s�����ꍇ
    -- CSV�t�@�C���o�͐�擾���s��
    IF (lv_csv_dir IS NULL) THEN
      lv_tkn_value := cv_csv_dir;
    -- CSV�t�@�C�����擾���s��
    ELSIF (lv_csv_nm IS NULL) THEN
      lv_tkn_value := cv_csv_sls_mng;
    END IF;
    -- �G���[���b�Z�[�W�擾
    IF lv_tkn_value IS NOT NULL THEN
       lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_02             -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_prof_nm               -- �g�[�N���R�[�h1
                    ,iv_token_value1 => lv_tkn_value                 -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    END IF;
    -- �擾�����v���t�@�C���l��OUT�p�����[�^�ɐݒ�
    ov_csv_dir        :=  lv_csv_dir;          -- CSV�t�@�C���o�͐�
    ov_csv_nm         :=  lv_csv_nm;           -- CSV�t�@�C����
--#################################  �Œ��O������ START   ####################################
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
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
   * Description      : CSV�t�@�C���I�[�v�� (A-3)
   ***********************************************************************************/
  PROCEDURE open_csv_file(
     iv_csv_dir        IN  VARCHAR2  -- CSV�t�@�C���o�͐�
    ,iv_csv_nm         IN  VARCHAR2  -- CSV�t�@�C����
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
    -- CSV�t�@�C�����݃`�F�b�N
    UTL_FILE.FGETATTR(
       location    => iv_csv_dir
      ,filename    => iv_csv_nm
      ,fexists     => lb_retcd
      ,file_length => ln_file_size
      ,block_size  => ln_block_size
    );
--
    -- ���łɃt�@�C�������݂����ꍇ
    IF (lb_retcd = cb_true ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_05             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_csv_loc               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => iv_csv_dir                   -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_csv_fnm               -- �g�[�N���R�[�h1
                     ,iv_token_value2 => iv_csv_nm                    -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE file_err_expt;
    END IF;
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
        ,buff   => cv_debug_msg4   || CHR(10)   ||
                   cv_debug_msg_fnm || iv_csv_nm || CHR(10) ||
                   ''
      );
    EXCEPTION
      WHEN UTL_FILE.INVALID_PATH         OR     -- �t�@�C���p�X�s���G���[
           UTL_FILE.INVALID_MODE         OR     -- open_mode�p�����[�^�s���G���[
           UTL_FILE.INVALID_OPERATION    OR     -- �I�[�v���s�\�G���[
           UTL_FILE.INVALID_MAXLINESIZE  THEN   -- MAX_LINESIZE�l�����G���[
        -- �G���[���b�Z�[�W�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name          --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_03     --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_csv_loc       --�g�[�N���R�[�h1
                      ,iv_token_value1 => iv_csv_dir           --�g�[�N���l1
                      ,iv_token_name2  => cv_tkn_csv_fnm       --�g�[�N���R�[�h1
                      ,iv_token_value2 => iv_csv_nm            --�g�[�N���l1
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE file_err_expt;
    END;
  EXCEPTION
    -- *** �t�@�C��������O�n���h�� ***
    WHEN file_err_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
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
                   cv_debug_msg_fnm  || CHR(10) ||
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
                   cv_debug_msg_fnm  || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
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
                   cv_debug_msg_fnm  || CHR(10) ||
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
                   cv_debug_msg_fnm  || CHR(10) ||
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
  /**********************************************************************************
   * Procedure Name   : create_csv_rec
   * Description      : CSV�t�@�C���o�� (A-5)
  ***********************************************************************************/
  PROCEDURE create_csv_rec(
     ir_get_data_rec     IN  g_get_data_rec      -- �c�ƈ��ʌv�撊�o�f�[�^
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
    lv_data          VARCHAR2(4000);    -- �ҏW�f�[�^�i�[
    lv_data_info     VARCHAR2(4000);    -- �ҏW�f�[�^���O�ɏo�͗p
    lv_last_up_date  VARCHAR2(30);      -- �L���X�V���i�[
--
    -- *** ���[�J���E���R�[�h ***
    l_get_data_rec g_get_data_rec;      -- IN�p�����[�^.�c�ƈ��ʌv�撊�o�f�[�^�i�[
    -- *** ���[�J����O ***
    file_put_line_expt   EXCEPTION;     -- �f�[�^�o�͏�����O
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
    l_get_data_rec  := ir_get_data_rec; -- �c�ƈ��ʌv�撊�o�f�[�^
    lv_last_up_date := TO_CHAR(l_get_data_rec.last_update_date,'yyyy/mm/dd hh24:mi:ss'); -- �ŏI�X�V��
--
    -- ======================
    -- CSV�o�͏��� 
    -- ======================
    BEGIN
      -- �f�[�^�쐬
      lv_data := cv_sep_wquot || l_get_data_rec.lookup_code || cv_sep_wquot || cv_sep_com     -- �K��敪
              || cv_sep_wquot || l_get_data_rec.meaning || cv_sep_wquot || cv_sep_com         -- �K����e
              || l_get_data_rec.year_month || cv_sep_com                                      -- �L���N��
              || cv_sep_wquot || lv_last_up_date || cv_sep_wquot;                             -- �ŏI�X�V��
--
      -- �f�[�^�o��
      UTL_FILE.PUT_LINE(
        file   => gf_file_hand
       ,buffer => lv_data
      );
    EXCEPTION
      WHEN UTL_FILE.INVALID_FILEHANDLE OR     -- �t�@�C���E�n���h�������G���[
           UTL_FILE.INVALID_OPERATION  OR     -- �I�[�v���s�\�G���[
           UTL_FILE.WRITE_ERROR  THEN         -- �����ݑ��쒆�I�y���[�e�B���O�G���[
        -- �G���[���b�Z�[�W�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                          --�A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_07                     --���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_lookup_code                   -- �g�[�N���R�[�h1
                       ,iv_token_value1 => ir_get_data_rec.lookup_code          -- �K��敪
                       ,iv_token_name2  => cv_tkn_date_next                     -- �g�[�N���R�[�h2
                       ,iv_token_value2 => ir_get_data_rec.year_month           -- �L���N��
                       ,iv_token_name3  => cv_tkn_errmsg                        -- �g�[�N���R�[�h6
                       ,iv_token_value3 => SQLERRM                              -- SQL�G���[���b�Z�[�W
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
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
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
  END create_csv_rec;
--
  /**********************************************************************************
   * Procedure Name   : close_csv_file
   * Description      : CSV�t�@�C���N���[�Y���� (A-7)
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
--##################  �Œ�X�e�[�^�X�������� START   ###################
    ov_retcode := cv_status_normal;
--###########################  �Œ蕔 END   ############################
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
      ,buff   => cv_debug_msg5   || CHR(10)   ||
                 cv_debug_msg_fnm || iv_csv_nm || CHR(10) ||
                 ''
    );
    EXCEPTION
      WHEN UTL_FILE.WRITE_ERROR          OR     -- �I�y���[�e�B���O�V�X�e���G���[
           UTL_FILE.INVALID_FILEHANDLE   THEN   -- �t�@�C���E�n���h�������G���[
        -- �G���[���b�Z�[�W�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_04             --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_csv_loc               --�g�[�N���R�[�h1
                      ,iv_token_value1 => iv_csv_dir                   --�g�[�N���l1
                      ,iv_token_name2  => cv_tkn_csv_fnm               --�g�[�N���R�[�h1
                      ,iv_token_value2 => iv_csv_nm                    --�g�[�N���l1
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE file_err_expt;
    END;
  EXCEPTION
    -- *** �t�@�C��������O�n���h�� ***
    WHEN file_err_expt THEN
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
        ,buff   => cv_prg_name       || cv_debug_msg_err1 ||
                   cv_debug_msg_fcls || CHR(10) ||
                   ''
      );
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
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
       ,buff   => cv_prg_name       || cv_debug_msg_err2 ||
                  cv_debug_msg_fcls || CHR(10) ||
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
        ,buff   => cv_prg_name       || cv_debug_msg_err3 ||
                   cv_debug_msg_fcls || CHR(10)  ||
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
        ,buff   => cv_prg_name       || cv_debug_msg_err4 ||
                   cv_debug_msg_fcls || CHR(10) ||
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
     iv_value            IN         VARCHAR2   -- �p�����[�^������
    ,ov_errbuf           OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #

  )
  IS
        -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'submain';     -- �v���O������
    cv_lookup_type          CONSTANT VARCHAR2(30)    := 'XXCSO_ASN_HOUMON_KUBUN';
    cv_flag_y               CONSTANT VARCHAR2(1)     := 'Y';
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
    cn_max_meaning NUMBER := 30;
    cn_number_one  NUMBER := 1;
    -- *** ���[�J���ϐ� ***
    lv_work VARCHAR2(1000);
    -- OUT�p�����[�^�i�[�p
    lv_csv_dir             VARCHAR2(2000); -- CSV�t�@�C���o�͐�
    lv_csv_nm              VARCHAR2(2000); -- CSV�t�@�C����
    lb_fopn_retcd          BOOLEAN;        -- �t�@�C���I�[�v���m�F�߂�l�i�[
    lv_err_rec_info        VARCHAR2(5000); -- �f�[�^���ړ��e���b�Z�[�W�o�͗p
    ld_process_date_next   DATE;           -- �f�[�^���ړ��e���b�Z�[�W�o�͗p
    lv_process_date_next   VARCHAR2(6);    -- �f�[�^�i�[�p
    lv_process_date_next_1 VARCHAR2(6);    -- �f�[�^�i�[�p
    lv_value               VARCHAR2(8);    -- �p�����[�^������
    ld_date_next_1         DATE;           -- �p�����[�^�����������̗���
    -- ���b�Z�[�W�o�͗p
    lv_msg               VARCHAR2(2000);
-- *** ���[�J���E�J�[�\�� ***
    CURSOR flvv_data_cur
    IS
      SELECT flvv.lookup_code         lookup_code              -- �K��敪
            ,flvv.meaning             meaning                  -- �K����e
            ,lv_process_date_next     year_month               -- �L���N��
            ,flvv.last_update_date    last_update_date         -- �ŏI�X�V��
      FROM   fnd_lookup_values_vl     flvv
      WHERE  flvv.lookup_type = cv_lookup_type
        AND  ld_process_date_next BETWEEN
             TRUNC(flvv.start_date_active) AND
             TRUNC(NVL(flvv.end_date_active,ld_process_date_next))
        AND  flvv.enabled_flag = cv_flag_y
        AND  flvv.attribute2 = cv_flag_y
      UNION
      SELECT flvv.lookup_code         lookup_code              -- �K��敪
            ,flvv.meaning             meaning                  -- �K����e
            ,lv_process_date_next_1   year_month               -- �L���N��
            ,flvv.last_update_date    last_update_date         -- �ŏI�X�V��
      FROM   fnd_lookup_values_vl flvv
      WHERE  flvv.lookup_type = cv_lookup_type
        AND  ld_date_next_1 BETWEEN
             TRUNC(flvv.start_date_active) AND
             TRUNC(NVL(flvv.end_date_active,ld_date_next_1))
        AND  flvv.enabled_flag = cv_flag_y
        AND  flvv.attribute2 = cv_flag_y
      ORDER BY year_month,lookup_code;                    -- �K��敪
--
    -- *** ���[�J���E���R�[�h ***
    l_flvv_data_rec   flvv_data_cur%ROWTYPE;
    l_get_data_rec    g_get_data_rec;
    -- *** ���[�J����O ***
    no_data_expt       EXCEPTION;

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
    gn_target_cnt         := 0;
    gn_normal_cnt         := 0;
    gn_error_cnt          := 0;
    gn_warn_cnt           := 0;
    lv_value              := iv_value;
--
  -- ========================================
  -- A-1.�������� 
  -- ========================================
    init(
      iv_process_date  => lv_value            -- ���͂��ꂽ�p�����[�^������
     ,ov_errbuf        => lv_errbuf           -- �G���[�E���b�Z�[�W            --# �Œ� #
     ,ov_retcode       => lv_retcode          -- ���^�[���E�R�[�h              --# �Œ� #
     ,ov_errmsg        => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
  --
  -- ======================================
  -- A-2.�v���t�@�C���l�擾 
  -- ========================================
    get_profile_info(
       ov_csv_dir     => lv_csv_dir     -- CSV�t�@�C���o�͐�
      ,ov_csv_nm      => lv_csv_nm      -- CSV�t�@�C����
      ,ov_errbuf      => lv_errbuf      -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode     => lv_retcode     -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg      => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    -- =================================================
    -- A-3.CSV�t�@�C���I�[�v��
    -- =================================================
    open_csv_file(
       iv_csv_dir   => lv_csv_dir   -- CSV�t�@�C���o�͐�
      ,iv_csv_nm    => lv_csv_nm    -- CSV�t�@�C����
      ,ov_errbuf    => lv_errbuf    -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode   => lv_retcode   -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg    => lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    -- =================================================
    -- A-4.�Ώۃf�[�^�擾����
    -- =================================================
    ld_process_date_next   := gd_process_date + 1;
    lv_process_date_next   := TO_CHAR(ld_process_date_next,'YYYYMM');
    lv_process_date_next_1 := TO_CHAR(ADD_MONTHS(ld_process_date_next,1),'YYYYMM');
    ld_date_next_1        := TO_DATE(TO_CHAR(ADD_MONTHS(ld_process_date_next,1),'YYYYMM') || '01','YYYYMMDD');
      --�J�[�\���I�[�v��
      OPEN flvv_data_cur;
      <<get_data_loop>>
      LOOP 
          FETCH flvv_data_cur INTO l_flvv_data_rec;
          --�����Ώی����i�[
          gn_target_cnt := flvv_data_cur%ROWCOUNT;
          EXIT WHEN flvv_data_cur%NOTFOUND
          OR  flvv_data_cur%ROWCOUNT = 0;
          -- ���R�[�h�ϐ�������
          l_get_data_rec := NULL;
          -- �擾�f�[�^���i�[
          l_get_data_rec.lookup_code              := l_flvv_data_rec.lookup_code;              -- ��ЃR�[�h
          l_get_data_rec.meaning                  := l_flvv_data_rec.meaning;                  -- �K����e
          l_get_data_rec.last_update_date         := l_flvv_data_rec.last_update_date;         -- �N��
          l_get_data_rec.year_month               := l_flvv_data_rec.year_month;
          -- �K����e��30�o�C�g�ȓ��ɕҏW
          lv_work := NULL;
          --
          FOR i IN cn_number_one..LENGTH(l_get_data_rec.meaning) LOOP
            -- 1����������
            lv_work := lv_work || SUBSTR(l_get_data_rec.meaning, i, cn_number_one);
            --
            IF LENGTHB(lv_work) > cn_max_meaning THEN
              -- �K����e��30�o�C�g�𒴂����ꍇ
              l_get_data_rec.meaning := SUBSTRB(lv_work, cn_number_one, cn_max_meaning - cn_number_one);
              EXIT;
              --
            ELSIF LENGTHB(lv_work) = cn_max_meaning THEN
              -- �K����e��30�o�C�g�̏ꍇ
              l_get_data_rec.meaning := lv_work;
              EXIT;
              --
            END IF;
            --
          END LOOP;
/*          -- ���o�������ڂ��J���}��؂�ŕ����A�����ă��O�ɏo�͂���p
          fnd_file.put_line(
            which  => FND_FILE.LOG
           ,buff   => cv_debug_msg6 || l_get_data_rec.lookup_code || CHR(10) ||
                      cv_debug_msg7 || l_get_data_rec.meaning || CHR(10) ||
                      cv_debug_msg9 || l_get_data_rec.year_month || CHR(10) ||
                      cv_debug_msg8 || l_get_data_rec.last_update_date || CHR(10) ||
                      ''
          );
*/
          -- ========================================
          -- A-5.�K��\��f�[�^CSV�o�� 
          -- ========================================
          create_csv_rec(
            ir_get_data_rec    => l_get_data_rec      -- �擾�������[�N�e�[�u���f�[�^
           ,ov_errbuf          => lv_errbuf           -- �G���[�E���b�Z�[�W            --# �Œ� #
           ,ov_retcode         => lv_retcode          -- ���^�[���E�R�[�h              --# �Œ� #
           ,ov_errmsg          => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
          );
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
          -- ���팏���J�E���g�A�b�v
          gn_normal_cnt := gn_normal_cnt + 1;
--
      END LOOP get_data_loop;
      -- �J�[�\���N���[�Y
    CLOSE flvv_data_cur;
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
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
  EXCEPTION
    -- *** �����Ώۃf�[�^0����O�n���h�� ***
    WHEN no_data_expt THEN
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
        ,buff   => cv_prg_name       || cv_debug_msg_err5 ||
                   cv_debug_msg_fcls || CHR(10) ||
                   ''
      );
      END IF;
--
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (flvv_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE flvv_data_cur;
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
        fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_prg_name    || cv_debug_msg_err5 ||
                   cv_debug_msg_err7 || CHR(10)  ||
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
        ,buff   => cv_prg_name       || cv_debug_msg_err6 ||
                   cv_debug_msg_fcls || CHR(10) ||
                   ''
      );
      END IF;
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (flvv_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE flvv_data_cur;
        fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_prg_name    || cv_debug_msg_err6 ||
                   cv_debug_msg_err7 || CHR(10) ||
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
        ,buff   => cv_prg_name       || cv_debug_msg_err3 ||
                   cv_debug_msg_fcls || CHR(10) ||
                   ''
      );
      END IF;
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (flvv_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE flvv_data_cur;
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_prg_name    || cv_debug_msg_err3 ||
                   cv_debug_msg_err7 || CHR(10) ||
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
        ,buff   => cv_prg_name       || cv_debug_msg_err4 ||
                   cv_debug_msg_fcls || CHR(10) ||
                   ''
      );
      END IF;
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (flvv_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE flvv_data_cur;
      -- *** DEBUG_LOG ***
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_prg_name    || cv_debug_msg_err4 ||
                   cv_debug_msg_err7 || CHR(10) ||
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
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
     errbuf        OUT NOCOPY VARCHAR2    -- �G���[�E���b�Z�[�W  --# �Œ� #
    ,retcode       OUT NOCOPY VARCHAR2    -- ���^�[���E�R�[�h    --# �Œ� #
    ,iv_value      IN         VARCHAR2    -- �p�����[�^������
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
    lv_value           VARCHAR2(8);     -- �p�����[�^������
--
  BEGIN
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
    lv_value := iv_value;
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       iv_value     => lv_value           -- �p�����[�^������
      ,ov_errbuf    => lv_errbuf          -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode   => lv_retcode         -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg    => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #

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

    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      retcode := cv_status_error;
      ROLLBACK;
      -- *** DEBUG_LOG ***
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
END XXCSO014A07C;
/
