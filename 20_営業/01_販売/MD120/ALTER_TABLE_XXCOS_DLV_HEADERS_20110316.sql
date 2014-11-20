ALTER TABLE XXCOS.XXCOS_DLV_HEADERS  ADD (
                                          ORDER_NUMBER  VARCHAR2(16)         --オーダーNo
                                         );
--
COMMENT ON COLUMN XXCOS.XXCOS_DLV_HEADERS.ORDER_NUMBER                    IS 'オーダーNo';