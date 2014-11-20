CREATE OR REPLACE PACKAGE xxcok_common_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcok_common_pkg(spec)
 * Description      : 個別開発領域・共通関数
 * MD.070           : MD070_IPO_COK_共通関数
 * Version          : 1.2
 *
 * Program List
 * --------------------------   ------------------------------------------------------------
 *  Name                         Description
 * --------------------------   ------------------------------------------------------------
 *  get_acctg_calendar_p         会計カレンダ取得
 *  get_next_year_p              翌会計年度取得
 *  get_set_of_books_info_p      会計帳簿情報取得
 *  get_close_date_p             締め・支払日取得
 *  get_emp_code_f               従業員コード取得
 *  check_acctg_period_f         会計期間チェック
 *  get_operating_day_f          稼働日取得
 *  get_sales_staff_code_f       担当営業員コード取得
 *  get_wholesale_req_est_p      問屋請求見積照合
 *  get_wholesale_req_est_type_f 問屋請求書見積書突合ステータス取得
 *  get_companies_code_f         企業コード取得
 *  get_department_code_f        所属部門コード取得
 *  get_batch_name_f             バッチ名取得
 *  get_slip_number_f            伝票番号取得
 *  check_year_migration_f       年次移行情報確定チェック
 *  get_code_combination_id_f    CCID取得
 *  put_message_f                メッセージ出力
 *  get_base_code_f              所属拠点コード取得
 *  split_csv_data_p             CSV文字列分割
 *  get_bill_to_cust_code_f      請求先顧客コード取得
 *  check_code_combination_id_f  CCIDチェック
 *  get_uom_conversion_qty_f     基準単位換算数取得
 *  get_directory_path_f         ディレクトリパス取得
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/10/31    1.0   T.OSADA          新規作成
 *  2009/02/06    1.1   K.YAMAGUCHI      [障害COK_022] ディレクトリパス取得追加
 *  2012/03/06    1.2   SCSK K.Nakamura  [E_本稼動_08318] 問屋請求見積照合 OUTに通常NET価格、今回NET価格を追加
 *  
 *****************************************************************************************/
  -- ===============================
  -- グローバル型
  -- ===============================
  -- 分割後CSV(VARCHAR2)データを格納する配列
  TYPE g_split_csv_tbl IS TABLE OF VARCHAR2(32767) INDEX BY PLS_INTEGER;
  --共通関数プロシージャ・会計カレンダ取得
  PROCEDURE get_acctg_calendar_p(
    ov_errbuf                   OUT VARCHAR2             -- エラーバッファ
  , ov_retcode                  OUT VARCHAR2             -- リターンコード
  , ov_errmsg                   OUT VARCHAR2             -- エラーメッセージ
  , in_set_of_books_id          IN  NUMBER               -- 会計帳簿ID
  , iv_application_short_name   IN  VARCHAR2             -- アプリケーション短縮名
  , id_object_date              IN  DATE                 -- 対象日
  , iv_adjustment_period_flag   IN  VARCHAR2 DEFAULT 'N' -- 調整フラグ
  , on_period_year              OUT NUMBER               -- 会計年度
  , ov_period_name              OUT VARCHAR2             -- 会計期間名
  , ov_closing_status           OUT VARCHAR2             -- ステータス
  );
  --共通関数プロシージャ・翌会計年度取得
  PROCEDURE get_next_year_p(
    ov_errbuf                   OUT VARCHAR2                              -- エラー・バッファ
  , ov_retcode                  OUT VARCHAR2                              -- リターン・コード
  , ov_errmsg                   OUT VARCHAR2                              -- エラー・メッセージ
  , in_set_of_books_id          IN  gl_sets_of_books.set_of_books_id%TYPE -- 会計帳簿ID
  , in_period_year              IN  gl_periods.period_year%TYPE           -- 会計年度
  , on_next_period_year         OUT gl_periods.period_year%TYPE           -- 翌会計年度
  , od_next_start_date          OUT gl_periods.start_date%TYPE            -- 翌会計年度期首日
  );
  --共通関数プロシージャ・会計帳簿情報取得
  PROCEDURE get_set_of_books_info_p(
    ov_errbuf                   OUT VARCHAR2            -- エラー・バッファ
  , ov_retcode                  OUT VARCHAR2            -- リターンコード
  , ov_errmsg                   OUT VARCHAR2            -- エラー・メッセージ
  , on_set_of_books_id          OUT NUMBER              -- 会計帳簿ID
  , ov_set_of_books_name        OUT VARCHAR2            -- 会計帳簿名
  , on_chart_acct_id            OUT NUMBER              -- 勘定体系ID
  , ov_period_set_name          OUT VARCHAR2            -- カレンダ名
  , on_aff_segment_cnt          OUT NUMBER              -- AFFセグメント定義数
  , ov_currency_code            OUT VARCHAR2            -- 機能通貨コード
  );
  --共通関数プロシージャ・締め・支払日取得
  PROCEDURE get_close_date_p(
    ov_errbuf                   OUT VARCHAR2            -- エラー・バッファ
  , ov_retcode                  OUT VARCHAR2            -- リターンコード
  , ov_errmsg                   OUT VARCHAR2            -- エラー・メッセージ
  , id_proc_date                IN  DATE DEFAULT NULL   -- 処理日(対象日)
  , iv_pay_cond                 IN  VARCHAR2            -- 支払条件(IN)
  , od_close_date               OUT DATE                -- 締め日(OUT)
  , od_pay_date                 OUT DATE                -- 支払日(OUT)
  );
  --共通関数ファンクション・従業員コード取得
  FUNCTION get_emp_code_f(
    in_user_id                  IN NUMBER               -- ユーザID
  )
  RETURN VARCHAR2;                                      --従業員コード
  --共通関数ファンクション・会計期間チェック
  FUNCTION check_acctg_period_f(
    in_set_of_books_id          IN NUMBER               -- 会計帳簿ID
  , id_proc_date                IN DATE                 -- 処理日(対象日)
  , iv_application_short_name   IN VARCHAR2             -- アプリケーション短縮名
  )
  RETURN BOOLEAN;                                       -- BOOLEAN型 TRUE/FALSE
  --共通関数ファンクション・営業日取得
  FUNCTION get_operating_day_f(
    id_proc_date                IN DATE                 -- 処理日 
  , in_days                     IN NUMBER               -- 日数 
  , in_proc_type                IN NUMBER               -- 処理区分 
  , in_calendar_type            IN NUMBER DEFAULT 0     -- カレンダー区分
  )
  RETURN DATE;                                          -- 営業日
  --共通関数ファンクション・担当営業員コード取得
  FUNCTION get_sales_staff_code_f(
    iv_customer_code            IN VARCHAR2             -- 顧客コード 
  , id_proc_date                IN DATE                 -- 処理日 
  )
  RETURN VARCHAR2;                                      -- 担当営業員コード
  --共通関数プロシージャ・問屋請求見積照合
  PROCEDURE get_wholesale_req_est_p(
    ov_errbuf                   OUT VARCHAR2            -- エラーバッファ
  , ov_retcode                  OUT VARCHAR2            -- リターンコード
  , ov_errmsg                   OUT VARCHAR2            -- エラーメッセージ
  , iv_wholesale_code           IN  VARCHAR2            -- 問屋管理コード
  , iv_sales_outlets_code       IN  VARCHAR2            -- 問屋帳合先コード
  , iv_item_code                IN  VARCHAR2            -- 品目コード
  , in_demand_unit_price        IN  NUMBER              -- 請求単価
  , iv_demand_unit_type         IN  VARCHAR2            -- 請求単位
  , iv_selling_month            IN  VARCHAR2            -- 売上対象年月
  , ov_estimated_no             OUT VARCHAR2            -- 見積書No.
  , on_quote_line_id            OUT NUMBER              -- 明細ID
  , ov_emp_code                 OUT VARCHAR2            -- 担当者コード
  , on_market_amt               OUT NUMBER              -- 建値
  , on_allowance_amt            OUT NUMBER              -- 値引(割戻し)
  , on_normal_store_deliver_amt OUT NUMBER              -- 通常店納
  , on_once_store_deliver_amt   OUT NUMBER              -- 今回店納
  , on_net_selling_price        OUT NUMBER              -- NET価格
-- 2012/03/06 Ver.1.2 [E_本稼動_08318] SCSK K.Nakamura ADD START
  , on_normal_net_selling_price OUT NUMBER              -- 通常NET価格(NET差照合時のみ)
-- 2012/03/06 Ver.1.2 [E_本稼動_08318] SCSK K.Nakamura ADD END
  , ov_estimated_type           OUT VARCHAR2            -- 見積区分
  , on_backmargin_amt           OUT NUMBER              -- 販売手数料
  , on_sales_support_amt        OUT NUMBER              -- 販売協賛金
  );
  --共通関数ファンクション・問屋請求書見積書突合ステータス取得
  FUNCTION get_wholesale_req_est_type_f(
    iv_wholesale_code           IN  VARCHAR2            -- 問屋管理コード
  , iv_sales_outlets_code       IN  VARCHAR2            -- 問屋帳合先コード
  , iv_item_code                IN  VARCHAR2            -- 品目コード
  , in_demand_unit_price        IN  NUMBER              -- 請求単価
  , iv_demand_unit_type         IN  VARCHAR2            -- 請求単位
  , iv_selling_month            IN  VARCHAR2            -- 売上対象年月
  )
  RETURN VARCHAR2;                                      -- ステータス
  --共通関数ファンクション・企業コード取得
  FUNCTION get_companies_code_f(
    iv_customer_code            IN  VARCHAR2            -- 顧客コード
  )
  RETURN VARCHAR2;                                      -- 企業コード
  --共通関数ファンクション・所属部門コード取得
  FUNCTION get_department_code_f(
    in_user_id                  IN  NUMBER              -- ユーザーID
  )
  RETURN VARCHAR2;                                      -- 所属部門コード
  --共通関数ファンクション・バッチ名取得
  FUNCTION get_batch_name_f(
    iv_category_name            IN  VARCHAR2            -- 仕訳カテゴリ
  )
  RETURN VARCHAR2;                                      -- バッチ名
  --共通関数ファンクション・伝票番号取得
  FUNCTION get_slip_number_f(
    iv_package_name             IN  VARCHAR2            -- パッケージ名
  )
  RETURN VARCHAR2;                                      -- 伝票番号
  --共通関数ファンクション・年次移行情報確定チェック
  FUNCTION check_year_migration_f(
    in_year                     IN  NUMBER              -- 年度
  )
  RETURN BOOLEAN;                                       -- ブール値
  --共通関数ファンクション・CCID取得
  FUNCTION get_code_combination_id_f(
    id_proc_date                IN  DATE                -- 処理日
  , iv_segment1                 IN  VARCHAR2            -- 会社コード
  , iv_segment2                 IN  VARCHAR2            -- 部門コード
  , iv_segment3                 IN  VARCHAR2            -- 勘定科目コード
  , iv_segment4                 IN  VARCHAR2            -- 補助科目コード
  , iv_segment5                 IN  VARCHAR2            -- 顧客コード
  , iv_segment6                 IN  VARCHAR2            -- 企業コード
  , iv_segment7                 IN  VARCHAR2            -- 予備１コード
  , iv_segment8                 IN  VARCHAR2            -- 予備２コード
  )
  RETURN NUMBER;                                        -- 勘定科目ID
  --共通関数ファンクション・メッセージ出力
  FUNCTION put_message_f(
    in_which                    IN  NUMBER              -- 出力区分
  , iv_message                  IN  VARCHAR2            -- メッセージ
  , in_new_line                 IN  NUMBER              -- 改行
  )
  RETURN BOOLEAN;                                       -- BOOLEAN型 TRUE/FALSE
  --共通関数ファンクション・所属拠点コード取得
  FUNCTION get_base_code_f(
    id_proc_date                IN  DATE                -- 処理日
  , in_user_id                  IN  NUMBER              -- ユーザーID
  )
  RETURN VARCHAR2;                                      -- 所属拠点
  --共通関数プロシージャ・CSV文字列分割
  PROCEDURE split_csv_data_p(
    ov_errbuf                   OUT VARCHAR2            -- エラーバッファ
  , ov_retcode                  OUT VARCHAR2            -- リターンコード
  , ov_errmsg                   OUT VARCHAR2            -- エラーメッセージ
  , iv_csv_data                 IN  VARCHAR2            -- CSV文字列
  , on_csv_col_cnt              OUT PLS_INTEGER         -- CSV項目数
  , ov_split_csv_tab            OUT g_split_csv_tbl     -- CSV分割データ
  );
  --共通関数ファンクション・請求先顧客コード取得
  FUNCTION get_bill_to_cust_code_f(
    iv_ship_to_cust_code        IN VARCHAR2             -- 出荷先顧客コード
  )
  RETURN VARCHAR2;                                      -- 請求先顧客コード
  --共通関数ファンクション・CCID存在チェック
  FUNCTION check_code_combination_id_f(
    iv_segment1                 IN  VARCHAR2            -- 会社コード
  , iv_segment2                 IN  VARCHAR2            -- 部門コード
  , iv_segment3                 IN  VARCHAR2            -- 勘定科目コード
  , iv_segment4                 IN  VARCHAR2            -- 補助科目コード
  , iv_segment5                 IN  VARCHAR2            -- 顧客コード
  , iv_segment6                 IN  VARCHAR2            -- 企業コード
  , iv_segment7                 IN  VARCHAR2            -- 予備１コード
  , iv_segment8                 IN  VARCHAR2            -- 予備２コード
  )
  RETURN BOOLEAN;                                       -- ブール値
  --共通関数ファンクション・基準単位換算数取得
  FUNCTION get_uom_conversion_qty_f(
    iv_item_code                IN  VARCHAR2            -- 品目コード
  , iv_uom_code                 IN  VARCHAR2            -- 単位コード
  , in_quantity                 IN  NUMBER              -- 換算前数量
  )
  RETURN NUMBER;                                        -- 基準単位換算後数量
  --共通関数ファンクション・ディレクトリパス取得
  FUNCTION get_directory_path_f(
    iv_directory_name              IN  VARCHAR2         -- ディレクトリ名
  )
  RETURN VARCHAR2;                                      -- ディレクトリパス
--
END xxcok_common_pkg;
/
