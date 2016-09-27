ALTER TABLE xxcff.xxcff_contract_lines_bk ADD (
    original_cost_type1           NUMBER(13)
   ,original_cost_type2           NUMBER(13)
);
--
COMMENT ON COLUMN xxcff.xxcff_contract_lines_bk.original_cost_type1                      IS 'リース負債額_原契約';
COMMENT ON COLUMN xxcff.xxcff_contract_lines_bk.original_cost_type2                      IS 'リース負債額_再リース';
