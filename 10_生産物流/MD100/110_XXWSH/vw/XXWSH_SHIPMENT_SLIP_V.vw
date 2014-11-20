CREATE OR REPLACE VIEW xxwsh_shipment_slip_v
(
  gyomu_class,
  plan_type,
  request_no,
  head_sales_branch,
  party_name,
  deliver_to,
  party_site_full_name,
  address_line,
  deliver_from,
  shipped_name,
  shipped_date,
  arrival_date,
  shipping_instructions,
  cust_po_number,
  item_class_code,
  shipping_item_code,
  item_short_name,
  case_quantity,
  lot_no,
  num_of_cases,
  quantity,item_um,
  freight_carrier_code,
  delivery_no,
  block,
  prod_class,
  order_type_id,
  inventory_location_id,
  xvs2v_start_date_active,
  xvs2v_end_date_active,
  xv2v_start_date_active,
  xv2v_end_date_active
  )
AS
SELECT
   TO_CHAR ( '1' )                                     AS    gyomu_class         -- 業務種別
  ,TO_CHAR ( '2' )                                     AS    plan_type           -- 予定/実績区分
  ,xoha.request_no                                     AS    request_no          -- 伝票No
  ,xoha.head_sales_branch                              AS    head_sales_branch   -- 管轄拠点(コード)
  ,xcav.party_name                                     AS    party_name          -- 管轄拠点(名称)
  ,xoha.deliver_to                                     AS    deliver_to          -- 配送先(コード)
  ,xcas2v.party_site_full_name                         AS    party_site_full_name-- 配送先(名称)
  , ( xcas2v.address_line1 || xcas2v.address_line2 )   AS    address_line        -- 住所
  ,xoha.deliver_from                                   AS    deliver_from        -- 出庫元(コード)
  ,xil2v.description                                   AS    shipped_name        -- 出庫元(名称)
  ,xoha.shipped_date                                   AS    shipped_date
  ,xoha.arrival_date                                   AS    arrival_date        -- 到着日
  ,xoha.shipping_instructions                          AS    shipping_instructions    -- 摘要
  ,xoha.cust_po_number                                 AS    cust_po_number      -- 受注No
  ,xic4v.item_class_code                               AS    item_class_code     -- 品目区分
  ,xola.shipping_item_code                             AS    shipping_item_code  -- コード(品目)
  ,xim2v.item_short_name                               AS    item_short_name     -- 商品名
  ,CASE 
    WHEN ( xola.reserved_quantity IS NULL ) THEN 
     TRUNC ( ( xola.quantity /  xim2v.num_of_cases ),3 )
    ELSE 
       xola.quantity
   END                                                 AS   case_quantity        -- ケース数量
  ,ilm.attribute3                                      AS   lot_no               -- ロットNo
  ,xim2v.num_of_cases                                  AS   num_of_cases         -- 入数
  ,xmld.actual_quantity                                AS   actual_quantity      -- 数量
  ,xim2v.item_um                                       AS   item_um              -- 単位
  ,xoha.result_freight_carrier_code                    AS   freight_carrier_code -- 運送業者
  ,xoha.delivery_no                                    AS   delivery_no          -- 配送No
------------------------------------------------------------------------------------------------
  ,xil2v.distribution_block                            AS   block                -- ブロック
  ,xoha.prod_class                                     AS   prod_class           -- 商品区分
  ,xoha.order_type_id                                  AS   order_type_id
  ,xil2v.inventory_location_id                         AS   inventory_location_id
  ,NULL                                                AS   xvs2v_start_date_active
  ,NULL                                                AS   xvs2v_end_date_active
  ,NULL                                                AS   xv2v_start_date_active
  ,NULL                                                AS   xv2v_end_date_active
----------------------------------------------------------------------------------------------------
FROM   xxwsh_order_headers_all          xoha         -- 受注ヘッダアドオン
      ,xxwsh_order_lines_all            xola         -- 受注明細アドオン
      ,xxcmn_item_locations2_v          xil2v        -- OPM保管場所情報VIEW2  
      ,xxwsh_oe_transaction_types2_v    xott2v       -- 受注タイプ情報VIEW2
      ,xxinv_mov_lot_details            xmld         -- 移動ロット詳細 ( アドオン ) 
      ,xxcmn_item_mst2_v                xim2v        -- OPM品目情報VIEW2
      ,xxcmn_item_categories4_v         xic4v        -- OPM品目カテゴリ割当情報VIEW4
      ,ic_lots_mst                      ilm          -- OPMロットマスタ
      ,xxcmn_cust_acct_sites2_v         xcas2v       -- 顧客サイト
      ,xxcmn_cust_accounts2_v           xcav         -- 顧客情報VIEW2
