CREATE OR REPLACE VIEW xxinv_rcv_pay_mst7_v
(
  new_div_invent
 ,use_div_invent
 ,use_div_invent_rep
 ,new_div_account
 ,dealings_div
 ,rcv_pay_div
 ,stock_adjustment_div
 ,doc_type
 ,whse_code
 ,location
 ,item_id
 ,lot_id
 ,order_category_code
 ,arrival_date
 ,trans_qty
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
        ,iwm.whse_code
        ,xoha.deliver_from
        ,xmld.item_id
        ,xmld.lot_id
        ,otta.order_category_code
        ,xoha.arrival_date
        ,xmld.actual_quantity
  FROM  xxcmn_rcv_pay_mst          xrpm
       ,oe_transaction_types_all   otta
       ,ic_item_mst_b              iimb_a
       ,ic_item_mst_b              iimb_o
       ,ic_whse_mst                iwm
       ,mtl_item_locations         mil
       ,xxwsh_order_headers_all    xoha
       ,xxwsh_order_lines_all      xola
       ,xxinv_mov_lot_details      xmld
       ,xxcmn_item_categories5_v   xicv4_a
       ,xxcmn_item_categories5_v   xicv4_o
  WHERE  xrpm.doc_type                    = 'OMSO'
  AND    otta.transaction_type_id         = xoha.order_type_id
  AND    xoha.latest_external_flag        = 'Y'
  AND    xoha.req_status                 IN ('04','08')
  AND    xola.order_header_id             = xoha.order_header_id
  AND    xmld.mov_line_id                 = xola.order_line_id
  AND    xmld.document_type_code         IN ('10','30')
  AND    xmld.record_type_code            = '20'
  AND    iimb_a.item_no                   = xola.request_item_code
  AND    xicv4_a.item_id                  = iimb_a.item_id
  AND    iimb_o.item_no                   = xola.shipping_item_code
  AND    xicv4_o.item_id                  = iimb_o.item_id
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
  AND NVL(xrpm.item_div_ahead, 'dummy')   = DECODE(xicv4_a.item_class_code,'5','5','dummy')
  AND NVL(xrpm.item_div_origin,'dummy')   = DECODE(xicv4_o.item_class_code,'5','5','dummy')))
  AND  (( xola.shipping_inventory_item_id = xola.request_item_id
     AND  xrpm.prod_div_origin            IS NULL
     AND  xrpm.prod_div_ahead             IS NULL )
   OR    (xola.shipping_inventory_item_id <> xola.request_item_id
     AND  xicv4_a.item_class_code         = '5'
     AND  xicv4_o.item_class_code         = '5'
   AND  ((NVL(xrpm.prod_div_ahead,  'dummy') = DECODE(xicv4_a.prod_class_code,'1','1','dummy')
     AND  NVL(xrpm.prod_div_origin, 'dummy') = DECODE(xicv4_o.prod_class_code,'2','2','dummy'))
    OR   (xicv4_a.prod_class_code            = xicv4_o.prod_class_code
     AND  NVL(xrpm.prod_div_origin, 'dummy') = 'dummy')
    OR   (xrpm.shipment_provision_div        = '3'
     AND  xrpm.prod_div_origin              IS NULL
     AND  xrpm.prod_div_ahead               IS NULL)))
   OR    (xola.shipping_inventory_item_id <> xola.request_item_id
     AND  xicv4_a.item_class_code         = '5'
     AND  xicv4_o.item_class_code        <> '5'
     AND  xrpm.prod_div_origin            IS NULL
     AND  xrpm.prod_div_ahead             IS NULL )
   OR    (xola.shipping_inventory_item_id <> xola.request_item_id
     AND  xicv4_a.item_class_code        <> '5'
     AND  xicv4_o.item_class_code        <> '5'
     AND  xrpm.prod_div_origin            IS NULL
     AND  xrpm.prod_div_ahead             IS NULL ))
  AND mil.segment1                        = xoha.deliver_from
  AND iwm.mtl_organization_id             = mil.organization_id
  ;
--
COMMENT ON COLUMN xxinv_rcv_pay_mst7_v.new_div_invent       IS '新区分（在庫用）' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst7_v.use_div_invent       IS '在庫使用区分' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst7_v.use_div_invent_rep   IS '在庫帳票使用区分' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst7_v.new_div_account      IS '新経理受払区分' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst7_v.dealings_div         IS '取引区分' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst7_v.rcv_pay_div          IS '受払区分' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst7_v.stock_adjustment_div IS '在庫調整区分' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst7_v.doc_type             IS '文書タイプ' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst7_v.whse_code            IS '倉庫';
COMMENT ON COLUMN xxinv_rcv_pay_mst7_v.location             IS '保管倉庫';
COMMENT ON COLUMN xxinv_rcv_pay_mst7_v.item_id              IS '品目ID';
COMMENT ON COLUMN xxinv_rcv_pay_mst7_v.lot_id               IS 'ロットID';
COMMENT ON COLUMN xxinv_rcv_pay_mst7_v.arrival_date         IS '着日';
COMMENT ON COLUMN xxinv_rcv_pay_mst7_v.trans_qty            IS '実績数量';
--
COMMENT ON TABLE  xxinv_rcv_pay_mst7_v IS '受払区分情報VIEW_OMSO' ;
/
