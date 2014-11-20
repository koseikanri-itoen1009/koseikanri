CREATE OR REPLACE VIEW xxcmn_item_locations_v
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
  location_id,
  segment1,
  description,
  subinventory_code,
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
          haou.location_id,
          mil.segment1,
          mil.description,
          mil.subinventory_code,
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
  WHERE iwm.mtl_organization_id =   haou.organization_id
  AND   haou.organization_id    =   mil.organization_id
  AND   haou.date_from          <=  TRUNC(SYSDATE)
  AND   ( haou.date_to IS NULL OR haou.date_to >= TRUNC(SYSDATE) )
  AND   mil.disable_date        IS NULL
;
--
COMMENT ON COLUMN xxcmn_item_locations_v.mtl_organization_id     IS '在庫組織ID';
COMMENT ON COLUMN xxcmn_item_locations_v.inventory_location_id   IS '倉庫ID';
COMMENT ON COLUMN xxcmn_item_locations_v.whse_code               IS '倉庫コード';
COMMENT ON COLUMN xxcmn_item_locations_v.whse_name               IS '倉庫名';
COMMENT ON COLUMN xxcmn_item_locations_v.orgn_code               IS 'プラントコード';
COMMENT ON COLUMN xxcmn_item_locations_v.customer_stock_whse     IS '相手先在庫管理対象';
COMMENT ON COLUMN xxcmn_item_locations_v.whse_spare1             IS '倉庫予備1';
COMMENT ON COLUMN xxcmn_item_locations_v.whse_spare2             IS '倉庫予備2';
COMMENT ON COLUMN xxcmn_item_locations_v.whse_spare3             IS '倉庫予備3';
COMMENT ON COLUMN xxcmn_item_locations_v.whse_spare4             IS '倉庫予備4';
COMMENT ON COLUMN xxcmn_item_locations_v.whse_spare5             IS '倉庫予備5';
COMMENT ON COLUMN xxcmn_item_locations_v.whse_spare6             IS '倉庫予備6';
COMMENT ON COLUMN xxcmn_item_locations_v.whse_spare7             IS '倉庫予備7';
COMMENT ON COLUMN xxcmn_item_locations_v.whse_spare8             IS '倉庫予備8';
COMMENT ON COLUMN xxcmn_item_locations_v.whse_spare9             IS '倉庫予備9';
COMMENT ON COLUMN xxcmn_item_locations_v.location_id             IS '事業所ID';
COMMENT ON COLUMN xxcmn_item_locations_v.segment1                IS '保管倉庫コード';
COMMENT ON COLUMN xxcmn_item_locations_v.description             IS '保管倉庫名';
COMMENT ON COLUMN xxcmn_item_locations_v.subinventory_code       IS '保管場所コード';
COMMENT ON COLUMN xxcmn_item_locations_v.eos_control_type        IS 'ＥＯＳ管理区分';
COMMENT ON COLUMN xxcmn_item_locations_v.eos_detination          IS 'ＥＯＳ宛先';
COMMENT ON COLUMN xxcmn_item_locations_v.whse_department         IS '倉庫管理部署';
COMMENT ON COLUMN xxcmn_item_locations_v.allow_pickup_flag       IS '出荷引当対象フラグ';
COMMENT ON COLUMN xxcmn_item_locations_v.frequent_whse           IS '代表倉庫';
COMMENT ON COLUMN xxcmn_item_locations_v.distribution_block      IS '物流ブロック';
COMMENT ON COLUMN xxcmn_item_locations_v.frequent_mover          IS '代表運送会社';
COMMENT ON COLUMN xxcmn_item_locations_v.frequent_whse_code      IS '主要保管倉庫コード';
COMMENT ON COLUMN xxcmn_item_locations_v.whse_inside_outside_div IS '内外倉庫区分';
COMMENT ON COLUMN xxcmn_item_locations_v.drink_calender          IS 'ドリンク基準カレンダ';
COMMENT ON COLUMN xxcmn_item_locations_v.d1_whse_code            IS 'Ｄ＋１倉庫フラグ';
COMMENT ON COLUMN xxcmn_item_locations_v.short_name              IS '略称';
COMMENT ON COLUMN xxcmn_item_locations_v.purchase_code           IS '仕入先コード';
COMMENT ON COLUMN xxcmn_item_locations_v.leaf_calender           IS 'リーフ基準カレンダ';
COMMENT ON COLUMN xxcmn_item_locations_v.direct_ship_type        IS '直送倉庫区分';
COMMENT ON COLUMN xxcmn_item_locations_v.purchase_site_code      IS '仕入先サイトコード';
--
COMMENT ON TABLE  xxcmn_item_locations_v IS 'OPM保管場所情報VIEW';
