ALTER TABLE xxcos.xxcos_sales_exp_headers ADD (
                    item_sales_send_flag  VARCHAR2(1),    -- ���i�ʔ̔����ё��M�σt���O
                    item_sales_send_date  DATE            -- ���i�ʔ̔����ё��M��
)
;

COMMENT ON COLUMN xxcos.xxcos_sales_exp_headers.item_sales_send_flag IS '���i�ʔ̔����ё��M�σt���O'
;
COMMENT ON COLUMN xxcos.xxcos_sales_exp_headers.item_sales_send_date IS '���i�ʔ̔����ё��M��'
;