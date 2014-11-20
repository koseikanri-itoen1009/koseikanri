CREATE OR REPLACE PACKAGE BODY XXCMM005A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM005A04C(body)
 * Description      : �����}�X�^IF�o�́i���̋@�Ǘ��j
 * MD.050           : �����}�X�^IF�o�́i���̋@�Ǘ��j MD050_CMM_005_A04
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  open_csv_file          �t�@�C���I�[�v������(A-2)
 *  chk_count_top_dept     �ŏ�ʕ��匏���擾(A-3)
 *  get_output_data        �����Ώۃf�[�^���o(A-4)
 *  output_csv_data        ���o���o��(A-5)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/02/12    1.0   Masayuki.Sano    �V�K�쐬
 *  2009/02/26    1.1   Masayuki.Sano    �����e�X�g����s���Ή�
 *  2009/03/09    1.2   Yuuki.Nakamura   �t�@�C���o�͐�v���t�@�C�����̕ύX
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
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         -- CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    -- PROGRAM_UPDATE_DATE
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
  no_output_data_expt       EXCEPTION;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCMM005A04C';                  -- �p�b�P�[�W��
  -- �� �A�v���P�[�V�����Z�k��
  cv_app_name_xxcmm   CONSTANT VARCHAR2(30)  := 'XXCMM';                      -- �}�X�^
  cv_app_name_xxccp   CONSTANT VARCHAR2(30)  := 'XXCCP';                      -- ���ʁEIF
  -- �� �J�X�^���E�v���t�@�C���E�I�v�V����(XXCMM:�����}�X�^IF�o��(���̋@�Ǘ�)�A�g�p)
--ver.1.2 2009/03/09 mod by Yuuki.Nakamura start
--  cv_pro_out_file_dir CONSTANT VARCHAR2(50) := 'XXCMM1_005A04_OUT_FILE_DIR';  -- CSV�t�@�C���o�͐�
  cv_pro_out_file_dir CONSTANT VARCHAR2(50) := 'XXCMM1_JIHANKI_OUT_DIR';        -- CSV�t�@�C���o�͐�
--ver.1.2 2009/03/09 mod by Yuuki.Nakamura end
  cv_pro_out_file_fil CONSTANT VARCHAR2(50) := 'XXCMM1_005A04_OUT_FILE_FIL';  -- CSV�t�@�C����
  -- �� ���b�Z�[�W�E�R�[�h�i�G���[�j
  cv_msg_00002        CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00002';            -- �v���t�@�C���擾�G���[
  cv_msg_00010        CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00010';            -- CSV�t�@�C�����݃`�F�b�N
  cv_msg_00031        CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00031';            -- ���Ԏw��G���[
  cv_msg_00003        CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00003';            -- �t�@�C���p�X�s���G���[
  cv_msg_00500        CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00500';            -- ����K�w�G���[
  cv_msg_00009        CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00009';            -- CSV�f�[�^�o�̓G���[
-- 2009/02/26 ADD by M.Sano Start
  cv_msg_91003        CONSTANT VARCHAR2(20) := 'APP-XXCCP1-91003';            -- �V�X�e���G���[
-- 2009/02/26 ADD by M.Sano End
  -- �� ���b�Z�[�W�E�R�[�h�i�R���J�����g�E�o�́j
  cv_msg_00038        CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00038';            -- ���̓p�����[�^���b�Z�[�W
  cv_msg_05132        CONSTANT VARCHAR2(20) := 'APP-XXCCP1-05102';            -- �t�@�C�����o�̓��b�Z�[�W
  cv_msg_00001        CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00001';            -- �Ώۃf�[�^����
  cv_msg_90000        CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90000';            -- �Ώی������b�Z�[�W
  cv_msg_90001        CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90001';            -- �����������b�Z�[�W
  cv_msg_90002        CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90002';            -- �G���[�������b�Z�[�W
  cv_normal_msg       CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90004';            -- ����I�����b�Z�[�W
  cv_error_msg        CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90006';            -- �G���[�I���S���[���o�b�N
  -- �� �g�[�N��
  cv_tok_ng_profile   CONSTANT VARCHAR2(10) := 'NG_PROFILE';
  cv_tok_ffv_set_name CONSTANT VARCHAR2(15) := 'FFV_SET_NAME';                -- �l�Z�b�g��
  cv_tok_count        CONSTANT VARCHAR2(10) := 'COUNT';
  cv_tok_ng_word      CONSTANT VARCHAR2(10) := 'NG_WORD';
  cv_tok_ng_data      CONSTANT VARCHAR2(10) := 'NG_DATA';
  cv_tok_param        CONSTANT VARCHAR2(5)  := 'PARAM';
  cv_tok_value        CONSTANT VARCHAR2(5)  := 'VALUE';
  cv_tok_filename     CONSTANT VARCHAR2(10) := 'FILE_NAME';                   -- �t�@�C����
  -- �� �g�[�N���l
  cv_tvl_out_file_dir CONSTANT VARCHAR2(70) := 'XXCMM:�����}�X�^�i���̋@�Ǘ��j�A�g�pCSV�t�@�C���o�͐�';
  cv_tvl_out_file_fil CONSTANT VARCHAR2(70) := 'XXCMM:�����}�X�^�i���̋@�Ǘ��j�A�g�pCSV�t�@�C����';
  cv_tvl_ffv_set_name CONSTANT VARCHAR2(20) := 'XX03_DEPARTMENT';
  cv_tvl_dept_code    CONSTANT VARCHAR2(20) := '�����R�[�h'; 
  cv_tvl_update_from  CONSTANT VARCHAR2(20) := '�ŏI�X�V��(from)';
  cv_tvl_update_to    CONSTANT VARCHAR2(20) := '�ŏI�X�V��(to)  ';
  cv_tvl_auto_st      CONSTANT VARCHAR2(20) := '[]:�����擾�l['; -- �ݶ��ĥ���Ұ���_����(�J�n)
  cv_tvl_auto_en      CONSTANT VARCHAR2(1)  := ']';              -- �ݶ��ĥ���Ұ���_����(�I��)
  cv_tvl_para_st      CONSTANT VARCHAR2(1)  := '[';              -- �ݶ��ĥ���Ұ���(�J�n)
  cv_tvl_para_en      CONSTANT VARCHAR2(1)  := ']';              -- �ݶ��ĥ���Ұ���(�I��)
  -- �� ���̑�
  cv_date_format      CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';
  cv_date_format2     CONSTANT VARCHAR2(8)   := 'YYYYMMDD';
  cv_datetime_format  CONSTANT VARCHAR2(21)  := 'YYYY/MM/DD HH24:MI:SS';
-- 
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �����}�X�^IF�o�́i���̋@�Ǘ��j���C�A�E�g
  TYPE output_data_rtype IS RECORD
  (
     dpt_cd                xxcmm_hierarchy_dept_v.dpt6_cd%TYPE              -- ����R�[�h
    ,dpt_name              xxcmm_hierarchy_dept_v.dpt6_name%TYPE            -- ���喼��
    ,dpt_abbreviate        xxcmm_hierarchy_dept_v.dpt6_abbreviate%TYPE      -- ���嗪��
    ,dpt_sort_num          xxcmm_hierarchy_dept_v.dpt6_sort_num%TYPE        -- ���я�
    ,dpt_div               xxcmm_hierarchy_dept_v.dpt6_div%TYPE             -- ����敪
    ,district_cd           xxcmm_hierarchy_dept_v.dpt6_old_cd%TYPE          -- �n��R�[�h
    ,xhdv_last_update_date xxcmm_hierarchy_dept_v.last_update_date%TYPE     -- �ŏI�X�V��
    ,user_div              hz_cust_accounts.attribute8%TYPE                 -- ���p�ҋ敪
    ,customer_class_code   hz_cust_accounts.customer_class_code%TYPE        -- �ڋq�敪
    ,start_date_active     xxcmn_parties.start_date_active%TYPE             -- �K�p�J�n��
    ,end_date_active       xxcmn_parties.end_date_active%TYPE               -- �K�p�I����
    ,party_name            xxcmn_parties.party_name%TYPE                    -- ������
    ,party_short_name      xxcmn_parties.party_short_name%TYPE              -- ����
    ,party_name_alt        xxcmn_parties.party_name_alt%TYPE                -- �J�i��
    ,address_line1         xxcmn_parties.address_line1%TYPE                 -- �Z���P
    ,address_line2         xxcmn_parties.address_line2%TYPE                 -- �Z���Q
    ,zip                   xxcmn_parties.zip%TYPE                           -- �X�֔ԍ�
    ,phone                 xxcmn_parties.phone%TYPE                         -- �d�b�ԍ�
    ,fax                   xxcmn_parties.fax%TYPE                           -- FAX�ԍ�
    ,xpty_last_update_date xxcmn_parties.last_update_date%TYPE              -- �ŏI�X�V��
    ,flex_value_set_id     xxcmm_hierarchy_dept_v.flex_value_set_id%TYPE     -- �l�Z�b�gID
  );
--
  -- �����}�X�^IF�o�́i���̋@�Ǘ��j���C�A�E�g �e�[�u���^�C�v
  TYPE output_data_ttype IS TABLE OF output_data_rtype INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_process_date       VARCHAR2(50);     -- �Ɩ����t(�t�H�[�}�b�g�FYYYY/MM/DD)
  -- ���̓p�����[�^
  gv_update_from        VARCHAR2(50);     -- �ŏI�X�V��(FROM)
  gv_update_to          VARCHAR2(50);     -- �ŏI�X�V��(TO)
  -- �����p
  gv_csv_file_dir       fnd_profile_option_values.profile_option_value%TYPE;  -- CSV�t�@�C���o�͐�
  gv_csv_file_name      fnd_profile_option_values.profile_option_value%TYPE;  -- CSV�t�@�C����
  gf_file_handler       UTL_FILE.FILE_TYPE;                                   -- CSV�t�@�C���o�͗p�n���h��
  gt_out_tab            output_data_ttype;                                    -- �����}�X�^IF�o�̓f�[�^
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf             OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- *** ���[�J���ϐ� ***
    lb_file_exists   BOOLEAN;        -- �t�@�C�����ݔ��f
    ln_file_length   NUMBER(30);     -- �t�@�C���̕�����
    lbi_block_size   BINARY_INTEGER; -- �u���b�N�T�C�Y
    lv_update_from   VARCHAR2(10);   -- �`�F�b�N�p�ŏI�X�V��(From)
    lv_update_to     VARCHAR2(10);   -- �`�F�b�N�p�ŏI�X�V��(To)
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    --�P�D�v���t�@�C���̎擾���s���܂��B
    --==============================================================
    -- XXCMM: �����}�X�^IF�o�́i���̋@�Ǘ��j�A�g�pCSV�t�@�C���o�͐���擾
    gv_csv_file_dir    := FND_PROFILE.VALUE(cv_pro_out_file_dir);
    -- XXCMM: �����}�X�^IF�o�́i���̋@�Ǘ��j�A�g�pCSV�t�@�C���o�͐�̎擾���e�`�F�b�N
    IF ( gv_csv_file_dir IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxcmm    -- �}�X�^
                     ,iv_name         => cv_msg_00002         -- �G���[  :�v���t�@�C���擾�G���[
                     ,iv_token_name1  => cv_tok_ng_profile    -- �g�[�N��:NG_PROFILE
                     ,iv_token_value1 => cv_tvl_out_file_dir  -- �l      :CSV�t�@�C���o�͐�
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCMM: �����}�X�^IF�o�́i���̋@�Ǘ��j�A�g�pCSV�t�@�C�������擾
    gv_csv_file_name    := FND_PROFILE.VALUE(cv_pro_out_file_fil);
    -- XXCMM: �����}�X�^IF�o�́i���̋@�Ǘ��j�A�g�pCSV�t�@�C�����̎擾���e�`�F�b�N
    IF ( gv_csv_file_name IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxcmm    -- �}�X�^
                     ,iv_name         => cv_msg_00002         -- �G���[  :�v���t�@�C���擾�G���[
                     ,iv_token_name1  => cv_tok_ng_profile    -- �g�[�N��:NG_PROFILE
                     ,iv_token_value1 => cv_tvl_out_file_fil  -- �l      :CSV�t�@�C����
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --�Q�DCSV�t�@�C�����݃`�F�b�N���s���܂��B
    --==============================================================
    -- �t�@�C�������擾
    UTL_FILE.FGETATTR(
         location     => gv_csv_file_dir
        ,filename     => gv_csv_file_name
        ,fexists      => lb_file_exists
        ,file_length  => ln_file_length
        ,block_size   => lbi_block_size
      );
    -- �t�@�C���d���`�F�b�N(�t�@�C�����݂̗L��)
    IF ( lb_file_exists ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxcmm    -- �}�X�^
                     ,iv_name         => cv_msg_00010         -- �G���[:CSV�t�@�C�����݃`�F�b�N
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --�R�D�Ɩ����t���擾���܂��B
    --==============================================================
    gv_process_date := TO_CHAR(xxccp_common_pkg2.get_process_date, cv_date_format);
--
    --==============================================================
    --�S�D�p�����[�^�`�F�b�N���s���܂��B
    --==============================================================
    -- "�ŏI�X�V��(From) > �ŏI�X�V��(To)"�̏ꍇ�A�p�����[�^�G���[
    lv_update_from := NVL(gv_update_from, gv_process_date);
    lv_update_to   := NVL(gv_update_to,   gv_process_date);
    IF ( lv_update_from > lv_update_to ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxcmm    -- �}�X�^
                     ,iv_name         => cv_msg_00031         -- �G���[:���Ԏw��G���[
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
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- �}�X�^
                     ,iv_name         => cv_msg_91003         -- �G���[:�V�X�e���G���[
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- �}�X�^
                     ,iv_name         => cv_msg_91003         -- �G���[:�V�X�e���G���[
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : open_file
   * Description      : �t�@�C���I�[�v������(A-2)
   ***********************************************************************************/
  PROCEDURE open_csv_file(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'open_csv_file'; -- �v���O������
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
    cv_csv_mode_w CONSTANT VARCHAR2(1) := 'w';  -- �t�@�C���I�[�v�����[�h(�������݃��[�h)
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
    -- �I�[�v�����[�h'W'(�o��)�ŃI�[�v�����܂��B
    -- ===============================================
    BEGIN
      -- �t�@�C�����J��
      gf_file_handler := UTL_FILE.FOPEN(
                            location   => gv_csv_file_dir     -- �o�͐�
                           ,filename   => gv_csv_file_name    -- �t�@�C����
                           ,open_mode  => cv_csv_mode_w       -- �t�@�C���I�[�v�����[�h
                        );
    EXCEPTION
      WHEN UTL_FILE.INVALID_PATH THEN
        -- ���b�Z�[�W���擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name_xxcmm  -- �}�X�^
                       ,iv_name         => cv_msg_00003       -- �G���[:�t�@�C���p�X�s���G���[
                     );
        lv_errbuf := lv_errmsg;
        -- ��O���X���[
        RAISE global_api_expt;
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
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
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- �}�X�^
                     ,iv_name         => cv_msg_91003         -- �G���[:�V�X�e���G���[
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- �}�X�^
                     ,iv_name         => cv_msg_91003         -- �G���[:�V�X�e���G���[
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END open_csv_file;
--
  /**********************************************************************************
   * Procedure Name   : chk_count_top_dept
   * Description      : �ŏ�ʕ��匏���擾(A-3)
   ***********************************************************************************/
  PROCEDURE chk_count_top_dept(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_count_top_dept'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    ln_top_dept_cnt NUMBER;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    -- 1.�ŏ�ʕ���̌������擾���܂��B
    --==============================================================
    BEGIN
      SELECT COUNT(1)
      INTO   ln_top_dept_cnt
      FROM   fnd_flex_value_sets ffvs  -- �l�Z�b�g��`�}�X�^
            ,fnd_flex_values     ffvl  -- �l�Z�b�g�l��`�}�X�^
      WHERE  ffvs.flex_value_set_id = ffvl.flex_value_set_id
      AND    ffvl.enabled_flag = 'Y'
      AND    ffvl.summary_flag = 'Y'
      AND    ffvs.flex_value_set_name = 'XX03_DEPARTMENT'
      AND    xxccp_common_pkg2.get_process_date BETWEEN
                   NVL(ffvl.start_date_active, TO_DATE('19000101','YYYYMMDD'))
               AND NVL(ffvl.end_date_active, TO_DATE('99991231','YYYYMMDD'))
      AND    NOT EXISTS (
               SELECT 'X'
               FROM   fnd_flex_value_norm_hierarchy ffvh
               WHERE  ffvh.flex_value_set_id = ffvl.flex_value_set_id
               AND    ffvl.flex_value BETWEEN ffvh.child_flex_value_low
                                          AND ffvh.child_flex_value_high
             )
      ;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    -- 2�D�ŏ�ʕ��匏����1���ȊO�̏ꍇ�A����K�w�G���[
    --==============================================================
    IF ( ln_top_dept_cnt <> 1 ) THEN
      -- �G���[���b�Z�[�W���o�͌�A�ُ�I��
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxcmm        -- �}�X�^
                     ,iv_name         => cv_msg_00500             -- �G���[:����K�w�G���[
                     ,iv_token_name1  => cv_tok_ffv_set_name      -- �g�[�N��  :FFV_SET_NAME
                     ,iv_token_value1 => cv_tvl_ffv_set_name      -- �g�[�N���l:XX03_DEPARTMENT
                     ,iv_token_name2  => cv_tok_count             -- �g�[�N��  :COUNT
                     ,iv_token_value2 => TO_CHAR(ln_top_dept_cnt) -- �g�[�N���l:�ŏ�ʊK�w�̌���
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
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- �}�X�^
                     ,iv_name         => cv_msg_91003         -- �G���[:�V�X�e���G���[
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- �}�X�^
                     ,iv_name         => cv_msg_91003         -- �G���[:�V�X�e���G���[
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_count_top_dept;
--
  /**********************************************************************************
   * Procedure Name   : get_output_data
   * Description      : �����Ώۃf�[�^���o(A-4)
   ***********************************************************************************/
  PROCEDURE get_output_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_output_data'; -- �v���O������
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
    cv_time_min    VARCHAR2(10) := ' 00:00:00';
    cv_time_max    VARCHAR2(10) := ' 23:59:59';
    
    -- *** ���[�J���ϐ� ***
    ld_update_from DATE;
    ld_update_to   DATE;
--
    -- *** ���[�J���J�[�\��***
    CURSOR output_data_cur(
       id_last_update_date_from DATE
      ,id_last_update_date_to   DATE)
    IS
      SELECT xhdv.dpt6_cd              dpt_cd                 -- ����R�[�h
            ,xhdv.dpt6_name            dpt_name               -- ���喼��
            ,xhdv.dpt6_abbreviate      dpt_abbreviate         -- ���嗪��
            ,xhdv.dpt6_sort_num        dpt_sort_num           -- ���я�
            ,xhdv.dpt6_div             dpt_div                -- ����敪
            ,xhdv.dpt6_old_cd          district_cd            -- �n��R�[�h
            ,xhdv.last_update_date     xhdv_last_update_date  -- �ŏI�X�V��
            ,hzac.attribute8           user_div               -- ���p�ҋ敪
            ,hzac.customer_class_code  customer_class_code    -- �ڋq�敪
            ,xpty.start_date_active    start_date_active      -- �K�p�J�n��
            ,xpty.end_date_active      end_date_active        -- �K�p�I����
            ,xpty.party_name           party_name             -- ������
            ,xpty.party_short_name     party_short_name       -- ����
            ,xpty.party_name_alt       party_name_alt         -- �J�i��
            ,xpty.address_line1        address_line1          -- �Z���P
            ,xpty.address_line2        address_line2          -- �Z���Q
            ,xpty.zip                  zip                    -- �X�֔ԍ�
            ,xpty.phone                phone                  -- �d�b�ԍ�
            ,xpty.fax                  fax                    -- FAX�ԍ�
            ,xpty.last_update_date     xpty_last_update_date  -- �ŏI�X�V��
            ,xhdv.flex_value_set_id    flex_value_set_id      -- �l�Z�b�gID
      FROM   xxcmm_hierarchy_dept_v   xhdv  -- (TABLE)����K�w�r���[
            ,hz_cust_accounts         hzac  -- (TABLE)�ڋq�}�X�^
            ,xxcmn_parties            xpty  -- (TABLE)�p�[�e�B�A�h�I���}�X�^
      WHERE  xhdv.dpt6_cd             = hzac.account_number
      AND    hzac.customer_class_code = '1' -- ���o�ΏہF���_
      AND    hzac.party_id            = xpty.party_id
      AND    xpty.start_date_active BETWEEN id_last_update_date_from
                                        AND id_last_update_date_to
      AND    (  ( xhdv.last_update_date BETWEEN id_last_update_date_from
                                            AND id_last_update_date_to  )
             OR ( xpty.last_update_date BETWEEN id_last_update_date_from 
                                            AND id_last_update_date_to  ) )
      ORDER BY
             xhdv.dpt6_cd ASC
      ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    -- ���������ɑ}������������쐬����B
    --==============================================================
    -- �ŏI�X�V��(From)���쐬(YYYY/MM/DD 00:00:00)
    ld_update_from := TO_DATE(NVL(gv_update_from, gv_process_date) || cv_time_min, cv_datetime_format);
    -- �ŏI�X�V��(To)���쐬  (YYYY/MM/DD 23:59:59)
    ld_update_to   := TO_DATE(NVL(gv_update_to, gv_process_date)   || cv_time_max, cv_datetime_format);
--
    --==============================================================
    -- �����}�X�^IF�����擾���A���ʂ�z��Ɋi�[���܂��B
    --==============================================================
    -- CSV�o�̓f�[�^�擾�J�[�\���̃I�[�v��
    OPEN output_data_cur(ld_update_from, ld_update_to);
    -- CSV�o�̓f�[�^�擾�̎擾
    <<output_data_loop>>
    LOOP
      FETCH output_data_cur BULK COLLECT INTO gt_out_tab;
      EXIT WHEN output_data_cur%NOTFOUND;
    END LOOP output_data_loop;
    -- CSV�o�̓f�[�^�擾�J�[�\���̃N���[�Y
    CLOSE output_data_cur;
    -- �������擾
    gn_target_cnt := gt_out_tab.COUNT;
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
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- �}�X�^
                     ,iv_name         => cv_msg_91003         -- �G���[:�V�X�e���G���[
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- �}�X�^
                     ,iv_name         => cv_msg_91003         -- �G���[:�V�X�e���G���[
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_output_data;
--
  /**********************************************************************************
   * Procedure Name   : output_csv_data
   * Description      : ���o���o��(A-5)
   ***********************************************************************************/
  PROCEDURE output_csv_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_csv_data'; -- �v���O������
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
    -- ����
    cv_sep                  CONSTANT VARCHAR2(1)   := ',';          -- ��؂蕶��
    cv_dqu                  CONSTANT VARCHAR2(1)   := '"';          -- �_�u���N�H�[�e�[�V����
    cv_hyphen               CONSTANT VARCHAR2(1)   := '-';          -- �n�C�t��
    -- �f�t�H���g������
    cv_def_phone_len        CONSTANT NUMBER        := 6; 
    -- ����
    cv_term_code            CONSTANT VARCHAR2(4)   := '0000';       -- �`�[���R�[�h
    cv_stop_using_flg       CONSTANT VARCHAR2(1)   := '0';          -- ���p��~�t���O
    cv_create_prep_code     CONSTANT VARCHAR2(5)   := '99999';      -- �쐬�S���҃R�[�h
    cv_create_dept          CONSTANT VARCHAR2(6)   := '999999';     -- �쐬����
    cv_create_prog_id       CONSTANT VARCHAR2(10)  := 'BUKKEN_2UD'; -- �쐬�v���O����ID
    cv_update_prep_code     CONSTANT VARCHAR2(5)   := '99999';      -- �X�V�S���҃R�[�h
    cv_update_dept          CONSTANT VARCHAR2(6)   := '999999';     -- �X�V����
    cv_update_prog_id       CONSTANT VARCHAR2(10)  := 'BUKKEN_2UD'; -- �X�V�v���O����ID
    -- �t�H�[�}�b�g
    cv_last_update_fmt      CONSTANT VARCHAR2(10)  := 'DDHH24MISS'; -- �ŏI�X�V���������b�t�H�[�}�b�g
    -- *** ���[�J���ϐ� ***
    lv_outline              VARCHAR2(2400);                         -- �o�͓��e(�s)
    ln_idx                  NUMBER;
    -- �ꎞ�ϐ�
    ln_phone_st             NUMBER; -- ���o����d�b�ԍ��̊J�n�ʒu
    ln_phone_len            NUMBER; -- ���o����d�b�ԍ��̕�����
    ln_hyphen_idx           NUMBER; -- ���n�C�t���̈ʒu
    -- ����
    lv_dept_code            VARCHAR2(4);                -- �����R�[�h
    lv_address_line         VARCHAR2(60);               -- �����Z��
    lv_phone_1              xxcmn_parties.phone%TYPE;   -- �d�b�ԍ�1
    lv_phone_2              xxcmn_parties.phone%TYPE;   -- �d�b�ԍ�2
    lv_phone_3              xxcmn_parties.phone%TYPE;   -- �d�b�ԍ�3
    lv_district_code        VARCHAR2(6);                -- �n��R�[�h
    lv_district_name        VARCHAR2(16);               -- �n�於��
    lv_last_update_date     VARCHAR2(8);                -- �ŏI�X�V���������b
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    -- �擾���������}�X�^IF�̏����ACSV�t�@�C���֏o��
    --==============================================================
    <<output_csv_loop>>
    FOR ln_idx IN 1 .. gn_target_cnt LOOP
      -- �� �����R�[�h���擾
      lv_dept_code := SUBSTRB(gt_out_tab(ln_idx).dpt_cd, 1, 4);
--
      -- �� �����Z�����擾
      lv_address_line := SUBSTRB(gt_out_tab(ln_idx).address_line1 || gt_out_tab(ln_idx).address_line2, 1, 60);
--
      -- �� �s�O�ǔԂ��擾
      IF ( gt_out_tab(ln_idx).phone IS NULL ) THEN
        lv_phone_1    := NULL;
      ELSE
        -- ���o�J�n�ʒu���Z�o
        ln_phone_st   := 1;
        -- "-"�̈ʒu���擾
        ln_hyphen_idx := INSTRB(gt_out_tab(ln_idx).phone, cv_hyphen, ln_phone_st, 1);
        -- �p�[�e�B�A�h�I���̓d�b�ԍ��̎s�O�ǔԂ��擾
        -- �"-"����������   �� �J�n�ʒu0"-"�̈ʒu�܂ł𒊏o
        -- �"-"��������Ȃ� �� 6�����Œ�
        IF ( ln_hyphen_idx > 0 ) THEN
          ln_phone_len := ln_hyphen_idx; 
          lv_phone_1   := SUBSTRB(gt_out_tab(ln_idx).phone, ln_phone_st, ln_phone_len); 
        ELSE
          lv_phone_1   := SUBSTRB(gt_out_tab(ln_idx).phone, ln_phone_st, cv_def_phone_len);
        END IF;
      END IF;
--
      -- �� �s���ǔԂ��擾
      IF ( lv_phone_1 IS NULL ) THEN
        lv_phone_2    := NULL;
      ELSE
        -- ���o�J�n�ʒu���Z�o
        ln_phone_st   := ln_phone_st + LENGTHB(lv_phone_1);
        -- "-"�̈ʒu���擾(�s�O�ǔԂ̎������ȍ~)
        ln_hyphen_idx := INSTRB(gt_out_tab(ln_idx).phone, cv_hyphen, ln_phone_st, 1);
        -- �p�[�e�B�A�h�I���̓d�b�ԍ��̎s���ǔԂ��擾
        -- �"-"����������   �� �s�O�ǔԂ̎�����0"-"�̈ʒu
        -- �"-"��������Ȃ� �� 6�����Œ�
        IF ( ln_hyphen_idx > 0 ) THEN
          ln_phone_len := ln_hyphen_idx - ln_phone_st + 1; 
          lv_phone_2   := SUBSTRB(gt_out_tab(ln_idx).phone, ln_phone_st, ln_phone_len);
        ELSE
          lv_phone_2   := SUBSTRB(gt_out_tab(ln_idx).phone, ln_phone_st, cv_def_phone_len);
        END IF;
      END IF;
--
      -- �� �����Ҕԍ����擾
      IF ( lv_phone_2 IS NULL ) THEN
        lv_phone_3   := NULL;
      ELSE
        -- ���o�J�n�ʒu���Z�o
        ln_phone_st  := ln_phone_st + LENGTHB(lv_phone_2);
        -- �p�[�e�B�A�h�I���̓d�b�ԍ��̉����Ҕԍ����擾(�s���ǔԂ̎�����0���[)
        ln_phone_len := LENGTHB(gt_out_tab(ln_idx).phone) - ln_phone_st + 1;
        lv_phone_3   := SUBSTRB(gt_out_tab(ln_idx).phone, ln_phone_st, ln_phone_len);
      END IF;
--
      -- �� �n��R�[�h���擾
      lv_district_code := SUBSTRB(gt_out_tab(ln_idx).district_cd, 1, 4)
                            || SUBSTRB(gt_out_tab(ln_idx).dpt_sort_num, 2, 2);
--
      -- �� �n�於�̂��擾
      IF ( gt_out_tab(ln_idx).district_cd IS NOT NULL ) THEN
        BEGIN
          SELECT SUBSTRB(ffvl.attribute4, 1, 16)
          INTO   lv_district_name
          FROM   fnd_flex_values   ffvl
          WHERE  ffvl.flex_value_set_id = gt_out_tab(ln_idx).flex_value_set_id
          AND    ffvl.flex_value        = gt_out_tab(ln_idx).district_cd
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            lv_district_name := '';
          WHEN OTHERS THEN
            RAISE global_api_others_expt;
        END;
      ELSE
        lv_district_name := '';
      END IF;
--
      -- �� �ŏI�X�V���������b���擾
      IF ( gt_out_tab(ln_idx).xhdv_last_update_date > gt_out_tab(ln_idx).xpty_last_update_date ) THEN
        lv_last_update_date := TO_CHAR(gt_out_tab(ln_idx).xhdv_last_update_date, cv_last_update_fmt);
      ELSE
        lv_last_update_date := TO_CHAR(gt_out_tab(ln_idx).xpty_last_update_date, cv_last_update_fmt);
      END IF;
--
      -- �� �o�̓f�[�^�쐬
      -- 1.���p�ҋ敪
      lv_outline := cv_dqu || SUBSTRB(gt_out_tab(ln_idx).user_div, 1, 2) || cv_dqu;
      -- 2.�����R�[�h
      lv_outline := lv_outline || cv_sep || cv_dqu || lv_dept_code || cv_dqu;
      -- 3.�`�[���R�[�h
      lv_outline := lv_outline || cv_sep || cv_dqu || cv_term_code  || cv_dqu;
      -- 4.�K�p�J�n��
      lv_outline := lv_outline || cv_sep || TO_CHAR(gt_out_tab(ln_idx).start_date_active, cv_date_format2);
      -- 5.�K�p�I����
      lv_outline := lv_outline || cv_sep || TO_CHAR(gt_out_tab(ln_idx).end_date_active, cv_date_format2);
      -- 6.�������i�������j
      lv_outline := lv_outline || cv_sep || cv_dqu || SUBSTRB(gt_out_tab(ln_idx).party_name, 1, 40) || cv_dqu;
      -- 7.�������i���́j
      lv_outline := lv_outline || cv_sep || cv_dqu || SUBSTRB(gt_out_tab(ln_idx).party_short_name, 1, 20) || cv_dqu;
      -- 8.�������i�J�i�j
      lv_outline := lv_outline || cv_sep || cv_dqu || SUBSTRB(gt_out_tab(ln_idx).party_name_alt, 1, 20) || cv_dqu;
      -- 9.�`�[�����i�������j
      lv_outline := lv_outline || cv_sep || cv_dqu || cv_dqu;
      -- 10.�`�[�����i���́j
      lv_outline := lv_outline || cv_sep || cv_dqu || cv_dqu;
      -- 11.��ƒS���҃R�[�h�P
      lv_outline := lv_outline || cv_sep || cv_dqu || cv_dqu;
      -- 12.��ƒS���҃R�[�h�Q
      lv_outline := lv_outline || cv_sep || cv_dqu || cv_dqu;
      -- 13.�����Z��
      lv_outline := lv_outline || cv_sep || cv_dqu || lv_address_line || cv_dqu;
      -- 14.�X�֔ԍ�
      lv_outline := lv_outline || cv_sep || SUBSTRB(gt_out_tab(ln_idx).zip, 1, 20);
      -- 15.�d�b�ԍ��P
      lv_outline := lv_outline || cv_sep || cv_dqu || lv_phone_1 || cv_dqu;
      -- 16.�d�b�ԍ��Q
      lv_outline := lv_outline || cv_sep || cv_dqu || lv_phone_2 || cv_dqu;
      -- 17.�d�b�ԍ��R
      lv_outline := lv_outline || cv_sep || cv_dqu || lv_phone_3 || cv_dqu;
      -- 18.�e�`�w�ԍ�
      lv_outline := lv_outline || cv_sep || cv_dqu || SUBSTRB(gt_out_tab(ln_idx).fax, 1, 15) || cv_dqu;
      -- 19.�n��R�[�h
      lv_outline := lv_outline || cv_sep || cv_dqu || lv_district_code || cv_dqu;
      -- 20.�n�於��
      lv_outline := lv_outline || cv_sep || cv_dqu || lv_district_name || cv_dqu;
      -- 21.�\����R�[�h
      lv_outline := lv_outline || cv_sep || cv_dqu || cv_dqu;
      -- 22.�˗��旘�p�ҋ敪
      lv_outline := lv_outline || cv_sep || cv_dqu || cv_dqu;
      -- 23.�˗��揊���R�[�h
      lv_outline := lv_outline || cv_sep || cv_dqu || cv_dqu;
      -- 24.���p��~�t���O
      lv_outline := lv_outline || cv_sep || cv_stop_using_flg;
      -- 25.�쐬�S���҃R�[�h
      lv_outline := lv_outline || cv_sep || cv_dqu || cv_create_prep_code || cv_dqu;
      -- 26.�쐬����
      lv_outline := lv_outline || cv_sep || cv_dqu || cv_create_dept || cv_dqu;
      -- 27.�쐬�v���O�����h�c
      lv_outline := lv_outline || cv_sep || cv_dqu || cv_create_prog_id || cv_dqu;
      -- 28.�X�V�S���҃R�[�h
      lv_outline := lv_outline || cv_sep || cv_dqu || cv_update_prep_code || cv_dqu;
      -- 29.�X�V�����R�[�h
      lv_outline := lv_outline || cv_sep || cv_dqu || cv_update_dept || cv_dqu;
      -- 30.�X�V�v���O�����h�c
      lv_outline := lv_outline || cv_sep || cv_dqu || cv_update_prog_id || cv_dqu;
      -- 31.�쐬���������b
      lv_outline := lv_outline || cv_sep;
      -- 32.�X�V���������b
      lv_outline := lv_outline || cv_sep || lv_last_update_date;
--
      -- �� �o�̓f�[�^��csv�t�@�C���ɏo�͂���B
      BEGIN
        UTL_FILE.PUT_LINE(gf_file_handler, lv_outline);
      EXCEPTION
        WHEN UTL_FILE.WRITE_ERROR THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name_xxcmm    -- �}�X�^
                         ,iv_name         => cv_msg_00009         -- �G���[  :CSV�f�[�^�o�̓G���[
                         ,iv_token_name1  => cv_tok_ng_word       -- �g�[�N��:NG_WORD
                         ,iv_token_value1 => cv_tvl_dept_code     -- �l      :�����R�[�h
                         ,iv_token_name2  => cv_tok_ng_data       -- �g�[�N��:NG_DATA
                         ,iv_token_value2 => lv_dept_code         -- �l      :�����R�[�h(�f�[�^)
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
--
      --�� �����������X�V����B
      gn_normal_cnt := gn_normal_cnt + 1;
   END LOOP output_csv_loop;
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
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- �}�X�^
                     ,iv_name         => cv_msg_91003         -- �G���[:�V�X�e���G���[
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- �}�X�^
                     ,iv_name         => cv_msg_91003         -- �G���[:�V�X�e���G���[
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END output_csv_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf             OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    cv_csv_mode_w CONSTANT VARCHAR2(1) := 'w';  -- �t�@�C���I�[�v�����[�h(�������݃��[�h)
--
    -- *** ���[�J���ϐ� ***
    lv_tvl_para        VARCHAR2(100);  -- �g�[�N���Ɋi�[����l
    lv_out_msg          VARCHAR2(5000); -- �o�͗p
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
    -- ===============================================
    -- A-1.��������
    -- ===============================================
    init(
       ov_errbuf           => lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode          => lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg           => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- ���̓p�����[�^(�ŏI�X�V��(From))�̏o�̓��b�Z�[�W���擾
    -- �E�ŏI�X�V��(From)��NULL�ȊO �� �ŏI�X�V���iFrom�j �F [YYYY/MM/DD]
    IF ( gv_update_from IS NOT NULL ) THEN
      lv_tvl_para := cv_tvl_para_st || gv_update_from || cv_tvl_para_en;
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_xxcmm
                      ,iv_name         => cv_msg_00038
                      ,iv_token_name1  => cv_tok_param
                      ,iv_token_value1 => cv_tvl_update_from
                      ,iv_token_name2  => cv_tok_value
                      ,iv_token_value2 => lv_tvl_para
                     );
    -- �E�ŏI�X�V��(From)��NULL     �� �ŏI�X�V���iFrom�j �F [] : �����擾[YYYY/MM/DD]
    ELSE
      lv_tvl_para := cv_tvl_auto_st || gv_process_date || cv_tvl_auto_en;
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_xxcmm
                      ,iv_name         => cv_msg_00038
                      ,iv_token_name1  => cv_tok_param
                      ,iv_token_value1 => cv_tvl_update_from
                      ,iv_token_name2  => cv_tok_value
                      ,iv_token_value2 => lv_tvl_para
                     );
    END IF;
    -- ���̓p�����[�^(�ŏI�X�V��(From))���R���J�����g��o�͂ɏo��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_out_msg
    );
    -- ���̓p�����[�^(�ŏI�X�V��(To))�̏o�̓��b�Z�[�W���擾
    -- �E�ŏI�X�V��(To)��NULL�ȊO �� �ŏI�X�V���iTo�j �F [YYYY/MM/DD]
    IF ( gv_update_to IS NOT NULL ) THEN
      lv_tvl_para := cv_tvl_para_st || gv_update_to || cv_tvl_para_en;
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_xxcmm
                      ,iv_name         => cv_msg_00038
                      ,iv_token_name1  => cv_tok_param
                      ,iv_token_value1 => cv_tvl_update_to
                      ,iv_token_name2  => cv_tok_value
                      ,iv_token_value2 => lv_tvl_para
                     );
    -- �E�ŏI�X�V��(To)��NULL     �� �ŏI�X�V���iTo�j �F [] : �����擾[YYYY/MM/DD]
    ELSE
      lv_tvl_para := cv_tvl_auto_st || gv_process_date || cv_tvl_auto_en;
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_xxcmm
                      ,iv_name         => cv_msg_00038
                      ,iv_token_name1  => cv_tok_param
                      ,iv_token_value1 => cv_tvl_update_to
                      ,iv_token_name2  => cv_tok_value
                      ,iv_token_value2 => lv_tvl_para
                     );
    END IF;
    -- ���̓p�����[�^(�ŏI�X�V��(To))���R���J�����g��o�͂ɏo��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_out_msg
    );
    -- �t�@�C�����̏o�̓��b�Z�[�W���擾
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => cv_msg_05132
                    ,iv_token_name1  => cv_tok_filename
                    ,iv_token_value1 => gv_csv_file_name
                   );
    -- �t�@�C�������R���J�����g��o�͂ɏo��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_out_msg
    );
    -- ���������̎��s���ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- A-2�D�t�@�C���I�[�v������(�������[�h)
    -- ===============================================
    open_csv_file(
       ov_errbuf           => lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode          => lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg           => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- A-3�D�ŏ�ʕ��匏���擾
    -- ===============================================
    chk_count_top_dept(
       ov_errbuf           => lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode          => lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg           => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- (��O���X���[)
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- A-4�D�����Ώۃf�[�^���o
    -- ===============================================
    get_output_data(
       ov_errbuf           => lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode          => lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg           => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- (��O���X���[)
      RAISE global_process_expt;
    END IF;
    -- 0���̏ꍇ�A���b�Z�[�W�o�͌�A�����I��
    IF ( gn_target_cnt = 0 ) THEN
      -- (�R���J�����g�E�o�͂ƃ��O�փ��b�Z�[�W�o��)
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxcmm    -- �}�X�^
                     ,iv_name         => cv_msg_00001         -- �G���[  :�Ώۃf�[�^�Ȃ�
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg
      );
      -- (��O���X���[)
      RAISE no_output_data_expt;
    END IF;
--
    -- ===============================================
    -- A-5�D���o���o��
    -- ===============================================
    output_csv_data(
       ov_errbuf           => lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode          => lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg           => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �G���[�������X�V����B
    gn_error_cnt := gn_target_cnt - gn_normal_cnt;
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- (��O���X���[)
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    -- *** �Ώۃf�[�^������O�n���h�� ***
    WHEN no_output_data_expt THEN
      ov_retcode := cv_status_normal;
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
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- �}�X�^
                     ,iv_name         => cv_msg_91003         -- �G���[:�V�X�e���G���[
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- �}�X�^
                     ,iv_name         => cv_msg_91003         -- �G���[:�V�X�e���G���[
                   );
-- 2009/02/26 ADD by M.Sano End
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
    errbuf                OUT    VARCHAR2,        --   �G���[���b�Z�[�W #�Œ�#
    retcode               OUT    VARCHAR2,        --   �G���[�R�[�h     #�Œ�#
    iv_update_from        IN     VARCHAR2,        --   1.�ŏI�X�V��(FROM)
    iv_update_to          IN     VARCHAR2)        --   2.�ŏI�X�V��(TO)
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
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf           VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode          VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg           VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code     VARCHAR2(100);   -- �I�����b�Z�[�W�R�[�h
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
    -- ���̓p�����[�^�̎擾
    -- ===============================================
    gv_update_from := iv_update_from;
    gv_update_to   := iv_update_to;
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       ov_errbuf           => lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode          => lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg           => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- ===============================================
    -- A-6�D�I������
    -- ===============================================
    BEGIN
      IF ( UTL_FILE.IS_OPEN(gf_file_handler) ) THEN
        UTL_FILE.FCLOSE(gf_file_handler);
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
        lv_retcode := cv_status_error;
    END;
--
    -- ===============================================
    -- �G���[���b�Z�[�W�̏o��
    -- ===============================================
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
      -- �G���[�������Ńf�[�^�����擾�̏ꍇ�A�e�����͈ȉ��ɓ��ꂵ�ďo�͂���
      IF ( gn_target_cnt = 0 ) THEN
        gn_target_cnt := 0;
        gn_normal_cnt := 0;
        gn_error_cnt  := 1;
      END IF;
    END IF;
--
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -- ===============================================
    -- �����̏o��
    -- ===============================================
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => cv_msg_90000
                    ,iv_token_name1  => cv_tok_count
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => cv_msg_90001
                    ,iv_token_name1  => cv_tok_count
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => cv_msg_90002
                    ,iv_token_name1  => cv_tok_count
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    -- ===============================================
    --�I�����b�Z�[�W
    -- ===============================================
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
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
END XXCMM005A04C;
/
