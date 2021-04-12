CREATE OR REPLACE PACKAGE BODY      XXCOK024A30C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A30C(body)
 * Description      : �T���}�X�^IF�o�́i���n�j
 * MD.050           : �T���}�X�^IF�o�́i���n�j MD050_COK_024_A30
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  proc_init            ��������(A-1)
 *
 *  submain              ���C�������v���V�[�W��
 *                          �Eproc_init
 *                       �T�����̎擾(A-2)
 *                       �T���}�X�^�i���n�j�o�͏���(A-3)
 *
 *  main                 �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                          �Esubmain
 *                       �I������(A-4)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2020/12/18    1.0   R.Oikawa        main�V�K�쐬
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal               CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal;  -- ����:0
  cv_status_warn                 CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;    -- �x��:1
  cv_status_error                CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;   -- �ُ�:2
  --WHO�J����
  cn_created_by                  CONSTANT NUMBER      := fnd_global.user_id;            -- CREATED_BY
  cd_creation_date               CONSTANT DATE        := SYSDATE;                       -- CREATION_DATE
  cn_last_updated_by             CONSTANT NUMBER      := fnd_global.user_id;            -- LAST_UPDATED_BY
  cd_last_update_date            CONSTANT DATE        := SYSDATE;                       -- LAST_UPDATE_DATE
  cn_last_update_login           CONSTANT NUMBER      := fnd_global.login_id;           -- LAST_UPDATE_LOGIN
  cn_request_id                  CONSTANT NUMBER      := fnd_global.conc_request_id;    -- REQUEST_ID
  cn_program_application_id      CONSTANT NUMBER      := fnd_global.prog_appl_id;       -- PROGRAM_APPLICATION_ID
  cn_program_id                  CONSTANT NUMBER      := fnd_global.conc_program_id;    -- PROGRAM_ID
  cd_program_update_date         CONSTANT DATE        := SYSDATE;                       -- PROGRAM_UPDATE_DATE
  cv_msg_part                    CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont                    CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg                     VARCHAR2(2000);
  gv_sep_msg                     VARCHAR2(2000);
  gv_exec_user                   VARCHAR2(100);
  gv_conc_name                   VARCHAR2(30);
  gv_conc_status                 VARCHAR2(30);
  gn_target_cnt                  NUMBER;                    -- �Ώی���
  gn_normal_cnt                  NUMBER;                    -- ���팏��
  gn_error_cnt                   NUMBER;                    -- �G���[����
  gn_warn_cnt                    NUMBER;                    -- �X�L�b�v����
--
--################################  �Œ蕔 END   ##################################
--
--##########################  �Œ苤�ʗ�O�錾�� START  ###########################
--
  --*** ���������ʗ�O ***
  global_process_expt            EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt                EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt         EXCEPTION;
  global_check_lock_expt         EXCEPTION;                 -- ���b�N�擾�G���[
  --
  PRAGMA EXCEPTION_INIT( global_check_lock_expt, -54);
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                    CONSTANT VARCHAR2(30)  := 'XXCOK024A30C';       -- �p�b�P�[�W��
--
  cv_appl_name_xxcok             CONSTANT VARCHAR2(5)   := 'XXCOK';              -- �A�v���P�[�V�����Z�k��
  -- ���b�Z�[�W
  cv_msg_xxcok_00001             CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-00001';   -- �Ώۃf�[�^�Ȃ�
  cv_msg_xxcok_00003             CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-00003';   -- �v���t�@�C���擾�G���[
--
  cv_msg_xxcok_00006             CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-00006';   -- CSV�t�@�C�����m�[�g
--
  cv_msg_xxcok_00009             CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-00009';   -- CSV�t�@�C�����݃G���[
  cv_msg_xxcok_10787             CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10787';   -- �t�@�C���I�[�v���G���[
  cv_msg_xxcok_10788             CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10788';   -- �t�@�C���������݃G���[
  cv_msg_xxcok_10789             CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10789';   -- �t�@�C���N���[�Y�G���[
  -- �g�[�N��
  cv_tkn_profile                 CONSTANT VARCHAR2(10)  := 'PROFILE';            -- �g�[�N���F�v���t�@�C����
  cv_tkn_sqlerrm                 CONSTANT VARCHAR2(10)  := 'SQLERRM';            -- �g�[�N���FSQL�G���[
  cv_tkn_file_name               CONSTANT VARCHAR2(10)  := 'FILE_NAME';          -- �g�[�N���FSQL�G���[
--                                                                                 -- YYYYMMDD
  cv_date_fmt_ymd                CONSTANT VARCHAR2(10)  := 'RRRRMMDD';           -- YYYYMMDD
  cv_date_fmt_dt_ymdhms          CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_date_fmt_dt_ymdhms;
                                                                                 -- YYYYMMDDHH24MISS
  --
  cv_csv_fl_name                 CONSTANT VARCHAR2(33)  := 'XXCOK1_DEDUCTION_MASTER_FILE_NAME';
                                                                                 -- XXCOK:�T���}�X�^�t�@�C����
  cv_csv_fl_dir                  CONSTANT VARCHAR2(33)  := 'XXCOK1_DEDUCTION_MASTER_DIRE_PATH';
                                                                                 -- XXCOK:�T���}�X�^�f�B���N�g���p�X
  cv_dqu                         CONSTANT VARCHAR2(1)   := '"';
  cv_sep                         CONSTANT VARCHAR2(1)   := ',';
--
  cv_company_code                CONSTANT VARCHAR2(3)   := '001';                -- ��ЃR�[�h
  cv_csv_mode                    CONSTANT VARCHAR2(1)   := 'w';                  -- csv�t�@�C���I�[�v�����̃��[�h
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_trans_date                  VARCHAR2(14);                                  -- �A�g���t
  gv_csv_file_dir                VARCHAR2(1000);                                -- �T���}�X�^�i���n�j�A�g�pCSV�t�@�C���o�͐�̎擾
  gv_file_name                   VARCHAR2(30);                                  -- �T���}�X�^�i���n�j�A�g�pCSV�t�@�C����
--
  /**********************************************************************************
   * Procedure Name   : proc_init
   * Description      : ���������v���V�[�W��(A-1)
   ***********************************************************************************/
  PROCEDURE proc_init(
    ov_errbuf      OUT    VARCHAR2         --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode     OUT    VARCHAR2         --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg      OUT    VARCHAR2         --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name               CONSTANT VARCHAR2(100) := 'proc_init';          -- �v���O������
--
    -- ===============================
    -- �Œ胍�[�J���ϐ�
    -- ===============================
    lv_errbuf                 VARCHAR2(5000);                                 -- �G���[�E���b�Z�[�W
    lv_retcode                VARCHAR2(1);                                    -- ���^�[���E�R�[�h
    lv_errmsg                 VARCHAR2(5000);                                 -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_step                   VARCHAR2(100);                                    -- �X�e�b�v
    lv_message_token          VARCHAR2(100);                                    -- �A�g���t
    lb_fexists                BOOLEAN;                                          -- �t�@�C�����ݔ��f
    ln_file_length            NUMBER;                                           -- �t�@�C���̕�����
    lbi_block_size            BINARY_INTEGER;                                   -- �u���b�N�T�C�Y
    lv_csv_file               VARCHAR2(1000);                                   -- csv�t�@�C����
    --
    -- *** ���[�U�[��`��O ***
    profile_expt              EXCEPTION;                                        -- �v���t�@�C���擾��O
    csv_file_exst_expt        EXCEPTION;                                        -- CSV�t�@�C�����݃G���[
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
    -- �A�g�����̎擾
    lv_step := 'A-1.1';
    lv_message_token := '�A�g�����̎擾';
    gv_trans_date    := TO_CHAR( SYSDATE, cv_date_fmt_dt_ymdhms );
    --
    -- �v���t�@�C���擾
    lv_step := 'A-1.2';
    lv_message_token := '�A�g�pCSV�t�@�C�����̎擾';
    -- �T���}�X�^�i���n�j�A�g�pCSV�t�@�C�����̎擾
    gv_file_name := FND_PROFILE.VALUE( cv_csv_fl_name );
    -- �擾�G���[��
    IF ( gv_file_name IS NULL ) THEN
      lv_message_token := cv_csv_fl_name;
      RAISE profile_expt;
    END IF;
    --
    lv_csv_file := xxccp_common_pkg.get_msg(                                    -- �A�b�v���[�h���̂̏o��
                    iv_application  => cv_appl_name_xxcok                       -- �A�v���P�[�V�����Z�k��
                   ,iv_name         => cv_msg_xxcok_00006                       -- ���b�Z�[�W�R�[�h
                   ,iv_token_name1  => cv_tkn_file_name                         -- �g�[�N���R�[�h1
                   ,iv_token_value1 => gv_file_name                             -- �g�[�N���l1
                  );
    -- �t�@�C�����o��
    xxcmm_004common_pkg.put_message(
      iv_message_buff => lv_csv_file
     ,ov_errbuf       => lv_errbuf
     ,ov_retcode      => lv_retcode
     ,ov_errmsg       => lv_errmsg
    );
    --
    lv_step := 'A-1.2';
    lv_message_token := '�A�g�pCSV�t�@�C���o�͐�̎擾';
    -- �T���}�X�^�i���n�j�A�g�pCSV�t�@�C���o�͐�̎擾
    gv_csv_file_dir := FND_PROFILE.VALUE( cv_csv_fl_dir );
    -- �擾�G���[��
    IF ( gv_csv_file_dir IS NULL ) THEN
      lv_message_token := cv_csv_fl_dir;
      RAISE profile_expt;
    END IF;
    --
    lv_step := 'A-1.3';
    lv_message_token := 'CSV�t�@�C�����݃`�F�b�N';
    --
    -- CSV�t�@�C�����݃`�F�b�N
    UTL_FILE.FGETATTR(
       location    => gv_csv_file_dir
      ,filename    => gv_file_name
      ,fexists     => lb_fexists
      ,file_length => ln_file_length
      ,block_size  => lbi_block_size
    );
    -- �t�@�C�����ݎ�
    IF ( lb_fexists = TRUE ) THEN
      RAISE csv_file_exst_expt;
    END IF;
    --
  EXCEPTION
    -- *** �C�ӂŗ�O�������L�q���� ****
    -- �J�[�\���̃N���[�Y�������ɋL�q����
    --*** �v���t�@�C���擾�G���[ ***
    WHEN profile_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcok            -- �A�v���P�[�V�����Z�k���FXXCMM �}�X�^
                     ,iv_name         => cv_msg_xxcok_00003            -- ���b�Z�[�W�FAPP-XXCOK1-00003 �v���t�@�C���擾�G���[
                     ,iv_token_name1  => cv_tkn_profile                -- �g�[�N���FPROFILE
                     ,iv_token_value1 => lv_message_token              -- �v���t�@�C����
                     );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg;
      ov_retcode := cv_status_error;
    --*** CSV�t�@�C�����݃G���[ ***
    WHEN csv_file_exst_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcok            -- �A�v���P�[�V�����Z�k���FXXCMM �}�X�^
                     ,iv_name         => cv_msg_xxcok_00009            -- ���b�Z�[�W�FAPP-XXCOK1-00009 CSV�t�@�C�����݃G���[
                     ,iv_token_name1  => cv_tkn_file_name              -- �g�[�N���FFILE_NAME
                     ,iv_token_value1 => gv_file_name                  -- �v���t�@�C����
                     );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg;
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf    := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      ov_retcode   := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf      OUT    VARCHAR2         --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode     OUT    VARCHAR2         --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg      OUT    VARCHAR2         --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name               CONSTANT VARCHAR2(100) := 'submain';            -- �v���O������
    -- ===============================
    -- �Œ胍�[�J���ϐ�
    -- ===============================
    lv_errbuf                 VARCHAR2(5000);                                 -- �G���[�E���b�Z�[�W
    lv_retcode                VARCHAR2(1);                                    -- ���^�[���E�R�[�h
    lv_errmsg                 VARCHAR2(5000);                                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_step                   VARCHAR2(100);                                  -- �X�e�b�v
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[���[�J���ϐ�
    -- ===============================
    lv_sqlerrm                VARCHAR2(5000);                                 -- SQLERRM�ޔ�
    lf_file_hand              UTL_FILE.FILE_TYPE;                             -- �t�@�C���E�n���h���̐錾
    lv_message_token          VARCHAR2(100);                                  -- �A�g���t
    lv_out_csv_line           VARCHAR2(1000);                                 -- �o�͍s
    --
    -- �T���}�X�^�i���n�j���J�[�\��
    --lv_step := 'A-2';
    CURSOR csv_condition_cur
    IS
      SELECT xch.condition_id                   condition_id,                 -- �T������ID
             xch.condition_no                   condition_no,                 -- �T���ԍ�
             xch.enabled_flag_h                 enabled_flag_h,               -- �L���t���O
             xch.corp_code                      corp_code,                    -- ��ƃR�[�h
             xch.deduction_chain_code           deduction_chain_code,         -- �T���p�`�F�[���R�[�h
             xch.customer_code                  customer_code,                -- �ڋq�R�[�h
-- 2021/04/02 MOD Start
             ffvv.attribute2 
                || flv2.attribute3 
                || xca.sale_base_code           base_code,                    -- ���_
-- 2021/04/02 MOD End
             xch.data_type                      data_type,                    -- �f�[�^���
             flv.meaning                        data_type_name,               -- �f�[�^��ޖ�
             xch.tax_code                       tax_code,                     -- �ŃR�[�h
             xch.tax_rate                       tax_rate,                     -- �ŗ�
             TO_CHAR( xch.start_date_active, cv_date_fmt_ymd )
                                                start_date_active,            -- �J�n��
             TO_CHAR( xch.end_date_active, cv_date_fmt_ymd )
                                                end_date_active,              -- �I����
-- 2021/03/03 ADD Start
             xch.content                        content ,                     -- ���e
-- 2021/03/03 ADD End
             xch.decision_no                    decision_no,                  -- ����No
             xch.agreement_no                   agreement_no,                 -- �_��ԍ�
             xch.header_recovery_flag           header_recovery_flag,         -- ���J�o���Ώۃt���O
             xcl.condition_line_id              condition_line_id,            -- �T���ڍ�ID
             xcl.detail_number                  detail_number,                -- ���הԍ�
             xcl.enabled_flag_l                 enabled_flag_l,               -- �L���t���O(����)
             xcl.target_category                target_category,              -- �Ώۋ敪
             xcl.product_class                  product_class,                -- ���i�敪
             xcl.item_code                      item_code,                    -- �i�ڃR�[�h
             xcl.uom_code                       uom_code,                     -- �P��
             xcl.line_recovery_flag             line_recovery_flag,           -- ���J�o���Ώۃt���O(����)
             xcl.shop_pay_1                     shop_pay_1,                   -- �X�[(��)
             xcl.material_rate_1                material_rate_1,              -- ����(��)
             xcl.condition_unit_price_en_2      condition_unit_price_en_2,    -- �����P���Q(�~)
             xcl.demand_en_3                    demand_en_3,                  -- ����(�~)
             xcl.shop_pay_en_3                  shop_pay_en_3,                -- �X�[(�~)
             xcl.compensation_en_3              compensation_en_3,            -- ��U(�~)
             xcl.wholesale_margin_en_3          wholesale_margin_en_3,        -- �≮�}�[�W��(�~)
             xcl.wholesale_margin_per_3         wholesale_margin_per_3,       -- �≮�}�[�W��(��)
             xcl.accrued_en_3                   accrued_en_3,                 -- �����v�R(�~)
             xcl.normal_shop_pay_en_4           normal_shop_pay_en_4,         -- �ʏ�X�[(�~)
             xcl.just_shop_pay_en_4             just_shop_pay_en_4,           -- ����X�[(�~)
             xcl.just_condition_en_4            just_condition_en_4,          -- �������(�~)
             xcl.wholesale_adj_margin_en_4      wholesale_adj_margin_en_4,    -- �≮�}�[�W���C��(�~)
             xcl.wholesale_adj_margin_per_4     wholesale_adj_margin_per_4,   -- �≮�}�[�W���C��(��)
             xcl.accrued_en_4                   accrued_en_4,                 -- �����v�S(�~)
             xcl.prediction_qty_5               prediction_qty_5,             -- �\�����ʂT(�{)
             xcl.ratio_per_5                    ratio_per_5,                  -- �䗦(��)
             xcl.amount_prorated_en_5           amount_prorated_en_5,         -- ���z��(�~)
             xcl.condition_unit_price_en_5      condition_unit_price_en_5,    -- �����P���T(�~)
             xcl.support_amount_sum_en_5        support_amount_sum_en_5,      -- ���^�����v(�~)
             xcl.prediction_qty_6               prediction_qty_6,             -- �\�����ʂU(�{)
             xcl.condition_unit_price_en_6      condition_unit_price_en_6,    -- �����P���U(�~)
             xcl.target_rate_6                  target_rate_6,                -- �Ώۗ�(��)
             xcl.deduction_unit_price_en_6      deduction_unit_price_en_6,    -- �T���P��(�~)
-- 2021/03/01 MOD Start
--             xcl.accounting_base                accounting_base,              -- �v�㋒�_
             xcl.accounting_customer_code       accounting_customer_code,     -- �v��ڋq
-- 2021/03/01 MOD End
             xcl.deduction_amount               deduction_amount,             -- �T���z(�{��)
             xcl.deduction_tax_amount           deduction_tax_amount,         -- �T���Ŋz
             xcl.dl_wholesale_margin_en         dl_wholesale_margin_en,       -- DL�p�≮�}�[�W��(�~)
             xcl.dl_wholesale_margin_per        dl_wholesale_margin_per,      -- DL�p�≮�}�[�W��(��)
             xcl.dl_wholesale_adj_margin_en     dl_wholesale_adj_margin_en,   -- DL�p�≮�}�[�W���C��(�~)
             xcl.dl_wholesale_adj_margin_per    dl_wholesale_adj_margin_per,  -- DL�p�≮�}�[�W���C��(��)
             fu1.user_name                      create_user_name,             -- �쐬��
             TO_CHAR( xcl.creation_date, cv_date_fmt_ymd )
                                                creation_date,                -- �쐬��
             fu2.user_name                      last_updated_user_name,       -- �ŏI�X�V��
             TO_CHAR( xcl.last_update_date, cv_date_fmt_ymd )
                                                last_update_date              -- �ŏI�X�V��
      FROM   xxcok_condition_header xch, -- �T�������e�[�u��
             xxcok_condition_lines  xcl, -- �T���ڍ׃e�[�u��
             fnd_user fu1,               -- ���[�U�[�}�X�^
             fnd_user fu2,               -- ���[�U�[�}�X�^
             fnd_lookup_values      flv, -- �f�[�^���
-- 2021/04/02 MOD Start
             fnd_lookup_values      flv2,-- �`�F�[���R�[�h
             fnd_flex_values_vl     ffvv, -- ���
             xxcmm_cust_accounts    xca  -- �ڋq
-- 2021/04/02 MOD End
      WHERE  xch.condition_id    = xcl.condition_id
      AND    xcl.created_by      = fu1.user_id(+)
      AND    xcl.last_updated_by = fu2.user_id(+)
      AND    flv.lookup_type(+)  = 'XXCOK1_DEDUCTION_DATA_TYPE'
      AND    flv.lookup_code(+)  = xch.data_type
      AND    flv.language(+)     = 'JA'
--      AND    flv.enabled_flag(+) = 'Y'
-- 2021/04/02 MOD Start
      AND    flv2.lookup_type(+)  = 'XXCMM_CHAIN_CODE'
      AND    flv2.lookup_code(+)  = xch.deduction_chain_code
      AND    flv2.language(+)     = 'JA'
      AND    ffvv.flex_value(+)   = xch.corp_code
      AND    ffvv.value_category(+) = 'XX03_BUSINESS_TYPE'
      AND    xca.customer_code(+) = xch.customer_code
-- 2021/04/02 MOD End
      ORDER BY xch.condition_id, xcl.condition_line_id
      ;
--
    TYPE csv_condition_ttype IS TABLE OF csv_condition_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    lt_csv_condition_tab       csv_condition_ttype;               -- �T������IF�o�̓f�[�^
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    subproc_expt              EXCEPTION;       -- �T�u�v���O�����G���[
    file_open_expt            EXCEPTION;       -- �t�@�C���I�[�v���G���[
    file_output_expt          EXCEPTION;       -- �t�@�C���������݃G���[
    file_close_expt           EXCEPTION;       -- �t�@�C���N���[�Y�G���[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
    --
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
    --
    -- ===============================================
    -- proc_init�̌Ăяo���i����������proc_init�ōs���j
    -- ===============================================
    proc_init(
       ov_errbuf      => lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode     => lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg      => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE subproc_expt;
    END IF;
    --
    -----------------------------------
    -- A-2.�T���������̎擾
    -----------------------------------
    lv_step := 'A-2';
--
    OPEN  csv_condition_cur;
    FETCH csv_condition_cur BULK COLLECT INTO lt_csv_condition_tab;
    CLOSE csv_condition_cur;
    -- ���������J�E���g
    gn_target_cnt := lt_csv_condition_tab.COUNT;
--
    -----------------------------------------------
    -- A-3.�T���}�X�^�i���n�j�o�͏���
    -----------------------------------------------
    lv_step := 'A-3.1a';
    IF ( gn_target_cnt = 0 ) THEN
      -- �Ώۃf�[�^�Ȃ�
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcok
                     ,iv_name         => cv_msg_xxcok_00001
                     );
      ov_retcode := cv_status_error;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errmsg;
    ELSE
      -- CSV�t�@�C���I�[�v��
      lv_step := 'A-1.5';
      BEGIN
        lf_file_hand := UTL_FILE.FOPEN(  location  => gv_csv_file_dir  -- �o�͐�
                                        ,filename  => gv_file_name     -- CSV�t�@�C����
                                        ,open_mode => cv_csv_mode      -- ���[�h
                                       );
      EXCEPTION
        WHEN OTHERS THEN
          lv_sqlerrm := SQLERRM;
          RAISE file_open_expt;
      END;
      -- �t�@�C���o��
      lv_step := 'A-3.1b';
      <<out_csv_loop>>
      FOR i IN 1..lt_csv_condition_tab.COUNT LOOP
        --
        lv_out_csv_line := '';
        -- ��ЃR�[�h
        lv_step := 'A-3.company_code';
        lv_out_csv_line := cv_dqu ||
                           cv_company_code ||
                           cv_dqu;
        -- �T������ID
        lv_step := 'A-3.condition_id';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_condition_tab( i ).condition_id;
        -- �T���ԍ�
        lv_step := 'A-3.condition_no';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_condition_tab( i ).condition_no ||
                           cv_dqu;
        -- �L���t���O
        lv_step := 'A-3.enabled_flag_h';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_condition_tab( i ).enabled_flag_h ||
                           cv_dqu;
        -- ��ƃR�[�h
        lv_step := 'A-3.corp_code';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_condition_tab( i ).corp_code ||
                           cv_dqu;
        -- �T���p�`�F�[���R�[�h
        lv_step := 'A-3.deduction_chain_code';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_condition_tab( i ).deduction_chain_code ||
                           cv_dqu;
        -- �ڋq�R�[�h
        lv_step := 'A-3.customer_code';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_condition_tab( i ).customer_code ||
                           cv_dqu;
-- 2021/04/02 MOD Start
        lv_step := 'A-3.base_code';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_condition_tab( i ).base_code ||
                           cv_dqu;
-- 2021/04/02 MOD End
        -- �f�[�^���
        lv_step := 'A-3.data_type_name';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_condition_tab( i ).data_type_name ||
                           cv_dqu;
        -- �ŃR�[�h
        lv_step := 'A-3.tax_code';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_condition_tab( i ).tax_code ||
                           cv_dqu;
        -- �ŗ�
        lv_step := 'A-3.tax_rate';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_condition_tab( i ).tax_rate;
        -- �J�n���yYYYYMMDD�z
        lv_step := 'A-3.start_date_active';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_condition_tab( i ).start_date_active;
        -- �I�����yYYYYMMDD�z
        lv_step := 'A-3.end_date_active';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_condition_tab( i ).end_date_active;
-- 2021/03/03 ADD Start
        -- ���e
        lv_step := 'A-3.content';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_condition_tab( i ).content ||
                           cv_dqu;
-- 2021/03/03 ADD End
        -- ����No
        lv_step := 'A-3.decision_no';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_condition_tab( i ).decision_no ||
                           cv_dqu;
        -- �_��ԍ�
        lv_step := 'A-3.agreement_no';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_condition_tab( i ).agreement_no ||
                           cv_dqu;
        -- ���J�o���Ώۃt���O
        lv_step := 'A-3.header_recovery_flag';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_condition_tab( i ).header_recovery_flag ||
                           cv_dqu;
        -- �T���ڍ�ID
        lv_step := 'A-3.condition_line_id';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).condition_line_id;
        -- ���הԍ�
        lv_step := 'A-3.detail_number';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).detail_number;
        -- �L���t���O(����)
        lv_step := 'A-3.enabled_flag_l';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_condition_tab( i ).enabled_flag_l ||
                           cv_dqu;
        -- �Ώۋ敪
        lv_step := 'A-3.target_category';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_condition_tab( i ).target_category ||
                           cv_dqu;
        -- ���i�敪
        lv_step := 'A-3.product_class';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_condition_tab( i ).product_class ||
                           cv_dqu;
        -- �i�ڃR�[�h
        lv_step := 'A-3.item_code';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_condition_tab( i ).item_code ||
                           cv_dqu;
        -- �P��
        lv_step := 'A-3.uom_code';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_condition_tab( i ).uom_code ||
                           cv_dqu;
        -- ���J�o���Ώۃt���O(����)
        lv_step := 'A-3.line_recovery_flag';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_condition_tab( i ).line_recovery_flag ||
                           cv_dqu;
        -- �X�[(��)
        lv_step := 'A-3.shop_pay_1';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).shop_pay_1;
        -- ����(��)
        lv_step := 'A-3.material_rate_1';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).material_rate_1;
        -- �����P���Q(�~)
        lv_step := 'A-3.condition_unit_price_en_2';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).condition_unit_price_en_2;
        -- ����(�~)
        lv_step := 'A-3.demand_en_3';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).demand_en_3;
        -- �X�[(�~)
        lv_step := 'A-3.shop_pay_en_3';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).shop_pay_en_3;
        -- ��U(�~)
        lv_step := 'A-3.compensation_en_3';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).compensation_en_3;
        -- �≮�}�[�W��(�~)
        lv_step := 'A-3.wholesale_margin_en_3';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).wholesale_margin_en_3;
        -- �≮�}�[�W��(��)
        lv_step := 'A-3.wholesale_margin_per_3';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).wholesale_margin_per_3;
        -- �����v�R(�~)
        lv_step := 'A-3.accrued_en_3';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).accrued_en_3;
        -- �ʏ�X�[(�~)
        lv_step := 'A-3.normal_shop_pay_en_4';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).normal_shop_pay_en_4;
        -- ����X�[(�~)
        lv_step := 'A-3.just_shop_pay_en_4';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).just_shop_pay_en_4;
        -- �������(�~)
        lv_step := 'A-3.just_condition_en_4';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).just_condition_en_4;
        -- �≮�}�[�W���C��(�~)
        lv_step := 'A-3.wholesale_adj_margin_en_4';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).wholesale_adj_margin_en_4;
        -- �≮�}�[�W���C��(��)
        lv_step := 'A-3.wholesale_adj_margin_per_4';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).wholesale_adj_margin_per_4;
        -- �����v�S(�~)
        lv_step := 'A-3.accrued_en_4';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).accrued_en_4;
        -- �\�����ʂT(�{)
        lv_step := 'A-3.prediction_qty_5';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).prediction_qty_5;
        -- �䗦(��)
        lv_step := 'A-3.ratio_per_5';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).ratio_per_5;
        -- ���z��(�~)
        lv_step := 'A-3.amount_prorated_en_5';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).amount_prorated_en_5;
        -- �����P���T(�~)
        lv_step := 'A-3.condition_unit_price_en_5';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).condition_unit_price_en_5;
        -- ���^�����v(�~)
        lv_step := 'A-3.support_amount_sum_en_5';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).support_amount_sum_en_5;
        -- �\�����ʂU(�{)
        lv_step := 'A-3.prediction_qty_6';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).prediction_qty_6;
        -- �����P���U(�~)
        lv_step := 'A-3.condition_unit_price_en_6';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).condition_unit_price_en_6;
        -- �Ώۗ�(��)
        lv_step := 'A-3.target_rate_6';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).target_rate_6;
        -- �T���P��(�~)
        lv_step := 'A-3.deduction_unit_price_en_6';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).deduction_unit_price_en_6;
        -- �v�㋒�_
-- 2021/03/01 MOD Start
--        lv_step := 'A-3.accounting_base';
        lv_step := 'A-3.accounting_customer_code';
-- 2021/03/01 MOD End
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
-- 2021/03/01 MOD Start
--                           lt_csv_condition_tab( i ).accounting_base ||
                           lt_csv_condition_tab( i ).accounting_customer_code ||
-- 2021/03/01 MOD End
                           cv_dqu;
        -- �T���z(�{��)
        lv_step := 'A-3.deduction_amount';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).deduction_amount;
        -- �T���Ŋz
        lv_step := 'A-3.deduction_tax_amount';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).deduction_tax_amount;
        -- DL�p�≮�}�[�W��(�~)
        lv_step := 'A-3.dl_wholesale_margin_en';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).dl_wholesale_margin_en;
        -- DL�p�≮�}�[�W��(��)
        lv_step := 'A-3.dl_wholesale_margin_per';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).dl_wholesale_margin_per;
        -- DL�p�≮�}�[�W���C��(�~)
        lv_step := 'A-3.dl_wholesale_adj_margin_en';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).dl_wholesale_adj_margin_en;
        -- DL�p�≮�}�[�W���C��(��)
        lv_step := 'A-3.dl_wholesale_adj_margin_per';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).dl_wholesale_adj_margin_per;
        -- �쐬��
        lv_step := 'A-3.create_user_name';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_condition_tab( i ).create_user_name ||
                           cv_dqu;
        --�쐬��
        lv_step := 'A-3.creation_date';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).creation_date;
        -- �ŏI�X�V��
        lv_step := 'A-3.last_updated_user_name';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_condition_tab( i ).last_updated_user_name ||
                           cv_dqu;
        --�ŏI�X�V��
        lv_step := 'A-3.last_update_date';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).last_update_date;
        -- �A�g�����yYYYYMMDDHH24MISS�z
        lv_step := 'A-3.gv_trans_date';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           gv_trans_date;
        --
        --=================
        -- CSV�t�@�C���o��
        --=================
        lv_step := 'A-3.1c';
        BEGIN
          UTL_FILE.PUT_LINE( lf_file_hand, lv_out_csv_line );
        EXCEPTION
          WHEN OTHERS THEN
            lv_sqlerrm := SQLERRM;
            RAISE file_output_expt;
        END;
        --
        -- ��������
        gn_normal_cnt := gn_normal_cnt + 1;
        --
      END LOOP out_csv_loop;
      --
      -----------------------------------------------
      -- A-4.�I������
      -----------------------------------------------
      -- �t�@�C���N���[�Y
      lv_step := 'A-4.1';
      --
      --�t�@�C���N���[�Y���s
      BEGIN
        UTL_FILE.FCLOSE( lf_file_hand );
      EXCEPTION
        WHEN OTHERS THEN
          lv_sqlerrm := SQLERRM;
          RAISE file_close_expt;
      END;
      --
    END IF;
    --
  EXCEPTION
    -- *** �C�ӂŗ�O�������L�q���� ****
    -- *** �T�u�v���O������O�n���h�� ****
    WHEN subproc_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_error;
    --*** �t�@�C���I�[�v���G���[ ***
    WHEN file_open_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcok             -- �A�v���P�[�V�����Z�k���FXXCMM �}�X�^
                     ,iv_name         => cv_msg_xxcok_10787             -- ���b�Z�[�W�FAPP-XXCOK1-10787 �t�@�C���I�[�v���G���[
                     ,iv_token_name1  => cv_tkn_sqlerrm                 -- �g�[�N���FSQLERRM
                     ,iv_token_value1 => lv_sqlerrm                     -- �l�FSQLERRM
                     );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg;
      ov_retcode := cv_status_error;
    --*** �t�@�C���������݃G���[ ***
    WHEN file_output_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcok             -- �A�v���P�[�V�����Z�k���FXXCMM �}�X�^
                     ,iv_name         => cv_msg_xxcok_10788             -- ���b�Z�[�W�FAPP-XXCOK1-10788 �t�@�C���I�[�v���G���[
                     ,iv_token_name1  => cv_tkn_sqlerrm                 -- �g�[�N���FSQLERRM
                     ,iv_token_value1 => lv_sqlerrm                     -- �l�FSQLERRM
                     );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg;
      ov_retcode := cv_status_error;
    --*** �t�@�C���N���[�Y�G���[ ***
    WHEN file_close_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcok             -- �A�v���P�[�V�����Z�k���FXXCMM �}�X�^
                     ,iv_name         => cv_msg_xxcok_10789             -- ���b�Z�[�W�FAPP-XXCOK1-10789 �t�@�C���N���[�Y�G���[
                     ,iv_token_name1  => cv_tkn_sqlerrm                 -- �g�[�N���FSQLERRM
                     ,iv_token_value1 => lv_sqlerrm                     -- �l�FSQLERRM
                     );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg;
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �G���[�����o��
      gn_error_cnt := gn_target_cnt;
      ov_errbuf    := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      ov_retcode   := cv_status_error;
--
--####################################  �Œ蕔 END   ###################s#######################
--
  END submain;
  --
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
  --
  PROCEDURE main(
    errbuf         OUT    VARCHAR2         --   �G���[���b�Z�[�W #�Œ�#
   ,retcode        OUT    VARCHAR2         --   �G���[�R�[�h     #�Œ�#
  )
  IS
  --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name               CONSTANT VARCHAR2(100) := 'main';               -- �v���O������
    cv_log                    CONSTANT VARCHAR2(100) := 'LOG';                -- ���O
    cv_output                 CONSTANT VARCHAR2(100) := 'OUTPUT';             -- �A�E�g�v�b�g
    cv_app_name_xxccp         CONSTANT VARCHAR2(100) := 'XXCCP';              -- �A�v���P�[�V�����Z�k��
    cv_target_cnt_msg         CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000';   -- �Ώی������b�Z�[�W
    cv_success_cnt_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001';   -- �����������b�Z�[�W
    cv_error_cnt_msg          CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002';   -- �G���[�������b�Z�[�W
    cv_normal_msg             CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004';   -- ����I�����b�Z�[�W
    cv_warn_msg               CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005';   -- �x���I�����b�Z�[�W
    cv_error_msg              CONSTANT VARCHAR2(100) := 'APP-XXCCP1-10008';   -- �G���[�I�����b�Z�[�W
    cv_token_name1            CONSTANT VARCHAR2(100) := 'COUNT';              -- ��������
    --
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf                 VARCHAR2(5000);                                 -- �G���[�E���b�Z�[�W
    lv_retcode                VARCHAR2(1);                                    -- ���^�[���E�R�[�h
    lv_errmsg                 VARCHAR2(5000);                                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_step                   VARCHAR2(10);                                   -- �X�e�b�v
    lv_message_code           VARCHAR2(100);                                  -- ���b�Z�[�W�R�[�h
    --
    --
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_log
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_output
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       ov_errbuf      => lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode     => lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg      => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    IF ( lv_retcode <> cv_status_normal ) THEN
      --�G���[�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�G���[���b�Z�[�W
      );
      --
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
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => cv_target_cnt_msg
                    ,iv_token_name1  => cv_token_name1
                    ,iv_token_value1 => TO_CHAR( gn_target_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => cv_success_cnt_msg
                    ,iv_token_name1  => cv_token_name1
                    ,iv_token_value1 => TO_CHAR( gn_normal_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => cv_error_cnt_msg
                    ,iv_token_name1  => cv_token_name1
                    ,iv_token_value1 => TO_CHAR( gn_error_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --�I�����b�Z�[�W
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF( lv_retcode = cv_status_error ) THEN
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
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
  --
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCOK024A30C;
/
