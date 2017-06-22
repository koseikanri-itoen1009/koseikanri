CREATE OR REPLACE VIEW xxcmn_item_mst2_v
(
  item_id,
  item_no,
  item_desc1,
  item_um,
  lot_ctl,
  shelf_life,
  inactive_ind,
  old_crowd_code,
  new_crowd_code,
  crowd_start_date,
  old_price,
  new_price,
  price_start_date,
  old_operating_cost,
  new_operating_cost,
  operating_start_date,
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
  obsolete_class,
  obsolete_date,
  model_type,
  product_class,
  product_type,
  expiration_day,
-- Ver.1.1 E_本稼動_14244 Add Start
  expiration_month,
  expiration_type,
-- Ver.1.1 E_本稼動_14244 Add End
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
)
AS
  SELECT  iimb.item_id,
          iimb.item_no,
          iimb.item_desc1,
          iimb.item_um,
          iimb.lot_ctl,
          iimb.shelf_life,
          iimb.inactive_ind,
          iimb.attribute1,
          iimb.attribute2,
          iimb.attribute3,
          iimb.attribute4,
          iimb.attribute5,
          iimb.attribute6,
          iimb.attribute7,
          iimb.attribute8,
          iimb.attribute9,
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
          ximb.obsolete_class,
          ximb.obsolete_date,
          ximb.model_type,
          ximb.product_class,
          ximb.product_type,
          ximb.expiration_day,
-- Ver.1.1 E_本稼動_14244 Add Start
          ximb.expiration_month,
          ximb.expiration_type,
-- Ver.1.1 E_本稼動_14244 Add End
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
  FROM    ic_item_mst_b      iimb,
          xxcmn_item_mst_b   ximb,
          mtl_system_items_b msib
  WHERE   iimb.item_id            = ximb.item_id
  AND     msib.organization_id    = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
  AND     iimb.item_no            = msib.segment1
