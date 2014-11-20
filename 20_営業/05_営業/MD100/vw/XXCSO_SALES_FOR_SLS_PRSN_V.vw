/*************************************************************************
 * 
 * VIEW Name       : xxcso_sales_for_sls_prsn_v
 * Description     : 共通用：ルート営業員用売上実績ビュー
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2009/02/01    1.0  T.Maruyama    初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW apps.xxcso_sales_for_sls_prsn_v
(
  account_number
 ,order_no_hht
 ,delivery_date
 ,pure_amount
)
AS
SELECT xsv.account_number    -- 顧客【納品先】
      ,xsv.order_no_hht      -- 受注No(HHT)
      ,xsv.delivery_date     -- 納品日
      ,xsv.pure_amount       -- 本体金額（明細）
FROM   xxcso_sales_v xsv
WHERE  xsv.delivery_pattern_class in ('1','2','3','4','6') -- 納品形態区分（5:他拠点倉庫売上以外）
WITH READ ONLY
;

COMMENT ON TABLE XXCSO_SALES_FOR_SLS_PRSN_V IS '共通用：ルート営業員用売上実績ビュー';
