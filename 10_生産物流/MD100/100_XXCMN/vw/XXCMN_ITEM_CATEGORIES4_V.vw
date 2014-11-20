CREATE OR REPLACE FORCE VIEW xxcmn_item_categories4_v
(
  item_id
 ,prod_class_code
 ,prod_class_name
 ,item_class_code
 ,item_class_name
 ,crowd_code
)
AS
  SELECT gic_s.item_id
        ,mcb_s.segment1    AS prod_class_code
        ,mct_s.description AS prod_class_name
        ,mcb_h.segment1    AS item_class_code
        ,mct_h.description AS item_class_name
        ,mcb_g.segment1    AS crowd_code
  FROM   gmi_item_categories    gic_s
        ,mtl_categories_b       mcb_s
        ,mtl_categories_tl      mct_s
        ,mtl_category_sets_b    mcsb_s
        ,mtl_category_sets_tl   mcst_s
        ,gmi_item_categories    gic_h
        ,mtl_categories_b       mcb_h
        ,mtl_categories_tl      mct_h
        ,mtl_category_sets_b    mcsb_h
        ,mtl_category_sets_tl   mcst_h
        ,gmi_item_categories    gic_g
        ,mtl_categories_b       mcb_g
        ,mtl_categories_tl      mct_g
        ,mtl_category_sets_b    mcsb_g
        ,mtl_category_sets_tl   mcst_g
  WHERE mct_s.source_lang        = 'JA'
  AND   mct_s.language           = 'JA'
  AND   mcb_s.category_id        = mct_s.category_id
  AND   mcsb_s.structure_id      = mcb_s.structure_id
  AND   gic_s.category_id        = mcb_s.category_id
  AND   mcst_s.source_lang       = 'JA'
  AND   mcst_s.language          = 'JA'
  AND   mcst_s.category_set_name = '商品区分'
  AND   mcsb_s.category_set_id   = mcst_s.category_set_id
  AND   gic_s.category_set_id    = mcsb_s.category_set_id
--
  AND   gic_s.item_id            = gic_h.item_id
  AND   mct_h.source_lang        = 'JA'
  AND   mct_h.language           = 'JA'
  AND   mcb_h.category_id        = mct_h.category_id
  AND   mcsb_h.structure_id      = mcb_h.structure_id
  AND   gic_h.category_id        = mcb_h.category_id
  AND   mcst_h.source_lang       = 'JA'
  AND   mcst_h.language          = 'JA'
  AND   mcst_h.category_set_name = '品目区分'
  AND   mcsb_h.category_set_id   = mcst_h.category_set_id
  AND   gic_h.category_set_id    = mcsb_h.category_set_id
--
  AND   gic_s.item_id            = gic_g.item_id
  AND   mct_g.source_lang        = 'JA'
  AND   mct_g.language           = 'JA'
  AND   mcb_g.category_id        = mct_g.category_id
  AND   mcsb_g.structure_id      = mcb_g.structure_id
  AND   gic_g.category_id        = mcb_g.category_id
  AND   mcst_g.source_lang       = 'JA'
  AND   mcst_g.language          = 'JA'
  AND   mcst_g.category_set_name = '群コード'
  AND   mcsb_g.category_set_id   = mcst_g.category_set_id
  AND   gic_g.category_set_id    = mcsb_g.category_set_id
;
--
COMMENT ON COLUMN xxcmn_item_categories4_v.item_id          IS '品目ID' ;
COMMENT ON COLUMN xxcmn_item_categories4_v.prod_class_code  IS '商品区分' ;
COMMENT ON COLUMN xxcmn_item_categories4_v.prod_class_name  IS '商品区分名' ;
COMMENT ON COLUMN xxcmn_item_categories4_v.item_class_code  IS '品目区分' ;
COMMENT ON COLUMN xxcmn_item_categories4_v.item_class_name  IS '品目区分名' ;
COMMENT ON COLUMN xxcmn_item_categories4_v.crowd_code       IS '群コード' ;
--
COMMENT ON TABLE  xxcmn_item_categories4_v IS 'OPM品目カテゴリ割当情報VIEW4' ;
/
