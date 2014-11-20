CREATE OR REPLACE PACKAGE BODY XX03PVI001C
AS
/*****************************************************************************************
 *
 * Copyright(c)Oracle Corporation Japan, 2003. All rights reserved.
 *
 * Package Name     : XX03PVI001C(body)
 * Description      : 仕入先ｲﾝﾀｰﾌｪｰｽﾃｰﾌﾞﾙにセットされている情報を、仕入先マスタ、
 *                    仕入先サイトマスタ、銀行口座マスタ、銀行口座割当テーブルへ登録を行う。
 * MD.050(CMD.040)  : 仕入先ｲﾝﾀｰﾌｪｰｽ      <B_P_MD050_DVL_009>
 * MD.070(CMD.050)  : 仕入先ｲﾝﾀｰﾌｪｰｽ(PVI) <B_P_MD070_DVL_013>
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  chk_param              パラメータのチェック(A-1)
 *  get_option_data        各種データの取得(A-2)
 *  valid_data             仕入先データの妥当性チェック(A-4)
 *  upd_vendors            仕入先マスタへの登録(A-5)
 *  upd_vendor_sites       仕入先サイトマスタへの登録(A-6)
 *  upd_bank_accounts      銀行口座マスタへの登録･更新(A-7)
 *  upd_bank_account_uses  銀行口座割当ﾃｰﾌﾞﾙへの登録･更新(A-8)
 *  upd_ift                仕入先インターフェーステーブルの更新(A-9)
 *  main_loop              仕入先データ抽出(A-3)
 *  del_ift                インポート成功データ削除(A-10)
 *  msg_processed_data     メッセージ出力(A-11)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ----------- ------------- ------------ -------------------------------------------------
 *  Date        Ver.          Editor       Description
 * ----------- ------------- ------------ -------------------------------------------------
 *  2003.05.14  1.0           H.TANIGAWA   新規
 *  2004.08.20  1.1           MATSUMURA    仕入先サイト購買フラグ追加(IFテーブルも変更)
 *  2006.06.10  11.5.10.1.3   MATSUMURA    仕入先サイト、銀行口座のORG対応
 *  2009.04.24  1.2           マスタＴＭ   バグ対応（出荷先事業所の強制）
 *****************************************************************************************/
--
--#####################  固定共通例外宣言部 START   ####################
--
  --*** 処理部共通例外 ***
  global_process_expt       EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt           EXCEPTION;
--
--###########################  固定部 END   ############################
--
  -- ===============================
  -- ユーザー定義宣言部
  -- ===============================
--
    -- *** グローバル定数 ***
    cv_msg_appl_name          CONSTANT VARCHAR2(100) := 'XXIF';

    -- *** パッケージカーソル ***
    --会計オプションデータ取得カーソル
    CURSOR financials_cur
    IS
      SELECT user_defined_vendor_num_code,
             ship_to_location_id,
             bill_to_location_id,
             ship_via_lookup_code,
             freight_terms_lookup_code,
             fob_lookup_code,
             terms_id,
             always_take_disc_flag,
             invoice_currency_code,
             payment_currency_code,
             payment_method_lookup_code,
             exclusive_payment_flag,
             hold_unmatched_invoices_flag,
             match_option,
             tax_rounding_rule,
             accts_pay_code_combination_id,
             future_dated_payment_ccid
      FROM   financials_system_parameters;
--
    --# 買掛管理オプション取得カーソル
    CURSOR payables_cur
    IS
      SELECT pay_date_basis_lookup_code,
             terms_date_basis,
             auto_tax_calc_flag,
             auto_tax_calc_override,
             amount_includes_tax_flag,
             bank_charge_bearer,
             gain_code_combination_id,
             loss_code_combination_id,
             max_outlay,
             multi_currency_flag
      FROM   ap_system_parameters;
    --# 受入オプションカーソル
    CURSOR rcv_parameters_cur(
      in_c_org_id IN rcv_parameters.organization_id%TYPE)
    IS
      SELECT qty_rcv_tolerance,
             days_early_receipt_allowed,
             days_late_receipt_allowed,
             enforce_ship_to_location_code,
             receiving_routing_id,
             receipt_days_exception_code,
             qty_rcv_exception_code,
             allow_substitute_receipts_flag,
             allow_unordered_receipts_flag
      FROM   rcv_parameters
      WHERE  organization_id = in_c_org_id;
--
    --# vendor_interface_cur(対象データ取得カーソル)
    CURSOR vendor_interface_cur(
      iv_force_flag   IN  VARCHAR2)
    IS
      SELECT xvi.ROWID,
             xvi.vendors_interface_id,
             UPPER(xvi.insert_update_flag) insert_update_flag,
             xvi.vndr_vendor_id,
             xvi.vndr_vendor_name,
             xvi.vndr_segment1,
             xvi.vndr_employee_id,
             xvi.vndr_vendor_type_lkup_code,
             xvi.vndr_terms_id,
             xvi.vndr_pay_group_lkup_code,
             xvi.vndr_invoice_amount_limit,
             xvi.vndr_accts_pay_ccid,
             xvi.vndr_prepay_ccid,
             xvi.vndr_end_date_active,
             UPPER(xvi.vndr_small_business_flag) vndr_small_business_flag,
             UPPER(xvi.vndr_receipt_required_flag) vndr_receipt_required_flag,
             xvi.vndr_attribute_category,
             xvi.vndr_attribute1,
             xvi.vndr_attribute2,
             xvi.vndr_attribute3,
             xvi.vndr_attribute4,
             xvi.vndr_attribute5,
             xvi.vndr_attribute6,
             xvi.vndr_attribute7,
             xvi.vndr_attribute8,
             xvi.vndr_attribute9,
             xvi.vndr_attribute10,
             xvi.vndr_attribute11,
             xvi.vndr_attribute12,
             xvi.vndr_attribute13,
             xvi.vndr_attribute14,
             xvi.vndr_attribute15,
             UPPER(xvi.vndr_allow_awt_flag) vndr_allow_awt_flag,
             xvi.vndr_vendor_name_alt,
             UPPER(xvi.vndr_ap_tax_rounding_rule) vndr_ap_tax_rounding_rule,
             UPPER(xvi.vndr_auto_tax_calc_flag) vndr_auto_tax_calc_flag,
             UPPER(xvi.vndr_auto_tax_calc_override) vndr_auto_tax_calc_override,
             xvi.vndr_bank_charge_bearer,
             xvi.site_vendor_site_id,
             xvi.site_vendor_site_code,
             xvi.site_address_line1,
             xvi.site_address_line2,
             xvi.site_address_line3,
             xvi.site_city,
             xvi.site_state,
             xvi.site_zip,
             xvi.site_province,
             xvi.site_country,
             xvi.site_area_code,
             xvi.site_phone,
             xvi.site_fax,
             xvi.site_fax_area_code,
             xvi.site_payment_method_lkup_code,
             xvi.site_bank_account_name,
             xvi.site_bank_account_num,
             abb.bank_num site_bank_num,
             xvi.site_bank_account_type,
             xvi.site_vat_code,
             xvi.site_distribution_set_id,
             xvi.site_accts_pay_ccid,
             xvi.site_prepay_ccid,
             xvi.site_pay_group_lkup_code,
             xvi.site_terms_id,
             xvi.site_invoice_amount_limit,
             xvi.site_attribute_category,
             xvi.site_attribute1,
             xvi.site_attribute2,
             xvi.site_attribute3,
             xvi.site_attribute4,
             xvi.site_attribute5,
             xvi.site_attribute6,
             xvi.site_attribute7,
             xvi.site_attribute8,
             xvi.site_attribute9,
             xvi.site_attribute10,
             xvi.site_attribute11,
             xvi.site_attribute12,
             xvi.site_attribute13,
             xvi.site_attribute14,
             xvi.site_attribute15,
             abb.bank_number site_bank_number,
             xvi.site_address_line4,
             xvi.site_county,
             UPPER(xvi.site_allow_awt_flag) site_allow_awt_flag,
             xvi.site_awt_group_id,
             xvi.site_vendor_site_code_alt,
             xvi.site_address_lines_alt,
             UPPER(xvi.site_ap_tax_rounding_rule) site_ap_tax_rounding_rule,
             UPPER(xvi.site_auto_tax_calc_flag) site_auto_tax_calc_flag,
             UPPER(xvi.site_auto_tax_calc_override) site_auto_tax_calc_override,
             xvi.site_bank_charge_bearer,
             xvi.site_bank_branch_type,
             UPPER(xvi.site_create_debit_memo_flag) site_create_debit_memo_flag,
             UPPER(xvi.site_supplier_notif_method) site_supplier_notif_method,
             xvi.site_email_address,
             UPPER(xvi.site_primary_pay_site_flag) site_primary_pay_site_flag,
             --松村修正
             UPPER(xvi.site_purchasing_site_flag) site_purchasing_site_flag,
             --松村修正end
             --畠山修正
             --xvi.acnt_bank_name,
             abb.bank_name acnt_bank_name,
             --畠山修正
             --xvi.acnt_bank_branch_name,
             abb.bank_branch_name acnt_bank_branch_name,
             xvi.acnt_bank_account_name,
             xvi.acnt_bank_account_num,
             xvi.acnt_currency_code,
             xvi.acnt_description,
             xvi.acnt_asset_id,
             xvi.acnt_bank_account_type,
             xvi.acnt_attribute_category,
             xvi.acnt_attribute1,
             xvi.acnt_attribute2,
             xvi.acnt_attribute3,
             xvi.acnt_attribute4,
             xvi.acnt_attribute5,
             xvi.acnt_attribute6,
             xvi.acnt_attribute7,
             xvi.acnt_attribute8,
             xvi.acnt_attribute9,
             xvi.acnt_attribute10,
             xvi.acnt_attribute11,
             xvi.acnt_attribute12,
             xvi.acnt_attribute13,
             xvi.acnt_attribute14,
             xvi.acnt_attribute15,
             xvi.acnt_cash_clearing_ccid,
             xvi.acnt_bank_charges_ccid,
             xvi.acnt_bank_errors_ccid,
             xvi.acnt_account_holder_name,
             xvi.acnt_account_holder_name_alt,
             xvi.uses_start_date,
             xvi.uses_end_date,
             xvi.uses_attribute_category,
             xvi.uses_attribute1,
             xvi.uses_attribute2,
             xvi.uses_attribute3,
             xvi.uses_attribute4,
             xvi.uses_attribute5,
             xvi.uses_attribute6,
             xvi.uses_attribute7,
             xvi.uses_attribute8,
             xvi.uses_attribute9,
             xvi.uses_attribute10,
             xvi.uses_attribute11,
             xvi.uses_attribute12,
             xvi.uses_attribute13,
             xvi.uses_attribute14,
             xvi.uses_attribute15
      FROM   xx03_vendors_interface xvi,
             ap_bank_branches abb
      WHERE  xvi.status_flag = iv_force_flag
      --畠山修正
      --AND    xvi.site_bank_name = abb.bank_name(+)
      --ymatsumu修正
      --AND    xvi.acnt_bank_number = abb.bank_num(+)
      AND    NVL(xvi.acnt_bank_number,xvi.site_bank_number) = abb.bank_num(+)
      --畠山修正
      --AND    xvi.site_bank_branch_name = abb.bank_branch_name(+)
      --ymatsumu修正
      --AND    xvi.acnt_bank_num = abb.bank_number(+)
      AND    NVL(xvi.acnt_bank_num,xvi.site_bank_num) = abb.bank_number(+)
      ORDER BY xvi.vendors_interface_id
      FOR UPDATE NOWAIT;
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
    chk_param_expt           EXCEPTION;  --パラメータチェックエラー
    get_option_data_expt     EXCEPTION;  --各種データ取得失敗
    valid_data_expt          EXCEPTION;  --妥当性チェックエラー
    upd_vendors_expt         EXCEPTION;  --仕入先マスタデータ更新失敗
    upd_vendor_sites_expt    EXCEPTION;  --仕入先サイトマスタデータ更新失敗
    upd_bank_accounts_expt   EXCEPTION;  --銀行口座マスタデータ更新失敗
    upd_bank_acnt_uses_expt  EXCEPTION;  --銀行口座割当データ更新失敗
    upd_ift_expt             EXCEPTION;  --仕入先インターフェーステーブル更新失敗
    del_ift_expt             EXCEPTION;  --インポート成功データ削除失敗
