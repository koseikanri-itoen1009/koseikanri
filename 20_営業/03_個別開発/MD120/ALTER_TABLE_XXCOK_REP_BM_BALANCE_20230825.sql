ALTER TABLE XXCOK.XXCOK_REP_BM_BALANCE
 ADD (
  BM_TAX_KBN              VARCHAR2(1),                                 -- BMÅæª
  TAX_CALC_KBN_NAME       VARCHAR2(80),                                -- BMÅvZæª¼
  TAX_CALC_KBN            VARCHAR2(1),                                 -- BMÅvZæª
  INVOICE_T_NO            VARCHAR2(14),                                -- o^Ôix¥æj
  TOTAL_LINETITLE1        VARCHAR2(30),                                -- vs^CgP
  TOTAL_LINETITLE2        VARCHAR2(30),                                -- vs^CgQ
  TOTAL_LINETITLE3        VARCHAR2(30),                                -- vs^CgR
  UNPAID_BALANCE_SUM2     NUMBER,                                      -- vs¢¥cvQ
  UNPAID_BALANCE_SUM3     NUMBER                                       -- vs¢¥cvR
 )
/
COMMENT ON COLUMN XXCOK.XXCOK_REP_BM_BALANCE.BM_TAX_KBN                IS 'BMÅæª'
/
COMMENT ON COLUMN XXCOK.XXCOK_REP_BM_BALANCE.TAX_CALC_KBN_NAME         IS 'BMÅvZæª¼'
/
COMMENT ON COLUMN XXCOK.XXCOK_REP_BM_BALANCE.TAX_CALC_KBN              IS 'BMÅvZæª'
/
COMMENT ON COLUMN XXCOK.XXCOK_REP_BM_BALANCE.INVOICE_T_NO              IS 'o^Ôix¥æj'
/
COMMENT ON COLUMN XXCOK.XXCOK_REP_BM_BALANCE.TOTAL_LINETITLE1          IS 'vs^CgP'
/
COMMENT ON COLUMN XXCOK.XXCOK_REP_BM_BALANCE.TOTAL_LINETITLE2          IS 'vs^CgQ'
/
COMMENT ON COLUMN XXCOK.XXCOK_REP_BM_BALANCE.TOTAL_LINETITLE3          IS 'vs^CgR'
/
COMMENT ON COLUMN XXCOK.XXCOK_REP_BM_BALANCE.UNPAID_BALANCE_SUM2       IS 'vs¢¥cvQ'
/
COMMENT ON COLUMN XXCOK.XXCOK_REP_BM_BALANCE.UNPAID_BALANCE_SUM3       IS 'vs¢¥cvR'
/
