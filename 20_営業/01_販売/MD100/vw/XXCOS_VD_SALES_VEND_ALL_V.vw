/************************************************************************
 * Copyright c 2011, SCSK Corporation. All rights reserved.
 *
 * View Name       : xxcos_vd_sales_vend_all_v
 * Description     : ���̋@�̔��񍐏��p�d����(�Ǘ��җp)�r���[
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 * 2012/02/09    1.0   K.Kiriu          [E_�{�ғ�_08359]�V�K�쐬
 * 2021/06/17    1.1   Y.Koh            [E_�{�ғ�_16294]�Ή�
 *
 ************************************************************************/
CREATE OR REPLACE VIEW xxcos_vd_sales_vend_all_v(
  vendor_code  -- �d����R�[�h
 ,vendor_name  -- �d���於��
)
AS
SELECT pv.segment1        vendor_code
      ,REPLACE( pv.vendor_name, pv.segment1, '' )
                          vendor_name
FROM   po_vendors  pv     --�d����}�X�^
WHERE  pv.segment1      LIKE '8%'
AND    EXISTS (
         SELECT /*+
                  INDEX(xca2 XXCMM_CUST_ACCOUNTS_N02)
                */
                1
         FROM   xxcmm_cust_accounts xca    --�ڋq�ǉ����
               ,hz_cust_accounts    hca    --�ڋq�}�X�^
               ,hz_parties          hp     --�p�[�e�B�}�X�^
-- 2021/06/17 Ver1.1 MOD Start
         WHERE  pv.segment1                  IN ( xca.contractor_supplier_code, xca.bm_pay_supplier_code1, xca.bm_pay_supplier_code2 )
--         WHERE  xca.contractor_supplier_code =  pv.segment1         --BM1�̎d����
-- 2021/06/17 Ver1.1 MOD End
         AND    xca.business_low_type        =  '25'                --�t��VD(�t��VD�����͎d����Ȃ����_�~�[)
         AND    xca.customer_id              =  hca.cust_account_id
         AND    hca.customer_class_code      =  '10'                --�ڋq�敪(�ڋq)
         AND    hca.party_id                 =  hp.party_id
         AND    hp.duns_number_c             >= '30'                --�ڋq�X�e�[�^�X(���オ�オ��X�e�[�^�X)
       )
;
COMMENT ON  COLUMN  xxcos_vd_sales_vend_all_v.vendor_code  IS '�d����R�[�h';
COMMENT ON  COLUMN  xxcos_vd_sales_vend_all_v.vendor_name  IS '�d���於��';
--
COMMENT ON  TABLE   xxcos_vd_sales_vend_all_v              IS '���̋@�̔��񍐏��p�d����(�Ǘ��җp)�r���[';
