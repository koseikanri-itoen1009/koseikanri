/*************************************************************************
 * 
 * View  Name      : XXSKZ_仕入有償時系列_基本_V
 * Description     : XXSKZ_仕入有償時系列_基本_V
 * MD.070          : 
 * Version         : 1.4
 * 
 * Change Record
 * ------------- ----- ---------------- -------------------------------------
 *  Date          Ver.  Editor          Description
 * ------------- ----- ---------------- -------------------------------------
 *  2012/11/26    1.0   SCSK M.Nagai    初回作成
 *  2013/06/18    1.1   SCSK D.Sugahara E_本稼働_10839消費税対応
 *  2013/11/05    1.2   SCSK D.Sugahara E_本稼動_11245対応
 *  2019/06/15    1.3   SCSK Y.Soji     E_本稼動_15601対応
 *  2019/11/11    1.4   SCSK Y.Sasaki   E_本稼動_16045対応
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_仕入有償時系列_基本_V
(
 年度
,部署
,部署名
,取引先
,取引先名
,商品区分
,商品区分名
,品目区分
,品目区分名
,群コード
,品目コード
,品目名
,品目略称
,仕入形態
,仕入形態名
,仕入数量_５月
,仕入金額_５月
,仕入消費税_５月
,有償数量_５月
,有償在庫金額_５月
,有償金額_５月
,有償消費税_５月
,仕入数量_６月
,仕入金額_６月
,仕入消費税_６月
,有償数量_６月
,有償在庫金額_６月
,有償金額_６月
,有償消費税_６月
,仕入数量_７月
,仕入金額_７月
,仕入消費税_７月
,有償数量_７月
,有償在庫金額_７月
,有償金額_７月
,有償消費税_７月
,仕入数量_８月
,仕入金額_８月
,仕入消費税_８月
,有償数量_８月
,有償在庫金額_８月
,有償金額_８月
,有償消費税_８月
,仕入数量_９月
,仕入金額_９月
,仕入消費税_９月
,有償数量_９月
,有償在庫金額_９月
,有償金額_９月
,有償消費税_９月
,仕入数量_１０月
,仕入金額_１０月
,仕入消費税_１０月
,有償数量_１０月
,有償在庫金額_１０月
,有償金額_１０月
,有償消費税_１０月
,仕入数量_１１月
,仕入金額_１１月
,仕入消費税_１１月
,有償数量_１１月
,有償在庫金額_１１月
,有償金額_１１月
,有償消費税_１１月
,仕入数量_１２月
,仕入金額_１２月
,仕入消費税_１２月
,有償数量_１２月
,有償在庫金額_１２月
,有償金額_１２月
,有償消費税_１２月
,仕入数量_１月
,仕入金額_１月
,仕入消費税_１月
,有償数量_１月
,有償在庫金額_１月
,有償金額_１月
,有償消費税_１月
,仕入数量_２月
,仕入金額_２月
,仕入消費税_２月
,有償数量_２月
,有償在庫金額_２月
,有償金額_２月
,有償消費税_２月
,仕入数量_３月
,仕入金額_３月
,仕入消費税_３月
,有償数量_３月
,有償在庫金額_３月
,有償金額_３月
,有償消費税_３月
,仕入数量_４月
,仕入金額_４月
,仕入消費税_４月
,有償数量_４月
,有償在庫金額_４月
,有償金額_４月
,有償消費税_４月
)
AS
SELECT  SMRP.year                         year                   --年度
       ,SMRP.dept_code                    dept_code              --部署コード
       ,LOCT.location_name                dept_name              --部署名
       ,VNDR.segment1                     vndr_code              --取引先コード
       ,VNDR.vendor_name                  vndr_name              --取引先名
       ,PRODC.prod_class_code             prod_class_code        --商品区分
       ,PRODC.prod_class_name             prod_class_name        --商品区分名
       ,ITEMC.item_class_code             item_class_code        --品目区分
       ,ITEMC.item_class_name             item_class_name        --品目区分名
       ,CROWD.crowd_code                  crowd_code             --群コード
       ,SMRP.item_code                    item_code              --品目
       ,ITEM.item_name                    item_name              --品目名
       ,ITEM.item_short_name              item_s_name            --品目略称
       ,SMRP.rcv_class                    rcv_class              --仕入形態
       ,FLV03.meaning                     rcv_name               --仕入形態名
        --５月集計
       ,NVL( SMRP.rcv_qty_5th    , 0 )    rcv_qty_5th            --仕入数量_５月
       ,NVL( SMRP.rcv_price_5th  , 0 )    rcv_price_5th          --仕入金額_５月
       ,NVL( SMRP.rcv_cn_tax_5th , 0 )    rcv_cn_tax_5th         --仕入消費税_５月
       ,NVL( SMRP.pay_qty_5th    , 0 )    pay_qty_5th            --有償数量_５月
       ,NVL( SMRP.inv_price_5th  , 0 )    inv_price_5th          --有償在庫金額_５月
       ,NVL( SMRP.pay_price_5th  , 0 )    pay_price_5th          --有償金額_５月
       ,NVL( SMRP.pay_cn_tax_5th , 0 )    pay_cn_tax_5th         --有償消費税_５月
        --６月集計
       ,NVL( SMRP.rcv_qty_6th    , 0 )    rcv_qty_6th            --仕入数量_６月
       ,NVL( SMRP.rcv_price_6th  , 0 )    rcv_price_6th          --仕入金額_６月
       ,NVL( SMRP.rcv_cn_tax_6th , 0 )    rcv_cn_tax_6th         --仕入消費税_６月
       ,NVL( SMRP.pay_qty_6th    , 0 )    pay_qty_6th            --有償数量_６月
       ,NVL( SMRP.inv_price_6th  , 0 )    inv_price_6th          --有償在庫金額_６月
       ,NVL( SMRP.pay_price_6th  , 0 )    pay_price_6th          --有償金額_６月
       ,NVL( SMRP.pay_cn_tax_6th , 0 )    pay_cn_tax_6th         --有償消費税_６月
        --７月集計
       ,NVL( SMRP.rcv_qty_7th    , 0 )    rcv_qty_7th            --仕入数量_７月
       ,NVL( SMRP.rcv_price_7th  , 0 )    rcv_price_7th          --仕入金額_７月
       ,NVL( SMRP.rcv_cn_tax_7th , 0 )    rcv_cn_tax_7th         --仕入消費税_７月
       ,NVL( SMRP.pay_qty_7th    , 0 )    pay_qty_7th            --有償数量_７月
       ,NVL( SMRP.inv_price_7th  , 0 )    inv_price_7th          --有償在庫金額_７月
       ,NVL( SMRP.pay_price_7th  , 0 )    pay_price_7th          --有償金額_７月
       ,NVL( SMRP.pay_cn_tax_7th , 0 )    pay_cn_tax_7th         --有償消費税_７月
        --８月集計
       ,NVL( SMRP.rcv_qty_8th    , 0 )    rcv_qty_8th            --仕入数量_８月
       ,NVL( SMRP.rcv_price_8th  , 0 )    rcv_price_8th          --仕入金額_８月
       ,NVL( SMRP.rcv_cn_tax_8th , 0 )    rcv_cn_tax_8th         --仕入消費税_８月
       ,NVL( SMRP.pay_qty_8th    , 0 )    pay_qty_8th            --有償数量_８月
       ,NVL( SMRP.inv_price_8th  , 0 )    inv_price_8th          --有償在庫金額_８月
       ,NVL( SMRP.pay_price_8th  , 0 )    pay_price_8th          --有償金額_８月
       ,NVL( SMRP.pay_cn_tax_8th , 0 )    pay_cn_tax_8th         --有償消費税_８月
        --９月集計
       ,NVL( SMRP.rcv_qty_9th    , 0 )    rcv_qty_9th            --仕入数量_９月
       ,NVL( SMRP.rcv_price_9th  , 0 )    rcv_price_9th          --仕入金額_９月
       ,NVL( SMRP.rcv_cn_tax_9th , 0 )    rcv_cn_tax_9th         --仕入消費税_９月
       ,NVL( SMRP.pay_qty_9th    , 0 )    pay_qty_9th            --有償数量_９月
       ,NVL( SMRP.inv_price_9th  , 0 )    inv_price_9th          --有償在庫金額_９月
       ,NVL( SMRP.pay_price_9th  , 0 )    pay_price_9th          --有償金額_９月
       ,NVL( SMRP.pay_cn_tax_9th , 0 )    pay_cn_tax_9th         --有償消費税_９月
        --１０月集計
       ,NVL( SMRP.rcv_qty_10th   , 0 )    rcv_qty_10th           --仕入数量_１０月
       ,NVL( SMRP.rcv_price_10th , 0 )    rcv_price_10th         --仕入金額_１０月
       ,NVL( SMRP.rcv_cn_tax_10th, 0 )    rcv_cn_tax_10th        --仕入消費税_１０月
       ,NVL( SMRP.pay_qty_10th   , 0 )    pay_qty_10th           --有償数量_１０月
       ,NVL( SMRP.inv_price_10th , 0 )    inv_price_10th         --有償在庫金額_１０月
       ,NVL( SMRP.pay_price_10th , 0 )    pay_price_10th         --有償金額_１０月
       ,NVL( SMRP.pay_cn_tax_10th, 0 )    pay_cn_tax_10th        --有償消費税_１０月
        --１１月集計
       ,NVL( SMRP.rcv_qty_11th   , 0 )    rcv_qty_11th           --仕入数量_１１月
       ,NVL( SMRP.rcv_price_11th , 0 )    rcv_price_11th         --仕入金額_１１月
       ,NVL( SMRP.rcv_cn_tax_11th, 0 )    rcv_cn_tax_11th        --仕入消費税_１１月
       ,NVL( SMRP.pay_qty_11th   , 0 )    pay_qty_11th           --有償数量_１１月
       ,NVL( SMRP.inv_price_11th , 0 )    inv_price_11th         --有償在庫金額_１１月
       ,NVL( SMRP.pay_price_11th , 0 )    pay_price_11th         --有償金額_１１月
       ,NVL( SMRP.pay_cn_tax_11th, 0 )    pay_cn_tax_11th        --有償消費税_１１月
        --１２月集計
       ,NVL( SMRP.rcv_qty_12th   , 0 )    rcv_qty_12th           --仕入数量_１２月
       ,NVL( SMRP.rcv_price_12th , 0 )    rcv_price_12th         --仕入金額_１２月
       ,NVL( SMRP.rcv_cn_tax_12th, 0 )    rcv_cn_tax_12th        --仕入消費税_１２月
       ,NVL( SMRP.pay_qty_12th   , 0 )    pay_qty_12th           --有償数量_１２月
       ,NVL( SMRP.inv_price_12th , 0 )    inv_price_12th         --有償在庫金額_１２月
       ,NVL( SMRP.pay_price_12th , 0 )    pay_price_12th         --有償金額_１２月
       ,NVL( SMRP.pay_cn_tax_12th, 0 )    pay_cn_tax_12th        --有償消費税_１２月
        --１月集計
       ,NVL( SMRP.rcv_qty_1th    , 0 )    rcv_qty_1th            --仕入数量_１月
       ,NVL( SMRP.rcv_price_1th  , 0 )    rcv_price_1th          --仕入金額_１月
       ,NVL( SMRP.rcv_cn_tax_1th , 0 )    rcv_cn_tax_1th         --仕入消費税_１月
       ,NVL( SMRP.pay_qty_1th    , 0 )    pay_qty_1th            --有償数量_１月
       ,NVL( SMRP.inv_price_1th  , 0 )    inv_price_1th          --有償在庫金額_１月
       ,NVL( SMRP.pay_price_1th  , 0 )    pay_price_1th          --有償金額_１月
       ,NVL( SMRP.pay_cn_tax_1th , 0 )    pay_cn_tax_1th         --有償消費税_１月
        --２月集計
       ,NVL( SMRP.rcv_qty_2th    , 0 )    rcv_qty_2th            --仕入数量_２月
       ,NVL( SMRP.rcv_price_2th  , 0 )    rcv_price_2th          --仕入金額_２月
       ,NVL( SMRP.rcv_cn_tax_2th , 0 )    rcv_cn_tax_2th         --仕入消費税_２月
       ,NVL( SMRP.pay_qty_2th    , 0 )    pay_qty_2th            --有償数量_２月
       ,NVL( SMRP.inv_price_2th  , 0 )    inv_price_2th          --有償在庫金額_２月
       ,NVL( SMRP.pay_price_2th  , 0 )    pay_price_2th          --有償金額_２月
       ,NVL( SMRP.pay_cn_tax_2th , 0 )    pay_cn_tax_2th         --有償消費税_２月
        --３月集計
       ,NVL( SMRP.rcv_qty_3th    , 0 )    rcv_qty_3th            --仕入数量_３月
       ,NVL( SMRP.rcv_price_3th  , 0 )    rcv_price_3th          --仕入金額_３月
       ,NVL( SMRP.rcv_cn_tax_3th , 0 )    rcv_cn_tax_3th         --仕入消費税_３月
       ,NVL( SMRP.pay_qty_3th    , 0 )    pay_qty_3th            --有償数量_３月
       ,NVL( SMRP.inv_price_3th  , 0 )    inv_price_3th          --有償在庫金額_３月
       ,NVL( SMRP.pay_price_3th  , 0 )    pay_price_3th          --有償金額_３月
       ,NVL( SMRP.pay_cn_tax_3th , 0 )    pay_cn_tax_3th         --有償消費税_３月
        --４月集計
       ,NVL( SMRP.rcv_qty_4th    , 0 )    rcv_qty_4th            --仕入数量_４月
       ,NVL( SMRP.rcv_price_4th  , 0 )    rcv_price_4th          --仕入金額_４月
       ,NVL( SMRP.rcv_cn_tax_4th , 0 )    rcv_cn_tax_4th         --仕入消費税_４月
       ,NVL( SMRP.pay_qty_4th    , 0 )    pay_qty_4th            --有償数量_４月
       ,NVL( SMRP.inv_price_4th  , 0 )    inv_price_4th          --有償在庫金額_４月
       ,NVL( SMRP.pay_price_4th  , 0 )    pay_price_4th          --有償金額_４月
       ,NVL( SMRP.pay_cn_tax_4th , 0 )    pay_cn_tax_4th         --有償消費税_４月
  FROM  (  --年度、部署、取引先、品目、仕入形態単位で集計した（月度集計を横にした）仕入有償集計データ
           SELECT  ICD.fiscal_year                                            year             --年度
                  ,RVPY.dept_code                                             dept_code        --部署コード
                  ,RVPY.vendor_id                                             vendor_id        --取引先ID
                  ,RVPY.item_code                                             item_code        --品目
                  ,RVPY.rcv_class                                             rcv_class        --仕入形態
                   --５月集計
                  ,SUM( CASE WHEN ICD.period =  1 THEN RVPY.rcv_qty    END )  rcv_qty_5th      --仕入数量_５月
                  ,SUM( CASE WHEN ICD.period =  1 THEN RVPY.rcv_price  END )  rcv_price_5th    --仕入金額_５月
                  ,SUM( CASE WHEN ICD.period =  1 THEN RVPY.rcv_cn_tax END )  rcv_cn_tax_5th   --仕入消費税_５月
                  ,SUM( CASE WHEN ICD.period =  1 THEN RVPY.pay_qty    END )  pay_qty_5th      --有償数量_５月
                  ,SUM( CASE WHEN ICD.period =  1 THEN RVPY.inv_price  END )  inv_price_5th    --有償在庫金額_５月
                  ,SUM( CASE WHEN ICD.period =  1 THEN RVPY.pay_price  END )  pay_price_5th    --有償金額_５月
                  ,SUM( CASE WHEN ICD.period =  1 THEN RVPY.pay_cn_tax END )  pay_cn_tax_5th   --有償消費税_５月
                   --６月集計
                  ,SUM( CASE WHEN ICD.period =  2 THEN RVPY.rcv_qty    END )  rcv_qty_6th      --仕入数量_６月
                  ,SUM( CASE WHEN ICD.period =  2 THEN RVPY.rcv_price  END )  rcv_price_6th    --仕入金額_６月
                  ,SUM( CASE WHEN ICD.period =  2 THEN RVPY.rcv_cn_tax END )  rcv_cn_tax_6th   --仕入消費税_６月
                  ,SUM( CASE WHEN ICD.period =  2 THEN RVPY.pay_qty    END )  pay_qty_6th      --有償数量_６月
                  ,SUM( CASE WHEN ICD.period =  2 THEN RVPY.inv_price  END )  inv_price_6th    --有償在庫金額_６月
                  ,SUM( CASE WHEN ICD.period =  2 THEN RVPY.pay_price  END )  pay_price_6th    --有償金額_６月
                  ,SUM( CASE WHEN ICD.period =  2 THEN RVPY.pay_cn_tax END )  pay_cn_tax_6th   --有償消費税_６月
                   --７月集計
                  ,SUM( CASE WHEN ICD.period =  3 THEN RVPY.rcv_qty    END )  rcv_qty_7th      --仕入数量_７月
                  ,SUM( CASE WHEN ICD.period =  3 THEN RVPY.rcv_price  END )  rcv_price_7th    --仕入金額_７月
                  ,SUM( CASE WHEN ICD.period =  3 THEN RVPY.rcv_cn_tax END )  rcv_cn_tax_7th   --仕入消費税_７月
                  ,SUM( CASE WHEN ICD.period =  3 THEN RVPY.pay_qty    END )  pay_qty_7th      --有償数量_７月
                  ,SUM( CASE WHEN ICD.period =  3 THEN RVPY.inv_price  END )  inv_price_7th    --有償在庫金額_７月
                  ,SUM( CASE WHEN ICD.period =  3 THEN RVPY.pay_price  END )  pay_price_7th    --有償金額_７月
                  ,SUM( CASE WHEN ICD.period =  3 THEN RVPY.pay_cn_tax END )  pay_cn_tax_7th   --有償消費税_７月
                   --８月集計
                  ,SUM( CASE WHEN ICD.period =  4 THEN RVPY.rcv_qty    END )  rcv_qty_8th      --仕入数量_８月
                  ,SUM( CASE WHEN ICD.period =  4 THEN RVPY.rcv_price  END )  rcv_price_8th    --仕入金額_８月
                  ,SUM( CASE WHEN ICD.period =  4 THEN RVPY.rcv_cn_tax END )  rcv_cn_tax_8th   --仕入消費税_８月
                  ,SUM( CASE WHEN ICD.period =  4 THEN RVPY.pay_qty    END )  pay_qty_8th      --有償数量_８月
                  ,SUM( CASE WHEN ICD.period =  4 THEN RVPY.inv_price  END )  inv_price_8th    --有償在庫金額_８月
                  ,SUM( CASE WHEN ICD.period =  4 THEN RVPY.pay_price  END )  pay_price_8th    --有償金額_８月
                  ,SUM( CASE WHEN ICD.period =  4 THEN RVPY.pay_cn_tax END )  pay_cn_tax_8th   --有償消費税_８月
                   --９月集計
                  ,SUM( CASE WHEN ICD.period =  5 THEN RVPY.rcv_qty    END )  rcv_qty_9th      --仕入数量_９月
                  ,SUM( CASE WHEN ICD.period =  5 THEN RVPY.rcv_price  END )  rcv_price_9th    --仕入金額_９月
                  ,SUM( CASE WHEN ICD.period =  5 THEN RVPY.rcv_cn_tax END )  rcv_cn_tax_9th   --仕入消費税_９月
                  ,SUM( CASE WHEN ICD.period =  5 THEN RVPY.pay_qty    END )  pay_qty_9th      --有償数量_９月
                  ,SUM( CASE WHEN ICD.period =  5 THEN RVPY.inv_price  END )  inv_price_9th    --有償在庫金額_９月
                  ,SUM( CASE WHEN ICD.period =  5 THEN RVPY.pay_price  END )  pay_price_9th    --有償金額_９月
                  ,SUM( CASE WHEN ICD.period =  5 THEN RVPY.pay_cn_tax END )  pay_cn_tax_9th   --有償消費税_９月
                   --１０月集計
                  ,SUM( CASE WHEN ICD.period =  6 THEN RVPY.rcv_qty    END )  rcv_qty_10th     --仕入数量_１０月
                  ,SUM( CASE WHEN ICD.period =  6 THEN RVPY.rcv_price  END )  rcv_price_10th   --仕入金額_１０月
                  ,SUM( CASE WHEN ICD.period =  6 THEN RVPY.rcv_cn_tax END )  rcv_cn_tax_10th  --仕入消費税_１０月
                  ,SUM( CASE WHEN ICD.period =  6 THEN RVPY.pay_qty    END )  pay_qty_10th     --有償数量_１０月
                  ,SUM( CASE WHEN ICD.period =  6 THEN RVPY.inv_price  END )  inv_price_10th   --有償在庫金額_１０月
                  ,SUM( CASE WHEN ICD.period =  6 THEN RVPY.pay_price  END )  pay_price_10th   --有償金額_１０月
                  ,SUM( CASE WHEN ICD.period =  6 THEN RVPY.pay_cn_tax END )  pay_cn_tax_10th  --有償消費税_１０月
                   --１１月集計
                  ,SUM( CASE WHEN ICD.period =  7 THEN RVPY.rcv_qty    END )  rcv_qty_11th     --仕入数量_１１月
                  ,SUM( CASE WHEN ICD.period =  7 THEN RVPY.rcv_price  END )  rcv_price_11th   --仕入金額_１１月
                  ,SUM( CASE WHEN ICD.period =  7 THEN RVPY.rcv_cn_tax END )  rcv_cn_tax_11th  --仕入消費税_１１月
                  ,SUM( CASE WHEN ICD.period =  7 THEN RVPY.pay_qty    END )  pay_qty_11th     --有償数量_１１月
                  ,SUM( CASE WHEN ICD.period =  7 THEN RVPY.inv_price  END )  inv_price_11th   --有償在庫金額_１１月
                  ,SUM( CASE WHEN ICD.period =  7 THEN RVPY.pay_price  END )  pay_price_11th   --有償金額_１１月
                  ,SUM( CASE WHEN ICD.period =  7 THEN RVPY.pay_cn_tax END )  pay_cn_tax_11th  --有償消費税_１１月
                   --１２月集計
                  ,SUM( CASE WHEN ICD.period =  8 THEN RVPY.rcv_qty    END )  rcv_qty_12th     --仕入数量_１２月
                  ,SUM( CASE WHEN ICD.period =  8 THEN RVPY.rcv_price  END )  rcv_price_12th   --仕入金額_１２月
                  ,SUM( CASE WHEN ICD.period =  8 THEN RVPY.rcv_cn_tax END )  rcv_cn_tax_12th  --仕入消費税_１２月
                  ,SUM( CASE WHEN ICD.period =  8 THEN RVPY.pay_qty    END )  pay_qty_12th     --有償数量_１２月
                  ,SUM( CASE WHEN ICD.period =  8 THEN RVPY.inv_price  END )  inv_price_12th   --有償在庫金額_１２月
                  ,SUM( CASE WHEN ICD.period =  8 THEN RVPY.pay_price  END )  pay_price_12th   --有償金額_１２月
                  ,SUM( CASE WHEN ICD.period =  8 THEN RVPY.pay_cn_tax END )  pay_cn_tax_12th  --有償消費税_１２月
                   --１月集計
                  ,SUM( CASE WHEN ICD.period =  9 THEN RVPY.rcv_qty    END )  rcv_qty_1th      --仕入数量_１月
                  ,SUM( CASE WHEN ICD.period =  9 THEN RVPY.rcv_price  END )  rcv_price_1th    --仕入金額_１月
                  ,SUM( CASE WHEN ICD.period =  9 THEN RVPY.rcv_cn_tax END )  rcv_cn_tax_1th   --仕入消費税_１月
                  ,SUM( CASE WHEN ICD.period =  9 THEN RVPY.pay_qty    END )  pay_qty_1th      --有償数量_１月
                  ,SUM( CASE WHEN ICD.period =  9 THEN RVPY.inv_price  END )  inv_price_1th    --有償在庫金額_１月
                  ,SUM( CASE WHEN ICD.period =  9 THEN RVPY.pay_price  END )  pay_price_1th    --有償金額_１月
                  ,SUM( CASE WHEN ICD.period =  9 THEN RVPY.pay_cn_tax END )  pay_cn_tax_1th   --有償消費税_１月
                   --２月集計
                  ,SUM( CASE WHEN ICD.period = 10 THEN RVPY.rcv_qty    END )  rcv_qty_2th      --仕入数量_２月
                  ,SUM( CASE WHEN ICD.period = 10 THEN RVPY.rcv_price  END )  rcv_price_2th    --仕入金額_２月
                  ,SUM( CASE WHEN ICD.period = 10 THEN RVPY.rcv_cn_tax END )  rcv_cn_tax_2th   --仕入消費税_２月
                  ,SUM( CASE WHEN ICD.period = 10 THEN RVPY.pay_qty    END )  pay_qty_2th      --有償数量_２月
                  ,SUM( CASE WHEN ICD.period = 10 THEN RVPY.inv_price  END )  inv_price_2th    --有償在庫金額_２月
                  ,SUM( CASE WHEN ICD.period = 10 THEN RVPY.pay_price  END )  pay_price_2th    --有償金額_２月
                  ,SUM( CASE WHEN ICD.period = 10 THEN RVPY.pay_cn_tax END )  pay_cn_tax_2th   --有償消費税_２月
                   --３月集計
                  ,SUM( CASE WHEN ICD.period = 11 THEN RVPY.rcv_qty    END )  rcv_qty_3th      --仕入数量_３月
                  ,SUM( CASE WHEN ICD.period = 11 THEN RVPY.rcv_price  END )  rcv_price_3th    --仕入金額_３月
                  ,SUM( CASE WHEN ICD.period = 11 THEN RVPY.rcv_cn_tax END )  rcv_cn_tax_3th   --仕入消費税_３月
                  ,SUM( CASE WHEN ICD.period = 11 THEN RVPY.pay_qty    END )  pay_qty_3th      --有償数量_３月
                  ,SUM( CASE WHEN ICD.period = 11 THEN RVPY.inv_price  END )  inv_price_3th    --有償在庫金額_３月
                  ,SUM( CASE WHEN ICD.period = 11 THEN RVPY.pay_price  END )  pay_price_3th    --有償金額_３月
                  ,SUM( CASE WHEN ICD.period = 11 THEN RVPY.pay_cn_tax END )  pay_cn_tax_3th   --有償消費税_３月
                   --４月集計
                  ,SUM( CASE WHEN ICD.period = 12 THEN RVPY.rcv_qty    END )  rcv_qty_4th      --仕入数量_４月
                  ,SUM( CASE WHEN ICD.period = 12 THEN RVPY.rcv_price  END )  rcv_price_4th    --仕入金額_４月
                  ,SUM( CASE WHEN ICD.period = 12 THEN RVPY.rcv_cn_tax END )  rcv_cn_tax_4th   --仕入消費税_４月
                  ,SUM( CASE WHEN ICD.period = 12 THEN RVPY.pay_qty    END )  pay_qty_4th      --有償数量_４月
                  ,SUM( CASE WHEN ICD.period = 12 THEN RVPY.inv_price  END )  inv_price_4th    --有償在庫金額_４月
                  ,SUM( CASE WHEN ICD.period = 12 THEN RVPY.pay_price  END )  pay_price_4th    --有償金額_４月
                  ,SUM( CASE WHEN ICD.period = 12 THEN RVPY.pay_cn_tax END )  pay_cn_tax_4th   --有償消費税_４月
             FROM  ( --受入＋仕入返品＋有償支給の実績データをUNION ALLで取得
                      ----------------------------------------------
                      -- 発注受入データ
                      --  ※帳票『仕入実績表』の消費税額と一致させる為、保留在庫トランザクションを参照
                      ----------------------------------------------
-- 2019/06/15 Y.Shoji Mod Start E_本稼動_15601
--                      SELECT  ITP.trans_date                    tran_date       --対象日(取引日)
                      SELECT  /*+
                                 PUSH_PRED(xitrv)
                               */
                              ITP.trans_date                    tran_date       --対象日(取引日)
