CREATE OR REPLACE VIEW xxinv_rcv_pay_mst6_v
(
  new_div_invent
 ,use_div_invent
 ,use_div_invent_rep
 ,new_div_account
 ,dealings_div
 ,rcv_pay_div
 ,stock_adjustment_div
 ,doc_type
 ,reason_code
)
AS
  SELECT xrpm.new_div_invent
        ,xrpm.use_div_invent
        ,xrpm.use_div_invent_rep
        ,xrpm.new_div_account
        ,xrpm.dealings_div
        ,xrpm.rcv_pay_div
        ,xrpm.stock_adjustment_div
        ,xrpm.doc_type    as doc_type
        ,xrpm.reason_code as reason_code
  FROM   xxcmn_rcv_pay_mst xrpm
  WHERE  xrpm.doc_type = 'ADJI'
  ;
--
COMMENT ON COLUMN xxinv_rcv_pay_mst6_v.new_div_invent       IS 'VæªiÝÉpj' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst6_v.use_div_invent       IS 'ÝÉgpæª' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst6_v.use_div_invent_rep   IS 'ÝÉ [gpæª' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst6_v.new_div_account      IS 'Voó¥æª' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst6_v.dealings_div         IS 'æøæª' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst6_v.rcv_pay_div          IS 'ó¥æª' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst6_v.stock_adjustment_div IS 'ÝÉ²®æª' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst6_v.doc_type             IS '¶^Cv' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst6_v.reason_code          IS 'RR[h' ;
--
COMMENT ON TABLE  xxinv_rcv_pay_mst6_v IS 'ó¥æªîñVIEW_ADJI' ;
/
