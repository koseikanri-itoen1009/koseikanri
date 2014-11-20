CREATE OR REPLACE VIEW xxcmn_item_categories_v
(
  structure_id,
  category_set_id,
  category_set_name,
  category_id,
  segment1,
  description,
  item_id,
  item_no
)
AS
  SELECT  mcsb.structure_id,
          mcsb.category_set_id,
          mcst.category_set_name,
          mcb.category_id,
          mcb.segment1,
          mct.description,
          gic.item_id,
          iimb.item_no
  FROM    mtl_category_sets_b   mcsb,
          mtl_category_sets_tl  mcst,
          mtl_categories_b      mcb,
          mtl_categories_tl     mct,
          gmi_item_categories   gic,
          ic_item_mst_b         iimb
  WHERE   mcsb.category_set_id  = mcst.category_set_id
  AND     mcst.language         = 'JA'
  AND     mcst.source_lang      = 'JA' 
  AND     mcsb.structure_id     = mcb.structure_id
  AND     mcb.category_id       = mct.category_id
  AND     mct.language          = 'JA'
  AND     mct.source_lang       = 'JA' 
  AND     mcb.enabled_flag      = 'Y' 
  AND     mcb.disable_date      IS NULL 
  AND     mcsb.category_set_id  = gic.category_set_id
  AND     mcb.category_id       = gic.category_id
  AND     gic.item_id           = iimb.item_id
  AND     iimb.inactive_ind     <> '1'
;
--
COMMENT ON COLUMN xxcmn_item_categories_v.structure_id        IS '構造ID';
COMMENT ON COLUMN xxcmn_item_categories_v.category_set_id     IS 'カテゴリセットID';
COMMENT ON COLUMN xxcmn_item_categories_v.category_set_name   IS 'カテゴリセット名';
COMMENT ON COLUMN xxcmn_item_categories_v.category_id         IS 'カテゴリID';
COMMENT ON COLUMN xxcmn_item_categories_v.segment1            IS 'カテゴリコード';
COMMENT ON COLUMN xxcmn_item_categories_v.description         IS '摘要';
COMMENT ON COLUMN xxcmn_item_categories_v.item_id             IS '品目ID';
COMMENT ON COLUMN xxcmn_item_categories_v.item_no             IS '品目コード';
--
COMMENT ON TABLE  xxcmn_item_categories_v IS 'OPM品目カテゴリ割当情報VIEW';
