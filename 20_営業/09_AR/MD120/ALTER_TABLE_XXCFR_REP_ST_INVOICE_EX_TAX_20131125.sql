ALTER TABLE xxcfr.xxcfr_rep_st_invoice_ex_tax
    ADD (
        tax_rate        NUMBER,
        tax_rate1       NUMBER,
        ex_tax_charge1  NUMBER,
        tax_sum1        NUMBER,
        tax_rate2       NUMBER,
        ex_tax_charge2  NUMBER,
        tax_sum2        NUMBER
    );
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_ex_tax.tax_rate        IS '����ŗ�(�ҏW�p)';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_ex_tax.tax_rate1       IS '����ŗ��P';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_ex_tax.ex_tax_charge1  IS '���������グ�z�P';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_ex_tax.tax_sum1        IS '����Ŋz�P';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_ex_tax.tax_rate2       IS '����ŗ��Q';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_ex_tax.ex_tax_charge2  IS '���������グ�z�Q';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_ex_tax.tax_sum2        IS '����Ŋz�Q';
