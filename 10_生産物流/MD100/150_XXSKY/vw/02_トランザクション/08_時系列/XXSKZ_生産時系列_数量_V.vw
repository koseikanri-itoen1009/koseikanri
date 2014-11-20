/*************************************************************************
 * 
 * View  Name      : XXSKZ_生産時系列_数量_V
 * Description     : XXSKZ_生産時系列_数量_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/26    1.0   SCSK M.Nagai 初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_生産時系列_数量_V
(
 年度
,成績管理部署
,商品区分
,商品区分名
,品目区分
,品目区分名
,群コード
,品目コード
,品目名
,品目略称
,伝票区分
,工順
,工順名称
,工順摘要
,投入数量_５月
,副産物数量_５月
,打込数量_５月
,出来高数量_５月
,資材数量_５月
,業者不良数量_５月
,製造不良数量_５月
,投入数量_６月
,副産物数量_６月
,打込数量_６月
,出来高数量_６月
,資材数量_６月
,業者不良数量_６月
,製造不良数量_６月
,投入数量_７月
,副産物数量_７月
,打込数量_７月
,出来高数量_７月
,資材数量_７月
,業者不良数量_７月
,製造不良数量_７月
,投入数量_８月
,副産物数量_８月
,打込数量_８月
,出来高数量_８月
,資材数量_８月
,業者不良数量_８月
,製造不良数量_８月
,投入数量_９月
,副産物数量_９月
,打込数量_９月
,出来高数量_９月
,資材数量_９月
,業者不良数量_９月
,製造不良数量_９月
,投入数量_１０月
,副産物数量_１０月
,打込数量_１０月
,出来高数量_１０月
,資材数量_１０月
,業者不良数量_１０月
,製造不良数量_１０月
,投入数量_１１月
,副産物数量_１１月
,打込数量_１１月
,出来高数量_１１月
,資材数量_１１月
,業者不良数量_１１月
,製造不良数量_１１月
,投入数量_１２月
,副産物数量_１２月
,打込数量_１２月
,出来高数量_１２月
,資材数量_１２月
,業者不良数量_１２月
,製造不良数量_１２月
,投入数量_１月
,副産物数量_１月
,打込数量_１月
,出来高数量_１月
,資材数量_１月
,業者不良数量_１月
,製造不良数量_１月
,投入数量_２月
,副産物数量_２月
,打込数量_２月
,出来高数量_２月
,資材数量_２月
,業者不良数量_２月
,製造不良数量_２月
,投入数量_３月
,副産物数量_３月
,打込数量_３月
,出来高数量_３月
,資材数量_３月
,業者不良数量_３月
,製造不良数量_３月
,投入数量_４月
,副産物数量_４月
,打込数量_４月
,出来高数量_４月
,資材数量_４月
,業者不良数量_４月
,製造不良数量_４月
)
AS
SELECT  SMMR.year                          year               --年度
       ,SMMR.pm_dept                       pm_dept            --成績管理部署
       ,PRODC.prod_class_code              prod_class_code    --商品区分
       ,PRODC.prod_class_name              prod_class_name    --商品区分名
       ,ITEMC.item_class_code              item_class_code    --品目区分
       ,ITEMC.item_class_name              item_class_name    --品目区分名
       ,CROWD.crowd_code                   crowd_code         --群コード
       ,ITEM.item_no                       item_code          --品目コード
       ,ITEM.item_name                     item_name          --品目名
       ,ITEM.item_short_name               item_s_name        --品目略称
       ,SMMR.slip_cls                      slip_cls           --伝票区分
       ,SMMR.rtng_no                       rtng_no            --工順
       ,GRTT.routing_desc                  rtng_name          --工順名称
       ,GRTT.routing_desc                  rtng_desc          --工順摘要
        --５月
       ,NVL( SMMR.invest_qty_5th  , 0 )    invest_qty_5th     --投入数量_５月
       ,NVL( SMMR.product_qty_5th , 0 )    product_qty_5th    --副産物数量_５月
       ,NVL( SMMR.into_qty_5th    , 0 )    into_qty_5th       --打込数量_５月
       ,NVL( SMMR.output_qty_5th  , 0 )    output_qty_5th     --出来高数量_５月
       ,NVL( SMMR.mtrl_qty_5th    , 0 )    mtrl_qty_5th       --資材数量_５月
       ,NVL( SMMR.mfg_qty_5th     , 0 )    mfg_qty_5th        --業者不良数量_５月
       ,NVL( SMMR.prod_qty_5th    , 0 )    prod_qty_5th       --製造不良数量_５月
        --６月
       ,NVL( SMMR.invest_qty_6th  , 0 )    invest_qty_6th     --投入数量_６月
       ,NVL( SMMR.product_qty_6th , 0 )    product_qty_6th    --副産物数量_６月
       ,NVL( SMMR.into_qty_6th    , 0 )    into_qty_6th       --打込数量_６月
       ,NVL( SMMR.output_qty_6th  , 0 )    output_qty_6th     --出来高数量_６月
       ,NVL( SMMR.mtrl_qty_6th    , 0 )    mtrl_qty_6th       --資材数量_６月
       ,NVL( SMMR.mfg_qty_6th     , 0 )    mfg_qty_6th        --業者不良数量_６月
       ,NVL( SMMR.prod_qty_6th    , 0 )    prod_qty_6th       --製造不良数量_６月
        --７月
       ,NVL( SMMR.invest_qty_7th  , 0 )    invest_qty_7th     --投入数量_７月
       ,NVL( SMMR.product_qty_7th , 0 )    product_qty_7th    --副産物数量_７月
       ,NVL( SMMR.into_qty_7th    , 0 )    into_qty_7th       --打込数量_７月
       ,NVL( SMMR.output_qty_7th  , 0 )    output_qty_7th     --出来高数量_７月
       ,NVL( SMMR.mtrl_qty_7th    , 0 )    mtrl_qty_7th       --資材数量_７月
       ,NVL( SMMR.mfg_qty_7th     , 0 )    mfg_qty_7th        --業者不良数量_７月
       ,NVL( SMMR.prod_qty_7th    , 0 )    prod_qty_7th       --製造不良数量_７月
        --８月
       ,NVL( SMMR.invest_qty_8th  , 0 )    invest_qty_8th     --投入数量_８月
       ,NVL( SMMR.product_qty_8th , 0 )    product_qty_8th    --副産物数量_８月
       ,NVL( SMMR.into_qty_8th    , 0 )    into_qty_8th       --打込数量_８月
       ,NVL( SMMR.output_qty_8th  , 0 )    output_qty_8th     --出来高数量_８月
       ,NVL( SMMR.mtrl_qty_8th    , 0 )    mtrl_qty_8th       --資材数量_８月
       ,NVL( SMMR.mfg_qty_8th     , 0 )    mfg_qty_8th        --業者不良数量_８月
       ,NVL( SMMR.prod_qty_8th    , 0 )    prod_qty_8th       --製造不良数量_８月
        --９月
       ,NVL( SMMR.invest_qty_9th  , 0 )    invest_qty_9th     --投入数量_９月
       ,NVL( SMMR.product_qty_9th , 0 )    product_qty_9th    --副産物数量_９月
       ,NVL( SMMR.into_qty_9th    , 0 )    into_qty_9th       --打込数量_９月
       ,NVL( SMMR.output_qty_9th  , 0 )    output_qty_9th     --出来高数量_９月
       ,NVL( SMMR.mtrl_qty_9th    , 0 )    mtrl_qty_9th       --資材数量_９月
       ,NVL( SMMR.mfg_qty_9th     , 0 )    mfg_qty_9th        --業者不良数量_９月
       ,NVL( SMMR.prod_qty_9th    , 0 )    prod_qty_9th       --製造不良数量_９月
        --１０月
       ,NVL( SMMR.invest_qty_10th , 0 )    invest_qty_10th    --投入数量_１０月
       ,NVL( SMMR.product_qty_10th, 0 )    product_qty_10th   --副産物数量_１０月
       ,NVL( SMMR.into_qty_10th   , 0 )    into_qty_10th      --打込数量_１０月
       ,NVL( SMMR.output_qty_10th , 0 )    output_qty_10th    --出来高数量_１０月
       ,NVL( SMMR.mtrl_qty_10th   , 0 )    mtrl_qty_10th      --資材数量_１０月
       ,NVL( SMMR.mfg_qty_10th    , 0 )    mfg_qty_10th       --業者不良数量_１０月
       ,NVL( SMMR.prod_qty_10th   , 0 )    prod_qty_10th      --製造不良数量_１０月
        --１１月
       ,NVL( SMMR.invest_qty_11th , 0 )    invest_qty_11th    --投入数量_１１月
       ,NVL( SMMR.product_qty_11th, 0 )    product_qty_11th   --副産物数量_１１月
       ,NVL( SMMR.into_qty_11th   , 0 )    into_qty_11th      --打込数量_１１月
       ,NVL( SMMR.output_qty_11th , 0 )    output_qty_11th    --出来高数量_１１月
       ,NVL( SMMR.mtrl_qty_11th   , 0 )    mtrl_qty_11th      --資材数量_１１月
       ,NVL( SMMR.mfg_qty_11th    , 0 )    mfg_qty_11th       --業者不良数量_１１月
       ,NVL( SMMR.prod_qty_11th   , 0 )    prod_qty_11th      --製造不良数量_１１月
        --１２月
       ,NVL( SMMR.invest_qty_12th , 0 )    invest_qty_12th    --投入数量_１２月
       ,NVL( SMMR.product_qty_12th, 0 )    product_qty_12th   --副産物数量_１２月
       ,NVL( SMMR.into_qty_12th   , 0 )    into_qty_12th      --打込数量_１２月
       ,NVL( SMMR.output_qty_12th , 0 )    output_qty_12th    --出来高数量_１２月
       ,NVL( SMMR.mtrl_qty_12th   , 0 )    mtrl_qty_12th      --資材数量_１２月
       ,NVL( SMMR.mfg_qty_12th    , 0 )    mfg_qty_12th       --業者不良数量_１２月
       ,NVL( SMMR.prod_qty_12th   , 0 )    prod_qty_12th      --製造不良数量_１２月
        --１月
       ,NVL( SMMR.invest_qty_1th  , 0 )    invest_qty_1th     --投入数量_１月
       ,NVL( SMMR.product_qty_1th , 0 )    product_qty_1th    --副産物数量_１月
       ,NVL( SMMR.into_qty_1th    , 0 )    into_qty_1th       --打込数量_１月
       ,NVL( SMMR.output_qty_1th  , 0 )    output_qty_1th     --出来高数量_１月
       ,NVL( SMMR.mtrl_qty_1th    , 0 )    mtrl_qty_1th       --資材数量_１月
       ,NVL( SMMR.mfg_qty_1th     , 0 )    mfg_qty_1th        --業者不良数量_１月
       ,NVL( SMMR.prod_qty_1th    , 0 )    prod_qty_1th       --製造不良数量_１月
        --２月
       ,NVL( SMMR.invest_qty_2th  , 0 )    invest_qty_2th     --投入数量_２月
       ,NVL( SMMR.product_qty_2th , 0 )    product_qty_2th    --副産物数量_２月
       ,NVL( SMMR.into_qty_2th    , 0 )    into_qty_2th       --打込数量_２月
       ,NVL( SMMR.output_qty_2th  , 0 )    output_qty_2th     --出来高数量_２月
       ,NVL( SMMR.mtrl_qty_2th    , 0 )    mtrl_qty_2th       --資材数量_２月
       ,NVL( SMMR.mfg_qty_2th     , 0 )    mfg_qty_2th        --業者不良数量_２月
       ,NVL( SMMR.prod_qty_2th    , 0 )    prod_qty_2th       --製造不良数量_２月
        --３月
       ,NVL( SMMR.invest_qty_3th  , 0 )    invest_qty_3th     --投入数量_３月
       ,NVL( SMMR.product_qty_3th , 0 )    product_qty_3th    --副産物数量_３月
       ,NVL( SMMR.into_qty_3th    , 0 )    into_qty_3th       --打込数量_３月
       ,NVL( SMMR.output_qty_3th  , 0 )    output_qty_3th     --出来高数量_３月
       ,NVL( SMMR.mtrl_qty_3th    , 0 )    mtrl_qty_3th       --資材数量_３月
       ,NVL( SMMR.mfg_qty_3th     , 0 )    mfg_qty_3th        --業者不良数量_３月
       ,NVL( SMMR.prod_qty_3th    , 0 )    prod_qty_3th       --製造不良数量_３月
        --４月
       ,NVL( SMMR.invest_qty_4th  , 0 )    invest_qty_4th     --投入数量_４月
       ,NVL( SMMR.product_qty_4th , 0 )    product_qty_4th    --副産物数量_４月
       ,NVL( SMMR.into_qty_4th    , 0 )    into_qty_4th       --打込数量_４月
       ,NVL( SMMR.output_qty_4th  , 0 )    output_qty_4th     --出来高数量_４月
       ,NVL( SMMR.mtrl_qty_4th    , 0 )    mtrl_qty_4th       --資材数量_４月
       ,NVL( SMMR.mfg_qty_4th     , 0 )    mfg_qty_4th        --業者不良数量_４月
       ,NVL( SMMR.prod_qty_4th    , 0 )    prod_qty_4th       --製造不良数量_４月
  FROM  (  --年度、部署、伝票区分、工順番号、完成品_品目の単位で集計したデータ
           SELECT  ICD.fiscal_year    year          --年度(実績完了日を変換)
                  ,MTRL.pm_dept       pm_dept       --成績管理部署
                  ,MTRL.slip_cls      slip_cls      --伝票区分
                  ,MTRL.rtng_id       rtng_id       --工順ID
                  ,MTRL.rtng_no       rtng_no       --工順番号
                  ,MTRL.cp_item_id    cp_item_id    --完成品_品目ID
                   --５月
                  ,SUM( CASE WHEN ICD.period =  1 THEN MTRL.invest_qty  END ) invest_qty_5th    --投入数量_５月
                  ,SUM( CASE WHEN ICD.period =  1 THEN MTRL.product_qty END ) product_qty_5th   --副産物数量_５月
                  ,SUM( CASE WHEN ICD.period =  1 THEN MTRL.into_qty    END ) into_qty_5th      --打込数量_５月
                  ,SUM( CASE WHEN ICD.period =  1 THEN MTRL.output_qty  END ) output_qty_5th    --出来高数量_５月
                  ,SUM( CASE WHEN ICD.period =  1 THEN MTRL.mtrl_qty    END ) mtrl_qty_5th      --資材数量_５月
                  ,SUM( CASE WHEN ICD.period =  1 THEN MTRL.mfg_qty     END ) mfg_qty_5th       --業者不良数量_５月
                  ,SUM( CASE WHEN ICD.period =  1 THEN MTRL.prod_qty    END ) prod_qty_5th      --製造不良数量_５月
                   --６月
                  ,SUM( CASE WHEN ICD.period =  2 THEN MTRL.invest_qty  END ) invest_qty_6th    --投入数量_６月
                  ,SUM( CASE WHEN ICD.period =  2 THEN MTRL.product_qty END ) product_qty_6th   --副産物数量_６月
                  ,SUM( CASE WHEN ICD.period =  2 THEN MTRL.into_qty    END ) into_qty_6th      --打込数量_６月
                  ,SUM( CASE WHEN ICD.period =  2 THEN MTRL.output_qty  END ) output_qty_6th    --出来高数量_６月
                  ,SUM( CASE WHEN ICD.period =  2 THEN MTRL.mtrl_qty    END ) mtrl_qty_6th      --資材数量_６月
                  ,SUM( CASE WHEN ICD.period =  2 THEN MTRL.mfg_qty     END ) mfg_qty_6th       --業者不良数量_６月
                  ,SUM( CASE WHEN ICD.period =  2 THEN MTRL.prod_qty    END ) prod_qty_6th      --製造不良数量_６月
                   --７月
                  ,SUM( CASE WHEN ICD.period =  3 THEN MTRL.invest_qty  END ) invest_qty_7th    --投入数量_７月
                  ,SUM( CASE WHEN ICD.period =  3 THEN MTRL.product_qty END ) product_qty_7th   --副産物数量_７月
                  ,SUM( CASE WHEN ICD.period =  3 THEN MTRL.into_qty    END ) into_qty_7th      --打込数量_７月
                  ,SUM( CASE WHEN ICD.period =  3 THEN MTRL.output_qty  END ) output_qty_7th    --出来高数量_７月
                  ,SUM( CASE WHEN ICD.period =  3 THEN MTRL.mtrl_qty    END ) mtrl_qty_7th      --資材数量_７月
                  ,SUM( CASE WHEN ICD.period =  3 THEN MTRL.mfg_qty     END ) mfg_qty_7th       --業者不良数量_７月
                  ,SUM( CASE WHEN ICD.period =  3 THEN MTRL.prod_qty    END ) prod_qty_7th      --製造不良数量_７月
                   --８月
                  ,SUM( CASE WHEN ICD.period =  4 THEN MTRL.invest_qty  END ) invest_qty_8th    --投入数量_８月
                  ,SUM( CASE WHEN ICD.period =  4 THEN MTRL.product_qty END ) product_qty_8th   --副産物数量_８月
                  ,SUM( CASE WHEN ICD.period =  4 THEN MTRL.into_qty    END ) into_qty_8th      --打込数量_８月
                  ,SUM( CASE WHEN ICD.period =  4 THEN MTRL.output_qty  END ) output_qty_8th    --出来高数量_８月
                  ,SUM( CASE WHEN ICD.period =  4 THEN MTRL.mtrl_qty    END ) mtrl_qty_8th      --資材数量_８月
                  ,SUM( CASE WHEN ICD.period =  4 THEN MTRL.mfg_qty     END ) mfg_qty_8th       --業者不良数量_８月
                  ,SUM( CASE WHEN ICD.period =  4 THEN MTRL.prod_qty    END ) prod_qty_8th      --製造不良数量_８月
                   --９月
                  ,SUM( CASE WHEN ICD.period =  5 THEN MTRL.invest_qty  END ) invest_qty_9th    --投入数量_９月
                  ,SUM( CASE WHEN ICD.period =  5 THEN MTRL.product_qty END ) product_qty_9th   --副産物数量_９月
                  ,SUM( CASE WHEN ICD.period =  5 THEN MTRL.into_qty    END ) into_qty_9th      --打込数量_９月
                  ,SUM( CASE WHEN ICD.period =  5 THEN MTRL.output_qty  END ) output_qty_9th    --出来高数量_９月
                  ,SUM( CASE WHEN ICD.period =  5 THEN MTRL.mtrl_qty    END ) mtrl_qty_9th      --資材数量_９月
                  ,SUM( CASE WHEN ICD.period =  5 THEN MTRL.mfg_qty     END ) mfg_qty_9th       --業者不良数量_９月
                  ,SUM( CASE WHEN ICD.period =  5 THEN MTRL.prod_qty    END ) prod_qty_9th      --製造不良数量_９月
                   --１０月
                  ,SUM( CASE WHEN ICD.period =  6 THEN MTRL.invest_qty  END ) invest_qty_10th   --投入数量_１０月
                  ,SUM( CASE WHEN ICD.period =  6 THEN MTRL.product_qty END ) product_qty_10th  --副産物数量_１０月
                  ,SUM( CASE WHEN ICD.period =  6 THEN MTRL.into_qty    END ) into_qty_10th     --打込数量_１０月
                  ,SUM( CASE WHEN ICD.period =  6 THEN MTRL.output_qty  END ) output_qty_10th   --出来高数量_１０月
                  ,SUM( CASE WHEN ICD.period =  6 THEN MTRL.mtrl_qty    END ) mtrl_qty_10th     --資材数量_１０月
                  ,SUM( CASE WHEN ICD.period =  6 THEN MTRL.mfg_qty     END ) mfg_qty_10th      --業者不良数量_１０月
                  ,SUM( CASE WHEN ICD.period =  6 THEN MTRL.prod_qty    END ) prod_qty_10th     --製造不良数量_１０月
                   --１１月
                  ,SUM( CASE WHEN ICD.period =  7 THEN MTRL.invest_qty  END ) invest_qty_11th   --投入数量_１１月
                  ,SUM( CASE WHEN ICD.period =  7 THEN MTRL.product_qty END ) product_qty_11th  --副産物数量_１１月
                  ,SUM( CASE WHEN ICD.period =  7 THEN MTRL.into_qty    END ) into_qty_11th     --打込数量_１１月
                  ,SUM( CASE WHEN ICD.period =  7 THEN MTRL.output_qty  END ) output_qty_11th   --出来高数量_１１月
                  ,SUM( CASE WHEN ICD.period =  7 THEN MTRL.mtrl_qty    END ) mtrl_qty_11th     --資材数量_１１月
                  ,SUM( CASE WHEN ICD.period =  7 THEN MTRL.mfg_qty     END ) mfg_qty_11th      --業者不良数量_１１月
                  ,SUM( CASE WHEN ICD.period =  7 THEN MTRL.prod_qty    END ) prod_qty_11th     --製造不良数量_１１月
                   --１２月
                  ,SUM( CASE WHEN ICD.period =  8 THEN MTRL.invest_qty  END ) invest_qty_12th   --投入数量_１２月
                  ,SUM( CASE WHEN ICD.period =  8 THEN MTRL.product_qty END ) product_qty_12th  --副産物数量_１２月
                  ,SUM( CASE WHEN ICD.period =  8 THEN MTRL.into_qty    END ) into_qty_12th     --打込数量_１２月
                  ,SUM( CASE WHEN ICD.period =  8 THEN MTRL.output_qty  END ) output_qty_12th   --出来高数量_１２月
                  ,SUM( CASE WHEN ICD.period =  8 THEN MTRL.mtrl_qty    END ) mtrl_qty_12th     --資材数量_１２月
                  ,SUM( CASE WHEN ICD.period =  8 THEN MTRL.mfg_qty     END ) mfg_qty_12th      --業者不良数量_１２月
                  ,SUM( CASE WHEN ICD.period =  8 THEN MTRL.prod_qty    END ) prod_qty_12th     --製造不良数量_１２月
                   --１月
                  ,SUM( CASE WHEN ICD.period =  9 THEN MTRL.invest_qty  END ) invest_qty_1th    --投入数量_１月
                  ,SUM( CASE WHEN ICD.period =  9 THEN MTRL.product_qty END ) product_qty_1th   --副産物数量_１月
                  ,SUM( CASE WHEN ICD.period =  9 THEN MTRL.into_qty    END ) into_qty_1th      --打込数量_１月
                  ,SUM( CASE WHEN ICD.period =  9 THEN MTRL.output_qty  END ) output_qty_1th    --出来高数量_１月
                  ,SUM( CASE WHEN ICD.period =  9 THEN MTRL.mtrl_qty    END ) mtrl_qty_1th      --資材数量_１月
                  ,SUM( CASE WHEN ICD.period =  9 THEN MTRL.mfg_qty     END ) mfg_qty_1th       --業者不良数量_１月
                  ,SUM( CASE WHEN ICD.period =  9 THEN MTRL.prod_qty    END ) prod_qty_1th      --製造不良数量_１月
                   --２月
                  ,SUM( CASE WHEN ICD.period = 10 THEN MTRL.invest_qty  END ) invest_qty_2th    --投入数量_２月
                  ,SUM( CASE WHEN ICD.period = 10 THEN MTRL.product_qty END ) product_qty_2th   --副産物数量_２月
                  ,SUM( CASE WHEN ICD.period = 10 THEN MTRL.into_qty    END ) into_qty_2th      --打込数量_２月
                  ,SUM( CASE WHEN ICD.period = 10 THEN MTRL.output_qty  END ) output_qty_2th    --出来高数量_２月
                  ,SUM( CASE WHEN ICD.period = 10 THEN MTRL.mtrl_qty    END ) mtrl_qty_2th      --資材数量_２月
                  ,SUM( CASE WHEN ICD.period = 10 THEN MTRL.mfg_qty     END ) mfg_qty_2th       --業者不良数量_２月
                  ,SUM( CASE WHEN ICD.period = 10 THEN MTRL.prod_qty    END ) prod_qty_2th      --製造不良数量_２月
                   --３月
                  ,SUM( CASE WHEN ICD.period = 11 THEN MTRL.invest_qty  END ) invest_qty_3th    --投入数量_３月
                  ,SUM( CASE WHEN ICD.period = 11 THEN MTRL.product_qty END ) product_qty_3th   --副産物数量_３月
                  ,SUM( CASE WHEN ICD.period = 11 THEN MTRL.into_qty    END ) into_qty_3th      --打込数量_３月
                  ,SUM( CASE WHEN ICD.period = 11 THEN MTRL.output_qty  END ) output_qty_3th    --出来高数量_３月
                  ,SUM( CASE WHEN ICD.period = 11 THEN MTRL.mtrl_qty    END ) mtrl_qty_3th      --資材数量_３月
                  ,SUM( CASE WHEN ICD.period = 11 THEN MTRL.mfg_qty     END ) mfg_qty_3th       --業者不良数量_３月
                  ,SUM( CASE WHEN ICD.period = 11 THEN MTRL.prod_qty    END ) prod_qty_3th      --製造不良数量_３月
                   --４月
                  ,SUM( CASE WHEN ICD.period = 12 THEN MTRL.invest_qty  END ) invest_qty_4th    --投入数量_４月
                  ,SUM( CASE WHEN ICD.period = 12 THEN MTRL.product_qty END ) product_qty_4th   --副産物数量_４月
                  ,SUM( CASE WHEN ICD.period = 12 THEN MTRL.into_qty    END ) into_qty_4th      --打込数量_４月
                  ,SUM( CASE WHEN ICD.period = 12 THEN MTRL.output_qty  END ) output_qty_4th    --出来高数量_４月
                  ,SUM( CASE WHEN ICD.period = 12 THEN MTRL.mtrl_qty    END ) mtrl_qty_4th      --資材数量_４月
                  ,SUM( CASE WHEN ICD.period = 12 THEN MTRL.mfg_qty     END ) mfg_qty_4th       --業者不良数量_４月
                  ,SUM( CASE WHEN ICD.period = 12 THEN MTRL.prod_qty    END ) prod_qty_4th      --製造不良数量_４月
             FROM  ( --集計対象データを『完成品』、『原料』、『副産物』別で取得
                      --================================================
                      -- 完成品データ
                      --================================================
                      SELECT  GBH.batch_no             batch_no      --バッチNo(デバッグ用)
                             ,TO_DATE( GMD.attribute11, 'YYYY/MM/DD' )
                                                       act_date      --完成品_生産日
                             ,GBH.attribute2           pm_dept       --成績管理部署
                             ,GBH.attribute1           slip_cls      --伝票区分
                             ,GBH.routing_id           rtng_id       --工順ID
                             ,GRB.routing_no           rtng_no       --工順番号
                             ,GMD.item_id              cp_item_id    --完成品_品目ID
                             ,GMD.item_id              item_id       --品目ID
                             ,ITP.lot_id               lot_id        --ロットID
                             ,0                        invest_qty    --投入数量
                             ,0                        product_qty   --副産物数量
                             ,0                        into_qty      --打込数量
                             ,ITP.trans_qty            output_qty    --出来高数量
                             ,0                        mtrl_qty      --資材数量
                             ,0                        mfg_qty       --業者不良数量
                             ,0                        prod_qty      --製造不良数量
                        FROM  xxcmn_gme_batch_header_arc      GBH    --生産バッチヘッダ（標準）バックアップ
                             ,gmd_routings_b                  GRB    --工順マスタ
                             ,xxcmn_gme_material_details_arc  GMD    --生産原料詳細（標準）バックアップ
                             ,xxcmn_ic_tran_pnd_arc           ITP    --OPM保留在庫トランザクション（標準）バックアップ
                       WHERE  GBH.batch_type           = 0
                         AND  GBH.attribute4          <> '-1'        --業務ステータス『取消し』のデータは対象外
                         --工順番号の取得と生産データ抽出の為の付加条件
                         AND  GRB.routing_class        NOT IN ( '61', '62', '70' )  -- 品目振替(70)、解体(61,62) 以外
                         AND  GBH.routing_id           = GRB.routing_id
                         --原料詳細データ『完成品』との結合
                         AND  GMD.line_type            = '1'         --【完成品】
                         AND  GBH.batch_id             = GMD.batch_id
                         --保留在庫トランザクションとの結合
                         AND  ITP.trans_qty           <> 0
                         AND  ITP.doc_type             = 'PROD'
                         AND  ITP.delete_mark          = 0
                         AND  ITP.completed_ind        = 1           --完了(⇒実績)
                         AND  ITP.reverse_id           IS NULL
                         AND  ITP.lot_id              <> 0           --『資材』は有り得ない
                         AND  GMD.material_detail_id   = ITP.line_id
                         AND  GMD.item_id              = ITP.item_id
                      -- [ 完成品データ END ] --
                     UNION ALL
                      --================================================
                      -- 原料データ
                      --================================================
                      SELECT  GBH.batch_no             batch_no      --バッチNo(デバッグ用)
                             ,TO_DATE( GMDF.attribute11, 'YYYY/MM/DD' )
                                                       act_date      --完成品_生産日
                             ,GBH.attribute2           pm_dept       --成績管理部署
                             ,GBH.attribute1           slip_cls      --伝票区分
                             ,GBH.routing_id           rtng_id       --工順ID
                             ,GRB.routing_no           rtng_no       --工順番号
                             ,GMDF.item_id             cp_item_id    --完成品_品目ID
                             ,GMD.item_id              item_id       --品目ID
                             ,XMD.lot_id               lot_id        --ロットID
                              --------------
                              -- 投入     --
                              --------------
                             ,CASE WHEN NVL( GMD.attribute5, 'N' ) <> 'Y' THEN           --投入･打込区分『投入』
-- 2009/10/15 H.Itou Mod Start 本番障害#1667
--                                CASE WHEN NVL( ITEMC.item_class_code, '1' ) <> '2' THEN  --品目区分『資材』以外
                                CASE WHEN NVL( MCB.segment1, '1' ) <> '2' THEN  --品目区分『資材』以外
-- 2009/10/15 H.Itou Mod End
                                  XMD.invested_qty - XMD.return_qty
                              END END                  invest_qty    --投入数量
                              -- 投入 END --
                             ,0                        product_qty   --副産物数量
                              --------------
                              -- 打込     --
                              --------------
                             ,CASE WHEN NVL( GMD.attribute5, 'N' ) = 'Y' THEN            --投入･打込区分『打込』
                                XMD.invested_qty - XMD.return_qty
                              END                      into_qty      --打込数量
                              -- 投入 END --
                             ,0                        output_qty    --出来高数量
                              --------------
                              -- 資材     --
                              --------------
                             ,CASE WHEN NVL( GMD.attribute5, 'N' ) <> 'Y' THEN           --投入･打込区分『投入』
-- 2009/10/15 H.Itou Mod Start 本番障害#1667
--                                CASE WHEN NVL( ITEMC.item_class_code, '1' ) = '2' THEN   --品目区分『資材』
                                CASE WHEN NVL( MCB.segment1, '1' ) = '2' THEN   --品目区分『資材』
-- 2009/10/15 H.Itou Mod End
                                  XMD.invested_qty - XMD.return_qty - ( XMD.mtl_prod_qty + XMD.mtl_mfg_qty )
                              END END                  mtrl_qty      --資材数量（数量 - 不良数量）
                              -- 資材 END --
                              ----------------
                              -- その他     --
                              ----------------
                             ,XMD.mtl_mfg_qty          mfg_qty       --業者不良数量
                             ,XMD.mtl_prod_qty         prod_qty      --製造不良数量
                              -- その他 END --
                        FROM  xxcmn_gme_batch_header_arc      GBH    --生産バッチヘッダ（標準）バックアップ
                             ,gmd_routings_b                  GRB    --工順マスタ
                             ,xxcmn_gme_material_details_arc  GMD    --生産原料詳細（標準）バックアップ
                             ,xxcmn_material_detail_arc       XMD    --生産原料詳細（アドオン）バックアップ
-- 2009/10/15 H.Itou Mod Start 本番障害#1667
--                             ,xxskz_item_class_v       ITEMC         --品目区分取得用
                             ,gmi_item_categories      GIC           -- 品目カテゴリ割当
                             ,mtl_categories_b         MCB           -- 品目カテゴリ
-- 2009/10/15 H.Itou Mod End
                             ,xxcmn_gme_material_details_arc  GMDF   --生産原料詳細（標準）バックアップ(完成品情報取得用)
                             ,xxcmn_ic_tran_pnd_arc           ITPF   --OPM保留在庫トランザクション（標準）バックアップ(完成品情報取得用)
                       WHERE  GBH.batch_type           = 0
                         AND  GBH.attribute4          <> '-1'        --業務ステータス『取消し』のデータは対象外
                         --工順番号の取得と生産データ抽出の為の付加条件
                         AND  GRB.routing_class        NOT IN ( '61', '62', '70' )  --品目振替(70)、解体(61,62) 以外
                         AND  GBH.routing_id           = GRB.routing_id
                         --原料詳細データ『原料』との結合
                         AND  GMD.line_type            = '-1'        --【原料】
                         AND  GBH.batch_id             = GMD.batch_id
                         --品目区分取得
-- 2009/10/15 H.Itou Mod Start 本番障害#1667
--                         AND  GMD.item_id              = ITEMC.item_id
                         AND  GMD.item_id              = GIC.item_id
                         AND  GIC.category_set_id      = TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS'))
                         AND  GIC.category_id          = MCB.category_id
                         AND  XMD.item_id              = GIC.item_id
-- 2009/10/15 H.Itou Mod End
                         --原料詳細アドオンとの結合
                         AND  XMD.plan_type            = '4'         --実績
                         AND  (    XMD.invested_qty   <> 0
                                OR XMD.return_qty     <> 0
                                OR XMD.mtl_mfg_qty    <> 0
                                OR XMD.mtl_prod_qty   <> 0
                              )
                         AND  GMD.batch_id             = XMD.batch_id
                         AND  GMD.material_detail_id   = XMD.material_detail_id
                         --完成品データとの結合
                         AND  GMDF.line_type           = '1'         --【完成品】
                         AND  GBH.batch_id             = GMDF.batch_id
                         --完成品データが完了しているかをチェック
                         AND  ITPF.doc_type            = 'PROD'
                         AND  ITPF.delete_mark         = 0
                         AND  ITPF.completed_ind       = 1           --完了(⇒実績)
                         AND  ITPF.reverse_id          IS NULL
                         AND  ITPF.lot_id             <> 0           --『資材』は有り得ない
                         AND  GMDF.material_detail_id  = ITPF.line_id
                         AND  GMDF.item_id             = ITPF.item_id
                      -- [ 原料データ END ] --
                     UNION ALL
                      --================================================
                      -- 副産物データ
                      --================================================
                      SELECT  GBH.batch_no             batch_no      --バッチNo(デバッグ用)
                             ,TO_DATE( GMDF.attribute11, 'YYYY/MM/DD' )
                                                              act_date       --完成品_生産日
                             ,GBH.attribute2                  pm_dept        --成績管理部署
                             ,GBH.attribute1                  slip_cls       --伝票区分
                             ,GBH.routing_id                  rtng_id        --工順ID
                             ,GRB.routing_no                  rtng_no        --工順番号
                             ,GMDF.item_id                    cp_item_id     --完成品_品目ID
                             ,GMD.item_id                     item_id        --品目ID
                             ,ITP.lot_id                      lot_id         --ロットID
                             ,0                               invest_qty     --投入数量
                             ,ITP.trans_qty                   product_qty    --副産物数量
                             ,0                               into_qty       --打込数量
                             ,0                               output_qty     --出来高数量
                             ,0                               mtrl_qty       --資材数量
                             ,0                               mfg_qty        --業者不良数量
                             ,0                               prod_qty       --製造不良数量
                        FROM  xxcmn_gme_batch_header_arc      GBH            --生産バッチヘッダ（標準）バックアップ
                             ,gmd_routings_b                  GRB            --工順マスタ
                             ,xxcmn_gme_material_details_arc  GMD            --生産原料詳細（標準）バックアップ
                             ,xxcmn_ic_tran_pnd_arc           ITP            --OPM保留在庫トランザクション（標準）バックアップ
                             ,xxcmn_gme_material_details_arc  GMDF           --生産原料詳細（標準）バックアップ(完成品情報取得用)
                             ,xxcmn_ic_tran_pnd_arc           ITPF           --OPM保留在庫トランザクション（標準）バックアップ(完成品情報取得用)
                       WHERE  GBH.batch_type           = 0
                         AND  GBH.attribute4          <> '-1'        --業務ステータス『取消し』のデータは対象外
                         --工順番号の取得と生産データ抽出の為の付加条件
                         AND  GRB.routing_class        NOT IN ( '61', '62', '70' )  --品目振替(70)、解体(61,62) 以外
                         AND  GBH.routing_id           = GRB.routing_id
                         --原料詳細データ『副産物』との結合
                         AND  GMD.line_type            = '2'         --【副産物】
                         AND  GBH.batch_id             = GMD.batch_id
                         --保留在庫トランザクションとの結合
                         AND  ITP.trans_qty           <> 0
                         AND  ITP.doc_type             = 'PROD'
                         AND  ITP.delete_mark          = 0
                         AND  ITP.completed_ind        = 1           --完了(⇒実績)
                         AND  ITP.reverse_id           IS NULL
                         AND  ITP.lot_id              <> 0           --『資材』は有り得ない
                         AND  GMD.material_detail_id   = ITP.line_id
                         AND  GMD.item_id              = ITP.item_id
                         --完成品データとの結合
                         AND  GMDF.line_type           = '1'         --【完成品】
                         AND  GBH.batch_id             = GMDF.batch_id
                         --完成品データが完了しているかをチェック
                         AND  ITPF.doc_type            = 'PROD'
                         AND  ITPF.delete_mark         = 0
                         AND  ITPF.completed_ind       = 1           --完了(⇒実績)
                         AND  ITPF.reverse_id          IS NULL
                         AND  ITPF.lot_id             <> 0           --『資材』は有り得ない
                         AND  GMDF.material_detail_id  = ITPF.line_id
                         AND  GMDF.item_id             = ITPF.item_id
                      -- [ 副産物データ END ] --
                   )                MTRL          --生産データ
                  ,ic_cldr_dtl      ICD           --在庫カレンダ
            WHERE
              --在庫カレンダとの結合 ⇒ 年月単位に分ける
                   ICD.orgn_code         = 'ITOE'  
              AND  TO_CHAR( MTRL.act_date, 'YYYYMM' ) = TO_CHAR( ICD.period_end_date, 'YYYYMM' )
           GROUP BY
                   ICD.fiscal_year  --年度(実績完了日を変換)
                  ,MTRL.pm_dept     --成績管理部署
                  ,MTRL.slip_cls    --伝票区分
                  ,MTRL.rtng_id     --工順ID
                  ,MTRL.rtng_no     --工順番号
                  ,MTRL.cp_item_id  --完成品_品目ID
        )  SMMR
       ,xxskz_item_mst_v         ITEM    --品目名取得用（SYSDATEで有効データを抽出）
       ,xxskz_prod_class_v       PRODC   --商品区分取得用
       ,xxskz_item_class_v       ITEMC   --品目区分取得用
       ,xxskz_crowd_code_v       CROWD   --群コード取得用
       ,gmd_routings_tl          GRTT    --工順マスタ(日本語)
 WHERE
   --品目名(完成品)取得
        SMMR.cp_item_id = ITEM.item_id(+)
   --品目カテゴリ名(完成品)取得
   AND  SMMR.cp_item_id = PRODC.item_id(+)
   AND  SMMR.cp_item_id = ITEMC.item_id(+)
   AND  SMMR.cp_item_id = CROWD.item_id(+)
   --工順摘要取得
   AND  GRTT.language(+) = 'JA'
   AND  SMMR.rtng_id = GRTT.routing_id(+)
/
COMMENT ON TABLE APPS.XXSKZ_生産時系列_数量_V IS 'SKYLINK用 生産時系列（数量）VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.年度                IS '年度'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.成績管理部署        IS '成績管理部署'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.商品区分            IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.商品区分名          IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.品目区分            IS '品目区分'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.品目区分名          IS '品目区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.群コード            IS '群コード'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.品目コード          IS '品目コード'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.品目名              IS '品目名'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.品目略称            IS '品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.伝票区分            IS '伝票区分'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.工順                IS '工順'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.工順名称            IS '工順名称'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.工順摘要            IS '工順摘要'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.投入数量_５月       IS '投入数量_５月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.副産物数量_５月     IS '副産物数量_５月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.打込数量_５月       IS '打込数量_５月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.出来高数量_５月     IS '出来高数量_５月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.資材数量_５月       IS '資材数量_５月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.業者不良数量_５月   IS '業者不良数量_５月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.製造不良数量_５月   IS '製造不良数量_５月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.投入数量_６月       IS '投入数量_６月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.副産物数量_６月     IS '副産物数量_６月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.打込数量_６月       IS '打込数量_６月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.出来高数量_６月     IS '出来高数量_６月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.資材数量_６月       IS '資材数量_６月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.業者不良数量_６月   IS '業者不良数量_６月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.製造不良数量_６月   IS '製造不良数量_６月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.投入数量_７月       IS '投入数量_７月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.副産物数量_７月     IS '副産物数量_７月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.打込数量_７月       IS '打込数量_７月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.出来高数量_７月     IS '出来高数量_７月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.資材数量_７月       IS '資材数量_７月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.業者不良数量_７月   IS '業者不良数量_７月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.製造不良数量_７月   IS '製造不良数量_７月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.投入数量_８月       IS '投入数量_８月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.副産物数量_８月     IS '副産物数量_８月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.打込数量_８月       IS '打込数量_８月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.出来高数量_８月     IS '出来高数量_８月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.資材数量_８月       IS '資材数量_８月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.業者不良数量_８月   IS '業者不良数量_８月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.製造不良数量_８月   IS '製造不良数量_８月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.投入数量_９月       IS '投入数量_９月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.副産物数量_９月     IS '副産物数量_９月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.打込数量_９月       IS '打込数量_９月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.出来高数量_９月     IS '出来高数量_９月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.資材数量_９月       IS '資材数量_９月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.業者不良数量_９月   IS '業者不良数量_９月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.製造不良数量_９月   IS '製造不良数量_９月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.投入数量_１０月     IS '投入数量_１０月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.副産物数量_１０月   IS '副産物数量_１０月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.打込数量_１０月     IS '打込数量_１０月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.出来高数量_１０月   IS '出来高数量_１０月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.資材数量_１０月     IS '資材数量_１０月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.業者不良数量_１０月 IS '業者不良数量_１０月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.製造不良数量_１０月 IS '製造不良数量_１０月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.投入数量_１１月     IS '投入数量_１１月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.副産物数量_１１月   IS '副産物数量_１１月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.打込数量_１１月     IS '打込数量_１１月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.出来高数量_１１月   IS '出来高数量_１１月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.資材数量_１１月     IS '資材数量_１１月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.業者不良数量_１１月 IS '業者不良数量_１１月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.製造不良数量_１１月 IS '製造不良数量_１１月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.投入数量_１２月     IS '投入数量_１２月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.副産物数量_１２月   IS '副産物数量_１２月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.打込数量_１２月     IS '打込数量_１２月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.出来高数量_１２月   IS '出来高数量_１２月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.資材数量_１２月     IS '資材数量_１２月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.業者不良数量_１２月 IS '業者不良数量_１２月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.製造不良数量_１２月 IS '製造不良数量_１２月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.投入数量_１月       IS '投入数量_１月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.副産物数量_１月     IS '副産物数量_１月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.打込数量_１月       IS '打込数量_１月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.出来高数量_１月     IS '出来高数量_１月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.資材数量_１月       IS '資材数量_１月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.業者不良数量_１月   IS '業者不良数量_１月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.製造不良数量_１月   IS '製造不良数量_１月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.投入数量_２月       IS '投入数量_２月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.副産物数量_２月     IS '副産物数量_２月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.打込数量_２月       IS '打込数量_２月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.出来高数量_２月     IS '出来高数量_２月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.資材数量_２月       IS '資材数量_２月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.業者不良数量_２月   IS '業者不良数量_２月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.製造不良数量_２月   IS '製造不良数量_２月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.投入数量_３月       IS '投入数量_３月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.副産物数量_３月     IS '副産物数量_３月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.打込数量_３月       IS '打込数量_３月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.出来高数量_３月     IS '出来高数量_３月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.資材数量_３月       IS '資材数量_３月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.業者不良数量_３月   IS '業者不良数量_３月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.製造不良数量_３月   IS '製造不良数量_３月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.投入数量_４月       IS '投入数量_４月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.副産物数量_４月     IS '副産物数量_４月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.打込数量_４月       IS '打込数量_４月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.出来高数量_４月     IS '出来高数量_４月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.資材数量_４月       IS '資材数量_４月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.業者不良数量_４月   IS '業者不良数量_４月'
/
COMMENT ON COLUMN APPS.XXSKZ_生産時系列_数量_V.製造不良数量_４月   IS '製造不良数量_４月'
/
