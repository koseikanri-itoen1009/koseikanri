CREATE OR REPLACE PACKAGE BODY XXCFR001A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR001A03C(body)
 * Description      : �������f�[�^�A�g
 * MD.050           : MD050_CFR_001_A03_�������f�[�^�A�g
 * MD.070           : MD050_CFR_001_A03_�������f�[�^�A�g
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   p ��������                                (A-1)
 *  get_profile_value      p �v���t�@�C���擾����                    (A-2)
 *  get_last_close_period_name p �Ō�ɃN���[�Y������v���Ԗ��擾    (A-4)
 *  get_cash_receipts_data p �������f�[�^�擾                      (A-5)
 *  put_cash_receipts_data p �������f�[�^�b�r�u�쐬����            (A-6)
 *  submain                p ���C�������v���V�[�W��
 *  main                   p �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/13    1.00 SCS ���� ��      ����쐬
 *  2009/02/27    1.1  SCS T.KANEDA     [��QCFR_001] ���z�擾�s��Ή�
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
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFR001A03C'; -- �p�b�P�[�W��
  cv_msg_kbn_cmn     CONSTANT VARCHAR2(5)   := 'XXCMN'; -- �A�v���P�[�V�����Z�k��(XXCMN)
  cv_msg_kbn_ccp     CONSTANT VARCHAR2(5)   := 'XXCCP'; -- �A�v���P�[�V�����Z�k��(XXCCP)
  cv_msg_kbn_cfr     CONSTANT VARCHAR2(5)   := 'XXCFR'; -- �A�v���P�[�V�����Z�k��(XXCFR)
--
  -- ���b�Z�[�W�ԍ�
--
  cv_msg_001a03_010  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00004'; --�v���t�@�C���擾�G���[���b�Z�[�W
  cv_msg_001a03_011  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00029'; --�t�@�C�����o�̓��b�Z�[�W
  cv_msg_001a03_012  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00024'; --�Ώۃf�[�^��0�����b�Z�[�W
  cv_msg_001a03_013  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00015'; --��v���Ԗ��擾�Ȃ��G���[���b�Z�[�W
  cv_msg_001a03_014  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00047'; --�t�@�C���̏ꏊ���������b�Z�[�W
  cv_msg_001a03_015  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00048'; --�t�@�C�����I�[�v���ł��Ȃ����b�Z�[�W
  cv_msg_001a03_016  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00049'; --�t�@�C���ɏ����݂ł��Ȃ����b�Z�[
  cv_msg_001a03_017  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00050'; --�t�@�C�������݂��Ă��郁�b�Z�[�W
--
-- �g�[�N��
  cv_tkn_prof        CONSTANT VARCHAR2(15) := 'PROF_NAME';        -- �v���t�@�C����
  cv_tkn_file        CONSTANT VARCHAR2(15) := 'FILE_NAME';        -- �t�@�C����
  cv_tkn_path        CONSTANT VARCHAR2(15) := 'FILE_PATH';        -- �t�@�C���p�X
  cv_tkn_table       CONSTANT VARCHAR2(15) := 'TABLE';            -- �e�[�u����
  cv_tkn_data        CONSTANT VARCHAR2(15) := 'DATA';             -- �f�[�^
--
  --�v���t�@�C��
  cv_org_id            CONSTANT VARCHAR2(30) := 'ORG_ID';           -- �g�DID
  cv_set_of_bks_id     CONSTANT VARCHAR2(30) := 'GL_SET_OF_BKS_ID'; -- ��v����ID
  cv_receipt_filename  CONSTANT VARCHAR2(35) := 'XXCFR1_CASH_RECEIPTS_DATA_FILENAME';
                                                                    -- XXCFR:�������f�[�^�t�@�C����
  cv_receipt_filepath  CONSTANT VARCHAR2(35) := 'XXCFR1_CASH_RECEIPTS_DATA_FILEPATH';
                                                                    -- XXCFR: �������f�[�^�t�@�C���i�[�p�X
--
  -- ���{�ꎫ��
  cv_dict_peroid_name  CONSTANT VARCHAR2(100) := 'CFR001A03001';    -- �Ō�ɃN���[�Y������v���Ԗ�
--
  -- ���s�R�[�h
  cv_cr              CONSTANT VARCHAR2(1) := CHR(10);      -- ���s�R�[�h
--
  -- �t�@�C���o��
  cv_file_type_out   CONSTANT VARCHAR2(10) := 'OUTPUT';    -- ���b�Z�[�W�o��
  cv_file_type_log   CONSTANT VARCHAR2(10) := 'LOG';       -- ���O�o��
--
  cv_flag_yes        CONSTANT VARCHAR2(1)  := 'Y';         -- �t���O�i�x�j
  cv_flag_no         CONSTANT VARCHAR2(1)  := 'N';         -- �t���O�i�m�j
--
    cv_format_date_ym CONSTANT VARCHAR2(6)      := 'YYYYMM';            -- ���t�t�H�[�}�b�g�i�N���j
    cv_format_date_ymdhns CONSTANT VARCHAR2(16) := 'YYYYMMDDHH24MISS';  -- ���t�t�H�[�}�b�g�i�N���������b�j
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_org_id                NUMBER;            -- �g�DID
  gn_set_of_bks_id         NUMBER;            -- ��v����ID
  gv_receipt_filename      VARCHAR2(100);     -- �������f�[�^�t�@�C����
  gv_receipt_filepath      VARCHAR2(500);     -- �������f�[�^�t�@�C���i�[�p�X
  gv_period_name           gl_period_statuses.period_name%TYPE;  -- ��v���Ԗ�
  gv_start_date_yymm       VARCHAR2(6);       -- ��v���ԔN��
-- Modify 2009.02.27 Ver1.1 Start
  gd_start_date            DATE;              -- ��v���ԊJ�n��
  gd_end_date              DATE;              -- ��v���ԏI����
-- Modify 2009.02.27 Ver1.1 End
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���J�[�\��
  -- ===============================
    -- ���o
    CURSOR get_cash_receipts_cur
    IS
-- Modify 2009.02.27 Ver1.1 Start
--      SELECT hca_b.account_number           bill_to_account_number,     -- �ڋq�R�[�h�i������ڋq�R�[�h�j
--             gcc.segment1                   company_code,               -- ��ЃR�[�h
--             sum ( jzabv.begin_bal_entered_dr
--                 - jzabv.begin_bal_entered_cr
--                 + jzabv.period_net_entered_dr ) amount_due_remaining,  -- �����\��z
--             sum ( jzabv.period_net_entered_cr ) amount_applied         -- �������ъz
--      FROM jg_zz_ar_balances_v         jzabv,                           -- JG�ڋq�c���e�[�u��
--           hz_cust_accounts            hca_b,                           -- �ڋq�}�X�^�i������j
--           gl_code_combinations        gcc                              -- ����Ȗڑg�����}�X�^
--      WHERE jzabv.period_name          = gv_period_name
--        AND jzabv.set_of_books_id      = gn_set_of_bks_id
--        AND (( jzabv.begin_bal_entered_dr - jzabv.begin_bal_entered_cr <> 0 )
--            OR jzabv.period_net_entered_dr <> 0
--            OR jzabv.period_net_entered_cr <> 0 )
--        AND jzabv.customer_id          = hca_b.cust_account_id(+)
--        AND jzabv.code_combination_id  = gcc.code_combination_id
--      GROUP BY
--        gcc.segment1,
--        hca_b.account_number
--      ORDER BY 
--        hca_b.account_number
      SELECT sub_bal.bill_to_account_number                bill_to_account_number -- �ڋq�R�[�h�i������ڋq�R�[�h�j
            ,sub_bal.customer_id                           customer_id            -- �ڋq�h�c
            ,sub_bal.company_code                          company_code           -- ��ЃR�[�h
            ,( sub_bal.amount_due_remaining
                 - NVL(sub_unapp.unapp_entered_dr ,0) )    amount_due_remaining   -- �����\��z
            ,( sub_bal.amount_applied
                 - NVL( sub_unapp.unapp_entered_cr ,0) )   amount_applied         -- �������ъz
       FROM
            (
             SELECT hca_b.account_number           bill_to_account_number,     -- �ڋq�R�[�h�i������ڋq�R�[�h�j
                    jzabv.customer_id              customer_id,                -- ��ЃR�[�h
                    gcc.segment1                   company_code,               -- ��ЃR�[�h
                    SUM(  jzabv.begin_bal_entered_dr
                        - jzabv.begin_bal_entered_cr
                        + jzabv.period_net_entered_dr ) amount_due_remaining,  -- �����\��z
                    SUM(  jzabv.period_net_entered_cr ) amount_applied         -- �������ъz
             FROM jg_zz_ar_balances_v         jzabv,                           -- JG�ڋq�c���e�[�u��
                  hz_cust_accounts            hca_b,                           -- �ڋq�}�X�^�i������j
                  gl_code_combinations        gcc                              -- ����Ȗڑg�����}�X�^
             WHERE jzabv.period_name          = gv_period_name
               AND jzabv.set_of_books_id      = gn_set_of_bks_id
               AND (( jzabv.begin_bal_entered_dr - jzabv.begin_bal_entered_cr <> 0 )
                   OR jzabv.period_net_entered_dr <> 0
                   OR jzabv.period_net_entered_cr <> 0 )
               AND jzabv.customer_id          = hca_b.cust_account_id(+)
               AND jzabv.code_combination_id  = gcc.code_combination_id
             GROUP BY
               gcc.segment1,
               hca_b.account_number,
               jzabv.customer_id
             ) sub_bal,
            (
             SELECT sum(nvl(jzatd.entered_dr,0)) unapp_entered_dr,
                    sum(nvl(jzatd.entered_cr,0)) unapp_entered_cr,
                    jzatd.customer_id            customer_id
               FROM jg_zz_ar_tmp_detail jzatd
              WHERE jzatd.set_of_books_id = gn_set_of_bks_id
                AND jzatd.accounting_date BETWEEN gd_start_date
                                              AND gd_end_date
                AND jzatd.account_class = 'UNAPP'
              GROUP BY jzatd.customer_id
            ) sub_unapp
       WHERE sub_bal.customer_id = sub_unapp.customer_id(+)
       ORDER BY sub_bal.bill_to_account_number
    ;
-- Modify 2009.02.27 Ver1.1 End
--
    TYPE g_cash_receipts_ttype IS TABLE OF get_cash_receipts_cur%ROWTYPE INDEX BY PLS_INTEGER;
    gt_cash_receipts_data      g_cash_receipts_ttype;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf               OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- ���b�Z�[�W�o��
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_out   -- ���b�Z�[�W�o��
      ,ov_errbuf       => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ���O�o��
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_log   -- ���O�o��
      ,ov_errbuf       => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �v���t�@�C�������v����ID�擾
    gn_set_of_bks_id      := TO_NUMBER(FND_PROFILE.VALUE(cv_set_of_bks_id));
    -- �擾�G���[��
    IF (gn_set_of_bks_id IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_001a03_010 -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof       -- �g�[�N��'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_set_of_bks_id))
                                                       -- ��v����ID
                                                   ,1
                                                   ,5000);
      RAISE global_api_expt;
    END IF;
--
    -- �v���t�@�C������XXCFR:�������f�[�^�t�@�C�����擾
    gv_receipt_filename := FND_PROFILE.VALUE(cv_receipt_filename);
    -- �擾�G���[��
    IF (gv_receipt_filename IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_001a03_010 -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof       -- �g�[�N��'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_receipt_filename))
                                                       -- XXCFR:�������f�[�^�t�@�C����
                                                   ,1
                                                   ,5000);
      RAISE global_api_expt;
    END IF;
--
    -- �v���t�@�C������XXCFR: �������f�[�^�t�@�C���i�[�p�X�擾
    gv_receipt_filepath := FND_PROFILE.VALUE(cv_receipt_filepath);
    -- �擾�G���[��
    IF (gv_receipt_filepath IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_001a03_010 -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof       -- �g�[�N��'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_receipt_filepath))
                                                       -- XXCFR: �������f�[�^�t�@�C���i�[�p�X
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
   * Procedure Name   : get_last_close_period_name
   * Description      : �Ō�ɃN���[�Y������v���Ԗ��擾 (A-4)
   ***********************************************************************************/
  PROCEDURE get_last_close_period_name(
    ov_errbuf               OUT VARCHAR2,            -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT VARCHAR2,            -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT VARCHAR2)            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_last_close_period_name'; -- �v���O������
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
    cv_gl_short_name   CONSTANT VARCHAR2(5)   := 'SQLGL';    -- �A�v���P�[�V�����Z�k���i�f�k)
    cv_flag_no         CONSTANT VARCHAR2(1)   := 'N';        -- �t���O�i�m�j
    cv_close_status_c  CONSTANT VARCHAR2(1)   := 'C';        -- �N���[�Y�X�e�[�^�X�i�N���[�Y)
    cv_close_status_p  CONSTANT VARCHAR2(1)   := 'P';        -- �N���[�Y�X�e�[�^�X�i�i�v�N���[�Y)
--
    -- *** ���[�J���ϐ� ***
    ln_target_cnt     NUMBER;         -- �Ώی���
    ln_loop_cnt       NUMBER;         -- ���[�v�J�E���^
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- �Ō�ɃN���[�Y������v���Ԗ����o
    CURSOR get_period_name_cur
    IS
      SELECT gps.period_name                                period_name,    -- ��v���Ԗ�
-- Modify 2009.02.27 Ver1.1 Start
             gps.start_date                                 start_date,     -- ��v���ԊJ�n��
             gps.end_date                                   end_date,       -- ��v���ԏI����
-- Modify 2009.02.27 Ver1.1 End
             TO_CHAR ( gps.start_date, cv_format_date_ym )  start_date_yymm -- ��v���ԔN��
      FROM gl_period_statuses             gps,          -- GL��v���ԃX�e�[�^�X
           gl_sets_of_books               gsob,         -- GL��v����
           fnd_application                fa            -- ��v�A�v���P�[�V����
      WHERE gps.application_id            = fa.application_id
        AND fa.application_short_name     = cv_gl_short_name   -- �f�k
        AND gps.adjustment_period_flag    = cv_flag_no         -- �������ԂłȂ�
        AND gps.set_of_books_id           = gsob.set_of_books_id
        -- AND gps.closing_status            IN ( 'O','C','P' )   -- �N���[�Y�A�i�v�N���[�Y
        AND gps.closing_status            IN ( cv_close_status_c, cv_close_status_p )  -- �N���[�Y�A�i�v�N���[�Y
        AND gsob.set_of_books_id          = gn_set_of_bks_id
      ORDER BY gps.start_date desc
    ;
--
    TYPE l_period_name_ttype IS TABLE OF get_period_name_cur%ROWTYPE INDEX BY PLS_INTEGER;
    lt_period_name_data      l_period_name_ttype;
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
    OPEN get_period_name_cur;
--
    -- �f�[�^�̈ꊇ�擾
    FETCH get_period_name_cur BULK COLLECT INTO lt_period_name_data;
--
    -- ���������̃Z�b�g
    ln_target_cnt := lt_period_name_data.COUNT;
--
    -- �J�[�\���N���[�Y
    CLOSE get_period_name_cur;
--
    -- �Ώۃf�[�^����̏ꍇ�͂P���ڂ��O���[�o���ϐ��ɐݒ�
    IF (ln_target_cnt > 0) THEN
--
      gv_period_name      := lt_period_name_data(1).period_name;
      gv_start_date_yymm  := lt_period_name_data(1).start_date_yymm;
-- Modify 2009.02.27 Ver1.1 Start
      gd_start_date       := lt_period_name_data(1).start_date;
      gd_end_date         := TO_DATE(TO_CHAR(lt_period_name_data(1).end_date,'yyyymmdd')||'235959','yyyymmddhh24miss');
-- Modify 2009.02.27 Ver1.1 End
--
    -- �Ώۃf�[�^�Ȃ��̏ꍇ�́A�G���[���b�Z�[�W��ݒ�
    ELSE
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_001a03_013 -- ��v���Ԗ��擾�Ȃ��G���[
                                                    ,cv_tkn_data
                                                    ,xxcfr_common_pkg.lookup_dictionary(
                                                       cv_msg_kbn_cfr
                                                      ,cv_dict_peroid_name 
                                                     )
                                                   )
                                                   ,1
                                                   ,5000);
      RAISE global_api_expt;
--
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
  END get_last_close_period_name;
--
  /**********************************************************************************
   * Procedure Name   : get_cash_receipts_data
   * Description      : �������f�[�^�擾 (A-5)
   ***********************************************************************************/
  PROCEDURE get_cash_receipts_data(
    ov_errbuf               OUT VARCHAR2,            -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT VARCHAR2,            -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT VARCHAR2)            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_cash_receipts_data'; -- �v���O������
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
    OPEN get_cash_receipts_cur;
--
    -- �f�[�^�̈ꊇ�擾
    FETCH get_cash_receipts_cur BULK COLLECT INTO gt_cash_receipts_data;
--
    -- ���������̃Z�b�g
    gn_target_cnt := gt_cash_receipts_data.COUNT;
--
    -- �J�[�\���N���[�Y
    CLOSE get_cash_receipts_cur;
--
    IF gn_target_cnt = 0 THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_001a03_012 -- �Ώۃf�[�^��0���G���[
                                                   )
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
  END get_cash_receipts_data;
--
  /**********************************************************************************
   * Procedure Name   : put_cash_receipts_data
   * Description      : �������f�[�^�b�r�u�쐬���� (A-6)
   ***********************************************************************************/
  PROCEDURE put_cash_receipts_data(
    ov_errbuf               OUT VARCHAR2,            -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT VARCHAR2,            -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT VARCHAR2)            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put_cash_receipts_data'; -- �v���O������
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
    cv_open_mode_w    CONSTANT VARCHAR2(10) := 'w';     -- �t�@�C���I�[�v�����[�h�i�㏑���j
    cv_delimiter      CONSTANT VARCHAR2(1)  := ',';     -- CSV��؂蕶��
    cv_enclosed       CONSTANT VARCHAR2(2)  := '"';     -- �P��͂ݕ���
--
    -- *** ���[�J���ϐ� ***
    ln_target_cnt   NUMBER;         -- �Ώی���
    ln_loop_cnt     NUMBER;         -- ���[�v�J�E���^
    -- 
    -- �t�@�C���o�͊֘A
    lf_file_hand        UTL_FILE.FILE_TYPE ;    -- �t�@�C���E�n���h���̐錾
    lv_csv_text         VARCHAR2(32000) ;       -- �o�͂P�s��������ϐ�
    lb_fexists          BOOLEAN;                -- �t�@�C�������݂��邩�ǂ���
    ln_file_size        NUMBER;                 -- �t�@�C���̒���
    ln_block_size       NUMBER;                 -- �t�@�C���V�X�e���̃u���b�N�T�C�Y
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
    -- �t�s�k�t�@�C�����݃`�F�b�N
    -- ====================================================
    UTL_FILE.FGETATTR(gv_receipt_filepath,
                      gv_receipt_filename,
                      lb_fexists,
                      ln_file_size,
                      ln_block_size);
--
    -- �O��t�@�C�������݂��Ă���
    IF lb_fexists THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_001a03_017 -- �t�@�C�������݂��Ă���
                                                   )
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- ====================================================
    -- �t�s�k�t�@�C���I�[�v��
    -- ====================================================
    lf_file_hand := UTL_FILE.FOPEN
                      (
                        gv_receipt_filepath
                       ,gv_receipt_filename
                       ,cv_open_mode_w
                      ) ;
--
    -- ====================================================
    -- �o�̓f�[�^���o
    -- ====================================================
    <<out_loop>>
    FOR ln_loop_cnt IN gt_cash_receipts_data.FIRST..gt_cash_receipts_data.LAST LOOP
--
      -- �o�͕�����쐬
      lv_csv_text := cv_enclosed || gt_cash_receipts_data(ln_loop_cnt).company_code || cv_enclosed || cv_delimiter
                  || gv_start_date_yymm || cv_delimiter
                  || cv_enclosed || gt_cash_receipts_data(ln_loop_cnt).bill_to_account_number || cv_enclosed || cv_delimiter
                  || TO_CHAR ( gt_cash_receipts_data(ln_loop_cnt).amount_due_remaining ) ||  cv_delimiter
                  || TO_CHAR ( gt_cash_receipts_data(ln_loop_cnt).amount_applied ) || cv_delimiter
                  || TO_CHAR ( cd_last_update_date, cv_format_date_ymdhns)
      ;
--
      -- ====================================================
      -- �t�@�C����������
      -- ====================================================
      UTL_FILE.PUT_LINE( lf_file_hand, lv_csv_text ) ;
--
      -- ====================================================
      -- ���������J�E���g�A�b�v
      -- ====================================================
      ln_target_cnt := ln_target_cnt + 1 ;
--
    END LOOP out_loop;
--
    -- ====================================================
    -- �t�s�k�t�@�C���N���[�Y
    -- ====================================================
    UTL_FILE.FCLOSE( lf_file_hand ) ;
--
    gn_normal_cnt := ln_target_cnt;
--
  EXCEPTION
    -- *** �t�@�C���̏ꏊ�������ł� ***
    WHEN UTL_FILE.INVALID_PATH THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_001a03_014 -- �t�@�C���̏ꏊ������
                                                   )
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** �v���ǂ���Ƀt�@�C�����I�[�v���ł��Ȃ����A�܂��͑���ł��܂��� ***
    WHEN UTL_FILE.INVALID_OPERATION THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_001a03_015 -- �t�@�C�����I�[�v���ł��Ȃ�
                                                   )
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** �����ݑ��쒆�ɃI�y���[�e�B���O�E�V�X�e���̃G���[���������܂��� ***
    WHEN UTL_FILE.WRITE_ERROR THEN
      --���t�@�C���N���[�Y�֐���ǉ�
      IF UTL_FILE.IS_OPEN ( lf_file_hand ) then
        UTL_FILE.FCLOSE( lf_file_hand );
      END IF;
      gn_normal_cnt := ln_target_cnt;
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_001a03_016 -- �t�@�C���ɏ����݂ł��Ȃ�
                                                   )
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      --���t�@�C���N���[�Y�֐���ǉ�
      IF UTL_FILE.IS_OPEN ( lf_file_hand ) then
        UTL_FILE.FCLOSE( lf_file_hand );
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      --���t�@�C���N���[�Y�֐���ǉ�
      IF UTL_FILE.IS_OPEN ( lf_file_hand ) then
        UTL_FILE.FCLOSE( lf_file_hand );
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      --���t�@�C���N���[�Y�֐���ǉ�
      IF UTL_FILE.IS_OPEN ( lf_file_hand ) then
        UTL_FILE.FCLOSE( lf_file_hand );
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END put_cash_receipts_data;
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
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    --  �������f�[�^�t�@�C����񃍃O����(A-3)
    -- =====================================================
    lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                  ,cv_msg_001a03_011 -- �t�@�C�����o�̓��b�Z�[�W
                                                  ,cv_tkn_file       -- �g�[�N��'FILE_NAME'
                                                  ,gv_receipt_filename)      -- �t�@�C����
                                                ,1
                                                ,5000);
    FND_FILE.PUT_LINE(
       FND_FILE.OUTPUT
      ,lv_errmsg
    );
--
    --�P�s���s
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => '' --���[�U�[�E�G���[���b�Z�[�W
    );
--
    -- =====================================================
    --  �Ō�ɃN���[�Y������v���Ԗ��擾 (A-4)
    -- =====================================================
    get_last_close_period_name(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  �������f�[�^�擾 (A-5)
    -- =====================================================
    get_cash_receipts_data(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  �������f�[�^�b�r�u�쐬���� (A-6)
    -- =====================================================
    put_cash_receipts_data(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- ���팏���̐ݒ�
    gn_normal_cnt := gn_target_cnt - gn_error_cnt;
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
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_file_type_out
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
       lv_errbuf     -- �G���[�E���b�Z�[�W           --# �Œ� #
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
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
    END IF;
    --�G���[�̏ꍇ�A�V�X�e���G���[���b�Z�[�W�o��
    IF (lv_retcode = cv_status_error) THEN
      -- �G���[�o�b�t�@�̃��b�Z�[�W�A��
      lv_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
--
    --�P�s���s
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => '' --���[�U�[�E�G���[���b�Z�[�W
    );
-- Add End   2008/11/18 SCS H.Nakamura �e���v���[�g���C��
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
-- Add Start 2008/11/18 SCS H.Nakamura �e���v���[�g���C��
    --�P�s���s
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
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
END XXCFR001A03C;
/
