ALTER TABLE xxcfr.xxcfr_rep_st_inv_ex_tax_c_l
    ADD (
        description     VARCHAR2(10),
        category        VARCHAR2(30)
    );
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_ex_tax_c_l.description     IS '摘要';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_ex_tax_c_l.category        IS '内訳分類(編集用)';
