ALTER TABLE xxcfr.xxcfr_rep_st_inv_ex_tax_b_h 
ADD (
      ex_tax_charge_header                NUMBER
     ,tax_sum_header                      NUMBER
     ,invoice_t_no                        VARCHAR2(14)
)
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_ex_tax_b_h.ex_tax_charge_header           IS 'ヘッダー用当月お買上げ額'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_ex_tax_b_h.tax_sum_header                 IS 'ヘッダー用消費税額'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_ex_tax_b_h.invoice_t_no                   IS '適格請求書発行事業者登録番号'
/

