ALTER TABLE xxcfr.xxcfr_rep_st_invoice_inc_tax_d 
ADD (
      invoice_tax_div                     VARCHAR2(1)
     ,tax_sum1                            NUMBER
     ,tax_sum2                            NUMBER
     ,tax_sum3                            NUMBER
     ,tax_amount_sum                      NUMBER
     ,tax_amount_sum2                     NUMBER
     ,inv_amount_sum                      NUMBER
     ,inv_amount_sum2                     NUMBER
     ,ex_tax_charge_header                NUMBER
     ,tax_sum_header                      NUMBER
     ,invoice_t_no                        VARCHAR2(14)
)
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_inc_tax_d.invoice_tax_div               IS 'êøãÅèëè¡îÔê≈êœè„Ç∞åvéZï˚éÆ'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_inc_tax_d.tax_sum1                      IS 'è¡îÔê≈äzÇP'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_inc_tax_d.tax_sum2                      IS 'è¡îÔê≈äzÇQ'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_inc_tax_d.tax_sum3                      IS 'è¡îÔê≈äzÇR'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_inc_tax_d.tax_amount_sum                IS 'ê≈äzçáåvÇP'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_inc_tax_d.tax_amount_sum2               IS 'ê≈äzçáåvÇQ'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_inc_tax_d.inv_amount_sum                IS 'ê≈î≤çáåvÇP'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_inc_tax_d.inv_amount_sum2               IS 'ê≈î≤çáåvÇQ'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_inc_tax_d.ex_tax_charge_header          IS 'ÉwÉbÉ_Å[ópìñåéÇ®îÉè„Ç∞äz'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_inc_tax_d.tax_sum_header                IS 'ÉwÉbÉ_Å[ópè¡îÔê≈äz'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_inc_tax_d.invoice_t_no                  IS 'ìKäiêøãÅèëî≠çséñã∆é“ìoò^î‘çÜ'
/

