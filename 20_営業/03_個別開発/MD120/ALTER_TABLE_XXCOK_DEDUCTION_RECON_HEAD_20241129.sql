ALTER TABLE xxcok.xxcok_deduction_recon_head ADD    ( invoice_ele_data  VARCHAR2(1),
                                                      invoice_t_num     VARCHAR2(1));
COMMENT ON COLUMN xxcok.xxcok_deduction_recon_head.invoice_ele_data                    IS '電子データ受領';
COMMENT ON COLUMN xxcok.xxcok_deduction_recon_head.invoice_t_num                       IS '適格請求書';
