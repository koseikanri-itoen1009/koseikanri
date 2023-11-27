CREATE OR REPLACE PACKAGE BODY XXCOK016A05C
AS
/*****************************************************************************************
 * Copyright(c) SCSK, 2023. All rights reserved.
 *
 * Package Name     : XXCOK016A05C(body)
 * Description      : FB�f�[�^�t�@�C���쐬�����ō쐬���ꂽFB�f�[�^����ɁA
 *                    �d����s�̐U�蕪���������s���܂��B
 *
 * MD.050           : FB�f�[�^�t�@�C���U�蕪������ MD050_COK_016_A05
 * Version          : 1.0
 *
 * Program List
 * -------------------------------- ----------------------------------------------------------
 *  Name                             Description
 * -------------------------------- ----------------------------------------------------------
 *  init                             �������� (A-1)
 *  init_update_data                 ���������e�[�u���X�V(A-2)
 *  auto_distribute_proc             FB�f�[�^�����U�蕪������(A-3)
 *  manual_distribute_proc           FB�f�[�^���U�蕪������(A-4)
 *  output_fb_proc                   FB�f�[�^�o�͏���(A-5)
 *  fb_header_record                 FB�w�b�_�[���R�[�h�o��(A-6)
 *  fb_data_record                   FB�f�[�^���R�[�h�̏o��(A-7)
 *  fb_trailer_record                FB�g���[�����R�[�h�̏o��(A-8)
 *  fb_end_record                    FB�G���h���R�[�h�̏o��(A-9)
 *  submain                          ���C�������v���V�[�W��
 *  main                             �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2023/11/15    1.0   T.Okuyama        [E_�{�ғ�_19540�Ή�] �V�K�쐬
 *  2023/11/24    1.1   T.Okuyama        [E_�{�ғ�_19540�Ή�] �V�K�쐬
 *
 *****************************************************************************************/
