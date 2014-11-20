/************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2009. All rights reserved.
 *
 * View Name       : XXCOP_WK_YOKO_PLAN_OUTPUT
 * Description     : 横持計画出力ワークテーブル(ALTER文)
 ************************************************************************/
ALTER TABLE XXCOP.XXCOP_WK_YOKO_PLAN_OUTPUT
 ADD (
     crowd_class_code               VARCHAR2(40)
    ,expiration_day                 NUMBER
 );
--
COMMENT ON COLUMN xxcop.xxcop_wk_yoko_plan_output.crowd_class_code               IS '群コード'
/
COMMENT ON COLUMN xxcop.xxcop_wk_yoko_plan_output.expiration_day                 IS '賞味期間'
/
--
