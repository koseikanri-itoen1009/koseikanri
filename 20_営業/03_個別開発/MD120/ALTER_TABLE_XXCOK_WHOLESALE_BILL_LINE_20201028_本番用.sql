ALTER TABLE xxcok.xxcok_wholesale_bill_line 
ADD (
      expansion_sales_type          VARCHAR2(1)
     ,difference_amt                NUMBER
     ,selling_date                  DATE
     ,recon_slip_num                VARCHAR2(20) DEFAULT NULL
)
/
COMMENT ON COLUMN xxcok.xxcok_wholesale_bill_line.expansion_sales_type     IS '�g���敪'
/
COMMENT ON COLUMN xxcok.xxcok_wholesale_bill_line.difference_amt           IS '�������z(�Ŕ�)'
/
COMMENT ON COLUMN xxcok.xxcok_wholesale_bill_line.selling_date             IS '����Ώ۔N����'
/
COMMENT ON COLUMN xxcok.xxcok_wholesale_bill_line.recon_slip_num           IS '�x���`�[�ԍ�'
/

