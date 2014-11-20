-- 顧客一括更新登録ワークテーブル項目追加
ALTER TABLE xxcmm.xxcmm_wk_cust_batch_regist ADD(
  DELIVERY_ORDER          VARCHAR2(14),
  EDI_DISTRICT_CODE       VARCHAR2(8),
  EDI_DISTRICT_NAME       VARCHAR2(40),
  EDI_DISTRICT_KANA       VARCHAR2(20),
  TSUKAGATAZAIKO_DIV      VARCHAR2(2),
  DELI_CENTER_CODE        VARCHAR2(8),
  DELI_CENTER_NAME        VARCHAR2(20),
  EDI_FORWARD_NUMBER      VARCHAR2(2),
  CUST_STORE_NAME         VARCHAR2(30),
  TORIHIKISAKI_CODE       VARCHAR2(8)
)
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.delivery_order IS '配送順（EDI）'
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.edi_district_code IS 'EDI地区コード（EDI)'
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.edi_district_name IS 'EDI地区名（EDI）'
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.edi_district_kana IS 'EDI地区名カナ（EDI）'
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.tsukagatazaiko_div IS '通過在庫型区分（EDI）'
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.deli_center_code IS 'EDI納品センターコード'
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.deli_center_name IS 'EDI納品センター名'
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.edi_forward_number IS 'EDI伝送追番'
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.cust_store_name IS '顧客店舗名称'
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.torihikisaki_code IS '取引先コード'
/
