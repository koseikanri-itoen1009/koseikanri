ALTER TABLE xxcfr.xxcfr_rep_st_inv_inc_tax_a_h
    ADD (
        category1       VARCHAR2(30),
        category2       VARCHAR2(30),
        category3       VARCHAR2(30),
        inc_tax_charge3 NUMBER
    );
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_a_h.category1       IS '���󕪗ނP';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_a_h.category2       IS '���󕪗ނQ';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_a_h.category3       IS '���󕪗ނR';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_a_h.inc_tax_charge3 IS '���������グ�z�R';