WHERE     xoha.req_status               =            '04' -- 出荷実績計上済
      AND xott2v.order_category_code    <> 'RETURN'
      AND xott2v.shipping_shikyu_class  =            '1'   -- 出荷依頼
      AND xoha.order_type_id            =            xott2v.transaction_type_id 
      AND xoha.latest_external_flag     =            'Y' 
      AND xoha.head_sales_branch        =            xcav.party_number
      AND xoha.result_deliver_to_id     =            xcas2v.party_site_id
      AND xoha.deliver_from_id          =            xil2v .inventory_location_id 
      AND xoha.order_header_id          =            xola.order_header_id
      AND xola.delete_flag              =            'N'
      AND xola.order_line_id            =            xmld.mov_line_id(+)
      AND xola.shipping_inventory_item_id =          xim2v.inventory_item_id
      AND xim2v.item_id                 =            xic4v.item_id
      AND xmld.lot_id                   =            ilm.lot_id(+)
      AND xmld.item_id                  =            ilm.item_id(+)
      AND xmld.document_type_code(+)    =            '10'      --出荷依頼
      AND xmld.record_type_code(+)      =            '20'      --出庫実績
  --------------------------------------------------------------------------------------------
      AND xcav.start_date_active        <=   xoha.shipped_date
      AND ( xcav.end_date_active IS NULL
            OR ( xcav.end_date_active   >=   xoha.shipped_date ) )
  --------------------------------------------------------------------------------------------
      AND  xcas2v.start_date_active     <=   xoha.shipped_date
      AND ( xcas2v.end_date_active IS NULL
            OR ( xcas2v.end_date_active >=   xoha.shipped_date ) )
  --------------------------------------------------------------------------------------------
      AND  xim2v.start_date_active      <=   xoha.shipped_date
      AND ( xim2v.end_date_active IS NULL
            OR ( xim2v.end_date_active  >=   xoha.shipped_date ) )
------------------------------------------------------------------------------------------------------------------------------------------------------------------------
UNION
------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT
   TO_CHAR ( '1' )                                     AS    gyomu_class         -- 業務種別
  ,TO_CHAR ( '1' )                                     AS    plan_type           -- 予定/実績区分
  ,xoha.request_no                                     AS    request_no          -- 伝票No
  ,xoha.head_sales_branch                              AS    head_sales_branch   -- 管轄拠点(コード)
  ,xcav.party_name                                     AS    party_name          -- 管轄拠点(名称)
  ,xoha.deliver_to                                     AS    deliver_to          -- 配送先(コード)
  ,xcas2v.party_site_full_name                         AS    party_site_full_name-- 配送先(名称)
  , ( xcas2v.address_line1 || xcas2v.address_line2 )   AS    address_line        -- 住所
  ,xoha.deliver_from                                   AS    deliver_from        -- 出庫元(コード)
  ,xil2v.description                                   AS    shipped_name        -- 出庫元(名称)
  ,xoha.schedule_ship_date                             AS    shipped_date
  ,xoha.schedule_arrival_date                          AS    arrival_date        -- 到着日
  ,xoha.shipping_instructions                          AS    shipping_instructions    -- 摘要
  ,xoha.cust_po_number                                 AS    cust_po_number      -- 受注No
  ,xic4v.item_class_code                               AS    item_class_code     -- 品目区分
  ,xola.shipping_item_code                             AS    shipping_item_code  -- コード(品目)
  ,xim2v.item_short_name                               AS    item_short_name     -- 商品名
  ,CASE
   -- 引当されている場合
    WHEN ( xola.reserved_quantity > 0 ) THEN
      CASE 
        WHEN  ( ( xic4v.item_class_code = '5' )
        AND     ( xim2v.conv_unit IS NOT NULL  ) ) THEN
          TRUNC (xmld.actual_quantity / TO_NUMBER(
                                            CASE
                                              WHEN ( xim2v.num_of_cases > 0 ) THEN
                                                xim2v.num_of_cases
                                              ELSE
                                                TO_CHAR(1)
                                            END
                                          ),3 )
        ELSE
          xmld.actual_quantity
    END
    -- 引当されていない場合
    WHEN  ( ( xola.reserved_quantity IS NULL ) 
              OR ( xola.reserved_quantity = 0 ) ) THEN
      CASE 
        WHEN  ( ( xic4v.item_class_code = '5' )
        AND     ( xim2v.conv_unit IS NOT NULL ) ) THEN
          TRUNC (xola.quantity / TO_NUMBER(
                                     CASE
                                       WHEN ( xim2v.num_of_cases > 0 ) THEN
                                         xim2v.num_of_cases
                                       ELSE
                                         TO_CHAR(1)
                                       END
                                   ),3 )
        ELSE
          xola.quantity
      END
    END                                                AS     case_quantity      -- ケース数量
  ,ilm.attribute3                                      AS     lot_no             -- ロットNo
  ,xim2v.num_of_cases                                  AS     num_of_cases       -- 入数
  ,CASE 
    --引当されている場合
    WHEN ( xola.reserved_quantity > 0 ) THEN ( 
      xmld.actual_quantity                                   --移動ロット詳細の実績数量を取得
    ) 
    --引当されていない場合  
    WHEN  ( ( xola.reserved_quantity IS NULL ) 
              OR  ( xola.reserved_quantity = 0 ) ) THEN ( 
      xola.quantity                                          --受注明細アドオンの数量を取得
    )
   END                                                 AS    actual_quantity      -- 数量
  ,xim2v.item_um                                       AS    item_um              -- 単位
  ,xoha.freight_carrier_code                           AS    freight_carrier_code -- 運送業者
  ,xoha.delivery_no                                    AS    delivery_no          -- 配送No
