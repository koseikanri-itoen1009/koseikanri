ALTER TABLE xxcfr.xxcfr_rep_st_inv_inc_tax_c_h
    ADD (
        category1       VARCHAR2(30),
        category2       VARCHAR2(30),
        category3       VARCHAR2(30),
        inc_tax_charge3 NUMBER
    );
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_c_h.category1       IS '内訳分類１';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_c_h.category2       IS '内訳分類２';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_c_h.category3       IS '内訳分類３';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_c_h.inc_tax_charge3 IS '当月お買上げ額３';
