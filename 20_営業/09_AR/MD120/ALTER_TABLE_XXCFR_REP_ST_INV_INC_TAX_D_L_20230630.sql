ALTER TABLE xxcfr.xxcfr_rep_st_inv_inc_tax_d_l
ADD (
      store_tax_sum                     NUMBER
     ,tax_sum1                          NUMBER
     ,tax_sum2                          NUMBER
     ,tax_sum3                          NUMBER
     ,invoice_tax_div                   VARCHAR2(1)
     ,tax_amount_sum                    NUMBER
     ,tax_amount_sum2                   NUMBER
     ,inv_amount_sum                    NUMBER
     ,inv_amount_sum2                   NUMBER
     ,invoice_t_no                      VARCHAR2(14)
)
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_d_l.store_tax_sum             IS '����œ�'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_d_l.tax_sum1                  IS '����Ŋz�P'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_d_l.tax_sum2                  IS '����Ŋz�Q'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_d_l.tax_sum3                  IS '����Ŋz�R'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_d_l.invoice_tax_div           IS '����������ŐϏグ�v�Z����'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_d_l.tax_amount_sum            IS '�Ŋz���v�P'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_d_l.tax_amount_sum2           IS '�Ŋz���v�Q'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_d_l.inv_amount_sum            IS '�Ŕ����v�P'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_d_l.inv_amount_sum2           IS '�Ŕ����v�Q'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_d_l.invoice_t_no              IS '�K�i���������s���Ǝғo�^�ԍ�'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_d_l.store_sum                 IS '���������グ�z'
/
