CREATE OR REPLACE VIEW APPS.XXSKY_生産ヘッダ_基本_V
(
 バッチNO
,プラントコード
,プラント名
,レシピ
,レシピ名称
,レシピ摘要
,フォーミュラ
,フォーミュラ名称
,フォーミュラ名称２
,フォーミュラ摘要
,フォーミュラ摘要２
,工順
,工順名称
,工順摘要
,業務ステータス
,業務ステータス名
,送信済みフラグ
,送信済みフラグ名
,計画開始日
,実績開始日
,必須完了日
,計画完了日
,実績完了日
,バッチステータス
,バッチステータス名
,WIP倉庫
,WIP倉庫名
,クローズ日
,削除マーク
,伝票区分
,成績管理部署
,旧伝票番号
,完成品_商品区分
,完成品_商品区分名
,完成品_品目区分
,完成品_品目区分名
,完成品_群コード
,完成品_品目コード
,完成品_品目正式名
,完成品_品目略称
,完成品_ロットNO
,完成品_タイプ
,完成品_タイプ名
,完成品_製造年月日
,完成品_固有記号
,完成品_賞味期限日
,完成品_生産日
,完成品_原料入庫日
,完成品_計画数量
,完成品_WIP計画数量
,完成品_オリジナル数量
,完成品_実績数量
,完成品_単位
,完成品_原価割当
,完成品_割当済フラグ
,完成品_割当済フラグ名
,完成品_ランク１
,完成品_ランク２
,完成品_ランク３
,完成品_摘要
,完成品_在庫入数
,完成品_依頼総数
,完成品_指図総数
,完成品_委託加工単価
,完成品_委託加工費
,完成品_その他金額
,完成品_計算区分
,完成品_計算区分名
,完成品_移動場所コード
,完成品_移動場所名
,作成者
,作成日
,最終更新者
,最終更新日
,最終更新ログイン
)
AS
SELECT
        -- 生産バッチヘッダ
        GPROD.batch_no                                           -- バッチNo
       ,GPROD.plant_code                                         -- プラントコード
       ,SOMT.orgn_name                                           -- プラント名
       ,GRPB.recipe_no                                           -- レシピ
       ,GRPT.recipe_description                                  -- レシピ名称
       ,GRPT.recipe_description                                  -- レシピ摘要
       ,FFMB.formula_no                                          -- フォーミュラ
       ,FFMT.formula_desc1                                       -- フォーミュラ名称
       ,FFMT.formula_desc2                                       -- フォーミュラ名称２
       ,FFMT.formula_desc1                                       -- フォーミュラ摘要
       ,FFMT.formula_desc2                                       -- フォーミュラ摘要２
       ,GPROD.routing_no                                         -- 工順
       ,GRTT.routing_desc                                        -- 工順名称
       ,GRTT.routing_desc                                        -- 工順摘要
       ,GPROD.hattr4                                             -- 業務ステータス
       ,FLV01.meaning                                            -- 業務ステータス名
       ,GPROD.hattr3                                             -- 送信済みフラグ
       ,FLV02.meaning                                            -- 送信済みフラグ名
       ,GPROD.plan_start_date                                    -- 計画開始日
       ,GPROD.actual_start_date                                  -- 実績開始日
       ,GPROD.due_date                                           -- 必須完了日
       ,GPROD.plan_cmplt_date                                    -- 計画完了日
       ,GPROD.actual_cmplt_date                                  -- 実績完了日
       ,GPROD.batch_status                                       -- バッチステータス
       ,FLV03.meaning                                            -- バッチステータス名
       ,GPROD.wip_whse_code                                      -- WIP倉庫
       ,IWM.whse_name                                            -- WIP倉庫名
       ,GPROD.batch_close_date                                   -- クローズ日
       ,GPROD.delete_mark                                        -- 削除マーク
       ,GPROD.hattr1                                             -- 伝票区分
       ,GPROD.hattr2                                             -- 成績管理部署
       ,GPROD.hattr5                                             -- 旧伝票番号
        -- 生産明細(完成品情報)
       ,XPCV.prod_class_code                                     -- 完成品_商品区分
       ,XPCV.prod_class_name                                     -- 完成品_商品区分名
       ,XICV.item_class_code                                     -- 完成品_品目区分
       ,XICV.item_class_name                                     -- 完成品_品目区分名
       ,XCCV.crowd_code                                          -- 完成品_群コード
       ,XIM2V.item_no                                            -- 完成品_品目コード
       ,XIM2V.item_name                                          -- 完成品_品目正式名
       ,XIM2V.item_short_name                                    -- 完成品_品目略称
       ,NVL( DECODE( ILM.lot_no, 'DEFAULTLOT', '0', ILM.lot_no ), '0' )
                                             lot_no              -- 完成品_ロットNo('DEFALTLOT'、ロット未割当は'0')
       ,GPROD.dattr1                                             -- 完成品_タイプ
       ,FLV04.meaning                                            -- 完成品_タイプ名
       ,GPROD.dattr17                                            -- 完成品_製造年月日
       ,CASE WHEN XIM2V.lot_ctl = 1 THEN ILM.attribute2    --ロット管理品   →固有記号を取得
             ELSE NULL                                     --非ロット管理品 →NULL
        END                                  uniqe_sign          -- 完成品_固有記号
       ,GPROD.dattr10                                            -- 完成品_賞味期限日
       ,GPROD.dattr11                                            -- 完成品_生産日
       ,GPROD.dattr22                                            -- 完成品_原料入庫日
       ,ROUND( GPROD.plan_qty    , 3 )                           -- 完成品_計画数量
       ,ROUND( GPROD.wip_plan_qty, 3 )                           -- 完成品_WIP計画数量
       ,ROUND( GPROD.original_qty, 3 )                           -- 完成品_オリジナル数量
       ,ROUND( GPROD.actual_qty  , 3 )                           -- 完成品_実績数量
       ,GPROD.item_um                                            -- 完成品_単位
       ,GPROD.cost_alloc                                         -- 完成品_原価割当
       ,GPROD.alloc_ind                                          -- 完成品_割当済フラグ
       ,CASE WHEN GPROD.alloc_ind = 0 THEN '未割当'
             WHEN GPROD.alloc_ind = 1 THEN '割当済'
        END                                  alloc_ind_name      -- 完成品_割当済フラグ名
       ,GPROD.dattr2                                             -- 完成品_ランク1
       ,GPROD.dattr3                                             -- 完成品_ランク2
       ,GPROD.dattr26                                            -- 完成品_ランク3
       ,GPROD.dattr4                                             -- 完成品_摘要
       ,NVL( ROUND( TO_NUMBER( GPROD.dattr6  ), 3 ), 0 )         -- 完成品_在庫入数
       ,NVL( ROUND( TO_NUMBER( GPROD.dattr7  ), 3 ), 0 )         -- 完成品_依頼総数
       ,NVL( ROUND( TO_NUMBER( GPROD.dattr23 ), 3 ), 0 )         -- 完成品_指図総数
       ,NVL( ROUND( TO_NUMBER( GPROD.dattr9  ), 3 ), 0 )         -- 完成品_委託加工単価
       ,NVL( ROUND( TO_NUMBER( GPROD.dattr15 ), 3 ), 0 )         -- 完成品_委託加工費
       ,NVL( ROUND( TO_NUMBER( GPROD.dattr16 ), 3 ), 0 )         -- 完成品_その他金額
       ,GPROD.dattr14                                            -- 完成品_計算区分
       ,FLV05.meaning                                            -- 完成品_計算区分名
       ,GPROD.dattr12                                            -- 完成品_移動場所コード
       ,XILV01.description                                       -- 完成品_移動場所名
       -- ユーザ情報
       ,FU_CB.user_name                                          -- 作成者
       ,TO_CHAR( GPROD.creation_date   , 'YYYY/MM/DD HH24:MI:SS' )
                                                                 -- 作成日
       ,FU_LU.user_name                                          -- 最終更新者
       ,TO_CHAR( GPROD.last_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                                                 -- 最終更新日
       ,FU_LL.user_name                                          -- 最終更新ログイン
FROM
        -- 名称取得系以外のデータはこの内部SQLで全て取得する
        ( SELECT
                -- 生産バッチヘッダ
                GBH.batch_no                                     -- バッチNo
               ,GBH.routing_id                                   -- 工順
               ,GRTB.routing_no                                  -- 工順No
               ,GBH.plant_code                                   -- プラントコード
               ,GBH.recipe_validity_rule_id                      -- レシピ妥当性ルール
               ,GBH.formula_id                                   -- フォーミュラ名
               ,GBH.attribute4                    HATTR4         -- 業務ステータス
               ,GBH.attribute3                    HATTR3         -- 送信済みフラグ
               ,GBH.plan_start_date                              -- 計画開始日
               ,GBH.actual_start_date                            -- 実績開始日
               ,GBH.due_date                                     -- 必須完了日
               ,GBH.plan_cmplt_date                              -- 計画完了日
               ,GBH.actual_cmplt_date                            -- 実績完了日
               ,GBH.batch_status                                 -- バッチステータス
               ,GBH.wip_whse_code                                -- WIP倉庫
               ,GBH.batch_close_date                             -- クローズ日
               ,GBH.delete_mark                                  -- 削除マーク
               ,GBH.attribute1                    HATTR1         -- 伝票区分
               ,GBH.attribute2                    HATTR2         -- 成績管理部署
               ,GBH.attribute5                    HATTR5         -- 旧伝票番号
                -- 生産明細(完成品情報)
               ,GMD.item_id                                      -- 完成品_商品区分、品目区分、群コード、品目名称
               ,ITP.lot_id                                       -- 完成品_ロットID
               ,GMD.attribute1                    DATTR1         -- 完成品_タイプ
               ,GMD.attribute17                   DATTR17        -- 完成品_製造年月日
               ,GMD.attribute10                   DATTR10        -- 完成品_賞味期限日
               ,GMD.attribute11                   DATTR11        -- 完成品_生産日
               ,GMD.attribute22                   DATTR22        -- 完成品_原料入庫日
               ,GMD.plan_qty                                     -- 完成品_計画数量
               ,GMD.wip_plan_qty                                 -- 完成品_WIP計画数量
               ,GMD.original_qty                                 -- 完成品_オリジナル数量
               ,GMD.actual_qty                                   -- 完成品_実績数量
               ,GMD.item_um                                      -- 完成品_単位
               ,GMD.cost_alloc                                   -- 完成品_原価割当
               ,GMD.alloc_ind                                    -- 完成品_割当済フラグ
               ,GMD.attribute2                    DATTR2         -- 完成品_ランク1
               ,GMD.attribute3                    DATTR3         -- 完成品_ランク2
               ,GMD.attribute26                   DATTR26        -- 完成品_ランク3
               ,GMD.attribute4                    DATTR4         -- 完成品_摘要
               ,GMD.attribute6                    DATTR6         -- 完成品_在庫入数
               ,GMD.attribute7                    DATTR7         -- 完成品_依頼総数
               ,GMD.attribute23                   DATTR23        -- 完成品_指図総数
               ,GMD.attribute9                    DATTR9         -- 完成品_委託加工単価
               ,GMD.attribute15                   DATTR15        -- 完成品_委託加工費
               ,GMD.attribute16                   DATTR16        -- 完成品_その他金額
               ,GMD.attribute14                   DATTR14        -- 完成品_計算区分
               ,GMD.attribute12                   DATTR12        -- 完成品_移動場所コード
               ,GMD.created_by                                   -- 作成者
               ,GMD.creation_date                                -- 作成日(支給依頼情報IF明細)
               ,GMD.last_updated_by                              -- 最終更新者
               ,GMD.last_update_date                             -- 最終更新日(支給依頼情報IF明細)
               ,GMD.last_update_login                            -- 最終更新ログイン
                --名称取得用基準日
-- 2016/06/21 S.Yamashita Mod Start
--               ,NVL( TO_DATE( GMD.attribute11 ), TRUNC( GBH.plan_start_date ) )    --NVL( 生産日, 計画開始日 )
               ,NVL( TO_DATE( GMD.attribute11,'YYYY/MM/DD' ), TRUNC( GBH.plan_start_date ) )    --NVL( 生産日, 計画開始日 )
-- 2016/06/21 S.Yamashita Mod End
                                                  act_date       -- 生産日 (⇒品目名称取得で使用)
          FROM
                 gme_batch_header            GBH                 -- 生産バッチ
                ,gmd_routings_b              GRTB                -- 工順マスタ
                ,gme_material_details        GMD                 -- 生産原料詳細(完成品情報)
                ,ic_tran_pnd                 ITP                 -- 保留在庫トランザクション
         WHERE
                -- データ取得条件
                GBH.batch_type               = 0
           AND  GBH.attribute4              <> '-1'              -- 業務ステータス『取消し』のデータは対象外
                -- 工順(生産情報取得)
           AND  GRTB.routing_class           NOT IN ( '61', '62', '70' )     -- 品目振替(70)、解体(61,62) 以外
           AND  GBH.routing_id               = GRTB.routing_id
                -- 完成品明細部結合条件
           AND  GBH.batch_id                 = GMD.batch_id
           AND  GMD.line_type                = '1'               -- 完成品
                -- ロットID取得
           AND  ITP.doc_type(+)              = 'PROD'
           AND  ITP.delete_mark(+)           = 0
           AND  ITP.reverse_id(+)            IS NULL
           AND  ITP.lot_id(+)               <> 0                 --『資材』は有り得ない
           AND  GMD.material_detail_id       = ITP.line_id(+)
           AND  GMD.item_id                  = ITP.item_id(+)
        )                               GPROD               -- 生産バッチヘッダ＆生産明細(完成品情報)
        -- 以下は上記SQL内部の項目を使用して外部結合を行うもの(エラー回避策)
       ,sy_orgn_mst_tl                  SOMT                -- OPMプラントマスタ
       ,gmd_recipes_b                   GRPB                -- レシピマスタ
       ,gmd_recipes_tl                  GRPT                -- レシピマスタ(日本語)
       ,gmd_recipe_validity_rules       GRPVR               -- △レシピ妥当性ルール(WHERE句のみ)
       ,fm_form_mst_b                   FFMB                -- フォーミュラマスタ
       ,fm_form_mst_tl                  FFMT                -- フォーミュラマスタ(言語)
       ,gmd_routings_tl                 GRTT                -- 工順マスタ(言語)
       ,ic_whse_mst                     IWM                 -- OPM倉庫マスタ
       ,xxsky_prod_class_v              XPCV                -- SKYLINK用中間VIEW OPM品目区分VIEW(完成品_商品区分)
       ,xxsky_item_class_v              XICV                -- SKYLINK用中間VIEW OPM品目区分VIEW(完成品_品目区分)
       ,xxsky_crowd_code_v              XCCV                -- SKYLINK用中間VIEW OPM品目区分VIEW(完成品_群コード)
       ,xxsky_item_mst2_v               XIM2V               -- SKYLINK用中間VIEW OPM品目情報VIEW2(完成品_品目名)
       ,ic_lots_mst                     ILM                 -- OPMロットマスタ
       ,fnd_lookup_values               FLV01               -- クイックコード表(業務ステータス名)
       ,fnd_lookup_values               FLV02               -- クイックコード表(送信済みフラグ名)
       ,fnd_lookup_values               FLV03               -- クイックコード表(バッチステータス名)
       ,fnd_lookup_values               FLV04               -- クイックコード表(完成品_タイプ名)
       ,fnd_lookup_values               FLV05               -- クイックコード表(完成品_計算区分名)
       ,xxsky_item_locations_v          XILV01              -- SKYLINK用中間VIEW OPM保管場所情報VIEW(完成品_移動場所名)
       ,fnd_user                        FU_CB               -- ユーザーマスタ(CREATED_BY名称取得用)
       ,fnd_user                        FU_LU               -- ユーザーマスタ(LAST_UPDATE_BY名称取得用)
       ,fnd_user                        FU_LL               -- ユーザーマスタ(LAST_UPDATE_LOGIN名称取得用)
       ,fnd_logins                      FL_LL               -- ログインマスタ(LAST_UPDATE_LOGIN名称取得用)
WHERE
        -- プラント名
        SOMT.language(+)                = 'JA'
   AND  GPROD.plant_code                = SOMT.orgn_code(+)
        -- レシピ名
   AND  GPROD.recipe_validity_rule_id   = GRPVR.recipe_validity_rule_id(+)
   AND  GRPVR.recipe_id                 = GRPB.recipe_id(+)
   AND  GRPVR.recipe_id                 = GRPT.recipe_id(+)
   AND  GRPT.language(+)                = 'JA'
        -- フォーミュラ名
   AND  GPROD.formula_id                = FFMB.formula_id(+)
   AND  FFMT.language(+)                = 'JA'
   AND  FFMB.formula_id                 = FFMT.formula_id(+)
        -- 工順名
   AND  GRTT.language(+)                = 'JA'
   AND  GPROD.routing_id                = GRTT.routing_id(+)
        -- WIP倉庫名
   AND  GPROD.wip_whse_code             = IWM.whse_code(+)
        -- 完成品_商品区分
   AND  GPROD.item_id                   = XPCV.item_id(+)
        -- 完成品_品目区分
   AND  GPROD.item_id                   = XICV.item_id(+)
        -- 完成品_群コード
   AND  GPROD.item_id                   = XCCV.item_id(+)
        -- 完成品_品目名称
   AND  GPROD.item_id                   = XIM2V.item_id(+)
   AND  GPROD.act_date                 >= XIM2V.start_date_active(+)
   AND  GPROD.act_date                 <= XIM2V.end_date_active(+)
        -- 完成品ロット情報
   AND  GPROD.item_id                   = ILM.item_id(+)
   AND  GPROD.lot_id                    = ILM.lot_id(+)
        -- 完成品_移動場所
   AND  GPROD.dattr12                   = XILV01.segment1(+)
        -- ユーザ名など
   AND  GPROD.created_by                = FU_CB.user_id(+)
   AND  GPROD.last_updated_by           = FU_LU.user_id(+)
   AND  GPROD.last_update_login         = FL_LL.login_id(+)
   AND  FL_LL.user_id                   = FU_LL.user_id(+)
        -- 【クイックコード】業務ステータス名
   AND  FLV01.language(+)               = 'JA'
   AND  FLV01.lookup_type(+)            = 'XXWIP_DUTY_STATUS'
   AND  FLV01.lookup_code(+)            = GPROD.hattr4
        -- 【クイックコード】送信済みフラグ名
   AND  FLV02.language(+)               = 'JA'
   AND  FLV02.lookup_type(+)            = 'XXCMN_INCLUDE_EXCLUDE'
   AND  FLV02.lookup_code(+)            = GPROD.hattr3
        -- 【クイックコード】バッチステータス名
   AND  FLV03.language(+)               = 'JA'
   AND  FLV03.lookup_type(+)            = 'GME_BATCH_STATUS'
   AND  FLV03.lookup_code(+)            = GPROD.batch_status
        -- 【クイックコード】完成品_タイプ名
   AND  FLV04.language(+)               = 'JA'
   AND  FLV04.lookup_type(+)            = 'XXCMN_L08'
   AND  FLV04.lookup_code(+)            = GPROD.dattr1
        -- 【クイックコード】完成品_計算区分名
   AND  FLV05.language(+)               = 'JA'
   AND  FLV05.lookup_type(+)            = 'XXWIP_CALCULATE_TYPE'
   AND  FLV05.lookup_code(+)            = GPROD.dattr14
/
COMMENT ON TABLE APPS.XXSKY_生産ヘッダ_基本_V IS 'SKYLINK用生産ヘッダ（基本）VIEW'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.バッチNO              IS 'バッチNo'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.プラントコード        IS 'プラントコード'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.プラント名            IS 'プラント名'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.レシピ                IS 'レシピ'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.レシピ名称            IS 'レシピ名称'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.レシピ摘要            IS 'レシピ摘要'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.フォーミュラ          IS 'フォーミュラ'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.フォーミュラ名称      IS 'フォーミュラ名称'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.フォーミュラ名称２    IS 'フォーミュラ名称２'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.フォーミュラ摘要      IS 'フォーミュラ摘要'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.フォーミュラ摘要２    IS 'フォーミュラ摘要２'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.工順                  IS '工順'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.工順名称              IS '工順名称'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.工順摘要              IS '工順摘要'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.業務ステータス        IS '業務ステータス'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.業務ステータス名      IS '業務ステータス名'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.送信済みフラグ        IS '送信済みフラグ'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.送信済みフラグ名      IS '送信済みフラグ名'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.計画開始日            IS '計画開始日'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.実績開始日            IS '実績開始日'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.必須完了日            IS '必須完了日'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.計画完了日            IS '計画完了日'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.実績完了日            IS '実績完了日'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.バッチステータス      IS 'バッチステータス'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.バッチステータス名    IS 'バッチステータス名'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.WIP倉庫               IS 'WIP倉庫'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.WIP倉庫名             IS 'WIP倉庫名'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.クローズ日            IS 'クローズ日'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.削除マーク            IS '削除マーク'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.伝票区分              IS '伝票区分'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.成績管理部署          IS '成績管理部署'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.旧伝票番号            IS '旧伝票番号'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.完成品_商品区分       IS '完成品_商品区分'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.完成品_商品区分名     IS '完成品_商品区分名'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.完成品_品目区分       IS '完成品_品目区分'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.完成品_品目区分名     IS '完成品_品目区分名'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.完成品_群コード       IS '完成品_群コード'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.完成品_品目コード     IS '完成品_品目コード'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.完成品_品目正式名     IS '完成品_品目正式名'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.完成品_品目略称       IS '完成品_品目略称'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.完成品_ロットNO       IS '完成品_ロットNo'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.完成品_タイプ         IS '完成品_タイプ'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.完成品_タイプ名       IS '完成品_タイプ名'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.完成品_製造年月日     IS '完成品_製造年月日'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.完成品_固有記号       IS '完成品_固有記号'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.完成品_賞味期限日     IS '完成品_賞味期限日'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.完成品_生産日         IS '完成品_生産日'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.完成品_原料入庫日     IS '完成品_原料入庫日'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.完成品_計画数量       IS '完成品_計画数量'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.完成品_WIP計画数量    IS '完成品_WIP計画数量'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.完成品_オリジナル数量 IS '完成品_オリジナル数量'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.完成品_実績数量       IS '完成品_実績数量'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.完成品_単位           IS '完成品_単位'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.完成品_原価割当       IS '完成品_原価割当'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.完成品_割当済フラグ   IS '完成品_割当済フラグ'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.完成品_割当済フラグ名 IS '完成品_割当済フラグ名'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.完成品_ランク１       IS '完成品_ランク１'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.完成品_ランク２       IS '完成品_ランク２'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.完成品_ランク３       IS '完成品_ランク３'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.完成品_摘要           IS '完成品_摘要'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.完成品_在庫入数       IS '完成品_在庫入数'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.完成品_依頼総数       IS '完成品_依頼総数'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.完成品_指図総数       IS '完成品_指図総数'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.完成品_委託加工単価   IS '完成品_委託加工単価'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.完成品_委託加工費     IS '完成品_委託加工費'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.完成品_その他金額     IS '完成品_その他金額'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.完成品_計算区分       IS '完成品_計算区分'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.完成品_計算区分名     IS '完成品_計算区分名'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.完成品_移動場所コード IS '完成品_移動場所コード'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.完成品_移動場所名     IS '完成品_移動場所名'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.作成者                IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.作成日                IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.最終更新者            IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.最終更新日            IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKY_生産ヘッダ_基本_V.最終更新ログイン      IS '最終更新ログイン'
/
