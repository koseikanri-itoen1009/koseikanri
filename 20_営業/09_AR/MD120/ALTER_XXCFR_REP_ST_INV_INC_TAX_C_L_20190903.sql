ALTER TABLE xxcfr.xxcfr_rep_st_inv_inc_tax_c_l
    ADD (
        description     VARCHAR2(10),
        category        VARCHAR2(30)
    );
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_c_l.description     IS '�E�v';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_c_l.category        IS '���󕪗�(�ҏW�p)';
