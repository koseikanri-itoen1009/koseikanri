/************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2006-2008. All rights reserved.
 *
 * View Name       : XXCMN_ITEM_CATEGORIES6_V
 * Description     : カテゴリ情報View(商品区分,品目区分,群コード,経理部用群コード)
 * Version         : 1.1
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2008-07-23    1.0   Y.Ishikawa       新規作成
 *  2008-07-31    1.1   T.Ikehara        カテゴリセットとの結合取りやめ対応
 *
 ************************************************************************/
CREATE OR REPLACE VIEW XXCMN_ITEM_CATEGORIES6_V
    (ITEM_ID,PROD_CLASS_CODE,ITEM_CLASS_CODE,CROWD_CODE,ACNT_CROWD_CODE)
AS
SELECT   gic1.item_id     AS item_id
        ,mcb1.segment1    AS prod_class_code
        ,mcb2.segment1    AS item_class_code
        ,mcb3.segment1    AS crowd_code
        ,mcb4.segment1    AS acnt_crowd_code
  FROM gmi_item_categories    gic1
      ,mtl_categories_b       mcb1
      ,gmi_item_categories    gic2
      ,mtl_categories_b       mcb2
      ,gmi_item_categories    gic3
      ,mtl_categories_b       mcb3
      ,gmi_item_categories    gic4
      ,mtl_categories_b       mcb4
  WHERE gic1.item_id            = gic2.item_id
  AND   gic1.item_id            = gic3.item_id
  AND   gic1.item_id            = gic4.item_id
  AND   gic1.category_set_id    = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_PROD_CLASS')
  AND   gic1.category_id        = mcb1.category_id
  AND   gic2.category_set_id    = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND   gic2.category_id        = mcb2.category_id
  AND   gic3.category_set_id    = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_CROWD_CODE')
  AND   gic3.category_id        = mcb3.category_id
  AND   gic4.category_set_id    = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ACNT_CROWD_CODE')
  AND   gic4.category_id        = mcb4.category_id
/
COMMENT ON TABLE XXCMN_ITEM_CATEGORIES6_V IS
                 'カテゴリ情報View(商品区分,品目区分,群コード,経理部用群コード)'
/
COMMENT ON COLUMN XXCMN_ITEM_CATEGORIES6_V.ITEM_ID             IS '品目ＩＤ'
/
COMMENT ON COLUMN XXCMN_ITEM_CATEGORIES6_V.PROD_CLASS_CODE     IS '商品区分'
/
COMMENT ON COLUMN XXCMN_ITEM_CATEGORIES6_V.ITEM_CLASS_CODE     IS '品目区分'
/
COMMENT ON COLUMN XXCMN_ITEM_CATEGORIES6_V.CROWD_CODE          IS '群コード'
/
COMMENT ON COLUMN XXCMN_ITEM_CATEGORIES6_V.ACNT_CROWD_CODE     IS '経理部用群コード'
/
