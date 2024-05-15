-- 見積帳票ワークテーブル項目追加
ALTER TABLE xxcso.xxcso_rep_quote_list ADD(
  company_code   VARCHAR2(3)
 ,company_name   VARCHAR2(44)
);
--
COMMENT ON COLUMN xxcso.xxcso_rep_quote_list.company_code IS '会社コード';
COMMENT ON COLUMN xxcso.xxcso_rep_quote_list.company_name IS '会社名称';
