ALTER TABLE XXCOS.XXCOS_REP_DLV_CHK_LIST  ADD (
                                               VISIT_TIME               VARCHAR2(5),   --�K�⎞��
                                               DLV_INVOICE_LINE_NUMBER  NUMBER         --�[�i���הԍ�
                                                );
--
COMMENT ON COLUMN XXCOS.XXCOS_REP_DLV_CHK_LIST.VISIT_TIME                      IS '�K�⎞��';
COMMENT ON COLUMN XXCOS.XXCOS_REP_DLV_CHK_LIST.DLV_INVOICE_LINE_NUMBER         IS '�[�i���הԍ�';
