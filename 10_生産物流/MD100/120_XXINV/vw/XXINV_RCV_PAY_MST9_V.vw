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
COMMENT ON COLUMN xxinv_rcv_pay_mst9_v.new_div_invent   IS '�V�敪�i�݌ɗp�j' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst9_v.use_div_invent   IS '�݌Ɏg�p�敪' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst9_v.new_div_account  IS '�V�o���󕥋敪' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst9_v.dealings_div     IS '����敪' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst9_v.rcv_pay_div      IS '�󕥋敪' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst9_v.doc_type         IS '�����^�C�v' ;
COMMENT ON COLUMN xxinv_rcv_pay_mst9_v.reason_code      IS '���R�R�[�h' ;
--
COMMENT ON TABLE  xxinv_rcv_pay_mst9_v IS '�󕥋敪���VIEW_�q�Ɋ֘A' ;
/
