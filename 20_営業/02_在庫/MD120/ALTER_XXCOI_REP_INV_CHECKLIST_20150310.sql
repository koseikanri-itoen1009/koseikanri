-- 棚卸チェックリスト帳票ワークテーブル項目追加スクリプト
ALTER TABLE xxcoi.xxcoi_rep_inv_checklist ADD (
  inv_cl_char                    VARCHAR2(4)
)
/
COMMENT ON COLUMN xxcoi.xxcoi_rep_inv_checklist.inv_cl_char                   IS '在庫確定印字文字';
/
