CREATE OR REPLACE PACKAGE BODY XXCSO014A09C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO014A09C(spec)
 * Description      : ���ʔ���v��t�@�C����HHT�֘A�g���邽�߂�CSV�t�@�C�����쐬���܂��B
 *                    
 * MD.050           : MD050_IPO_CSO_014_A09_HHT-EBS�C���^�[�t�F�[�X�F(OUT)���ʔ���v��
 *                    
 * Version          : 1.0
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                        Description
 * ---------------------------- ----------------------------------------------------------
 *  init                        �������� (A-1)
 *  set_parm_def                �p�����[�^�f�t�H���g�Z�b�g (A-2)
 *  chk_parm_date               �p�����[�^�`�F�b�N (A-3)
 *  get_profile_info            �v���t�@�C���l���擾 (A-4)
 *  open_csv_file               CSV�t�@�C���I�[�v�� (A-5) 
 *  create_csv_rec              CSV�t�@�C���o�� (A-8)
 *  close_csv_file              CSV�t�@�C���N���[�Y (A-9)
 *  submain                     ���C�������v���V�[�W��
 *                                �ڋq�ʌ��ʔ���v��f�[�^���o (A-6)
 *                                CSV�t�@�C���ɏo�͂���֘A���擾 (A-7)
 *  main                        �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                                  �I������ (A-10)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-12-10    1.0   Syoei.Kin        �V�K�쐬
 *  2008-1-30     1.1   Syoei.Kin        ���r���[���ʔ��f
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
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg                VARCHAR2(2000);
  gn_target_cnt             NUMBER;                    -- �Ώی���
  gn_normal_cnt             NUMBER;                    -- ���팏��
  gn_error_cnt              NUMBER;                    -- �G���[����
--
  gv_from_value             VARCHAR2(20);              -- �X�V��FROM(YYYYMMDD)
  gv_to_value               VARCHAR2(20);              -- �X�V��TO(YYYYMMDD)
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
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCSO014A09C';      -- �p�b�P�[�W��
  cv_app_name            CONSTANT VARCHAR2(10)  := 'XXCSO';             -- �A�v���P�[�V�����Z�k��
  cv_appl_short_name     CONSTANT VARCHAR2(10)  := 'XXCCP';             -- �A�h�I���F���ʁEIF�̈�
--
  cv_active_status       CONSTANT VARCHAR2(1)   := 'A';                 -- �A�N�e�B�u
  cv_dumm_day_month      CONSTANT VARCHAR2(2)   := '99';                -- ���ʏꍇ�̓��ɂ��i99�j
  cv_monday_kbn_month    CONSTANT VARCHAR2(1)   := '1';                 -- �����敪�i���ʁF1�j
  cv_monday_kbn_day      CONSTANT VARCHAR2(1)   := '2';                 -- �����敪�i���ʁF2�j
--
  -- �g�[�N���R�[�h
  cv_tkn_prof_name       CONSTANT VARCHAR2(20) := 'PROF_NAME';          -- �v���t�@�C����
  cv_tkn_err_msg         CONSTANT VARCHAR2(20) := 'ERR_MSG';            -- SQL�G���[���b�Z�[�W
  cv_tkn_value           CONSTANT VARCHAR2(20) := 'VALUE';              -- ���͂��ꂽ�p�����[�^�l
  cv_tkn_status          CONSTANT VARCHAR2(20) := 'STATUS';             -- ���^�[���X�e�[�^�X(���t�����`�F�b�N����)
  cv_tkn_message         CONSTANT VARCHAR2(20) := 'MESSAGE';            -- ���^�[�����b�Z�[�W(���t�����`�F�b�N) 
  cv_tkn_from_value      CONSTANT VARCHAR2(20) := 'FROM_VALUE';         -- �X�V��FROM
  cv_tkn_to_value        CONSTANT VARCHAR2(20) := 'TO_VALUE';           -- �X�V��TO
  cv_tkn_csv_location    CONSTANT VARCHAR2(20) := 'CSV_LOCATION';       -- CSV�t�@�C���o�͐�
  cv_tkn_csv_file_name   CONSTANT VARCHAR2(20) := 'CSV_FILE_NAME';      -- CSV�t�@�C����
  cv_tkn_year_month      CONSTANT VARCHAR2(20) := 'YEAR_MONTH';         -- �N��
  cv_tkn_location_cd     CONSTANT VARCHAR2(20) := 'LOCATION_CD';        -- ���㋒�_�R�[�h
  cv_tkn_customer_cd     CONSTANT VARCHAR2(20) := 'CUSTOMER_CD';        -- �ڋq�R�[�h
  cv_tkn_root_no         CONSTANT VARCHAR2(20) := 'ROOT_NO';            -- ���[�gNo
  cv_tkn_proc_name       CONSTANT VARCHAR2(20) := 'PROCESSING_NAME';    -- ���o������
  cv_tkn_count           CONSTANT VARCHAR2(20) := 'COUNT';              -- ��������
  cv_table               CONSTANT VARCHAR2(20) := 'TABLE';              -- ��������
--
  cb_true                CONSTANT BOOLEAN := TRUE;
  cb_false               CONSTANT BOOLEAN := FALSE;
--
  -- DEBUG_LOG�p���b�Z�[�W
  cv_debug_msg1           CONSTANT VARCHAR2(200) := '<< �V�X�e�����t�擾���� >>';
  cv_debug_msg2           CONSTANT VARCHAR2(200) := 'od_sysdate = ';
  cv_debug_msg3           CONSTANT VARCHAR2(200) := '<< �Ɩ��������t�擾���� >>';
  cv_debug_msg4           CONSTANT VARCHAR2(200) := 'ld_process_date = ';
  cv_debug_msg5           CONSTANT VARCHAR2(200) := '<< �N�x�擾���� >>';
  cv_debug_msg6           CONSTANT VARCHAR2(200) := 'ln_business_year = ';
  cv_debug_msg7           CONSTANT VARCHAR2(200) := '<< �v���t�@�C���l�擾���� >>';
  cv_debug_msg9           CONSTANT VARCHAR2(200) := 'lv_file_dir    = ';
  cv_debug_msg10          CONSTANT VARCHAR2(200) := 'lv_file_name     = ';
  cv_debug_msg11          CONSTANT VARCHAR2(200) := 'lv_cntrbt_sls = ';
  cv_debug_msg12          CONSTANT VARCHAR2(200) := '<< CSV�t�@�C�����I�[�v�����܂��� >>' ;
  cv_debug_msg13          CONSTANT VARCHAR2(200) := '<< CSV�t�@�C�����N���[�Y���܂��� >>' ;
  cv_debug_msg14          CONSTANT VARCHAR2(200) := '<< ���[���o�b�N���܂��� >>' ;
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
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- CSV�o�̓f�[�^�i�[�p���R�[�h�^��`
    TYPE g_get_sales_plan_month_rtype IS RECORD(
      base_code             xxcso_account_sales_plans.base_code%TYPE,            -- ���㋒�_�R�[�h
      account_number        xxcso_account_sales_plans.account_number%TYPE,       -- �ڋq�R�[�h
      year_month            xxcso_account_sales_plans.year_month%TYPE,           -- �N��
      visit_times           NUMBER,                                              -- �K�����
      sales_plan_month_amt  xxcso_account_sales_plans.sales_plan_month_amt%TYPE, -- ���ʔ���v��
      process_date          VARCHAR2(100)                                        -- ��������
    );
  --*** �f�[�^�o�^�A�X�V��O ***
  global_ins_upd_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_ins_upd_expt,-30000);
--

--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : �������� (A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_sysdate          OUT NOCOPY VARCHAR2,  -- �V�X�e�����t
    ov_errbuf           OUT NOCOPY VARCHAR2,  -- �G���[�E���b�Z�[�W            --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,  -- ���^�[���E�R�[�h              --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W    --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'init';           -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    lv_sysdate      VARCHAR2(100);    --�V�X�e�����t
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
    --
    --�v���O�����J�n���_�̃V�X�e�����t
    lv_sysdate := TO_CHAR(SYSDATE, 'YYYY/MM/DD HH24:MI:SS');
    -- *** DEBUG_LOG ***
    -- �擾�����V�X�e�����t�����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg1  || CHR(10) ||
                 cv_debug_msg2  || lv_sysdate || CHR(10) ||
                 ''
    );
    -- �擾�����V�X�e�����t��OUT�p�����[�^�ɐݒ�
    ov_sysdate  := lv_sysdate;
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
   * Procedure Name   : set_parm_def                                  
   * Description      : �p�����[�^�f�t�H���g�Z�b�g (A-2)
   ***********************************************************************************/
  PROCEDURE set_parm_def(
    od_process_date         OUT NOCOPY DATE,            -- �Ɩ�������
    ov_errbuf               OUT NOCOPY VARCHAR2,        -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,        -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W   --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'set_parm_def';      -- �v���O������
--
    cv_param_def_set_tkn    CONSTANT VARCHAR2(100)  := 'APP-XXCSO1-00150';  -- �p�����[�^�f�t�H���g�Z�b�g
    cv_process_date_tkn     CONSTANT VARCHAR2(100)  := 'APP-XXCSO1-00011';  -- �Ɩ��������t�擾�G���[
    cv_from_value_tkn       CONSTANT VARCHAR2(100)  := 'APP-XXCSO1-00145';  -- �p�����[�^�X�V��FROM
    cv_to_value_tkn         CONSTANT VARCHAR2(100)  := 'APP-XXCSO1-00146';  -- �p�����[�^�X�V��TO
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
    ld_process_date        DATE;            -- �Ɩ�������
    lv_param_set           VARCHAR2(1000);  -- �p�����[�^�f�t�H���g�Z�b�g���b�Z�[�W���i�[
    lb_null_check          BOOLEAN;         -- NULL���f�`�F�b�N
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- =======================================
    -- �p�����[�^�X�V��FROM�ƍX�V��TO�o�� 
    -- =======================================
--
    --�X�V��FROM���b�Z�[�W�o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name
                    ,iv_name         => cv_from_value_tkn
                    ,iv_token_name1  => cv_tkn_from_value
                    ,iv_token_value1 => gv_from_value
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''           || CHR(10) ||   -- ��s�̑}��
                   gv_out_msg 
    );
    --�X�V��TO���b�Z�[�W�o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name
                    ,iv_name         => cv_to_value_tkn
                    ,iv_token_name1  => cv_tkn_to_value
                    ,iv_token_value1 => gv_to_value
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   =>     gv_out_msg ||
                 ''                  -- ��s�̑}��
    );
--
    -- =======================================================================
    -- �N���p�����[�^�u�X�V��FROM�v�u�X�V��TO�v���uNULL�v�ł��邩�ǂ������m�F 
    -- =======================================================================
--
    -- �Ɩ��������t�擾���� 
    ld_process_date := xxccp_common_pkg2.get_process_date; 
    -- *** DEBUG_LOG ***
    -- �擾�����Ɩ��������t�����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg3 || CHR(10) ||
                 cv_debug_msg4 || TO_CHAR(ld_process_date,'yyyy/mm/dd hh24:mi:ss') || CHR(10) ||
                 ''
    );
    -- �Ɩ��������t�擾�Ɏ��s�����ꍇ
    IF (ld_process_date IS NULL) THEN
      --��s�̏o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
      lv_errmsg := xxccp_common_pkg.get_msg(
              iv_application  => cv_app_name                 -- �A�v���P�[�V�����Z�k��
             ,iv_name         => cv_process_date_tkn         -- ���b�Z�[�W�R�[�h
      );
      lv_errbuf  := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- �X�V��FROM�̑��݃`�F�b�N
    IF (gv_from_value IS NULL) THEN
      gv_from_value := TO_CHAR(ld_process_date,'YYYYMMDD');
      lb_null_check := cb_true;
    END IF;
    -- �X�V��TO�̑��݃`�F�b�N
    IF (gv_to_value IS NULL) THEN
      gv_to_value := TO_CHAR(ld_process_date,'YYYYMMDD');
      lb_null_check := cb_true;
    END IF;
    --�p�����[�^�f�t�H���g�Z�b�g
    IF (lb_null_check = cb_true) THEN
      lv_param_set := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_param_def_set_tkn
                     );
      lv_errbuf  := lv_errmsg;
      fnd_file.put_line(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_param_set
      );
    END IF;
    -- �擾�����Ɩ���������OUT�p�����[�^�ɐݒ�
    od_process_date  := ld_process_date;
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
  END set_parm_def;
--
  /**********************************************************************************
   * Procedure Name   : chk_parm_date
   * Description      : �p�����[�^�`�F�b�N (A-3)
   ***********************************************************************************/
  PROCEDURE chk_parm_date(
    ov_errbuf               OUT NOCOPY VARCHAR2,        -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,        -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W   --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'chk_parm_date';     -- �v���O������
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
    cv_false               CONSTANT VARCHAR2(10)  := 'false';
    cv_date_formart_tkn    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00012';  -- ���t�����G���[
    cv_parameter_tkn       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00176';  -- �p�����[�^�������G���[
    -- *** ���[�J���ϐ� ***
    lv_format                 VARCHAR2(20);  -- ���t�̃t�H�[�}�b�g
    lb_check_date_from_value  BOOLEAN;       -- �X�V��FROM�̏������w�肳�ꂽ���t�̏����iYYYYMMDD�j�ł��邩���m�F
    lb_check_date_to_value    BOOLEAN;       -- �X�V��TO�̏������w�肳�ꂽ���t�̏����iYYYYMMDD�j�ł��邩���m�F
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    lv_format            := 'YYYYMMDD';     -- ���t�̃t�H�[�}�b�g
--
    -- ===========================
    -- ���t�����`�F�b�N 
    -- ===========================
    BEGIN
--
      --�擾�����p�����[�^�̏������w�肳�ꂽ���t�̏����iYYYYMMDD�j�ł��邩���m�F
      lb_check_date_from_value := xxcso_util_common_pkg.check_date(
                                    iv_date         => gv_from_value
                                   ,iv_date_format  => lv_format
      );
      lb_check_date_to_value   := xxcso_util_common_pkg.check_date(
                                    iv_date         => gv_to_value
                                   ,iv_date_format  => lv_format
      );     
      --���^�[���X�e�[�^�X���uFALSE�v�̏ꍇ,��O�������s��
      IF (lb_check_date_from_value = cb_false) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name               -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_date_formart_tkn       -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_value              -- �g�[�N���R�[�h1
                        ,iv_token_value1 => gv_from_value             -- �g�[�N���l1�p�����[�^
                        ,iv_token_name2  => cv_tkn_status             -- �g�[�N���R�[�h2
                        ,iv_token_value2 => cv_false                  -- �g�[�N���l2���^�[���X�e�[�^�X
                        ,iv_token_name3  => cv_tkn_message            -- �g�[�N���R�[�h3
                        ,iv_token_value3 => NULL                      -- �g�[�N���l3���^�[�����b�Z�[�W
        );
        lv_errbuf  := lv_errmsg;
        RAISE global_api_expt;
      END IF;
      IF (lb_check_date_to_value = cb_false) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name               -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_date_formart_tkn       -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_value              -- �g�[�N���R�[�h1
                        ,iv_token_value1 => gv_to_value               -- �g�[�N���l1�p�����[�^
                        ,iv_token_name2  => cv_tkn_status             -- �g�[�N���R�[�h2
                        ,iv_token_value2 => cv_false                  -- �g�[�N���l2���^�[���X�e�[�^�X
                        ,iv_token_name3  => cv_tkn_message            -- �g�[�N���R�[�h3
                        ,iv_token_value3 => NULL                      -- �g�[�N���l3���^�[�����b�Z�[�W
        );
        lv_errbuf  := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END;
--
    -- ===========================
    -- ���t�召�֌W�`�F�b�N
    -- ===========================
    BEGIN
--
      --���͂��ꂽ�p�����[�^�̒l�̑召�֌W�����������m�F
      IF (gv_from_value > gv_to_value) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name              -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_parameter_tkn         -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_from_value        -- �g�[�N���R�[�h1
                        ,iv_token_value1 => gv_from_value            -- �g�[�N���l1�X�V��FROM
                        ,iv_token_name2  => cv_tkn_to_value          -- �g�[�N���R�[�h2
                        ,iv_token_value2 => gv_to_value              -- �g�[�N���l2�X�V��TO
        );
        lv_errbuf  := lv_errmsg;
        RAISE global_api_expt;
      END IF;
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_parm_date;
--
  /**********************************************************************************
   * Procedure Name   : get_profile_info
   * Description      : �v���t�@�C���l���擾 (A-4)
   ***********************************************************************************/
  PROCEDURE get_profile_info(
    ov_file_dir             OUT NOCOPY VARCHAR2,        --XXCSO:HTT�A�g�pCSV�t�@�C���o�͐�
    ov_file_name            OUT NOCOPY VARCHAR2,        --XXCSO:HTT�A�g�pCSV�t�@�C����
    ov_errbuf               OUT NOCOPY VARCHAR2,        -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,        -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W   --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100)  := 'get_profile_info';          -- �v���O������
--
    cv_intf_file_name   CONSTANT VARCHAR2(100)  := 'APP-XXCSO1-00152';          -- �C���^�[�t�F�[�X�t�@�C����
    cv_profile_get_tkn  CONSTANT VARCHAR2(100)  := 'APP-XXCSO1-00014';          -- �v���t�@�C���擾�G���[
    cv_tkn_csv_name     CONSTANT VARCHAR2(100)  := 'CSV_FILE_NAME';
      -- �C���^�[�t�F�[�X�t�@�C�����g�[�N����
    cv_file_dir         CONSTANT VARCHAR2(100)  := 'XXCSO1_HHT_OUT_CSV_DIR';
      --XXCSO:HTT�A�g�pCSV�t�@�C���o�͐�
    cv_file_name        CONSTANT VARCHAR2(100)  := 'XXCSO1_HHT_OUT_CSV_MONTH_PLAN';
      --XXCSO:HTT�A�g�pCSV�t�@�C����
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
    lv_file_dir       VARCHAR2(1000);      -- XXCSO:HTT�A�g�pCSV�t�@�C���o�͐�
    lv_file_name      VARCHAR2(1000);      -- XXCSO:HTT�A�g�pCSV�t�@�C����
    lv_msg_set        VARCHAR2(1000);      -- ���b�Z�[�W�i�[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================
    -- �v���t�@�C���l���擾
    -- ===============================
--
    fnd_profile.get(
                  cv_file_dir
                 ,lv_file_dir
    );  --CSV�t�@�C���o�͐�̒l�擾
    fnd_profile.get(
                  cv_file_name
                 ,lv_file_name
    );  --CSV�t�@�C�����̒l�擾
    -- *** DEBUG_LOG ***
    -- �擾�����v���t�@�C���l�����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg7  || CHR(10) ||
                 cv_debug_msg9  || lv_file_dir    || CHR(10) ||
                 cv_debug_msg10 || lv_file_name     || CHR(10) ||
                 ''
    );
    --�߂�l���uNULL�v�ł������ꍇ,��O�������s��
    --XXCSO:HTT�A�g�pCSV�t�@�C���o�͐�
    IF (lv_file_dir IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name              -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_profile_get_tkn       -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_prof_name         -- �g�[�N���R�[�h1
                        ,iv_token_value1 => cv_file_dir              -- �g�[�N���l1CSV�t�@�C���o�͐�
      );
      lv_errbuf  := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --XXCSO:HTT�A�g�pCSV�t�@�C����
    IF (lv_file_name IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name              -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_profile_get_tkn       -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_prof_name         -- �g�[�N���R�[�h1
                        ,iv_token_value1 => cv_file_name             -- �g�[�N���l1CSV�t�@�C����
      );
      lv_errbuf  := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --�C���^�[�t�F�[�X�t�@�C�������b�Z�[�W�o��
    lv_msg_set := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name
                    ,iv_name         => cv_intf_file_name
                    ,iv_token_name1  => cv_tkn_csv_name
                    ,iv_token_value1 => lv_file_name
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''           || CHR(10) ||   -- ��s�̑}��
                   lv_msg_set ||
                 ''           || CHR(10)         -- ��s�̑}��
    );
    -- �擾����CSV�t�@�C���o�͐�ƃt�@�C������OUT�p�����[�^�ɐݒ�
    ov_file_dir   := lv_file_dir;       --XXCSO:HTT�A�g�pCSV�t�@�C���o�͐�
    ov_file_name  := lv_file_name;      --XXCSO:HTT�A�g�pCSV�t�@�C����
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
   * Description      : CSV�t�@�C���I�[�v�� (A-5)
   ***********************************************************************************/
  PROCEDURE open_csv_file(
    iv_file_dir             IN  VARCHAR2,               -- XXCSO:HTT�A�g�pCSV�t�@�C���o�͐�
    iv_file_name            IN  VARCHAR2,               -- XXCSO:HTT�A�g�pCSV�t�@�C����
    ov_errbuf               OUT NOCOPY VARCHAR2,        -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,        -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'open_csv_file';     -- �v���O������
--
    cv_open_writer          CONSTANT VARCHAR2(100)  := 'W';                 -- ���o�̓��[�h
    cv_csv_in_tkn           CONSTANT VARCHAR2(100)  := 'APP-XXCSO1-00123';  -- CSV�t�@�C���c���G���[
    cv_csv_open_tkn         CONSTANT VARCHAR2(100)  := 'APP-XXCSO1-00015';  -- CSV�t�@�C���I�[�v���G���[

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
    lv_file_dir       VARCHAR2(1000);      --XXCSO:HTT�A�g�pCSV�t�@�C���o�͐�
    lv_file_name      VARCHAR2(1000);      --XXCSO:HTT�A�g�pCSV�t�@�C����
    lv_exists         BOOLEAN;             --���݃`�F�b�N����
    lv_file_length    VARCHAR2(1000);      --�t�@�C���T�C�Y
    lv_blocksize      VARCHAR2(1000);      --�u���b�N�T�C�Y
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
    -- IN�p�����[�^�����[�J���ϐ��ɑ��
    lv_file_dir   := iv_file_dir;       --XXCSO:HTT�A�g�pCSV�t�@�C���o�͐�
    lv_file_name  := iv_file_name;      --XXCSO:HTT�A�g�pCSV�t�@�C����
    -- ========================
    -- CSV�t�@�C�����݃`�F�b�N 
    -- ========================
    UTL_FILE.FGETATTR(
                  location    => lv_file_dir
                 ,filename    => lv_file_name
                 ,fexists     => lv_exists
                 ,file_length => lv_file_length
                 ,block_size  => lv_blocksize
    );
    --CSV�t�@�C�������݂����ꍇ
    IF (lv_exists = cb_true) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name              -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_csv_in_tkn            -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_csv_location      -- �g�[�N���R�[�h1
                        ,iv_token_value1 => lv_file_dir              -- �g�[�N���l1CSV�t�@�C���o�͐�
                        ,iv_token_name2  => cv_tkn_csv_file_name     -- �g�[�N���R�[�h1
                        ,iv_token_value2 => lv_file_name             -- �g�[�N���l1CSV�t�@�C����
      );
      lv_errbuf := lv_errmsg;
      RAISE file_err_expt;
    END IF;
    BEGIN
      -- ========================
      -- CSV�t�@�C���I�[�v�� 
      -- ========================
        gf_file_hand := UTL_FILE.FOPEN(
                           location   => lv_file_dir
                          ,filename   => lv_file_name
                          ,open_mode  => cv_open_writer
        );
      -- *** DEBUG_LOG ***
      -- �t�@�C���I�[�v���������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg12   || CHR(10)   ||
                   cv_debug_msg_fnm || lv_file_name || CHR(10) ||
                   ''
      );
      EXCEPTION
        WHEN UTL_FILE.INVALID_PATH       OR       -- �t�@�C���p�X�s���G���[
             UTL_FILE.INVALID_MODE       OR       -- open_mode�p�����[�^�s���G���[
             UTL_FILE.INVALID_OPERATION  OR       -- �I�[�v���s�\�G���[
             UTL_FILE.INVALID_MAXLINESIZE  THEN   -- MAX_LINESIZE�l�����G���[
          -- �G���[���b�Z�[�W�擾
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name              -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_csv_open_tkn          -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_csv_location      -- �g�[�N���R�[�h1
                        ,iv_token_value1 => lv_file_dir              -- �g�[�N���l1CSV�t�@�C���o�͐�
                        ,iv_token_name2  => cv_tkn_csv_file_name     -- �g�[�N���R�[�h1
                        ,iv_token_value2 => lv_file_name             -- �g�[�N���l1CSV�t�@�C����
          );
          lv_errbuf := lv_errmsg;
          RAISE file_err_expt;
    END;
--
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
                   cv_debug_msg_fnm  || iv_file_name   || CHR(10) ||
                   ''
      );
      END IF;
--
      -- �擾�����p�����[�^��OUT�p�����[�^�ɐݒ�
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
                   cv_debug_msg_fnm  || iv_file_name   || CHR(10) ||
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
                   cv_debug_msg_fnm  || iv_file_name   || CHR(10) ||
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
                   cv_debug_msg_fnm  || iv_file_name   || CHR(10) ||
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
  /**********************************************************************************
   * Procedure Name   : create_csv_rec
   * Description      : CSV�t�@�C���o�� (A-8)
   ***********************************************************************************/
  PROCEDURE create_csv_rec(
    it_get_rec  IN  g_get_sales_plan_month_rtype,  -- ���ʔ���v����i�[���郌�R�[�h
    ov_errbuf   OUT NOCOPY VARCHAR2,               -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode  OUT NOCOPY VARCHAR2,               -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg   OUT NOCOPY VARCHAR2                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'create_csv_rec';       -- �v���O������
    cv_sep_com              CONSTANT VARCHAR2(3)    := ',';
    cv_sep_wquot            CONSTANT VARCHAR2(3)    := '"';
--
    cv_csv_create_tkn       CONSTANT VARCHAR2(100)  := 'APP-XXCSO1-00065';     -- CSV�t�@�C���o�̓G���[
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--_
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    lv_data          VARCHAR2(5000);                -- �ҏW�f�[�^
    lt_get_rec       g_get_sales_plan_month_rtype;  -- ���ʔ���v����i�[���郌�R�[�h
    -- *** ���[�J����O ***
    file_put_line_expt             EXCEPTION;          -- �f�[�^�o�͏�����O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- IN�p�����[�^�����[�J���ϐ��ɑ��
    lt_get_rec  := it_get_rec;       -- ���ʔ���v����i�[���郌�R�[�h
    BEGIN
--
      --�f�[�^�쐬
      lv_data := cv_sep_wquot || TO_CHAR(lt_get_rec.base_code) || cv_sep_wquot            -- ���㋒�_�R�[�h
        || cv_sep_com || cv_sep_wquot || lt_get_rec.account_number || cv_sep_wquot        -- �ڋq�R�[�h
        || cv_sep_com || lt_get_rec.year_month                                            -- �N��
        || cv_sep_com || TO_CHAR(lt_get_rec.visit_times)                                  -- �K�����
        || cv_sep_com || TO_CHAR(lt_get_rec.sales_plan_month_amt)                         -- ���ʔ���v��
        || cv_sep_com || cv_sep_wquot || lt_get_rec.process_date || cv_sep_wquot;         -- ��������
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
                      iv_application  => cv_app_name                       --�A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_csv_create_tkn                 --���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_customer_cd                --�g�[�N���R�[�h1
                     ,iv_token_value1 => lt_get_rec.account_number         --�g�[�N���l1�ڋq�R�[�h
                     ,iv_token_name2  => cv_tkn_location_cd                --�g�[�N���R�[�h2
                     ,iv_token_value2 => lt_get_rec.base_code              --�g�[�N���l2���㋒�_�R�[�h
                     ,iv_token_name3  => cv_tkn_year_month                 --�g�[�N���R�[�h3
                     ,iv_token_value3 => lt_get_rec.year_month             --�g�[�N���l3�N��
                     ,iv_token_name4  => cv_tkn_err_msg                    --�g�[�N���R�[�h4
                     ,iv_token_value4 => SQLERRM                           --�g�[�N���l4
                    );
        lv_errbuf := lv_errmsg;
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
   * Description      : CSV�t�@�C���N���[�Y���� (A-9)
   ***********************************************************************************/
  PROCEDURE close_csv_file(
     iv_file_dir       IN  VARCHAR2         -- CSV�t�@�C���o�͐�
    ,iv_file_name      IN  VARCHAR2         -- CSV�t�@�C����
    ,ov_errbuf         OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W              --# �Œ� #
    ,ov_retcode        OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h                --# �Œ� #
    ,ov_errmsg         OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W    --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'close_csv_file';    -- �v���O������
--
    cv_csv_close_tkn    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00018';  -- CSV�t�@�C���N���[�Y�G���[
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
        ,buff   => cv_debug_msg13   || CHR(10)   ||
                   cv_debug_msg_fnm || iv_file_name || CHR(10) ||
                   ''
      );
      EXCEPTION
        WHEN UTL_FILE.WRITE_ERROR          OR     -- �I�y���[�e�B���O�V�X�e���G���[
             UTL_FILE.INVALID_FILEHANDLE   THEN   -- �t�@�C���E�n���h�������G���[
          -- �G���[���b�Z�[�W�擾
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_csv_close_tkn             --���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_csv_location          --�g�[�N���R�[�h1
                        ,iv_token_value1 => iv_file_dir                  --�g�[�N���l1
                        ,iv_token_name2  => cv_tkn_csv_file_name         --�g�[�N���R�[�h1
                        ,iv_token_value2 => iv_file_name                 --�g�[�N���l1
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
          file =>gf_file_hand
        );
--
      -- *** DEBUG_LOG ***
      -- �t�@�C���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err1 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_file_name   || CHR(10) ||
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
                   cv_debug_msg_fnm  || iv_file_name   || CHR(10) ||
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
                   cv_debug_msg_fnm  || iv_file_name   || CHR(10) ||
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
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err4 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_file_name   || CHR(10) ||
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
    ,ov_errmsg           OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W    --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name            CONSTANT VARCHAR2(100) := 'submain';           -- �v���O������
--
    cv_app_month_plan_tkn  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00024';  -- �ڋq�ʌ��ʔ���v��f�[�^���o�G���[
    cv_app_day_plan_tkn    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00062';  -- �ڋq�ʓ��ʔ���v��f�[�^���o�G���[
    cv_csv_0_tkn           CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00224';  -- CSV�t�@�C���o��0���G���[
    cv_route_get_tkn       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00063';  -- ���[�gNo�擾���ʊ֐��G���[
    cv_route_visit_tkn     CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00064';  -- ���[�gNo�K������Z�o�������ʊ֐��G���[
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
---- *** ���[�J���萔 ***
    cv_sep_com              CONSTANT VARCHAR2(3)     := ',';
    cv_sep_wquot            CONSTANT VARCHAR2(3)     := '"';
    cv_app_month_plans      CONSTANT VARCHAR2(100)   := '�ڋq�ʔ���v��e�[�u��';
    cv_app_day_plans        CONSTANT VARCHAR2(100)   := '�ڋq�ʓ��ʔ���v��f�[�^';
    cv_app_day_plans_0      CONSTANT VARCHAR2(100)   := '�ڋq�ʓ��ʌv��f�[�^�i���ʌv�悪0(�[���j�ȏ�)';
    cv_app_route_number     CONSTANT VARCHAR2(100)   := '���[�gNo';
    -- *** ���[�J���ϐ� ***
    lv_sysdate             VARCHAR2(100);                                      -- �V�X�e�����t
    ld_process_date        DATE;                                               -- �Ɩ�������
    lv_target_cnt          NUMBER;                                             -- �����Ώی����i�[
    ln_table_no            NUMBER;                                             -- ���R�[�h�ɑ΂���z��\�̓�
    lb_csv_putl_rec        VARCHAR2(2000);                                     -- CSV�t�@�C���o�͔��f
    lv_file_dir            VARCHAR2(2000);                                     -- CSV�t�@�C���o�͐�
    lv_file_name           VARCHAR2(2000);                                     -- CSV�t�@�C����
    lv_data                VARCHAR2(5000);                                     -- �ҏW�f�[�^
    lv_process_date        VARCHAR2(100);                                      -- �Ɩ�������
    lv_process_date_add    VARCHAR2(100);                                      -- �Ɩ�������(����)
    lv_process_date_1      DATE;                                               -- �Ɩ�������+1
    lv_process_date_trunc  DATE;                                               -- �Ɩ�������(TRUNC)
    lv_taget_cnt           NUMBER;                                             -- ���[�v����
    ln_count               NUMBER;                                             -- �J�E���g
    ln_count_1             NUMBER;                                             -- �J�E���g
    lv_sub_retcode         VARCHAR2(1);                                        -- �T�[�u���C���p���^�[���E�R�[�h
    lv_sub_msg             VARCHAR2(5000);                                     -- �x���p���b�Z�[�W
    lv_sub_buf             VARCHAR2(5000);                                     -- �x���p�G���[�E���b�Z�[�W
    lv_route_acc_num       xxcso_cust_routes_v2.account_number%TYPE;           -- ���[�gNo�擾�p�ڋq�R�[�h
    lt_route_no_v          xxcso_cust_routes_v2.route_number%TYPE;             -- ���[�gNo(view)
    lt_route_no            xxcso_in_route_no.route_no%TYPE;                    -- ���[�gNo
    ln_visit_times         NUMBER;                                             -- �K�����
    ln_day_ln_month        NUMBER;                                             -- �Y�����̓���
    lt_plan_day_amt_v      xxcso_account_sales_plans.sales_plan_day_amt%TYPE;  -- ���ʔ���v����z(�K������擾�p)
    lt_plan_month_amt_v    xxcso_in_sales_plan_month.sales_plan_amt%TYPE;      -- ���Ԕ���v����z(�K������擾�p)
    lv_year_month_v        VARCHAR2(6);                                        -- �N��(�K������擾�p)
    -- �t�@�C���I�[�v���m�F�߂�l�i�[
    lb_fopn_retcd   BOOLEAN;
    -- ���b�Z�[�W�o�͗p
    lv_msg          VARCHAR2(2000);
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR xsasp_data_cur
    IS
      SELECT     xsasp.base_code base_code                         -- ���㋒�_�R�[�h
                ,xsasp.account_number account_number               -- �ڋq�R�[�h
                ,xsasp.year_month year_month                       -- �N��
                ,xsasp.sales_plan_month_amt sales_plan_month_amt   -- ���ʔ���v��
      FROM       xxcso_account_sales_plans xsasp                   -- �ڋq�ʔ���v��e�[�u��
      WHERE      xsasp.year_month BETWEEN lv_process_date AND lv_process_date_add
        AND      TO_CHAR(xsasp.last_update_date,'YYYYMMDD') BETWEEN gv_from_value AND gv_to_value
        AND      xsasp.month_date_div = cv_monday_kbn_month
      ORDER BY   xsasp.base_code        ASC                        -- ���㋒�_�R�[�h
                ,xsasp.account_number   ASC                        -- �ڋq�R�[�h
                ,xsasp.year_month       ASC;                       -- �N��
    -- *** ���[�J���E���R�[�h ***
    l_xsasp_data_rec   xsasp_data_cur%ROWTYPE;
    l_get_rec          g_get_sales_plan_month_rtype;
    -- *** ���[�J���E��O ***
    select_error_expt EXCEPTION;
    lv_process_expt   EXCEPTION;
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
--
    -- ================================
    -- A-1.�������� 
    -- ================================
    init(
      ov_sysdate          => lv_sysdate,  -- �V�X�e�����t
      ov_errbuf           => lv_errbuf,   -- �G���[�E���b�Z�[�W            --# �Œ� #
      ov_retcode          => lv_retcode,  -- ���^�[���E�R�[�h              --# �Œ� #
      ov_errmsg           => lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    ); 
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ================================
    -- A-2.�p�����[�^�f�t�H���g�Z�b�g 
    -- ================================
    set_parm_def(
      od_process_date     => ld_process_date,     -- �Ɩ�������
      ov_errbuf           => lv_errbuf,           -- �G���[�E���b�Z�[�W            --# �Œ� #
      ov_retcode          => lv_retcode,          -- ���^�[���E�R�[�h              --# �Œ� #
      ov_errmsg           => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W    --# �Œ� #
    );
    lv_process_date       := TO_CHAR(ld_process_date, 'YYYYMM');
    lv_process_date_add   := TO_CHAR(ADD_MONTHS(ld_process_date, 1), 'YYYYMM');
    lv_process_date_1     := ld_process_date+1;
    lv_process_date_trunc := TRUNC(lv_process_date_1);
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ================================
    -- A-3.�p�����[�^�`�F�b�N 
    -- ================================
    chk_parm_date(
      ov_errbuf           => lv_errbuf,         -- �G���[�E���b�Z�[�W            --# �Œ� #
      ov_retcode          => lv_retcode,        -- ���^�[���E�R�[�h              --# �Œ� #
      ov_errmsg           => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W    --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =================================================
    -- A-4.�v���t�@�C���l���擾 
    -- =================================================
    get_profile_info(
       ov_file_dir   => lv_file_dir   -- CSV�t�@�C���o�͐�
      ,ov_file_name  => lv_file_name  -- CSV�t�@�C����
      ,ov_errbuf     => lv_errbuf     -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode    => lv_retcode    -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg     => lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W    --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =================================================
    -- A-5.CSV�t�@�C���I�[�v�� 
    -- =================================================
    open_csv_file(
       iv_file_dir  => lv_file_dir   -- CSV�t�@�C���o�͐�
      ,iv_file_name => lv_file_name  -- CSV�t�@�C����
      ,ov_errbuf    => lv_errbuf     -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode   => lv_retcode    -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg    => lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W    --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    -- �J�[�\���I�[�v��
    OPEN xsasp_data_cur;
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
--
      BEGIN
--
        BEGIN
          FETCH xsasp_data_cur INTO l_xsasp_data_rec;
--
        EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_app_name               -- �A�v���P�[�V�����Z�k��
                                ,iv_name         => cv_app_month_plan_tkn     -- ���b�Z�[�W�R�[�h
                                ,iv_token_name1  => cv_table                  -- �g�[�N���R�[�h1
                                ,iv_token_value1 => cv_app_month_plans        -- �g�[�N���l1�p�����[�^
                                ,iv_token_name2  => cv_tkn_err_msg            -- �g�[�N���R�[�h2
                                ,iv_token_value2 => SQLERRM                   -- �g�[�N���l2���^�[���X�e�[�^�X
                );
            lv_errbuf  := lv_errmsg;
          RAISE lv_process_expt;
        END;
--
        -- �f�[�^������
        lv_sub_msg := NULL;
        lv_sub_buf := NULL;
        -- ���R�[�h�ϐ�������
        l_get_rec := NULL;
        -- �����Ώی����i�[
        gn_target_cnt := xsasp_data_cur%ROWCOUNT;
        -- �Ώی�����O���̏ꍇ
        EXIT WHEN xsasp_data_cur%NOTFOUND
        OR  xsasp_data_cur%ROWCOUNT = 0;
        -- �擾�f�[�^���i�[
        l_get_rec.base_code             := l_xsasp_data_rec.base_code;             -- ���㋒�_�R�[�h
        l_get_rec.account_number        := l_xsasp_data_rec.account_number;        -- �ڋq�R�[�h
        l_get_rec.year_month            := l_xsasp_data_rec.year_month;            -- �N��
        l_get_rec.sales_plan_month_amt  := l_xsasp_data_rec.sales_plan_month_amt;  --���ʔ���v��
        l_get_rec.process_date          := lv_sysdate;                             -- ��������
--
        -- ================================================================
        -- A-7 CSV�t�@�C���ɏo�͂���֘A���擾
        -- ================================================================
        -- ���Y����v��N���̓��ʌv��f�[�^�𒊏o
--
        BEGIN     
          SELECT COUNT(*)
          INTO ln_count
          FROM   xxcso_account_sales_plans xsasp
          WHERE  xsasp.month_date_div = cv_monday_kbn_day
            AND  xsasp.base_code = l_get_rec.base_code
            AND  xsasp.account_number = l_get_rec.account_number
            AND  xsasp.year_month = l_get_rec.year_month;
--
        EXCEPTION
          WHEN OTHERS THEN
            lv_sub_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_app_day_plan_tkn           -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_proc_name              -- �g�[�N���R�[�h1
                      ,iv_token_value1 => cv_app_day_plans              -- �g�[�N���l1�p�����[�^
                      ,iv_token_name2  => cv_tkn_location_cd            -- �g�[�N���R�[�h2
                      ,iv_token_value2 => TO_CHAR(l_get_rec.base_code)  -- �g�[�N���l2���㋒�_�R�[�h
                      ,iv_token_name3  => cv_tkn_customer_cd            -- �g�[�N���R�[�h3
                      ,iv_token_value3 => l_get_rec.account_number      -- �g�[�N���l3�ڋq�R�[�h
                      ,iv_token_name4  => cv_tkn_year_month             -- �g�[�N���R�[�h4
                      ,iv_token_value4 => l_get_rec.year_month          -- �g�[�N���l4�N��
                      ,iv_token_name5  => cv_tkn_err_msg                -- �g�[�N���R�[�h5
                      ,iv_token_value5 => SQLERRM                       -- �g�[�N���l5
                );
            lv_sub_buf     := lv_sub_msg;
          RAISE select_error_expt;
        END;
--
        -- ================================================================
        -- �K������擾
        -- ================================================================
        -- ���o����������1���ȏ�̏ꍇ
        IF (ln_count > 0) THEN
--
          BEGIN
            SELECT COUNT(*)
            INTO ln_count_1
            FROM   xxcso_account_sales_plans xsasp
            WHERE  xsasp.month_date_div = cv_monday_kbn_day
              AND  xsasp.sales_plan_day_amt > 0
              AND  xsasp.base_code = l_get_rec.base_code
              AND  xsasp.account_number = l_get_rec.account_number
              AND  xsasp.year_month = l_get_rec.year_month;
            --
            ln_visit_times := ln_count_1;
--
          EXCEPTION
          WHEN OTHERS THEN
            lv_sub_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_app_day_plan_tkn           -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_proc_name              -- �g�[�N���R�[�h1
                    ,iv_token_value1 => cv_app_day_plans_0            -- �g�[�N���l1�p�����[�^
                    ,iv_token_name2  => cv_tkn_location_cd            -- �g�[�N���R�[�h2
                    ,iv_token_value2 => TO_CHAR(l_get_rec.base_code)  -- �g�[�N���l2���㋒�_�R�[�h
                    ,iv_token_name3  => cv_tkn_customer_cd            -- �g�[�N���R�[�h3
                    ,iv_token_value3 => l_get_rec.account_number      -- �g�[�N���l3�ڋq�R�[�h
                    ,iv_token_name4  => cv_tkn_year_month             -- �g�[�N���R�[�h4
                    ,iv_token_value4 => l_get_rec.year_month          -- �g�[�N���l4�N��
                    ,iv_token_name5  => cv_tkn_err_msg                -- �g�[�N���R�[�h5
                    ,iv_token_value5 => SQLERRM                       -- �g�[�N���l5
                  );
            lv_sub_buf  := lv_sub_msg;
            RAISE select_error_expt;
          END;
--
        -- ���o����������0���̏ꍇ
        ELSIF(ln_count = 0) THEN
          lv_route_acc_num := l_get_rec.account_number;
          -- ���[�gNo�𒊏o
--
          BEGIN
            SELECT xxcrv.ROUTE_NUMBER
            INTO   lt_route_no_v  
            FROM   xxcso_cust_routes_v xxcrv
            WHERE  xxcrv.account_number = lv_route_acc_num
              AND  lv_process_date_trunc BETWEEN TRUNC(xxcrv.start_date_active)
                      AND TRUNC(NVL(xxcrv.end_date_active,(lv_process_date_1)));
--
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              lt_route_no_v := NULL;
            WHEN OTHERS THEN
              lv_sub_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_app_day_plan_tkn           -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_proc_name              -- �g�[�N���R�[�h1
                    ,iv_token_value1 => cv_app_route_number           -- �g�[�N���l1�p�����[�^
                    ,iv_token_name2  => cv_tkn_location_cd            -- �g�[�N���R�[�h2
                    ,iv_token_value2 => TO_CHAR(l_get_rec.base_code)  -- �g�[�N���l2���㋒�_�R�[�h
                    ,iv_token_name3  => cv_tkn_customer_cd            -- �g�[�N���R�[�h3
                    ,iv_token_value3 => l_get_rec.account_number      -- �g�[�N���l3�ڋq�R�[�h
                    ,iv_token_name4  => cv_tkn_year_month             -- �g�[�N���R�[�h4
                    ,iv_token_value4 => l_get_rec.year_month          -- �g�[�N���l4�N��
                    ,iv_token_name5  => cv_tkn_err_msg                -- �g�[�N���R�[�h5
                    ,iv_token_value5 => SQLERRM                       -- �g�[�N���l5
                  );
              lv_sub_buf  := lv_sub_msg;
              RAISE select_error_expt;
          END;
--
          IF (lt_route_no_v IS NULL) THEN
            ln_visit_times := 0;
          ELSE
            -- �K������擾�p�ϐ�
            lt_route_no         := lt_route_no_v;
            lt_plan_month_amt_v := l_get_rec.sales_plan_month_amt;
            lv_year_month_v     := l_get_rec.year_month;
            --
            xxcso_route_common_pkg.distribute_sales_plan(
                   iv_year_month             => lv_year_month_v
                  ,it_sales_plan_amt         => lt_plan_month_amt_v
                  ,it_route_number           => lt_route_no
                  ,on_day_on_month           => ln_day_ln_month
                  ,on_visit_daytimes         => ln_visit_times
                  ,ot_sales_plan_day_amt_1   => lt_plan_day_amt_v
                  ,ot_sales_plan_day_amt_2   => lt_plan_day_amt_v
                  ,ot_sales_plan_day_amt_3   => lt_plan_day_amt_v
                  ,ot_sales_plan_day_amt_4   => lt_plan_day_amt_v
                  ,ot_sales_plan_day_amt_5   => lt_plan_day_amt_v
                  ,ot_sales_plan_day_amt_6   => lt_plan_day_amt_v
                  ,ot_sales_plan_day_amt_7   => lt_plan_day_amt_v
                  ,ot_sales_plan_day_amt_8   => lt_plan_day_amt_v
                  ,ot_sales_plan_day_amt_9   => lt_plan_day_amt_v
                  ,ot_sales_plan_day_amt_10  => lt_plan_day_amt_v
                  ,ot_sales_plan_day_amt_11  => lt_plan_day_amt_v
                  ,ot_sales_plan_day_amt_12  => lt_plan_day_amt_v
                  ,ot_sales_plan_day_amt_13  => lt_plan_day_amt_v
                  ,ot_sales_plan_day_amt_14  => lt_plan_day_amt_v
                  ,ot_sales_plan_day_amt_15  => lt_plan_day_amt_v
                  ,ot_sales_plan_day_amt_16  => lt_plan_day_amt_v
                  ,ot_sales_plan_day_amt_17  => lt_plan_day_amt_v
                  ,ot_sales_plan_day_amt_18  => lt_plan_day_amt_v
                  ,ot_sales_plan_day_amt_19  => lt_plan_day_amt_v
                  ,ot_sales_plan_day_amt_20  => lt_plan_day_amt_v
                  ,ot_sales_plan_day_amt_21  => lt_plan_day_amt_v
                  ,ot_sales_plan_day_amt_22  => lt_plan_day_amt_v
                  ,ot_sales_plan_day_amt_23  => lt_plan_day_amt_v
                  ,ot_sales_plan_day_amt_24  => lt_plan_day_amt_v
                  ,ot_sales_plan_day_amt_25  => lt_plan_day_amt_v
                  ,ot_sales_plan_day_amt_26  => lt_plan_day_amt_v
                  ,ot_sales_plan_day_amt_27  => lt_plan_day_amt_v
                  ,ot_sales_plan_day_amt_28  => lt_plan_day_amt_v
                  ,ot_sales_plan_day_amt_29  => lt_plan_day_amt_v
                  ,ot_sales_plan_day_amt_30  => lt_plan_day_amt_v
                  ,ot_sales_plan_day_amt_31  => lt_plan_day_amt_v
                  ,ov_errbuf                 => lv_sub_buf
                  ,ov_retcode                => lv_sub_retcode
                  ,ov_errmsg                 => lv_sub_msg
            );
            IF (lv_sub_retcode = cv_status_error) THEN
              lv_sub_msg := xxccp_common_pkg.get_msg(
                                   iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                                  ,iv_name         => cv_route_visit_tkn            -- ���b�Z�[�W�R�[�h
                                  ,iv_token_name1  => cv_tkn_root_no                -- �g�[�N���R�[�h1
                                  ,iv_token_value1 => TO_CHAR(lt_route_no)          -- �g�[�N���l1���[�gNo
                                  ,iv_token_name2  => cv_tkn_location_cd            -- �g�[�N���R�[�h2
                                  ,iv_token_value2 => TO_CHAR(l_get_rec.base_code)  -- �g�[�N���l2���㋒�_�R�[�h
                                  ,iv_token_name3  => cv_tkn_customer_cd            -- �g�[�N���R�[�h3
                                  ,iv_token_value3 => l_get_rec.account_number      -- �g�[�N���l4�ڋq�R�[�h
                                  ,iv_token_name4  => cv_tkn_year_month             -- �g�[�N���R�[�h4
                                  ,iv_token_value4 => l_get_rec.year_month          -- �g�[�N���l4�N��
                  );
              lv_sub_buf  := lv_sub_msg;
              RAISE select_error_expt;
            END IF;
          END IF;
        END IF;
        -- �K��������i�[
        l_get_rec.visit_times := ln_visit_times;
  --
        -- ========================================
        -- A-8.CSV�t�@�C���o�� 
        -- ========================================
        create_csv_rec(
          it_get_rec                    =>  l_get_rec               -- �ڋq�ʌ��ʔ���f�[�^���i�[���郌�R�[�h
         ,ov_errbuf                     =>  lv_sub_buf              -- �G���[�E���b�Z�[�W
         ,ov_retcode                    =>  lv_sub_retcode          -- ���^�[���E�R�[�h
         ,ov_errmsg                     =>  lv_sub_msg              -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
        IF (lv_sub_retcode = cv_status_error) THEN
          RAISE select_error_expt;
        END IF;
        --���������J�E���g
        gn_normal_cnt := gn_normal_cnt + 1;
--
      EXCEPTION
        -- *** �f�[�^���o���̃G���[��O�n���h�� ***
        WHEN lv_process_expt THEN
          RAISE global_process_expt;
        -- *** �f�[�^���o���̌x����O�n���h�� ***
        WHEN select_error_expt THEN
          --�G���[�����J�E���g
          gn_error_cnt   := gn_error_cnt + 1;
          --
          lv_sub_retcode := cv_status_warn;
          ov_retcode     := lv_sub_retcode;
          --�x���o��
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_sub_msg                  --���[�U�[�E�G���[���b�Z�[�W
          );
          fnd_file.put_line(
             which  => FND_FILE.LOG
            ,buff   => cv_pkg_name||cv_msg_cont||
                       cv_prg_name||cv_msg_part||
                       lv_sub_buf                  --�G���[���b�Z�[�W
          );
      END;
--
    END LOOP get_data_loop;
--
    --�o�͌������O���̏ꍇ�A���b�Z�[�W���o�͂���
    IF (gn_target_cnt = 0) THEN
      gv_out_msg  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_csv_0_tkn                 --���b�Z�[�W�R�[�h
                   );
      lv_errbuf  := gv_out_msg;
      -- ���b�Z�[�W�o��
      fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg 
      );
    END IF;
--
    -- �J�[�\���N���[�Y
    CLOSE xsasp_data_cur;
    -- *** DEBUG_LOG ***
    -- �J�[�\���N���[�Y�������Ƃ����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg_ccls1 || CHR(10) ||
                 ''
    );
--
    -- ========================================
    -- A-9.CSV�t�@�C���N���[�Y  
    -- ========================================
--
    close_csv_file(
       iv_file_dir   => lv_file_dir   -- CSV�t�@�C���o�͐�
      ,iv_file_name  => lv_file_name  -- CSV�t�@�C����
      ,ov_errbuf     => lv_errbuf     -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode    => lv_retcode    -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg     => lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W    --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
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
        -- *** DEBUG_LOG ***
        -- �t�@�C���N���[�Y�������Ƃ����O�o��
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_fcls || CHR(10) ||
                     cv_prg_name       || cv_msg_part ||
                     cv_debug_msg_err6 || cv_msg_part ||
                     cv_debug_msg_fnm  || lv_file_name   || CHR(10) ||
                     ''
        );
      END IF;
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (xsasp_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE xsasp_data_cur;
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
                     cv_debug_msg_err3 || cv_msg_part ||
                     cv_debug_msg_fnm  || lv_file_name   || CHR(10) ||
                     ''
        );
      END IF;
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (xsasp_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE xsasp_data_cur;
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
                     cv_debug_msg_fnm  || lv_file_name   || CHR(10) ||
                     ''
        );
      END IF;
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (xsasp_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE xsasp_data_cur;
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
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
     errbuf              OUT NOCOPY VARCHAR2     -- �G���[�E���b�Z�[�W  --# �Œ� #
    ,retcode             OUT NOCOPY VARCHAR2     -- ���^�[���E�R�[�h    --# �Œ� #
    ,iv_from_value       IN VARCHAR2             -- �X�V��FROM(YYYYMMDD)
    ,iv_to_value         IN VARCHAR2             -- �X�V��TO(YYYYMMDD)
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
    -- IN�p�����[�^�����[�J���ϐ��ɑ��
    gv_from_value        := iv_from_value;     -- �X�V��FROM(YYYYMMDD)
    gv_to_value          := iv_to_value;       -- �X�V��TO(YYYYMMDD)
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
    -- A-9.�I������ 
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
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
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
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCSO014A09C;
/
