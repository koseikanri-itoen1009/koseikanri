-- 稼働日カレンダーコード項目追加スクリプト
ALTER TABLE xxcmm.xxcmm_cust_accounts ADD (
  calendar_code VARCHAR2(10)
)
/
COMMENT ON COLUMN xxcmm.xxcmm_cust_accounts.calendar_code IS '稼働日カレンダーコード'
/