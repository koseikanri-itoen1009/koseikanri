-- ロット別引当可能数量一時表項目追加スクリプト
ALTER TABLE xxcoi.xxcoi_tmp_lot_reserve_qty ADD (
  priority NUMBER
)
/
COMMENT ON COLUMN xxcoi.xxcoi_tmp_lot_reserve_qty.priority  IS '優先順位';
/