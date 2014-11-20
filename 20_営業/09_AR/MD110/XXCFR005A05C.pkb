CREATE OR REPLACE PACKAGE BODY XXCFR005A05C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR005A05C(body)
 * Description      : ���b�N�{�b�N�X��������
 * MD.050           : MD050_CFR_005_A05_���b�N�{�b�N�X��������
 * MD.070           : MD050_CFR_005_A05_���b�N�{�b�N�X��������
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   �������� (A-1)
 *  start_apply_api        ��������API�N������ (A-4)
 *  delete_rockbox_wk      ���b�N�{�b�N�X�����������[�N�e�[�u���폜 (A-5)
 *  submain                ���C�������v���V�[�W��
 *                           ���b�N�{�b�N�X�����������[�N�e�[�u���擾 (A-2)
 *                           �Ώێ���f�[�^�擾���� (A-3)
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                           �I������ (A-6)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2010/10/14    1.00 SCS �Γn ���a    ����쐬
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
  --*** ���b�N�G���[��O�n���h�� ***
  global_lock_err_expt          EXCEPTION;
  --
  PRAGMA EXCEPTION_INIT(global_lock_err_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name           CONSTANT VARCHAR2(100) := 'XXCFR005A05C';         -- �p�b�P�[�W��
  cv_msg_kbn_cfr        CONSTANT VARCHAR2(5)   := 'XXCFR';
--
  -- ���b�Z�[�W�ԍ�
  cv_msg_005a05_003     CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00003';      -- ���b�N�G���[
  cv_msg_005a05_004     CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00004';      -- �v���t�@�C���擾�G���[
  cv_msg_005a05_007     CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00007';      -- �f�[�^�폜�G���[(OTHERS)
  cv_msg_005a05_024     CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00024';      -- �Ώۃf�[�^�Ȃ����b�Z�[�W
  cv_msg_005a05_025     CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00025';      -- �x���������b�Z�[�W
  cv_msg_005a05_104     CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00036';      -- ��������API�G���[
  cv_msg_005a05_108     CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00108';      -- ���̓p�����[�^�u�p���������s�敪�v���ݒ�G���[
  cv_msg_005a05_109     CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00109';      -- �Ώۍ��f�[�^�Ȃ��G���[
  cv_msg_005a05_112     CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00112';      -- �����ΏۊO����
  cv_msg_005a05_125     CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00125';      -- ���̓p�����[�^�u�p���������s�敪�v���l�`�F�b�N�G���[
--
-- �g�[�N��
  cv_tkn_prof           CONSTANT VARCHAR2(15) := 'PROF_NAME';             -- �v���t�@�C����
  cv_tkn_table          CONSTANT VARCHAR2(15) := 'TABLE';                 -- �e�[�u����
  cv_tkn_receipt_number CONSTANT VARCHAR2(15) := 'RECEIPT_NUMBER';        -- �����ԍ�
  cv_tkn_account_number CONSTANT VARCHAR2(15) := 'ACCOUNT_CODE';          -- �ڋq�R�[�h
  cv_tkn_receipt_method CONSTANT VARCHAR2(15) := 'RECEIPT_MEATHOD';       -- �x�����@
  cv_tkn_receipt_date   CONSTANT VARCHAR2(15) := 'RECEIPT_DATE';          -- ������
  cv_tkn_amount         CONSTANT VARCHAR2(15) := 'AMOUNT';                -- ���z
  cv_tkn_trx_number     CONSTANT VARCHAR2(15) := 'TRX_NUMBER';            -- �������ԍ�
  cv_tkn_count          CONSTANT VARCHAR2(15) := 'COUNT';                 -- ����
--
--
  -- �e�[�u����
  cv_tkn_t_tab          CONSTANT VARCHAR2(30) := 'XXCFR_ROCKBOX_WK';      -- ���b�N�{�b�N�X�����������[�N�e�[�u��
--
--
  --�v���t�@�C��
  cv_limit_of_count     CONSTANT VARCHAR2(30) := 'XXCFR1_LIMIT_OF_COUNT'; -- XXCFR:�Ώی���臒l
--
  -- �t�@�C���o��
  cv_file_type_out      CONSTANT VARCHAR2(10) := 'OUTPUT';                -- ���b�Z�[�W�o��
  cv_file_type_log      CONSTANT VARCHAR2(10) := 'LOG';                   -- ���O�o��
--
  -- �����t�H�[�}�b�g
  cv_format_date_ymd    CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';           -- ���t�t�H�[�}�b�g�i�N�����j
--
  -- ���e�����l
  cv_one                CONSTANT VARCHAR2(10) := '1';                     -- �����v�ۃt���O(�v)
  cn_parallel_type_0    CONSTANT NUMBER       :=  0;                      -- �p���������s�敪�u0�v
  cv_y                  CONSTANT VARCHAR2(10) := 'Y';                     -- ������uY�v
  cv_n                  CONSTANT VARCHAR2(10) := 'N';                     -- ������uN�v
--
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_parallel_type      NUMBER;             -- �p���������s�敪(NUMBER�^)
  gn_limit_of_count     NUMBER;             -- �Ώی���臒l
  --
  gn_no_target_cnt      NUMBER;             -- �����ΏۊO����
  --
  gn_api_sucs_cnt       NUMBER;             -- ��������������
--
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_parallel_type       IN      VARCHAR2,         -- �p���������s�敪
    iv_lmt_of_cnt_flg      IN      VARCHAR2,         -- �Ώی���臒l�g�p�t���O
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
    -- *** ���[�J���E��O ***
    in_param_null_expt       EXCEPTION;  -- ���̓p�����[�^�u�p���������s�敪�v���ݒ��O
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
    -- �R���J�����g�p�����[�^�o��
    --==============================================================
--
    -- ���O�o��
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_log   -- ���O�o��
      ,iv_conc_param1  => iv_parallel_type   -- �R���J�����g�p�����[�^�P
      ,iv_conc_param2  => iv_lmt_of_cnt_flg  -- �R���J�����g�p�����[�^�Q
      ,ov_errbuf       => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ���b�Z�[�W�o��
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_out   -- OUT�t�@�C���o��
      ,iv_conc_param1  => iv_parallel_type   -- �R���J�����g�p�����[�^�P
      ,iv_conc_param2  => iv_lmt_of_cnt_flg  -- �R���J�����g�p�����[�^�Q
      ,ov_errbuf       => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- ���̓p�����[�^�`�F�b�N
    --==============================================================
    -- ���̓p�����[�^�u�p���������s�敪�v�����ݒ�̏ꍇ
    IF ( iv_parallel_type IS NULL ) THEN
      RAISE in_param_null_expt;
    ELSE
      -- ���̓p�����[�^�u�p���������s�敪�v���l�`�F�b�N
      BEGIN
        gn_parallel_type := TO_NUMBER( iv_parallel_type );
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfr       -- �A�v���P�[�V�����Z�k��
                                               ,iv_name         => cv_msg_005a05_125);  -- ���b�Z�[�W
          lv_errbuf := SQLERRM;
          RAISE global_api_expt;
      END;
    END IF;
    --
--
    --==============================================================
    -- �v���t�@�C���I�v�V�����l�̎擾
    --==============================================================
    -- �v���t�@�C���FXXCFR:�Ώی���臒l
    gn_limit_of_count := TO_NUMBER( FND_PROFILE.VALUE(cv_limit_of_count) );
    -- �擾�G���[��
    IF (gn_limit_of_count IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfr       -- �A�v���P�[�V�����Z�k��
                                           ,iv_name         => cv_msg_005a05_004    -- ���b�Z�[�W
                                           ,iv_token_name1  => cv_tkn_prof          -- �g�[�N���R�[�h
                                           ,iv_token_value1 => cv_limit_of_count);  -- �g�[�N���FXXCFR1_LIMIT_OF_COUNT
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
    -- *** ���̓p�����[�^�u�p���������s�敪�v���ݒ��O�n���h�� ***
    WHEN in_param_null_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfr      -- �A�v���P�[�V�����Z�k��
                                            ,iv_name         => cv_msg_005a05_108); -- ���b�Z�[�W
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
    --
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : start_apply_api
   * Description      : ��������API�N������ (A-4)
   ***********************************************************************************/
  PROCEDURE start_apply_api(
    in_cash_receipt_id       IN  NUMBER,   --   ����ID
    iv_receipt_number        IN  VARCHAR2, --   �����ԍ�
    id_receipt_date          IN  DATE,     --   ������
    in_amount                IN  NUMBER,   --   �����z
    iv_receipt_method        IN  VARCHAR2, --   �x�����@
    iv_account_number        IN  VARCHAR2, --   �ڋq�R�[�h
    in_customer_trx_id       IN  NUMBER,   --   ����w�b�_ID
    iv_trx_number            IN  VARCHAR2, --   ����ԍ�
    in_amount_due_remaining  IN  NUMBER,   --   ������c��
    ov_errbuf                OUT VARCHAR2, --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT VARCHAR2, --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT VARCHAR2) --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'start_apply_api'; -- �v���O������
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
    --
    PRAGMA AUTONOMOUS_TRANSACTION; -- �����^�g�����U�N�V���� 
    --
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_return_status   VARCHAR2(1);
    ln_msg_count       NUMBER;
    lv_msg_data        VARCHAR2(2000);
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
    -- ��������API�N��
    ar_receipt_api_pub.apply(
       p_api_version     =>  1.0
      ,p_init_msg_list   =>  FND_API.G_TRUE
      ,p_commit          =>  FND_API.G_FALSE
      ,x_return_status   =>  lv_return_status
      ,x_msg_count       =>  ln_msg_count
      ,x_msg_data        =>  lv_msg_data
      ,p_customer_trx_id =>  in_customer_trx_id        -- ����w�b�_ID
      ,p_cash_receipt_id =>  in_cash_receipt_id        -- ����ID
      ,p_amount_applied  =>  in_amount_due_remaining   -- �������z
      ,p_apply_date      =>  id_receipt_date           -- ������
      ,p_apply_gl_date   =>  id_receipt_date           -- GL�L����
      );
--
    IF    (lv_return_status  = 'S') THEN
      -- ����Ȃ�΃R�~�b�g
      COMMIT;
    ELSE
      --�G���[����
      --��������API�G���[���b�Z�[�W�o��
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cfr                                 -- 'XXCFR'
                     ,iv_name         => cv_msg_005a05_104                              -- ��������API
                     ,iv_token_name1  => cv_tkn_receipt_number                          -- �g�[�N��'RECEIPT_NUMBER'
                     ,iv_token_value1 => iv_receipt_number                              -- �����ԍ�
                     ,iv_token_name2  => cv_tkn_account_number                          -- �g�[�N��'ACCOUNT_NUMBER'
                     ,iv_token_value2 => iv_account_number                              -- �ڋq�R�[�h
                     ,iv_token_name3  => cv_tkn_receipt_method                          -- �g�[�N��'RECEIPT_MEATHOD'
                     ,iv_token_value3 => iv_receipt_method                              -- �x�����@
                     ,iv_token_name4  => cv_tkn_receipt_date                            -- �g�[�N��'RECEIPT_DATE'
                     ,iv_token_value4 => TO_CHAR(id_receipt_date, cv_format_date_ymd)   -- ������
                     ,iv_token_name5  => cv_tkn_amount                                  -- �g�[�N��'AMOUNT'
                     ,iv_token_value5 => in_amount                                      -- �����z
                     ,iv_token_name6  => cv_tkn_trx_number                              -- �g�[�N��'TRX_NUMBER'
                     ,iv_token_value6 => iv_trx_number );                               -- ����ԍ�
      --
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
--
      -- API�W���G���[���b�Z�[�W�o��
      IF (ln_msg_count = 1) THEN
        -- API�W���G���[���b�Z�[�W���P���̏ꍇ
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => '�E' || lv_msg_data
        );
--
      ELSE
        -- API�W���G���[���b�Z�[�W���������̏ꍇ
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => '�E' || SUBSTRB( FND_MSG_PUB.GET(FND_MSG_PUB.G_FIRST, FND_API.G_FALSE)
                                       ,1
                                       ,5000
                                     )
        );
        ln_msg_count := ln_msg_count - 1;
        
        <<while_loop>>
        WHILE ln_msg_count > 0 LOOP
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => '�E' || SUBSTRB( FND_MSG_PUB.GET(FND_MSG_PUB.G_NEXT, FND_API.G_FALSE)
                                         ,1
                                         ,5000
                                       )
          );
          
          ln_msg_count := ln_msg_count - 1;
          --
        END LOOP while_loop;
--
      END IF;
      -- �x���Ȃ�΃��[���o�b�N
      ROLLBACK;
      -- �x���Z�b�g
      ov_retcode := cv_status_warn;
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
  END start_apply_api;
--
  /**********************************************************************************
   * Procedure Name   : delete_rockbox_wk
   * Description      : ���b�N�{�b�N�X�����������[�N�e�[�u���폜 (A-5)
   ***********************************************************************************/
  PROCEDURE delete_rockbox_wk(
    in_parallel_type   IN      NUMBER,           -- �p���������s�敪
    iv_lmt_of_cnt_flg  IN      VARCHAR2,         -- �Ώی���臒l�g�p�t���O
    ov_errbuf          OUT     VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT     VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT     VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_rockbox_wk'; -- �v���O������
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
    -- ���b�N�{�b�N�X�����������[�N�e�[�u���̍폜
    BEGIN
      DELETE FROM xxcfr_rockbox_wk
      WHERE  ((   in_parallel_type    <> cn_parallel_type_0        -- ���̓p�����[�^�u�p���������s�敪�v�� 0�ȊO�̏ꍇ
              AND parallel_type    = in_parallel_type              -- ���̓p�����[�^�u�p���������s�敪�v����v
              -- �Ώی���臒l�g�p�t���O = 'Y'
              AND ((   iv_lmt_of_cnt_flg  = cv_y
                   AND apply_trx_count   <= gn_limit_of_count      -- �����Ώی��� ��= A-1�Ŏ擾�����Ώی���臒l
                   )
                  OR ( iv_lmt_of_cnt_flg  = cv_n )
                  )
              )
             OR
              (   in_parallel_type     = cn_parallel_type_0        -- ���̓p�����[�^�u�p���������s�敪�v�� 0�̏ꍇ
              ))
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfr     -- �A�v���P�[�V�����Z�k��
                                             ,iv_name         => cv_msg_005a05_007  -- ���b�Z�[�W
                                             ,iv_token_name1  => cv_tkn_table       -- �g�[�N���R�[�h
                                             ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_tkn_t_tab)
                                                                                    -- �g�[�N���F���b�N�{�b�N�X�����������[�N�e�[�u��
                                             );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END delete_rockbox_wk;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_parallel_type       IN      VARCHAR2,         -- �p���������s�敪
    iv_lmt_of_cnt_flg      IN      VARCHAR2,         -- �Ώی���臒l�g�p�t���O
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
    cv_account_class_rec CONSTANT VARCHAR2(10) := 'REC';      -- �A�J�E���g�N���X
--
    -- *** ���[�J���ϐ� ***
    lv_lmt_of_cnt_flg   VARCHAR2(1);                          -- �Ώی���臒l�g�p�t���O
    ln_total_cash_cnt   NUMBER;                               -- �S�����f�[�^����
    ln_cust_trx_cnt     NUMBER;                               -- �Ώێ���f�[�^����
    ln_cust_trx_err_cnt NUMBER;                               -- �������s������
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    --���b�N�{�b�N�X�����������[�N�e�[�u�����b�N�p�J�[�\��
    CURSOR get_lock_rockbox_wk_cur
    IS
    SELECT 'X'
    FROM   xxcfr_rockbox_wk xrw                                  -- ���b�N�{�b�N�X�����������[�N�e�[�u��
    WHERE  ((   gn_parallel_type    <> cn_parallel_type_0        -- ���̓p�����[�^�u�p���������s�敪�v�� 0�ȊO�̏ꍇ
            AND xrw.parallel_type    = gn_parallel_type          -- ���̓p�����[�^�u�p���������s�敪�v����v
            -- �Ώی���臒l�g�p�t���O = 'Y'
            AND ((   lv_lmt_of_cnt_flg    = cv_y
                 AND xrw.apply_trx_count <= gn_limit_of_count    -- �����Ώی��� ��= A-1�Ŏ擾�����Ώی���臒l
                 )
                OR ( lv_lmt_of_cnt_flg    = cv_n )
                )
            )
           OR
            (   gn_parallel_type     = cn_parallel_type_0        -- ���̓p�����[�^�u�p���������s�敪�v�� 0�̏ꍇ
            ))
    FOR UPDATE NOWAIT
    ;
--
    --���b�N�{�b�N�X�����������[�N�e�[�u���擾�J�[�\��
    CURSOR get_rockbox_wk_cur
    IS
      SELECT  xrw.cash_receipt_id     cash_receipt_id              -- ��������ID
             ,xrw.account_number      cash_acct_number             -- �ڋq�ԍ�
             ,xrw.cust_account_id     cash_cust_acct_id            -- ������ڋqID
             ,xrw.receipt_number      receipt_number               -- �����ԍ�
             ,xrw.receipt_date        receipt_date                 -- ������
             ,xrw.amount              receipt_amount               -- �����z
             ,xrw.receipt_method_name receipt_method_name          -- �x�����@��
      FROM    xxcfr_rockbox_wk        xrw                          -- ���b�N�{�b�N�X�����������[�N�e�[�u��
      WHERE  ((   gn_parallel_type     <> cn_parallel_type_0        -- ���̓p�����[�^�u�p���������s�敪�v�� 0�ȊO�̏ꍇ
              AND xrw.parallel_type     = gn_parallel_type          -- ���̓p�����[�^�u�p���������s�敪�v����v
              AND xrw.apply_flag        = cv_one                    -- �����v�ۃt���O�� '1'(�v)
              -- �Ώی���臒l�g�p�t���O = 'Y'
              AND ((   lv_lmt_of_cnt_flg    = cv_y
                   AND xrw.apply_trx_count <= gn_limit_of_count    -- �����Ώی��� ��= A-1�Ŏ擾�����Ώی���臒l
                   )
                  OR ( lv_lmt_of_cnt_flg    = cv_n )
                  )
              )
             OR
              (   gn_parallel_type      = cn_parallel_type_0        -- ���̓p�����[�^�u�p���������s�敪�v�� 0�̏ꍇ
              AND xrw.apply_flag        = cv_one ))                 -- �����v�ۃt���O�� '1'(�v)
    ;
--
    lt_rockbox_wk_rec   get_rockbox_wk_cur%ROWTYPE;
--
    --�Ώێ���f�[�^�擾�J�[�\��
    CURSOR ra_customer_trx_cur(
      in_pay_from_customer NUMBER) --������ڋqID
    IS
      SELECT 
            xrctmv.customer_trx_id       customer_trx_id           -- ����w�b�_ID
           ,xrctmv.trx_number            trx_number                -- ����ԍ�
           ,xrctmv.amount_due_remaining  amount_due_remaining      -- ������c��
      FROM  xxcfr_rock_cust_trx_mv   xrctmv                        -- �ڋq���}�e���A���C�Y�h�r���[
           ,xxcfr_cust_hierarchy_mv  xchmv                         -- �ڋq�K�w�}�e���A���C�Y�h�r���[
      WHERE xrctmv.bill_to_customer_id = xchmv.bill_account_id
        AND xchmv.cash_account_id      = in_pay_from_customer      -- ������ڋqID
      ORDER BY xrctmv.amount_due_remaining
    ;
--
    lt_ra_customer_trx_rec   ra_customer_trx_cur%ROWTYPE;
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
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt    := 0;
    gn_normal_cnt    := 0;
    gn_error_cnt     := 0;
    gn_warn_cnt      := 0;
    gn_no_target_cnt := 0;
    gn_api_sucs_cnt  := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
-- 
    -- =====================================================
    --  �������� (A-1)
    -- =====================================================
    init(
       iv_parallel_type   => iv_parallel_type       -- �p���������s�敪
      ,iv_lmt_of_cnt_flg  => iv_lmt_of_cnt_flg      -- �Ώی���臒l�g�p�t���O
      ,ov_errbuf          => lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode         => lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg          => lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      -- �G���[�����̃J�E���g
      gn_error_cnt := 1;
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
    --
    -- ���̓p�����[�^�u�Ώی���臒l�g�p�t���O�v�����ݒ�̏ꍇ
    lv_lmt_of_cnt_flg := NVL( iv_lmt_of_cnt_flg, cv_n ); -- N���Z�b�g
    --
--
    -- =====================================================
    --  ���b�N�{�b�N�X�����������[�N�e�[�u���擾 (A-2)
    -- =====================================================
    -- ���b�N�̎擾
    OPEN  get_lock_rockbox_wk_cur;
    CLOSE get_lock_rockbox_wk_cur;
    --
    -- ���b�N�{�b�N�X�����������[�N�e�[�u���̑ΏۑS�����f�[�^�����擾
    SELECT COUNT(1)
    INTO   ln_total_cash_cnt                               -- �S�����f�[�^����
    FROM   xxcfr_rockbox_wk xrw                            -- ���b�N�{�b�N�X�����������[�N�e�[�u��
    WHERE  ((   gn_parallel_type <> cn_parallel_type_0     -- ���̓p�����[�^�u�p���������s�敪�v�� 0�ȊO�̏ꍇ
            AND xrw.parallel_type = gn_parallel_type       -- �p���������s�敪����v
            AND xrw.apply_flag    = cv_one )               -- �����v�ۃt���O�� '1'(�v)
           OR
            (   gn_parallel_type  = cn_parallel_type_0     -- ���̓p�����[�^�u�p���������s�敪�v�� 0�̏ꍇ
            AND xrw.apply_flag    = cv_one ))              -- �����v�ۃt���O�� '1'(�v)
    ;
    --
    -- 臒l�ȉ��̃��b�N�{�b�N�X�����������[�N�e�[�u���f�[�^�擾
    BEGIN
      -- �J�[�\���I�[�v��
      OPEN get_rockbox_wk_cur;
--
      -- ���b�N�{�b�N�X���[�N�e�[�u���擾���[�v�J�n
      <<rockbox_wk_loop>>
      LOOP
        -- �f�[�^�̎擾
        FETCH get_rockbox_wk_cur INTO lt_rockbox_wk_rec;
        EXIT WHEN get_rockbox_wk_cur%NOTFOUND;
--
        -- =====================================================
        --  �Ώێ���f�[�^�擾���� (A-3)
        -- =====================================================
        -- �J�[�\���I�[�v��
        OPEN ra_customer_trx_cur( lt_rockbox_wk_rec.cash_cust_acct_id );   -- ������ڋqID
--
        -- �Ώێ���f�[�^���[�v������������
        ln_cust_trx_cnt     := 0;                                          -- �Ώێ���f�[�^����
        ln_cust_trx_err_cnt := 0;                                          -- �������s������
--
        -- �Ώێ���f�[�^���[�v�J�n
        <<ra_customer_trx_loop>>
        LOOP
          -- �f�[�^�̎擾
          FETCH ra_customer_trx_cur INTO lt_ra_customer_trx_rec;
          EXIT WHEN ra_customer_trx_cur%NOTFOUND;
--
          -- =====================================================
          --  ��������API�N������ (A-4)
          -- =====================================================
          start_apply_api(
             in_cash_receipt_id      => lt_rockbox_wk_rec.cash_receipt_id            -- ����ID
            ,iv_receipt_number       => lt_rockbox_wk_rec.receipt_number             -- �����ԍ�
            ,id_receipt_date         => lt_rockbox_wk_rec.receipt_date               -- ������
            ,in_amount               => lt_rockbox_wk_rec.receipt_amount             -- �����z
            ,iv_receipt_method       => lt_rockbox_wk_rec.receipt_method_name        -- �x�����@
            ,iv_account_number       => lt_rockbox_wk_rec.cash_acct_number           -- �ڋq�R�[�h
            ,in_customer_trx_id      => lt_ra_customer_trx_rec.customer_trx_id       -- ����w�b�_ID
            ,iv_trx_number           => lt_ra_customer_trx_rec.trx_number            -- ����ԍ�
            ,in_amount_due_remaining => lt_ra_customer_trx_rec.amount_due_remaining  -- ������c��
            ,ov_errbuf               => lv_errbuf                                    -- �G���[�E���b�Z�[�W           --# �Œ� #
            ,ov_retcode              => lv_retcode                                   -- ���^�[���E�R�[�h             --# �Œ� #
            ,ov_errmsg               => lv_errmsg);                                  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        
          -- ���폈���`�F�b�N
          IF ( lv_retcode <> cv_status_normal ) THEN
            ln_cust_trx_err_cnt := ln_cust_trx_err_cnt + 1;      -- �������s������
          ELSE
            gn_api_sucs_cnt      := gn_api_sucs_cnt    + 1;      -- ��������������
          END IF;
--
        -- �T�u���[�v�I��
        END LOOP ra_customer_trx_loop;
--
        -- ������ޔ�
        ln_cust_trx_cnt := ra_customer_trx_cur%ROWCOUNT;
        --
        -- �Ώێ���f�[�^���[�����̏ꍇ
        IF ( ln_cust_trx_cnt = 0 ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_cfr                                 -- 'XXCFR'
                         ,iv_name         => cv_msg_005a05_109                              -- ��������API
                         ,iv_token_name1  => cv_tkn_receipt_number                          -- �g�[�N��'RECEIPT_NUMBER'
                         ,iv_token_value1 => lt_rockbox_wk_rec.receipt_number               -- �����ԍ�
                         ,iv_token_name2  => cv_tkn_account_number                          -- �g�[�N��'ACCOUNT_NUMBER'
                         ,iv_token_value2 => lt_rockbox_wk_rec.cash_acct_number             -- �ڋq�R�[�h
                         ,iv_token_name3  => cv_tkn_receipt_method                          -- �g�[�N��'RECEIPT_MEATHOD'
                         ,iv_token_value3 => lt_rockbox_wk_rec.receipt_method_name          -- �x�����@
                         ,iv_token_name4  => cv_tkn_receipt_date                            -- �g�[�N��'RECEIPT_DATE'
                         ,iv_token_value4 => TO_CHAR(lt_rockbox_wk_rec.receipt_date
                                                   , cv_format_date_ymd)                    -- ������
                         ,iv_token_name5  => cv_tkn_amount                                  -- �g�[�N��'AMOUNT'
                         ,iv_token_value5 => lt_rockbox_wk_rec.receipt_amount );            -- �����z
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
        END IF;
        -- �J�[�\���N���[�Y
        CLOSE ra_customer_trx_cur;
        --
        -- ��������0���ȊO�̏ꍇ
        IF (  ( ln_cust_trx_err_cnt > 0 ) 
           OR ( ln_cust_trx_cnt     = 0 ) )
        THEN
          -- �x�������J�E���g
          gn_warn_cnt   := gn_warn_cnt + 1;
        ELSE
          -- ���팏���J�E���g
          gn_normal_cnt := gn_normal_cnt + 1;
        END IF;
--
      -- ���C�����[�v�I��
      END LOOP ar_cash_receipts_loop;
--
      -- �Ώی����J�E���g
      gn_target_cnt := get_rockbox_wk_cur%ROWCOUNT;
--
      -- �J�[�\���N���[�Y
      CLOSE get_rockbox_wk_cur;
    --
    -- OTHERS��O����
    EXCEPTION
      WHEN OTHERS THEN
        -- �J�[�\���̃N���[�Y
        IF( ra_customer_trx_cur%ISOPEN ) THEN
          CLOSE ra_customer_trx_cur;
        END IF;
        IF( get_rockbox_wk_cur%ISOPEN  ) THEN
          CLOSE get_rockbox_wk_cur;
        END IF;
        -- 
        lv_errmsg  := NULL;
        lv_errbuf  := SQLERRM;
        --
        RAISE global_process_expt;
    END;
    --
    -- �����ΏۊO�����̎Z�o
    gn_no_target_cnt :=  ln_total_cash_cnt - gn_target_cnt;
--
    -- =====================================================
    --  ���b�N�{�b�N�X�����������[�N�e�[�u���폜 (A-5)
    -- =====================================================
    delete_rockbox_wk (
       in_parallel_type  => gn_parallel_type       -- �p���������s�敪
      ,iv_lmt_of_cnt_flg => lv_lmt_of_cnt_flg      -- �Ώی���臒l�g�p�t���O
      ,ov_errbuf         => lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode        => lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg         => lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    -- ���폈���`�F�b�N
    IF (lv_retcode <> cv_status_normal) THEN
      -- �G���[�����̃J�E���g
      gn_error_cnt := 1;
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    --�Ώۃf�[�^�Ȃ����b�Z�[�W�̔���
    IF ( gn_target_cnt = 0 ) THEN
      --
      ov_errmsg := xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr          -- �A�v���P�[�V�����Z�k��
                                           ,cv_msg_005a05_024 );    -- ���b�Z�[�W
      ov_errbuf := ov_errmsg;
    END IF;
    --
    --���^�[���E�R�[�h�̐ݒ�
    IF (gn_warn_cnt > 0) THEN
      -- �x���Z�b�g
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
    -- *** ���b�N�G���[��O�n���h�� ****
    WHEN global_lock_err_expt THEN
      -- �J�[�\����OPEN���Ă���Ȃ�΃J�[�\����CLOSE
      IF( get_rockbox_wk_cur%ISOPEN ) THEN
        CLOSE get_rockbox_wk_cur;
      END IF;
      --
    --�擾���ʂ�NULL�Ȃ�΃G���[
      ov_errmsg := xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfr     -- �A�v���P�[�V�����Z�k���FXXCFR
                                            ,iv_name         => cv_msg_005a05_003  -- ���b�Z�[�W�FAPP-XXCFR1-00003
                                            ,iv_token_name1  => cv_tkn_table       -- �g�[�N���R�[�h
                                            ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_tkn_t_tab)
                                                                                   -- �g�[�N���F���b�N�{�b�N�X�����������[�N�e�[�u��
                                           );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
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
    errbuf                 OUT     VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode                OUT     VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_parallel_type       IN      VARCHAR2,      --   �p���������s�敪
    iv_lmt_of_cnt_flg      IN      VARCHAR2       --   �Ώی���臒l�g�p�t���O
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
    cv_error_part_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90007'; -- �G���[�I���ꕔ�������b�Z�[�W
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
       iv_parallel_type   => iv_parallel_type  -- �p���������s�敪
      ,iv_lmt_of_cnt_flg  => iv_lmt_of_cnt_flg -- �Ώی���臒l�g�p�t���O
      ,ov_errbuf          => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode         => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg          => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�E�x���o��
    IF ( ( lv_errmsg IS NOT NULL )
       OR( lv_errbuf IS NOT NULL ) ) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg                 --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf                 --�G���[���b�Z�[�W
      );
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    -- =====================================================
    --  �I������ (A-6)
    -- =====================================================
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name           -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_target_rec_msg            -- ���b�Z�[�W
                    ,iv_token_name1  => cv_cnt_token                 -- �g�[�N���R�[�h
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)       -- �g�[�N��
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�����ΏۊO�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cfr               -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_005a05_112            -- ���b�Z�[�W
                    ,iv_token_name1  => cv_cnt_token                 -- �g�[�N���R�[�h
                    ,iv_token_value1 => TO_CHAR(gn_no_target_cnt)    -- �g�[�N��
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name           -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_success_rec_msg           -- ���b�Z�[�W
                    ,iv_token_name1  => cv_cnt_token                 -- �g�[�N���R�[�h
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)       -- �g�[�N��
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�x�������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cfr               -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_005a05_025            -- ���b�Z�[�W
                    ,iv_token_name1  => cv_cnt_token                 -- �g�[�N���R�[�h
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)         -- �g�[�N��
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name           -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_error_rec_msg             -- ���b�Z�[�W
                    ,iv_token_name1  => cv_cnt_token                 -- �g�[�N���R�[�h
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)        -- �g�[�N��
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;                              -- ����I�����b�Z�[�W
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;                                -- �x���I�����b�Z�[�W
    ELSIF(lv_retcode = cv_status_error) THEN
      -- ����������������1���ȏ�
      IF ( gn_api_sucs_cnt > 0 ) THEN
        lv_message_code := cv_error_part_msg;                        -- �G���[�I���ꕔ�������b�Z�[�W
      ELSE
        lv_message_code := cv_error_msg;                             -- �G���[�I���S���[���o�b�N
      END IF;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name           -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => lv_message_code              -- ���b�Z�[�W
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
END XXCFR005A05C;
/