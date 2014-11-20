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
COMMENT ON COLUMN xxcmn_item_mst2_v.item_id                   IS '�i��ID';
COMMENT ON COLUMN xxcmn_item_mst2_v.item_no                   IS '�i�ڃR�[�h';
COMMENT ON COLUMN xxcmn_item_mst2_v.item_desc1                IS '�E�v';
COMMENT ON COLUMN xxcmn_item_mst2_v.item_um                   IS '�P��';
COMMENT ON COLUMN xxcmn_item_mst2_v.lot_ctl                   IS '���b�g';
COMMENT ON COLUMN xxcmn_item_mst2_v.shelf_life                IS '�ۑ�����';
COMMENT ON COLUMN xxcmn_item_mst2_v.inactive_ind              IS '�����t���O';
COMMENT ON COLUMN xxcmn_item_mst2_v.old_crowd_code            IS '���E�Q�R�[�h';
COMMENT ON COLUMN xxcmn_item_mst2_v.new_crowd_code            IS '�V�E�Q�R�[�h';
COMMENT ON COLUMN xxcmn_item_mst2_v.crowd_start_date          IS '�Q�R�[�h�K�p�J�n��';
COMMENT ON COLUMN xxcmn_item_mst2_v.old_price                 IS '���E�艿';
COMMENT ON COLUMN xxcmn_item_mst2_v.new_price                 IS '�V�E�艿';
COMMENT ON COLUMN xxcmn_item_mst2_v.price_start_date          IS '�艿�K�p�J�n��';
COMMENT ON COLUMN xxcmn_item_mst2_v.old_operating_cost        IS '���E�c�ƌ���';
COMMENT ON COLUMN xxcmn_item_mst2_v.new_operating_cost        IS '�V�E�c�ƌ���';
COMMENT ON COLUMN xxcmn_item_mst2_v.operating_start_date      IS '�c�ƌ����K�p�J�n��';
COMMENT ON COLUMN xxcmn_item_mst2_v.weight_capacity_class     IS '�d�ʗe�ϋ敪';
COMMENT ON COLUMN xxcmn_item_mst2_v.num_of_cases              IS '�P�[�X����';
COMMENT ON COLUMN xxcmn_item_mst2_v.net                       IS 'NET';
COMMENT ON COLUMN xxcmn_item_mst2_v.sell_start_date           IS '�����i�����j�J�n��';
COMMENT ON COLUMN xxcmn_item_mst2_v.inspect_lot               IS '����L/T';
COMMENT ON COLUMN xxcmn_item_mst2_v.cost_manage_code          IS '�����Ǘ��敪';
COMMENT ON COLUMN xxcmn_item_mst2_v.capacity                  IS '�e��';
COMMENT ON COLUMN xxcmn_item_mst2_v.frequent_qty              IS '��\����';
COMMENT ON COLUMN xxcmn_item_mst2_v.ship_class                IS '�o�׋敪';
COMMENT ON COLUMN xxcmn_item_mst2_v.max_palette_steps         IS '�p���b�g����ő�i��';
COMMENT ON COLUMN xxcmn_item_mst2_v.unit_price_calc_code      IS '�d���P�����o���^�C�v';
COMMENT ON COLUMN xxcmn_item_mst2_v.jan_code                  IS 'JAN�R�[�h';
COMMENT ON COLUMN xxcmn_item_mst2_v.itf_code                  IS 'ITF�R�[�h';
COMMENT ON COLUMN xxcmn_item_mst2_v.test_code                 IS '�����L���敪';
COMMENT ON COLUMN xxcmn_item_mst2_v.conv_unit                 IS '���o�Ɋ��Z�P��';
COMMENT ON COLUMN xxcmn_item_mst2_v.unit                      IS '�d��';
COMMENT ON COLUMN xxcmn_item_mst2_v.sales_div                 IS '����Ώۋ敪';
COMMENT ON COLUMN xxcmn_item_mst2_v.judge_times               IS '�����';
COMMENT ON COLUMN xxcmn_item_mst2_v.destination_div           IS '�d���敪';
COMMENT ON COLUMN xxcmn_item_mst2_v.order_judge_times         IS '�����\�����';
COMMENT ON COLUMN xxcmn_item_mst2_v.recept_date               IS '�}�X�^��M����';
COMMENT ON COLUMN xxcmn_item_mst2_v.whse_item_id              IS '�q�ɕi��';
COMMENT ON COLUMN xxcmn_item_mst2_v.inventory_item_id         IS 'INV�i��ID';
COMMENT ON COLUMN xxcmn_item_mst2_v.start_date_active         IS '�K�p�J�n��';
COMMENT ON COLUMN xxcmn_item_mst2_v.end_date_active           IS '�K�p�I����';
COMMENT ON COLUMN xxcmn_item_mst2_v.active_flag               IS '�K�p�σt���O';
COMMENT ON COLUMN xxcmn_item_mst2_v.item_name                 IS '�i���E������';
COMMENT ON COLUMN xxcmn_item_mst2_v.item_short_name           IS '�i���E����';
COMMENT ON COLUMN xxcmn_item_mst2_v.item_name_alt             IS '�i���E�J�i';
COMMENT ON COLUMN xxcmn_item_mst2_v.parent_item_id            IS '�e�i��ID';
COMMENT ON COLUMN xxcmn_item_mst2_v.obsolete_class            IS '�p�~�敪';
COMMENT ON COLUMN xxcmn_item_mst2_v.obsolete_date             IS '�p�~���i�������~���j';
COMMENT ON COLUMN xxcmn_item_mst2_v.model_type                IS '�^���';
COMMENT ON COLUMN xxcmn_item_mst2_v.product_class             IS '���i����';
COMMENT ON COLUMN xxcmn_item_mst2_v.product_type              IS '���i���';
COMMENT ON COLUMN xxcmn_item_mst2_v.expiration_day            IS '�ܖ�����';
COMMENT ON COLUMN xxcmn_item_mst2_v.delivery_lead_time        IS '�[������';
COMMENT ON COLUMN xxcmn_item_mst2_v.whse_county_code          IS '�H��Q�R�[�h';
COMMENT ON COLUMN xxcmn_item_mst2_v.standard_yield            IS '�W������';
COMMENT ON COLUMN xxcmn_item_mst2_v.shipping_end_date         IS '�o�ג�~��';
COMMENT ON COLUMN xxcmn_item_mst2_v.rate_class                IS '���敪';
COMMENT ON COLUMN xxcmn_item_mst2_v.shelf_life                IS '�������';
COMMENT ON COLUMN xxcmn_item_mst2_v.shelf_life_class          IS '�ܖ����ԋ敪';
COMMENT ON COLUMN xxcmn_item_mst2_v.bottle_class              IS '�e��敪';
COMMENT ON COLUMN xxcmn_item_mst2_v.uom_class                 IS '�P�ʋ敪';
COMMENT ON COLUMN xxcmn_item_mst2_v.inventory_chk_class       IS '�I���敪';
COMMENT ON COLUMN xxcmn_item_mst2_v.trace_class               IS '�g���[�X�敪';
COMMENT ON COLUMN xxcmn_item_mst2_v.num_of_deliver            IS '�o�ד���';
COMMENT ON COLUMN xxcmn_item_mst2_v.delivery_qty              IS '�z��';
COMMENT ON COLUMN xxcmn_item_mst2_v.palette_max_step_qty      IS '�p���b�g����ő�i��';
COMMENT ON COLUMN xxcmn_item_mst2_v.palette_step_qty          IS '�p���b�g�i';
COMMENT ON COLUMN xxcmn_item_mst2_v.cs_weigth_or_capacity     IS '�P�[�X�d�ʗe��';
COMMENT ON COLUMN xxcmn_item_mst2_v.raw_material_consumption  IS '�����g�p��';
COMMENT ON COLUMN xxcmn_item_mst2_v.attribute1                IS '�\���P';
COMMENT ON COLUMN xxcmn_item_mst2_v.attribute2                IS '�\���Q';
COMMENT ON COLUMN xxcmn_item_mst2_v.attribute3                IS '�\���R';
COMMENT ON COLUMN xxcmn_item_mst2_v.attribute4                IS '�\���S';
COMMENT ON COLUMN xxcmn_item_mst2_v.attribute5                IS '�\���T';
--
COMMENT ON TABLE  xxcmn_item_mst2_v IS 'OPM�i�ڏ��VIEW2';
