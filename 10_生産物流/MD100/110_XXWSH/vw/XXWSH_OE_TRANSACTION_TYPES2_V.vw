/***********************************************************************************/
/* �󒍃^�C�v���View2                                                             */
/*   Create:2008/02/21                                                             */
/*   Update:2008/04/10 �U�֋敪�A�i�ڋ敪��ǉ�                                    */
/***********************************************************************************/
CREATE OR REPLACE VIEW xxwsh_oe_transaction_types2_v
(
  transaction_type_id,
  transaction_type_name,
  description,
  transaction_type_code,
  order_category_code,
  start_date_active,
  end_date_active,
  org_id,
  price_list_id,
  default_inbound_line_type_id,
  default_outbound_line_type_id,
  shipping_shikyu_class,
  shipping_class,
  auto_create_po_class,
  adjs_class,
  cancel_order_type,
  transfer_class,
  item_class,
  ship_sikyu_rcv_pay_ctg,
  used_disp_flg
)
AS
  SELECT  otta.transaction_type_id,
          ottt.name,
          ottt.description,
          otta.transaction_type_code,
          otta.order_category_code,
          otta.start_date_active,
          otta.end_date_active,
          otta.org_id,
          otta.price_list_id,
          otta.default_inbound_line_type_id,
          otta.default_outbound_line_type_id,
          otta.attribute1,
          otta.attribute2,
          otta.attribute3,
          otta.attribute4,
          otta.attribute5,
          otta.attribute6,
          otta.attribute7,
          otta.attribute11,
          otta.attribute12
  FROM    oe_transaction_types_all  otta,
          oe_transaction_types_tl   ottt
  WHERE   ottt.transaction_type_id                                  = otta.transaction_type_id
  AND     otta.org_id                                               = FND_PROFILE.VALUE('org_id')
  AND     ottt.language                                             = USERENV('lang')
;
--
COMMENT ON COLUMN xxwsh_oe_transaction_types2_v.transaction_type_id            IS '����^�C�vID';
COMMENT ON COLUMN xxwsh_oe_transaction_types2_v.transaction_type_name          IS '����^�C�v��';
COMMENT ON COLUMN xxwsh_oe_transaction_types2_v.description                    IS '�E�v';
COMMENT ON COLUMN xxwsh_oe_transaction_types2_v.transaction_type_code          IS '����^�C�v�R�[�h';
COMMENT ON COLUMN xxwsh_oe_transaction_types2_v.order_category_code            IS '�󒍃J�e�S���R�[�h';
COMMENT ON COLUMN xxwsh_oe_transaction_types2_v.start_date_active              IS '�L���J�n��';
COMMENT ON COLUMN xxwsh_oe_transaction_types2_v.end_date_active                IS '�L���I����';
COMMENT ON COLUMN xxwsh_oe_transaction_types2_v.org_id                         IS '�c�ƒP��ID';
COMMENT ON COLUMN xxwsh_oe_transaction_types2_v.price_list_id                  IS '���i�\ID';
COMMENT ON COLUMN xxwsh_oe_transaction_types2_v.default_inbound_line_type_id   IS '�f�t�H���g�ԕi���׃^�C�vID';
COMMENT ON COLUMN xxwsh_oe_transaction_types2_v.default_outbound_line_type_id  IS '�f�t�H���g�󒍖��׃^�C�vID';
COMMENT ON COLUMN xxwsh_oe_transaction_types2_v.shipping_shikyu_class          IS '�o�׎x���敪';
COMMENT ON COLUMN xxwsh_oe_transaction_types2_v.shipping_class                 IS '�o�׋敪����';
COMMENT ON COLUMN xxwsh_oe_transaction_types2_v.auto_create_po_class           IS '���������쐬�敪';
COMMENT ON COLUMN xxwsh_oe_transaction_types2_v.adjs_class                     IS '�݌ɒ����敪';
COMMENT ON COLUMN xxwsh_oe_transaction_types2_v.cancel_order_type              IS '����󒍃^�C�v';
COMMENT ON COLUMN xxwsh_oe_transaction_types2_v.transfer_class                 IS '�U�֋敪';
COMMENT ON COLUMN xxwsh_oe_transaction_types2_v.item_class                     IS '�i�ڋ敪';
COMMENT ON COLUMN xxwsh_oe_transaction_types2_v.ship_sikyu_rcv_pay_ctg         IS '�o�׎x���󕥃J�e�S��';
COMMENT ON COLUMN xxwsh_oe_transaction_types2_v.used_disp_flg                  IS '��ʎg�p�t���O';
--
COMMENT ON TABLE  xxwsh_oe_transaction_types2_v IS '�󒍃^�C�v���VIEW2';