CREATE OR REPLACE VIEW xxcmn_v_set_post_code_02_v
(
  location_code,
  location_short_name
)
AS
  SELECT hla.location_code        AS location_code
        ,xla.location_short_name  AS location_short_name
  FROM   hr_locations_all     hla
        ,xxcmn_locations_all  xla
  WHERE hla.location_id = xla.location_id
  AND   SYSDATE BETWEEN xla.start_date_active AND
                        NVL( xla.end_date_active, SYSDATE )
  UNION ALL
  SELECT 'ZZZZ'                   AS location_code
        ,'部署での分類なし'       AS location_short_name
  FROM dual
;
--
COMMENT ON COLUMN xxcmn_v_set_post_code_02_v.location_code        IS '事業所コード';
COMMENT ON COLUMN xxcmn_v_set_post_code_02_v.location_short_name  IS '事業所名';
--
COMMENT ON TABLE  xxcmn_v_set_post_code_02_v IS '値セット用VIEW（XXCMN_POST_CODE_02）';
