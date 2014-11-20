CREATE OR REPLACE PACKAGE BODY APPS.XXCCP007A06C
AS
/*****************************************************************************************
 *
 * Package Name     : XXCCP007A06C(body)
 * Description      : �s���o��Z�f�[�^�폜
 * Version          : 1.00
 *
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012/08/03    1.00  SCSK ����ˍ��D [E_�{�ғ�_09865]�V�K�쐬
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
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
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
  resource_busy_expt        EXCEPTION; -- ���b�N�擾�G���[
  error_proc_expt           EXCEPTION; -- �G���[�I��
  warning_skip_expt         EXCEPTION; -- �x���X�L�b�v
  PRAGMA EXCEPTION_INIT( resource_busy_expt, -54 );
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  -- �A�v���P�[�V�����Z�k��
  cv_appl_short_name_xxccp  CONSTANT VARCHAR2(10) := 'XXCCP';
  -- �p�b�P�[�W��
  cv_pkg_name               CONSTANT VARCHAR2(20) := 'XXCCP007A06C'; -- �p�b�P�[�W��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_head_del_cnt           NUMBER DEFAULT 0;          -- �o��Z���w�b�_�폜����
  gn_lines_del_cnt          NUMBER DEFAULT 0;          -- �o��Z�����׍폜����
  gv_invoice_num            VARCHAR2(50);              -- �p�����[�^�F�o��Z���ԍ�
  gv_exe_mode               VARCHAR2(5);               -- �p�����[�^�F���s���[�h(0:�Ώۊm�F�A1:�f�[�^�X�V)
--
  --==================================================
  -- �O���[�o���J�[�\��
  --==================================================
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
    lv_head_data_output_flg  VARCHAR2(5)    DEFAULT 'N';                -- �o��Z���w�b�_CSV�o�͍σt���O
--
    -- ===============================================
    -- ���[�J����O����
    -- ===============================================
    err_prm_expt             EXCEPTION;
    err_delete_expt          EXCEPTION;
    data_warn_expt           EXCEPTION;
--
    -- ===============================================
    -- ���[�J���J�[�\��(���b�N�擾)
    -- ===============================================
    -- �o��Z���w�b�_
    CURSOR l_exp_rep_head_cur
    IS
      SELECT 
             aerha.report_header_id
      ,      aerha.invoice_num
      ,      aerha.source
      ,      aerha.workflow_approved_flag
      ,      aerha.expense_status_code
      ,      aerha.employee_id
      ,      TO_CHAR(aerha.week_end_date,'yyyy-mm-dd') AS week_end_date
      ,      TO_CHAR(aerha.creation_date,'yyyy-mm-dd') AS creation_date
      ,      aerha.created_by
      ,      TO_CHAR(aerha.last_update_date,'yyyy-mm-dd') AS last_update_date
      ,      aerha.last_updated_by
      ,      aerha.vouchno
      ,      aerha.total
      ,      aerha.expense_check_address_flag
      ,      aerha.expense_report_id
      ,      aerha.set_of_books_id
      ,      aerha.apply_advances_default
      ,      aerha.employee_ccid
      ,      aerha.description
      ,      aerha.reject_code
      ,      aerha.hold_lookup_code
      ,      aerha.attribute_category
      ,      aerha.last_update_login
      ,      aerha.org_id
      ,      aerha.flex_concatenated  
      ,      aerha.override_approver_id
      ,      aerha.payment_currency_code
      ,      aerha.core_wf_status_flag
      ,      aerha.prepay_apply_flag
      ,      aerha.prepay_num
      ,      aerha.prepay_dist_num
      ,      aerha.prepay_apply_amount
      ,      TO_CHAR(aerha.prepay_gl_date,'yyyy-mm-dd') AS prepay_gl_date
      ,      aerha.bothpay_parent_id
      ,      aerha.shortpay_parent_id
      ,      aerha.paid_on_behalf_employee_id
      ,      aerha.override_approver_name
      ,      aerha.amt_due_ccard_company
      ,      aerha.amt_due_employee
      ,      TO_CHAR(aerha.expense_last_status_date,'yyyy-mm-dd') AS expense_last_status_date
      ,      aerha.expense_current_approver_id
      ,      aerha.report_filing_number
      ,      TO_CHAR(aerha.receipts_received_date,'yyyy-mm-dd') AS receipts_received_date
      ,      aerha.audit_code
      ,      TO_CHAR(aerha.report_submitted_date,'yyyy-mm-dd') AS report_submitted_date
      ,      aerha.last_audited_by
      ,      aerha.return_reason_code
      ,      aerha.return_instruction
      FROM apps.ap_expense_report_headers_all aerha
      WHERE invoice_num = gv_invoice_num;
    TYPE l_exp_rep_head_ttype IS TABLE OF l_exp_rep_head_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    l_exp_rep_head_tab l_exp_rep_head_ttype;
--
    -- �o��Z������
    CURSOR l_exp_rep_lines_cur
    IS
      SELECT 
             aerla.report_header_id
      ,      TO_CHAR(aerla.last_update_date,'yyyy-mm-dd') AS last_update_date
      ,      aerla.last_updated_by
      ,      aerla.code_combination_id
      ,      aerla.item_description
      ,      aerla.set_of_books_id
      ,      aerla.amount
      ,      aerla.attribute_category
      ,      aerla.currency_code
      ,      aerla.vat_code
      ,      aerla.line_type_lookup_code
      ,      aerla.last_update_login
      ,      TO_CHAR(aerla.creation_date,'yyyy-mm-dd') AS creation_date
      ,      aerla.created_by
      ,      aerla.expenditure_organization_id
      ,      aerla.expenditure_type
      ,      TO_CHAR(aerla.expenditure_item_date,'yyyy-mm-dd') AS expenditure_item_date
      ,      aerla.pa_quantity
      ,      aerla.distribution_line_number
      ,      aerla.reference_1
      ,      aerla.reference_2
      ,      aerla.awt_group_id
      ,      aerla.org_id
      ,      aerla.receipt_verified_flag
      ,      aerla.justification_required_flag
      ,      aerla.receipt_required_flag
      ,      aerla.receipt_missing_flag
      ,      aerla.justification
      ,      aerla.expense_group
      ,      TO_CHAR(aerla.start_expense_date,'yyyy-mm-dd') AS start_expense_date
      ,      TO_CHAR(aerla.end_expense_date,'yyyy-mm-dd') AS end_expense_date
      ,      aerla.receipt_currency_code
      ,      aerla.receipt_conversion_rate
      ,      aerla.daily_amount
      ,      aerla.receipt_currency_amount
      ,      aerla.web_parameter_id
      ,      aerla.global_attribute_category
      ,      aerla.global_attribute1
      ,      aerla.global_attribute2
      ,      aerla.global_attribute3
      ,      aerla.global_attribute4
      ,      aerla.global_attribute5
      ,      aerla.global_attribute6
      ,      aerla.global_attribute7
      ,      aerla.global_attribute8
      ,      aerla.global_attribute9
      ,      aerla.global_attribute10
      ,      aerla.amount_includes_tax_flag
      ,      aerla.global_attribute11
      ,      aerla.global_attribute12
      ,      aerla.global_attribute13
      ,      aerla.global_attribute14
      ,      aerla.global_attribute15
      ,      aerla.global_attribute16
      ,      aerla.global_attribute17
      ,      aerla.global_attribute18
      ,      aerla.global_attribute19
      ,      aerla.global_attribute20
      ,      aerla.adjustment_reason
      ,      aerla.policy_shortpay_flag
      ,      aerla.award_id
      ,      aerla.merchant_document_number
      ,      aerla.merchant_name
      ,      aerla.merchant_reference
      ,      aerla.merchant_tax_reg_number
      ,      aerla.merchant_taxpayer_id
      ,      aerla.country_of_supply
      ,      aerla.tax_code_override_flag
      ,      aerla.tax_code_id
      ,      aerla.credit_card_trx_id
      ,      aerla.itemize_id
      ,      aerla.project_name
      ,      aerla.task_name
      ,      aerla.company_prepaid_invoice_id
      ,      aerla.pa_interfaced_flag
      ,      aerla.project_number
      ,      aerla.task_number
      ,      aerla.award_number
      ,      aerla.vehicle_category_code
      ,      aerla.vehicle_type
      ,      aerla.fuel_type
      ,      aerla.number_people
      ,      aerla.daily_distance
      ,      aerla.distance_unit_code
      ,      aerla.avg_mileage_rate
      ,      aerla.destination_from
      ,      aerla.destination_to
      ,      aerla.trip_distance
      ,      aerla.license_plate_number
      ,      aerla.mileage_rate_adjusted_flag
      ,      aerla.location_id
      ,      aerla.num_pdm_days1
      ,      aerla.num_pdm_days2
      ,      aerla.num_pdm_days3
      ,      aerla.per_diem_rate1
      ,      aerla.per_diem_rate2
      ,      aerla.per_diem_rate3
      ,      aerla.deduction_addition_amt1
      ,      aerla.deduction_addition_amt2
      ,      aerla.deduction_addition_amt3
      ,      aerla.num_free_breakfasts1
      ,      aerla.num_free_lunches1
      ,      aerla.num_free_dinners1
      ,      aerla.num_free_accommodations1
      ,      aerla.num_free_breakfasts2
      ,      aerla.num_free_lunches2
      ,      aerla.num_free_dinners2
      ,      aerla.num_free_accommodations2
      ,      aerla.num_free_breakfasts3
      ,      aerla.num_free_lunches3
      ,      aerla.num_free_dinners3
      ,      aerla.num_free_accommodations3
      ,      aerla.attendees
      ,      aerla.number_attendees
      ,      aerla.travel_type
      ,      aerla.ticket_class_code
      ,      aerla.ticket_number
      ,      aerla.flight_number
      ,      aerla.location_to_id
      ,      aerla.itemization_parent_id
      ,      aerla.flex_concatenated
      ,      aerla.func_currency_amt
      ,      aerla.location
      ,      aerla.category_code
      ,      aerla.adjustment_reason_code
      ,      aerla.ap_validation_error
      ,      aerla.submitted_amount
      ,      aerla.report_line_id
      FROM apps.ap_expense_report_lines_all aerla
      WHERE report_header_id = (SELECT head.report_header_id
                                FROM   ap_expense_report_headers_all head
                                WHERE  head.invoice_num = gv_invoice_num
                               )
      FOR UPDATE OF aerla.report_header_id NOWAIT;
    TYPE l_exp_rep_lines_ttype IS TABLE OF l_exp_rep_lines_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    l_exp_rep_lines_tab l_exp_rep_lines_ttype;
--
    -- AP������
    CURSOR l_ap_invoices_cur( in_vouchno IN NUMBER )
    IS
      SELECT aia.invoice_id
      FROM   apps.ap_invoices_all aia
      WHERE  aia.invoice_id = in_vouchno
      ;
    TYPE l_ap_invoices_ttype IS TABLE OF l_ap_invoices_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    l_ap_invoices_tab l_ap_invoices_ttype;
--
    -- �o��Z���w�b�_���b�N�p
    CURSOR l_exp_rep_head_lock_cur( in_report_header_id IN NUMBER )
    IS
      SELECT aerha.report_header_id
      FROM apps.ap_expense_report_headers_all aerha
      WHERE aerha.report_header_id = in_report_header_id
      FOR UPDATE OF aerha.report_header_id NOWAIT;
    TYPE l_exp_rep_head_lock_ttype IS TABLE OF l_exp_rep_head_lock_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    l_exp_rep_head_lock_tab l_exp_rep_head_lock_ttype;
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
    gn_head_del_cnt  := 0;  -- �o��Z���w�b�_�폜����
    gn_lines_del_cnt := 0;  -- �o��Z�����׍폜����
--
    -- ===============================================
    -- ���̓p�����[�^.���s���[�h�`�F�b�N
    -- ===============================================
    IF ( gv_exe_mode <> 0 ) AND
       ( gv_exe_mode <> 1 ) THEN
      ov_errmsg  := '���̓p�����[�^.���s���[�h�ɂ�0(�Ώۊm�F)�܂���1(�f�[�^�X�V)�̒l����͂��ĉ������B';
      RAISE err_prm_expt;
    END IF;
--
    -- ===============================================
    -- �o��Z���w�b�_��񒊏o����
    -- ===============================================
    -- �o��Z���w�b�_���擾�J�[�\��
    OPEN l_exp_rep_head_cur;
    FETCH l_exp_rep_head_cur BULK COLLECT INTO l_exp_rep_head_tab;
    CLOSE l_exp_rep_head_cur;
--
    IF ( l_exp_rep_head_tab.COUNT = 0 ) THEN
    -- �o��Z���w�b�_���0���̏ꍇ�A�x���I������
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => '�w�肵���o��Z���f�[�^�͑��݂��܂���B'
      );
      RAISE data_warn_expt;
    END IF;
--
    <<head_loop>>
    FOR i IN 1 .. l_exp_rep_head_tab.COUNT LOOP
      --
      -- ===============================================
      -- �o��Z���X�e�[�^�X�`�F�b�N����
      -- ===============================================
      IF ( ( l_exp_rep_head_tab( i ).source = 'SelfService' ) AND
           ( l_exp_rep_head_tab( i ).workflow_approved_flag = 'A' ) AND
           ( l_exp_rep_head_tab( i ).expense_status_code = 'INVOICED' ) ) THEN
--
        -- �o��Z���w�b�_���b�N����
        OPEN l_exp_rep_head_lock_cur( l_exp_rep_head_tab( i ).report_header_id );
        FETCH l_exp_rep_head_lock_cur BULK COLLECT INTO l_exp_rep_head_lock_tab;
        CLOSE l_exp_rep_head_lock_cur;
--
        -- ===============================================
        -- AP��������񒊏o����
        -- ===============================================
        -- AP�������J�[�\��
        OPEN l_ap_invoices_cur( l_exp_rep_head_tab( i ).vouchno );
        FETCH l_ap_invoices_cur BULK COLLECT INTO l_ap_invoices_tab;
        CLOSE l_ap_invoices_cur;
        --
        -- �Y���̐������f�[�^�����݂���ꍇ�A�x���I��
        IF ( l_ap_invoices_tab.COUNT >= 1 ) THEN
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => '�o��Z���ԍ��F' || gv_invoice_num || '�́A����AP�������f�[�^���쐬����Ă��܂��B'
          );
          RAISE data_warn_expt;
        ELSE
          -- ===============================================
          -- �o��Z�����׏�񒊏o����
          -- ===============================================
          -- �o��Z�����׃J�[�\��
          OPEN l_exp_rep_lines_cur;
          FETCH l_exp_rep_lines_cur BULK COLLECT INTO l_exp_rep_lines_tab;
          CLOSE l_exp_rep_lines_cur;
          --
          <<lines_loop>>
          FOR j IN 1 .. l_exp_rep_lines_tab.COUNT LOOP
            IF ( lv_head_data_output_flg = 'N' ) THEN
              -- �o��Z���w�b�_�l��CSV�ɖ��o��(=N)�̏ꍇ�A�w�b�_�l�̏o�͂��s��
              -- ���o��
              fnd_file.put_line(
                 which  => FND_FILE.OUTPUT
                ,buff   => '"�o��Z���w�b�_�폜�Ώ�"'
              );
              -- ���ږ�
              fnd_file.put_line(
                 which  => FND_FILE.OUTPUT
                ,buff   => '"report_header_id","invoice_num","source","workflow_approved_flag","expense_status_code",' ||
                           '"employee_id","week_end_date","creation_date","created_by","last_update_date",' ||
                           '"last_updated_by","vouchno","total","expense_check_address_flag","expense_report_id",' ||
                           '"set_of_books_id","apply_advances_default","employee_ccid","description","reject_code",' ||
                           '"hold_lookup_code","attribute_category","last_update_login","org_id","flex_concatenated",' ||
                           '"override_approver_id","payment_currency_code","core_wf_status_flag","prepay_apply_flag",' ||
                           '"prepay_num","prepay_dist_num","prepay_apply_amount","prepay_gl_date","bothpay_parent_id",' ||
                           '"shortpay_parent_id","paid_on_behalf_employee_id","override_approver_name",' ||
                           '"amt_due_ccard_company","amt_due_employee","expense_last_status_date",' ||
                           '"expense_current_approver_id","report_filing_number","receipts_received_date","audit_code",' ||
                           '"report_submitted_date","last_audited_by","return_reason_code","return_instruction"'
              );
              -- ���ڒl
              fnd_file.put_line(
                 which  => FND_FILE.OUTPUT
                ,buff   => '"' || l_exp_rep_head_tab( i ).report_header_id           || '","' ||
                                  l_exp_rep_head_tab( i ).invoice_num                || '","' ||
                                  l_exp_rep_head_tab( i ).source                     || '","' ||
                                  l_exp_rep_head_tab( i ).workflow_approved_flag     || '","' ||
                                  l_exp_rep_head_tab( i ).expense_status_code        || '","' ||
                                  l_exp_rep_head_tab( i ).employee_id                || '","' ||
                                  l_exp_rep_head_tab( i ).week_end_date              || '","' ||
                                  l_exp_rep_head_tab( i ).creation_date              || '","' ||
                                  l_exp_rep_head_tab( i ).created_by                 || '","' ||
                                  l_exp_rep_head_tab( i ).last_update_date           || '","' ||
                                  l_exp_rep_head_tab( i ).last_updated_by            || '","' ||
                                  l_exp_rep_head_tab( i ).vouchno                    || '","' ||
                                  l_exp_rep_head_tab( i ).total                      || '","' ||
                                  l_exp_rep_head_tab( i ).expense_check_address_flag || '","' ||
                                  l_exp_rep_head_tab( i ).expense_report_id          || '","' ||
                                  l_exp_rep_head_tab( i ).set_of_books_id            || '","' ||
                                  l_exp_rep_head_tab( i ).apply_advances_default     || '","' ||
                                  l_exp_rep_head_tab( i ).employee_ccid              || '","' ||
                                  l_exp_rep_head_tab( i ).description                || '","' ||
                                  l_exp_rep_head_tab( i ).reject_code                || '","' ||
                                  l_exp_rep_head_tab( i ).hold_lookup_code           || '","' ||
                                  l_exp_rep_head_tab( i ).attribute_category         || '","' ||
                                  l_exp_rep_head_tab( i ).last_update_login          || '","' ||
                                  l_exp_rep_head_tab( i ).org_id                     || '","' ||
                                  l_exp_rep_head_tab( i ).flex_concatenated          || '","' ||
                                  l_exp_rep_head_tab( i ).override_approver_id       || '","' ||
                                  l_exp_rep_head_tab( i ).payment_currency_code      || '","' ||
                                  l_exp_rep_head_tab( i ).core_wf_status_flag        || '","' ||
                                  l_exp_rep_head_tab( i ).prepay_apply_flag          || '","' ||
                                  l_exp_rep_head_tab( i ).prepay_num                 || '","' ||
                                  l_exp_rep_head_tab( i ).prepay_dist_num            || '","' ||
                                  l_exp_rep_head_tab( i ).prepay_apply_amount        || '","' ||
                                  l_exp_rep_head_tab( i ).prepay_gl_date             || '","' ||
                                  l_exp_rep_head_tab( i ).bothpay_parent_id          || '","' ||
                                  l_exp_rep_head_tab( i ).shortpay_parent_id         || '","' ||
                                  l_exp_rep_head_tab( i ).paid_on_behalf_employee_id || '","' ||
                                  l_exp_rep_head_tab( i ).override_approver_name     || '","' ||
                                  l_exp_rep_head_tab( i ).amt_due_ccard_company      || '","' ||
                                  l_exp_rep_head_tab( i ).amt_due_employee           || '","' ||
                                  l_exp_rep_head_tab( i ).expense_last_status_date   || '","' ||
                                  l_exp_rep_head_tab( i ).expense_current_approver_id || '","' ||
                                  l_exp_rep_head_tab( i ).report_filing_number       || '","' ||
                                  l_exp_rep_head_tab( i ).receipts_received_date     || '","' ||
                                  l_exp_rep_head_tab( i ).audit_code                 || '","' ||
                                  l_exp_rep_head_tab( i ).report_submitted_date      || '","' ||
                                  l_exp_rep_head_tab( i ).last_audited_by            || '","' ||
                                  l_exp_rep_head_tab( i ).return_reason_code         || '","' ||
                                  l_exp_rep_head_tab( i ).return_instruction         || '"'
              );
              -- CSV�o�͍σt���O��Y(�o�͍�)�ɐݒ肷��
              lv_head_data_output_flg := 'Y';
            END IF;
            -- ���גl�o��
            -- ���o��
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => '"�o��Z�����׍폜�Ώ�"'
            );
            -- ���ږ�
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => '"report_header_id","last_update_date","last_updated_by","code_combination_id","item_description",' ||
                         '"set_of_books_id","amount","attribute_category","currency_code","vat_code","line_type_lookup_code",' ||
                         '"last_update_login","creation_date","created_by","expenditure_organization_id","expenditure_type",' ||
                         '"expenditure_item_date","pa_quantity","distribution_line_number","reference_1","reference_2",' ||
                         '"awt_group_id","org_id","receipt_verified_flag","justification_required_flag","receipt_required_flag",' ||
                         '"receipt_missing_flag","justification","expense_group","start_expense_date","end_expense_date",' ||
                         '"receipt_currency_code","receipt_conversion_rate","daily_amount","receipt_currency_amount",' ||
                         '"web_parameter_id","global_attribute_category","global_attribute1","global_attribute2",' ||
                         '"global_attribute3","global_attribute4","global_attribute5","global_attribute6","global_attribute7",' ||
                         '"global_attribute8","global_attribute9","global_attribute10","amount_includes_tax_flag",' ||
                         '"global_attribute11","global_attribute12","global_attribute13","global_attribute14",' ||
                         '"global_attribute15","global_attribute16","global_attribute17","global_attribute18",' ||
                         '"global_attribute19","global_attribute20","adjustment_reason","policy_shortpay_flag",' ||
                         '"award_id","merchant_document_number","merchant_name","merchant_reference","merchant_tax_reg_number",' ||
                         '"merchant_taxpayer_id","country_of_supply","tax_code_override_flag","tax_code_id","credit_card_trx_id",' ||
                         '"itemize_id","project_name","task_name","company_prepaid_invoice_id","pa_interfaced_flag",' ||
                         '"project_number","task_number","award_number","vehicle_category_code","vehicle_type","fuel_type",' ||
                         '"number_people","daily_distance","distance_unit_code","avg_mileage_rate","destination_from",' ||
                         '"destination_to","trip_distance","license_plate_number","mileage_rate_adjusted_flag","location_id",' ||
                         '"num_pdm_days1","num_pdm_days2","num_pdm_days3","per_diem_rate1","per_diem_rate2","per_diem_rate3",' ||
                         '"deduction_addition_amt1","deduction_addition_amt2","deduction_addition_amt3","num_free_breakfasts1",' ||
                         '"num_free_lunches1","num_free_dinners1","num_free_accommodations1","num_free_breakfasts2",' ||
                         '"num_free_lunches2","num_free_dinners2","num_free_accommodations2","num_free_breakfasts3",' ||
                         '"num_free_lunches3","num_free_dinners3","num_free_accommodations3","attendees","number_attendees",' ||
                         '"travel_type","ticket_class_code","ticket_number","flight_number","location_to_id",' ||
                         '"itemization_parent_id","flex_concatenated","func_currency_amt","location","category_code",' ||
                         '"adjustment_reason_code","ap_validation_error","submitted_amount","report_line_id"'
            );
            -- ���ڒl
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => '"' || l_exp_rep_lines_tab( j ).report_header_id            || '","' ||
                                l_exp_rep_lines_tab( j ).last_update_date            || '","' ||
                                l_exp_rep_lines_tab( j ).last_updated_by             || '","' ||
                                l_exp_rep_lines_tab( j ).code_combination_id         || '","' ||
                                l_exp_rep_lines_tab( j ).item_description            || '","' ||
                                l_exp_rep_lines_tab( j ).set_of_books_id             || '","' ||
                                l_exp_rep_lines_tab( j ).amount                      || '","' ||
                                l_exp_rep_lines_tab( j ).attribute_category          || '","' ||
                                l_exp_rep_lines_tab( j ).currency_code               || '","' ||
                                l_exp_rep_lines_tab( j ).vat_code                    || '","' ||
                                l_exp_rep_lines_tab( j ).line_type_lookup_code       || '","' ||
                                l_exp_rep_lines_tab( j ).last_update_login           || '","' ||
                                l_exp_rep_lines_tab( j ).creation_date               || '","' ||
                                l_exp_rep_lines_tab( j ).created_by                  || '","' ||
                                l_exp_rep_lines_tab( j ).expenditure_organization_id || '","' ||
                                l_exp_rep_lines_tab( j ).expenditure_type            || '","' ||
                                l_exp_rep_lines_tab( j ).expenditure_item_date       || '","' ||
                                l_exp_rep_lines_tab( j ).pa_quantity                 || '","' ||
                                l_exp_rep_lines_tab( j ).distribution_line_number    || '","' ||
                                l_exp_rep_lines_tab( j ).reference_1                 || '","' ||
                                l_exp_rep_lines_tab( j ).reference_2                 || '","' ||
                                l_exp_rep_lines_tab( j ).awt_group_id                || '","' ||
                                l_exp_rep_lines_tab( j ).org_id                      || '","' ||
                                l_exp_rep_lines_tab( j ).receipt_verified_flag       || '","' ||
                                l_exp_rep_lines_tab( j ).justification_required_flag || '","' ||
                                l_exp_rep_lines_tab( j ).receipt_required_flag       || '","' ||
                                l_exp_rep_lines_tab( j ).receipt_missing_flag        || '","' ||
                                l_exp_rep_lines_tab( j ).justification               || '","' ||
                                l_exp_rep_lines_tab( j ).expense_group               || '","' ||
                                l_exp_rep_lines_tab( j ).start_expense_date          || '","' ||
                                l_exp_rep_lines_tab( j ).end_expense_date            || '","' ||
                                l_exp_rep_lines_tab( j ).receipt_currency_code       || '","' ||
                                l_exp_rep_lines_tab( j ).receipt_conversion_rate     || '","' ||
                                l_exp_rep_lines_tab( j ).daily_amount                || '","' ||
                                l_exp_rep_lines_tab( j ).receipt_currency_amount     || '","' ||
                                l_exp_rep_lines_tab( j ).web_parameter_id            || '","' ||
                                l_exp_rep_lines_tab( j ).global_attribute_category   || '","' ||
                                l_exp_rep_lines_tab( j ).global_attribute1           || '","' ||
                                l_exp_rep_lines_tab( j ).global_attribute2           || '","' ||
                                l_exp_rep_lines_tab( j ).global_attribute3           || '","' ||
                                l_exp_rep_lines_tab( j ).global_attribute4           || '","' ||
                                l_exp_rep_lines_tab( j ).global_attribute5           || '","' ||
                                l_exp_rep_lines_tab( j ).global_attribute6           || '","' ||
                                l_exp_rep_lines_tab( j ).global_attribute7           || '","' ||
                                l_exp_rep_lines_tab( j ).global_attribute8           || '","' ||
                                l_exp_rep_lines_tab( j ).global_attribute9           || '","' ||
                                l_exp_rep_lines_tab( j ).global_attribute10          || '","' ||
                                l_exp_rep_lines_tab( j ).amount_includes_tax_flag    || '","' ||
                                l_exp_rep_lines_tab( j ).global_attribute11          || '","' ||
                                l_exp_rep_lines_tab( j ).global_attribute12          || '","' ||
                                l_exp_rep_lines_tab( j ).global_attribute13          || '","' ||
                                l_exp_rep_lines_tab( j ).global_attribute14          || '","' ||
                                l_exp_rep_lines_tab( j ).global_attribute15          || '","' ||
                                l_exp_rep_lines_tab( j ).global_attribute16          || '","' ||
                                l_exp_rep_lines_tab( j ).global_attribute17          || '","' ||
                                l_exp_rep_lines_tab( j ).global_attribute18          || '","' ||
                                l_exp_rep_lines_tab( j ).global_attribute19          || '","' ||
                                l_exp_rep_lines_tab( j ).global_attribute20          || '","' ||
                                l_exp_rep_lines_tab( j ).adjustment_reason           || '","' ||
                                l_exp_rep_lines_tab( j ).policy_shortpay_flag        || '","' ||
                                l_exp_rep_lines_tab( j ).award_id                    || '","' ||
                                l_exp_rep_lines_tab( j ).merchant_document_number    || '","' ||
                                l_exp_rep_lines_tab( j ).merchant_name               || '","' ||
                                l_exp_rep_lines_tab( j ).merchant_reference          || '","' ||
                                l_exp_rep_lines_tab( j ).merchant_tax_reg_number     || '","' ||
                                l_exp_rep_lines_tab( j ).merchant_taxpayer_id        || '","' ||
                                l_exp_rep_lines_tab( j ).country_of_supply           || '","' ||
                                l_exp_rep_lines_tab( j ).tax_code_override_flag      || '","' ||
                                l_exp_rep_lines_tab( j ).tax_code_id                 || '","' ||
                                l_exp_rep_lines_tab( j ).credit_card_trx_id          || '","' ||
                                l_exp_rep_lines_tab( j ).itemize_id                  || '","' ||
                                l_exp_rep_lines_tab( j ).project_name                || '","' ||
                                l_exp_rep_lines_tab( j ).task_name                   || '","' ||
                                l_exp_rep_lines_tab( j ).company_prepaid_invoice_id  || '","' ||
                                l_exp_rep_lines_tab( j ).pa_interfaced_flag          || '","' ||
                                l_exp_rep_lines_tab( j ).project_number              || '","' ||
                                l_exp_rep_lines_tab( j ).task_number                 || '","' ||
                                l_exp_rep_lines_tab( j ).award_number                || '","' ||
                                l_exp_rep_lines_tab( j ).vehicle_category_code       || '","' ||
                                l_exp_rep_lines_tab( j ).vehicle_type                || '","' ||
                                l_exp_rep_lines_tab( j ).fuel_type                   || '","' ||
                                l_exp_rep_lines_tab( j ).number_people               || '","' ||
                                l_exp_rep_lines_tab( j ).daily_distance              || '","' ||
                                l_exp_rep_lines_tab( j ).distance_unit_code          || '","' ||
                                l_exp_rep_lines_tab( j ).avg_mileage_rate            || '","' ||
                                l_exp_rep_lines_tab( j ).destination_from            || '","' ||
                                l_exp_rep_lines_tab( j ).destination_to              || '","' ||
                                l_exp_rep_lines_tab( j ).trip_distance               || '","' ||
                                l_exp_rep_lines_tab( j ).license_plate_number        || '","' ||
                                l_exp_rep_lines_tab( j ).mileage_rate_adjusted_flag  || '","' ||
                                l_exp_rep_lines_tab( j ).location_id                 || '","' ||
                                l_exp_rep_lines_tab( j ).num_pdm_days1               || '","' ||
                                l_exp_rep_lines_tab( j ).num_pdm_days2               || '","' ||
                                l_exp_rep_lines_tab( j ).num_pdm_days3               || '","' ||
                                l_exp_rep_lines_tab( j ).per_diem_rate1              || '","' ||
                                l_exp_rep_lines_tab( j ).per_diem_rate2              || '","' ||
                                l_exp_rep_lines_tab( j ).per_diem_rate3              || '","' ||
                                l_exp_rep_lines_tab( j ).deduction_addition_amt1     || '","' ||
                                l_exp_rep_lines_tab( j ).deduction_addition_amt2     || '","' ||
                                l_exp_rep_lines_tab( j ).deduction_addition_amt3     || '","' ||
                                l_exp_rep_lines_tab( j ).num_free_breakfasts1        || '","' ||
                                l_exp_rep_lines_tab( j ).num_free_lunches1           || '","' ||
                                l_exp_rep_lines_tab( j ).num_free_dinners1           || '","' ||
                                l_exp_rep_lines_tab( j ).num_free_accommodations1    || '","' ||
                                l_exp_rep_lines_tab( j ).num_free_breakfasts2        || '","' ||
                                l_exp_rep_lines_tab( j ).num_free_lunches2           || '","' ||
                                l_exp_rep_lines_tab( j ).num_free_dinners2           || '","' ||
                                l_exp_rep_lines_tab( j ).num_free_accommodations2    || '","' ||
                                l_exp_rep_lines_tab( j ).num_free_breakfasts3        || '","' ||
                                l_exp_rep_lines_tab( j ).num_free_lunches3           || '","' ||
                                l_exp_rep_lines_tab( j ).num_free_dinners3           || '","' ||
                                l_exp_rep_lines_tab( j ).num_free_accommodations3    || '","' ||
                                l_exp_rep_lines_tab( j ).attendees                   || '","' ||
                                l_exp_rep_lines_tab( j ).number_attendees            || '","' ||
                                l_exp_rep_lines_tab( j ).travel_type                 || '","' ||
                                l_exp_rep_lines_tab( j ).ticket_class_code           || '","' ||
                                l_exp_rep_lines_tab( j ).ticket_number               || '","' ||
                                l_exp_rep_lines_tab( j ).flight_number               || '","' ||
                                l_exp_rep_lines_tab( j ).location_to_id              || '","' ||
                                l_exp_rep_lines_tab( j ).itemization_parent_id       || '","' ||
                                l_exp_rep_lines_tab( j ).flex_concatenated           || '","' ||
                                l_exp_rep_lines_tab( j ).func_currency_amt           || '","' ||
                                l_exp_rep_lines_tab( j ).location                    || '","' ||
                                l_exp_rep_lines_tab( j ).category_code               || '","' ||
                                l_exp_rep_lines_tab( j ).adjustment_reason_code      || '","' ||
                                l_exp_rep_lines_tab( j ).ap_validation_error         || '","' ||
                                l_exp_rep_lines_tab( j ).submitted_amount            || '","' ||
                                l_exp_rep_lines_tab( j ).report_line_id              || '"'
            );
            -- �폜�����J�E���g
            gn_lines_del_cnt := gn_lines_del_cnt + 1;
          END LOOP lines_loop;
--
          -- CSV�o�͍σt���O��Y(�o�͍�)�ɐݒ肷��
          lv_head_data_output_flg := 'Y';
--
          IF ( gv_exe_mode = '1' ) THEN
            -- �p�����[�^�F���s���[�h��1(�f�[�^�X�V)�̏ꍇ�̂ݍ폜�������s��
            -- ===============================================
            -- �폜����
            -- ===============================================
            -- �o��Z�����׍폜
            IF ( l_exp_rep_lines_tab.COUNT >= 1 ) THEN
              BEGIN
                DELETE FROM apps.ap_expense_report_lines_all
                WHERE report_header_id = (SELECT head.report_header_id
                                          FROM   apps.ap_expense_report_headers_all head
                                          WHERE  head.invoice_num = gv_invoice_num
                                         )
                ;
                --
              EXCEPTION
                -- *** �f�[�^�폜�G���[ ***
                WHEN OTHERS THEN
                  -- �폜�����J�E���g�N���A
                  gn_lines_del_cnt := 0;
                  --
                  ov_errmsg  := '�폜�����Ɏ��s���܂����B�y�o��Z�����ׁzreport_header_id�F' || gv_invoice_num;
                  ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
                  RAISE err_delete_expt;
              END;
            END IF;
--
            -- �o��Z���w�b�_�폜
            BEGIN
              DELETE FROM apps.ap_expense_report_headers_all
              WHERE invoice_num = gv_invoice_num
              ;
              -- �폜�����J�E���g
              gn_head_del_cnt := gn_head_del_cnt + 1;
              -- ���팏���J�E���g
              gn_normal_cnt := gn_normal_cnt + 1;
              --
            EXCEPTION
              -- *** �f�[�^�폜�G���[ ***
              WHEN OTHERS THEN
                -- �폜�����J�E���g�N���A
                gn_lines_del_cnt := 0;
                --
                ov_errmsg  := '�폜�����Ɏ��s���܂����B�y�o��Z���w�b�_�zreport_header_id�F' || gv_invoice_num;
                ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
                RAISE err_delete_expt;
            END;
          END IF;
          -- �Ώی���
          gn_target_cnt := gn_target_cnt + 1;
        END IF;
--
      ELSE
        -- �Ώۂ̌o��Z���ԍ��������F�̏ꍇ�A�x���I������
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => '�o��Z���ԍ��F' || gv_invoice_num || '�͖����F�ł��B' ||
                     '�iSOURCE�F' || l_exp_rep_head_tab( i ).source ||
                     ' WORKFLOW_APPROVED_FLAG�F' || l_exp_rep_head_tab( i ).workflow_approved_flag ||
                     ' EXPENSE_STATUS_CODE�F' || l_exp_rep_head_tab( i ).expense_status_code || '�j'
        );
        RAISE data_warn_expt;
      END IF;
    END LOOP head_loop;
--
--
  EXCEPTION
    -- *** ���̓p�����[�^��O�n���h�� ***
    WHEN err_prm_expt THEN
      ov_retcode := cv_status_error;
      -- �ُ팏���J�E���g
      gn_error_cnt := gn_error_cnt + 1;
--
    -- *** �x����O�n���h�� ***
    WHEN data_warn_expt THEN
      ov_retcode := cv_status_warn;
      -- �X�L�b�v�����J�E���g
      gn_warn_cnt := gn_warn_cnt + 1;
--
    -- *** �폜������O�n���h�� ***
    WHEN err_delete_expt THEN
      ov_retcode := cv_status_error;
      -- �ُ팏���J�E���g
      gn_error_cnt := gn_error_cnt + 1;
--
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- �ُ팏���J�E���g
      gn_error_cnt := gn_error_cnt + 1;
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      -- �ُ팏���J�E���g
      gn_error_cnt := gn_error_cnt + 1;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      -- �ُ팏���J�E���g
      gn_error_cnt := gn_error_cnt + 1;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      -- �ُ팏���J�E���g
      gn_error_cnt := gn_error_cnt + 1;
--
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
    errbuf         OUT VARCHAR2,       --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode        OUT VARCHAR2,       --   ���^�[���E�R�[�h    --# �Œ� #
    iv_invoice_num IN  VARCHAR2,       --   �o��Z���ԍ�
    iv_exe_mode    IN  VARCHAR2        --   ���s���[�h(0:�Ώۊm�F�A1:�f�[�^�X�V)
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
    lv_outmsg          VARCHAR2(5000) DEFAULT NULL; -- �o�͗p���b�Z�[�W
    lb_retcode         BOOLEAN        DEFAULT TRUE; -- ���b�Z�[�W�o�͊֐��߂�l
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
    -- �p�����[�^���O���[�o���ϐ��ɐݒ�
    gv_invoice_num := iv_invoice_num;
    gv_exe_mode    := iv_exe_mode;
    -- �v���O�������͍��ڂ��o��
    -- �o��Z���ԍ�
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '�o��Z���ԍ��F' || gv_invoice_num
    );
    -- ���s���[�h
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '���s���[�h�F' || gv_exe_mode
    );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => NULL --���s
    );
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
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
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --���s���[�h��0:�Ώۊm�F�̏ꍇ�A�J�E���g�����폜����������������
    IF ( gv_exe_mode = 0 ) THEN
      gn_head_del_cnt  := 0;
      gn_lines_del_cnt := 0;
    END IF;
    --
    --�폜�����o��(�o��Z���w�b�_�e�[�u��)
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '�폜����  �F  ' || gn_head_del_cnt || '��  ( �o��Z���w�b�_�e�[�u�� )'
    );
    --
    --�폜�����o��(�o��Z�����׃e�[�u��)
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '�폜����  �F  ' || gn_lines_del_cnt || '��  ( �o��Z�����׃e�[�u�� )'
    );
    --
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
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_normal_msg
                     );
    ELSIF(lv_retcode = cv_status_warn) THEN
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_warn_msg
                     );
    ELSIF(lv_retcode = cv_status_error) THEN
      gv_out_msg := '�������G���[�I�����܂����B';
    END IF;
    --
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
END XXCCP007A06C;
/