-- 2019/06/15 Y.Shoji Mod End E_本稼動_15601
                             ,PHA.attribute10                   dept_code       --部署コード
                             ,PHA.vendor_id                     vendor_id       --取引先ID
                             ,IIMB.item_no                      item_code       --品目
                             ,ILTM.attribute9                   rcv_class       --仕入形態
                             ,ITP.trans_qty                     rcv_qty         --仕入数量
                             ,ROUND( PLA.unit_price * ITP.trans_qty )
                                                                rcv_price       --仕入金額( 実際単価【※発注明細のものを使用】 * 数量 )
-- 2019/06/15 Y.Shoji Mod Start E_本稼動_15601
--                             ,ROUND( ROUND( PLA.unit_price * ITP.trans_qty ) * ( TO_NUMBER( FLV01.lookup_code ) * 0.01 ) )
                             ,ROUND( ROUND( PLA.unit_price * ITP.trans_qty ) * ( TO_NUMBER( xitrv.tax ) * 0.01 ) )
-- 2019/06/15 Y.Shoji Mod End E_本稼動_15601
                                                                rcv_cn_tax      --仕入消費税( 仕入金額 * (消費税率*0.01) )
                             ,0                                 pay_qty         --有償数量
                             ,0                                 inv_price       --有償在庫金額
                             ,0                                 pay_price       --有償金額
                             ,0                                 pay_cn_tax      --有償消費税
                        FROM  ic_tran_pnd                       ITP             --保留在庫トランザクション
                             ,rcv_shipment_lines                RSL             --受入明細
                             ,po_headers_all                    PHA             --発注ヘッダ
                             ,po_lines_all                      PLA             --発注明細
                             ,ic_item_mst_b                     IIMB            --OPM品目マスタ(品目コード取得用)
                             ,ic_lots_mst                       ILTM            --ロット情報取得用
