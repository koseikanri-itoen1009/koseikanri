ALTER TABLE XXCOS.XXCOS_DLV_HEADERS_WORK  ADD (
                                               ORDER_NUMBER  VARCHAR2(16)         --オーダーNo
                                              );
--
COMMENT ON COLUMN XXCOS.XXCOS_DLV_HEADERS_WORK.ORDER_NUMBER                    IS 'オーダーNo';