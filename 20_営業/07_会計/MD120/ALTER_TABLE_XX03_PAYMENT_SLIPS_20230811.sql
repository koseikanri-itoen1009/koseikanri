ALTER TABLE xx03.xx03_payment_slips ADD (
  invoice_t_num_yes  VARCHAR2(1),
  invoice_t_num_no   VARCHAR2(1)
);
COMMENT ON COLUMN xx03.xx03_payment_slips.invoice_t_num_yes IS '�K�i������(�C���{�C�X)����';
COMMENT ON COLUMN xx03.xx03_payment_slips.invoice_t_num_no IS '�K�i������(�C���{�C�X)�Ȃ�';
