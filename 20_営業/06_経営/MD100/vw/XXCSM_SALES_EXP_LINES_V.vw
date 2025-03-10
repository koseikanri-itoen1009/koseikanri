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
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.sales_exp_line_id              IS 'ÌÀÑ¾×ID'; 
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.sales_exp_header_id            IS 'ÌÀÑwb_ID';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.dlv_invoice_number             IS '[i`[Ô';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.dlv_invoice_line_number        IS '[i¾×Ô';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.order_invoice_line_number      IS '¶¾×Ô';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.sales_class                    IS 'ãæª';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.delivery_pattern_class         IS '[i`Ôæª';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.red_black_flag                 IS 'ÔtO';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.item_code                      IS 'iÚR[h';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.dlv_qty                        IS '[iÊ';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.standard_qty                   IS 'îÊ';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.dlv_uom_code                   IS '[iPÊ';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.standard_uom_code              IS 'îPÊ';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.dlv_unit_price                 IS '[iP¿';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.standard_unit_price_excluded   IS 'Å²îP¿';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.standard_unit_price            IS 'îP¿';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.business_cost                  IS 'cÆ´¿';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.sale_amount                    IS 'ãàz';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.pure_amount                    IS '{Ìàz';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.tax_amount                     IS 'ÁïÅàz';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.cash_and_card                  IS '»àEJ[h¹pz';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.ship_from_subinventory_code    IS 'o×³ÛÇê';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.delivery_base_code             IS '[i_R[h';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.hot_cold_class                 IS 'gb';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.column_no                      IS 'RNo';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.sold_out_class                 IS 'Øæª';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.sold_out_time                  IS 'ØÔ';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.to_calculate_fees_flag         IS 'è¿vZC^tF[XÏtO';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.unit_price_mst_flag            IS 'P¿}X^ì¬ÏtO';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.inv_interface_flag             IS 'INVC^tF[XÏtO';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.created_by                     IS 'ì¬Ò';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.creation_date                  IS 'ì¬ú';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.last_updated_by                IS 'ÅIXVÒ';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.last_update_date               IS 'ÅIXVú';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.last_update_login              IS 'ÅIXVÛ¸Þ²Ý';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.request_id                     IS 'vID';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.program_application_id         IS 'ºÝ¶ÚÝÄ¥ÌßÛ¸Þ×Ñ¥±ÌßØ¹°¼®ÝID';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.program_id                     IS 'ºÝ¶ÚÝÄ¥ÌßÛ¸Þ×ÑID';
COMMENT ON COLUMN apps.xxcsm_sales_exp_lines_v.program_update_date            IS 'ÌßÛ¸Þ×ÑXVú';
COMMENT ON TABLE  apps.xxcsm_sales_exp_lines_v                                IS 'ÌÀÑ¾×r[';
