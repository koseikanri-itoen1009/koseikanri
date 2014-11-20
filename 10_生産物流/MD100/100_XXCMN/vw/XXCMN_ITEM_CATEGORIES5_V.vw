CREATE OR REPLACE FORCE VIEW xxcmn_item_categories5_v
(
  item_id
 ,item_no
 ,prod_class_code
 ,prod_class_name
 ,item_class_code
 ,item_class_name
)
AS
  SELECT iimb.item_id
        ,iimb.item_no
        ,mcb_s.segment1    AS prod_class_code
        ,mct_s.description AS prod_class_name
        ,mcb_h.segment1    AS item_class_code
        ,mct_h.description AS item_class_name
  FROM  ic_item_mst_b           iimb
        ,gmi_item_categories    gic_s
        ,mtl_categories_b       mcb_s
        ,mtl_categories_tl      mct_s
        ,gmi_item_categories    gic_h
        ,mtl_categories_b       mcb_h
        ,mtl_categories_tl      mct_h
  WHERE iimb.item_id             = gic_s.item_id
  AND   mct_s.source_lang        = 'JA'
  AND   mct_s.language           = 'JA'
  AND   mcb_s.category_id        = mct_s.category_id
  AND   gic_s.category_id        = mcb_s.category_id
  AND   gic_s.category_set_id    = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_PROD_CLASS')
--
  AND   gic_s.item_id            = gic_h.item_id
  AND   mct_h.source_lang        = 'JA'
  AND   mct_h.language           = 'JA'
  AND   mcb_h.category_id        = mct_h.category_id
  AND   gic_h.category_id        = mcb_h.category_id
  AND   gic_h.category_set_id    = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
;
--
COMMENT ON COLUMN xxcmn_item_categories5_v.item_id          IS '品目ID' ;
COMMENT ON COLUMN xxcmn_item_categories5_v.item_no          IS '品目NO' ;
COMMENT ON COLUMN xxcmn_item_categories5_v.prod_class_code  IS '商品区分' ;
COMMENT ON COLUMN xxcmn_item_categories5_v.prod_class_name  IS '商品区分名' ;
COMMENT ON COLUMN xxcmn_item_categories5_v.item_class_code  IS '品目区分' ;
COMMENT ON COLUMN xxcmn_item_categories5_v.item_class_name  IS '品目区分名' ;
--
COMMENT ON TABLE  xxcmn_item_categories5_v IS 'OPM品目カテゴリ割当情報VIEW5' ;
/
