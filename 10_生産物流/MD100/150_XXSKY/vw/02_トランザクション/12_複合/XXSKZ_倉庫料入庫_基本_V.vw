/*************************************************************************
 * 
 * View  Name      : XXSKZ_倉庫料入庫_基本_V
 * Description     : XXSKZ_倉庫料入庫_基本_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2012/11/28    1.0   SCSK 月野    初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_倉庫料入庫_基本_V
(
 入庫先保管場所
,入庫先保管場所名
,入庫先保管場所略称
,出庫形態
,出庫実績日
,入庫実績日
,出庫元保管場所
,出庫元保管場所名
,出庫元保管場所略称
,商品区分
,商品区分名
,品目区分
,品目区分名
,群コード
,品目コード
,品目名
,品目略称
,ロットNO
,製造年月日
,固有記号
,賞味期限
,実績数量
,実績ケース数量
)
AS
SELECT
        MRO.ship_to                ship_to             -- 入庫先保管場所
       ,ILOC.description           ship_to_name        -- 入庫先保管場所名
       ,ILOC.short_name            ship_to_s_name      -- 入庫先保管場所略称
       ,MRO.syukoform              syukoform           -- 出庫形態
       ,MRO.shipped_date           shipped_date        -- 出庫実績日
       ,MRO.arrival_date           arrival_date        -- 入庫実績日
       ,MRO.ship_from              ship_from           -- 出庫元保管場所
       ,MRO.ship_from_name         ship_from_name      -- 出庫元保管場所名
       ,MRO.ship_from_s_name       ship_from_s_name    -- 出庫元保管場所名
       ,PRODC.prod_class_code      prod_class_code     -- 商品区分
       ,PRODC.prod_class_name      prod_class_name     -- 商品区分名
       ,ITEMC.item_class_code      item_class_code     -- 品目区分
       ,ITEMC.item_class_name      item_class_name     -- 品目区分名
       ,CROWD.crowd_code           crowd_code          -- 群コード
       ,MRO.item_code              item_code           -- 品目コード
       ,ITEM.item_name             item_name           -- 品目名
       ,ITEM.item_short_name       item_s_name         -- 品目略称
       ,NVL( DECODE( MRO.lot_no, 'DEFAULTLOT', '0', MRO.lot_no ), '0' )
                                   lot_no              -- ロットNo('DEFALTLOT'、ロット未割当は'0')
       ,CASE WHEN ITEM.lot_ctl = 1 THEN LOT.attribute1    --ロット管理品   →ロットNOを取得
             ELSE NULL                                    --非ロット管理品 →NULL
        END                        seizou_ymd          -- 製造年月日
       ,CASE WHEN ITEM.lot_ctl = 1 THEN LOT.attribute2    --ロット管理品   →ロットNOを取得
             ELSE NULL                                    --非ロット管理品 →NULL
        END                        koyu_kigo           -- 固有記号
       ,CASE WHEN ITEM.lot_ctl = 1 THEN LOT.attribute3    --ロット管理品   →ロットNOを取得
             ELSE NULL                                    --非ロット管理品 →NULL
        END                        syoumi_ymd          -- 賞味期限
       ,MRO.quantity               quantity            -- 実績数量
       ,TRUNC( MRO.quantity / ITEM.num_of_cases )
                                   quantity            -- 実績ケース数量
  FROM ( --入庫実績データを取得
          --=====================================================================
          -- 移動 入庫実績データ
          --=====================================================================
          SELECT
                  XMRIH.ship_to_locat_code        ship_to             -- 入庫先保管場所
                 ,'移動'                          syukoform           -- 出庫形態
                 ,NVL( XMRIH.actual_ship_date   , XMRIH.schedule_ship_date    )
                                                  shipped_date        -- 出庫実績日
                 ,NVL( XMRIH.actual_arrival_date, XMRIH.schedule_arrival_date )
                                                  arrival_date        -- 入庫実績日
                 ,XMRIH.shipped_locat_code        ship_from           -- 出庫元保管場所
                 ,ILOC.description                ship_from_name      -- 出庫元保管場所名
                 ,ILOC.short_name                 ship_from_s_name    -- 出庫元保管場所略称
                 ,XMLD.item_id                    item_id             -- 品目コード
                 ,XMLD.item_code                  item_code           -- 品目コード
                 ,XMLD.lot_id                     lot_id              -- ロットID
                 ,XMLD.lot_no                     lot_no              -- ロットNo
                 ,XMLD.actual_quantity            quantity            -- 実績数量
            FROM
                  xxcmn_mov_req_instr_hdrs_arc     XMRIH              -- 移動依頼/指示ヘッダ（アドオン）バックアップ
                 ,xxcmn_mov_req_instr_lines_arc    XMRIL              -- 移動依頼/指示明細（アドオン）バックアップ
                 ,xxcmn_mov_lot_details_arc           XMLD            -- 移動ロット詳細（アドオン）バックアップ
                 ,xxskz_item_locations2_v         ILOC                -- SKYLINK用中間VIEW OPM保管場所情報VIEW(出庫元保管場所名取得用)
           WHERE
             -- 移動 入庫情報取得
                  XMRIH.status                    IN ( '05', '06' )   -- '05:入庫報告あり'、'06:入出庫報告あり'
             -- 移動明細情報取得
             AND  NVL( XMRIL.delete_flg, 'N' )   <> 'Y'               -- 無効明細以外
             AND  XMRIH.mov_hdr_id                = XMRIL.mov_hdr_id
             -- 移動ロット詳細情報取得
             AND  XMLD.document_type_code         = '20'              -- 移動
             AND  XMLD.record_type_code           = '30'              -- 入庫実績
             AND  XMRIL.mov_line_id               = XMLD.mov_line_id
             -- 出庫元保管場所名取得
             AND  XMRIH.shipped_locat_id          = ILOC.inventory_location_id(+)
          --[ 移動 入庫実績データ  END ]
         UNION ALL
          --=====================================================================
          -- 発注受入 入庫実績データ
          --   ⇒取消しデータ除外の為に発注情報と結合
          --=====================================================================
          SELECT
                  XRART.location_code             ship_to             -- 入庫先保管場所
                 ,FLV01.meaning                   syukoform           -- 出庫形態
                 ,XRART.txns_date                 shipped_date        -- 出庫実績日
                 ,XRART.txns_date                 arrival_date        -- 入庫実績日
                 ,XRART.vendor_code               ship_from           -- 出庫元保管場所
                 ,VNDR.vendor_name                ship_from_name      -- 出庫元保管場所名
                 ,VNDR.vendor_short_name          ship_from_s_name    -- 出庫元保管場所略称
                 ,XRART.item_id                   item_id             -- 品目ID
                 ,XRART.item_code                 item_code           -- 品目コード
                 ,XRART.lot_id                    lot_id              -- ロットID
                 ,XRART.lot_number                lot_no              -- ロットNo
                 ,XRART.quantity                  quantity            -- 実績数量
            FROM
                  xxpo_rcv_and_rtn_txns           XRART               -- 受入返品実績アドオン
                 ,po_headers_all                  PHA                 -- 発注ヘッダ
                 ,po_lines_all                    PLA                 -- 発注明細
                 ,xxskz_vendors2_v                VNDR                -- SKYLINK用中間VIEW 仕入先情報VIEW(取引先名)
                 ,fnd_lookup_values               FLV01               -- クイックコード(実績区分名)
           WHERE
             --発注受入･発注あり返品データの取得
                  XRART.txns_type                 = '1'               -- '1:発注受入実績'
             --発注データとの結合
             AND  NVL( PLA.cancel_flag, 'N' )    <> 'Y'               -- キャンセル以外
             AND  NVL( PLA.attribute13, 'N' )     = 'Y'               -- 承諾済
             AND  XRART.source_document_number              = PHA.segment1
             AND  XRART.source_document_line_num            = PLA.line_num
             AND  PHA.po_header_id                          = PLA.po_header_id
             -- 取引先名情報取得
             AND  XRART.vendor_id                 = VNDR.vendor_id(+)
             AND  XRART.txns_date                >= VNDR.start_date_active(+)
             AND  XRART.txns_date                <= VNDR.end_date_active(+)
             --【クイックコード】実績区分名
             AND  FLV01.language(+)               = 'JA'
             AND  FLV01.lookup_type(+)            = 'XXPO_TXNS_TYPE'
             AND  FLV01.lookup_code(+)            = XRART.txns_type
          --[ 発注受入 入庫実績データ  END ]
         UNION ALL
          --=====================================================================
          -- 発注あり返品・発注無し返品 入庫実績データ
          --   ⇒発注あり返品に取消しはあり得ないので発注データとの結合は不要
          --=====================================================================
          SELECT
                  XRART.location_code             ship_to             -- 入庫先保管場所
                 ,FLV01.meaning                   syukoform           -- 出庫形態
                 ,XRART.txns_date                 shipped_date        -- 出庫実績日
                 ,XRART.txns_date                 arrival_date        -- 入庫実績日
                 ,XRART.vendor_code               ship_from           -- 出庫元保管場所
                 ,VNDR.vendor_name                ship_from_name      -- 出庫元保管場所名
                 ,VNDR.vendor_short_name          ship_from_s_name    -- 出庫元保管場所略称
                 ,XRART.item_id                   item_id             -- 品目ID
                 ,XRART.item_code                 item_code           -- 品目コード
                 ,XRART.lot_id                    lot_id              -- ロットID
                 ,XRART.lot_number                lot_no              -- ロットNo
                 ,XRART.quantity * -1             quantity            -- 実績数量(返品データなのでマイナス値)
            FROM
                  xxpo_rcv_and_rtn_txns           XRART               -- 受入返品実績アドオン
                 ,xxskz_vendors2_v                VNDR                -- SKYLINK用中間VIEW 仕入先情報VIEW(取引先名)
                 ,fnd_lookup_values               FLV01               -- クイックコード(実績区分名)
           WHERE
             -- 発注無し返品データ取得
                  XRART.txns_type                 IN ( '2', '3' )     -- '2:発注無し返品'、'3:発注無し返品'
             -- 取引先名情報取得
             AND  XRART.vendor_id                 = VNDR.vendor_id(+)
             AND  XRART.txns_date                >= VNDR.start_date_active(+)
             AND  XRART.txns_date                <= VNDR.end_date_active(+)
             --【クイックコード】実績区分名
             AND  FLV01.language(+)               = 'JA'
             AND  FLV01.lookup_type(+)            = 'XXPO_TXNS_TYPE'
             AND  FLV01.lookup_code(+)            = XRART.txns_type
          --[ 発注あり返品・発注無し返品 入庫実績データ  END ]
         UNION ALL
          --===============================================
          -- 倉替返品 入庫実績データ
          --===============================================
          SELECT
                  KRHN.ship_to                    ship_to             -- 入庫先保管場所
                 ,KRHN.syukoform                  syukoform           -- 出庫形態
                 ,KRHN.shipped_date               shipped_date        -- 出庫実績日
                 ,KRHN.arrival_date               arrival_date        -- 入庫実績日
                 ,KRHN.ship_from                  ship_from           -- 出庫元保管場所
                 ,PSITE.party_site_name           ship_from_name      -- 出庫元保管場所名
                 ,PSITE.party_site_short_name     ship_from_s_name    -- 出庫元保管場所略称
                 ,KRHN.item_id                    item_id             -- 品目ID
                 ,KRHN.item_code                  item_code           -- 品目コード
                 ,KRHN.lot_id                     lot_id              -- ロットID
                 ,KRHN.lot_no                     lot_no              -- ロットNo
                 ,KRHN.quantity                   quantity            -- 実績数量
            FROM (  --外部結合の為に副問い合わせ
                    SELECT
                            XOHA.deliver_from          ship_to        -- 入庫先保管場所
                           ,OTTT.name                  syukoform      -- 出庫形態
                           ,NVL( XOHA.shipped_date, XOHA.schedule_ship_date    )
                                                       shipped_date   -- 出庫実績日
                           ,NVL( XOHA.arrival_date, XOHA.schedule_arrival_date )
                                                       arrival_date   -- 入庫実績日
                           ,NVL( XOHA.result_deliver_to_id, XOHA.deliver_to_id )
                                                       ship_from_id   -- 出庫元保管場所ID
                           ,CASE WHEN XOHA.result_deliver_to_id IS NULL THEN XOHA.deliver_to           --出荷先_実績IDが存在しない場合は出荷先
                                 ELSE                                        XOHA.result_deliver_to    --出荷先_実績IDが存在する場合は出荷先_実績
                            END                        ship_from      -- 出庫元保管場所
                           ,XMLD.item_id               item_id        -- 品目ID
                           ,XMLD.item_code             item_code      -- 品目コード
                           ,XMLD.lot_id                lot_id         -- ロットID
                           ,XMLD.lot_no                lot_no         -- ロットNO
                           ,XMLD.actual_quantity * DECODE( OTTA.order_category_code, 'ORDER', -1, 1 )
                                                       quantity       -- 実績数量(取消の場合はマイナス値)
                      FROM
                            xxcmn_order_headers_all_arc    XOHA       -- 受注ヘッダ（アドオン）バックアップ
                           ,xxcmn_order_lines_all_arc      XOLA       -- 受注明細（アドオン）バックアップ
                           ,xxcmn_mov_lot_details_arc      XMLD       -- 移動ロット詳細（アドオン）バックアップ
                           ,oe_transaction_types_all   OTTA           -- 受注タイプマスタ
                           ,oe_transaction_types_tl    OTTT           -- 受注タイプマスタ(日本語)
                     WHERE
                       -- 倉替返品データ取得
                            OTTA.attribute1            = '3'          -- '3':倉替返品
                       AND  XOHA.req_status            = '04'         -- '実績計上済'
                       AND  XOHA.latest_external_flag  = 'Y'          -- 最新フラグ
                       AND  XOHA.order_type_id         = OTTA.transaction_type_id
                       -- 受注明細情報取得
                       AND  NVL( XOLA.delete_flag, 'N' ) <> 'Y'       -- 無効明細以外
                       AND  XOHA.order_header_id       = XOLA.order_header_id
                       -- 移動ロット詳細情報取得
                       AND  XMLD.document_type_code    = '10'         -- '10:出荷依頼'
                       AND  XMLD.record_type_code      = '20'         -- '20:出庫実績'
                       AND  XOLA.order_line_id         = XMLD.mov_line_id
                       -- 受注タイプ名取得
                       AND  OTTT.language(+)           = 'JA'
                       AND  XOHA.order_type_id         = OTTT.transaction_type_id(+)
               )                                  KRHN                -- 倉替返品データ
              ,xxskz_party_sites2_v               PSITE               -- SKYLINK用中間VIEW 配送先情報VIEW2(出庫元保管場所名取得用)
          WHERE
            -- 出庫元保管場所名取得
                 KRHN.ship_from_id                = PSITE.party_site_id(+)
            AND  KRHN.arrival_date               >= PSITE.start_date_active(+)
            AND  KRHN.arrival_date               <= PSITE.end_date_active(+)
          --[ 倉替返品 入庫実績データ  END ]
        )                          MRO                 -- 移動＋受入返品＋倉替返品の入庫実績データ
        --以下名称取得用
       ,xxskz_item_locations_v     ILOC                -- SKYLINK用中間VIEW OPM保管場所情報VIEW(入庫先保管場所名取得用)
       ,xxskz_item_mst2_v          ITEM                -- SKYLINK用中間VIEW OPM品目情報VIEW
       ,xxskz_prod_class_v         PRODC               -- SKYLINK用商品区分取得VIEW
       ,xxskz_item_class_v         ITEMC               -- SKYLINK用品目区分取得VIEW
       ,xxskz_crowd_code_v         CROWD               -- SKYLINK用郡コード取得VIEW
       ,ic_lots_mst                LOT                 -- ロットマスタ
 WHERE
   -- 入庫先保管場所名取得
        MRO.ship_to                = ILOC.segment1(+)
   -- 品目情報取得
   AND  MRO.item_id                = ITEM.item_id(+)
   AND  MRO.arrival_date          >= ITEM.start_date_active(+)
   AND  MRO.arrival_date          <= ITEM.end_date_active(+)
   -- 品目カテゴリ情報取得
   AND  MRO.item_id                = PRODC.item_id(+)   -- 商品区分
   AND  MRO.item_id                = ITEMC.item_id(+)   -- 品目区分
   AND  MRO.item_id                = CROWD.item_id(+)   -- 群コード
   -- ロット情報取得
   AND  MRO.item_id                = LOT.item_id(+)
   AND  MRO.lot_id                 = LOT.lot_id(+)
/
COMMENT ON TABLE APPS.XXSKZ_倉庫料入庫_基本_V IS 'SKYLINK用倉庫料入庫基本VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_倉庫料入庫_基本_V.入庫先保管場所     IS '入庫先保管場所'
/
COMMENT ON COLUMN APPS.XXSKZ_倉庫料入庫_基本_V.入庫先保管場所名   IS '入庫先保管場所名'
/
COMMENT ON COLUMN APPS.XXSKZ_倉庫料入庫_基本_V.入庫先保管場所略称 IS '入庫先保管場所略称'
/
COMMENT ON COLUMN APPS.XXSKZ_倉庫料入庫_基本_V.出庫形態           IS '出庫形態'
/
COMMENT ON COLUMN APPS.XXSKZ_倉庫料入庫_基本_V.出庫実績日         IS '出庫実績日'
/
COMMENT ON COLUMN APPS.XXSKZ_倉庫料入庫_基本_V.入庫実績日         IS '入庫実績日'
/
COMMENT ON COLUMN APPS.XXSKZ_倉庫料入庫_基本_V.出庫元保管場所     IS '出庫元保管場所'
/
COMMENT ON COLUMN APPS.XXSKZ_倉庫料入庫_基本_V.出庫元保管場所名   IS '出庫元保管場所名'
/
COMMENT ON COLUMN APPS.XXSKZ_倉庫料入庫_基本_V.出庫元保管場所略称 IS '出庫元保管場所略称'
/
COMMENT ON COLUMN APPS.XXSKZ_倉庫料入庫_基本_V.商品区分           IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKZ_倉庫料入庫_基本_V.商品区分名         IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_倉庫料入庫_基本_V.品目区分           IS '品目区分'
/
COMMENT ON COLUMN APPS.XXSKZ_倉庫料入庫_基本_V.品目区分名         IS '品目区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_倉庫料入庫_基本_V.群コード           IS '群コード'
/
COMMENT ON COLUMN APPS.XXSKZ_倉庫料入庫_基本_V.品目コード         IS '品目コード'
/
COMMENT ON COLUMN APPS.XXSKZ_倉庫料入庫_基本_V.品目名             IS '品目名'
/
COMMENT ON COLUMN APPS.XXSKZ_倉庫料入庫_基本_V.品目略称           IS '品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_倉庫料入庫_基本_V.ロットNO           IS 'ロットNO'
/
COMMENT ON COLUMN APPS.XXSKZ_倉庫料入庫_基本_V.製造年月日         IS '製造年月日'
/
COMMENT ON COLUMN APPS.XXSKZ_倉庫料入庫_基本_V.固有記号           IS '固有記号'
/
COMMENT ON COLUMN APPS.XXSKZ_倉庫料入庫_基本_V.賞味期限           IS '賞味期限'
/
COMMENT ON COLUMN APPS.XXSKZ_倉庫料入庫_基本_V.実績数量           IS '実績数量'
/
COMMENT ON COLUMN APPS.XXSKZ_倉庫料入庫_基本_V.実績ケース数量     IS '実績ケース数量'
/
