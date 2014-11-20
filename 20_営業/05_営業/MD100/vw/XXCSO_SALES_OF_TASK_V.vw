/*************************************************************************
 * 
 * VIEW Name       : xxcso_sales_of_task_v
 * Description     : 共通用：有効訪問販売実績ビュー
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2009/11/24    1.0  D.Abe        初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW apps.xxcso_sales_of_task_v
(
 account_number
,order_no_hht
,cancel_correct_class
,delivery_date
,change_out_time_100
,change_out_time_10
,delivery_pattern_class
,pure_amount
,sold_out_class
,sold_out_time
,dlv_invoice_number
,digestion_ln_number
)
AS
SELECT  seh.ship_to_customer_code      -- 顧客【納品先】
       ,seh.order_no_hht               -- 受注No(HHT)
       ,seh.cancel_correct_class       -- 取消・訂正区分
       ,seh.delivery_date              -- 納品日
       ,seh.change_out_time_100        -- つり銭切れ時間１００円
       ,seh.change_out_time_10         -- つり銭切れ時間１０円
       ,sel.delivery_pattern_class     -- 納品形態区分
       ,sel.pure_amount                -- 本体金額（明細）
       ,sel.sold_out_class             -- 売切区分
       ,sel.sold_out_time              -- 売切時間
       ,seh.dlv_invoice_number         -- 納品伝票番号
       ,seh.digestion_ln_number        -- 受注No（HHT）枝番
FROM    xxcos_sales_exp_headers seh -- 販売実績ヘッダー
       ,xxcos_sales_exp_lines   sel -- 販売実績明細
WHERE  seh.sales_exp_header_id = sel.sales_exp_header_id  -- 販売実績ヘッダID
AND    NOT EXISTS
       ( -- 品目コード<>変動電気料品目コード
         SELECT 'X'
         FROM   DUAL
         WHERE  sel.item_code = fnd_profile.value('XXCOS1_ELECTRIC_FEE_ITEM_CODE')
       )
WITH READ ONLY
;

COMMENT ON TABLE XXCSO_SALES_OF_TASK_V IS '共通用：有効訪問販売実績ビュー';

