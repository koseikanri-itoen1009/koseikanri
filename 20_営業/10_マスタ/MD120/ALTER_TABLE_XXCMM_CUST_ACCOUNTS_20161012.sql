-- 顧客追加情報テーブル項目追加スクリプト
ALTER TABLE xxcmm.xxcmm_cust_accounts ADD(
    bp_customer_code            VARCHAR2(15),
    offset_cust_code            VARCHAR2(9),
    offset_cust_div             VARCHAR2(1)
)
/
COMMENT ON COLUMN xxcmm.xxcmm_cust_accounts.bp_customer_code            IS '取引先顧客コード'
/
COMMENT ON COLUMN xxcmm.xxcmm_cust_accounts.offset_cust_code            IS '相殺用顧客コード'
/
COMMENT ON COLUMN xxcmm.xxcmm_cust_accounts.offset_cust_div             IS '相殺用顧客区分'
/