-------------------------------------------------------------------------------------------------
  ,xil2v.distribution_block                            AS    block                -- ブロック
  ,xoha.prod_class                                     AS    prod_class           -- 商品区分
  ,xoha.order_type_id                                  AS    order_type_id
  ,xil2v.inventory_location_id                         AS    inventory_location_id
  ,NULL                                                AS    xvs2v_start_date_active
  ,NULL                                                AS    xvs2v_end_date_active
  ,NULL                                                AS    xv2v_start_date_active
  ,NULL                                                AS    xv2v_end_date_active
----------------------------------------------------------------------------------------------------
FROM   xxwsh_order_headers_all          xoha         -- 受注ヘッダアドオン
      ,xxwsh_order_lines_all            xola         -- 受注明細アドオン
      ,xxcmn_item_locations2_v          xil2v        -- OPM保管場所情報VIEW2  
      ,xxwsh_oe_transaction_types2_v    xott2v       -- 受注タイプ情報VIEW2
      ,xxinv_mov_lot_details            xmld         -- 移動ロット詳細 ( アドオン ) 
      ,xxcmn_item_mst2_v                xim2v        -- OPM品目情報VIEW2
      ,xxcmn_item_categories4_v         xic4v        -- OPM品目カテゴリ割当情報VIEW4
      ,ic_lots_mst                      ilm          -- OPMロットマスタ
      ,xxcmn_cust_acct_sites2_v         xcas2v       -- 顧客サイト
      ,xxcmn_cust_accounts2_v           xcav         -- 顧客情報VIEW2
WHERE     xoha.req_status               =            '03' -- 出荷実績計上済
      AND xott2v.order_category_code    <>           'RETURN'
      AND xott2v.shipping_shikyu_class  =            '1'   -- 出荷依頼
      AND xoha.order_type_id            =            xott2v.transaction_type_id 
      AND xoha.latest_external_flag     =            'Y' 
      AND xoha.head_sales_branch        =            xcav.party_number
      AND xoha.deliver_to_id            =            xcas2v.party_site_id
      AND xoha.deliver_from_id          =            xil2v .inventory_location_id 
      AND xoha.order_header_id          =            xola.order_header_id
      AND xola.delete_flag              =            'N'
      AND xola.order_line_id            =            xmld.mov_line_id(+)
      AND xola.shipping_inventory_item_id =          xim2v.inventory_item_id
      AND xim2v.item_id                 =            xic4v.item_id
      AND xmld.lot_id                   =            ilm.lot_id(+)
      AND xmld.item_id                  =            ilm.item_id(+)
      AND xmld.document_type_code(+)    =            '10'      -- 出荷依頼
      AND xmld.record_type_code(+)      =            '10'      -- 指示
  --------------------------------------------------------------------------------------------
      AND xcav.start_date_active        <=   xoha.schedule_ship_date
      AND ( xcav.end_date_active IS NULL
            OR ( xcav.end_date_active   >=   xoha.schedule_ship_date ) )
  --------------------------------------------------------------------------------------------
      AND xcas2v.start_date_active      <=   xoha.schedule_ship_date
      AND ( xcas2v.end_date_active IS NULL
            OR ( xcas2v.end_date_active >=   xoha.schedule_ship_date ) ) 
  --------------------------------------------------------------------------------------------
      AND  xim2v.start_date_active      <=   xoha.schedule_ship_date
      AND ( xim2v.end_date_active IS NULL
            OR ( xim2v.end_date_active  >=   xoha.schedule_ship_date ) ) 
