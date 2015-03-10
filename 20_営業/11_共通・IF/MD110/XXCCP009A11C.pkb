CREATE OR REPLACE PACKAGE BODY XXCCP009A11C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCCP009A11C(body)
 * Description      : ���|�������c���i�ڋq�ʕ⏕�ȖڕʃT�}���j�擾
 * MD.070           : ���|�������c���i�ڋq�ʕ⏕�ȖڕʃT�}���j�擾(MD070_IPO_CCP_009_A11)
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
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCCP009A11C'; -- �p�b�P�[�W��
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
    iv_period_name  IN  jg_zz_ar_balances.period_name%TYPE,     --   ��v����
    ov_errbuf       OUT VARCHAR2,                               --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT VARCHAR2,                               --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT VARCHAR2)                               --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- ���|�������c���i�ڋq�ʕ⏕�ȖڕʃT�}���j�擾
    CURSOR jg_balance_cur
      IS
        SELECT 
           /*+ 
               FIRST_ROWS
               LEADING(a hca hcp gcc)
           */
           hca.account_number                                             AS account_number               -- �ڋq�ԍ�
          ,hcp.party_name                                                 AS party_name                   -- �ڋq��
          ,jgblc.period_name                                              AS period_name                  -- ��v����
          ,gcc.segment3                                                   AS aff_account_code             -- ����Ȗ�
          ,(SELECT a.aff_account_name
            FROM xxcff_aff_account_v a
            WHERE gcc.segment3 = a.aff_account_code)                      AS aff_account_name             -- ����Ȗږ�
          ,gcc.segment4                                                   AS aff_sub_account_cooe         -- �⏕�Ȗ�
          ,(SELECT a.aff_sub_account_name
            FROM xxcff_aff_sub_account_v a
            WHERE gcc.segment4 = a.aff_sub_account_code
            AND gcc.segment3   = a.aff_account_name)                      AS aff_sub_account_name         -- �⏕�Ȗږ�
          ,SUM(NVL(jgblc.begin_bal_accounted_dr,0))                       AS sum_begin_bal_accounted_dr   -- ����ؕ�
          ,SUM(NVL(jgblc.begin_bal_accounted_cr,0))                       AS sum_begin_bal_accounted_cr   -- ����ݕ�
          ,SUM(CASE
               WHEN gcc.account_type IN ('A','E') THEN
                 NVL(jgblc.begin_bal_accounted_dr,0) - NVL(jgblc.begin_bal_accounted_cr,0)
               ELSE
                 NVL(jgblc.begin_bal_accounted_cr,0) - NVL(jgblc.begin_bal_accounted_dr,0)
               END)                                                       AS remain_begin_bal_accounted   -- ����c
          ,SUM(NVL(jgblc.period_net_accounted_dr,0))                      AS sum_period_net_accounted_dr  -- �����ؕ�
          ,SUM(NVL(jgblc.period_net_accounted_cr,0))                      AS sum_period_net_accounted_cr  -- �����ݕ�
          ,SUM(CASE
               WHEN gcc.account_type IN ('A','E') THEN
                 NVL(jgblc.period_net_accounted_dr,0) - NVL(jgblc.period_net_accounted_cr,0)
               ELSE
                 NVL(jgblc.period_net_accounted_cr,0) - NVL(jgblc.period_net_accounted_dr,0)
               END)                                                       AS remain_period_net_accounted  -- �����c
          ,SUM(CASE
               WHEN gcc.account_type IN ('A','E') THEN
                 (NVL(jgblc.begin_bal_accounted_dr,0) - NVL(jgblc.begin_bal_accounted_cr,0)) + (NVL(jgblc.period_net_accounted_dr,0) - NVL(jgblc.period_net_accounted_cr,0))
               ELSE
                 (NVL(jgblc.begin_bal_accounted_cr,0) - NVL(jgblc.begin_bal_accounted_dr,0)) + (NVL(jgblc.period_net_accounted_cr,0) - NVL(jgblc.period_net_accounted_dr,0))
               END)                                                       AS remain_end_bal_accounted     -- �����c
        FROM   
           jg_zz_ar_balances        jgblc    -- JG�ڋq�c���e�[�u��
          ,hz_cust_accounts         hca      -- �ڋq�}�X�^
          ,hz_parties               hcp      -- �p�[�e�B���}�X�^
          ,gl_code_combinations     gcc      -- ����Ȗڑg�����}�X�^
        WHERE  1 = 1
        AND    jgblc.customer_id         = hca.cust_account_id(+)
        AND    hca.party_id              = hcp.party_id(+)
        AND    jgblc.set_of_books_id     = 2001
        AND    jgblc.currency_code       = 'JPY'
        -->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
        --  �����w��
        --����v����
        AND    jgblc.period_name         = iv_period_name
        --������Ȗ�
        AND    gcc.segment3              = '14500'--��������
        -->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
        AND    jgblc.code_combination_id = gcc.code_combination_id
        GROUP BY
         hca.account_number
        ,hcp.party_name
        ,jgblc.period_name
        ,gcc.segment3
        ,gcc.segment4
        ORDER BY
         hca.account_number
        ,gcc.segment3
        ;
    -- ���R�[�h�^
    jg_balance_rec jg_balance_cur%ROWTYPE;
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
        ,buff   => '"�ڋq�ԍ�","�ڋq��","��v����","����Ȗ�","����Ȗږ�","�⏕�Ȗ�","�⏕�Ȗږ�","����ؕ�","����ݕ�","����c","�����ؕ�","�����ݕ�","�����c","�����c"'
      );
      -- �f�[�^���o��(CSV)
      FOR jg_balance_rec IN jg_balance_cur
       LOOP
         --�����Z�b�g
         gn_target_cnt := gn_target_cnt + 1;
         --�ύX���鍀�ڋy�уL�[�����o��
         FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => '"'|| jg_balance_rec.account_number               || '","'
                         || jg_balance_rec.party_name                   || '","'
                         || jg_balance_rec.period_name                  || '","'
                         || jg_balance_rec.aff_account_code             || '","'
                         || jg_balance_rec.aff_account_name             || '","'
                         || jg_balance_rec.aff_sub_account_cooe         || '","'
                         || jg_balance_rec.aff_sub_account_name         || '","'
                         || jg_balance_rec.sum_begin_bal_accounted_dr   || '","'
                         || jg_balance_rec.sum_begin_bal_accounted_cr   || '","'
                         || jg_balance_rec.remain_begin_bal_accounted   || '","'
                         || jg_balance_rec.sum_period_net_accounted_dr  || '","'
                         || jg_balance_rec.sum_period_net_accounted_cr  || '","'
                         || jg_balance_rec.remain_period_net_accounted  || '","'
                         || jg_balance_rec.remain_end_bal_accounted     || '"'
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
END XXCCP009A11C;
/
