-- 顧客追加情報テーブル項目追加スクリプト
ALTER TABLE xxcmm.xxcmm_cust_accounts ADD(
  invoice_printing_unit       VARCHAR2(1),
  invoice_code                VARCHAR2(9),
  enclose_invoice_code        VARCHAR2(9)
)
/
COMMENT ON COLUMN xxcmm.xxcmm_cust_accounts.invoice_printing_unit       IS '請求書印刷単位'
/
COMMENT ON COLUMN xxcmm.xxcmm_cust_accounts.invoice_code                IS '請求書用コード'
/
COMMENT ON COLUMN xxcmm.xxcmm_cust_accounts.enclose_invoice_code        IS '統括請求書用コード'
/