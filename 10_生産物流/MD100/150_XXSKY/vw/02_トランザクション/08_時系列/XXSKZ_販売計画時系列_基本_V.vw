/*************************************************************************
 * 
 * View  Name      : XXSKZ_販売計画時系列_基本_V
 * Description     : XXSKZ_販売計画時系列_基本_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/26    1.0   SCSK M.Nagai 初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_販売計画時系列_基本_V
(
 年度
,世代
,拠点コード
,拠点名
,商品区分
,商品区分名
,品目区分
,品目区分名
,群コード
,品目コード
,品目名
,品目略称
,年間合計ケース数
,年間合計バラ数
,年間合計金額
,年間掛率
,販売計画ケース数_５月
,販売計画バラ数_５月
,販売計画金額_５月
,販売計画掛率_５月
,販売計画ケース数_６月
,販売計画バラ数_６月
,販売計画金額_６月
,販売計画掛率_６月
,販売計画ケース数_７月
,販売計画バラ数_７月
,販売計画金額_７月
,販売計画掛率_７月
,販売計画ケース数_８月
,販売計画バラ数_８月
,販売計画金額_８月
,販売計画掛率_８月
,販売計画ケース数_９月
,販売計画バラ数_９月
,販売計画金額_９月
,販売計画掛率_９月
,販売計画ケース数_１０月
,販売計画バラ数_１０月
,販売計画金額_１０月
,販売計画掛率_１０月
,販売計画ケース数_１１月
,販売計画バラ数_１１月
,販売計画金額_１１月
,販売計画掛率_１１月
,販売計画ケース数_１２月
,販売計画バラ数_１２月
,販売計画金額_１２月
,販売計画掛率_１２月
,販売計画ケース数_１月
,販売計画バラ数_１月
,販売計画金額_１月
,販売計画掛率_１月
,販売計画ケース数_２月
,販売計画バラ数_２月
,販売計画金額_２月
,販売計画掛率_２月
,販売計画ケース数_３月
,販売計画バラ数_３月
,販売計画金額_３月
,販売計画掛率_３月
,販売計画ケース数_４月
,販売計画バラ数_４月
,販売計画金額_４月
,販売計画掛率_４月
)
AS
SELECT
        SMFC.year                                                     year                --年度
       ,SMFC.generation                                               generation          --世代
       ,SMFC.hs_branch                                                hs_branch           --拠点コード
       ,BRCH.party_name                                               hs_branch_name      --拠点名
       ,PRODC.prod_class_code                                         prod_class_code     --商品区分
       ,PRODC.prod_class_name                                         prod_class_name     --商品区分名
       ,ITEMC.item_class_code                                         item_class_code     --品目区分
       ,ITEMC.item_class_name                                         item_class_name     --品目区分名
       ,CROWD.crowd_code                                              crowd_code          --群コード
       ,ITEM.item_no                                                  item_code           --品目コード
       ,ITEM.item_name                                                item_name           --品目名
       ,ITEM.item_short_name                                          item_s_name         --品目略称
        --=====================
        -- 年間
        --=====================
-- MOD DATE:2011/03/02 AUTHOR:HORIGOME CONTENT:E_本稼動_02856 START
-- MOD DATE:2011/02/01 AUTHOR:OUKOU CONTENT:E_本稼動_02856 START
--       ,NVL( TRUNC( SMFC.sum_year_qty / ITEM.num_of_cases ), 0 )      sum_year_cs_qty     --年間合計ケース数
--       ,NVL( CEIL( SMFC.sum_year_qty / ITEM.num_of_cases ), 0 )      sum_year_cs_qty     --年間合計ケース数
-- MOD DATE:2011/02/01 AUTHOR:OUKOU CONTENT:E_本稼動_02856 END
       ,NVL( CEIL( SMFC.sum_year_qty / DECODE(NVL(ITEMB.attribute11,0),0,null,ITEMB.attribute11) ), 0 )      sum_year_cs_qty     --年間合計ケース数
-- MOD DATE:2011/03/02 AUTHOR:HORIGOME CONTENT:E_本稼動_02856 END
       ,NVL( SMFC.sum_year_qty , 0 )                                  sum_year_qty        --年間合計バラ数
       ,NVL( SMFC.sum_year_amt , 0 )                                  sum_year_amt        --年間合計金額
        --掛率  ＜パーセント単位(少数点第３位以下四捨五入)で表示＞
       ,CASE WHEN NVL( TO_NUMBER( ITEMB.attribute5 ) * SMFC.sum_year_qty, 0 ) <> 0 THEN  --ゼロ割り対策
                  -- 掛率 ＝ 販売金額÷定価金額(定価×数量)
                  NVL( ROUND( ( SMFC.sum_year_amt / ( TO_NUMBER( ITEMB.attribute5 ) * SMFC.sum_year_qty ) ) * 100, 2 ), 0 )
             ELSE 0
        END                                                           sum_year_rate       --年間掛率
        --=====================
        --５月
        --=====================
-- MOD DATE:2011/03/02 AUTHOR:HORIGOME CONTENT:E_本稼動_02856 START
-- MOD DATE:2011/02/01 AUTHOR:OUKOU CONTENT:E_本稼動_02856 START
--       ,NVL( TRUNC( SMFC.fc_qty_5th   / ITEM.num_of_cases ), 0 )      fc_cs_qty_5th       --販売計画ケース数_５月
--       ,NVL( CEIL( SMFC.fc_qty_5th   / ITEM.num_of_cases ), 0 )      fc_cs_qty_5th       --販売計画ケース数_５月
-- MOD DATE:2011/02/01 AUTHOR:OUKOU CONTENT:E_本稼動_02856 END
       ,NVL( CEIL( SMFC.fc_qty_5th   / DECODE(NVL(ITEMB.attribute11,0),0,null,ITEMB.attribute11) ), 0 )      fc_cs_qty_5th       --販売計画ケース数_５月
-- MOD DATE:2011/03/02 AUTHOR:HORIGOME CONTENT:E_本稼動_02856 END
       ,NVL( SMFC.fc_qty_5th   , 0 )                                  fc_qty_5th          --販売計画バラ数_５月
       ,NVL( SMFC.fc_amt_5th   , 0 )                                  fc_amt_5th          --販売計画金額_５月
       ,CASE WHEN NVL( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_5th , 0 ) <> 0 THEN  --ゼロ割り対策
                  NVL( ROUND( ( SMFC.fc_amt_5th  / ( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_5th  ) ) * 100, 2 ), 0 )
             ELSE 0
        END                                                           fc_rate_5th         --販売計画掛率_５月
        --=====================
        --６月
        --=====================
-- MOD DATE:2011/03/02 AUTHOR:HORIGOME CONTENT:E_本稼動_02856 START
-- MOD DATE:2011/02/01 AUTHOR:OUKOU CONTENT:E_本稼動_02856 START
--       ,NVL( TRUNC( SMFC.fc_qty_6th   / ITEM.num_of_cases ), 0 )      fc_cs_qty_6th       --販売計画ケース数_６月
--       ,NVL( CEIL( SMFC.fc_qty_6th   / ITEM.num_of_cases ), 0 )      fc_cs_qty_6th       --販売計画ケース数_６月
-- MOD DATE:2011/02/01 AUTHOR:OUKOU CONTENT:E_本稼動_02856 END
       ,NVL( CEIL( SMFC.fc_qty_6th   / DECODE(NVL(ITEMB.attribute11,0),0,null,ITEMB.attribute11) ), 0 )      fc_cs_qty_6th       --販売計画ケース数_６月
-- MOD DATE:2011/03/02 AUTHOR:HORIGOME CONTENT:E_本稼動_02856 END
       ,NVL( SMFC.fc_qty_6th   , 0 )                                  fc_qty_6th          --販売計画バラ数_６月
       ,NVL( SMFC.fc_amt_6th   , 0 )                                  fc_amt_6th          --販売計画金額_６月
       ,CASE WHEN NVL( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_6th , 0 ) <> 0 THEN  --ゼロ割り対策
                  NVL( ROUND( ( SMFC.fc_amt_6th  / ( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_6th  ) ) * 100, 2 ), 0 )
             ELSE 0
        END                                                           fc_rate_6th         --販売計画掛率_６月
        --=====================
        --７月
        --=====================
-- MOD DATE:2011/03/02 AUTHOR:HORIGOME CONTENT:E_本稼動_02856 START
-- MOD DATE:2011/02/01 AUTHOR:OUKOU CONTENT:E_本稼動_02856 START
--       ,NVL( TRUNC( SMFC.fc_qty_7th   / ITEM.num_of_cases ), 0 )      fc_cs_qty_7th       --販売計画ケース数_７月
--       ,NVL( CEIL( SMFC.fc_qty_7th   / ITEM.num_of_cases ), 0 )      fc_cs_qty_7th       --販売計画ケース数_７月
-- MOD DATE:2011/02/01 AUTHOR:OUKOU CONTENT:E_本稼動_02856 END
       ,NVL( CEIL( SMFC.fc_qty_7th   / DECODE(NVL(ITEMB.attribute11,0),0,null,ITEMB.attribute11) ), 0 )      fc_cs_qty_7th       --販売計画ケース数_７月
-- MOD DATE:2011/03/02 AUTHOR:HORIGOME CONTENT:E_本稼動_02856 END
       ,NVL( SMFC.fc_qty_7th   , 0 )                                  fc_qty_7th          --販売計画バラ数_７月
       ,NVL( SMFC.fc_amt_7th   , 0 )                                  fc_amt_7th          --販売計画金額_７月
       ,CASE WHEN NVL( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_7th , 0 ) <> 0 THEN  --ゼロ割り対策
                  NVL( ROUND( ( SMFC.fc_amt_7th  / ( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_7th  ) ) * 100, 2 ), 0 )
             ELSE 0
        END                                                           fc_rate_7th         --販売計画掛率_７月
        --=====================
        --８月
        --=====================
-- MOD DATE:2011/03/02 AUTHOR:HORIGOME CONTENT:E_本稼動_02856 START
-- MOD DATE:2011/02/01 AUTHOR:OUKOU CONTENT:E_本稼動_02856 START
--       ,NVL( TRUNC( SMFC.fc_qty_8th   / ITEM.num_of_cases ), 0 )      fc_cs_qty_8th       --販売計画ケース数_８月
--       ,NVL( CEIL( SMFC.fc_qty_8th   / ITEM.num_of_cases ), 0 )      fc_cs_qty_8th       --販売計画ケース数_８月
-- MOD DATE:2011/02/01 AUTHOR:OUKOU CONTENT:E_本稼動_02856 END
       ,NVL( CEIL( SMFC.fc_qty_8th   / DECODE(NVL(ITEMB.attribute11,0),0,null,ITEMB.attribute11) ), 0 )      fc_cs_qty_8th       --販売計画ケース数_８月
-- MOD DATE:2011/03/02 AUTHOR:HORIGOME CONTENT:E_本稼動_02856 END
       ,NVL( SMFC.fc_qty_8th   , 0 )                                  fc_qty_8th          --販売計画バラ数_８月
       ,NVL( SMFC.fc_amt_8th   , 0 )                                  fc_amt_8th          --販売計画金額_８月
       ,CASE WHEN NVL( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_8th , 0 ) <> 0 THEN  --ゼロ割り対策
                  NVL( ROUND( ( SMFC.fc_amt_8th  / ( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_8th  ) ) * 100, 2 ), 0 )
             ELSE 0
        END                                                           fc_rate_8th         --販売計画掛率_８月
        --=====================
        --９月
        --=====================
-- MOD DATE:2011/03/02 AUTHOR:HORIGOME CONTENT:E_本稼動_02856 START
-- MOD DATE:2011/02/01 AUTHOR:OUKOU CONTENT:E_本稼動_02856 START
--       ,NVL( TRUNC( SMFC.fc_qty_9th   / ITEM.num_of_cases ), 0 )      fc_cs_qty_9th       --販売計画ケース数_９月
--       ,NVL( CEIL( SMFC.fc_qty_9th   / ITEM.num_of_cases ), 0 )      fc_cs_qty_9th       --販売計画ケース数_９月
-- MOD DATE:2011/02/01 AUTHOR:OUKOU CONTENT:E_本稼動_02856 END
       ,NVL( CEIL( SMFC.fc_qty_9th   / DECODE(NVL(ITEMB.attribute11,0),0,null,ITEMB.attribute11) ), 0 )      fc_cs_qty_9th       --販売計画ケース数_９月
-- MOD DATE:2011/03/02 AUTHOR:HORIGOME CONTENT:E_本稼動_02856 END
       ,NVL( SMFC.fc_qty_9th   , 0 )                                  fc_qty_9th          --販売計画バラ数_９月
       ,NVL( SMFC.fc_amt_9th   , 0 )                                  fc_amt_9th          --販売計画金額_９月
       ,CASE WHEN NVL( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_9th , 0 ) <> 0 THEN  --ゼロ割り対策
                  NVL( ROUND( ( SMFC.fc_amt_9th  / ( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_9th  ) ) * 100, 2 ), 0 )
             ELSE 0
        END                                                           fc_rate_9th         --販売計画掛率_９月
        --=====================
        --１０月
        --=====================
-- MOD DATE:2011/03/02 AUTHOR:HORIGOME CONTENT:E_本稼動_02856 START
-- MOD DATE:2011/02/01 AUTHOR:OUKOU CONTENT:E_本稼動_02856 START
--       ,NVL( TRUNC( SMFC.fc_qty_10th  / ITEM.num_of_cases ), 0 )      fc_cs_qty_10th      --販売計画ケース数_１０月
--       ,NVL( CEIL( SMFC.fc_qty_10th  / ITEM.num_of_cases ), 0 )      fc_cs_qty_10th      --販売計画ケース数_１０月
-- MOD DATE:2011/02/01 AUTHOR:OUKOU CONTENT:E_本稼動_02856 END
       ,NVL( CEIL( SMFC.fc_qty_10th  / DECODE(NVL(ITEMB.attribute11,0),0,null,ITEMB.attribute11) ), 0 )      fc_cs_qty_10th      --販売計画ケース数_１０月
-- MOD DATE:2011/03/02 AUTHOR:HORIGOME CONTENT:E_本稼動_02856 END
       ,NVL( SMFC.fc_qty_10th  , 0 )                                  fc_qty_10th         --販売計画バラ数_１０月
       ,NVL( SMFC.fc_amt_10th  , 0 )                                  fc_amt_10th         --販売計画金額_１０月
       ,CASE WHEN NVL( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_10th, 0 ) <> 0 THEN  --ゼロ割り対策
                  NVL( ROUND( ( SMFC.fc_amt_10th / ( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_10th ) ) * 100, 2 ), 0 )
             ELSE 0
        END                                                           fc_rate_10th        --販売計画掛率_１０月
        --=====================
        --１１月
        --=====================
-- MOD DATE:2011/03/02 AUTHOR:HORIGOME CONTENT:E_本稼動_02856 START
-- MOD DATE:2011/02/01 AUTHOR:OUKOU CONTENT:E_本稼動_02856 START
--       ,NVL( TRUNC( SMFC.fc_qty_11th  / ITEM.num_of_cases ), 0 )      fc_cs_qty_11th      --販売計画ケース数_１１月
--       ,NVL( CEIL( SMFC.fc_qty_11th  / ITEM.num_of_cases ), 0 )      fc_cs_qty_11th      --販売計画ケース数_１１月
-- MOD DATE:2011/02/01 AUTHOR:OUKOU CONTENT:E_本稼動_02856 END
       ,NVL( CEIL( SMFC.fc_qty_11th  / DECODE(NVL(ITEMB.attribute11,0),0,null,ITEMB.attribute11) ), 0 )      fc_cs_qty_11th      --販売計画ケース数_１１月
-- MOD DATE:2011/03/02 AUTHOR:HORIGOME CONTENT:E_本稼動_02856 END
       ,NVL( SMFC.fc_qty_11th  , 0 )                                  fc_qty_11th         --販売計画バラ数_１１月
       ,NVL( SMFC.fc_amt_11th  , 0 )                                  fc_amt_11th         --販売計画金額_１１月
       ,CASE WHEN NVL( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_11th, 0 ) <> 0 THEN  --ゼロ割り対策
                  NVL( ROUND( ( SMFC.fc_amt_11th / ( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_11th ) ) * 100, 2 ), 0 )
             ELSE 0
        END                                                           fc_rate_11th        --販売計画掛率_１１月
        --=====================
        --１２月
        --=====================
-- MOD DATE:2011/03/02 AUTHOR:HORIGOME CONTENT:E_本稼動_02856 START
-- MOD DATE:2011/02/01 AUTHOR:OUKOU CONTENT:E_本稼動_02856 START
--       ,NVL( TRUNC( SMFC.fc_qty_12th  / ITEM.num_of_cases ), 0 )      fc_cs_qty_12th      --販売計画ケース数_１２月
--       ,NVL( CEIL( SMFC.fc_qty_12th  / ITEM.num_of_cases ), 0 )      fc_cs_qty_12th      --販売計画ケース数_１２月
-- MOD DATE:2011/02/01 AUTHOR:OUKOU CONTENT:E_本稼動_02856 END
       ,NVL( CEIL( SMFC.fc_qty_12th  / DECODE(NVL(ITEMB.attribute11,0),0,null,ITEMB.attribute11) ), 0 )      fc_cs_qty_12th      --販売計画ケース数_１２月
-- MOD DATE:2011/03/02 AUTHOR:HORIGOME CONTENT:E_本稼動_02856 END
       ,NVL( SMFC.fc_qty_12th  , 0 )                                  fc_qty_12th         --販売計画バラ数_１２月
       ,NVL( SMFC.fc_amt_12th  , 0 )                                  fc_amt_12th         --販売計画金額_１２月
       ,CASE WHEN NVL( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_12th, 0 ) <> 0 THEN  --ゼロ割り対策
                  NVL( ROUND( ( SMFC.fc_amt_12th / ( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_12th ) ) * 100, 2 ), 0 )
             ELSE 0
        END                                                           fc_rate_12th        --販売計画掛率_１２月
        --=====================
        --１月
        --=====================
-- MOD DATE:2011/03/02 AUTHOR:HORIGOME CONTENT:E_本稼動_02856 START
-- MOD DATE:2011/02/01 AUTHOR:OUKOU CONTENT:E_本稼動_02856 START
--       ,NVL( TRUNC( SMFC.fc_qty_1th   / ITEM.num_of_cases ), 0 )      fc_cs_qty_1th       --販売計画ケース数_１月
--       ,NVL( CEIL( SMFC.fc_qty_1th   / ITEM.num_of_cases ), 0 )      fc_cs_qty_1th       --販売計画ケース数_１月
-- MOD DATE:2011/02/01 AUTHOR:OUKOU CONTENT:E_本稼動_02856 END
       ,NVL( CEIL( SMFC.fc_qty_1th   / DECODE(NVL(ITEMB.attribute11,0),0,null,ITEMB.attribute11) ), 0 )      fc_cs_qty_1th       --販売計画ケース数_１月
-- MOD DATE:2011/03/02 AUTHOR:HORIGOME CONTENT:E_本稼動_02856 END
       ,NVL( SMFC.fc_qty_1th   , 0 )                                  fc_qty_1th          --販売計画バラ数_１月
       ,NVL( SMFC.fc_amt_1th   , 0 )                                  fc_amt_1th          --販売計画金額_１月
       ,CASE WHEN NVL( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_1th , 0 ) <> 0 THEN  --ゼロ割り対策
                  NVL( ROUND( ( SMFC.fc_amt_1th  / ( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_1th  ) ) * 100, 2 ), 0 )
             ELSE 0
        END                                                           fc_rate_1th         --販売計画掛率_１月
        --=====================
        --２月
        --=====================
-- MOD DATE:2011/03/02 AUTHOR:HORIGOME CONTENT:E_本稼動_02856 START
-- MOD DATE:2011/02/01 AUTHOR:OUKOU CONTENT:E_本稼動_02856 START
--       ,NVL( TRUNC( SMFC.fc_qty_2th   / ITEM.num_of_cases ), 0 )      fc_cs_qty_2th       --販売計画ケース数_２月
--       ,NVL( CEIL( SMFC.fc_qty_2th   / ITEM.num_of_cases ), 0 )      fc_cs_qty_2th       --販売計画ケース数_２月
-- MOD DATE:2011/02/01 AUTHOR:OUKOU CONTENT:E_本稼動_02856 END
       ,NVL( CEIL( SMFC.fc_qty_2th   / DECODE(NVL(ITEMB.attribute11,0),0,null,ITEMB.attribute11) ), 0 )      fc_cs_qty_2th       --販売計画ケース数_２月
-- MOD DATE:2011/03/02 AUTHOR:HORIGOME CONTENT:E_本稼動_02856 END
       ,NVL( SMFC.fc_qty_2th   , 0 )                                  fc_qty_2th          --販売計画バラ数_２月
       ,NVL( SMFC.fc_amt_2th   , 0 )                                  fc_amt_2th          --販売計画金額_２月
       ,CASE WHEN NVL( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_2th , 0 ) <> 0 THEN  --ゼロ割り対策
                  NVL( ROUND( ( SMFC.fc_amt_2th  / ( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_2th  ) ) * 100, 2 ), 0 )
             ELSE 0
        END                                                           fc_rate_2th         --販売計画掛率_２月
        --=====================
        --３月
        --=====================
-- MOD DATE:2011/03/02 AUTHOR:HORIGOME CONTENT:E_本稼動_02856 START
-- MOD DATE:2011/02/01 AUTHOR:OUKOU CONTENT:E_本稼動_02856 START
--       ,NVL( TRUNC( SMFC.fc_qty_3th   / ITEM.num_of_cases ), 0 )      fc_cs_qty_3th       --販売計画ケース数_３月
--       ,NVL( CEIL( SMFC.fc_qty_3th   / ITEM.num_of_cases ), 0 )      fc_cs_qty_3th       --販売計画ケース数_３月
-- MOD DATE:2011/02/01 AUTHOR:OUKOU CONTENT:E_本稼動_02856 END
       ,NVL( CEIL( SMFC.fc_qty_3th   / DECODE(NVL(ITEMB.attribute11,0),0,null,ITEMB.attribute11) ), 0 )      fc_cs_qty_3th       --販売計画ケース数_３月
-- MOD DATE:2011/03/02 AUTHOR:HORIGOME CONTENT:E_本稼動_02856 END
       ,NVL( SMFC.fc_qty_3th   , 0 )                                  fc_qty_3th          --販売計画バラ数_３月
       ,NVL( SMFC.fc_amt_3th   , 0 )                                  fc_amt_3th          --販売計画金額_３月
       ,CASE WHEN NVL( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_3th , 0 ) <> 0 THEN  --ゼロ割り対策
                  NVL( ROUND( ( SMFC.fc_amt_3th  / ( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_3th  ) ) * 100, 2 ), 0 )
             ELSE 0
        END                                                           fc_rate_3th         --販売計画掛率_３月
        --=====================
        --４月
        --=====================
-- MOD DATE:2011/03/02 AUTHOR:HORIGOME CONTENT:E_本稼動_02856 START
-- MOD DATE:2011/02/01 AUTHOR:OUKOU CONTENT:E_本稼動_02856 START
--       ,NVL( TRUNC( SMFC.fc_qty_4th   / ITEM.num_of_cases ), 0 )      fc_cs_qty_4th       --販売計画ケース数_４月
--       ,NVL( CEIL( SMFC.fc_qty_4th   / ITEM.num_of_cases ), 0 )      fc_cs_qty_4th       --販売計画ケース数_４月
-- MOD DATE:2011/02/01 AUTHOR:OUKOU CONTENT:E_本稼動_02856 END
       ,NVL( CEIL( SMFC.fc_qty_4th   / DECODE(NVL(ITEMB.attribute11,0),0,null,ITEMB.attribute11) ), 0 )      fc_cs_qty_4th       --販売計画ケース数_４月
-- MOD DATE:2011/03/02 AUTHOR:HORIGOME CONTENT:E_本稼動_02856 END
       ,NVL( SMFC.fc_qty_4th   , 0 )                                  fc_qty_4th          --販売計画バラ数_４月
       ,NVL( SMFC.fc_amt_4th   , 0 )                                  fc_amt_4th          --販売計画金額_４月
       ,CASE WHEN NVL( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_4th , 0 ) <> 0 THEN  --ゼロ割り対策
                  NVL( ROUND( ( SMFC.fc_amt_4th  / ( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_4th  ) ) * 100, 2 ), 0 )
             ELSE 0
        END                                                           fc_rate_4th         --販売計画掛率_４月
  FROM
       ( --年月、世代、拠点、品目単位で集計した販売計画集計データ
          SELECT
                  ICD.fiscal_year                                     year                --年度
                 ,MFDN.attribute5                                     generation          --世代
                 -- 2009/05/12 T.Yoshimoto Mod Start 本番#1469
                 --,MFDN.attribute3                                     hs_branch           --拠点
                 ,MFDT.attribute5                                     hs_branch           --拠点
                 -- 2009/05/12 T.Yoshimoto Mod End 本番#1469
                 ,MFDT.inventory_item_id                              inv_item_id         --品目ID(INV品目ID)
                  --年間
                 ,SUM( MFDT.current_forecast_quantity )               sum_year_qty        --年間合計数量
                 ,SUM( TO_NUMBER( MFDT.attribute2 )   )               sum_year_amt        --年間合計金額
                  --５月
                 ,SUM( CASE WHEN ICD.period =  1 THEN MFDT.current_forecast_quantity END )  fc_qty_5th     --販売計画バラ数_５月
                 ,SUM( CASE WHEN ICD.period =  1 THEN TO_NUMBER( MFDT.attribute2 )   END )  fc_amt_5th     --販売計画金額_５月
                  --６月
                 ,SUM( CASE WHEN ICD.period =  2 THEN MFDT.current_forecast_quantity END )  fc_qty_6th     --販売計画バラ数_６月
                 ,SUM( CASE WHEN ICD.period =  2 THEN TO_NUMBER( MFDT.attribute2 )   END )  fc_amt_6th     --販売計画金額_６月
                  --７月
                 ,SUM( CASE WHEN ICD.period =  3 THEN MFDT.current_forecast_quantity END )  fc_qty_7th     --販売計画バラ数_７月
                 ,SUM( CASE WHEN ICD.period =  3 THEN TO_NUMBER( MFDT.attribute2 )   END )  fc_amt_7th     --販売計画金額_７月
                  --８月
                 ,SUM( CASE WHEN ICD.period =  4 THEN MFDT.current_forecast_quantity END )  fc_qty_8th     --販売計画バラ数_８月
                 ,SUM( CASE WHEN ICD.period =  4 THEN TO_NUMBER( MFDT.attribute2 )   END )  fc_amt_8th     --販売計画金額_８月
                  --９月
                 ,SUM( CASE WHEN ICD.period =  5 THEN MFDT.current_forecast_quantity END )  fc_qty_9th     --販売計画バラ数_９月
                 ,SUM( CASE WHEN ICD.period =  5 THEN TO_NUMBER( MFDT.attribute2 )   END )  fc_amt_9th     --販売計画金額_９月
                  --１０月
                 ,SUM( CASE WHEN ICD.period =  6 THEN MFDT.current_forecast_quantity END )  fc_qty_10th    --販売計画バラ数_１０月
                 ,SUM( CASE WHEN ICD.period =  6 THEN TO_NUMBER( MFDT.attribute2 )   END )  fc_amt_10th    --販売計画金額_１０月
                  --１１月
                 ,SUM( CASE WHEN ICD.period =  7 THEN MFDT.current_forecast_quantity END )  fc_qty_11th    --販売計画バラ数_１１月
                 ,SUM( CASE WHEN ICD.period =  7 THEN TO_NUMBER( MFDT.attribute2 )   END )  fc_amt_11th    --販売計画金額_１１月
                  --１２月
                 ,SUM( CASE WHEN ICD.period =  8 THEN MFDT.current_forecast_quantity END )  fc_qty_12th    --販売計画バラ数_１２月
                 ,SUM( CASE WHEN ICD.period =  8 THEN TO_NUMBER( MFDT.attribute2 )   END )  fc_amt_12th    --販売計画金額_１２月
                  --１月
                 ,SUM( CASE WHEN ICD.period =  9 THEN MFDT.current_forecast_quantity END )  fc_qty_1th     --販売計画バラ数_１月
                 ,SUM( CASE WHEN ICD.period =  9 THEN TO_NUMBER( MFDT.attribute2 )   END )  fc_amt_1th     --販売計画金額_１月
                  --２月
                 ,SUM( CASE WHEN ICD.period = 10 THEN MFDT.current_forecast_quantity END )  fc_qty_2th     --販売計画バラ数_２月
                 ,SUM( CASE WHEN ICD.period = 10 THEN TO_NUMBER( MFDT.attribute2 )   END )  fc_amt_2th     --販売計画金額_２月
                  --３月
                 ,SUM( CASE WHEN ICD.period = 11 THEN MFDT.current_forecast_quantity END )  fc_qty_3th     --販売計画バラ数_３月
                 ,SUM( CASE WHEN ICD.period = 11 THEN TO_NUMBER( MFDT.attribute2 )   END )  fc_amt_3th     --販売計画金額_３月
                  --４月
                 ,SUM( CASE WHEN ICD.period = 12 THEN MFDT.current_forecast_quantity END )  fc_qty_4th     --販売計画バラ数_４月
                 ,SUM( CASE WHEN ICD.period = 12 THEN TO_NUMBER( MFDT.attribute2 )   END )  fc_amt_4th     --販売計画金額_４月
            FROM
                  ic_cldr_dtl                               ICD                 --在庫カレンダ
                 ,mrp_forecast_designators                  MFDN                --フォーキャスト名テーブル
                 ,mrp_forecast_dates                        MFDT                --フォーキャスト日付テーブル
           WHERE
             --販売計画データ取得条件
                  MFDN.attribute1                           = '05'              --05:販売計画
             AND (    MFDT.current_forecast_quantity       <> 0
                   OR TO_NUMBER( MFDT.attribute2 )         <> 0
                 )
             AND  MFDN.organization_id                      = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
             AND  MFDN.forecast_designator                  = MFDT.forecast_designator
             AND  MFDN.organization_id                      = MFDT.organization_id
             --在庫カレンダとの結合条件
             AND  ICD.orgn_code = 'ITOE'
             AND  TO_CHAR( MFDT.forecast_date, 'YYYYMM' )   = TO_CHAR( ICD.period_end_date, 'YYYYMM' )
          GROUP BY
                  ICD.fiscal_year                           --年度
                 ,MFDN.attribute5                           --世代
                 -- 2009/05/12 T.Yoshimoto Mod Start 本番#1469
                 --,MFDN.attribute3                           --拠点
                 ,MFDT.attribute5                           --拠点
                 -- 2009/05/12 T.Yoshimoto Mod End 本番#1469
                 ,MFDT.inventory_item_id                    --品目ID(INV品目ID)
       )                           SMFC                     --販売計画集計
       ,xxskz_cust_accounts_v      BRCH                     --拠点名取得用（SYSDATEで有効データを抽出）
       ,xxskz_item_mst_v           ITEM                     --品目名取得用（SYSDATEで有効データを抽出）
       ,xxskz_prod_class_v         PRODC                    --商品区分取得用
       ,xxskz_item_class_v         ITEMC                    --品目区分取得用
       ,xxskz_crowd_code_v         CROWD                    --群コード取得用
       ,ic_item_mst_b              ITEMB                    --品目別定価取得用
 WHERE
   --拠点名取得（SYSDATEで有効データを抽出）
        SMFC.hs_branch             = BRCH.party_number(+)
   --品目情報取得（SYSDATEで有効データを抽出）
   AND  SMFC.inv_item_id           = ITEM.inventory_item_id(+)
   --品目カテゴリ情報取得
   AND  ITEM.item_id               = PRODC.item_id(+)       --商品区分
   AND  ITEM.item_id               = ITEMC.item_id(+)       --品目区分
   AND  ITEM.item_id               = CROWD.item_id(+)       --群コード
   --品目別定価取得
   AND  ITEM.item_id               = ITEMB.item_id(+)
/
COMMENT ON TABLE APPS.XXSKZ_販売計画時系列_基本_V IS 'XXSKZ_販売計画時系列 (基本) VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_販売計画時系列_基本_V.年度                    IS '年度'
/
COMMENT ON COLUMN APPS.XXSKZ_販売計画時系列_基本_V.世代                    IS '世代'
/
COMMENT ON COLUMN APPS.XXSKZ_販売計画時系列_基本_V.拠点コード              IS '拠点コード'
/
COMMENT ON COLUMN APPS.XXSKZ_販売計画時系列_基本_V.拠点名                  IS '拠点名'
/
COMMENT ON COLUMN APPS.XXSKZ_販売計画時系列_基本_V.商品区分                IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKZ_販売計画時系列_基本_V.商品区分名              IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_販売計画時系列_基本_V.品目区分                IS '品目区分'
/
COMMENT ON COLUMN APPS.XXSKZ_販売計画時系列_基本_V.品目区分名              IS '品目区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_販売計画時系列_基本_V.群コード                IS '群コード'
/
COMMENT ON COLUMN APPS.XXSKZ_販売計画時系列_基本_V.品目コード              IS '品目コード'
/
COMMENT ON COLUMN APPS.XXSKZ_販売計画時系列_基本_V.品目名                  IS '品目名'
/
COMMENT ON COLUMN APPS.XXSKZ_販売計画時系列_基本_V.品目略称                IS '品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_販売計画時系列_基本_V.年間合計ケース数        IS '年間合計ケース数'
/
COMMENT ON COLUMN APPS.XXSKZ_販売計画時系列_基本_V.年間合計バラ数          IS '年間合計バラ数'
/
COMMENT ON COLUMN APPS.XXSKZ_販売計画時系列_基本_V.年間合計金額            IS '年間合計金額'
/
COMMENT ON COLUMN APPS.XXSKZ_販売計画時系列_基本_V.年間掛率                IS '年間掛率'
/
COMMENT ON COLUMN APPS.XXSKZ_販売計画時系列_基本_V.販売計画ケース数_５月   IS '販売計画ケース数_５月'
/
COMMENT ON COLUMN APPS.XXSKZ_販売計画時系列_基本_V.販売計画バラ数_５月     IS '販売計画バラ数_５月'
/
COMMENT ON COLUMN APPS.XXSKZ_販売計画時系列_基本_V.販売計画金額_５月       IS '販売計画金額_５月'
/
COMMENT ON COLUMN APPS.XXSKZ_販売計画時系列_基本_V.販売計画掛率_５月       IS '販売計画掛率_５月'
/
COMMENT ON COLUMN APPS.XXSKZ_販売計画時系列_基本_V.販売計画ケース数_６月   IS '販売計画ケース数_６月'
/
COMMENT ON COLUMN APPS.XXSKZ_販売計画時系列_基本_V.販売計画バラ数_６月     IS '販売計画バラ数_６月'
/
COMMENT ON COLUMN APPS.XXSKZ_販売計画時系列_基本_V.販売計画金額_６月       IS '販売計画金額_６月'
/
COMMENT ON COLUMN APPS.XXSKZ_販売計画時系列_基本_V.販売計画掛率_６月       IS '販売計画掛率_６月'
/
COMMENT ON COLUMN APPS.XXSKZ_販売計画時系列_基本_V.販売計画ケース数_７月   IS '販売計画ケース数_７月'
/
COMMENT ON COLUMN APPS.XXSKZ_販売計画時系列_基本_V.販売計画バラ数_７月     IS '販売計画バラ数_７月'
/
COMMENT ON COLUMN APPS.XXSKZ_販売計画時系列_基本_V.販売計画金額_７月       IS '販売計画金額_７月'
/
COMMENT ON COLUMN APPS.XXSKZ_販売計画時系列_基本_V.販売計画掛率_７月       IS '販売計画掛率_７月'
/
COMMENT ON COLUMN APPS.XXSKZ_販売計画時系列_基本_V.販売計画ケース数_８月   IS '販売計画ケース数_８月'
/
COMMENT ON COLUMN APPS.XXSKZ_販売計画時系列_基本_V.販売計画バラ数_８月     IS '販売計画バラ数_８月'
/
COMMENT ON COLUMN APPS.XXSKZ_販売計画時系列_基本_V.販売計画金額_８月       IS '販売計画金額_８月'
/
COMMENT ON COLUMN APPS.XXSKZ_販売計画時系列_基本_V.販売計画掛率_８月       IS '販売計画掛率_８月'
/
COMMENT ON COLUMN APPS.XXSKZ_販売計画時系列_基本_V.販売計画ケース数_９月   IS '販売計画ケース数_９月'
/
COMMENT ON COLUMN APPS.XXSKZ_販売計画時系列_基本_V.販売計画バラ数_９月     IS '販売計画バラ数_９月'
/
COMMENT ON COLUMN APPS.XXSKZ_販売計画時系列_基本_V.販売計画金額_９月       IS '販売計画金額_９月'
/
COMMENT ON COLUMN APPS.XXSKZ_販売計画時系列_基本_V.販売計画掛率_９月       IS '販売計画掛率_９月'
/
COMMENT ON COLUMN APPS.XXSKZ_販売計画時系列_基本_V.販売計画ケース数_１０月 IS '販売計画ケース数_１０月'
/
COMMENT ON COLUMN APPS.XXSKZ_販売計画時系列_基本_V.販売計画バラ数_１０月   IS '販売計画バラ数_１０月'
/
COMMENT ON COLUMN APPS.XXSKZ_販売計画時系列_基本_V.販売計画金額_１０月     IS '販売計画金額_１０月'
/
COMMENT ON COLUMN APPS.XXSKZ_販売計画時系列_基本_V.販売計画掛率_１０月     IS '販売計画掛率_１０月'
/
COMMENT ON COLUMN APPS.XXSKZ_販売計画時系列_基本_V.販売計画ケース数_１１月 IS '販売計画ケース数_１１月'
/
COMMENT ON COLUMN APPS.XXSKZ_販売計画時系列_基本_V.販売計画バラ数_１１月   IS '販売計画バラ数_１１月'
/
COMMENT ON COLUMN APPS.XXSKZ_販売計画時系列_基本_V.販売計画金額_１１月     IS '販売計画金額_１１月'
/
COMMENT ON COLUMN APPS.XXSKZ_販売計画時系列_基本_V.販売計画掛率_１１月     IS '販売計画掛率_１１月'
/
COMMENT ON COLUMN APPS.XXSKZ_販売計画時系列_基本_V.販売計画ケース数_１２月 IS '販売計画ケース数_１２月'
/
COMMENT ON COLUMN APPS.XXSKZ_販売計画時系列_基本_V.販売計画バラ数_１２月   IS '販売計画バラ数_１２月'
/
COMMENT ON COLUMN APPS.XXSKZ_販売計画時系列_基本_V.販売計画金額_１２月     IS '販売計画金額_１２月'
/
COMMENT ON COLUMN APPS.XXSKZ_販売計画時系列_基本_V.販売計画掛率_１２月     IS '販売計画掛率_１２月'
/
COMMENT ON COLUMN APPS.XXSKZ_販売計画時系列_基本_V.販売計画ケース数_１月   IS '販売計画ケース数_１月'
/
COMMENT ON COLUMN APPS.XXSKZ_販売計画時系列_基本_V.販売計画バラ数_１月     IS '販売計画バラ数_１月'
/
COMMENT ON COLUMN APPS.XXSKZ_販売計画時系列_基本_V.販売計画金額_１月       IS '販売計画金額_１月'
/
COMMENT ON COLUMN APPS.XXSKZ_販売計画時系列_基本_V.販売計画掛率_１月       IS '販売計画掛率_１月'
/
COMMENT ON COLUMN APPS.XXSKZ_販売計画時系列_基本_V.販売計画ケース数_２月   IS '販売計画ケース数_２月'
/
COMMENT ON COLUMN APPS.XXSKZ_販売計画時系列_基本_V.販売計画バラ数_２月     IS '販売計画バラ数_２月'
/
COMMENT ON COLUMN APPS.XXSKZ_販売計画時系列_基本_V.販売計画金額_２月       IS '販売計画金額_２月'
/
COMMENT ON COLUMN APPS.XXSKZ_販売計画時系列_基本_V.販売計画掛率_２月       IS '販売計画掛率_２月'
/
COMMENT ON COLUMN APPS.XXSKZ_販売計画時系列_基本_V.販売計画ケース数_３月   IS '販売計画ケース数_３月'
/
COMMENT ON COLUMN APPS.XXSKZ_販売計画時系列_基本_V.販売計画バラ数_３月     IS '販売計画バラ数_３月'
/
COMMENT ON COLUMN APPS.XXSKZ_販売計画時系列_基本_V.販売計画金額_３月       IS '販売計画金額_３月'
/
COMMENT ON COLUMN APPS.XXSKZ_販売計画時系列_基本_V.販売計画掛率_３月       IS '販売計画掛率_３月'
/
COMMENT ON COLUMN APPS.XXSKZ_販売計画時系列_基本_V.販売計画ケース数_４月   IS '販売計画ケース数_４月'
/
COMMENT ON COLUMN APPS.XXSKZ_販売計画時系列_基本_V.販売計画バラ数_４月     IS '販売計画バラ数_４月'
/
COMMENT ON COLUMN APPS.XXSKZ_販売計画時系列_基本_V.販売計画金額_４月       IS '販売計画金額_４月'
/
COMMENT ON COLUMN APPS.XXSKZ_販売計画時系列_基本_V.販売計画掛率_４月       IS '販売計画掛率_４月'
/
