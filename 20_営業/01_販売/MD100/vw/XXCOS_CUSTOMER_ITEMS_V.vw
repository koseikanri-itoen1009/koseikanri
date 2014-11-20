/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcos_customer_items_v
 * Description     : 顧客品目view
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/01/01    1.0   K.Kumamoto       新規作成
 *  2009/03/06    1.1   K.Kumamoto       SELECT句に顧客品目摘要を追加
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
COMMENT ON  COLUMN  xxcos_customer_items_v.customer_item_id        IS  '顧客品目ID';
COMMENT ON  COLUMN  xxcos_customer_items_v.customer_id             IS  '顧客ID';
COMMENT ON  COLUMN  xxcos_customer_items_v.customer_item_number    IS  '顧客品目';
COMMENT ON  COLUMN  xxcos_customer_items_v.item_definition_level   IS  '定義レベル';
COMMENT ON  COLUMN  xxcos_customer_items_v.order_uom               IS  '発注単位';
COMMENT ON  COLUMN  xxcos_customer_items_v.inventory_item_id       IS  '品目ID';
COMMENT ON  COLUMN  xxcos_customer_items_v.master_organization_id  IS  '組織ID';
COMMENT ON  COLUMN  xxcos_customer_items_v.inactive_flag           IS  '無効フラグ';
COMMENT ON  COLUMN  xxcos_customer_items_v.deliver_from            IS  '出荷元保管場所';
COMMENT ON  COLUMN  xxcos_customer_items_v.customer_item_desc      IS  '顧客品目摘要';
--
COMMENT ON  TABLE   xxcos_customer_items_v                         IS  '顧客品目ビュー';
