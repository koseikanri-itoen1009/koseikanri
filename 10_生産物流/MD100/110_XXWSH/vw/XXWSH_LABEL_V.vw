CREATE OR REPLACE VIEW xxwsh_label_v
(
 ship_type,
 order_type_id,
 deliver_from,
 career_code,
 schedule_ship_date,
 prod_class,
 delivery_no,
 deliver_to,
 block,
 request_no,
 small_quantity,
 label_quantity,
 party_site_name,
 address_line,
 phone
 )
AS
SELECT
  ---------------------------------------------------------------------------------
  -- パラメータ指定項目
  -- 業務種別共通
  TO_CHAR('1')                       AS  ship_type              --"業務種別"
  ,xoha.order_type_id                AS  order_type_id          --"出庫形態"
  ,xoha.deliver_from                 AS  deliver_from           --"出荷元ID"
  ,CASE
    WHEN (xoha.req_status = '04') THEN xoha.result_freight_carrier_code
    WHEN (xoha.req_status = '03') THEN xoha.freight_carrier_code
   END                               AS  career_code            --"運送業者"
  ,CASE
    WHEN (xoha.req_status = '04') THEN xoha.shipped_date
    WHEN (xoha.req_status = '03') THEN xoha.schedule_ship_date
   END                               AS  schedule_ship_date     --"出荷日"
  ,xoha.prod_class                   AS  prod_class             --"商品区分"
  ,xcs.delivery_no                   AS  delivery_no            --"配送No"
  ,xoha.deliver_to                   AS  deliver_to             --"配送先/入庫先"
  ,xilv.distribution_block           AS  block                  --"ブロック"
  ------------------------------------------------
  ,xoha.request_no                   AS  request_no             --"依頼No"
  ,xoha.small_quantity               AS  small_quantity         --"小口個数"
  ,xoha.label_quantity               AS  label_quantity         --"ラベル枚数"
  ,xcas.party_site_full_name         AS  party_site_name        --"正式名(顧客名)"
  ,( xcas.address_line1 || xcas.address_line2 ) AS address_line --"住所"
  ,xcas.phone                        AS  phone                  --"電話番号"
FROM
   xxwsh_order_headers_all           xoha          -- 受注ヘッダアドオン
  ,xxwsh_carriers_schedule           xcs           -- 配車配送計画(アドオン)
  ,xxcmn_cust_acct_sites2_v          xcas          -- 顧客サイト
  ,xxcmn_item_locations2_v           xilv          -- OPM保管場所マスタ2
  ,xxwsh_oe_transaction_types2_v     xottv         -- 受注タイプ
  ,xxwsh_ship_method2_v              xsm2v         -- 配送区分情報VIEW2
-- 2008.07.07 ADD S.Takemoto start
  ,xxcmn_lookup_values_v             xlvv
-- 2008.07.07 ADD S.Takemoto end
WHERE
  ----------------------------------------------------------------------------------
  -- ヘッダ情報
      xottv.shipping_shikyu_class   =   '1'        -- 出荷支給区分：「出荷依頼」
  AND xottv.order_category_code     =   'ORDER'    -- 受注カテゴリ：受注
  AND xoha.req_status               >=  '03'       -- ステータス：「締め済み」
  AND xoha.req_status               <>  '99'       -- ステータス：取消
  --------------------------------------------------------------------------------------------
  --------------------------------------------------------------------------------------------
-- 2008.07.03 ADD S.Takemoto start
  --------------------------------------------------------------------------------------------
  AND  xoha.latest_external_flag    = 'Y'        -- 最新フラグ
  --OPM保管場所情報(出荷元情報)(実績)
  AND  xoha.deliver_from_id = xilv.inventory_location_id                    --配送元ID = 倉庫ID
  AND   NVL(xoha.shipped_date,xoha.schedule_ship_date)                 --適用開始日 <= 出荷日(出荷予定日) <= 適用終了日
    BETWEEN xilv.date_from
    AND NVL(xilv.date_to,NVL(xoha.shipped_date,xoha.schedule_ship_date))
  -- 配送区分情報VIEW2
  AND   NVL(xoha.shipped_date,xoha.schedule_ship_date)                 --適用開始日 <= 出荷日(出荷予定日) <= 適用終了日
    BETWEEN xsm2v.start_date_active
    AND NVL(xsm2v.end_date_active,NVL(xoha.shipped_date,xoha.schedule_ship_date))
