CREATE OR REPLACE VIEW xxwsh_ship_method2_v
(
  ship_method_code,
  ship_method_meaning,
  description,
  start_date_active,
  end_date_active,
  security_group_id,
  view_application_id,
  attribute_category,
  drink_deadweight,
  leaf_deadweight,
  drink_loading_capacity,
  leaf_loading_capacity,
  penalty_class,
  small_amount_class,
  auto_process_type,
  tariff_class,
  mixed_class,
  mixed_ship_method_code,
  max_case_quantity,
  max_pallet_quantity
)
AS
  SELECT  lookup_code,
          meaning,
          description,
          start_date_active,
          end_date_active,
          security_group_id,
          view_application_id,
          attribute_category,
          attribute1,
          attribute2,
          attribute3,
          attribute4,
          attribute5,
          attribute6,
          attribute7,
          attribute8,
          attribute9,
          attribute10,
          attribute11,
          attribute12
  FROM    fnd_lookup_values  flv
  WHERE   flv.language       = 'JA'
  AND     flv.source_lang    = 'JA'
  AND     flv.lookup_type    = 'XXCMN_SHIP_METHOD'
;
--
COMMENT ON COLUMN xxwsh_ship_method2_v.ship_method_code          IS '配送区分コード';
COMMENT ON COLUMN xxwsh_ship_method2_v.ship_method_meaning       IS '配送区分';
COMMENT ON COLUMN xxwsh_ship_method2_v.description               IS '摘要';
COMMENT ON COLUMN xxwsh_ship_method2_v.start_date_active         IS '有効開始日';
COMMENT ON COLUMN xxwsh_ship_method2_v.end_date_active           IS '有効終了日';
COMMENT ON COLUMN xxwsh_ship_method2_v.security_group_id         IS 'セキュリティグループID';
COMMENT ON COLUMN xxwsh_ship_method2_v.view_application_id       IS 'ビューアプリケーションID';
COMMENT ON COLUMN xxwsh_ship_method2_v.attribute_category        IS 'コンテキスト';
COMMENT ON COLUMN xxwsh_ship_method2_v.drink_deadweight          IS 'ドリンク積載重量';
COMMENT ON COLUMN xxwsh_ship_method2_v.leaf_deadweight           IS 'ドリンク積載容積';
COMMENT ON COLUMN xxwsh_ship_method2_v.drink_loading_capacity    IS 'リーフ積載重量';
COMMENT ON COLUMN xxwsh_ship_method2_v.leaf_loading_capacity     IS 'リーフ積載容積';
COMMENT ON COLUMN xxwsh_ship_method2_v.penalty_class             IS 'ペナルティ区分(生産)';
COMMENT ON COLUMN xxwsh_ship_method2_v.small_amount_class        IS '小口区分';
COMMENT ON COLUMN xxwsh_ship_method2_v.auto_process_type         IS '自動配車対象区分';
COMMENT ON COLUMN xxwsh_ship_method2_v.tariff_class              IS 'タリフ区分';
COMMENT ON COLUMN xxwsh_ship_method2_v.mixed_class               IS '混載区分';
COMMENT ON COLUMN xxwsh_ship_method2_v.mixed_ship_method_code    IS '混載配送区分コード';
COMMENT ON COLUMN xxwsh_ship_method2_v.max_case_quantity         IS '最大ケース数';
COMMENT ON COLUMN xxwsh_ship_method2_v.max_pallet_quantity       IS 'パレット最大枚数';
--                                    
COMMENT ON TABLE  xxwsh_ship_method2_v IS '配送区分情報VIEW2';
