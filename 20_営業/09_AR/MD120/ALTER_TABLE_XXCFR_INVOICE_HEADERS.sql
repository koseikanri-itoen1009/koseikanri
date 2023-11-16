ALTER TABLE xxcfr.xxcfr_invoice_headers 
ADD (
      tax_gap_amount_sent                 NUMBER
     ,inv_gap_amount_sent                 NUMBER
)
/
COMMENT ON COLUMN xxcfr.xxcfr_invoice_headers.tax_gap_amount_sent        IS '‘—MÏÅ·Šz'
/
COMMENT ON COLUMN xxcfr.xxcfr_invoice_headers.inv_gap_amount_sent        IS '‘—MÏ–{‘Ì·Šz'
/
