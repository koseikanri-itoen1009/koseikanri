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
        ,xxcsm_process_date_v  xpcdv
  WHERE  ffvs.flex_value_set_name = 'XX03_DEPARTMENT'
  AND    ffvs.flex_value_set_id = ffv.flex_value_set_id
  AND    ffv.flex_value_id = ffvt.flex_value_id
  AND    ffvt.language = USERENV('LANG')
  AND    ffv.enabled_flag = 'Y'
  AND    (ffv.start_date_active <= xpcdv.process_date
          OR ffv.start_date_active IS NULL)
  AND    (ffv.end_date_active >= xpcdv.process_date
          OR ffv.end_date_active IS NULL)
  AND    exists (SELECT 'X'
                 FROM   fnd_lookup_values  flv                      --クイックコード値
                 WHERE  flv.lookup_type = 'XXCSM1_CALC_POINT_LEVEL'    --コードタイプ:ポイント算出用部署階層を指す文字列（”XXCSM1_CALC_POINT_LEVEL”）
                 AND    flv.language    = 'JA'                         --言語
                 AND    NVL(flv.start_date_active,sysdate) <= sysdate    --有効開始日<=業務日付
                 AND    NVL(flv.end_date_active,sysdate) >= sysdate      --有効終了日>=業務日付
                 AND    flv.enabled_flag = 'Y'
                 AND    flv.lookup_code =  ffv.hierarchy_level)         --最下層レベルが参照タイプで返ってきた値
;
--
COMMENT ON COLUMN xxcsm_hierarchy_list_v.hierarchy_code    IS '部門コード';
COMMENT ON COLUMN xxcsm_hierarchy_list_v.hierarchy_name    IS '部門名称';
--
COMMENT ON TABLE  xxcsm_hierarchy_list_v IS '資格ポイント部門一覧ビュー';
/