------------------------------------------------------------------------------------------------------------------------------------------------------------------------
UNION
------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 支給
SELECT
   TO_CHAR ( '2' )                                     AS    gyomu_class         -- 支給
  ,TO_CHAR ( '2' )                                     AS    plan_type           -- 予定/実績区分
  ,xoha.request_no                                     AS    request_no          -- 伝票No
  ,xoha.vendor_code                                    AS    head_sales_branch   -- 管轄拠点(コード)
  ,xv2v.vendor_full_name                               AS    party_name          -- 管轄拠点(名称)
  ,xoha.vendor_site_code                               AS    deliver_to          -- 配送先(コード)
  ,xvs2v.vendor_site_name                              AS    party_site_full_name-- 配送先(名称)
  , ( xvs2v.address_line1 || xvs2v.address_line2 )     AS    address_line        -- 住所
  ,xoha.deliver_from                                   AS    deliver_from        -- 出庫元(コード)
  ,xil2v.description                                   AS    shipped_name        -- 出庫元(名称)
  ,xoha.shipped_date                                   AS    shipped_date
  ,xoha.arrival_date                                   AS    arrival_date        -- 到着日
  ,xoha.shipping_instructions                          AS    shipping_instructions-- 摘要
  ,NULL                                                AS    cust_po_number      -- 受注No
  ,xic4v.item_class_code                               AS    item_class_code     -- 品目区分
  ,xola.shipping_item_code                             AS    shipping_item_code  -- コード(品目)
  ,xim2v.item_short_name                               AS    item_short_name     -- 商品名
  ,NULL                                                AS    case_quantity       -- ケース数量
  ,xmld.lot_no                                         AS    lot_no              -- ロットNo
  ,NULL                                                AS    num_of_cases        -- 入数
  ,CASE 
    WHEN ( xott2v.order_category_code   <> 'RETURN' ) THEN ( 
      xmld.actual_quantity 
    )
    WHEN ( xott2v.order_category_code   =  'RETURN' ) THEN (
      ( xmld.actual_quantity * -1 )
    ) 
  END                                                   AS    actual_quantity    -- 数量
  ,xim2v.item_um                                        AS   item_um             -- 単位
  ,xoha.result_freight_carrier_code                     AS   freight_carrier_code-- 運送業者
  ,xoha.delivery_no                                     AS   delivery_no         -- 配送No
-------------------------------------------------------------------------------------------------
  ,xil2v.distribution_block                             AS    block              -- ブロック
  ,xoha.prod_class                                      AS    prod_class         -- 商品区分
  ,xoha.order_type_id                                   AS    order_type_id
  ,xil2v.inventory_location_id                          AS    inventory_location_id
  ,xvs2v.start_date_active                              AS    xvs2v_start_date_active
  ,xvs2v.end_date_active                                AS    xvs2v_end_date_active
  ,xv2v.start_date_active                               AS    xv2v_start_date_active
  ,xv2v.end_date_active                                 AS    xv2v_end_date_active
---------------------------------------------------------------------------------------------------
FROM   
       xxwsh_order_headers_all          xoha         -- 受注ヘッダアドオン
      ,xxwsh_order_lines_all            xola         -- 受注明細アドオン
      ,xxcmn_vendor_sites2_v            xvs2v        -- 仕入先サイト情報VIEW2
      ,xxcmn_vendors2_v                 xv2v         -- 仕入先情報VIEW2
      ,xxcmn_item_locations2_v          xil2v        -- OPM保管場所情報VIEW2  
      ,xxwsh_oe_transaction_types2_v    xott2v       -- 受注タイプ情報VIEW2
      ,xxinv_mov_lot_details            xmld         -- 移動ロット詳細 ( アドオン ) 
      ,xxcmn_item_mst2_v                xim2v        -- OPM品目情報VIEW2
      ,xxcmn_item_categories4_v         xic4v        -- OPM品目カテゴリ割当情報VIEW4
      ,ic_lots_mst                      ilm          -- OPMロットマスタ
