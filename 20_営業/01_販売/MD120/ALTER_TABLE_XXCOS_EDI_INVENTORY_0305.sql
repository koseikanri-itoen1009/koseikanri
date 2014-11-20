--テーブル定義追加
ALTER TABLE xxcos.xxcos_edi_inventory
  ADD (edi_received_date DATE NULL );


--コメント追加
COMMENT ON COLUMN xxcos.xxcos_edi_inventory.edi_received_date IS 'EDI受信日';