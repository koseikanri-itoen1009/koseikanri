ALTER TABLE xxcfr.xxcfr_rep_st_inv_ex_tax_b_h 
ADD (
      ex_tax_charge_header                NUMBER
     ,tax_sum_header                      NUMBER
     ,invoice_t_no                        VARCHAR2(14)
)
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_ex_tax_b_h.ex_tax_charge_header           IS '�w�b�_�[�p���������グ�z'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_ex_tax_b_h.tax_sum_header                 IS '�w�b�_�[�p����Ŋz'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_ex_tax_b_h.invoice_t_no                   IS '�K�i���������s���Ǝғo�^�ԍ�'
/

