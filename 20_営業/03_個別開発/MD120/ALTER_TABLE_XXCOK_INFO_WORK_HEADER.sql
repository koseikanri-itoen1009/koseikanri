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
COMMENT ON COLUMN xxcok.xxcok_info_work_header.bm_payment_kbn                          IS 'BM�x���敪'
/
COMMENT ON COLUMN xxcok.xxcok_info_work_header.tax_calc_kbn                            IS '�Ōv�Z�敪'
/
COMMENT ON COLUMN xxcok.xxcok_info_work_header.bm_tax_kbn                              IS 'BM�ŋ敪'
/
COMMENT ON COLUMN xxcok.xxcok_info_work_header.bank_charge_bearer                      IS '�U���萔�����S��'
/
COMMENT ON COLUMN xxcok.xxcok_info_work_header.sales_fee_no_tax                        IS '�̔��萔���i�Ŕ��j'
/
COMMENT ON COLUMN xxcok.xxcok_info_work_header.sales_fee_tax                           IS '�̔��萔���i����Łj'
/
COMMENT ON COLUMN xxcok.xxcok_info_work_header.sales_fee_with_tax                      IS '�̔��萔���i�ō��j'
/
COMMENT ON COLUMN xxcok.xxcok_info_work_header.electric_amt_no_tax                     IS '�d�C�㓙�i�Ŕ��j'
/
COMMENT ON COLUMN xxcok.xxcok_info_work_header.electric_amt_tax                        IS '�d�C�㓙�i����Łj'
/
COMMENT ON COLUMN xxcok.xxcok_info_work_header.electric_amt_with_tax                   IS '�d�C�㓙�i�ō��j'
/
COMMENT ON COLUMN xxcok.xxcok_info_work_header.recalc_total_fee_no_tax                 IS '�Čv�Z�ώ萔���v�i�Ŕ��j'
/
COMMENT ON COLUMN xxcok.xxcok_info_work_header.recalc_total_fee_tax                    IS '�Čv�Z�ώ萔���v�i����Łj'
/
COMMENT ON COLUMN xxcok.xxcok_info_work_header.recalc_total_fee_with_tax               IS '�Čv�Z�ώ萔���v�i�ō��j'
/
COMMENT ON COLUMN xxcok.xxcok_info_work_header.bank_trans_fee_no_tax                   IS '�U���萔���i�Ŕ��j'
/
COMMENT ON COLUMN xxcok.xxcok_info_work_header.bank_trans_fee_tax                      IS '�U���萔���i����Łj'
/
COMMENT ON COLUMN xxcok.xxcok_info_work_header.bank_trans_fee_with_tax                 IS '�U���萔���i�ō��j'
/
COMMENT ON COLUMN xxcok.xxcok_info_work_header.vendor_invoice_regnum                   IS '���t��C���{�C�X�o�^�ԍ�'
/
