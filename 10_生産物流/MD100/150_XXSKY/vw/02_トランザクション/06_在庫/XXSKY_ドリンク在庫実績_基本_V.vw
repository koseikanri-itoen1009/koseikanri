CREATE OR REPLACE VIEW APPS.XXSKY_ドリンク在庫実績_基本_V
(
 対象年月
,倉庫コード
,倉庫名
,保管場所コード
,保管場所名
,保管場所略称
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
,固有記号
,賞味期限
,棚卸ケース数
,棚卸バラ数
,積送中在庫ケース数
,積送中在庫バラ数
,論理_月末在庫ケース数
,論理_月末在庫バラ数
,返品_月間入庫ケース数
,返品_月間入庫バラ数
,生産_月間入庫ケース数
,生産_月間入庫バラ数
,移動_月間入庫ケース数
,移動_月間入庫バラ数
,その他_月間入庫ケース数
,その他_月間入庫バラ数
,拠点_月間出庫ケース数
,拠点_月間出庫バラ数
,移動_月間出庫ケース数
,移動_月間出庫バラ数
,その他_月間出庫ケース数
,その他_月間出庫バラ数
)
AS
SELECT
        STRN.yyyymm                                         yyyymm              --年月
       ,STRN.whse_code                                      whse_code           --倉庫コード
       ,IWM.whse_name                                       whse_name           --倉庫名
       ,STRN.location                                       location            --保管場所コード
       ,ILOC.description                                    loct_name           --保管場所名
       ,ILOC.short_name                                     loct_s_name         --保管場所略称
       ,PRODC.prod_class_code                               prod_class_code     --商品区分
       ,PRODC.prod_class_name                               prod_class_name     --商品区分名
       ,ITEMC.item_class_code                               item_class_code     --品目区分
       ,ITEMC.item_class_name                               item_class_name     --品目区分名
       ,CROWD.crowd_code                                    crowd_code          --群コード
       ,ITEM.item_no                                        item_code           --品目
       ,ITEM.item_name                                      item_name           --品目名
       ,ITEM.item_short_name                                item_s_name         --品目略称
       ,ILM.lot_no                                          lot_no              --ロットNo
       ,ILM.attribute1                                      lot_date            --製造年月日
       ,ILM.attribute2                                      lot_sign            --固有記号
       ,ILM.attribute3                                      best_bfr_date       --賞味期限
       ,NVL( STRN.stc_r_cs_qty, 0 )                         stc_r_cs_qty        --棚卸ケース数
       ,NVL( STRN.stc_r_qty   , 0 )                         stc_r_qty           --棚卸バラ数
       ,NVL( TRUNC( STRN.cargo_qty   / ITEM.num_of_cases ), 0 )
                                                            cargo_cs_qty        --積送中ケース数
       ,NVL( STRN.cargo_qty   , 0 )                         cargo_qty           --積送中バラ数
       ,NVL( TRUNC( STRN.month_qty   / ITEM.num_of_cases ), 0 )
                                                            month_cs_qty        --論理_月末在庫ケース数
       ,NVL( STRN.month_qty   , 0 )                         month_qty           --論理_月末在庫バラ数
       ,NVL( TRUNC( STRN.rev_in_qty  / ITEM.num_of_cases ), 0 )
                                                            rev_in_cs_qty       --返品_月間入庫ケース数(受入返品)
       ,NVL( STRN.rev_in_qty  , 0 )                         rev_in_qty          --返品_月間入庫バラ数(受入返品)
       ,NVL( TRUNC( STRN.po_in_qty   / ITEM.num_of_cases ), 0 )
                                                            po_in_cs_qty        --生産_月間入庫ケース数(受入)
       ,NVL( STRN.po_in_qty   , 0 )                         po_in_qty           --生産_月間入庫バラ数(受入)
       ,NVL( TRUNC( STRN.mov_in_qty  / ITEM.num_of_cases ), 0 )
                                                            mov_in_cs_qty       --移動_月間入庫ケース数
       ,NVL( STRN.mov_in_qty  , 0 )                         mov_in_qty          --移動_月間入庫バラ数
       ,NVL( TRUNC( STRN.etc_in_qty  / ITEM.num_of_cases ), 0 )
                                                            etc_in_cs_qty       --その他_月間入庫ケース数
       ,NVL( STRN.etc_in_qty  , 0 )                         etc_in_qty          --その他_月間入庫バラ数
       ,NVL( TRUNC( STRN.oe_out_qty  / ITEM.num_of_cases ), 0 )
                                                            oe_out_cs_qty       --拠点_月間出庫ケース数(出荷)
       ,NVL( STRN.oe_out_qty  , 0 )                         oe_out_qty          --拠点_月間出庫バラ数(出荷)
       ,NVL( TRUNC( STRN.mov_out_qty / ITEM.num_of_cases ), 0 )
                                                            mov_out_cs_qty      --移動_月間出庫ケース数
       ,NVL( STRN.mov_out_qty , 0 )                         mov_out_qty         --移動_月間出庫バラ数
       ,NVL( TRUNC( STRN.etc_out_qty / ITEM.num_of_cases ), 0 )
                                                            etc_out_cs_qty      --その他_月間出庫ケース数
       ,NVL( STRN.etc_out_qty , 0 )                         etc_out_qty         --その他_月間出庫バラ数
  FROM
        (  --年月、倉庫コード、保管場所コード、品目ID、ロットID単位で集計
           SELECT
                    TRAN.yyyymm                             yyyymm              --年月
                   ,TRAN.whse_code                          whse_code           --倉庫コード
                   ,TRAN.location                           location            --保管場所コード
                   ,TRAN.item_id                            item_id             --品目ID
                   ,TRAN.lot_id                             lot_id              --ロットID
                   ,SUM( TRAN.stc_r_cs_qty )                stc_r_cs_qty        --棚卸ケース数
                   ,SUM( TRAN.stc_r_qty    )                stc_r_qty           --棚卸バラ数
                   ,SUM( TRAN.cargo_qty    )                cargo_qty           --積送中バラ数
                    --月末在庫数は棚卸月末在庫テーブルの最大年月の次月までを出力する（それ以降は月首在庫数を取得しないので求まらない）
                   ,SUM( CASE WHEN TRAN.yyyymm <= MYM.yyyymm THEN TRAN.month_qty END )
                                                            month_qty           --月末在庫バラ数
                   ,SUM( TRAN.rev_in_qty   )                rev_in_qty          --返品_月間入庫バラ数(受入返品)
                   ,SUM( TRAN.po_in_qty    )                po_in_qty           --生産_月間入庫バラ数(受入)
                   ,SUM( TRAN.mov_in_qty   )                mov_in_qty          --移動_月間入庫バラ数
                   ,SUM( TRAN.etc_in_qty   )                etc_in_qty          --その他_月間入庫バラ数
                   ,SUM( TRAN.oe_out_qty   )                oe_out_qty          --拠点_月間出庫バラ数(出荷)
                   ,SUM( TRAN.mov_out_qty  )                mov_out_qty         --移動_月間出庫バラ数
                   ,SUM( TRAN.etc_out_qty  )                etc_out_qty         --その他_月間出庫バラ数
             FROM
                   ( --======================================================================
                     -- 棚卸結果アドオンから棚卸在庫数を取得
                     --======================================================================
                      SELECT
                              TO_CHAR( XSIR.invent_date, 'YYYYMM' )
                                                            yyyymm              --年月
                             ,XSIR.invent_whse_code         whse_code           --倉庫コード
                             ,XILV.segment1                 location            --保管場所コード
                             ,XSIR.item_id                  item_id             --品目ID
                             ,XSIR.lot_id                   lot_id              --ロットID
                             ,TRUNC( NVL( XSIR.case_amt, 0 ) + ( NVL( XSIR.loose_amt, 0 ) / DECODE( XSIR.content, NULL, 1, 0, 1, XSIR.content ) ) )
                                                            stc_r_cs_qty        --棚卸ケース数 (棚卸結果アドオンテーブルのみケース数とバラ数の和で総数となっている)
                             ,( NVL( XSIR.case_amt, 0 ) * NVL( XSIR.content, 0 ) ) + NVL( XSIR.loose_amt, 0 )
                                                            stc_r_qty           --棚卸バラ数   (棚卸結果アドオンテーブルのみケース数とバラ数の和で総数となっている)
                             ,0                             cargo_qty           --積送中バラ数
                             ,0                             month_qty           --月末在庫バラ数
                             ,0                             rev_in_qty          --返品_入庫バラ数(受入返品)
                             ,0                             po_in_qty           --生産_入庫バラ数(受入)
                             ,0                             mov_in_qty          --移動_入庫バラ数
                             ,0                             etc_in_qty          --その他_入庫バラ数
                             ,0                             oe_out_qty          --拠点_出庫バラ数(出荷)
                             ,0                             mov_out_qty         --移動_出庫バラ数
                             ,0                             etc_out_qty         --その他_出庫バラ数
                        FROM
                              xxinv_stc_inventory_result    XSIR                --棚卸結果アドオン
                             ,xxsky_item_locations_v        XILV                --保管場所取得用
                       WHERE
                            ( XSIR.case_amt <> 0  OR  XSIR.loose_amt <> 0 )
                         AND  XSIR.invent_whse_code         = XILV.whse_code
                         AND  XILV.allow_pickup_flag        = '1'               --出荷引当対象フラグ
                     --<< 棚卸結果アドオンから棚卸在庫数を取得 END >>--
                    UNION ALL
                     --======================================================================
                     -- 棚卸月末在庫テーブルから月首在庫数として前月の月末在庫数を取得
                     --   ⇒【前月の月末在庫＋当月の入出庫数の積み上げ】によって当月の月末在庫数を求める
                     --======================================================================
                      SELECT
                              TO_CHAR( ADD_MONTHS( TO_DATE( XSIM.invent_ym || '01', 'YYYYMMDD' ), 1 ), 'YYYYMM' )    --前月の月末在庫数を当月の月首在庫数として扱う
                                                            yyyymm              --年月
                             ,XSIM.whse_code                whse_code           --倉庫コード
                             ,XILV.segment1                 location            --保管場所コード
                             ,XSIM.item_id                  item_id             --品目ID
                             ,XSIM.lot_id                   lot_id              --ロットID
                             ,0                             stc_r_cs_qty        --棚卸ケース数
                             ,0                             stc_r_qty           --棚卸バラ数
                             ,0                             cargo_qty           --積送中バラ数
                             ,NVL( XSIM.monthly_stock, 0 ) + NVL( XSIM.cargo_stock, 0 )
                                                            month_qty           --月末在庫バラ数
                             ,0                             rev_in_qty          --返品_入庫バラ数(受入返品)
                             ,0                             po_in_qty           --生産_入庫バラ数(受入)
                             ,0                             mov_in_qty          --移動_入庫バラ数
                             ,0                             etc_in_qty          --その他_入庫バラ数
                             ,0                             oe_out_qty          --拠点_出庫バラ数(出荷)
                             ,0                             mov_out_qty         --移動_出庫バラ数
                             ,0                             etc_out_qty         --その他_出庫バラ数
                        FROM
                              xxinv_stc_inventory_month_stck    XSIM            --棚卸月末在庫アドオン
                             ,xxsky_item_locations_v            XILV            --保管場所取得用
                       WHERE
                            ( XSIM.cargo_stock <> 0  OR  XSIM.monthly_stock <> 0 )
                         AND  XSIM.whse_code                = XILV.whse_code
                         AND  XILV.allow_pickup_flag        = '1'               --出荷引当対象フラグ
                     --<< 棚卸月末在庫テーブから月首在庫数として前月の月末在庫数を取得 END >>--
                    UNION ALL
                     --======================================================================
                     -- 各トランザクションから積送中数を取得
                     --  １．移動出庫実績（積送中のみ）
                     --  ２．出荷実績（積送中のみ）
                     --  ３．支給実績（積送中のみ）
                     --======================================================================
                      ----------------------------------------------------------------------
                      -- １．移動出庫実績（積送中のみ）
                      ----------------------------------------------------------------------
                      SELECT
                              TO_CHAR( XMH.actual_ship_date, 'YYYYMM' )
                                                            yyyymm              --年月
                             ,XIL.whse_code                 whse_code           --倉庫コード
                             ,XMH.shipped_locat_code        location            --保管場所コード
                             ,XMD.item_id                   item_id             --品目ID
                             ,XMD.lot_id                    lot_id              --ロットID
                             ,0                             stc_r_cs_qty        --棚卸ケース数
                             ,0                             stc_r_qty           --棚卸バラ数
                             ,XMD.actual_quantity           cargo_qty           --積送中バラ数
                             ,0                             month_qty           --月末在庫バラ数 …入出庫数の積み上げを使用して月末在庫数を求める
                             ,0                             rev_in_qty          --返品_入庫バラ数(仕入先返品)
                             ,0                             po_in_qty           --生産_入庫バラ数(受入)
                             ,0                             mov_in_qty          --移動_入庫バラ数
                             ,0                             etc_in_qty          --その他_入庫バラ数
                             ,0                             oe_out_qty          --拠点_出庫バラ数(出荷)
                             ,0                             mov_out_qty         --移動_出庫バラ数
                             ,0                             etc_out_qty         --その他_出庫バラ数
                        FROM
                              xxinv_mov_req_instr_headers   XMH                 --移動依頼/指示ヘッダ(アドオン)
                             ,xxinv_mov_req_instr_lines     XML                 --移動依頼/指示明細(アドオン)
                             ,xxinv_mov_lot_details         XMD                 --移動ロット詳細(アドオン)
                             ,xxsky_item_locations_v        XIL                 --OPM保管場所情報VIEW
                             ,xxsky_item_locations_v        XIL_TO              --OPM保管場所情報VIEW -- 2010/03/09 H.Itou Add E_本稼動_01822
                       WHERE
                         -- 出庫日の年月 < 入庫日の年月   …積層中と判断
                              TO_CHAR( XMH.actual_ship_date, 'YYYYMM' ) 
                            < TO_CHAR( NVL( XMH.actual_arrival_date, XMH.schedule_arrival_date ), 'YYYYMM' )
                         -- 移動依頼/指示ヘッダ(アドオン)の条件
                         AND  XMH.status                    IN ( '06', '04' )   --06:入出庫報告有、04:出庫報告有
                         -- 移動依頼/指示明細(アドオン)との結合
                         AND  XML.delete_flg                = 'N'               --OFF
                         AND  XMH.mov_hdr_id                = XML.mov_hdr_id
                         -- 移動ロット詳細(アドオン)との結合
                         AND  XMD.actual_quantity          <> 0
                         AND  XMD.document_type_code        = '20'              --移動
                         AND  XMD.record_type_code          = '20'              --出庫実績
                         AND  XML.mov_line_id               = XMD.mov_line_id
                         -- 保管場所情報取得
                         AND  XMH.shipped_locat_id          = XIL.inventory_location_id
                         AND  XMH.ship_to_locat_id          = XIL_TO.inventory_location_id -- 2010/03/09 H.Itou Add E_本稼動_01822
                         AND  XIL.whse_code                <> XIL_TO.whse_code             -- 2010/03/09 H.Itou Add E_本稼動_01822 同一倉庫移動は対象外
                      --[ １．移動出庫実績（積層中のみ） END ]--
                    UNION ALL
                      ----------------------------------------------------------------------
                      -- ２．出荷実績（積送中のみ）
                      ----------------------------------------------------------------------
                      SELECT
                              TO_CHAR( XOH.shipped_date, 'YYYYMM' )
                                                            yyyymm              --年月
                             ,XIL.whse_code                 whse_code           --倉庫コード
                             ,XOH.deliver_from              location            --保管場所コード
                             ,XMD.item_id                   item_id             --品目ID
                             ,XMD.lot_id                    lot_id              --ロットID
                             ,0                             stc_r_cs_qty        --棚卸ケース数
                             ,0                             stc_r_qty           --棚卸バラ数
                             ,XMD.actual_quantity           cargo_qty           --積送中バラ数
                             ,0                             month_qty           --月末在庫バラ数 …入出庫数の積み上げを使用して月末在庫数を求める
                             ,0                             rev_in_qty          --返品_入庫バラ数(仕入先返品)
                             ,0                             po_in_qty           --生産_入庫バラ数(受入)
                             ,0                             mov_in_qty          --移動_入庫バラ数
                             ,0                             etc_in_qty          --その他_入庫バラ数
                             ,0                             oe_out_qty          --拠点_出庫バラ数(出荷)
                             ,0                             mov_out_qty         --移動_出庫バラ数
                             ,0                             etc_out_qty         --その他_出庫バラ数
                        FROM
                              xxwsh_order_headers_all       XOH                 --受注ヘッダ
                             ,xxwsh_order_lines_all         XOL                 --受注明細
                             ,xxinv_mov_lot_details         XMD                 --移動ロット詳細
                             ,oe_transaction_types_all      OTA                 --受注タイプ
                             ,xxsky_item_locations2_v       XIL                 --保管場所マスタ
                       WHERE
                         -- 出庫日の年月 < 入庫日の年月   …積層中と判断
                              TO_CHAR( XOH.shipped_date, 'YYYYMM' ) 
                            < TO_CHAR( XOH.arrival_date, 'YYYYMM' )
                         --受注ヘッダの条件
                         AND  XOH.req_status                = '04'              --実績計上済
                         AND  NVL( XOH.latest_external_flag, 'N' ) = 'Y'        --ON
                         --受注タイプマスタとの結合
                         AND  OTA.attribute1                = '1'               --出荷依頼
                         AND  OTA.order_category_code       = 'ORDER'
                         AND  XOH.order_type_id             = OTA.transaction_type_id
                         --受注明細との結合
                         AND  NVL( XOL.delete_flag, 'N' )  <> 'Y'               --無効明細以外
                         AND  XOH.order_header_id           = XOL.order_header_id
                         --移動ロット詳細との結合[
                         AND  XMD.actual_quantity          <> 0
                         AND  XMD.document_type_code        = '10'              --出荷依頼
                         AND  XMD.record_type_code          = '20'              --出庫実績
                         AND  XMD.mov_line_id               = XOL.order_line_id
                         --出庫元保管場所情報取得
                         AND  XOH.deliver_from_id           = XIL.inventory_location_id
                      --[ ２．出荷実績（積送中のみ） END ]--
                    UNION ALL
                      ----------------------------------------------------------------------
                      -- ３．支給実績（積送中のみ）
                      ----------------------------------------------------------------------
                      SELECT
                              TO_CHAR( XOH.shipped_date, 'YYYYMM' )
                                                            yyyymm              --年月
                             ,XIL.whse_code                 whse_code           --倉庫コード
                             ,XOH.deliver_from              location            --保管場所コード
                             ,XMD.item_id                   item_id             --品目ID
                             ,XMD.lot_id                    lot_id              --ロットID
                             ,0                             stc_r_cs_qty        --棚卸ケース数
                             ,0                             stc_r_qty           --棚卸バラ数
                             ,XMD.actual_quantity * DECODE( OTA.order_category_code, 'RETURN', -1, 1 )
                                                            cargo_qty           --積送中バラ数
                             ,0                             month_qty           --月末在庫バラ数 …入出庫数の積み上げを使用して月末在庫数を求める
                             ,0                             rev_in_qty          --返品_入庫バラ数(仕入先返品)
                             ,0                             po_in_qty           --生産_入庫バラ数(受入)
                             ,0                             mov_in_qty          --移動_入庫バラ数
                             ,0                             etc_in_qty          --その他_入庫バラ数
                             ,0                             oe_out_qty          --拠点_出庫バラ数(出荷)
                             ,0                             mov_out_qty         --移動_出庫バラ数
                             ,0                             etc_out_qty         --その他_出庫バラ数
                        FROM
                              xxwsh_order_headers_all       XOH                 --受注ヘッダ
                             ,xxwsh_order_lines_all         XOL                 --受注明細
                             ,xxinv_mov_lot_details         XMD                 --移動ロット詳細
                             ,oe_transaction_types_all      OTA                 --受注タイプ
                             ,xxsky_item_locations2_v       XIL                 --保管場所マスタ
                       WHERE
                         -- 出庫日の年月 < 入庫日の年月   …積層中と判断
                              TO_CHAR( XOH.shipped_date, 'YYYYMM' ) 
                            < TO_CHAR( XOH.arrival_date, 'YYYYMM' )
                         --受注ヘッダの条件
                         AND  XOH.req_status                = '08'              --実績計上済
                         AND  NVL( XOH.latest_external_flag, 'N' ) = 'Y'        --ON
                         --受注タイプマスタとの結合
                         AND  OTA.attribute1                = '2'               --支給依頼
                         AND  XOH.order_type_id             = OTA.transaction_type_id
                         --受注明細との結合
                         AND  NVL( XOL.delete_flag, 'N' )  <> 'Y'               --無効明細以外
                         AND  XOH.order_header_id           = XOL.order_header_id
                         --移動ロット詳細との結合[
                         AND  XMD.actual_quantity          <> 0
                         AND  XMD.document_type_code        = '30'              --支給指示
                         AND  XMD.record_type_code          = '20'              --出庫実績
                         AND  XMD.mov_line_id               = XOL.order_line_id
                         --出庫元保管場所情報取得
                         AND  XOH.deliver_from_id           = XIL.inventory_location_id
                      --[ ３．支給実績（積送中のみ） END ]--
                     --<< 各トランザクションから積層中数を取得 END >>--
                    UNION ALL
                     --======================================================================
                     -- 各トランザクションから月間入庫数を取得
                     --  １．仕入先返品
                     --  ２．発注受入実績
                     --  ３．移動入庫実績
                     --  ４．倉替返品入庫実績
                     --  ５．その他入庫
                     --======================================================================
                      ----------------------------------------------------------------------
                      -- １．仕入先返品  …マイナス値で出力
                      ----------------------------------------------------------------------
                      SELECT
                              TO_CHAR( ITC.trans_date, 'YYYYMM' )
                                                            yyyymm              --年月
                             ,ITC.whse_code                 whse_code           --倉庫コード
                             ,ITC.location                  location            --保管場所コード
                             ,ITC.item_id                   item_id             --品目ID
                             ,ITC.lot_id                    lot_id              --ロットID
                             ,0                             stc_r_cs_qty        --棚卸ケース数
                             ,0                             stc_r_qty           --棚卸バラ数
                             ,0                             cargo_qty           --積送中バラ数
                             ,ITC.trans_qty                 month_qty           --月末在庫バラ数 …入出庫数の積み上げを使用して月末在庫数を求める
                             ,ITC.trans_qty                 rev_in_qty          --返品_入庫バラ数(仕入先返品)
                             ,0                             po_in_qty           --生産_入庫バラ数(受入)
                             ,0                             mov_in_qty          --移動_入庫バラ数
                             ,0                             etc_in_qty          --その他_入庫バラ数
                             ,0                             oe_out_qty          --拠点_出庫バラ数(出荷)
                             ,0                             mov_out_qty         --移動_出庫バラ数
                             ,0                             etc_out_qty         --その他_出庫バラ数
                        FROM
                              xxcmn_rcv_pay_mst             XRP                 --受払区分アドオンマスタ
                             ,ic_adjs_jnl                   IAJ                 --OPM在庫調整ジャーナル
                             ,ic_jrnl_mst                   IJM                 --OPMジャーナルマスタ
                             ,ic_tran_cmp                   ITC                 --OPM完了在庫トランザクション
                       WHERE
                         -- 受払区分アドオンマスタの条件
                              XRP.doc_type                  = 'ADJI'
                         AND  XRP.reason_code               = 'X201'            --仕入返品出庫
                         AND  XRP.rcv_pay_div               = '1'               --受入
                         AND  XRP.use_div_invent            = 'Y'
                         -- OPM完了在庫トランザクションとの結合
                         AND  ITC.trans_qty                <> 0
                         AND  ITC.doc_type                  = XRP.doc_type
                         AND  ITC.reason_code               = XRP.reason_code
                         -- OPM在庫調整ジャーナルとの結合
                         AND  ITC.doc_type                  = IAJ.trans_type
                         AND  ITC.doc_id                    = IAJ.doc_id
                         AND  ITC.doc_line                  = IAJ.doc_line
                         -- OPMジャーナルマスタとの結合
                         AND  IAJ.journal_id                = IJM.journal_id
                      --[ １．仕入先返品 END ]--
                    UNION ALL
                      ----------------------------------------------------------------------
                      -- ２．発注受入実績
                      ----------------------------------------------------------------------
                      SELECT
                              TO_CHAR( XRT.txns_date, 'YYYYMM' )
                                                            yyyymm              --年月
                             ,XIL.whse_code                 whse_code           --倉庫コード
                             ,PHA.attribute5                location            --保管場所コード
                             ,XRT.item_id                   item_id             --品目ID
                             ,XRT.lot_id                    lot_id              --ロットID
                             ,0                             stc_r_cs_qty        --棚卸ケース数
                             ,0                             stc_r_qty           --棚卸バラ数
                             ,0                             cargo_qty           --積送中バラ数
                             ,XRT.quantity                  month_qty           --月末在庫バラ数 …入出庫数の積み上げを使用して月末在庫数を求める
                             ,0                             rev_in_qty          --返品_入庫バラ数(仕入先返品)
                             ,XRT.quantity                  po_in_qty           --生産_入庫バラ数(受入)
                             ,0                             mov_in_qty          --移動_入庫バラ数
                             ,0                             etc_in_qty          --その他_入庫バラ数
                             ,0                             oe_out_qty          --拠点_出庫バラ数(出荷)
                             ,0                             mov_out_qty         --移動_出庫バラ数
                             ,0                             etc_out_qty         --その他_出庫バラ数
                        FROM
                              po_headers_all                PHA                 --発注ヘッダ
                             ,po_lines_all                  PLA                 --発注明細
                             ,xxpo_rcv_and_rtn_txns         XRT                 --受入返品実績(アドオン)
                             ,xxsky_item_locations_v        XIL                 --OPM保管場所情報VIEW
                       WHERE
                         -- 発注ヘッダの条件
                              PHA.attribute1                IN ( '25'           --受入あり
                                                               , '30'           --数量確定済
                                                               , '35' )         --金額確定済
                         -- 発注明細との結合
                         AND  PLA.attribute13               = 'Y'               --承諾済
                         AND  PLA.cancel_flag              <> 'Y'               --キャンセル以外
                         AND  PHA.po_header_id              = PLA.po_header_id
                         -- 受入返品実績(アドオン)との結合
                         AND  XRT.txns_type                 = '1'               --受入
                         AND  XRT.quantity                 <> 0
                         AND  PHA.segment1                  = XRT.source_document_number
                         AND  PLA.line_num                  = XRT.source_document_line_num
                         -- 保管場所情報取得
                         AND  PHA.attribute5                = XIL.segment1
                      --[ ２．発注受入実績 END ]--
                    UNION ALL
                      ----------------------------------------------------------------------
                      -- ３．移動入庫実績
                      ----------------------------------------------------------------------
                      SELECT
                              TO_CHAR( XMH.actual_arrival_date, 'YYYYMM' )
                                                            yyyymm              --年月
                             ,XIL.whse_code                 whse_code           --倉庫コード
                             ,XMH.ship_to_locat_code        location            --保管場所コード
                             ,XMD.item_id                   item_id             --品目ID
                             ,XMD.lot_id                    lot_id              --ロットID
                             ,0                             stc_r_cs_qty        --棚卸ケース数
                             ,0                             stc_r_qty           --棚卸バラ数
                             ,0                             cargo_qty           --積送中バラ数
                             ,XMD.actual_quantity           month_qty           --月末在庫バラ数 …入出庫数の積み上げを使用して月末在庫数を求める
                             ,0                             rev_in_qty          --返品_入庫バラ数(仕入先返品)
                             ,0                             po_in_qty           --生産_入庫バラ数(受入)
                             ,XMD.actual_quantity           mov_in_qty          --移動_入庫バラ数
                             ,0                             etc_in_qty          --その他_入庫バラ数
                             ,0                             oe_out_qty          --拠点_出庫バラ数(出荷)
                             ,0                             mov_out_qty         --移動_出庫バラ数
                             ,0                             etc_out_qty         --その他_出庫バラ数
                        FROM
                              xxinv_mov_req_instr_headers   XMH                 --移動依頼/指示ヘッダ(アドオン)
                             ,xxinv_mov_req_instr_lines     XML                 --移動依頼/指示明細(アドオン)
                             ,xxinv_mov_lot_details         XMD                 --移動ロット詳細(アドオン)
                             ,xxsky_item_locations_v        XIL                 --OPM保管場所情報VIEW
                             ,xxsky_item_locations_v        XIL_FROM            --OPM保管場所情報VIEW -- 2010/03/09 H.Itou Add E_本稼動_01822
                       WHERE
                         -- 移動依頼/指示ヘッダ(アドオン)の条件
                              XMH.status                    IN ( '06', '05' )   --06:入出庫報告有、05:入庫報告有
                         -- 移動依頼/指示明細(アドオン)との結合
                         AND  XML.delete_flg                = 'N'               --OFF
                         AND  XMH.mov_hdr_id                = XML.mov_hdr_id
                         -- 移動ロット詳細(アドオン)との結合
                         AND  XMD.actual_quantity          <> 0
                         AND  XMD.document_type_code        = '20'              --移動
                         AND  XMD.record_type_code          = '30'              --入庫実績
                         AND  XML.mov_line_id               = XMD.mov_line_id
                         -- 保管場所情報取得
                         AND  XMH.ship_to_locat_id          = XIL.inventory_location_id
                         AND  XMH.shipped_locat_id          = XIL_FROM.inventory_location_id -- 2010/03/09 H.Itou Add E_本稼動_01822
                         AND  XIL.whse_code                <> XIL_FROM.whse_code             -- 2010/03/09 H.Itou Add E_本稼動_01822 同一倉庫移動は対象外
                      --[ ３．移動入庫実績 END ]--
                    UNION ALL
                      ----------------------------------------------------------------------
                      -- ４．倉替返品入庫実績
                      ----------------------------------------------------------------------
                      SELECT
                              TO_CHAR( XOH.arrival_date, 'YYYYMM' )
                                                            yyyymm              --年月
                             ,XIL.whse_code                 whse_code           --倉庫コード
                             ,XOH.deliver_from              location            --保管場所コード
                             ,XMD.item_id                   item_id             --品目ID
                             ,XMD.lot_id                    lot_id              --ロットID
                             ,0                             stc_r_cs_qty        --棚卸ケース数
                             ,0                             stc_r_qty           --棚卸バラ数
                             ,0                             cargo_qty           --積送中バラ数
                             ,XMD.actual_quantity * DECODE( OTA.order_category_code, 'ORDER', -1, 1 )    --取消なら出庫扱い
                                                            month_qty           --月末在庫バラ数 …入出庫数の積み上げを使用して月末在庫数を求める
                             ,0                             rev_in_qty          --返品_入庫バラ数(仕入先返品)
                             ,0                             po_in_qty           --生産_入庫バラ数(受入)
                             ,0                             mov_in_qty          --移動_入庫バラ数
                             ,XMD.actual_quantity * DECODE( OTA.order_category_code, 'ORDER', -1, 1 )    --取消なら出庫(入庫のマイナス)扱い
                                                            etc_in_qty          --その他_入庫バラ数
                             ,0                             oe_out_qty          --拠点_出庫バラ数(出荷)
                             ,0                             mov_out_qty         --移動_出庫バラ数
                             ,0                             etc_out_qty         --その他_出庫バラ数
                        FROM
                              xxwsh_order_headers_all       XOH                 --受注ヘッダ
                             ,xxwsh_order_lines_all         XOL                 --受注明細
                             ,xxinv_mov_lot_details         XMD                 --移動ロット詳細
                             ,oe_transaction_types_all      OTA                 --受注タイプ
                             ,xxsky_item_locations2_v       XIL                 --保管場所マスタ
                       WHERE
                         --受注ヘッダの条件
                              XOH.req_status                = '04'              --実績計上済
                         AND  NVL( XOH.latest_external_flag, 'N' ) = 'Y'        --ON
                         --受注タイプマスタとの結合
                         AND  OTA.attribute1                = '3'               --倉替返品
                         AND  XOH.order_type_id             = OTA.transaction_type_id
                         --受注明細との結合
                         AND  NVL( XOL.delete_flag, 'N' )  <> 'Y'               --無効明細以外
                         AND  XOH.order_header_id           = XOL.order_header_id
                         --移動ロット詳細との結合[
                         AND  XMD.actual_quantity          <> 0
                         AND  XMD.document_type_code        = '10'              --出荷依頼
                         AND  XMD.record_type_code          = '20'              --出庫実績
                         AND  XMD.mov_line_id               = XOL.order_line_id
                         --出庫元保管場所情報取得
                         AND  XOH.deliver_from_id           = XIL.inventory_location_id
                      --[ ４．倉替返品入庫実績 END ]--
                    UNION ALL
                      ----------------------------------------------------------------------
                      -- ５．その他入庫
                      ----------------------------------------------------------------------
                      SELECT
                              TO_CHAR( ITC.trans_date, 'YYYYMM' )
                                                            yyyymm              --年月
                             ,ITC.whse_code                 whse_code           --倉庫コード
                             ,ITC.location                  location            --保管場所コード
                             ,ITC.item_id                   item_id             --品目ID
                             ,ITC.lot_id                    lot_id              --ロットID
                             ,0                             stc_r_cs_qty        --棚卸ケース数
                             ,0                             stc_r_qty           --棚卸バラ数
                             ,0                             cargo_qty           --積送中バラ数
                             ,ITC.trans_qty                 month_qty           --月末在庫バラ数 …入出庫数の積み上げを使用して月末在庫数を求める
                             ,0                             rev_in_qty          --返品_入庫バラ数(仕入先返品)
                             ,0                             po_in_qty           --生産_入庫バラ数(受入)
                             ,0                             mov_in_qty          --移動_入庫バラ数
                             ,ITC.trans_qty                 etc_in_qty          --その他_入庫バラ数
                             ,0                             oe_out_qty          --拠点_出庫バラ数(出荷)
                             ,0                             mov_out_qty         --移動_出庫バラ数
                             ,0                             etc_out_qty         --その他_出庫バラ数
                        FROM
                              xxcmn_rcv_pay_mst             XRP                 --受払区分アドオンマスタ
                             ,ic_adjs_jnl                   IAJ                 --OPM在庫調整ジャーナル
                             ,ic_jrnl_mst                   IJM                 --OPMジャーナルマスタ
                             ,ic_tran_cmp                   ITC                 --OPM完了在庫トランザクション
                       WHERE
                         -- 受払区分アドオンマスタの条件
                              XRP.doc_type                  = 'ADJI'
                         AND  XRP.reason_code              <> 'X977'            --相手先在庫
                         AND  XRP.reason_code              <> 'X988'            --浜岡入庫
                         AND  XRP.reason_code              <> 'X123'            --移動実績訂正（出庫）
                         AND  XRP.reason_code              <> 'X201'            --仕入先返品
                         AND  XRP.rcv_pay_div               = '1'               --受入
                         AND  XRP.use_div_invent            = 'Y'
                         -- OPM完了在庫トランザクションとの結合
                         AND  ITC.trans_qty                <> 0
                         AND  XRP.doc_type                  = ITC.doc_type
                         AND  XRP.reason_code               = ITC.reason_code
                         -- OPM在庫調整ジャーナルとの結合
                         AND  ITC.doc_type                  = IAJ.trans_type
                         AND  ITC.doc_id                    = IAJ.doc_id
                         AND  ITC.doc_line                  = IAJ.doc_line
                         -- OPMジャーナルマスタとの結合
                         AND  IAJ.journal_id                = IJM.journal_id
                      --[ ５．その他入庫 END ]--
                     --<< 各トランザクションから月間入庫数を取得 END >>--
                    UNION ALL
                     --======================================================================
                     -- 各トランザクションから月間出庫数を取得
                     --  １．出荷実績
                     --  ２．有償支給実績
                     --  ３．見本･廃棄出荷実績
                     --  ４．移動入庫実績
                     --  ５．その他出庫
                     --======================================================================
                      ----------------------------------------------------------------------
                      -- １．出荷実績
                      ----------------------------------------------------------------------
                      SELECT
                              TO_CHAR( XOH.arrival_date, 'YYYYMM' )
                                                            yyyymm              --年月
                             ,XIL.whse_code                 whse_code           --倉庫コード
                             ,XOH.deliver_from              location            --保管場所コード
                             ,XMD.item_id                   item_id             --品目ID
                             ,XMD.lot_id                    lot_id              --ロットID
                             ,0                             stc_r_cs_qty        --棚卸ケース数
                             ,0                             stc_r_qty           --棚卸バラ数
                             ,0                             cargo_qty           --積送中バラ数
                             ,XMD.actual_quantity * -1      month_qty           --月末在庫バラ数 …入出庫数の積み上げを使用して月末在庫数を求める
                             ,0                             rev_in_qty          --返品_入庫バラ数(仕入先返品)
                             ,0                             po_in_qty           --生産_入庫バラ数(受入)
                             ,0                             mov_in_qty          --移動_入庫バラ数
                             ,0                             etc_in_qty          --その他_入庫バラ数
                             ,XMD.actual_quantity           oe_out_qty          --拠点_出庫バラ数(出荷)
                             ,0                             mov_out_qty         --移動_出庫バラ数
                             ,0                             etc_out_qty         --その他_出庫バラ数
                        FROM
                              xxwsh_order_headers_all       XOH                 --受注ヘッダ
                             ,xxwsh_order_lines_all         XOL                 --受注明細
                             ,xxinv_mov_lot_details         XMD                 --移動ロット詳細
                             ,oe_transaction_types_all      OTA                 --受注タイプ
                             ,xxsky_item_locations2_v       XIL                 --保管場所マスタ
                       WHERE
                         --受注ヘッダの条件
                              XOH.req_status                = '04'              --実績計上済
                         AND  NVL( XOH.latest_external_flag, 'N' ) = 'Y'        --ON
                         --受注タイプマスタとの結合
                         AND  OTA.attribute1                = '1'               --出荷依頼
                         AND  OTA.attribute4                = '1'               --通常出荷
                         AND  OTA.order_category_code       = 'ORDER'
                         AND  XOH.order_type_id             = OTA.transaction_type_id
                         --受注明細との結合
                         AND  NVL( XOL.delete_flag, 'N' )  <> 'Y'               --無効明細以外
                         AND  XOH.order_header_id           = XOL.order_header_id
                         --移動ロット詳細との結合[
                         AND  XMD.actual_quantity          <> 0
                         AND  XMD.document_type_code        = '10'              --出荷依頼
                         AND  XMD.record_type_code          = '20'              --出庫実績
                         AND  XMD.mov_line_id               = XOL.order_line_id
                         --出庫元保管場所情報取得
                         AND  XOH.deliver_from_id           = XIL.inventory_location_id
                      --[ １．出荷･倉返実績 END ]--
                    UNION ALL
                      ----------------------------------------------------------------------
                      -- ２．有償支給実績
                      ----------------------------------------------------------------------
                      SELECT
                              TO_CHAR( XOH.arrival_date, 'YYYYMM' )
                                                            yyyymm              --年月
                             ,XIL.whse_code                 whse_code           --倉庫コード
                             ,XOH.deliver_from              location            --保管場所コード
                             ,XMD.item_id                   item_id             --品目ID
                             ,XMD.lot_id                    lot_id              --ロットID
                             ,0                             stc_r_cs_qty        --棚卸ケース数
                             ,0                             stc_r_qty           --棚卸バラ数
                             ,0                             cargo_qty           --積送中バラ数
                             ,XMD.actual_quantity * DECODE( OTA.order_category_code, 'RETURN', 1, -1 )    --返品なら入庫扱い
                                                            month_qty           --月末在庫バラ数 …入出庫数の積み上げを使用して月末在庫数を求める
                             ,0                             rev_in_qty          --返品_入庫バラ数(仕入先返品)
                             ,0                             po_in_qty           --生産_入庫バラ数(受入)
                             ,0                             mov_in_qty          --移動_入庫バラ数
                             ,0                             etc_in_qty          --その他_入庫バラ数
                             ,XMD.actual_quantity * DECODE( OTA.order_category_code, 'RETURN', -1, 1 )    --返品なら入庫(出庫のマイナス)扱い
                                                            oe_out_qty          --拠点_出庫バラ数(出荷)
                             ,0                             mov_out_qty         --移動_出庫バラ数
                             ,0                             etc_out_qty         --その他_出庫バラ数
                        FROM
                              xxwsh_order_headers_all       XOH                 --受注ヘッダ
                             ,xxwsh_order_lines_all         XOL                 --受注明細
                             ,xxinv_mov_lot_details         XMD                 --移動ロット詳細
                             ,oe_transaction_types_all      OTA                 --受注タイプ
                             ,xxsky_item_locations2_v       XIL                 --保管場所マスタ
                       WHERE
                         --受注ヘッダの条件
                              XOH.req_status                = '08'              --実績計上済
                         AND  NVL( XOH.latest_external_flag, 'N' ) = 'Y'        --ON
                         --受注タイプマスタとの結合
                         AND  OTA.attribute1                = '2'               --支給
                         AND  XOH.order_type_id             = OTA.transaction_type_id
                         --受注明細との結合
                         AND  NVL( XOL.delete_flag, 'N' )  <> 'Y'               --無効明細以外
                         AND  XOH.order_header_id           = XOL.order_header_id
                         --移動ロット詳細との結合
                         AND  XMD.actual_quantity          <> 0
                         AND  XMD.document_type_code        = '30'              --支給指示
                         AND  XMD.record_type_code          = '20'              --出庫実績
                         AND  XMD.mov_line_id               = XOL.order_line_id
                         --出庫元保管場所情報取得
                         AND  XOH.deliver_from_id           = XIL.inventory_location_id
                      --[ ２．有償支給実績 END ]--
                    UNION ALL
                      ----------------------------------------------------------------------
                      -- ３．見本･廃棄出荷実績
                      ----------------------------------------------------------------------
                      SELECT
                              TO_CHAR( XOH.arrival_date, 'YYYYMM' )
                                                            yyyymm              --年月
                             ,XIL.whse_code                 whse_code           --倉庫コード
                             ,XOH.deliver_from              location            --保管場所コード
                             ,XMD.item_id                   item_id             --品目ID
                             ,XMD.lot_id                    lot_id              --ロットID
                             ,0                             stc_r_cs_qty        --棚卸ケース数
                             ,0                             stc_r_qty           --棚卸バラ数
                             ,0                             cargo_qty           --積送中バラ数
                             ,XMD.actual_quantity * -1      month_qty           --月末在庫バラ数 …入出庫数の積み上げを使用して月末在庫数を求める
                             ,0                             rev_in_qty          --返品_入庫バラ数(仕入先返品)
                             ,0                             po_in_qty           --生産_入庫バラ数(受入)
                             ,0                             mov_in_qty          --移動_入庫バラ数
                             ,0                             etc_in_qty          --その他_入庫バラ数
                             ,0                             oe_out_qty          --拠点_出庫バラ数(出荷)
                             ,0                             mov_out_qty         --移動_出庫バラ数
                             ,XMD.actual_quantity           etc_out_qty         --その他_出庫バラ数
                        FROM
                              xxwsh_order_headers_all       XOH                 --受注ヘッダ
                             ,xxwsh_order_lines_all         XOL                 --受注明細
                             ,xxinv_mov_lot_details         XMD                 --移動ロット詳細
                             ,oe_transaction_types_all      OTA                 --受注タイプ
                             ,xxsky_item_locations2_v       XIL                 --保管場所マスタ
                       WHERE
                         --受注ヘッダの条件
                              XOH.req_status                = '04'              --実績計上済
                         AND  NVL( XOH.latest_external_flag, 'N' ) = 'Y'        --ON
                         --受注タイプマスタとの結合
                         AND  OTA.attribute1                = '1'               --出荷依頼
                         AND  OTA.attribute4                = '2'               --見本･廃棄出荷
                         AND  OTA.order_category_code       = 'ORDER'
                         AND  XOH.order_type_id             = OTA.transaction_type_id
                         --受注明細との結合
                         AND  NVL( XOL.delete_flag, 'N' )  <> 'Y'               --無効明細以外
                         AND  XOH.order_header_id           = XOL.order_header_id
                         --移動ロット詳細との結合[
                         AND  XMD.actual_quantity          <> 0
                         AND  XMD.document_type_code        = '10'              --出荷依頼
                         AND  XMD.record_type_code          = '20'              --出庫実績
                         AND  XMD.mov_line_id               = XOL.order_line_id
                         --出庫元保管場所情報取得
                         AND  XOH.deliver_from_id           = XIL.inventory_location_id
                      --[ ３．出荷･倉返実績 END ]--
                    UNION ALL
                      ----------------------------------------------------------------------
                      -- ４．移動出荷実績
                      ----------------------------------------------------------------------
                      SELECT
                              TO_CHAR( XMH.actual_arrival_date, 'YYYYMM' )
                                                            yyyymm              --年月
                             ,XIL.whse_code                 whse_code           --倉庫コード
                             ,XMH.shipped_locat_code        location            --保管場所コード
                             ,XMD.item_id                   item_id             --品目ID
                             ,XMD.lot_id                    lot_id              --ロットID
                             ,0                             stc_r_cs_qty        --棚卸ケース数
                             ,0                             stc_r_qty           --棚卸バラ数
                             ,0                             cargo_qty           --積送中バラ数
                             ,XMD.actual_quantity * -1      month_qty           --月末在庫バラ数 …入出庫数の積み上げを使用して月末在庫数を求める
                             ,0                             rev_in_qty          --返品_入庫バラ数(仕入先返品)
                             ,0                             po_in_qty           --生産_入庫バラ数(受入)
                             ,0                             mov_in_qty          --移動_入庫バラ数
                             ,0                             etc_in_qty          --その他_入庫バラ数
                             ,0                             oe_out_qty          --拠点_出庫バラ数(出荷)
                             ,XMD.actual_quantity           mov_out_qty         --移動_出庫バラ数
                             ,0                             etc_out_qty         --その他_出庫バラ数
                        FROM
                              xxinv_mov_req_instr_headers   XMH                 --移動依頼/指示ヘッダ(アドオン)
                             ,xxinv_mov_req_instr_lines     XML                 --移動依頼/指示明細(アドオン)
                             ,xxinv_mov_lot_details         XMD                 --移動ロット詳細(アドオン)
                             ,xxsky_item_locations_v        XIL                 --OPM保管場所情報VIEW
                             ,xxsky_item_locations_v        XIL_TO              --OPM保管場所情報VIEW -- 2010/03/09 H.Itou Add E_本稼動_01822
                       WHERE
                         -- 移動依頼/指示ヘッダ(アドオン)の条件
                              XMH.status                    IN ( '06', '04' )   -- 06:入出庫報告有、04:出庫報告有
                         -- 移動依頼/指示明細(アドオン)との結合
                         AND  XML.delete_flg                = 'N'               -- OFF
                         AND  XMH.mov_hdr_id                = XML.mov_hdr_id
                         -- 移動ロット詳細(アドオン)との結合
                         AND  XMD.actual_quantity          <> 0
                         AND  XMD.document_type_code        = '20'              -- 移動
                         AND  XMD.record_type_code          = '20'              -- 出庫実績
                         AND  XML.mov_line_id               = XMD.mov_line_id
                         -- 保管場所情報取得
                         AND  XMH.shipped_locat_id          = XIL.inventory_location_id
                         AND  XMH.ship_to_locat_id          = XIL_TO.inventory_location_id -- 2010/03/09 H.Itou Add E_本稼動_01822
                         AND  XIL.whse_code                <> XIL_TO.whse_code             -- 2010/03/09 H.Itou Add E_本稼動_01822 同一倉庫移動は対象外
                      --[ ４．移動出荷実績 END ]--
                    UNION ALL
                      ----------------------------------------------------------------------
                      -- ５．その他出庫
                      ----------------------------------------------------------------------
                      SELECT
                              TO_CHAR( ITC.trans_date, 'YYYYMM' )
                                                            yyyymm              --年月
                             ,ITC.whse_code                 whse_code           --倉庫コード
                             ,ITC.location                  location            --保管場所コード
                             ,ITC.item_id                   item_id             --品目ID
                             ,ITC.lot_id                    lot_id              --ロットID
                             ,0                             stc_r_cs_qty        --棚卸ケース数
                             ,0                             stc_r_qty           --棚卸バラ数
                             ,0                             cargo_qty           --積送中バラ数
                             ,ITC.trans_qty                 month_qty           --月末在庫バラ数 …入出庫数の積み上げを使用して月末在庫数を求める
                             ,0                             rev_in_qty          --返品_入庫バラ数(仕入先返品)
                             ,0                             po_in_qty           --生産_入庫バラ数(受入)
                             ,0                             mov_in_qty          --移動_入庫バラ数
                             ,0                             etc_in_qty          --その他_入庫バラ数
                             ,0                             oe_out_qty          --拠点_出庫バラ数(出荷)
                             ,0                             mov_out_qty         --移動_出庫バラ数
                             ,ITC.trans_qty * -1            etc_out_qty         --その他_出庫バラ数
                        FROM
                              xxcmn_rcv_pay_mst             XRP                 --受払区分アドオンマスタ
                             ,ic_adjs_jnl                   IAJ                 --OPM在庫調整ジャーナル
                             ,ic_jrnl_mst                   IJM                 --OPMジャーナルマスタ
                             ,ic_tran_cmp                   ITC                 --OPM完了在庫トランザクション
                       WHERE
                         -- 受払区分アドオンマスタの条件
                              XRP.doc_type                  = 'ADJI'
                         AND  XRP.reason_code              <> 'X977'            --相手先在庫
                         AND  XRP.reason_code              <> 'X123'            --移動実績訂正（出庫）
                         AND  XRP.rcv_pay_div               = '-1'              --払出
                         AND  XRP.use_div_invent            = 'Y'
                         -- OPM完了在庫トランザクションとの結合
                         AND  ITC.trans_qty                <> 0
                         AND  XRP.doc_type                  = ITC.doc_type
                         AND  XRP.reason_code               = ITC.reason_code
                         -- OPM在庫調整ジャーナルとの結合
                         AND  ITC.doc_type                  = IAJ.trans_type
                         AND  ITC.doc_id                    = IAJ.doc_id
                         AND  ITC.doc_line                  = IAJ.doc_line
                         -- OPMジャーナルマスタとの結合
                         AND  IAJ.journal_id                = IJM.journal_id
                      --[ ５．その他入庫 END ]--
                     --<< 各トランザクションから月間出庫数を取得 END >>--
                   )  TRAN
                  ,( -- 月末在庫数を求める最大期間を取得（それ以降は月首在庫数が分からない為に月末在庫が求まらない）
                     SELECT  TO_CHAR( ADD_MONTHS( TO_DATE( MAX( XSIM.invent_ym ) || '01', 'YYYYMMDD' ), 1 ), 'YYYYMM' )  yyyymm
                       FROM  xxinv_stc_inventory_month_stck    XSIM
                   )  MYM
           GROUP BY  TRAN.yyyymm
                    ,TRAN.whse_code
                    ,TRAN.location
                    ,TRAN.item_id
                    ,TRAN.lot_id
        )  STRN
       ,ic_whse_mst               IWM     --倉庫マスタ
       ,xxsky_item_locations_v    ILOC    --保管場所取得用
       ,xxsky_item_mst2_v         ITEM    --品目名称取得用
       ,xxsky_prod_class_v        PRODC   --商品区分取得用
       ,xxsky_item_class_v        ITEMC   --品目区分取得用
       ,xxsky_crowd_code_v        CROWD   --群コード取得用
       ,ic_lots_mst               ILM     --ロットマスタ
 WHERE
   --倉庫名取得用
        STRN.whse_code            = IWM.whse_code(+)
   --保管場所取得
   AND  STRN.location             = ILOC.segment1(+)
   --品目名称取得(SYSDATEで取得)
   AND  STRN.item_id              = ITEM.item_id(+)
   AND  LAST_DAY( TO_DATE( STRN.yyyymm || '01', 'YYYYMMDD') ) >= ITEM.start_date_active(+)
   AND  LAST_DAY( TO_DATE( STRN.yyyymm || '01', 'YYYYMMDD') ) <= ITEM.end_date_active(+)
   --商品区分:ドリンクの条件  (※ここで条件を絞る方がレスポンスが良い)
   AND  PRODC.prod_class_code     = '2'
   AND  STRN.item_id              = PRODC.item_id
   --品目区分:製品の条件      (※ここで条件を絞る方がレスポンスが良い)
   AND  ITEMC.item_class_code     = '5'
   AND  STRN.item_id              = ITEMC.item_id
   --群コード取得
   AND  STRN.item_id              = CROWD.item_id(+)
   --ロット情報取得
   AND  STRN.item_id              = ILM.item_id(+)
   AND  STRN.lot_id               = ILM.lot_id(+)
/
COMMENT ON TABLE APPS.XXSKY_ドリンク在庫実績_基本_V IS 'SKYLINK用 ドリンク在庫実績（基本）VIEW'
/
COMMENT ON COLUMN APPS.XXSKY_ドリンク在庫実績_基本_V.対象年月                IS '対象年月'
/
COMMENT ON COLUMN APPS.XXSKY_ドリンク在庫実績_基本_V.倉庫コード              IS '倉庫コード'
/
COMMENT ON COLUMN APPS.XXSKY_ドリンク在庫実績_基本_V.倉庫名                  IS '倉庫名'
/
COMMENT ON COLUMN APPS.XXSKY_ドリンク在庫実績_基本_V.保管場所コード          IS '保管場所コード'
/
COMMENT ON COLUMN APPS.XXSKY_ドリンク在庫実績_基本_V.保管場所名              IS '保管場所名'
/
COMMENT ON COLUMN APPS.XXSKY_ドリンク在庫実績_基本_V.保管場所略称            IS '保管場所略称'
/
COMMENT ON COLUMN APPS.XXSKY_ドリンク在庫実績_基本_V.商品区分                IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKY_ドリンク在庫実績_基本_V.商品区分名              IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKY_ドリンク在庫実績_基本_V.品目区分                IS '品目区分'
/
COMMENT ON COLUMN APPS.XXSKY_ドリンク在庫実績_基本_V.品目区分名              IS '品目区分名'
/
COMMENT ON COLUMN APPS.XXSKY_ドリンク在庫実績_基本_V.群コード                IS '群コード'
/
COMMENT ON COLUMN APPS.XXSKY_ドリンク在庫実績_基本_V.品目                    IS '品目'
/
COMMENT ON COLUMN APPS.XXSKY_ドリンク在庫実績_基本_V.品目名                  IS '品目名'
/
COMMENT ON COLUMN APPS.XXSKY_ドリンク在庫実績_基本_V.品目略称                IS '品目略称'
/
COMMENT ON COLUMN APPS.XXSKY_ドリンク在庫実績_基本_V.ロットNO                IS 'ロットNO'
/
COMMENT ON COLUMN APPS.XXSKY_ドリンク在庫実績_基本_V.製造年月日              IS '製造年月日'
/
COMMENT ON COLUMN APPS.XXSKY_ドリンク在庫実績_基本_V.固有記号                IS '固有記号'
/
COMMENT ON COLUMN APPS.XXSKY_ドリンク在庫実績_基本_V.賞味期限                IS '賞味期限'
/
COMMENT ON COLUMN APPS.XXSKY_ドリンク在庫実績_基本_V.棚卸ケース数            IS '棚卸ケース数'
/
COMMENT ON COLUMN APPS.XXSKY_ドリンク在庫実績_基本_V.棚卸バラ数              IS '棚卸バラ数'
/
COMMENT ON COLUMN APPS.XXSKY_ドリンク在庫実績_基本_V.積送中在庫ケース数      IS '積送中在庫ケース数'
/
COMMENT ON COLUMN APPS.XXSKY_ドリンク在庫実績_基本_V.積送中在庫バラ数        IS '積送中在庫バラ数'
/
COMMENT ON COLUMN APPS.XXSKY_ドリンク在庫実績_基本_V.論理_月末在庫ケース数   IS '論理_月末在庫ケース数'
/
COMMENT ON COLUMN APPS.XXSKY_ドリンク在庫実績_基本_V.論理_月末在庫バラ数     IS '論理_月末在庫バラ数'
/
COMMENT ON COLUMN APPS.XXSKY_ドリンク在庫実績_基本_V.返品_月間入庫ケース数   IS '返品_月間入庫ケース数'
/
COMMENT ON COLUMN APPS.XXSKY_ドリンク在庫実績_基本_V.返品_月間入庫バラ数     IS '返品_月間入庫バラ数'
/
COMMENT ON COLUMN APPS.XXSKY_ドリンク在庫実績_基本_V.生産_月間入庫ケース数   IS '生産_月間入庫ケース数'
/
COMMENT ON COLUMN APPS.XXSKY_ドリンク在庫実績_基本_V.生産_月間入庫バラ数     IS '生産_月間入庫バラ数'
/
COMMENT ON COLUMN APPS.XXSKY_ドリンク在庫実績_基本_V.移動_月間入庫ケース数   IS '移動_月間入庫ケース数'
/
COMMENT ON COLUMN APPS.XXSKY_ドリンク在庫実績_基本_V.移動_月間入庫バラ数     IS '移動_月間入庫バラ数'
/
COMMENT ON COLUMN APPS.XXSKY_ドリンク在庫実績_基本_V.その他_月間入庫ケース数 IS 'その他_月間入庫ケース数'
/
COMMENT ON COLUMN APPS.XXSKY_ドリンク在庫実績_基本_V.その他_月間入庫バラ数   IS 'その他_月間入庫バラ数'
/
COMMENT ON COLUMN APPS.XXSKY_ドリンク在庫実績_基本_V.拠点_月間出庫ケース数   IS '拠点_月間出庫ケース数'
/
COMMENT ON COLUMN APPS.XXSKY_ドリンク在庫実績_基本_V.拠点_月間出庫バラ数     IS '拠点_月間出庫バラ数'
/
COMMENT ON COLUMN APPS.XXSKY_ドリンク在庫実績_基本_V.移動_月間出庫ケース数   IS '移動_月間出庫ケース数'
/
COMMENT ON COLUMN APPS.XXSKY_ドリンク在庫実績_基本_V.移動_月間出庫バラ数     IS '移動_月間出庫バラ数'
/
COMMENT ON COLUMN APPS.XXSKY_ドリンク在庫実績_基本_V.その他_月間出庫ケース数 IS 'その他_月間出庫ケース数'
/
COMMENT ON COLUMN APPS.XXSKY_ドリンク在庫実績_基本_V.その他_月間出庫バラ数   IS 'その他_月間出庫バラ数'
/
