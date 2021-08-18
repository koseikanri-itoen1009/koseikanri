CREATE OR REPLACE PACKAGE BODY APPS.XXCOK024A14C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A14 (spec)
 * Description      : �T�������쐬API(AP�x��)
 * MD.050           : �T�������쐬API(AP�x��) MD050_COK_024_A14
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                      ��������(A-1)
 *  sales_dedu_get            �̔��T���f�[�^���o(A-2)
 *  insert_dedu_recon_head    �T�������w�b�_�[�쐬(A-3)
 *  insert_dedu_num_recon     �T��No�ʏ������쐬(A-4)
 *  insert_dedu_recon_line_ap �T���������׏��(AP�\��)�쐬(A-5)
 *  submain                   ���C�������v���V�[�W��
 *  main                      �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2020/11/11    1.0   Y.Nakajima       �V�K�쐬
 *  2021/08/12    1.1   K.Yoshikawa      E_�{�ғ�_17382(Q4148)
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; -- ����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   -- �x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  -- �ُ�:2
  --WHO�J����
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;                 -- CREATED_BY
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;                 -- LAST_UPDATED_BY
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;                -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id;         -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;            -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id;         -- PROGRAM_ID
  cd_creation_date          CONSTANT DATE        := SYSDATE;                            -- CREATION_DATE
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                            -- LAST_UPDATE_DATE
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                            -- PROGRAM_UPDATE_DATE
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gn_target_cnt    NUMBER        DEFAULT 0;      -- �Ώی���
  gn_normal_cnt    NUMBER        DEFAULT 0;      -- ���팏��
  gn_error_cnt     NUMBER        DEFAULT 0;      -- �ُ팏��
  gn_skip_cnt      NUMBER        DEFAULT 0;      -- �X�L�b�v����
-- 2021/08/12 Ver1.1 ADD Start
  gv_condition_no    VARCHAR2(1039);
  gv_condition_no_01 VARCHAR2(1039);
  gv_condition_no_02 VARCHAR2(1039);
  gv_condition_no_03 VARCHAR2(1039);
  gv_condition_no_04 VARCHAR2(1039);
  gv_condition_no_05 VARCHAR2(1039);
  gv_condition_no_06 VARCHAR2(1039);
  gv_condition_no_07 VARCHAR2(1039);
  gv_condition_no_08 VARCHAR2(1039);
  gv_condition_no_09 VARCHAR2(1039);
  gv_condition_no_10 VARCHAR2(1039);
  gv_condition_no_11 VARCHAR2(1039);
  gv_condition_no_12 VARCHAR2(1039);
  gv_condition_no_13 VARCHAR2(1039);
  gv_condition_no_14 VARCHAR2(1039);
  gv_condition_no_15 VARCHAR2(1039);
  gv_condition_no_16 VARCHAR2(1039);
  gv_condition_no_17 VARCHAR2(1039);
  gv_condition_no_18 VARCHAR2(1039);
  gv_condition_no_19 VARCHAR2(1039);
  gv_condition_no_20 VARCHAR2(1039);
  gv_condition_no_21 VARCHAR2(1039);
  gv_condition_no_22 VARCHAR2(1039);
  gv_condition_no_23 VARCHAR2(1039);
  gv_condition_no_24 VARCHAR2(1039);
  gv_condition_no_25 VARCHAR2(1039);
  gv_condition_no_26 VARCHAR2(1039);
  gv_condition_no_27 VARCHAR2(1039);
  gv_condition_no_28 VARCHAR2(1039);
  gv_condition_no_29 VARCHAR2(1039);
  gv_condition_no_30 VARCHAR2(1039);
  gv_condition_no_31 VARCHAR2(1039);
  gv_condition_no_32 VARCHAR2(1039);
  gv_condition_no_33 VARCHAR2(1039);
  gv_condition_no_34 VARCHAR2(1039);
  gv_condition_no_35 VARCHAR2(1039);
  gv_condition_no_36 VARCHAR2(1039);
  gv_condition_no_37 VARCHAR2(1039);
  gv_condition_no_38 VARCHAR2(1039);
  gv_condition_no_39 VARCHAR2(1039);
  gv_condition_no_40 VARCHAR2(1039);
  gv_condition_no_41 VARCHAR2(1039);
  gv_condition_no_42 VARCHAR2(1039);
  gv_condition_no_43 VARCHAR2(1039);
  gv_condition_no_44 VARCHAR2(1039);
  gv_condition_no_45 VARCHAR2(1039);
  gv_condition_no_46 VARCHAR2(1039);
  gv_condition_no_47 VARCHAR2(1039);
  gv_condition_no_48 VARCHAR2(1039);
  gv_condition_no_49 VARCHAR2(1039);
  gv_condition_no_50 VARCHAR2(1039);
  gv_condition_no_51 VARCHAR2(1039);
  gv_condition_no_52 VARCHAR2(1039);
  gv_condition_no_53 VARCHAR2(1039);
  gv_condition_no_54 VARCHAR2(1039);
  gv_condition_no_55 VARCHAR2(1039);
  gv_condition_no_56 VARCHAR2(1039);
  gv_condition_no_57 VARCHAR2(1039);
  gv_condition_no_58 VARCHAR2(1039);
  gv_condition_no_59 VARCHAR2(1039);
  gv_condition_no_60 VARCHAR2(1039);
  gv_condition_no_61 VARCHAR2(1039);
  gv_condition_no_62 VARCHAR2(1039);
  gv_condition_no_63 VARCHAR2(1039);
  gv_condition_no_64 VARCHAR2(1039);
  gv_condition_no_65 VARCHAR2(1039);
  gv_condition_no_66 VARCHAR2(1039);
  gv_condition_no_67 VARCHAR2(1039);
  gv_condition_no_68 VARCHAR2(1039);
  gv_condition_no_69 VARCHAR2(1039);
  gv_condition_no_70 VARCHAR2(1039);
  gv_condition_no_71 VARCHAR2(1039);
  gv_condition_no_72 VARCHAR2(1039);
  gv_condition_no_73 VARCHAR2(1039);
  gv_condition_no_74 VARCHAR2(1039);
  gv_condition_no_75 VARCHAR2(1039);
  gv_condition_no_76 VARCHAR2(1039);
  gv_condition_no_77 VARCHAR2(1039);
  gv_condition_no_78 VARCHAR2(1039);
  gv_condition_no_79 VARCHAR2(1039);
  gv_condition_no_80 VARCHAR2(1039);
-- 2021/08/12 Ver1.1 ADD End
--
--################################  �Œ蕔 END   ##################################
--
--##########################  �Œ苤�ʗ�O�錾�� START  ###########################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐��x����O ***
  global_api_warn_expt      EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
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
  -- �p�b�P�[�W��
  cv_pkg_name               CONSTANT VARCHAR2(20) := 'XXCOK024A14C';                -- �p�b�P�[�W��
  -- �A�v���P�[�V�����Z�k��
  cv_msg_kbn_cok            CONSTANT VARCHAR2(5)  := 'XXCOK';                       -- �A�h�I���F�ʊJ��
  -- ���b�Z�[�W����
  cv_data_get_msg           CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00001';            -- �Ώۃf�[�^�Ȃ��G���[���b�Z�[�W
  cv_rock_err_msg           CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10632';            -- ���b�N�G���[���b�Z�[�W
  -- ���l
  cn_zero                   CONSTANT NUMBER       := 0;                             -- 0
  cn_one                    CONSTANT NUMBER       := 1;                             -- 1
  -- �L���t���O
  cv_enable                 CONSTANT VARCHAR2(1)  := 'Y';
  -- ����R�[�h
  ct_lang                   CONSTANT fnd_lookup_values.language%TYPE := USERENV('LANG');
  -- �Q�ƃ^�C�v
  cv_chain_code             CONSTANT VARCHAR2(50) := 'XXCMM_CHAIN_CODE';            -- �T���p�`�F�[���R�[�h
  cv_deduction_data_type    CONSTANT VARCHAR2(50) := 'XXCOK1_DEDUCTION_DATA_TYPE';  -- �T���f�[�^���
  cv_target_data_type       CONSTANT VARCHAR2(50) := 'XXCOK1_TARGET_DATA_TYPE';     -- �Ώۃf�[�^���
  --
  cv_ap                     CONSTANT VARCHAR2(4)  :=  'AP';                         -- AP
  cv_one                    CONSTANT VARCHAR2(1)  :=  '1';                          -- '1'
  cv_status_n               CONSTANT VARCHAR2(1)  :=  'N';                          -- 'N' (�V�K)
  -- �T�������w�b�_�p
  cv_recon_status           CONSTANT VARCHAR2(2)  :=  'EG';                         -- 'EG'(�쐬��)
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : insert_dedu_recon_line_ap
   * Description      : �T���������׏��(AP�\��)�쐬(A-5)
   **********************************************************************************/
  PROCEDURE insert_dedu_recon_line_ap(
    iv_recon_slip_num               IN     VARCHAR2   -- �x���`�[�ԍ�
   ,ov_errbuf                       OUT    VARCHAR2   -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode                      OUT    VARCHAR2   -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg                       OUT    VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_dedu_recon_line_ap'; -- �v���O������
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
    ln_deduction_amt      NUMBER;
    ln_deduction_tax      NUMBER;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �T��No�ʏ������̒��o
    SELECT   SUM(xdnr.deduction_amt)
           , SUM(xdnr.deduction_tax)
    INTO     ln_deduction_amt           -- �T���z(�Ŕ�)
           , ln_deduction_tax           -- �T���z(�����)
    FROM   xxcok_deduction_num_recon    xdnr
    WHERE  xdnr.recon_slip_num = iv_recon_slip_num
    ;
--
    -- �T���������׏��(AP�\��)�̓o�^
    INSERT INTO xxcok_deduction_recon_line_ap(
      deduction_recon_line_id                     -- �T����������ID
    , recon_slip_num                              -- �x���`�[�ԍ�
    , deduction_line_num                          -- �������הԍ�
    , recon_line_status                           -- ���̓X�e�[�^�X
    , deduction_chain_code                        -- �T���p�`�F�[���R�[�h
    , prev_carryover_amt                          -- �O���J�z�z(�Ŕ�)
    , prev_carryover_tax                          -- �O���J�z�z(�����)
    , deduction_amt                               -- �T���z(�Ŕ�)
    , deduction_tax                               -- �T���z(�����)
    , payment_amt                                 -- �x���z(�Ŕ�)
    , payment_tax                                 -- �x���z(�����)
    , difference_amt                              -- �������z(�Ŕ�)
    , difference_tax                              -- �������z(�����)
    , next_carryover_amt                          -- �����J�z�z(�Ŕ�)
    , next_carryover_tax                          -- �����J�z�z(�����)
    , created_by                                  -- �쐬��
    , creation_date                               -- �쐬��
    , last_updated_by                             -- �ŏI�X�V��
    , last_update_date                            -- �ŏI�X�V��
    , last_update_login                           -- �ŏI�X�V���O�C��
    , request_id                                  -- �v��ID
    , program_application_id                      -- �R���J�����g�E�v���O������A�v���P�[�V����ID
    , program_id                                  -- �R���J�����g��v���O����ID
    , program_update_date                         -- �v���O�����X�V��
    )
    VALUES(
      xxcok_deduction_recon_line_s01.nextval      -- �T����������ID
    , iv_recon_slip_num                           -- �x���`�[�ԍ�
    , cn_one                                      -- �������הԍ�
    , cv_recon_status                             -- ���̓X�e�[�^�X
    , NULL                                        -- �T���p�`�F�[���R�[�h
    , cn_zero                                     -- �O���J�z�z(�Ŕ�)
    , cn_zero                                     -- �O���J�z�z(�����)
    , ln_deduction_amt                            -- �T���z(�Ŕ�)
    , ln_deduction_tax                            -- �T���z(�����)
    , cn_zero                                     -- �x���z(�Ŕ�)
    , cn_zero                                     -- �x���z(�����)
    , ln_deduction_amt                            -- �������z(�Ŕ�)
    , ln_deduction_tax                            -- �������z(�����)
    , cn_zero                                     -- �����J�z�z(�Ŕ�)
    , cn_zero                                     -- �����J�z�z(�����)
    , cn_created_by                               -- �쐬��
    , SYSDATE                                     -- �쐬��
    , cn_last_updated_by                          -- �ŏI�X�V��
    , SYSDATE                                     -- �ŏI�X�V��
    , cn_last_update_login                        -- �ŏI�X�V���O�C��
    , cn_request_id                               -- �v��ID
    , cn_program_application_id                   -- �R���J�����g�E�v���O������A�v���P�[�V����ID
    , cn_program_id                               -- �R���J�����g��v���O����ID
    , SYSDATE                                     -- �v���O�����X�V��
    )
    ;
--
--#################################  �Œ��O������ START   ###################################
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** �x���n���h�� ***
    WHEN global_api_warn_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
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
  END insert_dedu_recon_line_ap;
--
  /**********************************************************************************
   * Procedure Name   : insert_dedu_num_recon
   * Description      : �T��No�ʏ������쐬(A-4)
   **********************************************************************************/
  PROCEDURE insert_dedu_num_recon(
    iv_recon_slip_num               IN     VARCHAR2   -- �x���`�[�ԍ�
   ,ov_errbuf                       OUT    VARCHAR2   -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode                      OUT    VARCHAR2   -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg                       OUT    VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_dedu_num_recon'; -- �v���O������
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
    -- ���׃C���N�������g�p
    deduction_line_num_cnt        xxcok_deduction_num_recon.deduction_line_num%TYPE;       -- �T�����הԍ�
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �̔��T����񒊏o
    CURSOR sales_dedu_cur
    IS
      SELECT  xsd.data_type                   AS data_type              -- �f�[�^���
            , xsd.condition_no                AS condition_no           -- �T���ԍ�
            , xsd.tax_code                    AS tax_code               -- �ŃR�[�h
            , SUM(xsd.deduction_amount)       AS deduction_amount       -- �T���z
            , SUM(xsd.deduction_tax_amount)   AS deduction_tax_amount   -- �T������z
      FROM    xxcok_sales_deduction    xsd    -- �̔��T�����e�[�u��
      WHERE   xsd.recon_slip_num = iv_recon_slip_num
      GROUP BY   xsd.data_type
               , xsd.condition_no
               , xsd.tax_code
      ORDER BY   xsd.condition_no
               , xsd.tax_code
    ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
    deduction_line_num_cnt := 0;
--
--###########################  �Œ蕔 END   ############################
--
    -- �T��No�ʏ������̓o�^����
    <<dedu_num_recon_ins_loop>>
    FOR sales_dedu_inline_rec IN sales_dedu_cur LOOP
      -- �T�����הԍ����C���N�������g
      deduction_line_num_cnt := deduction_line_num_cnt + 1;
      -- �T��No�ʏ������̓o�^
      INSERT INTO xxcok_deduction_num_recon(
        deduction_num_recon_id                      -- �T��No�ʏ���ID
      , recon_slip_num                              -- �x���`�[�ԍ�
      , recon_line_num                              -- �������הԍ�
      , deduction_chain_code                        -- �T���p�`�F�[���R�[�h
      , deduction_line_num                          -- �T�����הԍ�
      , data_type                                   -- �f�[�^���
      , target_flag                                 -- �Ώۃt���O
      , condition_no                                -- �T���ԍ�
      , tax_code                                    -- ����ŃR�[�h
      , prev_carryover_amt                          -- �O���J�z�z(�Ŕ�)
      , prev_carryover_tax                          -- �O���J�z�z(�����)
      , deduction_amt                               -- �T���z(�Ŕ�)
      , deduction_tax                               -- �T���z(�����)
      , carryover_pay_off_flg                       -- �J�z�z�S�z���Z�t���O
      , payment_tax_code                            -- �x�����ŃR�[�h
      , payment_amt                                 -- �x���z(�Ŕ�)
      , payment_tax                                 -- �x���z(�����)
      , difference_amt                              -- �������z(�Ŕ�)
      , difference_tax                              -- �������z(�����)
      , next_carryover_amt                          -- �����J�z�z(�Ŕ�)
      , next_carryover_tax                          -- �����J�z�z(�����)
      , remarks                                     -- �E�v
      , created_by                                  -- �쐬��
      , creation_date                               -- �쐬��
      , last_updated_by                             -- �ŏI�X�V��
      , last_update_date                            -- �ŏI�X�V��
      , last_update_login                           -- �ŏI�X�V���O�C��
      , request_id                                  -- �v��ID
      , program_application_id                      -- �R���J�����g�E�v���O������A�v���P�[�V����ID
      , program_id                                  -- �R���J�����g��v���O����ID
      , program_update_date                         -- �v���O�����X�V��
      )
      VALUES(
        xxcok_deduction_num_recon_s01.nextval       -- �T��No�ʏ���ID
      , iv_recon_slip_num                           -- �x���`�[�ԍ�
      , cn_one                                      -- �������הԍ�
      , NULL                                        -- �T���p�`�F�[���R�[�h
      , deduction_line_num_cnt                      -- �T�����הԍ�
      , sales_dedu_inline_rec.data_type             -- �f�[�^���
      , cv_status_n                                 -- �Ώۃt���O
      , sales_dedu_inline_rec.condition_no          -- �T���ԍ�
      , sales_dedu_inline_rec.tax_code              -- ����ŃR�[�h
      , cn_zero                                     -- �O���J�z�z(�Ŕ�)
      , cn_zero                                     -- �O���J�z�z(�����)
      , sales_dedu_inline_rec.deduction_amount      -- �T���z(�Ŕ�)
      , sales_dedu_inline_rec.deduction_tax_amount  -- �T���z(�����)
      , cv_enable                                   -- �J�z�z�S�z���Z�t���O
      , sales_dedu_inline_rec.tax_code              -- �x�����ŃR�[�h
      , cn_zero                                     -- �x���z(�Ŕ�)
      , cn_zero                                     -- �x���z(�����)
      , sales_dedu_inline_rec.deduction_amount      -- �������z(�Ŕ�)
      , sales_dedu_inline_rec.deduction_tax_amount  -- �������z(�����)
      , cn_zero                                     -- �����J�z�z(�Ŕ�)
      , cn_zero                                     -- �����J�z�z(�����)
      , NULL                                        -- �E�v
      , cn_created_by                               -- �쐬��
      , SYSDATE                                     -- �쐬��
      , cn_last_updated_by                          -- �ŏI�X�V��
      , SYSDATE                                     -- �ŏI�X�V��
      , cn_last_update_login                        -- �ŏI�X�V���O�C��
      , cn_request_id                               -- �v��ID
      , cn_program_application_id                   -- �R���J�����g�E�v���O������A�v���P�[�V����ID
      , cn_program_id                               -- �R���J�����g��v���O����ID
      , SYSDATE                                     -- �v���O�����X�V��
      );
--
    END LOOP dedu_num_recon_ins_loop;
--
--#################################  �Œ��O������ START   ###################################
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** �x���n���h�� ***
    WHEN global_api_warn_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
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
  END insert_dedu_num_recon;
--
  /**********************************************************************************
   * Procedure Name   : insert_dedu_recon_head
   * Description      : �T�������w�b�_�[�쐬(A-3)
   **********************************************************************************/
  PROCEDURE insert_dedu_recon_head(
    iv_recon_base_code              IN     VARCHAR2          -- �x���������_
   ,id_recon_due_date               IN     DATE              -- �x���\���
   ,id_gl_date                      IN     DATE              -- GL�L����
   ,id_target_date_end              IN     DATE              -- �Ώۊ���(TO)
   ,id_invoice_date                 IN     DATE              -- ���������t
   ,iv_payee_code                   IN     VARCHAR2          -- �x����R�[�h
   ,iv_corp_code                    IN     VARCHAR2          -- ��ƃR�[�h
   ,iv_deduction_chain_code         IN     VARCHAR2          -- �T���p�`�F�[���R�[�h
   ,iv_cust_code                    IN     VARCHAR2          -- �ڋq�R�[�h
   ,iv_invoice_number               IN     VARCHAR2          -- ��̐������ԍ�
   ,iv_target_data_type             IN     VARCHAR2          -- �Ώۃf�[�^���
   ,iv_terms_name                   IN     VARCHAR2          -- �x������
   ,iv_recon_slip_num               IN     VARCHAR2          -- �x���`�[�ԍ�
   ,ov_errbuf                       OUT    VARCHAR2          -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode                      OUT    VARCHAR2          -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg                       OUT    VARCHAR2          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_dedu_recon_head'; -- �v���O������
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
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
  -- 
    INSERT INTO xxcok_deduction_recon_head(
      deduction_recon_head_id                     -- �T�������w�b�_�[ID
    , recon_base_code                             -- �x���������_
    , recon_slip_num                              -- �x���`�[�ԍ� 
    , recon_status                                -- �����X�^�[�^�X 
    , application_date                            -- �\����
    , approval_date                               -- ���F��
    , cancellation_date                           -- �����
    , recon_due_date                              -- �x���\���
    , gl_date                                     -- GL�L����
    , target_date_end                             -- �Ώۊ���(TO)
    , interface_div                               -- �A�g��
    , payee_code                                  -- �x����R�[�h
    , corp_code                                   -- ��ƃR�[�h
    , deduction_chain_code                        -- �T���p�`�F�[���R�[�h
    , cust_code                                   -- �ڋq�R�[�h
    , invoice_number                              -- �≮�������ԍ�
    , target_data_type                            -- �Ώۃf�[�^���
    , applicant                                   -- �\����
    , approver                                    -- ���F��
    , ap_ar_if_flag                               -- AP/AR�A�g�t���O
    , gl_if_flag                                  -- ����GL�A�g�t���O
    , terms_name                                  -- �x������
    , invoice_date                                -- ���������t
    , created_by                                  -- �쐬��
    , creation_date                               -- �쐬��
    , last_updated_by                             -- �ŏI�X�V��
    , last_update_date                            -- �ŏI�X�V��
    , last_update_login                           -- �ŏI�X�V���O�C��
    , request_id                                  -- �v��ID
    , program_application_id                      -- �R���J�����g�E�v���O������A�v���P�[�V����ID
    , program_id                                  -- �R���J�����g��v���O����ID
    , program_update_date                         -- �v���O�����X�V��
-- 2021/08/12 Ver1.1 ADD Start
    , condition_no                                -- �T���ԍ�
-- 2021/08/12 Ver1.1 ADD End
    )
    VALUES(
      xxcok_deduction_recon_head_s01.nextval      -- �T�������w�b�_�[ID
    , iv_recon_base_code                          -- �x���������_
    , iv_recon_slip_num                           -- �x���`�[�ԍ� 
    , cv_recon_status                             -- �����X�^�[�^�X 
    , NULL                                        -- �\����
    , NULL                                        -- ���F��
    , NULL                                        -- �����
    , id_recon_due_date                           -- �x���\���
    , id_gl_date                                  -- GL�L����
    , id_target_date_end                          -- �Ώۊ���(TO)
    , cv_ap                                       -- �A�g��
    , iv_payee_code                               -- �x����R�[�h
    , iv_corp_code                                -- ��ƃR�[�h
    , iv_deduction_chain_code                     -- �T���p�`�F�[���R�[�h
    , iv_cust_code                                -- �ڋq�R�[�h
    , iv_invoice_number                           -- �≮�������ԍ�
    , iv_target_data_type                         -- �Ώۃf�[�^���
    , xxcok_common_pkg.get_emp_code_f(cn_created_by)
                                                  -- �\����
    , NULL                                        -- ���F��
    , cv_status_n                                 -- AP/AR�A�g�t���O
    , cv_status_n                                 -- ����GL�A�g�t���O
    , iv_terms_name                               -- �x������
    , id_invoice_date                             -- ���������t
    , cn_created_by                               -- �쐬��
    , SYSDATE                                     -- �쐬��
    , cn_last_updated_by                          -- �ŏI�X�V��
    , SYSDATE                                     -- �ŏI�X�V��
    , cn_last_update_login                        -- �ŏI�X�V���O�C��
    , cn_request_id                               -- �v��ID
    , cn_program_application_id                   -- �R���J�����g�E�v���O������A�v���P�[�V����ID
    , cn_program_id                               -- �R���J�����g��v���O����ID
    , SYSDATE                                     -- �v���O�����X�V��
-- 2021/08/12 Ver1.1 ADD Start
    , gv_condition_no                             -- �T���ԍ�
-- 2021/08/12 Ver1.1 ADD End
    );
--
--#################################  �Œ��O������ START   ###################################
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** �x���n���h�� ***
    WHEN global_api_warn_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
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
  END insert_dedu_recon_head;
--
  /**********************************************************************************
   * Procedure Name   : sales_dedu_get
   * Description      : �̔��T���f�[�^���o(A-2)
   **********************************************************************************/
  PROCEDURE sales_dedu_get(
    id_target_date_end              IN     DATE       -- �Ώۊ���(TO)
   ,iv_corp_code                    IN     VARCHAR2   -- ��ƃR�[�h
   ,iv_deduction_chain_code         IN     VARCHAR2   -- �T���p�`�F�[���R�[�h
   ,iv_cust_code                    IN     VARCHAR2   -- �ڋq�R�[�h
   ,iv_target_data_type             IN     VARCHAR2   -- �Ώۃf�[�^���
   ,iv_recon_slip_num               IN     VARCHAR2   -- �x���`�[�ԍ�
   ,ov_errbuf                       OUT    VARCHAR2   -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode                      OUT    VARCHAR2   -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg                       OUT    VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'sales_dedu_get'; -- �v���O������
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
    result_count  NUMBER;
--
    -- *** ���[�J���J�[�\�� ***
    CURSOR l_recon_slip_num_up_cur
    IS
      WITH 
        target_data_type  AS
        ( SELECT  /*+ MATERIALIZED */
                  flvd.lookup_code  AS  lookup_code
          FROM    fnd_lookup_values flvd,                 -- �T���f�[�^���
                  fnd_lookup_values flvt                  -- �Ώۃf�[�^���
          WHERE   flvt.lookup_type  =     cv_target_data_type
          AND     flvt.description  =     iv_target_data_type
          AND     flvt.language     =     ct_lang
          AND     flvt.enabled_flag =     cv_enable
          AND     flvd.lookup_type  =     cv_deduction_data_type
          AND     flvd.lookup_code  LIKE  flvt.attribute1
          AND     flvd.language     =     ct_lang
          AND     flvd.enabled_flag =     cv_enable
          AND     flvd.attribute3   =     cv_ap                   )
      SELECT  xsd.sales_deduction_id
      FROM    xxcok_sales_deduction     xsd
      WHERE   xsd.sales_deduction_id    IN
              ( SELECT  /*+ INDEX(xsd xxcok_sales_deduction_n08) */
                        xsd.sales_deduction_id      AS  sales_deduction_id
                FROM    xxcok_sales_deduction       xsd
                WHERE   xsd.customer_code_to        IN
-- 2021/08/12 Ver1.1 MOD Start
                        ( SELECT  xca.customer_code
                          FROM    xxcmm_cust_accounts     xca
                          WHERE   xca.customer_code       =   iv_cust_code
                        UNION ALL
                          SELECT  xca.customer_code
                          FROM    xxcmm_cust_accounts     xca
                          WHERE   xca.intro_chain_code2   =   iv_deduction_chain_code
                        UNION ALL
                          SELECT  xca.customer_code
                          FROM    xxcmm_cust_accounts     xca,
                                  fnd_lookup_values       flv
                          WHERE   flv.lookup_type         =   cv_chain_code
                          AND     flv.language            =   ct_lang
                          AND     flv.enabled_flag        =   cv_enable
                          AND     flv.attribute1          =   iv_corp_code
                          AND     xca.intro_chain_code2   =   flv.lookup_code  )
--                        ( SELECT  xca.customer_code
--                          FROM    fnd_lookup_values       flv,
--                                  xxcmm_cust_accounts     xca
--                          WHERE ( xca.customer_code       =   iv_cust_code            or  iv_cust_code            IS  NULL )
--                          AND   ( xca.intro_chain_code2   =   iv_deduction_chain_code or  iv_deduction_chain_code IS  NULL )
--                          AND     flv.lookup_type(+)      =   cv_chain_code
--                          AND     flv.lookup_code(+)      =   xca.intro_chain_code2
--                          AND     flv.language(+)         =   ct_lang
--                          AND     flv.enabled_flag(+)     =   cv_enable
--                          AND   ( flv.attribute1          =   iv_corp_code            or  iv_corp_code            IS  NULL )  )
-- 2021/08/12 Ver1.1 MOD End
                AND     xsd.recon_slip_num          IS  NULL
                AND     xsd.record_date             <=  id_target_date_end
                AND     xsd.data_type               IN  ( SELECT tdt.lookup_code FROM target_data_type tdt )
                AND   ( xsd.report_decision_flag IS NULL OR xsd.report_decision_flag = cv_one )
                AND     xsd.status                  =   cv_status_n
-- 2021/08/12 Ver1.1 ADD Start
-- �ڋq�A�`�F�[���A��Ƃ̂����ꂩ���w��
                AND  iv_cust_code || iv_deduction_chain_code || iv_corp_code IS NOT NULL
-- 2021/08/12 Ver1.1 ADD End
                UNION ALL
                SELECT  /*+ INDEX(xsd xxcok_sales_deduction_n08) */
                        xsd.sales_deduction_id      AS  sales_deduction_id
                FROM    xxcok_sales_deduction       xsd
                WHERE   xsd.customer_code_to        IS  NULL
                AND     xsd.deduction_chain_code    IN
                        ( SELECT  flv.lookup_code
                          FROM    fnd_lookup_values   flv
                          WHERE   flv.lookup_type     =   cv_chain_code
                          AND     flv.language        =   ct_lang
                          AND     flv.enabled_flag    =   cv_enable
                          AND   ( flv.lookup_code     =   iv_deduction_chain_code     OR  flv.attribute1          =   iv_corp_code )  )
                AND     xsd.recon_slip_num          IS  NULL
                AND     xsd.record_date             <=  id_target_date_end
                AND     xsd.data_type               IN  ( SELECT tdt.lookup_code FROM target_data_type tdt )
                AND   ( xsd.report_decision_flag IS NULL OR xsd.report_decision_flag = cv_one )
                AND     xsd.status                  =   cv_status_n
                UNION ALL
                SELECT  /*+ INDEX(xsd xxcok_sales_deduction_n08) */
                        xsd.sales_deduction_id      AS  sales_deduction_id
                FROM    xxcok_sales_deduction       xsd
                WHERE   xsd.customer_code_to        IS  NULL
                AND     xsd.deduction_chain_code    IS  NULL
                AND     xsd.corp_code               =   iv_corp_code
                AND     xsd.recon_slip_num          IS  NULL
                AND     xsd.record_date             <=  id_target_date_end
                AND     xsd.data_type               IN  ( SELECT tdt.lookup_code FROM target_data_type tdt )
                AND   ( xsd.report_decision_flag IS NULL OR xsd.report_decision_flag = cv_one )
-- 2021/08/12 Ver1.1 ADD Start
--                AND     xsd.status                  =   cv_status_n                                           )
                AND     xsd.status                  =   cv_status_n                                           
-- �T���ԍ��̂ݎw�� �p�t�H�[�}���X���ソ�ߖ{SQL���ɍT���ԍ��̏���������
                UNION ALL
                SELECT  /*+ INDEX(xsd xxcok_sales_deduction_n06) */
                        xsd.sales_deduction_id      AS  sales_deduction_id
                FROM    xxcok_sales_deduction       xsd
                WHERE   iv_cust_code                IS  NULL
                AND     iv_deduction_chain_code     IS  NULL
                AND     iv_corp_code                IS  NULL
                AND     xsd.recon_slip_num          IS  NULL
                AND     xsd.record_date             <=  id_target_date_end
                AND     xsd.data_type               IN  ( SELECT tdt.lookup_code FROM target_data_type tdt )
                AND   ( xsd.report_decision_flag IS NULL OR xsd.report_decision_flag = cv_one )
                AND     xsd.status                  =   cv_status_n                                           
                      AND (   xsd.condition_no = gv_condition_no_01
                           OR xsd.condition_no = gv_condition_no_02
                           OR xsd.condition_no = gv_condition_no_03
                           OR xsd.condition_no = gv_condition_no_04
                           OR xsd.condition_no = gv_condition_no_05
                           OR xsd.condition_no = gv_condition_no_06
                           OR xsd.condition_no = gv_condition_no_07
                           OR xsd.condition_no = gv_condition_no_08
                           OR xsd.condition_no = gv_condition_no_09
                           OR xsd.condition_no = gv_condition_no_10
                           OR xsd.condition_no = gv_condition_no_11
                           OR xsd.condition_no = gv_condition_no_12
                           OR xsd.condition_no = gv_condition_no_13
                           OR xsd.condition_no = gv_condition_no_14
                           OR xsd.condition_no = gv_condition_no_15
                           OR xsd.condition_no = gv_condition_no_16
                           OR xsd.condition_no = gv_condition_no_17
                           OR xsd.condition_no = gv_condition_no_18
                           OR xsd.condition_no = gv_condition_no_19
                           OR xsd.condition_no = gv_condition_no_20
                           OR xsd.condition_no = gv_condition_no_21
                           OR xsd.condition_no = gv_condition_no_22
                           OR xsd.condition_no = gv_condition_no_23
                           OR xsd.condition_no = gv_condition_no_24
                           OR xsd.condition_no = gv_condition_no_25
                           OR xsd.condition_no = gv_condition_no_26
                           OR xsd.condition_no = gv_condition_no_27
                           OR xsd.condition_no = gv_condition_no_28
                           OR xsd.condition_no = gv_condition_no_29
                           OR xsd.condition_no = gv_condition_no_30
                           OR xsd.condition_no = gv_condition_no_31
                           OR xsd.condition_no = gv_condition_no_32
                           OR xsd.condition_no = gv_condition_no_33
                           OR xsd.condition_no = gv_condition_no_34
                           OR xsd.condition_no = gv_condition_no_35
                           OR xsd.condition_no = gv_condition_no_36
                           OR xsd.condition_no = gv_condition_no_37
                           OR xsd.condition_no = gv_condition_no_38
                           OR xsd.condition_no = gv_condition_no_39
                           OR xsd.condition_no = gv_condition_no_40
                           OR xsd.condition_no = gv_condition_no_41
                           OR xsd.condition_no = gv_condition_no_42
                           OR xsd.condition_no = gv_condition_no_43
                           OR xsd.condition_no = gv_condition_no_44
                           OR xsd.condition_no = gv_condition_no_45
                           OR xsd.condition_no = gv_condition_no_46
                           OR xsd.condition_no = gv_condition_no_47
                           OR xsd.condition_no = gv_condition_no_48
                           OR xsd.condition_no = gv_condition_no_49
                           OR xsd.condition_no = gv_condition_no_50
                           OR xsd.condition_no = gv_condition_no_51
                           OR xsd.condition_no = gv_condition_no_52
                           OR xsd.condition_no = gv_condition_no_53
                           OR xsd.condition_no = gv_condition_no_54
                           OR xsd.condition_no = gv_condition_no_55
                           OR xsd.condition_no = gv_condition_no_56
                           OR xsd.condition_no = gv_condition_no_57
                           OR xsd.condition_no = gv_condition_no_58
                           OR xsd.condition_no = gv_condition_no_59
                           OR xsd.condition_no = gv_condition_no_60
                           OR xsd.condition_no = gv_condition_no_61
                           OR xsd.condition_no = gv_condition_no_62
                           OR xsd.condition_no = gv_condition_no_63
                           OR xsd.condition_no = gv_condition_no_64
                           OR xsd.condition_no = gv_condition_no_65
                           OR xsd.condition_no = gv_condition_no_66
                           OR xsd.condition_no = gv_condition_no_67
                           OR xsd.condition_no = gv_condition_no_68
                           OR xsd.condition_no = gv_condition_no_69
                           OR xsd.condition_no = gv_condition_no_70
                           OR xsd.condition_no = gv_condition_no_71
                           OR xsd.condition_no = gv_condition_no_72
                           OR xsd.condition_no = gv_condition_no_73
                           OR xsd.condition_no = gv_condition_no_74
                           OR xsd.condition_no = gv_condition_no_75
                           OR xsd.condition_no = gv_condition_no_76
                           OR xsd.condition_no = gv_condition_no_77
                           OR xsd.condition_no = gv_condition_no_78
                           OR xsd.condition_no = gv_condition_no_79
                           OR xsd.condition_no = gv_condition_no_80
                           OR gv_condition_no is null))
-- 2021/08/12 Ver1.1 ADD End
-- 2021/08/12 Ver1.1 ADD Start
      AND (   xsd.condition_no = gv_condition_no_01
           OR xsd.condition_no = gv_condition_no_02
           OR xsd.condition_no = gv_condition_no_03
           OR xsd.condition_no = gv_condition_no_04
           OR xsd.condition_no = gv_condition_no_05
           OR xsd.condition_no = gv_condition_no_06
           OR xsd.condition_no = gv_condition_no_07
           OR xsd.condition_no = gv_condition_no_08
           OR xsd.condition_no = gv_condition_no_09
           OR xsd.condition_no = gv_condition_no_10
           OR xsd.condition_no = gv_condition_no_11
           OR xsd.condition_no = gv_condition_no_12
           OR xsd.condition_no = gv_condition_no_13
           OR xsd.condition_no = gv_condition_no_14
           OR xsd.condition_no = gv_condition_no_15
           OR xsd.condition_no = gv_condition_no_16
           OR xsd.condition_no = gv_condition_no_17
           OR xsd.condition_no = gv_condition_no_18
           OR xsd.condition_no = gv_condition_no_19
           OR xsd.condition_no = gv_condition_no_20
           OR xsd.condition_no = gv_condition_no_21
           OR xsd.condition_no = gv_condition_no_22
           OR xsd.condition_no = gv_condition_no_23
           OR xsd.condition_no = gv_condition_no_24
           OR xsd.condition_no = gv_condition_no_25
           OR xsd.condition_no = gv_condition_no_26
           OR xsd.condition_no = gv_condition_no_27
           OR xsd.condition_no = gv_condition_no_28
           OR xsd.condition_no = gv_condition_no_29
           OR xsd.condition_no = gv_condition_no_30
           OR xsd.condition_no = gv_condition_no_31
           OR xsd.condition_no = gv_condition_no_32
           OR xsd.condition_no = gv_condition_no_33
           OR xsd.condition_no = gv_condition_no_34
           OR xsd.condition_no = gv_condition_no_35
           OR xsd.condition_no = gv_condition_no_36
           OR xsd.condition_no = gv_condition_no_37
           OR xsd.condition_no = gv_condition_no_38
           OR xsd.condition_no = gv_condition_no_39
           OR xsd.condition_no = gv_condition_no_40
           OR xsd.condition_no = gv_condition_no_41
           OR xsd.condition_no = gv_condition_no_42
           OR xsd.condition_no = gv_condition_no_43
           OR xsd.condition_no = gv_condition_no_44
           OR xsd.condition_no = gv_condition_no_45
           OR xsd.condition_no = gv_condition_no_46
           OR xsd.condition_no = gv_condition_no_47
           OR xsd.condition_no = gv_condition_no_48
           OR xsd.condition_no = gv_condition_no_49
           OR xsd.condition_no = gv_condition_no_50
           OR xsd.condition_no = gv_condition_no_51
           OR xsd.condition_no = gv_condition_no_52
           OR xsd.condition_no = gv_condition_no_53
           OR xsd.condition_no = gv_condition_no_54
           OR xsd.condition_no = gv_condition_no_55
           OR xsd.condition_no = gv_condition_no_56
           OR xsd.condition_no = gv_condition_no_57
           OR xsd.condition_no = gv_condition_no_58
           OR xsd.condition_no = gv_condition_no_59
           OR xsd.condition_no = gv_condition_no_60
           OR xsd.condition_no = gv_condition_no_61
           OR xsd.condition_no = gv_condition_no_62
           OR xsd.condition_no = gv_condition_no_63
           OR xsd.condition_no = gv_condition_no_64
           OR xsd.condition_no = gv_condition_no_65
           OR xsd.condition_no = gv_condition_no_66
           OR xsd.condition_no = gv_condition_no_67
           OR xsd.condition_no = gv_condition_no_68
           OR xsd.condition_no = gv_condition_no_69
           OR xsd.condition_no = gv_condition_no_70
           OR xsd.condition_no = gv_condition_no_71
           OR xsd.condition_no = gv_condition_no_72
           OR xsd.condition_no = gv_condition_no_73
           OR xsd.condition_no = gv_condition_no_74
           OR xsd.condition_no = gv_condition_no_75
           OR xsd.condition_no = gv_condition_no_76
           OR xsd.condition_no = gv_condition_no_77
           OR xsd.condition_no = gv_condition_no_78
           OR xsd.condition_no = gv_condition_no_79
           OR xsd.condition_no = gv_condition_no_80
           OR gv_condition_no is null)
-- 2021/08/12 Ver1.1 ADD End
      FOR UPDATE  NOWAIT;
--
    recon_slip_num_up_rec          l_recon_slip_num_up_cur%ROWTYPE;
--
    -- *** ���[�J����O ***
    lock_expt       EXCEPTION;
    PRAGMA EXCEPTION_INIT(lock_expt, -54);                  -- ���b�N�G���[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode   := cv_status_normal;
    result_count := 0;
--
--###########################  �Œ蕔 END   ############################
--
    -- �̔��T�����X�V
    FOR recon_slip_num_up_rec IN l_recon_slip_num_up_cur LOOP
      UPDATE  xxcok_sales_deduction       xsd
      SET     xsd.recon_slip_num            = iv_recon_slip_num         , -- �x���`�[�ԍ�
              xsd.carry_payment_slip_num    = iv_recon_slip_num         , -- �J�z���x���`�[�ԍ�
              xsd.last_updated_by           = cn_last_updated_by        ,
              xsd.last_update_date          = SYSDATE                   ,
              xsd.last_update_login         = cn_last_update_login      ,
              xsd.request_id                = cn_request_id             ,
              xsd.program_application_id    = cn_program_application_id ,
              xsd.program_id                = cn_program_id             ,
              xsd.program_update_date       = SYSDATE
      WHERE  xsd.sales_deduction_id      = recon_slip_num_up_rec.sales_deduction_id
      ;
      -- ���s���ʌ������擾
      result_count := result_count + 1;
    --
    END LOOP;
    --
--
  -- �Ώی������O���̏ꍇ�I������
    IF result_count = 0 THEN
      lv_errbuf := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_msg_kbn_cok
                     ,iv_name         =>  cv_data_get_msg  -- �Ώۃf�[�^�Ȃ��G���[���b�Z�[�W
                   );
      RAISE global_api_warn_expt;
    END IF;
--
--#################################  �Œ��O������ START   ###################################
--
  EXCEPTION
    -- ���b�N�G���[
    WHEN lock_expt THEN
      -- �J�[�\���N���[�Y
      IF ( l_recon_slip_num_up_cur%ISOPEN ) THEN
        CLOSE l_recon_slip_num_up_cur;
      END IF;
      -- ���b�N�G���[���b�Z�[�W
      ov_errmsg := xxccp_common_pkg.get_msg( cv_msg_kbn_cok
                                            ,cv_rock_err_msg
                                             );
      ov_errbuf :=  cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- �J�[�\���N���[�Y
      IF ( l_recon_slip_num_up_cur%ISOPEN ) THEN
        CLOSE l_recon_slip_num_up_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** �x���n���h�� ***
    WHEN global_api_warn_expt THEN
      -- �J�[�\���N���[�Y
      IF ( l_recon_slip_num_up_cur%ISOPEN ) THEN
        CLOSE l_recon_slip_num_up_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\���N���[�Y
      IF ( l_recon_slip_num_up_cur%ISOPEN ) THEN
        CLOSE l_recon_slip_num_up_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���N���[�Y
      IF ( l_recon_slip_num_up_cur%ISOPEN ) THEN
        CLOSE l_recon_slip_num_up_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--####################################  �Œ蕔 END   ##########################################
--
  END sales_dedu_get;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ���������v���V�[�W��(A-1)
   **********************************************************************************/
  PROCEDURE init(
    ov_recon_slip_num     OUT  VARCHAR2   --   �x���`�[�ԍ�
   ,ov_errbuf             OUT  VARCHAR2   --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode            OUT  VARCHAR2   --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg             OUT  VARCHAR2   --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- �v���O������
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
      lv_recon_slip_num         VARCHAR2(20);    -- �x���`�[�ԍ�
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �x���`�[�ԍ��擾
    lv_recon_slip_num := xxcok_deduction_slip_num_s01.nextval;
    --
    ov_recon_slip_num := TO_CHAR(lv_recon_slip_num,'FM0000000000');
--
-- 2021/08/12 Ver1.1 ADD Start
   gv_condition_no_01 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' , 1) ,' ') ,' ');
   gv_condition_no_02 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' , 2) ,' ') ,' ');
   gv_condition_no_03 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' , 3) ,' ') ,' ');
   gv_condition_no_04 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' , 4) ,' ') ,' ');
   gv_condition_no_05 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' , 5) ,' ') ,' ');
   gv_condition_no_06 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' , 6) ,' ') ,' ');
   gv_condition_no_07 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' , 7) ,' ') ,' ');
   gv_condition_no_08 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' , 8) ,' ') ,' ');
   gv_condition_no_09 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' , 9) ,' ') ,' ');
   gv_condition_no_10 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,10) ,' ') ,' ');
   gv_condition_no_11 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,11) ,' ') ,' ');
   gv_condition_no_12 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,12) ,' ') ,' ');
   gv_condition_no_13 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,13) ,' ') ,' ');
   gv_condition_no_14 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,14) ,' ') ,' ');
   gv_condition_no_15 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,15) ,' ') ,' ');
   gv_condition_no_16 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,16) ,' ') ,' ');
   gv_condition_no_17 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,17) ,' ') ,' ');
   gv_condition_no_18 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,18) ,' ') ,' ');
   gv_condition_no_19 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,19) ,' ') ,' ');
   gv_condition_no_20 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,20) ,' ') ,' ');
   gv_condition_no_21 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,21) ,' ') ,' ');
   gv_condition_no_22 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,22) ,' ') ,' ');
   gv_condition_no_23 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,23) ,' ') ,' ');
   gv_condition_no_24 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,24) ,' ') ,' ');
   gv_condition_no_25 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,25) ,' ') ,' ');
   gv_condition_no_26 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,26) ,' ') ,' ');
   gv_condition_no_27 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,27) ,' ') ,' ');
   gv_condition_no_28 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,28) ,' ') ,' ');
   gv_condition_no_29 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,29) ,' ') ,' ');
   gv_condition_no_30 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,30) ,' ') ,' ');
   gv_condition_no_31 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,31) ,' ') ,' ');
   gv_condition_no_32 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,32) ,' ') ,' ');
   gv_condition_no_33 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,33) ,' ') ,' ');
   gv_condition_no_34 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,34) ,' ') ,' ');
   gv_condition_no_35 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,35) ,' ') ,' ');
   gv_condition_no_36 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,36) ,' ') ,' ');
   gv_condition_no_37 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,37) ,' ') ,' ');
   gv_condition_no_38 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,38) ,' ') ,' ');
   gv_condition_no_39 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,39) ,' ') ,' ');
   gv_condition_no_40 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,40) ,' ') ,' ');
   gv_condition_no_41 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,41) ,' ') ,' ');
   gv_condition_no_42 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,42) ,' ') ,' ');
   gv_condition_no_43 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,43) ,' ') ,' ');
   gv_condition_no_44 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,44) ,' ') ,' ');
   gv_condition_no_45 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,45) ,' ') ,' ');
   gv_condition_no_46 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,46) ,' ') ,' ');
   gv_condition_no_47 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,47) ,' ') ,' ');
   gv_condition_no_48 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,48) ,' ') ,' ');
   gv_condition_no_49 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,49) ,' ') ,' ');
   gv_condition_no_50 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,50) ,' ') ,' ');
   gv_condition_no_51 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,51) ,' ') ,' ');
   gv_condition_no_52 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,52) ,' ') ,' ');
   gv_condition_no_53 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,53) ,' ') ,' ');
   gv_condition_no_54 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,54) ,' ') ,' ');
   gv_condition_no_55 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,55) ,' ') ,' ');
   gv_condition_no_56 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,56) ,' ') ,' ');
   gv_condition_no_57 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,57) ,' ') ,' ');
   gv_condition_no_58 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,58) ,' ') ,' ');
   gv_condition_no_59 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,59) ,' ') ,' ');
   gv_condition_no_60 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,60) ,' ') ,' ');
   gv_condition_no_61 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,61) ,' ') ,' ');
   gv_condition_no_62 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,62) ,' ') ,' ');
   gv_condition_no_63 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,63) ,' ') ,' ');
   gv_condition_no_64 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,64) ,' ') ,' ');
   gv_condition_no_65 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,65) ,' ') ,' ');
   gv_condition_no_66 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,66) ,' ') ,' ');
   gv_condition_no_67 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,67) ,' ') ,' ');
   gv_condition_no_68 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,68) ,' ') ,' ');
   gv_condition_no_69 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,69) ,' ') ,' ');
   gv_condition_no_70 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,70) ,' ') ,' ');
   gv_condition_no_71 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,71) ,' ') ,' ');
   gv_condition_no_72 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,72) ,' ') ,' ');
   gv_condition_no_73 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,73) ,' ') ,' ');
   gv_condition_no_74 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,74) ,' ') ,' ');
   gv_condition_no_75 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,75) ,' ') ,' ');
   gv_condition_no_76 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,76) ,' ') ,' ');
   gv_condition_no_77 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,77) ,' ') ,' ');
   gv_condition_no_78 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,78) ,' ') ,' ');
   gv_condition_no_79 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,79) ,' ') ,' ');
   gv_condition_no_80 := LTRIM(RTRIM(xxccp_common_pkg.char_delim_partition(gv_condition_no, ',' ,80) ,' ') ,' ');
-- 2021/08/12 Ver1.1 ADD END
--
--#################################  �Œ��O������ START   ###################################
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** �x���n���h�� ***
    WHEN global_api_warn_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_recon_base_code              IN     VARCHAR2          -- �x���������_
   ,id_recon_due_date               IN     DATE              -- �x���\���
   ,id_gl_date                      IN     DATE              -- GL�L����
   ,id_target_date_end              IN     DATE              -- �Ώۊ���(TO)
   ,id_invoice_date                 IN     DATE              -- ���������t
   ,iv_payee_code                   IN     VARCHAR2          -- �x����R�[�h
   ,iv_corp_code                    IN     VARCHAR2          -- ��ƃR�[�h
   ,iv_deduction_chain_code         IN     VARCHAR2          -- �T���p�`�F�[���R�[�h
   ,iv_cust_code                    IN     VARCHAR2          -- �ڋq�R�[�h
   ,iv_invoice_number               IN     VARCHAR2          -- ��̐������ԍ�
   ,iv_terms_name                   IN     VARCHAR2          -- �x������
   ,iv_target_data_type             IN     VARCHAR2          -- �Ώۃf�[�^���
-- 2021/08/12 Ver1.1 ADD Start
   ,iv_condition_no                 IN     VARCHAR2          -- �T���ԍ�(�J���}��؂�ő�50��)
-- 2021/08/12 Ver1.1 ADD End
   ,ov_recon_slip_num               OUT    VARCHAR2          -- �x���`�[�ԍ�
   ,ov_errbuf                       OUT    VARCHAR2          -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode                      OUT    VARCHAR2          -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg                       OUT    VARCHAR2          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
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
    lv_recon_slip_num  VARCHAR2(20); -- �x���`�[�ԍ�
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
    gn_target_cnt        := 0; -- �Ώی���
    gn_normal_cnt        := 0; -- ���팏��
    gn_error_cnt         := 0; -- �G���[����
--
    -- ============================================
    -- A-1�D��������
    -- ============================================
-- 2021/08/12 Ver1.1 ADD Start
    gv_condition_no := iv_condition_no;
-- 2021/08/12 Ver1.1 ADD End
    init(
       lv_recon_slip_num -- �x���`�[�ԍ�ID
      ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    ov_recon_slip_num := lv_recon_slip_num;
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-2�D�̔��T���f�[�^���o
    -- ============================================
    sales_dedu_get(
       id_target_date_end     -- �Ώۊ���(TO)
      ,iv_corp_code           -- ��ƃR�[�h
      ,iv_deduction_chain_code-- �T���p�`�F�[���R�[�h
      ,iv_cust_code           -- �ڋq�R�[�h
      ,iv_target_data_type    -- �Ώۃf�[�^���
      ,lv_recon_slip_num      -- �x���`�[�ԍ�
      ,lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-3�D �T�������w�b�_�[�쐬
    -- ============================================
    insert_dedu_recon_head(
       iv_recon_base_code     -- �x���������_
      ,id_recon_due_date      -- �x���\���
      ,id_gl_date             -- GL�L����
      ,id_target_date_end     -- �Ώۊ���(TO)
      ,id_invoice_date        -- ���������t
      ,iv_payee_code          -- �x����R�[�h
      ,iv_corp_code           -- ��ƃR�[�h
      ,iv_deduction_chain_code-- �T���p�`�F�[���R�[�h
      ,iv_cust_code           -- �ڋq�R�[�h
      ,iv_invoice_number      -- ��̐������ԍ�
      ,iv_target_data_type    -- �Ώۃf�[�^���
      ,iv_terms_name          -- �x������
      ,lv_recon_slip_num      -- �x���`�[�ԍ�
      ,lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-4�D�T��No�ʏ������쐬
    -- ============================================
    insert_dedu_num_recon(
       lv_recon_slip_num   -- �x���`�[�ԍ�
      ,lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-5�D�T���������׏��(AP�\��)�쐬
    -- ============================================
    insert_dedu_recon_line_ap(
       lv_recon_slip_num   -- �x���`�[�ԍ�
      ,lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
--#################################  �Œ��O������ START   ###################################
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** �x���n���h�� ***
    WHEN global_api_warn_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
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
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                          OUT    VARCHAR2          -- �G���[���b�Z�[�W #�Œ�#
   ,retcode                         OUT    VARCHAR2          -- �G���[�R�[�h     #�Œ�#
   ,ov_recon_slip_num               OUT    VARCHAR2          -- �x���`�[�ԍ�
   ,iv_recon_base_code              IN     VARCHAR2          -- �x���������_
   ,id_recon_due_date               IN     DATE              -- �x���\���
   ,id_gl_date                      IN     DATE              -- GL�L����
   ,id_target_date_end              IN     DATE              -- �Ώۊ���(TO)
   ,id_invoice_date                 IN     DATE              -- ���������t
   ,iv_payee_code                   IN     VARCHAR2          -- �x����R�[�h
   ,iv_corp_code                    IN     VARCHAR2          -- ��ƃR�[�h
   ,iv_deduction_chain_code         IN     VARCHAR2          -- �T���p�`�F�[���R�[�h
   ,iv_cust_code                    IN     VARCHAR2          -- �ڋq�R�[�h
   ,iv_invoice_number               IN     VARCHAR2          -- ��̐������ԍ�
   ,iv_terms_name                   IN     VARCHAR2          -- �x������
   ,iv_target_data_type             IN     VARCHAR2          -- �Ώۃf�[�^���
-- 2021/08/12 Ver1.1 ADD Start
   ,iv_condition_no                 IN     VARCHAR2          -- �T���ԍ�(�J���}��؂�ő�50��)
-- 2021/08/12 Ver1.1 ADD End
  )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100)  :=  'main';             -- �v���O������
--
    cv_appl_short_name  CONSTANT VARCHAR2(10)   :=  'XXCCP';            -- �A�h�I���F���ʁEIF�̈�
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code    VARCHAR2(100);   -- �I�����b�Z�[�W�R�[�h
    lv_recon_slip_num  VARCHAR2(20);    -- �x���`�[�ԍ�
    --
--
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       iv_recon_base_code        -- �x���������_
      ,id_recon_due_date         -- �x���\���
      ,id_gl_date                -- GL�L����
      ,id_target_date_end        -- �Ώۊ���(TO)
      ,id_invoice_date           -- ���������t
      ,iv_payee_code             -- �x����R�[�h
      ,iv_corp_code              -- ��ƃR�[�h
      ,iv_deduction_chain_code   -- �T���p�`�F�[���R�[�h
      ,iv_cust_code              -- �ڋq�R�[�h
      ,iv_invoice_number         -- ��̐������ԍ�
      ,iv_terms_name             -- �x������
      ,iv_target_data_type       -- �Ώۃf�[�^���
-- 2021/08/12 Ver1.1 ADD Start
      ,iv_condition_no           -- �T���ԍ�(�J���}��؂�ő�50��)
-- 2021/08/12 Ver1.1 ADD End
      ,lv_recon_slip_num         -- �x���`�[�ԍ�
      ,lv_errbuf                 -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode                -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- A-1�ō̔Ԃ����x�����`�[�ԍ��𔽉f
    ov_recon_slip_num := lv_recon_slip_num;
    -- �I���X�e�[�^�X�𔽉f
    retcode           := lv_retcode;
--
    --  ����I���ȊO�̏ꍇ
    IF ( lv_retcode <> cv_status_normal ) THEN
      errbuf := lv_errbuf;
      -- ���[���o�b�N�𔭍s
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf      :=  cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode     :=  cv_status_error;
      gv_out_msg  :=  0;
      ROLLBACK;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf      :=  cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode     :=  cv_status_error;
      gv_out_msg  :=  0;
      ROLLBACK;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
END XXCOK024A14C;
/
