ALTER TABLE XXCMM.XXCMM_WK_CUST_UPLOAD  ADD (
     offset_cust_code               VARCHAR2(30)    -- 相殺用顧客コード
    ,bp_customer_code               VARCHAR2(100)   -- 取引先顧客コード
);
--
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_upload.offset_cust_code                    IS '相殺用顧客コード'
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_upload.bp_customer_code                    IS '取引先顧客コード'
/
