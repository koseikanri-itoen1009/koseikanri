ALTER TABLE xxcfr.xxcfr_rep_st_inv_inc_tax_d_l
    ADD (
        description     VARCHAR2(10),
        category        VARCHAR2(30),
        category1       VARCHAR2(30),
        category2       VARCHAR2(30),
        category3       VARCHAR2(30),
        inc_tax_charge3 NUMBER
    );
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_d_l.description     IS '摘要';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_d_l.category        IS '内訳分類(編集用)';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_d_l.category1       IS '内訳分類１';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_d_l.category2       IS '内訳分類２';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_d_l.category3       IS '内訳分類３';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_d_l.inc_tax_charge3 IS '当月お買上げ額３';
