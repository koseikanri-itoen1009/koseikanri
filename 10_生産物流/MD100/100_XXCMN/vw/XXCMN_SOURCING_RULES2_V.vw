CREATE OR REPLACE VIEW xxcmn_sourcing_rules2_v
(
  sourcing_rules_id,
  item_code,
  base_code,
  ship_to_code,
  start_date_active,
  end_date_active,
  delivery_whse_code,
  move_from_whse_code1,
  move_from_whse_code2,
  vendor_site_code1,
  vendor_site_code2,
  plan_item_flag
)
AS
  SELECT  xsr.sourcing_rules_id,
          xsr.item_code,
          xsr.base_code,
          xsr.ship_to_code,
          xsr.start_date_active,
          xsr.end_date_active,
          xsr.delivery_whse_code,
          xsr.move_from_whse_code1,
          xsr.move_from_whse_code2,
          xsr.vendor_site_code1,
          xsr.vendor_site_code2,
          xsr.plan_item_flag
  FROM    xxcmn_sourcing_rules  xsr
;
--
COMMENT ON COLUMN xxcmn_sourcing_rules2_v.sourcing_rules_id     IS '物流構成アドオンID';
COMMENT ON COLUMN xxcmn_sourcing_rules2_v.item_code             IS '品目コード';
COMMENT ON COLUMN xxcmn_sourcing_rules2_v.base_code             IS '拠点コード';
COMMENT ON COLUMN xxcmn_sourcing_rules2_v.ship_to_code          IS '配送先コード';
COMMENT ON COLUMN xxcmn_sourcing_rules2_v.start_date_active     IS '適用開始日';
COMMENT ON COLUMN xxcmn_sourcing_rules2_v.end_date_active       IS '適用終了日';
COMMENT ON COLUMN xxcmn_sourcing_rules2_v.delivery_whse_code    IS '出荷保管倉庫コード';
COMMENT ON COLUMN xxcmn_sourcing_rules2_v.move_from_whse_code1  IS '移動元保管倉庫コード1';
COMMENT ON COLUMN xxcmn_sourcing_rules2_v.move_from_whse_code2  IS '移動元保管倉庫コード2';
COMMENT ON COLUMN xxcmn_sourcing_rules2_v.vendor_site_code1     IS '仕入先サイトコード1';
COMMENT ON COLUMN xxcmn_sourcing_rules2_v.vendor_site_code2     IS '仕入先サイトコード2';
COMMENT ON COLUMN xxcmn_sourcing_rules2_v.plan_item_flag        IS '計画商品フラグ';
--
COMMENT ON TABLE  xxcmn_sourcing_rules2_v IS '物流構成情報VIEW';
