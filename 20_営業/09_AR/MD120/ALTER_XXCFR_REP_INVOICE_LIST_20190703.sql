ALTER TABLE xxcfr.xxcfr_rep_invoice_list
    ADD (
        category        VARCHAR2(30),
        category1       VARCHAR2(30),
        ex_tax_charge1  NUMBER      ,
        tax_sum1        NUMBER      ,
        category2       VARCHAR2(30),
        ex_tax_charge2  NUMBER      ,
        tax_sum2        NUMBER      ,
        category3       VARCHAR2(30),
        ex_tax_charge3  NUMBER      ,
        tax_sum3        NUMBER
    );
COMMENT ON COLUMN xxcfr.xxcfr_rep_invoice_list.category       IS '���󕪗�(�ҏW�p)';
COMMENT ON COLUMN xxcfr.xxcfr_rep_invoice_list.category1      IS '���󕪗ނP';
COMMENT ON COLUMN xxcfr.xxcfr_rep_invoice_list.ex_tax_charge1 IS '���������グ�z�P';
COMMENT ON COLUMN xxcfr.xxcfr_rep_invoice_list.tax_sum1       IS '����Ŋz�P';
COMMENT ON COLUMN xxcfr.xxcfr_rep_invoice_list.category2      IS '���󕪗ނQ';
COMMENT ON COLUMN xxcfr.xxcfr_rep_invoice_list.ex_tax_charge2 IS '���������グ�z�Q';
COMMENT ON COLUMN xxcfr.xxcfr_rep_invoice_list.tax_sum2       IS '����Ŋz�Q';
COMMENT ON COLUMN xxcfr.xxcfr_rep_invoice_list.category3      IS '���󕪗ނR';
COMMENT ON COLUMN xxcfr.xxcfr_rep_invoice_list.ex_tax_charge3 IS '���������グ�z�R';
COMMENT ON COLUMN xxcfr.xxcfr_rep_invoice_list.tax_sum3       IS '����Ŋz�R';
