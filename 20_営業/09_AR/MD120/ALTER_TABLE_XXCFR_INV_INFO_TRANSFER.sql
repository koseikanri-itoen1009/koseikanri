ALTER TABLE xxcfr.xxcfr_inv_info_transfer ADD
(
   bill_acct_code         VARCHAR2(30)    -- 請求先顧客コード
);
COMMENT ON COLUMN xxcfr.xxcfr_inv_info_transfer.bill_acct_code       IS '請求先顧客コード';