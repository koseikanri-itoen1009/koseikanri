CREATE OR REPLACE VIEW xxcmn_delivery_lt_v
(
  delivery_lt_id,
  code_class1,
  entering_despatching_code1,
  code_class2,
  entering_despatching_code2,
  lt_start_date_active,
  lt_end_date_active,
  delivery_lead_time,
  consolidated_flag,
  drink_lead_time_day,
  leaf_lead_time_day,
  receipt_change_lead_time_day,
  ship_methods_id,
  ship_method,
  sm_start_date_active,
  sm_end_date_active,
  drink_deadweight,
  leaf_deadweight,
  drink_loading_capacity,
  leaf_loading_capacity,
  palette_max_qty
)
AS
  SELECT  xdl.delivery_lt_id,
          xdl.code_class1,
          xdl.entering_despatching_code1,
          xdl.code_class2,
          xdl.entering_despatching_code2,
          xdl.start_date_active,
          xdl.end_date_active,
          xdl.delivery_lead_time,
          xdl.consolidated_flag,
          xdl.drink_lead_time_day,
          xdl.leaf_lead_time_day,
          xdl.receipt_change_lead_time_day,
          xsm.ship_methods_id,
          xsm.ship_method,
          xsm.start_date_active,
          xsm.end_date_active,
          xsm.drink_deadweight,
          xsm.leaf_deadweight,
          xsm.drink_loading_capacity,
          xsm.leaf_loading_capacity,
          xsm.palette_max_qty
  FROM    xxcmn_delivery_lt   xdl,
          xxcmn_ship_methods  xsm
  WHERE xdl.code_class1                 = xsm.code_class1(+)
  AND   xdl.entering_despatching_code1  = xsm.entering_despatching_code1(+)
  AND   xdl.code_class2                 = xsm.code_class2(+)
  AND   xdl.entering_despatching_code2  = xsm.entering_despatching_code2(+)
  AND   xdl.start_date_active           <= TRUNC(SYSDATE)
  AND   xdl.end_date_active             >= TRUNC(SYSDATE)
  AND   xsm.start_date_active(+)        <= TRUNC(SYSDATE)
  AND   xsm.end_date_active(+)          >= TRUNC(SYSDATE)
;
--
COMMENT ON COLUMN xxcmn_delivery_lt_v.delivery_lt_id              IS '配送LTアドオンID';
COMMENT ON COLUMN xxcmn_delivery_lt_v.code_class1                 IS 'コード区分１';
COMMENT ON COLUMN xxcmn_delivery_lt_v.entering_despatching_code1  IS '入出庫場所コード１';
COMMENT ON COLUMN xxcmn_delivery_lt_v.code_class2                 IS 'コード区分２';
COMMENT ON COLUMN xxcmn_delivery_lt_v.entering_despatching_code2  IS '入出庫場所コード２';
COMMENT ON COLUMN xxcmn_delivery_lt_v.lt_start_date_active        IS '配送LT適用開始日';
COMMENT ON COLUMN xxcmn_delivery_lt_v.lt_end_date_active          IS '配送LT適用終了日';
COMMENT ON COLUMN xxcmn_delivery_lt_v.delivery_lead_time          IS '配送リードタイム';
COMMENT ON COLUMN xxcmn_delivery_lt_v.consolidated_flag           IS '混載許可フラグ';
COMMENT ON COLUMN xxcmn_delivery_lt_v.drink_lead_time_day         IS 'ドリンク生産物流LT';
COMMENT ON COLUMN xxcmn_delivery_lt_v.leaf_lead_time_day          IS 'リーフ生産物流LT';
COMMENT ON COLUMN xxcmn_delivery_lt_v.receipt_change_lead_time_day    IS '引取変更LT';
COMMENT ON COLUMN xxcmn_delivery_lt_v.ship_methods_id             IS '出荷方法アドオンID';
COMMENT ON COLUMN xxcmn_delivery_lt_v.ship_method                 IS '出荷方法';
COMMENT ON COLUMN xxcmn_delivery_lt_v.sm_start_date_active        IS '出荷方法適用開始日';
COMMENT ON COLUMN xxcmn_delivery_lt_v.sm_end_date_active          IS '出荷方法適用終了日';
COMMENT ON COLUMN xxcmn_delivery_lt_v.drink_deadweight            IS 'ドリンク積載重量';
COMMENT ON COLUMN xxcmn_delivery_lt_v.leaf_deadweight             IS 'リーフ積載重量';
COMMENT ON COLUMN xxcmn_delivery_lt_v.drink_loading_capacity      IS 'ドリンク積載容積';
COMMENT ON COLUMN xxcmn_delivery_lt_v.leaf_loading_capacity       IS 'リーフ積載容積';
COMMENT ON COLUMN xxcmn_delivery_lt_v.palette_max_qty             IS 'パレット最大枚数';
--
COMMENT ON TABLE  xxcmn_delivery_lt_v IS '配送L/T情報VIEW';
