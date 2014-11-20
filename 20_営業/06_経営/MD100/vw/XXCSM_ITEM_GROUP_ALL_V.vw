CREATE OR REPLACE VIEW XXCSM_ITEM_GROUP_ALL_V
(
  item_group_cd
 ,item_group_nm
)
AS
  SELECT xign.item_group_cd  item_group_cd
        ,xign.item_group_nm  item_group_nm
  FROM   xxcsm_item_group_3_nm_v xign
  UNION ALL
  SELECT flv.lookup_code     item_group_cd  --"1"
        ,flv.meaning         item_group_nm  --全政策群
  FROM   fnd_lookup_values flv
        ,xxcsm_process_date_v  xpcdv
  WHERE  flv.lookup_type = 'XXCSM1_ITEM_PLAN_PARAM'
  AND    flv.language = USERENV('LANG')
  AND    flv.enabled_flag = 'Y'
  AND    NVL(flv.start_date_active,xpcdv.process_date)  <= xpcdv.process_date
  AND    NVL(flv.end_date_active,xpcdv.process_date)    >= xpcdv.process_date
  ;
--
COMMENT ON COLUMN xxcsm_item_group_all_v.item_group_cd           IS '政策群コード(3桁)';
COMMENT ON COLUMN xxcsm_item_group_all_v.item_group_nm           IS '政策群名(3桁)';
--                
COMMENT ON TABLE  xxcsm_item_group_all_v IS '全政策群＋政策群3桁ビュー';