-- 2019/06/15 Y.Shoji Mod Start E_本稼動_15601
--                             ,fnd_lookup_values                 FLV01           --消費税率取得用
                             ,xxcmm_item_tax_rate_v             xitrv           --消費税率VIEW
-- 2019/06/15 Y.Shoji Mod End E_本稼動_15601
                       WHERE
                         --保留在庫トランザクションデータ取得
                              ITP.doc_type = 'PORC'                             --購買関連
                         AND  ITP.completed_ind = 1                             --完了
                         AND  ITP.trans_qty <> 0
                         --受入明細データの取得
                         AND  RSL.source_document_code = 'PO'
                         AND  ITP.doc_id = RSL.shipment_header_id
                         AND  ITP.doc_line = RSL.line_num
                         --発注･受入実績データ取得
                         AND  RSL.po_header_id = PHA.po_header_id
                         AND  RSL.po_header_id = PLA.po_header_id
                         AND  RSL.po_line_id = PLA.po_line_id
                         --品目コード取得
                         AND  ITP.item_id = IIMB.item_id
                         --ロット情報取得
                         AND  ITP.item_id = ILTM.item_id(+)
                         AND  ITP.lot_id = ILTM.lot_id(+)
                         --消費税率取得
-- 2019/06/15 Y.Shoji Mod Start E_本稼動_15601
--                         AND  FLV01.language(+) = 'JA'
--                         AND  FLV01.lookup_type(+) = 'XXCMN_CONSUMPTION_TAX_RATE'
--                         AND  NVL( FLV01.start_date_active(+), TO_DATE( '19000101', 'YYYYMMDD' ) ) <= ITP.trans_date
--                         AND  NVL( FLV01.end_date_active(+)  , TO_DATE( '99991231', 'YYYYMMDD' ) ) >= ITP.trans_date
                         AND  ITP.item_id = xitrv.item_id
