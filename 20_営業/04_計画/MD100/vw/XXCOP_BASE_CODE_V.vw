/************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * View Name       : XXCOP_BASE_CODE_V
 * Description     : �v��_�S�����_�r���[
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2008-12-09    1.0   SCS.Tsubomatsu  �V�K�쐬
 *
 ************************************************************************/
CREATE OR REPLACE FORCE VIEW XXCOP_BASE_CODE_V
  ( "BASE_CODE"     -- ���_�R�[�h
  , "BASE_NAME"     -- ���_����
  )
AS
  SELECT hca.account_number   AS base_code  -- ���_�R�[�h
        ,xp.party_short_name  AS base_name  -- ���_����
  FROM   hz_cust_accounts hca   -- �ڋq�}�X�^
        ,xxcmn_parties xp       -- �p�[�e�B�A�h�I���}�X�^
  WHERE  hca.customer_class_code = '1'
  AND    hca.party_id = xp.party_id (+)
  AND (( hca.account_number = xxcop_common_pkg.get_charge_base_code( FND_GLOBAL.USER_ID, SYSDATE ) )
  OR   ( hca.cust_account_id IN (
           SELECT xca.customer_id           -- �ڋqID
           FROM   xxcmm_cust_accounts xca   -- �ڋq�ǉ����
           WHERE  xca.management_base_code = xxcop_common_pkg.get_charge_base_code( FND_GLOBAL.USER_ID, SYSDATE ) )
       ))
--  AND    NVL( TO_DATE( hca.attribute3, 'yyyy/mm/dd' ), SYSDATE ) <= SYSDATE
  AND    xp.start_date_active(+) <= TRUNC( SYSDATE )
  AND    xp.end_date_active  (+) >= TRUNC( SYSDATE )
  ORDER BY DECODE( hca.account_number, xxcop_common_pkg.get_charge_base_code( FND_GLOBAL.USER_ID, SYSDATE ), 0, 1 )
          ,hca.account_number
  ;
--
COMMENT ON TABLE XXCOP_BASE_CODE_V IS '�v��_�S�����_�r���['
/
--
COMMENT ON COLUMN XXCOP_BASE_CODE_V.base_code IS '���_�R�[�h'
/
COMMENT ON COLUMN XXCOP_BASE_CODE_V.base_name IS '���_����'
/
