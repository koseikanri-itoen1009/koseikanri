-- �ڋq�ǉ����e�[�u�����ڒǉ��X�N���v�g
ALTER TABLE xxcmm.xxcmm_cust_accounts ADD(
  store_cust_code       VARCHAR2(9)
)
/
COMMENT ON COLUMN xxcmm.xxcmm_cust_accounts.store_cust_code             IS '�X�܉c�Ɨp�ڋq�R�[�h'
/
COMMENT ON COLUMN xxcmm.xxcmm_cust_accounts.latitude                    IS '�ܓx'
/