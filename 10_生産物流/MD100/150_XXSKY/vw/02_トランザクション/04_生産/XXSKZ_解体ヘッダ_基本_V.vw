/*************************************************************************
 * 
 * View  Name      : XXSKZ_解体ヘッダ_基本_V
 * Description     : XXSKZ_解体ヘッダ_基本_V
 * MD.070          : 
 * Version         : 1.1
 * 
 * Change Record
 * ------------- ----- ---------------- -------------------------------------
 *  Date          Ver.  Editor          Description
 * ------------- ----- ---------------- -------------------------------------
 *  2012/11/26    1.0   SCSK M.Nagai    初回作成
 *  2013/03/19    1.1   SCSK D.Sugahara E_本稼働_10479 課題20対応
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_解体ヘッダ_基本_V
(
 バッチNO
,プラントコード
,プラント名
,レシピ
,レシピ名称
,レシピ摘要
,フォーミュラ
,フォーミュラ名称
,フォーミュラ摘要
,フォーミュラ名称２
,フォーミュラ摘要２
,工順
,工順名称
,工順摘要
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
,解体元_商品区分
,解体元_商品区分名
,解体元_品目区分
,解体元_品目区分名
,解体元_群コード
,解体元_品目コード
,解体元_品目正式名
,解体元_品目略称
,解体元_ロットNO
,解体元_製造年月日
,解体元_固有記号
,解体元_賞味期限日
,解体元_計画数量
,解体元_WIP計画数量
,解体元_オリジナル数量
,解体元_実績数量
,解体元_単位
,解体元_原価割当
,解体元_割当済フラグ
,解体元_割当済フラグ名
,作成者
,作成日
,最終更新者
,最終更新日
,最終更新ログイン
)
AS
SELECT
        -- 生産バッチヘッダ
         GPROD.batch_no                                     -- バッチNo
        ,GPROD.plant_code                                   -- プラントコード
        ,SOMT.orgn_name                                     -- プラント名
        ,GRPB.recipe_no                                     -- レシピ
        ,GRPT.recipe_description                            -- レシピ名称
        ,GRPT.recipe_description                            -- レシピ摘要
        ,FFMB.formula_no                                    -- フォーミュラ
        ,FFMT.formula_desc1                                 -- フォーミュラ名称
        ,FFMT.formula_desc2                                 -- フォーミュラ名称２
        ,FFMT.formula_desc1                                 -- フォーミュラ摘要
        ,FFMT.formula_desc2                                 -- フォーミュラ摘要２
        ,GPROD.routing_no                                   -- 工順
        ,GRTT.routing_desc                                  -- 工順摘要
        ,GRTT.routing_desc                                  -- 工順摘要２
        ,GPROD.plan_start_date                              -- 計画開始日
        ,GPROD.actual_start_date                            -- 実績開始日
        ,GPROD.due_date                                     -- 必須完了日
        ,GPROD.plan_cmplt_date                              -- 計画完了日
        ,GPROD.actual_cmplt_date                            -- 実績完了日
        ,GPROD.batch_status                                 -- バッチステータス
        ,FLV01.meaning                                      -- バッチステータス名
        ,GPROD.wip_whse_code                                -- WIP倉庫
        ,IWM.whse_name                                      -- WIP倉庫名
        ,GPROD.batch_close_date                             -- クローズ日
        ,GPROD.delete_mark                                  -- 削除マーク
        -- 生産明細(解体元情報)
        ,XPCV.prod_class_code                               -- 解体元_商品区分
        ,XPCV.prod_class_name                               -- 解体元_商品区分名
        ,XICV.item_class_code                               -- 解体元_品目区分
        ,XICV.item_class_name                               -- 解体元_品目区分名
        ,XCCV.crowd_code                                    -- 解体元_群コード
        ,XIM2V.item_no                                      -- 解体元_品目コード
        ,XIM2V.item_name                                    -- 解体元_品目正式名
        ,XIM2V.item_short_name                              -- 解体元_品目略称
        ,NVL( DECODE( ILM.lot_no, 'DEFAULTLOT', '0', ILM.lot_no ), '0' )
                                        lot_no              --- 解体元_ロットNo('DEFALTLOT'、ロット未割当は'0')
        ,CASE WHEN XIM2V.lot_ctl = 1 THEN ILM.attribute1  --ロット管理品   →製造年月日を取得
              ELSE NULL                                   --非ロット管理品 →NULL
         END                            manufacture_date    -- 解体元_製造年月日
        ,CASE WHEN XIM2V.lot_ctl = 1 THEN ILM.attribute2  --ロット管理品   →固有記号を取得
              ELSE NULL                                   --非ロット管理品 →NULL
         END                            uniqe_sign          -- 解体元_固有記号
        ,CASE WHEN XIM2V.lot_ctl = 1 THEN ILM.attribute3  --ロット管理品   →賞味期限日を取得
              ELSE NULL                                   --非ロット管理品 →NULL
         END                            expiration_date     -- 解体元_賞味期限日
        ,ROUND( GPROD.plan_qty    , 3 )                     -- 解体元_計画数量
        ,ROUND( GPROD.wip_plan_qty, 3 )                     -- 解体元_WIP計画数量
        ,ROUND( GPROD.original_qty, 3 )                     -- 解体元_オリジナル数量
        ,ROUND( GPROD.actual_qty  , 3 )                     -- 解体元_実績数量
        ,GPROD.item_um                                      -- 解体元_単位
        ,GPROD.cost_alloc                                   -- 解体元_原価割当
        ,GPROD.alloc_ind                                    -- 解体元_割当済フラグ
        ,CASE WHEN GPROD.alloc_ind = 0 THEN '未割当'
              WHEN GPROD.alloc_ind = 1 THEN '割当済'
         END                            alloc_ind_name      -- 解体元_割当済フラグ名
        -- ユーザ情報
        ,FU_CB.user_name                                    -- 作成者
        ,TO_CHAR( GPROD.creation_date   , 'YYYY/MM/DD HH24:MI:SS' )
                                                            -- 作成日
        ,FU_LU.user_name                                    -- 最終更新者
        ,TO_CHAR( GPROD.last_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                                            -- 最終更新日
        ,FU_LL.user_name                                    -- 最終更新ログイン
FROM
        -- 名称取得系以外のデータはこの内部SQLで全て取得する
        ( SELECT
                -- 生産バッチヘッダ
                 GBH.batch_no                               -- バッチNo
                ,GBH.plant_code                             -- プラントコード
                ,GBH.recipe_validity_rule_id                -- レシピ妥当性ルール
                ,GBH.formula_id                             -- フォーミュラ
                ,GBH.routing_id                             -- 工順
                ,GBH.plan_start_date                        -- 計画開始日
                ,GBH.actual_start_date                      -- 実績開始日
                ,GBH.due_date                               -- 必須完了日
                ,GBH.plan_cmplt_date                        -- 計画完了日
                ,GBH.actual_cmplt_date                      -- 実績完了日
                ,GBH.batch_status                           -- バッチステータス
                ,GBH.wip_whse_code                          -- WIP倉庫
                ,GBH.batch_close_date                       -- クローズ日
                ,GBH.delete_mark                            -- 削除マーク
                -- 生産明細(解体元情報)
                ,GMD.item_id                                -- 解体元_商品区分、品目区分、群コード、品目名称
                ,ITP.lot_id                                 -- 解体元_ロットID
                ,GMD.plan_qty                               -- 解体元_計画数量
                ,GMD.wip_plan_qty                           -- 解体元_WIP計画数量
                ,GMD.original_qty                           -- 解体元_オリジナル数量
                ,GMD.actual_qty                             -- 解体元_実績数量
                ,GMD.item_um                                -- 解体元_単位
                ,GMD.cost_alloc                             -- 解体元_原価割当
                ,GMD.alloc_ind                              -- 解体元_割当済フラグ
                ,GMD.created_by                             -- 作成者
                ,GMD.creation_date                          -- 作成日
                ,GMD.last_updated_by                        -- 最終更新者
                ,GMD.last_update_date                       -- 最終更新日
                ,GMD.last_update_login                      -- 最終更新ログイン
                -- 生産情報工順
                ,GRB.routing_no                             -- 工順
                --名称取得用基準日
                ,NVL( TO_DATE( GBH.actual_cmplt_date ), TRUNC( GBH.plan_start_date ) )    --NVL( 実績完了日, 計画開始日 )
                                             act_date       -- 実施日 (⇒品目名称取得で使用)
        FROM
--Mod 2013/3/19 V1.1 Start 解体データがバックアップされるまでは元テーブル参照
--                 xxcmn_gme_batch_header_arc      GBH            -- 生産バッチヘッダ（標準）バックアップ
--                ,xxcmn_gme_material_details_arc  GMD            -- 生産原料詳細（標準）バックアップ
                 gme_batch_header            GBH            -- 生産バッチ
                ,gme_material_details        GMD            -- 生産明細(解体元情報)
                ,gmd_routings_b                  GRB            -- 工順マスタ
--                ,xxcmn_ic_tran_pnd_arc           ITP            -- OPM保留在庫トランザクション（標準）バックアップ
                ,ic_tran_pnd                 ITP            -- 保留在庫トランザクション(ロットID取得用)
--Mod 2013/3/19 V1.1 End
        WHERE
                -- データ取得条件
                    GBH.batch_type           = 0
                -- 解体元品明細部結合条件
                AND GMD.line_type            = '-1'         -- 解体元
                AND GBH.batch_id             = GMD.batch_id
                -- 生産情報取得条件
                AND GRB.routing_class        IN ( '61', '62' )   -- 解体
                AND GBH.routing_id           = GRB.routing_id
                --ロットID取得
                AND  ITP.doc_type(+)         = 'PROD'
                AND  ITP.delete_mark(+)      = 0
                AND  ITP.completed_ind(+)    = 1             --完了
                AND  ITP.reverse_id(+)       IS NULL
                AND  GMD.material_detail_id  = ITP.line_id(+)
                AND  GMD.item_id             = ITP.item_id(+)
        )                               GPROD               -- 生産バッチヘッダ＆生産明細(解体元情報)
        -- 以下は上記SQL内部の項目を使用して外部結合を行うもの(エラー回避策)
        ,sy_orgn_mst_tl                 SOMT                -- OPMプラントマスタ
        ,gmd_recipes_b                  GRPB                -- レシピマスタ
        ,gmd_recipes_tl                 GRPT                -- レシピマスタ
        ,gmd_recipe_validity_rules      GRPVR               -- レシピ妥当性ルール
        ,fm_form_mst_b                  FFMB                -- フォーミュラマスタ
        ,fm_form_mst_tl                 FFMT                -- フォーミュラマスタ(言語)
        ,gmd_routings_tl                GRTT                -- 工順マスタ(言語)
        ,ic_whse_mst                    IWM                 -- OPM倉庫マスタ
        ,xxskz_prod_class_v             XPCV                -- SKYLINK用中間VIEW OPM品目区分VIEW(解体元_商品区分)
        ,xxskz_item_class_v             XICV                -- SKYLINK用中間VIEW OPM品目区分VIEW(解体元_品目区分)
        ,xxskz_crowd_code_v             XCCV                -- SKYLINK用中間VIEW OPM品目区分VIEW(解体元_群コード)
        ,xxskz_item_mst2_v              XIM2V               -- SKYLINK用中間VIEW OPM品目情報VIEW2(解体元_品目名)
        ,ic_lots_mst                    ILM                 -- OPMロットマスタ(ロットNo取得用)
        ,fnd_lookup_values              FLV01               -- クイックコード表(バッチステータス名)
        ,fnd_user                       FU_CB               -- ユーザーマスタ(CREATED_BY名称取得用)
        ,fnd_user                       FU_LU               -- ユーザーマスタ(LAST_UPDATE_BY名称取得用)
        ,fnd_user                       FU_LL               -- ユーザーマスタ(LAST_UPDATE_LOGIN名称取得用)
        ,fnd_logins                     FL_LL               -- ログインマスタ(LAST_UPDATE_LOGIN名称取得用)
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
        -- 解体元_商品区分
   AND  GPROD.item_id                   = XPCV.item_id(+)
        -- 解体元_品目区分
   AND  GPROD.item_id                   = XICV.item_id(+)
        -- 解体元_群コード
   AND  GPROD.item_id                   = XCCV.item_id(+)
        -- 解体元_品目名称
   AND  GPROD.item_id                   = XIM2V.item_id(+)
   AND  GPROD.act_date                 >= XIM2V.start_date_active(+)
   AND  GPROD.act_date                 <= XIM2V.end_date_active(+)
        -- ロット情報取得
   AND  GPROD.item_id                   = ILM.item_id(+)
   AND  GPROD.lot_id                    = ILM.lot_id(+)
        -- バッチステータス名
   AND  FLV01.language(+)               = 'JA'
   AND  FLV01.lookup_type(+)            = 'GME_BATCH_STATUS'
   AND  FLV01.lookup_code(+)            = GPROD.batch_status
        -- ユーザ名など
   AND  GPROD.created_by                = FU_CB.user_id(+)
   AND  GPROD.last_updated_by           = FU_LU.user_id(+)
   AND  GPROD.last_update_login         = FL_LL.login_id(+)
   AND  FL_LL.user_id                   = FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKZ_解体ヘッダ_基本_V IS 'SKYLINK用解体ヘッダ（基本）VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_解体ヘッダ_基本_V.バッチNO              IS 'バッチNO'
/
COMMENT ON COLUMN APPS.XXSKZ_解体ヘッダ_基本_V.プラントコード        IS 'プラントコード'
/
COMMENT ON COLUMN APPS.XXSKZ_解体ヘッダ_基本_V.プラント名            IS 'プラント名'
/
COMMENT ON COLUMN APPS.XXSKZ_解体ヘッダ_基本_V.レシピ                IS 'レシピ'
/
COMMENT ON COLUMN APPS.XXSKZ_解体ヘッダ_基本_V.レシピ名称            IS 'レシピ名称'
/
COMMENT ON COLUMN APPS.XXSKZ_解体ヘッダ_基本_V.レシピ摘要            IS 'レシピ摘要'
/
COMMENT ON COLUMN APPS.XXSKZ_解体ヘッダ_基本_V.フォーミュラ          IS 'フォーミュラ'
/
COMMENT ON COLUMN APPS.XXSKZ_解体ヘッダ_基本_V.フォーミュラ名称      IS 'フォーミュラ名称'
/
COMMENT ON COLUMN APPS.XXSKZ_解体ヘッダ_基本_V.フォーミュラ名称２    IS 'フォーミュラ名称２'
/
COMMENT ON COLUMN APPS.XXSKZ_解体ヘッダ_基本_V.フォーミュラ摘要      IS 'フォーミュラ摘要'
/
COMMENT ON COLUMN APPS.XXSKZ_解体ヘッダ_基本_V.フォーミュラ摘要２    IS 'フォーミュラ摘要２'
/
COMMENT ON COLUMN APPS.XXSKZ_解体ヘッダ_基本_V.工順                  IS '工順'
/
COMMENT ON COLUMN APPS.XXSKZ_解体ヘッダ_基本_V.工順名称              IS '工順名称'
/
COMMENT ON COLUMN APPS.XXSKZ_解体ヘッダ_基本_V.工順摘要              IS '工順摘要'
/
COMMENT ON COLUMN APPS.XXSKZ_解体ヘッダ_基本_V.計画開始日            IS '計画開始日'
/
COMMENT ON COLUMN APPS.XXSKZ_解体ヘッダ_基本_V.実績開始日            IS '実績開始日'
/
COMMENT ON COLUMN APPS.XXSKZ_解体ヘッダ_基本_V.必須完了日            IS '必須完了日'
/
COMMENT ON COLUMN APPS.XXSKZ_解体ヘッダ_基本_V.計画完了日            IS '計画完了日'
/
COMMENT ON COLUMN APPS.XXSKZ_解体ヘッダ_基本_V.実績完了日            IS '実績完了日'
/
COMMENT ON COLUMN APPS.XXSKZ_解体ヘッダ_基本_V.バッチステータス      IS 'バッチステータス'
/
COMMENT ON COLUMN APPS.XXSKZ_解体ヘッダ_基本_V.バッチステータス名    IS 'バッチステータス名'
/
COMMENT ON COLUMN APPS.XXSKZ_解体ヘッダ_基本_V.WIP倉庫               IS 'WIP倉庫'
/
COMMENT ON COLUMN APPS.XXSKZ_解体ヘッダ_基本_V.WIP倉庫名             IS 'WIP倉庫名'
/
COMMENT ON COLUMN APPS.XXSKZ_解体ヘッダ_基本_V.クローズ日            IS 'クローズ日'
/
COMMENT ON COLUMN APPS.XXSKZ_解体ヘッダ_基本_V.削除マーク            IS '削除マーク'
/
COMMENT ON COLUMN APPS.XXSKZ_解体ヘッダ_基本_V.解体元_商品区分       IS '解体元_商品区分'
/
COMMENT ON COLUMN APPS.XXSKZ_解体ヘッダ_基本_V.解体元_商品区分名     IS '解体元_商品区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_解体ヘッダ_基本_V.解体元_品目区分       IS '解体元_品目区分'
/
COMMENT ON COLUMN APPS.XXSKZ_解体ヘッダ_基本_V.解体元_品目区分名     IS '解体元_品目区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_解体ヘッダ_基本_V.解体元_群コード       IS '解体元_群コード'
/
COMMENT ON COLUMN APPS.XXSKZ_解体ヘッダ_基本_V.解体元_品目コード     IS '解体元_品目コード'
/
COMMENT ON COLUMN APPS.XXSKZ_解体ヘッダ_基本_V.解体元_品目正式名     IS '解体元_品目正式名'
/
COMMENT ON COLUMN APPS.XXSKZ_解体ヘッダ_基本_V.解体元_品目略称       IS '解体元_品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_解体ヘッダ_基本_V.解体元_ロットNO       IS '解体元_ロットNO'
/
COMMENT ON COLUMN APPS.XXSKZ_解体ヘッダ_基本_V.解体元_製造年月日     IS '解体元_製造年月日'
/
COMMENT ON COLUMN APPS.XXSKZ_解体ヘッダ_基本_V.解体元_固有記号       IS '解体元_固有記号'
/
COMMENT ON COLUMN APPS.XXSKZ_解体ヘッダ_基本_V.解体元_賞味期限日     IS '解体元_賞味期限日'
/
COMMENT ON COLUMN APPS.XXSKZ_解体ヘッダ_基本_V.解体元_計画数量       IS '解体元_計画数量'
/
COMMENT ON COLUMN APPS.XXSKZ_解体ヘッダ_基本_V.解体元_WIP計画数量    IS '解体元_WIP計画数量'
/
COMMENT ON COLUMN APPS.XXSKZ_解体ヘッダ_基本_V.解体元_オリジナル数量 IS '解体元_オリジナル数量'
/
COMMENT ON COLUMN APPS.XXSKZ_解体ヘッダ_基本_V.解体元_実績数量       IS '解体元_実績数量'
/
COMMENT ON COLUMN APPS.XXSKZ_解体ヘッダ_基本_V.解体元_単位           IS '解体元_単位'
/
COMMENT ON COLUMN APPS.XXSKZ_解体ヘッダ_基本_V.解体元_原価割当       IS '解体元_原価割当'
/
COMMENT ON COLUMN APPS.XXSKZ_解体ヘッダ_基本_V.解体元_割当済フラグ   IS '解体元_割当済フラグ'
/
COMMENT ON COLUMN APPS.XXSKZ_解体ヘッダ_基本_V.解体元_割当済フラグ名 IS '解体元_割当済フラグ名'
/
COMMENT ON COLUMN APPS.XXSKZ_解体ヘッダ_基本_V.作成者                IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKZ_解体ヘッダ_基本_V.作成日                IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKZ_解体ヘッダ_基本_V.最終更新者            IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKZ_解体ヘッダ_基本_V.最終更新日            IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKZ_解体ヘッダ_基本_V.最終更新ログイン      IS '最終更新ログイン'
/
