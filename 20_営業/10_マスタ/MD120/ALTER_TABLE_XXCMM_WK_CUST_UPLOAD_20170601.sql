ALTER TABLE XXCMM.XXCMM_WK_CUST_UPLOAD  ADD (
     offset_cust_code               VARCHAR2(30)    -- ���E�p�ڋq�R�[�h
    ,bp_customer_code               VARCHAR2(100)   -- �����ڋq�R�[�h
);
--
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_upload.offset_cust_code                    IS '���E�p�ڋq�R�[�h'
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_upload.bp_customer_code                    IS '�����ڋq�R�[�h'
/
