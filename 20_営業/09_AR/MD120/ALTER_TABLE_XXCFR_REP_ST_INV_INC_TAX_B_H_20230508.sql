ALTER TABLE xxcfr.xxcfr_rep_st_inv_inc_tax_b_h 
ADD (
      tax_sum1                            NUMBER
     ,tax_sum2                            NUMBER
     ,tax_sum3                            NUMBER
     ,ex_tax_charge_header                NUMBER
     ,tax_sum_header                      NUMBER
     ,invoice_t_no                        VARCHAR2(14)
)
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_b_h.tax_sum1                      IS '����Ŋz�P'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_b_h.tax_sum2                      IS '����Ŋz�Q'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_b_h.tax_sum3                      IS '����Ŋz�R'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_b_h.ex_tax_charge_header          IS '�w�b�_�[�p���������グ�z'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_b_h.tax_sum_header                IS '�w�b�_�[�p����Ŋz'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_b_h.invoice_t_no                  IS '�K�i���������s���Ǝғo�^�ԍ�'
/

