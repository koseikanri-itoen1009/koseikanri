-- �ڋq�ꊇ�X�V�o�^���[�N�e�[�u�����ڒǉ�
ALTER TABLE xxcmm.xxcmm_wk_cust_batch_regist ADD(
  INVOICE_CODE            VARCHAR2(9),
  INDUSTRY_DIV            VARCHAR2(2),
  BILL_BASE_CODE          VARCHAR2(4),
  RECEIV_BASE_CODE        VARCHAR2(4),
  DELIVERY_BASE_CODE      VARCHAR2(4),
  SELLING_TRANSFER_DIV    VARCHAR2(1),
  CARD_COMPANY            VARCHAR2(9),
  WHOLESALE_CTRL_CODE     VARCHAR2(9),
  PRICE_LIST              VARCHAR2(240)
)
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.invoice_class IS '����������P��'
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.invoice_code IS '�������p�R�[�h'
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.industry_div IS '�Ǝ�'
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.bill_base_code IS '�������_'
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.receiv_base_code IS '�������_'
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.delivery_base_code IS '�[�i���_'
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.selling_transfer_div IS '������ѐU��'
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.card_company IS '�J�[�h���'
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.wholesale_ctrl_code IS '�≮�Ǘ��R�[�h'
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.price_list IS '���i�\'
/
