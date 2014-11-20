CREATE OR REPLACE VIEW xxwsh_req_no_move_no_sh_mv2_v
(
  biz_type,
  request_no
)
AS
  SELECT '1',
         xoha.request_no
  FROM xxwsh_order_headers_all xoha,
       xxwsh_oe_transaction_types_v xottv,
       xxwsh_order_lines_all xola
  WHERE xoha.latest_external_flag = 'Y'
  AND   xottv.shipping_shikyu_class = '1'
        AND xoha.req_status >= '03'
  AND   xoha.req_status <> '99'
  AND   xoha.prod_class = '1'
  AND   xottv.transaction_type_id = xoha.order_type_id
  AND   xottv.order_category_code = 'ORDER'
  AND   xoha.order_header_id = xola.order_header_id
  AND   xola.delete_flag <> 'Y'
  AND   move_number IS NULL
  AND   po_number IS NULL
  UNION
  SELECT '3',
         xmrih.mov_num
  FROM xxinv_mov_req_instr_headers xmrih,
       xxinv_mov_req_instr_lines xmril
  WHERE xmrih.status >= '02'
  AND   xmrih.status <> '99'
  AND   xmrih.item_class = '1'
  AND   xmrih.mov_type = '1'
  AND   xmrih.mov_hdr_id = xmril.mov_hdr_id
  AND   xmril.delete_flg <> 'Y'
  AND   xmril.move_num IS NULL
  AND   xmril.po_num IS NULL
;
--
COMMENT ON COLUMN xxwsh_req_no_move_no_sh_mv2_v.biz_type          IS '‹Æ–±í•Ê';
COMMENT ON COLUMN xxwsh_req_no_move_no_sh_mv2_v.request_no        IS 'ˆË—ŠNo/ˆÚ“®No';
--
COMMENT ON TABLE  xxwsh_req_no_move_no_sh_mv2_v IS 'ˆË—ŠNo/ˆÚ“®No(o‰×/ˆÚ“®_ˆÚ“®No”­’NoIsNull)VIEW';
