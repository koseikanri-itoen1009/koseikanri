ALTER TABLE xxcfr.xxcfr_rep_invoice_list ADD
(
    output_standard            VARCHAR2(8)       -- 出力基準
   ,inv_amount_no_tax          NUMBER            -- 税抜請求額合計
   ,tax_amount_sum             NUMBER            -- 税額合計
   );
COMMENT ON COLUMN xxcfr.xxcfr_rep_invoice_list.output_standard      IS '出力基準';
COMMENT ON COLUMN xxcfr.xxcfr_rep_invoice_list.inv_amount_no_tax    IS '税抜請求額合計';
COMMENT ON COLUMN xxcfr.xxcfr_rep_invoice_list.tax_amount_sum       IS '税額合計';
