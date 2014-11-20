ALTER TABLE xxcos.xxcos_sales_exp_headers ADD (
                    item_sales_send_flag  VARCHAR2(1),    -- 商品別販売実績送信済フラグ
                    item_sales_send_date  DATE            -- 商品別販売実績送信日
)
;

COMMENT ON COLUMN xxcos.xxcos_sales_exp_headers.item_sales_send_flag IS '商品別販売実績送信済フラグ'
;
COMMENT ON COLUMN xxcos.xxcos_sales_exp_headers.item_sales_send_date IS '商品別販売実績送信日'
;