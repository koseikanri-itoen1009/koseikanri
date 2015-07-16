-- 営業成績表帳票ワークテーブル項目追加スクリプト
ALTER TABLE xxcos.xxcos_rep_bus_perf ADD (
  gl_cl_char                    VARCHAR2(4)
)
/
COMMENT ON COLUMN xxcos.xxcos_rep_bus_perf.gl_cl_char                   IS 'GL確定印字文字';
/
