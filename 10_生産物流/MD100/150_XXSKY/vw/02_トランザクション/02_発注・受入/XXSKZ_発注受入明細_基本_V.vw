/*************************************************************************
 * 
 * View  Name      : XXSKZ_発注受入明細_基本_V
 * Description     : XXSKZ_発注受入明細_基本_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2012/11/21    1.0   SCSK 月野    初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_発注受入明細_基本_V
(
 発注番号
,受入返品番号
,明細番号
,商品区分
,商品区分名
,品目区分
,品目区分名
,群コード
,品目コード
,品目名
,品目略称
,単価
,数量
,ロット番号
,製造年月日
,固有記号
,賞味期限
,工場コード
,工場名
,付帯コード
,在庫入数
,依頼数量
,依頼数量単位コード
,仕入先出荷日
,仕入先出荷数量
,受入数量
,仕入定価
,日付指定
,発注単位
,発注数量
,相手先在庫入庫先
,相手先在庫入庫先名
,数量確定フラグ
,数量確定フラグ名
,金額確定フラグ
,金額確定フラグ名
,取消フラグ
,取消フラグ名
,摘要
,発注_作成者
,発注_作成日
,発注_最終更新者
,発注_最終更新日
,発注_最終更新ログイン
,受入実績日
,受入単位
,受入返品数量
,受入返品単位
,受入返品換算入数
,粉引率
,粉引後単価
,口銭区分
,口銭区分名
,口銭
,預り口銭金額
,賦課金区分
,賦課金区分名
,賦課金
,賦課金額
,粉引後金額
,受入_作成者
,受入_作成日
,受入_最終更新者
,受入_最終更新日
,受入_最終更新ログイン
)
AS
SELECT
        POL.po_number                                       po_number                     --発注番号
       ,POL.rcv_rtn_number                                  rcv_rtn_number                --受入返品番号（NULLでも結合条件として使用する為 'Dummy' で表示）
       ,POL.line_num                                        line_num                      --明細番号
       ,PRODC.prod_class_code                               prod_class_code               --商品区分
       ,PRODC.prod_class_name                               prod_class_name               --商品区分名
       ,ITEMC.item_class_code                               item_class_code               --品目区分
       ,ITEMC.item_class_name                               item_class_name               --品目区分名
       ,CROWD.crowd_code                                    crowd_code                    --群コード
       ,ITEM.item_no                                        item_code                     --品目コード
       ,ITEM.item_name                                      item_name                     --品目名
       ,ITEM.item_short_name                                item_short_name               --品目略称
       ,NVL( POL.unit_price, 0 )                            unit_price                    --単価
       ,NVL( POL.quantity, 0 )                              quantity                      --数量
       ,NVL( DECODE( POL.lot_no, 'DEFAULTLOT', '0', POL.lot_no ), '0' )
                                                            lot_no                        --ロットNo('DEFALTLOT'、ロット未割当は'0')
       ,CASE WHEN ITEM.lot_ctl = 1 THEN LOT.attribute1  --ロット管理品   →製造年月日を取得
             ELSE NULL                                  --非ロット管理品 →NULL
        END                                                 manufacture_date              --製造年月日
       ,CASE WHEN ITEM.lot_ctl = 1 THEN LOT.attribute2  --ロット管理品   →固有記号を取得
             ELSE NULL                                  --非ロット管理品 →NULL
        END                                                 uniqe_sign                    --固有記号
       ,CASE WHEN ITEM.lot_ctl = 1 THEN LOT.attribute3  --ロット管理品   →賞味期限を取得
             ELSE NULL                                  --非ロット管理品 →NULL
        END                                                 expiration_date               --賞味期限
       ,POL.factory_code                                    factory_code                  --工場コード
       ,VDST.vendor_site_name                               factory_name                  --工場名
       ,POL.futai_code                                      futai_code                    --付帯コード
       ,NVL( POL.pack_qty, 0 )                              pack_qty                      --在庫入数
       ,NVL( POL.request_qty, 0 )                           request_qty                   --依頼数量
       ,POL.request_uom                                     request_uom                   --依頼数量単位コード
       ,POL.vendor_dlvr_date                                vendor_dlvr_date              --仕入先出荷日
       ,NVL( POL.vendor_dlvr_qty, 0 )                       vendor_dlvr_qty               --仕入先出荷数量
       ,NVL( POL.rcv_qty, 0 )                               rcv_qty                       --受入数量
       ,NVL( POL.purchase_amt, 0 )                          purchase_amt                  --仕入定価
       ,POL.date_reserved                                   date_reserved                 --日付指定
       ,POL.order_uom                                       order_uom                     --発注単位
       ,NVL( POL.order_qty, 0 )                             order_qty                     --発注数量
       ,POL.party_dlvr_to                                   party_dlvr_to                 --相手先在庫入庫先
       ,ILOC.description                                    party_dlvr_to_name            --相手先在庫入庫先名
       ,POL.fix_qty_flg                                     fix_qty_flg                   --数量確定フラグ
       ,FLV01.meaning                                       fix_qty_flg_name              --数量確定フラグ名
       ,POL.fix_amt_flg                                     fix_amt_flg                   --金額確定フラグ
       ,FLV02.meaning                                       fix_amt_flg_name              --金額確定フラグ名
       ,NVL( POL.cancel_flg, 'N' )                          cancel_flg                    --取消フラグ
       ,FLV03.meaning                                       cancel_flg_name               --取消フラグ名
       ,POL.description                                     description                   --摘要
       ,FU_CB_H.user_name                                   h_created_by                  --発注_作成者
       ,TO_CHAR( POL.h_creation_date   , 'YYYY/MM/DD HH24:MI:SS' )
                                                            h_creation_date               --発注_作成日
       ,FU_LU_H.user_name                                   h_last_updated_by             --発注_最終更新者
       ,TO_CHAR( POL.h_last_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                                            h_last_update_date            --発注_最終更新日
       ,FU_LL_H.user_name                                   h_last_update_login           --発注_最終更新ログイン
       ,POL.u_txns_date                                     u_txns_date                   --受入実績日
       ,POL.u_uom                                           u_uom                         --受入単位
       ,NVL( POL.u_rcv_rtn_quantity, 0 )                    u_rcv_rtn_quantity            --受入返品数量
       ,POL.u_rcv_rtn_uom                                   u_rcv_rtn_uom                 --受入返品単位
       ,NVL( POL.u_conversion_factor, 0 )                   u_conversion_factor           --受入返品換算入数
       ,NVL( POL.kobiki_rate, 0 )                           kobiki_rate                   --粉引率
       ,NVL( POL.kobki_converted_unit_price, 0 )            kobki_converted_unit_price    --粉引後単価
       ,POL.kousen_type                                     kousen_type                   --口銭区分
       ,FLV04.meaning                                       kousen_type_name              --口銭区分名
       ,NVL( POL.kousen_rate_or_unit_price, 0 )             kousen_rate_or_unit_price     --口銭
       ,NVL( POL.kousen_price, 0 )                          kousen_price                  --預り口銭金額
       ,POL.fukakin_type                                    fukakin_type                  --賦課金区分
       ,FLV05.meaning                                       fukakin_type_name             --賦課金区分名
       ,NVL( POL.fukakin_rate_or_unit_price, 0 )            fukakin_rate_or_unit_price    --賦課金
       ,NVL( POL.fukakin_price, 0 )                         fukakin_price                 --賦課金額
       ,NVL( POL.kobki_converted_price, 0 )                 kobki_converted_price         --粉引後金額（粉引後単価×受入数量）
       ,FU_CB_U.user_name                                   u_created_by                  --受入_作成者
       ,TO_CHAR( POL.u_creation_date   , 'YYYY/MM/DD HH24:MI:SS' )
                                                            u_creation_date               --受入_作成日
       ,FU_LU_U.user_name                                   u_last_updated_by             --受入_最終更新者
       ,TO_CHAR( POL.u_last_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                                            u_last_update_date            --受入_最終更新日
       ,FU_LL_U.user_name                                   u_last_update_login           --受入_最終更新ログイン
  FROM
       ( --【発注依頼】【発注受入】【発注あり返品】【発注無し返品】 の各データを取得
          --========================================================================
          -- 発注依頼データ （発注依頼データ NOT EXISTS 発注データ）
          --========================================================================
          SELECT
                  XRH.po_header_number                      po_number                     --発注番号
                 ,'Dummy'                                   rcv_rtn_number                --受入返品番号（受入実績データが存在しない為に 'Dummy' 固定）
                 ,XRL.requisition_line_number               line_num                      --明細番号
                 ,XRL.item_id                               item_id                       --品目ID(OPM品目ID)
                 ,0                                         unit_price                    --単価
                 ,0                                         quantity                      --数量
                 ,NULL                                      lot_no                        --ロット番号
                 ,NULL                                      factory_code                  --工場コード
                 ,NULL                                      futai_code                    --付帯コード
                 ,XRL.pack_quantity                         pack_qty                      --在庫入数
                 ,XRL.requested_quantity                    request_qty                   --依頼数量
                 ,XRL.requested_quantity_uom                request_uom                   --依頼数量単位コード
                 ,NULL                                      vendor_dlvr_date              --仕入先出荷日
                 ,0                                         vendor_dlvr_qty               --仕入先出荷数量
                 ,0                                         rcv_qty                       --受入数量
                 ,0                                         purchase_amt                  --仕入定価
                 ,XRL.requested_date                        date_reserved                 --日付指定
                 ,NULL                                      order_uom                     --発注単位
                 ,XRL.ordered_quantity                      order_qty                     --発注数量
                 ,NULL                                      party_dlvr_to                 --相手先在庫入庫先
                 ,NULL                                      fix_qty_flg                   --数量確定フラグ
                 ,NULL                                      fix_amt_flg                   --金額確定フラグ
                 ,'N'                                       cancel_flg                    --取消フラグ
                 ,XRL.description                           description                   --摘要
                 ,XRL.created_by                            h_created_by                  --発注_作成者
                 ,XRL.creation_date                         h_creation_date               --発注_作成日
                 ,XRL.last_updated_by                       h_last_updated_by             --発注_最終更新者
                 ,XRL.last_update_date                      h_last_update_date            --発注_最終更新日
                 ,XRL.last_update_login                     h_last_update_login           --発注_最終更新ログイン
                 ,NULL                                      u_txns_date                   --受入実績日
                 ,NULL                                      u_uom                         --受入単位
                 ,0                                         u_rcv_rtn_quantity            --受入返品数量
                 ,NULL                                      u_rcv_rtn_uom                 --受入返品単位
                 ,0                                         u_conversion_factor           --受入返品換算入数
                 ,0                                         kobiki_rate                   --粉引率
                 ,0                                         kobki_converted_unit_price    --粉引後単価
                 ,NULL                                      kousen_type                   --口銭区分
                 ,0                                         kousen_rate_or_unit_price     --口銭
                 ,0                                         kousen_price                  --預り口銭金額
                 ,NULL                                      fukakin_type                  --賦課金区分
                 ,0                                         fukakin_rate_or_unit_price    --賦課金
                 ,0                                         fukakin_price                 --賦課金額
                 ,0                                         kobki_converted_price         --粉引後金額（粉引後単価×受入数量）
                 ,NULL                                      u_created_by                  --受入_作成者
                 ,NULL                                      u_creation_date               --受入_作成日
                 ,NULL                                      u_last_updated_by             --受入_最終更新者
                 ,NULL                                      u_last_update_date            --受入_最終更新日
                 ,NULL                                      u_last_update_login           --受入_最終更新ログイン
                  --名称取得用基準日
                 ,XRH.promised_date                         deliver_date                  --納入日
            FROM
                  xxpo_requisition_headers                  XRH                           --発注依頼ヘッダアドオン
                 ,xxpo_requisition_lines                    XRL                           --発注依頼明細アドオン
           WHERE
             --発注依頼ヘッダとの結合
                  XRH.requisition_header_id                 = XRL.requisition_header_id
             --発注済データは『発注･受入データ』として表示する為、除外する
             AND  NOT EXISTS
                  (
                    SELECT  E_XRL.requisition_line_id
                      FROM  xxpo_requisition_headers        E_XRH
                           ,po_headers_all                  E_PHA
                           ,xxpo_requisition_lines          E_XRL
                           ,po_lines_all                    E_PLA
                     WHERE  E_XRH.po_header_number          = E_PHA.segment1
                       AND  E_XRH.requisition_header_id     = E_XRL.requisition_header_id
                       AND  E_PHA.po_header_id              = E_PLA.po_header_id
                       AND  E_XRL.requisition_line_id       = XRL.requisition_line_id
                  )
          --[ 発注依頼データ  END ]
        UNION ALL
-- 2010/07/16 T.Yoshimoto Del Start E_本稼動_03772
--          --========================================================================
--          -- 発注・受入データ （受入実績区分 = '1'）
--          --========================================================================
--          SELECT
--                  PO.po_number                              po_number                     --発注番号
--                 ,NVL( XRART.rcv_rtn_number, 'Dummy' )      rcv_rtn_number                --受入返品番号（受入実績データが存在しない場合は 'Dummy' 固定）
--                 ,PO.line_num                               line_num                      --明細番号
--                 ,PO.item_id                                item_id                       --品目ID(OPM品目ID)
--                 ,PO.unit_price                             unit_price                    --単価
--                 ,PO.quantity                               quantity                      --数量
--                 ,PO.lot_no                                 lot_no                        --ロット番号
--                 ,PO.factory_code                           factory_code                  --工場コード
--                 ,PO.futai_code                             futai_code                    --付帯コード
--                 ,PO.pack_qty                               pack_qty                      --在庫入数
--                 ,0                                         request_qty                   --依頼数量
--                 ,NULL                                      request_uom                   --依頼数量単位コード
--                 ,PO.vendor_dlvr_date                       vendor_dlvr_date              --仕入先出荷日
--                 ,PO.vendor_dlvr_qty                        vendor_dlvr_qty               --仕入先出荷数量
--                 ,PO.rcv_qty                                rcv_qty                       --受入数量
--                 ,PO.purchase_amt                           purchase_amt                  --仕入定価
--                 ,PO.date_reserved                          date_reserved                 --日付指定
--                 ,PO.order_uom                              order_uom                     --発注単位
--                 ,PO.order_qty                              order_qty                     --発注数量
--                 ,PO.party_dlvr_to                          party_dlvr_to                 --相手先在庫入庫先
--                 ,PO.fix_qty_flg                            fix_qty_flg                   --数量確定フラグ
--                 ,PO.fix_amt_flg                            fix_amt_flg                   --金額確定フラグ
--                 ,PO.cancel_flg                             cancel_flg                    --取消フラグ
--                 ,PO.description                            description                   --摘要
--                 ,PO.h_created_by                           h_created_by                  --発注_作成者
--                 ,PO.h_creation_date                        h_creation_date               --発注_作成日
--                 ,PO.h_last_updated_by                      h_last_updated_by             --発注_最終更新者
--                 ,PO.h_last_update_date                     h_last_update_date            --発注_最終更新日
--                 ,PO.h_last_update_login                    h_last_update_login           --発注_最終更新ログイン
--                 ,XRART.txns_date                           u_txns_date                   --受入実績日
--                 ,XRART.uom                                 u_uom                         --受入単位
--                 ,XRART.rcv_rtn_quantity                    u_rcv_rtn_quantity            --受入返品数量
--                 ,XRART.rcv_rtn_uom                         u_rcv_rtn_uom                 --受入返品単位
--                 ,XRART.conversion_factor                   u_conversion_factor           --受入返品換算入数
--                 ,TO_NUMBER( PLLA.attribute1 )              kobiki_rate                   --粉引率
--                 ,TO_NUMBER( PLLA.attribute2 )              kobki_converted_unit_price    --粉引後単価
--                 ,PLLA.attribute3                           kousen_type                   --口銭区分
--                 ,TO_NUMBER( PLLA.attribute4 )              kousen_rate_or_unit_price     --口銭
--                 ,TO_NUMBER( PLLA.attribute5 )              kousen_price                  --預り口銭金額
--                 ,PLLA.attribute6                           fukakin_type                  --賦課金区分
--                 ,TO_NUMBER( PLLA.attribute7 )              fukakin_rate_or_unit_price    --賦課金
--                 ,TO_NUMBER( PLLA.attribute8 )              fukakin_price                 --賦課金額
---- 2009-03-10 H.Iida MOD START 本番障害#1131
----                 ,NVL( TO_NUMBER( PLLA.attribute2 ), 0 ) * NVL( PO.rcv_qty, 0 )
----                                                            kobki_converted_price         --粉引後金額（粉引後単価×受入数量）
---- 2009-12-28 Y.Fukami MOD START 本稼動障害#696
----                 ,NVL( TO_NUMBER( PLLA.attribute2 ), 0 ) * NVL( XRART.quantity, 0 )
--                 ,ROUND(NVL( TO_NUMBER( PLLA.attribute2 ), 0 ) * NVL( XRART.quantity, 0 ))
---- 2009-12-28 Y.Fukami MOD END
--                                                            kobki_converted_price         --粉引後金額（粉引後単価×受入返品実績(アドオン).数量）
---- 2009-03-10 H.Iida MOD END
--                 ,XRART.created_by                          u_created_by                  --受入_作成者
--                 ,XRART.creation_date                       u_creation_date               --受入_作成日
--                 ,XRART.last_updated_by                     u_last_updated_by             --受入_最終更新者
--                 ,XRART.last_update_date                    u_last_update_date            --受入_最終更新日
--                 ,XRART.last_update_login                   u_last_update_login           --受入_最終更新ログイン
--                 --名称取得用基準日
--                 ,PO.deliver_date                           deliver_date                  --納入日
--            FROM
--                 (
--                    --受入返品アドオンと外部結合を行う為、副問い合わせとする
--                    SELECT
--                            PHA.po_header_id                po_header_id                  --発注ヘッダID
--                           ,PLA.po_line_id                  po_line_id                    --発注明細ID
--                           ,PHA.segment1                    po_number                     --発注番号
--                           ,PLA.line_num                    line_num                      --明細番号
--                           ,IIMB.item_id                    item_id                       --品目ID(OPM品目ID)
--                           ,PLA.unit_price                  unit_price                    --単価
--                           ,PLA.quantity                    quantity                      --数量
--                           ,PLA.attribute1                  lot_no                        --ロット番号
--                           ,PLA.attribute2                  factory_code                  --工場コード
--                           ,PLA.attribute3                  futai_code                    --付帯コード
--                           ,TO_NUMBER( PLA.attribute4  )    pack_qty                      --在庫入数
--                           ,TO_DATE( PLA.attribute5 )       vendor_dlvr_date              --仕入先出荷日
--                           ,TO_NUMBER( PLA.attribute6  )    vendor_dlvr_qty               --仕入先出荷数量
--                           ,TO_NUMBER( PLA.attribute7  )    rcv_qty                       --受入数量
--                           ,TO_NUMBER( PLA.attribute8  )    purchase_amt                  --仕入定価
--                           ,TO_DATE( PLA.attribute9 )       date_reserved                 --日付指定
--                           ,PLA.attribute10                 order_uom                     --発注単位
--                           ,TO_NUMBER( PLA.attribute11 )    order_qty                     --発注数量
--                           ,PLA.attribute12                 party_dlvr_to                 --相手先在庫入庫先
--                           ,PLA.attribute13                 fix_qty_flg                   --数量確定フラグ
--                           ,PLA.attribute14                 fix_amt_flg                   --金額確定フラグ
--                           ,PLA.cancel_flag                 cancel_flg                    --取消フラグ
--                           ,PLA.attribute15                 description                   --摘要
--                           ,PLA.created_by                  h_created_by                  --発注_作成者
--                           ,PLA.creation_date               h_creation_date               --発注_作成日
--                           ,PLA.last_updated_by             h_last_updated_by             --発注_最終更新者
--                           ,PLA.last_update_date            h_last_update_date            --発注_最終更新日
--                           ,PLA.last_update_login           h_last_update_login           --発注_最終更新ログイン
--                            --名称取得用基準日
--                           ,TO_DATE( PHA.attribute4 )       deliver_date                  --納入日
--                      FROM
--                            po_headers_all                  PHA                           --発注ヘッダ
--                           ,po_lines_all                    PLA                           --発注明細
--                           ,mtl_system_items_b              MSIB                          --INV品目マスタ(OPM品目ID変換用)
--                           ,ic_item_mst_b                   IIMB                          --OPM品目マスタ(OPM品目ID変換用)
--                     WHERE
--                       --発注ヘッダとの結合
--                            PHA.po_header_id                = PLA.po_header_id
--                       --INV品目ID⇒OPM品目ID 変換
--                       AND  PLA.item_id                     = MSIB.inventory_item_id
--                       AND  MSIB.organization_id            = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
--                       AND  MSIB.segment1                   = IIMB.item_no
--                 )                                          PO                            --発注データ
--                 ,po_line_locations_all                     PLLA                          --発注納入明細
--                 ,xxpo_rcv_and_rtn_txns                     XRART                         --受入返品実績(アドオン)
--           WHERE
--             --発注納入明細との結合（【粉引率】以下の項目は受入返品実績のデータではなくこちらを使用する）
--                  PO.po_header_id                           = PLLA.po_header_id
--             AND  PO.po_line_id                             = PLLA.po_line_id
--             --受入返品実績アドオン   ⇒発注止まり（受入実績データ無し）のデータも取得する為、外部結合
--             AND  XRART.txns_type(+)                        = '1'                         -- 実績区分:'1:受入'
--             AND  PO.po_number                              = XRART.rcv_rtn_number(+)
--             AND  PO.line_num                               = XRART.source_document_line_num(+)
--          --[ 発注依頼データ  END ]
-- 2010/07/16 T.Yoshimoto Del End E_本稼動_03772
-- 2010/07/16 T.Yoshimoto Add Start E_本稼動_03772
          --========================================================================
          -- 発注・受入実績なしデータ(数量確定フラグ = 'N')
          --========================================================================
          SELECT
                  PHA.segment1                              po_number                     --発注番号
                 ,'Dummy'                                   rcv_rtn_number                --受入返品番号（受入実績データが存在しない場合は 'Dummy' 固定）
                 ,PLA.line_num                              line_num                      --明細番号
                 ,IIMB.item_id                              item_id                       --品目ID(OPM品目ID)
                 ,PLA.unit_price                            unit_price                    --単価
                 ,PLA.quantity                              quantity                      --数量
                 ,PLA.attribute1                            lot_no                        --ロット番号
                 ,PLA.attribute2                            factory_code                  --工場コード
                 ,PLA.attribute3                            futai_code                    --付帯コード
                 ,TO_NUMBER( PLA.attribute4  )              pack_qty                      --在庫入数
                 ,0                                         request_qty                   --依頼数量
                 ,NULL                                      request_uom                   --依頼数量単位コード
                 ,TO_DATE( PLA.attribute5 )                 vendor_dlvr_date              --仕入先出荷日
                 ,TO_NUMBER( PLA.attribute6  )              vendor_dlvr_qty               --仕入先出荷数量
                 ,TO_NUMBER( PLA.attribute7  )              rcv_qty                       --受入数量
                 ,TO_NUMBER( PLA.attribute8  )              purchase_amt                  --仕入定価
                 ,TO_DATE( PLA.attribute9 )                 date_reserved                 --日付指定
                 ,PLA.attribute10                           order_uom                     --発注単位
                 ,TO_NUMBER( PLA.attribute11 )              order_qty                     --発注数量
                 ,PLA.attribute12                           party_dlvr_to                 --相手先在庫入庫先
                 ,PLA.attribute13                           fix_qty_flg                   --数量確定フラグ
                 ,PLA.attribute14                           fix_amt_flg                   --金額確定フラグ
                 ,PLA.cancel_flag                           cancel_flg                    --取消フラグ
                 ,PLA.attribute15                           description                   --摘要
                 ,PLA.created_by                            h_created_by                  --発注_作成者
                 ,PLA.creation_date                         h_creation_date               --発注_作成日
                 ,PLA.last_updated_by                       h_last_updated_by             --発注_最終更新者
                 ,PLA.last_update_date                      h_last_update_date            --発注_最終更新日
                 ,PLA.last_update_login                     h_last_update_login           --発注_最終更新ログイン
                 ,NULL                                      u_txns_date                   --受入実績日
                 ,NULL                                      u_uom                         --受入単位
                 ,0                                         u_rcv_rtn_quantity            --受入返品数量
                 ,NULL                                      u_rcv_rtn_uom                 --受入返品単位
                 ,NULL                                      u_conversion_factor           --受入返品換算入数
                 ,TO_NUMBER( PLLA.attribute1 )              kobiki_rate                   --粉引率
                 ,TO_NUMBER( PLLA.attribute2 )              kobki_converted_unit_price    --粉引後単価
                 ,PLLA.attribute3                           kousen_type                   --口銭区分
                 ,TO_NUMBER( PLLA.attribute4 )              kousen_rate_or_unit_price     --口銭
                 ,TO_NUMBER( PLLA.attribute5 )              kousen_price                  --預り口銭金額
                 ,PLLA.attribute6                           fukakin_type                  --賦課金区分
                 ,TO_NUMBER( PLLA.attribute7 )              fukakin_rate_or_unit_price    --賦課金
                 ,TO_NUMBER( PLLA.attribute8 )              fukakin_price                 --賦課金額
                 ,0                                         kobki_converted_price         --粉引後金額（粉引後単価×受入返品実績(アドオン).数量）
                 ,NULL                                      u_created_by                  --受入_作成者
                 ,NULL                                      u_creation_date               --受入_作成日
                 ,NULL                                      u_last_updated_by             --受入_最終更新者
                 ,NULL                                      u_last_update_date            --受入_最終更新日
                 ,NULL                                      u_last_update_login           --受入_最終更新ログイン
                 --名称取得用基準日
                 ,TO_DATE( PHA.attribute4 )                 deliver_date                  --納入日
            FROM
                  po_headers_all                            PHA                           --発注ヘッダ
                 ,po_lines_all                              PLA                           --発注明細
                 ,mtl_system_items_b                        MSIB                          --INV品目マスタ(OPM品目ID変換用)
                 ,ic_item_mst_b                             IIMB                          --OPM品目マスタ(OPM品目ID変換用)
                 ,po_line_locations_all                     PLLA                          --発注納入明細
           WHERE
             --発注ヘッダとの結合
                  PHA.po_header_id                = PLA.po_header_id
             AND  PHA.attribute1                  IN ('15','20','25','99')
             AND  PLA.attribute13                 = 'N'
             --INV品目ID⇒OPM品目ID 変換
             AND  PLA.item_id                     = MSIB.inventory_item_id
             AND  MSIB.organization_id            = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
             AND  MSIB.segment1                   = IIMB.item_no
             --発注納入明細との結合（【粉引率】以下の項目は受入返品実績のデータではなくこちらを使用する）
             AND  PHA.po_header_id                = PLLA.po_header_id
             AND  PLA.po_line_id                  = PLLA.po_line_id
          --[ 発注・受入実績なしデータ  END ]
        UNION ALL
          --========================================================================
          -- 受入実績データ （受入実績区分 = '1'）(数量確定フラグ = 'Y')
          --========================================================================
          SELECT
                  PHA.segment1                              po_number                     --発注番号
                 ,XRART.rcv_rtn_number                      rcv_rtn_number                --受入返品番号
                 ,PLA.line_num                              line_num                      --明細番号
                 ,IIMB.item_id                              item_id                       --品目ID(OPM品目ID)
                 ,PLA.unit_price                            unit_price                    --単価
                 ,PLA.quantity                              quantity                      --数量
                 ,PLA.attribute1                            lot_no                        --ロット番号
                 ,PLA.attribute2                            factory_code                  --工場コード
                 ,PLA.attribute3                            futai_code                    --付帯コード
                 ,TO_NUMBER( PLA.attribute4  )              pack_qty                      --在庫入数
                 ,0                                         request_qty                   --依頼数量
                 ,NULL                                      request_uom                   --依頼数量単位コード
                 ,TO_DATE( PLA.attribute5 )                 vendor_dlvr_date              --仕入先出荷日
                 ,TO_NUMBER( PLA.attribute6  )              vendor_dlvr_qty               --仕入先出荷数量
                 ,TO_NUMBER( PLA.attribute7  )              rcv_qty                       --受入数量
                 ,TO_NUMBER( PLA.attribute8  )              purchase_amt                  --仕入定価
                 ,TO_DATE( PLA.attribute9 )                 date_reserved                 --日付指定
                 ,PLA.attribute10                           order_uom                     --発注単位
                 ,TO_NUMBER( PLA.attribute11 )              order_qty                     --発注数量
                 ,PLA.attribute12                           party_dlvr_to                 --相手先在庫入庫先
                 ,PLA.attribute13                           fix_qty_flg                   --数量確定フラグ
                 ,PLA.attribute14                           fix_amt_flg                   --金額確定フラグ
                 ,PLA.cancel_flag                           cancel_flg                    --取消フラグ
                 ,PLA.attribute15                           description                   --摘要
                 ,PLA.created_by                            h_created_by                  --発注_作成者
                 ,PLA.creation_date                         h_creation_date               --発注_作成日
                 ,PLA.last_updated_by                       h_last_updated_by             --発注_最終更新者
                 ,PLA.last_update_date                      h_last_update_date            --発注_最終更新日
                 ,PLA.last_update_login                     h_last_update_login           --発注_最終更新ログイン
                 ,XRART.txns_date                           u_txns_date                   --受入実績日
                 ,XRART.uom                                 u_uom                         --受入単位
                 ,XRART.rcv_rtn_quantity                    u_rcv_rtn_quantity            --受入返品数量
                 ,XRART.rcv_rtn_uom                         u_rcv_rtn_uom                 --受入返品単位
                 ,XRART.conversion_factor                   u_conversion_factor           --受入返品換算入数
                 ,TO_NUMBER( PLLA.attribute1 )              kobiki_rate                   --粉引率
                 ,TO_NUMBER( PLLA.attribute2 )              kobki_converted_unit_price    --粉引後単価
                 ,PLLA.attribute3                           kousen_type                   --口銭区分
                 ,TO_NUMBER( PLLA.attribute4 )              kousen_rate_or_unit_price     --口銭
                 -- 口銭金額
                 ,CASE
                    -- 口銭区分が「率」の場合
                    WHEN PLLA.attribute3 = '2' THEN
                      -- 預かり口銭金額＝単価*数量*口銭/100
                      TRUNC(TO_NUMBER( PLA.attribute8  ) * 
                                       NVL(XRART.quantity, 0) * NVL(TO_NUMBER( PLLA.attribute4 ), 0) / 100 )
                    -- 口銭区分が「円」の場合
                    WHEN PLLA.attribute3 = '1' THEN
                      -- 預り口銭金額＝口銭*数量
                      TRUNC( NVL(TO_NUMBER( PLLA.attribute4 ), 0) * NVL(XRART.quantity, 0))
                    -- 口銭区分が「無」の場合
                    ELSE
                      0
                  END                                       kousen_price                  --預り口銭金額
                 ,PLLA.attribute6                           fukakin_type                  --賦課金区分
                 ,TO_NUMBER( PLLA.attribute7 )              fukakin_rate_or_unit_price    --賦課金
                 -- 賦課金額
                 ,CASE
                    -- 賦課金区分が「率」の場合
                    WHEN PLLA.attribute6 = '2' THEN
                      -- 粉引額＝単価 * 数量 * 粉引率 / 100
                      -- 賦課金額＝（単価 * 数量 - 粉引額）* 賦課率 / 100
                      TRUNC(
                        ( TO_NUMBER( PLA.attribute8  ) * NVL(XRART.quantity, 0) - 
                          ( TO_NUMBER( PLA.attribute8  ) * NVL(XRART.quantity, 0) * 
                            NVL(TO_NUMBER( PLLA.attribute1 ),0) / 100)) * TO_NUMBER( PLLA.attribute7 ) / 100)
                    -- 賦課金区分が「円」の場合
                    WHEN PLLA.attribute6 = '1' THEN
                      -- 賦課金額＝賦課金*数量
                      TRUNC( NVL(TO_NUMBER( PLLA.attribute7 ),0) * NVL(XRART.quantity, 0) )
                    -- 賦課金区分が「無」の場合
                    ELSE
                      0
                  END                                       fukakin_price                 --賦課金額
                 ,ROUND(NVL( TO_NUMBER( PLLA.attribute2 ), 0 ) * NVL( XRART.quantity, 0 ))
                                                            kobki_converted_price         --粉引後金額（粉引後単価×受入返品実績(アドオン).数量）
                 ,XRART.created_by                          u_created_by                  --受入_作成者
                 ,XRART.creation_date                       u_creation_date               --受入_作成日
                 ,XRART.last_updated_by                     u_last_updated_by             --受入_最終更新者
                 ,XRART.last_update_date                    u_last_update_date            --受入_最終更新日
                 ,XRART.last_update_login                   u_last_update_login           --受入_最終更新ログイン
                 --名称取得用基準日
                 ,TO_DATE( PHA.attribute4 )                 deliver_date                  --納入日
            FROM
                  po_headers_all                            PHA                           --発注ヘッダ
                 ,po_lines_all                              PLA                           --発注明細
                 ,mtl_system_items_b                        MSIB                          --INV品目マスタ(OPM品目ID変換用)
                 ,ic_item_mst_b                             IIMB                          --OPM品目マスタ(OPM品目ID変換用)
                 ,po_line_locations_all                     PLLA                          --発注納入明細
                 ,xxpo_rcv_and_rtn_txns                     XRART                         --受入返品実績(アドオン)
           WHERE
             --発注ヘッダとの結合
                  PHA.po_header_id                = PLA.po_header_id
             AND  PHA.attribute1                  IN ('25','30','35')
             AND  PLA.attribute13                 = 'Y'
             --INV品目ID⇒OPM品目ID 変換
             AND  PLA.item_id                     = MSIB.inventory_item_id
             AND  MSIB.organization_id            = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
             AND  MSIB.segment1                   = IIMB.item_no
             --発注納入明細との結合（【粉引率】以下の項目は受入返品実績のデータではなくこちらを使用する）
             AND  PHA.po_header_id                = PLLA.po_header_id
             AND  PLA.po_line_id                  = PLLA.po_line_id
             --受入返品実績アドオン
             AND  XRART.txns_type                 = '1'                         -- 実績区分:'1:受入'
             AND  PHA.segment1                    = XRART.rcv_rtn_number
             AND  PLA.line_num                    = XRART.source_document_line_num
          --[ 受入実績データ  END ]
-- 2010/07/16 T.Yoshimoto Add End E_本稼動_03772
        UNION ALL
          --========================================================================
          -- 発注あり返品データ （受入実績区分 = '2'）
          --   ※数量、金額はマイナス値とする
          --========================================================================
          SELECT
                  PHA.segment1                              po_number                     --発注番号（発注ありなので発注番号は必ず存在する）
                 ,NVL( XRART.rcv_rtn_number, 'Dummy' )      rcv_rtn_number                --受入返品番号（返品データなので返品番号が必ず存在する）
                 ,PLA.line_num                              line_num                      --明細番号
                 ,IIMB.item_id                              item_id                       --品目ID(OPM品目ID)
                 ,PLA.unit_price                            unit_price                    --単価
                 ,PLA.quantity * -1                         quantity                      --数量
                 ,PLA.attribute1                            lot_no                        --ロット番号
                 ,PLA.attribute2                            factory_code                  --工場コード
                 ,PLA.attribute3                            futai_code                    --付帯コード
                 ,TO_NUMBER( PLA.attribute4  )              pack_qty                      --在庫入数
                 ,0                                         request_qty                   --依頼数量
                 ,NULL                                      request_uom                   --依頼数量単位コード
                 ,TO_DATE( PLA.attribute5 )                 vendor_dlvr_date              --仕入先出荷日
                 ,TO_NUMBER( PLA.attribute6  ) * -1         vendor_dlvr_qty               --仕入先出荷数量
                 ,TO_NUMBER( PLA.attribute7  ) * -1         rcv_qty                       --受入数量
                 ,TO_NUMBER( PLA.attribute8  )              purchase_amt                  --仕入定価
                 ,TO_DATE( PLA.attribute9 )                 date_reserved                 --日付指定
                 ,PLA.attribute10                           order_uom                     --発注単位
                 ,TO_NUMBER( PLA.attribute11 ) * -1         order_qty                     --発注数量
                 ,PLA.attribute12                           party_dlvr_to                 --相手先在庫入庫先
                 ,PLA.attribute13                           fix_qty_flg                   --数量確定フラグ
                 ,PLA.attribute14                           fix_amt_flg                   --金額確定フラグ
                 ,PLA.cancel_flag                           cancel_flg                    --取消フラグ
                 ,PLA.attribute15                           description                   --摘要
                 ,PLA.created_by                            h_created_by                  --発注_作成者
                 ,PLA.creation_date                         h_creation_date               --発注_作成日
                 ,PLA.last_updated_by                       h_last_updated_by             --発注_最終更新者
                 ,PLA.last_update_date                      h_last_update_date            --発注_最終更新日
                 ,PLA.last_update_login                     h_last_update_login           --発注_最終更新ログイン
                 ,XRART.txns_date                           u_txns_date                   --受入実績日
                 ,XRART.uom                                 u_uom                         --受入単位
                 ,XRART.rcv_rtn_quantity * -1               u_rcv_rtn_quantity            --受入返品数量
                 ,XRART.rcv_rtn_uom                         u_rcv_rtn_uom                 --受入返品単位
                 ,XRART.conversion_factor                   u_conversion_factor           --受入返品換算入数
                 ,XRART.kobiki_rate                         kobiki_rate                   --粉引率
                 ,XRART.kobki_converted_unit_price          kobki_converted_unit_price    --粉引後単価
                 ,XRART.kousen_type                         kousen_type                   --口銭区分
                 ,XRART.kousen_rate_or_unit_price           kousen_rate_or_unit_price     --口銭
                 ,XRART.kousen_price * -1                   kousen_price                  --預り口銭金額
                 ,XRART.fukakin_type                        fukakin_type                  --賦課金区分
                 ,XRART.fukakin_rate_or_unit_price          fukakin_rate_or_unit_price    --賦課金
                 ,XRART.fukakin_price * -1                  fukakin_price                 --賦課金額
-- 2012/07/23 H.Nakamura Del Start E_本稼動_09828
--                 ,XRART.kobki_converted_price * -1          kobki_converted_price         --粉引後金額
-- 2012/07/23 H.Nakamura Del End E_本稼動_09828
-- 2012/07/23 H.Nakamura Add Start E_本稼動_09828
                 ,ROUND(NVL( TO_NUMBER( XRART.kobki_converted_unit_price ), 0 ) * NVL( XRART.quantity, 0 ) * -1)
                                                            kobki_converted_price         --粉引後金額（粉引後単価×受入返品実績(アドオン).数量）
-- 2012/07/23 H.Nakamura Add End E_本稼動_09828
                 ,XRART.created_by                          u_created_by                  --受入_作成者
                 ,XRART.creation_date                       u_creation_date               --受入_作成日
                 ,XRART.last_updated_by                     u_last_updated_by             --受入_最終更新者
                 ,XRART.last_update_date                    u_last_update_date            --受入_最終更新日
                 ,XRART.last_update_login                   u_last_update_login           --受入_最終更新ログイン
                  --名称取得用基準日
                 ,TO_DATE( PHA.attribute4 )                 deliver_date                  --納入日
            FROM
                  po_headers_all                            PHA                           --発注ヘッダ
                 ,po_lines_all                              PLA                           --発注明細
                 ,mtl_system_items_b                        MSIB                          --INV品目マスタ(OPM品目ID変換用)
                 ,ic_item_mst_b                             IIMB                          --OPM品目マスタ(OPM品目ID変換用)
                 ,xxpo_rcv_and_rtn_txns                     XRART                         --受入返品実績(アドオン)
           WHERE
             --発注ヘッダとの結合
                  PHA.po_header_id                          = PLA.po_header_id
             --INV品目ID⇒OPM品目ID 変換
             AND  PLA.item_id                               = MSIB.inventory_item_id
             AND  MSIB.organization_id                      = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
             AND  MSIB.segment1                             = IIMB.item_no
             --受入返品実績アドオン   ⇒外部結合しない
             AND  XRART.txns_type                           = '2'                         -- 実績区分:'2:発注あり返品'
             AND  PHA.segment1                              = XRART.source_document_number
             AND  PLA.line_num                              = XRART.source_document_line_num
          --[ 発注あり返品データ  END ]
        UNION ALL
          --========================================================================
          -- 発注無し返品データ （受入実績区分 = '3'）
          --========================================================================
          SELECT
                  'Dummy'                                   po_number                     --発注番号（発注データ無しなので 'Dummy' 固定）
                 ,XRART.rcv_rtn_number                      rcv_rtn_number                --受入返品番号（返品データなので返品番号が必ず存在する）
                 ,XRART.rcv_rtn_line_number                 line_num                      --明細番号
                 ,XRART.item_id                             item_id                       --品目ID(OPM品目ID)
                 ,XRART.unit_price                          unit_price                    --単価
                 ,XRART.quantity * -1                       quantity                      --数量
                 ,XRART.lot_number                          lot_no                        --ロット番号
                 ,XRART.factory_code                        factory_code                  --工場コード
                 ,XRART.futai_code                          futai_code                    --付帯コード
                 ,TO_NUMBER( LOT.attribute6 )               pack_qty                      --在庫入数
                 ,0                                         request_qty                   --依頼数量
                 ,NULL                                      request_uom                   --依頼数量単位コード
                 ,NULL                                      vendor_dlvr_date              --仕入先出荷日
                 ,0                                         vendor_dlvr_qty               --仕入先出荷数量
                 ,0                                         rcv_qty                       --受入数量
                 ,0                                         purchase_amt                  --仕入定価
                 ,NULL                                      date_reserved                 --日付指定
                 ,NULL                                      order_uom                     --発注単位
                 ,0                                         order_qty                     --発注数量
                 ,NULL                                      party_dlvr_to                 --相手先在庫入庫先
                 ,NULL                                      fix_qty_flg                   --数量確定フラグ
                 ,NULL                                      fix_amt_flg                   --金額確定フラグ
                 ,'N'                                       cancel_flg                    --取消フラグ
                 ,NULL                                      description                   --摘要
                 ,NULL                                      h_created_by                  --発注_作成者
                 ,NULL                                      h_creation_date               --発注_作成日
                 ,NULL                                      h_last_updated_by             --発注_最終更新者
                 ,NULL                                      h_last_update_date            --発注_最終更新日
                 ,NULL                                      h_last_update_login           --発注_最終更新ログイン
                 ,XRART.txns_date                           u_txns_date                   --受入実績日
                 ,XRART.uom                                 u_uom                         --受入単位
                 ,XRART.rcv_rtn_quantity * -1               u_rcv_rtn_quantity            --受入返品数量
                 ,XRART.rcv_rtn_uom                         u_rcv_rtn_uom                 --受入返品単位
                 ,XRART.conversion_factor                   u_conversion_factor           --受入返品換算入数
                 ,XRART.kobiki_rate                         kobiki_rate                   --粉引率
                 ,XRART.kobki_converted_unit_price          kobki_converted_unit_price    --粉引後単価
                 ,XRART.kousen_type                         kousen_type                   --口銭区分
                 ,XRART.kousen_rate_or_unit_price           kousen_rate_or_unit_price     --口銭
                 ,XRART.kousen_price * -1                   kousen_price                  --預り口銭金額
                 ,XRART.fukakin_type                        fukakin_type                  --賦課金区分
                 ,XRART.fukakin_rate_or_unit_price          fukakin_rate_or_unit_price    --賦課金
                 ,XRART.fukakin_price * -1                  fukakin_price                 --賦課金額
-- 2012/07/23 H.Nakamura Del Start E_本稼動_09828
--                 ,XRART.kobki_converted_price * -1          kobki_converted_price         --粉引後金額
-- 2012/07/23 H.Nakamura Del End E_本稼動_09828
-- 2012/07/23 H.Nakamura Add Start E_本稼動_09828
                 ,ROUND(NVL( TO_NUMBER( XRART.kobki_converted_unit_price ), 0 ) * NVL( XRART.quantity, 0 ) * -1)
                                                            kobki_converted_price         --粉引後金額（粉引後単価×受入返品実績(アドオン).数量）
-- 2012/07/23 H.Nakamura Add End E_本稼動_09828
                 ,XRART.created_by                          u_created_by                  --受入_作成者
                 ,XRART.creation_date                       u_creation_date               --受入_作成日
                 ,XRART.last_updated_by                     u_last_updated_by             --受入_最終更新者
                 ,XRART.last_update_date                    u_last_update_date            --受入_最終更新日
                 ,XRART.last_update_login                   u_last_update_login           --受入_最終更新ログイン
                  --名称取得用基準日
                 ,XRART.txns_date                           deliver_date                  --納入日
            FROM
                  xxpo_rcv_and_rtn_txns                     XRART                         --受入返品実績(アドオン)
                 ,ic_lots_mst                               LOT                           --ロットマスタ
           WHERE
                  XRART.txns_type                           = '3'                         --実績区分:'3:発注無し返品'
             --ロットマスタとの結合
             AND  XRART.item_id                             = LOT.item_id(+)
             AND  XRART.lot_id                              = LOT.lot_id(+)
          --[ 発注無し返品データ  END ]
       )                                          POL                           --発注受入明細データ
       ------------------------------------------
       -- 以下、名称取得用
       ------------------------------------------
       ,xxskz_item_mst2_v                         ITEM                          --SKYLINK用中間VIEW 品目マスタVIEW2
       ,xxskz_prod_class_v                        PRODC                         --商品区分取得用
       ,xxskz_item_class_v                        ITEMC                         --品目区分取得用
       ,xxskz_crowd_code_v                        CROWD                         --群コード取得用
       ,ic_lots_mst                               LOT                           --ロット情報取得用
       ,xxskz_vendor_sites2_v                     VDST                          --SKYLINK用中間VIEW 仕入先サイト情報VIEW2(工場名)
       ,xxskz_item_locations_v                    ILOC                          --SKYLINK用中間VIEW OPM保管場所情報VIEW2(相手先在庫入庫先名)
       ,fnd_user                                  FU_CB_H                       --ユーザーマスタ(発注_created_by名称取得用)
       ,fnd_user                                  FU_LU_H                       --ユーザーマスタ(発注_last_updated_by名称取得用)
       ,fnd_user                                  FU_LL_H                       --ユーザーマスタ(発注_last_update_login名称取得用)
       ,fnd_logins                                FL_LL_H                       --ログインマスタ(発注_last_update_login名称取得用)
       ,fnd_user                                  FU_CB_U                       --ユーザーマスタ(受入返品_created_by名称取得用)
       ,fnd_user                                  FU_LU_U                       --ユーザーマスタ(受入返品_last_updated_by名称取得用)
       ,fnd_user                                  FU_LL_U                       --ユーザーマスタ(受入返品_last_update_login名称取得用)
       ,fnd_logins                                FL_LL_U                       --ログインマスタ(受入返品_last_update_login名称取得用)
       ,fnd_lookup_values                         FLV01                         --クイックコード(数量確定フラグ名)
       ,fnd_lookup_values                         FLV02                         --クイックコード(金額確定フラグ名)
       ,fnd_lookup_values                         FLV03                         --クイックコード(取消フラグ名)
       ,fnd_lookup_values                         FLV04                         --クイックコード(口銭区分名)
       ,fnd_lookup_values                         FLV05                         --クイックコード(賦課金区分名)
 WHERE
   --品目情報取得
        POL.item_id                               = ITEM.item_id(+)
   AND  NVL( POL.deliver_date, SYSDATE )         >= ITEM.start_date_active(+)
   AND  NVL( POL.deliver_date, SYSDATE )         <= ITEM.end_date_active(+)
   --品目カテゴリ情報取得
   AND  POL.item_id                               = PRODC.item_id(+)            --商品区分
   AND  POL.item_id                               = ITEMC.item_id(+)            --品目区分
   AND  POL.item_id                               = CROWD.item_id(+)            --群コード
   --ロット情報取得
   AND  POL.item_id                               = LOT.item_id(+)
   AND  POL.lot_no                                = LOT.lot_no(+)
   --工場名取得
   AND  POL.factory_code                          = VDST.vendor_site_code(+)
   AND  NVL( POL.deliver_date, SYSDATE )         >= VDST.start_date_active(+)
   AND  NVL( POL.deliver_date, SYSDATE )         <= VDST.end_date_active(+)
   --相手先在庫入庫先名取得
   AND  POL.party_dlvr_to                         = ILOC.segment1(+)
   --発注明細のWHOカラム情報取得
   AND  POL.h_created_by                          = FU_CB_H.user_id(+)
   AND  POL.h_last_updated_by                     = FU_LU_H.user_id(+)
   AND  POL.h_last_update_login                   = FL_LL_H.login_id(+)
   AND  FL_LL_H.user_id                           = FU_LL_H.user_id(+)
   --受入返品明細のWHOカラム情報取得
   AND  POL.u_created_by                          = FU_CB_U.user_id(+)
   AND  POL.u_last_updated_by                     = FU_LU_U.user_id(+)
   AND  POL.u_last_update_login                   = FL_LL_U.login_id(+)
   AND  FL_LL_U.user_id                           = FU_LL_U.user_id(+)
   --【クイックコード】数量確定フラグ名
   AND  FLV01.language(+)                         = 'JA'
   AND  FLV01.lookup_type(+)                      = 'XXCMN_YESNO'
   AND  FLV01.lookup_code(+)                      = POL.fix_qty_flg
   --【クイックコード】金額確定フラグ名
   AND  FLV02.language(+)                         = 'JA'
   AND  FLV02.lookup_type(+)                      = 'XXCMN_YESNO'
   AND  FLV02.lookup_code(+)                      = POL.fix_amt_flg
   --【クイックコード】取消フラグ名
   AND  FLV03.language(+)                         = 'JA'
   AND  FLV03.lookup_type(+)                      = 'XXCMN_YESNO'
   AND  FLV03.lookup_code(+)                      = NVL( POL.cancel_flg, 'N' )
   --【クイックコード】口銭区分名
   AND  FLV04.language(+)                         = 'JA'
   AND  FLV04.lookup_type(+)                      = 'XXPO_KOUSEN_TYPE'
   AND  FLV04.lookup_code(+)                      = POL.kousen_type
   --【クイックコード】賦課金区分名
   AND  FLV05.language(+)                         = 'JA'
   AND  FLV05.lookup_type(+)                      = 'XXPO_FUKAKIN_TYPE'
   AND  FLV05.lookup_code(+)                      = POL.fukakin_type
/
COMMENT ON TABLE APPS.XXSKZ_発注受入明細_基本_V IS 'SKYLINK用発注受入明細（基本）VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入明細_基本_V.発注番号 IS '発注番号'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入明細_基本_V.受入返品番号 IS '受入返品番号'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入明細_基本_V.明細番号 IS '明細番号'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入明細_基本_V.商品区分 IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入明細_基本_V.商品区分名 IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入明細_基本_V.品目区分 IS '品目区分'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入明細_基本_V.品目区分名 IS '品目区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入明細_基本_V.群コード IS '群コード'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入明細_基本_V.品目コード IS '品目コード'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入明細_基本_V.品目名 IS '品目名'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入明細_基本_V.品目略称 IS '品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入明細_基本_V.単価 IS '単価'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入明細_基本_V.数量 IS '数量'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入明細_基本_V.ロット番号 IS 'ロット番号'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入明細_基本_V.製造年月日 IS '製造年月日'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入明細_基本_V.固有記号 IS '固有記号'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入明細_基本_V.賞味期限 IS '賞味期限'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入明細_基本_V.工場コード IS '工場コード'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入明細_基本_V.工場名 IS '工場名'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入明細_基本_V.付帯コード IS '付帯コード'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入明細_基本_V.在庫入数 IS '在庫入数'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入明細_基本_V.依頼数量 IS '依頼数量'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入明細_基本_V.依頼数量単位コード IS '依頼数量単位コード'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入明細_基本_V.仕入先出荷日 IS '仕入先出荷日'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入明細_基本_V.仕入先出荷数量 IS '仕入先出荷数量'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入明細_基本_V.受入数量 IS '受入数量'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入明細_基本_V.仕入定価 IS '仕入定価'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入明細_基本_V.日付指定 IS '日付指定'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入明細_基本_V.発注単位 IS '発注単位'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入明細_基本_V.発注数量 IS '発注数量'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入明細_基本_V.相手先在庫入庫先 IS '相手先在庫入庫先'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入明細_基本_V.相手先在庫入庫先名 IS '相手先在庫入庫先名'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入明細_基本_V.数量確定フラグ IS '数量確定フラグ'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入明細_基本_V.数量確定フラグ名 IS '数量確定フラグ名'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入明細_基本_V.金額確定フラグ IS '金額確定フラグ'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入明細_基本_V.金額確定フラグ名 IS '金額確定フラグ名'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入明細_基本_V.取消フラグ IS '取消フラグ'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入明細_基本_V.取消フラグ名 IS '取消フラグ名'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入明細_基本_V.摘要 IS '摘要'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入明細_基本_V.発注_作成者 IS '発注_作成者'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入明細_基本_V.発注_作成日 IS '発注_作成日'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入明細_基本_V.発注_最終更新者 IS '発注_最終更新者'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入明細_基本_V.発注_最終更新日 IS '発注_最終更新日'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入明細_基本_V.発注_最終更新ログイン IS '発注_最終更新ログイン'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入明細_基本_V.受入実績日 IS '受入実績日'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入明細_基本_V.受入単位 IS '受入単位'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入明細_基本_V.受入返品数量 IS '受入返品数量'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入明細_基本_V.受入返品単位 IS '受入返品単位'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入明細_基本_V.受入返品換算入数 IS '受入返品換算入数'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入明細_基本_V.粉引率 IS '粉引率'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入明細_基本_V.粉引後単価 IS '粉引後単価'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入明細_基本_V.口銭区分 IS '口銭区分'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入明細_基本_V.口銭区分名 IS '口銭区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入明細_基本_V.口銭 IS '口銭'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入明細_基本_V.預り口銭金額 IS '預り口銭金額'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入明細_基本_V.賦課金区分 IS '賦課金区分'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入明細_基本_V.賦課金区分名 IS '賦課金区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入明細_基本_V.賦課金 IS '賦課金'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入明細_基本_V.賦課金額 IS '賦課金額'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入明細_基本_V.粉引後金額 IS '粉引後金額'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入明細_基本_V.受入_作成者 IS '受入_作成者'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入明細_基本_V.受入_作成日 IS '受入_作成日'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入明細_基本_V.受入_最終更新者 IS '受入_最終更新者'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入明細_基本_V.受入_最終更新日 IS '受入_最終更新日'
/
COMMENT ON COLUMN APPS.XXSKZ_発注受入明細_基本_V.受入_最終更新ログイン IS '受入_最終更新ログイン'
/
