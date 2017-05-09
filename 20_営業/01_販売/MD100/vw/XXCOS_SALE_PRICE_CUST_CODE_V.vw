/************************************************************************
 * Copyright(c)SCSK Corporation, 2017. All rights reserved.
 *
 * View Name       : xxcos_sale_price_cust_code_v
 * Description     : �������i�\�ڋq�R�[�h�r���[
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2017/04/11    1.0   S.Niki           �V�K�쐬
 ************************************************************************/
CREATE OR REPLACE VIEW xxcos_sale_price_cust_code_v (
  account_number
 ,account_name
 ,sale_base_code
 ,delivery_base_code
 ,sales_head_base_code
)
AS
  SELECT
      hca.account_number         AS account_number
     ,hp.party_name              AS account_name
     ,xca.sale_base_code         AS sale_base_code
     ,xca.delivery_base_code     AS delivery_base_code
     ,xca.sales_head_base_code   AS sales_head_base_code
  FROM
      hz_cust_accounts             hca
     ,hz_parties                   hp
     ,xxcmm_cust_accounts          xca
  WHERE
      hca.party_id        = hp.party_id
  AND hca.cust_account_id = xca.customer_id
  AND EXISTS (SELECT 'X'
              FROM xxcos_sale_price_lists  xspl
              WHERE xspl.customer_id  = hca.cust_account_id
      )
  ORDER BY
      hca.account_number
;
COMMENT ON  COLUMN  xxcos_sale_price_cust_code_v.account_number       IS  '�ڋq�R�[�h';
COMMENT ON  COLUMN  xxcos_sale_price_cust_code_v.account_name         IS  '�ڋq��'; 
COMMENT ON  COLUMN  xxcos_sale_price_cust_code_v.sale_base_code       IS  '���㋒�_�R�[�h';
COMMENT ON  COLUMN  xxcos_sale_price_cust_code_v.delivery_base_code   IS  '�[�i���_�R�[�h'; 
COMMENT ON  COLUMN  xxcos_sale_price_cust_code_v.sales_head_base_code IS  '�̔���{���S�����_'; 
--
COMMENT ON  TABLE   xxcos_sale_price_cust_code_v                      IS  '�������i�\�ڋq�R�[�h�r���[';
