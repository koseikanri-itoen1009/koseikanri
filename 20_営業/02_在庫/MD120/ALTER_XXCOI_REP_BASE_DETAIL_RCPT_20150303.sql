-- 受払残高票（拠点別・合計）帳票ワークテーブル項目追加スクリプト
ALTER TABLE xxcoi.xxcoi_rep_base_detail_rcpt ADD (
  inv_cl_char                    VARCHAR2(4)
)
/
COMMENT ON COLUMN xxcoi.xxcoi_rep_base_detail_rcpt.inv_cl_char                   IS '在庫確定印字文字';
/
