ALTER TABLE xxcfr.xxcfr_rep_st_inv_ex_tax_b_l 
ADD (
      invoice_tax_div                     VARCHAR2(1)
     ,tax_amount_sum                      NUMBER
     ,tax_amount_sum2                     NUMBER
     ,invoice_t_no                        VARCHAR2(14)
)
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_ex_tax_b_l.invoice_tax_div                IS '����������ŐϏグ�v�Z����'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_ex_tax_b_l.tax_amount_sum                 IS '�Ŋz���v�P'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_ex_tax_b_l.tax_amount_sum2                IS '�Ŋz���v�Q'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_ex_tax_b_l.invoice_t_no                   IS '�K�i���������s���Ǝғo�^�ԍ�'
/
