ALTER TABLE xxcfr.xxcfr_invoice_headers
    ADD (
        parallel_type NUMBER
    );
COMMENT ON COLUMN xxcfr.xxcfr_invoice_headers.parallel_type IS '�p���������s�敪';
