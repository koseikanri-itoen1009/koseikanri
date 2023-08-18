ALTER TABLE xxcfr.xxcfr_rep_st_inv_inc_tax_a_l 
ADD (
      invoice_tax_div                     VARCHAR2(1)
     ,tax_amount_sum                      NUMBER
     ,tax_amount_sum2                     NUMBER
     ,inv_amount_sum                      NUMBER
     ,inv_amount_sum2                     NUMBER
     ,invoice_t_no                        VARCHAR2(14)
)
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_a_l.invoice_tax_div                IS '請求書消費税積上げ計算方式'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_a_l.tax_amount_sum                 IS '税額合計１'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_a_l.tax_amount_sum2                IS '税額合計２'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_a_l.inv_amount_sum                 IS '税抜合計１'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_a_l.inv_amount_sum2                IS '税抜合計２'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_a_l.invoice_t_no                   IS '適格請求書発行事業者登録番号'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_a_l.store_sum                      IS '当月ご請求額（税込）'
/
