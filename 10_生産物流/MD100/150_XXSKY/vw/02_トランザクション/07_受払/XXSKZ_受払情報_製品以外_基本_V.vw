/*************************************************************************
 * 
 * View  Name      : XXSKZ_受払情報_製品以外_基本_V
 * Description     : XXSKZ_受払情報_製品以外_基本_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2012/11/27    1.0   SCSK 月野    初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_受払情報_製品以外_基本_V
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
,月首在庫金額
,受入数量_仕入
,受入数量_仕入ケース
,受入金額_仕入
,受入数量_再製
,受入数量_再製ケース
,受入金額_再製
,受入数量_合組
,受入数量_合組ケース
,受入金額_合組
,受入数量_再製合組
,受入数量_再製合組ケース
,受入金額_再製合組
,受入数量_製品より
,受入数量_製品よりケース
,受入金額_製品より
,受入数量_原料_半製品より
,受入数量_原料_半製品よりケース
,受入金額_原料_半製品より
,受入数量_浜岡
,受入数量_浜岡ケース
,受入金額_浜岡
,受入数量_品種移動
,受入数量_品種移動ケース
,受入金額_品種移動
,受入数量_倉庫移動
,受入数量_倉庫移動ケース
,受入金額_倉庫移動
,受入数量_その他
,受入数量_その他ケース
,受入金額_その他
,払出数量_再製
,払出数量_再製ケース
,払出金額_再製
,払出数量_ブレンド合組
,払出数量_ブレンド合組ケース
,払出金額_ブレンド合組
,払出数量_再製合組
,払出数量_再製合組ケース
,払出金額_再製合組
,払出数量_包装
,払出数量_包装ケース
,払出金額_包装
,払出数量_セット
,払出数量_セットケース
,払出金額_セット
,払出数量_沖縄
,払出数量_沖縄ケース
,払出金額_沖縄
,払出数量_有償
,払出数量_有償ケース
,払出金額_有償
,払出数量_拠点
,払出数量_拠点ケース
,払出金額_拠点
,払出数量_振替出庫
,払出数量_振替出庫ケース
,払出金額_振替出庫
,払出数量_製品へ
,払出数量_製品へケース
,払出金額_製品へ
,払出数量_原料_半製品へ
,払出数量_原料_半製品へケース
,払出金額_原料_半製品へ
,払出数量_転売
,払出数量_転売ケース
,払出金額_転売
,払出数量_廃却
,払出数量_廃却ケース
,払出金額_廃却
,払出数量_見本
,払出数量_見本ケース
,払出金額_見本
,払出数量_総務払出
,払出数量_総務払出ケース
,払出金額_総務払出
,払出数量_経理払出
,払出数量_経理払出ケース
,払出金額_経理払出
,払出数量_品種移動
,払出数量_品種移動ケース
,払出金額_品種移動
,払出数量_倉庫移動
,払出数量_倉庫移動ケース
,払出金額_倉庫移動
,払出数量_その他
,払出数量_その他ケース
,払出金額_その他
,払出数量_棚卸減耗
,払出数量_棚卸減耗ケース
,払出金額_棚卸減耗
)
AS
SELECT
        SUHM.yyyymm                                    yyyymm                             --年月
       ,PRODC.prod_class_code                          prod_class_code                    --商品区分
       ,PRODC.prod_class_name                          prod_class_name                    --商品区分名
       ,SUHM.whse_code                                 whse_code                          --倉庫コード
       ,IWM.whse_name                                  whse_name                          --倉庫名
       ,ITEMC.item_class_code                          item_class_code                    --品目区分
       ,ITEMC.item_class_name                          item_class_name                    --品目区分名
       ,CROWD.crowd_code                               crowd_code                         --群コード
       ,SUHM.item_code                                 item_code                          --品目コード
       ,SUHM.item_name                                 item_name                          --品目名称
       ,SUHM.item_s_name                               item_s_name                        --品目略称
        --0.月首在庫
       ,NVL( SUHM.trans_qty_gessyuzaiko         , 0 )  trans_qty_gessyuzaiko              --月首在庫
       ,NVL( SUHM.trans_qty_gessyuzaiko_cs      , 0 )  trans_qty_gessyuzaiko_cs           --月首在庫ケース
       ,NVL( SUHM.price_gessyuzaiko             , 0 )  price_gessyuzaiko                  --月首在庫金額
        --1.受入_仕入
       ,NVL( SUHM.trans_qty_uke_shiire          , 0 )  trans_qty_uke_shiire               --受入数量_仕入
       ,NVL( SUHM.trans_qty_uke_shiire_cs       , 0 )  trans_qty_uke_shiire_cs            --受入数量_仕入ケース
       ,NVL( SUHM.price_uke_shiire              , 0 )  price_uke_shiire                   --受入金額_仕入
        --2.受入_再製
       ,NVL( SUHM.trans_qty_uke_saisei          , 0 )  trans_qty_uke_saisei               --受入数量_再製
       ,NVL( SUHM.trans_qty_uke_saisei_cs       , 0 )  trans_qty_uke_saisei_cs            --受入数量_再製ケース
       ,NVL( SUHM.price_uke_saisei              , 0 )  price_uke_saisei                   --受入金額_再製
        --3.受入_合組
       ,NVL( SUHM.trans_qty_uke_gougumi         , 0 )  trans_qty_uke_gougumi              --受入数量_合組
       ,NVL( SUHM.trans_qty_uke_gougumi_cs      , 0 )  trans_qty_uke_gougumi_cs           --受入数量_合組ケース
       ,NVL( SUHM.price_uke_gougumi             , 0 )  price_uke_gougumi                  --受入金額_合組
        --4.受入_再製合組
       ,NVL( SUHM.trans_qty_uke_saigougumi      , 0 )  trans_qty_uke_saigougumi           --受入数量_再製合組
       ,NVL( SUHM.trans_qty_uke_saigougumi_cs   , 0 )  trans_qty_uke_saigougumi_cs        --受入数量_再製合組ケース
       ,NVL( SUHM.price_uke_saigougumi          , 0 )  price_uke_saigougumi               --受入金額_再製合組
        --5.受入_製品より
       ,NVL( SUHM.trans_qty_uke_seihinyori      , 0 )  trans_qty_uke_seihinyori           --受入数量_製品より
       ,NVL( SUHM.trans_qty_uke_seihinyori_cs   , 0 )  trans_qty_uke_seihinyori_cs        --受入数量_製品よりケース
       ,NVL( SUHM.price_uke_seihinyori          , 0 )  price_uke_seihinyori               --受入金額_製品より
        --6.受入_原料_半製品より
       ,NVL( SUHM.trans_qty_uke_genhanseihin    , 0 )  trans_qty_uke_genhanseihin         --受入数量_原料_半製品より
       ,NVL( SUHM.trans_qty_uke_genhanseihin_cs , 0 )  trans_qty_uke_genhanseihin_cs      --受入数量_原料_半製品よりケース
       ,NVL( SUHM.price_uke_genhanseihin        , 0 )  price_uke_genhanseihin             --受入金額_原料_半製品より
        --20.受入_浜岡
       ,NVL( SUHM.trans_qty_uke_hamaoka         , 0 )  trans_qty_uke_hamaoka              --受入数量_浜岡
       ,NVL( SUHM.trans_qty_uke_hamaoka_cs      , 0 )  trans_qty_uke_hamaoka_cs           --受入数量_浜岡ケース
       ,NVL( SUHM.price_uke_hamaoka             , 0 )  price_uke_hamaoka                  --受入金額_浜岡
        --21.受入_品種移動
       ,NVL( SUHM.trans_qty_uke_hinsyuido       , 0 )  trans_qty_uke_hinsyuido            --受入数量_品種移動
       ,NVL( SUHM.trans_qty_uke_hinsyuido_cs    , 0 )  trans_qty_uke_hinsyuido_cs         --受入数量_品種移動ケース
       ,NVL( SUHM.price_uke_hinsyuido           , 0 )  price_uke_hinsyuido                --受入金額_品種移動
        --22.受入_倉庫移動
       ,NVL( SUHM.trans_qty_uke_soukoido        , 0 )  trans_qty_uke_soukoido             --受入数量_倉庫移動
       ,NVL( SUHM.trans_qty_uke_soukoido_cs     , 0 )  trans_qty_uke_soukoido_cs          --受入数量_倉庫移動ケース
       ,NVL( SUHM.price_uke_soukoido            , 0 )  price_uke_soukoido                 --受入金額_倉庫移動
        --23.受入_その他
       ,NVL( SUHM.trans_qty_uke_sonota          , 0 )  trans_qty_uke_sonota               --受入数量_その他
       ,NVL( SUHM.trans_qty_uke_sonota_cs       , 0 )  trans_qty_uke_sonota_cs            --受入数量_その他ケース
       ,NVL( SUHM.price_uke_sonota              , 0 )  price_uke_sonota                   --受入金額_その他
        --8.払出_再製
       ,NVL( SUHM.trans_qty_hara_saisei         , 0 )  trans_qty_hara_saisei              --払出数量_再製
       ,NVL( SUHM.trans_qty_hara_saisei_cs      , 0 )  trans_qty_hara_saisei_cs           --払出数量_再製ケース
       ,NVL( SUHM.price_hara_saisei             , 0 )  price_hara_saisei                  --払出金額_再製
        --9.払出_ブレンド合組
       ,NVL( SUHM.trans_qty_hara_brendgougumi   , 0 )  trans_qty_hara_brendgougumi        --払出数量_ブレンド合組
       ,NVL( SUHM.trans_qty_hara_brendgougumi_cs, 0 )  trans_qty_hara_brendgougumi_cs     --払出数量_ブレンド合組ケース
       ,NVL( SUHM.price_hara_brendgougumi       , 0 )  price_hara_brendgougumi            --払出金額_ブレンド合組
        --10.払出_再製合組
       ,NVL( SUHM.trans_qty_hara_saigougumi     , 0 )  trans_qty_hara_saigougumi          --払出数量_再製合組
       ,NVL( SUHM.trans_qty_hara_saigougumi_cs  , 0 )  trans_qty_hara_saigougumi_cs       --払出数量_再製合組ケース
       ,NVL( SUHM.price_hara_saigougumi         , 0 )  price_hara_saigougumi              --払出金額_再製合組
        --11.払出_包装
       ,NVL( SUHM.trans_qty_hara_housou         , 0 )  trans_qty_hara_housou              --払出数量_包装
       ,NVL( SUHM.trans_qty_hara_housou_cs      , 0 )  trans_qty_hara_housou_cs           --払出数量_包装ケース
       ,NVL( SUHM.price_hara_housou             , 0 )  price_hara_housou                  --払出金額_包装
        --12.払出_セット
       ,NVL( SUHM.trans_qty_hara_set            , 0 )  trans_qty_hara_set                 --払出数量_セット
       ,NVL( SUHM.trans_qty_hara_set_cs         , 0 )  trans_qty_hara_set_cs              --払出数量_セットケース
       ,NVL( SUHM.price_hara_set                , 0 )  price_hara_set                     --払出金額_セット
        --13.払出_沖縄
       ,NVL( SUHM.trans_qty_hara_okinawa        , 0 )  trans_qty_hara_okinawa             --払出数量_沖縄
       ,NVL( SUHM.trans_qty_hara_okinawa_cs     , 0 )  trans_qty_hara_okinawa_cs          --払出数量_沖縄ケース
       ,NVL( SUHM.price_hara_okinawa            , 0 )  price_hara_okinawa                 --払出金額_沖縄
        --14.払出_有償
       ,NVL( SUHM.trans_qty_hara_yusyou         , 0 )  trans_qty_hara_yusyou              --払出数量_有償
       ,NVL( SUHM.trans_qty_hara_yusyou_cs      , 0 )  trans_qty_hara_yusyou_cs           --払出数量_有償ケース
       ,NVL( SUHM.price_hara_yusyou             , 0 )  price_hara_yusyou                  --払出金額_有償
        --15.払出_拠点
       ,NVL( SUHM.trans_qty_hara_kyoten         , 0 )  trans_qty_hara_kyoten              --払出数量_拠点
       ,NVL( SUHM.trans_qty_hara_kyoten_cs      , 0 )  trans_qty_hara_kyoten_cs           --払出数量_拠点ケース
       ,NVL( SUHM.price_hara_kyoten             , 0 )  price_hara_kyoten                  --払出金額_拠点
        --16.払出_振替出庫
       ,NVL( SUHM.trans_qty_hara_furisyukko     , 0 )  trans_qty_hara_furisyukko          --払出数量_振替出庫
       ,NVL( SUHM.trans_qty_hara_furisyukko_cs  , 0 )  trans_qty_hara_furisyukko_cs       --払出数量_振替出庫ケース
       ,NVL( SUHM.price_hara_furisyukko         , 0 )  price_hara_furisyukko              --払出金額_振替出庫
        --17.払出_製品へ
       ,NVL( SUHM.trans_qty_hara_seihinhe       , 0 )  trans_qty_hara_seihinhe            --払出数量_製品へ
       ,NVL( SUHM.trans_qty_hara_seihinhe_cs    , 0 )  trans_qty_hara_seihinhe_cs         --払出数量_製品へケース
       ,NVL( SUHM.price_hara_seihinhe           , 0 )  price_hara_seihinhe                --払出金額_製品へ
        --18.払出_原料_半製品へ
       ,NVL( SUHM.trans_qty_hara_genhanseihin   , 0 )  trans_qty_hara_genhanseihin        --払出数量_原料_半製品へ
       ,NVL( SUHM.trans_qty_hara_genhanseihin_cs, 0 )  trans_qty_hara_genhanseihin_cs     --払出数量_原料_半製品へケース
       ,NVL( SUHM.price_hara_genhanseihinhe     , 0 )  price_hara_genhanseihinhe          --払出金額_原料_半製品へ
        --24.払出_転売
       ,NVL( SUHM.trans_qty_hara_tenbai         , 0 )  trans_qty_hara_tenbai              --払出数量_転売
       ,NVL( SUHM.trans_qty_hara_tenbai_cs      , 0 )  trans_qty_hara_tenbai_cs           --払出数量_転売ケース
       ,NVL( SUHM.price_hara_tenbai             , 0 )  price_hara_tenbai                  --払出金額_転売
        --25.払出_廃却
       ,NVL( SUHM.trans_qty_hara_haikyaku       , 0 )  trans_qty_hara_haikyaku            --払出数量_廃却
       ,NVL( SUHM.trans_qty_hara_haikyaku_cs    , 0 )  trans_qty_hara_haikyaku_cs         --払出数量_廃却ケース
       ,NVL( SUHM.price_hara_haikyaku           , 0 )  price_hara_haikyaku                --払出金額_廃却
        --26.払出_見本
       ,NVL( SUHM.trans_qty_hara_mihon          , 0 )  trans_qty_hara_mihon               --払出数量_見本
       ,NVL( SUHM.trans_qty_hara_mihon_cs       , 0 )  trans_qty_hara_mihon_cs            --払出数量_見本ケース
       ,NVL( SUHM.price_hara_mihon              , 0 )  price_hara_mihon                   --払出金額_見本
        --27.払出_総務払出
       ,NVL( SUHM.trans_qty_hara_soumu          , 0 )  trans_qty_hara_soumu               --払出数量_総務払出
       ,NVL( SUHM.trans_qty_hara_soumu_cs       , 0 )  trans_qty_hara_soumu_cs            --払出数量_総務払出ケース
       ,NVL( SUHM.price_hara_soumu              , 0 )  price_hara_soumu                   --払出金額_総務払出
        --28.払出_経理払出
       ,NVL( SUHM.trans_qty_hara_keiri          , 0 )  trans_qty_hara_keiri               --払出数量_経理払出
       ,NVL( SUHM.trans_qty_hara_keiri_cs       , 0 )  trans_qty_hara_keiri_cs            --払出数量_経理払出ケース
       ,NVL( SUHM.price_hara_keiri              , 0 )  price_hara_keiri                   --払出金額_経理払出
        --29.払出_品種移動
       ,NVL( SUHM.trans_qty_hara_hinsyuido      , 0 )  trans_qty_hara_hinsyuido           --払出数量_品種移動
       ,NVL( SUHM.trans_qty_hara_hinsyuido_cs   , 0 )  trans_qty_hara_hinsyuido_cs        --払出数量_品種移動ケース
       ,NVL( SUHM.price_hara_hinsyuido          , 0 )  price_hara_hinsyuido               --払出金額_品種移動
        --30.払出_倉庫移動
       ,NVL( SUHM.trans_qty_hara_soukoido       , 0 )  trans_qty_hara_soukoido            --払出数量_倉庫移動
       ,NVL( SUHM.trans_qty_hara_soukoido_cs    , 0 )  trans_qty_hara_soukoido_cs         --払出数量_倉庫移動ケース
       ,NVL( SUHM.price_hara_soukoido           , 0 )  price_hara_soukoido                --払出金額_倉庫移動
        --31.払出_その他
       ,NVL( SUHM.trans_qty_hara_sonota         , 0 )  trans_qty_hara_sonota              --払出数量_その他
       ,NVL( SUHM.trans_qty_hara_sonota_cs      , 0 )  trans_qty_hara_sonota_cs           --払出数量_その他ケース
       ,NVL( SUHM.price_hara_sonota             , 0 )  price_hara_sonota                  --払出金額_その他
        --32.払出_棚卸減耗
       ,NVL( SUHM.trans_qty_hara_genmou         , 0 )  trans_qty_hara_genmou              --払出数量_棚卸減耗
       ,NVL( SUHM.trans_qty_hara_genmou_cs      , 0 )  trans_qty_hara_genmou_cs           --払出数量_棚卸減耗ケース
       ,NVL( SUHM.price_hara_genmou             , 0 )  price_hara_genmou                  --払出金額_棚卸減耗
  FROM (
         --**********************************************************************************************
         -- 【年月】【倉庫】【品目】単位に集計した受入情報を取得  START
         --**********************************************************************************************
         SELECT
                 TO_CHAR( UHM.trans_date, 'YYYYMM' )   yyyymm                        --年月
                ,UHM.whse_code                         whse_code                     --倉庫コード
                ,UHM.item_id                           item_id                       --品目ID
                ,ITEM.item_no                          item_code                     --品目コード
                ,ITEM.item_name                        item_name                     --品目名称
                ,ITEM.item_short_name                  item_s_name                   --品目略称
                 --0.月首在庫
                ,SUM( CASE WHEN UHM.column_no =  0 THEN UHM.trans_qty                     END ) trans_qty_gessyuzaiko          --月首在庫
                ,SUM( CASE WHEN UHM.column_no =  0 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_gessyuzaiko_cs       --月首在庫ケース数
                ,SUM( CASE WHEN UHM.column_no =  0 THEN
                                --------------------------------------------------------------------------------------------------
                                -- 【金額計算】 ※明細単位で四捨五入する必要がある                                              --
                                --     ① 原価管理区分が'1:標準' なら                                   【標準原価×数量】      --
                                --     ② 原価管理区分が'0:実勢' 且つ ロット管理管理区分が'0:無し' なら 【標準原価×数量】      --
                                --     ③ 原価管理区分が'0:実勢' 且つ ロット管理管理区分が'1:有り' なら 【ロット別原価×数量】  --
                                --------------------------------------------------------------------------------------------------
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )         --①
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )   --②
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHM.trans_qty )        --③
                                          END
                                END
                      END )                                                                     price_gessyuzaiko              --月首在庫金額
                 --1.受入数量_仕入
                ,SUM( CASE WHEN UHM.column_no =  1 THEN UHM.trans_qty                     END ) trans_qty_uke_shiire           --受入数量_仕入
                ,SUM( CASE WHEN UHM.column_no =  1 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_uke_shiire_cs        --受入数量_仕入ケース数
                ,SUM( CASE WHEN UHM.column_no =  1 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHM.trans_qty )
                                          END
                                END
                      END )                                                                     price_uke_shiire               --受入金額_仕入
                 --2.受入数量_再製
                ,SUM( CASE WHEN UHM.column_no =  2 THEN UHM.trans_qty                     END ) trans_qty_uke_saisei           --受入数量_再製
                ,SUM( CASE WHEN UHM.column_no =  2 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_uke_saisei_cs        --受入数量_再製ケース数
                ,SUM( CASE WHEN UHM.column_no =  2 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHM.trans_qty )
                                          END
                                END
                      END )                                                                     price_uke_saisei               --受入金額_再製
                 --3.受入数量_合組
                ,SUM( CASE WHEN UHM.column_no =  3 THEN UHM.trans_qty                     END ) trans_qty_uke_gougumi          --受入数量_合組
                ,SUM( CASE WHEN UHM.column_no =  3 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_uke_gougumi_cs       --受入数量_合組ケース数
                ,SUM( CASE WHEN UHM.column_no =  3 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHM.trans_qty )
                                          END
                                END
                      END )                                                                     price_uke_gougumi              --受入金額_合組
                 --4.受入数量_再製合組
                ,SUM( CASE WHEN UHM.column_no =  4 THEN UHM.trans_qty                     END ) trans_qty_uke_saigougumi       --受入数量_再製合組
                ,SUM( CASE WHEN UHM.column_no =  4 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_uke_saigougumi_cs    --受入数量_再製合組ケース数
                ,SUM( CASE WHEN UHM.column_no =  4 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHM.trans_qty )
                                          END
                                END
                      END )                                                                     price_uke_saigougumi           --受入金額_再製合組
                 --5.受入数量_製品より
                ,SUM( CASE WHEN UHM.column_no =  5 THEN UHM.trans_qty                     END ) trans_qty_uke_seihinyori       --受入数量_製品より
                ,SUM( CASE WHEN UHM.column_no =  5 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_uke_seihinyori_cs    --受入数量_製品よりケース数
                ,SUM( CASE WHEN UHM.column_no =  5 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHM.trans_qty )
                                          END
                                END
                      END )                                                                     price_uke_seihinyori           --受入金額_製品より
                 --6.受入数量_原料_半製品より
                ,SUM( CASE WHEN UHM.column_no =  6 THEN UHM.trans_qty                     END ) trans_qty_uke_genhanseihin     --受入数量_原料_半製品より
                ,SUM( CASE WHEN UHM.column_no =  6 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_uke_genhanseihin_cs  --受入数量_原料_半製品よりケース数
                ,SUM( CASE WHEN UHM.column_no =  6 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHM.trans_qty )
                                          END
                                END
                      END )                                                                     price_uke_genhanseihin         --受入金額_原料_半製品より
                 --20.受入数量_浜岡
                ,SUM( CASE WHEN UHM.column_no = 20 THEN UHM.trans_qty                     END ) trans_qty_uke_hamaoka          --受入数量_浜岡
                ,SUM( CASE WHEN UHM.column_no = 20 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_uke_hamaoka_cs       --受入数量_浜岡ケース数
                ,SUM( CASE WHEN UHM.column_no = 20 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHM.trans_qty )
                                          END
                                END
                      END )                                                                     price_uke_hamaoka              --受入金額_浜岡
                 --21.受入数量_品種移動
                ,SUM( CASE WHEN UHM.column_no = 21 THEN UHM.trans_qty                     END ) trans_qty_uke_hinsyuido        --受入数量_品種移動
                ,SUM( CASE WHEN UHM.column_no = 21 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_uke_hinsyuido_cs     --受入数量_品種移動ケース数
                ,SUM( CASE WHEN UHM.column_no = 21 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHM.trans_qty )
                                          END
                                END
                      END )                                                                     price_uke_hinsyuido            --受入金額_品種移動
                 --22.受入数量_倉庫移動
                ,SUM( CASE WHEN UHM.column_no = 22 THEN UHM.trans_qty                     END ) trans_qty_uke_soukoido         --受入数量_倉庫移動
                ,SUM( CASE WHEN UHM.column_no = 22 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_uke_soukoido_cs      --受入数量_倉庫移動ケース数
                ,SUM( CASE WHEN UHM.column_no = 22 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHM.trans_qty )
                                          END
                                END
                      END )                                                                     price_uke_soukoido             --受入金額_倉庫移動
                 --23.受入数量_その他
                ,SUM( CASE WHEN UHM.column_no = 23 THEN UHM.trans_qty                     END ) trans_qty_uke_sonota           --受入数量_その他
                ,SUM( CASE WHEN UHM.column_no = 23 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_uke_sonota_cs        --受入数量_その他ケース数
                ,SUM( CASE WHEN UHM.column_no = 23 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHM.trans_qty )
                                          END
                                END
                      END )                                                                     price_uke_sonota               --受入金額_その他
                 --8.払出数量_再製
                ,SUM( CASE WHEN UHM.column_no =  8 THEN UHM.trans_qty                     END ) trans_qty_hara_saisei          --払出数量_再製
                ,SUM( CASE WHEN UHM.column_no =  8 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_saisei_cs       --払出数量_再製ケース数
                ,SUM( CASE WHEN UHM.column_no =  8 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHM.trans_qty )
                                          END
                                END
                      END )                                                                     price_hara_saisei              --払出金額_再製
                 --9.払出数量_ブレンド合組
                ,SUM( CASE WHEN UHM.column_no =  9 THEN UHM.trans_qty                     END ) trans_qty_hara_brendgougumi    --払出数量_ブレンド合組
                ,SUM( CASE WHEN UHM.column_no =  9 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_brendgougumi_cs --払出数量_ブレンド合組ケース数
                ,SUM( CASE WHEN UHM.column_no =  9 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHM.trans_qty )
                                          END
                                END
                      END )                                                                     price_hara_brendgougumi        --払出金額_ブレンド合組
                 --10.払出数量_再製合組
                ,SUM( CASE WHEN UHM.column_no = 10 THEN UHM.trans_qty                     END ) trans_qty_hara_saigougumi      --払出数量_再製合組
                ,SUM( CASE WHEN UHM.column_no = 10 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_saigougumi_cs   --払出数量_再製合組ケース数
                ,SUM( CASE WHEN UHM.column_no = 10 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHM.trans_qty )
                                          END
                                END
                      END )                                                                     price_hara_saigougumi          --払出金額_再製合組
                 --11.払出数量_包装
                ,SUM( CASE WHEN UHM.column_no = 11 THEN UHM.trans_qty                     END ) trans_qty_hara_housou          --払出数量_包装
                ,SUM( CASE WHEN UHM.column_no = 11 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_housou_cs       --払出数量_包装ケース数
                ,SUM( CASE WHEN UHM.column_no = 11 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHM.trans_qty )
                                          END
                                END
                      END )                                                                     price_hara_housou              --払出金額_包装
                 --12.払出数量_セット
                ,SUM( CASE WHEN UHM.column_no = 12 THEN UHM.trans_qty                     END ) trans_qty_hara_set             --払出数量_セット
                ,SUM( CASE WHEN UHM.column_no = 12 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_set_cs          --払出数量_セットケース数
                ,SUM( CASE WHEN UHM.column_no = 12 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHM.trans_qty )
                                          END
                                END
                      END )                                                                     price_hara_set                 --払出金額_セット
                 --13.払出数量_沖縄
                ,SUM( CASE WHEN UHM.column_no = 13 THEN UHM.trans_qty                     END ) trans_qty_hara_okinawa         --払出数量_沖縄
                ,SUM( CASE WHEN UHM.column_no = 13 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_okinawa_cs      --払出数量_沖縄ケース数
                ,SUM( CASE WHEN UHM.column_no = 13 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHM.trans_qty )
                                          END
                                END
                      END )                                                                     price_hara_okinawa             --払出金額_沖縄
                 --14.払出数量_有償
                ,SUM( CASE WHEN UHM.column_no = 14 THEN UHM.trans_qty                     END ) trans_qty_hara_yusyou          --払出数量_有償
                ,SUM( CASE WHEN UHM.column_no = 14 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_yusyou_cs       --払出数量_有償ケース数
                ,SUM( CASE WHEN UHM.column_no = 14 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHM.trans_qty )
                                          END
                                END
                      END )                                                                     price_hara_yusyou              --払出金額_有償
                 --15.払出数量_拠点
                ,SUM( CASE WHEN UHM.column_no = 15 THEN UHM.trans_qty                     END ) trans_qty_hara_kyoten          --払出数量_拠点
                ,SUM( CASE WHEN UHM.column_no = 15 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_kyoten_cs       --払出数量_拠点ケース数
                ,SUM( CASE WHEN UHM.column_no = 15 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHM.trans_qty )
                                          END
                                END
                      END )                                                                     price_hara_kyoten              --払出金額_拠点
                 --16.払出数量_振替出庫
                ,SUM( CASE WHEN UHM.column_no = 16 THEN UHM.trans_qty                     END ) trans_qty_hara_furisyukko      --払出数量_振替出庫
                ,SUM( CASE WHEN UHM.column_no = 16 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_furisyukko_cs   --払出数量_振替出庫ケース数
                ,SUM( CASE WHEN UHM.column_no = 16 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHM.trans_qty )
                                          END
                                END
                      END )                                                                     price_hara_furisyukko          --払出金額_振替出庫
                 --17.払出数量_製品へ
                ,SUM( CASE WHEN UHM.column_no = 17 THEN UHM.trans_qty                     END ) trans_qty_hara_seihinhe        --払出数量_製品へ
                ,SUM( CASE WHEN UHM.column_no = 17 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_seihinhe_cs     --払出数量_製品へケース数
                ,SUM( CASE WHEN UHM.column_no = 17 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHM.trans_qty )
                                          END
                                END
                      END )                                                                     price_hara_seihinhe            --払出金額_製品へ
                 --18.払出数量_原料_半製品へ
                ,SUM( CASE WHEN UHM.column_no = 18 THEN UHM.trans_qty                     END ) trans_qty_hara_genhanseihin    --払出数量_原料_半製品へ
                ,SUM( CASE WHEN UHM.column_no = 18 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_genhanseihin_cs --払出数量_原料_半製品へケース数
                ,SUM( CASE WHEN UHM.column_no = 18 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHM.trans_qty )
                                          END
                                END
                      END )                                                                     price_hara_genhanseihinhe      --払出金額_原料_半製品へ
                 --24.払出数量_転売
                ,SUM( CASE WHEN UHM.column_no = 24 THEN UHM.trans_qty                     END ) trans_qty_hara_tenbai          --払出数量_転売
                ,SUM( CASE WHEN UHM.column_no = 24 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_tenbai_cs       --払出数量_転売ケース数
                ,SUM( CASE WHEN UHM.column_no = 24 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHM.trans_qty )
                                          END
                                END
                      END )                                                                     price_hara_tenbai              --払出金額_転売
                 --25.払出数量_廃却
                ,SUM( CASE WHEN UHM.column_no = 25 THEN UHM.trans_qty                     END ) trans_qty_hara_haikyaku        --払出数量_廃却
                ,SUM( CASE WHEN UHM.column_no = 25 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_haikyaku_cs     --払出数量_廃却ケース数
                ,SUM( CASE WHEN UHM.column_no = 25 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHM.trans_qty )
                                          END
                                END
                      END )                                                                     price_hara_haikyaku            --払出金額_廃却
                 --26.払出数量_見本
                ,SUM( CASE WHEN UHM.column_no = 26 THEN UHM.trans_qty                     END ) trans_qty_hara_mihon           --払出数量_見本
                ,SUM( CASE WHEN UHM.column_no = 26 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_mihon_cs        --払出数量_見本ケース数
                ,SUM( CASE WHEN UHM.column_no = 26 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHM.trans_qty )
                                          END
                                END
                      END )                                                                     price_hara_mihon               --払出金額_見本
                 --27.払出数量_総務払出
                ,SUM( CASE WHEN UHM.column_no = 27 THEN UHM.trans_qty                     END ) trans_qty_hara_soumu           --払出数量_総務払出
                ,SUM( CASE WHEN UHM.column_no = 27 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_soumu_cs        --払出数量_総務払出ケース数
                ,SUM( CASE WHEN UHM.column_no = 27 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHM.trans_qty )
                                          END
                                END
                      END )                                                                     price_hara_soumu               --払出金額_総務払出
                 --28.払出数量_経理払出
                ,SUM( CASE WHEN UHM.column_no = 28 THEN UHM.trans_qty                     END ) trans_qty_hara_keiri           --払出数量_経理払出
                ,SUM( CASE WHEN UHM.column_no = 28 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_keiri_cs        --払出数量_経理払出ケース数
                ,SUM( CASE WHEN UHM.column_no = 28 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHM.trans_qty )
                                          END
                                END
                      END )                                                                     price_hara_keiri               --払出金額_経理払出
                 --29.払出数量_品種移動
                ,SUM( CASE WHEN UHM.column_no = 29 THEN UHM.trans_qty                     END ) trans_qty_hara_hinsyuido       --払出数量_品種移動
                ,SUM( CASE WHEN UHM.column_no = 29 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_hinsyuido_cs    --払出数量_品種移動ケース数
                ,SUM( CASE WHEN UHM.column_no = 29 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHM.trans_qty )
                                          END
                                END
                      END )                                                                     price_hara_hinsyuido           --払出金額_品種移動
                 --30.払出数量_倉庫移動
                ,SUM( CASE WHEN UHM.column_no = 30 THEN UHM.trans_qty                     END ) trans_qty_hara_soukoido        --払出数量_倉庫移動
                ,SUM( CASE WHEN UHM.column_no = 30 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_soukoido_cs     --払出数量_倉庫移動ケース数
                ,SUM( CASE WHEN UHM.column_no = 30 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHM.trans_qty )
                                          END
                                END
                      END )                                                                     price_hara_soukoido            --払出金額_倉庫移動
                 --31.払出数量_その他
                ,SUM( CASE WHEN UHM.column_no = 31 THEN UHM.trans_qty                     END ) trans_qty_hara_sonota          --払出数量_その他
                ,SUM( CASE WHEN UHM.column_no = 31 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_sonota_cs       --払出数量_その他ケース数
                ,SUM( CASE WHEN UHM.column_no = 31 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHM.trans_qty )
                                          END
                                END
                      END )                                                                     price_hara_sonota              --払出金額_その他
                 --32.払出数量_棚卸減耗
                ,SUM( CASE WHEN UHM.column_no = 32 THEN UHM.trans_qty                     END ) trans_qty_hara_genmou          --払出数量_棚卸減耗
                ,SUM( CASE WHEN UHM.column_no = 32 THEN UHM.trans_qty / ITEM.num_of_cases END ) trans_qty_hara_genmou_cs       --払出数量_棚卸減耗ケース
                ,SUM( CASE WHEN UHM.column_no = 32 THEN
                                CASE WHEN ITMB.attribute15 = '1' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                     WHEN ITMB.attribute15 = '0' THEN
                                          CASE WHEN ITMB.lot_ctl = '0' THEN ROUND( GPRC.stnd_unit_price * UHM.trans_qty )
                                               WHEN ITMB.lot_ctl = '1' THEN ROUND( LCST.unit_ploce * UHM.trans_qty )
                                          END
                                END
                      END )                                                                     price_hara_genmou              --払出金額_棚卸減耗
           FROM
                 xxskz_uh_materials_v                  UHM                 --SKYLINK用中間VIEW 受払情報_製品以外VIEW
                ,xxskz_item_mst2_v                     ITEM                --SKYLINK用中間VIEW OPM品目情報VIEW
                ,ic_item_mst_b                         ITMB                --品目マスタ(原価･ロット管理区分取得用)
                ,xxcmn_lot_cost                        LCST                --ロット別原価アドオンテーブル
               ,(  -------------------------------------------------
                   -- 品目別標準原価取得用の副問い合わせ
                   -------------------------------------------------
                   SELECT
                           CMPD.item_id                item_id             --品目ID
                          ,CLDD.start_date             start_date_active   --有効開始日
                          ,CLDD.end_date               end_date_active     --有効終了日
                          ,SUM( CMPD.cmpnt_cost )      stnd_unit_price     --標準原価
                     FROM
                           cm_cmpt_dtl                 CMPD                --品目原価マスタ
                          ,cm_cmpt_mst_b               CMPM                --コンポーネント
                          ,cm_cldr_dtl                 CLDD                --原価カレンダ明細
                    WHERE
                           CMPD.whse_code              = '000'             --倉庫コード(原価倉庫)
                      AND  CMPD.cost_mthd_code         = 'STDU'            --原価方法コード
                      AND  CMPD.cost_analysis_code     = '0000'            --分析コード
                      AND  CMPD.cost_level             = 0                 --コストレベル
                      AND  CMPD.rollover_ind           = 0                 --確定フラグ
                      AND  CMPD.delete_mark            = 0                 --削除フラグ
                      AND  CMPD.cost_cmpntcls_id       = CMPM.cost_cmpntcls_id
                      AND  CMPD.calendar_code          = CLDD.calendar_code
                      AND  CMPD.period_code            = CLDD.period_code
                    GROUP BY
                           CMPD.item_id
                          ,CLDD.start_date
                          ,CLDD.end_date
                )                                      GPRC                --品目別標準原価情報
          WHERE
            --品目情報取得
                 UHM.item_id                  = ITEM.item_id(+)
            AND  TRUNC( UHM.trans_date )     >= ITEM.start_date_active(+)
            AND  TRUNC( UHM.trans_date )     <= ITEM.end_date_active(+)
            --原価･ロット管理区分取得
            AND  UHM.item_id                  = ITMB.item_id(+)
            --ロット原価情報取得
            AND  UHM.item_id                  = LCST.item_id(+)
            AND  UHM.lot_id                   = LCST.lot_id(+)
            --標準単価情報取得
            AND  UHM.item_id                  = GPRC.item_id(+)
            AND  TRUNC( UHM.trans_date )     >= TRUNC( GPRC.start_date_active(+) )  --EBS標準テーブルなので時分秒が存在する
            AND  TRUNC( UHM.trans_date )     <= TRUNC( GPRC.end_date_active(+)   )  --EBS標準テーブルなので時分秒が存在する
         GROUP BY
                 TO_CHAR( UHM.trans_date, 'YYYYMM' )
                ,UHM.whse_code
                ,UHM.item_id
                ,ITEM.item_no
                ,ITEM.item_name
                ,ITEM.item_short_name
         --**********************************************************************************************
         -- 【年月】【倉庫】【品目】単位に集計した受入情報を取得  END
         --**********************************************************************************************
       )                                SUHM           --集計受払_製品以外情報
       ,ic_whse_mst                     IWM            --倉庫マスタ
       ,xxskz_prod_class_v              PRODC          --SKYLINK用 商品区分取得VIEW
       ,xxskz_item_class_v              ITEMC          --SKYLINK用 品目区分取得VIEW
       ,xxskz_crowd_code_v              CROWD          --SKYLINK用 群コード取得VIEW
 WHERE
   --全項目の数量がゼロの場合は出力しない
       (    SUHM.trans_qty_gessyuzaiko       <> 0       --0.月首在庫
         OR SUHM.trans_qty_uke_shiire        <> 0       --1.受入_仕入
         OR SUHM.trans_qty_uke_saisei        <> 0       --2.受入_再製
         OR SUHM.trans_qty_uke_gougumi       <> 0       --3.受入_合組
         OR SUHM.trans_qty_uke_saigougumi    <> 0       --4.受入_再製合組
         OR SUHM.trans_qty_uke_seihinyori    <> 0       --5.受入_製品より
         OR SUHM.trans_qty_uke_genhanseihin  <> 0       --6.受入_原料_半製品より
         OR SUHM.trans_qty_uke_hamaoka       <> 0       --20.受入_浜岡
         OR SUHM.trans_qty_uke_hinsyuido     <> 0       --21.受入_品種移動
         OR SUHM.trans_qty_uke_soukoido      <> 0       --22.受入_倉庫移動
         OR SUHM.trans_qty_uke_sonota        <> 0       --23.受入_その他
         OR SUHM.trans_qty_hara_saisei       <> 0       --8.払出_再製
         OR SUHM.trans_qty_hara_brendgougumi <> 0       --9.払出_ブレンド合組
         OR SUHM.trans_qty_hara_saigougumi   <> 0       --10.払出_再製合組
         OR SUHM.trans_qty_hara_housou       <> 0       --11.払出_包装
         OR SUHM.trans_qty_hara_set          <> 0       --12.払出_セット
         OR SUHM.trans_qty_hara_okinawa      <> 0       --13.払出_沖縄
         OR SUHM.trans_qty_hara_yusyou       <> 0       --14.払出_有償
         OR SUHM.trans_qty_hara_kyoten       <> 0       --15.払出_拠点
         OR SUHM.trans_qty_hara_furisyukko   <> 0       --16.払出_振替出庫
         OR SUHM.trans_qty_hara_seihinhe     <> 0       --17.払出_製品へ
         OR SUHM.trans_qty_hara_genhanseihin <> 0       --18.払出_原料_半製品へ
         OR SUHM.trans_qty_hara_tenbai       <> 0       --24.払出_転売
         OR SUHM.trans_qty_hara_haikyaku     <> 0       --25.払出_廃却
         OR SUHM.trans_qty_hara_mihon        <> 0       --26.払出_見本
         OR SUHM.trans_qty_hara_soumu        <> 0       --27.払出_総務払出
         OR SUHM.trans_qty_hara_keiri        <> 0       --28.払出_経理払出
         OR SUHM.trans_qty_hara_hinsyuido    <> 0       --29.払出_品種移動
         OR SUHM.trans_qty_hara_soukoido     <> 0       --30.払出_倉庫移動
         OR SUHM.trans_qty_hara_sonota       <> 0       --31.払出_その他
         OR SUHM.trans_qty_hara_genmou       <> 0       --32.払出_棚卸減耗
       )
   --倉庫名取得
   AND  SUHM.whse_code   = IWM.whse_code(+)
-- 2010/03/10 M.Miyagawa Add Start
   AND  IWM.attribute1 = '0' -- 0: 伊藤園在庫管理倉庫
-- 2010/03/10 M.Miyagawa Add End
   --品目カテゴリ情報取得
   AND  SUHM.item_id     = PRODC.item_id(+)  --商品区分
   AND  SUHM.item_id     = ITEMC.item_id(+)  --品目区分
   AND  SUHM.item_id     = CROWD.item_id(+)  --群コード
/
COMMENT ON TABLE APPS.XXSKZ_受払情報_製品以外_基本_V IS 'SKYLINK用受払情報製品以外（基本）VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.年月                           IS '年月'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.商品区分                       IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.商品区分名                     IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.倉庫コード                     IS '倉庫コード'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.倉庫名                         IS '倉庫名'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.品目区分                       IS '品目区分'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.品目区分名                     IS '品目区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.群コード                       IS '群コード'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.品目コード                     IS '品目コード'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.品目名称                       IS '品目名称'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.品目略称                       IS '品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.月首在庫                       IS '月首在庫'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.月首在庫ケース                 IS '月首在庫ケース'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.月首在庫金額                   IS '月首在庫金額'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.受入数量_仕入                  IS '受入数量_仕入'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.受入数量_仕入ケース            IS '受入数量_仕入ケース'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.受入金額_仕入                  IS '受入金額_仕入'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.受入数量_再製                  IS '受入数量_再製'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.受入数量_再製ケース            IS '受入数量_再製ケース'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.受入金額_再製                  IS '受入金額_再製'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.受入数量_合組                  IS '受入数量_合組'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.受入数量_合組ケース            IS '受入数量_合組ケース'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.受入金額_合組                  IS '受入金額_合組'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.受入数量_再製合組              IS '受入数量_再製合組'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.受入数量_再製合組ケース        IS '受入数量_再製合組ケース'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.受入金額_再製合組              IS '受入金額_再製合組'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.受入数量_製品より              IS '受入数量_製品より'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.受入数量_製品よりケース        IS '受入数量_製品よりケース'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.受入金額_製品より              IS '受入金額_製品より'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.受入数量_原料_半製品より       IS '受入数量_原料_半製品より'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.受入数量_原料_半製品よりケース IS '受入数量_原料_半製品よりケース'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.受入金額_原料_半製品より       IS '受入金額_原料_半製品より'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.受入数量_浜岡                  IS '受入数量_浜岡'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.受入数量_浜岡ケース            IS '受入数量_浜岡ケース'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.受入金額_浜岡                  IS '受入金額_浜岡'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.受入数量_品種移動              IS '受入数量_品種移動'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.受入数量_品種移動ケース        IS '受入数量_品種移動ケース'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.受入金額_品種移動              IS '受入金額_品種移動'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.受入数量_倉庫移動              IS '受入数量_倉庫移動'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.受入数量_倉庫移動ケース        IS '受入数量_倉庫移動ケース'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.受入金額_倉庫移動              IS '受入金額_倉庫移動'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.受入数量_その他                IS '受入数量_その他'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.受入数量_その他ケース          IS '受入数量_その他ケース'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.受入金額_その他                IS '受入金額_その他'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.払出数量_再製                  IS '払出数量_再製'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.払出数量_再製ケース            IS '払出数量_再製ケース'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.払出金額_再製                  IS '払出金額_再製'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.払出数量_ブレンド合組          IS '払出数量_ブレンド合組'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.払出数量_ブレンド合組ケース    IS '払出数量_ブレンド合組ケース'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.払出金額_ブレンド合組          IS '払出金額_ブレンド合組'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.払出数量_再製合組              IS '払出数量_再製合組'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.払出数量_再製合組ケース        IS '払出数量_再製合組ケース'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.払出金額_再製合組              IS '払出金額_再製合組'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.払出数量_包装                  IS '払出数量_包装'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.払出数量_包装ケース            IS '払出数量_包装ケース'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.払出金額_包装                  IS '払出金額_包装'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.払出数量_セット                IS '払出数量_セット'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.払出数量_セットケース          IS '払出数量_セットケース'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.払出金額_セット                IS '払出金額_セット'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.払出数量_沖縄                  IS '払出数量_沖縄'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.払出数量_沖縄ケース            IS '払出数量_沖縄ケース'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.払出金額_沖縄                  IS '払出金額_沖縄'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.払出数量_有償                  IS '払出数量_有償'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.払出数量_有償ケース            IS '払出数量_有償ケース'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.払出金額_有償                  IS '払出金額_有償'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.払出数量_拠点                  IS '払出数量_拠点'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.払出数量_拠点ケース            IS '払出数量_拠点ケース'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.払出金額_拠点                  IS '払出金額_拠点'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.払出数量_振替出庫              IS '払出数量_振替出庫'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.払出数量_振替出庫ケース        IS '払出数量_振替出庫ケース'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.払出金額_振替出庫              IS '払出金額_振替出庫'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.払出数量_製品へ                IS '払出数量_製品へ'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.払出数量_製品へケース          IS '払出数量_製品へケース'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.払出金額_製品へ                IS '払出金額_製品へ'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.払出数量_原料_半製品へ         IS '払出数量_原料_半製品へ'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.払出数量_原料_半製品へケース   IS '払出数量_原料_半製品へケース'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.払出金額_原料_半製品へ         IS '払出金額_原料_半製品へ'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.払出数量_転売                  IS '払出数量_転売'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.払出数量_転売ケース            IS '払出数量_転売ケース'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.払出金額_転売                  IS '払出金額_転売'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.払出数量_廃却                  IS '払出数量_廃却'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.払出数量_廃却ケース            IS '払出数量_廃却ケース'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.払出金額_廃却                  IS '払出金額_廃却'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.払出数量_見本                  IS '払出数量_見本'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.払出数量_見本ケース            IS '払出数量_見本ケース'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.払出金額_見本                  IS '払出金額_見本'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.払出数量_総務払出              IS '払出数量_総務払出'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.払出数量_総務払出ケース        IS '払出数量_総務払出ケース'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.払出金額_総務払出              IS '払出金額_総務払出'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.払出数量_経理払出              IS '払出数量_経理払出'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.払出数量_経理払出ケース        IS '払出数量_経理払出ケース'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.払出金額_経理払出              IS '払出金額_経理払出'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.払出数量_品種移動              IS '払出数量_品種移動'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.払出数量_品種移動ケース        IS '払出数量_品種移動ケース'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.払出金額_品種移動              IS '払出金額_品種移動'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.払出数量_倉庫移動              IS '払出数量_倉庫移動'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.払出数量_倉庫移動ケース        IS '払出数量_倉庫移動ケース'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.払出金額_倉庫移動              IS '払出金額_倉庫移動'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.払出数量_その他                IS '払出数量_その他'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.払出数量_その他ケース          IS '払出数量_その他ケース'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.払出金額_その他                IS '払出金額_その他'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.払出数量_棚卸減耗              IS '払出数量_棚卸減耗'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.払出数量_棚卸減耗ケース        IS '払出数量_棚卸減耗ケース'
/
COMMENT ON COLUMN APPS.XXSKZ_受払情報_製品以外_基本_V.払出金額_棚卸減耗              IS '払出金額_棚卸減耗'
/
