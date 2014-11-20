/************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2006-2008. All rights reserved.
 *
 * View Name       : XXCMN_ITEM_CATEGORIES6_V
 * Description     : �J�e�S�����View(���i�敪,�i�ڋ敪,�Q�R�[�h,�o�����p�Q�R�[�h)
 * Version         : 1.1
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2008-07-23    1.0   Y.Ishikawa       �V�K�쐬
 *  2008-07-31    1.1   T.Ikehara        �J�e�S���Z�b�g�Ƃ̌�������ߑΉ�
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
