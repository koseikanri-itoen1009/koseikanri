/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcos_chain_security_v
 * Description     : チェーン店セキュリティview
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/01/01    1.0   T.Kumamoto       新規作成
 ************************************************************************/
CREATE OR REPLACE VIEW xxcos_chain_security_v (
  user_id
 ,user_name
 ,account_number
 ,chain_code
 ,chain_name
)
AS
  SELECT DISTINCT
         store.user_id                   user_id
        ,store.user_name                 user_name
        ,hca.account_number              account_number
        ,xca.chain_store_code            chain_code
        ,hp.party_name                   chain_name
  FROM   xxcos_chain_store_security_v    store
        ,xxcmm_cust_accounts             xca
        ,hz_cust_accounts                hca
        ,hz_parties                      hp
  WHERE  xca.chain_store_code = store.chain_code
  AND    hca.cust_account_id = xca.customer_id
  AND    hca.customer_class_code = '18'
  AND    hp.party_id = hca.party_id
;
COMMENT ON  COLUMN  xxcos_chain_security_v.user_id          IS  'ユーザID';
COMMENT ON  COLUMN  xxcos_chain_security_v.user_name        IS  'ユーザ名称';
COMMENT ON  COLUMN  xxcos_chain_security_v.account_number   IS  '顧客コード';
COMMENT ON  COLUMN  xxcos_chain_security_v.chain_code       IS  'チェーン店コード';
COMMENT ON  COLUMN  xxcos_chain_security_v.chain_name       IS  'チェーン店名称';
--
COMMENT ON  TABLE   xxcos_chain_security_v                  IS  'チェーン店セキュリティビュー';
