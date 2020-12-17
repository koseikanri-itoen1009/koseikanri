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
COMMENT ON COLUMN xxcok.xxcok_dedu_trn_rev.sales_deduction_id                          IS '販売控除ID'
/
COMMENT ON COLUMN xxcok.xxcok_dedu_trn_rev.source_line_id                              IS '作成元明細ID'
/
COMMENT ON COLUMN xxcok.xxcok_dedu_trn_rev.condition_id                                IS '控除条件ID'
/
COMMENT ON COLUMN xxcok.xxcok_dedu_trn_rev.condition_no                                IS '控除番号'
/
COMMENT ON COLUMN xxcok.xxcok_dedu_trn_rev.condition_line_id                           IS '控除詳細ID'
/
COMMENT ON COLUMN xxcok.xxcok_dedu_trn_rev.data_type                                   IS 'データ種類'
/
COMMENT ON COLUMN xxcok.xxcok_dedu_trn_rev.compensation                                IS '補填'
/
COMMENT ON COLUMN xxcok.xxcok_dedu_trn_rev.margin                                      IS '問屋マージン'
/
COMMENT ON COLUMN xxcok.xxcok_dedu_trn_rev.sales_promotion_expenses                    IS '拡売'
/
COMMENT ON COLUMN xxcok.xxcok_dedu_trn_rev.margin_reduction                            IS '問屋マージン減額'
/


ALTER TABLE xxcok.xxcok_dedu_trn_rev DROP ( recon_tax_code,
                                            recon_tax_rate);
