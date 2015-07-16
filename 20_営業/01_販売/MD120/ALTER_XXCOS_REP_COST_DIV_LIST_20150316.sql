-- 原価割れチェックリスト帳票ワークテーブル項目追加スクリプト
ALTER TABLE xxcos.xxcos_rep_cost_div_list ADD (
  inv_cl_char                    VARCHAR2(4)
)
/
COMMENT ON COLUMN xxcos.xxcos_rep_cost_div_list.inv_cl_char                   IS '在庫確定印字文字';
/
