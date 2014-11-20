ALTER TABLE xxcok.xxcok_backmargin_balance
ADD(
  amt_fix_status VARCHAR2(1)
)
/
UPDATE xxcok_backmargin_balance xbb
SET xbb.amt_fix_status = NVL( ( SELECT DISTINCT
                                       xcbs.amt_fix_status
                                FROM xxcok_cond_bm_support   xcbs
                                WHERE xcbs.base_code            = xbb.base_code
                                  AND xcbs.supplier_code        = xbb.supplier_code
                                  AND xcbs.supplier_site_code   = xbb.supplier_site_code
                                  AND xcbs.delivery_cust_code   = xbb.cust_code
                                  AND xcbs.closing_date         = xbb.closing_date
                                  AND xcbs.expect_payment_date  = xbb.expect_payment_date
                                  AND xcbs.tax_code             = xbb.tax_code
                              )
                            , '9' )
/
ALTER TABLE xxcok.xxcok_backmargin_balance
MODIFY(
  amt_fix_status VARCHAR2(1) NOT NULL
)
/
