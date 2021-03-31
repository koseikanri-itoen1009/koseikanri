ALTER TABLE xxcok.xxcok_wholesale_bill_line 
ADD (
      expansion_sales_type          VARCHAR2(1)
     ,difference_amt                NUMBER
     ,selling_date                  DATE
     ,recon_slip_num                VARCHAR2(20) DEFAULT NULL
)
/
COMMENT ON COLUMN xxcok.xxcok_wholesale_bill_line.expansion_sales_type     IS 'ägîÑãÊï™'
/
COMMENT ON COLUMN xxcok.xxcok_wholesale_bill_line.difference_amt           IS 'êøãÅç∑äz(ê≈î≤)'
/
COMMENT ON COLUMN xxcok.xxcok_wholesale_bill_line.selling_date             IS 'îÑè„ëŒè€îNåéì˙'
/
COMMENT ON COLUMN xxcok.xxcok_wholesale_bill_line.recon_slip_num           IS 'éxï•ì`ï[î‘çÜ'
/

