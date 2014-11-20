CREATE OR REPLACE VIEW XXCSM_ITEM_GROUP_1_NM_V
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
  AND     flv.enabled_flag = 'Y'  -- �L��
  AND     NVL(flv.start_date_active,xpcdv.process_date)  <= xpcdv.process_date
  AND     NVL(flv.end_date_active,xpcdv.process_date)    >= xpcdv.process_date
  AND     NOT EXISTS (SELECT 'X'
                      FROM   xxcsm_item_category_v xicv2
                      WHERE  xicv2.segment1 = flv.lookup_code)
  AND     INSTR(flv.lookup_code,'*',1,1) = 2   --����Q1���̂ݑΏ�
  UNION ALL
  SELECT  xicv.segment1    item_group_cd
         ,xicv.description item_group_nm
  FROM    xxcsm_item_category_v xicv
  WHERE   xicv.segment1 LIKE '%*%'
  AND     INSTR(xicv.segment1,'*',1,1) = 2
;
--
COMMENT ON COLUMN xxcsm_item_group_1_nm_v.item_group_cd         IS '���i�Q�R�[�h';
COMMENT ON COLUMN xxcsm_item_group_1_nm_v.item_group_nm         IS '���i�Q��';
--
COMMENT ON TABLE  xxcsm_item_group_1_nm_v                       IS '���i�Q1�����̃r���[';
