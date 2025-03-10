ALTER TABLE XXCOK.XXCOK_INFO_WORK_HEADER ADD
(
     bm_payment_kbn                 VARCHAR2(1)
    ,tax_calc_kbn                   VARCHAR2(1)
    ,bm_tax_kbn                     VARCHAR2(1)
    ,bank_charge_bearer             VARCHAR2(1)
    ,sales_fee_no_tax               NUMBER(13)
    ,sales_fee_tax                  NUMBER(13)
    ,sales_fee_with_tax             NUMBER(13)
    ,electric_amt_no_tax            NUMBER(13)
    ,electric_amt_tax               NUMBER(13)
    ,electric_amt_with_tax          NUMBER(13)
    ,recalc_total_fee_no_tax        NUMBER(13)
    ,recalc_total_fee_tax           NUMBER(13)
    ,recalc_total_fee_with_tax      NUMBER(13)
    ,bank_trans_fee_no_tax          NUMBER(13)
    ,bank_trans_fee_tax             NUMBER(13)
    ,bank_trans_fee_with_tax        NUMBER(13)
    ,vendor_invoice_regnum          VARCHAR2(30)
)
/
COMMENT ON COLUMN xxcok.xxcok_info_work_header.bm_payment_kbn                          IS 'BMx¥æª'
/
COMMENT ON COLUMN xxcok.xxcok_info_work_header.tax_calc_kbn                            IS 'ÅvZæª'
/
COMMENT ON COLUMN xxcok.xxcok_info_work_header.bm_tax_kbn                              IS 'BMÅæª'
/
COMMENT ON COLUMN xxcok.xxcok_info_work_header.bank_charge_bearer                      IS 'Uè¿SÒ'
/
COMMENT ON COLUMN xxcok.xxcok_info_work_header.sales_fee_no_tax                        IS 'Ìè¿iÅ²j'
/
COMMENT ON COLUMN xxcok.xxcok_info_work_header.sales_fee_tax                           IS 'Ìè¿iÁïÅj'
/
COMMENT ON COLUMN xxcok.xxcok_info_work_header.sales_fee_with_tax                      IS 'Ìè¿iÅj'
/
COMMENT ON COLUMN xxcok.xxcok_info_work_header.electric_amt_no_tax                     IS 'dCãiÅ²j'
/
COMMENT ON COLUMN xxcok.xxcok_info_work_header.electric_amt_tax                        IS 'dCãiÁïÅj'
/
COMMENT ON COLUMN xxcok.xxcok_info_work_header.electric_amt_with_tax                   IS 'dCãiÅj'
/
COMMENT ON COLUMN xxcok.xxcok_info_work_header.recalc_total_fee_no_tax                 IS 'ÄvZÏè¿viÅ²j'
/
COMMENT ON COLUMN xxcok.xxcok_info_work_header.recalc_total_fee_tax                    IS 'ÄvZÏè¿viÁïÅj'
/
COMMENT ON COLUMN xxcok.xxcok_info_work_header.recalc_total_fee_with_tax               IS 'ÄvZÏè¿viÅj'
/
COMMENT ON COLUMN xxcok.xxcok_info_work_header.bank_trans_fee_no_tax                   IS 'Uè¿iÅ²j'
/
COMMENT ON COLUMN xxcok.xxcok_info_work_header.bank_trans_fee_tax                      IS 'Uè¿iÁïÅj'
/
COMMENT ON COLUMN xxcok.xxcok_info_work_header.bank_trans_fee_with_tax                 IS 'Uè¿iÅj'
/
COMMENT ON COLUMN xxcok.xxcok_info_work_header.vendor_invoice_regnum                   IS 'tæC{CXo^Ô'
/
