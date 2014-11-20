/*************************************************************************
 * 
 * View  Name      : XXSKZ_仕分入荷_基本_V
 * Description     : XXSKZ_仕分入荷_基本_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2012/11/27    1.0   SCSK 月野    初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_仕分入荷_基本_V
(
 生産予定日
,納品場所
,納品場所名
,手配NO
,出来高品目
,出来高品目名
,出来高品目略称
,出来高ロットNo
,出来高製造日
,出来高賞味期限
,出来高固有記号
,出来高依頼数
,摘要
,商品区分
,商品区分名
,品目区分
,品目区分名
,郡コード
,投入品目
,投入品目名
,投入品目略称
,投入ロットNO
,投入製造日
,投入賞味期限
,投入固有記号
,予定区分
,予定区分名
,予定番号
,指示_実績数
,入庫元
,入庫元名
,納入日
,投入口区分
,投入口区分名
)
AS
SELECT
        WPLN.plan_start_date                                plan_start_date               --生産予定日
       ,WPLN.location_code                                  location_code                 --納品場所
       ,ILCT.description                                    location_name                 --納品場所名
       ,WPLN.batch_no                                       batch_no                      --手配No
       ,FITM.item_no                                        output_item_no                --出来高品目
       ,FITM.item_name                                      output_item_name              --出来高品目名
       ,FITM.item_short_name                                output_item_s_name            --出来高品目略称
       ,NVL( DECODE( FLOT.lot_no, 'DEFAULTLOT', '0', FLOT.lot_no ), '0' )
                                                            lot_no                        --出来高品目ロット番号('DEFALTLOT'、ロット未割当は'0')
       ,CASE WHEN FITM.lot_ctl = 1 THEN FLOT.attribute1  --ロット管理品   →製造年月日を取得
             ELSE NULL                                   --非ロット管理品 →NULL
        END                                                 output_manufacture_date       --出来高製造日
       ,CASE WHEN FITM.lot_ctl = 1 THEN FLOT.attribute3  --ロット管理品   →固有記号を取得
             ELSE NULL                                   --非ロット管理品 →NULL
        END                                                 output_expiration_date        --出来高賞味期限
       ,CASE WHEN FITM.lot_ctl = 1 THEN FLOT.attribute2  --ロット管理品   →賞味期限を取得
             ELSE NULL                                   --非ロット管理品 →NULL
        END                                                 output_uniqe_sign             --出来高固有記号
       ,WPLN.output_qty                                     output_qty                    --出来高依頼数
       ,WPLN.description                                    description                   --摘要
       ,PRODC.prod_class_code                               prod_class_code               --商品区分
       ,PRODC.prod_class_name                               prod_class_name               --商品区分名
       ,ITEMC.item_class_code                               item_class_code               --品目区分
       ,ITEMC.item_class_name                               item_class_name               --品目区分名
       ,CROWD.crowd_code                                    crowd_code                    --群コード
       ,MITM.item_no                                        invest_item_no                --投入品目
       ,MITM.item_name                                      invest_item_name              --投入品目名称
       ,MITM.item_short_name                                invest_item_s_name            --投入品目略称
       ,NVL( DECODE( MLOT.lot_no, 'DEFAULTLOT', '0', MLOT.lot_no ), '0' )
                                                            lot_no                        --投入ロット番号('DEFALTLOT'、ロット未割当は'0')
       ,CASE WHEN MITM.lot_ctl = 1 THEN MLOT.attribute1  --ロット管理品   →製造年月日を取得
             ELSE NULL                                   --非ロット管理品 →NULL
        END                                                 invest_manufacture_date       --投入製造日
       ,CASE WHEN MITM.lot_ctl = 1 THEN MLOT.attribute3  --ロット管理品   →固有記号を取得
             ELSE NULL                                   --非ロット管理品 →NULL
        END                                                 invest_expiration_date        --投入賞味期限
       ,CASE WHEN MITM.lot_ctl = 1 THEN MLOT.attribute2  --ロット管理品   →賞味期限を取得
             ELSE NULL                                   --非ロット管理品 →NULL
        END                                                 invest_uniqe_sign             --投入固有記号
       ,WPLN.plan_type                                      plan_type                     --予定区分
       ,FLV01.meaning                                       plan_type_name                --予定区分名
       ,WPLN.plan_number                                    plan_number                   --予定番号
       ,WPLN.invest_qty                                     invest_qty                    --指示_実績数
       ,WPLN.ship_from_code                                 ship_from_code                --入庫元
       ,WPLN.ship_from_name                                 ship_from_name                --入庫元名
       ,WPLN.txns_date                                      txns_date                     --納入日
       ,WPLN.invest_ent_type                                invest_ent_type               --投入口区分
       ,GOT.oprn_desc                                       invest_ent_type_name          --投入口区分名
  FROM  ( --生産予定データを抽出
          -----------------------------------------------------
          -- 生産予定(予定区分が'1')＋移動 データの抽出
          -----------------------------------------------------
          SELECT
                  GBH.plan_start_date                       plan_start_date               --生産予定日
                 ,GRB.attribute9                            location_code                 --生産保管場所
                 ,GBH.batch_no                              batch_no                      --手配No(バッチNo)
                 ,ITP.item_id                               output_item_id                --出来高品目ID
                 ,ITP.lot_id                                output_lot_id                 --出来高ロットID
                 ,ITP.trans_qty                             output_qty                    --出来高依頼数
                 ,GMDF.attribute4                           description                   --摘要
                 ,XMD.item_id                               invest_item_id                --投入品目ID
                 ,XMD.lot_id                                invest_lot_id                 --投入ロットID
                 ,XMD.plan_type                             plan_type                     --予定区分
                 ,XMD.plan_number                           plan_number                   --予定番号
                 ,XMLD.actual_quantity                      invest_qty                    --投入指示_実績数
                 ,XMRIH.shipped_locat_code                  ship_from_code                --入庫元
                 ,ILCT.description                          ship_from_name                --入庫元名
                 ,NVL( XMRIH.actual_arrival_date, XMRIH.schedule_arrival_date )
                                                            txns_date                     --納入日
                 ,GMDM.attribute8                           invest_ent_type               --投入口区分
                 ,GBH.batch_id                              batch_id                      --バッチID(投入口区分名取得用)
            FROM
                  --生産データ
                  xxcmn_gme_batch_header_arc                          GBH                 --生産バッチヘッダ（標準）バックアップ
                 ,gmd_routings_b                            GRB                           --工順マスタ(生産データのみを抽出する為に結合)
                  --生産データ(完成品)
                 ,xxcmn_gme_material_details_arc                      GMDF                --生産原料詳細（標準）バックアップ
                 ,xxcmn_ic_tran_pnd_arc                               ITP                 --OPM保留在庫トランザクション（標準）バックアップ
                  --生産データ(投入品)
                 ,xxcmn_gme_material_details_arc                      GMDM                --生産原料詳細（標準）バックアップ
                 ,xxcmn_material_detail_arc                     XMD                       --生産原料詳細（アドオン）バックアップ
                 ,xxskz_item_class_v                        ITEMC                         --投入品の品目区分取得用(資材を除外する為)
                  --移動データ(投入品)
                 ,xxcmn_mov_req_instr_hdrs_arc               XMRIH                        --移動依頼/指示ヘッダ（アドオン）バックアップ
                 ,xxcmn_mov_req_instr_lines_arc                 XMRIL                     --移動依頼/指示明細（アドオン）バックアップ
                 ,xxcmn_mov_lot_details_arc                     XMLD                      --移動ロット詳細（アドオン）バックアップ
                 ,xxskz_item_locations2_v                   ILCT                          --移動元倉庫名取得用
           WHERE
             --生産バッチヘッダの条件
                  GBH.batch_type                            = 0
             AND  GBH.attribute4                           <> '-1'                        --業務ステータス『取消し』のデータは対象外
             AND  GBH.batch_status                          IN ( '1', '2' )               --予定データ('1:保留'、'2:WIP')
             --工順マスタとの条件
             AND  GRB.routing_class                         NOT IN ( '61', '62', '70' )   --品目振替(70)、解体(61,62) 以外
             AND  GBH.routing_id                            = GRB.routing_id
             --原料詳細データ【完成品】との結合
             AND  GMDF.line_type                            = '1'                         --完成品
             AND  GBH.batch_id                              = GMDF.batch_id
             --完成品のロットID取得の為、保留在庫トランザクションデータと結合
             AND  ITP.doc_type                              = 'PROD'
             AND  ITP.delete_mark                           = 0
             AND  ITP.completed_ind                         = 0                           --完了していない(⇒予定)
             AND  ITP.reverse_id                            IS NULL
             AND  GMDF.material_detail_id                   = ITP.line_id
             AND  GRB.attribute9                            = ITP.location
             AND  GMDF.item_id                              = ITP.item_id
             --原料詳細データ【原料(投入品のみ)】との結合
             AND  GMDM.line_type                            = '-1'                        --原料
             AND  NVL( GMDM.attribute5, 'N' )              <> 'Y'                         --打込品以外(投入品)
             AND  GBH.batch_id                              = GMDM.batch_id
             AND  NVL( ITEMC.item_class_code(+), '1' )     <> '2'                         --投入品の中でも'2:資材'は含まない
             AND  GMDM.item_id                              = ITEMC.item_id(+)
             --原料詳細データ【原料(投入品のみ)】と原料詳細アドオンの結合
             AND  XMD.plan_type                             = '1'                         --予定区分(1：移動)
             AND  GMDM.batch_id                             = XMD.batch_id
             AND  GMDM.material_detail_id                   = XMD.material_detail_id
             --原料詳細アドオンの予定番号から移動データを取得
             AND  XMD.plan_number                           = XMRIH.mov_num               --原料詳細アドオン.予定番号に格納された移動番号で結合
             AND  NVL( XMRIL.delete_flg, 'N' )             <> 'Y'                         --無効明細以外
             AND  XMRIH.mov_hdr_id                          = XMRIL.mov_hdr_id
             AND  XMLD.document_type_code                   = '20'                        --文書タイプ('20':移動)
             AND  XMLD.record_type_code                     = DECODE( XMRIH.status        --ステータスが
                                                                     , '04', '20'         --'04:出庫報告有'   なら '20:出庫実績'
                                                                     , '05', '30'         --'05:入庫報告有'   なら '30:入庫実績'
                                                                     , '06', '30'         --'06:入出庫報告有' なら '30:入庫実績'
                                                                     , '10'               --上記以外          なら '10:指示'
                                                                      )
             AND  XMRIL.mov_line_id                         = XMLD.mov_line_id
             AND  XMD.item_id                               = XMLD.item_id                --投入品の品目IDで結合
             AND  XMD.lot_id                                = XMLD.lot_id                 --投入品のロットIDで結合
             --移動元倉庫名取得
             AND  XMRIH.shipped_locat_id                    = ILCT.inventory_location_id(+)
           --[ 生産予定(予定区分が'1')＋移動 データの抽出  END ]
         UNION ALL
          -----------------------------------------------------
          -- 生産予定(予定区分が'2')＋発注受入 データの抽出
          -----------------------------------------------------
          SELECT
                  GBH.plan_start_date                       plan_start_date               --生産予定日
                 ,GRB.attribute9                            location_code                 --生産保管場所
                 ,GBH.batch_no                              batch_no                      --手配No(バッチNo)
                 ,ITP.item_id                               output_item_id                --出来高品目ID
                 ,ITP.lot_id                                output_lot_id                 --出来高ロットID
                 ,ITP.trans_qty                             output_qty                    --出来高依頼数
                 ,GMDF.attribute4                           description                   --摘要
                 ,XMD.item_id                               invest_item_id                --投入品目ID
                 ,XMD.lot_id                                invest_lot_id                 --投入ロットID
                 ,XMD.plan_type                             plan_type                     --予定区分
                 ,XMD.plan_number                           plan_number                   --予定番号
                 ,PLA.quantity                              invest_qty                    --投入指示_実績数
                 ,VNDR.segment1                             ship_from_code                --入庫元
                 ,VNDR.vendor_name                          ship_from_name                --入庫元名
                 ,TO_DATE( PHA.attribute4, 'YYYY/MM/DD' )   txns_date                     --納入日
                 ,GMDM.attribute8                           invest_ent_type               --投入口区分
                 ,GBH.batch_id                              batch_id                      --バッチID(投入口区分名取得用)
            FROM
                  --生産データ
                  xxcmn_gme_batch_header_arc                          GBH                 --生産バッチヘッダ（標準）バックアップ
                 ,gmd_routings_b                            GRB                           --工順マスタ(生産データのみを抽出する為に結合)
                  --生産データ(完成品)
                 ,xxcmn_gme_material_details_arc                      GMDF                --生産原料詳細（標準）バックアップ
                 ,xxcmn_ic_tran_pnd_arc                               ITP                 --OPM保留在庫トランザクション（標準）バックアップ
                  --生産データ(投入品)
                 ,xxcmn_gme_material_details_arc                      GMDM                --生産原料詳細（標準）バックアップ
                 ,xxcmn_material_detail_arc                     XMD                       --生産原料詳細（アドオン）バックアップ
                 ,xxskz_item_class_v                        ITEMC                         --投入品の品目区分取得用(資材を除外する為)
                  --発注データ(投入品)
                 ,po_headers_all                            PHA                           --発注ヘッダ
                 ,po_lines_all                              PLA                           --発注明細
                 ,mtl_system_items_b                        IITM                          --INV品目マスタ(OPM品目ID変換用)
                 ,ic_item_mst_b                             OITM                          --OPM品目マスタ(OPM品目ID変換用)
                 ,ic_lots_mst                               LOTS                          --ロットマスタ
                 ,xxskz_vendors2_v                          VNDR                          --取引先名取得用
           WHERE
             --生産バッチヘッダの条件
                  GBH.batch_type                            = 0
             AND  GBH.attribute4                           <> '-1'                        --業務ステータス『取消し』のデータは対象外
             AND  GBH.batch_status                          IN ( '1', '2' )               --予定データ('1:保留'、'2:WIP')
             --工順マスタとの条件
             AND  GRB.routing_class                         NOT IN ( '61', '62', '70' )   --品目振替(70)、解体(61,62) 以外
             AND  GBH.routing_id                            = GRB.routing_id
             --原料詳細データ【完成品】との結合
             AND  GMDF.line_type                            = '1'                         --完成品
             AND  GBH.batch_id                              = GMDF.batch_id
             --完成品のロットID取得の為、保留在庫トランザクションデータと結合
             AND  ITP.doc_type                              = 'PROD'
             AND  ITP.delete_mark                           = 0
             AND  ITP.completed_ind                         = 0                           --完了していない(⇒予定)
             AND  ITP.reverse_id                            IS NULL
             AND  GMDF.material_detail_id                   = ITP.line_id
             AND  GRB.attribute9                            = ITP.location
             AND  GMDF.item_id                              = ITP.item_id
             --原料詳細データ【原料(投入品のみ)】との結合
             AND  GMDM.line_type                            = '-1'                        --原料
             AND  NVL( GMDM.attribute5, 'N' )              <> 'Y'                         --打込品以外(投入品)
             AND  GBH.batch_id                              = GMDM.batch_id
             AND  NVL( ITEMC.item_class_code(+), '1' )     <> '2'                         --投入品の中でも'2:資材'は含まない
             AND  GMDM.item_id                              = ITEMC.item_id(+)
             --原料詳細データ【原料(投入品のみ)】と原料詳細アドオンの結合
             AND  XMD.plan_type                             = '2'                         --予定区分(2：発注受入)
             AND  GMDM.batch_id                             = XMD.batch_id
             AND  GMDM.material_detail_id                   = XMD.material_detail_id
             --原料詳細アドオンの予定番号から発注データを取得(①と②含む)
             AND  XMD.plan_number                           = PHA.segment1                --原料詳細アドオン.予定番号に格納された発注番号で結合
             AND  NVL( PLA.cancel_flag, 'N')               <> 'Y'                         --無効明細以外
             AND  PHA.po_header_id                          = PLA.po_header_id
                --①品目IDの結合
             AND  PLA.item_id                               = IITM.inventory_item_id                   --発注INV品目IDをOPM品目IDに変換
             AND  IITM.organization_id                      = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID') --発注INV品目IDをOPM品目IDに変換
             AND  IITM.segment1                             = OITM.item_no                             --発注INV品目IDをOPM品目IDに変換
             AND  OITM.item_id                              = XMD.item_id                 --投入品の品目IDで結合
                --②ロットIDの結合
             AND  OITM.item_id                              = LOTS.item_id                --発注ロットNoをロットIDに変換
             AND  (    ( OITM.lot_ctl = '1' AND LOTS.lot_no = PLA.attribute1 )            --発注ロットNoをロットIDに変換(ロット管理品ならロット番号で結合)
                    OR ( OITM.lot_ctl = '0' AND LOTS.lot_id = 0              )            --発注ロットNoをロットIDに変換(ロット非管理品なら'DEFAULTLOT')
                  )
             AND  LOTS.item_id                              = XMD.item_id                 --投入品の品目IDで結合
             AND  LOTS.lot_id                               = XMD.lot_id                  --投入品のロットIDで結合
             --移動元倉庫名取得
             AND  PHA.vendor_id                             = VNDR.vendor_id(+)
             AND  TO_DATE( PHA.attribute4, 'YYYY/MM/DD' )  >= VNDR.start_date_active(+)
             AND  TO_DATE( PHA.attribute4, 'YYYY/MM/DD' )  <= VNDR.end_date_active(+)
           --[ 生産予定(予定区分が'2')＋発注受入 データの抽出  END ]
         UNION ALL
          -----------------------------------------------------
          -- 生産予定(予定区分が'3:在庫有り') データの抽出
          -----------------------------------------------------
          SELECT
                  GBH.plan_start_date                       plan_start_date               --生産予定日
                 ,GRB.attribute9                            location_code                 --生産保管場所
                 ,GBH.batch_no                              batch_no                      --手配No(バッチNo)
                 ,ITP.item_id                               output_item_id                --出来高品目ID
                 ,ITP.lot_id                                output_lot_id                 --出来高ロットID
                 ,ITP.trans_qty                             output_qty                    --出来高依頼数
                 ,GMDF.attribute4                           description                   --摘要
                 ,XMD.item_id                               invest_item_id                --投入品目ID
                 ,XMD.lot_id                                invest_lot_id                 --投入ロットID
                 ,XMD.plan_type                             plan_type                     --予定区分
                 ,XMD.plan_number                           plan_number                   --予定番号
                 ,NVL( XMD.invested_qty, 0 ) - NVL( XMD.return_qty, 0 )
                                                            invest_qty                    --投入指示_実績数
                 ,NULL                                      ship_from_code                --入庫元
                 ,NULL                                      ship_from_name                --入庫元名
                 ,NULL                                      txns_date                     --納入日
                 ,GMDM.attribute8                           invest_ent_type               --投入口区分
                 ,GBH.batch_id                              batch_id                      --バッチID(投入口区分名取得用)
            FROM
                  --生産データ
                  xxcmn_gme_batch_header_arc                          GBH                 --生産バッチヘッダ（標準）バックアップ
                 ,gmd_routings_b                            GRB                           --工順マスタ(生産データのみを抽出する為に結合)
                  --生産データ(完成品)
                 ,xxcmn_gme_material_details_arc                      GMDF                --生産原料詳細（標準）バックアップ
                 ,xxcmn_ic_tran_pnd_arc                               ITP                 --OPM保留在庫トランザクション（標準）バックアップ
                  --生産データ(投入品)
                 ,xxcmn_gme_material_details_arc                      GMDM                --生産原料詳細（標準）バックアップ
                 ,xxcmn_material_detail_arc                     XMD                       --生産原料詳細（アドオン）バックアップ
                 ,xxskz_item_class_v                        ITEMC                         --投入品の品目区分取得用(資材を除外する為)
           WHERE
             --生産バッチヘッダの条件
                  GBH.batch_type                            = 0
             AND  GBH.attribute4                           <> '-1'                        --業務ステータス『取消し』のデータは対象外
             AND  GBH.batch_status                          IN ( '1', '2' )               --予定データ('1:保留'、'2:WIP')
             --工順マスタとの条件
             AND  GRB.routing_class                         NOT IN ( '61', '62', '70' )   --品目振替(70)、解体(61,62) 以外
             AND  GBH.routing_id                            = GRB.routing_id
             --原料詳細データ【完成品】との結合
             AND  GMDF.line_type                            = '1'                         --完成品
             AND  GBH.batch_id                              = GMDF.batch_id
             --完成品のロットID取得の為、保留在庫トランザクションデータと結合
             AND  ITP.doc_type                              = 'PROD'
             AND  ITP.delete_mark                           = 0
             AND  ITP.completed_ind                         = 0                           --完了していない(⇒予定)
             AND  ITP.reverse_id                            IS NULL
             AND  GMDF.material_detail_id                   = ITP.line_id
             AND  GRB.attribute9                            = ITP.location
             AND  GMDF.item_id                              = ITP.item_id
             --原料詳細データ【原料(投入品のみ)】との結合
             AND  GMDM.line_type                            = '-1'                        --原料
             AND  NVL( GMDM.attribute5, 'N' )              <> 'Y'                         --打込品以外(投入品)
             AND  GBH.batch_id                              = GMDM.batch_id
             AND  NVL( ITEMC.item_class_code(+), '1' )     <> '2'                         --投入品の中でも'2:資材'は含まない
             AND  GMDM.item_id                              = ITEMC.item_id(+)
             --原料詳細データ【原料(投入品のみ)】と原料詳細アドオンの結合
             AND  XMD.plan_type                             = '3'                         --予定区分(3：在庫)
             AND  GMDM.batch_id                             = XMD.batch_id
             AND  GMDM.material_detail_id                   = XMD.material_detail_id
           --[ 生産予定(予定区分が'3:在庫有り') データの抽出  END ]
        )                               WPLN                --生産予定データ
       ,xxskz_item_locations_v          ILCT                --納品場所名取得用
       ,xxskz_item_mst2_v               FITM                --出来高品目名取得用
       ,ic_lots_mst                     FLOT                --出来高品目ロット情報取得用
       ,xxskz_item_mst2_v               MITM                --投入品目名取得用
       ,ic_lots_mst                     MLOT                --投入品目ロット情報取得用
       ,xxskz_prod_class_v              PRODC               --投入品目商品区分取得用
       ,xxskz_item_class_v              ITEMC               --投入品目品目区分取得用
       ,xxskz_crowd_code_v              CROWD               --投入品目群コード取得用
       ,gmd_operations_tl               GOT                 --工程マスタ(投入口区分名取得用)
       ,xxcmn_gme_batch_steps_arc                 GBS       --生産バッチステップ（標準）バックアップ
       ,fnd_lookup_values               FLV01               --予定区分名取得用
 WHERE
   --納品場所名取得
        WPLN.location_code              = ILCT.segment1(+)
   --出来高品目情報取得
   AND  WPLN.output_item_id             = FITM.item_id(+)
   AND  WPLN.plan_start_date           >= FITM.start_date_active(+)
   AND  WPLN.plan_start_date           <= FITM.end_date_active(+)
   --出来高品目ロット情報取得
   AND  WPLN.output_item_id             = FLOT.item_id(+)
   AND  WPLN.output_lot_id              = FLOT.lot_id(+)
   --投入品目情報取得
   AND  WPLN.invest_item_id             = MITM.item_id(+)
   AND  WPLN.plan_start_date           >= MITM.start_date_active(+)
   AND  WPLN.plan_start_date           <= MITM.end_date_active(+)
   --投入品目ロット情報取得
   AND  WPLN.invest_item_id             = MLOT.item_id(+)
   AND  WPLN.invest_lot_id              = MLOT.lot_id(+)
   --投入品目カテゴリ情報取得
   AND  WPLN.invest_item_id             = PRODC.item_id(+)
   AND  WPLN.invest_item_id             = ITEMC.item_id(+)
   AND  WPLN.invest_item_id             = CROWD.item_id(+)
   --投入口区分名取得
   AND  WPLN.batch_id                   = GBS.batch_id(+)
   AND  WPLN.invest_ent_type            = GBS.batchstep_no(+)
   AND  GOT.language(+)                 = 'JA'
   AND  GBS.oprn_id                     = GOT.oprn_id(+)
   --ロット予定区分名
   AND  FLV01.language(+)               = 'JA'
   AND  FLV01.lookup_type(+)            = 'XXWIP_PLAN_TYPE'
   AND  FLV01.lookup_code(+)            = WPLN.plan_type
/
COMMENT ON TABLE APPS.XXSKZ_仕分入荷_基本_V IS 'SKYLINK用仕分入荷基本VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_仕分入荷_基本_V.生産予定日     IS '生産予定日'
/
COMMENT ON COLUMN APPS.XXSKZ_仕分入荷_基本_V.納品場所       IS '納品場所'
/
COMMENT ON COLUMN APPS.XXSKZ_仕分入荷_基本_V.納品場所名     IS '納品場所名'
/
COMMENT ON COLUMN APPS.XXSKZ_仕分入荷_基本_V.手配NO         IS '手配NO'
/
COMMENT ON COLUMN APPS.XXSKZ_仕分入荷_基本_V.出来高品目     IS '出来高品目'
/
COMMENT ON COLUMN APPS.XXSKZ_仕分入荷_基本_V.出来高品目名   IS '出来高品目名'
/
COMMENT ON COLUMN APPS.XXSKZ_仕分入荷_基本_V.出来高品目略称 IS '出来高品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_仕分入荷_基本_V.出来高ロットNo IS '出来高ロットNo'
/
COMMENT ON COLUMN APPS.XXSKZ_仕分入荷_基本_V.出来高製造日   IS '出来高製造日'
/
COMMENT ON COLUMN APPS.XXSKZ_仕分入荷_基本_V.出来高賞味期限 IS '出来高賞味期限'
/
COMMENT ON COLUMN APPS.XXSKZ_仕分入荷_基本_V.出来高固有記号 IS '出来高固有記号'
/
COMMENT ON COLUMN APPS.XXSKZ_仕分入荷_基本_V.出来高依頼数   IS '出来高依頼数'
/
COMMENT ON COLUMN APPS.XXSKZ_仕分入荷_基本_V.摘要           IS '摘要'
/
COMMENT ON COLUMN APPS.XXSKZ_仕分入荷_基本_V.商品区分       IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKZ_仕分入荷_基本_V.商品区分名     IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_仕分入荷_基本_V.品目区分       IS '品目区分'
/
COMMENT ON COLUMN APPS.XXSKZ_仕分入荷_基本_V.品目区分名     IS '品目区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_仕分入荷_基本_V.郡コード       IS '郡コード'
/
COMMENT ON COLUMN APPS.XXSKZ_仕分入荷_基本_V.投入品目       IS '投入品目'
/
COMMENT ON COLUMN APPS.XXSKZ_仕分入荷_基本_V.投入品目名     IS '投入品目名'
/
COMMENT ON COLUMN APPS.XXSKZ_仕分入荷_基本_V.投入品目略称   IS '投入品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_仕分入荷_基本_V.投入ロットNo   IS '投入ロットNo'
/
COMMENT ON COLUMN APPS.XXSKZ_仕分入荷_基本_V.投入製造日     IS '投入製造日'
/
COMMENT ON COLUMN APPS.XXSKZ_仕分入荷_基本_V.投入賞味期限   IS '投入賞味期限'
/
COMMENT ON COLUMN APPS.XXSKZ_仕分入荷_基本_V.投入固有記号   IS '投入固有記号'
/
COMMENT ON COLUMN APPS.XXSKZ_仕分入荷_基本_V.予定区分       IS '予定区分'
/
COMMENT ON COLUMN APPS.XXSKZ_仕分入荷_基本_V.予定区分名     IS '予定区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_仕分入荷_基本_V.予定番号       IS '予定番号'
/
COMMENT ON COLUMN APPS.XXSKZ_仕分入荷_基本_V.指示_実績数    IS '指示_実績数'
/
COMMENT ON COLUMN APPS.XXSKZ_仕分入荷_基本_V.入庫元         IS '入庫元'
/
COMMENT ON COLUMN APPS.XXSKZ_仕分入荷_基本_V.入庫元名       IS '入庫元名'
/
COMMENT ON COLUMN APPS.XXSKZ_仕分入荷_基本_V.納入日         IS '納入日'
/
COMMENT ON COLUMN APPS.XXSKZ_仕分入荷_基本_V.投入口区分     IS '投入口区分'
/
COMMENT ON COLUMN APPS.XXSKZ_仕分入荷_基本_V.投入口区分名   IS '投入口区分名'
/
