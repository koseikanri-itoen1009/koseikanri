ALTER TABLE XXCOS.XXCOS_VD_COLUMN_HEADERS ADD(
  TOTAL_SALES_AMT              NUMBER(8),                      -- Ìàz
  CASH_TOTAL_SALES_AMT         NUMBER(8),                      -- »àèg[^Ìàz
  PPCARD_TOTAL_SALES_AMT       NUMBER(8),                      -- PPJ[hg[^Ìàz
  IDCARD_TOTAL_SALES_AMT       NUMBER(8),                      -- IDJ[hg[^Ìàz
  HHT_RECEIVED_FLAG            VARCHAR2(1)                     -- HHTóMtO
);
--
COMMENT ON COLUMN XXCOS.XXCOS_VD_COLUMN_HEADERS.TOTAL_SALES_AMT               IS 'Ìàz';
COMMENT ON COLUMN XXCOS.XXCOS_VD_COLUMN_HEADERS.CASH_TOTAL_SALES_AMT          IS '»àèg[^Ìàz';
COMMENT ON COLUMN XXCOS.XXCOS_VD_COLUMN_HEADERS.PPCARD_TOTAL_SALES_AMT        IS 'PPJ[hg[^Ìàz';
COMMENT ON COLUMN XXCOS.XXCOS_VD_COLUMN_HEADERS.IDCARD_TOTAL_SALES_AMT        IS 'IDJ[hg[^Ìàz';
COMMENT ON COLUMN XXCOS.XXCOS_VD_COLUMN_HEADERS.HHT_RECEIVED_FLAG             IS 'HHTóMtO';
