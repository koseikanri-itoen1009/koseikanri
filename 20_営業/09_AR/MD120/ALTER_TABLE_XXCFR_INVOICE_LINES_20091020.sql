ALTER TABLE xxcfr.xxcfr_invoice_lines
    ADD (
        cutoff_date  DATE         ,
        num_of_cases VARCHAR(240) ,
        medium_class VARCHAR(2)
    );
/
COMMENT ON COLUMN xxcfr.xxcfr_invoice_lines.cutoff_date  IS '����';
COMMENT ON COLUMN xxcfr.xxcfr_invoice_lines.num_of_cases IS '�P�[�X����';
COMMENT ON COLUMN xxcfr.xxcfr_invoice_lines.medium_class IS '�󒍃\�[�X';