WHERE     xoha.req_status               =            '08'
      AND xott2v.shipping_shikyu_class  =            '2'  -- 支給依頼
      AND xoha.order_type_id            =            xott2v.transaction_type_id 
      AND xoha.latest_external_flag     =            'Y' 
      AND xoha.vendor_site_id           =            xvs2v.vendor_site_id
      AND xoha.vendor_id                =            xv2v.vendor_id
      AND xv2v.vendor_id                =            xvs2v.vendor_id
      AND xoha.deliver_from_id          =            xil2v.inventory_location_id 
      AND xoha.order_header_id          =            xola.order_header_id
      AND xola.delete_flag              =            'N'
      AND xola.order_line_id            =            xmld.mov_line_id(+)
      AND xola.shipping_inventory_item_id =          xim2v.inventory_item_id
      AND xim2v.item_id                 =            xic4v.item_id
      AND xmld.lot_id                   =            ilm.lot_id(+)
      AND xmld.item_id                  =            ilm.item_id(+)
      AND xmld.document_type_code(+)    =            '30'      -- 支給指示
      AND xmld.record_type_code(+)      =            '20'      -- 出庫実績
  --------------------------------------------------------------------------------------------
      AND xvs2v.start_date_active       <=   xoha.shipped_date
      AND ( xvs2v.end_date_active IS NULL
            OR (xvs2v.end_date_active  >=   xoha.shipped_date ) ) 
  --------------------------------------------------------------------------------------------
      AND xv2v.start_date_active        <=   xoha.shipped_date
      AND ( xv2v.end_date_active IS NULL
            OR ( xv2v.end_date_active   >=   xoha.shipped_date ) ) 
  --------------------------------------------------------------------------------------------
      AND xim2v.start_date_active       <=   xoha.shipped_date
      AND ( xim2v.end_date_active IS NULL
            OR ( xim2v.end_date_active  >=   xoha.shipped_date ) )
  --------------------------------------------------------------------------------------------
UNION
-- 支給
SELECT
   TO_CHAR ( '2' )                                     AS    gyomu_class              -- 支給
  ,TO_CHAR ( '1' )                                     AS    plan_type           -- 予定/実績区分
  ,xoha.request_no                                     AS    request_no          -- 伝票No
  ,xoha.vendor_code                                    AS    head_sales_branch -- 管轄拠点(コード)
  ,xv2v.vendor_full_name                               AS    party_name          -- 管轄拠点(名称)
  ,xoha.vendor_site_code                               AS    deliver_to          -- 配送先(コード)
  ,xvs2v.vendor_site_name                              AS    party_site_full_name-- 配送先(名称)
  , ( xvs2v.address_line1 || xvs2v.address_line2 )     AS    address_line        -- 住所
  ,xoha.deliver_from                                   AS    deliver_from        -- 出庫元(コード)
  ,xil2v.description                                   AS    shipped_name        -- 出庫元(名称)
  ,xoha.schedule_ship_date                             AS    shipped_date
  ,xoha.schedule_arrival_date                          AS    arrival_date      -- 到着日
  ,xoha.shipping_instructions                          AS    shipping_instructions-- 摘要
  ,NULL                                                AS    cust_po_number      -- 受注No
  ,xic4v.item_class_code                               AS    item_class_code     -- 品目区分
  ,xola.shipping_item_code                             AS    shipping_item_code  -- コード(品目)
  ,xim2v.item_short_name                               AS    item_short_name     -- 商品名
  ,NULL                                                AS    case_quantity       -- ケース数量
  ,xmld.lot_no                                         AS    lot_no              -- ロットNo
  ,NULL                                                AS    num_of_cases        -- 入数
  ,CASE 
    WHEN ( xott2v.order_category_code   <> 'RETURN' ) THEN ( 
      CASE 
        --引当されている場合
        WHEN ( xola.reserved_quantity  > 0  ) THEN ( 
          xmld.actual_quantity                       --移動ロット詳細の実績数量を取得
        ) 
        --引当されていない場合  
        WHEN ( ( xola.reserved_quantity IS NULL  ) 
                  OR ( xola.reserved_quantity = 0 ) ) THEN ( 
          xola.quantity                              --受注明細アドオンの数量を取得
        )
      END
    )  --移動ロット詳細の実績数量＊-1を取得
    WHEN ( xott2v.order_category_code   =  'RETURN' ) THEN (
      CASE 
        --引当されている場合
        WHEN ( xola.reserved_quantity  > 0  ) THEN ( 
          ( xmld.actual_quantity * -1 )              --移動ロット詳細の実績数量を取得
        ) 
        --引当されていない場合  
        WHEN  ( ( xola.reserved_quantity IS NULL  ) 
                  OR ( xola.reserved_quantity = 0 ) ) THEN ( 
          ( xola.quantity * -1 )                     --受注明細アドオンの数量を取得
        )
      END
    ) 
  END                                                  AS    actual_quantity     -- 数量
  ,xim2v.item_um                                       AS    item_um             -- 単位
  ,xoha.freight_carrier_code                           AS    freight_carrier_code-- 運送業者
  ,xoha.delivery_no                                    AS    delivery_no         -- 配送No
