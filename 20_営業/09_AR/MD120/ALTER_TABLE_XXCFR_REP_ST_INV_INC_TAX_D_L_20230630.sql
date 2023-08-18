ALTER TABLE xxcfr.xxcfr_rep_st_inv_inc_tax_d_l
ADD (
      store_tax_sum                     NUMBER
     ,tax_sum1                          NUMBER
     ,tax_sum2                          NUMBER
     ,tax_sum3                          NUMBER
     ,invoice_tax_div                   VARCHAR2(1)
     ,tax_amount_sum                    NUMBER
     ,tax_amount_sum2                   NUMBER
     ,inv_amount_sum                    NUMBER
     ,inv_amount_sum2                   NUMBER
     ,invoice_t_no                      VARCHAR2(14)
)
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_d_l.store_tax_sum             IS 'è¡îÔê≈ìô'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_d_l.tax_sum1                  IS 'è¡îÔê≈äzÇP'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_d_l.tax_sum2                  IS 'è¡îÔê≈äzÇQ'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_d_l.tax_sum3                  IS 'è¡îÔê≈äzÇR'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_d_l.invoice_tax_div           IS 'êøãÅèëè¡îÔê≈êœè„Ç∞åvéZï˚éÆ'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_d_l.tax_amount_sum            IS 'ê≈äzçáåvÇP'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_d_l.tax_amount_sum2           IS 'ê≈äzçáåvÇQ'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_d_l.inv_amount_sum            IS 'ê≈î≤çáåvÇP'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_d_l.inv_amount_sum2           IS 'ê≈î≤çáåvÇQ'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_d_l.invoice_t_no              IS 'ìKäiêøãÅèëî≠çséñã∆é“ìoò^î‘çÜ'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_d_l.store_sum                 IS 'ìñåéÇ®îÉè„Ç∞äz'
/
