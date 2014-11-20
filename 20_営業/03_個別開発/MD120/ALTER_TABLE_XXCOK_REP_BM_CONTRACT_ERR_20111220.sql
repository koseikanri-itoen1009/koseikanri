ALTER TABLE xxcok.xxcok_rep_bm_contract_err
ADD(
   p_cust_code     VARCHAR2(9)
)
/
COMMENT ON COLUMN xxcok.xxcok_rep_bm_contract_err.p_cust_code              IS '顧客コード(入力パラメータ)'
/
