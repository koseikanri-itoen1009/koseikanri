/************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2009. All rights reserved.
 *
 * View Name       : XXCOP_MRP_SCHEDULE_INTERFACE
 * Description     : 基準計画IF表(ALTER文)
 ************************************************************************/
ALTER TABLE XXCOP.XXCOP_MRP_SCHEDULE_INTERFACE
 ADD (
  schedule_prod_date      DATE,
  prod_purchase_flg       VARCHAR2(1)
 );
--
COMMENT ON COLUMN XXCOP.XXCOP_MRP_SCHEDULE_INTERFACE.SCHEDULE_PROD_DATE                IS '生産予定日';
COMMENT ON COLUMN XXCOP.XXCOP_MRP_SCHEDULE_INTERFACE.PROD_PURCHASE_FLG                 IS '製造/購入品フラグ';
--