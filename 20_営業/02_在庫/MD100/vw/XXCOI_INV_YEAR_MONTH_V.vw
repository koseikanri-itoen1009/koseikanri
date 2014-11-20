/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name   : XXCOI_INV_YEAR_MONTH_V
 * Description : �󕥔N���r���[
 * Version     : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2008/12/02    1.0   H.Sasaki         �V�K�쐬
 *
 ************************************************************************/
CREATE OR REPLACE FORCE VIEW XXCOI_INV_YEAR_MONTH_V(
   INVENTORY_YEAR_MONTH
) AS 
      SELECT  DISTINCT  inventory_year_month
      FROM    xxcoi_inv_control
      WHERE   inventory_kbn   = '2'
      AND     inventory_date  < xxccp_common_pkg2.get_process_date;
/
COMMENT ON TABLE  XXCOI_INV_YEAR_MONTH_V                        IS '�󕥔N���r���[';
/
COMMENT ON COLUMN XXCOI_INV_YEAR_MONTH_V.INVENTORY_YEAR_MONTH   IS '�󕥔N��';
/