-- 2008.07.03 ADD S.Takemoto end
-- 2008.07.07 ADD S.Takemoto start
  AND xlvv.lookup_type    ='XXCMN_SHIP_METHOD' -- 配送区分
  AND xlvv.attribute6     = '1'  -- 小口区分：小口
  AND xlvv.lookup_code    = NVL(xoha.result_shipping_method_code,xoha.shipping_method_code) -- 配送区分
-- 2008.07.07 ADD S.Takemoto end
  AND  xoha.shipping_method_code    = xsm2v.ship_method_code
  AND  (CASE 
         WHEN  xoha.req_status = '03' THEN  xoha.deliver_to_id
         WHEN  xoha.req_status = '04' THEN  xoha.result_deliver_to_id
        END )          =    xcas.party_site_id ( + ) 
  AND  xoha.delivery_no             =    xcs.delivery_no
  AND  xoha.order_type_id           =    xottv.transaction_type_id
  --------------------------------------------------------------------------------------------
  AND ( xcas.start_date_active IS NULL
        OR ( ( xoha.req_status = '03' 
              AND 
               xcas.start_date_active       <=   xoha.schedule_ship_date )
           OR
             ( xoha.req_status = '04' 
              AND 
               xcas.start_date_active       <=   xoha.shipped_date ) ) 
  )
  --------------------------------------------------------------------------------------------
  AND ( xcas.end_date_active IS NULL
        OR ( ( xoha.req_status = '03' 
              AND 
               xcas.end_date_active         >=   xoha.schedule_ship_date )
           OR
             ( xoha.req_status = '04' 
              AND 
               xcas.end_date_active         >=   xoha.shipped_date ) ) 
  )
  --------------------------------------------------------------------------------------------
UNION 
SELECT
  ---------------------------------------------------------------------------------
  -- パラメータ指定項目
  -- 業務種別共通
  TO_CHAR('2')                       AS  ship_type              --"業務種別"
  ,xoha.order_type_id                AS  order_type_id          --"出庫形態"
  ,xoha.deliver_from                 AS  deliver_from           --"出荷元ID"
  ,CASE
    WHEN (xoha.req_status = '08') THEN xoha.result_freight_carrier_code
    WHEN (xoha.req_status = '07') THEN xoha.freight_carrier_code
   END                               AS  career_id              --"運送業者"
  ,CASE
    WHEN (xoha.req_status = '08') THEN xoha.shipped_date
    WHEN (xoha.req_status = '07') THEN xoha.schedule_ship_date
   END                               AS  schedule_ship_date     --"出荷日"
  ,xoha.prod_class                   AS  prod_class             --"商品区分"
  ,xcs.delivery_no                   AS  delivery_no            --"配送No"
  ,xoha.deliver_to                   AS  deliver_to             --"配送先/入庫先"
  ,xilv.distribution_block           AS  block                  --"ブロック"
  ------------------------------------------------
  ,xoha.request_no                   AS  request_no             --"依頼No"
  ,xoha.small_quantity               AS  small_quantity         --"小口個数"
  ,xoha.label_quantity               AS  label_quantity         --"ラベル枚数"
  ,xvsa.vendor_site_name             AS  party_site_name        --"正式名(顧客名)"
  ,( xvsa.address_line1 || xvsa.address_line2 ) AS address_line --"住所"
  ,xvsa.phone                        AS  phone                  --"電話番号"
FROM
   xxwsh_order_headers_all           xoha    -- 受注ヘッダアドオン
  ,xxwsh_carriers_schedule           xcs     -- 配車配送計画(アドオン)
  ,xxcmn_vendor_sites2_v             xvsa    -- 仕入先サイト情報VIEW
  ,xxcmn_item_locations2_v           xilv    -- OPM保管場所マスタ2
  ,xxwsh_oe_transaction_types2_v     xottv   -- 受注タイプ
  ,xxwsh_ship_method2_v              xsm2v   -- 配送区分情報VIEW2
-- 2008.07.07 ADD S.Takemoto start
  ,xxcmn_lookup_values_v             xlvv
