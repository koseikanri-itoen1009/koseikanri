/************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * View Name       : XXCOP_SALES_EXP_MV
 * Description     : 計画_販売実績マテリアライズドビュー
 * Version         : 1.1
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009-11-26    1.0   SCS.Kikuchi      新規作成
 *  2010-06-17    1.1   SCS.Niki         E_本稼動_03010対応 
 *
 ************************************************************************/
CREATE MATERIALIZED VIEW APPS.XXCOP_SALES_EXP_MV
  TABLESPACE "XXDATA2"
  BUILD IMMEDIATE
  USING INDEX
  REFRESH COMPLETE
  ON DEMAND
  USING DEFAULT LOCAL ROLLBACK SEGMENT
  DISABLE QUERY REWRITE
  AS
  SELECT xsel.delivery_base_code                     -- 納品拠点コード
  ,      xsel.item_code                              -- 品目コード
  ,      NVL(SUM(standard_qty),0) sum_standard_qty   -- 基準数量
  FROM   xxcos_sales_exp_headers xseh                -- 販売実績ヘッダ
  ,      xxcos_sales_exp_lines   xsel                -- 販売実績明細
  WHERE  xseh.sales_exp_header_id =  xsel.sales_exp_header_id
  AND    xseh.dlv_invoice_class   IN ('1','3')       -- 納品伝票区分
-- 2010/06/17 Ver1.1 障害：E_本稼動_03010 Delete Start by SCS.Niki
--  AND    xsel.sales_class         IN ('1','5','6')   -- 売上区分
-- 2010/06/17 Ver1.1 障害：E_本稼動_03010 Delete End by SCS.Niki
  AND    xseh.delivery_date       BETWEEN TRUNC(xxccp_common_pkg2.get_process_date,'MM')
                                  AND     TRUNC(xxccp_common_pkg2.get_process_date) - (1/24/60/60)
  GROUP
  by     xsel.item_code
  ,      xsel.delivery_base_code
  ;
COMMENT ON COLUMN APPS.XXCOP_SALES_EXP_MV.item_code IS '品目コード'
/
COMMENT ON COLUMN APPS.XXCOP_SALES_EXP_MV.delivery_base_code IS '納品拠点コード'
/
COMMENT ON COLUMN APPS.XXCOP_SALES_EXP_MV.sum_standard_qty IS '基準数量合計'
/