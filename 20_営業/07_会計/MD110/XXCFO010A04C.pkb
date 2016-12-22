CREATE OR REPLACE PACKAGE BODY XXCFO010A04C
AS
/*************************************************************************
 * Copyright(c)SCSK Corporation, 2016. All rights reserved.
 * 
 * Package Name    : XXCFO010A04C(body)
 * Description     : �g�cWF�A�g
 * MD.050          : MD050_CFO_010_A04_�g�cWF�A�g
 * Version         : 1.0
 * 
 * Program List
 * --------------- ---- ----- --------------------------------------------
 *  Name           Type  Ret   Description
 * --------------- ---- ----- --------------------------------------------
 *  init              P        ��������                               (A-1)
 *  del_coop_data     P        �g�cWF�A�g�f�[�^�e�[�u���폜����       (A-2)
 *  get_target_data   P        �A�g�Ώۃf�[�^�̒��o����               (A-3)
 *  ins_coop_data     P        �g�cWF�A�g�f�[�^�o�^����               (A-4)
 *  ins_control       P        �g�cWF�A�g�Ǘ��e�[�u���o�^�E�X�V����   (A-5)
 *  get_coop_data     P        �g�cWF�A�g�f�[�^�e�[�u�����o����       (A-6)
 *  put_data_file     P        �g�cWF�A�g�f�[�^�t�@�C���o�͏���       (A-7)
 *  submain           P        ���C�������v���V�[�W��
 *  main              P        �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 * 
 * Change Record
 * ------------- ----- ------------- -------------------------------------
 *  Date          Ver.  Editor        Description
 * ------------- ----- ------------- -------------------------------------
 *  2016-12-09    1.0  SCSK ���H���O  ����쐬
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
  -- ���b�N�G���[
  lock_expt EXCEPTION;
  PRAGMA EXCEPTION_INIT( lock_expt, -54 );
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name         CONSTANT VARCHAR2(100) := 'XXCFO010A04C';               -- �p�b�P�[�W��
--
  --�A�v���P�[�V�����Z�k��
  cv_msg_kbn_cfo      CONSTANT VARCHAR2(5)   := 'XXCFO';                      -- �A�h�I���F��v�E�A�h�I���̈�̃A�v���P�[�V�����Z�k��
  cv_msg_kbn_coi      CONSTANT VARCHAR2(5)   := 'XXCOI';                      -- �A�h�I���F�݌ɁE�A�h�I���̈�̃A�v���P�[�V�����Z�k��
--
  -- ���b�Z�[�W�ԍ�
  cv_msg_coi_00029    CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00029';            -- �f�B���N�g���t���p�X�擾�G���[���b�Z�[�W
  cv_msg_cfo_00001    CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00001';            -- �v���t�@�C���擾�G���[���b�Z�[�W
  cv_msg_cfo_00002    CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00002';            -- �t�@�C�����o�̓��b�Z�[�W
  cv_msg_cfo_00004    CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00004';            -- �Ώۃf�[�^��0�����b�Z�[�W
  cv_msg_cfo_00015    CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00015';            -- �Ɩ����t�擾�G���[���b�Z�[�W
  cv_msg_cfo_00019    CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00019';            -- �f�[�^���b�N�G���[���b�Z�[�W
  cv_msg_cfo_00020    CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00020';            -- �X�V�G���[���b�Z�[�W
  cv_msg_cfo_00024    CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00024';            -- �o�^�G���[���b�Z�[�W
  cv_msg_cfo_00025    CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00025';            -- �f�[�^�폜�G���[���b�Z�[�W
  cv_msg_cfo_00027    CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00027';            -- �t�@�C�������݂��Ă��郁�b�Z�[�W
  cv_msg_cfo_00028    CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00028';            -- �t�@�C���̏ꏊ���������b�Z�[�W
  cv_msg_cfo_00029    CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00029';            -- �t�@�C�����I�[�v���ł��Ȃ����b�Z�[�W
  cv_msg_cfo_00030    CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00030';            -- �t�@�C���ɏ����݂ł��Ȃ����b�Z�[�W
  cv_msg_cfo_00058    CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00058';            -- �Ώۊ��ԃG���[
--
  -- �g�[�N��
  cv_tkn_date_from    CONSTANT VARCHAR2(20) := 'DATE_FROM';                   -- ���tFROM
  cv_tkn_dir_tok      CONSTANT VARCHAR2(20) := 'DIR_TOK';                     -- �f�B���N�g����
  cv_tkn_table        CONSTANT VARCHAR2(20) := 'TABLE';                       -- �e�[�u����
  cv_tkn_errmsg       CONSTANT VARCHAR2(20) := 'ERRMSG';                      -- �G���[���e
  cv_tkn_prof         CONSTANT VARCHAR2(20) := 'PROF_NAME';                   -- �v���t�@�C����
  cv_tkn_file         CONSTANT VARCHAR2(20) := 'FILE_NAME';                   -- �t�@�C����
--
  --���b�Z�[�W�o�͗p(�g�[�N���o�^)
  cv_msgtkn_cfo_50001   CONSTANT VARCHAR2(20) := 'APP-XXCFO1-50001';                   -- �g�cWF�A�g�f�[�^�e�[�u��
  cv_msgtkn_cfo_50002   CONSTANT VARCHAR2(20) := 'APP-XXCFO1-50002';                   -- �g�cWF�A�g�Ǘ��e�[�u��
--
  -- �v���t�@�C��
  cv_set_of_bks_id      CONSTANT VARCHAR2(40) := 'GL_SET_OF_BKS_ID';                   -- ��v����ID
  cv_data_filepath      CONSTANT VARCHAR2(40) := 'XXCFO1_RFD_PAY_DATA_FILEPATH';       -- XXCFO:�g�cWF�A�g�x���f�[�^�t�@�C���i�[�p�X
  cv_data_filename      CONSTANT VARCHAR2(40) := 'XXCFO1_RFD_PAY_DATA_FILENAME';       -- XXCFO:�g�cWF�A�g�x���f�[�^�t�@�C����
--
  -- ���t�^
  cv_format_hh24_mi_ss  CONSTANT VARCHAR2(21) := 'YYYY/MM/DD HH24:MI:SS';              -- YYYY/MM/DD HH24:MI:SS�`��
  cv_format_yyyy_mm_dd  CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';                         -- YYYY/MM/DD�`��
--
  -- �t�@�C���o��
  cv_file_type_log      CONSTANT VARCHAR2(3)  := 'LOG';                                -- ���O�o��
--
  cv_enabled_flag_n     CONSTANT VARCHAR2(1) := 'N';                                   -- ���聁N
  cv_enabled_flag_y     CONSTANT VARCHAR2(1) := 'Y';                                   -- ���聁Y
  cv_user_lang          CONSTANT fnd_lookup_values.language%TYPE := USERENV( 'LANG' ); -- ����
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- �A�g�Ώۃf�[�^�z��
  TYPE g_gl_je_header_id_ttype              IS TABLE OF gl_je_lines.je_header_id%type
                                                        INDEX BY PLS_INTEGER;
  TYPE g_gl_je_line_num_ttype               IS TABLE OF gl_je_lines.je_line_num%type
                                                        INDEX BY PLS_INTEGER;
  TYPE g_gl_period_year_ttype               IS TABLE OF gl_periods.period_year%type
                                                        INDEX BY PLS_INTEGER;
  TYPE g_gl_segment2_ttype                  IS TABLE OF gl_code_combinations.segment2%type
                                                        INDEX BY PLS_INTEGER;
  TYPE g_gl_segment2_name_ttype             IS TABLE OF fnd_flex_values_tl.description%type
                                                        INDEX BY PLS_INTEGER;
  TYPE g_gl_segment6_ttype                  IS TABLE OF gl_code_combinations.segment6%type
                                                        INDEX BY PLS_INTEGER;
  TYPE g_gl_segment6_name_ttype             IS TABLE OF fnd_flex_values_tl.description%type
                                                        INDEX BY PLS_INTEGER;
  TYPE g_gl_segment3_ttype                  IS TABLE OF gl_code_combinations.segment3%type
                                                        INDEX BY PLS_INTEGER;
  TYPE g_gl_segment3_name_ttype             IS TABLE OF fnd_flex_values_tl.description%type
                                                        INDEX BY PLS_INTEGER;
  TYPE g_gl_segment4_ttype                  IS TABLE OF gl_code_combinations.segment4%type
                                                        INDEX BY PLS_INTEGER;
  TYPE g_gl_segment4_name_ttype             IS TABLE OF fnd_flex_values_tl.description%type
                                                        INDEX BY PLS_INTEGER;
  TYPE g_gl_decision_num_ttype              IS TABLE OF gl_je_lines.attribute9%type
                                                        INDEX BY PLS_INTEGER;
  TYPE g_gl_amount_ttype                    IS TABLE OF gl_je_lines.entered_dr%type
                                                        INDEX BY PLS_INTEGER;
  TYPE g_gl_gl_date_ttype                   IS TABLE OF gl_je_lines.effective_date%type
                                                        INDEX BY PLS_INTEGER;
  gt_gl_je_header_id               g_gl_je_header_id_ttype;                   -- �d��_�d��w�b�_ID
  gt_gl_je_line_num                g_gl_je_line_num_ttype;                    -- �d��_�d�󖾍הԍ�
  gt_gl_period_year                g_gl_period_year_ttype;                    -- �d��_�N�x
  gt_gl_segment2                   g_gl_segment2_ttype;                       -- �d��_�Z�O�����g2(����E���_�R�[�h)
  gt_gl_segment2_name              g_gl_segment2_name_ttype;                  -- �d��_�Z�O�����g2(����E���_��)
  gt_gl_segment6                   g_gl_segment6_ttype;                       -- �d��_�Z�O�����g6(��ƃR�[�h)
  gt_gl_segment6_name              g_gl_segment6_name_ttype;                  -- �d��_�Z�O�����g6(��Ɩ�)
  gt_gl_segment3                   g_gl_segment3_ttype;                       -- �d��_�Z�O�����g3(����ȖڃR�[�h)
  gt_gl_segment3_name              g_gl_segment3_name_ttype;                  -- �d��_�Z�O�����g3(����Ȗ�)
  gt_gl_segment4                   g_gl_segment4_ttype;                       -- �d��_�Z�O�����g4(�⏕�ȖڃR�[�h)
  gt_gl_segment4_name              g_gl_segment4_name_ttype;                  -- �d��_�Z�O�����g4(�⏕�Ȗ�)
  gt_gl_decision_num               g_gl_decision_num_ttype;                   -- �d��_�g�c���ϔԍ�
  gt_gl_amount                     g_gl_amount_ttype;                         -- �d��_�x�����z
  gt_gl_gl_date                    g_gl_gl_date_ttype;                        -- �d��_�v��N����
--
  -- �A�g�Ώۃf�[�^�z��
  TYPE g_period_year_ttype                  IS TABLE OF xxcfo_rfd_wf_coop_data.period_year%type
                                                        INDEX BY PLS_INTEGER;
  TYPE g_segment2_ttype                     IS TABLE OF xxcfo_rfd_wf_coop_data.segment2%type
                                                        INDEX BY PLS_INTEGER;
  TYPE g_segment2_name_ttype                IS TABLE OF xxcfo_rfd_wf_coop_data.segment2_name%type
                                                        INDEX BY PLS_INTEGER;
  TYPE g_segment6_ttype                     IS TABLE OF xxcfo_rfd_wf_coop_data.segment6%type
                                                        INDEX BY PLS_INTEGER;
  TYPE g_segment6_name_ttype                IS TABLE OF xxcfo_rfd_wf_coop_data.segment6_name%type
                                                        INDEX BY PLS_INTEGER;
  TYPE g_segment3_ttype                     IS TABLE OF xxcfo_rfd_wf_coop_data.segment3%type
                                                        INDEX BY PLS_INTEGER;
  TYPE g_segment3_name_ttype                IS TABLE OF xxcfo_rfd_wf_coop_data.segment3_name%type
                                                        INDEX BY PLS_INTEGER;
  TYPE g_segment4_ttype                     IS TABLE OF xxcfo_rfd_wf_coop_data.segment4%type
                                                        INDEX BY PLS_INTEGER;
  TYPE g_segment4_name_ttype                IS TABLE OF xxcfo_rfd_wf_coop_data.segment4_name%type
                                                        INDEX BY PLS_INTEGER;
  TYPE g_decision_num_ttype                 IS TABLE OF xxcfo_rfd_wf_coop_data.decision_num%type
                                                        INDEX BY PLS_INTEGER;
  TYPE g_amount_ttype                       IS TABLE OF xxcfo_rfd_wf_coop_data.amount%type
                                                        INDEX BY PLS_INTEGER;
  TYPE g_gl_date_ttype                      IS TABLE OF xxcfo_rfd_wf_coop_data.gl_date%type
                                                        INDEX BY PLS_INTEGER;
  gt_period_year                   g_period_year_ttype;                       -- �N�x
  gt_segment2                      g_segment2_ttype;                          -- �Z�O�����g2(����E���_�R�[�h)
  gt_segment2_name                 g_segment2_name_ttype;                     -- �Z�O�����g2(����E���_��)
  gt_segment6                      g_segment6_ttype;                          -- �Z�O�����g6(��ƃR�[�h)
  gt_segment6_name                 g_segment6_name_ttype;                     -- �Z�O�����g6(��Ɩ�)
  gt_segment3                      g_segment3_ttype;                          -- �Z�O�����g3(����ȖڃR�[�h)
  gt_segment3_name                 g_segment3_name_ttype;                     -- �Z�O�����g3(����Ȗ�)
  gt_segment4                      g_segment4_ttype;                          -- �Z�O�����g4(�⏕�ȖڃR�[�h)
  gt_segment4_name                 g_segment4_name_ttype;                     -- �Z�O�����g4(�⏕�Ȗ�)
  gt_decision_num                  g_decision_num_ttype;                      -- �g�c���ϔԍ�
  gt_amount                        g_amount_ttype;                            -- �x�����z
  gt_gl_date                       g_gl_date_ttype;                           -- �v��N����
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gt_data_filepath        all_directories.directory_name%TYPE DEFAULT NULL;   -- XXCFO:�g�cWF�A�g�f�[�^�t�@�C���i�[�p�X
  gt_coop_date            xxcfo_rfd_wf_control.coop_date%TYPE;                -- �A�g��
  gr_rwc_rowid            ROWID;                                              -- �g�cWF�A�g�Ǘ��e�[�u����ROWID
  gv_control_flag         VARCHAR2(1) DEFAULT 'Y';                            -- �Ǘ��e�[�u�����݃t���O
  gv_recovery_flag        VARCHAR2(1) DEFAULT 'N';                            -- ���J�o���t���O
  gv_data_filename        VARCHAR2(100);                                      -- XXCFO:�g�cWF�A�g�f�[�^�t�@�C����
  gd_coop_date_del        DATE;                                               -- �A�g�f�[�^�폜�p
  gd_coop_date_max        DATE;                                               -- �ŏI�A�g��
  gd_coop_date_from       DATE;                                               -- �A�g���tFrom���t�^
  gd_coop_date_to         DATE;                                               -- �A�g���tTo���t�^
  gd_process_date         DATE;                                               -- �Ɩ����t
  gn_set_of_bks_id        NUMBER;                                             -- GL��v����ID
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_coop_date_from  IN  VARCHAR2,     --   1.�A�g��From
    iv_coop_date_to    IN  VARCHAR2,     --   2.�A�g��To
    ov_errbuf          OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    cv_slash         CONSTANT VARCHAR2(1)   := '/';                    -- �X���b�V��
--
    -- *** ���[�J���ϐ� ***
    lt_dir_path      all_directories.directory_path%TYPE DEFAULT NULL; --�f�B���N�g���p�X
    lv_full_name     VARCHAR2(200) DEFAULT NULL;                       --�f�B���N�g�����{�t�@�C�����A���l
    ld_coop_date_to  DATE;                                             -- �R���J�����g�p�����[�^To�`�F�b�N�p
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
    --==============================================================
    -- �R���J�����g�p�����[�^�o��
    --==============================================================
--
    -- ���O�o��
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_log  -- ���O�o��
      ,iv_conc_param1  => iv_coop_date_from -- �R���J�����g�p�����[�^1
      ,iv_conc_param2  => iv_coop_date_to   -- �R���J�����g�p�����[�^2
      ,ov_errbuf       => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- �v���t�@�C���擾
    --==============================================================
--
    -- GL��v����ID
    gn_set_of_bks_id := TO_NUMBER(FND_PROFILE.VALUE( cv_set_of_bks_id ));
    -- �擾�G���[��
    IF ( gn_set_of_bks_id IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo     -- 'XXCFO'
                                                    ,cv_msg_cfo_00001   -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof        -- �g�[�N��'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name( cv_set_of_bks_id ))
                                                                        -- GL��v����ID
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFO: �g�cWF�A�g�x���f�[�^�t�@�C���i�[�p�X
    gt_data_filepath := FND_PROFILE.VALUE( cv_data_filepath );
    -- �擾�G���[��
    IF ( gt_data_filepath IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo     -- 'XXCFO'
                                                    ,cv_msg_cfo_00001   -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof        -- �g�[�N��'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name( cv_data_filepath ))
                                                                        -- XXCFO:�g�cWF�A�g�x���f�[�^�t�@�C���i�[�p�X
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFO: �g�cWF�A�g�x���f�[�^�t�@�C����
    gv_data_filename := FND_PROFILE.VALUE( cv_data_filename );
    -- �擾�G���[��
    IF ( gv_data_filename IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo     -- 'XXCFO'
                                                    ,cv_msg_cfo_00001   -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof        -- �g�[�N��'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name( cv_data_filename ))
                                                                        -- XXCFO:�g�cWF�A�g�x���f�[�^�t�@�C����
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- �Ɩ����t�擾
    --==================================
--
    -- ���ʊ֐�����Ɩ����t���擾
    gd_process_date := xxccp_common_pkg2.get_process_date;
    -- �擾�G���[��
    IF  ( gd_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg( cv_msg_kbn_cfo        -- �A�v���P�[�V�����Z�k��
                                            ,cv_msg_cfo_00015);    -- ���b�Z�[�W�FAPP-XXCFO1-00015
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- �ŏI�A�g�����擾
    --==================================
    BEGIN
      SELECT rwc.ROWID      row_id
            ,rwc.coop_date  coop_date
      INTO   gr_rwc_rowid
            ,gt_coop_date
      FROM   xxcfo_rfd_wf_control  rwc   -- �g�cWF�A�g�Ǘ��e�[�u��
      FOR UPDATE NOWAIT
      ;
    -- �ŏI�A�g���̐ݒ�
    gd_coop_date_max := gt_coop_date;
--
    EXCEPTION
      -- ���b�N�G���[
      WHEN lock_expt THEN
        ov_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo        -- 'XXCFO'
                                                      ,cv_msg_cfo_00019      -- �f�[�^���b�N�G���[���b�Z�[�W
                                                      ,cv_tkn_table          -- �g�[�N��'TABLE'
                                                      ,cv_msgtkn_cfo_50002   -- �g�cWF�A�g�Ǘ��e�[�u��
                                                      )
                             ,1
                             ,5000);
        ov_errbuf := ov_errmsg;
        ov_retcode := cv_status_error;
      WHEN NO_DATA_FOUND THEN
        -- �ŏI�A�g���ɋƖ����t-1��ݒ�
        gd_coop_date_max := gd_process_date - 1;
        -- �Ǘ��e�[�u�����݃t���O��ݒ�
        gv_control_flag := cv_enabled_flag_n;
    END;
--
    -- �R���J�����g�p�����[�^From�̓��͂��Ȃ��ꍇ
    IF ( iv_coop_date_from IS NULL ) THEN
      -- �A�g���tFrom�ɍŏI�A�g����ݒ�
      gd_coop_date_from := gd_coop_date_max;
    -- �R���J�����g�p�����[�^From�̓��͂�����ꍇ
    ELSE
      -- �A�g���tFrom�ɃR���J�����g�p�����[�^��ݒ�
      gd_coop_date_from := TO_DATE(iv_coop_date_from ,cv_format_hh24_mi_ss);
      -- �A�g���tFrom���ŏI�X�V������̏ꍇ
      IF ( gd_coop_date_from > NVL(gt_coop_date, gd_coop_date_from) ) THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo                                  -- 'XXCFO'
                                                      ,cv_msg_cfo_00058                                -- �Ώۊ��ԃG���[
                                                      ,cv_tkn_date_from                                -- 'DATE_FROM'
                                                      ,TO_CHAR(gd_coop_date_max, cv_format_hh24_mi_ss) -- �ŏI�A�g��
                                                     )
                             ,1
                             ,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- �R���J�����g�p�����[�^To�̓��͂��Ȃ��ꍇ
    IF ( iv_coop_date_to IS NULL ) THEN
      -- �A�g���tTo��SYSDATE��ݒ�
      gd_coop_date_to   := SYSDATE;
    -- �R���J�����g�p�����[�^To�̓��͂�����ꍇ
    ELSE
      -- �R���J�����g�p�����[�^To�`�F�b�N
      ld_coop_date_to := TO_DATE(iv_coop_date_to ,cv_format_hh24_mi_ss);
      -- �R���J�����g�p�����[�^To�����{���ȍ~�̏ꍇ
      IF (ld_coop_date_to >= TRUNC(SYSDATE)) THEN
        gd_coop_date_to := SYSDATE;
      ELSE
        -- �A�g���tTo�ɃR���J�����g�p�����[�^To + 1��ݒ�
        gd_coop_date_to   := TO_DATE(iv_coop_date_to ,cv_format_hh24_mi_ss) + 1;
      END IF;
--
      -- �R���J�����g�p�����[�^To���ŏI�X�V���t���O�̏ꍇ
      IF ( ld_coop_date_to < TRUNC(NVL(gt_coop_date, ld_coop_date_to)) ) THEN
        -- ���J�o���t���O��ݒ�
        gv_recovery_flag := cv_enabled_flag_y;
      END IF;
    END IF;
--
    -- �폜�Ώۂ̘A�g����ݒ�
    gd_coop_date_del  := ADD_MONTHS(gd_process_date ,-12);
--
    --==================================
    -- �f�B���N�g���p�X�擾
    --==================================
    BEGIN
      SELECT    ad.directory_path
      INTO      lt_dir_path
      FROM      all_directories ad
      WHERE     ad.directory_name = gt_data_filepath;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_coi   -- 'XXCOI'
                                                      ,cv_msg_coi_00029 -- �f�B���N�g���p�X�擾�G���[
                                                      ,cv_tkn_dir_tok   -- 'DIR_TOK'
                                                      ,gt_data_filepath -- �t�@�C���i�[�p�X
                                                     )
                             ,1
                             ,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --==================================
    -- IF�t�@�C�����o��
    --==================================
--
    -- �f�B���N�g���p�X + '/' + �t�@�C����
    lv_full_name :=  lt_dir_path || cv_slash || gv_data_filename;
--
    -- �g�cWF�A�g�f�[�^�t�@�C������ݒ�
    lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                  ,cv_msg_cfo_00002
                                                  ,cv_tkn_file       -- �g�[�N��'FILE_NAME'
                                                  ,lv_full_name)     -- �g�cWF�A�g�f�[�^�t�@�C����
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : del_coop_data
   * Description      : �g�cWF�A�g�f�[�^�e�[�u���폜����(A-2)
   ***********************************************************************************/
  PROCEDURE del_coop_data(
    ov_errbuf       OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_coop_data'; -- �v���O������
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
    CURSOR rfd_wf_coop_data_cur
    IS
      SELECT rwc.ROWID
      FROM   xxcfo_rfd_wf_coop_data rwc  -- �g�cWF�A�g�f�[�^�e�[�u��
      WHERE  rwc.coop_date <= gd_coop_date_del
      FOR UPDATE NOWAIT
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
    -- �g�cWF�A�g�f�[�^�e�[�u���̃��b�N���擾
    OPEN rfd_wf_coop_data_cur;
    CLOSE rfd_wf_coop_data_cur;
--
    BEGIN
      -- �g�cWF�A�g�f�[�^�e�[�u���폜
      DELETE xxcfo_rfd_wf_coop_data rwc
      WHERE  rwc.coop_date <= gd_coop_date_del
      ;
--
    EXCEPTION
      -- �G���[�����i�f�[�^�폜�G���[�j
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo        -- 'XXCFO'
                                                      ,cv_msg_cfo_00025      -- �f�[�^�폜�G���[���b�Z�[�W
                                                      ,cv_tkn_table          -- �g�[�N��'TABLE'
                                                      ,cv_msgtkn_cfo_50001   -- �g�cWF�A�g�f�[�^�e�[�u��
                                                      )
                             ,1
                             ,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
  EXCEPTION
    -- ���b�N�G���[
    WHEN lock_expt THEN
      ov_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo        -- 'XXCFO'
                                                    ,cv_msg_cfo_00019      -- �f�[�^���b�N�G���[���b�Z�[�W
                                                    ,cv_tkn_table          -- �g�[�N��'TABLE'
                                                    ,cv_msgtkn_cfo_50001   -- �g�cWF�A�g�f�[�^�e�[�u��
                                                    )
                           ,1
                           ,5000);
      ov_errbuf := ov_errmsg;
      ov_retcode := cv_status_error;
--
      IF ( rfd_wf_coop_data_cur%ISOPEN ) THEN
        CLOSE rfd_wf_coop_data_cur;
      END IF;
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
  END del_coop_data;
--
  /**********************************************************************************
   * Procedure Name   : get_target_data
   * Description      : �A�g�Ώۃf�[�^�̒��o����(A-3)
   ***********************************************************************************/
  PROCEDURE get_target_data(
    ov_errbuf       OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_target_data'; -- �v���O������
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
    cv_actual_flag_a              CONSTANT VARCHAR2(30)  := 'A';                 -- �c���^�C�v
    -- �\�[�X
    cv_receivables                CONSTANT VARCHAR2(30)  := 'Receivables';       -- ���|�Ǘ�
    cv_payables                   CONSTANT VARCHAR2(30)  := 'Payables';          -- ���|�Ǘ�
    cv_je_source_1                CONSTANT VARCHAR2(30)  := '1';                 -- GL�������
    -- �J�e�S��
    cv_credit_memos               CONSTANT VARCHAR2(30)  := 'Credit Memos';      -- �N���W�b�g�����i���|�j
    cv_sales_invoices             CONSTANT VARCHAR2(30)  := 'Sales Invoices';    -- ���㐿�����i���|�j
    cv_purchase_invoices          CONSTANT VARCHAR2(30)  := 'Purchase Invoices'; -- �d���������i���|�j
    cv_je_category_1              CONSTANT VARCHAR2(30)  := '1';                 -- �U�֓`�[�iGL������́j
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �A�g�Ώۃf�[�^���o
    CURSOR get_target_data_cur
    IS
      -- �����f�[�^�̎擾
      SELECT /*+
                LEADING(gjh ,gjl ,gcc)
                USE_NL (gcc ,rwcm)
                INDEX  (gcc GL_CODE_COMBINATIONS_U1)
                INDEX  (rwcm XXCFO_RFD_WF_COOP_MST_N01)
              */
             gjl.je_header_id                                             je_header_id    -- �d��w�b�_ID
            ,gjl.je_line_num                                              je_line_num     -- �d�󖾍הԍ�
            ,(
              SELECT gp.period_year
              FROM   gl_sets_of_books  glb  -- ��v����}�X�^
                    ,gl_periods        gp   -- ��v�J�����_
              WHERE  glb.set_of_books_id       =  gn_set_of_bks_id
              AND    gp.period_set_name        =  glb.period_set_name
              AND    gp.adjustment_period_flag =  cv_enabled_flag_n
              AND    gp.start_date             <= gjl.effective_date
              AND    gp.end_date               >= gjl.effective_date
             )                                                            period_year     -- �N�x
            , gcc.segment2                                                segment2        -- ����E���_�R�[�h
            ,(SELECT REPLACE(xdv.description, '"', '""')  segment2_name
              FROM   xx03_departments_v xdv           -- ����}�X�^
              WHERE  gcc.segment2 = xdv.flex_value
              AND    ROWNUM = 1)                                          segment2_name   -- ����E���_��
            ,gcc.segment6                                                 segment6        -- ��ƃR�[�h
            ,(SELECT REPLACE(xbtv.description, '"', '""') segment6_name
              FROM   xx03_business_types_v xbtv       -- ���Ƌ敪�}�X�^
              WHERE  gcc.segment6 = xbtv.flex_value
              AND    ROWNUM = 1)                                          segment6_name   -- ��Ɩ�
            ,gcc.segment3                                                 segment3        -- ����ȖڃR�[�h
            ,(SELECT REPLACE(xav.description, '"', '""')  segment3_name
              FROM   xx03_accounts_v xav              -- ����Ȗڃ}�X�^
              WHERE  gcc.segment3 = xav.flex_value
              AND    ROWNUM = 1)                                          segment3_name   -- ����Ȗ�
            ,gcc.segment4                                                 segment4        -- �⏕�ȖڃR�[�h
            ,(SELECT REPLACE(xsav.description, '"', '""')  segment4_name
              FROM   xx03_sub_accounts_v xsav         -- �⏕�Ȗڃ}�X�^
              WHERE  gcc.segment4 = xsav.flex_value 
              AND    gcc.segment3 = xsav.parent_flex_value_low
              AND    ROWNUM = 1)                                          segment4_name   -- �⏕�Ȗ�
            ,gjl.attribute9                                               decision_num    -- �g�c���ϔԍ�
            ,NVL(gjl.entered_dr,0) - NVL(gjl.entered_cr,0)                amount          -- �x�����z
            ,gjl.effective_date                                           gl_date         -- �v��N����
      FROM   gl_je_headers          gjh   -- GL�d��w�b�_
            ,gl_je_lines            gjl   -- GL�d�󖾍�
            ,gl_code_combinations   gcc   -- ����Ȗڑg�����}�X�^
            ,xxcfo_rfd_wf_coop_mst  rwcm  -- �g�cWF�A�g�g�����}�X�^
      WHERE  gjh.creation_date       >= gd_coop_date_from
      AND    gjh.creation_date       <  gd_coop_date_to
      AND    gjh.set_of_books_id     =  gn_set_of_bks_id
      AND    gjh.actual_flag         =  cv_actual_flag_a
      AND    gjh.je_source           IN (
                                          cv_receivables       -- ���|�Ǘ�
                                         ,cv_payables          -- ���|�Ǘ�
                                         ,cv_je_source_1       -- GL�������
                                        )
      AND    gjh.je_category         IN (
                                          cv_credit_memos      -- �N���W�b�g�����i���|�j
                                         ,cv_sales_invoices    -- ���㐿�����i���|�j
                                         ,cv_purchase_invoices -- �d���������i���|�j
                                         ,cv_je_category_1     -- �U�֓`�[�iGL������́j
                                        )
      AND    gjh.je_header_id        =  gjl.je_header_id
      AND    gjl.code_combination_id =  gcc.code_combination_id
      AND    gcc.segment3            =  rwcm.segment3                    -- ����ȖڃR�[�h
      AND    gcc.segment4            =  rwcm.segment4                    -- �⏕�ȖڃR�[�h
      AND    gcc.segment6            =  NVL(rwcm.segment6 ,gcc.segment6) -- ��ƃR�[�h
      AND    gd_coop_date_from       >= NVL(rwcm.start_date_active ,gd_coop_date_from)
      AND    gd_coop_date_to         <= NVL(rwcm.end_date_active ,gd_coop_date_to)
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
    OPEN get_target_data_cur;
--
    -- �f�[�^�̈ꊇ�擾
    FETCH get_target_data_cur BULK COLLECT INTO
          gt_gl_je_header_id,
          gt_gl_je_line_num,
          gt_gl_period_year,
          gt_gl_segment2,
          gt_gl_segment2_name,
          gt_gl_segment6,
          gt_gl_segment6_name,
          gt_gl_segment3,
          gt_gl_segment3_name,
          gt_gl_segment4,
          gt_gl_segment4_name,
          gt_gl_decision_num,
          gt_gl_amount,
          gt_gl_gl_date;
--
    -- �Ώی����̃Z�b�g
    gn_target_cnt := gt_gl_je_header_id.COUNT;
--
    -- �Ώی���0���̏ꍇ�A�x��
    IF ( gn_target_cnt = 0 ) THEN
      -- �Ώۃf�[�^��0�����b�Z�[�W
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo     -- 'XXCFO'
                                                    ,cv_msg_cfo_00004)
                                                   ,1
                                                   ,5000);
--
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
--
    END IF;
    -- �J�[�\���N���[�Y
    CLOSE get_target_data_cur;
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
  END get_target_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_coop_data
   * Description      : �g�cWF�A�g�f�[�^�o�^����(A-4)
   ***********************************************************************************/
  PROCEDURE ins_coop_data(
    ov_errbuf       OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_coop_data'; -- �v���O������
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
    BEGIN
--
      FORALL i IN 1..gt_gl_je_header_id.COUNT
        -- �g�cWF�A�g�f�[�^�e�[�u���ꊇ�o�^
        INSERT INTO xxcfo_rfd_wf_coop_data          -- �g�cWF�A�g�f�[�^�e�[�u��
          (
            je_header_id                        -- 1.�d��w�b�_ID
           ,je_line_num                         -- 2.�d�󖾍הԍ�
           ,period_year                         -- 3.�N�x
           ,segment2                            -- 4.����E���_�R�[�h
           ,segment2_name                       -- 5.����E���_��
           ,segment6                            -- 6.��ƃR�[�h
           ,segment6_name                       -- 7.��Ɩ�
           ,segment3                            -- 8.����ȖڃR�[�h
           ,segment3_name                       -- 9.����Ȗ�
           ,segment4                            -- 10�⏕�ȖڃR�[�h
           ,segment4_name                       -- 11�⏕�Ȗ�
           ,decision_num                        -- 12.�g�c���ٔԍ�
           ,amount                              -- 13.�x�����z
           ,gl_date                             -- 14.�v��N����
           ,coop_date                           -- 15.�A�g��
           ,created_by                          -- 16.�쐬��
           ,creation_date                       -- 17.�쐬��
           ,last_updated_by                     -- 18.�ŏI�X�V��
           ,last_update_date                    -- 19.�ŏI�X�V��
           ,last_update_login                   -- 20.�ŏI�X�V���O�C��
           ,request_id                          -- 21.�v��ID
           ,program_application_id              -- 22.�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
           ,program_id                          -- 23.�R���J�����g�E�v���O����ID
           ,program_update_date                 -- 24.�v���O�����X�V��
          )VALUES(
            gt_gl_je_header_id(i)              -- 1.�d��w�b�_ID
           ,gt_gl_je_line_num(i)               -- 2.�d�󖾍הԍ�
           ,gt_gl_period_year(i)               -- 3.�N�x
           ,gt_gl_segment2(i)                  -- 4.����E���_�R�[�h
           ,gt_gl_segment2_name(i)             -- 5.����E���_��
           ,gt_gl_segment6(i)                  -- 6.��ƃR�[�h
           ,gt_gl_segment6_name(i)             -- 7.��Ɩ�
           ,gt_gl_segment3(i)                  -- 8.����ȖڃR�[�h
           ,gt_gl_segment3_name(i)             -- 9.����Ȗ�
           ,gt_gl_segment4(i)                  -- 10�⏕�ȖڃR�[�h
           ,gt_gl_segment4_name(i)             -- 11�⏕�Ȗ�
           ,gt_gl_decision_num(i)              -- 12.�g�c���ٔԍ�
           ,gt_gl_amount(i)                    -- 13.�x�����z
           ,gt_gl_gl_date(i)                   -- 14.�v��N����
           ,gd_coop_date_to                    -- 15.�A�g��
           ,cn_created_by                      -- 16.�쐬��
           ,cd_creation_date                   -- 17.�쐬��
           ,cn_last_updated_by                 -- 18.�ŏI�X�V��
           ,cd_last_update_date                -- 19.�ŏI�X�V��
           ,cn_last_update_login               -- 20.�ŏI�X�V���O�C��
           ,cn_request_id                      -- 21.�v��ID
           ,cn_program_application_id          -- 22.�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
           ,cn_program_id                      -- 23.�R���J�����g�E�v���O����ID
           ,cd_program_update_date             -- 24.�v���O�����X�V��
          );
    EXCEPTION
      WHEN OTHERS THEN
       lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cfo             -- XXCFO
                                                      ,cv_msg_cfo_00024           -- �f�[�^�o�^�G���[
                                                      ,cv_tkn_table               -- �g�[�N��'TABLE'
                                                      ,cv_msgtkn_cfo_50001        -- �g�cWF�A�g�f�[�^�e�[�u��
                                                      ,cv_tkn_errmsg              -- �g�[�N��'ERRMSG'
                                                      ,SQLERRM                    -- SQL�G���[���b�Z�[�W
                                                     )
                            ,1
                            ,5000);
       lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
       RAISE global_api_expt;
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
  END ins_coop_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_control
   * Description      : �g�cWF�A�g�Ǘ��e�[�u���o�^�E�X�V����(A-5)
   ***********************************************************************************/
  PROCEDURE ins_control(
    ov_errbuf       OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_control'; -- �v���O������
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
    -- �Ǘ��e�[�u�������݂��Ȃ��ꍇ
    IF ( gv_control_flag = cv_enabled_flag_n ) THEN
      BEGIN
        -- �g�cWF�A�g�Ǘ��e�[�u���o�^
        INSERT INTO xxcfo_rfd_wf_control   -- �g�cWF�A�g�Ǘ��e�[�u��
          (
            coop_date                  -- 1.�A�g��
           ,created_by                 -- 2.�쐬��
           ,creation_date              -- 3.�쐬��
           ,last_updated_by            -- 4.�ŏI�X�V��
           ,last_update_date           -- 5.�ŏI�X�V��
           ,last_update_login          -- 6.�ŏI�X�V���O�C��
           ,request_id                 -- 7.�v��ID
           ,program_application_id     -- 8.�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
           ,program_id                 -- 9.�R���J�����g�E�v���O����ID
           ,program_update_date        -- 10.�v���O�����X�V��
          )VALUES(
            gd_coop_date_to            -- 1.�A�g��
           ,cn_created_by              -- 2.�쐬��
           ,cd_creation_date           -- 3.�쐬��
           ,cn_last_updated_by         -- 4.�ŏI�X�V��
           ,cd_last_update_date        -- 5.�ŏI�X�V��
           ,cn_last_update_login       -- 6.�ŏI�X�V���O�C��
           ,cn_request_id              -- 7.�v��ID
           ,cn_program_application_id  -- 8.�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
           ,cn_program_id              -- 9.�R���J�����g�E�v���O����ID
           ,cd_program_update_date     -- 10.�v���O�����X�V��
          );
      EXCEPTION
        WHEN OTHERS THEN
         lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cfo             -- XXCFO
                                                        ,cv_msg_cfo_00024           -- �f�[�^�o�^�G���[
                                                        ,cv_tkn_table               -- �g�[�N��'TABLE'
                                                        ,cv_msgtkn_cfo_50002        -- �g�cWF�A�g�Ǘ��e�[�u��
                                                        ,cv_tkn_errmsg              -- �g�[�N��'ERRMSG'
                                                        ,SQLERRM                    -- SQL�G���[���b�Z�[�W
                                                       )
                              ,1
                              ,5000);
         lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
         RAISE global_api_expt;
      END;
    -- �Ǘ��e�[�u�������݂���ꍇ
    ELSE
      BEGIN
        UPDATE xxcfo_rfd_wf_control rwc
        SET rwc.coop_date              = gd_coop_date_to           -- �A�g��
           ,rwc.last_updated_by        = cn_last_updated_by        -- �ŏI�X�V��
           ,rwc.last_update_date       = cd_last_update_date       -- �ŏI�X�V��
           ,rwc.last_update_login      = cn_last_update_login      -- �ŏI�X�V���O�C��
           ,rwc.request_id             = cn_request_id             -- �v��ID
           ,rwc.program_application_id = cn_program_application_id -- �v���O�����A�v���P�[�V����ID
           ,rwc.program_id             = cn_program_id             -- �v���O����ID
           ,rwc.program_update_date    = cd_program_update_date    -- �v���O�����X�V��
        WHERE rwc.ROWID = gr_rwc_rowid
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cfo           -- XXCFO
                                                         ,cv_msg_cfo_00020         -- �f�[�^�o�^�G���[
                                                         ,cv_tkn_table             -- �g�[�N��'TABLE'
                                                         ,cv_msgtkn_cfo_50002      -- �g�cWF�A�g�Ǘ��e�[�u��
                                                         ,cv_tkn_errmsg            -- �g�[�N��'ERRMSG'
                                                         ,SQLERRM                  -- SQL�G���[���b�Z�[�W
                                                        )
                               ,1
                               ,5000);
          lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
          RAISE global_api_expt;
      END;
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
  END ins_control;
--
  /**********************************************************************************
   * Procedure Name   : get_coop_data
   * Description      : �g�cWF�A�g�f�[�^�e�[�u�����o����(A-6)
   ***********************************************************************************/
  PROCEDURE get_coop_data(
    ov_errbuf       OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_coop_data'; -- �v���O������
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
    -- �A�g�Ώۃf�[�^���o
    CURSOR get_coop_data_cur
    IS
      SELECT rwcd.period_year               period_year                -- �N�x
            ,rwcd.segment2                  segment2                   -- ����E���_�R�[�h
            ,rwcd.segment2_name             segment2_name              -- ����E���_��
            ,rwcd.segment6                  segment6                   -- ��ƃR�[�h
            ,rwcd.segment6_name             segment6_name              -- ��Ɩ�
            ,rwcd.segment3                  segment3                   -- ����ȖڃR�[�h
            ,rwcd.segment3_name             segment3_name              -- ����Ȗ�
            ,rwcd.segment4                  segment4                   -- �⏕�ȖڃR�[�h
            ,rwcd.segment4_name             segment4_name              -- �⏕�Ȗ�
            ,rwcd.decision_num              decision_num               -- �g�c���ٔԍ�
            ,rwcd.amount                    amount                     -- �x�����z
            ,rwcd.gl_date                   gl_date                    -- �v��N����
      FROM   xxcfo_rfd_wf_coop_data  rwcd   -- �g�cWF�A�g�f�[�^�e�[�u��
      WHERE  rwcd.request_id = cn_request_id
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
    OPEN get_coop_data_cur;
--
    -- �f�[�^�̈ꊇ�擾
    FETCH get_coop_data_cur BULK COLLECT INTO
          gt_period_year,
          gt_segment2,
          gt_segment2_name,
          gt_segment6,
          gt_segment6_name,
          gt_segment3,
          gt_segment3_name,
          gt_segment4,
          gt_segment4_name,
          gt_decision_num,
          gt_amount,
          gt_gl_date;
--
    -- �J�[�\���N���[�Y
    CLOSE get_coop_data_cur;
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
  END get_coop_data;
--
  /**********************************************************************************
   * Procedure Name   : put_data_file
   * Description      : �g�cWF�A�g�f�[�^�t�@�C���o�͏���(A-7)
   ***********************************************************************************/
  PROCEDURE put_data_file(
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put_data_file'; -- �v���O������
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
    cn_max_linesize     CONSTANT NUMBER       := 32767;                     -- �t�@�C����1�s������̍ő啶����
    cv_open_mode_w      CONSTANT VARCHAR2(1)  := 'w';                       -- �t�@�C���I�[�v�����[�h�i�㏑���j
    cv_delimiter        CONSTANT VARCHAR2(1)  := ',';                       -- CSV��؂蕶��
    cv_enclosed         CONSTANT VARCHAR2(1)  := '"';                       -- �P��͂ݕ���
    cv_csv_output_head  CONSTANT VARCHAR2(22) := 'XXCFO1_CSV_OUTPUT_HEAD';  -- �g�cWF�A�g�x��CSV�o�͗p�w�b�_
--
    -- *** ���[�J���ϐ� ***
    ln_normal_cnt   NUMBER;         -- ���팏��
    ln_loop_cnt     NUMBER;         -- ���[�v�J�E���^
--
    -- �t�@�C���o�͊֘A
    lf_file_hand        UTL_FILE.FILE_TYPE ;    -- �t�@�C���E�n���h���̐錾
    lv_csv_text_all     VARCHAR2(32767) ;       -- �o�͂P�s������������p
    lv_csv_text         VARCHAR2(32767) ;       -- �o�͂P�s��������ϐ�
    lb_fexists          BOOLEAN;                -- �t�@�C�������݂��邩�ǂ���
    ln_file_size        NUMBER;                 -- �t�@�C���̒���
    ln_block_size       NUMBER;                 -- �t�@�C���V�X�e���̃u���b�N�T�C�Y
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR get_csv_output_head_cur
    IS
      SELECT flv.description
      FROM   fnd_lookup_values  flv
      WHERE  flv.lookup_type   =  cv_csv_output_head
      AND    flv.language      =  cv_user_lang
      AND    gd_coop_date_from >= NVL(flv.start_date_active, gd_coop_date_from)
      AND    gd_coop_date_to   <= NVL(flv.end_date_active, gd_coop_date_to)
      AND    flv.enabled_flag  =  cv_enabled_flag_y
      ORDER BY flv.lookup_code
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
    -- ���[�J���ϐ��̏�����
    ln_normal_cnt := 0;
--
    -- ====================================================
    -- �t�s�k�t�@�C�����݃`�F�b�N
    -- ====================================================
    UTL_FILE.FGETATTR( gt_data_filepath,
                       gv_data_filename,
                       lb_fexists,
                       ln_file_size,
                       ln_block_size );
--
    -- �O��t�@�C�������݂��Ă���
    IF ( lb_fexists ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_cfo_00027  -- �t�@�C�������݂��Ă���
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
                        gt_data_filepath
                       ,gv_data_filename
                       ,cv_open_mode_w
                       ,cn_max_linesize
                      ) ;
--
    -- �Ώی��������݂���ꍇ
    IF ( gn_target_cnt > 0 ) THEN
      -- ====================================================
      -- �w�b�_���ڒ��o
      -- ====================================================
      FOR csv_output_head_rec  IN  get_csv_output_head_cur
        LOOP
          IF  ( get_csv_output_head_cur%ROWCOUNT = 1 ) THEN
            lv_csv_text :=  csv_output_head_rec.description;
          ELSE
            lv_csv_text :=  lv_csv_text || cv_delimiter || cv_enclosed || csv_output_head_rec.description || cv_enclosed;
          END IF;
      END LOOP;
--
      -- ���s�R�[�h�t��
      lv_csv_text :=  lv_csv_text || CHR(13) || CHR(10);
--
      -- �ő啶��������p
      lv_csv_text_all := lv_csv_text;
--
      -- ====================================================
      -- �w�b�_���ڃt�@�C����������
      -- ====================================================
      UTL_FILE.PUT( lf_file_hand, lv_csv_text ) ;
--
      -- ====================================================
      -- �o�̓f�[�^���o
      -- ====================================================
      <<out_loop>>
      FOR ln_loop_cnt IN gt_period_year.FIRST..gt_period_year.LAST LOOP
--
        -- �o�͕�����쐬
        lv_csv_text := cv_enclosed || gt_period_year(ln_loop_cnt)                               || cv_enclosed || cv_delimiter       -- �N�x
                    || cv_enclosed || gt_segment2(ln_loop_cnt)                                  || cv_enclosed || cv_delimiter       -- ����E���_�R�[�h
                    || cv_enclosed || gt_segment2_name(ln_loop_cnt)                             || cv_enclosed || cv_delimiter       -- ����E���_��
                    || cv_enclosed || gt_segment6(ln_loop_cnt)                                  || cv_enclosed || cv_delimiter       -- ��ƃR�[�h
                    || cv_enclosed || gt_segment6_name(ln_loop_cnt)                             || cv_enclosed || cv_delimiter       -- ��Ɩ�
                    || cv_enclosed || gt_segment3(ln_loop_cnt)                                  || cv_enclosed || cv_delimiter       -- ����ȖڃR�[�h
                    || cv_enclosed || gt_segment3_name(ln_loop_cnt)                             || cv_enclosed || cv_delimiter       -- ����Ȗ�
                    || cv_enclosed || gt_segment4(ln_loop_cnt)                                  || cv_enclosed || cv_delimiter       -- �⏕�ȖڃR�[�h
                    || cv_enclosed || gt_segment4_name(ln_loop_cnt)                             || cv_enclosed || cv_delimiter       -- �⏕�Ȗ�
                    || cv_enclosed || gt_decision_num(ln_loop_cnt)                              || cv_enclosed || cv_delimiter       -- �g�c���ٔԍ�
                    || cv_enclosed || TO_CHAR(gt_amount(ln_loop_cnt))                           || cv_enclosed || cv_delimiter       -- �x�����z
                    || cv_enclosed || TO_CHAR(gt_gl_date(ln_loop_cnt), cv_format_yyyy_mm_dd)    || cv_enclosed || cv_delimiter       -- �v��N����
                    || cv_enclosed || ''                                                        || cv_enclosed || cv_delimiter       -- �\������1
                    || cv_enclosed || ''                                                        || cv_enclosed || cv_delimiter       -- �\������2
                    || cv_enclosed || ''                                                        || cv_enclosed || cv_delimiter       -- �\������3
                    || cv_enclosed || ''                                                        || cv_enclosed || cv_delimiter       -- �\������4
                    || cv_enclosed || ''                                                        || cv_enclosed || cv_delimiter       -- �\������5
                    || cv_enclosed || ''                                                        || cv_enclosed || cv_delimiter       -- �\������6
                    || cv_enclosed || ''                                                        || cv_enclosed || cv_delimiter       -- �\������7
                    || cv_enclosed || ''                                                        || cv_enclosed || CHR(13) || CHR(10) -- �\������8
        ;
--
        -- ====================================================
        -- �t�@�C����������
        -- ====================================================
        UTL_FILE.PUT( lf_file_hand, lv_csv_text ) ;
--
        -- ====================================================
        -- ���������J�E���g�A�b�v
        -- ====================================================
        ln_normal_cnt := ln_normal_cnt + 1 ;
--
        -- �ő啶��������p
        lv_csv_text_all := lv_csv_text_all || lv_csv_text;
--
        -- 30000byte�𒴂����珑������
        IF ( LENGTHB(lv_csv_text_all) > 30000 ) THEN
          UTL_FILE.FFLUSH( lf_file_hand );
          lv_csv_text_all := NULL;
        END IF;
--
      END LOOP out_loop;
--
    END IF;
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
                                                    ,cv_msg_cfo_00028  -- �t�@�C���̏ꏊ������
                                                   )
                                                   ,1
                                                   ,5000);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** �v���ǂ���Ƀt�@�C�����I�[�v���ł��Ȃ����A�܂��͑���ł��܂��� ***
    WHEN UTL_FILE.INVALID_OPERATION THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_cfo_00029  -- �t�@�C�����I�[�v���ł��Ȃ�
                                                   )
                                                   ,1
                                                   ,5000);
      lv_errbuf  := lv_errmsg;
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
                                                    ,cv_msg_cfo_00030  -- �t�@�C���ɏ����݂ł��Ȃ�
                                                   )
                                                   ,1
                                                   ,5000);
      lv_errbuf  := lv_errmsg;
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
  END put_data_file;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_coop_date_from  IN  VARCHAR2,     --   1.�A�g��From
    iv_coop_date_to    IN  VARCHAR2,     --   2.�A�g��To
    ov_errbuf          OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    gn_target_cnt       := 0;
    gn_normal_cnt       := 0;
    gn_error_cnt        := 0;
    gn_warn_cnt         := 0;
--
    -- PL/SQL�\�̏�����
    gt_gl_je_header_id.DELETE;              -- �d��_�d��w�b�_ID
    gt_gl_je_line_num.DELETE;               -- �d��_�d�󖾍הԍ�
    gt_gl_period_year.DELETE;               -- �d��_�N�x
    gt_gl_segment2.DELETE;                  -- �d��_�Z�O�����g2(����E���_�R�[�h)
    gt_gl_segment2_name.DELETE;             -- �d��_�Z�O�����g2(����E���_��)
    gt_gl_segment6.DELETE;                  -- �d��_�Z�O�����g6(��ƃR�[�h)
    gt_gl_segment6_name.DELETE;             -- �d��_�Z�O�����g6(��Ɩ�)
    gt_gl_segment3.DELETE;                  -- �d��_�Z�O�����g3(����ȖڃR�[�h)
    gt_gl_segment3_name.DELETE;             -- �d��_�Z�O�����g3(����Ȗ�)
    gt_gl_segment4.DELETE;                  -- �d��_�Z�O�����g4(�⏕�ȖڃR�[�h)
    gt_gl_segment4_name.DELETE;             -- �d��_�Z�O�����g4(�⏕�Ȗ�)
    gt_gl_decision_num.DELETE;              -- �d��_�g�c���ϔԍ�
    gt_gl_amount.DELETE;                    -- �d��_�x�����z
    gt_gl_gl_date.DELETE;                   -- �d��_�v��N����
--
    gt_period_year.DELETE;                  -- �N�x
    gt_segment2.DELETE;                     -- �Z�O�����g2(����E���_�R�[�h)
    gt_segment2_name.DELETE;                -- �Z�O�����g2(����E���_��)
    gt_segment6.DELETE;                     -- �Z�O�����g6(��ƃR�[�h)
    gt_segment6_name.DELETE;                -- �Z�O�����g6(��Ɩ�)
    gt_segment3.DELETE;                     -- �Z�O�����g3(����ȖڃR�[�h)
    gt_segment3_name.DELETE;                -- �Z�O�����g3(����Ȗ�)
    gt_segment4.DELETE;                     -- �Z�O�����g4(�⏕�ȖڃR�[�h)
    gt_segment4_name.DELETE;                -- �Z�O�����g4(�⏕�Ȗ�)
    gt_decision_num.DELETE;                 -- �g�c���ϔԍ�
    gt_amount.DELETE;                       -- �x�����z
    gt_gl_date.DELETE;                      -- �v��N����
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- =====================================================
    --  ��������(A-1)
    -- =====================================================
    init(
       iv_coop_date_from     -- 1.�A�g��From
      ,iv_coop_date_to       -- 2.�A�g��To
      ,lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  �g�cWF�A�g�f�[�^�e�[�u���폜����(A-2)
    -- =====================================================
    del_coop_data(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  �A�g�Ώۃf�[�^�̒��o����(A-3)
    -- =====================================================
    get_target_data(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- �l���擾�ł����ꍇ
    IF ( gn_target_cnt > 0 ) THEN
      -- =====================================================
      --  �g�cWF�A�g�f�[�^�o�^����(A-4)
      -- =====================================================
      ins_coop_data(
         lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = cv_status_error) THEN
        --(�G���[����)
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- ���J�o���t���O��'Y'�ł͂Ȃ��ꍇ
    IF ( gv_recovery_flag <> cv_enabled_flag_y ) THEN
      -- =====================================================
      --  �g�cWF�A�g�Ǘ��e�[�u���o�^�E�X�V����(A-5)
      -- =====================================================
      ins_control(
         lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = cv_status_error) THEN
        --(�G���[����)
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- =====================================================
    --  �g�cWF�A�g�f�[�^�e�[�u�����o����(A-6)
    -- =====================================================
    get_coop_data(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  �g�cWF�A�g�f�[�^�t�@�C���o�͏���(A-7)
    -- =====================================================
    put_data_file(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    -- �Ώی�����0���̏ꍇ
    ELSIF ( gn_target_cnt = 0 ) THEN
      -- �x���I��
      ov_retcode := cv_status_warn;
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
    errbuf             OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode            OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_coop_date_from  IN  VARCHAR2,      --   1.�A�g��From
    iv_coop_date_to    IN  VARCHAR2       --   2.�A�g��To
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
       iv_coop_date_from  -- 1.�A�g��From
      ,iv_coop_date_to    -- 2.�A�g��To
      ,lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- ��v�`�[���W���F�ُ�I�����̌����ݒ�
    IF (lv_retcode = cv_status_error) THEN
      gn_target_cnt       := 0;
      gn_normal_cnt       := 0;
      gn_error_cnt        := 1;
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
    --
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
END XXCFO010A04C;
/
