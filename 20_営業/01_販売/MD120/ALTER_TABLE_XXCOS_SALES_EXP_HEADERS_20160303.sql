ALTER TABLE XXCOS.XXCOS_SALES_EXP_HEADERS ADD(
  TOTAL_SALES_AMT              NUMBER(8),                      --  ���̔����z
  CASH_TOTAL_SALES_AMT         NUMBER(8),                      --  ��������g�[�^���̔����z
  PPCARD_TOTAL_SALES_AMT       NUMBER(8),                      --  PP�J�[�h�g�[�^���̔����z
  IDCARD_TOTAL_SALES_AMT       NUMBER(8),                      --  ID�J�[�h�g�[�^���̔����z
  HHT_RECEIVED_FLAG            VARCHAR2(1)                     --  HHT��M�t���O
);
--
COMMENT ON COLUMN XXCOS.XXCOS_SALES_EXP_HEADERS.TOTAL_SALES_AMT                IS  '���̔����z'                           ;
COMMENT ON COLUMN XXCOS.XXCOS_SALES_EXP_HEADERS.CASH_TOTAL_SALES_AMT           IS  '��������g�[�^���̔����z'             ;
COMMENT ON COLUMN XXCOS.XXCOS_SALES_EXP_HEADERS.PPCARD_TOTAL_SALES_AMT         IS  'PP�J�[�h�g�[�^���̔����z'             ;
COMMENT ON COLUMN XXCOS.XXCOS_SALES_EXP_HEADERS.IDCARD_TOTAL_SALES_AMT         IS  'ID�J�[�h�g�[�^���̔����z'             ;
COMMENT ON COLUMN XXCOS.XXCOS_SALES_EXP_HEADERS.HHT_RECEIVED_FLAG              IS  'HHT��M�t���O'                        ;
