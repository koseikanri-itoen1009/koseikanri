/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcos_edi_chain_security_v
 * Description     : EDIチェーン店セキュリティview
 * Version         : 1.2
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2008/12/25    1.0   S.Nakamura      新規作成
 *  2009/05/11    1.1   K.Kiriu          [T1_0777]並列処理番号の条件削除
 *  2022/01/11    1.2   SCSK Y.Koh       [E_本稼動_17874]
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
-- 2022/01/11 Ver1.2 MOD Start
        ,xca2.chain_store_code       -- EDIチェーン店コード
        ,hp2.party_name              -- 顧客名称
        ,xca1.delivery_base_code     -- 納品拠点コード
        ,xlb.base_name               -- 納品拠点名
--        ,hca2.chain_store_code       -- EDIチェーン店コード
--        ,hca2.account_name           -- 顧客名称
--        ,hca1.delivery_base_code     -- 納品拠点コード
--        ,hca1.delivery_base_name     -- 納品拠点名
-- 2022/01/11 Ver1.2 MOD End
  FROM
-- 2022/01/11 Ver1.2 MOD Start
         hz_cust_accounts         hca1                      -- 顧客
        ,xxcmm_cust_accounts      xca1                      -- 顧客追加情報
        ,xxcos_login_base_info_v  xlb                       -- ログインユーザ拠点ビュー
        ,hz_parties               hp1                       -- パーティ
        ,hz_cust_accounts         hca2                      -- 顧客
        ,xxcmm_cust_accounts      xca2                      -- 顧客追加情報
        ,hz_parties               hp2                       -- パーティ
   ,( SELECT   DISTINCT
               flv.attribute1        chain_store_code  -- EDIチェーン店コード
--    ( SELECT hca.cust_account_id       cust_account_id    -- 顧客ID
--            ,hca.account_number        account_number     -- 顧客コード
--            ,xca.chain_store_code      chain_store_code   -- EDIチェーン店コード
--            ,xca.store_code            store_code         -- 店舗コード
--            ,hp.party_name             account_name       -- 顧客名
--            ,xca.delivery_base_code    delivery_base_code -- 納品拠点コード
--            ,xlb.base_name             delivery_base_name -- 納品拠点名
--      FROM  hz_cust_accounts         hca  -- 顧客
--           ,xxcmm_cust_accounts      xca  -- 顧客追加情報
--           ,xxcos_login_base_info_v  xlb  -- ログインユーザ拠点ビュー
--           ,hz_parties               hp   -- パーティ
--      WHERE   hca.cust_account_id     = xca.customer_id
--      AND     hca.customer_class_code = '10'
--      AND     xca.delivery_base_code  = xlb.base_code    -- 拠点セキュリティ
--      AND     hca.party_id            = hp.party_id
--      AND     hca.status              = 'A'
--      AND     hp.duns_number_c        in ('30','40')     -- 顧客ステータス
--      AND     xca.store_code IS NOT NULL                 -- 店舗コードあり
--    )    hca1   -- 顧客マスタ(顧客)
--   ,( SELECT  hca.account_number           account_number    -- 顧客コード
--             ,xca.chain_store_code         chain_store_code  -- EDIチェーン店コード
--             ,hp.party_name                account_name      -- 顧客名
--      FROM    hz_cust_accounts       hca               -- 顧客
--             ,xxcmm_cust_accounts    xca               -- 顧客追加情報
--             ,hz_parties             hp   -- パーティ
--      WHERE   hca.cust_account_id     = xca.customer_id
--      AND     hca.customer_class_code = '18'
--      AND     hca.party_id            = hp.party_id
--    )    hca2   -- 顧客マスタ(チェーン店)
--   ,( SELECT   flv.attribute1        chain_store_code  -- EDIチェーン店コード
-- 2022/01/11 Ver1.2 MOD End
      FROM     fnd_lookup_values     flv
      WHERE    flv.lookup_type        = 'XXCOS1_EDI_CONTROL_LIST'   -- EDI制御情報
        AND    flv.attribute2         = '21'                        -- データ種コード 納品予定
/* 2009/05/11 Ver1.1 Del Start */
--        AND    flv.attribute3         = '01'                        -- 並列処理番号
/* 2009/05/11 Ver1.1 Del End   */
        AND    flv.language           = userenv('LANG')
        AND    flv.source_lang        = userenv('LANG')
        AND    flv.enabled_flag       = 'Y'
        AND    flv.start_date_active <= TRUNC(SYSDATE)
        AND  ( flv.end_date_active   >= TRUNC(SYSDATE) OR flv.end_date_active IS NULL )
    )  flv     -- EDI制御情報
-- 2022/01/11 Ver1.2 MOD Start
WHERE    hca1.cust_account_id     =   xca1.customer_id
  AND    hca1.customer_class_code =   '10'
  AND    xca1.delivery_base_code  =   xlb.base_code         -- 拠点セキュリティ
  AND    hca1.party_id            =   hp1.party_id
  AND    hca1.status              =   'A'
  AND    hp1.duns_number_c        in  ('30','40')           -- 顧客ステータス
  AND    xca1.store_code          IS  NOT NULL              -- 店舗コードあり
  AND    hca2.cust_account_id     =   xca2.customer_id
  AND    hca2.customer_class_code =   '18'
  AND    hca2.party_id            =   hp2.party_id
  AND    xca1.chain_store_code    =   xca2.chain_store_code
  AND    xca2.chain_store_code    =   flv.chain_store_code
--WHERE    hca1.chain_store_code = hca2.chain_store_code
--  AND    hca1.chain_store_code = flv.chain_store_code
--  AND    hca2.chain_store_code = flv.chain_store_code
-- 2022/01/11 Ver1.2 MOD End
GROUP BY hca2.account_number         -- 顧客コード
-- 2022/01/11 Ver1.2 MOD Start
        ,xca2.chain_store_code       -- EDIチェーン店コード
        ,hp2.party_name              -- 顧客名称
        ,xca1.delivery_base_code     -- 納品拠点コード
        ,xlb.base_name               -- 納品拠点名
--        ,hca2.chain_store_code       -- EDIチェーン店コード
--        ,hca2.account_name           -- 顧客名称
--        ,hca1.delivery_base_code     -- 納品拠点コード
--        ,hca1.delivery_base_name     -- 納品拠点名
-- 2022/01/11 Ver1.2 MOD End
;
COMMENT ON  COLUMN  xxcos_edi_chain_security_v.account_number      IS '顧客コード';
COMMENT ON  COLUMN  xxcos_edi_chain_security_v.edi_chain_code      IS 'EDIチェーン店コード';
COMMENT ON  COLUMN  xxcos_edi_chain_security_v.edi_chain_name      IS 'チェーン店名(顧客名称)';
COMMENT ON  COLUMN  xxcos_edi_chain_security_v.delivery_base_code  IS '納品拠点コード';
COMMENT ON  COLUMN  xxcos_edi_chain_security_v.delivery_base_name  IS '納品拠点名';
--
COMMENT ON  TABLE   xxcos_edi_chain_security_v                     IS 'EDIチェーン店セキュリティビュー';
