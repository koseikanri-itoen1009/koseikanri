ALTER TABLE xxcfr.xxcfr_invoice_lines 
ADD (
      invoice_id_bef                      NUMBER
     ,invoice_detail_num_bef              NUMBER
)
/
COMMENT ON COLUMN xxcfr.xxcfr_invoice_lines.invoice_id_bef               IS 'ê¿ID(ÅV¿æKpO)'
/
COMMENT ON COLUMN xxcfr.xxcfr_invoice_lines.invoice_detail_num_bef       IS 'ê¿¾×No(ÅV¿æKpO)'
/
