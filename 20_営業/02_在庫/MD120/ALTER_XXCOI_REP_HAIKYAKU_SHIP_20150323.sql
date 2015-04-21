-- VDコラムマスタ項目追加スクリプト
ALTER TABLE xxcoi.xxcoi_rep_haikyaku_ship ADD (
  input_order_id  NUMBER
)
/
COMMENT ON COLUMN xxcoi.xxcoi_rep_haikyaku_ship.input_order_id   IS '入力順ID'
/