-------------------------------------------------------------------------------------------------
  ,xil2v.distribution_block                            AS    block               -- ブロック
  ,xoha.prod_class                                     AS    prod_class          -- 商品区分
  ,xoha.order_type_id                                  AS    order_type_id
  ,xil2v.inventory_location_id                         AS    inventory_location_id
  ,xvs2v.start_date_active                             AS    xvs2v_start_date_active
  ,xvs2v.end_date_active                               AS    xvs2v_end_date_active
  ,xv2v.start_date_active                              AS    xv2v_start_date_active
  ,xv2v.end_date_active                                AS    xv2v_end_date_active
---------------------------------------------------------------------------------------------------
FROM   
      xxwsh_order_headers_all           xoha         -- 受注ヘッダアドオン
      ,xxwsh_order_lines_all            xola         -- 受注明細アドオン
      ,xxcmn_vendor_sites2_v            xvs2v        -- 仕入先サイト情報VIEW2
      ,xxcmn_vendors2_v                 xv2v         -- 仕入先情報VIEW2
      ,xxcmn_item_locations2_v          xil2v        -- OPM保管場所情報VIEW2  
      ,xxwsh_oe_transaction_types2_v    xott2v       -- 受注タイプ情報VIEW2
      ,xxinv_mov_lot_details            xmld         -- 移動ロット詳細 ( アドオン ) 
      ,xxcmn_item_mst2_v                xim2v        -- OPM品目情報VIEW2
      ,xxcmn_item_categories4_v         xic4v        -- OPM品目カテゴリ割当情報VIEW4
      ,ic_lots_mst                      ilm          -- OPMロットマスタ
       --支給の場合
WHERE     xoha.req_status               =            '07' -- 出荷実績計上済
      AND xott2v.shipping_shikyu_class  =            '2'  -- 支給依頼
      AND xoha.order_type_id            =            xott2v.transaction_type_id 
      AND xoha.latest_external_flag     =            'Y' 
      AND xoha.vendor_site_id           =            xvs2v.vendor_site_id
      AND xoha.vendor_id                =            xv2v.vendor_id
      AND xv2v.vendor_id                =            xvs2v.vendor_id
      AND xoha.deliver_from_id          =            xil2v.inventory_location_id 
      AND xoha.order_header_id          =            xola.order_header_id
      AND xola.delete_flag              =            'N'
      AND xola.order_line_id            =            xmld.mov_line_id(+)
      AND xola.shipping_inventory_item_id =          xim2v.inventory_item_id
      AND xim2v.item_id                 =            xic4v.item_id
      AND xmld.lot_id                   =            ilm.lot_id(+)
      AND xmld.item_id                  =            ilm.item_id(+)
      AND xmld.document_type_code(+)    =            '30'      -- 支給指示
      AND xmld.record_type_code(+)      =            '10'      -- 指示
  --------------------------------------------------------------------------------------------
      AND xvs2v.start_date_active       <=   xoha.schedule_ship_date
      AND ( xvs2v.end_date_active IS NULL
            OR ( xvs2v.end_date_active  >=   xoha.schedule_ship_date ) )
  --------------------------------------------------------------------------------------------
      AND xv2v.start_date_active        <=   xoha.schedule_ship_date
      AND ( xv2v.end_date_active IS NULL
            OR ( xv2v.end_date_active   >=   xoha.schedule_ship_date ) )
  --------------------------------------------------------------------------------------------
      AND xim2v.start_date_active       <=   xoha.schedule_ship_date
      AND ( xim2v.end_date_active IS NULL
            OR ( xim2v.end_date_active  >=   xoha.schedule_ship_date ) )
  --------------------------------------------------------------------------------------------
