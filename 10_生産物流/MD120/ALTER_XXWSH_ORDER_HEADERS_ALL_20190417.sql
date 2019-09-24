-- 受注ヘッダアドオン項目追加スクリプト
ALTER TABLE xxwsh.xxwsh_order_headers_all ADD (
  sikyu_return_date  DATE
)
/
COMMENT ON COLUMN xxwsh.xxwsh_order_headers_all.sikyu_return_date  IS '有償支給年月(返品)';
/
