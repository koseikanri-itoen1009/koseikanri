ALTER TABLE XXCMM.XXCMM_WK_CUST_UPLOAD  ADD (
   TDB_CODE                 VARCHAR2(20)    -- TDBR[h
  ,BASE_CODE                VARCHAR2(10)    -- {S_
  ,CREDIT_LIMIT             VARCHAR2(10)    -- ^MÀxz
  ,DECIDE_DIV               VARCHAR2(10)    -- »èæª
  ,APPROVAL_DATE            VARCHAR2(30)    -- Ùút
  ,TAX_DIV                  VARCHAR2(10)    -- ÁïÅæª
  ,TAX_ROUNDING_RULE        VARCHAR2(40)    -- Åà[
  ,INVOICE_GRP_CODE         VARCHAR2(160)   -- |R[h1i¿j
  ,OUTPUT_FORM              VARCHAR2(160)   -- ¿oÍ`®
  ,PRT_CYCLE                VARCHAR2(160)   -- ¿­sTCN
  ,PAYMENT_TERM             VARCHAR2(20)    -- x¥ð
  ,DELIVERY_BASE_CODE       VARCHAR2(10)    -- [i_
  ,BILL_BASE_CODE           VARCHAR2(10)    -- ¿_
  ,RECEIV_BASE_CODE         VARCHAR2(10)    -- üà_
  ,SALES_HEAD_BASE_CODE     VARCHAR2(10)    -- Ìæ{S_
);
--
COMMENT ON COLUMN XXCMM.XXCMM_WK_CUST_UPLOAD.TDB_CODE              IS  'TDBR[h';
COMMENT ON COLUMN XXCMM.XXCMM_WK_CUST_UPLOAD.BASE_CODE             IS  '{S_';
COMMENT ON COLUMN XXCMM.XXCMM_WK_CUST_UPLOAD.CREDIT_LIMIT          IS  '^MÀxz';
COMMENT ON COLUMN XXCMM.XXCMM_WK_CUST_UPLOAD.DECIDE_DIV            IS  '»èæª';
COMMENT ON COLUMN XXCMM.XXCMM_WK_CUST_UPLOAD.APPROVAL_DATE         IS  'Ùút';
COMMENT ON COLUMN XXCMM.XXCMM_WK_CUST_UPLOAD.TAX_DIV               IS  'ÁïÅæª';
COMMENT ON COLUMN XXCMM.XXCMM_WK_CUST_UPLOAD.TAX_ROUNDING_RULE     IS  'Åà[';
COMMENT ON COLUMN XXCMM.XXCMM_WK_CUST_UPLOAD.INVOICE_GRP_CODE      IS  '|R[h1i¿j';
COMMENT ON COLUMN XXCMM.XXCMM_WK_CUST_UPLOAD.OUTPUT_FORM           IS  '¿oÍ`®';
COMMENT ON COLUMN XXCMM.XXCMM_WK_CUST_UPLOAD.PRT_CYCLE             IS  '¿­sTCN';
COMMENT ON COLUMN XXCMM.XXCMM_WK_CUST_UPLOAD.PAYMENT_TERM          IS  'x¥ð';
COMMENT ON COLUMN XXCMM.XXCMM_WK_CUST_UPLOAD.DELIVERY_BASE_CODE    IS  '[i_';
COMMENT ON COLUMN XXCMM.XXCMM_WK_CUST_UPLOAD.BILL_BASE_CODE        IS  '¿_';
COMMENT ON COLUMN XXCMM.XXCMM_WK_CUST_UPLOAD.RECEIV_BASE_CODE      IS  'üà_';
COMMENT ON COLUMN XXCMM.XXCMM_WK_CUST_UPLOAD.SALES_HEAD_BASE_CODE  IS  'Ìæ{S_';
