ALTER TABLE xxcfr.xxcfr_rep_invoice_list ADD
(
    output_standard            VARCHAR2(8)       -- �o�͊
   ,inv_amount_no_tax          NUMBER            -- �Ŕ������z���v
   ,tax_amount_sum             NUMBER            -- �Ŋz���v
   );
COMMENT ON COLUMN xxcfr.xxcfr_rep_invoice_list.output_standard      IS '�o�͊';
COMMENT ON COLUMN xxcfr.xxcfr_rep_invoice_list.inv_amount_no_tax    IS '�Ŕ������z���v';
COMMENT ON COLUMN xxcfr.xxcfr_rep_invoice_list.tax_amount_sum       IS '�Ŋz���v';
