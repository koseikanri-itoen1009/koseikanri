/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : XXCOS_GOOD_PROD_CLASS_V
 * Description     : ���i���i�敪�r���[
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2008/12/25    1.0   S.Nakamura       �V�K�쐬
 ************************************************************************/
CREATE OR REPLACE VIEW xxcos_good_prod_class_v
(
  inventory_item_id
 ,segment1
 ,goods_prod_class_code
 ,goods_prod_class_name
)
AS
  SELECT msib.inventory_item_id  AS inventory_item_id
        ,msib.segment1           AS segment1
        ,mcb.segment1            AS goods_prod_class_code
        ,mct.description         AS goods_prod_class_name
  FROM   mtl_item_categories    mic
        ,mtl_category_sets_b    mcsb
        ,mtl_category_sets_tl   mcst
        ,mtl_categories_b       mcb
        ,mtl_categories_tl      mct
        ,mtl_system_items_b     msib
        ,mtl_parameters         mp
  WHERE mcst.category_set_name  = FND_PROFILE.VALUE('XXCOI1_GOODS_PRODUCT_CLASS')
  AND   mcst.category_set_id    = mcsb.category_set_id
  AND   mcst.source_lang        = userenv('LANG')
  AND   mcst.language           = userenv('LANG')
  AND   mcsb.structure_id       = mcb.structure_id
  AND   mcb.category_id         = mct.category_id
  AND   mct.source_lang         = userenv('LANG')
  AND   mct.language            = userenv('LANG')
  AND   mcsb.category_set_id    = mic.category_set_id
  AND   mcb.category_id         = mic.category_id
  AND   mic.inventory_item_id   = msib.inventory_item_id
  AND   msib.organization_id    = mp.organization_id
  AND   msib.organization_id    = mic.organization_id
  AND   mp.organization_code    = FND_PROFILE.VALUE('XXCOI1_ORGANIZATION_CODE')
  AND ( mcb.disable_date IS NULL OR mcb.disable_date > SYSDATE )
  AND   mcb.enabled_flag                      = 'Y'      -- �J�e�S���L���t���O
  AND   SYSDATE BETWEEN NVL(mcb.start_date_active, SYSDATE) 
  AND   NVL(mcb.end_date_active, SYSDATE)
  AND   msib.enabled_flag                     = 'Y'      -- �i�ڃ}�X�^�L���t���O
  AND   SYSDATE BETWEEN NVL(msib.start_date_active, SYSDATE) 
  AND   NVL(msib.end_date_active, SYSDATE)
;
--
COMMENT ON COLUMN xxcos_good_prod_class_v.inventory_item_id       IS '�i��ID' ;
COMMENT ON COLUMN xxcos_good_prod_class_v.segment1                IS '�i�ڃR�[�h' ;
COMMENT ON COLUMN xxcos_good_prod_class_v.goods_prod_class_code   IS '���i���i�敪�R�[�h' ;
COMMENT ON COLUMN xxcos_good_prod_class_v.goods_prod_class_name   IS '���i���i�敪��' ;
--
COMMENT ON TABLE  xxcos_good_prod_class_v                         IS '���i���i�敪�r���[' ;
/
