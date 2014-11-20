CREATE OR REPLACE PACKAGE BODY XXCFR004A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR004A02C(body)
 * Description      : �x���ʒm�f�[�^�_�E�����[�h
 * MD.050           : MD050_CFR_004_A02_�x���ʒm�f�[�^�_�E�����[�h
 * MD.070           : MD050_CFR_004_A02_�x���ʒm�f�[�^�_�E�����[�h
 * Version          : 1.00
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   p ��������                                (A-1)
 *  check_parameter        p ���̓p�����[�^�l�`�F�b�N����            (A-2)
 *  get_profile_value      p �v���t�@�C���擾����                    (A-3)
 *  insert_work_table      p ���[�N�e�[�u���f�[�^�o�^                (A-4)
 *  put_out_file           p �x���ʒm�f�[�^CSV�쐬����               (A-5)
 *  submain                p ���C�������v���V�[�W��
 *  main                   p �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/19    1.00 SCS ���� ��      ����쐬
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
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFR004A02C'; -- �p�b�P�[�W��
  cv_msg_kbn_cmn     CONSTANT VARCHAR2(5)   := 'XXCMN'; -- �A�v���P�[�V�����Z�k��(XXCMN)
  cv_msg_kbn_ccp     CONSTANT VARCHAR2(5)   := 'XXCCP'; -- �A�v���P�[�V�����Z�k��(XXCCP)
  cv_msg_kbn_cfr     CONSTANT VARCHAR2(5)   := 'XXCFR'; -- �A�v���P�[�V�����Z�k��(XXCFR)
--
  -- ���b�Z�[�W�ԍ�
  cv_msg_004a02_009  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00056'; --�V�X�e���G���[���b�Z�[�W
--
  cv_msg_004a02_010  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00004'; --�v���t�@�C���擾�G���[���b�Z�[�W
  cv_msg_004a02_011  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00009'; --�R���J�����g�p�����[�^�l�召�`�F�b�N�G���[
  cv_msg_004a02_012  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00016'; --�e�[�u���}���G���[
  cv_msg_004a02_013  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00024'; --�Ώۃf�[�^0���x�����b�Z�[�W
--
-- �g�[�N��
  cv_tkn_prof        CONSTANT VARCHAR2(15) := 'PROF_NAME';        -- �v���t�@�C����
  cv_tkn_table       CONSTANT VARCHAR2(15) := 'TABLE';            -- �e�[�u����
  cv_tkn_paranm_from CONSTANT VARCHAR2(15) := 'PARAM_NAME_FROM';  -- �p�����[�^��FROM
  cv_tkn_paranm_to   CONSTANT VARCHAR2(15) := 'PARAM_NAME_TO';    -- �p�����[�^��TO
  cv_tkn_paravl_from CONSTANT VARCHAR2(15) := 'PARAM_VAL_FROM';   -- �p�����[�^�lFROM
  cv_tkn_paravl_to   CONSTANT VARCHAR2(15) := 'PARAM_VAL_TO';     -- �p�����[�^�lTO
--
  -- �Q�ƃ^�C�v��
  cv_lookup_type_pn  CONSTANT VARCHAR2(100) := 'XXCFR1_004A02_DATA';   -- CSV�o�͗p�Q�ƃ^�C�v
--
  --�v���t�@�C��
  cv_org_id          CONSTANT VARCHAR2(30) := 'ORG_ID';           -- �g�DID
--
  -- �g�pDB��
  cv_table           CONSTANT VARCHAR2(100) := 'XXCFR_CSV_OUTS_TEMP';  -- �e�[�u����
--
  -- �t�@�C���o��
  cv_file_type_out   CONSTANT VARCHAR2(10) := 'OUTPUT';    -- ���b�Z�[�W�o��
  cv_file_type_log   CONSTANT VARCHAR2(10) := 'LOG';       -- ���O�o��
--
  cv_enabled_yes     CONSTANT VARCHAR2(1)  := 'Y';         -- �L���t���O�i�x�j
--
  cv_format_date_ymd    CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';        -- ���t�t�H�[�}�b�g�i�N�����j
  cv_format_date_ymdhns CONSTANT VARCHAR2(16) := 'YYYYMMDDHH24MISS';  -- ���t�t�H�[�}�b�g�i�N���������b�j
--
  cv_error_string    CONSTANT VARCHAR2(30) := 'Error';            -- �G���[�p�X�R�[�h������
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_org_id             NUMBER;             -- �g�DID
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_receipt_cust_code   IN      VARCHAR2,         --    ������ڋq
    iv_due_date_from       IN      VARCHAR2,         --    �x���N����(FROM)
    iv_due_date_to         IN      VARCHAR2,         --    �x���N����(TO)
    iv_received_date_from  IN      VARCHAR2,         --    ��M��(FROM)
    iv_received_date_to    IN      VARCHAR2,         --    ��M��(TO)
    ov_errbuf              OUT     VARCHAR2,         --    �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode             OUT     VARCHAR2,         --    ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg              OUT     VARCHAR2)         --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --==============================================================
    --�R���J�����g�p�����[�^�o��
    --==============================================================
--
    -- ���O�o��
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_log      -- ���O�o��
      ,iv_conc_param1  => iv_receipt_cust_code  -- �R���J�����g�p�����[�^�P
      ,iv_conc_param2  => iv_due_date_from      -- �R���J�����g�p�����[�^�Q
      ,iv_conc_param3  => iv_due_date_to        -- �R���J�����g�p�����[�^�R
      ,iv_conc_param4  => iv_received_date_from -- �R���J�����g�p�����[�^�S
      ,iv_conc_param5  => iv_received_date_to   -- �R���J�����g�p�����[�^�T
      ,ov_errbuf       => lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
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
   * Procedure Name   : check_parameter
   * Description      : ���̓p�����[�^�l�`�F�b�N����(A-2)
   ***********************************************************************************/
  PROCEDURE check_parameter(
    iv_receipt_cust_code   IN      VARCHAR2,         --    ������ڋq
    iv_due_date_from       IN      VARCHAR2,         --    �x���N����(FROM)
    iv_due_date_to         IN      VARCHAR2,         --    �x���N����(TO)
    iv_received_date_from  IN      VARCHAR2,         --    ��M��(FROM)
    iv_received_date_to    IN      VARCHAR2,         --    ��M��(TO)
    ov_errbuf              OUT     VARCHAR2,         --    �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode             OUT     VARCHAR2,         --    ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg              OUT     VARCHAR2)         --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_parameter'; -- �v���O������
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
    cv_conc_prefix     CONSTANT VARCHAR2(6)  := '$SRS$.';    -- �R���J�����g�Z�k���v���t�B�b�N�X
    cv_const_yes       CONSTANT VARCHAR2(1)  := 'Y';         -- �g�p�\='Y'
--
    -- *** ���[�J���ϐ� ***
    ld_due_date_from       date;   -- �x���N����(FROM)
    ld_due_date_to         date;   -- �x���N����(TO)
    ld_received_date_from  date;   -- ��M��(FROM)
    ld_received_date_to    date;   -- ��M��(TO)
--
    ln_target_cnt   NUMBER;         -- �d�����Ă��錏��
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- �R���J�����g�p�����[�^�����o
    CURSOR conc_param_name_cur1 IS
    SELECT fdfc.column_seq_num,
           fdfc.end_user_column_name,
           fdfc.description
      FROM fnd_concurrent_programs_vl  fcpv,
           fnd_descr_flex_col_usage_vl fdfc
     WHERE fdfc.application_id                = fnd_global.prog_appl_id  -- �R���J�����g�E�v���O�����̃A�v���P�[�V����ID
       AND fdfc.descriptive_flexfield_name    = cv_conc_prefix || fcpv.concurrent_program_name
       AND fdfc.enabled_flag                  = cv_const_yes
       AND fdfc.application_id                = fcpv.application_id
       AND fcpv.concurrent_program_id         = fnd_global.conc_program_id  -- �R���J�����g�E�v���O�����̃v���O����ID 
     ORDER BY fdfc.column_seq_num
    ;
--
    TYPE conc_param_name_tbl1 IS TABLE OF conc_param_name_cur1%ROWTYPE INDEX BY PLS_INTEGER;
    lt_conc_param_name_data1    conc_param_name_tbl1;
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ���t�^�̕ϊ�
    ld_due_date_from      := xxcfr_common_pkg.get_date_param_trans( iv_due_date_from );
    ld_due_date_to        := xxcfr_common_pkg.get_date_param_trans( iv_due_date_to );
    ld_received_date_from := xxcfr_common_pkg.get_date_param_trans( iv_received_date_from );
    ld_received_date_to   := xxcfr_common_pkg.get_date_param_trans( iv_received_date_to );
--
    --==============================================================
    --�G���[���b�Z�[�W�p�Ƀp�����[�^���擾
    --==============================================================
    -- �J�[�\���I�[�v��
    OPEN conc_param_name_cur1;
--
    -- �f�[�^�̈ꊇ�擾
    FETCH conc_param_name_cur1 BULK COLLECT INTO lt_conc_param_name_data1;
--
    -- ���������̃Z�b�g
    ln_target_cnt := lt_conc_param_name_data1.COUNT;
--
    -- �J�[�\���N���[�Y
    CLOSE conc_param_name_cur1;
--
    IF ( ld_due_date_from > ld_due_date_to ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_004a02_011 -- �p�����[�^�l�召�`�F�b�N�G���[
                                                    ,cv_tkn_paranm_from -- �g�[�N��'PARAM_NAME_FROM'
                                                    ,lt_conc_param_name_data1(2).description -- �x���N����(FROM)
                                                    ,cv_tkn_paranm_to   -- �g�[�N��'PARAM_NAME_TO'
                                                    ,lt_conc_param_name_data1(3).description -- �x���N����(TO)
                                                    ,cv_tkn_paravl_from -- �g�[�N��'PARAM_VAL_FROM'
                                                    ,TO_CHAR( ld_due_date_from, cv_format_date_ymd )
                                                    ,cv_tkn_paravl_to   -- �g�[�N��'PARAM_VAL_TO'
                                                    ,TO_CHAR( ld_due_date_to, cv_format_date_ymd ))
                                                   ,1
                                                   ,5000);
      RAISE global_api_expt;
--
    END IF;
--
    IF ( ld_received_date_from > ld_received_date_to ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_004a02_011 -- �p�����[�^�l�召�`�F�b�N�G���[
                                                    ,cv_tkn_paranm_from -- �g�[�N��'PARAM_NAME_FROM'
                                                    ,lt_conc_param_name_data1(4).description -- ��M��(FROM)
                                                    ,cv_tkn_paranm_to   -- �g�[�N��'PARAM_NAME_TO'
                                                    ,lt_conc_param_name_data1(5).description -- ��M��(TO)
                                                    ,cv_tkn_paravl_from -- �g�[�N��'PARAM_VAL_FROM'
                                                    ,TO_CHAR( ld_received_date_from, cv_format_date_ymd )
                                                    ,cv_tkn_paravl_to   -- �g�[�N��'PARAM_VAL_TO'
                                                    ,TO_CHAR( ld_received_date_to, cv_format_date_ymd ))
                                                   ,1
                                                   ,5000);
      RAISE global_api_expt;
--
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
  END check_parameter;
--
  /**********************************************************************************
   * Procedure Name   : get_profile_value
   * Description      : �v���t�@�C���擾����(A-3)
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �v���t�@�C������g�DID�擾
    gn_org_id      := TO_NUMBER(FND_PROFILE.VALUE(cv_org_id));
    -- �擾�G���[��
    IF (gn_org_id IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_004a02_010 -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof       -- �g�[�N��'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_org_id))
                                                       -- �g�DID
                                                   ,1
                                                   ,5000);
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
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
   * Procedure Name   : insert_work_table
   * Description      : ���[�N�e�[�u���f�[�^�o�^ (A-4)
   ***********************************************************************************/
  PROCEDURE insert_work_table(
    iv_receipt_cust_code    IN  VARCHAR2,            -- ������ڋq
    iv_due_date_from        IN  VARCHAR2,            -- �x���N����(FROM)
    iv_due_date_to          IN  VARCHAR2,            -- �x���N����(TO)
    iv_received_date_from   IN  VARCHAR2,            -- ��M��(FROM)
    iv_received_date_to     IN  VARCHAR2,            -- ��M��(TO)
    ov_errbuf               OUT VARCHAR2,            -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT VARCHAR2,            -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT VARCHAR2)            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    cv_rounding_rule_n   CONSTANT VARCHAR2(10) := 'NEAREST';  -- �l�̌ܓ�
    cv_rounding_rule_u   CONSTANT VARCHAR2(10) := 'UP';       -- �؏グ
    cv_rounding_rule_d   CONSTANT VARCHAR2(10) := 'DOWN';     -- �؎̂�
    cv_bill_to           CONSTANT VARCHAR2(10) := 'BILL_TO';  -- �g�p�ړI�F������
    cv_status_op         CONSTANT VARCHAR2(10) := 'OP';       -- �X�e�[�^�X�F�I�[�v��
    cv_status_enabled    CONSTANT VARCHAR2(10) := 'A';        -- �X�e�[�^�X�F�L��
    cv_relate_class      CONSTANT VARCHAR2(10) := '1';        -- �֘A���ށF����
    cv_lookup_tax_type   CONSTANT VARCHAR2(30) := 'XXCMM_CSUT_SYOHIZEI_KBN';   -- ����ŋ敪
    cv_sales_rep_attr    CONSTANT VARCHAR2(30) := 'RESOURCE' ; -- �S���c�ƈ�����
    cv_db_space          CONSTANT VARCHAR2(2)  := CHR(33088); -- �S�p�X�y�[�X
    cv_format_ymd        CONSTANT VARCHAR2(10) := 'YYYYMMDD'; -- ���t�t�H�[�}�b�g�i�N�����j
--
    -- *** ���[�J���ϐ� ***
    ln_target_cnt   NUMBER := 0;    -- �Ώی���
    ln_loop_cnt     NUMBER;         -- ���[�v�J�E���^
--
    lv_no_data_msg          VARCHAR2(5000); -- ���[�O�����b�Z�[�W
    lv_due_date_from        VARCHAR2(8);    -- �x���N����(FROM)
    lv_due_date_to          VARCHAR2(8);    -- �x���N����(TO)
    lv_received_date_from   VARCHAR2(8);    -- ��M��(FROM)
    lv_received_date_to     VARCHAR2(8);    -- ��M��(TO)
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
    -- ====================================================
    -- �p�����[�^�̌^�ϊ�
    -- ====================================================
    lv_due_date_from      := TO_CHAR( xxcfr_common_pkg.get_date_param_trans( iv_due_date_from ), cv_format_ymd );
    lv_due_date_to        := TO_CHAR( xxcfr_common_pkg.get_date_param_trans( iv_due_date_to ), cv_format_ymd );
    lv_received_date_from := TO_CHAR( xxcfr_common_pkg.get_date_param_trans( iv_received_date_from ), cv_format_ymd );
    lv_received_date_to   := TO_CHAR( xxcfr_common_pkg.get_date_param_trans( iv_received_date_to ), cv_format_ymd );
    -- ====================================================
    -- ���[�N�e�[�u���ւ̓o�^
    -- ====================================================
    BEGIN
--
      INSERT INTO xxcfr_csv_outs_temp ( 
         request_id
        ,seq
        ,col1
        ,col2
        ,col3
        ,col4
        ,col5
        ,col6
        ,col7
        ,col8
        ,col9
        ,col10
        ,col11
        ,col12
        ,col13
        ,col14
        ,col15
        ,col16
        ,col17
        ,col18
        ,col19
        ,col20
        ,col21
        ,col22
        ,col23
        ,col24
        ,col25
        ,col26
        ,col27
        ,col28
        ,col29
        ,col30
        ,col31
        ,col32
        ,col33
        ,col34
        ,col35
        ,col36
        ,col37
        ,col38
        ,col39
        ,col40
        ,col41
        ,col42
        ,col43
        ,col44
        ,col45
        ,col46
        ,col47
        ,col48
        ,col49
        ,col50
        ,col51
        ,col52
        ,col53
        ,col54
        ,col55
        ,col56
        ,col57
        ,col58
        ,col59
        ,col60
      )
      SELECT
        cn_request_id                         request_id,               -- �v��ID
        ROWNUM                                seq,                      -- �A��
        xpay.chain_shop_code                  chain_shop_code,          -- �`�F�[���X�R�[�h
        xpay.process_date                     process_date,             -- �f�[�^�������t
        xpay.process_time                     process_time,             -- �f�[�^��������
        xpay.vendor_code                      vendor_code,              -- �d����R�[�h
        xpay.vendor_name                      vendor_name,              -- �d���於��/����於�́i�����j
        xpay.vendor_name_alt                  vendor_name_alt,          -- �d���於��/����於�́i�J�i�j
        xpay.company_code                     company_code,             -- �ЃR�[�h
        xpay.period_from                      period_from,              -- �Ώۊ��ԁE��
        xpay.period_to                        period_to,                -- �Ώۊ��ԁE��
        xpay.invoice_close_date               invoice_close_date,       -- �������N����
        xpay.payment_date                     payment_date,             -- �x���N����
        xpay.site_month                       site_month,               -- �T�C�g����
        xpay.note_count                       note_count,               -- �`�[����
        xpay.credit_note_count                credit_note_count,        -- �����`�[����
        xpay.rem_acceptance_count             rem_acceptance_count,     -- �������`�[����
        xpay.vendor_record_count              vendor_record_count,      -- ���������R�[�h�ʔ�
        xpay.invoice_number                   invoice_number,           -- �����ԍ�
        xpay.invoice_type                     invoice_type,             -- �����敪
        xpay.payment_type                     payment_type,             -- �x���敪
        xpay.payment_method_type              payment_method_type,      -- �x�����@�敪
        xpay.due_type                         due_type,                 -- ���s�敪
        xpay.ebs_cust_account_number          ebs_cust_account_number,  -- �ϊ���d�a�r�ڋq�R�[�h
        xpay.shop_code                        shop_code,                -- �X�R�[�h
        xpay.shop_name                        shop_name,                -- �X�ܖ��́i�����j
        xpay.shop_name_alt                    shop_name_alt,            -- �X�ܖ��́i�J�i�j
        xpay.amount_sign                      amount_sign,              -- ���z����
        xpay.amount                           amount,                   -- ���z
        xpay.tax_type                         tax_type,                 -- ����ŋ敪
        xpay.tax_rate                         tax_rate,                 -- ����ŗ�
        xpay.tax_amount                       tax_amount,               -- ����Ŋz
        xpay.tax_diff_flag                    tax_diff_flag,            -- ����ō��z�t���O
        xpay.diff_calc_flag                   diff_calc_flag,           -- ��Z�敪
        xpay.match_type                       match_type,               -- �}�b�`�敪
        xpay.unmatch_accoumt_amount           unmatch_accoumt_amount,   -- �A���}�b�`���|�v����z
        xpay.double_type                      double_type,              -- �_�u���敪
        xpay.acceptance_date                  acceptance_date,          -- ������
        xpay.max_month                        max_month,                -- ����
        xpay.note_number                      note_number,              -- �`�[�ԍ�
        xpay.line_number                      line_number,              -- �s��
        xpay.note_type                        note_type,                -- �`�[�敪
        xpay.class_code                       class_code,               -- ���ރR�[�h
        xpay.div_code                         div_code,                 -- ����R�[�h
        xpay.sec_code                         sec_code,                 -- �ۃR�[�h
        xpay.return_type                      return_type,              -- ����ԕi�敪
        xpay.nitiriu_type                     nitiriu_type,             -- �j�`���E�o�R�敪
        xpay.sp_sale_type                     sp_sale_type,             -- �����敪
        xpay.shipment                         shipment,                 -- ��
        xpay.order_date                       order_date,               -- ������
        xpay.delivery_date                    delivery_date,            -- �[�i��_�ԕi��
        xpay.product_code                     product_code,             -- ���i�R�[�h
        xpay.product_name                     product_name,             -- ���i���i�����j
        xpay.product_name_alt                 product_name_alt,         -- ���i���i�J�i�j
        xpay.delivery_quantity                delivery_quantity,        -- �[�i����
        xpay.cost_unit_price                  cost_unit_price,          -- �����P��
        xpay.cost_price                       cost_price,               -- �������z
        xpay.desc_code                        desc_code,                -- ���l�R�[�h
        xpay.chain_orig_desc                  chain_orig_desc,          -- �`�F�[���ŗL�G���A
        xpay.sum_amount                       sum_amount,               -- ���v���z
        xpay.discount_sum_amount              discount_sum_amount,      -- �l�����v���z
        xpay.return_sum_amount                return_sum_amount         -- �ԕi���v���z
      FROM
        (
        SELECT
          xpn.chain_shop_code                 chain_shop_code,          -- �`�F�[���X�R�[�h
          xpn.process_date                    process_date,             -- �f�[�^�������t
          xpn.process_time                    process_time,             -- �f�[�^��������
          xpn.vendor_code                     vendor_code,              -- �d����R�[�h
          RTRIM( xpn.vendor_name, cv_db_space ) vendor_name,              -- �d���於��/����於�́i�����j
          RTRIM( xpn.vendor_name_alt )        vendor_name_alt,          -- �d���於��/����於�́i�J�i�j
          xpn.company_code                    company_code,             -- �ЃR�[�h
          xpn.period_from                     period_from,              -- �Ώۊ��ԁE��
          xpn.period_to                       period_to,                -- �Ώۊ��ԁE��
          xpn.invoice_close_date              invoice_close_date,       -- �������N����
          xpn.payment_date                    payment_date,             -- �x���N����
          TO_CHAR( xpn.site_month )           site_month,               -- �T�C�g����
          TO_CHAR( xpn.note_count )           note_count,               -- �`�[����
          TO_CHAR( xpn.credit_note_count )    credit_note_count,        -- �����`�[����
          TO_CHAR( xpn.rem_acceptance_count ) rem_acceptance_count,     -- �������`�[����
          TO_CHAR( xpn.vendor_record_count )  vendor_record_count,      -- ���������R�[�h�ʔ�
          TO_CHAR( xpn.invoice_number )       invoice_number,           -- �����ԍ�
          xpn.invoice_type                    invoice_type,             -- �����敪
          xpn.payment_type                    payment_type,             -- �x���敪
          xpn.payment_method_type             payment_method_type,      -- �x�����@�敪
          xpn.due_type                        due_type,                 -- ���s�敪
          xpn.ebs_cust_account_number         ebs_cust_account_number,  -- EBS�ڋq�R�[�h
          xpn.shop_code                       shop_code,                -- �X�R�[�h
          RTRIM( xpn.shop_name, cv_db_space ) shop_name,                -- �X�ܖ��́i�����j
          RTRIM( xpn.shop_name_alt )          shop_name_alt,            -- �X�ܖ��́i�J�i�j
          xpn.amount_sign                     amount_sign,              -- ���z����
          TO_CHAR( xpn.amount )               amount,                   -- ���z
          xpn.tax_type                        tax_type,                 -- ����ŋ敪
          TO_CHAR( xpn.tax_rate )             tax_rate,                 -- ����ŗ�
          TO_CHAR( xpn.tax_amount )           tax_amount,               -- ����Ŋz
          xpn.tax_diff_flag                   tax_diff_flag,            -- ����ō��z�t���O
          xpn.diff_calc_flag                  diff_calc_flag,           -- ��Z�敪
          xpn.match_type                      match_type,               -- �}�b�`�敪
          TO_CHAR( xpn.unmatch_accoumt_amount ) unmatch_accoumt_amount, -- �A���}�b�`���|�v����z
          xpn.double_type                     double_type,              -- �_�u���敪
          xpn.acceptance_date                 acceptance_date,          -- ������
          xpn.max_month                       max_month,                -- ����
          xpn.note_number                     note_number,              -- �`�[�ԍ�
          TO_CHAR( xpn.line_number )          line_number,              -- �s��
          xpn.note_type                       note_type,                -- �`�[�敪
          xpn.class_code                      class_code,               -- ���ރR�[�h
          xpn.div_code                        div_code,                 -- ����R�[�h
          xpn.sec_code                        sec_code,                 -- �ۃR�[�h
          TO_CHAR( xpn.return_type )          return_type,              -- ����ԕi�敪
          xpn.nitiriu_type                    nitiriu_type,             -- �j�`���E�o�R�敪
          xpn.sp_sale_type                    sp_sale_type,             -- �����敪
          xpn.shipment                        shipment,                 -- ��
          xpn.order_date                      order_date,               -- ������
          xpn.delivery_date                   delivery_date,            -- �[�i��_�ԕi��
          xpn.product_code                    product_code,             -- ���i�R�[�h
          RTRIM( xpn.product_name, cv_db_space ) product_name,          -- ���i���i�����j
          RTRIM( xpn.product_name_alt )       product_name_alt,         -- ���i���i�J�i�j
          TO_CHAR( xpn.delivery_quantity )    delivery_quantity,        -- �[�i����
          TO_CHAR( xpn.cost_unit_price )      cost_unit_price,          -- �����P��
          TO_CHAR( xpn.cost_price )           cost_price,               -- �������z
          xpn.desc_code                       desc_code,                -- ���l�R�[�h
          RTRIM( xpn.chain_orig_desc )        chain_orig_desc,          -- �`�F�[���ŗL�G���A
          TO_CHAR( xpn.sum_amount )           sum_amount,               -- ���v���z
          TO_CHAR( xpn.discount_sum_amount )  discount_sum_amount,      -- �l�����v���z
          TO_CHAR( xpn.return_sum_amount )    return_sum_amount         -- �ԕi���v���z
        FROM xxcfr_payment_notes        xpn,             -- �x���ʒm���e�[�u��
             xxcfr_cust_hierarchy_v     xchv             -- �ڋq�K�w�r���[
        WHERE ( lv_due_date_from          IS NULL
             OR xpn.payment_date          >= lv_due_date_from )
          AND ( lv_due_date_to            IS NULL
             OR xpn.payment_date          <= lv_due_date_to )
          AND ( lv_received_date_from     IS NULL
             OR xpn.process_date          >= lv_received_date_from )
          AND ( lv_received_date_to       IS NULL
             OR xpn.process_date          <= lv_received_date_to )
          AND xpn.ebs_cust_account_number =  xchv.ship_account_number(+)
          AND ( iv_receipt_cust_code      IS NULL
             OR xchv.cash_account_number  =  iv_receipt_cust_code
             OR ( iv_receipt_cust_code        = cv_error_string
              AND xpn.ebs_cust_account_number = iv_receipt_cust_code ))
          AND xpn.org_id                  =  gn_org_id
        ORDER BY
          xchv.cash_account_number,       -- ������ڋq�R�[�h
          xpn.ebs_cust_account_number,    -- EBS�ڋq�R�[�h
          xpn.acceptance_date,            -- ������
          xpn.delivery_date               -- �[�i��_�ԕi��
        ) xpay
    ;
--
      gn_target_cnt := SQL%ROWCOUNT;
--
      -- �o�^�f�[�^���P�������݂��Ȃ��ꍇ�A�x���I�����邱�ƂƂ���B
      IF ( gn_target_cnt = 0 ) THEN
        -- �x���I��
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
                                                       ,cv_msg_004a02_013    -- �Ώۃf�[�^0���x��
                                                      )
                                                      ,1
                                                      ,5000);
        ov_errmsg  := lv_errmsg;
        ov_retcode := cv_status_warn;
      END IF;
--
    EXCEPTION
      WHEN OTHERS THEN  -- �o�^���G���[
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
                                                       ,cv_msg_004a02_012    -- �e�[�u���o�^�G���[
                                                       ,cv_tkn_table         -- �g�[�N��'TABLE'
                                                       ,xxcfr_common_pkg.get_table_comment(cv_table))
                                                      -- �c�ƈ��ʕ����ʓ����\��\���[���[�N�e�[�u��
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
   * Procedure Name   : put_out_file
   * Description      : �x���ʒm�f�[�^CSV�쐬���� (A-5)
   ***********************************************************************************/
  PROCEDURE put_out_file(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put_out_file'; -- �v���O������
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- =====================================================
    --  �x���ʒm�f�[�^CSV�쐬���� (A-5)
    -- =====================================================
--
    xxcfr_common_pkg.csv_out(
       in_request_id   => cn_request_id        -- �v��ID
      ,iv_lookup_type  => cv_lookup_type_pn    -- �Q�ƃ^�C�v���iCSV�J������`�j
      ,in_rec_cnt      => gn_target_cnt        -- �Ώی���
      ,ov_errbuf       => lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- CSV�o�͗p���ʊ֐��̌Ăяo���̓G���[��
    IF (lv_retcode = cv_status_error) THEN
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
  END put_out_file;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_receipt_cust_code   IN      VARCHAR2,         --   ������ڋq
    iv_due_date_from       IN      VARCHAR2,         --   �x���N����(FROM)
    iv_due_date_to         IN      VARCHAR2,         --   �x���N����(TO)
    iv_received_date_from  IN      VARCHAR2,         --   ��M��(FROM)
    iv_received_date_to    IN      VARCHAR2,         --   ��M��(TO)
    ov_errbuf              OUT     VARCHAR2,         --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode             OUT     VARCHAR2,         --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg              OUT     VARCHAR2)         --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- =====================================================
    --  ��������(A-1)
    -- =====================================================
    init(
       iv_receipt_cust_code   -- �������_
      ,iv_due_date_from       -- �x������(FROM)
      ,iv_due_date_to         -- �x������(TO)
      ,iv_received_date_from  -- ��M��(FROM)
      ,iv_received_date_to    -- ��M��(TO)
      ,lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  ���̓p�����[�^�l�`�F�b�N����(A-2)
    -- =====================================================
    check_parameter(
       iv_receipt_cust_code   -- �������_
      ,iv_due_date_from       -- �x������(FROM)
      ,iv_due_date_to         -- �x������(TO)
      ,iv_received_date_from  -- ��M��(FROM)
      ,iv_received_date_to    -- ��M��(TO)
      ,lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  �v���t�@�C���擾����(A-3)
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
    --  ���[�N�e�[�u���f�[�^�o�^ (A-4)
    -- =====================================================
    insert_work_table(
       iv_receipt_cust_code   -- �������_
      ,iv_due_date_from       -- �x������(FROM)
      ,iv_due_date_to         -- �x������(TO)
      ,iv_received_date_from  -- ��M��(FROM)
      ,iv_received_date_to    -- ��M��(TO)
      ,lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      --(�߂�l�̕ۑ�)
      ov_errmsg  := lv_errmsg;
      ov_retcode := lv_retcode;
    END IF;
--
    -- =====================================================
    --  �x���ʒm�f�[�^CSV�쐬���� (A-5)
    -- =====================================================
    put_out_file(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
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
    errbuf                 OUT     VARCHAR2,         --    �G���[�E���b�Z�[�W  --# �Œ� #
    retcode                OUT     VARCHAR2,         --    �G���[�R�[�h     #�Œ�#
    iv_receipt_cust_code   IN      VARCHAR2,         --    ������ڋq
    iv_due_date_from       IN      VARCHAR2,         --    �x���N����(FROM)
    iv_due_date_to         IN      VARCHAR2,         --    �x���N����(TO)
    iv_received_date_from  IN      VARCHAR2,         --    ��M��(FROM)
    iv_received_date_to    IN      VARCHAR2          --    ��M��(TO)
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
       iv_receipt_cust_code   -- �������_
      ,iv_due_date_from       -- �x������(FROM)
      ,iv_due_date_to         -- �x������(TO)
      ,iv_received_date_from  -- ��M��(FROM)
      ,iv_received_date_to    -- ��M��(TO)
      ,lv_errbuf     -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode    -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
-- Add Start 2008/11/18 SCS H.Nakamura �e���v���[�g���C��
    --�G���[���b�Z�[�W���ݒ肳��Ă���ꍇ�A�G���[�o��
    IF (lv_errmsg IS NOT NULL) THEN
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
                      ,iv_name         => cv_msg_004a02_009
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
    END IF;
--
    --�P�s���s
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => '' --���[�U�[�E�G���[���b�Z�[�W
    );
--
-- Add End   2008/11/18 SCS H.Nakamura �e���v���[�g���C��
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
-- Add Start 2008/11/18 SCS H.Nakamura �e���v���[�g���C��
    --�P�s���s
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => '' --���[�U�[�E�G���[���b�Z�[�W
    );
-- Add End 2008/11/18 SCS H.Nakamura �e���v���[�g���C��
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
END XXCFR004A02C;
/
