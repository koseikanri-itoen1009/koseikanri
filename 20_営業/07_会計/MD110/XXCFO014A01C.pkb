CREATE OR REPLACE PACKAGE BODY XXCFO014A01C
AS
/*************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 * 
 * Package Name    : XXCFO014A01C
 * Description     : ���n�V�X�e���ւ̃f�[�^�A�g�i����ʑ��v�\�Z�j
 * MD.050          : MD050_CFO_014_A01_���n�V�X�e���ւ̃f�[�^�A�g�i����ʑ��v�\�Z�j
 * MD.070          : MD050_CFO_014_A01_���n�V�X�e���ւ̃f�[�^�A�g�i����ʑ��v�\�Z�j
 * Version         : 1.1
 * 
 * Program List
 * --------------- ---- ----- --------------------------------------------
 *  Name           Type  Ret   Description
 * --------------- ---- ----- --------------------------------------------
 *  init              P        ���̓p�����[�^�l���O�o�͏���             (A-1)
 *  get_system_value  P        �e��V�X�e���l�擾����                   (A-2)
 *  out_data_filename P        ����ʑ��v�\�Z�f�[�^�t�@�C����񃍃O���� (A-3)
 *  get_pl_budget_sum P        ����ʑ��v�\�Z�f�[�^�W�v����             (A-4)
 *  put_pl_budget_data_file P  ����ʑ��v�\�Z�f�[�^�t�@�C���o�͏���     (A-5)
 *  out_no_target     P        0�����b�Z�[�W�o�͏���                    (A-6)
 *  submain           P        ���C�������v���V�[�W��
 *  main              P        �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 * 
 * Change Record
 * ------------- ----- ------------- -------------------------------------
 *  Date          Ver.  Editor        Description
 * ------------- ----- ------------- -------------------------------------
 *  2008-11-20    1.0  SCS ���� ��   ����쐬
 *  2009-07-03    1.1  SCS ���X��    [0000020]�p�t�H�[�}���X���P
 ************************************************************************/
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
  -- ���[�U�[��`��O
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFO014A01C'; -- �p�b�P�[�W��
  cv_msg_kbn_cmn     CONSTANT VARCHAR2(5)   := 'XXCMN';        -- �A�h�I���F�}�X�^�E�o���E���ʂ̃A�v���P�[�V�����Z�k��
  cv_msg_kbn_ccp     CONSTANT VARCHAR2(5)   := 'XXCCP';        -- �A�h�I���F���ʁEIF�̈�̃A�v���P�[�V�����Z�k��
  cv_msg_kbn_cfo     CONSTANT VARCHAR2(5)   := 'XXCFO';        -- �A�h�I���F��v�E�A�h�I���̈�̃A�v���P�[�V�����Z�k��
--
  -- ���b�Z�[�W�ԍ�
  cv_msg_014a01_001  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00003'; --�����Ώۗ\�Z�Ȃ����b�Z�[�W
  cv_msg_014a01_002  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00004'; --�Ώۃf�[�^��0�����b�Z�[�W
  cv_msg_014a01_003  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00001'; --�v���t�@�C���擾�G���[���b�Z�[�W
  cv_msg_014a01_004  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00002'; --�t�@�C�����o�̓��b�Z�[�W
  cv_msg_014a01_005  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00027'; --�t�@�C�������݂��Ă��郁�b�Z�[�W
  cv_msg_014a01_006  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00028'; --�t�@�C���̏ꏊ���������b�Z�[�W
  cv_msg_014a01_007  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00029'; --�t�@�C�����I�[�v���ł��Ȃ����b�Z�[�W
  cv_msg_014a01_008  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00030'; --�t�@�C���ɏ����݂ł��Ȃ����b�Z�[�W
  cv_msg_014a01_009  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00032'; --�f�[�^�擾�G���[���b�Z�[�W
--
  -- �g�[�N��
  cv_tkn_prof             CONSTANT VARCHAR2(20) := 'PROF_NAME';                   -- �v���t�@�C����
  cv_tkn_file             CONSTANT VARCHAR2(20) := 'FILE_NAME';                   -- �t�@�C����
  cv_tkn_data             CONSTANT VARCHAR2(20) := 'DATA';                        -- �G���[�f�[�^�̐���
--
  -- ���{�ꎫ��
  cv_dict_aplid_sqlgl     CONSTANT VARCHAR2(100) := 'CFO000A00001';               -- "�A�v���P�[�V����ID�FSQLGL"
--
  -- �v���t�@�C��
  cv_data_filepath        CONSTANT VARCHAR2(40) := 'XXCFO1_BUDGET_DATA_FILEPATH'; -- XXCFO:����ʑ��v�\�Z�f�[�^�t�@�C���i�[�p�X
  cv_data_filename        CONSTANT VARCHAR2(40) := 'XXCFO1_BUDGET_DATA_FILENAME'; -- XXCFO:����ʑ��v�\�Z�f�[�^�t�@�C����
  cv_set_of_bks_id        CONSTANT VARCHAR2(30) := 'GL_SET_OF_BKS_ID';            -- ��v����ID
--
  -- �A�v���P�[�V�����Z�k��
  cv_appl_shrt_name_gl    CONSTANT fnd_application.application_short_name%TYPE := 'SQLGL'; -- �A�v���P�[�V�����Z�k��(��ʉ�v)
--
  cv_account_type_e       CONSTANT gl_code_combinations.account_type%TYPE := 'E'; -- ����Ȗڃ^�C�v(��p)
  cv_account_type_r       CONSTANT gl_code_combinations.account_type%TYPE := 'R'; -- ����Ȗڃ^�C�v(���v)
  cv_budgets_att1_y       CONSTANT gl_budgets.attribute1%TYPE := 'Y';             -- ���呹�v�\�Z�A�g�Ώۃt���O(�A�g�Ώ�)
  cv_budgets_stat_f       CONSTANT gl_budgets.status%TYPE := 'F';                 -- �\�Z��`�̃X�e�[�^�X(�m���)
  cv_actual_flag_b        CONSTANT gl_balances.actual_flag%TYPE := 'B';           -- ���уt���O(�\�Z)
  cv_currency_code        CONSTANT gl_balances.currency_code%TYPE := 'JPY';       -- �ʉ݃R�[�h(�~)
--
  -- ����ʑ��v�\�Z�f�[�^�t�@�C���̘A�g���t
  cv_put_file_date        CONSTANT VARCHAR2(14) := TO_CHAR(SYSDATE,'YYYYMMDDHH24MISS');
--
  -- �t�@�C���o��
  cv_file_type_out   CONSTANT VARCHAR2(10) := 'OUTPUT';      -- ���b�Z�[�W�o��
  cv_file_type_log   CONSTANT VARCHAR2(10) := 'LOG';         -- ���O�o��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ����ʑ��v�\�Z�f�[�^�z��
  TYPE g_segment1_ttype         IS TABLE OF gl_code_combinations.segment5%type
                                            INDEX BY PLS_INTEGER;
  TYPE g_period_year_ttype      IS TABLE OF gl_balances.period_year%type
                                            INDEX BY PLS_INTEGER;
  TYPE g_start_date_ym_ttype    IS TABLE OF VARCHAR2(6)
                                            INDEX BY PLS_INTEGER;
  TYPE g_segment2_ttype         IS TABLE OF gl_code_combinations.segment5%type
                                            INDEX BY PLS_INTEGER;
  TYPE g_segment3_ttype         IS TABLE OF gl_code_combinations.segment5%type
                                            INDEX BY PLS_INTEGER;
  TYPE g_segment4_ttype         IS TABLE OF gl_code_combinations.segment5%type
                                            INDEX BY PLS_INTEGER;
  TYPE g_period_net_sum_ttype   IS TABLE OF NUMBER
                                            INDEX BY PLS_INTEGER;
  gt_segment1                   g_segment1_ttype;                     -- �Z�O�����g1(���)
  gt_period_year                g_period_year_ttype;                  -- ��v�N�x
  gt_start_date_ym              g_start_date_ym_ttype;                -- �N��
  gt_segment2                   g_segment2_ttype;                     -- �Z�O�����g2(����)
  gt_segment3                   g_segment3_ttype;                     -- �Z�O�����g3(����Ȗ�)
  gt_segment4                   g_segment4_ttype;                     -- �Z�O�����g4(�⏕�Ȗ�)
  gt_period_net_sum             g_period_net_sum_ttype;               -- �\�Z���z
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_data_filepath        VARCHAR2(500);                              -- XXCFO:����ʑ��v�\�Z�f�[�^�t�@�C���i�[�p�X
  gv_data_filename        VARCHAR2(100);                              -- XXCFO:����ʑ��v�\�Z�f�[�^�t�@�C����
  gn_set_of_bks_id        NUMBER;                                     -- ��v����ID
  gn_appl_id_gl           fnd_application.application_id%TYPE;        -- �A�v���P�[�V����ID(��ʉ�v)
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ���̓p�����[�^�l���O�o�͏���(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf       OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ���b�Z�[�W�o��
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_out     -- ���b�Z�[�W�o��
      ,ov_errbuf       => lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg);          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     IF ( lv_retcode <> cv_status_normal ) THEN 
       RAISE global_api_expt; 
     END IF; 
--
    -- ���O�o��
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_log     -- ���O�o��
      ,ov_errbuf       => lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg);          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     IF ( lv_retcode <> cv_status_normal ) THEN 
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_system_value
   * Description      : �e��V�X�e���l�擾����(A-2)
   ***********************************************************************************/
  PROCEDURE get_system_value(
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_system_value'; -- �v���O������
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
    -- �v���t�@�C������XXCFO:����ʑ��v�\�Z�f�[�^�t�@�C���i�[�p�X
    gv_data_filepath := FND_PROFILE.VALUE( cv_data_filepath );
    -- �擾�G���[��
    IF ( gv_data_filepath IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_014a01_003 -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof       -- �g�[�N��'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name( cv_data_filepath ))
                                                                       -- XXCFO:����ʑ��v�\�Z�f�[�^�t�@�C���i�[�p�X
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �v���t�@�C������XXCFO:����ʑ��v�\�Z�f�[�^�t�@�C����
    gv_data_filename := FND_PROFILE.VALUE( cv_data_filename );
    -- �擾�G���[��
    IF ( gv_data_filename IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_014a01_003 -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof       -- �g�[�N��'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name( cv_data_filename ))
                                                                       -- XXCFO:����ʑ��v�\�Z�f�[�^�t�@�C����
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �v���t�@�C������GL��v����ID�擾
    gn_set_of_bks_id := TO_NUMBER(FND_PROFILE.VALUE( cv_set_of_bks_id ));
    -- �擾�G���[��
    IF ( gn_set_of_bks_id IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_014a01_003 -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof       -- �g�[�N��'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name( cv_set_of_bks_id ))
                                                                       -- GL��v����ID
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �u��ʉ�v�v�̃A�v���P�[�V����ID���擾
    gn_appl_id_gl := xxccp_common_pkg.get_application( cv_appl_shrt_name_gl );
    -- �擾���ʂ�NULL�Ȃ�΃G���[
    IF ( gn_appl_id_gl IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_014a01_009 -- �f�[�^�擾�G���[
                                                    ,cv_tkn_data       -- �g�[�N��'DATA'
                                                    ,xxcfr_common_pkg.lookup_dictionary(
                                                       cv_msg_kbn_cfo
                                                      ,cv_dict_aplid_sqlgl 
                                                     ))
                                                   ,1
                                                   ,5000);
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_system_value;
--
  /**********************************************************************************
   * Procedure Name   : out_data_filename
   * Description      : ����ʑ��v�\�Z�f�[�^�t�@�C����񃍃O����(A-3)
   ***********************************************************************************/
  PROCEDURE out_data_filename(
    ov_errbuf       OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'out_data_filename'; -- �v���O������
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
    -- �t�@�C�����o�̓��b�Z�[�W
    lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                  ,cv_msg_014a01_004
                                                  ,cv_tkn_file       -- �g�[�N��'FILE_NAME'
                                                  ,gv_data_filename) -- ����ʑ��v�\�Z�f�[�^�t�@�C����
                                                 ,1
                                                 ,5000);
--
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END out_data_filename;
--
  /**********************************************************************************
   * Procedure Name   : get_pl_budget_sum
   * Description      : ����ʑ��v�\�Z�f�[�^�W�v����(A-4)
   ***********************************************************************************/
  PROCEDURE get_pl_budget_sum(
    ov_errbuf       OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_pl_budget_sum'; -- �v���O������
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
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
    -- ����ʑ��v�\�Z�f�[�^���o
    CURSOR get_pl_budget_sum_cur
    IS
      SELECT glcc.segment1                       segment1,
             glbl.period_year                    period_year,
             TO_CHAR( glps.start_date,'YYYYMM' ) start_date_ym,
             glcc.segment2                       segment2,
             glcc.segment3                       segment3,
             glcc.segment4                       segment4,
             SUM(DECODE( glcc.account_type,cv_account_type_e,
                          glbl.period_net_dr - glbl.period_net_cr,
                          glbl.period_net_cr - glbl.period_net_dr )) period_net_sum
      FROM gl_budgets               glbg,
           gl_budget_versions       glbv,
           gl_period_statuses       glps,
           gl_balances              glbl,
           gl_code_combinations     glcc
-- == 2009/07/03 V1.1 Added START ===============================================================
          ,gl_sets_of_books         gsob
          ,gl_budget_period_ranges  gbpr
-- == 2009/07/03 V1.1 Added END   ===============================================================
      WHERE glbg.set_of_books_id        =   gn_set_of_bks_id
        AND glbg.attribute1             =   cv_budgets_att1_y
        AND glbg.status                 =   cv_budgets_stat_f
        AND glbv.budget_type            =   glbg.budget_type
        AND glbv.budget_name            =   glbg.budget_name
        AND glps.set_of_books_id        =   glbg.set_of_books_id
        AND glps.application_id         =   gn_appl_id_gl
        AND glbl.actual_flag            =   cv_actual_flag_b
        AND glbl.currency_code          =   cv_currency_code
        AND glbl.budget_version_id      =   glbv.budget_version_id
        AND glbl.set_of_books_id        =   glbg.set_of_books_id
        AND glbl.period_name            =   glps.period_name
        AND glcc.account_type           IN ( cv_account_type_e,
                                             cv_account_type_r )
        AND glcc.code_combination_id    =   glbl.code_combination_id
-- == 2009/07/03 V1.1 Added START ===============================================================
        AND glcc.chart_of_accounts_id   =   gsob.chart_of_accounts_id
        AND gsob.set_of_books_id        =   gn_set_of_bks_id
        AND glps.set_of_books_id        =   gn_set_of_bks_id
        AND glbv.budget_version_id      =   gbpr.budget_version_id
        AND gbpr.period_year            =   glps.period_year
        AND glps.period_num   BETWEEN gbpr.start_period_num 
                              AND     gbpr.end_period_num 
-- == 2009/07/03 V1.1 Added END   ===============================================================
      GROUP BY glcc.segment1,
               glbl.period_year,
               TO_CHAR( glps.start_date,'YYYYMM' ),
               glcc.segment2,
               glcc.segment3,
               glcc.segment4
      ORDER BY glcc.segment1,
               glbl.period_year,
               TO_CHAR( glps.start_date,'YYYYMM' ),
               glcc.segment2,
               glcc.segment3,
               glcc.segment4
    ;
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
    -- �J�[�\���I�[�v��
    OPEN get_pl_budget_sum_cur;
--
    -- �f�[�^�̈ꊇ�擾
    FETCH get_pl_budget_sum_cur BULK COLLECT INTO
          gt_segment1,
          gt_period_year,
          gt_start_date_ym,
          gt_segment2,
          gt_segment3,
          gt_segment4,
          gt_period_net_sum;
--
    -- �Ώی����̃Z�b�g
    gn_target_cnt := gt_segment1.COUNT;
--
    -- �J�[�\���N���[�Y
    CLOSE get_pl_budget_sum_cur;
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
  END get_pl_budget_sum;
--
  /**********************************************************************************
   * Procedure Name   : put_pl_budget_data_file
   * Description      : ����ʑ��v�\�Z�f�[�^�t�@�C���o�͏���(A-5)
   ***********************************************************************************/
  PROCEDURE put_pl_budget_data_file(
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put_pl_budget_data_file'; -- �v���O������
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
--
    cv_open_mode_w    CONSTANT VARCHAR2(1)  := 'w';     -- �t�@�C���I�[�v�����[�h�i�㏑���j
    cv_delimiter      CONSTANT VARCHAR2(1)  := ',';     -- CSV��؂蕶��
    cv_enclosed       CONSTANT VARCHAR2(1)  := '"';     -- �P��͂ݕ���
--
    -- *** ���[�J���ϐ� ***
    ln_normal_cnt   NUMBER;         -- ���팏��
    ln_loop_cnt     NUMBER;         -- ���[�v�J�E���^
--
    -- �t�@�C���o�͊֘A
    lf_file_hand        UTL_FILE.FILE_TYPE ;    -- �t�@�C���E�n���h���̐錾
    lv_csv_text         VARCHAR2(32000) ;       -- �o�͂P�s��������ϐ�
    lb_fexists          BOOLEAN;                -- �t�@�C�������݂��邩�ǂ���
    ln_file_size        NUMBER;                 -- �t�@�C���̒���
    ln_block_size       NUMBER;                 -- �t�@�C���V�X�e���̃u���b�N�T�C�Y
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
    -- ���[�J���ϐ��̏�����
    ln_normal_cnt := 0;
--
    -- ====================================================
    -- �t�s�k�t�@�C�����݃`�F�b�N
    -- ====================================================
    UTL_FILE.FGETATTR( gv_data_filepath,
                       gv_data_filename,
                       lb_fexists,
                       ln_file_size,
                       ln_block_size );
--
    -- �O��t�@�C�������݂��Ă���
    IF ( lb_fexists ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_014a01_005 -- �t�@�C�������݂��Ă���
                                                   )
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ====================================================
    -- �t�s�k�t�@�C���I�[�v��
    -- ====================================================
    lf_file_hand := UTL_FILE.FOPEN
                      (
                        gv_data_filepath
                       ,gv_data_filename
                       ,cv_open_mode_w
                      ) ;
--
    -- ====================================================
    -- �o�̓f�[�^���o
    -- ====================================================
    <<out_loop>>
    FOR ln_loop_cnt IN gt_segment1.FIRST..gt_segment1.LAST LOOP
--
      -- �o�͕�����쐬
      lv_csv_text := cv_enclosed || gt_segment1( ln_loop_cnt )       || cv_enclosed || cv_delimiter
                  || TO_CHAR( gt_period_year( ln_loop_cnt ))                        || cv_delimiter
                  || gt_start_date_ym( ln_loop_cnt )                                || cv_delimiter
                  || cv_enclosed || gt_segment2( ln_loop_cnt )       || cv_enclosed || cv_delimiter
                  || cv_enclosed || gt_segment3( ln_loop_cnt )       || cv_enclosed || cv_delimiter
                  || cv_enclosed || gt_segment4( ln_loop_cnt )       || cv_enclosed || cv_delimiter
                  || TO_CHAR( gt_period_net_sum( ln_loop_cnt ))                     || cv_delimiter
                  || cv_put_file_date
      ;
--
      -- ====================================================
      -- �t�@�C����������
      -- ====================================================
      UTL_FILE.PUT_LINE( lf_file_hand, lv_csv_text ) ;
--
      -- ====================================================
      -- ���������J�E���g�A�b�v
      -- ====================================================
      ln_normal_cnt := ln_normal_cnt + 1 ;
--
    END LOOP out_loop;
--
    -- ====================================================
    -- �t�s�k�t�@�C���N���[�Y
    -- ====================================================
    UTL_FILE.FCLOSE( lf_file_hand ) ;
--
    gn_normal_cnt := ln_normal_cnt;
--
  EXCEPTION
--
    -- *** �t�@�C���̏ꏊ�������ł� ***
    WHEN UTL_FILE.INVALID_PATH THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_014a01_006 -- �t�@�C���̏ꏊ������
                                                   )
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** �v���ǂ���Ƀt�@�C�����I�[�v���ł��Ȃ����A�܂��͑���ł��܂��� ***
    WHEN UTL_FILE.INVALID_OPERATION THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_014a01_007 -- �t�@�C�����I�[�v���ł��Ȃ�
                                                   )
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** �����ݑ��쒆�ɃI�y���[�e�B���O�E�V�X�e���̃G���[���������܂��� ***
    WHEN UTL_FILE.WRITE_ERROR THEN
      --���t�@�C���N���[�Y�֐���ǉ�
      IF ( UTL_FILE.IS_OPEN ( lf_file_hand )) THEN
        UTL_FILE.FCLOSE( lf_file_hand );
      END IF;
      gn_normal_cnt := ln_normal_cnt;
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_014a01_008 -- �t�@�C���ɏ����݂ł��Ȃ�
                                                   )
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      --���t�@�C���N���[�Y�֐���ǉ�
      IF UTL_FILE.IS_OPEN ( lf_file_hand ) THEN
        UTL_FILE.FCLOSE( lf_file_hand );
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      --���t�@�C���N���[�Y�֐���ǉ�
      IF UTL_FILE.IS_OPEN ( lf_file_hand ) THEN
        UTL_FILE.FCLOSE( lf_file_hand );
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      --���t�@�C���N���[�Y�֐���ǉ�
      IF UTL_FILE.IS_OPEN ( lf_file_hand ) THEN
        UTL_FILE.FCLOSE( lf_file_hand );
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END put_pl_budget_data_file;
--
  /**********************************************************************************
   * Procedure Name   : out_no_target
   * Description      : 0�����b�Z�[�W�o�͏���(A-6)
   ***********************************************************************************/
  PROCEDURE out_no_target(
    ov_errbuf       OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'out_no_target'; -- �v���O������
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
--
    -- *** ���[�J���ϐ� ***
    ln_rec_cnt   NUMBER;         -- ���R�[�h����

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
    -- ����ʑ��v�\�Z�A�g�Ώۂ̗\�Z�������ꍇ�͌ʂ̃��b�Z�[�W�o��
    SELECT COUNT( glbg.budget_name ) rec_cnt
    INTO ln_rec_cnt
    FROM gl_budgets glbg
    WHERE glbg.set_of_books_id = gn_set_of_bks_id
      AND glbg.attribute1      = cv_budgets_att1_y
    ;
    IF ( ln_rec_cnt = 0 ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo     -- 'XXCFO'
                                                    ,cv_msg_014a01_001)  -- �����Ώۗ\�Z�Ȃ�
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �Ώۃf�[�^��0�����b�Z�[�W
    lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo     -- 'XXCFO'
                                                  ,cv_msg_014a01_002)
                                                 ,1
                                                 ,5000);
    lv_errbuf := lv_errmsg;
    RAISE global_api_expt;
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
  END out_no_target;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
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
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    -- PL/SQL�\�̏�����
    gt_segment1.DELETE;         -- �Z�O�����g1(���)
    gt_period_year.DELETE;      -- ��v�N�x
    gt_start_date_ym.DELETE;    -- �N��
    gt_segment2.DELETE;         -- �Z�O�����g2(����)
    gt_segment3.DELETE;         -- �Z�O�����g3(����Ȗ�)
    gt_segment4.DELETE;         -- �Z�O�����g4(�⏕�Ȗ�)
    gt_period_net_sum.DELETE;   -- �\�Z���z
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- =====================================================
    --  ���̓p�����[�^�l���O�o�͏���(A-1)
    -- =====================================================
    init(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  �e��V�X�e���l�擾����(A-2)
    -- =====================================================
    get_system_value(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  ����ʑ��v�\�Z�f�[�^�t�@�C����񃍃O����(A-3)
    -- =====================================================
    out_data_filename(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  ����ʑ��v�\�Z�f�[�^�W�v����(A-4)
    -- =====================================================
    get_pl_budget_sum(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    IF ( gn_target_cnt > 0 ) THEN
--
      -- =====================================================
      --  ����ʑ��v�\�Z�f�[�^�t�@�C���o�͏���(A-5)
      -- =====================================================
      put_pl_budget_data_file(
         lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = cv_status_error) THEN
        --(�G���[����)
        RAISE global_process_expt;
      END IF;
--
    ELSE
--
      -- =====================================================
      --  0�����b�Z�[�W�o�͏���(A-6)
      -- =====================================================
      out_no_target(
         lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = cv_status_error) THEN
        --(�G���[����)
        RAISE global_process_expt;
      END IF;
--
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
    errbuf        OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT VARCHAR2       --   ���^�[���E�R�[�h    --# �Œ� #
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
       lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- ��v�`�[���W���F�ُ�I�����̌����ݒ�
    IF (lv_retcode = cv_status_error) THEN
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
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
END XXCFO014A01C;
/
