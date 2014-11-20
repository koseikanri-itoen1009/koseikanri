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
 ,line_id
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
        ,wdd.source_line_id as line_id
  FROM  xxcmn_rcv_pay_mst          xrpm
       ,wsh_delivery_details       wdd
       ,oe_order_headers_all       ooha
       ,oe_transaction_types_all   otta
       ,ic_item_mst_b              iimb_a
       ,ic_item_mst_b              iimb_o
       ,xxwsh_order_lines_all      xola
       ,xxcmn_item_categories4_v   xicv4_a
       ,xxcmn_item_categories4_v   xicv4_o
  WHERE  xrpm.doc_type                    = 'OMSO'
  AND    ooha.header_id                   = wdd.source_header_id
  AND    ooha.org_id                        = wdd.org_id
  AND    otta.transaction_type_id         = ooha.order_type_id
  AND    xola.line_id                     = wdd.source_line_id
  AND    iimb_a.item_no                   = xola.request_item_code
  AND    xicv4_a.item_id                  = iimb_a.item_id
  AND    iimb_o.item_no                   = xola.shipping_item_code
  AND    xicv4_o.item_id                  = iimb_o.item_id
  AND (( xrpm.shipment_provision_div     IS NULL )
    OR ( xrpm.shipment_provision_div      = otta.attribute1 ))
  AND (( xrpm.stock_adjustment_div       IS NULL )
    OR ( xrpm.stock_adjustment_div        = otta.attribute4 ))
  AND (( xrpm.ship_prov_rcv_pay_category IS NULL )
    OR ( xrpm.ship_prov_rcv_pay_category  = otta.attribute11 ))
  AND (( xrpm.item_div_ahead             IS NULL )
    OR ( xrpm.item_div_ahead              = xicv4_a.item_class_code ))
  AND (( xrpm.item_div_origin            IS NULL )
    OR ( xrpm.item_div_origin             = xicv4_o.item_class_code ))
  AND (( xrpm.prod_div_ahead             IS NULL )
    OR ( xrpm.prod_div_ahead              = xicv4_a.prod_class_code ))
  AND (( xrpm.prod_div_origin            IS NULL )
    OR ( xrpm.prod_div_origin             = xicv4_o.prod_class_code ))
  ;
--
COMMENT ON COLUMN xxinv_rcv_pay_mst7_v.new_div_invent       IS '�V�敪�i�݌ɗp�j' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst7_v.use_div_invent       IS '�݌Ɏg�p�敪' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst7_v.use_div_invent_rep   IS '�݌ɒ��[�g�p�敪' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst7_v.new_div_account      IS '�V�o���󕥋敪' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst7_v.dealings_div         IS '����敪' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst7_v.rcv_pay_div          IS '�󕥋敪' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst7_v.stock_adjustment_div IS '�݌ɒ����敪' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst7_v.doc_type             IS '�����^�C�v' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst7_v.line_id              IS '�������ID' ;
--
COMMENT ON TABLE  xxinv_rcv_pay_mst7_v IS '�󕥋敪���VIEW_OMSO' ;
/
