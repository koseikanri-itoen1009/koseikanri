SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;

clear buffer;

set feed off
set linesize 300
set pagesize 5000
set underline '='
set serveroutput on size 1000000
set trimspool on

set head off

SELECT
   '伝票番号'              ||','||
   '伝票日付'              ||','||
   '出庫側拠点'            ||','||
   '出庫側倉庫'            ||','||
   '入庫側拠点'            ||','||
   '入庫側営業車'          ||','||
   '担当者'                ||','||
   '担当者名'              ||','||
   '本社商品区分'          ||','||
   '親品目'                ||','||
   '親品目略称'            ||','||
   '子品目'                ||','||
   '子品目略称'            ||','||
   'ロット'                ||','||
   '固有記号'              ||','||
   'ロケーション'          ||','||
   '入数'                  ||','||
   'ケース数'              ||','||
   'バラ数'                ||','||
   '取引数量（総数）'      ||','||
   '基準単位'              ||','||
   '倉替先メイン倉庫'      ||','||
   '取引タイプ'            ||','||
   'タイプ名'
FROM
   dual
;
SELECT        xlt.slip_num                        --  "伝票番号"
      ||','|| xlt.transaction_date                --  "伝票日付"
      ||','|| xlt.base_code                       --  "出庫側拠点"
      ||','|| xlt.subinventory_code               --  "出庫側倉庫"
      ||','|| msiin.attribute7                    --  "入庫側拠点"
      ||','|| xlt.inside_warehouse_code           --  "入庫側営業車"
      ||','|| msiin.attribute3                    --  "担当者"
      ||','|| SUBSTRB(msiin.description, 1, 20)   --  "担当者名"
      ||','|| mc.description                      --  "本社商品区分"
      ||','|| msibp.segment1                      --  "親品目"
--      ||','|| msibp.description                   --  "親品目名"
      ||','|| ximbp.item_short_name               --  "親品目略称"
      ||','|| msibc.segment1                      --  "子品目"
--      ||','|| msibc.description                   --  "子品目名"
      ||','|| ximbc.item_short_name               --  "子品目略称"
      ||','|| xlt.lot                             --  "ロット"
      ||','|| xlt.difference_summary_code         --  "固有記号"
      ||','|| xlt.location_code                   --  "ロケーション"
      ||','|| xlt.case_in_qty                     --  "入数"
      ||','|| -xlt.case_qty                        --  "ケース数"
      ||','|| -xlt.singly_qty                      --  "バラ数"
      ||','|| -xlt.summary_qty                     --  "取引数量（総数）"
      ||','|| xlt.transaction_uom                 --  "基準単位"
      ||','|| xlt.transfer_subinventory           --  "倉替先メイン倉庫"
      ||','|| xlt.transaction_type_code           --  "取引タイプ"
      ||','|| flv.meaning                         --  "タイプ名"
FROM    xxcoi_lot_transactions      xlt
      , mtl_secondary_inventories   msiin
      , mtl_system_items_b          msibp
      , mtl_system_items_b          msibc
      , fnd_lookup_values           flv
      , ic_item_mst_b               iimbp
      , xxcmn_item_mst_b            ximbp
      , ic_item_mst_b               iimbc
      , xxcmn_item_mst_b            ximbc
      , mtl_category_sets           mcs
      , mtl_item_categories         mic
      , mtl_categories              mc
WHERE   xlt.inside_warehouse_code   =   msiin.secondary_inventory_name
AND     xlt.parent_item_id          =   msibp.inventory_item_id
AND     xlt.child_item_id           =   msibc.inventory_item_id
AND     msibp.organization_id       =   xxcoi_common_pkg.get_organization_id( fnd_profile.value( 'XXCOI1_ORGANIZATION_CODE' ) )
AND     msibc.organization_id       =   xxcoi_common_pkg.get_organization_id( fnd_profile.value( 'XXCOI1_ORGANIZATION_CODE' ) )
AND     msibp.segment1              =   iimbp.item_no
AND     iimbp.item_id               =   ximbp.item_id
AND     SYSDATE BETWEEN ximbp.start_date_active AND ximbp.end_date_active
AND     msibc.segment1              =   iimbc.item_no
AND     iimbc.item_id               =   ximbc.item_id
AND     SYSDATE BETWEEN ximbc.start_date_active AND ximbc.end_date_active
AND     msibp.inventory_item_id     =   mic.inventory_item_id
AND     msibp.organization_id       =   mic.organization_id
AND     mcs.category_set_name       =   '本社商品区分'
AND     mcs.category_set_id         =   mic.category_set_id
AND     mic.category_id             =   mc.category_id
AND     flv.lookup_type             =   'XXCOI1_TRANSACTION_TYPE_NAME'
AND     flv.language                =   USERENV( 'LANG' )
AND     flv.lookup_code             =   xlt.transaction_type_code
--  検索条件（伝票日付）
AND     xlt.transaction_date        >=  TRUNC(SYSDATE)
order by xlt.transaction_date , mc.description , msibp.segment1 , msibc.segment1 , xlt.location_code , xlt.inside_warehouse_code
;

--Prompt
--Prompt ********************************************************************************
--Prompt ********************* END ******************************************************
--Prompt ********************************************************************************
--Prompt

exit;
