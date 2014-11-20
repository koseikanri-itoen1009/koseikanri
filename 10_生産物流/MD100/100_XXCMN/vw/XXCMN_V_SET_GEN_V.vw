CREATE OR REPLACE VIEW xxcmn_v_set_gen_v
(
  attribute6
 ,attribute5
)
AS
  SELECT DISTINCT mfd.attribute6
                 ,mfd.attribute5
  FROM mrp_forecast_designators   mfd
;
--
COMMENT ON COLUMN xxcmn_v_set_gen_v.attribute6 IS '対象の年度';
COMMENT ON COLUMN xxcmn_v_set_gen_v.attribute5 IS '対象の世代';
--
COMMENT ON TABLE  xxcmn_v_set_gen_v IS '値セット用VIEW（XXCMN_GEN）';
