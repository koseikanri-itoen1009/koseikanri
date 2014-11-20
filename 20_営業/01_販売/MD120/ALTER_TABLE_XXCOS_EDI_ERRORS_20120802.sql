ALTER TABLE XXCOS.XXCOS_EDI_ERRORS  ADD (
  SHOP_NAME_ALT                    VARCHAR2(20)        NULL                               -- 店舗名称（カナ）
);
--
COMMENT ON COLUMN XXCOS.XXCOS_EDI_ERRORS.SHOP_NAME_ALT                               IS  '店舗名称（カナ）';
