/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcos_edi_chain_security_v
 * Description     : EDIチェーン店セキュリティview
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2008/12/25    1.0   S.Nakamura      新規作成
 ************************************************************************/
CREATE OR REPLACE VIEW xxcos_edi_chain_security_v(
   account_number     -- 顧客コード
  ,edi_chain_code     -- EDIチェーン店コード
  ,edi_chain_name     -- チェーン店名(顧客名称)
  ,delivery_base_code -- 納品拠点コード
  ,delivery_base_name -- 納品拠点名
)
AS
  SELECT 
         hca2.account_number         -- 顧客コード
        ,hca2.chain_store_code       -- EDIチェーン店コード
        ,hca2.account_name           -- 顧客名称
        ,hca1.delivery_base_code     -- 納品拠点コード
        ,hca1.delivery_base_name     -- 納品拠点名
  FROM
    ( SELECT hca.cust_account_id       cust_account_id    -- 顧客ID
            ,hca.account_number        account_number     -- 顧客コード
            ,xca.chain_store_code      chain_store_code   -- EDIチェーン店コード
            ,xca.store_code            store_code         -- 店舗コード
            ,hp.party_name             account_name       -- 顧客名
            ,xca.delivery_base_code    delivery_base_code -- 納品拠点コード
            ,xlb.base_name             delivery_base_name -- 納品拠点名
      FROM  hz_cust_accounts         hca  -- 顧客
           ,xxcmm_cust_accounts      xca  -- 顧客追加情報
           ,xxcos_login_base_info_v  xlb  -- ログインユーザ拠点ビュー
           ,hz_parties               hp   -- パーティ
      WHERE   hca.cust_account_id     = xca.customer_id
      AND     hca.customer_class_code = '10'
      AND     xca.delivery_base_code  = xlb.base_code    -- 拠点セキュリティ
      AND     hca.party_id            = hp.party_id
      AND     hca.status              = 'A'
      AND     hp.duns_number_c        in ('30','40')     -- 顧客ステータス
      AND     xca.store_code IS NOT NULL                 -- 店舗コードあり
    )    hca1   -- 顧客マスタ(顧客)
   ,( SELECT  hca.account_number           account_number    -- 顧客コード
             ,xca.chain_store_code         chain_store_code  -- EDIチェーン店コード
             ,hp.party_name                account_name      -- 顧客名
      FROM    hz_cust_accounts       hca               -- 顧客
             ,xxcmm_cust_accounts    xca               -- 顧客追加情報
             ,hz_parties             hp   -- パーティ
      WHERE   hca.cust_account_id     = xca.customer_id
      AND     hca.customer_class_code = '18'
      AND     hca.party_id            = hp.party_id
    )    hca2   -- 顧客マスタ(チェーン店)
   ,( SELECT   flv.attribute1        chain_store_code  -- EDIチェーン店コード
      FROM     fnd_lookup_values     flv
      WHERE    flv.lookup_type        = 'XXCOS1_EDI_CONTROL_LIST'   -- EDI制御情報
        AND    flv.attribute2         = '21'                        -- データ種コード 納品予定
        AND    flv.attribute3         = '01'                        -- 並列処理番号
        AND    flv.language           = userenv('LANG')
        AND    flv.source_lang        = userenv('LANG')
        AND    flv.enabled_flag       = 'Y'
        AND    flv.start_date_active <= TRUNC(SYSDATE)
        AND  ( flv.end_date_active   >= TRUNC(SYSDATE) OR flv.end_date_active IS NULL )
    )  flv     -- EDI制御情報
WHERE    hca1.chain_store_code = hca2.chain_store_code
  AND    hca1.chain_store_code = flv.chain_store_code
  AND    hca2.chain_store_code = flv.chain_store_code
GROUP BY hca2.account_number         -- 顧客コード
        ,hca2.chain_store_code       -- EDIチェーン店コード
        ,hca2.account_name           -- 顧客名称
        ,hca1.delivery_base_code     -- 納品拠点コード
        ,hca1.delivery_base_name     -- 納品拠点名
;
COMMENT ON  COLUMN  xxcos_edi_chain_security_v.account_number      IS '顧客コード';
COMMENT ON  COLUMN  xxcos_edi_chain_security_v.edi_chain_code      IS 'EDIチェーン店コード';
COMMENT ON  COLUMN  xxcos_edi_chain_security_v.edi_chain_name      IS 'チェーン店名(顧客名称)';
COMMENT ON  COLUMN  xxcos_edi_chain_security_v.delivery_base_code  IS '納品拠点コード';
COMMENT ON  COLUMN  xxcos_edi_chain_security_v.delivery_base_name  IS '納品拠点名';
--
COMMENT ON  TABLE   xxcos_edi_chain_security_v                     IS 'EDIチェーン店セキュリティビュー';
