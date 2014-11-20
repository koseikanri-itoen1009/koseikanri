CREATE OR REPLACE VIEW APPS.XXSKY_運賃明細_基本_V
(
 依頼NO
,送り状NO
,配送NO
,運送業者
,運送業者名
,出庫倉庫コード
,出庫倉庫名
,配送区分
,配送区分名
,配送先コード区分
,配送先コード区分名
,配送先コード
,代表配送先名
,支払判断区分
,支払判断区分名
,管轄拠点
,管轄拠点名称
,出庫日
,到着日
,報告日
,判断日
,商品区分
,商品区分名
,重量容積区分
,重量容積区分名
,距離
,実際距離
,個数
,重量
,タイプ
,タイプ名
,混載区分
,混載区分名
,契約外区分
,契約外区分名
,振替先
,振替先名
,摘要
,作成者
,作成日
,最終更新者
,最終更新日
,最終更新ログイン
)
AS
SELECT
         XDL.request_no                         -- 依頼No
        ,XDL.invoice_no                         -- 送り状No
        ,XDL.delivery_no                        -- 配送No
        ,XDL.delivery_company_code              -- 運送業者
        ,XC2V.party_name                        -- 運送業者名
        ,XDL.whs_code                           -- 出庫倉庫コード
        ,XILV.description                       -- 出庫倉庫名
        ,XDL.dellivary_classe                   -- 配送区分
        ,FLV01.meaning                          -- 配送区分名
        ,XDL.code_division                      -- 配送先コード区分
        ,FLV02.meaning                          -- 配送先コード区分名
        ,XDL.shipping_address_code              -- 配送先コード
        ,SAC.name    shipping_address_code_name -- 代表配送先名
        ,XDL.payments_judgment_classe           -- 支払判断区分
        ,FLV03.meaning                          -- 支払判断区分名
        ,CASE WHEN XDL.order_type = '1'
-- 2009/12/01 Y.Fukami Mod Start
--              THEN XHMV.配送先_拠点コード       -- 管轄拠点（出荷の場合）
              THEN XHM2V.配送先_拠点コード      -- 管轄拠点（出荷の場合）
-- 2009/12/01 Y.Fukami Mod End
              WHEN XDL.order_type = '2'
              THEN NULL                         -- 管轄拠点（支給の場合、NULL）
              WHEN XDL.order_type = '3'
              THEN '2100'                       -- 管轄拠点（移動の場合、'2100'固定）
         END base_code
        ,CASE WHEN XDL.order_type = '1'
-- 2009/12/01 Y.Fukami Mod Start
--              THEN XHMV.配送先_拠点名           -- 管轄拠点名称（出荷の場合）
              THEN XHM2V.配送先_拠点名          -- 管轄拠点名称（出荷の場合）
