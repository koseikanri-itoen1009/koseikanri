CREATE OR REPLACE PACKAGE BODY XXCSO014A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO014A04C(body)
 * Description      : ���[�g��񃏁[�N�e�[�u��(�A�h�I��)�Ɏ�荞�܂ꂽ���[�g�����A
 *                    �ڋq���Ɗ֘A�t����EBS��̌ڋq�}�X�^�ɓo�^���܂��B
 *                    
 * MD.050           : MD050_CSO_014_A04_HHT-EBS�C���^�[�t�F�[�X�F(IN�j���[�g���
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
 *  upd_route_info              ���[�g���e�[�u���f�[�^�o�^�y�эX�V (A-5)
 *  del_wrk_tbl_data            ���[�g��񃏁[�N�e�[�u���f�[�^�폜 (A-7)
 *  submain                     ���C�������v���V�[�W��
 *                                ���[�g��񃏁[�N�e�[�u���f�[�^���o (A-2)
 *                                �Z�[�u�|�C���g�ݒ� (A-6)
 *  main                        �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                                �I������(A-8)
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-1-16    1.0   Kenji.Sai        �V�K�쐬
 *  2009-2-18    1.1   Kenji.Sai        �f�[�^���o�G���[�͌x���A�X�L�b�v�����ɂ��� 
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
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCSO014A04C';      -- �p�b�P�[�W��
  cv_app_name            CONSTANT VARCHAR2(5)   := 'XXCSO';             -- �A�v���P�[�V�����Z�k��
--
  cv_active_status       CONSTANT VARCHAR2(1)   := 'A';                 -- �A�N�e�B�u
--
  -- ���b�Z�[�W�R�[�h
  cv_tkn_number_01       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00390';  -- �f�[�^���o�G���[
  cv_tkn_number_02       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00391';  -- �ڋq�R�[�h�Ȃ��x��
  cv_tkn_number_03       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00393';  -- �f�[�^�X�V�G���[
  cv_tkn_number_04       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00072';  -- �f�[�^�폜�G���[
--
  -- �g�[�N���R�[�h
  cv_tkn_prof_nm         CONSTANT VARCHAR2(20) := 'PROF_NAME';
  cv_tkn_errmsg          CONSTANT VARCHAR2(20) := 'ERR_MESSAGE';
  cv_tkn_tbl             CONSTANT VARCHAR2(20) := 'TABLE';  
  cv_tkn_sequence        CONSTANT VARCHAR2(20) := 'SEQUENCE';
  cv_tkn_cstm_cd         CONSTANT VARCHAR2(20) := 'CUSTOMERCODE';
  cv_tkn_cstm_nm         CONSTANT VARCHAR2(20) := 'CUSTOMERNAME';
  cv_route_cd            CONSTANT VARCHAR2(20) := 'ROUTECODE';
  cv_tkn_ym              CONSTANT VARCHAR2(20) := 'DATE';
  cv_tkn_cnt             CONSTANT VARCHAR2(20) := 'COUNT';
--
  cb_true                CONSTANT BOOLEAN := TRUE;
  cb_false               CONSTANT BOOLEAN := FALSE;
--
  -- DEBUG_LOG�p���b�Z�[�W
  cv_debug_msg3           CONSTANT VARCHAR2(200) := '<<�X�L�b�v�������ꂽ�f�[�^>>';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  gd_process_date        DATE;                                                 -- �Ɩ�������
  -- �t�@�C���E�n���h���̐錾
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �擾���i�[���R�[�h�^��`
--
  -- ���[�g��񃏁[�N�e�[�u�����֘A��񒊏o�f�[�^
  TYPE g_get_route_info_rtype IS RECORD(
    no_seq                xxcso_in_route_no.no_seq%TYPE,                 -- �V�[�P���X�ԍ�
    record_number         xxcso_in_route_no.record_number%TYPE,          -- ���R�[�h�ԍ�
    account_number        xxcso_in_route_no.account_number%TYPE,         -- �ڋq�R�[�h
    route_no              xxcso_in_route_no.route_no%TYPE,               -- ���[�gNO
    input_date            xxcso_in_route_no.input_date%TYPE,             -- ���͓��t�iDATE�^�j
    coalition_trance_date xxcso_in_route_no.coalition_trance_date%TYPE,  -- �A�g�������iDATE�^�j
    input_date_ymd        VARCHAR2(8),                                   -- ���͓��t�iVARCHAR2:YYYYMMDD�j
    account_name          xxcso_cust_accounts_v.account_name%TYPE        -- �ڋq����
  );
  -- �e�[�u���^��`
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
    io_route_info_rec       IN OUT NOCOPY g_get_route_info_rtype,  -- ���[�g��񃏁[�N�e�[�u�����֘A��񒊏o�f�[�^
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
    cv_table_name        CONSTANT VARCHAR2(100) := '�ڋq�}�X�^�r���[';            -- �ڋq�}�X�^�r���[��
    -- *** ���[�J���ϐ� ***
    lt_account_name        xxcso_cust_accounts_v.account_name%TYPE;               -- �ڋq����
--
    -- *** ���[�J���E���R�[�h ***
    l_route_info_rec  g_get_route_info_rtype; 
-- IN�p�����[�^.���[�g��񃏁[�N�e�[�u���f�[�^�i�[
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
    l_route_info_rec := io_route_info_rec;
--
    -- ===========================
    -- �ڋq�}�X�^���݃`�F�b�N 
    -- ===========================
    BEGIN
--
      -- �ڋq�}�X�^�r���[����ڋq���̂𒊏o����
      SELECT xcav.account_name account_name          -- �ڋq�R�[�h
      INTO   lt_account_name                         -- �ڋq�R�[�h 
      FROM   xxcso_cust_accounts_v xcav              -- �ڋq�}�X�^�r���[
      WHERE  xcav.account_number = io_route_info_rec.account_number    -- �ڋq�R�[�h
        AND  xcav.account_status = cv_active_status                    -- �ڋq�X�e�[�^�X�iA)
        AND  xcav.party_status   = cv_active_status;                   -- �p�[�e�B�X�e�[�^�X�iA)
--
      -- �擾�����ڋq�}�X�^�f�[�^��OUT�p�����[�^�ɐݒ�
      io_route_info_rec.account_name      := lt_account_name;            -- �ڋq����
--
    EXCEPTION
      -- *** �Y���f�[�^�����݂��Ȃ���O�n���h�� ***
      WHEN NO_DATA_FOUND THEN
      -- �G���[���b�Z�[�W�쐬
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                              -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_02                         -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tbl                               -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_table_name                            -- �G���[�����̃e�[�u����
                       ,iv_token_name2  => cv_tkn_sequence                          -- �g�[�N���R�[�h2
                       ,iv_token_value2 => io_route_info_rec.no_seq                 -- �V�[�P���X�ԍ�
                       ,iv_token_name3  => cv_tkn_cstm_cd                           -- �g�[�N���R�[�h3
                       ,iv_token_value3 => io_route_info_rec.account_number         -- �ڋq�R�[�h
                       ,iv_token_name4  => cv_tkn_cstm_nm                           -- �g�[�N���R�[�h4
                       ,iv_token_value4 => io_route_info_rec.account_name           -- �ڋq����
                       ,iv_token_name5  => cv_route_cd                              -- �g�[�N���R�[�h5
                       ,iv_token_value5 => io_route_info_rec.route_no               -- ���[�g�R�[�h
                       ,iv_token_name6  => cv_tkn_ym                                -- �g�[�N���R�[�h6
                       ,iv_token_value6 => io_route_info_rec.input_date_ymd         -- ���͓��t
                      );
        lv_errbuf  := lv_errmsg||SQLERRM;
        RAISE warning_expt;
      -- *** OTHERS��O�n���h�� ***
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                              -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_01                         -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_errmsg                            -- �g�[�N���R�[�h1
                       ,iv_token_value1 => SQLERRM                                  -- SQLERRM
                       ,iv_token_name2  => cv_tkn_tbl                               -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_table_name                            -- �G���[�����̃e�[�u����
                       ,iv_token_name3  => cv_tkn_sequence                          -- �g�[�N���R�[�h3
                       ,iv_token_value3 => io_route_info_rec.no_seq                 -- �V�[�P���X�ԍ�
                       ,iv_token_name4  => cv_tkn_cstm_cd                           -- �g�[�N���R�[�h4
                       ,iv_token_value4 => io_route_info_rec.account_number         -- �ڋq�R�[�h
                       ,iv_token_name5  => cv_tkn_cstm_nm                           -- �g�[�N���R�[�h5
                       ,iv_token_value5 => io_route_info_rec.account_name           -- �ڋq����
                       ,iv_token_name6  => cv_route_cd                              -- �g�[�N���R�[�h6
                       ,iv_token_value6 => io_route_info_rec.route_no               -- ���[�g�R�[�h
                       ,iv_token_name7  => cv_tkn_ym                                -- �g�[�N���R�[�h7
                       ,iv_token_value7 => io_route_info_rec.input_date_ymd         -- ���͓��t
                      );
        lv_errbuf  := lv_errmsg||SQLERRM;
        RAISE warning_expt;
    END;
--    
  EXCEPTION
--
    -- *** �Y���f�[�^�����݂��Ȃ��A�f�[�^���o�G���[�������G���[�������̗�O�n���h�� ***
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
    io_route_info_rec       IN OUT NOCOPY g_get_route_info_rtype, -- ���[�g��񃏁[�N�e�[�u���f�[�^
    ob_not_exists_new_data  OUT BOOLEAN,                          -- �ŐV���R�[�h�`�F�b�N�t���O
    ov_errbuf               OUT NOCOPY VARCHAR2,            -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,            -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    cv_table_name       CONSTANT VARCHAR2(100)  := '���[�g��񃏁[�N�e�[�u��';   -- ���[�g��񃏁[�N�e�[�u��
    -- *** ���[�J���E�ϐ� ***
    lt_max_no_seq          xxcso_in_route_no.no_seq%TYPE;          -- �ő�V�[�P���X�ԍ�
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
    lb_not_exists_new_data := cb_true;                    -- �ŐV���R�[�h�����݂��Ȃ�
--
    -- ================================================================
    -- ���[�g��񃏁[�N�e�[�u������Y���ő�V�[�P���X�ԍ����擾 
    -- ================================================================
    BEGIN
      SELECT  MAX(xirn.no_seq) max_no_seq      -- �ő�V�[�P���X�ԍ�
      INTO    lt_max_no_seq                    -- �ő�V�[�P���X�ԍ� 
      FROM    xxcso_in_route_no  xirn          -- ���[�g��񃏁[�N�e�[�u��
      WHERE   xirn.account_number = io_route_info_rec.account_number;        -- �ڋq�R�[�h
--
      -- ���Y���R�[�h�̃V�[�P���X�ԍ����ő�V�[�P���X�ԍ����A�傫���ꍇ�A�X�L�b�v����
      -- ���Y���R�[�h�̃V�[�P���X�ԍ����ő�V�[�P���X�ԍ��Ɠ����ꍇ�A����
      IF (lt_max_no_seq > io_route_info_rec.no_seq) THEN
        lb_not_exists_new_data := cb_false;               -- �ŐV���R�[�h�����݂���
      END IF;
      -- �擾�����ŐV���R�[�h�`�F�b�N���ʂ�OUT�p�����[�^�ɐݒ�
      ob_not_exists_new_data := lb_not_exists_new_data;
--
    EXCEPTION
      -- *** OTHERS��O�n���h�� ***
      WHEN OTHERS THEN
        -- �G���[���b�Z�[�W�쐬
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                              -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_01                         -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_errmsg                            -- �g�[�N���R�[�h1
                       ,iv_token_value1 => SQLERRM                                  -- SQLERRM
                       ,iv_token_name2  => cv_tkn_tbl                               -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_table_name                            -- �G���[�����̃e�[�u����
                       ,iv_token_name3  => cv_tkn_sequence                          -- �g�[�N���R�[�h3
                       ,iv_token_value3 => io_route_info_rec.no_seq                 -- �V�[�P���X�ԍ�
                       ,iv_token_name4  => cv_tkn_cstm_cd                           -- �g�[�N���R�[�h4
                       ,iv_token_value4 => io_route_info_rec.account_number         -- �ڋq�R�[�h
                       ,iv_token_name5  => cv_tkn_cstm_nm                           -- �g�[�N���R�[�h5
                       ,iv_token_value5 => io_route_info_rec.account_name           -- �ڋq����
                       ,iv_token_name6  => cv_route_cd                              -- �g�[�N���R�[�h6
                       ,iv_token_value6 => io_route_info_rec.route_no               -- ���[�g�R�[�h
                       ,iv_token_name7  => cv_tkn_ym                                -- �g�[�N���R�[�h7
                       ,iv_token_value7 => io_route_info_rec.input_date_ymd         -- ���͓��t
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
  END chk_is_new_recode;
--
  /**********************************************************************************
   * Procedure Name   : upd_route_info                                                               
   * Description      : ���[�g���f�[�^�̓o�^�y�эX�V (A-5)
   ***********************************************************************************/
  PROCEDURE upd_route_info(
    io_route_info_rec        IN OUT NOCOPY g_get_route_info_rtype,   -- ���[�g��񃏁[�N�e�[�u���f�[�^
    ov_errbuf                OUT NOCOPY VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT NOCOPY VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT NOCOPY VARCHAR2          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'upd_route_info';     -- �v���O������
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
    -- ���[�g���e�[�u���������[�J���ϐ��ɑ��
    cv_table_name          CONSTANT VARCHAR2(100) := '�g�D�v���t�@�C���g���e�[�u��';  -- �g�D�v���t�@�C���g���e�[�u��
    -- *** ���[�J���ϐ� ***
    lv_msg_code            VARCHAR2(100);                                             -- ���b�Z�[�W�R�[�h
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J���E��O ***
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
    -- ���ʊ֐��ɂ��A���[�g���e�[�u���̃f�[�^�X�V���s��
    xxcso_rtn_rsrc_pkg.regist_route_no(
                         iv_account_number => io_route_info_rec.account_number,          -- �ڋq�R�[�h
                         iv_route_no       => io_route_info_rec.route_no,                -- ���[�gNo
                         id_start_date     => TRUNC(io_route_info_rec.input_date,'MM'),  -- ���͓��t
                         ov_errbuf         => lv_errbuf,                             -- ���[�U�[�E�G���[�E���b�Z�[�W
                         ov_retcode        => lv_retcode,                            -- ���^�[���E�R�[�h 
                         ov_errmsg         => lv_errmsg                              -- �G���[�E���b�Z�[�W
                       );
--
    IF (lv_retcode <> cv_status_normal) THEN
      -- �G���[���b�Z�[�W�쐬
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                              -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_03                         -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_errmsg                            -- �g�[�N���R�[�h1
                     ,iv_token_value1 => SQLERRM                                  -- SQLERRM
                     ,iv_token_name2  => cv_tkn_tbl                               -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_table_name                            -- �G���[�����̃e�[�u����
                     ,iv_token_name3  => cv_tkn_sequence                          -- �g�[�N���R�[�h3
                     ,iv_token_value3 => io_route_info_rec.no_seq                 -- �V�[�P���X�ԍ�
                     ,iv_token_name4  => cv_tkn_cstm_cd                           -- �g�[�N���R�[�h4
                     ,iv_token_value4 => io_route_info_rec.account_number         -- �ڋq�R�[�h
                     ,iv_token_name5  => cv_tkn_cstm_nm                           -- �g�[�N���R�[�h5
                     ,iv_token_value5 => io_route_info_rec.account_name           -- �ڋq����
                     ,iv_token_name6  => cv_route_cd                              -- �g�[�N���R�[�h6
                     ,iv_token_value6 => io_route_info_rec.route_no               -- ���[�g�R�[�h
                     ,iv_token_name7  => cv_tkn_ym                                -- �g�[�N���R�[�h7
                     ,iv_token_value7 => io_route_info_rec.input_date_ymd         -- ���͓��t
                    );
      lv_errbuf  := lv_errmsg||SQLERRM;  
      RAISE ins_upd_expt;
    END IF;
--
  EXCEPTION
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
  END upd_route_info;
--
  /**********************************************************************************
   * Procedure Name   : del_wrk_tbl_data                                                                         
   * Description      : ���[�g��񃏁[�N�e�[�u���f�[�^�폜 (A-7)
   ***********************************************************************************/
  PROCEDURE del_wrk_tbl_data(
    ov_errbuf               OUT NOCOPY VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name              CONSTANT VARCHAR2(100)    := 'del_wrk_tbl_data';         -- �v���O������
    cv_table_name            CONSTANT VARCHAR2(100)    := '���[�g��񃏁[�N�e�[�u��'; -- ���[�g��񃏁[�N�e�[�u����
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf   VARCHAR2(5000);   -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1);      -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000);   -- ���[�U�[�E�G���[�E���b�Z�[�W
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
    -- *** ���[�J���E��O ***
    del_tbl_data_expt     EXCEPTION;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
    -- ***************************************************
    -- ***       ���[�g��񃏁[�N�e�[�u���f�[�^�폜        ***
    -- ***************************************************
    BEGIN
      DELETE
      FROM  xxcso_in_route_no;
--
    EXCEPTION
      -- *** OTHERS��O�n���h�� ***
      WHEN OTHERS THEN
        -- �G���[���b�Z�[�W�쐬
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_04              -- ���b�Z�[�W�R�[�h �f�[�^�폜�G���[
                       ,iv_token_name1  => cv_tkn_tbl                    -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_table_name                 -- �G���[�����̃e�[�u����
                       ,iv_token_name2  => cv_tkn_errmsg                 -- �g�[�N���R�[�h2
                       ,iv_token_value2 => SQLERRM                       -- ORACLE�G���[
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
    ln_sales_plan_cnt      NUMBER;                     -- ���ʔ���v��A�g�`�F�b�N�p�̃f�[�^����
    lb_not_exists_new_data BOOLEAN;                    -- �ŐV���R�[�h���݃`�F�b�N�t���O
    lv_msg_code            VARCHAR2(100);              -- ���b�Z�[�W�R�[�h
    lv_err_rec_info        VARCHAR2(5000);             -- �G���[�f�[�^�i�[�p
    lt_visit_target_div    xxcso_cust_accounts_v.vist_target_div%TYPE;    -- �K��Ώۋ敪
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR xirn_data_cur
    IS
      SELECT  xirn.no_seq  no_seq,                                    -- �V�[�P���X�ԍ�
              xirn.record_number record_number,                       -- ���R�[�h�ԍ�
              xirn.account_number account_number,                     -- �ڋq�R�[�h
              xirn.route_no route_no,                                 -- ���[�g�R�[�h
              xirn.input_date input_date,                             -- ���͓��t
              xirn.coalition_trance_date coalition_trance_date        -- �A�g������
      FROM   xxcso_in_route_no  xirn                                  -- ���[�g��񃏁[�N�e�[�u��
      ORDER BY xirn.no_seq;
--
    -- *** ���[�J���E���R�[�h ***
    l_xirn_data_rec      xirn_data_cur%ROWTYPE;
    l_get_data_rec       g_get_route_info_rtype;
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
    OPEN xirn_data_cur;
--
    <<get_data_loop>>
    LOOP
--
      BEGIN
        FETCH xirn_data_cur INTO l_xirn_data_rec;
        -- �����Ώی����i�[
        gn_target_cnt := xirn_data_cur%ROWCOUNT;
--
        EXIT WHEN xirn_data_cur%NOTFOUND
        OR  xirn_data_cur%ROWCOUNT = 0;
--
        -- ���R�[�h�ϐ�������
        l_get_data_rec := NULL;
--
        l_get_data_rec.no_seq                  := l_xirn_data_rec.no_seq;                -- �V�[�P���X�ԍ�
        l_get_data_rec.record_number           := l_xirn_data_rec.record_number;         -- ���R�[�h�ԍ�
        l_get_data_rec.account_number          := l_xirn_data_rec.account_number;        -- �ڋq�R�[�h
        l_get_data_rec.route_no                := l_xirn_data_rec.route_no;              -- ���[�gNO
        l_get_data_rec.input_date              := l_xirn_data_rec.input_date;            -- ���͓��t�iDATE�^�j
        l_get_data_rec.coalition_trance_date   := l_xirn_data_rec.coalition_trance_date; -- �A�g�������iDATE�^�j
        -- ���͓��t��VARCHAR2�^�ŕϊ�
        l_get_data_rec.input_date_ymd          := TO_CHAR(l_get_data_rec.input_date,'YYYYMMDD');
--      
        -- INPUT�f�[�^�̍��ڂ��J���}��؂�ŕ����A�����ă��O�ɏo�͂���p
        lv_err_rec_info := l_get_data_rec.no_seq||','
                        || l_get_data_rec.record_number  || ','
                        || l_get_data_rec.account_number || ','
                        || l_get_data_rec.route_no       || ','
                        || l_get_data_rec.input_date_ymd || ' ';
--
        -- ========================================
        -- A-3.�}�X�^���݃`�F�b�N 
        -- ========================================
        chk_mst_is_exists(
          io_route_info_rec        => l_get_data_rec,  -- ���[�g��񃏁[�N�e�[�u���f�[�^
          ov_errbuf                => lv_errbuf,       -- �G���[�E���b�Z�[�W            --# �Œ� #
          ov_retcode               => lv_retcode,      -- ���^�[���E�R�[�h              --# �Œ� #
          ov_errmsg                => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
        );
        -- �}�X�^���݃`�F�b�N�ŃG���[����������ꍇ�A���f�A�x���̏ꍇ�̓X�L�b�v����
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
          io_route_info_rec         => l_get_data_rec,              -- ���[�g��񃏁[�N�e�[�u���f�[�^
          ob_not_exists_new_data    => lb_not_exists_new_data,      -- �ŐV���R�[�h���݃`�F�b�N�t���O
          ov_errbuf                 => lv_errbuf,      -- �G���[�E���b�Z�[�W             --# �Œ� #
          ov_retcode                => lv_retcode,     -- ���^�[���E�R�[�h               --# �Œ� #
          ov_errmsg                 => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W   --# �Œ� #
        );
        -- �G���[����������ꍇ�͒��f�A�x���̏ꍇ�̓X�L�b�v�����A�ŐV���R�[�h�����݂���ꍇ�͐���X�L�b�v
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        ELSIF (lv_retcode = cv_status_warn) THEN
          RAISE error_skip_data_expt;
        ELSIF (lb_not_exists_new_data = cb_false) THEN
          RAISE skip_data_expt;
        END IF;
--
        -- �ŐV���R�[�h�����݂��Ȃ��i���Y���R�[�h���V�[�P���X�ԍ����傫�����R�[�h���Ȃ��j�ꍇ
        -- ========================================
        -- A-5.���[�g���e�[�u���f�[�^�o�^�y�эX�V 
        -- ========================================  
        upd_route_info(
          io_route_info_rec        => l_get_data_rec, -- ���[�g��񃏁[�N�e�[�u���f�[�^
          ov_errbuf                => lv_errbuf,      -- �G���[�E���b�Z�[�W            --# �Œ� #
          ov_retcode               => lv_retcode,     -- ���^�[���E�R�[�h              --# �Œ� #
          ov_errmsg                => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
        );
--
        -- ���[�g���f�[�^�o�^���X�V�ŃG���[����������ꍇ�͒��f�A�x���̏ꍇ�X�L�b�v
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        ELSIF (lv_retcode = cv_status_warn) THEN
          RAISE error_skip_data_expt;
        END IF;
--
        -- ========================
        -- A-6.�Z�[�u�|�C���g�ݒ�
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
    CLOSE xirn_data_cur;
--
    -- ========================================
    -- A-7.���[�g��񃏁[�N�e�[�u���f�[�^�폜����
    -- ========================================
    del_wrk_tbl_data(
      ov_errbuf           => lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode          => lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg           => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
-- 
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
      IF xirn_data_cur%ISOPEN THEN
        -- �J�[�\���N���[�Y
        CLOSE xirn_data_cur;
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
      IF xirn_data_cur%ISOPEN THEN
        -- �J�[�\���N���[�Y
        CLOSE xirn_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      gn_error_cnt := gn_error_cnt + 1;                           -- �G���[�����J�E���g
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF xirn_data_cur%ISOPEN THEN
        -- �J�[�\���N���[�Y
        CLOSE xirn_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
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
END XXCSO014A04C;
/
