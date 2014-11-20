/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcos_deposit_store_security_v
 * Description     : �X�܁i�a���VD�j�Z�L�����e�Bview
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/03/06    1.0   K.Kumamoto       �V�K�쐬
 ************************************************************************/
CREATE OR REPLACE VIEW xxcos_deposit_store_security_v (
  user_id
 ,user_name
 ,account_number
 ,chain_code
 ,chain_store_code
 ,chain_store_name
)
AS
  SELECT xuiv.user_id                                        user_id
        ,xuiv.user_name                                      user_name
        ,store.account_number                                account_number
        ,store.chain_code                                    chain_code
        ,store.store_code                                    store_code
        ,store.cust_store_name                               cust_store_name
  FROM (
    SELECT hca.account_number      account_number
          ,xlvv.lookup_code        chain_code
          ,xca.store_code          store_code
          ,xca.cust_store_name     cust_store_name
          ,xca.delivery_base_code  delivery_base_code
    FROM   xxcos_lookup_values_v xlvv
          ,xxcmm_cust_accounts xca
          ,hz_cust_accounts hca
    WHERE  xlvv.lookup_type = 'XXCOS1_DEPOSIT_VD_CHAIN_MST'
    AND    xca.sales_chain_code = xlvv.lookup_code
    AND    hca.cust_account_id = xca.customer_id
    AND    hca.customer_class_code = '10'
    ) store
  ,(
    --base:���_���
    SELECT hca_b.account_number                              account_number
          ,hca_b.account_name                                account_name
          ,xca_b.management_base_code                        management_base_code
    FROM   xxcmm_cust_accounts                               xca_b
          ,hz_cust_accounts                                  hca_b
    WHERE  hca_b.cust_account_id = xca_b.customer_id
    AND    hca_b.customer_class_code = '1'
  )                                                          base
    --xuiv:���[�U���
  , xxcos_user_info_v                                        xuiv
  WHERE store.delivery_base_code = base.account_number
  AND  (xuiv.base_code = fnd_profile.value('XXCOS1_BIZ_MAN_DEPT_CODE')
  OR    xuiv.base_code != fnd_profile.value('XXCOS1_BIZ_MAN_DEPT_CODE')
  AND   xuiv.base_code IN (store.delivery_base_code, base.management_base_code)
  )
;
COMMENT ON  COLUMN  xxcos_deposit_store_security_v.user_id          IS  '���[�UID';
COMMENT ON  COLUMN  xxcos_deposit_store_security_v.user_name        IS  '���[�U����';
COMMENT ON  COLUMN  xxcos_deposit_store_security_v.account_number   IS  '�ڋq�R�[�h';
COMMENT ON  COLUMN  xxcos_deposit_store_security_v.chain_code       IS  '�`�F�[���X�R�[�h';
COMMENT ON  COLUMN  xxcos_deposit_store_security_v.chain_store_code IS  '�X�܃R�[�h';
COMMENT ON  COLUMN  xxcos_deposit_store_security_v.chain_store_name IS  '�X�ܖ���';
--
COMMENT ON  TABLE   xxcos_deposit_store_security_v                  IS  '�X�܁i�a���VD�j�Z�L�����e�B�r���[';
