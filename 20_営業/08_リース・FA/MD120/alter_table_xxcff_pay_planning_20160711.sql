ALTER TABLE xxcff.xxcff_pay_planning ADD (
     debt_re                        NUMBER(10)
    ,interest_due_re                NUMBER(10)
    ,debt_rem_re                    NUMBER(10)
);
--
COMMENT ON COLUMN xxcff.xxcff_pay_planning.debt_re                                     IS '���[�X���z_�ă��[�X';
COMMENT ON COLUMN xxcff.xxcff_pay_planning.interest_due_re                             IS '���[�X�x������_�ă��[�X';
COMMENT ON COLUMN xxcff.xxcff_pay_planning.debt_rem_re                                 IS '���[�X���c_�ă��[�X';
