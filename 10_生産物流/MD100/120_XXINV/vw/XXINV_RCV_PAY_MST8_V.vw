CREATE OR REPLACE VIEW xxinv_rcv_pay_mst8_v
(
  new_div_invent
 ,use_div_invent
 ,use_div_invent_rep
 ,new_div_account
 ,dealings_div
 ,rcv_pay_div
 ,stock_adjustment_div
 ,doc_type
 ,doc_id
 ,doc_line
)
AS
  SELECT xrpm.new_div_invent
        ,xrpm.use_div_invent
        ,xrpm.use_div_invent_rep
        ,xrpm.new_div_account
        ,xrpm.dealings_div
        ,xrpm.rcv_pay_div
        ,xrpm.stock_adjustment_div
        ,xrpm.doc_type
        ,rsl.shipment_header_id AS doc_id
        ,rsl.line_num           AS doc_line
  FROM   xxcmn_rcv_pay_mst         xrpm
        ,rcv_shipment_lines        rsl
        ,oe_order_headers_all      ooha
        ,oe_transaction_types_all  otta
        ,ic_item_mst_b             iimb_a
        ,ic_item_mst_b             iimb_o
-- 08/07/08 Y.Yamamoto ADD v1.02 Start
        ,xxwsh_order_headers_all   xoha
-- 08/07/08 Y.Yamamoto ADD v1.02 End
        ,xxwsh_order_lines_all     xola
-- 2008/08/27 K.Yamane Mod ↓
--        ,xxcmn_item_categories4_v  xicv4_a
--        ,xxcmn_item_categories4_v  xicv4_o
        ,xxcmn_item_categories5_v  xicv4_a
        ,xxcmn_item_categories5_v  xicv4_o
-- 2008/08/27 K.Yamane Mod ↑
  WHERE  xrpm.doc_type                    = 'PORC'
  AND    xrpm.source_document_code        = 'RMA'
  AND    ooha.header_id                   = rsl.oe_order_header_id
  AND    otta.transaction_type_id         = ooha.order_type_id
-- 08/07/08 Y.Yamamoto ADD v1.02 Start
  AND    xoha.header_id                   = ooha.header_id
  AND    xoha.latest_external_flag        = 'Y'
  AND    xola.order_header_id             = xoha.order_header_id
-- 08/07/08 Y.Yamamoto ADD v1.02 End
  AND    xola.line_id                     = rsl.oe_order_line_id
  AND    iimb_a.item_no                   = xola.request_item_code
  AND    xicv4_a.item_id                  = iimb_a.item_id
  AND    iimb_o.item_no                   = xola.shipping_item_code
  AND    xicv4_o.item_id                  = iimb_o.item_id
-- 08/07/08 Y.Yamamoto Update v1.02 Start
--  AND (( xrpm.shipment_provision_div     IS NULL )
--    OR ( xrpm.shipment_provision_div      = otta.attribute1 ))
--  AND (( xrpm.stock_adjustment_div       IS NULL )
--    OR ( xrpm.stock_adjustment_div        = otta.attribute4 ))
--  AND (( xrpm.ship_prov_rcv_pay_category IS NULL )
--    OR ( xrpm.ship_prov_rcv_pay_category  = otta.attribute11 ))
  AND (( xrpm.shipment_provision_div     IS NULL )
   OR (( xrpm.shipment_provision_div     IS NOT NULL )
   AND ( xrpm.shipment_provision_div     = otta.attribute1 )))
  AND (( xrpm.stock_adjustment_div       IS NULL )
   OR (( xrpm.stock_adjustment_div       IS NOT NULL )
   AND ( xrpm.stock_adjustment_div       = otta.attribute4 )))
  AND (( xrpm.ship_prov_rcv_pay_category IS NULL )
   OR (( xrpm.ship_prov_rcv_pay_category IS NOT NULL )
   AND ( xrpm.ship_prov_rcv_pay_category = otta.attribute11 )))
  AND (((xrpm.shipment_provision_div     = '3' )
    OR ( xrpm.stock_adjustment_div       = '2' ))
   OR (((xrpm.shipment_provision_div    <> '3' )
    AND (xrpm.stock_adjustment_div      <> '2' ))
-- 08/07/08 Y.Yamamoto Update v1.02 End
-- 08/06/09 Y.Yamamoto Update v1.01 Start
--  AND (( xrpm.item_div_ahead             IS NULL )
--    OR ( xrpm.item_div_ahead              = xicv4_a.item_class_code ))
--  AND (( xrpm.item_div_origin            IS NULL )
--    OR ( xrpm.item_div_origin             = xicv4_o.item_class_code ))
--  AND (( xrpm.prod_div_ahead             IS NULL )
--    OR ( xrpm.prod_div_ahead              = xicv4_a.prod_class_code ))
--  AND (( xrpm.prod_div_origin            IS NULL )
--    OR ( xrpm.prod_div_origin             = xicv4_o.prod_class_code ))
  AND NVL(xrpm.item_div_ahead, 'dummy')   = DECODE(xicv4_a.item_class_code,'5','5','dummy')
-- 08/07/08 Y.Yamamoto Update v1.02 Start
--  AND NVL(xrpm.item_div_origin,'dummy')   = DECODE(xicv4_o.item_class_code,'5','5','dummy')
  AND NVL(xrpm.item_div_origin,'dummy')   = DECODE(xicv4_o.item_class_code,'5','5','dummy')))
