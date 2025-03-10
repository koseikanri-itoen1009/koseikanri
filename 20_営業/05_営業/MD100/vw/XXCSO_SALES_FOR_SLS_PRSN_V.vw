/*************************************************************************
 * 
 * VIEW Name       : xxcso_sales_for_sls_prsn_v
 * Description     : ¤ÊpF[gcÆõpãÀÑr[
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2009/02/01    1.0  T.Maruyama    ñì¬
 ************************************************************************/
CREATE OR REPLACE VIEW apps.xxcso_sales_for_sls_prsn_v
(
  account_number
 ,order_no_hht
 ,delivery_date
 ,pure_amount
)
AS
SELECT xsv.account_number    -- Úqy[iæz
      ,xsv.order_no_hht      -- óNo(HHT)
      ,xsv.delivery_date     -- [iú
      ,xsv.pure_amount       -- {Ìàzi¾×j
FROM   xxcso_sales_v xsv
WHERE  xsv.delivery_pattern_class in ('1','2','3','4','6') -- [i`Ôæªi5:¼_qÉãÈOj
WITH READ ONLY
;

COMMENT ON TABLE XXCSO_SALES_FOR_SLS_PRSN_V IS '¤ÊpF[gcÆõpãÀÑr[';
