-- ロット別引当情報テーブル項目追加スクリプト
ALTER TABLE xxcoi.xxcoi_lot_reserve_info ADD (
  wf_delivery_flag  VARCHAR2(1)
)
/
COMMENT ON COLUMN xxcoi.xxcoi_lot_reserve_info.wf_delivery_flag  IS 'WF配信済フラグ';
/
