/*************************************************************************
 * 
 * View  Name      : XXSKZ_倉替返品時系列_基本_V
 * Description     : XXSKZ_倉替返品時系列_基本_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/26    1.0   SCSK M.Nagai 初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_倉替返品時系列_基本_V
(
 年度
,拠点
,拠点名
,商品区分
,商品区分名
,品目区分
,品目区分名
,群コード
,品目
,品目名
,品目略称
,入庫倉庫
,入庫倉庫名
,倉替総数_５月
,返品総数_５月
,倉替総数_６月
,返品総数_６月
,倉替総数_７月
,返品総数_７月
,倉替総数_８月
,返品総数_８月
,倉替総数_９月
,返品総数_９月
,倉替総数_１０月
,返品総数_１０月
,倉替総数_１１月
,返品総数_１１月
,倉替総数_１２月
,返品総数_１２月
,倉替総数_１月
,返品総数_１月
,倉替総数_２月
,返品総数_２月
,倉替総数_３月
,返品総数_３月
,倉替総数_４月
,返品総数_４月
)
AS
SELECT  SMKH.year                    year             --年度
       ,SMKH.hs_branch               hs_branch        --拠点
       ,BRCH.party_name              hs_branch_name   --拠点名
       ,PRODC.prod_class_code        prod_class_code  --商品区分
       ,PRODC.prod_class_name        prod_class_name  --商品区分名
       ,ITEMC.item_class_code        item_class_code  --品目区分
       ,ITEMC.item_class_name        item_class_name  --品目区分名
       ,CROWD.crowd_code             crowd_code       --群コード
       ,SMKH.item_code               item_code        --品目
       ,ITEM.item_name               item_name        --品目名
       ,ITEM.item_short_name         item_s_name      --品目略称
       ,SMKH.dlvr_from               dlvr_from        --入庫倉庫
       ,ITMLC.description            dlvr_from_name   --入庫倉庫名
       ,NVL( SMKH.kur_qty_5th , 0 )  kur_qty_5th      --倉替総数_５月
       ,NVL( SMKH.ret_qty_5th , 0 )  ret_qty_5th      --返品総数_５月
       ,NVL( SMKH.kur_qty_6th , 0 )  kur_qty_6th      --倉替総数_６月
       ,NVL( SMKH.ret_qty_6th , 0 )  ret_qty_6th      --返品総数_６月
       ,NVL( SMKH.kur_qty_7th , 0 )  kur_qty_7th      --倉替総数_７月
       ,NVL( SMKH.ret_qty_7th , 0 )  ret_qty_7th      --返品総数_７月
       ,NVL( SMKH.kur_qty_8th , 0 )  kur_qty_8th      --倉替総数_８月
       ,NVL( SMKH.ret_qty_8th , 0 )  ret_qty_8th      --返品総数_８月
       ,NVL( SMKH.kur_qty_9th , 0 )  kur_qty_9th      --倉替総数_９月
       ,NVL( SMKH.ret_qty_9th , 0 )  ret_qty_9th      --返品総数_９月
       ,NVL( SMKH.kur_qty_10th, 0 )  kur_qty_10th     --倉替総数_１０月
       ,NVL( SMKH.ret_qty_10th, 0 )  ret_qty_10th     --返品総数_１０月
       ,NVL( SMKH.kur_qty_11th, 0 )  kur_qty_11th     --倉替総数_１１月
       ,NVL( SMKH.ret_qty_11th, 0 )  ret_qty_11th     --返品総数_１１月
       ,NVL( SMKH.kur_qty_12th, 0 )  kur_qty_12th     --倉替総数_１２月
       ,NVL( SMKH.ret_qty_12th, 0 )  ret_qty_12th     --返品総数_１２月
       ,NVL( SMKH.kur_qty_1th , 0 )  kur_qty_1th      --倉替総数_１月
       ,NVL( SMKH.ret_qty_1th , 0 )  ret_qty_1th      --返品総数_１月
       ,NVL( SMKH.kur_qty_2th , 0 )  kur_qty_2th      --倉替総数_２月
       ,NVL( SMKH.ret_qty_2th , 0 )  ret_qty_2th      --返品総数_２月
       ,NVL( SMKH.kur_qty_3th , 0 )  kur_qty_3th      --倉替総数_３月
       ,NVL( SMKH.ret_qty_3th , 0 )  ret_qty_3th      --返品総数_３月
       ,NVL( SMKH.kur_qty_4th , 0 )  kur_qty_4th      --倉替総数_４月
       ,NVL( SMKH.ret_qty_4th , 0 )  ret_qty_4th      --返品総数_４月
  FROM  (  --年度、拠点、品目、倉庫単位で集計した（月度集計を横にした）倉替返品数量集計データ
           SELECT  ICD.fiscal_year                                          year          --年度
                  ,XOHA.head_sales_branch                                   hs_branch     --拠点
                  ,XOLA.shipping_item_code                                  item_code     --出荷品目
                  ,XOHA.deliver_from                                        dlvr_from     --出荷元保管倉庫(入庫倉庫)
                   --==================================================================================
                   -- 各月集計値
                   --  ・受注タイプマスタ.ATTRIBUTE11 は『倉替』or『返品』を判断
                   --  ・取消しのデータ(受注タイプマスタ.ORDER_CATEGORY_CODE = 'ORDER')はマイナス値となる
                   --==================================================================================
                   --５月集計
                  ,SUM( CASE WHEN ICD.period =  1 AND OTTA.attribute11 = '03' THEN XOLA.shipped_quantity * DECODE( OTTA.order_category_code, 'ORDER', -1, 1 ) END ) kur_qty_5th  --倉替総数_５月
                  ,SUM( CASE WHEN ICD.period =  1 AND OTTA.attribute11 = '04' THEN XOLA.shipped_quantity * DECODE( OTTA.order_category_code, 'ORDER', -1, 1 ) END ) ret_qty_5th  --返品総数_５月
                   --６月集計
                  ,SUM( CASE WHEN ICD.period =  2 AND OTTA.attribute11 = '03' THEN XOLA.shipped_quantity * DECODE( OTTA.order_category_code, 'ORDER', -1, 1 ) END ) kur_qty_6th  --倉替総数_６月
                  ,SUM( CASE WHEN ICD.period =  2 AND OTTA.attribute11 = '04' THEN XOLA.shipped_quantity * DECODE( OTTA.order_category_code, 'ORDER', -1, 1 ) END ) ret_qty_6th  --返品総数_６月
                   --７月集計
                  ,SUM( CASE WHEN ICD.period =  3 AND OTTA.attribute11 = '03' THEN XOLA.shipped_quantity * DECODE( OTTA.order_category_code, 'ORDER', -1, 1 ) END ) kur_qty_7th  --倉替総数_７月
                  ,SUM( CASE WHEN ICD.period =  3 AND OTTA.attribute11 = '04' THEN XOLA.shipped_quantity * DECODE( OTTA.order_category_code, 'ORDER', -1, 1 ) END ) ret_qty_7th  --返品総数_７月
                   --８月集計
                  ,SUM( CASE WHEN ICD.period =  4 AND OTTA.attribute11 = '03' THEN XOLA.shipped_quantity * DECODE( OTTA.order_category_code, 'ORDER', -1, 1 ) END ) kur_qty_8th  --倉替総数_８月
                  ,SUM( CASE WHEN ICD.period =  4 AND OTTA.attribute11 = '04' THEN XOLA.shipped_quantity * DECODE( OTTA.order_category_code, 'ORDER', -1, 1 ) END ) ret_qty_8th  --返品総数_８月
                   --９月集計
                  ,SUM( CASE WHEN ICD.period =  5 AND OTTA.attribute11 = '03' THEN XOLA.shipped_quantity * DECODE( OTTA.order_category_code, 'ORDER', -1, 1 ) END ) kur_qty_9th  --倉替総数_９月
                  ,SUM( CASE WHEN ICD.period =  5 AND OTTA.attribute11 = '04' THEN XOLA.shipped_quantity * DECODE( OTTA.order_category_code, 'ORDER', -1, 1 ) END ) ret_qty_9th  --返品総数_９月
                   --１０月集計
                  ,SUM( CASE WHEN ICD.period =  6 AND OTTA.attribute11 = '03' THEN XOLA.shipped_quantity * DECODE( OTTA.order_category_code, 'ORDER', -1, 1 ) END ) kur_qty_10th --倉替総数_１０月
                  ,SUM( CASE WHEN ICD.period =  6 AND OTTA.attribute11 = '04' THEN XOLA.shipped_quantity * DECODE( OTTA.order_category_code, 'ORDER', -1, 1 ) END ) ret_qty_10th --返品総数_１０月
                   --１１月集計
                  ,SUM( CASE WHEN ICD.period =  7 AND OTTA.attribute11 = '03' THEN XOLA.shipped_quantity * DECODE( OTTA.order_category_code, 'ORDER', -1, 1 ) END ) kur_qty_11th --倉替総数_１１月
                  ,SUM( CASE WHEN ICD.period =  7 AND OTTA.attribute11 = '04' THEN XOLA.shipped_quantity * DECODE( OTTA.order_category_code, 'ORDER', -1, 1 ) END ) ret_qty_11th --返品総数_１１月
                   --１２月集計
                  ,SUM( CASE WHEN ICD.period =  8 AND OTTA.attribute11 = '03' THEN XOLA.shipped_quantity * DECODE( OTTA.order_category_code, 'ORDER', -1, 1 ) END ) kur_qty_12th --倉替総数_１２月
                  ,SUM( CASE WHEN ICD.period =  8 AND OTTA.attribute11 = '04' THEN XOLA.shipped_quantity * DECODE( OTTA.order_category_code, 'ORDER', -1, 1 ) END ) ret_qty_12th --返品総数_１２月
                   --１月集計
                  ,SUM( CASE WHEN ICD.period =  9 AND OTTA.attribute11 = '03' THEN XOLA.shipped_quantity * DECODE( OTTA.order_category_code, 'ORDER', -1, 1 ) END ) kur_qty_1th  --倉替総数_１月
                  ,SUM( CASE WHEN ICD.period =  9 AND OTTA.attribute11 = '04' THEN XOLA.shipped_quantity * DECODE( OTTA.order_category_code, 'ORDER', -1, 1 ) END ) ret_qty_1th  --返品総数_１月
                   --２月集計
                  ,SUM( CASE WHEN ICD.period = 10 AND OTTA.attribute11 = '03' THEN XOLA.shipped_quantity * DECODE( OTTA.order_category_code, 'ORDER', -1, 1 ) END ) kur_qty_2th  --倉替総数_２月
                  ,SUM( CASE WHEN ICD.period = 10 AND OTTA.attribute11 = '04' THEN XOLA.shipped_quantity * DECODE( OTTA.order_category_code, 'ORDER', -1, 1 ) END ) ret_qty_2th  --返品総数_２月
                   --３月集計
                  ,SUM( CASE WHEN ICD.period = 11 AND OTTA.attribute11 = '03' THEN XOLA.shipped_quantity * DECODE( OTTA.order_category_code, 'ORDER', -1, 1 ) END ) kur_qty_3th  --倉替総数_３月
                  ,SUM( CASE WHEN ICD.period = 11 AND OTTA.attribute11 = '04' THEN XOLA.shipped_quantity * DECODE( OTTA.order_category_code, 'ORDER', -1, 1 ) END ) ret_qty_3th  --返品総数_３月
                   --４月集計
                  ,SUM( CASE WHEN ICD.period = 12 AND OTTA.attribute11 = '03' THEN XOLA.shipped_quantity * DECODE( OTTA.order_category_code, 'ORDER', -1, 1 ) END ) kur_qty_4th  --倉替総数_４月
                  ,SUM( CASE WHEN ICD.period = 12 AND OTTA.attribute11 = '04' THEN XOLA.shipped_quantity * DECODE( OTTA.order_category_code, 'ORDER', -1, 1 ) END ) ret_qty_4th  --返品総数_４月
             FROM  ic_cldr_dtl                  ICD     --在庫カレンダ
                  ,xxcmn_order_headers_all_arc  XOHA    --受注ヘッダ（アドオン）バックアップ
                  ,xxcmn_order_lines_all_arc    XOLA    --受注明細（アドオン）バックアップ
                  ,oe_transaction_types_all     OTTA    --受注タイプマスタ
            WHERE
              --倉替返品データ抽出条件
                   OTTA.attribute1 = '3'                                       --倉替返品
              AND  XOHA.req_status = '04'                                      --実績計上済
              AND  XOHA.latest_external_flag = 'Y'
              AND  XOHA.order_type_id = OTTA.transaction_type_id
              --明細データ抽出条件
              AND  XOLA.shipped_quantity <> 0
              AND  NVL( XOLA.delete_flag, 'N' ) <> 'Y'                         --無効明細以外
              AND  XOHA.order_header_id = XOLA.order_header_id
              --在庫カレンダとの結合条件
              AND  ICD.orgn_code = 'ITOE'
              AND  TO_CHAR( NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ), 'YYYYMM' ) = TO_CHAR( ICD.period_end_date, 'YYYYMM' )
           GROUP BY  ICD.fiscal_year            --年度
                    ,XOHA.head_sales_branch     --拠点
                    ,XOLA.shipping_item_code    --出荷品目
                    ,XOHA.deliver_from          --出荷元保管倉庫(入庫倉庫)
        )  SMKH
        ,xxskz_cust_accounts_v    BRCH    --拠点名取得（SYSDATEで有効データを抽出）
        ,xxskz_item_mst_v         ITEM    --品目名取得用（SYSDATEで有効データを抽出）
        ,xxskz_prod_class_v       PRODC   --商品区分取得用
        ,xxskz_item_class_v       ITEMC   --品目区分取得用
        ,xxskz_crowd_code_v       CROWD   --群コード取得用
        ,xxskz_item_locations_v   ITMLC   --保管倉庫名取得用
 WHERE
   --取消データとの集計により全ての集計数量がゼロとなったデータは出力しない
       (     SMKH.kur_qty_5th  <> 0  OR  SMKH.ret_qty_5th  <> 0
         OR  SMKH.kur_qty_6th  <> 0  OR  SMKH.ret_qty_6th  <> 0
         OR  SMKH.kur_qty_7th  <> 0  OR  SMKH.ret_qty_7th  <> 0
         OR  SMKH.kur_qty_8th  <> 0  OR  SMKH.ret_qty_8th  <> 0
         OR  SMKH.kur_qty_9th  <> 0  OR  SMKH.ret_qty_9th  <> 0
         OR  SMKH.kur_qty_10th <> 0  OR  SMKH.ret_qty_10th <> 0
         OR  SMKH.kur_qty_11th <> 0  OR  SMKH.ret_qty_11th <> 0
         OR  SMKH.kur_qty_12th <> 0  OR  SMKH.ret_qty_12th <> 0
         OR  SMKH.kur_qty_1th  <> 0  OR  SMKH.ret_qty_1th  <> 0
         OR  SMKH.kur_qty_2th  <> 0  OR  SMKH.ret_qty_2th  <> 0
         OR  SMKH.kur_qty_3th  <> 0  OR  SMKH.ret_qty_3th  <> 0
         OR  SMKH.kur_qty_4th  <> 0  OR  SMKH.ret_qty_4th  <> 0
       )
   --拠点名取得
   AND  SMKH.hs_branch = BRCH.party_number(+)
   --品目名取得
   AND  SMKH.item_code = ITEM.item_no(+)
   --品目カテゴリ名取得
   AND  ITEM.item_id   = PRODC.item_id(+)
   AND  ITEM.item_id   = ITEMC.item_id(+)
   AND  ITEM.item_id   = CROWD.item_id(+)
   --出荷元保管倉庫名取得
   AND  SMKH.dlvr_from = ITMLC.segment1(+)
/
COMMENT ON TABLE APPS.XXSKZ_倉替返品時系列_基本_V IS 'SKYLINK用 倉替返品時系列（基本）VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品時系列_基本_V.年度 IS '年度'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品時系列_基本_V.拠点 IS '拠点'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品時系列_基本_V.拠点名 IS '拠点名'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品時系列_基本_V.商品区分 IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品時系列_基本_V.商品区分名 IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品時系列_基本_V.品目区分 IS '品目区分'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品時系列_基本_V.品目区分名 IS '品目区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品時系列_基本_V.群コード IS '群コード'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品時系列_基本_V.品目 IS '品目'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品時系列_基本_V.品目名 IS '品目名'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品時系列_基本_V.品目略称 IS '品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品時系列_基本_V.入庫倉庫 IS '入庫倉庫'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品時系列_基本_V.入庫倉庫名 IS '入庫倉庫名'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品時系列_基本_V.倉替総数_５月 IS '倉替総数_５月'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品時系列_基本_V.返品総数_５月 IS '返品総数_５月'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品時系列_基本_V.倉替総数_６月 IS '倉替総数_６月'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品時系列_基本_V.返品総数_６月 IS '返品総数_６月'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品時系列_基本_V.倉替総数_７月 IS '倉替総数_７月'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品時系列_基本_V.返品総数_７月 IS '返品総数_７月'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品時系列_基本_V.倉替総数_８月 IS '倉替総数_８月'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品時系列_基本_V.返品総数_８月 IS '返品総数_８月'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品時系列_基本_V.倉替総数_９月 IS '倉替総数_９月'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品時系列_基本_V.返品総数_９月 IS '返品総数_９月'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品時系列_基本_V.倉替総数_１０月 IS '倉替総数_１０月'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品時系列_基本_V.返品総数_１０月 IS '返品総数_１０月'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品時系列_基本_V.倉替総数_１１月 IS '倉替総数_１１月'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品時系列_基本_V.返品総数_１１月 IS '返品総数_１１月'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品時系列_基本_V.倉替総数_１２月 IS '倉替総数_１２月'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品時系列_基本_V.返品総数_１２月 IS '返品総数_１２月'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品時系列_基本_V.倉替総数_１月 IS '倉替総数_１月'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品時系列_基本_V.返品総数_１月 IS '返品総数_１月'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品時系列_基本_V.倉替総数_２月 IS '倉替総数_２月'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品時系列_基本_V.返品総数_２月 IS '返品総数_２月'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品時系列_基本_V.倉替総数_３月 IS '倉替総数_３月'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品時系列_基本_V.返品総数_３月 IS '返品総数_３月'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品時系列_基本_V.倉替総数_４月 IS '倉替総数_４月'
/
COMMENT ON COLUMN APPS.XXSKZ_倉替返品時系列_基本_V.返品総数_４月 IS '返品総数_４月'
/
