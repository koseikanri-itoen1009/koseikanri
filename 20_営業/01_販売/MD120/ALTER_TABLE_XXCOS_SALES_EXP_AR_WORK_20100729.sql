ALTER TABLE XXCOS.XXCOS_SALES_EXP_AR_WORK  ADD (
  SHIP_TO_CUSTOMER_NAME            VARCHAR2(150)        NULL                           -- �ڋq���́y�[�i��z
);
--
COMMENT ON COLUMN XXCOS.XXCOS_SALES_EXP_AR_WORK.SHIP_TO_CUSTOMER_NAME                IS  '�ڋq���́y�[�i��z';
