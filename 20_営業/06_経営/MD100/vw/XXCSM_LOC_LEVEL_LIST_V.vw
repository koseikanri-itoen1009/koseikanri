CREATE OR REPLACE VIEW XXCSM_LOC_LEVEL_LIST_V 
(
  cd_level1
 ,cd_level2
 ,cd_level3
 ,cd_level4
 ,cd_level5
 ,cd_level6
 ,location_level
)
AS
  SELECT DISTINCT
         ffv_l1.flex_value AS cd_level1
        ,ffv_l2.flex_value AS cd_level2
        ,ffv_l3.flex_value AS cd_level3
        ,ffv_l4.flex_value AS cd_level4
        ,ffv_l5.flex_value AS cd_level5
        ,ffv_l6.flex_value AS cd_level6
        ,CASE WHEN ffv_l2.flex_value IS NULL THEN ffv_l1.hierarchy_level
              WHEN ffv_l3.flex_value IS NULL THEN ffv_l2.hierarchy_level
              WHEN ffv_l4.flex_value IS NULL THEN ffv_l3.hierarchy_level
              WHEN ffv_l5.flex_value IS NULL THEN ffv_l4.hierarchy_level
              WHEN ffv_l6.flex_value IS NULL THEN ffv_l5.hierarchy_level
         ELSE ffv_l6.hierarchy_level END AS location_level
  FROM   fnd_flex_value_sets  ffvs
        ,fnd_flex_values ffv_l1
        ,fnd_flex_value_norm_hierarchy ffvh_l1
        ,fnd_flex_values ffv_l2
        ,fnd_flex_value_norm_hierarchy ffvh_l2
        ,fnd_flex_values ffv_l3
        ,fnd_flex_value_norm_hierarchy ffvh_l3
        ,fnd_flex_values ffv_l4
        ,fnd_flex_value_norm_hierarchy ffvh_l4
        ,fnd_flex_values ffv_l5
        ,fnd_flex_value_norm_hierarchy ffvh_l5
        ,fnd_flex_values ffv_l6
        ,xxcsm_process_date_v xpcdv
  WHERE  ffvs.flex_value_set_name = 'XX03_DEPARTMENT'
  AND    ffvs.flex_value_set_id = ffv_l1.flex_value_set_id(+)
  AND    ffvh_l1.flex_value_set_id = ffv_l2.flex_value_set_id(+)
  AND    ffv_l1.flex_value_set_id = ffvh_l1.flex_value_set_id(+)
  AND    ffvh_l2.flex_value_set_id = ffv_l3.flex_value_set_id(+)
  AND    ffv_l2.flex_value_set_id = ffvh_l2.flex_value_set_id(+)
  AND    ffvh_l3.flex_value_set_id = ffv_l4.flex_value_set_id(+)
  AND    ffv_l3.flex_value_set_id = ffvh_l3.flex_value_set_id(+)
  AND    ffvh_l4.flex_value_set_id = ffv_l5.flex_value_set_id(+)
  AND    ffv_l4.flex_value_set_id = ffvh_l4.flex_value_set_id(+)
  AND    ffvh_l5.flex_value_set_id = ffv_l6.flex_value_set_id(+)
  AND    ffv_l5.flex_value_set_id = ffvh_l5.flex_value_set_id(+)
  --L1
  AND    ffv_l1.enabled_flag = 'Y'
  AND    xpcdv.process_date
      BETWEEN NVL(ffv_l1.start_date_active,xpcdv.process_date)
      AND     NVL(ffv_l1.end_date_active,xpcdv.process_date)
  AND    ffv_l1.hierarchy_level = 'L1'
  AND    ffv_l1.flex_value = ffvh_l1.parent_flex_value(+)
  --L2
  AND    NVL(ffv_l2.enabled_flag,'Y') = 'Y'
  AND    xpcdv.process_date
     BETWEEN NVL(ffv_l2.start_date_active,xpcdv.process_date)
     AND     NVL(ffv_l2.end_date_active,xpcdv.process_date)
  AND    NVL(ffv_l2.hierarchy_level,'L2') = 'L2'
  AND    ffv_l2.flex_value(+) BETWEEN ffvh_l1.child_flex_value_low AND ffvh_l1.child_flex_value_high
  AND    ffv_l2.flex_value = ffvh_l2.parent_flex_value(+)
  --L3
  AND    NVL(ffv_l3.enabled_flag,'Y') = 'Y'
  AND    xpcdv.process_date
      BETWEEN NVL(ffv_l3.start_date_active,xpcdv.process_date)
      AND     NVL(ffv_l3.end_date_active,xpcdv.process_date)
  AND    NVL(ffv_l3.hierarchy_level,'L3') = 'L3'
  AND    ffv_l3.flex_value(+) BETWEEN ffvh_l2.child_flex_value_low AND ffvh_l2.child_flex_value_high
  AND    ffv_l3.flex_value = ffvh_l3.parent_flex_value(+)
  --L4
  AND    NVL(ffv_l4.enabled_flag,'Y') = 'Y'
  AND    xpcdv.process_date
      BETWEEN NVL(ffv_l4.start_date_active,xpcdv.process_date) 
      AND     NVL(ffv_l4.end_date_active,xpcdv.process_date)
  AND    NVL(ffv_l4.hierarchy_level,'L4') = 'L4'
  AND    ffv_l4.flex_value(+) BETWEEN ffvh_l3.child_flex_value_low AND ffvh_l3.child_flex_value_high
  AND    ffv_l4.flex_value = ffvh_l4.parent_flex_value(+)
  --L5
  AND    NVL(ffv_l5.enabled_flag,'Y') = 'Y'
  AND    xpcdv.process_date
      BETWEEN NVL(ffv_l5.start_date_active,xpcdv.process_date) 
      AND     NVL(ffv_l5.end_date_active,xpcdv.process_date)
  AND    NVL(ffv_l5.hierarchy_level,'L5') = 'L5'
  AND    ffv_l5.flex_value(+) BETWEEN ffvh_l4.child_flex_value_low AND ffvh_l4.child_flex_value_high
  AND    ffv_l5.flex_value = ffvh_l5.parent_flex_value(+)
  --L6
  AND    NVL(ffv_l6.enabled_flag,'Y') = 'Y'
  AND    xpcdv.process_date
      BETWEEN NVL(ffv_l6.start_date_active,xpcdv.process_date) 
      AND     NVL(ffv_l6.end_date_active,xpcdv.process_date)
  AND    NVL(ffv_l6.hierarchy_level,'L6') = 'L6'
  AND    ffv_l6.flex_value(+) BETWEEN ffvh_l5.child_flex_value_low AND ffvh_l5.child_flex_value_high
;
--
COMMENT ON COLUMN xxcsm_loc_level_list_v.cd_level1       IS 'ëÊàÍäKëwïîñÂÉRÅ[Éh';
COMMENT ON COLUMN xxcsm_loc_level_list_v.cd_level2       IS 'ëÊìÒäKëwïîñÂÉRÅ[Éh';
COMMENT ON COLUMN xxcsm_loc_level_list_v.cd_level3       IS 'ëÊéOäKëwïîñÂÉRÅ[Éh';
COMMENT ON COLUMN xxcsm_loc_level_list_v.cd_level4       IS 'ëÊéläKëwïîñÂÉRÅ[Éh';
COMMENT ON COLUMN xxcsm_loc_level_list_v.cd_level5       IS 'ëÊå‹äKëwïîñÂÉRÅ[Éh';
COMMENT ON COLUMN xxcsm_loc_level_list_v.cd_level6       IS 'ëÊòZäKëwïîñÂÉRÅ[Éh';
COMMENT ON COLUMN xxcsm_loc_level_list_v.location_level  IS 'ãíì_äKëw';
--                
COMMENT ON TABLE  xxcsm_loc_level_list_v IS 'ïîñÂàÍóóÉrÉÖÅ[';
