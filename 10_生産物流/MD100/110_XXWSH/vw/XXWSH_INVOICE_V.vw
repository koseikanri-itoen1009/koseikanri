CREATE OR REPLACE VIEW xxwsh_invoice_v
(
  biz_type,
  distribution_block,
  freight_carrier_code,
  prod_class_code,
  order_type_id,
  arrival_date,
  arrival_time_from,
  delivery_no,
  request_no,
  small_quantity,
  cust_po_number,
  shipped_date,
  deliver_from,
  shipped_zip,
  shipped_address,
  shipped_name,
  shipped_phone,
  deli_shitei,
  party_name,
  deliver_to,
  ship_zip,
  ship_address,
  ship_name,
  ship_phone
  )
AS
SELECT
  ---------------------------------------------------------------------------------
  -- パラメータ指定項目
  -- 業務種別共通
   TO_CHAR('1')                       AS  biz_type               --"業務種別"
  ,xilv.distribution_block            AS  distribution_block     --"物流ブロック"
  ,CASE
     WHEN (xoha.req_status = '04') THEN xoha.result_freight_carrier_code
     WHEN (xoha.req_status = '03') THEN xoha.freight_carrier_code
   END                                AS  freight_carrier_code   --"運送業者"
  ,xoha.prod_class                    AS  prod_class_code        --"商品区分"
  -- 出荷支給用パラメータ
  ,xoha.order_type_id                 AS  order_type_id          --"受注タイプID"
  ---------------------------------------------------------------------------------
  -- 共通出力項目
  ,CASE
    WHEN (xoha.req_status = '04')  THEN xoha.arrival_date
    WHEN (xoha.req_status = '03')  THEN xoha.schedule_arrival_date
   END                                AS  arrival_date           --"着荷予定日"
  ,xoha.arrival_time_from             AS  arrival_time_from      --"時間指定"
  ,xoha.delivery_no                   AS  delivery_no            --"配送No"
  ,xoha.request_no                    AS  request_no             --"依頼No/移動No"
  ,xoha.small_quantity                AS  small_quantity         --"個数"
  ,xoha.cust_po_number                AS  cust_po_number         --"顧客発注No"
  ,CASE
    WHEN (xoha.req_status = '04')  THEN xoha.shipped_date
    WHEN (xoha.req_status = '03')  THEN xoha.schedule_ship_date
   END                                AS  shipped_date           --"出庫予定日"
  ,xoha.deliver_from                  AS  deliver_from           --"出庫元(コード)"
  ,xlv.zip                            AS  shipped_zip            --"出庫元(郵便番号)"
  ,xlv.address_line1                  AS  shipped_address        --"出庫元(住所)"
  ,xilv.description                   AS  shipped_name           --"出庫元(名称)"
  ,xlv.phone                          AS  shipped_phone          --"出庫元(電話番号)"
  ,TO_CHAR('配達指定　有 ・ 無')      AS  deli_shitei            --"配達指定"
  ---------------------------------------------------------------------------------
  ,xcav.party_name                   AS  party_name              --"管轄拠点"
  ,CASE
    WHEN (xoha.req_status = '04')  THEN xoha.result_deliver_to
    WHEN (xoha.req_status = '03')  THEN xoha.deliver_to
   END                                AS  deliver_to             --"配送先/入庫先(コード)"
  ,CASE
    WHEN (xoha.req_status = '04')  THEN xcasv1.zip
    WHEN (xoha.req_status = '03')  THEN xcasv2.zip
   END                                AS  ship_zip               --"配送先/入庫先(郵便番号)"
  ,CASE
    WHEN (xoha.req_status = '04')  THEN xcasv1.address_line1
    WHEN (xoha.req_status = '03')  THEN xcasv2.address_line1 || xcasv2.address_line2
   END                                AS  ship_address           --"配送先/入庫先(住所)"
  ,CASE
    WHEN (xoha.req_status = '04')  THEN xcasv1.party_site_full_name
    WHEN (xoha.req_status = '03')  THEN xcasv2.party_site_full_name
   END                                AS  ship_name               --"配送先/入庫先(名称)"
  ,CASE
    WHEN (xoha.req_status = '04')  THEN xcasv1.phone
    WHEN (xoha.req_status = '03')  THEN xcasv2.phone
   END                                AS  ship_phone              --"配送先/入庫先(電話番号)"
