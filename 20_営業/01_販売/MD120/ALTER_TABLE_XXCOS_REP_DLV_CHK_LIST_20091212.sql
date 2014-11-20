ALTER TABLE XXCOS.XXCOS_REP_DLV_CHK_LIST  ADD (
                                               VISIT_TIME               VARCHAR2(5),   --ñKñ‚éûä‘
                                               DLV_INVOICE_LINE_NUMBER  NUMBER         --î[ïiñæç◊î‘çÜ
                                                );
--
COMMENT ON COLUMN XXCOS.XXCOS_REP_DLV_CHK_LIST.VISIT_TIME                      IS 'ñKñ‚éûä‘';
COMMENT ON COLUMN XXCOS.XXCOS_REP_DLV_CHK_LIST.DLV_INVOICE_LINE_NUMBER         IS 'î[ïiñæç◊î‘çÜ';
