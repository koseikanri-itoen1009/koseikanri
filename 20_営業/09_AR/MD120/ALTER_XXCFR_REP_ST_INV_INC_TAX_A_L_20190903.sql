ALTER TABLE xxcfr.xxcfr_rep_st_inv_inc_tax_a_l
    ADD (
        description     VARCHAR2(10),
        category        VARCHAR2(30),
        category1       VARCHAR2(30),
        category2       VARCHAR2(30),
        category3       VARCHAR2(30),
        inc_tax_charge3 NUMBER
    );
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_a_l.description     IS '�E�v';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_a_l.category        IS '���󕪗�(�ҏW�p)';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_a_l.category1       IS '���󕪗ނP';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_a_l.category2       IS '���󕪗ނQ';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_a_l.category3       IS '���󕪗ނR';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_a_l.inc_tax_charge3 IS '���������グ�z�R';
