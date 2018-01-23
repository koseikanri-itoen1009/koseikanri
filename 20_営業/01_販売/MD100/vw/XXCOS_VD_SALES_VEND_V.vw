/************************************************************************
 * Copyright c 2011, SCSK Corporation. All rights reserved.
 *
 * View Name       : xxcos_vd_sales_vend_v
 * Description     : ���̋@�̔��񍐏��p�d����(���_�p)�r���[
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
CREATE OR REPLACE VIEW xxcos_vd_sales_vend_v(
  vendor_code  -- �d����R�[�h
 ,vendor_name  -- �d���於��
)
AS
-- ���[�U���_(�Ǘ�������)�����㋒�_�̎d����
SELECT /*+
         NO_MERGE(xlbiv1)
       */
       DISTINCT
       pv1.segment1        vendor_code
      ,REPLACE( pv1.vendor_name, pv1.segment1, '' )
                           vendor_name
FROM   xxcos_login_base_info_v xlbiv1  --���[�U���_�r���[
      ,xxcmm_cust_accounts     xca1    --�ڋq�ǉ����
      ,hz_cust_accounts        hca1    --�ڋq�}�X�^
      ,hz_parties              hp1     --�p�[�e�B�}�X�^
      ,po_vendors              pv1     --�d����}�X�^
WHERE  xlbiv1.base_code              =  xca1.sale_base_code
AND    xca1.business_low_type        =  '25'                   --�t��VD(�t��VD�����͎d����Ȃ����_�~�[)
AND    xca1.customer_id              =  hca1.cust_account_id
AND    hca1.customer_class_code      =  '10'                   --�ڋq�敪(�ڋq)
AND    hca1.party_id                 =  hp1.party_id
AND    hp1.duns_number_c             >= '30'                   --�ڋq�X�e�[�^�X(���オ�オ��X�e�[�^�X)
AND    xca1.contractor_supplier_code =  pv1.segment1           --BM1�̎d����
-- 2018/01/05 Ver.1.1 H.Maeda E_�{�ғ�_14793 ADD START
UNION
-- ���[�U���_(�Ǘ�������)���Љ�҃`�F�[���X�R�[�h�Q�̎d����
SELECT /*+
         NO_MERGE(xlbiv1)
       */
       DISTINCT
       pv1.segment1        vendor_code
      ,REPLACE( pv1.vendor_name, pv1.segment1, '' )
                           vendor_name
FROM   xxcos_login_base_info_v xlbiv1  --���[�U���_�r���[
      ,xxcmm_cust_accounts     xca1    --�ڋq�ǉ����
      ,hz_cust_accounts        hca1    --�ڋq�}�X�^
      ,hz_parties              hp1     --�p�[�e�B�}�X�^
      ,po_vendors              pv1     --�d����}�X�^
WHERE  xlbiv1.base_code              =  xca1.intro_chain_code2
AND    xca1.business_low_type        =  '25'                   --�t��VD(�t��VD�����͎d����Ȃ����_�~�[)
AND    xca1.customer_id              =  hca1.cust_account_id
AND    hca1.customer_class_code      =  '10'                   --�ڋq�敪(�ڋq)
AND    hca1.party_id                 =  hp1.party_id
AND    hp1.duns_number_c             >= '30'                   --�ڋq�X�e�[�^�X(���オ�オ��X�e�[�^�X)
AND    xca1.contractor_supplier_code =  pv1.segment1           --BM1�̎d����
-- 2018/01/05 Ver.1.1 H.Maeda E_�{�ғ�_14793 ADD END
UNION
-- �����_���⍇���S�����_�̎d����
SELECT /*+
         NO_MERGE(xlbiv2)
       */
       DISTINCT
       pv2.segment1        vendor_code
      ,REPLACE( pv2.vendor_name, pv2.segment1, '' )
                           vendor_name
FROM   xxcos_login_base_info_v      xlbiv2  --���[�U���_�r���[
      ,po_vendor_sites_all          pvsa2   --�d����T�C�g
      ,po_vendors                   pv2     --�d����}�X�^
WHERE  xlbiv2.base_code  =    pvsa2.attribute5
AND    pv2.segment1      LIKE '8%'
AND    pvsa2.vendor_id   =    pv2.vendor_id
AND    EXISTS (
         SELECT /*+
                  INDEX(xca2 XXCMM_CUST_ACCOUNTS_N02)
                */
                1
         FROM   xxcmm_cust_accounts xca2    --�ڋq�ǉ����
               ,hz_cust_accounts    hca2    --�ڋq�}�X�^
               ,hz_parties          hp2     --�p�[�e�B�}�X�^
         WHERE  xca2.contractor_supplier_code =  pv2.segment1         --BM1�̎d����
         AND    xca2.business_low_type        =  '25'                 --�t��VD(�t��VD�����͎d����Ȃ����_�~�[)
         AND    xca2.customer_id              =  hca2.cust_account_id
         AND    hca2.customer_class_code      =  '10'                 --�ڋq�敪(�ڋq)
         AND    hca2.party_id                 =  hp2.party_id
         AND    hp2.duns_number_c             >= '30'                 --�ڋq�X�e�[�^�X(���オ�オ��X�e�[�^�X)
         AND    ROWNUM                        = 1
       )
;
COMMENT ON  COLUMN  xxcos_vd_sales_vend_v.vendor_code  IS '�d����R�[�h';
COMMENT ON  COLUMN  xxcos_vd_sales_vend_v.vendor_name  IS '�d���於��';
--
COMMENT ON  TABLE   xxcos_vd_sales_vend_v              IS '���̋@�̔��񍐏��p�d����(���_�p)�r���[';
