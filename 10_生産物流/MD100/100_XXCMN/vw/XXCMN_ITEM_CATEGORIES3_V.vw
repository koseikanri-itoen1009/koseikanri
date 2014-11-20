CREATE OR REPLACE VIEW xxcmn_item_categories3_v
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
 crowd_code,
 acnt_crowd_code,
 int_ext_class
) AS 
SELECT iimb.item_id
      ,iimb.item_no
      ,mct_s.description        AS prod_class_name
      ,mcb_s.segment1           AS prod_class_code
      ,hs.prod_class_h_name     AS prod_class_h_name
      ,hs.prod_class_h_code     AS prod_class_h_code
      ,mct_h.description        AS item_class_name
      ,mcb_h.segment1           AS item_class_code
      ,n.in_out_class_name      AS in_out_class_name
      ,n.in_out_class_code      AS in_out_class_code
      ,b.b_tae_class_name       AS b_tae_class_name
      ,b.b_tae_class_code       AS b_tae_class_code
      ,sh.prod_item_class_name  AS prod_item_class_name
      ,sh.prod_item_class_code  AS prod_item_class_code
      ,gun.crowd_code           AS crowd_code
      ,kgun.acnt_crowd_code     AS acnt_crowd_code
      ,n.int_ext_class          AS int_ext_class
FROM ic_item_mst_b          iimb
    -- 商品区分
    ,gmi_item_categories    gic_s
    ,mtl_categories_b       mcb_s
    ,mtl_categories_tl      mct_s
--
    -- 本社商品区分
    ,(SELECT  mct_hs.description prod_class_h_name
             ,mcb_hs.segment1    prod_class_h_code
             ,gic_hs.item_id     item_id
      FROM
        gmi_item_categories    gic_hs
       ,mtl_categories_b       mcb_hs
       ,mtl_categories_tl      mct_hs
      WHERE mct_hs.source_lang        = 'JA'
      AND   mct_hs.language           = 'JA'
      AND   mcb_hs.category_id        = mct_hs.category_id
      AND   gic_hs.category_id        = mcb_hs.category_id
      AND   gic_hs.category_set_id    = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_PROD_CLASS_H')
     ) hs
--
    -- 品目区分
    ,gmi_item_categories    gic_h
    ,mtl_categories_b       mcb_h
    ,mtl_categories_tl      mct_h
--
    -- 内外区分
    ,(SELECT  mct_n.description in_out_class_name
             ,mcb_n.segment1    in_out_class_code
             ,mcb_n.attribute1  int_ext_class
             ,gic_n.item_id     item_id
      FROM
        gmi_item_categories    gic_n
       ,mtl_categories_b       mcb_n
       ,mtl_categories_tl      mct_n
      WHERE mct_n.source_lang        = 'JA'
      AND   mct_n.language           = 'JA'
      AND   mcb_n.category_id        = mct_n.category_id
      AND   gic_n.category_id        = mcb_n.category_id
      AND   gic_n.category_set_id    = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_IN_OUT_CLASS')
     ) n
--
    -- バラ茶区分
    ,(SELECT  mct_b.description b_tae_class_name
             ,mcb_b.segment1    b_tae_class_code
             ,gic_b.item_id     item_id
      FROM
        gmi_item_categories    gic_b
       ,mtl_categories_b       mcb_b
       ,mtl_categories_tl      mct_b
      WHERE mct_b.source_lang        = 'JA'
      AND   mct_b.language           = 'JA'
      AND   mcb_b.category_id        = mct_b.category_id
      AND   gic_b.category_id        = mcb_b.category_id
      AND   gic_b.category_set_id    = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_B_TAE_CLASS')
     ) b
--
    -- 商品製品区分
    ,(SELECT  mct_sh.description prod_item_class_name
             ,mcb_sh.segment1    prod_item_class_code
             ,gic_sh.item_id     item_id
      FROM
        gmi_item_categories    gic_sh
       ,mtl_categories_b       mcb_sh
       ,mtl_categories_tl      mct_sh
      WHERE mct_sh.source_lang        = 'JA'
      AND   mct_sh.language           = 'JA'
      AND   mcb_sh.category_id        = mct_sh.category_id
      AND   gic_sh.category_id        = mcb_sh.category_id
      AND   gic_sh.category_set_id    = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_PROD_ITEM_CLASS')
     ) sh
--
    -- 群コード
    ,(SELECT  mcb_g.segment1 crowd_code
             ,gic_g.item_id  item_id
      FROM
        gmi_item_categories    gic_g
       ,mtl_categories_b       mcb_g
      WHERE gic_g.category_id        = mcb_g.category_id
      AND   gic_g.category_set_id    = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_CROWD_CODE')
     ) gun
--
    -- 経理部用群コード
    ,(SELECT  mcb_kg.segment1 acnt_crowd_code
             ,gic_kg.item_id  item_id
      FROM
        gmi_item_categories    gic_kg
       ,mtl_categories_b       mcb_kg
      WHERE gic_kg.category_id        = mcb_kg.category_id
      AND   gic_kg.category_set_id    = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ACNT_CROWD_CODE')
     ) kgun
--
WHERE mct_s.source_lang         = 'JA'
AND   mct_s.language            = 'JA'
AND   mcb_s.category_id         = mct_s.category_id
AND   gic_s.category_id         = mcb_s.category_id
AND   gic_s.category_set_id     = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_PROD_CLASS')
AND   iimb.item_id              = gic_s.item_id
--
AND   iimb.item_id              = hs.item_id(+)
--
AND   mct_h.source_lang         = 'JA'
AND   mct_h.language            = 'JA'
AND   mcb_h.category_id         = mct_h.category_id
AND   gic_h.category_id         = mcb_h.category_id
AND   gic_h.category_set_id     = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
AND   iimb.item_id              = gic_h.item_id
--
AND   iimb.item_id              = n.item_id(+)
--
AND   iimb.item_id              = b.item_id(+)
--
AND   iimb.item_id              = sh.item_id(+)
--
AND   iimb.item_id              = gun.item_id(+)
--
AND   iimb.item_id              = kgun.item_id(+)
;
