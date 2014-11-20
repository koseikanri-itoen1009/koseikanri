CREATE OR REPLACE PACKAGE BODY XXCSO014A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO014A02C(body)
 * Description      : ���ʔ���v��f�[�^���ڋq�ʔ���v��e�[�u���֓o�^�܂��͍X�V���܂��B
 *                    
 * MD.050           : MD050_CSO_014_A02_HHT-EBS�C���^�t�F�[�X�iIN�j�F����v�����
 *                    
 * Version          : 1.0
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                        Description
 * ---------------------------- ----------------------------------------------------------
 *  init                        �������� (A-1)
 *  chk_mst_is_exists           �}�X�^���݃`�F�b�N (A-3)
 *  chk_is_new_recode           �ŐV���R�[�h�`�F�b�N (A-4)
 *  store_data_one_month        �P�����P�ʂ̓��ʔ���v��f�[�^�ێ� (A-5) 
 *  upd_sales_plan_day          �P���������ʔ���v��f�[�^�̓o�^�܂��͍X�V (A-6)
 *  del_wrk_tbl_data            ���[�N�e�[�u���f�[�^�폜 (A-8)
 *  submain                     ���C�������v���V�[�W��
 *                                ����v���񒊏o (A-2)
 *                                �Z�[�u�|�C���g�ݒ� (A-7)
 *  main                        �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                                �I������(A-9)
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-12-24    1.0   Kenji.Sai        �V�K�쐬
 *  2009-03-17    1.1   K.Boku           �y������Q68�z��(����)�擪�O����
 *  2009-04-27    1.2   K.Satomura       �V�X�e���e�X�g��Q�Ή�(T1_0578)
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
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCSO014A02C';      -- �p�b�P�[�W��
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
  cv_tkn_number_01       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00080';  -- �f�[�^���o�G���[
  cv_tkn_number_02       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00081';  -- �ڋq�R�[�h�Ȃ��x��
  cv_tkn_number_03       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00082';  -- ���㋒�_�R�[�h�Ȃ��x��
  cv_tkn_number_04       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00083';  -- �f�[�^�ǉ��G���[
  cv_tkn_number_05       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00084';  -- �f�[�^�X�V�G���[
  cv_tkn_number_06       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00011';  -- �Ɩ��������t�擾�G���[ 
  cv_tkn_number_07       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00149';  -- �N�x�擾�G���[
  cv_tkn_number_08       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00071';  -- ���Y���ɑ��݂��Ȃ����t�f�[�^�x��
  cv_tkn_number_09       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00119';  -- �f�[�^�폜�G���[
--
  -- �g�[�N���R�[�h
  cv_tkn_errmsg          CONSTANT VARCHAR2(20) := 'ERR_MESSAGE';
  cv_tkn_tbl             CONSTANT VARCHAR2(20) := 'TABLE';  
  cv_tkn_sequence        CONSTANT VARCHAR2(20) := 'SEQUENCE';
  cv_tkn_cstm_cd         CONSTANT VARCHAR2(20) := 'CUSTOMERCODE';
  cv_tkn_cstm_nm         CONSTANT VARCHAR2(20) := 'CUSTOMERNAME';
  cv_tkn_loc_cd          CONSTANT VARCHAR2(20) := 'LOCATIONCODE';
  cv_tkn_loc_nm          CONSTANT VARCHAR2(20) := 'LOCATIONNAME';
  cv_tkn_ymd             CONSTANT VARCHAR2(20) := 'YEARMONTHDAY';
  cv_tkn_mnt             CONSTANT VARCHAR2(20) := 'MOUNT';
  cv_tkn_cnt             CONSTANT VARCHAR2(20) := 'COUNT';
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
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- �X�L�b�v�����A�L�[�u���C�N�����p���R�[�h
  TYPE g_store_key_data_rtype IS RECORD(
    account_number      xxcso_in_sales_plan_day.account_number%TYPE,        -- �ڋq�R�[�h
    sales_base_code     xxcso_in_sales_plan_day.sales_base_code%TYPE,       -- ���㋒�_�R�[�h
    sales_plan_day      xxcso_in_sales_plan_day.sales_plan_day%TYPE,        -- ����v��N����
    sales_plan_month    VARCHAR2(6)                                         -- ����v��N��
  );
  -- ���ʔ���v�惏�[�N�e�[�u�����֘A��񒊏o�f�[�^
  TYPE g_get_sales_plan_day_rtype IS RECORD(
    no_seq              xxcso_in_sales_plan_day.no_seq%TYPE,                -- �V�[�P���X�ԍ�
    account_number      xxcso_in_sales_plan_day.account_number%TYPE,        -- �ڋq�R�[�h
    sales_base_code     xxcso_in_sales_plan_day.sales_base_code%TYPE,       -- ���㋒�_�R�[�h
    sales_plan_day      xxcso_in_sales_plan_day.sales_plan_day%TYPE,        -- ����v��N����
    sales_plan_amt      xxcso_in_sales_plan_day.sales_plan_amt%TYPE,        -- ����v����z
    party_id            xxcso_cust_accounts_v.party_id%TYPE,                -- �p�[�e�BID
    vist_target_div     xxcso_cust_accounts_v.vist_target_div%TYPE,         -- �K��Ώۋ敪
    account_name        xxcso_cust_accounts_v.account_name%TYPE,            -- �ڋq����
    sales_base_name     xxcso_aff_base_v.base_name%TYPE                     -- ���㋒�_����
  );
  -- �e�[�u���^��`
  TYPE store_month_data_ttype IS TABLE OF g_get_sales_plan_day_rtype INDEX BY PLS_INTEGER;
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  gd_process_date        DATE;                                        -- �Ɩ�������
  gt_business_year       xxcso_account_sales_plans.fiscal_year%TYPE;  -- �N�x
  g_skip_key_data_rec    g_store_key_data_rtype;                      -- �P�������X�L�b�v�����p
  g_break_key_data_rec   g_store_key_data_rtype;                      -- �P�����f�[�^�o�^���̃L�[�u���C�N�p
  g_store_month_data_tab store_month_data_ttype;                      -- �P�������f�[�^��ێ�����PLSQL�\
  gn_day_cnt             NUMBER;                                      -- �L�[�u���C�N�����f�[�^�J�E���g�p�ϐ�
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
    g_skip_key_data_rec    := NULL;                                  -- �P�������X�L�b�v�����p
    g_break_key_data_rec   := NULL;                                  -- �P�����f�[�^�o�^���̃L�[�u���C�N�p
    gn_day_cnt             := 0;                                     -- �L�[�u���C�N�����f�[�^�J�E���g��������
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
    io_sales_plan_day_rec IN OUT NOCOPY g_get_sales_plan_day_rtype,  
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
    cv_table_name_xispd  CONSTANT VARCHAR2(100) := 'xxcso_in_sales_plan_day';  -- ���ʔ���v�惏�[�N�e�[�u��
    -- *** ���[�J���ϐ� ***
    lt_account_number      xxcso_cust_accounts_v.account_number%TYPE;          -- �ڋq�R�[�h
    lt_party_id            xxcso_cust_accounts_v.party_id%TYPE;                -- �p�[�e�BID
    lt_vist_target_div     xxcso_cust_accounts_v.vist_target_div%TYPE;         -- �K��Ώۋ敪
    lt_account_name        xxcso_cust_accounts_v.account_name%TYPE;            -- �ڋq����
    lt_sales_base_name     xxcso_aff_base_v.base_name%TYPE;                    -- ���㋒�_����   
    lv_date_dummy          VARCHAR2(20);                                       -- ���t�`�F�b�N�p�ϐ�
--
    -- *** ���[�J���E���R�[�h ***
    l_sales_plan_month_rec  g_get_sales_plan_day_rtype; 
-- IN�p�����[�^.���ʔ���v�惏�[�N�e�[�u���f�[�^�i�[
    --*** ���[�J���E��O ***
    warning_expt       EXCEPTION;
    date_warning_expt  EXCEPTION;
-- 
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
    -- IN�p�����[�^�����R�[�h�ϐ��ɑ��
    l_sales_plan_month_rec := io_sales_plan_day_rec;
--
    -- ===========================
    -- �ڋq�}�X�^���݃`�F�b�N 
    -- ===========================
    BEGIN
--
      -- �ڋq�}�X�^�r���[����ڋq�R�[�h�A�p�[�e�BID�A�K��Ώۋ敪�A�ڋq���̂𒊏o����
      SELECT xcav.account_number account_number, 
             xcav.party_id party_id, 
             xcav.vist_target_div vist_target_div, 
             xcav.account_name account_name
      INTO   lt_account_number, 
             lt_party_id, 
             lt_vist_target_div, 
             lt_account_name
      FROM   xxcso_cust_accounts_v xcav
      WHERE  xcav.account_number = io_sales_plan_day_rec.account_number
        AND  xcav.account_status = cv_active_status
        AND  xcav.party_status   = cv_active_status;
--
      -- �擾�����ڋq�}�X�^�f�[�^��OUT�p�����[�^�ɐݒ�
      io_sales_plan_day_rec.party_id          := lt_party_id;                -- �p�[�e�BID
      io_sales_plan_day_rec.vist_target_div   := lt_vist_target_div;         -- �K��Ώۋ敪
      io_sales_plan_day_rec.account_name      := lt_account_name;            -- �ڋq����
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
                       ,iv_token_value2 => io_sales_plan_day_rec.no_seq             -- �V�[�P���X�ԍ�
                       ,iv_token_name3  => cv_tkn_cstm_cd                           -- �g�[�N���R�[�h3
                       ,iv_token_value3 => io_sales_plan_day_rec.account_number     -- �ڋq�R�[�h
                       ,iv_token_name4  => cv_tkn_cstm_nm                           -- �g�[�N���R�[�h4
                       ,iv_token_value4 => io_sales_plan_day_rec.account_name       -- �ڋq����
                       ,iv_token_name5  => cv_tkn_loc_cd                            -- �g�[�N���R�[�h5
                       ,iv_token_value5 => io_sales_plan_day_rec.sales_base_code    -- ���㋒�_�R�[�h
                       ,iv_token_name6  => cv_tkn_loc_nm                            -- �g�[�N���R�[�h6
                       ,iv_token_value6 => io_sales_plan_day_rec.sales_base_name    -- ���㋒�_����
                       ,iv_token_name7  => cv_tkn_ymd                               -- �g�[�N���R�[�h7
                       ,iv_token_value7 => io_sales_plan_day_rec.sales_plan_day     -- ����v��N����
                       ,iv_token_name8  => cv_tkn_mnt                               -- �g�[�N���R�[�h8
                       ,iv_token_value8 => io_sales_plan_day_rec.sales_plan_amt     -- ����v����z
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
                       ,iv_token_value2 => io_sales_plan_day_rec.no_seq             -- �V�[�P���X�ԍ�
                       ,iv_token_name3  => cv_tkn_cstm_cd                           -- �g�[�N���R�[�h3
                       ,iv_token_value3 => io_sales_plan_day_rec.account_number     -- �ڋq�R�[�h
                       ,iv_token_name4  => cv_tkn_cstm_nm                           -- �g�[�N���R�[�h4
                       ,iv_token_value4 => io_sales_plan_day_rec.account_name       -- �ڋq����
                       ,iv_token_name5  => cv_tkn_loc_cd                            -- �g�[�N���R�[�h5
                       ,iv_token_value5 => io_sales_plan_day_rec.sales_base_code    -- ���㋒�_�R�[�h
                       ,iv_token_name6  => cv_tkn_loc_nm                            -- �g�[�N���R�[�h6
                       ,iv_token_value6 => io_sales_plan_day_rec.sales_base_name    -- ���㋒�_����
                       ,iv_token_name7  => cv_tkn_ymd                               -- �g�[�N���R�[�h7
                       ,iv_token_value7 => io_sales_plan_day_rec.sales_plan_day     -- ����v��N����
                       ,iv_token_name8  => cv_tkn_mnt                               -- �g�[�N���R�[�h8
                       ,iv_token_value8 => io_sales_plan_day_rec.sales_plan_amt     -- ����v����z
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
      SELECT xabv.base_name base_name
      INTO   lt_sales_base_name
      FROM   xxcso_aff_base_v xabv
      WHERE  xabv.base_code = io_sales_plan_day_rec.sales_base_code
        AND  gd_process_date BETWEEN TRUNC(NVL(xabv.start_date_active, gd_process_date))
               AND TRUNC(NVL(xabv.end_date_active, gd_process_date));
--
      -- �擾�������㋒�_���̂�OUT�p�����[�^�ɐݒ�
      io_sales_plan_day_rec.sales_base_name := lt_sales_base_name;           -- ���㋒�_����
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
                       ,iv_token_value2 => io_sales_plan_day_rec.no_seq             -- �V�[�P���X�ԍ�
                       ,iv_token_name3  => cv_tkn_cstm_cd                           -- �g�[�N���R�[�h3
                       ,iv_token_value3 => io_sales_plan_day_rec.account_number     -- �ڋq�R�[�h
                       ,iv_token_name4  => cv_tkn_cstm_nm                           -- �g�[�N���R�[�h4
                       ,iv_token_value4 => io_sales_plan_day_rec.account_name       -- �ڋq����
                       ,iv_token_name5  => cv_tkn_loc_cd                            -- �g�[�N���R�[�h5
                       ,iv_token_value5 => io_sales_plan_day_rec.sales_base_code    -- ���㋒�_�R�[�h
                       ,iv_token_name6  => cv_tkn_loc_nm                            -- �g�[�N���R�[�h6
                       ,iv_token_value6 => io_sales_plan_day_rec.sales_base_name    -- ���㋒�_����
                       ,iv_token_name7  => cv_tkn_ymd                               -- �g�[�N���R�[�h7
                       ,iv_token_value7 => io_sales_plan_day_rec.sales_plan_day     -- ����v��N����
                       ,iv_token_name8  => cv_tkn_mnt                               -- �g�[�N���R�[�h8
                       ,iv_token_value8 => io_sales_plan_day_rec.sales_plan_amt     -- ����v����z
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
                       ,iv_token_value2 => io_sales_plan_day_rec.no_seq             -- �V�[�P���X�ԍ�
                       ,iv_token_name3  => cv_tkn_cstm_cd                           -- �g�[�N���R�[�h3
                       ,iv_token_value3 => io_sales_plan_day_rec.account_number     -- �ڋq�R�[�h
                       ,iv_token_name4  => cv_tkn_cstm_nm                           -- �g�[�N���R�[�h4
                       ,iv_token_value4 => io_sales_plan_day_rec.account_name       -- �ڋq����
                       ,iv_token_name5  => cv_tkn_loc_cd                            -- �g�[�N���R�[�h5
                       ,iv_token_value5 => io_sales_plan_day_rec.sales_base_code    -- ���㋒�_�R�[�h
                       ,iv_token_name6  => cv_tkn_loc_nm                            -- �g�[�N���R�[�h6
                       ,iv_token_value6 => io_sales_plan_day_rec.sales_base_name    -- ���㋒�_����
                       ,iv_token_name7  => cv_tkn_ymd                               -- �g�[�N���R�[�h7
                       ,iv_token_value7 => io_sales_plan_day_rec.sales_plan_day     -- ����v��N����
                       ,iv_token_name8  => cv_tkn_mnt                               -- �g�[�N���R�[�h8
                       ,iv_token_value8 => io_sales_plan_day_rec.sales_plan_amt     -- ����v����z
                      );
        lv_errbuf  := lv_errmsg||SQLERRM;
        RAISE warning_expt;
    END;   
    -- ===========================
    -- ���Y���ɑ��݂��Ȃ����t�`�F�b�N
    -- ===========================  
    BEGIN    
      SELECT TO_DATE(io_sales_plan_day_rec.sales_plan_day,'YYYYMMDD')
      INTO lv_date_dummy
      FROM DUAL;
    EXCEPTION
      -- *** OTHERS��O�n���h�� ***
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                              -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_08                         -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tbl                               -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_table_name_xispd                      -- �G���[�����̃e�[�u����
                       ,iv_token_name2  => cv_tkn_sequence                          -- �g�[�N���R�[�h2
                       ,iv_token_value2 => io_sales_plan_day_rec.no_seq             -- �V�[�P���X�ԍ�
                       ,iv_token_name3  => cv_tkn_cstm_cd                           -- �g�[�N���R�[�h3
                       ,iv_token_value3 => io_sales_plan_day_rec.account_number     -- �ڋq�R�[�h
                       ,iv_token_name4  => cv_tkn_cstm_nm                           -- �g�[�N���R�[�h4
                       ,iv_token_value4 => io_sales_plan_day_rec.account_name       -- �ڋq����
                       ,iv_token_name5  => cv_tkn_loc_cd                            -- �g�[�N���R�[�h5
                       ,iv_token_value5 => io_sales_plan_day_rec.sales_base_code    -- ���㋒�_�R�[�h
                       ,iv_token_name6  => cv_tkn_loc_nm                            -- �g�[�N���R�[�h6
                       ,iv_token_value6 => io_sales_plan_day_rec.sales_base_name    -- ���㋒�_����
                       ,iv_token_name7  => cv_tkn_ymd                               -- �g�[�N���R�[�h7
                       ,iv_token_value7 => io_sales_plan_day_rec.sales_plan_day     -- ����v��N����
                       ,iv_token_name8  => cv_tkn_mnt                               -- �g�[�N���R�[�h8
                       ,iv_token_value8 => io_sales_plan_day_rec.sales_plan_amt     -- ����v����z
                      );
        lv_errbuf  := lv_errmsg||SQLERRM;
        RAISE date_warning_expt;
    END;
--    
  EXCEPTION
--
    -- *** �Y���f�[�^�����݂��Ȃ��A�f�[�^���o�G���[�������̗�O�n���h�� ***
    WHEN warning_expt THEN
      -- �X�L�b�v�����p�ϐ��ւ̃f�[�^�Z�b�g
      g_skip_key_data_rec.account_number    := io_sales_plan_day_rec.account_number;             -- �ڋq�R�[�h
      g_skip_key_data_rec.sales_base_code   := io_sales_plan_day_rec.sales_base_code;            -- ���㋒�_�R�[�h
      g_skip_key_data_rec.sales_plan_day    := io_sales_plan_day_rec.sales_plan_day;             -- ����v��N����
      g_skip_key_data_rec.sales_plan_month  := SUBSTR(io_sales_plan_day_rec.sales_plan_day,1,6); -- ����v��N��
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      -- �X�e�[�^�X�͌x��
      ov_retcode := cv_status_warn;
    -- *** ���Y���ɑ��݂��Ȃ����t���̗�O�n���h�� ***
    WHEN date_warning_expt THEN
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
    io_sales_plan_day_rec IN OUT NOCOPY g_get_sales_plan_day_rtype,   -- ���ʔ���v�惏�[�N�e�[�u���f�[�^
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
    cv_table_name       CONSTANT VARCHAR2(100)  := 'xxcso_in_sales_plan_day';   -- ���ʔ���v�惏�[�N�e�[�u��
    -- *** ���[�J���E�ϐ� ***
    lt_max_no_seq          xxcso_in_sales_plan_day.no_seq%TYPE;    -- �ő�V�[�P���X�ԍ�
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
      SELECT  MAX(xispd.no_seq) max_no_seq
      INTO    lt_max_no_seq
      FROM    xxcso_in_sales_plan_day  xispd
      WHERE   xispd.account_number   = io_sales_plan_day_rec.account_number
        AND   xispd.sales_base_code  = io_sales_plan_day_rec.sales_base_code
        AND   xispd.sales_plan_day   = io_sales_plan_day_rec.sales_plan_day;
      -- ���Y���R�[�h�̃V�[�P���X�ԍ����ő�V�[�P���X�ԍ����A�傫���ꍇ�A�X�L�b�v����
      -- ���Y���R�[�h�̃V�[�P���X�ԍ����ő�V�[�P���X�ԍ��Ɠ����ꍇ�A����
      IF (lt_max_no_seq > io_sales_plan_day_rec.no_seq) THEN
        -- �ŐV���R�[�h�`�F�b�N�t���O�ɁuFALSE�v�i�ŐV���R�[�h�����݂���j���Z�b�g
        lb_not_exists_new_data := cb_false;                        
        -- �X�L�b�v�����p�ϐ��ւ̃f�[�^�Z�b�g
        g_skip_key_data_rec.account_number    := io_sales_plan_day_rec.account_number;             -- �ڋq�R�[�h
        g_skip_key_data_rec.sales_base_code   := io_sales_plan_day_rec.sales_base_code;            -- ���㋒�_�R�[�h
        g_skip_key_data_rec.sales_plan_day    := io_sales_plan_day_rec.sales_plan_day;             -- ����v��N����
        g_skip_key_data_rec.sales_plan_month  := SUBSTR(io_sales_plan_day_rec.sales_plan_day,1,6); -- ����v��N��
      END IF;
      -- �擾�����ŐV���R�[�h�`�F�b�N���ʂ�OUT�p�����[�^�ɐݒ�
      ob_not_exists_new_data   := lb_not_exists_new_data;
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
                       ,iv_token_value3 => io_sales_plan_day_rec.no_seq              -- �V�[�P���X�ԍ�
                       ,iv_token_name4  => cv_tkn_cstm_cd                            -- �g�[�N���R�[�h4
                       ,iv_token_value4 => io_sales_plan_day_rec.account_number      -- �ڋq�R�[�h
                       ,iv_token_name5  => cv_tkn_cstm_nm                            -- �g�[�N���R�[�h5
                       ,iv_token_value5 => io_sales_plan_day_rec.account_name        -- �ڋq����
                       ,iv_token_name6  => cv_tkn_loc_cd                             -- �g�[�N���R�[�h6
                       ,iv_token_value6 => io_sales_plan_day_rec.sales_base_code     -- ���㋒�_�R�[�h
                       ,iv_token_name7  => cv_tkn_loc_nm                             -- �g�[�N���R�[�h7
                       ,iv_token_value7 => io_sales_plan_day_rec.sales_base_name     -- ���㋒�_����
                       ,iv_token_name8  => cv_tkn_ymd                                -- �g�[�N���R�[�h8
                       ,iv_token_value8 => io_sales_plan_day_rec.sales_plan_day      -- ����v��N����
                       ,iv_token_name9  => cv_tkn_mnt                                -- �g�[�N���R�[�h9
                       ,iv_token_value9 => io_sales_plan_day_rec.sales_plan_amt      -- ����v����z
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
   * Procedure Name   : store_data_one_month                                                       
   * Description      : �P�����P�ʂ̓��ʔ���v��f�[�^�ێ��iA-5�j
   ***********************************************************************************/
  PROCEDURE store_data_one_month(
    io_sales_plan_day_rec IN OUT NOCOPY g_get_sales_plan_day_rtype,    -- ���ʔ���v�惏�[�N�e�[�u���f�[�^
    ob_key_break_on         OUT BOOLEAN,                               -- �L�[�u���C�N�������f�p�t���O
    ov_errbuf               OUT NOCOPY VARCHAR2,        -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,        -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'store_data_one_month';     -- �v���O������
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
    lb_key_break_on     BOOLEAN;                                               -- �L�[�u���C�N�������f�p�t���O    
    ln_days_on_month    NUMBER;                                                -- �Y�����̓���
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
    -- �L�[�u���C�N�������f�p�t���O��FALSE���Z�b�g�i�L�[�u���C�N���������j
    lb_key_break_on     := cb_false;  
    -- �L�[�u���C�N�����f�[�^�J�E���g
    gn_day_cnt          := gn_day_cnt + 1;
    -- �L�[�u���C�N����
    IF g_break_key_data_rec.account_number IS NULL THEN
      -- �L�[�u���C�N�������f�p�t���O��TRUE���Z�b�g�i�L�[�u���C�N�����L��j
      lb_key_break_on   := cb_true;  
      -- �L�[�u���C�N�����ϐ��ւ̃f�[�^�Z�b�g
      g_break_key_data_rec.account_number   := io_sales_plan_day_rec.account_number;             -- �ڋq�R�[�h
      g_break_key_data_rec.sales_base_code  := io_sales_plan_day_rec.sales_base_code;            -- ���㋒�_�R�[�h
      g_break_key_data_rec.sales_plan_day   := io_sales_plan_day_rec.sales_plan_day;             -- ����v��N����
      g_break_key_data_rec.sales_plan_month := SUBSTR(io_sales_plan_day_rec.sales_plan_day,1,6); -- ����v��N��
      -- �L�[�u���C�N�����p�N���ɊY������������擾
      ln_days_on_month := TO_NUMBER(TO_CHAR(LAST_DAY(TO_DATE(g_break_key_data_rec.sales_plan_day, 'YYYYMMDD')),'DD')); 
      -- �P�������f�[�^�ێ��p�ϐ��ւ̃f�[�^�Z�b�g
      g_store_month_data_tab(gn_day_cnt)    := io_sales_plan_day_rec;
    ELSE  
      -- �L�[�u���C�N�����p�N���ɊY������������擾
      ln_days_on_month := TO_NUMBER(TO_CHAR(LAST_DAY(TO_DATE(g_break_key_data_rec.sales_plan_day, 'YYYYMMDD')),'DD')); 
      -- ���Y���R�[�h���N���P�ʂŃL�[�u���C�N�����p�̃��R�[�h�f�[�^�ƈ�v���ŏI���ŏꍇ�A�X�V�����ɐi��
      IF g_break_key_data_rec.account_number        = io_sales_plan_day_rec.account_number                 
          AND g_break_key_data_rec.sales_base_code  = io_sales_plan_day_rec.sales_base_code            
          AND g_break_key_data_rec.sales_plan_month = SUBSTR(io_sales_plan_day_rec.sales_plan_day,1,6)
          AND gn_day_cnt                            = ln_days_on_month THEN
        -- �L�[�u���C�N�������f�p�t���O��FALSE���Z�b�g�i�L�[�u���C�N���������A�X�V�����ɐi�ށj
        lb_key_break_on   := cb_false;  
        -- �P�������f�[�^�ێ��p�ϐ��ւ̃f�[�^�Z�b�g
        g_store_month_data_tab(gn_day_cnt)    := io_sales_plan_day_rec;
      -- ��L�����ȊO�̏ꍇ�A�L�[�u���C�N����
      ELSE
        -- �L�[�u���C�N�������f�p�t���O��TRUE���Z�b�g�i�L�[�u���C�N�����L��j
        lb_key_break_on   := cb_true;  
        -- �P�������f�[�^�ێ��p�ϐ��ւ̃f�[�^�Z�b�g
        g_store_month_data_tab(gn_day_cnt)    := io_sales_plan_day_rec;
      END IF;
    END IF;
--
   ob_key_break_on := lb_key_break_on;
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
  END store_data_one_month;
--
  /**********************************************************************************
   * Procedure Name   : upd_sales_plan_day                                                                         
   * Description      : ���ʔ���v��f�[�^�̓o�^�܂��͍X�V (A-6)
   ***********************************************************************************/
  PROCEDURE upd_sales_plan_day(
    io_sales_plan_day_rec   IN OUT NOCOPY g_get_sales_plan_day_rtype,    -- ���ʔ���v�惏�[�N�e�[�u���f�[�^
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
    ln_data_cnt            NUMBER;              -- �ڋq�ʔ���v��e�[�u���̓��ʔ���v��f�[�^����    
    lv_msg_code            VARCHAR2(200);                                        -- ���b�Z�[�W�R�[�h
--
    lv_table_name          VARCHAR2(200);       -- �e�[�u����
    -- *** ���[�J���E��O ***
    select_error_expt      EXCEPTION;
    ins_upd_expt           EXCEPTION;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ==============================================================
    -- �ڋq�ʔ���v��e�[�u������Y�����ʔ���f�[�^�������擾 
    -- ==============================================================
    BEGIN
      SELECT COUNT(xasp.account_sales_plan_id) datacnt
      INTO   ln_data_cnt
      FROM   xxcso_account_sales_plans xasp
      WHERE  xasp.account_number = g_break_key_data_rec.account_number
        AND  xasp.base_code      = g_break_key_data_rec.sales_base_code
        AND  xasp.year_month     = g_break_key_data_rec.sales_plan_month
        AND  xasp.month_date_div = cv_monday_kbn_day;
--
    EXCEPTION
      -- *** OTHERS��O�n���h�� ***
      WHEN OTHERS THEN
        -- �G���[���b�Z�[�W�쐬
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name              -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_01         -- ���b�Z�[�W�R�[�h �f�[�^���o�G���[
                       ,iv_token_name1  => cv_tkn_tbl                                    -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_table_name                                 -- �G���[�����̃e�[�u����
                       ,iv_token_name2  => cv_tkn_errmsg                                 -- �g�[�N���R�[�h2
                       ,iv_token_value2 => SQLERRM                                       -- ORACLE�G���[
                       ,iv_token_name3  => cv_tkn_sequence                               -- �g�[�N���R�[�h3
                       ,iv_token_value3 => g_store_month_data_tab(1).no_seq              -- �V�[�P���X�ԍ�
                       ,iv_token_name4  => cv_tkn_cstm_cd                                -- �g�[�N���R�[�h4
                       ,iv_token_value4 => g_store_month_data_tab(1).account_number      -- �ڋq�R�[�h
                       ,iv_token_name5  => cv_tkn_cstm_nm                                -- �g�[�N���R�[�h5
                       ,iv_token_value5 => g_store_month_data_tab(1).account_name        -- �ڋq����
                       ,iv_token_name6  => cv_tkn_loc_cd                                 -- �g�[�N���R�[�h6
                       ,iv_token_value6 => g_store_month_data_tab(1).sales_base_code     -- ���㋒�_�R�[�h
                       ,iv_token_name7  => cv_tkn_loc_nm                                 -- �g�[�N���R�[�h7
                       ,iv_token_value7 => g_store_month_data_tab(1).sales_base_name     -- ���㋒�_����
                       ,iv_token_name8  => cv_tkn_ymd                                    -- �g�[�N���R�[�h8
                       ,iv_token_value8 => g_store_month_data_tab(1).sales_plan_day      -- ����v��N����
                       ,iv_token_name9  => cv_tkn_mnt                                    -- �g�[�N���R�[�h9
                       ,iv_token_value9 => TO_CHAR(g_store_month_data_tab(1).sales_plan_amt)  -- ����v����z
                      );
        lv_errbuf  := lv_errmsg||SQLERRM;
        RAISE select_error_expt;
    END;
--
    -- �Y���f�[�^�������P���ȏ�̏ꍇ�A�ڋq�ʔ���v��e�[�u���̓��ʔ���v��f�[�^�̔���v����z��NULL�ōX�V
    -- �Y���f�[�^�������O���̏ꍇ�A�ڋq�ʔ���v��e�[�u���̔���v����z��NULL�ɂē��ʔ���v��f�[�^�o�^���s��
    BEGIN
      IF (ln_data_cnt >= 1) THEN
        lv_msg_code := cv_tkn_number_05;  -- �f�[�^�X�V�G���[�R�[�h�Z�b�g
        -- ==============================================================
        -- �ڋq�ʔ���v��e�[�u���̊Y�����̓��ʔ���v��f�[�^�X�V 
        -- ==============================================================
        UPDATE xxcso_account_sales_plans
        SET    last_updated_by        = cn_last_updated_by,
               last_update_date       = cd_last_update_date,
               last_update_login      = cn_last_update_login,
               request_id             = cn_request_id,
               program_application_id = cn_program_application_id,
               program_id             = cn_program_id,
               program_update_date    = cd_program_update_date,
               sales_plan_day_amt     = NULL,
               update_func_div        = cv_upd_kbn_sales_day
        WHERE  account_number         = g_break_key_data_rec.account_number
          AND  base_code              = g_break_key_data_rec.sales_base_code
          AND  year_month             = g_break_key_data_rec.sales_plan_month
          AND  month_date_div         = cv_monday_kbn_day;
      ELSE
        lv_msg_code := cv_tkn_number_04;  -- �f�[�^�o�^�G���[�R�[�h�Z�b�g
        <<sales_plan_day_data_loop2>>
        FOR ln_loop_cnt IN 1..gn_day_cnt LOOP
          -- ==============================================================
          -- �ڋq�ʔ���v��e�[�u���̊Y�����̓��ʔ���v��f�[�^�o�^ 
          -- ==============================================================
          INSERT INTO xxcso_account_sales_plans(
            account_sales_plan_id,
            base_code,
            account_number,
            year_month,
            plan_day,
            fiscal_year,
            month_date_div,
            sales_plan_month_amt,
            sales_plan_day_amt,
            plan_date,
            party_id,
            update_func_div,
            created_by,
            creation_date,
            last_updated_by,
            last_update_date,
            last_update_login,
            request_id,
            program_application_id,
            program_id,
            program_update_date
          )VALUES(
            xxcso_account_sales_plans_s01.NEXTVAL,                                 -- �ڋq�ʔ���v��h�c
            g_store_month_data_tab(ln_loop_cnt).sales_base_code,                   -- ���㋒�_�R�[�h
            g_store_month_data_tab(ln_loop_cnt).account_number,                    -- �ڋq�R�[�h
            SUBSTR(g_store_month_data_tab(ln_loop_cnt).sales_plan_day,1,6),        -- ����v��N����
-- ������Q068
--            ln_loop_cnt,                                                           -- ��
            LPAD(TO_CHAR(ln_loop_cnt),2,'0'),                                      -- ��
--
            gt_business_year,                                                      -- �N�x
            cv_monday_kbn_day,                                                     -- �����敪:���ʌv��F2
            NULL,                                                                  -- ���ʔ���v��
            NULL,                                                                  -- ���ʔ���v��
            g_store_month_data_tab(ln_loop_cnt).sales_plan_day,                    -- �N����
            g_store_month_data_tab(ln_loop_cnt).party_id,                          -- �p�[�e�BID
            cv_upd_kbn_sales_day,                                                  -- �X�V�@�\�敪
            cn_created_by,                                                         -- �쐬��
            SYSDATE,                                                               -- �쐬��
            cn_last_updated_by,                                                    -- �ŏI�X�V��
            SYSDATE,                                                               -- �ŏI�X�V��
            cn_last_update_login,                                                  -- �ŏI�X�V���O�C��
            cn_request_id,                                                         -- �v��ID
            cn_program_application_id,              -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
            cn_program_id,                          -- �R���J�����g�E�v���O����ID	PROGRAM_ID
            SYSDATE                                 -- �v���O�����X�V��
          );
        END LOOP sales_plan_day_data_loop2;
      END IF;
      -- �P����������v����z�̍X�V
      lv_msg_code := cv_tkn_number_04;  -- �f�[�^�o�^�G���[�R�[�h�Z�b�g
      <<sales_plan_day_data_loop3>>
      FOR ln_loop_cnt IN 1..gn_day_cnt LOOP
        -- ==============================================================
        -- �ڋq�ʔ���v��e�[�u���̊Y�����̓��ʔ���v��f�[�^�X�V 
        -- ==============================================================
        UPDATE xxcso_account_sales_plans
        SET    last_updated_by        = cn_last_updated_by,
               last_update_date       = cd_last_update_date,
               last_update_login      = cn_last_update_login,
               request_id             = cn_request_id,
               program_application_id = cn_program_application_id,
               program_id             = cn_program_id,
               program_update_date    = cd_program_update_date,
               /* 2009.04.27 K.Satomura T1_0578�Ή� START */
               --sales_plan_day_amt     = g_store_month_data_tab(ln_loop_cnt).sales_plan_amt,
               sales_plan_day_amt     = DECODE(g_store_month_data_tab(ln_loop_cnt).sales_plan_amt
                                              ,0 ,NULL
                                              ,g_store_month_data_tab(ln_loop_cnt).sales_plan_amt),
               /* 2009.04.27 K.Satomura T1_0578�Ή� END */
               update_func_div        = cv_upd_kbn_sales_day
        WHERE  account_number         = g_store_month_data_tab(ln_loop_cnt).account_number
          AND  base_code              = g_store_month_data_tab(ln_loop_cnt).sales_base_code
          AND  plan_date              = g_store_month_data_tab(ln_loop_cnt).sales_plan_day
          AND  month_date_div         = cv_monday_kbn_day;
      END LOOP sales_plan_day_data_loop3;    
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
                       ,iv_token_value3 => g_store_month_data_tab(1).no_seq          -- �V�[�P���X�ԍ�
                       ,iv_token_name4  => cv_tkn_cstm_cd                            -- �g�[�N���R�[�h4
                       ,iv_token_value4 => g_store_month_data_tab(1).account_number  -- �ڋq�R�[�h
                       ,iv_token_name5  => cv_tkn_cstm_nm                            -- �g�[�N���R�[�h5
                       ,iv_token_value5 => g_store_month_data_tab(1).account_name    -- �ڋq����
                       ,iv_token_name6  => cv_tkn_loc_cd                             -- �g�[�N���R�[�h6
                       ,iv_token_value6 => g_store_month_data_tab(1).sales_base_code -- ���㋒�_�R�[�h
                       ,iv_token_name7  => cv_tkn_loc_nm                             -- �g�[�N���R�[�h7
                       ,iv_token_value7 => g_store_month_data_tab(1).sales_base_name -- ���㋒�_����
                       ,iv_token_name8  => cv_tkn_ymd                                -- �g�[�N���R�[�h8
                       ,iv_token_value8 => g_store_month_data_tab(1).sales_plan_day  -- ����v��N����
                       ,iv_token_name9  => cv_tkn_mnt                                -- �g�[�N���R�[�h9
                       ,iv_token_value9 => TO_CHAR(g_store_month_data_tab(1).sales_plan_amt)  -- ����v����z
                      );
        lv_errbuf  := lv_errmsg||SQLERRM;  
        RAISE ins_upd_expt;
    END;
    -- �P�����f�[�^�ێ��p�ϐ��̏�����
    g_store_month_data_tab.DELETE;
    -- �L�[�u���C�N�����p�ϐ��̏�����
    g_break_key_data_rec  := NULL;
--
  EXCEPTION
    -- *** �f�[�^���o���̗�O�n���h�� ***
    WHEN select_error_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** �f�[�^�o�^�X�V��O�n���h�� ***
    WHEN ins_upd_expt THEN  
      -- �P�����f�[�^�ێ��p�ϐ��̏�����
      g_store_month_data_tab.DELETE;
      -- �L�[�u���C�N�����p�ϐ��̏�����
      g_break_key_data_rec  := NULL;
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
   * Procedure Name   : del_wrk_tbl_data                                                                
   * Description      : ���[�N�e�[�u���f�[�^�폜 (A-8)
   ***********************************************************************************/
  PROCEDURE del_wrk_tbl_data(
    ov_errbuf                OUT NOCOPY VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT NOCOPY VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT NOCOPY VARCHAR2          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'del_wrk_tbl_data';     -- �v���O������
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
    cv_table_name_month     CONSTANT VARCHAR2(100) := 'xxcso_in_sales_plan_month';  -- ���ʔ���v�惏�[�N�e�[�u��
    cv_table_name_day       CONSTANT VARCHAR2(100) := 'xxcso_in_sales_plan_day';    -- ���ʔ���v�惏�[�N�e�[�u��
    -- *** ���[�J���ϐ� ***
    lv_msg_code            VARCHAR2(100);                                           -- ���b�Z�[�W�R�[�h
--
    -- *** ���[�J���E���R�[�h ***
    -- *** ���[�J���E��O ***
    del_tbl_data_expt     EXCEPTION;
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ======================================================
    -- ���ʔ���v�惏�[�N�e�[�u���f�[�^���폜
    -- ======================================================
    BEGIN
      DELETE FROM xxcso_in_sales_plan_month;
--
    EXCEPTION
      -- *** OTHERS��O�n���h�� ***
      WHEN OTHERS THEN
        -- �G���[���b�Z�[�W�쐬
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name              -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_09         -- ���b�Z�[�W�R�[�h �f�[�^�폜�G���[
                       ,iv_token_name1  => cv_tkn_tbl                                -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_table_name_month                       -- �G���[�����̃e�[�u����
                       ,iv_token_name2  => cv_tkn_errmsg                             -- �g�[�N���R�[�h2
                       ,iv_token_value2 => SQLERRM                                   -- ORACLE�G���[
                      );
        lv_errbuf  := lv_errmsg||SQLERRM;
        RAISE del_tbl_data_expt;
    END;
--    
    -- ======================================================
    -- ���ʔ���v�惏�[�N�e�[�u���f�[�^���폜
    -- ======================================================
    BEGIN
      DELETE FROM xxcso_in_sales_plan_day;
--
    EXCEPTION
      -- *** OTHERS��O�n���h�� ***
      WHEN OTHERS THEN
        -- �G���[���b�Z�[�W�쐬
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name              -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_09         -- ���b�Z�[�W�R�[�h �f�[�^�폜�G���[
                       ,iv_token_name1  => cv_tkn_tbl                                -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_table_name_day                         -- �G���[�����̃e�[�u����
                       ,iv_token_name2  => cv_tkn_errmsg                             -- �g�[�N���R�[�h2
                       ,iv_token_value2 => SQLERRM                                   -- ORACLE�G���[
                      );
        lv_errbuf  := lv_errmsg||SQLERRM;
        RAISE del_tbl_data_expt;
    END;
--    
  EXCEPTION
    -- *** �f�[�^�폜���̗�O�n���h�� ***
    WHEN del_tbl_data_expt THEN
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
  END del_wrk_tbl_data;
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
    lb_not_exists_new_data BOOLEAN;                    -- �ŐV���R�[�h���݃`�F�b�N�t���O
    lb_key_break_on        BOOLEAN;                    -- �L�[�u���C�N�������f�p�t���O TRUE:�L�[�u���C�N����
    lv_msg_code            VARCHAR2(100);              -- ���b�Z�[�W�R�[�h
    lv_err_rec_info        VARCHAR2(5000);             -- �G���[�f�[�^�i�[�p
    lt_visit_target_div    VARCHAR2(1);                -- �K��Ώۋ敪
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR xispd_data_cur
    IS
      SELECT  xispd.no_seq  no_seq,                           -- �V�[�P���X�ԍ�
              xispd.account_number account_number,            -- �ڋq�R�[�h
              xispd.sales_base_code sales_base_code,          -- ���㋒�_�R�[�h
              xispd.sales_plan_day  sales_plan_day,           -- ����v��N����
              xispd.sales_plan_amt sales_plan_amt             -- ����v����z
      FROM   xxcso_in_sales_plan_day  xispd                   -- ���ʔ���v�惏�[�N�e�[�u��
      ORDER BY xispd.no_seq;
--
    -- *** ���[�J���E���R�[�h ***
    l_xispd_data_rec      xispd_data_cur%ROWTYPE;
    l_get_data_rec        g_get_sales_plan_day_rtype;
--
    -- *** ���[�J����O ***
    skip_data_expt             EXCEPTION;  -- ���폈���ŃX�L�b�v����������O�i�ŐV���R�[�h�`�F�b�N�Ȃǁj
    error_skip_data_expt       EXCEPTION;  -- �}�X�^���݃`�F�b�N�G���[�ȂǂŔ���������O
    key_break_expt             EXCEPTION;  -- �L�[�u���C�N������O�i���̏����𔲂��鏈���Ɏg���j
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
    OPEN xispd_data_cur;
--
    <<get_data_loop>>
    LOOP
--
      BEGIN
        FETCH xispd_data_cur INTO l_xispd_data_rec;
        -- �����Ώی����i�[
        gn_target_cnt := xispd_data_cur%ROWCOUNT;
--
        EXIT WHEN xispd_data_cur%NOTFOUND
        OR  xispd_data_cur%ROWCOUNT = 0;
--
        -- ���R�[�h�ϐ�������
        l_get_data_rec := NULL;
--
        l_get_data_rec.no_seq                  := l_xispd_data_rec.no_seq;               -- �V�[�P���X�ԍ�
        l_get_data_rec.account_number          := l_xispd_data_rec.account_number;       -- �ڋq�R�[�h
        l_get_data_rec.sales_base_code         := l_xispd_data_rec.sales_base_code;      -- ���㋒�_�R�[�h
        l_get_data_rec.sales_plan_day          := l_xispd_data_rec.sales_plan_day;       -- ����v��N����
        l_get_data_rec.sales_plan_amt          := l_xispd_data_rec.sales_plan_amt;       -- ����v����z
--      
        -- INPUT�f�[�^�̍��ڂ��J���}��؂�ŕ����A�����ă��O�ɏo�͂���p
        lv_err_rec_info := l_get_data_rec.no_seq||','
                        || l_get_data_rec.account_number ||','
                        || l_get_data_rec.sales_base_code ||','
                        || l_get_data_rec.sales_plan_day ||','
                        || l_get_data_rec.sales_plan_amt || ' ';
--
        -- �N�x�擾
        gt_business_year := TO_CHAR(xxcso_util_common_pkg.get_business_year(
                              iv_year_month => SUBSTR(l_get_data_rec.sales_plan_day,1,6)));
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
        -- �X�L�b�v�������f
        IF g_skip_key_data_rec.account_number IS NOT NULL THEN
          -- �X�L�b�v�����f�[�^�ƈ�v�����Y�f�[�^�̔���N�������قȂ�ꍇ�A�X�L�b�v����
          IF g_skip_key_data_rec.account_number        = l_get_data_rec.account_number
              AND g_skip_key_data_rec.sales_base_code  = l_get_data_rec.sales_base_code
              AND g_skip_key_data_rec.sales_plan_month = SUBSTR(l_get_data_rec.sales_plan_day,1,6)
              AND g_skip_key_data_rec.sales_plan_day   <> l_get_data_rec.sales_plan_day THEN
             -- ����X�L�b�v�̏ꍇ
             IF (lb_not_exists_new_data = cb_false) THEN
               RAISE skip_data_expt;
             -- �x���X�L�b�v�̏ꍇ 
             ELSIF (lv_retcode = cv_status_warn) THEN
               RAISE error_skip_data_expt;
             END IF;
          END IF; 
          -- �X�L�b�v�����f�[�^�ƈقȂ邩�A���Y�f�[�^�̔���N�����������̏ꍇ�A�X�L�b�v�����ϐ��̏��������p������
          IF g_skip_key_data_rec.account_number <> l_get_data_rec.account_number
              OR g_skip_key_data_rec.sales_base_code <> l_get_data_rec.sales_base_code
              OR g_skip_key_data_rec.sales_plan_month <> SUBSTR(l_get_data_rec.sales_plan_day,1,6)
              OR g_skip_key_data_rec.sales_plan_day = l_get_data_rec.sales_plan_day THEN
            g_skip_key_data_rec := NULL;
          END IF; 
        END IF;
--
        -- ========================================
        -- A-3.�}�X�^���݃`�F�b�N 
        -- ========================================
        chk_mst_is_exists(
          io_sales_plan_day_rec    => l_get_data_rec,  -- ���ʔ���v�惏�[�N�e�[�u���f�[�^
          ov_errbuf                => lv_errbuf,       -- �G���[�E���b�Z�[�W            --# �Œ� #
          ov_retcode               => lv_retcode,      -- ���^�[���E�R�[�h              --# �Œ� #
          ov_errmsg                => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
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
          io_sales_plan_day_rec     => l_get_data_rec,              -- ���ʔ���v�惏�[�N�e�[�u���f�[�^
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
        -- �L�[�u���C�N�����p�f�[�^�ƈ�v����ꍇ�A���̃��R�[�h���o�����ɐi��
        -- ========================================
        -- A-5.�P�����P�ʂ̓��ʔ���v��f�[�^�ێ� 
        -- ========================================  
        store_data_one_month(
          io_sales_plan_day_rec    => l_get_data_rec,     -- ���ʔ���v�惏�[�N�e�[�u���f�[�^
          ob_key_break_on          => lb_key_break_on,    -- �L�[�u���C�N�������f�p�t���O
          ov_errbuf                => lv_errbuf,          -- �G���[�E���b�Z�[�W            --# �Œ� #
          ov_retcode               => lv_retcode,         -- ���^�[���E�R�[�h              --# �Œ� #
          ov_errmsg                => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
        );
--
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        ELSIF (lb_key_break_on = cb_true) THEN
          RAISE key_break_expt;
        END IF;
--
        -- ===============================================
        -- A-6.�P���������ʔ���v��f�[�^�̓o�^�܂��͍X�V 
        -- ===============================================
        upd_sales_plan_day(
            io_sales_plan_day_rec    => l_get_data_rec,   -- ���ʔ���v�惏�[�N�e�[�u���f�[�^
            ov_errbuf                => lv_errbuf,        -- �G���[�E���b�Z�[�W            --# �Œ� #
            ov_retcode               => lv_retcode,       -- ���^�[���E�R�[�h              --# �Œ� #
            ov_errmsg                => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
        );
--
        -- �P���������ʔ���v��f�[�^�̓o�^�܂��͍X�V�ŃG���[����������ꍇ�͒��f
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        ELSIF (lv_retcode = cv_status_warn) THEN
          RAISE error_skip_data_expt;
        END IF;
--
        -- ========================
        -- A-7.�Z�[�u�|�C���g�ݒ�
        -- ========================
        SAVEPOINT a;
--  
        -- ���팏���J�E���g
        gn_normal_cnt := gn_normal_cnt + gn_day_cnt;
        -- �L�[�u���C�N�����f�[�^�J�E���g�ϐ�������
        gn_day_cnt    := 0;
--
      EXCEPTION
          -- �L�[�u���C�N����
          WHEN key_break_expt THEN
            NULL;
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
            -- �L�[�u���C�N�����f�[�^�J�E���g�ϐ�������
            gn_day_cnt    := 0;
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
--
    -- �J�[�\���N���[�Y
    CLOSE xispd_data_cur;
--
    -- ===============================================
    -- A-8.���[�N�e�[�u���f�[�^�폜 
    -- ===============================================
    del_wrk_tbl_data(
      ov_errbuf                => lv_errbuf,      -- �G���[�E���b�Z�[�W            --# �Œ� #
      ov_retcode               => lv_retcode,     -- ���^�[���E�R�[�h              --# �Œ� #
      ov_errmsg                => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    -- ���[�N�e�[�u���f�[�^�폜�ŃG���[����������ꍇ�͒��f
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      gn_error_cnt := gn_error_cnt + 1;                           -- �G���[�����J�E���g
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF xispd_data_cur%ISOPEN THEN
        -- �J�[�\���N���[�Y
        CLOSE xispd_data_cur;
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
      IF xispd_data_cur%ISOPEN THEN
        -- �J�[�\���N���[�Y
        CLOSE xispd_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      gn_error_cnt := gn_error_cnt + 1;                           -- �G���[�����J�E���g
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF xispd_data_cur%ISOPEN THEN
        -- �J�[�\���N���[�Y
        CLOSE xispd_data_cur;
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
END XXCSO014A02C;
/
