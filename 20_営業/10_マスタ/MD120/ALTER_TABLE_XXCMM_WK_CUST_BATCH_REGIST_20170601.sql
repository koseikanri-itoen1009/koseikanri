-- �ڋq�ꊇ�X�V�p���[�N���ڒǉ��X�N���v�g
ALTER TABLE xxcmm.xxcmm_wk_cust_batch_regist ADD(
  OFFSET_CUST_CODE        VARCHAR2(30),
  BP_CUSTOMER_CODE        VARCHAR2(100)
)
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.offset_cust_code IS '���E�p�ڋq�R�[�h'
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.bp_customer_code IS '�����ڋq�R�[�h'
/