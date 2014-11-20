CREATE OR REPLACE PACKAGE BODY XXCFR003A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR003A01C(body)
 * Description      : �����f�[�^�폜
 * MD.050           : MD050_CFR_003_A01_�����f�[�^�폜
 * MD.070           : MD050_CFR_003_A01_�����f�[�^�폜
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  out_log_inparam        ���̓p�����[�^�l���O�o��     (A-1)
 *  get_profile_value      �v���t�@�C���擾����         (A-2)
 *  get_del_period         �ێ��ΏۊO���t�擾����       (A-3)
 *  del_inv_detail         �������׏��폜����         (A-4)
 *  del_inv_header         �����w�b�_���폜����       (A-5)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-10-31    1.0  SCS ��� �b      ����쐬
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
  cn_created_by             CONSTANT NUMBER := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE   := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE   := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE   := SYSDATE;                    --PROGRAM_UPDATE_DATE
  cv_msg_part      CONSTANT VARCHAR2(3)     := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3)     := '.';
  cv_msg_pnt       CONSTANT VARCHAR2(3)     := ',';
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
  gn_target_h_cnt  NUMBER;                   -- �Ώی���(�w�b�_)
  gn_normal_h_cnt  NUMBER;                   -- ���팏��(�w�b�_)
  gn_target_d_cnt  NUMBER;                   -- �Ώی���(����)
  gn_normal_d_cnt  NUMBER;                   -- ���팏��(����)
  gn_error_cnt     NUMBER;                   -- �G���[����
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
  profile_expt              EXCEPTION;     -- �v���t�@�C���擾�G���[
  lock_expt                 EXCEPTION;     -- ���b�N�擾�G���[
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  -- ���b�Z�[�W�p�萔
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFR003A01C'; -- �p�b�P�[�W��
  cv_msg_kbn_cmn     CONSTANT VARCHAR2(5)   := 'XXCMN';
  cv_msg_kbn_ccp     CONSTANT VARCHAR2(5)   := 'XXCCP';
  cv_msg_kbn_cfr     CONSTANT VARCHAR2(5)   := 'XXCFR';
--
  -- ���b�Z�[�W�ԍ�
  cv_msg_003a01_001  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90000'; --�Ώی������b�Z�[�W  �F�w�b�_
  cv_msg_003a01_002  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90001'; --�����������b�Z�[�W  �F�w�b�_
  cv_msg_003a01_003  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90002'; --�G���[�������b�Z�[�W�F�w�b�_
  cv_msg_003a01_004  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90000'; --�Ώی������b�Z�[�W  �F����
  cv_msg_003a01_005  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90001'; --�����������b�Z�[�W  �F����
  cv_msg_003a01_006  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90002'; --�G���[�������b�Z�[�W�F����
  cv_msg_003a01_007  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90004'; --����I�����b�Z�[�W
  cv_msg_003a01_008  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90006'; --�G���[�I���S���[���o�b�N���b�Z�[�W
--
  cv_msg_003a01_009  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00018'; --�����^�C�g���F�w�b�_
  cv_msg_003a01_010  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00019'; --�����^�C�g���F����
  cv_msg_003a01_011  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00004'; --�v���t�@�C���擾�G���[���b�Z�[�W
  cv_msg_003a01_012  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00006'; --�Ɩ��������t�擾�G���[���b�Z�[�W
  cv_msg_003a01_013  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00003'; --���b�N�G���[���b�Z�[�W
  cv_msg_003a01_014  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00007'; --�f�[�^�폜�G���[���b�Z�[�W
--
  -- �g�[�N��
  cv_tkn_prof        CONSTANT VARCHAR2(15) := 'PROF_NAME';        -- �v���t�@�C����
  cv_tkn_table       CONSTANT VARCHAR2(15) := 'TABLE';            -- �e�[�u����
--
  --�v���t�@�C��
  cv_org_id          CONSTANT VARCHAR2(30) := 'ORG_ID';                           -- �g�DID
  cv_account_id      CONSTANT VARCHAR2(30) := 'SET_OF_BOOKS_ID';                  -- ��v����ID
  cv_tkn_profn       CONSTANT VARCHAR2(35) := 'XXCFR1_INVOICE_DATA_RESERVE_DATE'; -- �ۑ�����
  -- �g�pDB��
  cv_tkn_d_tab       CONSTANT VARCHAR2(50) := 'XXCFR_INVOICE_LINES';   -- �������׏��e�[�u��
  cv_tkn_h_tab       CONSTANT VARCHAR2(50) := 'XXCFR_INVOICE_HEADERS'; -- �����w�b�_���e�[�u��
  -- ���b�Z�[�W�o�͋敪
  cv_file_type_out   CONSTANT VARCHAR2(50) := 'OUTPUT';
  cv_file_type_log   CONSTANT VARCHAR2(50) := 'LOG';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- �萔
  gn_inv_keep_period          NUMBER;                     -- �v���t�@�C���F�ۑ�����
  gd_process_date             DATE;                       -- �Ɩ����t
  gd_del_date                 DATE;                       -- �������ێ��ΏۊO���t
--
  /**********************************************************************************
   * Procedure Name   : out_log_inparam
   * Description      : ���̓p�����[�^�l���O�o�͏��� (A-1)
   ***********************************************************************************/
  PROCEDURE out_log_inparam(
    ov_errbuf   OUT  VARCHAR2,  -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode  OUT  VARCHAR2,  -- 2.���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg   OUT  VARCHAR2)  -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'out_log_inparam'; -- �v���O������
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
    -- ���b�Z�[�W�o��
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_out   -- ���b�Z�[�W�o��
      ,ov_errbuf       => ov_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => ov_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => ov_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ���O�o��
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_log   -- ���O�o��
      ,ov_errbuf       => ov_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => ov_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => ov_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode <> cv_status_normal) THEN
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
  END out_log_inparam;
--
  /**********************************************************************************
   * Procedure Name   : get_profile_value
   * Description      : �v���t�@�C���擾���� (A-2)
   ***********************************************************************************/
  PROCEDURE get_profile_value(
    ov_errbuf   OUT  VARCHAR2,  -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode  OUT  VARCHAR2,  -- 2.���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg   OUT  VARCHAR2)  -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- �v���t�@�C���F�ۑ����Ԃ̎擾
    gn_inv_keep_period := TO_NUMBER( FND_PROFILE.VALUE(cv_tkn_profn) );
    -- �擾�G���[��
    IF (gn_inv_keep_period IS NULL) THEN
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(cv_msg_kbn_cfr     -- �A�v���P�[�V�����Z�k��
                                                    ,cv_msg_003a01_011  -- ���b�Z�[�W
                                                    ,cv_tkn_prof        -- �g�[�N���R�[�h
                                                     -- �g�[�N���FXXCFR:�����f�[�^�ێ�����
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_tkn_profn))
                          ,1
                          ,5000);
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
   * Procedure Name   : get_del_period
   * Description      : �ێ��ΏۊO���t�擾���� (A-3)
   ***********************************************************************************/
  PROCEDURE get_del_period(
    ov_errbuf   OUT  VARCHAR2,  -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode  OUT  VARCHAR2,  -- 2.���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg   OUT  VARCHAR2)  -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_del_period'; -- �v���O������
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
    --���ʊ֐��u�Ɩ��������t�擾�֐��v�ɂ��Ɩ��������t���擾
    gd_process_date := xxccp_common_pkg2.get_process_date;
    --�擾���ʂ�NULL�Ȃ�΃G���[
    IF (gd_process_date IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                                                    cv_msg_kbn_cfr     -- �A�v���P�[�V�����Z�k���FXXCFR
                                                   ,cv_msg_003a01_012) -- ���b�Z�[�W�FAPP-XXCFR1-00006
                          ,1
                          ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --�������ێ��ΏۊO���t���擾
    --�Ɩ����t(DATE�^)�|�ۑ�����(NUMBER�^)
    gd_del_date := TRUNC(gd_process_date) - gn_inv_keep_period;
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
  END get_del_period;
--
  /**********************************************************************************
   * Procedure Name   : del_inv_detail
   * Description      : �������׏��폜���� (A-4)
   ***********************************************************************************/
  PROCEDURE del_inv_detail(
    ov_errbuf           OUT NOCOPY VARCHAR2,   -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,   -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2)   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_inv_detail'; -- �v���O������
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
    ln_del_count NUMBER :=0;
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �e�[�u�����b�N�J�[�\��
    CURSOR del_table_d_cur
    IS
      SELECT xil.invoice_id invoice_id
      FROM xxcfr_invoice_lines xil
      WHERE  EXISTS(
        SELECT 'x'
        FROM   xxcfr_invoice_headers xih
        WHERE  xih.invoice_id = xil.invoice_id    -- �ꊇ������ID
          AND  xih.inv_creation_date <= gd_del_date ) -- �������ێ��ΏۊO���t
        FOR UPDATE OF xil.invoice_id NOWAIT;
--
    -- *** ���[�J���E���R�[�h ***
--
  xxcfr_del_rec    del_table_d_cur%ROWTYPE;
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
    -- �J�[�\���I�[�v��
    OPEN del_table_d_cur;
    BEGIN
      <<delete_lines_loop>>
      LOOP
        FETCH del_table_d_cur INTO xxcfr_del_rec;
        EXIT delete_lines_loop WHEN del_table_d_cur%NOTFOUND;
        --�Ώۃf�[�^���폜
        DELETE FROM xxcfr_invoice_lines xil
        WHERE  CURRENT OF del_table_d_cur;
        -- ���������J�E���g
        ln_del_count := ln_del_count + 1; 
      END LOOP delete_lines_loop;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                      ,cv_msg_003a01_014 -- �f�[�^�폜�G���[
                                                      ,cv_tkn_table         -- �g�[�N��'TABLE'
                                                      ,xxcfr_common_pkg.get_table_comment(cv_tkn_d_tab))
                                                       -- �������׏��e�[�u��
                                                      ,1
                                                      ,5000);
        lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
        -- �J�[�\���N���[�Y
        CLOSE del_table_d_cur;
        RAISE global_api_expt;
    END;
--
    -- ���������̃Z�b�g
    gn_target_d_cnt := ln_del_count;
    gn_normal_d_cnt := ln_del_count;
    -- �J�[�\���N���[�Y
    CLOSE del_table_d_cur;
--
  EXCEPTION
--
    WHEN lock_expt THEN  -- �e�[�u�����b�N�G���[
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                                                     cv_msg_kbn_cfr        -- 'XXCFR'
                                                    ,cv_msg_003a01_013    -- �e�[�u�����b�N�G���[
                                                    ,cv_tkn_table         -- �g�[�N��'TABLE'
                                                    ,xxcfr_common_pkg.get_table_comment( -- �������׏��e�[�u��
                                                                                        cv_tkn_d_tab
                                                                                        ) )
                          ,1
                          ,5000);
      lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(
                            cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf
                           ,1
                           ,5000);
      ov_retcode := cv_status_error;
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
  END del_inv_detail;
--
  /**********************************************************************************
   * Procedure Name   : del_inv_header
   * Description      : �����w�b�_���폜���� (A-5)
   ***********************************************************************************/
  PROCEDURE del_inv_header(
    ov_errbuf           OUT NOCOPY VARCHAR2,   -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,   -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2)   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
      -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_inv_detail'; -- �v���O������
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
    ln_del_h_count NUMBER :=0;
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �e�[�u�����b�N�J�[�\��
    CURSOR del_table_h_cur
    IS
      SELECT xih.invoice_id invoice_id
      FROM   xxcfr_invoice_headers xih         -- �����w�b�_���
      WHERE  xih.inv_creation_date <= gd_del_date  -- �������ێ��ΏۊO���t
      FOR UPDATE OF xih.invoice_id NOWAIT;
--
    -- *** ���[�J���E���R�[�h ***
--
  xxcfr_del_h_rec    del_table_h_cur%rowtype;
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
    OPEN del_table_h_cur;
    BEGIN
      <<delete_headers_loop>>
      LOOP
        FETCH del_table_h_cur INTO xxcfr_del_h_rec;
        EXIT delete_headers_loop WHEN del_table_h_cur%NOTFOUND;
        --�Ώۃf�[�^���폜
        DELETE FROM xxcfr_invoice_headers xih
        WHERE  CURRENT OF del_table_h_cur;
        -- ���������J�E���g
        ln_del_h_count := ln_del_h_count + 1;
      END LOOP delete_headers_loop;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                      ,cv_msg_003a01_014 -- �f�[�^�폜�G���[
                                                      ,cv_tkn_table         -- �g�[�N��'TABLE'
                                                      ,xxcfr_common_pkg.get_table_comment(cv_tkn_h_tab))
                                                       --�����w�b�_���e�[�u��
                                                      ,1
                                                      ,5000);
        lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
        -- �J�[�\���N���[�Y
        CLOSE del_table_h_cur;
        RAISE global_api_expt;
    END;
    -- ���������̃Z�b�g
    gn_target_h_cnt := ln_del_h_count;
    gn_normal_h_cnt := ln_del_h_count;
    -- �J�[�\���N���[�Y
    CLOSE del_table_h_cur;
--
  EXCEPTION
--
    WHEN lock_expt THEN  -- �e�[�u�����b�N�G���[
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg( cv_msg_kbn_cfr        -- 'XXCFR'
                                                     ,cv_msg_003a01_013    -- �e�[�u�����b�N�G���[
                                                     ,cv_tkn_table         -- �g�[�N��'TABLE'
                                                     --�����w�b�_���e�[�u��
                                                     ,xxcfr_common_pkg.get_table_comment(cv_tkn_h_tab))
                          ,1
                          ,5000);
      lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(
                            cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf
                           ,1
                           ,5000);
      ov_retcode := cv_status_error;
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
  END del_inv_header;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
--
    -- �O���[�o���ϐ��̏�����
    gn_target_h_cnt := 0;
    gn_normal_h_cnt := 0;
    gn_target_d_cnt := 0;
    gn_normal_d_cnt := 0;
    gn_error_cnt    := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- =====================================================
    --  ���̓p�����[�^�l���O�o�� (A-1)
    -- =====================================================
    out_log_inparam(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  �v���t�@�C���擾���� (A-2)
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
    --  �ێ��ΏۊO���t�擾���� (A-3)
    -- =====================================================
    get_del_period(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  �������׏��폜���� (A-4)
    -- =====================================================
    del_inv_detail(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  �����w�b�_���폜���� (A-5)
    -- =====================================================
    del_inv_header(
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
    errbuf        OUT     VARCHAR2,         --    �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT     VARCHAR2          --    �G���[�R�[�h     #�Œ�#
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
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf       VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code VARCHAR2(100);   --���b�Z�[�W�R�[�h
--
    cv_normal_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; --����I�����b�Z�[�W
    cv_warn_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; --�x���I�����b�Z�[�W
    cv_error_msg CONSTANT VARCHAR2(100)  := 'APP-XXCCP1-90006'; --�x���I�����b�Z�[�W
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
            lv_errbuf     -- �G���[�E���b�Z�[�W           --# �Œ� #
           ,lv_retcode    -- ���^�[���E�R�[�h             --# �Œ� #
           ,lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      -- �G���[�������A�e�����͈ȉ��ɓ��ꂵ�ďo�͂���
      gn_target_h_cnt := 0;
      gn_normal_h_cnt := 0;
      gn_target_d_cnt := 0;
      gn_normal_d_cnt := 0;
      gn_error_cnt    := 1;
    END IF;
--
--###########################  �Œ蕔 START   #####################################################
--
    --����łȂ��ꍇ�A�G���[�o��
    IF (lv_retcode <> cv_status_normal) THEN
      -- �G���[�o�b�t�@�̃��b�Z�[�W�A��
      lv_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      -- ���b�Z�[�W�o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      --�P�s���s
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
    END IF;
    --�G���[�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_errbuf --�G���[���b�Z�[�W
    );
    --�����^�C�g���F�w�b�_
    gv_out_msg := xxccp_common_pkg.get_msg(
                                           iv_application  => cv_msg_kbn_cfr
                                          ,iv_name         => cv_msg_003a01_009
                  );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                                           iv_application  => cv_msg_kbn_ccp
                                          ,iv_name         => cv_msg_003a01_001
                                          ,iv_token_name1  => 'COUNT'
                                          ,iv_token_value1 => TO_CHAR(gn_target_h_cnt)
                  );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                                           iv_application  => cv_msg_kbn_ccp
                                          ,iv_name         => cv_msg_003a01_002
                                          ,iv_token_name1  => 'COUNT'
                                          ,iv_token_value1 => TO_CHAR(gn_normal_h_cnt)
                  );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                                           iv_application  => cv_msg_kbn_ccp
                                          ,iv_name         => cv_msg_003a01_003
                                          ,iv_token_name1  => 'COUNT'
                                          ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                  );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --�����^�C�g���F����
    gv_out_msg := xxccp_common_pkg.get_msg(
                                           iv_application  => cv_msg_kbn_cfr
                                          ,iv_name         => cv_msg_003a01_010
                  );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                                           iv_application  => cv_msg_kbn_ccp
                                          ,iv_name         => cv_msg_003a01_001
                                          ,iv_token_name1  => 'COUNT'
                                          ,iv_token_value1 => TO_CHAR(gn_target_d_cnt)
                  );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                                           iv_application  => cv_msg_kbn_ccp
                                          ,iv_name         => cv_msg_003a01_002
                                          ,iv_token_name1  => 'COUNT'
                                          ,iv_token_value1 => TO_CHAR(gn_normal_d_cnt)
                  );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                                           iv_application  => cv_msg_kbn_ccp
                                          ,iv_name         => cv_msg_003a01_003
                                          ,iv_token_name1  => 'COUNT'
                                          ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                  );
    fnd_file.put_line(
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
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                                           iv_application  => cv_msg_kbn_ccp
                                          ,iv_name         => lv_message_code
                  );
    --�P�s���s
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    fnd_file.put_line(
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
END XXCFR003A01C;
/
