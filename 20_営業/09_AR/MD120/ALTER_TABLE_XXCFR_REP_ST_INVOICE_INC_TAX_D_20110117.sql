ALTER TABLE xxcfr.xxcfr_rep_st_invoice_inc_tax_d
    ADD (
        store_code          VARCHAR2(10),
        store_code_sort     VARCHAR2(10),
        ship_account_number VARCHAR2(30),
        invo_account_number VARCHAR2(30)
    );
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_inc_tax_d.store_code           IS '�X�܃R�[�h';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_inc_tax_d.store_code_sort      IS '�X�܃R�[�h(�\�[�g�p)';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_inc_tax_d.ship_account_number  IS '�[�i��ڋq�R�[�h(�\�[�g�p)';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_inc_tax_d.invo_account_number  IS '�����p�ڋq�R�[�h(�\�[�g�p)';
