ALTER TABLE xxcfr.xxcfr_rep_st_inv_ex_tax_d_l
ADD (
      invoice_tax_div                   VARCHAR2(1)
     ,tax_amount_sum                    NUMBER
     ,tax_amount_sum2                   NUMBER
     ,inv_amount_sum                    NUMBER
     ,inv_amount_sum2                   NUMBER
     ,invoice_t_no                      VARCHAR2(14)
)
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_ex_tax_d_l.invoice_tax_div            IS 'êøãÅèëè¡îÔê≈êœè„Ç∞åvéZï˚éÆ'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_ex_tax_d_l.tax_amount_sum             IS 'ê≈äzçáåvÇP'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_ex_tax_d_l.tax_amount_sum2            IS 'ê≈äzçáåvÇQ'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_ex_tax_d_l.inv_amount_sum             IS 'ê≈î≤çáåvÇP'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_ex_tax_d_l.inv_amount_sum2            IS 'ê≈î≤çáåvÇQ'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_ex_tax_d_l.invoice_t_no               IS 'ìKäiêøãÅèëî≠çséñã∆é“ìoò^î‘çÜ'
/
