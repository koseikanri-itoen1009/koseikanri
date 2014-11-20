CREATE OR REPLACE VIEW xxwsh_eos_data_type_v
(
  REPORT_POST_CODE,
  EOS_DATA_TYPE,
  MEANING
)
AS
SELECT
    XSHI.REPORT_POST_CODE,
    XSHI.EOS_DATA_TYPE,
    XLVV.MEANING
FROM
    XXWSH_SHIPPING_HEADERS_IF XSHI,
    XXCMN_LOOKUP_VALUES_V XLVV
WHERE XSHI.EOS_DATA_TYPE = XLVV.LOOKUP_CODE(+)
AND XLVV.LOOKUP_TYPE(+) = 'XXCMN_D17'
GROUP BY XSHI.REPORT_POST_CODE, XSHI.EOS_DATA_TYPE, XLVV.MEANING
;
--
COMMENT ON COLUMN xxwsh_eos_data_type_v.report_post_code               IS '�񍐕���';
COMMENT ON COLUMN xxwsh_eos_data_type_v.eos_data_type                  IS 'EOS�f�[�^���';
COMMENT ON COLUMN xxwsh_eos_data_type_v.meaning                        IS '�E�v';
--
COMMENT ON TABLE  xxwsh_eos_data_type_v IS 'EOS�f�[�^���VIEW';
