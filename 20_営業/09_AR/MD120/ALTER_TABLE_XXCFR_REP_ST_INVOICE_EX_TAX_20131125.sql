ALTER TABLE xxcfr.xxcfr_rep_st_invoice_ex_tax
    ADD (
        tax_rate        NUMBER,
        tax_rate1       NUMBER,
        ex_tax_charge1  NUMBER,
        tax_sum1        NUMBER,
        tax_rate2       NUMBER,
        ex_tax_charge2  NUMBER,
        tax_sum2        NUMBER
    );
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_ex_tax.tax_rate        IS 'è¡îÔê≈ó¶(ï“èWóp)';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_ex_tax.tax_rate1       IS 'è¡îÔê≈ó¶ÇP';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_ex_tax.ex_tax_charge1  IS 'ìñåéÇ®îÉè„Ç∞äzÇP';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_ex_tax.tax_sum1        IS 'è¡îÔê≈äzÇP';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_ex_tax.tax_rate2       IS 'è¡îÔê≈ó¶ÇQ';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_ex_tax.ex_tax_charge2  IS 'ìñåéÇ®îÉè„Ç∞äzÇQ';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_ex_tax.tax_sum2        IS 'è¡îÔê≈äzÇQ';
