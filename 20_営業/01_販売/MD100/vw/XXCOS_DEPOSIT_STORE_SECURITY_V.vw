/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcos_deposit_store_security_v
 * Description     : 店舗（預り金VD）セキュリティview
 * Version         : 1.2
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/03/06    1.0   K.Kumamoto       新規作成
 *  2009/05/07    1.1   K.Kiriu          [T1_0326]ステータス条件追加対応
 *  2018/07/27    1.2   K.Kiriu          [E_本稼動_15193]中止決裁済条件追加対応
 ************************************************************************/
CREATE OR REPLACE VIEW xxcos_deposit_store_security_v (
  user_id
 ,user_name
 ,account_number
 ,chain_code
 ,chain_store_code
 ,chain_store_name
/* 2009/05/07 Ver1.1 Add Start */
 ,status
/* 2009/05/07 Ver1.1 Add End   */
)
AS
  SELECT xuiv.user_id                                        user_id
        ,xuiv.user_name                                      user_name
        ,store.account_number                                account_number
        ,store.chain_code                                    chain_code
        ,store.store_code                                    store_code
        ,store.cust_store_name                               cust_store_name
/* 2009/05/07 Ver1.1 Add Start */
        ,store.status                                        status
/* 2009/05/07 Ver1.1 Add End   */
  FROM (
    SELECT hca.account_number      account_number
          ,xlvv.lookup_code        chain_code
          ,xca.store_code          store_code
          ,xca.cust_store_name     cust_store_name
          ,xca.delivery_base_code  delivery_base_code
/* 2009/05/07 Ver1.1 Add Start */
          ,hca.status              status
/* 2009/05/07 Ver1.1 Add End   */
    FROM   xxcos_lookup_values_v xlvv
          ,xxcmm_cust_accounts xca
          ,hz_cust_accounts hca
--Ver1.2 Add Start
          ,hz_parties hp
--Ver1.2 Add End
    WHERE  xlvv.lookup_type = 'XXCOS1_DEPOSIT_VD_CHAIN_MST'
    AND    xca.sales_chain_code = xlvv.lookup_code
    AND    hca.cust_account_id = xca.customer_id
    AND    hca.customer_class_code = '10'
--Ver1.2 Add Start
    AND    hca.party_id = hp.party_id
    AND    hp.duns_number_c <> '90'             -- 中止決裁済以外
--Ver1.2 Add End
    ) store
  ,(
    --base:拠点情報
    SELECT hca_b.account_number                              account_number
          ,hca_b.account_name                                account_name
          ,xca_b.management_base_code                        management_base_code
    FROM   xxcmm_cust_accounts                               xca_b
          ,hz_cust_accounts                                  hca_b
    WHERE  hca_b.cust_account_id = xca_b.customer_id
    AND    hca_b.customer_class_code = '1'
  )                                                          base
    --xuiv:ユーザ情報
  , xxcos_user_info_v                                        xuiv
  WHERE store.delivery_base_code = base.account_number
  AND  (xuiv.base_code = fnd_profile.value('XXCOS1_BIZ_MAN_DEPT_CODE')
  OR    xuiv.base_code != fnd_profile.value('XXCOS1_BIZ_MAN_DEPT_CODE')
  AND   xuiv.base_code IN (store.delivery_base_code, base.management_base_code)
  )
;
COMMENT ON  COLUMN  xxcos_deposit_store_security_v.user_id          IS  'ユーザID';
COMMENT ON  COLUMN  xxcos_deposit_store_security_v.user_name        IS  'ユーザ名称';
COMMENT ON  COLUMN  xxcos_deposit_store_security_v.account_number   IS  '顧客コード';
COMMENT ON  COLUMN  xxcos_deposit_store_security_v.chain_code       IS  'チェーン店コード';
COMMENT ON  COLUMN  xxcos_deposit_store_security_v.chain_store_code IS  '店舗コード';
COMMENT ON  COLUMN  xxcos_deposit_store_security_v.chain_store_name IS  '店舗名称';
/* 2009/05/07 Ver1.1 Add Start */
COMMENT ON  COLUMN  xxcos_deposit_store_security_v.status           IS  'ステータス';
/* 2009/05/07 Ver1.1 Add End   */
--
COMMENT ON  TABLE   xxcos_deposit_store_security_v                  IS  '店舗（預り金VD）セキュリティビュー';
