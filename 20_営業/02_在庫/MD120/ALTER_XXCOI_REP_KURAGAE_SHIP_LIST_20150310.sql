-- 倉替出庫明細リスト帳票ワークテーブル項目追加スクリプト
ALTER TABLE xxcoi.xxcoi_rep_kuragae_ship_list ADD (
  inv_cl_char                    VARCHAR2(4)
)
/
COMMENT ON COLUMN xxcoi.xxcoi_rep_kuragae_ship_list.inv_cl_char                   IS '在庫確定印字文字';
/
