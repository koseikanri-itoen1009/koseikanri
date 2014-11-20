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
      ,mct_s.description   AS prod_class_name
      ,mcb_s.segment1      AS prod_class_code
      ,mct_hs.description  AS prod_class_h_name
      ,mcb_hs.segment1     AS prod_class_h_code
      ,mct_h.description   AS item_class_name
      ,mcb_h.segment1      AS item_class_code
      ,mct_n.description   AS in_out_class_name
      ,mcb_n.segment1      AS in_out_class_code
      ,mct_b.description   AS b_tae_class_name
      ,mcb_b.segment1      AS b_tae_class_code
      ,mct_sh.description  AS prod_item_class_name
      ,mcb_sh.segment1     AS prod_item_class_code
      ,mcb_g.segment1      AS crowd_code
      ,mcb_kg.segment1     AS acnt_crowd_code
      ,mcb_n.attribute1    AS int_ext_class
FROM ic_item_mst_b          iimb
    -- 商品区分
    ,gmi_item_categories    gic_s
    ,mtl_categories_b       mcb_s
    ,mtl_categories_tl      mct_s
    ,mtl_category_sets_b    mcsb_s
    ,mtl_category_sets_tl   mcst_s
--
    -- 本社商品区分
    ,gmi_item_categories    gic_hs
    ,mtl_categories_b       mcb_hs
    ,mtl_categories_tl      mct_hs
    ,mtl_category_sets_b    mcsb_hs
    ,mtl_category_sets_tl   mcst_hs
--
    -- 品目区分
    ,gmi_item_categories    gic_h
    ,mtl_categories_b       mcb_h
    ,mtl_categories_tl      mct_h
    ,mtl_category_sets_b    mcsb_h
    ,mtl_category_sets_tl   mcst_h
--
    -- 内外区分
    ,gmi_item_categories    gic_n
    ,mtl_categories_b       mcb_n
    ,mtl_categories_tl      mct_n
    ,mtl_category_sets_b    mcsb_n
    ,mtl_category_sets_tl   mcst_n
--
    -- バラ茶区分
    ,gmi_item_categories    gic_b
    ,mtl_categories_b       mcb_b
    ,mtl_categories_tl      mct_b
    ,mtl_category_sets_b    mcsb_b
    ,mtl_category_sets_tl   mcst_b
--
    -- 商品製品区分
    ,gmi_item_categories    gic_sh
    ,mtl_categories_b       mcb_sh
    ,mtl_categories_tl      mct_sh
    ,mtl_category_sets_b    mcsb_sh
    ,mtl_category_sets_tl   mcst_sh
--
    -- 群コード
    ,gmi_item_categories    gic_g
    ,mtl_categories_b       mcb_g
    ,mtl_categories_tl      mct_g
    ,mtl_category_sets_b    mcsb_g
    ,mtl_category_sets_tl   mcst_g
--
    -- 経理部用群コード
    ,gmi_item_categories    gic_kg
    ,mtl_categories_b       mcb_kg
    ,mtl_categories_tl      mct_kg
    ,mtl_category_sets_b    mcsb_kg
    ,mtl_category_sets_tl   mcst_kg
