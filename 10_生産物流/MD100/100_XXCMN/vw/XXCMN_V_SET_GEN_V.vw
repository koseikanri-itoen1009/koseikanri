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
COMMENT ON COLUMN xxcmn_v_set_gen_v.attribute6 IS '�Ώۂ̔N�x';
COMMENT ON COLUMN xxcmn_v_set_gen_v.attribute5 IS '�Ώۂ̐���';
--
COMMENT ON TABLE  xxcmn_v_set_gen_v IS '�l�Z�b�g�pVIEW�iXXCMN_GEN�j';
