/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : XXCOI_BASE_INFO_V
 * Description     : ���_���r���[
 * Version         : 1.1
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2008-12-05    1.0   SCS M.Yoshioka   �V�K�쐬
 *  2009/04/30    1.1   T.Nakamura       [��QT1_0877] �Z�~�R������ǉ�
 *
 ************************************************************************/
CREATE OR REPLACE VIEW XXCOI_BASE_INFO_V
  (base_code                                                          -- ���_�R�[�h
  ,base_short_name                                                    -- ���_����
  ,focus_base_code                                                    -- �i���݋��_
  )
AS
SELECT hca.account_number                                             -- ���_�R�[�h
      ,SUBSTRB(hca.account_name,1,8)                                  -- ���_����
      ,xca.management_base_code                                       -- �i���݋��_
FROM hz_cust_accounts hca                                             -- �ڋq�}�X�^
    ,xxcmm_cust_accounts xca                                          -- �ڋq�ǉ����
WHERE hca.customer_class_code = '1'
    AND hca.status = 'A'
    AND hca.cust_account_id = xca.customer_id
    AND hca.account_number <> NVL(xca.management_base_code,'99999')
    AND xca.management_base_code IS NOT NULL
UNION ALL
SELECT hca.account_number                                             -- ���_�R�[�h
      ,SUBSTRB(hca.account_name,1,8)                                  -- ���_����
      ,hca.account_number                                             -- �i���݋��_
FROM hz_cust_accounts hca                                             -- �ڋq�}�X�^
    ,xxcmm_cust_accounts xca                                          -- �ڋq�ǉ����
WHERE hca.customer_class_code = '1'
    AND hca.status = 'A'
    AND hca.cust_account_id = xca.customer_id
    AND hca.account_number <> NVL(xca.management_base_code,'99999');
/
COMMENT ON TABLE xxcoi_base_info_v IS '���_���r���[';
/
COMMENT ON COLUMN xxcoi_base_info_v.base_code IS '���_�R�[�h';
/
COMMENT ON COLUMN xxcoi_base_info_v.base_short_name IS '���_����';
/
COMMENT ON COLUMN xxcoi_base_info_v.focus_base_code IS '�i���݋��_';
/
