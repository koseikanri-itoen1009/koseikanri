/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcos_customer_security_v
 * Description     : �ڋq�Z�L�����e�Bview
 * Version         : 1.1
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/01/01    1.0   T.Kumamoto       �V�K�쐬
 *  2018/07/27    1.1   K.Kiriu          [E_�{�ғ�_15193]���~���ٍϏ����ǉ��Ή�
 ************************************************************************/
CREATE OR REPLACE VIEW xxcos_customer_security_v (
  user_id
 ,user_name
 ,account_number
 ,account_name
)
AS
  SELECT xuiv.user_id                                        user_id
        ,xuiv.user_name                                      user_name
        ,cust.account_number                                 account_number
        ,cust.account_name                                   account_name
  FROM (
    --cust:�ڋq���
    SELECT hca_s.account_number                              account_number
          ,hp.party_name                                     account_name
          ,xca_s.chain_store_code                            chain_code
          ,xca_s.delivery_base_code                          delivery_base_code
    FROM   xxcmm_cust_accounts                               xca_s
          ,hz_cust_accounts                                  hca_s
          ,hz_parties                                        hp
    WHERE  xca_s.chain_store_code IS NULL
    AND    hca_s.cust_account_id = xca_s.customer_id
    AND    hca_s.customer_class_code IN ('10', '12')
    AND    hp.party_id = hca_s.party_id
-- Ver1.1 Add Start
    AND    hp.duns_number_c     <> '90'               -- ���~���ٍψȊO
-- Ver1.1 Add End
  )                                                          cust
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
  WHERE cust.delivery_base_code = base.account_number
  AND   xuiv.base_code in (cust.delivery_base_code, base.management_base_code)
;
COMMENT ON  COLUMN  xxcos_customer_security_v.user_id          IS  '���[�UID';
COMMENT ON  COLUMN  xxcos_customer_security_v.user_name        IS  '���[�U����';
COMMENT ON  COLUMN  xxcos_customer_security_v.account_number   IS  '�ڋq�R�[�h';
COMMENT ON  COLUMN  xxcos_customer_security_v.account_name     IS  '�ڋq����';
--
COMMENT ON  TABLE   xxcos_customer_security_v                  IS  '�ڋq�Z�L�����e�B�r���[';
