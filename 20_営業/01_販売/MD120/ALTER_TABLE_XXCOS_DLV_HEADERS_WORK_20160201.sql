ALTER TABLE XXCOS.XXCOS_DLV_HEADERS_WORK ADD(
  TOTAL_SALES_AMT              NUMBER(8),                      -- ���̔����z
  CASH_TOTAL_SALES_AMT         NUMBER(8),                      -- ��������g�[�^���̔����z
  PPCARD_TOTAL_SALES_AMT       NUMBER(8),                      -- PP�J�[�h�g�[�^���̔����z
  IDCARD_TOTAL_SALES_AMT       NUMBER(8)                       -- ID�J�[�h�g�[�^���̔����z
);
--
COMMENT ON COLUMN XXCOS.XXCOS_DLV_HEADERS_WORK.TOTAL_SALES_AMT           IS '���̔����z';
COMMENT ON COLUMN XXCOS.XXCOS_DLV_HEADERS_WORK.CASH_TOTAL_SALES_AMT      IS '��������g�[�^���̔����z';
COMMENT ON COLUMN XXCOS.XXCOS_DLV_HEADERS_WORK.PPCARD_TOTAL_SALES_AMT    IS 'PP�J�[�h�g�[�^���̔����z';
COMMENT ON COLUMN XXCOS.XXCOS_DLV_HEADERS_WORK.IDCARD_TOTAL_SALES_AMT    IS 'ID�J�[�h�g�[�^���̔����z';
