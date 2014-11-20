/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcos_item_div_v
 * Description     : 品目区分ビュー
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2010/10/25    1.0   K.Kiriu         新規作成
 ************************************************************************/
CREATE OR REPLACE VIEW xxcos_item_div_v
(
  item_div
 ,item_div_description
 ,item_sort
)
AS
  SELECT /*+
           use_nl(mcb mct)
         */
         SUBSTRB(mcb.segment1, 1, 40)    item_div
        ,mct.description                 item_div_description
        ,1                               item_sort
  FROM   mtl_category_sets_tl mcst
        ,mtl_category_sets_b  mcsb
        ,mtl_categories_b     mcb
        ,mtl_categories_tl    mct
  WHERE  mcst.category_set_name = FND_PROFILE.VALUE('XXCOI1_GOODS_PRODUCT_CLASS')
  AND    mcst.language          = 'JA'
  AND    mcst.category_set_id   = mcsb.category_set_id
  AND    mcsb.structure_id      = mcb.structure_id
  AND    mcb.category_id        = mct.category_id
  AND    mct.language           = 'JA'
  UNION ALL
  SELECT SUBSTRB(flvv.attribute1, 1, 40) item_div
        ,flvv.meaning                    item_div_description
        ,2                               item_sort
  FROM   fnd_lookup_values_vl flvv
        ,( SELECT TRUNC( xxccp_common_pkg2.get_process_date ) process_date
           FROM dual
         )                    pd
  WHERE  flvv.lookup_type       = 'XXCOS1_DISCOUNT_ITEM_CODE'
  AND    flvv.enabled_flag      = 'Y'
  AND    pd.process_date BETWEEN NVL( flvv.start_date_active, pd.process_date)
                             AND NVL( flvv.end_date_active, pd.process_date )
;
--
COMMENT ON COLUMN xxcos_item_div_v.item_div              IS '品目区分'       ;
COMMENT ON COLUMN xxcos_item_div_v.item_div_description  IS '品目区分適用'   ;
COMMENT ON COLUMN xxcos_item_div_v.item_sort             IS 'ソート用コード' ;
--
COMMENT ON TABLE  xxcos_item_div_v                       IS '品目区分ビュー' ;
/
