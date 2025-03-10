/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2014. All rights reserved.
 *
 * View Name       : XXCOI_TRANSFER_SUBINVENTORY_V
 * Description     : qÉÇVXe]æÛÇêr[
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2014/10/27    1.0   Y.Umino          VKì¬
 *
 ************************************************************************/
CREATE OR REPLACE VIEW xxcoi_transfer_subinventory_v
  (  organization_id                                                  -- ÝÉgDID
   , transfer_subinventory                                            -- ]æÛÇêR[h
   , transfer_subinventory_name                                       -- ]æÛÇê¼Ì
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
COMMENT ON TABLE xxcoi_transfer_subinventory_v IS 'qÉÇVXe]æÛÇêr[';
/
COMMENT ON COLUMN xxcoi_transfer_subinventory_v.organization_id IS 'ÝÉgDID';
/
COMMENT ON COLUMN xxcoi_transfer_subinventory_v.transfer_subinventory IS ']æÛÇêR[h';
/
COMMENT ON COLUMN xxcoi_transfer_subinventory_v.transfer_subinventory_name IS ']æÛÇê¼Ì';
/
