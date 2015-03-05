/************************************************************************
 * Copyright(c)SCSK Corporation, 2014. All rights reserved.
 *
 * View Name       : XXCOI_MST_WAREHOUSE_LOCATION_V
 * Description     : 倉庫ロケーションマスタ管理画面用ビュー
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2014/12/01    1.0   R.Oikawa           新規作成
 *
 ************************************************************************/
CREATE OR REPLACE VIEW XXCOI_MST_WAREHOUSE_LOCATION_V
  (  warehouse_location_id                                            -- 倉庫ロケーションマスタID
    ,organization_id                                                  -- 在庫組織ID
    ,base_code                                                        -- 拠点コード
    ,subinventory_code                                                -- 保管場所コード
    ,location_code                                                    -- ロケーションコード
    ,location_name                                                    -- ロケーション名称
    ,location_type                                                    -- ロケーションタイプ
    ,location_type_name                                               -- ロケーションタイプ名称
    ,priority                                                         -- 優先順位
    ,disable_date                                                     -- 無効日
    ,parent_item_id                                                   -- 親品目ID
    ,parent_item_code                                                 -- 親品目コード
    ,parent_item_name                                                 -- 親品目名称
    ,item_id                                                          -- 子品目ID
    ,item_code                                                        -- 子品目コード
    ,item_name                                                        -- 子品目名称
    ,attribute1                                                       -- DFF1
    ,created_by                                                       -- 作成者
    ,creation_date                                                    -- 作成日
    ,last_updated_by                                                  -- 最終更新者
    ,last_update_date                                                 -- 最終更新日
    ,last_update_login                                                -- 最終更新ログイン
  )
AS
  SELECT   xmwl.warehouse_location_id                                 -- 倉庫ロケーションマスタID
         , xmwl.organization_id                                       -- 在庫組織ID
         , xmwl.base_code                                             -- 拠点コード
         , xmwl.subinventory_code                                     -- 保管場所コード
         , xmwl.location_code                                         -- ロケーションコード
         , xmwl.location_name                                         -- ロケーション名称
         , xmwl.location_type                                         -- ロケーションタイプ
         , xmwl.location_type_name                                    -- ロケーションタイプ名称
         , xmwl.priority                                              -- 優先順位
         , xmwl.disable_date                                          -- 無効日
         , msib_p.inventory_item_id                                   -- 親品目ID
         , msib_p.segment1                                            -- 親品目コード
         , ximb_p.item_short_name                                     -- 親品目名称
         , xmwl.child_item_id                                         -- 子品目ID
         , msib_c.segment1                                            -- 子品目コード
         , ximb_c.item_short_name                                     -- 子品目名称
         , flv.attribute1                                             -- DFF1
         , xmwl.created_by                                            -- 作成者
         , xmwl.creation_date                                         -- 作成日
         , xmwl.last_updated_by                                       -- 最終更新者
         , xmwl.last_update_date                                      -- 最終更新日
         , xmwl.last_update_login                                     -- 最終更新ログイン
  FROM     xxcoi_mst_warehouse_location    xmwl
         , ic_item_mst_b                   iimb_p
         , xxcmn_item_mst_b                ximb_p
         , ic_item_mst_b                   iimb_c
         , xxcmn_item_mst_b                ximb_c
         , mtl_system_items_b              msib_p
         , mtl_system_items_b              msib_c
         , fnd_lookup_values               flv
  WHERE    xmwl.organization_id      = msib_c.organization_id
  AND      xmwl.child_item_id        = msib_c.inventory_item_id
  AND      msib_c.segment1           = iimb_c.item_no
  AND      iimb_c.item_id            = ximb_c.item_id
  AND      xxccp_common_pkg2.get_process_date BETWEEN ximb_c.start_date_active
    AND ximb_c.end_date_active
  AND      ximb_c.parent_item_id     = ximb_p.item_id
  AND      xxccp_common_pkg2.get_process_date BETWEEN ximb_p.start_date_active
    AND ximb_p.end_date_active
  AND      ximb_p.item_id            = iimb_p.item_id
  AND      iimb_p.item_no            = msib_p.segment1
  AND      xmwl.organization_id      = msib_p.organization_id
  AND      flv.lookup_type           = 'XXCOI1_LOCATION_TYPE_NAME'
  AND      flv.lookup_code           = '1'
  AND      flv.enabled_flag          = 'Y'
  AND      xxccp_common_pkg2.get_process_date BETWEEN flv.start_date_active
    AND NVL(flv.end_date_active, xxccp_common_pkg2.get_process_date)
  AND      flv.language              = USERENV('LANG')
  AND      xmwl.location_type        = flv.lookup_code
