CREATE OR REPLACE VIEW xxinv_rcv_pay_mst9_v
(
  new_div_invent
 ,use_div_invent
 ,new_div_account
 ,dealings_div
 ,rcv_pay_div
 ,doc_type
 ,reason_code
)
AS
  SELECT xrpm.new_div_invent
        ,xrpm.use_div_invent
        ,xrpm.new_div_account
        ,xrpm.dealings_div
        ,xrpm.rcv_pay_div
        ,xrpm.doc_type    as doc_type
        ,xrpm.reason_code as reason_code
  FROM   xxcmn_rcv_pay_mst xrpm
  WHERE  xrpm.doc_type in ( 'TRNI', 'XFER' )
  ;
--
COMMENT ON COLUMN xxinv_rcv_pay_mst9_v.new_div_invent   IS '新区分（在庫用）' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst9_v.use_div_invent   IS '在庫使用区分' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst9_v.new_div_account  IS '新経理受払区分' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst9_v.dealings_div     IS '取引区分' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst9_v.rcv_pay_div      IS '受払区分' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst9_v.doc_type         IS '文書タイプ' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst9_v.reason_code      IS '事由コード' ;
--
COMMENT ON TABLE  xxinv_rcv_pay_mst9_v IS '受払区分情報VIEW_倉庫関連' ;
/
