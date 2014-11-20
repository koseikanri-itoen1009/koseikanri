CREATE OR REPLACE PACKAGE BODY XXCMM005A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM005A02C(spec)
 * Description      : �g�D�}�X�^IF�o�́i���n�j
 * MD.050           : �g�D�}�X�^IF�o�́i���n�j CMM_005_A02
 * Version          : 1.4
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  init_proc            ��������(A-1)
 *
 *  create_aff_date_proc ���擾�v���V�[�W��(A-4)
 *
 *  output_aff_date_proc ��񏑂����݃v���V�[�W��(A-5)
 *
 *  fin_proc             �I�������v���V�[�W��(A-6)
 *
 *  submain              ���C�������v���V�[�W��(A-1�`A-5)
 *                          �E��������(A-1)�Ăяo��
 *                          �E�t�@�C���I�[�v������(A-2)���s
 *                          �E�ŏ�ʕ��匏���擾���f����(A-3)���s
 *                          �E���擾�v���V�[�W��(A-4)�Ăяo��
 *                          �E��񏑂����݃v���V�[�W��(A-5)�Ăяo��
 *
 *  main                 �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                          �Esubmain(A-1�`A-5)�Ăяo��
 *                          �E�I�������v���V�[�W��(A-6)�Ăяo��
 *                          �EROLLBACK�̎��s���f�{���s
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/28    1.0  T.Matsumoto       main�V�K�쐬
 *  2009/03/09    1.1  Takuya Kaihara    �v���t�@�C���l���ʉ�
 *  2009/04/20    1.2  Yutaka.Kuboshima  ��QT1_0590�̑Ή�
 *  2009/05/15    1.3  Yutaka.Kuboshima  ��QT1_1026�̑Ή�
 *  2009/10/06    1.4  Shigeto.Niki      I_E_542�AE_T3_00469�Ή�
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; -- ����:0
  cv_status_warn              CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   -- �x��:1
  cv_status_error             CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  -- �ُ�:2
  --WHO�J����
  cn_created_by               CONSTANT NUMBER      := fnd_global.user_id;                 -- CREATED_BY
  cd_creation_date            CONSTANT DATE        := SYSDATE;                            -- CREATION_DATE
  cn_last_updated_by          CONSTANT NUMBER      := fnd_global.user_id;                 -- LAST_UPDATED_BY
  cd_last_update_date         CONSTANT DATE        := SYSDATE;                            -- LAST_UPDATE_DATE
  cn_last_update_login        CONSTANT NUMBER      := fnd_global.login_id;                -- LAST_UPDATE_LOGIN
  cn_request_id               CONSTANT NUMBER      := fnd_global.conc_request_id;         -- REQUEST_ID
  cn_program_application_id   CONSTANT NUMBER      := fnd_global.prog_appl_id;            -- PROGRAM_APPLICATION_ID
  cn_program_id               CONSTANT NUMBER      := fnd_global.conc_program_id;         -- PROGRAM_ID
  cd_program_update_date      CONSTANT DATE        := SYSDATE;                            -- PROGRAM_UPDATE_DATE
  cv_msg_part                 CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont                 CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg                  VARCHAR2(2000);
  gv_sep_msg                  VARCHAR2(2000);
  gv_exec_user                VARCHAR2(100);
  gv_conc_name                VARCHAR2(30);
  gv_conc_status              VARCHAR2(30);
  gn_target_cnt               NUMBER;                                                     -- �Ώی���
  gn_normal_cnt               NUMBER;                                                     -- ���팏��
  gn_error_cnt                NUMBER;                                                     -- �G���[����
  gn_warn_cnt                 NUMBER;                                                     -- �X�L�b�v����
--
--################################  �Œ蕔 END   ##################################
--
--##########################  �Œ苤�ʗ�O�錾�� START  ###########################
--
  --*** ���������ʗ�O ***
  global_process_expt         EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt             EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt      EXCEPTION;
  global_check_lock_expt      EXCEPTION;                                                  -- ���b�N�擾�G���[
--
  PRAGMA EXCEPTION_INIT( global_check_lock_expt, -54);
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                 CONSTANT VARCHAR2(30)  := 'XXCMM005A02C';                   -- �p�b�P�[�W��
--
  cv_app_name_xxcmm           CONSTANT VARCHAR2(30)  := 'XXCMM';                          -- APPL�Z�k���F�}�X�^
  cv_app_name_xxccp           CONSTANT VARCHAR2(30)  := 'XXCCP';                          -- APPL�Z�k���F���ʁEIF
  -- ���b�Z�[�W
  cv_emsg_nodata              CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-00001';               -- �Ώۃf�[�^�����G���[
  cv_emsg_plofaile_get        CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-00002';               -- �v���t�@�C���擾�G���[
  cv_emsg_output              CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-00009';               -- �t�@�C���������݃G���[
  cv_emsg_file_exists         CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-00010';               -- CSV�t�@�C�����݃G���[
  cv_emsg_file_open           CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-00487';               -- �t�@�C���I�[�v���G���[
  cv_emsg_file_close          CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-00489';               -- �t�@�C���N���[�Y�G���[
-- 2009/05/15 Ver1.3 delete start by Yutaka.Kuboshima
--  cv_emsg_uppersec_cnt        CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-00500';               -- �ŏ�ʕ��啡�����G���[
-- 2009/05/15 Ver1.3 delete end by Yutaka.Kuboshima
  cv_imsg_all_count           CONSTANT VARCHAR2(30)  := 'APP-XXCCP1-90000';               -- ���������
  cv_imsg_suc_count           CONSTANT VARCHAR2(30)  := 'APP-XXCCP1-90001';               -- �����������
  cv_imsg_err_count           CONSTANT VARCHAR2(30)  := 'APP-XXCCP1-90002';               -- �G���[�������
  cv_imsg_normal_end          CONSTANT VARCHAR2(30)  := 'APP-XXCCP1-90004';               -- ����I�����b�Z�[�W
  cv_imsg_warn_end            CONSTANT VARCHAR2(30)  := 'APP-XXCCP1-90005';               -- �x���I�����b�Z�[�W
  cv_imsg_error_end           CONSTANT VARCHAR2(30)  := 'APP-XXCCP1-90006';               -- �ُ�I�����b�Z�[�W
  -- �g�[�N��
  cv_tkn_sqlerrm              CONSTANT VARCHAR2(20)  := 'SQLERRM';                        -- �g�[�N���FSQL�G���[
  cv_tkn_ng_profile           CONSTANT VARCHAR2(20)  := 'NG_PROFILE';                     -- �g�[�N���F�v���t�@�C����
  cv_tkn_ffvset_name          CONSTANT VARCHAR2(20)  := 'FFV_SET_NAME';                   -- �g�[�N���F�l�Z�b�g��
  cv_tkn_ng_word              CONSTANT VARCHAR2(20)  := 'NG_WORD';                        -- �g�[�N���F���ږ�
  cv_tkn_nd_data              CONSTANT VARCHAR2(20)  := 'NG_DATA';                        -- �g�[�N���F�Ώۂ̍��ڒl
  cv_tkn_count                CONSTANT VARCHAR2(20)  := 'COUNT';                          -- �g�[�N���F�J�E���g
  -- �g�[�N���l
  cv_tknv_csv_fl_dir          CONSTANT VARCHAR2(100) := 'XXCMM:���n(OUTBOUND)�A�g�pCSV�t�@�C���o�͐�';
  cv_tknv_csv_fl_name         CONSTANT VARCHAR2(100) := '�g�D�}�X�^�i���n�j�A�g�pCSV�t�@�C����';
  cv_tknv_base_code           CONSTANT VARCHAR2(100) := '���_�R�[�h'; 
-- 2009/04/20 Ver1.2 add start by Yutaka.Kuboshima
  cv_tknv_dummy_dept_code     CONSTANT VARCHAR2(100) := 'AFF�_�~�[����R�[�h'; 
-- 2009/04/20 Ver1.2 add end by Yutaka.Kuboshima
  -- �J�X�^���E�v���t�@�C�����F�g�D�}�X�^(���n)
  cv_csv_fl_dir               CONSTANT VARCHAR2(50)  := 'XXCMM1_JYOHO_OUT_DIR';           -- �A�g�pCSV�t�@�C���o�͐�
  cv_csv_fl_name              CONSTANT VARCHAR2(50)  := 'XXCMM1_005A02_OUT_FILE_FIL';     -- �A�g�pCSV�t�@�C������
-- 2009/04/20 Ver1.2 add start by Yutaka.Kuboshima
  cv_aff_dept_dummy_cd        CONSTANT VARCHAR2(50)  := 'XXCMM1_AFF_DEPT_DUMMY_CD';       -- AFF�_�~�[����R�[�h
-- 2009/04/20 Ver1.2 add end by Yutaka.Kuboshima
  -- �l�Z�b�g��
  cv_dept_valset_name         CONSTANT VARCHAR2(50)  := 'XX03_DEPARTMENT';                -- ����
  -- ���̑�
  cv_flag_yes                 CONSTANT VARCHAR2(1)   := 'Y';                              -- �t���O�FY
  cv_csv_mode_w               CONSTANT VARCHAR2(1)   := 'w';                              -- Fopen�F�㏑�����[�h
  cv_dqu                      CONSTANT VARCHAR2(1)   := '"';                              -- �_�u���N�H�[�e�[�V����
  cv_sep                      CONSTANT VARCHAR2(1)   := ',';                              -- �J���}
-- 2009/04/20 Ver1.2 add start by Yutaka.Kuboshima
  cv_flag_parent              CONSTANT VARCHAR2(1)   := 'P';                              -- �t���O�FP(�e)
-- 2009/04/20 Ver1.2 add end by Yutaka.Kuboshima
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �g�D�}�X�^IF�o�́i���n�j���C�A�E�g
  TYPE xxcmm005a02c_rtype IS RECORD
  (
     base_code                fnd_flex_values.flex_value%TYPE                             -- ���_�R�[�h
    ,base_name                fnd_flex_values.attribute4%TYPE                             -- ���_����
    ,base_abbrev              fnd_flex_values.attribute5%TYPE                             -- ���_����
    ,base_order               fnd_flex_values.attribute6%TYPE                             -- ���_���я�
-- 2009/10/06 Ver1.4 add start by Shigeto.Niki
--    ,dpt6_start_date_active   fnd_flex_values.attribute6%TYPE                             -- �U�K�w�ړK�p�J�n��
    ,dpt6_start_date_active   VARCHAR2(8)
    ,dpt6_old_cd              fnd_flex_values.attribute7%TYPE                             -- �U�K�w�ڋ��{���R�[�h
    ,dpt6_new_cd              fnd_flex_values.attribute9%TYPE                             -- �U�K�w�ڐV�{���R�[�h    
-- 2009/10/06 Ver1.4 add end by Shigeto.Niki    
    ,section_div              fnd_flex_values.attribute8%TYPE                             -- ����敪
    ,district_code            fnd_flex_values.flex_value%TYPE                             -- �n��R�[�h
    ,district_name            fnd_flex_values.attribute4%TYPE                             -- �n�於
    ,district_abbrev          fnd_flex_values.attribute5%TYPE                             -- �n�旪��
    ,district_order           fnd_flex_values.attribute6%TYPE                             -- �n����я�
-- 2009/10/06 Ver1.4 add start by Shigeto.Niki
    ,dpt5_start_date_active   fnd_flex_values.attribute6%TYPE                             -- �T�K�w�ړK�p�J�n��
    ,dpt5_old_cd              fnd_flex_values.attribute7%TYPE                             -- �T�K�w�ڋ��{���R�[�h
    ,dpt5_new_cd              fnd_flex_values.attribute9%TYPE                             -- �T�K�w�ڐV�{���R�[�h    
-- 2009/10/06 Ver1.4 add end by Shigeto.Niki
    ,area_code                fnd_flex_values.flex_value%TYPE                             -- �G���A�R�[�h
    ,area_name                fnd_flex_values.attribute4%TYPE                             -- �G���A��
    ,area_abbrev              fnd_flex_values.attribute5%TYPE                             -- �G���A����
    ,area_order               fnd_flex_values.attribute6%TYPE                             -- �G���A���я�
-- 2009/10/06 Ver1.4 add start by Shigeto.Niki
    ,dpt4_start_date_active   fnd_flex_values.attribute6%TYPE                             -- �S�K�w�ړK�p�J�n��
    ,dpt4_old_cd              fnd_flex_values.attribute7%TYPE                             -- �S�K�w�ڋ��{���R�[�h
    ,dpt4_new_cd              fnd_flex_values.attribute9%TYPE                             -- �S�K�w�ڐV�{���R�[�h
-- 2009/10/06 Ver1.4 add end by Shigeto.Niki
    ,head_code                fnd_flex_values.flex_value%TYPE                             -- �{���R�[�h
    ,head_name                fnd_flex_values.attribute4%TYPE                             -- �{����
    ,head_abbrev              fnd_flex_values.attribute5%TYPE                             -- �{������
    ,head_order               fnd_flex_values.attribute6%TYPE                             -- �{�����я�
-- 2009/10/06 Ver1.4 add start by Shigeto.Niki
    ,dpt3_start_date_active   fnd_flex_values.attribute6%TYPE                             -- �R�K�w�ړK�p�J�n��
    ,dpt3_old_cd              fnd_flex_values.attribute7%TYPE                             -- �R�K�w�ڋ��{���R�[�h
    ,dpt3_new_cd              fnd_flex_values.attribute9%TYPE                             -- �R�K�w�ڐV�{���R�[�h
-- 2009/10/06 Ver1.4 add end by Shigeto.Niki
    ,foundation_code          fnd_flex_values.flex_value%TYPE                             -- ��{��
    ,foundation_name          fnd_flex_values.attribute4%TYPE                             -- ��{����
    ,foundation_abbrev        fnd_flex_values.attribute5%TYPE                             -- ��{������
    ,foundation_order         fnd_flex_values.attribute6%TYPE                             -- ��{�����я�
-- 2009/10/06 Ver1.4 add start by Shigeto.Niki
    ,dpt2_start_date_active   fnd_flex_values.attribute6%TYPE                             -- �Q�K�w�ړK�p�J�n��
    ,dpt2_old_cd              fnd_flex_values.attribute7%TYPE                             -- �Q�K�w�ڋ��{���R�[�h
    ,dpt2_new_cd              fnd_flex_values.attribute9%TYPE                             -- �Q�K�w�ڐV�{���R�[�h
-- 2009/10/06 Ver1.4 add end by Shigeto.Niki
    ,co_code                  fnd_flex_values.flex_value%TYPE                             -- �{�Ќv
    ,co_name                  fnd_flex_values.attribute4%TYPE                             -- �{�Ќv��
    ,co_abbrev                fnd_flex_values.attribute5%TYPE                             -- �{�Ќv����
    ,co_order                 fnd_flex_values.attribute6%TYPE                             -- �{�Ќv���я�
-- 2009/10/06 Ver1.4 add start by Shigeto.Niki
    ,dpt1_start_date_active   fnd_flex_values.attribute6%TYPE                             -- �P�K�w�ړK�p�J�n��
    ,dpt1_old_cd              fnd_flex_values.attribute7%TYPE                             -- �P�K�w�ڋ��{���R�[�h
    ,dpt1_new_cd              fnd_flex_values.attribute9%TYPE                             -- �P+�K�w�ڐV�{���R�[�h
-- 2009/10/06 Ver1.4 add end by Shigeto.Niki
    ,enabled_flag             fnd_flex_values.enabled_flag%TYPE                           -- �g�p�\�t���O
    ,start_date_active        fnd_flex_values.start_date_active%TYPE                      -- �L�����ԊJ�n��
    ,end_date_active          fnd_flex_values.end_date_active%TYPE                        -- �L�����ԏI����
    );
--
  -- �g�D�}�X�^IF�o�́i���n�j���C�A�E�g �e�[�u���^�C�v
  TYPE xxcmm005a02c_ttype IS TABLE OF xxcmm005a02c_rtype INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- �J�X�^���E�v���t�@�C���l�F�擾�p
  gt_out_file_dir             fnd_profile_option_values.profile_option_value%TYPE;        -- �A�g�pCSV�t�@�C���o�͐�
  gt_out_file_name            fnd_profile_option_values.profile_option_value%TYPE;        -- �A�g�pCSV�t�@�C������
-- 2009/04/20 Ver1.2 add start by Yutaka.Kuboshima
  gv_aff_dept_dummy_cd        fnd_profile_option_values.profile_option_value%TYPE;        -- AFF�_�~�[����R�[�h
-- 2009/04/20 Ver1.2 add end by Yutaka.Kuboshima
-- 2009/10/06 Ver1.4 add start by Shigeto.Niki
  gv_process_date              VARCHAR2(8);                                               -- �Ɩ����t(YYYYMMDD)
-- 2009/10/06 Ver1.4 add end by Shigeto.Niki
--
  gf_file_hand                UTL_FILE.FILE_TYPE;                                         -- CSV�t�@�C���o�͗p�n���h��
  g_csv_organ_tab             xxcmm005a02c_ttype;                                         -- �g�DIF�o�̓f�[�^
--
  /**********************************************************************************
   * Procedure Name   : init_proc
   * Description      : ���������v���V�[�W��(A-1)
   ***********************************************************************************/
  PROCEDURE init_proc(
    ov_errbuf         OUT     VARCHAR2,                                                   -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT     VARCHAR2,                                                   -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT     VARCHAR2)                                                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name               CONSTANT VARCHAR2(100) := 'init_proc';                      -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf                 VARCHAR2(5000);                                             -- �G���[�E���b�Z�[�W
    lv_retcode                VARCHAR2(1);                                                -- ���^�[���E�R�[�h
    lv_errmsg                 VARCHAR2(5000);                                             -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_step                   VARCHAR2(100);                                              -- �X�e�b�v
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_message_token          VARCHAR2(100);                                              -- �σ��b�Z�[�W�g�[�N��
    lb_file_exists            BOOLEAN;                                                    -- �t�@�C�����ݔ��f
    ln_file_length            NUMBER(30);                                                 -- �t�@�C���̕�����
    lbi_block_size            BINARY_INTEGER;                                             -- �u���b�N�T�C�Y
    --
    -- *** ���[�U�[��`��O ***
    profile_expt              EXCEPTION;                                                  -- �v���t�@�C���擾��O
    csv_file_exst_expt        EXCEPTION;                                                  -- �t�@�C���d���G���[  
--
  BEGIN
    -- �ϐ�������
    lv_step := 'A-1.0';
    lv_errbuf           := NULL;
    lv_retcode          := NULL;
    lv_errmsg           := NULL;
    gt_out_file_dir     := NULL;
    gt_out_file_name    := NULL;
    lv_message_token    := NULL;
    g_csv_organ_tab.DELETE;
    --
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    -- �J�X�^���E�v���t�@�C���l�F�A�g�pCSV�t�@�C���o�͐�̎擾
    lv_step := 'A-1.1';
    lv_message_token    := cv_tknv_csv_fl_dir;
    gt_out_file_dir     := FND_PROFILE.VALUE(cv_csv_fl_dir);
    -- �A�g�pCSV�t�@�C���o�͐�̎擾���e�`�F�b�N
    IF ( gt_out_file_dir IS NULL) THEN
      --
      RAISE profile_expt;
    END IF;
--
    -- �J�X�^���E�v���t�@�C���l�F�A�g�pCSV�t�@�C�����̂̎擾
    lv_step := 'A-1.2';
    lv_message_token    := cv_tknv_csv_fl_name;
    gt_out_file_name    := FND_PROFILE.VALUE(cv_csv_fl_name);
    -- �A�g�pCSV�t�@�C���o�͐�̎擾���e�`�F�b�N
    IF ( gt_out_file_name IS NULL) THEN
      --
      RAISE profile_expt;
    END IF;
--
-- 2009/04/20 Ver1.2 add start by Yutaka.Kuboshima
    -- �J�X�^���E�v���t�@�C���l�FAFF�_�~�[����R�[�h�̎擾
    lv_step := 'A-1.3';
    lv_message_token     := cv_tknv_dummy_dept_code;
    gv_aff_dept_dummy_cd := FND_PROFILE.VALUE(cv_aff_dept_dummy_cd);
    -- �A�g�pCSV�t�@�C���o�͐�̎擾���e�`�F�b�N
    IF ( gv_aff_dept_dummy_cd IS NULL) THEN
      --
      RAISE profile_expt;
    END IF;
-- 2009/04/20 Ver1.2 add end by Yutaka.Kuboshima
    -- CSV�t�@�C�����݃`�F�b�N
    lv_step := 'A-1.3';
    UTL_FILE.FGETATTR(
         location     => gt_out_file_dir
        ,filename     => gt_out_file_name
        ,fexists      => lb_file_exists
        ,file_length  => ln_file_length
        ,block_size   => lbi_block_size
      );
      -- �t�@�C���d���`�F�b�N(�t�@�C�����݂̗L��)
      IF ( lb_file_exists = TRUE ) THEN
        RAISE csv_file_exst_expt;
      END IF;

-- 2009/10/06 Ver1.4 add start by Shigeto.Niki
      -- �Ɩ����t��YYYYMMDD�`���Ŏ擾���܂�
      gv_process_date := TO_CHAR(xxccp_common_pkg2.get_process_date,'YYYYMMDD');
      --
-- 2009/10/06 Ver1.4 add end by Shigeto.Niki
--
  EXCEPTION
    --*** �v���t�@�C���擾�G���[ ***
    WHEN profile_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxcmm                                -- �}�X�^
                     ,iv_name         => cv_emsg_plofaile_get                             -- �v���t�@�C���擾�G���[
                     ,iv_token_name1  => cv_tkn_ng_profile                                -- NG_PROFILE
                     ,iv_token_value1 => lv_message_token                                 -- �v���t�@�C����
                     );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont ||
                    lv_step     || cv_msg_part || lv_errbuf;
      ov_retcode := cv_status_error;
    --*** CSV�t�@�C�����݃G���[ ***
    WHEN csv_file_exst_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxcmm                                -- �}�X�^
                     ,iv_name         => cv_emsg_file_exists                              -- CSV�t�@�C�����݃G���[
                     );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont ||
                    lv_step     || cv_msg_part || lv_errbuf;
      ov_retcode := cv_status_error;
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
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
  END init_proc;
--
--
  /**********************************************************************************
   * Procedure Name   : create_aff_date_proc
   * Description      : AFF����}�X�^���擾�v���V�[�W��(A-4)
   ***********************************************************************************/
  PROCEDURE create_aff_date_proc(
    ov_errbuf         OUT     VARCHAR2,                                                   -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT     VARCHAR2,                                                   -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT     VARCHAR2)                                                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name               CONSTANT VARCHAR2(100) := 'create_aff_date_proc';           -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf                 VARCHAR2(5000);                                             -- �G���[�E���b�Z�[�W
    lv_retcode                VARCHAR2(1);                                                -- ���^�[���E�R�[�h
    lv_errmsg                 VARCHAR2(5000);                                             -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_step                   VARCHAR2(100);                                              -- �X�e�b�v
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_loop_cnt               NUMBER := 0;                                                -- Loop���̃J�E���g�ϐ�
    lv_message_token          VARCHAR2(1000);                                             -- ���b�Z�[�W�p�ϐ�
    -- �g�D�}�X�^�i���n�j���J�[�\��
    CURSOR csv_organ_cur
    IS
      SELECT     xhdal.dpt6_cd                 AS base_code                                  -- ���_�R�[�h
                ,xhdal.dpt6_name               AS base_name                                  -- ���_����
                ,xhdal.dpt6_abbreviate         AS base_abbrev                                -- ���_����
-- 2009/10/06 Ver1.4 mod start by Shigeto.Niki
--                 ,xhdal.dpt6_sort_num           AS base_order                                 -- ���_���я�
                ,xhdal.dpt6_start_date_active  AS dpt6_start_date_active                     -- �U�K�w�ړK�p�J�n��
                ,xhdal.dpt6_old_cd             AS dpt6_old_cd                                -- �U�K�w�ڋ��{���R�[�h
                ,xhdal.dpt6_new_cd             AS dpt6_new_cd                                -- �U�K�w�ڐV�{���R�[�h
-- 2009/10/06 Ver1.4 mod end by Shigeto.Niki
                ,xhdal.dpt6_div                AS section_div                                -- ����敪
                ,xhdal.dpt5_cd                 AS district_code                              -- �n��R�[�h
                ,xhdal.dpt5_name               AS district_name                              -- �n�於
                ,xhdal.dpt5_abbreviate         AS district_abbrev                            -- �n�旪��
-- 2009/10/06 Ver1.4 mod start by Shigeto.Niki
--                 ,xhdal.dpt5_sort_num           AS district_order                             -- �n����я�
                ,xhdal.dpt5_start_date_active  AS dpt5_start_date_active                     -- �T�K�w�ړK�p�J�n��
                ,xhdal.dpt5_old_cd             AS dpt5_old_cd                                -- �T�K�w�ڋ��{���R�[�h
                ,xhdal.dpt5_new_cd             AS dpt5_new_cd                                -- �T�K�w�ڐV�{���R�[�h
-- 2009/10/06 Ver1.4 mod end by Shigeto.Niki
                ,xhdal.dpt4_cd                 AS area_code                                  -- �G���A�R�[�h
                ,xhdal.dpt4_name               AS area_name                                  -- �G���A��
                ,xhdal.dpt4_abbreviate         AS area_abbrev                                -- �G���A����
-- 2009/10/06 Ver1.4 mod start by Shigeto.Niki
--                 ,xhdal.dpt4_sort_num           AS area_order                                 -- �G���A���я�
                ,xhdal.dpt4_start_date_active  AS dpt4_start_date_active                     -- �S�K�w�ړK�p�J�n��
                ,xhdal.dpt4_old_cd             AS dpt4_old_cd                                -- �S�K�w�ڋ��{���R�[�h
                ,xhdal.dpt4_new_cd             AS dpt4_new_cd                                -- �S�K�w�ڐV�{���R�[�h
-- 2009/10/06 Ver1.4 mod end by Shigeto.Niki
                ,xhdal.dpt3_cd                 AS head_code                                  -- �{���R�[�h
                ,xhdal.dpt3_name               AS head_name                                  -- �{����
                ,xhdal.dpt3_abbreviate         AS head_abbrev                                -- �{������
-- 2009/10/06 Ver1.4 mod start by Shigeto.Niki
--                 ,xhdal.dpt3_sort_num           AS head_order                                 -- �{�����я�
                ,xhdal.dpt3_start_date_active  AS dpt3_start_date_active                     -- �R�K�w�ړK�p�J�n��
                ,xhdal.dpt3_old_cd             AS dpt3_old_cd                                -- �R�K�w�ڋ��{���R�[�h
                ,xhdal.dpt3_new_cd             AS dpt3_new_cd                                -- �R�K�w�ڐV�{���R�[�h
-- 2009/10/06 Ver1.4 mod end by Shigeto.Niki
                ,xhdal.dpt2_cd                 AS foundation_code                            -- ��{��
                ,xhdal.dpt2_name               AS foundation_name                            -- ��{����
                ,xhdal.dpt2_abbreviate         AS foundation_abbrev                          -- ��{������
-- 2009/10/06 Ver1.4 mod start by Shigeto.Niki
--                 ,xhdal.dpt2_sort_num           AS foundation_order                           -- ��{�����я�
                ,xhdal.dpt2_start_date_active  AS dpt2_start_date_active                     -- �Q�K�w�ړK�p�J�n��
                ,xhdal.dpt2_old_cd             AS dpt2_old_cd                                -- �Q�K�w�ڋ��{���R�[�h
                ,xhdal.dpt2_new_cd             AS dpt2_new_cd                                -- �Q�K�w�ڐV�{���R�[�h
-- 2009/10/06 Ver1.4 mod end by Shigeto.Niki
                ,xhdal.dpt1_cd                 AS co_code                                    -- �{�Ќv
                ,xhdal.dpt1_name               AS co_name                                    -- �{�Ќv��
                ,xhdal.dpt1_abbreviate         AS co_abbrev                                  -- �{�Ќv����
-- 2009/10/06 Ver1.4 mod start by Shigeto.Niki
--                 ,xhdal.dpt1_sort_num           AS co_order                                   -- �{�Ќv���я�
                ,xhdal.dpt1_start_date_active  AS dpt1_start_date_active                     -- �P�K�w�ړK�p�J�n��
                ,xhdal.dpt1_old_cd             AS dpt1_old_cd                                -- �P�K�w�ڋ��{���R�[�h
                ,xhdal.dpt1_new_cd             AS dpt1_new_cd                                -- �P�K�w�ڐV�{���R�[�h
-- 2009/10/06 Ver1.4 mod end by Shigeto.Niki
                ,DECODE(xhdal.enabled_flag,'N','0','Y','1',NULL)
                                               AS enabled_flag                               -- �g�p�\�t���O
                ,xhdal.start_date_active       AS start_date_active                          -- �L�����ԊJ�n��
                ,xhdal.end_date_active         AS end_date_active                            -- �L�����ԏI����
      FROM      xxcmm_hierarchy_dept_all_v     xhdal
-- 2009/10/06 Ver1.4 mod start by Shigeto.Niki
--       ORDER BY  xhdal.dpt1_cd ASC
      ORDER BY  xhdal.dpt6_cd ASC
-- 2009/10/06 Ver1.4 mod start by Shigeto.Niki
      ;
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    nodata_expt             EXCEPTION;                                                    -- �Ώۃf�[�^�����G���[
--
  BEGIN
    -- ===============================================
    -- A-4.0���[�J���ϐ�������
    -- ===============================================
    lv_step :='A-4.0';
    lv_errbuf   := NULL;
    lv_retcode  := NULL;
    lv_errmsg   := NULL;
    lv_message_token := NULL;
    --
    -- ===============================================
    -- A-4.xxxxx�\���̂ւ̒l�̓��͂��J�n
    -- ===============================================
    <<csv_organ_loop>>
    FOR l_csv_organ_rec IN csv_organ_cur LOOP
      -- LOOP�J�E���gUP
      lv_step :='A-4.1';
      ln_loop_cnt := ln_loop_cnt + 1 ;
      -- ===============================
      -- ���o���e�̍\���̂ւ̓���
      -- ===============================
      -- ���_�R�[�h
      lv_step :='A-4.base_code';
      lv_message_token :='���_�R�[�h';
      g_csv_organ_tab(ln_loop_cnt).base_code         := l_csv_organ_rec.base_code;
      -- ���_����
      lv_step :='A-4.base_name';
      lv_message_token :='���_����';
      g_csv_organ_tab(ln_loop_cnt).base_name         := l_csv_organ_rec.base_name;
      -- ���_����
      lv_step :='A-4.base_abbrev';
      lv_message_token :='���_����';
      g_csv_organ_tab(ln_loop_cnt).base_abbrev       := l_csv_organ_rec.base_abbrev;
-- 2009/10/06 Ver1.4 mod start by Shigeto.Niki
      -- ���_���я�
      lv_step :='A-4.base_order';
      lv_message_token :='���_���я�';
--       g_csv_organ_tab(ln_loop_cnt).base_order        := l_csv_organ_rec.base_order;
      -- �K�p�J�n�� <= �Ɩ����t�̏ꍇ�́A�V�{���R�[�h���Z�b�g
      IF (l_csv_organ_rec.dpt6_start_date_active IS NULL) THEN
        g_csv_organ_tab(ln_loop_cnt).base_order  := l_csv_organ_rec.dpt6_old_cd;
      ELSIF (l_csv_organ_rec.dpt6_start_date_active <= gv_process_date) THEN
        g_csv_organ_tab(ln_loop_cnt).base_order  := l_csv_organ_rec.dpt6_new_cd;
      ELSE
        g_csv_organ_tab(ln_loop_cnt).base_order  := l_csv_organ_rec.dpt6_old_cd;
      END IF;
-- 2009/10/06 Ver1.4 mod end by Shigeto.Niki
      -- ����敪
      lv_step :='A-4.section_div';
      lv_message_token :='����敪';
      g_csv_organ_tab(ln_loop_cnt).section_div       := l_csv_organ_rec.section_div;
      -- �n��R�[�h
      lv_step :='A-4.district_code';
      lv_message_token :='�n��R�[�h';
      g_csv_organ_tab(ln_loop_cnt).district_code     := l_csv_organ_rec.district_code;
      -- �n�於
      lv_step :='A-4.district_name';
      lv_message_token :='�n�於';
      g_csv_organ_tab(ln_loop_cnt).district_name     := l_csv_organ_rec.district_name;
      -- �n�旪��
      lv_step :='A-4.district_abbrev';
      lv_message_token :='�n�旪��';
      g_csv_organ_tab(ln_loop_cnt).district_abbrev   := l_csv_organ_rec.district_abbrev;
-- 2009/10/06 Ver1.4 mod start by Shigeto.Niki
      -- �n����я�
      lv_step :='A-4.district_order';
      lv_message_token :='�n����я�';
--      g_csv_organ_tab(ln_loop_cnt).district_order    := l_csv_organ_rec.district_order;
      -- �K�p�J�n�� <= �Ɩ����t�̏ꍇ�́A�V�{���R�[�h���Z�b�g
      IF (l_csv_organ_rec.dpt5_start_date_active IS NULL) THEN
        g_csv_organ_tab(ln_loop_cnt).district_order  := l_csv_organ_rec.dpt5_old_cd;
      ELSIF (l_csv_organ_rec.dpt5_start_date_active <= gv_process_date) THEN
        g_csv_organ_tab(ln_loop_cnt).district_order  := l_csv_organ_rec.dpt5_new_cd;
      ELSE
        g_csv_organ_tab(ln_loop_cnt).district_order  := l_csv_organ_rec.dpt5_old_cd;
      END IF;
-- 2009/10/06 Ver1.4 mod end by Shigeto.Niki
      -- �G���A�R�[�h
      lv_step :='A-4.area_code';
      lv_message_token :='�G���A�R�[�h';
      g_csv_organ_tab(ln_loop_cnt).area_code         := l_csv_organ_rec.area_code;
      -- �G���A��
      lv_step :='A-4.area_name';
      lv_message_token :='�G���A��';
      g_csv_organ_tab(ln_loop_cnt).area_name         := l_csv_organ_rec.area_name;
      -- �G���A����
      lv_step :='A-4.area_abbrev';
      lv_message_token :='�G���A����';
      g_csv_organ_tab(ln_loop_cnt).area_abbrev       := l_csv_organ_rec.area_abbrev;
-- 2009/10/06 Ver1.4 mod start by Shigeto.Niki
      -- �G���A���я�
      lv_step :='A-4.area_order';
      lv_message_token :='�G���A���я�';
--       g_csv_organ_tab(ln_loop_cnt).area_order        := l_csv_organ_rec.area_order;
      -- �K�p�J�n�� <= �Ɩ����t�̏ꍇ�́A�V�{���R�[�h���Z�b�g
      IF (l_csv_organ_rec.dpt4_start_date_active IS NULL) THEN
        g_csv_organ_tab(ln_loop_cnt).area_order      := l_csv_organ_rec.dpt4_old_cd;
      ELSIF (l_csv_organ_rec.dpt4_start_date_active <= gv_process_date) THEN
        g_csv_organ_tab(ln_loop_cnt).area_order      := l_csv_organ_rec.dpt4_new_cd;
      ELSE
        g_csv_organ_tab(ln_loop_cnt).area_order      := l_csv_organ_rec.dpt4_old_cd;
      END IF;
-- 2009/10/06 Ver1.4 mod end by Shigeto.Niki
      -- �{���R�[�h
      lv_step :='A-4.head_code';
      lv_message_token :='�{���R�[�h';
      g_csv_organ_tab(ln_loop_cnt).head_code         := l_csv_organ_rec.head_code;
      -- �{����
      lv_step :='A-4.head_name';
      lv_message_token :='�{����';
      g_csv_organ_tab(ln_loop_cnt).head_name         := l_csv_organ_rec.head_name;
      -- �{������
      lv_step :='A-4.head_abbrev';
      lv_message_token :='�{������';
      g_csv_organ_tab(ln_loop_cnt).head_abbrev       := l_csv_organ_rec.head_abbrev;
-- 2009/10/06 Ver1.4 mod start by Shigeto.Niki
      -- �{�����я�
      lv_step :='A-4.head_order';
      lv_message_token :='�{�����я�';
--       g_csv_organ_tab(ln_loop_cnt).head_order        := l_csv_organ_rec.head_order;
      -- �K�p�J�n�� <= �Ɩ����t�̏ꍇ�́A�V�{���R�[�h���Z�b�g
      IF (l_csv_organ_rec.dpt3_start_date_active IS NULL) THEN
        g_csv_organ_tab(ln_loop_cnt).head_order      := l_csv_organ_rec.dpt3_old_cd;
      ELSIF (l_csv_organ_rec.dpt3_start_date_active <= gv_process_date) THEN
        g_csv_organ_tab(ln_loop_cnt).head_order      := l_csv_organ_rec.dpt3_new_cd;
      ELSE
        g_csv_organ_tab(ln_loop_cnt).head_order      := l_csv_organ_rec.dpt3_old_cd;
      END IF;
-- 2009/10/06 Ver1.4 mod end by Shigeto.Niki
      -- ��{��
      lv_step :='A-4.foundation_code';
      lv_message_token :='��{��';
      g_csv_organ_tab(ln_loop_cnt).foundation_code   := l_csv_organ_rec.foundation_code;
      -- ��{����
      lv_step :='A-4.foundation_name';
      lv_message_token :='��{����';
      g_csv_organ_tab(ln_loop_cnt).foundation_name   := l_csv_organ_rec.foundation_name;
      -- ��{������
      lv_step :='A-4.foundation_abbrev';
      lv_message_token :='��{������';
      g_csv_organ_tab(ln_loop_cnt).foundation_abbrev := l_csv_organ_rec.foundation_abbrev;
-- 2009/10/06 Ver1.4 mod start by Shigeto.Niki
      -- ��{�����я�
      lv_step :='A-4.foundation_order';
      lv_message_token :='��{�����я�';
--       g_csv_organ_tab(ln_loop_cnt).foundation_order  := l_csv_organ_rec.foundation_order;
      -- �K�p�J�n�� <= �Ɩ����t�̏ꍇ�́A�V�{���R�[�h���Z�b�g
      IF (l_csv_organ_rec.dpt2_start_date_active IS NULL) THEN
        g_csv_organ_tab(ln_loop_cnt).foundation_order  := l_csv_organ_rec.dpt2_old_cd;
      ELSIF (l_csv_organ_rec.dpt2_start_date_active <= gv_process_date) THEN
        g_csv_organ_tab(ln_loop_cnt).foundation_order  := l_csv_organ_rec.dpt2_new_cd;
      ELSE
        g_csv_organ_tab(ln_loop_cnt).foundation_order  := l_csv_organ_rec.dpt2_old_cd;
      END IF;
-- 2009/10/06 Ver1.4 mod end by Shigeto.Niki
      -- �{�Ќv
      lv_step :='A-4.co_code';
      lv_message_token :='�{�Ќv';
      g_csv_organ_tab(ln_loop_cnt).co_code           := l_csv_organ_rec.co_code;
      -- �{�Ќv��
      lv_step :='A-4.co_name';
      lv_message_token :='�{�Ќv��';
      g_csv_organ_tab(ln_loop_cnt).co_name           := l_csv_organ_rec.co_name;
      -- �{�Ќv����
      lv_step :='A-4.co_abbrev';
      lv_message_token :='�{�Ќv����';
      g_csv_organ_tab(ln_loop_cnt).co_abbrev         := l_csv_organ_rec.co_abbrev;
-- 2009/10/06 Ver1.4 mod start by Shigeto.Niki
      -- �{�Ќv���я�
      lv_step :='A-4.co_order';
      lv_message_token :='�{�Ќv���я�';
--      g_csv_organ_tab(ln_loop_cnt).co_order          := l_csv_organ_rec.co_order;
      IF (l_csv_organ_rec.dpt1_start_date_active IS NULL) THEN
        g_csv_organ_tab(ln_loop_cnt).co_order      := l_csv_organ_rec.dpt1_old_cd;
      ELSIF (l_csv_organ_rec.dpt1_start_date_active <= gv_process_date) THEN
        g_csv_organ_tab(ln_loop_cnt).co_order      := l_csv_organ_rec.dpt1_new_cd;
      ELSE
        g_csv_organ_tab(ln_loop_cnt).co_order      := l_csv_organ_rec.dpt1_old_cd;
      END IF;
-- 2009/10/06 Ver1.4 mod end by Shigeto.Niki
      -- �g�p�\�t���O
      lv_step :='A-4.enabled_flag';
      lv_message_token :='�g�p�\�t���O';
      g_csv_organ_tab(ln_loop_cnt).enabled_flag      := l_csv_organ_rec.enabled_flag;
      -- �L�����ԊJ�n��
      lv_step :='A-4.start_date_active';
      lv_message_token :='�L�����ԊJ�n��';
      g_csv_organ_tab(ln_loop_cnt).start_date_active := l_csv_organ_rec.start_date_active;
      -- �L�����ԏI����
      lv_step :='A-4.end_date_active';
      lv_message_token :='�L�����ԏI����';
      g_csv_organ_tab(ln_loop_cnt).end_date_active   := l_csv_organ_rec.end_date_active;
    --
      -- �Ώی���
      gn_target_cnt := gn_target_cnt + 1;
    --
    END LOOP csv_organ_loop ;
  --
  -- �\���̂ւ̏o�͌������f
    lv_step :='A-4.2';
    IF (ln_loop_cnt =  0 ) THEN
      -- �\���̂̌��� = 0:�����o�͑Ώۂ������ꍇ�́A
      -- ���ɊJ���Ă�t�@�C�����폜���Ă���ُ�I���������s��
      UTL_FILE.FREMOVE( location    => gt_out_file_dir                                    -- �폜�Ώۂ�����f�B���N�g��
                       ,filename    => gt_out_file_name                                   -- �폜�Ώۃt�@�C����
                                       );
      --
      RAISE nodata_expt;
    END IF;
  --
  EXCEPTION
    -- *** �Ώۃf�[�^�����G���[�n���h�� ***
    WHEN nodata_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxcmm                                -- �}�X�^
                     ,iv_name         => cv_emsg_nodata                                   -- �Ώۃf�[�^�����G���[
                     );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont ||
                    lv_step     || cv_msg_part || lv_errbuf;
      ov_retcode := cv_status_error;
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
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      --�G���[�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_message_token --���[�U�[�E�G���[���b�Z�[�W
      );
      ov_errbuf  := cv_pkg_name ||  cv_msg_cont   ||  cv_prg_name ||  cv_msg_cont ||
                    lv_step     ||  cv_msg_part   ||  SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
  --
  END create_aff_date_proc;
--



  /**********************************************************************************
   * Procedure Name   : output_aff_date_proc
   * Description      : AFF����}�X�^��񏑂����݃v���V�[�W��(A-5)
   ***********************************************************************************/
  PROCEDURE output_aff_date_proc(
    ov_errbuf         OUT     VARCHAR2,                                                   -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT     VARCHAR2,                                                   -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT     VARCHAR2)                                                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name               CONSTANT VARCHAR2(100) := 'output_aff_date_proc';           -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf                 VARCHAR2(5000);                                             -- �G���[�E���b�Z�[�W
    lv_retcode                VARCHAR2(1);                                                -- ���^�[���E�R�[�h
    lv_errmsg                 VARCHAR2(5000);                                             -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_step                   VARCHAR2(100);                                              -- �X�e�b�v
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_company_code           CONSTANT VARCHAR2(10) := '001';                             -- ��ЃR�[�h�F�Œ�l"001"

--
    -- *** ���[�J���ϐ� ***
    ln_max_cnt                NUMBER := 0;                                                -- �J�[�\��Loop���̍ő�LOOP��
    ln_index                  NUMBER ;                                                    -- �J�[�\��Loop����index
    lv_message_token          VARCHAR2(1000);                                             -- ���b�Z�[�W�p�ϐ�
    lv_if_date                VARCHAR2(20);                                               -- �A�g�����p(CHAR�^)�ϐ�
    -- ��(�f�[�^�擾��varchar2(240)*30��+�A���t�@��8000�m��) --
    lv_out_csv_line           VARCHAR2(8000);                                             -- �o�͍s�p�ϐ�
    lt_base_code              fnd_flex_values.flex_value%TYPE;                            -- �G���[�����b�Z�[�W�p�ϐ�
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    file_output_expt          EXCEPTION;                                                  -- �t�@�C���o�̓G���[
  --
  BEGIN
    -- ===============================================
    -- A-5.0���[�J���ϐ�������
    -- ===============================================
    lv_step :='A-5.0';
    lv_errbuf   := NULL;
    lv_retcode  := NULL;
    lv_errmsg   := NULL;
    lt_base_code     := NULL;
    lv_message_token := NULL;
    ln_max_cnt  := g_csv_organ_tab.count;
    lv_if_date  := TO_CHAR(SYSDATE, 'YYYYMMDDHH24MISS');
--
    -- CSV�쐬LOOP�J�n
    <<out_csv_loop>>
    FOR ln_index IN 1 .. ln_max_cnt LOOP
      -- ===============================================
      -- A-5.xxxxx �g�D���\���̂���OUTPUT�p��CSV�s�𐶐�����
      -- ===============================================
      -- lv_out_csv_linen�ҏW���̋L�q�p�^�[��
      -- lv_out_csv_linen := <"> or < lv_out_csv_linen ,"> ||
      --                     <�\���ҏW���e>
      --                     || <">
--
      -- ��ЃR�[�h
      lv_step :='A-5.company_code';
      lv_message_token :='��ЃR�[�h';
      lv_out_csv_line  := cv_dqu ||
                          cv_company_code
                          || cv_dqu;
      -- ���_�R�[�h
      lv_step :='A-5.base_code';
      lv_message_token :='���_�R�[�h';
      lv_out_csv_line  := lv_out_csv_line || cv_sep || cv_dqu ||
                          SUBSTRB(g_csv_organ_tab(ln_index).base_code, 1, 4)
                          || cv_dqu;
      -- ���_����
      lv_step :='A-5.base_name';
      lv_message_token :='���_����';
      lv_out_csv_line  := lv_out_csv_line || cv_sep || cv_dqu ||
                          SUBSTRB(g_csv_organ_tab(ln_index).base_name, 1, 40)
                          || cv_dqu;
      -- ���_����
      lv_step :='A-5.base_abbrev';
      lv_message_token :='���_����';
      lv_out_csv_line  := lv_out_csv_line || cv_sep || cv_dqu ||
                          SUBSTRB(g_csv_organ_tab(ln_index).base_abbrev, 1, 8)
                          || cv_dqu;
      -- ���_���я�
      lv_step :='A-5.base_order';
      lv_message_token :='���_���я�';
      lv_out_csv_line  := lv_out_csv_line || cv_sep || cv_dqu ||
-- 2009/10/06 Ver1.4 mod start by Shigeto.Niki
--                           SUBSTRB(g_csv_organ_tab(ln_index).base_order, 1, 3)
                          SUBSTRB(g_csv_organ_tab(ln_index).base_order, 1, 8)
-- 2009/10/06 Ver1.4 mod end by Shigeto.Niki
                          || cv_dqu;
      -- ����敪
      lv_step :='A-5.section_div';
      lv_message_token :='����敪';
      lv_out_csv_line  := lv_out_csv_line || cv_sep || cv_dqu ||
                          SUBSTRB(g_csv_organ_tab(ln_index).section_div, 1, 2)
                          || cv_dqu;
      -- �n��R�[�h
      lv_step :='A-5.district_code';
      lv_message_token :='�n��R�[�h';
      lv_out_csv_line  := lv_out_csv_line || cv_sep || cv_dqu ||
                          SUBSTRB(g_csv_organ_tab(ln_index).district_code, 1, 4)
                          || cv_dqu;
      -- �n�於
      lv_step :='A-5.district_name';
      lv_message_token :='�n�於';
      lv_out_csv_line  := lv_out_csv_line || cv_sep || cv_dqu ||
                          SUBSTRB(g_csv_organ_tab(ln_index).district_name, 1, 40)
                          || cv_dqu;
      -- �n�旪��
      lv_step :='A-5.district_abbrev';
      lv_message_token :='�n�旪��';
      lv_out_csv_line  := lv_out_csv_line || cv_sep || cv_dqu ||
                          SUBSTRB(g_csv_organ_tab(ln_index).district_abbrev, 1, 8)
                          || cv_dqu;
      -- �n����я�
      lv_step :='A-5.district_order';
      lv_message_token :='�n����я�';
      lv_out_csv_line  := lv_out_csv_line || cv_sep || cv_dqu ||
-- 2009/10/06 Ver1.4 mod start by Shigeto.Niki
--                           SUBSTRB(g_csv_organ_tab(ln_index).district_order, 1, 3)
                          SUBSTRB(g_csv_organ_tab(ln_index).district_order, 1, 6)
-- 2009/10/06 Ver1.4 mod end by Shigeto.Niki
                          || cv_dqu;
      -- �G���A�R�[�h
      lv_step :='A-5.area_code';
      lv_message_token :='�G���A�R�[�h';
      lv_out_csv_line  := lv_out_csv_line || cv_sep || cv_dqu ||
                          SUBSTRB(g_csv_organ_tab(ln_index).area_code, 1, 4)
                          || cv_dqu;
      -- �G���A��
      lv_step :='A-5.area_name';
      lv_message_token :='�G���A��';
      lv_out_csv_line  := lv_out_csv_line || cv_sep || cv_dqu ||
                          SUBSTRB(g_csv_organ_tab(ln_index).area_name, 1, 40)
                          || cv_dqu;
      -- �G���A����
      lv_step :='A-5.area_abbrev';
      lv_message_token :='�G���A����';
      lv_out_csv_line  := lv_out_csv_line || cv_sep || cv_dqu ||
                          SUBSTRB(g_csv_organ_tab(ln_index).area_abbrev, 1, 8)
                          || cv_dqu;
      -- �G���A���я�
      lv_step :='A-5.area_order';
      lv_message_token :='�G���A���я�';
      lv_out_csv_line  := lv_out_csv_line || cv_sep || cv_dqu ||
-- 2009/10/06 Ver1.4 mod start by Shigeto.Niki
--                           SUBSTRB(g_csv_organ_tab(ln_index).area_order, 1, 3)
                          SUBSTRB(g_csv_organ_tab(ln_index).area_order, 1, 6)
-- 2009/10/06 Ver1.4 mod end by Shigeto.Niki
                          || cv_dqu;
      -- �{���R�[�h
      lv_step :='A-5.head_code';
      lv_message_token :='�{���R�[�h';
      lv_out_csv_line  := lv_out_csv_line || cv_sep || cv_dqu ||
                          SUBSTRB(g_csv_organ_tab(ln_index).head_code, 1, 4)
                          || cv_dqu;
      -- �{����
      lv_step :='A-5.head_name';
      lv_message_token :='�{����';
      lv_out_csv_line  := lv_out_csv_line || cv_sep || cv_dqu ||
                          SUBSTRB(g_csv_organ_tab(ln_index).head_name, 1, 40)
                          || cv_dqu;
      -- �{������
      lv_step :='A-5.head_abbrev';
      lv_message_token :='�{������';
      lv_out_csv_line  := lv_out_csv_line || cv_sep || cv_dqu ||
                          SUBSTRB(g_csv_organ_tab(ln_index).head_abbrev, 1, 8)
                          || cv_dqu;
      -- �{�����я�
      lv_step :='A-5.head_order';
      lv_message_token :='�{�����я�';
      lv_out_csv_line  := lv_out_csv_line || cv_sep || cv_dqu ||
-- 2009/10/06 Ver1.4 mod start by Shigeto.Niki
--                           SUBSTRB(g_csv_organ_tab(ln_index).head_order, 1, 3)
                          SUBSTRB(g_csv_organ_tab(ln_index).head_order, 1, 6)
-- 2009/10/06 Ver1.4 mod end by Shigeto.Niki
                          || cv_dqu;
      -- ��{��
      lv_step :='A-5.foundation_code';
      lv_message_token :='��{��';
      lv_out_csv_line  := lv_out_csv_line || cv_sep || cv_dqu ||
                          SUBSTRB(g_csv_organ_tab(ln_index).foundation_code, 1, 4)
                          || cv_dqu;
      -- ��{����
      lv_step :='A-5.foundation_name';
      lv_message_token :='��{����';
      lv_out_csv_line  := lv_out_csv_line || cv_sep || cv_dqu ||
                          SUBSTRB(g_csv_organ_tab(ln_index).foundation_name, 1, 40)
                          || cv_dqu;
      -- ��{������
      lv_step :='A-5.foundation_abbrev';
      lv_message_token :='��{������';
      lv_out_csv_line  := lv_out_csv_line || cv_sep || cv_dqu ||
                          SUBSTRB(g_csv_organ_tab(ln_index).foundation_abbrev, 1, 8)
                          || cv_dqu;
      -- ��{�����я�
      lv_step :='A-5.foundation_order';
      lv_message_token :='��{�����я�';
      lv_out_csv_line  := lv_out_csv_line || cv_sep || cv_dqu ||
-- 2009/10/06 Ver1.4 mod start by Shigeto.Niki
--                           SUBSTRB(g_csv_organ_tab(ln_index).foundation_order, 1, 3)
                          SUBSTRB(g_csv_organ_tab(ln_index).foundation_order, 1, 6)
-- 2009/10/06 Ver1.4 mod end by Shigeto.Niki
                          || cv_dqu;
      -- �{�Ќv
      lv_step :='A-5.co_code';
      lv_message_token :='�{�Ќv';
      lv_out_csv_line  := lv_out_csv_line || cv_sep || cv_dqu ||
                          SUBSTRB(g_csv_organ_tab(ln_index).co_code, 1, 4)
                          || cv_dqu;
      -- �{�Ќv��
      lv_step :='A-5.co_name';
      lv_message_token :='�{�Ќv��';
      lv_out_csv_line  := lv_out_csv_line || cv_sep || cv_dqu ||
                          SUBSTRB(g_csv_organ_tab(ln_index).co_name, 1, 40)
                          || cv_dqu;
      -- �{�Ќv����
      lv_step :='A-5.co_abbrev';
      lv_message_token :='�{�Ќv����';
      lv_out_csv_line  := lv_out_csv_line || cv_sep || cv_dqu ||
                          SUBSTRB(g_csv_organ_tab(ln_index).co_abbrev, 1, 8)
                          || cv_dqu;
      -- �{�Ќv���я�
      lv_step :='A-5.co_order';
      lv_message_token :='�{�Ќv���я�';
      lv_out_csv_line  := lv_out_csv_line || cv_sep || cv_dqu ||
-- 2009/10/06 Ver1.4 mod start by Shigeto.Niki
--                           SUBSTRB(g_csv_organ_tab(ln_index).co_order, 1, 3)
                          SUBSTRB(g_csv_organ_tab(ln_index).co_order, 1, 6)
-- 2009/10/06 Ver1.4 mod end by Shigeto.Niki
                          || cv_dqu;
      -- �g�p�\�t���O
      lv_step :='A-5.enabled_flag';
      lv_message_token :='�g�p�\�t���O';
      lv_out_csv_line  := lv_out_csv_line || cv_sep || cv_dqu ||
                          SUBSTRB(g_csv_organ_tab(ln_index).enabled_flag, 1, 1)
                          || cv_dqu;
      -- �L�����ԊJ�n��
      lv_step :='A-5.start_date_active';
      lv_message_token :='�L�����ԊJ�n��';
      lv_out_csv_line  := lv_out_csv_line || cv_sep ||
                          TO_CHAR(g_csv_organ_tab(ln_index).start_date_active, 'YYYYMMDD' )
                          ;
      -- �L�����ԏI����
      lv_step :='A-5.end_date_active';
      lv_message_token :='�L�����ԏI����';
      lv_out_csv_line  := lv_out_csv_line || cv_sep ||
                          TO_CHAR(g_csv_organ_tab(ln_index).end_date_active, 'YYYYMMDD'   )
                          ;
      -- �A�g����
      lv_step :='A-5.if_date';
      lv_message_token :='�A�g����';
      lv_out_csv_line  := lv_out_csv_line || cv_sep ||
                          lv_if_date
                          ;
      --
      -- CSV�t�@�C���o��
      lv_step := 'A-5.2';
      BEGIN
        --
        -- �G���[���̃��b�Z�[�W�o�͗p�ɋ��_�R�[�h��ϐ��Ɋi�[����
        lt_base_code     := SUBSTRB(g_csv_organ_tab(ln_index).base_code, 1, 4);
        -- �t�@�C���̏������݂��s��(���s����)
        UTL_FILE.PUT_LINE(gf_file_hand, lv_out_csv_line );
      EXCEPTION
        WHEN OTHERS THEN
          --
          RAISE file_output_expt;
      END;
      --
      -- ��������
      gn_normal_cnt := gn_normal_cnt + 1;
      --
    END LOOP out_csv_loop;
  --
  EXCEPTION
    -- *** �t�@�C���������݃G���[�n���h�� ***
    WHEN file_output_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name_xxcmm                                  -- �}�X�^
                   ,iv_name         => cv_emsg_output                                     -- �t�@�C���������݃G���[
                   ,iv_token_name1  => cv_tkn_ng_word                                     -- NG_WORD
                   ,iv_token_value1 => cv_tknv_base_code                                  -- ���_�R�[�h
                   ,iv_token_name2  => cv_tkn_nd_data                                     -- NG_DATA
                   ,iv_token_value2 => lt_base_code                                       -- ���_�R�[�h�l
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont ||
                    lv_step     || cv_msg_part || lv_errbuf;
      ov_retcode := cv_status_error;
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
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      --�G���[�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_message_token --���[�U�[�E�G���[���b�Z�[�W
      );
      ov_errbuf  := cv_pkg_name ||  cv_msg_cont   ||  cv_prg_name ||  cv_msg_cont ||
                    lv_step     ||  cv_msg_part   ||  SQLERRM;
      ov_retcode := cv_status_error;
--
  END output_aff_date_proc;
--
--
  /**********************************************************************************
   * Procedure Name   : fin_proc
   * Description      : �I�������v���V�[�W��(A-6)
   ***********************************************************************************/
  PROCEDURE fin_proc(
    iov_errbuf        IN OUT  VARCHAR2,                                                   -- �G���[�E���b�Z�[�W           --# �Œ� #
    iov_retcode       IN OUT  VARCHAR2,                                                   -- ���^�[���E�R�[�h             --# �Œ� #
    iov_errmsg        IN OUT  VARCHAR2)                                                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name               CONSTANT VARCHAR2(100) := 'fin_proc';                       -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf                 VARCHAR2(5000);                                             -- �G���[�E���b�Z�[�W
    lv_retcode                VARCHAR2(1);                                                -- ���^�[���E�R�[�h
    lv_errmsg                 VARCHAR2(5000);                                             -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_step                   VARCHAR2(100);                                              -- �X�e�b�v
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_message_code           VARCHAR2(30);                                               -- �σ��b�Z�[�W�R�[�h
    --
    -- *** ���[�U�[��`��O ***
--
  BEGIN
    -- ===============================================
    -- A-6.0���[�J���ϐ�������
    -- ===============================================
    lv_step :='A-6.0';
    lv_errbuf   := NULL ;
    lv_retcode  := NULL ;
    lv_errmsg   := NULL ;
    lv_message_code := NULL;
--
    -- ===============================================
    -- A-6.1�t�@�C���̃N���[�Y����
    -- ===============================================
    lv_step := 'A-6.1';
    --
    BEGIN
      -- �t�@�C���N���[�Y
      UTL_FILE.FCLOSE( gf_file_hand );
    EXCEPTION
      WHEN OTHERS THEN
      -- *** �t�@�C���N���[�Y���s��O�n���h�� ***
        -- ���݂܂łɃG���[���o�Ă�ꍇ�͐�ɏo�͂���
        IF ( iov_retcode <> cv_status_normal ) THEN
          -- �G���[�����ӏ� + �G���[���e
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => iov_errbuf || iov_errmsg
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => iov_errbuf || iov_errmsg
          );
        END IF;
        -- �t�@�C���N���[�Y���G���[���b�Z�[�W�𓱏o����
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name_xxcmm                                -- �}�X�^
                       ,iv_name         => cv_emsg_file_close                               -- �t�@�C���N���[�Y�G���[
                       ,iv_token_name1  => cv_tkn_sqlerrm                                   -- SQLERRM
                       ,iv_token_value1 => SQLERRM                                          -- SQLERRM
                       );
        iov_errmsg  := lv_errmsg;
        iov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont ||
                       lv_step     || cv_msg_part || lv_errbuf;
        iov_retcode := cv_status_error;
      --
    END;
    --
    -- ===============================================
    -- A-6.2�I�����O�̏o�͏���
    -- ===============================================
    -- �G���[���O�̏o��
    lv_step := 'A-6.2.1';
    IF ( iov_retcode  <> cv_status_normal ) THEN
      -- ����I�����ȊO�̓��b�Z�[�W���O���o�͂���
      -- �G���[�����ӏ� + �G���[���e
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => iov_errbuf || iov_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => iov_errbuf || iov_errmsg
      );
    END IF;
    --
    -- �G���[�����̎擾(�S���� - ��������)
    lv_step := 'A-6.2.2';
    gn_error_cnt := gn_target_cnt - gn_normal_cnt;
    --�Ώی����o��
    lv_step := 'A-6.2.3';
    lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => cv_imsg_all_count
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR( gn_target_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg
      );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_errmsg
      );
    -- ���b�Z�[�W�p�ϐ�������
    lv_errmsg := NULL;
    --
    --���������o��
    lv_step := 'A-6.2.4';
    lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => cv_imsg_suc_count
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR( gn_normal_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg
      );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_errmsg
      );
    -- ���b�Z�[�W�p�ϐ�������
    lv_errmsg := NULL;
    --
    --�ُ팏���o��
    lv_step := 'A-6.2.5';
    lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => cv_imsg_err_count
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR( gn_error_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg
      );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_errmsg
      );
    -- ���b�Z�[�W�p�ϐ�������
    lv_errmsg := NULL;
    --
    --�I�����b�Z�[�W�o��
    lv_step := 'A-6.2.6';
    IF ( iov_retcode    = cv_status_normal ) THEN
      -- ����I���̏ꍇ
      lv_message_code := cv_imsg_normal_end;
    --
    ELSIF( iov_retcode  = cv_status_warn ) THEN
      -- �x���I���̏ꍇ
      lv_message_code := cv_imsg_warn_end;
    --
    ELSIF( iov_retcode  = cv_status_error ) THEN
      -- �ُ�I���̏ꍇ
      lv_message_code := cv_imsg_error_end;
    END IF;
    -- ���b�Z�[�W�̎擾
    lv_errmsg  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => lv_message_code
                   );
    --
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_errmsg
    );
  --
  EXCEPTION
  --#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      iov_errmsg  := lv_errmsg;
      iov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf;
      iov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      iov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      iov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      --�G���[�o��
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part||SQLERRM,1,5000),TRUE);
--
  END fin_proc;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
     ov_errbuf        OUT     VARCHAR2                                                    --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode       OUT     VARCHAR2                                                    --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg        OUT     VARCHAR2                                                    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name               CONSTANT VARCHAR2(100) := 'submain';                        -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf                 VARCHAR2(5000);                                             -- �G���[�E���b�Z�[�W
    lv_retcode                VARCHAR2(1);                                                -- ���^�[���E�R�[�h
    lv_errmsg                 VARCHAR2(5000);                                             -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_step                   VARCHAR2(100);                                              -- �X�e�b�v
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[���[�J���ϐ�
    -- ===============================
    ln_upper_sec_cnt          NUMBER  := 0;                                               -- �ŏ�ʕ��吔�̃J�E���g�ϐ�
--
    -- ===============================
    -- ���[�U�[���[�J���J�[�\����`
    -- ===============================
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    subproc_expt              EXCEPTION;                                                  -- �T�u�v���O�����G���[
    file_open_expt            EXCEPTION;                                                  -- �t�@�C���I�[�v���G���[
-- 2009/05/15 Ver1.3 delete start by Yutaka.Kuboshima
--    upper_sec_cnt_expt        EXCEPTION;                                                  -- �ŏ�ʕ��啡�����̃G���[
-- 2009/05/15 Ver1.3 delete end by Yutaka.Kuboshima
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
    -- A-0.���[�J���ϐ�������
    -- ===============================================
    lv_errbuf   := NULL;
    lv_retcode  := NULL;
    lv_errmsg   := NULL;
    lv_step     := NULL;
--
    -- ===============================================
    -- A-1.��������(init_proc�ōs��)
    -- ===============================================
    init_proc(
       ov_errbuf      => lv_errbuf                                                        -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode     => lv_retcode                                                       -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg      => lv_errmsg                                                        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      --
      RAISE subproc_expt;
    END IF;
--
    -- ===============================================
    -- A-2.�t�@�C���I�[�v������(UTL_FILE.FOPEN�֐�)
    -- ===============================================
    --
      lv_step := 'A-2.1';
      BEGIN
        -- �t�@�C���n���h���̐���
        gf_file_hand := UTL_FILE.FOPEN(  location   => gt_out_file_dir                    -- �o�͐�
                                        ,filename   => gt_out_file_name                   -- �t�@�C����
                                        ,open_mode  => cv_csv_mode_w                      -- �t�@�C���I�[�v�����[�h
                                       );
      EXCEPTION
        WHEN OTHERS THEN
          --
          RAISE file_open_expt;
      END;
--
    -- ===============================================
    -- A-3.�ŏ�ʕ��匏���擾
    -- ===============================================
-- 2009/05/15 Ver1.3 delete start by Yutaka.Kuboshima
/*    -- �ŏ�ʕ���̐����J�E���g����
    lv_step := 'A-3.1';
    SELECT
          COUNT(1)
    INTO
          ln_upper_sec_cnt
    FROM
          fnd_flex_value_sets   ffvs,
          fnd_flex_values       ffv
    WHERE
          ffvs.flex_value_set_name    = cv_dept_valset_name
    AND   ffv.summary_flag            = cv_flag_yes
    AND   ffvs.flex_value_set_id      = ffv.flex_value_set_id
-- 2009/04/20 Ver1.2 add start by Yutaka.Kuboshima
    AND   ffv.flex_value             <> gv_aff_dept_dummy_cd
-- 2009/04/20 Ver1.2 add end by Yutaka.Kuboshima
    AND   NOT EXISTS (
                        SELECT
                            'X'
                        FROM
                            fnd_flex_value_norm_hierarchy ffvh
                        WHERE
                            ffvh.flex_value_set_id =  ffv.flex_value_set_id
                        AND (ffv.flex_value BETWEEN ffvh.child_flex_value_low AND ffvh.child_flex_value_high)
-- 2009/04/20 Ver1.2 add start by Yutaka.Kuboshima
                        AND ffvh.range_attribute   = cv_flag_parent
                        )
    AND   EXISTS (
                    SELECT
                        'X'
                    FROM
                        fnd_flex_value_norm_hierarchy ffvh2
                    WHERE
                        ffvh2.flex_value_set_id = ffv.flex_value_set_id
                    AND ffvh2.parent_flex_value = ffv.flex_value
                    AND ffvh2.range_attribute   = cv_flag_parent
                    )
    ;
-- 2009/04/20 Ver1.2 add end by Yutaka.Kuboshima
    -- �ŏ�ʕ���̐����`�F�b�N����
    lv_step := 'A-3.2';
    IF ( ln_upper_sec_cnt <> 1 ) THEN
      -- �ŏ�ʑw�̕��吔�ŃG���[���������ꍇ
      -- ���ɊJ���Ă�t�@�C�����폜���Ă���ُ�I���������s��
      UTL_FILE.FREMOVE( location    => gt_out_file_dir                                    -- �폜�Ώۂ�����f�B���N�g��
                       ,filename    => gt_out_file_name                                   -- �폜�Ώۃt�@�C����
                                       );
      --
      RAISE upper_sec_cnt_expt ;
    END IF;
--
*/
-- 2009/05/15 Ver1.3 delete end by Yutaka.Kuboshima
    -- ===============================================
    -- A-4.AFF����}�X�^���擾(create_aff_date_proc���Ăяo��)
    -- ===============================================
    create_aff_date_proc(
       ov_errbuf      => lv_errbuf                                                        -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode     => lv_retcode                                                       -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg      => lv_errmsg                                                        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      --
      RAISE subproc_expt;
    END IF;
--
    -- ===============================================
    -- A-5.AFF����}�X�^���o�͏���(output_aff_date_proc���Ăяo��)
    -- ===============================================
    output_aff_date_proc(
       ov_errbuf      => lv_errbuf                                                        -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode     => lv_retcode                                                       -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg      => lv_errmsg                                                        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      --
      RAISE subproc_expt;
    END IF;
--
  EXCEPTION
    -- *** �T�u�v���O������O�n���h�� ****
    WHEN subproc_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_error;
--
    --*** �t�@�C���I�[�v���G���[ ***
    WHEN file_open_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxcmm                                -- �}�X�^
                     ,iv_name         => cv_emsg_file_open                                -- �t�@�C���I�[�v���G���[
                     ,iv_token_name1  => cv_tkn_sqlerrm                                   -- SQLERRM
                     ,iv_token_value1 => SQLERRM                                          -- SQLERRM
                     );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont ||
                    lv_step     || cv_msg_part || lv_errbuf;
      ov_retcode := cv_status_error;
--
-- 2009/05/15 Ver1.3 delete start by Yutaka.Kuboshima
/*    --*** �ŏ�ʕ��吔�G���[ ***
    WHEN upper_sec_cnt_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxcmm                                -- �}�X�^
                     ,iv_name         => cv_emsg_uppersec_cnt                             -- �ŏ�ʕ��吔�G���[
                     ,iv_token_name1  => cv_tkn_ffvset_name                               -- FFV_SET_NAME
                     ,iv_token_value1 => cv_dept_valset_name                              -- �l�Z�b�g��
                     ,iv_token_name2  => cv_tkn_count                                     -- COUNT
                     ,iv_token_value2 => TO_CHAR(ln_upper_sec_cnt)                        -- �ŏ�ʕ��吔
                     );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont ||
                    lv_step     || cv_msg_part || lv_errbuf;
      ov_retcode := cv_status_error;
*/
-- 2009/05/15 Ver1.3 delete end by Yutaka.Kuboshima
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
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part||SQLERRM,1,5000),TRUE);
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
    errbuf            OUT     VARCHAR2                                                    --   �G���[���b�Z�[�W #�Œ�#
   ,retcode           OUT     VARCHAR2                                                    --   �G���[�R�[�h     #�Œ�#
  )
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name               CONSTANT VARCHAR2(100) := 'main';                           -- �v���O������
    cv_log                    CONSTANT VARCHAR2(100) := 'LOG';                            -- ���O
    cv_output                 CONSTANT VARCHAR2(100) := 'OUTPUT';                         -- �A�E�g�v�b�g
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf                 VARCHAR2(5000);                                             -- �G���[�E���b�Z�[�W
    lv_retcode                VARCHAR2(1);                                                -- ���^�[���E�R�[�h
    lv_errmsg                 VARCHAR2(5000);                                             -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_step                   VARCHAR2(10);                                               -- �X�e�b�v
    lv_message_code           VARCHAR2(100);                                              -- ���b�Z�[�W�R�[�h
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
    IF ( lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_output
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- A-1.�`A-5��submain���ōs��
    -- ===============================================
    submain(
       ov_errbuf      => lv_errbuf                                                        -- �G���[�E���b�Z�[�W          --# �Œ� #
      ,ov_retcode     => lv_retcode                                                       -- ���^�[���E�R�[�h            --# �Œ� #
      ,ov_errmsg      => lv_errmsg                                                        -- ���[�U�[�E�G���[�E���b�Z�[�W--# �Œ� #
    );
--
    -- ===============================================
    -- A-6.�I������(A-6.1.�t�@�C���N���[�Y/A-6.2.�I�����O�o�͂�fin_proc�ōs��)
    -- ===============================================
    fin_proc(
       iov_errbuf     => lv_errbuf                                                        -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,iov_retcode    => lv_retcode                                                       -- ���^�[���E�R�[�h             --# �Œ� #
      ,iov_errmsg     => lv_errmsg                                                        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- ===============================================
    -- A-6.3.�I���X�e�[�^�X�̃Z�b�g
    -- ===============================================
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF ( retcode = cv_status_error ) THEN
      --
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  --
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  --
  END main;
--
END XXCMM005A02C ;
/
