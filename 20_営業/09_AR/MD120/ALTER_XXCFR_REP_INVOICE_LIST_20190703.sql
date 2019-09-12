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
COMMENT ON COLUMN xxcfr.xxcfr_rep_invoice_list.category       IS '“à–ó•ª—Ş(•ÒW—p)';
COMMENT ON COLUMN xxcfr.xxcfr_rep_invoice_list.category1      IS '“à–ó•ª—Ş‚P';
COMMENT ON COLUMN xxcfr.xxcfr_rep_invoice_list.ex_tax_charge1 IS '“–Œ‚¨”ƒã‚°Šz‚P';
COMMENT ON COLUMN xxcfr.xxcfr_rep_invoice_list.tax_sum1       IS 'Á”ïÅŠz‚P';
COMMENT ON COLUMN xxcfr.xxcfr_rep_invoice_list.category2      IS '“à–ó•ª—Ş‚Q';
COMMENT ON COLUMN xxcfr.xxcfr_rep_invoice_list.ex_tax_charge2 IS '“–Œ‚¨”ƒã‚°Šz‚Q';
COMMENT ON COLUMN xxcfr.xxcfr_rep_invoice_list.tax_sum2       IS 'Á”ïÅŠz‚Q';
COMMENT ON COLUMN xxcfr.xxcfr_rep_invoice_list.category3      IS '“à–ó•ª—Ş‚R';
COMMENT ON COLUMN xxcfr.xxcfr_rep_invoice_list.ex_tax_charge3 IS '“–Œ‚¨”ƒã‚°Šz‚R';
COMMENT ON COLUMN xxcfr.xxcfr_rep_invoice_list.tax_sum3       IS 'Á”ïÅŠz‚R';
