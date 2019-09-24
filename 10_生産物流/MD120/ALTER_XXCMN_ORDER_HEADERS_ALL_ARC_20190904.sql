-- 受注ヘッダアドオン項目追加スクリプト
ALTER TABLE xxcmn.xxcmn_order_headers_all_arc ADD (
  sikyu_return_date  DATE
)
/
COMMENT ON COLUMN xxcmn.xxcmn_order_headers_all_arc.sikyu_return_date  IS '有償支給年月(返品)';
/
