CREATE OR REPLACE VIEW APPS.XXCSM_SALES_EXP_LINES_V
(
  sales_exp_line_id,
  sales_exp_header_id,
  dlv_invoice_number,
  dlv_invoice_line_number,
  order_invoice_line_number,
  sales_class,
  delivery_pattern_class,
  red_black_flag,
  item_code,
  dlv_qty,
  standard_qty,
  dlv_uom_code,
  standard_uom_code,
  dlv_unit_price,
  standard_unit_price_excluded,
  standard_unit_price,
  business_cost,
  sale_amount,
  pure_amount,
  tax_amount,
  cash_and_card,
  ship_from_subinventory_code,
  delivery_base_code,
  hot_cold_class,
  column_no,
  sold_out_class,
  sold_out_time,
  to_calculate_fees_flag,
  unit_price_mst_flag,
  inv_interface_flag,
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
SELECT sales_exp_line_id,
       sales_exp_header_id,
       dlv_invoice_number,
       dlv_invoice_line_number,
       order_invoice_line_number,
       sales_class,
       delivery_pattern_class,
       red_black_flag,
       item_code,
       dlv_qty,
       standard_qty,
       dlv_uom_code,
       standard_uom_code,
       dlv_unit_price,
       standard_unit_price_excluded,
       standard_unit_price,
       business_cost,
       sale_amount,
       pure_amount,
       tax_amount,
       cash_and_card,
       ship_from_subinventory_code,
       delivery_base_code,
       hot_cold_class,
       column_no,
       sold_out_class,
       sold_out_time,
       to_calculate_fees_flag,
       unit_price_mst_flag,
       inv_interface_flag,
       created_by,
       creation_date,
       last_updated_by,
       last_update_date,
       last_update_login,
       request_id,
       program_application_id,
       program_id,
       program_update_date
FROM apps.xxcos_sales_exp_lines
;
--
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.sales_exp_line_id              IS '販売実績明細ID'; 
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.sales_exp_header_id            IS '販売実績ヘッダID';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.dlv_invoice_number             IS '納品伝票番号';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.dlv_invoice_line_number        IS '納品明細番号';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.order_invoice_line_number      IS '注文明細番号';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.sales_class                    IS '売上区分';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.delivery_pattern_class         IS '納品形態区分';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.red_black_flag                 IS '赤黒フラグ';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.item_code                      IS '品目コード';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.dlv_qty                        IS '納品数量';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.standard_qty                   IS '基準数量';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.dlv_uom_code                   IS '納品単位';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.standard_uom_code              IS '基準単位';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.dlv_unit_price                 IS '納品単価';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.standard_unit_price_excluded   IS '税抜基準単価';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.standard_unit_price            IS '基準単価';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.business_cost                  IS '営業原価';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.sale_amount                    IS '売上金額';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.pure_amount                    IS '本体金額';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.tax_amount                     IS '消費税金額';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.cash_and_card                  IS '現金・カード併用額';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.ship_from_subinventory_code    IS '出荷元保管場所';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.delivery_base_code             IS '納品拠点コード';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.hot_cold_class                 IS 'Ｈ＆Ｃ';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.column_no                      IS 'コラムNo';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.sold_out_class                 IS '売切区分';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.sold_out_time                  IS '売切時間';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.to_calculate_fees_flag         IS '手数料計算インタフェース済フラグ';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.unit_price_mst_flag            IS '単価マスタ作成済フラグ';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.inv_interface_flag             IS 'INVインタフェース済フラグ';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.created_by                     IS '作成者';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.creation_date                  IS '作成日';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.last_updated_by                IS '最終更新者';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.last_update_date               IS '最終更新日';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.last_update_login              IS '最終更新ﾛｸﾞｲﾝ';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.request_id                     IS '要求ID';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.program_application_id         IS 'ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.program_id                     IS 'ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.program_update_date            IS 'ﾌﾟﾛｸﾞﾗﾑ更新日';
COMMENT ON TABLE  apps.xxcsm_sales_exp_lines_v                                IS '販売実績明細ビュー';
