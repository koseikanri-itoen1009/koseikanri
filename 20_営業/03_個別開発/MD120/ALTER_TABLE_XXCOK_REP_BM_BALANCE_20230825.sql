ALTER TABLE XXCOK.XXCOK_REP_BM_BALANCE
 ADD (
  BM_TAX_KBN              VARCHAR2(1),                                 -- BM税区分
  TAX_CALC_KBN_NAME       VARCHAR2(80),                                -- BM税計算区分名
  TAX_CALC_KBN            VARCHAR2(1),                                 -- BM税計算区分
  INVOICE_T_NO            VARCHAR2(14),                                -- 登録番号（支払先）
  TOTAL_LINETITLE1        VARCHAR2(30),                                -- 合計行タイトル１
  TOTAL_LINETITLE2        VARCHAR2(30),                                -- 合計行タイトル２
  TOTAL_LINETITLE3        VARCHAR2(30),                                -- 合計行タイトル３
  UNPAID_BALANCE_SUM2     NUMBER,                                      -- 合計行未払残高合計２
  UNPAID_BALANCE_SUM3     NUMBER                                       -- 合計行未払残高合計３
 )
/
COMMENT ON COLUMN XXCOK.XXCOK_REP_BM_BALANCE.BM_TAX_KBN                IS 'BM税区分'
/
COMMENT ON COLUMN XXCOK.XXCOK_REP_BM_BALANCE.TAX_CALC_KBN_NAME         IS 'BM税計算区分名'
/
COMMENT ON COLUMN XXCOK.XXCOK_REP_BM_BALANCE.TAX_CALC_KBN              IS 'BM税計算区分'
/
COMMENT ON COLUMN XXCOK.XXCOK_REP_BM_BALANCE.INVOICE_T_NO              IS '登録番号（支払先）'
/
COMMENT ON COLUMN XXCOK.XXCOK_REP_BM_BALANCE.TOTAL_LINETITLE1          IS '合計行タイトル１'
/
COMMENT ON COLUMN XXCOK.XXCOK_REP_BM_BALANCE.TOTAL_LINETITLE2          IS '合計行タイトル２'
/
COMMENT ON COLUMN XXCOK.XXCOK_REP_BM_BALANCE.TOTAL_LINETITLE3          IS '合計行タイトル３'
/
COMMENT ON COLUMN XXCOK.XXCOK_REP_BM_BALANCE.UNPAID_BALANCE_SUM2       IS '合計行未払残高合計２'
/
COMMENT ON COLUMN XXCOK.XXCOK_REP_BM_BALANCE.UNPAID_BALANCE_SUM3       IS '合計行未払残高合計３'
/
