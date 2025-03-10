ALTER TABLE XXCOK.XXCOK_INFO_REV_HEADER ADD
(
     BM_PAYMENT_KBN                 VARCHAR2(1)
    ,TAX_CALC_KBN                   VARCHAR2(1)
    ,BM_TAX_KBN                     VARCHAR2(1)
    ,BANK_CHARGE_BEARER             VARCHAR2(1)
    ,SALES_FEE_NO_TAX               NUMBER(13)
    ,SALES_FEE_TAX                  NUMBER(13)
    ,SALES_FEE_WITH_TAX             NUMBER(13)
    ,ELECTRIC_AMT_NO_TAX            NUMBER(13)
    ,ELECTRIC_AMT_TAX               NUMBER(13)
    ,ELECTRIC_AMT_WITH_TAX          NUMBER(13)
    ,RECALC_TOTAL_FEE_NO_TAX        NUMBER(13)
    ,RECALC_TOTAL_FEE_TAX           NUMBER(13)
    ,RECALC_TOTAL_FEE_WITH_TAX      NUMBER(13)
    ,BANK_TRANS_FEE_NO_TAX          NUMBER(13)
    ,BANK_TRANS_FEE_TAX             NUMBER(13)
    ,BANK_TRANS_FEE_WITH_TAX        NUMBER(13)
    ,VENDOR_INVOICE_REGNUM          VARCHAR2(30)
)
/
COMMENT ON COLUMN XXCOK.XXCOK_INFO_REV_HEADER.BM_PAYMENT_KBN                           IS 'BMx¥æª'
/
COMMENT ON COLUMN XXCOK.XXCOK_INFO_REV_HEADER.TAX_CALC_KBN                             IS 'ÅvZæª'
/
COMMENT ON COLUMN XXCOK.XXCOK_INFO_REV_HEADER.BM_TAX_KBN                               IS 'BMÅæª'
/
COMMENT ON COLUMN XXCOK.XXCOK_INFO_REV_HEADER.BANK_CHARGE_BEARER                       IS 'Uè¿SÒ'
/
COMMENT ON COLUMN XXCOK.XXCOK_INFO_REV_HEADER.SALES_FEE_NO_TAX                         IS 'Ìè¿iÅ²j'
/
COMMENT ON COLUMN XXCOK.XXCOK_INFO_REV_HEADER.SALES_FEE_TAX                            IS 'Ìè¿iÁïÅj'
/
COMMENT ON COLUMN XXCOK.XXCOK_INFO_REV_HEADER.SALES_FEE_WITH_TAX                       IS 'Ìè¿iÅj'
/
COMMENT ON COLUMN XXCOK.XXCOK_INFO_REV_HEADER.ELECTRIC_AMT_NO_TAX                      IS 'dCãiÅ²j'
/
COMMENT ON COLUMN XXCOK.XXCOK_INFO_REV_HEADER.ELECTRIC_AMT_TAX                         IS 'dCãiÁïÅj'
/
COMMENT ON COLUMN XXCOK.XXCOK_INFO_REV_HEADER.ELECTRIC_AMT_WITH_TAX                    IS 'dCãiÅj'
/
COMMENT ON COLUMN XXCOK.XXCOK_INFO_REV_HEADER.RECALC_TOTAL_FEE_NO_TAX                  IS 'ÄvZÏè¿viÅ²j'
/
COMMENT ON COLUMN XXCOK.XXCOK_INFO_REV_HEADER.RECALC_TOTAL_FEE_TAX                     IS 'ÄvZÏè¿viÁïÅj'
/
COMMENT ON COLUMN XXCOK.XXCOK_INFO_REV_HEADER.RECALC_TOTAL_FEE_WITH_TAX                IS 'ÄvZÏè¿viÅj'
/
COMMENT ON COLUMN XXCOK.XXCOK_INFO_REV_HEADER.BANK_TRANS_FEE_NO_TAX                    IS 'Uè¿iÅ²j'
/
COMMENT ON COLUMN XXCOK.XXCOK_INFO_REV_HEADER.BANK_TRANS_FEE_TAX                       IS 'Uè¿iÁïÅj'
/
COMMENT ON COLUMN XXCOK.XXCOK_INFO_REV_HEADER.BANK_TRANS_FEE_WITH_TAX                  IS 'Uè¿iÅj'
/
COMMENT ON COLUMN XXCOK.XXCOK_INFO_REV_HEADER.VENDOR_INVOICE_REGNUM                    IS 'tæC{CXo^Ô'
/
