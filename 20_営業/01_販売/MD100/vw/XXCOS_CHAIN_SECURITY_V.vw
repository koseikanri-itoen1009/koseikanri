/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcos_chain_security_v
 * Description     : �`�F�[���X�Z�L�����e�Bview
 * Version         : 1.1
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/01/01    1.0   T.Kumamoto       �V�K�쐬
 *  2010/07/28    1.1   K.Oomata         [E_�{�ғ�_04027]�Ή� �p�t�H�[�}���X���P
 ************************************************************************/
CREATE OR REPLACE VIEW xxcos_chain_security_v (
  user_id
 ,user_name
 ,account_number
 ,chain_code
 ,chain_name
)
AS
-- 2010/07/28 Ver.1.1 K.Oomata Mod Start
--  SELECT DISTINCT
  SELECT /*+
            USE_NL(xca)
         */
         DISTINCT
-- 2010/07/28 Ver.1.1 K.Oomata Mod End
         store.user_id                   user_id
        ,store.user_name                 user_name
        ,hca.account_number              account_number
-- 2010/07/28 Ver.1.1 K.Oomata Mod Start
--        ,xca.chain_store_code            chain_code
        ,xca.edi_chain_code              chain_code
-- 2010/07/28 Ver.1.1 K.Oomata Mod End
        ,hp.party_name                   chain_name
-- 2010/07/28 Ver.1.1 K.Oomata Mod Start
--  FROM   xxcos_chain_store_security_v    store
  FROM   (
           SELECT xuiv.user_id                                  user_id
                 ,xuiv.user_name                                user_name
                 ,shop.account_number                           account_number
                 ,shop.chain_code                               chain_code
           FROM (
                  --shop:�`�F�[���X�X�܏��
                  SELECT /*+
                            USE_NL(xca_s hca_s)
                         */
                         hca_s.account_number                   account_number
                        ,xca_s.chain_store_code                 chain_code
                        ,xca_s.delivery_base_code               delivery_base_code
                  FROM   xxcmm_cust_accounts      xca_s
                        ,hz_cust_accounts         hca_s
                  WHERE  xca_s.chain_store_code IS NOT NULL
                  AND    hca_s.cust_account_id = xca_s.customer_id
                  AND    hca_s.customer_class_code IN ('10','12')
                )                     shop
               ,(
                  --base:���_���
                  SELECT hca_b.account_number                   account_number
                        ,xca_b.management_base_code             management_base_code
                  FROM   xxcmm_cust_accounts      xca_b
                        ,hz_cust_accounts         hca_b
                  WHERE  hca_b.cust_account_id = xca_b.customer_id
                  AND    hca_b.customer_class_code = '1'
                )                     base
                --xuiv:���[�U���
               ,xxcos_user_info_v     xuiv
           WHERE shop.delivery_base_code = base.account_number
           AND   xuiv.base_code IN (shop.delivery_base_code, base.management_base_code)
         )                               store
-- 2010/07/28 Ver.1.1 K.Oomata Mod End
        ,xxcmm_cust_accounts             xca
        ,hz_cust_accounts                hca
        ,hz_parties                      hp
-- 2010/07/28 Ver.1.1 K.Oomata Mod Start
--  WHERE  xca.chain_store_code = store.chain_code
  WHERE  xca.edi_chain_code  = store.chain_code
-- 2010/07/28 Ver.1.1 K.Oomata Mod End
  AND    hca.cust_account_id = xca.customer_id
  AND    hca.customer_class_code = '18'
  AND    hp.party_id = hca.party_id
;
COMMENT ON  COLUMN  xxcos_chain_security_v.user_id          IS  '���[�UID';
COMMENT ON  COLUMN  xxcos_chain_security_v.user_name        IS  '���[�U����';
COMMENT ON  COLUMN  xxcos_chain_security_v.account_number   IS  '�ڋq�R�[�h';
COMMENT ON  COLUMN  xxcos_chain_security_v.chain_code       IS  '�`�F�[���X�R�[�h';
COMMENT ON  COLUMN  xxcos_chain_security_v.chain_name       IS  '�`�F�[���X����';
--
COMMENT ON  TABLE   xxcos_chain_security_v                  IS  '�`�F�[���X�Z�L�����e�B�r���[';