FROM
   xxwsh_order_headers_all        xoha    -- 受注ヘッダアドオン
  ,xxwsh_order_lines_all          xola    -- 受注明細アドオン
  ,xxwsh_oe_transaction_types2_v  xottv   -- 受注タイプ情報VIEW2
  ,xxcmn_item_locations2_v        xilv    -- OPM保管場所情報(出荷元情報)(実績)
  ,xxcmn_locations2_v             xlv     -- 事業所情報(出荷元情報)
  ,xxcmn_cust_acct_sites2_v       xcasv1  -- 顧客サイト情報(出荷先情報)(実績)
  ,xxcmn_cust_acct_sites2_v       xcasv2  -- 顧客サイト情報(出荷先情報)(指示)
  ,xxcmn_cust_accounts2_v         xcav    -- 顧客情報VIEW2
WHERE
  ----------------------------------------------------------------------------------
  -- ヘッダ情報
       xoha.order_type_id           = xottv.transaction_type_id
  AND  xottv.order_category_code   <> 'RETURN'   -- 受注カテゴリ：返品
  AND  xoha.req_status             <> '99'       -- ステータス：取消
  AND  xottv.shipping_shikyu_class  = '1'        -- 出荷支給区分：「出荷依頼」
  AND  xoha.req_status             >= '03'       -- ステータス：「締め済み」
  AND  xoha.latest_external_flag    = 'Y'        -- 最新フラグ
  -- 出荷元情報
  AND  xoha.deliver_from_id         = xilv.inventory_location_id
  AND  xilv.location_id             = xlv.location_id
  -- 出荷先情報
  AND  xoha.head_sales_branch       =  xcav.party_number
  AND  xoha.result_deliver_to_id    = xcasv1.party_site_id(+)
  AND  xoha.deliver_to_id    = xcasv2.party_site_id(+)
  ----------------------------------------------------------------------------------
  -- 明細情報
  AND  xoha.order_header_id         =  xola.order_header_id
  AND  NVL(xola.delete_flag,0)     <>  'Y'
  ----------------------------------------------------------------------------------
  -- 適用日
  --"事業所.適用開始日"
  AND xlv.start_date_active        <= xoha.schedule_ship_date
  --"事業所.適用終了日"
  AND ( xlv.end_date_active IS NULL
        OR
        xlv.end_date_active        >= xoha.schedule_ship_date
      )
  --"顧客.適用開始日"(実績)
  AND ( xcasv1.start_date_active IS NULL
        OR
        xcasv1.start_date_active   <= xoha.shipped_date
      )
  --"顧客.適用終了日"(実績)
  AND ( xcasv1.end_date_active IS NULL
        OR
        xcasv1.end_date_active     >= xoha.shipped_date
      )
  --"顧客.適用開始日"(指示)
  AND ( xcasv2.start_date_active IS NULL
        OR
        xcasv2.start_date_active   <= xoha.schedule_ship_date
      )
  --"顧客.適用終了日"(指示)
  AND ( xcasv2.end_date_active IS NULL
        OR
        xcasv2.end_date_active     >= xoha.schedule_ship_date
      )
  --"顧客情報.適用開始日"
  AND xcav.start_date_active       <= xoha.schedule_ship_date
  --"顧客情報.適用終了日"
  AND ( xcav.end_date_active IS NULL
        OR
        xcav.end_date_active       >= xoha.schedule_ship_date
      )