--
WHERE mct_s.source_lang         = 'JA'
AND   mct_s.language            = 'JA'
AND   mcb_s.category_id         = mct_s.category_id
AND   mcsb_s.structure_id       = mcb_s.structure_id
AND   gic_s.category_id         = mcb_s.category_id
AND   mcst_s.source_lang        = 'JA'
AND   mcst_s.language           = 'JA'
AND   mcst_s.category_set_name  = '商品区分'
AND   mcsb_s.category_set_id    = mcst_s.category_set_id
AND   gic_s.category_set_id     = mcsb_s.category_set_id
AND   iimb.item_id              = gic_s.item_id
--
AND   mct_hs.source_lang        = 'JA'
AND   mct_hs.language           = 'JA'
AND   mcb_hs.category_id        = mct_hs.category_id
AND   mcsb_hs.structure_id      = mcb_hs.structure_id
AND   gic_hs.category_id        = mcb_hs.category_id
AND   mcst_hs.source_lang       = 'JA'
AND   mcst_hs.language          = 'JA'
AND   mcst_hs.category_set_name = '本社商品区分'
AND   mcsb_hs.category_set_id   = mcst_hs.category_set_id
AND   gic_hs.category_set_id    = mcsb_hs.category_set_id
AND   iimb.item_id              = gic_hs.item_id
--
AND   mct_h.source_lang         = 'JA'
AND   mct_h.language            = 'JA'
AND   mcb_h.category_id         = mct_h.category_id
AND   mcsb_h.structure_id       = mcb_h.structure_id
AND   gic_h.category_id         = mcb_h.category_id
AND   mcst_h.source_lang        = 'JA'
AND   mcst_h.language           = 'JA'
AND   mcst_h.category_set_name  = '品目区分'
AND   mcsb_h.category_set_id    = mcst_h.category_set_id
AND   gic_h.category_set_id     = mcsb_h.category_set_id
AND   iimb.item_id              = gic_h.item_id
--
AND   mct_n.source_lang         = 'JA'
AND   mct_n.language            = 'JA'
AND   mcb_n.category_id         = mct_n.category_id
AND   mcsb_n.structure_id       = mcb_n.structure_id
AND   gic_n.category_id         = mcb_n.category_id
AND   mcst_n.source_lang        = 'JA'
AND   mcst_n.language           = 'JA'
AND   mcst_n.category_set_name  = '内外区分'
AND   mcsb_n.category_set_id    = mcst_n.category_set_id
AND   gic_n.category_set_id     = mcsb_n.category_set_id
AND   iimb.item_id              = gic_n.item_id
--
AND   mct_b.source_lang         = 'JA'
AND   mct_b.language            = 'JA'
AND   mcb_b.category_id         = mct_b.category_id
AND   mcsb_b.structure_id       = mcb_b.structure_id
AND   gic_b.category_id         = mcb_b.category_id
AND   mcst_b.source_lang        = 'JA'
AND   mcst_b.language           = 'JA'
AND   mcst_b.category_set_name  = 'バラ茶区分'
AND   mcsb_b.category_set_id    = mcst_b.category_set_id
AND   gic_b.category_set_id     = mcsb_b.category_set_id
AND   iimb.item_id              = gic_b.item_id
--
AND   mct_sh.source_lang        = 'JA'
AND   mct_sh.language           = 'JA'
AND   mcb_sh.category_id        = mct_sh.category_id
AND   mcsb_sh.structure_id      = mcb_sh.structure_id
AND   gic_sh.category_id        = mcb_sh.category_id
AND   mcst_sh.source_lang       = 'JA'
AND   mcst_sh.language          = 'JA'
AND   mcst_sh.category_set_name = '商品製品区分'
AND   mcsb_sh.category_set_id   = mcst_sh.category_set_id
AND   gic_sh.category_set_id    = mcsb_sh.category_set_id
AND   iimb.item_id              = gic_sh.item_id
--
AND   mct_g.source_lang         = 'JA'
AND   mct_g.language            = 'JA'
AND   mcb_g.category_id         = mct_g.category_id
AND   mcsb_g.structure_id       = mcb_g.structure_id
AND   gic_g.category_id         = mcb_g.category_id
AND   mcst_g.source_lang        = 'JA'
AND   mcst_g.language           = 'JA'
AND   mcst_g.category_set_name  = '群コード'
AND   mcsb_g.category_set_id    = mcst_g.category_set_id
AND   gic_g.category_set_id     = mcsb_g.category_set_id
AND   iimb.item_id              = gic_g.item_id
--
AND   mct_kg.source_lang        = 'JA'
AND   mct_kg.language           = 'JA'
AND   mcb_kg.category_id        = mct_kg.category_id
AND   mcsb_kg.structure_id      = mcb_kg.structure_id
AND   gic_kg.category_id        = mcb_kg.category_id
AND   mcst_kg.source_lang       = 'JA'
AND   mcst_kg.language          = 'JA'
AND   mcst_kg.category_set_name = '経理部用群コード'
AND   mcsb_kg.category_set_id   = mcst_kg.category_set_id
AND   gic_kg.category_set_id    = mcsb_kg.category_set_id
AND   iimb.item_id              = gic_kg.item_id
;
