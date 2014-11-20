CREATE OR REPLACE VIEW xxwsh_delivery_no_ship_move_v
(
  row_id,
  biz_type,
  delivery_no
)
AS
  SELECT xoha.rowid,
         '1',
         xoha.delivery_no
  FROM xxwsh_order_headers_all xoha,
       xxwsh_oe_transaction_types_v xottv
  WHERE xoha.latest_external_flag = 'Y'
  AND   xottv.shipping_shikyu_class = '1'
  AND   xoha.req_status >= '03'
  AND   xoha.req_status <> '99'
  AND   xottv.transaction_type_id = xoha.order_type_id
  AND   xottv.order_category_code = 'ORDER'
  AND   xoha.delivery_no IS NOT NULL
  UNION
  SELECT xmrih.rowid,
         '3',
         xmrih.delivery_no
  FROM xxinv_mov_req_instr_headers xmrih
  WHERE xmrih.status >= '02'
  AND   xmrih.status <> '99'
  AND   xmrih.mov_type = '1'
  AND   xmrih.delivery_no IS NOT NULL
;
--
COMMENT ON COLUMN xxwsh_delivery_no_ship_move_v.row_id            IS 'ROWID';
COMMENT ON COLUMN xxwsh_delivery_no_ship_move_v.biz_type          IS 'ã∆ñ±éÌï ';
COMMENT ON COLUMN xxwsh_delivery_no_ship_move_v.delivery_no       IS 'îzëóNo';
--
COMMENT ON TABLE  xxwsh_delivery_no_ship_move_v IS 'îzëóNo(èoâ◊/à⁄ìÆ)VIEW';