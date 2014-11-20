CREATE OR REPLACE VIEW APPS.XXSKY_受払_製品_数量2_V
(
 年月
,商品区分
,商品区分名
,倉庫コード
,倉庫名
,品目区分
,品目区分名
,群コード
,品目コード
,品目名称
,品目略称
,月首在庫
,月首在庫ケース
,受入数量_仕入
,受入数量_仕入ケース
,受入数量_包装
,受入数量_包装ケース
,受入数量_セット
,受入数量_セットケース
,受入数量_沖縄
,受入数量_沖縄ケース
,受入数量_振替入庫
,受入数量_振替入庫ケース
,受入数量_緑営１
,受入数量_緑営１ケース
,受入数量_緑営２
,受入数量_緑営２ケース
,受入数量_ドリンクギフト
,受入数量_ドリンクギフトケース
,受入数量_倉替
,受入数量_倉替ケース
,受入数量_返品
,受入数量_返品ケース
,受入数量_浜岡
,受入数量_浜岡ケース
,受入数量_品種移動
,受入数量_品種移動ケース
,受入数量_倉庫移動
,受入数量_倉庫移動ケース
,受入数量_その他
,受入数量_その他ケース
,払出数量_セット
,払出数量_セットケース
,払出数量_返品原料へ
,払出数量_返品原料へケース
,払出数量_解体半製品へ
,払出数量_解体半製品へケース
,払出数量_有償
,払出数量_有償ケース
,払出数量_振替有償
,払出数量_振替有償ケース
,払出数量_拠点
,払出数量_拠点ケース
,払出数量_ドリンクギフト
,払出数量_ドリンクギフトケース
,払出数量_転売
,払出数量_転売ケース
,払出数量_廃却
,払出数量_廃却ケース
,払出数量_見本
,払出数量_見本ケース
,払出数量_総務払出
,払出数量_総務払出ケース
,払出数量_経理払出
,払出数量_経理払出ケース
,払出数量_品種移動
,払出数量_品種移動ケース
,払出数量_倉庫移動
,払出数量_倉庫移動ケース
,払出数量_その他
,払出数量_その他ケース
,払出数量_棚卸減耗
,払出数量_棚卸減耗ケース
)
AS
SELECT
        SUHG.yyyymm                                    yyyymm                        --年月
       ,PRODC.prod_class_code                          prod_class_code               --商品区分
       ,PRODC.prod_class_name                          prod_class_name               --商品区分名
       ,SUHG.whse_code                                 whse_code                     --倉庫コード
       ,IWM.whse_name                                  whse_name                     --倉庫名
       ,ITEMC.item_class_code                          item_class_code               --品目区分
       ,ITEMC.item_class_name                          item_class_name               --品目区分名
       ,CROWD.crowd_code                               crowd_code                    --群コード
       ,SUHG.item_code                                 item_code                     --品目コード
       ,SUHG.item_name                                 item_name                     --品目名称
       ,SUHG.item_s_name                               item_s_name                   --品目略称
        --0.月首在庫
       ,NVL( SUHG.trans_qty_gessyuzaiko      , 0 )     trans_qty_gessyuzaiko         --月首在庫
       ,NVL( SUHG.trans_qty_gessyuzaiko_cs   , 0 )     trans_qty_gessyuzaiko_cs      --月首在庫ケース
        --1.受入_仕入
       ,NVL( SUHG.trans_qty_uke_shiire       , 0 )     trans_qty_uke_shiire          --受入数量_仕入
       ,NVL( SUHG.trans_qty_uke_shiire_cs    , 0 )     trans_qty_uke_shiire_cs       --受入数量_仕入ケース数
        --2.受入_包装
       ,NVL( SUHG.trans_qty_uke_housou       , 0 )     trans_qty_uke_housou          --受入数量_包装
       ,NVL( SUHG.trans_qty_uke_housou_cs    , 0 )     trans_qty_uke_housou_cs       --受入数量_包装ケース数
        --3.受入_セット
       ,NVL( SUHG.trans_qty_uke_set          , 0 )     trans_qty_uke_set             --受入数量_セット
       ,NVL( SUHG.trans_qty_uke_set_cs       , 0 )     trans_qty_uke_set_cs          --受入数量_セットケース
        --4.受入_沖縄
       ,NVL( SUHG.trans_qty_uke_okinawa      , 0 )     trans_qty_uke_okinawa         --受入数量_沖縄
       ,NVL( SUHG.trans_qty_uke_okinawa_cs   , 0 )     trans_qty_uke_okinawa_cs      --受入数量_沖縄ケース
        --5.受入_振替入庫
       ,NVL( SUHG.trans_qty_uke_furikaein    , 0 )     trans_qty_uke_furikaein       --受入数量_振替入庫
       ,NVL( SUHG.trans_qty_uke_furikaein_cs , 0 )     trans_qty_uke_furikaein_cs    --受入数量_振替入庫ケース
        --6.受入_緑営１
       ,NVL( SUHG.trans_qty_uke_ryokuei1     , 0 )     trans_qty_uke_ryokuei1        --受入数量_緑営１
       ,NVL( SUHG.trans_qty_uke_ryokuei1_cs  , 0 )     trans_qty_uke_ryokuei1_cs     --受入数量_緑営１ケース
        --7.受入_緑営２
       ,NVL( SUHG.trans_qty_uke_ryokuei2     , 0 )     trans_qty_uke_ryokuei2        --受入数量_緑営２
       ,NVL( SUHG.trans_qty_uke_ryokuei2_cs  , 0 )     trans_qty_uke_ryokuei2_cs     --受入数量_緑営２ケース
        --8.受入_ドリンクギフト
       ,NVL( SUHG.trans_qty_uke_drinkgift    , 0 )     trans_qty_uke_drinkgift       --受入数量_ドリンクギフト
       ,NVL( SUHG.trans_qty_uke_drinkgift_cs , 0 )     trans_qty_uke_drinkgift_cs    --受入数量_ドリンクギフトケース
        --9.受入_倉替
       ,NVL( SUHG.trans_qty_uke_kuragae      , 0 )     trans_qty_uke_kuragae         --受入数量_倉替
       ,NVL( SUHG.trans_qty_uke_kuragae_cs   , 0 )     trans_qty_uke_kuragae_cs      --受入数量_倉替ケース
        --10.受入_返品
       ,NVL( SUHG.trans_qty_uke_henpin       , 0 )     trans_qty_uke_henpin          --受入数量_返品
       ,NVL( SUHG.trans_qty_uke_henpin_cs    , 0 )     trans_qty_uke_henpin_cs       --受入数量_返品ケース
        --20.受入_浜岡
       ,NVL( SUHG.trans_qty_uke_hamaoka      , 0 )     trans_qty_uke_hamaoka         --受入数量_浜岡
       ,NVL( SUHG.trans_qty_uke_hamaoka_cs   , 0 )     trans_qty_uke_hamaoka_cs      --受入数量_浜岡ケース
        --21.受入_品種移動
       ,NVL( SUHG.trans_qty_uke_hinsyuido    , 0 )     trans_qty_uke_hinsyuido       --受入数量_品種移動
       ,NVL( SUHG.trans_qty_uke_hinsyuido_cs , 0 )     trans_qty_uke_hinsyuido_cs    --受入数量_品種移動ケース
        --22.受入_倉庫移動
       ,NVL( SUHG.trans_qty_uke_soukoido     , 0 )     trans_qty_uke_soukoido        --受入数量_倉庫移動
       ,NVL( SUHG.trans_qty_uke_soukoido_cs  , 0 )     trans_qty_uke_soukoido_cs     --受入数量_倉庫移動ケース
        --23.受入_その他
       ,NVL( SUHG.trans_qty_uke_sonota       , 0 )     trans_qty_uke_sonota          --受入数量_その他
       ,NVL( SUHG.trans_qty_uke_sonota_cs    , 0 )     trans_qty_uke_sonota_cs       --受入数量_その他ケース
        --12.払出_セット
       ,NVL( SUHG.trans_qty_hara_set         , 0 )     trans_qty_hara_set            --払出数量_セット
       ,NVL( SUHG.trans_qty_hara_set_cs      , 0 )     trans_qty_hara_set_cs         --払出数量_セットケース
        --13.払出_返品原料へ
       ,NVL( SUHG.trans_qty_hara_hengen      , 0 )     trans_qty_hara_hengen         --払出数量_返品原料へ
       ,NVL( SUHG.trans_qty_hara_hengen_cs   , 0 )     trans_qty_hara_hengen_cs      --払出数量_返品原料へケース
        --14.払出_解体半製品へ
       ,NVL( SUHG.trans_qty_hara_kaihan      , 0 )     trans_qty_hara_kaihan         --払出数量_解体半製品へ
       ,NVL( SUHG.trans_qty_hara_kaihan_cs   , 0 )     trans_qty_hara_kaihan_cs      --払出数量_解体半製品へケース
        --15.払出_有償
       ,NVL( SUHG.trans_qty_hara_yusyou      , 0 )     trans_qty_hara_yusyou         --払出数量_有償
       ,NVL( SUHG.trans_qty_hara_yusyou_cs   , 0 )     trans_qty_hara_yusyou_cs      --払出数量_有償ケース
        --16.払出_振替有償
       ,NVL( SUHG.trans_qty_hara_furikae     , 0 )     trans_qty_hara_furikae        --払出数量_振替有償
       ,NVL( SUHG.trans_qty_hara_furikae_cs  , 0 )     trans_qty_hara_furikae_cs     --払出数量_振替有償ケース
        --17.払出_拠点
       ,NVL( SUHG.trans_qty_hara_kyoten      , 0 )     trans_qty_hara_kyoten         --払出数量_拠点
       ,NVL( SUHG.trans_qty_hara_kyoten_cs   , 0 )     trans_qty_hara_kyoten_cs      --払出数量_拠点ケース
        --18.払出_ドリンクギフト
       ,NVL( SUHG.trans_qty_hara_drinkgift   , 0 )     trans_qty_hara_drinkgift      --払出数量_ドリンクギフト
       ,NVL( SUHG.trans_qty_hara_drinkgift_cs, 0 )     trans_qty_hara_drinkgift_cs   --払出数量_ドリンクギフトケース
        --24.払出_転売
       ,NVL( SUHG.trans_qty_hara_tenbai      , 0 )     trans_qty_hara_tenbai         --払出数量_転売
       ,NVL( SUHG.trans_qty_hara_tenbai_cs   , 0 )     trans_qty_hara_tenbai_cs      --払出数量_転売ケース
        --25.払出_廃却
       ,NVL( SUHG.trans_qty_hara_haikyaku    , 0 )     trans_qty_hara_haikyaku       --払出数量_廃却
       ,NVL( SUHG.trans_qty_hara_haikyaku_cs , 0 )     trans_qty_hara_haikyaku_cs    --払出数量_廃却ケース
        --26.払出_見本
       ,NVL( SUHG.trans_qty_hara_mihon       , 0 )     trans_qty_hara_mihon          --払出数量_見本
       ,NVL( SUHG.trans_qty_hara_mihon_cs    , 0 )     trans_qty_hara_mihon_cs       --払出数量_見本ケース
        --27.払出_総務払出
       ,NVL( SUHG.trans_qty_hara_soumu       , 0 )     trans_qty_hara_soumu          --払出数量_総務払出
       ,NVL( SUHG.trans_qty_hara_soumu_cs    , 0 )     trans_qty_hara_soumu_cs       --払出数量_総務払出ケース
        --28.払出_経理払出
       ,NVL( SUHG.trans_qty_hara_keiri       , 0 )     trans_qty_hara_keiri          --払出数量_経理払出
       ,NVL( SUHG.trans_qty_hara_keiri_cs    , 0 )     trans_qty_hara_keiri_cs       --払出数量_経理払出ケース
        --29.払出_品種移動
       ,NVL( SUHG.trans_qty_hara_hinsyuido   , 0 )     trans_qty_hara_hinsyuido      --払出数量_品種移動
       ,NVL( SUHG.trans_qty_hara_hinsyuido_cs, 0 )     trans_qty_hara_hinsyuido_cs   --払出数量_品種移動ケース
        --30.払出_倉庫移動
       ,NVL( SUHG.trans_qty_hara_soukoido    , 0 )     trans_qty_hara_soukoido       --払出数量_倉庫移動
       ,NVL( SUHG.trans_qty_hara_soukoido_cs , 0 )     trans_qty_hara_soukoido_cs    --払出数量_倉庫移動ケース
        --31.払出_その他
       ,NVL( SUHG.trans_qty_hara_sonota      , 0 )     trans_qty_hara_sonota         --払出数量_その他
       ,NVL( SUHG.trans_qty_hara_sonota_cs   , 0 )     trans_qty_hara_sonota_cs      --払出数量_その他ケース
        --32.払出_棚卸減耗
       ,NVL( SUHG.trans_qty_hara_genmou      , 0 )     trans_qty_hara_genmou         --払出数量_棚卸減耗
       ,NVL( SUHG.trans_qty_hara_genmou_cs   , 0 )     trans_qty_hara_genmou_cs      --払出数量_棚卸減耗ケース
  FROM (
         --**********************************************************************************************
         -- 【年月】【倉庫】【品目】単位に集計した受入情報を取得  START
         --**********************************************************************************************
         SELECT
                 TO_CHAR( UHG.trans_date, 'YYYYMM' )   yyyymm                        --年月
                ,UHG.whse_code                         whse_code                     --倉庫コード
                ,UHG.item_id                           item_id                       --品目ID
                ,ITEM.item_no                          item_code                     --品目コード
                ,ITEM.item_name                        item_name                     --品目名称
                ,ITEM.item_short_name                  item_s_name                   --品目略称
                 --0.月首在庫
                ,SUM( CASE WHEN UHG.column_no =  0 THEN UHG.trans_qty                     END ) trans_qty_gessyuzaiko       --月首在庫
                ,SUM( CASE WHEN UHG.column_no =  0 THEN UHG.trans_qty / ITEM.num_of_cases END ) trans_qty_gessyuzaiko_cs    --月首在庫ケース数
                 --1.受入_仕入
                ,SUM( CASE WHEN UHG.column_no =  1 THEN UHG.trans_qty                     END ) trans_qty_uke_shiire        --受入数量_仕入
                ,SUM( CASE WHEN UHG.column_no =  1 THEN UHG.trans_qty / ITEM.num_of_cases END ) trans_qty_uke_shiire_cs     --受入数量_仕入ケース数
                 --2.受入_包装
                ,SUM( CASE WHEN UHG.column_no =  2 THEN UHG.trans_qty                     END ) trans_qty_uke_housou        --受入数量_包装
                ,SUM( CASE WHEN UHG.column_no =  2 THEN UHG.trans_qty / ITEM.num_of_cases END ) trans_qty_uke_housou_cs     --受入数量_包装ケース数
                 --3.受入_セット
                ,SUM( CASE WHEN UHG.column_no =  3 THEN UHG.trans_qty                     END ) trans_qty_uke_set           --受入数量_セット
                ,SUM( CASE WHEN UHG.column_no =  3 THEN UHG.trans_qty / ITEM.num_of_cases END ) trans_qty_uke_set_cs        --受入数量_セットケース数
                 --4.受入_沖縄
                ,SUM( CASE WHEN UHG.column_no =  4 THEN UHG.trans_qty                     END ) trans_qty_uke_okinawa       --受入数量_沖縄
                ,SUM( CASE WHEN UHG.column_no =  4 THEN UHG.trans_qty / ITEM.num_of_cases END ) trans_qty_uke_okinawa_cs    --受入数量_沖縄ケース数
                 --5.受入_振替入庫
                ,SUM( CASE WHEN UHG.column_no =  5 THEN UHG.trans_qty                     END ) trans_qty_uke_furikaein     --受入数量_振替入庫
                ,SUM( CASE WHEN UHG.column_no =  5 THEN UHG.trans_qty / ITEM.num_of_cases END ) trans_qty_uke_furikaein_cs  --受入数量_振替入庫ケース数
                 --6.受入_緑営１
                ,SUM( CASE WHEN UHG.column_no =  6 THEN UHG.trans_qty                     END ) trans_qty_uke_ryokuei1      --受入数量_緑営１
                ,SUM( CASE WHEN UHG.column_no =  6 THEN UHG.trans_qty / ITEM.num_of_cases END ) trans_qty_uke_ryokuei1_cs   --受入数量_緑営１ケース数
                 --7.受入_緑営２
                ,SUM( CASE WHEN UHG.column_no =  7 THEN UHG.trans_qty                     END ) trans_qty_uke_ryokuei2      --受入数量_緑営２
                ,SUM( CASE WHEN UHG.column_no =  7 THEN UHG.trans_qty / ITEM.num_of_cases END ) trans_qty_uke_ryokuei2_cs   --受入数量_緑営２ケース数
                 --8.受入_ドリンクギフト
                ,SUM( CASE WHEN UHG.column_no =  8 THEN UHG.trans_qty                     END ) trans_qty_uke_drinkgift     --受入数量_ドリンクギフト
                ,SUM( CASE WHEN UHG.column_no =  8 THEN UHG.trans_qty / ITEM.num_of_cases END ) trans_qty_uke_drinkgift_cs  --受入数量_ドリンクギフトケース数
                 --9.受入_倉替
                ,SUM( CASE WHEN UHG.column_no =  9 THEN UHG.trans_qty                     END ) trans_qty_uke_kuragae       --受入数量_倉替
                ,SUM( CASE WHEN UHG.column_no =  9 THEN UHG.trans_qty / ITEM.num_of_cases END ) trans_qty_uke_kuragae_cs    --受入数量_倉替ケース数
                 --10.受入_返品
                ,SUM( CASE WHEN UHG.column_no = 10 THEN UHG.trans_qty                     END ) trans_qty_uke_henpin        --受入数量_返品
                ,SUM( CASE WHEN UHG.column_no = 10 THEN UHG.trans_qty / ITEM.num_of_cases END ) trans_qty_uke_henpin_cs     --受入数量_返品ケース数
                 --20.受入_浜岡
                ,SUM( CASE WHEN UHG.column_no = 20 THEN UHG.trans_qty                     END ) trans_qty_uke_hamaoka       --受入数量_浜岡
                ,SUM( CASE WHEN UHG.column_no = 20 THEN UHG.trans_qty / ITEM.num_of_cases END ) trans_qty_uke_hamaoka_cs    --受入数量_浜岡ケース数
                 --21.受入_品種移動
                ,SUM( CASE WHEN UHG.column_no = 21 THEN UHG.trans_qty                     END ) trans_qty_uke_hinsyuido     --受入数量_品種移動
                ,SUM( CASE WHEN UHG.column_no = 21 THEN UHG.trans_qty / ITEM.num_of_cases END ) trans_qty_uke_hinsyuido_cs  --受入数量_品種移動ケース数
                 --22.受入_倉庫移動
                ,SUM( CASE WHEN UHG.column_no = 22 THEN UHG.trans_qty                     END ) trans_qty_uke_soukoido      --受入数量_倉庫移動
                ,SUM( CASE WHEN UHG.column_no = 22 THEN UHG.trans_qty / ITEM.num_of_cases END ) trans_qty_uke_soukoido_cs   --受入数量_倉庫移動ケース数
                 --23.受入_その他
                ,SUM( CASE WHEN UHG.column_no = 23 THEN UHG.trans_qty                     END ) trans_qty_uke_sonota        --受入数量_その他
                ,SUM( CASE WHEN UHG.column_no = 23 THEN UHG.trans_qty / ITEM.num_of_cases END ) trans_qty_uke_sonota_cs     --受入数量_その他ケース数
                 --12.払出_セット
                ,SUM( CASE WHEN UHG.column_no = 12 THEN UHG.trans_qty                     END ) trans_qty_hara_set          --払出数量_セット
                ,SUM( CASE WHEN UHG.column_no = 12 THEN UHG.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_set_cs       --払出数量_セットケース数
                 --13.払出_返品原料へ
                ,SUM( CASE WHEN UHG.column_no = 13 THEN UHG.trans_qty                     END ) trans_qty_hara_hengen       --払出数量_返品原料へ
                ,SUM( CASE WHEN UHG.column_no = 13 THEN UHG.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_hengen_cs    --払出数量_返品原料へケース数
                 --14.払出_解体半製品へ
                ,SUM( CASE WHEN UHG.column_no = 14 THEN UHG.trans_qty                     END ) trans_qty_hara_kaihan       --払出数量_解体半製品へ
                ,SUM( CASE WHEN UHG.column_no = 14 THEN UHG.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_kaihan_cs    --払出数量_解体半製品へケース数
                 --15.払出_有償
                ,SUM( CASE WHEN UHG.column_no = 15 THEN UHG.trans_qty                     END ) trans_qty_hara_yusyou       --払出数量_有償
                ,SUM( CASE WHEN UHG.column_no = 15 THEN UHG.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_yusyou_cs    --払出数量_有償ケース数
                 --16.払出_振替有償
                ,SUM( CASE WHEN UHG.column_no = 16 THEN UHG.trans_qty                     END ) trans_qty_hara_furikae      --払出数量_振替有償
                ,SUM( CASE WHEN UHG.column_no = 16 THEN UHG.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_furikae_cs   --払出数量_振替有償ケース数
                 --17.払出_拠点
                ,SUM( CASE WHEN UHG.column_no = 17 THEN UHG.trans_qty                     END ) trans_qty_hara_kyoten       --払出数量_拠点
                ,SUM( CASE WHEN UHG.column_no = 17 THEN UHG.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_kyoten_cs    --払出数量_拠点ケース数
                 --18.払出_ドリンクギフト
                ,SUM( CASE WHEN UHG.column_no = 18 THEN UHG.trans_qty                     END ) trans_qty_hara_drinkgift    --払出数量_ドリンクギフト
                ,SUM( CASE WHEN UHG.column_no = 18 THEN UHG.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_drinkgift_cs --払出数量_ドリンクギフトケース数
                 --24.払出_転売
                ,SUM( CASE WHEN UHG.column_no = 24 THEN UHG.trans_qty                     END ) trans_qty_hara_tenbai       --払出数量_転売
                ,SUM( CASE WHEN UHG.column_no = 24 THEN UHG.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_tenbai_cs    --払出数量_転売ケース数
                 --25.払出_廃却
                ,SUM( CASE WHEN UHG.column_no = 25 THEN UHG.trans_qty                     END ) trans_qty_hara_haikyaku     --払出数量_廃却
                ,SUM( CASE WHEN UHG.column_no = 25 THEN UHG.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_haikyaku_cs  --払出数量_廃却ケース数
                 --26.払出_見本
                ,SUM( CASE WHEN UHG.column_no = 26 THEN UHG.trans_qty                     END ) trans_qty_hara_mihon        --払出数量_見本
                ,SUM( CASE WHEN UHG.column_no = 26 THEN UHG.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_mihon_cs     --払出数量_見本ケース数
                 --27.払出_総務払出
                ,SUM( CASE WHEN UHG.column_no = 27 THEN UHG.trans_qty                     END ) trans_qty_hara_soumu        --払出数量_総務払出
                ,SUM( CASE WHEN UHG.column_no = 27 THEN UHG.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_soumu_cs     --払出数量_総務払出ケース数
                 --28.払出_経理払出
                ,SUM( CASE WHEN UHG.column_no = 28 THEN UHG.trans_qty                     END ) trans_qty_hara_keiri        --払出数量_経理払出
                ,SUM( CASE WHEN UHG.column_no = 28 THEN UHG.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_keiri_cs     --払出数量_経理払出ケース数
                 --29.払出_品種移動
                ,SUM( CASE WHEN UHG.column_no = 29 THEN UHG.trans_qty                     END ) trans_qty_hara_hinsyuido    --払出数量_品種移動
                ,SUM( CASE WHEN UHG.column_no = 29 THEN UHG.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_hinsyuido_cs --払出数量_品種移動ケース数
                 --30.払出_倉庫移動
                ,SUM( CASE WHEN UHG.column_no = 30 THEN UHG.trans_qty                     END ) trans_qty_hara_soukoido     --払出数量_倉庫移動
                ,SUM( CASE WHEN UHG.column_no = 30 THEN UHG.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_soukoido_cs  --払出数量_倉庫移動ケース数
                 --31.払出_その他
                ,SUM( CASE WHEN UHG.column_no = 31 THEN UHG.trans_qty                     END ) trans_qty_hara_sonota       --払出数量_その他
                ,SUM( CASE WHEN UHG.column_no = 31 THEN UHG.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_sonota_cs    --払出数量_その他ケース数
                 --32.払出_棚卸減耗
                ,SUM( CASE WHEN UHG.column_no = 32 THEN UHG.trans_qty                     END ) trans_qty_hara_genmou       --払出数量_棚卸減耗
                ,SUM( CASE WHEN UHG.column_no = 32 THEN UHG.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_genmou_cs    --払出数量_棚卸減耗ケース
           FROM
                 xxsky_uh_goods2_v                     UHG                 --SKYLINK用中間VIEW 受払情報_製品VIEW2
                ,xxsky_item_mst2_v                     ITEM                --SKYLINK用中間VIEW OPM品目情報VIEW
          WHERE
            --品目情報取得
-- 2009/12/15 T.Yoshimoto Mod Start
--                 UHG.item_id                  = ITEM.item_id(+)
--            AND  TRUNC( UHG.trans_date )     >= ITEM.start_date_active(+)
--            AND  TRUNC( UHG.trans_date )     <= ITEM.end_date_active(+)
                 UHG.item_id                  = ITEM.item_id
            AND  TRUNC( UHG.trans_date )     >= ITEM.start_date_active
            AND  TRUNC( UHG.trans_date )     <= ITEM.end_date_active
-- 2009/12/15 T.Yoshimoto Mod Start
         GROUP BY
                 TO_CHAR( UHG.trans_date, 'YYYYMM' )
                ,UHG.whse_code
                ,UHG.item_id
                ,ITEM.item_no
                ,ITEM.item_name
                ,ITEM.item_short_name
         --**********************************************************************************************
         -- 【年月】【倉庫】【品目】単位に集計した受入情報を取得  END
         --**********************************************************************************************
       )                                SUHG           --集計受払_製品情報
       ,ic_whse_mst                     IWM            --倉庫マスタ
       ,xxsky_prod_class_v              PRODC          --SKYLINK用 商品区分取得VIEW
       ,xxsky_item_class_v              ITEMC          --SKYLINK用 品目区分取得VIEW
       ,xxsky_crowd_code_v              CROWD          --SKYLINK用 群コード取得VIEW
 WHERE
   --全項目の数量がゼロの場合は出力しない
       (    SUHG.trans_qty_gessyuzaiko      <> 0       --0.月首在庫
         OR SUHG.trans_qty_uke_shiire       <> 0       --1.受入_仕入
         OR SUHG.trans_qty_uke_housou       <> 0       --2.受入_包装
         OR SUHG.trans_qty_uke_set          <> 0       --3.受入_セット
         OR SUHG.trans_qty_uke_okinawa      <> 0       --4.受入_沖縄
         OR SUHG.trans_qty_uke_furikaein    <> 0       --5.受入_振替入庫
         OR SUHG.trans_qty_uke_ryokuei1     <> 0       --6.受入_緑営１
         OR SUHG.trans_qty_uke_ryokuei2     <> 0       --7.受入_緑営２
         OR SUHG.trans_qty_uke_drinkgift    <> 0       --8.受入_ドリンクギフト
         OR SUHG.trans_qty_uke_kuragae      <> 0       --9.受入_倉替
         OR SUHG.trans_qty_uke_henpin       <> 0       --10.受入_返品
         OR SUHG.trans_qty_uke_hamaoka      <> 0       --20.受入_浜岡
         OR SUHG.trans_qty_uke_hinsyuido    <> 0       --21.受入_品種移動
         OR SUHG.trans_qty_uke_soukoido     <> 0       --22.受入_倉庫移動
         OR SUHG.trans_qty_uke_sonota       <> 0       --23.受入_その他
         OR SUHG.trans_qty_hara_set         <> 0       --12.払出_セット
         OR SUHG.trans_qty_hara_hengen      <> 0       --13.払出_返品原料へ
         OR SUHG.trans_qty_hara_kaihan      <> 0       --14.払出_解体半製品へ
         OR SUHG.trans_qty_hara_yusyou      <> 0       --15.払出_有償
         OR SUHG.trans_qty_hara_furikae     <> 0       --16.払出_振替有償
         OR SUHG.trans_qty_hara_kyoten      <> 0       --17.払出_拠点
         OR SUHG.trans_qty_hara_drinkgift   <> 0       --18.払出_ドリンクギフト
         OR SUHG.trans_qty_hara_tenbai      <> 0       --24.払出_転売
         OR SUHG.trans_qty_hara_haikyaku    <> 0       --25.払出_廃却
         OR SUHG.trans_qty_hara_mihon       <> 0       --26.払出_見本
         OR SUHG.trans_qty_hara_soumu       <> 0       --27.払出_総務払出
         OR SUHG.trans_qty_hara_keiri       <> 0       --28.払出_経理払出
         OR SUHG.trans_qty_hara_hinsyuido   <> 0       --29.払出_品種移動
         OR SUHG.trans_qty_hara_soukoido    <> 0       --30.払出_倉庫移動
         OR SUHG.trans_qty_hara_sonota      <> 0       --31.払出_その他
         OR SUHG.trans_qty_hara_genmou      <> 0       --32.払出_棚卸減耗
       )
   --倉庫名取得
-- 2009/12/15 T.Yoshimoto Mod Start
   --AND  SUHG.whse_code   = IWM.whse_code(+)
   AND  SUHG.whse_code   = IWM.whse_code
-- 2009/12/15 T.Yoshimoto Mod End
   --品目カテゴリ情報取得
-- 2009/12/15 T.Yoshimoto Mod Start
--   AND  SUHG.item_id     = PRODC.item_id(+)  --商品区分
--   AND  SUHG.item_id     = ITEMC.item_id(+)  --品目区分
--   AND  SUHG.item_id     = CROWD.item_id(+)  --群コード
   AND  SUHG.item_id     = PRODC.item_id  --商品区分
   AND  PRODC.item_id     = ITEMC.item_id  --品目区分
   AND  PRODC.item_id     = CROWD.item_id  --群コード
   AND  ITEMC.item_id     = CROWD.item_id
-- 2009/12/15 T.Yoshimoto Mod End
/
COMMENT ON TABLE APPS.XXSKY_受払_製品_数量2_V IS 'SKYLINK用受払情報製品（数量）VIEW'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.年月                          IS '年月'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.商品区分                      IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.商品区分名                    IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.倉庫コード                    IS '倉庫コード'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.倉庫名                        IS '倉庫名'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.品目区分                      IS '品目区分'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.品目区分名                    IS '品目区分名'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.群コード                      IS '群コード'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.品目コード                    IS '品目コード'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.品目名称                      IS '品目名称'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.品目略称                      IS '品目略称'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.月首在庫                      IS '月首在庫'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.月首在庫ケース                IS '月首在庫ケース'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.受入数量_仕入                 IS '受入数量_仕入'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.受入数量_仕入ケース           IS '受入数量_仕入ケース'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.受入数量_包装                 IS '受入数量_包装'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.受入数量_包装ケース           IS '受入数量_包装ケース'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.受入数量_セット               IS '受入数量_セット'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.受入数量_セットケース         IS '受入数量_セットケース'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.受入数量_沖縄                 IS '受入数量_沖縄'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.受入数量_沖縄ケース           IS '受入数量_沖縄ケース'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.受入数量_振替入庫             IS '受入数量_振替入庫'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.受入数量_振替入庫ケース       IS '受入数量_振替入庫ケース'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.受入数量_緑営１               IS '受入数量_緑営１'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.受入数量_緑営１ケース         IS '受入数量_緑営１ケース'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.受入数量_緑営２               IS '受入数量_緑営２'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.受入数量_緑営２ケース         IS '受入数量_緑営２ケース'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.受入数量_ドリンクギフト       IS '受入数量_ドリンクギフト'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.受入数量_ドリンクギフトケース IS '受入数量_ドリンクギフトケース'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.受入数量_倉替                 IS '受入数量_倉替'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.受入数量_倉替ケース           IS '受入数量_倉替ケース'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.受入数量_返品                 IS '受入数量_返品'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.受入数量_返品ケース           IS '受入数量_返品ケース'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.受入数量_浜岡                 IS '受入数量_浜岡'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.受入数量_浜岡ケース           IS '受入数量_浜岡ケース'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.受入数量_品種移動             IS '受入数量_品種移動'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.受入数量_品種移動ケース       IS '受入数量_品種移動ケース'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.受入数量_倉庫移動             IS '受入数量_倉庫移動'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.受入数量_倉庫移動ケース       IS '受入数量_倉庫移動ケース'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.受入数量_その他               IS '受入数量_その他'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.受入数量_その他ケース         IS '受入数量_その他ケース'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.払出数量_セット               IS '払出数量_セット'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.払出数量_セットケース         IS '払出数量_セットケース'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.払出数量_返品原料へ           IS '払出数量_返品原料へ'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.払出数量_返品原料へケース     IS '払出数量_返品原料へケース'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.払出数量_解体半製品へ         IS '払出数量_解体半製品へ'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.払出数量_解体半製品へケース   IS '払出数量_解体半製品へケース'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.払出数量_有償                 IS '払出数量_有償'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.払出数量_有償ケース           IS '払出数量_有償ケース'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.払出数量_振替有償             IS '払出数量_振替有償'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.払出数量_振替有償ケース       IS '払出数量_振替有償ケース'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.払出数量_拠点                 IS '払出数量_拠点'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.払出数量_拠点ケース           IS '払出数量_拠点ケース'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.払出数量_ドリンクギフト       IS '払出数量_ドリンクギフト'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.払出数量_ドリンクギフトケース IS '払出数量_ドリンクギフトケース'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.払出数量_転売                 IS '払出数量_転売'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.払出数量_転売ケース           IS '払出数量_転売ケース'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.払出数量_廃却                 IS '払出数量_廃却'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.払出数量_廃却ケース           IS '払出数量_廃却ケース'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.払出数量_見本                 IS '払出数量_見本'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.払出数量_見本ケース           IS '払出数量_見本ケース'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.払出数量_総務払出             IS '払出数量_総務払出'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.払出数量_総務払出ケース       IS '払出数量_総務払出ケース'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.払出数量_経理払出             IS '払出数量_経理払出'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.払出数量_経理払出ケース       IS '払出数量_経理払出ケース'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.払出数量_品種移動             IS '払出数量_品種移動'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.払出数量_品種移動ケース       IS '払出数量_品種移動ケース'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.払出数量_倉庫移動             IS '払出数量_倉庫移動'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.払出数量_倉庫移動ケース       IS '払出数量_倉庫移動ケース'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.払出数量_その他               IS '払出数量_その他'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.払出数量_その他ケース         IS '払出数量_その他ケース'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.払出数量_棚卸減耗             IS '払出数量_棚卸減耗'
/
COMMENT ON COLUMN APPS.XXSKY_受払_製品_数量2_V.払出数量_棚卸減耗ケース       IS '払出数量_棚卸減耗ケース'
/