-- 2008.07.07 ADD S.Takemoto end
WHERE
  ----------------------------------------------------------------------------------
  -- ヘッダ情報
       xottv.shipping_shikyu_class  =   '2'
  AND  xottv.order_category_code    =   'ORDER'    -- 受注カテゴリ：受注
  AND  xoha.req_status              >=  '07'       -- ステータス：「受領済」
  AND  xoha.req_status              <>  '99'       -- ステータス：取消
  --------------------------------------------------------------------------------------------
  --------------------------------------------------------------------------------------------
-- 2008.07.03 ADD S.Takemoto start
  --------------------------------------------------------------------------------------------
  AND  xoha.latest_external_flag    = 'Y'        -- 最新フラグ
  --OPM保管場所情報(出荷元情報)(実績)
  AND  xoha.deliver_from_id         = xilv.inventory_location_id
  AND   NVL(xoha.shipped_date,xoha.schedule_ship_date)                 --適用開始日 <= 出荷日(出荷予定日) <= 適用終了日
    BETWEEN xilv.date_from
    AND NVL(xilv.date_to,NVL(xoha.shipped_date,xoha.schedule_ship_date))
  -- 配送区分情報VIEW2
  AND   NVL(xoha.shipped_date,xoha.schedule_ship_date)                 --適用開始日 <= 出荷日(出荷予定日) <= 適用終了日
    BETWEEN xsm2v.start_date_active
    AND NVL(xsm2v.end_date_active,NVL(xoha.shipped_date,xoha.schedule_ship_date))
-- 2008.07.03 ADD S.Takemoto end
-- 2008.07.07 ADD S.Takemoto start
  AND xlvv.lookup_type    ='XXCMN_SHIP_METHOD' -- 配送区分
  AND xlvv.attribute6     = '1'  -- 小口区分：小口
  AND xlvv.lookup_code    = NVL(xoha.result_shipping_method_code,xoha.shipping_method_code) -- 配送区分
-- 2008.07.07 ADD S.Takemoto end
  AND  xoha.shipping_method_code    =    xsm2v.ship_method_code
  AND  xoha.vendor_site_id          =    xvsa.vendor_site_id ( + )
  AND  xoha.delivery_no             =    xcs.delivery_no
  AND  xoha.order_type_id           =    xottv.transaction_type_id
  --------------------------------------------------------------------------------------------
  AND ( xvsa.start_date_active IS NULL
        OR ( ( xoha.req_status = '07' 
              AND 
               xvsa.start_date_active       <=   xoha.schedule_ship_date )
           OR
             ( xoha.req_status = '08' 
              AND 
               xvsa.start_date_active       <=   xoha.shipped_date ) ) 
  )
  --------------------------------------------------------------------------------------------
  AND ( xvsa.end_date_active IS NULL
        OR ( ( xoha.req_status = '07' 
              AND 
               xvsa.end_date_active         >=   xoha.schedule_ship_date )
           OR
             ( xoha.req_status = '08' 
              AND 
               xvsa.end_date_active         >=   xoha.shipped_date ) ) 
  )
  --------------------------------------------------------------------------------------------
UNION 
SELECT
  ---------------------------------------------------------------------------------
  -- パラメータ指定項目
  -- 業務種別共通
   TO_CHAR('3')                      AS  ship_type              --"業務種別"
  ,NULL                              AS  order_type_id          --"出庫形態"
  ,xmrih.shipped_locat_code          AS  deliver_from           --"出荷元ID"
  ,CASE
    WHEN (xmrih.status = '04') THEN xmrih.actual_freight_carrier_code
    WHEN (xmrih.status = '06') THEN xmrih.actual_freight_carrier_code
    WHEN (xmrih.status = '02') THEN xmrih.freight_carrier_code
    WHEN (xmrih.status = '03') THEN xmrih.freight_carrier_code
    WHEN (xmrih.status = '05') THEN xmrih.freight_carrier_code
   END                               AS  career_id              --"運送業者"
  ,CASE
    WHEN (xmrih.status = '04') THEN xmrih.actual_ship_date
    WHEN (xmrih.status = '06') THEN xmrih.actual_ship_date
    WHEN (xmrih.status = '02') THEN xmrih.schedule_ship_date
    WHEN (xmrih.status = '03') THEN xmrih.schedule_ship_date
    WHEN (xmrih.status = '05') THEN xmrih.schedule_ship_date
   END                               AS  schedule_ship_date     --"出荷日"
  ,xmrih.item_class                  AS  prod_class             --"商品区分"
  ,xcs.delivery_no                   AS  delivery_no            --"配送No"
  ,xmrih.ship_to_locat_code          AS  deliver_to             --"配送先/入庫先"
