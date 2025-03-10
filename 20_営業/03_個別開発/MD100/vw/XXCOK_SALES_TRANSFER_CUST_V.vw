/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name   : xxcok_sales_transfer_cust_v
 * Description : ãUÖ³Úqr[
 * Version     : 1.1
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/10/20    1.0   S.Moriyama       VKì¬
 *  2009/12/03    1.1   S.Moriyama       [E_{Ò®_00294]UÖ³ÚqEDI`F[Î
 *
 **************************************************************************************/
CREATE OR REPLACE VIEW apps.xxcok_sales_transfer_cust_v(
  cust_code
, cust_name
)
AS
SELECT  /*+ LEADING(xca, hca, hp)
            INDEX(xca xxcmm_cust_accounts_n08)
            INDEX(hca hz_cust_accounts_u1)
            INDEX(hp hz_parties_u1)
         */
        hca.account_number  AS cust_code
      , hp.party_name       AS cust_name
  FROM  xxcmm_cust_accounts xca
      , hz_cust_accounts    hca
      , hz_parties          hp
 WHERE  xca.selling_transfer_div =  '1'
-- 2009/12/03 Ver.1.1 [E_{Ò®_00294] SCS S.Moriyama DEL START
--   AND  xca.chain_store_code     IS NULL
-- 2009/12/03 Ver.1.1 [E_{Ò®_00294] SCS S.Moriyama DEL END
   AND  hca.cust_account_id      =  xca.customer_id
   AND  hp.party_id              =  hca.party_id
   AND  EXISTS( SELECT /*+ INDEX(xsfi xxcok_selling_from_info_n01) */
                       'X'
                  FROM xxcok_selling_from_info xsfi
                 WHERE xsfi.selling_from_cust_code =  xca.customer_code
                   AND ROWNUM = 1
        )
ORDER BY  hca.account_number
/
COMMENT ON TABLE  apps.xxcok_sales_transfer_cust_v IS 'ãUÖ³Úqr['
/
COMMENT ON COLUMN apps.xxcok_sales_transfer_cust_v.cust_code IS 'ãUÖ³ÚqR[h'
/
COMMENT ON COLUMN apps.xxcok_sales_transfer_cust_v.cust_name IS 'ãUÖ³Úq¼'
/