--
  --===============================
  -- �O���[�o���萔
  --===============================
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal            CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_normal; -- ����:0
  cv_status_warn              CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_warn;   -- �x��:1
  cv_status_error             CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_error;  -- �ُ�:2
  --WHO�J����
  cn_created_by               CONSTANT NUMBER        := fnd_global.user_id;                 -- CREATED_BY
  cd_creation_date            CONSTANT DATE          := SYSDATE;                            -- CREATION_DATE
  cn_last_updated_by          CONSTANT NUMBER        := fnd_global.user_id;                 -- LAST_UPDATED_BY
  cd_last_update_date         CONSTANT DATE          := SYSDATE;                            -- LAST_UPDATE_DATE
  cn_last_update_login        CONSTANT NUMBER        := fnd_global.login_id;                -- LAST_UPDATE_LOGIN
  cn_request_id               CONSTANT NUMBER        := fnd_global.conc_request_id;         -- REQUEST_ID
  cn_program_application_id   CONSTANT NUMBER        := fnd_global.prog_appl_id;            -- PROGRAM_APPLICATION_ID
  cn_program_id               CONSTANT NUMBER        := fnd_global.conc_program_id;         -- PROGRAM_ID
  cd_program_update_date      CONSTANT DATE          := SYSDATE;                            -- PROGRAM_UPDATE_DATE
  --
  cv_msg_part                 CONSTANT VARCHAR2(3)   := ' : ';                              -- �R����
  cv_msg_cont                 CONSTANT VARCHAR2(3)   := '.';                                -- �s���I�h
  --
  cv_pkg_name                 CONSTANT VARCHAR2(100) := 'XXCOK016A05C';                     -- �p�b�P�[�W��
  -- �v���t�@�C��
  cv_prof_org_id              CONSTANT VARCHAR2(35)  := 'ORG_ID';                           -- MO: �c�ƒP��
  cv_prof_acc_type_internal   CONSTANT VARCHAR2(35)  := 'XXCOK1_BM_ACC_TYPE_INTERNAL';      -- XXCOK:�̔��萔��_����_�����g�p
  -- �A�v���P�[�V������
  cv_appli_xxccp              CONSTANT VARCHAR2(5)   := 'XXCCP';               -- 'XXCCP'
  cv_appli_xxcok              CONSTANT VARCHAR2(5)   := 'XXCOK';               -- 'XXCOK'
  -- ���b�Z�[�W
  cv_msg_cok_10865            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10865';    -- �R���J�����g���̓p�����[�^�o�̓��b�Z�[�W
  cv_msg_cok_10866            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10866';    -- �R���J�����g���̓p�����[�^�g���o�̓��b�Z�[�W
  cv_msg_cok_10867            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10867';    -- FB�t�@�C���쐬�v��ID�擾�G���[
  cv_msg_cok_10868            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10868';    -- FB���s���d����s�擾�G���[
  cv_msg_cok_10869            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10869';    -- FB���s���d����s����`�G���[
  cv_msg_cok_10870            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10870';    -- FB���s���d����s�������G���[
  cv_msg_cok_10871            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10871';    -- FB���s���d����s�����������G���[
  cv_msg_cok_10872            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10872';    -- FB�f�[�^���׎擾�G���[
  cv_msg_cok_10873            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10873';    -- �Q�ƕ\�i���Ћ�s�������j�擾�G���[
  cv_msg_cok_10874            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10874';    -- FB���s���d����s�d���G���[
  cv_msg_cok_10875            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10875';    -- FB�p������s�������G���[
  cv_msg_cok_10876            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10876';    -- �Q�ƕ\�iFB���s���d����s�j�擾�G���[
  cv_msg_cok_10877            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10877';    -- ���������A���v���z���b�Z�[�W
  cv_msg_cok_10863            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10863';    -- �e�[�u�����b�N�擾�G���[
  cv_msg_cok_10864            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10864';    -- �e�[�u���X�V�G���[
  cv_msg_cok_00003            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00003';    -- �v���t�@�C���l�擾�G���[���b�Z�[�W
  cv_msg_cok_00028            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00028';    -- �Ɩ��������t�擾�G���[���b�Z�[�W
  cv_msg_ccp_90000            CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90000';    -- ���o�������b�Z�[�W
  cv_msg_ccp_90002            CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90002';    -- �G���[�������b�Z�[�W
  cv_msg_ccp_90001            CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90001';    -- �t�@�C���o�͌������b�Z�[�W
  cv_msg_ccp_90004            CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90004';    -- ����I�����b�Z�[�W
  cv_msg_ccp_90006            CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90006';    -- �G���[�I���S���[���o�b�N���b�Z�[�W
  -- ���b�Z�[�W�E�g�[�N��
  cv_token_request_id         CONSTANT VARCHAR2(15)  := 'REQUEST_ID';             -- �����p�����[�^�FFB�f�[�^�t�@�C���쐬���̗v��ID
  cv_token_fb_bank1           CONSTANT VARCHAR2(30)  := 'FB_DISTRIBUTION_BANK1';  -- �����p�����[�^�F���s���d����s1
  cv_token_fb_bank_cnt1       CONSTANT VARCHAR2(30)  := 'REQUEST_CNT1';           -- �����p�����[�^�F�d����s1�ւ̈�����
  cv_token_fb_bank2           CONSTANT VARCHAR2(30)  := 'FB_DISTRIBUTION_BANK2';  -- �����p�����[�^�F���s���d����s2
  cv_token_fb_bank_cnt2       CONSTANT VARCHAR2(30)  := 'REQUEST_CNT2';           -- �����p�����[�^�F�d����s2�ւ̈�����
  cv_token_fb_bank3           CONSTANT VARCHAR2(30)  := 'FB_DISTRIBUTION_BANK3';  -- �����p�����[�^�F���s���d����s3
  cv_token_fb_bank_cnt3       CONSTANT VARCHAR2(30)  := 'REQUEST_CNT3';           -- �����p�����[�^�F�d����s3�ւ̈�����
  cv_token_fb_bank4           CONSTANT VARCHAR2(30)  := 'FB_DISTRIBUTION_BANK4';  -- �����p�����[�^�F���s���d����s4
  cv_token_fb_bank_cnt4       CONSTANT VARCHAR2(30)  := 'REQUEST_CNT4';           -- �����p�����[�^�F�d����s4�ւ̈�����
  cv_token_fb_bank5           CONSTANT VARCHAR2(30)  := 'FB_DISTRIBUTION_BANK5';  -- �����p�����[�^�F���s���d����s5
  cv_token_fb_bank_cnt5       CONSTANT VARCHAR2(30)  := 'REQUEST_CNT5';           -- �����p�����[�^�F�d����s5�ւ̈�����
  cv_token_fb_bank6           CONSTANT VARCHAR2(30)  := 'FB_DISTRIBUTION_BANK6';  -- �����p�����[�^�F���s���d����s6
  cv_token_fb_bank_cnt6       CONSTANT VARCHAR2(30)  := 'REQUEST_CNT6';           -- �����p�����[�^�F�d����s6�ւ̈�����
  cv_token_dist_bank          CONSTANT VARCHAR2(20)  := 'FB_DISTRIBUTION_BANK';   -- ��d����s�U�蕪����s
  cv_token_dupli_bank         CONSTANT VARCHAR2(20)  := 'DUPLI_BANK';             -- �d����s
  cv_token_profile            CONSTANT VARCHAR2(15)  := 'PROFILE';                -- �J�X�^���v���t�@�C���̕�����
  cv_token_count              CONSTANT VARCHAR2(15)  := 'COUNT';                  -- ����
  cv_token_amount             CONSTANT VARCHAR2(15)  := 'AMOUNT';                 -- ���v���z
  -- �萔
  cv_log                      CONSTANT VARCHAR2(3)   := 'LOG';                    -- ���O�o�͎w��
  cv_yes                      CONSTANT VARCHAR2(1)   := 'Y';                      -- �t���O:'Y'
  cv_no                       CONSTANT VARCHAR2(1)   := 'N';                      -- �t���O:'N'
  cv_space                    CONSTANT VARCHAR2(1)   := ' ';                      -- �X�y�[�X1����
  cv_zero                     CONSTANT VARCHAR2(1)   := '0';                      -- �����^�����F'0'
  cn_zero                     CONSTANT NUMBER        := 0;                        -- ���l�F0
  cv_auto                     CONSTANT VARCHAR2(1)   := 'A';                      -- �����U�蕪�����s�t���O:'Y'
  cv_manual                   CONSTANT VARCHAR2(1)   := 'M';                      -- �蓮�U�蕪�����s�t���O:'M'
  cv_tkn_tbl                  CONSTANT VARCHAR2(30)  := 'TABLE';                  -- �e�[�u����
  cv_tkn_err_msg              CONSTANT VARCHAR2(30)  := 'ERR_MSG';                -- �G���[���b�Z�[�W
  cv_loopup_type              CONSTANT VARCHAR2(30)  := 'LOOPUP_TYPE';            -- �Q�ƃ^�C�v
  cv_loopup_tbl_nm            CONSTANT VARCHAR2(100) := '�Q�ƕ\�iFB���s���d����s�j';
  cv_wk_tbl_nm                CONSTANT VARCHAR2(100) := 'FB�f�[�^���׃��[�N�e�[�u��';
  cv_lookup_type_fb           CONSTANT VARCHAR2(50)  := 'XXCMM_FB_DISTRIBUTION_BANK';   -- �Q�ƃ^�C�v�FFB���s���d����s
  cv_lookup_type_bank         CONSTANT VARCHAR2(50)  := 'XXCOK1_BM_BANK_ACCOUNT';       -- �Q�ƃ^�C�v�F���Ћ�s�������
  cv_lookup_code_bank         CONSTANT VARCHAR2(10)  := 'VDBM_FB';                      -- �Q�ƃR�[�h�FVDBM�U��������
  --
  --===============================
  -- �O���[�o���ϐ�
  --===============================
  -- �o�̓��b�Z�[�W
  gv_out_msg                  VARCHAR2(2000) DEFAULT NULL;                            -- �o�̓��b�Z�[�W
  -- �J�E���^
  gn_target_cnt               NUMBER         DEFAULT 0;                               -- �Ώی���
  gn_error_cnt                NUMBER         DEFAULT 0;                               -- �G���[����
  gn_out_cnt                  NUMBER         DEFAULT 0;                               -- ���������iFB���׍��v�����j
  gn_out_amount               NUMBER         DEFAULT 0;                               -- FB���׍��v���z
  gn_request_id               xxcok_fb_lines_work.request_id%TYPE  DEFAULT NULL;      -- �����Ώۗv��ID
  gv_default_bank_code        fnd_lookup_values.lookup_code%TYPE   DEFAULT NULL;      -- FB�f�[�^�쐬���̎��Ћ�s

  -- �v���t�@�C��
  gt_prof_org_id              fnd_profile_option_values.profile_option_value%TYPE;    -- �c�ƒP��
  gt_prof_acc_type_internal   fnd_profile_option_values.profile_option_value%TYPE;    -- XXCOK:�̔��萔��_����_�����g�p
  -- ���t
  gd_proc_date                DATE;                                                   -- �Ɩ��������t
  --=================================
  -- ���ʗ�O
  --=================================
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION;
  --*** ���b�N�擾���ʗ�O ***
  global_lock_err_expt      EXCEPTION;
  --=================================
  -- �v���O�}
  --=================================
  PRAGMA EXCEPTION_INIT( global_api_others_expt,-20000 );
  PRAGMA EXCEPTION_INIT( global_lock_err_expt, -54 );
  --
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf          OUT VARCHAR2     -- �G���[�E���b�Z�[�W
  , ov_retcode         OUT VARCHAR2     -- ���^�[���E�R�[�h
  , ov_errmsg          OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W
  , in_request_id      IN  NUMBER       -- �p�����[�^�FFB�f�[�^�t�@�C���쐬���̗v��ID
  , iv_internal_bank1  IN  VARCHAR2     -- �p�����[�^�F���s���d����s1
  , in_bank_cnt1       IN  NUMBER       -- �p�����[�^�F�d����s1�ւ̈�����
  , iv_internal_bank2  IN  VARCHAR2     -- �p�����[�^�F���s���d����s2
  , in_bank_cnt2       IN  NUMBER       -- �p�����[�^�F�d����s2�ւ̈�����
  , iv_internal_bank3  IN  VARCHAR2     -- �p�����[�^�F���s���d����s3
  , in_bank_cnt3       IN  NUMBER       -- �p�����[�^�F�d����s3�ւ̈�����
  , iv_internal_bank4  IN  VARCHAR2     -- �p�����[�^�F���s���d����s4
  , in_bank_cnt4       IN  NUMBER       -- �p�����[�^�F�d����s4�ւ̈�����
  , iv_internal_bank5  IN  VARCHAR2     -- �p�����[�^�F���s���d����s5
  , in_bank_cnt5       IN  NUMBER       -- �p�����[�^�F�d����s5�ւ̈�����
  , iv_internal_bank6  IN  VARCHAR2     -- �p�����[�^�F���s���d����s6
  , in_bank_cnt6       IN  NUMBER       -- �p�����[�^�F�d����s6�ւ̈�����
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name      CONSTANT       VARCHAR2(100) := 'init';     -- �v���O������
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf        VARCHAR2(5000) DEFAULT NULL;          -- �G���[�E���b�Z�[�W
    lv_retcode       VARCHAR2(1)    DEFAULT NULL;          -- ���^�[���E�R�[�h
    lv_errmsg        VARCHAR2(5000) DEFAULT NULL;          -- ���[�U�[�E�G���[�E���b�Z�[�W
    ln_errout        NUMBER         DEFAULT 0;             -- �G���[�o�͐�
    lb_retcode       BOOLEAN;                              -- ���b�Z�[�W
    lv_profile       VARCHAR2(35)   DEFAULT NULL;          -- �v���t�@�C��
    lv_in_code       fnd_lookup_values.lookup_code%TYPE   DEFAULT NULL;
    lv_bank_code     fnd_lookup_values.lookup_code%TYPE   DEFAULT NULL;
    lv_dupli_code    fnd_lookup_values.lookup_code%TYPE   DEFAULT NULL;
    lv_dupli_name    fnd_lookup_values.lookup_code%TYPE   DEFAULT NULL;
    -- ===============================================
    -- ���[�J���J�[�\��
    -- ===============================================
    -- 6.���̓p�����[�^�`�F�b�N
    -- ���̓p�����[�^��s��FB���s���d����s�o�^�̃`�F�b�N�J�[�\��
    CURSOR fb_lookup_bank_ck_cur(iv_code IN VARCHAR2)
    IS
    SELECT MAX(flv.lookup_code) AS  internal_bank       -- ��d����s�U������s
          ,MAX(flv.meaning)     AS  internal_bank_name  -- ��d����s�U������s��
    FROM   fnd_lookup_values flv
    WHERE  flv.lookup_type  = cv_lookup_type_fb
    AND    flv.lookup_code  = iv_code                   -- ���̓p�����[�^��s
    AND    flv.attribute10  = cv_yes                    -- ���s���U�����Ώۋ敪
    AND    flv.enabled_flag = cv_yes
    AND    gd_proc_date BETWEEN NVL(flv.start_date_active, gd_proc_date)
                                AND NVL(flv.end_date_active, gd_proc_date)
    AND    flv.language     = USERENV('LANG')
    ORDER BY flv.lookup_code
    ;
--
    -- 7.FB���s���d����s�o�^�`�F�b�N�J�[�\��
    CURSOR fb_lookup_bank_dff_ck_cur
    IS
    SELECT MIN(flv.lookup_code) AS  internal_bank       -- ��d����s�U������s
    FROM   fnd_lookup_values flv
    WHERE  flv.lookup_type  = cv_lookup_type_fb
    AND   (flv.attribute1 IS NULL
      OR   flv.attribute2 IS NULL
      OR   flv.attribute3 IS NULL
      OR   flv.attribute4 IS NULL
      OR   flv.attribute5 IS NULL
      OR   flv.attribute6 IS NULL
      OR   flv.attribute7 IS NULL
      OR   flv.attribute8 IS NULL)
    AND    flv.enabled_flag = cv_yes
    AND    gd_proc_date BETWEEN NVL(flv.start_date_active, gd_proc_date)
                                AND NVL(flv.end_date_active, gd_proc_date)
    AND    flv.language     = USERENV('LANG')
    ;
--
    -- 8.�Q�ƕ\�iFB���s���d����s�j�o�^���Ƌ�s�x�X�}�X�^�̐������`�F�b�N�J�[�\��
    CURSOR fb_bank_number_ck_cur
    IS
    SELECT flv.lookup_code AS  internal_bank            -- ��d����s�U������s
          ,abb.bank_number AS  bank_number              -- ��s�ԍ�
    FROM   fnd_lookup_values flv                        -- �Q�ƕ\�iFB���s���d����s�j
          ,ap_bank_branches  abb                        -- ��s�x�X�}�X�^
    WHERE  flv.lookup_type  = cv_lookup_type_fb
    AND    flv.lookup_code  = abb.bank_number(+)        -- ��s�ԍ�
    AND    flv.enabled_flag = cv_yes
    AND    gd_proc_date BETWEEN NVL(flv.start_date_active, gd_proc_date)
                                AND NVL(flv.end_date_active, gd_proc_date)
    AND    flv.language     = USERENV('LANG')
    GROUP BY flv.lookup_code, abb.bank_number
    ORDER BY flv.lookup_code, abb.bank_number
    ;
--
    -- 9.�Q�ƕ\�iFB���s���d����s�j�U���Ώۋ�s��FB�p���Ќ�����s�̃`�F�b�N�J�[�\��
    CURSOR fb_internal_bank_ck_cur
    IS
    SELECT flv.attribute1             AS  internal_bank           -- ��d����s�U������s
          ,MAX(abaa.eft_requester_id) AS  eft_requester           -- �˗��l�R�[�h
    FROM    ap_bank_accounts_all      abaa                        -- ��s�����}�X�^
           ,ap_bank_branches          abb                         -- ��s�x�X�}�X�^
           ,fnd_lookup_values         flv                         -- �Q�ƕ\�iFB���s���d����s�j
    WHERE  abaa.bank_branch_id(+)   = abb.bank_branch_id
    AND    abaa.org_id(+)           = TO_NUMBER( gt_prof_org_id ) -- �c�ƒP��
    AND    abaa.account_type(+)     = gt_prof_acc_type_internal   -- �����g�p�i'INTERNAL'�j
    AND    abaa.eft_requester_id(+) IS NOT NULL
    AND    flv.lookup_type          = cv_lookup_type_fb
    AND    flv.lookup_code          = abb.bank_number
    AND   (flv.attribute9   = cv_yes                              -- �d����s�����U���敪
      OR   flv.attribute10  = cv_yes)                             -- ���s���U�����Ώۋ敪
    AND    flv.enabled_flag = cv_yes
    AND    gd_proc_date BETWEEN NVL(flv.start_date_active, gd_proc_date)
                                AND NVL(flv.end_date_active, gd_proc_date)
    AND    flv.language     = USERENV('LANG')
    GROUP BY flv.attribute1
    ORDER BY flv.attribute1
    ;
--
    -- 10.FB���s���d����s���Ƌ�s�����}�X�^�̐������`�F�b�N�J�[�\��
    CURSOR fb_bank_accounts_ck_cur
    IS
    SELECT flv.lookup_code AS  internal_bank                      -- ��d����s�U������s
    FROM    ap_bank_accounts_all          abaa                    -- ��s�����}�X�^
           ,ap_bank_branches              abb                     -- ��s�x�X�}�X�^
           ,fnd_lookup_values             flv
    WHERE  abaa.bank_branch_id    = abb.bank_branch_id
    AND    abaa.org_id            = TO_NUMBER( gt_prof_org_id )   -- �c�ƒP��
    AND    abaa.account_type      = gt_prof_acc_type_internal     -- �����g�p�i'INTERNAL'�j
    AND    abaa.eft_requester_id IS NOT NULL
    AND    flv.lookup_type        = cv_lookup_type_fb
    AND    flv.lookup_code        = abb.bank_number
    AND   (abb.bank_number              <> flv.attribute1         -- ��s�ԍ�
      OR   abb.bank_name_alt            <> flv.attribute2         -- ��s���J�i
      OR   abb.bank_num                 <> flv.attribute3         -- �x�X�ԍ�
      OR   abb.bank_branch_name_alt     <> flv.attribute4         -- ��s�x�X���J�i
      OR   abaa.bank_account_type       <> flv.attribute5         -- ��s�������
      OR   abaa.bank_account_num        <> flv.attribute6         -- �����ԍ�
      OR   abaa.eft_requester_id        <> flv.attribute7         -- �˗��l�R�[�h
      OR   abaa.account_holder_name_alt <> flv.attribute8)        -- �������`�l�J�i�i�˗��l���j
    AND    flv.enabled_flag = cv_yes
    AND    gd_proc_date BETWEEN NVL(flv.start_date_active, gd_proc_date)
                                AND NVL(flv.end_date_active, gd_proc_date)
    AND    flv.language     = USERENV('LANG')
    ORDER BY flv.lookup_code
    ;
--
    --===============================
    -- ���[�J����O
    --===============================
    --*** ���������G���[ ***
    no_profile_expt            EXCEPTION; -- �v���t�@�C���l�擾�G���[
    init_fail_expt             EXCEPTION; -- ���������G���[
    init_warning_expt          EXCEPTION; -- ���������x���G���[
    init_othes_expt            EXCEPTION; -- ����������O�G���[
--
  BEGIN
    -- �X�e�[�^�X������
    ov_retcode := cv_status_normal;
    --==========================================================
    --1.���̓p�����[�^�`�F�b�N
    --==========================================================
    -- FB�t�@�C���쐬�v��ID
    IF( in_request_id IS NULL ) THEN
      -- �W���u�N���̎�
      SELECT MAX(request_id) INTO gn_request_id FROM xxcok_fb_lines_work;
      IF( gn_request_id IS NULL ) THEN
        -- FB�t�@�C���쐬�v��ID���擾�o���Ȃ����A�x���I��
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appli_xxcok
                        ,iv_name         => cv_msg_cok_10872
                        ,iv_token_name1  => cv_token_request_id
                        ,iv_token_value1 => TO_CHAR(gn_request_id)
                       );
        RAISE init_warning_expt;
      END IF;
    ELSE
      -- �������s
      SELECT MAX(request_id) INTO gn_request_id FROM xxcok_fb_lines_work WHERE request_id = in_request_id;
      IF( gn_request_id IS NULL ) THEN
        -- �p�����[�^�w���FB�t�@�C���쐬�v��ID���擾�o���Ȃ����A�G���[�I��
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appli_xxcok
                        ,iv_name         => cv_msg_cok_10867
                        ,iv_token_name1  => cv_token_request_id
                        ,iv_token_value1 => TO_CHAR(gn_request_id)
                       );
        RAISE init_fail_expt;
      END IF;
    END IF;
    --==========================================================
    --2.�R���J�����g�E�v���O�������͍��ڃ��b�Z�[�W�o��
    --==========================================================
    lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appli_xxcok
                   ,iv_name         => cv_msg_cok_10865
                   -- FB�t�@�C���쐬�v��ID
                   ,iv_token_name1  => cv_token_request_id
                   ,iv_token_value1 => TO_CHAR(gn_request_id)
                   -- 1.���s���d���s�A������
                   ,iv_token_name2  => cv_token_fb_bank1
                   ,iv_token_value2 => iv_internal_bank1
                   ,iv_token_name3  => cv_token_fb_bank_cnt1
                   ,iv_token_value3 => TO_CHAR(in_bank_cnt1)
                   -- 2.���s���d���s�A������
                   ,iv_token_name4  => cv_token_fb_bank2
                   ,iv_token_value4 => iv_internal_bank2
                   ,iv_token_name5  => cv_token_fb_bank_cnt2
                   ,iv_token_value5 => TO_CHAR(in_bank_cnt2)
                   -- 3.���s���d���s�A������
                   ,iv_token_name6  => cv_token_fb_bank3
                   ,iv_token_value6 => iv_internal_bank3
                   ,iv_token_name7  => cv_token_fb_bank_cnt3
                   ,iv_token_value7 => TO_CHAR(in_bank_cnt3)
                   -- 4.���s���d���s�A������
                   ,iv_token_name8  => cv_token_fb_bank4
                   ,iv_token_value8 => iv_internal_bank4
                   ,iv_token_name9  => cv_token_fb_bank_cnt4
                   ,iv_token_value9 => TO_CHAR(in_bank_cnt4)
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG        -- �o�͋敪
                   ,iv_message  => lv_errmsg           -- ���b�Z�[�W
                   ,in_new_line => 0                   -- ���s
                  );
    --==========================================================
    --3.�R���J�����g�E�v���O�������͊g�����ڃ��b�Z�[�W�o��
    --==========================================================
    IF (iv_internal_bank5 || iv_internal_bank6) IS NOT NULL THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appli_xxcok
                     ,iv_name         => cv_msg_cok_10866
                     -- 5.���s���d���s�A������
                     ,iv_token_name1  => cv_token_fb_bank5
                     ,iv_token_value1 => iv_internal_bank5
                     ,iv_token_name2  => cv_token_fb_bank_cnt5
                     ,iv_token_value2 => TO_CHAR(in_bank_cnt5)
                     -- 6.���s���d���s�A������
                     ,iv_token_name3  => cv_token_fb_bank6
                     ,iv_token_value3 => iv_internal_bank6
                     ,iv_token_name4  => cv_token_fb_bank_cnt6
                     ,iv_token_value4 => TO_CHAR(in_bank_cnt6)
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG        -- �o�͋敪
                     ,iv_message  => lv_errmsg           -- ���b�Z�[�W
                     ,in_new_line => 0                   -- ���s
                    );
    END IF;
--
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG         -- �o�͋敪
                   ,iv_message  => NULL                 -- ���b�Z�[�W
                   ,in_new_line => 1                    -- ���s
                  );
    --==========================================================
    --4.�Ɩ��������t�擾
    --==========================================================
    gd_proc_date := xxccp_common_pkg2.get_process_date;
    IF( gd_proc_date IS NULL ) THEN
      -- �Ɩ��������t�擾�G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appli_xxcok
                      ,iv_name         => cv_msg_cok_00028
                     );
      RAISE init_fail_expt;
    END IF;
    --==========================================================
    --5.�v���t�@�C���̎擾
    --6.�J�X�^���E�v���t�@�C���̎擾
    --==========================================================
    gt_prof_org_id              := FND_PROFILE.VALUE( cv_prof_org_id );               -- MO: �c�ƒP��
    gt_prof_acc_type_internal   := FND_PROFILE.VALUE( cv_prof_acc_type_internal );    -- XXCOK:�̔��萔��_����_�����g�p
--
      -- �v���t�@�C���l�擾�G���[
    IF( gt_prof_org_id IS NULL ) THEN
      lv_profile := cv_prof_org_id;
      RAISE no_profile_expt;
    END IF;
    IF( gt_prof_acc_type_internal IS NULL ) THEN
      lv_profile := cv_prof_acc_type_internal;
      RAISE no_profile_expt;
    END IF;
--
    -- FB���s���d����s
    <<fb_bank_ck_loop>>
    FOR i IN 1 .. 6 LOOP
      IF i = 1 THEN
        lv_in_code := iv_internal_bank1;
      ELSIF  i = 2 THEN
        lv_in_code := iv_internal_bank2;
      ELSIF  i = 3 THEN
        lv_in_code := iv_internal_bank3;
      ELSIF  i = 4 THEN
        lv_in_code := iv_internal_bank4;
      ELSIF  i = 5 THEN
        lv_in_code := iv_internal_bank5;
      ELSIF  i = 6 THEN
        lv_in_code := iv_internal_bank6;
      END IF;
--
      IF lv_in_code IS NOT NULL THEN
        -- ���̓p�����[�^��s��FB���s���d����s�o�^�̃`�F�b�N
        OPEN  fb_lookup_bank_ck_cur(lv_in_code);
        FETCH fb_lookup_bank_ck_cur INTO lv_bank_code, lv_dupli_name;
        CLOSE fb_lookup_bank_ck_cur;
        IF( lv_bank_code IS NULL ) THEN
          -- FB���s���d����s�擾�G���[
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appli_xxcok
                          ,iv_name         => cv_msg_cok_10868
                          ,iv_token_name1  => cv_token_dist_bank
                          ,iv_token_value1 => lv_in_code
                         );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.LOG      -- �o�͋敪
                         ,iv_message  => lv_errmsg         -- ���b�Z�[�W
                         ,in_new_line => 0                 -- ���s
                        );
          ln_errout := ln_errout + 1;
        END IF;
        IF i = 1 THEN
          IF   lv_in_code = NVL(iv_internal_bank2,'N') OR lv_in_code = NVL(iv_internal_bank3,'N') OR lv_in_code = NVL(iv_internal_bank4,'N') 
            OR lv_in_code = NVL(iv_internal_bank5,'N') OR lv_in_code = NVL(iv_internal_bank6,'N') THEN
            lv_dupli_code := lv_in_code;
          END IF;
        ELSIF  i = 2 THEN
          IF   lv_in_code = NVL(iv_internal_bank3,'N') OR lv_in_code = NVL(iv_internal_bank4,'N') 
            OR lv_in_code = NVL(iv_internal_bank5,'N') OR lv_in_code = NVL(iv_internal_bank6,'N') THEN
            lv_dupli_code := lv_in_code;
          END IF;
        ELSIF  i = 3 THEN
          IF   lv_in_code = NVL(iv_internal_bank4,'N') 
            OR lv_in_code = NVL(iv_internal_bank5,'N') OR lv_in_code = NVL(iv_internal_bank6,'N') THEN
            lv_dupli_code := lv_in_code;
          END IF;
        ELSIF  i = 4 THEN
          IF   lv_in_code = NVL(iv_internal_bank5,'N') OR lv_in_code = NVL(iv_internal_bank6,'N') THEN
            lv_dupli_code := lv_in_code;
          END IF;
        ELSIF  i = 5 THEN
          IF   lv_in_code = NVL(iv_internal_bank6,'N') THEN
            lv_dupli_code := lv_in_code;
          END IF;
        END IF;
      END IF;
    END LOOP fb_bank_ck_loop;
--
    IF ln_errout > 0 THEN
      lv_errmsg := NULL;
      RAISE init_othes_expt;
    END IF;
--
    IF lv_dupli_code IS NOT NULL THEN
      -- FB���s���d����s�p�����[�^�d���G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appli_xxcok
                      ,iv_name         => cv_msg_cok_10874
                      ,iv_token_name1  => cv_token_dupli_bank
                      ,iv_token_value1 => lv_dupli_code || cv_msg_part || lv_dupli_name
                     );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG      -- �o�͋敪
                     ,iv_message  => lv_errmsg         -- ���b�Z�[�W
                     ,in_new_line => 0                 -- ���s
                    );
      lv_errmsg := NULL;
      RAISE init_othes_expt;
    END IF;
--
    --==========================================================
    --7.�Q�ƕ\�iFB���s���d����s�j�̓o�^�`�F�b�N
    --==========================================================
    BEGIN
      lv_bank_code := NULL;
      OPEN  fb_lookup_bank_dff_ck_cur;
      FETCH fb_lookup_bank_dff_ck_cur INTO lv_bank_code;
      CLOSE fb_lookup_bank_dff_ck_cur;
--
      IF( lv_bank_code IS NOT NULL ) THEN
        -- FB���s���d����s����`�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appli_xxcok
                        ,iv_name         => cv_msg_cok_10869
                        ,iv_token_name1  => cv_token_dist_bank
                        ,iv_token_value1 => lv_bank_code
                       );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.LOG      -- �o�͋敪
                       ,iv_message  => lv_errmsg         -- ���b�Z�[�W
                       ,in_new_line => 0                 -- ���s
                      );
        lv_errmsg := NULL;
        RAISE init_othes_expt;
      END IF;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
    --=====================================================================
    --8.�Q�ƕ\�iFB���s���d����s�j�o�^���Ƌ�s�x�X�}�X�^�̐������`�F�b�N
    --=====================================================================
    ln_errout := 0;
    <<fb_bank_ck_loop>>
    FOR lt_bank_ck_rec in fb_bank_number_ck_cur LOOP
      IF( lt_bank_ck_rec.bank_number IS NULL ) THEN
        -- FB���s���d����s�������G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appli_xxcok
                        ,iv_name         => cv_msg_cok_10870
                        ,iv_token_name1  => cv_token_dist_bank
                        ,iv_token_value1 => lt_bank_ck_rec.internal_bank
                       );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.LOG      -- �o�͋敪
                       ,iv_message  => lv_errmsg         -- ���b�Z�[�W
                       ,in_new_line => 0                 -- ���s
                      );
        ln_errout := ln_errout + 1;
      END IF;
    END LOOP fb_bank_ck_loop;
--
    IF ln_errout > 0 THEN
      lv_errmsg := NULL;
      RAISE init_othes_expt;
    END IF;
--
    --=====================================================================
    --9.�Q�ƕ\�iFB���s���d����s�j�U���Ώۋ�s��FB�p���Ќ�����s�̃`�F�b�N
    --=====================================================================
    ln_errout := 0;
    <<fb_bank_ck_loop>>
    FOR lt_internal_bank_rec in fb_internal_bank_ck_cur LOOP
      IF( lt_internal_bank_rec.eft_requester IS NULL ) THEN
        -- FB�p���Ќ�����s�������G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appli_xxcok
                        ,iv_name         => cv_msg_cok_10875
                        ,iv_token_name1  => cv_token_dist_bank
                        ,iv_token_value1 => lt_internal_bank_rec.internal_bank
                       );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.LOG      -- �o�͋敪
                       ,iv_message  => lv_errmsg         -- ���b�Z�[�W
                       ,in_new_line => 0                 -- ���s
                      );
        ln_errout := ln_errout + 1;
      END IF;
    END LOOP fb_bank_ck_loop;
--
    IF ln_errout > 0 THEN
      lv_errmsg := NULL;
      RAISE init_othes_expt;
    END IF;
--
    --======================================================================
    --10.�Q�ƕ\�iFB���s���d����s�j�o�^���Ƌ�s�����}�X�^�̐������`�F�b�N
    --======================================================================
    ln_errout := 0;
    <<fb_bank_ck_loop>>
    FOR lt_bank_accounts_rec in fb_bank_accounts_ck_cur LOOP
      IF( lt_bank_accounts_rec.internal_bank IS NOT NULL ) THEN
        -- ��s�����}�X�^�������G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appli_xxcok
                        ,iv_name         => cv_msg_cok_10871
                        ,iv_token_name1  => cv_token_dist_bank
                        ,iv_token_value1 => lt_bank_accounts_rec.internal_bank
                       );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.LOG      -- �o�͋敪
                       ,iv_message  => lv_errmsg         -- ���b�Z�[�W
                       ,in_new_line => 0                 -- ���s
                      );
        ln_errout := ln_errout + 1;
      END IF;
    END LOOP fb_bank_ck_loop;
--
    IF ln_errout > 0 THEN
      lv_errmsg := NULL;
      RAISE init_othes_expt;
    END IF;
--
  EXCEPTION
    -- *** ���������x���I�� ***
    WHEN init_warning_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_warn;
    -- *** ���������G���[ ***
    WHEN init_fail_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    WHEN init_othes_expt THEN
      -- *** ����������O�n���h�� ***
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_error;
    WHEN no_profile_expt THEN
      -- *** �v���t�@�C���擾��O�n���h�� ***
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appli_xxcok
                     ,iv_name         => cv_msg_cok_00003
                     ,iv_token_name1  => cv_token_profile
                     ,iv_token_value1 => lv_profile
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  END init;
--
  /**********************************************************************************
   * Procedure Name   : init_update_data
   * Description      : ���������e�[�u���X�V(A-2)
   ***********************************************************************************/
  PROCEDURE init_update_data(
    ov_errbuf          OUT VARCHAR2     -- �G���[�E���b�Z�[�W
  , ov_retcode         OUT VARCHAR2     -- ���^�[���E�R�[�h
  , ov_errmsg          OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W
  , iv_internal_bank1  IN  VARCHAR2     -- �p�����[�^�F���s���d����s1
  , in_bank_cnt1       IN  NUMBER       -- �p�����[�^�F�d����s1�ւ̈�����
  , iv_internal_bank2  IN  VARCHAR2     -- �p�����[�^�F���s���d����s2
  , in_bank_cnt2       IN  NUMBER       -- �p�����[�^�F�d����s2�ւ̈�����
  , iv_internal_bank3  IN  VARCHAR2     -- �p�����[�^�F���s���d����s3
  , in_bank_cnt3       IN  NUMBER       -- �p�����[�^�F�d����s3�ւ̈�����
  , iv_internal_bank4  IN  VARCHAR2     -- �p�����[�^�F���s���d����s4
  , in_bank_cnt4       IN  NUMBER       -- �p�����[�^�F�d����s4�ւ̈�����
  , iv_internal_bank5  IN  VARCHAR2     -- �p�����[�^�F���s���d����s5
  , in_bank_cnt5       IN  NUMBER       -- �p�����[�^�F�d����s5�ւ̈�����
  , iv_internal_bank6  IN  VARCHAR2     -- �p�����[�^�F���s���d����s6
  , in_bank_cnt6       IN  NUMBER       -- �p�����[�^�F�d����s6�ւ̈�����
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'init_update_data';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lb_retcode       BOOLEAN;                                                   -- ���b�Z�[�W
    lv_in_code       fnd_lookup_values.lookup_code%TYPE   DEFAULT NULL;
    ln_in_cnt        NUMBER         DEFAULT 0;                                  -- ������
    lv_tbl_nm        VARCHAR2(100);                                             -- �e�[�u����
    --===============================
    -- ���[�J����O
    --===============================
    init_othes_expt            EXCEPTION; -- ����������O�G���[
    -- ===============================================
    -- ���[�J���J�[�\��
    -- ===============================================
    CURSOR fb_lookup_cur
    IS
      SELECT 'X'
      FROM   fnd_lookup_values flv
      WHERE  flv.lookup_type  = cv_lookup_type_fb
      FOR UPDATE OF flv.lookup_code NOWAIT;
--
    CURSOR fb_lines_cur
    IS
      SELECT 'X'
      FROM   xxcok_fb_lines_work  xflw
      WHERE  xflw.request_id = gn_request_id
      FOR UPDATE OF xflw.request_id NOWAIT;
--
    --  FB�f�[�^�t�@�C���쐬���̎��Ћ�s�iFB�w�b�_�[�j�擾�J�[�\��
    CURSOR vdbm_fb_bank_cur
    IS
    SELECT MAX(flv.attribute1) AS  internal_bank       --FB�f�[�^�t�@�C���쐬���Ћ�s
    FROM   fnd_lookup_values flv
    WHERE  flv.lookup_type  = cv_lookup_type_bank
    AND    flv.lookup_code  = cv_lookup_code_bank
    AND    flv.enabled_flag = cv_yes
    AND    gd_proc_date BETWEEN NVL(flv.start_date_active, gd_proc_date)
                                AND NVL(flv.end_date_active, gd_proc_date)
    AND    flv.language     = USERENV('LANG')
    ;
--
  BEGIN
    -- ===============================================
    -- �X�e�[�^�X������
    -- ===============================================
    ov_retcode := cv_status_normal;
     -- ========================================================
    -- 1.�Q�ƕ\�iFB���s���d����s�j�e�[�u���ւ̈������̓o�^
    -- =========================================================
    lv_tbl_nm := cv_loopup_tbl_nm;
--
    -- ===============================================
    -- �Q�ƕ\�iFB���s���d����s�j���b�N�擾
    -- ===============================================
    OPEN  fb_lookup_cur;
    CLOSE fb_lookup_cur;
    -- ===============================================
    -- �Q�ƕ\�iFB���s���d����s�j�f�[�^�X�V
    -- ===============================================
    -- �O����s�̈������A���׍��v���z���N���A
    BEGIN
      UPDATE fnd_lookup_values flv
      SET    flv.attribute11  = NULL
            ,flv.attribute12  = NULL
      WHERE  flv.lookup_type  = cv_lookup_type_fb
      AND    flv.enabled_flag = cv_yes
      AND    gd_proc_date BETWEEN NVL(flv.start_date_active, gd_proc_date)
                                  AND NVL(flv.end_date_active, gd_proc_date)
      AND    flv.language     = USERENV('LANG')
      ;
    EXCEPTION
      -- *** �X�V�����G���[ ***
      WHEN OTHERS THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appli_xxcok                       -- �A�v���P�[�V�����Z�k��
                 ,iv_name         => cv_msg_cok_10864                     -- ���b�Z�[�W�R�[�h
                 ,iv_token_name1  => cv_tkn_tbl                           -- �g�[�N���R�[�h1
                 ,iv_token_value1 => lv_tbl_nm                            -- �g�[�N���l1
                 ,iv_token_name2  => cv_tkn_err_msg                       -- �g�[�N���R�[�h2
                 ,iv_token_value2 => SQLERRM                              -- �g�[�N���l2
                );
        lv_errbuf := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_error;
    END;
--
    -- �p�����[�^���͂��ꂽ�������̓o�^
    <<fb_bank_ck_loop>>
    FOR i IN 1 .. 6 LOOP
      IF i = 1 THEN
        lv_in_code := iv_internal_bank1;
        ln_in_cnt  := in_bank_cnt1;
      ELSIF  i = 2 THEN
        lv_in_code := iv_internal_bank2;
        ln_in_cnt  := in_bank_cnt2;
      ELSIF  i = 3 THEN
        lv_in_code := iv_internal_bank3;
        ln_in_cnt  := in_bank_cnt3;
      ELSIF  i = 4 THEN
        lv_in_code := iv_internal_bank4;
        ln_in_cnt  := in_bank_cnt4;
      ELSIF  i = 5 THEN
        lv_in_code := iv_internal_bank5;
        ln_in_cnt  := in_bank_cnt5;
      ELSIF  i = 6 THEN
        lv_in_code := iv_internal_bank6;
        ln_in_cnt  := in_bank_cnt6;
      END IF;
      IF NVL (ln_in_cnt, 0 ) = 0 THEN
        ln_in_cnt := NULL;
      END IF;
--
      BEGIN
        UPDATE fnd_lookup_values flv
        SET    flv.attribute11  = TO_CHAR(ln_in_cnt, '999,999')
        WHERE  flv.lookup_type  = cv_lookup_type_fb
        AND    flv.lookup_code  = lv_in_code
        AND    flv.enabled_flag = cv_yes
        AND    gd_proc_date BETWEEN NVL(flv.start_date_active, gd_proc_date)
                                    AND NVL(flv.end_date_active, gd_proc_date)
        AND    flv.language     = USERENV('LANG')
        ;
      EXCEPTION
        -- *** �X�V�����G���[ ***
        WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appli_xxcok                       -- �A�v���P�[�V�����Z�k��
                   ,iv_name         => cv_msg_cok_10864                     -- ���b�Z�[�W�R�[�h
                   ,iv_token_name1  => cv_tkn_tbl                           -- �g�[�N���R�[�h1
                   ,iv_token_value1 => lv_tbl_nm                            -- �g�[�N���l1
                   ,iv_token_name2  => cv_tkn_err_msg                       -- �g�[�N���R�[�h2
                   ,iv_token_value2 => SQLERRM                              -- �g�[�N���l2
                  );
          lv_errbuf := lv_errmsg;
          ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
          ov_retcode := cv_status_error;
      END;
    END LOOP fb_bank_ck_loop;
--
    -- ===============================================
    -- 2.FB�f�[�^���׃��[�N�e�[�u���E�f�[�^�X�V
    -- ===============================================
    lv_tbl_nm := cv_wk_tbl_nm;
    --  FB�f�[�^�t�@�C���쐬���̎��Ћ�s�擾
    OPEN  vdbm_fb_bank_cur;
    FETCH vdbm_fb_bank_cur INTO gv_default_bank_code;
    CLOSE vdbm_fb_bank_cur;
--
    IF( gv_default_bank_code IS NULL ) THEN
      -- FB���Ћ�s�擾�G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appli_xxcok
                      ,iv_name         => cv_msg_cok_10873
                      ,iv_token_name1  => cv_loopup_type
                      ,iv_token_value1 => cv_lookup_type_bank
                     );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG      -- �o�͋敪
                     ,iv_message  => lv_errmsg         -- ���b�Z�[�W
                     ,in_new_line => 0                 -- ���s
                    );
      lv_errmsg := NULL;
      RAISE init_othes_expt;
    ELSE
      -- ===============================================
      -- FB�f�[�^���׃��[�N�e�[�u�����b�N�擾
      -- ===============================================
      OPEN  fb_lines_cur;
      CLOSE fb_lines_cur;
      -- ===============================================
      -- FB�f�[�^���׃��[�N�e�[�u���E�f�[�^�X�V
      -- ===============================================
      BEGIN
        UPDATE xxcok_fb_lines_work  xflw
        SET    xflw.internal_bank_number = gv_default_bank_code
              ,xflw.implemented_flag     = NULL
        WHERE  xflw.request_id = gn_request_id
        AND    xflw.implemented_flag IS NOT NULL
        ;
      EXCEPTION
        -- *** �X�V�����G���[ ***
        WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appli_xxcok                       -- �A�v���P�[�V�����Z�k��
                   ,iv_name         => cv_msg_cok_10864                     -- ���b�Z�[�W�R�[�h
                   ,iv_token_name1  => cv_tkn_tbl                           -- �g�[�N���R�[�h1
                   ,iv_token_value1 => lv_tbl_nm                            -- �g�[�N���l1
                   ,iv_token_name2  => cv_tkn_err_msg                       -- �g�[�N���R�[�h2
                   ,iv_token_value2 => SQLERRM                              -- �g�[�N���l2
                  );
          lv_errbuf := lv_errmsg;
          ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
          ov_retcode := cv_status_error;
      END;
    END IF;
--
  EXCEPTION
    -- *** ����������O�n���h�� ***
    WHEN init_othes_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_error;
    --*** ���b�N�G���[ ***
    WHEN global_lock_err_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appli_xxcok                       -- �A�v���P�[�V�����Z�k��
                 ,iv_name         => cv_msg_cok_10863                     -- ���b�Z�[�W�R�[�h
                 ,iv_token_name1  => cv_tkn_tbl                           -- �g�[�N���R�[�h1
                 ,iv_token_value1 => lv_tbl_nm                            -- �g�[�N���l1
                 ,iv_token_name2  => cv_tkn_err_msg                       -- �g�[�N���R�[�h2
                 ,iv_token_value2 => SQLERRM                              -- �g�[�N���l2
                );
      lv_errbuf := lv_errmsg;
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
  END init_update_data;
--
  /**********************************************************************************
   * Procedure Name   : auto_distribute_proc
   * Description      : FB�f�[�^�����U�蕪������(A-3)
   ***********************************************************************************/
  PROCEDURE auto_distribute_proc(
    ov_errbuf          OUT VARCHAR2     -- �G���[�E���b�Z�[�W
  , ov_retcode         OUT VARCHAR2     -- ���^�[���E�R�[�h
  , ov_errmsg          OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name        CONSTANT VARCHAR2(100)   := 'auto_distribute_proc';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lb_retcode       BOOLEAN;                                                   -- ���b�Z�[�W
    ln_in_cnt        NUMBER         DEFAULT 0;                                  -- ������
    -- ===============================================
    -- ���[�J���J�[�\��
    -- ===============================================
    CURSOR fb_lines_cur
    IS
    SELECT 'X'
    FROM   xxcok_fb_lines_work  xflw
    WHERE  xflw.request_id = gn_request_id
    FOR UPDATE OF xflw.request_id NOWAIT
    ;
--
    -- �����U�蕪����s�擾�J�[�\��
    CURSOR get_auto_sub_cur
    IS
    SELECT flv.attribute1 AS  internal_bank            -- �U����s
    FROM   xxcok_fb_lines_work  xflw
          ,fnd_lookup_values    flv
    WHERE xflw.request_id = gn_request_id
    AND   flv.lookup_type = cv_lookup_type_fb
    AND   flv.lookup_code = xflw.bank_number
    AND   NVL(flv.attribute9, cv_no) = cv_yes
    AND   flv.enabled_flag = cv_yes
    AND   gd_proc_date BETWEEN NVL(flv.start_date_active, gd_proc_date)
                               AND NVL(flv.end_date_active, gd_proc_date)
    AND   flv.language    = USERENV('LANG')
    ORDER BY xflw.base_code, xflw.supplier_code
    FOR UPDATE OF xflw.request_id NOWAIT
    ;
--
  BEGIN
    -- ===============================================
    -- �X�e�[�^�X������
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- FB�f�[�^���׃��[�N�e�[�u�����b�N�擾
    -- ===============================================
    OPEN  fb_lines_cur;
    CLOSE fb_lines_cur;
    -- ===============================================
    -- FB�f�[�^���׃��[�N�e�[�u���E�f�[�^�X�V
    -- ===============================================
    BEGIN
      <<fb_bank_ck_loop>>
      -- �����U�蕪�����s�X�V
      FOR lt_auto_sub_rec in get_auto_sub_cur LOOP
        UPDATE xxcok_fb_lines_work  xflw
        SET    xflw.internal_bank_number = lt_auto_sub_rec.internal_bank  -- �d�����Z�@�֔ԍ�
              ,xflw.implemented_flag     = cv_auto                        -- FB�U�����s�ϋ敪
        WHERE CURRENT OF get_auto_sub_cur
        ;
      END LOOP fb_bank_ck_loop;
    EXCEPTION
      -- *** �X�V�����G���[ ***
      WHEN OTHERS THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appli_xxcok                       -- �A�v���P�[�V�����Z�k��
                 ,iv_name         => cv_msg_cok_10864                     -- ���b�Z�[�W�R�[�h
                 ,iv_token_name1  => cv_tkn_tbl                           -- �g�[�N���R�[�h1
                 ,iv_token_value1 => cv_wk_tbl_nm                         -- �g�[�N���l1
                 ,iv_token_name2  => cv_tkn_err_msg                       -- �g�[�N���R�[�h2
                 ,iv_token_value2 => SQLERRM                              -- �g�[�N���l2
                );
        lv_errbuf := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_error;
    END;
--
  EXCEPTION
    --*** ���b�N�G���[ ***
    WHEN global_lock_err_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appli_xxcok                       -- �A�v���P�[�V�����Z�k��
                 ,iv_name         => cv_msg_cok_10863                     -- ���b�Z�[�W�R�[�h
                 ,iv_token_name1  => cv_tkn_tbl                           -- �g�[�N���R�[�h1
                 ,iv_token_value1 => cv_wk_tbl_nm                         -- �g�[�N���l1
                 ,iv_token_name2  => cv_tkn_err_msg                       -- �g�[�N���R�[�h2
                 ,iv_token_value2 => SQLERRM                              -- �g�[�N���l2
                );
      lv_errbuf := lv_errmsg;
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
  END auto_distribute_proc;
--
  /**********************************************************************************
   * Procedure Name   : manual_distribute_proc
   * Description      : FB�f�[�^���U�蕪������(A-4)
   ***********************************************************************************/
  PROCEDURE manual_distribute_proc(
    ov_errbuf          OUT VARCHAR2     -- �G���[�E���b�Z�[�W
  , ov_retcode         OUT VARCHAR2     -- ���^�[���E�R�[�h
  , ov_errmsg          OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'manual_distribute_proc';     -- �v���O������
    cn_bank_max             CONSTANT NUMBER          := 6;                            -- �������ő�6�s
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lb_retcode       BOOLEAN;                                                   -- ���b�Z�[�W
    ln_in_cnt        NUMBER         DEFAULT 0;                                  -- ������
    -- ===============================================
    -- ���[�J���J�[�\��
    -- ===============================================
    CURSOR fb_lines_cur
    IS
      SELECT 'X'
      FROM   xxcok_fb_lines_work  xflw
      WHERE  xflw.request_id = gn_request_id
      FOR UPDATE OF xflw.request_id NOWAIT;
--
    -- ���U�蕪���Ώۋ�s�擾�J�[�\��
    CURSOR get_manual_sub_cur
    IS
    SELECT xflw.internal_bank_number AS  internal_bank_number     -- �U����s
    FROM   xxcok_fb_lines_work   xflw
    WHERE xflw.request_id = gn_request_id
    AND   xflw.implemented_flag IS NULL
    ORDER BY xflw.base_code, xflw.supplier_code
    FOR UPDATE OF xflw.request_id NOWAIT
    ;
--
    -- ���U�蕪�����s�擾�J�[�\��
    CURSOR get_source_bank_cur
    IS
    SELECT flv.attribute1                          AS  bank_number       -- ���s���d����s
          ,TO_NUMBER(flv.attribute11, '999,999')   AS  distribute_cnt    -- ������
    FROM   fnd_lookup_values flv
    WHERE  flv.lookup_type  = cv_lookup_type_fb
    AND    NVL(flv.attribute10, cv_no) = cv_yes              -- ���s���U�����Ώۋ敪
    AND    flv.attribute11  IS NOT NULL                      -- ������
    AND    flv.enabled_flag = cv_yes
    AND    gd_proc_date BETWEEN NVL(flv.start_date_active, gd_proc_date)
                                AND NVL(flv.end_date_active, gd_proc_date)
    AND    flv.language     = USERENV('LANG')
    AND    rownum          <= cn_bank_max                    -- �ő�6�s
    ORDER BY distribute_cnt, flv.attribute1
    ;
--
  BEGIN
    -- ===============================================
    -- �X�e�[�^�X������
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- FB�f�[�^���׃��[�N�e�[�u�����b�N�擾
    -- ===============================================
    OPEN  fb_lines_cur;
    CLOSE fb_lines_cur;
    -- ===============================================
    -- FB�f�[�^���׃��[�N�e�[�u���E�f�[�^�X�V
    -- ===============================================
    BEGIN
      -- ���U�蕪�����s�X�V
      <<source_bank_loop>>
      FOR lt_source_bank_rec in get_source_bank_cur LOOP
        <<manual_sub_loop>>
        FOR lt_manual_sub_rec in get_manual_sub_cur LOOP
          IF lt_source_bank_rec.distribute_cnt > ln_in_cnt THEN
            UPDATE xxcok_fb_lines_work  xflw
            SET    xflw.internal_bank_number = lt_source_bank_rec.bank_number  -- �d�����Z�@�֔ԍ�
                  ,xflw.implemented_flag     = cv_manual                       -- FB�U�����s�ϋ敪
            WHERE CURRENT OF get_manual_sub_cur
            ;
            ln_in_cnt := ln_in_cnt + 1;
          ELSE
            exit;
          END IF;
        END LOOP manual_sub_loop;
        ln_in_cnt := 0;
      END LOOP source_bank_loop;
    EXCEPTION
      -- *** �X�V�����G���[ ***
      WHEN OTHERS THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appli_xxcok                       -- �A�v���P�[�V�����Z�k��
                 ,iv_name         => cv_msg_cok_10864                     -- ���b�Z�[�W�R�[�h
                 ,iv_token_name1  => cv_tkn_tbl                           -- �g�[�N���R�[�h1
                 ,iv_token_value1 => cv_wk_tbl_nm                         -- �g�[�N���l1
                 ,iv_token_name2  => cv_tkn_err_msg                       -- �g�[�N���R�[�h2
                 ,iv_token_value2 => SQLERRM                              -- �g�[�N���l2
                );
        lv_errbuf  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_error;
    END;
--
  EXCEPTION
    --*** ���b�N�G���[ ***
    WHEN global_lock_err_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appli_xxcok                       -- �A�v���P�[�V�����Z�k��
                 ,iv_name         => cv_msg_cok_10863                     -- ���b�Z�[�W�R�[�h
                 ,iv_token_name1  => cv_tkn_tbl                           -- �g�[�N���R�[�h1
                 ,iv_token_value1 => cv_wk_tbl_nm                         -- �g�[�N���l1
                 ,iv_token_name2  => cv_tkn_err_msg                       -- �g�[�N���R�[�h2
                 ,iv_token_value2 => SQLERRM                              -- �g�[�N���l2
                );
      lv_errbuf  := lv_errmsg;
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
  END manual_distribute_proc;
--
  /**********************************************************************************
   * Procedure Name   : fb_header_record
   * Description      : FB�w�b�_�[���R�[�h�o��(A-6)
   ***********************************************************************************/
  PROCEDURE fb_header_record(
     ov_errbuf                  OUT VARCHAR2                             -- �G���[�E���b�Z�[�W
    ,ov_retcode                 OUT VARCHAR2                             -- ���^�[���E�R�[�h
    ,ov_errmsg                  OUT VARCHAR2                             -- ���[�U�[�E�G���[�E���b�Z�[�W
    ,it_header_data_type        IN  VARCHAR2                             -- �w�b�_�[���R�[�h�敪
    ,it_type_code               IN  VARCHAR2                             -- ��ʃR�[�h
    ,it_code_type               IN  VARCHAR2                             -- �R�[�h�敪
    ,it_pay_date                IN  VARCHAR2                             -- �U���w���
    ,it_bank_number             IN  fnd_lookup_values.attribute1%TYPE    -- ��s�ԍ�
    ,it_bank_name_alt           IN  fnd_lookup_values.attribute2%TYPE    -- ��s���J�i
    ,it_bank_num                IN  fnd_lookup_values.attribute3%TYPE    -- ��s�x�X�ԍ�
    ,it_bank_branch_name_alt    IN  fnd_lookup_values.attribute4%TYPE    -- ��s�x�X���J�i
    ,it_bank_account_type       IN  fnd_lookup_values.attribute5%TYPE    -- �a�����
    ,it_bank_account_num        IN  fnd_lookup_values.attribute6%TYPE    -- ��s�����ԍ�
    ,it_eft_requester_id        IN  fnd_lookup_values.attribute7%TYPE    -- �˗��l�R�[�h
    ,it_account_holder_name_alt IN  fnd_lookup_values.attribute8%TYPE    -- �������`�l�J�i
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'fb_header_record';   -- �v���O������
    --================================
    -- ���[�J���ϐ�
    --================================
    lv_errbuf                VARCHAR2(5000) DEFAULT NULL;       -- �G���[�E���b�Z�[�W
    lv_retcode               VARCHAR2(1)    DEFAULT NULL;       -- ���^�[���E�R�[�h
    lv_errmsg                VARCHAR2(5000) DEFAULT NULL;       -- ���[�U�[�E�G���[�E���b�Z�[�W
    lb_retcode               BOOLEAN;                           -- ���b�Z�[�W
    lv_fb_header_data        VARCHAR2(2000) DEFAULT NULL;       -- FB�쐬�w�b�_�[�f�[�^
    lv_sc_client_code        VARCHAR2(10)   DEFAULT NULL;       -- DFF7_�˗��l�R�[�h
    lv_client_name           VARCHAR2(40)   DEFAULT NULL;       -- DFF8_�˗��l��
    lv_bank_number           VARCHAR2(4)    DEFAULT NULL;       -- DFF1_�d�����Z�@�֔ԍ�
    lv_bank_name_alt         VARCHAR2(15)   DEFAULT NULL;       -- DFF2_�d�����Z�@�֖�
    lv_bank_num              VARCHAR2(3)    DEFAULT NULL;       -- DFF3_�d���x�X�ԍ�
    lv_bank_branch_name_alt  VARCHAR2(15)   DEFAULT NULL;       -- DFF4_�d���x�X��
    lv_bank_account_type     VARCHAR2(1)    DEFAULT NULL;       -- DFF5_�a����ځi�˗��l�j
    lv_bank_account_num      VARCHAR2(7)    DEFAULT NULL;       -- DFF6_�����ԍ��i�˗��l�j
    lv_dummy                 VARCHAR2(17)   DEFAULT NULL;       -- �_�~�[
--
  BEGIN
    -- �X�e�[�^�X������
    ov_retcode := cv_status_normal;
--
    lv_sc_client_code       := LPAD( it_eft_requester_id, 10, cv_zero );                  -- DFF7_�˗��l�R�[�h
    lv_client_name          := RPAD( NVL( it_account_holder_name_alt, cv_space ), 40 );   -- DFF8_�˗��l��
    lv_bank_number          := LPAD( NVL( it_bank_number, cv_zero ), 4, cv_zero );        -- DFF1_�d�����Z�@�֔ԍ�
    lv_bank_name_alt        := RPAD( NVL( it_bank_name_alt, cv_space ), 15 );             -- DFF2_�d�����Z�@�֖�
    lv_bank_num             := LPAD( NVL( it_bank_num, cv_zero ), 3, cv_zero );           -- DFF3_�d���x�X�ԍ�
    lv_bank_branch_name_alt := RPAD( NVL( it_bank_branch_name_alt, cv_space ), 15 );      -- DFF4_�d���x�X��
    lv_bank_account_type    := NVL( it_bank_account_type, cv_zero );                      -- DFF5_�a�����(�˗��l)
    lv_bank_account_num     := LPAD( NVL( it_bank_account_num, cv_zero ), 7, cv_zero );   -- DFF6_�����ԍ�(�˗��l)
    lv_dummy                := LPAD( cv_space, 17, cv_space );                            -- �_�~�[
--
    lv_fb_header_data       := it_header_data_type     ||                     -- �f�[�^�敪
                               it_type_code            ||                     -- ��ʃR�[�h
                               it_code_type            ||                     -- �R�[�h�敪
                               lv_sc_client_code       ||                     -- DFF7_�˗��l�R�[�h
                               lv_client_name          ||                     -- DFF8_�˗��l��
                               it_pay_date             ||                     -- �U���w���
                               lv_bank_number          ||                     -- DFF1_�d�����Z�@�֔ԍ�
                               lv_bank_name_alt        ||                     -- DFF2_�d�����Z�@�֖�
                               lv_bank_num             ||                     -- DFF3_�d���x�X�ԍ�
                               lv_bank_branch_name_alt ||                     -- DFF4_�d���x�X��
                               lv_bank_account_type    ||                     -- DFF5_�a�����(�˗��l)
                               lv_bank_account_num     ||                     -- DFF6_�����ԍ�(�˗��l)
                               lv_dummy;                                      -- �_�~�[
    --=======================================================
    -- FB�w�b�_�[���R�[�h�o��
    --=======================================================
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT     -- �o�͋敪
                   ,iv_message  => lv_fb_header_data   -- ���b�Z�[�W
                   ,in_new_line => 0                   -- ���s
                  );
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  END fb_header_record;
--
   /**********************************************************************************
   * Procedure Name   : fb_data_record
   * Description      : FB�f�[�^���R�[�h�̏o��(A-7)
   ***********************************************************************************/
  PROCEDURE fb_data_record(
     ov_errbuf                  OUT VARCHAR2                                           -- �G���[�E���b�Z�[�W
    ,ov_retcode                 OUT VARCHAR2                                           -- ���^�[���E�R�[�h
    ,ov_errmsg                  OUT VARCHAR2                                           -- ���[�U�[�E�G���[�E���b�Z�[�W
    ,it_data_type               IN  xxcok_fb_lines_work.data_type%TYPE                 -- �f�[�^���R�[�h�敪
    ,it_bank_number             IN  xxcok_fb_lines_work.bank_number%TYPE               -- ��d�����Z�@�֔ԍ�
    ,it_bank_name_alt           IN  xxcok_fb_lines_work.bank_name_alt%TYPE             -- ��d�����Z�@�֖�
    ,it_bank_num                IN  xxcok_fb_lines_work.bank_num%TYPE                  -- ��d���x�X�ԍ�
    ,it_bank_branch_name_alt    IN  xxcok_fb_lines_work.bank_branch_name_alt%TYPE      -- ��d���x�X��
    ,it_clearinghouse_no        IN  xxcok_fb_lines_work.clearinghouse_no%TYPE          -- ��`�������ԍ�
    ,it_bank_account_type       IN  xxcok_fb_lines_work.bank_account_type%TYPE         -- �a�����
    ,it_bank_account_num        IN  xxcok_fb_lines_work.bank_account_num%TYPE          -- �����ԍ�
    ,it_account_holder_name_alt IN  xxcok_fb_lines_work.account_holder_name_alt%TYPE   -- ���l��
    ,it_transfer_amount         IN  xxcok_fb_lines_work.transfer_amount%TYPE           -- �U�����z
    ,it_record_type             IN  xxcok_fb_lines_work.record_type%TYPE               -- �V�K���R�[�h
    ,it_base_code               IN  xxcok_fb_lines_work.base_code%TYPE                 -- ���_�R�[�h
    ,it_supplier_code           IN  xxcok_fb_lines_work.supplier_code%TYPE             -- �d����R�[�h
  )
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'fb_data_record';   -- �v���O������
    --=================================
    -- ���[�J���ϐ�
    --=================================
    lv_errbuf                   VARCHAR2(5000) DEFAULT NULL;      -- �G���[�E���b�Z�[�W
    lv_retcode                  VARCHAR2(1)    DEFAULT NULL;      -- ���^�[���E�R�[�h
    lv_errmsg                   VARCHAR2(5000) DEFAULT NULL;      -- ���[�U�[�E�G���[�E���b�Z�[�W
    lb_retcode                  BOOLEAN;                          -- ���b�Z�[�W
    lv_fb_line_data             VARCHAR2(5000) DEFAULT NULL;      -- FB�쐬���׃f�[�^
    lv_transfer_amount          VARCHAR2(10)   DEFAULT NULL;      -- �U�����z
    lv_base_code                VARCHAR2(10)   DEFAULT NULL;      -- ���_�R�[�h
    lv_supplier_code            VARCHAR2(10)   DEFAULT NULL;      -- �d����R�[�h
    lv_dummy                    VARCHAR2(17)   DEFAULT NULL;      -- �_�~�[
--
  BEGIN
    -- �X�e�[�^�X������
    ov_retcode := cv_status_normal;
--
    lv_transfer_amount := TO_CHAR( NVL( it_transfer_amount, cn_zero ), 'FM0000000000');    -- �U�����z
    lv_base_code       := LPAD( NVL( it_base_code, cv_space ), 10 , cv_zero );             -- ���_�R�[�h
    lv_supplier_code   := LPAD( NVL( it_supplier_code, cv_space ), 10 , cv_zero );         -- �d����R�[�h
    lv_dummy           := LPAD( cv_space, 9, cv_space );                                   -- �_�~�[
--
    lv_fb_line_data    := it_data_type               ||         -- �f�[�^�敪
                          it_bank_number             ||         -- ��d�����Z�@�֔ԍ�
                          it_bank_name_alt           ||         -- ��d�����Z�@�֖�
                          it_bank_num                ||         -- ��d���x�X�ԍ�
                          it_bank_branch_name_alt    ||         -- ��d���x�X��
                          it_clearinghouse_no        ||         -- ��`�������ԍ�
                          it_bank_account_type       ||         -- �a�����
                          it_bank_account_num        ||         -- �����ԍ�
                          it_account_holder_name_alt ||         -- ���l��
                          lv_transfer_amount         ||         -- �U�����z
                          it_record_type             ||         -- �V�K���R�[�h
                          lv_base_code               ||         -- ���_�R�[�h
                          lv_supplier_code           ||         -- �d����R�[�h
                          lv_dummy;                             -- �_�~�[
    --=======================================================
    -- FB�f�[�^���R�[�h�o��
    --=======================================================
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT     -- �o�͋敪
                   ,iv_message  => lv_fb_line_data     -- ���b�Z�[�W
                   ,in_new_line => 0                   -- ���s
                  );
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  END fb_data_record;
--
   /**********************************************************************************
   * Procedure Name   : fb_trailer_record
   * Description      : FB�g���[�����R�[�h�̏o��(A-8)
   ***********************************************************************************/
  PROCEDURE fb_trailer_record(
     ov_errbuf                OUT VARCHAR2     -- �G���[�E���b�Z�[�W
    ,ov_retcode               OUT VARCHAR2     -- ���^�[���E�R�[�h
    ,ov_errmsg                OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W
    ,in_total_transfer_cnt    IN  NUMBER       -- ���׃��R�[�h����
    ,in_total_transfer_amount IN  NUMBER       -- �U�����v���z
  )
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'fb_trailer_record';  -- �v���O������
    cv_data_type  CONSTANT VARCHAR2(1)   := '8';                  -- �f�[�^�敪
    --=================================
    -- ���[�J���ϐ�
    --=================================
    lv_errbuf      VARCHAR2(5000) DEFAULT NULL;         -- �G���[�E���b�Z�[�W
    lv_retcode     VARCHAR2(1)    DEFAULT NULL;         -- ���^�[���E�R�[�h
    lv_errmsg      VARCHAR2(5000) DEFAULT NULL;         -- ���[�U�[�E�G���[�E���b�Z�[�W
    lb_retcode     BOOLEAN;                             -- ���b�Z�[�W
    lv_fb_trailer  VARCHAR2(2000) DEFAULT NULL;         -- FB�쐬�g���[�����R�[�h
    lv_data_type   VARCHAR2(1)    DEFAULT NULL;         -- �f�[�^�敪
    lv_total_cnt   VARCHAR2(6)    DEFAULT NULL;         -- ���v����
    lv_total_amt   VARCHAR2(12)   DEFAULT NULL;         -- ���v���z
    lv_dummy       VARCHAR2(101)  DEFAULT NULL;         -- �_�~�[
--
  BEGIN
    -- �X�e�[�^�X������
    ov_retcode := cv_status_normal;
--
    lv_data_type  := cv_data_type;                                              -- �f�[�^�敪
    lv_total_cnt  := LPAD( TO_CHAR( in_total_transfer_cnt ), 6, cv_zero );      -- ���׃��R�[�h����
    lv_total_amt  := LPAD( TO_CHAR( in_total_transfer_amount ), 12, cv_zero );  -- �U�����v���z
    lv_dummy      := LPAD( cv_space, 101, cv_space );                           -- �_�~�[
--
    lv_fb_trailer := lv_data_type ||            -- �f�[�^�敪
                     lv_total_cnt ||            -- ���v����
                     lv_total_amt ||            -- ���v���z
                     lv_dummy;                  -- �_�~�[
    --=======================================================
    -- FB�g���[�����R�[�h�o��
    --=======================================================
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT     -- �o�͋敪
                   ,iv_message  => lv_fb_trailer       -- ���b�Z�[�W
                   ,in_new_line => 0                   -- ���s
                  );
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  END fb_trailer_record;
--
   /**********************************************************************************
   * Procedure Name   : fb_end_record
   * Description      : FB�G���h���R�[�h�̏o��(A-9)
   ***********************************************************************************/
  PROCEDURE fb_end_record(
     ov_errbuf      OUT VARCHAR2     -- �G���[�E���b�Z�[�W
    ,ov_retcode     OUT VARCHAR2     -- ���^�[���E�R�[�h
    ,ov_errmsg      OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    --================================
    -- ���[�J���萔
    --================================
    cv_prg_name  CONSTANT VARCHAR2(100) := 'fb_end_record';    -- �v���O������
    cv_data_type CONSTANT VARCHAR2(1)   := '9';                -- �f�[�^�敪
    cv_at_mark   CONSTANT VARCHAR2(1)   := CHR( 64 );          -- �A�b�g�}�[�N
    --================================
    -- ���[�J���ϐ�
    --================================
    lv_errbuf     VARCHAR2(5000) DEFAULT NULL;        -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1)    DEFAULT NULL;        -- ���^�[���E�R�[�h
    lv_errmsg     VARCHAR2(5000) DEFAULT NULL;        -- ���[�U�[�E�G���[�E���b�Z�[�W
    lb_retcode    BOOLEAN;                            -- ���b�Z�[�W
    lv_fb_end     VARCHAR2(2000) DEFAULT NULL;        -- FB�쐬�G���h���R�[�h
    lv_data_type  VARCHAR2(1)    DEFAULT NULL;        -- �f�[�^�敪
    lv_dummy1     VARCHAR2(117)  DEFAULT NULL;        -- �_�~�[1
    lv_dummy2     VARCHAR2(1)    DEFAULT NULL;        -- �_�~�[2
    lv_dummy3     VARCHAR2(1)    DEFAULT NULL;        -- �_�~�[3
--
  BEGIN
    -- �X�e�[�^�X������
    ov_retcode   := cv_status_normal;
--
    lv_data_type := cv_data_type;                     -- �f�[�^�敪
    lv_dummy1    := LPAD( cv_space, 117, cv_space );  -- �_�~�[1
    lv_dummy2    := cv_at_mark;                       -- �_�~�[2
    lv_dummy3    := cv_space;                         -- �_�~�[3
--
    lv_fb_end := lv_data_type ||                -- �f�[�^�敪
                 lv_dummy1    ||                -- �_�~�[1
                 lv_dummy2    ||                -- �_�~�[2
                 lv_dummy3;                     -- �_�~�[3
    --=======================================================
    -- FB�G���h���R�[�h�o��
    --=======================================================
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT     -- �o�͋敪
                   ,iv_message  => lv_fb_end           -- ���b�Z�[�W
                   ,in_new_line => 0                   -- ���s
                  );
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  END fb_end_record;
--
  /**********************************************************************************
   * Procedure Name   : output_fb_proc
   * Description      : FB�f�[�^�o�͏���(A-5)
   ***********************************************************************************/
  PROCEDURE output_fb_proc(
     ov_errbuf                  OUT VARCHAR2     -- �G���[�E���b�Z�[�W
    ,ov_retcode                 OUT VARCHAR2     -- ���^�[���E�R�[�h
    ,ov_errmsg                  OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_fb_proc';                           -- �v���O������
    --================================
    -- ���[�J���ϐ�
    --================================
    lv_errbuf                   VARCHAR2(5000) DEFAULT NULL;                            -- �G���[�E���b�Z�[�W
    lv_retcode                  VARCHAR2(1)    DEFAULT NULL;                            -- ���^�[���E�R�[�h
    lv_errmsg                   VARCHAR2(5000) DEFAULT NULL;                            -- ���[�U�[�E�G���[�E���b�Z�[�W
    lb_retcode                  BOOLEAN;                                                -- ���^�[���E�R�[�h
    lv_header_rec               VARCHAR2(1)    DEFAULT cv_no;
    lv_bank_code                fnd_lookup_values.lookup_code%TYPE   DEFAULT '0000';
    ln_total_transfer_amount    NUMBER         DEFAULT 0;                               -- FB���אU�����v���z
    ln_total_transfer_cnt       NUMBER         DEFAULT 0;                               -- FB���׃��R�[�h����
    lv_tbl_nm                   VARCHAR2(100)  DEFAULT NULL;                            -- �e�[�u����
--
    --===============================
    -- ���[�J����O
    --===============================
    output_warning_expt         EXCEPTION; -- FB�o�͏����x���G���[
    -- ===============================================
    -- ���[�J���J�[�\��
    -- ===============================================
    -- FB�f�[�^�擾�J�[�\��
    CURSOR fb_data_cur(gn_request_id IN NUMBER)
    IS
    SELECT xflw.internal_bank_number     AS internal_bank_number          -- �d�����Z�@�֔ԍ�
          ,xflw.header_data_type         AS header_data_type              -- �w�b�_�[���R�[�h�敪
          ,xflw.type_code                AS type_code                     -- ��ʃR�[�h
          ,xflw.code_type                AS code_type                     -- �R�[�h�敪
          ,xflw.pay_date                 AS pay_date                      -- �U���w���
          ,xflw.data_type                AS data_type                     -- �f�[�^���R�[�h�敪
          ,xflw.bank_number              AS bank_number                   -- ��d�����Z�@�֔ԍ�
          ,xflw.bank_name_alt            AS bank_name_alt                 -- ��d�����Z�@�֖�
          ,xflw.bank_num                 AS bank_num                      -- ��d���x�X�ԍ�
          ,xflw.bank_branch_name_alt     AS bank_branch_name_alt          -- ��d���x�X��
          ,xflw.clearinghouse_no         AS clearinghouse_no              -- ��`�������ԍ�
          ,xflw.bank_account_type        AS bank_account_type             -- �a�����
          ,xflw.bank_account_num         AS bank_account_num              -- �����ԍ�
          ,xflw.account_holder_name_alt  AS account_holder_name_alt       -- ���l��
          ,xflw.transfer_amount          AS transfer_amount               -- �U�����z
          ,xflw.record_type              AS record_type                   -- �V�K���R�[�h
          ,xflw.base_code                AS base_code                     -- ���_�R�[�h
          ,xflw.supplier_code            AS supplier_code                 -- �d����R�[�h
          ,flv.lookup_code               AS lookup_code                   -- �U�蕪����s
          ,flv.meaning                   AS meaning                       -- �U�蕪����s��
          ,flv.attribute1                AS attribute1                    -- FB���s���d����s
          ,flv.attribute2                AS attribute2                    -- FB���s���d����s���J�i
          ,flv.attribute3                AS attribute3                    -- FB���s���d����s�x�X�ԍ�
          ,flv.attribute4                AS attribute4                    -- FB���s���d����s�x�X���J�i
          ,flv.attribute5                AS attribute5                    -- FB���s���d����s�a�����
          ,flv.attribute6                AS attribute6                    -- FB���s���d����s�����ԍ�
          ,flv.attribute7                AS attribute7                    -- FB���s���d����s�˗��l�R�[�h
          ,flv.attribute8                AS attribute8                    -- FB���s���d����s�˗��l��
    FROM   xxcok_fb_lines_work xflw    -- FB�f�[�^���׃��[�N�e�[�u��
          ,fnd_lookup_values   flv     -- �Q�ƕ\�iFB���s���d����s�j
    WHERE  xflw.request_id  = gn_request_id
    AND    flv.lookup_type  = cv_lookup_type_fb
    AND    flv.lookup_code  = xflw.internal_bank_number
    AND    flv.enabled_flag = cv_yes
    AND    gd_proc_date BETWEEN NVL(flv.start_date_active, gd_proc_date)
                                AND NVL(flv.end_date_active, gd_proc_date)
    AND    flv.language     = USERENV('LANG')
    ORDER BY xflw.internal_bank_number, xflw.base_code, xflw.supplier_code
    ;
--
    CURSOR fb_lookup_cur
    IS
      SELECT 'X'
      FROM   fnd_lookup_values flv
      WHERE  flv.lookup_type  = cv_lookup_type_fb
      FOR UPDATE OF flv.lookup_code NOWAIT;
--
    CURSOR fb_lines_cur
    IS
      SELECT 'X'
      FROM   xxcok_fb_lines_work  xflw
      WHERE  xflw.request_id = gn_request_id
      FOR UPDATE OF xflw.request_id NOWAIT;
--
  BEGIN
    -- �X�e�[�^�X������
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- �Q�ƕ\�iFB���s���d����s�j���b�N�擾
    -- ===============================================
    OPEN  fb_lookup_cur;
    CLOSE fb_lookup_cur;
    lv_tbl_nm := cv_loopup_tbl_nm;
--
    << fb_loop >>
    FOR fb_data_rec IN fb_data_cur(gn_request_id) LOOP
      IF ( fb_data_rec.internal_bank_number <> lv_bank_code ) THEN
        IF ( lv_header_rec = cv_yes ) THEN
          --==================================================
          -- A-8.FB�g���[�����R�[�h�̏o��(A-8)
          --==================================================
          fb_trailer_record(
            ov_errbuf                => lv_errbuf                  -- �G���[�E���b�Z�[�W
          , ov_retcode               => lv_retcode                 -- ���^�[���E�R�[�h
          , ov_errmsg                => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
          , in_total_transfer_cnt    => ln_total_transfer_cnt      -- ���׃��R�[�h����
          , in_total_transfer_amount => ln_total_transfer_amount   -- ���׍��v���z
          );
          IF( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
          --==================================================
          -- A-9.FB�G���h���R�[�h�̏o��(A-9)
          --==================================================
          fb_end_record(
            ov_errbuf      => lv_errbuf            -- �G���[�E���b�Z�[�W
          , ov_retcode     => lv_retcode           -- ���^�[���E�R�[�h
          , ov_errmsg      => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W
          );
          IF( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ���׃��R�[�h�����i�������j�A���׍��v���z�̓o�^
          BEGIN
            UPDATE fnd_lookup_values flv
            SET    flv.attribute11 = TO_CHAR(ln_total_transfer_cnt, '999,999')
                  ,flv.attribute12 = TO_CHAR(ln_total_transfer_amount, '999,999,999,999')
            WHERE  flv.lookup_type  = cv_lookup_type_fb
            AND    flv.lookup_code  = lv_bank_code
            AND    flv.enabled_flag = cv_yes
            AND    gd_proc_date BETWEEN NVL(flv.start_date_active, gd_proc_date)
                                        AND NVL(flv.end_date_active, gd_proc_date)
            AND    flv.language     = USERENV('LANG')
            ;
          EXCEPTION
            -- *** �X�V�����G���[ ***
            WHEN OTHERS THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appli_xxcok                       -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cok_10864                     -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tbl                           -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_tbl_nm                            -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_err_msg                       -- �g�[�N���R�[�h2
                       ,iv_token_value2 => SQLERRM                              -- �g�[�N���l2
                      );
              lv_errbuf := lv_errmsg;
              ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
              ov_retcode := cv_status_error;
          END;
--
          -- �U�����z���v�A���R�[�h�����N���A
          ln_total_transfer_amount := 0;
          ln_total_transfer_cnt    := 0;
        END IF;
        --==================================================
        -- A-6.FB�쐬�w�b�_�[�f�[�^�̏o��
        --==================================================
        fb_header_record(
          ov_errbuf                  => lv_errbuf                     -- �G���[�E���b�Z�[�W
        , ov_retcode                 => lv_retcode                    -- ���^�[���E�R�[�h
        , ov_errmsg                  => lv_errmsg                     -- ���[�U�[�E�G���[�E���b�Z�[�W
        , it_header_data_type        => fb_data_rec.header_data_type  -- �w�b�_�[���R�[�h�敪
        , it_type_code               => fb_data_rec.type_code         -- ��ʃR�[�h
        , it_code_type               => fb_data_rec.code_type         -- �R�[�h�敪
        , it_pay_date                => fb_data_rec.pay_date          -- �U���w���
        , it_bank_number             => fb_data_rec.attribute1        -- FB���s���d����s
        , it_bank_name_alt           => fb_data_rec.attribute2        -- ��s���J�i
        , it_bank_num                => fb_data_rec.attribute3        -- ��s�x�X�ԍ�
        , it_bank_branch_name_alt    => fb_data_rec.attribute4        -- ��s�x�X���J�i
        , it_bank_account_type       => fb_data_rec.attribute5        -- �a�����
        , it_bank_account_num        => fb_data_rec.attribute6        -- ��s�����ԍ�
        , it_eft_requester_id        => fb_data_rec.attribute7        -- �˗��l�R�[�h
        , it_account_holder_name_alt => fb_data_rec.attribute8        -- �˗��l��
        );
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        lv_bank_code  := fb_data_rec.internal_bank_number;
        lv_header_rec := cv_yes;
      END IF;
--
      BEGIN
        --==================================================
        -- A-7.FB�쐬�f�[�^���R�[�h�̏o��(A-6)
        --==================================================
        fb_data_record(
          ov_errbuf                  => lv_errbuf                             -- �G���[�E���b�Z�[�W
        , ov_retcode                 => lv_retcode                            -- ���^�[���E�R�[�h
        , ov_errmsg                  => lv_errmsg                             -- ���[�U�[�E�G���[�E���b�Z�[�W
        , it_data_type               => fb_data_rec.data_type                 -- �f�[�^���R�[�h�敪
        , it_bank_number             => fb_data_rec.bank_number               -- ��d�����Z�@�֔ԍ�
        , it_bank_name_alt           => fb_data_rec.bank_name_alt             -- ��d�����Z�@�֖�
        , it_bank_num                => fb_data_rec.bank_num                  -- ��d���x�X�ԍ�
        , it_bank_branch_name_alt    => fb_data_rec.bank_branch_name_alt      -- ��d���x�X��
        , it_clearinghouse_no        => fb_data_rec.clearinghouse_no          -- ��`�������ԍ�
        , it_bank_account_type       => fb_data_rec.bank_account_type         -- �a�����
        , it_bank_account_num        => fb_data_rec.bank_account_num          -- �����ԍ�
        , it_account_holder_name_alt => fb_data_rec.account_holder_name_alt   -- ���l��
        , it_transfer_amount         => fb_data_rec.transfer_amount           -- �U�����z
        , it_record_type             => fb_data_rec.record_type               -- �V�K���R�[�h
        , it_base_code               => fb_data_rec.base_code                 -- ���_�R�[�h
        , it_supplier_code           => fb_data_rec.supplier_code             -- �d����R�[�h
        );
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        -- �d����s�ʁF�U�����z���v�A���R�[�h����
        ln_total_transfer_amount := ln_total_transfer_amount + fb_data_rec.transfer_amount;
        ln_total_transfer_cnt    := ln_total_transfer_cnt    + 1;
        -- ��������
        gn_target_cnt := gn_target_cnt + 1;
        gn_out_cnt    := gn_out_cnt    + 1;                             -- FB�����U�����z���v
        gn_out_amount := gn_out_amount + fb_data_rec.transfer_amount;   -- FB���R�[�h������
      END;
    END LOOP fb_loop;
    --======================================================
    -- �Q�ƕ\�iFB���s���d����s�j���G���[
    --======================================================
    IF( gn_target_cnt = 0 ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appli_xxcok
                      ,iv_name         => cv_msg_cok_10876
                      ,iv_token_name1  => cv_loopup_type
                      ,iv_token_value1 => cv_lookup_type_fb
                    );
      RAISE output_warning_expt;
    END IF;
    --==================================================
    -- A-8.FB�g���[�����R�[�h�̏o��(A-8)
    --==================================================
    fb_trailer_record(
      ov_errbuf                => lv_errbuf                  -- �G���[�E���b�Z�[�W
    , ov_retcode               => lv_retcode                 -- ���^�[���E�R�[�h
    , ov_errmsg                => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
    , in_total_transfer_cnt    => ln_total_transfer_cnt      -- ���׃��R�[�h����
    , in_total_transfer_amount => ln_total_transfer_amount   -- �U�����v���z
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --==================================================
    -- A-9.FB�G���h���R�[�h�̏o��(A-9)
    --==================================================
    fb_end_record(
      ov_errbuf      => lv_errbuf            -- �G���[�E���b�Z�[�W
    , ov_retcode     => lv_retcode           -- ���^�[���E�R�[�h
    , ov_errmsg      => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    BEGIN
      -- ���׃��R�[�h�����i�������j�A���׍��v���z�̓o�^
      UPDATE fnd_lookup_values flv
      SET    flv.attribute11 = TO_CHAR(ln_total_transfer_cnt, '999,999')
            ,flv.attribute12 = TO_CHAR(ln_total_transfer_amount, '999,999,999,999')
      WHERE  flv.lookup_type  = cv_lookup_type_fb
      AND    flv.lookup_code  = lv_bank_code
      AND    flv.enabled_flag = cv_yes
      AND    gd_proc_date BETWEEN NVL(flv.start_date_active, gd_proc_date)
                                  AND NVL(flv.end_date_active, gd_proc_date)
      AND    flv.language     = USERENV('LANG')
      ;
--
      -- ===============================================
      -- FB�f�[�^���׃��[�N�e�[�u�����b�N�擾
      -- ===============================================
      OPEN  fb_lines_cur;
      CLOSE fb_lines_cur;
      lv_tbl_nm := cv_wk_tbl_nm;
--
      --  FB�f�[�^���׃��[�N�e�[�u��WHO��X�V
      UPDATE xxcok_fb_lines_work  xflw
      SET    created_by              = cn_created_by                      -- �쐬��
            ,creation_date           = cd_creation_date                   -- �쐬��
            ,last_updated_by         = cn_last_updated_by                 -- �ŏI�X�V��
            ,last_update_date        = cd_last_update_date                -- �ŏI�X�V��
            ,last_update_login       = cn_last_update_login               -- �ŏI�X�V���O�C��
            ,request_id              = cn_request_id                      -- �v��ID
            ,program_application_id  = cn_program_application_id          -- �A�v���P�[�V����ID
            ,program_id              = cn_program_id                      -- �v���O����ID
            ,program_update_date     = cd_program_update_date             -- �v���O�����X�V��
      WHERE  xflw.request_id = gn_request_id
      ;
    EXCEPTION
      -- *** �X�V�����G���[ ***
      WHEN OTHERS THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appli_xxcok                       -- �A�v���P�[�V�����Z�k��
                 ,iv_name         => cv_msg_cok_10864                     -- ���b�Z�[�W�R�[�h
                 ,iv_token_name1  => cv_tkn_tbl                           -- �g�[�N���R�[�h1
                 ,iv_token_value1 => lv_tbl_nm                            -- �g�[�N���l1
                 ,iv_token_name2  => cv_tkn_err_msg                       -- �g�[�N���R�[�h2
                 ,iv_token_value2 => SQLERRM                              -- �g�[�N���l2
                );
        lv_errbuf := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_error;
    END;
--
  EXCEPTION
    --*** ���b�N�G���[ ***
    WHEN global_lock_err_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appli_xxcok                       -- �A�v���P�[�V�����Z�k��
                 ,iv_name         => cv_msg_cok_10863                     -- ���b�Z�[�W�R�[�h
                 ,iv_token_name1  => lv_tbl_nm                            -- �g�[�N���R�[�h1
                 ,iv_token_value1 => cv_loopup_tbl_nm                     -- �g�[�N���l1
                 ,iv_token_name2  => cv_tkn_err_msg                       -- �g�[�N���R�[�h2
                 ,iv_token_value2 => SQLERRM                              -- �g�[�N���l2
                );
      lv_errbuf := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** FB�o�͏����x���I�� ***
    WHEN output_warning_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_warn;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  END output_fb_proc;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf          OUT VARCHAR2     -- �G���[�E���b�Z�[�W
  , ov_retcode         OUT VARCHAR2     -- ���^�[���E�R�[�h
  , ov_errmsg          OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W
  , in_request_id      IN  NUMBER       -- �p�����[�^�FFB�f�[�^�t�@�C���쐬���̗v��ID
  , iv_internal_bank1  IN  VARCHAR2     -- �p�����[�^�F���s���d����s1
  , in_bank_cnt1       IN  NUMBER       -- �p�����[�^�F�d����s1�ւ̈�����
  , iv_internal_bank2  IN  VARCHAR2     -- �p�����[�^�F���s���d����s2
  , in_bank_cnt2       IN  NUMBER       -- �p�����[�^�F�d����s2�ւ̈�����
  , iv_internal_bank3  IN  VARCHAR2     -- �p�����[�^�F���s���d����s3
  , in_bank_cnt3       IN  NUMBER       -- �p�����[�^�F�d����s3�ւ̈�����
  , iv_internal_bank4  IN  VARCHAR2     -- �p�����[�^�F���s���d����s4
  , in_bank_cnt4       IN  NUMBER       -- �p�����[�^�F�d����s4�ւ̈�����
  , iv_internal_bank5  IN  VARCHAR2     -- �p�����[�^�F���s���d����s5
  , in_bank_cnt5       IN  NUMBER       -- �p�����[�^�F�d����s5�ւ̈�����
  , iv_internal_bank6  IN  VARCHAR2     -- �p�����[�^�F���s���d����s6
  , in_bank_cnt6       IN  NUMBER       -- �p�����[�^�F�d����s6�ւ̈�����
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'submain';  -- �v���O������
    --
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf                  VARCHAR2(5000) DEFAULT NULL;                        -- �G���[�E���b�Z�[�W
    lv_retcode                 VARCHAR2(1)    DEFAULT NULL;                        -- ���^�[���E�R�[�h
    lv_errmsg                  VARCHAR2(5000) DEFAULT NULL;                        -- ���[�U�[�E�G���[�E���b�Z�[�W
    lb_retcode                 BOOLEAN        DEFAULT NULL;                        -- ���b�Z�[�W�E���^�[���E�R�[�h
    --
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    ov_retcode := cv_status_normal;
    --==================================================
    -- �O���[�o���ϐ��̏�����
    --==================================================
    gn_target_cnt            := 0;        -- �Ώی���
    gn_error_cnt             := 0;        -- �G���[����
    gn_out_cnt               := 0;        -- ��������
    --==================================================
    -- A-1.��������
    --==================================================
    init(
      ov_errbuf         => lv_errbuf              -- �G���[�E���b�Z�[�W
    , ov_retcode        => lv_retcode             -- ���^�[���E�R�[�h
    , ov_errmsg         => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W
    , in_request_id     => in_request_id          -- �����p�����[�^
    , iv_internal_bank1 => iv_internal_bank1      -- �p�����[�^�F���s���d����s1
    , in_bank_cnt1      => in_bank_cnt1           -- �p�����[�^�F�d����s1�ւ̈�����
    , iv_internal_bank2 => iv_internal_bank2      -- �p�����[�^�F���s���d����s2
    , in_bank_cnt2      => in_bank_cnt2           -- �p�����[�^�F�d����s2�ւ̈�����
    , iv_internal_bank3 => iv_internal_bank3      -- �p�����[�^�F���s���d����s3
    , in_bank_cnt3      => in_bank_cnt3           -- �p�����[�^�F�d����s3�ւ̈�����
    , iv_internal_bank4 => iv_internal_bank4      -- �p�����[�^�F���s���d����s4
    , in_bank_cnt4      => in_bank_cnt4           -- �p�����[�^�F�d����s4�ւ̈�����
    , iv_internal_bank5 => iv_internal_bank5      -- �p�����[�^�F���s���d����s5
    , in_bank_cnt5      => in_bank_cnt5           -- �p�����[�^�F�d����s5�ւ̈�����
    , iv_internal_bank6 => iv_internal_bank6      -- �p�����[�^�F���s���d����s6
    , in_bank_cnt6      => in_bank_cnt6           -- �p�����[�^�F�d����s6�ւ̈�����
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
    --==================================================
    -- A-2.���������e�[�u���X�V(A-2)
    --==================================================
    init_update_data(
      ov_errbuf         => lv_errbuf              -- �G���[�E���b�Z�[�W
    , ov_retcode        => lv_retcode             -- ���^�[���E�R�[�h
    , ov_errmsg         => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W
    , iv_internal_bank1 => iv_internal_bank1      -- �p�����[�^�F���s���d����s1
    , in_bank_cnt1      => in_bank_cnt1           -- �p�����[�^�F�d����s1�ւ̈�����
    , iv_internal_bank2 => iv_internal_bank2      -- �p�����[�^�F���s���d����s2
    , in_bank_cnt2      => in_bank_cnt2           -- �p�����[�^�F�d����s2�ւ̈�����
    , iv_internal_bank3 => iv_internal_bank3      -- �p�����[�^�F���s���d����s3
    , in_bank_cnt3      => in_bank_cnt3           -- �p�����[�^�F�d����s3�ւ̈�����
    , iv_internal_bank4 => iv_internal_bank4      -- �p�����[�^�F���s���d����s4
    , in_bank_cnt4      => in_bank_cnt4           -- �p�����[�^�F�d����s4�ւ̈�����
    , iv_internal_bank5 => iv_internal_bank5      -- �p�����[�^�F���s���d����s5
    , in_bank_cnt5      => in_bank_cnt5           -- �p�����[�^�F�d����s5�ւ̈�����
    , iv_internal_bank6 => iv_internal_bank6      -- �p�����[�^�F���s���d����s6
    , in_bank_cnt6      => in_bank_cnt6           -- �p�����[�^�F�d����s6�ւ̈�����
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --==================================================
    -- A-3.FB�f�[�^�����U�蕪������(A-3)
    --==================================================
    auto_distribute_proc(
      ov_errbuf         => lv_errbuf              -- �G���[�E���b�Z�[�W
    , ov_retcode        => lv_retcode             -- ���^�[���E�R�[�h
    , ov_errmsg         => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --==================================================
    -- A-4.FB�f�[�^���U�蕪������(A-4)
    --==================================================
    manual_distribute_proc(
      ov_errbuf         => lv_errbuf              -- �G���[�E���b�Z�[�W
    , ov_retcode        => lv_retcode             -- ���^�[���E�R�[�h
    , ov_errmsg         => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --==================================================
    -- A-5.FB�f�[�^�o�͏���(A-5)
    --==================================================
    output_fb_proc(
      ov_errbuf         => lv_errbuf              -- �G���[�E���b�Z�[�W
    , ov_retcode        => lv_retcode             -- ���^�[���E�R�[�h
    , ov_errmsg         => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      IF( lv_errbuf IS NOT NULL ) THEN
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      END IF;
      ov_retcode := lv_retcode;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
  PROCEDURE main(
    errbuf             OUT VARCHAR2     -- �G���[���b�Z�[�W
  , retcode            OUT VARCHAR2     -- �G���[�R�[�h
  , in_request_id      IN  NUMBER       -- �p�����[�^�FFB�f�[�^�t�@�C���쐬���̗v��ID
  , iv_internal_bank1  IN  VARCHAR2     -- �p�����[�^�F���s���d����s1
  , in_bank_cnt1       IN  NUMBER       -- �p�����[�^�F�d����s1�ւ̈�����
  , iv_internal_bank2  IN  VARCHAR2     -- �p�����[�^�F���s���d����s2
  , in_bank_cnt2       IN  NUMBER       -- �p�����[�^�F�d����s2�ւ̈�����
  , iv_internal_bank3  IN  VARCHAR2     -- �p�����[�^�F���s���d����s3
  , in_bank_cnt3       IN  NUMBER       -- �p�����[�^�F�d����s3�ւ̈�����
  , iv_internal_bank4  IN  VARCHAR2     -- �p�����[�^�F���s���d����s4
  , in_bank_cnt4       IN  NUMBER       -- �p�����[�^�F�d����s4�ւ̈�����
  , iv_internal_bank5  IN  VARCHAR2     -- �p�����[�^�F���s���d����s5
  , in_bank_cnt5       IN  NUMBER       -- �p�����[�^�F�d����s5�ւ̈�����
  , iv_internal_bank6  IN  VARCHAR2     -- �p�����[�^�F���s���d����s6
  , in_bank_cnt6       IN  NUMBER       -- �p�����[�^�F�d����s6�ւ̈�����
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'main';   -- �v���O������
    cv_bank         CONSTANT VARCHAR2(30)  := '�d����s�F';
    cv_count        CONSTANT VARCHAR2(30)  := '�����F';
    cv_c_percentage CONSTANT VARCHAR2(30)  := ' ���A �����F';
    cv_amount       CONSTANT VARCHAR2(30)  := '���v���z : ';
    cv_a_percentage CONSTANT VARCHAR2(30)  := ' �~�A ���� : ';
    cv_percentage   CONSTANT VARCHAR2(30)  := ' %';
    cv_sub_title    CONSTANT VARCHAR2(50)  := 'FB�f�[�^�U�蕪����������';
    cv_sub_line     CONSTANT VARCHAR2(120) := '---------------------------------------------------------------------------------------------------------------';
    cv_none_proc    CONSTANT VARCHAR2(50)  := '���d����s�U�蕪������';
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf           VARCHAR2(5000) DEFAULT NULL;        -- �G���[�E���b�Z�[�W
    lv_retcode          VARCHAR2(1)    DEFAULT NULL;        -- ���^�[���E�R�[�h
    lv_errmsg           VARCHAR2(5000) DEFAULT NULL;        -- ���[�U�[�E�G���[�E���b�Z�[�W
    lb_retcode          BOOLEAN;                            -- ���b�Z�[�W
    ln_line_no          NUMBER         DEFAULT 1;           -- �U�蕪���������ʃ��O�s��
    lv_fb_log           VARCHAR2(2000) DEFAULT NULL;        -- ���O�ҏW
    ln_bank_cnt         NUMBER         DEFAULT 0;           -- FB���׃��R�[�h����
    ln_bank_amount      NUMBER         DEFAULT 0;           -- FB���׍��v���z
    ln_bank_zan_cnt     NUMBER         DEFAULT 0;           -- FB���׃��R�[�h����(�c)
    ln_bank_zan_amount  NUMBER         DEFAULT 0;           -- FB���׍��v���z(�c)
    ln_c_percentage     NUMBER         DEFAULT 0;           -- FB���׃��R�[�h�����ɑ΂��銄��[%]
    ln_a_percentage     NUMBER         DEFAULT 0;           -- FB���׍��v���z�ɑ΂��銄��[%]
    -- ===============================================
    -- ���[�J���J�[�\��
    -- ===============================================
    -- FB�f�[�^�t�@�C���U�蕪���������ʃ��O�o�̓J�[�\��
    CURSOR fb_result_log_cur
    IS
    SELECT flv.lookup_code                   AS  internal_bank       -- �U�蕪����s
          ,flv.meaning                       AS  internal_bank_name  -- �U�蕪����s��
          ,flv.attribute11                   AS  attribute11         -- �U�蕪������
          ,flv.attribute12                   AS  attribute12         -- �U�蕪�����z
          ,COUNT(xflw.internal_bank_number)  AS defaut_bank_count    -- �f�t�H���g��s�ւ̐U�蕪������
          ,SUM(xflw.transfer_amount)         AS defaut_bank_amount   -- �f�t�H���g��s�ւ̐U�蕪�����z���v
    FROM   fnd_lookup_values flv
          ,xxcok_fb_lines_work xflw
    WHERE  flv.lookup_code = xflw.INTERNAL_BANK_NUMBER(+)
    AND    xflw.INTERNAL_BANK_NUMBER(+) = gv_default_bank_code
    AND    xflw.IMPLEMENTED_FLAG(+) IS NOT NULL
    AND    flv.lookup_type  = cv_lookup_type_fb
    AND    flv.attribute11 IS NOT NULL
    AND    flv.enabled_flag = cv_yes
    AND    gd_proc_date BETWEEN NVL(flv.start_date_active, gd_proc_date)
                                AND NVL(flv.end_date_active, gd_proc_date)
    AND    flv.language     = USERENV('LANG')
    GROUP BY xflw.internal_bank_number, flv.meaning, flv.attribute11, flv.attribute12, flv.lookup_code
    ORDER BY flv.lookup_code
    ;
--
  BEGIN
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_log
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       ov_errbuf         => lv_errbuf              -- �G���[�E���b�Z�[�W
     , ov_retcode        => lv_retcode             -- ���^�[���E�R�[�h
     , ov_errmsg         => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W
     , in_request_id     => in_request_id          -- �����p�����[�^
     , iv_internal_bank1 => iv_internal_bank1      -- �p�����[�^�F���s���d����s1
     , in_bank_cnt1      => in_bank_cnt1           -- �p�����[�^�F�d����s1�ւ̈�����
     , iv_internal_bank2 => iv_internal_bank2      -- �p�����[�^�F���s���d����s2
     , in_bank_cnt2      => in_bank_cnt2           -- �p�����[�^�F�d����s2�ւ̈�����
     , iv_internal_bank3 => iv_internal_bank3      -- �p�����[�^�F���s���d����s3
     , in_bank_cnt3      => in_bank_cnt3           -- �p�����[�^�F�d����s3�ւ̈�����
     , iv_internal_bank4 => iv_internal_bank4      -- �p�����[�^�F���s���d����s4
     , in_bank_cnt4      => in_bank_cnt4           -- �p�����[�^�F�d����s4�ւ̈�����
     , iv_internal_bank5 => iv_internal_bank5      -- �p�����[�^�F���s���d����s5
     , in_bank_cnt5      => in_bank_cnt5           -- �p�����[�^�F�d����s5�ւ̈�����
     , iv_internal_bank6 => iv_internal_bank6      -- �p�����[�^�F���s���d����s6
     , in_bank_cnt6      => in_bank_cnt6           -- �p�����[�^�F�d����s6�ւ̈�����
    );
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    IF( lv_retcode <> cv_status_normal ) THEN
      -- ��������
      gn_out_cnt := 0;
      -- �G���[����
      gn_error_cnt := 1;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG       -- �o�͋敪
                     ,iv_message  => lv_errbuf          -- ���b�Z�[�W
                     ,in_new_line => 0                  -- ���s
                    );
    END IF;
    --================================================
    -- A-10.�I������
    --================================================
    -- FB�f�[�^�U�蕪���������ʃ��O�o��
    IF( gn_target_cnt > 0 AND gn_error_cnt <> 1) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                      FND_FILE.LOG
                     ,cv_sub_title
                     ,0
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      FND_FILE.LOG
                     ,cv_sub_line
                     ,0
                    );
      <<fb_result_loop>>
      FOR lt_result_log_rec in fb_result_log_cur LOOP
        IF lt_result_log_rec.internal_bank = gv_default_bank_code
          AND  lt_result_log_rec.attribute11 <> TO_CHAR(lt_result_log_rec.defaut_bank_count, '999,999') THEN  -- FB�f�t�H���g��s
          ln_bank_cnt     := lt_result_log_rec.defaut_bank_count;
          ln_bank_amount  := lt_result_log_rec.defaut_bank_amount;
          ln_bank_zan_cnt     := TO_NUMBER(lt_result_log_rec.attribute11, '999,999') - ln_bank_cnt;
          ln_bank_zan_amount  := TO_NUMBER(lt_result_log_rec.attribute12, '999,999,999,999') - ln_bank_amount;
          lt_result_log_rec.attribute11 := TO_CHAR(ln_bank_cnt,    '999,999');
          lt_result_log_rec.attribute12 := TO_CHAR(ln_bank_amount, '999,999,999,999');
        ELSE
          ln_bank_cnt     := TO_NUMBER(lt_result_log_rec.attribute11, '999,999');
          ln_bank_amount  := TO_NUMBER(lt_result_log_rec.attribute12, '999,999,999,999');
        END IF;
        ln_c_percentage := ln_bank_cnt    / gn_out_cnt    * 100;
        ln_a_percentage := ln_bank_amount / gn_out_amount * 100;
        lv_errmsg := TO_CHAR(ln_line_no) || cv_msg_cont
                    || cv_bank   || lt_result_log_rec.internal_bank || cv_space || lt_result_log_rec.internal_bank_name || CHR(9)
                    || cv_count  || lt_result_log_rec.attribute11 || cv_c_percentage
                    || TO_CHAR(TRUNC(ln_c_percentage, 2)) || cv_percentage || CHR(9)
                    || cv_amount || lt_result_log_rec.attribute12 || cv_a_percentage || TO_CHAR(TRUNC(ln_a_percentage, 2))
                    || cv_percentage;
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.LOG      -- �o�͋敪
                       ,iv_message  => lv_errmsg         -- ���b�Z�[�W
                       ,in_new_line => 0                 -- ���s
                      );
        ln_line_no := ln_line_no + 1;
      END LOOP fb_result_loop;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                      FND_FILE.LOG
                     ,cv_sub_line
                     ,0
                    );
      IF ln_bank_zan_cnt <> 0 THEN
        ln_c_percentage := ln_bank_zan_cnt    / gn_out_cnt    * 100;
        ln_a_percentage := ln_bank_zan_amount / gn_out_amount * 100;
        lv_errmsg := cv_none_proc || CHR(9)
                    || cv_count  || TO_CHAR(ln_bank_zan_cnt, '999,999') || cv_c_percentage
                    || TO_CHAR(TRUNC(ln_c_percentage, 2)) || cv_percentage || CHR(9)
                    || cv_amount || TO_CHAR(ln_bank_zan_amount, '9,999,999,999') || cv_a_percentage || TO_CHAR(TRUNC(ln_a_percentage, 2))
                    || cv_percentage;
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG      -- �o�͋敪
                     ,iv_message  => lv_errmsg         -- ���b�Z�[�W
                     ,in_new_line => 0                 -- ���s
                    );
      END IF;
      lb_retcode := xxcok_common_pkg.put_message_f(
                     FND_FILE.LOG
                    ,NULL
                    ,1
                   );
   END IF;
    -- ��s
    IF( lv_retcode <> cv_status_normal ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                      FND_FILE.LOG
                     ,NULL
                     ,1
                    );
    END IF;
    --�Ώی���
    lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appli_xxccp
                   ,iv_name         => cv_msg_ccp_90000
                   ,iv_token_name1  => cv_token_count
                   ,iv_token_value1 => TO_CHAR( gn_target_cnt, '999,999' )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG      -- �o�͋敪
                   ,iv_message  => lv_errmsg         -- ���b�Z�[�W
                   ,in_new_line => 0                 -- ���s
                  );
    --���������A���v���z
    lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appli_xxcok   -- XXCOK
                   ,iv_name         => cv_msg_cok_10877
                   ,iv_token_name1  => cv_token_count
                   ,iv_token_value1 => TO_CHAR( gn_out_cnt, '999,999' )
                   ,iv_token_name2  => cv_token_amount
                   ,iv_token_value2 => TO_CHAR( gn_out_amount, '999,999,999,999' )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG      -- �o�͋敪
                   ,iv_message  => lv_errmsg         -- ���b�Z�[�W
                   ,in_new_line => 0                 -- ���s
                  );
    --�G���[����
    lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appli_xxccp
                   ,iv_name         => cv_msg_ccp_90002
                   ,iv_token_name1  => cv_token_count
                   ,iv_token_value1 => TO_CHAR( gn_error_cnt, '9,999' )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG      -- �o�͋敪
                   ,iv_message  => lv_errmsg         -- ���b�Z�[�W
                   ,in_new_line => 1                 -- ���s
                  );
    --�I�����b�Z�[�W
    IF( lv_retcode = cv_status_normal ) THEN
      --���b�Z�[�W�o�́i����������I�����܂����B�j
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appli_xxccp
                     ,iv_name         => cv_msg_ccp_90004
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG      -- �o�͋敪
                     ,iv_message  => lv_errmsg         -- ���b�Z�[�W
                     ,in_new_line => 0                 -- ���s
                    );
    ELSE
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
      ROLLBACK;
--
      --�G���[�I���i�S�������O�̏�Ԃɖ߂��܂����B�j
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application => cv_appli_xxccp
                     ,iv_name        => cv_msg_ccp_90006
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG      -- �o�͋敪
                     ,iv_message  => lv_errmsg         -- ���b�Z�[�W
                     ,in_new_line => 0                 -- ���s
                    );
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
END XXCOK016A05C;
/
