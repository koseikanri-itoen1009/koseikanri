/*************************************************************************
 * 
 * View  Name      : XXSKZ_支給依頼情報IF_基本_V
 * Description     : XXSKZ_支給依頼情報IF_基本_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/27    1.0   SCSK M.Nagai 初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_支給依頼情報IF_基本_V
(
会社名
,データ種別
,伝送用枝番
,発生区分
,発生区分名
,重量容積区分
,重量容積区分名
,依頼部署コード
,依頼部署名
,指示部署コード
,指示部署名
,取引先コード
,取引先名
,配送先コード
,配送先名
,出庫倉庫コード
,出庫倉庫名
,運送業者コード
,運送業者名
,出庫日
,入庫日
,運賃区分
,運賃区分名
,引取区分
,引取区分名
,着荷時間FROM
,着荷時間FROM名
,着荷時間TO
,着荷時間TO名
,製造日
,製造品目コード
,製造品目名
,製造品目略称
,製造番号
,ヘッダ摘要
,明細番号
,商品区分
,商品区分名
,品目区分
,品目区分名
,群コード
,品目コード
,品目名
,品目略称
,付帯
,依頼数量
,明細摘要
,作成者
,作成日
,最終更新者
,最終更新日
,最終更新ログイン
)
AS
SELECT
         SUPREQ.corporation_name                        -- 会社名
        ,SUPREQ.data_class                              -- データ種別
        ,SUPREQ.transfer_branch_no                      -- 伝送用枝番
        ,SUPREQ.trans_type                              -- 発生区分
        ,SUPREQ.trans_type_name                         -- 発生区分名
        ,SUPREQ.weight_capacity_class                   -- 重量容積区分
        ,FLV01.meaning                                  -- 重量容積区分名
        ,SUPREQ.requested_department_code               -- 依頼部署コード
        ,XL2V01.location_name                           -- 依頼部署名
        ,SUPREQ.instruction_post_code                   -- 指示部署コード
        ,XL2V02.location_name                           -- 指示部署名
        ,SUPREQ.vendor_code                             -- 取引先コード
        ,XV2V.vendor_name                               -- 取引先名
        ,SUPREQ.ship_to_code                            -- 配送先コード
        ,XPS2V.party_site_name                          -- 配送先名
        ,SUPREQ.shipped_locat_code                      -- 出庫倉庫コード
        ,XILV.description                               -- 出庫倉庫名
        ,SUPREQ.freight_carrier_code                    -- 運送業者コード
        ,XC2V.party_name                                -- 運送業者名
        ,SUPREQ.ship_date                               -- 出庫日
        ,SUPREQ.arvl_date                               -- 入庫日
        ,SUPREQ.freight_charge_class                    -- 運賃区分
        ,FLV02.meaning                                  -- 運賃区分名
        ,SUPREQ.takeback_class                          -- 引取区分
        ,FLV03.meaning                                  -- 引取区分名
        ,SUPREQ.arrival_time_from                       -- 着荷時間FROM
        ,FLV04.meaning                                  -- 着荷時間FROM名
        ,SUPREQ.arrival_time_to                         -- 着荷時間TO
        ,FLV05.meaning                                  -- 着荷時間TO名
        ,SUPREQ.product_date                            -- 製造日
        ,SUPREQ.producted_item_code                     -- 製造品目コード
        ,XIM2V01.item_name                              -- 製造品目名
        ,XIM2V01.item_short_name                        -- 製造品目略称
        ,SUPREQ.product_number                          -- 製造番号
        ,SUPREQ.header_description                      -- ヘッダ摘要
        ,SUPREQ.line_number                             -- 明細番号(支給依頼情報IF明細)
        ,XPCV.prod_class_code                           -- 商品区分
        ,XPCV.prod_class_name                           -- 商品区分名
        ,XICV.item_class_code                           -- 品目区分
        ,XICV.item_class_name                           -- 品目区分名
        ,XCCV.crowd_code                                -- 群コード
        ,SUPREQ.item_code                               -- 品目コード(支給依頼情報IF明細)
        ,XIM2V02.item_name                              -- 品目名
        ,XIM2V02.item_short_name                        -- 品目略称
        ,SUPREQ.futai_code                              -- 付帯(支給依頼情報IF明細)
        ,SUPREQ.request_qty                             -- 依頼数量(支給依頼情報IF明細)
        ,SUPREQ.line_description                        -- 明細摘要(支給依頼情報IF明細)
        ,FU_CB.user_name                                -- 作成者
        ,TO_CHAR( SUPREQ.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                                        -- 作成日(支給依頼情報IF明細)
        ,FU_LU.user_name                                -- 最終更新者
        ,TO_CHAR( SUPREQ.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                                        -- 最終更新日(支給依頼情報IF明細)
        ,FU_LL.user_name                                -- 最終更新ログイン
  FROM
        -- 名称取得系以外のデータはこの内部SQLで全て取得する
        ( SELECT
                 XSRHI.corporation_name                 -- 会社名
                , XSRHI.data_class                      -- データ種別
                , XSRHI.transfer_branch_no              -- 伝送用枝番
                , XSRHI.trans_type                      -- 発生区分
                , CASE XSRHI.trans_type                 -- 発生区分名
                        WHEN 1 THEN '支給依頼'
                        WHEN 2 THEN '仕入有償'
                  END trans_type_name
                , XSRHI.weight_capacity_class           -- 重量容積区分
                , XSRHI.requested_department_code       -- 依頼部署コード
                , XSRHI.instruction_post_code           -- 指示部署コード
                , XSRHI.vendor_code                     -- 取引先コード
                , XSRHI.ship_to_code                    -- 配送先コード
                , XSRHI.shipped_locat_code              -- 出庫倉庫コード
                , XSRHI.freight_carrier_code            -- 運送業者コード
                , XSRHI.ship_date                       -- 出庫日
                , XSRHI.arvl_date                       -- 入庫日
                , XSRHI.freight_charge_class            -- 運賃区分
                , XSRHI.takeback_class                  -- 引取区分
                , XSRHI.arrival_time_from               -- 着荷時間FROM
                , XSRHI.arrival_time_to                 -- 着荷時間TO
                , XSRHI.product_date                    -- 製造日
                , XSRHI.producted_item_code             -- 製造品目コード
                , XSRHI.product_number                  -- 製造番号
                , XSRHI.header_description              -- ヘッダ摘要
                , XSRLI.line_number                     -- 明細番号(支給依頼情報IF明細)
                , XSRLI.item_code                       -- 品目コード(支給依頼情報IF明細)
                , XSRLI.futai_code                      -- 付帯(支給依頼情報IF明細)
                , XSRLI.request_qty                     -- 依頼数量(支給依頼情報IF明細)
                , XSRLI.line_description                -- 明細摘要(支給依頼情報IF明細)
                , XSRLI.created_by                      -- 作成者(支給依頼情報IF明細)
                , XSRLI.creation_date                   -- 作成日(支給依頼情報IF明細)
                , XSRLI.last_updated_by                 -- 最終更新者(支給依頼情報IF明細)
                , XSRLI.last_update_date                -- 最終更新日(支給依頼情報IF明細)
                , XSRLI.last_update_login               -- 最終更新ログイン(支給依頼情報IF明細)
        FROM
                 xxpo_supply_req_headers_if XSRHI       -- 支給依頼情報インタフェーステーブルヘッダ
                ,xxpo_supply_req_lines_if   XSRLI       -- 支給依頼情報インタフェーステーブル明細
        WHERE
                XSRHI.supply_req_headers_if_id  = XSRLI.supply_req_headers_if_id
        )                                   SUPREQ      -- 支給依頼情報ヘッダ＆明細
        -- 以下は上記SQL内部の項目を使用して外部結合を行うもの(エラー回避策)
        ,xxskz_locations2_v                 XL2V01      -- SKYLINK用中間VIEW 事業所情報VIEW2(依頼部署名)
        ,xxskz_locations2_v                 XL2V02      -- SKYLINK用中間VIEW 事業所情報VIEW2(指示部署名)
        ,xxskz_vendors2_v                   XV2V        -- SKYLINK用中間VIEW 仕入先情報VIEW2(取引先名)
        ,xxskz_party_sites2_v               XPS2V       -- SKYLINK用中間VIEW 配送先情報VIEW2(配送先名)
        ,xxskz_item_locations_v             XILV        -- SKYLINK用中間VIEW OPM保管場所情報VIEW(出庫倉庫名)
        ,xxskz_carriers2_v                  XC2V        -- SKYLINK用中間VIEW 運送業者情報VIEW2(運送業者名)
        ,xxskz_item_mst2_v                  XIM2V01     -- SKYLINK用中間VIEW OPM品目情報VIEW2(製造品目名)
        ,xxskz_item_mst2_v                  XIM2V02     -- SKYLINK用中間VIEW OPM品目情報VIEW2(品目名)
        ,xxskz_prod_class_v                 XPCV        -- SKYLINK用中間VIEW OPM品目区分VIEW(商品区分)
        ,xxskz_item_class_v                 XICV        -- SKYLINK用中間VIEW OPM品目区分VIEW(品目区分)
        ,xxskz_crowd_code_v                 XCCV        -- SKYLINK用中間VIEW OPM品目区分VIEW(群コード)
        ,fnd_user                           FU_CB       -- ユーザーマスタ(CREATED_BY名称取得用)
        ,fnd_user                           FU_LU       -- ユーザーマスタ(LAST_UPDATE_BY名称取得用)
        ,fnd_user                           FU_LL       -- ユーザーマスタ(LAST_UPDATE_LOGIN名称取得用)
        ,fnd_logins                         FL_LL       -- ログインマスタ(LAST_UPDATE_LOGIN名称取得用)
        ,fnd_lookup_values                  FLV01       -- クイックコード表(重量容積区分名)
        ,fnd_lookup_values                  FLV02       -- クイックコード表(運賃区分名)
        ,fnd_lookup_values                  FLV03       -- クイックコード表(引取区分名)
        ,fnd_lookup_values                  FLV04       -- クイックコード表(着荷時間FROM名)
        ,fnd_lookup_values                  FLV05       -- クイックコード表(着荷時間TO名)
 WHERE
   -- 重量容積区分名取得
        FLV01.language(+)               = 'JA'
   AND  FLV01.lookup_type(+)            = 'XXCMN_WEIGHT_CAPACITY_CLASS'
   AND  FLV01.lookup_code(+)            = SUPREQ.weight_capacity_class
   -- 依頼部署名取得
   AND  XL2V01.location_code(+)         = SUPREQ.requested_department_code
   AND  XL2V01.start_date_active(+)     <= SUPREQ.arvl_date
   AND  XL2V01.end_date_active(+)       >= SUPREQ.arvl_date
   -- 指示部署名取得
   AND  XL2V02.location_code(+)         = SUPREQ.instruction_post_code
   AND  XL2V02.start_date_active(+)     <= SUPREQ.arvl_date
   AND  XL2V02.end_date_active(+)       >= SUPREQ.arvl_date
   -- 取引先名取得
   AND  SUPREQ.vendor_code              = XV2V.segment1(+)
   AND  XV2V.start_date_active(+)       <= SUPREQ.arvl_date
   AND  XV2V.end_date_active(+)         >= SUPREQ.arvl_date
   -- 配送先名取得
   AND  SUPREQ.ship_to_code             = XPS2V.party_site_number(+)
   AND  XPS2V.start_date_active(+)      <= SUPREQ.arvl_date
   AND  XPS2V.end_date_active(+)        >= SUPREQ.arvl_date
   -- 出庫倉庫名取得
   AND  SUPREQ.shipped_locat_code       = XILV.segment1(+)
   -- 運送業者名取得
   AND  SUPREQ.freight_carrier_code     = XC2V.freight_code(+)
   AND  XC2V.start_date_active(+)       <= SUPREQ.arvl_date
   AND  XC2V.end_date_active(+)         >= SUPREQ.arvl_date
   -- 運賃区分名取得
   AND  FLV02.language(+)               = 'JA'
   AND  FLV02.lookup_type(+)            = 'XXCMN_INCLUDE_EXCLUDE'
   AND  FLV02.lookup_code(+)            = SUPREQ.freight_charge_class
   -- 引取区分名取得
   AND  FLV03.language(+)               = 'JA'
   AND  FLV03.lookup_type(+)            = 'XXWSH_TAKEBACK_CLASS'
   AND  FLV03.lookup_code(+)            = SUPREQ.takeback_class
   -- 着荷時間名取得(FROM)
   AND  FLV04.language(+)               = 'JA'
   AND  FLV04.lookup_type(+)            = 'XXWSH_ARRIVAL_TIME'
   AND  FLV04.lookup_code(+)            = SUPREQ.arrival_time_from
   -- 着荷時間名取得(TO)
   AND  FLV05.language(+)               = 'JA'
   AND  FLV05.lookup_type(+)            = 'XXWSH_ARRIVAL_TIME'
   AND  FLV05.lookup_code(+)            = SUPREQ.arrival_time_to
   -- 製造品目名、製造品目略称取得
   AND  XIM2V01.item_no(+)              = SUPREQ.producted_item_code
   AND  XIM2V01.start_date_active(+)    <= SUPREQ.arvl_date
   AND  XIM2V01.end_date_active(+)      >= SUPREQ.arvl_date
   -- 商品区分、商品区分名取得
   AND  XIM2V02.item_id                 = XPCV.item_id(+)
   -- 品目区分、品目区分名取得
   AND  XIM2V02.item_id                 = XICV.item_id(+)
   -- 群コード取得
   AND  XIM2V02.item_id                 = XCCV.item_id(+)
   -- 品目名、品目略称取得
   AND  XIM2V02.item_no(+)              = SUPREQ.item_code
   AND  XIM2V02.start_date_active(+)    <= SUPREQ.arvl_date
   AND  XIM2V02.end_date_active(+)      >= SUPREQ.arvl_date
   -- ユーザ名など
   AND  SUPREQ.created_by               = FU_CB.user_id(+)
   AND  SUPREQ.last_updated_by          = FU_LU.user_id(+)
   AND  SUPREQ.last_update_login        = FL_LL.login_id(+)
   AND  FL_LL.user_id                   = FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKZ_支給依頼情報IF_基本_V IS 'SKYLINK用支給依頼情報インターフェース（基本）VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_支給依頼情報IF_基本_V.会社名           IS '会社名'
/
COMMENT ON COLUMN APPS.XXSKZ_支給依頼情報IF_基本_V.データ種別       IS 'データ種別'
/
COMMENT ON COLUMN APPS.XXSKZ_支給依頼情報IF_基本_V.伝送用枝番       IS '伝送用枝番'
/
COMMENT ON COLUMN APPS.XXSKZ_支給依頼情報IF_基本_V.発生区分         IS '発生区分'
/
COMMENT ON COLUMN APPS.XXSKZ_支給依頼情報IF_基本_V.発生区分名       IS '発生区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_支給依頼情報IF_基本_V.重量容積区分     IS '重量容積区分'
/
COMMENT ON COLUMN APPS.XXSKZ_支給依頼情報IF_基本_V.重量容積区分名   IS '重量容積区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_支給依頼情報IF_基本_V.依頼部署コード   IS '依頼部署コード'
/
COMMENT ON COLUMN APPS.XXSKZ_支給依頼情報IF_基本_V.依頼部署名       IS '依頼部署名'
/
COMMENT ON COLUMN APPS.XXSKZ_支給依頼情報IF_基本_V.指示部署コード   IS '指示部署コード'
/
COMMENT ON COLUMN APPS.XXSKZ_支給依頼情報IF_基本_V.指示部署名       IS '指示部署名'
/
COMMENT ON COLUMN APPS.XXSKZ_支給依頼情報IF_基本_V.取引先コード     IS '取引先コード'
/
COMMENT ON COLUMN APPS.XXSKZ_支給依頼情報IF_基本_V.取引先名         IS '取引先名'
/
COMMENT ON COLUMN APPS.XXSKZ_支給依頼情報IF_基本_V.配送先コード     IS '配送先コード'
/
COMMENT ON COLUMN APPS.XXSKZ_支給依頼情報IF_基本_V.配送先名         IS '配送先名'
/
COMMENT ON COLUMN APPS.XXSKZ_支給依頼情報IF_基本_V.出庫倉庫コード   IS '出庫倉庫コード'
/
COMMENT ON COLUMN APPS.XXSKZ_支給依頼情報IF_基本_V.出庫倉庫名       IS '出庫倉庫名'
/
COMMENT ON COLUMN APPS.XXSKZ_支給依頼情報IF_基本_V.運送業者コード   IS '運送業者コード'
/
COMMENT ON COLUMN APPS.XXSKZ_支給依頼情報IF_基本_V.運送業者名       IS '運送業者名'
/
COMMENT ON COLUMN APPS.XXSKZ_支給依頼情報IF_基本_V.出庫日           IS '出庫日'
/
COMMENT ON COLUMN APPS.XXSKZ_支給依頼情報IF_基本_V.入庫日           IS '入庫日'
/
COMMENT ON COLUMN APPS.XXSKZ_支給依頼情報IF_基本_V.運賃区分         IS '運賃区分'
/
COMMENT ON COLUMN APPS.XXSKZ_支給依頼情報IF_基本_V.運賃区分名       IS '運賃区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_支給依頼情報IF_基本_V.引取区分         IS '引取区分'
/
COMMENT ON COLUMN APPS.XXSKZ_支給依頼情報IF_基本_V.引取区分名       IS '引取区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_支給依頼情報IF_基本_V.着荷時間FROM     IS '着荷時間FROM'
/
COMMENT ON COLUMN APPS.XXSKZ_支給依頼情報IF_基本_V.着荷時間FROM名   IS '着荷時間FROM名'
/
COMMENT ON COLUMN APPS.XXSKZ_支給依頼情報IF_基本_V.着荷時間TO       IS '着荷時間TO'
/
COMMENT ON COLUMN APPS.XXSKZ_支給依頼情報IF_基本_V.着荷時間TO名     IS '着荷時間TO名'
/
COMMENT ON COLUMN APPS.XXSKZ_支給依頼情報IF_基本_V.製造日           IS '製造日'
/
COMMENT ON COLUMN APPS.XXSKZ_支給依頼情報IF_基本_V.製造品目コード   IS '製造品目コード'
/
COMMENT ON COLUMN APPS.XXSKZ_支給依頼情報IF_基本_V.製造品目名       IS '製造品目名'
/
COMMENT ON COLUMN APPS.XXSKZ_支給依頼情報IF_基本_V.製造品目略称     IS '製造品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_支給依頼情報IF_基本_V.製造番号         IS '製造番号'
/
COMMENT ON COLUMN APPS.XXSKZ_支給依頼情報IF_基本_V.ヘッダ摘要       IS 'ヘッダ摘要'
/
COMMENT ON COLUMN APPS.XXSKZ_支給依頼情報IF_基本_V.明細番号         IS '明細番号'
/
COMMENT ON COLUMN APPS.XXSKZ_支給依頼情報IF_基本_V.商品区分         IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKZ_支給依頼情報IF_基本_V.商品区分名       IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_支給依頼情報IF_基本_V.品目区分         IS '品目区分'
/
COMMENT ON COLUMN APPS.XXSKZ_支給依頼情報IF_基本_V.品目区分名       IS '品目区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_支給依頼情報IF_基本_V.群コード         IS '群コード'
/
COMMENT ON COLUMN APPS.XXSKZ_支給依頼情報IF_基本_V.品目コード       IS '品目コード'
/
COMMENT ON COLUMN APPS.XXSKZ_支給依頼情報IF_基本_V.品目名           IS '品目名'
/
COMMENT ON COLUMN APPS.XXSKZ_支給依頼情報IF_基本_V.品目略称         IS '品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_支給依頼情報IF_基本_V.付帯             IS '付帯'
/
COMMENT ON COLUMN APPS.XXSKZ_支給依頼情報IF_基本_V.依頼数量         IS '依頼数量'
/
COMMENT ON COLUMN APPS.XXSKZ_支給依頼情報IF_基本_V.明細摘要         IS '明細摘要'
/
COMMENT ON COLUMN APPS.XXSKZ_支給依頼情報IF_基本_V.作成者           IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKZ_支給依頼情報IF_基本_V.作成日           IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKZ_支給依頼情報IF_基本_V.最終更新者       IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKZ_支給依頼情報IF_基本_V.最終更新日       IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKZ_支給依頼情報IF_基本_V.最終更新ログイン IS '最終更新ログイン'
/
