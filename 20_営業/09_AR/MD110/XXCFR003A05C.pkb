CREATE OR REPLACE PACKAGE BODY XXCFR003A05C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR003A05C(body)
 * Description      : �������z�ꗗ�\�o��
 * MD.050           : MD050_CFR_003_A05_�������z�ꗗ�\�o��
 * MD.070           : MD050_CFR_003_A05_�������z�ꗗ�\�o��
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   p ���̓p�����[�^�l���O�o�͏���            (A-1)
 *  get_profile_value      p �v���t�@�C���擾����                    (A-2)
 *  get_output_date        p �o�͓��擾����                          (A-3)
 *  chk_inv_all_dept       P �S�Џo�͌����`�F�b�N����                (A-4)
 *  insert_work_table      p ���[�N�e�[�u���f�[�^�o�^                (A-5)
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
 *  2009/04/14    1.2  SCS ��� �b      [��QT1_0533] �o�̓t�@�C�����ϐ�������I�[�o�[�t���[�Ή�
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
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFR003A05C'; -- �p�b�P�[�W��
  cv_msg_kbn_cmn     CONSTANT VARCHAR2(5)   := 'XXCMN';
  cv_msg_kbn_ccp     CONSTANT VARCHAR2(5)   := 'XXCCP';
  cv_msg_kbn_cfr     CONSTANT VARCHAR2(5)   := 'XXCFR';
--
  -- ���b�Z�[�W�ԍ�
  cv_msg_003a05_001  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00056'; -- �V�X�e���G���[���b�Z�[�W
--
  cv_msg_003a05_010  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00004'; -- �v���t�@�C���擾�G���[���b�Z�[�W
  cv_msg_003a05_011  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00003'; -- ���b�N�G���[���b�Z�[�W
  cv_msg_003a05_012  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00007'; -- �f�[�^�폜�G���[���b�Z�[�W
  cv_msg_003a05_013  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00016'; -- �e�[�u���}���G���[
  cv_msg_003a05_014  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00023'; -- ���[�O�����b�Z�[�W
  cv_msg_003a05_015  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00011'; -- API�G���[���b�Z�[�W
  cv_msg_003a05_016  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00024'; -- ���[�O�����O���b�Z�[�W
  cv_msg_003a05_017  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00015'; -- �l�擾�G���[���b�Z�[�W
  cv_msg_003a05_018  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00010'; -- ���ʊ֐��G���[���b�Z�[�W
--
-- �g�[�N��
  cv_tkn_prof        CONSTANT VARCHAR2(15) := 'PROF_NAME';        -- �v���t�@�C����
  cv_tkn_api         CONSTANT VARCHAR2(15) := 'API_NAME';         -- API��
  cv_tkn_table       CONSTANT VARCHAR2(15) := 'TABLE';            -- �e�[�u����
  cv_tkn_comment     CONSTANT VARCHAR2(15) := 'COMMENT';          -- �R�����g
  cv_tkn_get_data    CONSTANT VARCHAR2(30) := 'DATA';             -- �擾�Ώۃf�[�^
  cv_tkn_count       CONSTANT VARCHAR2(30) := 'COUNT';            -- �J�E���g��
  cv_tkn_func        CONSTANT VARCHAR2(15) := 'FUNC_NAME';        -- ���ʊ֐���
--
  -- ���{�ꎫ��
  cv_dict_date       CONSTANT VARCHAR2(100) := 'CFR000A00003';    -- ���t�p�����[�^�ϊ��֐�
  cv_dict_svf        CONSTANT VARCHAR2(100) := 'CFR000A00004';    -- SVF�N��
  cv_dict_date_func  CONSTANT VARCHAR2(100) := 'CFR000A00002';    -- �c�Ɠ��t�擾�֐�
--
  --�v���t�@�C��
  cv_set_of_bks_id   CONSTANT VARCHAR2(30) := 'GL_SET_OF_BKS_ID'; -- ��v����ID
  cv_org_id          CONSTANT VARCHAR2(30) := 'ORG_ID';           -- �g�DID
--
  -- �g�pDB��
  cv_table           CONSTANT VARCHAR2(50) := 'XXCFR_REP_INVOICE_LIST'; -- �������z�ꗗ�\���[���[�N�e�[�u��
--
  -- �������^�C�v
  cv_invoice_type    CONSTANT VARCHAR2(1)   := 'A';                     -- �eA�f(�������z�ꗗ�\)
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
  cv_format_date_ymdhns CONSTANT VARCHAR2(25) := 'YYYY/MM/DD HH24:MI:SS';     -- ���t�t�H�[�}�b�g�i�N���������b
  cv_format_date_ymds   CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';           -- ���t�t�H�[�}�b�g�i�N�����X���b�V���t�j
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
  gv_output_date        VARCHAR2(19);                              -- �o�͓�
  gt_user_dept          per_all_people_f.attribute28%TYPE := NULL; -- ���O�C�����[�U��������
  gv_inv_all_flag       VARCHAR2(1) := '0';                        -- �S�Џo�͌�����������t���O
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_target_date         IN      VARCHAR2,         -- ����
    iv_bill_cust_code      IN      VARCHAR2,         -- ���|�R�[�h�P(������)
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
                                                    ,cv_msg_003a05_018 -- ���ʊ֐��G���[
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
    xxcfr_common_pkg.put_log_param( iv_which        => cv_file_type_log                            -- ���O�o��
                                   ,iv_conc_param1  => TO_CHAR(gd_target_date,cv_format_date_ymds) -- �R���J�����g�p�����[�^�P
                                   ,iv_conc_param2  => iv_bill_cust_code                                 -- �R���J�����g�p�����[�^�Q
                                   ,ov_errbuf       => ov_errbuf                                   -- �G���[�E���b�Z�[�W
                                   ,ov_retcode      => ov_retcode                                  -- ���^�[���E�R�[�h
                                   ,ov_errmsg       => ov_errmsg);                                 -- ���[�U�[�E�G���[�E���b�Z�[�W 
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
                                                    ,cv_msg_003a05_010 -- �v���t�@�C���擾�G���[
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
                                                    ,cv_msg_003a05_010 -- �v���t�@�C���擾�G���[
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
   * Procedure Name   : get_output_date
   * Description      : �o�͓��擾���� (A-3)
   ***********************************************************************************/
  PROCEDURE get_output_date(
    ov_errbuf   OUT  VARCHAR2,  -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode  OUT  VARCHAR2,  -- 2.���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg   OUT  VARCHAR2)  -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_output_date'; -- �v���O������
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
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���[�o�͓��Ƃ��Č��ݓ������擾�AYYYY/MM/DD HH24:MI:SS�`���ŕ�����Ƃ��Ď擾
    gv_output_date := TO_CHAR(SYSDATE,cv_format_date_ymdhns);
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(
                            cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf
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
  END get_output_date;
--
  /**********************************************************************************
   * Procedure Name   : chk_inv_all_dept
   * Description      : �S�Џo�͌����`�F�b�N���� (A-4)
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
                                                    ,cv_msg_003a05_017 -- �l�擾�G���[
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
   * Description      : ���[�N�e�[�u���f�[�^�o�^ (A-5)
   ***********************************************************************************/
  PROCEDURE insert_work_table(
    iv_target_date          IN   VARCHAR2,            -- ����
    iv_bill_cust_code       IN   VARCHAR2,            -- ���|�R�[�h�P(������)
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
    cv_lookup_tax_type  CONSTANT VARCHAR2(30) := 'XXCMM_CSUT_SYOHIZEI_KBN'; -- ����ŋ敪
    cv_value_set_name   CONSTANT VARCHAR2(30) := 'XX03_DEPARTMENT' ;        -- ��������l�Z�b�g��
--
    -- *** ���[�J���ϐ� ***
--
    ln_target_cnt   NUMBER := 0;    -- �Ώی���
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
    -- ���[�O�����b�Z�[�W�擾
    -- ====================================================
    lv_no_data_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr      -- 'XXCFR'
                                                       ,cv_msg_003a05_014 ) -- ���[�O�����b�Z�[�W
                              ,1
                              ,5000);
--
    -- ====================================================
    -- ���[�N�e�[�u���ւ̓o�^
    -- ====================================================
    BEGIN
--
    INSERT INTO xxcfr_rep_invoice_list(
       report_id              -- ���[ID
      ,output_date            -- �o�͓�
      ,cutoff_date            -- ����
      ,payment_cust_code      -- ���|�R�[�h�P(������)
      ,bill_location_code     -- �������_�R�[�h
      ,bill_location_name     -- �������_��
      ,tax_type               -- ����ŋ敪
      ,bill_cust_code         -- ������ڋq�R�[�h
      ,bill_cust_name         -- ������ڋq��
      ,bill_area_code         -- ������G���A�R�[�h
      ,inv_amount_includ_tax  -- �����z���v
      ,tax_gap_amount         -- �ō��z
      ,ship_shop_code         -- �X�܃R�[�h
      ,sold_location_code     -- ���㋒�_�R�[�h
      ,sold_location_name     -- ���㋒�_��
      ,sold_area_code         -- ����G���A�R�[�h
      ,ship_cust_code         -- �[�i��ڋq�R�[�h
      ,ship_cust_name         -- �[�i��ڋq��
      ,slip_num               -- �`�[No
      ,delivery_date          -- �[�i��
      ,ship_amount            -- ���z
      ,tax_amount             -- �Ŋz
      ,data_empty_message     -- 0�����b�Z�[�W
      ,created_by             -- �쐬��
      ,creation_date          -- �쐬��
      ,last_updated_by        -- �ŏI�X�V��
      ,last_update_date       -- �ŏI�X�V��
      ,last_update_login      -- �ŏI�X�V���O�C��
      ,request_id             -- �v��ID
      ,program_application_id -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
      ,program_id             -- �R���J�����g�E�v���O����ID
      ,program_update_date  ) -- �v���O�����X�V��
    SELECT cv_pkg_name,                                    -- ���[ID
           gv_output_date,                                 -- �o�͓�
           xih.cutoff_date           cutoff_date,           -- ����
           xih.payment_cust_code     payment_cust_code,     -- �e������ڋq�R�[�h
           xih.bill_location_code    bill_location_code,    -- �������_�R�[�h
           xih.bill_location_name    bill_location_name,    -- �������_��
           flv.meaning               tax_type,              -- ����ŋ敪��
           xih.bill_cust_code        bill_cust_code,        -- ������ڋq�R�[�h�i�\�[�g���S�j
           xih.bill_cust_name        bill_cust_name,        -- ������ڋq��
           ffvb.attribute9           bill_area_code        ,-- �������_�{���R�[�h
           xih.inv_amount_includ_tax inv_amount_includ_tax, -- �����z���v
           xih.tax_gap_amount        tax_gap_amount ,       -- �ō��z
           xil.ship_shop_code        ship_shop_code,        -- �X�܃R�[�h�i�\�[�g���U�j
           xil.sold_location_code    sold_location_code,    -- ���㋒�_�R�[�h
           xil.sold_location_name    sold_location_name,    -- ���㋒�_��
           ffvs.attribute9           sold_area_code,        -- ���㋒�_�{���R�[�h  
           xil.ship_cust_code        ship_cust_code,        -- �[�i��ڋq�R�[�h�i�\�[�g���V�j
           xil.ship_cust_name        ship_cust_name,        -- �[�i��ڋq��
           xil.slip_num              slip_num,              -- �`�[no�i�\�[�g���X�j
           xil.delivery_date         delivery_date,         -- �`�[���t�i�\�[�g���W�j
           SUM(xil.ship_amount)      ship_amount,           -- ���z
           SUM(xil.tax_amount)       tax_amount,            -- �Ŋz
           NULL,                                           -- 0�����b�Z�[�W
           cn_created_by,                                  -- �쐬��
           cd_creation_date,                               -- �쐬��
           cn_last_updated_by,                             -- �ŏI�X�V��
           cd_last_update_date,                            -- �ŏI�X�V��
           cn_last_update_login,                           -- �ŏI�X�V���O�C��
           cn_request_id,                                  -- �v��ID
           cn_program_application_id,                      -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
           cn_program_id,                                  -- �R���J�����g�E�v���O����ID
           cd_program_update_date                          -- �v���O�����X�V��
    FROM xxcfr_invoice_headers          xih,  -- �����w�b�_
         xxcfr_invoice_lines            xil,  -- ��������
         (SELECT ffvv.flex_value flex_value
                ,ffvv.attribute9 
          FROM fnd_flex_value_sets ffvs,
               fnd_flex_values_vl  ffvv
          WHERE ffvs.flex_value_set_name = cv_value_set_name
            AND ffvs.flex_value_set_id = ffvv.flex_value_set_id
         )                               ffvb, -- �������_�l�Z�b�g�l�r���[
         (SELECT ffvv.flex_value flex_value
                ,ffvv.attribute9 
          FROM fnd_flex_value_sets ffvs,
               fnd_flex_values_vl  ffvv
          WHERE ffvs.flex_value_set_name = cv_value_set_name
            AND ffvs.flex_value_set_id = ffvv.flex_value_set_id
         )                               ffvs, -- ���㋒�_�l�Z�b�g�l�r���[
         (SELECT flva.lookup_code,
                 flva.meaning
          FROM   fnd_lookup_values     flva
          WHERE  flva.lookup_type  = cv_lookup_tax_type
            AND flva.language  = USERENV( 'LANG' )
            AND flva.enabled_flag  = cv_enabled_yes
         )                               flv  -- �Q�ƕ\�i����ŋ敪�j
    WHERE xih.invoice_id = xil.invoice_id  -- �ꊇ������ID
      AND xih.cutoff_date = gd_target_date -- �p�����[�^�D����
      AND EXISTS (SELECT 'X'
                  FROM xxcfr_bill_customers_v xb                      --������ڋq�r���[
                  WHERE xih.bill_cust_code = xb.bill_customer_code
                    AND xb.cons_inv_flag = cv_enabled_yes             -- �ꊇ���������s�t���O���L��
                    AND (xb.bill_customer_code = NVL(iv_bill_cust_code,xb.bill_customer_code ) ) -- ������ڋq�R�[�h
                    AND ( (gv_inv_all_flag = cv_status_yes) OR
                          (gv_inv_all_flag = cv_status_no AND 
                           xb.bill_base_code = gt_user_dept) ) )      -- �������_�R�[�h
      AND xih.tax_type                = flv.lookup_code
      AND ffvb.flex_value(+) = xih.bill_location_code
      AND ffvs.flex_value(+) = xil.sold_location_code
      AND xih.set_of_books_id = gn_set_of_bks_id
      AND xih.org_id = gn_org_id
    GROUP BY  cv_pkg_name,
              gv_output_date,
              xih.cutoff_date           , -- ����
              xih.payment_cust_code     , -- �e������ڋq�R�[�h
              xih.bill_location_code    , -- �������_�R�[�h
              xih.bill_location_name    , -- �������_��
              flv.meaning               , -- ����ŋ敪��
              xih.bill_cust_code        , -- ������ڋq�R�[�h
              xih.bill_cust_name        , -- ������ڋq��
              ffvb.attribute9           , -- �������_�{���R�[�h
              xih.inv_amount_includ_tax , -- �����z���v
              xih.tax_gap_amount        , -- �ō��z
              xil.ship_shop_code        , -- �X�܃R�[�h
              xil.sold_location_code    , -- ���㋒�_�R�[�h
              xil.sold_location_name    , -- ���㋒�_��
              ffvs.attribute9           , -- ���㋒�_�{���R�[�h  
              xil.ship_cust_code        , -- �[�i��ڋq�R�[�h
              xil.ship_cust_name        , -- �[�i��ڋq��
              xil.slip_num              , -- �`�[no
              xil.delivery_date           -- �`�[���t
      ;
--
    -- �Ώی���
    gn_target_cnt := SQL%ROWCOUNT;
--
      -- �o�^�f�[�^���P�������݂��Ȃ��ꍇ�A�O�����b�Z�[�W���R�[�h�ǉ�
      IF ( gn_target_cnt = 0 ) THEN
--
        INSERT INTO xxcfr_rep_invoice_list (
          output_date                  , -- �o�͓�
          cutoff_date                  , -- ����
          bill_cust_code               , -- ������ڋq�R�[�h
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
          gv_output_date               , -- �o�͓�
          gd_target_date               , -- ����
          iv_bill_cust_code            , -- ������ڋq�R�[�h
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
                                                       ,cv_msg_003a05_016 )  -- �Ώۃf�[�^0���x��
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
                                                       ,cv_msg_003a05_013    -- �e�[�u���o�^�G���[
                                                       ,cv_tkn_table         -- �g�[�N��'TABLE'
                                                       ,xxcfr_common_pkg.get_table_comment(cv_table))
                                                      -- �������z�ꗗ�\���[���[�N�e�[�u��
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
    cv_svf_form_name  CONSTANT  VARCHAR2(20) := 'XXCFR003A05S.xml';  -- �t�H�[���l���t�@�C����
    cv_svf_query_name CONSTANT  VARCHAR2(20) := 'XXCFR003A05S.vrq';  -- �N�G���[�l���t�@�C����
    cv_output_mode    CONSTANT  VARCHAR2(1)   := '1';                -- �o�͋敪(=1�FPDF�o�́j
    cv_extension_pdf  CONSTANT  VARCHAR2(4)  := '.pdf';              -- �g���q�ipdf�j
--
    -- *** ���[�J���ϐ� ***
    lv_no_data_msg     VARCHAR2(5000);                               -- ���[�O�����b�Z�[�W
-- Modify 2009.04.14 Ver1.3 Start
--    lv_svf_file_name   VARCHAR2(30);                                 -- �o�̓t�@�C����
    lv_svf_file_name   VARCHAR2(100);
-- Modify 2009.04.14 Ver1.3 END
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
    --  SVF�N�� (A-6)
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
    -- �t�@�C�����̐ݒ�
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
    -- SVF�N��API�̌Ăяo���̓G���[��
    IF (lv_retcode = cv_status_error) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
                                                     ,cv_msg_003a05_015    -- API�G���[
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
    CURSOR del_rep_inv_cur
    IS
      SELECT xrsi.rowid        ln_rowid
      FROM xxcfr_rep_invoice_list xrsi -- �������z�ꗗ�\���[���[�N�e�[�u��
      WHERE xrsi.request_id = cn_request_id  -- �v��ID
      FOR UPDATE NOWAIT;
--
    TYPE g_del_rep_inv_ttype IS TABLE OF ROWID INDEX BY PLS_INTEGER;
    lt_del_rep_inv_tab    g_del_rep_inv_ttype;
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
    OPEN del_rep_inv_cur;
--
    -- �f�[�^�̈ꊇ�擾
    FETCH del_rep_inv_cur BULK COLLECT INTO lt_del_rep_inv_tab;
--
    -- ���������̃Z�b�g
    ln_target_cnt := lt_del_rep_inv_tab.COUNT;
--
    -- �J�[�\���N���[�Y
    CLOSE del_rep_inv_cur;
--
    -- �Ώۃf�[�^�����݂���ꍇ���R�[�h���폜����
    IF (ln_target_cnt > 0) THEN
      BEGIN
        <<data_loop>>
        FORALL ln_loop_cnt IN 1..ln_target_cnt
          DELETE FROM xxcfr_rep_invoice_list
          WHERE ROWID = lt_del_rep_inv_tab(ln_loop_cnt);
--
        -- �R�~�b�g���s
        COMMIT;
--
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                        ,cv_msg_003a05_012 -- �f�[�^�폜�G���[
                                                        ,cv_tkn_table         -- �g�[�N��'TABLE'
                                                        ,xxcfr_common_pkg.get_table_comment(cv_table))
                                                        -- �������z�ꗗ�\���[���[�N�e�[�u��
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
                                                     ,cv_msg_003a05_011    -- �e�[�u�����b�N�G���[
                                                     ,cv_tkn_table         -- �g�[�N��'TABLE'
                                                     ,xxcfr_common_pkg.get_table_comment(cv_table))
                                                    -- �������z�ꗗ�\���[���[�N�e�[�u��
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
    iv_bill_cust_code      IN      VARCHAR2,         -- ������ڋq�R�[�h
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
      ,iv_bill_cust_code            -- ���|�R�[�h�P(������)
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
    --  �o�͓��擾����(A-3)
    -- =====================================================
    get_output_date(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  �S�Џo�͌����`�F�b�N����(A-4)
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
    --  ���[�N�e�[�u���f�[�^�o�^ (A-5)
    -- =====================================================
    insert_work_table(
       iv_target_date         -- ����
      ,iv_bill_cust_code            -- ���|�R�[�h�P(������)
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
    iv_bill_cust_code      IN      VARCHAR2          -- ���|�R�[�h�P(������)
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
      ,iv_bill_cust_code    -- ���|�R�[�h�P(������)
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
                      ,iv_name         => cv_msg_003a05_001
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
END XXCFR003A05C;
/
