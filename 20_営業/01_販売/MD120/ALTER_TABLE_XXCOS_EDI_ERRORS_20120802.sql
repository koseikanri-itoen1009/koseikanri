ALTER TABLE XXCOS.XXCOS_EDI_ERRORS  ADD (
  SHOP_NAME_ALT                    VARCHAR2(20)        NULL                               -- �X�ܖ��́i�J�i�j
);
--
COMMENT ON COLUMN XXCOS.XXCOS_EDI_ERRORS.SHOP_NAME_ALT                               IS  '�X�ܖ��́i�J�i�j';
