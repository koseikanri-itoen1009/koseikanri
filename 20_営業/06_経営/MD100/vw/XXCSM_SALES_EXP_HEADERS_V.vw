CREATE OR REPLACE VIEW APPS.XXCSM_SALES_EXP_HEADERS_V
(
  sales_exp_header_id,
  dlv_invoice_number,
  order_invoice_number,
  order_number,
  order_no_hht,
  digestion_ln_number,
  order_connection_number,
  dlv_invoice_class,
  cancel_correct_class,
  input_class,
  cust_gyotai_sho,
  delivery_date,
  orig_delivery_date,
  inspect_date,
  orig_inspect_date,
  ship_to_customer_code,
  sale_amount_sum,
  pure_amount_sum,
  tax_amount_sum,
  consumption_tax_class,
  tax_code,
  tax_rate,
  results_employee_code,
  sales_base_code,
  receiv_base_code,
  order_source_id,
  card_sale_class,
  invoice_class,
  invoice_classification_code,
  change_out_time_100,
  change_out_time_10,
  ar_interface_flag,
  gl_interface_flag,
  dwh_interface_flag,
  edi_interface_flag,
  edi_send_date,
  hht_dlv_input_date,
  dlv_by_code,
  create_class,
  business_date,
  created_by,
  creation_date,
  last_updated_by,
  last_update_date,
  last_update_login,
  request_id,
  program_application_id,
  program_id,
  program_update_date
)
AS
SELECT sales_exp_header_id,
       dlv_invoice_number,
       order_invoice_number,
       order_number,
       order_no_hht,
       digestion_ln_number,
       order_connection_number,
       dlv_invoice_class,
       cancel_correct_class,
       input_class,
       cust_gyotai_sho,
       delivery_date,
       orig_delivery_date,
       inspect_date,
       orig_inspect_date,
       ship_to_customer_code,
       sale_amount_sum,
       pure_amount_sum,
       tax_amount_sum,
       consumption_tax_class,
       tax_code,
       tax_rate,
       results_employee_code,
       sales_base_code,
       receiv_base_code,
       order_source_id,
       card_sale_class,
       invoice_class,
       invoice_classification_code,
       change_out_time_100,
       change_out_time_10,
       ar_interface_flag,
       gl_interface_flag,
       dwh_interface_flag,
       edi_interface_flag,
       edi_send_date,
       hht_dlv_input_date,
       dlv_by_code,
       create_class,
       business_date,
       created_by,
       creation_date,
       last_updated_by,
       last_update_date,
       last_update_login,
       request_id,
       program_application_id,
       program_id,
       program_update_date
FROM   apps.xxcos_sales_exp_headers
;
--
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.sales_exp_header_id           IS '販売実績ヘッダID';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.dlv_invoice_number            IS '納品伝票番号';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.order_invoice_number          IS '注文伝票番号';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.order_number                  IS '受注番号';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.order_no_hht                  IS '受注No（HHT)';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.digestion_ln_number           IS '受注No（HHT）枝番';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.order_connection_number       IS '受注関連番号';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.dlv_invoice_class             IS '納品伝票区分';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.cancel_correct_class          IS '取消・訂正区分';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.input_class                   IS '入力区分';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.cust_gyotai_sho               IS '業態小分類';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.delivery_date                 IS '納品日';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.orig_delivery_date            IS 'オリジナル納品日';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.inspect_date                  IS '検収日';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.orig_inspect_date             IS 'オリジナル検収日';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.ship_to_customer_code         IS '顧客【納品先】';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.sale_amount_sum               IS '売上金額合計';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.pure_amount_sum               IS '本体金額合計';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.tax_amount_sum                IS '消費税金額合計';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.consumption_tax_class         IS '消費税区分';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.tax_code                      IS '税金コード';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.tax_rate                      IS '消費税率';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.results_employee_code         IS '成績計上者コード';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.sales_base_code               IS '売上拠点コード';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.receiv_base_code              IS '入金拠点コード';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.order_source_id               IS '受注ソースID';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.card_sale_class               IS 'カード売り区分';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.invoice_class                 IS '伝票区分';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.invoice_classification_coDE   IS '伝票分類コード';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.change_out_time_100           IS 'つり銭切れ時間１００円';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.change_out_time_10            IS 'つり銭切れ時間１０円';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.ar_interface_flag             IS 'ARインタフェース済フラグ';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.gl_interface_flag             IS 'GLインタフェース済フラグ';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.dwh_interface_flag            IS '情報システムインタフェース済フラグ';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.edi_interface_flag            IS 'EDI送信済みフラグ';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.edi_send_date                 IS 'EDI送信日時';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.hht_dlv_input_date            IS 'HHT納品入力日時';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.dlv_by_code                   IS '納品者コード';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.create_class                  IS '作成元区分';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.business_date                 IS '登録業務日付';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.created_by                    IS '作成者';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.creation_date                 IS '作成日';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.last_updated_by               IS '最終更新者';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.last_update_date              IS '最終更新日';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.last_update_login             IS '最終更新ﾛｸﾞｲﾝ';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.request_id                    IS '要求ID';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.program_application_id        IS 'ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.program_id                    IS 'ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID';
COMMENT ON COLUMN apps.xxcsm_sales_exp_headers_v.program_update_date           IS 'ﾌﾟﾛｸﾞﾗﾑ更新日';
COMMENT ON TABLE  apps.xxcsm_sales_exp_headers_v                               IS '販売実績ヘッダビュー';
