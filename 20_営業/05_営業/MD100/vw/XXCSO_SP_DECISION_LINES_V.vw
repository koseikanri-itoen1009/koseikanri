/*************************************************************************
 * 
 * VIEW Name       : xxcso_sp_decision_lines_v
 * Description     : 画面用：SP専決登録画面用ビュー
 * MD.070          : 
 * Version         : 1.1
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2009/02/01    1.0  T.Maruyama    初回作成
 *  2014/01/31    1.1  K.Kiriu       [E_本稼動_11397]売価1円対応
 ************************************************************************/
CREATE OR REPLACE VIEW apps.xxcso_sp_decision_lines_v
(
 SP_DECISION_LINE_ID
,SP_DECISION_HEADER_ID
,SP_CONTAINER_TYPE
,FIXED_PRICE
-- 2014/01/31 Ver.1.1 Add Start
,CARD_SALE_CLASS
-- 2014/01/31 Ver.1.1 Add End
,SALES_PRICE
,DISCOUNT_AMT
,BM_RATE_PER_SALES_PRICE
,BM_AMOUNT_PER_SALES_PRICE
,BM_CONV_RATE_PER_SALES_PRICE
,BM1_BM_RATE
,BM1_BM_AMOUNT
,BM2_BM_RATE
,BM2_BM_AMOUNT
,BM3_BM_RATE
,BM3_BM_AMOUNT
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
 xsdl.SP_DECISION_LINE_ID
,xsdl.SP_DECISION_HEADER_ID
,xsdl.SP_CONTAINER_TYPE
,TO_CHAR(xsdl.FIXED_PRICE)
,xsdl.card_sale_class
,TO_CHAR(xsdl.SALES_PRICE, 'FM999G999G999G999G990')
,TO_CHAR(xsdl.DISCOUNT_AMT, 'FM999G999G999G999G990')
,TO_CHAR(xsdl.BM_RATE_PER_SALES_PRICE, 'FM999G999G999G999G990D90')
,TO_CHAR(xsdl.BM_AMOUNT_PER_SALES_PRICE, 'FM999G999G999G999G990D90')
,TO_CHAR(xsdl.BM_CONV_RATE_PER_SALES_PRICE, 'FM999G999G999G999G990D90')
,TO_CHAR(xsdl.BM1_BM_RATE, 'FM999G999G999G999G990D90')
,TO_CHAR(xsdl.BM1_BM_AMOUNT, 'FM999G999G999G999G990D90')
,TO_CHAR(xsdl.BM2_BM_RATE, 'FM999G999G999G999G990D90')
,TO_CHAR(xsdl.BM2_BM_AMOUNT, 'FM999G999G999G999G990D90')
,TO_CHAR(xsdl.BM3_BM_RATE, 'FM999G999G999G999G990D90')
,TO_CHAR(xsdl.BM3_BM_AMOUNT, 'FM999G999G999G999G990D90')
,xsdl.CREATED_BY
,xsdl.CREATION_DATE
,xsdl.LAST_UPDATED_BY
,xsdl.LAST_UPDATE_DATE
,xsdl.LAST_UPDATE_LOGIN
,xsdl.REQUEST_ID
,xsdl.PROGRAM_APPLICATION_ID
,xsdl.PROGRAM_ID
,xsdl.PROGRAM_UPDATE_DATE
FROM XXCSO_SP_DECISION_LINES    xsdl
WITH READ ONLY
;

COMMENT ON TABLE XXCSO_SP_DECISION_LINES_V IS '画面用：SP専決登録画面用ビュー';