--------------------------------------------------------------------------------
UNION ALL
--支給依頼情報の抽出
SELECT
  ---------------------------------------------------------------------------------
  -- パラメータ指定項目
  -- 業務種別共通
   TO_CHAR('2')                       AS  biz_type               --"業務種別"
  ,xilv.distribution_block            AS  distribution_block     --"物流ブロック"
  ,CASE
    WHEN (xoha.req_status = '08') THEN xoha.result_freight_carrier_code
    WHEN (xoha.req_status = '07') THEN xoha.freight_carrier_code
   END                                AS  freight_carrier_code   --"運送業者"
  ,xoha.prod_class                    AS  prod_class_code        --"商品区分"
  -- 出荷支給用パラメータ
  ,xoha.order_type_id                 AS  order_type_id          --"受注タイプID"
  ---------------------------------------------------------------------------------
  -- 共通出力項目
  ,CASE
    WHEN (xoha.req_status = '08') THEN xoha.arrival_date
    WHEN (xoha.req_status = '07') THEN xoha.schedule_arrival_date
   END                                AS  arrival_date           --"着荷予定日"
  ,xoha.arrival_time_from             AS  arrival_time_from      --"時間指定"
  ,xoha.delivery_no                   AS  delivery_no            --"配送No"
  ,xoha.request_no                    AS  request_no             --"依頼No/移動No"
  ,xoha.small_quantity                AS  small_quantity         --"個数"
  ,xoha.cust_po_number                AS  cust_po_number         --"顧客発注No"
  ,CASE
    WHEN (xoha.req_status = '08') THEN xoha.shipped_date
    WHEN (xoha.req_status = '07') THEN xoha.schedule_ship_date
   END                                AS  shipped_date           --"出庫予定日"
  ,xoha.deliver_from                  AS  deliver_from           --"出庫元(コード)"
  ,xlv.zip                            AS  shipped_zip            --"出庫元(郵便番号)"
  ,xlv.address_line1                  AS  shipped_address        --"出庫元(住所)"
  ,xilv.description                   AS  shipped_name           --"出庫元(名称)"
  ,xlv.phone                          AS  shipped_phone          --"出庫元(電話番号)"
  ,TO_CHAR('配達指定　有 ・ 無')      AS  deli_shitei            --"配達指定"
  ---------------------------------------------------------------------------------
  ,NULL                               AS  party_name   --"管轄拠点"
  ,xoha.vendor_site_code              AS  deliver_to             --"配送先/入庫先(コード)"
  ,CASE
    WHEN  (xoha.req_status = '08') THEN xvsv1.zip
    WHEN  (xoha.req_status = '07') THEN xvsv2.zip
   END                                AS  ship_zip               --"配送先/入庫先(郵便番号)"
  ,CASE
    WHEN  (xoha.req_status = '08') THEN xvsv1.address_line1 || xvsv1.address_line2
    WHEN  (xoha.req_status = '07') THEN xvsv2.address_line1 || xvsv2.address_line2
   END                                AS  ship_address           --"配送先/入庫先(住所)"
  ,CASE
    WHEN  (xoha.req_status = '08') THEN xvsv1.vendor_site_name
    WHEN  (xoha.req_status = '07') THEN xvsv2.vendor_site_name
   END                                AS  ship_name              --"配送先/入庫先(名称)"
  ,CASE
    WHEN  (xoha.req_status = '08') THEN xvsv1.phone
    WHEN  (xoha.req_status = '07') THEN xvsv2.phone
   END                                AS  ship_phone             --"配送先/入庫先(電話番号)"
FROM
   xxwsh_order_headers_all        xoha    -- 受注ヘッダアドオン
  ,xxwsh_order_lines_all          xola    -- 受注明細アドオン
  ,xxwsh_oe_transaction_types2_v  xottv   -- 受注タイプ情報VIEW2
  ,xxcmn_item_locations2_v        xilv    -- OPM保管場所情報(出荷元情報)
  ,xxcmn_locations2_v             xlv     -- 事業所情報(出荷元情報)
  ,xxcmn_vendor_sites2_v          xvsv1   -- 仕入先サイト情報(実績用)
  ,xxcmn_vendor_sites2_v          xvsv2   -- 仕入先サイト情報(指示用)
WHERE
  ----------------------------------------------------------------------------------
  -- ヘッダ情報
       xoha.order_type_id           = xottv.transaction_type_id
  AND  xottv.order_category_code   <> 'RETURN'   -- 受注カテゴリ：返品
  AND  xoha.req_status             <> '99'       -- ステータス：取消
  AND  xottv.shipping_shikyu_class  = '2'        -- 出荷支給区分：「支給依頼」
  AND  xoha.req_status             >= '07'       -- ステータス：「受領済」
  AND  xoha.latest_external_flag    = 'Y'        -- 最新フラグ
  -- 出荷元情報
  AND  xoha.deliver_from_id         = xilv.inventory_location_id
  AND  xilv.location_id             =  xlv.location_id
  -- 仕入先サイト(実績用)
  AND  xoha.vendor_id               =  xvsv1.vendor_id(+)
  -- 仕入先サイト(指示用)
  AND  xoha.vendor_id               =  xvsv2.vendor_id(+)
  ----------------------------------------------------------------------------------
  -- 明細情報
  AND  xoha.order_header_id         =  xola.order_header_id
  AND  NVL(xola.delete_flag,0)     <>  'Y'
  ----------------------------------------------------------------------------------
  -- 適用日
  --"事業所.適用開始日"
  AND xlv.start_date_active        <= xoha.schedule_ship_date
  --"事業所.適用終了日"
  AND ( xlv.end_date_active IS NULL
        OR
        xlv.end_date_active        >= xoha.schedule_ship_date
      )
  --"仕入先.適用開始日"(実績)
  AND ( xvsv1.start_date_active IS NULL
        OR 
        xvsv1.start_date_active    <= xoha.shipped_date
      )
  --"仕入先.適用終了日"(実績)
  AND ( xvsv1.end_date_active IS NULL
        OR
        xvsv1.end_date_active      >= xoha.shipped_date
      )--
  --"仕入先.適用開始日"(指示)
  AND ( xvsv2.start_date_active IS NULL
        OR 
        xvsv2.start_date_active    <= xoha.schedule_ship_date
      )
  --"仕入先.適用終了日"(指示)
  AND ( xvsv2.end_date_active IS NULL
        OR
        xvsv2.end_date_active      >= xoha.schedule_ship_date
      )
