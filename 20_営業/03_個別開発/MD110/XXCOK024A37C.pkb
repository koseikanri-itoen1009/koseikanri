CREATE OR REPLACE PACKAGE BODY      XXCOK024A37C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A37C(body)
 * Description      : �T���f�[�^IF�o�́i���n�j
 * MD.050           : �T���f�[�^IF�o�́i���n�j MD050_COK_024_A37
 * Version          : 1.6
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  proc_init            ��������(A-1)
 *
 *  upd_control_p        �̔��T���Ǘ����X�V(A-5)
 *  submain              ���C�������v���V�[�W��
 *                          �Eproc_init
 *                       �̔��T�����̎擾(A-2)
 *                       ����敪�A�[�i�`�ԋ敪�̎擾(A-3)
 *                       �̔��T�����i���n�j�o�͏���(A-4)
 *                       ���C�������v���V�[�W��
 *                          �Eupd_control_p
 *                       �I������(A-6)
 *  main                 �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                          �Esubmain
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2021/02/15    1.0   K.Yoshikawa      main�V�K�쐬
 *  2021/04/23    1.1   K.Yoshikawa      main�V�K�쐬
 *  2021/06/30    1.2   T.Nishikawa      [E_�{�ғ�_17306] �����l�������ϓ��Ή��敪�Ή�
 *  2021/08/04    1.3   T.Nishikawa      [E_�{�ғ�_17409] GL�L�����ǉ��Ή�
 *  2022/07/21    1.4   K.Yoshikawa      [E_�{�ғ�_N1424] IaaS���t�g��QNo.21
 *  2022/09/06    1.5   SCSK Y.Koh        E_�{�ғ�_18172  �T���x���`�[������̍��z
 *  2023/06/22    1.6   SCSK R.Oikawa     E_�{�ғ�_19294  �������E�`�[������̍��z�T���̘A�g�s��
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal               CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal;  -- ����:0
  cv_status_warn                 CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;    -- �x��:1
  cv_status_error                CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;   -- �ُ�:2
  --WHO�J����
  cn_created_by                  CONSTANT NUMBER      := fnd_global.user_id;            -- CREATED_BY
  cd_creation_date               CONSTANT DATE        := SYSDATE;                       -- CREATION_DATE
  cn_last_updated_by             CONSTANT NUMBER      := fnd_global.user_id;            -- LAST_UPDATED_BY
  cd_last_update_date            CONSTANT DATE        := SYSDATE;                       -- LAST_UPDATE_DATE
  cn_last_update_login           CONSTANT NUMBER      := fnd_global.login_id;           -- LAST_UPDATE_LOGIN
  cn_request_id                  CONSTANT NUMBER      := fnd_global.conc_request_id;    -- REQUEST_ID
  cn_program_application_id      CONSTANT NUMBER      := fnd_global.prog_appl_id;       -- PROGRAM_APPLICATION_ID
  cn_program_id                  CONSTANT NUMBER      := fnd_global.conc_program_id;    -- PROGRAM_ID
  cd_program_update_date         CONSTANT DATE        := SYSDATE;                       -- PROGRAM_UPDATE_DATE
  cv_msg_part                    CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont                    CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg                     VARCHAR2(2000);
  gv_sep_msg                     VARCHAR2(2000);
  gv_exec_user                   VARCHAR2(100);
  gv_conc_name                   VARCHAR2(30);
  gv_conc_status                 VARCHAR2(30);
  gn_target_cnt                  NUMBER;                    -- �Ώی���
  gn_normal_cnt                  NUMBER;                    -- ���팏��
  gn_error_cnt                   NUMBER;                    -- �G���[����
  gn_warn_cnt                    NUMBER;                    -- �X�L�b�v����
--
--################################  �Œ蕔 END   ##################################
--
--##########################  �Œ苤�ʗ�O�錾�� START  ###########################
--
  --*** ���������ʗ�O ***
  global_process_expt            EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt                EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt         EXCEPTION;
  global_check_lock_expt         EXCEPTION;                 -- ���b�N�擾�G���[
  --
  --*** ���O�̂ݏo�͗�O ***
  global_api_expt_log            EXCEPTION;
  PRAGMA EXCEPTION_INIT( global_check_lock_expt, -54);
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                    CONSTANT VARCHAR2(30)  := 'XXCOK024A37C';       -- �p�b�P�[�W��
--
  cv_appl_name_xxcok             CONSTANT VARCHAR2(5)   := 'XXCOK';              -- �A�v���P�[�V�����Z�k��
  -- ���b�Z�[�W
  cv_msg_xxcok_00001             CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-00001';   -- �Ώۃf�[�^�Ȃ�
  cv_msg_xxcok_00003             CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-00003';   -- �v���t�@�C���擾�G���[
--
  cv_msg_xxcok_00006             CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-00006';   -- CSV�t�@�C�����m�[�g
--
  cv_msg_xxcok_00009             CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-00009';   -- CSV�t�@�C�����݃G���[
  cv_msg_xxcok_10787             CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10787';   -- �t�@�C���I�[�v���G���[
  cv_msg_xxcok_10788             CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10788';   -- �t�@�C���������݃G���[
  cv_msg_xxcok_10789             CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10789';   -- �t�@�C���N���[�Y�G���[
  cv_msg_xxcok_10592             CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10592';   -- �O�񏈗�ID�擾�G���[
  cv_msg_proc_date_err           CONSTANT  VARCHAR2(100):= 'APP-XXCOK1-00028';   -- �Ɩ����t�擾�G���[���b�Z�[�W
  -- �g�[�N��
  cv_tkn_profile                 CONSTANT VARCHAR2(10)  := 'PROFILE';            -- �g�[�N���F�v���t�@�C����
  cv_tkn_sqlerrm                 CONSTANT VARCHAR2(10)  := 'SQLERRM';            -- �g�[�N���FSQL�G���[
  cv_tkn_file_name               CONSTANT VARCHAR2(10)  := 'FILE_NAME';          -- �g�[�N���FSQL�G���[
--                                                                               -- YYYYMMDD
  cv_date_fmt_ymd                CONSTANT VARCHAR2(10)  := 'RRRRMMDD';           -- YYYYMMDD
  cv_date_fmt_dt_ymdhms          CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_date_fmt_dt_ymdhms;
                                                                                 -- YYYYMMDDHH24MISS
--
  cv_csv_fl_name                 CONSTANT VARCHAR2(33)  := 'XXCOK1_DEDUCTION_DATA_FILE_NAME';
                                                                                 -- XXCOK:�T���f�[�^�t�@�C����
  cv_csv_fl_dir                  CONSTANT VARCHAR2(33)  := 'XXCOK1_DEDUCTION_DATA_DIRE_PATH';
                                                                                 -- XXCOK:�T���f�[�^�f�B���N�g���p�X
  cv_item_code_dummy_f           CONSTANT VARCHAR2(33)  := 'XXCOK1_ITEM_CODE_DUMMY_F';  -- XXCOK:�i�ڃR�[�h_�_�~�[�l�i��z�T���j
  cv_item_code_dummy_u           CONSTANT VARCHAR2(33)  := 'XXCOK1_ITEM_CODE_DUMMY_U';  -- XXCOK:�i�ڃR�[�h_�_�~�[�l�i�A�b�v���[�h�j
  cv_item_code_dummy_o           CONSTANT VARCHAR2(33)  := 'XXCOK1_ITEM_CODE_DUMMY_O';  -- XXCOK:�i�ڃR�[�h_�_�~�[�l�i�J�z�����j
-- 2021/06/30 Ver1.2 Add Start
  cv_item_code_dummy_nt          CONSTANT VARCHAR2(33)  := 'XXCOK1_ITEM_CODE_DUMMY_NT';  -- XXCOK:�i�ڃR�[�h_�_�~�[�l�i�����l���j
-- 2021/06/30 Ver1.2 Add End
  cv_dqu                         CONSTANT VARCHAR2(1)   := '"';
  cv_sep                         CONSTANT VARCHAR2(1)   := ',';
--
  cv_company_code                CONSTANT VARCHAR2(3)   := '001';                -- ��ЃR�[�h
  cv_csv_mode                    CONSTANT VARCHAR2(1)   := 'w';                  -- csv�t�@�C���I�[�v�����̃��[�h
  cv_flag_1                      CONSTANT VARCHAR2(1)   := '1';                  -- �쐬���敪 1 �T����
  cv_flag_2                      CONSTANT VARCHAR2(1)   := '2';                  -- �쐬���敪 2 �T���ԁi���J�o���ԁA���z��������A�J�z��������j
  cv_flag_3                      CONSTANT VARCHAR2(1)   := '3';                  -- �쐬���敪 3 �T���ԁi����߂��j
  cv_status_cancel               CONSTANT VARCHAR2(1)   := 'C';                  -- �X�e�[�^�X C �L�����Z��
  cv_status_new                  CONSTANT VARCHAR2(1)   := 'N';                  -- �X�e�[�^�X N �V�K
  cv_source_category_v           CONSTANT VARCHAR2(1)   := 'V';                  -- �쐬���敪 V ������ѐU��
  cv_source_category_s           CONSTANT VARCHAR2(1)   := 'S';                  -- �쐬���敪 S �̔�����
  cv_source_category_t           CONSTANT VARCHAR2(1)   := 'T';                  -- �쐬���敪 T ������ѐU�ցiEDI�j
  cv_source_category_d           CONSTANT VARCHAR2(1)   := 'D';                  -- �쐬���敪 D ���z����
  cv_source_category_o           CONSTANT VARCHAR2(1)   := 'O';                  -- �쐬���敪 O �J�z����
  cv_source_category_u           CONSTANT VARCHAR2(1)   := 'U';                  -- �쐬���敪 U �A�b�v���[�h
  cv_source_category_f           CONSTANT VARCHAR2(1)   := 'F';                  -- �쐬���敪 F ��z�T��
  cv_report_decision_flag_0      CONSTANT VARCHAR2(1)   := '0';                  -- ����m��t���O 0 
  cv_sales_class_1               CONSTANT VARCHAR2(1)   := '1';                  -- ����敪 1�ʏ�
  cv_delivery_pattern_class_6    CONSTANT VARCHAR2(1)   := '6';                  -- �[�i�`�ԋ敪 6 ���ѐU��
  cv_delivery_pattern_class_9    CONSTANT VARCHAR2(1)   := '9';                  -- �[�i�`�ԋ敪 9 ���̑�
  cv_data_type_lookup            CONSTANT VARCHAR2(30)  := 'XXCOK1_DEDUCTION_DATA_TYPE'; -- �f�[�^��� �Q�ƃ^�C�v

  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_proc_date                   DATE;                                          -- �Ɩ����t
  gv_trans_date                  VARCHAR2(14);                                  -- �A�g���t
  gv_csv_file_dir                VARCHAR2(1000);                                -- �T���f�[�^�i���n�j�A�g�pCSV�t�@�C���o�͐�̎擾
  gv_file_name                   VARCHAR2(30);                                  -- �T���f�[�^�i���n�j�A�g�pCSV�t�@�C����
  gv_item_code_dummy_f           VARCHAR2(7);                                   -- �_�~�[�i�ڃR�[�h�i��z�T���j
  gv_item_code_dummy_u           VARCHAR2(7);                                   -- �_�~�[�i�ڃR�[�h�i�A�b�v���[�h�j
  gv_item_code_dummy_o           VARCHAR2(7);                                   -- �_�~�[�i�ڃR�[�h�i�J�z�����j
-- 2021/06/30 Ver1.2 Add Start
  gv_item_code_dummy_nt          VARCHAR2(7);                                   -- �_�~�[�i�ڃR�[�h�i�����l���j
-- 2021/06/30 Ver1.2 Add End
  gn_target_header_id_st_1       NUMBER;                                        -- �̔��T��ID (��)�T����
  gn_target_header_id_ed_1       NUMBER;                                        -- �̔��T��ID (��)�T����
  gd_target_header_date_st_2     DATE;                                          -- �̔��T��ID (��)�T���ԁi���J�o���ԁA���z��������A�J�z��������j
  gd_target_header_date_ed_2     DATE;                                          -- �̔��T��ID (��)�T���ԁi���J�o���ԁA���z��������A�J�z��������j
  gn_target_header_id_st_3       NUMBER;                                        -- �̔��T��ID (��)�T���ԁi����߂��j
  gn_target_header_id_ed_3       NUMBER;                                        -- �̔��T��ID (��)�T���ԁi����߂��j
-- 2021/08/04 Ver1.3 Add Start
  gd_max_gl_date                 DATE;                                          -- �ݒ�ύő�GL�L����
-- 2022/09/06 Ver1.5 DEL Start
--  gd_gl_date                     DATE;                                          -- ���߂̃I�[�v�����Ă����v���Ԃ̏I����
-- 2022/09/06 Ver1.5 DEL End
-- 2021/08/04 Ver1.3 Add End
--
  /**********************************************************************************
   * Procedure Name   : proc_init
   * Description      : ���������v���V�[�W��(A-1)
   ***********************************************************************************/
  PROCEDURE proc_init(
    ov_errbuf      OUT    VARCHAR2         --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode     OUT    VARCHAR2         --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg      OUT    VARCHAR2         --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name               CONSTANT VARCHAR2(100) := 'proc_init';          -- �v���O������
--
    -- ===============================
    -- �Œ胍�[�J���ϐ�
    -- ===============================
    lv_errbuf                 VARCHAR2(5000);                                 -- �G���[�E���b�Z�[�W
    lv_retcode                VARCHAR2(1);                                    -- ���^�[���E�R�[�h
    lv_errmsg                 VARCHAR2(5000);                                 -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_step                   VARCHAR2(100);                                    -- �X�e�b�v
    lv_message_token          VARCHAR2(100);                                    -- �A�g���t
    lb_fexists                BOOLEAN;                                          -- �t�@�C�����ݔ��f
    ln_file_length            NUMBER;                                           -- �t�@�C���̕�����
    lbi_block_size            BINARY_INTEGER;                                   -- �u���b�N�T�C�Y
    lv_csv_file               VARCHAR2(1000);                                   -- csv�t�@�C����
    --
    -- *** ���[�U�[��`��O ***
    profile_expt              EXCEPTION;                                        -- �v���t�@�C���擾��O
    csv_file_exst_expt        EXCEPTION;                                        -- CSV�t�@�C�����݃G���[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �Ɩ����t�̎擾
    lv_step := 'A-1.1';
    lv_message_token := '�Ɩ����t�̎擾';
    gd_proc_date := xxccp_common_pkg2.get_process_date;
    IF ( gd_proc_date IS NULL ) THEN
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_appl_name_xxcok,
        iv_name               =>  cv_msg_proc_date_err
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt_log;
    END IF;
--
    -- �A�g�����̎擾
    lv_step := 'A-1.2';
    lv_message_token := '�A�g�����̎擾';
    gv_trans_date    := TO_CHAR( SYSDATE, cv_date_fmt_dt_ymdhms );
--
    -- �v���t�@�C���擾
    lv_step := 'A-1.3a';
    lv_message_token := '�A�g�pCSV�t�@�C�����̎擾';
    -- �T���f�[�^�i���n�j�A�g�pCSV�t�@�C�����̎擾
    gv_file_name := FND_PROFILE.VALUE( cv_csv_fl_name );
    -- �擾�G���[��
    IF ( gv_file_name IS NULL ) THEN
      lv_message_token := cv_csv_fl_name;
      RAISE profile_expt;
    END IF;
--
    lv_csv_file := xxccp_common_pkg.get_msg(                                    -- �A�b�v���[�h���̂̏o��
                    iv_application  => cv_appl_name_xxcok                       -- �A�v���P�[�V�����Z�k��
                   ,iv_name         => cv_msg_xxcok_00006                       -- ���b�Z�[�W�R�[�h
                   ,iv_token_name1  => cv_tkn_file_name                         -- �g�[�N���R�[�h1
                   ,iv_token_value1 => gv_file_name                             -- �g�[�N���l1
                  );
    -- �t�@�C�����o��
    xxcmm_004common_pkg.put_message(
      iv_message_buff => lv_csv_file
     ,ov_errbuf       => lv_errbuf
     ,ov_retcode      => lv_retcode
     ,ov_errmsg       => lv_errmsg
    );
--
    lv_step := 'A-1.3b';
    lv_message_token := '�A�g�pCSV�t�@�C���o�͐�̎擾';
    -- �T���f�[�^�i���n�j�A�g�pCSV�t�@�C���o�͐�̎擾
    gv_csv_file_dir := FND_PROFILE.VALUE( cv_csv_fl_dir );
    -- �擾�G���[��
    IF ( gv_csv_file_dir IS NULL ) THEN
      lv_message_token := cv_csv_fl_dir;
      RAISE profile_expt;
    END IF;
--
    lv_step := 'A-1.3c';
    lv_message_token := '�_�~�[�i�ڃR�[�h�i��z�T���j�̎擾';
    -- �_�~�[�i�ڃR�[�h�̎擾
    gv_item_code_dummy_f := FND_PROFILE.VALUE( cv_item_code_dummy_f );
    -- �擾�G���[��
    IF ( gv_item_code_dummy_f IS NULL ) THEN
      lv_message_token := cv_item_code_dummy_f;
      RAISE profile_expt;
    END IF;
--
    lv_step := 'A-1.3d';
    lv_message_token := '�_�~�[�i�ڃR�[�h�i�A�b�v���[�h�j�̎擾';
    -- �_�~�[�i�ڃR�[�h�̎擾
    gv_item_code_dummy_u := FND_PROFILE.VALUE( cv_item_code_dummy_u );
    -- �擾�G���[��
    IF ( gv_item_code_dummy_u IS NULL ) THEN
      lv_message_token := cv_item_code_dummy_u;
      RAISE profile_expt;
    END IF;
--
    lv_step := 'A-1.3e';
    lv_message_token := '�_�~�[�i�ڃR�[�h�i�J�z�����j�̎擾';
    -- �_�~�[�i�ڃR�[�h�̎擾
    gv_item_code_dummy_o := FND_PROFILE.VALUE( cv_item_code_dummy_o );
    -- �擾�G���[��
    IF ( gv_item_code_dummy_o IS NULL ) THEN
      lv_message_token := cv_item_code_dummy_o;
      RAISE profile_expt;
    END IF;
-- 2021/06/30 Ver1.2 Add Start
--
    lv_step := 'A-1.3f';
    lv_message_token := '�_�~�[�i�ڃR�[�h�i�����l���j�̎擾';
    -- �_�~�[�i�ڃR�[�h�̎擾
    gv_item_code_dummy_nt := FND_PROFILE.VALUE( cv_item_code_dummy_nt );
    -- �擾�G���[��
    IF ( gv_item_code_dummy_nt IS NULL ) THEN
      lv_message_token := cv_item_code_dummy_nt;
      RAISE profile_expt;
    END IF;
-- 2021/06/30 Ver1.2 Add End
--
    lv_step := 'A-1.4';
    lv_message_token := 'CSV�t�@�C�����݃`�F�b�N';
--
    -- CSV�t�@�C�����݃`�F�b�N
    UTL_FILE.FGETATTR(
       location    => gv_csv_file_dir
      ,filename    => gv_file_name
      ,fexists     => lb_fexists
      ,file_length => ln_file_length
      ,block_size  => lbi_block_size
    );
    -- �t�@�C�����ݎ�
    IF ( lb_fexists = TRUE ) THEN
      RAISE csv_file_exst_expt;
    END IF;
--
    -- �����ΏۂƂȂ�̔��T��ID�擾
    lv_step := 'A-1.5';
    lv_message_token := '�����ΏۂƂȂ�̔��T��ID�擾';
    -- �@�T����
    BEGIN
--
      SELECT  xsdc.last_processing_id + 1
      INTO    gn_target_header_id_st_1
      FROM    xxcok_sales_deduction_control xsdc
      WHERE   xsdc.control_flag = cv_flag_1;
--
    EXCEPTION
      WHEN  OTHERS THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                        cv_appl_name_xxcok
                      , cv_msg_xxcok_10592
                      );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
    END;
--
    SELECT  MAX(xsd.sales_deduction_id)
    INTO    gn_target_header_id_ed_1
    FROM    xxcok_sales_deduction xsd
    WHERE   xsd.sales_deduction_id >= gn_target_header_id_st_1;
--
    -- �A�T���ԃf�[�^(���J�o���ԁA���z��������A�J�z�������)
    BEGIN
--
      SELECT  xsdc.last_cooperation_date
      INTO    gd_target_header_date_st_2
      FROM    xxcok_sales_deduction_control xsdc
      WHERE   xsdc.control_flag = cv_flag_2;
--
    EXCEPTION
      WHEN  OTHERS THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                        cv_appl_name_xxcok
                      , cv_msg_xxcok_10592
                      );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
    END;
--
-- 2021/08/04 Ver1.3 Mod Start
--    gd_target_header_date_ed_2 := gd_proc_date ;
    gd_target_header_date_ed_2 := gd_proc_date + .99999 ;
-- 2021/08/04 Ver1.3 Mod End
--
    -- �B�T���ԃf�[�^(����߂�)
    BEGIN
--
      SELECT  xsdc.last_processing_id + 1
      INTO    gn_target_header_id_st_3
      FROM    xxcok_sales_deduction_control xsdc
      WHERE   xsdc.control_flag = cv_flag_3;
--
    EXCEPTION
      WHEN  OTHERS THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                        cv_appl_name_xxcok
                      , cv_msg_xxcok_10592
                      );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
    END;
--
    SELECT  MAX(xdtr.sales_deduction_id)
    INTO    gn_target_header_id_ed_3
    FROM    xxcok_dedu_trn_rev xdtr
    WHERE   xdtr.sales_deduction_id >= gn_target_header_id_st_3;
--
-- 2021/08/04 Ver1.3 Add Start
    -- �����ς̍ő�GL�L�����擾
    lv_step := 'A-1.7';
--
    SELECT  MAX(xsd.gl_date)  max_gl_date
    INTO    gd_max_gl_date
    FROM    xxcok_sales_deduction xsd
    WHERE   xsd.gl_date  IS NOT NULL;
--
-- 2022/09/06 Ver1.5 DEL Start
--    --���߂̃I�[�v�����Ă����v���Ԃ̏I�����擾
--    lv_step := 'A-1.8';
--    SELECT MIN(gps.end_date)  min_end_date
--    INTO   gd_gl_date
--    FROM   gl_period_statuses  gps
--    WHERE  gps.set_of_books_id        = FND_PROFILE.VALUE('GL_SET_OF_BKS_ID')
--    AND    gps.application_id         = 101
--    AND    gps.adjustment_period_flag = 'N'
--    AND    gps.closing_status         = 'O';
-- 2022/09/06 Ver1.5 DEL End
--
-- 2021/08/04 Ver1.3 Add End
--
  EXCEPTION
    -- *** �C�ӂŗ�O�������L�q���� ****
    -- �J�[�\���̃N���[�Y�������ɋL�q����
    --*** �v���t�@�C���擾�G���[ ***
    WHEN profile_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcok            -- �A�v���P�[�V�����Z�k���FXXCOK
                     ,iv_name         => cv_msg_xxcok_00003            -- ���b�Z�[�W�FAPP-XXCOK1-00003 �v���t�@�C���擾�G���[
                     ,iv_token_name1  => cv_tkn_profile                -- �g�[�N���FPROFILE
                     ,iv_token_value1 => lv_message_token              -- �v���t�@�C����
                     );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg;
      ov_retcode := cv_status_error;
    --*** CSV�t�@�C�����݃G���[ ***
    WHEN csv_file_exst_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcok            -- �A�v���P�[�V�����Z�k���FXXCOK
                     ,iv_name         => cv_msg_xxcok_00009            -- ���b�Z�[�W�FAPP-XXCOK1-00009 CSV�t�@�C�����݃G���[
                     ,iv_token_name1  => cv_tkn_file_name              -- �g�[�N���FFILE_NAME
                     ,iv_token_value1 => gv_file_name                  -- �v���t�@�C����
                     );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg;
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf    := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      ov_retcode   := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_init;
--
  /**********************************************************************************
   * Procedure Name   : upd_control_p
   * Description      : �̔��T���Ǘ����X�V(A-5)
   ***********************************************************************************/
  PROCEDURE upd_control_p(
    ov_errbuf  OUT VARCHAR2                                 -- �G���[�E���b�Z�[�W
  , ov_retcode OUT VARCHAR2                                 -- ���^�[���E�R�[�h
  , ov_errmsg  OUT VARCHAR2                                 -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
--
    -- ==============================
    -- ���[�J���萔
    -- ==============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'upd_control_p'; -- �v���O������
    -- ==============================
    -- ���[�J���ϐ�
    -- ==============================
    lv_errbuf        VARCHAR2(5000)      DEFAULT NULL;       -- �G���[�E���b�Z�[�W
    lv_retcode       VARCHAR2(1)         DEFAULT NULL;       -- ���^�[���E�R�[�h
    lv_errmsg        VARCHAR2(5000)      DEFAULT NULL;       -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_step          VARCHAR2(100);                          -- �X�e�b�v
    lv_message_token VARCHAR2(100);                          -- �A�g���t
--
  BEGIN
--
    ov_retcode  :=  cv_status_normal;
--
    -- ============================================================
    -- �̔��T���Ǘ����X�V
    -- ============================================================
   lv_step := 'A-5.1';
   lv_message_token := ' �̔��T���Ǘ����X�V';
   UPDATE  xxcok_sales_deduction_control
    SET     last_processing_id      = NVL(gn_target_header_id_ed_1, last_processing_id) ,
            last_updated_by         = cn_last_updated_by                            ,
            last_update_date        = SYSDATE                                       ,
            last_update_login       = cn_last_update_login                          ,
            request_id              = cn_request_id                                 ,
            program_application_id  = cn_program_application_id                     ,
            program_id              = cn_program_id                                 ,
            program_update_date     = SYSDATE
    WHERE   control_flag  = cv_flag_1;
--
    UPDATE  xxcok_sales_deduction_control
    SET     last_cooperation_date   = NVL(gd_target_header_date_ed_2, last_cooperation_date) ,
            last_updated_by         = cn_last_updated_by                            ,
            last_update_date        = SYSDATE                                       ,
            last_update_login       = cn_last_update_login                          ,
            request_id              = cn_request_id                                 ,
            program_application_id  = cn_program_application_id                     ,
            program_id              = cn_program_id                                 ,
            program_update_date     = SYSDATE
    WHERE   control_flag  = cv_flag_2;
--
    UPDATE  xxcok_sales_deduction_control
    SET     last_processing_id      = NVL(gn_target_header_id_ed_3, last_processing_id) ,
            last_updated_by         = cn_last_updated_by                            ,
            last_update_date        = SYSDATE                                       ,
            last_update_login       = cn_last_update_login                          ,
            request_id              = cn_request_id                                 ,
            program_application_id  = cn_program_application_id                     ,
            program_id              = cn_program_id                                 ,
            program_update_date     = SYSDATE
    WHERE   control_flag  = cv_flag_3;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN  global_process_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN  global_api_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN  global_api_others_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN  OTHERS THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
  END upd_control_p;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf      OUT    VARCHAR2         --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode     OUT    VARCHAR2         --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg      OUT    VARCHAR2         --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name               CONSTANT VARCHAR2(100) := 'submain';            -- �v���O������
    -- ===============================
    -- �Œ胍�[�J���ϐ�
    -- ===============================
    lv_errbuf                 VARCHAR2(5000);                                 -- �G���[�E���b�Z�[�W
    lv_retcode                VARCHAR2(1);                                    -- ���^�[���E�R�[�h
    lv_errmsg                 VARCHAR2(5000);                                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_step                   VARCHAR2(100);                                  -- �X�e�b�v
    lv_sales_class            VARCHAR2(1);                                    -- ����敪
    lv_delivery_pattern_class VARCHAR2(1);                                    -- �[�i�`�ԋ敪
    lv_attribute11            VARCHAR2(150);                                  -- �T���f�[�^���DFF11 �ϓ��Ή��敪
    lv_attribute12            VARCHAR2(150);                                  -- �T���f�[�^���DFF12 �ϓ��Ή��敪(���z������)
    lv_fluctuation_value_class   VARCHAR2(150);                               -- �ϓ��Ή��敪
    lv_data_type_name         VARCHAR2(80);                                   -- �T���f�[�^��ޖ���
-- 2021/08/04 Ver1.3 Add Start
    ld_gl_date                DATE;                                           -- GL�L����
-- 2021/08/04 Ver1.3 End Start
    --###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[���[�J���ϐ�
    -- ===============================
    lv_sqlerrm                VARCHAR2(5000);                                 -- SQLERRM�ޔ�
    lf_file_hand              UTL_FILE.FILE_TYPE;                             -- �t�@�C���E�n���h���̐錾
    lv_message_token          VARCHAR2(100);                                  -- �A�g���t
    lv_out_csv_line           VARCHAR2(1000);                                 -- �o�͍s
    lv_item_code              VARCHAR2(7);                                    -- �i�ڃR�[�h
--
    -- �T���f�[�^�i���n�j���J�[�\��
    --lv_step := 'A-2';
    CURSOR csv_deduction_cur
    IS
      --�@�T����
      SELECT sales_deduction_id ,
             --base_code_from,
             base_code_to,
             --customer_code_from,
             customer_code_to,
             deduction_chain_code,
             corp_code,
             record_date,
             source_category,
             source_line_id,
             condition_id,
             condition_no,
             condition_line_id,
             data_type,
             status ,
             item_code,
             sales_uom_code,
             sales_unit_price,
             sales_quantity,
             sale_pure_amount,
             sale_tax_amount,
             deduction_uom_code,
             deduction_unit_price,
             deduction_quantity,
             deduction_amount,
             compensation,
             margin,
             sales_promotion_expenses,
             margin_reduction,
             tax_code,
             tax_rate,
             recon_tax_code,
             recon_tax_rate,
             deduction_tax_amount,
             --remarks,
             application_no,
             --gl_if_flag,
             --gl_base_code,
             --gl_date,
             --recovery_date,
             --recovery_add_request_id,
             report_decision_flag,
             recovery_del_date ,
             --recovery_del_request_id,
             --cancel_flag,
             --cancel_base_code,
             --cancel_gl_date,
             --cancel_user,
             --recon_base_code,
-- 2021/08/04 Ver1.3 Mod Start
--             --recon_slip_num,
             recon_slip_num,
-- 2021/08/04 Ver1.3 Mod End
             --carry_payment_slip_num,
             --gl_interface_id,
             --cancel_gl_interface_id,
             created_by,
             last_updated_by,
             --last_update_login,
             --request_id,
             --program_application_id,
             --program_id,
             --program_update_date,
             create_user_name,
             creation_date,
             last_updated_user_name,
             last_update_date 
      FROM
         (SELECT xsd.sales_deduction_id ,                                         --�̔��T��ID
                 --xsd.base_code_from ,
                 xsd.base_code_to ,                                               --�U�֐拒�_
                 --xsd.customer_code_from ,
                 xsd.customer_code_to ,                                           --�U�֐�ڋq�R�[�h
                 xsd.deduction_chain_code ,                                       --�T���p�`�F�[���R�[�h
                 xsd.corp_code ,                                                  --��ƃR�[�h
                 TO_CHAR( xsd.record_date , cv_date_fmt_ymd )
                                                      record_date,                --�v���
                 xsd.source_category ,                                            --�쐬���敪
                 xsd.source_line_id ,                                             --�쐬������ID
                 xsd.condition_id ,                                               --�T������ID
                 xsd.condition_no ,                                               --�T���ԍ�
                 xsd.condition_line_id ,                                          --�T���ڍ�ID
                 xsd.data_type ,                                                  --�f�[�^���
                 cv_status_new                        status ,                    --�X�e�[�^�X
                 xsd.item_code ,                                                  --�i�ڃR�[�h
                 xsd.sales_uom_code ,                                             --�̔��P��
                 xsd.sales_unit_price ,                                           --�̔��P��
                 xsd.sales_quantity ,                                             --�̔�����
                 xsd.sale_pure_amount ,                                           --����{�̋��z
                 xsd.sale_tax_amount ,                                            --�������Ŋz
                 xsd.deduction_uom_code ,                                         --�T���P��
                 xsd.deduction_unit_price ,                                       --�T���P��
                 xsd.deduction_quantity ,                                         --�T������
                 xsd.deduction_amount ,                                           --�T���z
                 xsd.compensation ,                                               --��U
                 xsd.margin ,                                                     --�≮�}�[�W��
                 xsd.sales_promotion_expenses ,                                   --�g��
                 xsd.margin_reduction ,                                           --�≮�}�[�W�����z
                 xsd.tax_code ,                                                   --�ŃR�[�h
                 xsd.tax_rate ,                                                   --�ŗ�
                 xsd.recon_tax_code ,                                             --�������ŃR�[�h
                 xsd.recon_tax_rate ,                                             --�������ŗ�
                 xsd.deduction_tax_amount ,                                       --�T���Ŋz
                 --xsd.remarks ,
                 xsd.application_no ,                                             --�\����No.
                 --xsd.gl_if_flag ,
                 --xsd.gl_base_code ,
                 --xsd.gl_date ,
                 --xsd.recovery_date ,
                 --xsd.recovery_add_request_id ,
                 xsd.report_decision_flag ,                                       --����m��t���O
                 NULL                                 recovery_del_date ,         --���J�o���f�[�^�폜�����t
                 --xsd.recovery_del_request_id ,
                 --xsd.cancel_flag ,
                 --xsd.cancel_base_code ,
                 --xsd.cancel_gl_date ,
                 --xsd.cancel_user ,
                 --xsd.recon_base_code ,
-- 2021/08/04 Ver1.3 Mod Start
--                 --xsd.recon_slip_num ,
                 xsd.recon_slip_num ,                                              --�x���`�[�ԍ�
-- 2021/08/04 Ver1.3 Mod End
                 --xsd.carry_payment_slip_num ,
                 --xsd.gl_interface_id ,
                 --xsd.cancel_gl_interface_id ,
                 xsd.created_by ,                                                 --�쐬��
                 xsd.last_updated_by ,                                            --�ŏI�X�V��
                 --xsd.last_update_login ,
                 --xsd.request_id ,
                 --xsd.program_application_id ,
                 --xsd.program_id ,
                 --xsd.program_update_date ,
                 fu1.user_name                        create_user_name,           -- �쐬��
                 TO_CHAR( xsd.creation_date, cv_date_fmt_ymd )
                                                      creation_date,              -- �쐬��
                 fu2.user_name                        last_updated_user_name,     -- �ŏI�X�V��
                 TO_CHAR( xsd.last_update_date, cv_date_fmt_ymd )
                                                      last_update_date            -- �ŏI�X�V��
          FROM   xxcok_sales_deduction xsd,  -- �̔��T�����
                 fnd_user fu1,               -- ���[�U
                 fnd_user fu2                -- ���[�U
          WHERE  1=1
          AND    xsd.sales_deduction_id BETWEEN gn_target_header_id_st_1  AND gn_target_header_id_ed_1
          AND    xsd.created_by      = fu1.user_id(+)
          AND    xsd.last_updated_by = fu2.user_id(+)
          ORDER BY xsd.sales_deduction_id
         ) 
          UNION ALL
      --�A�T���ԃf�[�^(���J�o���ԁA���z��������A�J�z�������)
      SELECT sales_deduction_id,
             --base_code_from,
             base_code_to,
             --customer_code_from,
             customer_code_to,
             deduction_chain_code,
             corp_code,
             record_date,
             source_category,
             source_line_id,
             condition_id,
             condition_no,
             condition_line_id,
             data_type,
             status,
             item_code,
             sales_uom_code,
             sales_unit_price,
             sales_quantity,
             sale_pure_amount,
             sale_tax_amount,
             deduction_uom_code,
             deduction_unit_price,
             deduction_quantity,
             deduction_amount,
             compensation,
             margin,
             sales_promotion_expenses,
             margin_reduction,
             tax_code,
             tax_rate,
             recon_tax_code,
             recon_tax_rate,
             deduction_tax_amount,
             --remarks,
             application_no,
             --gl_if_flag,
             --gl_base_code,
             --gl_date,
             --recovery_date,
             --recovery_add_request_id,
             report_decision_flag,
             recovery_del_date,
             --recovery_del_request_id,
             --cancel_flag,
             --cancel_base_code,
             --cancel_gl_date,
             --cancel_user,
             --recon_base_code,
-- 2021/08/04 Ver1.3 Mod Start
--             --recon_slip_num,
             recon_slip_num,
-- 2021/08/04 Ver1.3 Mod End
             --carry_payment_slip_num,
             --gl_interface_id,
             --cancel_gl_interface_id,
             created_by,
             last_updated_by,
             --last_update_login,
             --request_id,
             --program_application_id,
             --program_id,
             --program_update_date,
             create_user_name,
             creation_date,
             last_updated_user_name,
             last_update_date 
      FROM
         (SELECT xsd.sales_deduction_id ,                                         --�̔��T��ID
                 --xsd.base_code_from ,
                 xsd.base_code_to ,                                               --�U�֐拒�_
                 --xsd.customer_code_from ,
                 xsd.customer_code_to ,                                           --�U�֐�ڋq�R�[�h
                 xsd.deduction_chain_code ,                                       --�T���p�`�F�[���R�[�h
                 xsd.corp_code ,                                                  --��ƃR�[�h
                 TO_CHAR( xsd.record_date , cv_date_fmt_ymd )
                                                      record_date,                --�v���
                 xsd.source_category ,                                            --�쐬���敪
                 xsd.source_line_id ,                                             --�쐬������ID
                 xsd.condition_id ,                                               --�T������ID
                 xsd.condition_no ,                                               --�T���ԍ�
                 xsd.condition_line_id ,                                          --�T���ڍ�ID
                 xsd.data_type ,                                                  --�f�[�^���
                 xsd.status ,                                                     --�X�e�[�^�X
                 xsd.item_code ,                                                  --�i�ڃR�[�h
                 xsd.sales_uom_code ,                                             --�̔��P��
                 xsd.sales_unit_price ,                                           --�̔��P��
                 xsd.sales_quantity * -1              sales_quantity,             --�̔�����
                 xsd.sale_pure_amount * -1            sale_pure_amount,           --����{�̋��z
                 xsd.sale_tax_amount * -1             sale_tax_amount,            --�������Ŋz
                 xsd.deduction_uom_code ,                                         --�T���P��
                 xsd.deduction_unit_price ,                                       --�T���P��
                 xsd.deduction_quantity * -1          deduction_quantity,         --�T������
                 xsd.deduction_amount * -1            deduction_amount,           --�T���z
                 xsd.compensation * -1                compensation,               --��U
                 xsd.margin * -1                      margin,                     --�≮�}�[�W��
                 xsd.sales_promotion_expenses * -1    sales_promotion_expenses,   --�g��
                 xsd.margin_reduction * -1            margin_reduction,           --�≮�}�[�W�����z
                 xsd.tax_code ,                                                   --�ŃR�[�h
                 xsd.tax_rate ,                                                   --�ŗ�
                 xsd.recon_tax_code ,                                             --�������ŃR�[�h
                 xsd.recon_tax_rate ,                                             --�������ŗ�
                 xsd.deduction_tax_amount * -1        deduction_tax_amount,       --�T���Ŋz
                 --xsd.remarks ,
                 xsd.application_no ,                                             --�\����No.
                 --xsd.gl_if_flag ,
                 --xsd.gl_base_code ,
                 --xsd.gl_date ,
                 --xsd.recovery_date ,
                 --xsd.recovery_add_request_id ,
                 xsd.report_decision_flag ,                                       --����m��t���O
                 TO_CHAR( xsd.recovery_del_date, cv_date_fmt_ymd )
                                                      recovery_del_date,          --���J�o���f�[�^�폜�����t
                 --xsd.recovery_del_request_id ,
                 --xsd.cancel_flag ,
                 --xsd.cancel_base_code ,
                 --xsd.cancel_gl_date ,
                 --xsd.cancel_user ,
                 --xsd.recon_base_code ,
-- 2021/08/04 Ver1.3 Mod Start
--                 --xsd.recon_slip_num ,
                 xsd.recon_slip_num ,                                              --�x���`�[�ԍ�
-- 2021/08/04 Ver1.3 Mod End
                 --xsd.carry_payment_slip_num ,
                 --xsd.gl_interface_id ,
                 --xsd.cancel_gl_interface_id ,
                 xsd.created_by ,                                                 --�쐬��
                 xsd.last_updated_by ,                                            --�ŏI�X�V��
                 --xsd.last_update_login ,
                 --xsd.request_id ,
                 --xsd.program_application_id ,
                 --xsd.program_id ,
                 --xsd.program_update_date ,
                 fu1.user_name                        create_user_name,           -- �쐬��
                 TO_CHAR( xsd.creation_date, cv_date_fmt_ymd )
                                                      creation_date,              -- �쐬��
                 fu2.user_name                        last_updated_user_name,     -- �ŏI�X�V��
                 TO_CHAR( xsd.last_update_date, cv_date_fmt_ymd )
                                                      last_update_date            -- �ŏI�X�V��
          FROM   xxcok_sales_deduction xsd,  -- �̔��T�����
                 fnd_user fu1,               -- ���[�U
                 fnd_user fu2                -- ���[�U
          WHERE  1=1
          AND    xsd.recovery_del_date >  gd_target_header_date_st_2  
          AND    xsd.recovery_del_date <= gd_target_header_date_ed_2
          AND    xsd.status            =  cv_status_cancel
          AND    xsd.created_by        =  fu1.user_id(+)
          AND    xsd.last_updated_by   =  fu2.user_id(+)
          ORDER BY xsd.sales_deduction_id
         )
          UNION ALL
      --�B�T���ԃf�[�^(����߂�)
      SELECT sales_deduction_id,
             --base_code_from,
             base_code_to,
             --customer_code_from,
             customer_code_to,
             deduction_chain_code,
             corp_code,
             record_date,
             source_category,
             source_line_id,
             condition_id,
             condition_no,
             condition_line_id,
             data_type,
             status,
             item_code,
             sales_uom_code,
             sales_unit_price,
             sales_quantity,
             sale_pure_amount,
             sale_tax_amount,
             deduction_uom_code,
             deduction_unit_price,
             deduction_quantity,
             deduction_amount,
             compensation,
             margin,
             sales_promotion_expenses,
             margin_reduction,
             tax_code,
             tax_rate,
             recon_tax_code,
             recon_tax_rate,
             deduction_tax_amount,
             --remarks,
             application_no,
             --gl_if_flag,
             --gl_base_code,
             --gl_date,
             --recovery_date,
             --recovery_add_request_id,
             report_decision_flag,
             recovery_del_date,
             --recovery_del_request_id,
             --cancel_flag,
             --cancel_base_code,
             --cancel_gl_date,
             --cancel_user,
             --recon_base_code,
-- 2021/08/04 Ver1.3 Mod Start
--             --recon_slip_num,
             recon_slip_num,
-- 2021/08/04 Ver1.3 Mod End
             --carry_payment_slip_num,
             --gl_interface_id,
             --cancel_gl_interface_id,
             created_by,
             last_updated_by,
             --last_update_login,
             --request_id,
             --program_application_id,
             --program_id,
             --program_update_date,
             create_user_name,
             creation_date,
             last_updated_user_name,
             last_update_date 
      FROM
         (SELECT xdtr.sales_deduction_id ,                                         --�̔��T��ID
                 --xdtr.base_code_from ,
                 xdtr.base_code_to ,                                               --�U�֐拒�_
                 --xdtr.customer_code_from ,
                 xdtr.customer_code_to ,                                           --�U�֐�ڋq�R�[�h
                 NULL                                  deduction_chain_code,       --�T���p�`�F�[���R�[�h
                 NULL                                  corp_code,                  --��ƃR�[�h
                 TO_CHAR( xdtr.record_date , cv_date_fmt_ymd )
                                                       record_date,                --�v���
                 cv_source_category_v                  source_category,            --�쐬���敪
                 xdtr.source_line_id ,                                             --�쐬������ID
                 xdtr.condition_id ,                                               --�T������ID
                 xdtr.condition_no ,                                               --�T���ԍ�
                 xdtr.condition_line_id ,                                          --�T���ڍ�ID
                 xdtr.data_type ,                                                  --�f�[�^���
                 cv_status_cancel                      status,                     --�X�e�[�^�X
                 xdtr.item_code ,                                                  --�i�ڃR�[�h
                 xdtr.sales_uom_code ,                                             --�̔��P��
                 xdtr.sales_unit_price ,                                           --�̔��P��
                 xdtr.sales_quantity                   sales_quantity,             --�̔�����
                 xdtr.sale_pure_amount                 sale_pure_amount,           --����{�̋��z
                 xdtr.sale_tax_amount                  sale_tax_amount,            --�������Ŋz
                 xdtr.deduction_uom_code ,                                         --�T���P��
                 xdtr.deduction_unit_price ,                                       --�T���P��
                 xdtr.deduction_quantity               deduction_quantity,         --�T������
                 xdtr.deduction_amount                 deduction_amount,           --�T���z
                 xdtr.compensation                     compensation,               --��U
                 xdtr.margin                           margin,                     --�≮�}�[�W��
                 xdtr.sales_promotion_expenses         sales_promotion_expenses,   --�g��
                 xdtr.margin_reduction                 margin_reduction,           --�≮�}�[�W�����z
                 xdtr.tax_code ,                                                   --�ŃR�[�h
                 xdtr.tax_rate ,                                                   --�ŗ�
                 NULL                                  recon_tax_code,             --�������ŃR�[�h
                 NULL                                  recon_tax_rate,             --�������ŗ�
                 xdtr.deduction_tax_amount             deduction_tax_amount,       --�T���Ŋz
                 --xdtr.remarks ,
                 NULL                                  application_no,             --�\����No.
                 --xdtr.gl_if_flag ,
                 --xdtr.gl_base_code ,
                 --xdtr.gl_date ,
                 --xdtr.recovery_date ,
                 --xdtr.recovery_add_request_id ,
                 cv_report_decision_flag_0             report_decision_flag,       --����m��t���O
                 NULL                                  recovery_del_date,          --���J�o���f�[�^�폜�����t
                 --xdtr.recovery_del_request_id ,
                 --xdtr.cancel_flag ,
                 --xdtr.cancel_base_code ,
                 --xdtr.cancel_gl_date ,
                 --xdtr.cancel_user ,
                 --xdtr.recon_base_code ,
-- 2021/08/04 Ver1.3 Mod Start
--                 --xdtr.recon_slip_num ,
                 NULL                                  recon_slip_num ,            --�x���`�[�ԍ�
-- 2021/08/04 Ver1.3 Mod End
                 --xdtr.carry_payment_slip_num ,
                 --xdtr.gl_interface_id ,
                 --xdtr.cancel_gl_interface_id ,
                 xdtr.created_by ,                                                 --�쐬��
                 xdtr.last_updated_by ,                                            --�ŏI�X�V��
                 --xdtr.last_update_login ,
                 --xdtr.request_id ,
                 --xdtr.program_application_id ,
                 --xdtr.program_id ,
                 --xdtr.program_update_date ,
                 fu1.user_name                         create_user_name,           -- �쐬��
                 TO_CHAR( xdtr.creation_date, cv_date_fmt_ymd )
                                                       creation_date,              -- �쐬��
                 fu2.user_name                         last_updated_user_name,     -- �ŏI�X�V��
                 TO_CHAR( xdtr.last_update_date, cv_date_fmt_ymd )
                                                       last_update_date            -- �ŏI�X�V��
          FROM   xxcok_dedu_trn_rev xdtr,    -- �̔��T�����
                 fnd_user fu1,               -- ���[�U
                 fnd_user fu2                -- ���[�U
          WHERE  1=1
          AND    xdtr.sales_deduction_id BETWEEN gn_target_header_id_st_3  AND gn_target_header_id_ed_3
          AND    xdtr.created_by      = fu1.user_id(+)
          AND    xdtr.last_updated_by = fu2.user_id(+)
          ORDER BY xdtr.sales_deduction_id
         ) ;
--
    TYPE csv_deduction_ttype IS TABLE OF csv_deduction_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    lt_csv_deduction_tab       csv_deduction_ttype;               -- �T�̔��T�����IF�o�̓f�[�^
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    subproc_expt              EXCEPTION;       -- �T�u�v���O�����G���[
    file_open_expt            EXCEPTION;       -- �t�@�C���I�[�v���G���[
    file_output_expt          EXCEPTION;       -- �t�@�C���������݃G���[
    file_close_expt           EXCEPTION;       -- �t�@�C���N���[�Y�G���[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    -- ===============================================
    -- proc_init�̌Ăяo���i����������proc_init�ōs���j
    -- ===============================================
    proc_init(
       ov_errbuf      => lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode     => lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg      => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE subproc_expt;
    END IF;
--
    -----------------------------------
    -- A-2.�̔��T�����̎擾
    -----------------------------------
    lv_step := 'A-2';
--
    OPEN  csv_deduction_cur;
-- 2022/07/21 DEL Start
--    FETCH csv_deduction_cur BULK COLLECT INTO lt_csv_deduction_tab;
--    CLOSE csv_deduction_cur;
    -- ���������J�E���g
--    gn_target_cnt := lt_csv_deduction_tab.COUNT;
-- 2022/07/21 DEL End
--
    -----------------------------------------------
    -- A-3.�̔��敪�A�[�i�`�ԋ敪�A�ϓ��Ή��敪�̎擾
    -----------------------------------------------
    lv_step := 'A-4.1a';
      -- CSV�t�@�C���I�[�v��
      lv_step := 'A-1.5';
      BEGIN
        lf_file_hand := UTL_FILE.FOPEN(  location  => gv_csv_file_dir  -- �o�͐�
                                        ,filename  => gv_file_name     -- CSV�t�@�C����
                                        ,open_mode => cv_csv_mode      -- ���[�h
                                       );
      EXCEPTION
        WHEN OTHERS THEN
          lv_sqlerrm := SQLERRM;
          RAISE file_open_expt;
      END;
--
-- 2022/07/21 ADD Start
    LOOP
    FETCH csv_deduction_cur BULK COLLECT INTO lt_csv_deduction_tab LIMIT 500000;
    -- ���������J�E���g
    gn_target_cnt := gn_target_cnt + lt_csv_deduction_tab.COUNT;
-- 2022/07/21 ADD End
      <<out_csv_loop>>
      FOR i IN 1..lt_csv_deduction_tab.COUNT LOOP
--
      -- �̔��敪�A�[�i�`�ԋ敪�擾
      lv_step := 'A-3.1' || 'sales_deduction_id:' || lt_csv_deduction_tab( i ).sales_deduction_id;
        IF (lt_csv_deduction_tab( i ).source_category = cv_source_category_s ) THEN
          BEGIN
            SELECT sales_class,
                   delivery_pattern_class
            INTO   lv_sales_class,
                   lv_delivery_pattern_class
            FROM   xxcos_sales_exp_lines xsel
            WHERE  xsel.sales_exp_line_id = lt_csv_deduction_tab( i ).source_line_id;
      --
          EXCEPTION
              WHEN  NO_DATA_FOUND THEN
                lv_sales_class            := NULL;
                lv_delivery_pattern_class := NULL;
          END;
        ELSIF (lt_csv_deduction_tab( i ).source_category = cv_source_category_t ) THEN
            lv_sales_class            := cv_sales_class_1;
            lv_delivery_pattern_class := cv_delivery_pattern_class_6;
        ELSIF (lt_csv_deduction_tab( i ).source_category = cv_source_category_v ) THEN
            lv_sales_class            := cv_sales_class_1;
            lv_delivery_pattern_class := cv_delivery_pattern_class_6;
        ELSE
            lv_sales_class            := cv_sales_class_1;
            lv_delivery_pattern_class := cv_delivery_pattern_class_9;
        END IF;
      -- �ϓ��Ή��敪�擾
      lv_step := 'A-3.3' || 'sales_deduction_id:' || lt_csv_deduction_tab( i ).sales_deduction_id;
        BEGIN
          SELECT attribute11,
                 attribute12,
                 meaning
          INTO   lv_attribute11,
                 lv_attribute12,
                 lv_data_type_name
          FROM   fnd_lookup_values_vl flv
          WHERE  flv.lookup_code = lt_csv_deduction_tab( i ).data_type
          AND    flv.lookup_type = cv_data_type_lookup;
        EXCEPTION
            WHEN  NO_DATA_FOUND THEN
                 lv_attribute11    := null;
                 lv_attribute12    := null;
                 lv_data_type_name := null;
        END;
--
        IF lt_csv_deduction_tab( i ).source_category = cv_source_category_d THEN
          lv_fluctuation_value_class := lv_attribute12;
-- 2021/04/20 MOD Start
        ELSIF lt_csv_deduction_tab( i ).source_category = cv_source_category_o THEN
          lv_fluctuation_value_class := null;
-- 2021/04/20 MOD End
        ELSE
-- 2021/06/30 Ver1.2 Mod Start
          IF  lt_csv_deduction_tab( i ).item_code  = gv_item_code_dummy_nt THEN
            lv_fluctuation_value_class := lv_attribute12;
          ELSE
            lv_fluctuation_value_class := lv_attribute11;
          END IF;
--          lv_fluctuation_value_class := lv_attribute11;
-- 2021/06/30 Ver1.2 Mod End
        END IF;
-- 2021/08/04 Ver1.3 Add Start
--
      -- GL�L�����̕ҏW
      lv_step := 'A-3.4' || 'sales_deduction_id:' || lt_csv_deduction_tab( i ).sales_deduction_id;
--
      IF ( LAST_DAY(TO_DATE(lt_csv_deduction_tab( i ).record_date,cv_date_fmt_ymd)) <= gd_max_gl_date ) THEN
        ld_gl_date := LAST_DAY( ADD_MONTHS( gd_max_gl_date, 1 ) );
      ELSE
        ld_gl_date := LAST_DAY(TO_DATE(lt_csv_deduction_tab( i ).record_date,cv_date_fmt_ymd));
      END IF;
--
      IF (lt_csv_deduction_tab( i ).source_category = cv_source_category_d ) THEN
        IF (lt_csv_deduction_tab( i ).status = cv_status_new ) THEN
          BEGIN
            SELECT xdrh.gl_date  gl_date
            INTO   ld_gl_date
            FROM   xxcok_deduction_recon_head  xdrh
            WHERE  xdrh.recon_slip_num   = lt_csv_deduction_tab( i ).recon_slip_num;
          EXCEPTION
            WHEN  NO_DATA_FOUND THEN
              ld_gl_date := null;
          END;
        ELSIF (lt_csv_deduction_tab( i ).status = cv_status_cancel ) THEN
-- 2022/09/06 Ver1.5 MOD Start
          BEGIN
-- Ver1.6 MOD Start
--            SELECT DECODE(xdrh.interface_div,'AP',xdrh.cancel_gl_date,'WP',xdrh.gl_date)  gl_date
            SELECT DECODE(xdrh.interface_div,'AP',xdrh.cancel_gl_date,
                          'AR',xdrh.cancel_gl_date,
                          'WP',xdrh.gl_date)  gl_date
-- Ver1.6 MOD End
            INTO   ld_gl_date
            FROM   xxcok_deduction_recon_head  xdrh
            WHERE  xdrh.recon_slip_num   = lt_csv_deduction_tab( i ).recon_slip_num;
          EXCEPTION
            WHEN  NO_DATA_FOUND THEN
              ld_gl_date := null;
          END;
--          ld_gl_date := gd_gl_date;
-- 2022/09/06 Ver1.5 MOD End
        END IF;
      ELSIF (lt_csv_deduction_tab( i ).source_category = cv_source_category_o ) THEN
        ld_gl_date := null;
      END IF;
-- 2021/08/04 Ver1.3 Add End
--
    -----------------------------------------------
    -- A-4.�̔��T�����i���n�j�o�͏���
    -----------------------------------------------
      -- �t�@�C���o��
      lv_step := 'A-4.1b';
        lv_out_csv_line := '';
        -- ��ЃR�[�h
        lv_step := 'A-4.company_code';
        lv_out_csv_line := lv_out_csv_line  ||
                           cv_dqu ||
                           cv_company_code ||
                           cv_dqu;
        --�̔��T��ID
        lv_step := 'A-4.sales_deduction_id';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_deduction_tab( i ).sales_deduction_id ;
        --���_�R�[�h
        lv_step := 'A-4.base_code_to';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_deduction_tab( i ).base_code_to ||
                           cv_dqu;
       --�ڋq�R�[�h
        lv_step := 'A-4.customer_code_to';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_deduction_tab( i ).customer_code_to ||
                           cv_dqu;
        --�T���p�`�F�[���R�[�h
        lv_step := 'A-4.deduction_chain_code';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_deduction_tab( i ).deduction_chain_code ||
                           cv_dqu;
        --��ƃR�[�h
        lv_step := 'A-4.corp_code';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_deduction_tab( i ).corp_code ||
                           cv_dqu;
-- 2021/08/04 Ver1.3 Add Start
        -- GL�L����
        lv_step := 'A-4.gl_date';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           TO_CHAR( ld_gl_date , cv_date_fmt_ymd );
-- 2021/08/04 Ver1.3 Add End
        --�v����yYYYYMMDD�z
        lv_step := 'A-4.record_date';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_deduction_tab( i ).record_date ;
        --�쐬���敪
        lv_step := 'A-4.source_category';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_deduction_tab( i ).source_category ||
                           cv_dqu;
        --�쐬������ID
        lv_step := 'A-4.source_line_id';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_deduction_tab( i ).source_line_id ;
        --�T������ID
        lv_step := 'A-4.condition_id';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_deduction_tab( i ).condition_id ;
        --�T���ԍ�
        lv_step := 'A-4.condition_no';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_deduction_tab( i ).condition_no ||
                           cv_dqu;
        --�T���ڍ�ID
        lv_step := 'A-4.condition_line_id';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_deduction_tab( i ).condition_line_id ;
        --�f�[�^���
        lv_step := 'A-4.data_type';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lv_data_type_name ||
                           cv_dqu;
        --�T�����
        lv_step := 'A-4.status';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_deduction_tab( i ).data_type ||
                           cv_dqu;
        --����敪
        lv_step := 'A-4.sales_class';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lv_sales_class ||
                           cv_dqu;
        --�[�i�`�ԋ敪
        lv_step := 'A-4.delivery_pattern_class';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lv_delivery_pattern_class ||
                           cv_dqu;
        --�ϓ��Ή��敪
        lv_step := 'A-4.fluctuation_value_class';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lv_fluctuation_value_class ||
                           cv_dqu;
        --�X�e�[�^�X
        lv_step := 'A-4.status';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_deduction_tab( i ).status ||
                           cv_dqu;
        --�i�ڃR�[�h
        lv_step := 'A-4.item_code';
        IF (lt_csv_deduction_tab( i ).item_code is NULL ) THEN
          IF (lt_csv_deduction_tab( i ).source_category = cv_source_category_f) THEN
            lv_item_code := gv_item_code_dummy_f;
          ELSIF (lt_csv_deduction_tab( i ).source_category = cv_source_category_u) THEN
            lv_item_code := gv_item_code_dummy_u;
          ELSIF (lt_csv_deduction_tab( i ).source_category = cv_source_category_o) THEN
            lv_item_code := gv_item_code_dummy_o;
-- 2021/04/23 MOD Start
          ELSE
            IF(substrb(lt_csv_deduction_tab( i ).condition_no,5,2) = 'UP') THEN
              lv_item_code := gv_item_code_dummy_u;
            ELSE
              lv_item_code := gv_item_code_dummy_f;
            END IF;  
-- 2021/04/23 MOD End
          END IF;
        ELSE
          lv_item_code := lt_csv_deduction_tab( i ).item_code;
        END IF;
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lv_item_code ||
                           cv_dqu;
        --�̔��P��
        lv_step := 'A-4.sales_uom_code';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_deduction_tab( i ).sales_uom_code ||
                           cv_dqu;
        --�̔��P��
        lv_step := 'A-4.sales_unit_price';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_deduction_tab( i ).sales_unit_price ;
        --�̔�����
        lv_step := 'A-4.sales_quantity';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_deduction_tab( i ).sales_quantity ;
        --����{�̋��z
        lv_step := 'A-4.sale_pure_amount';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_deduction_tab( i ).sale_pure_amount ;
        --�������Ŋz
        lv_step := 'A-4.sale_tax_amount';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_deduction_tab( i ).sale_tax_amount ;
        --�T���P��
        lv_step := 'A-4.deduction_uom_code';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_deduction_tab( i ).deduction_uom_code ||
                           cv_dqu;
        --�T���P��
        lv_step := 'A-4.deduction_unit_price';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_deduction_tab( i ).deduction_unit_price ;
        --�T������
        lv_step := 'A-4.deduction_quantity';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_deduction_tab( i ).deduction_quantity ;
        --�T���z
        lv_step := 'A-4.deduction_amount';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_deduction_tab( i ).deduction_amount ;
        --��U
        lv_step := 'A-4.compensation';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_deduction_tab( i ).compensation ;
        --�≮�}�[�W��
        lv_step := 'A-4.margin';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_deduction_tab( i ).margin ;
        --�g��
        lv_step := 'A-4.sales_promotion_expenses';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_deduction_tab( i ).sales_promotion_expenses ;
        --�≮�}�[�W�����z
        lv_step := 'A-4.margin_reduction';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_deduction_tab( i ).margin_reduction ;
        --�ŃR�[�h
        lv_step := 'A-4.tax_code';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_deduction_tab( i ).tax_code ||
                           cv_dqu;
        --�ŗ�
        lv_step := 'A-4.tax_rate';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_deduction_tab( i ).tax_rate ;
        --�������ŃR�[�h
        lv_step := 'A-4.recon_tax_code';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_deduction_tab( i ).recon_tax_code ||
                           cv_dqu;
        --�������ŗ�
        lv_step := 'A-4.recon_tax_rate';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_deduction_tab( i ).recon_tax_rate ;
        --�T���Ŋz
        lv_step := 'A-4.deduction_tax_amount';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_deduction_tab( i ).deduction_tax_amount ;
        --�\����No.
        lv_step := 'A-4.application_no';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_deduction_tab( i ).application_no ||
                           cv_dqu;
        --����m��t���O
        lv_step := 'A-4.report_decision_flag';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_deduction_tab( i ).report_decision_flag ||
                           cv_dqu;
        --���J�o���f�[�^�폜�����t�yYYYYMMDD�z
        lv_step := 'A-4.recovery_del_date';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_deduction_tab( i ).recovery_del_date ;
        --�쐬��
        lv_step := 'A-4.create_user_name';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_deduction_tab( i ).create_user_name ||
                           cv_dqu;
        --�쐬���yYYYYMMDD�z
        lv_step := 'A-4.creation_date';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_deduction_tab( i ).creation_date ;
        -- �ŏI�X�V��
        lv_step := 'A-4.last_updated_user_name';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_deduction_tab( i ).last_updated_user_name ||
                           cv_dqu;
        --�ŏI�X�V���yYYYYMMDD�z
        lv_step := 'A-4.last_update_date';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_deduction_tab( i ).last_update_date;
        -- �A�g�����yYYYYMMDDHH24MISS�z
        lv_step := 'A-4.gv_trans_date';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           gv_trans_date;
--
        --=================
        -- CSV�t�@�C���o��
        --=================
        lv_step := 'A-4.1c';
        BEGIN
          UTL_FILE.PUT_LINE( lf_file_hand, lv_out_csv_line );
        EXCEPTION
          WHEN OTHERS THEN
            lv_sqlerrm := SQLERRM;
            RAISE file_output_expt;
        END;
--
        -- ��������
        gn_normal_cnt := gn_normal_cnt + 1;
        --
      END LOOP out_csv_loop;
-- 2022/07/21 ADD Start
     lt_csv_deduction_tab.DELETE;
    EXIT WHEN csv_deduction_cur%notfound;
    END LOOP;
    CLOSE csv_deduction_cur;
-- 2022/07/21 ADD End
--
      -- ============================================================
      -- �̔��T���Ǘ����X�V�̌Ăяo��
      -- ============================================================
      upd_control_p(
        ov_errbuf   =>  lv_errbuf                             -- �G���[�E���b�Z�[�W
      , ov_retcode  =>  lv_retcode                            -- ���^�[���E�R�[�h
      , ov_errmsg   =>  lv_errmsg                             -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      IF  lv_retcode  = cv_status_error THEN
        RAISE global_process_expt;
      END IF;
--
      COMMIT;
--
      -----------------------------------------------
      -- A-6.�I������
      -----------------------------------------------
      -- �t�@�C���N���[�Y
      lv_step := 'A-6.1';
--
      --�t�@�C���N���[�Y���s
      BEGIN
        UTL_FILE.FCLOSE( lf_file_hand );
      EXCEPTION
        WHEN OTHERS THEN
          lv_sqlerrm := SQLERRM;
          RAISE file_close_expt;
      END;
--
--
  EXCEPTION
    -- *** �C�ӂŗ�O�������L�q���� ****
    -- *** �T�u�v���O������O�n���h�� ****
    WHEN subproc_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_error;
    --*** �t�@�C���I�[�v���G���[ ***
    WHEN file_open_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcok             -- �A�v���P�[�V�����Z�k���FXXCMM �}�X�^
                     ,iv_name         => cv_msg_xxcok_10787             -- ���b�Z�[�W�FAPP-XXCOK1-10787 �t�@�C���I�[�v���G���[
                     ,iv_token_name1  => cv_tkn_sqlerrm                 -- �g�[�N���FSQLERRM
                     ,iv_token_value1 => lv_sqlerrm                     -- �l�FSQLERRM
                     );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg;
      ov_retcode := cv_status_error;
    --*** �t�@�C���������݃G���[ ***
    WHEN file_output_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcok             -- �A�v���P�[�V�����Z�k���FXXCMM �}�X�^
                     ,iv_name         => cv_msg_xxcok_10788             -- ���b�Z�[�W�FAPP-XXCOK1-10788 �t�@�C���I�[�v���G���[
                     ,iv_token_name1  => cv_tkn_sqlerrm                 -- �g�[�N���FSQLERRM
                     ,iv_token_value1 => lv_sqlerrm                     -- �l�FSQLERRM
                     );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg;
      ov_retcode := cv_status_error;
    --*** �t�@�C���N���[�Y�G���[ ***
    WHEN file_close_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcok             -- �A�v���P�[�V�����Z�k���FXXCMM �}�X�^
                     ,iv_name         => cv_msg_xxcok_10789             -- ���b�Z�[�W�FAPP-XXCOK1-10789 �t�@�C���N���[�Y�G���[
                     ,iv_token_name1  => cv_tkn_sqlerrm                 -- �g�[�N���FSQLERRM
                     ,iv_token_value1 => lv_sqlerrm                     -- �l�FSQLERRM
                     );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg;
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �G���[�����o��
      gn_error_cnt := gn_target_cnt;
      ov_errbuf    := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      ov_retcode   := cv_status_error;
--
--####################################  �Œ蕔 END   ###################s#######################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
  --
  PROCEDURE main(
    errbuf         OUT    VARCHAR2         --   �G���[���b�Z�[�W #�Œ�#
   ,retcode        OUT    VARCHAR2         --   �G���[�R�[�h     #�Œ�#
  )
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name               CONSTANT VARCHAR2(100) := 'main';               -- �v���O������
    cv_log                    CONSTANT VARCHAR2(100) := 'LOG';                -- ���O
    cv_output                 CONSTANT VARCHAR2(100) := 'OUTPUT';             -- �A�E�g�v�b�g
    cv_app_name_xxccp         CONSTANT VARCHAR2(100) := 'XXCCP';              -- �A�v���P�[�V�����Z�k��
    cv_target_cnt_msg         CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000';   -- �Ώی������b�Z�[�W
    cv_success_cnt_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001';   -- �����������b�Z�[�W
    cv_error_cnt_msg          CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002';   -- �G���[�������b�Z�[�W
    cv_normal_msg             CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004';   -- ����I�����b�Z�[�W
    cv_warn_msg               CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005';   -- �x���I�����b�Z�[�W
    cv_error_msg              CONSTANT VARCHAR2(100) := 'APP-XXCCP1-10008';   -- �G���[�I�����b�Z�[�W
    cv_token_name1            CONSTANT VARCHAR2(100) := 'COUNT';              -- ��������
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf                 VARCHAR2(5000);                                 -- �G���[�E���b�Z�[�W
    lv_retcode                VARCHAR2(1);                                    -- ���^�[���E�R�[�h
    lv_errmsg                 VARCHAR2(5000);                                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_step                   VARCHAR2(10);                                   -- �X�e�b�v
    lv_message_code           VARCHAR2(100);                                  -- ���b�Z�[�W�R�[�h
--
--
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_log
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_output
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       ov_errbuf      => lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode     => lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg      => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      --�G���[�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�G���[���b�Z�[�W
      );
--
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
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => cv_target_cnt_msg
                    ,iv_token_name1  => cv_token_name1
                    ,iv_token_value1 => TO_CHAR( gn_target_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => cv_success_cnt_msg
                    ,iv_token_name1  => cv_token_name1
                    ,iv_token_value1 => TO_CHAR( gn_normal_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => cv_error_cnt_msg
                    ,iv_token_name1  => cv_token_name1
                    ,iv_token_value1 => TO_CHAR( gn_error_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --�I�����b�Z�[�W
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF( lv_retcode = cv_status_error ) THEN
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
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCOK024A37C;
/
