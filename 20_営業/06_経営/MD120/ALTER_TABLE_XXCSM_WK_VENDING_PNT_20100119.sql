--テーブル定義追加
ALTER TABLE XXCSM.XXCSM_WK_VENDING_PNT
  ADD (data_kbn VARCHAR2(100)  NULL );

--コメント追加
COMMENT ON COLUMN xxcsm.xxcsm_wk_vending_pnt.data_kbn IS 'データ区分';