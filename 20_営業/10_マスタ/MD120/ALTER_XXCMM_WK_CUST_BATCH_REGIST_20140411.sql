-- �ڋq�ꊇ�X�V���[�N�e�[�u�����ڒǉ�
ALTER TABLE xxcmm.xxcmm_wk_cust_batch_regist ADD(
  SALE_BASE_CODE          VARCHAR2(4),
  ADDRESS_LINES_PHONETIC  VARCHAR2(30),
  ADDRESS4                VARCHAR2(30),
  TAX_DIV                 VARCHAR2(1),
  LONGITUDE               VARCHAR2(20),
  CALENDAR_CODE           VARCHAR2(10),
  RATE                    VARCHAR2(3),
  RECEIV_DISCOUNT_RATE    VARCHAR2(4),
  CONCLUSION_DAY1         VARCHAR2(2),
  CONCLUSION_DAY2         VARCHAR2(2),
  CONCLUSION_DAY3         VARCHAR2(2),
  STORE_CUST_CODE         VARCHAR2(9)
)
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.sale_base_code         IS '���㋒�_'
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.address_lines_phonetic IS '�d�b�ԍ�'
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.address4               IS 'FAX'
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.tax_div                IS '����ŋ敪'
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.longitude              IS '�s�[�N�J�b�g�J�n����'
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.calendar_code          IS '�ғ����J�����_'
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.rate                   IS '�����v�Z�p�|��'
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.receiv_discount_rate   IS '�����l����'
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.conclusion_day1        IS '�����v�Z����1'
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.conclusion_day2        IS '�����v�Z����2'
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.conclusion_day3        IS '�����v�Z����3'
/
COMMENT ON COLUMN xxcmm.xxcmm_wk_cust_batch_regist.store_cust_code        IS '�X�܉c�Ɨp�ڋq�R�[�h'
/