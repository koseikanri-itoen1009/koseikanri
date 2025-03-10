/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcos_customer_items_v
 * Description     : ÚqiÚview
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/01/01    1.0   K.Kumamoto       VKì¬
 *  2009/03/06    1.1   K.Kumamoto       SELECTåÉÚqiÚEvðÇÁ
 ************************************************************************/
CREATE OR REPLACE VIEW xxcos_customer_items_v (
   customer_item_id
  ,customer_id
  ,customer_item_number
  ,item_definition_level
  ,order_uom
  ,inventory_item_id
  ,master_organization_id
  ,inactive_flag
  ,deliver_from
  ,customer_item_desc
)
AS
  SELECT mci.customer_item_id                customer_item_id
        ,mci.customer_id                     customer_id
        ,mci.customer_item_number            customer_item_number
        ,mci.item_definition_level           item_definition_level
        ,mci.attribute1                      order_uom
        ,mcix.inventory_item_id              inventory_item_id
        ,mcix.master_organization_id         master_organization_id
        ,mcix.inactive_flag                  inactive_flag
        ,mcix.attribute1                     deliver_from
        ,mci.customer_item_desc              customer_item_desc
  FROM   mtl_customer_items mci
        ,mtl_customer_item_xrefs mcix
  WHERE mcix.customer_item_id = mci.customer_item_id
  AND    mci.inactive_flag = 'N'
  AND    mcix.inactive_flag = 'N'
;
COMMENT ON  COLUMN  xxcos_customer_items_v.customer_item_id        IS  'ÚqiÚID';
COMMENT ON  COLUMN  xxcos_customer_items_v.customer_id             IS  'ÚqID';
COMMENT ON  COLUMN  xxcos_customer_items_v.customer_item_number    IS  'ÚqiÚ';
COMMENT ON  COLUMN  xxcos_customer_items_v.item_definition_level   IS  'è`x';
COMMENT ON  COLUMN  xxcos_customer_items_v.order_uom               IS  '­PÊ';
COMMENT ON  COLUMN  xxcos_customer_items_v.inventory_item_id       IS  'iÚID';
COMMENT ON  COLUMN  xxcos_customer_items_v.master_organization_id  IS  'gDID';
COMMENT ON  COLUMN  xxcos_customer_items_v.inactive_flag           IS  '³øtO';
COMMENT ON  COLUMN  xxcos_customer_items_v.deliver_from            IS  'o×³ÛÇê';
COMMENT ON  COLUMN  xxcos_customer_items_v.customer_item_desc      IS  'ÚqiÚEv';
--
COMMENT ON  TABLE   xxcos_customer_items_v                         IS  'ÚqiÚr[';
