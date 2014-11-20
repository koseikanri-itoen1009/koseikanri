CREATE OR REPLACE PACKAGE BODY XXCFR005A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR005A03C(body)
 * Description      : ���b�N�{�b�N�X��������������
 * MD.050           : MD050_CFR_005_A03_���b�N�{�b�N�X��������������
 * MD.070           : MD050_CFR_005_A03_���b�N�{�b�N�X��������������
 * Version          : 1.00
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   p ���̓p�����[�^�l���O�o�͏���            (A-1)
 *  get_profile_value      P �v���t�@�C���擾����                    (A-2)
 *  get_submit_request     p ���b�N�{�b�N�X�����N������              (A-4)
 *  submain                p ���C�������v���V�[�W��
 *  main                   p �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/15    1.00  SCS �_�� ����    ����쐬
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
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFR005A03C';        -- �p�b�P�[�W��
  cv_pg_name         CONSTANT VARCHAR2(100) := 'ARLPLB';              -- �R���J�����g��
  cv_msg_kbn_cfr     CONSTANT VARCHAR2(5)   := 'XXCFR';               -- �A�v���P�[�V�����Z�k��(XXCFR)
  cv_dict_cd         CONSTANT VARCHAR2(100) := 'CFR005A01003';        -- �v���O������
--
  -- ���b�Z�[�W�ԍ�
  cv_msg_005a03_004  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00004';     -- �v���t�@�C���擾�G���[���b�Z�[�W
  cv_msg_005a03_012  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00012';     -- �R���J�����g���s�G���[���b�Z�[�W
  cv_msg_005a03_013  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00013';     -- �R���J�����g�Ď��G���[���b�Z�[�W
  cv_msg_005a03_067  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00067';     -- ���b�N�{�b�N�X����I�����b�Z�[�W
  cv_msg_005a03_027  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00027';     -- ���b�N�{�b�N�X�x���I�����b�Z�[�W
  cv_msg_005a03_028  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00028';     -- ���b�N�{�b�N�X�G���[�I�����b�Z�[�W
--
-- �g�[�N��
  cv_tkn_prof          CONSTANT VARCHAR2(15) := 'PROF_NAME';            -- �v���t�@�C����
  cv_tkn_prog_name     CONSTANT VARCHAR2(30) := 'PROGRAM_NAME';         -- �R���J�����g�v���O������
  cv_tkn_request       CONSTANT VARCHAR2(15) := 'REQUEST_ID';           -- �v��ID
  cv_transmission_name CONSTANT VARCHAR2(18) := 'TRANSMISSION_NAME';    -- �`����
  cv_tkn_file_name     CONSTANT VARCHAR2(15) := 'FB_FILE_NAME';         -- �Ώۂ̓`����
  cv_tkn_dev_phase     CONSTANT VARCHAR2(15) := 'DEV_PHASE';            -- DEV_PHASE
  cv_tkn_dev_status    CONSTANT VARCHAR2(15) := 'DEV_STATUS';           -- DEV_STATUS
--
  -- �R���J�����gDEV�t�F�[�Y
  cv_dev_phase_complete CONSTANT VARCHAR2(30) := 'COMPLETE';          -- '����'
--
  -- �R���J�����gDEV�X�e�[�^�X
  cv_dev_status_normal  CONSTANT VARCHAR2(30) := 'NORMAL';            -- '����'
  cv_dev_status_warn    CONSTANT VARCHAR2(30) := 'WARNING';           -- '�x��'
  cv_dev_status_err     CONSTANT VARCHAR2(30) := 'ERROR';             -- '�G���['
--
  --�v���t�@�C��
  cv_org_id                   CONSTANT VARCHAR2(30) := 'ORG_ID';                          -- �g�DID
  cv_prof_name_wait_interval  CONSTANT VARCHAR2(35) := 'XXCFR1_GENERAL_RECEIPT_INTERVAL';
                                                                       -- XXCFR:���b�N�{�b�N�X�v�������`�F�b�N�ҋ@�b��
  cv_prof_name_wait_max       CONSTANT VARCHAR2(35) := 'XXCFR1_GENERAL_RECEIPT_MAX_WAIT';
                                                                       -- XXCFR:���b�N�{�b�N�X�v�������ҋ@�ő�b��
--
  -- �t�@�C���o��
  cv_file_type_out   CONSTANT VARCHAR2(10) := 'OUTPUT';               -- ���b�Z�[�W�o��
  cv_file_type_log   CONSTANT VARCHAR2(10) := 'LOG';                  -- ���O�o��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  gn_org_id          NUMBER;                                               -- �g�DID
  gv_pg_name         VARCHAR2(100);                                        -- �R���J�����g��
  gv_wait_interval   fnd_profile_option_values.profile_option_value%TYPE;  -- �R���J�����g�Ď��Ԋu
  gv_wait_max        fnd_profile_option_values.profile_option_value%TYPE;  -- �R���J�����g�Ď��ő厞��
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ���̓p�����[�^�l���O�o�͏���(A-1)
   ***********************************************************************************/
  PROCEDURE init(
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
    -- �R���J�����g�p�����[�^�o��
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_out   -- ���b�Z�[�W�o��
      ,ov_errbuf       => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ���O�o��
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_log   -- ���O�o��
      ,ov_errbuf       => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
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
--#################################  �Œ��O������ START   ####################################
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
   * Description      : �v���t�@�C���擾���� (A-2)
   ***********************************************************************************/
  PROCEDURE get_profile_value(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
--
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
    gn_org_id := TO_NUMBER(FND_PROFILE.VALUE(cv_org_id));
    -- �擾�G���[��
    IF (gn_org_id IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_005a03_004 -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof       -- �g�[�N��'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_org_id))
                                                                       -- �g�DID
                                                   ,1
                                                   ,5000);
      RAISE global_api_expt;
    END IF;
--
    -- �v���t�@�C������XXCFR:���b�N�{�b�N�X�v�������`�F�b�N�ҋ@�b�����擾
    gv_wait_interval := FND_PROFILE.VALUE(cv_prof_name_wait_interval);
    IF (gv_wait_interval IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_005a03_004 -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof       -- �g�[�N��'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_prof_name_wait_interval))
                                                       -- XXCFR:���b�N�{�b�N�X�v�������`�F�b�N�ҋ@�b��
                                                   ,1
                                                   ,5000);
      RAISE global_api_expt;
    END IF;
--
    -- �v���t�@�C������XXCFR:���b�N�{�b�N�X�v�������ҋ@�ő�b�����擾
    gv_wait_max := FND_PROFILE.VALUE(cv_prof_name_wait_max);
    IF (gv_wait_max IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_005a03_004 -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof       -- �g�[�N��'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_prof_name_wait_max))
                                                       -- XXCFR:���b�N�{�b�N�X�v�������ҋ@�ő�b��
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
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
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
   * Procedure  Name   : get_submit_request
   * Description      : ���b�N�{�b�N�X�����N������ (A-4)
   ***********************************************************************************/
  Procedure get_submit_request(
    iv_transmission_id                 VARCHAR2,            -- �`��ID
    iv_transmission_name               VARCHAR2,            -- �`����
    iv_transmission_request_id         VARCHAR2,            -- �����v��ID
    ov_errbuf               OUT NOCOPY VARCHAR2,            -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,            -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2)            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
--
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_submit_request'; -- �v���O������
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
    cv_conc_appli   CONSTANT VARCHAR2(2) := 'AR'; -- �A�v���P�[�V�����Z�k��('AR')
    cv_conc_param_y CONSTANT VARCHAR2(1) := 'Y';  -- �R���J�����g�p�����[�^('Y')
    cv_conc_param_n CONSTANT VARCHAR2(1) := 'N';  -- �R���J�����g�p�����[�^('N')
    cv_conc_param_a CONSTANT VARCHAR2(1) := 'A';  -- �R���J�����g�p�����[�^('A')
    cv_conc_null    CONSTANT VARCHAR2(1) := NULL; -- �R���J�����g�p�����[�^(NULL)
    cv_zengin       CONSTANT VARCHAR2(3) := '102';-- 'ZENGIN'
--
    -- *** ���[�J���ϐ� ***
    ln_request_id   NUMBER;           -- �R���J�����g�v��ID
    lb_wait_request BOOLEAN;          -- FND_CONCURRENT.WAIT_FOR_REQUEST�̖߂�l�i�[�p�ϐ�
    lv_phase        VARCHAR2(100);    -- FND_CONCURRENT.WAIT_FOR_REQUEST�̖߂�l�i�[�p�ϐ�
    lv_status       VARCHAR2(100);    -- FND_CONCURRENT.WAIT_FOR_REQUEST�̖߂�l�i�[�p�ϐ�
    lv_dev_phase    VARCHAR2(100);    -- FND_CONCURRENT.WAIT_FOR_REQUEST�̖߂�l�i�[�p�ϐ�
    lv_dev_status   VARCHAR2(100);    -- FND_CONCURRENT.WAIT_FOR_REQUEST�̖߂�l�i�[�p�ϐ�
    lv_message      VARCHAR2(5000);   -- FND_CONCURRENT.WAIT_FOR_REQUEST�̖߂�l�i�[�p�ϐ�
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- ===============================
    -- ���[�J����O
    -- ===============================
    submit_request_expt    EXCEPTION;  -- �R���J�����g���s�G���[��O
    wait_for_request_expt  EXCEPTION;  -- �R���J�����g�Ď��G���[��O
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
    -- �R���J�����g���s
    ln_request_id := 
    FND_REQUEST.SUBMIT_REQUEST( application => cv_conc_appli              -- �A�v���P�[�V�����Z�k��
                               ,program     => cv_pg_name                 -- �R���J�����g�v���O������
                               ,argument1   => cv_conc_param_n            -- �V�K�`��
                               ,argument2   => iv_transmission_id         -- �`��ID
                               ,argument3   => iv_transmission_request_id -- �����v��ID
                               ,argument4   => iv_transmission_name       -- �`����
                               ,argument5   => cv_conc_param_n            -- �C���|�[�g�̔��s
                               ,argument6   => cv_conc_null               -- �f�[�^�E�t�@�C��
                               ,argument7   => cv_conc_null               -- �Ǘ��t�@�C��
                               ,argument8   => cv_zengin                  -- �`���t�H�[�}�b�gID
                               ,argument9   => cv_conc_param_y            -- ���؂̔��s
                               ,argument10  => cv_conc_param_n            -- ���֘A�������x��
                               ,argument11  => cv_conc_null               -- ���b�N�{�b�N�XID
                               ,argument12  => cv_conc_null               -- GL�L����
                               ,argument13  => cv_conc_param_a            -- ���|�[�g�E�t�H�[�}�b�g
                               ,argument14  => cv_conc_param_n            -- �����p�b�`�̂�
                               ,argument15  => cv_conc_param_y            -- �p�b�`�]�L�̔��s
                               ,argument16  => cv_conc_param_n            -- �J�i�����I�v�V����
                               ,argument17  => cv_conc_null               -- �ꕔ���z�̓]�L�܂��͑S�����̋���
                               ,argument18  => cv_conc_null               -- USSGL����R�[�h
                               ,argument19  => gn_org_id                  -- �g�DID
                              );
    IF (ln_request_id = 0) THEN
      RAISE submit_request_expt;
    END IF;
--
    COMMIT;
    -- �R���J�����g�v���Ď�
    lb_wait_request := FND_CONCURRENT.WAIT_FOR_REQUEST( request_id => ln_request_id    -- �v��ID
                                                       ,interval   => gv_wait_interval -- �R���J�����g�Ď��Ԋu
                                                       ,max_wait   => gv_wait_max      -- �R���J�����g�Ď��ő厞��
                                                       ,phase      => lv_phase         -- �v���t�F�[�Y
                                                       ,status     => lv_status        -- �v���X�e�[�^�X
                                                       ,dev_phase  => lv_dev_phase     -- �v���t�F�[�Y�R�[�h
                                                       ,dev_status => lv_dev_status    -- �v���X�e�[�^�X�R�[�h
                                                       ,message    => lv_message       -- �������b�Z�[�W
                                                      );
    IF (lb_wait_request) THEN
      IF (lv_dev_phase = cv_dev_phase_complete)
        AND (lv_dev_status = cv_dev_status_normal)
      THEN
        -- ����I���̏ꍇ
        gn_normal_cnt := gn_normal_cnt + 1;
        -- ����I�����b�Z�[�W�o��
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(
                               iv_application => cv_msg_kbn_cfr       -- 'XXCFR'
                              ,iv_name => cv_msg_005a03_067           -- ����I�����b�Z�[�W
                              ,iv_token_name1 => cv_tkn_prog_name     -- �g�[�N��'PROGRAM_NAME'
                              ,iv_token_value1 => xxcfr_common_pkg.lookup_dictionary( cv_msg_kbn_cfr
                                                                                     ,cv_dict_cd
                                                                                    ) -- �v���O������
                              ,iv_token_name2 => cv_tkn_request       -- �g�[�N��'REQUEST_ID'
                              ,iv_token_value2 => TO_CHAR(ln_request_id)
                              ,iv_token_name3 => cv_transmission_name       -- �g�[�N��'TRANSMISSION_NAME'
                              ,iv_token_value3 => iv_transmission_name
                              )
                             ,1
                             ,5000
                            );
        --�P�s���s
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => '' --���[�U�[�E�G���[���b�Z�[�W
        );
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
                          lv_errmsg
                         );
        lv_errmsg := '';
      ELSIF (lv_dev_phase = cv_dev_phase_complete)
        AND (lv_dev_status = cv_dev_status_warn)
      THEN
        -- �x���I���̏ꍇ
        gn_error_cnt := gn_error_cnt + 1;
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(
                               cv_msg_kbn_cfr     -- 'XXCFR'
                              ,cv_msg_005a03_027  -- �x���I�����b�Z�[�W
                              ,cv_tkn_request     -- �g�[�N��'REQUEST_ID'
                              ,ln_request_id
                                 -- �v��ID
                              ,cv_tkn_file_name   -- �g�[�N��'FB_FILE_NAME'
                              ,iv_transmission_name
                                 -- �Ώۂ̓`����
                              ,cv_tkn_dev_phase   -- �g�[�N��'DEV_PHASE'
                              ,lv_dev_phase
                                 -- DEV_PHASE
                              ,cv_tkn_dev_status  -- �g�[�N��'DEV_STATUS'
                              ,lv_dev_status
                            )    -- DEV_STATUS
                           ,1
                           ,5000
                          );
        --�P�s���s
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => '' --���[�U�[�E�G���[���b�Z�[�W
        );
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
                          lv_errmsg
                         );
        lv_errmsg := '';
      ELSE
        -- �G���[�I���̏ꍇ
        gn_error_cnt := gn_error_cnt + 1;
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(
                               cv_msg_kbn_cfr     -- 'XXCFR'
                              ,cv_msg_005a03_028  -- �G���[�I�����b�Z�[�W
                              ,cv_tkn_request     -- �g�[�N��'REQUEST_ID'
                              ,ln_request_id
                                 -- �v��ID
                              ,cv_tkn_file_name   -- �g�[�N��'FB_FILE_NAME'
                              ,iv_transmission_name
                                 -- �Ώۂ̓`����
                              ,cv_tkn_dev_phase   -- �g�[�N��'DEV_PHASE'
                              ,lv_dev_phase
                                 -- DEV_PHASE
                              ,cv_tkn_dev_status  -- �g�[�N��'DEV_STATUS'
                              ,lv_dev_status
                            )    -- DEV_STATUS
                           ,1
                           ,5000
                          );
        --�P�s���s
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => '' --���[�U�[�E�G���[���b�Z�[�W
        );
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
                          lv_errmsg
                         );
        lv_errmsg := '';
      END IF;
    ELSE
      RAISE wait_for_request_expt;
    END IF;
--
  EXCEPTION
--
    -- *** �v�����s���s�� ***
    WHEN submit_request_expt THEN
      lv_errbuf := FND_MESSAGE.GET; -- FND_REQUEST.SUBMIT_REQUEST�ŃX�^�b�N���ꂽ�G���[���b�Z�[�W���擾
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfr,      -- 'XXCFR'
                                            iv_name         => cv_msg_005a03_012,   -- �R���J�����g���s�G���[���b�Z�[�W
                                            iv_token_name1  => cv_tkn_prog_name,    -- �g�[�N��'PROGRAM_NAME'
                                            iv_token_value1 => xxcfr_common_pkg.lookup_dictionary(
                                                                  cv_msg_kbn_cfr
                                                                 ,cv_dict_cd
                                                               )                    -- �v���O������
                                           );
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      ov_errmsg := lv_errmsg;
    -- *** �v���Ď����s�� ***
    WHEN wait_for_request_expt THEN
      lv_errbuf := FND_MESSAGE.GET; -- FND_REQUEST.WAIT_FOR_REQUEST�ŃX�^�b�N���ꂽ�G���[���b�Z�[�W���擾
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfr,      -- 'XXCFR'
                                            iv_name         => cv_msg_005a03_013,   -- �R���J�����g�Ď��G���[���b�Z�[�W
                                            iv_token_name1  => cv_tkn_prog_name,    -- �g�[�N��'PROGRAM_NAME'
                                            iv_token_value1 => xxcfr_common_pkg.lookup_dictionary(
                                                                  cv_msg_kbn_cfr
                                                                 ,cv_dict_cd
                                                               )                    -- �v���O������
                                           );
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      ov_errmsg := lv_errmsg;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
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
  END get_submit_request;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    on_target_cnt          OUT     NUMBER,           -- �Ώی���
    on_normal_cnt          OUT     NUMBER,           -- ��������
    on_error_cnt           OUT     NUMBER,           -- �G���[����
    on_warn_cnt            OUT     NUMBER,           -- �x������
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
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
--
    -- ���o
    CURSOR ar_transmissions_cur
    IS
      SELECT tra.transmission_id         transmission_id         -- �`��ID
            ,tra.transmission_name       transmission_name       -- �`����
            ,tra.transmission_request_id transmission_request_id -- �����v��ID
      FROM ar_transmissions_all tra                              -- ���b�N�{�b�N�X�f�[�^�`�������e�[�u��
      WHERE EXISTS (SELECT 'X'
                    FROM ar_payments_interface_all pay           -- ���b�N�{�b�N�XIF
                    WHERE pay.transmission_request_id = tra.transmission_request_id)  -- �����v��ID
    ;
--
    ar_transmissions_rec ar_transmissions_cur%ROWTYPE;
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
    --  ���̓p�����[�^�l���O�o�͏���(A-1)
    -- =====================================================
    init(
       lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  �v���t�@�C���擾����(A-2)
    -- =====================================================
    get_profile_value(
       lv_errbuf                     -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode                    -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg                     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  �Ώۃ��b�N�{�b�N�X�f�[�^�擾����(A-3)
    -- =====================================================
--
    -- �J�[�\���I�[�v��
    OPEN ar_transmissions_cur;
--
    <<transmissions_loop>>
    LOOP
      -- ���^�[���l������
      lv_retcode  := cv_status_normal;
--
    -- �f�[�^�̎擾
      FETCH ar_transmissions_cur INTO ar_transmissions_rec;
      EXIT WHEN ar_transmissions_cur%NOTFOUND;
--
      -- �Ώی����J�E���g
      gn_target_cnt := gn_target_cnt + 1;
--
    -- =====================================================
    --  ���b�N�{�b�N�X�����N������(A-4)
    -- =====================================================
--
      -- ���b�N�{�b�N�X�����N������
      get_submit_request(
         ar_transmissions_rec.transmission_id           -- �`��ID
        ,ar_transmissions_rec.transmission_name         -- �`����
        ,ar_transmissions_rec.transmission_request_id   -- �����v��ID
        ,lv_errbuf                                      -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode                                     -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg                                      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode = cv_status_error) THEN
        --(�G���[����)
        RAISE global_process_expt;
      END IF;
--
    END LOOP transmissions_loop;
--
    -- �J�[�\���N���[�Y
    CLOSE ar_transmissions_cur;
--
    -- =====================================================
    --  �I������ (A-5)
    -- =====================================================
    on_target_cnt  := gn_target_cnt;  -- �Ώی����J�E���g
    on_normal_cnt  := gn_normal_cnt;  -- ���������J�E���g
    on_error_cnt   := gn_error_cnt;   -- �G���[�����J�E���g
    on_warn_cnt    := gn_warn_cnt;    -- �x�������J�E���g
--
    -- �x���t���O����
    IF (gn_error_cnt > 0) THEN
      ov_retcode := cv_status_warn;
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
-- Add Start 2008/12/16 SCS R.Hamanaka �e���v���[�g���C��
      IF (ar_transmissions_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE ar_transmissions_cur;
      END IF;
-- Add End 2008/12/16 SCS R.Hamanaka �e���v���[�g���C��
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
-- Add Start 2008/12/16 SCS R.Hamanaka �e���v���[�g���C��
      IF (ar_transmissions_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE ar_transmissions_cur;
      END IF;
-- Add End 2008/12/16 SCS R.Hamanaka �e���v���[�g���C��
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
-- Add Start 2008/12/16 SCS R.Hamanaka �e���v���[�g���C��
      IF (ar_transmissions_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE ar_transmissions_cur;
      END IF;
-- Add End 2008/12/15 SCS R.Hamanaka �e���v���[�g���C��
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
    retcode                OUT     VARCHAR2)         --    �G���[�R�[�h        --# �Œ� #
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
    cv_warn_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���������b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
    cv_error_msg_part  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90007'; -- �G���[�I���ꕔ�������b�Z�[�W
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf       VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code VARCHAR2(100);   -- ���b�Z�[�W�R�[�h
-- ������ �ʏ�����}�� --
    lv_error_msg    VARCHAR2(100);   -- �G���[���b�Z�[�W�i�[
-- ������ �ʏ�����}�� --
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
       gn_target_cnt -- �Ώی���
      ,gn_normal_cnt -- ��������
      ,gn_error_cnt  -- �G���[����
      ,gn_warn_cnt   -- �x������
      ,lv_errbuf     -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode    -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      -- �G���[�������A�e�����͈ȉ��ɓ��ꂵ�ďo�͂���
-- ������ �ʏ�����}�� --
      IF (NVL(gn_normal_cnt,0) = 0) THEN
        lv_error_msg := cv_error_msg;
-- ������ �ʏ�����}�� --
        gn_target_cnt := 0;
        gn_normal_cnt := 0;
        gn_error_cnt  := 1;
        gn_warn_cnt   := 0;
-- ������ �ʏ�����}�� --
      ELSE
        lv_error_msg := cv_error_msg_part;
        gn_error_cnt  := 1;
      END IF;
-- ������ �ʏ�����}�� --

    END IF;
--
--###########################  �Œ蕔 START   #####################################################
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
    --�I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
-- ������ �ʏ�����}�� --
--      lv_message_code := cv_error_msg;
      lv_message_code := lv_error_msg;
-- ������ �ʏ�����}�� --
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
END XXCFR005A03C;
/
