CREATE OR REPLACE PACKAGE BODY APPS.XXCOK024A42C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2022. All rights reserved.
 *
 * Package Name     : XXCOK024A42C(body)
 * Description      : �������E������������
 * MD.050           : MD050_COK_024_A42_�������E������������
 *
 * Version          : 1.2
 *
 * Program List
 * ------------------------  -------------------------------------------------------------
 *  Name                     Description
 * ------------------------- --------------------------------------------------------------
 *  init                     ��������(A-1)
 *  get_receivable_slips_key AR������́i�������j�̃L�[���擾(A-2)
 *                           �̔��T�����i�������j�擾(A-3)
 *                           AR������́i�������j�̖��׏��擾(A-4)
 *                           AR������͍X�V(A-6)
 *                           �̔��T���f�[�^�X�V(A-7)
 *                           �T�������w�b�_�[���쐬(A-8)
 *  ins_sales_deduction      ���z�����T���f�[�^�쐬(A-5)
 *  submain                  ���C�������v���V�[�W��
 *  main                     ���s�t�@�C���o�^�v���V�[�W��
 *                           �I������(A-9)
 *
 * Change Record
 * ------------- ----- ---------------- --------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- --------------------------------------------------
 *  2022/12/13    1.0   M.Akachi         �V�K�쐬 E_�{�ғ�_18519 �������E�̏����iAR�A�g�j
 *  2023/07/26    1.1   M.Akachi         E_�{�ғ�_19275 �������E������14�Ԍڋq�̃`�F�b�N
 *                                       E_�{�ғ�_19333 �������E�����ɂ�����EDI���ѐU�֍T���̏����s��
 *  2024/03/12    1.2   SCSK Y.Koh       [E_�{�ғ�_19496] �O���[�v��Г����Ή�
 *
 *****************************************************************************************/
  --
  --#######################  �Œ�O���[�o���萔�錾�� START   #######################
  --
  -- �X�e�[�^�X�E�R�[�h
  cv_status_normal CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; -- ����:0
  cv_status_warn   CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   -- �x��:1
  cv_status_error  CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  -- �ُ�:2
  --
  -- WHO�J����
  cn_created_by             CONSTANT NUMBER := fnd_global.user_id;         -- CREATED_BY
  cd_creation_date          CONSTANT DATE   := SYSDATE;                    -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER := fnd_global.user_id;         -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE   := SYSDATE;                    -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER := fnd_global.login_id;        -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER := fnd_global.conc_request_id; -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER := fnd_global.prog_appl_id;    -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER := fnd_global.conc_program_id; -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE   := SYSDATE;                    -- PROGRAM_UPDATE_DATE
  --
  cv_msg_part CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont CONSTANT VARCHAR2(3) := '.';
  --
  --
  --################################  �Œ蕔 END   ##################################
  --
  --#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
  --
  gv_out_msg    VARCHAR2(2000) DEFAULT NULL;
  gn_target_cnt NUMBER   := 0; -- �Ώی���
  gn_normal_cnt NUMBER   := 0; -- ���팏��
  gn_error_cnt  NUMBER   := 0; -- �G���[����
  gn_warn_cnt   NUMBER   := 0; -- �X�L�b�v����
  --
  --################################  �Œ蕔 END   ##################################
  --
  --##########################  �Œ苤�ʗ�O�錾�� START  ###########################
  --
  --*** ���������ʗ�O ***
  global_process_expt EXCEPTION;
  --
  --*** ���ʊ֐���O ***
  global_api_expt EXCEPTION;
  --
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt EXCEPTION;
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
  --
  -- *** ���b�N�擾�G���[��O ***
  global_lock_failure_expt EXCEPTION;
  PRAGMA EXCEPTION_INIT( global_lock_failure_expt, -54 );
  --################################  �Œ蕔 END   ##################################
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCOK024A42C';                      -- �p�b�P�[�W��
  cv_appl_short_name_xxcok  CONSTANT VARCHAR2(10)  := 'XXCOK';                             -- �A�v���P�[�V�����Z�k��
  cn_number_zero            CONSTANT NUMBER        := 0;
  cn_number_one             CONSTANT NUMBER        := 1;
  cv_flag_yes               CONSTANT VARCHAR2(1)   := 'Y';                                 -- �t���OY
  cv_flag_off               CONSTANT VARCHAR2(1)   := '0';                                 -- �t���OOFF
  cv_flag_on                CONSTANT VARCHAR2(1)   := '1';                                 -- �t���OON
  cv_date_format            CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';                        -- ���t����
-- Ver1.1 Add Start
  cv_date_format2           CONSTANT VARCHAR2(10)  := 'YYYYMMDD';                          -- ���t����
-- Ver1.1 Add End
  cv_year_format            CONSTANT VARCHAR2(10)  := 'YYYY';                              -- ���t����(�N)
  cv_month_format           CONSTANT VARCHAR2(10)  := 'MM';                                -- ���t����(��)
  ct_deduction_data_type    CONSTANT fnd_lookup_values.lookup_type%TYPE  := 'XXCOK1_DEDUCTION_DATA_TYPE';  -- �T���f�[�^���
  cv_flag_d                 CONSTANT VARCHAR2(1)   := 'D';                                 -- �쐬���敪(���z����)
  cv_flag_v                 CONSTANT VARCHAR2(1)   := 'V';                                 -- �쐬���敪 ������ѐU�ցi�U�֊����j
  cv_flag_n                 CONSTANT VARCHAR2(1)   := 'N';                                 -- �X�e�[�^�X(�V�K) / ����t���O(�����)
  cv_flag_o                 CONSTANT VARCHAR2(1)   := 'O';                                 -- �쐬���敪(�J�z����) / GL�A�g�t���O(�ΏۊO) 
  cv_flag_y                 CONSTANT VARCHAR2(1)   := 'Y';                                 -- �������E�����X�e�[�^�X(Y�F������)
-- 2024/03/12 Ver1.2 DEL Start
--  cv_slip_type_80300        CONSTANT VARCHAR2(5)   := '80300';                             -- �`�[���:�������E
-- 2024/03/12 Ver1.2 DEL End
  cv_ar_status_appr         CONSTANT VARCHAR2(2)   := '80';                                -- ���F��
  cv_lang                   CONSTANT  VARCHAR2(100) := USERENV( 'LANG' );                  -- ����
  --
  -- ���b�Z�[�W�R�[�h
  cv_msg_cok_00028          CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00028';  -- �Ɩ��������t�擾�G���[
  cv_msg_cok_00003          CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00003';  -- �v���t�@�C���擾�G���[
  cv_msg_cok_10732          CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10732';  -- ���b�N�G���[���b�Z�[�W
  cv_msg_cok_10857          CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10857';  -- �ΏۍT���f�[�^�Ȃ����b�Z�[�W
  cv_msg_cok_10858          CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10858';  -- �x���������G���[���b�Z�[�W
  --
  --���b�Z�[�W������
  ct_msg_cok_10855          CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOK1-10855'; -- �̔��T�����(���b�Z�[�W������)
  ct_msg_cok_10856          CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOK1-10856'; -- AR������͖���(���b�Z�[�W������)
  -- �g�[�N���R�[�h
  cv_tkn_profile            CONSTANT VARCHAR2(20) := 'PROFILE';
  cv_tkn_table              CONSTANT VARCHAR2(20) := 'TABLE';
  cv_tkn_receivable_num     CONSTANT VARCHAR2(20) := 'RECEIVABLE_NUM';
  cv_tkn_line_number        CONSTANT VARCHAR2(20) := 'LINE_NUMBER';
  cv_tkn_terms_name         CONSTANT VARCHAR2(20) := 'TERMS_NAME';
  --
  --�v���t�@�C��
  cv_standard_date             CONSTANT VARCHAR2(100) := 'XXCOK1_DEDU_OFFSET_FROM_DATE';  -- �������E�`�[���o���
  cv_trans_type_name_var_cons  CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOK1_RA_TRX_TYPE_VARIABLE_CONS'; -- ����^�C�v��
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_proc_date                 DATE     DEFAULT NULL;   -- �Ɩ����t
  gd_before_month_last_date    DATE     DEFAULT NULL;   -- �Ɩ����t�̑O������
  gd_standard_date             DATE     DEFAULT NULL;   -- �������E�`�[���o���
  gv_trans_type_name_var_cons  xx03_receivable_slips.trans_type_name%TYPE;  -- �ϓ��Ή����E
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  --
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     ov_errbuf  OUT NOCOPY VARCHAR2 -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode OUT NOCOPY VARCHAR2 -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg  OUT NOCOPY VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'init'; -- �v���O������
    --
    --#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
    --
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL; -- �G���[�E���b�Z�[�W
    lv_token_value  VARCHAR2(100)  DEFAULT NULL; -- �g�[�N����
    --
    --###########################  �Œ蕔 END   ####################################
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    --
    --===============================
    --���[�J����O
    --===============================
    profile_expt  EXCEPTION;  -- �v���t�@�C���擾�G���[
    --
  BEGIN
    --
    --##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  �Œ蕔 END   ############################
    --
    -- ======================
    -- �Ɩ����t�`�F�b�N
    -- ======================
    gd_proc_date := TRUNC( xxccp_common_pkg2.get_process_date );
    --
    IF ( gd_proc_date IS NULL ) THEN
      -- �Ɩ����t�̎擾�Ɏ��s�����ꍇ�G���[
      lv_errbuf := xxccp_common_pkg.get_msg(
                     iv_application => cv_appl_short_name_xxcok  -- �A�v���P�[�V�����Z�k��
                    ,iv_name       => cv_msg_cok_00028           -- ���b�Z�[�W�R�[�h
                    );
      --
      RAISE global_api_expt;
      --
    END IF;
    --
    -- �Ɩ����t�̑O������
    gd_before_month_last_date := TRUNC( LAST_DAY( ADD_MONTHS( gd_proc_date, -1 ) ) );
    --
    --===================================
    -- XXCOK:�������E�`�[���o����̎擾
    --===================================
    gd_standard_date := TO_DATE( FND_PROFILE.VALUE( cv_standard_date ), cv_date_format ); -- �������E�`�[���o���
    --
    IF( gd_standard_date IS NULL ) THEN
      lv_token_value := TO_CHAR( cv_standard_date );
      RAISE profile_expt;
    END IF;
    --
    --====================================
    -- XXCOK:����^�C�v_�ϓ��Ή����E�̎擾
    --====================================
    gv_trans_type_name_var_cons := FND_PROFILE.VALUE( cv_trans_type_name_var_cons );
    --
    IF ( gv_trans_type_name_var_cons IS NULL ) THEN
      lv_token_value := cv_trans_type_name_var_cons;
      RAISE profile_expt;
    END IF;
--
  EXCEPTION
    --
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** ���ʊ֐���O�n���h�� ***
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
        -- *** �v���t�@�C���擾�G���[ ***
    WHEN profile_expt THEN
      lv_errbuf := xxccp_common_pkg.get_msg(
                      cv_appl_short_name_xxcok
                    , cv_msg_cok_00003
                    , cv_tkn_profile
                    , lv_token_value
                    );
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END init;
  --
  /**********************************************************************************
   * Procedure Name   : ins_sales_deduction
   * Description      : ���z�����T���f�[�^�쐬(A-5)
   ***********************************************************************************/
  PROCEDURE ins_sales_deduction(
     in_account_number         IN hz_cust_accounts.account_number%TYPE                 -- �ڋq�R�[�h
    ,iv_slip_line_type_name    IN xx03_receivable_slips_line.slip_line_type_name%TYPE  -- �������E�����p�������e
    ,in_deduction_amt_sum      IN xxcok_sales_deduction.deduction_amount%TYPE          -- �T���z���v
    ,in_deduction_tax_amt_sum  IN xxcok_sales_deduction.deduction_tax_amount%TYPE      -- �T���Ŋz���v
    ,id_derivation_record_date IN DATE                                                 -- �Ώیv������o���W�b�N�œ��o�������t
    ,iv_receivable_num         IN xx03_receivable_slips.receivable_num%TYPE            -- �Ώۃ��R�[�h�̓`�[�ԍ�
    ,iv_line_number            IN xx03_receivable_slips_line.line_number%TYPE          -- �Ώۃ��R�[�h�̖��הԍ�
    ,iv_receivable_num_1       IN xx03_receivable_slips.receivable_num%TYPE            -- 1���R�[�h�ڂ̓`�[�ԍ�
    ,iv_line_number_1          IN xx03_receivable_slips_line.line_number%TYPE          -- 1���R�[�h�ڂ̖��הԍ�
    ,ln_difference_amt         IN NUMBER                                               -- ���z
    ,ln_difference_tax_amt     IN NUMBER                                               -- �ō��z
    ,ov_errbuf                 OUT NOCOPY VARCHAR2                                     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode                OUT NOCOPY VARCHAR2                                     -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg                 OUT NOCOPY VARCHAR2                                     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT    VARCHAR2(100) := 'ins_sales_deduction'; -- �v���O������
    --
    --#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
    --
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL; -- �G���[�E���b�Z�[�W
    --
    --###########################  �Œ蕔 END   ####################################
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    --
    -- *** ���[�J���ϐ� ***
    l_xxcok_sales_deduction_rec xxcok_sales_deduction%ROWTYPE;                    -- �̔��T�����
--
    lt_difference_amt_rest      xxcok_sales_deduction.deduction_amount%TYPE;      -- �������z(�Ŕ�)_�c�z
    lt_difference_tax_rest      xxcok_sales_deduction.deduction_tax_amount%TYPE;  -- �������z(�����)_�c�z
    --
    -- *** ���[�J���E�J�[�\�� ( �̔��T�����i�������j)***
    CURSOR xxcok_sales_deduction_s_cur(
        in_account_number         IN hz_cust_accounts.account_number%TYPE                 -- A-2-1�Ŏ擾�����ڋq�R�[�h
       ,iv_receivable_num_1       IN xx03_receivable_slips.receivable_num%TYPE            -- A-4-1�Ŏ擾����1���R�[�h�ڂ̓`�[�ԍ�
       ,iv_line_number_1          IN xx03_receivable_slips_line.line_number%TYPE          -- A-4-1�Ŏ擾����1���R�[�h�ڂ̖��הԍ�
       ,iv_slip_line_type_name    IN xx03_receivable_slips_line.slip_line_type_name%TYPE  -- A-2-1�Ŏ擾�����������E�����p�������e
       ,id_derivation_record_date IN DATE                                                 -- �Ώیv������o���W�b�N�œ��o�������t
    )
    IS
      SELECT  /*+ USE_INVISIBLE_INDEXES INDEX(xxcok_sales_deduction_n10) */
              xsd.customer_code_to          AS customer_code_to        -- �U�֐�ڋq�R�[�h
             ,xsd.deduction_chain_code      AS deduction_chain_code    -- �T���p�`�F�[���R�[�h
             ,xsd.corp_code                 AS corp_code               -- ��ƃR�[�h
             ,xsd.condition_id              AS condition_id            -- �T������ID
             ,xsd.condition_no              AS condition_no            -- �T���ԍ�
             ,xsd.data_type                 AS data_type               -- �f�[�^���
             ,xsd.item_code                 AS item_code               -- �i�ڃR�[�h
             ,xsd.tax_code                  AS tax_code                -- �ŃR�[�h
             ,CASE  
               WHEN  xsd.source_category IN  ( 'F', 'U' ) THEN
                     xsd.base_code_to
               ELSE
                     xca.past_sale_base_code
              END                           AS recon_base_code         -- �������v�㋒�_
             ,SUM(xsd.deduction_amount)     AS deduction_amount        -- �T���z���v
             ,SUM(xsd.deduction_tax_amount) AS deduction_tax_amount    -- �T���Ŋz���v
      FROM    xxcok_sales_deduction xsd                                -- �̔��T�����
             ,xxcmm_cust_accounts   xca                                -- �ڋq�ǉ����
      WHERE
      ( xsd.recon_slip_num IS NULL OR xsd.recon_slip_num = iv_receivable_num_1 || '-' || iv_line_number_1 )  -- �x���`�[�ԍ�
      AND xsd.status = cv_flag_n                                                            -- �X�e�[�^�X:N(�V�K)
      AND xsd.customer_code_from IN ( SELECT ship_account_number AS ship_account_number     -- �U�֌��ڋq�R�[�h
                                      FROM   xxcfr_cust_hierarchy_v xchv
                                      WHERE  xchv.cash_account_number = in_account_number
                                      OR     xchv.bill_account_number = in_account_number
                                      OR     xchv.ship_account_number = in_account_number )
      AND xsd.data_type          IN ( SELECT flv.lookup_code AS code                        -- �f�[�^���
                                      FROM   fnd_lookup_values flv
                                      WHERE  flv.lookup_type  = ct_deduction_data_type
                                      AND    flv.language     = cv_lang
                                      AND    flv.enabled_flag = cv_flag_yes
                                      AND    flv.attribute14 = iv_slip_line_type_name )
      AND xsd.source_category <> cv_flag_d                                                    -- �쐬���敪 <> D:���z����
      AND xsd.record_date <= id_derivation_record_date                                        -- �Ώیv������o���W�b�N�œ��o�������t
-- Ver1.1 Mod Start
--      AND ( ( xsd.source_category = cv_flag_v AND xsd.report_decision_flag = cv_flag_on )     -- (�쐬���敪 = V:������ѐU�ցi�U�֊����jAND ����m��t���O:1(���ѐU�֊m��ς�)
--            OR                                                                                --  OR
--            ( xsd.source_category <> cv_flag_v AND xsd.report_decision_flag IS NULL ) )       --  �쐬���敪 <> V:������ѐU�ցi�U�֊����jAND ����m��t���O IS NULL)
      AND ( xsd.report_decision_flag = cv_flag_on OR xsd.report_decision_flag IS NULL )       -- ����m��t���O:1(���ѐU�֊m��ς�)�܂���NULL
-- Ver1.1 Mod End
      AND xsd.customer_code_to = xca.customer_code
      GROUP BY  xsd.customer_code_to      -- �U�֐�ڋq�R�[�h
               ,xsd.deduction_chain_code  -- �T���p�`�F�[���R�[�h
               ,xsd.corp_code             -- ��ƃR�[�h
               ,xsd.condition_id          -- �T������ID
               ,xsd.condition_no          -- �T���ԍ�
               ,xsd.data_type             -- �f�[�^���
               ,xsd.item_code             -- �i�ڃR�[�h
               ,xsd.tax_code              -- �ŃR�[�h
               ,CASE  
                  WHEN  xsd.source_category IN  ( 'F', 'U' ) THEN
                        xsd.base_code_to
                  ELSE
                        xca.past_sale_base_code
                END     
      ORDER BY  xsd.customer_code_to
               ,xsd.item_code
      ;
--
    TYPE xxcok_sales_deduction_s_ttype  IS TABLE OF xxcok_sales_deduction_s_cur%ROWTYPE;
    xxcok_sales_deduction_s_tab         xxcok_sales_deduction_s_ttype;
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
    -- �ϐ�������
    lt_difference_amt_rest  :=  ln_difference_amt;
    lt_difference_tax_rest  :=  ln_difference_tax_amt;
--
    OPEN  xxcok_sales_deduction_s_cur( in_account_number, iv_receivable_num_1, iv_line_number_1, iv_slip_line_type_name, id_derivation_record_date );
    FETCH xxcok_sales_deduction_s_cur BULK COLLECT INTO xxcok_sales_deduction_s_tab;
    CLOSE xxcok_sales_deduction_s_cur;
--
    FOR i IN 1..xxcok_sales_deduction_s_tab.COUNT LOOP
      -- �ŏI���R�[�h�̏ꍇ�́A�������z_�c�A�������z(�����)_�c��ݒ�
      IF i = xxcok_sales_deduction_s_tab.COUNT THEN
        l_xxcok_sales_deduction_rec.deduction_amount         :=  lt_difference_amt_rest;
        l_xxcok_sales_deduction_rec.deduction_tax_amount     :=  lt_difference_tax_rest;
      ELSE
        -- �T���z���v��0�̏ꍇ�́A�T���z = 0 ��ݒ�
        IF in_deduction_amt_sum = 0 THEN
          l_xxcok_sales_deduction_rec.deduction_amount       :=  0;
        ELSE
          l_xxcok_sales_deduction_rec.deduction_amount       :=  ROUND( ln_difference_amt
                                                                        * xxcok_sales_deduction_s_tab(i).deduction_amount
                                                                        / in_deduction_amt_sum );
        END IF;
        -- �T���Ŋz���v��0�̏ꍇ�́A�T���Ŋz = 0��ݒ�
        IF in_deduction_tax_amt_sum = 0 THEN
          l_xxcok_sales_deduction_rec.deduction_tax_amount   :=  0;
        ELSE
          l_xxcok_sales_deduction_rec.deduction_tax_amount   :=  ROUND( ln_difference_tax_amt
                                                                        * xxcok_sales_deduction_s_tab(i).deduction_tax_amount
                                                                        / in_deduction_tax_amt_sum );
        END IF;
      END IF;
--
      IF  l_xxcok_sales_deduction_rec.deduction_amount  !=  0 OR  l_xxcok_sales_deduction_rec.deduction_tax_amount  !=0 THEN
        l_xxcok_sales_deduction_rec.sales_deduction_id       :=  xxcok_sales_deduction_s01.NEXTVAL                   ;   -- �̔��T��ID
        l_xxcok_sales_deduction_rec.base_code_from           :=  xxcok_sales_deduction_s_tab(i).recon_base_code      ;   -- �U�֌����_
        l_xxcok_sales_deduction_rec.base_code_to             :=  xxcok_sales_deduction_s_tab(i).recon_base_code      ;   -- �U�֐拒�_
        l_xxcok_sales_deduction_rec.customer_code_from       :=  xxcok_sales_deduction_s_tab(i).customer_code_to     ;   -- �U�֌��ڋq�R�[�h
        l_xxcok_sales_deduction_rec.customer_code_to         :=  xxcok_sales_deduction_s_tab(i).customer_code_to     ;   -- �U�֐�ڋq�R�[�h
        l_xxcok_sales_deduction_rec.deduction_chain_code     :=  xxcok_sales_deduction_s_tab(i).deduction_chain_code ;   -- �T���p�`�F�[���R�[�h
        l_xxcok_sales_deduction_rec.corp_code                :=  xxcok_sales_deduction_s_tab(i).corp_code            ;   -- ��ƃR�[�h
        l_xxcok_sales_deduction_rec.record_date              :=  id_derivation_record_date                           ;   -- �v���
        l_xxcok_sales_deduction_rec.source_category          :=  cv_flag_d                                           ;   -- �쐬���敪
        l_xxcok_sales_deduction_rec.source_line_id           :=  NULL      	                                         ;   -- �쐬������ID
        l_xxcok_sales_deduction_rec.condition_id             :=  xxcok_sales_deduction_s_tab(i).condition_id         ;   -- �T������ID
        l_xxcok_sales_deduction_rec.condition_no             :=  xxcok_sales_deduction_s_tab(i).condition_no         ;   -- �T���ԍ�
        l_xxcok_sales_deduction_rec.condition_line_id        :=  NULL                                                ;   -- �T���ڍ�ID
        l_xxcok_sales_deduction_rec.data_type                :=  xxcok_sales_deduction_s_tab(i).data_type            ;   -- �f�[�^���
        l_xxcok_sales_deduction_rec.status                   :=  cv_flag_n                                           ;   -- �X�e�[�^�X
        l_xxcok_sales_deduction_rec.item_code                :=  xxcok_sales_deduction_s_tab(i).item_code            ;   -- �i�ڃR�[�h
        l_xxcok_sales_deduction_rec.sales_uom_code           :=  NULL                                                ;   -- �̔��P��
        l_xxcok_sales_deduction_rec.sales_unit_price         :=  NULL                                                ;   -- �̔��P��
        l_xxcok_sales_deduction_rec.sales_quantity           :=  NULL                                                ;   -- �̔�����
        l_xxcok_sales_deduction_rec.sale_pure_amount         :=  NULL                                                ;   -- ����{�̋��z
        l_xxcok_sales_deduction_rec.sale_tax_amount          :=  NULL                                                ;   -- �������Ŋz
        l_xxcok_sales_deduction_rec.deduction_uom_code       :=  NULL                                                ;   -- �T���P��
        l_xxcok_sales_deduction_rec.deduction_unit_price     :=  NULL                                                ;   -- �T���P��
        l_xxcok_sales_deduction_rec.deduction_quantity       :=  NULL                                                ;   -- �T������
--      l_xxcok_sales_deduction_rec.deduction_amount         :=  (��L�ŎZ�o��)                                      ;   -- �T���z
        l_xxcok_sales_deduction_rec.compensation             :=  NULL                                                ;   -- ��U
        l_xxcok_sales_deduction_rec.margin                   :=  NULL                                                ;   -- �≮�}�[�W��
        l_xxcok_sales_deduction_rec.sales_promotion_expenses :=  NULL                                                ;   -- �g��
        l_xxcok_sales_deduction_rec.margin_reduction         :=  NULL                                                ;   -- �≮�}�[�W�����z
        l_xxcok_sales_deduction_rec.tax_code                 :=  xxcok_sales_deduction_s_tab(i).tax_code             ;   -- �ŃR�[�h
        l_xxcok_sales_deduction_rec.tax_rate                 :=  NULL                                                ;   -- �ŗ�
        l_xxcok_sales_deduction_rec.recon_tax_code           :=  xxcok_sales_deduction_s_tab(i).tax_code             ;   -- �������ŃR�[�h
        l_xxcok_sales_deduction_rec.recon_tax_rate           :=  NULL                                                ;   -- �������ŗ�
--      l_xxcok_sales_deduction_rec.deduction_tax_amount     :=  (��L�ŎZ�o��)                                      ;   -- �T���Ŋz
        l_xxcok_sales_deduction_rec.remarks                  :=  NULL                                                ;   -- ���l
        l_xxcok_sales_deduction_rec.application_no           :=  NULL                                                ;   -- �\����No.
        l_xxcok_sales_deduction_rec.gl_if_flag               :=  cv_flag_o                                           ;   -- GL�A�g�t���O
        l_xxcok_sales_deduction_rec.gl_base_code             :=  NULL                                                ;   -- GL�v�㋒�_
        l_xxcok_sales_deduction_rec.gl_date                  :=  NULL                                                ;   -- GL�L����
        l_xxcok_sales_deduction_rec.recovery_date            :=  NULL                                                ;   -- ���J�o���f�[�^�ǉ������t
        l_xxcok_sales_deduction_rec.recovery_add_request_id  :=  NULL                                                ;   -- ���J�o���f�[�^�ǉ����v��ID
        l_xxcok_sales_deduction_rec.recovery_del_date        :=  NULL                                                ;   -- ���J�o���f�[�^�폜�����t
        l_xxcok_sales_deduction_rec.recovery_del_request_id  :=  NULL                                                ;   -- ���J�o���f�[�^�폜���v��ID
        l_xxcok_sales_deduction_rec.cancel_flag              :=  cv_flag_n                                           ;   -- ����t���O
        l_xxcok_sales_deduction_rec.cancel_base_code         :=  NULL                                                ;   -- ������v�㋒�_
        l_xxcok_sales_deduction_rec.cancel_gl_date           :=  NULL                                                ;   -- ���GL�L����
        l_xxcok_sales_deduction_rec.cancel_user              :=  NULL                                                ;   -- ������{���[�U
        l_xxcok_sales_deduction_rec.recon_base_code          :=  xxcok_sales_deduction_s_tab(i).recon_base_code      ;   -- �������v�㋒�_
        l_xxcok_sales_deduction_rec.recon_slip_num           :=  iv_receivable_num || '-' || iv_line_number          ;   -- �x���`�[�ԍ�
        l_xxcok_sales_deduction_rec.carry_payment_slip_num   :=  iv_receivable_num || '-' || iv_line_number          ;   -- �J�z���x���`�[�ԍ�
        l_xxcok_sales_deduction_rec.report_decision_flag     :=  NULL                                                ;   -- ����m��t���O
        l_xxcok_sales_deduction_rec.gl_interface_id          :=  NULL                                                ;   -- GL�A�gID
        l_xxcok_sales_deduction_rec.cancel_gl_interface_id   :=  NULL                                                ;   -- ���GL�A�gID
        l_xxcok_sales_deduction_rec.created_by               :=  cn_created_by                                       ;   -- �쐬��
        l_xxcok_sales_deduction_rec.creation_date            :=  cd_creation_date                                    ;   -- �쐬��
        l_xxcok_sales_deduction_rec.last_updated_by          :=  cn_last_updated_by                                  ;   -- �ŏI�X�V��
        l_xxcok_sales_deduction_rec.last_update_date         :=  cd_last_update_date                                 ;   -- �ŏI�X�V��
        l_xxcok_sales_deduction_rec.last_update_login        :=  cn_last_update_login                                ;   -- �ŏI�X�V���O�C��
        l_xxcok_sales_deduction_rec.request_id               :=  cn_request_id                                       ;   -- �v��ID
        l_xxcok_sales_deduction_rec.program_application_id   :=  cn_program_application_id                           ;   -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        l_xxcok_sales_deduction_rec.program_id               :=  cn_program_id                                       ;   -- �R���J�����g�E�v���O����ID
        l_xxcok_sales_deduction_rec.program_update_date      :=  cd_program_update_date                              ;   -- �v���O�����X�V��
--
        INSERT  INTO  xxcok_sales_deduction VALUES  l_xxcok_sales_deduction_rec;
--
        lt_difference_amt_rest  :=  lt_difference_amt_rest  - l_xxcok_sales_deduction_rec.deduction_amount;
        lt_difference_tax_rest  :=  lt_difference_tax_rest  - l_xxcok_sales_deduction_rec.deduction_tax_amount;
      END IF;
    END LOOP;
  EXCEPTION
    --
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** ���ʊ֐���O�n���h�� ***
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END ins_sales_deduction;
  --
   /**********************************************************************************
   * Procedure Name   : get_receivable_slips_key
   * Description      : AR������́i�������j�̃L�[���擾(A-2)
   ***********************************************************************************/
  PROCEDURE get_receivable_slips_key(
     ov_errbuf                 OUT NOCOPY VARCHAR2                                        -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode                OUT NOCOPY VARCHAR2                                        -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg                 OUT NOCOPY VARCHAR2                                        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'get_receivable_slips_key'; -- �v���O������
    --
    --#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
    --
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL; -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1)    DEFAULT NULL; -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL; -- ���[�U�[�E�G���[�E���b�Z�[�W
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
    -- *** ���[�J����O ***
--
    -- *** ���[�J���E�J�[�\�� (AR������̓��b�N���)***
    CURSOR receivable_slips_lock_cur
    IS
       SELECT xrsl.receivable_line_id  AS receivable_line_id
       FROM xx03_receivable_slips xrs1                                      -- AR�������
           ,xx03_receivable_slips_line xrsl                                 -- AR������͖���
           ,ar_memo_lines_vl amlv                                           -- ��������
       WHERE
       xrs1.receivable_id = xrsl.receivable_id
-- 2024/03/12 Ver1.2 DEL Start
--       AND xrs1.slip_type = cv_slip_type_80300                              -- �`�[���:80300(�������E)
-- 2024/03/12 Ver1.2 DEL End
-- 2024/03/12 Ver1.2 MOD Start
       AND xrs1.trans_type_name LIKE gv_trans_type_name_var_cons || '%'     -- ����^�C�v��(�ϓ��Ή����E)
--       AND xrs1.trans_type_name = gv_trans_type_name_var_cons               -- ����^�C�v��(�ϓ��Ή����E)
-- 2024/03/12 Ver1.2 MOD End
       AND xrsl.slip_line_type_name = amlv.name                             -- �������e
       AND amlv.attribute3 IS NOT NULL                                      -- ��������.�������E�����p�������e�ɒl����
       AND xrs1.wf_status = cv_ar_status_appr                               -- �X�e�[�^�X:80(���F��)
       AND NOT EXISTS ( SELECT *                                            -- �`�[����ς݂͏��O
                        FROM   xx03_receivable_slips xrs2
                        WHERE  xrs1.receivable_num = xrs2.orig_invoice_num  -- AR�������.�`�[�ԍ�= AR�������2.�C�����`�[�ԍ�
                        AND    xrs2.wf_status = cv_ar_status_appr )         -- �������2.�X�e�[�^�X = 80(���F��)
       AND xrs1.orig_invoice_num IS NULL                                    -- ����`�[�͒��o�ΏۊO
       AND xrsl.attribute8 IS NULL                                          -- �������E�����X�e�[�^�X(������)
       AND xrs1.gl_date >= gd_standard_date
       AND xrs1.gl_date <= gd_before_month_last_date
       FOR UPDATE OF xrsl.receivable_line_id NOWAIT
       ;
     receivable_slips_line_lock_rec         receivable_slips_lock_cur%ROWTYPE;
--
    -- *** ���[�J���E�J�[�\�� (AR������́i�������j�̃L�[���)***
    CURSOR receivable_slips_key_cur
    IS
      SELECT
      DISTINCT
       hca.account_number           AS account_number                      -- �ڋq�R�[�h
      ,xrs1.customer_id             AS customer_id                         -- �ڋqID
      ,xrs1.invoice_date            AS invoice_date                        -- ���������t
      ,xrs1.payment_scheduled_date  AS payment_scheduled_date              -- �����\���
      ,xrs1.terms_name              AS terms_name                          -- �x��������
      ,amlv.attribute3              AS slip_line_type_name                 -- �������E�����p�������e
-- Ver1.1 Add Start
      ,(SELECT distinct 1
        FROM  xxcfr_cust_hierarchy_v xchv
        WHERE xchv.cash_account_number <> hca.account_number
        AND   xchv.bill_account_number <> hca.account_number
        AND   xchv.ship_account_number = hca.account_number )  AS div1 -- �o�א�ڋq�R�[�h
      ,(SELECT distinct 2
        FROM  xxcfr_cust_hierarchy_v xchv
        WHERE xchv.cash_account_number <> hca.account_number
        AND   xchv.bill_account_number = hca.account_number
        AND   xchv.ship_account_number = hca.account_number )  AS div2 -- �o�א�ڋq�R�[�h
      ,(SELECT distinct 3
        FROM  xxcfr_cust_hierarchy_v xchv
        WHERE xchv.cash_account_number <> hca.account_number
        AND   xchv.bill_account_number = hca.account_number
        AND   xchv.ship_account_number <> hca.account_number ) AS div3 -- ������ڋq�R�[�h
      ,(SELECT distinct 4
        FROM  xxcfr_cust_hierarchy_v xchv
        WHERE xchv.cash_account_number = hca.account_number
        AND   xchv.bill_account_number = hca.account_number
        AND   xchv.ship_account_number = hca.account_number )  AS div4 -- ������ڋq�R�[�h
      ,(SELECT distinct 5
        FROM  xxcfr_cust_hierarchy_v xchv
        WHERE xchv.cash_account_number = hca.account_number
        AND   xchv.bill_account_number = hca.account_number
        AND   xchv.ship_account_number <> hca.account_number ) AS div5 -- ������ڋq�R�[�h
      ,(SELECT distinct 6
        FROM  xxcfr_cust_hierarchy_v xchv
        WHERE xchv.cash_account_number = hca.account_number
        AND   xchv.bill_account_number <> hca.account_number
        AND   xchv.ship_account_number <> hca.account_number ) AS div6 -- ������ڋq�R�[�h
-- Ver1.1 Add End
      FROM xx03_receivable_slips xrs1                                      -- AR�������
          ,xx03_receivable_slips_line xrsl                                 -- AR������͖���
          ,hz_cust_accounts hca                                            -- �ڋq�}�X�^
          ,ar_memo_lines_vl amlv                                           -- ��������
      WHERE
      xrs1.receivable_id = xrsl.receivable_id
-- 2024/03/12 Ver1.2 DEL Start
--      AND xrs1.slip_type = cv_slip_type_80300                              -- �`�[���:80300(�������E)
-- 2024/03/12 Ver1.2 DEL End
-- 2024/03/12 Ver1.2 MOD Start
      AND xrs1.trans_type_name LIKE gv_trans_type_name_var_cons || '%'     -- ����^�C�v��(�ϓ��Ή����E)
--      AND xrs1.trans_type_name = gv_trans_type_name_var_cons               -- ����^�C�v��(�ϓ��Ή����E)
-- 2024/03/12 Ver1.2 MOD End
      AND xrsl.slip_line_type_name  = amlv.name                            -- AR������͖���. �������e = ��������.����
      AND amlv.attribute3 IS NOT NULL                                      -- ��������.�������E�����p�������e�ɒl����
      AND xrs1.wf_status = cv_ar_status_appr                               -- �X�e�[�^�X:80(���F��)
      AND NOT EXISTS ( SELECT *                                            -- �`�[����ς݂͏��O
                       FROM   xx03_receivable_slips xrs2
                       WHERE  xrs1.receivable_num = xrs2.orig_invoice_num  -- AR�������.�`�[�ԍ�= AR�������2.�C�����`�[�ԍ�
                       AND    xrs2.wf_status = cv_ar_status_appr )         -- �������2.�X�e�[�^�X = 80(���F��)
      AND xrs1.orig_invoice_num IS NULL                                    -- ����`�[�͒��o�ΏۊO
      AND xrsl.attribute8 IS NULL                                          -- �������E�����X�e�[�^�X(������)
      AND hca.cust_account_id = xrs1.customer_id
      AND xrs1.gl_date >= gd_standard_date
      AND xrs1.gl_date <= gd_before_month_last_date
-- Ver1.1 Mod Start
--      ORDER BY xrs1.invoice_date ASC
      ORDER BY div1 ASC
              ,div2 ASC
              ,div3 ASC
              ,div4 ASC
              ,div5 ASC
              ,div6 ASC
              ,xrs1.invoice_date ASC
-- Ver1.1 Mod End
      ;
--
    -- *** ���[�J���E�J�[�\�� (�̔��T����񃍃b�N���)***
    CURSOR sales_deduction_lock_cur(
      in_account_number         IN hz_cust_accounts.account_number%TYPE                 -- A-2-1�Ŏ擾�����ڋq�R�[�h
     ,iv_slip_line_type_name    IN xx03_receivable_slips_line.slip_line_type_name%TYPE  -- 1.2.1�Ŏ擾�����������E�����p�������e
     ,id_derivation_record_date IN DATE
    )
    IS
      SELECT /*+ USE_INVISIBLE_INDEXES INDEX(xxcok_sales_deduction_n10) */
             xsd.sales_deduction_id   AS sales_deduction_id
      FROM   xxcok_sales_deduction xsd                                                   -- �̔��T�����
      WHERE
      xsd.recon_slip_num IS NULL                                                         -- �x���`�[�ԍ�
      AND xsd.status = cv_flag_n                                                         -- �X�e�[�^�X:N(�V�K)
      AND xsd.customer_code_from IN ( SELECT ship_account_number AS ship_account_number  -- �U�֌��ڋq�R�[�h
                                      FROM   xxcfr_cust_hierarchy_v xchv
                                      WHERE  xchv.cash_account_number = in_account_number
                                      OR     xchv.bill_account_number = in_account_number
                                      OR     xchv.ship_account_number = in_account_number )
      AND xsd.data_type          IN ( SELECT flv.lookup_code AS code                     -- �f�[�^���
                                      FROM   fnd_lookup_values flv
                                      WHERE  flv.lookup_type  = ct_deduction_data_type
                                      AND    flv.language     = cv_lang
                                      AND    flv.enabled_flag = cv_flag_yes
                                      AND    flv.attribute14  = iv_slip_line_type_name )
      AND xsd.record_date <= id_derivation_record_date                                     -- �Ώیv������o���W�b�N�œ��o�������t
      AND xsd.source_category <> cv_flag_d                                                 -- �쐬���敪 <> D:���z����
-- Ver1.1 Mod Start
--      AND ( ( xsd.source_category = cv_flag_v AND xsd.report_decision_flag = cv_flag_on )  -- (�쐬���敪 = V:������ѐU�ցi�U�֊����jAND ����m��t���O:1(���ѐU�֊m��ς�)
--            OR                                                                             --  OR
--            ( xsd.source_category <> cv_flag_v AND xsd.report_decision_flag IS NULL ) )    --  �쐬���敪 <> V:������ѐU�ցi�U�֊����jAND ����m��t���O IS NULL)
      AND ( xsd.report_decision_flag = cv_flag_on OR xsd.report_decision_flag IS NULL )    -- ����m��t���O:1(���ѐU�֊m��ς�)�܂���NULL
-- Ver1.1 Mod End
      FOR UPDATE NOWAIT
      ;
--
    -- *** ���[�J���E�J�[�\�� (AR������́i�������j�̖��׏��)***
    CURSOR receivable_slips_cur(
        in_customer_id            IN xx03_receivable_slips.customer_id%TYPE               -- �ڋqID
       ,id_invoice_date           IN xx03_receivable_slips.invoice_date%TYPE              -- ���������t
       ,id_payment_scheduled_date IN xx03_receivable_slips.payment_scheduled_date%TYPE    -- �����\���
       ,iv_terms_name             IN xx03_receivable_slips.terms_name%TYPE                -- �x��������
       ,iv_slip_line_type_name    IN xx03_receivable_slips_line.slip_line_type_name%TYPE  -- �������E�����p�������e
       ,id_standard_day           IN DATE                                                 -- �������E�`�[���o���
       ,id_before_month_last_date IN DATE                                                 -- �Ɩ����t�̑O���̖���
    )
    IS
      SELECT
       xrs1.receivable_num        AS receivable_num                        -- AR�������.�`�[�ԍ�
      ,xrsl.receivable_line_id    AS receivable_line_id                    -- AR������͖���.����ID
      ,xrsl.line_number           AS line_number                           -- AR������͖���.����No
      ,xrsl.slip_line_type_name   AS slip_line_type_name                   -- AR������͖���.�������e
      ,xrsl.tax_code              AS tax_code                              -- AR������͖���.�ŃR�[�h
      ,xrsl.entered_item_amount   AS entered_item_amount                   -- AR������͖���.�{�̋��z
      ,xrsl.entered_tax_amount    AS entered_tax_amount                    -- AR������͖���.����Ŋz
      ,xrs1.requestor_person_id   AS requestor_person_id                   -- AR�������.�\����
      ,xrs1.approver_person_id    AS approver_person_id                    -- AR�������.���F��
      ,xrs1.request_date          AS request_date                          -- AR�������.�\����
      ,xrs1.approval_date         AS approval_date                         -- AR�������.���F��
      ,xrs1.entry_department      AS entry_department                      -- AR�������.�N�[����
      ,xrs1.gl_date               AS gl_date                               -- AR�������.�v���
      FROM xx03_receivable_slips xrs1                                      -- AR�������
          ,xx03_receivable_slips_line xrsl                                 -- AR������͖���
      WHERE
      xrs1.receivable_id = xrsl.receivable_id
-- 2024/03/12 Ver1.2 DEL Start
--      AND xrs1.slip_type = cv_slip_type_80300                              -- �`�[���:80300(�������E)
-- 2024/03/12 Ver1.2 DEL End
-- 2024/03/12 Ver1.2 MOD Start
      AND xrs1.trans_type_name LIKE gv_trans_type_name_var_cons || '%'     -- ����^�C�v��(�ϓ��Ή����E)
--      AND xrs1.trans_type_name = gv_trans_type_name_var_cons               -- ����^�C�v��(�ϓ��Ή����E)
-- 2024/03/12 Ver1.2 MOD End
      AND xrs1.customer_id = in_customer_id                                -- �ڋqID
      AND xrs1.invoice_date = id_invoice_date                              -- ���������t
      AND xrs1.payment_scheduled_date = id_payment_scheduled_date          -- �����\���
      AND xrs1.terms_name = iv_terms_name                                  -- �x��������
      AND xrsl.slip_line_type_name IN ( SELECT amlv.name                   -- �������e
                                        FROM   ar_memo_lines_vl amlv
                                        WHERE  amlv.attribute3 = iv_slip_line_type_name )
      AND xrs1.wf_status = cv_ar_status_appr                               -- �X�e�[�^�X:80(���F��)
      AND NOT EXISTS ( SELECT *                                            -- �`�[����ς݂͏��O
                       FROM   xx03_receivable_slips xrs2
                       WHERE  xrs1.receivable_num = xrs2.orig_invoice_num  -- AR�������.�`�[�ԍ�= AR�������2.�C�����`�[�ԍ�
                       AND    xrs2.wf_status = cv_ar_status_appr )         -- �������2.�X�e�[�^�X = 80(���F��)
      AND xrs1.orig_invoice_num IS NULL                                    -- ����`�[�͒��o�ΏۊO
      AND xrsl.attribute8 IS NULL                                          -- �������E�����X�e�[�^�X(������)
      AND xrs1.gl_date >= id_standard_day
      AND xrs1.gl_date <= id_before_month_last_date
      ORDER BY xrs1.invoice_date   ASC                                     -- ���������t
              ,xrs1.receivable_num ASC                                     -- �`�[�ԍ�
              ,xrsl.line_number    ASC                                     -- ����No
      ;
--
    TYPE receivable_slips_ttype  IS TABLE OF receivable_slips_cur%ROWTYPE;
    receivable_slips_tab         receivable_slips_ttype;
--
    -- *** ���[�J���ϐ� ***
    lt_deduction_amt_sum           xxcok_sales_deduction.deduction_amount%TYPE;      -- �T���z���v
    lt_deduction_tax_amt_sum       xxcok_sales_deduction.deduction_tax_amount%TYPE;  -- �T���Ŋz���v
    lt_deduction_amt_sum_calc      xxcok_sales_deduction.deduction_amount%TYPE;      -- �T���z���v(�v�Z�p)
    lt_deduction_tax_amt_sum_calc  xxcok_sales_deduction.deduction_tax_amount%TYPE;  -- �T���Ŋz���v(�v�Z�p)
    lt_receivable_num_1            xx03_receivable_slips.receivable_num%TYPE;        -- A-4�Ŏ擾����AR������́i�������j1���R�[�h�ڂ̓`�[�ԍ�
    lt_line_number_1               xx03_receivable_slips_line.line_number%TYPE;      -- A-4�Ŏ擾����AR������́i�������j1���R�[�h�ڂ̖��הԍ�
    ln_difference_amt              NUMBER  DEFAULT NULL;                             -- ���z
    ln_difference_tax_amt          NUMBER  DEFAULT NULL;                             -- �ō��z
    ln_derivation_month            NUMBER  DEFAULT NULL;                             -- �v������o�p�̌�
    ln_derivation_date             NUMBER  DEFAULT NULL;                             -- �v������o�p�̓�
    ld_derivation_record_date      DATE    DEFAULT NULL;                             -- �v������o���W�b�N�œ��o�������t
    lb_derivation_err_flg          BOOLEAN DEFAULT FALSE;                            -- �v������o�t���O �G���[�̏ꍇ�ATRUE
    --
  BEGIN
    --
    --##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  �Œ蕔 END   ############################
    --
    -- AR������͖��ׂ̃��b�N�擾
    OPEN  receivable_slips_lock_cur;
    FETCH receivable_slips_lock_cur INTO receivable_slips_line_lock_rec;
    CLOSE receivable_slips_lock_cur;
    --
    -- AR������́i�������j�̃L�[���
    <<receivable_slips_key_loop>>
    FOR lt_receivable_slips_key_rec IN receivable_slips_key_cur LOOP
      --
      -- ==============================
      -- A-3.�̔��T�����i�������j�擾
      -- ==============================
      --
      -- �ϐ��̏�����
      lt_deduction_amt_sum          := NULL;
      lt_deduction_tax_amt_sum      := NULL;
      lt_deduction_amt_sum_calc     := NULL;
      lt_deduction_tax_amt_sum_calc := NULL;
      lt_receivable_num_1           := NULL;
      lt_line_number_1              := NULL;
      ln_derivation_month           := NULL;
      ln_derivation_date            := NULL;
      ld_derivation_record_date     := NULL;
      --
      -- �Ώیv������o
      IF ( lt_receivable_slips_key_rec.terms_name = '00_00_00' ) THEN
      -- �x�����������u00_00_00�v�̏ꍇ�AA-2�Ŏ擾�������������t��Ώیv����Ƃ���B
        ld_derivation_record_date := lt_receivable_slips_key_rec.invoice_date;
      ELSE
        BEGIN
          ln_derivation_month := TO_NUMBER( SUBSTR( lt_receivable_slips_key_rec.terms_name, 7, 2 ) );
          ln_derivation_date  := TO_NUMBER( SUBSTR( lt_receivable_slips_key_rec.terms_name, 1, 2 ) );
        EXCEPTION
          WHEN VALUE_ERROR THEN
          ld_derivation_record_date := NULL;
          lb_derivation_err_flg     := TRUE;
        END;
        --
        IF ( lb_derivation_err_flg = FALSE ) THEN
          -- �����\�������1�Ŏ擾�����������Z����B
          ld_derivation_record_date := ADD_MONTHS( lt_receivable_slips_key_rec.payment_scheduled_date, -ln_derivation_month );
          --
          IF ( ln_derivation_date = 30 ) THEN
            -- ����30�̏ꍇ�A���Z���������\����̌�������ݒ肷��B
            ld_derivation_record_date := TRUNC( LAST_DAY( ld_derivation_record_date ) );
          ELSE
            -- ����30�ȊO�̏ꍇ�A���Z���������\�����2�Ŏ擾��������ݒ肷��B
            ld_derivation_record_date := TO_DATE( TO_CHAR( ld_derivation_record_date, cv_year_format )
                                                  || TO_CHAR( ld_derivation_record_date, cv_month_format )
-- Ver1.1 Mod Start
--                                                  || SUBSTR( lt_receivable_slips_key_rec.terms_name, 1, 2 ) , cv_date_format );
                                                  || SUBSTR( lt_receivable_slips_key_rec.terms_name, 1, 2 ) , cv_date_format2 );
-- Ver1.1 Mod End
          END IF;
        END IF;
      END IF;
      --
      -- �Ώیv������o����
      IF ( lb_derivation_err_flg = FALSE ) THEN
        -- �̔��T�����̃��b�N�擾
        BEGIN
          OPEN  sales_deduction_lock_cur(
              in_account_number         => lt_receivable_slips_key_rec.account_number
             ,iv_slip_line_type_name    => lt_receivable_slips_key_rec.slip_line_type_name
             ,id_derivation_record_date => ld_derivation_record_date
            );
          CLOSE sales_deduction_lock_cur;
        EXCEPTION
          -- ���b�N�G���[
          WHEN global_lock_failure_expt THEN
            IF ( sales_deduction_lock_cur%ISOPEN ) THEN
              CLOSE sales_deduction_lock_cur;
            END IF;
            --
            -- ���b�N�G���[���b�Z�[�W
            lv_errmsg      := xxccp_common_pkg.get_msg( iv_application   => cv_appl_short_name_xxcok
                                                       ,iv_name          => cv_msg_cok_10732
                                                       ,iv_token_name1   => cv_tkn_table
                                                       ,iv_token_value1  => ct_msg_cok_10855            -- ������u�̔��T�����v
                                                       );
            lv_errbuf      := lv_errmsg;
            ov_errmsg      := lv_errmsg;
            ov_errbuf      := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
            RAISE global_api_expt;
        END;
        --
        BEGIN
          SELECT /*+ USE_INVISIBLE_INDEXES INDEX(xxcok_sales_deduction_n10) */
             SUM(xsd.deduction_amount)     AS deduction_amount             -- �T���z���v
            ,SUM(xsd.deduction_tax_amount) AS deduction_tax_amount         -- �T���Ŋz���v
          INTO
             lt_deduction_amt_sum
            ,lt_deduction_tax_amt_sum
          FROM    xxcok_sales_deduction xsd                                -- �̔��T�����
          WHERE
          xsd.recon_slip_num IS NULL                                                         -- �x���`�[�ԍ�
          AND xsd.status = cv_flag_n                                                         -- �X�e�[�^�X:N(�V�K)
          AND xsd.customer_code_from IN ( SELECT ship_account_number AS ship_account_number  -- �U�֌��ڋq�R�[�h
                                          FROM   xxcfr_cust_hierarchy_v xchv
                                          WHERE  xchv.cash_account_number = lt_receivable_slips_key_rec.account_number
                                          OR     xchv.bill_account_number = lt_receivable_slips_key_rec.account_number
                                          OR     xchv.ship_account_number = lt_receivable_slips_key_rec.account_number )
          AND xsd.data_type          IN ( SELECT flv.lookup_code AS code                     -- �f�[�^���
                                          FROM   fnd_lookup_values flv
                                          WHERE  flv.lookup_type  = ct_deduction_data_type
                                          AND    flv.language     = cv_lang
                                          AND    flv.enabled_flag = cv_flag_yes
                                          AND    flv.attribute14  = lt_receivable_slips_key_rec.slip_line_type_name )
          AND xsd.record_date <= ld_derivation_record_date                                     -- �Ώیv������o���W�b�N�œ��o�������t
          AND xsd.source_category <> cv_flag_d                                                 -- �쐬���敪 <> D:���z����
-- Ver1.1 Mod Start
--          AND ( ( xsd.source_category = cv_flag_v AND xsd.report_decision_flag = cv_flag_on )  -- ( �쐬���敪 = V:������ѐU�ցi�U�֊����jAND ����m��t���O:1(���ѐU�֊m��ς�)
--                OR                                                                             --   OR
--                ( xsd.source_category <> cv_flag_v AND xsd.report_decision_flag IS NULL ) )    --   �쐬���敪 <> V:������ѐU�ցi�U�֊����jAND ����m��t���O IS NULL )
          AND ( xsd.report_decision_flag = cv_flag_on OR xsd.report_decision_flag IS NULL )    -- ����m��t���O:1(���ѐU�֊m��ς�)�܂���NULL
-- Ver1.1 Mod End
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            lt_deduction_amt_sum := NULL;
            lt_deduction_tax_amt_sum := NULL;
        END;
      --
      END IF;
      --
      -- ======================================
      -- A-4.AR������́i�������j�̖��׏��擾
      -- ======================================
      --
      OPEN  receivable_slips_cur( lt_receivable_slips_key_rec.customer_id
                                 ,lt_receivable_slips_key_rec.invoice_date
                                 ,lt_receivable_slips_key_rec.payment_scheduled_date
                                 ,lt_receivable_slips_key_rec.terms_name
                                 ,lt_receivable_slips_key_rec.slip_line_type_name
                                 ,gd_standard_date
                                 ,gd_before_month_last_date
                                 );
      FETCH receivable_slips_cur BULK COLLECT INTO receivable_slips_tab;
      CLOSE receivable_slips_cur;
      -- 
      -- ��������
      gn_target_cnt := gn_target_cnt + receivable_slips_tab.COUNT;
      --
      -- A-3�Ŏ擾�����T���z���v��NULL�̏ꍇ�AA-4-1�Ŏ擾�������ו��̌x�����b�Z�[�W���o�͂��A�������X�L�b�v���܂��B
      IF ( lt_deduction_amt_sum IS NULL AND lb_derivation_err_flg = FALSE ) THEN
        FOR i IN 1..receivable_slips_tab.COUNT LOOP
          -- �X�L�b�v����
          gn_warn_cnt := gn_warn_cnt + cn_number_one;
          --
          lv_errmsg   := xxccp_common_pkg.get_msg( iv_application   => cv_appl_short_name_xxcok
                                       ,iv_name          => cv_msg_cok_10857
                                       ,iv_token_name1   => cv_tkn_receivable_num
                                       ,iv_token_value1  => receivable_slips_tab(i).receivable_num
                                       ,iv_token_name2   => cv_tkn_line_number
                                       ,iv_token_value2  => receivable_slips_tab(i).line_number
                                      );
          lv_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errbuf
          );
        END LOOP;
        CONTINUE;
      END IF;
      -- A-3�̑Ώیv������o���W�b�N�Ŏx�����������z��O�̏ꍇ�AA-4-1�Ŏ擾�������ו��̌x�����b�Z�[�W���o�͂��A�������X�L�b�v���܂��B
      IF ( lb_derivation_err_flg = TRUE ) THEN
        FOR i IN 1..receivable_slips_tab.COUNT LOOP
          -- �X�L�b�v����
          gn_warn_cnt := gn_warn_cnt + cn_number_one;
          --
          lv_errmsg   := xxccp_common_pkg.get_msg( iv_application   => cv_appl_short_name_xxcok
                                       ,iv_name          => cv_msg_cok_10858
                                       ,iv_token_name1   => cv_tkn_receivable_num
                                       ,iv_token_value1  => receivable_slips_tab(i).receivable_num
                                       ,iv_token_name2   => cv_tkn_line_number
                                       ,iv_token_value2  => receivable_slips_tab(i).line_number
                                       ,iv_token_name3   => cv_tkn_terms_name
                                       ,iv_token_value3  => lt_receivable_slips_key_rec.terms_name
                                      );
          lv_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errbuf
          );
        END LOOP;
        CONTINUE;
      END IF;
      --
      -- �T���z���v(�v�Z�p)�A�T���Ŋz���v(�v�Z�p)�̒l��������
      lt_deduction_amt_sum_calc     := lt_deduction_amt_sum;
      lt_deduction_tax_amt_sum_calc := lt_deduction_tax_amt_sum;
      --
      FOR i IN 1..receivable_slips_tab.COUNT LOOP
        -- �ϐ��̏�����
        ln_difference_amt          := NULL;
        ln_difference_tax_amt      := NULL;
        --
        IF i = 1 THEN
        -- 1���R�[�h�ڂ̓`�[�ԍ��A���הԍ���ێ�
          lt_receivable_num_1 := receivable_slips_tab(i).receivable_num;
          lt_line_number_1    := receivable_slips_tab(i).line_number;
        END IF;
        -- �Q���R�[�h�ڂ���͍T���z���v�A�T���Ŋz���v��0�~�ɐݒ肷��
        IF i > 1 THEN
          lt_deduction_amt_sum     := cn_number_zero;
          lt_deduction_tax_amt_sum := cn_number_zero;
        END IF;
        --
        -- AR������͖��׋��z�Ɣ̔��T���f�[�^�̍T���z�̍��z���v�Z
        ln_difference_amt     := lt_deduction_amt_sum + receivable_slips_tab(i).entered_item_amount;
        ln_difference_tax_amt := lt_deduction_tax_amt_sum + receivable_slips_tab(i).entered_tax_amount;
        --
        -- �T���������׏��(AR�������E)�e�[�u���Ƀ��R�[�h��o�^
        INSERT INTO xxcok_deduction_recon_line_ar(
           deduction_recon_line_id      -- �T����������ID
          ,recon_slip_num               -- �������E�`�[�ԍ�
          ,deduction_line_num           -- �������הԍ�
          ,recon_line_status            -- ���̓X�e�[�^�X
          ,cust_code                    -- �ڋq�R�[�h
          ,memo_line_name               -- �������e
          ,tax_code                     -- �ŃR�[�h
          ,deduction_amt                -- �T���z(�Ŕ�)
          ,deduction_tax                -- �T���z(�����)
          ,payment_amt                  -- �x���z(�Ŕ�)
          ,payment_tax                  -- �x���z(�����)
          ,difference_amt               -- �������z(�Ŕ�)
          ,difference_tax               -- �������z(�����)
          ,created_by                   -- �쐬��
          ,creation_date                -- �쐬��
          ,last_updated_by              -- �ŏI�X�V��
          ,last_update_date             -- �ŏI�X�V��
          ,last_update_login            -- �ŏI�X�V���O�C��
          ,request_id                   -- �v��ID
          ,program_application_id       -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          ,program_id                   -- �R���J�����g�E�v���O����ID
          ,program_update_date          -- �v���O�����X�V��
        )
        VALUES(
          xxcok_dedu_recon_ar_s01.NEXTVAL
         ,receivable_slips_tab(i).receivable_num || '-' || receivable_slips_tab(i).line_number
         ,cn_number_one
         ,'ED'
         ,lt_receivable_slips_key_rec.account_number
         ,receivable_slips_tab(i).slip_line_type_name
         ,receivable_slips_tab(i).tax_code
         ,lt_deduction_amt_sum
         ,lt_deduction_tax_amt_sum
         ,receivable_slips_tab(i).entered_item_amount
         ,receivable_slips_tab(i).entered_tax_amount
         ,ln_difference_amt
         ,ln_difference_tax_amt
         ,cn_created_by                                  -- created_by
         ,cd_creation_date                               -- creation_date
         ,cn_last_updated_by                             -- last_updated_by
         ,cd_last_update_date                            -- last_update_date
         ,cn_last_update_login                           -- last_update_login
         ,cn_request_id                                  -- request_id
         ,cn_program_application_id                      -- program_application_id
         ,cn_program_id                                  -- program_id
         ,cd_program_update_date                         -- program_update_date
        );
        -- ���z����̏ꍇ
        IF ( ln_difference_amt != 0 OR ln_difference_tax_amt != 0 ) THEN
          --
          -- ==========================
          -- A-5.���z�����T���f�[�^�o�^
          -- ==========================
          ins_sales_deduction(
             in_account_number         => lt_receivable_slips_key_rec.account_number        -- �ڋq�R�[�h
            ,iv_slip_line_type_name    => lt_receivable_slips_key_rec.slip_line_type_name   -- �������E�����p�������e
            ,in_deduction_amt_sum      => lt_deduction_amt_sum_calc                         -- �T���z���v(�v�Z�p)
            ,in_deduction_tax_amt_sum  => lt_deduction_tax_amt_sum_calc                     -- �T���Ŋz���v(�v�Z�p)
            ,id_derivation_record_date => ld_derivation_record_date                         -- �Ώیv������o���W�b�N�œ��o�������t
            ,iv_receivable_num         => receivable_slips_tab(i).receivable_num            -- �Ώۃ��R�[�h�̓`�[�ԍ�
            ,iv_line_number            => receivable_slips_tab(i).line_number               -- �Ώۃ��R�[�h�̖��הԍ�
            ,iv_receivable_num_1       => lt_receivable_num_1                               -- 1���R�[�h�ڂ̓`�[�ԍ�
            ,iv_line_number_1          => lt_line_number_1                                  -- 1���R�[�h�ڂ̖��הԍ�
            ,ln_difference_amt         => -1 * ln_difference_amt                            -- ���z
            ,ln_difference_tax_amt     => -1 * ln_difference_tax_amt                        -- �ō��z
            ,ov_errbuf                 => lv_errbuf                                         -- �G���[�E���b�Z�[�W           --# �Œ� #
            ,ov_retcode                => lv_retcode                                        -- ���^�[���E�R�[�h             --# �Œ� #
            ,ov_errmsg                 => lv_errmsg                                         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          IF ( lv_retcode <> cv_status_normal ) THEN
             RAISE global_process_expt;
               --
          END IF;
        END IF;
        --
        -- ===================
        -- A-6  AR������͍X�V
        -- ===================
        UPDATE xx03_receivable_slips_line xrsl
        SET    xrsl.attribute8               = cv_flag_y                        -- �������E���������t���O
              ,xrsl.last_updated_by          = cn_last_updated_by               -- �ŏI�X�V��
              ,xrsl.last_update_date         = cd_last_update_date              -- �ŏI�X�V��
              ,xrsl.last_update_login        = cn_last_update_login             -- �ŏI�X�V���O�C��
              ,xrsl.request_id               = cn_request_id                    -- �v��ID
              ,xrsl.program_application_id   = cn_program_application_id        -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
              ,xrsl.program_id               = cn_program_id                    -- �R���J�����g�E�v���O����ID
              ,xrsl.program_update_date      = cd_program_update_date           -- �v���O�����X�V��
        WHERE  xrsl.receivable_line_id       = receivable_slips_tab(i).receivable_line_id
        ;
        -- AR������͖��׍X�V�̍X�V����
        gn_normal_cnt := gn_normal_cnt + SQL%ROWCOUNT;
--
        -- =======================
        -- A-7  �̔��T���f�[�^�X�V
        -- =======================
        UPDATE /*+ USE_INVISIBLE_INDEXES INDEX(xxcok_sales_deduction_n10) */
               xxcok_sales_deduction xsd
        SET    xsd.recon_slip_num          = receivable_slips_tab(i).receivable_num || '-' || receivable_slips_tab(i).line_number  -- �x���`�[�ԍ�
              ,xsd.carry_payment_slip_num  = receivable_slips_tab(i).receivable_num || '-' || receivable_slips_tab(i).line_number  -- �J�z���x���`�[�ԍ�
              ,xsd.last_updated_by         = cn_last_updated_by                             -- �ŏI�X�V��
              ,xsd.last_update_date        = cd_last_update_date                            -- �ŏI�X�V��
              ,xsd.last_update_login       = cn_last_update_login                           -- �ŏI�X�V���O�C��
              ,xsd.request_id              = cn_request_id                                  -- �v��ID
              ,xsd.program_application_id  = cn_program_application_id                      -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
              ,xsd.program_id              = cn_program_id                                  -- �R���J�����g�E�v���O����ID
              ,xsd.program_update_date     = cd_program_update_date                         -- �v���O�����X�V��
        WHERE  xsd.recon_slip_num IS NULL                                                   -- �x���`�[�ԍ�
        AND  xsd.status = cv_flag_n                                                         -- �X�e�[�^�X:N(�V�K)
        AND  xsd.customer_code_from IN ( SELECT ship_account_number AS ship_account_number  -- �U�֌��ڋq�R�[�h
                                         FROM   xxcfr_cust_hierarchy_v xchv
                                         WHERE  xchv.cash_account_number = lt_receivable_slips_key_rec.account_number
                                         OR     xchv.bill_account_number = lt_receivable_slips_key_rec.account_number
                                         OR     xchv.ship_account_number = lt_receivable_slips_key_rec.account_number )
        AND  xsd.data_type          IN ( SELECT flv.lookup_code AS code                     -- �f�[�^���
                                         FROM   fnd_lookup_values flv
                                         WHERE  flv.lookup_type  = ct_deduction_data_type
                                         AND    flv.language     = cv_lang
                                         AND    flv.enabled_flag = cv_flag_yes
                                         AND    flv.attribute14  = lt_receivable_slips_key_rec.slip_line_type_name )
        AND  xsd.record_date <= ld_derivation_record_date                                     -- �Ώیv������o���W�b�N�œ��o�������t
        AND  xsd.source_category <> cv_flag_d                                                 -- �쐬���敪 <> D:���z����
-- Ver1.1 Mod Start
--        AND  ( ( xsd.source_category = cv_flag_v AND xsd.report_decision_flag = cv_flag_on )  -- ( �쐬���敪 = V:������ѐU�ցi�U�֊����jAND ����m��t���O:1(���ѐU�֊m��ς�)
--               OR                                                                             --   OR
--               ( xsd.source_category <> cv_flag_v AND xsd.report_decision_flag IS NULL ) )    --   �쐬���敪 <> V:������ѐU�ցi�U�֊����jAND ����m��t���O IS NULL )
        AND ( xsd.report_decision_flag = cv_flag_on OR xsd.report_decision_flag IS NULL )     -- ����m��t���O:1(���ѐU�֊m��ς�)�܂���NULL
-- Ver1.1 Mod End
        ;
        -- ==========================
        --A-8  �T�������w�b�_���쐬
        -- ==========================
        INSERT INTO xxcok_deduction_recon_head(
           deduction_recon_head_id      -- �T�������w�b�_�[ID
          ,recon_base_code              -- �x���������_
          ,recon_slip_num               -- �x���`�[�ԍ�
          ,recon_status                 -- �����X�e�[�^�X
          ,application_date             -- �\����
          ,approval_date                -- ���F��
          ,cancellation_date            -- �����
          ,recon_due_date               -- �x���\���
          ,gl_date                      -- GL�L����
          ,cancel_gl_date               -- ���GL�L����
          ,target_date_end              -- �Ώۊ���(TO)
          ,interface_div                -- �A�g��
          ,payee_code                   -- �x����R�[�h
          ,corp_code                    -- ��ƃR�[�h
          ,deduction_chain_code         -- �T���p�`�F�[���R�[�h
          ,cust_code                    -- �ڋq�R�[�h
          ,condition_no                 -- �T���ԍ�
          ,invoice_number               -- �≮�������ԍ�
          ,target_data_type             -- �Ώۃf�[�^���
          ,applicant                    -- �\����
          ,approver                     -- ���F��
          ,ap_ar_if_flag                -- AP/AR�A�g�t���O
          ,gl_if_flag                   -- ����GL�A�g�t���O
          ,terms_name                   -- �x������
          ,invoice_date                 -- ���������t
          ,created_by                   -- �쐬��
          ,creation_date                -- �쐬��
          ,last_updated_by              -- �ŏI�X�V��
          ,last_update_date             -- �ŏI�X�V��
          ,last_update_login            -- �ŏI�X�V���O�C��
          ,request_id                   -- �v��ID
          ,program_application_id       -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          ,program_id                   -- �R���J�����g�E�v���O����ID
          ,program_update_date          -- �v���O�����X�V��
        )
        VALUES(
           xxcok_deduction_recon_head_s01.NEXTVAL
          ,receivable_slips_tab(i).entry_department
          ,receivable_slips_tab(i).receivable_num || '-' || receivable_slips_tab(i).line_number
          ,'AD'
          ,receivable_slips_tab(i).request_date
          ,receivable_slips_tab(i).approval_date
          ,NULL
          ,lt_receivable_slips_key_rec.payment_scheduled_date
          ,gd_before_month_last_date
          ,NULL
          ,ld_derivation_record_date
          ,'AR'
          ,lt_receivable_slips_key_rec.account_number
          ,NULL
          ,NULL
          ,NULL
          ,NULL
          ,NULL
          ,NULL
          ,receivable_slips_tab(i).requestor_person_id
          ,receivable_slips_tab(i).approver_person_id
          ,NULL
          ,'N'
          ,lt_receivable_slips_key_rec.terms_name
          ,lt_receivable_slips_key_rec.invoice_date
          ,cn_created_by                                  -- created_by
          ,cd_creation_date                               -- creation_date
          ,cn_last_updated_by                             -- last_updated_by
          ,cd_last_update_date                            -- last_update_date
          ,cn_last_update_login                           -- last_update_login
          ,cn_request_id                                  -- request_id
          ,cn_program_application_id                      -- program_application_id
          ,cn_program_id                                  -- program_id
          ,cd_program_update_date                         -- program_update_date
        ); 
        --
      END LOOP;
    END LOOP receivable_slips_key_loop;
    --
  EXCEPTION
  --
    -- ���b�N�G���[
    WHEN global_lock_failure_expt THEN
      IF ( receivable_slips_lock_cur%ISOPEN ) THEN
        CLOSE receivable_slips_lock_cur;
      END IF;
--
      -- ���b�N�G���[���b�Z�[�W
      lv_errmsg      := xxccp_common_pkg.get_msg( iv_application   => cv_appl_short_name_xxcok
                                                 ,iv_name          => cv_msg_cok_10732
                                                 ,iv_token_name1   => cv_tkn_table
                                                 ,iv_token_value1  => ct_msg_cok_10856            -- ������uAR������͖��ׁv
                                                 );
      lv_errbuf      := lv_errmsg;
      ov_errmsg      := lv_errmsg;
      ov_errbuf      := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode     := cv_status_error;
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** ���ʊ֐���O�n���h�� ***
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END get_receivable_slips_key;
  --
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   ***********************************************************************************/
  PROCEDURE submain(
     ov_errbuf  OUT NOCOPY VARCHAR2 -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode OUT NOCOPY VARCHAR2 -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg  OUT NOCOPY VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������
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
  BEGIN
    --
    --##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  �Œ蕔 END   ############################
    --
    -- ============
    -- A-1.��������
    -- ============
    init(
       ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode => lv_retcode -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
      --
    END IF;
    --
    -- ======================================
    -- A-2.AR������́i�������j�̃L�[���擾
    -- ======================================
    get_receivable_slips_key(
       ov_errbuf                 => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode                => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg                 => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    --
    END IF;
    --
    IF ( gn_warn_cnt > cn_number_zero ) THEN
      ov_retcode := cv_status_warn;
      --
    END IF;
    --
    COMMIT;
    --
  EXCEPTION
 --
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
--
--####################################  �Œ蕔 END   ##########################################
--
  END submain;
--
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : ���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
  --
  PROCEDURE main(
     errbuf  OUT NOCOPY VARCHAR2 -- �G���[�E���b�Z�[�W --# �Œ� #
    ,retcode OUT NOCOPY VARCHAR2 -- ���^�[���E�R�[�h   --# �Œ� #
  )
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
    lv_errbuf       VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code VARCHAR2(100);   -- �I�����b�Z�[�W�R�[�h
    --
    --###########################  �Œ蕔 END   ####################################
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- �g�[�N���p�萔
    --
    -- *** ���[�J���ϐ� ***
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
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
      --
    END IF;
    --
    --###########################  �Œ蕔 END   #############################
    --
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode => lv_retcode -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
       -- �G���[�o��
       fnd_file.put_line(
          which  => fnd_file.output
         ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
       );
       --
       fnd_file.put_line(
          which  => fnd_file.log
         ,buff   => cv_pkg_name || cv_msg_cont ||
                    cv_prg_name || cv_msg_part ||
                    lv_errbuf --�G���[���b�Z�[�W
       );
       --
    END IF;
    --
    -- =======================
    -- A-6.�I������
    -- =======================
    -- ��s�̏o��
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => ''
    );
    --
    --�G���[�̏ꍇ�A���������A���������A�X�L�b�v�����N���A�A�G���[�����Œ�
    IF ( lv_retcode = cv_status_error ) THEN
      gn_target_cnt := cn_number_zero;
      gn_normal_cnt := cn_number_zero;
      gn_error_cnt  := cn_number_one;
      gn_warn_cnt   := cn_number_zero;
    END IF;
    --
    -- �Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_target_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_target_cnt )
                  );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    -- ���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_success_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_normal_cnt )
                  );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    -- �X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_skip_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_warn_cnt )
                  );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    -- �G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_error_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_error_cnt )
                  );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --
    -- �I�����b�Z�[�W
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application => cv_appl_short_name
                    ,iv_name        => lv_message_code
                  );
    --
    fnd_file.put_line(
       which => fnd_file.output
      ,buff  => gv_out_msg
    );
    --
    -- �X�e�[�^�X�Z�b�g
    errbuf  := lv_errbuf;
    retcode := lv_retcode;
    -- �I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
    --
  EXCEPTION
    --
    --###########################  �Œ蕔 START   #####################################################
    --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM || lv_errbuf;
      retcode := cv_status_error;
      ROLLBACK;
      --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
      --
  END main;
  --
  --###########################  �Œ蕔 END   #######################################################
  --
END XXCOK024A42C;
/
