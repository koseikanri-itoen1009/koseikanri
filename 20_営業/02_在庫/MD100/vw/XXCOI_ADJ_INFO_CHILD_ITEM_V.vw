/************************************************************************
 * Copyright(c)SCSK Corporation, 2014. All rights reserved.
 *
 * View Name       : XXCOI_ADJ_INFO_CHILD_ITEM_V
 * Description     : 在庫調整情報画面_子品目ビュー
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2014/11/27    1.0   Y.Nagasue        新規作成
 *
 ************************************************************************/
 CREATE OR REPLACE VIEW xxcoi_adj_info_child_item_v(
   child_item_id     -- 子品目ID
  ,child_item_code   -- 子品目コード
  ,child_item_name   -- 子品目名
  ,case_in_qty       -- 入数
  ,parent_item_id    -- 親品目ID
  ,parent_item_code  -- 親品目コード
  ,parent_item_name  -- 親品目名
 )AS
SELECT msib.inventory_item_id               AS child_item_id
      ,msib.segment1                        AS child_item_code
      ,ximb.item_short_name                 AS child_item_name
      ,TO_NUMBER(iimb.attribute11)          AS case_in_qty
      ,msib_p.inventory_item_id             AS parent_item_id
      ,msib_p.segment1                      AS parent_item_code
      ,ximb_p.item_short_name               AS parent_item_name
FROM   ic_item_mst_b          iimb   
      ,xxcmn_item_mst_b       ximb   
      ,mtl_system_items_b     msib   
      ,xxcmm_system_items_b   xsib
      ,mtl_system_items_b     msib_p
      ,xxcmn_item_mst_b       ximb_p
      ,ic_item_mst_b          iimb_p 
WHERE  iimb.item_id         = ximb.item_id
AND    iimb.item_no         = xsib.item_code
AND    iimb.item_no         = msib.segment1
AND    msib.organization_id = xxcoi_common_pkg.get_organization_id(FND_PROFILE.VALUE('XXCOI1_ORGANIZATION_CODE'))
AND    xxccp_common_pkg2.get_process_date BETWEEN ximb.start_date_active AND ximb.end_date_active
AND    ximb.parent_item_id  = iimb_p.item_id
AND    iimb_p.item_id       = ximb_p.item_id
AND    iimb_p.item_no       = msib_p.segment1
AND    msib.organization_id = msib_p.organization_id
AND    xxccp_common_pkg2.get_process_date BETWEEN ximb_p.start_date_active AND ximb_p.end_date_active
AND    xsib.item_status IN ( '30' ,'40' ,'50' )
ORDER BY msib.segment1
/
COMMENT ON TABLE xxcoi_adj_info_child_item_v                    IS '在庫調整情報画面_子品目ビュー';
/
COMMENT ON COLUMN xxcoi_adj_info_child_item_v.child_item_id     IS '子品目ID';
/
COMMENT ON COLUMN xxcoi_adj_info_child_item_v.child_item_code   IS '子品目コード';
/
COMMENT ON COLUMN xxcoi_adj_info_child_item_v.child_item_name   IS '子品目名';
/
COMMENT ON COLUMN xxcoi_adj_info_child_item_v.case_in_qty       IS '入数';
/ 
COMMENT ON COLUMN xxcoi_adj_info_child_item_v.parent_item_id    IS '親品目ID';
/
COMMENT ON COLUMN xxcoi_adj_info_child_item_v.parent_item_code  IS '親品目コード';
/
COMMENT ON COLUMN xxcoi_adj_info_child_item_v.parent_item_name  IS '親品目名';
/
