-- VDコラムマスタ項目追加スクリプト
ALTER TABLE xxcoi.xxcoi_mst_vd_column ADD (
  dlv_date_1         DATE,
  quantity_1         NUMBER(6),
  dlv_date_2         DATE,
  quantity_2         NUMBER(6),
  dlv_date_3         DATE,
  quantity_3         NUMBER(6),
  dlv_date_4         DATE,
  quantity_4         NUMBER(6),
  dlv_date_5         DATE,
  quantity_5         NUMBER(6),
  column_change_date DATE
)
/
COMMENT ON COLUMN xxcoi.xxcoi_mst_vd_column.dlv_date_1 IS '納品日1'
/
COMMENT ON COLUMN xxcoi.xxcoi_mst_vd_column.quantity_1 IS '本数1'
/
COMMENT ON COLUMN xxcoi.xxcoi_mst_vd_column.dlv_date_2 IS '納品日2'
/
COMMENT ON COLUMN xxcoi.xxcoi_mst_vd_column.quantity_2 IS '本数2'
/
COMMENT ON COLUMN xxcoi.xxcoi_mst_vd_column.dlv_date_3 IS '納品日3'
/
COMMENT ON COLUMN xxcoi.xxcoi_mst_vd_column.quantity_3 IS '本数3'
/
COMMENT ON COLUMN xxcoi.xxcoi_mst_vd_column.dlv_date_4 IS '納品日4'
/
COMMENT ON COLUMN xxcoi.xxcoi_mst_vd_column.quantity_4 IS '本数4'
/
COMMENT ON COLUMN xxcoi.xxcoi_mst_vd_column.dlv_date_5 IS '納品日5'
/
COMMENT ON COLUMN xxcoi.xxcoi_mst_vd_column.quantity_5 IS '本数5'
/
COMMENT ON COLUMN xxcoi.xxcoi_mst_vd_column.column_change_date IS 'コラム変更日'
/
