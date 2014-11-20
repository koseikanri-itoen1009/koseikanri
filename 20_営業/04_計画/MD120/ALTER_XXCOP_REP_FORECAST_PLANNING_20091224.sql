/************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2009. All rights reserved.
 *
 * View Name       : XXCOP_REP_FORECAST_PLANNING
 * Description     : 引取計画立案表帳票ワークテーブル(ALTER文)
 ************************************************************************/
ALTER TABLE XXCOP.XXCOP_REP_FORECAST_PLANNING MODIFY(
  SHIP_TO_QUANTITY_15_MONTHS_AGO      NUMBER(13,2),
  SHIP_TO_QUANTITY_14_MONTHS_AGO      NUMBER(13,2)
)
/
