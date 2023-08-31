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
COMMENT ON COLUMN xxcok.xxcok_info_work_header.bm_payment_kbn                          IS 'BM支払区分'
/
COMMENT ON COLUMN xxcok.xxcok_info_work_header.tax_calc_kbn                            IS '税計算区分'
/
COMMENT ON COLUMN xxcok.xxcok_info_work_header.bm_tax_kbn                              IS 'BM税区分'
/
COMMENT ON COLUMN xxcok.xxcok_info_work_header.bank_charge_bearer                      IS '振込手数料負担者'
/
COMMENT ON COLUMN xxcok.xxcok_info_work_header.sales_fee_no_tax                        IS '販売手数料（税抜）'
/
COMMENT ON COLUMN xxcok.xxcok_info_work_header.sales_fee_tax                           IS '販売手数料（消費税）'
/
COMMENT ON COLUMN xxcok.xxcok_info_work_header.sales_fee_with_tax                      IS '販売手数料（税込）'
/
COMMENT ON COLUMN xxcok.xxcok_info_work_header.electric_amt_no_tax                     IS '電気代等（税抜）'
/
COMMENT ON COLUMN xxcok.xxcok_info_work_header.electric_amt_tax                        IS '電気代等（消費税）'
/
COMMENT ON COLUMN xxcok.xxcok_info_work_header.electric_amt_with_tax                   IS '電気代等（税込）'
/
COMMENT ON COLUMN xxcok.xxcok_info_work_header.recalc_total_fee_no_tax                 IS '再計算済手数料計（税抜）'
/
COMMENT ON COLUMN xxcok.xxcok_info_work_header.recalc_total_fee_tax                    IS '再計算済手数料計（消費税）'
/
COMMENT ON COLUMN xxcok.xxcok_info_work_header.recalc_total_fee_with_tax               IS '再計算済手数料計（税込）'
/
COMMENT ON COLUMN xxcok.xxcok_info_work_header.bank_trans_fee_no_tax                   IS '振込手数料（税抜）'
/
COMMENT ON COLUMN xxcok.xxcok_info_work_header.bank_trans_fee_tax                      IS '振込手数料（消費税）'
/
COMMENT ON COLUMN xxcok.xxcok_info_work_header.bank_trans_fee_with_tax                 IS '振込手数料（税込）'
/
COMMENT ON COLUMN xxcok.xxcok_info_work_header.vendor_invoice_regnum                   IS '送付先インボイス登録番号'
/
