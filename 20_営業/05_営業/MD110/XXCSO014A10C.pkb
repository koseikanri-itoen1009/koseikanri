CREATE OR REPLACE PACKAGE BODY APPS.XXCSO014A10C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO014A10C(spec)
 * Description      : �K��\��t�@�C����HHT�֘A�g���邽�߂�CSV�t�@�C�����쐬���܂��B
 *                    
 * MD.050           : MD050_IPO_CSO_014_A10_HHT-EBS�C���^�[�t�F�[�X�F(OUT)�K��\��t�@�C��
 *                    
 * Version          : 1.0
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                        Description
 * ---------------------------- ----------------------------------------------------------
 *  init                        �������� (A-1)
 *  chk_parm_date               �p�����[�^�`�F�b�N (A-2)
 *  get_profile_info            �v���t�@�C���l�擾 (A-3)
 *  open_csv_file               CSV�t�@�C���I�[�v�� (A-4)
 *  get_csv_data                CSV�t�@�C���ɏo�͂���֘A���擾 (A-6)
 *  create_csv_rec              �K��\��f�[�^CSV�o�� (A-7)
 *  close_csv_file              CSV�t�@�C���N���[�Y���� (A-8)
 *  submain                     ���C�������v���V�[�W��
 *                                �K��\��f�[�^���o���� (A-5)
 *  main                        �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                                  �I������ (A-9)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-12-18    1.0   Syoei.Kin        �V�K�쐬
 *  2009-03-18    1.1   K.Boku           �y������Q069�z���o���Ԑݒ�ӏ��C��
 *  2009-05-01    1.2   Tomoko.Mori      T1_0897�Ή�
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
  gv_value                  VARCHAR2(100);             -- �������s��(YYYYMMDD)
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
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCSO014A10C';      -- �p�b�P�[�W��
  cv_app_name            CONSTANT VARCHAR2(10)  := 'XXCSO';             -- �A�v���P�[�V�����Z�k��
  cv_appl_short_name     CONSTANT VARCHAR2(10)  := 'XXCCP';             -- �A�h�I���F���ʁEIF�̈�
--
  cv_active_status       CONSTANT VARCHAR2(1)   := 'A';                 -- �A�N�e�B�u
  cv_dumm_day_month      CONSTANT VARCHAR2(2)   := '99';                -- ���ʏꍇ�̓��ɂ��i99�j
  cv_monday_kbn_month    CONSTANT VARCHAR2(1)   := '1';                 -- �����敪�i���ʁF1�j
  cv_monday_kbn_day      CONSTANT VARCHAR2(1)   := '2';                 -- �����敪�i���ʁF2�j
  cv_upd_kbn_sales_month CONSTANT VARCHAR2(1)   := '6';                 -- HHT�A�g�X�V�@�\�敪�i����v��F6�j  
  cv_upd_kbn_sales_day   CONSTANT VARCHAR2(1)   := '7';                 -- HHT�A�g�X�V�@�\�敪�i����v����ʁF7�j    
  cv_houmon_kbn_taget    CONSTANT VARCHAR2(1)   := '1';                 -- �K��Ώۋ敪�i�K��ΏہF1�j
  cv_source_obj_type_cd  CONSTANT VARCHAR2(10)  := 'PARTY';             -- �\�[�X�I�u�W�F�N�g�^�C�v�R�[�h
  cv_delete_flg          CONSTANT VARCHAR2(10)  := 'N';                 -- �폜�t���O
--
  -- ���b�Z�[�W�R�[�h
  cv_tkn_number_01    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00014';     -- �v���t�@�C���擾�G���[
  cv_tkn_number_02    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00150';     -- �p�����[�^�f�t�H���g�Z�b�g
  cv_tkn_number_03    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00011';     -- �Ɩ��������t�擾�G���[
  cv_tkn_number_04    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00012';     -- ���t�����G���[
  cv_tkn_number_05    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00123';     -- CSV�t�@�C���c���G���[
  cv_tkn_number_06    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00015';     -- CSV�t�@�C���I�[�v���G���[
  cv_tkn_number_07    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00024';     -- �K��\��f�[�^���o�G���[
  cv_tkn_number_08    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00224';     -- CSV�t�@�C���o��0���G���[
  cv_tkn_number_09    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00060';     -- ���o�G���[
  cv_tkn_number_10    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00061';     -- �c�ƈ��R�[�h�擾�֐��G���[
  cv_tkn_number_11    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00246';     -- CSV�t�@�C���o�̓G���[
  cv_tkn_number_12    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00018';     -- CSV�t�@�C���N���[�Y�G���[
  cv_tkn_number_13    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00147';     -- �p�����[�^�������s��
  cv_tkn_number_14    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00152';     -- �C���^�[�t�F�[�X�t�@�C����
  -- �g�[�N���R�[�h
  cv_tkn_prof_name       CONSTANT VARCHAR2(20) := 'PROF_NAME';          -- �v���t�@�C����
  cv_tkn_err_msg         CONSTANT VARCHAR2(20) := 'ERR_MSG';            -- SQL�G���[���b�Z�[�W
  cv_tkn_value           CONSTANT VARCHAR2(20) := 'VALUE';              -- ���͂��ꂽ�p�����[�^�l
  cv_tkn_status          CONSTANT VARCHAR2(20) := 'STATUS';             -- ���^�[���X�e�[�^�X(���t�����`�F�b�N����)
  cv_tkn_message         CONSTANT VARCHAR2(20) := 'MESSAGE';            -- ���^�[�����b�Z�[�W(���t�����`�F�b�N) 
  cv_tkn_csv_location    CONSTANT VARCHAR2(20) := 'CSV_LOCATION';       -- CSV�t�@�C���o�͐�
  cv_tkn_csv_file_name   CONSTANT VARCHAR2(20) := 'CSV_FILE_NAME';      -- CSV�t�@�C����
  cv_tkn_year_month      CONSTANT VARCHAR2(20) := 'YEAR_MONTH';         -- �N��
  cv_tkn_day             CONSTANT VARCHAR2(20) := 'DAY';                -- ��
  cv_tkn_location_cd     CONSTANT VARCHAR2(20) := 'LOCATION_CD';        -- ���㋒�_�R�[�h
  cv_tkn_customer_cd     CONSTANT VARCHAR2(20) := 'CUSTOMER_CD';        -- �ڋq�R�[�h
  cv_tkn_proc_name       CONSTANT VARCHAR2(20) := 'PROCESSING_NAME';    -- ���o������
  cv_tkn_count           CONSTANT VARCHAR2(20) := 'COUNT';              -- ��������
  cv_tkn_table           CONSTANT VARCHAR2(20) := 'TABLE';              -- �e�[�u����
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
  cv_debug_msg15          CONSTANT VARCHAR2(200) := 'lv_task_id     = ';
  cv_debug_msg16          CONSTANT VARCHAR2(200) := '<< �S���c�ƈ��R�[�h���o���� >>' ;
  cv_debug_msg17          CONSTANT VARCHAR2(200) := 'lt_emp_number     = ';
  cv_debug_msg18          CONSTANT VARCHAR2(200) := '<< �O�T�K�⎞�����o���� >>' ;
  cv_debug_msg19          CONSTANT VARCHAR2(200) := 'lv_visite_p_week_date     = ';
  cv_debug_msg20          CONSTANT VARCHAR2(200) := '<< �̔����ы��z���o���� >>' ;
  cv_debug_msg21          CONSTANT VARCHAR2(200) := 'lt_pure_amount_sum     = ';
  cv_debug_msg22          CONSTANT VARCHAR2(200) := '<< ���ʔ���v�捇�v���o���� >>' ;
  cv_debug_msg23          CONSTANT VARCHAR2(200) := 'lt_sales_plan_amt_sum     = ';
  cv_debug_msg24          CONSTANT VARCHAR2(200) := '<< �v�捷�擾���� >>' ;
  cv_debug_msg25          CONSTANT VARCHAR2(200) := 'ln_plan_diff     = ';  
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
  -- �K��\����f�[�^
    TYPE g_value_rtype IS RECORD(
      base_code             xxcso_account_sales_plans.base_code%TYPE,            -- ���㋒�_�R�[�h
      account_number        xxcso_account_sales_plans.account_number%TYPE,       -- �ڋq�R�[�h
      year_month            xxcso_account_sales_plans.year_month%TYPE,           -- �N��
      plan_day              xxcso_account_sales_plans.plan_day%TYPE,             -- ��
      plan_date             xxcso_account_sales_plans.plan_date%TYPE,            -- �N����(�K��\���)
      sales_plan_day_amt    xxcso_account_sales_plans.sales_plan_day_amt%TYPE,   -- ���ʔ���v��(�v����z)
      final_call_date       VARCHAR2(100),                                       -- �ŏI�K���(�O��K���)
      sales_person_cd       xxcso_cust_resources_v.employee_number%type,         -- �S���c�ƈ��R�[�h
      visite_p_week_date    VARCHAR2(100),                                       -- �O�T�K�⎞��
      plan_diff             NUMBER                                               -- �v�捷
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
    od_process_date     OUT NOCOPY DATE,      -- �Ɩ�������
    ov_errbuf           OUT NOCOPY VARCHAR2,  -- �G���[�E���b�Z�[�W            --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,  -- ���^�[���E�R�[�h              --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W    --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'init';             -- �v���O������
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
    ld_process_date      DATE;        -- �Ɩ�������
    lv_init_msg          VARCHAR2(5000);   -- �G���[���b�Z�[�W���i�[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �N���p�����[�^���o��
    lv_init_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name
                    ,iv_name         => cv_tkn_number_13
                    ,iv_token_name1  => cv_tkn_value
                    ,iv_token_value1 => gv_value
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''           || CHR(10) ||   -- ��s�̑}��
                  lv_init_msg || CHR(10) ||
                 ''
    );
    -- �p�����[�^���uNULL�v�ł��邩�ǂ������m�F
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
      lv_errmsg := xxccp_common_pkg.get_msg(
              iv_application  => cv_app_name                 -- �A�v���P�[�V�����Z�k��
             ,iv_name         => cv_tkn_number_03            -- ���b�Z�[�W�R�[�h
      );
      lv_errbuf  := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- �p�����[�^�f�t�H���g�Z�b�g
    IF (gv_value IS NULL) THEN
      gv_value := TO_CHAR(ld_process_date,'YYYYMMDD');
      -- �p�����[�^�f�t�H���g�Z�b�g���b�Z�[�W
      lv_init_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_tkn_number_02
                     );
      -- ���b�Z�[�W���o��
      fnd_file.put_line(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_init_msg
      );
      -- ���b�Z�[�W�����O�o��
      fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   =>  cv_pkg_name || cv_msg_cont||
                     cv_prg_name || cv_msg_part||
                     lv_init_msg || CHR(10) ||
                     '' 
      );
    END IF;
    -- �擾�����Ɩ��������t��OUT�p�����[�^�ɐݒ�
    od_process_date := ld_process_date;
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : chk_parm_date
   * Description      : �p�����[�^�`�F�b�N (A-2)
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
    -- *** ���[�J���ϐ� ***
    lv_format                 VARCHAR2(20);  -- ���t�̃t�H�[�}�b�g
    lb_check_date_value       BOOLEAN;       -- ���t�̏����`�F�b�N�̃��^�[���X�e�[�^�X
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
    --�擾�����p�����[�^�̏������w�肳�ꂽ���t�̏����iYYYYMMDD�j�ł��邩���m�F
    lb_check_date_value := xxcso_util_common_pkg.check_date(
                                  iv_date         => gv_value
                                 ,iv_date_format  => lv_format
    );
    --���^�[���X�e�[�^�X���uFALSE�v�̏ꍇ,��O�������s��
    IF (lb_check_date_value = cb_false) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name               -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_04          -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_value              -- �g�[�N���R�[�h1
                      ,iv_token_value1 => gv_value                  -- �g�[�N���l1�p�����[�^
                      ,iv_token_name2  => cv_tkn_status             -- �g�[�N���R�[�h2
                      ,iv_token_value2 => cv_false                  -- �g�[�N���l2���^�[���X�e�[�^�X
                      ,iv_token_name3  => cv_tkn_message            -- �g�[�N���R�[�h3
                      ,iv_token_value3 => NULL                      -- �g�[�N���l3���^�[�����b�Z�[�W
      );
      lv_errbuf  := lv_errmsg;
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
   * Description      : �v���t�@�C���l���擾 (A-3)
   ***********************************************************************************/
  PROCEDURE get_profile_info(
    ov_file_dir             OUT NOCOPY VARCHAR2,        -- XXCSO:HTT�A�g�pCSV�t�@�C���o�͐�
    ov_file_name            OUT NOCOPY VARCHAR2,        -- XXCSO:HTT�A�g�pCSV�t�@�C����
    ov_task_id              OUT NOCOPY VARCHAR2,        -- XXCSO:�^�X�N�X�e�[�^�XID(�N���[�Y)
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
    cv_tkn_csv_name     CONSTANT VARCHAR2(100)  := 'CSV_FILE_NAME';
      -- �C���^�[�t�F�[�X�t�@�C�����g�[�N����
    cv_file_dir         CONSTANT VARCHAR2(100)  := 'XXCSO1_HHT_OUT_CSV_DIR';
      --XXCSO:HTT�A�g�pCSV�t�@�C���o�͐�
    cv_file_name        CONSTANT VARCHAR2(100)  := 'XXCSO1_HHT_OUT_CSV_VISIT_PLAN';
      --XXCSO:HTT�A�g�pCSV�t�@�C����
    cv_task_id          CONSTANT VARCHAR2(100)  := 'XXCSO1_TASK_STATUS_CLOSED_ID';
      --XXCSO:�^�X�N�X�e�[�^�XID(�N���[�Y)   
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
    lv_task_id        VARCHAR2(1000);      -- XXCSO:�^�X�N�X�e�[�^�XID(�N���[�Y)
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
    -- CSV�t�@�C���o�͐�̒l�擾
    fnd_profile.get(
                  cv_file_dir
                 ,lv_file_dir
    );
    -- CSV�t�@�C�����̒l�擾
    fnd_profile.get(
                  cv_file_name
                 ,lv_file_name
    );
    --�^�X�N�X�e�[�^�XID(�N���[�Y)�̒l�擾
    fnd_profile.get(
                  cv_task_id
                 ,lv_task_id
    );
    -- *** DEBUG_LOG ***
    -- �擾�����v���t�@�C���l�����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg7  || CHR(10) ||
                 cv_debug_msg9  || lv_file_dir    || CHR(10) ||
                 cv_debug_msg10 || lv_file_name     || CHR(10) ||
                 cv_debug_msg15 || lv_task_id     || CHR(10) ||
                 ''
    );
    --�߂�l���uNULL�v�ł������ꍇ,��O�������s��
    --XXCSO:HTT�A�g�pCSV�t�@�C���o�͐�
    IF (lv_file_dir IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name              -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_tkn_number_01         -- ���b�Z�[�W�R�[�h
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
                        ,iv_name         => cv_tkn_number_01         -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_prof_name         -- �g�[�N���R�[�h1
                        ,iv_token_value1 => cv_file_name             -- �g�[�N���l1CSV�t�@�C����
      );
      lv_errbuf  := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --XXCSO:�^�X�N�X�e�[�^�XID(�N���[�Y)
    IF (lv_task_id IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name              -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_tkn_number_01         -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_prof_name         -- �g�[�N���R�[�h1
                        ,iv_token_value1 => cv_task_id               -- �g�[�N���l1CSV�t�@�C����
      );
      lv_errbuf  := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --�C���^�[�t�F�[�X�t�@�C�������b�Z�[�W�o��
    lv_msg_set := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name
                    ,iv_name         => cv_tkn_number_14
                    ,iv_token_name1  => cv_tkn_csv_name
                    ,iv_token_value1 => lv_file_name
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''           || CHR(10) ||   -- ��s�̑}��
                   lv_msg_set ||CHR(10) ||
                 ''                           -- ��s�̑}��
    );
    -- �擾����CSV�t�@�C���o�͐�ƃt�@�C������OUT�p�����[�^�ɐݒ�
    ov_file_dir   := lv_file_dir;       -- XXCSO:HTT�A�g�pCSV�t�@�C���o�͐�
    ov_file_name  := lv_file_name;      -- XXCSO:HTT�A�g�pCSV�t�@�C����
    ov_task_id    := lv_task_id;        -- XXCSO:�^�X�N�X�e�[�^�XID(�N���[�Y)
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
   * Description      : CSV�t�@�C���I�[�v�� (A-4)
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
      -- CSV�t�@�C���c���G���[���b�Z�[�W�擾
      lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name              -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_tkn_number_05         -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_csv_location      -- �g�[�N���R�[�h1
                        ,iv_token_value1 => lv_file_dir              -- �g�[�N���l1CSV�t�@�C���o�͐�
                        ,iv_token_name2  => cv_tkn_csv_file_name     -- �g�[�N���R�[�h1
                        ,iv_token_value2 => lv_file_name             -- �g�[�N���l1CSV�t�@�C����
      );
      lv_errbuf := lv_errmsg;
      RAISE file_err_expt;
    END IF;
    -- ========================
    -- CSV�t�@�C���I�[�v�� 
    -- ========================
    BEGIN
--
      -- �t�@�C��ID���擾
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
          -- CSV�t�@�C���I�[�v���G���[���b�Z�[�W�擾
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name              -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_tkn_number_06         -- ���b�Z�[�W�R�[�h
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
   * Procedure Name   : get_csv_data
   * Description      : CSV�t�@�C���ɏo�͂���֘A���擾 (A-6)
   ***********************************************************************************/
  PROCEDURE get_csv_data(
    io_get_rec      IN OUT NOCOPY g_value_rtype,       -- �K��\����f�[�^
    id_process_date IN DATE,                           -- �Ɩ�������
    iv_task_id      IN VARCHAR2,                       -- �^�X�N�X�e�[�^�XID(�N���[�Y)
    ov_errbuf       OUT NOCOPY VARCHAR2,               -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT NOCOPY VARCHAR2,               -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT NOCOPY VARCHAR2                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                CONSTANT VARCHAR2(100)  := 'get_csv_data';       -- �v���O������
    cv_sep_com                 CONSTANT VARCHAR2(3)    := ',';
    cv_sep_wquot               CONSTANT VARCHAR2(3)    := '"';
    cv_p_week_visit            CONSTANT VARCHAR2(100)  := '�O�T�K�⎞��';
    cv_pure_amount_sum         CONSTANT VARCHAR2(100)  := '�̔����ы��z';
    cv_sales_plan_amt_sum      CONSTANT VARCHAR2(100)  := '����v����z';
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
    ld_process_date        DATE;              -- �Ɩ�������
    lv_visite_p_week_date  VARCHAR2(100);     -- �O�T�K�⎞��
    lv_task_id             VARCHAR2(1000);    -- �^�X�N�X�e�[�^�XID(�N���[�Y)
    ld_year_month_01       DATE;              -- �N��||'01'
    ld_plan_date           DATE;              -- �N����
    ld_plan_date_7         DATE;              -- �N����-7
    ld_plan_date_1         DATE;              -- �N����-1
    lt_emp_number          xxcso_cust_resources_v.employee_number%type;          -- �S���c�ƈ��R�[�h
    lt_pure_amount_sum     xxcos_sales_exp_headers.pure_amount_sum%TYPE;         -- �̔����ы��z
    lt_sales_plan_amt_sum  xxcso_account_sales_plans.sales_plan_day_amt%TYPE;    -- ���ʔ���v��̍��v
    ln_plan_diff           NUMBER;            -- �v�捷
    -- *** ���[�J���E���R�[�h ***
    l_get_rec       g_value_rtype;            -- �K��\����f�[�^
    -- *** ���[�J����O ***
    select_error_expt     EXCEPTION;          -- �f�[�^�o�͏�����O
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
    ld_process_date   := id_process_date;     -- �Ɩ�������
    lv_task_id        := iv_task_id;          -- �^�X�N�X�e�[�^�XID(�N���[�Y)
    l_get_rec         := io_get_rec;          -- �K��\����i�[���郌�R�[�h
    ld_plan_date_7    := TO_DATE(l_get_rec.plan_date,'YYYYMMDD')-7;            -- �N����-7
    ld_plan_date      := TO_DATE(l_get_rec.plan_date,'YYYYMMDD');              -- �N����
    ld_year_month_01  := TO_DATE((l_get_rec.year_month||'01'),'YYYYMMDD');     -- �N��||'01'
    ld_plan_date_1    := (TO_DATE(l_get_rec.plan_date,'YYYYMMDD')-1);          -- �N����-1
    -- �S���c�ƈ��R�[�h���o
    BEGIN
-- 
      SELECT xcrv.employee_number
      INTO   lt_emp_number                         -- �S���c�ƈ��R�[�h
      FROM   xxcso_cust_resources_v xcrv
      WHERE  xcrv.account_number = l_get_rec.account_number
        AND  ld_plan_date BETWEEN TRUNC(xcrv.start_date_active) 
               AND TRUNC(NVL(xcrv.end_date_active,ld_plan_date));
--
    EXCEPTION
      WHEN OTHERS THEN
        -- �c�ƈ��R�[�h�擾�֐��G���[���b�Z�[�W
        lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_app_name                    -- �A�v���P�[�V�����Z�k��
                  ,iv_name         => cv_tkn_number_10               -- ���b�Z�[�W�R�[�h
                  ,iv_token_name1  => cv_tkn_location_cd             -- �g�[�N���R�[�h1
                  ,iv_token_value1 => TO_CHAR(l_get_rec.base_code)   -- �g�[�N���l1���㋒�_�R�[�h
                  ,iv_token_name2  => cv_tkn_customer_cd             -- �g�[�N���R�[�h2
                  ,iv_token_value2 => l_get_rec.account_number       -- �g�[�N���l2�ڋq�R�[�h
                  ,iv_token_name3  => cv_tkn_year_month              -- �g�[�N���R�[�h3
                  ,iv_token_value3 => l_get_rec.year_month           -- �g�[�N���l3�N��
                  ,iv_token_name4  => cv_tkn_day                     -- �g�[�N���R�[�h4
                  ,iv_token_value4 => l_get_rec.plan_day             -- �g�[�N���l4��
            );
        lv_errbuf     := lv_errmsg;
      RAISE select_error_expt;
    END;
--
    -- �O�T�K�⎞���𒊏o
    BEGIN
--
      SELECT TO_CHAR(MAX(jtb.actual_end_date),'HH24MI')
      INTO   lv_visite_p_week_date                          -- �O�T�K�⎞��
      FROM   jtf_tasks_b jtb
            ,xxcso_cust_accounts_v xcav
      WHERE  jtb.source_object_type_code = cv_source_obj_type_cd
        AND  xcav.account_number = l_get_rec.account_number
        AND  jtb.source_object_id = xcav.party_id
        AND  jtb.task_status_id = lv_task_id
        AND  jtb.deleted_flag = cv_delete_flg
        AND  TRUNC(jtb.actual_end_date) = ld_plan_date_7
        AND  xcav.account_status = cv_active_status
        AND  xcav.party_status = cv_active_status;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_visite_p_week_date := NULL;
      WHEN OTHERS THEN
        -- �O�T�K�⎞�����o�G���[���b�Z�[�W
        lv_errmsg := xxccp_common_pkg.get_msg(
                 iv_application  => cv_app_name                         -- �A�v���P�[�V�����Z�k��
                ,iv_name         => cv_tkn_number_09                    -- ���b�Z�[�W�R�[�h
                ,iv_token_name1  => cv_tkn_proc_name                    -- �g�[�N���R�[�h1
                ,iv_token_value1 => cv_p_week_visit                     -- �g�[�N���l1�p�����[�^
                ,iv_token_name2  => cv_tkn_location_cd                  -- �g�[�N���R�[�h2
                ,iv_token_value2 => TO_CHAR(l_get_rec.base_code)        -- �g�[�N���l2���㋒�_�R�[�h
                ,iv_token_name3  => cv_tkn_customer_cd                  -- �g�[�N���R�[�h3
                ,iv_token_value3 => l_get_rec.account_number            -- �g�[�N���l3�ڋq�R�[�h
                ,iv_token_name4  => cv_tkn_year_month                   -- �g�[�N���R�[�h4
                ,iv_token_value4 => l_get_rec.year_month                -- �g�[�N���l4�N��
                ,iv_token_name5  => cv_tkn_day                          -- �g�[�N���R�[�h5
                ,iv_token_value5 => l_get_rec.plan_day                  -- �g�[�N���l5��
                ,iv_token_name6  => cv_tkn_err_msg                      -- �g�[�N���R�[�h6
                ,iv_token_value6 => SQLERRM                             -- �g�[�N���l6
              );
        lv_errbuf  := lv_errmsg;
      RAISE select_error_expt;
    END;
--
    -- ���o���ʂ��uNULL�v�̏ꍇ
    IF (lv_visite_p_week_date IS NULL) THEN
      lv_visite_p_week_date := '9999';
    END IF;
--
    -- �̔����ы��z���o
    IF (l_get_rec.year_month = SUBSTR(gv_value,1,6)) THEN
      BEGIN
--
        SELECT ROUND(SUM(pure_amount)/1000)        
        INTO   lt_pure_amount_sum 
        FROM   xxcso_sales_for_sls_prsn_v xsfsp
        WHERE  xsfsp.account_number = l_get_rec.account_number
          AND  xsfsp.delivery_date BETWEEN ld_year_month_01 AND ld_plan_date_1;
--
      EXCEPTION
        WHEN OTHERS THEN
          -- �̔����ы��z���o�G���[���b�Z�[�W
        lv_errmsg := xxccp_common_pkg.get_msg(
                 iv_application  => cv_app_name                         -- �A�v���P�[�V�����Z�k��
                ,iv_name         => cv_tkn_number_09                    -- ���b�Z�[�W�R�[�h
                ,iv_token_name1  => cv_tkn_proc_name                    -- �g�[�N���R�[�h1
                ,iv_token_value1 => cv_pure_amount_sum                  -- �g�[�N���l1�p�����[�^
                ,iv_token_name2  => cv_tkn_location_cd                  -- �g�[�N���R�[�h2
                ,iv_token_value2 => TO_CHAR(l_get_rec.base_code)        -- �g�[�N���l2���㋒�_�R�[�h
                ,iv_token_name3  => cv_tkn_customer_cd                  -- �g�[�N���R�[�h3
                ,iv_token_value3 => l_get_rec.account_number            -- �g�[�N���l3�ڋq�R�[�h
                ,iv_token_name4  => cv_tkn_year_month                   -- �g�[�N���R�[�h4
                ,iv_token_value4 => l_get_rec.year_month                -- �g�[�N���l4�N��
                ,iv_token_name5  => cv_tkn_day                          -- �g�[�N���R�[�h5
                ,iv_token_value5 => l_get_rec.plan_day                  -- �g�[�N���l5��
                ,iv_token_name6  => cv_tkn_err_msg                      -- �g�[�N���R�[�h6
                ,iv_token_value6 => SQLERRM                             -- �g�[�N���l6
              );
        lv_errbuf  := lv_errmsg;
      RAISE select_error_expt;
    END;
--
    ELSIF (l_get_rec.year_month = TO_CHAR(ADD_MONTHS(TO_DATE(gv_value,'YYYYMMDD'),1),'YYYYMM')) THEN
      lt_pure_amount_sum := 0;
    END IF;
    -- ���ʔ���v�捇�v���o
    BEGIN
--
      SELECT SUM(NVL(xasp.sales_plan_day_amt,0))
      INTO   lt_sales_plan_amt_sum
      FROM   xxcso_account_sales_plans xasp
      WHERE  xasp.base_code = l_get_rec.base_code
        AND  xasp.account_number = l_get_rec.account_number
        AND  xasp.year_month = l_get_rec.year_month
        AND  xasp.plan_day <= l_get_rec.plan_day
        AND  xasp.month_date_div = cv_monday_kbn_day;
--
    EXCEPTION
      WHEN OTHERS THEN
          -- ���ʔ���v�捇�v���o�G���[���b�Z�[�W
        lv_errmsg := xxccp_common_pkg.get_msg(
                 iv_application  => cv_app_name                         -- �A�v���P�[�V�����Z�k��
                ,iv_name         => cv_tkn_number_09                    -- ���b�Z�[�W�R�[�h
                ,iv_token_name1  => cv_tkn_proc_name                    -- �g�[�N���R�[�h1
                ,iv_token_value1 => cv_sales_plan_amt_sum               -- �g�[�N���l1�p�����[�^
                ,iv_token_name2  => cv_tkn_location_cd                  -- �g�[�N���R�[�h2
                ,iv_token_value2 => TO_CHAR(l_get_rec.base_code)        -- �g�[�N���l2���㋒�_�R�[�h
                ,iv_token_name3  => cv_tkn_customer_cd                  -- �g�[�N���R�[�h3
                ,iv_token_value3 => l_get_rec.account_number            -- �g�[�N���l3�ڋq�R�[�h
                ,iv_token_name4  => cv_tkn_year_month                   -- �g�[�N���R�[�h4
                ,iv_token_value4 => l_get_rec.year_month                -- �g�[�N���l4�N��
                ,iv_token_name5  => cv_tkn_day                          -- �g�[�N���R�[�h5
                ,iv_token_value5 => l_get_rec.plan_day                  -- �g�[�N���l5��
                ,iv_token_name6  => cv_tkn_err_msg                      -- �g�[�N���R�[�h6
                ,iv_token_value6 => SQLERRM                             -- �g�[�N���l6
              );
        lv_errbuf  := lv_errmsg;
      RAISE select_error_expt;
    END;
    -- �v�捷���擾
    ln_plan_diff := NVL(lt_pure_amount_sum,0) - NVL(lt_sales_plan_amt_sum,0);
--
    -- �擾�����p�����[�^��OUT�p�����[�^�ɐݒ�
    l_get_rec.sales_person_cd     := lt_emp_number;            -- �S���c�ƈ��R�[�h
    l_get_rec.visite_p_week_date  := lv_visite_p_week_date;    -- �O�T�K�⎞��
    l_get_rec.plan_diff           := ln_plan_diff;             -- �v�捷
    io_get_rec                    := l_get_rec;                -- �K��\����f�[�^
--
  EXCEPTION
    -- *** �t�@�C��������O�n���h�� ***
    WHEN select_error_expt THEN
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
  END get_csv_data;
--
  /**********************************************************************************
   * Procedure Name   : create_csv_rec
   * Description      : CSV�t�@�C���o�� (A-7)
   ***********************************************************************************/
  PROCEDURE create_csv_rec(
    i_get_rec   IN g_value_rtype,                  -- �K��\����f�[�^
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
    -- *** ���[�J���E���R�[�h ***
    l_get_rec       g_value_rtype;                  -- �K��\����f�[�^
    -- *** ���[�J����O ***
    file_put_line_expt             EXCEPTION;       -- �f�[�^�o�͏�����O
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
    l_get_rec  := i_get_rec;       -- �K��\����i�[���郌�R�[�h
    BEGIN
--
      --�f�[�^�쐬
      lv_data := cv_sep_wquot || TO_CHAR(l_get_rec.base_code) || cv_sep_wquot            -- ���㋒�_�R�[�h
        || cv_sep_com || cv_sep_wquot || l_get_rec.sales_person_cd || cv_sep_wquot       -- �S���c�ƈ��R�[�h
        || cv_sep_com || l_get_rec.plan_date                                             -- �K��\���
        || cv_sep_com || TO_CHAR(l_get_rec.visite_p_week_date)                           -- �O�T�K�⎞��
        || cv_sep_com || cv_sep_wquot || l_get_rec.account_number || cv_sep_wquot        -- �ڋq�R�[�h
        || cv_sep_com || TO_CHAR(l_get_rec.final_call_date)                              -- �O��K���
        || cv_sep_com || TO_CHAR(l_get_rec.sales_plan_day_amt)                           -- �v����z
        || cv_sep_com || TO_CHAR(l_get_rec.plan_diff);                                   -- �v�捷
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
                     ,iv_name         => cv_tkn_number_11                  --���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_customer_cd                --�g�[�N���R�[�h1
                     ,iv_token_value1 => l_get_rec.account_number          --�g�[�N���l1�ڋq�R�[�h
                     ,iv_token_name2  => cv_tkn_location_cd                --�g�[�N���R�[�h2
                     ,iv_token_value2 => l_get_rec.base_code               --�g�[�N���l2���㋒�_�R�[�h
                     ,iv_token_name3  => cv_tkn_year_month                 --�g�[�N���R�[�h3
                     ,iv_token_value3 => l_get_rec.year_month              --�g�[�N���l3�N��
                     ,iv_token_name4  => cv_tkn_day                        --�g�[�N���R�[�h4
                     ,iv_token_value4 => l_get_rec.plan_day                --�g�[�N���l4��
                     ,iv_token_name5  => cv_tkn_err_msg                    --�g�[�N���R�[�h5
                     ,iv_token_value5 => SQLERRM                           --�g�[�N���l5
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
   * Description      : CSV�t�@�C���N���[�Y���� (A-8)
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
                        ,iv_name         => cv_tkn_number_12             --���b�Z�[�W�R�[�h
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
    cv_visit_plan           CONSTANT VARCHAR2(100)   := '�K��\��e�[�u��';
    cv_p_week_visit         CONSTANT VARCHAR2(100)   := '�O�T�K�⎞��';
    -- *** ���[�J���ϐ� ***
    lv_sub_retcode         VARCHAR2(1);                -- �T�[�u���C���p���^�[���E�R�[�h
    lv_sub_msg             VARCHAR2(5000);             -- �x���p���b�Z�[�W
    lv_sub_buf             VARCHAR2(5000);             -- �x���p�G���[�E���b�Z�[�W
    ld_process_date        DATE;                       -- �Ɩ�������
    lv_target_cnt          NUMBER;                     -- �����Ώی����i�[
    lb_csv_putl_rec        VARCHAR2(2000);             -- CSV�t�@�C���o�͔��f
    lv_file_dir            VARCHAR2(2000);             -- CSV�t�@�C���o�͐�
    lv_file_name           VARCHAR2(2000);             -- CSV�t�@�C����
    lv_task_id             VARCHAR2(1000);             -- �^�X�N�X�e�[�^�XID(�N���[�Y)
    lv_gv_value_1          VARCHAR2(100);              -- �������s��+1
    lv_gv_value_8          VARCHAR2(100);              -- �������s��+8
    -- �t�@�C���I�[�v���m�F�߂�l�i�[
    lb_fopn_retcd   BOOLEAN;
    -- ���b�Z�[�W�o�͗p
    lv_msg          VARCHAR2(2000);
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR xsasp_xcav_data_cur
    IS
      SELECT xsasp.base_code base_code                                 -- ���㋒�_�R�[�h
            ,xsasp.account_number account_number                       -- �ڋq�R�[�h
            ,xsasp.year_month year_month                               -- �N��
            ,xsasp.plan_day plan_day                                   -- ��
            ,xsasp.plan_date plan_date                                 -- �N����
            ,xsasp.sales_plan_day_amt sales_plan_day_amt               -- ���ʔ���v��
            ,TO_CHAR(xcav.final_call_date,'YYYYMMDD') final_call_date  -- �ŏI�K���
      FROM   xxcso_cust_accounts_v xcav                                -- �ڋq�}�X�^�r���[
            ,xxcso_account_sales_plans xsasp                           -- �ڋq�ʔ���v��e�[�u��
      WHERE  xcav.account_number = xsasp.account_number
        AND  xcav.vist_target_div = cv_houmon_kbn_taget
        AND  xsasp.plan_date BETWEEN lv_gv_value_1 AND lv_gv_value_8 
        AND  xsasp.sales_plan_day_amt > 0
        AND  xsasp.month_date_div = cv_monday_kbn_day
        AND  xcav.account_status = cv_active_status
        AND  xcav.party_status = cv_active_status
      ORDER BY xsasp.base_code        ASC                        -- ���㋒�_�R�[�h
              ,xsasp.account_number   ASC                        -- �ڋq�R�[�h
              ,xsasp.year_month       ASC                        -- �N��
              ,xsasp.plan_day         ASC;                       -- ��
    -- *** ���[�J���E���R�[�h ***
    l_xsasp_xcav_data_rec   xsasp_xcav_data_cur%ROWTYPE;
    l_get_rec               g_value_rtype;                       -- �K��\����f�[�^
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
      od_process_date     => ld_process_date,  -- �Ɩ�������
      ov_errbuf           => lv_errbuf,        -- �G���[�E���b�Z�[�W            --# �Œ� #
      ov_retcode          => lv_retcode,       -- ���^�[���E�R�[�h              --# �Œ� #
      ov_errmsg           => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    ); 
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ================================
    -- A-2.�p�����[�^�`�F�b�N 
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
    -- ���[�J���ϐ��̏�����
    lv_gv_value_1  := TO_CHAR(TO_DATE(gv_value,'YYYYMMDD') + 1,'YYYYMMDD');
    lv_gv_value_8  := TO_CHAR(TO_DATE(gv_value,'YYYYMMDD') + 8,'YYYYMMDD');
    -- �擾�����Ɩ��������t�����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg3 || 'FromTo' || CHR(10) ||
                 lv_gv_value_1 || '�`' || lv_gv_value_8 || CHR(10) ||
                 ''
    );
    -- =================================================
    -- A-3.�v���t�@�C���l���擾 
    -- =================================================
    get_profile_info(
       ov_file_dir   => lv_file_dir   -- CSV�t�@�C���o�͐�
      ,ov_file_name  => lv_file_name  -- CSV�t�@�C����
      ,ov_task_id    => lv_task_id    -- �^�X�N�X�e�[�^�XID(�N���[�Y)
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
    -- A-4.CSV�t�@�C���I�[�v�� 
    -- =================================================
--
    open_csv_file(
       iv_file_dir  => lv_file_dir   -- CSV�t�@�C���o�͐�
      ,iv_file_name => lv_file_name  -- CSV�t�@�C����
      ,ov_errbuf    => lv_errbuf     -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode   => lv_retcode    -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg    => lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =================================================
    -- A-5.�K��\��f�[�^���o����
    -- =================================================
--
    -- �J�[�\���I�[�v��
    OPEN xsasp_xcav_data_cur;
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
          FETCH xsasp_xcav_data_cur INTO l_xsasp_xcav_data_rec;
--
        EXCEPTION
          WHEN OTHERS THEN
            -- �K��\��f�[�^���o�G���[���b�Z�[�W
            lv_errmsg := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_app_name               -- �A�v���P�[�V�����Z�k��
                                ,iv_name         => cv_tkn_number_07          -- ���b�Z�[�W�R�[�h
                                ,iv_token_name1  => cv_tkn_table              -- �g�[�N���R�[�h1
                                ,iv_token_value1 => cv_visit_plan             -- �g�[�N���l1���^�[���X�e�[�^�X
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
        l_get_rec         := NULL;    -- �K��\��f�[�^�i�[
        -- �����Ώی����i�[
        gn_target_cnt := xsasp_xcav_data_cur%ROWCOUNT;
        -- �Ώی�����O���̏ꍇ
        EXIT WHEN xsasp_xcav_data_cur%NOTFOUND
        OR  xsasp_xcav_data_cur%ROWCOUNT = 0;
        
        -- �擾�f�[�^���i�[
        l_get_rec.base_code             := l_xsasp_xcav_data_rec.base_code;             -- ���㋒�_�R�[�h
        l_get_rec.account_number        := l_xsasp_xcav_data_rec.account_number;        -- �ڋq�R�[�h
        l_get_rec.year_month            := l_xsasp_xcav_data_rec.year_month;            -- �N��
        l_get_rec.plan_day              := l_xsasp_xcav_data_rec.plan_day;              -- ��
        l_get_rec.plan_date             := l_xsasp_xcav_data_rec.plan_date;             -- �N����
        l_get_rec.sales_plan_day_amt    := l_xsasp_xcav_data_rec.sales_plan_day_amt;    -- ���ʔ���v��
        l_get_rec.final_call_date       := l_xsasp_xcav_data_rec.final_call_date;       -- �ŏI�K���
--
        -- ================================================================
        -- A-6 CSV�t�@�C���ɏo�͂���֘A���擾
        -- ================================================================
--
        get_csv_data(
           io_get_rec       => l_get_rec        -- �K��\����f�[�^
          ,id_process_date  => ld_process_date  -- �Ɩ�������
          ,iv_task_id       => lv_task_id       -- �^�X�N�X�e�[�^�XID(�N���[�Y)
          ,ov_errbuf        => lv_sub_buf       -- �G���[�E���b�Z�[�W            --# �Œ� #
          ,ov_retcode       => lv_sub_retcode   -- ���^�[���E�R�[�h              --# �Œ� #
          ,ov_errmsg        => lv_sub_msg       -- ���[�U�[�E�G���[�E���b�Z�[�W    --# �Œ� #
        );
        IF (lv_sub_retcode = cv_status_error) THEN
          RAISE select_error_expt;
        END IF;
--
        -- ========================================
        -- A-7. �K��\��f�[�^CSV�t�@�C���o�� 
        -- ========================================
        create_csv_rec(
          i_get_rec                    =>  l_get_rec                -- �K��\��f�[�^���i�[���郌�R�[�h
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
                    ,iv_name         => cv_tkn_number_08             --���b�Z�[�W�R�[�h
                   );
      -- ���b�Z�[�W�o��
      fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg 
      );
      -- ���b�Z�[�W�����O�ɏo��
      fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => cv_pkg_name||cv_msg_cont||
                    cv_prg_name||cv_msg_part||
                    gv_out_msg
       );
    END IF;
--
    -- �J�[�\���N���[�Y
    CLOSE xsasp_xcav_data_cur;
    -- *** DEBUG_LOG ***
    -- �J�[�\���N���[�Y�������Ƃ����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg_ccls1 || CHR(10) ||
                 ''
    );
--
    -- ========================================
    -- A-8.CSV�t�@�C���N���[�Y  
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
      IF (xsasp_xcav_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE xsasp_xcav_data_cur;
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
      IF (xsasp_xcav_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE xsasp_xcav_data_cur;
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
      IF (xsasp_xcav_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE xsasp_xcav_data_cur;
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
    ,iv_value            IN VARCHAR2             --   �������s��(YYYYMMDD)
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
    gv_value        := iv_value;       -- �������s��
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
END XXCSO014A10C;
/
