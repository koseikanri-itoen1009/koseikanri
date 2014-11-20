-- 顧客追加情報テーブル項目追加スクリプト
ALTER TABLE xxcmm.xxcmm_cust_accounts ADD(
  store_cust_code       VARCHAR2(9)
)
/
COMMENT ON COLUMN xxcmm.xxcmm_cust_accounts.store_cust_code             IS '店舗営業用顧客コード'
/
COMMENT ON COLUMN xxcmm.xxcmm_cust_accounts.latitude                    IS '緯度'
/