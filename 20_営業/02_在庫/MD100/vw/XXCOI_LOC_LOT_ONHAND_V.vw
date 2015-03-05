/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2014. All rights reserved.
 *
 * View Name       : XXCOI_LOC_LOT_ONHAND_V
 * Description     : ロケーション別ロット別手持在庫情報画面ビュー
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2014/12/09    1.0   S.Yamashita      新規作成
 *
 ************************************************************************/
 CREATE OR REPLACE VIEW xxcoi_loc_lot_onhand_v(
   organization_id                                                                       -- 在庫組織ID
  ,base_code                                                                             -- 拠点コード
  ,base_name                                                                             -- 拠点名称
  ,subinventory_code                                                                     -- 保管場所コード
  ,subinventory_name                                                                     -- 保管場所名
  ,location_code                                                                         -- ロケーション
  ,location_name                                                                         -- ロケーション名
  ,parent_item_id                                                                        -- 親品目ID
  ,parent_item_code                                                                      -- 親品目
  ,parent_item_name                                                                      -- 親品目名
  ,child_item_id                                                                         -- 子品目ID
  ,child_item_code                                                                       -- 子品目
  ,child_item_name                                                                       -- 子品目名
  ,lot                                                                                   -- ロット(賞味期限)
  ,difference_summary_code                                                               -- 固有記号
  ,case_in_qty                                                                           -- 入数
  ,case_qty                                                                              -- ケース数
  ,singly_qty                                                                            -- バラ数
  ,onhand_qty                                                                            -- 手持数量
  ,reserved_qty                                                                          -- 引当可能数
  ,production_date                                                                       -- 製造日
  ,created_by                                                                            -- 作成者
  ,creation_date                                                                         -- 作成日
  ,last_updated_by                                                                       -- 最終更新者
  ,last_update_date                                                                      -- 最終更新日
  ,last_update_login                                                                     -- 最終更新ログイン
 )AS
   SELECT /*+ INDEX(xloq xxcoi_lot_onhand_quantites_n01) */
          xloq.organization_id                                   organization_id         -- 在庫組織ID
         ,xloq.base_code                                         base_code               -- 拠点コード
         ,hp.party_name                                          base_name               -- 拠点名称
         ,xloq.subinventory_code                                 subinventory_code       -- 保管場所
         ,msi.description                                        subinventory_name       -- 保管場所名
         ,xloq.location_code                                     location_code           -- ロケーション
         ,xwlmv.location_name                                    location_name           -- ロケーション名
         ,msib_oya.inventory_item_id                             parent_item_id          -- 親品目ID
         ,msib_oya.segment1                                      parent_item_code        -- 親品目
         ,ximb_oya.item_short_name                               parent_item_name        -- 親品目名
         ,msib_ko.inventory_item_id                              child_item_id           -- 子品目ID
         ,msib_ko.segment1                                       child_item_code         -- 子品目
         ,ximb_ko.item_short_name                                child_item_name         -- 子品目名
         ,xloq.lot                                               lot                     -- ロット(賞味期限)
         ,xloq.difference_summary_code                           difference_summary_code -- 固有記号
         ,xloq.case_in_qty                                       case_in_qty             -- 入数
         ,xloq.case_qty                                          case_qty                -- ケース数
         ,xloq.singly_qty                                        singly_qty              -- バラ数
         ,xloq.summary_qty                                       onhand_qty              -- 手持数量
         ,NULL
         ,xloq.production_date                                   production_date         -- 製造日
         ,xloq.created_by                                        created_by              -- 作成者
         ,xloq.creation_date                                     creation_date           -- 作成日
         ,xloq.last_updated_by                                   last_updated_by         -- 最終更新者
         ,xloq.last_update_date                                  last_update_date        -- 最終更新日
         ,xloq.last_update_login                                 last_update_login       -- 最終更新ログイン
   FROM   xxcoi_lot_onhand_quantites     xloq
         ,xxcoi_warehouse_location_mst_v xwlmv
         ,mtl_system_items_b             msib_oya
         ,mtl_system_items_b             msib_ko
         ,ic_item_mst_b                  iimb_oya
         ,ic_item_mst_b                  iimb_ko
         ,xxcmn_item_mst_b               ximb_oya
         ,xxcmn_item_mst_b               ximb_ko
         ,hz_cust_accounts               hca
         ,hz_parties                     hp
         ,mtl_secondary_inventories      msi
   WHERE  xloq.organization_id   = xwlmv.organization_id
   AND    xloq.base_code         = xwlmv.base_code
   AND    xloq.subinventory_code = xwlmv.subinventory_code
   AND    xloq.location_code     = xwlmv.location_code
   AND    xloq.organization_id   = msib_ko.organization_id
   AND    xloq.child_item_id     = msib_ko.inventory_item_id
   AND    msib_ko.segment1       = iimb_ko.item_no
   AND    iimb_ko.item_id        = ximb_ko.item_id
   AND    xxccp_common_pkg2.get_process_date 
            BETWEEN ximb_ko.start_date_active AND ximb_ko.end_date_active
   AND    ximb_ko.parent_item_id = ximb_oya.item_id
   AND    xxccp_common_pkg2.get_process_date
            BETWEEN ximb_oya.start_date_active AND ximb_oya.end_date_active
   AND    ximb_oya.item_id       = iimb_oya.item_id
   AND    iimb_oya.item_no       = msib_oya.segment1
   AND    xloq.organization_id   = msib_oya.organization_id
   AND    xloq.base_code         = hca.account_number
   AND    hca.party_id           = hp.party_id
   AND    hca.customer_class_code = '1'
   AND    xloq.organization_id   = msi.organization_id
   AND    xloq.subinventory_code = msi.secondary_inventory_name
