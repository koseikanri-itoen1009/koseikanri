ALTER TABLE XXCOS.XXCOS_SALES_EXP_HEADERS ADD(
  TOTAL_SALES_AMT              NUMBER(8),                      --  総販売金額
  CASH_TOTAL_SALES_AMT         NUMBER(8),                      --  現金売りトータル販売金額
  PPCARD_TOTAL_SALES_AMT       NUMBER(8),                      --  PPカードトータル販売金額
  IDCARD_TOTAL_SALES_AMT       NUMBER(8),                      --  IDカードトータル販売金額
  HHT_RECEIVED_FLAG            VARCHAR2(1)                     --  HHT受信フラグ
);
--
COMMENT ON COLUMN XXCOS.XXCOS_SALES_EXP_HEADERS.TOTAL_SALES_AMT                IS  '総販売金額'                           ;
COMMENT ON COLUMN XXCOS.XXCOS_SALES_EXP_HEADERS.CASH_TOTAL_SALES_AMT           IS  '現金売りトータル販売金額'             ;
COMMENT ON COLUMN XXCOS.XXCOS_SALES_EXP_HEADERS.PPCARD_TOTAL_SALES_AMT         IS  'PPカードトータル販売金額'             ;
COMMENT ON COLUMN XXCOS.XXCOS_SALES_EXP_HEADERS.IDCARD_TOTAL_SALES_AMT         IS  'IDカードトータル販売金額'             ;
COMMENT ON COLUMN XXCOS.XXCOS_SALES_EXP_HEADERS.HHT_RECEIVED_FLAG              IS  'HHT受信フラグ'                        ;