UNION ALL
  SELECT   xmwl.warehouse_location_id                                 -- 倉庫ロケーションマスタID
         , xmwl.organization_id                                       -- 在庫組織ID
         , xmwl.base_code                                             -- 拠点コード
         , xmwl.subinventory_code                                     -- 保管場所コード
         , xmwl.location_code                                         -- ロケーションコード
         , xmwl.location_name                                         -- ロケーション名称
         , xmwl.location_type                                         -- ロケーションタイプ
         , xmwl.location_type_name                                    -- ロケーションタイプ名称
         , xmwl.priority                                              -- 優先順位
         , xmwl.disable_date                                          -- 無効日
         , NULL                                                       -- 親品目ID
         , NULL                                                       -- 親品目コード
         , NULL                                                       -- 親品目名称
         , NULL                                                       -- 子品目ID
         , NULL                                                       -- 子品目コード
         , NULL                                                       -- 子品目名称
         , flv.attribute1                                             -- DFF1
         , xmwl.created_by                                            -- 作成者
         , xmwl.creation_date                                         -- 作成日
         , xmwl.last_updated_by                                       -- 最終更新者
         , xmwl.last_update_date                                      -- 最終更新日
         , xmwl.last_update_login                                     -- 最終更新ログイン
  FROM     xxcoi_mst_warehouse_location    xmwl
         , fnd_lookup_values               flv
  WHERE    flv.lookup_type           = 'XXCOI1_LOCATION_TYPE_NAME'
  AND      flv.lookup_code           <> '1'
  AND      flv.enabled_flag          = 'Y'
  AND      xxccp_common_pkg2.get_process_date BETWEEN flv.start_date_active
    AND NVL(flv.end_date_active, xxccp_common_pkg2.get_process_date)
  AND      flv.language              = USERENV('LANG')
  AND      xmwl.location_type        = flv.lookup_code
/
COMMENT ON TABLE xxcoi_mst_warehouse_location_v IS '倉庫ロケーションマスタ管理画面用ビュー';
/
COMMENT ON COLUMN xxcoi_mst_warehouse_location_v.warehouse_location_id IS '倉庫ロケーションマスタID';
/
COMMENT ON COLUMN xxcoi_mst_warehouse_location_v.organization_id IS '在庫組織ID';
/
COMMENT ON COLUMN xxcoi_mst_warehouse_location_v.base_code IS '拠点コード';
/
COMMENT ON COLUMN xxcoi_mst_warehouse_location_v.subinventory_code IS '保管場所コード';
/
COMMENT ON COLUMN xxcoi_mst_warehouse_location_v.location_code IS 'ロケーションコード';
/
COMMENT ON COLUMN xxcoi_mst_warehouse_location_v.location_name IS 'ロケーション名称';
/
COMMENT ON COLUMN xxcoi_mst_warehouse_location_v.location_type IS 'ロケーションタイプ';
/
COMMENT ON COLUMN xxcoi_mst_warehouse_location_v.location_type_name IS 'ロケーションタイプ名称';
/
COMMENT ON COLUMN xxcoi_mst_warehouse_location_v.priority IS '優先順位';
/
COMMENT ON COLUMN xxcoi_mst_warehouse_location_v.disable_date IS '無効日';
/
COMMENT ON COLUMN xxcoi_mst_warehouse_location_v.parent_item_id IS '親品目ID';
/
COMMENT ON COLUMN xxcoi_mst_warehouse_location_v.parent_item_code IS '親品目コード';
/
COMMENT ON COLUMN xxcoi_mst_warehouse_location_v.parent_item_name IS '親品目名称';
/
COMMENT ON COLUMN xxcoi_mst_warehouse_location_v.item_id IS '子品目ID';
/
COMMENT ON COLUMN xxcoi_mst_warehouse_location_v.item_code IS '子品目コード';
/
COMMENT ON COLUMN xxcoi_mst_warehouse_location_v.item_name IS '子品目名称';
/
COMMENT ON COLUMN xxcoi_mst_warehouse_location_v.attribute1 IS 'DFF1';
/
COMMENT ON COLUMN xxcoi_mst_warehouse_location_v.created_by IS '作成者';
/
COMMENT ON COLUMN xxcoi_mst_warehouse_location_v.creation_date IS '作成日';
/
COMMENT ON COLUMN xxcoi_mst_warehouse_location_v.last_updated_by IS '最終更新者';
/
COMMENT ON COLUMN xxcoi_mst_warehouse_location_v.last_update_date IS '最終更新日';
/
COMMENT ON COLUMN xxcoi_mst_warehouse_location_v.last_update_login IS '最終更新ログイン';
/