-- 2019/11/11 Y.Sasaki Mod Start E_本稼動_16045
--                         AND  xitrv.start_date_active < ITP.trans_date
                         AND  xitrv.start_date_active <= ITP.trans_date
-- 2019/11/11 Y.Sasaki Mod End E_本稼動_16045
                         AND  NVL( xitrv.end_date_active ,ITP.trans_date ) >= ITP.trans_date
-- 2019/06/15 Y.Shoji Mod End E_本稼動_15601
                      -- [ 発注受入データ END ] --
                    UNION ALL
                      ----------------------------------------------
                      -- 発注あり返品･発注無し返品データ
                      --  ※帳票『仕入実績表』の消費税額と一致させる為、完了トランザクションを参照
                      --  ⇒ 数値・金額はマイナス値となる
                      ----------------------------------------------
-- 2019/06/15 Y.Shoji Mod Start E_本稼動_15601
--                      SELECT  ITC.trans_date                    tran_date       --対象日(取引日)
                      SELECT  /*+
                                 PUSH_PRED(xitrv)
                               */
                              ITC.trans_date                    tran_date       --対象日(取引日)
-- 2019/06/15 Y.Shoji Mod End E_本稼動_15601
                             ,XRRT.department_code              dept_code       --部署コード
-- 2019/06/15 Y.Shoji Del Start E_本稼動_15601
--                             ,XRRT.department_code              dept_code       --部署コード
-- 2019/06/15 Y.Shoji Del End E_本稼動_15601
                             ,XRRT.vendor_id                    vendor_id       --取引先ID
                             ,XRRT.item_code                    item_code       --品目
                             ,ILTM.attribute9                   rcv_class       --仕入形態
                              --以下の項目は『返品』なのでマイナスで計上する
                             ,ITC.trans_qty                     rcv_qty         --仕入数量
                             ,ROUND( XRRT.unit_price * ITC.trans_qty )
                                                                rcv_price       --仕入金額( 実際単価【※受入アドオンのものを使用】 * 数量 )
