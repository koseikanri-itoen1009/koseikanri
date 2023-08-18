ALTER TABLE xxcfr.xxcfr_rep_st_invoice_ex_tax 
ADD (
      invoice_tax_div                     VARCHAR2(1)
     ,tax_amount_sum                      NUMBER
     ,tax_amount_sum2                     NUMBER
     ,ex_tax_charge_header                NUMBER
     ,tax_sum_header                      NUMBER
     ,invoice_t_no                        VARCHAR2(14)
)
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_ex_tax.invoice_tax_div                IS '請求書消費税積上げ計算方式'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_ex_tax.tax_amount_sum                 IS '税額合計１'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_ex_tax.tax_amount_sum2                IS '税額合計２'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_ex_tax.ex_tax_charge_header           IS 'ヘッダー用当月お買上げ額'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_ex_tax.tax_sum_header                 IS 'ヘッダー用消費税額'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_ex_tax.invoice_t_no                   IS '適格請求書発行事業者登録番号'
/

