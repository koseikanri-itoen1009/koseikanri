/************************************************************************
 * Copyright(c)SCSK Corporation, 2014. All rights reserved.
 *
 * View Name       : XXCOI_WAREHOUSE_LOCATION_MST_V
 * Description     : 倉庫ロケーションマスタビュー
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2014/12/04    1.0   SCSK Koh        新規作成
 *
 ************************************************************************/
CREATE OR REPLACE VIEW xxcoi_warehouse_location_mst_v
  (  warehouse_location_id              -- 倉庫ロケーションマスタID
    ,organization_id                    -- 在庫組織ID
    ,base_code                          -- 拠点コード
    ,subinventory_code                  -- 保管場所コード
    ,location_type                      -- ロケーションタイプ
    ,location_type_name                 -- ロケーションタイプ名称
    ,location_code                      -- ロケーションコード
    ,location_name                      -- ロケーション名称
  )
AS
  SELECT   xmwl1.warehouse_location_id  -- 倉庫ロケーションマスタID
          ,xmwl1.organization_id
          ,xmwl1.base_code
          ,xmwl1.subinventory_code
          ,xmwl1.location_type
          ,xmwl1.location_type_name
          ,xmwl1.location_code
          ,xmwl1.location_name
  FROM    xxcoi_mst_warehouse_location  xmwl1
  WHERE   warehouse_location_id   =
  (
  SELECT  MIN(warehouse_location_id)
  FROM    xxcoi_mst_warehouse_location  xmwl2
  WHERE   xmwl2.organization_id   = xmwl1.organization_id
  AND     xmwl2.base_code         = xmwl1.base_code
  AND     xmwl2.subinventory_code = xmwl1.subinventory_code
  AND     xmwl2.location_code     = xmwl1.location_code
  )
/
COMMENT ON TABLE xxcoi_warehouse_location_mst_v IS '倉庫ロケーションマスタ管理画面用ビュー';
/
COMMENT ON COLUMN xxcoi_warehouse_location_mst_v.warehouse_location_id IS '倉庫ロケーションマスタID';
/
COMMENT ON COLUMN xxcoi_warehouse_location_mst_v.organization_id IS '在庫組織ID';
/
COMMENT ON COLUMN xxcoi_warehouse_location_mst_v.base_code IS '拠点コード';
/
COMMENT ON COLUMN xxcoi_warehouse_location_mst_v.subinventory_code IS '保管場所コード';
/
COMMENT ON COLUMN xxcoi_warehouse_location_mst_v.location_type IS 'ロケーションタイプ';
/
COMMENT ON COLUMN xxcoi_warehouse_location_mst_v.location_type_name IS 'ロケーションタイプ名称';
/
COMMENT ON COLUMN xxcoi_warehouse_location_mst_v.location_code IS 'ロケーションコード';
/
COMMENT ON COLUMN xxcoi_warehouse_location_mst_v.location_name IS 'ロケーション名称';
/
