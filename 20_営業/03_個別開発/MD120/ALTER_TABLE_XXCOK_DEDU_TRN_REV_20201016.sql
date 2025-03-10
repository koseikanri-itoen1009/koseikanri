ALTER TABLE xxcok.xxcok_dedu_trn_rev
ADD(
     sales_deduction_id             NUMBER
    ,source_line_id                 NUMBER
    ,condition_id                   NUMBER
    ,condition_no                   VARCHAR2(12)
    ,condition_line_id              NUMBER
    ,data_type                      VARCHAR2(10)
    ,compensation                   NUMBER(12,2)
    ,margin                         NUMBER(12,2)
    ,sales_promotion_expenses       NUMBER(12,2)
    ,margin_reduction               NUMBER(12,2)
)
/
COMMENT ON COLUMN xxcok.xxcok_dedu_trn_rev.sales_deduction_id                          IS 'ÌTID'
/
COMMENT ON COLUMN xxcok.xxcok_dedu_trn_rev.source_line_id                              IS 'ì¬³¾×ID'
/
COMMENT ON COLUMN xxcok.xxcok_dedu_trn_rev.condition_id                                IS 'TðID'
/
COMMENT ON COLUMN xxcok.xxcok_dedu_trn_rev.condition_no                                IS 'TÔ'
/
COMMENT ON COLUMN xxcok.xxcok_dedu_trn_rev.condition_line_id                           IS 'TÚ×ID'
/
COMMENT ON COLUMN xxcok.xxcok_dedu_trn_rev.data_type                                   IS 'f[^íÞ'
/
COMMENT ON COLUMN xxcok.xxcok_dedu_trn_rev.compensation                                IS 'âU'
/
COMMENT ON COLUMN xxcok.xxcok_dedu_trn_rev.margin                                      IS 'â®}[W'
/
COMMENT ON COLUMN xxcok.xxcok_dedu_trn_rev.sales_promotion_expenses                    IS 'g'
/
COMMENT ON COLUMN xxcok.xxcok_dedu_trn_rev.margin_reduction                            IS 'â®}[W¸z'
/


ALTER TABLE xxcok.xxcok_dedu_trn_rev DROP ( recon_tax_code,
                                            recon_tax_rate);
