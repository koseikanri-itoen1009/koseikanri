CREATE OR REPLACE PACKAGE BODY APPS.XXCOK024A44C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2022. All rights reserved.
 *
 * Package Name     : XXCOK024A44C (body)
 * Description      : �T�����쐬�������E�`�[CSV�o��
 * MD.050           : �T�����쐬�������E�`�[CSV�o�� MD050_COK_024_A44
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  get_receivable_slips   AR������͏��(������)�f�[�^���o(A-2)
 *  chk_sales_deduction    �̔��T�����i�������j�m�F(A-3)
 *  output_data            �f�[�^�o��(A-4)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2022/10/21    1.0   R.Oikawa         main�V�K�쐬
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; -- ����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   -- �x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  -- �ُ�:2
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg                VARCHAR2(2000)  DEFAULT NULL;
  gv_sep_msg                VARCHAR2(2000)  DEFAULT NULL;
  gv_exec_user              VARCHAR2(100)   DEFAULT NULL;
  gv_conc_name              VARCHAR2(30)    DEFAULT NULL;
  gv_conc_status            VARCHAR2(30)    DEFAULT NULL;
  gn_target_cnt             NUMBER          DEFAULT NULL;    -- �Ώی���
  gn_normal_cnt             NUMBER          DEFAULT NULL;    -- ���팏��
  gn_error_cnt              NUMBER          DEFAULT NULL;    -- �G���[����
--
--################################  �Œ蕔 END   ##################################
--
--##########################  �Œ苤�ʗ�O�錾�� START  ###########################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
  --*** ���ʊ֐��x����O ***
  global_api_warn_expt      EXCEPTION;
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
  --*** �o�͓� ���t�t�]�`�F�b�N��O ***
  global_date_rever_old_chk_expt    EXCEPTION;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  --
  cv_pkg_name                 CONSTANT  VARCHAR2(100) := 'XXCOK024A44C';            -- �p�b�P�[�W��
  cv_xxcok_short_name         CONSTANT  VARCHAR2(100) := 'XXCOK';                   -- �̕��̈�Z�k�A�v����
  --
  cv_delimit                  CONSTANT  VARCHAR2(4)   := ',';                       -- ��؂蕶��
  cv_null                     CONSTANT  VARCHAR2(4)   := '';                        -- �󕶎�
  cv_half_space               CONSTANT  VARCHAR2(4)   := ' ';                       -- �X�y�[�X
  cv_full_space               CONSTANT  VARCHAR2(4)   := '�@';                      -- �S�p�X�y�[�X
  cv_const_y                  CONSTANT  VARCHAR2(1)   := 'Y';                       -- 'Y'
  cv_const_n                  CONSTANT  VARCHAR2(1)   := 'N';                       -- 'N'
  cv_perc                     CONSTANT  VARCHAR2(1)   := '%';                       -- '%'
  cv_lang                     CONSTANT  VARCHAR2(100) := USERENV( 'LANG' );         -- ����
  -- ���l
  cn_zero                     CONSTANT  NUMBER        := 0;                         -- 0
  cn_one                      CONSTANT  NUMBER        := 1;                         -- 1
  -- �t���O
  cv_flag_off                 CONSTANT VARCHAR2(1)    := '0';                       -- �t���OOFF
  cv_flag_on                  CONSTANT VARCHAR2(1)    := '1';                       -- �t���OON
  cv_flag_d                   CONSTANT VARCHAR2(1)    := 'D';                       -- �쐬���敪(���z����)
  cv_flag_u                   CONSTANT VARCHAR2(1)    := 'U';                       -- �쐬���敪(�A�b�v���[�h)
  cv_flag_v                   CONSTANT VARCHAR2(1)    := 'V';                       -- �쐬���敪 ������ѐU�ցi�U�֊����j
  -- �����}�X�N
  cv_date_format              CONSTANT  VARCHAR2(10)  := 'YYYY/MM/DD';              -- ���t����
  cv_date_format_time         CONSTANT  VARCHAR2(30)  := 'YYYY/MM/DD HH24:MI:SS';   -- ���t����(����)
  cv_year_format              CONSTANT  VARCHAR2(10)  := 'YYYY';                    -- ���t����(�N)
  cv_month_format             CONSTANT  VARCHAR2(10)  := 'MM';                      -- ���t����(��)
  --�v���t�@�C��
  cv_prof_trx_type            CONSTANT  fnd_profile_options.profile_option_name%TYPE := 'XXCOK1_RA_TRX_TYPE_VARIABLE_CONS';     -- ����^�C�v_�ϓ��Ή����E
  -- �Q�ƃ^�C�v
  cv_type_header              CONSTANT  fnd_lookup_values.lookup_type%TYPE  := 'XXCOK1_RECEIVABLE_SLIPS_HEAD';  -- �T�����쐬�������E�`�[�p���o��
  cv_type_dec_pri_base        CONSTANT  fnd_lookup_values.lookup_type%TYPE  := 'XXCOK1_DEC_PRIVILEGE_BASE';     -- �T���}�X�^�������_
  cv_type_deduction_data      CONSTANT  fnd_lookup_values.lookup_type%TYPE  := 'XXCOK1_DEDUCTION_DATA_TYPE';    -- �T���f�[�^���
  cv_type_slip_types          CONSTANT  fnd_lookup_values.lookup_type%TYPE  := 'XX03_SLIP_TYPES';               -- �`�[���
  cv_type_wf_statuses         CONSTANT  fnd_lookup_values.lookup_type%TYPE  := 'XX03_WF_STATUSES';              -- �X�e�[�^�X
  -- �Q�ƃ^�C�v�R�[�h
  cv_code_eoh_024a44          CONSTANT  fnd_lookup_values.lookup_code%TYPE  := '024A44%';                       -- �N�C�b�N�R�[�h�i�T�����쐬�������E�`�[�p���o���j
  --���b�Z�[�W
  cv_msg_date_rever_err       CONSTANT  VARCHAR2(100) := 'APP-XXCOK1-10651';              -- ���t�t�]�G���[
  cv_msg_parameter            CONSTANT  VARCHAR2(100) := 'APP-XXCOK1-10859';              -- �p�����[�^�o�̓��b�Z�[�W
  cv_msg_proc_date_err        CONSTANT  VARCHAR2(100) := 'APP-XXCOK1-00028';              -- �Ɩ����t�擾�G���[���b�Z�[�W
  cv_msg_user_id_err          CONSTANT  VARCHAR2(100) := 'APP-XXCOK1-10594';              -- ���[�U�[ID�擾�G���[���b�Z�[�W
  cv_msg_user_base_code_err   CONSTANT  VARCHAR2(100) := 'APP-XXCOK1-00012';              -- �������_�R�[�h�擾�G���[���b�Z�[�W
  cv_msg_no_data_err          CONSTANT  VARCHAR2(100) := 'APP-XXCOK1-00001';              -- �Ώۃf�[�^�Ȃ��G���[���b�Z�[�W
  cv_msg_profile_err          CONSTANT  VARCHAR2(100) := 'APP-XXCOK1-00003';              -- �v���t�@�C���擾�G���[���b�Z�[�W
  --�g�[�N����
  cv_tkn_nm_rec_date_from     CONSTANT  VARCHAR2(100) := 'RECORD_DATE_FROM';              -- �v����iFROM�j
  cv_tkn_nm_rec_date_to       CONSTANT  VARCHAR2(100) := 'RECORD_DATE_TO';                -- �v����iTO�j
  cv_tkn_nm_cust_code         CONSTANT  VARCHAR2(100) := 'CUST_CODE';                     -- �ڋq
  cv_tkn_nm_base_code         CONSTANT  VARCHAR2(100) := 'BASE_CODE';                     -- �N�[����
  cv_tkn_nm_user_name         CONSTANT  VARCHAR2(100) := 'USER_NAME';                     -- ���͎�
  cv_tkn_nm_slip_line_type    CONSTANT  VARCHAR2(100) := 'SLIP_LINE_TYPE_NAME';           -- �������e
  cv_tkn_nm_payment_date      CONSTANT  VARCHAR2(100) := 'PAYMENT_SCHEDULED_DATE';        -- �����\���
  cv_tkn_nm_user_id           CONSTANT  VARCHAR2(100) := 'USER_ID';                       -- ���[�U�[ID
  cv_tkn_nm_profile           CONSTANT  VARCHAR2(100) := 'PROFILE';                       -- �v���t�@�C��
  --�x������
  cv_terms_name_00_00_00      CONSTANT  VARCHAR2(100) := '00_00_00';
  --������
  cv_last_day_30              CONSTANT  NUMBER        := 30;
  --
  cv_slip_type_80300          CONSTANT  VARCHAR2(5)   := '80300';                         -- �`�[���:�������E
  cv_ar_status_appr           CONSTANT  VARCHAR2(2)   := '80';                            -- ���F��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_process_date           DATE                                                DEFAULT NULL; -- �Ɩ����t
  gn_user_id                NUMBER                                              DEFAULT NULL; -- ���[�U�[ID
  gv_user_base_code         VARCHAR2(150)                                       DEFAULT NULL; -- �������_�R�[�h
  gv_privilege_flag         VARCHAR2(1)                                         DEFAULT NULL; -- �������[�U�[���f�t���O
  gd_record_date_from       DATE                                                DEFAULT NULL; -- �p�����[�^�F�v���(FROM)
  gd_record_date_to         DATE                                                DEFAULT NULL; -- �p�����[�^�F�v���(TO)
  gv_cust_code              hz_cust_accounts.account_number%TYPE                DEFAULT NULL; -- �p�����[�^�F�ڋq
  gv_base_code              xx03_receivable_slips.entry_department%TYPE         DEFAULT NULL; -- �p�����[�^�F�N�[����
  gv_user_name              per_all_people_f.full_name%TYPE                     DEFAULT NULL; -- �p�����[�^�F���͎�
  gv_slip_line_type_name    xx03_receivable_slips_line.slip_line_type_name%TYPE DEFAULT NULL; -- �p�����[�^�F�������e
  gd_payment_scheduled_date DATE                                                DEFAULT NULL; -- �p�����[�^�F�����\���
  gv_trans_type_name        xx03_receivable_slips.trans_type_name%TYPE          DEFAULT NULL; -- ����^�C�v
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���E�J�[�\��
  -- ===============================
  CURSOR get_receivable_slips_cur (
           id_record_date_from           IN DATE                                                 -- �v���(FROM)
          ,id_record_date_to             IN DATE                                                 -- �v���(TO)
          ,iv_cust_code                  IN hz_cust_accounts.account_number%TYPE                 -- �ڋq
          ,iv_base_code                  IN xx03_receivable_slips.entry_department%TYPE          -- �N�[����
          ,iv_user_name                  IN per_all_people_f.employee_number%TYPE                -- ���͎�
          ,iv_slip_line_type_name        IN xx03_receivable_slips_line.slip_line_type_name%TYPE  -- �������e
          ,id_payment_scheduled_date     IN DATE                                                 -- �����\���
          )
  IS
    SELECT    xrs.slip_type                 AS slip_type                       -- �`�[���
             ,flv.description               AS slip_type_name                  -- �`�[��ʖ���
             ,xrs.receivable_num            AS receivable_num                  -- �`�[�ԍ�
             ,xrs.wf_status                 AS wf_status                       -- �X�e�[�^�X
             ,flv2.meaning                  AS wf_status_name                  -- �X�e�[�^�X����
             ,xrs.entry_date                AS entry_date                      -- �N�[��
             ,xrs.requestor_person_name     AS requestor_person_name           -- �\���Җ�
             ,xrs.approver_person_name      AS approver_person_name            -- ���F�Җ�
             ,xrs.request_date              AS request_date                    -- �\����
             ,xrs.approval_date             AS approval_date                   -- ���F��
             ,xrs.rejection_date            AS rejection_date                  -- �۔F��
             ,xrs.account_approval_date     AS account_approval_date           -- �o�����F��
             ,xrs.ar_forward_date           AS ar_forward_date                 -- AR�]����
             ,xrs.approver_comments         AS approver_comments               -- ���F�R�����g
             ,xrs.invoice_date              AS invoice_date                    -- ���������t
             ,xrs.trans_type_name           AS trans_type_name                 -- ����^�C�v��
             ,hca.account_number            AS account_number                  -- �ڋq�R�[�h
             ,xrs.customer_name             AS customer_name                   -- �ڋq��
             ,xrs.customer_office_name      AS customer_office_name            -- �ڋq���Ə���
             ,xrs.receipt_method_name       AS receipt_method_name             -- �x�����@��
             ,xrs.terms_name                AS terms_name                      -- �x��������
             ,REPLACE( REPLACE( xrs.description, CHR(13), NULL)
                       ,CHR(10), NULL )     AS description                     -- ���l
             ,xrs.entry_department          AS entry_department                -- �N�[����
             ,ppv7.full_name                AS full_name                       -- �`�[���͎Җ�
             ,xrs.gl_date                   AS gl_date                         -- �v���
             ,xrs.payment_scheduled_date    AS payment_scheduled_date          -- �����\���
             ,xrsl.line_number              AS line_number                     -- ���הԍ�
             ,xrsl.slip_line_type_name      AS slip_line_type_name             -- �������e
             ,xrsl.slip_line_uom            AS slip_line_uom                   -- �P��
             ,xrsl.slip_line_unit_price     AS slip_line_unit_price            -- �P��
             ,xrsl.slip_line_quantity       AS slip_line_quantity              -- ����
             ,xrsl.slip_line_entered_amount AS slip_line_entered_amount        -- ���͋��z
             ,xrsl.tax_code                 AS tax_code                        -- �ŋ敪�R�[�h
             ,xrsl.tax_name                 AS tax_name                        -- �ŋ敪
             ,xrsl.entered_item_amount      AS entered_item_amount             -- �{�̋��z
             ,xrsl.entered_tax_amount       AS entered_tax_amount              -- ����Ŋz
             ,xrsl.slip_line_reciept_no     AS slip_line_reciept_no            -- �[�i���ԍ�
             ,REPLACE( REPLACE( xrsl.slip_description, CHR(13), NULL)
                       ,CHR(10), NULL )     AS slip_description                -- ���l�i���ׁj
             ,xrsl.segment1                 AS segment1                        -- ���
             ,xrsl.segment2                 AS segment2                        -- ����
             ,xrsl.segment3                 AS segment3                        -- ����Ȗ�
             ,xrsl.segment4                 AS segment4                        -- �⏕�Ȗ�
             ,xrsl.segment5                 AS segment5                        -- �����
             ,xrsl.segment6                 AS segment6                        -- ���Ƌ敪
             ,xrsl.segment7                 AS segment7                        -- �v���W�F�N�g
             ,xrsl.segment8                 AS segment8                        -- �\���P
    FROM     xx03_receivable_slips      xrs                                    -- AR������̓w�b�_�[
            ,xx03_receivable_slips_line xrsl                                   -- AR������͖���
            ,fnd_lookup_values          flv                                    -- �Q�ƕ\�i�`�[��ʁj
            ,fnd_lookup_values          flv2                                   -- �Q�ƕ\�i�X�e�[�^�X�j
            ,hz_cust_accounts           hca                                    -- �ڋq�}�X�^
            ,per_all_people_f           ppv7                                   -- �]�ƈ��}�X�^
    WHERE    xrsl.receivable_id         = xrs.receivable_id
    AND      xrs.slip_type              = flv.lookup_code
    AND      flv.lookup_type            = cv_type_slip_types
    AND      flv.language               = cv_lang
    AND      flv.enabled_flag           = cv_const_y
    AND      NVL(flv.start_date_active, gd_process_date) <= gd_process_date
    AND      NVL(flv.end_date_active, gd_process_date)   >= gd_process_date
    AND      xrs.wf_status              = flv2.lookup_code
    AND      flv2.lookup_type           = cv_type_wf_statuses
    AND      flv2.language              = cv_lang
    AND      flv2.enabled_flag          = cv_const_y
    AND      NVL(flv2.start_date_active, gd_process_date) <= gd_process_date
    AND      NVL(flv2.end_date_active, gd_process_date)   >= gd_process_date
    AND      hca.cust_account_id        = xrs.customer_id
    AND      xrs.entry_person_id        = ppv7.person_id
    AND      NVL(ppv7.effective_start_date, gd_process_date) <= gd_process_date
    AND      NVL(ppv7.effective_end_date,   gd_process_date) >= gd_process_date
    AND      xrs.slip_type              = cv_slip_type_80300                    -- �`�[���
    AND      xrs.trans_type_name        = gv_trans_type_name                    -- ����^�C�v��
    AND      xrs.wf_status              = cv_ar_status_appr                     -- �X�e�[�^�X�i���F�ρj
    AND      xrsl.attribute8      IS NULL                                       -- �������E�����X�e�[�^�X
    AND      xrs.orig_invoice_num IS NULL                                       -- �C�����`�[�ԍ�
    AND      NOT EXISTS ( SELECT 1
                          FROM   xx03_receivable_slips xrs2
                          WHERE  xrs.receivable_num = xrs2.orig_invoice_num    -- AR�������.�`�[�ԍ�= AR�������2.�C�����`�[�ԍ�
                          AND    xrs2.wf_status = cv_ar_status_appr            -- �X�e�[�^�X(���F��)
                        )                                                      -- �`�[����ς݂͏��O
    AND      xrs.gl_date               >= id_record_date_from                  -- �v���(FROM)
    AND      xrs.gl_date               <= id_record_date_to                    -- �v���(TO)
    AND      ( 
               ( iv_cust_code IS NULL
               AND 1 = 1
               )
               OR
               ( iv_cust_code IS NOT NULL
               AND hca.account_number  = iv_cust_code
               )
             )                                                                 -- �ڋq�R�[�h
    AND      ( 
               ( gv_privilege_flag      = cv_const_y                           -- �������_
               AND iv_base_code IS NULL
               AND 1 = 1
               )
               OR
               ( gv_privilege_flag      = cv_const_y                           -- �������_
               AND iv_base_code IS NOT NULL
               AND xrs.entry_department = iv_base_code
               )
               OR
               ( gv_privilege_flag     <> cv_const_y                           -- �������_�ȊO(�������_�ƃp�����[�^�N�[���傪����)
               AND gv_user_base_code    = iv_base_code
               AND xrs.entry_department = iv_base_code
               )
               OR
               ( gv_privilege_flag     <> cv_const_y                           -- �������_�ȊO(�������_�ƃp�����[�^�N�[���傪�قȂ�)
               AND gv_user_base_code   <> iv_base_code
               AND 1 = 2
               )
             )                                                                 -- �N�[����
    AND      ( 
               ( iv_user_name IS NULL
               AND 1 = 1
               )
               OR
               ( iv_user_name IS NOT NULL
               AND ppv7.employee_number   = iv_user_name
               )
             )                                                                 -- �`�[���͎�
    AND      ( 
               ( iv_slip_line_type_name IS NULL
               AND xrsl.slip_line_type_name IN ( SELECT amlv.name
                                                 FROM   ar_memo_lines_vl amlv
                                                 WHERE  amlv.attribute3 IS NOT NULL )
               )
               OR
               ( iv_slip_line_type_name IS NOT NULL
               AND xrsl.slip_line_type_name   = iv_slip_line_type_name
               )
             )                                                                 -- �������e
    AND      ( 
               ( id_payment_scheduled_date IS NULL
               AND 1 = 1
               )
               OR
               ( id_payment_scheduled_date IS NOT NULL
               AND TRUNC( xrs.payment_scheduled_date )  = id_payment_scheduled_date
               )
             )                                                                 -- �����\���
    ORDER BY 
             xrs.receivable_num                                                -- �`�[�ԍ�
            ,xrsl.line_number                                                  -- ���הԍ�
    ;
--
--
  -- �擾�f�[�^�i�[�ϐ���` (�S�o��)
  TYPE g_out_file_ttype IS TABLE OF get_receivable_slips_cur%ROWTYPE INDEX BY BINARY_INTEGER;
  gt_out_file_tab       g_out_file_ttype;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_record_date_from             IN     VARCHAR2     -- �v���(FROM)
   ,iv_record_date_to               IN     VARCHAR2     -- �v���(TO)
   ,iv_cust_code                    IN     VARCHAR2     -- �ڋq
   ,iv_base_code                    IN     VARCHAR2     -- �N�[����
   ,iv_user_name                    IN     VARCHAR2     -- ���͎�
   ,iv_slip_line_type_name          IN     VARCHAR2     -- �������e
   ,iv_payment_scheduled_date       IN     VARCHAR2     -- �����\���
   ,ov_errbuf                       OUT    VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode                      OUT    VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg                       OUT    VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000)  DEFAULT NULL;  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1)     DEFAULT NULL;  -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000)  DEFAULT NULL;  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_para_msg                     VARCHAR2(5000)  DEFAULT NULL;     -- �p�����[�^�o�̓��b�Z�[�W
    lv_para_msg2                    VARCHAR2(5000)  DEFAULT NULL;     -- �p�����[�^�o�̓��b�Z�[�W
    ln_option_param_count           NUMBER := cn_zero;                -- �C�Ӄp�����[�^�ݒ萔
    ln_privilege_base               NUMBER := cn_zero;                -- �o�^�E�X�V�����i0�F�����Ȃ��A1�F��������j
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode        := cv_status_normal;
    gv_privilege_flag := NULL;
--
--###########################  �Œ蕔 END   ############################
--
    --========================================
    -- 1.�p�����[�^�o�͏���
    --========================================
    lv_para_msg   :=  xxccp_common_pkg.get_msg( iv_application        =>  cv_xxcok_short_name           -- �A�v���Z�k��
                                               ,iv_name               =>  cv_msg_parameter              -- �p�����[�^�o�̓��b�Z�[�W
                                               ,iv_token_name1        =>  cv_tkn_nm_rec_date_from       -- �g�[�N���F�v����iFROM�j
                                               ,iv_token_value1       =>  iv_record_date_from           --           �v����iFROM�j
                                               ,iv_token_name2        =>  cv_tkn_nm_rec_date_to         -- �g�[�N���F�v����iTO�j
                                               ,iv_token_value2       =>  iv_record_date_to             --           �v����iTO�j
                                               ,iv_token_name3        =>  cv_tkn_nm_cust_code           -- �g�[�N���F�ڋq
                                               ,iv_token_value3       =>  iv_cust_code                  --           �ڋq
                                               ,iv_token_name4        =>  cv_tkn_nm_base_code           -- �g�[�N���F�N�[����
                                               ,iv_token_value4       =>  iv_base_code                  --           �N�[����
                                               ,iv_token_name5        =>  cv_tkn_nm_user_name           -- �g�[�N���F���͎�
                                               ,iv_token_value5       =>  iv_user_name                  --           ���͎�
                                               ,iv_token_name6        =>  cv_tkn_nm_slip_line_type      -- �g�[�N���F�������e
                                               ,iv_token_value6       =>  iv_slip_line_type_name        --           �������e
                                               ,iv_token_name7        =>  cv_tkn_nm_payment_date        -- �g�[�N���F�����\���
                                               ,iv_token_value7       =>  iv_payment_scheduled_date     --           �����\���
                                               );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_para_msg
    );
--
    -- ��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    -- �p�����[�^��ϐ��Ɋi�[
    gd_record_date_from       := TO_DATE( iv_record_date_from ,cv_date_format);       -- �p�����[�^�F�v���(FROM)
    gd_record_date_to         := TO_DATE( iv_record_date_to ,cv_date_format);         -- �p�����[�^�F�v���(TO)
    gv_cust_code              := iv_cust_code;                                        -- �p�����[�^�F�ڋq
    gv_base_code              := iv_base_code;                                        -- �p�����[�^�F�N�[����
    gv_user_name              := iv_user_name;                                        -- �p�����[�^�F���͎�
    gv_slip_line_type_name    := iv_slip_line_type_name;                              -- �p�����[�^�F�������e
    gd_payment_scheduled_date := TO_DATE( iv_payment_scheduled_date ,cv_date_format); -- �p�����[�^�F�����\���
--
    --========================================
    -- 2.���̓p�����[�^�`�F�b�N
    --========================================
    -- �v���(FROM)���v���(TO)��薢�����̏ꍇ�G���[
    IF ( gd_record_date_from > gd_record_date_to ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                                            iv_application => cv_xxcok_short_name,
                                            iv_name        => cv_msg_date_rever_err
                                           );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 3.�Ɩ����t�擾����
    --========================================
    gd_process_date := TRUNC( xxccp_common_pkg2.get_process_date );
    IF ( gd_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                                            iv_application => cv_xxcok_short_name,
                                            iv_name        => cv_msg_proc_date_err
                                           );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 4.���[�U�[ID�擾����
    --========================================
    gn_user_id := fnd_global.user_id;
    IF ( gn_user_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                                            iv_application => cv_xxcok_short_name,
                                            iv_name        => cv_msg_user_id_err
                                           );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 5.�������_�R�[�h�擾����
    --========================================
    gv_user_base_code := xxcok_common_pkg.get_base_code_f(
                                                          id_proc_date => gd_process_date,
                                                          in_user_id   => gn_user_id
                                                         );
    IF ( gv_user_base_code IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_xxcok_short_name,
                                            iv_name         => cv_msg_user_base_code_err,
                                            iv_token_name1  => cv_tkn_nm_user_id,
                                            iv_token_value1 => gn_user_id
                                           );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 6.�������[�U�[�m�F����
    --========================================
    -- 6-1 �������_�̏������[�U�[���m�F
    BEGIN
      SELECT  COUNT(1)            AS privilege_base_cnt
      INTO    ln_privilege_base
      FROM    fnd_lookup_values flv
      WHERE   flv.lookup_type      = cv_type_dec_pri_base
      AND     flv.lookup_code      = gv_user_base_code
      AND     flv.enabled_flag     = cv_const_y
      AND     flv.language         = cv_lang
      AND     gd_process_date BETWEEN flv.start_date_active 
                               AND NVL(flv.end_date_active,gd_process_date)
      ;
    END;
--
    -- �������_���[�U�[�̔���
    IF (ln_privilege_base >= cn_one) THEN
      gv_privilege_flag  := cv_const_y;
    ELSE
      gv_privilege_flag  := cv_const_n;
      -- 6-2 �p�����[�^�̋N�[���傪���ݒ�̏ꍇ�A�������_��ݒ�
      IF ( gv_base_code IS NULL ) THEN
        gv_base_code := gv_user_base_code;
      END IF;
    END IF;
--
    --======================================
    -- 7.XXCOK:����^�C�v_�ϓ��Ή����E�̎擾
    --======================================
    gv_trans_type_name := FND_PROFILE.VALUE( cv_prof_trx_type );
    IF ( gv_trans_type_name IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcok_short_name
                    ,iv_name         => cv_msg_profile_err   -- �v���t�@�C���擾�G���[
                    ,iv_token_name1  => cv_tkn_nm_profile
                    ,iv_token_value1 => cv_prof_trx_type
                   );
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
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
   * Procedure Name   : get_receivable_slips
   * Description      : AR������͏��(������)�f�[�^���o(A-2)
   ***********************************************************************************/
  PROCEDURE get_receivable_slips(
    ov_errbuf                       OUT    VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode                      OUT    VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg                       OUT    VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_receivable_slips'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000)  DEFAULT NULL;  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1)     DEFAULT NULL;  -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000)  DEFAULT NULL;  -- ���[�U�[�E�G���[�E���b�Z�[�W
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
    ov_retcode    := cv_status_normal;
    gn_target_cnt := cn_zero;
--
--###########################  �Œ蕔 END   ############################
--
    -- �Ώۃf�[�^�擾
    OPEN get_receivable_slips_cur (
            id_record_date_from       => gd_record_date_from        -- �v���(FROM)
           ,id_record_date_to         => gd_record_date_to          -- �v���(TO)
           ,iv_cust_code              => gv_cust_code               -- �ڋq
           ,iv_base_code              => gv_base_code               -- �N�[����
           ,iv_user_name              => gv_user_name               -- ���͎�
           ,iv_slip_line_type_name    => gv_slip_line_type_name     -- �������e
           ,id_payment_scheduled_date => gd_payment_scheduled_date  -- �����\���
          );
    FETCH get_receivable_slips_cur BULK COLLECT INTO gt_out_file_tab;
    CLOSE get_receivable_slips_cur;
    -- ���������J�E���g
    gn_target_cnt := gt_out_file_tab.COUNT;
--
    -- ���o�f�[�^��0���������ꍇ�x��
    IF  gn_target_cnt = cn_zero THEN
      RAISE global_api_warn_expt;
    END IF;
--
--
  EXCEPTION
--##################################  �Œ��O������ START   #################################
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
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
      IF get_receivable_slips_cur%ISOPEN THEN
        CLOSE get_receivable_slips_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_receivable_slips;
--
  /**********************************************************************************
   * Procedure Name   : chk_sales_deduction
   * Description      : �̔��T�����i�������j�m�F(A-3)
   ***********************************************************************************/
  PROCEDURE chk_sales_deduction
  (
      iv_cust_code              IN     hz_cust_accounts.account_number%TYPE                 -- �ڋq�R�[�h
     ,iv_slip_line_type_name    IN     xx03_receivable_slips_line.slip_line_type_name%TYPE  -- �������e
     ,iv_terms_name             IN     xx03_receivable_slips.terms_name%TYPE                -- �x��������
     ,id_invoice_date           IN     DATE                                                 -- ���������t
     ,id_payment_scheduled_date IN     DATE                                                 -- �����\���
     ,on_cnt                    OUT    NUMBER                                               -- �̔��T����񌏐�
     ,on_upload_cnt             OUT    NUMBER                                               -- �̔��T����񌏐�(�A�b�v���[�h)
     ,ov_errbuf                 OUT    VARCHAR2     -- �G���[�E���b�Z�[�W                   --# �Œ� #
     ,ov_retcode                OUT    VARCHAR2     -- ���^�[���E�R�[�h                     --# �Œ� #
     ,ov_errmsg                 OUT    VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W         --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_sales_deduction'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000)  DEFAULT NULL;  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1)     DEFAULT NULL;  -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000)  DEFAULT NULL;  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_derivation_month       NUMBER  DEFAULT NULL;            -- �v������o�p�̌�
    ln_derivation_date        NUMBER  DEFAULT NULL;            -- �v������o�p�̓�
    ld_derivation_record_date DATE    DEFAULT NULL;            -- �v������o���W�b�N�œ��o�������t
    lb_derivation_err_flg     BOOLEAN DEFAULT FALSE;           -- �v������o�t���O �G���[�̏ꍇ�ATRUE
    ln_cnt                    NUMBER  := 0;                    -- �̔��T������
    ln_upload_cnt             NUMBER  := 0;                    -- �̔��T�������i�A�b�v���[�h�̂݁j
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
    ------------------------------------------
    -- �Ώیv������o
    ------------------------------------------
    IF ( iv_terms_name = cv_terms_name_00_00_00 ) THEN
    -- �x�����������u00_00_00�v�̏ꍇ�AA-2�Ŏ擾�������������t��Ώیv����Ƃ���B
      ld_derivation_record_date := id_invoice_date;
    ELSE
      BEGIN
        ln_derivation_month := TO_NUMBER( SUBSTR( iv_terms_name, 7, 2 ) );
        ln_derivation_date  := TO_NUMBER( SUBSTR( iv_terms_name, 1, 2 ) );
      EXCEPTION
        WHEN VALUE_ERROR THEN
        ld_derivation_record_date := NULL;
        lb_derivation_err_flg     := TRUE;
      END;
      --
      IF ( lb_derivation_err_flg = FALSE ) THEN
        BEGIN
          -- �����\�������1�Ŏ擾�����������Z����B
          ld_derivation_record_date := ADD_MONTHS( id_payment_scheduled_date, -ln_derivation_month );
          --
          IF ( ln_derivation_date = cv_last_day_30 ) THEN
            -- ����30�̏ꍇ�A���Z���������\����̌�������ݒ肷��B
            ld_derivation_record_date := TRUNC( LAST_DAY( ld_derivation_record_date ) );
          ELSE
            -- ����30�ȊO�̏ꍇ�A���Z���������\�����2�Ŏ擾��������ݒ肷��B
            ld_derivation_record_date := TO_DATE( TO_CHAR( ld_derivation_record_date, cv_year_format ) 
                                                  || TO_CHAR( ld_derivation_record_date, cv_month_format ) 
                                                  || SUBSTR( iv_terms_name, 1, 2 ) , cv_date_format );
          END IF;
        EXCEPTION
          WHEN OTHERS THEN
            ld_derivation_record_date := NULL;
        END;
      END IF;
    END IF;
--
    ------------------------------------------
    -- �̔��T�����i�������j�擾
    ------------------------------------------
    BEGIN
      SELECT  /*+ USE_INVISIBLE_INDEXES INDEX(xxcok_sales_deduction_n10) */
              COUNT(*)   AS cnt
      INTO    ln_cnt
      FROM    xxcok_sales_deduction xsd                                                           -- �̔��T�����
      WHERE   xsd.recon_slip_num IS NULL                                                          -- �x���`�[�ԍ�
      AND     xsd.status              = cv_const_n                                                -- �X�e�[�^�X:N(�V�K)
      AND     xsd.customer_code_from IN ( SELECT xchv.ship_account_number AS ship_account_number  -- �U�֌��ڋq�R�[�h
                                          FROM   xxcfr_cust_hierarchy_v xchv
                                          WHERE  xchv.cash_account_number = iv_cust_code
                                          OR     xchv.bill_account_number = iv_cust_code
                                          OR     xchv.ship_account_number = iv_cust_code
                                        )
      AND     xsd.data_type          IN ( SELECT flv.lookup_code AS code                          -- �f�[�^���
                                          FROM   fnd_lookup_values flv
                                          WHERE  flv.lookup_type          = cv_type_deduction_data
                                          AND    flv.language             = cv_lang
                                          AND    flv.enabled_flag         = cv_const_y
                                          AND    flv.attribute14          = ( SELECT amlv.attribute3
                                                                              FROM   ar_memo_lines_vl amlv
                                                                              WHERE  amlv.attribute3 IS NOT NULL
                                                                              AND    amlv.name =  iv_slip_line_type_name
                                                                            )
                                          AND    NVL(flv.start_date_active, gd_process_date) <= gd_process_date
                                          AND    NVL(flv.end_date_active, gd_process_date)   >= gd_process_date
                                        )
      AND     xsd.record_date        <= ld_derivation_record_date                             -- �Ώیv������o���W�b�N�œ��o�������t
      AND     xsd.source_category    NOT IN ( cv_flag_d, cv_flag_u )                          -- �쐬���敪 NOT IN  D:���z����,U:�A�b�v���[�h
      AND     (
               ( xsd.source_category          = cv_flag_v                                     -- �쐬���敪 = V:������ѐU�ցi�U�֊����j
                 AND xsd.report_decision_flag = cv_flag_on                                    -- ����m��t���O:1(���ѐU�֊m��ς�)
               )
              OR
               ( xsd.source_category         <> cv_flag_v                                     -- �쐬���敪��V:������ѐU�ցi�U�֊����j�ȊO
                 AND xsd.report_decision_flag IS NULL                                         -- ����m��t���O IS NULL)
               )
              )
      ;
    EXCEPTION
      WHEN OTHERS THEN
        ln_cnt := 0;
    END;
--
    ------------------------------------------
    -- �̔��T�����A�b�v���[�h�i�������j�擾
    ------------------------------------------
    IF ( ln_cnt = 0 ) THEN 
      -- �A�b�v���[�h�̃f�[�^�̂ݑ��݂��Ă��邩�m�F
      BEGIN
        SELECT  /*+ USE_INVISIBLE_INDEXES INDEX(xxcok_sales_deduction_n10) */
                COUNT(*)   AS cnt
        INTO    ln_upload_cnt
        FROM    xxcok_sales_deduction xsd                                                           -- �̔��T�����
        WHERE   xsd.recon_slip_num IS NULL                                                          -- �x���`�[�ԍ�
        AND     xsd.status              = cv_const_n                                                -- �X�e�[�^�X:N(�V�K)
        AND     xsd.customer_code_from IN ( SELECT xchv.ship_account_number AS ship_account_number  -- �U�֌��ڋq�R�[�h
                                            FROM   xxcfr_cust_hierarchy_v xchv
                                            WHERE  xchv.cash_account_number = iv_cust_code
                                            OR     xchv.bill_account_number = iv_cust_code
                                            OR     xchv.ship_account_number = iv_cust_code
                                          )
        AND     xsd.data_type          IN ( SELECT flv.lookup_code AS code                          -- �f�[�^���
                                            FROM   fnd_lookup_values flv
                                            WHERE  flv.lookup_type          = cv_type_deduction_data
                                            AND    flv.language             = cv_lang
                                            AND    flv.enabled_flag         = cv_const_y
                                            AND    flv.attribute14          = ( SELECT amlv.attribute3
                                                                                FROM   ar_memo_lines_vl amlv
                                                                                WHERE  amlv.attribute3 IS NOT NULL
                                                                                AND    amlv.name =  iv_slip_line_type_name
                                                                              )
                                            AND    NVL(flv.start_date_active, gd_process_date) <= gd_process_date
                                            AND    NVL(flv.end_date_active, gd_process_date)   >= gd_process_date
                                          )
        AND     xsd.record_date        <= ld_derivation_record_date                           -- �Ώیv������o���W�b�N�œ��o�������t
        AND     xsd.source_category    = cv_flag_u                                            -- �쐬���敪 = U:�A�b�v���[�h
        AND     xsd.report_decision_flag IS NULL                                              -- ����m��t���O IS NULL
        ;
      EXCEPTION
        WHEN OTHERS THEN
          ln_upload_cnt := 0;
      END;
    END IF;
--
    -- �A�E�g�p�����[�^�ɐݒ�
    on_cnt        := ln_cnt;
    on_upload_cnt := ln_upload_cnt;
--
  EXCEPTION
--##################################  �Œ��O������ START   #################################
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
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
--#####################################  �Œ蕔 END   ##########################################
  END chk_sales_deduction;
--
  /**********************************************************************************
   * Procedure Name   : output_data
   * Description      : �f�[�^�o��(A-4)
   ***********************************************************************************/
  PROCEDURE output_data(
    ov_errbuf                       OUT    VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                      OUT    VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                       OUT    VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf     VARCHAR2(5000)  DEFAULT NULL;  -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1)     DEFAULT NULL;  -- ���^�[���E�R�[�h
    lv_errmsg     VARCHAR2(5000)  DEFAULT NULL;  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_line_data              VARCHAR2(5000)  DEFAULT NULL;        -- OUTPUT�f�[�^�ҏW�p
    ln_cnt                    NUMBER          := 0;                -- �̔��T����񌏐�
    ln_upload_cnt             NUMBER          := 0;                -- �̔��T����񌏐�(�A�b�v���[�h)
    lv_upload_flag            VARCHAR2(1)     DEFAULT NULL;        -- �A�b�v���[�h�̂݃t���O
--
    -- *** ���[�J���E�J�[�\�� ***
    --���o���擾�p�J�[�\��
    CURSOR header_cur
    IS
      SELECT  flv.description  head                                                -- �E�v�F�o�͗p���o��
      FROM    fnd_lookup_values flv
      WHERE   flv.language        = cv_lang                                        -- ����
      AND     flv.lookup_type     = cv_type_header                                 -- �T�����쐬�������E�`�[�p���o��
      AND     flv.lookup_code LIKE cv_code_eoh_024a44                              -- �N�C�b�N�R�[�h�i�T�����쐬�������E�`�[�p���o���j
      AND     gd_process_date    >= NVL( flv.start_date_active, gd_process_date )  -- �L���J�n��
      AND     gd_process_date    <= NVL( flv.end_date_active,   gd_process_date )  -- �L���I����
      AND     flv.enabled_flag    = cv_const_y                                     -- �g�p�\
      ORDER BY
              TO_NUMBER(flv.attribute1)
      ;
    --���o��
    TYPE l_header_ttype IS TABLE OF fnd_lookup_values.description%TYPE INDEX BY BINARY_INTEGER;
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J���E�e�[�u�� ***
    lt_header_tab l_header_ttype;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    ------------------------------------------
    -- ���o���̏o��
    ------------------------------------------
    -- �f�[�^�̌��o�����擾
    OPEN  header_cur;
    FETCH header_cur BULK COLLECT INTO lt_header_tab;
    CLOSE header_cur;
--
    --�f�[�^�̌��o����ҏW
    <<data_head_output>>
    FOR i IN 1..lt_header_tab.COUNT LOOP
      IF ( i = 1 ) THEN
        lv_line_data := lt_header_tab(i);
      ELSE
        lv_line_data := lv_line_data || cv_delimit || lt_header_tab(i);
      END IF;
    END LOOP data_head_output;
--
    --�f�[�^�̌��o�����o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_line_data
    );
    ------------------------------------------
    -- �f�[�^�o��
    ------------------------------------------
    <<data_output>>
    FOR i IN 1..gt_out_file_tab.COUNT LOOP
--
      -- ===============================
      -- A-3  �̔��T�����i�������j�m�F
      -- ===============================
      chk_sales_deduction( 
                            iv_cust_code              => gt_out_file_tab(i).account_number           -- �ڋq
                           ,iv_slip_line_type_name    => gt_out_file_tab(i).slip_line_type_name      -- �������e
                           ,iv_terms_name             => gt_out_file_tab(i).terms_name               -- �x��������
                           ,id_invoice_date           => gt_out_file_tab(i).invoice_date             -- ���������t
                           ,id_payment_scheduled_date => gt_out_file_tab(i).payment_scheduled_date   -- �����\���
                           ,on_cnt                    => ln_cnt                                      -- �̔��T����񌏐�
                           ,on_upload_cnt             => ln_upload_cnt                               -- �̔��T����񌏐�(�A�b�v���[�h)
                           ,ov_errbuf                 => lv_errbuf                                   -- �G���[�E���b�Z�[�W           --# �Œ� #
                           ,ov_retcode                => lv_retcode                                  -- ���^�[���E�R�[�h             --# �Œ� #
                           ,ov_errmsg                 => lv_errmsg                                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                           );
--
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_api_expt;
      END IF;
--
      -- �A�b�v���[�h�̂݃t���O�̐ݒ�
      IF ( ln_upload_cnt = 0 ) THEN
        lv_upload_flag := NULL;
      ELSE
        lv_upload_flag := cv_const_y;
      END IF;
--
      -- �����ΏۂƂȂ�̔��T����񂪂Ȃ��ꍇ
      IF ( ln_cnt = 0 ) THEN
        --�f�[�^��ҏW
        lv_line_data :=     gt_out_file_tab(i).slip_type                                          -- �`�[���
           || cv_delimit || gt_out_file_tab(i).slip_type_name                                     -- �`�[��ʖ���
           || cv_delimit || gt_out_file_tab(i).receivable_num                                     -- �`�[�ԍ�
           || cv_delimit || gt_out_file_tab(i).wf_status                                          -- �X�e�[�^�X
           || cv_delimit || gt_out_file_tab(i).wf_status_name                                     -- �X�e�[�^�X����
           || cv_delimit || TO_CHAR(gt_out_file_tab(i).entry_date ,cv_date_format)                -- �N�[��
           || cv_delimit || gt_out_file_tab(i).requestor_person_name                              -- �\���Җ�
           || cv_delimit || gt_out_file_tab(i).approver_person_name                               -- ���F�Җ�
           || cv_delimit || TO_CHAR(gt_out_file_tab(i).request_date ,cv_date_format)              -- �\����
           || cv_delimit || TO_CHAR(gt_out_file_tab(i).approval_date ,cv_date_format)             -- ���F��
           || cv_delimit || TO_CHAR(gt_out_file_tab(i).rejection_date ,cv_date_format)            -- �۔F��
           || cv_delimit || TO_CHAR(gt_out_file_tab(i).account_approval_date ,cv_date_format)     -- �o�����F��
           || cv_delimit || TO_CHAR(gt_out_file_tab(i).ar_forward_date ,cv_date_format)           -- AR�]����
           || cv_delimit || gt_out_file_tab(i).approver_comments                                  -- ���F�R�����g
           || cv_delimit || TO_CHAR(gt_out_file_tab(i).invoice_date ,cv_date_format)              -- ���������t
           || cv_delimit || gt_out_file_tab(i).trans_type_name                                    -- ����^�C�v��
           || cv_delimit || gt_out_file_tab(i).account_number                                     -- �ڋq�R�[�h
           || cv_delimit || gt_out_file_tab(i).customer_name                                      -- �ڋq��
           || cv_delimit || gt_out_file_tab(i).customer_office_name                               -- �ڋq���Ə���
           || cv_delimit || gt_out_file_tab(i).receipt_method_name                                -- �x�����@��
           || cv_delimit || gt_out_file_tab(i).terms_name                                         -- �x��������
           || cv_delimit || gt_out_file_tab(i).description                                        -- ���l
           || cv_delimit || gt_out_file_tab(i).entry_department                                   -- �N�[����
           || cv_delimit || gt_out_file_tab(i).full_name                                          -- �`�[���͎Җ�
           || cv_delimit || TO_CHAR(gt_out_file_tab(i).gl_date ,cv_date_format)                   -- �v���
           || cv_delimit || TO_CHAR(gt_out_file_tab(i).payment_scheduled_date ,cv_date_format)    -- �����\���
           || cv_delimit || gt_out_file_tab(i).line_number                                        -- ���הԍ�
           || cv_delimit || gt_out_file_tab(i).slip_line_type_name                                -- �������e
           || cv_delimit || gt_out_file_tab(i).slip_line_uom                                      -- �P��
           || cv_delimit || gt_out_file_tab(i).slip_line_unit_price                               -- �P��
           || cv_delimit || gt_out_file_tab(i).slip_line_quantity                                 -- ����
           || cv_delimit || gt_out_file_tab(i).slip_line_entered_amount                           -- ���͋��z
           || cv_delimit || gt_out_file_tab(i).tax_code                                           -- �ŋ敪�R�[�h
           || cv_delimit || gt_out_file_tab(i).tax_name                                           -- �ŋ敪
           || cv_delimit || gt_out_file_tab(i).entered_item_amount                                -- �{�̋��z
           || cv_delimit || gt_out_file_tab(i).entered_tax_amount                                 -- ����Ŋz
           || cv_delimit || gt_out_file_tab(i).slip_line_reciept_no                               -- �[�i���ԍ�
           || cv_delimit || gt_out_file_tab(i).slip_description                                   -- ���l�i���ׁj
           || cv_delimit || gt_out_file_tab(i).segment1                                           -- ���
           || cv_delimit || gt_out_file_tab(i).segment2                                           -- ����
           || cv_delimit || gt_out_file_tab(i).segment3                                           -- ����Ȗ�
           || cv_delimit || gt_out_file_tab(i).segment4                                           -- �⏕�Ȗ�
           || cv_delimit || gt_out_file_tab(i).segment5                                           -- �����
           || cv_delimit || gt_out_file_tab(i).segment6                                           -- ���Ƌ敪
           || cv_delimit || gt_out_file_tab(i).segment7                                           -- �v���W�F�N�g
           || cv_delimit || gt_out_file_tab(i).segment8                                           -- �\���P
           || cv_delimit || lv_upload_flag                                                        -- �A�b�v���[�h�̂݃t���O
        ;
        -- �f�[�^���o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_line_data
        );
        -- ���������J�E���g
        gn_normal_cnt := gn_normal_cnt + 1;
      END IF;
--
    END LOOP data_output;
--
  EXCEPTION
--##################################  �Œ��O������ START   #################################
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
      IF header_cur%ISOPEN THEN
        CLOSE header_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--##################################  �Œ蕔 END   ##########################################
--
  END output_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain( iv_record_date_from             IN     VARCHAR2  -- �v���(FROM)
                    ,iv_record_date_to               IN     VARCHAR2  -- �v���(TO)
                    ,iv_cust_code                    IN     VARCHAR2  -- �ڋq
                    ,iv_base_code                    IN     VARCHAR2  -- �N�[����
                    ,iv_user_name                    IN     VARCHAR2  -- ���͎�
                    ,iv_slip_line_type_name          IN     VARCHAR2  -- �������e
                    ,iv_payment_scheduled_date       IN     VARCHAR2  -- �����\���
                    ,ov_errbuf                       OUT    VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
                    ,ov_retcode                      OUT    VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
                    ,ov_errmsg                       OUT    VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_errbuf  VARCHAR2(5000)  DEFAULT NULL;  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1)     DEFAULT NULL;  -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000)  DEFAULT NULL;  -- ���[�U�[�E�G���[�E���b�Z�[�W
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
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
--
    -- ===============================
    -- A-1  ��������
    -- ===============================
    init( 
          iv_record_date_from       => iv_record_date_from            -- �v���(FROM)
         ,iv_record_date_to         => iv_record_date_to              -- �v���(TO)
         ,iv_cust_code              => iv_cust_code                   -- �ڋq
         ,iv_base_code              => iv_base_code                   -- �N�[����
         ,iv_user_name              => iv_user_name                   -- ���͎�
         ,iv_slip_line_type_name    => iv_slip_line_type_name         -- �������e
         ,iv_payment_scheduled_date => iv_payment_scheduled_date      -- �����\���
         ,ov_errbuf                 => lv_errbuf                      -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode                => lv_retcode                     -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg                 => lv_errmsg                      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
         );
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-2  �x�����A�g�T���f�[�^���o
    -- ===============================
    get_receivable_slips( 
                          ov_errbuf  => lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
                         ,ov_retcode => lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
                         ,ov_errmsg  => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                         );
--
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg( iv_application        =>  cv_xxcok_short_name,
                                             iv_name               =>  cv_msg_no_data_err
                                            );
      RAISE global_api_warn_expt;
    ELSIF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-4  �f�[�^�o��
    -- ===============================
    output_data(
                 ov_errbuf  => lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
                ,ov_retcode => lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
                ,ov_errmsg  => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** �x���n���h�� ***
    WHEN global_api_warn_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
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
  PROCEDURE main(
    errbuf                          OUT    VARCHAR2          -- �G���[���b�Z�[�W #�Œ�#
   ,retcode                         OUT    VARCHAR2          -- �G���[�R�[�h     #�Œ�#
   ,iv_record_date_from             IN     VARCHAR2          -- �v���(FROM)
   ,iv_record_date_to               IN     VARCHAR2          -- �v���(TO)
   ,iv_cust_code                    IN     VARCHAR2          -- �ڋq
   ,iv_base_code                    IN     VARCHAR2          -- �N�[����
   ,iv_user_name                    IN     VARCHAR2          -- ���͎�
   ,iv_slip_line_type_name          IN     VARCHAR2          -- �������e
   ,iv_payment_scheduled_date       IN     VARCHAR2          -- �����\���
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
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
    cv_log_header_out  CONSTANT VARCHAR2(6)   := 'OUTPUT';           -- �R���J�����g�w�b�_���b�Z�[�W�o�͐�F�o��
    cv_log_header_log  CONSTANT VARCHAR2(6)   := 'LOG';              -- �R���J�����g�w�b�_���b�Z�[�W�o�͐�F���O
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf          VARCHAR2(5000)  DEFAULT NULL;  -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1)     DEFAULT NULL;  -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000)  DEFAULT NULL;  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code    VARCHAR2(100)   DEFAULT NULL;  -- �I�����b�Z�[�W�R�[�h
    --
  BEGIN
--
--###########################  �Œ蕔 START   ###########################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_log_header_log
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
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
       iv_record_date_from             -- �v���(FROM)
      ,iv_record_date_to               -- �v���(TO)
      ,iv_cust_code                    -- �ڋq
      ,iv_base_code                    -- �N�[����
      ,iv_user_name                    -- ���͎�
      ,iv_slip_line_type_name          -- �������e
      ,iv_payment_scheduled_date       -- �����\���
      ,lv_errbuf                       -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode                      -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg                       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- ===============================
    -- A-4.�I������
    -- ===============================
--
    --�G���[�o��
    IF ( lv_retcode <> cv_status_normal ) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --
    --�G���[�̏ꍇ���������N���A�A�G���[�����Œ�
    IF ( lv_retcode = cv_status_error ) THEN
      gn_normal_cnt := cn_zero;
      gn_error_cnt  := cn_one;
    END IF;
    --
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_target_cnt )
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
                    ,iv_token_value1 => TO_CHAR( gn_normal_cnt )
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
                    ,iv_token_value1 => TO_CHAR( gn_error_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
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
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
--###########################  �Œ��O������ START   ###################################
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
--###########################  �Œ蕔 END   ###################################################
--
END XXCOK024A44C;
/
