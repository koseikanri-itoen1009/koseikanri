/*************************************************************************
 * 
 * View  Name      : XXSKZ_生産原価差異_基本_V
 * Description     : XXSKZ_生産原価差異_基本_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/26    1.0   SCSK M.Nagai 初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_生産原価差異_基本_V
(
 生産日
,成績管理部署
,商品区分
,商品区分名
,品目区分
,品目区分名
,群コード
,品目
,品目名
,品目略称
,ロットNO
,製造年月日
,賞味期限
,固有記号
,出来高数量
,標準原価単価
,標準原価金額
,投入金額
,打込金額
,副産物金額
,出来高金額
,出来高単価
,単価差異
,原価差異
)
AS
SELECT  SMMR.act_date                           act_date           --生産日
       ,SMMR.pm_dept                            pm_dept            --成績管理部署
       ,PRODC.prod_class_code                   prod_class_code    --商品区分
       ,PRODC.prod_class_name                   prod_class_name    --商品区分名
       ,ITEMC.item_class_code                   item_class_code    --品目区分
       ,ITEMC.item_class_name                   item_class_name    --品目区分名
       ,CROWD.crowd_code                        crowd_code         --群コード
       ,ITEM.item_no                            item_code          --品目
       ,ITEM.item_name                          item_name          --品目名
       ,ITEM.item_short_name                    item_s_name        --品目略称
       ,NVL( DECODE( ILMF.lot_no, 'DEFAULTLOT', '0', ILMF.lot_no ), '0' )
                                                lot_no             --ロットNo('DEFALTLOT'、ロット未割当は'0')
       ,CASE WHEN ITEM.lot_ctl = 1 THEN ILMF.attribute1    --ロット管理品   →製造年月日を取得
             ELSE NULL                                     --非ロット管理品 →NULL
        END                                     lot_date           --製造年月日
       ,CASE WHEN ITEM.lot_ctl = 1 THEN ILMF.attribute3    --ロット管理品   →固有記号を取得
             ELSE NULL                                     --非ロット管理品 →NULL
        END                                     best_bfr_date      --賞味期限
       ,CASE WHEN ITEM.lot_ctl = 1 THEN ILMF.attribute2    --ロット管理品   →賞味期限を取得
             ELSE NULL                                     --非ロット管理品 →NULL
        END                                     lot_sign           --固有記号
       ,NVL( SMMR.output_qty , 0 )              output_qty         --出来高数量
       ,NVL( ICOST.cmpnt_cost, 0 )              cmpt_cost          --標準原価単価
        --標準原価金額 = ( 原価単価 × 出来高数量 )
       ,NVL( ROUND( ICOST.cmpnt_cost * SMMR.output_qty ), 0 )
                                                cmpt_amt           --標準原価金額
       ,NVL( SMMR.invest_amt , 0 )              invest_amt         --投入金額
       ,NVL( SMMR.into_amt   , 0 )              into_amt           --打込金額
       ,NVL( SMMR.product_amt, 0 )              product_amt        --副産物金額
       ,NVL( SMMR.output_amt , 0 )              output_amt         --出来高金額
        --出来高単価 = ( 出来高金額 ÷ 出来高数量 )
       ,CASE WHEN NVL( SMMR.output_qty, 0 ) = 0 THEN 0               --出来高数量がゼロなら除算しない
             ELSE                                    NVL( ROUND( SMMR.output_amt / SMMR.output_qty, 2 ), 0 )
        END                                     output_unt         --出来高単価
        --単価差異 = ( 標準原価単価 - 出来高単価 )
       ,NVL( ICOST.cmpnt_cost, 0 )
         - CASE WHEN NVL( SMMR.output_qty, 0 ) = 0 THEN 0               --出来高数量がゼロなら除算しない
                ELSE                                    NVL( ROUND( SMMR.output_amt / SMMR.output_qty, 2 ), 0 )
           END
        --原価差異 = ( 標準原価金額 - 出来高金額 )
       ,NVL( ROUND( ICOST.cmpnt_cost * SMMR.output_qty ), 0 ) - NVL( SMMR.output_amt , 0 )
  FROM  (  --生産日、部署、完成品_品目の単位で集計したデータ
           SELECT  MTRL.act_date                     act_date      --生産日
                  ,MTRL.pm_dept                      pm_dept       --成績管理部署
                  ,MTRL.cp_item_id                   cp_item_id    --完成品_品目ID
                  ,MTRL.cp_lot_id                    cp_lot_id     --完成品_ロットID
                  ,SUM( MTRL.output_qty  )           output_qty    --出来高数量
                  ,SUM( MTRL.output_amt  )           output_amt    --出来高金額（投入金額＋打込金額－副産物金額）
                  ,SUM( MTRL.invest_amt  )           invest_amt    --投入金額
                  ,SUM( MTRL.into_amt    )           into_amt      --打込金額
                  ,SUM( MTRL.product_amt )           product_amt   --副産物金額
             FROM  ( --集計対象データを『完成品』、『原料』、『副産物』別で取得
                      --================================================
                      -- 完成品データ
                      --================================================
                      SELECT  GBH.batch_no             batch_no      --バッチNo
                             ,TO_DATE( GMD.attribute11, 'YYYY/MM/DD' )
                                                       act_date     --生産日(完成品_生産日)
                             ,GBH.attribute2          pm_dept       --成績管理部署
                             ,GMD.item_id             cp_item_id    --完成品_品目ID
                             ,ITP.lot_id              cp_lot_id     --完成品_ロットID
                             ,GMD.item_id             item_id       --完成品_品目ID
                             ,ITP.lot_id              lot_id        --完成品_ロットID
                             ,ITP.trans_qty           output_qty    --出来高数量
                             ,0                        output_amt   --出来高金額（投入金額＋打込金額－副産物金額）
                             ,0                        invest_amt   --投入金額（単価×在庫数量）
                             ,0                        into_amt     --打込金額（単価×在庫数量）
                             ,0                        product_amt  --副産物金額（単価×在庫数量）
                        FROM  xxcmn_gme_batch_header_arc      GBH   --生産バッチヘッダ（標準）バックアップ
                             ,gmd_routings_b                  GRB   --工順マスタ
                             ,xxcmn_gme_material_details_arc  GMD   --生産原料詳細（標準）バックアップ
                             ,xxcmn_ic_tran_pnd_arc           ITP   --OPM保留在庫トランザクション（標準）バックアップ
                       WHERE  GBH.batch_type           = 0
                         AND  GBH.attribute4          <> '-1'       --業務ステータス『取消し』のデータは対象外
                         --工順番号の取得と生産データ抽出の為の付加条件
                         AND  GRB.routing_class        NOT IN ( '61', '62', '70' )  --品目振替(70)、解体(61,62) 以外
                         AND  GBH.routing_id           = GRB.routing_id
                         --原料詳細データ『完成品』との結合
                         AND  GMD.line_type            = '1'         --【完成品】
                         AND  GBH.batch_id             = GMD.batch_id
                         --完成品ロットID取得の為、保留在庫トランザクションとの結合
                         AND  ITP.trans_qty           <> 0
                         AND  ITP.doc_type             = 'PROD'
                         AND  ITP.delete_mark          = 0
                         AND  ITP.completed_ind        = 1           --完了(⇒実績)
                         AND  ITP.reverse_id           IS NULL
                         AND  ITP.lot_id              <> 0           --『資材』は有り得ない
                         AND  GMD.material_detail_id   = ITP.line_id
                         AND  GMD.item_id              = ITP.item_id
                      -- [ 完成品データ END ] --
                    UNION ALL
                      --================================================
                      -- 原料データ
                      --================================================
                      SELECT  SGMD.batch_no            batch_no      --バッチNo
                             ,SGMD.act_date            act_date      --生産日(完成品_生産日)
                             ,SGMD.pm_dept             pm_dept       --成績管理部署
                             ,SGMD.cp_item_id          cp_item_id    --完成品_品目ID
                             ,SGMD.cp_lot_id           cp_lot_id     --完成品_ロットID
                             ,SGMD.item_id             item_id       --原料_品目ID
                             ,SGMD.lot_id              lot_id        --原料_ロットID
                             ,0                        output_qty    --出来高数量
                              --出来高金額（投入金額＋打込金額－副産物金額）
                             ,ROUND( DECODE( IIM.attribute15, '0', SGMD.inv_amt      --原価管理区分が0:実勢なら在庫単価
                                                            , '1', XPH.total_amount  --原価管理区分が1:標準なら標準単価
                                                                 , 0 )
                                                       * SGMD.quantity )
                                                       output_amt    --出来高金額（投入金額＋打込金額－副産物金額）
                              --投入金額
                             ,CASE WHEN invest_type <> 'Y' THEN                --投入･打込区分『投入』
                                ROUND( DECODE( IIM.attribute15, '0', SGMD.inv_amt      --原価管理区分が0:実勢なら在庫単価
                                                              , '1', XPH.total_amount  --原価管理区分が1:標準なら標準単価
                                                                   , 0 )
                                                       * SGMD.quantity )
                              END                      invest_amt    --投入金額（単価×在庫数量）
                              --打込金額
                             ,CASE WHEN invest_type  = 'Y' THEN                --投入･打込区分『打込』
                                ROUND( DECODE( IIM.attribute15, '0', SGMD.inv_amt      --原価管理区分が0:実勢なら在庫単価
                                                              , '1', XPH.total_amount  --原価管理区分が1:標準なら標準単価
                                                                   , 0 )
                                                       * SGMD.quantity )
                              END                      into_amt      --打込金額（単価×在庫数量）
                             ,0                        product_amt   --副産物金額（単価×在庫数量）
                        FROM  (  --標準単価マスタとの外部結合の為、副問い合わせとする
                                 SELECT  GBH.batch_no                    batch_no        --バッチNo
                                        ,GBH.attribute2                  pm_dept         --成績管理部署
                                        ,TO_DATE( GMDF.attribute11, 'YYYY/MM/DD' )
                                                                         act_date        --完成品_生産日
                                        ,GMDF.item_id                    cp_item_id      --完成品_品目ID
                                        ,ITPF.lot_id                     cp_lot_id       --完成品_ロットID
                                        ,GMD.item_id                     item_id         --原料_品目ID
                                        ,XMD.lot_id                      lot_id          --原料_ロットID
                                        ,NVL( GMD.attribute5, 'N' )      invest_type     --投入･打込区分
                                        ,XMD.invested_qty - XMD.return_qty
                                                                         quantity        --数量
                                        ,TO_NUMBER( ILM.attribute7 )     inv_amt         --在庫単価
                                   FROM  xxcmn_gme_batch_header_arc      GBH             --生産バッチヘッダ（標準）バックアップ
                                        ,gmd_routings_b                  GRB             --工順マスタ
                                        ,xxcmn_gme_material_details_arc  GMD             --生産原料詳細（標準）バックアップ
                                        ,xxcmn_material_detail_arc       XMD             --生産原料詳細（アドオン）バックアップ
                                        ,ic_lots_mst                     ILM             --OPMロットマスタ
                                        ,xxskz_item_class_v              ITEMC           --品目区分取得用
                                        ,xxcmn_gme_material_details_arc  GMDF            --生産原料詳細（標準）バックアップ(完成品情報取得用)
                                        ,xxcmn_ic_tran_pnd_arc           ITPF            --OPM保留在庫トランザクション（標準）バックアップ(完成品情報取得用)
                                  WHERE  GBH.batch_type              = 0
                                    AND  GBH.attribute4             <> '-1'          --業務ステータス『取消し』のデータは対象外
                                    --工順番号の取得と生産データ抽出の為の付加条件
                                    AND  GRB.routing_class           NOT IN ( '61', '62', '70' )  --品目振替(70)、解体(61,62) 以外
                                    AND  GBH.routing_id              = GRB.routing_id
                                    --原料詳細データ『原料』との結合
                                    AND  GMD.line_type               = '-1'          --【原料】
                                    AND  GBH.batch_id                = GMD.batch_id
                                    --『資材』は除外する
                                    AND  GMD.item_id                 = ITEMC.item_id
                                    AND  ITEMC.item_class_code      <> '2'           --『資材』以外
                                    --原料詳細アドオンとの結合
                                    AND  XMD.plan_type               = '4'           --実績
                                    AND  (    XMD.invested_qty      <> 0
                                           OR XMD.return_qty        <> 0
                                         )
                                    AND  GMD.batch_id                = XMD.batch_id
                                    AND  GMD.material_detail_id      = XMD.material_detail_id
                                    --ロットマスタとの結合
                                    AND  XMD.item_id                 = ILM.item_id
                                    AND  XMD.lot_id                  = ILM.lot_id
                                    --完成品データとの結合
                                    AND  GMDF.line_type              = '1'           --【完成品】
                                    AND  GBH.batch_id                = GMDF.batch_id
                                    --完成品ロットID取得の為、保留在庫トランザクションとの結合
                                    AND  ITPF.doc_type               = 'PROD'
                                    AND  ITPF.delete_mark            = 0
                                    AND  ITPF.completed_ind          = 1             --完了(⇒実績)
                                    AND  ITPF.reverse_id             IS NULL
                                    AND  ITPF.lot_id                <> 0             --『資材』は有り得ない
                                    AND  GMDF.material_detail_id     = ITPF.line_id
                                    AND  GMDF.item_id                = ITPF.item_id
                              )                        SGMD          --完成品データ
                             ,ic_item_mst_b            IIM           --OPM品目マスタ
                             ,xxpo_price_headers       XPH           --仕入/標準単価マスタ
                       WHERE
                         --OPM品目マスタとの結合
                              SGMD.item_id             = IIM.item_id
                         --標準単価マスタとの結合
                         AND  XPH.price_type(+)        = '2'         --標準
                         AND  SGMD.item_id             = XPH.item_id(+)
                         AND  SGMD.act_date           >= XPH.start_date_active(+)
                         AND  SGMD.act_date           <= XPH.end_date_active(+)
                      -- [ 原料データ END ] --
                    UNION ALL
                      --================================================
                      -- 副産物データ
                      --================================================
                      SELECT  SGMD.batch_no            batch_no      --バッチNo
                             ,SGMD.act_date            act_date      --生産日(完成品_生産日)
                             ,SGMD.pm_dept             pm_dept       --成績管理部署
                             ,SGMD.cp_item_id          cp_item_id    --完成品_品目ID
                             ,SGMD.cp_lot_id           cp_lot_id     --完成品_ロットID
                             ,SGMD.item_id             item_id       --副産物_品目ID
                             ,SGMD.lot_id              lot_id        --副産物_ロットID
                             ,0                        output_qty    --出来高数量
                              --出来高金額（投入金額＋打込金額－副産物金額）
                             ,ROUND( DECODE( IIM.attribute15, '0', SGMD.inv_amt      --原価管理区分が0:実勢なら在庫単価
                                                            , '1', XPH.total_amount  --原価管理区分が1:標準なら標準単価
                                                                 , 0 )
                                                       * SGMD.quantity * -1 )
                                                       output_amt    --出来高金額（投入金額＋打込金額－副産物金額）
                             ,0                        invest_amt    --投入金額（単価×在庫数量）
                             ,0                        into_amt      --打込金額（単価×在庫数量）
                              --副産物金額
                             ,ROUND( DECODE( IIM.attribute15, '0', SGMD.inv_amt      --原価管理区分が0:実勢なら在庫単価
                                                            , '1', XPH.total_amount  --原価管理区分が1:標準なら標準単価
                                                                 , 0 )
                                                       * SGMD.quantity )
                                                       product_amt   --副産物金額（単価×在庫数量）
                        FROM  (  --標準単価マスタとの外部結合の為、副問い合わせとする
                                 SELECT  GBH.batch_no                    batch_no        --バッチNo
                                        ,GBH.attribute2                  pm_dept         --成績管理部署
                                        ,TO_DATE( GMDF.attribute11, 'YYYY/MM/DD' )
                                                                         act_date        --完成品_生産日
                                        ,GMDF.item_id                    cp_item_id      --完成品_品目ID
                                        ,ITPF.lot_id                     cp_lot_id       --完成品_ロットID
                                        ,GMD.item_id                     item_id         --副産物_品目ID
                                        ,ITP.lot_id                      lot_id          --副産物_ロットID
                                        ,ITP.trans_qty                   quantity        --数量
                                        ,TO_NUMBER( ILM.attribute7 )     inv_amt         --在庫単価
                                   FROM  xxcmn_gme_batch_header_arc      GBH             --生産バッチヘッダ（標準）バックアップ
                                        ,gmd_routings_b                  GRB             --工順マスタ
                                        ,xxcmn_gme_material_details_arc  GMD             --生産原料詳細（標準）バックアップ
                                        ,xxcmn_ic_tran_pnd_arc           ITP             --OPM保留在庫トランザクション（標準）バックアップ
                                        ,ic_lots_mst                     ILM             --OPMロットマスタ
                                        ,xxcmn_gme_material_details_arc  GMDF            --生産原料詳細（標準）バックアップ(完成品情報取得用)
                                        ,xxcmn_ic_tran_pnd_arc           ITPF            --OPM保留在庫トランザクション（標準）バックアップ(完成品情報取得用)
                                  WHERE  GBH.batch_type              = 0
                                    AND  GBH.attribute4             <> '-1'          --業務ステータス『取消し』のデータは対象外
                                    --工順番号の取得と生産データ抽出の為の付加条件
                                    AND  GRB.routing_class           NOT IN ( '61', '62', '70' )  --品目振替(70)、解体(61,62) 以外
                                    AND  GBH.routing_id              = GRB.routing_id
                                    --原料詳細データ『副産物』との結合
                                    AND  GMD.line_type               = '2'           --【副産物】
                                    AND  GBH.batch_id                = GMD.batch_id
                                    --保留在庫トランザクションとの結合
                                    AND  ITP.trans_qty              <> 0
                                    AND  ITP.doc_type                = 'PROD'
                                    AND  ITP.delete_mark             = 0
                                    AND  ITP.completed_ind           = 1             --完了(⇒実績)
                                    AND  ITP.reverse_id              IS NULL
                                    AND  ITP.lot_id                 <> 0             --『資材』は有り得ない
                                    AND  GMD.material_detail_id      = ITP.line_id
                                    AND  GMD.item_id                 = ITP.item_id
                                    --ロットマスタとの結合
                                    AND  ITP.item_id                 = ILM.item_id
                                    AND  ITP.lot_id                  = ILM.lot_id
                                    --完成品データとの結合
                                    AND  GMDF.line_type              = '1'           --【完成品】
                                    AND  GBH.batch_id                = GMDF.batch_id
                                    --完成品ロットID取得の為、保留在庫トランザクションとの結合
                                    AND  ITPF.doc_type               = 'PROD'
                                    AND  ITPF.delete_mark            = 0
                                    AND  ITPF.completed_ind          = 1             --完了(⇒実績)
                                    AND  ITPF.reverse_id             IS NULL
                                    AND  ITPF.lot_id                <> 0             --『資材』は有り得ない
                                    AND  GMDF.batch_id               = ITPF.doc_id
                                    AND  GMDF.material_detail_id     = ITPF.line_id
                                    AND  GMDF.item_id                = ITPF.item_id
                              )                        SGMD          --完成品データ
                             ,ic_item_mst_b            IIM           --OPM品目マスタ
                             ,xxpo_price_headers       XPH           --仕入/標準単価マスタ
                       WHERE
                         --OPM品目マスタとの結合
                              SGMD.item_id             = IIM.item_id
                         --標準単価マスタとの結合
                         AND  XPH.price_type(+)        = '2'         --標準
                         AND  SGMD.item_id             = XPH.item_id(+)
                         AND  SGMD.act_date           >= XPH.start_date_active(+)
                         AND  SGMD.act_date           <= XPH.end_date_active(+)
                   )            MTRL
           GROUP BY MTRL.act_date           --生産日
                   ,MTRL.pm_dept            --成績管理部署
                   ,MTRL.cp_item_id         --完成品_品目ID
                   ,MTRL.cp_lot_id          --完成品_ロットID
        )  SMMR                             --生産集計情報
       ,(  --品目別標準原価情報(原料のみ)取得
           SELECT  CCD.item_id              --品目ID
                  ,CCDL.start_date          --適用開始年月日
                  ,CCDL.end_date            --適用終了年月日
                  ,CCD.cmpnt_cost           --原価値
             FROM  cm_cmpt_dtl      CCD
                  ,cm_cmpt_mst_b    CCMB
                  ,cm_cldr_dtl      CCDL
            WHERE  CCD.whse_code           = '000'
              AND  CCD.cost_mthd_code      = 'STDU'
              AND  CCD.cost_analysis_code  = '0000'
              AND  CCD.cost_level          = 0
              AND  CCMB.cost_cmpntcls_code = '01GEN'    --原料費
              AND  CCD.cost_cmpntcls_id    = CCMB.cost_cmpntcls_id
              AND  CCD.calendar_code       = CCDL.calendar_code
              AND  CCD.period_code         = CCDL.period_code
        )                       ICOST       --品目別原料原価
       ,ic_lots_mst             ILMF        --OPMロットマスタ(完成品品目のロット情報＆在庫単価取得用)
       ,xxpo_price_headers      XPH         --仕入/標準単価マスタ(完成品品目の標準単価取得用)
       ,xxskz_item_mst2_v       ITEM        --品目名取得用
       ,xxskz_prod_class_v      PRODC       --商品区分取得用
       ,xxskz_item_class_v      ITEMC       --品目区分取得用
       ,xxskz_crowd_code_v      CROWD       --群コード取得用
 WHERE
   --完成品品目のロット情報＆在庫単価取得
        SMMR.cp_item_id    = ILMF.item_id
   AND  SMMR.cp_lot_id     = ILMF.lot_id
   --標準単価マスタとの結合
   AND  XPH.price_type(+)  = '2'            --標準
   AND  SMMR.cp_item_id    = XPH.item_id(+)
   AND  SMMR.act_date     >= XPH.start_date_active(+)
   AND  SMMR.act_date     <= XPH.end_date_active(+)
   --完成品品目の原価単価(原料のみ)取得
   AND  SMMR.cp_item_id    = ICOST.item_id(+)
   AND  SMMR.act_date     >= ICOST.start_date(+)
   AND  SMMR.act_date     <= ICOST.end_date(+)
   --品目名(完成品)取得
   AND  SMMR.cp_item_id    = ITEM.item_id(+)
   AND  SMMR.act_date     >= ITEM.start_date_active(+)
   AND  SMMR.act_date     <= ITEM.end_date_active(+)
   --品目カテゴリ名(完成品)取得
   AND  ITEM.item_id       = PRODC.item_id(+)
   AND  ITEM.item_id       = ITEMC.item_id(+)
   AND  ITEM.item_id       = CROWD.item_id(+)
/
COMMENT ON TABLE APPS.XXSKZ_生産原価差異_基本_V IS 'SKYLINK用 生産原価差異（基本）VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_生産原価差異_基本_V.生産日       IS '生産日'
/
COMMENT ON COLUMN APPS.XXSKZ_生産原価差異_基本_V.成績管理部署 IS '成績管理部署'
/
COMMENT ON COLUMN APPS.XXSKZ_生産原価差異_基本_V.商品区分     IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKZ_生産原価差異_基本_V.商品区分名   IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_生産原価差異_基本_V.品目区分     IS '品目区分'
/
COMMENT ON COLUMN APPS.XXSKZ_生産原価差異_基本_V.品目区分名   IS '品目区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_生産原価差異_基本_V.群コード     IS '群コード'
/
COMMENT ON COLUMN APPS.XXSKZ_生産原価差異_基本_V.品目         IS '品目'
/
COMMENT ON COLUMN APPS.XXSKZ_生産原価差異_基本_V.品目名       IS '品目名'
/
COMMENT ON COLUMN APPS.XXSKZ_生産原価差異_基本_V.品目略称     IS '品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_生産原価差異_基本_V.ロットNO     IS 'ロットNo'
/
COMMENT ON COLUMN APPS.XXSKZ_生産原価差異_基本_V.製造年月日   IS '製造年月日'
/
COMMENT ON COLUMN APPS.XXSKZ_生産原価差異_基本_V.賞味期限     IS '賞味期限'
/
COMMENT ON COLUMN APPS.XXSKZ_生産原価差異_基本_V.固有記号     IS '固有記号'
/
COMMENT ON COLUMN APPS.XXSKZ_生産原価差異_基本_V.出来高数量   IS '出来高数量'
/
COMMENT ON COLUMN APPS.XXSKZ_生産原価差異_基本_V.標準原価単価 IS '標準原価単価'
/
COMMENT ON COLUMN APPS.XXSKZ_生産原価差異_基本_V.標準原価金額 IS '標準原価金額'
/
COMMENT ON COLUMN APPS.XXSKZ_生産原価差異_基本_V.投入金額     IS '投入金額'
/
COMMENT ON COLUMN APPS.XXSKZ_生産原価差異_基本_V.打込金額     IS '打込金額'
/
COMMENT ON COLUMN APPS.XXSKZ_生産原価差異_基本_V.副産物金額   IS '副産物金額'
/
COMMENT ON COLUMN APPS.XXSKZ_生産原価差異_基本_V.出来高金額   IS '出来高金額'
/
COMMENT ON COLUMN APPS.XXSKZ_生産原価差異_基本_V.出来高単価   IS '出来高単価'
/
COMMENT ON COLUMN APPS.XXSKZ_生産原価差異_基本_V.単価差異     IS '単価差異'
/
COMMENT ON COLUMN APPS.XXSKZ_生産原価差異_基本_V.原価差異     IS '原価差異'
/