/
COMMENT ON TABLE xxcoi_loc_lot_onhand_v IS 'ロケーション別ロット別手持在庫情報画面ビュー';
/
COMMENT ON COLUMN xxcoi_loc_lot_onhand_v.organization_id IS '在庫組織ID';
/
COMMENT ON COLUMN xxcoi_loc_lot_onhand_v.base_code IS '拠点コード';
/
COMMENT ON COLUMN xxcoi_loc_lot_onhand_v.base_name IS '拠点名称';
/
COMMENT ON COLUMN xxcoi_loc_lot_onhand_v.subinventory_code IS '保管場所';
/
COMMENT ON COLUMN xxcoi_loc_lot_onhand_v.subinventory_name IS '保管場所名';
/
COMMENT ON COLUMN xxcoi_loc_lot_onhand_v.location_code IS 'ロケーション';
/
COMMENT ON COLUMN xxcoi_loc_lot_onhand_v.location_name IS 'ロケーション名';
/
COMMENT ON COLUMN xxcoi_loc_lot_onhand_v.parent_item_id IS '親品目ID';
/
COMMENT ON COLUMN xxcoi_loc_lot_onhand_v.parent_item_code IS '親品目';
/
COMMENT ON COLUMN xxcoi_loc_lot_onhand_v.parent_item_name IS '親品目名';
/
COMMENT ON COLUMN xxcoi_loc_lot_onhand_v.child_item_id IS '子品目ID';
/
COMMENT ON COLUMN xxcoi_loc_lot_onhand_v.child_item_code IS '子品目';
/
COMMENT ON COLUMN xxcoi_loc_lot_onhand_v.child_item_name IS '子品目名';
/
COMMENT ON COLUMN xxcoi_loc_lot_onhand_v.lot IS 'ロット(賞味期限)';
/
COMMENT ON COLUMN xxcoi_loc_lot_onhand_v.difference_summary_code IS '固有記号';
/
COMMENT ON COLUMN xxcoi_loc_lot_onhand_v.case_in_qty IS '入数';
/
COMMENT ON COLUMN xxcoi_loc_lot_onhand_v.case_qty IS 'ケース数';
/
COMMENT ON COLUMN xxcoi_loc_lot_onhand_v.singly_qty IS 'バラ数';
/
COMMENT ON COLUMN xxcoi_loc_lot_onhand_v.onhand_qty IS '手持数量';
/
COMMENT ON COLUMN xxcoi_loc_lot_onhand_v.reserved_qty IS '引当可能数';
/
COMMENT ON COLUMN xxcoi_loc_lot_onhand_v.production_date IS '製造日';
/
COMMENT ON COLUMN xxcoi_loc_lot_onhand_v.created_by IS '作成者';
/
COMMENT ON COLUMN xxcoi_loc_lot_onhand_v.creation_date IS '作成日';
/
COMMENT ON COLUMN xxcoi_loc_lot_onhand_v.last_updated_by IS '最終更新者';
/
COMMENT ON COLUMN xxcoi_loc_lot_onhand_v.last_update_date IS '最終更新日';
/
COMMENT ON COLUMN xxcoi_loc_lot_onhand_v.last_update_login IS '最終更新ログイン';
/
