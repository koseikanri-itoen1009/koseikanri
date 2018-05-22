ALTER TABLE xxcso.xxcso_sp_decision_headers ADD(
  construction_start_year         NUMBER(4,0),  -- 工期開始（年）
  construction_start_month        NUMBER(2,0),  -- 工期開始（月）
  construction_end_year           NUMBER(4,0),  -- 工期終了（年）
  construction_end_month          NUMBER(2,0),  -- 工期終了（月）
  Installation_start_year         NUMBER(4,0),  -- 設置見込み期間開始（年）
  Installation_start_month        NUMBER(2,0),  -- 設置見込み期間開始（月）
  Installation_end_year           NUMBER(4,0),  -- 設置見込み期間終了（年）
  Installation_end_month          NUMBER(2,0)   -- 設置見込み期間終了（月）
);
--
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.construction_start_year       IS '工期開始（年）';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.construction_start_month      IS '工期開始（月）';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.construction_end_year         IS '工期終了（年）';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.construction_end_month        IS '工期終了（月）';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.Installation_start_year       IS '設置見込み期間開始（年）';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.Installation_start_month      IS '設置見込み期間開始（月）';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.Installation_end_year         IS '設置見込み期間終了（年）';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.Installation_end_month        IS '設置見込み期間終了（月）';
