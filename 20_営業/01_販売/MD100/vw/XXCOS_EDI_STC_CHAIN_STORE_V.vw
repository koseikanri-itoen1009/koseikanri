/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcos_edi_stc_chain_store_v
 * Description     : EDIチェーン店コードview
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/01/01    1.0   x.xxxxxxx        新規作成
 ************************************************************************/
CREATE OR REPLACE VIEW xxcos_edi_stc_chain_store_v (
   chain_store_code   --EDIチェーン店コード
  ,customer_name      --顧客名称
  ,ship_storage_code  --出荷元保管場所(条件)
)
AS
   SELECT   hca2.chain_store_code
           ,hca2.party_name
           ,hca1.ship_storage_code
   FROM     ( SELECT  xca.ship_storage_code  ship_storage_code --出荷元保管場所
                     ,xca.chain_store_code   chain_store_code  --EDIチェーン店コード
                     ,hca.account_number     account_number    --顧客コード
              FROM    hz_cust_accounts         hca   --顧客
                     ,xxcmm_cust_accounts      xca   --顧客追加情報
                     ,hz_parties               hp    --パーティ
                     ,xxcos_login_base_info_v  xlbiv --ログインユーザ拠点
              WHERE   hca.customer_class_code =  '10'  -- 顧客
              AND     hca.status              =  'A'   -- ステータス
              AND     hp.duns_number_c        <> '90'  -- 顧客ステータス
              AND     hca.party_id            =  hp.party_id
              AND     hca.cust_account_id     =  xca.customer_id
              AND     xca.delivery_base_code  =  xlbiv.base_code
            )                       hca1   --顧客
           ,( SELECT  xca.chain_store_code   chain_store_code  --EDIチェーン店コード
                     ,hp.party_name          party_name        --顧客名称
              FROM    hz_cust_accounts    hca  --顧客
                     ,xxcmm_cust_accounts xca  --顧客追加情報
                     ,hz_parties          hp   --パーティ
              WHERE   hca.customer_class_code =  '18'  -- チェーン店
              AND     hca.cust_account_id     =  xca.customer_id
              AND     hca.party_id            =  hp.party_id
            )                       hca2   --顧客(チェーン店)
   WHERE    hca1.chain_store_code = hca2.chain_store_code
   AND      hca1.account_number =
              ( SELECT   MAX(hca.account_number)
                FROM     hz_cust_accounts    hca
                        ,xxcmm_cust_accounts xca
                        ,hz_parties          hp    --パーティ
                WHERE    hca.customer_class_code =  '10'  -- 顧客
                AND      hca.status              =  'A'   -- ステータス
                AND      hp.duns_number_c        <> '90'  -- 顧客ステータス
                AND      hca.party_id            =  hp.party_id
                AND      hca.cust_account_id     =  xca.customer_id
                AND      xca.ship_storage_code   =  hca1.ship_storage_code
                AND      xca.chain_store_code    =  hca1.chain_store_code
              )
;
COMMENT ON  COLUMN  xxcos_edi_stc_chain_store_v.chain_store_code       IS 'EDIチェーン店コード'; 
COMMENT ON  COLUMN  xxcos_edi_stc_chain_store_v.customer_name          IS '顧客名称';
COMMENT ON  COLUMN  xxcos_edi_stc_chain_store_v.ship_storage_code      IS '出荷元保管場所(条件)';
--
COMMENT ON  TABLE   xxcos_edi_stc_chain_store_v                        IS 'EDIチェーン店コードビュー';
