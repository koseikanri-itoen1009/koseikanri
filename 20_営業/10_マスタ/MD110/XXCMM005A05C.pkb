create or replace PACKAGE BODY XXCMM005A05C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM005A05C(body)
 * Description      : ���_�}�X�^IF�o�́i���[�N�t���[�j
 * MD.050           : ���_�}�X�^IF�o�́i���[�N�t���[�j MD050_CMM_005_A05
 * Version          : 1.3
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  open_csv_file          �t�@�C���I�[�v������(A-2)
 *  chk_count_top_dept     �ŏ�ʕ��匏���擾(A-3)
 *  get_base_data          �����Ώۃf�[�^���o(A-4)
 *  output_csv_data        ���o���o��(A-5)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/02/06    1.0   Masayuki.Sano    �V�K�쐬
 *  2009/02/26    1.1   Masayuki.Sano    �����e�X�g����s���Ή�
 *  2009/02/27    1.2   Masayuki.Sano    �����e�X�g����s���Ή�(�o�͕s��)
 *  2009/03/09    1.3   Yuuki.Nakamura   �t�@�C���o�͐�v���t�@�C�����̕ύX
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
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         -- CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    -- PROGRAM_UPDATE_DATE
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
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name         CONSTANT VARCHAR2(100) := 'XXCMM005A05C';               -- �p�b�P�[�W��
  -- �� �A�v���P�[�V�����Z�k��
  cv_app_name_xxcmm   CONSTANT VARCHAR2(30)  := 'XXCMM';                      -- �}�X�^
  cv_app_name_xxccp   CONSTANT VARCHAR2(30)  := 'XXCCP';                      -- ���ʁEIF
  -- �� �J�X�^���E�v���t�@�C���E�I�v�V����
--ver.1.3 2009/03/09 mod by Yuuki.Nakamura start
--  cv_pro_out_file_dir CONSTANT VARCHAR2(50) := 'XXCMM1_005A05_OUT_FILE_DIR';  -- �A�g�pCSV�t�@�C���o�͐�
  cv_pro_out_file_dir CONSTANT VARCHAR2(50) := 'XXCMM1_WORKFLOW_OUT_DIR';     -- �A�g�pCSV�t�@�C���o�͐�
--ver.1.3 2009/03/09 mod by Yuuki.Nakamura end
  cv_pro_out_file_fil CONSTANT VARCHAR2(50) := 'XXCMM1_005A05_OUT_FILE_FIL';  -- �A�g�pCSV�t�@�C����
  -- �� ���b�Z�[�W�E�R�[�h(�G���[)
  cv_msg_00002        CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00002';            -- �v���t�@�C���擾�G���[
  cv_msg_00010        CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00010';            -- CSV�t�@�C�����݃`�F�b�N
  cv_msg_00003        CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00003';            -- �t�@�C���p�X�s���G���[
  cv_msg_00500        CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00500';            -- ����K�w�G���[
  cv_msg_00001        CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00001';            -- �Ώۃf�[�^����
  cv_msg_00009        CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00009';            -- CSV�f�[�^�o�̓G���[
-- 2009/02/26 ADD by M.Sano Start
  cv_msg_91003        CONSTANT VARCHAR2(20) := 'APP-XXCCP1-91003';            -- �V�X�e���G���[
-- 2009/02/26 ADD by M.Sano End
  -- �� ���b�Z�[�W�E�R�[�h(�o��)
  cv_msg_90008        CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90008';            -- �R���J�����g���̓p�����[�^�Ȃ�
  cv_msg_05132        CONSTANT VARCHAR2(20) := 'APP-XXCCP1-05102';            -- �t�@�C�����o�̓��b�Z�[�W
  cv_msg_90000        CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90000';            -- �Ώی������b�Z�[�W
  cv_msg_90001        CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90001';            -- �����������b�Z�[�W
  cv_msg_90002        CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90002';            -- �G���[�������b�Z�[�W
  cv_normal_msg       CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90004';            -- ����I�����b�Z�[�W
  cv_error_msg        CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90006';            -- �G���[�I���S���[���o�b�N
  -- �� �g�[�N��(�L�[)
  cv_tok_filename     CONSTANT VARCHAR2(15) := 'FILE_NAME';                   -- �t�@�C����
  cv_tok_ng_profile   CONSTANT VARCHAR2(15) := 'NG_PROFILE';
  cv_tok_ffv_set_name CONSTANT VARCHAR2(15) := 'FFV_SET_NAME';                -- �l�Z�b�g��
  cv_tok_ng_word      CONSTANT VARCHAR2(15) := 'NG_WORD';
  cv_tok_ng_data      CONSTANT VARCHAR2(15) := 'NG_DATA';
  cv_tok_count        CONSTANT VARCHAR2(15) := 'COUNT';
  -- �� �g�[�N��(�l)
  cv_tvl_out_file_dir CONSTANT VARCHAR2(50) := '���_�}�X�^�i���[�N�t���[�j�A�g�pCSV�t�@�C���o�͐�';
  cv_tvl_out_file_fil CONSTANT VARCHAR2(50) := '���_�}�X�^�i���[�N�t���[�j�A�g�pCSV�t�@�C����';
  cv_tvl_base_code    CONSTANT VARCHAR2(20) := '���_�R�[�h';
  cv_tvl_ffv_set_name CONSTANT VARCHAR2(20) := 'XX03_DEPARTMENT';
-- 
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ���_�}�X�^IF�o��(���[�N�t���[)���C�A�E�g
  TYPE output_data_rtype IS RECORD
  (
     dpt6_cd                 xxcmm_hierarchy_dept_v.dpt6_cd%TYPE          -- ����R�[�h
    ,dpt6_name               xxcmm_hierarchy_dept_v.dpt6_name%TYPE        -- ���_������
    ,dpt6_abbreviate         xxcmm_hierarchy_dept_v.dpt6_abbreviate%TYPE  -- ���_����
    ,dpt6_old_cd             xxcmm_hierarchy_dept_v.dpt6_old_cd%TYPE      -- ���{���R�[�h
    ,dpt6_sort_num           xxcmm_hierarchy_dept_v.dpt6_sort_num%TYPE    -- ���_���я�
    ,attribute4              fnd_flex_values.attribute4%TYPE              -- ���_�������i���{���R�[�h�j
    ,attribute6              fnd_flex_values.attribute6%TYPE              -- ���_���я��i���{���R�[�h�j
    ,creation_date           xxcmm_hierarchy_dept_v.creation_date%TYPE    -- �쐬��
    ,dpt3_cd                 xxcmm_hierarchy_dept_v.dpt3_cd%TYPE          -- ����R�[�h(3�K�w��)
    ,dpt3_name               xxcmm_hierarchy_dept_v.dpt3_name%TYPE        -- ���_������(3�K�w��)
    ,customer_name_phonetic  ar_customers_v.customer_name_phonetic%TYPE   -- �ڋq�J�i��
    ,address_line            VARCHAR2(100)                                -- �Z��
    ,zip                     xxcmn_parties.zip%TYPE                       -- �X�֔ԍ�
    ,phone                   xxcmn_parties.phone%TYPE                     -- �d�b�ԍ�
    ,fax                     xxcmn_parties.fax%TYPE                       -- FAX�ԍ�
  );
--
  -- ���_�}�X�^IF�o��(���[�N�t���[)���C�A�E�g �e�[�u���^�C�v
  TYPE output_data_ttype IS TABLE OF output_data_rtype INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_csv_file_dir       fnd_profile_option_values.profile_option_value%TYPE;
                                        -- ���_�}�X�^IF�o�́i���[�N�t���[�j�A�g�pCSV�t�@�C���o�͐�
  gv_csv_file_name      fnd_profile_option_values.profile_option_value%TYPE;  
                                        -- ���_�}�X�^IF�o�́i���[�N�t���[�j�A�g�pCSV�t�@�C����
  gf_file_handler       UTL_FILE.FILE_TYPE;                                   
                                        -- CSV�t�@�C���o�͗p�n���h��
  gt_csv_out_tab        output_data_ttype;                                   
                                        -- ���_�}�X�^IF�o�́i���[�N�t���[�j�f�[�^
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf             OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- *** ���[�J���ϐ� ***
    lb_file_exists   BOOLEAN;        -- �t�@�C�����ݔ��f
    ln_file_length   NUMBER(30);     -- �t�@�C���̕�����
    lbi_block_size   BINARY_INTEGER; -- �u���b�N�T�C�Y
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    --�P�D�v���t�@�C���̎擾���s���܂��B
    --==============================================================
    -- ���_�}�X�^IF�o�́i���[�N�t���[�j�A�g�pCSV�t�@�C���o�͐���擾
    gv_csv_file_dir    := FND_PROFILE.VALUE(cv_pro_out_file_dir);
    -- ���_�}�X�^IF�o�́i���[�N�t���[�j�A�g�pCSV�t�@�C���o�͐�̎擾���e�`�F�b�N
    IF ( gv_csv_file_dir IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxcmm    -- �}�X�^
                     ,iv_name         => cv_msg_00002         -- �G���[  :�v���t�@�C���擾�G���[
                     ,iv_token_name1  => cv_tok_ng_profile    -- �g�[�N��:NG_PROFILE
                     ,iv_token_value1 => cv_tvl_out_file_dir  -- �l      :CSV�t�@�C���o�͐�
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ���_�}�X�^IF�o�́i���[�N�t���[�j�A�g�pCSV�t�@�C�������擾
    gv_csv_file_name    := FND_PROFILE.VALUE(cv_pro_out_file_fil);
    -- ���_�}�X�^IF�o�́i���[�N�t���[�j�A�g�pCSV�t�@�C�����̎擾���e�`�F�b�N
    IF ( gv_csv_file_name IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxcmm    -- �}�X�^
                     ,iv_name         => cv_msg_00002         -- �G���[  :�v���t�@�C���擾�G���[
                     ,iv_token_name1  => cv_tok_ng_profile    -- �g�[�N��:NG_PROFILE
                     ,iv_token_value1 => cv_tvl_out_file_fil  -- �l      :CSV�t�@�C����
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --�Q�DCSV�t�@�C�����݃`�F�b�N���s���܂��B
    --==============================================================
    -- �t�@�C�������擾
    UTL_FILE.FGETATTR(
         location     => gv_csv_file_dir
        ,filename     => gv_csv_file_name
        ,fexists      => lb_file_exists
        ,file_length  => ln_file_length
        ,block_size   => lbi_block_size
      );
    -- �t�@�C���d���`�F�b�N(�t�@�C�����݂̗L��)
    IF ( lb_file_exists ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxcmm    -- �}�X�^
                     ,iv_name         => cv_msg_00010         -- �G���[:CSV�t�@�C�����݃`�F�b�N
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- �}�X�^
                     ,iv_name         => cv_msg_91003         -- �G���[:�V�X�e���G���[
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- �}�X�^
                     ,iv_name         => cv_msg_91003         -- �G���[:�V�X�e���G���[
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : open_file
   * Description      : �t�@�C���I�[�v������(A-2)
   ***********************************************************************************/
  PROCEDURE open_csv_file(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'open_csv_file'; -- �v���O������
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
    cv_csv_mode_w CONSTANT VARCHAR2(1) := 'w';  -- �t�@�C���I�[�v�����[�h(�������݃��[�h)
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================================
    -- �I�[�v�����[�h'W'(�o��)�ŃI�[�v�����܂��B
    -- ===============================================
    BEGIN
      -- �t�@�C�����J��
      gf_file_handler := UTL_FILE.FOPEN(
                            location   => gv_csv_file_dir     -- �o�͐�
                           ,filename   => gv_csv_file_name    -- �t�@�C����
                           ,open_mode  => cv_csv_mode_w       -- �t�@�C���I�[�v�����[�h
                        );
    EXCEPTION
      WHEN UTL_FILE.INVALID_PATH THEN
        -- ���b�Z�[�W���擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name_xxcmm  -- �}�X�^
                       ,iv_name         => cv_msg_00003       -- �G���[:�t�@�C���p�X�s���G���[
                     );
        lv_errbuf := lv_errmsg;
        -- ��O���X���[
        RAISE global_api_expt;
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
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
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- �}�X�^
                     ,iv_name         => cv_msg_91003         -- �G���[:�V�X�e���G���[
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- �}�X�^
                     ,iv_name         => cv_msg_91003         -- �G���[:�V�X�e���G���[
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END open_csv_file;
--
  /**********************************************************************************
   * Procedure Name   : chk_count_top_dept
   * Description      : �ŏ�ʕ��匏���擾(A-3)
   ***********************************************************************************/
  PROCEDURE chk_count_top_dept(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_count_top_dept'; -- �v���O������
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
    ln_top_dept_cnt NUMBER;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    -- 1.�ŏ�ʕ���̌������擾���܂��B
    --==============================================================
    BEGIN
      SELECT COUNT(1)
      INTO   ln_top_dept_cnt
      FROM   fnd_flex_value_sets ffvs  -- �l�Z�b�g��`�}�X�^
            ,fnd_flex_values     ffvl  -- �l�Z�b�g�l��`�}�X�^
      WHERE  ffvs.flex_value_set_id = ffvl.flex_value_set_id
      AND    ffvl.enabled_flag = 'Y'
      AND    ffvl.summary_flag = 'Y'
      AND    ffvs.flex_value_set_name = 'XX03_DEPARTMENT'
      AND    xxccp_common_pkg2.get_process_date BETWEEN
                   NVL(ffvl.start_date_active, TO_DATE('19000101','YYYYMMDD'))
               AND NVL(ffvl.end_date_active, TO_DATE('99991231','YYYYMMDD'))
      AND    NOT EXISTS (
               SELECT 'X'
               FROM   fnd_flex_value_norm_hierarchy ffvh
               WHERE  ffvh.flex_value_set_id = ffvl.flex_value_set_id
               AND    ffvl.flex_value BETWEEN ffvh.child_flex_value_low
                                          AND ffvh.child_flex_value_high
             )
      ;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    -- 2�D�ŏ�ʕ��匏����1���ȊO�̏ꍇ�A����K�w�G���[
    --==============================================================
    IF ( ln_top_dept_cnt <> 1 ) THEN
      -- �ŏ�ʑw�̕��吔�ŃG���[���������ꍇ�A���ɊJ���Ă�t�@�C�����폜
      UTL_FILE.FREMOVE( location    => gv_csv_file_dir    -- �폜�Ώۂ�����f�B���N�g��
                       ,filename    => gv_csv_file_name   -- �폜�Ώۃt�@�C����
      );
      -- �G���[���b�Z�[�W���o�͌�A�ُ�I��
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxcmm        -- �}�X�^
                     ,iv_name         => cv_msg_00500             -- �G���[:����K�w�G���[
                     ,iv_token_name1  => cv_tok_ffv_set_name      -- �g�[�N��  :FFV_SET_NAME
                     ,iv_token_value1 => cv_tvl_ffv_set_name      -- �g�[�N���l:XX03_DEPARTMENT
                     ,iv_token_name2  => cv_tok_count             -- �g�[�N��  :COUNT
                     ,iv_token_value2 => TO_CHAR(ln_top_dept_cnt) -- �g�[�N���l:�ŏ�ʊK�w�̌���
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
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
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- �}�X�^
                     ,iv_name         => cv_msg_91003         -- �G���[:�V�X�e���G���[
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- �}�X�^
                     ,iv_name         => cv_msg_91003         -- �G���[:�V�X�e���G���[
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_count_top_dept;
--
  /**********************************************************************************
   * Procedure Name   : get_base_data
   * Description      : �����Ώۃf�[�^���o(A-4)
   ***********************************************************************************/
  PROCEDURE get_base_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_base_data'; -- �v���O������
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
    -- *** ���[�J���J�[�\��***
    CURSOR base_mst_cur
    IS
      SELECT xhdv.dpt6_cd                 AS  dpt6_cd                 -- ����R�[�h
            ,xhdv.dpt6_name               AS  dpt6_name               -- ���_������
            ,xhdv.dpt6_abbreviate         AS  dpt6_abbreviate         -- ���_����
            ,xhdv.dpt6_old_cd             AS  dpt6_old_cd             -- ���{���R�[�h
            ,xhdv.dpt6_sort_num           AS  dpt6_sort_num           -- ���_���я�
            ,ffvl.attribute4              AS  attribute4              -- ���_�������i���{���R�[�h�j
            ,ffvl.attribute6              AS  attribute6              -- ���_���я��i���{���R�[�h�j
            ,xhdv.creation_date           AS  creation_date           -- �쐬��
            ,xhdv.dpt3_cd                 AS  dpt3_cd                 -- ����R�[�h(3�K�w��)
            ,xhdv.dpt3_name               AS  dpt3_name               -- ���_������(3�K�w��)
            ,bnad.customer_name_phonetic  AS  customer_name_phonetic  -- �ڋq�J�i��
            ,bnad.address_line            AS  address_line            -- �Z��
            ,bnad.zip                     AS  zip                     -- �X�֔ԍ�
            ,bnad.phone                   AS  phone                   -- �d�b�ԍ�
            ,bnad.fax                     AS  fax                     -- FAX�ԍ�
      FROM   xxcmm_hierarchy_dept_v xhdv          -- (table)����K�w�r���[
            ,fnd_flex_values        ffvl          -- (table)�l�Z�b�g�l��`�}�X�^
            ,( SELECT arv.customer_number         AS customer_number         -- �ڋq�R�[�h
                     ,arv.customer_name           AS customer_name           -- �ڋq����
                     ,arv.account_name            AS account_name            -- �ڋq����
                     ,arv.customer_name_phonetic  AS customer_name_phonetic  -- �ڋq�J�i��
                     ,pta.party_id                AS party_id                -- �p�[�e�Bid
                     ,pta.address_line            AS address_line            -- �Z��
                     ,pta.zip                     AS zip                     -- �X�֔ԍ�
                     ,pta.phone                   AS phone                   -- �d�b�ԍ�
                     ,pta.fax                     AS fax                     -- FAX�ԍ�
               FROM   ar_customers_v  arv         -- (table)�ڋq�}�X�^
                     ,( /*** ���ݗL���ȓK�p���͈͂̂��� ***/
                        SELECT xpt.party_id                           AS  party_id
                              ,xpt.address_line1 || xpt.address_line2 AS  address_line
                              ,xpt.zip                                AS  zip
                              ,xpt.phone                              AS  phone
                              ,xpt.fax                                AS  fax
                        FROM   xxcmn_parties xpt  -- (table)�p�[�e�B�A�h�I��
                        WHERE  xxccp_common_pkg2.get_process_date BETWEEN xpt.start_date_active
                                                                      AND xpt.end_date_active
                      )               pta         -- (table)�p�[�e�B�A�h�I��
               WHERE  pta.party_id(+)         = arv.party_id
                 AND  arv.customer_class_code = '1'
             )                      bnad          -- (table)���_���̏Z��
      WHERE  bnad.customer_number(+)   = xhdv.dpt6_cd
      AND    ffvl.flex_value_set_id(+) = xhdv.flex_value_set_id
      AND    ffvl.flex_value(+)        = xhdv.dpt6_old_cd
      ORDER BY
             xhdv.dpt6_cd ASC
      ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    -- �P�D���_�����擾���܂�
    --==============================================================
    -- CSV�o�̓f�[�^�擾�J�[�\���̃I�[�v��
    OPEN base_mst_cur;
    -- CSV�o�̓f�[�^�擾�̎擾
    <<base_mst_loop>>
    LOOP
      FETCH base_mst_cur BULK COLLECT INTO gt_csv_out_tab;
      EXIT WHEN base_mst_cur%NOTFOUND;
    END LOOP base_mst_loop;
    -- CSV�o�̓f�[�^�擾�J�[�\���̃N���[�Y
    CLOSE base_mst_cur;
    -- �������擾
    gn_target_cnt := gt_csv_out_tab.COUNT;
--
    --==============================================================
    -- �Q�D���_���擾������0���̏ꍇ�A�Ώۃf�[�^����
    --==============================================================
    IF ( gn_target_cnt = 0 ) THEN
      -- �ŏ�ʑw�̕��吔�ŃG���[���������ꍇ�A���ɊJ���Ă�t�@�C�����폜
      UTL_FILE.FREMOVE( location    => gv_csv_file_dir    -- �폜�Ώۂ�����f�B���N�g��
                       ,filename    => gv_csv_file_name   -- �폜�Ώۃt�@�C����
      );
      -- �G���[���b�Z�[�W���o�͌�A�ُ�I��
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxcmm    -- �}�X�^
                     ,iv_name         => cv_msg_00001         -- �G���[:�Ώۃf�[�^����
                   );
      RAISE global_api_expt;
    END IF;
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
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- �}�X�^
                     ,iv_name         => cv_msg_91003         -- �G���[:�V�X�e���G���[
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- �}�X�^
                     ,iv_name         => cv_msg_91003         -- �G���[:�V�X�e���G���[
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_base_data;
--
  /**********************************************************************************
   * Procedure Name   : output_csv_data
   * Description      : ���o���o��(A-5)
   ***********************************************************************************/
  PROCEDURE output_csv_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_csv_data'; -- �v���O������
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
    cv_sep          CONSTANT VARCHAR2(1)   := ',';  -- ��؂蕶��
    cv_dqu          CONSTANT VARCHAR2(1)   := '"';  -- �_�u���N�H�[�e�[�V����
    cv_datetime_fmt CONSTANT VARCHAR2(16)  := 'YYYYMMDDHH24MISS'; -- �����o�̓t�H�[�}�b�g�@
    -- *** ���[�J���ϐ� ***
    ln_idx          NUMBER;          -- Loop���̃J�E���g�ϐ�
    lv_out_val      VARCHAR2(255);   -- �o�͓��e(����)
    lv_out_line     VARCHAR2(2400);  -- �o�͓��e(�s)
    lv_base_code    hz_cust_accounts.account_number%TYPE;
                                    -- ���_�R�[�h
    ld_sys_date     DATE;            -- 1���R�[�h�ڏo�͎��̃V�X�e�����t
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    -- �擾�������_�}�X�^IF�̏����ACSV�t�@�C���֏o��
    --==============================================================
    <<output_csv_loop>>
    FOR ln_idx IN 1 .. gn_target_cnt LOOP
      BEGIN
        -- �� �����ݒ�
        lv_base_code := SUBSTRB(gt_csv_out_tab(ln_idx).dpt6_cd, 1, 4);
        lv_out_val   := '';
        lv_out_line  := '';
--
        -- �� �V�X�e�����t���擾����B
        IF ln_idx = 1 THEN
          ld_sys_date := SYSDATE;
        END IF;
--
        -- �� �o�̓f�[�^�쐬
        -- 1.���_�i����j�R�[�h
        lv_out_val  := SUBSTRB(gt_csv_out_tab(ln_idx).dpt6_cd, 1, 4);
        lv_out_line := cv_dqu || lv_out_val || cv_dqu;
        -- 2.���n�p���_���̂P
        lv_out_val   := '';
        lv_out_line := lv_out_line || cv_sep || cv_dqu || lv_out_val || cv_dqu;
        -- 3.���n�p���_���̂Q
        lv_out_val   := '';
        lv_out_line := lv_out_line || cv_sep || cv_dqu || lv_out_val || cv_dqu;
        -- 4.���n�p���_���̂R
        lv_out_val  := SUBSTRB(gt_csv_out_tab(ln_idx).dpt6_name, 1, 20);
        lv_out_line := lv_out_line || cv_sep || cv_dqu || lv_out_val || cv_dqu;
        -- 5.���n�p���_���̂P
        lv_out_val   := '';
        lv_out_line := lv_out_line || cv_sep || cv_dqu || lv_out_val || cv_dqu;
        -- 6.���n�p���_���̂Q
        lv_out_val   := '';
        lv_out_line := lv_out_line || cv_sep || cv_dqu || lv_out_val || cv_dqu;
        -- 7.���n�p���_���̂R
        lv_out_val  := SUBSTRB(gt_csv_out_tab(ln_idx).dpt6_abbreviate, 1, 8);
        lv_out_line := lv_out_line || cv_sep || cv_dqu || lv_out_val || cv_dqu;
        -- 8.�ŐV��{���R�[�h
        lv_out_val   := '';
        lv_out_line := lv_out_line || cv_sep || cv_dqu || lv_out_val || cv_dqu;
        -- 9.�ŐV��{������
        lv_out_val   := '';
        lv_out_line := lv_out_line || cv_sep || cv_dqu || lv_out_val || cv_dqu;
        --10.�ŐV�{���R�[�h(��ʂS��)
        lv_out_val  := SUBSTRB(gt_csv_out_tab(ln_idx).dpt3_cd, 1, 4);
        lv_out_line := lv_out_line || cv_sep || cv_dqu || lv_out_val || cv_dqu;
        --11.�ŐV�{������
        lv_out_val  := SUBSTRB(gt_csv_out_tab(ln_idx).dpt3_name, 1, 12);
        lv_out_line := lv_out_line || cv_sep || cv_dqu || lv_out_val || cv_dqu;
        --12.�ŐV�n��{���R�[�h
        lv_out_val  := SUBSTRB(gt_csv_out_tab(ln_idx).dpt6_old_cd, 1, 4);
        lv_out_line := lv_out_line || cv_sep || cv_dqu || lv_out_val || cv_dqu;
        --13.�ŐV�n��{������
        lv_out_val  := SUBSTRB(gt_csv_out_tab(ln_idx).attribute4, 1, 16);
        lv_out_line := lv_out_line || cv_sep || cv_dqu || lv_out_val || cv_dqu;
        --14.�ŐV�{���R�[�h
        lv_out_val  := SUBSTRB(gt_csv_out_tab(ln_idx).dpt6_old_cd ||
                         SUBSTRB(LPAD(gt_csv_out_tab(ln_idx).attribute6, 3, '0'), 2, 2), 1, 6);
        lv_out_line := lv_out_line || cv_sep || cv_dqu || lv_out_val || cv_dqu;
        --15.���_���i�������j
        lv_out_val  := SUBSTRB(gt_csv_out_tab(ln_idx).dpt6_name, 1, 20);
        lv_out_line := lv_out_line || cv_sep || cv_dqu || lv_out_val || cv_dqu;
        --16.���_���i�����j
        lv_out_val  := SUBSTRB(gt_csv_out_tab(ln_idx).dpt6_abbreviate, 1, 8);
        lv_out_line := lv_out_line || cv_sep || cv_dqu || lv_out_val || cv_dqu;
        --17.���_���i�J�i�j
        lv_out_val  := SUBSTRB(gt_csv_out_tab(ln_idx).customer_name_phonetic, 1, 10);
        lv_out_line := lv_out_line || cv_sep || cv_dqu || lv_out_val || cv_dqu;
        --18.���_�Z��
        lv_out_val  := SUBSTRB(gt_csv_out_tab(ln_idx).address_line, 1, 60);
        lv_out_line := lv_out_line || cv_sep || cv_dqu || lv_out_val || cv_dqu;
        --19.�X�֔ԍ�
        lv_out_val  := SUBSTRB(gt_csv_out_tab(ln_idx).zip, 1, 60);
        lv_out_line := lv_out_line || cv_sep || cv_dqu || lv_out_val || cv_dqu;
        --20.�d�b�ԍ�
        lv_out_val  := SUBSTRB(gt_csv_out_tab(ln_idx).phone, 1, 60);
        lv_out_line := lv_out_line || cv_sep || cv_dqu || lv_out_val || cv_dqu;
        --21.�e�`�w�ԍ�
        lv_out_val  := SUBSTRB(gt_csv_out_tab(ln_idx).fax, 1, 60);
        lv_out_line := lv_out_line || cv_sep || cv_dqu || lv_out_val || cv_dqu;
        --22.���{���R�[�h(null)
        lv_out_val   := '';
        lv_out_line := lv_out_line || cv_sep || cv_dqu || lv_out_val || cv_dqu;
        --23.�V�{���R�[�h
        lv_out_val  := SUBSTRB(gt_csv_out_tab(ln_idx).dpt6_old_cd ||
                         SUBSTRB(LPAD(NVL(gt_csv_out_tab(ln_idx).attribute6, ''), 3, '0'), 2, 2), 1, 6);
        lv_out_line := lv_out_line || cv_sep || cv_dqu || lv_out_val || cv_dqu;
        --24.�{���R�[�h�K�p�J�n��(null)
        lv_out_val   := '';
        lv_out_line := lv_out_line || cv_sep || cv_dqu || lv_out_val || cv_dqu;
        --25.���_���їL���敪(null)
        lv_out_val   := '';
        lv_out_line := lv_out_line || cv_sep || cv_dqu || lv_out_val || cv_dqu;
        --26.�o�ɊǗ����敪(null)
        lv_out_val   := '';
        lv_out_line := lv_out_line || cv_sep || cv_dqu || lv_out_val || cv_dqu;
        --27.�n�於�i�{���R�[�h�p�j
        lv_out_val  := SUBSTRB(gt_csv_out_tab(ln_idx).attribute4, 1, 16);
        lv_out_line := lv_out_line || cv_sep || cv_dqu || lv_out_val || cv_dqu;
        --28.�쐬�N���������b	���t
        lv_out_val  := TO_CHAR(gt_csv_out_tab(ln_idx).creation_date, cv_datetime_fmt);
-- 2009/02/27 UPD by M.Sano Start
--        lv_out_line := lv_out_line || cv_sep || cv_dqu || lv_out_val || cv_dqu;
        lv_out_line := lv_out_line || cv_sep || lv_out_val;
-- 2009/02/27 UPD by M.Sano End
        --29.�ŏI�X�V�N���������b
        lv_out_val  := TO_CHAR(ld_sys_date, cv_datetime_fmt);
-- 2009/02/27 UPD by M.Sano Start
--        lv_out_line := lv_out_line || cv_sep || cv_dqu || lv_out_val || cv_dqu;
        lv_out_line := lv_out_line || cv_sep || lv_out_val;
-- 2009/02/27 UPD by M.Sano End
        --30.�\��(null)
        lv_out_val   := '';
        lv_out_line := lv_out_line || cv_sep || cv_dqu || lv_out_val || cv_dqu;
--
        -- �� �o�̓f�[�^��csv�t�@�C���ɏo�͂���B
        UTL_FILE.PUT_LINE(gf_file_handler, lv_out_line);
--
      EXCEPTION
        WHEN UTL_FILE.WRITE_ERROR THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name_xxcmm    -- �}�X�^
                         ,iv_name         => cv_msg_00009         -- �G���[  :CSV�f�[�^�o�̓G���[
                         ,iv_token_name1  => cv_tok_ng_word       -- �g�[�N��:NG_WORD
                         ,iv_token_value1 => cv_tvl_base_code     -- �l      :���_�R�[�h
                         ,iv_token_name2  => cv_tok_ng_data       -- �g�[�N��:NG_DATA
                         ,iv_token_value2 => lv_base_code         -- �l      :���_�R�[�h(�f�[�^)
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
--
      --�����������X�V����B
      gn_normal_cnt := gn_normal_cnt + 1;
   END LOOP output_csv_loop;
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
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- �}�X�^
                     ,iv_name         => cv_msg_91003         -- �G���[:�V�X�e���G���[
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- �}�X�^
                     ,iv_name         => cv_msg_91003         -- �G���[:�V�X�e���G���[
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END output_csv_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf             OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- *** ���[�J���ϐ� ***
    lv_tok_value        VARCHAR2(100);  -- �g�[�N���Ɋi�[����l
    lv_out_msg          VARCHAR2(5000); -- �o�͗p
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
    -- ===============================================
    -- A-1.��������
    -- ===============================================
    init(
       ov_errbuf           => lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode          => lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg           => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- ���̓p�����[�^�Ȃ��o��
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => cv_msg_90008
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_out_msg
    );
    -- �t�@�C�����o��
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => cv_msg_05132
                    ,iv_token_name1  => cv_tok_filename
                    ,iv_token_value1 => gv_csv_file_name
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_out_msg
    );
    -- ���������̎��s���ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- A-2�D�t�@�C���I�[�v������(�������[�h)
    -- ===============================================
    open_csv_file(
       ov_errbuf           => lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode          => lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg           => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- A-3�D�ŏ�ʕ��匏���擾
    -- ===============================================
    chk_count_top_dept(
       ov_errbuf           => lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode          => lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg           => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- �t�@�C���������Ă��Ȃ��ꍇ�A�t�@�C�������B
      IF ( UTL_FILE.IS_OPEN(gf_file_handler) ) THEN
        UTL_FILE.FCLOSE(gf_file_handler);
      END IF;
      -- ��O���X���[
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- A-4�D�����Ώۃf�[�^���o
    -- ===============================================
    get_base_data(
       ov_errbuf           => lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode          => lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg           => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- �t�@�C���������Ă��Ȃ��ꍇ�A�t�@�C�������B
      IF ( UTL_FILE.IS_OPEN(gf_file_handler) ) THEN
        UTL_FILE.FCLOSE(gf_file_handler);
      END IF;
      -- ��O���X���[
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- A-5�D���o���o��
    -- ===============================================
    output_csv_data(
       ov_errbuf           => lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode          => lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg           => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �G���[�������X�V����B
    gn_error_cnt := gn_target_cnt - gn_normal_cnt;
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- �t�@�C���������Ă��Ȃ��ꍇ�A�t�@�C�������B
      IF ( UTL_FILE.IS_OPEN(gf_file_handler) ) THEN
        UTL_FILE.FCLOSE(gf_file_handler);
      END IF;
      -- ��O���X���[
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- A-6�D�I������
    -- ===============================================
    UTL_FILE.FCLOSE(gf_file_handler);
--
  EXCEPTION
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- �}�X�^
                     ,iv_name         => cv_msg_91003         -- �G���[:�V�X�e���G���[
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- �}�X�^
                     ,iv_name         => cv_msg_91003         -- �G���[:�V�X�e���G���[
                   );
-- 2009/02/26 ADD by M.Sano End
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
  PROCEDURE main(
    errbuf                OUT    VARCHAR2,        --   �G���[���b�Z�[�W #�Œ�#
    retcode               OUT    VARCHAR2)        --   �G���[�R�[�h     #�Œ�#
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
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf           VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode          VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg           VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code     VARCHAR2(100);   -- �I�����b�Z�[�W�R�[�h
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
       ov_errbuf           => lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode          => lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg           => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- ===============================================
    -- �G���[���b�Z�[�W�̏o��
    -- ===============================================
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
      -- �G���[�������A���A�G���[����:0�̏ꍇ�A�e�����͈ȉ��ɓ��ꂵ�ďo�͂���
      if ( gn_error_cnt = 0 ) THEN
        gn_target_cnt := 0;
        gn_normal_cnt := 0;
        gn_error_cnt  := 1;
      END IF;
    END IF;
--
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -- ===============================================
    -- �����̏o��
    -- ===============================================
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => cv_msg_90000
                    ,iv_token_name1  => cv_tok_count
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => cv_msg_90001
                    ,iv_token_name1  => cv_tok_count
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => cv_msg_90002
                    ,iv_token_name1  => cv_tok_count
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    -- ===============================================
    --�I�����b�Z�[�W
    -- ===============================================
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
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
END XXCMM005A05C;
/
