-- �ڋq�ǉ����e�[�u�����ڒǉ��X�N���v�g
ALTER TABLE xxcmm.xxcmm_cust_accounts ADD(
    bp_customer_code            VARCHAR2(15),
    offset_cust_code            VARCHAR2(9),
    offset_cust_div             VARCHAR2(1)
)
/
COMMENT ON COLUMN xxcmm.xxcmm_cust_accounts.bp_customer_code            IS '�����ڋq�R�[�h'
/
COMMENT ON COLUMN xxcmm.xxcmm_cust_accounts.offset_cust_code            IS '���E�p�ڋq�R�[�h'
/
COMMENT ON COLUMN xxcmm.xxcmm_cust_accounts.offset_cust_div             IS '���E�p�ڋq�敪'
/