;
--
COMMENT ON COLUMN xxcmn_item_mst2_v.item_id                   IS '品目ID';
COMMENT ON COLUMN xxcmn_item_mst2_v.item_no                   IS '品目コード';
COMMENT ON COLUMN xxcmn_item_mst2_v.item_desc1                IS '摘要';
COMMENT ON COLUMN xxcmn_item_mst2_v.item_um                   IS '単位';
COMMENT ON COLUMN xxcmn_item_mst2_v.lot_ctl                   IS 'ロット';
COMMENT ON COLUMN xxcmn_item_mst2_v.shelf_life                IS '保存期間';
COMMENT ON COLUMN xxcmn_item_mst2_v.inactive_ind              IS '無効フラグ';
COMMENT ON COLUMN xxcmn_item_mst2_v.old_crowd_code            IS '旧・群コード';
COMMENT ON COLUMN xxcmn_item_mst2_v.new_crowd_code            IS '新・群コード';
COMMENT ON COLUMN xxcmn_item_mst2_v.crowd_start_date          IS '群コード適用開始日';
COMMENT ON COLUMN xxcmn_item_mst2_v.old_price                 IS '旧・定価';
COMMENT ON COLUMN xxcmn_item_mst2_v.new_price                 IS '新・定価';
COMMENT ON COLUMN xxcmn_item_mst2_v.price_start_date          IS '定価適用開始日';
COMMENT ON COLUMN xxcmn_item_mst2_v.old_operating_cost        IS '旧・営業原価';
COMMENT ON COLUMN xxcmn_item_mst2_v.new_operating_cost        IS '新・営業原価';
COMMENT ON COLUMN xxcmn_item_mst2_v.operating_start_date      IS '営業原価適用開始日';
COMMENT ON COLUMN xxcmn_item_mst2_v.weight_capacity_class     IS '重量容積区分';
COMMENT ON COLUMN xxcmn_item_mst2_v.num_of_cases              IS 'ケース入数';
COMMENT ON COLUMN xxcmn_item_mst2_v.net                       IS 'NET';
COMMENT ON COLUMN xxcmn_item_mst2_v.sell_start_date           IS '発売（製造）開始日';
COMMENT ON COLUMN xxcmn_item_mst2_v.inspect_lot               IS '検査L/T';
COMMENT ON COLUMN xxcmn_item_mst2_v.cost_manage_code          IS '原価管理区分';
COMMENT ON COLUMN xxcmn_item_mst2_v.capacity                  IS '容積';
COMMENT ON COLUMN xxcmn_item_mst2_v.frequent_qty              IS '代表入数';
COMMENT ON COLUMN xxcmn_item_mst2_v.ship_class                IS '出荷区分';
COMMENT ON COLUMN xxcmn_item_mst2_v.max_palette_steps         IS 'パレット当り最大段数';
COMMENT ON COLUMN xxcmn_item_mst2_v.unit_price_calc_code      IS '仕入単価導出日タイプ';
COMMENT ON COLUMN xxcmn_item_mst2_v.jan_code                  IS 'JANコード';
COMMENT ON COLUMN xxcmn_item_mst2_v.itf_code                  IS 'ITFコード';
COMMENT ON COLUMN xxcmn_item_mst2_v.test_code                 IS '試験有無区分';
COMMENT ON COLUMN xxcmn_item_mst2_v.conv_unit                 IS '入出庫換算単位';
COMMENT ON COLUMN xxcmn_item_mst2_v.unit                      IS '重量';
COMMENT ON COLUMN xxcmn_item_mst2_v.sales_div                 IS '売上対象区分';
COMMENT ON COLUMN xxcmn_item_mst2_v.judge_times               IS '判定回数';
COMMENT ON COLUMN xxcmn_item_mst2_v.destination_div           IS '仕向区分';
COMMENT ON COLUMN xxcmn_item_mst2_v.order_judge_times         IS '発注可能判定回数';
COMMENT ON COLUMN xxcmn_item_mst2_v.recept_date               IS 'マスタ受信日時';
COMMENT ON COLUMN xxcmn_item_mst2_v.whse_item_id              IS '倉庫品目';
COMMENT ON COLUMN xxcmn_item_mst2_v.inventory_item_id         IS 'INV品目ID';
COMMENT ON COLUMN xxcmn_item_mst2_v.start_date_active         IS '適用開始日';
COMMENT ON COLUMN xxcmn_item_mst2_v.end_date_active           IS '適用終了日';
COMMENT ON COLUMN xxcmn_item_mst2_v.active_flag               IS '適用済フラグ';
COMMENT ON COLUMN xxcmn_item_mst2_v.item_name                 IS '品名・正式名';
COMMENT ON COLUMN xxcmn_item_mst2_v.item_short_name           IS '品名・略称';
COMMENT ON COLUMN xxcmn_item_mst2_v.item_name_alt             IS '品名・カナ';
COMMENT ON COLUMN xxcmn_item_mst2_v.parent_item_id            IS '親品目ID';
COMMENT ON COLUMN xxcmn_item_mst2_v.obsolete_class            IS '廃止区分';
COMMENT ON COLUMN xxcmn_item_mst2_v.obsolete_date             IS '廃止日（製造中止日）';
COMMENT ON COLUMN xxcmn_item_mst2_v.model_type                IS '型種別';
COMMENT ON COLUMN xxcmn_item_mst2_v.product_class             IS '商品分類';
COMMENT ON COLUMN xxcmn_item_mst2_v.product_type              IS '商品種別';
COMMENT ON COLUMN xxcmn_item_mst2_v.expiration_day            IS '賞味期間';
-- Ver.1.1 E_本稼動_14244 Add Start
COMMENT ON COLUMN xxcmn_item_mst2_v.expiration_month          IS '賞味期間（月）';
COMMENT ON COLUMN xxcmn_item_mst2_v.expiration_type           IS '表示区分';
-- Ver.1.1 E_本稼動_14244 Add End
COMMENT ON COLUMN xxcmn_item_mst2_v.delivery_lead_time        IS '納入期間';
COMMENT ON COLUMN xxcmn_item_mst2_v.whse_county_code          IS '工場群コード';
COMMENT ON COLUMN xxcmn_item_mst2_v.standard_yield            IS '標準歩留';
COMMENT ON COLUMN xxcmn_item_mst2_v.shipping_end_date         IS '出荷停止日';
COMMENT ON COLUMN xxcmn_item_mst2_v.rate_class                IS '率区分';
COMMENT ON COLUMN xxcmn_item_mst2_v.shelf_life                IS '消費期間';
COMMENT ON COLUMN xxcmn_item_mst2_v.shelf_life_class          IS '賞味期間区分';
COMMENT ON COLUMN xxcmn_item_mst2_v.bottle_class              IS '容器区分';
COMMENT ON COLUMN xxcmn_item_mst2_v.uom_class                 IS '単位区分';
COMMENT ON COLUMN xxcmn_item_mst2_v.inventory_chk_class       IS '棚卸区分';
COMMENT ON COLUMN xxcmn_item_mst2_v.trace_class               IS 'トレース区分';
COMMENT ON COLUMN xxcmn_item_mst2_v.num_of_deliver            IS '出荷入数';
COMMENT ON COLUMN xxcmn_item_mst2_v.delivery_qty              IS '配数';
COMMENT ON COLUMN xxcmn_item_mst2_v.palette_max_step_qty      IS 'パレット当り最大段数';
COMMENT ON COLUMN xxcmn_item_mst2_v.palette_step_qty          IS 'パレット段';
COMMENT ON COLUMN xxcmn_item_mst2_v.cs_weigth_or_capacity     IS 'ケース重量容積';
COMMENT ON COLUMN xxcmn_item_mst2_v.raw_material_consumption  IS '原料使用量';
COMMENT ON COLUMN xxcmn_item_mst2_v.attribute1                IS '予備１';
COMMENT ON COLUMN xxcmn_item_mst2_v.attribute2                IS '予備２';
COMMENT ON COLUMN xxcmn_item_mst2_v.attribute3                IS '予備３';
COMMENT ON COLUMN xxcmn_item_mst2_v.attribute4                IS '予備４';
COMMENT ON COLUMN xxcmn_item_mst2_v.attribute5                IS '予備５';
--
COMMENT ON TABLE  xxcmn_item_mst2_v IS 'OPM品目情報VIEW2';
