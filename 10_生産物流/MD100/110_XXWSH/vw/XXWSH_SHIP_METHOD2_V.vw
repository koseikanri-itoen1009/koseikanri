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
COMMENT ON COLUMN xxwsh_ship_method2_v.ship_method_code          IS '�z���敪�R�[�h';
COMMENT ON COLUMN xxwsh_ship_method2_v.ship_method_meaning       IS '�z���敪';
COMMENT ON COLUMN xxwsh_ship_method2_v.description               IS '�E�v';
COMMENT ON COLUMN xxwsh_ship_method2_v.start_date_active         IS '�L���J�n��';
COMMENT ON COLUMN xxwsh_ship_method2_v.end_date_active           IS '�L���I����';
COMMENT ON COLUMN xxwsh_ship_method2_v.security_group_id         IS '�Z�L�����e�B�O���[�vID';
COMMENT ON COLUMN xxwsh_ship_method2_v.view_application_id       IS '�r���[�A�v���P�[�V����ID';
COMMENT ON COLUMN xxwsh_ship_method2_v.attribute_category        IS '�R���e�L�X�g';
COMMENT ON COLUMN xxwsh_ship_method2_v.drink_deadweight          IS '�h�����N�ύڏd��';
COMMENT ON COLUMN xxwsh_ship_method2_v.leaf_deadweight           IS '�h�����N�ύڗe��';
COMMENT ON COLUMN xxwsh_ship_method2_v.drink_loading_capacity    IS '���[�t�ύڏd��';
COMMENT ON COLUMN xxwsh_ship_method2_v.leaf_loading_capacity     IS '���[�t�ύڗe��';
COMMENT ON COLUMN xxwsh_ship_method2_v.penalty_class             IS '�y�i���e�B�敪(���Y)';
COMMENT ON COLUMN xxwsh_ship_method2_v.small_amount_class        IS '�����敪';
COMMENT ON COLUMN xxwsh_ship_method2_v.auto_process_type         IS '�����z�ԑΏۋ敪';
COMMENT ON COLUMN xxwsh_ship_method2_v.tariff_class              IS '�^���t�敪';
COMMENT ON COLUMN xxwsh_ship_method2_v.mixed_class               IS '���ڋ敪';
COMMENT ON COLUMN xxwsh_ship_method2_v.mixed_ship_method_code    IS '���ڔz���敪�R�[�h';
COMMENT ON COLUMN xxwsh_ship_method2_v.max_case_quantity         IS '�ő�P�[�X��';
COMMENT ON COLUMN xxwsh_ship_method2_v.max_pallet_quantity       IS '�p���b�g�ő喇��';
--                                    
COMMENT ON TABLE  xxwsh_ship_method2_v IS '�z���敪���VIEW2';
