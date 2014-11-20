CREATE OR REPLACE VIEW APPS.XXSKY_仕入有償時系列_数量_V
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
,有償数量_５月
,仕入数量_６月
,有償数量_６月
,仕入数量_７月
,有償数量_７月
,仕入数量_８月
,有償数量_８月
,仕入数量_９月
,有償数量_９月
,仕入数量_１０月
,有償数量_１０月
,仕入数量_１１月
,有償数量_１１月
,仕入数量_１２月
,有償数量_１２月
,仕入数量_１月
,有償数量_１月
,仕入数量_２月
,有償数量_２月
,仕入数量_３月
,有償数量_３月
,仕入数量_４月
,有償数量_４月
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
       ,NVL( SMRP.rcv_qty_5th , 0 )       rcv_qty_5th            --仕入数量_５月
       ,NVL( SMRP.pay_qty_5th , 0 )       pay_qty_5th            --有償数量_５月
       ,NVL( SMRP.rcv_qty_6th , 0 )       rcv_qty_6th            --仕入数量_６月
       ,NVL( SMRP.pay_qty_6th , 0 )       pay_qty_6th            --有償数量_６月
       ,NVL( SMRP.rcv_qty_7th , 0 )       rcv_qty_7th            --仕入数量_７月
       ,NVL( SMRP.pay_qty_7th , 0 )       pay_qty_7th            --有償数量_７月
       ,NVL( SMRP.rcv_qty_8th , 0 )       rcv_qty_8th            --仕入数量_８月
       ,NVL( SMRP.pay_qty_8th , 0 )       pay_qty_8th            --有償数量_８月
       ,NVL( SMRP.rcv_qty_9th , 0 )       rcv_qty_9th            --仕入数量_９月
       ,NVL( SMRP.pay_qty_9th , 0 )       pay_qty_9th            --有償数量_９月
       ,NVL( SMRP.rcv_qty_10th, 0 )       rcv_qty_10th           --仕入数量_１０月
       ,NVL( SMRP.pay_qty_10th, 0 )       pay_qty_10th           --有償数量_１０月
       ,NVL( SMRP.rcv_qty_11th, 0 )       rcv_qty_11th           --仕入数量_１１月
       ,NVL( SMRP.pay_qty_11th, 0 )       pay_qty_11th           --有償数量_１１月
       ,NVL( SMRP.rcv_qty_12th, 0 )       rcv_qty_12th           --仕入数量_１２月
       ,NVL( SMRP.pay_qty_12th, 0 )       pay_qty_12th           --有償数量_１２月
       ,NVL( SMRP.rcv_qty_1th , 0 )       rcv_qty_1th            --仕入数量_１月
       ,NVL( SMRP.pay_qty_1th , 0 )       pay_qty_1th            --有償数量_１月
       ,NVL( SMRP.rcv_qty_2th , 0 )       rcv_qty_2th            --仕入数量_２月
       ,NVL( SMRP.pay_qty_2th , 0 )       pay_qty_2th            --有償数量_２月
       ,NVL( SMRP.rcv_qty_3th , 0 )       rcv_qty_3th            --仕入数量_３月
       ,NVL( SMRP.pay_qty_3th , 0 )       pay_qty_3th            --有償数量_３月
       ,NVL( SMRP.rcv_qty_4th , 0 )       rcv_qty_4th            --仕入数量_４月
       ,NVL( SMRP.pay_qty_4th , 0 )       pay_qty_4th            --有償数量_４月
  FROM  (  --年度、部署、取引先、品目、仕入形態単位で集計した（月度集計を横にした）仕入有償集計データ
           SELECT  ICD.fiscal_year                                            year             --年度
                  ,RVPY.dept_code                                             dept_code        --部署コード
                  ,RVPY.vendor_id                                             vendor_id        --取引先ID
                  ,RVPY.item_code                                             item_code        --品目
                  ,RVPY.rcv_class                                             rcv_class        --仕入形態
                  ,SUM( CASE WHEN ICD.period =  1 THEN RVPY.rcv_qty    END )  rcv_qty_5th      --仕入数量_５月
                  ,SUM( CASE WHEN ICD.period =  1 THEN RVPY.pay_qty    END )  pay_qty_5th      --有償数量_５月
                  ,SUM( CASE WHEN ICD.period =  2 THEN RVPY.rcv_qty    END )  rcv_qty_6th      --仕入数量_６月
                  ,SUM( CASE WHEN ICD.period =  2 THEN RVPY.pay_qty    END )  pay_qty_6th      --有償数量_６月
                  ,SUM( CASE WHEN ICD.period =  3 THEN RVPY.rcv_qty    END )  rcv_qty_7th      --仕入数量_７月
                  ,SUM( CASE WHEN ICD.period =  3 THEN RVPY.pay_qty    END )  pay_qty_7th      --有償数量_７月
                  ,SUM( CASE WHEN ICD.period =  4 THEN RVPY.rcv_qty    END )  rcv_qty_8th      --仕入数量_８月
                  ,SUM( CASE WHEN ICD.period =  4 THEN RVPY.pay_qty    END )  pay_qty_8th      --有償数量_８月
                  ,SUM( CASE WHEN ICD.period =  5 THEN RVPY.rcv_qty    END )  rcv_qty_9th      --仕入数量_９月
                  ,SUM( CASE WHEN ICD.period =  5 THEN RVPY.pay_qty    END )  pay_qty_9th      --有償数量_９月
                  ,SUM( CASE WHEN ICD.period =  6 THEN RVPY.rcv_qty    END )  rcv_qty_10th     --仕入数量_１０月
                  ,SUM( CASE WHEN ICD.period =  6 THEN RVPY.pay_qty    END )  pay_qty_10th     --有償数量_１０月
                  ,SUM( CASE WHEN ICD.period =  7 THEN RVPY.rcv_qty    END )  rcv_qty_11th     --仕入数量_１１月
                  ,SUM( CASE WHEN ICD.period =  7 THEN RVPY.pay_qty    END )  pay_qty_11th     --有償数量_１１月
                  ,SUM( CASE WHEN ICD.period =  8 THEN RVPY.rcv_qty    END )  rcv_qty_12th     --仕入数量_１２月
                  ,SUM( CASE WHEN ICD.period =  8 THEN RVPY.pay_qty    END )  pay_qty_12th     --有償数量_１２月
                  ,SUM( CASE WHEN ICD.period =  9 THEN RVPY.rcv_qty    END )  rcv_qty_1th      --仕入数量_１月
                  ,SUM( CASE WHEN ICD.period =  9 THEN RVPY.pay_qty    END )  pay_qty_1th      --有償数量_１月
                  ,SUM( CASE WHEN ICD.period = 10 THEN RVPY.rcv_qty    END )  rcv_qty_2th      --仕入数量_２月
                  ,SUM( CASE WHEN ICD.period = 10 THEN RVPY.pay_qty    END )  pay_qty_2th      --有償数量_２月
                  ,SUM( CASE WHEN ICD.period = 11 THEN RVPY.rcv_qty    END )  rcv_qty_3th      --仕入数量_３月
                  ,SUM( CASE WHEN ICD.period = 11 THEN RVPY.pay_qty    END )  pay_qty_3th      --有償数量_３月
                  ,SUM( CASE WHEN ICD.period = 12 THEN RVPY.rcv_qty    END )  rcv_qty_4th      --仕入数量_４月
                  ,SUM( CASE WHEN ICD.period = 12 THEN RVPY.pay_qty    END )  pay_qty_4th      --有償数量_４月
             FROM  ( --受入＋仕入返品＋有償支給の実績データをUNION ALLで取得
                      ----------------------------------------------
                      -- 発注受入データ
                      ----------------------------------------------
                      SELECT  XRRT.txns_date                    tran_date       --対象日(取引日)
                             ,XRRT.department_code              dept_code       --部署コード
                             ,XRRT.vendor_id                    vendor_id       --取引先ID
                             ,XRRT.item_code                    item_code       --品目
                             ,ILTM.attribute9                   rcv_class       --仕入形態
                             ,XRRT.quantity                     rcv_qty         --仕入数量
                             ,0                                 pay_qty         --有償数量
                        FROM  xxpo_rcv_and_rtn_txns             XRRT            --受入返品実績
                             ,po_headers_all                    PHA             --発注ヘッダ
                             ,po_lines_all                      PLA             --発注明細
                             ,ic_lots_mst                       ILTM            --ロット情報取得用
                       WHERE
                         --発注受入データの抽出
                              XRRT.txns_type = '1'
                         AND  XRRT.quantity <> 0
                         --発注明細データ取得
                         AND  NVL( PLA.attribute13, 'N' )  = 'Y'                --承諾済
                         AND  NVL( PLA.cancel_flag, 'N' ) <> 'Y'                --キャンセル以外
                         AND  PHA.po_header_id = PLA.po_header_id
                         AND  XRRT.source_document_number = PHA.segment1
                         AND  XRRT.source_document_line_num = PLA.line_num
                         --ロット情報取得
                         AND  XRRT.item_id = ILTM.item_id(+)
                         AND  XRRT.lot_id = ILTM.lot_id(+)
                      -- [ 発注受入データ END ] --
                    UNION ALL
                      ----------------------------------------------
                      -- 発注あり返品データ
                      ----------------------------------------------
                      SELECT  XRRT.txns_date                    tran_date       --対象日(取引日)
                             ,XRRT.department_code              dept_code       --部署コード
                             ,XRRT.vendor_id                    vendor_id       --取引先ID
                             ,XRRT.item_code                    item_code       --品目
                             ,ILTM.attribute9                   rcv_class       --仕入形態
                              --以下の項目は『返品』なのでマイナスで計上する
                             ,XRRT.quantity * -1                rcv_qty         --仕入数量
                             ,0                                 pay_qty         --有償数量
                        FROM  xxpo_rcv_and_rtn_txns             XRRT            --受入返品実績
                             ,po_headers_all                    PHA             --発注ヘッダ
                             ,po_lines_all                      PLA             --発注明細
                             ,ic_lots_mst                       ILTM            --ロット情報取得用
                       WHERE
                         --発注あり返品データの抽出
                              XRRT.txns_type = '2'
                         AND  XRRT.quantity <> 0
                         --発注明細データ取得
                         AND  NVL( PLA.attribute13, 'N' )  = 'Y'                --承諾済
                         AND  NVL( PLA.cancel_flag, 'N' ) <> 'Y'                --キャンセル以外
                         AND  PHA.po_header_id = PLA.po_header_id
                         AND  XRRT.source_document_number = PHA.segment1
                         AND  XRRT.source_document_line_num = PLA.line_num
                         --ロット情報取得
                         AND  XRRT.item_id = ILTM.item_id(+)
                         AND  XRRT.lot_id = ILTM.lot_id(+)
                      -- [ 発注あり返品データ END ] --
                    UNION ALL
                      ----------------------------------------------
                      -- 発注無し返品データ
                      ----------------------------------------------
                      SELECT  XRRT.txns_date                    tran_date       --対象日(取引日)
                             ,XRRT.department_code              dept_code       --部署コード
                             ,XRRT.vendor_id                    vendor_id       --取引先ID
                             ,XRRT.item_code                    item_code       --品目
                             ,ILTM.attribute9                   rcv_class       --仕入形態
                              --以下の項目は『返品』なのでマイナスで計上する
                             ,XRRT.quantity * -1                rcv_qty         --仕入数量
                             ,0                                 pay_qty         --有償数量
                        FROM  xxpo_rcv_and_rtn_txns             XRRT            --受入返品実績
                             ,ic_lots_mst                       ILTM            --ロット情報取得用
                       WHERE
                         --発注無し返品データの抽出
                              XRRT.txns_type = '3'
                         AND  XRRT.quantity <> 0
                         --ロット情報取得
                         AND  XRRT.item_id = ILTM.item_id(+)
                         AND  XRRT.lot_id = ILTM.lot_id(+)
                      -- [ 発注無し返品データ END ] --
                    UNION ALL
                      ----------------------------------------------
                      -- 有償支給データ
                      ----------------------------------------------
-- 2010/01/08 T.Yoshimoto Mod Start E_本稼動#716
                      --SELECT  NVL( XOHA.arrival_date, XOHA.shipped_date )
                      SELECT  XOHA.arrival_date
-- 2010/01/08 T.Yoshimoto Mod End E_本稼動#716
                                                                tran_date       --対象日(着荷日)
                             ,XOHA.performance_management_dept  dept_code       --部署コード
                             ,XOHA.vendor_id                    vendor_id       --取引先ID
                             ,XOLA.shipping_item_code           item_code       --品目
                             ,ILTM.attribute9                   rcv_class       --仕入形態
                             ,0                                 rcv_qty         --仕入数量
                             ,XMLD.actual_quantity * DECODE( OTTA.order_category_code, 'RETURN', -1, 1 )
                                                                pay_qty         --有償数量（『支給返品』の場合はマイナス値となる）
                        FROM  xxwsh_order_headers_all           XOHA            --受注ヘッダ
                             ,xxwsh_order_lines_all             XOLA            --受注明細
                             ,oe_transaction_types_all          OTTA            --受注タイプマスタ
                             ,xxinv_mov_lot_details             XMLD            --移動ロット詳細
                             ,ic_lots_mst                       ILTM            --ロット情報取得用
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
                         --ロット情報取得
                         AND  XMLD.item_id = ILTM.item_id(+)
                         AND  XMLD.lot_id = ILTM.lot_id(+)
-- 2010/01/08 T.Yoshimoto Mod Start E_本稼動#716
                         AND  XOHA.arrival_date IS NOT NULL
-- 2010/01/08 T.Yoshimoto Mod End E_本稼動#716
                      -- [ 有償支給データ END ] --
                   )  RVPY
                  ,ic_cldr_dtl    ICD    --在庫カレンダ
            WHERE  ICD.orgn_code = 'ITOE'
              AND  TO_CHAR( RVPY.tran_date, 'YYYYMM' ) = TO_CHAR( ICD.period_end_date, 'YYYYMM' )
            GROUP BY ICD.fiscal_year
                    ,RVPY.dept_code
                    ,RVPY.vendor_id
                    ,RVPY.item_code
                    ,RVPY.rcv_class
         )  SMRP
        ,xxsky_locations_v    LOCT    --部署名取得用（SYSDATEで有効データを抽出）
        ,xxsky_vendors_v      VNDR    --取引先名取得用（SYSDATEで有効データを抽出）
        ,xxsky_item_mst_v     ITEM    --品目名取得用（SYSDATEで有効データを抽出）
        ,xxsky_prod_class_v   PRODC   --商品区分取得用
        ,xxsky_item_class_v   ITEMC   --品目区分取得用
        ,xxsky_crowd_code_v   CROWD   --群コード取得用
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
COMMENT ON TABLE APPS.XXSKY_仕入有償時系列_数量_V IS 'SKYLINK用 仕入有償時系列（数量）VIEW'
/
COMMENT ON COLUMN APPS.XXSKY_仕入有償時系列_数量_V.年度                IS '年度'
/
COMMENT ON COLUMN APPS.XXSKY_仕入有償時系列_数量_V.部署                IS '部署'
/
COMMENT ON COLUMN APPS.XXSKY_仕入有償時系列_数量_V.部署名              IS '部署名'
/
COMMENT ON COLUMN APPS.XXSKY_仕入有償時系列_数量_V.取引先              IS '取引先'
/
COMMENT ON COLUMN APPS.XXSKY_仕入有償時系列_数量_V.取引先名            IS '取引先名'
/
COMMENT ON COLUMN APPS.XXSKY_仕入有償時系列_数量_V.商品区分            IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKY_仕入有償時系列_数量_V.商品区分名          IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKY_仕入有償時系列_数量_V.品目区分            IS '品目区分'
/
COMMENT ON COLUMN APPS.XXSKY_仕入有償時系列_数量_V.品目区分名          IS '品目区分名'
/
COMMENT ON COLUMN APPS.XXSKY_仕入有償時系列_数量_V.群コード            IS '群コード'
/
COMMENT ON COLUMN APPS.XXSKY_仕入有償時系列_数量_V.品目コード          IS '品目コード'
/
COMMENT ON COLUMN APPS.XXSKY_仕入有償時系列_数量_V.品目名              IS '品目名'
/
COMMENT ON COLUMN APPS.XXSKY_仕入有償時系列_数量_V.品目略称            IS '品目略称'
/
COMMENT ON COLUMN APPS.XXSKY_仕入有償時系列_数量_V.仕入形態            IS '仕入形態'
/
COMMENT ON COLUMN APPS.XXSKY_仕入有償時系列_数量_V.仕入形態名          IS '仕入形態名'
/
COMMENT ON COLUMN APPS.XXSKY_仕入有償時系列_数量_V.仕入数量_５月       IS '仕入数量_５月'
/
COMMENT ON COLUMN APPS.XXSKY_仕入有償時系列_数量_V.有償数量_５月       IS '有償数量_５月'
/
COMMENT ON COLUMN APPS.XXSKY_仕入有償時系列_数量_V.仕入数量_６月       IS '仕入数量_６月'
/
COMMENT ON COLUMN APPS.XXSKY_仕入有償時系列_数量_V.有償数量_６月       IS '有償数量_６月'
/
COMMENT ON COLUMN APPS.XXSKY_仕入有償時系列_数量_V.仕入数量_７月       IS '仕入数量_７月'
/
COMMENT ON COLUMN APPS.XXSKY_仕入有償時系列_数量_V.有償数量_７月       IS '有償数量_７月'
/
COMMENT ON COLUMN APPS.XXSKY_仕入有償時系列_数量_V.仕入数量_８月       IS '仕入数量_８月'
/
COMMENT ON COLUMN APPS.XXSKY_仕入有償時系列_数量_V.有償数量_８月       IS '有償数量_８月'
/
COMMENT ON COLUMN APPS.XXSKY_仕入有償時系列_数量_V.仕入数量_９月       IS '仕入数量_９月'
/
COMMENT ON COLUMN APPS.XXSKY_仕入有償時系列_数量_V.有償数量_９月       IS '有償数量_９月'
/
COMMENT ON COLUMN APPS.XXSKY_仕入有償時系列_数量_V.仕入数量_１０月     IS '仕入数量_１０月'
/
COMMENT ON COLUMN APPS.XXSKY_仕入有償時系列_数量_V.有償数量_１０月     IS '有償数量_１０月'
/
COMMENT ON COLUMN APPS.XXSKY_仕入有償時系列_数量_V.仕入数量_１１月     IS '仕入数量_１１月'
/
COMMENT ON COLUMN APPS.XXSKY_仕入有償時系列_数量_V.有償数量_１１月     IS '有償数量_１１月'
/
COMMENT ON COLUMN APPS.XXSKY_仕入有償時系列_数量_V.仕入数量_１２月     IS '仕入数量_１２月'
/
COMMENT ON COLUMN APPS.XXSKY_仕入有償時系列_数量_V.有償数量_１２月     IS '有償数量_１２月'
/
COMMENT ON COLUMN APPS.XXSKY_仕入有償時系列_数量_V.仕入数量_１月       IS '仕入数量_１月'
/
COMMENT ON COLUMN APPS.XXSKY_仕入有償時系列_数量_V.有償数量_１月       IS '有償数量_１月'
/
COMMENT ON COLUMN APPS.XXSKY_仕入有償時系列_数量_V.仕入数量_２月       IS '仕入数量_２月'
/
COMMENT ON COLUMN APPS.XXSKY_仕入有償時系列_数量_V.有償数量_２月       IS '有償数量_２月'
/
COMMENT ON COLUMN APPS.XXSKY_仕入有償時系列_数量_V.仕入数量_３月       IS '仕入数量_３月'
/
COMMENT ON COLUMN APPS.XXSKY_仕入有償時系列_数量_V.有償数量_３月       IS '有償数量_３月'
/
COMMENT ON COLUMN APPS.XXSKY_仕入有償時系列_数量_V.仕入数量_４月       IS '仕入数量_４月'
/
COMMENT ON COLUMN APPS.XXSKY_仕入有償時系列_数量_V.有償数量_４月       IS '有償数量_４月'
/
