/************************************************************************
 * Copyright(c)SCSK Corporation, 2017. All rights reserved.
 *
 * View Name       : xxcos_sale_price_item_code_v
 * Description     : �������i�\�i�ڃR�[�h�r���[
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2017/04/11    1.0   S.Niki           �V�K�쐬
 ************************************************************************/
CREATE OR REPLACE VIEW xxcos_sale_price_item_code_v (
  item_code
 ,item_name
)
AS
  SELECT
      msib.segment1         AS item_code
     ,msib.description      AS item_name
  FROM
      mtl_system_items_b      msib
     ,mtl_parameters          mp
  WHERE
      mp.organization_code   = FND_PROFILE.VALUE('XXCOI1_ORGANIZATION_CODE')
  AND mp.organization_id     = msib.organization_id
  AND EXISTS (SELECT 'X'
              FROM   xxcos_sale_price_lists  xspl
              WHERE  xspl.item_id = msib.inventory_item_id
      )
  ORDER BY
      msib.segment1
  ;
COMMENT ON  COLUMN  xxcos_sale_price_item_code_v.item_code          IS  '�i�ڃR�[�h'; 
COMMENT ON  COLUMN  xxcos_sale_price_item_code_v.item_name          IS  '�i�ږ�'; 
--
COMMENT ON  TABLE   xxcos_sale_price_item_code_v                    IS  '�������i�\�i�ڃR�[�h�r���[';
