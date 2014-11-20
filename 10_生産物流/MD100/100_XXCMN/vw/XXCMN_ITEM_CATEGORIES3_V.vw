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
              WHEN mcst.category_set_name = '���i�敪' THEN mct.description
              ELSE NULL
            END ) AS prod_class_name
      ,MAX( CASE
              WHEN mcst.category_set_name = '���i�敪' THEN mcb.segment1
              ELSE NULL
            END ) AS PROD_CLASS_CODE
      ,MAX( CASE
              WHEN mcst.category_set_name = '�{�Џ��i�敪' THEN mct.description
              ELSE NULL
            END ) AS prod_class_h_name
      ,MAX( CASE
              WHEN mcst.category_set_name = '�{�Џ��i�敪' THEN mcb.segment1
              ELSE NULL
            END ) AS prod_class_h_code
      ,MAX( CASE
              WHEN mcst.category_set_name = '�i�ڋ敪' THEN mct.description
              ELSE NULL
            END ) AS ITEM_CLASS_NAME
      ,MAX( CASE
              WHEN mcst.category_set_name = '�i�ڋ敪' THEN mcb.segment1
              ELSE NULL
            END ) AS item_class_code
      ,MAX( CASE
              WHEN mcst.category_set_name = '�i��GL�敪' THEN mct.description
              ELSE NULL
            END ) AS item_class_gl_name
      ,MAX( CASE
              WHEN mcst.category_set_name = '�i��GL�敪' THEN mcb.segment1
              ELSE NULL
            END ) AS item_class_gl_code
      ,MAX( CASE
              WHEN mcst.category_set_name = '�i�ڊ����敪' THEN mct.description
              ELSE NULL
            END ) AS item_alct_class_name
      ,MAX( CASE
              WHEN mcst.category_set_name = '�i�ڊ����敪' THEN mcb.segment1
              ELSE NULL
            END ) AS item_alct_class_code
      ,MAX( CASE
              WHEN mcst.category_set_name = '���O�敪' THEN mct.description
              ELSE NULL
            END ) AS in_out_class_name
      ,MAX( CASE
              WHEN mcst.category_set_name = '���O�敪' THEN mcb.segment1
              ELSE NULL
            END ) AS in_out_class_code
      ,MAX( CASE
              WHEN mcst.category_set_name = '�o�����敪' THEN mct.description
              ELSE NULL
            END ) AS b_tae_class_name
      ,MAX( CASE
              WHEN mcst.category_set_name = '�o�����敪' THEN mcb.segment1
              ELSE NULL
            END ) AS b_tae_class_code
      ,MAX( CASE
              WHEN mcst.category_set_name = '���i���i�敪' THEN mct.description
              ELSE NULL
            END ) AS prod_item_class_name
      ,MAX( CASE
              WHEN mcst.category_set_name = '���i���i�敪' THEN mcb.segment1
              ELSE NULL
            END ) AS prod_item_class_code
      ,MAX( CASE
              WHEN mcst.category_set_name = '�Q�R�[�h' THEN mcb.segment1
              ELSE NULL
            END ) AS crowd_code
      ,MAX( CASE
              WHEN mcst.category_set_name = '�o�����p�Q�R�[�h' THEN mcb.segment1
              ELSE NULL
            END ) AS acnt_crowd_code
      ,MAX( CASE
              WHEN mcst.category_set_name = '���O�敪' THEN mcb.attribute1
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
    '���i�敪',
    '�{�Џ��i�敪',
    '�i�ڋ敪',
    '�i��GL�敪',
    '�i�ڊ����敪',
    '���O�敪',
    '�o�����敪',
    '���i���i�敪',
    '�Q�R�[�h',
    '�o�����p�Q�R�[�h')
AND   mcsb.category_set_id  = mcst.category_set_id
AND   gic.category_set_id   = mcsb.category_set_id
AND   iimb.item_id          = gic.item_id
GROUP BY iimb.item_id
        ,iimb.item_no;
