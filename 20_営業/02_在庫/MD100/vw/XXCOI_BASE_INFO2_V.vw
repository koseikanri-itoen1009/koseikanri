/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name   : XXCOI_BASE_INFO2_V
 * Description : ���_���r���[2
 * Version     : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2008/11/28    1.0   U.Sai            �V�K�쐬
 *
 ************************************************************************/

  CREATE OR REPLACE FORCE VIEW "APPS"."XXCOI_BASE_INFO2_V" ("BASE_CODE", "BASE_SHORT_NAME", "FOCUS_BASE_CODE") AS 
  SELECT hca.account_number                                 -- ���_�R�[�h
        ,SUBSTRB(hca.account_name,1,8)                      -- ���_����
        ,xca.management_base_code                           -- �i���݋��_
  FROM   hz_cust_accounts hca                               -- �ڋq�}�X�^
        ,xxcmm_cust_accounts xca                            -- �ڋq�ǉ����
  WHERE  hca.customer_class_code = '1'
  AND    hca.status = 'A'
  AND    hca.cust_account_id = xca.customer_id
  AND    xca.management_base_code IS NOT NULL
  UNION ALL
  SELECT hca.account_number                                 -- ���_�R�[�h
        ,SUBSTRB(hca.account_name,1,8)                      -- ���_����
        ,hca.account_number                                 -- �i���݋��_
  FROM   hz_cust_accounts hca                               -- �ڋq�}�X�^
        ,xxcmm_cust_accounts xca                            -- �ڋq�ǉ����
  WHERE  hca.customer_class_code = '1'
  AND    hca.status = 'A'
  AND    hca.cust_account_id = xca.customer_id
  AND    hca.account_number <> NVL(xca.management_base_code,'99999');
