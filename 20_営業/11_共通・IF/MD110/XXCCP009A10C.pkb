CREATE OR REPLACE PACKAGE BODY XXCCP009A10C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCCP009A10C(body)
 * Description      : AR-�s������������i�ݕ��j�ڍ׎擾
 * MD.070           : AR-�s������������i�ݕ��j�ڍ׎擾 (MD070_IPO_CCP_009_A10)
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2014/12/16     1.0  SCSK K.Nakatsu   [E_�{�ғ�_12777]�V�K�쐬
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
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCCP009A10C'; -- �p�b�P�[�W��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_period_name  IN  VARCHAR2,     --   ��v����
    ov_errbuf       OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- AR-�s������������i�ݕ��j�擾
    CURSOR unid_sus_receipt_cur
      IS
        SELECT /*+ USE_NL(acra arm arc fu papf base_hp base_hc gcc araa)
               */
           acra.creation_date             AS creation_date           -- �����쐬��
          ,acra.receipt_number            AS receipt_number          -- �����ԍ�
          ,acra.doc_sequence_value        AS doc_sequence_value      -- �����ԍ�
          ,acra.receipt_date              AS receipt_date            -- ������
          ,acra.amount                    AS amount                  -- �����z
          ,(SELECT cash_hc.account_number
            FROM   hz_parties       cash_hp
                  ,hz_cust_accounts cash_hc
            WHERE  acra.pay_from_customer = cash_hc.cust_account_id
            AND    cash_hc.party_id = cash_hp.party_id
            AND    cash_hc.status   = 'A'
           )                              AS pay_from_cust_code      -- �����ڋq�ԍ�
          ,(SELECT cash_hp.party_name
            FROM   hz_parties       cash_hp
                  ,hz_cust_accounts cash_hc
            WHERE  acra.pay_from_customer = cash_hc.cust_account_id
            AND    cash_hc.party_id = cash_hp.party_id
            AND    cash_hc.status   = 'A'
           )                              AS pay_from_cust_name      -- �����ڋq��
          ,DECODE( acra.status
                  ,'CCRR'    , '�N���W�b�g�E�J�[�h�ԍϖ߂�����'
                  ,'NSF'     , '��s���ϕs��'
                  ,'STOP'    , '�x����~'
                  ,'APP'     , '������'
                  ,'UNID'    , '�s��'
                  ,'UNAPP'   , '������'
                  ,'REV'     , '�߂�����-���[�U�[�E�G���[')
                                          AS receipt_status          -- �����X�e�[�^�X
          ,arc.name                       AS receipt_class           -- �����敪
          ,arm.name                       AS receipt_method          -- �x�����@
          ,acra.attribute1                AS kana_name               -- �U���l�J�i��
          ,papf.full_name                 AS last_updated_name       -- �ŏI�X�V��
          ,acra.last_update_date          AS last_update_date        -- �ŏI�X�V��
          ,base_hc.account_number         AS base_code               -- ���_�R�[�h
          ,base_hp.party_name             AS base_name               -- ���_��
          ,NVL(araa.amount_applied,0)     AS amount_applied          -- �����z
        FROM   ar_cash_receipts_all       acra       -- AR�����e�[�u��
          ,ar_receipt_methods             arm        -- AR�x�����@�e�[�u��
          ,ar_receipt_classes             arc        -- AR�����敪�e�[�u��
          ,fnd_user                       fu         -- ���[�U�[�}�X�^
          ,per_all_people_f               papf       -- �]�ƈ��}�X�^
          ,hz_parties                     base_hp    -- �p�[�e�B���}�X�^
          ,hz_cust_accounts               base_hc    -- �ڋq�}�X�^
          ,ar_receivable_applications_all araa       -- ���������e�[�u��
          ,gl_code_combinations           gcc        -- ����Ȗڑg�����}�X�^
        WHERE  1 = 1
        --AND    acra.org_id            = 2424
        AND    acra.receipt_method_id = arm.receipt_method_id
        AND    arm.receipt_class_id   = arc.receipt_class_id
        AND    acra.last_updated_by   = fu.user_id
        AND    fu.employee_id         = papf.person_id
        AND    papf.current_employee_flag = 'Y'
        AND    acra.last_update_date BETWEEN papf.effective_start_date AND papf.effective_end_date
        AND    papf.attribute28       = base_hc.account_number
        AND    base_hc.party_id       = base_hp.party_id
        AND    base_hc.customer_class_code = '1'
        AND    base_hc.status              = 'A'
        AND   araa.gl_date >= TO_DATE(iv_period_name, 'YYYY-MM')
        AND   araa.gl_date <= ADD_MONTHS(TO_DATE(iv_period_name, 'YYYY-MM'),1) -1
        AND   araa.application_type = 'CASH'
        AND   araa.amount_applied   > 0                           -- ����� �v���X=�ݕ� (�}�C�i�X���z=�ؕ�)
        AND   araa.code_combination_id = gcc.code_combination_id
        AND   gcc.segment3          IN ('41803')                  -- �����
        AND   araa.status           = 'UNID'
        AND   araa.cash_receipt_id  = acra.cash_receipt_id
        ;
    -- ���R�[�h�^
    unid_sus_receipt_rec unid_sus_receipt_cur%ROWTYPE;
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
    -- ===============================
    -- init��
    -- ===============================
    -- ���p�����[�^�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => '�Ώۊ���: ' || iv_period_name
    );
    -- ��s�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => NULL
    );
    -- ���e�����ŕK�v�ȃv���t�@�C���l�A�N�C�b�N�R�[�h�l���Œ�l�Őݒ�
--
    -- ===============================
    -- ������
    -- ===============================
--
    -- ���ږ��o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => '"�����쐬��","�����ԍ�","�����ԍ�","������","�����z","�����ڋq�ԍ�","�����ڋq��","�����X�e�[�^�X","�����敪","�x�����@","�U���l�J�i��","�ŏI�X�V��","�ŏI�X�V��","���_�R�[�h","���_��","�����z"'
    );
    -- �f�[�^���o��(CSV)
    FOR unid_sus_receipt_rec IN unid_sus_receipt_cur
     LOOP
       --�����Z�b�g
       gn_target_cnt := gn_target_cnt + 1;
       --�ύX���鍀�ڋy�уL�[�����o��
       FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => '"'|| TO_CHAR(unid_sus_receipt_rec.creation_date, 'YYYY/MM/DD HH24:MI:SS')              || '","'
                       || unid_sus_receipt_rec.receipt_number                                               || '","'
                       || unid_sus_receipt_rec.doc_sequence_value                                           || '","'
                       || TO_CHAR(unid_sus_receipt_rec.receipt_date, 'YYYY/MM/DD HH24:MI:SS')               || '","'
                       || unid_sus_receipt_rec.amount                                                       || '","'
                       || unid_sus_receipt_rec.pay_from_cust_code                                           || '","'
                       || unid_sus_receipt_rec.pay_from_cust_name                                           || '","'
                       || unid_sus_receipt_rec.receipt_status                                               || '","'
                       || unid_sus_receipt_rec.receipt_class                                                || '","'
                       || unid_sus_receipt_rec.receipt_method                                               || '","'
                       || unid_sus_receipt_rec.kana_name                                                    || '","'
                       || unid_sus_receipt_rec.last_updated_name                                            || '","'
                       || TO_CHAR(unid_sus_receipt_rec.last_update_date, 'YYYY/MM/DD HH24:MI:SS')           || '","'
                       || unid_sus_receipt_rec.base_code                                                    || '","'
                       || unid_sus_receipt_rec.base_name                                                    || '","'
                       || unid_sus_receipt_rec.amount_applied                                               || '"'
       );
    END LOOP;
--
    -- �����������Ώی���
    gn_normal_cnt  := gn_target_cnt;
    -- �Ώی���=0�ł���Όx��
    IF (gn_target_cnt = 0) THEN
      gn_warn_cnt    := 1;
      ov_retcode     := cv_status_warn;
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
    errbuf          OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode         OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_period_name  IN  VARCHAR2       --   ��v����
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
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- �v���O������
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
    lv_errbuf          VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code    VARCHAR2(100);   -- �I�����b�Z�[�W�R�[�h
    --
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       iv_which   => 'LOG'
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
       iv_period_name -- ��v����
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
      gn_error_cnt := 1;
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
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
    --�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
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
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
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
END XXCCP009A10C;
/
