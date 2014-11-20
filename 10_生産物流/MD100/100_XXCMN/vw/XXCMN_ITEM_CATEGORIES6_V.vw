/************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2006-2008. All rights reserved.
 *
 * View Name       : XXCMN_ITEM_CATEGORIES6_V
 * Description     : �J�e�S�����View(���i�敪,�i�ڋ敪,�Q�R�[�h,�o�����p�Q�R�[�h)
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2008-07-23    1.0   Y.Ishikawa       �V�K�쐬
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
      ,mtl_category_sets_b    mcsb1
      ,mtl_category_sets_tl   mcst1
      ,gmi_item_categories    gic2
      ,mtl_categories_b       mcb2
      ,mtl_category_sets_b    mcsb2
      ,mtl_category_sets_tl   mcst2
      ,gmi_item_categories    gic3
      ,mtl_categories_b       mcb3
      ,mtl_category_sets_b    mcsb3
      ,mtl_category_sets_tl   mcst3
      ,gmi_item_categories    gic4
      ,mtl_categories_b       mcb4
      ,mtl_category_sets_b    mcsb4
      ,mtl_category_sets_tl   mcst4
  WHERE gic1.item_id            = gic2.item_id
  AND   gic1.item_id            = gic3.item_id
  AND   gic1.item_id            = gic4.item_id
  AND   gic1.category_set_id    = mcsb1.category_set_id
  AND   mcsb1.category_set_id   = mcst1.category_set_id
  AND   mcst1.category_set_name = '���i�敪'
  AND   mcst1.source_lang       = 'JA'
  AND   mcst1.language          = 'JA'
  AND   gic1.category_id        = mcb1.category_id
  AND   gic2.category_set_id    = mcsb2.category_set_id
  AND   mcsb2.category_set_id   = mcst2.category_set_id
  AND   mcst2.category_set_name = '�i�ڋ敪'
  AND   mcst2.source_lang       = 'JA'
  AND   mcst2.language          = 'JA'
  AND   gic2.category_id        = mcb2.category_id
  AND   gic3.category_set_id    = mcsb3.category_set_id
  AND   mcsb3.category_set_id   = mcst3.category_set_id
  AND   mcst3.category_set_name = '�Q�R�[�h'
  AND   mcst3.source_lang        = 'JA'
  AND   mcst3.language           = 'JA'
  AND   gic3.category_id        = mcb3.category_id
  AND   gic4.category_set_id    = mcsb4.category_set_id
  AND   mcsb4.category_set_id   = mcst4.category_set_id
  AND   mcst4.category_set_name = '�o�����p�Q�R�[�h'
  AND   mcst4.source_lang        = 'JA'
  AND   mcst4.language           = 'JA'
  AND   gic4.category_id        = mcb4.category_id
/
COMMENT ON TABLE XXCMN_ITEM_CATEGORIES6_V IS
                 '�J�e�S�����View(���i�敪,�i�ڋ敪,�Q�R�[�h,�o�����p�Q�R�[�h)'
/
COMMENT ON COLUMN XXCMN_ITEM_CATEGORIES6_V.ITEM_ID             IS '�i�ڂh�c'
/
COMMENT ON COLUMN XXCMN_ITEM_CATEGORIES6_V.PROD_CLASS_CODE     IS '���i�敪'
/
COMMENT ON COLUMN XXCMN_ITEM_CATEGORIES6_V.ITEM_CLASS_CODE     IS '�i�ڋ敪'
/
COMMENT ON COLUMN XXCMN_ITEM_CATEGORIES6_V.CROWD_CODE          IS '�Q�R�[�h'
/
COMMENT ON COLUMN XXCMN_ITEM_CATEGORIES6_V.ACNT_CROWD_CODE     IS '�o�����p�Q�R�[�h'
/
