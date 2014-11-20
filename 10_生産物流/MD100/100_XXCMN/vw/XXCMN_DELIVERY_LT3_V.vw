CREATE OR REPLACE VIEW apps.xxcmn_delivery_lt3_v
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
  leaf_consolidated_flag,
  drink_lead_time_day,
  leaf_lead_time_day,
  receipt_change_lead_time_day
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
          xdl.leaf_consolidated_flag,
          xdl.drink_lead_time_day,
          xdl.leaf_lead_time_day,
          xdl.receipt_change_lead_time_day
  FROM    xxcmn_delivery_lt   xdl
;
--
COMMENT ON COLUMN xxcmn_delivery_lt3_v.delivery_lt_id              IS '配送LTアドオンID';
COMMENT ON COLUMN xxcmn_delivery_lt3_v.code_class1                 IS 'コード区分１';
COMMENT ON COLUMN xxcmn_delivery_lt3_v.entering_despatching_code1  IS '入出庫場所コード１';
COMMENT ON COLUMN xxcmn_delivery_lt3_v.code_class2                 IS 'コード区分２';
COMMENT ON COLUMN xxcmn_delivery_lt3_v.entering_despatching_code2  IS '入出庫場所コード２';
COMMENT ON COLUMN xxcmn_delivery_lt3_v.lt_start_date_active        IS '配送LT適用開始日';
COMMENT ON COLUMN xxcmn_delivery_lt3_v.lt_end_date_active          IS '配送LT適用終了日';
COMMENT ON COLUMN xxcmn_delivery_lt3_v.delivery_lead_time          IS '配送リードタイム';
COMMENT ON COLUMN xxcmn_delivery_lt3_v.consolidated_flag           IS 'ドリンク混載許可フラグ';
COMMENT ON COLUMN xxcmn_delivery_lt3_v.leaf_consolidated_flag      IS 'リーフ混載許可フラグ';
COMMENT ON COLUMN xxcmn_delivery_lt3_v.drink_lead_time_day         IS 'ドリンク生産物流LT';
COMMENT ON COLUMN xxcmn_delivery_lt3_v.leaf_lead_time_day          IS 'リーフ生産物流LT';
COMMENT ON COLUMN xxcmn_delivery_lt3_v.receipt_change_lead_time_day    IS '引取変更LT';
--
COMMENT ON TABLE  xxcmn_delivery_lt3_v IS '配送L/T情報VIEW3';
