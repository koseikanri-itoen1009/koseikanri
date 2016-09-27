ALTER TABLE xxcff.xxcff_pay_planning ADD (
     debt_re                        NUMBER(10)
    ,interest_due_re                NUMBER(10)
    ,debt_rem_re                    NUMBER(10)
);
--
COMMENT ON COLUMN xxcff.xxcff_pay_planning.debt_re                                     IS 'リース債務額_再リース';
COMMENT ON COLUMN xxcff.xxcff_pay_planning.interest_due_re                             IS 'リース支払利息_再リース';
COMMENT ON COLUMN xxcff.xxcff_pay_planning.debt_rem_re                                 IS 'リース債務残_再リース';
