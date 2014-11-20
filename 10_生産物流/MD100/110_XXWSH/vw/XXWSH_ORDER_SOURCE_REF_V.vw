CREATE OR REPLACE VIEW xxwsh_order_source_ref_v
(
  REPORT_POST_CODE,
  EOS_DATA_TYPE,
  ORDER_SOURCE_REF,
  DELIVERY_NO
)
AS
SELECT
    XSHI.REPORT_POST_CODE,
    XSHI.EOS_DATA_TYPE,
    XSHI.ORDER_SOURCE_REF,
    XSHI.DELIVERY_NO
FROM
    XXWSH_SHIPPING_HEADERS_IF XSHI
GROUP BY XSHI.REPORT_POST_CODE,XSHI.EOS_DATA_TYPE,XSHI.ORDER_SOURCE_REF,XSHI.DELIVERY_NO
;
--
COMMENT ON COLUMN xxwsh_order_source_ref_v.report_post_code               IS '報告部署';
COMMENT ON COLUMN xxwsh_order_source_ref_v.eos_data_type                  IS 'EOSデータ種別';
COMMENT ON COLUMN xxwsh_order_source_ref_v.order_source_ref               IS '受注ソース参照';
COMMENT ON COLUMN xxwsh_order_source_ref_v.delivery_no                    IS '配送No';
--
COMMENT ON TABLE  xxwsh_order_source_ref_v IS '受注ソース参照VIEW';
