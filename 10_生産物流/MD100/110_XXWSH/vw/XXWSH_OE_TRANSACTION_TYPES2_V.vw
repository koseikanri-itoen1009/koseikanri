/***********************************************************************************/
/* 受注タイプ情報View2                                                             */
/*   Create:2008/02/21                                                             */
/*   Update:2008/04/10 振替区分、品目区分を追加                                    */
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
COMMENT ON COLUMN xxwsh_oe_transaction_types2_v.transaction_type_id            IS '取引タイプID';
COMMENT ON COLUMN xxwsh_oe_transaction_types2_v.transaction_type_name          IS '取引タイプ名';
COMMENT ON COLUMN xxwsh_oe_transaction_types2_v.description                    IS '摘要';
COMMENT ON COLUMN xxwsh_oe_transaction_types2_v.transaction_type_code          IS '取引タイプコード';
COMMENT ON COLUMN xxwsh_oe_transaction_types2_v.order_category_code            IS '受注カテゴリコード';
COMMENT ON COLUMN xxwsh_oe_transaction_types2_v.start_date_active              IS '有効開始日';
COMMENT ON COLUMN xxwsh_oe_transaction_types2_v.end_date_active                IS '有効終了日';
COMMENT ON COLUMN xxwsh_oe_transaction_types2_v.org_id                         IS '営業単位ID';
COMMENT ON COLUMN xxwsh_oe_transaction_types2_v.price_list_id                  IS '価格表ID';
COMMENT ON COLUMN xxwsh_oe_transaction_types2_v.default_inbound_line_type_id   IS 'デフォルト返品明細タイプID';
COMMENT ON COLUMN xxwsh_oe_transaction_types2_v.default_outbound_line_type_id  IS 'デフォルト受注明細タイプID';
COMMENT ON COLUMN xxwsh_oe_transaction_types2_v.shipping_shikyu_class          IS '出荷支給区分';
COMMENT ON COLUMN xxwsh_oe_transaction_types2_v.shipping_class                 IS '出荷区分分類';
COMMENT ON COLUMN xxwsh_oe_transaction_types2_v.auto_create_po_class           IS '自動発注作成区分';
COMMENT ON COLUMN xxwsh_oe_transaction_types2_v.adjs_class                     IS '在庫調整区分';
COMMENT ON COLUMN xxwsh_oe_transaction_types2_v.cancel_order_type              IS '取消受注タイプ';
COMMENT ON COLUMN xxwsh_oe_transaction_types2_v.transfer_class                 IS '振替区分';
COMMENT ON COLUMN xxwsh_oe_transaction_types2_v.item_class                     IS '品目区分';
COMMENT ON COLUMN xxwsh_oe_transaction_types2_v.ship_sikyu_rcv_pay_ctg         IS '出荷支給受払カテゴリ';
COMMENT ON COLUMN xxwsh_oe_transaction_types2_v.used_disp_flg                  IS '画面使用フラグ';
--
COMMENT ON TABLE  xxwsh_oe_transaction_types2_v IS '受注タイプ情報VIEW2';