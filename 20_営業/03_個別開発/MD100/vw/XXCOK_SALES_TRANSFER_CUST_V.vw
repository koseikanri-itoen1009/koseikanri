/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name   : xxcok_sales_transfer_cust_v
 * Description : îÑè„êUë÷å≥å⁄ãqÉrÉÖÅ[
 * Version     : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/10/20    1.0   S.Moriyama       êVãKçÏê¨
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
   AND  xca.chain_store_code     IS NULL
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
COMMENT ON TABLE  apps.xxcok_sales_transfer_cust_v IS 'îÑè„êUë÷å≥å⁄ãqÉrÉÖÅ['
/
COMMENT ON COLUMN apps.xxcok_sales_transfer_cust_v.cust_code IS 'îÑè„êUë÷å≥å⁄ãqÉRÅ[Éh'
/
COMMENT ON COLUMN apps.xxcok_sales_transfer_cust_v.cust_name IS 'îÑè„êUë÷å≥å⁄ãqñº'
/
