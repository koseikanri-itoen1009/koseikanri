ALTER TABLE xxcfr.xxcfr_rep_st_invoice_inc_tax
    ADD (
        description     VARCHAR2(10),
        category        VARCHAR2(30),
        category1       VARCHAR2(30),
        category2       VARCHAR2(30),
        category3       VARCHAR2(30),
        inc_tax_charge3 NUMBER
    );
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_inc_tax.description     IS '摘要';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_inc_tax.category        IS '内訳分類(編集用)';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_inc_tax.category1       IS '内訳分類１';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_inc_tax.category2       IS '内訳分類２';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_inc_tax.category3       IS '内訳分類３';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_inc_tax.inc_tax_charge3 IS '当月お買上げ額３';
