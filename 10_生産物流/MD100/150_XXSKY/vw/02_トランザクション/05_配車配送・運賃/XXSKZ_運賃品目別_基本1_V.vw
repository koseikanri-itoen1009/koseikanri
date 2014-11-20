/*************************************************************************
 * 
 * View  Name      : XXSKZ_運賃品目別_基本1_V
 * Description     : XXSKZ_運賃品目別_基本1_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2012/11/26    1.0   SCSK 月野    初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_運賃品目別_基本1_V
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
       ,UHK.request_no                      --依頼_移動No
       ,UHK.delivery_item_details_class     --区分
       ,UHK.order_type                      --受注タイプ
       ,UHK.req_status                      --ステータス
       ,CASE WHEN UHK.delivery_item_details_class = '出荷'
             THEN FLV01.meaning             --入庫先_配送先名
             ELSE FLV00.meaning             --入庫先_配送先名
        END
       ,UHK.head_sales_branch               --管轄拠点
       ,CASE WHEN UHK.delivery_item_details_class = '出荷'
             THEN XCAV.party_name           --管轄拠点名
             ELSE XL2V.location_name        --管轄拠点名
        END
       ,UHK.freight_carrier_code            --運送業者
       ,XCRV.party_name                     --運送業者名
       ,XCRV.party_short_name               --運送業者略称
       ,UHK.ship_to_deliver_to_code         --入庫先_配送先
       ,CASE WHEN UHK.delivery_item_details_class = '出荷'
             THEN XPSV.party_site_name                --入庫先_配送先名
             ELSE XILV1.description                   --入庫先_配送先名
        END
       ,CASE WHEN UHK.delivery_item_details_class = '出荷'
             THEN XPSV.party_site_short_name          --入庫先_配送先略称
             ELSE XILV1.short_name                    --入庫先_配送先略称
        END
       ,UHK.deliver_from                    --出庫元
       ,XILV.description                    --出庫元名
       ,XILV.short_name                     --出庫元略称
       ,UHK.shipping_method_code            --配送区分
       ,FLV02.meaning                       --配送区分名
       ,UHK.shipped_date                    --出庫日
       ,UHK.arrival_date                    --入庫日
       ,PRODC.prod_class_code               --商品区分
       ,PRODC.prod_class_name               --商品区分名
       ,ITEMC.item_class_code               --品目区分
       ,ITEMC.item_class_name               --品目区分名
       ,CROWD.crowd_code                    --群コード
       ,UHK.item_no                         --品目コード
       ,ITEM.item_name                      --品目名称
       ,ITEM.item_short_name                --品目略称
       ,UHK.shipped_quantity                --品目バラ数
       ,UHK.shipped_case_quantity           --品目ケース数
       ,UHK.sum_case_quantity               --合計ケース数
       ,UHK.sum_loading_weight              --積載重量合計
       ,UHK.calc_sum_loading_weight         --按分計算用_積載重量合計
       ,UHK.item_loading_weight             --品目重量合計
       ,UHK.calc_item_loading_weight        --按分計算用_品目重量合計
       ,UHK.sum_amount                      --合計金額
       ,UHK.item_amount                     --品目_合計金額
  FROM
        xxwip_delivery_item_details     UHK      --品目別按分運賃明細アドオン
       ,xxskz_prod_class_v              PRODC    --SKYLINK用中間VIEW 商品区分VIEW
       ,xxskz_item_class_v              ITEMC    --SKYLINK用中間VIEW 品目区分VIEW
       ,xxskz_crowd_code_v              CROWD    --SKYLINK用中間VIEW 群コードVIEW
       ,xxskz_cust_accounts2_v          XCAV     --SKYLINK用中間VIEW 顧客情報VIEW2(管轄拠点)
       ,xxskz_locations2_v              XL2V     --SKYLINK用中間VIEW 事業所情報VIEW2(管轄拠点名)
       ,xxskz_carriers2_v               XCRV     --SKYLINK用中間VIEW 運送業者情報VIEW2(運送業者名)
       ,xxskz_party_sites2_v            XPSV     --SKYLINK用中間VIEW 配送先情報VIEW2(配送先名)
       ,xxskz_item_locations2_v         XILV1    --SKYLINK用中間VIEW OPM保管場所情報VIEW2(入庫先名)
       ,xxskz_item_locations2_v         XILV     --SKYLINK用中間VIEW OPM保管場所情報VIEW2(出庫元名)
       ,xxskz_item_mst2_v               ITEM     --SKYLINK用中間VIEW OPM品目情報VIEW2(品目情報)
       ,fnd_lookup_values               FLV00    --クイックコード(ステータス名)
       ,fnd_lookup_values               FLV01    --クイックコード(ステータス名)
       ,fnd_lookup_values               FLV02    --クイックコード(配送区分名)
 WHERE
   -- 品目のカテゴリ情報取得条件
        ITEM.item_id = PRODC.item_id(+)  --商品区分
   AND  ITEM.item_id = ITEMC.item_id(+)  --品目区分
   AND  ITEM.item_id = CROWD.item_id(+)  --群コード
   -- 管轄拠点名取得条件(移動)
   AND  UHK.head_sales_branch = XL2V.location_code(+)
   AND  UHK.arrival_date >= XL2V.start_date_active(+)
   AND  UHK.arrival_date <= XL2V.end_date_active(+)
   -- 管轄拠点名取得条件(出荷)
   AND  UHK.head_sales_branch = XCAV.party_number(+)
   AND  UHK.arrival_date >= XCAV.start_date_active(+)
   AND  UHK.arrival_date <= XCAV.end_date_active(+)
   -- 運送業者_実績名取得条件
   AND  UHK.freight_carrier_code = XCRV.freight_code(+)
   AND  UHK.arrival_date >= XCRV.start_date_active(+)
   AND  UHK.arrival_date <= XCRV.end_date_active(+)
   -- 移動_入庫先名取得
   AND  UHK.ship_to_deliver_to_code = XILV1.segment1(+)
   -- 出荷_配送先名取得条件
   AND  UHK.ship_to_deliver_to_code = XPSV.party_site_number(+)
   AND  UHK.arrival_date >= XPSV.start_date_active(+)
   AND  UHK.arrival_date <= XPSV.end_date_active(+)
   -- 出庫元名取得条件
   AND  UHK.deliver_from = XILV.segment1(+)
   -- 出荷品目情報取得条件
   AND  UHK.item_no = ITEM.item_no(+)
   AND  UHK.arrival_date >= ITEM.start_date_active(+)
   AND  UHK.arrival_date <= ITEM.end_date_active(+)
   -- ステータス名(移動)
   AND  FLV00.language(+)    = 'JA'
   AND  FLV00.lookup_type(+) = 'XXINV_MOVE_STATUS'
   AND  FLV00.lookup_code(+) = UHK.req_status
   -- ステータス名(出荷)
   AND  FLV01.language(+)    = 'JA'
   AND  FLV01.lookup_type(+) = 'XXWSH_TRANSACTION_STATUS'
   AND  FLV01.lookup_code(+) = UHK.req_status
   -- 配送区分名
   AND  FLV02.language(+)    = 'JA'
   AND  FLV02.lookup_type(+) = 'XXCMN_SHIP_METHOD'
   AND  FLV02.lookup_code(+) = UHK.shipping_method_code
/
COMMENT ON TABLE APPS.XXSKZ_運賃品目別_基本1_V IS 'SKYLINK用運賃品目別（基本） VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本1_V.配送NO IS '配送No'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本1_V.依頼_移動NO IS '依頼_移動No'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本1_V.区分 IS '区分'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本1_V.受注タイプ IS '受注タイプ'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本1_V.ステータス IS 'ステータス'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本1_V.ステータス名 IS 'ステータス名'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本1_V.管轄拠点 IS '管轄拠点'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本1_V.管轄拠点名 IS '管轄拠点名'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本1_V.運送業者 IS '運送業者'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本1_V.運送業者名 IS '運送業者名'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本1_V.運送業者略称 IS '運送業者略称'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本1_V.入庫先_配送先 IS '入庫先_配送先'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本1_V.入庫先_配送先名 IS '入庫先_配送先名'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本1_V.入庫先_配送先略称 IS '入庫先_配送先略称'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本1_V.出庫元 IS '出庫元'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本1_V.出庫元名 IS '出庫元名'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本1_V.出庫元略称 IS '出庫元略称'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本1_V.配送区分 IS '配送区分'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本1_V.配送区分名 IS '配送区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本1_V.出庫日 IS '出庫日'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本1_V.入庫日 IS '入庫日'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本1_V.商品区分 IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本1_V.商品区分名 IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本1_V.品目区分 IS '品目区分'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本1_V.品目区分名 IS '品目区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本1_V.群コード IS '群コード'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本1_V.品目コード IS '品目コード'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本1_V.品目名称 IS '品目名称'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本1_V.品目略称 IS '品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本1_V.品目バラ数 IS '品目バラ数'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本1_V.品目ケース数 IS '品目ケース数'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本1_V.合計ケース数 IS '合計ケース数'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本1_V.積載重量合計 IS '積載重量合計'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本1_V.按分計算用_積載重量合計 IS '按分計算用_積載重量合計'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本1_V.品目重量合計 IS '品目重量合計'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本1_V.按分計算用_品目重量合計 IS '按分計算用_品目重量合計'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本1_V.合計金額 IS '合計金額'
/
COMMENT ON COLUMN APPS.XXSKZ_運賃品目別_基本1_V.品目_合計金額 IS '品目_合計金額'
/