-- 2009/12/01 Y.Fukami Mod End
              WHEN XDL.order_type = '2'
              THEN NULL                         -- 管轄拠点名称（支給の場合、NULL）
              WHEN XDL.order_type = '3'
              THEN XL2V02.location_name         -- 管轄拠点名称（移動の場合、'飲料部'）
         END base_name
        ,XDL.ship_date                          -- 出庫日
        ,XDL.arrival_date                       -- 到着日
        ,XDL.report_date                        -- 報告日
        ,XDL.judgement_date                     -- 判断日
        ,XDL.goods_classe                       -- 商品区分
        ,FLV04.meaning                          -- 商品区分名
        ,XDL.weight_capacity_class              -- 重量容積区分
        ,FLV05.meaning                          -- 重量容積区分名
        ,XDL.distance                           -- 距離
        ,XDL.actual_distance                    -- 実際距離
        ,XDL.qty                                -- 個数
        ,XDL.delivery_weight                    -- 重量
        ,XDL.order_type                         -- タイプ
        ,FLV06.meaning                          -- タイプ名
        ,XDL.mixed_code                         -- 混載区分
        ,FLV07.meaning                          -- 混載区分名
        ,XDL.outside_contract                   -- 契約外区分
        ,FLV08.meaning                          -- 契約外区分名
        ,XDL.transfer_location                  -- 振替先
        ,XL2V.location_name                     -- 振替先名
        ,XDL.description                        -- 摘要
        ,FU_CB.user_name                        -- 作成者
        ,TO_CHAR( XDL.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                                -- 作成日(支給依頼情報IF明細)
        ,FU_LU.user_name                        -- 最終更新者
        ,TO_CHAR( XDL.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                                -- 最終更新日(支給依頼情報IF明細)
        ,FU_LL.user_name                        -- 最終更新ログイン
FROM
-- 2009/12/01 Y.Fukami Mod Start
--         xxwip_delivery_lines   XDL             -- 運賃明細アドオン
-- 運賃明細アドオンに出荷の場合の管轄拠点を取得するための配送先IDを受注ヘッダアドオンから結合
        (
                SELECT
                       XXDL.request_no
                      ,XXDL.invoice_no
                      ,XXDL.delivery_no
                      ,XXDL.delivery_company_code
                      ,XXDL.whs_code
                      ,XXDL.dellivary_classe
                      ,XXDL.code_division
                      ,XXDL.shipping_address_code
                      ,XXDL.payments_judgment_classe
                      ,XXDL.ship_date
                      ,XXDL.arrival_date
                      ,XXDL.report_date
                      ,XXDL.judgement_date
                      ,XXDL.goods_classe
                      ,XXDL.weight_capacity_class
                      ,XXDL.distance
                      ,XXDL.actual_distance
                      ,XXDL.qty
                      ,XXDL.delivery_weight
                      ,XXDL.order_type
                      ,XXDL.mixed_code
                      ,XXDL.outside_contract
                      ,XXDL.transfer_location
                      ,XXDL.description
                      ,XXDL.created_by
                      ,XXDL.creation_date
                      ,XXDL.last_update_login
                      ,XXDL.last_updated_by
                      ,XXDL.last_update_date
                      ,XOHA.result_deliver_to_id
                FROM
                       xxwip_delivery_lines     XXDL      -- 運賃明細アドオン
                      ,xxwsh_order_headers_all  XOHA      -- 受注ヘッダアドオン
                WHERE
                       XOHA.request_no(+)              =  XXDL.request_no
                  AND  XOHA.latest_external_flag(+)    =  'Y'
        )                                       XDL     -- 運賃明細アドオン＋受注ヘッダアドオンの配送先ID
-- 2009/12/01 Y.Fukami Mod End
        ,xxsky_carriers2_v      XC2V            -- SKYLINK用中間VIEW 運送業者情報VIEW2(運送業者名)
        ,xxsky_item_locations_v XILV            -- SKYLINK用中間VIEW OPM保管場所情報VIEW(出庫倉庫名)
        ,xxsky_locations2_v     XL2V            -- SKYLINK用中間VIEW 事業所情報VIEW2(振替先名)
        ,fnd_lookup_values      FLV01           -- クイックコード表(配送区分名)
        ,fnd_lookup_values      FLV02           -- クイックコード表(配送先コード区分名)
        ,fnd_lookup_values      FLV03           -- クイックコード表(支払判断区分名)
-- 2009/12/01 Y.Fukami Mod Start
--        ,XXSKY_配送先マスタ_基本_V    XHMV      -- SKYLINK用配送先マスタ_基本_V
        ,XXSKY_配送先マスタ_基本2_V   XHM2V     -- SKYLINK用配送先マスタ_基本2_V
-- 2009/12/01 Y.Fukami Mod End
        ,xxsky_locations2_v     XL2V02          -- SKYLINK用中間VIEW 事業所情報VIEW2(管轄拠点名)
        ,fnd_lookup_values      FLV04           -- クイックコード表(商品区分名)
        ,fnd_lookup_values      FLV05           -- クイックコード表(重量容積区分名)
        ,fnd_lookup_values      FLV06           -- クイックコード表(タイプ名)
        ,fnd_lookup_values      FLV07           -- クイックコード表(混載区分名)
        ,fnd_lookup_values      FLV08           -- クイックコード表(契約外区分名)
        ,( -- 代表配送先名取得用（コード区分の値によって取得先が異なる）
                -- コード区分が'1:倉庫'の場合はOPM保管倉庫名を取得
                SELECT
                        1                       class   -- 1:倉庫
                        , segment1              code    -- 保管倉庫No
                        , description           name    -- 保管倉庫名
                        , date_from             dstart  -- 適用開始日
                        , date_to               dend    -- 適用終了日
                FROM
                        xxsky_item_locations_v          -- 保管倉庫
                UNION ALL
                -- コード区分が'2:取引先'の場合は取引先サイト名を取得
                SELECT
                        2                       class   -- 2:取引先
                        , vendor_site_code      code    -- 取引先サイトNo
                        , vendor_site_name      name    -- 取引先サイト名
                        , start_date_active     dstart  -- 適用開始日
                        , end_date_active       dend    -- 適用終了日
                FROM
                        xxsky_vendor_sites2_v           -- 仕入先サイトVIEW
                UNION ALL
                -- コード区分が'3:配送先'の場合は配送先名を取得
                SELECT
                        3                       class   -- 3:配送先
                        , party_site_number     code    -- 配送先No
                        , party_site_name       name    -- 配送先名
                        , start_date_active     dstart  -- 適用開始日
                        , end_date_active       dend    -- 適用終了日
                FROM
                        xxsky_party_sites2_v            -- 配送先VIEW
        )                                       SAC     -- 配送先名取得用
        ,fnd_user                               FU_CB   -- ユーザーマスタ(CREATED_BY名称取得用)
        ,fnd_user                               FU_LU   -- ユーザーマスタ(LAST_UPDATE_BY名称取得用)
        ,fnd_user                               FU_LL   -- ユーザーマスタ(LAST_UPDATE_LOGIN名称取得用)
        ,fnd_logins                             FL_LL   -- ログインマスタ(LAST_UPDATE_LOGIN名称取得用)
WHERE
        -- 運送業者名
        XC2V.freight_code(+)            =  XDL.delivery_company_code
   AND  XC2V.start_date_active(+)       <= XDL.ship_date
   AND  XC2V.end_date_active(+)         >= XDL.ship_date
        -- 出庫倉庫名
   AND  XILV.segment1(+)                = XDL.whs_code
        -- 配送区分名
   AND  FLV01.language(+)               = 'JA'
   AND  FLV01.lookup_type(+)            = 'XXCMN_SHIP_METHOD'
   AND  FLV01.lookup_code(+)            = XDL.dellivary_classe
        -- 配送先コード区分名
   AND  FLV02.language(+)               = 'JA'
   AND  FLV02.lookup_type(+)            = 'XXWIP_CODE_TYPE'
   AND  FLV02.lookup_code(+)            = XDL.code_division
        -- 代表配送先名
   AND  XDL.code_division               = SAC.class(+)
   AND  XDL.shipping_address_code       = SAC.code(+)
   AND  SAC.dstart(+)                   <= XDL.ship_date
   AND  SAC.dend(+)                     >= XDL.ship_date
        -- 支払先判断区分名
   AND  FLV03.language(+)               = 'JA'
   AND  FLV03.lookup_type(+)            = 'XXWIP_CLAIM_PAY_STD'
   AND  FLV03.lookup_code(+)            = XDL.payments_judgment_classe
        -- 管轄拠点情報取得
-- 2009/12/01 Y.Fukami Mod Start
--   AND  XDL.shipping_address_code       = XHMV.配送先_番号(+)
   AND  XDL.result_deliver_to_id        = XHM2V.配送先_ID(+)
   AND  XHM2V.顧客拠点_適用開始日(+)   <= XDL.ship_date
   AND  XHM2V.顧客拠点_適用終了日(+)   >= XDL.ship_date
   AND  XHM2V.配送先_適用開始日(+)     <= XDL.ship_date
   AND  XHM2V.配送先_適用終了日(+)     >= XDL.ship_date
-- 2009/12/01 Y.Fukami Mod End
        -- 管轄拠点名
   AND  XL2V02.location_code(+)         = '2100'            -- 飲料部
   AND  XL2V02.start_date_active(+)    <= XDL.ship_date
   AND  XL2V02.end_date_active(+)      >= XDL.ship_date
        -- 商品区分名
   AND  FLV04.language(+)               = 'JA'
   AND  FLV04.lookup_type(+)            = 'XXWIP_ITEM_TYPE'
   AND  FLV04.lookup_code(+)            = XDL.goods_classe
        -- 重量容積区分名
   AND  FLV05.language(+)               = 'JA'
   AND  FLV05.lookup_type(+)            = 'XXCMN_WEIGHT_CAPACITY_CLASS'
   AND  FLV05.lookup_code(+)            = XDL.weight_capacity_class
        -- タイプ名
   AND  FLV06.language(+)               = 'JA'
   AND  FLV06.lookup_type(+)            = 'XXWIP_ORDER_TYPE'
   AND  FLV06.lookup_code(+)            = XDL.order_type
        -- 混載区分名
   AND  FLV07.language(+)               = 'JA'
   AND  FLV07.lookup_type(+)            = 'XXCMN_D24'
   AND  FLV07.lookup_code(+)            = XDL.mixed_code
        -- 契約外区分名
   AND  FLV08.language(+)               = 'JA'
   AND  FLV08.lookup_type(+)            = 'XXCMN_INCLUDE_EXCLUDE'
   AND  FLV08.lookup_code(+)            = XDL.outside_contract
        -- 振替先名
   AND  XL2V.location_code(+)           = XDL.transfer_location
   AND  XL2V.start_date_active(+)       <= XDL.ship_date
   AND  XL2V.end_date_active(+)         >= XDL.ship_date
        -- ユーザ名など
   AND  XDL.created_by                  = FU_CB.user_id(+)
   AND  XDL.last_updated_by             = FU_LU.user_id(+)
   AND  XDL.last_update_login           = FL_LL.login_id(+)
   AND  FL_LL.user_id                   = FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKY_運賃明細_基本_V IS 'SKYLINK用運賃明細（基本）VIEW'
/
COMMENT ON COLUMN APPS.XXSKY_運賃明細_基本_V.依頼NO IS '依頼No'
/
COMMENT ON COLUMN APPS.XXSKY_運賃明細_基本_V.送り状NO IS '送り状No'
/
COMMENT ON COLUMN APPS.XXSKY_運賃明細_基本_V.配送NO IS '配送No'
/
COMMENT ON COLUMN APPS.XXSKY_運賃明細_基本_V.運送業者 IS '運送業者'
/
COMMENT ON COLUMN APPS.XXSKY_運賃明細_基本_V.運送業者名 IS '運送業者名'
/
COMMENT ON COLUMN APPS.XXSKY_運賃明細_基本_V.出庫倉庫コード IS '出庫倉庫コード'
/
COMMENT ON COLUMN APPS.XXSKY_運賃明細_基本_V.出庫倉庫名 IS '出庫倉庫名'
/
COMMENT ON COLUMN APPS.XXSKY_運賃明細_基本_V.配送区分 IS '配送区分'
/
COMMENT ON COLUMN APPS.XXSKY_運賃明細_基本_V.配送区分名 IS '配送区分名'
/
COMMENT ON COLUMN APPS.XXSKY_運賃明細_基本_V.配送先コード区分 IS '配送先コード区分'
/
COMMENT ON COLUMN APPS.XXSKY_運賃明細_基本_V.配送先コード区分名 IS '配送先コード区分名'
/
COMMENT ON COLUMN APPS.XXSKY_運賃明細_基本_V.配送先コード IS '配送先コード'
/
COMMENT ON COLUMN APPS.XXSKY_運賃明細_基本_V.代表配送先名 IS '代表配送先名'
/
COMMENT ON COLUMN APPS.XXSKY_運賃明細_基本_V.支払判断区分 IS '支払判断区分'
/
COMMENT ON COLUMN APPS.XXSKY_運賃明細_基本_V.支払判断区分名 IS '支払判断区分名'
/
COMMENT ON COLUMN APPS.XXSKY_運賃明細_基本_V.管轄拠点 IS '管轄拠点'
/
COMMENT ON COLUMN APPS.XXSKY_運賃明細_基本_V.管轄拠点名称 IS '管轄拠点名称'
/
COMMENT ON COLUMN APPS.XXSKY_運賃明細_基本_V.出庫日 IS '出庫日'
/
COMMENT ON COLUMN APPS.XXSKY_運賃明細_基本_V.到着日 IS '到着日'
/
COMMENT ON COLUMN APPS.XXSKY_運賃明細_基本_V.報告日 IS '報告日'
/
COMMENT ON COLUMN APPS.XXSKY_運賃明細_基本_V.判断日 IS '判断日'
/
COMMENT ON COLUMN APPS.XXSKY_運賃明細_基本_V.商品区分 IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKY_運賃明細_基本_V.商品区分名 IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKY_運賃明細_基本_V.重量容積区分 IS '重量容積区分'
/
COMMENT ON COLUMN APPS.XXSKY_運賃明細_基本_V.重量容積区分名 IS '重量容積区分名'
/
COMMENT ON COLUMN APPS.XXSKY_運賃明細_基本_V.距離 IS '距離'
/
COMMENT ON COLUMN APPS.XXSKY_運賃明細_基本_V.実際距離 IS '実際距離'
/
COMMENT ON COLUMN APPS.XXSKY_運賃明細_基本_V.個数 IS '個数'
/
COMMENT ON COLUMN APPS.XXSKY_運賃明細_基本_V.重量 IS '重量'
/
COMMENT ON COLUMN APPS.XXSKY_運賃明細_基本_V.タイプ IS 'タイプ'
/
COMMENT ON COLUMN APPS.XXSKY_運賃明細_基本_V.タイプ名 IS 'タイプ名'
/
COMMENT ON COLUMN APPS.XXSKY_運賃明細_基本_V.混載区分 IS '混載区分'
/
COMMENT ON COLUMN APPS.XXSKY_運賃明細_基本_V.混載区分名 IS '混載区分名'
/
COMMENT ON COLUMN APPS.XXSKY_運賃明細_基本_V.契約外区分 IS '契約外区分'
/
COMMENT ON COLUMN APPS.XXSKY_運賃明細_基本_V.契約外区分名 IS '契約外区分名'
/
COMMENT ON COLUMN APPS.XXSKY_運賃明細_基本_V.振替先 IS '振替先'
/
COMMENT ON COLUMN APPS.XXSKY_運賃明細_基本_V.振替先名 IS '振替先名'
/
COMMENT ON COLUMN APPS.XXSKY_運賃明細_基本_V.摘要 IS '摘要'
/
COMMENT ON COLUMN APPS.XXSKY_運賃明細_基本_V.作成者 IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKY_運賃明細_基本_V.作成日 IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKY_運賃明細_基本_V.最終更新者 IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKY_運賃明細_基本_V.最終更新日 IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKY_運賃明細_基本_V.最終更新ログイン IS '最終更新ログイン'
/
