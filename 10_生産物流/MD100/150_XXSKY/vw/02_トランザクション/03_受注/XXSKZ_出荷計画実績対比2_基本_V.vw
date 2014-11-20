/*************************************************************************
 * 
 * View  Name      : XXSKZ_出荷計画実績対比2_基本_V
 * Description     : XXSKZ_出荷計画実績対比2_基本_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2012/11/22    1.0   SCSK 月野    初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_出荷計画実績対比2_基本_V
(
 着日
,商品区分
,商品区分名
,品目区分
,品目区分名
,群コード
,品目
,品目名
,品目略称
,拠点
,拠点名
--2009.02.16 Add->
,出荷元保管場所
,出荷元保管場所名
--2009.02.16 Add<-
,引取計画数
,出荷予定数
,出荷実績数
,差異数
,引取率
)
AS
SELECT  SMSP.arrival_date            arrival_date     --着日
       ,PRODC.prod_class_code        prod_class_code  --商品区分
       ,PRODC.prod_class_name        prod_class_name  --商品区分名
       ,ITEMC.item_class_code        item_class_code  --品目区分
       ,ITEMC.item_class_name        item_class_name  --品目区分名
       ,CROWD.crowd_code             crowd_code       --群コード
       ,SMSP.item_code               item_code        --出荷品目
       ,ITEM.item_name               item_name        --出荷品目名
       ,ITEM.item_short_name         item_s_name      --出荷品目略称
       ,SMSP.branch                  branch           --拠点
       ,CSACT.party_name             branch_name      --拠点名
--2009.02.16 Add->
       ,SMSP.deliver_from            deliver_from     --出荷元保管場所
       ,XIL2V.DESCRIPTION            deliver_name     --出荷元保管場所名
--2009.02.16 Add<-
       ,NVL( SMSP.forecast_qty, 0 )  forecast_qty     --引取計画数
       ,NVL( SMSP.request_qty , 0 )  request_qty      --出荷予定数
       ,NVL( SMSP.shipped_qty , 0 )  shipped_qty      --出荷実績数
       ,NVL( SMSP.forecast_qty, 0 ) - NVL( SMSP.shipped_qty , 0 )
                                     deff_qty         --差異数
       ,CASE WHEN ( NVL( SMSP.forecast_qty, 0 ) = 0 ) THEN
                 0    --0割対策
             ELSE  -- 引取率 = ( 出荷実績数 / 引取計画数 ) * 100   ⇒小数点第３位以下四捨五入
                 ROUND( ( ( NVL( SMSP.shipped_qty , 0 ) / SMSP.forecast_qty ) * 100 ), 2 )
        END                          forecast_rate    --引取率
  FROM  ( --出荷データ＋引取計画データを集計
          SELECT  SHIP.arrival_date                         --着日
                 ,SHIP.item_code                            --出荷品目コード
                 ,SHIP.branch                               --管轄拠点コード
--2009.02.16 Add->
                 ,SHIP.deliver_from                         --出荷元保管場所
--2009.02.16 Add<-
                 ,SUM( SHIP.forecast_qty )    forecast_qty  --引取計画数
                 ,SUM( SHIP.request_qty  )    request_qty   --出荷予定数
                 ,SUM( SHIP.shipped_qty  )    shipped_qty   --出荷実績数
            FROM  (  --集計元データ（受注テーブルのレコード単位）
                     -------------------------------------------------
                     -- 出荷データ（予定）
                     -------------------------------------------------
                     SELECT  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date )
                                                               arrival_date      --着日(着日予定日)
                            ,XOLA.shipping_item_code           item_code         --出荷品目コード
                            ,XOHA.head_sales_branch            branch            --拠点コード(管轄拠点)
--2009.02.16 Add->
                            ,XOHA.deliver_from                 deliver_from      --出荷元保管場所
--2009.02.16 Add<-
                            ,0                                 forecast_qty      --引取計画数
                            ,XOLA.quantity                     request_qty       --出荷予定数（指示数）
                            ,0                                 shipped_qty       --出荷実績数
                       FROM  xxcmn_order_headers_all_arc           XOHA              --受注ヘッダ（アドオン）バックアップ
                            ,xxcmn_order_lines_all_arc             XOLA              --受注明細（アドオン）バックアップ
                            ,oe_transaction_types_all          OTTA              --受注タイプ
                      WHERE  XOHA.order_type_id                = OTTA.transaction_type_id
                        AND  OTTA.attribute1                   = '1'             --'1:出荷'
                        AND  OTTA.attribute4                   = '1'             --'1:通常出荷'(見本、廃棄を除く)
                        AND  OTTA.order_category_code          = 'ORDER'
                        AND  XOHA.req_status                   = '03'            --'03:締め済み'
                        AND  XOHA.latest_external_flag         = 'Y'             --最新フラグ有効
                        AND  NVL( XOLA.delete_flag, 'N' )     <> 'Y'             --無効明細以外
                        AND  XOLA.quantity                    <> 0
                        AND  XOHA.order_header_id              = XOLA.order_header_id
                   UNION ALL
                     -------------------------------------------------
                     -- 出荷データ（実績）
                     -------------------------------------------------
                     SELECT  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date )
                                                               arrival_date      --着日(着日予定日)
                            ,XOLA.shipping_item_code           item_code         --出荷品目コード
                            ,XOHA.head_sales_branch            branch            --拠点コード(管轄拠点)
--2009.02.16 Add->
                            ,XOHA.deliver_from                 deliver_from      --出荷元保管場所
--2009.02.16 Add<-
                            ,0                                 forecast_qty      --引取計画数
                            ,0                                 request_qty       --出荷予定数
                            ,XOLA.shipped_quantity             shipped_qty       --出荷実績数
                       FROM  xxcmn_order_headers_all_arc           XOHA              --受注ヘッダ（アドオン）バックアップ
                            ,xxcmn_order_lines_all_arc             XOLA              --受注明細（アドオン）バックアップ
                            ,oe_transaction_types_all          OTTA              --受注タイプ
                      WHERE  XOHA.order_type_id                = OTTA.transaction_type_id
                        AND  OTTA.attribute1                   = '1'             --'1:出荷'
                        AND  OTTA.attribute4                   = '1'             --'1:通常出荷'(見本、廃棄を除く)
                        AND  OTTA.order_category_code          = 'ORDER'
                        AND  XOHA.req_status                   = '04'            --'04:実績計上済'
                        AND  XOHA.latest_external_flag         = 'Y'             --最新フラグ有効
                        AND  NVL( XOLA.delete_flag, 'N' )     <> 'Y'             --無効明細以外
                        AND  XOLA.shipped_quantity            <> 0
                        AND  XOHA.order_header_id              = XOLA.order_header_id
                   UNION ALL
                     -------------------------------------------------
                     -- 引取計画データ
                     -------------------------------------------------
                     SELECT  MFDT.forecast_date                arrival_date      --着日(計画日)
                            ,XIMV.item_no                      item_code         --出荷品目コード
                            ,MFDN.attribute3                   branch            --拠点コード
--2009.02.16 Add->
                            ,MFDN.attribute2                   deliver_from      --出荷元保管場所
--2009.02.16 Add<-
                            ,MFDT.original_forecast_quantity   forecast_qty      --引取計画数(予測当初数量)
                            ,0                                 request_qty       --出荷予定数
                            ,0                                 shipped_qty       --出荷実績数
                       FROM  mrp_forecast_designators          MFDN              --フォーキャスト名テーブル
                            ,mrp_forecast_dates                MFDT              --フォーキャスト日付テーブル
                            ,xxskz_item_mst2_v                 XIMV              --品目情報取得用
                      WHERE  MFDN.attribute1                   = '01'            --引取計画
                        AND  MFDN.organization_id              = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
                        AND  MFDT.original_forecast_quantity  <> 0
                        AND  MFDN.forecast_designator          = MFDT.forecast_designator
                        AND  MFDN.organization_id              = MFDT.organization_id
                        AND  MFDT.inventory_item_id            = XIMV.inventory_item_id(+)
                        AND  MFDT.forecast_date               >= XIMV.start_date_active(+)
                        AND  MFDT.forecast_date               <= XIMV.end_date_active(+)
                  )    SHIP
          GROUP BY  SHIP.arrival_date
                   ,SHIP.item_code
                   ,SHIP.branch
--2009.02.16 Add->
                   ,SHIP.deliver_from
--2009.02.16 Add<-
        )                         SMSP
        --以下は上記SQL内部の項目を使用して外部結合を行うもの(エラー回避策)
       ,xxskz_item_mst2_v         ITEM
       ,xxskz_prod_class_v        PRODC
       ,xxskz_item_class_v        ITEMC
       ,xxskz_crowd_code_v        CROWD
       ,xxskz_cust_accounts2_v    CSACT
--2009.02.16 Add->
       ,xxskz_item_locations2_v   XIL2V
--2009.02.16 Add<-
 WHERE
   --品目情報取得条件
        SMSP.item_code    =  ITEM.item_no(+)
   AND  SMSP.arrival_date >= ITEM.start_date_active(+)
   AND  SMSP.arrival_date <= ITEM.end_date_active(+)
   --品目のカテゴリ情報取得条件
   AND  ITEM.item_id = PRODC.item_id(+)    --商品区分
   AND  ITEM.item_id = ITEMC.item_id(+)    --品目区分
   AND  ITEM.item_id = CROWD.item_id(+)    --群コード
   --拠点名取得条件
   AND  SMSP.branch       =  CSACT.party_number(+)
   AND  SMSP.arrival_date >= CSACT.start_date_active(+)
   AND  SMSP.arrival_date <= CSACT.end_date_active(+)
--2009.02.16 Add->
   --出荷元保管場所名取得
   AND  SMSP.deliver_from = XIL2V.segment1(+)
--2009.02.16 Add<-
/
COMMENT ON TABLE APPS.XXSKZ_出荷計画実績対比2_基本_V IS 'SKYLINK用 XXSKZ_出荷計画実績対比2（基本）VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷計画実績対比2_基本_V.着日 IS '着日'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷計画実績対比2_基本_V.商品区分 IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷計画実績対比2_基本_V.商品区分名 IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷計画実績対比2_基本_V.品目区分 IS '品目区分'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷計画実績対比2_基本_V.品目区分名 IS '品目区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷計画実績対比2_基本_V.群コード IS '群コード'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷計画実績対比2_基本_V.品目 IS '品目'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷計画実績対比2_基本_V.品目名 IS '品目名'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷計画実績対比2_基本_V.品目略称 IS '品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷計画実績対比2_基本_V.拠点 IS '拠点'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷計画実績対比2_基本_V.拠点名 IS '拠点名'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷計画実績対比2_基本_V.出荷元保管場所 IS '出荷元保管場所'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷計画実績対比2_基本_V.出荷元保管場所名 IS '出荷元保管場所名'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷計画実績対比2_基本_V.引取計画数 IS '引取計画数'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷計画実績対比2_基本_V.出荷予定数 IS '出荷予定数'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷計画実績対比2_基本_V.出荷実績数 IS '出荷実績数'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷計画実績対比2_基本_V.差異数 IS '差異数'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷計画実績対比2_基本_V.引取率 IS '引取率'
/
