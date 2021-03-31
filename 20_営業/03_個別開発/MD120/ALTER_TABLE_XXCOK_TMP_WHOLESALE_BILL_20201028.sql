ALTER TABLE xxcok.xxcok_tmp_wholesale_bill
ADD (
      selling_date                  VARCHAR2(100)
     ,expansion_sales_type          VARCHAR2(100)
     ,difference_amt                VARCHAR2(100)
)
/
COMMENT ON COLUMN xxcok.xxcok_tmp_wholesale_bill.selling_date             IS '”„ã‘ÎÛ”NŒ“ú'
/
COMMENT ON COLUMN xxcok.xxcok_tmp_wholesale_bill.expansion_sales_type     IS 'Šg”„‹æ•ª'
/
COMMENT ON COLUMN xxcok.xxcok_tmp_wholesale_bill.difference_amt           IS '¿‹·Šz(Å”²)'
/
