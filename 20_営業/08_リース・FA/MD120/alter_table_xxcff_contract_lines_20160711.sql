ALTER TABLE xxcff.xxcff_contract_lines ADD (
    original_cost_type1           NUMBER(13)
   ,original_cost_type2           NUMBER(13)
);
--
COMMENT ON COLUMN xxcff.xxcff_contract_lines.original_cost_type1                      IS '���[�X���z_���_��';
COMMENT ON COLUMN xxcff.xxcff_contract_lines.original_cost_type2                      IS '���[�X���z_�ă��[�X';
