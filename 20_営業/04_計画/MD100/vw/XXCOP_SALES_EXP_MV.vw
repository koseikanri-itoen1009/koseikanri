/************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * View Name       : XXCOP_SALES_EXP_MV
 * Description     : �v��_�̔����у}�e���A���C�Y�h�r���[
 * Version         : 1.1
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009-11-26    1.0   SCS.Kikuchi      �V�K�쐬
 *  2010-06-17    1.1   SCS.Niki         E_�{�ғ�_03010�Ή� 
 *
 ************************************************************************/
CREATE MATERIALIZED VIEW APPS.XXCOP_SALES_EXP_MV
  TABLESPACE "XXDATA2"
  BUILD IMMEDIATE
  USING INDEX
  REFRESH COMPLETE
  ON DEMAND
  USING DEFAULT LOCAL ROLLBACK SEGMENT
  DISABLE QUERY REWRITE
  AS
  SELECT xsel.delivery_base_code                     -- �[�i���_�R�[�h
  ,      xsel.item_code                              -- �i�ڃR�[�h
  ,      NVL(SUM(standard_qty),0) sum_standard_qty   -- �����
  FROM   xxcos_sales_exp_headers xseh                -- �̔����уw�b�_
  ,      xxcos_sales_exp_lines   xsel                -- �̔����і���
  WHERE  xseh.sales_exp_header_id =  xsel.sales_exp_header_id
  AND    xseh.dlv_invoice_class   IN ('1','3')       -- �[�i�`�[�敪
-- 2010/06/17 Ver1.1 ��Q�FE_�{�ғ�_03010 Delete Start by SCS.Niki
--  AND    xsel.sales_class         IN ('1','5','6')   -- ����敪
-- 2010/06/17 Ver1.1 ��Q�FE_�{�ғ�_03010 Delete End by SCS.Niki
  AND    xseh.delivery_date       BETWEEN TRUNC(xxccp_common_pkg2.get_process_date,'MM')
                                  AND     TRUNC(xxccp_common_pkg2.get_process_date) - (1/24/60/60)
  GROUP
  by     xsel.item_code
  ,      xsel.delivery_base_code
  ;
COMMENT ON COLUMN APPS.XXCOP_SALES_EXP_MV.item_code IS '�i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXCOP_SALES_EXP_MV.delivery_base_code IS '�[�i���_�R�[�h'
/
COMMENT ON COLUMN APPS.XXCOP_SALES_EXP_MV.sum_standard_qty IS '����ʍ��v'
/