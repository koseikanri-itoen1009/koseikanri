/************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2009. All rights reserved.
 *
 * View Name       : XXCOP_ASSIGNMENT_CONTROLS
 * Description     : 特別横持制御マスタコントロールテーブル(ALTER文)
 ************************************************************************/
ALTER TABLE XXCOP.XXCOP_ASSIGNMENT_CONTROLS
 ADD (
  SHIP_FROM_CODE          VARCHAR2(4),
  SHIP_TO_CODE            VARCHAR2(4),
  PROD_START_DATE         DATE
 );
--
COMMENT ON COLUMN XXCOP.XXCOP_ASSIGNMENT_CONTROLS.SHIP_FROM_CODE         IS '出荷元倉庫';
COMMENT ON COLUMN XXCOP.XXCOP_ASSIGNMENT_CONTROLS.SHIP_TO_CODE           IS '入庫先倉庫';
COMMENT ON COLUMN XXCOP.XXCOP_ASSIGNMENT_CONTROLS.PROD_START_DATE        IS '製造年月日';
--