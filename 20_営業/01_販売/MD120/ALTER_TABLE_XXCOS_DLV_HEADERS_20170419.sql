ALTER TABLE XXCOS.XXCOS_DLV_HEADERS ADD(
  HHT_INPUT_DATE               DATE                       -- HHT入力日
);
--
COMMENT ON COLUMN XXCOS.XXCOS_DLV_HEADERS.HHT_INPUT_DATE            IS 'HHT入力日';
