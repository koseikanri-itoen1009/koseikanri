/************************************************************************
 * Copyright c 2011, SCSK Corporation. All rights reserved.
 *
 * View Name       : xxcos_vd_sales_cust_v
 * Description     : ���̋@�̔��񍐏��p�ڋq�r���[
 * Version         : 1.1
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 * 2012/02/09    1.0   K.Kiriu          [E_�{�ғ�_08359]�V�K�쐬
 * 2018/01/05    1.1   H.Maeda          [E_�{�ғ�_14793]�Ή�
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
-- 2018/01/05 Ver.1.1 H.Maeda E_�{�ғ�_14793 ADD START
UNION
--�u�Љ�҃`�F�[���X�R�[�h�Q�v
SELECT /*+
         USE_NL(xca hca hp)
       */
       hca.account_number     customer_code      --�ڋq�R�[�h
      ,hp.party_name          customer_name      --�ڋq����
      ,NVL(xca.intro_chain_code2, xca.sale_base_code)
                              intro_chain_code2  --�Љ�҃`�F�[���X�R�[�h�Q
FROM   xxcmm_cust_accounts  xca
      ,hz_cust_accounts     hca
      ,hz_parties           hp
WHERE  xca.customer_id         =  hca.cust_account_id
AND    xca.business_low_type   IN ('24','25')   --�t��VD or �t��VD(����)
AND    hca.customer_class_code =  '10'          --�ڋq
AND    hca.party_id            =  hp.party_id
AND    hp.duns_number_c       >=  '30'          --����L��
-- 2018/01/05 Ver.1.1 H.Maeda E_�{�ғ�_14793 ADD END
;
COMMENT ON  COLUMN  xxcos_vd_sales_cust_v.customer_code   IS '�ڋq�R�[�h';
COMMENT ON  COLUMN  xxcos_vd_sales_cust_v.customer_name   IS '�ڋq����';
COMMENT ON  COLUMN  xxcos_vd_sales_cust_v.sale_base_code  IS '���㋒�_�R�[�h';
--
COMMENT ON  TABLE   xxcos_vd_sales_cust_v                 IS '���̋@�̔��񍐏��p�ڋq�r���[';
