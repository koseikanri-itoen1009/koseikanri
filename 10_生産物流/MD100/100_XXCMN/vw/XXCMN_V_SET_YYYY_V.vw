CREATE OR REPLACE VIEW xxcmn_v_set_yyyy_v
(
  attribute6
)
AS
  SELECT DISTINCT mfd.attribute6
  FROM mrp_forecast_designators   mfd
;
--
COMMENT ON COLUMN xxcmn_v_set_yyyy_v.attribute6 IS '�Ώۂ̔N�x' ;
--
COMMENT ON TABLE  xxcmn_v_set_yyyy_v IS '�l�Z�b�g�pVIEW�iXXCMN_YYYY�j' ;


