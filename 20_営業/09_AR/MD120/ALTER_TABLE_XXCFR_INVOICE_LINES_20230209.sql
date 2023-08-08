ALTER TABLE xxcfr.xxcfr_invoice_lines 
ADD (
      tax_gap_amount                      NUMBER
     ,tax_amount_sum                      NUMBER
     ,tax_amount_sum2                     NUMBER
     ,category                            VARCHAR2(30)
     ,inv_gap_amount                      NUMBER
     ,inv_amount_sum                      NUMBER
     ,inv_amount_sum2                     NUMBER
     ,invoice_printing_unit               VARCHAR2(1)
     ,customer_for_sum                    VARCHAR2(10)
)
/
COMMENT ON COLUMN xxcfr.xxcfr_invoice_lines.tax_gap_amount           IS 'ê≈ç∑äz'
/
COMMENT ON COLUMN xxcfr.xxcfr_invoice_lines.tax_amount_sum           IS 'ê≈äzçáåvÇP'
/
COMMENT ON COLUMN xxcfr.xxcfr_invoice_lines.tax_amount_sum2          IS 'ê≈äzçáåvÇQ'
/
COMMENT ON COLUMN xxcfr.xxcfr_invoice_lines.category                 IS 'ì‡ñÛï™óﬁ'
/
COMMENT ON COLUMN xxcfr.xxcfr_invoice_lines.inv_gap_amount           IS 'ñ{ëÃç∑äz'
/
COMMENT ON COLUMN xxcfr.xxcfr_invoice_lines.inv_amount_sum           IS 'ê≈î≤çáåvÇP'
/
COMMENT ON COLUMN xxcfr.xxcfr_invoice_lines.inv_amount_sum2          IS 'ê≈î≤çáåvÇQ'
/
COMMENT ON COLUMN xxcfr.xxcfr_invoice_lines.invoice_printing_unit    IS 'êøãÅèëàÛç¸íPà '
/
COMMENT ON COLUMN xxcfr.xxcfr_invoice_lines.customer_for_sum         IS 'å⁄ãq(èWåvóp)'
/