--------------------------------------------------------------------------------
UNION ALL
--移動指示情報の抽出
SELECT
  ---------------------------------------------------------------------------------
  -- パラメータ指定項目
  -- 業務種別共通
   TO_CHAR('3')                        AS  biz_type               --"業務種別"
  ,xilv2.distribution_block            AS  distribution_block     --"物流ブロック"
  ,CASE
    WHEN (xmrih.status IN ('04','06')) THEN xmrih.actual_freight_carrier_code
    WHEN (xmrih.status IN ('02','03','05')) THEN xmrih.freight_carrier_code
    END                                AS  freight_carrier_code   --"運送業者"
  ,xmrih.item_class                    AS  prod_class_code        --"商品区分"
  -- 出荷支給用パラメータ
  ,NULL                                AS  order_type_id          --"受注タイプID"
  ---------------------------------------------------------------------------------
  -- 共通出力項目
  ,CASE
    WHEN (xmrih.status IN ('04','06')) THEN xmrih.actual_arrival_date
    WHEN (xmrih.status IN ('02','03','05')) THEN xmrih.schedule_arrival_date
   END                                 AS  arrival_date           --"着荷予定日"
  ,xmrih.arrival_time_from             AS  arrival_time_from      --"時間指定"
  ,xmrih.delivery_no                   AS  delivery_no            --"配送No"
  ,xmrih.mov_num                       AS  request_no             --"依頼No/移動No"
  ,xmrih.small_quantity                AS  small_quantity         --"個数"
  ,NULL                                AS  cust_po_number         --"顧客発注No"
  ,CASE
    WHEN (xmrih.status IN ('04','06')) THEN xmrih.actual_ship_date
    WHEN (xmrih.status IN ('02','03','05')) THEN xmrih.schedule_ship_date
   END                                 AS  shipped_date           --"出庫予定日"
  ,xmrih.shipped_locat_code            AS  deliver_from           --"出庫元(コード)"
  ,xlv2.zip                            AS  shipped_zip            --"出庫元(郵便番号)"
  ,xlv2.address_line1                  AS  shipped_address        --"出庫元(住所)"
  ,xilv2.description                   AS  shipped_name           --"出庫元(名称)"
  ,xlv2.phone                          AS  shipped_phone          --"出庫元(電話番号)"
  ,TO_CHAR('配達指定　有 ・ 無')       AS  deli_shitei            --"配達指定"
  ---------------------------------------------------------------------------------
  -- 業務種別ごと
  ,NULL                                AS  party_name             --"管轄拠点"
  ,xmrih.ship_to_locat_code            AS  deliver_to             --"配送先/入庫先(コード)"
  ,xlv1.zip                            AS  ship_zip               --"配送先/入庫先(郵便番号)"
  ,xlv1.address_line1                  AS  ship_address           --"配送先/入庫先(住所)"
  ,xilv1.description                   AS  ship_name              --"配送先/入庫先(名称)"
  ,xlv1.phone                          AS  ship_phone             --"配送先/入庫先(電話番号)"
FROM
   xxinv_mov_req_instr_headers    xmrih     -- 移動依頼/指示ヘッダ(アドオン)
  ,xxinv_mov_req_instr_lines      xmril     -- 移動依頼/指示明細(アドオン)
  ,xxcmn_item_locations2_v        xilv1     -- OPM保管場所情報(入庫先)
  ,xxcmn_item_locations2_v        xilv2     -- OPM保管場所情報(出庫元)
  ,xxcmn_locations2_v             xlv1      -- 事業所情報(入庫先)
  ,xxcmn_locations2_v             xlv2      -- 事業所情報(出庫元)
