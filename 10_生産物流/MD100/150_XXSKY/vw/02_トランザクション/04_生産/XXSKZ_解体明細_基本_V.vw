/*************************************************************************
 * 
 * View  Name      : XXSKZ_解体明細_基本_V
 * Description     : XXSKZ_解体明細_基本_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/26    1.0   SCSK M.Nagai 初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_解体明細_基本_V
(
バッチNO
,プラントコード
,プラント名
,ラインNO
,商品区分
,商品区分名
,品目区分
,品目区分名
,群コード
,品目コード
,品目正式名
,品目略称
,ロットNO
,製造年月日
,固有記号
,賞味期限日
,計画数量
,WIP計画数量
,オリジナル数量
,実績数量
,単位
,原価割当
,割当済フラグ
,割当済フラグ名
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
        -- 生産明細 解体元以外(解体先)の情報
        ,GPROD.line_no                                      -- ラインNo
        ,XPCV.prod_class_code                               -- 商品区分
        ,XPCV.prod_class_name                               -- 商品区分名
        ,XICV.item_class_code                               -- 品目区分
        ,XICV.item_class_name                               -- 品目区分名
        ,XCCV.crowd_code                                    -- 群コード
        ,XIM2V.item_no                                      -- 品目コード
        ,XIM2V.item_name                                    -- 品目正式名
        ,XIM2V.item_short_name                              -- 品目略称
        ,NVL( DECODE( ILM.lot_no, 'DEFAULTLOT', '0', ILM.lot_no ), '0' )
                                        lot_no              -- ロットNo('DEFALTLOT'、ロット未割当は'0')
        ,CASE WHEN XIM2V.lot_ctl = 1 THEN ILM.attribute1  --ロット管理品   →製造年月日を取得
              ELSE NULL                                   --非ロット管理品 →NULL
         END                            manufacture_date    -- 製造年月日
        ,CASE WHEN XIM2V.lot_ctl = 1 THEN ILM.attribute2  --ロット管理品   →固有記号を取得
              ELSE NULL                                   --非ロット管理品 →NULL
         END                            uniqe_sign          -- 固有記号
        ,CASE WHEN XIM2V.lot_ctl = 1 THEN ILM.attribute3  --ロット管理品   →賞味期限日を取得
              ELSE NULL                                   --非ロット管理品 →NULL
         END                            expiration_date     -- 賞味期限日
        ,ROUND( GPROD.plan_qty    , 3 )                     -- 計画数量
        ,ROUND( GPROD.wip_plan_qty, 3 )                     -- WIP計画数量
        ,ROUND( GPROD.original_qty, 3 )                     -- オリジナル数量
        ,ROUND( GPROD.actual_qty  , 3 )                     -- 実績数量
        ,GPROD.item_um                                      -- 単位
        ,GPROD.cost_alloc                                   -- 原価割当
        ,GPROD.alloc_ind                                    -- 割当済フラグ
        ,CASE WHEN GPROD.alloc_ind = 0 THEN '未割当'
              WHEN GPROD.alloc_ind = 1 THEN '割当済'
         END                            alloc_ind_name      -- 割当済フラグ名
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
                ,GBH.plan_start_date                        -- ★計画開始日(外部結合用)
                -- 生産明細 完成品以外(原料、副産物)の情報
                ,GMD.line_no                                -- ラインNo
                ,GMD.plan_qty                               -- 計画数量
                ,GMD.wip_plan_qty                           -- WIP計画数量
                ,GMD.original_qty                           -- オリジナル数量
                ,GMD.actual_qty                             -- 実績数量
                ,GMD.item_um                                -- 単位
                ,GMD.cost_alloc                             -- 原価割当
                ,GMD.alloc_ind                              -- 割当済フラグ
                ,GMD.created_by                             -- 作成者
                ,GMD.creation_date                          -- 作成日
                ,GMD.last_updated_by                        -- 最終更新者
                ,GMD.last_update_date                       -- 最終更新日
                ,GMD.last_update_login                      -- 最終更新ログイン
                ,GMD.item_id                                -- 解体先_商品区分、品目区分、群コード、品目名称(外部結合用)
                ,ITP.lot_id                                 -- 解体先_ロットID
                --名称取得用基準日
                ,NVL( TO_DATE( GBH.actual_cmplt_date ), TRUNC( GBH.plan_start_date ) )    --NVL( 実績完了日, 計画開始日 )
                                             act_date       -- 実施日 (⇒品目名称取得で使用)
        FROM
                 xxcmn_gme_batch_header_arc            GBH            -- 生産バッチヘッダ（標準）バックアップ
                ,xxcmn_gme_material_details_arc        GMD            -- 生産原料詳細（標準）バックアップ
                ,gmd_routings_b                        GRB            -- 工順マスタ
                ,xxcmn_ic_tran_pnd_arc                 ITP            -- OPM保留在庫トランザクション（標準）バックアップ
        WHERE
                -- ヘッダテーブルとの結合
                    GBH.batch_type           = 0
                AND GBH.batch_id             = GMD.batch_id
                -- 『完成品以外（原料、副産物）』の明細部取得
                AND GMD.line_type           <> '-1'         -- 解体元以外
                -- 工順(生産情報取得)
                AND GRB.routing_class        IN ( '61', '62' )   -- 解体
                AND GBH.routing_id           = GRB.routing_id
                --ロットID取得
                AND  ITP.doc_type(+)         = 'PROD'
                AND  ITP.delete_mark(+)      = 0
                AND  ITP.completed_ind(+)    = 1             --完了
                AND  ITP.reverse_id(+)       IS NULL
                AND  GMD.material_detail_id  = ITP.line_id(+)
                AND  GMD.item_id             = ITP.item_id(+)
        )                               GPROD               -- 生産バッチヘッダ＆生産明細(完成品情報)
        -- 以下は上記SQL内部の項目を使用して外部結合を行うもの(エラー回避策)
        ,sy_orgn_mst_tl                 SOMT                -- OPMプラントマスタ
        ,xxskz_prod_class_v             XPCV                -- SKYLINK用中間VIEW OPM品目区分VIEW(商品区分)
        ,xxskz_item_class_v             XICV                -- SKYLINK用中間VIEW OPM品目区分VIEW(品目区分)
        ,xxskz_crowd_code_v             XCCV                -- SKYLINK用中間VIEW OPM品目区分VIEW(群コード)
        ,xxskz_item_mst2_v              XIM2V               -- SKYLINK用中間VIEW OPM品目情報VIEW2(品目名)
        ,ic_lots_mst                    ILM                 -- OPMロットマスタ(ロットNo取得用)
        ,fnd_user                       FU_CB               -- ユーザーマスタ(CREATED_BY名称取得用)
        ,fnd_user                       FU_LU               -- ユーザーマスタ(LAST_UPDATE_BY名称取得用)
        ,fnd_user                       FU_LL               -- ユーザーマスタ(LAST_UPDATE_LOGIN名称取得用)
        ,fnd_logins                     FL_LL               -- ログインマスタ(LAST_UPDATE_LOGIN名称取得用)
WHERE
        -- プラント名
        SOMT.language(+)                = 'JA'
   AND  GPROD.plant_code                = SOMT.orgn_code(+)
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
        -- ロット情報取得
   AND  GPROD.item_id                   = ILM.item_id(+)
   AND  GPROD.lot_id                    = ILM.lot_id(+)
        -- ユーザ名など
   AND  GPROD.created_by                = FU_CB.user_id(+)
   AND  GPROD.last_updated_by           = FU_LU.user_id(+)
   AND  GPROD.last_update_login         = FL_LL.login_id(+)
   AND  FL_LL.user_id                   = FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKZ_解体明細_基本_V IS 'SKYLINK用解体明細（基本）VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_解体明細_基本_V.バッチNO           IS 'バッチNo'
/
COMMENT ON COLUMN APPS.XXSKZ_解体明細_基本_V.プラントコード     IS 'プラントコード'
/
COMMENT ON COLUMN APPS.XXSKZ_解体明細_基本_V.プラント名         IS 'プラント名'
/
COMMENT ON COLUMN APPS.XXSKZ_解体明細_基本_V.ラインNO           IS 'ラインNo'
/
COMMENT ON COLUMN APPS.XXSKZ_解体明細_基本_V.商品区分           IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKZ_解体明細_基本_V.商品区分名         IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_解体明細_基本_V.品目区分           IS '品目区分'
/
COMMENT ON COLUMN APPS.XXSKZ_解体明細_基本_V.品目区分名         IS '品目区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_解体明細_基本_V.群コード           IS '群コード'
/
COMMENT ON COLUMN APPS.XXSKZ_解体明細_基本_V.品目コード         IS '品目コード'
/
COMMENT ON COLUMN APPS.XXSKZ_解体明細_基本_V.品目正式名         IS '品目正式名'
/
COMMENT ON COLUMN APPS.XXSKZ_解体明細_基本_V.品目略称           IS '品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_解体明細_基本_V.ロットNO           IS 'ロットNo'
/
COMMENT ON COLUMN APPS.XXSKZ_解体明細_基本_V.製造年月日         IS '製造年月日'
/
COMMENT ON COLUMN APPS.XXSKZ_解体明細_基本_V.固有記号           IS '固有記号'
/
COMMENT ON COLUMN APPS.XXSKZ_解体明細_基本_V.賞味期限日         IS '賞味期限日'
/
COMMENT ON COLUMN APPS.XXSKZ_解体明細_基本_V.計画数量           IS '計画数量'
/
COMMENT ON COLUMN APPS.XXSKZ_解体明細_基本_V.WIP計画数量        IS 'WIP計画数量'
/
COMMENT ON COLUMN APPS.XXSKZ_解体明細_基本_V.オリジナル数量     IS 'オリジナル数量'
/
COMMENT ON COLUMN APPS.XXSKZ_解体明細_基本_V.実績数量           IS '実績数量'
/
COMMENT ON COLUMN APPS.XXSKZ_解体明細_基本_V.単位               IS '単位'
/
COMMENT ON COLUMN APPS.XXSKZ_解体明細_基本_V.原価割当           IS '原価割当'
/
COMMENT ON COLUMN APPS.XXSKZ_解体明細_基本_V.割当済フラグ       IS '割当済フラグ'
/
COMMENT ON COLUMN APPS.XXSKZ_解体明細_基本_V.割当済フラグ名     IS '割当済フラグ名'
/
COMMENT ON COLUMN APPS.XXSKZ_解体明細_基本_V.作成者             IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKZ_解体明細_基本_V.作成日             IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKZ_解体明細_基本_V.最終更新者         IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKZ_解体明細_基本_V.最終更新日         IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKZ_解体明細_基本_V.最終更新ログイン   IS '最終更新ログイン'
/
