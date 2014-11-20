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
               WHEN mcst.category_set_name = '���i�敪' THEN mcb.segment1
               ELSE NULL
             END ) AS prod_class_code
        ,MAX( CASE
               WHEN mcst.category_set_name = '���i�敪' THEN mct.description
               ELSE NULL
             END ) AS prod_class_name
        ,MAX( CASE
               WHEN mcst.category_set_name = '�i�ڋ敪' THEN mcb.segment1
               ELSE NULL
             END ) AS item_class_code
        ,MAX( CASE
               WHEN mcst.category_set_name = '�i�ڋ敪' THEN mct.description
               ELSE NULL
             END ) AS item_class_name
        ,MAX( CASE
               WHEN mcst.category_set_name = '�Q�R�[�h' THEN mcb.segment1
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
  AND   mcst.category_set_name IN( '���i�敪','�i�ڋ敪','�Q�R�[�h' )
  AND   mcsb.category_set_id  = mcst.category_set_id
  AND   gic.category_set_id   = mcsb.category_set_id
  GROUP BY gic.item_id
;
--
COMMENT ON COLUMN xxcmn_item_categories4_v.item_id          IS '�i��ID' ;
COMMENT ON COLUMN xxcmn_item_categories4_v.prod_class_code  IS '���i�敪' ;
COMMENT ON COLUMN xxcmn_item_categories4_v.prod_class_name  IS '���i�敪��' ;
COMMENT ON COLUMN xxcmn_item_categories4_v.item_class_code  IS '�i�ڋ敪' ;
COMMENT ON COLUMN xxcmn_item_categories4_v.item_class_name  IS '�i�ڋ敪��' ;
COMMENT ON COLUMN xxcmn_item_categories4_v.crowd_code       IS '�Q�R�[�h' ;
--
COMMENT ON TABLE  xxcmn_item_categories4_v IS 'OPM�i�ڃJ�e�S���������VIEW4' ;
/
