CREATE OR REPLACE VIEW xxcmn_item_locations2_v
(
  mtl_organization_id,
  inventory_location_id,
  whse_code,
  whse_name,
  orgn_code,
  customer_stock_whse,
  whse_spare1,
  whse_spare2,
  whse_spare3,
  whse_spare4,
  whse_spare5,
  whse_spare6,
  whse_spare7,
  whse_spare8,
  whse_spare9,
  date_from,
  date_to,
  location_id,
  segment1,
  description,
  subinventory_code,
  disable_date,
  eos_control_type,
  eos_detination,
  whse_department,
  allow_pickup_flag,
  frequent_whse,
  distribution_block,
  frequent_mover,
  frequent_whse_code,
  whse_inside_outside_div,
  drink_calender,
  d1_whse_code,
  short_name,
  purchase_code,
  leaf_calender,
  direct_ship_type,
  purchase_site_code
)
AS
  SELECT  iwm.mtl_organization_id,
          mil.inventory_location_id,
          iwm.whse_code,
          iwm.whse_name,
          iwm.orgn_code,
          iwm.attribute1,
          iwm.attribute2,
          iwm.attribute3,
          iwm.attribute4,
          iwm.attribute5,
          iwm.attribute6,
          iwm.attribute7,
          iwm.attribute8,
          iwm.attribute9,
          iwm.attribute10,
          haou.date_from,
          haou.date_to,
          haou.location_id,
          mil.segment1,
          mil.description,
          mil.subinventory_code,
          mil.disable_date,
          CASE
            WHEN mil.attribute2 IS NULL
              THEN '0'
              ELSE '1'
          END,
          mil.attribute2,
          mil.attribute3,
          mil.attribute4,
          mil.attribute5,
          mil.attribute6,
          mil.attribute7,
          mil.attribute8,
          mil.attribute9,
          mil.attribute10,
          mil.attribute11,
          mil.attribute12,
          mil.attribute13,
          mil.attribute14,
          mil.attribute15,
          mil.attribute1
  FROM    ic_whse_mst               iwm,
          hr_all_organization_units haou,
          mtl_item_locations        mil
  WHERE   iwm.mtl_organization_id = haou.organization_id
  AND     haou.organization_id    = mil.organization_id
;
--
COMMENT ON COLUMN xxcmn_item_locations2_v.mtl_organization_id     IS 'ÝÉgDID';
COMMENT ON COLUMN xxcmn_item_locations2_v.inventory_location_id   IS 'qÉID';
COMMENT ON COLUMN xxcmn_item_locations2_v.whse_code               IS 'qÉR[h';
COMMENT ON COLUMN xxcmn_item_locations2_v.whse_name               IS 'qÉ¼';
COMMENT ON COLUMN xxcmn_item_locations2_v.orgn_code               IS 'vgR[h';
COMMENT ON COLUMN xxcmn_item_locations2_v.customer_stock_whse     IS 'èæÝÉÇÎÛ';
COMMENT ON COLUMN xxcmn_item_locations2_v.whse_spare1             IS 'qÉ\õ1';
COMMENT ON COLUMN xxcmn_item_locations2_v.whse_spare2             IS 'qÉ\õ2';
COMMENT ON COLUMN xxcmn_item_locations2_v.whse_spare3             IS 'qÉ\õ3';
COMMENT ON COLUMN xxcmn_item_locations2_v.whse_spare4             IS 'qÉ\õ4';
COMMENT ON COLUMN xxcmn_item_locations2_v.whse_spare5             IS 'qÉ\õ5';
COMMENT ON COLUMN xxcmn_item_locations2_v.whse_spare6             IS 'qÉ\õ6';
COMMENT ON COLUMN xxcmn_item_locations2_v.whse_spare7             IS 'qÉ\õ7';
COMMENT ON COLUMN xxcmn_item_locations2_v.whse_spare8             IS 'qÉ\õ8';
COMMENT ON COLUMN xxcmn_item_locations2_v.whse_spare9             IS 'qÉ\õ9';
COMMENT ON COLUMN xxcmn_item_locations2_v.date_from               IS 'gDLøJnú';
COMMENT ON COLUMN xxcmn_item_locations2_v.date_to                 IS 'gDLøI¹ú';
COMMENT ON COLUMN xxcmn_item_locations2_v.location_id             IS 'ÆID';
COMMENT ON COLUMN xxcmn_item_locations2_v.segment1                IS 'ÛÇqÉR[h';
COMMENT ON COLUMN xxcmn_item_locations2_v.description             IS 'ÛÇqÉ¼';
COMMENT ON COLUMN xxcmn_item_locations2_v.subinventory_code       IS 'ÛÇêR[h';
COMMENT ON COLUMN xxcmn_item_locations2_v.disable_date            IS '³øú';
COMMENT ON COLUMN xxcmn_item_locations2_v.eos_control_type        IS 'dnrÇæª';
COMMENT ON COLUMN xxcmn_item_locations2_v.eos_detination          IS 'dnr¶æ';
COMMENT ON COLUMN xxcmn_item_locations2_v.whse_department         IS 'qÉÇ';
COMMENT ON COLUMN xxcmn_item_locations2_v.allow_pickup_flag       IS 'o×øÎÛtO';
COMMENT ON COLUMN xxcmn_item_locations2_v.frequent_whse           IS 'ã\qÉ';
COMMENT ON COLUMN xxcmn_item_locations2_v.distribution_block      IS '¨¬ubN';
COMMENT ON COLUMN xxcmn_item_locations2_v.frequent_mover          IS 'ã\^ïÐ';
COMMENT ON COLUMN xxcmn_item_locations2_v.frequent_whse_code      IS 'åvÛÇqÉR[h';
COMMENT ON COLUMN xxcmn_item_locations2_v.whse_inside_outside_div IS 'àOqÉæª';
COMMENT ON COLUMN xxcmn_item_locations2_v.drink_calender          IS 'hNîJ_';
COMMENT ON COLUMN xxcmn_item_locations2_v.d1_whse_code            IS 'c{PqÉtO';
COMMENT ON COLUMN xxcmn_item_locations2_v.short_name              IS 'ªÌ';
COMMENT ON COLUMN xxcmn_item_locations2_v.purchase_code           IS 'düæR[h';
COMMENT ON COLUMN xxcmn_item_locations2_v.leaf_calender           IS '[tîJ_';
COMMENT ON COLUMN xxcmn_item_locations2_v.direct_ship_type        IS '¼qÉæª';
COMMENT ON COLUMN xxcmn_item_locations2_v.purchase_site_code      IS 'düæTCgR[h';
--
COMMENT ON TABLE  xxcmn_item_locations2_v IS 'OPMÛÇêîñVIEW2';
