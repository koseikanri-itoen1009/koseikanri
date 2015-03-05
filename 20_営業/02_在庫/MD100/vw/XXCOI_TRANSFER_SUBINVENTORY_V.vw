/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2014. All rights reserved.
 *
 * View Name       : XXCOI_TRANSFER_SUBINVENTORY_V
 * Description     : 倉庫管理システム転送先保管場所ビュー
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2014/10/27    1.0   Y.Umino          新規作成
 *
 ************************************************************************/
CREATE OR REPLACE VIEW xxcoi_transfer_subinventory_v
  (  organization_id                                                  -- 在庫組織ID
   , transfer_subinventory                                            -- 転送先保管場所コード
   , transfer_subinventory_name                                       -- 転送先保管場所名称
  )
AS
  SELECT   mil.organization_id
         , mil.segment1
         , mil.attribute12
  FROM     mtl_item_locations  mil
  UNION ALL
  SELECT   msi.organization_id
         , msi.secondary_inventory_name
         , msi.description
  FROM     mtl_secondary_inventories  msi
  WHERE    msi.organization_id = xxcoi_common_pkg.get_organization_id(FND_PROFILE.VALUE('XXCOI1_ORGANIZATION_CODE'))
  AND      msi.attribute14 = 'Y'
/
COMMENT ON TABLE xxcoi_transfer_subinventory_v IS '倉庫管理システム転送先保管場所ビュー';
/
COMMENT ON COLUMN xxcoi_transfer_subinventory_v.organization_id IS '在庫組織ID';
/
COMMENT ON COLUMN xxcoi_transfer_subinventory_v.transfer_subinventory IS '転送先保管場所コード';
/
COMMENT ON COLUMN xxcoi_transfer_subinventory_v.transfer_subinventory_name IS '転送先保管場所名称';
/
