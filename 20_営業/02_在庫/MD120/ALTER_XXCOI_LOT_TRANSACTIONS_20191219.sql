-- ロット別取引明細テーブル項目追加スクリプト
ALTER TABLE xxcoi.xxcoi_lot_transactions ADD (
  inside_warehouse_code VARCHAR2(10)
)
/
COMMENT ON COLUMN xxcoi.xxcoi_lot_transactions.inside_warehouse_code  IS '最終入庫保管場所';
/
