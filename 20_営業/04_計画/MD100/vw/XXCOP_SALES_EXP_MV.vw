/************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * View Name       : XXCOP_SALES_EXP_MV
 * Description     : væ_ÌÀÑ}eACYhr[
 * Version         : 1.1
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009-11-26    1.0   SCS.Kikuchi      VKì¬
 *  2010-06-17    1.1   SCS.Niki         E_{Ò®_03010Î 
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
  SELECT xsel.delivery_base_code                     -- [i_R[h
  ,      xsel.item_code                              -- iÚR[h
  ,      NVL(SUM(standard_qty),0) sum_standard_qty   -- îÊ
  FROM   xxcos_sales_exp_headers xseh                -- ÌÀÑwb_
  ,      xxcos_sales_exp_lines   xsel                -- ÌÀÑ¾×
  WHERE  xseh.sales_exp_header_id =  xsel.sales_exp_header_id
  AND    xseh.dlv_invoice_class   IN ('1','3')       -- [i`[æª
-- 2010/06/17 Ver1.1 áQFE_{Ò®_03010 Delete Start by SCS.Niki
--  AND    xsel.sales_class         IN ('1','5','6')   -- ãæª
-- 2010/06/17 Ver1.1 áQFE_{Ò®_03010 Delete End by SCS.Niki
  AND    xseh.delivery_date       BETWEEN TRUNC(xxccp_common_pkg2.get_process_date,'MM')
                                  AND     TRUNC(xxccp_common_pkg2.get_process_date) - (1/24/60/60)
  GROUP
  by     xsel.item_code
  ,      xsel.delivery_base_code
  ;
COMMENT ON COLUMN APPS.XXCOP_SALES_EXP_MV.item_code IS 'iÚR[h'
/
COMMENT ON COLUMN APPS.XXCOP_SALES_EXP_MV.delivery_base_code IS '[i_R[h'
/
COMMENT ON COLUMN APPS.XXCOP_SALES_EXP_MV.sum_standard_qty IS 'îÊv'
/