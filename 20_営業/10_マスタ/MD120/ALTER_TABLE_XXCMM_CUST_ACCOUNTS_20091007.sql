-- �ڋq�ǉ����e�[�u�����ڒǉ��X�N���v�g
ALTER TABLE xxcmm.xxcmm_cust_accounts ADD(
  invoice_printing_unit       VARCHAR2(1),
  invoice_code                VARCHAR2(9),
  enclose_invoice_code        VARCHAR2(9)
)
/
COMMENT ON COLUMN xxcmm.xxcmm_cust_accounts.invoice_printing_unit       IS '����������P��'
/
COMMENT ON COLUMN xxcmm.xxcmm_cust_accounts.invoice_code                IS '�������p�R�[�h'
/
COMMENT ON COLUMN xxcmm.xxcmm_cust_accounts.enclose_invoice_code        IS '�����������p�R�[�h'
/