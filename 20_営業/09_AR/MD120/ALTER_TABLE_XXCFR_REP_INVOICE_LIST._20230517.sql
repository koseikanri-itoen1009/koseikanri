ALTER TABLE xxcfr.xxcfr_rep_invoice_list 
ADD (
      invoice_tax_div                     VARCHAR2(1)
     ,tax_amount_sum1                     NUMBER
     ,tax_amount_sum2                     NUMBER
     ,inv_amount_sum1                     NUMBER
     ,inv_amount_sum2                     NUMBER
     ,invoice_t_no                        VARCHAR2(14)
)
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_invoice_list.invoice_tax_div               IS '����������ŐϏグ�v�Z����'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_invoice_list.tax_amount_sum1               IS '�Ŋz���v�P'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_invoice_list.tax_amount_sum2               IS '�Ŋz���v�Q'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_invoice_list.inv_amount_sum1               IS '�Ŕ����v�P'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_invoice_list.inv_amount_sum2               IS '�Ŕ����v�Q'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_invoice_list.invoice_t_no                  IS '�K�i���������s���Ǝғo�^�ԍ�'
/
