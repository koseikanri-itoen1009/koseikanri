ALTER TABLE xxcfr.xxcfr_rep_st_inv_inc_tax_a_l
    ADD (
        description     VARCHAR2(10),
        category        VARCHAR2(30),
        category1       VARCHAR2(30),
        category2       VARCHAR2(30),
        category3       VARCHAR2(30),
        inc_tax_charge3 NUMBER
    );
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_a_l.description     IS 'ìEóv';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_a_l.category        IS 'ì‡ñÛï™óﬁ(ï“èWóp)';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_a_l.category1       IS 'ì‡ñÛï™óﬁÇP';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_a_l.category2       IS 'ì‡ñÛï™óﬁÇQ';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_a_l.category3       IS 'ì‡ñÛï™óﬁÇR';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_a_l.inc_tax_charge3 IS 'ìñåéÇ®îÉè„Ç∞äzÇR';
