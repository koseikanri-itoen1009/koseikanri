CREATE OR REPLACE VIEW XXCSM_LOC_NAME_LIST_V
(
  base_code
 ,base_name
 ,parent_flag
 ,hierarchy_level
)
AS
  SELECT ffv.flex_value      base_code
        ,ffvt.description    base_name
        ,ffv.summary_flag    parent_flag
        ,ffv.hierarchy_level hierarchy_level
  FROM   fnd_flex_value_sets ffvs
        ,fnd_flex_values    ffv
        ,fnd_flex_values_tl ffvt
        ,xxcsm_process_date_v xpcdv
  WHERE  ffvs.flex_value_set_name = 'XX03_DEPARTMENT'
  AND    ffvs.flex_value_set_id = ffv.flex_value_set_id
  AND    ffv.flex_value_id = ffvt.flex_value_id
  AND    ffvt.language = USERENV('LANG')
  AND    ffv.enabled_flag = 'Y'
  AND    (ffv.end_date_active >= xpcdv.process_date
          OR ffv.end_date_active IS NULL)
;
--
COMMENT ON COLUMN xxcsm_loc_name_list_v.base_code           IS '部門コード';
COMMENT ON COLUMN xxcsm_loc_name_list_v.base_name           IS '部門名称';
COMMENT ON COLUMN xxcsm_loc_name_list_v.parent_flag         IS '親フラグ';
COMMENT ON COLUMN xxcsm_loc_name_list_v.hierarchy_level     IS '階層';
--                
COMMENT ON TABLE  xxcsm_loc_name_list_v IS '部門名称ビュー';
                  
