/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcos_dept_store_security_v
 * Description     : �X��(�S�ݓX)�Z�L�����e�Bview
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/03/04    1.0   K.Kumamoto       �V�K�쐬
 ************************************************************************/
CREATE OR REPLACE VIEW xxcos_dept_store_security_v (
  user_id
 ,user_name
 ,account_number
 ,dept_code
 ,dept_store_code
 ,dept_store_name
)
AS
  SELECT xuiv.user_id                                        user_id
        ,xuiv.user_name                                      user_name
        ,store.account_number                                account_number
        ,store.dept_code                                     dept_code
        ,store.store_code                                    store_code
        ,store.cust_store_name                               cust_store_name
  FROM (
    --store:�S�ݓX�X�܏��
    SELECT hca_s.account_number                              account_number
          ,xca_s.child_dept_shop_code                        dept_code
          ,xca_s.delivery_base_code                          delivery_base_code
          ,xca_s.store_code                                  store_code
          ,xca_s.cust_store_name                             cust_store_name
    FROM   xxcmm_cust_accounts                               xca_s
          ,hz_cust_accounts                                  hca_s
    WHERE  xca_s.child_dept_shop_code IS NOT NULL
    AND    hca_s.cust_account_id = xca_s.customer_id
    AND    hca_s.customer_class_code IN ('10')
  )                                                          store
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
  AND   xuiv.base_code in (store.delivery_base_code, base.management_base_code)
;
COMMENT ON  COLUMN  xxcos_dept_store_security_v.user_id          IS  '���[�UID';
COMMENT ON  COLUMN  xxcos_dept_store_security_v.user_name        IS  '���[�U����';
COMMENT ON  COLUMN  xxcos_dept_store_security_v.account_number   IS  '�ڋq�R�[�h';
COMMENT ON  COLUMN  xxcos_dept_store_security_v.dept_code        IS  '�S�ݓX�R�[�h';
COMMENT ON  COLUMN  xxcos_dept_store_security_v.dept_store_code  IS  '�X�܃R�[�h';
COMMENT ON  COLUMN  xxcos_dept_store_security_v.dept_store_name  IS  '�X�ܖ���';
--
COMMENT ON  TABLE   xxcos_dept_store_security_v                  IS  '�X��(�S�ݓX)�Z�L�����e�B�r���[';
