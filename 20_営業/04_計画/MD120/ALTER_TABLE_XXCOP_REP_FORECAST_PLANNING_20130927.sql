-- テーブルに残存するデータ（エラーデータ）を削除
TRUNCATE TABLE XXCOP.XXCOP_REP_FORECAST_PLANNING;
--
-- 項目削除
ALTER TABLE XXCOP.XXCOP_REP_FORECAST_PLANNING DROP (
   CROWD_CLASS_CODE
  ,ITEM_NO
  ,PARENT_ITEM_NO
);
--
-- 項目追加
ALTER TABLE XXCOP.XXCOP_REP_FORECAST_PLANNING ADD (
   CROWD_CLASS_CODE_3 VARCHAR2(3)
  ,CROWD_CLASS_CODE   VARCHAR2(4)
  ,GROUP_ITEM_CODE    VARCHAR2(7)
);
COMMENT ON COLUMN XXCOP.XXCOP_REP_FORECAST_PLANNING.CROWD_CLASS_CODE_3 IS '政策群コード（上３桁）';
COMMENT ON COLUMN XXCOP.XXCOP_REP_FORECAST_PLANNING.CROWD_CLASS_CODE   IS '政策群コード';
COMMENT ON COLUMN XXCOP.XXCOP_REP_FORECAST_PLANNING.GROUP_ITEM_CODE    IS '集約コード';
