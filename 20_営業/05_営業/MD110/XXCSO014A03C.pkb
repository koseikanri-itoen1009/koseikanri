CREATE OR REPLACE PACKAGE BODY APPS.XXCSO014A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO014A03C(body)
 * Description      : �K��̂ݏ����d�a�r�̃^�X�N���֓o�^���܂��B
 *                    
 * MD.050           : MD050_CSO_014_A03_�K��̂�
 *                    
 * Version          : 1.0
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                        Description
 * ---------------------------- ----------------------------------------------------------
 *  init                        ��������                                        (A-1)
 *  get_profile_info            �v���t�@�C���l�擾                              (A-2)
 *  open_csv_file               CSV�t�@�C���I�[�v��                             (A-3)
 *  file_format_check           �t�@�C���t�H�[�}�b�g�`�F�b�N                    (A-5)
 *  chk_mst_is_exists           �}�X�^���݃`�F�b�N                              (A-6)
 *  insert_visit_data           �K��̂ݏ��o�^����                            (A-7)
 *  close_csv_file              CSV�t�@�C���N���[�Y����                         (A-9)
 *  submain                     ���C�������v���V�[�W��(
 *                                CSV�t�@�C���f�[�^���o                         (A-4)
 *                                �Z�[�u�|�C���g�ݒ�                            (A-8)
 *                              )
 *  main                        �R���J�����g���s�t�@�C���o�^�v���V�[�W��(
 *                                �I������                                      (A-10)
 *                              )
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-1-8     1.0   Kenji.Sai        �V�K�쐬
 *  2009-05-01   1.1   Tomoko.Mori      T1_0897�Ή�
 *  2009-05-07   1.2   Tomoko.Mori      T1_0912�Ή�
 *
 *****************************************************************************************/
-- 
-- #######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal       CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn         CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --�x��:1
  cv_status_error        CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --�ُ�:2
--
  cv_msg_part            CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont            CONSTANT VARCHAR2(3) := '.';
--
-- #######################  �Œ�O���[�o���萔�錾�� END   #########################
--
-- #######################  �Œ�O���[�o���ϐ��錾�� START #########################
--
  gv_out_msg             VARCHAR2(2000);
  gn_target_cnt          NUMBER;                    -- �Ώی���
  gn_normal_cnt          NUMBER;                    -- ���팏��
  gn_error_cnt           NUMBER;                    -- �G���[����
--
-- #######################  �Œ�O���[�o���ϐ��錾�� END   #########################
--
-- #######################  �Œ苤�ʗ�O�錾�� START       #########################
--
  --*** ���������ʗ�O ***
  global_process_expt    EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt        EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
-- #######################  �Œ苤�ʗ�O�錾�� END         #########################
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCSO014A03C';      -- �p�b�P�[�W��
  cv_app_name            CONSTANT VARCHAR2(5)   := 'XXCSO';             -- �A�v���P�[�V�����Z�k��
--
  cv_comma               CONSTANT VARCHAR2(1)   := ',';
  cv_active_status       CONSTANT VARCHAR2(1)   := 'A';                 -- �A�N�e�B�u
  cv_enabled_flag        CONSTANT VARCHAR2(1)   := 'Y';                 -- �L��
  cv_enable_houmon_kubun CONSTANT VARCHAR2(1)   := '0';                 -- �L���K��敪�@�K��F0
  cv_insert_kubun        CONSTANT VARCHAR2(1)   := '1';                 -- �o�^�敪�@�K��̂݁iHHT�j�F1
  cv_false               CONSTANT VARCHAR2(10)  := 'FALSE';             -- FALSE
  cv_true                CONSTANT VARCHAR2(10)  := 'TRUE';              -- TRUE  
  cb_false               CONSTANT BOOLEAN       := FALSE;               -- FALSE
  cb_true                CONSTANT BOOLEAN       := TRUE;                -- TRUE  
  cv_r                   CONSTANT VARCHAR2(10)  := 'r';                 -- CSV�t�@�C���ǂݍ��݃t���O  
--
  -- ���b�Z�[�W�R�[�h
  cv_tkn_number_01       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00023';  -- �p�����[�^NULL�G���[
  cv_tkn_number_02       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00108';  -- CSV�t�@�C�����݃`�F�b�N�G���[
  cv_tkn_number_03       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00015';  -- CSV�t�@�C���I�[�v���G���[
  cv_tkn_number_04       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00247';  -- CSV�t�@�C�����o�G���[
  cv_tkn_number_05       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00014';  -- �v���t�@�C���擾�G���[
  cv_tkn_number_06       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00109';  -- �f�[�^���o�G���[
  cv_tkn_number_07       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00110';  -- �ڋq���݃`�F�b�N�G���[
  cv_tkn_number_08       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00111';  -- �c�ƈ��R�[�h���݃`�F�b�N�G���[
  cv_tkn_number_09       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00501';  -- �K����̒��ߓ����߃G���[
  cv_tkn_number_10       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00174';  -- �K��敪�R�[�h���݃`�F�b�N�G���[
  cv_tkn_number_11       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00112';  -- �f�[�^�ǉ��G���[
  cv_tkn_number_12       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00113';  -- �f�[�^���ڐ��`�F�b�N�G���[  
  cv_tkn_number_13       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00029';  -- DATE�^�`�F�b�N�G���[
  cv_tkn_number_14       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00114';  -- �K�{�`�F�b�N�G���[
  cv_tkn_number_15       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00015';  -- CSV�t�@�C���N���[�Y�G���[
  cv_tkn_number_16       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00152';  -- �p�����[�^�o�̓t�@�C����  
  cv_tkn_number_17       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00030';  -- �T�C�Y�`�F�b�N�G���[
--
  -- �g�[�N���R�[�h
  cv_tkn_prof_nm         CONSTANT VARCHAR2(20)  := 'PROF_NAME';
  cv_tkn_err_msg         CONSTANT VARCHAR2(20)  := 'ERR_MSG';
  cv_tkn_csv_loc         CONSTANT VARCHAR2(20)  := 'CSV_LOCATION';
  cv_tkn_csv_fnm         CONSTANT VARCHAR2(20)  := 'CSV_FILE_NAME';
  cv_tkn_base_val        CONSTANT VARCHAR2(20)  := 'BASE_VALUE';
  cv_tkn_item            CONSTANT VARCHAR2(20)  := 'ITEM';
  cv_tkn_cstm_cd         CONSTANT VARCHAR2(20)  := 'CUSTOMERCODE';
  cv_tkn_cstm_nm         CONSTANT VARCHAR2(20)  := 'CUSTOMERNAME';
  cv_tkn_sales_cd        CONSTANT VARCHAR2(20)  := 'SALESCODE';
  cv_tkn_sales_nm        CONSTANT VARCHAR2(20)  := 'SALESNAME';
  cv_date_time           CONSTANT VARCHAR2(20)  := 'DATETIME';
  cv_lookup_cd           CONSTANT VARCHAR2(20)  := 'LOOKUP_CODE';
  cv_tkn_tbl             CONSTANT VARCHAR2(20)  := 'TABLE';  
  cv_tkn_cnt             CONSTANT VARCHAR2(20)  := 'COUNT';
--
  -- DEBUG_LOG�p���b�Z�[�W
  cv_debug_msg1           CONSTANT VARCHAR2(200) := '<< �v���t�@�C���l�擾���� >>';
  cv_debug_msg2           CONSTANT VARCHAR2(200) := 'csv_dir               = ';
  cv_debug_msg3           CONSTANT VARCHAR2(200) := 'task_type             = ';
  cv_debug_msg4           CONSTANT VARCHAR2(200) := 'task_status_closed_id = ';
  cv_debug_msg7           CONSTANT VARCHAR2(200) := '���[���o�b�N���܂����B';    
  cv_debug_msg8           CONSTANT VARCHAR2(200) := '�Z�[�u�|�C���g�փ��[���o�b�N���܂����B';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �s�P�ʃf�[�^���i�[����z��
  TYPE g_col_data_ttype IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER;
  -- �K��敪�R�[�h�e�[�u��
  TYPE g_houmon_kubun_cd_ttype IS TABLE OF VARCHAR2(10) INDEX BY BINARY_INTEGER;
  -- �K����уf�[�^���֘A��񒊏o�f�[�^
  TYPE g_visit_data_rtype IS RECORD(
    account_number       hz_cust_accounts.account_number%TYPE,     -- �ڋq�R�[�h
    employee_number      xxcso_resources_v.employee_number%TYPE,   -- �c�ƈ��R�[�h
    dff1_cd              fnd_lookup_values_vl.lookup_code%TYPE,    -- �K��敪�R�[�h�P
    dff2_cd              fnd_lookup_values_vl.lookup_code%TYPE,    -- �K��敪�R�[�h�Q
    dff3_cd              fnd_lookup_values_vl.lookup_code%TYPE,    -- �K��敪�R�[�h�R
    dff4_cd              fnd_lookup_values_vl.lookup_code%TYPE,    -- �K��敪�R�[�h�S
    dff5_cd              fnd_lookup_values_vl.lookup_code%TYPE,    -- �K��敪�R�[�h�T
    description          jtf_tasks_tl.description%TYPE,            -- �ڍד��e
    visit_date           VARCHAR2(8),                              -- �K���    YYYYMMDD
    visit_time           VARCHAR2(4),                              -- �K�⎞��  HH24MI
    visit_datetime       DATE,                                     -- �K�����  DATE
    resource_id          jtf_rs_resource_extns.resource_id%TYPE,   -- ���\�[�XID
    party_id             hz_parties.party_id%TYPE,                 -- �p�[�e�BID
    party_name           hz_parties.party_name%TYPE,               -- �p�[�e�B����
    account_name         hz_cust_accounts.account_name%TYPE,       -- �ڋq����
    employee_name        xxcso_resources_v.full_name%TYPE,         -- �c�ƈ�����
    customer_status      hz_parties.duns_number_c%TYPE             -- �ڋq�X�e�[�^�X
  );
  -- *** ���[�U�[��`�O���[�o����O ***
  global_skip_error_expt EXCEPTION;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- �t�@�C���E�n���h���̐錾
  gf_file_hand    UTL_FILE.FILE_TYPE;
--
  gv_houmon_csv_file_nm  VARCHAR2(1000);                           -- �K��CSV�t�@�C����
  gv_hht_in_csv_dir      VARCHAR2(1000);                           -- HHT�A�g�pCSV�t�@�C���擾��
  gv_hht_task_type       VARCHAR2(100);                            -- �^�X�N�^�C�v
  gv_task_status_close   VARCHAR2(100);                            -- �^�X�N�X�e�[�^�X
--
  g_visit_data_rec               g_visit_data_rtype;               -- CSV�t�@�C�����璊�o���ꂽ�����f�[�^
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : �������� (A-1)
   ***********************************************************************************/
--
  PROCEDURE init(
     iv_file_name         IN         VARCHAR2   -- �t�@�C����
    ,ov_errbuf            OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W            -- # �Œ� #
    ,ov_retcode           OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h              -- # �Œ� #
    ,ov_errmsg            OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
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
--
    -- *** ���[�J���ϐ� ***
    lv_prm_msg    VARCHAR2(5000);  -- ���̓p�����[�^���b�Z�[�W�i�[�p
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
    -- �p�����[�^�l�o�� 
    -- =======================================
    lv_prm_msg   := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_16             -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_csv_fnm               -- �g�[�N���R�[�h1
                      ,iv_token_value1 => iv_file_name                 -- �g�[�N���l1
                    );
    -- ���b�Z�[�W�o��
    fnd_file.put_line(
      which  => FND_FILE.OUTPUT,
      buff   => ''         || CHR(10) ||     -- ��s�̑}��
                lv_prm_msg || CHR(10) ||
                 ''                          -- ��s�̑}��
    );
--
    -- CSV�t�@�C����NULL�̏ꍇ
    IF (iv_file_name IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_01             -- ���b�Z�[�W�R�[�h
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    g_visit_data_rec := NULL;
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
   * Procedure Name   : get_profile_info
   * Description      : �v���t�@�C���l�擾 (A-2)
   ***********************************************************************************/
--
  PROCEDURE get_profile_info(
     ov_errbuf           OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W            -- # �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h              -- # �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100) := 'get_profile_info';  -- �v���O������
--
-- #######################  �Œ胍�[�J���ϐ��錾�� START   ######################
--
    lv_errbuf            VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode           VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg            VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
-- ###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- �v���t�@�C���� (XXCSO: HHT�A�g�pCSV�t�@�C���擾��iXXCSO1_HHT_IN_CSV_DIR�j)
    cv_prfnm_hht_in_csv_dir          CONSTANT VARCHAR2(30)   := 'XXCSO1_HHT_IN_CSV_DIR';
    -- �v���t�@�C���� (XXCSO: �^�X�N�^�C�v�i�^�X�N�o�^���̐ݒ�l�j�iXXCSO1_HHT_TASK_TYPE�j)
    cv_prfnm_hht_task_type           CONSTANT VARCHAR2(30)   := 'XXCSO1_HHT_TASK_TYPE';
    -- �v���t�@�C���� (XXCSO: �^�X�N�X�e�[�^�X�i�N���[�Y�j�iXXCSO1_TASK_STATUS_CLOSED_ID�j)
    cv_prfnm_task_status_closed_id   CONSTANT VARCHAR2(30)   := 'XXCSO1_TASK_STATUS_CLOSED_ID';    
--
    -- *** ���[�J���ϐ� ***
    -- �v���t�@�C���l�擾���s�� �g�[�N���l�i�[�p
    lv_tkn_value                VARCHAR2(1000);
    -- �擾�f�[�^���b�Z�[�W�o�͗p
    lv_msg                      VARCHAR2(4000);
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- =======================
    -- �ϐ����������� 
    -- =======================
    lv_tkn_value := NULL;
--
    -- =======================
    -- �v���t�@�C���l�擾���� 
    -- =======================
    FND_PROFILE.GET(
                    name => cv_prfnm_hht_in_csv_dir
                   ,val  => gv_hht_in_csv_dir
                   ); -- HHT�A�g�pCSV�t�@�C���擾��
    FND_PROFILE.GET(
                    name => cv_prfnm_hht_task_type
                   ,val  => gv_hht_task_type
                   ); -- �^�X�N�^�C�v
    FND_PROFILE.GET(
                    name => cv_prfnm_task_status_closed_id
                   ,val  => gv_task_status_close
                   ); -- �^�X�N�X�e�[�^�X
    -- *** DEBUG_LOG ***
    -- �擾�����v���t�@�C���l�����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg1  || CHR(10) ||
                 cv_debug_msg2  || gv_hht_in_csv_dir    || CHR(10) ||
                 cv_debug_msg3  || gv_hht_task_type     || CHR(10) ||
                 cv_debug_msg4 || gv_task_status_close || CHR(10) ||
                 ''
    );
--
    -- �v���t�@�C���l�擾�Ɏ��s�����ꍇ
    -- HHT�A�g�pCSV�t�@�C���擾��擾���s��
    IF (gv_hht_in_csv_dir IS NULL) THEN
      lv_tkn_value := cv_prfnm_hht_in_csv_dir;
    -- �^�X�N�^�C�v�擾���s��
    ELSIF (gv_hht_task_type IS NULL) THEN
      lv_tkn_value := cv_prfnm_hht_task_type;
    -- �^�X�N�X�e�[�^�X�擾���s��
    ELSIF (gv_task_status_close IS NULL) THEN
      lv_tkn_value := cv_prfnm_task_status_closed_id;
    END IF;
    -- �G���[���b�Z�[�W�擾
    IF (lv_tkn_value) IS NOT NULL THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_05             --���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_prof_nm               --�g�[�N���R�[�h1
                    ,iv_token_value1 => lv_tkn_value                 --�g�[�N���l1
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
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
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
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
  END get_profile_info;
--
--
  /**********************************************************************************
   * Procedure Name   : open_csv_file
   * Description      : CSV�t�@�C���I�[�v�� (A-3)
   ***********************************************************************************/
  PROCEDURE open_csv_file(
     ov_errbuf         OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode        OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg         OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'open_csv_file';  -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_w            CONSTANT VARCHAR2(1) := 'r';
--
    -- *** ���[�J���ϐ� ***
    -- �t�@�C�����݃`�F�b�N�߂�l�p
    lb_retcd        BOOLEAN;
    ln_file_size    NUMBER;
    ln_block_size   NUMBER;
    -- �t�@�C���I�[�v���m�F�߂�l�i�[
    lb_fopn_retcd   BOOLEAN;
    -- *** ���[�J����O ***
    file_err_expt   EXCEPTION;  -- �t�@�C��������O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ========================
    -- CSV�t�@�C�����݃`�F�b�N 
    -- ========================
    UTL_FILE.FGETATTR(
       location    => gv_hht_in_csv_dir                -- CSV�t�@�C���擾��
      ,filename    => gv_houmon_csv_file_nm            -- CSV�t�@�C����
      ,fexists     => lb_retcd                         -- �߂�l
      ,file_length => ln_file_size                     -- �t�@�C���T�C�Y
      ,block_size  => ln_block_size                    -- �t�@�C���u���b�N�̃T�C�Y
    );
--
    -- �t�@�C�������݂��Ȃ��ꍇ
    IF (lb_retcd = cb_false) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_02             --���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_csv_loc               --�g�[�N���R�[�h1
                    ,iv_token_value1 => gv_hht_in_csv_dir            --�g�[�N���l1
                    ,iv_token_name2  => cv_tkn_csv_fnm               --�g�[�N���R�[�h2
                    ,iv_token_value2 => gv_houmon_csv_file_nm        --�g�[�N���l2
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE file_err_expt;
    END IF;
--
    -- ========================
    -- CSV�t�@�C���I�[�v�� 
    -- ========================
    BEGIN
      -- �t�@�C���I�[�v��
      gf_file_hand := UTL_FILE.FOPEN(
                         location   => gv_hht_in_csv_dir
                        ,filename   => gv_houmon_csv_file_nm
                        ,open_mode  => cv_r
                      );
--
    EXCEPTION
      WHEN UTL_FILE.INVALID_PATH       OR       -- �t�@�C���p�X�s���G���[
           UTL_FILE.INVALID_MODE       OR       -- open_mode�p�����[�^�s���G���[
           UTL_FILE.INVALID_OPERATION  OR       -- �I�[�v���s�\�G���[
           UTL_FILE.INVALID_MAXLINESIZE  THEN   -- MAX_LINESIZE�l�����G���[
        -- �G���[���b�Z�[�W�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name            --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_03       --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_csv_loc         --�g�[�N���R�[�h1
                      ,iv_token_value1 => gv_hht_in_csv_dir      --�g�[�N���l1
                      ,iv_token_name2  => cv_tkn_csv_fnm         --�g�[�N���R�[�h1
                      ,iv_token_value2 => gv_houmon_csv_file_nm  --�g�[�N���l1
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE file_err_expt;
    END;
  EXCEPTION
    -- *** �t�@�C��������O�n���h�� ***
    WHEN file_err_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file => gf_file_hand
        );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END open_csv_file;
--
  /**********************************************************************************
   * Procedure Name   : file_format_check           
   * Description      : �t�@�C���t�H�[�}�b�g�`�F�b�N (A-5)
   ***********************************************************************************/
--
  PROCEDURE file_format_check(
     iv_base_value       IN  VARCHAR2                -- ���Y�s�f�[�^
    ,ov_errbuf           OUT NOCOPY VARCHAR2         -- �G���[�E���b�Z�[�W           -- # �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2         -- ���^�[���E�R�[�h             -- # �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W -- # �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'file_format_check';       -- �v���O������
--
-- #####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf   VARCHAR2(5000);   -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1);      -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000);   -- ���[�U�[�E�G���[�E���b�Z�[�W
--
-- ###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_format_col_cnt       CONSTANT NUMBER        := 9;                    -- ���ڐ�
    cv_account_number_len   CONSTANT NUMBER        := 9;                    -- �ڋq�R�[�h�o�C�g��
    cv_employee_number_len  CONSTANT NUMBER        := 5;                    -- �c�ƈ��R�[�h�o�C�g��
    cv_houmon_kubun_len     CONSTANT NUMBER        := 2;                    -- �K��敪�o�C�g��
    cv_description_cut_len  CONSTANT NUMBER        := 2000;                 -- �ڍד��e�͈�
    cv_visit_date_len       CONSTANT NUMBER        := 8;                    -- �K���
    cv_visit_time_len       CONSTANT NUMBER        := 4;                    -- �K�⎞��
    cv_visit_date_fmt       CONSTANT VARCHAR2(100) := 'YYYYMMDDHH24MI';     -- DATE�^
    /*20090507_mori_T1_0912 START*/
    cv_blank                CONSTANT VARCHAR2(1)   := ' ';                  -- ��
    /*20090507_mori_T1_0912 END*/
--
    -- *** ���[�J���ϐ� ***
    l_col_data_tab          g_col_data_ttype;       -- �����㍀�ڃf�[�^���i�[����z��
    lv_item_nm              VARCHAR2(100);         -- �Y�����ږ�
    lv_visit_date           VARCHAR2(100);         -- �K�����
    lb_return               BOOLEAN;               -- ���^�[���X�e�[�^�X
--
    loop_cnt                NUMBER;
    lv_tmp                  VARCHAR2(2000);
    ln_pos                  NUMBER;
    ln_cnt                  NUMBER  := 1;
    lb_format_flag          BOOLEAN := TRUE;
--
  BEGIN
--
-- ##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
-- ###########################  �Œ蕔 END   ############################
--
    -- ���o�f�[�^���R�[�h�ϐ�������
    g_visit_data_rec := NULL;
    -- ���ڐ����擾
    IF (iv_base_value IS NULL) THEN
      lb_format_flag := FALSE;
    END IF;
--
    IF lb_format_flag THEN
      lv_tmp := iv_base_value;
      LOOP
        ln_pos := INSTR(lv_tmp, cv_comma);
        IF ((ln_pos IS NULL) OR (ln_pos = 0)) THEN
          EXIT;
        ELSE
          ln_cnt := ln_cnt + 1;
          lv_tmp := SUBSTR(lv_tmp, ln_pos + 1);
          ln_pos := 0;
        END IF;
      END LOOP;
    END IF;
--
    -- 1.���ڐ��`�F�b�N
    IF ((lb_format_flag = FALSE) OR (ln_cnt <> cv_format_col_cnt)) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_base_val              -- �g�[�N���R�[�h1
                       ,iv_token_value1 => iv_base_value                -- �g�[�N���l1
                     );
        lv_errbuf  := lv_errmsg;
        RAISE global_skip_error_expt;
--
    -- 2.�f�[�^�^�i���p�����^���t�j�̃`�F�b�N�A�T�C�Y�`�F�b�N
    ELSE
--
      -- ���ʊ֐��ɂ���ĕ����������ڃf�[�^�擾
      <<delim_partition_loop>>
      FOR loop_cnt IN 1..9 LOOP
        l_col_data_tab(loop_cnt) := TRIM(
                                      REPLACE(xxccp_common_pkg.char_delim_partition(iv_base_value, cv_comma, loop_cnt)
                                                , '"', '')
                                     );
      END LOOP delim_partition_loop;
--
      lb_return  := TRUE;
      lv_item_nm := '';
--
      -- 1). �K�{�`�F�b�N
      IF l_col_data_tab(1) IS NULL THEN
        lb_return  := FALSE;
        lv_item_nm := '�ڋq�R�[�h';
      ELSIF l_col_data_tab(2) IS NULL THEN
        lb_return  := FALSE;
        lv_item_nm := '�c�ƈ��R�[�h';
      ELSIF l_col_data_tab(8) IS NULL THEN
        lb_return  := FALSE;
        lv_item_nm := '�K���';
      ELSIF l_col_data_tab(9) IS NULL THEN
        lb_return  := FALSE;
        lv_item_nm := '�K�⎞��';
      END IF;
--
      IF (lb_return = FALSE) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_14             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_item                  -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_item_nm                   -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_base_val              -- �g�[�N���R�[�h2
                       ,iv_token_value2 => iv_base_value                -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_skip_error_expt;
      END IF;
--
      -- 2). ���t�����`�F�b�N
      -- �K�����
      lv_visit_date := TO_CHAR(l_col_data_tab(8)) || l_col_data_tab(9);
--
      lb_return := xxcso_util_common_pkg.check_date(lv_visit_date, cv_visit_date_fmt);
      IF (lb_return = FALSE) THEN
        lv_item_nm := '�K�����';
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_13             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_item                  -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_item_nm                   -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_base_val              -- �g�[�N���R�[�h2
                       ,iv_token_value2 => iv_base_value                -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_skip_error_expt;
      END IF;
--
      -- 3). �T�C�Y�`�F�b�N
      /*20090507_mori_T1_0912 START*/
      -- �������p�X�y�[�X�폜
      l_col_data_tab(3)         := TRIM(cv_blank from l_col_data_tab(3));             -- �K��敪1
      l_col_data_tab(4)         := TRIM(cv_blank from l_col_data_tab(4));             -- �K��敪2
      l_col_data_tab(5)         := TRIM(cv_blank from l_col_data_tab(5));             -- �K��敪3
      l_col_data_tab(6)         := TRIM(cv_blank from l_col_data_tab(6));             -- �K��敪4
      l_col_data_tab(7)         := TRIM(cv_blank from l_col_data_tab(7));             -- �K��敪5
      /*20090507_mori_T1_0912 END*/
      IF (LENGTHB(l_col_data_tab(1)) <> cv_account_number_len) THEN
        lb_return  := FALSE;
        lv_item_nm := '�ڋq�R�[�h';
      ELSIF (LENGTHB(l_col_data_tab(2)) <> cv_employee_number_len) THEN
        lb_return  := FALSE;
        lv_item_nm := '�c�ƈ��R�[�h';
      ELSIF (l_col_data_tab(3) IS NOT NULL)
        AND (LENGTHB(l_col_data_tab(3)) <> cv_houmon_kubun_len) THEN
        lb_return  := FALSE;
        lv_item_nm := '�K��敪�P';
      ELSIF (l_col_data_tab(4) IS NOT NULL)
        AND (LENGTHB(l_col_data_tab(4)) <> cv_houmon_kubun_len) THEN
        lb_return  := FALSE;
        lv_item_nm := '�K��敪�Q';
      ELSIF (l_col_data_tab(5) IS NOT NULL)
        AND (LENGTHB(l_col_data_tab(5)) <> cv_houmon_kubun_len) THEN
        lb_return  := FALSE;
        lv_item_nm := '�K��敪�R';
      ELSIF (l_col_data_tab(6) IS NOT NULL)
        AND (LENGTHB(l_col_data_tab(6)) <> cv_houmon_kubun_len) THEN
        lb_return  := FALSE;
        lv_item_nm := '�K��敪�S';
      ELSIF (l_col_data_tab(7) IS NOT NULL)
        AND (LENGTHB(l_col_data_tab(7)) <> cv_houmon_kubun_len) THEN
        lb_return  := FALSE;
        lv_item_nm := '�K��敪�T';
      ELSIF (LENGTHB(l_col_data_tab(9)) <> cv_visit_time_len) THEN
        lb_return  := FALSE;
        lv_item_nm := '�K�⎞��';
      END IF;
--
      IF (lb_return = FALSE) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_17             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_item                  -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_item_nm                   -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_base_val              -- �g�[�N���R�[�h2
                       ,iv_token_value2 => iv_base_value                -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_skip_error_expt;
      END IF;
    END IF;
    -- �`�F�b�N�ς݂̕����f�[�^���O���[�o���ϐ��ɃZ�b�g
    g_visit_data_rec.account_number  := l_col_data_tab(1);             -- �ڋq�R�[�h
    g_visit_data_rec.employee_number := l_col_data_tab(2);             -- �c�ƈ��R�[�h
    g_visit_data_rec.dff1_cd         := l_col_data_tab(3);             -- �K��敪1
    g_visit_data_rec.dff2_cd         := l_col_data_tab(4);             -- �K��敪2
    g_visit_data_rec.dff3_cd         := l_col_data_tab(5);             -- �K��敪3
    g_visit_data_rec.dff4_cd         := l_col_data_tab(6);             -- �K��敪4
    g_visit_data_rec.dff5_cd         := l_col_data_tab(7);             -- �K��敪5
    g_visit_data_rec.visit_date      := TO_CHAR(l_col_data_tab(8));    -- �K���     
    g_visit_data_rec.visit_time      := l_col_data_tab(9);             -- �K�⎞��
    g_visit_data_rec.visit_datetime  := TO_DATE(g_visit_data_rec.visit_date||g_visit_data_rec.visit_time
                                                , cv_visit_date_fmt);
--
  EXCEPTION
    -- *** �X�L�b�v��O�n���h�� ***
    WHEN global_skip_error_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END file_format_check;
--
  /**********************************************************************************
   * Procedure Name   : chk_mst_is_exists
   * Description      : �}�X�^���݃`�F�b�N (A-6)
   ***********************************************************************************/
--
  PROCEDURE chk_mst_is_exists(
     ov_errbuf           OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W            -- # �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h              -- # �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100) := 'chk_mst_is_exists';  -- �v���O������
--
-- #######################  �Œ胍�[�J���ϐ��錾�� START   ######################
--
    lv_errbuf            VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode           VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg            VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
-- ###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_lookup_type            CONSTANT VARCHAR2(100) := 'XXCSO_ASN_HOUMON_KUBUN';
    cv_flag_y                 CONSTANT VARCHAR2(1)   := 'Y';
    cv_resource_table_nm      CONSTANT VARCHAR2(100) := '���\�[�X�}�X�^�r���[';
    cv_account_table_vl_nm    CONSTANT VARCHAR2(100) := '�ڋq�}�X�^�r���[';
    cv_lookup_table_nm        CONSTANT VARCHAR2(100) := '�Q�ƃ^�C�v�e�[�u��';
    cv_false                  CONSTANT VARCHAR2(100) := 'FALSE';
    -- *** ���[�J���ϐ� ***
    lv_lookup_cd              VARCHAR2(10);            -- �K��敪�R�[�h
    lv_lookup_cd_tab          g_houmon_kubun_cd_ttype; -- �K��敪�R�[�h��ێ�����PLSQL�\
    ld_visite_date            DATE;                    -- �K�����
    lv_houmon_kubun           VARCHAR2(10);            -- �K��敪
    loop_cnt                  NUMBER;

    lv_gl_period_statuses     VARCHAR2(100); -- �u�K������v�ɊY������Ώۂ̉�v���Ԃ��N���[�Y

--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- *** 1. �ڋq�R�[�h�̃}�X�^���݃`�F�b�N *** --
    BEGIN
--
      -- *** 1. �p�[�e�BID�A�p�[�e�B���̂ƌڋq�X�e�[�^�X�𒊏o *** --
      SELECT xcav.party_id party_id                 -- �p�[�e�BID
            ,xcav.party_name party_name             -- �p�[�e�B����
            ,xcav.account_name account_name         -- �ڋq����
            ,xcav.customer_status customer_status   -- �ڋq�X�e�[�^�X
      INTO   g_visit_data_rec.party_id              -- �p�[�e�BID
            ,g_visit_data_rec.party_name            -- �p�[�e�B����
            ,g_visit_data_rec.account_name          -- �ڋq����
            ,g_visit_data_rec.customer_status       -- �ڋq�X�e�[�^�X
      FROM   xxcso_cust_accounts_v xcav             -- �ڋq�}�X�^�r���[
      WHERE  xcav.account_number = g_visit_data_rec.account_number
        AND  xcav.account_status = cv_active_status
        AND  xcav.party_status   = cv_active_status;
--
    EXCEPTION
      -- ���o������0���̏ꍇ
      WHEN NO_DATA_FOUND THEN
--
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                      -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_07                 -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tbl                       -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_account_table_vl_nm           -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_cstm_cd                   -- �g�[�N���R�[�h2
                       ,iv_token_value2 => g_visit_data_rec.account_number  -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_cstm_nm                   -- �g�[�N���R�[�h3
                       ,iv_token_value3 => g_visit_data_rec.account_name    -- �g�[�N���l3                       
                       ,iv_token_name4  => cv_tkn_sales_cd                  -- �g�[�N���R�[�h4
                       ,iv_token_value4 => g_visit_data_rec.employee_number -- �g�[�N���l4
                       ,iv_token_name5  => cv_tkn_sales_nm                  -- �g�[�N���R�[�h5
                       ,iv_token_value5 => g_visit_data_rec.employee_name   -- �g�[�N���l5                       
                       ,iv_token_name6  => cv_date_time                     -- �g�[�N���R�[�h6
                       ,iv_token_value6 => g_visit_data_rec.visit_date || g_visit_data_rec.visit_time
                         -- �g�[�N���l6
                     );
        lv_errbuf := lv_errmsg||SQLERRM;
        RAISE global_skip_error_expt;
--
      -- ���o�Ɏ��s�����ꍇ�̌㏈��
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                      -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_06                 -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tbl                       -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_account_table_vl_nm           -- �g�[�N���l1                       
                       ,iv_token_name2  => cv_tkn_err_msg                   -- �g�[�N���R�[�h2
                       ,iv_token_value2 => SQLERRM                          -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_cstm_cd                   -- �g�[�N���R�[�h3
                       ,iv_token_value3 => g_visit_data_rec.account_number  -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_cstm_nm                   -- �g�[�N���R�[�h4
                       ,iv_token_value4 => g_visit_data_rec.account_name    -- �g�[�N���l4                       
                       ,iv_token_name5  => cv_tkn_sales_cd                  -- �g�[�N���R�[�h5
                       ,iv_token_value5 => g_visit_data_rec.employee_number -- �g�[�N���l5
                       ,iv_token_name6  => cv_tkn_sales_nm                  -- �g�[�N���R�[�h6
                       ,iv_token_value6 => g_visit_data_rec.employee_name   -- �g�[�N���l6                       
                       ,iv_token_name7  => cv_date_time                     -- �g�[�N���R�[�h7
                       ,iv_token_value7 => g_visit_data_rec.visit_date || g_visit_data_rec.visit_time
                         -- �g�[�N���l7
                     );
        lv_errbuf := lv_errmsg||SQLERRM;
        RAISE global_skip_error_expt;
    END;
--
    -- *** 2. �c�ƈ��R�[�h�̃}�X�^���݃`�F�b�N *** --
--
    ld_visite_date := TRUNC(g_visit_data_rec.visit_datetime);
--
    BEGIN
      -- *** ���\�[�X�}�X�^�r���[���烊�\�[�XID�𒊏o *** --
      SELECT xrv.resource_id resource_id         -- ���\�[�XID
            ,xrv.full_name employee_name         -- �c�ƈ�����
      INTO   g_visit_data_rec.resource_id        -- ���\�[�XID
            ,g_visit_data_rec.employee_name      -- �c�ƈ�����
      FROM   xxcso_resources_v xrv               -- ���\�[�X�}�X�^�r���[
      WHERE  xrv.employee_number = g_visit_data_rec.employee_number
        AND ld_visite_date BETWEEN TRUNC(xrv.employee_start_date) 
          AND TRUNC(NVL(xrv.employee_end_date, ld_visite_date))
        AND ld_visite_date BETWEEN TRUNC(xrv.resource_start_date)
          AND TRUNC(NVL(xrv.resource_end_date, ld_visite_date))
        AND ld_visite_date BETWEEN TRUNC(xrv.assign_start_date)
          AND TRUNC(NVL(xrv.assign_end_date, ld_visite_date))
        AND ld_visite_date BETWEEN TRUNC(xrv.start_date)
          AND TRUNC(NVL(xrv.end_date, ld_visite_date));
--
    EXCEPTION
      -- ���o������0���̏ꍇ
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                      -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_08                 -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tbl                       -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_resource_table_nm             -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_cstm_cd                   -- �g�[�N���R�[�h2
                       ,iv_token_value2 => g_visit_data_rec.account_number  -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_cstm_nm                   -- �g�[�N���R�[�h3
                       ,iv_token_value3 => g_visit_data_rec.account_name    -- �g�[�N���l3                       
                       ,iv_token_name4  => cv_tkn_sales_cd                  -- �g�[�N���R�[�h4
                       ,iv_token_value4 => g_visit_data_rec.employee_number -- �g�[�N���l4
                       ,iv_token_name5  => cv_tkn_sales_nm                  -- �g�[�N���R�[�h5
                       ,iv_token_value5 => g_visit_data_rec.employee_name   -- �g�[�N���l5                       
                       ,iv_token_name6  => cv_date_time                     -- �g�[�N���R�[�h6
                       ,iv_token_value6 => g_visit_data_rec.visit_date || g_visit_data_rec.visit_time
                         -- �g�[�N���l6
                     );
          lv_errbuf := lv_errmsg;
          RAISE global_skip_error_expt;
      -- ���o�Ɏ��s�����ꍇ
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                      -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_06                 -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tbl                       -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_resource_table_nm             -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_err_msg                   -- �g�[�N���R�[�h2
                       ,iv_token_value2 => SQLERRM                          -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_cstm_cd                   -- �g�[�N���R�[�h3
                       ,iv_token_value3 => g_visit_data_rec.account_number  -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_cstm_nm                   -- �g�[�N���R�[�h4
                       ,iv_token_value4 => g_visit_data_rec.account_name    -- �g�[�N���l4                       
                       ,iv_token_name5  => cv_tkn_sales_cd                  -- �g�[�N���R�[�h5
                       ,iv_token_value5 => g_visit_data_rec.employee_number -- �g�[�N���l5
                       ,iv_token_name6  => cv_tkn_sales_nm                  -- �g�[�N���R�[�h6
                       ,iv_token_value6 => g_visit_data_rec.employee_name   -- �g�[�N���l6                       
                       ,iv_token_name7  => cv_date_time                     -- �g�[�N���R�[�h7
                       ,iv_token_value7 => g_visit_data_rec.visit_date || g_visit_data_rec.visit_time
                         -- �g�[�N���l7
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_skip_error_expt;
    END;
--
    -- *** 3. �Q�ƃ^�C�v�e�[�u������K��敪�R�[�h�̑��݃`�F�b�N *** --
    -- CSV���o�f�[�^�̖K��敪��PLSQL�\�ɃZ�b�g
    lv_lookup_cd_tab(1)  := g_visit_data_rec.dff1_cd;  -- �K��敪�R�[�h�P
    lv_lookup_cd_tab(2)  := g_visit_data_rec.dff2_cd;  -- �K��敪�R�[�h�Q
    lv_lookup_cd_tab(3)  := g_visit_data_rec.dff3_cd;  -- �K��敪�R�[�h�R
    lv_lookup_cd_tab(4)  := g_visit_data_rec.dff4_cd;  -- �K��敪�R�[�h�S
    lv_lookup_cd_tab(5)  := g_visit_data_rec.dff5_cd;  -- �K��敪�R�[�h�T    
--
    BEGIN
      -- �K��敪�R�[�h��NULL�ł͂Ȃ��ꍇ�A�Q�ƃR�[�h�e�[�u���ɊY���K��敪�R�[�h�����݂��邩���`�F�b�N
      <<lookup_code_loop>>
      FOR loop_cnt IN 1..5 LOOP
        IF lv_lookup_cd_tab(loop_cnt) IS NOT NULL THEN
          lv_lookup_cd := lv_lookup_cd_tab(loop_cnt);
          SELECT   flvv.lookup_code       houmon_kubun              -- �K��敪
          INTO     lv_houmon_kubun                                  -- �K��敪
          FROM     fnd_lookup_values_vl   flvv                      -- �Q�ƃR�[�h�e�[�u��
          WHERE    flvv.lookup_type                 = cv_lookup_type
            AND    ld_visite_date BETWEEN NVL(flvv.start_date_active, ld_visite_date) 
              AND  NVL(flvv.end_date_active, ld_visite_date)
            AND    flvv.enabled_flag                = cv_flag_y
            AND    flvv.attribute2                  = cv_flag_y
            AND    flvv.lookup_code                 = lv_lookup_cd;
        END IF;
      END LOOP lookup_code_loop;
--
    EXCEPTION
      -- ���o������0���̏ꍇ
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                      -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_10                 -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tbl                       -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_lookup_table_nm               -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_cstm_cd                   -- �g�[�N���R�[�h2
                       ,iv_token_value2 => g_visit_data_rec.account_number  -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_cstm_nm                   -- �g�[�N���R�[�h3
                       ,iv_token_value3 => g_visit_data_rec.account_name    -- �g�[�N���l3                       
                       ,iv_token_name4  => cv_tkn_sales_cd                  -- �g�[�N���R�[�h4
                       ,iv_token_value4 => g_visit_data_rec.employee_number -- �g�[�N���l4
                       ,iv_token_name5  => cv_tkn_sales_nm                  -- �g�[�N���R�[�h5
                       ,iv_token_value5 => g_visit_data_rec.employee_name   -- �g�[�N���l5                       
                       ,iv_token_name6  => cv_date_time                     -- �g�[�N���R�[�h6
                       ,iv_token_value6 => g_visit_data_rec.visit_date || g_visit_data_rec.visit_time
                         -- �g�[�N���l6
                       ,iv_token_name7  => cv_lookup_cd                     -- �g�[�N���R�[�h7
                       ,iv_token_value7 => lv_lookup_cd                     -- �g�[�N���l7 
                     );
          lv_errbuf := lv_errmsg||SQLERRM;
          RAISE global_skip_error_expt;
      -- ���o�Ɏ��s�����ꍇ
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                      -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_06                 -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tbl                       -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_lookup_table_nm               -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_err_msg                   -- �g�[�N���R�[�h2
                       ,iv_token_value2 => SQLERRM                          -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_cstm_cd                   -- �g�[�N���R�[�h3
                       ,iv_token_value3 => g_visit_data_rec.account_number  -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_cstm_nm                   -- �g�[�N���R�[�h4
                       ,iv_token_value4 => g_visit_data_rec.account_name    -- �g�[�N���l4                       
                       ,iv_token_name5  => cv_tkn_sales_cd                  -- �g�[�N���R�[�h5
                       ,iv_token_value5 => g_visit_data_rec.employee_number -- �g�[�N���l5
                       ,iv_token_name6  => cv_tkn_sales_nm                  -- �g�[�N���R�[�h6
                       ,iv_token_value6 => g_visit_data_rec.employee_name   -- �g�[�N���l6                       
                       ,iv_token_name7  => cv_date_time                     -- �g�[�N���R�[�h7
                       ,iv_token_value7 => g_visit_data_rec.visit_date || g_visit_data_rec.visit_time
                         -- �g�[�N���l7
                     );
        lv_errbuf := lv_errmsg||SQLERRM;
        RAISE global_skip_error_expt;
    END;
--
    -- *** 4. �u�K������v�ɊY������Ώۂ̉�v���Ԃ��N���[�Y����Ă��邩���`�F�b�N *** --
    -- ��v���ԃ`�F�b�N�֐����g�p
    lv_gl_period_statuses := xxcso_util_common_pkg.check_ar_gl_period_status(g_visit_data_rec.visit_datetime);
    -- �`�F�b�N�֐��̃��^�[���l��'FALSE'(�N���[�Y����Ă���)�̏ꍇ
    IF lv_gl_period_statuses = cv_false THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                      -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_09                 -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_cstm_cd                   -- �g�[�N���R�[�h1
                     ,iv_token_value1 => g_visit_data_rec.account_number  -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_cstm_nm                   -- �g�[�N���R�[�h2
                     ,iv_token_value2 => g_visit_data_rec.account_name    -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_sales_cd                  -- �g�[�N���R�[�h3
                     ,iv_token_value3 => g_visit_data_rec.employee_number -- �g�[�N���l3                       
                     ,iv_token_name4  => cv_tkn_sales_nm                  -- �g�[�N���R�[�h4
                     ,iv_token_value4 => g_visit_data_rec.employee_name   -- �g�[�N���l4
                     ,iv_token_name5  => cv_date_time                     -- �g�[�N���R�[�h5
                     ,iv_token_value5 => g_visit_data_rec.visit_date || g_visit_data_rec.visit_time   -- �g�[�N���l5   
                   );
      lv_errbuf := lv_errmsg||SQLERRM;
      RAISE global_skip_error_expt;
    END IF;
--
  EXCEPTION
    -- *** �X�L�b�v��O�n���h�� ***
    WHEN global_skip_error_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
     -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END chk_mst_is_exists;
--
  /**********************************************************************************
   * Procedure Name   : insert_visit_data
   * Description      : �K��̂ݏ��o�^���� (A-7)
   ***********************************************************************************/
--
  PROCEDURE insert_visit_data(
     ov_errbuf            OUT NOCOPY VARCHAR2             -- �G���[�E���b�Z�[�W            -- # �Œ� #
    ,ov_retcode           OUT NOCOPY VARCHAR2             -- ���^�[���E�R�[�h              -- # �Œ� #
    ,ov_errmsg            OUT NOCOPY VARCHAR2             -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'insert_visit_data';     -- �v���O������
--
-- #####################  �Œ胍�[�J���ϐ��錾�� START     #########################
--
    lv_errbuf            VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode           VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg            VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
-- #####################  �Œ胍�[�J���ϐ��錾�� END       #########################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_task_table_nm   CONSTANT VARCHAR2(100) := '�^�X�N�e�[�u��';
    -- *** ���[�J���ϐ� ***
    ln_task_id         NUMBER;            -- �^�X�NID
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- =======================
    -- �K��̂ݏ��o�^ 
    -- =======================
    xxcso_task_common_pkg.create_task(
        in_resource_id            => g_visit_data_rec.resource_id         -- �c�ƈ��R�[�h�̃��\�[�XID
       ,in_party_id               => g_visit_data_rec.party_id            -- �ڋq�̃p�[�e�BID
       ,iv_party_name             => g_visit_data_rec.party_name          -- �ڋq�̃p�[�e�B����
       ,id_visit_date             => g_visit_data_rec.visit_datetime      -- ���яI�����i�K������j
       ,iv_description            => g_visit_data_rec.description         -- �ڍד��e
       ,iv_attribute1             => g_visit_data_rec.dff1_cd             -- DFF1 �K��敪�P
       ,iv_attribute2             => g_visit_data_rec.dff2_cd             -- DFF2 �K��敪�Q
       ,iv_attribute3             => g_visit_data_rec.dff3_cd             -- DFF3 �K��敪�R
       ,iv_attribute4             => g_visit_data_rec.dff4_cd             -- DFF4 �K��敪�S
       ,iv_attribute5             => g_visit_data_rec.dff5_cd             -- DFF5 �K��敪�T
       ,iv_attribute11            => cv_enable_houmon_kubun               -- DFF11 �L���K��敪 �K��F0
       ,iv_attribute12            => cv_insert_kubun                      -- DFF12 �o�^�敪 �K��̂݁iHHT�j�F1
       ,iv_attribute13            => NULL                                 -- DFF13�@�o�^�敪�ԍ�
       ,iv_attribute14            => g_visit_data_rec.customer_status     -- DFF14�@�ڋq�X�e�[�^�X
       ,on_task_id                => ln_task_id                           -- �^�X�NID
       ,ov_errbuf                 => lv_errbuf                            -- �G���[�E���b�Z�[�W
       ,ov_retcode                => lv_retcode                           -- ����:0�A�x��:1�A�ُ�:2
       ,ov_errmsg                 => lv_errmsg                            -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF (lv_retcode <> cv_status_normal) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                      -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_11                 -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_tbl                       -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_task_table_nm                 -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_err_msg                   -- �g�[�N���R�[�h2
                     ,iv_token_value2 => SQLERRM                          -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_cstm_cd                   -- �g�[�N���R�[�h3
                     ,iv_token_value3 => g_visit_data_rec.account_number  -- �g�[�N���l3
                     ,iv_token_name4  => cv_tkn_cstm_nm                   -- �g�[�N���R�[�h4
                     ,iv_token_value4 => g_visit_data_rec.account_name    -- �g�[�N���l4                       
                     ,iv_token_name5  => cv_tkn_sales_cd                  -- �g�[�N���R�[�h5
                     ,iv_token_value5 => g_visit_data_rec.employee_number -- �g�[�N���l5
                     ,iv_token_name6  => cv_tkn_sales_nm                  -- �g�[�N���R�[�h6
                     ,iv_token_value6 => g_visit_data_rec.employee_name   -- �g�[�N���l6                       
                     ,iv_token_name7  => cv_date_time                     -- �g�[�N���R�[�h7
                     ,iv_token_value7 => g_visit_data_rec.visit_date || g_visit_data_rec.visit_time
                         -- �g�[�N���l7
                   );
      lv_errbuf := lv_errmsg||SQLERRM;
      RAISE global_skip_error_expt;
    END IF;
--
  EXCEPTION
    -- *** �X�L�b�v��O�n���h�� ***
    WHEN global_skip_error_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END insert_visit_data;
--
  /**********************************************************************************
   * Procedure Name   : close_csv_file
   * Description      : CSV�t�@�C���N���[�Y���� (A-9)
   ***********************************************************************************/
  PROCEDURE close_csv_file(
     ov_errbuf         OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode        OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg         OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'close_csv_file';  -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    -- �t�@�C���I�[�v���m�F�߂�l�i�[
    lb_fopn_retcd   BOOLEAN;
    -- *** ���[�J����O ***
    file_err_expt   EXCEPTION;  -- �t�@�C��������O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================
    -- CSV�t�@�C���N���[�Y 
    -- ====================
    BEGIN
      UTL_FILE.FCLOSE(
        file => gf_file_hand
      );
--
    EXCEPTION
      WHEN UTL_FILE.WRITE_ERROR          OR     -- �I�y���[�e�B���O�V�X�e���G���[
           UTL_FILE.INVALID_FILEHANDLE   THEN   -- �t�@�C���E�n���h�������G���[
        -- �G���[���b�Z�[�W�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_15             --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_csv_loc               --�g�[�N���R�[�h1
                      ,iv_token_value1 => gv_hht_in_csv_dir            --�g�[�N���l1
                      ,iv_token_name2  => cv_tkn_csv_fnm               --�g�[�N���R�[�h2
                      ,iv_token_value2 => gv_houmon_csv_file_nm        --�g�[�N���l2
                      ,iv_token_name3  => cv_tkn_err_msg               --�g�[�N���R�[�h3
                      ,iv_token_value3 => SQLERRM                      --�g�[�N���l3                      
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE file_err_expt;
    END;
  EXCEPTION
    -- *** �t�@�C��������O�n���h�� ***
    WHEN file_err_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END close_csv_file;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   ***********************************************************************************/
--
  PROCEDURE submain(
     iv_file_name        IN VARCHAR2           -- �K��̂�CSV�t�@�C����
    ,ov_errbuf           OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W            -- # �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h              -- # �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'submain';     -- �v���O������
--
-- #####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf      VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode     VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_sub_retcode VARCHAR2(1);     -- �T�[�u���^�[���E�R�[�h
    lv_errmsg      VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
-- ###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_base_value           VARCHAR2(5000);         -- ���Y�s�f�[�^
    ln_task_id              NUMBER;                 -- �^�X�N�h�c
    ln_task_count           NUMBER;                 -- ���o����
    lb_fopn_retcd           BOOLEAN;                -- CSV�t�@�C���I�[�v���߂�l
--
    -- *** ���[�J����O ***
--
  BEGIN
--
-- ##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
-- ###########################  �Œ蕔 END   ############################
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
--
    -- ================================
    -- A-1.�������� 
    -- ================================
    init(
       iv_file_name => gv_houmon_csv_file_nm  -- �K��̂�CSV�t�@�C����
      ,ov_errbuf    => lv_errbuf              -- �G���[�E���b�Z�[�W            -- # �Œ� #
      ,ov_retcode   => lv_retcode             -- ���^�[���E�R�[�h              -- # �Œ� #
      ,ov_errmsg    => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- A-2.�v���t�@�C���l�擾 
    -- ========================================
    get_profile_info(
       ov_errbuf        => lv_errbuf        -- �G���[�E���b�Z�[�W            -- # �Œ� #
      ,ov_retcode       => lv_retcode       -- ���^�[���E�R�[�h              -- # �Œ� #
      ,ov_errmsg        => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =================================================
    -- A-3.CSV�t�@�C���I�[�v�� 
    -- =================================================
    open_csv_file(
       ov_errbuf    => lv_errbuf    -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode   => lv_retcode   -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg    => lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- �t�@�C���f�[�^���[�v
    <<get_visit_data_loop>>
    LOOP
      BEGIN
        -- A-4.CSV�f�[�^���o      
        BEGIN
          UTL_FILE.GET_LINE(gf_file_hand, lv_base_value, 32767);    
        EXCEPTION
          -- CSV�t�@�C���Ƀf�[�^���Ȃ��ꍇ�A���[�v�𔲂���
          WHEN NO_DATA_FOUND THEN
            EXIT;
          -- �z��O�G���[�̏ꍇ�A�x���X�L�b�v
          WHEN OTHERS  THEN                      -- ����ȊO�̃G���[
            -- �G���[���b�Z�[�W�擾
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name            --�A�v���P�[�V�����Z�k��
                           ,iv_name         => cv_tkn_number_04       --���b�Z�[�W�R�[�h
                           ,iv_token_name1  => cv_tkn_csv_loc         --�g�[�N���R�[�h1
                           ,iv_token_value1 => gv_hht_in_csv_dir      --�g�[�N���l1
                           ,iv_token_name2  => cv_tkn_csv_fnm         --�g�[�N���R�[�h2
                           ,iv_token_value2 => gv_houmon_csv_file_nm  --�g�[�N���l2
                           ,iv_token_name3  => cv_tkn_err_msg         --�g�[�N���R�[�h3
                           ,iv_token_value3 => SQLERRM                --�g�[�N���l3  
                         );
            lv_errbuf := lv_errmsg || SQLERRM;
            RAISE global_skip_error_expt;
--
        END;
--
        -- �Ώی����J�E���g
        gn_target_cnt := gn_target_cnt + 1;
--
        -- =================================================
        -- A-5.�t�@�C���t�H�}�b�g�`�F�b�N
        -- =================================================
        file_format_check(
           iv_base_value    => lv_base_value    -- ���Y�s�f�[�^
          ,ov_errbuf        => lv_errbuf        -- �G���[�E���b�Z�[�W            -- # �Œ� #
          ,ov_retcode       => lv_sub_retcode   -- ���^�[���E�R�[�h              -- # �Œ� #
          ,ov_errmsg        => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
        );
--
        IF (lv_sub_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        ELSIF (lv_sub_retcode = cv_status_warn) THEN
          RAISE global_skip_error_expt;
        END IF;
--
        -- =============================
        -- A-6.�}�X�^���݃`�F�b�N 
        -- =============================
        chk_mst_is_exists(
           ov_errbuf        => lv_errbuf        -- �G���[�E���b�Z�[�W            -- # �Œ� #
          ,ov_retcode       => lv_sub_retcode   -- ���^�[���E�R�[�h              -- # �Œ� #
          ,ov_errmsg        => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
        );
--
        IF (lv_sub_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        ELSIF (lv_sub_retcode = cv_status_warn) THEN
          RAISE global_skip_error_expt;
        END IF;
--
        -- =============================
        -- A-7.�K��̂ݏ��o�^���� 
        -- =============================
        insert_visit_data(
           ov_errbuf        => lv_errbuf        -- �G���[�E���b�Z�[�W            -- # �Œ� #
          ,ov_retcode       => lv_sub_retcode   -- ���^�[���E�R�[�h              -- # �Œ� #
          ,ov_errmsg        => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
        );
--
        IF (lv_sub_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        ELSIF (lv_sub_retcode = cv_status_warn) THEN
          RAISE global_skip_error_expt;
        END IF;
--
        -- A-8.SAVEPOINT���s
        SAVEPOINT visit;
--
        -- ���������J�E���g
        gn_normal_cnt := gn_normal_cnt + 1;
--
      EXCEPTION
        -- *** �X�L�b�v��O�n���h�� ***
        WHEN global_skip_error_expt THEN
          gn_error_cnt := gn_error_cnt + 1;       -- �G���[�����J�E���g
--
          -- ���b�Z�[�W�o��
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg                  -- ���[�U�[�E�G���[���b�Z�[�W
          );
          fnd_file.put_line(
             which  => FND_FILE.LOG
            ,buff   => cv_pkg_name||cv_msg_cont||
                       cv_prg_name||cv_msg_part||
                       lv_errbuf                  -- �G���[���b�Z�[�W
          );
--
          -- ���[���o�b�N
          IF gn_normal_cnt > 0 THEN
            ROLLBACK TO SAVEPOINT visit;          -- ROLLBACK TO SAVEPOINT
            -- ���O�o��
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff   => CHR(10) ||cv_debug_msg8|| CHR(10)
            );
          ELSE
            ROLLBACK;          -- ROLLBACK
            -- ���O�o��
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff   => CHR(10) ||cv_debug_msg7|| CHR(10)
            );
          END IF;
          -- �S�̂̏����X�e�[�^�X�Ɍx���Z�b�g
          ov_retcode := cv_status_warn;
--
        -- *** �X�L�b�v��OOTHERS�n���h�� ***
        WHEN OTHERS THEN
          gn_error_cnt := gn_error_cnt + 1;       -- �G���[�����J�E���g
--
          -- ���O�o��
          fnd_file.put_line(
             which  => FND_FILE.LOG
            ,buff   => cv_pkg_name||cv_msg_cont||
                       cv_prg_name||cv_msg_part||
                       lv_errbuf                  -- �G���[���b�Z�[�W
          );
--
          -- ���[���o�b�N
          IF gn_normal_cnt > 0 THEN
            ROLLBACK TO SAVEPOINT visit;          -- ROLLBACK TO SAVEPOINT
            -- ���O�o��
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff   => CHR(10) ||cv_debug_msg8|| CHR(10)
            );
          ELSE
            ROLLBACK;          -- ROLLBACK
            -- ���O�o��
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff   => CHR(10) ||cv_debug_msg7|| CHR(10)
            );
          END IF;
          -- �S�̂̏����X�e�[�^�X�Ɍx���Z�b�g
          ov_retcode := cv_status_warn;
--
      END;
    END LOOP get_visit_data_loop;
--
    -- ========================================
    -- CSV�t�@�C���N���[�Y (A-9) 
    -- ========================================
    close_csv_file(
       ov_errbuf    => lv_errbuf    -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode   => lv_retcode   -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg    => lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
--
-- #################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file => gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
--
      ov_errbuf     := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode    := cv_status_error;
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
--
      ov_errbuf     := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode    := cv_status_error;
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
     errbuf        OUT NOCOPY VARCHAR2          -- �G���[�E���b�Z�[�W  -- # �Œ� #
    ,retcode       OUT NOCOPY VARCHAR2          -- ���^�[���E�R�[�h    -- # �Œ� #
    ,iv_file_name  IN         VARCHAR2          -- �t�@�C����
  )    
--
-- ###########################  �Œ蕔 START   ###########################
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
-- ###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
-- ###########################  �Œ蕔 END   #############################
--
    -- *** ���̓p�����[�^���Z�b�g
    gv_houmon_csv_file_nm := iv_file_name;
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       iv_file_name => gv_houmon_csv_file_nm  -- �K��̂�CSV�t�@�C����
      ,ov_errbuf    => lv_errbuf              -- �G���[�E���b�Z�[�W            -- # �Œ� #
      ,ov_retcode   => lv_retcode             -- ���^�[���E�R�[�h              -- # �Œ� #
      ,ov_errmsg    => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
       --�G���[�o��
       fnd_file.put_line(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg                  -- ���[�U�[�E�G���[���b�Z�[�W
       );
       fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => lv_errbuf                  -- �G���[���b�Z�[�W
       );
    END IF;
--
    -- =======================
    -- A-10.�I������ 
    -- =======================
    -- ��s�̏o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''               -- ��s
    );
    -- �Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_tkn_cnt
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                  );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- ���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_tkn_cnt
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                  );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- �G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_tkn_cnt
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                  );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- �I�����b�Z�[�W
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
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- �X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    -- �I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
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
END XXCSO014A03C;
/
