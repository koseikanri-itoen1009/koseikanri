ALTER TABLE xxcos.xxcos_rep_order_err_list  ADD (
  shop_name_alt             VARCHAR2(20)
);
--
COMMENT ON COLUMN XXCOS.XXCOS_EDI_ERRORS.SHOP_NAME_ALT                               IS  '店舗名称（カナ）';