-- 2008.07.03 mod S.Takemoto start
--  ,xilv.distribution_block           AS  block                  --"ブロック"
  ,xilv2.distribution_block          AS  block                  --"ブロック"
-- 2008.07.03 mod S.Takemoto end
  ------------------------------------------------
  ,xmrih.mov_num                     AS  request_no             --"依頼No"
  ,xmrih.small_quantity              AS  small_quantity         --"小口個数"
  ,xmrih.label_quantity              AS  label_quantity         --"ラベル枚数"
  ,xilv.description                  AS  party_site_name        --"正式名(顧客名)"
  ,xl2v.address_line1                AS  address_line           --"住所"
  ,xl2v.phone                        AS  phone                  --"電話番号"
FROM
   xxwsh_carriers_schedule          xcs      --配車配送計画( アドオン)
  ,xxcmn_item_locations2_v          xilv     --OPM保管場所マスタ2
-- 2008.07.03 ADD S.Takemoto start
  ,xxcmn_item_locations2_v          xilv2     --OPM保管場所マスタ2
-- 2008.07.03 ADD S.Takemoto end
  ,xxcmn_locations2_v               xl2v     --事業所アドオンマスタ
  ,xxinv_mov_req_instr_headers      xmrih    --移動依頼/指示ヘッダ( アドオン)
  ,xxwsh_ship_method2_v             xsm2v    --配送区分情報VIEW2
-- 2008.07.07 ADD S.Takemoto start
  ,xxcmn_lookup_values_v             xlvv
-- 2008.07.07 ADD S.Takemoto end
WHERE 
      xmrih.status                  >=   '02'
  AND xmrih.status                  <>   '99'
  AND xmrih.mov_type                <>   '2'
  AND xmrih.ship_to_locat_id        =    xilv.inventory_location_id 
  AND xilv.location_id              =    xl2v.location_id
  AND xmrih.shipping_method_code    =    xsm2v.ship_method_code
  AND xmrih.delivery_no             =    xcs.delivery_no
  --------------------------------------------------------------------------------------------
-- 2008.07.03 ADD S.Takemoto start
  --------------------------------------------------------------------------------------------
--OPM保管場所情報view(出庫元)抽出条件
  AND   xmrih.ship_to_locat_id = xilv2.inventory_location_id                    --配送元ID = 倉庫ID
  AND   NVL(xmrih.actual_ship_date,xmrih.schedule_ship_date)                 --適用開始日 <= 出荷日(出荷予定日) <= 適用終了日
    BETWEEN xilv2.date_from
    AND NVL(xilv2.date_to,NVL(xmrih.actual_ship_date,xmrih.schedule_ship_date))
  --OPM保管場所情報(出荷元情報)(実績)
  AND   NVL(xmrih.actual_ship_date,xmrih.schedule_ship_date)                 --適用開始日 <= 出荷日(出荷予定日) <= 適用終了日
    BETWEEN xilv.date_from
    AND NVL(xilv.date_to,NVL(xmrih.actual_ship_date,xmrih.schedule_ship_date))
  -- 配送区分情報VIEW2
  AND   NVL(xmrih.actual_ship_date,xmrih.schedule_ship_date)                 --適用開始日 <= 出荷日(出荷予定日) <= 適用終了日
    BETWEEN xsm2v.start_date_active
    AND NVL(xsm2v.end_date_active,NVL(xmrih.actual_ship_date,xmrih.schedule_ship_date))
-- 2008.07.03 ADD S.Takemoto end
-- 2008.07.07 ADD S.Takemoto start
  AND xlvv.lookup_type    ='XXCMN_SHIP_METHOD' -- 配送区分
  AND xlvv.attribute6     = '1'  -- 小口区分：小口
  AND xlvv.lookup_code    = NVL(xmrih.actual_shipping_method_code,xmrih.shipping_method_code) -- 配送区分
