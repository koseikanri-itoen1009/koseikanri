CREATE OR REPLACE VIEW xxcmn_categories2_v
(
  structure_id,
  category_set_id,
  category_set_name,
  category_id,
  segment1,
  enabled_flag,
  disable_date,
  description
)
AS
  SELECT  mcsb.structure_id,
          mcsb.category_set_id,
          mcst.category_set_name,
          mcb.category_id,
          mcb.segment1,
          mcb.enabled_flag,
          mcb.disable_date,
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
;
--
COMMENT ON COLUMN xxcmn_categories2_v.structure_id       IS '構造ID';
COMMENT ON COLUMN xxcmn_categories2_v.category_set_id    IS 'カテゴリセットID';
COMMENT ON COLUMN xxcmn_categories2_v.category_set_name  IS 'カテゴリセット名';
COMMENT ON COLUMN xxcmn_categories2_v.category_id        IS 'カテゴリID';
COMMENT ON COLUMN xxcmn_categories2_v.segment1           IS 'カテゴリコード';
COMMENT ON COLUMN xxcmn_categories2_v.enabled_flag       IS '使用可能フラグ';
COMMENT ON COLUMN xxcmn_categories2_v.disable_date       IS '無効日';
COMMENT ON COLUMN xxcmn_categories2_v.description        IS '摘要';
--
COMMENT ON TABLE  xxcmn_categories2_v IS '品目カテゴリ情報VIEW2';
