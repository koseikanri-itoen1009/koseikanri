/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcos_edi_stc_chain_store_v
 * Description     : EDI`F[XR[hview
 * Version         : 1.1
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/01/01    1.0   x.xxxxxxx        VKì¬
 *  2023/06/02    1.1   R.Oikawa         E_{Ò®_19250Î  2018/8/6ÉÎµ½«\áQÌqgåÎiâ¹#3128j
 ************************************************************************/
CREATE OR REPLACE VIEW xxcos_edi_stc_chain_store_v (
   chain_store_code   --EDI`F[XR[h
  ,customer_name      --Úq¼Ì
  ,ship_storage_code  --o×³ÛÇê(ð)
)
AS
   SELECT   /*+ leading(hca1.xca) */
            hca2.chain_store_code
           ,hca2.party_name
           ,hca1.ship_storage_code
   FROM     ( SELECT  xca.ship_storage_code  ship_storage_code --o×³ÛÇê
                     ,xca.chain_store_code   chain_store_code  --EDI`F[XR[h
                     ,hca.account_number     account_number    --ÚqR[h
              FROM    hz_cust_accounts         hca   --Úq
                     ,xxcmm_cust_accounts      xca   --ÚqÇÁîñ
                     ,hz_parties               hp    --p[eB
                     ,xxcos_login_base_info_v  xlbiv --OC[U_
              WHERE   hca.customer_class_code =  '10'  -- Úq
              AND     hca.status              =  'A'   -- Xe[^X
              AND     hp.duns_number_c        <> '90'  -- ÚqXe[^X
              AND     hca.party_id            =  hp.party_id
              AND     hca.cust_account_id     =  xca.customer_id
              AND     xca.delivery_base_code  =  xlbiv.base_code
            )                       hca1   --Úq
           ,( SELECT  xca.chain_store_code   chain_store_code  --EDI`F[XR[h
                     ,hp.party_name          party_name        --Úq¼Ì
              FROM    hz_cust_accounts    hca  --Úq
                     ,xxcmm_cust_accounts xca  --ÚqÇÁîñ
                     ,hz_parties          hp   --p[eB
              WHERE   hca.customer_class_code =  '18'  -- `F[X
              AND     hca.cust_account_id     =  xca.customer_id
              AND     hca.party_id            =  hp.party_id
            )                       hca2   --Úq(`F[X)
   WHERE    hca1.chain_store_code = hca2.chain_store_code
   AND      hca1.account_number =
              ( SELECT   MAX(hca.account_number)
                FROM     hz_cust_accounts    hca
                        ,xxcmm_cust_accounts xca
                        ,hz_parties          hp    --p[eB
                WHERE    hca.customer_class_code =  '10'  -- Úq
                AND      hca.status              =  'A'   -- Xe[^X
                AND      hp.duns_number_c        <> '90'  -- ÚqXe[^X
                AND      hca.party_id            =  hp.party_id
                AND      hca.cust_account_id     =  xca.customer_id
                AND      xca.ship_storage_code   =  hca1.ship_storage_code
                AND      xca.chain_store_code    =  hca1.chain_store_code
              )
;
COMMENT ON  COLUMN  xxcos_edi_stc_chain_store_v.chain_store_code       IS 'EDI`F[XR[h'; 
COMMENT ON  COLUMN  xxcos_edi_stc_chain_store_v.customer_name          IS 'Úq¼Ì';
COMMENT ON  COLUMN  xxcos_edi_stc_chain_store_v.ship_storage_code      IS 'o×³ÛÇê(ð)';
--
COMMENT ON  TABLE   xxcos_edi_stc_chain_store_v                        IS 'EDI`F[XR[hr[';
