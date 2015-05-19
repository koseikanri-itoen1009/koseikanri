-- 受払残高表帳票（営業員）帳票ワークテーブル項目追加スクリプト
ALTER TABLE xxcoi.xxcoi_rep_employee_rcpt ADD (
  inv_cl_char                    VARCHAR2(4)
)
/
COMMENT ON COLUMN xxcoi.xxcoi_rep_employee_rcpt.inv_cl_char                      IS '在庫確定印字文字';
/
