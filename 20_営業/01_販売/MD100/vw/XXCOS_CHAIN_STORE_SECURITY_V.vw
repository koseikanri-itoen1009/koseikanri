/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcos_chain_store_security_v
 * Description     : XÜ(`F[X)ZLeBview
 * Version         : 1.2
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/01/01    1.0   T.Kumamoto       VKì¬
 *  2009/05/07    1.1   K.Kiriu          [T1_0326]Xe[^XðÇÁÎ
 *  2018/07/27    1.2   K.Kiriu          [E_{Ò®_15193]~ÙÏðÇÁÎ
 ************************************************************************/
CREATE OR REPLACE VIEW xxcos_chain_store_security_v (
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
    --store:`F[XXÜîñ
    SELECT hca_s.account_number                              account_number
          ,xca_s.chain_store_code                              chain_code
          ,xca_s.delivery_base_code                          delivery_base_code
          ,xca_s.store_code                                  store_code
          ,xca_s.cust_store_name                             cust_store_name
/* 2009/05/07 Ver1.1 Add Start */
          ,hca_s.status                                      status
/* 2009/05/07 Ver1.1 Add End   */
    FROM   xxcmm_cust_accounts                               xca_s
          ,hz_cust_accounts                                  hca_s
--Ver1.2 Add Start
          ,hz_parties                                        hp_s
--Ver1.2 Add End
    WHERE  xca_s.chain_store_code IS NOT NULL
    AND    hca_s.cust_account_id = xca_s.customer_id
    AND    hca_s.customer_class_code IN ('10', '12')
--Ver1.2 Add Start
    AND    hca_s.party_id        = hp_s.party_id
    AND    hp_s.duns_number_c   <> '90'               -- ~ÙÏÈO
--Ver1.2 Add End
  )                                                          store
  ,(
    --base:_îñ
    SELECT hca_b.account_number                              account_number
          ,hca_b.account_name                                account_name
          ,xca_b.management_base_code                        management_base_code
    FROM   xxcmm_cust_accounts                               xca_b
          ,hz_cust_accounts                                  hca_b
    WHERE  hca_b.cust_account_id = xca_b.customer_id
    AND    hca_b.customer_class_code = '1'
  )                                                          base
    --xuiv:[Uîñ
  , xxcos_user_info_v                                        xuiv
  WHERE store.delivery_base_code = base.account_number
  AND   xuiv.base_code in (store.delivery_base_code, base.management_base_code)
;
COMMENT ON  COLUMN  xxcos_chain_store_security_v.user_id          IS  '[UID';
COMMENT ON  COLUMN  xxcos_chain_store_security_v.user_name        IS  '[U¼Ì';
COMMENT ON  COLUMN  xxcos_chain_store_security_v.account_number   IS  'ÚqR[h';
COMMENT ON  COLUMN  xxcos_chain_store_security_v.chain_code       IS  '`F[XR[h';
COMMENT ON  COLUMN  xxcos_chain_store_security_v.chain_store_code IS  'XÜR[h';
COMMENT ON  COLUMN  xxcos_chain_store_security_v.chain_store_name IS  'XÜ¼Ì';
/* 2009/05/07 Ver1.1 Add Start */
COMMENT ON  COLUMN  xxcos_chain_store_security_v.status           IS  'Xe[^X';
/* 2009/05/07 Ver1.1 Add End   */
--
COMMENT ON  TABLE   xxcos_chain_store_security_v                  IS  'XÜ(`F[X)ZLeBr[';
