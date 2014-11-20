/************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2009. All rights reserved.
 *
 * View Name       : XXCOP_WK_YOKO_PLANNING
 * Description     : 横持計画物流ワークテーブル(ALTER文)
 ************************************************************************/
ALTER TABLE XXCOP.XXCOP_WK_YOKO_PLANNING
 ADD (
     crowd_class_code               VARCHAR2(40)
    ,expiration_day                 NUMBER
 );
--
COMMENT ON COLUMN xxcop.xxcop_wk_yoko_planning.crowd_class_code                  IS '群コード'
/
COMMENT ON COLUMN xxcop.xxcop_wk_yoko_planning.expiration_day                    IS '賞味期間'
/
--
