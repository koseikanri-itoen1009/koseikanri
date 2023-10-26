ALTER TABLE xxcfr.xxcfr_invoice_lines 
ADD (
      invoice_id_bef                      NUMBER
     ,invoice_detail_num_bef              NUMBER
)
/
COMMENT ON COLUMN xxcfr.xxcfr_invoice_lines.invoice_id_bef               IS '一括請求書ID(最新請求先適用前)'
/
COMMENT ON COLUMN xxcfr.xxcfr_invoice_lines.invoice_detail_num_bef       IS '一括請求書明細No(最新請求先適用前)'
/
