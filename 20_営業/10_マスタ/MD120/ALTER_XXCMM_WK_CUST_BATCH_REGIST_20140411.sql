-- 顧客一括更新ワークテーブル項目追加
ALTER TABLE xxcmm.xxcmm_wk_cust_batch_regist ADD(
  SALE_BASE_CODE          VARCHAR2(4),
  ADDRESS_LINES_PHONETIC  VARCHAR2(30),
  ADDRESS4                VARCHAR2(30),
  TAX_DIV                 VARCHAR2(1),
  LONGITUDE               VARCHAR2(20),
  CALENDAR_CODE           VARCHAR2(10),
  RATE                    VARCHAR2(3),
  RECEIV_DISCOUNT_RATE    VARCHAR2(4),
  CONCLUSION_DAY1         VARCHAR2(2),
  CONCLUSION_DAY2         VARCHAR2(2),
  CONCLUSION_DAY3         VARCHAR2(2),
  STORE_CUST_CODE         VARCHAR2(9)
)
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.sale_base_code         IS '売上拠点'
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.address_lines_phonetic IS '電話番号'
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.address4               IS 'FAX'
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.tax_div                IS '消費税区分'
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.longitude              IS 'ピークカット開始時刻'
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.calendar_code          IS '稼働日カレンダ'
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.rate                   IS '消化計算用掛率'
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.receiv_discount_rate   IS '入金値引率'
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.conclusion_day1        IS '消化計算締日1'
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.conclusion_day2        IS '消化計算締日2'
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.conclusion_day3        IS '消化計算締日3'
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.store_cust_code        IS '店舗営業用顧客コード'
/