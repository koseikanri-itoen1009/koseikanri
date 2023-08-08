ALTER TABLE xxcfr.xxcfr_rep_invoice_list 
ADD (
      invoice_tax_div                     VARCHAR2(1)
     ,tax_amount_sum1                     NUMBER
     ,tax_amount_sum2                     NUMBER
     ,inv_amount_sum1                     NUMBER
     ,inv_amount_sum2                     NUMBER
     ,invoice_t_no                        VARCHAR2(14)
)
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_invoice_list.invoice_tax_div               IS 'êøãÅèëè¡îÔê≈êœè„Ç∞åvéZï˚éÆ'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_invoice_list.tax_amount_sum1               IS 'ê≈äzçáåvÇP'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_invoice_list.tax_amount_sum2               IS 'ê≈äzçáåvÇQ'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_invoice_list.inv_amount_sum1               IS 'ê≈î≤çáåvÇP'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_invoice_list.inv_amount_sum2               IS 'ê≈î≤çáåvÇQ'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_invoice_list.invoice_t_no                  IS 'ìKäiêøãÅèëî≠çséñã∆é“ìoò^î‘çÜ'
/
