-- 顧客一括更新登録ワークテーブル項目追加
ALTER TABLE xxcmm.xxcmm_wk_cust_batch_regist ADD(
  INVOICE_TAX_DIV          VARCHAR2(1)
)
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.invoice_tax_div IS '請求書消費税積上げ計算方式'
/
