ALTER TABLE xxcfr.xxcfr_rep_st_inv_inc_tax_a_l 
ADD (
      invoice_tax_div                     VARCHAR2(1)
     ,tax_amount_sum                      NUMBER
     ,tax_amount_sum2                     NUMBER
     ,inv_amount_sum                      NUMBER
     ,inv_amount_sum2                     NUMBER
     ,invoice_t_no                        VARCHAR2(14)
)
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_a_l.invoice_tax_div                IS '����������ŐϏグ�v�Z����'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_a_l.tax_amount_sum                 IS '�Ŋz���v�P'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_a_l.tax_amount_sum2                IS '�Ŋz���v�Q'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_a_l.inv_amount_sum                 IS '�Ŕ����v�P'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_a_l.inv_amount_sum2                IS '�Ŕ����v�Q'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_a_l.invoice_t_no                   IS '�K�i���������s���Ǝғo�^�ԍ�'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_inc_tax_a_l.store_sum                      IS '�����������z�i�ō��j'
/
