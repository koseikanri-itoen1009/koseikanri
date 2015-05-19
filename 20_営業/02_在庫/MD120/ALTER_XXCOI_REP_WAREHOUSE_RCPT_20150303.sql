-- 受払残高表帳票（倉庫・預け先）帳票ワークテーブル項目追加スクリプト
ALTER TABLE xxcoi.xxcoi_rep_warehouse_rcpt ADD (
  inv_cl_char                    VARCHAR2(4)
)
/
COMMENT ON COLUMN xxcoi.xxcoi_rep_warehouse_rcpt.inv_cl_char                     IS '在庫確定印字文字';
/
