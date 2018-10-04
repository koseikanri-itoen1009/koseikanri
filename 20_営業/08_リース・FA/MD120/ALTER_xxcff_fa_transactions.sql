ALTER TABLE xxcff.xxcff_fa_transactions ADD (
    tax_charge  NUMBER
  , tax_code    VARCHAR2(4)
)
/
COMMENT ON COLUMN xxcff.xxcff_fa_transactions.tax_charge  IS 'è¡îÔê≈äz';
/
COMMENT ON COLUMN xxcff.xxcff_fa_transactions.tax_code    IS 'ê≈ã‡ÉRÅ[Éh';
/
