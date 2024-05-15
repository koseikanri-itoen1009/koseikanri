ALTER TABLE xxcok.xxcok_xxcok024a06c_temp
ADD (
   company              VARCHAR2(3)
  ,debt_account         VARCHAR2(150)
  ,debt_sub_account     VARCHAR2(150)
);

alter table xxcok.xxcok_xxcok024a06c_temp drop column past_sale_base_code;

COMMENT ON COLUMN xxcok.xxcok_xxcok024a06c_temp.company               IS '‰ïĞ';
COMMENT ON COLUMN xxcok.xxcok_xxcok024a06c_temp.accounting_base       IS '•”–å';
COMMENT ON COLUMN xxcok.xxcok_xxcok024a06c_temp.debt_account          IS 'Š¨’è‰È–Ú(•‰Â)';
COMMENT ON COLUMN xxcok.xxcok_xxcok024a06c_temp.debt_sub_account      IS '•â•‰È–Ú(•‰Â)';
