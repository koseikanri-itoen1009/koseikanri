/************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcos_tax_rate_v
 * Description     : 消費税率view
 * Version         : 1.2
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/01/01    1.0   T.Kumamoto       新規作成
 *  2009/02/25    1.1   S.Nakamura       [COS_135]ar_vat_tax_all_bの有効条件追加
 *  2013/07/10    1.2   T.Shimoji        [E_本稼動_10904]消費税増税対応
 *
 ************************************************************************************/
CREATE OR REPLACE VIEW xxcos_tax_rate_v (
  cust_account_id         --顧客ID
 ,account_number          --顧客コード
 ,chain_store_code        --チェーン店コード
 ,ship_storage_code       --出荷元保管場所
 ,customer_class_code     --顧客区分
 ,set_of_books_id         --GL会計帳簿ID
 ,tax_div                 --消費税区分
 ,tax_code                --消費税コード
 ,tax_rate                --消費税率
 ,start_date_active       --適用開始日
 ,end_date_active         --適用終了日
 ,tax_start_date          --税開始日     --1.1 COS_135
 ,tax_end_date            --税終了日     --1.1 COS_135
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
COMMENT ON  COLUMN  xxcos_tax_rate_v.cust_account_id      IS  '顧客ID';
COMMENT ON  COLUMN  xxcos_tax_rate_v.account_number       IS  '顧客コード';
COMMENT ON  COLUMN  xxcos_tax_rate_v.chain_store_code     IS  'チェーン店コード';
COMMENT ON  COLUMN  xxcos_tax_rate_v.ship_storage_code    IS  '出荷元保管場所';
COMMENT ON  COLUMN  xxcos_tax_rate_v.customer_class_code  IS  '顧客区分';
COMMENT ON  COLUMN  xxcos_tax_rate_v.set_of_books_id      IS  'GL会計帳簿ID';
COMMENT ON  COLUMN  xxcos_tax_rate_v.tax_div              IS  '消費税区分';
COMMENT ON  COLUMN  xxcos_tax_rate_v.tax_code             IS  '消費税コード';
COMMENT ON  COLUMN  xxcos_tax_rate_v.tax_rate             IS  '消費税率';
COMMENT ON  COLUMN  xxcos_tax_rate_v.start_date_active    IS  '適用開始日';
COMMENT ON  COLUMN  xxcos_tax_rate_v.end_date_active      IS  '適用終了日';
COMMENT ON  COLUMN  xxcos_tax_rate_v.tax_start_date       IS  '税開始日';
COMMENT ON  COLUMN  xxcos_tax_rate_v.tax_end_date         IS  '税終了日';
--
COMMENT ON  TABLE   xxcos_tax_rate_v                      IS  '消費税率ビュー';
