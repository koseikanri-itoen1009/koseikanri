-- 顧客一括更新登録ワークテーブル項目追加
ALTER TABLE xxcmm.xxcmm_wk_cust_batch_regist ADD(
  VIST_TARGET_DIV          VARCHAR2(1)
)
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.vist_target_div IS '訪問対象区分'
/
