/*************************************************************************
 * 
 * View  Name      : XXSKZ_運賃品目別_基本_V
 * Description     : XXSKZ_運賃品目別_基本_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2012/11/26    1.0   SCSK 月野    初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_運賃品目別_基本_V
(
 配送NO
,依頼_移動NO
,区分
,受注タイプ
,ステータス
,ステータス名
,管轄拠点
,管轄拠点名
,運送業者
,運送業者名
,運送業者略称
,入庫先_配送先
,入庫先_配送先名
,入庫先_配送先略称
,出庫元
,出庫元名
,出庫元略称
,配送区分
,配送区分名
,出庫日
,入庫日
,商品区分
,商品区分名
,品目区分
,品目区分名
,群コード
,品目コード
,品目名称
,品目略称
,品目バラ数
,品目ケース数
,合計ケース数
,積載重量合計
,按分計算用_積載重量合計
,品目重量合計
,按分計算用_品目重量合計
,合計金額
,品目_合計金額
)
AS
SELECT
        UHK.delivery_no                     --配送No
       ,UHK.req_mov_no                      --依頼_移動No
       ,UHK.kbn                             --区分
       ,UHK.order_type                      --受注タイプ
       ,UHK.status                          --ステータス
       ,UHK.status_name                     --ステータス名
       ,UHK.branch                          --管轄拠点
       ,UHK.branch_name                     --管轄拠点名
       ,UHK.carrier_code                    --運送業者
       ,UHK.carrier_name                    --運送業者名
       ,UHK.carrier_short_name              --運送業者略称
       ,UHK.ship_deliver_to                 --入庫先_配送先
       ,UHK.ship_deliver_to_name            --入庫先_配送先名
       ,UHK.ship_deliver_to_short_name      --入庫先_配送先略称
       ,UHK.ship_from                       --出庫元
       ,UHK.ship_from_name                  --出庫元名
       ,UHK.ship_from_short_name            --出庫元略称
       ,UHK.ship_method_code                --配送区分
       ,UHK.ship_method_name                --配送区分名
       ,UHK.shipped_date                    --出庫日
       ,UHK.arrival_date                    --入庫日
       ,PRODC.prod_class_code               --商品区分
       ,PRODC.prod_class_name               --商品区分名
       ,ITEMC.item_class_code               --品目区分
       ,ITEMC.item_class_name               --品目区分名
       ,CROWD.crowd_code                    --群コード
       ,UHK.item_code                       --品目コード
       ,UHK.item_name                       --品目名称
       ,UHK.item_short_name                 --品目略称
       ,UHK.quantity                        --品目バラ数
       ,UHK.cs_quantity                     --品目ケース数
       ,UHK.sum_cs_quantity                 --合計ケース数
       ,UHK.sum_loading_weight              --積載重量合計
       ,UHK.distribute_sum_loading_weight   --按分計算用_積載重量合計
       ,UHK.item_weight                     --品目重量合計
       ,UHK.distribute_item_weight          --按分計算用_品目重量
       ,UHK.total_amount                    --合計金額
       ,UHK.item_total_amount               --品目_合計金額
  FROM
       (
        --=========================================================
        -- 出荷データ
        --=========================================================
        SELECT
                DELV.delivery_no                    delivery_no                     --配送No
               ,DELV.request_no                     req_mov_no                      --依頼_移動No
               ,'出荷'                              kbn                             --区分
               ,DELV.order_type_name                order_type                      --受注タイプ
               ,DELV.req_status                     status                          --ステータス
               ,FLV01.meaning                       status_name                     --ステータス名
               ,DELV.head_sales_branch              branch                          --管轄拠点
               ,XCAV.party_name                     branch_name                     --管轄拠点名
               ,DELV.freight_carrier_code           carrier_code                    --運送業者
               ,XCRV.party_name                     carrier_name                    --運送業者名
               ,XCRV.party_short_name               carrier_short_name              --運送業者略称
               ,DELV.deliver_to                     ship_deliver_to                 --入庫先_配送先
               ,XPSV.party_site_name                ship_deliver_to_name            --入庫先_配送先名
               ,XPSV.party_site_short_name          ship_deliver_to_short_name      --入庫先_配送先略称
               ,DELV.deliver_from                   ship_from                       --出庫元
               ,XILV.description                    ship_from_name                  --出庫元名
               ,XILV.short_name                     ship_from_short_name            --出庫元略称
               ,DELV.shipping_method_code           ship_method_code                --配送区分
               ,FLV02.meaning                       ship_method_name                --配送区分名
               ,DELV.shipped_date                   shipped_date                    --出庫日
               ,DELV.arrival_date                   arrival_date                    --入庫日
               ,ITEM.item_id                        item_id                         --品目ID
               ,ITEM.item_no                        item_code                       --品目コード
               ,ITEM.item_name                      item_name                       --品目名称
               ,ITEM.item_short_name                item_short_name                 --品目略称
               ,DELV.shipped_quantity               quantity                        --品目バラ数
               ,NVL( DELV.shipped_quantity / ITEM.num_of_cases, 0 )
                                                    cs_quantity                     --品目ケース数
               ,NVL( DELV.qty1, 0 )                 sum_cs_quantity                 --合計ケース数
-- 2010/1/8 #627 Y.Fukami Mod Start
--               ,ROUND(DELV.sum_loading_weight)      sum_loading_weight              --積載重量合計
               ,CEIL(TRUNC(NVL(DELV.sum_loading_weight,0),1))      
                                                    sum_loading_weight              --積載重量合計(小数点第2位以下を切り捨て後、小数点第1位を切り上げ)
-- 2010/1/8 #627 Y.Fukami Mod End
               ,DELV.distribute_sum_loading_weight  distribute_sum_loading_weight   --按分計算用_積載重量合計
-- 2010/1/8 #627 Y.Fukami Mod Start
--               ,ROUND(DELV.weight)                  item_weight                     --品目重量合計
               ,CEIL(TRUNC(NVL(DELV.weight,0),1))   item_weight                     --品目重量合計(小数点第2位以下を切り捨て後、小数点第1位を切り上げ)
-- 2010/1/8 #627 Y.Fukami Mod End
               ,DELV.distribute_item_weight         distribute_item_weight          --按分計算用_品目重量合計
               --配送単位と品目単位の運賃
               ,NVL( DELV.total_amount      , 0 )                       total_amount             --合計金額
               ,NVL( ROUND( DELV.total_amount       * item_rate ), 0 )  item_total_amount        --品目_合計金額
          FROM  (  --対象データを抽出
                   SELECT  XOHA.delivery_no                                          --配送No
                          ,XOHA.request_no                                           --依頼_移動No
                          ,XOHA.order_type_id                                        --受注タイプ
                          ,OTTT.name                         order_type_name         --受注タイプ名
                          ,XOHA.req_status                                           --ステータス
                          ,XOHA.head_sales_branch                                    --管轄拠点
                          ,XOHA.result_freight_carrier_id    freight_carrier_id      --運送業者ID
                          ,XOHA.result_freight_carrier_code  freight_carrier_code    --運送業者
                          ,XOHA.result_deliver_to_id         deliver_to_id           --出荷_配送先ID
                          ,XOHA.result_deliver_to            deliver_to              --出荷_配送先
                          ,XOHA.deliver_from_id                                      --出庫元ID
                          ,XOHA.deliver_from                                         --出庫元
                          ,XOHA.result_shipping_method_code  shipping_method_code    --配送区分
                          ,XOHA.shipped_date                                         --出庫日
                          ,XOHA.arrival_date                                         --入庫日
--                        ,XOLA.shipping_item_code                                   --出荷品目コード
                          ,XOLA.request_item_code                                    --依頼品目コード
                          ,XOLA.shipped_quantity                                     --品目_数量
                          ,XCS.sum_loading_weight            sum_loading_weight      --配送_積載重量合計
                          ,XCS.sum_loading_weight            distribute_sum_loading_weight      --配送_按分計算用_積載重量合計
                          ,XOLA.weight                                               --品目重量合計
                          ,XOLA.weight                       distribute_item_weight  --按分計算用_品目重量合計
                           --配送No内の品目重量割合（品目_重量合計 ÷ 配送_重量合計）
                          ,CASE WHEN XCS.sum_loading_weight = 0 THEN 0
                                ELSE XOLA.weight / XCS.sum_loading_weight
                           END                               item_rate               --配送No内の品目重量割合
                           --配送単位の運賃
                          ,XDLV.qty1                                                 --配送_個数１
                          ,XDLV.total_amount                                         --配送_合計金額
                     FROM  xxcmn_order_headers_all_arc         XOHA                  --受注ヘッダ（アドオン）バックアップ
                          ,oe_transaction_types_all        OTTA                      --受注タイプマスタ
                          ,oe_transaction_types_tl         OTTT                      --受注タイプ名マスタ
                          ,xxcmn_order_lines_all_arc           XOLA                  --受注明細（アドオン）バックアップ
                          ,(    -- 配送NO単位の積載重量合計算出
                            SELECT delivery_no                                       --配送NO
                                  ,SUM(sum_weight)   sum_loading_weight              --積載重量合計
                              FROM (SELECT delivery_no
                                          ,sum_weight
                                      FROM xxcmn_order_headers_all_arc               --受注ヘッダ（アドオン）バックアップ
                                     WHERE latest_external_flag = 'Y'
                                    UNION ALL
                                    SELECT delivery_no
                                          ,sum_weight
                                      FROM xxcmn_mov_req_instr_hdrs_arc              --移動依頼/指示ヘッダ（アドオン）バックアップ
                                   )
                            GROUP BY delivery_no
                           )                               XCS                      --配送NO単位積載重量合計
                          ,(
                            SELECT XD1.delivery_no                                  --配送NO
                                  ,XD1.qty1                                         --配送_個数１
                                  ,XD1.total_amount                                 --配送_合計金額
                              FROM xxwip_deliverys XD1
                             WHERE XD1.p_b_classe = '2'                             --'2:請求運賃'
                            UNION ALL
                            SELECT XD2.delivery_no                                  --配送NO
                                  ,XD2.qty1                                         --配送_個数１
                                  ,0                                                --配送_合計金額
                              FROM xxwip_deliverys XD2
                             WHERE XD2.p_b_classe = '1'                             --'1:支払運賃'
                               -- 支払請求区分が'1':支払運賃のみ
                               AND NOT EXISTS
                                   (
                                    SELECT 'X'
                                      FROM xxwip_deliverys XD3
                                      WHERE XD3.p_b_classe = '2'                    --'2:請求運賃'
                                        AND XD3.delivery_no = XD2.delivery_no
                                   )
                           )                               XDLV                     --運賃ヘッダアドオン
                    WHERE
                      -- 出荷データ取得条件
                           OTTA.attribute1 = '1'                                    --'1:出荷'
                      -- 出荷ヘッダデータ取得条件
                      AND  XOHA.latest_external_flag = 'Y'                          --最新フラグ
                      AND  XOHA.order_type_id = OTTA.transaction_type_id
                      AND  XOHA.req_status = '04'                                   --出荷実績計上済のみ
                      -- 出荷明細データ取得条件
                      AND  NVL(XOLA.delete_flag, 'N') <> 'Y'
                      AND  XOHA.order_header_id = XOLA.order_header_id
                      -- 配送NO単位積載重量合計取得条件
                      AND  XOHA.delivery_no = XCS.delivery_no
                      -- 運賃ヘッダアドオン情報取得条件
                      AND  XOHA.delivery_no = XDLV.delivery_no
                      -- 受注タイプ名取得条件
                      AND  OTTT.language(+) = 'JA'
                      AND  XOHA.order_type_id = OTTT.transaction_type_id(+)
                )  DELV
               ,xxskz_cust_accounts2_v          XCAV     --SKYLINK用中間VIEW 顧客情報VIEW2(管轄拠点)
               ,xxskz_carriers2_v               XCRV     --SKYLINK用中間VIEW 運送業者情報VIEW2(運送業者名)
               ,xxskz_party_sites2_v            XPSV     --SKYLINK用中間VIEW 配送先情報VIEW2(配送先名)
               ,xxskz_item_locations2_v         XILV     --SKYLINK用中間VIEW OPM保管場所情報VIEW2(出庫元名)
               ,xxskz_item_mst2_v               ITEM     --SKYLINK用中間VIEW OPM品目情報VIEW2(品目情報)
               ,fnd_lookup_values               FLV01    --クイックコード(ステータス名)
               ,fnd_lookup_values               FLV02    --クイックコード(配送区分名)
         WHERE
           -- 管轄拠点名取得条件
                DELV.head_sales_branch = XCAV.party_number(+)
           AND  DELV.arrival_date >= XCAV.start_date_active(+)
           AND  DELV.arrival_date <= XCAV.end_date_active(+)
           -- 運送業者_実績名取得条件
           AND  DELV.freight_carrier_id = XCRV.party_id(+)
           AND  DELV.arrival_date >= XCRV.start_date_active(+)
           AND  DELV.arrival_date <= XCRV.end_date_active(+)
           -- 出荷_配送先名取得条件
-- *----------* 2009/06/23 本番#1438対応 start *----------*
--           AND  DELV.deliver_to_id = XPSV.party_site_id(+)
           AND  DELV.deliver_to    = XPSV.party_site_number(+)
-- *----------* 2009/06/23 本番#1438対応 end   *----------*
           AND  DELV.arrival_date >= XPSV.start_date_active(+)
           AND  DELV.arrival_date <= XPSV.end_date_active(+)
           -- 出庫元名取得条件
           AND  DELV.deliver_from_id = XILV.inventory_location_id(+)
           -- 出荷品目情報取得条件
--         AND  DELV.shipping_item_code = ITEM.item_no(+)
           AND  DELV.request_item_code  = ITEM.item_no(+)
           AND  DELV.arrival_date >= ITEM.start_date_active(+)
           AND  DELV.arrival_date <= ITEM.end_date_active(+)
           -- ステータス名
           AND  FLV01.language(+)    = 'JA'
           AND  FLV01.lookup_type(+) = 'XXWSH_TRANSACTION_STATUS'
           AND  FLV01.lookup_code(+) = DELV.req_status
           -- 配送区分名
           AND  FLV02.language(+)    = 'JA'
           AND  FLV02.lookup_type(+) = 'XXCMN_SHIP_METHOD'
           AND  FLV02.lookup_code(+) = DELV.shipping_method_code
           -- 積載重量合計がゼロ以上のみ
           AND  NVL( DELV.sum_loading_weight, 0 ) > 0
        UNION ALL
        --=========================================================
        -- 出荷データ（積載重量合計ゼロのみ【積載重量ゼロで運賃が発生する場合がある為】）
        --=========================================================
        SELECT
                DELV.delivery_no                    delivery_no                     --配送No
               ,DELV.request_no                     req_mov_no                      --依頼_移動No
               ,'出荷'                              kbn                             --区分
               ,DELV.order_type_name                order_type                      --受注タイプ
               ,DELV.req_status                     status                          --ステータス
               ,FLV01.meaning                       status_name                     --ステータス名
               ,DELV.head_sales_branch              branch                          --管轄拠点
               ,XCAV.party_name                     branch_name                     --管轄拠点名
               ,DELV.freight_carrier_code           carrier_code                    --運送業者
               ,XCRV.party_name                     carrier_name                    --運送業者名
               ,XCRV.party_short_name               carrier_short_name              --運送業者略称
               ,DELV.deliver_to                     ship_deliver_to                 --入庫先_配送先
               ,XPSV.party_site_name                ship_deliver_to_name            --入庫先_配送先名
               ,XPSV.party_site_short_name          ship_deliver_to_short_name      --入庫先_配送先略称
               ,DELV.deliver_from                   ship_from                       --出庫元
               ,XILV.description                    ship_from_name                  --出庫元名
               ,XILV.short_name                     ship_from_short_name            --出庫元略称
               ,DELV.shipping_method_code           ship_method_code                --配送区分
               ,FLV02.meaning                       ship_method_name                --配送区分名
               ,DELV.shipped_date                   shipped_date                    --出庫日
               ,DELV.arrival_date                   arrival_date                    --入庫日
               ,ITEM.item_id                        item_id                         --品目ID
               ,ITEM.item_no                        item_code                       --品目コード
               ,ITEM.item_name                      item_name                       --品目名称
               ,ITEM.item_short_name                item_short_name                 --品目略称
               ,DELV.shipped_quantity               quantity                        --品目バラ数
               ,NVL( DELV.shipped_quantity / ITEM.num_of_cases, 0 )
                                                    cs_quantity                     --品目ケース数
               ,NVL( DELV.qty1, 0 )                 sum_cs_quantity                 --合計ケース数
-- 2010/1/8 #627 Y.Fukami Mod Start
--               ,ROUND(DELV.sum_loading_weight)      sum_loading_weight            --積載重量合計
               ,CEIL(TRUNC(NVL(DELV.sum_loading_weight,0),1))      
                                                    sum_loading_weight              --積載重量合計(小数点第2位以下を切り捨て後、小数点第1位を切り上げ)
-- 2010/1/8 #627 Y.Fukami Mod End
               ,DELV.distribute_sum_loading_weight  distribute_sum_loading_weight   --按分計算用_積載重量合計
-- 2010/1/8 #627 Y.Fukami Mod Start
--               ,ROUND(DELV.weight)                  item_weight                   --品目重量合計
               ,CEIL(TRUNC(NVL(DELV.weight,0),1))   item_weight                     --品目重量合計(小数点第2位以下を切り捨て後、小数点第1位を切り上げ)
-- 2010/1/8 #627 Y.Fukami Mod End
               ,DELV.distribute_item_weight         distribute_item_weight          --按分計算用_品目重量合計
               --配送単位と品目単位の運賃
               --運賃がある場合、配送単位の最大依頼NOの最大明細番号にセットする
               ,CASE WHEN DELV.req_mov_line = DELV.request_no || LPAD(order_line_number, 5, '0')
                     THEN NVL( DELV.total_amount      , 0 )
                     ELSE 0
                END                                 total_amount                     --合計金額
               ,CASE WHEN DELV.req_mov_line = DELV.request_no || LPAD(order_line_number, 5, '0')
                     THEN NVL( DELV.total_amount      , 0 )
                     ELSE 0
                END                                 item_total_amount                --品目_合計金額
          FROM  (  --対象データを抽出
                   SELECT  XOHA.delivery_no                                          --配送No
                          ,XOHA.request_no                                           --依頼_移動No
                          ,XOLA.order_line_number                                    --明細番号
                          ,XOHA.order_type_id                                        --受注タイプ
                          ,OTTT.name                         order_type_name         --受注タイプ名
                          ,XOHA.req_status                                           --ステータス
                          ,XOHA.head_sales_branch                                    --管轄拠点
                          ,XOHA.result_freight_carrier_id    freight_carrier_id      --運送業者ID
                          ,XOHA.result_freight_carrier_code  freight_carrier_code    --運送業者
                          ,XOHA.result_deliver_to_id         deliver_to_id           --出荷_配送先ID
                          ,XOHA.result_deliver_to            deliver_to              --出荷_配送先
                          ,XOHA.deliver_from_id                                      --出庫元ID
                          ,XOHA.deliver_from                                         --出庫元
                          ,XOHA.result_shipping_method_code  shipping_method_code    --配送区分
                          ,XOHA.shipped_date                                         --出庫日
                          ,XOHA.arrival_date                                         --入庫日
--                        ,XOLA.shipping_item_code                                   --出荷品目コード
                          ,XOLA.request_item_code                                    --依頼品目コード
                          ,XOLA.shipped_quantity                                     --品目_数量
                          ,XCS.sum_loading_weight            sum_loading_weight      --配送_積載重量合計
                          ,XCS.sum_loading_weight            distribute_sum_loading_weight      --配送_按分計算用_積載重量合計
                          ,XOLA.weight                                               --品目重量合計
                          ,XOLA.weight                       distribute_item_weight  --按分計算用_品目重量合計
                          ,RML.req_mov_line                                          --最大依頼・明細番号
                           --配送No内の品目重量割合（品目_重量合計 ÷ 配送_重量合計）
                          ,CASE WHEN XCS.sum_loading_weight = 0 THEN 0
                                ELSE XOLA.weight / XCS.sum_loading_weight
                           END                               item_rate               --配送No内の品目重量割合
                           --配送単位の運賃
                          ,XDLV.qty1                                                 --配送_個数１
                          ,XDLV.total_amount                                         --配送_合計金額
                     FROM  xxcmn_order_headers_all_arc         XOHA                      --受注ヘッダ（アドオン）バックアップ
                          ,oe_transaction_types_all        OTTA                      --受注タイプマスタ
                          ,oe_transaction_types_tl         OTTT                      --受注タイプ名マスタ
                          ,xxcmn_order_lines_all_arc           XOLA                      --受注明細（アドオン）バックアップ
                          ,(    -- 配送NO単位の積載重量合計算出
                            SELECT delivery_no                                       --配送NO
                                  ,SUM(sum_weight)   sum_loading_weight              --積載重量合計
                              FROM (SELECT delivery_no
                                          ,sum_weight
                                      FROM xxcmn_order_headers_all_arc               --受注ヘッダ（アドオン）バックアップ
                                     WHERE latest_external_flag = 'Y'
                                    UNION ALL
                                    SELECT delivery_no
                                          ,sum_weight
                                      FROM xxcmn_mov_req_instr_hdrs_arc              --移動依頼/指示ヘッダ（アドオン）バックアップ
                                   )
                            GROUP BY delivery_no
                           )                               XCS                       --配送NO単位積載重量合計
                          ,(
                            SELECT XD1.delivery_no                                   --配送NO
                                  ,XD1.qty1                                          --配送_個数１
                                  ,XD1.total_amount                                  --配送_合計金額
                              FROM xxwip_deliverys XD1
                             WHERE XD1.p_b_classe = '2'                              --'2:請求運賃'
                            UNION ALL
                            SELECT XD2.delivery_no                                   --配送NO
                                  ,XD2.qty1                                          --配送_個数１
                                  ,0                                                 --配送_合計金額
                              FROM xxwip_deliverys XD2
                             WHERE XD2.p_b_classe = '1'                              --'1:支払運賃'
                               -- 支払請求区分が'1':支払運賃のみ
                               AND NOT EXISTS
                                   (
                                    SELECT 'X'
                                      FROM xxwip_deliverys XD3
                                      WHERE XD3.p_b_classe = '2'                     --'2:請求運賃'
                                        AND XD3.delivery_no = XD2.delivery_no
                                   )
                           )                               XDLV                      --運賃ヘッダアドオン
                          ,(    -- 配送NO単位の最大依頼NO、最大明細番号取得
                            SELECT delivery_no
                                  ,req_mov_line
                              FROM (SELECT OH.delivery_no
                                          ,MAX(OH.request_no || LPAD(OL.order_line_number, 5, '0')) req_mov_line
                                      FROM xxcmn_order_headers_all_arc  OH  --受注ヘッダ（アドオン）バックアップ
                                          ,xxcmn_order_lines_all_arc    OL   --受注明細（アドオン）バックアップ
                                     WHERE OH.order_header_id = OL.order_header_id
                                       AND OH.latest_external_flag = 'Y'
                                       AND NVL(OL.delete_flag, 'N') <> 'Y'
                                    GROUP BY OH.delivery_no
                                    UNION ALL
                                    SELECT MH.delivery_no
                                          ,MAX(MH.mov_num || LPAD(ML.line_number, 5, '0')) req_mov_line
                                      FROM xxcmn_mov_req_instr_hdrs_arc    MH          --移動依頼/指示ヘッダ（アドオン）バックアップ
                                          ,xxcmn_mov_req_instr_lines_arc   ML        --移動依頼/指示明細（アドオン）バックアップ
                                     WHERE MH.mov_hdr_id = ML.mov_hdr_id
                                       AND NVL( ML.delete_flg, 'N' ) <> 'Y'          --無効明細以外
                                    GROUP BY MH.delivery_no
                                   )
                           )                               RML                       --配送NO単位の最大依頼・明細番号情報
                    WHERE
                      -- 出荷データ取得条件
                           OTTA.attribute1 = '1'                                     --'1:出荷'
                      -- 出荷ヘッダデータ取得条件
                      AND  XOHA.latest_external_flag = 'Y'                           --最新フラグ
                      AND  XOHA.order_type_id = OTTA.transaction_type_id
                      AND  XOHA.req_status = '04'                                    --出荷実績計上済のみ
                      -- 出荷明細データ取得条件
                      AND  NVL(XOLA.delete_flag, 'N') <> 'Y'
                      AND  XOHA.order_header_id = XOLA.order_header_id
                      -- 配送NO単位積載重量合計取得条件
                      AND  XOHA.delivery_no = XCS.delivery_no
                      -- 運賃ヘッダアドオン情報取得条件
                      AND  XOHA.delivery_no = XDLV.delivery_no
                      -- 配送NO単位最大依頼・明細番号取得条件
                      AND  XOHA.delivery_no = RML.delivery_no
                      -- 受注タイプ名取得条件
                      AND  OTTT.language(+) = 'JA'
                      AND  XOHA.order_type_id = OTTT.transaction_type_id(+)
                )  DELV
               ,xxskz_cust_accounts2_v          XCAV     --SKYLINK用中間VIEW 顧客情報VIEW2(管轄拠点)
               ,xxskz_carriers2_v               XCRV     --SKYLINK用中間VIEW 運送業者情報VIEW2(運送業者名)
               ,xxskz_party_sites2_v            XPSV     --SKYLINK用中間VIEW 配送先情報VIEW2(配送先名)
               ,xxskz_item_locations2_v         XILV     --SKYLINK用中間VIEW OPM保管場所情報VIEW2(出庫元名)
               ,xxskz_item_mst2_v               ITEM     --SKYLINK用中間VIEW OPM品目情報VIEW2(品目情報)
               ,fnd_lookup_values               FLV01    --クイックコード(ステータス名)
               ,fnd_lookup_values               FLV02    --クイックコード(配送区分名)
         WHERE
           -- 管轄拠点名取得条件
                DELV.head_sales_branch = XCAV.party_number(+)
           AND  DELV.arrival_date >= XCAV.start_date_active(+)
           AND  DELV.arrival_date <= XCAV.end_date_active(+)
           -- 運送業者_実績名取得条件
           AND  DELV.freight_carrier_id = XCRV.party_id(+)
           AND  DELV.arrival_date >= XCRV.start_date_active(+)
           AND  DELV.arrival_date <= XCRV.end_date_active(+)
           -- 出荷_配送先名取得条件
-- *----------* 2009/06/23 本番#1438対応 start *----------*
--           AND  DELV.deliver_to_id = XPSV.party_site_id(+)
           AND  DELV.deliver_to    = XPSV.party_site_number(+)
-- *----------* 2009/06/23 本番#1438対応 end   *----------*
           AND  DELV.arrival_date >= XPSV.start_date_active(+)
           AND  DELV.arrival_date <= XPSV.end_date_active(+)
           -- 出庫元名取得条件
           AND  DELV.deliver_from_id = XILV.inventory_location_id(+)
           -- 出荷品目情報取得条件
--         AND  DELV.shipping_item_code = ITEM.item_no(+)
           AND  DELV.request_item_code  = ITEM.item_no(+)
           AND  DELV.arrival_date >= ITEM.start_date_active(+)
           AND  DELV.arrival_date <= ITEM.end_date_active(+)
           -- ステータス名
           AND  FLV01.language(+)    = 'JA'
           AND  FLV01.lookup_type(+) = 'XXWSH_TRANSACTION_STATUS'
           AND  FLV01.lookup_code(+) = DELV.req_status
           -- 配送区分名
           AND  FLV02.language(+)    = 'JA'
           AND  FLV02.lookup_type(+) = 'XXCMN_SHIP_METHOD'
           AND  FLV02.lookup_code(+) = DELV.shipping_method_code
           -- 積載重量合計がゼロのみ
           AND  NVL( DELV.sum_loading_weight, 0 ) = 0
-- 2009.01.21↓
        UNION ALL
        --=========================================================
        -- 出荷データ（運賃アドオンに存在しないもの）
        --=========================================================
        SELECT
                DELV.delivery_no                    delivery_no                     --配送No
               ,DELV.request_no                     req_mov_no                      --依頼_移動No
               ,'出荷'                              kbn                             --区分
               ,DELV.order_type_name                order_type                      --受注タイプ
               ,DELV.req_status                     status                          --ステータス
               ,FLV01.meaning                       status_name                     --ステータス名
               ,DELV.head_sales_branch              branch                          --管轄拠点
               ,XCAV.party_name                     branch_name                     --管轄拠点名
               ,DELV.freight_carrier_code           carrier_code                    --運送業者
               ,XCRV.party_name                     carrier_name                    --運送業者名
               ,XCRV.party_short_name               carrier_short_name              --運送業者略称
               ,DELV.deliver_to                     ship_deliver_to                 --入庫先_配送先
               ,XPSV.party_site_name                ship_deliver_to_name            --入庫先_配送先名
               ,XPSV.party_site_short_name          ship_deliver_to_short_name      --入庫先_配送先略称
               ,DELV.deliver_from                   ship_from                       --出庫元
               ,XILV.description                    ship_from_name                  --出庫元名
               ,XILV.short_name                     ship_from_short_name            --出庫元略称
               ,DELV.shipping_method_code           ship_method_code                --配送区分
               ,FLV02.meaning                       ship_method_name                --配送区分名
               ,DELV.shipped_date                   shipped_date                    --出庫日
               ,DELV.arrival_date                   arrival_date                    --入庫日
               ,ITEM.item_id                        item_id                         --品目ID
               ,ITEM.item_no                        item_code                       --品目コード
               ,ITEM.item_name                      item_name                       --品目名称
               ,ITEM.item_short_name                item_short_name                 --品目略称
               ,DELV.shipped_quantity               quantity                        --品目バラ数
               ,NVL( DELV.shipped_quantity / ITEM.num_of_cases, 0 )
                                                    cs_quantity                     --品目ケース数
--             ,NVL( DELV.qty1 / ITEM.num_of_cases, 0 )
--                                                  sum_cs_quantity                 --合計ケース数
               ,DELV.qty1                           sum_cs_quantity                 --合計ケース数
-- 2010/1/8 #627 Y.Fukami Mod Start
--               ,ROUND(DELV.sum_loading_weight)      sum_loading_weight              --積載重量合計
               ,CEIL(TRUNC(NVL(DELV.sum_loading_weight,0),1))      
                                                    sum_loading_weight              --積載重量合計(小数点第2位以下を切り捨て後、小数点第1位を切り上げ)
-- 2010/1/8 #627 Y.Fukami Mod End
               ,DELV.distribute_sum_loading_weight  distribute_sum_loading_weight   --按分計算用_積載重量合計
-- 2010/1/8 #627 Y.Fukami Mod Start
--               ,ROUND(DELV.weight)                  item_weight                     --品目重量合計
               ,CEIL(TRUNC(NVL(DELV.weight,0),1))   item_weight                     --品目重量合計(小数点第2位以下を切り捨て後、小数点第1位を切り上げ)
-- 2010/1/8 #627 Y.Fukami Mod End
               ,DELV.distribute_item_weight         distribute_item_weight          --按分計算用_品目重量合計
               ,0                                   total_amount                    --合計金額
               ,0                                   item_total_amount               --品目_合計金額
          FROM  (  --対象データを抽出
                   SELECT  XOHA.delivery_no                                          --配送No
                          ,XOHA.request_no                                           --依頼_移動No
                          ,XOLA.order_line_number                                    --明細番号
                          ,XOHA.order_type_id                                        --受注タイプ
                          ,OTTT.name                         order_type_name         --受注タイプ名
                          ,XOHA.req_status                                           --ステータス
                          ,XOHA.head_sales_branch                                    --管轄拠点
                          ,XOHA.result_freight_carrier_id    freight_carrier_id      --運送業者ID
                          ,XOHA.result_freight_carrier_code  freight_carrier_code    --運送業者
                          ,XOHA.result_deliver_to_id         deliver_to_id           --出荷_配送先ID
                          ,XOHA.result_deliver_to            deliver_to              --出荷_配送先
                          ,XOHA.deliver_from_id                                      --出庫元ID
                          ,XOHA.deliver_from                                         --出庫元
                          ,XOHA.result_shipping_method_code  shipping_method_code    --配送区分
                          ,XOHA.shipped_date                                         --出庫日
                          ,XOHA.arrival_date                                         --入庫日
--                        ,XOLA.shipping_item_code                                   --出荷品目コード
                          ,XOLA.request_item_code                                    --依頼品目コード
                          ,XOLA.shipped_quantity                                     --品目_数量
                          ,XCS.sum_loading_weight            sum_loading_weight      --配送_積載重量合計
                          ,XCS.sum_loading_weight            distribute_sum_loading_weight      --配送_按分計算用_積載重量合計
                          ,XOLA.weight                                               --品目重量合計
                          ,XOLA.weight                       distribute_item_weight  --按分計算用_品目重量合計
                           --配送No内の品目重量割合（品目_重量合計 ÷ 配送_重量合計）
                          ,CASE WHEN XCS.sum_loading_weight = 0 THEN 0
                                ELSE XOLA.weight / XCS.sum_loading_weight
                           END                               item_rate               --配送No内の品目重量割合
                           --配送単位の運賃
                          ,XCS.sum_loading_quantity          qty1                    --個数１
                     FROM  xxcmn_order_headers_all_arc         XOHA                      --受注ヘッダ（アドオン）バックアップ
                          ,oe_transaction_types_all        OTTA                      --受注タイプマスタ
                          ,oe_transaction_types_tl         OTTT                      --受注タイプ名マスタ
                          ,xxcmn_order_lines_all_arc           XOLA                      --受注明細（アドオン）バックアップ
                          ,(    -- 配送NO単位の積載重量合計算出
                            SELECT delivery_no                                       --配送NO
                                  ,SUM(sum_quantity) sum_loading_quantity
                                  ,SUM(sum_weight)   sum_loading_weight              --積載重量合計
                              FROM (
                                    SELECT delivery_no
                                          ,NVL(shipped_quantity / ITEM11.num_of_cases, 0)  sum_quantity
                                          ,weight                                          sum_weight
                                      FROM (
                                            SELECT XOHA.delivery_no
                                                  ,XOHA.arrival_date
--                                                ,XOLA.shipping_item_code
                                                  ,XOLA.request_item_code
                                                  ,XOLA.shipped_quantity
                                                  ,XOLA.weight
                                              FROM xxcmn_order_headers_all_arc  XOHA,  --受注ヘッダ（アドオン）バックアップ
                                                   xxcmn_order_lines_all_arc    XOLA  --受注明細（アドオン）バックアップ
                                             WHERE NVL(XOLA.delete_flag, 'N') <> 'Y'
                                               AND XOHA.order_header_id = XOLA.order_header_id
                                               AND XOHA.delivery_no IS NOT NULL
                                               AND XOHA.latest_external_flag = 'Y'
                                               AND XOHA.req_status = '04'
                                           )  XOHA11,
                                           xxskz_item_mst2_v   ITEM11
--                                   WHERE XOHA11.shipping_item_code = ITEM11.item_no(+)
                                     WHERE XOHA11.request_item_code  = ITEM11.item_no(+)
                                       AND XOHA11.arrival_date >= ITEM11.start_date_active(+)
                                       AND XOHA11.arrival_date <= ITEM11.end_date_active(+)
                                       AND XOHA11.delivery_no IS NOT NULL
                                    UNION ALL
                                    SELECT delivery_no
                                          ,NVL(shipped_quantity / ITEM11.num_of_cases, 0)  sum_quantity
                                          ,weight                                          sum_weight
                                      FROM (
                                            SELECT XMRH11.delivery_no
                                                  ,XMRH11.actual_arrival_date
                                                  ,XMRL11.item_code
                                                  ,XMRL11.shipped_quantity
                                                  ,XMRL11.weight
                                              FROM xxcmn_mov_req_instr_hdrs_arc   XMRH11   --移動依頼/指示ヘッダ（アドオン）バックアップ
                                                  ,xxcmn_mov_req_instr_lines_arc   XMRL11  --移動依頼/指示明細（アドオン）バックアップ
                                             WHERE NVL(XMRL11.delete_flg, 'N') <> 'Y'
                                               AND XMRH11.mov_hdr_id = XMRL11.mov_hdr_id
                                               AND XMRH11.delivery_no IS NOT NULL
                                           )  XMR11,
                                           xxskz_item_mst2_v   ITEM11
                                     WHERE XMR11.item_code = ITEM11.item_no(+)
                                       AND XMR11.actual_arrival_date >= ITEM11.start_date_active(+)
                                       AND XMR11.actual_arrival_date <= ITEM11.end_date_active(+)
                                       AND XMR11.delivery_no IS NOT NULL
                                   )
                            GROUP BY delivery_no
                           )                               XCS                       --配送NO単位積載重量合計
                    WHERE
                      -- 出荷データ取得条件
                           OTTA.attribute1 = '1'                                     --'1:出荷'
                      AND  OTTA.attribute4 = '1'
                      -- 出荷ヘッダデータ取得条件
                      AND  XOHA.latest_external_flag = 'Y'                           --最新フラグ
                      AND  XOHA.order_type_id = OTTA.transaction_type_id
                      AND  XOHA.req_status = '04'                                    --出荷実績計上済のみ
                      -- 出荷明細データ取得条件
                      AND  NVL(XOLA.delete_flag, 'N') <> 'Y'
                      AND  XOHA.order_header_id = XOLA.order_header_id
                      -- 配送NO単位積載重量合計取得条件
                      AND  XOHA.delivery_no = XCS.delivery_no
                      -- 受注タイプ名取得条件
                      AND  OTTT.language(+) = 'JA'
                      AND  XOHA.order_type_id = OTTT.transaction_type_id(+)
                      AND  NOT EXISTS(SELECT 'X' FROM xxwip_deliverys VD11
                                       WHERE VD11.delivery_no = XOHA.delivery_no
                                     )
                      AND  XOHA.delivery_no IS NOT NULL
                   UNION
                   SELECT  XOHA2.delivery_no                                          --配送No
                          ,XOHA2.request_no                                           --依頼_移動No
                          ,XOLA2.order_line_number                                    --明細番号
                          ,XOHA2.order_type_id                                        --受注タイプ
                          ,OTTT2.name                         order_type_name         --受注タイプ名
                          ,XOHA2.req_status                                           --ステータス
                          ,XOHA2.head_sales_branch                                    --管轄拠点
                          ,XOHA2.result_freight_carrier_id    freight_carrier_id      --運送業者ID
                          ,XOHA2.result_freight_carrier_code  freight_carrier_code    --運送業者
                          ,XOHA2.result_deliver_to_id         deliver_to_id           --出荷_配送先ID
                          ,XOHA2.result_deliver_to            deliver_to              --出荷_配送先
                          ,XOHA2.deliver_from_id                                      --出庫元ID
                          ,XOHA2.deliver_from                                         --出庫元
                          ,XOHA2.result_shipping_method_code  shipping_method_code    --配送区分
                          ,XOHA2.shipped_date                                         --出庫日
                          ,XOHA2.arrival_date                                         --入庫日
--                        ,XOLA2.shipping_item_code                                   --出荷品目コード
                          ,XOLA2.request_item_code                                    --依頼品目コード
                          ,XOLA2.shipped_quantity                                     --品目_数量
                          ,XCS2.sum_loading_weight            sum_loading_weight      --配送_積載重量合計
                          ,XCS2.sum_loading_weight            distribute_sum_loading_weight      --配送_按分計算用_積載重量合計
                          ,XOLA2.weight                                               --品目重量合計
                          ,XOLA2.weight                       distribute_item_weight  --按分計算用_品目重量合計
                           --配送No内の品目重量割合（品目_重量合計 ÷ 配送_重量合計）
                          ,CASE WHEN XCS2.sum_loading_weight = 0 THEN 0
                                ELSE XOLA2.weight / XCS2.sum_loading_weight
                           END                               item_rate               --配送No内の品目重量割合
                           --配送単位の運賃
                          ,XCS2.sum_loading_quantity          qty1                    --個数１
                     FROM  xxcmn_order_headers_all_arc         XOHA2                     --受注ヘッダ（アドオン）バックアップ
                          ,oe_transaction_types_all        OTTA2                     --受注タイプマスタ
                          ,oe_transaction_types_tl         OTTT2                     --受注タイプ名マスタ
                          ,xxcmn_order_lines_all_arc           XOLA2                     --受注明細（アドオン）バックアップ
                          ,(    -- 依頼NO単位の積載重量合計算出
                            SELECT request_no                                        --依頼NO
                                  ,SUM(sum_quantity) sum_loading_quantity
                                  ,SUM(sum_weight)   sum_loading_weight              --積載重量合計
                              FROM (
                                   SELECT request_no
                                          ,NVL(shipped_quantity / ITEM11.num_of_cases, 0)  sum_quantity
                                          ,weight                                          sum_weight
                                      FROM (
                                            SELECT XOHA.request_no
                                                  ,XOHA.arrival_date
--                                                ,XOLA.shipping_item_code
                                                  ,XOLA.request_item_code
                                                  ,XOLA.shipped_quantity
                                                  ,XOLA.weight
                                              FROM xxcmn_order_headers_all_arc  XOHA,  --受注ヘッダ（アドオン）バックアップ
                                                   xxcmn_order_lines_all_arc   XOLA  --受注明細（アドオン）バックアップ
                                             WHERE NVL(XOLA.delete_flag, 'N') <> 'Y'
                                               AND XOHA.order_header_id = XOLA.order_header_id
                                               AND XOHA.delivery_no IS NULL
                                               AND XOHA.latest_external_flag = 'Y'
                                               AND XOHA.req_status = '04'
                                           )  XOHA11,
                                           xxskz_item_mst2_v   ITEM11
--                                   WHERE XOHA11.shipping_item_code = ITEM11.item_no(+)
                                     WHERE XOHA11.request_item_code  = ITEM11.item_no(+)
                                       AND XOHA11.arrival_date >= ITEM11.start_date_active(+)
                                       AND XOHA11.arrival_date <= ITEM11.end_date_active(+)
                                   )
                            GROUP BY request_no
                           )     　                          XCS2                      --依頼NO単位積載重量合計
                    WHERE
                      -- 出荷データ取得条件
                           OTTA2.attribute1 = '1'                                     --'1:出荷'
                      AND  OTTA2.attribute4 = '1'
                      -- 出荷ヘッダデータ取得条件
                      AND  XOHA2.latest_external_flag = 'Y'                           --最新フラグ
                      AND  XOHA2.order_type_id = OTTA2.transaction_type_id
                      AND  XOHA2.req_status = '04'                                    --出荷実績計上済のみ
                      -- 出荷明細データ取得条件
                      AND  NVL(XOLA2.delete_flag, 'N') <> 'Y'
                      AND  XOHA2.order_header_id = XOLA2.order_header_id
                      -- 依頼NO単位積載重量合計取得条件
                      AND  XOHA2.request_no = XCS2.request_no
                      -- 受注タイプ名取得条件
                      AND  OTTT2.language(+) = 'JA'
                      AND  XOHA2.order_type_id = OTTT2.transaction_type_id(+)
                      AND  NOT EXISTS(SELECT 'X' FROM xxwip_deliverys VD11
                                       WHERE VD11.delivery_no = XOHA2.delivery_no
                                     )
                      AND  XOHA2.delivery_no IS NULL
                )  DELV
               ,xxskz_cust_accounts2_v          XCAV     --SKYLINK用中間VIEW 顧客情報VIEW2(管轄拠点)
               ,xxskz_carriers2_v               XCRV     --SKYLINK用中間VIEW 運送業者情報VIEW2(運送業者名)
               ,xxskz_party_sites2_v            XPSV     --SKYLINK用中間VIEW 配送先情報VIEW2(配送先名)
               ,xxskz_item_locations2_v         XILV     --SKYLINK用中間VIEW OPM保管場所情報VIEW2(出庫元名)
               ,xxskz_item_mst2_v               ITEM     --SKYLINK用中間VIEW OPM品目情報VIEW2(品目情報)
               ,fnd_lookup_values               FLV01    --クイックコード(ステータス名)
               ,fnd_lookup_values               FLV02    --クイックコード(配送区分名)
         WHERE
           -- 管轄拠点名取得条件
                DELV.head_sales_branch = XCAV.party_number(+)
           AND  DELV.arrival_date >= XCAV.start_date_active(+)
           AND  DELV.arrival_date <= XCAV.end_date_active(+)
           -- 運送業者_実績名取得条件
           AND  DELV.freight_carrier_id = XCRV.party_id(+)
           AND  DELV.arrival_date >= XCRV.start_date_active(+)
           AND  DELV.arrival_date <= XCRV.end_date_active(+)
           -- 出荷_配送先名取得条件
-- *----------* 2009/06/23 本番#1438対応 start *----------*
--           AND  DELV.deliver_to_id = XPSV.party_site_id(+)
           AND  DELV.deliver_to    = XPSV.party_site_number(+)
-- *----------* 2009/06/23 本番#1438対応 end   *----------*
           AND  DELV.arrival_date >= XPSV.start_date_active(+)
           AND  DELV.arrival_date <= XPSV.end_date_active(+)
           -- 出庫元名取得条件
           AND  DELV.deliver_from_id = XILV.inventory_location_id(+)
           -- 出荷品目情報取得条件
--         AND  DELV.shipping_item_code = ITEM.item_no(+)
           AND  DELV.request_item_code  = ITEM.item_no(+)
           AND  DELV.arrival_date >= ITEM.start_date_active(+)
           AND  DELV.arrival_date <= ITEM.end_date_active(+)
           -- ステータス名
           AND  FLV01.language(+)    = 'JA'
           AND  FLV01.lookup_type(+) = 'XXWSH_TRANSACTION_STATUS'
           AND  FLV01.lookup_code(+) = DELV.req_status
           -- 配送区分名
           AND  FLV02.language(+)    = 'JA'
           AND  FLV02.lookup_type(+) = 'XXCMN_SHIP_METHOD'
           AND  FLV02.lookup_code(+) = DELV.shipping_method_code
-- 2009.01.21↑
        UNION ALL
        --=========================================================
        -- 移動データ
        --=========================================================
        SELECT
                DELV.delivery_no                    delivery_no                     --配送No
               ,DELV.mov_num                        req_mov_no                      --依頼_移動No
               ,'移動'                              kbn                             --区分
               ,NULL                                order_type                      --受注タイプ
               ,DELV.status                         status                          --ステータス
               ,FLV01.meaning                       status_name                     --ステータス名
               ,'2100'                              branch                          --管轄拠点
               ,XL2V.location_name                  branch_name                     --管轄拠点名
               ,DELV.freight_carrier_code           carrier_code                    --運送業者
               ,XCRV.party_name                     carrier_name                    --運送業者名
               ,XCRV.party_short_name               carrier_short_name              --運送業者略称
               ,DELV.ship_to_locat_code             ship_deliver_to                 --入庫先_配送先
               ,XILV1.description                   ship_deliver_to_name            --入庫先_配送先名
               ,XILV1.short_name                    ship_deliver_to_short_name      --入庫先_配送先略称
               ,DELV.shipped_locat_code             ship_from                       --出庫元
               ,XILV2.description                   ship_from_name                  --出庫元名
               ,XILV2.short_name                    ship_from_short_name            --出庫元略称
               ,DELV.shipping_method_code           ship_method_code                --配送区分
               ,FLV02.meaning                       ship_method_name                --配送区分名
               ,DELV.shipped_date                   shipped_date                    --出庫日
               ,DELV.arrival_date                   arrival_date                    --入庫日
               ,ITEM.item_id                        item_id                         --品目ID
               ,DELV.item_code                      item_code                       --品目コード
               ,ITEM.item_name                      item_name                       --品目名称
               ,ITEM.item_short_name                item_short_name                 --品目略称
               ,DELV.quantity                       quantity                        --品目_バラ数
               ,NVL( DELV.quantity / ITEM.num_of_cases, 0 )
                                                    cs_quantity                     --品目_ケース数
               ,NVL( DELV.qty1, 0 )                 sum_cs_quantity                 --合計ケース数
-- 2010/1/8 #627 Y.Fukami Mod Start
--               ,ROUND(DELV.sum_loading_weight)      sum_loading_weight              --配送_積載重量合計
               ,CEIL(TRUNC(NVL(DELV.sum_loading_weight,0),1))      
                                                    sum_loading_weight              --積載重量合計(小数点第2位以下を切り捨て後、小数点第1位を切り上げ)
-- 2010/1/8 #627 Y.Fukami Mod End
               ,DELV.distribute_sum_loading_weight  distribute_sum_loading_weight   --配送_按分計算用_積載重量合計
-- 2010/1/8 #627 Y.Fukami Mod Start
--               ,ROUND(DELV.weight)                  item_weight                     --品目重量合計
               ,CEIL(TRUNC(NVL(DELV.weight,0),1))   item_weight                     --品目重量合計(小数点第2位以下を切り捨て後、小数点第1位を切り上げ)
-- 2010/1/8 #627 Y.Fukami Mod End
               ,DELV.distribute_item_weight         distribute_item_weight          --按分計算用_品目重量合計
               --配送単位と品目単位の運賃
               ,NVL( DELV.total_amount      , 0 )                       total_amount             --合計金額
               ,NVL( ROUND( DELV.total_amount       * item_rate ), 0 )  item_total_amount        --品目_合計金額
          FROM  (  --対象データを抽出
                   SELECT  XMRH.delivery_no                                          --配送No
                          ,XMRH.mov_num                                              --依頼_移動No
                          ,XMRH.status                                               --ステータス
                          ,XMRH.actual_career_id             freight_carrier_id      --運送業者ID
                          ,XMRH.actual_freight_carrier_code  freight_carrier_code    --運送業者
                          ,XMRH.ship_to_locat_id                                     --入庫先ID
                          ,XMRH.ship_to_locat_code                                   --入庫先
                          ,XMRH.shipped_locat_id                                     --出庫元ID
                          ,XMRH.shipped_locat_code                                   --出庫元
                          ,XMRH.actual_shipping_method_code  shipping_method_code    --配送区分
                          ,XMRH.actual_ship_date             shipped_date            --出庫日
                          ,XMRH.actual_arrival_date          arrival_date            --入庫日
                          ,XMRL.item_code                                            --品目コード
--                        ,XMRL.shipped_quantity             quantity                --品目_数量
                          ,XMRL.ship_to_quantity             quantity                --品目_数量
                          ,XCS.sum_loading_weight            sum_loading_weight      --配送_積載重量合計
                          ,XCS.sum_loading_weight            distribute_sum_loading_weight      --配送_按分計算用_積載重量合計
                          ,XMRL.weight                                               --品目重量合計
                          ,XMRL.weight                       distribute_item_weight  --按分計算用_品目重量合計
                           --配送No内の品目重量割合（品目_重量合計 ÷ 配送_重量合計）
                          ,CASE WHEN XCS.sum_loading_weight = 0 THEN 0
                                ELSE XMRL.weight / XCS.sum_loading_weight
                           END                               item_rate               --配送No内の品目重量割合
                           --配送単位の運賃
                          ,XDLV.qty1                                                 --配送_個数１
                          ,XDLV.total_amount                                         --配送_合計金額
                     FROM  xxcmn_mov_req_instr_hdrs_arc     XMRH                     --移動依頼/指示ヘッダ（アドオン）バックアップ
                          ,xxcmn_mov_req_instr_lines_arc       XMRL                  --移動依頼/指示明細（アドオン）バックアップ
                          ,(    -- 配送NO単位の積載重量合計算出
                            SELECT delivery_no                                       --配送NO
                                  ,SUM(sum_weight)   sum_loading_weight              --積載重量合計
                              FROM (SELECT delivery_no
                                          ,sum_weight
                                      FROM xxcmn_order_headers_all_arc  --受注ヘッダ（アドオン）バックアップ
                                     WHERE latest_external_flag = 'Y'
                                    UNION ALL
                                    SELECT delivery_no
                                          ,sum_weight
                                      FROM xxcmn_mov_req_instr_hdrs_arc  --移動依頼/指示ヘッダ（アドオン）バックアップ
                                   )
                            GROUP BY delivery_no
                           )                               XCS                       --配送NO単位積載重量合計
                          ,(
                            SELECT XD1.delivery_no                                   --配送NO
                                  ,XD1.qty1                                          --配送_個数１
                                  ,XD1.total_amount                                  --配送_合計金額
                              FROM xxwip_deliverys XD1
                             WHERE XD1.p_b_classe = '2'                              --'2:請求運賃'
                            UNION ALL
                            SELECT XD2.delivery_no                                   --配送NO
                                  ,XD2.qty1                                          --配送_個数１
                                  ,0                                                 --配送_合計金額
                              FROM xxwip_deliverys XD2
                             WHERE XD2.p_b_classe = '1'                              --'1:支払運賃'
                               -- 支払請求区分が'1':支払運賃のみ
                               AND NOT EXISTS
                                   (
                                    SELECT 'X'
                                      FROM xxwip_deliverys XD3
                                      WHERE XD3.p_b_classe = '2'                     --'2:請求運賃'
                                        AND XD3.delivery_no = XD2.delivery_no
                                   )
                           )                               XDLV                      --運賃ヘッダアドオン
                    WHERE
                      -- 移動ヘッダデータ取得条件
                           XMRH.status = '06'                                        --入出庫報告有のみ
                      -- 移動明細データ取得条件
                      AND  NVL(XMRL.delete_flg, 'N') <> 'Y'
                      AND  XMRH.mov_hdr_id = XMRL.mov_hdr_id
                      -- 配送NO単位積載重量合計取得条件
                      AND  XMRH.delivery_no = XCS.delivery_no
                      -- 運賃ヘッダアドオン情報取得条件
                      AND  XMRH.delivery_no = XDLV.delivery_no
                )  DELV
               ,xxskz_locations2_v              XL2V     --SKYLINK用中間VIEW 事業所情報VIEW2(管轄拠点名)
               ,xxskz_carriers2_v               XCRV     --SKYLINK用中間VIEW 運送業者情報VIEW2(運送業者名)
               ,xxskz_item_locations2_v         XILV1    --SKYLINK用中間VIEW OPM保管場所情報VIEW2(入庫先名)
               ,xxskz_item_locations2_v         XILV2    --SKYLINK用中間VIEW OPM保管場所情報VIEW2(出庫元名)
               ,xxskz_item_mst2_v               ITEM     --SKYLINK用中間VIEW OPM品目情報VIEW2(品目情報)
               ,fnd_lookup_values               FLV01    --クイックコード(ステータス名)
               ,fnd_lookup_values               FLV02    --クイックコード(配送区分名)
         WHERE
           -- 管轄拠点名取得条件
                XL2V.location_code(+)           = '2100'            -- 飲料部
           AND  XL2V.start_date_active(+)       <= DELV.shipped_date
           AND  XL2V.end_date_active(+)         >= DELV.shipped_date
           -- 運送業者_実績名取得条件
           AND  DELV.freight_carrier_id = XCRV.party_id(+)
           AND  DELV.arrival_date >= XCRV.start_date_active(+)
           AND  DELV.arrival_date <= XCRV.end_date_active(+)
           -- 移動_入庫先名取得
           AND  DELV.ship_to_locat_id = XILV1.inventory_location_id(+)
           -- 出庫元名取得条件
           AND  DELV.shipped_locat_id = XILV2.inventory_location_id(+)
           -- 出荷品目情報取得条件
           AND  DELV.item_code = ITEM.item_no(+)
           AND  DELV.arrival_date >= ITEM.start_date_active(+)
           AND  DELV.arrival_date <= ITEM.end_date_active(+)
           -- ステータス名
           AND  FLV01.language(+)    = 'JA'
           AND  FLV01.lookup_type(+) = 'XXINV_MOVE_STATUS'
           AND  FLV01.lookup_code(+) = DELV.status
           -- 配送区分名
           AND  FLV02.language(+)    = 'JA'
           AND  FLV02.lookup_type(+) = 'XXCMN_SHIP_METHOD'
           AND  FLV02.lookup_code(+) = DELV.shipping_method_code
           -- 積載重量合計がゼロ以上のみ
           AND  NVL( DELV.sum_loading_weight, 0 ) > 0
        UNION ALL
        --=========================================================
        -- 移動データ（積載重量合計ゼロのみ【積載重量ゼロで運賃が発生する場合がある為】）
        --=========================================================
        SELECT
                DELV.delivery_no                    delivery_no                     --配送No
               ,DELV.mov_num                        req_mov_no                      --依頼_移動No
               ,'移動'                              kbn                             --区分
               ,NULL                                order_type                      --受注タイプ
               ,DELV.status                         status                          --ステータス
               ,FLV01.meaning                       status_name                     --ステータス名
               ,'2100'                              branch                          --管轄拠点
               ,XL2V.location_name                  branch_name                     --管轄拠点名
               ,DELV.freight_carrier_code           carrier_code                    --運送業者
               ,XCRV.party_name                     carrier_name                    --運送業者名
               ,XCRV.party_short_name               carrier_short_name              --運送業者略称
               ,DELV.ship_to_locat_code             ship_deliver_to                 --入庫先_配送先
               ,XILV1.description                   ship_deliver_to_name            --入庫先_配送先名
               ,XILV1.short_name                    ship_deliver_to_short_name      --入庫先_配送先略称
               ,DELV.shipped_locat_code             ship_from                       --出庫元
               ,XILV2.description                   ship_from_name                  --出庫元名
               ,XILV2.short_name                    ship_from_short_name            --出庫元略称
               ,DELV.shipping_method_code           ship_method_code                --配送区分
               ,FLV02.meaning                       ship_method_name                --配送区分名
               ,DELV.shipped_date                   shipped_date                    --出庫日
               ,DELV.arrival_date                   arrival_date                    --入庫日
               ,ITEM.item_id                        item_id                         --品目ID
               ,DELV.item_code                      item_code                       --品目コード
               ,ITEM.item_name                      item_name                       --品目名称
               ,ITEM.item_short_name                item_short_name                 --品目略称
               ,DELV.quantity                       quantity                        --品目_バラ数
               ,NVL( DELV.quantity / ITEM.num_of_cases, 0 )
                                                    cs_quantity                     --品目_ケース数
               ,NVL( DELV.qty1, 0 )                 sum_cs_quantity                 --合計ケース数
-- 2010/1/8 #627 Y.Fukami Mod Start
--               ,ROUND(DELV.sum_loading_weight)      sum_loading_weight              --配送_積載重量合計
               ,CEIL(TRUNC(NVL(DELV.sum_loading_weight,0),1))      
                                                    sum_loading_weight              --積載重量合計(小数点第2位以下を切り捨て後、小数点第1位を切り上げ)
-- 2010/1/8 #627 Y.Fukami Mod End
               ,DELV.distribute_sum_loading_weight  distribute_sum_loading_weight   --配送_按分計算用_積載重量合計
-- 2010/1/8 #627 Y.Fukami Mod Start
--               ,ROUND(DELV.weight)                  item_weight                     --品目重量合計
               ,CEIL(TRUNC(NVL(DELV.weight,0),1))   item_weight                     --品目重量合計(小数点第2位以下を切り捨て後、小数点第1位を切り上げ)
-- 2010/1/8 #627 Y.Fukami Mod End
               ,DELV.distribute_item_weight         distribute_item_weight          --按分計算用_品目重量合計
               --配送単位と品目単位の運賃
               --運賃がある場合、配送単位の最大依頼NOの最大明細番号にセットする
               ,CASE WHEN DELV.req_mov_line = DELV.mov_num || LPAD(line_number, 5, '0')
                     THEN NVL( DELV.total_amount      , 0 )
                     ELSE 0
                END                                 total_amount                    --合計金額
               ,CASE WHEN DELV.req_mov_line = DELV.mov_num || LPAD(line_number, 5, '0')
                     THEN NVL( DELV.total_amount      , 0 )
                     ELSE 0
                END                                 item_total_amount               --品目_合計金額
          FROM  (  --対象データを抽出
                   SELECT  XMRH.delivery_no                                          --配送No
                          ,XMRH.mov_num                                              --依頼_移動No
                          ,XMRL.line_number                                          --明細番号
                          ,XMRH.status                                               --ステータス
                          ,XMRH.actual_career_id             freight_carrier_id      --運送業者ID
                          ,XMRH.actual_freight_carrier_code  freight_carrier_code    --運送業者
                          ,XMRH.ship_to_locat_id                                     --入庫先ID
                          ,XMRH.ship_to_locat_code                                   --入庫先
                          ,XMRH.shipped_locat_id                                     --出庫元ID
                          ,XMRH.shipped_locat_code                                   --出庫元
                          ,XMRH.actual_shipping_method_code  shipping_method_code    --配送区分
                          ,XMRH.actual_ship_date             shipped_date            --出庫日
                          ,XMRH.actual_arrival_date          arrival_date            --入庫日
                          ,XMRL.item_code                                            --品目コード
--                        ,XMRL.shipped_quantity             quantity                --品目_数量
                          ,XMRL.ship_to_quantity             quantity                --品目_数量
                          ,XCS.sum_loading_weight            sum_loading_weight      --配送_積載重量合計
                          ,XCS.sum_loading_weight            distribute_sum_loading_weight      --配送_按分計算用_積載重量合計
                          ,XMRL.weight                                               --品目重量合計
                          ,XMRL.weight                       distribute_item_weight  --按分計算用_品目重量合計
                          ,RML.req_mov_line                                          --最大依頼・明細番号
                           --配送No内の品目重量割合（品目_重量合計 ÷ 配送_重量合計）
                          ,CASE WHEN XCS.sum_loading_weight = 0 THEN 0
                                ELSE XMRL.weight / XCS.sum_loading_weight
                           END                               item_rate               --配送No内の品目重量割合
                           --配送単位の運賃
                          ,XDLV.qty1                                                 --配送_個数１
                          ,XDLV.total_amount                                         --配送_合計金額
                     FROM  xxcmn_mov_req_instr_hdrs_arc     XMRH                     --移動依頼/指示ヘッダ（アドオン）バックアップ
                          ,xxcmn_mov_req_instr_lines_arc       XMRL                  --移動依頼/指示明細（アドオン）バックアップ
                          ,(    -- 配送NO単位の積載重量合計算出
                            SELECT delivery_no                                       --配送NO
                                  ,SUM(sum_weight)   sum_loading_weight              --積載重量合計
                              FROM (SELECT delivery_no
                                          ,sum_weight
                                      FROM xxcmn_order_headers_all_arc  --受注ヘッダ（アドオン）バックアップ
                                     WHERE latest_external_flag = 'Y'
                                    UNION ALL
                                    SELECT delivery_no
                                          ,sum_weight
                                      FROM xxcmn_mov_req_instr_hdrs_arc  --移動依頼/指示ヘッダ（アドオン）バックアップ
                                   )
                            GROUP BY delivery_no
                           )                               XCS                       --配送NO単位積載重量合計
                          ,(
                            SELECT XD1.delivery_no                                   --配送NO
                                  ,XD1.qty1                                          --配送_個数１
                                  ,XD1.total_amount                                  --配送_合計金額
                              FROM xxwip_deliverys XD1
                             WHERE XD1.p_b_classe = '2'                              --'2:請求運賃'
                            UNION ALL
                            SELECT XD2.delivery_no                                   --配送NO
                                  ,XD2.qty1                                          --配送_個数１
                                  ,0                                                 --配送_合計金額
                              FROM xxwip_deliverys XD2
                             WHERE XD2.p_b_classe = '1'                              --'1:支払運賃'
                               -- 支払請求区分が'1':支払運賃のみ
                               AND NOT EXISTS
                                   (
                                    SELECT 'X'
                                      FROM xxwip_deliverys XD3
                                      WHERE XD3.p_b_classe = '2'                     --'2:請求運賃'
                                        AND XD3.delivery_no = XD2.delivery_no
                                   )
                           )                               XDLV                      --運賃ヘッダアドオン
                          ,(    -- 配送NO単位の最大依頼NO、最大明細番号取得
                            SELECT delivery_no
                                  ,req_mov_line
                              FROM (SELECT OH.delivery_no
                                          ,MAX(OH.request_no || LPAD(OL.order_line_number, 5, '0')) req_mov_line
                                      FROM xxcmn_order_headers_all_arc  OH  --受注ヘッダ（アドオン）バックアップ
                                          ,xxcmn_order_lines_all_arc   OL  --受注明細（アドオン）バックアップ
                                     WHERE OH.order_header_id = OL.order_header_id
                                       AND OH.latest_external_flag = 'Y'
                                       AND NVL(OL.delete_flag, 'N') <> 'Y'
                                    GROUP BY OH.delivery_no
                                    UNION ALL
                                    SELECT MH.delivery_no
                                          ,MAX(MH.mov_num || LPAD(ML.line_number, 5, '0')) req_mov_line
                                      FROM xxcmn_mov_req_instr_hdrs_arc  MH   --移動依頼/指示ヘッダ（アドオン）バックアップ
                                          ,xxcmn_mov_req_instr_lines_arc   ML --移動依頼/指示明細（アドオン）バックアップ
                                     WHERE MH.mov_hdr_id = ML.mov_hdr_id
                                       AND NVL( ML.delete_flg, 'N' ) <> 'Y'      --無効明細以外
                                    GROUP BY MH.delivery_no
                                   )
                           )                               RML                       --配送NO単位の最大依頼・明細番号情報
                    WHERE
                      -- 移動ヘッダデータ取得条件
                           XMRH.status = '06'                                        --入出庫報告有のみ
                      -- 移動明細データ取得条件
                      AND  NVL(XMRL.delete_flg, 'N') <> 'Y'
                      AND  XMRH.mov_hdr_id = XMRL.mov_hdr_id
                      -- 配送NO単位積載重量合計取得条件
                      AND  XMRH.delivery_no = XCS.delivery_no
                      -- 運賃ヘッダアドオン情報取得条件
                      AND  XMRH.delivery_no = XDLV.delivery_no
                      -- 配送NO単位最大依頼・明細番号取得条件
                      AND  XMRH.delivery_no = RML.delivery_no
                )  DELV
               ,xxskz_locations2_v              XL2V     --SKYLINK用中間VIEW 事業所情報VIEW2(管轄拠点名)
               ,xxskz_carriers2_v               XCRV     --SKYLINK用中間VIEW 運送業者情報VIEW2(運送業者名)
               ,xxskz_item_locations2_v         XILV1    --SKYLINK用中間VIEW OPM保管場所情報VIEW2(入庫先名)
               ,xxskz_item_locations2_v         XILV2    --SKYLINK用中間VIEW OPM保管場所情報VIEW2(出庫元名)
               ,xxskz_item_mst2_v               ITEM     --SKYLINK用中間VIEW OPM品目情報VIEW2(品目情報)
               ,fnd_lookup_values               FLV01    --クイックコード(ステータス名)
               ,fnd_lookup_values               FLV02    --クイックコード(配送区分名)
         WHERE
           -- 管轄拠点名取得条件
                XL2V.location_code(+)           = '2100'            -- 飲料部
           AND  XL2V.start_date_active(+)       <= DELV.shipped_date
           AND  XL2V.end_date_active(+)         >= DELV.shipped_date
           -- 運送業者_実績名取得条件
           AND  DELV.freight_carrier_id = XCRV.party_id(+)
           AND  DELV.arrival_date >= XCRV.start_date_active(+)
           AND  DELV.arrival_date <= XCRV.end_date_active(+)
           -- 移動_入庫先名取得
           AND  DELV.ship_to_locat_id = XILV1.inventory_location_id(+)
           -- 出庫元名取得条件
           AND  DELV.shipped_locat_id = XILV2.inventory_location_id(+)
           -- 出荷品目情報取得条件
           AND  DELV.item_code = ITEM.item_no(+)
           AND  DELV.arrival_date >= ITEM.start_date_active(+)
           AND  DELV.arrival_date <= ITEM.end_date_active(+)
           -- ステータス名
           AND  FLV01.language(+)    = 'JA'
           AND  FLV01.lookup_type(+) = 'XXINV_MOVE_STATUS'
           AND  FLV01.lookup_code(+) = DELV.status
           -- 配送区分名
           AND  FLV02.language(+)    = 'JA'
           AND  FLV02.lookup_type(+) = 'XXCMN_SHIP_METHOD'
           AND  FLV02.lookup_code(+) = DELV.shipping_method_code
           -- 積載重量合計がゼロのみ
           AND  NVL( DELV.sum_loading_weight, 0 ) = 0
-- 2009.01.21↓
        UNION ALL
        --=========================================================
        -- 移動データ（運賃アドオンに存在しないもの）
        --=========================================================
        SELECT
                DELV.delivery_no                    delivery_no                     --配送No
               ,DELV.mov_num                        req_mov_no                      --依頼_移動No
               ,'移動'                              kbn                             --区分
               ,NULL                                order_type                      --受注タイプ
               ,DELV.status                         status                          --ステータス
               ,FLV01.meaning                       status_name                     --ステータス名
               ,'2100'                              branch                          --管轄拠点
               ,XL2V.location_name                  branch_name                     --管轄拠点名
               ,DELV.freight_carrier_code           carrier_code                    --運送業者
               ,XCRV.party_name                     carrier_name                    --運送業者名
               ,XCRV.party_short_name               carrier_short_name              --運送業者略称
               ,DELV.ship_to_locat_code             ship_deliver_to                 --入庫先_配送先
               ,XILV1.description                   ship_deliver_to_name            --入庫先_配送先名
               ,XILV1.short_name                    ship_deliver_to_short_name      --入庫先_配送先略称
               ,DELV.shipped_locat_code             ship_from                       --出庫元
               ,XILV2.description                   ship_from_name                  --出庫元名
               ,XILV2.short_name                    ship_from_short_name            --出庫元略称
               ,DELV.shipping_method_code           ship_method_code                --配送区分
               ,FLV02.meaning                       ship_method_name                --配送区分名
               ,DELV.shipped_date                   shipped_date                    --出庫日
               ,DELV.arrival_date                   arrival_date                    --入庫日
               ,ITEM.item_id                        item_id                         --品目ID
               ,DELV.item_code                      item_code                       --品目コード
               ,ITEM.item_name                      item_name                       --品目名称
               ,ITEM.item_short_name                item_short_name                 --品目略称
               ,DELV.quantity                       quantity                        --品目_バラ数
               ,NVL( DELV.quantity / ITEM.num_of_cases, 0 )
                                                    cs_quantity                     --品目_ケース数
               ,NVL( DELV.qty1, 0 )                 sum_cs_quantity                 --合計ケース数
-- 2010/1/8 #627 Y.Fukami Mod Start
--               ,ROUND(DELV.sum_loading_weight)      sum_loading_weight              --配送_積載重量合計
               ,CEIL(TRUNC(NVL(DELV.sum_loading_weight,0),1))      
                                                    sum_loading_weight              --積載重量合計(小数点第2位以下を切り捨て後、小数点第1位を切り上げ)
-- 2010/1/8 #627 Y.Fukami Mod End
               ,DELV.distribute_sum_loading_weight  distribute_sum_loading_weight   --配送_按分計算用_積載重量合計
-- 2010/1/8 #627 Y.Fukami Mod Start
--               ,ROUND(DELV.weight)                  item_weight                     --品目重量合計
               ,CEIL(TRUNC(NVL(DELV.weight,0),1))   item_weight                     --品目重量合計(小数点第2位以下を切り捨て後、小数点第1位を切り上げ)
-- 2010/1/8 #627 Y.Fukami Mod End
               ,DELV.distribute_item_weight         distribute_item_weight          --按分計算用_品目重量合計
               ,0                                   total_amount                    --合計金額
               ,0                                   item_total_amount               --品目_合計金額
          FROM  (  --対象データを抽出
--aaa
                   SELECT  XMRH.delivery_no                                          --配送No
                          ,XMRH.mov_num                                              --依頼_移動No
                          ,XMRL.line_number                                          --明細番号
                          ,XMRH.status                                               --ステータス
                          ,XMRH.actual_career_id             freight_carrier_id      --運送業者ID
                          ,XMRH.actual_freight_carrier_code  freight_carrier_code    --運送業者
                          ,XMRH.ship_to_locat_id                                     --入庫先ID
                          ,XMRH.ship_to_locat_code                                   --入庫先
                          ,XMRH.shipped_locat_id                                     --出庫元ID
                          ,XMRH.shipped_locat_code                                   --出庫元
                          ,XMRH.actual_shipping_method_code  shipping_method_code    --配送区分
                          ,XMRH.actual_ship_date             shipped_date            --出庫日
                          ,XMRH.actual_arrival_date          arrival_date            --入庫日
                          ,XMRL.item_code                                            --品目コード
--                        ,XMRL.shipped_quantity             quantity                --品目_数量
                          ,XMRL.ship_to_quantity             quantity                --品目_数量
                          ,XCS.sum_loading_weight            sum_loading_weight      --配送_積載重量合計
                          ,XCS.sum_loading_weight            distribute_sum_loading_weight      --配送_按分計算用_積載重量合計
                          ,XMRL.weight                                               --品目重量合計
                          ,XMRL.weight                       distribute_item_weight  --按分計算用_品目重量合計
                           --配送No内の品目重量割合（品目_重量合計 ÷ 配送_重量合計）
                          ,CASE WHEN XCS.sum_loading_weight = 0 THEN 0
                                ELSE XMRL.weight / XCS.sum_loading_weight
                           END                               item_rate               --配送No内の品目重量割合
                           --配送単位の運賃
                          ,XCS.sum_loading_quantity          qty1                    --配送_個数１
                     FROM  xxcmn_mov_req_instr_hdrs_arc     XMRH                     --移動依頼/指示ヘッダ（アドオン）バックアップ
                          ,xxcmn_mov_req_instr_lines_arc       XMRL                  --移動依頼/指示明細（アドオン）バックアップ
                          ,(    -- 配送NO単位の積載重量合計算出
                            SELECT delivery_no                                       --配送NO
                                  ,SUM(sum_quantity) sum_loading_quantity
                                  ,SUM(sum_weight)   sum_loading_weight              --積載重量合計
                              FROM (
                                    SELECT delivery_no
                                          ,NVL(shipped_quantity / ITEM11.num_of_cases, 0)  sum_quantity
                                          ,weight                                          sum_weight
                                      FROM (
                                            SELECT XOHA.delivery_no
                                                  ,XOHA.arrival_date
                                                  ,XOLA.shipping_item_code
                                                  ,XOLA.shipped_quantity
                                                  ,XOLA.weight
                                              FROM xxcmn_order_headers_all_arc  XOHA,  --受注ヘッダ（アドオン）バックアップ
                                                   xxcmn_order_lines_all_arc   XOLA  --受注明細（アドオン）バックアップ
                                             WHERE NVL(XOLA.delete_flag, 'N') <> 'Y'
                                               AND XOHA.order_header_id = XOLA.order_header_id
                                               AND XOHA.delivery_no IS NOT NULL
                                               AND XOHA.latest_external_flag = 'Y'
                                               AND XOHA.req_status = '04'
                                           )  XOHA11,
                                           xxskz_item_mst2_v   ITEM11
                                     WHERE XOHA11.shipping_item_code = ITEM11.item_no(+)
                                       AND XOHA11.arrival_date >= ITEM11.start_date_active(+)
                                       AND XOHA11.arrival_date <= ITEM11.end_date_active(+)
                                       AND XOHA11.delivery_no IS NOT NULL
                                    UNION ALL
                                    SELECT delivery_no
                                          ,NVL(shipped_quantity / ITEM11.num_of_cases, 0)  sum_quantity
                                          ,weight                                          sum_weight
                                      FROM (
                                            SELECT XMRH11.delivery_no
                                                  ,XMRH11.actual_arrival_date
                                                  ,XMRL11.item_code
--                                                ,XMRL11.shipped_quantity
                                                  ,XMRL11.ship_to_quantity    shipped_quantity
                                                  ,XMRL11.weight
                                              FROM xxcmn_mov_req_instr_hdrs_arc  XMRH11,   --移動依頼/指示ヘッダ（アドオン）バックアップ
                                                   xxcmn_mov_req_instr_lines_arc   XMRL11  --移動依頼/指示明細（アドオン）バックアップ
                                             WHERE NVL(XMRL11.delete_flg, 'N') <> 'Y'
                                               AND XMRH11.mov_hdr_id = XMRL11.mov_hdr_id
                                               AND XMRH11.delivery_no IS NOT NULL
                                           )  XMR11,
                                           xxskz_item_mst2_v   ITEM11
                                     WHERE item_code = item_no(+)
                                       AND actual_arrival_date >= start_date_active(+)
                                       AND actual_arrival_date <= end_date_active(+)
                                       AND delivery_no IS NOT NULL
                                   )
                            GROUP BY delivery_no
                           )                               XCS                       --配送NO単位積載重量合計
                    WHERE
                      -- 移動ヘッダデータ取得条件
                           XMRH.status = '06'                                        --入出庫報告有のみ
                      -- 移動明細データ取得条件
                      AND  NVL(XMRL.delete_flg, 'N') <> 'Y'
                      AND  XMRH.mov_hdr_id = XMRL.mov_hdr_id
                      -- 配送NO単位積載重量合計取得条件
                      AND  XMRH.delivery_no = XCS.delivery_no
                      AND  NOT EXISTS(SELECT 'X' FROM xxwip_deliverys VD12
                                       WHERE VD12.delivery_no = XMRH.delivery_no
                                     )
                      AND  XMRH.delivery_no IS NOT NULL
                   UNION ALL
                   SELECT  XMRH.delivery_no                                          --配送No
                          ,XMRH.mov_num                                              --依頼_移動No
                          ,XMRL.line_number                                          --明細番号
                          ,XMRH.status                                               --ステータス
                          ,XMRH.actual_career_id             freight_carrier_id      --運送業者ID
                          ,XMRH.actual_freight_carrier_code  freight_carrier_code    --運送業者
                          ,XMRH.ship_to_locat_id                                     --入庫先ID
                          ,XMRH.ship_to_locat_code                                   --入庫先
                          ,XMRH.shipped_locat_id                                     --出庫元ID
                          ,XMRH.shipped_locat_code                                   --出庫元
                          ,XMRH.actual_shipping_method_code  shipping_method_code    --配送区分
                          ,XMRH.actual_ship_date             shipped_date            --出庫日
                          ,XMRH.actual_arrival_date          arrival_date            --入庫日
                          ,XMRL.item_code                                            --品目コード
--                        ,XMRL.shipped_quantity             quantity                --品目_数量
                          ,XMRL.ship_to_quantity             quantity                --品目_数量
                          ,XCS.sum_loading_weight            sum_loading_weight      --配送_積載重量合計
                          ,XCS.sum_loading_weight            distribute_sum_loading_weight      --配送_按分計算用_積載重量合計
                          ,XMRL.weight                                               --品目重量合計
                          ,XMRL.weight                       distribute_item_weight  --按分計算用_品目重量合計
                           --配送No内の品目重量割合（品目_重量合計 ÷ 配送_重量合計）
                          ,CASE WHEN XCS.sum_loading_weight = 0 THEN 0
                                ELSE XMRL.weight / XCS.sum_loading_weight
                           END                               item_rate               --配送No内の品目重量割合
                           --配送単位の運賃
                          ,XCS.sum_loading_quantity          qty1                    --配送_個数１
                     FROM  xxcmn_mov_req_instr_hdrs_arc     XMRH                     --移動依頼/指示ヘッダ（アドオン）バックアップ
                          ,xxcmn_mov_req_instr_lines_arc       XMRL                  --移動依頼/指示明細（アドオン）バックアップ
                          ,(    -- 移動NO単位の積載重量合計算出
                            SELECT mov_num                                           --移動NO
                                  ,SUM(sum_quantity) sum_loading_quantity
                                  ,SUM(sum_weight)   sum_loading_weight              --積載重量合計
                              FROM (
                                    SELECT mov_num
                                          ,NVL(shipped_quantity / ITEM11.num_of_cases, 0)  sum_quantity
                                          ,weight                                          sum_weight
                                      FROM (
                                            SELECT XMRH11.delivery_no
                                                  ,XMRH11.mov_num
                                                  ,XMRH11.actual_arrival_date
                                                  ,XMRL11.item_code
--                                                ,XMRL11.shipped_quantity
                                                  ,XMRL11.ship_to_quantity   shipped_quantity
                                                  ,XMRL11.weight
                                              FROM xxcmn_mov_req_instr_hdrs_arc  XMRH11,   --移動依頼/指示ヘッダ（アドオン）バックアップ
                                                   xxcmn_mov_req_instr_lines_arc   XMRL11  --移動依頼/指示明細（アドオン）バックアップ
                                             WHERE NVL(XMRL11.delete_flg, 'N') <> 'Y'
                                               AND XMRH11.mov_hdr_id = XMRL11.mov_hdr_id
                                               AND XMRH11.delivery_no IS NULL
                                           )  XMR11,
                                           xxskz_item_mst2_v   ITEM11
                                     WHERE item_code = item_no(+)
                                       AND actual_arrival_date >= start_date_active(+)
                                       AND actual_arrival_date <= end_date_active(+)
                                   )
                            GROUP BY mov_num
                           )                               XCS                       --配送NO単位積載重量合計
                    WHERE
                      -- 移動ヘッダデータ取得条件
                           XMRH.status = '06'                                        --入出庫報告有のみ
                      -- 移動明細データ取得条件
                      AND  NVL(XMRL.delete_flg, 'N') <> 'Y'
                      AND  XMRH.mov_hdr_id = XMRL.mov_hdr_id
                      -- 移動NO単位積載重量合計取得条件
                      AND  XMRH.mov_num = XCS.mov_num
                      AND  XMRH.delivery_no IS NULL
--aaa
                )  DELV
               ,xxskz_locations2_v              XL2V     --SKYLINK用中間VIEW 事業所情報VIEW2(管轄拠点名)
               ,xxskz_carriers2_v               XCRV     --SKYLINK用中間VIEW 運送業者情報VIEW2(運送業者名)
               ,xxskz_item_locations2_v         XILV1    --SKYLINK用中間VIEW OPM保管場所情報VIEW2(入庫先名)
               ,xxskz_item_locations2_v         XILV2    --SKYLINK用中間VIEW OPM保管場所情報VIEW2(出庫元名)
               ,xxskz_item_mst2_v               ITEM     --SKYLINK用中間VIEW OPM品目情報VIEW2(品目情報)
               ,fnd_lookup_values               FLV01    --クイックコード(ステータス名)
               ,fnd_lookup_values               FLV02    --クイックコード(配送区分名)
         WHERE
           -- 管轄拠点名取得条件
                XL2V.location_code(+)           = '2100'            -- 飲料部
           AND  XL2V.start_date_active(+)       <= DELV.shipped_date
           AND  XL2V.end_date_active(+)         >= DELV.shipped_date
           -- 運送業者_実績名取得条件
           AND  DELV.freight_carrier_id = XCRV.party_id(+)
           AND  DELV.arrival_date >= XCRV.start_date_active(+)
           AND  DELV.arrival_date <= XCRV.end_date_active(+)
           -- 移動_入庫先名取得
           AND  DELV.ship_to_locat_id = XILV1.inventory_location_id(+)
           -- 出庫元名取得条件
           AND  DELV.shipped_locat_id = XILV2.inventory_location_id(+)
           -- 出荷品目情報取得条件
           AND  DELV.item_code = ITEM.item_no(+)
           AND  DELV.arrival_date >= ITEM.start_date_active(+)
           AND  DELV.arrival_date <= ITEM.end_date_active(+)
           -- ステータス名
           AND  FLV01.language(+)    = 'JA'
           AND  FLV01.lookup_type(+) = 'XXINV_MOVE_STATUS'
           AND  FLV01.lookup_code(+) = DELV.status
           -- 配送区分名
           AND  FLV02.language(+)    = 'JA'
           AND  FLV02.lookup_type(+) = 'XXCMN_SHIP_METHOD'
           AND  FLV02.lookup_code(+) = DELV.shipping_method_code
-- 2009.01.21↑
        )    UHK
       ,xxskz_prod_class_v              PRODC    --SKYLINK用中間VIEW 商品区分VIEW
       ,xxskz_item_class_v              ITEMC    --SKYLINK用中間VIEW 品目区分VIEW
       ,xxskz_crowd_code_v              CROWD    --SKYLINK用中間VIEW 群コードVIEW
 WHERE
   -- 出荷品目のカテゴリ情報取得条件
        UHK.item_id = PRODC.item_id(+)  --商品区分
   AND  UHK.item_id = ITEMC.item_id(+)  --品目区分
   AND  UHK.item_id = CROWD.item_id(+)  --群コード
   -- ドリンクのみ
   AND  PRODC.prod_class_code = '2'
   -- 製品のみ 2009.01.21
   AND  ITEMC.item_class_code = '5'
/
COMMENT ON TABLE APPS.XXSKZ_運賃品目別_基本_V IS 'SKYLINK用運賃品目別（基本） VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本_V.配送NO IS '配送No'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本_V.依頼_移動NO IS '依頼_移動No'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本_V.区分 IS '区分'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本_V.受注タイプ IS '受注タイプ'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本_V.ステータス IS 'ステータス'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本_V.ステータス名 IS 'ステータス名'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本_V.管轄拠点 IS '管轄拠点'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本_V.管轄拠点名 IS '管轄拠点名'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本_V.運送業者 IS '運送業者'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本_V.運送業者名 IS '運送業者名'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本_V.運送業者略称 IS '運送業者略称'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本_V.入庫先_配送先 IS '入庫先_配送先'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本_V.入庫先_配送先名 IS '入庫先_配送先名'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本_V.入庫先_配送先略称 IS '入庫先_配送先略称'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本_V.出庫元 IS '出庫元'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本_V.出庫元名 IS '出庫元名'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本_V.出庫元略称 IS '出庫元略称'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本_V.配送区分 IS '配送区分'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本_V.配送区分名 IS '配送区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本_V.出庫日 IS '出庫日'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本_V.入庫日 IS '入庫日'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本_V.商品区分 IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本_V.商品区分名 IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本_V.品目区分 IS '品目区分'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本_V.品目区分名 IS '品目区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本_V.群コード IS '群コード'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本_V.品目コード IS '品目コード'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本_V.品目名称 IS '品目名称'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本_V.品目略称 IS '品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本_V.品目バラ数 IS '品目バラ数'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本_V.品目ケース数 IS '品目ケース数'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本_V.合計ケース数 IS '合計ケース数'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本_V.積載重量合計 IS '積載重量合計'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本_V.按分計算用_積載重量合計 IS '按分計算用_積載重量合計'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本_V.品目重量合計 IS '品目重量合計'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本_V.按分計算用_品目重量合計 IS '按分計算用_品目重量合計'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本_V.合計金額 IS '合計金額'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本_V.品目_合計金額 IS '品目_合計金額'
/
