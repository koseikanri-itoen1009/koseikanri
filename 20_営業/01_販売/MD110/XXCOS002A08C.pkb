CREATE OR REPLACE PACKAGE BODY APPS.XXCOS002A08C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : �ڕW�B���󋵃��[���z�M(body)
 * Description      : ����ڕW�̃��[���z�M���s��
 * MD.050           : �ڕW�B���󋵃��[���z�M <MD050_COS_002_A08>
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  del_send_mail_relate   ���[���z�M�֘A�e�[�u���폜(A-2)
 *  ins_send_mail_trn      ���[���z�M�󋵃g�����쐬(A-3)
 *  ins_target_date        ���[���z�M�Ώۈꎞ�e�[�u���쐬(A-4)
 *  edit_mail_text         ���[���{���ҏW(A-5)
 *  get_send_mail_data_e   ���[���z�M�f�[�^�擾(�]�ƈ��v)(A-6)
 *  get_send_mail_data_b   ���[���z�M�f�[�^�擾(���_�v)(A-7)
 *  ins_wf_mail            �A���[�g���[�����M�e�[�u���쐬(A-8)
 *  upd_send_mail_trn      ���[���z�M�󋵃g�����X�V(A-9)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 * 2013/06/12    1.0   K.Kiriu          �V�K�쐬
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
  lock_expt            EXCEPTION;         -- ���b�N��O
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
  no_data_expt         EXCEPTION;         -- �Ώۃf�[�^�Ȃ���O
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCOS002A08C';   -- �p�b�P�[�W��
  --�ėp
  cv_yes           CONSTANT VARCHAR2(1)   := 'Y';              -- �ėp(Y)
  cv_no            CONSTANT VARCHAR2(1)   := 'N';              -- �ėp(N)
  cn_1             CONSTANT NUMBER        := 1;                -- �ėp(1)
  --�A�v���P�[�V����
  cv_app_xxcos     CONSTANT VARCHAR2(5)   := 'XXCOS';
  --�p�����[�^
  cv_base          CONSTANT VARCHAR2(1)   := '1';  --���_�W�v
  cv_emp           CONSTANT VARCHAR2(1)   := '2';  --�]�ƈ��W�v
  cv_parge         CONSTANT VARCHAR2(1)   := '3';  --���[���z�M�e�[�u���p�[�W
  --�����ݒ�
  cv_date_mm       CONSTANT VARCHAR2(2)   := 'MM';
  cv_month         CONSTANT VARCHAR2(6)   := 'YYYYMM';
  cv_num_achieve   CONSTANT VARCHAR2(5)   := '990.0';
  --�N�����E�N�����Ԏ擾
  cd_sysdate       CONSTANT DATE          := SYSDATE;
  --���[�����e�̕ҏW�p�^�[��
  cv_area          CONSTANT VARCHAR2(1)   := '3';  --�n��W�v
  --�Q�ƃ^�C�v
  cv_send_mail     CONSTANT VARCHAR2(29)  := 'XXCOS1_SALES_TARGET_SEND_MAIL';
  cv_item_g_sum    CONSTANT VARCHAR2(25)  := 'XXCMM1_ITEM_GROUP_SUMMARY';
  --�v���t�@�C��
  ct_prof_bus_cal_code
    CONSTANT  fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_BUSINESS_CALENDAR_CODE'; -- XXCOS:�J�����_�R�[�h
  ct_prof_keep_day
    CONSTANT  fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_SEND_MAIL_KEEPING_DAY';  -- XXCOS:���M���[���ێ���
  ct_prof_set_of_bks_id
    CONSTANT  fnd_profile_options.profile_option_name%TYPE := 'GL_SET_OF_BKS_ID';              -- GL��v����ID
  --���b�Z�[�W
  cv_msg_param     CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-14651';  --�p�����[�^�o��
  cv_msg_lock_err  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00001';  --���b�N�G���[
  cv_msg_no_data   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00003';  --�Ώۃf�[�^�����G���[
  cv_msg_profile   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00004';  --�v���t�@�C���擾
  cv_msg_ins_err   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00010';  --�f�[�^�o�^�G���[
  cv_msg_upd_err   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00011';  --�f�[�^�X�V�G���[
  cv_msg_del_err   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00012';  --�f�[�^�폜�G���[
  cv_msg_sel_err   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00013';  --�f�[�^���o�G���[
  cv_msg_cal       CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-14652';  --���b�Z�[�W�F�J�����_�e�[�u��
  cv_msg_mail_wf   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-14653';  --���b�Z�[�W�F���[���z�M�e�[�u��
  cv_msg_mail_trn  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-14654';  --���b�Z�[�W�F���[���z�M�󋵃g�����e�[�u��
  cv_msg_mail_tmp  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-14665';  --���b�Z�[�W�F����ڕW�󋵃��[���z�M�ꎞ�\�e�[�u��
  cv_msg_rs_info   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-14666';  --���b�Z�[�W�F�c�ƈ��������e�[�u��
  --���b�Z�[�W(���[���p�Œ蕶��)
  cv_msg_word_1    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-14655';  --���b�Z�[�W�F�N
  cv_msg_word_2    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-14656';  --���b�Z�[�W�F��
  cv_msg_word_3    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-14657';  --���b�Z�[�W�F�n��v
  cv_msg_word_4    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-14658';  --���b�Z�[�W�F���_�v
  cv_msg_word_5    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-14659';  --���b�Z�[�W�F�c�ƈ��v
  cv_msg_word_6    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-14660';  --���b�Z�[�W�F�ڕW
  cv_msg_word_7    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-14661';  --���b�Z�[�W�F����
  cv_msg_word_8    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-14662';  --���b�Z�[�W�F�B����
  cv_msg_word_9    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-14663';  --���b�Z�[�W�F��~
  cv_msg_word_10   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-14664';  --���b�Z�[�W�F%
  --�g�[�N��
  cv_tkn_proc      CONSTANT VARCHAR2(4)   := 'PROC';
  cv_tkn_trg_time  CONSTANT VARCHAR2(11)  := 'TARGET_TIME';
  cv_tkn_prof_nm   CONSTANT VARCHAR2(7)   := 'PROFILE';
  cv_tkn_tab_name  CONSTANT VARCHAR2(10)  := 'TABLE_NAME';
  cv_tkn_tab       CONSTANT VARCHAR2(5)   := 'TABLE';
  cv_tkn_key_data  CONSTANT VARCHAR2(8)   := 'KEY_DATA';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  --���[�����M�p�Œ蕶���擾�p
  TYPE g_fixed_word_ttype IS TABLE OF VARCHAR2(20) INDEX BY BINARY_INTEGER;
  g_fixed_word_tab g_fixed_word_ttype;
  --���[�����e�ҏW�p
  TYPE g_edit_rtype IS RECORD (
     target_management_code  xxcso_wk_sales_target.target_management_code%TYPE  --�ڕW�Ǘ����ڃR�[�h
    ,target_month            xxcso_wk_sales_target.target_month%TYPE            --�Ώ۔N��
    ,total_code              fnd_lookup_values_vl.lookup_code%TYPE              --���v�s�R�[�h
    ,total_name              fnd_lookup_values_vl.description%TYPE              --���v�s����
    ,line_code               fnd_lookup_values_vl.lookup_code%TYPE              --���׍s�R�[�h
    ,line_name               fnd_lookup_values_vl.description%TYPE              --���׍s����
    ,target_amount           xxcso_wk_sales_target.target_amount%TYPE           --�ڕW���z
    ,sale_amount_month_sum   xxcso_wk_sales_target.sale_amount_month_sum%TYPE   --������z
    ,mail_to_1               fnd_lookup_values_vl.attribute5%TYPE               --����1
    ,mail_to_2               fnd_lookup_values_vl.attribute6%TYPE               --����2
    ,mail_to_3               fnd_lookup_values_vl.attribute7%TYPE               --����3
    ,mail_to_4               fnd_lookup_values_vl.attribute8%TYPE               --����4
  );
  TYPE g_edit_ttype IS TABLE OF g_edit_rtype INDEX BY BINARY_INTEGER;
  gt_edit_tab  g_edit_ttype;
  --�A���[�g���[�����M�e�[�u���쐬�p
  TYPE g_wf_mail_ttype IS TABLE OF xxccp_wf_mail%ROWTYPE INDEX BY BINARY_INTEGER;
  gt_wf_mail_tab  g_wf_mail_ttype;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_proc_date        DATE;           --�N����(���ԂȂ�)
  gv_proc_time        VARCHAR2(5);    --�N������(�z�M�Ώێ擾�p)
  gv_trn_create_flag  VARCHAR2(1);    --���[���z�M�󋵃g�����쐬���f�t���O
  gd_data_target_day  DATE;           --�f�[�^�擾��(1�c�Ɠ��̏ꍇ�O���A����ȊO�͓���)
  gn_set_of_books_id  NUMBER;         --��v����ID
  gn_ins_wf_cnt       BINARY_INTEGER; --�A���[�g���[�����M�e�[�u���p�z��
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_process    IN  VARCHAR2,     -- 1.�����敪 ( 1�F�]�ƈ��W�v 2�F����W�v 3:�p�[�W����)
    iv_trg_time   IN  VARCHAR2,     -- 2.�z�M�^�C�~���O ( HH24:MI �`�� )
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_para_msg       VARCHAR2(100);                                       --�p�����[�^�o�͗p
    lt_last_proc_date xxcos_mail_send_status_trn.target_date%TYPE;         --�ŏI���s���擾�p
    lt_bus_cla_code   fnd_profile_option_values.profile_option_value%TYPE; --�J�����_�R�[�h
    lt_first_day_seq  bom_calendar_dates.seq_num%TYPE;                     --1�c�Ɠ��̃V�[�P���X
    lt_day_seq        bom_calendar_dates.seq_num%TYPE;                     --�����̃V�[�P���X
    lv_msg_token      VARCHAR2(100);                                       --���b�Z�[�W�p
    lt_msg_word_code  fnd_new_messages.message_name%TYPE;                  --���[�������p�̃��b�Z�[�W�R�[�h�i�[�p
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
    -------------------
    --�p�����[�^�o��
    -------------------
    lv_para_msg := xxccp_common_pkg.get_msg(
      iv_application   =>  cv_app_xxcos,
      iv_name          =>  cv_msg_param,
      iv_token_name1   =>  cv_tkn_proc,
      iv_token_value1  =>  iv_process,
      iv_token_name2   =>  cv_tkn_trg_time,
      iv_token_value2  =>  iv_trg_time
      );
    --�o��
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.OUTPUT
      ,buff   =>  lv_para_msg
    );
    --���O
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_para_msg
    );
--
    --��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --�N�����E���Ԏ擾(�z�M�Ώێ擾�p)
    gd_proc_date  := xxccp_common_pkg2.get_process_date;
    gv_proc_time  := iv_trg_time;
--
    --�����敪���p�[�W�����̏ꍇ�A�ȍ~�̏����͍s��Ȃ�
    IF ( iv_process = cv_parge ) THEN
      RETURN;
    END IF;
--
    --�ϐ�������
    gv_trn_create_flag := cv_no;  --���[���z�M�󋵃g�����쐬���f�t���O
    gd_data_target_day := NULL;   --�擾�f�[�^��
    gn_ins_wf_cnt      := 0;      --�A���[�g���[�����M�e�[�u���z��p

    -------------------
    --�v���t�@�C���擾
    -------------------
    --�J�����_�R�[�h
    lt_bus_cla_code   := FND_PROFILE.VALUE( ct_prof_bus_cal_code );
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( lt_bus_cla_code IS NULL ) THEN
      --���b�Z�[�W����
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_xxcos          -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_profile        -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_prof_nm        -- �g�[�N���R�[�h1
                    ,iv_token_value1 => ct_prof_bus_cal_code  -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --��v����ID
    gn_set_of_books_id := TO_NUMBER( FND_PROFILE.VALUE( ct_prof_set_of_bks_id ) );
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( gn_set_of_books_id IS NULL ) THEN
      --���b�Z�[�W����
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_xxcos           -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_profile         -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_prof_nm         -- �g�[�N���R�[�h1
                    ,iv_token_value1 => ct_prof_set_of_bks_id  -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    ---------------------
    -- �g�����쐬���f
    ---------------------
    --���[���z�M�󋵃g��������w��̏����敪�ōŌ�Ɏ��s���������擾(����N���͑O����ݒ�)
    SELECT NVL( MAX( xmsst.target_date ), gd_proc_date -1 )
    INTO   lt_last_proc_date
    FROM   xxcos_mail_send_status_trn xmsst
    WHERE  xmsst.summary_type = iv_process
    ;
    --�ŏI�N�����O���ȑO�̏ꍇ(�����̏�����s)
    IF ( gd_proc_date > lt_last_proc_date ) THEN
      --���[���z�M�󋵃g�������쐬����B
      gv_trn_create_flag := cv_yes;
    END IF;
--
    --------------------------
    --����(1�c�Ɠ�)���f
    --------------------------
    BEGIN
      --�����̍ŏ��̃V�[�P���X���J�����_���擾
      SELECT MIN(seq_num)
      INTO   lt_first_day_seq
      FROM   bom_calendar_dates gcd
      WHERE  gcd.calendar_code = lt_bus_cla_code
      AND    gcd.calendar_date BETWEEN TRUNC( gd_proc_date, cv_date_mm )  --�N�����̌���
                               AND     LAST_DAY( gd_proc_date )           --�N�����̌���
      AND    gcd.seq_num       IS NOT NULL
      ;
      --�����̃V�[�P���X���擾(��c�Ɠ��̋N��(NULL)�͂Ȃ��Ƃ���)
      SELECT seq_num
      INTO   lt_day_seq
      FROM   bom_calendar_dates gcd
      WHERE  gcd.calendar_code = lt_bus_cla_code
      AND    gcd.calendar_date = gd_proc_date
      ;
    EXCEPTION
      WHEN OTHERS THEN
        --���b�Z�[�W����
        lv_msg_token := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_xxcos   -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_cal     -- ���b�Z�[�W�R�[�h
                     );
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_xxcos     -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_sel_err   -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_tab_name  -- �g�[�N���R�[�h1
                      ,iv_token_value1 => lv_msg_token     -- �g�[�N���l1
                      ,iv_token_name2  => cv_tkn_key_data  -- �g�[�N���R�[�h1
                      ,iv_token_value2 => SQLERRM          -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
    --���������̃V�[�P���X�Ɠ����̃V�[�P���X������(1�c�Ɠ��̏ꍇ)
    IF ( lt_first_day_seq = lt_day_seq ) THEN
      --�f�[�^�̎擾����O���ɂ���
      gd_data_target_day := LAST_DAY( ADD_MONTHS( gd_proc_date, -1 ) );
    --1�c�Ɠ��ȊO
    ELSE
      --�f�[�^�̎擾����{���ɂ���
      gd_data_target_day := gd_proc_date;
    END IF;
--
    --------------------------
    --���[���p�Œ蕶���擾
    --------------------------
    FOR i IN 1.. 10 LOOP
      --���b�Z�[�W�R�[�h�̎擾
      IF ( i = 1 ) THEN
        lt_msg_word_code := cv_msg_word_1;  --�N
      ELSIF ( i = 2 ) THEN
        lt_msg_word_code := cv_msg_word_2;  --��
      ELSIF ( i = 3 ) THEN
        lt_msg_word_code := cv_msg_word_3;  --�n��v
      ELSIF ( i = 4 ) THEN
        lt_msg_word_code := cv_msg_word_4;  --���_�v
      ELSIF ( i = 5 ) THEN
        lt_msg_word_code := cv_msg_word_5;  --�c�ƈ��v
      ELSIF ( i = 6 ) THEN
        lt_msg_word_code := cv_msg_word_6;  --�ڕW
      ELSIF ( i = 7 ) THEN
        lt_msg_word_code := cv_msg_word_7;  --����
      ELSIF ( i = 8 ) THEN
        lt_msg_word_code := cv_msg_word_8;  --�B����
      ELSIF ( i = 9 ) THEN
        lt_msg_word_code := cv_msg_word_9;  --��~
      ELSIF ( i = 10 ) THEN
        lt_msg_word_code := cv_msg_word_10; --%
      END IF;
      --���b�Z�[�W����
      lv_msg_token := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_xxcos      -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => lt_msg_word_code  -- ���b�Z�[�W�R�[�h
                   );
      --�z��Ɋi�[
      g_fixed_word_tab(i) := lv_msg_token;
--
    END LOOP;
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
   * Procedure Name   : del_send_mail_relate
   * Description      : ���[���z�M�֘A�e�[�u���폜(A-2)
   ***********************************************************************************/
  PROCEDURE del_send_mail_relate(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_send_mail_relate'; -- �v���O������
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
    cv_create_program   CONSTANT VARCHAR2(100)  := 'XXCOS002A081C';
--
    -- *** ���[�J���ϐ� ***
    ln_keep_day_cnt  NUMBER;         --���[���z�M�ێ���
    ld_keep_day      DATE;           --���[���z�M�ێ�
    lv_msg_token     VARCHAR2(100);  --���b�Z�[�W�p
--
    -- *** ���[�J���E�J�[�\�� ***
    --���[���z�M�e�[�u�����b�N�p
    CURSOR lock_wf_cur
    IS
      SELECT 1
      FROM   xxccp_wf_mail xwm
      WHERE  TRUNC( xwm.creation_date ) < ld_keep_day
      AND    xwm.program_id IN (
               SELECT concurrent_program_id
               FROM   fnd_concurrent_programs_vl fcpv
               WHERE  fcpv.concurrent_program_name = cv_create_program
             )
      FOR UPDATE NOWAIT
      ;
    --���[���z�M�󋵃g�������b�N�p
    CURSOR lock_trn_cur
    IS
      SELECT 1
      FROM   xxcos_mail_send_status_trn xmsst
      WHERE  xmsst.target_date < ld_keep_day
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    ----------------------------
    -- �c�ƈ��������e�[�u���폜
    ----------------------------
    BEGIN
      EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcos.xxcos_rs_info_day';
    EXCEPTION
      WHEN OTHERS THEN
        --���b�Z�[�W����
        lv_msg_token := xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_xxcos    -- �A�v���P�[�V�����Z�k��
                          ,iv_name         => cv_msg_rs_info  -- ���b�Z�[�W�R�[�h
                 );
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_xxcos     -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_del_err   -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tab_name  -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_msg_token     -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_key_data  -- �g�[�N���R�[�h1
                       ,iv_token_value2 => SQLERRM          -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --------------------
    --�v���t�@�C���擾
    --------------------
    --���M���[���ێ���
    ln_keep_day_cnt   := TO_NUMBER(FND_PROFILE.VALUE( ct_prof_keep_day ));
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( ln_keep_day_cnt IS NULL ) THEN
      --���b�Z�[�W����
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_xxcos     -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_profile   -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_prof_nm   -- �g�[�N���R�[�h1
                    ,iv_token_value1 => ct_prof_keep_day -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --�ێ����̐ݒ�
    ld_keep_day := gd_proc_date - ln_keep_day_cnt;
--
    --------------------------
    -- ���[�����M�e�[�u���폜
    --------------------------
    --�G���[���̃g�[�N���擾
    lv_msg_token := xxccp_common_pkg.get_msg(
                   iv_application  => cv_app_xxcos    -- �A�v���P�[�V�����Z�k��
                  ,iv_name         => cv_msg_mail_wf  -- ���b�Z�[�W�R�[�h
                 );
    --���b�N�擾
    BEGIN
      OPEN  lock_wf_cur;
      CLOSE lock_wf_cur;
    EXCEPTION
      WHEN lock_expt THEN
        --���b�Z�[�W����
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_xxcos     -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_lock_err  -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tab       -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_msg_token     -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
    --�폜
    BEGIN
      DELETE
      FROM   xxccp_wf_mail xwm
      WHERE  TRUNC( xwm.creation_date ) < ld_keep_day
      AND    xwm.program_id IN (
               SELECT concurrent_program_id
               FROM   fnd_concurrent_programs_vl fcpv
               WHERE  fcpv.concurrent_program_name = cv_create_program
             )
      ;
      gn_target_cnt := SQL%ROWCOUNT;
      gn_normal_cnt := gn_target_cnt;
    EXCEPTION
      WHEN OTHERS THEN
        --���b�Z�[�W����
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_xxcos     -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_del_err   -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tab_name  -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_msg_token     -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_key_data  -- �g�[�N���R�[�h1
                       ,iv_token_value2 => SQLERRM          -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    ----------------------------
    -- ���[���z�M�󋵃g�����폜
    ----------------------------
    --�G���[���̃g�[�N���擾
    lv_msg_token := xxccp_common_pkg.get_msg(
                   iv_application  => cv_app_xxcos    -- �A�v���P�[�V�����Z�k��
                  ,iv_name         => cv_msg_mail_trn -- ���b�Z�[�W�R�[�h
                 );
    BEGIN
      OPEN  lock_trn_cur;
      CLOSE lock_trn_cur;
    EXCEPTION
      WHEN lock_expt THEN
        --���b�Z�[�W����
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_xxcos     -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_lock_err  -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tab       -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_msg_token     -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
    --�폜
    BEGIN
      DELETE
      FROM   xxcos_mail_send_status_trn xmsst
      WHERE  xmsst.target_date < ld_keep_day
      ;
    EXCEPTION
      WHEN OTHERS THEN
        --���b�Z�[�W����
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_xxcos     -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_del_err   -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tab_name  -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_msg_token     -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_key_data  -- �g�[�N���R�[�h1
                       ,iv_token_value2 => SQLERRM          -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
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
  END del_send_mail_relate;
--
  /**********************************************************************************
   * Procedure Name   : ins_send_mail_trn
   * Description      : ���[���z�M�󋵃g�����쐬(A-3)
   ***********************************************************************************/
  PROCEDURE ins_send_mail_trn(
    iv_process    IN  VARCHAR,     -- -- 1.�����敪 ( 1�F����W�v 2�F�]�ƈ��W�v )
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_send_mail_trn'; -- �v���O������
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
    lv_msg_token     VARCHAR2(100);  --���b�Z�[�W�p
--
    -- *** ���[�J���E�J�[�\�� ***
    --���[���z�M�󋵃g�����쐬�p�J�[�\��(���_)
    CURSOR send_time_base_cur
    IS
      SELECT flvv.attribute4  --�z�M�^�C�~���O
      FROM   fnd_lookup_values_vl flvv
      WHERE  flvv.lookup_type = cv_send_mail --���M�惁�[���e�[�u���i�Q�ƃ^�C�v�j
      AND    flvv.attribute2  = cv_yes       --����W�v
      GROUP BY
             flvv.attribute4  --�z�M�^�C�~���O
      ;
    --���[���z�M�󋵃g�����쐬�p�J�[�\��(�]�ƈ�)
    CURSOR send_time_emp_cur
    IS
      SELECT flvv.attribute4  --�z�M�^�C�~���O
      FROM   fnd_lookup_values_vl flvv
      WHERE  flvv.lookup_type = cv_send_mail --���M�惁�[���e�[�u���i�Q�ƃ^�C�v�j
      AND    flvv.attribute1  = cv_yes       --�]�ƈ��W�v
      GROUP BY
             flvv.attribute4  --�z�M�^�C�~���O
      ;
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J���E�e�[�u�� ***
    TYPE g_send_time_ttype IS TABLE OF fnd_lookup_values_vl.attribute4%TYPE INDEX BY BINARY_INTEGER;
    g_send_time_tab g_send_time_ttype;
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
    ------------------------------
    --���[���z�M�󋵃g�����쐬
    ------------------------------
    --����W�v
    IF ( iv_process = cv_base ) THEN
      OPEN  send_time_base_cur;
      FETCH send_time_base_cur BULK COLLECT INTO g_send_time_tab;
      CLOSE send_time_base_cur;
    --�]�ƈ��W�v
    ELSIF ( iv_process = cv_emp ) THEN
      OPEN  send_time_emp_cur;
      FETCH send_time_emp_cur BULK COLLECT INTO g_send_time_tab;
      CLOSE send_time_emp_cur;
    END IF;
--
    BEGIN
      --�쐬
      FORALL i IN 1..g_send_time_tab.COUNT
        INSERT INTO xxcos_mail_send_status_trn(
           mail_trn_id           --���[���g����ID
          ,send_time             --�z�M�^�C�~���O
          ,summary_type          --�W�v�敪
          ,send_flag             --���M�t���O
          ,target_date           --�Ώۓ�
          ,created_by
          ,creation_date
          ,last_updated_by
          ,last_update_date
          ,last_update_login
          ,request_id
          ,program_application_id
          ,program_id
          ,program_update_date
        )
        VALUES
        (
          xxcos_mail_send_status_trn_s01.NEXTVAL --���[���g����ID
         ,g_send_time_tab(i)                     --�z�M�^�C�~���O
         ,iv_process                             --�W�v�敪
         ,cv_no                                  --���M�t���O
         ,gd_proc_date                           --�Ώۓ�
         ,cn_created_by
         ,cd_creation_date
         ,cn_last_updated_by
         ,cd_last_update_date
         ,cn_last_update_login
         ,cn_request_id
         ,cn_program_application_id
         ,cn_program_id
         ,cd_program_update_date
        )
        ;
      --�z��폜
      g_send_time_tab.DELETE;
--
    EXCEPTION
      WHEN OTHERS THEN
        --���b�Z�[�W����
        lv_msg_token := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_xxcos     -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_mail_trn  -- ���b�Z�[�W�R�[�h
                     );
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_xxcos     -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_ins_err   -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_tab_name  -- �g�[�N���R�[�h1
                      ,iv_token_value1 => lv_msg_token     -- �g�[�N���l1
                      ,iv_token_name2  => cv_tkn_key_data  -- �g�[�N���R�[�h1
                      ,iv_token_value2 => SQLERRM          -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -----------------------------
    -- �c�ƈ��������e�[�u���쐬
    -----------------------------
    IF ( iv_process = cv_emp ) THEN
      BEGIN
        INSERT INTO xxcos_rs_info_day(
           rs_info_id                --�c�ƈ����ID
          ,base_code                 --���_�R�[�h
          ,employee_number           --�c�ƈ��R�[�h
          ,employee_name             --�c�ƈ�����
          ,group_code                --�O���[�v�ԍ�
          ,group_in_sequence         --�O���[�v���ԍ�
          ,effective_start_date      --���_�K�p�J�n��
          ,effective_end_date        --���_�K�p�I����
          ,per_effective_start_date  --�]�ƈ��K�p�J�n��
          ,per_effective_end_date    --�]�ƈ��K�p�I����
          ,paa_effective_start_date  --�A�T�C�������g�K�p�J�n��
          ,paa_effective_end_date    --�A�T�C�������g�K�p�I����
          ,created_by                --�쐬��
          ,creation_date             --�쐬��
          ,last_updated_by           --�ŏI�X�V��
          ,last_update_date          --�ŏI�X�V��
          ,last_update_login         --�ŏI�X�V���O�C��
          ,request_id                --�v��ID
          ,program_application_id    --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          ,program_id                --�R���J�����g�E�v���O����ID
          ,program_update_date       --�v���O�����X�V��
        )
        SELECT
           xxcos_rs_info_day_s01.NEXTVAL
          ,base_code
          ,employee_number
          ,employee_name
          ,group_code
          ,group_in_sequence
          ,effective_start_date
          ,effective_end_date
          ,per_effective_start_date
          ,per_effective_end_date
          ,paa_effective_start_date
          ,paa_effective_end_date
          ,cn_created_by
          ,cd_creation_date
          ,cn_last_updated_by
          ,cd_last_update_date
          ,cn_last_update_login
          ,cn_request_id
          ,cn_program_application_id
          ,cn_program_id
          ,cd_program_update_date
        FROM  xxcos_rs_info2_v xriv
        ;
      EXCEPTION
        WHEN OTHERS THEN
          --���b�Z�[�W����
          lv_msg_token := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_xxcos     -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_msg_rs_info   -- ���b�Z�[�W�R�[�h
                       );
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_xxcos     -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_msg_ins_err   -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_tab_name  -- �g�[�N���R�[�h1
                        ,iv_token_value1 => lv_msg_token     -- �g�[�N���l1
                        ,iv_token_name2  => cv_tkn_key_data  -- �g�[�N���R�[�h1
                        ,iv_token_value2 => SQLERRM          -- �g�[�N���l1
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
    END IF;
--
    --���[���z�M�󋵃g�����f�[�^�̓������A�y�сA�c�ƈ������m�肷��ׁACOMMIT
    COMMIT;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
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
  END ins_send_mail_trn;
--
  /**********************************************************************************
   * Procedure Name   : ins_target_date
   * Description      : ���[���z�M�Ώۈꎞ�e�[�u���쐬(A-4)
   ***********************************************************************************/
  PROCEDURE ins_target_date(
    iv_process    IN  VARCHAR2,     -- 1.�����敪 ( 1�F����W�v 2�F�]�ƈ��W�v )
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_target_date'; -- �v���O������
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
    --�K�w�擾�p
    ct_application_id          fnd_id_flex_segments.application_id%TYPE          := 101;
    ct_id_flex_code            fnd_id_flex_segments.id_flex_code%TYPE            := 'GL#';
    ct_application_column_name fnd_id_flex_segments.application_column_name%TYPE := 'SEGMENT2';
--
    -- *** ���[�J���ϐ� ***
    lt_area_base_code          fnd_lookup_values_vl.lookup_type%TYPE; --�n��R�[�h
    lv_msg_token               VARCHAR2(100);                         --���b�Z�[�W�p
--
    -- *** ���[�J���E�J�[�\�� ***
    --�n��R�[�h�w��̃f�[�^�擾�J�[�\��
    CURSOR area_base_cur
    IS
      SELECT    flvv.lookup_code  area_base_code
               ,flvv.description  area_base_name
               ,''                base_code
               ,''                base_name
               ,flvv.attribute5   mail_to_1
               ,flvv.attribute6   mail_to_2
               ,flvv.attribute7   mail_to_3
               ,flvv.attribute8   mail_to_4
               ,''                base_sort_code
      FROM      xxcos_mail_send_status_trn xmsst --���[���z�M�󋵃g����
               ,fnd_lookup_values_vl       flvv  --����ڕW���M��}�X�^
      WHERE     xmsst.target_date       = gd_proc_date          --�N����
      AND       xmsst.summary_type      = iv_process            --���_�W�v
      AND       xmsst.send_flag         = cv_no                 --������
      AND       xmsst.send_time        <= gv_proc_time          --�z�M�^�C�~���O���N�����Ԃ��O
      AND       xmsst.send_time         = flvv.attribute4
      AND       flvv.lookup_type        = cv_send_mail          --XXCOS1_SALES_TARGET_SEND_MAIL
      AND       flvv.enabled_flag       = cv_yes                --�L��
      AND       gd_data_target_day      BETWEEN flvv.start_date_active
                                        AND     NVL( flvv.end_date_active, gd_data_target_day ) --�Ώۊ��ԓ�
      AND       flvv.attribute2         = cv_yes                --���_�W�v
      AND       flvv.attribute3         = cv_yes                --�n��敪"Y"(�����̊K�w)
      ;
    --�n��R�[�h�z���̋��_�擾�J�[�\��
    CURSOR under_area_base_cur
    IS
      SELECT xhdv.child_base_code  child_base_code  --���_�R�[�h(�n��z��)
            ,ffv.attribute4        child_base_name  --���_��(������)
            ,ffv.attribute9        base_sort_code   --�{���R�[�h(�V) ���\�[�g�p
      FROM   (SELECT  level                       lev
                     ,xablv.base_code             area_base_code
                     ,xablv.child_base_code       child_base_code
                     ,xablv.flex_value_set_id     flex_value_set_id
              FROM    (
                       SELECT  ffvnh.parent_flex_value      base_code
                              ,ffvnh.child_flex_value_low   child_base_code
                              ,ffvnh.flex_value_set_id      flex_value_set_id
                        FROM
                               gl_sets_of_books              gsob
                              ,fnd_id_flex_segments          fifs
                              ,fnd_flex_value_norm_hierarchy ffvnh
                        WHERE  gsob.set_of_books_id         = gn_set_of_books_id
                        AND    fifs.application_id          = ct_application_id
                        AND    fifs.id_flex_code            = ct_id_flex_code
                        AND    fifs.application_column_name = ct_application_column_name
                        AND    fifs.id_flex_num             = gsob.chart_of_accounts_id
                        AND    ffvnh.flex_value_set_id      = fifs.flex_value_set_id
                        AND    EXISTS (
                                 SELECT  1
                                 FROM    APPS.fnd_flex_values ffv
                                 WHERE   ffv.flex_value_set_id = ffvnh.flex_value_set_id
                                 AND     ffv.flex_value        = ffvnh.parent_flex_value
                                 AND     NVL(ffv.start_date_active, gd_data_target_day) <= gd_data_target_day
                                 AND     NVL(ffv.end_date_active,   gd_data_target_day) >= gd_data_target_day
                               )
                        AND    EXISTS (
                                 SELECT  1
                                 FROM    APPS.fnd_flex_values ffv
                                 WHERE   ffv.flex_value_set_id = ffvnh.flex_value_set_id
                                 AND     ffv.flex_value        = ffvnh.child_flex_value_low
                                 AND     NVL(ffv.start_date_active, gd_data_target_day)  <= gd_data_target_day
                                 AND     NVL(ffv.end_date_active,   gd_data_target_day)  >= gd_data_target_day
                               )
                           
                      ) xablv
              START WITH
                      xablv.base_code = lt_area_base_code
              CONNECT BY NOCYCLE PRIOR
                      xablv.base_code = xablv.child_base_code
              )                         xhdv   --�K�w�C�����C���r���[
             ,fnd_flex_values           ffv    --�t���b�N�X�l
      WHERE   xhdv.lev                = 1      --�w�肳�ꂽ����̒����̊K�w
      AND     xhdv.flex_value_set_id  = ffv.flex_value_set_id
      AND     xhdv.child_base_code    = ffv. flex_value
      ;
--
    -- *** ���[�J���E���R�[�h ***
    area_base_rec        area_base_cur%ROWTYPE;
    under_area_base_rec  under_area_base_cur%ROWTYPE;
--
    -- *** ��O ***
    ins_error_expt EXCEPTION;
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
    --�����敪�����_�W�v�̏ꍇ
    IF ( iv_process = cv_base ) THEN
--
      BEGIN
        ---------------------------
        --�ꎞ�\�ɑ}��(�����_�̂�)
        ---------------------------
        INSERT INTO xxcos_tmp_mail_send (
           area_base_code  --�n��R�[�h
          ,area_base_name  --�n�於��
          ,base_code       --���_�R�[�h
          ,base_name       --���_��
          ,mail_to_1       --����P
          ,mail_to_2       --����Q
          ,mail_to_3       --����R
          ,mail_to_4       --����S
          ,base_sort_code  --�{���R�[�h(�V)
        )
          SELECT  flvv.lookup_code  area_base_code
                 ,flvv.description  area_base_name
                 ,flvv.lookup_code  base_code
                 ,flvv.description  base_name
                 ,flvv.attribute5   mail_to_1
                 ,flvv.attribute6   mail_to_2
                 ,flvv.attribute7   mail_to_3
                 ,flvv.attribute8   mail_to_4
                 ,cn_1              base_sort_code
          FROM    xxcos_mail_send_status_trn xmsst --���[���z�M�󋵃g����
                 ,fnd_lookup_values_vl       flvv  --����ڕW���M��}�X�^
          WHERE   xmsst.target_date       = gd_proc_date          --�N����
          AND     xmsst.summary_type      = iv_process            --���_�W�v
          AND     xmsst.send_flag         = cv_no                 --������
          AND     xmsst.send_time        <= gv_proc_time          --�z�M�^�C�~���O���N�����Ԃ��O
          AND     xmsst.send_time         = flvv.attribute4
          AND     flvv.lookup_type        = cv_send_mail          --XXCOS1_SALES_TARGET_SEND_MAIL
          AND     flvv.enabled_flag       = cv_yes                --�L��
          AND     gd_data_target_day      BETWEEN flvv.start_date_active
                                          AND     NVL( flvv.end_date_active, gd_data_target_day ) --�Ώۊ��ԓ�
          AND     flvv.attribute2         = cv_yes                --���_�W�v
          AND     flvv.attribute3         = cv_no                 --�n��敪"N"(�����_�̂�)
        ;
     EXCEPTION
       WHEN OTHERS THEN
         --���b�Z�[�W����
         lv_msg_token := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_xxcos     -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_mail_tmp  -- ���b�Z�[�W�R�[�h
                      );
         lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_xxcos     -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_ins_err   -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tab_name  -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_msg_token     -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_key_data  -- �g�[�N���R�[�h1
                       ,iv_token_value2 => SQLERRM          -- �g�[�N���l1
                      );
         lv_errbuf := lv_errmsg;
         RAISE ins_error_expt;
     END;
--
      --�ꎞ�\�ɑ}��(�����̋��_��)
     OPEN  area_base_cur;
     <<area_base_loop>>
     LOOP
       FETCH area_base_cur INTO area_base_rec;
       EXIT WHEN area_base_cur%NOTFOUND;
       --�����ƂȂ�e����R�[�h�ݒ�
       lt_area_base_code := area_base_rec.area_base_code;
       --AFF���傩��z���̋��_���擾
       OPEN  under_area_base_cur;
       <<under_area_loop>>
       LOOP
         FETCH under_area_base_cur INTO under_area_base_rec;
         EXIT WHEN under_area_base_cur%NOTFOUND;
         BEGIN
           ---------------------------
           --�ꎞ�\�ɑ}��(�n��z�����_)
           ---------------------------
           INSERT INTO xxcos_tmp_mail_send (
              area_base_code  --�n��R�[�h
             ,area_base_name  --�n�於��
             ,base_code       --���_�R�[�h
             ,base_name       --���_��
             ,mail_to_1       --����P
             ,mail_to_2       --����Q
             ,mail_to_3       --����R
             ,mail_to_4       --����S
             ,base_sort_code  --�{���R�[�h(�V)
           ) VALUES (
             area_base_rec.area_base_code
            ,area_base_rec.area_base_name
            ,under_area_base_rec.child_base_code
            ,under_area_base_rec.child_base_name
            ,area_base_rec.mail_to_1
            ,area_base_rec.mail_to_2
            ,area_base_rec.mail_to_3
            ,area_base_rec.mail_to_4
            ,under_area_base_rec.base_sort_code
           )
           ;
         EXCEPTION
           WHEN OTHERS THEN
             --���b�Z�[�W����
             lv_msg_token := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_xxcos     -- �A�v���P�[�V�����Z�k��
                           ,iv_name         => cv_msg_mail_tmp  -- ���b�Z�[�W�R�[�h
                          );
             lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_xxcos     -- �A�v���P�[�V�����Z�k��
                           ,iv_name         => cv_msg_ins_err   -- ���b�Z�[�W�R�[�h
                           ,iv_token_name1  => cv_tkn_tab_name  -- �g�[�N���R�[�h1
                           ,iv_token_value1 => lv_msg_token     -- �g�[�N���l1
                           ,iv_token_name2  => cv_tkn_key_data  -- �g�[�N���R�[�h1
                           ,iv_token_value2 => SQLERRM          -- �g�[�N���l1
                          );
             lv_errbuf := lv_errmsg;
             RAISE ins_error_expt;
         END;
       END LOOP under_area_base_cur;
       CLOSE under_area_base_cur;
--
     END LOOP area_base_loop;
     CLOSE area_base_cur;
--
    --�����敪���]�ƈ��W�v�̏ꍇ
    ELSIF ( iv_process = cv_emp ) THEN
--
      BEGIN
        ---------------------------
        --�ꎞ�\�ɑ}��(�]�ƈ��W�v)
        ---------------------------
        INSERT INTO xxcos_tmp_mail_send (
           area_base_code  --�n��R�[�h
          ,area_base_name  --�n�於��
          ,base_code       --���_�R�[�h
          ,base_name       --���_��
          ,mail_to_1       --����P
          ,mail_to_2       --����Q
          ,mail_to_3       --����R
          ,mail_to_4       --����S
          ,base_sort_code  --�{���R�[�h(�V)
        )
          SELECT  ''                area_base_code
                 ,''                area_base_name
                 ,flvv.lookup_code  base_code
                 ,flvv.description  base_name
                 ,flvv.attribute5   mail_to_1
                 ,flvv.attribute6   mail_to_2
                 ,flvv.attribute7   mail_to_3
                 ,flvv.attribute8   mail_to_4
                 ,''                base_sort_code
          FROM    xxcos_mail_send_status_trn xmsst --���[���z�M�󋵃g����
                 ,fnd_lookup_values_vl       flvv  --����ڕW���M��}�X�^
          WHERE   xmsst.target_date       = gd_proc_date          --�N����
          AND     xmsst.summary_type      = iv_process            --�]�ƈ��W�v
          AND     xmsst.send_flag         = cv_no                 --������
          AND     xmsst.send_time        <= gv_proc_time          --�z�M�^�C�~���O���N�����Ԃ��O
          AND     xmsst.send_time         = flvv.attribute4
          AND     flvv.lookup_type        = cv_send_mail          --XXCOS1_SALES_TARGET_SEND_MAIL
          AND     flvv.enabled_flag       = cv_yes                --�L��
          AND     gd_data_target_day      BETWEEN flvv.start_date_active
                                          AND     NVL( flvv.end_date_active, gd_data_target_day ) --�Ώۊ��ԓ�
          AND     flvv.attribute1         = cv_yes                --�]�ƈ��W�v
        ;
      EXCEPTION
        WHEN OTHERS THEN
          --���b�Z�[�W����
          lv_msg_token := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_xxcos     -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_msg_mail_tmp  -- ���b�Z�[�W�R�[�h
                       );
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_xxcos     -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_msg_ins_err   -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_tab_name  -- �g�[�N���R�[�h1
                        ,iv_token_value1 => lv_msg_token     -- �g�[�N���l1
                        ,iv_token_name2  => cv_tkn_key_data  -- �g�[�N���R�[�h1
                        ,iv_token_value2 => SQLERRM          -- �g�[�N���l1
                       );
          lv_errbuf := lv_errmsg;
          RAISE ins_error_expt;
      END;
--
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
    WHEN ins_error_expt THEN
      --�J�[�\���N���[�Y
      IF ( area_base_cur%ISOPEN ) THEN
        CLOSE area_base_cur;
      END IF;
      IF ( under_area_base_cur%ISOPEN ) THEN
        CLOSE under_area_base_cur;
      END IF;
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
  END ins_target_date;
--
--
  /**********************************************************************************
   * Procedure Name   : edit_mail_text
   * Description      : ���[���{���ҏW(A-5)
   ***********************************************************************************/
  PROCEDURE edit_mail_text(
    it_edit_tab               IN  g_edit_ttype, -- 1.���[�����e�ҏW�p�e�[�u���^
    in_target_amount          IN  NUMBER,       -- 2.�ڕW���z(�v)
    in_sale_amount_month_sum  IN  NUMBER,       -- 3.���ы��z(�v)
    iv_pattern                IN  VARCHAR2,     -- 4.�ҏW�p�^�[��( 1:�n�� 2:���_ 3:�]�ƈ� )
    ov_errbuf                 OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                 OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'edit_mail_text'; -- �v���O������
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
    cv_canma           CONSTANT VARCHAR2(1) := ',';  --����ҏW�p
    cv_t               CONSTANT VARCHAR2(1) := 'T';  --���o���擾�p
    cv_part            CONSTANT VARCHAR2(1) := ':';  --��؂�
    cv_parentheses_l   CONSTANT VARCHAR2(1) := '(';  --����(��)
    cv_parentheses_r   CONSTANT VARCHAR2(1) := ')';  --����(�E)
    cn_no_target_amt   CONSTANT NUMBER      := 0;    --�ڕW��0�̏ꍇ�̒B����
--
    -- *** ���[�J���ϐ� ***
    lt_target_name     fnd_lookup_values_vl.description%TYPE;  --����ڕW����
    lv_text            VARCHAR2(20000);                        --���[���{���ҏW�p
    lv_pattern         VARCHAR2(1);                            --���[���ҏW�p�^�[��
    ln_target_amount   NUMBER := 0;                            --�ڕW���z�v�Z�p
    ln_sales_amount    NUMBER := 0;                            --���ы��z�v�Z�p
    ln_achievement_cal NUMBER := 0;                            --�B�����v�Z�p
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    <<edit_loop>>
    FOR i IN 1.. it_edit_tab.COUNT LOOP
--
      --�ŏ���1�s
      IF ( i = 1) THEN
--
        --�z��p�Y�����J�E���g�A�b�v
        gn_ins_wf_cnt := gn_ins_wf_cnt + 1;
--
        --���[���ҏW�p�^�[������(���_�͎����_�ƒn��ɕ�������)
        IF ( iv_pattern = cv_base ) THEN
--
          --�n��R�[�h�Ƌ��_�R�[�h���قȂ�ꍇ�͒n��
          IF ( it_edit_tab(i).total_code <> it_edit_tab(i).line_code ) THEN
            lv_pattern := cv_area;       --�n��
          --�����ꍇ�͎����_
          ELSE
            lv_pattern := cv_base;       --���_
          END IF;
--
        ELSE
          lv_pattern   := cv_emp;        --�]�ƈ�
        END IF;
--
        ------------
        --�V�[�P���X
        ------------
        SELECT xxccp_wf_mail_s01.NEXTVAL
        INTO   gt_wf_mail_tab(gn_ins_wf_cnt).wf_mail_id
        FROM   DUAL
        ;
--
        ------------
        --����ҏW
        ------------
        gt_wf_mail_tab(gn_ins_wf_cnt).mail_to := it_edit_tab(i).mail_to_1;
        --����2
        IF ( it_edit_tab(i).mail_to_2 IS NOT NULL ) THEN
          gt_wf_mail_tab(gn_ins_wf_cnt).mail_to := gt_wf_mail_tab(gn_ins_wf_cnt).mail_to || cv_canma || it_edit_tab(i).mail_to_2;
        END IF;
        --����3
        IF ( it_edit_tab(i).mail_to_3 IS NOT NULL ) THEN
          gt_wf_mail_tab(gn_ins_wf_cnt).mail_to := gt_wf_mail_tab(gn_ins_wf_cnt).mail_to || cv_canma || it_edit_tab(i).mail_to_3;
        END IF;
        --����4
        IF ( it_edit_tab(i).mail_to_4 IS NOT NULL ) THEN
          gt_wf_mail_tab(gn_ins_wf_cnt).mail_to := gt_wf_mail_tab(gn_ins_wf_cnt).mail_to || cv_canma || it_edit_tab(i).mail_to_4;
        END IF;
--
        -----------------
        --���[��CC
        -----------------
        gt_wf_mail_tab(gn_ins_wf_cnt).mail_cc  := NULL;
--
        -----------------
        --���[��BCC
        -----------------
        gt_wf_mail_tab(gn_ins_wf_cnt).mail_bcc := NULL;
--
        ------------------
        --���[�������ҏW
        ------------------
        BEGIN
          SELECT flvv.description description
          INTO   lt_target_name
          FROM   fnd_lookup_values_vl flvv
          WHERE  flvv.lookup_type                = cv_item_g_sum
          AND    SUBSTRB(flvv.lookup_code, 1, 3) = SUBSTRB( it_edit_tab(i).target_management_code, 1, 3 )  --�ŏ�3�����Ώۂ̃R�[�h
          AND    flvv.attribute3                 = cv_t                                                    --���o��
          ;
        EXCEPTION
          WHEN OTHERS THEN
            lt_target_name := NULL;
        END;
        gt_wf_mail_tab(gn_ins_wf_cnt).mail_subject := SUBSTRB( it_edit_tab(i).target_month, 3, 2) || g_fixed_word_tab(1)   || --�N
                                                      SUBSTRB( it_edit_tab(i).target_month, 5, 2) || g_fixed_word_tab(2)   || --��
                                                      cv_part                                                              || --��؂�
                                                      lt_target_name                                                       || --����ڕW����
                                                      cv_parentheses_l || it_edit_tab(i).total_name || cv_parentheses_r;      --�n��(���_)����
--
        ----------------
        --WHO�J����
        ----------------
        gt_wf_mail_tab(gn_ins_wf_cnt).created_by              :=  cn_created_by;
        gt_wf_mail_tab(gn_ins_wf_cnt).creation_date           :=  cd_creation_date;
        gt_wf_mail_tab(gn_ins_wf_cnt).last_updated_by         :=  cn_last_updated_by;
        gt_wf_mail_tab(gn_ins_wf_cnt).last_update_date        :=  cd_last_update_date;
        gt_wf_mail_tab(gn_ins_wf_cnt).last_update_login       :=  cn_last_update_login;
        gt_wf_mail_tab(gn_ins_wf_cnt).request_id              :=  cn_request_id;
        gt_wf_mail_tab(gn_ins_wf_cnt).program_application_id  :=  cn_program_application_id;
        gt_wf_mail_tab(gn_ins_wf_cnt).program_id              :=  cn_program_id;
        gt_wf_mail_tab(gn_ins_wf_cnt).program_update_date     :=  cd_program_update_date;
--
        ----------------
        -- ���v�s�̕ҏW
        ----------------
        --�ڕW���z�̌v�Z(��~�P�ʎl�̌ܓ�)
        ln_target_amount := ROUND( in_target_amount / 1000 );
        --���ы��z�̌v�Z(��~�P�ʎl�̌ܓ�)
        ln_sales_amount  := ROUND( in_sale_amount_month_sum / 1000 );
--
        --�B�����̌v�Z(������P�ʈȉ��؎̂�) ���ڕW�E���т͎l�̌ܓ���̒l�Ōv�Z
        IF ( in_target_amount <> 0 ) THEN
          ln_achievement_cal := TRUNC( ( ln_sales_amount / ln_target_amount ) * 100, 1 );
        ELSE
          ln_achievement_cal := cn_no_target_amt; --�ڕW��0�̏ꍇ�G���[�ƂȂ��
        END IF;
--
        --���o��(�n��)
        IF ( lv_pattern = cv_area ) THEN
          lv_text := g_fixed_word_tab(3) || CHR(10);  --�n��v(�Œ�l)
        --���o��(���_)
        ELSIF ( lv_pattern = cv_base ) THEN
          lv_text := g_fixed_word_tab(4) || CHR(10);  --���_�v(�Œ�l)
        --���o��(�]�ƈ�)
        ELSIF ( lv_pattern = cv_emp  ) THEN
          lv_text := g_fixed_word_tab(4) || CHR(10);  --���_�v(�Œ�l)
        END IF;
--
        --�ڕW�E���сE�B�����̕ҏW
        lv_text := lv_text || '  ' || it_edit_tab(i).total_code || ' ' || it_edit_tab(i).total_name          --�n��R�[�h�E�n�於��
                           || CHR(10);
        lv_text := lv_text || '    ' || g_fixed_word_tab(6) || ' ' || LPAD( TO_CHAR( ln_target_amount ),9 ,' ' )   || g_fixed_word_tab(9)  --�ڕW���z
                           || CHR(10);
        lv_text := lv_text || '    ' || g_fixed_word_tab(7) || ' ' || LPAD( TO_CHAR( ln_sales_amount ),9 ,' ' )    || g_fixed_word_tab(9)  --���ы��z
                           || CHR(10);
        lv_text := lv_text || '    ' || g_fixed_word_tab(8) || ' ' || LPAD( TO_CHAR( ln_achievement_cal, cv_num_achieve ),7 ,' ' ) || g_fixed_word_tab(10) --�B����
                           || CHR(10);
        lv_text := lv_text || CHR(10); --�󔒍s
--
        --���ׂ̌��o��(�n��)
        IF ( lv_pattern = cv_area ) THEN
          lv_text := lv_text || g_fixed_word_tab(4) || CHR(10);  --���_�v(�Œ�l)
        --���ׂ̌��o��(�]�ƈ�)
        ELSIF ( lv_pattern = cv_emp ) THEN
          lv_text := lv_text || g_fixed_word_tab(5) || CHR(10);  --�c�ƈ��v(�Œ�l)
        END IF;
--
      END IF;
--
      --���_�v��1�s�̂�(���v�s�݂̂Ȃ̂ŏ����C��)
      IF ( lv_pattern = cv_base ) THEN
        EXIT;
      END IF;
--
      --------------------------------------------------
      --���׍s�ҏW(�n��E�]�ƈ��̏ꍇ)
      --------------------------------------------------
      --�ϐ�������
      ln_target_amount   := 0;
      ln_sales_amount    := 0;
      ln_achievement_cal := 0;
--
      --�ڕW���z�̌v�Z(��~�P�ʎl�̌ܓ�)
      ln_target_amount := ROUND( it_edit_tab(i).target_amount / 1000 );
      --���ы��z�̌v�Z(��~�P�ʎl�̌ܓ�)
      ln_sales_amount  := ROUND( it_edit_tab(i).sale_amount_month_sum / 1000 );
--
      --�B�����̌v�Z(������P�ʈȉ��؎̂�) ���ڕW�E���т͎l�̌ܓ���̒l�Ōv�Z
      IF ( it_edit_tab(i).target_amount <> 0 ) THEN
        ln_achievement_cal := TRUNC( ( ln_sales_amount / ln_target_amount ) * 100, 1 );
      ELSE
        ln_achievement_cal := cn_no_target_amt; --�ڕW��0�̏ꍇ�G���[�ƂȂ��
      END IF;
--
      --�ڕW�E���сE�B�����̕ҏW
      lv_text := lv_text || '  ' || it_edit_tab(i).line_code || ' ' || it_edit_tab(i).line_name             --���_�R�[�h�E���_����
                         || CHR(10);
      lv_text := lv_text || '    ' || g_fixed_word_tab(6) || ' ' || LPAD( TO_CHAR( ln_target_amount ),9 ,' ' )   || g_fixed_word_tab(9)  --�ڕW���z
                         || CHR(10);
      lv_text := lv_text || '    ' || g_fixed_word_tab(7) || ' ' || LPAD( TO_CHAR( ln_sales_amount ),9 ,' ' )    || g_fixed_word_tab(9)  --���ы��z
                         || CHR(10); 
      lv_text := lv_text || '    ' || g_fixed_word_tab(8) || ' ' || LPAD( TO_CHAR( ln_achievement_cal, cv_num_achieve ),7 ,' ' ) || g_fixed_word_tab(10) --�B����
                         || CHR(10); 
      lv_text := lv_text || CHR(10); --�󔒍s
--
    END LOOP edit_loop;
--
    gt_wf_mail_tab(gn_ins_wf_cnt).mail_text := SUBSTRB( lv_text, 1, 4000 );
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
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
  END edit_mail_text;
--
  /**********************************************************************************
   * Procedure Name   : get_send_mail_data_e
   * Description      : ���[���z�M�f�[�^�擾(�]�ƈ��v)(A-6)
   ***********************************************************************************/
  PROCEDURE get_send_mail_data_e(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_send_mail_data_e'; -- �v���O������
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
--
    -- *** ���[�J���ϐ� ***
    lt_target_management_code    xxcso_wk_sales_target.target_management_code%TYPE;  --�ڕW�Ǘ����ڃR�[�h(�u���[�N����p)
    lt_base_code                 xxcos_tmp_mail_send.base_code%TYPE;                 --���_�R�[�h(�u���[�N����p)
    lv_last_flag                 VARCHAR2(1);                                        --�ŏI�f�[�^����p
    ln_sum_target_amount         NUMBER;                                             --���_�v(�ڕW)
    ln_sum_sale_amount_month_sum NUMBER;                                             --���_�v(����)
    ln_work_cnt                  BINARY_INTEGER;                                     --�z��p
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- �]�ƈ��W�v�p�J�[�\��
    CURSOR get_emp_data_cur
    IS
      SELECT  /*+
                 LEADING(xtms xwst xrid)
                 USE_NL(xtms xwst xrid )
                 INDEX(xrid xxcos_rs_info_day_pk)
              */
              xwst.target_management_code        target_management_code  --�ڕW�Ǘ����ڃR�[�h
             ,xwst.target_month                  target_month            --�Ώ۔N��
             ,xtms.base_code                     base_code               --���_�R�[�h
             ,xtms.base_name                     base_name               --���_��
             ,xwst.employee_code                 employee_code           --�c�ƈ��R�[�h
             ,xrid.employee_name                 employee_name           --�c�ƈ���
             ,SUM( xwst.target_amount )          target_amount           --�ڕW���z
             ,SUM( xwst.sale_amount_month_sum )  sale_amount_month_sum   --���ы��z
             ,xtms.mail_to_1                     mail_to_1               --����1
             ,xtms.mail_to_2                     mail_to_2               --����2
             ,xtms.mail_to_3                     mail_to_3               --����3
             ,xtms.mail_to_4                     mail_to_4               --����4
      FROM    xxcos_tmp_mail_send    xtms  --����ڕW�󋵃��[���z�M�ꎞ�\
             ,xxcso_wk_sales_target  xwst  --����ڕW���[�N
             ,xxcos_rs_info_day      xrid  --�c�ƈ�������
      WHERE   xtms.base_code          = xwst.base_code
      AND     xwst.target_month       = TO_CHAR( gd_data_target_day, cv_month ) --�ΏۂƂ���N��(�����͑O���A����ȊO�͓���)
      AND     EXISTS (
                SELECT 1
                FROM   xxcso_sales_target_mst xstm --����ڕW�}�X�^
                WHERE  xstm.employee_code          = xwst.employee_code
                AND    xstm.target_month           = xwst.target_month
                AND    xstm.base_code              = xwst.base_code
                AND    xstm.target_management_code = xwst.target_management_code
                AND    ROWNUM                      = 1
              )                                                                 --�ڕW���R�t���s
      AND     xrid.rs_info_id         = (
                SELECT xridi.rs_info_id
                FROM   xxcos_rs_info_day xridi
                WHERE  xridi.employee_number   = xwst.employee_code
                AND    xridi.base_code         = xwst.base_code
                AND    gd_data_target_day      BETWEEN TRUNC( xridi.effective_start_date, cv_date_mm )
                                                AND     LAST_DAY( xridi.effective_end_date )
                AND    gd_data_target_day      BETWEEN TRUNC( xridi.per_effective_start_date, cv_date_mm )
                                                AND     LAST_DAY( xridi.per_effective_end_date )
                AND    gd_data_target_day      BETWEEN TRUNC( xridi.paa_effective_start_date, cv_date_mm )
                                                AND     LAST_DAY( xridi.paa_effective_end_date )
                AND    ROWNUM                  = 1
             )                                                                  --�Y���̌��ŕ������ꋒ�_�����݂���ꍇ�P���擾
      GROUP BY
               xwst.target_management_code   --�ڕW�Ǘ����ڃR�[�h
              ,xwst.target_month             --�Ώ۔N��
              ,xtms.base_code                --���_
              ,xtms.base_name                --���_��
              ,xwst.employee_code            --�c�ƈ��R�[�h
              ,xrid.employee_name            --�c�ƈ���
              ,xtms.mail_to_1                --����1
              ,xtms.mail_to_2                --����2
              ,xtms.mail_to_3                --����3
              ,xtms.mail_to_4                --����4
              ,xrid.group_code               --�O���[�v�ԍ�
              ,xrid.group_in_sequence        --�O���[�v����
      ORDER BY
               xwst.target_management_code       --�ڕW�Ǘ����ڃR�[�h
              ,xtms.base_code                    --���_
              ,TO_NUMBER(xrid.group_code)        --�O���[�v�ԍ�
              ,TO_NUMBER(xrid.group_in_sequence) --�O���[�v����
              ,xwst.employee_code                --�]�ƈ��R�[�h
      ;
    -- *** ���[�J���e�[�u�� ***
    TYPE l_emp_data_ttype IS TABLE OF get_emp_data_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    -- *** ���[�J���z�� ***
    l_emp_data_tab       l_emp_data_ttype;
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
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
--
    -- �ϐ�������
    ln_sum_target_amount          := 0;
    ln_sum_sale_amount_month_sum  := 0;
    ln_work_cnt                   := 0;
--
    -- �I�[�v��
    OPEN get_emp_data_cur;
    -- �f�[�^�擾
    FETCH get_emp_data_cur BULK COLLECT INTO l_emp_data_tab;
    -- �N���[�Y
    CLOSE get_emp_data_cur;
--
    --�����f�[�^���Ȃ��ꍇ�A�x���ŏC��
    IF ( l_emp_data_tab.COUNT = 0 ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_xxcos     -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_no_data   -- ���b�Z�[�W�R�[�h
                   );
      lv_errbuf := lv_errmsg;
      RAISE no_data_expt;
    END IF;
--
    <<emp_edit_loop>>
    FOR i IN 1.. l_emp_data_tab.COUNT LOOP
--
      --�ŏ���1���ڂ̏ꍇ�A�u���[�N�ϐ���ݒ�
      IF ( i = 1 ) THEN
        lt_target_management_code := l_emp_data_tab(i).target_management_code;
        lt_base_code              := l_emp_data_tab(i).base_code;
      END IF;
--
      --�ŏI�s�̏ꍇ�A�ŏI�f�[�^�ҏW�p�̃t���O��ON�ɂ���
      IF ( i = l_emp_data_tab.COUNT ) THEN
        lv_last_flag := cv_yes;
      END IF;
--
      --�u���[�N������ҏW���������{
      IF (
           ( lt_target_management_code <> l_emp_data_tab(i).target_management_code )
           OR
           ( lt_base_code              <> l_emp_data_tab(i).base_code )
         )
      THEN
        ---------------------------
        -- ���[���{���ҏW(A-5)
        ---------------------------
        edit_mail_text(
          it_edit_tab               => gt_edit_tab,                   -- 1.���[�����e�ҏW�p�e�[�u���^
          in_target_amount          => ln_sum_target_amount,          -- 2.�ڕW���z(���_�v)
          in_sale_amount_month_sum  => ln_sum_sale_amount_month_sum,  -- 3.���ы��z(���_�v)
          iv_pattern                => cv_emp,                        -- 4.�ҏW�p�^�[��(�]�ƈ�)
          ov_errbuf                 => lv_errbuf,                     --   �G���[�E���b�Z�[�W           --# �Œ� #
          ov_retcode                => lv_retcode,                    --   ���^�[���E�R�[�h             --# �Œ� #
          ov_errmsg                 => lv_errmsg                      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode = cv_status_error) THEN
          --(�G���[����)
          RAISE global_process_expt;
        END IF;
--
        --�z��p�ϐ�������
        gt_edit_tab.DELETE;
        ln_work_cnt                   := 1;
        --���_�v������
        ln_sum_target_amount          := l_emp_data_tab(i).target_amount;
        ln_sum_sale_amount_month_sum  := l_emp_data_tab(i).sale_amount_month_sum;
        --�u���[�N�ϐ��ݒ�
        lt_target_management_code     := l_emp_data_tab(i).target_management_code;
        lt_base_code                  := l_emp_data_tab(i).base_code;
--
      ELSE
--
        --�z��p�ϐ��J�E���g�A�b�v
        ln_work_cnt                   := ln_work_cnt + 1;
        --���_�v�p
        ln_sum_target_amount          := ln_sum_target_amount         + l_emp_data_tab(i).target_amount;
        ln_sum_sale_amount_month_sum  := ln_sum_sale_amount_month_sum + l_emp_data_tab(i).sale_amount_month_sum;
--
      END IF;
--
      --���׍s�ݒ�
      gt_edit_tab(ln_work_cnt).target_management_code  :=  l_emp_data_tab(i).target_management_code;
      gt_edit_tab(ln_work_cnt).target_month            :=  l_emp_data_tab(i).target_month;
      gt_edit_tab(ln_work_cnt).total_code              :=  l_emp_data_tab(i).base_code;
      gt_edit_tab(ln_work_cnt).total_name              :=  l_emp_data_tab(i).base_name;
      gt_edit_tab(ln_work_cnt).line_code               :=  l_emp_data_tab(i).employee_code;
      gt_edit_tab(ln_work_cnt).line_name               :=  l_emp_data_tab(i).employee_name;
      gt_edit_tab(ln_work_cnt).target_amount           :=  l_emp_data_tab(i).target_amount;
      gt_edit_tab(ln_work_cnt).sale_amount_month_sum   :=  l_emp_data_tab(i).sale_amount_month_sum;
      gt_edit_tab(ln_work_cnt).mail_to_1               :=  l_emp_data_tab(i).mail_to_1;
      gt_edit_tab(ln_work_cnt).mail_to_2               :=  l_emp_data_tab(i).mail_to_2;
      gt_edit_tab(ln_work_cnt).mail_to_3               :=  l_emp_data_tab(i).mail_to_3;
      gt_edit_tab(ln_work_cnt).mail_to_4               :=  l_emp_data_tab(i).mail_to_4;
--
      --�ŏI�s�̃��[���ҏW
      IF ( lv_last_flag = cv_yes ) THEN
        ---------------------------
        -- ���[���{���ҏW(A-5)
        ---------------------------
        edit_mail_text(
          it_edit_tab               => gt_edit_tab,                   -- 1.���[�����e�ҏW�p�e�[�u���^
          in_target_amount          => ln_sum_target_amount,          -- 2.�ڕW���z(���_�v)
          in_sale_amount_month_sum  => ln_sum_sale_amount_month_sum,  -- 3.���ы��z(���_�v)
          iv_pattern                => cv_emp,                        -- 4.�ҏW�p�^�[��(�]�ƈ�)
          ov_errbuf                 => lv_errbuf,                     --   �G���[�E���b�Z�[�W           --# �Œ� #
          ov_retcode                => lv_retcode,                    --   ���^�[���E�R�[�h             --# �Œ� #
          ov_errmsg                 => lv_errmsg                      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode = cv_status_error) THEN
          --(�G���[����)
          RAISE global_process_expt;
        END IF;
      END IF;
--
    END LOOP emp_edit_loop;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
    -- *** �Ώۃf�[�^�Ȃ���O�n���h�� ***
    WHEN no_data_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END get_send_mail_data_e;
--
  /**********************************************************************************
   * Procedure Name   : get_send_mail_data_b
   * Description      : ���[���z�M�f�[�^�擾(���_�v)(A-7)
   ***********************************************************************************/
  PROCEDURE get_send_mail_data_b(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_send_mail_data_b'; -- �v���O������
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
--
    -- *** ���[�J���ϐ� ***
    lt_target_management_code    xxcso_wk_sales_target.target_management_code%TYPE;  --�ڕW�Ǘ����ڃR�[�h(�u���[�N����p)
    lt_area_base_code            xxcos_tmp_mail_send.area_base_code%TYPE;            --�n��R�[�h(�u���[�N����p)
    lv_last_flag                 VARCHAR2(1);                                        --�ŏI�f�[�^����p
    ln_sum_target_amount         NUMBER;                                             --�n��v(�ڕW)
    ln_sum_sale_amount_month_sum NUMBER;                                             --�n��v(����)
    ln_work_cnt                  BINARY_INTEGER;                                     --�z��p
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- ���_�W�v�p�J�[�\��
    CURSOR get_base_data_cur
    IS
      SELECT  /*+
                 LEADING( xtms xwst )
                 USE_NL( xtms xwst )
              */
              xwst.target_management_code        target_management_code  --�ڕW�Ǘ����ڃR�[�h
             ,xwst.target_month                  target_month            --�Ώ۔N��
             ,xtms.area_base_code                area_base_code          --�n��R�[�h
             ,xtms.area_base_name                area_base_name          --�n�於��
             ,xtms.base_code                     base_code               --���_�R�[�h
             ,xtms.base_name                     base_name               --���_��
             ,SUM( xwst.target_amount )          target_amount           --�ڕW���z
             ,SUM( xwst.sale_amount_month_sum )  sale_amount_month_sum   --���ы��z
             ,xtms.mail_to_1                     mail_to_1               --����1
             ,xtms.mail_to_2                     mail_to_2               --����2
             ,xtms.mail_to_3                     mail_to_3               --����3
             ,xtms.mail_to_4                     mail_to_4               --����4
      FROM    xxcos_tmp_mail_send    xtms  --����ڕW�󋵃��[���z�M�ꎞ�\
             ,xxcso_wk_sales_target  xwst  --����ڕW���[�N
      WHERE   xtms.base_code          = xwst.base_code
      AND     xwst.target_month       = TO_CHAR( gd_data_target_day, cv_month ) --�ΏۂƂ���N��(�����͑O���A����ȊO�͓���)
      AND     EXISTS (
                SELECT 1
                FROM   xxcso_sales_target_mst xstm --����ڕW�}�X�^
                WHERE  xstm.target_month           = xwst.target_month
                AND    xstm.base_code              = xwst.base_code
                AND    xstm.target_management_code = xwst.target_management_code
                AND    ROWNUM                      = 1
              )                                                                 --�ڕW���R�t���s
      GROUP BY
               xwst.target_management_code   --�ڕW�Ǘ����ڃR�[�h
              ,xwst.target_month             --�Ώ۔N��
              ,xtms.area_base_code           --�n��R�[�h
              ,xtms.area_base_name           --�n�於��
              ,xtms.base_code                --���_
              ,xtms.base_name                --���_��
              ,xtms.mail_to_1                --����1
              ,xtms.mail_to_2                --����2
              ,xtms.mail_to_3                --����3
              ,xtms.mail_to_4                --����4
              ,xtms.base_sort_code           --�{���R�[�h(�V)
      ORDER BY
               xwst.target_management_code   --�ڕW�Ǘ����ڃR�[�h
              ,xtms.area_base_code           --���_
              ,xtms.base_sort_code           --�{���R�[�h(�V)
      ;
    -- *** ���[�J���e�[�u�� ***
    TYPE l_base_data_ttype IS TABLE OF get_base_data_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    -- *** ���[�J���z�� ***
    l_base_data_tab       l_base_data_ttype;
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
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
--
    -- �ϐ�������
    ln_sum_target_amount          := 0;
    ln_sum_sale_amount_month_sum  := 0;
    ln_work_cnt                   := 0;
--
    -- �I�[�v��
    OPEN get_base_data_cur;
    -- �f�[�^�擾
    FETCH get_base_data_cur BULK COLLECT INTO l_base_data_tab;
    -- �N���[�Y
    CLOSE get_base_data_cur;
--
    --�����f�[�^���Ȃ��ꍇ�A�x���ŏC��
    IF ( l_base_data_tab.COUNT = 0 ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_xxcos     -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_no_data   -- ���b�Z�[�W�R�[�h
                   );
      lv_errbuf := lv_errmsg;
      RAISE no_data_expt;
    END IF;
--
    <<emp_edit_loop>>
    FOR i IN 1.. l_base_data_tab.COUNT LOOP
--
      --�ŏ���1���ڂ̏ꍇ�A�u���[�N�ϐ���ݒ�
      IF ( i = 1 ) THEN
        lt_target_management_code  := l_base_data_tab(i).target_management_code;
        lt_area_base_code          := l_base_data_tab(i).area_base_code;
      END IF;
--
      --�ŏI�s�̏ꍇ�A�ŏI�f�[�^�ҏW�p�̃t���O��ON�ɂ���
      IF ( i = l_base_data_tab.COUNT ) THEN
        lv_last_flag := cv_yes;
      END IF;
--
      --�u���[�N������ҏW���������{
      IF (
           ( lt_target_management_code <> l_base_data_tab(i).target_management_code )
           OR
           ( lt_area_base_code         <> l_base_data_tab(i).area_base_code )
         )
      THEN
        ---------------------------
        -- ���[���{���ҏW(A-5)
        ---------------------------
        edit_mail_text(
          it_edit_tab               => gt_edit_tab,                   -- 1.���[�����e�ҏW�p�e�[�u���^
          in_target_amount          => ln_sum_target_amount,          -- 2.�ڕW���z(���_�v)
          in_sale_amount_month_sum  => ln_sum_sale_amount_month_sum,  -- 3.���ы��z(���_�v)
          iv_pattern                => cv_base,                       -- 4.�ҏW�p�^�[��(���_)
          ov_errbuf                 => lv_errbuf,                     --   �G���[�E���b�Z�[�W           --# �Œ� #
          ov_retcode                => lv_retcode,                    --   ���^�[���E�R�[�h             --# �Œ� #
          ov_errmsg                 => lv_errmsg                      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode = cv_status_error) THEN
          --(�G���[����)
          RAISE global_process_expt;
        END IF;
--
        --�z��p�ϐ�������
        gt_edit_tab.DELETE;
        ln_work_cnt                   := 1;
        --�n��v������
        ln_sum_target_amount          := l_base_data_tab(i).target_amount;
        ln_sum_sale_amount_month_sum  := l_base_data_tab(i).sale_amount_month_sum;
        --�u���[�N�ϐ��ݒ�
        lt_target_management_code     := l_base_data_tab(i).target_management_code;
        lt_area_base_code             := l_base_data_tab(i).area_base_code;
--
      ELSE
--
        --�z��p�ϐ��J�E���g�A�b�v
        ln_work_cnt                   := ln_work_cnt + 1;
        --�n��v�p
        ln_sum_target_amount          := ln_sum_target_amount         + l_base_data_tab(i).target_amount;
        ln_sum_sale_amount_month_sum  := ln_sum_sale_amount_month_sum + l_base_data_tab(i).sale_amount_month_sum;
--
      END IF;
--
      --���׍s�ݒ�
      gt_edit_tab(ln_work_cnt).target_management_code  :=  l_base_data_tab(i).target_management_code;
      gt_edit_tab(ln_work_cnt).target_month            :=  l_base_data_tab(i).target_month;
      gt_edit_tab(ln_work_cnt).total_code              :=  l_base_data_tab(i).area_base_code;
      gt_edit_tab(ln_work_cnt).total_name              :=  l_base_data_tab(i).area_base_name;
      gt_edit_tab(ln_work_cnt).line_code               :=  l_base_data_tab(i).base_code;
      gt_edit_tab(ln_work_cnt).line_name               :=  l_base_data_tab(i).base_name;
      gt_edit_tab(ln_work_cnt).target_amount           :=  l_base_data_tab(i).target_amount;
      gt_edit_tab(ln_work_cnt).sale_amount_month_sum   :=  l_base_data_tab(i).sale_amount_month_sum;
      gt_edit_tab(ln_work_cnt).mail_to_1               :=  l_base_data_tab(i).mail_to_1;
      gt_edit_tab(ln_work_cnt).mail_to_2               :=  l_base_data_tab(i).mail_to_2;
      gt_edit_tab(ln_work_cnt).mail_to_3               :=  l_base_data_tab(i).mail_to_3;
      gt_edit_tab(ln_work_cnt).mail_to_4               :=  l_base_data_tab(i).mail_to_4;
--
      --�ŏI�s�̃��[���ҏW
      IF ( lv_last_flag = cv_yes ) THEN
        ---------------------------
        -- ���[���{���ҏW(A-5)
        ---------------------------
        edit_mail_text(
          it_edit_tab               => gt_edit_tab,                   -- 1.���[�����e�ҏW�p�e�[�u���^
          in_target_amount          => ln_sum_target_amount,          -- 2.�ڕW���z(���_�v)
          in_sale_amount_month_sum  => ln_sum_sale_amount_month_sum,  -- 3.���ы��z(���_�v)
          iv_pattern                => cv_base,                       -- 4.�ҏW�p�^�[��(���_)
          ov_errbuf                 => lv_errbuf,                     --   �G���[�E���b�Z�[�W           --# �Œ� #
          ov_retcode                => lv_retcode,                    --   ���^�[���E�R�[�h             --# �Œ� #
          ov_errmsg                 => lv_errmsg                      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode = cv_status_error) THEN
          --(�G���[����)
          RAISE global_process_expt;
        END IF;
      END IF;
--
    END LOOP emp_edit_loop;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
    -- *** �Ώۃf�[�^�Ȃ���O�n���h�� ***
    WHEN no_data_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END get_send_mail_data_b;
--
  /**********************************************************************************
   * Procedure Name   : ins_wf_mail
   * Description      : �A���[�g���[�����M�e�[�u���쐬(A-8)
   ***********************************************************************************/
  PROCEDURE ins_wf_mail(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_wf_mail'; -- �v���O������
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
    lv_msg_token   VARCHAR2(100); --���b�Z�[�W�擾�p
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --�Ώی����擾
    gn_target_cnt := gt_wf_mail_tab.COUNT;
--
    BEGIN
      FORALL i IN 1..gt_wf_mail_tab.COUNT
        --�A���[�g���[�����M�e�[�u���f�[�^�}������
        INSERT INTO xxccp_wf_mail
        VALUES gt_wf_mail_tab(i)
        ;
    EXCEPTION
      WHEN OTHERS THEN
        --���b�Z�[�W����
        lv_msg_token := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_xxcos     -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_mail_wf   -- ���b�Z�[�W�R�[�h
                     );
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_xxcos     -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_ins_err   -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_tab_name  -- �g�[�N���R�[�h1
                      ,iv_token_value1 => lv_msg_token     -- �g�[�N���l1
                      ,iv_token_name2  => cv_tkn_key_data  -- �g�[�N���R�[�h1
                      ,iv_token_value2 => SQLERRM          -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END;
    --���������擾
    gn_normal_cnt := gn_target_cnt;
    
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
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
  END ins_wf_mail;
--
--
  /**********************************************************************************
   * Procedure Name   : upd_send_mail_trn
   * Description      : ���[���z�M�󋵃g�����X�V(A-9)
   ***********************************************************************************/
  PROCEDURE upd_send_mail_trn(
    iv_process   IN   VARCHAR2,     -- 1.( 1�F����W�v 2�F�]�ƈ��W�v )
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_send_mail_trn'; -- �v���O������
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
    lv_msg_token   VARCHAR2(100);  --���b�Z�[�W�g�[�N���p
--
    -- *** ���[�J���E�J�[�\�� ***
    --���[���z�M�󋵃g�������b�N�J�[�\��
    CURSOR upd_trn_cur
    IS
      SELECT 1
      FROM   xxcos_mail_send_status_trn xmsst
      WHERE  xmsst.send_time    <= gv_proc_time  --�z�M�^�C�~���O
      AND    xmsst.summary_type  = iv_process    --�W�v�敪
      AND    xmsst.target_date   = gd_proc_date  --�Ώۓ�
      AND    xmsst.send_flag     = cv_no         --���M�t���O
      FOR UPDATE NOWAIT
      ;
--
    -- *** ���[�J���E���R�[�h ***
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    --�G���[���̃g�[�N���擾
    lv_msg_token  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_xxcos     -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_mail_trn  -- ���b�Z�[�W�R�[�h
                     );
    --���b�N�擾
    BEGIN
      OPEN  upd_trn_cur;
      CLOSE upd_trn_cur;
    EXCEPTION
      WHEN lock_expt THEN
        --���b�Z�[�W����
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_xxcos     -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_lock_err  -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tab       -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_msg_token     -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
    --�X�V
    BEGIN
      UPDATE  xxcos_mail_send_status_trn xmsst
      SET     xmsst.send_flag               = cv_yes  --���M��
             ,xmsst.last_updated_by         = cn_last_updated_by
             ,xmsst.last_update_date        = cd_last_update_date
             ,xmsst.last_update_login       = cn_last_update_login
             ,xmsst.request_id              = cn_request_id
             ,xmsst.program_application_id  = cn_program_application_id
             ,xmsst.program_id              = cn_program_id
             ,xmsst.program_update_date     = cd_program_update_date
      WHERE   xmsst.send_time    <= gv_proc_time  --�z�M�^�C�~���O
      AND     xmsst.summary_type  = iv_process    --�W�v�敪
      AND     xmsst.target_date   = gd_proc_date  --�Ώۓ�
      AND     xmsst.send_flag     = cv_no         --���M�t���O
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_xxcos     -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_upd_err   -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tab_name  -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_msg_token     -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_key_data  -- �g�[�N���R�[�h1
                       ,iv_token_value2 => SQLERRM          -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
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
  END upd_send_mail_trn;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_process    IN  VARCHAR2,     -- 1.�����敪 ( 1�F����W�v 2�F�]�ƈ��W�v 3:�p�[�W����)
    iv_trg_time   IN  VARCHAR2,     -- 2.�z�M�^�C�~���O ( HH24:MI �`��)
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
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- ��������(A-1)
    -- ===============================
    init(
      iv_process  => iv_process,        -- 1.�����敪
      iv_trg_time => iv_trg_time,       -- 2.�z�M�^�C�~���O ( HH24:MI �`��)
      ov_errbuf   => lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode  => lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg   => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );        
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    --�����敪���p�[�W�̏ꍇ
    IF ( iv_process = cv_parge ) THEN
      -- ===============================
      -- ���[���z�M�֘A�e�[�u���폜(A-2)
      -- ===============================
      del_send_mail_relate(
        ov_errbuf  => lv_errbuf,   -- �G���[�E���b�Z�[�W           --# �Œ� #
        ov_retcode => lv_retcode,  -- ���^�[���E�R�[�h             --# �Œ� #
        ov_errmsg  => lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode = cv_status_error) THEN
        --(�G���[����)
        RAISE global_process_expt;
      END IF;
--
    --�����敪���p�[�W�����ȊO�̏ꍇ
    ELSE
--
      --�����敪���ƂɋN�����̏���N���̏ꍇ
      IF ( gv_trn_create_flag = cv_yes ) THEN
        -- ===================================
        -- ���[���z�M�󋵃g�����쐬(A-3)
        -- ===================================
        ins_send_mail_trn(
          iv_process => iv_process,  -- 1.�����敪
          ov_errbuf  => lv_errbuf,   -- �G���[�E���b�Z�[�W           --# �Œ� #
          ov_retcode => lv_retcode,  -- ���^�[���E�R�[�h             --# �Œ� #
          ov_errmsg  => lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode = cv_status_error) THEN
          --(�G���[����)
          RAISE global_process_expt;
        END IF;
--
      END IF;
--
      -- ====================================
      -- ���[���z�M�Ώۈꎞ�e�[�u���쐬(A-4)
      -- ====================================
      ins_target_date(
        iv_process => iv_process,  -- 1.�����敪
        ov_errbuf  => lv_errbuf,   --   �G���[�E���b�Z�[�W           --# �Œ� #
        ov_retcode => lv_retcode,  --   ���^�[���E�R�[�h             --# �Œ� #
        ov_errmsg  => lv_errmsg    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode = cv_status_error) THEN
        --(�G���[����)
        RAISE global_process_expt;
      END IF;
--
      -- �N�����]�ƈ��W�v�̏ꍇ
      IF ( iv_process = cv_emp ) THEN
--
        -- ====================================
        -- ���[���z�M�f�[�^�擾(�]�ƈ��v)(A-6)
        -- ====================================
        get_send_mail_data_e(
          ov_errbuf  => lv_errbuf,   -- �G���[�E���b�Z�[�W           --# �Œ� #
          ov_retcode => lv_retcode,  -- ���^�[���E�R�[�h             --# �Œ� #
          ov_errmsg  => lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode = cv_status_error) THEN
          --(�G���[����)
          RAISE global_process_expt;
        END IF;
--
      -- �N�������_�W�v�̏ꍇ
      ELSIF (  iv_process = cv_base ) THEN
--
        -- ====================================
        -- ���[���z�M�f�[�^�擾(���_�v)(A-7)
        -- ====================================
        get_send_mail_data_b(
          ov_errbuf  => lv_errbuf,   -- �G���[�E���b�Z�[�W           --# �Œ� #
          ov_retcode => lv_retcode,  -- ���^�[���E�R�[�h             --# �Œ� #
          ov_errmsg  => lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode = cv_status_error) THEN
          --(�G���[����)
          RAISE global_process_expt;
        END IF;
--
      END IF;
--
      IF ( gt_wf_mail_tab.COUNT <> 0 ) THEN
        -- ====================================
        -- �A���[�g���[�����M�e�[�u���쐬(A-8)
        -- ====================================
        ins_wf_mail(
          ov_errbuf  => lv_errbuf,   -- �G���[�E���b�Z�[�W           --# �Œ� #
          ov_retcode => lv_retcode,  -- ���^�[���E�R�[�h             --# �Œ� #
          ov_errmsg  => lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode = cv_status_error) THEN
          --(�G���[����)
          RAISE global_process_expt;
        END IF;
--
        -- ====================================
        -- ���[���z�M�󋵃g�����X�V(A-9)
        -- ====================================
        upd_send_mail_trn(
          iv_process => iv_process,  -- 1.�����敪
          ov_errbuf  => lv_errbuf,   --   �G���[�E���b�Z�[�W           --# �Œ� #
          ov_retcode => lv_retcode,  --   ���^�[���E�R�[�h             --# �Œ� #
          ov_errmsg  => lv_errmsg    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode = cv_status_error) THEN
          --(�G���[����)
          RAISE global_process_expt;
        END IF;
      --�Ώۂ�0���̏ꍇ�A�x���I��
      ELSE
        ov_retcode := cv_status_warn;
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
    retcode       OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_process    IN  VARCHAR2,      -- 1.�����敪 (1�F����W�v 2�F�]�ƈ��W�v 3:�p�[�W����)
    iv_trg_time   IN  VARCHAR2       -- 2.�z�M�^�C�~���O ( HH24:MI �`��)
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
       iv_process
      ,iv_trg_time
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
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
      --�G���[�����J�E���g
      gn_error_cnt  := 1;
      --��������������
      gn_normal_cnt := 0;
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
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
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
END XXCOS002A08C;
/
