ALTER TABLE xxcfr.xxcfr_invoice_lines 
ADD (
      invoice_id_bef                      NUMBER
     ,invoice_detail_num_bef              NUMBER
)
/
COMMENT ON COLUMN xxcfr.xxcfr_invoice_lines.invoice_id_bef               IS '�ꊇ������ID(�ŐV������K�p�O)'
/
COMMENT ON COLUMN xxcfr.xxcfr_invoice_lines.invoice_detail_num_bef       IS '�ꊇ����������No(�ŐV������K�p�O)'
/
