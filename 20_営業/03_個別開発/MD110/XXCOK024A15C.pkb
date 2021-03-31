CREATE OR REPLACE PACKAGE BODY APPS.XXCOK024A15C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A15 (spec)
 * Description      : �T�������쐬API(AP�≮�x��)
 * MD.050           : �T�������쐬API(AP�≮�x��) MD050_COK_024_A15
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                      ��������(A-1)
 *  sales_dedu_get            �̔��T���f�[�^���o(A-2)
 *  insert_dedu_recon_head    �T�������w�b�_�[�쐬(A-3)
 *  insert_dedu_item_recon    ���i�ʓˍ����쐬(A-4)
 *  insert_dedu_recon_line_wp �T���������׏��(�≮����)�쐬(A-5)
 *  insert_dedu_num_recon     �T��No�ʏ������쐬(A-6)
 *  insert_dedu_recon_line_ap �T���������׏��(AP�\��)�쐬(A-7)
 *  submain                   ���C�������v���V�[�W��
 *  main                      �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2020/11/11    1.0   Y.Nakajima       �V�K�쐬
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
  cv_pkg_name               CONSTANT VARCHAR2(20) := 'XXCOK024A15C';                -- �p�b�P�[�W��
  -- �A�v���P�[�V�����Z�k��
  cv_msg_kbn_cok            CONSTANT VARCHAR2(5)  := 'XXCOK';                       -- �A�h�I���F�ʊJ��
  -- ���b�Z�[�W����
  cv_data_get_msg           CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00001';            -- �Ώۃf�[�^�Ȃ��G���[���b�Z�[�W
  cv_pro_get_err_msg        CONSTANT VARCHAR2(50) := 'APP-XXCOK1-00003';            -- �v���t�@�C���擾�G���[
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
  -- �v���t�@�C��
  cv_profile_organi_code    CONSTANT VARCHAR2(50) := 'XXCOI1_ORGANIZATION_CODE';    -- �݌ɑg�D�R�[�h
  --
  cv_condition_type_ws_fix  CONSTANT VARCHAR2(3)  :=  '030';                        -- �T���^�C�v(�≮�����i��z�j)
  cv_condition_type_ws_add  CONSTANT VARCHAR2(3)  :=  '040';                        -- �T���^�C�v(�≮�����i�ǉ��j)
  --
  cv_ap                     CONSTANT VARCHAR2(4)  :=  'AP';                         -- 'AP'
  cv_wp                     CONSTANT VARCHAR2(4)  :=  'WP';                         -- 'WP'
  cv_one                    CONSTANT VARCHAR2(1)  :=  '1';                          -- '1'
  cv_two                    CONSTANT VARCHAR2(1)  :=  '2';                          -- '2'
  cv_three                  CONSTANT VARCHAR2(1)  :=  '3';                          -- '3'
  cv_hon                    CONSTANT VARCHAR2(2)  :=  '�{';                         -- �P��:�{
  cv_cs                     CONSTANT VARCHAR2(2)  :=  'CS';                         -- �P��:CS
  cv_bl                     CONSTANT VARCHAR2(2)  :=  'BL';                         -- �P��:BL
  cv_status_n               CONSTANT VARCHAR2(1)  :=  'N';                          -- 'N' (�V�K)
  cv_o                      CONSTANT VARCHAR2(1)  :=  'O';                          -- 'O' (�J�z����)
  -- �T�������w�b�_�p
  cv_recon_status           CONSTANT VARCHAR2(2)  :=  'EG';                         -- 'EG'(�쐬��)
  -- �g�[�N����
  cv_tkn_profile            CONSTANT VARCHAR2(20) := 'PROFILE ';                     -- �v���t�@�C��
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_organization_code      VARCHAR2(3)   DEFAULT NULL;   -- �݌ɑg�D�R�[�h
--
  /**********************************************************************************
   * Procedure Name   : insert_dedu_recon_line_ap
   * Description      : �T���������׏��(AP�\��)�쐬(A-7)
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
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �T��No�ʏ������̒��o
    CURSOR dedu_num_recon_cur
    IS
      SELECT   xdnr.recon_line_num              AS recon_line_num           -- �������הԍ�
             , xdnr.deduction_chain_code        AS deduction_chain_code     -- �T���p�`�F�[���R�[�h
             , SUM(xdnr.prev_carryover_amt)     AS prev_carryover_amt       -- �O���J�z�z(�Ŕ�)
             , SUM(xdnr.prev_carryover_tax)     AS prev_carryover_tax       -- �O���J�z�z(�����)
             , SUM(xdnr.deduction_amt)          AS deduction_amt            -- �T���z(�Ŕ�)
             , SUM(xdnr.deduction_tax)          AS deduction_tax            -- �T���z(�����)
      FROM   xxcok_deduction_num_recon    xdnr
      WHERE  xdnr.recon_slip_num = iv_recon_slip_num
      GROUP BY   xdnr.recon_line_num
               , xdnr.deduction_chain_code
    ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �T���������׏��(AP�\��)�̓o�^
    <<dedu_recon_line_ap_ins_loop>>
    FOR dedu_num_recon_rec IN dedu_num_recon_cur LOOP
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
        xxcok_deduction_recon_line_s01.nextval                                      -- �T����������ID
      , iv_recon_slip_num                                                           -- �x���`�[�ԍ�
      , dedu_num_recon_rec.recon_line_num                                           -- �������הԍ�
      , cv_recon_status                                                             -- ���̓X�e�[�^�X
      , dedu_num_recon_rec.deduction_chain_code                                     -- �T���p�`�F�[���R�[�h
      , dedu_num_recon_rec.prev_carryover_amt                                       -- �O���J�z�z(�Ŕ�)
      , dedu_num_recon_rec.prev_carryover_tax                                       -- �O���J�z�z(�����)
      , dedu_num_recon_rec.deduction_amt                                            -- �T���z(�Ŕ�)
      , dedu_num_recon_rec.deduction_tax                                            -- �T���z(�����)
      , cn_zero                                                                     -- �x���z(�Ŕ�)
      , cn_zero                                                                     -- �x���z(�����)
      , dedu_num_recon_rec.deduction_amt                                            -- �������z(�Ŕ�)
      , dedu_num_recon_rec.deduction_tax                                            -- �������z(�����)
      , dedu_num_recon_rec.prev_carryover_amt + dedu_num_recon_rec.deduction_amt    -- �����J�z�z(�Ŕ�)
      , dedu_num_recon_rec.prev_carryover_tax + dedu_num_recon_rec.deduction_tax    -- �����J�z�z(�����)
      , cn_created_by                                                               -- �쐬��
      , SYSDATE                                                                     -- �쐬��
      , cn_last_updated_by                                                          -- �ŏI�X�V��
      , SYSDATE                                                                     -- �ŏI�X�V��
      , cn_last_update_login                                                        -- �ŏI�X�V���O�C��
      , cn_request_id                                                               -- �v��ID
      , cn_program_application_id                                                   -- �R���J�����g�E�v���O������A�v���P�[�V����ID
      , cn_program_id                                                               -- �R���J�����g��v���O����ID
      , SYSDATE                                                                     -- �v���O�����X�V��
      )
      ;
--
    END LOOP dedu_recon_line_ap_ins_loop;
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
   * Description      : �T��No�ʏ������쐬(A-6)
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
    -- �u���C�N����p�ϐ�
    lt_break_dedu_chain_code      xxcok_sales_deduction.deduction_chain_code%TYPE DEFAULT NULL;         -- �T���p�`�F�[���R�[�h
    -- ���׃C���N�������g�p
    deduction_line_num_cnt        xxcok_deduction_num_recon.deduction_line_num%TYPE;                    -- �T�����הԍ�
    recon_line_num_cnt            xxcok_deduction_num_recon.recon_line_num%TYPE;                        -- �������הԍ�
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �̔��T����񒊏o
    CURSOR sales_dedu_inline_cur
    IS
      SELECT  xsd_inline.deduction_chain_code       AS deduction_chain_code
            , xsd_inline.data_type                  AS data_type
            , xsd_inline.replace_flag               AS replace_flag
            , xsd_inline.condition_no               AS condition_no
            , xsd_inline.tax_code                   AS tax_code
            , SUM(xsd_inline.prev_carryover_amt)    AS prev_carryover_amt
            , SUM(xsd_inline.prev_carryover_tax)    AS prev_carryover_tax
            , SUM(xsd_inline.deduction_amount)      AS deduction_amount
            , SUM(xsd_inline.deduction_tax_amount)  AS deduction_tax_amount
      FROM    (
               SELECT  NVL(xca.intro_chain_code2,xsd.deduction_chain_code)  AS deduction_chain_code   -- �T���p�`�F�[���R�[�h
                     , xsd.data_type                                        AS data_type              -- �f�[�^���
                     , flv.attribute8                                       AS replace_flag           -- ���փt���O
                     , xsd.condition_no                                     AS condition_no           -- �T���ԍ�
                     , xsd.tax_code                                         AS tax_code               -- �ŃR�[�h
                     , xsd.deduction_amount * -1                            AS prev_carryover_amt     -- �O���J�z�z
                     , xsd.deduction_tax_amount * -1                        AS prev_carryover_tax     -- �O���J�z����Ŋz
                     , 0                                                    AS deduction_amount       -- �T���z
                     , 0                                                    AS deduction_tax_amount   -- �T������Ŋz
               FROM    xxcok_sales_deduction  xsd     -- �̔��T�����
                     , fnd_lookup_values      flv     -- �f�[�^���(�Q�ƕ\)
                     , xxcmm_cust_accounts    xca     -- �ڋq�ǉ����
               WHERE   xsd.carry_payment_slip_num  = iv_recon_slip_num
               AND     flv.lookup_code             = xsd.data_type
               AND     flv.lookup_type             = cv_deduction_data_type
               AND     flv.language                = ct_lang
               AND     flv.enabled_flag            = cv_enable
               AND     flv.attribute2 NOT IN( cv_condition_type_ws_fix,cv_condition_type_ws_add )
               AND     xsd.source_category         = cv_o
               AND     xca.customer_code(+)        = xsd.customer_code_to
               UNION ALL
               SELECT  NVL(xca.intro_chain_code2,xsd.deduction_chain_code)  AS deduction_chain_code   -- �T���p�`�F�[���R�[�h
                     , xsd.data_type            AS data_type              -- �f�[�^���
                     , flv.attribute8           AS replace_flag           -- ���փt���O
                     , xsd.condition_no         AS condition_no           -- �T���ԍ�
                     , xsd.tax_code             AS tax_code               -- �ŃR�[�h
                     , 0                        AS prev_carryover_amt     -- �O���J�z�z
                     , 0                        AS prev_carryover_tax     -- �O���J�z����Ŋz
                     , xsd.deduction_amount     AS deduction_amount       -- �T���z
                     , xsd.deduction_tax_amount AS deduction_tax_amount   -- �T������Ŋz
               FROM    xxcok_sales_deduction  xsd     -- �̔��T�����
                     , fnd_lookup_values      flv     -- �f�[�^���(�Q�ƕ\)
                     , xxcmm_cust_accounts    xca     -- �ڋq�ǉ����
               WHERE   xsd.carry_payment_slip_num  = iv_recon_slip_num
               AND     flv.lookup_code             = xsd.data_type
               AND     flv.lookup_type             = cv_deduction_data_type
               AND     flv.language                = ct_lang
               AND     flv.enabled_flag            = cv_enable
               AND     flv.attribute2 NOT IN( cv_condition_type_ws_fix,cv_condition_type_ws_add )
               AND     xsd.source_category         <> cv_o
               AND     xca.customer_code(+)        = xsd.customer_code_to
               )                                                           xsd_inline
      GROUP BY   xsd_inline.deduction_chain_code
               , xsd_inline.data_type
               , xsd_inline.replace_flag
               , xsd_inline.condition_no
               , xsd_inline.tax_code
      ORDER BY   xsd_inline.deduction_chain_code
               , xsd_inline.condition_no
               , xsd_inline.tax_code
    ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
    deduction_line_num_cnt := 0;
    recon_line_num_cnt     := 0;
--
--###########################  �Œ蕔 END   ############################
--
    -- �T��No�ʏ������̓o�^
    <<dedu_num_recon_ins_loop>>
    FOR sales_dedu_inline_rec IN sales_dedu_inline_cur LOOP
      -- �������הԍ��A�T�����הԍ��̍̔�
      IF lt_break_dedu_chain_code = sales_dedu_inline_rec.deduction_chain_code THEN
        deduction_line_num_cnt := deduction_line_num_cnt + 1;
        IF recon_line_num_cnt   = 0 THEN
           recon_line_num_cnt  := 1;
        ELSE
          NULL;
        END IF;
      ELSE
        recon_line_num_cnt     := recon_line_num_cnt + 1;
        deduction_line_num_cnt := 1;
      END IF;
      
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
        xxcok_deduction_num_recon_s01.nextval                                                     -- �T��No�ʏ���ID
      , iv_recon_slip_num                                                                         -- �x���`�[�ԍ�
      , recon_line_num_cnt                                                                        -- �������הԍ�
      , sales_dedu_inline_rec.deduction_chain_code                                                -- �T���p�`�F�[���R�[�h
      , deduction_line_num_cnt                                                                    -- �T�����הԍ�
      , sales_dedu_inline_rec.data_type                                                           -- �f�[�^���
      , cv_status_n                                                                               -- �Ώۃt���O
      , sales_dedu_inline_rec.condition_no                                                        -- �T���ԍ�
      , sales_dedu_inline_rec.tax_code                                                            -- ����ŃR�[�h
      , sales_dedu_inline_rec.prev_carryover_amt                                                  -- �O���J�z�z(�Ŕ�)
      , sales_dedu_inline_rec.prev_carryover_tax                                                  -- �O���J�z�z(�����)
      , sales_dedu_inline_rec.deduction_amount                                                    -- �T���z(�Ŕ�)
      , sales_dedu_inline_rec.deduction_tax_amount                                                -- �T���z(�����)
      , sales_dedu_inline_rec.replace_flag                                                        -- �J�z�z�S�z���Z�t���O
      , sales_dedu_inline_rec.tax_code                                                            -- �x�����ŃR�[�h
      , cn_zero                                                                                   -- �x���z(�Ŕ�)
      , cn_zero                                                                                   -- �x���z(�����)
      , sales_dedu_inline_rec.deduction_amount                                                    -- �������z(�Ŕ�)
      , sales_dedu_inline_rec.deduction_tax_amount                                                -- �������z(�����)
      , CASE 
          WHEN sales_dedu_inline_rec.replace_flag = cv_enable THEN
            cn_zero
          ELSE
            (sales_dedu_inline_rec.prev_carryover_amt + sales_dedu_inline_rec.deduction_amount)
        END                                                                                       -- �����J�z�z(�Ŕ�)
      , CASE
          WHEN sales_dedu_inline_rec.replace_flag = cv_enable THEN
            cn_zero
          ELSE
            (sales_dedu_inline_rec.prev_carryover_tax + sales_dedu_inline_rec.deduction_tax_amount)
        END                                                                                       -- �����J�z�z(�����)
      , NULL                                                                                      -- �E�v
      , cn_created_by                                                                             -- �쐬��
      , SYSDATE                                                                                   -- �쐬��
      , cn_last_updated_by                                                                        -- �ŏI�X�V��
      , SYSDATE                                                                                   -- �ŏI�X�V��
      , cn_last_update_login                                                                      -- �ŏI�X�V���O�C��
      , cn_request_id                                                                             -- �v��ID
      , cn_program_application_id                                                                 -- �R���J�����g�E�v���O������A�v���P�[�V����ID
      , cn_program_id                                                                             -- �R���J�����g��v���O����ID
      , SYSDATE                                                                                   -- �v���O�����X�V��
      );
--
      -- �T���p�`�F�[���R�[�h��ޔ�
      lt_break_dedu_chain_code := sales_dedu_inline_rec.deduction_chain_code;
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
   * Procedure Name   : insert_dedu_recon_line_wp
   * Description      : �T���������׏��(�≮����)�쐬(A-5)
   **********************************************************************************/
  PROCEDURE insert_dedu_recon_line_wp(
    iv_recon_slip_num               IN     VARCHAR2          -- �x���`�[�ԍ�
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
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_dedu_recon_line_wp'; -- �v���O������
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
    -- *** ���[�J���E�J�[�\�� ***
    -- ���i�ˍ���񒊏o�J�[�\��
    CURSOR dedu_item_recon_cur
    IS
      SELECT  xdir.deduction_chain_code           AS deduction_chain_code   -- �T���p�`�F�[���R�[�h
             ,SUM(xdir.billing_amount)            AS billing_amount         -- �����z(�Ŕ�)
             ,SUM(xdir.fixed_amount)              AS fixed_amount           -- �C���㐿���z(�Ŕ�)
             ,SUM(xdir.prev_carryover_amt)        AS prev_carryover_amt     -- �O���J�z�z(�Ŕ�)
             ,SUM(xdir.prev_carryover_tax)        AS prev_carryover_tax     -- �O���J�z�z(�����)
             ,SUM(xdir.deduction_amt)             AS deduction_amt          -- �T���z(�Ŕ�)
             ,SUM(xdir.deduction_tax)             AS deduction_tax          -- �T���z(�����)
             ,SUM(xdir.payment_amt)               AS payment_amt            -- �x���z(�Ŕ�)
             ,SUM(xdir.payment_tax)               AS payment_tax            -- �x���z(�����)
             ,SUM(xdir.difference_amt)            AS difference_amt         -- �������z(�Ŕ�)
             ,SUM(xdir.difference_tax)            AS difference_tax         -- �������z(�����)
             ,SUM(xdir.next_carryover_amt)        AS next_carryover_amt     -- �����J�z�z(�Ŕ�)
             ,SUM(xdir.next_carryover_tax)        AS next_carryover_tax     -- �����J�z�z(�����)
      FROM    xxcok_deduction_item_recon    xdir      -- ���i�ʓˍ����e�[�u��
      WHERE   xdir.recon_slip_num  =  iv_recon_slip_num
      GROUP BY  xdir.deduction_chain_code
    ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �T���������׏��(�≮����)�o�^
    <<dedu_recon_line_wp_ins_loop>>
    FOR dedu_item_recoe_rec IN dedu_item_recon_cur LOOP
      INSERT INTO xxcok_deduction_recon_line_wp(
        deduction_recon_line_id                     -- �T����������ID
      , recon_slip_num                              -- �x���`�[�ԍ�
      , recon_line_status                           -- ���̓X�e�[�^�X
      , deduction_chain_code                        -- �T���p�`�F�[���R�[�h
      , billing_amount                              -- �����z(�Ŕ�)
      , fixed_amount                                -- �C���㐿���z(�Ŕ�)
      , prev_carryover_amt                          -- �O���J�z�z(�Ŕ�)
      , prev_carryover_tax                          -- �O���J�z�z(�����)
      , deduction_amt                               -- �T���z(�Ŕ�)
      , deduction_tax                               -- �T���z(�����)
      , carryover_pay_off_flg                       -- �J�z�z�S�z���Z�t���O
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
      , cv_recon_status                             -- ���̓X�e�[�^�X
      , dedu_item_recoe_rec.deduction_chain_code    -- �T���p�`�F�[���R�[�h
      , dedu_item_recoe_rec.billing_amount          -- �����z(�Ŕ�)
      , dedu_item_recoe_rec.fixed_amount            -- �C���㐿���z(�Ŕ�)
      , dedu_item_recoe_rec.prev_carryover_amt      -- �O���J�z�z(�Ŕ�)
      , dedu_item_recoe_rec.prev_carryover_tax      -- �O���J�z�z(�����)
      , dedu_item_recoe_rec.deduction_amt           -- �T���z(�Ŕ�)
      , dedu_item_recoe_rec.deduction_tax           -- �T���z(�����)
      , cv_status_n                                 -- �J�z�z�S�z���Z�t���O
      , dedu_item_recoe_rec.payment_amt             -- �x���z(�Ŕ�)
      , dedu_item_recoe_rec.payment_tax             -- �x���z(�����)
      , dedu_item_recoe_rec.difference_amt          -- �������z(�Ŕ�)
      , dedu_item_recoe_rec.difference_tax          -- �������z(�����)
      , dedu_item_recoe_rec.next_carryover_amt      -- �����J�z�z(�Ŕ�)
      , dedu_item_recoe_rec.next_carryover_tax      -- �����J�z�z(�����)
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
    END LOOP dedu_recon_line_wp_ins_loop;
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
  END insert_dedu_recon_line_wp;
--
  /**********************************************************************************
   * Procedure Name   : insert_dedu_item_recon
   * Description      : ���i�ʓˍ����쐬(A-4)
   **********************************************************************************/
  PROCEDURE insert_dedu_item_recon(
    iv_recon_base_code              IN     VARCHAR2          -- �x���������_
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
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_dedu_item_recon'; -- �v���O������
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
    ln_demand_unit_price      NUMBER;               -- �����P��
    ln_demand_adj_amt         NUMBER;               -- �������z
    ln_dedu_quantity          NUMBER;               -- �T������
    ln_dedu_unit_price        NUMBER;               -- �T���P��
--
    ln_item_id                NUMBER DEFAULT NULL;  -- �i��ID
    ln_orga_id                NUMBER DEFAULT NULL;  -- �݌ɑg�DID
    ln_content                NUMBER;               -- ����
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �ˍ����쐬
    CURSOR dedu_item_recon_inline_cur
    IS
      SELECT
              xdir_inline.deduction_chain_code              AS  deduction_chain_code                -- �T���p�`�F�[���R�[�h
            , xdir_inline.item_code                         AS  item_code                           -- �i�ڃR�[�h
            , xrtrv.tax_rate                                AS  tax_rate                            -- ����ŗ�
            , xrtrv.tax_class_suppliers_outside             AS  tax_code                            -- ����ŃR�[�h
            , MAX(xdir_inline.demand_unit_type)             AS  demand_unit_type                    -- �����P��
            , SUM(xdir_inline.demand_qty)                   AS  demand_qty                          -- ��������
            , SUM(xdir_inline.detail_amount)                AS  detail_amount                       -- �����P���~��������
            , SUM(xdir_inline.demand_amt)                   AS  demand_amt                          -- �����z
            , SUM(xdir_inline.prev_carryover_amt)           AS  prev_carryover_amt                  -- �O���J�z�z
            , SUM(xdir_inline.prev_carryover_tax)           AS  prev_carryover_tax                  -- �O���J�z����Ŋz
            , MAX(xdir_inline.deduction_uom_code)           AS  deduction_uom_code                  -- �T���P��
            , SUM(xdir_inline.deduction_quantity)           AS  deduction_quantity                  -- �T������
            , SUM(xdir_inline.deduction_amt)                AS  deduction_amt                       -- �T���z
            , SUM(xdir_inline.deduction_030)                AS  deduction_030                       -- �T���z(�ʏ�)
            , SUM(xdir_inline.deduction_040)                AS  deduction_040                       -- �T���z(�g��)
            , SUM(xdir_inline.deduction_tax)                AS  deduction_tax                       -- �T������Ŋz
      FROM    xxcos_reduced_tax_rate_v                      xrtrv                                   -- �i�ڕʏ���ŗ�view
            , (
                -- �� �≮������ ��
                SELECT
                        xwbl.sales_outlets_code             AS  deduction_chain_code                -- �T���p�`�F�[���R�[�h
                      , xwbl.item_code                      AS  item_code                           -- �i�ڃR�[�h
                      , DECODE( xwbl.demand_unit_type, cv_one, cv_hon, cv_two, cv_cs, cv_three, cv_bl )
                                                            AS  demand_unit_type                    -- �����P��
                      , DECODE(xwbl.expansion_sales_type, cv_one, cn_zero, xwbl.demand_qty)
                                                            AS  demand_qty                          -- ��������
                      , xwbl.demand_unit_price * xwbl.demand_qty
                                                            AS  detail_amount                       -- �����P���~��������
                      , xwbl.demand_amt                     AS  demand_amt                          -- �����z
                      , cn_zero                             AS  prev_carryover_amt                  -- �O���J�z�z
                      , cn_zero                             AS  prev_carryover_tax                  -- �O���J�z����Ŋz
                      , NULL                                AS  deduction_uom_code                  -- �T���P��
                      , cn_zero                             AS  deduction_quantity                  -- �T������
                      , cn_zero                             AS  deduction_amt                       -- �T���z
                      , cn_zero                             AS  deduction_030                       -- �T���z(�ʏ�)
                      , cn_zero                             AS  deduction_040                       -- �T���z(�g��)
                      , cn_zero                             AS  deduction_tax                       -- �T������Ŋz
                FROM    xxcok_wholesale_bill_line           xwbl                                    -- �≮���������׃e�[�u��
                WHERE   xwbl.recon_slip_num                 =   iv_recon_slip_num
                AND     xwbl.demand_unit_type               IN  ( cv_one, cv_two, cv_three )
                UNION ALL
                -- �� �O���J�z ��
                SELECT
                        NVL(xca.intro_chain_code2,xsd.deduction_chain_code)
                                                            AS  deduction_chain_code                -- �T���p�`�F�[���R�[�h
                      , xsd.item_code                       AS  item_code                           -- �i�ڃR�[�h
                      , NULL                                AS  demand_unit_type                    -- �����P��
                      , cn_zero                             AS  demand_qty                          -- ��������
                      , cn_zero                             AS  detail_amount                       -- �����P���~��������
                      , cn_zero                             AS  demand_amt                          -- �����z
                      , xsd.deduction_amount * -1           AS  prev_carryover_amt                  -- �O���J�z�z
                      , xsd.deduction_tax_amount * -1       AS  prev_carryover_tax                  -- �O���J�z����Ŋz
                      , msib.primary_uom_code               AS  deduction_uom_code                  -- �T���P��
                      , cn_zero                             AS  deduction_quantity                  -- �T������
                      , cn_zero                             AS  deduction_amt                       -- �T���z
                      , cn_zero                             AS  deduction_030                       -- �T���z(�ʏ�)
                      , cn_zero                             AS  deduction_040                       -- �T���z(�g��)
                      , cn_zero                             AS  deduction_tax                       -- �T������Ŋz
                FROM    xxcok_sales_deduction               xsd                                     -- �̔��T�����
                      , fnd_lookup_values                   flv                                     -- �f�[�^���
                      , xxcmm_cust_accounts                 xca                                     -- �ڋq�ǉ����
                      , mtl_system_items_b                  msib                                    -- Disc�i�ڃ}�X�^
                WHERE   xsd.carry_payment_slip_num          =   iv_recon_slip_num
                AND     flv.lookup_type                     =   cv_deduction_data_type
                AND     flv.lookup_code                     =   xsd.data_type
                AND     flv.language                        =   ct_lang
                AND     flv.enabled_flag                    =   cv_enable
                AND     flv.attribute2                      IN  ( cv_condition_type_ws_fix,cv_condition_type_ws_add )
                AND     xsd.source_category                 =   cv_o
                AND     xca.customer_code(+)                =   xsd.customer_code_to
                AND     msib.segment1                       =   xsd.item_code
                AND     msib.organization_id                =   xxcoi_common_pkg.get_organization_id(gv_organization_code)
                UNION ALL
                -- �� �̔��T�� ��
                SELECT
                        NVL(xca.intro_chain_code2,xsd.deduction_chain_code)
                                                            AS  deduction_chain_code                -- �T���p�`�F�[���R�[�h
                      , xsd.item_code                       AS  item_code                           -- �i�ڃR�[�h
                      , NULL                                AS  demand_unit_type                    -- �����P��
                      , cn_zero                             AS  demand_qty                          -- ��������
                      , cn_zero                             AS  detail_amount                       -- �����P���~��������
                      , cn_zero                             AS  demand_amt                          -- �����z
                      , cn_zero                             AS  prev_carryover_amt                  -- �O���J�z�z
                      , cn_zero                             AS  prev_carryover_tax                  -- �O���J�z����Ŋz
                      , msib.primary_uom_code               AS  deduction_uom_code                  -- �T���P��
                      , CASE
                          WHEN flv.attribute2 = cv_condition_type_ws_fix THEN
                            xxcok_common_pkg.get_uom_conversion_qty_f(
                             xsd.item_code,
                             xsd.deduction_uom_code,
                             xsd.deduction_quantity
                             )
                          WHEN flv.attribute2 = cv_condition_type_ws_add THEN
                            cn_zero
                        END                                 AS  deduction_quantity                  -- �T������
                      , xsd.deduction_amount                AS  deduction_amt                       -- �T���z
                      , CASE
                          WHEN flv.attribute2 = cv_condition_type_ws_fix THEN
                            xsd.deduction_amount
                          WHEN flv.attribute2 = cv_condition_type_ws_add THEN
                            cn_zero
                        END                                 AS  deduction_030                       -- �T���z(�ʏ�)
                      , CASE
                          WHEN flv.attribute2 = cv_condition_type_ws_fix THEN
                            cn_zero
                          WHEN flv.attribute2 = cv_condition_type_ws_add THEN
                            xsd.deduction_amount
                        END                                 AS  deduction_040                       -- �T���z(�g��)
                      , xsd.deduction_tax_amount            AS  deduction_tax                       -- �T������Ŋz
                FROM    xxcok_sales_deduction               xsd                                     -- �̔��T�����
                      , fnd_lookup_values                   flv                                     -- �f�[�^���
                      , xxcmm_cust_accounts                 xca                                     -- �ڋq�ǉ����
                      , mtl_system_items_b                  msib                                    -- Disc�i�ڃ}�X�^
                WHERE   xsd.carry_payment_slip_num          =   iv_recon_slip_num
                AND     flv.lookup_type                     =   cv_deduction_data_type
                AND     flv.lookup_code                     =   xsd.data_type
                AND     flv.language                        =   ct_lang
                AND     flv.enabled_flag                    =   cv_enable
                AND     flv.attribute2                      IN  ( cv_condition_type_ws_fix,cv_condition_type_ws_add )
                AND     xsd.source_category                 <>  cv_o
                AND     xca.customer_code(+)                =   xsd.customer_code_to
                AND     msib.segment1                       =   xsd.item_code
                AND     msib.organization_id                =   xxcoi_common_pkg.get_organization_id(gv_organization_code)
              )                                             xdir_inline
      WHERE   xrtrv.item_code                               =   xdir_inline.item_code
      AND     TRUNC(SYSDATE)                                BETWEEN xrtrv.start_date_histories  AND xrtrv.end_date_histories
      GROUP BY  xdir_inline.deduction_chain_code
              , xdir_inline.item_code
              , xrtrv.tax_rate
              , xrtrv.tax_class_suppliers_outside
      ORDER BY  xdir_inline.deduction_chain_code
              , xdir_inline.item_code
    ;
--
    dedu_item_recon_inline_rec      dedu_item_recon_inline_cur%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    OPEN dedu_item_recon_inline_cur;
    LOOP
    FETCH dedu_item_recon_inline_cur INTO dedu_item_recon_inline_rec;
    EXIT WHEN dedu_item_recon_inline_cur%NOTFOUND;
--
      -- �����P��
      IF  dedu_item_recon_inline_rec.demand_qty !=  0 THEN
        ln_demand_unit_price  :=  TRUNC( dedu_item_recon_inline_rec.detail_amount / dedu_item_recon_inline_rec.demand_qty, 2);
      ELSE
        ln_demand_unit_price  :=  0;
      END IF;
--
      -- �������z
      ln_demand_adj_amt :=  dedu_item_recon_inline_rec.demand_amt - TRUNC(ln_demand_unit_price * dedu_item_recon_inline_rec.demand_qty);
--
      -- �T������
      -- �����P�ʂ�NULL�ȊO�̏ꍇ
      IF dedu_item_recon_inline_rec.demand_unit_type IS NOT NULL AND dedu_item_recon_inline_rec.deduction_uom_code IS NOT NULL THEN
           xxcos_common_pkg.get_uom_cnv(
                                          iv_before_uom_code      => dedu_item_recon_inline_rec.deduction_uom_code, -- ���Z�O�P�ʃR�[�h
                                          in_before_quantity      => dedu_item_recon_inline_rec.deduction_quantity, -- ���Z�O����
                                          iov_item_code           => dedu_item_recon_inline_rec.item_code,          -- �i�ڃR�[�h
                                          iov_organization_code   => gv_organization_code,                          -- �݌ɑg�D�R�[�h
                                          ion_inventory_item_id   => ln_item_id,                                    -- �i��ID
                                          ion_organization_id     => ln_orga_id,                                    -- �݌ɑg�DID
                                          iov_after_uom_code      => dedu_item_recon_inline_rec.demand_unit_type,   -- ���Z��P�ʃR�[�h
                                          on_after_quantity       => ln_dedu_quantity,                              -- ���Z�㐔��
                                          on_content              => ln_content,                                    -- ����
                                          ov_errbuf               => lv_errbuf,                                     -- �G���[�E���b�Z�[�W�G���[       #�Œ�#
                                          ov_retcode              => lv_retcode,                                    -- ���^�[���E�R�[�h               #�Œ�#
                                          ov_errmsg               => lv_errmsg                                      -- ���[�U�[�E�G���[�E���b�Z�[�W   #�Œ�#
                                    );
      -- �����P�ʂ������͍T���P�ʂ�NULL�̏ꍇ(�����Ȃ�/�T���Ȃ�)
      ELSE
        ln_dedu_quantity  := dedu_item_recon_inline_rec.deduction_quantity;
      END IF;
      ln_dedu_quantity  :=  ROUND(ln_dedu_quantity,2);
--
      -- �T���P��
      IF  ln_dedu_quantity  !=  0 THEN
        ln_dedu_unit_price  :=  TRUNC( dedu_item_recon_inline_rec.deduction_amt / ln_dedu_quantity, 2);
      ELSE
        ln_dedu_unit_price  :=  0;
      END IF;
--
      -- ���i�ʓˍ����̓o�^
      INSERT INTO xxcok_deduction_item_recon(
        deduction_item_recon_id         -- ���i�ʓˍ����ID
      , recon_slip_num                  -- �x���`�[�ԍ�
      , deduction_chain_code            -- �T���p�`�F�[���R�[�h
      , item_code                       -- �i�ڃR�[�h
      , tax_code                        -- ����ŃR�[�h
      , tax_rate                        -- �ŗ�
      , uom_code                        -- �P��
      , billing_quantity                -- ��������
      , billing_unit_price              -- �����P��
      , billing_adj_amount              -- �������z
      , billing_amount                  -- �����z(�Ŕ�)
      , fixed_quantity                  -- �C���㐿������
      , fixed_unit_price                -- �C���㐿���P��
      , fixed_adj_amount                -- �C���㐿�����z
      , fixed_amount                    -- �C���㐿���z(�Ŕ�)
      , prev_carryover_amt              -- �O���J�z�z(�Ŕ�)
      , prev_carryover_tax              -- �O���J�z�z(�����)
      , deduction_quantity              -- �T������
      , deduction_unit_price            -- �T���P��
      , deduction_amt                   -- �T���z(�Ŕ�)
      , deduction_030                   -- �T���z(�ʏ�)
      , deduction_040                   -- �T���z(�g��)
      , deduction_tax                   -- �T���z(�����)
      , payment_amt                     -- �x���z(�Ŕ�)
      , payment_tax                     -- �x���z(�����)
      , difference_amt                  -- �������z(�Ŕ�)
      , difference_tax                  -- �������z(�����)
      , next_carryover_amt              -- �����J�z�z(�Ŕ�)
      , next_carryover_tax              -- �����J�z�z(�����)
      , differences                     -- ���ُ��
      , created_by                      -- �쐬��
      , creation_date                   -- �쐬��
      , last_updated_by                 -- �ŏI�X�V��
      , last_update_date                -- �ŏI�X�V��
      , last_update_login               -- �ŏI�X�V���O�C��
      , request_id                      -- �v��ID
      , program_application_id          -- �R���J�����g�E�v���O������A�v���P�[�V����ID
      , program_id                      -- �R���J�����g��v���O����ID
      , program_update_date             -- �v���O�����X�V��
      )
      VALUES(
        xxcok_deduction_item_recon_s01.nextval              -- ���i�ʓˍ����ID
      , iv_recon_slip_num                                   -- �x���`�[�ԍ�
      , dedu_item_recon_inline_rec.deduction_chain_code     -- �T���p�`�F�[���R�[�h
      , dedu_item_recon_inline_rec.item_code                -- �i�ڃR�[�h
      , dedu_item_recon_inline_rec.tax_code                 -- ����ŃR�[�h
      , dedu_item_recon_inline_rec.tax_rate                 -- �ŗ�
      , NVL( dedu_item_recon_inline_rec.demand_unit_type, dedu_item_recon_inline_rec.deduction_uom_code )
                                                            -- �P��
      , dedu_item_recon_inline_rec.demand_qty               -- ��������
      , ln_demand_unit_price                                -- �����P��
      , ln_demand_adj_amt                                   -- �������z
      , dedu_item_recon_inline_rec.demand_amt               -- �����z(�Ŕ�)
      , dedu_item_recon_inline_rec.demand_qty               -- �C���㐿������
      , ln_demand_unit_price                                -- �C���㐿���P��
      , ln_demand_adj_amt                                   -- �C���㐿�����z
      , dedu_item_recon_inline_rec.demand_amt               -- �C���㐿���z(�Ŕ�)
      , dedu_item_recon_inline_rec.prev_carryover_amt       -- �O���J�z�z(�Ŕ�)
      , dedu_item_recon_inline_rec.prev_carryover_tax       -- �O���J�z�z(�����)
      , ln_dedu_quantity                                    -- �T������
      , ln_dedu_unit_price                                  -- �T���P��
      , dedu_item_recon_inline_rec.deduction_amt            -- �T���z(�Ŕ�)
      , dedu_item_recon_inline_rec.deduction_030            -- �T���z(�ʏ�)
      , dedu_item_recon_inline_rec.deduction_040            -- �T���z(�g��)
      , dedu_item_recon_inline_rec.deduction_tax            -- �T���z(�����)
      , dedu_item_recon_inline_rec.demand_amt               -- �x���z(�Ŕ�)
      , ROUND(dedu_item_recon_inline_rec.demand_amt * dedu_item_recon_inline_rec.tax_rate / 100)
                                                            -- �x���z(�����)
      , dedu_item_recon_inline_rec.deduction_amt - dedu_item_recon_inline_rec.demand_amt
                                                            -- �������z(�Ŕ�)
      , dedu_item_recon_inline_rec.deduction_tax - ROUND(dedu_item_recon_inline_rec.demand_amt * dedu_item_recon_inline_rec.tax_rate / 100)
                                                            -- �������z(�����)
      , dedu_item_recon_inline_rec.prev_carryover_amt + dedu_item_recon_inline_rec.deduction_amt - dedu_item_recon_inline_rec.demand_amt
                                                            -- �����J�z�z(�Ŕ�)
      , dedu_item_recon_inline_rec.prev_carryover_tax + dedu_item_recon_inline_rec.deduction_tax - ROUND(dedu_item_recon_inline_rec.demand_amt * dedu_item_recon_inline_rec.tax_rate / 100)
                                                            -- �����J�z�z(�����)
      , NULL                                                -- ���ُ��
      , cn_created_by                                       -- �쐬��
      , SYSDATE                                             -- �쐬��
      , cn_last_updated_by                                  -- �ŏI�X�V��
      , SYSDATE                                             -- �ŏI�X�V��
      , cn_last_update_login                                -- �ŏI�X�V���O�C��
      , cn_request_id                                       -- �v��ID
      , cn_program_application_id                           -- �R���J�����g�E�v���O������A�v���P�[�V����ID
      , cn_program_id                                       -- �R���J�����g��v���O����ID
      , SYSDATE                                             -- �v���O�����X�V��
      )
      ;
--
    END LOOP;
    CLOSE dedu_item_recon_inline_cur;
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
  END insert_dedu_item_recon;
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
   ,iv_payee_code                   IN     VARCHAR2          -- �x����R�[�h
   ,iv_invoice_number               IN     VARCHAR2          -- �≮�������ԍ�
   ,iv_target_data_type             IN     VARCHAR2          -- �Ώۃf�[�^���
   ,iv_terms_name                   IN     VARCHAR2          -- �x������
   ,id_invoice_date                 IN     DATE              -- ���������t
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
    , cv_wp                                       -- �A�g��
    , iv_payee_code                               -- �x����R�[�h
    , NULL                                        -- ��ƃR�[�h
    , NULL                                        -- �T���p�`�F�[���R�[�h
    , NULL                                        -- �ڋq�R�[�h
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
    iv_recon_base_code              IN     VARCHAR2   -- �x���������_
   ,id_recon_due_date               IN     DATE       -- �x���\���
   ,id_gl_date                      IN     DATE       -- GL�L����
   ,od_target_date_end              OUT    DATE       -- �Ώۊ���(TO)
   ,iv_payee_code                   IN     VARCHAR2   -- �x����R�[�h
   ,iv_invoice_number               IN     VARCHAR2   -- �≮�������ԍ�
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
    result_sales_dedu_count             NUMBER;
    result_whole_bill_line_count        NUMBER;
--
    -- *** ���[�J���J�[�\�� ***
    -- �≮���������׍X�V
    CURSOR  l_recon_wholesale_bill_up_cur
    IS
      SELECT  xwbl.wholesale_bill_detail_id AS  wholesale_bill_detail_id        -- �≮����������ID
            , xwbl.selling_date             AS  target_date_end                 -- ����Ώ۔N����
      FROM    xxcok_wholesale_bill_line     xwbl
      WHERE   xwbl.bill_no                  =   iv_invoice_number
      AND     xwbl.recon_slip_num           IS  NULL
      AND     xwbl.status                   IS  NULL
      AND     xwbl.wholesale_bill_header_id IN
              (
              SELECT  xwbh.wholesale_bill_header_id
              FROM    xxcok_wholesale_bill_head xwbh
              WHERE   xwbh.base_code            =   iv_recon_base_code
              AND     xwbh.supplier_code        =   iv_payee_code
              AND     xwbh.expect_payment_date  =   id_recon_due_date
              )
      FOR UPDATE  NOWAIT;
--
    -- �̔��T�����
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
          AND     flvd.attribute3   =     cv_ap
          UNION ALL
          SELECT  flvd.lookup_code  AS  lookup_code
          FROM    fnd_lookup_values flvd
          WHERE   flvd.lookup_type  =     cv_deduction_data_type
          AND     flvd.language     =     ct_lang
          AND     flvd.enabled_flag =     cv_enable
          AND     flvd.attribute3   =     cv_wp                   )
      SELECT  xsd.sales_deduction_id
      FROM    xxcok_sales_deduction     xsd
      WHERE   xsd.sales_deduction_id    IN
              ( SELECT  /*+ INDEX(xsd xxcok_sales_deduction_n08) */
                        xsd.sales_deduction_id      AS  sales_deduction_id
                FROM    xxcok_sales_deduction       xsd
                WHERE   xsd.customer_code_to        IN
                        ( SELECT  xca.customer_code
                          FROM    xxcmm_cust_accounts         xca ,
                                  xxcok_wholesale_bill_line   xwbl
                          WHERE   xwbl.recon_slip_num         = iv_recon_slip_num
                          AND     xca.intro_chain_code2       = xwbl.sales_outlets_code )
                AND     xsd.carry_payment_slip_num  IS  NULL
                AND     xsd.record_date             <=  od_target_date_end
                AND     xsd.data_type               IN  ( SELECT tdt.lookup_code FROM target_data_type tdt )
                AND   ( xsd.report_decision_flag IS NULL OR xsd.report_decision_flag = cv_one )
                AND     xsd.status                  =   cv_status_n
                UNION ALL
                SELECT  /*+ INDEX(xsd xxcok_sales_deduction_n08) */
                        xsd.sales_deduction_id      AS  sales_deduction_id
                FROM    xxcok_sales_deduction       xsd
                WHERE   xsd.customer_code_to        IS  NULL
                AND     xsd.deduction_chain_code    IN
                        ( SELECT  xwbl.sales_outlets_code
                          FROM    xxcok_wholesale_bill_line   xwbl
                          WHERE   xwbl.recon_slip_num         = iv_recon_slip_num )
                AND     xsd.carry_payment_slip_num  IS  NULL
                AND     xsd.record_date             <=  od_target_date_end
                AND     xsd.data_type               IN  ( SELECT tdt.lookup_code FROM target_data_type tdt )
                AND   ( xsd.report_decision_flag IS NULL OR xsd.report_decision_flag = cv_one )
                AND     xsd.status                  =   cv_status_n                                           )
      FOR UPDATE  NOWAIT;
--
    -- *** ���[�J����O ***
    lock_expt       EXCEPTION;
    PRAGMA EXCEPTION_INIT(lock_expt, -54);                  -- ���b�N�G���[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �ϐ���������
    result_whole_bill_line_count := 0;
--
    -- �≮���������׍X�V
    FOR recon_wholesale_bill_up_rec IN l_recon_wholesale_bill_up_cur LOOP
      UPDATE  xxcok_wholesale_bill_line     xwbl
      SET     xwbl.recon_slip_num           = iv_recon_slip_num         ,
              xwbl.last_updated_by          = cn_last_updated_by        ,
              xwbl.last_update_date         = SYSDATE                   ,
              xwbl.last_update_login        = cn_last_update_login      ,
              xwbl.request_id               = cn_request_id             ,
              xwbl.program_application_id   = cn_program_application_id ,
              xwbl.program_id               = cn_program_id             ,
              xwbl.program_update_date      = SYSDATE
      WHERE   xwbl.wholesale_bill_detail_id = recon_wholesale_bill_up_rec.wholesale_bill_detail_id
      ;
      od_target_date_end  :=  recon_wholesale_bill_up_rec.target_date_end;
      -- ���s���ʌ������擾
      result_whole_bill_line_count := result_whole_bill_line_count + 1;
    END LOOP;
--
  -- �Ώی������O���̏ꍇ�I������
    IF result_whole_bill_line_count = 0 THEN
      lv_errbuf := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_msg_kbn_cok
                     ,iv_name         =>  cv_data_get_msg  -- �Ώۃf�[�^�Ȃ��G���[���b�Z�[�W
                   );
      RAISE global_api_warn_expt;
    END IF;
--
    -- �̔��T�����X�V
    FOR recon_slip_num_up_rec IN l_recon_slip_num_up_cur LOOP
      UPDATE  xxcok_sales_deduction         xsd
      SET     xsd.recon_slip_num            = CASE WHEN xsd.recon_slip_num IS NULL THEN
                                                  iv_recon_slip_num
                                                ELSE
                                                  xsd.recon_slip_num
                                                END                     ,
              xsd.carry_payment_slip_num    = iv_recon_slip_num         ,
              xsd.last_updated_by           = cn_last_updated_by        ,
              xsd.last_update_date          = SYSDATE                   ,
              xsd.last_update_login         = cn_last_update_login      ,
              xsd.request_id                = cn_request_id             ,
              xsd.program_application_id    = cn_program_application_id ,
              xsd.program_id                = cn_program_id             ,
              xsd.program_update_date       = SYSDATE
      WHERE   xsd.sales_deduction_id        = recon_slip_num_up_rec.sales_deduction_id
      ;
    END LOOP;
--
--#################################  �Œ��O������ START   ###################################
--
  EXCEPTION
    -- ���b�N�G���[
    WHEN lock_expt THEN
      -- �J�[�\���N���[�Y
      IF ( l_recon_slip_num_up_cur%ISOPEN ) THEN
        CLOSE l_recon_slip_num_up_cur;
      ELSIF ( l_recon_wholesale_bill_up_cur%ISOPEN ) THEN
        CLOSE l_recon_wholesale_bill_up_cur;
      END IF;
      --
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
      ELSIF ( l_recon_wholesale_bill_up_cur%ISOPEN ) THEN
        CLOSE l_recon_wholesale_bill_up_cur;
      END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** �x���n���h�� ***
    WHEN global_api_warn_expt THEN
      -- �J�[�\���N���[�Y
      IF ( l_recon_slip_num_up_cur%ISOPEN ) THEN
        CLOSE l_recon_slip_num_up_cur;
      ELSIF ( l_recon_wholesale_bill_up_cur%ISOPEN ) THEN
        CLOSE l_recon_wholesale_bill_up_cur;
      END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\���N���[�Y
      IF ( l_recon_slip_num_up_cur%ISOPEN ) THEN
        CLOSE l_recon_slip_num_up_cur;
      ELSIF ( l_recon_wholesale_bill_up_cur%ISOPEN ) THEN
        CLOSE l_recon_wholesale_bill_up_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���N���[�Y
      IF ( l_recon_slip_num_up_cur%ISOPEN ) THEN
        CLOSE l_recon_slip_num_up_cur;
      ELSIF ( l_recon_wholesale_bill_up_cur%ISOPEN ) THEN
        CLOSE l_recon_wholesale_bill_up_cur;
      END IF;
      --
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
      -- �v���t�@�C��(�݌ɑg�D�R�[�h)
    gv_organization_code := FND_PROFILE.VALUE( cv_profile_organi_code );
    IF( gv_organization_code IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_msg_kbn_cok
                    , iv_name                 => cv_pro_get_err_msg
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_organi_code
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
    -- �x���`�[�ԍ��擾
    lv_recon_slip_num := xxcok_deduction_slip_num_s01.nextval;
    --
    ov_recon_slip_num := TO_CHAR(lv_recon_slip_num,'FM0000000000');
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
   ,od_target_date_end              OUT    DATE              -- �Ώۊ���(TO)
   ,iv_payee_code                   IN     VARCHAR2          -- �x����R�[�h
   ,iv_invoice_number               IN     VARCHAR2          -- �≮�������ԍ�
   ,iv_terms_name                   IN     VARCHAR2          -- �x������
   ,id_invoice_date                 IN     DATE              -- ���������t
   ,iv_target_data_type             IN     VARCHAR2          -- �Ώۃf�[�^���
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
       iv_recon_base_code     -- �x���������_
      ,id_recon_due_date      -- �x���\���
      ,id_gl_date             -- GL�L����
      ,od_target_date_end     -- �Ώۊ���(TO)
      ,iv_payee_code          -- �x����R�[�h
      ,iv_invoice_number      -- �≮�������ԍ�
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
      ,od_target_date_end     -- �Ώۊ���(TO)
      ,iv_payee_code          -- �x����R�[�h
      ,iv_invoice_number      -- �≮�������ԍ�
      ,iv_target_data_type    -- �Ώۃf�[�^���
      ,iv_terms_name          -- �x������
      ,id_invoice_date        -- ���������t
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
    -- A-4�D���i�ʓˍ����쐬
    -- ============================================
    insert_dedu_item_recon(
       iv_recon_base_code  -- �x���������_
      ,lv_recon_slip_num   -- �x���`�[�ԍ�
      ,lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-5�D�T���������׏��(�≮����)�쐬
    -- ============================================
    insert_dedu_recon_line_wp(
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
    -- A-6�D�T��No�ʏ������쐬
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
    -- A-7�D�T���������׏��(AP�\��)�쐬
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
   ,od_target_date_end              OUT    DATE              -- �Ώۊ���(TO)
   ,iv_payee_code                   IN     VARCHAR2          -- �x����R�[�h
   ,iv_invoice_number               IN     VARCHAR2          -- �≮�������ԍ�
   ,iv_terms_name                   IN     VARCHAR2          -- �x������
   ,id_invoice_date                 IN     DATE              -- ���������t
   ,iv_target_data_type             IN     VARCHAR2          -- �Ώۃf�[�^���
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
      ,od_target_date_end        -- �Ώۊ���(TO)
      ,iv_payee_code             -- �x����R�[�h
      ,iv_invoice_number         -- �≮�������ԍ�
      ,iv_terms_name             -- �x������
      ,id_invoice_date           -- ���������t
      ,iv_target_data_type       -- �Ώۃf�[�^���
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
END XXCOK024A15C;
/