--
--
  /**********************************************************************************
   * Procedure Name   : chk_param
   * Description      : パラメータのチェック(A-1)
   ***********************************************************************************/
  PROCEDURE chk_param(
    iv_force_flag         IN  VARCHAR2,  -- 1.強制フラグ
    iv_start_date_active  IN  VARCHAR2,  -- 2.業務日付
    od_start_date_active  OUT DATE,      -- 3.業務日付（2のパラメータををDATE型に変換したもの）
    ov_errbuf             OUT VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg             OUT VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_param'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
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
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --# 強制フラグのチェック
    IF (iv_force_flag IS NULL) THEN
      RAISE chk_param_expt;
    END IF;
    --# 業務日付のチェック
    IF (iv_start_date_active IS NULL) THEN
      od_start_date_active := xx00_date_pkg.get_system_datetime_f;
    ELSE
      BEGIN
        od_start_date_active := TO_DATE(iv_start_date_active);
      EXCEPTION
        WHEN OTHERS THEN
          lv_retcode := xx00_common_pkg.set_status_error_f;
      END;
      IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
        RAISE chk_param_expt;
      END IF;
    END IF;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN chk_param_expt THEN                 --*** パラメータチェック失敗時 ***
      -- *** 任意で例外処理を記述する ****
      lv_errmsg := xx00_message_pkg.get_msg(cv_msg_appl_name,
                                            'APP-XX03-00009');
      --エラーメッセージをコピー
      lv_errbuf := lv_errmsg;
      -------------------------------------------------------
      ov_errmsg := lv_errmsg;                                                           --# 任意 #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# 任意 #
      ov_retcode := xx00_common_pkg.set_status_error_f;                                 --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_api_expt THEN   -- *** 共通関数例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  固定部 END   ##########################################
--
  END chk_param;
--
--
  /**********************************************************************************
   * Procedure Name   : get_option_data
   * Description      : 各種データの取得(A-2)
   ***********************************************************************************/
  PROCEDURE get_option_data(
    financials_rec   OUT  financials_cur%ROWTYPE,      -- 1.会計オプションデータ
    payables_rec     OUT  payables_cur%ROWTYPE,        -- 2.買掛管理オプションデータ
    receipts_rec     OUT  rcv_parameters_cur%ROWTYPE,  -- 3.受入オプションデータ
    ot_chart_of_accounts_id OUT gl_sets_of_books.chart_of_accounts_id%TYPE,  -- 4.勘定体系ID
    on_set_of_books_id      OUT NUMBER, -- 5.会計帳簿ID
    ov_errbuf        OUT VARCHAR2,      -- エラー・メッセージ           --# 固定 #
    ov_retcode       OUT VARCHAR2,      -- リターン・コード             --# 固定 #
    ov_errmsg        OUT VARCHAR2)      -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_option_data'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
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
    ln_org_id                NUMBER;   --組織ID
    lt_currency              gl_sets_of_books.currency_code%TYPE;         --通貨コード
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --# 組織IDの取得
    xx00_profile_pkg.get('ORG_ID',ln_org_id);
    --# 会計帳簿IDの取得
    xx00_profile_pkg.get('GL_SET_OF_BKS_ID',on_set_of_books_id);
    --# 組織IDの設定
    xx00_client_info_pkg.set_org_context(ln_org_id);
    --# 会計オプションデータ取得
    OPEN financials_cur;
    FETCH financials_cur INTO financials_rec;
    IF (financials_cur%NOTFOUND) THEN
       CLOSE financials_cur;
       RAISE get_option_data_expt;
    END IF;
    CLOSE financials_cur;
    --# 買掛管理オプションデータ取得
    OPEN payables_cur;
    FETCH payables_cur INTO payables_rec;
    IF (payables_cur%NOTFOUND) THEN
       CLOSE payables_cur;
       RAISE get_option_data_expt;
    END IF;
    CLOSE payables_cur;
    --# 受入オプションデータ取得
    OPEN rcv_parameters_cur(ln_org_id);
    FETCH rcv_parameters_cur INTO receipts_rec;
    CLOSE rcv_parameters_cur;
    --# 勘定体系ID、通貨コードの取得
    BEGIN
      SELECT chart_of_accounts_id,
             currency_code
      INTO   ot_chart_of_accounts_id,
             lt_currency
      FROM   gl_sets_of_books
      WHERE  set_of_books_id = on_set_of_books_id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_retcode := xx00_common_pkg.set_status_error_f;
    END;
    IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
      RAISE get_option_data_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN get_option_data_expt THEN             --*** 各種データ取得失敗時 ***
      -- *** 任意で例外処理を記述する ****
      lv_errmsg := xx00_message_pkg.get_msg(cv_msg_appl_name,
                                           'APP-XX03-00010');
      --エラーメッセージをコピー
      lv_errbuf := lv_errmsg;
      -------------------------------------------------------
      ov_errmsg := lv_errmsg;                                                           --# 任意 #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# 任意 #
      ov_retcode := xx00_common_pkg.set_status_error_f;                                 --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_api_expt THEN   -- *** 共通関数例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  固定部 END   ##########################################
--
  END get_option_data;
--
--
  /**********************************************************************************
   * Procedure Name   : valid_data
   * Description      : 仕入先データの妥当性チェック(A-4)
   ***********************************************************************************/
  PROCEDURE valid_data(
    vendor_interface_rec     IN  vendor_interface_cur%ROWTYPE,  -- 1.仕入先データ
    financials_rec           IN  financials_cur%ROWTYPE,        -- 2.会計オプションデータ
    iv_force_flag            IN  VARCHAR2,    -- 3.強制フラグ
    id_start_date_active     IN  DATE,        -- 4.業務日付
    it_chart_of_accounts_id  IN  gl_sets_of_books.chart_of_accounts_id%TYPE,  -- 5.勘定体系ID
    ov_process_mode          OUT VARCHAR2,    -- 1.追加/更新モード
    ov_interface_errcode     OUT VARCHAR2,    -- 2.エラー理由コード
    ov_errbuf                OUT VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg                OUT VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'valid_data'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
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
    ln_wk_cnt   NUMBER;  --カウントのためのワーク変数
    --Ver11.5.10.1.3 2005.06.10 add START
    ln_org_id   NUMBER;
    --Ver11.5.10.1.3 2005.06.10 add END
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    --Ver11.5.10.1.3 2005.06.10 add START
    --# 組織IDの取得
    xx00_profile_pkg.get('ORG_ID',ln_org_id);
    --Ver11.5.10.1.3 2005.06.10 add END
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --==============================================================
    -- 追加/更新モードのチェック
    --==============================================================
    IF (vendor_interface_rec.insert_update_flag = 'I')
      AND (vendor_interface_rec.vndr_vendor_id IS NULL)
      AND (vendor_interface_rec.site_vendor_site_id IS NULL)
    THEN
      ov_process_mode := '1';
    ELSIF (vendor_interface_rec.insert_update_flag='I')
      AND (vendor_interface_rec.vndr_vendor_id IS NOT NULL)
      AND (vendor_interface_rec.site_vendor_site_id IS NULL)
    THEN
      ov_process_mode := '2';
    ELSIF (vendor_interface_rec.insert_update_flag='U')
      AND (vendor_interface_rec.vndr_vendor_id IS NOT NULL)
      AND (vendor_interface_rec.site_vendor_site_id IS NOT NULL)
    THEN
      ov_process_mode := '3';
    ELSIF (vendor_interface_rec.insert_update_flag='U')
      AND (vendor_interface_rec.vndr_vendor_id IS NOT NULL)
      AND (vendor_interface_rec.site_vendor_site_id IS NULL)
    THEN
      ov_process_mode := '4';
    ELSE
      ov_interface_errcode := '010';
      RAISE valid_data_expt;
    END IF;
--
    --==============================================================
    -- 仕入先情報に関するチェック
    --==============================================================
    --# 仕入先ID(vndr_vendor_id) 存在チェック
    IF (ov_process_mode IN ('2','3','4')) THEN
      SELECT COUNT(*)
      INTO   ln_wk_cnt
      FROM   po_vendors
      WHERE  vendor_id = vendor_interface_rec.vndr_vendor_id;
      IF (ln_wk_cnt = 0) THEN
        ov_interface_errcode := '060';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# 仕入先名(vndr_vendor_name) NULLチェック
    IF (ov_process_mode IN ('1','3','4')) THEN
      IF (vendor_interface_rec.vndr_vendor_name IS NULL) THEN
        ov_interface_errcode := '070';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# 仕入先名(vndr_vendor_name) 重複チェック
    IF (ov_process_mode IN ('1','3','4')) THEN
      SELECT COUNT(*)
      INTO   ln_wk_cnt
      FROM   po_vendors pv
      WHERE  (vendor_interface_rec.vndr_vendor_id IS NULL 
              OR vendor_interface_rec.vndr_vendor_id != pv.vendor_id)
      AND    pv.vendor_name = vendor_interface_rec.vndr_vendor_name;
      IF (ln_wk_cnt > 0) THEN
        ov_interface_errcode := '080';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# (user_defined_vendor_num_code) NULLチェック
    IF (financials_rec.user_defined_vendor_num_code <> 'AUTOMATIC')
      AND (ov_process_mode IN ('1','3','4')) 
    THEN
      IF (vendor_interface_rec.vndr_segment1 IS NULL) THEN
         ov_interface_errcode := '090';
         RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# 仕入先番号(vndr_segment1) 重複チェック
    IF (financials_rec.user_defined_vendor_num_code <> 'AUTOMATIC')
      AND (ov_process_mode IN ('1','3','4'))
    THEN
      SELECT COUNT(*)
      INTO   ln_wk_cnt
      FROM   po_vendors pv
      WHERE  (vendor_interface_rec.vndr_vendor_id IS NULL 
              OR vendor_interface_rec.vndr_vendor_id != pv.vendor_id)
      AND    pv.segment1 = vendor_interface_rec.vndr_segment1;
      IF (ln_wk_cnt > 0) THEN
        ov_interface_errcode := '100';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# 仕入先タイプ(vndr_vendor_type_lkup_code) のチェック
    IF (ov_process_mode IN ('1','3','4'))
      AND (vendor_interface_rec.vndr_vendor_type_lkup_code IS NOT NULL)
    THEN
      IF NOT (xx03_vendor_if_validate_pkg.check_lookup_code(
                'VENDOR TYPE',
                vendor_interface_rec.vndr_vendor_type_lkup_code,
                id_start_date_active))
      THEN
        ov_interface_errcode := '040';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# 従業員ID(employee_id) のチェック
    IF (vendor_interface_rec.vndr_employee_id IS NOT NULL)
      AND (ov_process_mode = '1')
    THEN
      SELECT COUNT(*)
      INTO   ln_wk_cnt
      FROM   hr_employees_current_v hec_v
      WHERE  hec_v.employee_id = vendor_interface_rec.vndr_employee_id;
      IF (ln_wk_cnt = 0) THEN
        ov_interface_errcode := '020';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# 従業員ID(employee_id) のチェック２
    IF (vendor_interface_rec.vndr_employee_id IS NOT NULL)
      AND (ov_process_mode = '1')
    THEN
      SELECT COUNT(*)
      INTO   ln_wk_cnt
      FROM   po_vendors pv
      WHERE  (vendor_interface_rec.vndr_vendor_id IS NULL 
             OR pv.vendor_id != vendor_interface_rec.vndr_vendor_id)
      AND    pv.employee_id = vendor_interface_rec.vndr_employee_id;
      IF (ln_wk_cnt > 0) THEN
        ov_interface_errcode := '030';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# 支払条件(vndr_terms_id) のチェック
    IF (ov_process_mode IN ('1','3','4'))
      AND (vendor_interface_rec.vndr_terms_id IS NOT NULL)
    THEN
      IF NOT (xx03_vendor_if_validate_pkg.check_term_id(vendor_interface_rec.vndr_terms_id,
                                                   id_start_date_active)) 
      THEN
        ov_interface_errcode := '110';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# 支払グループコード(vndr_pay_group_lkup_code) のチェック
    IF (ov_process_mode IN ('1','3','4'))
      AND (vendor_interface_rec.vndr_pay_group_lkup_code IS NOT NULL)
    THEN
      IF NOT (xx03_vendor_if_validate_pkg.check_lookup_code(
--畠山修正
--              'PAY_GROUP',
                'PAY GROUP',
                vendor_interface_rec.vndr_pay_group_lkup_code,
                id_start_date_active))
      THEN
        ov_interface_errcode := '120';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# 負債勘定科目ID(vndr_accts_pay_ccid) のチェック
    IF (ov_process_mode IN ('1','3','4'))
      AND (vendor_interface_rec.vndr_accts_pay_ccid IS NOT NULL)
    THEN
      --勘定科目組合せのチェック
      IF (NOT fnd_flex_keyval.validate_ccid('SQLGL',
                                            'GL#',
                                            it_chart_of_accounts_id,
                                            vendor_interface_rec.vndr_accts_pay_ccid,
                                            'ALL',
                                            NULL,
                                            NULL,
                                            'IGNORE',
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL))
      THEN
        ov_interface_errcode := '130';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# 前払/仮払い勘定科目ID(vndr_prepay_ccid) のチェック
    IF (ov_process_mode IN ('1','3','4'))
      AND (vendor_interface_rec.vndr_prepay_ccid IS NOT NULL)
    THEN
      --勘定科目組合せのチェック
      IF (NOT fnd_flex_keyval.validate_ccid('SQLGL',
                                            'GL#',
                                            it_chart_of_accounts_id,
                                            vendor_interface_rec.vndr_prepay_ccid,
                                            'ALL',
                                            NULL,
                                            NULL,
                                            'IGNORE',
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL))
      THEN
        ov_interface_errcode := '140';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
   --# 中小法人ﾌﾗｸﾞ(vndr_small_business_flag) のチェック
   IF (ov_process_mode IN ('1','3','4'))
     AND (vendor_interface_rec.vndr_small_business_flag IS NOT NULL)
   THEN
     IF (vendor_interface_rec.vndr_small_business_flag NOT IN ('Y','N')) THEN
       ov_interface_errcode := '150';
       RAISE valid_data_expt;
     END IF;
   END IF;
--
   --# 入金確認ﾌﾗｸﾞ(vndr_receipt_required_flag) のチェック
   IF (ov_process_mode = '1') 
     AND (vendor_interface_rec.vndr_receipt_required_flag IS NOT NULL)
   THEN
     IF (vendor_interface_rec.vndr_receipt_required_flag NOT IN ('Y','N')) THEN
       ov_interface_errcode := '050';
       RAISE valid_data_expt;
     END IF;
   END IF;
--
   --# 源泉徴収税使用ﾌﾗｸﾞ(vndr_allow_awt_flag) のチェック
   IF (ov_process_mode IN ('1','3','4'))
     AND (vendor_interface_rec.vndr_allow_awt_flag IS NOT NULL)
   THEN
     IF (vendor_interface_rec.vndr_allow_awt_flag NOT IN ('Y','N')) THEN
       ov_interface_errcode := '160';
       RAISE valid_data_expt;
     END IF;
   END IF;
--
   --# 請求税自動計算端数処理規則(vndr_ap_tax_rounding_rule) のチェック
   IF (ov_process_mode IN ('1','3','4'))
     AND (vendor_interface_rec.vndr_ap_tax_rounding_rule IS NOT NULL)
   THEN
     IF (vendor_interface_rec.vndr_ap_tax_rounding_rule NOT IN ('U','D','N')) THEN
       ov_interface_errcode := '170';
       RAISE valid_data_expt;
     END IF;
   END IF;
--
   --# 請求税自動計算計算レベル(vndr_auto_tax_calc_flag) のチェック
   IF (ov_process_mode IN ('1','3','4'))
     AND (vendor_interface_rec.vndr_auto_tax_calc_flag IS NOT NULL)
   THEN
     IF (vendor_interface_rec.vndr_auto_tax_calc_flag NOT IN ('Y','T','L','N')) THEN
       ov_interface_errcode := '180';
       RAISE valid_data_expt;
     END IF;
   END IF;
--
   --# 請求税自動計算上書きの許可ﾌﾗｸﾞ(vndr_auto_tax_calc_override) のチェック
   IF (ov_process_mode IN ('1','3','4'))
     AND (vendor_interface_rec.vndr_auto_tax_calc_override IS NOT NULL)
   THEN
     IF (vendor_interface_rec.vndr_auto_tax_calc_override NOT IN ('Y','N')) THEN
       ov_interface_errcode := '190';
       RAISE valid_data_expt;
     END IF;
   END IF;
--
    --# 銀行手数料負担者(vndr_bank_charge_bearer) のチェック
    IF (ov_process_mode IN ('1','3','4'))
      AND (vendor_interface_rec.vndr_bank_charge_bearer IS NOT NULL)
    THEN
      IF NOT (xx03_vendor_if_validate_pkg.check_lookup_code(
                'BANK CHARGE BEARER',
                vendor_interface_rec.vndr_bank_charge_bearer,
                id_start_date_active))
      THEN
        ov_interface_errcode := '200';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --==============================================================
    -- 仕入先サイト情報に関するチェック
    --==============================================================
    --# 仕入先サイトID(site_vendor_site_id) のチェック
    IF (ov_process_mode = '3') THEN
      SELECT COUNT(*)
      INTO   ln_wk_cnt
      FROM   po_vendor_sites_all pvsa
      WHERE  pvsa.vendor_site_id = vendor_interface_rec.site_vendor_site_id
      AND    pvsa.vendor_id = vendor_interface_rec.vndr_vendor_id;
      IF (ln_wk_cnt = 0) THEN
        ov_interface_errcode := '250';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# 仕入先サイト名(site_vendor_site_code) NULLチェック
    IF (ov_process_mode IN('1','2','3')) THEN
      IF (vendor_interface_rec.site_vendor_site_code IS NULL) THEN
        ov_interface_errcode := '260';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# 仕入先サイト名(site_vendor_site_code) 重複チェック
    IF (ov_process_mode IN ('2','3')) THEN
      SELECT COUNT(*)
      INTO   ln_wk_cnt
      FROM   po_vendor_sites_all pvsa
      WHERE  (vendor_interface_rec.site_vendor_site_id IS NULL 
              OR pvsa.vendor_site_id != vendor_interface_rec.site_vendor_site_id)
      AND    pvsa.vendor_id = vendor_interface_rec.vndr_vendor_id
      AND    pvsa.vendor_site_code = vendor_interface_rec.site_vendor_site_code
    --Ver11.5.10.1.3 2005.06.10 add START
      AND    pvsa.org_id = ln_org_id;
    --Ver11.5.10.1.3 2005.06.10 add START
      IF (ln_wk_cnt > 0) THEN
        ov_interface_errcode := '270';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# 住所･所在地1(site_address_line1) NULLチェック
    IF (ov_process_mode IN ('1','2','3')) THEN
      IF (vendor_interface_rec.site_address_line1 IS NULL) THEN
        ov_interface_errcode := '280';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# 住所･国(site_country) チェック
    IF (ov_process_mode IN ('1','2','3')) THEN
      SELECT COUNT(*)
      INTO   ln_wk_cnt
      FROM   fnd_territories_vl ft_v
      WHERE  ft_v.territory_code = vendor_interface_rec.site_country;
      IF (ln_wk_cnt = 0) THEN
        ov_interface_errcode := '290';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# 支払方法(site_payment_method_lkup_code) のチェック
    IF (ov_process_mode IN ('1','2','3'))
      AND (vendor_interface_rec.site_payment_method_lkup_code IS NOT NULL)
    THEN
      IF NOT (xx03_vendor_if_validate_pkg.check_lookup_code(
                'PAYMENT METHOD',
                vendor_interface_rec.site_payment_method_lkup_code,
                id_start_date_active))
      THEN
        ov_interface_errcode := '300';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# 税コード(site_vat_code) チェック
    IF (ov_process_mode IN ('1','2','3'))
      AND (vendor_interface_rec.site_vat_code IS NOT NULL)
    THEN
      SELECT COUNT(*)
      INTO   ln_wk_cnt
      FROM   fnd_lookup_values_vl lc,
             ap_tax_codes         tc
      WHERE  lc.lookup_type = 'TAX TYPE'
      AND    tc.name = vendor_interface_rec.site_vat_code
      AND    tc.tax_type != 'OFFSET'
      AND    tc.tax_type != 'AWT'
      AND    lc.lookup_code != tc.tax_type
      AND    (TRUNC(id_start_date_active) 
              BETWEEN TRUNC(NVL(lc.start_date_active,id_start_date_active - 1))
              AND TRUNC(NVL(lc.end_date_active,id_start_date_active + 1)))
      AND    lc.enabled_flag = 'Y'
      AND    NVL(tc.enabled_flag,'Y') = 'Y'
      AND    TRUNC(id_start_date_active) < TRUNC(NVL(tc.inactive_date,id_start_date_active + 1));
      IF (ln_wk_cnt = 0) THEN
        ov_interface_errcode := '310';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# 配分セット(site_distribution_set_id) チェック
    IF (ov_process_mode IN ('1','2','3'))
      AND (vendor_interface_rec.site_distribution_set_id IS NOT NULL)
    THEN
      SELECT COUNT(*)
      INTO   ln_wk_cnt
      FROM   ap_distribution_sets ads
      WHERE  ads.distribution_set_id = vendor_interface_rec.site_distribution_set_id
      AND    TRUNC(id_start_date_active) < TRUNC(NVL(ads.inactive_date,id_start_date_active + 1));
      IF (ln_wk_cnt = 0) THEN
        ov_interface_errcode := '320';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# 負債勘定科目(site_accts_pay_ccid) のチェック
    IF (ov_process_mode IN ('1','2'))
      AND (vendor_interface_rec.site_accts_pay_ccid IS NOT NULL)
    THEN
      --勘定科目組合せのチェック
      IF (NOT fnd_flex_keyval.validate_ccid('SQLGL',
                                            'GL#',
                                            it_chart_of_accounts_id,
                                            vendor_interface_rec.site_accts_pay_ccid,
                                            'ALL',
                                            NULL,
                                            NULL,
                                            'IGNORE',
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL))
      THEN
        ov_interface_errcode := '210';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# 前払/仮払金勘定科目ID(site_prepay_ccid) のチェック
    IF (ov_process_mode IN ('1','2'))
      AND (vendor_interface_rec.site_prepay_ccid IS NOT NULL)
    THEN
      --勘定科目組合せのチェック
      IF (NOT fnd_flex_keyval.validate_ccid('SQLGL',
                                            'GL#',
                                            it_chart_of_accounts_id,
                                            vendor_interface_rec.site_prepay_ccid,
                                            'ALL',
                                            NULL,
                                            NULL,
                                            'IGNORE',
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL))
      THEN
        ov_interface_errcode := '220';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# site_pay_group_lkup_code のチェック
    IF (ov_process_mode IN ('1','2','3'))
      AND (vendor_interface_rec.site_pay_group_lkup_code IS NOT NULL)
    THEN
      IF NOT (xx03_vendor_if_validate_pkg.check_lookup_code(
                'PAY GROUP',
                vendor_interface_rec.site_pay_group_lkup_code,
                id_start_date_active))
      THEN
        ov_interface_errcode := '330';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# site_terms_id のチェック
    IF (ov_process_mode IN ('1','2','3'))
      AND (vendor_interface_rec.site_terms_id IS NOT NULL)
    THEN
      IF NOT (xx03_vendor_if_validate_pkg.check_term_id(vendor_interface_rec.site_terms_id,
                                                   id_start_date_active)) 
      THEN
        ov_interface_errcode := '340';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
   --# 源泉徴収税使用フラグ(site_allow_awt_flag) のチェック
   IF (ov_process_mode IN ('1','2','3'))
     AND (vendor_interface_rec.site_allow_awt_flag IS NOT NULL)
   THEN
     IF (vendor_interface_rec.site_allow_awt_flag NOT IN ('Y','N')) THEN
       ov_interface_errcode := '350';
       RAISE valid_data_expt;
     END IF;
   END IF;
--
   --# 源泉徴収税グループ(site_awt_group_id) のチェック
   IF (ov_process_mode IN ('1','2','3'))
     AND (vendor_interface_rec.site_awt_group_id IS NOT NULL)
   THEN
     SELECT COUNT(*)
     INTO   ln_wk_cnt
     FROM   ap_awt_groups aag
     WHERE  aag.group_id = vendor_interface_rec.site_awt_group_id
     AND    TRUNC(id_start_date_active) < TRUNC(NVL(inactive_date,id_start_date_active + 1));
     IF (ln_wk_cnt = 0) THEN
       ov_interface_errcode := '360';
       RAISE valid_data_expt;
     END IF;
   END IF;
--
   --# 請求税自動計算端数処理規則(site_ap_tax_rounding_rule) のチェック
   IF (ov_process_mode IN ('1','2','3'))
     AND (vendor_interface_rec.site_ap_tax_rounding_rule IS NOT NULL)
   THEN
     IF (vendor_interface_rec.site_ap_tax_rounding_rule NOT IN ('U','D','N')) THEN
       ov_interface_errcode := '370';
       RAISE valid_data_expt;
     END IF;
   END IF;
--
   --# 請求税自動計算計算レベル(site_auto_tax_calc_flag) のチェック
   IF (ov_process_mode IN ('1','2','3'))
     AND (vendor_interface_rec.site_auto_tax_calc_flag IS NOT NULL)
   THEN
     IF (vendor_interface_rec.site_auto_tax_calc_flag NOT IN ('Y','T','L','N')) THEN
       ov_interface_errcode := '380';
       RAISE valid_data_expt;
     END IF;
   END IF;
--
   --# 請求税自動計算上書き許可フラグ(site_auto_tax_calc_override) のチェック
   IF (ov_process_mode IN ('1','2','3'))
     AND (vendor_interface_rec.site_auto_tax_calc_override IS NOT NULL)
   THEN
     IF (vendor_interface_rec.site_auto_tax_calc_override NOT IN ('Y','N')) THEN
       ov_interface_errcode := '390';
       RAISE valid_data_expt;
     END IF;
   END IF;
--
    --# 銀行手数料負担者(site_bank_charge_bearer) のチェック
    IF (ov_process_mode IN ('1','2','3'))
      AND (vendor_interface_rec.site_bank_charge_bearer IS NOT NULL)
    THEN
      IF NOT (xx03_vendor_if_validate_pkg.check_lookup_code(
                'BANK CHARGE BEARER',
                vendor_interface_rec.site_bank_charge_bearer,
                id_start_date_active))
      THEN
        ov_interface_errcode := '400';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# 銀行支店タイプ(site_bank_branch_type) のチェック
    IF (ov_process_mode IN ('1','2'))
      AND (vendor_interface_rec.site_bank_branch_type IS NOT NULL)
    THEN
      IF NOT (xx03_vendor_if_validate_pkg.check_lookup_code(
                'BANK BRANCH TYPE',
                vendor_interface_rec.site_bank_branch_type,
                id_start_date_active))
      THEN
        ov_interface_errcode := '230';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
   --# RTS取引デビットメモ作成フラグ(site_create_debit_memo_flag) のチェック
   IF (ov_process_mode IN ('1','2','3'))
     AND (vendor_interface_rec.site_create_debit_memo_flag IS NOT NULL)
   THEN
     IF (vendor_interface_rec.site_create_debit_memo_flag NOT IN ('Y','N')) THEN
       ov_interface_errcode := '410';
       RAISE valid_data_expt;
     END IF;
   END IF;
--
   --# 仕入先通知方法(site_supplier_notif_method) のチェック
   IF (ov_process_mode IN ('1','2','3'))
     AND (vendor_interface_rec.site_supplier_notif_method IS NOT NULL)
   THEN
     IF (vendor_interface_rec.site_supplier_notif_method NOT IN ('PRINT','FAX','EMAIL')) THEN
       ov_interface_errcode := '420';
       RAISE valid_data_expt;
     END IF;
   END IF;
--
   --# 主支払サイトフラグ(site_primary_pay_site_flag) のチェック
   IF (ov_process_mode IN ('1','2'))
     AND (vendor_interface_rec.site_primary_pay_site_flag IS NOT NULL)
   THEN
     IF (vendor_interface_rec.site_primary_pay_site_flag NOT IN ('Y','N')) THEN
       ov_interface_errcode := '240';
       RAISE valid_data_expt;
     END IF;
   END IF;
--
--松村修正(追加)
   --# 購買フラグ(site_purchasing_site_flag) のチェック
   IF (ov_process_mode IN ('1','2'))
     AND (vendor_interface_rec.site_purchasing_site_flag IS NOT NULL)
   THEN
     IF (vendor_interface_rec.site_purchasing_site_flag NOT IN ('Y','N')) THEN
       ov_interface_errcode := '640';
       RAISE valid_data_expt;
     END IF;
   END IF;
--松村修正end
--
    --==============================================================
    -- 銀行口座情報に関するチェック
    --==============================================================
    --# 銀行名(acnt_bank_name) NULLチェック
    IF (ov_process_mode IN('1','2','3')) THEN
      IF (vendor_interface_rec.acnt_bank_name IS NULL) THEN
        ov_interface_errcode := '500';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# 銀行支店名(acnt_bank_branch_name) NULLチェック
    IF (ov_process_mode IN('1','2','3')) THEN
      IF (vendor_interface_rec.acnt_bank_branch_name IS NULL) THEN
        ov_interface_errcode := '510';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# 銀行名、銀行支店名(acnt_bank_name, acnt_bank_branch_name) のチェック
    IF (ov_process_mode IN('1','2','3')) THEN
      SELECT COUNT(*)
      INTO   ln_wk_cnt
      FROM   ap_bank_branches abb
      WHERE  abb.bank_name = vendor_interface_rec.acnt_bank_name
      AND    abb.bank_branch_name = vendor_interface_rec.acnt_bank_branch_name;
      IF (ln_wk_cnt = 0) THEN
        ov_interface_errcode := '520';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# 口座名称(acnt_bank_account_name) NULLチェック
    IF (ov_process_mode IN('1','2','3')) THEN
      IF (vendor_interface_rec.acnt_bank_account_name IS NULL) THEN
        ov_interface_errcode := '530';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# 口座番号(acnt_bank_account_num) NULLチェック
    IF (ov_process_mode IN('1','2','3')) THEN
      IF (vendor_interface_rec.acnt_bank_account_num IS NULL) THEN
        ov_interface_errcode := '430';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# 通貨コード(acnt_currency_code) NULLチェック
    IF (ov_process_mode IN('1','2','3')) THEN
      IF (vendor_interface_rec.acnt_currency_code IS NULL) THEN
        ov_interface_errcode := '540';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# 通貨コード(acnt_currency_code) チェック２
    IF (ov_process_mode IN ('1','2','3'))
      AND (vendor_interface_rec.acnt_currency_code IS NOT NULL)
    THEN
      SELECT COUNT(*)
      INTO   ln_wk_cnt
      FROM   fnd_currencies_vl fc_v
      WHERE  fc_v.currency_code = vendor_interface_rec.acnt_currency_code
      AND    fc_v.enabled_flag = 'Y'
      AND    (TRUNC(id_start_date_active)
              BETWEEN TRUNC(NVL(fc_v.start_date_active,id_start_date_active - 1))
              AND TRUNC(NVL(fc_v.end_date_active,id_start_date_active + 1)));
      IF (ln_wk_cnt = 0) THEN
        ov_interface_errcode := '550';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# 現預金勘定科目ID(acnt_asset_id) のチェック
    IF (ov_process_mode IN ('1','2'))
      AND (vendor_interface_rec.acnt_asset_id IS NOT NULL)
    THEN
      --勘定科目組合せのチェック
      IF (NOT fnd_flex_keyval.validate_ccid('SQLGL',
                                            'GL#',
                                            it_chart_of_accounts_id,
                                            vendor_interface_rec.acnt_asset_id,
                                            'ALL',
                                            NULL,
                                            NULL,
                                            'IGNORE',
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL))
      THEN
        ov_interface_errcode := '450';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# 預金種別(acnt_bank_account_type) NULLチェック
    IF (ov_process_mode IN('1','2','3')) THEN
      IF (vendor_interface_rec.acnt_bank_account_type IS NULL) THEN
        ov_interface_errcode := '460';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# 資金決済勘定科目ID(acnt_cash_clearing_ccid) NULLチェック
    IF (ov_process_mode IN ('1','2'))
      AND (vendor_interface_rec.acnt_cash_clearing_ccid IS NOT NULL)
    THEN
      --勘定科目組合せのチェック
      IF (NOT fnd_flex_keyval.validate_ccid('SQLGL',
                                            'GL#',
                                            it_chart_of_accounts_id,
                                            vendor_interface_rec.acnt_cash_clearing_ccid,
                                            'ALL',
                                            NULL,
                                            NULL,
                                            'IGNORE',
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL))
      THEN
        ov_interface_errcode := '470';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# 銀行手数料勘定科目ID(acnt_bank_charges_ccid) NULLチェック
    IF (ov_process_mode IN ('1','2'))
      AND (vendor_interface_rec.acnt_bank_charges_ccid IS NOT NULL)
    THEN
      --勘定科目組合せのチェック
      IF (NOT fnd_flex_keyval.validate_ccid('SQLGL',
                                            'GL#',
                                            it_chart_of_accounts_id,
                                            vendor_interface_rec.acnt_bank_charges_ccid,
                                            'ALL',
                                            NULL,
                                            NULL,
                                            'IGNORE',
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL))
      THEN
        ov_interface_errcode := '480';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# 銀行エラー勘定科目ID(acnt_bank_errors_ccid) NULLチェック
    IF (ov_process_mode IN ('1','2'))
      AND (vendor_interface_rec.acnt_bank_errors_ccid IS NOT NULL)
    THEN
      --勘定科目組合せのチェック
      IF (NOT fnd_flex_keyval.validate_ccid('SQLGL',
                                            'GL#',
                                            it_chart_of_accounts_id,
                                            vendor_interface_rec.acnt_bank_errors_ccid,
                                            'ALL',
                                            NULL,
                                            NULL,
                                            'IGNORE',
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL))
      THEN
        ov_interface_errcode := '490';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# 口座名義人名かな(acnt_account_holder_name_alt) NULLチェック
    IF (ov_process_mode IN('1','2','3')) THEN
      IF (vendor_interface_rec.acnt_account_holder_name_alt IS NULL) THEN
        ov_interface_errcode := '560';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# 口座名義人名かな(acnt_account_holder_name_alt) チェック
    IF (ov_process_mode IN('1','2','3')) THEN
      IF NOT(xx03_chk_kana_pkg.chk_kana(vendor_interface_rec.acnt_account_holder_name_alt)) THEN
        ov_interface_errcode := '570';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --==============================================================
    -- 銀行口座割当情報に関するチェック
    --==============================================================
    --# 開始日(uses_start_date)、終了日(uses_end_date) のチェック
    IF (ov_process_mode IN ('1','2','3'))
      AND (vendor_interface_rec.uses_start_date IS NOT NULL 
           AND vendor_interface_rec.uses_end_date IS NOT NULL)
    THEN
      IF (vendor_interface_rec.uses_start_date > vendor_interface_rec.uses_end_date) THEN
        ov_interface_errcode := '580';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN valid_data_expt THEN              --*** 妥当性チェック失敗 ***
      -- *** 任意で例外処理を記述する ****
     lv_errbuf := xx00_message_pkg.get_msg(cv_msg_appl_name,
                                           'APP-XX03-00011',
                                           'TOK_XX03_VENDOR_INTERFACE_ID',
                                           vendor_interface_rec.VENDORS_INTERFACE_ID,
                                           'TOK_XX03_INSERT_UPDATE_FLAG',
                                           ov_process_mode,
                                           'TOK_XX03_VENDOR_ID',
                                           vendor_interface_rec.vndr_vendor_id,
                                           'TOK_XX03_VENDOR_NAME',
                                           vendor_interface_rec.vndr_vendor_name,
                                           'TOK_XX03_VENDOR_SITE_ID',
                                           vendor_interface_rec.site_vendor_site_id,
                                           'TOK_XX03_VENDOR_SITE_CODE',
                                           vendor_interface_rec.site_vendor_site_code,
                                           'TOK_XX03_ERROR_REASON',
                                           xx03_get_error_message_pkg.get_error_message(
                                             'XX03_VENDOR_IF_ERROR_REASON',
                                             ov_interface_errcode));
      lv_errmsg := xx00_message_pkg.get_msg(cv_msg_appl_name,
                                           'APP-XX03-00011',
                                           'TOK_XX03_VENDOR_INTERFACE_ID',
                                           vendor_interface_rec.VENDORS_INTERFACE_ID,
                                           'TOK_XX03_INSERT_UPDATE_FLAG',
                                           ov_process_mode,
                                           'TOK_XX03_VENDOR_ID',
                                           vendor_interface_rec.vndr_vendor_id,
                                           'TOK_XX03_VENDOR_NAME',
                                           vendor_interface_rec.vndr_vendor_name,
                                           'TOK_XX03_VENDOR_SITE_ID',
                                           vendor_interface_rec.site_vendor_site_id,
                                           'TOK_XX03_VENDOR_SITE_CODE',
                                           vendor_interface_rec.site_vendor_site_code,
                                           'TOK_XX03_ERROR_REASON',
                                           xx03_get_error_message_pkg.get_error_message(
                                             'XX03_VENDOR_IF_ERROR_REASON',
                                             ov_interface_errcode));
      --------------------------------------------------------------------------------------
      ov_errmsg := lv_errmsg;                                                           --# 任意 #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# 任意 #
      --ステータスを警告で返す
      ov_retcode := xx00_common_pkg.set_status_warn_f;                     --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_api_expt THEN   -- *** 共通関数例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  固定部 END   ##########################################
--
  END valid_data;
--
--
  /**********************************************************************************
   * Procedure Name   : upd_vendors
   * Description      : 仕入先マスタへの登録(A-5)
   ***********************************************************************************/
  PROCEDURE upd_vendors(
    iv_process_mode       IN  VARCHAR2,  -- 1.追加/更新モード
    vendor_interface_rec  IN  vendor_interface_cur%ROWTYPE,  -- 2.仕入先IFTのデータ
    financials_rec        IN  financials_cur%ROWTYPE,        -- 3.会計オプションデータ
    payables_rec          IN  payables_cur%ROWTYPE,          -- 4.買掛管理オプションデータ
    receipts_rec          IN  rcv_parameters_cur%ROWTYPE,    -- 5.受入オプションデータ
    in_set_of_books_id    IN  NUMBER,    -- 6.会計帳簿ID
    id_start_date_active  IN  DATE,      -- 7.業務日付
    or_vendors_rowid      OUT ROWID,                     --ap_vendors_pkg.insert_rowで取得のOUT変数
    ot_vendor_id          OUT po_vendors.vendor_id%TYPE, --upd_vendorsで取得のvendor_id
    ov_interface_errcode  OUT VARCHAR2,  -- エラー理由コード
    ov_errbuf             OUT VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg             OUT VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_vendors'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
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
    lt_wk_segment1   po_vendors.segment1%TYPE;
    lt_wk_vendor_id  po_vendors.vendor_id%TYPE; --ap_vendors_pkg.insert_rowで取得のOUT変数
--
    -- *** ローカル・カーソル ***
    --# 更新対象外列の更新用データ
    CURSOR  upd_vendors_cur(
      vndr_vendor_id IN vendor_interface_rec.vndr_vendor_id%TYPE)
    IS
      SELECT rowidtochar(rowid) char_rowid,
             vendor_id,
             segment1,
             summary_flag,
             enabled_flag,
             employee_id,
             validation_number,
             vendor_type_lookup_code,
             customer_num,
             one_time_flag,
             parent_vendor_id,
             min_order_amount,
             ship_to_location_id,
             bill_to_location_id,
             ship_via_lookup_code,
             freight_terms_lookup_code,
             fob_lookup_code,
             terms_id,
             set_of_books_id,
             always_take_disc_flag,
             pay_date_basis_lookup_code,
             payment_priority,
             invoice_currency_code,
             payment_currency_code,
             hold_all_payments_flag,
             hold_future_payments_flag,
             hold_reason,
             distribution_set_id,
             future_dated_payment_ccid,
             num_1099,
             type_1099,
             withholding_status_lookup_code,
             withholding_start_date,
             organization_type_lookup_code,
             vat_code,
             start_date_active,
             qty_rcv_tolerance,
             minority_group_lookup_code,
             payment_method_lookup_code,
             bank_account_name,
             bank_account_num,
             bank_num,
             bank_account_type,
             women_owned_flag,
             standard_industry_class,
             hold_flag,
             purchasing_hold_reason,
             hold_by,
             hold_date,
             terms_date_basis,
             price_tolerance,
             days_early_receipt_allowed,
             days_late_receipt_allowed,
             enforce_ship_to_location_code,
             exclusive_payment_flag,
             federal_reportable_flag,
             hold_unmatched_invoices_flag,
             match_option,
             create_debit_memo_flag,
             inspection_required_flag,
             receipt_required_flag,
             receiving_routing_id,
             state_reportable_flag,
             tax_verification_date,
             auto_calculate_interest_flag,
             name_control,
             allow_substitute_receipts_flag,
             allow_unordered_receipts_flag,
             receipt_days_exception_code,
             qty_rcv_exception_code,
             offset_tax_flag,
             exclude_freight_from_discount,
             vat_registration_num,
             tax_reporting_name,
             awt_group_id,
             check_digits,
             bank_number,
             bank_branch_type,
             edi_payment_method,
             edi_payment_format,
             edi_remittance_method,
             edi_remittance_instruction,
             edi_transaction_handling,
             amount_includes_tax_flag,
             global_attribute_category,
             global_attribute1,
             global_attribute2,
             global_attribute3,
             global_attribute4,
             global_attribute5,
             global_attribute6,
             global_attribute7,
             global_attribute8,
             global_attribute9,
             global_attribute10,
             global_attribute11,
             global_attribute12,
             global_attribute13,
             global_attribute14,
             global_attribute15,
             global_attribute16,
             global_attribute17,
             global_attribute18,
             global_attribute19,
             global_attribute20
      FROM   po_vendors
      WHERE  vendor_id = vndr_vendor_id
      FOR UPDATE NOWAIT;
--
    -- *** ローカル・レコード ***
    upd_vendors_rec    upd_vendors_cur%ROWTYPE;
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    BEGIN
      IF (iv_process_mode = '1') THEN
--
        lt_wk_segment1 := vendor_interface_rec.vndr_segment1;
        --# 追加処理
        ap_vendors_pkg.insert_row(
          or_vendors_rowid,   --OUT変数
          lt_wk_vendor_id,       --OUT変数
          xx00_date_pkg.get_system_datetime_f,
          xx00_global_pkg.last_updated_by,
          vendor_interface_rec.vndr_vendor_name,
          lt_wk_segment1,
          'N',
          'Y',
          xx00_global_pkg.last_update_login,
          xx00_date_pkg.get_system_datetime_f,
          xx00_global_pkg.created_by,
          vendor_interface_rec.vndr_employee_id,
          NULL,
          vendor_interface_rec.vndr_vendor_type_lkup_code,
          NULL,
          'N',
          NULL,
          NULL,
          financials_rec.ship_to_location_id,
          financials_rec.bill_to_location_id,
          financials_rec.ship_via_lookup_code,
          financials_rec.freight_terms_lookup_code,
          financials_rec.fob_lookup_code,
          NVL(vendor_interface_rec.vndr_terms_id,financials_rec.terms_id),
          in_set_of_books_id,
          financials_rec.always_take_disc_flag,
          payables_rec.pay_date_basis_lookup_code,
          vendor_interface_rec.vndr_pay_group_lkup_code,
          99,
          financials_rec.invoice_currency_code,
          financials_rec.payment_currency_code,
          vendor_interface_rec.vndr_invoice_amount_limit,
          'N',
          'N',
          NULL,
          NULL,
          vendor_interface_rec.vndr_accts_pay_ccid,
          NULL,
          vendor_interface_rec.vndr_prepay_ccid,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          id_start_date_active,
          vendor_interface_rec.vndr_end_date_active,
          receipts_rec.qty_rcv_tolerance,   --データなしの場合は、NULL
          NULL,
          financials_rec.payment_method_lookup_code,
          NULL,
          NULL,
          NULL,
          NULL,
          'N',
          vendor_interface_rec.vndr_small_business_flag,
          NULL,
          vendor_interface_rec.vndr_attribute_category,
          vendor_interface_rec.vndr_attribute1,
          vendor_interface_rec.vndr_attribute2,
          vendor_interface_rec.vndr_attribute3,
          vendor_interface_rec.vndr_attribute4,
          vendor_interface_rec.vndr_attribute5,
          'N',
          NULL,
          NULL,
          NULL,
          payables_rec.terms_date_basis,
          NULL,
          vendor_interface_rec.vndr_attribute10,
          vendor_interface_rec.vndr_attribute11,
          vendor_interface_rec.vndr_attribute12,
          vendor_interface_rec.vndr_attribute13,
          vendor_interface_rec.vndr_attribute14,
          vendor_interface_rec.vndr_attribute15,
          vendor_interface_rec.vndr_attribute6,
          vendor_interface_rec.vndr_attribute7,
          vendor_interface_rec.vndr_attribute8,
          vendor_interface_rec.vndr_attribute9,
          receipts_rec.days_early_receipt_allowed,  --データなしの場合はNULL
          receipts_rec.days_late_receipt_allowed,   --データなしの場合はNULL
          receipts_rec.enforce_ship_to_location_code,  --データなしの場合はNULL
          financials_rec.exclusive_payment_flag,
          'N',
          financials_rec.hold_unmatched_invoices_flag,
          financials_rec.match_option,
          NULL,
          'N',
          NVL(vendor_interface_rec.VNDR_RECEIPT_REQUIRED_FLAG,'Y'),
          receipts_rec.receiving_routing_id,   --データなしの場合はNULL
          'N',
          NULL,
          'N',
          NULL,
          receipts_rec.allow_substitute_receipts_flag,  --データなしの場合はNULL
          receipts_rec.allow_unordered_receipts_flag,   --データなしの場合はNULL
          receipts_rec.receipt_days_exception_code,     --データなしの場合はNULL
          receipts_rec.qty_rcv_exception_code,          --データなしの場合はNULL
          'N',
          'N',
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NVL(vendor_interface_rec.vndr_allow_awt_flag,'N'),
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NVL(vendor_interface_rec.vndr_auto_tax_calc_flag,payables_rec.auto_tax_calc_flag),
          NVL(vendor_interface_rec.vndr_auto_tax_calc_override,payables_rec.auto_tax_calc_override),
          payables_rec.amount_includes_tax_flag,
          NVL(vendor_interface_rec.vndr_ap_tax_rounding_rule,financials_rec.tax_rounding_rule),
          vendor_interface_rec.vndr_vendor_name_alt,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NVL(payables_rec.bank_charge_bearer,'I'),
          'XX03PVI001C');
--
          --# OUT変数にap_vendors_pkg.insert_rowで取得のvendor_idをセット
          ot_vendor_id := lt_wk_vendor_id;
--
        ELSIF (iv_process_mode in ('3','4')) THEN
          --# 更新対象レコード取得
          OPEN upd_vendors_cur(vendor_interface_rec.vndr_vendor_id);
          FETCH upd_vendors_cur INTO upd_vendors_rec;
          CLOSE upd_vendors_cur;
          --# 更新用仕入先番号を変数に格納
          IF (financials_rec.user_defined_vendor_num_code <> 'AUTOMATIC') THEN
            lt_wk_segment1 := vendor_interface_rec.vndr_segment1;
          ELSE
            lt_wk_segment1 := upd_vendors_rec.segment1;
          END IF;
          --# 更新処理
          ap_vendors_pkg.update_row(
            upd_vendors_rec.char_rowid,
            vendor_interface_rec.vndr_vendor_id,
            xx00_date_pkg.get_system_datetime_f,
            xx00_global_pkg.last_updated_by,
            vendor_interface_rec.vndr_vendor_name,
            lt_wk_segment1,
            upd_vendors_rec.summary_flag,
            upd_vendors_rec.enabled_flag,
            xx00_global_pkg.last_update_login,
            upd_vendors_rec.employee_id,
            upd_vendors_rec.validation_number,
            upd_vendors_rec.vendor_type_lookup_code,
            upd_vendors_rec.customer_num,
            upd_vendors_rec.one_time_flag,
            upd_vendors_rec.parent_vendor_id,
            upd_vendors_rec.min_order_amount,
            upd_vendors_rec.ship_to_location_id,
            upd_vendors_rec.bill_to_location_id,
            upd_vendors_rec.ship_via_lookup_code,
            upd_vendors_rec.freight_terms_lookup_code,
            upd_vendors_rec.fob_lookup_code,
            NVL(vendor_interface_rec.vndr_terms_id,financials_rec.terms_id),
            upd_vendors_rec.set_of_books_id,
            upd_vendors_rec.always_take_disc_flag,
            upd_vendors_rec.pay_date_basis_lookup_code,
            vendor_interface_rec.vndr_pay_group_lkup_code,
            upd_vendors_rec.payment_priority,
            upd_vendors_rec.invoice_currency_code,
            upd_vendors_rec.payment_currency_code,
            vendor_interface_rec.vndr_invoice_amount_limit,
            upd_vendors_rec.hold_all_payments_flag,
            upd_vendors_rec.hold_future_payments_flag,
            upd_vendors_rec.hold_reason,
            upd_vendors_rec.distribution_set_id,
            vendor_interface_rec.vndr_accts_pay_ccid,
            upd_vendors_rec.future_dated_payment_ccid,
            vendor_interface_rec.vndr_prepay_ccid,
            upd_vendors_rec.num_1099,
            upd_vendors_rec.type_1099,
            upd_vendors_rec.withholding_status_lookup_code,
            upd_vendors_rec.withholding_start_date,
            upd_vendors_rec.organization_type_lookup_code,
            upd_vendors_rec.vat_code,
            id_start_date_active,
            vendor_interface_rec.vndr_end_date_active,
            upd_vendors_rec.qty_rcv_tolerance,
            upd_vendors_rec.minority_group_lookup_code,
            upd_vendors_rec.payment_method_lookup_code,
            upd_vendors_rec.bank_account_name,
            upd_vendors_rec.bank_account_num,
            upd_vendors_rec.bank_num,
            upd_vendors_rec.bank_account_type,
            upd_vendors_rec.women_owned_flag,
            vendor_interface_rec.vndr_small_business_flag,
            upd_vendors_rec.standard_industry_class,
            vendor_interface_rec.vndr_attribute_category,
            vendor_interface_rec.vndr_attribute1,
            vendor_interface_rec.vndr_attribute2,
            vendor_interface_rec.vndr_attribute3,
            vendor_interface_rec.vndr_attribute4,
            vendor_interface_rec.vndr_attribute5,
            upd_vendors_rec.hold_flag,
            upd_vendors_rec.purchasing_hold_reason,
            upd_vendors_rec.hold_by,
            upd_vendors_rec.hold_date,
            upd_vendors_rec.terms_date_basis,
            upd_vendors_rec.price_tolerance,
            vendor_interface_rec.vndr_attribute10,
            vendor_interface_rec.vndr_attribute11,
            vendor_interface_rec.vndr_attribute12,
            vendor_interface_rec.vndr_attribute13,
            vendor_interface_rec.vndr_attribute14,
            vendor_interface_rec.vndr_attribute15,
            vendor_interface_rec.vndr_attribute6,
            vendor_interface_rec.vndr_attribute7,
            vendor_interface_rec.vndr_attribute8,
            vendor_interface_rec.vndr_attribute9,
            upd_vendors_rec.days_early_receipt_allowed,
            upd_vendors_rec.days_late_receipt_allowed,
-- 1.2  Modify 2009/04/24  Bug対応
--            upd_vendors_rec.days_late_receipt_allowed,
            upd_vendors_rec.enforce_ship_to_location_code,
-- End
            upd_vendors_rec.exclusive_payment_flag,
            upd_vendors_rec.federal_reportable_flag,
            upd_vendors_rec.hold_unmatched_invoices_flag,
            upd_vendors_rec.match_option,
            upd_vendors_rec.create_debit_memo_flag,
            upd_vendors_rec.inspection_required_flag,
            upd_vendors_rec.receipt_required_flag,
            upd_vendors_rec.receiving_routing_id,
            upd_vendors_rec.state_reportable_flag,
            upd_vendors_rec.tax_verification_date,
            upd_vendors_rec.auto_calculate_interest_flag,
            upd_vendors_rec.name_control,
            upd_vendors_rec.allow_substitute_receipts_flag,
            upd_vendors_rec.allow_unordered_receipts_flag,
            upd_vendors_rec.receipt_days_exception_code,
            upd_vendors_rec.qty_rcv_exception_code,
            upd_vendors_rec.offset_tax_flag,
            upd_vendors_rec.exclusive_payment_flag,
            upd_vendors_rec.vat_registration_num,
            upd_vendors_rec.tax_reporting_name,
            upd_vendors_rec.awt_group_id,
            upd_vendors_rec.check_digits,
            upd_vendors_rec.bank_number,
            NVL(vendor_interface_rec.vndr_allow_awt_flag,'N'),
            upd_vendors_rec.bank_branch_type,
            upd_vendors_rec.edi_payment_method,
            upd_vendors_rec.edi_payment_format,
            upd_vendors_rec.edi_remittance_method,
            upd_vendors_rec.edi_remittance_instruction,
            upd_vendors_rec.edi_transaction_handling,
            NVL(vendor_interface_rec.vndr_auto_tax_calc_flag,payables_rec.auto_tax_calc_flag),
            NVL(vendor_interface_rec.vndr_auto_tax_calc_override,
                payables_rec.auto_tax_calc_override) ,
            upd_vendors_rec.amount_includes_tax_flag,
            NVL(vendor_interface_rec.vndr_ap_tax_rounding_rule,financials_rec.tax_rounding_rule),
            vendor_interface_rec.vndr_vendor_name_alt,
            upd_vendors_rec.global_attribute_category,
            upd_vendors_rec.global_attribute1,
            upd_vendors_rec.global_attribute2,
            upd_vendors_rec.global_attribute3,
            upd_vendors_rec.global_attribute4,
            upd_vendors_rec.global_attribute5,
            upd_vendors_rec.global_attribute6,
            upd_vendors_rec.global_attribute7,
            upd_vendors_rec.global_attribute8,
            upd_vendors_rec.global_attribute9,
            upd_vendors_rec.global_attribute10,
            upd_vendors_rec.global_attribute11,
            upd_vendors_rec.global_attribute12,
            upd_vendors_rec.global_attribute13,
            upd_vendors_rec.global_attribute14,
            upd_vendors_rec.global_attribute15,
            upd_vendors_rec.global_attribute16,
            upd_vendors_rec.global_attribute17,
            upd_vendors_rec.global_attribute18,
            upd_vendors_rec.global_attribute19,
            upd_vendors_rec.global_attribute20,
            NVL(NVL(vendor_interface_rec.vndr_bank_charge_bearer,payables_rec.bank_charge_bearer),
                'I'),
            'XX03PVI001C');
--
            --# OUT変数にvendor_idを代入
            ot_vendor_id := vendor_interface_rec.vndr_vendor_id;
--
      ELSE
        --# OUT変数にvendor_idを代入
        ot_vendor_id := vendor_interface_rec.vndr_vendor_id;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        lv_retcode := xx00_common_pkg.set_status_warn_f;
    END;
    IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
      ov_interface_errcode := '590';
      RAISE upd_vendors_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN upd_vendors_expt THEN           --*** 仕入先マスタデータ更新失敗 ***
      -- *** 任意で例外処理を記述する ****
      --カーソルのクローズ
      IF (upd_vendors_cur%ISOPEN) THEN
        CLOSE upd_vendors_cur;
      END IF;
      lv_errbuf := xx00_message_pkg.get_msg(cv_msg_appl_name,
                                           'APP-XX03-00012',
                                           'TOK_XX03_VENDOR_INTERFACE_ID',
                                           vendor_interface_rec.VENDORS_INTERFACE_ID,
                                           'TOK_XX03_INSERT_UPDATE_FLAG',
                                           iv_process_mode,
                                           'TOK_XX03_VENDOR_ID',
                                           vendor_interface_rec.vndr_vendor_id,
                                           'TOK_XX03_VENDOR_NAME',
                                           vendor_interface_rec.vndr_vendor_name,
                                           'TOK_XX03_VENDOR_SITE_ID',
                                           vendor_interface_rec.site_vendor_site_id,
                                           'TOK_XX03_VENDOR_SITE_CODE',
                                           vendor_interface_rec.site_vendor_site_code,
                                           'TOK_XX03_ERROR_REASON',
                                           xx03_get_error_message_pkg.get_error_message(
                                             'XX03_VENDOR_IF_ERROR_REASON',
                                             ov_interface_errcode));
      lv_errmsg := xx00_message_pkg.get_msg(cv_msg_appl_name,
                                           'APP-XX03-00011',
                                           'TOK_XX03_VENDOR_INTERFACE_ID',
                                           vendor_interface_rec.VENDORS_INTERFACE_ID,
                                           'TOK_XX03_INSERT_UPDATE_FLAG',
                                           iv_process_mode,
                                           'TOK_XX03_VENDOR_ID',
                                           vendor_interface_rec.vndr_vendor_id,
                                           'TOK_XX03_VENDOR_NAME',
                                           vendor_interface_rec.vndr_vendor_name,
                                           'TOK_XX03_VENDOR_SITE_ID',
                                           vendor_interface_rec.site_vendor_site_id,
                                           'TOK_XX03_VENDOR_SITE_CODE',
                                           vendor_interface_rec.site_vendor_site_code,
                                           'TOK_XX03_ERROR_REASON',
                                           xx03_get_error_message_pkg.get_error_message(
                                             'XX03_VENDOR_IF_ERROR_REASON',
                                             ov_interface_errcode));
      --------------------------------------------------------------------------------------
      --# セーブポイントまでロールバック
      ROLLBACK TO main_loop_pvt;
      ov_errmsg := lv_errmsg;                                                           --# 任意 #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# 任意 #
      --ステータスを警告で返す
      ov_retcode := xx00_common_pkg.set_status_warn_f;                     --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_api_expt THEN   -- *** 共通関数例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  固定部 END   ##########################################
--
  END upd_vendors;
--
--
  /**********************************************************************************
   * Procedure Name   : upd_vendor_sites
   * Description      : 仕入先サイトマスタへの登録(A-6)
   ***********************************************************************************/
  PROCEDURE upd_vendor_sites(
    it_wk_vendor_id       IN po_vendors.vendor_id%TYPE,    --1.upd_vendors(A-6)で取得のvendor_id
    vendor_interface_rec  IN vendor_interface_cur%ROWTYPE, --2.仕入先IFTのデータ
    financials_rec        IN  financials_cur%ROWTYPE,      --3.会計オプションデータ
    iv_process_mode       IN VARCHAR2,                     --4.追加/更新モード
    ov_upd_vs_rowid          OUT VARCHAR2, --ap_vendor_site_pkg.update_rowのOUT変数
    on_upd_vs_vendor_site_id OUT NUMBER,   --upd_vendor_sitesで取得のvendor_sites_id
    ov_interface_errcode     OUT VARCHAR2, --エラー理由コード
    ov_errbuf                OUT VARCHAR2, --エラー・メッセージ           --# 固定 #
    ov_retcode               OUT VARCHAR2, --リターン・コード             --# 固定 #
    ov_errmsg                OUT VARCHAR2) --ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_vendor_sites'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
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
    lt_address_style        fnd_territories_vl.address_style%TYPE;  --住所形式データ格納用
    ln_wk_vendor_site_id    NUMBER;   --ap_vendor_site_pkg.update_rowで取得のvendr_seite_id
    lt_wk_vendor_site_code  po_vendor_sites.vendor_site_code%TYPE;
    lt_wk_vendor_id         po_vendor_sites_all.vendor_id%TYPE;  --追加時使用のvendor_id
    lt_lock_dummy           po_vendor_sites_all.vendor_site_id%TYPE; --ロック取得用ワーク変数
--
    -- *** ローカル・カーソル ***
    --# デフォルト値使用データ取得カーソル
    CURSOR po_vendors_cur(
      it_wk_vendor_id IN po_vendors.vendor_id%TYPE,
      vndr_vendor_id  IN vendor_interface_rec.vndr_vendor_id%TYPE)
    IS
    SELECT ship_to_location_id,
           bill_to_location_id,
           ship_via_lookup_code,
           freight_terms_lookup_code,
           fob_lookup_code,
           payment_method_lookup_code,
           terms_date_basis,
           prepay_code_combination_id,
           payment_priority,
           terms_id,
           pay_date_basis_lookup_code,
           always_take_disc_flag,
           invoice_currency_code,
           payment_currency_code,
           hold_all_payments_flag,
           hold_future_payments_flag,
           hold_reason,
           hold_unmatched_invoices_flag,
           match_option,
           exclusive_payment_flag,
           exclude_freight_from_discount,
           offset_tax_flag,
           allow_awt_flag,
           auto_tax_calc_flag,
           auto_tax_calc_override,
           amount_includes_tax_flag,
           ap_tax_rounding_rule
    FROM   po_vendors
    WHERE  vendor_id = it_wk_vendor_id;
--
   --# update時使用データ取得カーソル
   CURSOR vendors_site_all_cur (
     site_vendor_site_id IN vendor_interface_rec.site_vendor_site_id%TYPE)
   IS
     SELECT rowidtochar(rowid)  char_rowid,
            vendor_id,
            last_update_login,
            creation_date,
            created_by,
            purchasing_site_flag,
            rfq_only_site_flag,
            pay_site_flag,
            attention_ar_flag,
            customer_num,
            ship_to_location_id,
            bill_to_location_id,
            ship_via_lookup_code,
            freight_terms_lookup_code,
            fob_lookup_code,
            inactive_date,
            telex,
            bank_account_name,
            bank_account_num,
            bank_num,
            bank_account_type,
            terms_date_basis,
            current_catalog_num,
            accts_pay_code_combination_id,
            future_dated_payment_ccid,
            prepay_code_combination_id,
            payment_priority,
            pay_date_basis_lookup_code,
            always_take_disc_flag,
            invoice_currency_code,
            payment_currency_code,
            hold_all_payments_flag,
            hold_future_payments_flag,
            hold_reason,
            hold_unmatched_invoices_flag,
            match_option,
            exclusive_payment_flag,
            tax_reporting_site_flag,
            validation_number,
            exclude_freight_from_discount,
            vat_registration_num,
            offset_tax_flag,
            check_digits,
            bank_number,
            county,
            address_style,
            language,
            pay_on_code,
            default_pay_site_id,
            pay_on_receipt_summary_code,
            bank_branch_type,
            edi_id_number,
            edi_payment_method,
            edi_payment_format,
            edi_remittance_method,
            edi_remittance_instruction,
            edi_transaction_handling,
            amount_includes_tax_flag,
            global_attribute_category,
            global_attribute1,
            global_attribute2,
            global_attribute3,
            global_attribute4,
            global_attribute5,
            global_attribute6,
            global_attribute7,
            global_attribute8,
            global_attribute9,
            global_attribute10,
            global_attribute11,
            global_attribute12,
            global_attribute13,
            global_attribute14,
            global_attribute15,
            global_attribute16,
            global_attribute17,
            global_attribute18,
            global_attribute19,
            global_attribute20,
            ece_tp_location_code,
            pcard_site_flag,
            country_of_origin_code,
            remittance_email,
            primary_pay_site_flag
     FROM   po_vendor_sites_all
     WHERE  vendor_site_id = site_vendor_site_id;
--
    -- *** ローカル・レコード ***
    ven_rec   po_vendors_cur%ROWTYPE;       --デフォルト値使用データ
    site_rec  vendors_site_all_cur%ROWTYPE; --仕入先サイトマスタUPDATE時使用データ
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    BEGIN
      -- ===============================
      --  データ取得
      -- ===============================
      --# デフォルト値使用データ取得
      OPEN po_vendors_cur(it_wk_vendor_id,vendor_interface_rec.vndr_vendor_id);
      FETCH po_vendors_cur INTO ven_rec;
      CLOSE po_vendors_cur;
      --# 住所形式データ取得
      BEGIN
        SELECT ftv.address_style
        INTO   lt_address_style
        FROM   fnd_territories_vl ftv
        WHERE  ftv.territory_code = vendor_interface_rec.site_country;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lt_address_style := NULL;
      END;
--
      -- ===============================
      --  ロック取得
      -- ===============================
-- N.Fujikawa Start
xx00_file_pkg.log('Lock Start');
-- N.Fujikawa End
-- N.Fujikawa Start
BEGIN
-- N.Fujikawa End
      SELECT pvsa.vendor_site_id
      INTO   lt_lock_dummy
      FROM   po_vendor_sites_all pvsa
      WHERE  ROWNUM = 1
      FOR UPDATE NOWAIT;
-- N.Fujikawa Start
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    NULL;
-- N.Fujikawa End
END;
-- N.Fujikawa Start
xx00_file_pkg.log('Lock End');
-- N.Fujikawa End
--
      -- ===============================
      --  仕入先サイトマスタへの登録
      -- ===============================
      IF (iv_process_mode IN ('1','2')) THEN
-- N.Fujikawa Start
xx00_file_pkg.log('iv_process_mode IN (''1'',''2'')');
-- N.Fujikawa End
--
        --仕入先ｲﾝﾀｰﾌｪｰｽﾃｰﾌﾞﾙより取得のsite_vendor_site_codeを変数に格納
        lt_wk_vendor_site_code := vendor_interface_rec.site_vendor_site_code;
        --仕入先IDを変数に格納
        IF (iv_process_mode = '1') THEN
          lt_wk_vendor_id := it_wk_vendor_id;
        ELSIF (iv_process_mode = '2') THEN
          lt_wk_vendor_id := vendor_interface_rec.vndr_vendor_id;
        END IF;
--
        --# レコード追加
        ap_vendor_sites_pkg.insert_row(
          ov_upd_vs_rowid,
          ln_wk_vendor_site_id,
          xx00_date_pkg.get_system_datetime_f,
          xx00_global_pkg.last_updated_by,
          lt_wk_vendor_id,
          lt_wk_vendor_site_code,
          xx00_global_pkg.last_update_login,
          xx00_date_pkg.get_system_datetime_f,
          xx00_global_pkg.created_by,
          NVL(vendor_interface_rec.site_purchasing_site_flag,'N'),
          'N',
          'Y',
          'N',
          vendor_interface_rec.site_address_line1,
          vendor_interface_rec.site_address_line2,
          vendor_interface_rec.site_address_line3,
          vendor_interface_rec.site_city,
          vendor_interface_rec.site_state,
          vendor_interface_rec.site_zip,
          vendor_interface_rec.site_province,
          vendor_interface_rec.site_country,
          vendor_interface_rec.site_area_code,
          vendor_interface_rec.site_phone,
          NULL,
          ven_rec.ship_to_location_id,
          ven_rec.bill_to_location_id,
          ven_rec.ship_via_lookup_code,
          ven_rec.freight_terms_lookup_code,
          ven_rec.fob_lookup_code,
          NULL,
          vendor_interface_rec.site_fax,
          vendor_interface_rec.site_fax_area_code,
          NULL,
          NVL(vendor_interface_rec.site_payment_method_lkup_code,
              ven_rec.payment_method_lookup_code),
          vendor_interface_rec.site_bank_account_name,
          vendor_interface_rec.site_bank_account_num,
          vendor_interface_rec.site_bank_num,
          vendor_interface_rec.site_bank_account_type,
          ven_rec.terms_date_basis,
          NULL,
          vendor_interface_rec.site_vat_code,
          vendor_interface_rec.site_distribution_set_id,
          NVL(vendor_interface_rec.site_accts_pay_ccid,
              financials_rec.accts_pay_code_combination_id)  ,
          financials_rec.future_dated_payment_ccid,
          NVL(vendor_interface_rec.site_prepay_ccid,ven_rec.prepay_code_combination_id),
          vendor_interface_rec.site_pay_group_lkup_code,
          ven_rec.payment_priority,
          NVL(vendor_interface_rec.site_terms_id,ven_rec.terms_id),
          vendor_interface_rec.site_invoice_amount_limit,
          ven_rec.pay_date_basis_lookup_code,
          ven_rec.always_take_disc_flag,
          ven_rec.invoice_currency_code,
          ven_rec.payment_currency_code,
          ven_rec.hold_all_payments_flag,
          ven_rec.hold_future_payments_flag,
          ven_rec.hold_reason,
          ven_rec.hold_unmatched_invoices_flag,
          ven_rec.match_option,
          NVL(vendor_interface_rec.site_create_debit_memo_flag,'N'),
          ven_rec.exclusive_payment_flag,
          'N',
          vendor_interface_rec.site_attribute_category,
          vendor_interface_rec.site_attribute1,
          vendor_interface_rec.site_attribute2,
          vendor_interface_rec.site_attribute3,
          vendor_interface_rec.site_attribute4,
          vendor_interface_rec.site_attribute5,
          vendor_interface_rec.site_attribute6,
          vendor_interface_rec.site_attribute7,
          vendor_interface_rec.site_attribute8,
          vendor_interface_rec.site_attribute9,
          vendor_interface_rec.site_attribute10,
          vendor_interface_rec.site_attribute11,
          vendor_interface_rec.site_attribute12,
          vendor_interface_rec.site_attribute13,
          vendor_interface_rec.site_attribute14,
          vendor_interface_rec.site_attribute15,
          NULL,
          ven_rec.exclude_freight_from_discount,
          NULL,
          ven_rec.offset_tax_flag,
          NULL,
          vendor_interface_rec.site_bank_number,
          vendor_interface_rec.site_address_line4,
          vendor_interface_rec.site_county,
          lt_address_style,
          NULL,
          NVL(vendor_interface_rec.site_allow_awt_flag,ven_rec.allow_awt_flag),
          vendor_interface_rec.site_awt_group_id,
          NULL,
          NULL,
          NULL,
          vendor_interface_rec.site_bank_branch_type,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NVL(vendor_interface_rec.site_auto_tax_calc_flag,ven_rec.auto_tax_calc_flag),
          NVL(vendor_interface_rec.site_auto_tax_calc_override,ven_rec.auto_tax_calc_override),
          ven_rec.amount_includes_tax_flag,
          NVL(vendor_interface_rec.site_ap_tax_rounding_rule,ven_rec.ap_tax_rounding_rule),
          vendor_interface_rec.site_vendor_site_code_alt,
          vendor_interface_rec.site_address_lines_alt,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          vendor_interface_rec.site_bank_charge_bearer,
          NULL,
          NULL,
          NULL,
          'XX03PVI001C',
          NULL,
          NVL(vendor_interface_rec.site_supplier_notif_method,'PRINT'),
          vendor_interface_rec.site_email_address,
          NULL,
          NVL(vendor_interface_rec.site_primary_pay_site_flag,'N'));
--
          --# OUT変数にap_vendor_site_pkg.update_rowから取得のvendor_site_idを代入
          on_upd_vs_vendor_site_id := ln_wk_vendor_site_id;
--
      --# 仕入先サイトマスタ更新
      ELSIF (iv_process_mode = '3') THEN
-- N.Fujikawa Start
xx00_file_pkg.log('iv_process_mode = ''3'')');
-- N.Fujikawa End
        --# データ取得
        OPEN  vendors_site_all_cur(vendor_interface_rec.site_vendor_site_id);
        FETCH vendors_site_all_cur INTO site_rec;
        CLOSE vendors_site_all_cur;
        --# レコード更新
        ap_vendor_sites_pkg.update_row(
          site_rec.char_rowid,
          vendor_interface_rec.site_vendor_site_id,
          xx00_date_pkg.get_system_datetime_f,
          xx00_global_pkg.last_updated_by,
          site_rec.vendor_id,
          vendor_interface_rec.site_vendor_site_code,
          xx00_global_pkg.last_update_login,
          site_rec.creation_date,
          site_rec.created_by,
          NVL(vendor_interface_rec.site_purchasing_site_flag,'N'),
          site_rec.rfq_only_site_flag,
          site_rec.pay_site_flag,
          site_rec.attention_ar_flag,
          vendor_interface_rec.site_address_line1,
          vendor_interface_rec.site_address_line2,
          vendor_interface_rec.site_address_line3,
          vendor_interface_rec.site_city,
          vendor_interface_rec.site_state,
          vendor_interface_rec.site_zip,
          vendor_interface_rec.site_province,
          vendor_interface_rec.site_country,
          vendor_interface_rec.site_area_code,
          vendor_interface_rec.site_phone,
          site_rec.customer_num,
          site_rec.ship_to_location_id,
          site_rec.bill_to_location_id,
          site_rec.ship_via_lookup_code,
          site_rec.freight_terms_lookup_code,
          site_rec.fob_lookup_code,
          site_rec.inactive_date,
          vendor_interface_rec.site_fax,
          vendor_interface_rec.site_fax_area_code,
          site_rec.telex,
          NVL(vendor_interface_rec.site_payment_method_lkup_code,
              ven_rec.payment_method_lookup_code),
          site_rec.bank_account_name,
          site_rec.bank_account_num,
          site_rec.bank_num,
          site_rec.bank_account_type,
          site_rec.terms_date_basis,
          site_rec.current_catalog_num,
          vendor_interface_rec.site_vat_code,
          vendor_interface_rec.site_distribution_set_id,
          site_rec.accts_pay_code_combination_id,
          site_rec.future_dated_payment_ccid,
          site_rec.prepay_code_combination_id,
          vendor_interface_rec.site_pay_group_lkup_code,
          site_rec.payment_priority,
          NVL(vendor_interface_rec.site_terms_id,ven_rec.terms_id),
          vendor_interface_rec.site_invoice_amount_limit,
          site_rec.pay_date_basis_lookup_code,
          site_rec.always_take_disc_flag,
          site_rec.invoice_currency_code,
          site_rec.payment_currency_code,
          site_rec.hold_all_payments_flag,
          site_rec.hold_future_payments_flag,
          site_rec.hold_reason,
          site_rec.hold_unmatched_invoices_flag,
          site_rec.match_option,
          NVL(vendor_interface_rec.site_create_debit_memo_flag,'N'),
          site_rec.exclusive_payment_flag,
          site_rec.tax_reporting_site_flag,
          vendor_interface_rec.site_attribute_category,
          vendor_interface_rec.site_attribute1,
          vendor_interface_rec.site_attribute2,
          vendor_interface_rec.site_attribute3,
          vendor_interface_rec.site_attribute4,
          vendor_interface_rec.site_attribute5,
          vendor_interface_rec.site_attribute6,
          vendor_interface_rec.site_attribute7,
          vendor_interface_rec.site_attribute8,
          vendor_interface_rec.site_attribute9,
          vendor_interface_rec.site_attribute10,
          vendor_interface_rec.site_attribute11,
          vendor_interface_rec.site_attribute12,
          vendor_interface_rec.site_attribute13,
          vendor_interface_rec.site_attribute14,
          vendor_interface_rec.site_attribute15,
          site_rec.validation_number,
          site_rec.exclude_freight_from_discount,
          site_rec.vat_registration_num,
          site_rec.offset_tax_flag,
          site_rec.check_digits,
          site_rec.bank_number,
          vendor_interface_rec.site_address_line4,
          site_rec.county,
          site_rec.address_style,
          site_rec.language,
          NVL(vendor_interface_rec.site_allow_awt_flag,ven_rec.allow_awt_flag),
          vendor_interface_rec.site_awt_group_id,
          site_rec.pay_on_code,
          site_rec.default_pay_site_id,
          site_rec.pay_on_receipt_summary_code,
          site_rec.bank_branch_type,
          site_rec.edi_id_number,
          site_rec.edi_payment_method,
          site_rec.edi_payment_format,
          site_rec.edi_remittance_method,
          site_rec.edi_remittance_instruction,
          site_rec.edi_transaction_handling,
          NVL(vendor_interface_rec.site_auto_tax_calc_flag,ven_rec.auto_tax_calc_flag),
          NVL(vendor_interface_rec.site_auto_tax_calc_override,ven_rec.auto_tax_calc_override),
          site_rec.amount_includes_tax_flag,
          NVL(vendor_interface_rec.site_ap_tax_rounding_rule,ven_rec.ap_tax_rounding_rule),
          vendor_interface_rec.site_vendor_site_code_alt,
          vendor_interface_rec.site_address_lines_alt,
          site_rec.global_attribute_category,
          site_rec.global_attribute1,
          site_rec.global_attribute2,
          site_rec.global_attribute3,
          site_rec.global_attribute4,
          site_rec.global_attribute5,
          site_rec.global_attribute6,
          site_rec.global_attribute7,
          site_rec.global_attribute8,
          site_rec.global_attribute9,
          site_rec.global_attribute10,
          site_rec.global_attribute11,
          site_rec.global_attribute12,
          site_rec.global_attribute13,
          site_rec.global_attribute14,
          site_rec.global_attribute15,
          site_rec.global_attribute16,
          site_rec.global_attribute17,
          site_rec.global_attribute18,
          site_rec.global_attribute19,
          site_rec.global_attribute20,
          vendor_interface_rec.site_bank_charge_bearer,
          site_rec.ece_tp_location_code,
          site_rec.pcard_site_flag,
          site_rec.country_of_origin_code,
          'XX03PVI001C',
          NULL,
          NVL(vendor_interface_rec.site_supplier_notif_method,'PRINT'),
          vendor_interface_rec.site_email_address,
          site_rec.remittance_email,
          NVL(site_rec.primary_pay_site_flag,'N'));
--
       --# OUT変数にvendor_site_idを格納
       on_upd_vs_vendor_site_id := vendor_interface_rec.site_vendor_site_id;
--
     ELSE
-- N.Fujikawa Start
xx00_file_pkg.log('iv_process_mode = else');
-- N.Fujikawa End
       --# OUT変数にvendor_site_idを格納
       on_upd_vs_vendor_site_id := vendor_interface_rec.site_vendor_site_id;
     END IF;
   EXCEPTION
     WHEN OTHERS THEN
-- N.Fujikawa Start
xx00_file_pkg.log(SQLCODE || '>>' || SQLERRM);
-- N.Fujikawa End
       lv_retcode := xx00_common_pkg.set_status_warn_f;
   END;
   IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
     ov_interface_errcode := '600';
     RAISE upd_vendor_sites_expt;
   END IF;
--
   --==============================================================
   --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN upd_vendor_sites_expt THEN        --*** 仕入先サイトマスタ更新失敗 ***
      -- *** 任意で例外処理を記述する ****
      --カーソルのクローズ
      IF (po_vendors_cur%ISOPEN) THEN
        CLOSE po_vendors_cur;
      ELSIF (vendors_site_all_cur%ISOPEN) THEN
        CLOSE vendors_site_all_cur;
      END IF;
      --メッセージのセット
      lv_errbuf := xx00_message_pkg.get_msg(cv_msg_appl_name,
                                           'APP-XX03-00013',
                                           'TOK_XX03_VENDOR_INTERFACE_ID',
                                           vendor_interface_rec.VENDORS_INTERFACE_ID,
                                           'TOK_XX03_INSERT_UPDATE_FLAG',
                                           iv_process_mode,
                                           'TOK_XX03_VENDOR_ID',
                                           vendor_interface_rec.vndr_vendor_id,
                                           'TOK_XX03_VENDOR_NAME',
                                           vendor_interface_rec.vndr_vendor_name,
                                           'TOK_XX03_VENDOR_SITE_ID',
                                           vendor_interface_rec.site_vendor_site_id,
                                           'TOK_XX03_VENDOR_SITE_CODE',
                                           vendor_interface_rec.site_vendor_site_code,
                                           'TOK_XX03_ERROR_REASON',
                                           xx03_get_error_message_pkg.get_error_message(
                                             'XX03_VENDOR_IF_ERROR_REASON',
                                             ov_interface_errcode));
      lv_errmsg := lv_errbuf;
      --------------------------------------------------------------------------------------
      --# セーブポイントまでロールバック
      ROLLBACK TO main_loop_pvt;
      ov_errmsg := lv_errmsg;                                                           --# 任意 #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# 任意 #
      --ステータスを警告で返す
      ov_retcode := xx00_common_pkg.set_status_warn_f;                     --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_api_expt THEN   -- *** 共通関数例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  固定部 END   ##########################################
--
  END upd_vendor_sites;
--
--
  /**********************************************************************************
   * Procedure Name   : upd_bank_accounts
   * Description      : 銀行口座マスタへの登録･更新(A-7)
   ***********************************************************************************/
  PROCEDURE upd_bank_accounts(
    iv_process_mode       IN  VARCHAR2,               --1.追加/更新モード
    vendor_interface_rec  IN  vendor_interface_cur%ROWTYPE,             --2.仕入先IFTのデータ
    financials_rec        IN  financials_cur%ROWTYPE, --3.会計オプションデータ
    payables_rec          IN  payables_cur%ROWTYPE,   --4.買掛管理オプションデータ
    ot_wk_bank_account_id  OUT ap_bank_accounts_all.bank_account_id%TYPE, --銀行口座ID
    ov_interface_errcode  OUT VARCHAR2,     -- エラー理由コード
    ov_errbuf             OUT VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg             OUT VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_bank_accounts'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
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
    lt_wk_bank_branch_id   ap_bank_branches.bank_branch_id%TYPE;  --銀行支店ID
    lv_usr_prof_option     VARCHAR2(255); --xx00_profile_pkg.getの戻り値(ﾕｰｻﾞ･ﾌﾟﾛﾌｧｲﾙ･ｵﾌﾟｼｮﾝ)
    --Ver11.5.10.1.3 2005.06.10 add START
    ln_org_id NUMBER;
    --Ver11.5.10.1.3 2005.06.10 add END
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    --Ver11.5.10.1.3 2005.06.10 add START
    --# 組織IDの取得
    xx00_profile_pkg.get('ORG_ID',ln_org_id);
    --Ver11.5.10.1.3 2005.06.10 add END
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    BEGIN
      IF (iv_process_mode = '4') THEN
        --# 追加/更新モードが④の時は、登録/更新は行わない。
        NULL;
      ELSE
        --==============================================================
        -- データ取得
        --==============================================================
        --# 銀行支店ID取得
        SELECT abb.bank_branch_id
        INTO   lt_wk_bank_branch_id
        FROM   ap_bank_branches abb
        WHERE  abb.bank_name = vendor_interface_rec.acnt_bank_name
        AND    abb.bank_branch_name = vendor_interface_rec.acnt_bank_branch_name;
        --# 銀行口座IDの取得
        BEGIN
          SELECT bank_account_id
          INTO   ot_wk_bank_account_id
          FROM   ap_bank_accounts_all baa
          WHERE  baa.bank_account_num = vendor_interface_rec.acnt_bank_account_num
          AND    bank_branch_id = lt_wk_bank_branch_id
          AND    account_type = 'SUPPLIER'
          AND    NVL(currency_code,'null_currency') 
          = nvl(vendor_interface_rec.acnt_currency_code,'null_currency')
        --Ver11.5.10.1.3 2005.06.10 add START
          AND    org_id = ln_org_id
        --Ver11.5.10.1.3 2005.06.10 add END
          FOR UPDATE NOWAIT;
          --==============================================================
          -- データ更新（BANK_ACCOUNT_IDが取得できた場合）
          --==============================================================
          UPDATE ap_bank_accounts_all
          set    bank_account_name       = vendor_interface_rec.acnt_bank_account_name,
                 last_update_date        = xx00_date_pkg.get_system_datetime_f,
                 last_updated_by         = xx00_global_pkg.last_updated_by,
                 last_update_login       = xx00_global_pkg.last_update_login,
                 attribute_category      = vendor_interface_rec.acnt_attribute_category,
                 attribute1              = vendor_interface_rec.acnt_attribute1,
                 attribute2              = vendor_interface_rec.acnt_attribute2,
                 attribute3              = vendor_interface_rec.acnt_attribute3,
                 attribute4              = vendor_interface_rec.acnt_attribute4,
                 attribute5              = vendor_interface_rec.acnt_attribute5,
                 attribute6              = vendor_interface_rec.acnt_attribute6,
                 attribute7              = vendor_interface_rec.acnt_attribute7,
                 attribute8              = vendor_interface_rec.acnt_attribute8,
                 attribute9              = vendor_interface_rec.acnt_attribute9,
                 attribute10             = vendor_interface_rec.acnt_attribute10,
                 attribute11             = vendor_interface_rec.acnt_attribute11,
                 attribute12             = vendor_interface_rec.acnt_attribute12,
                 attribute13             = vendor_interface_rec.acnt_attribute13,
                 attribute14             = vendor_interface_rec.acnt_attribute14,
                 attribute15             = vendor_interface_rec.acnt_attribute15,
                 request_id              = xx00_global_pkg.conc_request_id,
                 program_application_id  = xx00_global_pkg.prog_appl_id,
                 program_id              = xx00_global_pkg.conc_program_id,
                 program_update_date     = xx00_date_pkg.get_system_datetime_f,
                 account_holder_name     = vendor_interface_rec.acnt_account_holder_name,
                 account_holder_name_alt = vendor_interface_rec.acnt_account_holder_name_alt
          WHERE  bank_account_id = ot_wk_bank_account_id;
        EXCEPTION
          --# BANK_ACCOUNT_IDが取得できなかった場合
          WHEN NO_DATA_FOUND THEN
            --# シーケンスを取得
            SELECT ap_bank_accounts_s.nextval
            INTO   ot_wk_bank_account_id
            FROM   sys.dual;
            --会計帳簿IDの取得
            xx00_profile_pkg.get('GL_SET_OF_BKS_ID',lv_usr_prof_option);
            --==============================================================
            -- データ追加（BANK_ACCOUNT_IDが取得できなかった場合）
            --==============================================================
            INSERT INTO ap_bank_accounts_all(
              bank_account_id,
              bank_account_name,
              last_update_date,
              last_updated_by,
              last_update_login,
              creation_date,
              created_by,
              bank_account_num,
              bank_branch_id,
              set_of_books_id,
              currency_code,
              description,
              contact_first_name,
              contact_middle_name,
              contact_last_name,
              contact_prefix,
              contact_title,
              contact_area_code,
              contact_phone,
              max_check_amount,
              min_check_amount,
              one_signature_max_flag,
              inactive_date,
              avg_float_days,
              asset_code_combination_id,
              gain_code_combination_id,
              loss_code_combination_id,
              bank_account_type,
              validation_number,
              max_outlay,
              multi_currency_flag,
              account_type,
              attribute_category,
              attribute1,
              attribute2,
              attribute3,
              attribute4,
              attribute5,
              attribute6,
              attribute7,
              attribute8,
              attribute9,
              attribute10,
              attribute11,
              attribute12,
              attribute13,
              attribute14,
              attribute15,
              pooled_flag,
              zero_amounts_allowed,
              request_id,
              program_application_id,
              program_id,
              program_update_date,
              receipt_multi_currency_flag,
              check_digits,
              org_id,
              cash_clearing_ccid,
              bank_charges_ccid,
              bank_errors_ccid,
              earned_ccid,
              unearned_ccid,
              on_account_ccid,
              unapplied_ccid,
              unidentified_ccid,
              factor_ccid,
              receipt_clearing_ccid,
              remittance_ccid,
              short_term_deposit_ccid,
              global_attribute_category,
              global_attribute1,
              global_attribute2,
              global_attribute3,
              global_attribute4,
              global_attribute5,
              global_attribute6,
              global_attribute7,
              global_attribute8,
              global_attribute9,
              global_attribute10,
              global_attribute11,
              global_attribute12,
              global_attribute13,
              global_attribute14,
              global_attribute15,
              global_attribute16,
              global_attribute17,
              global_attribute18,
              global_attribute19,
              global_attribute20,
              bank_account_name_alt,
              account_holder_name,
              account_holder_name_alt,
              eft_requester_id,
              eft_user_number,
              payroll_bank_account_id,
              future_dated_payment_ccid,
              edisc_receivables_trx_id,
              unedisc_receivables_trx_id,
              br_remittance_ccid,
              br_factor_ccid,
              br_std_receivables_trx_id,
              allow_multi_assignments_flag,
              agency_location_code)
            VALUES(
              ot_wk_bank_account_id,
              vendor_interface_rec.acnt_bank_account_name,
              xx00_date_pkg.get_system_datetime_f,
              xx00_global_pkg.last_updated_by,
              xx00_global_pkg.last_update_login,
              xx00_date_pkg.get_system_datetime_f,
              XX00_GLOBAL_PKG.CREATED_BY,
              vendor_interface_rec.acnt_bank_account_num,
              lt_wk_bank_branch_id,
--              xx00_profile_pkg.get('SET_OF_BOOKS_ID',lv_usr_prof_option),
              lv_usr_prof_option,
              vendor_interface_rec.acnt_currency_code,
              vendor_interface_rec.acnt_description,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              vendor_interface_rec.acnt_asset_id,
              payables_rec.gain_code_combination_id,
              payables_rec.loss_code_combination_id,
              vendor_interface_rec.acnt_bank_account_type,
              NULL,
              payables_rec.max_outlay,
              'N',
              'SUPPLIER',
              vendor_interface_rec.acnt_attribute_category,
              vendor_interface_rec.acnt_attribute1,
              vendor_interface_rec.acnt_attribute2,
              vendor_interface_rec.acnt_attribute3,
              vendor_interface_rec.acnt_attribute4,
              vendor_interface_rec.acnt_attribute5,
              vendor_interface_rec.acnt_attribute6,
              vendor_interface_rec.acnt_attribute7,
              vendor_interface_rec.acnt_attribute8,
              vendor_interface_rec.acnt_attribute9,
              vendor_interface_rec.acnt_attribute10,
              vendor_interface_rec.acnt_attribute11,
              vendor_interface_rec.acnt_attribute12,
              vendor_interface_rec.acnt_attribute13,
              vendor_interface_rec.acnt_attribute14,
              vendor_interface_rec.acnt_attribute15,
              'N',
              'N',
              xx00_global_pkg.conc_request_id,
              xx00_global_pkg.prog_appl_id,
              xx00_global_pkg.conc_program_id,
              xx00_date_pkg.get_system_datetime_f,
              payables_rec.multi_currency_flag,
              NULL,
            --Ver11.5.10.1.3 2005.06.10 modify START
              --to_number(xx00_profile_pkg.value('ORG_ID')),
              ln_org_id,
            --Ver11.5.10.1.3 2005.06.10 modify END
              vendor_interface_rec.acnt_cash_clearing_ccid,
              vendor_interface_rec.acnt_bank_charges_ccid,
              vendor_interface_rec.acnt_bank_errors_ccid,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              vendor_interface_rec.acnt_account_holder_name,
              vendor_interface_rec.acnt_account_holder_name_alt,
              NULL,
              NULL,
              NULL,
              financials_rec.future_dated_payment_ccid,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              'Y',
              NULL);
        END;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        lv_retcode := xx00_common_pkg.set_status_warn_f;
    END;
    IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
      ov_interface_errcode := '610';
      RAISE upd_bank_accounts_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN upd_bank_accounts_expt THEN       --*** 銀行口座マスタデータ更新失敗 ***
      -- *** 任意で例外処理を記述する ****
      lv_errbuf := xx00_message_pkg.get_msg(cv_msg_appl_name,
                                           'APP-XX03-00014',
                                           'TOK_XX03_VENDOR_INTERFACE_ID',
                                           vendor_interface_rec.VENDORS_INTERFACE_ID,
                                           'TOK_XX03_INSERT_UPDATE_FLAG',
                                           iv_process_mode,
                                           'TOK_XX03_VENDOR_ID',
                                           vendor_interface_rec.vndr_vendor_id,
                                           'TOK_XX03_VENDOR_NAME',
                                           vendor_interface_rec.vndr_vendor_name,
                                           'TOK_XX03_VENDOR_SITE_ID',
                                           vendor_interface_rec.site_vendor_site_id,
                                           'TOK_XX03_VENDOR_SITE_CODE',
                                           vendor_interface_rec.site_vendor_site_code,
                                           'TOK_XX03_ERROR_REASON',
                                           xx03_get_error_message_pkg.get_error_message(
                                             'XX03_VENDOR_IF_ERROR_REASON',
                                             ov_interface_errcode));
      lv_errmsg := lv_errbuf;
      --# セーブポイントまでロールバック
      ROLLBACK TO main_loop_pvt;
      -----------------------------------------------------------------------------------------
      ov_errmsg := lv_errmsg;                                                           --# 任意 #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# 任意 #
      --ステータスを警告で返す
      ov_retcode := xx00_common_pkg.set_status_warn_f;                     --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_api_expt THEN   -- *** 共通関数例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  固定部 END   ##########################################
--
  END upd_bank_accounts;
--
--
  /**********************************************************************************
   * Procedure Name   : upd_bank_account_uses
   * Description      : 銀行口座割当ﾃｰﾌﾞﾙへの登録･更新(A-8)
   ***********************************************************************************/
  PROCEDURE upd_bank_account_uses(
    iv_process_mode          IN  VARCHAR2,  --1.追加/更新モード
    it_wk_vendor_id          IN  po_vendors.vendor_id%TYPE,    --2.upd_vendorsで取得のvendor_id
    in_upd_vs_vendor_site_id IN  NUMBER,    --3.upd_vendor_sitesで取得のvendor_site_id
    vendor_interface_rec     IN  vendor_interface_cur%ROWTYPE, --4.仕入先データ
    it_wk_bank_account_id     IN  ap_bank_accounts_all.bank_account_id%TYPE, --5.銀行口座ID
    ov_interface_errcode OUT VARCHAR2,     --エラー理由コード
    ov_errbuf            OUT VARCHAR2,     --エラー・メッセージ           --# 固定 #
    ov_retcode           OUT VARCHAR2,     --リターン・コード             --# 固定 #
    ov_errmsg            OUT VARCHAR2)     --ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_bank_account_uses'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
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
    lr_wk_rowid   ROWID;            --ap_bank_account_uses_pkg.insert_rowで取得のOUT変数
    ln_wk_bank_account_uses_id  NUMBER;  --ap_bank_account_uses_pkg.insert_rowで取得のOUT変数
    lt_wk_lock    ap_bank_account_uses_all.bank_account_uses_id%TYPE; --ロック獲得時使用
--
    -- *** ローカル・カーソル ***
    --登録用データ取得カーソル
    CURSOR bank_account_uses_cur(
      it_wk_vendor_id           IN po_vendors.vendor_id%TYPE,
      in_upd_vs_vendor_site_id  IN NUMBER,
      it_wk_bank_account_id     IN ap_bank_accounts_all.bank_account_id%TYPE)
    IS
      SELECT rowidtochar(rowid) char_rowid,
             bank_account_uses_id,
             customer_id,
             customer_site_use_id,
             vendor_id,
             vendor_site_id,
             external_bank_account_id
      FROM   ap_bank_account_uses_all
      WHERE  vendor_id = it_wk_vendor_id
      AND    vendor_site_id = in_upd_vs_vendor_site_id
      AND    external_bank_account_id = it_wk_bank_account_id;
--
    -- *** ローカル・レコード ***
    bank_account_uses_rec bank_account_uses_cur%ROWTYPE;
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    BEGIN
      IF (iv_process_mode = '4') THEN
        --# 追加/更新モードが④の場合は、更新/追加は行わない
        NULL;
      ELSE
        --==============================================================
        -- ロックの獲得
        --==============================================================
-- N.Fujikawa Start
xx00_file_pkg.log('銀行口座割当Lock Start');
-- N.Fujikawa End
-- N.Fujikawa Start
BEGIN
-- N.Fujikawa End
        SELECT uses.bank_account_uses_id
        INTO   lt_wk_lock
        FROM   ap_bank_account_uses_all uses
        WHERE  ROWNUM = 1
        FOR UPDATE NOWAIT;
-- N.Fujikawa Start
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    NULL;
    END;
-- N.Fujikawa End
-- N.Fujikawa Start
xx00_file_pkg.log('銀行口座割当Lock End');
-- N.Fujikawa End
        --==============================================================
        -- データの更新
        --==============================================================
        UPDATE ap_bank_account_uses_all
        SET    primary_flag      = 'N',
               last_update_date  = xx00_date_pkg.get_system_datetime_f,
               last_updated_by   = xx00_global_pkg.last_updated_by,
               last_update_login = xx00_global_pkg.last_update_login
        WHERE  bank_account_uses_id IN (
          SELECT abau.bank_account_uses_id
          FROM   ap_bank_account_uses_all abau,
                 ap_bank_accounts_all     aba
          WHERE  abau.external_bank_account_id = aba.bank_account_id
          AND    abau.vendor_id = it_wk_vendor_id
          AND    abau.vendor_site_id = in_upd_vs_vendor_site_id
          AND    abau.primary_flag='Y'
          AND    NVL(aba.currency_code,'null_currency')
                 = NVL(vendor_interface_rec.acnt_currency_code,'null_currency')
          AND    ( NVL(vendor_interface_rec.uses_start_date,TO_DATE('01-01-1000','DD-MM-YYYY'))
                 BETWEEN NVL(abau.start_date, TO_DATE('01-01-1000','DD-MM-YYYY'))
                 AND NVL(abau.end_date, TO_DATE('01-01-9999','DD-MM-YYYY'))
                 OR  NVL(vendor_interface_rec.uses_end_date,TO_DATE('01-01-9999','DD-MM-YYYY'))
                 BETWEEN NVL(abau.start_date, TO_DATE('01-01-1000','DD-MM-YYYY'))
                 AND NVL(abau.end_date, TO_DATE('01-01-9999','DD-MM-YYYY'))
                 OR   NVL(vendor_interface_rec.uses_start_date,TO_DATE('01-01-1000','DD-MM-YYYY'))
                 <= NVL(abau.start_date, TO_DATE('01-01-1000','DD-MM-YYYY'))
                 AND NVL(vendor_interface_rec.uses_end_date,TO_DATE('01-01-9999','DD-MM-YYYY')) 
                 >= NVL(abau.end_date, TO_DATE('01-01-9999','DD-MM-YYYY'))
               ));
        --==============================================================
        -- データ取得
        --==============================================================
        OPEN  bank_account_uses_cur(it_wk_vendor_id,in_upd_vs_vendor_site_id,it_wk_bank_account_id);
        FETCH bank_account_uses_cur INTO bank_account_uses_rec;
        IF bank_account_uses_cur%NOTFOUND THEN
          --==============================================================
          -- データの追加（データが取得できなかった場合）
          --==============================================================
          ap_bank_account_uses_pkg.insert_row(
            lr_wk_rowid,
            ln_wk_bank_account_uses_id,
          xx00_date_pkg.get_system_datetime_f,
            xx00_global_pkg.last_updated_by,
          xx00_date_pkg.get_system_datetime_f,
            xx00_global_pkg.created_by,
            xx00_global_pkg.last_update_login,
            NULL,
            NULL,
            it_wk_vendor_id,
            in_upd_vs_vendor_site_id,
            it_wk_bank_account_id,
            vendor_interface_rec.uses_start_date,
            vendor_interface_rec.uses_end_date,
            'Y',
            vendor_interface_rec.uses_attribute_category,
            vendor_interface_rec.uses_attribute1,
            vendor_interface_rec.uses_attribute2,
            vendor_interface_rec.uses_attribute3,
            vendor_interface_rec.uses_attribute4,
            vendor_interface_rec.uses_attribute5,
            vendor_interface_rec.uses_attribute6,
            vendor_interface_rec.uses_attribute7,
            vendor_interface_rec.uses_attribute8,
            vendor_interface_rec.uses_attribute9,
            vendor_interface_rec.uses_attribute10,
            vendor_interface_rec.uses_attribute11,
            vendor_interface_rec.uses_attribute12,
            vendor_interface_rec.uses_attribute13,
            vendor_interface_rec.uses_attribute14,
            vendor_interface_rec.uses_attribute15);
        ELSE
          --==============================================================
          -- データの更新（データが取得できた場合）
          --==============================================================
          ap_bank_account_uses_pkg.update_row(
            bank_account_uses_rec.char_rowid,
            bank_account_uses_rec.bank_account_uses_id,
          xx00_date_pkg.get_system_datetime_f,
            xx00_global_pkg.last_updated_by,
            xx00_global_pkg.last_update_login,
            bank_account_uses_rec.customer_id,
            bank_account_uses_rec.customer_site_use_id,
            bank_account_uses_rec.vendor_id,
            bank_account_uses_rec.vendor_site_id,
            bank_account_uses_rec.external_bank_account_id,
            vendor_interface_rec.uses_start_date,
            vendor_interface_rec.uses_end_date,
            'Y',
            vendor_interface_rec.uses_attribute_category,
            vendor_interface_rec.uses_attribute1,
            vendor_interface_rec.uses_attribute2,
            vendor_interface_rec.uses_attribute3,
            vendor_interface_rec.uses_attribute4,
            vendor_interface_rec.uses_attribute5,
            vendor_interface_rec.uses_attribute6,
            vendor_interface_rec.uses_attribute7,
            vendor_interface_rec.uses_attribute8,
            vendor_interface_rec.uses_attribute9,
            vendor_interface_rec.uses_attribute10,
            vendor_interface_rec.uses_attribute11,
            vendor_interface_rec.uses_attribute12,
            vendor_interface_rec.uses_attribute13,
            vendor_interface_rec.uses_attribute14,
            vendor_interface_rec.uses_attribute15);
        END IF;
        CLOSE bank_account_uses_cur;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
-- N.Fujikawa Start
xx00_file_pkg.log(SQLCODE || '>>' || SQLERRM);
-- N.Fujikawa End
        --カーソルのクローズ
        IF (bank_account_uses_cur%ISOPEN) THEN
          CLOSE bank_account_uses_cur;
        END IF;
        lv_retcode := xx00_common_pkg.set_status_warn_f;
    END;
    IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
      ov_interface_errcode := '620';
      RAISE upd_bank_acnt_uses_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN upd_bank_acnt_uses_expt THEN      --*** 銀行口座割当データ更新失敗 ***
      -- *** 任意で例外処理を記述する ****
      --メッセージのセット
      lv_errbuf := xx00_message_pkg.get_msg(cv_msg_appl_name,
                                           'APP-XX03-00015',
                                           'TOK_XX03_VENDOR_INTERFACE_ID',
                                           vendor_interface_rec.VENDORS_INTERFACE_ID,
                                           'TOK_XX03_INSERT_UPDATE_FLAG',
                                           iv_process_mode,
                                           'TOK_XX03_VENDOR_ID',
                                           vendor_interface_rec.vndr_vendor_id,
                                           'TOK_XX03_VENDOR_NAME',
                                           vendor_interface_rec.vndr_vendor_name,
                                           'TOK_XX03_VENDOR_SITE_ID',
                                           vendor_interface_rec.site_vendor_site_id,
                                           'TOK_XX03_VENDOR_SITE_CODE',
                                           vendor_interface_rec.site_vendor_site_code,
                                           'TOK_XX03_ERROR_REASON',
                                           xx03_get_error_message_pkg.get_error_message(
                                             'XX03_VENDOR_IF_ERROR_REASON',
                                             ov_interface_errcode));
      lv_errmsg := lv_errbuf;
      --# セーブポイントまでロールバック
      ROLLBACK TO main_loop_pvt;
      -----------------------------------------------------------------------------------------
      ov_errmsg := lv_errmsg;                                                           --# 任意 #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# 任意 #
      --ステータスを警告で返す
      ov_retcode := xx00_common_pkg.set_status_warn_f;                     --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_api_expt THEN   -- *** 共通関数例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  固定部 END   ##########################################
--
  END upd_bank_account_uses;
--
--
  /**********************************************************************************
   * Procedure Name   : upd_ift
   * Description      : 仕入先インターフェーステーブルの更新(A-9)
   ***********************************************************************************/
  PROCEDURE upd_ift(
    ir_rowid      IN  ROWID,             -- 1.ROWID
    it_status     IN  xx03_vendors_interface.status_flag%TYPE,  -- 2.処理成功/失敗ﾌﾗｸﾞ
    iv_interface_errcode  IN  VARCHAR2,  -- 3.エラー理由コード
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_ift'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
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
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- =================================================
    -- 仕入先インターフェース表更新
    -- =================================================
    IF (it_status = 'S') THEN
      --# 登録成功フラグ書き込み
      BEGIN
        UPDATE xx03_vendors_interface
        SET    status_flag            = it_status,
               error_reason           = null,
               last_update_date       = xx00_date_pkg.get_system_datetime_f,
               last_updated_by        = xx00_global_pkg.last_updated_by,
               last_update_login      = xx00_global_pkg.last_update_login,
               request_id             = xx00_global_pkg.conc_request_id,
               program_application_id = xx00_global_pkg.prog_appl_id,
               program_id             = xx00_global_pkg.conc_program_id,
               program_update_date    = xx00_date_pkg.get_system_datetime_f
        WHERE  ROWID = ir_rowid;
      EXCEPTION
        WHEN OTHERS THEN
          lv_retcode := xx00_common_pkg.set_status_error_f;
      END;
      IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
        RAISE upd_ift_expt;
      END IF;
    ELSE
      --# 登録失敗フラグ書き込み
      BEGIN
        UPDATE xx03_vendors_interface
        SET    status_flag            = it_status,
               error_reason           = iv_interface_errcode,
               last_update_date       = xx00_date_pkg.get_system_datetime_f,
               last_updated_by        = xx00_global_pkg.last_updated_by,
               last_update_login      = xx00_global_pkg.last_update_login,
               request_id             = xx00_global_pkg.conc_request_id,
               program_application_id = xx00_global_pkg.prog_appl_id,
               program_id             = xx00_global_pkg.conc_program_id,
               program_update_date    = xx00_date_pkg.get_system_datetime_f
        WHERE  ROWID = ir_rowid;
      EXCEPTION
        WHEN OTHERS THEN
          lv_retcode := xx00_common_pkg.set_status_error_f;
      END;
      IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
        RAISE upd_ift_expt;
      END IF;
    END IF;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN upd_ift_expt THEN              --*** 仕入先ｲﾝﾀｰﾌｪｰｽﾃｰﾌﾞﾙ更新 ***
      -- *** 任意で例外処理を記述する ****
      --エラーメッセージセット
      lv_errbuf := xx00_message_pkg.get_msg(cv_msg_appl_name,
                                           'APP-XX03-00016');
      lv_errmsg := lv_errbuf;
      --ロールバック
      Rollback;
      -------------------------------------------------------------------------------
      ov_errmsg := lv_errmsg;                                                           --# 任意 #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# 任意 #
      ov_retcode := xx00_common_pkg.set_status_error_f;                                 --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_api_expt THEN   -- *** 共通関数例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  固定部 END   ##########################################
--
  END upd_ift;
--
--
  /**********************************************************************************
   * Procedure Name   : main_loop
   * Description      : 仕入先データ抽出(A-3)
   ***********************************************************************************/
  PROCEDURE main_loop(
    iv_force_flag            IN  VARCHAR2,     -- 強制フラグ
    id_start_date_active     IN  DATE,         -- 業務日付
    it_chart_of_accounts_id  IN  gl_sets_of_books.chart_of_accounts_id%TYPE,  -- 勘定体系ID
    financials_rec           IN  financials_cur%ROWTYPE,      -- 会計オプションデータ
    payables_rec             IN  payables_cur%ROWTYPE,        -- 買掛管理オプションデータ
    receipts_rec             IN  rcv_parameters_cur%ROWTYPE,  -- 受入オプションデータ
    in_set_of_books_id       IN  NUMBER,       -- 会計帳簿ID
    on_target_count          OUT NUMBER,       -- 処理対象件数
    on_err_count             OUT NUMBER,       -- エラーデータ件数
    on_success_count         OUT NUMBER,       -- 処理正常終了件数
    ov_errbuf                OUT VARCHAR2,     -- エラー・メッセージ                  --# 固定 #
    ov_retcode               OUT VARCHAR2,     -- リターン・コード                    --# 固定 #
    ov_errmsg                OUT VARCHAR2)     -- ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main_loop'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
--
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
    lv_interface_errcode      VARCHAR2(3); --エラー理由コード
    lv_process_mode           VARCHAR2(1); --追加/更新モード
    lr_wk_vendors_rowid       ROWID;       --ap_vendors_pkg.insert_rowで取得のOUT変数(ROWID)
    lt_wk_vendor_id           po_vendors.vendor_id%TYPE; --upd_vendorsで取得のvendor_id
    lv_upd_vs_rowid           VARCHAR2(2000);  --ap_vendor_site_pkg.update_rowのOUT変数
    ln_upd_vs_vendor_site_id  NUMBER;      --upd_vendor_sitesで取得のvendor_site_id
    lt_wk_bank_account_id     ap_bank_accounts_all.bank_account_id%TYPE; --銀行口座ID
    lv_wk_process_status      VARCHAR2(1); --各処理部の処理結果
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        ループ処理の記述         ***
    -- ***       処理部の呼び出し          ***
    -- ***************************************
--
    --# 初期処理
    on_target_count  := 0;  --処理対象件数
    on_err_count     := 0;  --エラー件数
    on_success_count := 0;  --処理成功件数
--
    --==============================================================
    -- 対象データの取得
    --==============================================================
    << vendor_ift_loop >>
    FOR vendor_interface_rec IN vendor_interface_cur(iv_force_flag) LOOP
      --# SavePointの設定
      SAVEPOINT main_loop_pvt;
      lv_interface_errcode := NULL;
      --処理対象データ件数のカウント
      on_target_count := on_target_count + 1;
      --処理部の処理結果格納変数の初期化
     lv_wk_process_status := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
      -- =================================================
      --  A-4.仕入先ﾃﾞｰﾀの妥当性ﾁｪｯｸ（valid_data）
      -- =================================================
      valid_data(
        vendor_interface_rec,  -- 仕入先IFTのデータ
        financials_rec,        -- 会計オプションデータ
        iv_force_flag,         -- 強制フラグ
        id_start_date_active,  -- 業務日付
        it_chart_of_accounts_id,  -- 勘定体系ID
        lv_process_mode,       -- 追加/更新モード
        lv_interface_errcode,  -- エラー理由コード
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      --# 処理結果を変数に保持
      lv_wk_process_status := lv_retcode;
      --# エラー処理
      IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
        --ログ･メッセージの出力
        xx00_file_pkg.log(lv_errbuf);
        xx00_file_pkg.output(lv_errmsg);
        --エラーデータ件数のカウント
        on_err_count := on_err_count + 1;
        ov_retcode := lv_retcode;
        -- =================================================
        --  A-9.仕入先ｲﾝﾀｰﾌｪｰｽﾃｰﾌﾞﾙ更新(upd_ift)
        -- =================================================
        --# 仕入先データ妥当性チェック失敗時（ステータス：エラー）
        upd_ift(
          vendor_interface_rec.rowid,  --対象データのROWID
          'E',                         --処理失敗のステータス
          lv_interface_errcode,        --エラー理由コード
          lv_errbuf,         -- エラー・メッセージ           --# 固定 #
          lv_retcode,        -- リターン・コード             --# 固定 #
          lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
        IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
          RAISE global_process_expt;
        END IF;
        --# エラー時は処理終了
        RAISE global_process_expt;
      --# 警告処理
      ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
        --ログ･メッセージの出力
        xx00_file_pkg.log(lv_errbuf);
        xx00_file_pkg.output(lv_errmsg);
        --エラーデータ件数のカウント
        on_err_count := on_err_count + 1;
        ov_retcode := lv_retcode;
        -- =================================================
        --  A-9.仕入先ｲﾝﾀｰﾌｪｰｽﾃｰﾌﾞﾙ更新(upd_ift)
        -- =================================================
        --# 仕入先データ妥当性チェック失敗時（ステータス：警告）
        upd_ift(
          vendor_interface_rec.rowid,  --対象データのROWID
          'E',                         --処理失敗のステータス
          lv_interface_errcode,        --エラー理由コード
          lv_errbuf,         -- エラー・メッセージ           --# 固定 #
          lv_retcode,        -- リターン・コード             --# 固定 #
          lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
        IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
--
      IF (lv_wk_process_status = xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
        -- =================================================
        --  A-5.仕入先マスタへの登録（upd_vendors）
        -- =================================================
        upd_vendors(
          lv_process_mode,       -- 追加/更新モード
          vendor_interface_rec,  -- 仕入先IFTのデータ
          financials_rec,        -- 会計オプションデータ
          payables_rec,          -- 買掛管理オプションデータ
          receipts_rec,          -- 受入オプションデータ
          in_set_of_books_id,    -- 会計帳簿ID
          id_start_date_active,  -- 業務日付
          lr_wk_vendors_rowid,   --ap_vendors_pkg.insert_rowで取得のOUT変数
          lt_wk_vendor_id,       --ap_vendors_pkg.insert_rowで取得のOUT変数
          lv_interface_errcode,  --エラー理由コード
          lv_errbuf,         -- エラー・メッセージ           --# 固定 #
          lv_retcode,        -- リターン・コード             --# 固定 #
          lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
        --# 処理結果を変数に保持
        lv_wk_process_status := lv_retcode;
        --# エラー処理
        IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
          --ログ･メッセージの出力
          xx00_file_pkg.log(lv_errbuf);
          xx00_file_pkg.output(lv_errmsg);
          --エラーデータ件数のカウント
          on_err_count := on_err_count + 1;
          ov_retcode := lv_retcode;
          -- =================================================
          --  A-9.仕入先ｲﾝﾀｰﾌｪｰｽﾃｰﾌﾞﾙ更新(upd_ift)
          -- =================================================
          --# 仕入先マスタ登録失敗時（ステータス：エラー）
          upd_ift(
            vendor_interface_rec.rowid,  --対象データのROWID
            'E',                         --処理失敗のステータス
            lv_interface_errcode,        --エラー理由コード
            lv_errbuf,         -- エラー・メッセージ           --# 固定 #
            lv_retcode,        -- リターン・コード             --# 固定 #
            lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
          IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
            RAISE global_process_expt;
          END IF;
          --# エラー時は処理終了
          RAISE global_process_expt;
        --# 警告処理
        ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
          --ログ･メッセージの出力
          xx00_file_pkg.log(lv_errbuf);
          xx00_file_pkg.output(lv_errmsg);
          --エラーデータ件数のカウント
          on_err_count := on_err_count + 1;
          ov_retcode := lv_retcode;
          -- =================================================
          --  A-9.仕入先ｲﾝﾀｰﾌｪｰｽﾃｰﾌﾞﾙ更新(upd_ift)
          -- =================================================
          --# 仕入先マスタ登録失敗時（ステータス：警告）
          upd_ift(
            vendor_interface_rec.rowid,  --対象データのROWID
            'E',                         --処理失敗のステータス
            lv_interface_errcode,        --エラー理由コード
            lv_errbuf,         -- エラー・メッセージ           --# 固定 #
            lv_retcode,        -- リターン・コード             --# 固定 #
            lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
          IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
      END IF;
--
      IF (lv_wk_process_status = xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
        -- =================================================
        --  A-6.仕入先サイトマスタへの登録（upd_vendor_sites）
        -- =================================================
        upd_vendor_sites(
          lt_wk_vendor_id,      --A-5.upd_vendors(ap_vendors_pkg.insert_row)で取得のOUT変数
          vendor_interface_rec, --仕入先IFTのデータ
          financials_rec,       --会計オプションデータ
          lv_process_mode,      --追加/更新モード
          lv_upd_vs_rowid,      --ap_vendor_site_pkg.update_rowのOUT変数
          ln_upd_vs_vendor_site_id, --ap_vendor_site_pkg.update_rowのOUT変数
          lv_interface_errcode,        --エラー理由コード
          lv_errbuf,            --エラー・メッセージ           --# 固定 #
          lv_retcode,           --リターン・コード             --# 固定 #
          lv_errmsg);           --ユーザー・エラー・メッセージ --# 固定 #
        --# 処理結果を変数に保持
        lv_wk_process_status := lv_retcode;
        --# エラー処理
        IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
          --ログ･メッセージの出力
          xx00_file_pkg.log(lv_errbuf);
          xx00_file_pkg.output(lv_errmsg);
          --エラーデータ件数のカウント
          on_err_count := on_err_count + 1;
          ov_retcode := lv_retcode;
          -- =================================================
          --  A-9.仕入先ｲﾝﾀｰﾌｪｰｽﾃｰﾌﾞﾙ更新(upd_ift)
          -- =================================================
          --# 仕入先サイトマスタ登録失敗時（ステータス：エラー）
          upd_ift(
            vendor_interface_rec.rowid,  --対象データのROWID
            'E',                         --処理失敗のステータス
            lv_interface_errcode,        --エラー理由コード
            lv_errbuf,         -- エラー・メッセージ           --# 固定 #
            lv_retcode,        -- リターン・コード             --# 固定 #
            lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
          IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
            RAISE global_process_expt;
          END IF;
          --# エラー時は処理終了
          RAISE global_process_expt;
        --# 警告処理
        ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
          --ログ･メッセージの出力
          xx00_file_pkg.log(lv_errbuf);
          xx00_file_pkg.output(lv_errmsg);
          --エラーデータ件数のカウント
          on_err_count := on_err_count + 1;
          ov_retcode := lv_retcode;
          -- =================================================
          --  A-9.仕入先ｲﾝﾀｰﾌｪｰｽﾃｰﾌﾞﾙ更新(upd_ift)
          -- =================================================
          --# 仕入先サイトマスタ登録失敗時（ステータス：警告）
          upd_ift(
            vendor_interface_rec.rowid,  --対象データのROWID
            'E',                         --処理失敗のステータス
            lv_interface_errcode,        --エラー理由コード
            lv_errbuf,         -- エラー・メッセージ           --# 固定 #
            lv_retcode,        -- リターン・コード             --# 固定 #
            lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
          IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
      END IF;
--
      IF (lv_wk_process_status = xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
        -- =================================================
        --  A-7.銀行口座マスタへの登録（upd_bank_accounts）
        -- =================================================
        upd_bank_accounts(
          lv_process_mode,       -- 追加/更新モード
          vendor_interface_rec,  -- 仕入先IFTのデータ
          financials_rec,        -- 会計オプションデータ
          payables_rec,          -- 買掛管理オプションデータ
          lt_wk_bank_account_id,  -- 銀行口座ID
          lv_interface_errcode,  -- エラー理由コード
          lv_errbuf,         -- エラー・メッセージ           --# 固定 #
          lv_retcode,        -- リターン・コード             --# 固定 #
          lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
        --# 処理結果を変数に保持
        lv_wk_process_status := lv_retcode;
        --# エラー処理
        IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
          --ログ･メッセージの出力
          xx00_file_pkg.log(lv_errbuf);
          xx00_file_pkg.output(lv_errmsg);
          --エラーデータ件数のカウント
          on_err_count := on_err_count + 1;
          ov_retcode := lv_retcode;
          -- =================================================
          --  A-9.仕入先ｲﾝﾀｰﾌｪｰｽﾃｰﾌﾞﾙ更新(upd_ift)
          -- =================================================
          --# 銀行口座マスタ登録失敗時（ステータス：エラー）
          upd_ift(
            vendor_interface_rec.rowid,  --対象データのROWID
            'E',                         --処理失敗のステータス
            lv_interface_errcode,        --エラー理由コード
            lv_errbuf,         -- エラー・メッセージ           --# 固定 #
            lv_retcode,        -- リターン・コード             --# 固定 #
            lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
          IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
            RAISE global_process_expt;
          END IF;
          --# エラー時は処理終了
          RAISE global_process_expt;
        --# 警告処理
        ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
          --ログ･メッセージの出力
          xx00_file_pkg.log(lv_errbuf);
          xx00_file_pkg.output(lv_errmsg);
          --エラーデータ件数のカウント
          on_err_count := on_err_count + 1;
          ov_retcode := lv_retcode;
          -- =================================================
          --  A-9.仕入先ｲﾝﾀｰﾌｪｰｽﾃｰﾌﾞﾙ更新(upd_ift)
          -- =================================================
          --# 銀行口座マスタ登録失敗時（ステータス：警告）
          upd_ift(
            vendor_interface_rec.rowid,  --対象データのROWID
            'E',                         --処理失敗のステータス
            lv_interface_errcode,        --エラー理由コード
            lv_errbuf,         -- エラー・メッセージ           --# 固定 #
            lv_retcode,        -- リターン・コード             --# 固定 #
            lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
          IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
      END IF;
--
      IF (lv_wk_process_status = xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
        -- =======================================================
        --  A-8.銀行口座割当ﾃｰﾌﾞﾙへの登録（upd_bank_account_uses）
        -- =======================================================
        upd_bank_account_uses(
          lv_process_mode,           -- 追加/更新モード
          lt_wk_vendor_id,           -- upd_vendorsで取得のvendor_id
          ln_upd_vs_vendor_site_id,  -- upd_vendor_sitesで取得のvendor_site_id
          vendor_interface_rec,      -- 仕入先データ
          lt_wk_bank_account_id,      -- 銀行口座ID
          lv_interface_errcode,      -- エラー理由コード
          lv_errbuf,         -- エラー・メッセージ           --# 固定 #
          lv_retcode,        -- リターン・コード             --# 固定 #
          lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
        --# 処理結果を変数に保持
        lv_wk_process_status := lv_retcode;
        --# エラー処理
        IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
          --ログ･メッセージの出力
          xx00_file_pkg.log(lv_errbuf);
          xx00_file_pkg.output(lv_errmsg);
          --エラーデータ件数のカウント
          on_err_count := on_err_count + 1;
          ov_retcode := lv_retcode;
          -- =================================================
          --  A-9.仕入先ｲﾝﾀｰﾌｪｰｽﾃｰﾌﾞﾙ更新(upd_ift)
          -- =================================================
          --# 銀行口座マスタ登録失敗時（ステータス：エラー）
          upd_ift(
            vendor_interface_rec.rowid,  --対象データのROWID
            'E',                         --処理失敗のステータス
            lv_interface_errcode,        --エラー理由コード
            lv_errbuf,         -- エラー・メッセージ           --# 固定 #
            lv_retcode,        -- リターン・コード             --# 固定 #
            lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
          IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
            RAISE global_process_expt;
          END IF;
          --# エラー時は処理終了
          RAISE global_process_expt;
        --# 警告処理
        ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
          --ログ･メッセージの出力
          xx00_file_pkg.log(lv_errbuf);
          xx00_file_pkg.output(lv_errmsg);
          --エラーデータ件数のカウント
          on_err_count := on_err_count + 1;
          ov_retcode := lv_retcode;
          -- =================================================
          --  A-9.仕入先ｲﾝﾀｰﾌｪｰｽﾃｰﾌﾞﾙ更新(upd_ift)
          -- =================================================
          --# 銀行口座マスタ登録失敗時（ステータス：警告）
          upd_ift(
            vendor_interface_rec.rowid,  --対象データのROWID
            'E',                         --処理失敗のステータス
            lv_interface_errcode,        --エラー理由コード
            lv_errbuf,         -- エラー・メッセージ           --# 固定 #
            lv_retcode,        -- リターン・コード             --# 固定 #
            lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
          IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
      END IF;
--
      IF (lv_wk_process_status = xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
        -- =================================================
        --  A-9.仕入先ｲﾝﾀｰﾌｪｰｽﾃｰﾌﾞﾙ更新(upd_ift)
        -- =================================================
        --# すべての登録が正常に終了
        upd_ift(
          vendor_interface_rec.rowid,  --対象データのROWID
          'S',                         --処理失敗のステータス
          NULL,                        --エラー理由コード
          lv_errbuf,         -- エラー・メッセージ           --# 固定 #
          lv_retcode,        -- リターン・コード             --# 固定 #
          lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
        IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
          RAISE global_process_expt;
        END IF;
--
        --処理成功件数のカウント
        on_success_count := on_success_count + 1;
      END IF;
--
    END LOOP vendor_ift_loop;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_process_expt THEN   -- *** 処理部共通例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN global_api_expt THEN   -- *** 共通関数例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  固定部 END   ##########################################
--
  END main_loop;
--
--
  /**********************************************************************************
   * Procedure Name   : del_ift
   * Description      : インポート成功データ削除(A-10)
   ***********************************************************************************/
  PROCEDURE del_ift(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_ift'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
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
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    BEGIN
      DELETE FROM xx03_vendors_interface
      WHERE  status_flag = 'S';
    EXCEPTION
      WHEN OTHERS THEN
        lv_retcode := xx00_common_pkg.set_status_error_f;
    END;
    IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
      RAISE del_ift_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN del_ift_expt THEN       --*** インポート成功データ削除失敗 ***
      -- *** 任意で例外処理を記述する ****
      lv_errbuf := xx00_message_pkg.get_msg(cv_msg_appl_name,
                                           'APP-XX03-00017');
      lv_errmsg := lv_errbuf;
      --ロールバック
      Rollback;
      ov_errmsg := lv_errmsg;                                                           --# 任意 #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# 任意 #
      ov_retcode := xx00_common_pkg.set_status_error_f;                                 --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_api_expt THEN   -- *** 共通関数例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  固定部 END   ##########################################
--
  END del_ift;
--
--
  /**********************************************************************************
   * Procedure Name   : msg_processed_data
   * Description      : メッセージ出力(A-11)
   ***********************************************************************************/
  PROCEDURE msg_processed_data(
    in_target_count  IN  NUMBER,   -- 処理対象件数
    in_err_count     IN  NUMBER,   -- エラーデータ件数
    in_success_count IN  NUMBER,   -- 処理成功件数
    ov_errbuf        OUT VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode       OUT VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg        OUT VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'msg_processed_data'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
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
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- ===============================
    --  対象データ件数出力
    -- ===============================
    xx00_file_pkg.log(xx00_message_pkg.get_msg(cv_msg_appl_name,
                                               'APP-XX03-00023',
                                               'TOK_XX03_ALL_COUNT',
                                               in_target_count));
    xx00_file_pkg.output(xx00_message_pkg.get_msg(cv_msg_appl_name,
                                               'APP-XX03-00023',
                                               'TOK_XX03_ALL_COUNT',
                                               in_target_count));
    -- ===============================
    --  インポート成功データ件数出力
    -- ===============================
    xx00_file_pkg.log(xx00_message_pkg.get_msg(cv_msg_appl_name,
                                               'APP-XX03-00024',
                                               'TOK_XX03_NORMAL_COUNT',
                                               in_success_count));
    xx00_file_pkg.output(xx00_message_pkg.get_msg(cv_msg_appl_name,
                                               'APP-XX03-00024',
                                               'TOK_XX03_NORMAL_COUNT',
                                               in_success_count));
    -- ===============================
    --  エラーデータ件数出力
    -- ===============================
    xx00_file_pkg.log(xx00_message_pkg.get_msg(cv_msg_appl_name,
                                               'APP-XX03-00025',
                                               'TOK_XX03_ERROR_COUNT',
                                               in_err_count));
    xx00_file_pkg.output(xx00_message_pkg.get_msg(cv_msg_appl_name,
                                               'APP-XX03-00025',
                                               'TOK_XX03_ERROR_COUNT',
                                               in_err_count));
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_api_expt THEN   -- *** 共通関数例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  固定部 END   ##########################################
--
  END msg_processed_data;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_force_flag          IN  VARCHAR2,  --強制フラグ
    iv_start_date_active   IN  VARCHAR2,  --業務日付
    ov_errbuf              OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode             OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg              OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    ld_start_date_active      DATE;    --業務日付
    financials_rec            financials_cur%ROWTYPE;     --会計オプションデータ
    payables_rec              payables_cur%ROWTYPE;       --買掛管理オプションデータ
    receipts_rec              rcv_parameters_cur%ROWTYPE; --受入オプションデータ
    lt_chart_of_accounts_id   gl_sets_of_books.chart_of_accounts_id%TYPE;  --勘定体系ID
    ln_set_of_books_id        NUMBER;  --会計帳簿ID
    ln_target_count           NUMBER;  --処理対象件数
    ln_err_count              NUMBER;  --エラーデータ件数
    ln_success_count          NUMBER;  --処理成功件数
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ============================================
    --  A-1.パラメータのチェック（chk_param）
    -- ============================================
    chk_param(
      iv_force_flag,          -- 強制フラグ
      iv_start_date_active,   -- 業務日付
      ld_start_date_active,   -- 業務日付（DATE型）
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
      --(エラー処理)
      RAISE global_process_expt;
    ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
      --(警告処理)
      --submainの終了ステータス(ov_retcode)のセットや
      --エラーメッセージをセットするロジックなどを記述して下さい。
      ov_retcode := xx00_common_pkg.set_status_warn_f;
    END IF;
--
    -- ============================================
    --  A-2.各種データ取得 (get_option_data)
    -- ============================================
    get_option_data(
      financials_rec,  --会計オプションデータ
      payables_rec,    --買掛管理オプションデータ
      receipts_rec,    --受入オプションデータ
      lt_chart_of_accounts_id,  --勘定科目コード
      ln_set_of_books_id,       --会計帳簿ID
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
      --(エラー処理)
      RAISE global_process_expt;
    ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
      --(警告処理)
      --submainの終了ステータス(ov_retcode)のセットや
      --エラーメッセージをセットするロジックなどを記述して下さい。
      ov_retcode := xx00_common_pkg.set_status_warn_f;
    END IF;
--
    -- ============================================
    --  A-3.仕入先データ抽出 (main_loop)
    -- ============================================
    main_loop(
      iv_force_flag,           -- 強制フラグ
      ld_start_date_active,    -- 業務日付(DATE型)
      lt_chart_of_accounts_id, -- 勘定体系ID
      financials_rec,          -- 会計オプションデータ
      payables_rec,            -- 買掛管理オプションデータ
      receipts_rec,            -- 受入オプションデータ
      ln_set_of_books_id,      -- 会計帳簿ID
      ln_target_count,   -- 処理対象件数
      ln_err_count,      -- エラーデータ件数
      ln_success_count,  -- 処理成功件数
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
      --(エラー処理)
      RAISE global_process_expt;
    ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
      --(警告処理)
      --submainの終了ステータス(ov_retcode)のセットや
      --エラーメッセージをセットするロジックなどを記述して下さい。
      ov_retcode := xx00_common_pkg.set_status_warn_f;
    END IF;
--
    -- =========================================
    --  A-10.インポート成功データ削除 (del_ift) 
    -- =========================================
    del_ift(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
      --(エラー処理)
      RAISE global_process_expt;
    ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
      --(警告処理)
      --submainの終了ステータス(ov_retcode)のセットや
      --エラーメッセージをセットするロジックなどを記述して下さい。
      ov_retcode := xx00_common_pkg.set_status_warn_f;
    END IF;
--
    -- =========================================
    --  A-11.メッセージ出力 (msg_processed_data)
    -- =========================================
    msg_processed_data(
      ln_target_count,   -- 処理対象件数
      ln_err_count,      -- エラーデータ件数
      ln_success_count,  -- 処理成功件数
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
      --(エラー処理)
      RAISE global_process_expt;
    ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
      --(警告処理)
      --submainの終了ステータス(ov_retcode)のセットや
      --エラーメッセージをセットするロジックなどを記述して下さい。
      ov_retcode := xx00_common_pkg.set_status_warn_f;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ###################################
--
    WHEN global_process_expt THEN  -- *** 処理部共通例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  --*** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
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
    errbuf                 OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode                OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_force_flag          IN  VARCHAR2,  --強制フラグ
    iv_start_date_active   IN  VARCHAR2)  --業務日付
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
  BEGIN
    -- ===============================
    -- ログヘッダの出力
    -- ===============================
    xx00_file_pkg.log_header;
--
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      iv_force_flag,          -- 強制フラグ
      iv_start_date_active,   -- 業務日付
      lv_errbuf,   -- エラー・メッセージ           --# 固定 #
      lv_retcode,  -- リターン・コード             --# 固定 #
      lv_errmsg);  -- ユーザー・エラー・メッセージ --# 固定 #
--
--###########################  固定部 START   #####################################################
    -- ======================
    -- エラー・メッセージ出力
    -- ======================
    IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
      IF (lv_errmsg IS NULL) THEN
        --定型メッセージ・セット
        lv_errmsg := xx00_message_pkg.get_msg('XX00','APP-XX00-00001');
      ELSIF (lv_errbuf IS NULL) THEN
        --ユーザー・エラー・メッセージのコピー
        lv_errbuf := lv_errmsg;
      END IF;
      xx00_file_pkg.log(lv_errbuf);
      xx00_file_pkg.output(lv_errmsg);
    END IF;
    -- ===============================
    -- ログフッタの出力
    -- ===============================
    xx00_file_pkg.log_footer;
    -- ==================================
    -- リターン・コードのセット、終了処理
    -- ==================================
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = xx00_common_pkg.set_status_error_f) THEN
      ROLLBACK;
    END IF;
  EXCEPTION
    WHEN xx00_global_pkg.global_api_others_expt THEN     -- *** 共通関数OTHERS例外ハンドラ ***
        errbuf := cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM;
        retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN                              -- *** OTHERS例外ハンドラ ***
        errbuf := cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM;
        retcode := xx00_common_pkg.set_status_error_f;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XX03PVI001C;
/
