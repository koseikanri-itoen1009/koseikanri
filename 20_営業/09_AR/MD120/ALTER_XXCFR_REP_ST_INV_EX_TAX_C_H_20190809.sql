ALTER TABLE xxcfr.xxcfr_rep_st_inv_ex_tax_c_h
    ADD (
        category1       VARCHAR2(30),
        category2       VARCHAR2(30),
        category3       VARCHAR2(30),
        ex_tax_charge3  NUMBER      ,
        tax_sum3        NUMBER
    );
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_ex_tax_c_h.category1       IS '���󕪗ނP';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_ex_tax_c_h.category2       IS '���󕪗ނQ';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_ex_tax_c_h.category3       IS '���󕪗ނR';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_ex_tax_c_h.ex_tax_charge3  IS '���������グ�z�R';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_ex_tax_c_h.tax_sum3        IS '����Ŋz�R';
