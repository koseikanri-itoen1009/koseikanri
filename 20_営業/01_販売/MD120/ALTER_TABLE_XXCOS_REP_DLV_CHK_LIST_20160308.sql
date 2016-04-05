ALTER TABLE XXCOS.XXCOS_REP_DLV_CHK_LIST ADD(
  TOTAL_SALES_AMT              NUMBER(8,0),                    --総販売金額
  CASH_CARD_SALES_AMT          NUMBER(9,0),                    --現金・カード販売金額
  OUTPUT_TYPE                  VARCHAR2(1),                    --出力区分
  NO_DATA_MESSAGE              VARCHAR2(40)                    --0件メッセージ
);
--
COMMENT ON COLUMN XXCOS.XXCOS_REP_DLV_CHK_LIST.TOTAL_SALES_AMT                 IS '総販売金額';
COMMENT ON COLUMN XXCOS.XXCOS_REP_DLV_CHK_LIST.CASH_CARD_SALES_AMT             IS '現金・カード販売金額';
COMMENT ON COLUMN XXCOS.XXCOS_REP_DLV_CHK_LIST.OUTPUT_TYPE                     IS '出力区分';
COMMENT ON COLUMN XXCOS.XXCOS_REP_DLV_CHK_LIST.NO_DATA_MESSAGE                 IS '0件メッセージ';
