ALTER TABLE XXCOS.XXCOS_REP_DLV_CHK_LIST  ADD (
                                               ORDER_NUMBER  VARCHAR2(16)         --オーダーNo
                                              );
--
COMMENT ON COLUMN XXCOS.XXCOS_REP_DLV_CHK_LIST.ORDER_NUMBER                    IS 'オーダーNo';