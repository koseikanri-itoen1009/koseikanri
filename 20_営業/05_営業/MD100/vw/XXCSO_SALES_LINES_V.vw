/*************************************************************************
 * 
 * VIEW Name       : xxcso_sales_lines_v
 * Description     : 画面用：商談決定情報入力画面用ビュー
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2009/02/01    1.0  T.Maruyama    初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW apps.xxcso_sales_lines_v
(
 SALES_LINE_ID
,SALES_HEADER_ID
,QUOTE_NUMBER
,QUOTE_REVISION_NUMBER
,INVENTORY_ITEM_ID
,SALES_CLASS_CODE
,SALES_ADOPT_CLASS_CODE
,SALES_AREA_CODE
,SALES_SCHEDULE_DATE
,DELIV_PRICE
,STORE_SALES_PRICE
,STORE_SALES_PRICE_INC_TAX
,QUOTATION_PRICE
,INTRODUCE_TERMS
,NOTIFY_FLAG
,CREATED_BY
,CREATION_DATE
,LAST_UPDATED_BY
,LAST_UPDATE_DATE
,LAST_UPDATE_LOGIN
,REQUEST_ID
,PROGRAM_APPLICATION_ID
,PROGRAM_ID
,PROGRAM_UPDATE_DATE
)
AS
SELECT
 SALES_LINE_ID
,SALES_HEADER_ID
,QUOTE_NUMBER
,QUOTE_REVISION_NUMBER
,INVENTORY_ITEM_ID
,SALES_CLASS_CODE
,SALES_ADOPT_CLASS_CODE
,SALES_AREA_CODE
,SALES_SCHEDULE_DATE
,TO_CHAR(DELIV_PRICE, 'FM99G990D90')
,TO_CHAR(STORE_SALES_PRICE, 'FM999G990D90')
,TO_CHAR(STORE_SALES_PRICE_INC_TAX, 'FM999G990D90')
,TO_CHAR(QUOTATION_PRICE, 'FM99G990D90')
,INTRODUCE_TERMS
,NOTIFY_FLAG
,CREATED_BY
,CREATION_DATE
,LAST_UPDATED_BY
,LAST_UPDATE_DATE
,LAST_UPDATE_LOGIN
,REQUEST_ID
,PROGRAM_APPLICATION_ID
,PROGRAM_ID
,PROGRAM_UPDATE_DATE
FROM
 xxcso_sales_lines
WITH READ ONLY
;

COMMENT ON TABLE XXCSO_SALES_LINES_V IS '画面用：商談決定情報入力画面用ビュー';
