CREATE OR REPLACE FORCE VIEW apps.xxcmn_item_categories3_v
(
 item_id,
 item_no,
 prod_class_name,
 prod_class_code,
 prod_class_h_name,
 prod_class_h_code,
 item_class_name,
 item_class_code,
 item_class_gl_name,
 item_class_gl_code,
 item_alct_class_name,
 item_alct_class_code,
 in_out_class_name,
 in_out_class_code,
 b_tae_class_name,
 b_tae_class_code,
 prod_item_class_name,
 prod_item_class_code,
 crowd_code, acnt_crowd_code,
 int_ext_class
) AS 
SELECT iimb.item_id
      ,iimb.item_no
      ,MAX( CASE
              WHEN mcst.category_set_name = '商品区分' THEN mct.description
              ELSE NULL
            END ) AS prod_class_name
      ,MAX( CASE
              WHEN mcst.category_set_name = '商品区分' THEN mcb.segment1
              ELSE NULL
            END ) AS PROD_CLASS_CODE
      ,MAX( CASE
              WHEN mcst.category_set_name = '本社商品区分' THEN mct.description
              ELSE NULL
            END ) AS prod_class_h_name
      ,MAX( CASE
              WHEN mcst.category_set_name = '本社商品区分' THEN mcb.segment1
              ELSE NULL
            END ) AS prod_class_h_code
      ,MAX( CASE
              WHEN mcst.category_set_name = '品目区分' THEN mct.description
              ELSE NULL
            END ) AS ITEM_CLASS_NAME
      ,MAX( CASE
              WHEN mcst.category_set_name = '品目区分' THEN mcb.segment1
              ELSE NULL
            END ) AS item_class_code
      ,MAX( CASE
              WHEN mcst.category_set_name = '品目GL区分' THEN mct.description
              ELSE NULL
            END ) AS item_class_gl_name
      ,MAX( CASE
              WHEN mcst.category_set_name = '品目GL区分' THEN mcb.segment1
              ELSE NULL
            END ) AS item_class_gl_code
      ,MAX( CASE
              WHEN mcst.category_set_name = '品目割当区分' THEN mct.description
              ELSE NULL
            END ) AS item_alct_class_name
      ,MAX( CASE
              WHEN mcst.category_set_name = '品目割当区分' THEN mcb.segment1
              ELSE NULL
            END ) AS item_alct_class_code
      ,MAX( CASE
              WHEN mcst.category_set_name = '内外区分' THEN mct.description
              ELSE NULL
            END ) AS in_out_class_name
      ,MAX( CASE
              WHEN mcst.category_set_name = '内外区分' THEN mcb.segment1
              ELSE NULL
            END ) AS in_out_class_code
      ,MAX( CASE
              WHEN mcst.category_set_name = 'バラ茶区分' THEN mct.description
              ELSE NULL
            END ) AS b_tae_class_name
      ,MAX( CASE
              WHEN mcst.category_set_name = 'バラ茶区分' THEN mcb.segment1
              ELSE NULL
            END ) AS b_tae_class_code
      ,MAX( CASE
              WHEN mcst.category_set_name = '商品製品区分' THEN mct.description
              ELSE NULL
            END ) AS prod_item_class_name
      ,MAX( CASE
              WHEN mcst.category_set_name = '商品製品区分' THEN mcb.segment1
              ELSE NULL
            END ) AS prod_item_class_code
      ,MAX( CASE
              WHEN mcst.category_set_name = '群コード' THEN mcb.segment1
              ELSE NULL
            END ) AS crowd_code
      ,MAX( CASE
              WHEN mcst.category_set_name = '経理部用群コード' THEN mcb.segment1
              ELSE NULL
            END ) AS acnt_crowd_code
      ,MAX( CASE
              WHEN mcst.category_set_name = '内外区分' THEN mcb.attribute1
              ELSE NULL
            END ) AS int_ext_class
FROM ic_item_mst_b          iimb
    ,gmi_item_categories    gic
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
AND   mcst.category_set_name IN(
    '商品区分',
    '本社商品区分',
    '品目区分',
    '品目GL区分',
    '品目割当区分',
    '内外区分',
    'バラ茶区分',
    '商品製品区分',
    '群コード',
    '経理部用群コード')
AND   mcsb.category_set_id  = mcst.category_set_id
AND   gic.category_set_id   = mcsb.category_set_id
AND   iimb.item_id          = gic.item_id
GROUP BY iimb.item_id
        ,iimb.item_no;
