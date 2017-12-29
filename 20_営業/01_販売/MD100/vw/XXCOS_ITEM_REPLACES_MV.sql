/************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2017. All rights reserved.
 *
 * View Name       : XXCOS_ITEM_REPLACES_MV
 * Description     : VD���i���փ}�e���A���C�Y�h�r���[
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2017-12-18    1.0   K.Kiriu          �V�K�쐬(E_�{�ғ�_14486)
 *
 ************************************************************************/
CREATE MATERIALIZED VIEW APPS.XXCOS_ITEM_REPLACES_MV
  TABLESPACE "XXDATA2"
  BUILD IMMEDIATE 
  USING INDEX 
  REFRESH COMPLETE ON DEMAND 
  USING DEFAULT LOCAL ROLLBACK SEGMENT
  DISABLE QUERY REWRITE
  AS
SELECT xhit.item_code                  AS item_code        -- �i�ڃR�[�h
      ,MAX(xhit.invoice_date)          AS invoice_date     -- �`�[���t
      ,xhit.column_no                  AS column_no        -- �R������
      ,xhit.inside_cust_code           AS cust_code        -- �ڋq�R�[�h
FROM   apps.xxcoi_hht_inv_transactions    xhit             -- HHT���o�Ɉꎞ�\
WHERE  xhit.invoice_date            >=  ADD_MONTHS( xxccp_common_pkg2.get_process_date, - fnd_profile.value('XXCOS1_ITEM_REPLACES_MONTH_FROM'))
AND    xhit.invoice_date            <   xxccp_common_pkg2.get_process_date + 1
AND    xhit.record_Type             =   '22'
GROUP BY xhit.item_code,xhit.column_no,xhit.inside_cust_code
;
COMMENT ON  MATERIALIZED VIEW apps.xxcos_item_replaces_mv    IS 'VD���i���փ}�e���A���C�Y�h�r���['
/
COMMENT ON COLUMN apps.xxcos_item_replaces_mv.item_code      IS '�i�ڃR�[�h'
/
COMMENT ON COLUMN apps.xxcos_item_replaces_mv.invoice_date   IS '�`�[���t'
/
COMMENT ON COLUMN apps.xxcos_item_replaces_mv.column_no      IS '�R������'
/
COMMENT ON COLUMN apps.xxcos_item_replaces_mv.cust_code      IS '�ڋq�R�[�h'
/

