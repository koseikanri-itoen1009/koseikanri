CREATE OR REPLACE VIEW xxcmn_item_mst_v
(
  item_id,
  item_no,
  item_desc1,
  item_um,
  lot_ctl,
  shelf_life,
  crowd_code,
  price,
  operating_cost,
  weight_capacity_class,
  num_of_cases,
  net,
  sell_start_date,
  inspect_lot,
  cost_manage_code,
  capacity,
  frequent_qty,
  ship_class,
  max_palette_steps,
  unit_price_calc_code,
  jan_code,
  itf_code,
  test_code,
  conv_unit,
  unit,
  sales_div,
  judge_times,
  destination_div,
  order_judge_times,
  recept_date,
  whse_item_id,
  inventory_item_id,
  start_date_active,
  end_date_active,
  active_flag,
  item_name,
  item_short_name,
  item_name_alt,
  parent_item_id,
  obsolete_date,
  model_type,
  product_class,
  product_type,
  expiration_day,
  delivery_lead_time,
  whse_county_code,
  standard_yield,
  shipping_end_date,
  rate_class,
  life,
  shelf_life_class,
  bottle_class,
  uom_class,
  inventory_chk_class,
  trace_class,
  num_of_deliver,
  delivery_qty,
  palette_max_step_qty,
  palette_step_qty,
  cs_weigth_or_capacity,
  raw_material_consumption,
  attribute1,
  attribute2,
  attribute3,
  attribute4,
  attribute5
-- E_{Ò®_16213 V1.1 Y.Sasaki Add Start
 ,origin_restriction
 ,tea_period_restriction
 ,product_year
 ,organic
-- E_{Ò®_16213 V1.1 Y.Sasaki Add End
)
AS
  SELECT  Iimb.item_id,
          iimb.item_no,
          iimb.item_desc1,
          iimb.item_um,
          iimb.lot_ctl,
          iimb.shelf_life,
          CASE
            WHEN iimb.attribute3 <= TO_CHAR(SYSDATE,'YYYYMMDD')
              THEN iimb.attribute2
              ELSE iimb.attribute1
          END,
          CASE
            WHEN iimb.attribute6 <= TO_CHAR(SYSDATE,'YYYYMMDD')
              THEN iimb.attribute5
              ELSE iimb.attribute4
          END,
          CASE
            WHEN iimb.attribute9 <= TO_CHAR(SYSDATE,'YYYYMMDD')
              THEN iimb.attribute8
              ELSE iimb.attribute7
          END,
          iimb.attribute10,
          iimb.attribute11,
          iimb.attribute12,
          iimb.attribute13,
          iimb.attribute14,
          iimb.attribute15,
          iimb.attribute16,
          iimb.attribute17,
          iimb.attribute18,
          TO_CHAR(ximb.palette_max_step_qty),
          iimb.attribute20,
          iimb.attribute21,
          iimb.attribute22,
          iimb.attribute23,
          iimb.attribute24,
          iimb.attribute25,
          iimb.attribute26,
          iimb.attribute27,
          iimb.attribute28,
          iimb.attribute29,
          iimb.attribute30,
          iimb.whse_item_id,
          msib.inventory_item_id,
          ximb.start_date_active,
          ximb.end_date_active,
          ximb.active_flag,
          ximb.item_name,
          ximb.item_short_name,
          ximb.item_name_alt,
          ximb.parent_item_id,
          ximb.obsolete_date,
          ximb.model_type,
          ximb.product_class,
          ximb.product_type,
          ximb.expiration_day,
          ximb.delivery_lead_time,
          ximb.whse_county_code,
          ximb.standard_yield,
          ximb.shipping_end_date,
          ximb.rate_class,
          ximb.shelf_life,
          ximb.shelf_life_class,
          ximb.bottle_class,
          ximb.uom_class,
          ximb.inventory_chk_class,
          ximb.trace_class,
          ximb.shipping_cs_unit_qty,
          ximb.palette_max_cs_qty,
          ximb.palette_max_step_qty,
          ximb.palette_step_qty,
          ximb.cs_weigth_or_capacity,
          ximb.raw_material_consumption,
          ximb.attribute1,
          ximb.attribute2,
          ximb.attribute3,
          ximb.attribute4,
          ximb.attribute5
-- E_{Ò®_16213 V1.1 Y.Sasaki Add Start
        , ximb.origin_restriction
        , ximb.tea_period_restriction
        , ximb.product_year
        , ximb.organic
-- E_{Ò®_16213 V1.1 Y.Sasaki Add End
  FROM    ic_item_mst_b      iimb,
          xxcmn_item_mst_b   ximb,
          mtl_system_items_b msib
  WHERE   iimb.item_id            = ximb.item_id
  AND     iimb.inactive_ind       <> '1'
  AND     ximb.obsolete_class     <> '1'
  AND     msib.organization_id = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
  AND     iimb.item_no         = msib.segment1
  AND     ximb.start_date_active  <= TRUNC(SYSDATE)
  AND     ximb.end_date_active    >= TRUNC(SYSDATE)
;
--
COMMENT ON COLUMN xxcmn_item_mst_v.item_id                     IS 'iÚID';
COMMENT ON COLUMN xxcmn_item_mst_v.item_no                     IS 'iÚR[h';
COMMENT ON COLUMN xxcmn_item_mst_v.item_desc1                  IS 'Ev';
COMMENT ON COLUMN xxcmn_item_mst_v.item_um                     IS 'PÊ';
COMMENT ON COLUMN xxcmn_item_mst_v.lot_ctl                     IS 'bg';
COMMENT ON COLUMN xxcmn_item_mst_v.shelf_life                  IS 'Û¶úÔ';
COMMENT ON COLUMN xxcmn_item_mst_v.crowd_code                  IS 'QR[h';
COMMENT ON COLUMN xxcmn_item_mst_v.price                       IS 'è¿';
COMMENT ON COLUMN xxcmn_item_mst_v.operating_cost              IS 'cÆ´¿';
COMMENT ON COLUMN xxcmn_item_mst_v.weight_capacity_class       IS 'dÊeÏæª';
COMMENT ON COLUMN xxcmn_item_mst_v.num_of_cases                IS 'P[Xü';
COMMENT ON COLUMN xxcmn_item_mst_v.net                         IS 'NET';
COMMENT ON COLUMN xxcmn_item_mst_v.sell_start_date             IS '­i»¢jJnú';
COMMENT ON COLUMN xxcmn_item_mst_v.inspect_lot                 IS '¸L/T';
COMMENT ON COLUMN xxcmn_item_mst_v.cost_manage_code            IS '´¿Çæª';
COMMENT ON COLUMN xxcmn_item_mst_v.capacity                    IS 'eÏ';
COMMENT ON COLUMN xxcmn_item_mst_v.frequent_qty                IS 'ã\ü';
COMMENT ON COLUMN xxcmn_item_mst_v.ship_class                  IS 'o×æª';
COMMENT ON COLUMN xxcmn_item_mst_v.max_palette_steps           IS 'pbgèÅåi';
COMMENT ON COLUMN xxcmn_item_mst_v.unit_price_calc_code        IS 'düP¿±oú^Cv';
COMMENT ON COLUMN xxcmn_item_mst_v.jan_code                    IS 'JANR[h';
COMMENT ON COLUMN xxcmn_item_mst_v.itf_code                    IS 'ITFR[h';
COMMENT ON COLUMN xxcmn_item_mst_v.test_code                   IS '±L³æª';
COMMENT ON COLUMN xxcmn_item_mst_v.conv_unit                   IS 'üoÉ·ZPÊ';
COMMENT ON COLUMN xxcmn_item_mst_v.unit                        IS 'dÊ';
COMMENT ON COLUMN xxcmn_item_mst_v.sales_div                   IS 'ãÎÛæª';
COMMENT ON COLUMN xxcmn_item_mst_v.judge_times                 IS '»èñ';
COMMENT ON COLUMN xxcmn_item_mst_v.destination_div             IS 'düæª';
COMMENT ON COLUMN xxcmn_item_mst_v.order_judge_times           IS '­Â\»èñ';
COMMENT ON COLUMN xxcmn_item_mst_v.recept_date                 IS '}X^óMú';
COMMENT ON COLUMN xxcmn_item_mst_v.whse_item_id                IS 'qÉiÚ';
COMMENT ON COLUMN xxcmn_item_mst_v.inventory_item_id           IS 'INViÚID';
COMMENT ON COLUMN xxcmn_item_mst_v.start_date_active           IS 'KpJnú';
COMMENT ON COLUMN xxcmn_item_mst_v.end_date_active             IS 'KpI¹ú';
COMMENT ON COLUMN xxcmn_item_mst_v.active_flag                 IS 'KpÏtO';
COMMENT ON COLUMN xxcmn_item_mst_v.item_name                   IS 'i¼E³®¼';
COMMENT ON COLUMN xxcmn_item_mst_v.item_short_name             IS 'i¼EªÌ';
COMMENT ON COLUMN xxcmn_item_mst_v.item_name_alt               IS 'i¼EJi';
COMMENT ON COLUMN xxcmn_item_mst_v.parent_item_id              IS 'eiÚID';
COMMENT ON COLUMN xxcmn_item_mst_v.obsolete_date               IS 'p~úi»¢~új';
COMMENT ON COLUMN xxcmn_item_mst_v.model_type                  IS '^íÊ';
COMMENT ON COLUMN xxcmn_item_mst_v.product_class               IS '¤iªÞ';
COMMENT ON COLUMN xxcmn_item_mst_v.product_type                IS '¤iíÊ';
COMMENT ON COLUMN xxcmn_item_mst_v.expiration_day              IS 'Ü¡úÔ';
COMMENT ON COLUMN xxcmn_item_mst_v.delivery_lead_time          IS '[üúÔ';
COMMENT ON COLUMN xxcmn_item_mst_v.whse_county_code            IS 'HêQR[h';
COMMENT ON COLUMN xxcmn_item_mst_v.standard_yield              IS 'Wà¯';
COMMENT ON COLUMN xxcmn_item_mst_v.shipping_end_date           IS 'o×â~ú';
COMMENT ON COLUMN xxcmn_item_mst_v.rate_class                  IS '¦æª';
COMMENT ON COLUMN xxcmn_item_mst_v.shelf_life                  IS 'ÁïúÔ';
COMMENT ON COLUMN xxcmn_item_mst_v.shelf_life_class            IS 'Ü¡úÔæª';
COMMENT ON COLUMN xxcmn_item_mst_v.bottle_class                IS 'eíæª';
COMMENT ON COLUMN xxcmn_item_mst_v.uom_class                   IS 'PÊæª';
COMMENT ON COLUMN xxcmn_item_mst_v.inventory_chk_class         IS 'Iµæª';
COMMENT ON COLUMN xxcmn_item_mst_v.trace_class                 IS 'g[Xæª';
COMMENT ON COLUMN xxcmn_item_mst_v.num_of_deliver              IS 'o×ü';
COMMENT ON COLUMN xxcmn_item_mst_v.delivery_qty                IS 'z';
COMMENT ON COLUMN xxcmn_item_mst_v.palette_max_step_qty        IS 'pbgèÅåi';
COMMENT ON COLUMN xxcmn_item_mst_v.palette_step_qty            IS 'pbgi';
COMMENT ON COLUMN xxcmn_item_mst_v.cs_weigth_or_capacity       IS 'P[XdÊeÏ';
COMMENT ON COLUMN xxcmn_item_mst_v.raw_material_consumption    IS '´¿gpÊ';
COMMENT ON COLUMN xxcmn_item_mst_v.attribute1                  IS '\õP';
COMMENT ON COLUMN xxcmn_item_mst_v.attribute2                  IS '\õQ';
COMMENT ON COLUMN xxcmn_item_mst_v.attribute3                  IS '\õR';
COMMENT ON COLUMN xxcmn_item_mst_v.attribute4                  IS '\õS';
COMMENT ON COLUMN xxcmn_item_mst_v.attribute5                  IS '\õT';
-- E_{Ò®_16213 V1.1 Y.Sasaki Add Start
COMMENT ON COLUMN xxcmn_item_mst_v.origin_restriction          IS 'Yn§À';
COMMENT ON COLUMN xxcmn_item_mst_v.tea_period_restriction      IS 'ú§À';
COMMENT ON COLUMN xxcmn_item_mst_v.product_year                IS 'Nx';
COMMENT ON COLUMN xxcmn_item_mst_v.organic                     IS 'L@';
-- E_{Ò®_16213 V1.1 Y.Sasaki Add End
--
COMMENT ON TABLE  xxcmn_item_mst_v IS 'OPMiÚîñVIEW';
