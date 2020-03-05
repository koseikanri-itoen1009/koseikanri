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

SELECT           '伝票番号'
        ||','||  '伝票日付'
        ||','||  '出庫側拠点'
        ||','||  '出庫側倉庫'
        ||','||  '入庫側拠点'
        ||','||  '入庫側営業車'
        ||','||  '担当者'
        ||','||  '担当者名'
        ||','||  '本社商品区分'
        ||','||  '容器群名'
        ||','||  '親品目'
        ||','||  '親品目略称'
        ||','||  '子品目'
        ||','||  '子品目略称'
        ||','||  'ロット'
        ||','||  '固有記号'
        ||','||  'ロケーション'
        ||','||  '入数'
        ||','||  'ケース数'
        ||','||  'バラ数'
        ||','||  '取引数量（総数）'
        ||','||  '基準単位'
        ||','||  '倉替先メイン倉庫'
        ||','||  '取引タイプ'
        ||','||  'タイプ名'
        ||','||  '引当日時'
FROM    dual
union all
SELECT          a.伝票番号
        ||','|| a.伝票日付
        ||','|| a.出庫側拠点
        ||','|| a.出庫側倉庫
        ||','|| a.入庫側拠点
        ||','|| a.入庫側営業車
        ||','|| a.担当者
        ||','|| a.担当者名
        ||','|| a.本社商品区分
--        ||','|| a.容器群
        ||','|| a.容器群名
        ||','|| a.親品目
--        ||','|| a.親品目名
        ||','|| a.親品目略称
        ||','|| a.子品目
--        ||','|| a.子品目名
        ||','|| a.子品目略称
        ||','|| a.ロット
        ||','|| a.固有記号
        ||','|| a.ロケーション
        ||','|| a.入数
        ||','|| a.ケース数
        ||','|| a.バラ数
        ||','|| a.取引数量
        ||','|| a.基準単位
        ||','|| a.倉替先メイン倉庫
        ||','|| a.取引タイプ
        ||','|| a.タイプ名
        ||','|| a.引当日時
FROM   
(SELECT xlt.slip_num                      as                  "伝票番号"
      , to_char(xlt.transaction_date,'YYYY/MM/DD') as         "伝票日付"
      , xlt.base_code                     as                  "出庫側拠点"
      , xlt.subinventory_code             as                  "出庫側倉庫"
      , msiin.attribute7                  as                  "入庫側拠点"
      , xlt.inside_warehouse_code         as                  "入庫側営業車"
      , msiin.attribute3                  as                  "担当者"
      , SUBSTRB(msiin.description, 1, 20) as                  "担当者名"
      , mc.description                    as                  "本社商品区分"
      , xsib.vessel_group                 as                  "容器群"
      , xiy.meaning                       as                  "容器群名"
      , msibp.segment1                    as                  "親品目"
      , msibp.description                 as                  "親品目名"
      , ximbp.item_short_name             as                  "親品目略称"
      , msibc.segment1                    as                  "子品目"
      , msibc.description                 as                  "子品目名"
      , ximbc.item_short_name             as                  "子品目略称"
      , xlt.lot                           as                  "ロット"
      , xlt.difference_summary_code       as                  "固有記号"
      , xlt.location_code                 as                  "ロケーション"
      , xlt.case_in_qty                   as                  "入数"
      , -xlt.case_qty                     as                  "ケース数"
      , -xlt.singly_qty                   as                  "バラ数"
      , -xlt.summary_qty                  as                  "取引数量"
      , xlt.transaction_uom               as                  "基準単位"
      , xlt.transfer_subinventory         as                  "倉替先メイン倉庫"
      , xlt.transaction_type_code         as                  "取引タイプ"
      , flv.meaning                       as                  "タイプ名"
      , to_char(xlt.creation_date,'YYYY/MM/DD HH24:MI:SS') as "引当日時"
FROM    xxcoi_lot_transactions            xlt
      , mtl_secondary_inventories         msiin
      , mtl_system_items_b                msibp
      , mtl_system_items_b                msibc
      , fnd_lookup_values                 flv
      , ic_item_mst_b                     iimbp
      , xxcmn_item_mst_b                  ximbp
      , ic_item_mst_b                     iimbc
      , xxcmn_item_mst_b                  ximbc
      , mtl_category_sets                 mcs
      , mtl_item_categories               mic
      , mtl_categories                    mc
      , xxcmm_system_items_b              xsib
      ,(SELECT flvv.lookup_code
              ,flvv.meaning
        FROM   apps.fnd_lookup_types_vl   fltv
              ,apps.fnd_lookup_values_vl  flvv
              ,apps.fnd_application_tl    fat
              ,apps.fnd_application       fa
        WHERE  fltv.lookup_type         = flvv.lookup_type(+)
        AND    fltv.application_id      = fat.application_id
        AND    fltv.view_application_id = fa.application_id
        AND    fat.language             = 'JA'
        AND    fltv.lookup_type         = 'XXCMM_ITM_YOKIGUN') xiy --参照タイプ：容器群
WHERE   xlt.inside_warehouse_code       = msiin.secondary_inventory_name
AND     xlt.parent_item_id              = msibp.inventory_item_id
AND     xlt.child_item_id               = msibc.inventory_item_id
AND     msibp.organization_id           = xxcoi_common_pkg.get_organization_id( fnd_profile.value( 'XXCOI1_ORGANIZATION_CODE' ) )
AND     msibc.organization_id           = xxcoi_common_pkg.get_organization_id( fnd_profile.value( 'XXCOI1_ORGANIZATION_CODE' ) )
AND     msibp.segment1                  = iimbp.item_no
AND     iimbp.item_id                   = ximbp.item_id
AND     SYSDATE BETWEEN ximbp.start_date_active AND ximbp.end_date_active
AND     msibc.segment1                  = iimbc.item_no
AND     iimbc.item_id                   = ximbc.item_id
AND     SYSDATE BETWEEN ximbc.start_date_active AND ximbc.end_date_active
AND     msibp.inventory_item_id         = mic.inventory_item_id
AND     msibp.organization_id           = mic.organization_id
AND     mcs.category_set_name           = '本社商品区分'
AND     mcs.category_set_id             = mic.category_set_id
AND     mic.category_id                 = mc.category_id
AND     flv.lookup_type                 = 'XXCOI1_TRANSACTION_TYPE_NAME'
AND     flv.language                    = USERENV( 'LANG' )
AND     flv.lookup_code                 = xlt.transaction_type_code
and     msibp.segment1                  = xsib.ITEM_CODE
and     xsib.vessel_group               = xiy.lookup_code(+)
AND     xlt.transaction_date           >= TRUNC(SYSDATE)-14
--  検索条件（作成日時）
and     xlt.creation_date              >= TO_DATE('&1', 'YYYY/MM/DD HH24:MI:SS' ) --パラメータ：作成日時
order by xlt.slip_num , xlt.transaction_date ,xlt.inside_warehouse_code , mc.description , xsib.vessel_group , msibp.segment1 , msibc.segment1) a
;

--Prompt
--Prompt ********************************************************************************
--Prompt ********************* END ******************************************************
--Prompt ********************************************************************************
--Prompt

exit;
