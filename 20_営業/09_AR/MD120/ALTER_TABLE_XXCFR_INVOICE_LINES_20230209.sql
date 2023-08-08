ALTER TABLE xxcfr.xxcfr_invoice_lines 
ADD (
      tax_gap_amount                      NUMBER
     ,tax_amount_sum                      NUMBER
     ,tax_amount_sum2                     NUMBER
     ,category                            VARCHAR2(30)
     ,inv_gap_amount                      NUMBER
     ,inv_amount_sum                      NUMBER
     ,inv_amount_sum2                     NUMBER
     ,invoice_printing_unit               VARCHAR2(1)
     ,customer_for_sum                    VARCHAR2(10)
)
/
COMMENT ON COLUMN xxcfr.xxcfr_invoice_lines.tax_gap_amount           IS '�ō��z'
/
COMMENT ON COLUMN xxcfr.xxcfr_invoice_lines.tax_amount_sum           IS '�Ŋz���v�P'
/
COMMENT ON COLUMN xxcfr.xxcfr_invoice_lines.tax_amount_sum2          IS '�Ŋz���v�Q'
/
COMMENT ON COLUMN xxcfr.xxcfr_invoice_lines.category                 IS '���󕪗�'
/
COMMENT ON COLUMN xxcfr.xxcfr_invoice_lines.inv_gap_amount           IS '�{�̍��z'
/
COMMENT ON COLUMN xxcfr.xxcfr_invoice_lines.inv_amount_sum           IS '�Ŕ����v�P'
/
COMMENT ON COLUMN xxcfr.xxcfr_invoice_lines.inv_amount_sum2          IS '�Ŕ����v�Q'
/
COMMENT ON COLUMN xxcfr.xxcfr_invoice_lines.invoice_printing_unit    IS '����������P��'
/
COMMENT ON COLUMN xxcfr.xxcfr_invoice_lines.customer_for_sum         IS '�ڋq(�W�v�p)'
/
