-- 顧客一括更新登録ワークテーブル項目追加
ALTER TABLE xxcmm.xxcmm_wk_cust_batch_regist ADD(
  INVOICE_CODE            VARCHAR2(9),
  INDUSTRY_DIV            VARCHAR2(2),
  BILL_BASE_CODE          VARCHAR2(4),
  RECEIV_BASE_CODE        VARCHAR2(4),
  DELIVERY_BASE_CODE      VARCHAR2(4),
  SELLING_TRANSFER_DIV    VARCHAR2(1),
  CARD_COMPANY            VARCHAR2(9),
  WHOLESALE_CTRL_CODE     VARCHAR2(9),
  PRICE_LIST              VARCHAR2(240)
)
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.invoice_class IS '請求書印刷単位'
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.invoice_code IS '請求書用コード'
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.industry_div IS '業種'
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.bill_base_code IS '請求拠点'
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.receiv_base_code IS '入金拠点'
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.delivery_base_code IS '納品拠点'
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.selling_transfer_div IS '売上実績振替'
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.card_company IS 'カード会社'
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.wholesale_ctrl_code IS '問屋管理コード'
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.price_list IS '価格表'
/
