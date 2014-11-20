ALTER TABLE xxcff.xxcff_contract_histories ADD (
   update_reason VARCHAR2(100)
  ,period_name   VARCHAR2(7)
);
--
COMMENT ON COLUMN xxcff.xxcff_contract_histories.update_reason  IS  '更新事由';
COMMENT ON COLUMN xxcff.xxcff_contract_histories.period_name    IS  '会計期間';
