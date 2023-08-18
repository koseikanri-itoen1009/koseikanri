ALTER TABLE xxcfr.xxcfr_rep_st_invoice_inc_tax_d 
ADD (
      invoice_tax_div                     VARCHAR2(1)
     ,tax_sum1                            NUMBER
     ,tax_sum2                            NUMBER
     ,tax_sum3                            NUMBER
     ,tax_amount_sum                      NUMBER
     ,tax_amount_sum2                     NUMBER
     ,inv_amount_sum                      NUMBER
     ,inv_amount_sum2                     NUMBER
     ,ex_tax_charge_header                NUMBER
     ,tax_sum_header                      NUMBER
     ,invoice_t_no                        VARCHAR2(14)
)
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_inc_tax_d.invoice_tax_div               IS '����������ŐϏグ�v�Z����'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_inc_tax_d.tax_sum1                      IS '����Ŋz�P'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_inc_tax_d.tax_sum2                      IS '����Ŋz�Q'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_inc_tax_d.tax_sum3                      IS '����Ŋz�R'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_inc_tax_d.tax_amount_sum                IS '�Ŋz���v�P'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_inc_tax_d.tax_amount_sum2               IS '�Ŋz���v�Q'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_inc_tax_d.inv_amount_sum                IS '�Ŕ����v�P'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_inc_tax_d.inv_amount_sum2               IS '�Ŕ����v�Q'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_inc_tax_d.ex_tax_charge_header          IS '�w�b�_�[�p���������グ�z'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_inc_tax_d.tax_sum_header                IS '�w�b�_�[�p����Ŋz'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_invoice_inc_tax_d.invoice_t_no                  IS '�K�i���������s���Ǝғo�^�ԍ�'
/

