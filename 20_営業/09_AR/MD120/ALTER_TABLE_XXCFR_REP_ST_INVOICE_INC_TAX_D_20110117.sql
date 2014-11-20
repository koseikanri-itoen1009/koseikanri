ALTER TABLE xxcfr.xxcfr_rep_st_invoice_inc_tax_d
    ADD (
        store_code          VARCHAR2(10),
        store_code_sort     VARCHAR2(10),
        ship_account_number VARCHAR2(30),
        invo_account_number VARCHAR2(30)
    );
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_inc_tax_d.store_code           IS '店舗コード';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_inc_tax_d.store_code_sort      IS '店舗コード(ソート用)';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_inc_tax_d.ship_account_number  IS '納品先顧客コード(ソート用)';
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_inc_tax_d.invo_account_number  IS '請求用顧客コード(ソート用)';
