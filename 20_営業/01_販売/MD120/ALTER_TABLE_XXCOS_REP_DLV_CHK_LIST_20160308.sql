ALTER TABLE XXCOS.XXCOS_REP_DLV_CHK_LIST ADD(
  TOTAL_SALES_AMT              NUMBER(8,0),                    --���̔����z
  CASH_CARD_SALES_AMT          NUMBER(9,0),                    --�����E�J�[�h�̔����z
  OUTPUT_TYPE                  VARCHAR2(1),                    --�o�͋敪
  NO_DATA_MESSAGE              VARCHAR2(40)                    --0�����b�Z�[�W
);
--
COMMENT ON COLUMN XXCOS.XXCOS_REP_DLV_CHK_LIST.TOTAL_SALES_AMT                 IS '���̔����z';
COMMENT ON COLUMN XXCOS.XXCOS_REP_DLV_CHK_LIST.CASH_CARD_SALES_AMT             IS '�����E�J�[�h�̔����z';
COMMENT ON COLUMN XXCOS.XXCOS_REP_DLV_CHK_LIST.OUTPUT_TYPE                     IS '�o�͋敪';
COMMENT ON COLUMN XXCOS.XXCOS_REP_DLV_CHK_LIST.NO_DATA_MESSAGE                 IS '0�����b�Z�[�W';
