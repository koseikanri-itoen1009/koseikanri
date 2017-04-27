-- 顧客一括更新用ワーク項目追加スクリプト
ALTER TABLE xxcmm.xxcmm_wk_cust_batch_regist ADD(
  ESM_TARGET_DIV          VARCHAR2(1)
)
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.esm_target_div IS 'ストレポ＆商談くん連携対象フラグ'
/