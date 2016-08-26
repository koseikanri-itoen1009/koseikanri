-- ロット別取引明細テーブル項目追加スクリプト
ALTER TABLE xxcoi.xxcoi_lot_transactions ADD (
  wf_delivery_flag  VARCHAR2(1)
)
/
COMMENT ON COLUMN xxcoi.xxcoi_lot_transactions.wf_delivery_flag  IS 'WF配信済フラグ';
/
