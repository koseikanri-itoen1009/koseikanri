ALTER TABLE xxcfr.xxcfr_invoice_headers 
ADD (
      tax_diff_amount_create_flg          VARCHAR2(1)
     ,invoice_tax_div                     VARCHAR2(1)
     ,inv_gap_amount                      NUMBER
     ,tax_rounding_rule                   VARCHAR2(30)
     ,output_format                       VARCHAR2(10)
)
/
COMMENT ON COLUMN xxcfr.xxcfr_invoice_headers.tax_diff_amount_create_flg           IS '����ō��z�쐬�t���O'
/
COMMENT ON COLUMN xxcfr.xxcfr_invoice_headers.invoice_tax_div                      IS '����������ŐϏグ�v�Z����'
/
COMMENT ON COLUMN xxcfr.xxcfr_invoice_headers.inv_gap_amount                       IS '�{�̍��z'
/
COMMENT ON COLUMN xxcfr.xxcfr_invoice_headers.tax_rounding_rule                    IS '�ŋ��|�[������'
/
COMMENT ON COLUMN xxcfr.xxcfr_invoice_headers.output_format                        IS '�������o�͌`��'
/