WHERE
  ----------------------------------------------------------------------------------
  -- ヘッダ情報
       xmrih.status            >= '02' --ステータス:依頼済
  AND  xmrih.status            <> '99' --ステータス:取消
  AND  xmrih.mov_type           = '1'  --ステータス:積送あり
  -- 入庫先
  AND  xmrih.ship_to_locat_id   =  xilv1.inventory_location_id
  AND  xilv1.location_id        =  xlv1.location_id
  -- 出庫元
  AND  xmrih.shipped_locat_id   =  xilv2.inventory_location_id
  AND  xilv2.location_id        =  xlv2.location_id
  ----------------------------------------------------------------------------------
  -- 明細情報
  AND  xmrih.mov_hdr_id         = xmril.mov_hdr_id
  AND  xmril.delete_flg        <> 'Y'
  ----------------------------------------------------------------------------------
  -- 適用日
  --"入庫先.適用開始日"
  AND xlv1.start_date_active   <= xmrih.schedule_ship_date
  --"入庫先.適用終了日"
  AND ( xlv1.end_date_active IS NULL
        OR
        xlv1.end_date_active   >= xmrih.schedule_ship_date
      )
  --"出庫元.適用開始日"
  AND xlv2.start_date_active   <= xmrih.schedule_ship_date
  --"出庫元.適用終了日"
  AND ( xlv2.end_date_active IS NULL
        OR
        xlv2.end_date_active   >= xmrih.schedule_ship_date
      )
  --"事業所(入庫先).適用開始日"
  AND xlv1.start_date_active   <= xmrih.schedule_ship_date
  --"事業所(入庫先).適用終了日"
  AND ( xlv1.end_date_active IS NULL
        OR
        xlv1.end_date_active   >= xmrih.schedule_ship_date
      )
  --"事業所(出庫元).適用開始日"
  AND xlv2.start_date_active   <= xmrih.schedule_ship_date
  --"事業所(出庫元).適用終了日"
  AND ( xlv2.end_date_active IS NULL
        OR
        xlv2.end_date_active   >= xmrih.schedule_ship_date
      )
  ------------------------------------------------------------------------------------
ORDER BY
   deliver_from  ASC
  ,shipped_date  ASC
  ,delivery_no   ASC
  ,deliver_to    ASC
/
COMMENT ON TABLE xxwsh_invoice_v IS '送り状VIEW'
/
COMMENT ON COLUMN xxwsh_invoice_v.biz_type is '業務種別'
/
COMMENT ON COLUMN xxwsh_invoice_v.distribution_block IS '物流ブロック'
/
COMMENT ON COLUMN xxwsh_invoice_v.freight_carrier_code IS '運送業者'
/
COMMENT ON COLUMN xxwsh_invoice_v.prod_class_code IS '商品区分'
/
COMMENT ON COLUMN xxwsh_invoice_v.order_type_id IS '受注タイプID'
/
COMMENT ON COLUMN xxwsh_invoice_v.arrival_date IS '着荷予定日'
/
COMMENT ON COLUMN xxwsh_invoice_v.arrival_time_from IS '時間指定'
/
COMMENT ON COLUMN xxwsh_invoice_v.delivery_no IS '配送NO'
/
COMMENT ON COLUMN xxwsh_invoice_v.request_no IS '依頼NO/移動NO'
/
COMMENT ON COLUMN xxwsh_invoice_v.small_quantity IS '個数'
/
COMMENT ON COLUMN xxwsh_invoice_v.cust_po_number IS '顧客発注NO'
/
COMMENT ON COLUMN xxwsh_invoice_v.shipped_date IS '出庫予定日'
/
COMMENT ON COLUMN xxwsh_invoice_v.deliver_from IS '出庫元(コード)'
/
COMMENT ON COLUMN xxwsh_invoice_v.shipped_zip IS '出庫元(名称)'
/
COMMENT ON COLUMN xxwsh_invoice_v.shipped_address IS '出庫元(郵便番号)'
/
COMMENT ON COLUMN xxwsh_invoice_v.shipped_name IS '出庫元(住所)'
/
COMMENT ON COLUMN xxwsh_invoice_v.shipped_phone IS '出庫元(電話番号)'
/
COMMENT ON COLUMN xxwsh_invoice_v.deli_shitei IS '配達指定'
/
COMMENT ON COLUMN xxwsh_invoice_v.party_name IS '管轄拠点'
/
COMMENT ON COLUMN xxwsh_invoice_v.deliver_to IS '配送先/入庫先(コード)'
/
COMMENT ON COLUMN xxwsh_invoice_v.ship_zip IS '配送先/入庫先(名称)'
/
COMMENT ON COLUMN xxwsh_invoice_v.ship_address IS '配送先/入庫先(郵便番号)'
/
COMMENT ON COLUMN xxwsh_invoice_v.ship_name IS '配送先/入庫先(住所)'
/
COMMENT ON COLUMN xxwsh_invoice_v.ship_phone IS '配送先/入庫先(電話番号)'
/
