ALTER TABLE xxcfr.xxcfr_rep_st_invoice_inc_tax
    ADD (
        description     VARCHAR2(10),
        category        VARCHAR2(30),
        category1       VARCHAR2(30),
        category2       VARCHAR2(30),
        category3       VARCHAR2(30),
        inc_tax_charge3 NUMBER
    );
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_inc_tax.description     IS '�E�v';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_inc_tax.category        IS '���󕪗�(�ҏW�p)';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_inc_tax.category1       IS '���󕪗ނP';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_inc_tax.category2       IS '���󕪗ނQ';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_inc_tax.category3       IS '���󕪗ނR';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_inc_tax.inc_tax_charge3 IS '���������グ�z�R';
