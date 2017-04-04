-- 顧客追加情報テーブル項目追加スクリプト
ALTER TABLE xxcmm.xxcmm_cust_accounts ADD(
  esm_target_div              VARCHAR2(1)
)
/
COMMENT ON COLUMN xxcmm.xxcmm_cust_accounts.esm_target_div       IS 'ストレポ＆商談くん連携対象フラグ'
/
