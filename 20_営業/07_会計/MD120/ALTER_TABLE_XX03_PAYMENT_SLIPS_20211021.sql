ALTER TABLE xx03.xx03_payment_slips ADD (
  invoice_ele_data_yes  VARCHAR2(1),
  invoice_ele_data_no   VARCHAR2(1)
);
COMMENT ON COLUMN xx03.xx03_payment_slips.invoice_ele_data_yes IS '請求書電子データ受領あり';
COMMENT ON COLUMN xx03.xx03_payment_slips.invoice_ele_data_no IS '請求書電子データ受領なし';
