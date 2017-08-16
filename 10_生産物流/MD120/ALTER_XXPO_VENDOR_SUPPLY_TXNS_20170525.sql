-- 外注出来高実績（アドオン）項目追加スクリプト
ALTER TABLE xxpo.xxpo_vendor_supply_txns ADD (
  po_number  VARCHAR2(20)
)
/
COMMENT ON COLUMN xxpo.xxpo_vendor_supply_txns.po_number  IS '発注番号';
/
