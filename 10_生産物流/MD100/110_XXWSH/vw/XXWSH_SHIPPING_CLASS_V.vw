CREATE OR REPLACE VIEW xxwsh_shipping_class_v
(
  shipping_class_code,
  shipping_class_meaning,
  description,
  start_date_active,
  end_date_active,
  security_group_id,
  view_application_id,
  attribute_category,
  invoice_class_1,
  request_class,
  send_data_type,
  customer_class,
  order_transaction_type_name,
  request_class_name
)
AS
  SELECT  flv.lookup_code,
          flv.meaning,
          flv.description,
          flv.start_date_active,
          flv.end_date_active,
          flv.security_group_id,
          flv.view_application_id,
          flv.attribute_category,
          flv.attribute1,
          flv.attribute2,
          flv.attribute3,
          flv.attribute4,
          flv.attribute5,
          flv.attribute6
  FROM    fnd_lookup_values flv
  WHERE   (
            (flv.start_date_active <= TRUNC(SYSDATE))
             OR
            (flv.start_date_active IS NULL )
          )
  AND     (
            (flv.end_date_active   >= TRUNC(SYSDATE))
             OR
            (flv.end_date_active IS NULL)
          )
  AND     flv.enabled_flag = 'Y'
  AND     flv.language     = 'JA'
  AND     flv.source_lang  = 'JA'
  AND     flv.lookup_type = 'XXWSH_SHIPPING_CLASS'
;
--
COMMENT ON COLUMN xxwsh_shipping_class_v.shipping_class_code          IS '�o�׋敪�R�[�h';
COMMENT ON COLUMN xxwsh_shipping_class_v.shipping_class_meaning       IS '�o�׋敪';
COMMENT ON COLUMN xxwsh_shipping_class_v.description                  IS '�E�v';
COMMENT ON COLUMN xxwsh_shipping_class_v.start_date_active            IS '�L���J�n��';
COMMENT ON COLUMN xxwsh_shipping_class_v.end_date_active              IS '�L���I����';
COMMENT ON COLUMN xxwsh_shipping_class_v.security_group_id            IS '�Z�L�����e�B�O���[�vID';
COMMENT ON COLUMN xxwsh_shipping_class_v.view_application_id          IS '�r���[�A�v���P�[�V����ID';
COMMENT ON COLUMN xxwsh_shipping_class_v.attribute_category           IS '�R���e�L�X�g';
COMMENT ON COLUMN xxwsh_shipping_class_v.invoice_class_1              IS '�`��1';
COMMENT ON COLUMN xxwsh_shipping_class_v.request_class                IS '�˗��敪';
COMMENT ON COLUMN xxwsh_shipping_class_v.send_data_type               IS '�f�[�^���(���M)';
COMMENT ON COLUMN xxwsh_shipping_class_v.customer_class               IS '�ڋq�敪';
COMMENT ON COLUMN xxwsh_shipping_class_v.order_transaction_type_name  IS '�󒍃^�C�v';
COMMENT ON COLUMN xxwsh_shipping_class_v.request_class_name           IS '�˗��敪����';
--
COMMENT ON TABLE  xxwsh_shipping_class_v IS '�o�׋敪���VIEW';
