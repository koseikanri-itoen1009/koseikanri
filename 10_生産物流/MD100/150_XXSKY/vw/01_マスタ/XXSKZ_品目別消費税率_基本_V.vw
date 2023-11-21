/*******************************************************************************
 * 
 * View  Name      : XXSKZ_品目別消費税率_基本_V
 * Description     : XXSKZ_品目別消費税率_基本_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------      -------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ------------      -------------------------------------
 *  2023/11/16    1.0   ITOEN H.NAKAMURA 初回作成
 ******************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_品目別消費税率_基本_V
(
 品目コード
,税率
,適用開始日
,適用終了日
,税コード_仕入外税
,税コード_仕入内税
,税コード_売上外税 
,税コード_売上内税
)
AS
SELECT XITR.item_no item_no --品目コード
      ,XITR.tax tax --税率
      ,XITR.start_date_active start_date_active --適用開始日
      ,XITR.end_date_active end_date_active --適用終了日
      ,XITR.tax_code_ex tax_code_ex       -- 税コード（仕入・外税）
      ,XITR.tax_code_in  tax_code_in      -- 税コード（仕入・内税）
      ,XITR.tax_code_sales_ex tax_code_sales_ex -- 税コード（売上・外税）
      ,XITR.tax_code_sales_in tax_code_sales_in -- 税コード（売上・内税）
FROM XXCMM_ITEM_TAX_RATE_V XITR
/
COMMENT ON TABLE APPS.XXSKZ_品目別消費税率_基本_V IS 'SKYLINK用品目別消費税率基本VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_品目別消費税率_基本_V.品目コード             IS '品目コード'
/
COMMENT ON COLUMN APPS.XXSKZ_品目別消費税率_基本_V.税率             IS '税率'
/
COMMENT ON COLUMN APPS.XXSKZ_品目別消費税率_基本_V.適用開始日             IS '適用開始日'
/
COMMENT ON COLUMN APPS.XXSKZ_品目別消費税率_基本_V.適用終了日             IS '適用終了日'
/
COMMENT ON COLUMN APPS.XXSKZ_品目別消費税率_基本_V.税コード_仕入外税             IS '税コード_仕入外税'
/
COMMENT ON COLUMN APPS.XXSKZ_品目別消費税率_基本_V.税コード_仕入内税             IS '税コード_仕入内税'
/
COMMENT ON COLUMN APPS.XXSKZ_品目別消費税率_基本_V.税コード_売上外税             IS '税コード_売上外税'
/
COMMENT ON COLUMN APPS.XXSKZ_品目別消費税率_基本_V.税コード_売上内税             IS '税コード_売上内税'
/