--  AND ( ( xola.request_item_code          = xola.shipping_item_code
--    AND   xrpm.prod_div_ahead            IS NULL
--    AND   xrpm.prod_div_origin           IS NULL)
--   OR   ( xola.request_item_code         <> xola.shipping_item_code
--    AND   xrpm.prod_div_ahead            IS NOT NULL
--    AND   xrpm.prod_div_origin           IS NOT NULL))
  AND  (( xola.shipping_inventory_item_id = xola.request_item_id
     AND  xrpm.prod_div_origin            IS NULL
     AND  xrpm.prod_div_ahead             IS NULL )
   OR    (xola.shipping_inventory_item_id <> xola.request_item_id
     AND  xicv4_a.item_class_code         = '5'
     AND  xicv4_o.item_class_code         = '5'
     AND  xrpm.prod_div_origin            IS NOT NULL
     AND  xrpm.prod_div_ahead             IS NOT NULL )
   OR    (xola.shipping_inventory_item_id <> xola.request_item_id
     AND (xicv4_a.item_class_code         <> '5'
     OR   xicv4_o.item_class_code         <> '5')
     AND  xrpm.prod_div_origin            IS NULL
     AND  xrpm.prod_div_ahead             IS NULL ))
-- 08/07/08 Y.Yamamoto Update v1.02 End
-- 08/06/09 Y.Yamamoto Update v1.01 End
UNION ALL
  SELECT xrpm.new_div_invent
        ,xrpm.use_div_invent
        ,xrpm.use_div_invent_rep
        ,xrpm.new_div_account
        ,xrpm.dealings_div
        ,xrpm.rcv_pay_div
        ,xrpm.stock_adjustment_div
        ,xrpm.doc_type
        ,rsl.shipment_header_id AS doc_id
        ,rsl.line_num           AS doc_line
  FROM   xxcmn_rcv_pay_mst         xrpm
        ,rcv_shipment_lines        rsl
        ,rcv_transactions          rt
        ,po_headers_all            pha
        ,po_lines_all              pla
  WHERE  xrpm.doc_type                    = 'PORC'
  AND    xrpm.source_document_code       <> 'RMA'
  AND    rsl.po_header_id                 = pha.po_header_id
  AND    rsl.po_line_id                   = pla.po_line_id
  AND    rsl.shipment_line_id             = rt.shipment_line_id
  AND    rsl.destination_type_code        = rt.destination_type_code
  AND    xrpm.transaction_type            = rt.transaction_type
  ;
--
COMMENT ON COLUMN xxinv_rcv_pay_mst8_v.new_div_invent       IS '新区分（在庫用）' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst8_v.use_div_invent       IS '在庫使用区分' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst8_v.use_div_invent_rep   IS '在庫帳票使用区分' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst8_v.new_div_account      IS '新経理受払区分' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst8_v.dealings_div         IS '取引区分' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst8_v.rcv_pay_div          IS '受払区分' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst8_v.stock_adjustment_div IS '在庫調整区分' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst8_v.doc_type             IS '文書タイプ' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst8_v.doc_id               IS '文書ID' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst8_v.doc_line             IS '取引明細番号' ;
--
COMMENT ON TABLE  xxinv_rcv_pay_mst8_v IS '受払区分情報VIEW_PORC' ;
/