-- 2008.07.07 ADD S.Takemoto end
  AND ( xl2v.start_date_active IS NULL
        OR ( ( ( xmrih.status                =    '02' 
                 OR
                 xmrih.status                =    '03' 
                 OR
                 xmrih.status                =    '05' )
              AND 
               xl2v.start_date_active       <=   xmrih.schedule_ship_date )
           OR
             ( ( xmrih.status                =    '04' 
                 OR
                 xmrih.status                =    '06' )
              AND 
               xl2v.start_date_active       <=   xmrih.actual_ship_date ) ) 
  )
  --------------------------------------------------------------------------------------------
  AND ( xl2v.end_date_active IS NULL
        OR ( ( ( xmrih.status                =    '02' 
                 OR
                 xmrih.status                =    '03' 
                 OR
                 xmrih.status                =    '05' )
              AND 
               xl2v.end_date_active         >=   xmrih.schedule_ship_date )
           OR
             ( ( xmrih.status                =    '04' 
                 OR
                 xmrih.status                =    '06' )
              AND 
               xl2v.end_date_active         >=   xmrih.actual_ship_date ) ) 
  )
-- 2008.07.02 add S.Takemoto START
UNION 
SELECT
  ---------------------------------------------------------------------------------
  -- パラメータ指定項目
  -- 業務種別共通
   TO_CHAR('4')                      AS  ship_type              --"業務種別"
  ,NULL                              AS  order_type_id          --"出庫形態"
  ,xcs.deliver_from                  AS  deliver_from           --"出荷元ID"
  ,NVL(xcs.result_freight_carrier_code,xcs.carrier_code)
                                     AS  career_id              --"運送業者" -- 実績
  ,NVL(xcs.shipped_date,xcs.schedule_ship_date)
                                     AS  schedule_ship_date     --"出荷日"
  ,xcs.prod_class                    AS  prod_class             --"商品区分"
  ,xcs.delivery_no                   AS  delivery_no            --"配送No"
  ,xcs.deliver_to                    AS  deliver_to             --"配送先/入庫先"
  ,xilv2.distribution_block           AS  block                  --"ブロック"
  ------------------------------------------------
  ,NULL                              AS  request_no             --"依頼No"
  ,xcs.small_quantity                AS  small_quantity         --"小口個数"
  ,xcs.label_quantity                AS  label_quantity         --"ラベル枚数"
  ,CASE
    WHEN (xcs.deliver_to_code_class IN('1','10'))  THEN xcas.party_site_full_name
    WHEN (xcs.deliver_to_code_class = '11') THEN xvsa.vendor_site_name
    WHEN (xcs.deliver_to_code_class = '4')  THEN xilv_loc.description
   END                               AS  party_site_name        --"正式名(顧客名)"
  ,CASE
    WHEN (xcs.deliver_to_code_class IN('1','10'))  THEN ( xcas.address_line1 || xcas.address_line2 )
    WHEN (xcs.deliver_to_code_class = '11') THEN ( xvsa.address_line1 || xvsa.address_line2 )
    WHEN (xcs.deliver_to_code_class = '4')  THEN xilv_loc.address_line1
   END                               AS  address_line           --"住所"
  ,CASE
    WHEN (xcs.deliver_to_code_class IN('1','10')) THEN xcas.phone
    WHEN (xcs.deliver_to_code_class = '11') THEN xvsa.phone
    WHEN (xcs.deliver_to_code_class = '4') THEN xilv_loc.phone
   END                               AS  phone                  --"電話番号"
FROM
   xxwsh_carriers_schedule          xcs      --配車配送計画( アドオン)
  ,xxcmn_cust_acct_sites2_v         xcas     -- 顧客サイト  -- 出荷
  ,xxcmn_vendor_sites2_v            xvsa    -- 仕入先サイト情報VIEW
  ,xxcmn_item_locations2_v          xilv2    --OPM保管場所マスタ2
  ,(SELECT xilv.inventory_location_id
           ,xl2v.start_date_active
           ,xl2v.end_date_active
           ,xilv.date_from
           ,xilv.date_to
           ,xilv.description
           ,xl2v.address_line1
           ,xl2v.phone           
    FROM xxcmn_item_locations2_v          xilv     --OPM保管場所マスタ2 -- 移動
        ,xxcmn_locations2_v               xl2v     --事業所アドオンマスタ
    WHERE xilv.location_id         = xl2v.location_id ) xilv_loc  -- 移動
  ,xxwsh_ship_method2_v             xsm2v    --配送区分情報VIEW2
-- 2008.07.07 ADD S.Takemoto start
  ,xxcmn_lookup_values_v             xlvv
