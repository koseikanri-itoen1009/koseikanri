/*************************************************************************
 * 
 * View  Name      : XXSKZ_運賃ヘッダKI_基本_V
 * Description     : XXSKZ_運賃ヘッダKI_基本_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2012/11/26    1.0   SCSK 月野    初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_運賃ヘッダKI_基本_V
(
運送業者
,運送業者名
,配送NO
,送り状NO
,送り状NO２
,支払請求区分
,支払請求区分名
,支払判断区分
,支払判断区分名
,出庫日
,到着日
,報告日
,判断日
,商品区分
,商品区分名
,混載区分
,混載区分名
,請求運賃
,契約運賃
,差額
,合計
,諸料金
,最長距離
,配送区分
,配送区分名
,代表出庫倉庫コード
,代表出庫倉庫名
,代表配送先コード区分
,代表配送先コード区分名
,代表配送先コード
,代表配送先名
,個数１
,個数２
,重量１
,重量２
,混載割増金額
,最長実際距離
,通行料
,ピッキング料
,混載数
,代表タイプ
,代表タイプ名
,重量容積区分
,重量容積区分名
,契約外区分
,契約外区分名
,差異区分
,差異区分名
,支払確定区分
,支払確定区分名
,支払確定戻
,支払確定戻名
,振替先
,振替先名
,外部業者変更回数
,運賃摘要
,配車タイプ
,配車タイプ名
,作成者
,作成日
,最終更新者
,最終更新日
,最終更新ログイン
)
AS
SELECT
         XD.delivery_company_code               -- 運送業者
        ,XC2V.party_name                        -- 運送業者名
        ,XD.delivery_no                         -- 配送No
        ,XD.invoice_no                          -- 送り状No
        ,XD.invoice_no2                         -- 送り状No2
        ,XD.p_b_classe                          -- 支払請求区分
        ,FLV01.meaning                          -- 支払請求区分名
        ,XD.payments_judgment_classe            -- 支払判断区分
        ,FLV02.meaning                          -- 支払判断区分名
        ,XD.ship_date                           -- 出庫日
        ,XD.arrival_date                        -- 到着日
        ,XD.report_date                         -- 報告日
        ,XD.judgement_date                      -- 判断日
        ,XD.goods_classe                        -- 商品区分
        ,FLV03.meaning                          -- 商品区分名
        ,XD.mixed_code                          -- 混載区分
        ,FLV04.meaning                          -- 混載区分名
        ,XD.charged_amount                      -- 請求運賃
        ,XD.contract_rate                       -- 契約運賃
        ,XD.balance                             -- 差額
        ,XD.total_amount                        -- 合計
        ,XD.many_rate                           -- 諸料金
        ,XD.distance                            -- 最長距離
        ,XD.delivery_classe                     -- 配送区分
        ,FLV05.meaning                          -- 配送区分名
        ,XD.whs_code                            -- 代表出庫倉庫コード
        ,XILV.description                       -- 代表出庫倉庫名
        ,XD.code_division                       -- 代表配送先コード区分
        ,FLV06.meaning                          -- 代表配送先コード区分名
        ,XD.shipping_address_code               -- 代表配送先コード
        ,SAC.name       shipping_address_code_name -- 代表配送先名
        ,XD.qty1                                -- 個数1
        ,XD.qty2                                -- 個数2
        ,XD.delivery_weight1                    -- 重量1
        ,XD.delivery_weight2                    -- 重量2
        ,XD.consolid_surcharge                  -- 混載割増金額
        ,XD.actual_distance                     -- 最長実際距離
        ,XD.congestion_charge                   -- 通行料
        ,XD.picking_charge                      -- ピッキング料
        ,XD.consolid_qty                        -- 混載数
        ,XD.order_type                          -- 代表タイプ
        ,FLV07.meaning                          -- 代表タイプ名
        ,XD.weight_capacity_class               -- 重量容積区分
        ,FLV08.meaning                          -- 重量容積区分名
        ,XD.outside_contract                    -- 契約外区分
        ,FLV09.meaning                          -- 契約外区分名
        ,XD.output_flag                         -- 差異区分
        ,CASE XD.output_flag                    -- 差異区分名
                WHEN 'Y' THEN '差異あり'
                WHEN 'N' THEN '差異なし'
        END output_flag_name
        ,XD.defined_flag                        -- 支払確定区分
        ,CASE XD.defined_flag                   -- 支払確定区分名
                WHEN 'Y' THEN '支払確定'
                WHEN 'N' THEN '支払未確定'
        END defined_flag_name
        ,XD.return_flag                         -- 支払確定戻
        ,CASE XD.defined_flag                   -- 支払確定戻名
                WHEN 'Y' THEN '支払確定後戻し'
                WHEN 'N' THEN '支払確定後戻しなし'
        END return_flag_name
        ,XD.transfer_location                   -- 振替先
        ,XL2V.location_name                     -- 振替先名
        ,XD.outside_up_count                    -- 外部業者変更回数
        ,XD.description                         -- 運賃摘要
        ,XD.dispatch_type                       -- 配車タイプ
        ,CASE XD.dispatch_type                  -- 配車タイプ名
                WHEN '1' THEN '通常配車'
                WHEN '2' THEN '伝票なし配車(リーフ小口)'
                WHEN '3' THEN '伝票なし配車(リーフ小口以外)'
        END dispatch_type_name
        ,FU_CB.user_name                        -- 作成者
        ,TO_CHAR( XD.creation_date, 'YYYY/MM/DD HH24:MI:SS' )
                                                -- 作成日(支給依頼情報IF明細)
        ,FU_LU.user_name                        -- 最終更新者
        ,TO_CHAR( XD.last_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                                -- 最終更新日(支給依頼情報IF明細)
        ,FU_LL.user_name                        -- 最終更新ログイン
FROM
         xxwip_deliverys        XD              -- 運賃ヘッダーアドオン
        ,xxskz_carriers2_v      XC2V            -- SKYLINK用中間VIEW 運送業者情報VIEW2(運送業者名)
        ,xxskz_item_locations_v XILV            -- SKYLINK用中間VIEW OPM保管場所情報VIEW(代表出庫倉庫名)
        ,xxskz_locations2_v     XL2V            -- SKYLINK用中間VIEW 事業所情報VIEW2(振替先名)
        ,fnd_lookup_values      FLV01           -- クイックコード表(支払請求区分名)
        ,fnd_lookup_values      FLV02           -- クイックコード表(支払判断区分名)
        ,fnd_lookup_values      FLV03           -- クイックコード表(商品区分名)
        ,fnd_lookup_values      FLV04           -- クイックコード表(混載区分名)
        ,fnd_lookup_values      FLV05           -- クイックコード表(配送区分名)
        ,fnd_lookup_values      FLV06           -- クイックコード表(代表配送先コード区分名)
        ,fnd_lookup_values      FLV07           -- クイックコード表(代表タイプ名)
        ,fnd_lookup_values      FLV08           -- クイックコード表(重量容積区分名)
        ,fnd_lookup_values      FLV09           -- クイックコード表(契約外区分名)
        ,( -- 配送先名取得用（コード区分の値によって取得先が異なる）
                -- コード区分が'1:倉庫'の場合はOPM保管倉庫名を取得
                SELECT
                        1                       class   -- 1:倉庫
                        , segment1              code    -- 保管倉庫No
                        , description           name    -- 保管倉庫名
                        , date_from             dstart  -- 適用開始日
                        , date_to               dend    -- 適用終了日
                FROM
                        xxskz_item_locations_v          -- 保管倉庫
                UNION ALL
                -- コード区分が'2:取引先'の場合は取引先サイト名を取得
                SELECT
                        2                       class   -- 2:取引先
                        , vendor_site_code      code    -- 取引先サイトNo
                        , vendor_site_name      name    -- 取引先サイト名
                        , start_date_active     dstart  -- 適用開始日
                        , end_date_active       dend    -- 適用終了日
                FROM
                        xxskz_vendor_sites2_v           -- 仕入先サイトVIEW
                UNION ALL
                -- コード区分が'3:配送先'の場合は配送先名を取得
                SELECT
                        3                       class   -- 3:配送先
                        , party_site_number     code    -- 配送先No
                        , party_site_name       name    -- 配送先名
                        , start_date_active     dstart  -- 適用開始日
                        , end_date_active       dend    -- 適用終了日
                FROM
                        xxskz_party_sites2_v            -- 配送先VIEW
        )                       SAC                     -- 配送先名取得用
        ,fnd_user               FU_CB                   -- ユーザーマスタ(CREATED_BY名称取得用)
        ,fnd_user               FU_LU                   -- ユーザーマスタ(LAST_UPDATE_BY名称取得用)
        ,fnd_user               FU_LL                   -- ユーザーマスタ(LAST_UPDATE_LOGIN名称取得用)
        ,fnd_logins             FL_LL                   -- ログインマスタ(LAST_UPDATE_LOGIN名称取得用)
WHERE
        -- 運送業者名
        XC2V.freight_code(+)            = XD.delivery_company_code
   AND  XC2V.start_date_active(+)       <= XD.ship_date
   AND  XC2V.end_date_active(+)         >= XD.ship_date
        -- 支払請求区分名
   AND  FLV01.language(+)               = 'JA'
   AND  FLV01.lookup_type(+)            = 'XXWIP_PAYCHARGE_TYPE'
   AND  FLV01.lookup_code(+)            = XD.p_b_classe
        -- 支払先判断区分名
   AND  FLV02.language(+)               = 'JA'
   AND  FLV02.lookup_type(+)            = 'XXWIP_CLAIM_PAY_STD'
   AND  FLV02.lookup_code(+)            = XD.payments_judgment_classe
        -- 商品区分名
   AND  FLV03.language(+)               = 'JA'
   AND  FLV03.lookup_type(+)            = 'XXWIP_ITEM_TYPE'
   AND  FLV03.lookup_code(+)            = XD.goods_classe
        -- 混載区分名
   AND  FLV04.language(+)               = 'JA'
   AND  FLV04.lookup_type(+)            = 'XXCMN_D24'
   AND  FLV04.lookup_code(+)            = XD.mixed_code
        -- 配送区分名
   AND  FLV05.language(+)               = 'JA'
   AND  FLV05.lookup_type(+)            = 'XXCMN_SHIP_METHOD'
   AND  FLV05.lookup_code(+)            = XD.delivery_classe
        -- 代表出庫倉庫名
   AND  XILV.segment1(+)                = XD.whs_code
        -- 代表配送先コード区分名
   AND  FLV06.language(+)               = 'JA'
   AND  FLV06.lookup_type(+)            = 'XXWIP_CODE_TYPE'
   AND  FLV06.lookup_code(+)            = XD.code_division
        -- 代表配送先名
   AND  XD.code_division                = SAC.class(+)
   AND  XD.shipping_address_code        = SAC.code(+)
   AND  SAC.dstart(+)                   <= XD.ship_date
   AND  SAC.dend(+)                     >= XD.ship_date
        -- 代表タイプ名
   AND  FLV07.language(+)               = 'JA'
   AND  FLV07.lookup_type(+)            = 'XXWIP_ORDER_TYPE'
   AND  FLV07.lookup_code(+)            = XD.order_type
        -- 重量容積区分名
   AND  FLV08.language(+)               = 'JA'
   AND  FLV08.lookup_type(+)            = 'XXCMN_WEIGHT_CAPACITY_CLASS'
   AND  FLV08.lookup_code(+)            = XD.weight_capacity_class
        -- 契約外区分名
   AND  FLV09.language(+)               = 'JA'
   AND  FLV09.lookup_type(+)            = 'XXCMN_INCLUDE_EXCLUDE'
   AND  FLV09.lookup_code(+)            = XD.outside_contract
        -- 振替先名
   AND  XL2V.location_code(+)           = XD.transfer_location
   AND  XL2V.start_date_active(+)       <= XD.ship_date
   AND  XL2V.end_date_active(+)         >= XD.ship_date
        -- ユーザ名など
   AND  XD.created_by                   = FU_CB.user_id(+)
   AND  XD.last_updated_by              = FU_LU.user_id(+)
   AND  XD.last_update_login            = FL_LL.login_id(+)
   AND  FL_LL.user_id                   = FU_LL.user_id(+)
        -- 請求データ
   AND  XD.p_b_classe                   = '2'
/
COMMENT ON TABLE APPS.XXSKZ_運賃ヘッダKI_基本_V IS 'SKYLINK用運賃ヘッダ（基本）VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃ヘッダKI_基本_V.運送業者             IS '運送業者'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃ヘッダKI_基本_V.運送業者名           IS '運送業者名'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃ヘッダKI_基本_V.配送NO               IS '配送No'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃ヘッダKI_基本_V.送り状NO             IS '送り状No'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃ヘッダKI_基本_V.送り状NO２           IS '送り状No2'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃ヘッダKI_基本_V.支払請求区分         IS '支払請求区分'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃ヘッダKI_基本_V.支払請求区分名       IS '支払請求区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃ヘッダKI_基本_V.支払判断区分         IS '支払判断区分'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃ヘッダKI_基本_V.支払判断区分名       IS '支払判断区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃ヘッダKI_基本_V.出庫日               IS '出庫日'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃ヘッダKI_基本_V.到着日               IS '到着日'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃ヘッダKI_基本_V.報告日               IS '報告日'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃ヘッダKI_基本_V.判断日               IS '判断日'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃ヘッダKI_基本_V.商品区分             IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃ヘッダKI_基本_V.商品区分名           IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃ヘッダKI_基本_V.混載区分             IS '混載区分'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃ヘッダKI_基本_V.混載区分名           IS '混載区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃ヘッダKI_基本_V.請求運賃             IS '請求運賃'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃ヘッダKI_基本_V.契約運賃             IS '契約運賃'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃ヘッダKI_基本_V.差額                 IS '差額'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃ヘッダKI_基本_V.合計                 IS '合計'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃ヘッダKI_基本_V.諸料金               IS '諸料金'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃ヘッダKI_基本_V.最長距離             IS '最長距離'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃ヘッダKI_基本_V.配送区分             IS '配送区分'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃ヘッダKI_基本_V.配送区分名           IS '配送区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃ヘッダKI_基本_V.代表出庫倉庫コード   IS '代表出庫倉庫コード'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃ヘッダKI_基本_V.代表出庫倉庫名       IS '代表出庫倉庫名'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃ヘッダKI_基本_V.代表配送先コード区分     IS '代表配送先コード区'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃ヘッダKI_基本_V.代表配送先コード区分名   IS '代表配送先コード区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃ヘッダKI_基本_V.代表配送先コード     IS '代表配送先コード'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃ヘッダKI_基本_V.代表配送先名         IS '代表配送先名'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃ヘッダKI_基本_V.個数１               IS '個数１'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃ヘッダKI_基本_V.個数２               IS '個数２'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃ヘッダKI_基本_V.重量１               IS '重量１'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃ヘッダKI_基本_V.重量２               IS '重量２'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃ヘッダKI_基本_V.混載割増金額         IS '混載割増金額'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃ヘッダKI_基本_V.最長実際距離         IS '最長実際距離'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃ヘッダKI_基本_V.通行料               IS '通行料'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃ヘッダKI_基本_V.ピッキング料         IS 'ピッキング料'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃ヘッダKI_基本_V.混載数               IS '混載数'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃ヘッダKI_基本_V.代表タイプ           IS '代表タイプ'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃ヘッダKI_基本_V.代表タイプ名         IS '代表タイプ名'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃ヘッダKI_基本_V.重量容積区分         IS '重量容積区分'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃ヘッダKI_基本_V.重量容積区分名       IS '重量容積区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃ヘッダKI_基本_V.契約外区分           IS '契約外区分'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃ヘッダKI_基本_V.契約外区分名         IS '契約外区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃ヘッダKI_基本_V.差異区分             IS '差異区分'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃ヘッダKI_基本_V.差異区分名           IS '差異区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃ヘッダKI_基本_V.支払確定区分         IS '支払確定区分'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃ヘッダKI_基本_V.支払確定区分名       IS '支払確定区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃ヘッダKI_基本_V.支払確定戻           IS '支払確定戻'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃ヘッダKI_基本_V.支払確定戻名         IS '支払確定戻名'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃ヘッダKI_基本_V.振替先               IS '振替先'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃ヘッダKI_基本_V.振替先名             IS '振替先名'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃ヘッダKI_基本_V.外部業者変更回数     IS '外部業者変更回数'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃ヘッダKI_基本_V.運賃摘要             IS '運賃摘要'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃ヘッダKI_基本_V.配車タイプ           IS '配車タイプ'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃ヘッダKI_基本_V.配車タイプ名         IS '配車タイプ名'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃ヘッダKI_基本_V.作成者               IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃ヘッダKI_基本_V.作成日               IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃ヘッダKI_基本_V.最終更新者           IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃ヘッダKI_基本_V.最終更新日           IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃ヘッダKI_基本_V.最終更新ログイン     IS '最終更新ログイン'
/
