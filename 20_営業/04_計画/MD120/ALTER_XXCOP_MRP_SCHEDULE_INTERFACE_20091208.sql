/************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2009. All rights reserved.
 *
 * View Name       : XXCOP_MRP_SCHEDULE_INTERFACE
 * Description     : ��v��IF�\(ALTER��)
 ************************************************************************/
ALTER TABLE XXCOP.XXCOP_MRP_SCHEDULE_INTERFACE
 ADD (
  schedule_prod_date      DATE,
  prod_purchase_flg       VARCHAR2(1)
 );
--
COMMENT ON COLUMN XXCOP.XXCOP_MRP_SCHEDULE_INTERFACE.SCHEDULE_PROD_DATE                IS '���Y�\���';
COMMENT ON COLUMN XXCOP.XXCOP_MRP_SCHEDULE_INTERFACE.PROD_PURCHASE_FLG                 IS '����/�w���i�t���O';
--