/************************************************************************
 * Copyright c 2011, SCSK Corporation. All rights reserved.
 *
 * View Name       : xxcos_vd_sales_cust_v
 * Description     : ���̋@�̔��񍐏��p�ڋq�r���[
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 * 2012/02/09    1.0   K.Kiriu          [E_�{�ғ�_08359]�V�K�쐬
 *
 ************************************************************************/
CREATE OR REPLACE VIEW xxcos_vd_sales_cust_v(
   customer_code   -- �ڋq�R�[�h
  ,customer_name   -- �ڋq����
  ,sale_base_code  -- ���㋒�_�R�[�h
)
AS
SELECT /*+
         USE_NL(xca hca hp)
       */
       hca.account_number  customer_code   --�ڋq�R�[�h
      ,hp.party_name       customer_name   --�ڋq����
      ,xca.sale_base_code  sale_base_code  --���㋒�_�R�[�h
FROM   xxcmm_cust_accounts  xca
      ,hz_cust_accounts     hca
      ,hz_parties           hp
WHERE  xca.customer_id         =  hca.cust_account_id
AND    xca.business_low_type   IN ('24','25')   --�t��VD or �t��VD(����)
AND    hca.customer_class_code =  '10'          --�ڋq
AND    hca.party_id            =  hp.party_id
AND    hp.duns_number_c       >=  '30'          --����L��
;
COMMENT ON  COLUMN  xxcos_vd_sales_cust_v.customer_code   IS '�ڋq�R�[�h';
COMMENT ON  COLUMN  xxcos_vd_sales_cust_v.customer_name   IS '�ڋq����';
COMMENT ON  COLUMN  xxcos_vd_sales_cust_v.sale_base_code  IS '���㋒�_�R�[�h';
--
COMMENT ON  TABLE   xxcos_vd_sales_cust_v                 IS '���̋@�̔��񍐏��p�ڋq�r���[';
