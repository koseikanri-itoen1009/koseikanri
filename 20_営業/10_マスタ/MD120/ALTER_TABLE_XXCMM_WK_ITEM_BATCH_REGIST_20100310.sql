-- 品目一括登録ワークテーブル項目追加スクリプト
ALTER TABLE xxcmm.xxcmm_wk_item_batch_regist ADD(
  apply_date       VARCHAR2(100)
)
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_item_batch_regist.apply_date IS '適用開始日'
/