CREATE OR REPLACE PACKAGE BODY XXCSO016A06C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO016A06C(spec)
 * Description      : ����(���̋@)�̈ړ������������n�V�X�e���ɑ��M���邽�߂�CSV�t�@�C�����쐬���܂��B
 *                    
 * MD.050           : MD050_CSO_016_A06_���n-EBS�C���^�[�t�F�[�X�F(OUT)�Y��ړ�����
 *                    
 * Version          : 1.1
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                        Description
 * ---------------------------- ----------------------------------------------------------
 *  init                        �������� (A-1)
 *  set_parm_def                �p�����[�^�f�t�H���g�Z�b�g (A-2)
 *  chk_parm_date               �p�����[�^�`�F�b�N (A-3)
 *  get_profile_info            �v���t�@�C���l�擾 (A-4)
 *  open_csv_file               CSV�t�@�C���I�[�v�� (A-5)
 *  get_csv_data                CSV�t�@�C���ɏo�͂���֘A���擾 (A-7)
 *  create_csv_rec              CSV�t�@�C���o�� (A-8)
 *  close_csv_file              CSV�t�@�C���N���[�Y���� (A-9)
 *  submain                     ���C�������v���V�[�W��
 *                                �Y��ړ����׃f�[�^���o (A-6)
 *  main                        �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                                  �I������ (A-10)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-01-21    1.0   Syoei.Kin        �V�K�쐬
 *  2009-02-24    1.1   K.Sai            ���r���[��Ή� 
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
  gv_from_value             VARCHAR2(20);               -- �X�V��FROM(YYYYMMDD)
  gv_to_value               VARCHAR2(20);               -- �X�V��TO(YYYYMMDD)
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
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCSO016A06C';  -- �p�b�P�[�W��
  cv_app_name            CONSTANT VARCHAR2(10)  := 'XXCSO';         -- �A�v���P�[�V�����Z�k��
  cv_appl_short_name     CONSTANT VARCHAR2(10)  := 'XXCCP';         -- �A�h�I���F���ʁEIF�̈�
--
  cv_active_status       CONSTANT VARCHAR2(1)   := 'A';             -- �A�N�e�B�u
  cn_job_kbn_1           CONSTANT NUMBER        := 1;               -- �Y��ړ��敪(1[�V��ݒu])
  cn_job_kbn_2           CONSTANT NUMBER        := 2;               -- �Y��ړ��敪(2[����ݒu])
  cn_job_kbn_3           CONSTANT NUMBER        := 3;               -- �Y��ړ��敪(3[�V����])
  cn_job_kbn_4           CONSTANT NUMBER        := 4;               -- �Y��ړ��敪(4[������])
  cn_job_kbn_5           CONSTANT NUMBER        := 5;               -- �Y��ړ��敪(5[���g])
  cn_job_kbn_6           CONSTANT NUMBER        := 6;               -- �Y��ړ��敪(6[�X���ړ�])
  cn_job_kbn_8           CONSTANT NUMBER        := 8;               -- �Y��ړ��敪(8[����])
  cn_job_kbn_15          CONSTANT NUMBER        := 15;              -- �Y��ړ��敪(15[�]��])
  cn_job_kbn_16          CONSTANT NUMBER        := 16;              -- �Y��ړ��敪(16[�]��])
  cn_job_kbn_17          CONSTANT NUMBER        := 17;              -- �Y��ړ��敪(17[�p������])
    
--
  -- ���b�Z�[�W�R�[�h
  cv_tkn_number_01    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00011';     -- �Ɩ��������t�擾�G���[���b�Z�[�W
  cv_tkn_number_02    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00012';     -- ���t�����G���[���b�Z�[�W
  cv_tkn_number_03    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00013';     -- �p�����[�^�������G���[���b�Z�[�W
  cv_tkn_number_04    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00014';     -- �v���t�@�C���擾�G���[���b�Z�[�W
  cv_tkn_number_05    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00123';     -- CSV�t�@�C���c���G���[���b�Z�[�W
  cv_tkn_number_06    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00015';     -- CSV�t�@�C���I�[�v���G���[���b�Z�[�W
  cv_tkn_number_07    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00016';     -- �f�[�^���o�G���[���b�Z�[�W
  cv_tkn_number_08    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00296';     -- ���_(����)�R�[�h�Ȃ��x�����b�Z�[�W
  cv_tkn_number_09    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00297';     -- CSV�t�@�C���o�̓G���[���b�Z�[�W
  cv_tkn_number_10    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00018';     -- CSV�t�@�C���N���[�Y�G���[���b�Z�[�W
  cv_tkn_number_11    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00152';     -- �C���^�[�t�F�[�X�t�@�C����
  cv_tkn_number_12    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00145';     -- �p�����[�^�X�V��FROM
  cv_tkn_number_13    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00146';     -- �p�����[�^�X�V��TO
  cv_tkn_number_14    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00150';     -- �p�����[�^�f�t�H���g�Z�b�g
  -- �g�[�N���R�[�h
  cv_tkn_err_msg         CONSTANT VARCHAR2(20) := 'ERR_MSG';            -- SQL�G���[���b�Z�[�W
  cv_tkn_err_message     CONSTANT VARCHAR2(20) := 'ERR_MESSAGE';       -- SQL�G���[���b�Z�[�W
  cv_tkn_value           CONSTANT VARCHAR2(20) := 'VALUE';              -- ���͂��ꂽ�p�����[�^�̒l
  cv_tkn_status          CONSTANT VARCHAR2(20) := 'STATUS';             -- ���^�[���X�e�[�^�X
  cv_tkn_from_value      CONSTANT VARCHAR2(20) := 'FROM_VALUE';         -- �X�V��FROM�ɃZ�b�g���ꂽ�p�����[�^�l
  cv_tkn_to_value        CONSTANT VARCHAR2(20) := 'TO_VALUE';           -- �X�V��TO�ɃZ�b�g���ꂽ�p�����[�^�l
  cv_tkn_prof_name       CONSTANT VARCHAR2(20) := 'PROF_NAME';          -- �v���t�@�C����
  cv_tkn_csv_location    CONSTANT VARCHAR2(20) := 'CSV_LOCATION';       -- CSV�t�@�C���o�͐�
  cv_tkn_csv_file_name   CONSTANT VARCHAR2(20) := 'CSV_FILE_NAME';      -- CSV�t�@�C����
  cv_tkn_slip_no         CONSTANT VARCHAR2(20) := 'SLIP_NO';            -- �`�[�ԍ�
  cv_tkn_line_no         CONSTANT VARCHAR2(20) := 'LINE_NO';            -- �s�ԍ�
  cv_tkn_year_month_day  CONSTANT VARCHAR2(20) := 'YEAR_MONTH_DAY';     -- �N����
  cv_tkn_object_cd       CONSTANT VARCHAR2(20) := 'OBJECT_CD';          -- �����R�[�h
  cv_tkn_object_cd1      CONSTANT VARCHAR2(20) := 'OBJECT_CD1';         -- �����R�[�h1
  cv_tkn_object_cd2      CONSTANT VARCHAR2(20) := 'OBJECT_CD2';         -- �����R�[�h2
  cv_tkn_work_kbn        CONSTANT VARCHAR2(20) := 'WORK_KBN';           -- ��Ƌ敪
  cv_tkn_proc_name       CONSTANT VARCHAR2(20) := 'PROCESSING_NAME';    -- ���o������
  cv_tkn_message         CONSTANT VARCHAR2(20) := 'MESSAGE';            -- ���b�Z�[�W
  cv_tkn_table           CONSTANT VARCHAR2(20) := 'TABLE';              -- �e�[�u����
--
  cb_true                CONSTANT BOOLEAN := TRUE;
  cb_false               CONSTANT BOOLEAN := FALSE;
--
  -- DEBUG_LOG�p���b�Z�[�W
  
  cv_debug_msg1           CONSTANT VARCHAR2(200) := '<< �V�X�e�����t�擾���� >>';
  cv_debug_msg2           CONSTANT VARCHAR2(200) := 'lv_sysdate          = ';
  cv_debug_msg3           CONSTANT VARCHAR2(200) := '<< �Ɩ��������t�擾���� >>';
  cv_debug_msg4           CONSTANT VARCHAR2(200) := 'ld_process_date = ';
  cv_debug_msg5           CONSTANT VARCHAR2(200) := '<< �v���t�@�C���l�擾���� >>';
  cv_debug_msg6           CONSTANT VARCHAR2(200) := 'lv_file_dir         = ';
  cv_debug_msg7           CONSTANT VARCHAR2(200) := 'lv_file_name        = ';
  cv_debug_msg8           CONSTANT VARCHAR2(200) := 'lv_company_cd       = ';
  cv_debug_msg10           CONSTANT VARCHAR2(200) := '<< CSV�t�@�C�����I�[�v�����܂��� >>' ;
  cv_debug_msg11          CONSTANT VARCHAR2(200) := '<< CSV�t�@�C�����N���[�Y���܂��� >>' ;
  cv_debug_msg12          CONSTANT VARCHAR2(200) := '<< ���[���o�b�N���܂��� >>' ;
--
  cv_debug_msg_fnm        CONSTANT VARCHAR2(200) := 'filename = ';
  cv_debug_msg_fcls       CONSTANT VARCHAR2(200) := '<< ��O��������CSV�t�@�C�����N���[�Y���܂��� >>';
  cv_debug_msg_copn       CONSTANT VARCHAR2(200) := '<< �J�[�\�����I�[�v�����܂��� >>';
  cv_debug_msg_ccls1      CONSTANT VARCHAR2(200) := '<< �J�[�\�����N���[�Y���܂��� >>';
  cv_debug_msg_ccls2      CONSTANT VARCHAR2(200) := '<< ��O�������ŃJ�[�\�����N���[�Y���܂��� >>';
  cv_debug_msg_err1       CONSTANT VARCHAR2(200) := 'file_err_expt';
  cv_debug_msg_err2       CONSTANT VARCHAR2(200) := 'global_api_expt';
  cv_debug_msg_err3       CONSTANT VARCHAR2(200) := 'global_api_others_expt';
  cv_debug_msg_err4       CONSTANT VARCHAR2(200) := 'others��O';
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
  -- �Y��ړ����׏��f�[�^
    TYPE g_value_rtype IS RECORD(
      company_cd                VARCHAR2(100),                                   -- ��ЃR�[�h
      slip_no                   xxcso_in_work_data.slip_no%TYPE,                 -- �`�[�ԍ�
      line_number               xxcso_in_work_data.line_number%TYPE,             -- �s�ԍ�
      year_month_day            NUMBER,                                          -- �N����
      install_code1             xxcso_in_work_data.install_code1%TYPE,           -- �����R�[�h1(�ݒu�p)
      install_code2             xxcso_in_work_data.install_code2%TYPE,           -- �����R�[�h2(���g�p)
      sale_base_code_s          xxcmm_cust_accounts.sale_base_code%TYPE,         -- ���_(����)�R�[�h(�ݒu�p)
      sale_base_code_w          xxcmm_cust_accounts.sale_base_code%TYPE,         -- ���_(����)�R�[�h(���g�p)
      job_kbn                   xxcso_in_work_data.job_kbn%TYPE,                 -- �Y��ړ��敪
      delete_flag               xxcso_in_work_data.delete_flag%TYPE,             -- �폜�t���O
      sysdate_now               VARCHAR2(100)                                    -- �A�g����
    );
  --*** �f�[�^�o�^�A�X�V��O ***
  global_ins_upd_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_ins_upd_expt,-30000);
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : �������� (A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_sysdate          OUT NOCOPY VARCHAR2,  -- �V�X�e�����t
    ov_errbuf           OUT NOCOPY VARCHAR2,  -- �G���[�E���b�Z�[�W            --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,  -- ���^�[���E�R�[�h              --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
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
    lv_sysdate           VARCHAR2(100);    -- �V�X�e�����t
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
    -- �V�X�e�����t�擾
    lv_sysdate := TO_CHAR(SYSDATE,'YYYYMMDDHH24MISS');
    -- �擾�����V�X�e�����t�����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg1  || CHR(10) ||
                 cv_debug_msg2  || lv_sysdate || CHR(10) ||
                 ''
    );
--
    -- �擾�����V�X�e�����t��OUT�p�����[�^�ɐݒ�
    ov_sysdate := lv_sysdate;
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
   * Procedure Name   : set_parm_def                                  
   * Description      : �p�����[�^�f�t�H���g�Z�b�g (A-2)
   ***********************************************************************************/
  PROCEDURE set_parm_def(
    ov_errbuf               OUT NOCOPY VARCHAR2,        -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,        -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W   --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'set_parm_def';      -- �v���O������
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
    lb_check               BOOLEAN;         -- �p�����[�^�f�t�H���g�Z�b�g�`�F�b�N
    lv_param_set           VARCHAR2(1000);  -- �p�����[�^�f�t�H���g�Z�b�g���b�Z�[�W���i�[
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
    lv_param_set := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name
                    ,iv_name         => cv_tkn_number_12
                    ,iv_token_name1  => cv_tkn_from_value
                    ,iv_token_value1 => gv_from_value
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''             || CHR(10) ||   -- ��s�̑}��
                   lv_param_set 
    );
    --�X�V��TO���b�Z�[�W�o��
    lv_param_set := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name
                    ,iv_name         => cv_tkn_number_13
                    ,iv_token_name1  => cv_tkn_to_value
                    ,iv_token_value1 => gv_to_value
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_param_set || CHR(10) ||
                    ''
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
      lv_errmsg := xxccp_common_pkg.get_msg(
              iv_application  => cv_app_name                 -- �A�v���P�[�V�����Z�k��
             ,iv_name         => cv_tkn_number_01            -- ���b�Z�[�W�R�[�h
      );
      lv_errbuf  := lv_errmsg||SQLERRM;
      RAISE global_api_expt;
    END IF;
    -- �X�V��FROM�ƍX�V��TO�̑��݃`�F�b�N 
    IF (gv_from_value IS NULL) THEN
      gv_from_value := TO_CHAR(ld_process_date,'YYYYMMDD');
      lb_check := TRUE;
    END IF;
    IF (gv_to_value IS NULL) THEN
      gv_to_value := TO_CHAR(ld_process_date,'YYYYMMDD');
      lb_check := TRUE;
    END IF;
    --�p�����[�^�f�t�H���g�Z�b�g
    IF (lb_check = TRUE) THEN
      lv_param_set := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_tkn_number_14
                     );
      lv_errbuf  := lv_errmsg||SQLERRM;
      fnd_file.put_line(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_param_set  || CHR(10) ||
                    ''
      );
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
  END set_parm_def;
--
  /**********************************************************************************
   * Procedure Name   : chk_parm_date
   * Description      : �p�����[�^�`�F�b�N (A-3)
   ***********************************************************************************/
  PROCEDURE chk_parm_date(
    ov_errbuf               OUT NOCOPY VARCHAR2,        -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,        -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lb_check_date_from_value  BOOLEAN;       -- �X�V��FROM�̏������w�肳�ꂽ���t�̏����iYYYYMMDD�j�ł��邩���m�F
    lb_check_date_to_value    BOOLEAN;       -- �X�V��TO�̏������w�肳�ꂽ���t�̏����iYYYYMMDD�j�ł��邩���m�F
    lv_value                  VARCHAR2(20);  -- �X�V��FROM�ƍX�V��TO�̒l
--
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
        lv_value   := gv_from_value;
      END IF;
      IF (lb_check_date_to_value = cb_false) THEN
        lv_value   := gv_to_value;
      END IF;
      IF ((lb_check_date_from_value = cb_false) OR (lb_check_date_to_value = cb_false)) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name               -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_tkn_number_02          -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_value              -- �g�[�N���R�[�h1
                        ,iv_token_value1 => lv_value                  -- �g�[�N���l1�p�����[�^
                        ,iv_token_name2  => cv_tkn_status             -- �g�[�N���R�[�h2
                        ,iv_token_value2 => cv_false                  -- �g�[�N���l2���^�[���X�e�[�^�X
                        ,iv_token_name3  => cv_tkn_message            -- �g�[�N���R�[�h3
                        ,iv_token_value3 => NULL                      -- �g�[�N���l3���^�[�����b�Z�[�W
        );
        lv_errbuf  := lv_errmsg||SQLERRM;
        RAISE global_api_expt;
      END IF;
    -- ===========================
    -- ���t�召�֌W�`�F�b�N
    -- ===========================
      --���͂��ꂽ�p�����[�^�̒l�̑召�֌W�����������m�F
      IF (gv_from_value > gv_to_value) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name              -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_tkn_number_03         -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_from_value        -- �g�[�N���R�[�h1
                        ,iv_token_value1 => gv_from_value            -- �g�[�N���l1�X�V��FROM
                        ,iv_token_name2  => cv_tkn_to_value          -- �g�[�N���R�[�h2
                        ,iv_token_value2 => gv_to_value              -- �g�[�N���l2�X�V��TO
        );
        lv_errbuf  := lv_errmsg||SQLERRM;
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
    ov_file_dir             OUT NOCOPY VARCHAR2,        -- CSV�t�@�C���o�͐�
    ov_file_name            OUT NOCOPY VARCHAR2,        -- CSV�t�@�C����
    ov_company_cd           OUT NOCOPY VARCHAR2,        -- ��ЃR�[�h(�Œ�l001)
    ov_errbuf               OUT NOCOPY VARCHAR2,        -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,        -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100)  := 'get_profile_info';            -- �v���O������
--
    cv_tkn_csv_name     CONSTANT VARCHAR2(100)  := 'CSV_FILE_NAME';
      -- �C���^�[�t�F�[�X�t�@�C�����g�[�N����
    cv_file_dir         CONSTANT VARCHAR2(100)  := 'XXCSO1_INFO_OUT_CSV_DIR';         -- CSV�t�@�C���o�͐�
    cv_file_name        CONSTANT VARCHAR2(100)  := 'XXCSO1_INFO_OUT_CSV_IB_WRK_LNS';  -- CSV�t�@�C����
    cv_company_cd       CONSTANT VARCHAR2(100)  := 'XXCSO1_INFO_OUT_COMPANY_CD';      -- ��ЃR�[�h(�Œ�l001)

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
    lv_file_dir       VARCHAR2(2000);             -- CSV�t�@�C���o�͐�
    lv_file_name      VARCHAR2(2000);             -- CSV�t�@�C����
    lv_company_cd     VARCHAR2(2000);             -- ��ЃR�[�h(�Œ�l001)
    lv_msg_set        VARCHAR2(1000);             -- ���b�Z�[�W�i�[
    lv_value          VARCHAR2(1000);             -- �v���t�@�C���I�v�V�����l
    lv_check_flg      VARCHAR2(1000);             -- �v���t�@�C���l�擾���s�̏ꍇ('1')
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
    -- ��ЃR�[�h�̒l�擾
    fnd_profile.get(
                  cv_company_cd
                 ,lv_company_cd
    );
    -- *** DEBUG_LOG ***
    -- �擾�����v���t�@�C���l�����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg5 || CHR(10) ||
                 cv_debug_msg6 || lv_file_dir    || CHR(10) ||
                 cv_debug_msg7 || lv_file_name   || CHR(10) ||
                 cv_debug_msg8 || lv_company_cd  || CHR(10) ||
                 ''
    );
    --�C���^�[�t�F�[�X�t�@�C�������b�Z�[�W�o��
    lv_msg_set := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name
                    ,iv_name         => cv_tkn_number_11
                    ,iv_token_name1  => cv_tkn_csv_name
                    ,iv_token_value1 => lv_file_name
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg_set ||CHR(10) ||
                 ''                           -- ��s�̑}��
    );
    -- �߂�l���uNULL�v�ł������ꍇ,��O�������s��
    -- CSV�t�@�C���o�͐�
    IF (lv_file_dir IS NULL) THEN
      lv_check_flg := '1';
      lv_value     := cv_file_dir;
    END IF;
    -- CSV�t�@�C����
    IF (lv_file_name IS NULL) THEN
      lv_check_flg := '1';
      lv_value     := cv_file_name;
    END IF;
    -- ��ЃR�[�h(�Œ�l001)
    IF (lv_company_cd IS NULL) THEN
      lv_check_flg := '1';
      lv_value := cv_company_cd;
    END IF;
    IF (lv_check_flg = '1') THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name              -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_tkn_number_04         -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_prof_name         -- �g�[�N���R�[�h1
                        ,iv_token_value1 => lv_value                 -- �g�[�N���l1���g���_�R�[�h
      );
      lv_errbuf  := lv_errmsg||SQLERRM;
      RAISE global_api_expt;    
    END IF;
    -- �擾�����l��OUT�p�����[�^�ɐݒ�
    ov_file_dir   := lv_file_dir;       -- CSV�t�@�C���o�͐�
    ov_file_name  := lv_file_name;      -- CSV�t�@�C����
    ov_company_cd := lv_company_cd;     -- ��ЃR�[�h(�Œ�l001)
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
    iv_file_dir             IN  VARCHAR2,               -- CSV�t�@�C���o�͐�
    iv_file_name            IN  VARCHAR2,               -- CSV�t�@�C����
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
    lv_file_dir       VARCHAR2(1000);      -- CSV�t�@�C���o�͐�
    lv_file_name      VARCHAR2(1000);      -- CSV�t�@�C����
    lv_exists         BOOLEAN;             -- ���݃`�F�b�N����
    lv_file_length    VARCHAR2(1000);      -- �t�@�C���T�C�Y
    lv_blocksize      VARCHAR2(1000);      -- �u���b�N�T�C�Y
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
    lv_file_dir   := iv_file_dir;       -- CSV�t�@�C���o�͐�
    lv_file_name  := iv_file_name;      -- CSV�t�@�C����
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
      lv_errbuf := lv_errmsg||SQLERRM;
      RAISE file_err_expt;
    ELSIF (lv_exists = cb_false) THEN
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
          ,buff   => cv_debug_msg10    || CHR(10)   ||
                     cv_debug_msg_fnm  || lv_file_name || CHR(10) ||
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
            lv_errbuf := lv_errmsg||SQLERRM;
            RAISE file_err_expt;
      END;
    END IF;
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
      -- �擾�����l��OUT�p�����[�^�ɐݒ�
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
--
  /**********************************************************************************
   * Procedure Name   : get_csv_data
   * Description      : CSV�t�@�C���ɏo�͂���֘A���擾 (A-7)
   ***********************************************************************************/
  PROCEDURE get_csv_data(
    io_get_rec      IN OUT NOCOPY g_value_rtype,       -- ���f�[�^
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
    --
    cv_account_master          CONSTANT VARCHAR2(100)  := '�ڋq�}�X�^';
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
    lv_sale_base_code_s          VARCHAR2(100);         -- ���_(����)�R�[�h(�ݒu�p)
    lv_sale_base_code_w          VARCHAR2(100);         -- ���_(����)�R�[�h(���g�p)
    ln_debug  number;
    -- *** ���[�J���E���R�[�h ***
    l_get_rec       g_value_rtype;            -- �Y��ړ����׃f�[�^
    -- *** ���[�J����O ***
    select_error_expt     EXCEPTION;          -- �f�[�^�o�͏�����O(�G���[)
    select_warning_expt   EXCEPTION;          -- �f�[�^�o�͏�����O(�x��)
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
    l_get_rec := io_get_rec;
    -- �����R�[�h1��NULL�łȂ��ꍇ�A
    -- �Y��ړ��敪=(1[�V��ݒu], 2[����ݒu], 3[�V����], 4[������], 6[�X���ړ�], 8[����])�̏ꍇ
    IF ((l_get_rec.install_code1 IS NOT NULL)
          AND (l_get_rec.job_kbn IN (cn_job_kbn_1,cn_job_kbn_2,cn_job_kbn_3,cn_job_kbn_4,
                                     cn_job_kbn_6,cn_job_kbn_8)) ) THEN
      BEGIN
        SELECT  xca.sale_base_code         -- ���_(����)�R�[�h(�ݒu�p)
        INTO    lv_sale_base_code_s
        FROM    csi_item_instances cii     -- �C���X�g�[���x�[�X�}�X�^
               ,xxcmm_cust_accounts xca    -- �ڋq�A�h�I���}�X�^
        WHERE cii.external_reference = l_get_rec.install_code1
        AND cii.owner_party_account_id = xca.customer_id;
        
      EXCEPTION
        -- �R�[�h�����݂��Ȃ��ꍇ
        WHEN NO_DATA_FOUND THEN
          -- �f�[�^���o�G���[���b�Z�[�W
          lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_app_name               -- �A�v���P�[�V�����Z�k��
                              ,iv_name         => cv_tkn_number_08          -- ���b�Z�[�W�R�[�h
                              ,iv_token_name1  => cv_tkn_table              -- �g�[�N���R�[�h1
                              ,iv_token_value1 => cv_account_master         -- �g�[�N���l1
                              ,iv_token_name2  => cv_tkn_slip_no            -- �g�[�N���R�[�h2
                              ,iv_token_value2 => l_get_rec.slip_no         -- �g�[�N���l2�`�[�ԍ�
                              ,iv_token_name3  => cv_tkn_line_no            -- �g�[�N���R�[�h3
                              ,iv_token_value3 => l_get_rec.line_number     -- �g�[�N���l3�s�ԍ�
                              ,iv_token_name4  => cv_tkn_year_month_day     -- �g�[�N���R�[�h4
                              ,iv_token_value4 => l_get_rec.year_month_day  -- �g�[�N���l4�N����
                              ,iv_token_name5  => cv_tkn_object_cd          -- �g�[�N���R�[�h5
                              ,iv_token_value5 => l_get_rec.install_code1   -- �g�[�N���l5�����R�[�h
                              ,iv_token_name6  => cv_tkn_work_kbn           -- �g�[�N���R�[�h6
                              ,iv_token_value6 => l_get_rec.job_kbn         -- �g�[�N���l6��Ƌ敪
              );
          lv_errbuf  := lv_errmsg;
          RAISE select_warning_expt;
        -- ���o�Ɏ��s�����ꍇ
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_app_name               -- �A�v���P�[�V�����Z�k��
                              ,iv_name         => cv_tkn_number_07          -- ���b�Z�[�W�R�[�h
                              ,iv_token_name1  => cv_tkn_proc_name          -- �g�[�N���R�[�h1
                              ,iv_token_value1 => cv_account_master         -- �g�[�N���l1
                              ,iv_token_name2  => cv_tkn_err_message        -- �g�[�N���R�[�h2
                              ,iv_token_value2 => SQLERRM                   -- �g�[�N���l2
              );
          lv_errbuf  := lv_errmsg;
        RAISE select_error_expt;
      END;
    END IF;
    -- �����R�[�h2��NULL�łȂ��ꍇ
    -- �Y��ړ��敪=(3[�V����], 4[������],5[���g], 15[�]��], 16[�]��], 17[�p������])�̏ꍇ
    IF ((l_get_rec.install_code2 IS NOT NULL)
          AND (l_get_rec.job_kbn IN (cn_job_kbn_3,cn_job_kbn_4,cn_job_kbn_5,
                                     cn_job_kbn_15,cn_job_kbn_16,cn_job_kbn_17)) ) THEN
      BEGIN
        SELECT xca.sale_base_code         -- ���_(����)�R�[�h(���g�p)
        INTO   lv_sale_base_code_w
        FROM   xxcso_install_base_v xibv  -- �����}�X�^�r���[
              ,hz_cust_accounts hca       -- �ڋq�}�X�^
              ,xxcmm_cust_accounts xca    -- �ڋq�A�h�I���}�X�^
        WHERE  xibv.install_code = l_get_rec.install_code2
          AND  xibv.ven_kyaku_last = hca.account_number
          AND  hca.cust_account_id = xca.customer_id
          AND  hca.status = cv_active_status
          ;
      EXCEPTION
        -- �R�[�h�����݂��Ȃ��ꍇ
        WHEN NO_DATA_FOUND THEN
          -- �f�[�^���o�G���[���b�Z�[�W
          lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_app_name               -- �A�v���P�[�V�����Z�k��
                              ,iv_name         => cv_tkn_number_08          -- ���b�Z�[�W�R�[�h
                              ,iv_token_name1  => cv_tkn_table              -- �g�[�N���R�[�h1
                              ,iv_token_value1 => cv_account_master         -- �g�[�N���l1
                              ,iv_token_name2  => cv_tkn_slip_no            -- �g�[�N���R�[�h2
                              ,iv_token_value2 => l_get_rec.slip_no         -- �g�[�N���l2�`�[�ԍ�
                              ,iv_token_name3  => cv_tkn_line_no            -- �g�[�N���R�[�h3
                              ,iv_token_value3 => l_get_rec.line_number     -- �g�[�N���l3�s�ԍ�
                              ,iv_token_name4  => cv_tkn_year_month_day     -- �g�[�N���R�[�h4
                              ,iv_token_value4 => l_get_rec.year_month_day  -- �g�[�N���l4�N����
                              ,iv_token_name5  => cv_tkn_object_cd          -- �g�[�N���R�[�h5
                              ,iv_token_value5 => l_get_rec.install_code2   -- �g�[�N���l5�����R�[�h
                              ,iv_token_name6  => cv_tkn_work_kbn           -- �g�[�N���R�[�h6
                              ,iv_token_value6 => l_get_rec.job_kbn         -- �g�[�N���l6��Ƌ敪
              );
          lv_errbuf  := lv_errmsg;
          RAISE select_warning_expt;
        -- ���o�Ɏ��s�����ꍇ
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_app_name               -- �A�v���P�[�V�����Z�k��
                              ,iv_name         => cv_tkn_number_07          -- ���b�Z�[�W�R�[�h
                              ,iv_token_name1  => cv_tkn_proc_name          -- �g�[�N���R�[�h1
                              ,iv_token_value1 => cv_account_master         -- �g�[�N���l1
                              ,iv_token_name2  => cv_tkn_err_message        -- �g�[�N���R�[�h2
                              ,iv_token_value2 => SQLERRM                   -- �g�[�N���l2
              );
          lv_errbuf  := lv_errmsg;
        RAISE select_error_expt;
      END;
    END IF;
      -- �擾�����l��OUT�p�����[�^�ɐݒ�
    l_get_rec.sale_base_code_s  := lv_sale_base_code_s;      -- ���_(����)�R�[�h(�ݒu�p)
    l_get_rec.sale_base_code_w  := lv_sale_base_code_w;      -- ���_(����)�R�[�h(���g�p)
--
    io_get_rec := l_get_rec;
--
  EXCEPTION
    -- *** �t�@�C��������O�n���h�� ***
    WHEN select_warning_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
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
--
  /**********************************************************************************
   * Procedure Name   : create_csv_rec
   * Description      : CSV�t�@�C���o�� (A-8)
   ***********************************************************************************/
  PROCEDURE create_csv_rec(
    i_get_rec   IN g_value_rtype,                  -- �Y��ړ����׃f�[�^
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
    l_get_rec       g_value_rtype;                  -- �Y��ړ����׃f�[�^
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
    l_get_rec  := i_get_rec;               -- �Y��ړ����׃f�[�^���i�[���郌�R�[�h
--
    BEGIN
--
      --�f�[�^�쐬
      lv_data := cv_sep_wquot || l_get_rec.company_cd || cv_sep_wquot                    -- ��ЃR�[�h
        || cv_sep_com || cv_sep_wquot || TO_CHAR(l_get_rec.slip_no) || cv_sep_wquot      -- �`�[�ԍ�
        || cv_sep_com || TO_CHAR(l_get_rec.line_number)                                  -- �s�ԍ�
        || cv_sep_com || TO_CHAR(l_get_rec.year_month_day)                               -- �N����
        || cv_sep_com || cv_sep_wquot || l_get_rec.install_code1 || cv_sep_wquot         -- �����R�[�h1
        || cv_sep_com || cv_sep_wquot || l_get_rec.install_code2 || cv_sep_wquot         -- �����R�[�h2
        || cv_sep_com || cv_sep_wquot || l_get_rec.sale_base_code_s || cv_sep_wquot      -- �O���Q��
        || cv_sep_com || cv_sep_wquot || l_get_rec.sale_base_code_w || cv_sep_wquot      -- �O���Q��
        || cv_sep_com || TO_CHAR(l_get_rec.job_kbn)                                      -- �Y��ړ��敪
        || cv_sep_com || cv_sep_wquot ||TO_CHAR(l_get_rec.delete_flag) || cv_sep_wquot   -- �폜�t���O
        || cv_sep_com || l_get_rec.sysdate_now;                                          -- �A�g����
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
                      iv_application  => cv_app_name               -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_09          -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_slip_no            -- �g�[�N���R�[�h1
                     ,iv_token_value1 => l_get_rec.slip_no         -- �g�[�N���l1�`�[�ԍ�
                     ,iv_token_name2  => cv_tkn_line_no            -- �g�[�N���R�[�h2
                     ,iv_token_value2 => l_get_rec.line_number     -- �g�[�N���l2�s�ԍ�
                     ,iv_token_name3  => cv_tkn_year_month_day     -- �g�[�N���R�[�h3
                     ,iv_token_value3 => l_get_rec.year_month_day  -- �g�[�N���l3�N����
                     ,iv_token_name4  => cv_tkn_object_cd1         -- �g�[�N���R�[�h4
                     ,iv_token_value4 => l_get_rec.install_code1   -- �g�[�N���l4�����R�[�h1
                     ,iv_token_name5  => cv_tkn_object_cd2         -- �g�[�N���R�[�h5
                     ,iv_token_value5 => l_get_rec.install_code2   -- �g�[�N���l5�����R�[�h2
                     ,iv_token_name6  => cv_tkn_err_msg            -- �g�[�N���R�[�h6
                     ,iv_token_value6 => SQLERRM                   -- �g�[�N���l6
                    );
        lv_errbuf := lv_errmsg||SQLERRM;
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
        ,buff   => cv_debug_msg11   || CHR(10)   ||
                   cv_debug_msg_fnm || iv_file_name || CHR(10) ||
                   ''
      );
      EXCEPTION
        WHEN UTL_FILE.WRITE_ERROR          OR     -- �I�y���[�e�B���O�V�X�e���G���[
             UTL_FILE.INVALID_FILEHANDLE   THEN   -- �t�@�C���E�n���h�������G���[
          -- �G���[���b�Z�[�W�擾
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_tkn_number_10             --���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_csv_location          --�g�[�N���R�[�h1
                        ,iv_token_value1 => iv_file_dir                  --�g�[�N���l1
                        ,iv_token_name2  => cv_tkn_csv_file_name         --�g�[�N���R�[�h1
                        ,iv_token_value2 => iv_file_name                 --�g�[�N���l1
                       );
          lv_errbuf := lv_errmsg||SQLERRM;
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
    cv_work_data_tkn        CONSTANT VARCHAR2(100)   := '��ƃf�[�^�e�[�u��';
    -- *** ���[�J���ϐ� ***
    lv_sub_retcode         VARCHAR2(1);                -- �T�[�u���C���p���^�[���E�R�[�h
    lv_sub_msg             VARCHAR2(5000);             -- �x���p���b�Z�[�W
    lv_sub_buf             VARCHAR2(5000);             -- �x���p�G���[�E���b�Z�[�W
    lv_sysdate             VARCHAR2(100);              -- �V�X�e�����t
    lv_file_dir            VARCHAR2(2000);             -- CSV�t�@�C���o�͐�
    lv_file_name           VARCHAR2(2000);             -- CSV�t�@�C����
    lv_company_cd          VARCHAR2(2000);             -- ��ЃR�[�h(�Œ�l001)
    lv_wd_base_cd          VARCHAR2(2000);             -- ���g���_�R�[�h
    ld_from_value          DATE;                       -- �X�V��FROM(DATE)
    ld_to_value            DATE;                       -- �X�V��TO(DATE)
    -- �t�@�C���I�[�v���m�F�߂�l�i�[
    lb_fopn_retcd   BOOLEAN;
    -- ���b�Z�[�W�o�͗p
    lv_msg          VARCHAR2(2000);
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR xiwd_data_cur
    IS
      SELECT  xiwd.slip_no slip_no                          -- �`�[�ԍ�
             ,xiwd.line_number line_number                  -- �s�ԍ�
             ,(CASE                                         -- �N����
                WHEN (xiwd.job_kbn IN(cn_job_kbn_1,cn_job_kbn_2,cn_job_kbn_3,cn_job_kbn_4,cn_job_kbn_5,
                                      cn_job_kbn_6,cn_job_kbn_8)) THEN
                xiwd.actual_work_date 
                WHEN (xiwd.job_kbn IN(cn_job_kbn_15,cn_job_kbn_16)) THEN
                xiwd.withdrawal_date 
                WHEN (xiwd.job_kbn IN(cn_job_kbn_17)) THEN
                xiwd.disposal_approval_date
              END) year_month_day
             ,xiwd.install_code1 install_code1              -- �����R�[�h1
             ,xiwd.install_code2 install_code2              -- �����R�[�h2
             ,xiwd.job_kbn job_kbn                          -- �Y��ړ��敪
             ,xiwd.delete_flag delete_flag                  -- �폜�t���O
      FROM xxcso_in_work_data xiwd                          -- ��ƃf�[�^�e�[�u��
      WHERE xiwd.job_kbn IN (cn_job_kbn_1,cn_job_kbn_2,cn_job_kbn_3,cn_job_kbn_4,cn_job_kbn_5,
                             cn_job_kbn_6,cn_job_kbn_8,cn_job_kbn_15,cn_job_kbn_16,cn_job_kbn_17)
        AND TRUNC(xiwd.last_update_date) BETWEEN ld_from_value AND ld_to_value;
    -- *** ���[�J���E���R�[�h ***
    l_xiwd_data_rec        xiwd_data_cur%ROWTYPE;
    l_get_rec              g_value_rtype;                    -- �Y��ړ����׃f�[�^
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
    -- ���[�J���ϐ��̏�����
    ld_from_value := TO_DATE(gv_from_value,'YYYYMMDD');
    ld_to_value   := TO_DATE(gv_to_value,'YYYYMMDD');
--
    -- ================================
    -- A-1.�������� 
    -- ================================
    init(
      ov_sysdate          => lv_sysdate,       -- �V�X�e�����t
      ov_errbuf           => lv_errbuf,        -- �G���[�E���b�Z�[�W            --# �Œ� #
      ov_retcode          => lv_retcode,       -- ���^�[���E�R�[�h              --# �Œ� #
      ov_errmsg           => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    ); 
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
--
    -- ================================
    -- A-2.�p�����[�^�f�t�H���g�Z�b�g 
    -- ================================
    set_parm_def(
      ov_errbuf           => lv_errbuf,           -- �G���[�E���b�Z�[�W            --# �Œ� #
      ov_retcode          => lv_retcode,          -- ���^�[���E�R�[�h              --# �Œ� #
      ov_errmsg           => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W    --# �Œ� #
    );
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
       ov_file_dir    => lv_file_dir    -- CSV�t�@�C���o�͐�
      ,ov_file_name   => lv_file_name   -- CSV�t�@�C����
      ,ov_company_cd  => lv_company_cd  -- ��ЃR�[�h(�Œ�l001)
      ,ov_errbuf      => lv_errbuf      -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode     => lv_retcode     -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg      => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =================================================
    -- A-5.CSV�t�@�C���I�[�v�� 
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
    -- A-6.�Y��ړ����׃f�[�^���o����
    -- =================================================
--
    -- �J�[�\���I�[�v��
    OPEN xiwd_data_cur;
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
        FETCH xiwd_data_cur INTO l_xiwd_data_rec;
--
      EXCEPTION
        WHEN OTHERS THEN
          -- �f�[�^���o�G���[���b�Z�[�W
          lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_app_name               -- �A�v���P�[�V�����Z�k��
                              ,iv_name         => cv_tkn_number_07          -- ���b�Z�[�W�R�[�h
                              ,iv_token_name1  => cv_tkn_proc_name          -- �g�[�N���R�[�h1
                              ,iv_token_value1 => cv_work_data_tkn          -- �g�[�N���l1
                              ,iv_token_name2  => cv_tkn_err_message        -- �g�[�N���R�[�h2
                              ,iv_token_value2 => SQLERRM                   -- �g�[�N���l2
              );
          lv_errbuf  := lv_errmsg||SQLERRM;
        RAISE global_process_expt;
      END;
--
      BEGIN
      -- �f�[�^������
      lv_sub_msg := NULL;
      lv_sub_buf := NULL;
      -- ���R�[�h�ϐ�������
      l_get_rec         := NULL;
      -- �����Ώی����i�[
      gn_target_cnt := xiwd_data_cur%ROWCOUNT;
      -- �Ώی�����O���̏ꍇ
      EXIT WHEN xiwd_data_cur%NOTFOUND
      OR  xiwd_data_cur%ROWCOUNT = 0;
      -- �擾�f�[�^���i�[
      l_get_rec.company_cd        := lv_company_cd;                     -- ��ЃR�[�h
      l_get_rec.slip_no           := l_xiwd_data_rec.slip_no;           -- �`�[�ԍ�
      l_get_rec.line_number       := l_xiwd_data_rec.line_number;       -- �s�ԍ�
      l_get_rec.year_month_day    := l_xiwd_data_rec.year_month_day;    -- �N����
      l_get_rec.install_code1     := l_xiwd_data_rec.install_code1;     -- �����R�[�h1
      l_get_rec.install_code2     := l_xiwd_data_rec.install_code2;     -- �����R�[�h2
      l_get_rec.job_kbn           := l_xiwd_data_rec.job_kbn;           -- �Y��ړ��敪
      l_get_rec.delete_flag       := l_xiwd_data_rec.delete_flag;       -- �폜�t���O
      l_get_rec.sysdate_now       := lv_sysdate;                        -- �A�g����
--
      -- ================================================================
      -- A-7 CSV�t�@�C���ɏo�͂���֘A���擾
      -- ================================================================
--
      get_csv_data(
         io_get_rec       => l_get_rec        -- �Y��ړ����׃f�[�^
        ,ov_errbuf        => lv_sub_buf       -- �G���[�E���b�Z�[�W            --# �Œ� #
        ,ov_retcode       => lv_sub_retcode   -- ���^�[���E�R�[�h              --# �Œ� #
        ,ov_errmsg        => lv_sub_msg       -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
      );
      IF (lv_sub_retcode = cv_status_warn) THEN
        RAISE select_error_expt;
      ELSIF (lv_sub_retcode = cv_status_error) THEN
        lv_errmsg := lv_sub_msg;
        lv_errbuf := lv_sub_buf;
        RAISE lv_process_expt;
      END IF;
--
      -- ========================================
      -- A-8. �Y��ړ����׏��f�[�^CSV�t�@�C���o�� 
      -- ========================================
      create_csv_rec(
        i_get_rec        =>  l_get_rec         -- �Y��ړ����׃f�[�^
       ,ov_errbuf        =>  lv_errbuf         -- �G���[�E���b�Z�[�W
       ,ov_retcode       =>  lv_retcode        -- ���^�[���E�R�[�h
       ,ov_errmsg        =>  lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      IF (lv_retcode = cv_status_error) THEN
        RAISE lv_process_expt;
      END IF;
      --���������J�E���g
      gn_normal_cnt := gn_normal_cnt + 1;
--
      EXCEPTION
        -- *** �f�[�^���o���̃G���[��O�n���h�� ***
        WHEN lv_process_expt THEN
          -- --�G���[�����J�E���g
          gn_error_cnt  := gn_error_cnt + 1;
          --
          RAISE global_process_expt;
        -- *** �f�[�^���o���̌x����O�n���h�� ***
        WHEN select_error_expt THEN
          --�G���[�����J�E���g
          gn_error_cnt  := gn_error_cnt + 1;
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
                       lv_sub_buf 
          );
      END;
--
    END LOOP get_data_loop;
--
    -- �J�[�\���N���[�Y
    CLOSE xiwd_data_cur;
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
      ,ov_errmsg     => lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
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
      IF (xiwd_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE xiwd_data_cur;
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
      IF (xiwd_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE xiwd_data_cur;
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
      IF (xiwd_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE xiwd_data_cur;
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
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I��
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
    -- IN�p�����[�^����
    gv_from_value    := iv_from_value;    -- �X�V��FROM
    gv_to_value      := iv_to_value;      -- �X�V��TO
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
    -- A-10.�I������ 
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
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
      -- *** DEBUG_LOG ***
      -- ���[���o�b�N�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg12 || CHR(10) ||
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
        ,buff   => cv_debug_msg12 || CHR(10) ||
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
        ,buff   => cv_debug_msg12 || CHR(10) ||
                   ''
      );
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCSO016A06C;
/
