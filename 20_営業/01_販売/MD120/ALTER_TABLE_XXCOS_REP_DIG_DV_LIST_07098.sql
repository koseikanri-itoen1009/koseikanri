ALTER TABLE xxcos.xxcos_rep_dig_dv_list ADD (
                    digestion_due_date  DATE    -- �����v�Z����
)
;
COMMENT ON COLUMN xxcos.xxcos_rep_dig_dv_list.digestion_due_date IS '�����v�Z����'
;
