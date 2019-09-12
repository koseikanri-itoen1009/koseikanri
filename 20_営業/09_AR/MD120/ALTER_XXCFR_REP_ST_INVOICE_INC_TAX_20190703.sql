ALTER TABLE xxcfr.xxcfr_rep_st_invoice_inc_tax
    ADD (
        description     VARCHAR2(10),
        category        VARCHAR2(30),
        category1       VARCHAR2(30),
        category2       VARCHAR2(30),
        category3       VARCHAR2(30),
        inc_tax_charge3 NUMBER
    );
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_inc_tax.description     IS 'ìEóv';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_inc_tax.category        IS 'ì‡ñÛï™óﬁ(ï“èWóp)';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_inc_tax.category1       IS 'ì‡ñÛï™óﬁÇP';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_inc_tax.category2       IS 'ì‡ñÛï™óﬁÇQ';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_inc_tax.category3       IS 'ì‡ñÛï™óﬁÇR';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_inc_tax.inc_tax_charge3 IS 'ìñåéÇ®îÉè„Ç∞äzÇR';
