/*************************************************************************
 * 
 * View  Name      : XXSKZ_品目振替情報_基本_V
 * Description     : XXSKZ_品目振替情報_基本_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/26    1.0   SCSK M.Nagai 初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_品目振替情報_基本_V
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
,品目振替名称
,品目振替摘要
,品目振替目的
,品目振替目的名
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
,払出_商品区分
,払出_商品区分名
,払出_品目区分
,払出_品目区分名
,払出_群コード
,払出_品目コード
,払出_品目正式名
,払出_品目略称
,払出_ロットNO
,払出_製造年月日
,払出_固有記号
,払出_賞味期限日
,払出_計画数量
,払出_WIP計画数量
,払出_オリジナル数量
,払出_実績数量
,払出_単位
,払出_原価割当
,払出_割当済フラグ
,払出_割当済フラグ名
,受入_商品区分
,受入_商品区分名
,受入_品目区分
,受入_品目区分名
,受入_群コード
,受入_品目コード
,受入_品目正式名
,受入_品目略称
,受入_ロットNO
,受入_製造年月日
,受入_固有記号
,受入_賞味期限日
,受入_計画数量
,受入_WIP計画数量
,受入_オリジナル数量
,受入_実績数量
,受入_単位
,受入_原価割当
,受入_割当済フラグ
,受入_割当済フラグ名
,作成者
,作成日
,最終更新者
,最終更新日
,最終更新ログイン
)
AS
SELECT 
        -- 共通項目
        GBHM.batch_no                             batch_no                 --バッチNo
       ,GBHM.plant_code                           plant_code               --プラントコード
       ,SOMT.orgn_name                            orgn_name                --プラント名
       ,GRPB.recipe_no                            recipe_no                --レシピ
       ,GRPT.recipe_description                   recipe_name              --レシピ名称
       ,GRPT.recipe_description                   recipe_description       --レシピ摘要
       ,FFMB.formula_no                           formula_no               --フォーミュラ
       ,FFMT.formula_desc1                        formula_neme1            --フォーミュラ名称
       ,FFMT.formula_desc2                        formula_name2            --フォーミュラ名称２
       ,FFMT.formula_desc1                        formula_desc1            --フォーミュラ摘要
       ,FFMT.formula_desc2                        formula_desc2            --フォーミュラ摘要２
       ,GBHM.routing_no                           routing_no               --工順
       ,GRTT.routing_desc                         routing_name             --工順名称
       ,GRTT.routing_desc                         routing_desc             --工順摘要
       ,GBHM.attribute6                           transfer_name            --品目振替名称
       ,GBHM.attribute6                           attribute6               --品目振替摘要
       ,GBHM.attribute7                           attribute7               --品目振替目的
       ,FLV01.meaning                             attribute7_name          --品目振替目的名
       ,GBHM.plan_start_date                      plan_start_date          --計画開始日
       ,GBHM.actual_start_date                    actual_start_date        --実績開始日
       ,GBHM.due_date                             due_date                 --必須完了日
       ,GBHM.plan_cmplt_date                      plan_cmplt_date          --計画完了日
       ,GBHM.actual_cmplt_date                    actual_cmplt_date        --実績完了日
       ,GBHM.batch_status                         batch_status             --バッチステータス
       ,FLV02.meaning                             batch_status_name        --バッチステータス名
       ,GBHM.wip_whse_code                        wip_whse_code            --WIP倉庫
       ,IWM.whse_name                             wip_whse_name            --WIP倉庫名
       ,GBHM.batch_close_date                     batch_close_date         --クローズ日
       ,GBHM.delete_mark                          delete_mark              --削除マーク
        --
        -- 【振替後 明細情報】
       ,XPCV_AFT.prod_class_code                  aft_prod_class_code      --払出_商品区分
       ,XPCV_AFT.prod_class_name                  aft_prod_class_name      --払出_商品区分名
       ,XICV_AFT.item_class_code                  aft_item_class_code      --払出_品目区分
       ,XICV_AFT.item_class_name                  aft_item_class_name      --払出_品目区分名
       ,XCCV_AFT.crowd_code                       aft_crowd_code           --払出_群コード
       ,XIM2V_AFT.item_no                         aft_item_no              --払出_品目コード
       ,XIM2V_AFT.item_name                       aft_item_name            --払出_品目正式名
       ,XIM2V_AFT.item_short_name                 aft_item_short_name      --払出_品目略称
       ,NVL( DECODE( ILM_AFT.lot_no, 'DEFAULTLOT', '0', ILM_AFT.lot_no ), '0' )
                                                  aft_lot_no               --払出_ロットNo('DEFALTLOT'、ロット未割当は'0')
       ,CASE WHEN XIM2V_AFT.lot_ctl = 1 THEN ILM_AFT.attribute1        --ロット管理品   →製造年月日を取得
             ELSE NULL                                                 --非ロット管理品 →NULL
        END                                       aft_manufacture_date     --払出_製造年月日
       ,CASE WHEN XIM2V_AFT.lot_ctl = 1 THEN ILM_AFT.attribute2        --ロット管理品   →固有記号を取得
             ELSE NULL                                                 --非ロット管理品 →NULL
        END                                       aft_uniqe_sign           --払出_固有記号
       ,CASE WHEN XIM2V_AFT.lot_ctl = 1 THEN ILM_AFT.attribute3        --ロット管理品   →賞味期限日を取得
             ELSE NULL                                                 --非ロット管理品 →NULL
        END                                       aft_expiration_date      --払出_賞味期限日
       ,ROUND( GBHM.aft_plan_qty    , 3 )         aft_plan_qty             --払出_計画数量
       ,ROUND( GBHM.aft_wip_plan_qty, 3 )         aft_wip_plan_qty         --払出_WIP計画数量
       ,ROUND( GBHM.aft_original_qty, 3 )         aft_original_qty         --払出_オリジナル数量
       ,ROUND( GBHM.aft_actual_qty  , 3 )         aft_actual_qty           --払出_実績数量
       ,GBHM.aft_item_um                          aft_item_um              --払出_単位
       ,GBHM.aft_cost_alloc                       aft_cost_alloc           --払出_原価割当
       ,GBHM.aft_alloc_ind                        aft_alloc_ind            --払出_割当済フラグ
       ,CASE WHEN GBHM.aft_alloc_ind = 0 THEN '未割当'
             WHEN GBHM.aft_alloc_ind = 1 THEN '割当済'
        END                                       aft_alloc_name           --払出_割当済フラグ名
        --
        -- 【振替前 明細情報】
       ,XPCV_BEF.prod_class_code                  bef_prod_class_code      --受入_商品区分
       ,XPCV_BEF.prod_class_name                  bef_prod_class_name      --受入_商品区分名
       ,XICV_BEF.item_class_code                  bef_item_class_code      --受入_品目区分
       ,XICV_BEF.item_class_name                  bef_item_class_name      --受入_品目区分名
       ,XCCV_BEF.crowd_code                       bef_crowd_code           --受入_群コード
       ,XIM2V_BEF.item_no                         bef_item_no              --受入_品目コード
       ,XIM2V_BEF.item_name                       bef_item_name            --受入_品目正式名
       ,XIM2V_BEF.item_short_name                 bef_item_short_name      --受入_品目略称
       ,NVL( DECODE( ILM_BEF.lot_no, 'DEFAULTLOT', '0', ILM_BEF.lot_no ), '0' )
                                                  bef_lot_no               --受入_ロットNo(DEFALTLOT、ロット未割当は'0')
       ,CASE WHEN XIM2V_BEF.lot_ctl = 1 THEN ILM_BEF.attribute1        --ロット管理品   →製造年月日を取得
             ELSE NULL                                                 --非ロット管理品 →NULL
        END                                       bef_manufacture_date     --受入_製造年月日
       ,CASE WHEN XIM2V_BEF.lot_ctl = 1 THEN ILM_BEF.attribute2        --ロット管理品   →固有記号を取得
             ELSE NULL                                                 --非ロット管理品 →NULL
        END                                       bef_uniqe_sign           --受入_固有記号
       ,CASE WHEN XIM2V_BEF.lot_ctl = 1 THEN ILM_BEF.attribute3        --ロット管理品   →賞味期限日を取得
             ELSE NULL                                                 --非ロット管理品 →NULL
        END                                       bef_expiration_date      --受入_賞味期限日
       ,ROUND( GBHM.bef_plan_qty    , 3 )         bef_plan_qty             --受入_計画数量
       ,ROUND( GBHM.bef_wip_plan_qty, 3 )         bef_wip_plan_qty         --受入_WIP計画数量
       ,ROUND( GBHM.bef_original_qty, 3 )         bef_original_qty         --受入_オリジナル数量
       ,ROUND( GBHM.bef_actual_qty  , 3 )         bef_actual_qty           --受入_実績数量
       ,GBHM.bef_item_um                          bef_item_um              --受入_単位
       ,GBHM.bef_cost_alloc                       bef_cost_alloc           --受入_原価割当
       ,GBHM.bef_alloc_ind                        bef_alloc_ind            --受入_割当済フラグ
       ,CASE WHEN GBHM.bef_alloc_ind = 0 THEN '未割当'
             WHEN GBHM.bef_alloc_ind = 1 THEN '割当済'
        END                                       bef_alloc_name           --払出_割当済フラグ名
        --
        -- ユーザ情報など
       ,FU_CB.user_name                           created_by_name          --CREATED_BYのユーザー名(ログイン時の入力コード)
       ,TO_CHAR( GBHM.creation_date, 'YYYY/MM/DD HH24:MI:SS' )
                                                  creation_date            --作成日時
       ,FU_LU.user_name                           last_updated_by_name     --LAST_UPDATED_BYのユーザー名(ログイン時の入力コード)
       ,TO_CHAR( GBHM.last_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                                  last_update_date         --更新日時
       ,FU_LL.user_name                           last_update_login_name   --LAST_UPDATE_LOGINのユーザー名(ログイン時の入力コード)
  FROM  (
        SELECT
               -- 共通項目
                GBH.batch_no                      batch_no                 --バッチNo
               ,GBH.plant_code                    plant_code               --プラントコード
               ,GBH.recipe_validity_rule_id       recipe_validity_rule_id  --レシピ取得用
               ,GBH.formula_id                    formula_id               --フォーミュラ取得用
               ,GRB.routing_id                    routing_id               --工順名取得用
               ,GRB.routing_no                    routing_no               --工順
               ,GBH.attribute6                    attribute6               --品目振替摘要
               ,GBH.attribute7                    attribute7               --品目振替目的
               ,GBH.plan_start_date               plan_start_date          --計画開始日
               ,GBH.actual_start_date             actual_start_date        --実績開始日
               ,GBH.due_date                      due_date                 --必須完了日
               ,GBH.plan_cmplt_date               plan_cmplt_date          --計画完了日
               ,GBH.actual_cmplt_date             actual_cmplt_date        --実績完了日
               ,GBH.batch_status                  batch_status             --バッチステータス
               ,GBH.wip_whse_code                 wip_whse_code            --WIP倉庫
               ,GBH.batch_close_date              batch_close_date         --クローズ日
               ,GBH.delete_mark                   delete_mark              --削除マーク
                --
                -- 【振替後 明細情報】
               ,GMD_AFT.item_id                   aft_item_id              --払出_品目ID
               ,ITP_AFT.lot_id                    aft_lot_id               --払出_ロットID
               ,GMD_AFT.plan_qty                  aft_plan_qty             --払出_計画数量
               ,GMD_AFT.wip_plan_qty              aft_wip_plan_qty         --払出_WIP計画数量
               ,GMD_AFT.original_qty              aft_original_qty         --払出_オリジナル数量
               ,GMD_AFT.actual_qty                aft_actual_qty           --払出_実績数量
               ,GMD_AFT.item_um                   aft_item_um              --払出_単位
               ,GMD_AFT.cost_alloc                aft_cost_alloc           --払出_原価割当
               ,GMD_AFT.alloc_ind                 aft_alloc_ind            --払出_割当済フラグ
                --
                -- 【振替前 明細情報】
               ,GMD_BEF.item_id                   bef_item_id              --受入_品目ID
               ,ITP_BEF.lot_id                    bef_lot_id               --受入_ロットID
               ,GMD_BEF.plan_qty                  bef_plan_qty             --受入_計画数量
               ,GMD_BEF.wip_plan_qty              bef_wip_plan_qty         --受入_WIP計画数量
               ,GMD_BEF.original_qty              bef_original_qty         --受入_オリジナル数量
               ,GMD_BEF.actual_qty                bef_actual_qty           --受入_実績数量
               ,GMD_BEF.item_um                   bef_item_um              --受入_単位
               ,GMD_BEF.cost_alloc                bef_cost_alloc           --受入_原価割当
               ,GMD_BEF.alloc_ind                 bef_alloc_ind            --受入_割当済フラグ
                --
                -- ユーザ情報など
               ,GMD_AFT.created_by                created_by               --CREATED_BY
               ,GMD_AFT.creation_date             creation_date            --作成日時
               ,GMD_AFT.last_updated_by           last_updated_by          --LAST_UPDATED_BY
               ,GMD_AFT.last_update_date          last_update_date         --更新日時
               ,GMD_AFT.last_update_login         last_update_login        --LAST_UPDATE_LOGIN
                --名称取得用基準日
               ,NVL( TRUNC( GBH.actual_cmplt_date ), TRUNC( GBH.plan_start_date ) )    --NVL( 実績完了日, 計画開始日 )
                                                  act_date                 --実施日 (⇒品目名称取得で使用)
        FROM
                xxcmn_gme_batch_header_arc             GBH                          --生産バッチヘッダ（標準）バックアップ
               ,gmd_routings_b                         GRB                          --品目振替情報取得条件用
                --【振替後情報取得用】
               ,xxcmn_gme_material_details_arc         GMD_AFT                      --生産原料詳細（標準）バックアップ
               ,xxcmn_ic_tran_pnd_arc                  ITP_AFT                      --OPM保留在庫トランザクション（標準）バックアップ
                --【振替前情報取得用】
               ,xxcmn_gme_material_details_arc         GMD_BEF                      --生産原料詳細（標準）バックアップ
               ,xxcmn_ic_tran_pnd_arc                  ITP_BEF                      --OPM保留在庫トランザクション（標準）バックアップ
        WHERE
                GBH.batch_type               =  0
          --品目振替情報取得条件
          AND   GRB.routing_class            =  '70'                       --'品目振替'
          AND   GBH.routing_id               =  GRB.routing_id
          --
          --【振替後情報取得】
          --振替後明細取得条件
          AND   GBH.batch_id                 =  GMD_AFT.batch_id
          AND   GMD_AFT.line_type            =  '-1'
          --振替後ロットID取得条件 (予定データも存在する為、COMPLETED_INDは参照しない)
          AND   ITP_AFT.doc_type             = 'PROD'
          AND   ITP_AFT.delete_mark          =  0
          AND   ITP_AFT.lot_id              <>  0                          --資材はあり得ない
          AND   ITP_AFT.reverse_id           IS NULL
          AND   GMD_AFT.material_detail_id   =  ITP_AFT.line_id
          AND   GMD_AFT.item_id              =  ITP_AFT.item_id
          --
          --【振替後情報取得】
          --振替前明細取得条件
          AND   GBH.batch_id                 =  GMD_BEF.batch_id
          AND   GMD_BEF.line_type(+)         =  '1'
          --振替前ロットID取得条件 (予定データも存在する為、COMPLETED_INDは参照しない)
          AND   ITP_BEF.doc_type             = 'PROD'
          AND   ITP_BEF.delete_mark          =  0
          AND   ITP_BEF.lot_id              <>  0                          --資材はあり得ない
          AND   ITP_BEF.reverse_id           IS NULL
          AND   GMD_BEF.material_detail_id   =  ITP_BEF.line_id
          AND   GMD_BEF.item_id              =  ITP_BEF.item_id
        )                               GBHM                        --品目振替情報　ヘッダ・明細(振替前後)
       ,sy_orgn_mst_tl                  SOMT                        --プラント名取得用
       ,gmd_recipe_validity_rules       GRPVR                       --レシピ取得用
       ,gmd_recipes_b                   GRPB                        --レシピ取得用
       ,gmd_recipes_tl                  GRPT                        --レシピ摘要取得用
       ,fm_form_mst_b                   FFMB                        --フォーミュラ取得用
       ,fm_form_mst_tl                  FFMT                        --フォーミュラ摘要取得用
       ,gmd_routings_tl                 GRTT                        --工順摘要取得用
       ,ic_whse_mst                     IWM                         --WIP倉庫名取得用
        --【振替後情報取得用】
       ,xxskz_prod_class_v              XPCV_AFT                    --SKYLINK用中間VIEW 商品区分取得VIEW
       ,xxskz_item_class_v              XICV_AFT                    --SKYLINK用中間VIEW 品目商品区分取得VIEW
       ,xxskz_crowd_code_v              XCCV_AFT                    --SKYLINK用中間VIEW 群コード取得VIEW
       ,xxskz_item_mst2_v               XIM2V_AFT                   --SKYLINK用中間VIEW OPM品目情報VIEW2
       ,ic_lots_mst                     ILM_AFT                     --OPMロットマスタ
        --【振替前情報取得用】
       ,xxskz_prod_class_v              XPCV_BEF                    --SKYLINK用中間VIEW 商品区分取得VIEW
       ,xxskz_item_class_v              XICV_BEF                    --SKYLINK用中間VIEW 品目商品区分取得VIEW
       ,xxskz_crowd_code_v              XCCV_BEF                    --SKYLINK用中間VIEW 群コード取得VIEW
       ,xxskz_item_mst2_v               XIM2V_BEF                   --SKYLINK用中間VIEW OPM品目情報VIEW2
       ,ic_lots_mst                     ILM_BEF                     --OPMロットマスタ
        --
       ,fnd_lookup_values               FLV01                       --品目振替目的名取得用
       ,fnd_lookup_values               FLV02                       --バッチステータス名取得用
       ,fnd_user                        FU_CB                       --ユーザーマスタ(CREATED_BY名称取得用)
       ,fnd_user                        FU_LU                       --ユーザーマスタ(LAST_UPDATE_BY名称取得用)
       ,fnd_user                        FU_LL                       --ユーザーマスタ(LAST_UPDATE_LOGIN名称取得用)
       ,fnd_logins                      FL_LL                       --ログインマスタ(LAST_UPDATE_LOGIN名称取得用)
 WHERE
   --プラント名取得条件
        SOMT.language(+)                =  'JA'
   AND  GBHM.plant_code                 =  SOMT.orgn_code(+)
   --レシピ取得条件
   AND  GBHM.recipe_validity_rule_id    =  GRPVR.recipe_validity_rule_id(+)
   AND  GRPVR.recipe_id                 =  GRPB.recipe_id(+)
   AND  GRPT.language(+)                =  'JA'
   AND  GRPVR.recipe_id                 =  GRPT.recipe_id(+)
   --フォーミュラ取得条件
   AND  FFMB.formula_id(+)              =  GBHM.formula_id
   AND  FFMT.formula_id(+)              =  FFMB.formula_id
   AND  FFMT.language(+)                =  'JA'
   --工順名取得条件
   AND  GBHM.routing_id                 =  GRTT.routing_id(+)
   AND  GRTT.language(+)                =  'JA'
   --WIP倉庫名取得条件
   AND  GBHM.wip_whse_code              =  IWM.whse_code(+)
   --
   --【振替後情報取得】
   --品目コード、品目名、品目略称取得条件
   AND  GBHM.aft_item_id                =  XIM2V_AFT.item_id(+)
   AND  GBHM.act_date                  >=  XIM2V_AFT.start_date_active(+)
   AND  GBHM.act_date                  <=  XIM2V_AFT.end_date_active(+)
   --商品区分、商品区分名取得条件
   AND  GBHM.aft_item_id                =  XPCV_AFT.item_id(+)
   --品目区分、品目区分名取得条件
   AND  GBHM.aft_item_id                =  XICV_AFT.item_id(+)
   --群コード取得条件
   AND  GBHM.aft_item_id                =  XCCV_AFT.item_id(+)
   --ロットNo取得
   AND  GBHM.aft_item_id                =  ILM_AFT.item_id(+)
   AND  GBHM.aft_lot_id                 =  ILM_AFT.lot_id(+)
   --
   --【振替前情報取得】
   --品目コード、品目名、品目略称取得条件
   AND  GBHM.bef_item_id                =  XIM2V_BEF.item_id(+)
   AND  GBHM.act_date                  >=  XIM2V_BEF.start_date_active(+)
   AND  GBHM.act_date                  <=  XIM2V_BEF.end_date_active(+)
   --商品区分、商品区分名取得条件
   AND  GBHM.bef_item_id                =  XPCV_BEF.item_id(+)
   --品目区分、品目区分名取得条件
   AND  GBHM.bef_item_id                =  XICV_BEF.item_id(+)
   --群コード取得条件
   AND  GBHM.bef_item_id                =  XCCV_BEF.item_id(+)
   --ロットNo取得
   AND  GBHM.bef_item_id                =  ILM_BEF.item_id(+)
   AND  GBHM.bef_lot_id                 =  ILM_BEF.lot_id(+)
   --
   --WHOカラム取得
   AND  GBHM.created_by                 =  FU_CB.user_id(+)
   AND  GBHM.last_updated_by            =  FU_LU.user_id(+)
   AND  GBHM.last_update_login          =  FL_LL.login_id(+)
   AND  FL_LL.user_id                   =  FU_LL.user_id(+)
   --【クイックコード】品目振替目的名取得条件
   AND  FLV01.language(+)               =  'JA'
   AND  FLV01.lookup_type(+)            =  'XXINV_ITEM_TRANS_CLASS'
   AND  FLV01.lookup_code(+)            =  GBHM.attribute7
   --【クイックコード】バッチステータス名取得条件
   AND  FLV02.language(+)               =  'JA'
   AND  FLV02.lookup_type(+)            =  'GME_BATCH_STATUS'
   AND  FLV02.lookup_code(+)            =  GBHM.batch_status
/
COMMENT ON TABLE APPS.XXSKZ_品目振替情報_基本_V IS 'SKYLINK用品目振替情報（基本）VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.バッチNO               IS 'バッチNo'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.プラントコード         IS 'プラントコード'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.プラント名             IS 'プラント名'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.レシピ                 IS 'レシピ'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.レシピ名称             IS 'レシピ名称'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.レシピ摘要             IS 'レシピ摘要'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.フォーミュラ           IS 'フォーミュラ'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.フォーミュラ名称       IS 'フォーミュラ名称'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.フォーミュラ名称２     IS 'フォーミュラ名称２'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.フォーミュラ摘要       IS 'フォーミュラ摘要'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.フォーミュラ摘要２     IS 'フォーミュラ摘要２'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.工順                   IS '工順'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.工順名称               IS '工順名称'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.工順摘要               IS '工順摘要'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.品目振替名称           IS '品目振替名称'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.品目振替摘要           IS '品目振替摘要'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.品目振替目的           IS '品目振替目的'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.品目振替目的名         IS '品目振替目的名'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.計画開始日             IS '計画開始日'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.実績開始日             IS '実績開始日'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.必須完了日             IS '必須完了日'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.計画完了日             IS '計画完了日'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.実績完了日             IS '実績完了日'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.バッチステータス       IS 'バッチステータス'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.バッチステータス名     IS 'バッチステータス名'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.WIP倉庫                IS 'WIP倉庫'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.WIP倉庫名              IS 'WIP倉庫名'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.クローズ日             IS 'クローズ日'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.削除マーク             IS '削除マーク'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.払出_商品区分          IS '払出_商品区分'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.払出_商品区分名        IS '払出_商品区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.払出_品目区分          IS '払出_品目区分'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.払出_品目区分名        IS '払出_品目区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.払出_群コード          IS '払出_群コード'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.払出_品目コード        IS '払出_品目コード'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.払出_品目正式名        IS '払出_品目正式名'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.払出_品目略称          IS '払出_品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.払出_ロットNO          IS '払出_ロットNo'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.払出_製造年月日        IS '払出_製造年月日'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.払出_固有記号          IS '払出_固有記号'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.払出_賞味期限日        IS '払出_賞味期限日'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.払出_計画数量          IS '払出_計画数量'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.払出_WIP計画数量       IS '払出_WIP計画数量'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.払出_オリジナル数量    IS '払出_オリジナル数量'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.払出_実績数量          IS '払出_実績数量'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.払出_単位              IS '払出_単位'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.払出_原価割当          IS '払出_原価割当'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.払出_割当済フラグ      IS '払出_割当済フラグ'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.払出_割当済フラグ名    IS '払出_割当済フラグ名'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.受入_商品区分          IS '受入_商品区分'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.受入_商品区分名        IS '受入_商品区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.受入_品目区分          IS '受入_品目区分'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.受入_品目区分名        IS '受入_品目区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.受入_群コード          IS '受入_群コード'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.受入_品目コード        IS '受入_品目コード'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.受入_品目正式名        IS '受入_品目正式名'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.受入_品目略称          IS '受入_品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.受入_ロットNO          IS '受入_ロットNo'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.受入_製造年月日        IS '受入_製造年月日'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.受入_固有記号          IS '受入_固有記号'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.受入_賞味期限日        IS '受入_賞味期限日'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.受入_計画数量          IS '受入_計画数量'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.受入_WIP計画数量       IS '受入_WIP計画数量'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.受入_オリジナル数量    IS '受入_オリジナル数量'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.受入_実績数量          IS '受入_実績数量'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.受入_単位              IS '受入_単位'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.受入_原価割当          IS '受入_原価割当'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.受入_割当済フラグ      IS '受入_割当済フラグ'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.受入_割当済フラグ名    IS '受入_割当済フラグ名'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.作成者                 IS '作成者'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.作成日                 IS '作成日'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.最終更新者             IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.最終更新日             IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXSKZ_品目振替情報_基本_V.最終更新ログイン       IS '最終更新ログイン'
/
