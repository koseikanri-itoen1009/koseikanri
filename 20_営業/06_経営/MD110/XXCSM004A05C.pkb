CREATE OR REPLACE PACKAGE BODY XXCSM004A05C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM004A05C(body)
 * Description      : ���i�|�C���g�E�V�K�l���|�C���g���n�V�X�e��I/F
 * MD.050           : ���i�|�C���g�E�V�K�l���|�C���g���n�V�X�e��I/F MD050_CSM_004_A05
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                                  ��������(A-1)
 *  open_csv_file                         �t�@�C���I�[�v������(A-2)
 *  create_csv_rec                        ���i�|�C���g�E�V�K�l���|�C���g�f�[�^��������(A-4)
 *  close_csv_file                        ���i�|�C���g�E�V�K�l���|�C���gI/F�t�@�C���N���[�Y����(A-5)
 *  submain                               ���C�������v���V�[�W��
 *  main                                  �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/05    1.0   S.Son            �V�K�쐬
 *  2009/07/01    1.1   T.Tsukino        �mSCS��Q�Ǘ��ԍ�0000256�n�Ή�
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
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;                 --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                            --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;                 --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                            --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;                --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id;         --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;            --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id;         --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                            --PROGRAM_UPDATE_DATE
  --
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
  cv_msg_comma              CONSTANT VARCHAR2(1) := ',';
  cv_msg_wquot              CONSTANT VARCHAR2(1) := '"';
  --
  cv_xxcsm                  CONSTANT VARCHAR2(100) := 'XXCSM'; 
--//+ADD START 2009/07/01 0000256 T.Tsukino
  cv_xxccp                  CONSTANT VARCHAR2(5)   := 'XXCCP';           -- ���ʊ֐��A�v���P�[�V����ID
--//+ADD START 2009/07/01 0000256 T.Tsukino
  --���b�Z�[�W�[�R�[�h
  cv_msg_00111              CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00111';       --�z��O�G���[���b�Z�[�W
  cv_msg_90008              CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90008';       --���̓p�����[�^�������b�Z�[�W
  cv_msg_00084              CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00084';       --�C���^�[�t�F�[�X�t�@�C�������b�Z�[�W
  cv_chk_err_00031          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00031';       --������s�p�v���t�@�C���擾�G���[���b�Z�[�W
  cv_chk_err_00001          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00001';       --�t�@�C�����݃`�F�b�N�G���[���b�Z�[�W
  cv_chk_err_00002          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00002';       --�t�@�C���I�[�v���G���[���b�Z�[�W
  cv_chk_err_00003          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00003';       --�t�@�C���N���[�Y�G���[���b�Z�[�W
  cv_chk_err_00019          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00019';       --���n�V�X�e���A�g�Ώۖ����G���[���b�Z�[�W
  --�g�[�N��
  cv_tkn_prof               CONSTANT VARCHAR2(100) := 'PROF_NAME';               --�J�X�^���E�v���t�@�C���E�I�v�V�����̉p��
  cv_tkn_file               CONSTANT VARCHAR2(100) := 'FILE_NAME';               --�t�@�C����
  cv_tkn_dir                CONSTANT VARCHAR2(100) := 'DIRECTORY';               --�f�B���N�g��
  cv_tkn_sql_cd             CONSTANT VARCHAR2(100) := 'SQL_CODE';                --�I���N���G���[�R�[�h
  --
  cv_app_short_name         CONSTANT VARCHAR2(2)   := 'AR';                      --�A�v���P�[�V�����Z�k��
  cv_mode_w                 CONSTANT VARCHAR2(1)   := 'W';                       --����
  cn_max_size               CONSTANT NUMBER        := 2047;                      -- 2047�o�C�g
  cv_status_open            CONSTANT VARCHAR2(1)   := 'O';                       --�X�e�[�^�X(�I�[�v��)
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
  gn_seq_no        NUMBER;                    -- �o�͏�
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
  file_err_expt          EXCEPTION;              --�t�@�C���I�[�v���G���[
  no_data_expt           EXCEPTION;              --���n�V�X�e���A�g�Ώۖ����G���[
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                         CONSTANT VARCHAR2(100) := 'XXCSM004A05C';                 -- �p�b�P�[�W��
  cv_file_dir_profile                 CONSTANT VARCHAR2(100) := 'XXCSM1_INFOSYS_FILE_DIR';      --���n�f�[�^�t�@�C���쐬�f�B���N�g��
  cv_file_name_profile                CONSTANT VARCHAR2(100) := 'XXCSM1_POINT_FILE_NAME';       --���i�|�C���g�E�V�K�l���|�C���g�f�[�^�t�@�C����
  cv_bks_id_profile                   CONSTANT VARCHAR2(100) := 'GL_SET_OF_BKS_ID';             --��v����ID
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  gv_file_dir          VARCHAR2(100);            --���n�f�[�^�t�@�C���쐬�f�B���N�g��
  gv_file_name         VARCHAR2(100);            --���i�|�C���g�A�V�K�l���|�C���g�f�[�^�t�@�C����
  gv_bks_id            VARCHAR2(100);            --��v����ID
  gv_app_id            VARCHAR2(100);            --�A�v���P�[�V����ID
  gf_file_hand         UTL_FILE.FILE_TYPE;
  gd_sysdate           DATE;                     --�V�X�e�����t

--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf        OUT NOCOPY VARCHAR2,       -- �G���[�E���b�Z�[�W
    ov_retcode       OUT NOCOPY VARCHAR2,       -- ���^�[���E�R�[�h
    ov_errmsg        OUT NOCOPY VARCHAR2)       -- ���[�U�[�E�G���[�E���b�Z�[�W 
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'init';            -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf         VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode        VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg         VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_tkn_value      VARCHAR2(4000);  --�g�[�N���l
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_no_pram_msg       VARCHAR2(100);         --���̓p�����[�^�������b�Z�[�W
    file_chk             BOOLEAN;               --�t�@�C�����݃`�F�b�N����
    file_size            NUMBER;                --�t�@�C���T�C�Y
    block_size           NUMBER;                --�u���b�N�T�C�Y
--
    -- *** ���[�J���E�J�[�\�� ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- *** ���[�J���ϐ������� ***

    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--�@���̓p�����[�^���������b�Z�[�W�o��
    --�Ώ۔N�x
    lv_no_pram_msg := xxccp_common_pkg.get_msg(
--//+UPD START 2009/07/01 0000256 T.Tsukino
--                                             iv_application  => cv_xxcsm
                                               iv_application  => cv_xxccp
--//+UPD START 2009/07/01 0000256 T.Tsukino
                                            ,iv_name         => cv_msg_90008
                                            );
    FND_FILE.PUT_LINE(FND_FILE.LOG,lv_no_pram_msg);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_no_pram_msg);
    
--
--�A �v���t�@�C���l�擾
    --���n�f�[�^�t�@�C���쐬�f�B���N�g��
    gv_file_dir := FND_PROFILE.VALUE(cv_file_dir_profile);
    
    IF gv_file_dir IS NULL THEN
        lv_tkn_value := cv_file_dir_profile;
        lv_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application  => cv_xxcsm
                                             ,iv_name         => cv_chk_err_00031
                                             ,iv_token_name1  => cv_tkn_prof
                                             ,iv_token_value1 => lv_tkn_value
                                             );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END IF;
--
    --���i�|�C���g�A�V�K�l���|�C���g�f�[�^�t�@�C����
    gv_file_name := FND_PROFILE.VALUE(cv_file_name_profile);
    IF gv_file_name IS NULL THEN
        lv_tkn_value := cv_file_name_profile;
        lv_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application  => cv_xxcsm
                                             ,iv_name         => cv_chk_err_00031
                                             ,iv_token_name1  => cv_tkn_prof
                                             ,iv_token_value1 => lv_tkn_value
                                             );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    ELSE
      lv_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application  => cv_xxcsm
                                             ,iv_name         => cv_msg_00084
                                             ,iv_token_name1  => cv_tkn_file
                                             ,iv_token_value1 => gv_file_name
                                             );
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
    END IF;
--
    --��v����ID
    gv_bks_id := FND_PROFILE.VALUE(cv_bks_id_profile);
    IF gv_bks_id IS NULL THEN
        lv_tkn_value := cv_bks_id_profile;
        lv_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application  => cv_xxcsm
                                             ,iv_name         => cv_chk_err_00031
                                             ,iv_token_name1  => cv_tkn_prof
                                             ,iv_token_value1 => lv_tkn_value
                                             );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END IF;
--
--�B �t�@�C���쐬�̈�ɓ����̃t�@�C�������݃`���b�N
    UTL_FILE.FGETATTR(gv_file_dir, gv_file_name, file_chk, file_size, block_size);
    IF file_chk THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application  => cv_xxcsm
                                             ,iv_name         => cv_chk_err_00001
                                             ,iv_token_name1  => cv_tkn_dir
                                             ,iv_token_value1 => gv_file_dir
                                             ,iv_token_name2  => cv_tkn_file
                                             ,iv_token_value2 => gv_file_name
                                             );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END IF;
--�C �V�X�e�����t�擾
    gd_sysdate := SYSDATE;
--
--�D �A�v���P�[�V����ID���擾
    gv_app_id := xxccp_common_pkg.get_application(cv_app_short_name);
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /****************************************************************************
  * Procedure Name   : open_csv_file
  * Description      : �t�@�C���I�[�v������(A-2)
  ****************************************************************************/
  PROCEDURE open_csv_file (
       ov_errbuf     OUT NOCOPY VARCHAR2              -- ���ʁE�G���[�E���b�Z�[�W
      ,ov_retcode    OUT NOCOPY VARCHAR2              -- ���^�[���E�R�[�h
      ,ov_errmsg     OUT NOCOPY VARCHAR2)             -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS

--#####################  �Œ胍�[�J���ϐ��錾�� START   ###########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   #####################################
--
--  ===============================
--  �Œ胍�[�J���萔
--  ===============================
    cv_prg_name         CONSTANT VARCHAR2(100)   := 'open_csv_file'; -- �v���O������
--  ===============================
--  �Œ胍�[�J���ϐ�
--  ===============================
--
    lb_fopn_retcd     BOOLEAN;            --�t�@�C���I�[�v���m�F�߂�l�i�[
--  ===============================
--  ���[�J���E�J�[�\��
--  ===============================
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
  BEGIN
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
    BEGIN
      gf_file_hand := UTL_FILE.FOPEN(
                                   location     => gv_file_dir 
                                  ,filename     => gv_file_name 
                                  ,open_mode    => cv_mode_w 
                                  ,max_linesize => cn_max_size
                                  );
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application  => cv_xxcsm
                                             ,iv_name         => cv_chk_err_00002
                                             ,iv_token_name1  => cv_tkn_dir
                                             ,iv_token_value1 => gv_file_dir
                                             ,iv_token_name2  => cv_tkn_file
                                             ,iv_token_value2 => gv_file_name
                                             ,iv_token_name3  => cv_tkn_sql_cd
                                             ,iv_token_value3 => SQLERRM
                                             );
          lv_errbuf := lv_errmsg;
          RAISE file_err_expt;
    END;
--
  EXCEPTION
    -- *** �t�@�C���I�[�v���G���[ ***
    WHEN file_err_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF lb_fopn_retcd  THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file => gf_file_hand
        );
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--#################################  �Œ��O������  #############################

    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ###########################
--
  END open_csv_file;
--
  /****************************************************************************
  * Procedure Name   : create_csv_rec
  * Description      : ���i�|�C���g�E�V�K�l���|�C���g�f�[�^���o����(A-3)
  *                    ���i�|�C���g�E�V�K�l���|�C���g�f�[�^��������(A-4)
  ****************************************************************************/
  PROCEDURE create_csv_rec (
       ov_errbuf       OUT NOCOPY VARCHAR2              -- ���ʁE�G���[�E���b�Z�[�W
      ,ov_retcode      OUT NOCOPY VARCHAR2              -- ���^�[���E�R�[�h
      ,ov_errmsg       OUT NOCOPY VARCHAR2)             -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
--#####################  �Œ胍�[�J���ϐ��錾�� START   ###########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   #####################################
--
--  ===============================
--  �Œ胍�[�J���萔
--  ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'create_csv_rec';   -- �v���O������
    cv_company_cd        CONSTANT VARCHAR2(3)     := '001';              -- ��ЃR�[�h
--  ===============================
--  �Œ胍�[�J���ϐ�
--  ===============================
--
    ln_subject_year           NUMBER;                      --�Ώ۔N�x
    ln_year_month             NUMBER;                      --�N��
    lv_location_cd            VARCHAR2(4);                 --���_�R�[�h
    lv_employee_number        VARCHAR2(5);                 --�]�ƈ��R�[�h
    lv_data_kbn               VARCHAR2(1);                 --�|�C���g�敪
    lv_get_intro_kbn          VARCHAR2(1);                 --�l���E�Љ��
    lv_get_custom_date        VARCHAR2(8);                 --�l���N����
    lv_account_number         VARCHAR2(9);                 --�ڋq�R�[�h
    lv_business_low_type      VARCHAR2(2);                 --�Ƒ�
    lv_evaluration_kbn        VARCHAR2(1);                 --�V�K�]���Ώ�
    ln_point                  NUMBER;                      --�|�C���g
    lb_fopn_retcd             BOOLEAN;                     --�t�@�C���I�[�v���m�F�߂�l�i�[
    lv_data                   VARCHAR2(4000);
--  ===============================
--  ���[�J���E�J�[�\��
--  ===============================
    CURSOR point_date_cur
    IS
      SELECT  xncph.employee_number                                                        --�]�ƈ��R�[�h
             ,xncph.subject_year                                                           --�Ώ۔N�x
             ,xncph.year_month                                                             --�N��
             ,xncph.location_cd                                                            --���_�R�[�h
             ,DECODE(xncph.data_kbn,1,xncph.account_number,'0') account_number           --�ڋq�R�[�h
             ,xncph.data_kbn                                                               --�f�[�^�敪
             ,xncph.get_intro_kbn                                                          --�l���E�Љ�敪
             ,xncph.get_custom_date                                                        --�ڋq�l����
             ,xncph.business_low_type                                                      --�Ƒԁi�����ށj
             ,DECODE(xncph.data_kbn,1,xncph.evaluration_kbn,NULL) evaluration_kbn        --�V�K�]���Ώۋ敪
             ,xncph.point                                                                  --�|�C���g
      FROM    xxcsm_new_cust_point_hst   xncph                                             --�V�K�l���|�C���g�ڋq�ʗ����e�[�u��
             ,(
               SELECT  DISTINCT gps.period_year  period_year            --��v�N�x
               FROM    gl_period_statuses  gps                          --��v���ԃX�e�[�^�X�e�[�u��
               WHERE   gps.set_of_books_id = gv_bks_id                  --��v����ID
               AND     gps.application_id = gv_app_id                   --�A�v���P�[�V����ID
               AND     gps.closing_status = cv_status_open              --�X�e�[�^�X
              ) status_view                                             --��v���ԃX�e�[�^�X�r���[
      WHERE   xncph.subject_year = status_view.period_year
      ORDER BY  xncph.data_kbn                                          --�f�[�^�敪
               ,xncph.employee_number                                   --�]�ƈ��R�[�h
               ,xncph.year_month                                        --�N��
      ;
    point_date_cur_rec point_date_cur%ROWTYPE;
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
  BEGIN
--
    ov_retcode := cv_status_normal;
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
--
--###########################  �Œ蕔 END   ############################
    OPEN point_date_cur;
      <<point_date_loop>>
      LOOP
        FETCH point_date_cur INTO point_date_cur_rec;
      -- �����Ώی����i�[
        gn_target_cnt := point_date_cur%ROWCOUNT;
        EXIT WHEN point_date_cur%NOTFOUND
             OR point_date_cur%ROWCOUNT = 0;
        -- �擾�f�[�^���i�[
        ln_subject_year       :=  point_date_cur_rec.subject_year;                           --�Ώ۔N�x
        ln_year_month         :=  point_date_cur_rec.year_month;                             --�N��
        lv_location_cd        :=  point_date_cur_rec.location_cd;                            --���_�R�[�h
        lv_employee_number    :=  point_date_cur_rec.employee_number;                        --�]�ƈ��R�[�h
        lv_data_kbn           :=  TO_CHAR(point_date_cur_rec.data_kbn);                      --�|�C���g�敪
        lv_get_intro_kbn      :=  point_date_cur_rec.get_intro_kbn;                          --�l���E�Љ�敪
        lv_get_custom_date    :=  TO_CHAR(point_date_cur_rec.get_custom_date,'YYYYMMDD');    --�l���N����
        lv_account_number     :=  point_date_cur_rec.account_number;                         --�ڋq�R�[�h
        lv_business_low_type  :=  point_date_cur_rec.business_low_type;                      --�Ƒ�
        lv_evaluration_kbn    :=  point_date_cur_rec.evaluration_kbn;                        --�V�K�]���Ώۋ�
        ln_point              :=  point_date_cur_rec.point;                                  --�|�C���g
        -- ========================================
        -- ���i�|�C���g�E�V�K�l���|�C���g�f�[�^�����ݏ���(A-4)
        -- ========================================
        lv_data := cv_msg_wquot||cv_company_cd||cv_msg_wquot||cv_msg_comma||                --��ЃR�[�h
                   ln_subject_year||cv_msg_comma||                                          --�Ώ۔N�x
                   ln_year_month||cv_msg_comma||                                            --�N��
                   cv_msg_wquot||lv_location_cd||cv_msg_wquot||cv_msg_comma||               --���_(����)�R�[�h
                   cv_msg_wquot||lv_employee_number||cv_msg_wquot||cv_msg_comma||           --�]�ƈ��R�[�h
                   cv_msg_wquot||lv_data_kbn||cv_msg_wquot||cv_msg_comma||                  --�|�C���g�敪
                   cv_msg_wquot||lv_get_intro_kbn||cv_msg_wquot||cv_msg_comma||             --�l���E�Љ�敪
                   lv_get_custom_date||cv_msg_comma||                                       --�l���N����
                   cv_msg_wquot||lv_account_number||cv_msg_wquot||cv_msg_comma||            --�ڋq�R�[�h
                   cv_msg_wquot||lv_business_low_type||cv_msg_wquot||cv_msg_comma||         --�Ƒ�
                   cv_msg_wquot||lv_evaluration_kbn||cv_msg_wquot||cv_msg_comma||           --�V�K�]���Ώۋ敪
                   ln_point||cv_msg_comma||                                                 --�|�C���g
                   TO_CHAR(gd_sysdate,'YYYYMMDDHH24MISS');                                  --�A�g����
        -- �f�[�^�o��
        UTL_FILE.PUT_LINE(
                          file   => gf_file_hand
                         ,buffer => lv_data
                         );
        
        -- ���팏���J�E���g�A�b�v
        gn_normal_cnt := gn_normal_cnt + 1;
      END LOOP point_date_loop;
    CLOSE point_date_cur;
    -- �����Ώی�����0���̏ꍇ
    IF (gn_target_cnt = 0) THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcsm                                --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_chk_err_00019                        --���b�Z�[�W�R�[�h
                   );
      lv_errbuf := lv_errmsg;
      RAISE no_data_expt;
    END IF;
--
  EXCEPTION
      -- *** �����Ώۃf�[�^0����O�n���h�� ***
    WHEN no_data_expt THEN
      -- �G���[�����J�E���g
      gn_error_cnt := gn_error_cnt + 1;
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF lb_fopn_retcd  THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (point_date_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE point_date_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--#################################  �Œ��O������  #############################

    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF lb_fopn_retcd  THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (point_date_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE point_date_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF lb_fopn_retcd  THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (point_date_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE point_date_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF lb_fopn_retcd  THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (point_date_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE point_date_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ###########################
--
  END create_csv_rec;
--
  /****************************************************************************
  * Procedure Name   : close_csv_file
  * Description      : �t�@�C���N���[�Y����(A-5)
  ****************************************************************************/
  PROCEDURE close_csv_file (
       ov_errbuf     OUT NOCOPY VARCHAR2              -- ���ʁE�G���[�E���b�Z�[�W
      ,ov_retcode    OUT NOCOPY VARCHAR2              -- ���^�[���E�R�[�h
      ,ov_errmsg     OUT NOCOPY VARCHAR2)             -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS

--#####################  �Œ胍�[�J���ϐ��錾�� START   ###########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   #####################################
--
--  ===============================
--  �Œ胍�[�J���萔
--  ===============================
    cv_prg_name         CONSTANT VARCHAR2(100)   := 'close_csv_file'; -- �v���O������
--  ===============================
--  �Œ胍�[�J���ϐ�
--  ===============================
--
    lb_fopn_retcd     BOOLEAN;            --�t�@�C���I�[�v���m�F�߂�l�i�[
--  ===============================
--  ���[�J���E�J�[�\��
--  ===============================
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
  BEGIN
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
    BEGIN
      UTL_FILE.FCLOSE(
        file => gf_file_hand
      );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_xxcsm
                                           ,iv_name         => cv_chk_err_00003
                                           ,iv_token_name1  => cv_tkn_dir
                                           ,iv_token_value1 => gv_file_dir
                                           ,iv_token_name2  => cv_tkn_file
                                           ,iv_token_value2 => gv_file_name
                                           ,iv_token_name3  => cv_tkn_sql_cd
                                           ,iv_token_value3 => SQLERRM
                                           );
        lv_errbuf := lv_errmsg;
        RAISE file_err_expt;
    END;
--
  EXCEPTION
    -- *** �t�@�C���I�[�v���G���[ ***
    WHEN file_err_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF lb_fopn_retcd  THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file => gf_file_hand
        );
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--#################################  �Œ��O������  #############################

    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF lb_fopn_retcd  THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file => gf_file_hand
        );
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF lb_fopn_retcd  THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file => gf_file_hand
        );
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF lb_fopn_retcd  THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file => gf_file_hand
        );
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ###########################
--
  END close_csv_file;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf        OUT NOCOPY VARCHAR2,     --  �G���[�E���b�Z�[�W
    ov_retcode       OUT NOCOPY VARCHAR2,     --  ���^�[���E�R�[�h
    ov_errmsg        OUT NOCOPY VARCHAR2)     --  ���[�U�[�E�G���[�E���b�Z�[�W 
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'submain';          -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf                 VARCHAR2(5000);                   --�G���[�E���b�Z�[�W
    lv_retcode                VARCHAR2(1);                      --���^�[���E�R�[�h
    lv_errmsg                 VARCHAR2(5000);                   --���[�U�[�E�G���[�E���b�Z�[�W
--
--  ===============================
--  ���[�J���E�J�[�\��
--  ===============================
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
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt  := 0;
    gn_normal_cnt  := 0;
    gn_error_cnt   := 0;
    gn_warn_cnt    := 0;
    -- ���[�J���ϐ�������
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- ��������(A-1)
    -- ===============================
    init(
          lv_errbuf         -- �G���[�E���b�Z�[�W
         ,lv_retcode        -- ���^�[���E�R�[�h
         ,lv_errmsg );
    -- ��O����
    IF (lv_retcode <> cv_status_normal) THEN
      --(�G���[����)
      gn_error_cnt := gn_error_cnt +1;
      RAISE global_process_expt;
    END IF;
    -- ===============================
    -- �t�@�C���I�[�v������(A-2)
    -- ===============================
    open_csv_file(
       ov_errbuf    => lv_errbuf                                                                    -- �G���[�E���b�Z�[�W
      ,ov_retcode   => lv_retcode                                                                   -- ���^�[���E�R�[�h
      ,ov_errmsg    => lv_errmsg                                                                    -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    -- =======================================================
    -- ���i�|�C���g�E�V�K�l���|�C���g�f�[�^���o����(A-3)
    -- ���i�|�C���g�E�V�K�l���|�C���g�f�[�^��������(A-4)
    -- =======================================================
    create_csv_rec(
       ov_errbuf    => lv_errbuf                                                                    -- �G���[�E���b�Z�[�W
      ,ov_retcode   => lv_retcode                                                                   -- ���^�[���E�R�[�h
      ,ov_errmsg    => lv_errmsg                                                                    -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ==========================================================
    -- ���i�|�C���g�E�V�K�l���|�C���gI/F�t�@�C���N���[�Y����(A-5)
    -- ==========================================================
    close_csv_file(
       ov_errbuf    => lv_errbuf                                                                    -- �G���[�E���b�Z�[�W
      ,ov_retcode   => lv_retcode                                                                   -- ���^�[���E�R�[�h
      ,ov_errmsg    => lv_errmsg                                                                    -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
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
    errbuf                  OUT  NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W
    retcode                 OUT  NOCOPY VARCHAR2      --   ���^�[���E�R�[�h
  )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
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

    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       lv_errbuf        -- �G���[�E���b�Z�[�W 
      ,lv_retcode       -- ���^�[���E�R�[�h  
      ,lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W 
    );
--
    IF lv_retcode = cv_status_error THEN
      IF lv_errmsg IS NULL THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                                                 iv_application  => cv_xxcsm
                                                ,iv_name         => cv_msg_00111
                                               );
      END IF;
      
    --�G���[�o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff => lv_errbuf --�G���[���b�Z�[�W
      );
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt := 1;
      gn_warn_cnt := 0;
    END IF;
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
    --�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    fnd_file.put_line(
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
    fnd_file.put_line(
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
END XXCSM004A05C;
/
