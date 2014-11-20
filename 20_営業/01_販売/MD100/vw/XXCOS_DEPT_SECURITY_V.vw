/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcos_dept_security_v
 * Description     : �S�ݓX�X�Z�L�����e�Bview
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/03/04    1.0   K.Kumamoto       �V�K�쐬
 ************************************************************************/
CREATE OR REPLACE VIEW xxcos_dept_security_v (
  user_id
 ,user_name
 ,account_number
 ,dept_code
 ,dept_name
)
AS
  SELECT DISTINCT
         store.user_id                   user_id
        ,store.user_name                 user_name
        ,hca.account_number              account_number
        ,xca.child_dept_shop_code        dept_code
        ,hp.party_name                   dept_name
  FROM   xxcos_dept_store_security_v     store
        ,xxcmm_cust_accounts             xca
        ,hz_cust_accounts                hca
        ,hz_parties                      hp
  WHERE  xca.child_dept_shop_code = store.dept_code
  AND    hca.cust_account_id = xca.customer_id
  AND    hca.customer_class_code = '19'
  AND    hp.party_id = hca.party_id
;
COMMENT ON  COLUMN  xxcos_dept_security_v.user_id          IS  '���[�UID';
COMMENT ON  COLUMN  xxcos_dept_security_v.user_name        IS  '���[�U����';
COMMENT ON  COLUMN  xxcos_dept_security_v.account_number   IS  '�ڋq�R�[�h';
COMMENT ON  COLUMN  xxcos_dept_security_v.dept_code        IS  '�S�ݓX�X�R�[�h';
COMMENT ON  COLUMN  xxcos_dept_security_v.dept_name        IS  '�S�ݓX����';
--
COMMENT ON  TABLE   xxcos_dept_security_v                  IS  '�S�ݓX�Z�L�����e�B�r���[';
