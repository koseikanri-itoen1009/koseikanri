ALTER TABLE xxcfr.xxcfr_rep_st_inv_inc_tax_b_h 
ADD (
      tax_sum1                            NUMBER
     ,tax_sum2                            NUMBER
     ,tax_sum3                            NUMBER
     ,ex_tax_charge_header                NUMBER
     ,tax_sum_header                      NUMBER
     ,invoice_t_no                        VARCHAR2(14)
)
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_b_h.tax_sum1                      IS 'è¡îÔê≈äzÇP'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_b_h.tax_sum2                      IS 'è¡îÔê≈äzÇQ'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_b_h.tax_sum3                      IS 'è¡îÔê≈äzÇR'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_b_h.ex_tax_charge_header          IS 'ÉwÉbÉ_Å[ópìñåéÇ®îÉè„Ç∞äz'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_b_h.tax_sum_header                IS 'ÉwÉbÉ_Å[ópè¡îÔê≈äz'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_b_h.invoice_t_no                  IS 'ìKäiêøãÅèëî≠çséñã∆é“ìoò^î‘çÜ'
/

