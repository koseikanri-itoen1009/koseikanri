/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2014. All rights reserved.
 *
 * View Name       : XXCOI_LOT_TRAN_CHILD_ITEM_V
 * Description     : 倉庫管理システムロット取引子品目ビュー
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2014/11/04    1.0   Y.Umino          新規作成
 *
 ************************************************************************/
CREATE OR REPLACE VIEW xxcoi_lot_tran_child_item_v
  (  organization_id                                             -- 在庫組織ID
   , parent_item_id                                              -- 親品目ID(DISC)
   , child_item_id                                               -- 子品目ID(DISC)
   , child_item_no                                               -- 子品目コード
   , child_item_short_name                                       -- 子品目名称
  )
AS
  SELECT msib_c.organization_id      AS organization_id
       , msib_p.inventory_item_id    AS parent_item_id
       , msib_c.inventory_item_id    AS child_item_id
       , msib_c.segment1             AS child_item_no
       , ximb.item_short_name        AS child_item_short_name
  FROM mtl_system_items_b   msib_p
      ,ic_item_mst_b        iimb_p
      ,xxcmn_item_mst_b     ximb
      ,mtl_system_items_b   msib_c
      ,ic_item_mst_b        iimb_c
      ,xxcmm_system_items_b xsib
  WHERE xsib.item_status      IN ( '30' ,'40' ,'50' )
    AND iimb_c.item_id         = xsib.item_id
    AND msib_c.segment1        = iimb_c.item_no
    AND msib_c.organization_id = xxcoi_common_pkg.get_organization_id(FND_PROFILE.VALUE('XXCOI1_ORGANIZATION_CODE'))
    AND ximb.item_id           = iimb_c.item_id
    AND xxccp_common_pkg2.get_process_date
          BETWEEN ximb.start_date_active AND ximb.end_date_active
    AND iimb_p.item_id         = ximb.parent_item_id
    AND msib_p.segment1        = iimb_p.item_no
    AND msib_p.organization_id = xxcoi_common_pkg.get_organization_id(FND_PROFILE.VALUE('XXCOI1_ORGANIZATION_CODE'))
/
COMMENT ON TABLE xxcoi_lot_tran_child_item_v IS '倉庫管理システムロット取引子品目ビュー';
/
COMMENT ON COLUMN xxcoi_lot_tran_child_item_v.organization_id IS '在庫組織ID';
/
COMMENT ON COLUMN xxcoi_lot_tran_child_item_v.parent_item_id IS '親品目ID(DISC)';
/
COMMENT ON COLUMN xxcoi_lot_tran_child_item_v.child_item_id IS '子品目ID(DISC)';
/
COMMENT ON COLUMN xxcoi_lot_tran_child_item_v.child_item_no IS '子品目コード';
/
COMMENT ON COLUMN xxcoi_lot_tran_child_item_v.child_item_short_name IS '子品目名称';
/
