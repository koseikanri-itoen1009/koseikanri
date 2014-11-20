CREATE OR REPLACE VIEW xxcmn_v_set_yyyy_v
(
  attribute6
)
AS
  SELECT DISTINCT mfd.attribute6
  FROM mrp_forecast_designators   mfd
;
--
COMMENT ON COLUMN xxcmn_v_set_yyyy_v.attribute6 IS '対象の年度' ;
--
COMMENT ON TABLE  xxcmn_v_set_yyyy_v IS '値セット用VIEW（XXCMN_YYYY）' ;


