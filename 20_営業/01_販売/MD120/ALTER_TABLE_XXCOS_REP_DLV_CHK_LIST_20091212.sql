ALTER TABLE XXCOS.XXCOS_REP_DLV_CHK_LIST  ADD (
                                               VISIT_TIME               VARCHAR2(5),   --訪問時間
                                               DLV_INVOICE_LINE_NUMBER  NUMBER         --納品明細番号
                                                );
--
COMMENT ON COLUMN XXCOS.XXCOS_REP_DLV_CHK_LIST.VISIT_TIME                      IS '訪問時間';
COMMENT ON COLUMN XXCOS.XXCOS_REP_DLV_CHK_LIST.DLV_INVOICE_LINE_NUMBER         IS '納品明細番号';
