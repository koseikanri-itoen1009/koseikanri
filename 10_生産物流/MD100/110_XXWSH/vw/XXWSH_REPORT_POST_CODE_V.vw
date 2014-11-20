CREATE OR REPLACE VIEW xxwsh_report_post_code_v
(
  REPORT_POST_CODE,
  LOCATION_SHORT_NAME
)
AS
SELECT
    XSHI.REPORT_POST_CODE,
    XLV.LOCATION_SHORT_NAME
FROM
    XXWSH_SHIPPING_HEADERS_IF XSHI,
    XXCMN_LOCATIONS_V XLV
WHERE XSHI.REPORT_POST_CODE = XLV.LOCATION_CODE(+)
GROUP BY XSHI.REPORT_POST_CODE, XLV.LOCATION_SHORT_NAME
;
--
COMMENT ON COLUMN xxwsh_report_post_code_v.report_post_code               IS 'ïÒçêïîèê';
COMMENT ON COLUMN xxwsh_report_post_code_v.location_short_name            IS 'ó™èÃ';
--
COMMENT ON TABLE  xxwsh_report_post_code_v IS 'ïÒçêïîèêVIEW';
