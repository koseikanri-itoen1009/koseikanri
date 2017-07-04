-- 顧客一括更新用ワーク項目追加スクリプト
ALTER TABLE xxcmm.xxcmm_wk_cust_batch_regist ADD(
  OFFSET_CUST_CODE        VARCHAR2(30),
  BP_CUSTOMER_CODE        VARCHAR2(100)
)
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.offset_cust_code IS '相殺用顧客コード'
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.bp_customer_code IS '取引先顧客コード'
/