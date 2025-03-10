/************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcos_tax_rate_v
 * Description     : ÁïÅ¦view
 * Version         : 1.2
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/01/01    1.0   T.Kumamoto       VKì¬
 *  2009/02/25    1.1   S.Nakamura       [COS_135]ar_vat_tax_all_bÌLøðÇÁ
 *  2013/07/10    1.2   T.Shimoji        [E_{Ò®_10904]ÁïÅÅÎ
 *
 ************************************************************************************/
CREATE OR REPLACE VIEW xxcos_tax_rate_v (
  cust_account_id         --ÚqID
 ,account_number          --ÚqR[h
 ,chain_store_code        --`F[XR[h
 ,ship_storage_code       --o×³ÛÇê
 ,customer_class_code     --Úqæª
 ,set_of_books_id         --GLïv ëID
 ,tax_div                 --ÁïÅæª
 ,tax_code                --ÁïÅR[h
 ,tax_rate                --ÁïÅ¦
 ,start_date_active       --KpJnú
 ,end_date_active         --KpI¹ú
 ,tax_start_date          --ÅJnú     --1.1 COS_135
 ,tax_end_date            --ÅI¹ú     --1.1 COS_135
)
AS
  SELECT  hca.cust_account_id         cust_account_id
         ,hca.account_number          account_number
         ,xca.chain_store_code        chain_store_code
         ,xca.ship_storage_code       ship_storage_code
         ,hca.customer_class_code     customer_class_code
         ,avtab.set_of_books_id       set_of_books_id
         ,xca.tax_div                 tax_div
         ,avtab.tax_code              tax_code
         ,avtab.tax_rate              tax_rate
         ,flv.start_date_active       start_date_active
         ,flv.end_date_active         end_date_active
-- 2013/07/10 Ver.1.2 Mod Start
--         ,avtab.start_date            tax_start_date
--         ,avtab.end_date              tax_end_date  
         ,TO_DATE(avtab.attribute1,'YYYYMMDD')   tax_start_date
         ,TO_DATE(avtab.attribute2,'YYYYMMDD')   tax_end_date
-- 2013/07/10 Ver.1.2 Mod End
  FROM    hz_cust_accounts            hca
         ,xxcmm_cust_accounts         xca
         ,fnd_lookup_values           flv
         ,ar_vat_tax_all_b            avtab
  WHERE   xca.customer_id  = hca.cust_account_id
  AND     flv.lookup_type  = 'XXCOS1_CONSUMPTION_TAX_CLASS'
  AND     flv.attribute3   = xca.tax_div
  AND     avtab.tax_code   = flv.attribute2
  AND     avtab.tax_rate IS NOT NULL
  AND     avtab.enabled_flag = 'Y'
  AND     flv.enabled_flag   = 'Y'
  AND     flv.language       = userenv('LANG')
  AND     flv.source_lang    = userenv('LANG')
;
COMMENT ON  COLUMN  xxcos_tax_rate_v.cust_account_id      IS  'ÚqID';
COMMENT ON  COLUMN  xxcos_tax_rate_v.account_number       IS  'ÚqR[h';
COMMENT ON  COLUMN  xxcos_tax_rate_v.chain_store_code     IS  '`F[XR[h';
COMMENT ON  COLUMN  xxcos_tax_rate_v.ship_storage_code    IS  'o×³ÛÇê';
COMMENT ON  COLUMN  xxcos_tax_rate_v.customer_class_code  IS  'Úqæª';
COMMENT ON  COLUMN  xxcos_tax_rate_v.set_of_books_id      IS  'GLïv ëID';
COMMENT ON  COLUMN  xxcos_tax_rate_v.tax_div              IS  'ÁïÅæª';
COMMENT ON  COLUMN  xxcos_tax_rate_v.tax_code             IS  'ÁïÅR[h';
COMMENT ON  COLUMN  xxcos_tax_rate_v.tax_rate             IS  'ÁïÅ¦';
COMMENT ON  COLUMN  xxcos_tax_rate_v.start_date_active    IS  'KpJnú';
COMMENT ON  COLUMN  xxcos_tax_rate_v.end_date_active      IS  'KpI¹ú';
COMMENT ON  COLUMN  xxcos_tax_rate_v.tax_start_date       IS  'ÅJnú';
COMMENT ON  COLUMN  xxcos_tax_rate_v.tax_end_date         IS  'ÅI¹ú';
--
COMMENT ON  TABLE   xxcos_tax_rate_v                      IS  'ÁïÅ¦r[';
