/*************************************************************************
 * 
 * VIEW Name       : xxcso_quote_lines_store_v
 * Description     : 画面用：帳合問屋用見積画面用ビュー
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2009/02/01    1.0  T.Maruyama    初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW apps.xxcso_quote_lines_store_v
(
 QUOTE_LINE_ID
,QUOTE_HEADER_ID
,REFERENCE_QUOTE_LINE_ID
,INVENTORY_ITEM_ID
,QUOTE_DIV
,USUALLY_DELIV_PRICE
,USUALLY_STORE_SALE_PRICE
,THIS_TIME_DELIV_PRICE
,THIS_TIME_STORE_SALE_PRICE
,QUOTATION_PRICE
,SALES_DISCOUNT_PRICE
,USUALL_NET_PRICE
,THIS_TIME_NET_PRICE
,AMOUNT_OF_MARGIN
,MARGIN_RATE
,QUOTE_START_DATE
,QUOTE_END_DATE
,REMARKS
,LINE_ORDER
,BUSINESS_PRICE
,CREATED_BY
,CREATION_DATE
,LAST_UPDATED_BY
,LAST_UPDATE_DATE
,LAST_UPDATE_LOGIN
,SORT_CODE
,SELECT_FLAG
)
AS
SELECT  store.QUOTE_LINE_ID
       ,store.QUOTE_HEADER_ID
       ,store.REFERENCE_QUOTE_LINE_ID
       ,store.INVENTORY_ITEM_ID
       ,store.QUOTE_DIV
       ,TO_CHAR(store.USUALLY_DELIV_PRICE, 'FM99G990D90')
       ,TO_CHAR(store.USUALLY_STORE_SALE_PRICE, 'FM999G990D90')
       ,TO_CHAR(store.THIS_TIME_DELIV_PRICE, 'FM99G990D90')
       ,TO_CHAR(store.THIS_TIME_STORE_SALE_PRICE, 'FM999G990D90')
       ,TO_CHAR(store.QUOTATION_PRICE, 'FM99G990D90')
       ,TO_CHAR(store.SALES_DISCOUNT_PRICE, 'FM99G990D90')
       ,TO_CHAR(store.USUALL_NET_PRICE, 'FM99G990D90')
       ,TO_CHAR(store.THIS_TIME_NET_PRICE, 'FM99G990D90')
       ,TO_CHAR(store.AMOUNT_OF_MARGIN, 'FM99G990D90')
       ,TO_CHAR(store.MARGIN_RATE, 'FM990D90')
       ,store.QUOTE_START_DATE
       ,store.QUOTE_END_DATE
       ,store.REMARKS
       ,store.LINE_ORDER
       ,store.BUSINESS_PRICE
       ,store.CREATED_BY
       ,store.CREATION_DATE
       ,store.LAST_UPDATED_BY
       ,store.LAST_UPDATE_DATE
       ,store.LAST_UPDATE_LOGIN
       ,1
       ,'Y'
FROM    xxcso_quote_lines    store
WHERE   store.reference_quote_line_id IS NOT NULL
UNION ALL
SELECT  sales.QUOTE_LINE_ID
       ,xqh.QUOTE_HEADER_ID
       ,sales.REFERENCE_QUOTE_LINE_ID
       ,sales.INVENTORY_ITEM_ID
       ,sales.QUOTE_DIV
       ,TO_CHAR(sales.USUALLY_DELIV_PRICE, 'FM99G990D90')
       ,TO_CHAR(sales.USUALLY_STORE_SALE_PRICE, 'FM999G990D90')
       ,TO_CHAR(sales.THIS_TIME_DELIV_PRICE, 'FM99G990D90')
       ,TO_CHAR(sales.THIS_TIME_STORE_SALE_PRICE, 'FM999G990D90')
       ,TO_CHAR(sales.QUOTATION_PRICE, 'FM99G990D90')
       ,TO_CHAR(sales.SALES_DISCOUNT_PRICE, 'FM99G990D90')
       ,TO_CHAR(sales.USUALL_NET_PRICE, 'FM99G990D90')
       ,TO_CHAR(sales.THIS_TIME_NET_PRICE, 'FM99G990D90')
       ,TO_CHAR(sales.AMOUNT_OF_MARGIN, 'FM99G990D90')
       ,TO_CHAR(sales.MARGIN_RATE, 'FM990D90')
       ,sales.QUOTE_START_DATE
       ,sales.QUOTE_END_DATE
       ,sales.REMARKS
       ,sales.LINE_ORDER
       ,sales.BUSINESS_PRICE
       ,sales.CREATED_BY
       ,sales.CREATION_DATE
       ,sales.LAST_UPDATED_BY
       ,sales.LAST_UPDATE_DATE
       ,sales.LAST_UPDATE_LOGIN
       ,2
       ,'N'
FROM    xxcso_quote_headers  xqh
       ,xxcso_quote_lines    sales
WHERE   sales.quote_header_id = xqh.reference_quote_header_id
AND     NOT EXISTS (
          SELECT  1
          FROM    xxcso_quote_lines    store
          WHERE   store.quote_header_id = xqh.quote_header_id
          AND     store.reference_quote_line_id = sales.quote_line_id
        )
WITH READ ONLY
;

COMMENT ON TABLE XXCSO_QUOTE_LINES_STORE_V IS '画面用：帳合問屋用見積画面用ビュー';