/
COMMENT ON TABLE xxwsh_shipment_slip_v IS '出荷伝票view'
/
COMMENT ON COLUMN xxwsh_shipment_slip_v.gyomu_class IS '業務種別'
/
COMMENT ON COLUMN xxwsh_shipment_slip_v.plan_type IS '予定/実績区分'
/
COMMENT ON COLUMN xxwsh_shipment_slip_v.request_no IS '伝票NO'
/
COMMENT ON COLUMN xxwsh_shipment_slip_v.head_sales_branch IS '管轄拠点(コード)'
/
COMMENT ON COLUMN xxwsh_shipment_slip_v.party_name IS '管轄拠点(名称)'
/
COMMENT ON COLUMN xxwsh_shipment_slip_v.deliver_to IS '配送先(コード)'
/
COMMENT ON COLUMN xxwsh_shipment_slip_v.party_site_full_name IS '配送先(名称)'
/
COMMENT ON COLUMN xxwsh_shipment_slip_v.address_line IS '住所'
/
COMMENT ON COLUMN xxwsh_shipment_slip_v.deliver_from IS '出庫元(コード)'
/
COMMENT ON COLUMN xxwsh_shipment_slip_v.shipped_name IS '出庫元(名称)'
/
COMMENT ON COLUMN xxwsh_shipment_slip_v.shipped_date IS '出庫予定日'
/
COMMENT ON COLUMN xxwsh_shipment_slip_v.arrival_date IS '到着予定日'
/
COMMENT ON COLUMN xxwsh_shipment_slip_v.shipping_instructions IS '摘要'
/
COMMENT ON COLUMN xxwsh_shipment_slip_v.cust_po_number IS '受注NO'
/
COMMENT ON COLUMN xxwsh_shipment_slip_v.item_class_code IS '品目区分'
/
COMMENT ON COLUMN xxwsh_shipment_slip_v.shipping_item_code IS 'コード(品目)'
/
COMMENT ON COLUMN xxwsh_shipment_slip_v.item_short_name IS '商品名'
/
COMMENT ON COLUMN xxwsh_shipment_slip_v.case_quantity IS 'ケース'
/
COMMENT ON COLUMN xxwsh_shipment_slip_v.lot_no IS 'ロットNO'
/
COMMENT ON COLUMN xxwsh_shipment_slip_v.num_of_cases IS '入数'
/
COMMENT ON COLUMN xxwsh_shipment_slip_v.quantity IS '数量'
/
COMMENT ON COLUMN xxwsh_shipment_slip_v.item_um IS '単位'
/
COMMENT ON COLUMN xxwsh_shipment_slip_v.freight_carrier_code IS '運送業者'
/
COMMENT ON COLUMN xxwsh_shipment_slip_v.delivery_no IS '配送NO'
/
COMMENT ON COLUMN xxwsh_shipment_slip_v.block IS 'ブロック'
/
COMMENT ON COLUMN xxwsh_shipment_slip_v.prod_class IS '商品区分'
/
COMMENT ON COLUMN xxwsh_shipment_slip_v.order_type_id IS '出庫形態'
/
COMMENT ON COLUMN xxwsh_shipment_slip_v.inventory_location_id IS '倉庫ID'
/
COMMENT ON COLUMN xxwsh_shipment_slip_v.xvs2v_start_date_active IS '仕入先サイト適用開始日'
/
COMMENT ON COLUMN xxwsh_shipment_slip_v.xvs2v_end_date_active IS '仕入先サイト適用終了日'
/
COMMENT ON COLUMN xxwsh_shipment_slip_v.xv2v_start_date_active IS '仕入先適用開始日'
/
COMMENT ON COLUMN xxwsh_shipment_slip_v.xv2v_end_date_active IS '仕入先適用終了日'
/
