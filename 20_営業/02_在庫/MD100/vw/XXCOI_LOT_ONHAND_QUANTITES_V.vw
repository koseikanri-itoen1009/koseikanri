/************************************************************************
 * Copyright(c)SCSK Corporation, 2014. All rights reserved.
 *
 * View Name       : XXCOI_LOT_ONHAND_QUANTITES_V
 * Description     : ロケーション移動入力画面用ビュー
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2014/10/17    1.0   S.Itou           新規作成
 *
 ************************************************************************/
CREATE OR REPLACE VIEW XXCOI_LOT_ONHAND_QUANTITES_V
  (  organization_id                                                  -- 在庫組織ID
    ,base_code                                                        -- 拠点コード
    ,subinventory_code                                                -- 保管場所コード
    ,location_code                                                    -- ロケーションコード
    ,location_name                                                    -- ロケーション名称
    ,parent_item_id                                                   -- 親品目ID
    ,parent_item_code                                                 -- 親品目コード
    ,parent_item_name                                                 -- 親品目名称
    ,item_id                                                          -- 子品目ID
    ,item_code                                                        -- 子品目コード
    ,item_name                                                        -- 子品目名称
    ,lot                                                              -- ロット
    ,difference_summary_code                                          -- 固有記号
    ,case_in_qty                                                      -- 入数
    ,case_qty                                                         -- ケース数
    ,singly_qty                                                       -- バラ数
    ,summary_qty                                                      -- 取引数量
    ,created_by                                                       -- 作成者
    ,creation_date                                                    -- 作成日
    ,last_updated_by                                                  -- 最終更新者
    ,last_update_date                                                 -- 最終更新日
  )
AS
  SELECT   xloq.organization_id                                       -- 在庫組織ID
         , xloq.base_code                                             -- 拠点コード
         , xloq.subinventory_code                                     -- 保管場所コード
         , xloq.location_code                                         -- ロケーションコード
         , xmwl.location_name                                         -- ロケーション名称
         , msib_p.inventory_item_id                                   -- 親品目ID
         , msib_p.segment1                                            -- 親品目コード
         , ximb_p.item_short_name                                     -- 親品目名称
         , xloq.child_item_id                                         -- 子品目ID
         , msib_c.segment1                                            -- 子品目コード
         , ximb_c.item_short_name                                     -- 子品目名称
         , xloq.lot                                                   -- ロット
         , xloq.difference_summary_code                               -- 固有記号
         , xloq.case_in_qty                                           -- 入数
         , xloq.case_qty                                              -- ケース数
         , xloq.singly_qty                                            -- バラ数
         , xloq.summary_qty                                           -- 取引数量
         , xloq.created_by                                            -- 作成者
         , xloq.creation_date                                         -- 作成日
         , xloq.last_updated_by                                       -- 最終更新者
         , xloq.last_update_date                                      -- 最終更新日
  FROM     ic_item_mst_b                   iimb_p
         , xxcmn_item_mst_b                ximb_p
         , ic_item_mst_b                   iimb_c
         , xxcmn_item_mst_b                ximb_c
         , xxcoi_warehouse_location_mst_v  xmwl
         , mtl_system_items_b              msib_p
         , mtl_system_items_b              msib_c
         , xxcoi_lot_onhand_quantites      xloq
  WHERE    xmwl.organization_id      = xloq.organization_id
  AND      xmwl.base_code            = xloq.base_code
  AND      xmwl.subinventory_code    = xloq.subinventory_code
  AND      xmwl.location_code        = xloq.location_code
  AND      msib_c.inventory_item_id  = xloq.child_item_id
  AND      msib_c.organization_id    = xloq.organization_id
  AND      iimb_c.item_no            = msib_c.segment1
  AND      ximb_c.item_id            = iimb_c.item_id
  AND      ximb_c.start_date_active <= xxccp_common_pkg2.get_process_date
  AND      ximb_c.end_date_active   >= xxccp_common_pkg2.get_process_date
  AND      ximb_p.item_id            = ximb_c.parent_item_id
  AND      ximb_p.start_date_active <= xxccp_common_pkg2.get_process_date
  AND      ximb_p.end_date_active   >= xxccp_common_pkg2.get_process_date
  AND      iimb_p.item_id            = ximb_c.parent_item_id
  AND      msib_p.segment1           = iimb_p.item_no
  AND      msib_p.organization_id    = xloq.organization_id
/
COMMENT ON TABLE xxcoi_lot_onhand_quantites_v IS 'ロケーション移動入力画面用ビュー';
/
COMMENT ON COLUMN xxcoi_lot_onhand_quantites_v.organization_id IS '在庫組織ID';
/
COMMENT ON COLUMN xxcoi_lot_onhand_quantites_v.base_code IS '拠点コード';
/
COMMENT ON COLUMN xxcoi_lot_onhand_quantites_v.subinventory_code IS '保管場所コード';
/
COMMENT ON COLUMN xxcoi_lot_onhand_quantites_v.location_code IS 'ロケーションコード';
/
COMMENT ON COLUMN xxcoi_lot_onhand_quantites_v.location_name IS 'ロケーション名称';
/
COMMENT ON COLUMN xxcoi_lot_onhand_quantites_v.parent_item_id IS '親品目ID';
/
COMMENT ON COLUMN xxcoi_lot_onhand_quantites_v.parent_item_code IS '親品目コード';
/
COMMENT ON COLUMN xxcoi_lot_onhand_quantites_v.parent_item_name IS '親品目名称';
/
COMMENT ON COLUMN xxcoi_lot_onhand_quantites_v.item_id IS '子品目ID';
/
COMMENT ON COLUMN xxcoi_lot_onhand_quantites_v.item_code IS '子品目コード';
/
COMMENT ON COLUMN xxcoi_lot_onhand_quantites_v.item_name IS '子品目名称';
/
COMMENT ON COLUMN xxcoi_lot_onhand_quantites_v.lot IS 'ロット';
/
COMMENT ON COLUMN xxcoi_lot_onhand_quantites_v.difference_summary_code IS '固有記号';
/
COMMENT ON COLUMN xxcoi_lot_onhand_quantites_v.case_in_qty IS '入数';
/
COMMENT ON COLUMN xxcoi_lot_onhand_quantites_v.case_qty IS 'ケース数';
/
COMMENT ON COLUMN xxcoi_lot_onhand_quantites_v.singly_qty IS 'バラ数';
/
COMMENT ON COLUMN xxcoi_lot_onhand_quantites_v.summary_qty IS '取引数量';
/
COMMENT ON COLUMN xxcoi_lot_onhand_quantites_v.created_by IS '作成者';
/
COMMENT ON COLUMN xxcoi_lot_onhand_quantites_v.creation_date IS '作成日';
/
COMMENT ON COLUMN xxcoi_lot_onhand_quantites_v.last_updated_by IS '最終更新者';
/
COMMENT ON COLUMN xxcoi_lot_onhand_quantites_v.last_update_date IS '最終更新日';
/
