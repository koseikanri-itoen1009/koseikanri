ALTER TABLE xxcfr.xxcfr_rep_st_inv_d_h
ADD (
      target_date                       VARCHAR2(10)
     ,ar_concat_text                    VARCHAR2(80)
     ,ex_tax_charge_header              NUMBER
     ,tax_sum_header                    NUMBER
     ,payment_due_date                  VARCHAR2(20)
     ,category1                         VARCHAR2(30)
     ,category2                         VARCHAR2(30)
     ,category3                         VARCHAR2(30)
     ,ex_tax_charge1                    NUMBER
     ,ex_tax_charge2                    NUMBER
     ,ex_tax_charge3                    NUMBER
     ,tax_sum1                          NUMBER
     ,tax_sum2                          NUMBER
     ,tax_sum3                          NUMBER
     ,ship_cust_code                    VARCHAR2(30)
     ,ship_cust_name                    VARCHAR2(360)
     ,store_code                        VARCHAR2(10)
     ,store_code_sort                   VARCHAR2(10)
     ,ship_account_number               VARCHAR2(30)
     ,store_charge_sum                  NUMBER
     ,store_tax_sum                     NUMBER
     ,invoice_t_no                      VARCHAR2(14)
)
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_d_h.target_date                        IS '�Ώ۔N��'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_d_h.ar_concat_text                     IS '���|�Ǘ��R�[�h�A��������'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_d_h.ex_tax_charge_header               IS '�w�b�_�[�p���������グ�z'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_d_h.tax_sum_header                     IS '�w�b�_�[�p����Ŋz'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_d_h.payment_due_date                   IS '�����\���'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_d_h.category1                          IS '���󕪗ނP'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_d_h.category2                          IS '���󕪗ނQ'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_d_h.category3                          IS '���󕪗ނR'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_d_h.ex_tax_charge1                     IS '���������グ�z�P'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_d_h.ex_tax_charge2                     IS '���������グ�z�Q'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_d_h.ex_tax_charge3                     IS '���������グ�z�R'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_d_h.tax_sum1                           IS '����Ŋz�P'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_d_h.tax_sum2                           IS '����Ŋz�Q'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_d_h.tax_sum3                           IS '����Ŋz�R'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_d_h.ship_cust_code                     IS '�[�i��ڋq�R�[�h'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_d_h.ship_cust_name                     IS '�[�i��ڋq��'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_d_h.store_code                         IS '�X�܃R�[�h'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_d_h.store_code_sort                    IS '�X�܃R�[�h(�\�[�g�p)'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_d_h.ship_account_number                IS '�[�i��ڋq�R�[�h(�\�[�g�p)'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_d_h.store_charge_sum                   IS '�X�܋��z'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_d_h.store_tax_sum                      IS '�X�ܐŊz'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_d_h.invoice_t_no                       IS '�K�i���������s���Ǝғo�^�ԍ�'
/
