ALTER TABLE xxcfr.xxcfr_rep_st_inv_ex_tax_b_l 
ADD (
      invoice_tax_div                     VARCHAR2(1)
     ,tax_amount_sum                      NUMBER
     ,tax_amount_sum2                     NUMBER
     ,invoice_t_no                        VARCHAR2(14)
)
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_ex_tax_b_l.invoice_tax_div                IS '¿‹‘Á”ïÅÏã‚°ŒvZ•û®'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_ex_tax_b_l.tax_amount_sum                 IS 'ÅŠz‡Œv‚P'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_ex_tax_b_l.tax_amount_sum2                IS 'ÅŠz‡Œv‚Q'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_ex_tax_b_l.invoice_t_no                   IS '“KŠi¿‹‘”­s–‹ÆÒ“o˜^”Ô†'
/
