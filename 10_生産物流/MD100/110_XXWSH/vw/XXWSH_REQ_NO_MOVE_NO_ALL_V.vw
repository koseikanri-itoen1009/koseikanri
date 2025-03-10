CREATE OR REPLACE VIEW apps.xxwsh_req_no_move_no_all_v
(
  biz_type,
  request_no
)
AS
  SELECT xottv.shipping_shikyu_class,
         xoha.request_no
  FROM xxwsh_order_headers_all xoha,
       xxwsh_oe_transaction_types_v xottv
  WHERE xoha.latest_external_flag = 'Y'
  AND   ((xottv.shipping_shikyu_class = '1'
          AND xoha.req_status >= '03') OR
         (xottv.shipping_shikyu_class = '2'
          AND xoha.req_status >= '07'))
  AND   xoha.req_status <> '99'
  AND   xottv.transaction_type_id = xoha.order_type_id
  AND   xottv.order_category_code = 'ORDER'
  UNION
  SELECT '3',
         xmrih.mov_num
  FROM xxinv_mov_req_instr_headers xmrih
  WHERE xmrih.status >= '02'
  AND   xmrih.status <> '99'
  AND   xmrih.mov_type = '1'
;
--
COMMENT ON COLUMN xxwsh_req_no_move_no_all_v.biz_type   IS '�Ɩ����';
COMMENT ON COLUMN xxwsh_req_no_move_no_all_v.request_no IS '�˗�No/�ړ�No';
--
COMMENT ON TABLE xxwsh_req_no_move_no_all_v IS '�˗�No/�ړ�No(�S��)VIEW';
