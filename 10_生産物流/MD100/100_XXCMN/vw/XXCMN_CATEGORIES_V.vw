CREATE OR REPLACE VIEW xxcmn_categories_v
(
  structure_id,
  category_set_id,
  category_set_name,
  category_id,
  segment1,
  description
)
AS
  SELECT  mcsb.structure_id,
          mcsb.category_set_id,
          mcst.category_set_name,
          mcb.category_id,
          mcb.segment1,
          mct.description
  FROM    mtl_category_sets_b   mcsb,
          mtl_category_sets_tl  mcst,
          mtl_categories_b      mcb,
          mtl_categories_tl     mct
  WHERE   mcsb.category_set_id  = mcst.category_set_id
  AND     mcst.language         = 'JA'
  AND     mcst.source_lang      = 'JA'
  AND     mcsb.structure_id     = mcb.structure_id
  AND     mcb.category_id       = mct.category_id
  AND     mct.language          = 'JA'
  AND     mct.source_lang       = 'JA'
  AND     mcb.enabled_flag      = 'Y'
  AND     mcb.disable_date      IS NULL
;
--
COMMENT ON COLUMN xxcmn_categories_v.structure_id       IS '構造ID';
COMMENT ON COLUMN xxcmn_categories_v.category_set_id    IS 'カテゴリセットID';
COMMENT ON COLUMN xxcmn_categories_v.category_set_name  IS 'カテゴリセット名';
COMMENT ON COLUMN xxcmn_categories_v.category_id        IS 'カテゴリID';
COMMENT ON COLUMN xxcmn_categories_v.segment1           IS 'カテゴリコード';
COMMENT ON COLUMN xxcmn_categories_v.description        IS '摘要';
--
COMMENT ON TABLE  xxcmn_categories_v IS '品目カテゴリ情報VIEW';
