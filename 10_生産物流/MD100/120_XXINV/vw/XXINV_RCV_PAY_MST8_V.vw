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
 ,line_id
 ,order_category_code
 ,arrival_date
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
        ,rt.transaction_id      AS line_id
        ,'RETURN'               AS order_category_code
        ,NULL                   AS arrival_date
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
  AND    xrpm.transaction_type            = rt.transaction_type
  ;
--
COMMENT ON COLUMN xxinv_rcv_pay_mst8_v.new_div_invent       IS 'VæªiÝÉpj' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst8_v.use_div_invent       IS 'ÝÉgpæª' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst8_v.use_div_invent_rep   IS 'ÝÉ [gpæª' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst8_v.new_div_account      IS 'Voó¥æª' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst8_v.dealings_div         IS 'æøæª' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst8_v.rcv_pay_div          IS 'ó¥æª' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst8_v.stock_adjustment_div IS 'ÝÉ²®æª' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst8_v.doc_type             IS '¶^Cv' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst8_v.doc_id               IS '¶ID' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst8_v.doc_line             IS 'æø¾×Ô' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst8_v.line_id              IS 'CID' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst8_v.order_category_code  IS 'JeS[R[h' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst8_v.arrival_date         IS 'ú' ;
--
COMMENT ON TABLE  xxinv_rcv_pay_mst8_v IS 'ó¥æªîñVIEW_PORC' ;
/