-- 2008.07.07 ADD S.Takemoto end
WHERE  xcs.non_slip_class   =    '2'   --伝票なし配車区分 2：伝票なし配車
  AND  xcs.deliver_to_code_class IN ('1','4','10','11')
  AND  xcs.delivery_type    =    xsm2v.ship_method_code
  AND   NVL(xcs.shipped_date,xcs.schedule_ship_date)                 --適用開始日 <= 出荷日(出荷予定日) <= 適用終了日
    BETWEEN xsm2v.start_date_active
    AND NVL(xsm2v.end_date_active,NVL(xcs.shipped_date,xcs.schedule_ship_date))
--OPM保管場所情報view(出庫元)抽出条件
  AND   xcs.deliver_from_id = xilv2.inventory_location_id                    --配送元ID = 倉庫ID
  AND   NVL(xcs.shipped_date,xcs.schedule_ship_date)                             --適用開始日 <= 出荷日(出荷予定日) <= 適用終了日
  BETWEEN xilv2.date_from
  AND NVL(xilv2.date_to,NVL(xcs.shipped_date,xcs.schedule_ship_date))
-- 2008.07.07 ADD S.Takemoto start
  AND xlvv.lookup_type    ='XXCMN_SHIP_METHOD' -- 配送区分
  AND xlvv.attribute6     = '1'  -- 小口区分：小口
  AND xlvv.lookup_code    = NVL(xcs.result_shipping_method_code,xcs.delivery_type) -- 配送区分
-- 2008.07.07 ADD S.Takemoto end
  AND  xcs.deliver_to_id         = xcas.party_site_id (+)             -- 出荷
  AND  NVL(xcs.shipped_date,xcs.schedule_ship_date)  >= xcas.start_date_active(+)
  AND  NVL(xcs.shipped_date,xcs.schedule_ship_date)  <= xcas.end_date_active(+)
  AND  xcs.deliver_to_id         = xvsa.vendor_site_id (+)            -- 支給
  AND  NVL(xcs.shipped_date,xcs.schedule_ship_date)  >= xvsa.start_date_active(+)
  AND  NVL(xcs.shipped_date,xcs.schedule_ship_date)  <= xvsa.end_date_active(+)
  AND  xcs.deliver_to_id         = xilv_loc.inventory_location_id (+) -- 移動
  AND  NVL(xcs.shipped_date,xcs.schedule_ship_date)  >= xilv_loc.start_date_active(+)
  AND  NVL(xcs.shipped_date,xcs.schedule_ship_date)  <= xilv_loc.end_date_active(+)
  AND  NVL(xcs.shipped_date,xcs.schedule_ship_date)                             --適用開始日 <= 出荷日(出荷予定日) <= 適用終了日
    BETWEEN xilv_loc.date_from(+)
    AND NVL(xilv_loc.date_to(+),NVL(xcs.shipped_date,xcs.schedule_ship_date))
-- 2008.07.03 ADD S.Takemoto end
/
COMMENT ON TABLE xxwsh_label_v IS 'ラベルVIEW'
/
COMMENT ON COLUMN xxwsh_label_v.ship_type is '業務種別'
/
COMMENT ON COLUMN xxwsh_label_v.order_type_id is '出庫形態'
/
COMMENT ON COLUMN xxwsh_label_v.deliver_from is '出荷元ID'
/
COMMENT ON COLUMN xxwsh_label_v.career_code is '運送業者'
/
COMMENT ON COLUMN xxwsh_label_v.schedule_ship_date is '出荷日'
/
COMMENT ON COLUMN xxwsh_label_v.prod_class is '商品区分'
/
COMMENT ON COLUMN xxwsh_label_v.delivery_no is '配送No'
/
COMMENT ON COLUMN xxwsh_label_v.deliver_to is '配送先/入庫先'
/
COMMENT ON COLUMN xxwsh_label_v.block is 'ブロック'
/
COMMENT ON COLUMN xxwsh_label_v.request_no is '依頼No'
/
COMMENT ON COLUMN xxwsh_label_v.small_quantity is '小口個数'
/
COMMENT ON COLUMN xxwsh_label_v.label_quantity is 'ラベル枚数'
/
COMMENT ON COLUMN xxwsh_label_v.party_site_name is '正式名(顧客名)'
/
COMMENT ON COLUMN xxwsh_label_v.address_line is '住所'
/
COMMENT ON COLUMN xxwsh_label_v.phone is '電話番号'
/
