ALTER TABLE xxcok.xxcok_condition_recovery_temp
ADD(
     compensation_en_3              NUMBER
    ,wholesale_margin_en_3          NUMBER
    ,just_condition_en_4            NUMBER
    ,wholesale_adj_margin_en_4      NUMBER
)
/
COMMENT ON COLUMN xxcok.xxcok_condition_recovery_temp.compensation_en_3                IS '��U(�~)'
/
COMMENT ON COLUMN xxcok.xxcok_condition_recovery_temp.wholesale_margin_en_3            IS '�≮�}�[�W��(�~)'
/
COMMENT ON COLUMN xxcok.xxcok_condition_recovery_temp.just_condition_en_4              IS '�������(�~)'
/
COMMENT ON COLUMN xxcok.xxcok_condition_recovery_temp.wholesale_adj_margin_en_4        IS '�≮�}�[�W���C��(�~)'
/
