ALTER TABLE xxcfr.xxcfr_rep_st_invoice_inc_tax_d
    ADD (
        tax_rate        NUMBER,
        tax_rate1       NUMBER,
        inc_tax_charge1 NUMBER,
        tax_rate2       NUMBER,
        inc_tax_charge2 NUMBER
    );
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_inc_tax_d.tax_rate                       IS 'è¡îÔê≈ó¶(ï“èWóp)';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_inc_tax_d.tax_rate1                      IS 'è¡îÔê≈ó¶ÇP';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_inc_tax_d.inc_tax_charge1                IS 'ìñåéÇ®îÉè„Ç∞äzÇP';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_inc_tax_d.tax_rate2                      IS 'è¡îÔê≈ó¶ÇQ';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_inc_tax_d.inc_tax_charge2                IS 'ìñåéÇ®îÉè„Ç∞äzÇQ';
