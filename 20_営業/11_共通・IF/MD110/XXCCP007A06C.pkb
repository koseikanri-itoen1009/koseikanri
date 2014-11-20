CREATE OR REPLACE PACKAGE BODY APPS.XXCCP007A06C
AS
/*****************************************************************************************
 *
 * Package Name     : XXCCP007A06C(body)
 * Description      : 不正経費精算データ削除
 * Version          : 1.00
 *
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012/08/03    1.00  SCSK 小野塚香織 [E_本稼動_09865]新規作成
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2
  --WHOカラム
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
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
  gn_target_cnt    NUMBER;                    -- 対象件数
  gn_normal_cnt    NUMBER;                    -- 正常件数
  gn_error_cnt     NUMBER;                    -- エラー件数
  gn_warn_cnt      NUMBER;                    -- スキップ件数
--
--################################  固定部 END   ##################################
--
--##########################  固定共通例外宣言部 START  ###########################
--
  --*** 処理部共通例外 ***
  global_process_expt       EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt           EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  resource_busy_expt        EXCEPTION; -- ロック取得エラー
  error_proc_expt           EXCEPTION; -- エラー終了
  warning_skip_expt         EXCEPTION; -- 警告スキップ
  PRAGMA EXCEPTION_INIT( resource_busy_expt, -54 );
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  -- アプリケーション短縮名
  cv_appl_short_name_xxccp  CONSTANT VARCHAR2(10) := 'XXCCP';
  -- パッケージ名
  cv_pkg_name               CONSTANT VARCHAR2(20) := 'XXCCP007A06C'; -- パッケージ名
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_head_del_cnt           NUMBER DEFAULT 0;          -- 経費精算書ヘッダ削除件数
  gn_lines_del_cnt          NUMBER DEFAULT 0;          -- 経費精算書明細削除件数
  gv_invoice_num            VARCHAR2(50);              -- パラメータ：経費精算書番号
  gv_exe_mode               VARCHAR2(5);               -- パラメータ：実行モード(0:対象確認、1:データ更新)
--
  --==================================================
  -- グローバルカーソル
  --==================================================
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--                                                                      
    -- *** ローカル変数 ***
    lv_head_data_output_flg  VARCHAR2(5)    DEFAULT 'N';                -- 経費精算書ヘッダCSV出力済フラグ
--
    -- ===============================================
    -- ローカル例外処理
    -- ===============================================
    err_prm_expt             EXCEPTION;
    err_delete_expt          EXCEPTION;
    data_warn_expt           EXCEPTION;
--
    -- ===============================================
    -- ローカルカーソル(ロック取得)
    -- ===============================================
    -- 経費精算書ヘッダ
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
    -- 経費精算書明細
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
    -- AP請求書
    CURSOR l_ap_invoices_cur( in_vouchno IN NUMBER )
    IS
      SELECT aia.invoice_id
      FROM   apps.ap_invoices_all aia
      WHERE  aia.invoice_id = in_vouchno
      ;
    TYPE l_ap_invoices_ttype IS TABLE OF l_ap_invoices_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    l_ap_invoices_tab l_ap_invoices_ttype;
--
    -- 経費精算書ヘッダロック用
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
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- グローバル変数の初期化
    gn_target_cnt    := 0;
    gn_normal_cnt    := 0;
    gn_error_cnt     := 0;
    gn_warn_cnt      := 0;
    gn_head_del_cnt  := 0;  -- 経費精算書ヘッダ削除件数
    gn_lines_del_cnt := 0;  -- 経費精算書明細削除件数
--
    -- ===============================================
    -- 入力パラメータ.実行モードチェック
    -- ===============================================
    IF ( gv_exe_mode <> 0 ) AND
       ( gv_exe_mode <> 1 ) THEN
      ov_errmsg  := '入力パラメータ.実行モードには0(対象確認)または1(データ更新)の値を入力して下さい。';
      RAISE err_prm_expt;
    END IF;
--
    -- ===============================================
    -- 経費精算書ヘッダ情報抽出処理
    -- ===============================================
    -- 経費精算書ヘッダ情報取得カーソル
    OPEN l_exp_rep_head_cur;
    FETCH l_exp_rep_head_cur BULK COLLECT INTO l_exp_rep_head_tab;
    CLOSE l_exp_rep_head_cur;
--
    IF ( l_exp_rep_head_tab.COUNT = 0 ) THEN
    -- 経費精算書ヘッダ情報が0件の場合、警告終了する
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => '指定した経費精算書データは存在しません。'
      );
      RAISE data_warn_expt;
    END IF;
--
    <<head_loop>>
    FOR i IN 1 .. l_exp_rep_head_tab.COUNT LOOP
      --
      -- ===============================================
      -- 経費精算書ステータスチェック処理
      -- ===============================================
      IF ( ( l_exp_rep_head_tab( i ).source = 'SelfService' ) AND
           ( l_exp_rep_head_tab( i ).workflow_approved_flag = 'A' ) AND
           ( l_exp_rep_head_tab( i ).expense_status_code = 'INVOICED' ) ) THEN
--
        -- 経費精算書ヘッダロック処理
        OPEN l_exp_rep_head_lock_cur( l_exp_rep_head_tab( i ).report_header_id );
        FETCH l_exp_rep_head_lock_cur BULK COLLECT INTO l_exp_rep_head_lock_tab;
        CLOSE l_exp_rep_head_lock_cur;
--
        -- ===============================================
        -- AP請求書情報抽出処理
        -- ===============================================
        -- AP請求書カーソル
        OPEN l_ap_invoices_cur( l_exp_rep_head_tab( i ).vouchno );
        FETCH l_ap_invoices_cur BULK COLLECT INTO l_ap_invoices_tab;
        CLOSE l_ap_invoices_cur;
        --
        -- 該当の請求書データが存在する場合、警告終了
        IF ( l_ap_invoices_tab.COUNT >= 1 ) THEN
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => '経費精算書番号：' || gv_invoice_num || 'は、既にAP請求書データが作成されています。'
          );
          RAISE data_warn_expt;
        ELSE
          -- ===============================================
          -- 経費精算書明細情報抽出処理
          -- ===============================================
          -- 経費精算書明細カーソル
          OPEN l_exp_rep_lines_cur;
          FETCH l_exp_rep_lines_cur BULK COLLECT INTO l_exp_rep_lines_tab;
          CLOSE l_exp_rep_lines_cur;
          --
          <<lines_loop>>
          FOR j IN 1 .. l_exp_rep_lines_tab.COUNT LOOP
            IF ( lv_head_data_output_flg = 'N' ) THEN
              -- 経費精算書ヘッダ値がCSVに未出力(=N)の場合、ヘッダ値の出力を行う
              -- 見出し
              fnd_file.put_line(
                 which  => FND_FILE.OUTPUT
                ,buff   => '"経費精算書ヘッダ削除対象"'
              );
              -- 項目名
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
              -- 項目値
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
              -- CSV出力済フラグをY(出力済)に設定する
              lv_head_data_output_flg := 'Y';
            END IF;
            -- 明細値出力
            -- 見出し
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => '"経費精算書明細削除対象"'
            );
            -- 項目名
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
            -- 項目値
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
            -- 削除件数カウント
            gn_lines_del_cnt := gn_lines_del_cnt + 1;
          END LOOP lines_loop;
--
          -- CSV出力済フラグをY(出力済)に設定する
          lv_head_data_output_flg := 'Y';
--
          IF ( gv_exe_mode = '1' ) THEN
            -- パラメータ：実行モードが1(データ更新)の場合のみ削除処理を行う
            -- ===============================================
            -- 削除処理
            -- ===============================================
            -- 経費精算書明細削除
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
                -- *** データ削除エラー ***
                WHEN OTHERS THEN
                  -- 削除件数カウントクリア
                  gn_lines_del_cnt := 0;
                  --
                  ov_errmsg  := '削除処理に失敗しました。【経費精算書明細】report_header_id：' || gv_invoice_num;
                  ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
                  RAISE err_delete_expt;
              END;
            END IF;
--
            -- 経費精算書ヘッダ削除
            BEGIN
              DELETE FROM apps.ap_expense_report_headers_all
              WHERE invoice_num = gv_invoice_num
              ;
              -- 削除件数カウント
              gn_head_del_cnt := gn_head_del_cnt + 1;
              -- 正常件数カウント
              gn_normal_cnt := gn_normal_cnt + 1;
              --
            EXCEPTION
              -- *** データ削除エラー ***
              WHEN OTHERS THEN
                -- 削除件数カウントクリア
                gn_lines_del_cnt := 0;
                --
                ov_errmsg  := '削除処理に失敗しました。【経費精算書ヘッダ】report_header_id：' || gv_invoice_num;
                ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
                RAISE err_delete_expt;
            END;
          END IF;
          -- 対象件数
          gn_target_cnt := gn_target_cnt + 1;
        END IF;
--
      ELSE
        -- 対象の経費精算書番号が未承認の場合、警告終了する
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => '経費精算書番号：' || gv_invoice_num || 'は未承認です。' ||
                     '（SOURCE：' || l_exp_rep_head_tab( i ).source ||
                     ' WORKFLOW_APPROVED_FLAG：' || l_exp_rep_head_tab( i ).workflow_approved_flag ||
                     ' EXPENSE_STATUS_CODE：' || l_exp_rep_head_tab( i ).expense_status_code || '）'
        );
        RAISE data_warn_expt;
      END IF;
    END LOOP head_loop;
--
--
  EXCEPTION
    -- *** 入力パラメータ例外ハンドラ ***
    WHEN err_prm_expt THEN
      ov_retcode := cv_status_error;
      -- 異常件数カウント
      gn_error_cnt := gn_error_cnt + 1;
--
    -- *** 警告例外ハンドラ ***
    WHEN data_warn_expt THEN
      ov_retcode := cv_status_warn;
      -- スキップ件数カウント
      gn_warn_cnt := gn_warn_cnt + 1;
--
    -- *** 削除処理例外ハンドラ ***
    WHEN err_delete_expt THEN
      ov_retcode := cv_status_error;
      -- 異常件数カウント
      gn_error_cnt := gn_error_cnt + 1;
--
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- 異常件数カウント
      gn_error_cnt := gn_error_cnt + 1;
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      -- 異常件数カウント
      gn_error_cnt := gn_error_cnt + 1;
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      -- 異常件数カウント
      gn_error_cnt := gn_error_cnt + 1;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      -- 異常件数カウント
      gn_error_cnt := gn_error_cnt + 1;
--
--
--####################################  固定部 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf         OUT VARCHAR2,       --   エラー・メッセージ  --# 固定 #
    retcode        OUT VARCHAR2,       --   リターン・コード    --# 固定 #
    iv_invoice_num IN  VARCHAR2,       --   経費精算書番号
    iv_exe_mode    IN  VARCHAR2        --   実行モード(0:対象確認、1:データ更新)
  )
--
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- プログラム名
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);     -- リターン・コード
    lv_errmsg          VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code    VARCHAR2(100);   -- 終了メッセージコード
    lv_outmsg          VARCHAR2(5000) DEFAULT NULL; -- 出力用メッセージ
    lb_retcode         BOOLEAN        DEFAULT TRUE; -- メッセージ出力関数戻り値
    --
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
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
--###########################  固定部 END   #############################
--
    -- パラメータをグローバル変数に設定
    gv_invoice_num := iv_invoice_num;
    gv_exe_mode    := iv_exe_mode;
    -- プログラム入力項目を出力
    -- 経費精算書番号
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '経費精算書番号：' || gv_invoice_num
    );
    -- 実行モード
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '実行モード：' || gv_exe_mode
    );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => NULL --改行
    );
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --実行モードが0:対象確認の場合、カウントした削除件数を初期化する
    IF ( gv_exe_mode = 0 ) THEN
      gn_head_del_cnt  := 0;
      gn_lines_del_cnt := 0;
    END IF;
    --
    --削除件数出力(経費精算書ヘッダテーブル)
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '削除件数  ：  ' || gn_head_del_cnt || '件  ( 経費精算書ヘッダテーブル )'
    );
    --
    --削除件数出力(経費精算書明細テーブル)
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '削除件数  ：  ' || gn_lines_del_cnt || '件  ( 経費精算書明細テーブル )'
    );
    --
    --対象件数出力
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
    --成功件数出力
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
    --エラー件数出力
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
    --スキップ件数出力
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
    --終了メッセージ
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
      gv_out_msg := '処理がエラー終了しました。';
    END IF;
    --
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCCP007A06C;
/
