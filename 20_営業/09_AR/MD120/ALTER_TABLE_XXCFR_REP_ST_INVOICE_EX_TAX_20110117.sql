ALTER TABLE xxcfr.xxcfr_rep_st_invoice_ex_tax
    ADD (
        bill_account_number VARCHAR2(30),
        store_code          VARCHAR2(10)
    );
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_ex_tax.bill_account_number  IS '�����ڋq�R�[�h(�\�[�g�p)';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_ex_tax.store_code  IS '�X�܃R�[�h(�\�[�g�p)';
