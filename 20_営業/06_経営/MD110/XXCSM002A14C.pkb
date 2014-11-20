CREATE OR REPLACE PACKAGE BODY XXCSM002A14C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM002A14C(body)
 * Description      : ���i�v��w�b�_�e�[�u���A�y�я��i�v�斾�׃e�[�u�����
 *                    �Ώۗ\�Z�N�x�̏��i�v��f�[�^�𒊏o���A���n�V�X�e����
 *                    �A�g���邽�߂�I/F�t�@�C�����쐬���܂��B
 * MD.050           : MD050_CSM_002_A14_�N�ԏ��i�v����n�V�X�e��IF
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   �������� (A-1)
 *  open_csv_file          �t�@�C���I�[�v������ (A-2)
 *  create_csv_rec         �N�ԏ��i�v��f�[�^�t�@�C���쐬���� (A-4)
 *  close_csv_file         �t�@�C���N���[�Y�������� (A-5)
 *  submain                ���C�������v���V�[�W��
 *                         �N�ԏ��i�v��f�[�^���o���� (A-3)
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                         �I������ (A-6)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-01-21    1.0   T.Shimoji       �V�K�쐬
 *  2009-07-27    1.1   K.Kubo          �mSCS��Q�Ǘ��ԍ�0000784�n�Ώ�0�����̃n���h�����O�ύX
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal;             -- ����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;               -- �x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;              -- �ُ�:2
  --WHO�J����
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;                             -- CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                                        -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;                             -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                                        -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;                            -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id;                     -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;                        -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id;                     -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                                        -- PROGRAM_UPDATE_DATE
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
  cv_msg_00111              CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00111';                           -- �z��O�G���[���b�Z�[�W
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg                VARCHAR2(2000);
  gv_sep_msg                VARCHAR2(2000);
  gv_exec_user              VARCHAR2(100);
  gv_conc_name              VARCHAR2(30);
  gv_conc_status            VARCHAR2(30);
  gn_target_cnt             NUMBER;                                                                 -- �Ώی���
  gn_normal_cnt             NUMBER;                                                                 -- ���팏��
  gn_error_cnt              NUMBER;                                                                 -- �G���[����
  gn_warn_cnt               NUMBER;                                                                 -- �X�L�b�v����
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
  cv_pkg_name             CONSTANT VARCHAR2(100) := 'XXCSM002A14C';                                 -- �p�b�P�[�W��
  cv_app_name             CONSTANT VARCHAR2(5)   := 'XXCSM';                                        -- �A�v���P�[�V�����Z�k��
  -- ���b�Z�[�W�R�[�h
  cv_xxccp_msg_008        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90008';                             -- �R���J�����g���̓p�����[�^�Ȃ�
  cv_xxcsm_msg_001        CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00001';                             -- �t�@�C�����݃`�F�b�N�G���[���b�Z�[�W
  cv_xxcsm_msg_002        CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00002';                             -- �t�@�C���I�[�v���G���[���b�Z�[�W
  cv_xxcsm_msg_003        CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00003';                             -- �t�@�C���N���[�Y�G���[���b�Z�[�W
--//+DEL START  2009-07-27 0000784 K.Kubo
--  cv_xxcsm_msg_019        CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00019';                             -- ���n�V�X�e���A�g�Ώۖ����G���[���b�Z�[�W
--//+DEL END    2009-07-27 0000784 K.Kubo
  cv_xxcsm_msg_021        CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00021';                             -- �N�x�擾�G���[���b�Z�[�W
  cv_xxcsm_msg_031        CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00031';                             -- ������s�p�v���t�@�C���擾�G���[���b�Z�[�W
  cv_xxcsm_msg_084        CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00084';                             -- �C���^�[�t�F�[�X�t�@�C����
  --�v���t�@�C����
  cv_file_dir             CONSTANT VARCHAR2(100) := 'XXCSM1_INFOSYS_FILE_DIR';                      -- ���n�f�[�^�t�@�C���쐬�f�B���N�g��
  cv_file_name            CONSTANT VARCHAR2(100) := 'XXCSM1_ITEM_PLAN_FILE_NAME';                   -- �N�ԏ��i�v��f�[�^�t�@�C����
  -- �g�[�N���R�[�h
  cv_tkn_directory        CONSTANT VARCHAR2(20) := 'DIRECTORY';
  cv_tkn_file_name        CONSTANT VARCHAR2(20) := 'FILE_NAME';
  cv_tkn_prf_name         CONSTANT VARCHAR2(20) := 'PROF_NAME';
  cv_tkn_sql_code         CONSTANT VARCHAR2(20) := 'SQL_CODE';
  cv_tkn_count            CONSTANT VARCHAR2(20) := 'COUNT';
  cv_tkn_yyyymm           CONSTANT VARCHAR2(20) := 'YYYYMM';
  -- ���i�v�斾�׃f�[�^�擾�����l
  cv_bdgt_kbn_m           CONSTANT VARCHAR2(1)  := '0';                                             -- �N�ԌQ�\�Z�敪(0:�e���P��)
  cv_item_kbn_g           CONSTANT VARCHAR2(1)  := '0';                                             -- ���i�敪(0:���i�Q)
--
  cb_true                 CONSTANT BOOLEAN := TRUE;
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- �t�@�C���E�n���h���̐錾
  gf_file_hand            UTL_FILE.FILE_TYPE;
  gv_file_dir             VARCHAR2(100);
  gv_file_name            VARCHAR2(100);
  gd_sysdate              DATE;
  gv_budget_year          VARCHAR2(4);
  gv_budget_month         VARCHAR2(2);
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- CSV�o�̓f�[�^�i�[�p���R�[�h�^��`
  TYPE g_get_data_rtype IS RECORD(
     plan_year            xxcsm_item_plan_headers.plan_year%TYPE                                    -- �\�Z�N�x
    ,year_month           xxcsm_item_plan_lines.year_month%TYPE                                     -- �N��
    ,location_cd          xxcsm_item_plan_headers.location_cd%TYPE                                  -- ���_�R�[�h
    ,item_no              xxcsm_item_plan_lines.item_no%TYPE                                        -- ���i�R�[�h
    ,amount               xxcsm_item_plan_lines.amount%TYPE                                         -- ����
    ,sales_budget         xxcsm_item_plan_lines.sales_budget%TYPE                                   -- ������z
  );
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : �������� (A-1)
   ***********************************************************************************/
  PROCEDURE init(
     ov_errbuf           OUT NOCOPY VARCHAR2                                                        -- �G���[�E���b�Z�[�W
    ,ov_retcode          OUT NOCOPY VARCHAR2                                                        -- ���^�[���E�R�[�h
    ,ov_errmsg           OUT NOCOPY VARCHAR2                                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100)   := 'init';                                         -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf           VARCHAR2(4000);                                                             -- �G���[�E���b�Z�[�W
    lv_retcode          VARCHAR2(1);                                                                -- ���^�[���E�R�[�h
    lv_errmsg           VARCHAR2(4000);                                                             -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_appl_short_name   CONSTANT VARCHAR2(10)  := 'XXCCP';                                         -- �A�v���P�[�V�����Z�k��
    cn_next_day          CONSTANT NUMBER := 1;                                                      -- ���c�Ɠ�
    -- *** ���[�J���ϐ� ***
    lv_noprm_msg         VARCHAR2(4000);                                                            -- �R���J�����g���̓p�����[�^�Ȃ����b�Z�[�W�i�[�p
    lv_month             VARCHAR2(100);
    lv_msg               VARCHAR2(100);
    lv_tkn_value         VARCHAR2(100);
    -- �t�@�C�����݃`�F�b�N�߂�l�p
    lb_retcd             BOOLEAN;
    ln_file_size         NUMBER;
    ln_block_size        NUMBER;
    ld_process_date      DATE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- =================================
    -- ���̓p�����[�^�Ȃ����b�Z�[�W�o�� 
    -- =================================
    lv_noprm_msg   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name                                       --�A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_xxccp_msg_008                                         --���b�Z�[�W�R�[�h
                      );
    --���b�Z�[�W�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_noprm_msg || CHR(10) ||
                 ''                                                                                 -- ��s�̑}��
    );
    -- 
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_noprm_msg || CHR(10) ||
                 ''                                                                                 -- ��s�̑}��
    );
    -- =======================
    -- �v���t�@�C���l�擾���� 
    -- =======================
    -- ���n�f�[�^�t�@�C���쐬�f�B���N�g�����擾
    gv_file_dir   := FND_PROFILE.VALUE(cv_file_dir);
    -- �v���t�@�C���l�擾�Ɏ��s�����ꍇ
    IF (gv_file_dir IS NULL) THEN                                                                   -- CSV�t�@�C���o�͐�擾���s��
      -- �G���[���b�Z�[�W�擾
      lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_app_name                                                   --�A�v���P�[�V�����Z�k��
                  ,iv_name         => cv_xxcsm_msg_031                                              --���b�Z�[�W�R�[�h
                  ,iv_token_name1  => cv_tkn_prf_name                                               --�g�[�N���R�[�h1
                  ,iv_token_value1 => cv_file_dir                                                   --�g�[�N���l1
                 );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    END IF;
    -- �N�ԏ��i�v��f�[�^�t�@�C�����擾
    gv_file_name  := FND_PROFILE.VALUE(cv_file_name);
    -- �v���t�@�C���l�擾�Ɏ��s�����ꍇ
    IF (gv_file_name IS NULL) THEN                                                                  -- CSV�t�@�C���o�͐�擾���s��
      -- �G���[���b�Z�[�W�擾
      lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_app_name                                                   --�A�v���P�[�V�����Z�k��
                  ,iv_name         => cv_xxcsm_msg_031                                              --���b�Z�[�W�R�[�h
                  ,iv_token_name1  => cv_tkn_prf_name                                               --�g�[�N���R�[�h1
                  ,iv_token_value1 => cv_file_name                                                  --�g�[�N���l1
                 );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    END IF;
    -- �N�ԏ��i�v��f�[�^�t�@�C���������b�Z�[�W�o�͂���
    lv_msg := xxccp_common_pkg.get_msg(
             iv_application  => cv_app_name                                                         --�A�v���P�[�V�����Z�k��
            ,iv_name         => cv_xxcsm_msg_084                                                    --���b�Z�[�W�R�[�h
            ,iv_token_name1  => cv_tkn_file_name                                                    --�g�[�N���R�[�h1
            ,iv_token_value1 => gv_file_name                                                        --�g�[�N���l1
          );
    --���b�Z�[�W�o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg || CHR(10) ||
                 ''                                                                                 -- ��s�̑}��
    );
    -- ========================
    -- CSV�t�@�C�����݃`�F�b�N 
    -- ========================
    UTL_FILE.FGETATTR(
       location    => gv_file_dir
      ,filename    => gv_file_name
      ,fexists     => lb_retcd
      ,file_length => ln_file_size
      ,block_size  => ln_block_size
    );
    -- ���łɃt�@�C�������݂���ꍇ
    IF (lb_retcd = cb_true) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_app_name                                                   --�A�v���P�[�V�����Z�k��
                  ,iv_name         => cv_xxcsm_msg_001                                              --���b�Z�[�W�R�[�h
                  ,iv_token_name1  => cv_tkn_directory                                              --�g�[�N���R�[�h1
                  ,iv_token_value1 => gv_file_dir                                                   --�g�[�N���l1
                  ,iv_token_name2  => cv_tkn_file_name                                              --�g�[�N���R�[�h2
                  ,iv_token_value2 => gv_file_name                                                  --�g�[�N���l2
                 );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    END IF;
    -- ===========================
    -- �V�X�e�����t�擾���� 
    -- ===========================
    gd_sysdate := SYSDATE;
    -- =====================
    -- �Ɩ��������t�擾���� 
    -- =====================
    ld_process_date := xxccp_common_pkg2.get_process_date;
    -- =====================
    -- �N�x�E���̎Z�o 
    -- =====================
    xxcsm_common_pkg.get_year_month(
         iv_process_years   => TO_CHAR(ld_process_date,'YYYYMM')                                    -- �N��
        ,ov_year            => gv_budget_year                                                       -- �擾�\�Z�N�x
        ,ov_month           => gv_budget_month                                                      -- �擾�\�Z��
        ,ov_retcode         => lv_retcode                                                           -- ���^�[���R�[�h
        ,ov_errbuf          => lv_errbuf                                                            -- �G���[���b�Z�[�W
        ,ov_errmsg          => lv_errmsg                                                            -- ���[�U�[�E�G���[���b�Z�[�W
    );
    -- �\�Z�N�x�擾�G���[�ꍇ
    IF (lv_retcode <> cv_status_normal) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_app_name                                                   --�A�v���P�[�V�����Z�k��
                  ,iv_name         => cv_xxcsm_msg_021                                              --���b�Z�[�W�R�[�h
                  ,iv_token_name1  => cv_tkn_yyyymm                                                 --�g�[�N���R�[�h1
                  ,iv_token_value1 => TO_CHAR(ld_process_date,'YYYYMM')                             --�g�[�N���l1
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
  /**********************************************************************************
   * Procedure Name   : open_csv_file
   * Description      : �t�@�C���I�[�v������ (A-2)
   ***********************************************************************************/
  PROCEDURE open_csv_file(
     ov_errbuf         OUT NOCOPY VARCHAR2                                                          -- �G���[�E���b�Z�[�W
    ,ov_retcode        OUT NOCOPY VARCHAR2                                                          -- ���^�[���E�R�[�h
    ,ov_errmsg         OUT NOCOPY VARCHAR2                                                          -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'open_csv_file';                                    -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
--
    lv_errbuf         VARCHAR2(4000);                                                               -- �G���[�E���b�Z�[�W
    lv_retcode        VARCHAR2(1);                                                                  -- ���^�[���E�R�[�h
    lv_errmsg         VARCHAR2(4000);                                                               -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_w              CONSTANT VARCHAR2(1) := 'w';                                                  -- ���� = w
    cn_max_size       CONSTANT NUMBER := 2047;                                                      -- 2047�o�C�g
--
    -- *** ���[�J���ϐ� ***
    -- �t�@�C���I�[�v���m�F�߂�l�i�[
    lb_fopn_retcd     BOOLEAN;
    -- *** ���[�J����O ***
    file_err_expt     EXCEPTION;                                                                    -- �t�@�C��������O
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
    -- CSV�t�@�C���I�[�v�� 
    -- ========================
    BEGIN
      -- �t�@�C���I�[�v��
      gf_file_hand := UTL_FILE.FOPEN(
                         location     => gv_file_dir                                                -- ���n�f�[�^�t�@�C���f�B���N�g��
                        ,filename     => gv_file_name                                               -- �N�ԏ��i�v��f�[�^�t�@�C����
                        ,open_mode    => cv_w                                                       -- ����
                        ,max_linesize => cn_max_size                                                -- 2047�o�C�g
                      );
    EXCEPTION
      WHEN OTHERS THEN
        -- �G���[���b�Z�[�W�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                                               --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_xxcsm_msg_002                                          --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_directory                                          --�g�[�N���R�[�h1
                      ,iv_token_value1 => gv_file_dir                                               --�g�[�N���l1
                      ,iv_token_name2  => cv_tkn_file_name                                          --�g�[�N���R�[�h2
                      ,iv_token_value2 => gv_file_name                                              --�g�[�N���l2
                      ,iv_token_name3  => cv_tkn_sql_code                                           --�g�[�N���R�[�h3
                      ,iv_token_value3 => SQLERRM                                                   --�g�[�N���l3
                     );
        lv_errbuf := lv_errmsg;
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
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
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
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END open_csv_file;
--
  /**********************************************************************************
   * Procedure Name   : create_csv_rec
   * Description      : �N�ԏ��i�v��f�[�^�t�@�C���쐬���� (A-4)
   ***********************************************************************************/
  PROCEDURE create_csv_rec(
     ir_plan_item        IN  g_get_data_rtype                                                       -- �N�ԏ��i�v��f�[�^
    ,ov_errbuf           OUT NOCOPY VARCHAR2                                                        -- �G���[�E���b�Z�[�W
    ,ov_retcode          OUT NOCOPY VARCHAR2                                                        -- ���^�[���E�R�[�h
    ,ov_errmsg           OUT NOCOPY VARCHAR2                                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'create_csv_rec';                              -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf            VARCHAR2(4000);                                                            -- �G���[�E���b�Z�[�W
    lv_retcode           VARCHAR2(1);                                                               -- ���^�[���E�R�[�h
    lv_errmsg            VARCHAR2(4000);                                                            -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_sep_com           CONSTANT VARCHAR2(1)  := ',';                                              -- ��؂蕶��
    cv_sep_wquot         CONSTANT VARCHAR2(1)  := '"';                                              -- �͂ݕ���
    cv_company_cd        CONSTANT VARCHAR2(3)  := '001';                                            -- ��ЃR�[�h
    -- *** ���[�J���ϐ� ***
    lv_data              VARCHAR2(4000);                                                            -- �ҏW�f�[�^�i�[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ======================
    -- CSV�o�͏��� 
    -- ======================
    -- �f�[�^�쐬
    lv_data := 
      cv_sep_wquot  || cv_company_cd         || cv_sep_wquot                         -- ��ЃR�[�h
      || cv_sep_com || TO_CHAR(ir_plan_item.plan_year)                               -- �\�Z�N�x
      || cv_sep_com || TO_CHAR(ir_plan_item.year_month)                              -- �N��
      || cv_sep_com ||
      cv_sep_wquot  || ir_plan_item.location_cd || cv_sep_wquot                      -- ���_�R�[�h
      || cv_sep_com ||
      cv_sep_wquot  || ir_plan_item.item_no     || cv_sep_wquot                      -- ���i�R�[�h
      || cv_sep_com || TO_CHAR(ir_plan_item.amount)                                  -- ����
      || cv_sep_com || TO_CHAR(ir_plan_item.sales_budget)                            -- ������z
      || cv_sep_com || TO_CHAR(gd_sysdate, 'yyyymmddhh24miss');                      -- �A�g����                                                                                            -- �A�g����
    -- �f�[�^�o��
    UTL_FILE.PUT_LINE(
      file   => gf_file_hand
     ,buffer => lv_data
    );
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
  END create_csv_rec;
--
  /**********************************************************************************
   * Procedure Name   : close_csv_file
   * Description      : �t�@�C���N���[�Y�������� (A-5)
   ***********************************************************************************/
  PROCEDURE close_csv_file(
     ov_errbuf         OUT NOCOPY VARCHAR2                                                          -- �G���[�E���b�Z�[�W
    ,ov_retcode        OUT NOCOPY VARCHAR2                                                          -- ���^�[���E�R�[�h
    ,ov_errmsg         OUT NOCOPY VARCHAR2                                                          -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'close_csv_file';                                  -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
--
    lv_errbuf          VARCHAR2(4000);                                                              -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);                                                                 -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(4000);                                                              -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    -- �t�@�C���I�[�v���m�F�߂�l�i�[
    lb_fopn_retcd     BOOLEAN;
    -- *** ���[�J����O ***
    file_err_expt     EXCEPTION;                                                                    -- �t�@�C��������O
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
    EXCEPTION
      WHEN OTHERS THEN
        -- �G���[���b�Z�[�W�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                                               -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_xxcsm_msg_003                                          -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_file_dir                                               -- �g�[�N���R�[�h1
                      ,iv_token_value1 => gv_file_dir                                               -- �g�[�N���l1
                      ,iv_token_name2  => cv_file_name                                              -- �g�[�N���R�[�h1
                      ,iv_token_value2 => gv_file_name                                              -- �g�[�N���l1
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
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
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
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
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
     ov_errbuf           OUT NOCOPY VARCHAR2                                                        -- �G���[�E���b�Z�[�W
    ,ov_retcode          OUT NOCOPY VARCHAR2                                                        -- ���^�[���E�R�[�h
    ,ov_errmsg           OUT NOCOPY VARCHAR2                                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'submain';                                     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf            VARCHAR2(4000);                                                            -- �G���[�E���b�Z�[�W
    lv_retcode           VARCHAR2(1);                                                               -- ���^�[���E�R�[�h
    lv_errmsg            VARCHAR2(4000);                                                            -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    -- �t�@�C���I�[�v���m�F�߂�l�i�[
    lb_fopn_retcd        BOOLEAN;
    -- ���b�Z�[�W�o�͗p
    lv_msg               VARCHAR2(2000);
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR get_item_plan_cur                                                              -- �N�ԏ��i�v��f�[�^�擾
    IS
      SELECT    xiph.plan_year             AS  plan_year                                  -- �\�Z�N�x
               ,xipl.year_month            AS  year_month                                 -- �N��
               ,xiph.location_cd           AS  location_cd                                -- ���_�R�[�h
               ,xipl.item_no               AS  item_no                                    -- ���i�R�[�h
               ,xipl.amount                AS  amount                                     -- ����
               ,xipl.sales_budget          AS  sales_budget                               -- ������z
      FROM      xxcsm_item_plan_headers  xiph                                             --�w���i�v��w�b�_�e�[�u���x
               ,xxcsm_item_plan_lines    xipl                                             --�w���i�v�斾�׃e�[�u���x
      WHERE     xiph.item_plan_header_id = xipl.item_plan_header_id                       -- ���i�v��w�b�_ID
        AND     xiph.plan_year           = TO_NUMBER(gv_budget_year)                      -- �\�Z�N�x
        AND     xipl.year_bdgt_kbn       = cv_bdgt_kbn_m                                  -- �N�ԌQ�\�Z�敪(0:�e���P��)
        AND     xipl.item_kbn           <> cv_item_kbn_g                                  -- ���i�敪(0:���i�Q)�ȊO
      ORDER BY  xipl.year_month                                                           -- �\�[�g����:�N��
               ,xiph.location_cd                                                          --   ���_�R�[�h
               ,xipl.item_no                                                              --   ���i�R�[�h
      ;
    -- *** ���[�J���E���R�[�h ***
    l_get_data_rec       g_get_data_rtype;
    -- *** ���[�J����O ***
    no_data_expt         EXCEPTION;
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
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    -- ========================================
    -- A-1.�������� 
    -- ========================================
    init(
       ov_errbuf  => lv_errbuf                                                                      -- �G���[�E���b�Z�[�W
      ,ov_retcode => lv_retcode                                                                     -- ���^�[���E�R�[�h
      ,ov_errmsg  => lv_errmsg                                                                      -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    -- =========================================
    -- A-2.�t�@�C���I�[�v������ 
    -- =========================================
    open_csv_file(
       ov_errbuf    => lv_errbuf                                                                    -- �G���[�E���b�Z�[�W
      ,ov_retcode   => lv_retcode                                                                   -- ���^�[���E�R�[�h
      ,ov_errmsg    => lv_errmsg                                                                    -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    -- ========================================
    -- A-3.�N�ԏ��i�v��f�[�^�擾����
    -- ========================================
    -- �J�[�\���I�[�v��
    OPEN get_item_plan_cur;
    -- �N�ԏ��i�v��f�[�^�擾LOOP
    <<get_data_loop>>
    LOOP
      FETCH get_item_plan_cur INTO l_get_data_rec;
      EXIT WHEN get_item_plan_cur%NOTFOUND;
      -- �����Ώی����i�[
      gn_target_cnt := get_item_plan_cur%ROWCOUNT;
      -- 
      -- ========================================
      -- A-4.�N�ԏ��i�v��f�[�^�t�@�C���쐬����
      -- ========================================
      create_csv_rec(
        ir_plan_item   =>  l_get_data_rec                                                           -- �N�ԏ��i�v��f�[�^
       ,ov_errbuf      =>  lv_errbuf                                                                -- �G���[�E���b�Z�[�W
       ,ov_retcode     =>  lv_retcode                                                               -- ���^�[���E�R�[�h
       ,ov_errmsg      =>  lv_errmsg                                                                -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      --
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
      -- ���팏���J�E���g�A�b�v
      gn_normal_cnt := gn_normal_cnt + 1;
    END LOOP get_data_loop;
    -- �J�[�\���N���[�Y
    CLOSE get_item_plan_cur;
--//+DEL START  2009-07-27 0000784 K.Kubo
--    -- �����Ώی�����0���̏ꍇ
--    IF (gn_target_cnt = 0) THEN
--      -- �G���[���b�Z�[�W�擾
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_app_name                                                 --�A�v���P�[�V�����Z�k��
--                    ,iv_name         => cv_xxcsm_msg_019                                            --���b�Z�[�W�R�[�h
--                   );
--      lv_errbuf := lv_errmsg;
--      RAISE no_data_expt;
--    END IF;
--//+DEL END    2009-07-27 0000784 K.Kubo
    -- ========================================
    -- A-5.�t�@�C���N���[�Y����
    -- ========================================
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
--//+DEL START  2009-07-27 0000784 K.Kubo
--    -- *** �����Ώۃf�[�^0����O�n���h�� ***
--    WHEN no_data_expt THEN
--      -- �G���[�����J�E���g
--      gn_error_cnt := gn_error_cnt + 1;
--      --
--      lb_fopn_retcd := UTL_FILE.IS_OPEN (
--                         file =>gf_file_hand
--                       );
--      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
--      IF (lb_fopn_retcd = cb_true) THEN
--        -- �t�@�C���N���[�Y
--        UTL_FILE.FCLOSE(
--          file =>gf_file_hand
--        );
--      END IF;
--      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
--      IF (get_item_plan_cur%ISOPEN) THEN
--        -- �J�[�\���N���[�Y
--        CLOSE get_item_plan_cur;
--      END IF;
--      --
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
--      ov_retcode := cv_status_error;
--//+DEL END    2009-07-27 0000784 K.Kubo
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN--
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (get_item_plan_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_item_plan_cur;
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
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (get_item_plan_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_item_plan_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    WHEN global_process_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (get_item_plan_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_item_plan_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
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
      END IF;
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (get_item_plan_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_item_plan_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
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
     errbuf        OUT NOCOPY VARCHAR2                                                              -- �G���[�E���b�Z�[�W
    ,retcode       OUT NOCOPY VARCHAR2 )                                                            -- ���^�[���E�R�[�h
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';                                            -- �v���O������
    cv_xxcsm           CONSTANT VARCHAR2(100) := 'XXCSM';                                           -- �A�v���P�[�V�����Z�k�� 
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';                                           -- �A�h�I���F���ʁEIF�̈�
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000';                                -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001';                                -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002';                                -- �G���[�������b�Z�[�W
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003';                                -- �X�L�b�v�������b�Z�[�W
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004';                                -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005';                                -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006';                                -- �G���[�I���S���[���o�b�N
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';                                           -- �������b�Z�[�W�p�g�[�N����
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf          VARCHAR2(4000);                                                              -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);                                                                 -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(4000);                                                              -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code    VARCHAR2(100);                                                               -- �I�����b�Z�[�W�R�[�h
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
    --��s�̏o��
    fnd_file.put_line(
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
       ov_errbuf   => lv_errbuf                                                                     -- �G���[�E���b�Z�[�W
      ,ov_retcode  => lv_retcode                                                                    -- ���^�[���E�R�[�h
      ,ov_errmsg   => lv_errmsg                                                                     -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
--
    IF (lv_retcode = cv_status_error) THEN
      IF lv_errmsg IS NULL THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcsm
                      ,iv_name         => cv_msg_00111
                     );
      END IF;
      --�G���[�o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg                                                                        --���[�U�[�E�G���[���b�Z�[�W
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf                                                                        --�G���[���b�Z�[�W
      );
      --�����̐U��(�G���[�̏ꍇ�A�G���[������1���̂ݕ\��������B�j
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt := 1;
    END IF;
--
    -- =======================
    -- A-6.�I������ 
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
    --��s�̏o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
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
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
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
END XXCSM002A14C;
/
