CREATE OR REPLACE VIEW XXCSM_HIERARCHY_LIST_V
(
  hierarchy_code
 ,hierarchy_name
)
AS
  SELECT ffv.flex_value      base_code
        ,ffvt.description    base_name
  FROM   fnd_flex_value_sets ffvs
        ,fnd_flex_values    ffv
        ,fnd_flex_values_tl ffvt
        ,(SELECT fpov.profile_option_value hierarchy_level
          FROM   fnd_profile_options       fpo
                ,fnd_profile_option_values fpov
          WHERE  fpo.profile_option_id = fpov.profile_option_id
          AND    fpo.profile_option_name = 'XXCSM1_CALC_POINT_POST_LEVEL'
          AND    fpo.application_id = fpov.application_id
         ) prof_v
        ,xxcsm_process_date_v  xpcdv
  WHERE  ffvs.flex_value_set_name = 'XX03_DEPARTMENT'
  AND    ffvs.flex_value_set_id = ffv.flex_value_set_id
  AND    ffv.flex_value_id = ffvt.flex_value_id
  AND    ffvt.language = USERENV('LANG')
  AND    ffv.enabled_flag = 'Y'
  AND    ffv.hierarchy_level = prof_v.hierarchy_level
  AND    (ffv.start_date_active <= xpcdv.process_date
          OR ffv.start_date_active IS NULL)
  AND    (ffv.end_date_active >= xpcdv.process_date
          OR ffv.end_date_active IS NULL)
  ;
--
COMMENT ON COLUMN xxcsm_hierarchy_list_v.hierarchy_code    IS '部門コード';
COMMENT ON COLUMN xxcsm_hierarchy_list_v.hierarchy_name    IS '部門名称';
--
COMMENT ON TABLE  xxcsm_hierarchy_list_v IS '資格ポイント部門一覧ビュー';