-- 2019/06/15 Y.Shoji Mod Start E_本稼動_15601
--                             ,ROUND( ROUND( XRRT.unit_price * ITC.trans_qty ) * ( TO_NUMBER( FLV01.lookup_code ) * 0.01 ) )
                             ,ROUND( ROUND( XRRT.unit_price * ITC.trans_qty ) * ( TO_NUMBER( xitrv.tax ) * 0.01 ) )
-- 2019/06/15 Y.Shoji Mod End E_本稼動_15601
                                                                rcv_cn_tax      --仕入消費税( 仕入金額 * (消費税率*0.01) )
                             ,0                                 pay_qty         --有償数量
                             ,0                                 inv_price       --有償在庫金額
                             ,0                                 pay_price       --有償金額
                             ,0                                 pay_cn_tax      --有償消費税
-- 2013/11/05 v1.2 Mod Start 
-- 仕入返品はバックアップされないため元テーブルを参照する
--                        FROM  xxcmn_ic_tran_cmp_arc             ITC             --OPM完了在庫トランザクション（標準）バックアップ
                        FROM  ic_tran_cmp                       ITC             --OPM完了在庫トランザクション（標準）
-- 2013/11/05 v1.2 Mod End 
                             ,ic_adjs_jnl                       IAJ             --在庫調整ジャーナル
                             ,ic_jrnl_mst                       IJM             --ジャーナルマスタ
