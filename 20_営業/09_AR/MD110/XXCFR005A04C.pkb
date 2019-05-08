CREATE OR REPLACE PACKAGE BODY XXCFR005A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR005A04C(body)
 * Description      : ���b�N�{�b�N�X��������
 * MD.050           : MD050_CFR_005_A04_���b�N�{�b�N�X��������
 * MD.070           : MD050_CFR_005_A04_���b�N�{�b�N�X��������
 * Version          : 1.04
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   �������� (A-1)
 *  get_fb_data            FB�t�@�C���捞���� (A-2)
 *  get_bank_info          ����24���ԉ���s���擾���� (A-11)
 *  get_receive_method     �x�����@�擾���� (A-3)
 *  get_receipt_customer   ������ڋq�擾���� (A-4)
 *  get_fb_out_acct_number ���������ΏۊO�ڋq�擾���� (A-5)
 *  get_trx_amount         �Ώۍ����z���� (A-6)
 *  exec_cash_api          ����API�N������ (A-7)
 *  insert_table           ���b�N�{�b�N�X�����������[�N�e�[�u���o�^���� (A-8)
 *  update_table           �p���������s�敪�t�^���� (A-9)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2010/10/15    1.00 SCS �A�� �^���l  ����쐬
 *  2013/07/22    1.01 SCSK ���� ����   E_�{�ғ�_10950 ����ő��őΉ�
 *  2015/05/29    1.02 SCSK ���H ���O   E_�{�ғ�_13114 �U��24���ԉ��Ή�
 *  2019/02/05    1.03 SCSK ��� �h�i   E_�{�ғ�_15534 �N���ύX�Ή�
 *  2019/05/08    1.04 SCSK ���� ����   E_�{�ғ�_15722 �N���ύX�s��Ή�
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
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
  cv_msg_pnt       CONSTANT VARCHAR2(3) := ',';
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
  gn_warn_cnt      NUMBER;                    -- �x������
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
  global_lock_err_expt      EXCEPTION;
  --
  PRAGMA EXCEPTION_INIT(global_lock_err_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFR005A04C'; -- �p�b�P�[�W��
  cv_msg_kbn_cfr     CONSTANT VARCHAR2(5)   := 'XXCFR';
--
  -- �L��
  cv_msg_brack_point CONSTANT VARCHAR2(5)   := '�E';
  cv_msg_under_score CONSTANT VARCHAR2(5)   := '_';
  cv_msg_dott        CONSTANT VARCHAR2(5)   := '.';
--
  -- ���b�Z�[�W�ԍ�
  cv_msg_005a04_003  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00003'; -- ���b�N�G���[
  cv_msg_005a04_004  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00004'; -- �v���t�@�C���擾�G���[���b�Z�[�W
  cv_msg_005a04_006  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00006'; -- �Ɩ��������t�擾�G���[���b�Z�[�W
  cv_msg_005a04_016  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00016'; -- �f�[�^�}���G���[���b�Z�[�W
  cv_msg_005a04_017  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00017'; -- �f�[�^�X�V�G���[���b�Z�[�W
  cv_msg_005a04_024  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00024'; -- �Ώۃf�[�^�Ȃ����b�Z�[�W
  cv_msg_005a04_029  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00029'; -- �捞�t�@�C�����o�̓��b�Z�[�W
  cv_msg_005a04_039  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00039'; -- �捞�t�@�C�����݂Ȃ��G���[
  cv_msg_005a04_113  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00113'; -- FB�t�@�C������`�Ȃ��G���[���b�Z�[�W
  cv_msg_005a04_114  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00114'; -- �萔�����x�z��`�Ȃ��G���[���b�Z�[�W
  cv_msg_005a04_115  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00115'; -- �Ώێx�����@�Ȃ��G���[���b�Z�[�W
  cv_msg_005a04_116  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00116'; -- �Ώیڋq�Ȃ����b�Z�[�W
  cv_msg_005a04_117  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00117'; -- ����API�G���[���b�Z�[�W
  cv_msg_005a04_118  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00118'; -- �s�������������b�Z�[�W
  cv_msg_005a04_119  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00119'; -- ���t�ϊ��G���[���b�Z�[�W
  cv_msg_005a04_120  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00120'; -- ���l�ϊ��G���[���b�Z�[�W
  cv_msg_005a04_121  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00121'; -- ���̓p�����[�^�u���[�N�e�[�u���쐬�t���O�v���ݒ�G���[���b�Z�[�W
  cv_msg_005a04_122  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00122'; -- �t�@�C�����o�͑ΏۂȂ����b�Z�[�W
  cv_msg_005a04_025  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00025'; -- �x���������b�Z�[�W
  cv_msg_005a04_126  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00126'; -- �Ώێx�����@�d���G���[���b�Z�[�W
  cv_msg_005a04_127  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00127'; -- �Ώێx�����@�o�̓��b�Z�[�W
  cv_msg_005a04_128  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00128'; -- ���������Ώی������b�Z�[�W
-- 2015/05/29 Ver1.02 Add Start
  cv_msg_005a04_151  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00151'; -- �����ԍ��Ǘ��e�[�u���폜�G���[���b�Z�[�W
-- 2015/05/29 Ver1.02 Add End
--
-- �g�[�N��
  cv_tkn_param_name            CONSTANT VARCHAR2(20) := 'PARAM_NAME';
  cv_tkn_param_val             CONSTANT VARCHAR2(20) := 'PARAM_VAL';
  cv_tkn_prof_name             CONSTANT VARCHAR2(20) := 'PROF_NAME';
  cv_tkn_lookup_type           CONSTANT VARCHAR2(20) := 'LOOKUP_TYPE';
  cv_tkn_table                 CONSTANT VARCHAR2(20) := 'TABLE';
  cv_tkn_file_name             CONSTANT VARCHAR2(20) := 'FILE_NAME';
  cv_tkn_file_path             CONSTANT VARCHAR2(20) := 'FILE_PATH';
  cv_tkn_receipt_number        CONSTANT VARCHAR2(20) := 'RECEIPT_NUMBER';
  cv_tkn_account_number        CONSTANT VARCHAR2(20) := 'ACCOUNT_NUMBER';
  cv_tkn_receipt_method        CONSTANT VARCHAR2(20) := 'RECEIPT_METHOD';
  cv_tkn_receipt_date          CONSTANT VARCHAR2(20) := 'RECEIPT_DATE';
  cv_tkn_amount                CONSTANT VARCHAR2(20) := 'AMOUNT';
  cv_tkn_trx_number            CONSTANT VARCHAR2(20) := 'TRX_NUMBER';
  cv_tkn_count                 CONSTANT VARCHAR2(20) := 'COUNT';
  cv_tkn_ref_number            CONSTANT VARCHAR2(20) := 'REF_NUMBER';
  cv_tkn_bank_number           CONSTANT VARCHAR2(20) := 'BANK_NUMBER';
  cv_tkn_bank_num              CONSTANT VARCHAR2(20) := 'BANK_NUM';
  cv_tkn_bank_account_type     CONSTANT VARCHAR2(20) := 'BANK_ACCOUNT_TYPE';
  cv_tkn_bank_account_num      CONSTANT VARCHAR2(20) := 'BANK_ACCOUNT_NUM';
  cv_tkn_alt_name              CONSTANT VARCHAR2(20) := 'ALT_NAME';
  cv_tkn_receipt_method_owner  CONSTANT VARCHAR2(20) := 'RECEIPT_METHOD_OWNER';
  cv_tkn_bank_account_owner    CONSTANT VARCHAR2(20) := 'BANK_ACCOUNT_OWNER';
-- 2015/05/29 Ver1.02 Add Start
  cv_tkn_retention_date        CONSTANT VARCHAR2(20) := 'RETENTION_DATE';
-- 2015/05/29 Ver1.02 Add End
--
  --�v���t�@�C��
  cv_prf_fb_path        CONSTANT VARCHAR2(30) := 'XXCFR1_FB_FILEPATH';    -- FB�t�@�C���i�[�p�X
  cv_prf_par_cnt        CONSTANT VARCHAR2(30) := 'XXCFR1_PARALLEL_COUNT'; -- �p���������s��
  cv_set_of_bks_id      CONSTANT VARCHAR2(30) := 'GL_SET_OF_BKS_ID';      -- ��v����ID
  cv_org_id             CONSTANT VARCHAR2(30) := 'ORG_ID';                -- �c�ƒP��ID
-- 2015/05/29 Ver1.02 Add Start
  cv_retention_period   CONSTANT VARCHAR2(30) := 'XXCFR1_RETENTION_PERIOD'; -- �����ԍ��Ǘ��e�[�u���ێ�����
-- 2015/05/29 Ver1.02 Add End
--
  -- �t�@�C���o��
  cv_file_type_out      CONSTANT VARCHAR2(10) := 'OUTPUT';           -- ���b�Z�[�W�o��
  cv_file_type_log      CONSTANT VARCHAR2(10) := 'LOG';              -- ���O�o��
--
  -- �����t�H�[�}�b�g
  cv_format_date_ymd    CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';   -- ���t�t�H�[�}�b�g�i�N�����j
  cv_format_ymd         CONSTANT VARCHAR2(10) := 'YYYYMMDD';     -- ���t�t�H�[�}�b�g�i�N�����j
  cv_format_rmd         CONSTANT VARCHAR2(6)  := 'RRMMDD';       -- ���t�t�H�[�}�b�g�i�a��j
  cv_format_nls_cal     CONSTANT VARCHAR2(40) := 'NLS_CALENDAR=''JAPANESE IMPERIAL''';  -- 
-- 2015/05/29 Ver1.02 Add Start
  cv_format_dd          CONSTANT VARCHAR2(2)  := 'DD';           -- ���t�t�H�[�}�b�g�i�N���j
-- 2015/05/29 Ver1.02 Add End
--
  -- �e�[�u����
  cv_tkn_rock_wk        CONSTANT VARCHAR2(50) := 'XXCFR_ROCKBOX_WK';  -- ���b�N�{�b�N�X�����������[�N�e�[�u��
-- 2015/05/29 Ver1.02 Add Start
  cv_tkn_xcrnc          CONSTANT VARCHAR2(50) := 'XXCFR_CASH_RECEIPTS_NO_CONTROL';  -- �����ԍ��Ǘ��e�[�u��
-- 2015/05/29 Ver1.02 Add END
--
  -- ���e�����l
  cb_true               CONSTANT BOOLEAN := TRUE;
  cb_false              CONSTANT BOOLEAN := FALSE;
--
  cv_flag_y             CONSTANT VARCHAR2(10) := 'Y';  -- �t���O�l�FY
-- 2015/05/29 Ver1.02 Add Start
  cv_flag_n             CONSTANT VARCHAR2(10) := 'N';  -- �t���O�l�FN
-- 2015/05/29 Ver1.02 Add End
  cv_need               CONSTANT VARCHAR2(1)  := '1';  -- �v
  cv_no_need            CONSTANT VARCHAR2(1)  := '0';  -- ��
--
  -- �Q�ƃ^�C�v�n
  ct_lc_fb_file_name    CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCFR1_FB_FILE_NAME';        -- �Q�ƃ^�C�v�uFB�t�@�C�����v
  ct_out_acct_number    CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCFR1_FB_OUT_ACCT_NUMBER';  -- �Q�ƃ^�C�v�u���������ΏۊO�ڋq�v
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  TYPE rockbox_table_ttype     IS TABLE OF xxcfr_rockbox_wk%ROWTYPE
                                  INDEX BY PLS_INTEGER;  -- FB�f�[�^
  TYPE fnd_lookup_values_ttype IS TABLE OF fnd_lookup_values_vl.description%TYPE
                                  INDEX BY PLS_INTEGER;  -- FB�t�@�C����
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- �v���t�@�C���l
  gt_prf_fb_path        all_directories.directory_name%TYPE;        -- FB�t�@�C���p�X
  gn_prf_par_cnt        NUMBER;                                     -- �p���������s��
  gt_set_of_bks_id      gl_sets_of_books.set_of_books_id%TYPE;      -- ��v����ID
  gn_org_id             NUMBER;                                     -- �c�ƒP��
-- 2015/05/29 Ver1.02 Add Start
  gn_retention_period   NUMBER;                                     -- �����ԍ��Ǘ��e�[�u���ێ�����
-- 2015/05/29 Ver1.02 Add End
  -- ���̑�
  gd_process_date       DATE;                                       -- �Ɩ��������t
  gt_tolerance_limit    ap_bank_charge_lines.tolerance_limit%TYPE;  -- �萔�����x�z
  gn_no_customer_cnt    NUMBER;                                     -- �s����������
  gn_auto_apply_cnt     NUMBER;                                     -- ���������Ώی���
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ���̓p�����[�^�l���O�o�͏���(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_fb_file_name      IN         VARCHAR2,                 -- �p�����[�^�DFB�t�@�C����
    iv_table_insert_flag IN         VARCHAR2,                 -- �p�����[�^�D���[�N�e�[�u���쐬�t���O
    o_fb_file_name_tab   OUT NOCOPY fnd_lookup_values_ttype,  -- FB�t�@�C����
    ov_errbuf            OUT NOCOPY VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT NOCOPY VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT NOCOPY VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    cv_ar  CONSTANT VARCHAR2(2) := 'AR';
--
    -- *** ���[�J���ϐ� ***
    ln_count           PLS_INTEGER;              -- ���[�v�J�E���^
    l_fb_file_name_tab fnd_lookup_values_ttype;  -- FB�t�@�C����
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J���E��O ***
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
    -- ������
    -- �߂�l
    ov_errbuf := NULL;
    ov_errmsg := NULL;
    -- �z��
    l_fb_file_name_tab.DELETE;
    o_fb_file_name_tab.DELETE;
--
    --==============================================================
    --�R���J�����g�p�����[�^�o��
    --==============================================================
--
    -- ���O�o��
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_log      -- ���O�o��
      ,iv_conc_param1  => iv_fb_file_name       -- �R���J�����g�p�����[�^�P
      ,iv_conc_param2  => iv_table_insert_flag  -- �R���J�����g�p�����[�^�Q
      ,ov_errbuf       => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
    -- ���b�Z�[�W�o��
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_out      -- ���O�o��
      ,iv_conc_param1  => iv_fb_file_name       -- �R���J�����g�p�����[�^�P
      ,iv_conc_param2  => iv_table_insert_flag  -- �R���J�����g�p�����[�^�Q
      ,ov_errbuf       => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- ���̓p�����[�^�K�{�`�F�b�N
    --==============================================================
    -- �p�����[�^�D���[�N�e�[�u���쐬�t���O�̕K�{�`�F�b�N
    IF (iv_table_insert_flag IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cfr
                    ,iv_name         => cv_msg_005a04_121
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- �Ɩ��������t�擾����
    --==============================================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
--
    -- �擾�G���[��
    IF ( gd_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cfr
                    ,iv_name         => cv_msg_005a04_006
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- �v���t�@�C���l�̎擾
    --==============================================================
    -- FB�t�@�C���p�X
    gt_prf_fb_path      := FND_PROFILE.VALUE( cv_prf_fb_path );
    IF ( gt_prf_fb_path IS NULL ) THEN    -- �擾�G���[��
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cfr
                    ,iv_name         => cv_msg_005a04_004
                    ,iv_token_name1  => cv_tkn_prof_name
                    ,iv_token_value1 => xxcfr_common_pkg.get_user_profile_name( cv_prf_fb_path )
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- �p���������s��
    gn_prf_par_cnt      := TO_NUMBER( FND_PROFILE.VALUE( cv_prf_par_cnt ) );
    IF ( gn_prf_par_cnt IS NULL ) THEN    -- �擾�G���[��
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cfr
                    ,iv_name         => cv_msg_005a04_004
                    ,iv_token_name1  => cv_tkn_prof_name
                    ,iv_token_value1 => xxcfr_common_pkg.get_user_profile_name( cv_prf_par_cnt )
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- ��v����ID
    gt_set_of_bks_id    := TO_NUMBER( FND_PROFILE.VALUE( cv_set_of_bks_id ) );
    IF ( gt_set_of_bks_id IS NULL ) THEN    -- �擾�G���[��
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cfr
                    ,iv_name         => cv_msg_005a04_004
                    ,iv_token_name1  => cv_tkn_prof_name
                    ,iv_token_value1 => xxcfr_common_pkg.get_user_profile_name( cv_set_of_bks_id )
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- �c�ƒP��
    gn_org_id           := TO_NUMBER( FND_PROFILE.VALUE( cv_org_id ) );
    IF ( gn_org_id IS NULL ) THEN    -- �擾�G���[��
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cfr
                    ,iv_name         => cv_msg_005a04_004
                    ,iv_token_name1  => cv_tkn_prof_name
                    ,iv_token_value1 => xxcfr_common_pkg.get_user_profile_name( cv_org_id )
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
-- 2015/05/29 Ver1.02 Add Start
    -- �����ԍ��Ǘ��e�[�u���ێ�����
    gn_retention_period    := TO_NUMBER( FND_PROFILE.VALUE( cv_retention_period ) );
    IF ( gn_retention_period IS NULL ) THEN    -- �擾�G���[��
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cfr
                    ,iv_name         => cv_msg_005a04_004
                    ,iv_token_name1  => cv_tkn_prof_name
                    ,iv_token_value1 => xxcfr_common_pkg.get_user_profile_name( cv_retention_period )
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
-- 2015/05/29 Ver1.02 Add End
--
    --==============================================================
    -- �Q�ƃ^�C�v�̎擾
    --==============================================================
    -- FB�t�@�C����
    -- �p�����[�^�DFB�t�@�C������NULL�ł���ΎQ�ƃ^�C�v����擾
    IF ( iv_fb_file_name IS NULL ) THEN
--
      BEGIN
--
        SELECT flvv.meaning AS meaning
        BULK COLLECT INTO l_fb_file_name_tab
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type  = ct_lc_fb_file_name  -- �Q�ƃ^�C�v
        AND    flvv.enabled_flag = cv_flag_y           -- �L���t���O
        AND    gd_process_date BETWEEN NVL( flvv.start_date_active, gd_process_date )  -- �L����(��)
                                   AND NVL( flvv.end_date_active  , gd_process_date )  -- �L����(��)
        AND    flvv.meaning IS NOT NULL  -- FB�t�@�C������NULL�ȊO
        ;
--
        -- �N�C�b�N�R�[�h���o�^����Ă��Ȃ��Ƃ�
        IF (l_fb_file_name_tab.COUNT < 1) THEN
          RAISE NO_DATA_FOUND;
        END IF;
--
      EXCEPTION
--
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cfr
                        ,iv_name         => cv_msg_005a04_113
                        ,iv_token_name1  => cv_tkn_lookup_type
                        ,iv_token_value1 => ct_lc_fb_file_name
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
--
      END;
    -- �p�����[�^�DFB�t�@�C������NULL�łȂ���΃p�����[�^.FB�t�@�C������ݒ�
    ELSE
      l_fb_file_name_tab(0) := iv_fb_file_name;
    END IF;
--
    -- �擾�����A�捞�Ώۂ�FB�t�@�C���������b�Z�[�W�o�͂���B
    <<loop_message>>
    FOR ln_count IN l_fb_file_name_tab.FIRST..l_fb_file_name_tab.LAST LOOP
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cfr
                      ,iv_name         => cv_msg_005a04_029
                      ,iv_token_name1  => cv_tkn_file_name
                      ,iv_token_value1 => l_fb_file_name_tab( ln_count )
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
    END LOOP loop_message;
    -- ���s
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    -- OUT�p�����[�^�ɐݒ�
    o_fb_file_name_tab := l_fb_file_name_tab;
--
    --==============================================================
    -- �萔�����x�z�̎擾
    --==============================================================
    BEGIN
      SELECT abcl.tolerance_limit AS tolerance_limit
      INTO   gt_tolerance_limit
      FROM   ap_bank_charges      abc   -- ��s�萔��
            ,ap_bank_charge_lines abcl  -- ��s�萔������
      WHERE  abc.bank_charge_id    = abcl.bank_charge_id  -- ����ID
      AND    abc.transfer_priority = cv_ar                -- �D��x
-- Mod 2013/07/22 Ver1.01 Start
--      AND    gd_process_date BETWEEN NVL( abcl.start_date, gd_process_date )  -- �J�n��
--                                 AND NVL( abcl.end_date  , gd_process_date )  -- �I����
      AND    abcl.start_date                          <= gd_process_date  -- �J�n��
      AND    NVL( abcl.end_date, gd_process_date + 1 ) > gd_process_date  -- �I����
-- Mod 2013/07/22 Ver1.01 End
      AND    abcl.tolerance_limit IS NOT NULL  -- �萔�����x�z��NULL�ȊO
      ;
--
    EXCEPTION
--
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cfr
                      ,iv_name         => cv_msg_005a04_114
-- 2015/05/29 Ver1.02 Add Start
                      ,iv_token_name1  => cv_tkn_receipt_date
                      ,iv_token_value1 => TO_CHAR(gd_process_date, cv_format_date_ymd)
-- 2015/05/29 Ver1.02 Add End
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
    END;
--
-- 2015/05/29 Ver1.02 Add Start
    --==============================================================
    -- �Ǘ��e�[�u���ێ����Ԃ��߂������R�[�h�̍폜
    --==============================================================
    BEGIN
      DELETE FROM XXCFR_CASH_RECEIPTS_NO_CONTROL xcrnc   -- �����ԍ��Ǘ��e�[�u��
      WHERE  xcrnc.receipt_date <= gd_process_date - gn_retention_period  -- �Ɩ����t-�����ԍ��Ǘ��e�[�u���ێ�����
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfr                                                      -- �A�v���P�[�V�����Z�k��
                                             ,iv_name         => cv_msg_005a04_151                                                   -- ���b�Z�[�W
                                             ,iv_token_name1  => cv_tkn_retention_date                                               -- �g�[�N���R�[�h
                                             ,iv_token_value1 => TO_CHAR(gd_process_date - gn_retention_period, cv_format_date_ymd)  -- �g�[�N���F�Ɩ����t-�����ԍ��Ǘ��e�[�u���ێ�����
                                             );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
-- 2015/05/29 Ver1.02 Add End
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
   * Procedure Name   : get_fb_data
   * Description      : FB�t�@�C���捞���� (A-2)
   ***********************************************************************************/
  PROCEDURE get_fb_data(
    i_fb_file_name_tab   IN         fnd_lookup_values_ttype,  -- FB�t�@�C����
    o_rockbox_table_tab  OUT NOCOPY rockbox_table_ttype,      -- FB�f�[�^
    ob_warn_end          OUT NOCOPY BOOLEAN,                  -- �I���X�e�[�^�X����
    ov_errbuf            OUT NOCOPY VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT NOCOPY VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT NOCOPY VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_fb_data'; -- �v���O������
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
    cv_open_mode_r     CONSTANT VARCHAR2(1) := 'r';   -- �t�@�C���I�[�v�����[�h�i�ǂݍ��݁j
    cv_div_header      CONSTANT VARCHAR2(1) := '1';   -- FB�f�[�^�w�b�_��
    cv_div_data        CONSTANT VARCHAR2(1) := '2';   -- FB�f�[�^�f�[�^��
    cv_kind_receipt    CONSTANT VARCHAR2(2) := '03';  -- ��ʃR�[�h
    cv_payment_receipt CONSTANT VARCHAR2(1) := '1';   -- �����敪
    cv_trance_receipt  CONSTANT VARCHAR2(2) := '11';  -- ����敪
-- 2019/02/05 Ver1.03 Add START
    cv_receipt_standard_date_to   CONSTANT VARCHAR2(6) := '310331'; -- �������ϊ� ���1
-- 2019/05/08 Ver1.04 Mod START
--    cv_receipt_standard_date_from CONSTANT VARCHAR2(6) := '310501'; -- �������ϊ� ���2
    cv_receipt_standard_date_from CONSTANT VARCHAR2(6) := '310401'; -- �������ϊ� ���2
-- 2019/05/08 Ver1.04 Mod END
    cn_newnengou_add_year         CONSTANT NUMBER(4)   := 2018;
    cn_heisei_add_year            CONSTANT NUMBER(4)   := 1988;
-- 2019/02/05 Ver1.03 Add END
--
    -- *** ���[�J���ϐ� ***
--
    lf_file_hand        UTL_FILE.FILE_TYPE;  -- �t�@�C���E�n���h���̐錾�i�Ǎ����p�j
    lv_csv_text         VARCHAR2(32000);     -- �t�@�C�����f�[�^���p�ϐ�
    -- �J�E���^
    ln_count            PLS_INTEGER;  -- ���[�v�J�E���^
    ln_read_count       PLS_INTEGER;  -- �ǂݎ�背�R�[�h���̃J�E���^
    ln_line_cnt         PLS_INTEGER;  -- �f�[�^���J�E���^
    -- �w�b�_���ϐ�
    lt_h_kind_code      xxcfr_rockbox_wk.kind_code%TYPE;         -- ��ʃR�[�h
    lt_h_bank_number    xxcfr_rockbox_wk.bank_number%TYPE;       -- ��s�R�[�h
    lt_h_bank_num       xxcfr_rockbox_wk.bank_num%TYPE;          -- �x�X�R�[�h
    lt_h_account_type   xxcfr_rockbox_wk.account_type%TYPE;      -- �������
    lt_h_account_num    xxcfr_rockbox_wk.account_num%TYPE;       -- �����ԍ�
    -- �f�[�^���ϐ�
    lt_l_payment_code   xxcfr_rockbox_wk.payment_code%TYPE;      -- �����敪
    lt_l_trans_code     xxcfr_rockbox_wk.trans_code%TYPE;        -- ����敪
    lt_l_ref_number     xxcfr_rockbox_wk.ref_number%TYPE;        -- �Q�Ɣԍ�
    lt_l_alt_name       xxcfr_rockbox_wk.alt_name%TYPE;          -- �U���˗��l��
    lt_l_comments       xxcfr_rockbox_wk.comments%TYPE;          -- ����
    lt_l_file_name      xxcfr_rockbox_wk.in_file_name%TYPE;      -- �t�@�C����
    lt_l_receipt_date   ar_cash_receipts_all.receipt_date%TYPE;  -- ������
    lt_l_amount         ar_cash_receipts_all.amount%TYPE;        -- �����z
    lv_l_receipt_date   VARCHAR2(20);                            -- ������(�ꎞ�i�[)
    lv_l_amount         VARCHAR2(20);                            -- �����z(�ꎞ�i�[)
--
    lb_open_error      BOOLEAN;  -- �t�@�C��OPEN�G���[
    lb_validate_error  BOOLEAN;  -- �Ó����G���[
--
    l_wk_tab           rockbox_table_ttype;  -- �w�b�_���A�f�[�^���i�[�p
    -- *** ���[�J���E�J�[�\�� ***
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
    -- ������
    -- �߂�l
    ov_errbuf := NULL;
    ov_errmsg := NULL;
    -- 
    ob_warn_end := cb_false;  -- �I���X�e�[�^�X����
    ln_line_cnt := 0;         -- FB�t�@�C���̓��A�捞�Ώۂ̃��R�[�h��
--
    -- �ǂݎ��Ώۂ�FB�t�@�C�������[�v
    <<loop_get_fb_data>>
    FOR ln_count IN i_fb_file_name_tab.FIRST..i_fb_file_name_tab.LAST LOOP
--
      BEGIN
--
        -- ������
        lb_open_error := cb_false;
        -- �t�@�C�����J��
        lf_file_hand := UTL_FILE.FOPEN(
                          location  => gt_prf_fb_path
                         ,filename  => i_fb_file_name_tab(ln_count)
                         ,open_mode => cv_open_mode_r
                        );
--
      EXCEPTION
--
        WHEN UTL_FILE.INVALID_OPERATION THEN  -- �t�@�C�����J���Ȃ�(�����A���݂��Ȃ�)
--
          -- �t�@�C�����J���Ă��������
          IF UTL_FILE.IS_OPEN ( lf_file_hand ) THEN
            UTL_FILE.FCLOSE( lf_file_hand ) ;
          END IF;
--
          -- �t�@�C�����Ȃ��|���o��
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_cfr
                          ,iv_name         => cv_msg_005a04_039
                          ,iv_token_name1  => cv_tkn_file_name
                          ,iv_token_value1 => i_fb_file_name_tab(ln_count)
                          ,iv_token_name2  => cv_tkn_file_path
                          ,iv_token_value2 => gt_prf_fb_path
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg
          );
--
          -- �t�@�C��OPEN���ɃG���[����
          lb_open_error := cb_true;
          ob_warn_end   := cb_true;  -- �R���J�����g���x���I���ɂ���
--
        WHEN OTHERS THEN
--
          -- �t�@�C�����J���Ă��������
          IF UTL_FILE.IS_OPEN ( lf_file_hand ) THEN
            UTL_FILE.FCLOSE( lf_file_hand ) ;
          END IF;
--
          RAISE global_api_expt;
      END;
--
      -- �t�@�C�����J�����Ƃ�
      IF NOT( lb_open_error ) THEN
--
        -- �ǂݍ��񂾃��R�[�h����������
        ln_read_count := 0;
--
        -- �t�@�C�����̃f�[�^��1���R�[�h���ǂݎ��
        <<loop_get_data>>
        LOOP
--
          BEGIN
--
            -- �t�@�C�����̃f�[�^��ǂݎ��܂��B�t�@�C�����Ƀf�[�^���Ȃ���΁A��O�I��(NO_DATA_FOUND)
            UTL_FILE.GET_LINE(
              file   => lf_file_hand
             ,buffer => lv_csv_text
            );
--
            -- �ǂݍ��񂾃��R�[�h�����J�E���g�A�b�v
            ln_read_count := ln_read_count + 1;
--
            -- �w�b�_��
            IF   ( SUBSTRB( lv_csv_text, 1, 1 ) = cv_div_header ) THEN
              lt_h_kind_code    := SUBSTRB( lv_csv_text, 2 , 2  );  -- ��ʃR�[�h
              lt_h_bank_number  := SUBSTRB( lv_csv_text, 23, 4  );  -- ��s�R�[�h
              lt_h_bank_num     := SUBSTRB( lv_csv_text, 42, 3  );  -- �x�X�R�[�h
              lt_h_account_type := SUBSTRB( lv_csv_text, 63, 1  );  -- �������
              lt_h_account_num  := SUBSTRB( lv_csv_text, 64, 10 );  -- �����ԍ�
            -- �f�[�^��
            ELSIF( SUBSTRB( lv_csv_text, 1, 1 ) = cv_div_data ) THEN
--
              -- �Ó����G���[�`�F�b�N��������
              lb_validate_error := cb_false;
--
              -- FB�t�@�C���̃f�[�^���擾����
              lt_l_ref_number   := SUBSTRB( lv_csv_text, 2 , 8  );            -- �Ɖ�ԍ�
              lv_l_receipt_date := SUBSTRB( lv_csv_text, 10, 6  );            -- ������
              lt_l_payment_code := SUBSTRB( lv_csv_text, 22, 1  );            -- �����敪
              lt_l_trans_code   := SUBSTRB( lv_csv_text, 23, 2  );            -- ����敪
              lv_l_amount       := SUBSTRB( lv_csv_text, 25, 12 );            -- �����z
              lt_l_alt_name     := RTRIM( SUBSTRB( lv_csv_text, 82 , 48 ) );  -- �U���˗��l
              lt_l_comments     := RTRIM( SUBSTRB( lv_csv_text, 160, 20 ) );  -- ����
              lt_l_file_name    := SUBSTRB( i_fb_file_name_tab( ln_count )
                                          , 1
                                          , INSTRB( i_fb_file_name_tab( ln_count )
                                                  , cv_msg_dott
                                           ) - 1
                                   );                                  -- �t�@�C����
--
              -- �������ׂł���Ƃ��́A�z��Ɋi�[����B
              IF ( ( lt_h_kind_code    = cv_kind_receipt    )  -- ��ʃR�[�h
               AND ( lt_l_payment_code = cv_payment_receipt )  -- �����敪
               AND ( lt_l_trans_code   = cv_trance_receipt  )  -- ����敪
              ) THEN
--
                -- �Ώی������J�E���g�A�b�v
                gn_target_cnt := gn_target_cnt + 1;
--
                -- �f�[�^�̑Ó����`�F�b�N
                -- �P�D������
                -- �����(������)��NULL�̎��̓G���[���b�Z�[�W���o�͂���
                IF( lv_l_receipt_date IS NULL) THEN
                  -- NULL�l�G���[
                  gv_out_msg := xxccp_common_pkg.get_msg(
                                   iv_application  => cv_msg_kbn_cfr
                                  ,iv_name         => cv_msg_005a04_119
                                  ,iv_token_name1  => cv_tkn_receipt_date
                                  ,iv_token_value1 => lv_l_receipt_date
                                  ,iv_token_name2  => cv_tkn_ref_number
                                  ,iv_token_value2 => lt_l_ref_number
                                 );
                  FND_FILE.PUT_LINE(
                     which  => FND_FILE.OUTPUT
                    ,buff   => gv_out_msg
                  );
--
                  lb_validate_error := cb_true;            -- �Ó����G���[���́A�z��Ɋi�[���Ȃ��B
--
                -- �����(������)��NULL�ȊO�̎��͓��t�ɕϊ�����
                ELSE
--
                  BEGIN
--
-- 2019/02/05 Ver1.03 Mod START
--                    lt_l_receipt_date := TO_DATE( lv_l_receipt_date
--                                                , cv_format_rmd
--                                                , cv_format_nls_cal
--                                         );
                    --�������ϊ� 310331�ȉ��̏ꍇ
                    IF( lv_l_receipt_date <= cv_receipt_standard_date_to )
                      THEN
                        lt_l_receipt_date := TO_DATE(
                                               ( TO_CHAR( TO_NUMBER( SUBSTRB( lv_l_receipt_date, 1, 2) + cn_newnengou_add_year ))
                                               || SUBSTRB( lv_l_receipt_date, 3, 4 ) ) , 'YYYYMMDD'
                                             );
                    --�������ϊ� 310501�ȏ�̏ꍇ
                    ELSIF (lv_l_receipt_date >= cv_receipt_standard_date_from )
                      THEN
                        lt_l_receipt_date := TO_DATE(
                                               ( TO_CHAR( TO_NUMBER( SUBSTRB(lv_l_receipt_date , 1, 2) + cn_heisei_add_year ))
                                               || SUBSTRB( lv_l_receipt_date, 3, 4 ) ) , 'YYYYMMDD'
                                             );
                    ELSE
                      lt_l_receipt_date := TO_DATE( lv_l_receipt_date
                                                  , cv_format_rmd
                                                  , cv_format_nls_cal
                                           );
                    END IF;
-- 2019/02/05 Ver1.03 Mod END
                  EXCEPTION
                    WHEN OTHERS THEN
                      -- ���t�ϊ��G���[
                      gv_out_msg := xxccp_common_pkg.get_msg(
                                       iv_application  => cv_msg_kbn_cfr
                                      ,iv_name         => cv_msg_005a04_119
                                      ,iv_token_name1  => cv_tkn_receipt_date
                                      ,iv_token_value1 => lv_l_receipt_date
                                      ,iv_token_name2  => cv_tkn_ref_number
                                      ,iv_token_value2 => lt_l_ref_number
                                     );
                      FND_FILE.PUT_LINE(
                         which  => FND_FILE.OUTPUT
                        ,buff   => gv_out_msg
                      );
--
                      lb_validate_error := cb_true;            -- �Ó����G���[���́A�z��Ɋi�[���Ȃ��B
--
                  END;
--
                END IF;
--
                -- �Q�D�����z
                -- ���͋��z(�����z)��NULL�̎��̓G���[���b�Z�[�W���o�͂���
                IF ( lv_l_amount IS NULL ) THEN
                  -- NULL�l�G���[
                  gv_out_msg := xxccp_common_pkg.get_msg(
                                   iv_application  => cv_msg_kbn_cfr
                                  ,iv_name         => cv_msg_005a04_120
                                  ,iv_token_name1  => cv_tkn_amount
                                  ,iv_token_value1 => lv_l_amount
                                  ,iv_token_name2  => cv_tkn_ref_number
                                  ,iv_token_value2 => lt_l_ref_number
                                 );
                  FND_FILE.PUT_LINE(
                     which  => FND_FILE.OUTPUT
                    ,buff   => gv_out_msg
                  );
--
                  lb_validate_error := cb_true;            -- �Ó����G���[���́A�z��Ɋi�[���Ȃ��B
--
                -- ���͋��z(�����z)��NULL�ȊO�̎��͐��l�ɕϊ�����
                ELSE
--
                  BEGIN
--
                    lt_l_amount       := TO_NUMBER( lv_l_amount );
--
                  EXCEPTION
                    WHEN OTHERS THEN
                      -- ���l�ϊ��G���[
                      gv_out_msg := xxccp_common_pkg.get_msg(
                                       iv_application  => cv_msg_kbn_cfr
                                      ,iv_name         => cv_msg_005a04_120
                                      ,iv_token_name1  => cv_tkn_amount
                                      ,iv_token_value1 => lv_l_amount
                                      ,iv_token_name2  => cv_tkn_ref_number
                                      ,iv_token_value2 => lt_l_ref_number
                                     );
                      FND_FILE.PUT_LINE(
                         which  => FND_FILE.OUTPUT
                        ,buff   => gv_out_msg
                      );
--
                      lb_validate_error := cb_true;            -- �Ó����G���[���́A�z��Ɋi�[���Ȃ��B
--
                  END;
--
                END IF;
--
                -- �Ó����`�F�b�N�ŃG���[���������Ă���Ƃ��́A�x���������J�E���g�A�b�v����B
                IF ( lb_validate_error ) THEN
                  gn_warn_cnt := gn_warn_cnt   + 1;  -- �x���������J�E���g�A�b�v
                -- �Ó����`�F�b�N�ŃG���[���������Ă��Ȃ��Ƃ��́A�z��Ɋi�[����B
                ELSE
--
                  ln_line_cnt := ln_line_cnt + 1;
--
                  l_wk_tab(ln_line_cnt).kind_code    := lt_h_kind_code;     -- ��ʃR�[�h
                  l_wk_tab(ln_line_cnt).bank_number  := lt_h_bank_number;   -- ��s�R�[�h
                  l_wk_tab(ln_line_cnt).bank_num     := lt_h_bank_num;      -- �x�X�R�[�h
                  l_wk_tab(ln_line_cnt).account_type := lt_h_account_type;  -- �������
                  l_wk_tab(ln_line_cnt).account_num  := lt_h_account_num;   -- �����ԍ�
                  l_wk_tab(ln_line_cnt).ref_number   := lt_l_ref_number;    -- �Q�Ɣԍ�
                  l_wk_tab(ln_line_cnt).payment_code := lt_l_payment_code;  -- �����敪
                  l_wk_tab(ln_line_cnt).trans_code   := lt_l_trans_code;    -- ����敪
                  l_wk_tab(ln_line_cnt).alt_name     := lt_l_alt_name;      -- �U���˗��l
                  l_wk_tab(ln_line_cnt).receipt_date := lt_l_receipt_date;  -- ������
                  l_wk_tab(ln_line_cnt).amount       := lt_l_amount;        -- �����z
                  l_wk_tab(ln_line_cnt).comments     := lt_l_comments;      -- ����
                  l_wk_tab(ln_line_cnt).cash_flag    := cv_need;            -- �����v�ۃt���O(�v)
                  l_wk_tab(ln_line_cnt).apply_flag   := cv_need;            -- �����v�ۃt���O(�v)
                  l_wk_tab(ln_line_cnt).in_file_name := lt_l_file_name;     -- �t�@�C����
--
                END IF;
--
              END IF;
            -- �g���[�����A�G���h��
            ELSE
              NULL;
            END IF;
--
          EXCEPTION
--
            WHEN NO_DATA_FOUND THEN
--
              -- �t�@�C�����J���Ă��������
              IF UTL_FILE.IS_OPEN ( lf_file_hand ) THEN
                UTL_FILE.FCLOSE( lf_file_hand ) ;
              END IF;
--
              -- �t�@�C�����Ƀf�[�^�����݂��Ȃ��ꍇ�́A���b�Z�[�W�o��
              IF (ln_read_count = 0) THEN
--
                -- �f�[�^���Ȃ��|���o��
                gv_out_msg := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_cfr
                                ,iv_name         => cv_msg_005a04_122
                                ,iv_token_name1  => cv_tkn_file_name
                                ,iv_token_value1 => i_fb_file_name_tab( ln_count )
                               );
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.OUTPUT
                  ,buff   => gv_out_msg
                );
--
                ob_warn_end   := cb_true;  -- �R���J�����g���x���I���ɂ���
--
              END IF;
--
              EXIT;  -- loop_get_data��E�o�Bloop_get_fb_data�̎����R�[�h�ցB
--
            WHEN OTHERS THEN
--
              -- �t�@�C�����J���Ă��������
              IF UTL_FILE.IS_OPEN ( lf_file_hand ) THEN
                UTL_FILE.FCLOSE( lf_file_hand ) ;
              END IF;
--
              RAISE global_api_expt;
          END;
--
        END LOOP loop_get_data;  -- FB�f�[�^�擾���[�v
--
      END IF;  -- �t�@�C��OPEN�G���[
--
    END LOOP loop_get_fb_data;  -- �t�@�C��OPEN���[�v
--
    -- OUT�p�����[�^�ɐݒ�
    o_rockbox_table_tab := l_wk_tab;
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
  END get_fb_data;
--
-- 2015/05/29 Ver1.02 Add Start
  /**********************************************************************************
   * Procedure Name   : get_bank_info
   * Description      : ����24���ԉ���s���擾���� (A-11)
   ***********************************************************************************/
  PROCEDURE get_bank_info(
    it_bank_number       IN         xxcfr_rockbox_wk.bank_number%TYPE,      -- ��s�R�[�h
    it_receipt_date      IN         xxcfr_rockbox_wk.receipt_date%TYPE,     -- ������(IN)
    ot_receipt_date      OUT NOCOPY xxcfr_rockbox_wk.receipt_date%TYPE,     -- ������(OUT)
    ot_bank_code_flag    OUT NOCOPY VARCHAR2,                               -- 24���ԉ��Ή���s�t���O
    ov_errbuf            OUT NOCOPY VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT NOCOPY VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT NOCOPY VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_bank_info'; -- �v���O������
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
    ct_fb_bank_code24    CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCFR1_FB_BANK_CODE24';  -- �Q�ƃ^�C�v�uFB24���ԉ��Ή���s�v
--
    -- *** ���[�J���ϐ� ***
    cn_count_bank_number NUMBER;              -- 24���ԉ��Ή���s�J�E���g
--
    -- *** ���[�J���E�J�[�\�� ***
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
    -- ������
    -- �߂�l
    ov_errbuf := NULL;
    ov_errmsg := NULL;
    ot_receipt_date      := gd_process_date;   -- ������(OUT)�ɋƖ����t���Z�b�g
    ot_bank_code_flag    := cv_flag_n;         -- 24���ԉ��Ή���s�t���O�F'N'
    cn_count_bank_number := 0;
--
    -- 24���ԉ��Ή���s�擾
    SELECT COUNT(flvv.lookup_code)  AS count_bank_number  -- ��s�R�[�h�J�E���g
    INTO   cn_count_bank_number
    FROM   fnd_lookup_values_vl flvv  -- �Q�ƕ\
    WHERE  flvv.lookup_type  = ct_fb_bank_code24   -- �Q�ƃ^�C�v
    AND    flvv.lookup_code  = it_bank_number      -- ��s�R�[�h
    AND    flvv.enabled_flag = cv_flag_y           -- �L���t���O
    AND    it_receipt_date BETWEEN NVL( flvv.start_date_active, it_receipt_date )  -- �L����(��)
                               AND NVL( flvv.end_date_active  , it_receipt_date )  -- �L����(��)
    ;
--
    -- 24���ԉ��Ή���s�̏ꍇ
    IF ( cn_count_bank_number > 0) THEN
      -- ������(OUT)�ɓ��������Z�b�g
      ot_receipt_date   := it_receipt_date;
      -- 24���ԉ��Ή���s�t���O��'Y'�ɂ���
      ot_bank_code_flag := cv_flag_y;
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
  END get_bank_info;
--
-- 2015/05/29 Ver1.02 Add End
  /**********************************************************************************
   * Procedure Name   : get_receive_method
   * Description      : �x�����@�擾���� (A-3)
   ***********************************************************************************/
  PROCEDURE get_receive_method(
    it_bank_number         IN         xxcfr_rockbox_wk.bank_number%TYPE,          -- ��s�R�[�h
    it_bank_num            IN         xxcfr_rockbox_wk.bank_num%TYPE,             -- �x�X�R�[�h
    it_account_type        IN         xxcfr_rockbox_wk.account_type%TYPE,         -- �������
    it_account_num         IN         xxcfr_rockbox_wk.account_num%TYPE,          -- �����ԍ�
    it_ref_number          IN         xxcfr_rockbox_wk.ref_number%TYPE,           -- �Q�Ɣԍ�
    ot_receipt_method_id   OUT NOCOPY xxcfr_rockbox_wk.receipt_method_id%TYPE,    -- �x�����@ID
    ot_receipt_method_name OUT NOCOPY xxcfr_rockbox_wk.receipt_method_name%TYPE,  -- �x�����@����
    ot_cash_flag           OUT NOCOPY xxcfr_rockbox_wk.cash_flag%TYPE,            -- �����v�ۃt���O
    ot_apply_flag          OUT NOCOPY xxcfr_rockbox_wk.apply_flag%TYPE,           -- �����v�ۃt���O
    ov_errbuf              OUT NOCOPY VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode             OUT NOCOPY VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg              OUT NOCOPY VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_receive_method'; -- �v���O������
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
    cv_staus_a           CONSTANT VARCHAR2(1)  := 'A';
    cv_my_part           CONSTANT VARCHAR2(10) := 'INTERNAL';
    cv_account_num_left  CONSTANT VARCHAR2(10) := '0000000000';
--
    -- *** ���[�J���ϐ� ***
    ln_count   PLS_INTEGER;  -- ���[�v�J�E���^
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �x�����@�擾
    CURSOR get_receipt_method_cur(
             p_bank_number  xxcfr_rockbox_wk.bank_number%TYPE   -- ��s�R�[�h
            ,p_bank_num     xxcfr_rockbox_wk.bank_num%TYPE      -- �x�X�R�[�h
            ,p_account_type xxcfr_rockbox_wk.account_type%TYPE  -- �������
            ,p_account_num  xxcfr_rockbox_wk.account_num%TYPE   -- �����ԍ�
           )
    IS
      SELECT arm.receipt_method_id  AS receipt_method_id    -- �x�����@����ID
            ,arm.name               AS receipt_method_name  -- �x�����@����
            ,arm.attribute1         AS receipt_method_owner -- �x�����@�������_
            ,aba.attribute1         AS bank_account_owner   -- �������L����
      FROM   ar_receipt_methods  arm  -- AR�x�����@�e�[�u��
            ,ap_bank_branches    abb  -- ��s�x�X
            ,ap_bank_accounts    aba  -- ��s�������}���`�I���O�r���[
            ,ar_lockboxes        ala  -- ���b�N�{�b�N�X�}���`�I���O�r���[
      WHERE  arm.receipt_method_id = ala.receipt_method_id        -- ����ID
      AND    aba.bank_account_num  = ala.bank_origination_number  -- ����ID
      AND    abb.bank_branch_id    = aba.bank_branch_id           -- ����ID
      AND    abb.bank_number       = p_bank_number    -- ��s�R�[�h
      AND    abb.bank_num          = p_bank_num       -- �x�X�R�[�h
      AND    aba.bank_account_type = p_account_type   -- �������
      AND    SUBSTRB(cv_account_num_left   -- FB�f�[�^�͍��[�����߂ō쐬����Ă��邽�߁B
                  || aba.bank_account_num  -- �����ԍ���7���ȊO�ł��Ή��\�Ƃ����B
                   ,-10
             )                     = p_account_num    -- �����ԍ�
      AND    aba.set_of_books_id   = gt_set_of_bks_id  -- ��v����ID
      AND    ala.status            = cv_staus_a  -- �X�e�[�^�X
      AND    aba.account_type      = cv_my_part  -- ��������
      AND    TRUNC( SYSDATE ) BETWEEN NVL( arm.start_date, TRUNC( SYSDATE ) )  -- �J�n��
                                  AND NVL( arm.end_date  , TRUNC( SYSDATE ) )  -- �I����
      AND    TRUNC( SYSDATE )       < NVL( aba.inactive_date, TRUNC( SYSDATE ) + 1 )  -- ��s�����̖�����
      ;
--
    TYPE ttype_get_rec_method IS TABLE OF get_receipt_method_cur%ROWTYPE
                                 INDEX BY PLS_INTEGER;
    l_get_rec_method_tab ttype_get_rec_method;
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
    -- ������
    -- �߂�l
    ov_errbuf := NULL;
    ov_errmsg := NULL;
    ot_receipt_method_id   := NULL;        -- �x�����@����ID
    ot_receipt_method_name := NULL;        -- �x�����@����
    ot_cash_flag           := cv_no_need;  -- �����v�ۃt���O(��)
    ot_apply_flag          := cv_no_need;  -- �����v�ۃt���O(��)
    -- �z��
    l_get_rec_method_tab.DELETE;
--
    OPEN get_receipt_method_cur(
      p_bank_number  => it_bank_number   -- ��s�R�[�h
     ,p_bank_num     => it_bank_num      -- �x�X�R�[�h
     ,p_account_type => it_account_type  -- �������
     ,p_account_num  => it_account_num   -- �����ԍ�
    );
--
    FETCH get_receipt_method_cur BULK COLLECT INTO l_get_rec_method_tab;
    CLOSE get_receipt_method_cur;
--
    IF   ( l_get_rec_method_tab.COUNT < 1 ) THEN
--
      -- �x�����@���擾�ł��Ȃ������|���o��
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cfr
                      ,iv_name         => cv_msg_005a04_115
                      ,iv_token_name1  => cv_tkn_bank_number
                      ,iv_token_value1 => it_bank_number
                      ,iv_token_name2  => cv_tkn_bank_num
                      ,iv_token_value2 => it_bank_num
                      ,iv_token_name3  => cv_tkn_bank_account_type
                      ,iv_token_value3 => it_account_type
                      ,iv_token_name4  => cv_tkn_bank_account_num
                      ,iv_token_value4 => it_account_num
                      ,iv_token_name5  => cv_tkn_ref_number
                      ,iv_token_value5 => it_ref_number
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
--
      gn_warn_cnt := gn_warn_cnt + 1;  -- �x���������J�E���g�A�b�v
--
    ELSIF( l_get_rec_method_tab.COUNT > 1 ) THEN
--
      -- �x�����@�������擾�ł����|���o��
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cfr
                      ,iv_name         => cv_msg_005a04_126
                      ,iv_token_name1  => cv_tkn_bank_number
                      ,iv_token_value1 => it_bank_number
                      ,iv_token_name2  => cv_tkn_bank_num
                      ,iv_token_value2 => it_bank_num
                      ,iv_token_name3  => cv_tkn_bank_account_type
                      ,iv_token_value3 => it_account_type
                      ,iv_token_name4  => cv_tkn_bank_account_num
                      ,iv_token_value4 => it_account_num
                      ,iv_token_name5  => cv_tkn_ref_number
                      ,iv_token_value5 => it_ref_number
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      -- �����擾�����x�����@���o��
      <<message_loop>>
      FOR ln_count IN l_get_rec_method_tab.FIRST..l_get_rec_method_tab.LAST LOOP
        gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cfr
                        ,iv_name         => cv_msg_005a04_127
                        ,iv_token_name1  => cv_tkn_receipt_method
                        ,iv_token_value1 => l_get_rec_method_tab(ln_count).receipt_method_name
                        ,iv_token_name2  => cv_tkn_receipt_method_owner
                        ,iv_token_value2 => l_get_rec_method_tab(ln_count).receipt_method_owner
                        ,iv_token_name3  => cv_tkn_bank_account_owner
                        ,iv_token_value3 => l_get_rec_method_tab(ln_count).bank_account_owner
                       );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
      END LOOP message_loop;
--
      gn_warn_cnt := gn_warn_cnt + 1;  -- �x���������J�E���g�A�b�v
--
    ELSE
      -- ����Ɏ擾�ł����ꍇ
      ot_receipt_method_id   := l_get_rec_method_tab(l_get_rec_method_tab.FIRST).receipt_method_id;    -- �x�����@ID
      ot_receipt_method_name := l_get_rec_method_tab(l_get_rec_method_tab.FIRST).receipt_method_name;  -- �x�����@����
      ot_cash_flag           := cv_need;                                                               -- �����v�ۃt���O(�v)
      ot_apply_flag          := cv_need;                                                               -- �����v�ۃt���O(�v)
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
--
      IF ( get_receipt_method_cur%ISOPEN ) THEN
        CLOSE get_receipt_method_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_receive_method;
--
  /**********************************************************************************
   * Procedure Name   : get_receipt_customer
   * Description      : ������ڋq�擾���� (A-4)
   ***********************************************************************************/
  PROCEDURE get_receipt_customer(
    it_alt_name          IN         xxcfr_rockbox_wk.alt_name%TYPE,         -- �U���˗��l��
    it_ref_number        IN         xxcfr_rockbox_wk.ref_number%TYPE,       -- �Q�Ɣԍ�
    ot_cust_account_id   OUT NOCOPY xxcfr_rockbox_wk.cust_account_id%TYPE,  -- �ڋqID
    ot_account_number    OUT NOCOPY xxcfr_rockbox_wk.account_number%TYPE,   -- �ڋq����
    ot_apply_flag        OUT NOCOPY xxcfr_rockbox_wk.apply_flag%TYPE,       -- �����v�ۃt���O
    ov_errbuf            OUT NOCOPY VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT NOCOPY VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT NOCOPY VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_receipt_customer'; -- �v���O������
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
    cv_status_a  CONSTANT VARCHAR2(1) := 'A';
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
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
    -- ������
    -- �߂�l
    ov_errbuf := NULL;
    ov_errmsg := NULL;
    ot_cust_account_id := NULL;        -- �ڋqID
    ot_account_number  := NULL;        -- �ڋq�ԍ�
    ot_apply_flag      := cv_no_need;  -- �����v�ۃt���O(��)
--
    -- �����ڋq�擾
    SELECT hca.cust_account_id  AS cust_account_id  -- �ڋqID
          ,xcan.account_number  AS account_number   -- �ڋq�ԍ�
    INTO   ot_cust_account_id
          ,ot_account_number
    FROM   xxcfr_cust_alt_name  xcan  -- �U���˗��l�}�X�^
          ,hz_cust_accounts     hca   -- �ڋq�}�X�^
    WHERE  xcan.alt_name       = it_alt_name         -- �U���˗��l��
    AND    xcan.account_number = hca.account_number  -- �ڋq�ԍ�
    AND    hca.status          = cv_status_a         -- �X�e�[�^�X(�L��)
    ;
--
    -- ����Ɏ擾�ł����ꍇ
    ot_apply_flag := cv_need;     -- �����v�ۃt���O(�v)
--
  EXCEPTION
    -- �Ώۃf�[�^�Ȃ�
    WHEN NO_DATA_FOUND THEN
      -- ������ڋq���擾�ł��Ȃ������|���o��
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cfr
                      ,iv_name         => cv_msg_005a04_116
                      ,iv_token_name1  => cv_tkn_alt_name
                      ,iv_token_value1 => it_alt_name
                      ,iv_token_name2  => cv_tkn_ref_number
                      ,iv_token_value2 => it_ref_number
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      gn_no_customer_cnt := gn_no_customer_cnt + 1;  -- �s�������������J�E���g�A�b�v
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
  END get_receipt_customer;
--
  /**********************************************************************************
   * Procedure Name   : get_fb_out_acct_number
   * Description      : ���������ΏۊO�ڋq�擾���� (A-5)
   ***********************************************************************************/
  PROCEDURE get_fb_out_acct_number(
    it_account_number    IN         xxcfr_rockbox_wk.account_number%TYPE,  -- �ڋq�ԍ�
-- 2015/05/29 Ver1.02 Add Start
    it_receipt_date      IN         xxcfr_rockbox_wk.receipt_date%TYPE,    -- ������
-- 2015/05/29 Ver1.02 Add End
    ot_apply_flag        OUT NOCOPY xxcfr_rockbox_wk.apply_flag%TYPE,      -- �����v�ۃt���O
    ov_errbuf            OUT NOCOPY VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT NOCOPY VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT NOCOPY VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_fb_out_acct_number'; -- �v���O������
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
    ln_count   PLS_INTEGER;
--
    -- *** ���[�J���E�J�[�\�� ***
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
    -- ������
    -- �߂�l
    ov_errbuf := NULL;
    ov_errmsg := NULL;
    ot_apply_flag := cv_need;  -- �����v�ۃt���O(�v)
    --
    ln_count  := 0;
--
    --���������ΏۊO�ڋq�擾
    SELECT COUNT(ROWNUM) AS cnt
    INTO   ln_count
    FROM   fnd_lookup_values_vl flvv  -- �Q�ƃ^�C�v�}�X�^
    WHERE  flvv.lookup_type  = ct_out_acct_number  -- �Q�ƃ^�C�v
    AND    flvv.lookup_code  = it_account_number   -- �Q�ƃR�[�h
    AND    flvv.enabled_flag = cv_flag_y           -- �L���t���O
-- 2015/05/29 Ver1.02 Mod Start
--    AND    gd_process_date BETWEEN NVL( flvv.start_date_active, gd_process_date )  -- �L����(��)
--                               AND NVL( flvv.end_date_active  , gd_process_date )  -- �L����(��)
    AND    it_receipt_date BETWEEN NVL( flvv.start_date_active, it_receipt_date )
                               AND NVL( flvv.end_date_active  , it_receipt_date )
-- 2015/05/29 Ver1.02 Mod End
    ;
--
    -- �Ώۂ��擾�ł���ꍇ
    IF ( ln_count > 0 )THEN
      ot_apply_flag := cv_no_need;  -- �����v�ۃt���O(��)
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
  END get_fb_out_acct_number;
--
  /**********************************************************************************
   * Procedure Name   : get_trx_amount
   * Description      : �Ώۍ����z���� (A-6)
   ***********************************************************************************/
  PROCEDURE get_trx_amount(
    it_cust_account_id        IN         xxcfr_rockbox_wk.cust_account_id%TYPE,         -- �ڋqID
    it_amount                 IN         xxcfr_rockbox_wk.amount%TYPE,                  -- �����z
-- 2015/05/29 Ver1.02 Add Start
    it_receipt_date           IN         xxcfr_rockbox_wk.receipt_date%TYPE,            -- ������
    it_bank_code_flag         IN         VARCHAR2,                                      -- 24���ԉ��Ή���s�t���O
-- 2015/05/29 Ver1.02 Add End
    ot_apply_flag             OUT NOCOPY xxcfr_rockbox_wk.apply_flag%TYPE,              -- �����v�ۃt���O
    ot_factor_discount_amount OUT NOCOPY xxcfr_rockbox_wk.factor_discount_amount%TYPE,  -- �萔��
    ot_apply_trx_count        OUT NOCOPY xxcfr_rockbox_wk.apply_trx_count%TYPE,         -- �����Ώی���
    ov_errbuf                 OUT NOCOPY VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                OUT NOCOPY VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                 OUT NOCOPY VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_trx_amount'; -- �v���O������
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
    cv_op    CONSTANT VARCHAR2(2) := 'OP';   -- �I�[�v��
    cv_rec   CONSTANT VARCHAR2(3) := 'REC';  -- ���|�^������
-- 2015/05/29 Ver1.02 Add Start
    cv_ar  CONSTANT VARCHAR2(2)   := 'AR';
-- 2015/05/29 Ver1.02 Add End
--
    -- *** ���[�J���ϐ� ***
    lt_amount_due_remaining  ar_payment_schedules_all.amount_due_remaining%TYPE := NULL;  -- ������c��
    lt_apply_trx_count       xxcfr_rockbox_wk.apply_trx_count%TYPE              := NULL;  -- �����Ώی���
-- 2015/05/29 Ver1.02 Add Start
    lt_tolerance_limit       ap_bank_charge_lines.tolerance_limit%TYPE          := NULL;  -- �萔�����x�z
-- 2015/05/29 Ver1.02 Add End
--
    -- *** ���[�J���E�J�[�\�� ***
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
    -- ������
    -- �߂�l
    ov_errbuf := NULL;
    ov_errmsg := NULL;
    ot_apply_flag             := cv_no_need;  -- �����v�ۃt���O(��)
    ot_factor_discount_amount := NULL;        -- �萔��
    ot_apply_trx_count        := NULL;        -- �����Ώی���
-- 2015/05/29 Ver1.02 Add Start
    lt_tolerance_limit        := NULL;        -- �萔�����x�z
--
    -- 24���ԉ��Ή���s�̏ꍇ
    IF ( it_bank_code_flag = cv_flag_y ) THEN
      -- �萔�����x�z��������Ŏ擾������
      BEGIN
        SELECT abcl.tolerance_limit AS tolerance_limit
        INTO   lt_tolerance_limit
        FROM   ap_bank_charges      abc   -- ��s�萔��
              ,ap_bank_charge_lines abcl  -- ��s�萔������
        WHERE  abc.bank_charge_id    = abcl.bank_charge_id  -- ����ID
        AND    abc.transfer_priority = cv_ar                -- �D��x
        AND    abcl.start_date                          <= it_receipt_date  -- �J�n��
        AND    NVL( abcl.end_date, it_receipt_date + 1 ) > it_receipt_date  -- �I����
        AND    abcl.tolerance_limit IS NOT NULL  -- �萔�����x�z��NULL�ȊO
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cfr
                        ,iv_name         => cv_msg_005a04_114
                        ,iv_token_name1  => cv_tkn_receipt_date
                        ,iv_token_value1 => TO_CHAR(it_receipt_date, cv_format_date_ymd)
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
--
      END;
    -- 24���ԉ��Ή���s�ł͂Ȃ��ꍇ
    ELSIF ( it_bank_code_flag = cv_flag_n ) THEN
      -- �Ɩ����t�Ŏ擾�����萔�����x�z���Z�b�g
      lt_tolerance_limit := gt_tolerance_limit;
    END IF;
-- 2015/05/29 Ver1.02 Add End
--
    -- ������c���擾
    SELECT SUM( xrctm.amount_due_remaining ) AS amount_due_remaining  -- ������c�����v
          ,COUNT( ROWNUM )                   AS cnt                   -- �����Ώۖ{��
    INTO   lt_amount_due_remaining
          ,lt_apply_trx_count
    FROM   xxcfr_rock_cust_trx_mv   xrctm   -- ���}�e�r���[
          ,xxcfr_cust_hierarchy_mv  xchm    -- �����ڋq�}�e�r���[
    WHERE xchm.bill_account_id = xrctm.bill_to_customer_id  -- ����ID
    AND   xchm.cash_account_id = it_cust_account_id         -- �����ڋqID
    ;
--
    -- �Ώۂ̍������݂��A���萔�������x�z�ȓ��ł��邩�𔻒肵�A�萔�������肷��B
-- 2015/05/29 Ver1.02 Mod Start
--    IF ( ( gt_tolerance_limit >= ABS( lt_amount_due_remaining - it_amount ) ) -- �萔�����x�z >= ABS(������c�����v - �����z)
    IF ( ( lt_tolerance_limit >= ABS( lt_amount_due_remaining - it_amount ) ) -- �萔�����x�z >= ABS(������c�����v - �����z)
-- 2015/05/29 Ver1.02 Mod End
     AND ( lt_apply_trx_count >  0                                          ) -- �����Ώۖ{�� >  0
    ) THEN 
--
      -- ������c�����v�������z�ȏ�ł���Ƃ��́A���̍��z���萔���Ƃ��č쐬����
      IF ( lt_amount_due_remaining >= it_amount ) THEN  -- ������c�����v >= �����z
        ot_factor_discount_amount := lt_amount_due_remaining - it_amount; -- �萔��(������c�����v - �����z)
      ELSE
        ot_factor_discount_amount := 0;                                   -- �[��
      END IF;
--
      ot_apply_trx_count := lt_apply_trx_count;  -- �����Ώی���
      ot_apply_flag      := cv_need;             -- �����v�ۃt���O(�v)
--
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
  END get_trx_amount;
--
  /**********************************************************************************
   * Procedure Name   : exec_cash_api
   * Description      : ����API�N������ (A-7)
   ***********************************************************************************/
  PROCEDURE exec_cash_api(
    it_amount                 IN            xxcfr_rockbox_wk.amount%TYPE,                  -- �����z
    it_factor_discount_amount IN            xxcfr_rockbox_wk.factor_discount_amount%TYPE,  -- �萔��
    it_receipt_number         IN            xxcfr_rockbox_wk.receipt_number%TYPE,          -- �����ԍ�
    it_receipt_date           IN            xxcfr_rockbox_wk.receipt_date%TYPE,            -- ������
    it_cust_account_id        IN            xxcfr_rockbox_wk.cust_account_id%TYPE,         -- �ڋqID
    it_account_number         IN            xxcfr_rockbox_wk.account_number%TYPE,          -- �ڋq�ԍ�
    it_receipt_method_id      IN            xxcfr_rockbox_wk.receipt_method_id%TYPE,       -- �x�����@ID
    it_receipt_method_name    IN            xxcfr_rockbox_wk.receipt_method_name%TYPE,     -- �x�����@��
    it_alt_name               IN            xxcfr_rockbox_wk.alt_name%TYPE,                -- �U���˗��l��
    it_comments               IN            xxcfr_rockbox_wk.comments%TYPE,                -- ����
    it_ref_number             IN            xxcfr_rockbox_wk.ref_number%TYPE,              -- �Q�Ɣԍ�
    iot_apply_flag            IN OUT NOCOPY xxcfr_rockbox_wk.apply_flag%TYPE,              -- �����v�ۃt���O 
    ot_cash_receipt_id        OUT    NOCOPY xxcfr_rockbox_wk.cash_receipt_id%TYPE,         -- ����ID
    ov_errbuf                 OUT    NOCOPY VARCHAR2,  --  �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                OUT    NOCOPY VARCHAR2,  --  ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                 OUT    NOCOPY VARCHAR2)  --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'exec_cash_api'; -- �v���O������
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
    lv_return_status   VARCHAR2(1);
    ln_msg_count       NUMBER;
    lv_msg_data        VARCHAR2(2000);
    l_attribute_rec    ar_receipt_api_pub.attribute_rec_type := NULL;  -- attribute�p
--
    -- *** ���[�J���E�J�[�\�� ***
    cv_status_n  CONSTANT VARCHAR2(1) := 'N';
    cv_status_s  CONSTANT VARCHAR2(1) := 'S';
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
    -- ������
    -- �߂�l
    ov_errbuf := NULL;
    ov_errmsg := NULL;
    ot_cash_receipt_id := NULL;        -- ��������ID
--
    -- �t���t���b�N�X�t�B�[���h�̐ݒ�
    l_attribute_rec.attribute_category := TO_CHAR(gn_org_id);  -- �c�ƒP��
    l_attribute_rec.attribute1         := it_alt_name;         -- �U���˗��l��
--
    -- ��������API�N��
    ar_receipt_api_pub.create_cash(
       p_api_version                 => 1.0
      ,p_init_msg_list               => FND_API.G_TRUE
      ,x_return_status               => lv_return_status
      ,x_msg_count                   => ln_msg_count
      ,x_msg_data                    => lv_msg_data
      ,p_amount                      => it_amount                 -- �����z
      ,p_factor_discount_amount      => it_factor_discount_amount -- �萔��
      ,p_receipt_number              => it_receipt_number         -- �����ԍ�
      ,p_receipt_date                => it_receipt_date           -- ������
      ,p_gl_date                     => it_receipt_date           -- GL�L����
      ,p_customer_id                 => it_cust_account_id        -- �ڋq����ID
      ,p_receipt_method_id           => it_receipt_method_id      -- �������@
      ,p_override_remit_account_flag => cv_status_n               -- ������s�����㏑���t���O(Y/N)
      ,p_attribute_rec               => l_attribute_rec           -- �t���t���b�N�X
      ,p_comments                    => it_comments               -- ����
      ,p_cr_id                       => ot_cash_receipt_id        -- (�߂�l)��������ID
    );
--
    -- ����API�����������Ƃ�
    IF ( lv_return_status = cv_status_s ) THEN
      -- �s�������łȂ���΁A�����������J�E���g�A�b�v
      IF NOT( it_cust_account_id IS NULL ) THEN
        gn_normal_cnt := gn_normal_cnt + 1;
      END IF;
    -- ����API�����s�����Ƃ�
    ELSE
      --�G���[����
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cfr
                     ,iv_name         => cv_msg_005a04_117
                     ,iv_token_name1  => cv_tkn_receipt_number
                     ,iv_token_value1 => it_receipt_number
                     ,iv_token_name2  => cv_tkn_account_number
                     ,iv_token_value2 => it_account_number
                     ,iv_token_name3  => cv_tkn_receipt_method
                     ,iv_token_value3 => it_receipt_method_name
                     ,iv_token_name4  => cv_tkn_receipt_date
                     ,iv_token_value4 => TO_CHAR( it_receipt_date,cv_format_date_ymd )
                     ,iv_token_name5  => cv_tkn_amount
                     ,iv_token_value5 => TO_CHAR( it_amount )
                     ,iv_token_name6  => cv_tkn_ref_number
                     ,iv_token_value6 => it_ref_number
                   );
      -- ����API�G���[���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
--
      -- API�W���G���[���b�Z�[�W�o��
      IF (ln_msg_count = 1) THEN
        -- API�W���G���[���b�Z�[�W���P���̏ꍇ
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => cv_msg_brack_point || lv_msg_data
        );
--
      ELSE
        -- API�W���G���[���b�Z�[�W���������̏ꍇ
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => cv_msg_brack_point || SUBSTRB( FND_MSG_PUB.GET(FND_MSG_PUB.G_FIRST, FND_API.G_FALSE)
                                                   ,1
                                                   ,5000
                                                 )
        );
        ln_msg_count := ln_msg_count - 1;
        
        <<while_loop>>
        WHILE ln_msg_count > 0 LOOP
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => cv_msg_brack_point || SUBSTRB( FND_MSG_PUB.GET(FND_MSG_PUB.G_NEXT, FND_API.G_FALSE)
                                                     ,1
                                                     ,5000
                                                   )
          );
          
          ln_msg_count := ln_msg_count - 1;
          
        END LOOP while_loop;
--
      END IF;
      -- �x���������J�E���g�A�b�v
      gn_warn_cnt := gn_warn_cnt + 1;
      -- �s�������̂Ƃ��́A�s�����������J�E���g�_�E������
      IF ( it_cust_account_id IS NULL ) THEN
        gn_no_customer_cnt := gn_no_customer_cnt - 1;
      END IF;
      -- �����v�ۃt���O(��)
      iot_apply_flag := cv_no_need;
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
  END exec_cash_api;
--
  /**********************************************************************************
   * Procedure Name   : insert_table
   * Description      : ���b�N�{�b�N�X�����������[�N�e�[�u���o�^���� (A-8)
   ***********************************************************************************/
  PROCEDURE insert_table(
    i_rockbox_table_tab IN         rockbox_table_ttype,  -- FB�f�[�^
    ov_errbuf           OUT NOCOPY VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_table'; -- �v���O������
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
    -- ������
    -- �߂�l
    ov_errbuf := NULL;
    ov_errmsg := NULL;
--
    BEGIN
--
      <<insert_loop>>
      FOR ln_count IN i_rockbox_table_tab.FIRST..i_rockbox_table_tab.LAST LOOP
--
        -- �����v��(�v)�̂Ƃ��́A���[�N�e�[�u���ɑΏۃf�[�^��o�^����
        IF (i_rockbox_table_tab(ln_count).apply_flag = cv_need) THEN
--
          INSERT INTO xxcfr_rockbox_wk(
            parallel_type          -- �p���������s�敪
           ,kind_code              -- ��ʃR�[�h
           ,bank_number            -- ��s�R�[�h
           ,bank_num               -- �x�X�R�[�h
           ,account_type           -- �������
           ,account_num            -- �����ԍ�
           ,ref_number             -- �Ɖ�ԍ�
           ,payment_code           -- �����敪
           ,trans_code             -- ����敪
           ,alt_name               -- �U���˗��l��
           ,cust_account_id        -- �ڋqID
           ,account_number         -- �ڋq�ԍ�
           ,cash_receipt_id        -- ��������ID
           ,receipt_number         -- �����ԍ�
           ,receipt_date           -- ������
           ,amount                 -- �����z
           ,factor_discount_amount -- �萔��
           ,receipt_method_name    -- �x�����@����
           ,receipt_method_id      -- �x�����@ID
           ,comments               -- ����
           ,cash_flag              -- �����v�ۃt���O
           ,apply_flag             -- �����v�ۃt���O
           ,apply_trx_count        -- �����Ώی���
           ,in_file_name           -- �捞�t�@�C����
           ,created_by             -- �쐬��
           ,creation_date          -- �쐬��
           ,last_updated_by        -- �ŏI�X�V��
           ,last_update_date       -- �ŏI�X�V��
           ,last_update_login      -- �ŏI�X�V���O�C��
           ,request_id             -- �v��ID
           ,program_application_id -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
           ,program_id             -- �R���J�����g�E�v���O����ID
           ,program_update_date    -- �v���O�����X�V��
          )
          VALUES
          (
           NULL                                               -- �p���������s�敪
          ,i_rockbox_table_tab(ln_count).kind_code               -- ��ʃR�[�h
          ,i_rockbox_table_tab(ln_count).bank_number             -- ��s�R�[�h
          ,i_rockbox_table_tab(ln_count).bank_num                -- �x�X�R�[�h
          ,i_rockbox_table_tab(ln_count).account_type            -- �������
          ,i_rockbox_table_tab(ln_count).account_num             -- �����ԍ�
          ,i_rockbox_table_tab(ln_count).ref_number              -- �Ɖ�ԍ�
          ,i_rockbox_table_tab(ln_count).payment_code            -- �����敪
          ,i_rockbox_table_tab(ln_count).trans_code              -- ����敪
          ,i_rockbox_table_tab(ln_count).alt_name                -- �U���˗��l��
          ,i_rockbox_table_tab(ln_count).cust_account_id         -- �ڋqID
          ,i_rockbox_table_tab(ln_count).account_number          -- �ڋq�ԍ�
          ,i_rockbox_table_tab(ln_count).cash_receipt_id         -- ��������ID
          ,i_rockbox_table_tab(ln_count).receipt_number          -- �����ԍ�
          ,i_rockbox_table_tab(ln_count).receipt_date            -- ������
          ,i_rockbox_table_tab(ln_count).amount                  -- �����z
          ,i_rockbox_table_tab(ln_count).factor_discount_amount  -- �萔��
          ,i_rockbox_table_tab(ln_count).receipt_method_name     -- �x�����@����
          ,i_rockbox_table_tab(ln_count).receipt_method_id       -- �x�����@ID
          ,i_rockbox_table_tab(ln_count).comments                -- ����
          ,i_rockbox_table_tab(ln_count).cash_flag               -- �����v�ۃt���O
          ,i_rockbox_table_tab(ln_count).apply_flag              -- �����v�ۃt���O
          ,i_rockbox_table_tab(ln_count).apply_trx_count         -- �����Ώی���
          ,i_rockbox_table_tab(ln_count).in_file_name            -- �捞�t�@�C����
          ,cn_created_by                                      -- �쐬��
          ,cd_creation_date                                   -- �쐬��
          ,cn_last_updated_by                                 -- �ŏI�X�V��
          ,cd_last_update_date                                -- �ŏI�X�V��
          ,cn_last_update_login                               -- �ŏI�X�V���O�C��
          ,cn_request_id                                      -- �v��ID
          ,cn_program_application_id                          -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          ,cn_program_id                                      -- �R���J�����g�E�v���O����ID
          ,cd_program_update_date                             -- �v���O�����X�V��
          )
          ;
--
          gn_auto_apply_cnt := gn_auto_apply_cnt + 1;  -- ���������Ώی������J�E���g�A�b�v
--
        END IF;
--
      END LOOP insert_loop;
--
    EXCEPTION
--
      WHEN OTHERS THEN
--
        -- �o�^�G���[�̎|���o��
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cfr
                        ,iv_name         => cv_msg_005a04_016
                        ,iv_token_name1  => cv_tkn_table
                        ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_tkn_rock_wk)
                       );
        lv_errbuf := SUBSTRB(SQLERRM,1,5000);
        RAISE global_api_expt;
--
    END
    ;
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
  END insert_table;
--
  /**********************************************************************************
   * Procedure Name   : update_table
   * Description      : �p���������s�敪�t�^���� (A-9)
   ***********************************************************************************/
  PROCEDURE update_table(
    ov_errbuf            OUT VARCHAR2,            -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT VARCHAR2,            -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT VARCHAR2)            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_table'; -- �v���O������
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
    ln_count   PLS_INTEGER;  -- ���[�v�J�E���^
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR upd_rock_cur
    IS
      SELECT xrw.rowid AS row_id
            ,MOD( ( ROW_NUMBER() OVER (ORDER BY xrw.apply_trx_count DESC) ) + gn_prf_par_cnt - 1
                                      , gn_prf_par_cnt
             ) + 1     AS parallel_type  -- �p���������s�敪
      FROM   xxcfr_rockbox_wk xrw  -- ���b�N�{�b�N�X�����������[�N
      WHERE  xrw.request_id  = cn_request_id  -- �v��ID
      AND    xrw.apply_flag  = cv_need        -- �����v�ۃt���O(�v)
      FOR UPDATE NOWAIT
      ;
--
    TYPE upd_rock_ttype IS TABLE OF upd_rock_cur%ROWTYPE
                           INDEX BY PLS_INTEGER;  -- FB�f�[�^
    l_upd_rock_tab  upd_rock_ttype;
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
    -- ������
    -- �߂�l
    ov_errbuf := NULL;
    ov_errmsg := NULL;
    -- �z��
    l_upd_rock_tab.DELETE;
--
    BEGIN
--
      OPEN upd_rock_cur;
      FETCH upd_rock_cur BULK COLLECT INTO l_upd_rock_tab;
      CLOSE upd_rock_cur;
--
      <<update_loop>>
      FOR ln_count IN 1..l_upd_rock_tab.COUNT LOOP
--
        UPDATE xxcfr_rockbox_wk xrw  -- ���b�N�{�b�N�X�����������[�N
        SET    xrw.parallel_type = l_upd_rock_tab(ln_count).parallel_type  -- �p���������s�敪
        WHERE  xrw.rowid = l_upd_rock_tab(ln_count).row_id
        ;
--
      END LOOP update_loop;
--
    EXCEPTION
      WHEN global_lock_err_expt THEN
--
        -- �J�[�\�����J���Ă��������
        IF ( upd_rock_cur%ISOPEN ) THEN
          CLOSE upd_rock_cur;
        END IF;
--
        -- ���b�N�G���[�����������|���o��
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cfr
                        ,iv_name         => cv_msg_005a04_003
                        ,iv_token_name1  => cv_tkn_table
                        ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_tkn_rock_wk)
                       );
        lv_errbuf := SUBSTRB(SQLERRM,1,5000);
        RAISE global_api_expt;
--
      WHEN OTHERS THEN
--
        -- �J�[�\�����J���Ă��������
        IF ( upd_rock_cur%ISOPEN ) THEN
          CLOSE upd_rock_cur;
        END IF;
--
        -- �X�V�G���[�����������|���o��
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cfr
                        ,iv_name         => cv_msg_005a04_017
                        ,iv_token_name1  => cv_tkn_table
                        ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_tkn_rock_wk)
                       );
        lv_errbuf := SUBSTRB(SQLERRM,1,5000);
        RAISE global_api_expt;
--
    END
    ;
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
  END update_table;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_fb_file_name       IN         VARCHAR2,  -- �p�����[�^�DFB�t�@�C����
    iv_table_insert_flag  IN         VARCHAR2,  -- �p�����[�^�D���[�N�e�[�u���쐬�t���O
    ov_errbuf             OUT NOCOPY VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    ln_count          PLS_INTEGER;  -- ���[�v�J�E���^
    ln_cash_cnt       PLS_INTEGER;  -- �����ԍ��Ɏg�p����A�Ԃ̍̔ԗp
    lb_warn_end       BOOLEAN;      -- �I���X�e�[�^�X����
-- 2015/05/29 Ver1.02 Add Start
    ln_cash_cnt2         PLS_INTEGER;  -- 24���ԉ��Ή���s�̓����ԍ��Ɏg�p����A�Ԃ̍̔ԗp
    lv_bank_code_flag    VARCHAR2(1);  -- 24���ԉ��Ή���s�t���O
    lv_registration_flag VARCHAR2(1);  -- �����ԍ��Ǘ��e�[�u���o�^�t���O
--
    lt_receipt_date      xxcfr_rockbox_wk.receipt_date%TYPE := NULL;  -- ������
-- 2015/05/29 Ver1.02 Add End
--
    l_rockbox_table_tab  rockbox_table_ttype;      -- FB�f�[�^
    l_fb_file_name_tab   fnd_lookup_values_ttype;  -- FB�t�@�C����
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
    -- ������
    -- �߂�l
    ov_errbuf := NULL;
    ov_errmsg := NULL;
    -- �O���[�o���ϐ�
    gn_target_cnt      := 0;  -- �Ώی���
    gn_normal_cnt      := 0;  -- ��������
    gn_error_cnt       := 0;  -- �G���[����
    gn_warn_cnt        := 0;  -- �x������
    gn_no_customer_cnt := 0;  -- �s����������
    gn_auto_apply_cnt  := 0;  -- ���������Ώی���
    -- �z��
    l_rockbox_table_tab.DELETE;
    l_fb_file_name_tab.DELETE;
    -- ���[�J���ϐ�
    ln_cash_cnt := 0;
    lb_warn_end := cb_false;
-- 2015/05/29 Ver1.02 Add Start
    ln_cash_cnt2         := 0;
    lv_bank_code_flag    := cv_flag_n;
    lv_registration_flag := cv_flag_n;
-- 2015/05/29 Ver1.02 Add End
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- =====================================================
    --  �������� (A-1)
    -- =====================================================
    init(
       iv_fb_file_name      => iv_fb_file_name       -- �p�����[�^�DFB�t�@�C����
      ,iv_table_insert_flag => iv_table_insert_flag  -- �p�����[�^�D���[�N�e�[�u���쐬�t���O
      ,o_fb_file_name_tab   => l_fb_file_name_tab    -- FB�t�@�C����
      ,ov_errbuf            => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode           => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg            => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  FB�t�@�C���捞���� (A-2)
    -- =====================================================
    get_fb_data(
       i_fb_file_name_tab  => l_fb_file_name_tab  -- FB�t�@�C����
      ,o_rockbox_table_tab => l_rockbox_table_tab -- FB�f�[�^
      ,ob_warn_end         => lb_warn_end         -- �I���X�e�[�^�X����
      ,ov_errbuf           => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode          => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg           => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- �Ώۃf�[�^�����݂��Ȃ��Ƃ��́A�x���I��
    IF ( l_rockbox_table_tab.COUNT = 0 ) THEN
--
      --��s�}��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
--
      -- �Ώۃf�[�^�Ȃ����b�Z�[�W�o��
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cfr
                      ,iv_name         => cv_msg_005a04_024
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
--
      ov_retcode := cv_status_warn;
--
    ELSE
--
      -- FB�t�@�C���̃��R�[�h�����[�v
      <<loop_fb_data>>
      FOR ln_count IN l_rockbox_table_tab.FIRST..l_rockbox_table_tab.LAST LOOP
--
-- 2015/05/29 Ver1.02 Add Start
        -- =====================================================
        --  ����24���ԉ���s���擾���� (A-11)
        -- =====================================================
        get_bank_info(
           it_bank_number         => l_rockbox_table_tab(ln_count).bank_number          -- ��s�R�[�h
          ,it_receipt_date        => l_rockbox_table_tab(ln_count).receipt_date         -- ������(IN)
          ,ot_receipt_date        => lt_receipt_date                                    -- ������(OUT)
          ,ot_bank_code_flag      => lv_bank_code_flag                                  -- 24���ԉ��Ή���s�t���O
          ,ov_errbuf              => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,ov_retcode             => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
          ,ov_errmsg              => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
--
-- 2015/05/29 Ver1.02 Add End
        -- =====================================================
        --  �x�����@�擾���� (A-3)
        -- =====================================================
        get_receive_method(
           it_bank_number         => l_rockbox_table_tab(ln_count).bank_number          -- ��s�R�[�h
          ,it_bank_num            => l_rockbox_table_tab(ln_count).bank_num             -- �x�X�R�[�h
          ,it_account_type        => l_rockbox_table_tab(ln_count).account_type         -- �������
          ,it_account_num         => l_rockbox_table_tab(ln_count).account_num          -- �����ԍ�
          ,it_ref_number          => l_rockbox_table_tab(ln_count).ref_number           -- �Q�Ɣԍ�
          ,ot_receipt_method_id   => l_rockbox_table_tab(ln_count).receipt_method_id    -- �x�����@ID
          ,ot_receipt_method_name => l_rockbox_table_tab(ln_count).receipt_method_name  -- �x�����@����
          ,ot_cash_flag           => l_rockbox_table_tab(ln_count).cash_flag            -- �����v�ۃt���O
          ,ot_apply_flag          => l_rockbox_table_tab(ln_count).apply_flag           -- �����v�ۃt���O
          ,ov_errbuf              => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,ov_retcode             => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
          ,ov_errmsg              => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
--
        -- �����Ώۃt���O��'1'(�v)�̂Ƃ��B(�x�����@���擾�ł����Ƃ�)
        IF ( l_rockbox_table_tab(ln_count).cash_flag = cv_need ) THEN
--
          -- =====================================================
          --  ������ڋq�擾���� (A-4)
          -- =====================================================
          get_receipt_customer(
             it_alt_name        => l_rockbox_table_tab(ln_count).alt_name         -- �U���˗��l��
            ,it_ref_number      => l_rockbox_table_tab(ln_count).ref_number       -- �Q�Ɣԍ�
            ,ot_cust_account_id => l_rockbox_table_tab(ln_count).cust_account_id  -- �ڋqID
            ,ot_account_number  => l_rockbox_table_tab(ln_count).account_number   -- �ڋq�ԍ�
            ,ot_apply_flag      => l_rockbox_table_tab(ln_count).apply_flag       -- �����v�ۃt���O
            ,ov_errbuf          => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
            ,ov_retcode         => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
            ,ov_errmsg          => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
          END IF;
--
          -- �����Ώۃt���O��'1'(�v)�̂Ƃ�(�s�������ł͂Ȃ��Ƃ�)�A���A�p�����[�^�D���[�N�e�[�u���쐬�t���O���iY�j�̂Ƃ�
          IF (  ( l_rockbox_table_tab(ln_count).apply_flag = cv_need )  -- ���������v�ۂ�'1'(�v)
            AND ( iv_table_insert_flag = cv_flag_y                   )  -- �p�����[�^�D���[�N�e�[�u���쐬�t���O��'Y'
          ) THEN
--
            -- =====================================================
            --  ���������ΏۊO�ڋq�擾���� (A-5)
            -- =====================================================
            get_fb_out_acct_number(
               it_account_number  => l_rockbox_table_tab(ln_count).account_number   -- �ڋq�ԍ�
-- 2015/05/29 Ver1.02 Add Start
              ,it_receipt_date    => lt_receipt_date                                -- ������
-- 2015/05/29 Ver1.02 Add End
              ,ot_apply_flag      => l_rockbox_table_tab(ln_count).apply_flag       -- �����v�ۃt���O
              ,ov_errbuf          => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
              ,ov_retcode         => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
              ,ov_errmsg          => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
            IF ( lv_retcode <> cv_status_normal ) THEN
              RAISE global_process_expt;
            END IF;
--
          END IF;
--
          -- �����Ώۃt���O��'1'(�v)�̂Ƃ��A���A�p�����[�^�D���[�N�e�[�u���쐬�t���O���iY�j�̂Ƃ�
          IF (  ( l_rockbox_table_tab(ln_count).apply_flag = cv_need )  -- ���������v�ۂ�'1'(�v)
            AND ( iv_table_insert_flag = cv_flag_y                   )  -- �p�����[�^�D���[�N�e�[�u���쐬�t���O��'Y'
          ) THEN
--
            -- =====================================================
            --  �Ώۍ����z���� (A-6)
            -- =====================================================
            get_trx_amount(
               it_cust_account_id        => l_rockbox_table_tab(ln_count).cust_account_id         -- �ڋqID
              ,it_amount                 => l_rockbox_table_tab(ln_count).amount                  -- �����z
-- 2015/05/29 Ver1.02 Add Start
              ,it_receipt_date           => lt_receipt_date                                       -- ������
              ,it_bank_code_flag         => lv_bank_code_flag                                     -- 24���ԉ��Ή���s�t���O
-- 2015/05/29 Ver1.02 Add End
              ,ot_apply_flag             => l_rockbox_table_tab(ln_count).apply_flag              -- �����v�ۃt���O
              ,ot_factor_discount_amount => l_rockbox_table_tab(ln_count).factor_discount_amount  -- �萔��
              ,ot_apply_trx_count        => l_rockbox_table_tab(ln_count).apply_trx_count         -- �����Ώۖ{��
              ,ov_errbuf                 => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
              ,ov_retcode                => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
              ,ov_errmsg                 => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
            IF ( lv_retcode <> cv_status_normal ) THEN
              RAISE global_process_expt;
            END IF;
--
          END IF;
--
        END IF;  -- �x�����@���擾�ł����Ƃ�
--
      END LOOP loop_fb_data;
--
      -- FB�t�@�C���̃��R�[�h�����[�v
      <<loop_exec_api>>
      FOR ln_count IN l_rockbox_table_tab.FIRST..l_rockbox_table_tab.LAST LOOP
--
        -- �����v�ۃt���O���i�v�j�̂Ƃ��͓������쐬����
        IF ( l_rockbox_table_tab(ln_count).cash_flag = cv_need ) THEN
--
-- 2015/05/29 Ver1.02 Add Start
        -- =====================================================
        --  ����24���ԉ���s���擾���� (A-11)
        -- =====================================================
        get_bank_info(
           it_bank_number         => l_rockbox_table_tab(ln_count).bank_number          -- ��s�R�[�h
          ,it_receipt_date        => l_rockbox_table_tab(ln_count).receipt_date         -- ������(IN)
          ,ot_receipt_date        => lt_receipt_date                                    -- ������(OUT)
          ,ot_bank_code_flag      => lv_bank_code_flag                                  -- 24���ԉ��Ή���s�t���O
          ,ov_errbuf              => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,ov_retcode             => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
          ,ov_errmsg              => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
--
-- 2015/05/29 Ver1.02 Add End
          -- =====================================================
          --  ����API�N������ (A-7)
          -- =====================================================
-- 2015/05/29 Ver1.02 Mod Start
--          -- �����ԍ��̘A�Ԃ��̔Ԃ���ϐ����J�E���g�A�b�v
--          ln_cash_cnt := ln_cash_cnt + 1;
--          -- �����ԍ��̍̔�
--          l_rockbox_table_tab(ln_count).receipt_number := l_rockbox_table_tab(ln_count).in_file_name -- FB�t�@�C����
--                                                       || cv_msg_under_score                         -- �A���_�[�X�R�A
--                                                       || TO_CHAR( gd_process_date, cv_format_ymd )  -- �Ɩ����t
--                                                       || cv_msg_under_score                         -- �A���_�[�X�R�A
--                                                       || TO_CHAR( ln_cash_cnt )                     -- �A��
--          ;
          -- 1.24���ԉ��Ή���s�ł͂Ȃ��ꍇ
          IF ( lv_bank_code_flag = cv_flag_n ) THEN
            -- �����ԍ��̘A�Ԃ��̔Ԃ���ϐ����J�E���g�A�b�v
            ln_cash_cnt := ln_cash_cnt + 1;
            -- �����ԍ��̍̔�
            l_rockbox_table_tab(ln_count).receipt_number := l_rockbox_table_tab(ln_count).in_file_name -- FB�t�@�C����
                                                         || cv_msg_under_score                         -- �A���_�[�X�R�A
                                                         || TO_CHAR( gd_process_date, cv_format_ymd )  -- �Ɩ����t
                                                         || cv_msg_under_score                         -- �A���_�[�X�R�A
                                                         || TO_CHAR( ln_cash_cnt )                     -- �A��
            ;
--
          -- 2.24���ԉ��Ή���s�̏ꍇ
          ELSIF ( lv_bank_code_flag = cv_flag_y ) THEN
            -- 2-1.�A�Ԃ̎擾
            -- 2-1-1.�ŏ��̃��R�[�h�������́A�O���R�[�h�Ƌ�s�R�[�h�������͓��������Ⴄ�ꍇ
            IF ( ( ln_count = l_rockbox_table_tab.FIRST )
              OR ( l_rockbox_table_tab(ln_count).bank_number  <> l_rockbox_table_tab(ln_count-1).bank_number  )
              OR ( l_rockbox_table_tab(ln_count).receipt_date <> l_rockbox_table_tab(ln_count-1).receipt_date ) ) THEN
              -- �����ԍ��Ǘ��e�[�u������A�Ԃ��擾
              BEGIN
                SELECT xcrnc.receipt_num  AS receipt_num
                INTO   ln_cash_cnt2
                FROM   xxcfr_cash_receipts_no_control xcrnc
                WHERE  xcrnc.bank_cd                           = l_rockbox_table_tab(ln_count).bank_number
                AND    TRUNC(xcrnc.receipt_date, cv_format_dd) = TRUNC(l_rockbox_table_tab(ln_count).receipt_date, cv_format_dd)
                ;
              EXCEPTION
                -- ��s�R�[�h�E�������P�ʂŖ��o�^�̏ꍇ
                WHEN NO_DATA_FOUND THEN
                  -- �A�Ԃ�0�ɂ���
                  ln_cash_cnt2 := 0;
                  -- �����ԍ��Ǘ��e�[�u���o�^�t���O��'Y'�ɂ���
                  lv_registration_flag := cv_flag_y;
              END;
              -- �����ԍ��̘A�Ԃ��J�E���g�A�b�v
              ln_cash_cnt2 := ln_cash_cnt2 + 1;
            -- 2-1-2.�O���R�[�h�Ƌ�s�R�[�h�E�������������ꍇ
            ELSIF ( ( l_rockbox_table_tab(ln_count).bank_number  = l_rockbox_table_tab(ln_count-1).bank_number  )
              AND   ( l_rockbox_table_tab(ln_count).receipt_date = l_rockbox_table_tab(ln_count-1).receipt_date ) ) THEN
              -- �����ԍ��̘A�Ԃ��J�E���g�A�b�v
              ln_cash_cnt2 := ln_cash_cnt2 + 1;
            END IF;
            -- 2-2.�����ԍ��̍̔�
            l_rockbox_table_tab(ln_count).receipt_number := l_rockbox_table_tab(ln_count).in_file_name -- FB�t�@�C����
                                                         || cv_msg_under_score                         -- �A���_�[�X�R�A
                                                         || TO_CHAR( lt_receipt_date, cv_format_ymd )  -- �������t
                                                         || cv_msg_under_score                         -- �A���_�[�X�R�A
                                                         || TO_CHAR( ln_cash_cnt2 )                    -- �A��
            ;
            -- 2-3.�Ō�̃��R�[�h�������́A�����R�[�h�Ƌ�s�R�[�h�������͓��������Ⴄ�ꍇ�A�����ԍ��Ǘ��e�[�u���̓o�^
            IF ( ( ln_count = l_rockbox_table_tab.LAST )
              OR ( l_rockbox_table_tab(ln_count).bank_number  <> l_rockbox_table_tab(ln_count+1).bank_number  )
              OR ( l_rockbox_table_tab(ln_count).receipt_date <> l_rockbox_table_tab(ln_count+1).receipt_date ) ) THEN
              -- 2-3-1.�����ԍ��Ǘ��e�[�u���o�^�t���O��'Y'�̏ꍇ
              IF ( lv_registration_flag = cv_flag_y ) THEN
                BEGIN
                  -- �����ԍ��Ǘ��e�[�u���ɑ}��
                  INSERT INTO xxcfr_cash_receipts_no_control(
                    bank_cd                 -- ��s�R�[�h
                   ,receipt_date            -- ������
                   ,receipt_num             -- �ԍ�
                   ,created_by              -- �쐬��
                   ,creation_date           -- �쐬��
                   ,last_updated_by         -- �ŏI�X�V��
                   ,last_update_date        -- �ŏI�X�V��
                   ,last_update_login       -- �ŏI�X�V���O�C��
                   ,request_id              -- �v��ID
                   ,program_application_id  -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
                   ,program_id              -- �R���J�����g�E�v���O����ID
                   ,program_update_date     -- �v���O�����X�V��
                  )
                  VALUES
                  (
                    l_rockbox_table_tab(ln_count).bank_number   -- ��s�R�[�h
                   ,l_rockbox_table_tab(ln_count).receipt_date  -- ������
                   ,ln_cash_cnt2                                -- �ԍ�
                   ,cn_created_by                               -- �쐬��
                   ,cd_creation_date                            -- �쐬��
                   ,cn_last_updated_by                          -- �ŏI�X�V��
                   ,cd_last_update_date                         -- �ŏI�X�V��
                   ,cn_last_update_login                        -- �ŏI�X�V���O�C��
                   ,cn_request_id                               -- �v��ID
                   ,cn_program_application_id                   -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
                   ,cn_program_id                               -- �R���J�����g�E�v���O����ID
                   ,cd_program_update_date                      -- �v���O�����X�V��
                  )
                  ;
                EXCEPTION
                  WHEN OTHERS THEN
                    -- �o�^�G���[�̎|���o��
                    lv_errmsg := xxccp_common_pkg.get_msg(
                                     iv_application  => cv_msg_kbn_cfr
                                    ,iv_name         => cv_msg_005a04_016
                                    ,iv_token_name1  => cv_tkn_table
                                    ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_tkn_xcrnc)
                                   );
                    lv_errbuf := SUBSTRB(SQLERRM,1,5000);
                    RAISE global_process_expt;
                END;
                -- �����ԍ��Ǘ��e�[�u���o�^�t���O��'N'�ɂ���
                lv_registration_flag := cv_flag_n;
              -- 2-3-2.�����ԍ��Ǘ��e�[�u���o�^�t���O��'N'�̏ꍇ
              ELSIF ( lv_registration_flag = cv_flag_n ) THEN
                BEGIN
                  -- �����ԍ��Ǘ��e�[�u�����X�V
                  UPDATE xxcfr_cash_receipts_no_control xcrnc
                  SET    xcrnc.receipt_num         = ln_cash_cnt2            -- �ԍ�
                        ,xcrnc.last_updated_by     = cn_last_updated_by      -- �ŏI�X�V��
                        ,xcrnc.last_update_date    = cd_last_update_date     -- �ŏI�X�V��
                        ,xcrnc.last_update_login   = cn_last_update_login    -- �ŏI�X�V���O�C��
                        ,xcrnc.program_update_date = cd_program_update_date  -- �v���O�����X�V��
                  WHERE  xcrnc.bank_cd                           = l_rockbox_table_tab(ln_count).bank_number
                  AND    TRUNC(xcrnc.receipt_date, cv_format_dd) = TRUNC(l_rockbox_table_tab(ln_count).receipt_date, cv_format_dd)
                  ;
                EXCEPTION
                  WHEN OTHERS THEN
                    -- �X�V�G���[�̎|���o��
                    lv_errmsg := xxccp_common_pkg.get_msg(
                                     iv_application  => cv_msg_kbn_cfr
                                    ,iv_name         => cv_msg_005a04_017
                                    ,iv_token_name1  => cv_tkn_table
                                    ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_tkn_xcrnc)
                                   );
                    lv_errbuf := SUBSTRB(SQLERRM,1,5000);
                    RAISE global_process_expt;
                END;
              END IF;
            END IF;
          END IF;
-- 2015/05/29 Ver1.02 Mod End
--
          exec_cash_api(
             it_amount                 => l_rockbox_table_tab(ln_count).amount                  -- �����z
            ,it_factor_discount_amount => l_rockbox_table_tab(ln_count).factor_discount_amount  -- �萔��
            ,it_receipt_number         => l_rockbox_table_tab(ln_count).receipt_number          -- �����ԍ�
            ,it_receipt_date           => l_rockbox_table_tab(ln_count).receipt_date            -- ������
            ,it_cust_account_id        => l_rockbox_table_tab(ln_count).cust_account_id         -- �ڋqID
            ,it_account_number         => l_rockbox_table_tab(ln_count).account_number          -- �ڋq�ԍ�
            ,it_receipt_method_id      => l_rockbox_table_tab(ln_count).receipt_method_id       -- �x�����@ID
            ,it_receipt_method_name    => l_rockbox_table_tab(ln_count).receipt_method_name     -- �x�����@��
            ,it_alt_name               => l_rockbox_table_tab(ln_count).alt_name                -- �U���˗��l��
            ,it_comments               => l_rockbox_table_tab(ln_count).comments                -- ����
            ,it_ref_number             => l_rockbox_table_tab(ln_count).ref_number              -- �Q�Ɣԍ�
            ,iot_apply_flag            => l_rockbox_table_tab(ln_count).apply_flag              -- �����t���O
            ,ot_cash_receipt_id        => l_rockbox_table_tab(ln_count).cash_receipt_id         -- ����ID
            ,ov_errbuf                 => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
            ,ov_retcode                => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
            ,ov_errmsg                 => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
          END IF;
--
        END IF;
--
      END LOOP loop_exec_api;
--
      -- �p�����[�^�D���[�N�e�[�u���쐬�t���O��'Y'�̂Ƃ��͓o�^����B
      IF ( iv_table_insert_flag = cv_flag_y ) THEN
--
        -- =====================================================
        --  ���b�N�{�b�N�X�����������[�N�e�[�u���o�^���� (A-8)
        -- =====================================================
        insert_table(
           i_rockbox_table_tab => l_rockbox_table_tab -- FB�f�[�^
          ,ov_errbuf           => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,ov_retcode          => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
          ,ov_errmsg           => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
--
        -- =====================================================
        --  �p���������s�敪�t�^���� (A-9)
        -- =====================================================
        update_table(
           ov_errbuf  => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,ov_retcode => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
          ,ov_errmsg  => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
--
      END IF;
--
      -- �t�@�C���ǂݎ��G���[���������Ă�����A�x���I��
      IF ( ( lb_warn_end            )  -- �t�@�C���ǂݎ��G���[
        OR ( gn_warn_cnt        > 0 )  -- �x������
        OR ( gn_no_customer_cnt > 0 )  -- �s����������
      ) THEN
        ov_retcode := cv_status_warn;
      END IF;
--
    END IF;  -- �f�[�^���݂Ȃ���������
--
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
      -- �J�[�\���̃N���[�Y�������ɋL�q����
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
    errbuf                OUT NOCOPY VARCHAR2,  -- �G���[���b�Z�[�W #�Œ�#
    retcode               OUT NOCOPY VARCHAR2,  -- �G���[�R�[�h     #�Œ�#
    iv_fb_file_name       IN         VARCHAR2,  -- �p�����[�^�DFB�t�@�C����
    iv_table_insert_flag  IN         VARCHAR2   -- �p�����[�^�D���[�N�e�[�u���쐬�t���O
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
       iv_fb_file_name      => iv_fb_file_name      -- FB�t�@�C����
      ,iv_table_insert_flag => iv_table_insert_flag -- ���[�N�e�[�u���폜�t���O
      ,ov_errbuf            => lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode           => lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg            => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      -- �G���[�������A�e�����͈ȉ��ɓ��ꂵ�ďo�͂���
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
    --�s�����������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cfr
                    ,iv_name         => cv_msg_005a04_118
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_no_customer_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�x�������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cfr
                    ,iv_name         => cv_msg_005a04_025
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --���������Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cfr
                    ,iv_name         => cv_msg_005a04_128
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_auto_apply_cnt)
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
END XXCFR005A04C;
/