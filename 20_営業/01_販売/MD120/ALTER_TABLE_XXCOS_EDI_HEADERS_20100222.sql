ALTER TABLE XXCOS.XXCOS_EDI_HEADERS  ADD (
  EDI_RECEIVED_DATE DATE NULL  -- EDI受信日
);
--
COMMENT ON COLUMN XXCOS.XXCOS_EDI_HEADERS.EDI_RECEIVED_DATE IS 'EDI受信日';