-- 2013/06/18 D.Sugahara Mod Start E_本稼動_10839
--  発注あり返品の場合は返品元発注の納入日を消費税率適用基準日とする。
--                             ,xxpo_rcv_and_rtn_txns             XRRT            --受入返品実績
                             ,(SELECT XRRT2.txns_id                    AS txns_id         --取引ID
                                     ,XRRT2.department_code            AS department_code --部署コード
                                     ,XRRT2.vendor_id                  AS vendor_id       --取引先ID
                                     ,XRRT2.item_code                  AS item_code       --品目
                                     ,XRRT2.unit_price                 AS unit_price      --単価
                                     ,CASE WHEN XRRT2.txns_type = '3' THEN   TRUNC(XRRT2.txns_date) 
                                           ELSE FND_DATE.STRING_TO_DATE(PHA2.attribute4, 'YYYY/MM/DD') 
                                      END                             AS txns_date 
                               FROM   xxpo_rcv_and_rtn_txns  XRRT2 
                                     ,po_headers_all         PHA2 
                               WHERE  XRRT2.source_document_number = PHA2.segment1(+) 
                               )                       XRRT     -- 返品元発注データ情報
-- 2013/06/18 D.Sugahara Mod End E_本稼動_10839
                             ,ic_lots_mst                       ILTM            --ロット情報取得用
-- 2019/06/15 Y.Shoji Mod Start E_本稼動_15601
--                             ,fnd_lookup_values                 FLV01           --消費税率取得用
                             ,xxcmm_item_tax_rate_v             xitrv           --消費税率VIEW
-- 2019/06/15 Y.Shoji Mod End E_本稼動_15601
                       WHERE
                         --完了トランザクションデータ取得
                              ITC.doc_type = 'ADJI'                             --在庫調整
                         AND  ITC.reason_code = 'X201'                          --仕入先返品
                         AND  ITC.trans_qty <> 0
                         --在庫調整ジャーナルデータの取得
                         AND  ITC.doc_type = IAJ.trans_type
                         AND  ITC.doc_id = IAJ.doc_id
                         AND  ITC.doc_line = IAJ.doc_line
                         --ジャーナルマスタデータの取得
                         AND  IJM.attribute1 IS NOT NULL
                         AND  IAJ.journal_id = IJM.journal_id
                         --受入返品実績の取得
                         AND  TO_NUMBER( IJM.attribute1 ) = XRRT.txns_id        --受入実績ID
                         --ロット情報取得
                         AND  ITC.item_id = ILTM.item_id(+)
                         AND  ITC.lot_id = ILTM.lot_id(+)
                         --消費税率取得
-- 2019/06/15 Y.Shoji Mod Start E_本稼動_15601
--                         AND  FLV01.language(+) = 'JA'
--                         AND  FLV01.lookup_type(+) = 'XXCMN_CONSUMPTION_TAX_RATE'
---- 2013/06/18 D.Sugahara Mod Start E_本稼動_10839
----  発注あり返品の場合は返品元発注の納入日を消費税率適用基準日とする。
----                         AND  NVL( FLV01.start_date_active(+), TO_DATE( '19000101', 'YYYYMMDD' ) ) <= ITC.trans_date
----                         AND  NVL( FLV01.end_date_active(+)  , TO_DATE( '99991231', 'YYYYMMDD' ) ) >= ITC.trans_date
--                         AND  NVL( FLV01.start_date_active(+), TO_DATE( '19000101', 'YYYYMMDD' ) ) <= XRRT.txns_date
--                         AND  NVL( FLV01.end_date_active(+)  , TO_DATE( '99991231', 'YYYYMMDD' ) ) >= XRRT.txns_date
-- 2013/06/18 D.Sugahara Mod End E_本稼動_10839
                         AND  ITC.item_id = xitrv.item_id
-- 2019/11/11 Y.Sasaki Mod Start E_本稼動_16045
--                         AND  xitrv.start_date_active < XRRT.txns_date
                         AND  xitrv.start_date_active <= XRRT.txns_date
-- 2019/11/11 Y.Sasaki Mod End E_本稼動_16045
                         AND  NVL( xitrv.end_date_active ,XRRT.txns_date ) >= XRRT.txns_date
-- 2019/06/15 Y.Shoji Mod End E_本稼動_15601
                      -- [ 発注無し返品データ END ] --
                    UNION ALL
                      ----------------------------------------------
                      -- 有償支給データ
                      ----------------------------------------------
-- 2019/06/15 Y.Shoji Mod Start E_本稼動_15601
--                      SELECT  PAY.tran_date                     tran_date       --対象日(着荷日)
                      SELECT  /*+
                                 PUSH_PRED(xitrv)
                               */
                              PAY.tran_date                     tran_date       --対象日(着荷日)
-- 2019/06/15 Y.Shoji Mod End E_本稼動_15601
                             ,PAY.dept_code                     dept_code       --部署コード
                             ,PAY.vendor_id                     vendor_id       --取引先ID
                             ,PAY.item_code                     item_code       --品目
                             ,ILM.attribute9                    rcv_class       --仕入形態
                             ,0                                 rcv_qty         --仕入数量
                             ,0                                 rcv_price       --仕入金額
                             ,0                                 rcv_cn_tax      --仕入消費税
                              --有償数量
                             ,PAY.quantity                      pay_qty         --有償数量
                              --有償在庫金額
                             ,ROUND( DECODE( IIM.attribute15, '0', TO_NUMBER( ILM.attribute7 )  --原価管理区分が0:実勢なら在庫単価
                                                            , '1', XPH.total_amount             --原価管理区分が1:標準なら標準単価
                                                            , 0 )
                                     * PAY.quantity
                                   )                            inv_price       --有償在庫金額( 単価 * 実績数量 )
                              --有償金額
                             ,ROUND( PAY.unit_price * PAY.quantity )
                                                                pay_price       --有償金額( 実際単価 * 出荷数量 )
                              --有償消費税
-- 2019/06/15 Y.Shoji Mod Start E_本稼動_15601
--                             ,ROUND( ROUND( PAY.unit_price * PAY.quantity ) * ( TO_NUMBER( FLV02.lookup_code ) * 0.01 ) )
                             ,ROUND( ROUND( PAY.unit_price * PAY.quantity ) * ( TO_NUMBER( xitrv.tax ) * 0.01 ) )
