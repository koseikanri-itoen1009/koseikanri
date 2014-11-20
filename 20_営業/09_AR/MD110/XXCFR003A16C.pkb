CREATE OR REPLACE PACKAGE BODY XXCFR003A16C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR003A16C(body)
 * Description      : �W���������Ŕ�
 * MD.050           : MD050_CFR_003_A16_�W���������Ŕ�
 * MD.070           : MD050_CFR_003_A16_�W���������Ŕ�
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   p ��������                                (A-1)
 *  get_profile_value      p �v���t�@�C���擾����                    (A-2)
 *  chk_inv_all_dept       P �S�Џo�͌����`�F�b�N����                (A-3)
 *  insert_work_table      p ���[�N�e�[�u���f�[�^�o�^                (A-4)
 *  chk_account_data       p �������擾�`�F�b�N                    (A-5)
 *  start_svf_api          p SVF�N��                                 (A-6)
 *  delete_work_table      p ���[�N�e�[�u���f�[�^�폜                (A-7)
 *  submain                p ���C�������v���V�[�W��
 *  main                   p �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/11    1.00 SCS ��� �b      ����쐬
 *  2009/03/05    1.1  SCS ��� �b      ���ʊ֐������[�X�ɔ���SVF�N�������ύX�Ή�
 *                                      ���ԃe�[�u���f�[�^�폜�����R�����g�A�E�g�폜�Ή�
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; -- ����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   -- �x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  -- �ُ�:2
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
  cv_msg_pnt                CONSTANT VARCHAR2(3) := ',';
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
--
  lock_expt             EXCEPTION;      -- ���b�N(�r�W�[)�G���[
  file_not_exists_expt  EXCEPTION;      -- �t�@�C�����݃G���[
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFR003A16C'; -- �p�b�P�[�W��
  cv_msg_kbn_cmn     CONSTANT VARCHAR2(5)   := 'XXCMN';
  cv_msg_kbn_ccp     CONSTANT VARCHAR2(5)   := 'XXCCP';
  cv_msg_kbn_cfr     CONSTANT VARCHAR2(5)   := 'XXCFR';
--
  -- ���b�Z�[�W�ԍ�
  cv_msg_003a16_001  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
  cv_msg_003a16_002  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
  cv_msg_003a16_003  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
  cv_msg_003a16_004  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90003'; -- �X�L�b�v�������b�Z�[�W
  cv_msg_003a16_005  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
  cv_msg_003a16_006  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
  cv_msg_003a16_007  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N���b�Z�[�W
  cv_msg_003a16_008  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90007'; -- �G���[�I���ꕔ�������b�Z�[�W
  cv_msg_003a16_009  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00056'; -- �V�X�e���G���[���b�Z�[�W
--
  cv_msg_003a16_010  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00004'; -- �v���t�@�C���擾�G���[���b�Z�[�W
  cv_msg_003a16_011  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00003'; -- ���b�N�G���[���b�Z�[�W
  cv_msg_003a16_012  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00007'; -- �f�[�^�폜�G���[���b�Z�[�W
  cv_msg_003a16_013  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00016'; -- �e�[�u���}���G���[
  cv_msg_003a16_014  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00023'; -- ���[�O�����b�Z�[�W
  cv_msg_003a16_015  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00011'; -- API�G���[���b�Z�[�W
  cv_msg_003a16_016  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00024'; -- ���[�O�����O���b�Z�[�W
  cv_msg_003a16_017  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00015'; -- �l�擾�G���[���b�Z�[�W
  cv_msg_003a16_018  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00038'; -- �U���������o�^���b�Z�[�W
  cv_msg_003a16_019  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00051'; -- �U���������o�^���
  cv_msg_003a16_020  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00052'; -- �U���������o�^�������b�Z�[�W
  cv_msg_003a16_021  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00010'; -- ���ʊ֐��G���[���b�Z�[�W
--
-- �g�[�N��
  cv_tkn_prof        CONSTANT VARCHAR2(15) := 'PROF_NAME';        -- �v���t�@�C����
  cv_tkn_api         CONSTANT VARCHAR2(15) := 'API_NAME';         -- API��
  cv_tkn_table       CONSTANT VARCHAR2(15) := 'TABLE';            -- �e�[�u����
  cv_tkn_comment     CONSTANT VARCHAR2(15) := 'COMMENT';          -- �R�����g
  cv_tkn_get_data    CONSTANT VARCHAR2(30) := 'DATA';             -- �擾�Ώۃf�[�^
  cv_tkn_ac_code     CONSTANT VARCHAR2(30) := 'ACCOUNT_CODE';     -- �ڋq�R�[�h
  cv_tkn_ac_name     CONSTANT VARCHAR2(30) := 'ACCOUNT_NAME';     -- �ڋq��
  cv_tkn_lc_name     CONSTANT VARCHAR2(30) := 'KYOTEN_NAME';      -- ���_��
  cv_tkn_count       CONSTANT VARCHAR2(30) := 'COUNT';            -- �J�E���g��
  cv_tkn_func        CONSTANT VARCHAR2(15) := 'FUNC_NAME';        -- ���ʊ֐���
--
  -- ���{�ꎫ��
  cv_dict_date       CONSTANT VARCHAR2(100) := 'CFR000A00003';    -- ���t�p�����[�^�ϊ��֐�
  cv_dict_svf        CONSTANT VARCHAR2(100) := 'CFR000A00004';    -- SVF�N��
--
  cv_dict_ymd4       CONSTANT VARCHAR2(100) := 'CFR000A00007';    -- YYYY"�N"MM"��"DD"��"
  cv_dict_ymd2       CONSTANT VARCHAR2(100) := 'CFR000A00008';    -- YY"�N"MM"��"DD"��"
  cv_dict_year       CONSTANT VARCHAR2(100) := 'CFR000A00009';    -- �N
  cv_dict_month      CONSTANT VARCHAR2(100) := 'CFR000A00010';    -- ��
  cv_dict_bank       CONSTANT VARCHAR2(100) := 'CFR000A00011';    -- ��s
  cv_dict_central    CONSTANT VARCHAR2(100) := 'CFR000A00015';    -- �{�X
  cv_dict_branch     CONSTANT VARCHAR2(100) := 'CFR000A00012';    -- �x�X
  cv_dict_account    CONSTANT VARCHAR2(100) := 'CFR000A00013';    -- ����
  cv_dict_current    CONSTANT VARCHAR2(100) := 'CFR000A00014';    -- ����
  cv_dict_zip_mark   CONSTANT VARCHAR2(100) := 'CFR000A00016';    -- ��
  cv_dict_bank_damy  CONSTANT VARCHAR2(100) := 'CFR000A00017';    -- ��s�_�~�[�R�[�h
  cv_dict_date_func  CONSTANT VARCHAR2(100) := 'CFR000A00002';    -- �c�Ɠ��t�擾�֐�
--
  --�v���t�@�C��
  cv_set_of_bks_id   CONSTANT VARCHAR2(30) := 'GL_SET_OF_BKS_ID'; -- ��v����ID
  cv_org_id          CONSTANT VARCHAR2(30) := 'ORG_ID';           -- �g�DID
--
  -- �g�pDB��
  cv_table           CONSTANT VARCHAR2(100) := 'XXCFR_REP_ST_INVOICE_EX_TAX';  -- ���[�N�e�[�u����
--
  -- �������^�C�v
  cv_invoice_type    CONSTANT VARCHAR2(1)   := 'S';                        -- �eS�f(�W��������)
--
  -- �t�@�C���o��
  cv_file_type_out   CONSTANT VARCHAR2(10)  := 'OUTPUT';    -- ���b�Z�[�W�o��
  cv_file_type_log   CONSTANT VARCHAR2(10)  := 'LOG';       -- ���O�o��
--
  cv_enabled_yes     CONSTANT VARCHAR2(1)   := 'Y';         -- �L���t���O�i�x�j
--
  cv_status_yes      CONSTANT VARCHAR2(1)   := '1';         -- �L���X�e�[�^�X�i1�F�L���j
  cv_status_no       CONSTANT VARCHAR2(1)   := '0';         -- �L���X�e�[�^�X�i0�F�����j
--
  cv_format_date_ymd    CONSTANT VARCHAR2(8)  := 'YYYYMMDD';             -- ���t�t�H�[�}�b�g�i�N�����j
  cv_format_date_ymdhns CONSTANT VARCHAR2(16) := 'YYYYMMDDHH24MISS';     -- ���t�t�H�[�}�b�g�i�N���������b
  cv_format_date_ymds   CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';           -- ���t�t�H�[�}�b�g�i�N�����X���b�V���t�j
  cv_format_date_ymds2  CONSTANT VARCHAR2(8)  := 'YY/MM/DD';             -- ���t�t�H�[�}�b�g�i2���N�����X���b�V���t�j
--
  cd_max_date           CONSTANT DATE         := TO_DATE('9999/12/31',cv_format_date_ymds);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  gd_target_date        DATE;                                      -- �p�����[�^�D�����i�f�[�^�^�ϊ��p�j
  gn_org_id             NUMBER;                                    -- �g�DID
  gn_set_of_bks_id      NUMBER;                                    -- ��v����ID
  gt_user_dept          per_all_people_f.attribute28%TYPE := NULL; -- ���O�C�����[�U��������
  gv_inv_all_flag       VARCHAR2(1) := '0';                        -- �S�Џo�͌�����������t���O
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_target_date         IN      VARCHAR2,         -- ����
    iv_ar_code1            IN      VARCHAR2,         -- ���|�R�[�h�P(������)
    ov_errbuf              OUT     VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode             OUT     VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg              OUT     VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    --==============================================================
    --�R���J�����g�p�����[�^�o��
    --==============================================================
--
    -- �p�����[�^�D������DATE�^�ɕϊ�����
    gd_target_date := TRUNC(xxcfr_common_pkg.get_date_param_trans(iv_target_date));
--
    IF (gd_target_date IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_003a16_021 -- ���ʊ֐��G���[
                                                    ,cv_tkn_func       -- �g�[�N��'FUNC_NAME'
                                                    ,xxcfr_common_pkg.lookup_dictionary(cv_msg_kbn_cfr
                                                                                       ,cv_dict_date_func))
                                                    -- �c�Ɠ��t�擾�֐�
                          ,1
                          ,5000);
      RAISE global_api_expt;
    END IF;
--
    -- ���O�o��
    xxcfr_common_pkg.put_log_param( iv_which        => cv_file_type_log             -- ���O�o��
                                   ,iv_conc_param1  => TO_CHAR(gd_target_date
                                                              ,cv_format_date_ymds) -- �R���J�����g�p�����[�^�P
                                   ,iv_conc_param2  => iv_ar_code1                  -- �R���J�����g�p�����[�^�Q
                                   ,ov_errbuf       => ov_errbuf                    -- �G���[�E���b�Z�[�W
                                   ,ov_retcode      => ov_retcode                   -- ���^�[���E�R�[�h
                                   ,ov_errmsg       => ov_errmsg);                  -- ���[�U�[�E�G���[�E���b�Z�[�W 
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
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
   * Procedure Name   : get_profile_value
   * Description      : �v���t�@�C���擾����(A-2)
   ***********************************************************************************/
  PROCEDURE get_profile_value(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_profile_value'; -- �v���O������
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
    -- �v���t�@�C�������v����ID�擾
    gn_set_of_bks_id      := FND_PROFILE.VALUE(cv_set_of_bks_id);
--
    -- �擾�G���[��
    IF (gn_set_of_bks_id IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_003a16_010 -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof       -- �g�[�N��'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_set_of_bks_id))
                                                     -- ��v����ID
                          ,1
                          ,5000);
      RAISE global_api_expt;
    END IF;
--
    -- �v���t�@�C������g�DID�擾
    gn_org_id      := FND_PROFILE.VALUE(cv_org_id);
--
    -- �擾�G���[��
    IF (gn_org_id IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_003a16_010 -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof       -- �g�[�N��'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_org_id))
                                                     -- �g�DID
                          ,1
                          ,5000);
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_profile_value;
--
  /**********************************************************************************
   * Procedure Name   : chk_inv_all_dept
   * Description      : �S�Џo�͌����`�F�b�N���� (A-3)
   ***********************************************************************************/
  PROCEDURE chk_inv_all_dept(
    ov_errbuf           OUT VARCHAR2,   -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,   -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_inv_all_dept'; -- �v���O������
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
    cv_person_dff_name CONSTANT VARCHAR2(10)  := 'PER_PEOPLE';   -- �]�ƈ��}�X�^DFF��
    cv_peson_dff_att28 CONSTANT VARCHAR2(11)  := 'ATTRIBUTE28';  -- �]�ƈ��}�X�^DFF28(��������)�J������
--
    -- *** ���[�J���ϐ� ***
    lv_token_value fnd_descr_flex_col_usage_vl.end_user_column_name%TYPE; -- ��������擾�G���[���̃��b�Z�[�W�g�[�N���l
    lv_valid_flag  VARCHAR2(1) := 'N'; -- �L���t���O
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J����O ***
    get_user_dept_expt EXCEPTION;  -- ���[�U��������擾��O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���O�C�����[�U��������擾����
    gt_user_dept := xxcfr_common_pkg.get_user_dept(cn_created_by -- ���[�UID
                                                  ,SYSDATE);     -- �擾���t
--
    -- �擾�G���[��
    IF (gt_user_dept IS NULL) THEN
      RAISE get_user_dept_expt;
    END IF;
--
    -- �S�Џo�͌����������唻�菈��
      lv_valid_flag := xxcfr_common_pkg.chk_invoice_all_dept(gt_user_dept      -- ��������R�[�h
                                                            ,cv_invoice_type); -- �������^�C�v
      IF lv_valid_flag = cv_enabled_yes THEN
        gv_inv_all_flag := '1';
      END IF;
--
  EXCEPTION
--
    -- *** �������傪�擾�ł��Ȃ��ꍇ ***
    WHEN get_user_dept_expt THEN
      BEGIN
        SELECT ffcu.end_user_column_name
        INTO lv_token_value
        FROM fnd_descr_flex_col_usage_vl ffcu
        WHERE ffcu.descriptive_flexfield_name = cv_person_dff_name
        AND ffcu.application_column_name = cv_peson_dff_att28;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_003a16_017 -- �l�擾�G���[
                                                    ,cv_tkn_get_data   -- �g�[�N��'DATA'
                                                    ,lv_token_value)   -- '���O�C�����[�U��������'
                          ,1
                          ,5000);
      lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf
                           ,1
                           ,5000);
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
  END chk_inv_all_dept;
--
  /**********************************************************************************
   * Procedure Name   : insert_work_table
   * Description      : ���[�N�e�[�u���f�[�^�o�^ (A-4)
   ***********************************************************************************/
  PROCEDURE insert_work_table(
    iv_target_date          IN   VARCHAR2,            -- ����
    iv_ar_code1             IN   VARCHAR2,            -- ���|�R�[�h�P(������)
    ov_errbuf               OUT  VARCHAR2,            -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT  VARCHAR2,            -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT  VARCHAR2)            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_work_table'; -- �v���O������
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
    -- ����ŋ敪
    cv_syohizei_kbn_te  CONSTANT VARCHAR2(1)  := '1';                      -- �O��
    cv_syohizei_kbn_nt  CONSTANT VARCHAR2(1)  := '4';                      -- ��ې�
    -- �������o�͋敪
    cv_inv_prt_type     CONSTANT VARCHAR2(1)  := '1';                       -- 1.�ɓ����W��
--
    -- *** ���[�J���ϐ� ***
    -- �������`�p�ϐ�
    lv_format_date_jpymd4  VARCHAR2(25); -- YYYY"�N"MM"��"DD"��"
    lv_format_date_jpymd2  VARCHAR2(25); -- YY"�N"MM"��"DD"��"
    lv_format_date_year    VARCHAR2(10); -- �N
    lv_format_date_month   VARCHAR2(10); -- ��
    lv_format_date_bank    VARCHAR2(10); -- ��s
    lv_format_date_central VARCHAR2(10); -- �{�X
    lv_format_date_branch  VARCHAR2(10); -- �x�X
    lv_format_date_account VARCHAR2(10); -- ����
    lv_format_date_current VARCHAR2(10); -- ����
    lv_format_zip_mark     VARCHAR2(10); -- ��
    lv_format_bank_dummy   VARCHAR2(10); -- D%
--
    ln_target_cnt   NUMBER := 0;    -- �Ώی���
    ln_loop_cnt     NUMBER;         -- ���[�v�J�E���^
--
    lv_no_data_msg  VARCHAR2(5000); -- ���[�O�����b�Z�[�W
    lv_func_status  VARCHAR2(1);    -- SVF���[���ʊ֐�(0���o�̓��b�Z�[�W)�I���X�e�[�^�X
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
    -- ====================================================
    -- ���{�ꕶ����擾
    -- ====================================================
    lv_format_date_jpymd4 := SUBSTRB(xxcfr_common_pkg.lookup_dictionary( cv_msg_kbn_cfr  -- 'XXCFR'
                                                                        ,cv_dict_ymd4 )  -- YYYY"�N"MM"��"DD"��"
                                    ,1
                                    ,5000);
    lv_format_date_jpymd2 := SUBSTRB(xxcfr_common_pkg.lookup_dictionary( cv_msg_kbn_cfr  -- 'XXCFR'
                                                                        ,cv_dict_ymd2 )  -- YY"�N"MM"��"DD"��"
                                    ,1
                                    ,5000);
    lv_format_date_year := SUBSTRB(xxcfr_common_pkg.lookup_dictionary( cv_msg_kbn_cfr  -- 'XXCFR'
                                                                      ,cv_dict_year )  -- �N
                                  ,1
                                  ,5000);
    lv_format_date_month := SUBSTRB(xxcfr_common_pkg.lookup_dictionary( cv_msg_kbn_cfr   -- 'XXCFR'
                                                                       ,cv_dict_month )  -- ��
                                   ,1
                                   ,5000);
    lv_format_date_bank := SUBSTRB(xxcfr_common_pkg.lookup_dictionary( cv_msg_kbn_cfr  -- 'XXCFR'
                                                                      ,cv_dict_bank )  -- ��s
                                  ,1
                                  ,5000);
    lv_format_date_central := SUBSTRB(xxcfr_common_pkg.lookup_dictionary( cv_msg_kbn_cfr    -- 'XXCFR'
                                                                        ,cv_dict_central )  -- �{�X
                                     ,1
                                     ,5000);
    lv_format_date_branch := SUBSTRB(xxcfr_common_pkg.lookup_dictionary( cv_msg_kbn_cfr    -- 'XXCFR'
                                                                        ,cv_dict_branch )  -- �x�X
                                     ,1
                                     ,5000);
    lv_format_date_account := SUBSTRB(xxcfr_common_pkg.lookup_dictionary( cv_msg_kbn_cfr    -- 'XXCFR'
                                                                         ,cv_dict_account ) -- ����
                                     ,1
                                     ,5000);
    lv_format_date_current := SUBSTRB(xxcfr_common_pkg.lookup_dictionary( cv_msg_kbn_cfr    -- 'XXCFR'
                                                                         ,cv_dict_current ) -- ����
                                    ,1
                                    ,5000);
    lv_format_zip_mark := SUBSTRB(xxcfr_common_pkg.lookup_dictionary( cv_msg_kbn_cfr     -- 'XXCFR'
                                                                     ,cv_dict_zip_mark ) -- ��
                                  ,1
                                  ,5000);
    lv_format_bank_dummy := SUBSTRB(xxcfr_common_pkg.lookup_dictionary( cv_msg_kbn_cfr     -- 'XXCFR'
                                                                       ,cv_dict_bank_damy ) -- D
                                   ,1
                                   ,5000);
--
    -- ====================================================
    -- ���[�O�����b�Z�[�W�擾
    -- ====================================================
    lv_no_data_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr      -- 'XXCFR'
                                                       ,cv_msg_003a16_014 ) -- ���[�O�����b�Z�[�W
                              ,1
                              ,5000);
--
    -- ====================================================
    -- ���[�N�e�[�u���ւ̓o�^
    -- ====================================================
    BEGIN
--
      INSERT INTO xxcfr_rep_st_invoice_ex_tax(
        report_id               , -- ���[�h�c
        issue_date              , -- ���s��
        zip_code                , -- �X�֔ԍ�
        send_address1           , -- �Z���P
        send_address2           , -- �Z���Q
        send_address3           , -- �Z���R
        bill_cust_code          , -- �ڋq�R�[�h(�\�[�g���Q)
        bill_cust_name          , -- �ڋq��
        location_name           , -- �S�����_��
        phone_num               , -- �d�b�ԍ�
        target_date             , -- �Ώ۔N��
        payment_cust_code       , -- ���|�R�[�h�P�i�������j(�\�[�g���P)
        ar_concat_text          , -- ���|�Ǘ��R�[�h�A��������(�e���ڂ̊ԂɃX�y�[�X��}��)
        ex_tax_charge           , -- ���������グ�z
        tax_sum                 , -- ����œ�
        total_charge            , -- ���������z(�ō�) 
        payment_due_date        , -- �����\���
        bank_account            , -- �U���������
        slip_date               , -- �`�[���t(�\�[�g���R)
        slip_num                , -- �`�[No(�\�[�g���S)
        slip_sum                , -- �`�[���z(�`�[�ԍ��P�ʂŏW�v�����l)
        data_empty_message      , -- 0�����b�Z�[�W
        created_by              , -- �쐬��
        creation_date           , -- �쐬��
        last_updated_by         , -- �ŏI�X�V��
        last_update_date        , -- �ŏI�X�V��
        last_update_login       , -- �ŏI�X�V���O�C��
        request_id              , -- �v��ID
        program_application_id  , -- �A�v���P�[�V����ID
        program_id              , -- �R���J�����g�E�v���O����ID
        program_update_date     ) -- �v���O�����X�V��
      SELECT cv_pkg_name                                                        report_id        , -- ���[�h�c
             TO_CHAR(xih.inv_creation_date,lv_format_date_jpymd4)               issue_date       , -- ���s��
             DECODE(xih.postal_code,
                    NULL,NULL,
                    lv_format_zip_mark||SUBSTR(xih.postal_code,1,3)||'-'||
                    SUBSTR(xih.postal_code,4,4))                                zip_code         , -- �X�֔ԍ�
             xih.send_address1                                                  send_address1    , -- �Z���P
             xih.send_address2                                                  send_address2    , -- �Z���Q
             xih.send_address3                                                  send_address3    , -- �Z���R
             xih.bill_cust_code                                                 bill_cust_code   , -- �ڋq�R�[�h(�\�[�g���Q)
             xih.send_to_name                                                   bill_cust_name   , -- �ڋq��
             xih.bill_location_name                                             location_name    , -- �S�����_��
             xih.agent_tel_num                                                  phone_num        , -- �d�b�ԍ�
             SUBSTR(xih.object_month,1,4)||lv_format_date_year||
             SUBSTR(xih.object_month,5,2)||lv_format_date_month                 target_date      , -- �Ώ۔N��
             xih.payment_cust_code                                              payment_cust_code,
                                                                                -- ���|�R�[�h�P�i�������j(�\�[�g���P)
             xih.payment_cust_code||' '||xih.bill_cust_code||' '||xih.term_name ar_concat_text   ,
                                                                                -- ���|�Ǘ��R�[�h�A��������
             xih.inv_amount_no_tax                                              ex_tax_charge    , -- �Ŕ��������z���v
             xih.tax_amount_sum                                                 tax_sum          , -- �Ŋz���v
             xih.inv_amount_includ_tax                                          total_charge     , -- ���������z(�ō�)
             TO_CHAR(xih.payment_date, lv_format_date_jpymd2)                   payment_due_date , -- �����\���
             CASE
             WHEN account.bank_account_num IS NULL THEN
               NULL
             ELSE
               DECODE(SUBSTR(account.bank_number,1,1),
               lv_format_bank_dummy,NULL,                                       -- �_�~�[��s�̏ꍇ��NULL
               CASE WHEN TO_NUMBER(account.bank_number)<1000  THEN
                 CASE WHEN INSTR(account.bank_name,lv_format_date_bank)>0 THEN
                   account.bank_name
                 ELSE
                   account.bank_name ||lv_format_date_bank
                 END
               ELSE
                account.bank_name 
               END||' '||                                                       -- ��s��
               CASE WHEN INSTR(account.bank_branch_name
                              ,lv_format_date_central)>0 THEN
                 account.bank_branch_name
               ELSE
                 account.bank_branch_name||lv_format_date_branch 
               END||' '||                                                       -- �x�X��
               DECODE( account.bank_account_type,
                       1,lv_format_date_account,
                       2,lv_format_date_current,
                       account.bank_account_type) ||' '||                       -- �������
               account.bank_account_num ||' '||                                 -- �����ԍ�
               account.account_holder_name||' '||                               -- �������`�l
               account.account_holder_name_alt)                                 -- �������`�l�J�i��
             END                                                                account_data     , -- �U���������
             TO_CHAR(DECODE(xil.acceptance_date,
                            NULL,xil.delivery_date,
                            xil.acceptance_date),
                     cv_format_date_ymds2)                                      slip_date        , -- �`�[���t(�\�[�g���R)
             xil.slip_num                                                       slip_num         , -- �`�[No(�\�[�g���S)
             SUM(xil.ship_amount)                                               slip_sum         , -- �`�[���z(�Ŕ��z)
             NULL                                                               data_empty_message,-- 0�����b�Z�[�W
             cn_created_by                                                      created_by,             -- �쐬��
             cd_creation_date                                                   creation_date,          -- �쐬��
             cn_last_updated_by                                                 last_updated_by,        -- �ŏI�X�V��
             cd_last_update_date                                                last_update_date,       -- �ŏI�X�V��
             cn_last_update_login                                               last_update_login,      -- �ŏI�X�V���O�C��
             cn_request_id                                                      request_id,             -- �v��ID
             cn_program_application_id                                          program_application_id, -- �A�v���P�[�V����ID
             cn_program_id                                                      program_id,
                                                                                -- �R���J�����g�E�v���O����ID
             cd_program_update_date                                             program_update_date     -- �v���O�����X�V��
      FROM xxcfr_invoice_headers          xih  , --�����w�b�_
           xxcfr_invoice_lines            xil  , -- ��������
           (SELECT rcrm.customer_id             customer_id,
                   abb.bank_number              bank_number,
                   abb.bank_name                bank_name,
                   abb.bank_branch_name         bank_branch_name,
                   abaa.bank_account_type       bank_account_type,
                   abaa.bank_account_num        bank_account_num,
                   abaa.account_holder_name     account_holder_name,
                   abaa.account_holder_name_alt account_holder_name_alt
            FROM ra_cust_receipt_methods        rcrm , --�x�����@���
                 ar_receipt_method_accounts_all arma , --AR�x�����@����
                 ap_bank_accounts_all           abaa , --��s����
                 ap_bank_branches               abb    --��s�x�X
            WHERE rcrm.primary_flag = cv_enabled_yes
              AND gd_target_date BETWEEN rcrm.start_date AND NVL(rcrm.end_date ,cd_max_date)
              AND rcrm.site_use_id IS NOT NULL
              AND rcrm.receipt_method_id = arma.receipt_method_id(+)
              AND arma.bank_account_id = abaa.bank_account_id(+)
              AND abaa.bank_branch_id = abb.bank_branch_id(+)
              AND arma.org_id = gn_org_id
              AND abaa.org_id = gn_org_id             ) account , -- ��s�����r���[
           xxcfr_bill_customers_v         xbcv                    --������ڋq�r���[
      WHERE xih.invoice_id = xil.invoice_id                       -- �ꊇ������ID
        AND xih.cutoff_date = gd_target_date                      -- �p�����[�^�D����
        AND EXISTS (SELECT 'X'
                    FROM xxcfr_bill_customers_v         xb        --������ڋq�r���[
                    WHERE xih.bill_cust_code = xb.bill_customer_code
                      AND (xb.tax_div = cv_syohizei_kbn_te OR
                           xb.tax_div = cv_syohizei_kbn_nt)       -- �O��OR��ې�
                      AND xb.inv_prt_type = cv_inv_prt_type       -- 1.�ɓ����W��
                      AND xb.cons_inv_flag = cv_enabled_yes       -- (�L��)
                      AND (xb.receiv_code1 = NVL(iv_ar_code1,xb.receiv_code1 ) )
                      AND ( (gv_inv_all_flag = cv_status_yes) OR
                            (gv_inv_all_flag = cv_status_no AND
                             xb.bill_base_code = gt_user_dept) ) )
        AND xih.bill_cust_code = xbcv.bill_customer_code
        AND xbcv.pay_customer_id = account.customer_id(+)
        AND xih.set_of_books_id = gn_set_of_bks_id
        AND xih.org_id = gn_org_id
      GROUP BY cv_pkg_name,
               xih.inv_creation_date,
               DECODE(xih.postal_code,
                           NULL,NULL,
                           lv_format_zip_mark||SUBSTR(xih.postal_code,1,3)||'-'||
                           SUBSTR(xih.postal_code,4,4)),
               xih.send_address1,
               xih.send_address2,
               xih.send_address3,
               xih.bill_cust_code,
               xih.send_to_name,
               xih.bill_location_name,
               xih.agent_tel_num,
               xih.object_month,
               xih.payment_cust_code,
               xih.payment_cust_code||' '||xih.bill_cust_code||' '||xih.term_name,
               xih.inv_amount_no_tax , -- �Ŕ��������z���v
               xih.tax_amount_sum,     -- �Ŋz���v
               xih.inv_amount_includ_tax,-- �ō��������z���v
               xih.payment_date,
               CASE
               WHEN account.bank_account_num IS NULL THEN
                 NULL
               ELSE
                 DECODE(SUBSTR(account.bank_number,1,1),
                 lv_format_bank_dummy,NULL,                                       -- �_�~�[��s�̏ꍇ��NULL
                 CASE WHEN TO_NUMBER(account.bank_number)<1000  THEN
                   CASE WHEN INSTR(account.bank_name,lv_format_date_bank)>0 THEN
                     account.bank_name
                   ELSE
                     account.bank_name ||lv_format_date_bank
                   END
                 ELSE
                  account.bank_name 
                 END||' '||                                                       -- ��s��
                 CASE WHEN INSTR(account.bank_branch_name
                                ,lv_format_date_central)>0 THEN
                   account.bank_branch_name
                 ELSE
                   account.bank_branch_name||lv_format_date_branch 
                 END||' '||                                                       -- �x�X��
                 DECODE( account.bank_account_type,
                         1,lv_format_date_account,
                         2,lv_format_date_current,
                         account.bank_account_type) ||' '||                       -- �������
                 account.bank_account_num ||' '||                                 -- �����ԍ�
                 account.account_holder_name||' '||                               -- �������`�l
                 account.account_holder_name_alt)                                 -- �������`�l�J�i��
               END,
               TO_CHAR(DECODE(xil.acceptance_date,
                              NULL,xil.delivery_date,
                              xil.acceptance_date),
               cv_format_date_ymds2),
               xil.slip_num;
--
      gn_target_cnt := SQL%ROWCOUNT;
--
      -- �o�^�f�[�^���P�������݂��Ȃ��ꍇ�A�O�����b�Z�[�W���R�[�h�ǉ�
      IF ( gn_target_cnt = 0 ) THEN
--
        INSERT INTO xxcfr_rep_st_invoice_ex_tax (
          data_empty_message           , -- 0�����b�Z�[�W
          created_by                   , -- �쐬��
          creation_date                , -- �쐬��
          last_updated_by              , -- �ŏI�X�V��
          last_update_date             , -- �ŏI�X�V��
          last_update_login            , -- �ŏI�X�V���O�C��
          request_id                   , -- �v��ID
          program_application_id       , -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          program_id                   , -- �R���J�����g�E�v���O����ID
          program_update_date          ) -- �v���O�����X�V��
        VALUES (
          lv_no_data_msg               , -- 0�����b�Z�[�W
          cn_created_by                , -- �쐬��
          cd_creation_date             , -- �쐬��
          cn_last_updated_by           , -- �ŏI�X�V��
          cd_last_update_date          , -- �ŏI�X�V��
          cn_last_update_login         , -- �ŏI�X�V���O�C��
          cn_request_id                , -- �v��ID
          cn_program_application_id    , -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          cn_program_id                , -- �R���J�����g�E�v���O����ID
          cd_program_update_date       );-- �v���O�����X�V��
--
        -- �x���I��
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
                                                       ,cv_msg_003a16_016 )  -- �Ώۃf�[�^0���x��
                             ,1
                             ,5000);
        ov_errmsg  := lv_errmsg;
--
        ov_retcode := cv_status_warn;
--
      END IF;
--
    EXCEPTION
      WHEN OTHERS THEN  -- �o�^���G���[
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
                                                       ,cv_msg_003a16_013    -- �e�[�u���o�^�G���[
                                                       ,cv_tkn_table         -- �g�[�N��'TABLE'
                                                       ,xxcfr_common_pkg.get_table_comment(cv_table))
                                                      -- �W���������Ŕ����[���[�N�e�[�u��
                             ,1
                             ,5000);
        lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
        raise global_api_expt;
    END;
--
    -- ���������̐ݒ�
    gn_normal_cnt := gn_target_cnt;
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
  END insert_work_table;
--
  /**********************************************************************************
   * Procedure Name   : chk_account_data
   * Description      : �������擾�`�F�b�N (A-5)
   ***********************************************************************************/
  PROCEDURE chk_account_data(
    ov_errbuf               OUT  VARCHAR2,            -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT  VARCHAR2,            -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT  VARCHAR2)            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_account_data'; -- �v���O������
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
    ln_target_cnt    NUMBER;         -- �Ώی���
    ln_loop_cnt      NUMBER;         -- ���[�v�J�E���^
    lv_warn_msg      VARCHAR2(5000);
    lv_bill_data_msg VARCHAR2(5000);
    lv_warn_bill_num VARCHAR2(5000);
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- ���o
    CURSOR sel_no_account_data_cur
    IS
      SELECT xrsi.bill_cust_code  lv_bill_cust_code ,
             xrsi.bill_cust_name  lv_bill_cust_name ,
             xrsi.location_name   lv_location_name
      FROM xxcfr_rep_st_invoice_ex_tax  xrsi
      WHERE xrsi.request_id  = cn_request_id  -- �v��ID
        AND bank_account IS NULL
      GROUP BY xrsi.bill_cust_code ,
               xrsi.bill_cust_name,
               xrsi.location_name
      ORDER BY xrsi.bill_cust_code ASC;
--
    TYPE g_sel_no_account_data_ttype IS TABLE OF sel_no_account_data_cur%ROWTYPE INDEX BY PLS_INTEGER;
    lt_sel_no_account_tab    g_sel_no_account_data_ttype;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���������s�Ώۃf�[�^�����݂���ꍇ�ȉ��̏��������s
    IF ( gn_target_cnt > 0 ) THEN
--
      -- �J�[�\���I�[�v��
      OPEN sel_no_account_data_cur;
--
      -- �f�[�^�̈ꊇ�擾
      FETCH sel_no_account_data_cur BULK COLLECT INTO lt_sel_no_account_tab;
--
      -- ���������̃Z�b�g
      ln_target_cnt := lt_sel_no_account_tab.COUNT;
--
      -- �J�[�\���N���[�Y
      CLOSE sel_no_account_data_cur;
--
      -- �Ώۃf�[�^�����݂���ꍇ���O�ɏo�͂���
      IF (ln_target_cnt > 0) THEN
--
        -- �U���������o�^���b�Z�[�W�o��
        lv_warn_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cfr
                        ,iv_name         => cv_msg_003a16_018);
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => lv_warn_msg
        );
        -- �ڋq�R�[�h�E�ڋq�����b�Z�[�W�o��
        BEGIN
          <<data_loop>>
          FOR ln_loop_cnt IN 1..ln_target_cnt LOOP
            lv_bill_data_msg := xxccp_common_pkg.get_msg(
                                   iv_application  => cv_msg_kbn_cfr
                                  ,iv_name         => cv_msg_003a16_019
                                  ,iv_token_name1  => cv_tkn_ac_code
                                  ,iv_token_value1 => lt_sel_no_account_tab(ln_loop_cnt).lv_bill_cust_code
                                  ,iv_token_name2  => cv_tkn_ac_name
                                  ,iv_token_value2 => lt_sel_no_account_tab(ln_loop_cnt).lv_bill_cust_name
                                  ,iv_token_name3  => cv_tkn_lc_name
                                  ,iv_token_value3 => lt_sel_no_account_tab(ln_loop_cnt).lv_location_name);
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff   => lv_bill_data_msg --�G���[���b�Z�[�W
            );
          END LOOP data_loop;
        END;
        -- �ڋq�R�[�h�̌��������b�Z�[�W�o��
        lv_warn_bill_num := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cfr
                        ,iv_name         => cv_msg_003a16_020
                        ,iv_token_name1  => cv_tkn_count
                        ,iv_token_value1 => TO_CHAR(ln_target_cnt)
                       );
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => lv_warn_bill_num
        );
--
        --�P�s���s
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => '' --���[�U�[�E�G���[���b�Z�[�W
        );
--
        -- �x���I��
        ov_retcode := cv_status_warn;
--
      END IF;
    END IF;
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
  END chk_account_data;
--
  /**********************************************************************************
   * Procedure Name   : start_svf_api
   * Description      : SVF�N�� (A-6)
   ***********************************************************************************/
  PROCEDURE start_svf_api(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'start_svf_api'; -- �v���O������
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
    cv_svf_form_name  CONSTANT  VARCHAR2(20) := 'XXCFR003A16S.xml';  -- �t�H�[���l���t�@�C����
    cv_svf_query_name CONSTANT  VARCHAR2(20) := 'XXCFR003A16S.vrq';  -- �N�G���[�l���t�@�C����
    cv_output_mode    CONSTANT  VARCHAR2(1)   := '1';                -- �o�͋敪(=1�FPDF�o�́j
    cv_extension_pdf  CONSTANT  VARCHAR2(4)  := '.pdf';              -- �g���q�ipdf�j
--
    -- *** ���[�J���ϐ� ***
    lv_no_data_msg     VARCHAR2(5000);  -- ���[�O�����b�Z�[�W
    lv_svf_file_name   VARCHAR2(30);
    lv_file_id         VARCHAR2(30)  := NULL;
    lv_conc_name       VARCHAR2(30)  := NULL;
    lv_user_name       VARCHAR2(240) := NULL;
    lv_resp_name       VARCHAR2(240) := NULL;
    lv_svf_errmsg      VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
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
    -- =====================================================
    --  SVF�N�� (A-4)
    -- =====================================================
--
    -- �t�@�C�����̐ݒ�
    lv_svf_file_name := cv_pkg_name
                     || TO_CHAR ( cd_creation_date, cv_format_date_ymd )
                     || TO_CHAR ( cn_request_id )
                     || cv_extension_pdf;
--
    -- �R���J�����g���̐ݒ�
      lv_conc_name := cv_pkg_name;
--
    -- �t�@�C��ID�̐ݒ�
      lv_file_id := cv_pkg_name;
--
    xxccp_svfcommon_pkg.submit_svf_request(
       ov_errbuf       => lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_svf_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      ,iv_conc_name    => lv_conc_name          -- �R���J�����g��
      ,iv_file_name    => lv_svf_file_name      -- �o�̓t�@�C����
      ,iv_file_id      => lv_file_id            -- ���[ID
      ,iv_output_mode  => cv_output_mode        -- �o�͋敪(=1�FPDF�o�́j
      ,iv_frm_file     => cv_svf_form_name      -- �t�H�[���l���t�@�C����
      ,iv_vrq_file     => cv_svf_query_name     -- �N�G���[�l���t�@�C����
      ,iv_org_id       => gn_org_id             -- ORG_ID
      ,iv_user_name    => lv_user_name          -- ���O�C���E���[�U��
      ,iv_resp_name    => lv_resp_name          -- ���O�C���E���[�U�̐E�Ӗ�
      ,iv_doc_name     => NULL                  -- ������
      ,iv_printer_name => NULL                  -- �v�����^��
      ,iv_request_id   => cn_request_id         -- �v��ID
      ,iv_nodata_msg   => NULL                  -- �f�[�^�Ȃ����b�Z�[�W
    );
--
    -- SVF�N��API�̌Ăяo���̓G���[��
    IF (lv_retcode = cv_status_error) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
                                                     ,cv_msg_003a16_015    -- API�G���[
                                                     ,cv_tkn_api           -- �g�[�N��'API_NAME'
                                                     ,xxcfr_common_pkg.lookup_dictionary(
                                                        cv_msg_kbn_cfr
                                                       ,cv_dict_svf 
                                                      )  -- SVF�N��
                                                    )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg ||cv_msg_part|| lv_errbuf ||cv_msg_part|| lv_svf_errmsg;
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END start_svf_api;
--
  /**********************************************************************************
   * Procedure Name   : delete_work_table
   * Description      : ���[�N�e�[�u���f�[�^�폜 (A-7)
   ***********************************************************************************/
  PROCEDURE delete_work_table(
    ov_errbuf               OUT  VARCHAR2,            -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT  VARCHAR2,            -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT  VARCHAR2)            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_work_table'; -- �v���O������
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
    ln_target_cnt   NUMBER;         -- �Ώی���
    ln_loop_cnt     NUMBER;         -- ���[�v�J�E���^
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- ���o
    CURSOR del_rep_st_inv_ex_cur
    IS
      SELECT xrsi.rowid        ln_rowid
      FROM xxcfr_rep_st_invoice_ex_tax xrsi -- �W���������Ŕ����[���[�N�e�[�u��
      WHERE xrsi.request_id = cn_request_id  -- �v��ID
      FOR UPDATE NOWAIT;
--
    TYPE g_del_rep_st_inv_ex_ttype IS TABLE OF ROWID INDEX BY PLS_INTEGER;
    lt_del_rep_st_inv_ex_data    g_del_rep_st_inv_ex_ttype;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �J�[�\���I�[�v��
    OPEN del_rep_st_inv_ex_cur;
--
    -- �f�[�^�̈ꊇ�擾
    FETCH del_rep_st_inv_ex_cur BULK COLLECT INTO lt_del_rep_st_inv_ex_data;
--
    -- ���������̃Z�b�g
    ln_target_cnt := lt_del_rep_st_inv_ex_data.COUNT;
--
    -- �J�[�\���N���[�Y
    CLOSE del_rep_st_inv_ex_cur;
--
    -- �Ώۃf�[�^�����݂���ꍇ���R�[�h���폜����
    IF (ln_target_cnt > 0) THEN
      BEGIN
        <<data_loop>>
        FORALL ln_loop_cnt IN 1..ln_target_cnt
          DELETE FROM xxcfr_rep_st_invoice_ex_tax
          WHERE ROWID = lt_del_rep_st_inv_ex_data(ln_loop_cnt);
--
        -- �R�~�b�g���s
        COMMIT;
--
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                        ,cv_msg_003a16_012 -- �f�[�^�폜�G���[
                                                        ,cv_tkn_table         -- �g�[�N��'TABLE'
                                                        ,xxcfr_common_pkg.get_table_comment(cv_table))
                                                        -- �W���������Ŕ����[���[�N�e�[�u��
                              ,1
                              ,5000);
          lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
          RAISE global_api_expt;
      END;
--
    END IF;
--
  EXCEPTION
    WHEN lock_expt THEN  -- �e�[�u�����b�N�ł��Ȃ�����
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
                                                     ,cv_msg_003a16_011    -- �e�[�u�����b�N�G���[
                                                     ,cv_tkn_table         -- �g�[�N��'TABLE'
                                                     ,xxcfr_common_pkg.get_table_comment(cv_table))
                                                    -- �W���������Ŕ����[���[�N�e�[�u��
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
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
  END delete_work_table;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_target_date         IN      VARCHAR2,         -- ����
    iv_ar_code1            IN      VARCHAR2,         -- ���|�R�[�h�P(������)
    ov_errbuf              OUT     VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode             OUT     VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg              OUT     VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_errbuf_svf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode_svf VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg_svf  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- <�J�[�\����>
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    -- =====================================================
    --  ��������(A-1)
    -- =====================================================
    init(
       iv_target_date         -- ����
      ,iv_ar_code1            -- ���|�R�[�h�P(������)
      ,lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  �v���t�@�C���擾����(A-2)
    -- =====================================================
    get_profile_value(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  �S�Џo�͌����`�F�b�N����(A-3)
    -- =====================================================
    chk_inv_all_dept(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  ���[�N�e�[�u���f�[�^�o�^ (A-4)
    -- =====================================================
    insert_work_table(
       iv_target_date         -- ����
      ,iv_ar_code1            -- ���|�R�[�h�P(������)
      ,lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF  (lv_retcode = cv_status_warn) THEN
      ov_retcode := cv_status_warn;
      ov_errmsg  := lv_errmsg;
    END IF;
--
    -- =====================================================
    --  �������擾�`�F�b�N (A-5)
    -- =====================================================
    chk_account_data(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    ELSIF  (lv_retcode = cv_status_warn) THEN
      ov_retcode := cv_status_warn;
    END IF;
--
    -- =====================================================
    --  SVF�N�� (A-6)
    -- =====================================================
    start_svf_api(
       lv_errbuf_svf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode_svf            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg_svf);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- =====================================================
    --  ���[�N�e�[�u���f�[�^�폜 (A-7)
    -- =====================================================
    delete_work_table(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  SVF�N��API�G���[�`�F�b�N (A-8)
    -- =====================================================
    IF (lv_retcode_svf = cv_status_error) THEN
      --(�G���[����)
      lv_errmsg := lv_errmsg_svf;
      lv_errbuf := lv_errbuf_svf;
      RAISE global_process_expt;
    END IF;
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
    errbuf                 OUT     VARCHAR2,         -- �G���[�E���b�Z�[�W  #�Œ�#
    retcode                OUT     VARCHAR2,         -- �G���[�R�[�h        #�Œ�#
    iv_target_date         IN      VARCHAR2,         -- ����
    iv_ar_code1            IN      VARCHAR2          -- ���|�R�[�h�P(������)
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
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf       VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code VARCHAR2(100);   --���b�Z�[�W�R�[�h
--
    lv_errbuf2      VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
--
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_file_type_log
      ,ov_retcode => lv_retcode
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
       iv_target_date -- ����
      ,iv_ar_code1    -- ���|�R�[�h�P(������)
      ,lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      -- �G���[�������A�e�����͈ȉ��ɓ��ꂵ�ďo�͂���
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
--
--###########################  �Œ蕔 START   #####################################################
--
    --����łȂ��ꍇ�A�G���[�o��
    IF (lv_retcode <> cv_status_normal) THEN
      -- ���b�Z�[�W�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
    END IF;
--
    --�G���[�̏ꍇ�A�V�X�e���G���[���b�Z�[�W�o��
    IF (lv_retcode = cv_status_error) THEN
      -- �V�X�e���G���[���b�Z�[�W�o��
      lv_errbuf2 := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cfr
                      ,iv_name         => cv_msg_003a16_009
                     );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf2 --�G���[���b�Z�[�W
      );
      -- �G���[�o�b�t�@�̃��b�Z�[�W�A��
      lv_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      -- ���b�Z�[�W�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --���[�U�[�E�G���[���b�Z�[�W
      );
        --�P�s���s
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => '' --���[�U�[�E�G���[���b�Z�[�W
    );
    END IF;
--
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --�P�s���s
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => '' --���[�U�[�E�G���[���b�Z�[�W
    );
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
    fnd_file.put_line(
       which  => FND_FILE.LOG
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
END XXCFR003A16C;
/
