ALTER TABLE xxcfr.xxcfr_inv_info_transfer ADD
(
   bill_acct_code         VARCHAR2(30)    -- ������ڋq�R�[�h
);
COMMENT ON COLUMN xxcfr.xxcfr_inv_info_transfer.bill_acct_code       IS '������ڋq�R�[�h';