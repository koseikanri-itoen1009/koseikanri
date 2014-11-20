/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcos_customer_items_v
 * Description     : �ڋq�i��view
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/01/01    1.0   K.Kumamoto       �V�K�쐬
 *  2009/03/06    1.1   K.Kumamoto       SELECT��Ɍڋq�i�ړE�v��ǉ�
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
COMMENT ON  COLUMN  xxcos_customer_items_v.customer_item_id        IS  '�ڋq�i��ID';
COMMENT ON  COLUMN  xxcos_customer_items_v.customer_id             IS  '�ڋqID';
COMMENT ON  COLUMN  xxcos_customer_items_v.customer_item_number    IS  '�ڋq�i��';
COMMENT ON  COLUMN  xxcos_customer_items_v.item_definition_level   IS  '��`���x��';
COMMENT ON  COLUMN  xxcos_customer_items_v.order_uom               IS  '�����P��';
COMMENT ON  COLUMN  xxcos_customer_items_v.inventory_item_id       IS  '�i��ID';
COMMENT ON  COLUMN  xxcos_customer_items_v.master_organization_id  IS  '�g�DID';
COMMENT ON  COLUMN  xxcos_customer_items_v.inactive_flag           IS  '�����t���O';
COMMENT ON  COLUMN  xxcos_customer_items_v.deliver_from            IS  '�o�׌��ۊǏꏊ';
COMMENT ON  COLUMN  xxcos_customer_items_v.customer_item_desc      IS  '�ڋq�i�ړE�v';
--
COMMENT ON  TABLE   xxcos_customer_items_v                         IS  '�ڋq�i�ڃr���[';
