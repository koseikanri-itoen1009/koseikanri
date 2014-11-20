ALTER TABLE xxcok.xxcok_rep_bm_balance
ADD (
  bm_payment_code    VARCHAR2(30)
)
/
COMMENT ON COLUMN xxcok.xxcok_rep_bm_balance.bm_payment_code IS 'BM支払区分（コード値）'
/