-- 2019/06/15 Y.Shoji Mod End E_本稼動_15601
                                                                pay_cn_tax      --有償消費税( 有償金額 * (消費税率*0.01) )
                        FROM  (  --標準単価マスタとの外部結合の為、副問い合わせとする
-- 2010/01/08 T.Yoshimoto Mod Start E_本稼動#716
                                 --SELECT  NVL( XOHA.arrival_date, XOHA.shipped_date )
                                   SELECT  XOHA.arrival_date
-- 2010/01/08 T.Yoshimoto Mod End E_本稼動#716
                                                                           tran_date       --対象日(着荷日)
-- 2019/11/11 Y.Sasaki Add Start E_本稼動_16045
                                        ,NVL(XOHA.sikyu_return_date ,XOHA.arrival_date)
                                                                           base_date       --基準日
-- 2019/11/11 Y.Sasaki Add End E_本稼動_16045
                                        ,XOHA.performance_management_dept  dept_code       --部署コード
                                        ,XOHA.vendor_id                    vendor_id       --取引先ID
                                        ,XOLA.shipping_item_code           item_code       --品目コード
                                        ,XOLA.unit_price                   unit_price      --実際単価
                                        ,XMLD.item_id                      item_id         --品目ID
                                        ,XMLD.lot_id                       lot_id          --ロットID
                                        ,XMLD.actual_quantity * DECODE( OTTA.order_category_code, 'RETURN', -1, 1 )
                                                                           quantity            --実績数量（『支給返品』の場合はマイナス値となる）
                                   FROM  xxcmn_order_headers_all_arc           XOHA            --受注ヘッダ（アドオン）バックアップ
                                        ,xxcmn_order_lines_all_arc             XOLA            --受注明細（アドオン）バックアップ
                                        ,oe_transaction_types_all              OTTA            --受注タイプマスタ
                                        ,xxcmn_mov_lot_details_arc             XMLD            --移動ロット詳細（アドオン）バックアップ
                                  WHERE
                                    --支給データ取得条件
                                         OTTA.attribute1 = '2'                             --支給
                                    AND  XOHA.req_status = '08'                            --実績計上済
                                    AND  XOHA.latest_external_flag = 'Y'                   --最新フラグ:ON
                                    AND  XOHA.order_type_id = OTTA.transaction_type_id
                                    --支給明細情報取得
                                    AND  NVL( XOLA.delete_flag, 'N' ) <> 'Y'               --無効明細以外
                                    AND  XOHA.order_header_id = XOLA.order_header_id
                                    --移動ロット詳細情報取得
                                    AND  XMLD.actual_quantity <> 0
                                    AND  XMLD.document_type_code = '30'                    --支給支持
                                    AND  XMLD.record_type_code = '20'                      --出庫実績
                                    AND  XOLA.order_line_id = XMLD.mov_line_id
-- 2010/01/08 T.Yoshimoto Mod Start E_本稼動#716
                                    AND  XOHA.arrival_date IS NOT NULL
-- 2010/01/08 T.Yoshimoto Mod End E_本稼動#716
                              )                                 PAY             --支給データ
                             ,ic_item_mst_b                     IIM             --OPM品目マスタ
                             ,ic_lots_mst                       ILM             --ロット情報取得用
                             ,xxpo_price_headers                XPH             --仕入/標準単価マスタ
-- 2019/06/15 Y.Shoji Mod Start E_本稼動_15601
--                             ,fnd_lookup_values                 FLV02           --消費税率取得用
                             ,xxcmm_item_tax_rate_v             xitrv           --消費税率VIEW
-- 2019/06/15 Y.Shoji Mod End E_本稼動_15601
                       WHERE
                         --OPM品目･ロットマスタとの結合
                              PAY.item_id = IIM.item_id
                         AND  PAY.item_id = ILM.item_id
                         AND  PAY.lot_id = ILM.lot_id
                         --標準単価マスタとの結合
                         AND  XPH.price_type(+) = '2'         --標準
                         AND  PAY.item_id = XPH.item_id(+)
                         AND  PAY.tran_date >= XPH.start_date_active(+)
                         AND  PAY.tran_date <= XPH.end_date_active(+)
                         --消費税率取得
-- 2019/06/15 Y.Shoji Mod Start E_本稼動_15601
--                         AND  FLV02.language(+) = 'JA'
--                         AND  FLV02.lookup_type(+) = 'XXCMN_CONSUMPTION_TAX_RATE'
--                         AND  NVL( FLV02.start_date_active(+), TO_DATE( '19000101', 'YYYYMMDD' ) ) <= PAY.tran_date
--                         AND  NVL( FLV02.end_date_active(+)  , TO_DATE( '99991231', 'YYYYMMDD' ) ) >= PAY.tran_date
                         AND  PAY.item_id = xitrv.item_id
-- 2019/11/11 Y.Sasak Mod Start E_本稼動_16045
--                         AND  xitrv.start_date_active < PAY.tran_date
--                         AND  NVL( xitrv.end_date_active ,PAY.tran_date ) >= PAY.tran_date
                         AND  xitrv.start_date_active <= PAY.base_date
                         AND  NVL( xitrv.end_date_active ,PAY.base_date ) >= PAY.base_date
-- 2019/11/11 Y.Sasak Mod End E_本稼動_16045
-- 2019/06/15 Y.Shoji Mod End E_本稼動_15601
                      -- [ 有償支給データ END ] --
                   )                RVPY
                  ,ic_cldr_dtl    ICD    --在庫カレンダ
            WHERE  ICD.orgn_code = 'ITOE'
              AND  TO_CHAR( RVPY.tran_date, 'YYYYMM' ) = TO_CHAR( ICD.period_end_date, 'YYYYMM' )
            GROUP BY ICD.fiscal_year
                    ,RVPY.dept_code
                    ,RVPY.vendor_id
                    ,RVPY.item_code
                    ,RVPY.rcv_class
         )  SMRP
        ,xxskz_locations_v    LOCT    --部署名取得用（SYSDATEで有効データを抽出）
        ,xxskz_vendors_v      VNDR    --取引先名取得用（SYSDATEで有効データを抽出）
        ,xxskz_item_mst_v     ITEM    --品目名取得用（SYSDATEで有効データを抽出）
        ,xxskz_prod_class_v   PRODC   --商品区分取得用
        ,xxskz_item_class_v   ITEMC   --品目区分取得用
        ,xxskz_crowd_code_v   CROWD   --群コード取得用
        ,fnd_lookup_values    FLV03   --仕入形態名取得用
 WHERE
   --仕入先返品･支給先返品データとの集計により全ての集計数量がゼロとなったデータは出力しない
       (     SMRP.rcv_qty_5th  <> 0  OR  SMRP.pay_qty_5th  <> 0
         OR  SMRP.rcv_qty_6th  <> 0  OR  SMRP.pay_qty_6th  <> 0
         OR  SMRP.rcv_qty_7th  <> 0  OR  SMRP.pay_qty_7th  <> 0
         OR  SMRP.rcv_qty_8th  <> 0  OR  SMRP.pay_qty_8th  <> 0
         OR  SMRP.rcv_qty_9th  <> 0  OR  SMRP.pay_qty_9th  <> 0
         OR  SMRP.rcv_qty_10th <> 0  OR  SMRP.pay_qty_10th <> 0
         OR  SMRP.rcv_qty_11th <> 0  OR  SMRP.pay_qty_11th <> 0
         OR  SMRP.rcv_qty_12th <> 0  OR  SMRP.pay_qty_12th <> 0
         OR  SMRP.rcv_qty_1th  <> 0  OR  SMRP.pay_qty_1th  <> 0
         OR  SMRP.rcv_qty_2th  <> 0  OR  SMRP.pay_qty_2th  <> 0
         OR  SMRP.rcv_qty_3th  <> 0  OR  SMRP.pay_qty_3th  <> 0
         OR  SMRP.rcv_qty_4th  <> 0  OR  SMRP.pay_qty_4th  <> 0
       )
   --部署名取得（SYSDATEで有効データを抽出）
   AND  SMRP.dept_code = LOCT.location_code(+)
   --取引先名取得（SYSDATEで有効データを抽出）
   AND  SMRP.vendor_id = VNDR.vendor_id(+)
   --品目名取得（SYSDATEで有効データを抽出）
   AND  SMRP.item_code = ITEM.item_no(+)
   --品目カテゴリ名取得
   AND  ITEM.item_id   = PRODC.item_id(+)
   AND  ITEM.item_id   = ITEMC.item_id(+)
   AND  ITEM.item_id   = CROWD.item_id(+)
   --仕入形態名取得
   AND  FLV03.language(+)    = 'JA'
   AND  FLV03.lookup_type(+) = 'XXCMN_L05'
   AND  FLV03.lookup_code(+) = SMRP.rcv_class
