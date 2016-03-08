ALTER TABLE xxcso.xxcso_in_item_data ADD(
  lease_type         VARCHAR2(1),
  declaration_place  VARCHAR2(5),
  get_price          NUMBER(10)
);
--
COMMENT ON COLUMN xxcso.xxcso_in_item_data.lease_type         IS 'リース区分';
COMMENT ON COLUMN xxcso.xxcso_in_item_data.declaration_place  IS '申告地';
COMMENT ON COLUMN xxcso.xxcso_in_item_data.get_price          IS '取得価格';
