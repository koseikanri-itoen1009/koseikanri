ALTER TABLE xx03.xx03_receivable_slips ADD (
  payment_ele_data_yes  VARCHAR2(1),
  payment_ele_data_no   VARCHAR2(1)
);
COMMENT ON COLUMN xx03.xx03_receivable_slips.payment_ele_data_yes IS '�x���ē����d�q�f�[�^��̂���';
COMMENT ON COLUMN xx03.xx03_receivable_slips.payment_ele_data_no IS '�x���ē����d�q�f�[�^��̂Ȃ�';