/
COMMENT ON TABLE APPS.XXSKZ_仕入有償時系列_基本_V IS 'SKYLINK用 仕入有償時系列（基本）VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.年度                IS '年度'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.部署                IS '部署'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.部署名              IS '部署名'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.取引先              IS '取引先'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.取引先名            IS '取引先名'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.商品区分            IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.商品区分名          IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.品目区分            IS '品目区分'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.品目区分名          IS '品目区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.群コード            IS '群コード'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.品目コード          IS '品目コード'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.品目名              IS '品目名'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.品目略称            IS '品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.仕入形態            IS '仕入形態'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.仕入形態名          IS '仕入形態名'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.仕入数量_５月       IS '仕入数量_５月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.仕入金額_５月       IS '仕入金額_５月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.仕入消費税_５月     IS '仕入消費税_５月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.有償数量_５月       IS '有償数量_５月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.有償在庫金額_５月   IS '有償在庫金額_５月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.有償金額_５月       IS '有償金額_５月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.有償消費税_５月     IS '有償消費税_５月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.仕入数量_６月       IS '仕入数量_６月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.仕入金額_６月       IS '仕入金額_６月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.仕入消費税_６月     IS '仕入消費税_６月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.有償数量_６月       IS '有償数量_６月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.有償在庫金額_６月   IS '有償在庫金額_６月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.有償金額_６月       IS '有償金額_６月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.有償消費税_６月     IS '有償消費税_６月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.仕入数量_７月       IS '仕入数量_７月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.仕入金額_７月       IS '仕入金額_７月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.仕入消費税_７月     IS '仕入消費税_７月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.有償数量_７月       IS '有償数量_７月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.有償在庫金額_７月   IS '有償在庫金額_７月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.有償金額_７月       IS '有償金額_７月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.有償消費税_７月     IS '有償消費税_７月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.仕入数量_８月       IS '仕入数量_８月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.仕入金額_８月       IS '仕入金額_８月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.仕入消費税_８月     IS '仕入消費税_８月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.有償数量_８月       IS '有償数量_８月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.有償在庫金額_８月   IS '有償在庫金額_８月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.有償金額_８月       IS '有償金額_８月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.有償消費税_８月     IS '有償消費税_８月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.仕入数量_９月       IS '仕入数量_９月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.仕入金額_９月       IS '仕入金額_９月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.仕入消費税_９月     IS '仕入消費税_９月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.有償数量_９月       IS '有償数量_９月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.有償在庫金額_９月   IS '有償在庫金額_９月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.有償金額_９月       IS '有償金額_９月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.有償消費税_９月     IS '有償消費税_９月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.仕入数量_１０月     IS '仕入数量_１０月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.仕入金額_１０月     IS '仕入金額_１０月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.仕入消費税_１０月   IS '仕入消費税_１０月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.有償数量_１０月     IS '有償数量_１０月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.有償在庫金額_１０月 IS '有償在庫金額_１０月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.有償金額_１０月     IS '有償金額_１０月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.有償消費税_１０月   IS '有償消費税_１０月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.仕入数量_１１月     IS '仕入数量_１１月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.仕入金額_１１月     IS '仕入金額_１１月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.仕入消費税_１１月   IS '仕入消費税_１１月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.有償数量_１１月     IS '有償数量_１１月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.有償在庫金額_１１月 IS '有償在庫金額_１１月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.有償金額_１１月     IS '有償金額_１１月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.有償消費税_１１月   IS '有償消費税_１１月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.仕入数量_１２月     IS '仕入数量_１２月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.仕入金額_１２月     IS '仕入金額_１２月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.仕入消費税_１２月   IS '仕入消費税_１２月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.有償数量_１２月     IS '有償数量_１２月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.有償在庫金額_１２月 IS '有償在庫金額_１２月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.有償金額_１２月     IS '有償金額_１２月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.有償消費税_１２月   IS '有償消費税_１２月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.仕入数量_１月       IS '仕入数量_１月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.仕入金額_１月       IS '仕入金額_１月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.仕入消費税_１月     IS '仕入消費税_１月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.有償数量_１月       IS '有償数量_１月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.有償在庫金額_１月   IS '有償在庫金額_１月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.有償金額_１月       IS '有償金額_１月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.有償消費税_１月     IS '有償消費税_１月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.仕入数量_２月       IS '仕入数量_２月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.仕入金額_２月       IS '仕入金額_２月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.仕入消費税_２月     IS '仕入消費税_２月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.有償数量_２月       IS '有償数量_２月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.有償在庫金額_２月   IS '有償在庫金額_２月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.有償金額_２月       IS '有償金額_２月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.有償消費税_２月     IS '有償消費税_２月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.仕入数量_３月       IS '仕入数量_３月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.仕入金額_３月       IS '仕入金額_３月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.仕入消費税_３月     IS '仕入消費税_３月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.有償数量_３月       IS '有償数量_３月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.有償在庫金額_３月   IS '有償在庫金額_３月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.有償金額_３月       IS '有償金額_３月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.有償消費税_３月     IS '有償消費税_３月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.仕入数量_４月       IS '仕入数量_４月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.仕入金額_４月       IS '仕入金額_４月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.仕入消費税_４月     IS '仕入消費税_４月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.有償数量_４月       IS '有償数量_４月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.有償在庫金額_４月   IS '有償在庫金額_４月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.有償金額_４月       IS '有償金額_４月'
/
COMMENT ON COLUMN APPS.XXSKZ_仕入有償時系列_基本_V.有償消費税_４月     IS '有償消費税_４月'
/
