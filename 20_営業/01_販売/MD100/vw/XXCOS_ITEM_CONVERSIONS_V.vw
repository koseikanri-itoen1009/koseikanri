/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcos_item_conversions_v
 * Description     : �i�ڊ��Z�r���[
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/01/01    1.0   T.Miyata         �V�K�쐬
 ************************************************************************/
CREATE OR REPLACE VIEW xxcos_item_conversions_v (
  inventory_item_id
 ,item_code
 ,to_uom_code
 ,conversion_rate
)
AS
  SELECT
     msib.inventory_item_id
    ,msib.segment1
    ,mucc.to_uom_code
    ,mucc.conversion_rate
  FROM
     mtl_system_items_b        msib
    ,mtl_uom_class_conversions mucc
    ,mtl_parameters            mp
  WHERE
       msib.inventory_item_id = mucc.inventory_item_id
  AND  msib.organization_id   = mp.organization_id
  AND  mp.organization_code   = FND_PROFILE.VALUE('XXCOI1_ORGANIZATION_CODE')
;
COMMENT ON  COLUMN  xxcos_item_conversions_v.inventory_item_id  IS  '�i��ID';
COMMENT ON  COLUMN  xxcos_item_conversions_v.item_code          IS  '�i�ڃR�[�h'; 
COMMENT ON  COLUMN  xxcos_item_conversions_v.to_uom_code        IS  '�ϊ���P��';
COMMENT ON  COLUMN  xxcos_item_conversions_v.conversion_rate    IS  '���Z���[�g';
--
COMMENT ON  TABLE   xxcos_item_conversions_v                    IS  '�i�ڊ��Z�r���[';
