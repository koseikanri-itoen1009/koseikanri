/*************************************************************************
 * 
 * VIEW Name       : xxcso_quote_lines_sales_v
 * Description     : 画面用：販売先用見積画面用ビュー
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2009/02/01    1.0  T.Maruyama    初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW apps.xxcso_quote_lines_sales_v
(
 quote_line_id
,quote_header_id
,reference_quote_line_id
,inventory_item_id
,quote_div
,usually_deliv_price
,usually_store_sale_price
,this_time_deliv_price
,this_time_store_sale_price
,quotation_price
,sales_discount_price
,usuall_net_price
,this_time_net_price
,amount_of_margin
,margin_rate
,quote_start_date
,quote_end_date
,remarks
,line_order
,business_price
,created_by
,creation_date
,last_updated_by
,last_update_date
,last_update_login
,request_id
,program_application_id
,program_id
,program_update_date
)
AS
SELECT
 xql.quote_line_id
,xql.quote_header_id
,xql.reference_quote_line_id
,xql.inventory_item_id
,xql.quote_div
,TO_CHAR(xql.usually_deliv_price,'FM99G990D90')
,TO_CHAR(xql.usually_store_sale_price,'FM999G990D90')
,TO_CHAR(xql.this_time_deliv_price,'FM99G990D90')
,TO_CHAR(xql.this_time_store_sale_price,'FM999G990D90')
,xql.quotation_price
,xql.sales_discount_price
,xql.usuall_net_price
,xql.this_time_net_price
,xql.amount_of_margin
,xql.margin_rate
,xql.quote_start_date
,xql.quote_end_date
,xql.remarks
,xql.line_order
,xql.business_price
,xql.created_by
,xql.creation_date
,xql.last_updated_by
,xql.last_update_date
,xql.last_update_login
,xql.request_id
,xql.program_application_id
,xql.program_id
,xql.program_update_date
FROM
 xxcso_quote_lines xql
WITH READ ONLY
;

COMMENT ON TABLE XXCSO_QUOTE_LINES_SALES_V IS '画面用：販売先用見積画面用ビュー';
