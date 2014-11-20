ALTER TABLE xxcfr.xxcfr_rep_st_invoice_ex_tax
    ADD (
        bill_account_number VARCHAR2(30),
        store_code          VARCHAR2(10)
    );
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_ex_tax.bill_account_number  IS '請求顧客コード(ソート用)';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_ex_tax.store_code  IS '店舗コード(ソート用)';
