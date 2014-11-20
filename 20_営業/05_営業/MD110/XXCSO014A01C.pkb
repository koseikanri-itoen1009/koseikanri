CREATE OR REPLACE PACKAGE BODY APPS.XXCSO014A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO014A01C(body)
 * Description      : ���ʔ���v��f�[�^���ڋq�ʔ���v��e�[�u���֓o�^�܂��͍X�V���܂��B
 *                    
 * MD.050           : MD050_CSO_014_A01_HHT-EBS�C���^�[�t�F�[�X�F(IN�j����v��
 *                    
 * Version          : 1.1
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                        Description
 * ---------------------------- ----------------------------------------------------------
 *  init                        �������� (A-1)
 *  chk_mst_is_exists           �}�X�^���݃`�F�b�N (A-3)
 *  chk_is_new_recode           �ŐV���R�[�h�`�F�b�N (A-4)
 *  chk_sales_plan_day          ���ʌv��A�g�`�F�b�N (A-5) 
 *  upd_sales_plan_month        �ڋq�ʔ���v��f�[�^�̓o�^�܂��͍X�V (A-6)
 *  upd_sales_plan_day          ���ʔ���v��f�[�^�̓o�^�܂��͍X�V (A-7) 
 *  submain                     ���C�������v���V�[�W��
 *                                ����v���񒊏o (A-2)
 *                                �Z�[�u�|�C���g�ݒ� (A-8)
 *  main                        �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                                �I������(A-9)
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-11-11    1.0   Kenji.Sai        �V�K�쐬
 *  2009-02-19    1.1   Kenji.Sai        ���r���[��Ή� 
 *  2009-03-17    1.1   K.Boku           �y������Q067�zupd_sales_plan_day�ŁA��(����)�ɐ擪�O���ߑΉ�
 *  2009-05-01    1.2   Tomoko.Mori      T1_0897�Ή�
 *  2009-12-07    1.3   T.Maruyama       E_�{�ғ�_00028
 *
 *****************************************************************************************/
-- 
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; -- ����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   -- �x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  -- �ُ�:2
--
  --WHO�J����
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         -- CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    -- PROGRAM_UPDATE_DATE
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gn_target_cnt    NUMBER;                    -- �Ώی���
  gn_normal_cnt    NUMBER;                    -- ���팏��
  gn_error_cnt     NUMBER;                    -- �G���[����
  gn_skip_cnt      NUMBER;                    -- �X�L�b�v����
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
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCSO014A01C';      -- �p�b�P�[�W��
  cv_app_name            CONSTANT VARCHAR2(5)   := 'XXCSO';             -- �A�v���P�[�V�����Z�k��
--
  cv_active_status       CONSTANT VARCHAR2(1)   := 'A';                 -- �A�N�e�B�u
  cv_dumm_day_month      CONSTANT VARCHAR2(2)   := '99';                -- ���ʏꍇ�̓��ɂ��i99�j
  cv_monday_kbn_month    CONSTANT VARCHAR2(1)   := '1';                 -- �����敪�i���ʁF1�j
  cv_monday_kbn_day      CONSTANT VARCHAR2(1)   := '2';                 -- �����敪�i���ʁF2�j
  cv_upd_kbn_sales_month CONSTANT VARCHAR2(1)   := '6';  -- HHT�A�g�X�V�@�\�敪�i����v��F6�j  
  cv_upd_kbn_sales_day   CONSTANT VARCHAR2(1)   := '7';  -- HHT�A�g�X�V�@�\�敪�i����v����ʁF7�j    
  cv_houmon_kbn_taget    CONSTANT VARCHAR2(1)   := '1';  -- �K��Ώۋ敪�i�K��ΏہF1�j 
--
  -- ���b�Z�[�W�R�[�h
  cv_tkn_number_01       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00066';  -- �f�[�^���o�G���[
  cv_tkn_number_02       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00067';  -- �ڋq�R�[�h�Ȃ��x��
  cv_tkn_number_03       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00068';  -- ���㋒�_�R�[�h�Ȃ��x��
  cv_tkn_number_04       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00069';  -- �f�[�^�ǉ��G���[
  cv_tkn_number_05       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00070';  -- �f�[�^�X�V�G���[
  cv_tkn_number_06       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00011';  -- �Ɩ��������t�擾�G���[ 
  cv_tkn_number_07       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00149';  -- �N�x�擾�G���[
--
  -- �g�[�N���R�[�h
  cv_tkn_errmsg          CONSTANT VARCHAR2(20) := 'ERR_MESSAGE';
  cv_tkn_tbl             CONSTANT VARCHAR2(20) := 'TABLE';  
  cv_tkn_sequence        CONSTANT VARCHAR2(20) := 'SEQUENCE';
  cv_tkn_cstm_cd         CONSTANT VARCHAR2(20) := 'CUSTOMERCODE';
  cv_tkn_cstm_nm         CONSTANT VARCHAR2(20) := 'CUSTOMERNAME';
  cv_tkn_loc_cd          CONSTANT VARCHAR2(20) := 'LOCATIONCODE';
  cv_tkn_loc_nm          CONSTANT VARCHAR2(20) := 'LOCATIONNAME';
  cv_tkn_ym              CONSTANT VARCHAR2(20) := 'YEARMONTH';
  cv_tkn_mnt             CONSTANT VARCHAR2(20) := 'MOUNT';
--
  cb_true                CONSTANT BOOLEAN := TRUE;
  cb_false               CONSTANT BOOLEAN := FALSE;
--
  -- DEBUG_LOG�p���b�Z�[�W
  cv_debug_msg1           CONSTANT VARCHAR2(200) := '<<�Ɩ��������t�擾����>>';
  cv_debug_msg2           CONSTANT VARCHAR2(200) := 'gd_process_date = ';
  cv_debug_msg3           CONSTANT VARCHAR2(200) := '<<�X�L�b�v�������ꂽ�f�[�^>>';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  gd_process_date        DATE;                                                 -- �Ɩ�������
  gt_business_year       xxcso_account_sales_plans.fiscal_year%TYPE;           -- �N�x
  -- �t�@�C���E�n���h���̐錾
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �擾���i�[���R�[�h�^��`
--
  -- ���ʔ���v�惏�[�N�e�[�u�����֘A��񒊏o�f�[�^
  TYPE g_get_sales_plan_month_rtype IS RECORD(
    no_seq              xxcso_in_sales_plan_month.no_seq%TYPE,                -- �V�[�P���X�ԍ�
    account_number      xxcso_in_sales_plan_month.account_number%TYPE,        -- �ڋq�R�[�h
    sales_base_code     xxcso_in_sales_plan_month.sales_base_code%TYPE,       -- ���㋒�_�R�[�h
    sales_plan_month    xxcso_in_sales_plan_month.sales_plan_month%TYPE,      -- ����v��N��
    sales_plan_amt      xxcso_in_sales_plan_month.sales_plan_amt%TYPE,        -- ����v����z
    party_id            xxcso_cust_accounts_v.party_id%TYPE,                  -- �p�[�e�BID
    vist_target_div     xxcso_cust_accounts_v.vist_target_div%TYPE,           -- �K��Ώۋ敪
    account_name        xxcso_cust_accounts_v.account_name%TYPE,              -- �ڋq����
    sales_base_name     xxcso_aff_base_v2.base_name%TYPE                      -- ���㋒�_����
  );
  -- �e�[�u���^��`
  TYPE sales_plan_day_on_month_ttype IS TABLE OF xxcso_in_sales_plan_month.sales_plan_amt%TYPE INDEX BY PLS_INTEGER;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : �������� (A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf           OUT NOCOPY VARCHAR2,  -- �G���[�E���b�Z�[�W            --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,  -- ���^�[���E�R�[�h              --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'init';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_app_name2           CONSTANT VARCHAR2(10)     := 'XXCCP';             -- �A�h�I���F���ʁEIF�̈�
    cv_no_para_msg         CONSTANT VARCHAR2(100)    := 'APP-XXCCP1-90008';  -- �R���J�����g���̓p�����[�^�Ȃ�
    -- *** ���[�J���ϐ� ***
    lv_noprm_msg    VARCHAR2(5000);  -- �R���J�����g���̓p�����[�^�Ȃ����b�Z�[�W�i�[�p
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
    -- ���̓p�����[�^�Ȃ����b�Z�[�W�o�� 
    -- =======================================
    lv_noprm_msg   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name2,             -- �A�v���P�[�V�����Z�k��
                        iv_name         => cv_no_para_msg            -- ���b�Z�[�W�R�[�h
                      );
    -- ���b�Z�[�W�o��
    fnd_file.put_line(
      which  => FND_FILE.OUTPUT,
      buff   => ''           || CHR(10) ||     -- ��s�̑}��
                lv_noprm_msg || CHR(10) ||
                 ''                            -- ��s�̑}��
    );
--
    -- =====================
    -- �Ɩ��������t�擾���� 
    -- =====================
    gd_process_date := xxccp_common_pkg2.get_process_date;
--
    -- *** DEBUG_LOG ***
    -- �擾�����Ɩ��������t�����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg1 || CHR(10) ||
                 cv_debug_msg2 || TO_CHAR(gd_process_date,'yyyy/mm/dd hh24:mi:ss') || CHR(10) ||
                 ''
    );
--
    -- �Ɩ��������t�擾�Ɏ��s�����ꍇ
    IF (gd_process_date IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_06             -- ���b�Z�[�W�R�[�h
                   );
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
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
   * Procedure Name   : chk_mst_is_exists                                  
   * Description      : �}�X�^���݃`�F�b�N (A-3)
   ***********************************************************************************/
  PROCEDURE chk_mst_is_exists(
    io_sales_plan_month_rec IN OUT NOCOPY g_get_sales_plan_month_rtype,  
-- ���ʔ���v�惏�[�N�e�[�u�����֘A��񒊏o�f�[�^
    ov_errbuf               OUT NOCOPY VARCHAR2,        -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,        -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'chk_mst_is_exists';     -- �v���O������
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
    cv_table_name_xcav   CONSTANT VARCHAR2(100) := 'xxcso_cust_accounts_v';    -- �ڋq�}�X�^�r���[��
    cv_table_name_xabv   CONSTANT VARCHAR2(100) := 'xxcso_aff_base_v';         -- AFF����}�X�^�r���[
    -- *** ���[�J���ϐ� ***
    lt_account_number      xxcso_cust_accounts_v.account_number%TYPE;          -- �ڋq�R�[�h
    lt_party_id            xxcso_cust_accounts_v.party_id%TYPE;                -- �p�[�e�BID
    lt_vist_target_div     xxcso_cust_accounts_v.vist_target_div%TYPE;         -- �K��Ώۋ敪
    lt_account_name        xxcso_cust_accounts_v.account_name%TYPE;            -- �ڋq����
    lt_sales_base_name     xxcso_aff_base_v2.base_name%TYPE;                   -- ���㋒�_����   
--
    -- *** ���[�J���E���R�[�h ***
    l_sales_plan_month_rec  g_get_sales_plan_month_rtype; 
-- IN�p�����[�^.���ʔ���v�惏�[�N�e�[�u���f�[�^�i�[
    --*** ���[�J���E��O ***
    warning_expt       EXCEPTION;
-- 
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
    -- IN�p�����[�^�����R�[�h�ϐ��ɑ��
    l_sales_plan_month_rec := io_sales_plan_month_rec;
--
    -- ===========================
    -- �ڋq�}�X�^���݃`�F�b�N 
    -- ===========================
    BEGIN
--
      -- �ڋq�}�X�^�r���[����ڋq�R�[�h�A�p�[�e�BID�A�K��Ώۋ敪�A�ڋq���̂𒊏o����
      SELECT xcav.account_number account_number,       -- �ڋq�R�[�h
             xcav.party_id party_id,                   -- �p�[�e�BID
             xcav.vist_target_div vist_target_div,     -- �K��Ώۋ敪
             xcav.account_name account_name            -- �ڋq����
      INTO   lt_account_number,                        -- �ڋq�R�[�h
             lt_party_id,                              -- �p�[�e�BID
             lt_vist_target_div,                       -- �K��Ώۋ敪
             lt_account_name                           -- �ڋq����
      FROM   xxcso_cust_accounts_v xcav                -- �ڋq�}�X�^�r���[
      WHERE  xcav.account_number = io_sales_plan_month_rec.account_number  -- �ڋq�R�[�h
        AND  xcav.account_status = cv_active_status                        -- �ڋq�X�e�[�^�X�iA)
        AND  xcav.party_status   = cv_active_status;                       -- �p�[�e�B�X�e�[�^�X�iA)
--
      -- �擾�����ڋq�}�X�^�f�[�^��OUT�p�����[�^�ɐݒ�
      io_sales_plan_month_rec.party_id          := lt_party_id;                -- �p�[�e�BID
      io_sales_plan_month_rec.vist_target_div   := lt_vist_target_div;         -- �K��Ώۋ敪
      io_sales_plan_month_rec.account_name      := lt_account_name;            -- �ڋq����
--
    EXCEPTION
      -- *** �Y���f�[�^�����݂��Ȃ���O�n���h�� ***
      WHEN NO_DATA_FOUND THEN
      -- �G���[���b�Z�[�W�쐬
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                              -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_02                         -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tbl                               -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_table_name_xcav                       -- �G���[�����̃e�[�u����
                       ,iv_token_name2  => cv_tkn_sequence                          -- �g�[�N���R�[�h2
                       ,iv_token_value2 => io_sales_plan_month_rec.no_seq           -- �V�[�P���X�ԍ�
                       ,iv_token_name3  => cv_tkn_cstm_cd                           -- �g�[�N���R�[�h3
                       ,iv_token_value3 => io_sales_plan_month_rec.account_number   -- �ڋq�R�[�h
                       ,iv_token_name4  => cv_tkn_cstm_nm                           -- �g�[�N���R�[�h4
                       ,iv_token_value4 => io_sales_plan_month_rec.account_name     -- �ڋq����
                       ,iv_token_name5  => cv_tkn_loc_cd                            -- �g�[�N���R�[�h5
                       ,iv_token_value5 => io_sales_plan_month_rec.sales_base_code  -- ���㋒�_�R�[�h
                       ,iv_token_name6  => cv_tkn_loc_nm                            -- �g�[�N���R�[�h6
                       ,iv_token_value6 => io_sales_plan_month_rec.sales_base_name  -- ���㋒�_����
                       ,iv_token_name7  => cv_tkn_ym                                -- �g�[�N���R�[�h7
                       ,iv_token_value7 => io_sales_plan_month_rec.sales_plan_month -- ����v��N��
                       ,iv_token_name8  => cv_tkn_mnt                               -- �g�[�N���R�[�h8
                       ,iv_token_value8 => io_sales_plan_month_rec.sales_plan_amt   -- ����v����z
                      );
        lv_errbuf  := lv_errmsg||SQLERRM;
        RAISE warning_expt;
      -- *** OTHERS��O�n���h�� ***
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                              -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_01                         -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tbl                               -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_table_name_xcav                       -- �G���[�����̃e�[�u����
                       ,iv_token_name2  => cv_tkn_sequence                          -- �g�[�N���R�[�h2
                       ,iv_token_value2 => io_sales_plan_month_rec.no_seq           -- �V�[�P���X�ԍ�
                       ,iv_token_name3  => cv_tkn_cstm_cd                           -- �g�[�N���R�[�h3
                       ,iv_token_value3 => io_sales_plan_month_rec.account_number   -- �ڋq�R�[�h
                       ,iv_token_name4  => cv_tkn_cstm_nm                           -- �g�[�N���R�[�h4
                       ,iv_token_value4 => io_sales_plan_month_rec.account_name     -- �ڋq����
                       ,iv_token_name5  => cv_tkn_loc_cd                            -- �g�[�N���R�[�h5
                       ,iv_token_value5 => io_sales_plan_month_rec.sales_base_code  -- ���㋒�_�R�[�h
                       ,iv_token_name6  => cv_tkn_loc_nm                            -- �g�[�N���R�[�h6
                       ,iv_token_value6 => io_sales_plan_month_rec.sales_base_name  -- ���㋒�_����
                       ,iv_token_name7  => cv_tkn_ym                                -- �g�[�N���R�[�h7
                       ,iv_token_value7 => io_sales_plan_month_rec.sales_plan_month -- ����v��N��
                       ,iv_token_name8  => cv_tkn_mnt                               -- �g�[�N���R�[�h8
                       ,iv_token_value8 => io_sales_plan_month_rec.sales_plan_amt   -- ����v����z
                      );
        lv_errbuf  := lv_errmsg||SQLERRM;
        RAISE warning_expt;
    END;
--
    -- ===========================
    -- AFF����}�X�^���݃`�F�b�N
    -- ===========================  
    BEGIN    
      -- AFF����}�X�^�r���[���甄�㋒�_���̂𒊏o����
      SELECT xabv.base_name base_name       -- ���㋒�_����
      INTO   lt_sales_base_name             -- ���㋒�_����
      FROM   xxcso_aff_base_v xabv          -- AFF����}�X�^�r���[
      WHERE  xabv.base_code = io_sales_plan_month_rec.sales_base_code                     -- ���㋒�_�R�[�h
        AND  gd_process_date BETWEEN TRUNC(NVL(xabv.start_date_active, gd_process_date))  -- �L�����Ԕ͈�
               AND TRUNC(NVL(xabv.end_date_active, gd_process_date));                     
--
      -- �擾�������㋒�_���̂�OUT�p�����[�^�ɐݒ�
      io_sales_plan_month_rec.sales_base_name := lt_sales_base_name;           -- ���㋒�_����
--
    EXCEPTION
      -- *** �Y���f�[�^�����݂��Ȃ���O�n���h�� ***
      WHEN NO_DATA_FOUND THEN
        -- �G���[���b�Z�[�W�쐬
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                              -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_03                         -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tbl                               -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_table_name_xabv                       -- �G���[�����̃e�[�u����
                       ,iv_token_name2  => cv_tkn_sequence                          -- �g�[�N���R�[�h2
                       ,iv_token_value2 => io_sales_plan_month_rec.no_seq           -- �V�[�P���X�ԍ�
                       ,iv_token_name3  => cv_tkn_cstm_cd                           -- �g�[�N���R�[�h3
                       ,iv_token_value3 => io_sales_plan_month_rec.account_number   -- �ڋq�R�[�h
                       ,iv_token_name4  => cv_tkn_cstm_nm                           -- �g�[�N���R�[�h4
                       ,iv_token_value4 => io_sales_plan_month_rec.account_name     -- �ڋq����
                       ,iv_token_name5  => cv_tkn_loc_cd                            -- �g�[�N���R�[�h5
                       ,iv_token_value5 => io_sales_plan_month_rec.sales_base_code  -- ���㋒�_�R�[�h
                       ,iv_token_name6  => cv_tkn_loc_nm                            -- �g�[�N���R�[�h6
                       ,iv_token_value6 => io_sales_plan_month_rec.sales_base_name  -- ���㋒�_����
                       ,iv_token_name7  => cv_tkn_ym                                -- �g�[�N���R�[�h7
                       ,iv_token_value7 => io_sales_plan_month_rec.sales_plan_month -- ����v��N��
                       ,iv_token_name8  => cv_tkn_mnt                               -- �g�[�N���R�[�h8
                       ,iv_token_value8 => io_sales_plan_month_rec.sales_plan_amt   -- ����v����z
                      );
        lv_errbuf  := lv_errmsg||SQLERRM;
        RAISE warning_expt;
      -- *** OTHERS��O�n���h�� ***
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                              -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_01                         -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tbl                               -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_table_name_xabv                       -- �G���[�����̃e�[�u����
                       ,iv_token_name2  => cv_tkn_sequence                          -- �g�[�N���R�[�h2
                       ,iv_token_value2 => io_sales_plan_month_rec.no_seq           -- �V�[�P���X�ԍ�
                       ,iv_token_name3  => cv_tkn_cstm_cd                           -- �g�[�N���R�[�h3
                       ,iv_token_value3 => io_sales_plan_month_rec.account_number   -- �ڋq�R�[�h
                       ,iv_token_name4  => cv_tkn_cstm_nm                           -- �g�[�N���R�[�h4
                       ,iv_token_value4 => io_sales_plan_month_rec.account_name     -- �ڋq����
                       ,iv_token_name5  => cv_tkn_loc_cd                            -- �g�[�N���R�[�h5
                       ,iv_token_value5 => io_sales_plan_month_rec.sales_base_code  -- ���㋒�_�R�[�h
                       ,iv_token_name6  => cv_tkn_loc_nm                            -- �g�[�N���R�[�h6
                       ,iv_token_value6 => io_sales_plan_month_rec.sales_base_name  -- ���㋒�_����
                       ,iv_token_name7  => cv_tkn_ym                                -- �g�[�N���R�[�h7
                       ,iv_token_value7 => io_sales_plan_month_rec.sales_plan_month -- ����v��N��
                       ,iv_token_name8  => cv_tkn_mnt                               -- �g�[�N���R�[�h8
                       ,iv_token_value8 => io_sales_plan_month_rec.sales_plan_amt   -- ����v����z
                      );
        lv_errbuf  := lv_errmsg||SQLERRM;
        RAISE warning_expt;
    END;    
--    
  EXCEPTION
--
    -- *** �Y���f�[�^�����݂��Ȃ����f�[�^���o�G���[�������̗�O�n���h�� ***
    WHEN warning_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      -- �X�e�[�^�X�͌x��
      ov_retcode := cv_status_warn;
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_mst_is_exists;
--
  /**********************************************************************************
   * Procedure Name   : chk_is_new_recode                                             
   * Description      : �ŐV���R�[�h�`�F�b�N (A-4)
   ***********************************************************************************/
  PROCEDURE chk_is_new_recode(
    io_sales_plan_month_rec IN OUT NOCOPY g_get_sales_plan_month_rtype, -- ���ʔ���v�惏�[�N�e�[�u���f�[�^
    ob_not_exists_new_data  OUT BOOLEAN,                                -- �ŐV���R�[�h�`�F�b�N�t���O
    ov_errbuf               OUT NOCOPY VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'chk_is_new_recode';     -- �v���O������
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
    -- *** ���[�J���E�萔 ***
    cv_table_name       CONSTANT VARCHAR2(100)  := 'xxcso_in_sales_plan_month';   -- ���ʔ���v�惏�[�N�e�[�u��
    -- *** ���[�J���E�ϐ� ***
    lt_max_no_seq          xxcso_in_sales_plan_month.no_seq%TYPE;  -- �ő�V�[�P���X�ԍ�
    lv_table_name          VARCHAR2(200);                          -- �e�[�u����
    lb_not_exists_new_data BOOLEAN;                                -- �ŐV���R�[�h���݃`�F�b�N�t���O
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J���E��O ***
    select_error_expt EXCEPTION;
--    
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
    --���Y���R�[�h���ŐV���R�[�h�����݂��邩�𔻒f����`�F�b�N�t���O�̏�����
    lb_not_exists_new_data := cb_true;                             -- �ŐV���R�[�h�����݂��Ȃ�
--
    -- ================================================================
    -- ���ʔ���v�惏�[�N�e�[�u������Y���ő�V�[�P���X�ԍ����擾 
    -- ================================================================
    BEGIN
      SELECT  MAX(xispm.no_seq) max_no_seq         -- �ő�V�[�P���X�ԍ�
      INTO    lt_max_no_seq                        -- �ő�V�[�P���X�ԍ�
      FROM    xxcso_in_sales_plan_month  xispm     -- ���ʔ���v�惏�[�N�e�[�u��
      WHERE   xispm.account_number   = io_sales_plan_month_rec.account_number     -- �ڋq�R�[�h
        AND   xispm.sales_base_code  = io_sales_plan_month_rec.sales_base_code    -- ���㋒�_�R�[�h
        AND   xispm.sales_plan_month = io_sales_plan_month_rec.sales_plan_month;  -- ����v��N��
      -- ���Y���R�[�h�̃V�[�P���X�ԍ����ő�V�[�P���X�ԍ����A�傫���ꍇ�A�X�L�b�v����
      -- ���Y���R�[�h�̃V�[�P���X�ԍ����ő�V�[�P���X�ԍ��Ɠ����ꍇ�A����
      IF (lt_max_no_seq > io_sales_plan_month_rec.no_seq) THEN
        lb_not_exists_new_data := cb_false;                        -- �ŐV���R�[�h�����݂���
      END IF;
      -- �擾�����ŐV���R�[�h�`�F�b�N���ʂ�OUT�p�����[�^�ɐݒ�
      ob_not_exists_new_data := lb_not_exists_new_data;
--
    EXCEPTION
      -- *** OTHERS��O�n���h�� ***
      WHEN OTHERS THEN
        -- �G���[���b�Z�[�W�쐬
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name              -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_01         -- ���b�Z�[�W�R�[�h �f�[�^���o�G���[
                       ,iv_token_name1  => cv_tkn_tbl                                -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_table_name                             -- �G���[�����̃e�[�u����
                       ,iv_token_name2  => cv_tkn_errmsg                             -- �g�[�N���R�[�h2
                       ,iv_token_value2 => SQLERRM                                   -- ORACLE�G���[
                       ,iv_token_name3  => cv_tkn_sequence                           -- �g�[�N���R�[�h3
                       ,iv_token_value3 => io_sales_plan_month_rec.no_seq            -- �V�[�P���X�ԍ�
                       ,iv_token_name4  => cv_tkn_cstm_cd                            -- �g�[�N���R�[�h4
                       ,iv_token_value4 => io_sales_plan_month_rec.account_number    -- �ڋq�R�[�h
                       ,iv_token_name5  => cv_tkn_cstm_nm                            -- �g�[�N���R�[�h5
                       ,iv_token_value5 => io_sales_plan_month_rec.account_name      -- �ڋq����
                       ,iv_token_name6  => cv_tkn_loc_cd                             -- �g�[�N���R�[�h6
                       ,iv_token_value6 => io_sales_plan_month_rec.sales_base_code   -- ���㋒�_�R�[�h
                       ,iv_token_name7  => cv_tkn_loc_nm                             -- �g�[�N���R�[�h7
                       ,iv_token_value7 => io_sales_plan_month_rec.sales_base_name   -- ���㋒�_����
                       ,iv_token_name8  => cv_tkn_ym                                 -- �g�[�N���R�[�h8
                       ,iv_token_value8 => io_sales_plan_month_rec.sales_plan_month  -- ����v��N��
                       ,iv_token_name9  => cv_tkn_mnt                                -- �g�[�N���R�[�h9
                       ,iv_token_value9 => io_sales_plan_month_rec.sales_plan_amt    -- ����v����z
                      );
          lv_errbuf  := lv_errmsg||SQLERRM;
          RAISE select_error_expt;
    END;
--
  EXCEPTION
    -- *** �f�[�^���o���̗�O�n���h�� ***
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
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_is_new_recode;
--
  /**********************************************************************************
   * Procedure Name   : chk_sales_plan_day                                                       
   * Description      : ���ʌv��A�g�`�F�b�N (A-5)
   ***********************************************************************************/
  PROCEDURE chk_sales_plan_day(
    io_sales_plan_month_rec IN OUT NOCOPY g_get_sales_plan_month_rtype,  -- ���ʔ���v�惏�[�N�e�[�u���f�[�^
    on_sales_plan_cnt       OUT NUMBER,                 -- ���ʔ���v��A�g�`�F�b�N�p�̃f�[�^����
    ov_errbuf               OUT NOCOPY VARCHAR2,        -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,        -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'chk_sales_plan_day';     -- �v���O������
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
    cv_table_name       CONSTANT VARCHAR2(100) := 'xxcso_in_sales_plan_day';   -- ���ʔ���v�惏�[�N�e�[�u��
    -- *** ���[�J���ϐ� ***
    ln_sales_plan_cnt      NUMBER;                              -- ���ʔ���v��A�g�`�F�b�N�p�̃f�[�^����    
--
    -- *** ���[�J���E���R�[�h ***
--    
    -- *** ���[�J���E��O ***
    select_error_expt EXCEPTION;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ========================================================
    -- ���ʔ���v�惏�[�N�e�[�u������Y���f�[�^�������擾 
    -- ========================================================
    BEGIN
      SELECT  COUNT(xispd.no_seq) sales_plan_cnt    -- ���ʔ���v��Y���f�[�^����
      INTO    ln_sales_plan_cnt                     -- ���ʔ���v��Y���f�[�^����
      FROM    xxcso_in_sales_plan_day  xispd        -- ���ʔ���v�惏�[�N�e�[�u��
      WHERE   xispd.account_number = io_sales_plan_month_rec.account_number           -- �ڋq�R�[�h
        AND   xispd.sales_base_code = io_sales_plan_month_rec.sales_base_code         -- ���㋒�_�R�[�h
        AND   xispd.sales_plan_day LIKE io_sales_plan_month_rec.sales_plan_month||'%' -- ����v��N����
        AND   ROWNUM = 1;                                                             -- �ŏ���1��
      -- �擾�������ʔ���v�惏�[�N�e�[�u���̊Y���f�[�^������OUT�p�����[�^�ɐݒ�
      on_sales_plan_cnt      := ln_sales_plan_cnt;                    
--
    EXCEPTION
      WHEN OTHERS THEN
        -- �G���[���b�Z�[�W�쐬
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name              -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_01         -- ���b�Z�[�W�R�[�h �f�[�^���o�G���[
                       ,iv_token_name1  => cv_tkn_tbl                                -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_table_name                             -- �G���[�����̃e�[�u����
                       ,iv_token_name2  => cv_tkn_errmsg                             -- �g�[�N���R�[�h2
                       ,iv_token_value2 => SQLERRM                                   -- ORACLE�G���[
                       ,iv_token_name3  => cv_tkn_sequence                           -- �g�[�N���R�[�h3
                       ,iv_token_value3 => io_sales_plan_month_rec.no_seq            -- �V�[�P���X�ԍ�
                       ,iv_token_name4  => cv_tkn_cstm_cd                            -- �g�[�N���R�[�h4
                       ,iv_token_value4 => io_sales_plan_month_rec.account_number    -- �ڋq�R�[�h
                       ,iv_token_name5  => cv_tkn_cstm_nm                            -- �g�[�N���R�[�h5
                       ,iv_token_value5 => io_sales_plan_month_rec.account_name      -- �ڋq����
                       ,iv_token_name6  => cv_tkn_loc_cd                             -- �g�[�N���R�[�h6
                       ,iv_token_value6 => io_sales_plan_month_rec.sales_base_code   -- ���㋒�_�R�[�h
                       ,iv_token_name7  => cv_tkn_loc_nm                             -- �g�[�N���R�[�h7
                       ,iv_token_value7 => io_sales_plan_month_rec.sales_base_name   -- ���㋒�_����
                       ,iv_token_name8  => cv_tkn_ym                                 -- �g�[�N���R�[�h8
                       ,iv_token_value8 => io_sales_plan_month_rec.sales_plan_month  -- ����v��N��
                       ,iv_token_name9  => cv_tkn_mnt                                -- �g�[�N���R�[�h9
                       ,iv_token_value9 => io_sales_plan_month_rec.sales_plan_amt    -- ����v����z
                      );
        lv_errbuf  := lv_errmsg||SQLERRM;
        RAISE select_error_expt;
    END;
--
  EXCEPTION
    -- *** �f�[�^���o���̗�O�n���h�� ***
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
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_sales_plan_day;
--
  /**********************************************************************************
   * Procedure Name   : upd_sales_plan_month                                                               
   * Description      : �ڋq�ʔ���v��f�[�^�̓o�^�܂��͍X�V (A-6)
   ***********************************************************************************/
  PROCEDURE upd_sales_plan_month(
    io_sales_plan_month_rec  IN OUT NOCOPY g_get_sales_plan_month_rtype,   -- ���ʔ���v�惏�[�N�e�[�u���f�[�^
    ov_errbuf                OUT NOCOPY VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT NOCOPY VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT NOCOPY VARCHAR2          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'upd_sales_plan_month';     -- �v���O������
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
    -- �ڋq�ʔ���v��e�[�u���������[�J���ϐ��ɑ��
    cv_table_name          CONSTANT VARCHAR2(100) := 'xxcso_account_sales_plans';  -- �ڋq�ʔ���v��e�[�u��
    -- *** ���[�J���ϐ� ***
    ln_data_cnt            NUMBER;              -- �ڋq�ʔ���v��e�[�u���̌��ʔ���v��f�[�^����    
    lv_msg_code            VARCHAR2(100);                                          -- ���b�Z�[�W�R�[�h
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J���E��O ***
    select_error_expt EXCEPTION;
    ins_upd_expt      EXCEPTION;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ======================================================
    -- �ڋq�ʔ���v��e�[�u������Y���f�[�^�������擾
    -- ======================================================
    BEGIN
      SELECT COUNT(xasp.account_sales_plan_id) data_cnt   -- �ڋq����v��̊Y���f�[�^����
      INTO   ln_data_cnt                                  -- �ڋq����v��̊Y���f�[�^����
      FROM   xxcso_account_sales_plans xasp               -- �ڋq�ʔ���v��e�[�u��
      WHERE  xasp.account_number = io_sales_plan_month_rec.account_number    -- �ڋq�R�[�h
        AND  xasp.base_code      = io_sales_plan_month_rec.sales_base_code   -- ���㋒�_�R�[�h
        AND  xasp.year_month     = io_sales_plan_month_rec.sales_plan_month  -- �N��
        AND  xasp.plan_day       = cv_dumm_day_month                         -- ��(99)
        AND  xasp.month_date_div = cv_monday_kbn_month;                      -- �����敪(1)
--
    EXCEPTION
      -- *** OTHERS��O�n���h�� ***
      WHEN OTHERS THEN
        -- �G���[���b�Z�[�W�쐬
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name              -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_01         -- ���b�Z�[�W�R�[�h �f�[�^���o�G���[
                       ,iv_token_name1  => cv_tkn_tbl                                -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_table_name                             -- �G���[�����̃e�[�u����
                       ,iv_token_name2  => cv_tkn_errmsg                             -- �g�[�N���R�[�h2
                       ,iv_token_value2 => SQLERRM                                   -- ORACLE�G���[
                       ,iv_token_name3  => cv_tkn_sequence                           -- �g�[�N���R�[�h3
                       ,iv_token_value3 => io_sales_plan_month_rec.no_seq            -- �V�[�P���X�ԍ�
                       ,iv_token_name4  => cv_tkn_cstm_cd                            -- �g�[�N���R�[�h4
                       ,iv_token_value4 => io_sales_plan_month_rec.account_number    -- �ڋq�R�[�h
                       ,iv_token_name5  => cv_tkn_cstm_nm                            -- �g�[�N���R�[�h5
                       ,iv_token_value5 => io_sales_plan_month_rec.account_name      -- �ڋq����
                       ,iv_token_name6  => cv_tkn_loc_cd                             -- �g�[�N���R�[�h6
                       ,iv_token_value6 => io_sales_plan_month_rec.sales_base_code   -- ���㋒�_�R�[�h
                       ,iv_token_name7  => cv_tkn_loc_nm                             -- �g�[�N���R�[�h7
                       ,iv_token_value7 => io_sales_plan_month_rec.sales_base_name   -- ���㋒�_����
                       ,iv_token_name8  => cv_tkn_ym                                 -- �g�[�N���R�[�h8
                       ,iv_token_value8 => io_sales_plan_month_rec.sales_plan_month  -- ����v��N��
                       ,iv_token_name9  => cv_tkn_mnt                                -- �g�[�N���R�[�h9
                       ,iv_token_value9 => io_sales_plan_month_rec.sales_plan_amt    -- ����v����z
                      );
        lv_errbuf  := lv_errmsg||SQLERRM;
        RAISE select_error_expt;
    END;
--    
    -- �Y���f�[�^�������P���ȏ�̏ꍇ�A�ڋq�ʔ���v��e�[�u���̃f�[�^�X�V���s��
    -- �Y���f�[�^�������O���̏ꍇ�A�ڋq�ʔ���v��e�[�u���̃f�[�^�o�^���s��
    BEGIN
      IF (ln_data_cnt >= 1) THEN
        -- ========================================================
        -- �ڋq�ʔ���v��e�[�u���̊Y�����ʔ���v��f�[�^�X�V 
        -- ========================================================
        lv_msg_code := cv_tkn_number_05;  -- �f�[�^�X�V�G���[�R�[�h�Z�b�g
        UPDATE xxcso_account_sales_plans       -- �ڋq�ʔ���v��e�[�u��
        SET    last_updated_by        = cn_last_updated_by,                     -- �ŏI�X�V��
               last_update_date       = cd_last_update_date,                    -- �ŏI�X�V��
               last_update_login      = cn_last_update_login,                   -- �ŏI�X�V���O�C��
               request_id             = cn_request_id,                          -- �v��ID
               program_application_id = cn_program_application_id,              -- �ݶ��ĥ��۸��т̱��ع����ID
               program_id             = cn_program_id,                          -- �ݶ��ĥ��۸���ID
               program_update_date    = cd_program_update_date,                 -- ��۸��тɂ��X�V��
               sales_plan_month_amt   = io_sales_plan_month_rec.sales_plan_amt, -- ���ʔ���v��
               update_func_div        = cv_upd_kbn_sales_month                  -- �X�V�@�\�敪(6)
        WHERE  account_number = io_sales_plan_month_rec.account_number          -- �ڋq�R�[�h
          AND  base_code      = io_sales_plan_month_rec.sales_base_code         -- ���㋒�_�R�[�h
          AND  year_month     = io_sales_plan_month_rec.sales_plan_month        -- ����v��N��
          AND  plan_day       = cv_dumm_day_month                               -- ��(99)
          AND  month_date_div = cv_monday_kbn_month;                            -- �����敪(1)
      ELSE
        -- ========================================================
        -- �ڋq�ʔ���v��e�[�u���̊Y�����ʔ���v��f�[�^�o�^ 
        -- ========================================================
        lv_msg_code := cv_tkn_number_04;  -- �f�[�^�ǉ��G���[�R�[�h�Z�b�g
        INSERT INTO xxcso_account_sales_plans(
          account_sales_plan_id,                                   -- �ڋq�ʔ���v��h�c
          base_code,                                               -- ���㋒�_�R�[�h
          account_number,                                          -- �ڋq�R�[�h
          year_month,                                              -- ����v��N��
          plan_day,                                                -- ��:99
          fiscal_year,                                             -- �N�x
          month_date_div,                                          -- �����敪:���ʌv��F1
          sales_plan_month_amt,                                    -- ���ʔ���v��
          sales_plan_day_amt,                                      -- ���ʔ���v��
          plan_date,                                               -- �N����
          party_id,                                                -- �p�[�e�BID
          update_func_div,                                         -- �X�V�@�\�敪
          created_by,                                              -- �쐬��
          creation_date,                                           -- �쐬��
          last_updated_by,                                         -- �ŏI�X�V��
          last_update_date,                                        -- �ŏI�X�V��
          last_update_login,                                       -- �ŏI�X�V���O�C��
          request_id,                                              -- �v��ID
          program_application_id,                                  -- �ݶ��ĥ��۸��т̱��ع����ID
          program_id,                                              -- �ݶ��ĥ��۸���ID
          program_update_date                                      -- ��۸��тɂ��X�V��
        )VALUES(
          xxcso_account_sales_plans_s01.NEXTVAL,                   -- �ڋq�ʔ���v��h�c
          io_sales_plan_month_rec.sales_base_code,                 -- ���㋒�_�R�[�h
          io_sales_plan_month_rec.account_number,                  -- �ڋq�R�[�h
          io_sales_plan_month_rec.sales_plan_month,                -- ����v��N��
          cv_dumm_day_month,                                       -- ��:99
          gt_business_year,                                        -- �N�x
          cv_monday_kbn_month,                                     -- �����敪:���ʌv��F1
          io_sales_plan_month_rec.sales_plan_amt,                  -- ���ʔ���v��
          NULL,                                                    -- ���ʔ���v��
          io_sales_plan_month_rec.sales_plan_month||'99',          -- �N����
          io_sales_plan_month_rec.party_id,                        -- �p�[�e�BID
          cv_upd_kbn_sales_month,                                  -- �X�V�@�\�敪
          cn_created_by,                                           -- �쐬��
          SYSDATE,                                                 -- �쐬��
          cn_last_updated_by,                                      -- �ŏI�X�V��
          SYSDATE,                                                 -- �ŏI�X�V��
          cn_last_update_login,                                    -- �ŏI�X�V���O�C��
          cn_request_id,                                           -- �v��ID
          cn_program_application_id,                               -- �ݶ��ĥ��۸��т̱��ع����ID
          cn_program_id,                                           -- �ݶ��ĥ��۸���ID
          SYSDATE                                                  -- ��۸��тɂ��X�V��
        );
      END IF;
    EXCEPTION
      -- *** OTHERS��O�n���h�� ***
      WHEN OTHERS THEN
        -- �G���[���b�Z�[�W�쐬
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                               -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => lv_msg_code                               -- ���b�Z�[�W�R�[�h 
                       ,iv_token_name1  => cv_tkn_tbl                                -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_table_name                             -- �G���[�����̃e�[�u����
                       ,iv_token_name2  => cv_tkn_errmsg                             -- �g�[�N���R�[�h2
                       ,iv_token_value2 => SQLERRM                                   -- ORACLE�G���[
                       ,iv_token_name3  => cv_tkn_sequence                           -- �g�[�N���R�[�h3
                       ,iv_token_value3 => io_sales_plan_month_rec.no_seq            -- �V�[�P���X�ԍ�
                       ,iv_token_name4  => cv_tkn_cstm_cd                            -- �g�[�N���R�[�h4
                       ,iv_token_value4 => io_sales_plan_month_rec.account_number    -- �ڋq�R�[�h
                       ,iv_token_name5  => cv_tkn_cstm_nm                            -- �g�[�N���R�[�h5
                       ,iv_token_value5 => io_sales_plan_month_rec.account_name      -- �ڋq����
                       ,iv_token_name6  => cv_tkn_loc_cd                             -- �g�[�N���R�[�h6
                       ,iv_token_value6 => io_sales_plan_month_rec.sales_base_code   -- ���㋒�_�R�[�h
                       ,iv_token_name7  => cv_tkn_loc_nm                             -- �g�[�N���R�[�h7
                       ,iv_token_value7 => io_sales_plan_month_rec.sales_base_name   -- ���㋒�_����
                       ,iv_token_name8  => cv_tkn_ym                                 -- �g�[�N���R�[�h8
                       ,iv_token_value8 => io_sales_plan_month_rec.sales_plan_month  -- ����v��N��
                       ,iv_token_name9  => cv_tkn_mnt                                -- �g�[�N���R�[�h9
                       ,iv_token_value9 => io_sales_plan_month_rec.sales_plan_amt    -- ����v����z
                      );
        lv_errbuf  := lv_errmsg||SQLERRM;  
        RAISE ins_upd_expt;
    END;
--
  EXCEPTION
    -- *** �f�[�^���o���̗�O�n���h�� ***
    WHEN select_error_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** �f�[�^�o�^�X�V��O�n���h�� ***
    WHEN ins_upd_expt THEN  
      ov_errmsg  := lv_errmsg;      
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END upd_sales_plan_month;
--
  /**********************************************************************************
   * Procedure Name   : upd_sales_plan_day                                                                         
   * Description      : ���ʔ���v��f�[�^�̓o�^�܂��͍X�V (A-7)
   ***********************************************************************************/
  PROCEDURE upd_sales_plan_day(
    io_sales_plan_month_rec IN OUT NOCOPY g_get_sales_plan_month_rtype, -- ���ʔ���v�惏�[�N�e�[�u���f�[�^
    ov_errbuf               OUT NOCOPY VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'upd_sales_plan_day';     -- �v���O������
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
    cv_table_name       CONSTANT VARCHAR2(100) := 'xxcso_account_sales_plans';   -- �ڋq�ʔ���v��e�[�u��
    -- *** ���[�J���ϐ� ***
    ln_data_cnt            NUMBER;              -- �ڋq�ʔ���v��e�[�u���̌��ʔ���v��f�[�^����    
    lt_route_no            xxcso_in_route_no.route_no%TYPE;                      -- ���[�gNo
    lv_msg_code            VARCHAR2(200);                                        -- ���b�Z�[�W�R�[�h
--
    l_sales_plan_day_on_month_tbl sales_plan_day_on_month_ttype;  --���ۂ̌��̓��ɂ����̓��ʔ���v��f�[�^ 
    ln_day_on_month        NUMBER;              -- ���Y���̓���
    ln_visit_daytimes      NUMBER;              -- ���Y���̖K�����
    ln_loop_cnt            NUMBER;              -- ���[�v�p�ϐ�
    lv_table_name          VARCHAR2(200);       -- �e�[�u����
    -- *** ���[�J���E��O ***
    select_error_expt      EXCEPTION;
    ins_upd_expt           EXCEPTION;
    normal_expt            EXCEPTION;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���[�gNo�ϐ�������
    lt_route_no := NULL;
    -- =========================================================
    -- ���[�gNo�r���[�ɂ��A���Y�ڋq�̃��[�gNo���擾 
    -- =========================================================
    BEGIN
      SELECT xcrv.route_number route_number        -- ���[�gNo
      INTO   lt_route_no                           -- ���[�gNo
      FROM   xxcso_cust_routes_v xcrv              -- �ڋq���[�gNo�r���[
      WHERE  xcrv.account_number = io_sales_plan_month_rec.account_number  -- �ڋq�R�[�h
        AND  gd_process_date BETWEEN TRUNC(xcrv.start_date_active)         -- �L������
               AND TRUNC(NVL(xcrv.end_date_active, gd_process_date));   
--
    EXCEPTION
      -- *** �Y���f�[�^�����݂��Ȃ����������݂���ꍇ��O�n���h�� ***
      WHEN NO_DATA_FOUND OR TOO_MANY_ROWS THEN
        RAISE normal_expt;
      -- *** OTHERS��O�n���h�� ***
      WHEN OTHERS THEN
        -- �G���[���b�Z�[�W�쐬
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name              -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_01         -- ���b�Z�[�W�R�[�h �f�[�^���o�G���[
                       ,iv_token_name1  => cv_tkn_tbl                                -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_table_name                             -- �G���[�����̃e�[�u����
                       ,iv_token_name2  => cv_tkn_errmsg                             -- �g�[�N���R�[�h2
                       ,iv_token_value2 => SQLERRM                                   -- ORACLE�G���[
                       ,iv_token_name3  => cv_tkn_sequence                           -- �g�[�N���R�[�h3
                       ,iv_token_value3 => io_sales_plan_month_rec.no_seq            -- �V�[�P���X�ԍ�
                       ,iv_token_name4  => cv_tkn_cstm_cd                            -- �g�[�N���R�[�h4
                       ,iv_token_value4 => io_sales_plan_month_rec.account_number    -- �ڋq�R�[�h
                       ,iv_token_name5  => cv_tkn_cstm_nm                            -- �g�[�N���R�[�h5
                       ,iv_token_value5 => io_sales_plan_month_rec.account_name      -- �ڋq����
                       ,iv_token_name6  => cv_tkn_loc_cd                             -- �g�[�N���R�[�h6
                       ,iv_token_value6 => io_sales_plan_month_rec.sales_base_code   -- ���㋒�_�R�[�h
                       ,iv_token_name7  => cv_tkn_loc_nm                             -- �g�[�N���R�[�h7
                       ,iv_token_value7 => io_sales_plan_month_rec.sales_base_name   -- ���㋒�_����
                       ,iv_token_name8  => cv_tkn_ym                                 -- �g�[�N���R�[�h8
                       ,iv_token_value8 => io_sales_plan_month_rec.sales_plan_month  -- ����v��N��
                       ,iv_token_name9  => cv_tkn_mnt                                -- �g�[�N���R�[�h9
                       ,iv_token_value9 => io_sales_plan_month_rec.sales_plan_amt    -- ����v����z
                      );
        lv_errbuf  := lv_errmsg||SQLERRM;
        RAISE select_error_expt;
    END;  
--
    --���[�gNo�����݂���ꍇ�A���ʔ���v��f�[�^�o�^�܂��͍X�V���s��
    --���[�gNo�����݂��Ȃ��ꍇ�A�p���������s��
    IF (lt_route_no IS NOT NULL) THEN
      --����v����ʔz���������ʊ֐��ɂ��A���ۂ̌��̓��ɂ����̔z���f�[�^���擾����
      xxcso_route_common_pkg.distribute_sales_plan(
        iv_year_month                 => io_sales_plan_month_rec.sales_plan_month,
        it_sales_plan_amt             => io_sales_plan_month_rec.sales_plan_amt,
        it_route_number               => lt_route_no,
        on_day_on_month               => ln_day_on_month,                     -- ���Y���̓������擾
        on_visit_daytimes             => ln_visit_daytimes,                   -- ���Y���̖K�����
        ot_sales_plan_day_amt_1       => l_sales_plan_day_on_month_tbl(1),    -- 1���ړ��ʔ���v����z
        ot_sales_plan_day_amt_2       => l_sales_plan_day_on_month_tbl(2),    -- 2���ړ��ʔ���v����z
        ot_sales_plan_day_amt_3       => l_sales_plan_day_on_month_tbl(3),    -- 3���ړ��ʔ���v����z
        ot_sales_plan_day_amt_4       => l_sales_plan_day_on_month_tbl(4),    -- 4���ړ��ʔ���v����z
        ot_sales_plan_day_amt_5       => l_sales_plan_day_on_month_tbl(5),    -- 5���ړ��ʔ���v����z
        ot_sales_plan_day_amt_6       => l_sales_plan_day_on_month_tbl(6),    -- 6���ړ��ʔ���v����z
        ot_sales_plan_day_amt_7       => l_sales_plan_day_on_month_tbl(7),    -- 7���ړ��ʔ���v����z
        ot_sales_plan_day_amt_8       => l_sales_plan_day_on_month_tbl(8),    -- 8���ړ��ʔ���v����z
        ot_sales_plan_day_amt_9       => l_sales_plan_day_on_month_tbl(9),    -- 9���ړ��ʔ���v����z
        ot_sales_plan_day_amt_10      => l_sales_plan_day_on_month_tbl(10),   -- 10���ړ��ʔ���v����z
        ot_sales_plan_day_amt_11      => l_sales_plan_day_on_month_tbl(11),   -- 11���ړ��ʔ���v����z
        ot_sales_plan_day_amt_12      => l_sales_plan_day_on_month_tbl(12),   -- 12���ړ��ʔ���v����z
        ot_sales_plan_day_amt_13      => l_sales_plan_day_on_month_tbl(13),   -- 13���ړ��ʔ���v����z
        ot_sales_plan_day_amt_14      => l_sales_plan_day_on_month_tbl(14),   -- 14���ړ��ʔ���v����z
        ot_sales_plan_day_amt_15      => l_sales_plan_day_on_month_tbl(15),   -- 15���ړ��ʔ���v����z
        ot_sales_plan_day_amt_16      => l_sales_plan_day_on_month_tbl(16),   -- 16���ړ��ʔ���v����z
        ot_sales_plan_day_amt_17      => l_sales_plan_day_on_month_tbl(17),   -- 17���ړ��ʔ���v����z
        ot_sales_plan_day_amt_18      => l_sales_plan_day_on_month_tbl(18),   -- 18���ړ��ʔ���v����z
        ot_sales_plan_day_amt_19      => l_sales_plan_day_on_month_tbl(19),   -- 19���ړ��ʔ���v����z
        ot_sales_plan_day_amt_20      => l_sales_plan_day_on_month_tbl(20),   -- 20���ړ��ʔ���v����z
        ot_sales_plan_day_amt_21      => l_sales_plan_day_on_month_tbl(21),   -- 21���ړ��ʔ���v����z
        ot_sales_plan_day_amt_22      => l_sales_plan_day_on_month_tbl(22),   -- 22���ړ��ʔ���v����z
        ot_sales_plan_day_amt_23      => l_sales_plan_day_on_month_tbl(23),   -- 23���ړ��ʔ���v����z
        ot_sales_plan_day_amt_24      => l_sales_plan_day_on_month_tbl(24),   -- 24���ړ��ʔ���v����z
        ot_sales_plan_day_amt_25      => l_sales_plan_day_on_month_tbl(25),   -- 25���ړ��ʔ���v����z
        ot_sales_plan_day_amt_26      => l_sales_plan_day_on_month_tbl(26),   -- 26���ړ��ʔ���v����z
        ot_sales_plan_day_amt_27      => l_sales_plan_day_on_month_tbl(27),   -- 27���ړ��ʔ���v����z
        ot_sales_plan_day_amt_28      => l_sales_plan_day_on_month_tbl(28),   -- 28���ړ��ʔ���v����z
        ot_sales_plan_day_amt_29      => l_sales_plan_day_on_month_tbl(29),   -- 29���ړ��ʔ���v����z
        ot_sales_plan_day_amt_30      => l_sales_plan_day_on_month_tbl(30),   -- 30���ړ��ʔ���v����z
        ot_sales_plan_day_amt_31      => l_sales_plan_day_on_month_tbl(31),   -- 31���ړ��ʔ���v����z
        ov_errbuf                     => lv_errbuf,
        ov_retcode                    => lv_retcode,
        ov_errmsg                     => lv_errmsg);
--
      /* 2009/12/07 T.Maruyama E_�{�ғ�_00028�Ή� START */
      --���ʈ����ł��Ȃ������[�gNo���s���ȏꍇ�́A���ʈ������{�����I��
      IF (lv_retcode = cv_status_error) THEN
        raise normal_expt;
      END IF;
      /* 2009/12/07 T.Maruyama E_�{�ғ�_00028�Ή� END */
--
      -- ==============================================================
      -- �ڋq�ʔ���v��e�[�u������Y�����ʔ���f�[�^�������擾 
      -- ==============================================================
      BEGIN
        SELECT COUNT(xasp.account_sales_plan_id) datacnt   -- �Y�����ʔ���f�[�^����
        INTO   ln_data_cnt                                 -- �Y�����ʔ���f�[�^����
        FROM   xxcso_account_sales_plans xasp              -- �ڋq�ʔ���v��e�[�u��
        WHERE  xasp.account_number = io_sales_plan_month_rec.account_number      -- �ڋq�R�[�h
          AND  xasp.base_code      = io_sales_plan_month_rec.sales_base_code     -- ���㋒�_�R�[�h
          AND  xasp.year_month     = io_sales_plan_month_rec.sales_plan_month    -- ����v��N��
          AND  xasp.plan_date LIKE io_sales_plan_month_rec.sales_plan_month||'%' -- ����v��N����
          AND  xasp.month_date_div = cv_monday_kbn_day;                          -- �����敪(2)
--
      EXCEPTION
        -- *** OTHERS��O�n���h�� ***
        WHEN OTHERS THEN
          -- �G���[���b�Z�[�W�쐬
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name              -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_01         -- ���b�Z�[�W�R�[�h �f�[�^���o�G���[
                         ,iv_token_name1  => cv_tkn_tbl                                -- �g�[�N���R�[�h1
                         ,iv_token_value1 => cv_table_name                             -- �G���[�����̃e�[�u����
                         ,iv_token_name2  => cv_tkn_errmsg                             -- �g�[�N���R�[�h2
                         ,iv_token_value2 => SQLERRM                                   -- ORACLE�G���[
                         ,iv_token_name3  => cv_tkn_sequence                           -- �g�[�N���R�[�h3
                         ,iv_token_value3 => io_sales_plan_month_rec.no_seq            -- �V�[�P���X�ԍ�
                         ,iv_token_name4  => cv_tkn_cstm_cd                            -- �g�[�N���R�[�h4
                         ,iv_token_value4 => io_sales_plan_month_rec.account_number    -- �ڋq�R�[�h
                         ,iv_token_name5  => cv_tkn_cstm_nm                            -- �g�[�N���R�[�h5
                         ,iv_token_value5 => io_sales_plan_month_rec.account_name      -- �ڋq����
                         ,iv_token_name6  => cv_tkn_loc_cd                             -- �g�[�N���R�[�h6
                         ,iv_token_value6 => io_sales_plan_month_rec.sales_base_code   -- ���㋒�_�R�[�h
                         ,iv_token_name7  => cv_tkn_loc_nm                             -- �g�[�N���R�[�h7
                         ,iv_token_value7 => io_sales_plan_month_rec.sales_base_name   -- ���㋒�_����
                         ,iv_token_name8  => cv_tkn_ym                                 -- �g�[�N���R�[�h8
                         ,iv_token_value8 => io_sales_plan_month_rec.sales_plan_month  -- ����v��N��
                         ,iv_token_name9  => cv_tkn_mnt                                -- �g�[�N���R�[�h9
                         ,iv_token_value9 => io_sales_plan_month_rec.sales_plan_amt    -- ����v����z
                        );
          lv_errbuf  := lv_errmsg||SQLERRM;
          RAISE select_error_expt;
      END;
--
      -- �Y���f�[�^�������P���ȏ�̏ꍇ�A�ڋq�ʔ���v��e�[�u���̓��ʔ���v��f�[�^�X�V���s��
      -- �Y���f�[�^�������O���̏ꍇ�A�ڋq�ʔ���v��e�[�u���̓��ʔ���v��f�[�^�o�^���s��
      BEGIN
        IF (ln_data_cnt >= 1) THEN
          lv_msg_code := cv_tkn_number_05;  -- �f�[�^�X�V�G���[�R�[�h�Z�b�g
          <<sales_plan_day_data_loop1>>
          FOR ln_loop_cnt IN 1..ln_day_on_month LOOP
            -- ==============================================================
            -- �ڋq�ʔ���v��e�[�u���̊Y�����̓��ʔ���v��f�[�^�X�V 
            -- ==============================================================
            UPDATE xxcso_account_sales_plans       -- �ڋq�ʔ���v��e�[�u��
            SET    last_updated_by        = cn_last_updated_by,        -- �ŏI�X�V��
                   last_update_date       = cd_last_update_date,       -- �ŏI�X�V��
                   last_update_login      = cn_last_update_login,      -- �ŏI�X�V���O�C��
                   request_id             = cn_request_id,             -- �v��ID
                   program_application_id = cn_program_application_id, -- �ݶ��ĥ��۸��т̱��ع����ID
                   program_id             = cn_program_id,             -- �ݶ��ĥ��۸���ID
                   program_update_date    = cd_program_update_date,    -- ��۸��тɂ��X�V��
                   sales_plan_day_amt     = l_sales_plan_day_on_month_tbl(ln_loop_cnt), -- ���ʔ���v��
                   update_func_div        = cv_upd_kbn_sales_month     -- �X�V�@�\�敪(6)
            WHERE  account_number = io_sales_plan_month_rec.account_number  -- �ڋq�R�[�h
              AND  base_code      = io_sales_plan_month_rec.sales_base_code -- ���㋒�_�R�[�h
              AND  plan_date      = io_sales_plan_month_rec.sales_plan_month||LPAD(TO_CHAR(ln_loop_cnt),2,'0') -- ����v��N����
              AND  month_date_div = cv_monday_kbn_day;                      -- �����敪(2)
          END LOOP sales_plan_day_data_loop1;
        ELSE
          lv_msg_code := cv_tkn_number_04;  -- �f�[�^�o�^�G���[�R�[�h�Z�b�g
          <<sales_plan_day_data_loop2>>
          FOR ln_loop_cnt IN 1..ln_day_on_month LOOP
            -- ==============================================================
            -- �ڋq�ʔ���v��e�[�u���̊Y�����̓��ʔ���v��f�[�^�o�^ 
            -- ==============================================================
            INSERT INTO xxcso_account_sales_plans(
              account_sales_plan_id,                                         -- �ڋq�ʔ���v��h�c
              base_code,                                                     -- ���㋒�_�R�[�h
              account_number,                                                -- �ڋq�R�[�h
              year_month,                                                    -- ����v��N��
              plan_day,                                                      -- ��
              fiscal_year,                                                   -- �N�x
              month_date_div,                                                -- �����敪
              sales_plan_month_amt,                                          -- ���ʔ���v��
              sales_plan_day_amt,                                            -- ���ʔ���v��
              plan_date,                                                     -- �N����
              party_id,                                                      -- �p�[�e�BID
              update_func_div,                                               -- �X�V�@�\�敪
              created_by,                                                    -- �쐬��
              creation_date,                                                 -- �쐬��
              last_updated_by,                                               -- �ŏI�X�V��
              last_update_date,                                              -- �ŏI�X�V��
              last_update_login,                                             -- �ŏI�X�V���O�C��
              request_id,                                                    -- �v��ID
              program_application_id,                                        -- �ݶ��ĥ��۸��т̱��ع����ID
              program_id,                                                    -- �ݶ��ĥ��۸���ID
              program_update_date                                            -- ��۸��тɂ��X�V��
            )VALUES(
              xxcso_account_sales_plans_s01.NEXTVAL,                         -- �ڋq�ʔ���v��h�c
              io_sales_plan_month_rec.sales_base_code,                       -- ���㋒�_�R�[�h
              io_sales_plan_month_rec.account_number,                        -- �ڋq�R�[�h
              io_sales_plan_month_rec.sales_plan_month,                      -- ����v��N��
-- ��Q�ԍ�067�Ή�
--              ln_loop_cnt,                                                   -- ��
              LPAD(TO_CHAR(ln_loop_cnt),2,'0'),                              -- ��
--
              gt_business_year,                                              -- �N�x
              cv_monday_kbn_day,                                             -- �����敪:���ʌv��F2
              NULL,                                                          -- ���ʔ���v��
              l_sales_plan_day_on_month_tbl(ln_loop_cnt),                    -- ���ʔ���v��
              io_sales_plan_month_rec.sales_plan_month||LPAD(TO_CHAR(ln_loop_cnt),2,'0'),  -- �N����
              io_sales_plan_month_rec.party_id,                              -- �p�[�e�BID
              cv_upd_kbn_sales_month,                                        -- �X�V�@�\�敪
              cn_created_by,                                                 -- �쐬��
              SYSDATE,                                                       -- �쐬��
              cn_last_updated_by,                                            -- �ŏI�X�V��
              SYSDATE,                                                       -- �ŏI�X�V��
              cn_last_update_login,                                          -- �ŏI�X�V���O�C��
              cn_request_id,                                                 -- �v��ID
              cn_program_application_id,                                     -- �ݶ��ĥ��۸��т̱��ع����ID
              cn_program_id,                                                 -- �ݶ��ĥ��۸���ID
              SYSDATE                                                        -- ��۸��тɂ��X�V��
            );
          END LOOP sales_plan_day_data_loop2;
        END IF;
      EXCEPTION
        -- *** OTHERS��O�n���h�� ***
        WHEN OTHERS THEN
          -- �G���[���b�Z�[�W�쐬
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                               -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => lv_msg_code                               -- ���b�Z�[�W�R�[�h 
                         ,iv_token_name1  => cv_tkn_tbl                                -- �g�[�N���R�[�h1
                         ,iv_token_value1 => cv_table_name                             -- �G���[�����̃e�[�u����
                         ,iv_token_name2  => cv_tkn_errmsg                             -- �g�[�N���R�[�h2
                         ,iv_token_value2 => SQLERRM                                   -- ORACLE�G���[
                         ,iv_token_name3  => cv_tkn_sequence                           -- �g�[�N���R�[�h3
                         ,iv_token_value3 => io_sales_plan_month_rec.no_seq            -- �V�[�P���X�ԍ�
                         ,iv_token_name4  => cv_tkn_cstm_cd                            -- �g�[�N���R�[�h4
                         ,iv_token_value4 => io_sales_plan_month_rec.account_number    -- �ڋq�R�[�h
                         ,iv_token_name5  => cv_tkn_cstm_nm                            -- �g�[�N���R�[�h5
                         ,iv_token_value5 => io_sales_plan_month_rec.account_name      -- �ڋq����
                         ,iv_token_name6  => cv_tkn_loc_cd                             -- �g�[�N���R�[�h6
                         ,iv_token_value6 => io_sales_plan_month_rec.sales_base_code   -- ���㋒�_�R�[�h
                         ,iv_token_name7  => cv_tkn_loc_nm                             -- �g�[�N���R�[�h7
                         ,iv_token_value7 => io_sales_plan_month_rec.sales_base_name   -- ���㋒�_����
                         ,iv_token_name8  => cv_tkn_ym                                 -- �g�[�N���R�[�h8
                         ,iv_token_value8 => io_sales_plan_month_rec.sales_plan_month  -- ����v��N��
                         ,iv_token_name9  => cv_tkn_mnt                                -- �g�[�N���R�[�h9
                         ,iv_token_value9 => io_sales_plan_month_rec.sales_plan_amt    -- ����v����z
                        );
          lv_errbuf  := lv_errmsg||SQLERRM;  
          RAISE ins_upd_expt;
      END;
    END IF;
--
  EXCEPTION
    -- *** ���[�gNo�����݂��Ȃ��ꍇ�f�[�^�X�V�����𔲂��� ***
    WHEN normal_expt THEN
      ov_retcode := cv_status_normal;  
    -- *** �f�[�^���o���̗�O�n���h�� ***
    WHEN select_error_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** �f�[�^�o�^�X�V��O�n���h�� ***
    WHEN ins_upd_expt THEN  
      ov_errmsg  := lv_errmsg;      
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END upd_sales_plan_day;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   ***********************************************************************************/
  PROCEDURE submain(
    ov_errbuf           OUT NOCOPY VARCHAR2,   -- �G���[�E���b�Z�[�W             --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,   -- ���^�[���E�R�[�h               --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2    -- ���[�U�[�E�G���[�E���b�Z�[�W   --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'submain';     -- �v���O������
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
    ln_sales_plan_cnt      NUMBER;                     -- ���ʔ���v��A�g�`�F�b�N�p�̃f�[�^����
    lb_not_exists_new_data BOOLEAN;                    -- �ŐV���R�[�h���݃`�F�b�N�t���O
    lv_msg_code            VARCHAR2(100);              -- ���b�Z�[�W�R�[�h
    lv_err_rec_info        VARCHAR2(5000);             -- �G���[�f�[�^�i�[�p
    lt_visit_target_div    xxcso_cust_accounts_v.vist_target_div%TYPE;    -- �K��Ώۋ敪
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR xispm_data_cur
    IS
      SELECT  xispm.no_seq  no_seq,                           -- �V�[�P���X�ԍ�
              xispm.account_number account_number,            -- �ڋq�R�[�h
              xispm.sales_base_code sales_base_code,          -- ���㋒�_�R�[�h
              xispm.sales_plan_month sales_plan_month,        -- ����v��N��
              xispm.sales_plan_amt sales_plan_amt             -- ����v����z
      FROM   xxcso_in_sales_plan_month  xispm                 -- ���ʔ���v�惏�[�N�e�[�u��
      ORDER BY xispm.no_seq;
--
    -- *** ���[�J���E���R�[�h ***
    l_xispm_data_rec      xispm_data_cur%ROWTYPE;
    l_get_data_rec        g_get_sales_plan_month_rtype;
--
    -- *** ���[�J����O ***
    skip_data_expt             EXCEPTION;  -- ���폈���ŃX�L�b�v����������O�i�ŐV���R�[�h�`�F�b�N�Ȃǁj
    error_skip_data_expt       EXCEPTION;  -- �}�X�^���݃`�F�b�N�G���[�ȂǂŔ���������O
    
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
    gn_skip_cnt   := 0;
    gn_error_cnt  := 0;
--
    -- ================================
    -- A-1.�������� 
    -- ================================
    init(
      ov_errbuf  => lv_errbuf,          -- �G���[�E���b�Z�[�W            --# �Œ� #
      ov_retcode => lv_retcode,         -- ���^�[���E�R�[�h              --# �Œ� #
      ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ====================================
    -- A-2.����v���񒊏o 
    -- ====================================
    -- �J�[�\���I�[�v��
    OPEN xispm_data_cur;
--
    <<get_data_loop>>
    LOOP
--
      BEGIN
        FETCH xispm_data_cur INTO l_xispm_data_rec;
        -- �����Ώی����i�[
        gn_target_cnt := xispm_data_cur%ROWCOUNT;
--
        EXIT WHEN xispm_data_cur%NOTFOUND
        OR  xispm_data_cur%ROWCOUNT = 0;
--
        -- ���R�[�h�ϐ�������
        l_get_data_rec := NULL;
--
        l_get_data_rec.no_seq                  := l_xispm_data_rec.no_seq;               -- �V�[�P���X�ԍ�
        l_get_data_rec.account_number          := l_xispm_data_rec.account_number;       -- �ڋq�R�[�h
        l_get_data_rec.sales_base_code         := l_xispm_data_rec.sales_base_code;      -- ���㋒�_�R�[�h
        l_get_data_rec.sales_plan_month        := l_xispm_data_rec.sales_plan_month;     -- ����v��N��
        l_get_data_rec.sales_plan_amt          := l_xispm_data_rec.sales_plan_amt;       -- ����v����z
--      
        -- INPUT�f�[�^�̍��ڂ��J���}��؂�ŕ����A�����ă��O�ɏo�͂���p
        lv_err_rec_info := l_get_data_rec.no_seq||','
                        || l_get_data_rec.account_number ||','
                        || l_get_data_rec.sales_base_code ||','
                        || l_get_data_rec.sales_plan_month ||','
                        || l_get_data_rec.sales_plan_amt || ' ';
--
        -- �N�x�擾
        gt_business_year := TO_CHAR(xxcso_util_common_pkg.get_business_year(
                              iv_year_month => l_get_data_rec.sales_plan_month));
--
        -- �N�x�擾�Ɏ��s�����ꍇ
        IF (gt_business_year IS NULL) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_tkn_number_07             -- ���b�Z�[�W�R�[�h
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- ========================================
        -- A-3.�}�X�^���݃`�F�b�N 
        -- ========================================
        chk_mst_is_exists(
          io_sales_plan_month_rec  => l_get_data_rec,                  -- ���ʔ���v�惏�[�N�e�[�u���f�[�^
          ov_errbuf                => lv_errbuf,      -- �G���[�E���b�Z�[�W            --# �Œ� #
          ov_retcode               => lv_retcode,     -- ���^�[���E�R�[�h              --# �Œ� #
          ov_errmsg                => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
        );
        -- �}�X�^���݃`�F�b�N�ŃG���[����������ꍇ�A���f�����܂��̓X�L�b�v����
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        ELSIF (lv_retcode = cv_status_warn) THEN
          RAISE error_skip_data_expt;
        END IF;
--
        -- ========================================
        -- A-4.�ŐV���R�[�h�`�F�b�N
        -- ========================================
        chk_is_new_recode(
          io_sales_plan_month_rec   => l_get_data_rec,              -- ���ʔ���v�惏�[�N�e�[�u���f�[�^
          ob_not_exists_new_data    => lb_not_exists_new_data,      -- �ŐV���R�[�h���݃`�F�b�N�t���O
          ov_errbuf                 => lv_errbuf,      -- �G���[�E���b�Z�[�W             --# �Œ� #
          ov_retcode                => lv_retcode,     -- ���^�[���E�R�[�h               --# �Œ� #
          ov_errmsg                 => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W   --# �Œ� #
        );
        -- �G���[����������ꍇ�͒��f�A�ŐV���R�[�h�����݂���ꍇ�͐���X�L�b�v
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        ELSIF (lb_not_exists_new_data = cb_false) THEN
          RAISE skip_data_expt;
        END IF;
--
        -- �ŐV���R�[�h�����݂��Ȃ��i���Y���R�[�h���V�[�P���X�ԍ����傫�����R�[�h���Ȃ��j�ꍇ
        -- ========================================
        -- A-5.���ʌv��A�g�`�F�b�N 
        -- ========================================  
        chk_sales_plan_day(
          io_sales_plan_month_rec  => l_get_data_rec,         -- ���ʔ���v�惏�[�N�e�[�u���f�[�^
          on_sales_plan_cnt        => ln_sales_plan_cnt,      -- ���ʔ���v��A�g�`�F�b�N�p�̃f�[�^����
          ov_errbuf                => lv_errbuf,      -- �G���[�E���b�Z�[�W            --# �Œ� #
          ov_retcode               => lv_retcode,     -- ���^�[���E�R�[�h              --# �Œ� #
          ov_errmsg                => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
        );
--
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
        -- ===============================================
        -- A-6.�ڋq�ʔ���v��f�[�^�̓o�^�܂��͍X�V 
        -- ===============================================
        upd_sales_plan_month(
            io_sales_plan_month_rec  => l_get_data_rec,         -- ���ʔ���v�惏�[�N�e�[�u���f�[�^
            ov_errbuf                => lv_errbuf,      -- �G���[�E���b�Z�[�W            --# �Œ� #
            ov_retcode               => lv_retcode,     -- ���^�[���E�R�[�h              --# �Œ� #
            ov_errmsg                => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
        );
--
        -- �ڋq�ʔ���v��f�[�^�̌��ʃf�[�^�o�^���X�V�ŃG���[����������ꍇ�͒��f
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        ELSIF (lv_retcode = cv_status_warn) THEN
          RAISE error_skip_data_expt;
        END IF;
--
        -- �ڋq�ʔ���v��f�[�^�̌��ʃf�[�^�o�^���X�V������̏ꍇ�͎��̏����ɐi��
        lt_visit_target_div := l_get_data_rec.vist_target_div;  -- �K��Ώۋ敪
        -- ===============================================
        -- A-7.���ʔ���v��f�[�^�̓o�^�܂��͍X�V 
        -- ===============================================
        -- �K��Ώۋ敪���u1�v�i�K��Ώہj�ŁA���ʔ���v��`�F�b�N���ʂ��Ȃ��̏ꍇ�A
        -- ���ڋq�ʔ���v��̌��ʃf�[�^�o�^�܂��͍X�V������̏ꍇ�A���ʃf�[�^�o�^���X�V
        IF (lt_visit_target_div = cv_houmon_kbn_taget) AND (ln_sales_plan_cnt = 0) 
          AND (lv_retcode = cv_status_normal) THEN
            upd_sales_plan_day(
              io_sales_plan_month_rec  => l_get_data_rec,  -- ���ʔ���v�惏�[�N�e�[�u���f�[�^
              ov_errbuf                => lv_errbuf,       -- �G���[�E���b�Z�[�W            --# �Œ� #
              ov_retcode               => lv_retcode,      -- ���^�[���E�R�[�h              --# �Œ� #
              ov_errmsg                => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
            );
--
          -- �ڋq�ʔ���v��f�[�^�̓��ʃf�[�^�o�^���X�V�ŃG���[����������ꍇ�͒��f
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          ELSIF (lv_retcode = cv_status_warn) THEN
            RAISE error_skip_data_expt;
          END IF;
        END IF;
--
        -- ========================
        -- A-8.�Z�[�u�|�C���g�ݒ�
        -- ========================
        SAVEPOINT a;
--        
        -- ���팏���J�E���g
        gn_normal_cnt := gn_normal_cnt + 1;
--
      EXCEPTION
          -- �f�[�^�����ΏۊO�ɂăX�L�b�v
          WHEN skip_data_expt THEN
            -- �X�L�b�v�����J�E���g
            gn_skip_cnt := gn_skip_cnt + 1;
            -- �X�L�b�v�f�[�^���O�o��
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff   => cv_debug_msg3 || lv_err_rec_info || CHR(10) ||
                         ''
            );
          -- �f�[�^�`�F�b�N�A�o�^�G���[�ɂăX�L�b�v
          WHEN error_skip_data_expt THEN
            -- �G���[�����J�E���g
            gn_error_cnt := gn_error_cnt + 1;
            -- �G���[�o��
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg                  -- ���[�U�[�E�G���[���b�Z�[�W
            );
            -- �G���[���O�i�f�[�^���{�G���[���b�Z�[�W�j
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff   => lv_err_rec_info || lv_errbuf || CHR(10) ||
                         ''
            );
            -- ���[���o�b�N
            IF (gn_normal_cnt = 0) THEN
              ROLLBACK;
            ELSE
              ROLLBACK TO SAVEPOINT a;
            END IF;
            -- �S�̂̏����X�e�[�^�X�Ɍx���Z�b�g
            ov_retcode := cv_status_warn;
      END;
    END LOOP get_data_loop;
    -- �J�[�\���N���[�Y
    CLOSE xispm_data_cur;
--
  EXCEPTION
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      gn_error_cnt := gn_error_cnt + 1;                           -- �G���[�����J�E���g
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF xispm_data_cur%ISOPEN THEN
        -- �J�[�\���N���[�Y
        CLOSE xispm_data_cur;
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
      gn_error_cnt := gn_error_cnt + 1;                           -- �G���[�����J�E���g
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      gn_error_cnt := gn_error_cnt + 1;                           -- �G���[�����J�E���g
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF xispm_data_cur%ISOPEN THEN
        -- �J�[�\���N���[�Y
        CLOSE xispm_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      gn_error_cnt := gn_error_cnt + 1;                           -- �G���[�����J�E���g
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF xispm_data_cur%ISOPEN THEN
        -- �J�[�\���N���[�Y
        CLOSE xispm_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
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
    errbuf        OUT NOCOPY VARCHAR2,    --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT NOCOPY VARCHAR2     --   ���^�[���E�R�[�h    --# �Œ� #
  )
  IS
--
--###########################  �Œ蕔 START   ###########################
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
    lv_message_code  VARCHAR2(100);  -- �I�����b�Z�[�W���i�[
--
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
      ov_retcode => lv_retcode,
      ov_errbuf  => lv_errbuf,
      ov_errmsg  => lv_errmsg
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
      ov_errbuf   => lv_errbuf,           -- �G���[�E���b�Z�[�W            --# �Œ� #
      ov_retcode  => lv_retcode,          -- ���^�[���E�R�[�h              --# �Œ� #
      ov_errmsg   => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
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
    -- ===============
    -- A-9.�I������
    -- ===============
    -- ��s�̏o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name,
                    iv_name         => cv_target_rec_msg,
                    iv_token_name1  => cv_cnt_token,
                    iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name,
                    iv_name         => cv_success_rec_msg,
                    iv_token_name1  => cv_cnt_token,
                    iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name,
                    iv_name         => cv_skip_rec_msg,
                    iv_token_name1  => cv_cnt_token,
                    iv_token_value1 => TO_CHAR(gn_skip_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name,
                    iv_name         => cv_error_rec_msg,
                    iv_token_name1  => cv_cnt_token,
                    iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    fnd_file.put_line(
      which  => FND_FILE.OUTPUT,
      buff   => gv_out_msg
    );
--
    --�I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF (lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;      
    ELSIF (lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
--
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name,
                    iv_name         => lv_message_code
                   );
    fnd_file.put_line(
      which  => FND_FILE.OUTPUT,
      buff   => gv_out_msg
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
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
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
END XXCSO014A01C;
/
