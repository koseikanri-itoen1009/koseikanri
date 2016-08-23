CREATE OR REPLACE VIEW APPS.XXSKY_生産明細_基本_V
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
,ラインタイプ
,ラインタイプ名
,タイプ
,タイプ名
,投入口区分
,投入口区分名
,打込区分
,打込区分名
,生産日
,原料入庫日
,計画数量
,WIP計画数量
,オリジナル数量
,実績数量
,単位
,原価割当
,割当済フラグ
,割当済フラグ名
,ランク１
,ランク２
,ランク３
,摘要
,在庫入数
,依頼総数
,原料削除フラグ
,出倉庫コード１
,出倉庫名１
,出倉庫コード２
,出倉庫名２
,出倉庫コード３
,出倉庫名３
,出倉庫コード４
,出倉庫名４
,出倉庫コード５
,出倉庫名５
,ロット_指示総数
,ロット_投入数量
,ロット_戻入数量
,ロット_資材製造不良数
,ロット_資材業者不良数
,ロット_手配倉庫コード
,ロット_手配倉庫名
,ロット_予定区分
,ロット_予定区分名
,ロット_予定番号
,作成者
,作成日
,最終更新者
,最終更新日
,最終更新ログイン
)
AS
SELECT
        -- 生産バッチヘッダ
         GPROD.batch_no                      batch_no                -- バッチNo
        ,GPROD.plant_code                    plant_code              -- プラントコード
        ,SOMT.orgn_name                      orgn_name               -- プラント名
        -- 生産明細 完成品以外(原料、副産物)の情報
        ,GPROD.line_no                       line_no                 -- ラインNo
        ,XPCV.prod_class_code                prod_class_code         -- 商品区分
        ,XPCV.prod_class_name                prod_class_name         -- 商品区分名
        ,XICV.item_class_code                item_class_code         -- 品目区分
        ,XICV.item_class_name                item_class_name         -- 品目区分名
        ,XCCV.crowd_code                     crowd_code              -- 群コード
        ,XIM2V.item_no                       item_no                 -- 品目コード
        ,XIM2V.item_name                     item_name               -- 品目正式名
        ,XIM2V.item_short_name               item_short_name         -- 品目略称
        ,NVL( DECODE( ILM.lot_no, 'DEFAULTLOT', '0', ILM.lot_no ), '0' )
                                             lot_no                  -- ロットNo('DEFALTLOT'、ロット未割当は'0')
        ,GPROD.manufacture_date              manufacture_date        -- 製造年月日
        ,CASE WHEN XIM2V.lot_ctl = 1 THEN ILM.attribute2          --ロット管理品   →固有記号を取得
              ELSE NULL                                           --非ロット管理品 →NULL
         END                                 uniqe_sign              -- 固有記号
        ,GPROD.expiration_date               expiration_date         -- 賞味期限日
        ,GPROD.line_type                     line_type               -- ラインタイプ
        ,FLV01.meaning                       line_type_name          -- ラインタイプ名
        ,GPROD.type                          type                    -- タイプ
        ,FLV02.meaning                       type_name               -- タイプ名
        ,GPROD.invest_ent_type               invest_ent_type         -- 投入口区分
        ,GOT.oprn_desc                       invest_ent_type_name    -- 投入口区分名
        ,GPROD.invest_type                   invest_type             -- 打込区分
        ,CASE WHEN GPROD.invest_type = 'N' THEN '投入'
              WHEN GPROD.invest_type = 'Y' THEN '打込'
         END                                 invest_type_name        -- 打込区分名
        ,GPROD.prod_date                     prod_date               -- 生産日
        ,GPROD.mtrl_in_date                  mtrl_in_date            -- 原料入庫日
        ,ROUND( GPROD.plan_qty    , 3 )      plan_qty                -- 計画数量
        ,ROUND( GPROD.wip_plan_qty, 3 )      wip_plan_qty            -- WIP計画数量
        ,ROUND( GPROD.original_qty, 3 )      original_qty            -- オリジナル数量
        ,ROUND( GPROD.actual_qty  , 3 )      actual_qty              -- 実績数量
        ,GPROD.item_um                       item_um                 -- 単位
        ,GPROD.cost_alloc                    cost_alloc              -- 原価割当
        ,GPROD.alloc_ind                     alloc_ind               -- 割当済フラグ
        ,CASE WHEN GPROD.alloc_ind = 0 THEN '未割当'
              WHEN GPROD.alloc_ind = 1 THEN '割当済'
         END                                 alloc_ind_name          -- 割当済フラグ名
        ,GPROD.rank1                         rank1                   -- ランク1
        ,GPROD.rank2                         rank2                   -- ランク2
        ,GPROD.rank3                         rank3                   -- ランク3
        ,GPROD.description                   description             -- 摘要
        ,NVL( ROUND( TO_NUMBER( GPROD.inv_qty ), 3 ), 0 )
                                             inv_qty                 -- 在庫入数
        ,NVL( ROUND( TO_NUMBER( GPROD.req_qty ), 3 ), 0 )
                                             req_qty                 -- 依頼総数
        ,GPROD.mtrl_del_flg                  mtrl_del_flg            -- 原料削除フラグ
        ,GPROD.item_loct1                    item_loct1              -- 出倉庫コード1
        ,XILV01.description                  item_loct_name1         -- 出倉庫名1
        ,GPROD.item_loct2                    item_loct2              -- 出倉庫コード2
        ,XILV02.description                  item_loct_name2         -- 出倉庫名2
        ,GPROD.item_loct3                    item_loct3              -- 出倉庫コード3
        ,XILV03.description                  item_loct_name3         -- 出倉庫名3
        ,GPROD.item_loct4                    item_loct4              -- 出倉庫コード4
        ,XILV04.description                  item_loct_name4         -- 出倉庫名4
        ,GPROD.item_loct5                    item_loct5              -- 出倉庫コード5
        ,XILV05.description                  item_loct_name5         -- 出倉庫名5
        -- ロット情報
        ,ROUND( GPROD.instructions_qty, 3 )  instructions_qty        -- ロット_指示総数
        ,ROUND( GPROD.invested_qty    , 3 )  invested_qty            -- ロット_投入数量
        ,ROUND( GPROD.return_qty      , 3 )  return_qty              -- ロット_戻入数量
        ,ROUND( GPROD.mtl_prod_qty    , 3 )  mtl_prod_qty            -- ロット_資材製造不良数
        ,ROUND( GPROD.mtl_mfg_qty     , 3 )  mtl_mfg_qty             -- ロット_資材業者不良数
        ,GPROD.lot_location                  lot_location            -- ロット_手配倉庫コード
        ,XILV06.description                  lot_loct_name           -- ロット_手配倉庫名
        ,GPROD.plan_type                     plan_type               -- ロット_予定区分
        ,FLV03.meaning                       plan_type_name          -- ロット_予定区分名
        ,GPROD.plan_number                   plan_number             -- ロット_予定番号
        -- ユーザ情報
        ,FU_CB.user_name                     created_by              -- 作成者
        ,TO_CHAR( GPROD.creation_date   , 'YYYY/MM/DD HH24:MI:SS' )
                                             creation_date           -- 作成日(支給依頼情報IF明細)
        ,FU_LU.user_name                     last_updated_by         -- 最終更新者
        ,TO_CHAR( GPROD.last_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                             last_update_date        -- 最終更新日(支給依頼情報IF明細)
        ,FU_LL.user_name                     last_update_login       -- 最終更新ログイン
FROM
        (  --========================================================================
           -- 原料のデータを抽出     ⇒ロットIDは原料詳細アドオンから取得
           --========================================================================
           SELECT  MTRL.*
             FROM  (  -- 原料詳細アドオンを外部結合＋予定区分の選択条件を満たす為、副問い合わせとする
                      SELECT
                             -- 生産バッチヘッダ
                              GBH.batch_no                  batch_no           -- バッチNo
                             ,GBH.plant_code                plant_code         -- プラントコード
                             ,GBH.batch_id                  batch_id           -- ★バッチID(打込区分名取得用)
                             ,GBH.attribute4                work_stat          -- ★業務ステータス(予定区分抽出用)
                             -- 生産明細 原料情報
                             ,GMD.line_no                   line_no            -- ラインNo
                             ,GMD.attribute17               manufacture_date   -- 製造年月日
                             ,GMD.attribute10               expiration_date    -- 賞味期限日
                             ,GMD.line_type                 line_type          -- ラインタイプ
                             ,GMD.attribute1                type               -- タイプ
                             ,GMD.attribute8                invest_ent_type    -- 投入口区分
                             ,GMD.attribute5                invest_type        -- 打込区分
                             ,GMD.attribute11               prod_date          -- 生産日
                             ,GMD.attribute22               mtrl_in_date       -- 原料入庫日
                             ,NVL( TO_NUMBER( gmd.attribute25 ), gmd.original_qty )
                                                            plan_qty           -- 計画数量(原料のみ仕様が異なる)
                             ,GMD.wip_plan_qty              wip_plan_qty       -- WIP計画数量
                             ,GMD.original_qty              original_qty       -- オリジナル数量
                             ,GMD.actual_qty                actual_qty         -- 実績数量
                             ,GMD.item_um                   item_um            -- 単位
                             ,GMD.cost_alloc                cost_alloc         -- 原価割当
                             ,GMD.alloc_ind                 alloc_ind          -- 割当済フラグ
                             ,GMD.attribute2                rank1              -- ランク1
                             ,GMD.attribute3                rank2              -- ランク2
                             ,GMD.attribute26               rank3              -- ランク3
                             ,GMD.attribute4                description        -- 摘要
                             ,GMD.attribute6                inv_qty            -- 在庫入数
                             ,GMD.attribute7                req_qty            -- 依頼総数
                             ,GMD.attribute24               mtrl_del_flg       -- 原料削除フラグ
                             ,GMD.attribute13               item_loct1         -- 出倉庫コード1
                             ,GMD.attribute18               item_loct2         -- 出倉庫コード2
                             ,GMD.attribute19               item_loct3         -- 出倉庫コード3
                             ,GMD.attribute20               item_loct4         -- 出倉庫コード4
                             ,GMD.attribute21               item_loct5         -- 出倉庫コード5
                             ,GMD.created_by                created_by         -- 作成者
                             ,GMD.creation_date             creation_date      -- 作成日
                             ,GMD.last_updated_by           last_updated_by    -- 最終更新者
                             ,GMD.last_update_date          last_update_date   -- 最終更新日
                             ,GMD.last_update_login         last_update_login  -- 最終更新ログイン
                             ,GMD.item_id                   item_id            -- ★品目ID(品目情報取得用)
                             -- ロット情報
                             ,XMD.lot_id                    lot_id             -- ★ロットID
                             ,XMD.instructions_qty          instructions_qty   -- ロット_指示総数
                             ,XMD.invested_qty              invested_qty       -- ロット_投入数量
                             ,XMD.return_qty                return_qty         -- ロット_戻入数量
                             ,XMD.mtl_prod_qty              mtl_prod_qty       -- ロット_資材製造不良数
                             ,XMD.mtl_mfg_qty               mtl_mfg_qty        -- ロット_資材業者不良数
                             ,XMD.location_code             lot_location       -- ロット_手配倉庫コード
                             ,XMD.plan_type                 plan_type          -- ロット_予定区分
                             ,XMD.plan_number               plan_number        -- ロット_予定番号
                              --名称取得用基準日
-- 2016/06/21 S.Yamashita Mod Start
--                             ,NVL( TO_DATE( GMDF.attribute11 ), GBH.plan_start_date )    --NVL( 生産日, 計画開始日 )
                             ,NVL( TO_DATE( GMDF.attribute11, 'YYYY/MM/DD' ), GBH.plan_start_date )    --NVL( 生産日, 計画開始日 )
-- 2016/06/21 S.Yamashita Mod ENd
                                                            act_date           -- 生産日 (⇒品目名称取得で使用)
                        FROM
                              gme_batch_header              GBH                -- 生産バッチ
                             ,gmd_routings_b                GRTB               -- 工順マスタ
                             ,gme_material_details          GMD                -- 生産原料詳細(原料)
                             ,xxwip_material_detail         XMD                -- 生産原料詳細アドオン
                             ,gme_material_details          GMDF               -- 生産原料詳細(完成品)
                       WHERE
                         -- ヘッダテーブルとの結合
                              GBH.batch_type   = 0
                         AND  GBH.attribute4  <> -1                            -- 業務ステータス『取消し』のデータは対象外
                         -- 工順(生産情報取得)
                         AND  GRTB.routing_class NOT IN ( '61', '62', '70' )   -- 品目振替(70)、解体(61,62) 以外
                         AND  GBH.routing_id   = GRTB.routing_id
                         -- 『原料』の明細部取得
                         AND  GMD.line_type    = '-1'                          -- 原料
                         AND  GBH.batch_id     = GMD.batch_id
                         -- 生産原料詳細アドオン情報取得
                         AND  GMD.batch_id            = XMD.batch_id(+)
                         AND  GMD.material_detail_id  = XMD.material_detail_id(+)
                         -- 『完成品』の明細部取得
                         AND  GMDF.line_type   = '1'                           -- 完成品
                         AND  GBH.batch_id     = GMDF.batch_id
                   )                                  MTRL
            WHERE
              -- 予定区分抽出の条件(業務ステータスによって取得する予定区分のレコードが異なる)
                   (      MTRL.plan_type IS NULL                                             -- 原料詳細アドオンが存在しないデータはそのまま(ロット割当無し)
                     OR ( MTRL.work_stat     IN ( '7', '8' )  AND MTRL.plan_type  = '4' )    -- 業務ステータスが実績であれば予定区分'4:実績'のデータを抽出
                     OR ( MTRL.work_stat NOT IN ( '7', '8' )  AND MTRL.plan_type <> '4' )    -- 業務ステータスが実績以外であれば予定区分'4:実績'以外のデータを抽出
                   )
         UNION ALL
           --========================================================================
           -- 副産物のデータを抽出   ⇒ロットIDは保留在庫トランザクションから取得
           --========================================================================
           SELECT
                  -- 生産バッチヘッダ
                   GBH.batch_no                batch_no           -- バッチNo
                  ,GBH.plant_code              plant_code         -- プラントコード
                  ,GBH.batch_id                batch_id           -- ★バッチID(打込区分名取得用)
                  ,GBH.attribute4              work_stat          -- ★業務ステータス(予定区分抽出用)
                  -- 生産明細 副産物情報
                  ,GMD.line_no                 line_no            -- ラインNo
                  ,GMD.attribute17             manufacture_date   -- 製造年月日
                  ,GMD.attribute10             expiration_date    -- 賞味期限日
                  ,GMD.line_type               line_type          -- ラインタイプ
                  ,GMD.attribute1              type               -- タイプ
                  ,GMD.attribute8              invest_ent_type    -- 投入口区分
                  ,GMD.attribute5              invest_type        -- 打込区分
                  ,GMD.attribute11             prod_date          -- 生産日
                  ,GMD.attribute22             mtrl_in_date       -- 原料入庫日
                  ,GMD.plan_qty                plan_qty           -- 計画数量
                  ,GMD.wip_plan_qty            wip_plan_qty       -- WIP計画数量
                  ,GMD.original_qty            original_qty       -- オリジナル数量
                  ,GMD.actual_qty              actual_qty         -- 実績数量
                  ,GMD.item_um                 item_um            -- 単位
                  ,GMD.cost_alloc              cost_alloc         -- 原価割当
                  ,GMD.alloc_ind               alloc_ind          -- 割当済フラグ
                  ,GMD.attribute2              rank1              -- ランク1
                  ,GMD.attribute3              rank2              -- ランク2
                  ,GMD.attribute26             rank3              -- ランク3
                  ,GMD.attribute4              description        -- 摘要
                  ,GMD.attribute6              inv_qty            -- 在庫入数
                  ,GMD.attribute7              req_qty            -- 依頼総数
                  ,GMD.attribute24             mtrl_del_flg       -- 原料削除フラグ
                  ,GMD.attribute13             item_loct1         -- 出倉庫コード1
                  ,GMD.attribute18             item_loct2         -- 出倉庫コード2
                  ,GMD.attribute19             item_loct3         -- 出倉庫コード3
                  ,GMD.attribute20             item_loct4         -- 出倉庫コード4
                  ,GMD.attribute21             item_loct5         -- 出倉庫コード5
                  ,GMD.created_by              created_by         -- 作成者
                  ,GMD.creation_date           creation_date      -- 作成日
                  ,GMD.last_updated_by         last_updated_by    -- 最終更新者
                  ,GMD.last_update_date        last_update_date   -- 最終更新日
                  ,GMD.last_update_login       last_update_login  -- 最終更新ログイン
                  ,GMD.item_id                 item_id            -- ★品目ID(品目情報取得用)
                   -- ロット情報
                  ,ITP.lot_id                  lot_id             -- ★ロットID
                  ,NULL                        instructions_qty   -- ロット_指示総数
                  ,NULL                        invested_qty       -- ロット_投入数量
                  ,NULL                        return_qty         -- ロット_戻入数量
                  ,NULL                        mtl_prod_qty       -- ロット_資材製造不良数
                  ,NULL                        mtl_mfg_qty        -- ロット_資材業者不良数
                  ,NULL                        lot_location       -- ロット_手配倉庫コード
                  ,NULL                        plan_type          -- ロット_予定区分
                  ,NULL                        plan_number        -- ロット_予定番号
                   --名称取得用基準日
-- 2016/06/21 S.Yamashita Mod Start
--                  ,NVL( TO_DATE( GMDF.attribute11 ), TRUNC( GBH.plan_start_date ) )    --NVL( 生産日, 計画開始日 )
                  ,NVL( TO_DATE( GMDF.attribute11, 'YYYY/MM/DD' ), TRUNC( GBH.plan_start_date ) )    --NVL( 生産日, 計画開始日 )
-- 2016/06/21 S.Yamashita Mod End
                                               act_date           -- 生産日 (⇒品目名称取得で使用)
             FROM
                   gme_batch_header            GBH                -- 生産バッチ
                  ,gmd_routings_b              GRTB               -- 工順マスタ
                  ,gme_material_details        GMD                -- 生産原料詳細(副産物)
                  ,ic_tran_pnd                 ITP                -- OPM保留在庫トランザクション
                  ,gme_material_details        GMDF               -- 生産原料詳細(完成品)
            WHERE
              -- ヘッダテーブルとの結合
                   GBH.batch_type         = 0
              AND  GBH.attribute4        <> '-1'                  -- 業務ステータス『取消し』のデータは対象外
              -- 工順(生産情報取得)
              AND  GRTB.routing_class     NOT IN ( '61', '62', '70' ) -- 品目振替(70)、解体(61,62) 以外
              AND  GBH.routing_id         = GRTB.routing_id
              -- 『副産物』の明細部取得
              AND  GBH.batch_id           = GMD.batch_id
              AND  GMD.line_type          = '2'                   -- 副産物
              -- OPM保留在庫トランザクションとの結合条件 (予定データも存在する為、COMPLETED_INDは参照しない)
              AND  ITP.doc_type(+)        = 'PROD'
              AND  ITP.delete_mark(+)     = 0                     -- 有効チェック(OPM保留在庫)
              AND  ITP.reverse_id(+)      IS NULL
              AND  ITP.lot_id(+)         <> 0                     --『資材』は有り得ない
              AND  GMD.material_detail_id = ITP.line_id(+)
              AND  GMD.item_id            = ITP.item_id(+)
              -- 『完成品』の明細部取得
              AND  GMDF.line_type         = '1'                   -- 完成品
              AND  GBH.batch_id           = GMDF.batch_id
        )                                   GPROD               -- 原料＋副産物情報
        -- 以下は上記SQL内部の項目を使用して外部結合を行うもの(エラー回避策)
        ,sy_orgn_mst_tl                     SOMT                -- △OPMプラントマスタ(WHERE句のみ)
        ,xxsky_prod_class_v                 XPCV                -- SKYLINK用中間VIEW OPM品目区分VIEW(完成品_商品区分)
        ,xxsky_item_class_v                 XICV                -- SKYLINK用中間VIEW OPM品目区分VIEW(完成品_品目区分)
        ,xxsky_crowd_code_v                 XCCV                -- SKYLINK用中間VIEW OPM品目区分VIEW(完成品_群コード)
        ,xxsky_item_mst2_v                  XIM2V               -- SKYLINK用中間VIEW OPM品目情報VIEW2(完成品_品目名)
        ,ic_lots_mst                        ILM                 -- OPMロットマスタ
        ,gmd_operations_tl                  GOT                 -- 工程マスタ
        ,gme_batch_steps                    GBS                 -- ★投入口区分名取得用
        ,fnd_lookup_values                  FLV01               -- クイックコード表(ラインタイプ名)
        ,fnd_lookup_values                  FLV02               -- クイックコード表(タイプ名)
        ,fnd_lookup_values                  FLV03               -- クイックコード表(ロット_予定区分名)
        ,xxsky_item_locations_v             XILV01              -- SKYLINK用中間VIEW OPM保管場所情報VIEW(出倉庫名1)
        ,xxsky_item_locations_v             XILV02              -- SKYLINK用中間VIEW OPM保管場所情報VIEW(出倉庫名2)
        ,xxsky_item_locations_v             XILV03              -- SKYLINK用中間VIEW OPM保管場所情報VIEW(出倉庫名3)
        ,xxsky_item_locations_v             XILV04              -- SKYLINK用中間VIEW OPM保管場所情報VIEW(出倉庫名4)
        ,xxsky_item_locations_v             XILV05              -- SKYLINK用中間VIEW OPM保管場所情報VIEW(出倉庫名5)
        ,xxsky_item_locations_v             XILV06              -- SKYLINK用中間VIEW OPM保管場所情報VIEW(ロット手配倉庫名)
        ,fnd_user                           FU_CB               -- ユーザーマスタ(CREATED_BY名称取得用)
        ,fnd_user                           FU_LU               -- ユーザーマスタ(LAST_UPDATE_BY名称取得用)
        ,fnd_user                           FU_LL               -- ユーザーマスタ(LAST_UPDATE_LOGIN名称取得用)
        ,fnd_logins                         FL_LL               -- ログインマスタ(LAST_UPDATE_LOGIN名称取得用)
WHERE
        -- プラント名
        SOMT.language(+)                    = 'JA'
   AND  GPROD.plant_code                    = SOMT.orgn_code(+)
        -- 商品区分(原料、副産物)
   AND  GPROD.item_id                       = XPCV.item_id(+)
        -- 品目区分(原料、副産物)
   AND  GPROD.item_id                       = XICV.item_id(+)
        -- 群コード(原料、副産物)
   AND  GPROD.item_id                       = XCCV.item_id(+)
        -- 品目名称(原料、副産物)
   AND  GPROD.item_id                       = XIM2V.item_id(+)
   AND  GPROD.act_date                     >= XIM2V.start_date_active(+)
   AND  GPROD.act_date                     <= XIM2V.end_date_active(+)
        -- ロット情報(原料、副産物)
   AND  GPROD.item_id                       = ILM.item_id(+)
   AND  GPROD.lot_id                        = ILM.lot_id(+)
        -- 投入口区分名
   AND  GOT.language(+)                     = 'JA'
   AND  GBS.oprn_id                         = GOT.oprn_id(+)
   AND  GPROD.batch_id                      = GBS.batch_id(+)
   AND  GPROD.invest_ent_type               = GBS.batchstep_no(+)
        -- 出倉庫名1～5
   AND  GPROD.item_loct1                    = XILV01.segment1(+)
   AND  GPROD.item_loct2                    = XILV02.segment1(+)
   AND  GPROD.item_loct3                    = XILV03.segment1(+)
   AND  GPROD.item_loct4                    = XILV04.segment1(+)
   AND  GPROD.item_loct5                    = XILV05.segment1(+)
        -- ロット手配倉庫名
   AND  GPROD.lot_location                  = XILV06.segment1(+)
        -- ユーザ名など
   AND  GPROD.created_by                    = FU_CB.user_id(+)
   AND  GPROD.last_updated_by               = FU_LU.user_id(+)
   AND  GPROD.last_update_login             = FL_LL.login_id(+)
   AND  FL_LL.user_id                       = FU_LL.user_id(+)
        -- 【クイックコード】ラインタイプ名
   AND  FLV01.language(+)                   = 'JA'
   AND  FLV01.lookup_type(+)                = 'GMD_FORMULA_ITEM_TYPE'
   AND  FLV01.lookup_code(+)                = GPROD.line_type
        -- 【クイックコード】タイプ名
   AND  FLV02.language(+)                   = 'JA'
   AND  FLV02.lookup_type(+)                = 'XXCMN_L08'
   AND  FLV02.lookup_code(+)                = GPROD.type
        -- 【クイックコード】ロット予定区分名
   AND  FLV03.language(+)                   = 'JA'
   AND  FLV03.lookup_type(+)                = 'XXWIP_PLAN_TYPE'
   AND  FLV03.lookup_code(+)                = GPROD.plan_type
/
COMMENT ON TABLE APPS.XXSKY_生産明細_基本_V IS 'SKYLINK用生産明細（基本）VIEW'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.バッチNO               IS 'バッチNo'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.プラントコード         IS 'プラントコード'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.プラント名             IS 'プラント名'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.ラインNO               IS 'ラインNo'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.商品区分               IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.商品区分名             IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.品目区分               IS '品目区分'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.品目区分名             IS '品目区分名'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.群コード               IS '群コード'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.品目コード             IS '品目コード'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.品目正式名             IS '品目正式名'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.品目略称               IS '品目略称'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.ロットNO               IS 'ロットNo'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.製造年月日             IS '製造年月日'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.固有記号               IS '固有記号'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.賞味期限日             IS '賞味期限日'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.ラインタイプ           IS 'ラインタイプ'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.ラインタイプ名         IS 'ラインタイプ名'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.タイプ                 IS 'タイプ'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.タイプ名               IS 'タイプ名'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.投入口区分             IS '投入口区分'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.投入口区分名           IS '投入口区分名'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.打込区分               IS '打込区分'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.打込区分名             IS '打込区分名'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.生産日                 IS '生産日'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.原料入庫日             IS '原料入庫日'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.計画数量               IS '計画数量'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.WIP計画数量            IS 'WIP計画数量'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.オリジナル数量         IS 'オリジナル数量'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.実績数量               IS '実績数量'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.単位                   IS '単位'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.原価割当               IS '原価割当'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.割当済フラグ           IS '割当済フラグ'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.割当済フラグ名         IS '割当済フラグ名'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.ランク１               IS 'ランク１'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.ランク２               IS 'ランク２'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.ランク３               IS 'ランク３'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.摘要                   IS '摘要'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.在庫入数               IS '在庫入数'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.依頼総数               IS '依頼総数'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.原料削除フラグ         IS '原料削除フラグ'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.出倉庫コード１         IS '出倉庫コード１'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.出倉庫名１             IS '出倉庫名１'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.出倉庫コード２         IS '出倉庫コード２'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.出倉庫名２             IS '出倉庫名２'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.出倉庫コード３         IS '出倉庫コード３'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.出倉庫名３             IS '出倉庫名３'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.出倉庫コード４         IS '出倉庫コード４'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.出倉庫名４             IS '出倉庫名４'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.出倉庫コード５         IS '出倉庫コード５'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.出倉庫名５             IS '出倉庫名５'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.ロット_指示総数        IS 'ロット_指示総数'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.ロット_投入数量        IS 'ロット_投入数量'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.ロット_戻入数量        IS 'ロット_戻入数量'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.ロット_資材製造不良数  IS 'ロット_資材製造不良数'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.ロット_資材業者不良数  IS 'ロット_資材業者不良数'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.ロット_手配倉庫コード  IS 'ロット_手配倉庫コード'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.ロット_手配倉庫名      IS 'ロット_手配倉庫名'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.ロット_予定区分        IS 'ロット_予定区分'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.ロット_予定区分名      IS 'ロット_予定区分名'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.ロット_予定番号        IS 'ロット_予定番号'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.作成者                 IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.作成日                 IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.最終更新者             IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.最終更新日             IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKY_生産明細_基本_V.最終更新ログイン       IS '最終更新ログイン'
/
