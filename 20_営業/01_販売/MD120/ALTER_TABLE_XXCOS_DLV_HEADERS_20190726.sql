ALTER TABLE xxcos.xxcos_dlv_headers ADD(
  discount_tax_class              VARCHAR2(4)                       -- �l���ŋ敪
);
--
COMMENT ON COLUMN xxcos.xxcos_dlv_headers.discount_tax_class   IS '�l���ŋ敪';
