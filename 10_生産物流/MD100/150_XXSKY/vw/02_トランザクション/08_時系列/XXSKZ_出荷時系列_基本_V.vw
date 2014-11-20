/*************************************************************************
 * 
 * View  Name      : XXSKZ_出荷時系列_基本_V
 * Description     : XXSKZ_出荷時系列_基本_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/26    1.0   SCSK M.Nagai 初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_出荷時系列_基本_V
(
 年度
,部署
,部署名
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
,出荷倉庫
,出荷倉庫名
,出荷総数_５月
,出荷総数_６月
,出荷総数_７月
,出荷総数_８月
,出荷総数_９月
,出荷総数_１０月
,出荷総数_１１月
,出荷総数_１２月
,出荷総数_１月
,出荷総数_２月
,出荷総数_３月
,出荷総数_４月
)
AS
SELECT  SMSP.year                     year             --年度
       ,SMSP.pm_dept                  pm_dept          --部署
       ,LOCT.location_name            pm_dept_name     --部署名
       ,SMSP.hs_branch                hs_branch        --拠点
       ,BRCH.party_name               hs_branch_name   --拠点名
       ,PRODC.prod_class_code         prod_class_code  --商品区分
       ,PRODC.prod_class_name         prod_class_name  --商品区分名
       ,ITEMC.item_class_code         item_class_code  --品目区分
       ,ITEMC.item_class_name         item_class_name  --品目区分名
       ,CROWD.crowd_code              crowd_code       --群コード
       ,SMSP.item_code                item_code        --品目
       ,ITEM.item_name                item_name        --品目名
       ,ITEM.item_short_name          item_s_name      --品目略称
       ,SMSP.dlvr_from                dlvr_from        --出荷倉庫
       ,ITMLC.description             dlvr_from_name   --出荷倉庫名
       ,NVL( SMSP.ship_qty_5th , 0 )  ship_qty_5th     --出荷総数_５月
       ,NVL( SMSP.ship_qty_6th , 0 )  ship_qty_6th     --出荷総数_６月
       ,NVL( SMSP.ship_qty_7th , 0 )  ship_qty_7th     --出荷総数_７月
       ,NVL( SMSP.ship_qty_8th , 0 )  ship_qty_8th     --出荷総数_８月
       ,NVL( SMSP.ship_qty_9th , 0 )  ship_qty_9th     --出荷総数_９月
       ,NVL( SMSP.ship_qty_10th, 0 )  ship_qty_10th    --出荷総数_１０月
       ,NVL( SMSP.ship_qty_11th, 0 )  ship_qty_11th    --出荷総数_１１月
       ,NVL( SMSP.ship_qty_12th, 0 )  ship_qty_12th    --出荷総数_１２月
       ,NVL( SMSP.ship_qty_1th , 0 )  ship_qty_1th     --出荷総数_１月
       ,NVL( SMSP.ship_qty_2th , 0 )  ship_qty_2th     --出荷総数_２月
       ,NVL( SMSP.ship_qty_3th , 0 )  ship_qty_3th     --出荷総数_３月
       ,NVL( SMSP.ship_qty_4th , 0 )  ship_qty_4th     --出荷総数_４月
  FROM  (  --年度、部署、拠点、出荷品目、倉庫単位で集計した（月度集計を横にした）出荷数量集計データ
           SELECT  ICD.fiscal_year                                                  year           --年度
                  ,XOHA.performance_management_dept                                 pm_dept        --部署
                  ,XOHA.head_sales_branch                                           hs_branch      --拠点
                  ,XOLA.request_item_code                                           item_code      --依頼品目
                  ,XOHA.deliver_from                                                dlvr_from      --出荷元保管倉庫
                   --出荷総数５月～４月
                  ,SUM( CASE WHEN ICD.period =  1 THEN XOLA.shipped_quantity END )  ship_qty_5th   --出荷総数_５月
                  ,SUM( CASE WHEN ICD.period =  2 THEN XOLA.shipped_quantity END )  ship_qty_6th   --出荷総数_６月
                  ,SUM( CASE WHEN ICD.period =  3 THEN XOLA.shipped_quantity END )  ship_qty_7th   --出荷総数_７月
                  ,SUM( CASE WHEN ICD.period =  4 THEN XOLA.shipped_quantity END )  ship_qty_8th   --出荷総数_８月
                  ,SUM( CASE WHEN ICD.period =  5 THEN XOLA.shipped_quantity END )  ship_qty_9th   --出荷総数_９月
                  ,SUM( CASE WHEN ICD.period =  6 THEN XOLA.shipped_quantity END )  ship_qty_10th  --出荷総数_１０月
                  ,SUM( CASE WHEN ICD.period =  7 THEN XOLA.shipped_quantity END )  ship_qty_11th  --出荷総数_１１月
                  ,SUM( CASE WHEN ICD.period =  8 THEN XOLA.shipped_quantity END )  ship_qty_12th  --出荷総数_１２月
                  ,SUM( CASE WHEN ICD.period =  9 THEN XOLA.shipped_quantity END )  ship_qty_1th   --出荷総数_１月
                  ,SUM( CASE WHEN ICD.period = 10 THEN XOLA.shipped_quantity END )  ship_qty_2th   --出荷総数_２月
                  ,SUM( CASE WHEN ICD.period = 11 THEN XOLA.shipped_quantity END )  ship_qty_3th   --出荷総数_３月
                  ,SUM( CASE WHEN ICD.period = 12 THEN XOLA.shipped_quantity END )  ship_qty_4th   --出荷総数_４月
             FROM  ic_cldr_dtl                  ICD     --在庫カレンダ
                  ,xxcmn_order_headers_all_arc  XOHA    --受注ヘッダ（アドオン）バックアップ
                  ,xxcmn_order_lines_all_arc    XOLA    --受注明細（アドオン）バックアップ
                  ,oe_transaction_types_all     OTTA    --受注タイプマスタ
            WHERE
              --出荷データ抽出条件
                   OTTA.attribute1 = '1'                                      --出荷
              AND  OTTA.attribute4 = '1'                                      --通常出荷(見本、廃棄を除く)
              AND  OTTA.order_category_code = 'ORDER'
              AND  XOHA.req_status = '04'                                     --実績計上済
              AND  XOHA.latest_external_flag = 'Y'
              AND  XOHA.order_type_id = OTTA.transaction_type_id
              --明細データ抽出条件
              AND  XOLA.shipped_quantity <> 0
              AND  NVL( XOLA.delete_flag, 'N' ) <> 'Y'                        --無効明細以外
              AND  XOHA.order_header_id = XOLA.order_header_id
              --在庫カレンダとの結合条件
              AND  ICD.orgn_code = 'ITOE'
              AND  TO_CHAR( NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ), 'YYYYMM' ) = TO_CHAR( ICD.period_end_date, 'YYYYMM' )
            GROUP BY ICD.fiscal_year
                    ,XOHA.performance_management_dept
                    ,XOHA.head_sales_branch
                    ,XOLA.request_item_code
                    ,XOHA.deliver_from
         )  SMSP                          --出荷数量月次集計
        ,xxskz_locations_v        LOCT    --部署名取得用（SYSDATEで有効データを抽出）
        ,xxskz_cust_accounts_v    BRCH    --拠点名取得用（SYSDATEで有効データを抽出）
        ,xxskz_item_mst_v         ITEM    --品目名取得用（SYSDATEで有効データを抽出）
        ,xxskz_prod_class_v       PRODC   --商品区分取得用
        ,xxskz_item_class_v       ITEMC   --品目区分取得用
        ,xxskz_crowd_code_v       CROWD   --群コード取得用
        ,xxskz_item_locations_v   ITMLC   --保管倉庫名取得用
 WHERE
   --部署名取得
        SMSP.pm_dept   = LOCT.location_code(+)
   --拠点名取得
   AND  SMSP.hs_branch = BRCH.party_number(+)
   --品目名取得
   AND  SMSP.item_code = ITEM.item_no(+)
   --品目カテゴリ名取得
   AND  ITEM.item_id   = PRODC.item_id(+)
   AND  ITEM.item_id   = ITEMC.item_id(+)
   AND  ITEM.item_id   = CROWD.item_id(+)
   --出荷元保管倉庫名取得
   AND  SMSP.dlvr_from = ITMLC.segment1(+)
/
COMMENT ON TABLE APPS.XXSKZ_出荷時系列_基本_V IS 'SKYLINK用 出荷時系列（基本）VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷時系列_基本_V.年度 IS '年度'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷時系列_基本_V.部署 IS '部署'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷時系列_基本_V.部署名 IS '部署名'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷時系列_基本_V.拠点 IS '拠点'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷時系列_基本_V.拠点名 IS '拠点名'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷時系列_基本_V.商品区分 IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷時系列_基本_V.商品区分名 IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷時系列_基本_V.品目区分 IS '品目区分'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷時系列_基本_V.品目区分名 IS '品目区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷時系列_基本_V.群コード IS '群コード'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷時系列_基本_V.品目 IS '品目'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷時系列_基本_V.品目名 IS '品目名'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷時系列_基本_V.品目略称 IS '品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷時系列_基本_V.出荷倉庫 IS '出荷倉庫'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷時系列_基本_V.出荷倉庫名 IS '出荷倉庫名'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷時系列_基本_V.出荷総数_５月 IS '出荷総数_５月'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷時系列_基本_V.出荷総数_６月 IS '出荷総数_６月'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷時系列_基本_V.出荷総数_７月 IS '出荷総数_７月'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷時系列_基本_V.出荷総数_８月 IS '出荷総数_８月'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷時系列_基本_V.出荷総数_９月 IS '出荷総数_９月'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷時系列_基本_V.出荷総数_１０月 IS '出荷総数_１０月'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷時系列_基本_V.出荷総数_１１月 IS '出荷総数_１１月'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷時系列_基本_V.出荷総数_１２月 IS '出荷総数_１２月'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷時系列_基本_V.出荷総数_１月 IS '出荷総数_１月'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷時系列_基本_V.出荷総数_２月 IS '出荷総数_２月'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷時系列_基本_V.出荷総数_３月 IS '出荷総数_３月'
/
COMMENT ON COLUMN APPS.XXSKZ_出荷時系列_基本_V.出荷総数_４月 IS '出荷総数_４月'
/
