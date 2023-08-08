ALTER TABLE xxcfr.xxcfr_invoice_headers 
ADD (
      tax_diff_amount_create_flg          VARCHAR2(1)
     ,invoice_tax_div                     VARCHAR2(1)
     ,inv_gap_amount                      NUMBER
     ,tax_rounding_rule                   VARCHAR2(30)
     ,output_format                       VARCHAR2(10)
)
/
COMMENT ON COLUMN xxcfr.xxcfr_invoice_headers.tax_diff_amount_create_flg           IS '消費税差額作成フラグ'
/
COMMENT ON COLUMN xxcfr.xxcfr_invoice_headers.invoice_tax_div                      IS '請求書消費税積上げ計算方式'
/
COMMENT ON COLUMN xxcfr.xxcfr_invoice_headers.inv_gap_amount                       IS '本体差額'
/
COMMENT ON COLUMN xxcfr.xxcfr_invoice_headers.tax_rounding_rule                    IS '税金－端数処理'
/
COMMENT ON COLUMN xxcfr.xxcfr_invoice_headers.output_format                        IS '請求書出力形式'
/
