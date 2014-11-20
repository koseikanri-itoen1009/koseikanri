CREATE OR REPLACE VIEW xxcsm_item_group_3_nm_v
(
  item_group_cd
 ,item_group_nm
)
AS
  SELECT  flv.lookup_code item_group_cd
         ,flv.meaning     item_group_nm
  FROM    fnd_lookup_values      flv
         ,xxcsm_process_date_v   xpcdv
  WHERE   flv.lookup_type  = 'XXCSM1_ITEM_GROUP'
  AND     flv.language     = USERENV('LANG')
  AND     flv.enabled_flag = 'Y'  -- 有効
  AND     NVL(flv.start_date_active,xpcdv.process_date)  <= xpcdv.process_date
  AND     NVL(flv.end_date_active,xpcdv.process_date)    >= xpcdv.process_date
  AND     INSTR(flv.lookup_code,'*',1,1) = 4   --政策群3桁のみ対象
  UNION
  SELECT  xicv.segment1    item_group_cd
         ,xicv.description item_group_nm
  FROM    xxcsm_item_category_v xicv
  WHERE   xicv.segment1 LIKE '%*%'
  AND     INSTR(xicv.segment1,'*',1,1) = 4
;
--
COMMENT ON COLUMN xxcsm_item_group_3_nm_v.item_group_cd         IS '商品群コード';
COMMENT ON COLUMN xxcsm_item_group_3_nm_v.item_group_nm         IS '商品群名';
--
COMMENT ON TABLE  xxcsm_item_group_3_nm_v                       IS '【暫定版】商品群3桁名称ビュー';
