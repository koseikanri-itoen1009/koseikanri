-- 自動販売機設置契約書帳票ワークテーブル項目追加
ALTER TABLE xxcso.xxcso_rep_auto_sale_cont ADD(
  condition_contents_13   VARCHAR2(150)
 ,condition_contents_14   VARCHAR2(150)
 ,condition_contents_15   VARCHAR2(150)
 ,condition_contents_16   VARCHAR2(150)
 ,condition_contents_17   VARCHAR2(150)
);
--
COMMENT ON COLUMN xxcso.xxcso_rep_auto_sale_cont.condition_contents_13 IS '条件内容13';
COMMENT ON COLUMN xxcso.xxcso_rep_auto_sale_cont.condition_contents_14 IS '条件内容14';
COMMENT ON COLUMN xxcso.xxcso_rep_auto_sale_cont.condition_contents_15 IS '条件内容15';
COMMENT ON COLUMN xxcso.xxcso_rep_auto_sale_cont.condition_contents_16 IS '条件内容16';
COMMENT ON COLUMN xxcso.xxcso_rep_auto_sale_cont.condition_contents_17 IS '条件内容17';
