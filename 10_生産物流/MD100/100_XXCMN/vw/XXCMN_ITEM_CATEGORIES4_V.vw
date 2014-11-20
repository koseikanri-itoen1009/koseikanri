CREATE OR REPLACE VIEW xxcmn_item_categories4_v
(
  item_id
 ,prod_class_code
 ,prod_class_name
 ,item_class_code
 ,item_class_name
 ,crowd_code
)
AS
  SELECT gic.item_id
        ,MAX( CASE
               WHEN mcst.category_set_name = '商品区分' THEN mcb.segment1
               ELSE NULL
             END ) AS prod_class_code
        ,MAX( CASE
               WHEN mcst.category_set_name = '商品区分' THEN mct.description
               ELSE NULL
             END ) AS prod_class_name
        ,MAX( CASE
               WHEN mcst.category_set_name = '品目区分' THEN mcb.segment1
               ELSE NULL
             END ) AS item_class_code
        ,MAX( CASE
               WHEN mcst.category_set_name = '品目区分' THEN mct.description
               ELSE NULL
             END ) AS item_class_name
        ,MAX( CASE
               WHEN mcst.category_set_name = '群コード' THEN mcb.segment1
               ELSE NULL
             END ) AS crowd_code
  FROM gmi_item_categories    gic
      ,mtl_categories_b       mcb
      ,mtl_categories_tl      mct
      ,mtl_category_sets_b    mcsb
      ,mtl_category_sets_tl   mcst
  WHERE mct.source_lang       = 'JA'
  AND   mct.language          = 'JA'
  AND   mcb.category_id       = mct.category_id
  AND   mcsb.structure_id     = mcb.structure_id
  AND   gic.category_id       = mcb.category_id
  AND   mcst.source_lang      = 'JA'
  AND   mcst.language         = 'JA'
  AND   mcst.category_set_name IN( '商品区分','品目区分','群コード' )
  AND   mcsb.category_set_id  = mcst.category_set_id
  AND   gic.category_set_id   = mcsb.category_set_id
  GROUP BY gic.item_id
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
