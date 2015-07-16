-- 払出明細表（拠点別計）帳票ワークテーブル項目追加スクリプト
ALTER TABLE xxcoi.xxcoi_rep_base_expend ADD (
  inv_cl_char                    VARCHAR2(4)
)
/
COMMENT ON COLUMN xxcoi.xxcoi_rep_base_expend.inv_cl_char                   IS '在庫確定印字文字';
/
