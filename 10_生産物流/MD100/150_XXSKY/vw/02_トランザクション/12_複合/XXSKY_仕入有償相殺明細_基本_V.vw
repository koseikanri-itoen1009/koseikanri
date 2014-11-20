CREATE OR REPLACE VIEW APPS.XXSKY_仕入有償相殺明細_基本_V
(
 年月
,成績管理部署
,成績管理部署名
,商品区分
,商品区分名
,品目区分
,品目区分名
,取引先
,取引先名
,仕入金額
,有償金額_原料
,有償金額_資材
,有償金額_合計
,支払金額
)
AS
SELECT
        XRO.yyyymm                                          yyyymm              --年月
       ,XRO.department_code                                 department_code     --成績管理部署
       ,XLV.location_name                                   location_name       --成績管理部署名
       ,XRO.prod_class_code                                 prod_class_code     --商品区分
       ,XRO.prod_class_name                                 prod_class_name     --商品区分名
       ,XRO.item_class_code                                 item_class_code     --品目区分
       ,XRO.item_class_name                                 item_class_name     --品目区分名
       ,XRO.vendor_code                                     vendor_code         --取引先
       ,XVV.vendor_name                                     vendor_name         --取引先名
       ,SUM( NVL( XRO.rcv_price    , 0 ) )                  rcv_price           --仕入金額
       ,SUM( NVL( XRO.pay_price_gen, 0 ) )                  pay_price_gen       --有償金額_原料
       ,SUM( NVL( XRO.pay_price_szi, 0 ) )                  pay_price_szi       --有償金額_資材
       ,SUM( NVL( XRO.pay_price_gen, 0 ) + NVL( XRO.pay_price_szi, 0 ) )
                                                            pay_price_total     --有償金額_合計（有償金額_原料 ＋ 有償金額_資材）
       ,SUM( NVL( XRO.rcv_price    , 0 )
              - ( NVL( XRO.pay_price_gen, 0 ) + NVL( XRO.pay_price_szi, 0 ) ) )
                                                            sihr_price          --支払金額（仕入金額 － 有償金額_合計）
  FROM
       ( --受入＋仕入返品＋有償支給の実績データをUNION ALLで取得
          -------------------------------------------------------------------
          -- 発注・受入データ
          -------------------------------------------------------------------
          SELECT
                  TO_CHAR( txns_date, 'YYYYMM' )            yyyymm              --年月
                 ,XRART.department_code                     department_code     --部署コード
                 ,XRART.vendor_code                         vendor_code         --取引先コード
                 ,PRODC.prod_class_code                     prod_class_code     --商品区分
                 ,PRODC.prod_class_name                     prod_class_name     --商品区分名
                 ,ITEMC.item_class_code                     item_class_code     --品目区分
                 ,ITEMC.item_class_name                     item_class_name     --品目区分名
                 ,ROUND( PLA.unit_price * XRART.quantity )  rcv_price           --仕入金額 （※単価は発注明細のものを使用）
                 ,0                                         pay_price_gen       --有償金額_原料
                 ,0                                         pay_price_szi       --有償金額_資材
            FROM
                  xxpo_rcv_and_rtn_txns                     XRART               --受入返品実績アドオン
                 ,po_headers_all                            PHA                 --発注ヘッダ
                 ,po_lines_all                              PLA                 --発注明細
                 ,xxsky_prod_class_v                        PRODC               --商品区分取得用
                 ,xxsky_item_class_v                        ITEMC               --品目区分取得用
           WHERE
             --発注受入データの抽出
                  XRART.txns_type                           = '1'               --'1:受入実績'
             AND  XRART.quantity                           <> 0
             --発注データとの結合
             AND  NVL( PLA.cancel_flag, 'N' )              <> 'Y'               --キャンセル以外
             AND  NVL( PLA.attribute13, 'N' )               = 'Y'               --承諾済
             AND  XRART.source_document_number              = PHA.segment1
             AND  XRART.source_document_line_num            = PLA.line_num
             AND  PHA.po_header_id                          = PLA.po_header_id
             --品目カテゴリ情報取得
-- 2010/01/08 T.Yoshimoto Mod Start E_本稼動#716
             --AND  XRART.item_id                             = PRODC.item_id(+)  --商品区分情報取得
             --AND  XRART.item_id                             = ITEMC.item_id(+)  --品目区分情報取得
             AND  XRART.item_id                             = PRODC.item_id     --商品区分情報取得
             AND  XRART.item_id                             = ITEMC.item_id     --品目区分情報取得
             AND  PRODC.item_id                             = ITEMC.item_id
-- 2010/01/08 T.Yoshimoto Mod End E_本稼動#716
          --[ 発注・受入データ  END ]--
        UNION ALL
          -------------------------------------------------------------------
          -- 発注あり返品データ（仕入金額はマイナス値となる）
          -------------------------------------------------------------------
          SELECT
                  TO_CHAR( txns_date, 'YYYYMM' )            yyyymm              --年月
                 ,XRART.department_code                     department_code     --部署コード
                 ,XRART.vendor_code                         vendor_code         --取引先コード
                 ,PRODC.prod_class_code                     prod_class_code     --商品区分
                 ,PRODC.prod_class_name                     prod_class_name     --商品区分名
                 ,ITEMC.item_class_code                     item_class_code     --品目区分
                 ,ITEMC.item_class_name                     item_class_name     --品目区分名
                 ,ROUND( ( XRART.unit_price * XRART.quantity ) * -1 )
                                                            rcv_price           --仕入金額 （※単価は受入返品アドオンのものを使用）
                 ,0                                         pay_price_gen       --有償金額_原料
                 ,0                                         pay_price_szi       --有償金額_資材
            FROM
                  xxpo_rcv_and_rtn_txns                     XRART               --受入返品実績アドオン
                 ,po_headers_all                            PHA                 --発注ヘッダ
                 ,po_lines_all                              PLA                 --発注明細
                 ,xxsky_prod_class_v                        PRODC               --商品区分取得用
                 ,xxsky_item_class_v                        ITEMC               --品目区分取得用
           WHERE
             --発注あり返品データの抽出
                  XRART.txns_type                           = '2'               --'2:発注あり返品'
             AND  XRART.quantity                           <> 0
             --発注データとの結合
             AND  NVL( PLA.cancel_flag, 'N' )              <> 'Y'               --キャンセル以外
             AND  NVL( PLA.attribute13, 'N' )               = 'Y'               --承諾済
             AND  XRART.source_document_number              = PHA.segment1
             AND  XRART.source_document_line_num            = PLA.line_num
             AND  PHA.po_header_id                          = PLA.po_header_id
             --品目カテゴリ情報取得
-- 2010/01/08 T.Yoshimoto Mod Start E_本稼動#716
             --AND  XRART.item_id                             = PRODC.item_id(+)  --商品区分情報取得
             --AND  XRART.item_id                             = ITEMC.item_id(+)  --品目区分情報取得
             AND  XRART.item_id                             = PRODC.item_id     --商品区分情報取得
             AND  XRART.item_id                             = ITEMC.item_id     --品目区分情報取得
             AND  PRODC.item_id                             = ITEMC.item_id
-- 2010/01/08 T.Yoshimoto Mod End E_本稼動#716
          --[ 発注あり返品データ  END ]--
        UNION ALL
          -------------------------------------------------------------------
          -- 発注無し返品データ（仕入金額はマイナス値となる）
          -------------------------------------------------------------------
          SELECT
                  TO_CHAR( txns_date, 'YYYYMM' )            yyyymm              --年月
                 ,XRART.department_code                     department_code     --部署コード
                 ,XRART.vendor_code                         vendor_code         --取引先コード
                 ,PRODC.prod_class_code                     prod_class_code     --商品区分
                 ,PRODC.prod_class_name                     prod_class_name     --商品区分名
                 ,ITEMC.item_class_code                     item_class_code     --品目区分
                 ,ITEMC.item_class_name                     item_class_name     --品目区分名
                 ,ROUND( ( XRART.unit_price * XRART.quantity ) * -1 )
                                                            rcv_price           --仕入金額 （※単価は受入返品アドオンのものを使用）
                 ,0                                         pay_price_gen       --有償金額_原料
                 ,0                                         pay_price_szi       --有償金額_資材
            FROM
                  xxpo_rcv_and_rtn_txns                     XRART               --受入返品実績アドオン
                 ,xxsky_prod_class_v                        PRODC               --商品区分取得用
                 ,xxsky_item_class_v                        ITEMC               --品目区分取得用
           WHERE
             --発注無し返品データの抽出
                  XRART.txns_type                           = '3'               --'3:発注無し返品'
             AND  XRART.quantity                           <> 0
             --品目カテゴリ情報取得
-- 2010/01/08 T.Yoshimoto Mod Start E_本稼動#716
             --AND  XRART.item_id                             = PRODC.item_id(+)  --商品区分情報取得
             --AND  XRART.item_id                             = ITEMC.item_id(+)  --品目区分情報取得
             AND  XRART.item_id                             = PRODC.item_id     --商品区分情報取得
             AND  XRART.item_id                             = ITEMC.item_id     --品目区分情報取得
             AND  PRODC.item_id                             = ITEMC.item_id
-- 2010/01/08 T.Yoshimoto Mod End E_本稼動#716
          --[ 発注無し返品データ  END ]--
        UNION ALL
          -------------------------------------------------------------------
          -- 有償支給データ（原料<資材以外> or 資材 の金額【単価×数量】を取得する）
          -------------------------------------------------------------------
          SELECT
-- 2010/01/08 T.Yoshimoto Mod Start E_本稼動#716
                  --TO_CHAR( NVL( XOHA.arrival_date, XOHA.shipped_date ), 'YYYYMM' )
                  TO_CHAR( XOHA.arrival_date, 'YYYYMM' )
-- 2010/01/08 T.Yoshimoto Mod End E_本稼動#716
                                                            yyyymm              --年月（着荷日がNULL時は出荷日）
                 ,XOHA.performance_management_dept          department_code     --成績管理部署
                 ,XOHA.vendor_code                          vendor_code         --取引先コード
                 ,PRODC.prod_class_code                     prod_class_code     --商品区分
                 ,PRODC.prod_class_name                     prod_class_name     --商品区分名
                 ,ITEMC.item_class_code                     item_class_code     --品目区分
                 ,ITEMC.item_class_name                     item_class_name     --品目区分名
                 ,0                                         rcv_price           --仕入金額
                  --有償金額（原料<資材以外>）
                 ,CASE WHEN NVL( ITEMC.item_class_code, '1' ) <> '2' THEN           --品目区分が'2:資材'以外の場合
                    ROUND( ( XOLA.unit_price * XMLD.actual_quantity )
                             * DECODE( OTTA.order_category_code, 'RETURN', -1, 1 )  --『支給返品』の場合はマイナス値
                         )
                  END                                       pay_price_gen       --有償金額_原料
                  --有償金額（資材）
                 ,CASE WHEN NVL( ITEMC.item_class_code, '1' )  = '2' THEN           --品目区分が'2:資材'の場合
                    ROUND( ( XOLA.unit_price * XMLD.actual_quantity )
                             * DECODE( OTTA.order_category_code, 'RETURN', -1, 1 )  --『支給返品』の場合はマイナス値
                         )
                  END                                       pay_price_szi       --有償金額_原料
            FROM
                  xxwsh_order_headers_all                   XOHA                --受注ヘッダ
                 ,xxwsh_order_lines_all                     XOLA                --受注明細
                 ,oe_transaction_types_all                  OTTA                --受注タイプマスタ
                 ,xxinv_mov_lot_details                     XMLD                --移動ロット詳細
                 ,xxsky_prod_class_v                        PRODC               --商品区分取得用
                 ,xxsky_item_class_v                        ITEMC               --品目区分取得用
           WHERE
             --受注タイプマスタの条件
                  OTTA.attribute1                           = '2'               --'2:支給'
             --受注ヘッダの条件
             AND  XOHA.req_status                           = '08'              --実績計上済
             AND  NVL( XOHA.latest_external_flag, 'N' )     = 'Y'               --最新フラグ'Y'のみ
             AND  OTTA.transaction_type_id                  = XOHA.order_type_id
             --受注明細との結合
             AND  NVL( XOLA.delete_flag, 'N' )             <> 'Y'               --無効明細以外
             AND  XOHA.order_header_id                      = XOLA.order_header_id
             --移動ロット詳細情報との結合（金額の四捨五入処理を行うのはロット明細単位）
             AND  XMLD.actual_quantity                     <> 0
             AND  XMLD.document_type_code                   = '30'              --支給支持
             AND  XMLD.record_type_code                     = '20'              --出庫実績
             AND  XOLA.order_line_id                        = XMLD.mov_line_id
             --品目カテゴリ情報取得
-- 2010/01/08 T.Yoshimoto Mod Start E_本稼動#716
             --AND  XMLD.item_id                              = PRODC.item_id(+)  --商品区分情報取得
             --AND  XMLD.item_id                              = ITEMC.item_id(+)  --品目区分情報取得
             AND  XMLD.item_id                              = PRODC.item_id     --商品区分情報取得
             AND  XMLD.item_id                              = ITEMC.item_id     --品目区分情報取得
             AND  PRODC.item_id                             = ITEMC.item_id
-- 2010/01/08 T.Yoshimoto Mod End E_本稼動#716
-- 2010/01/08 T.Yoshimoto Add Start E_本稼動#716
             AND  XOHA.arrival_date IS NOT NULL
-- 2010/01/08 T.Yoshimoto Add End E_本稼動#716
          --[ 有償支給データ  END ]--
       )                      XRO
       ,xxsky_locations2_v    XLV                           --部署名取得用
       ,xxsky_vendors2_v      XVV                           --取引先名取得用
 WHERE
   --支給先返品データとの集計により全ての集計項目がゼロとなったデータは出力しない
       (     XRO.rcv_price     <> 0
         OR  XRO.pay_price_gen <> 0
         OR  XRO.pay_price_szi <> 0
       )
   --部署名取得
   AND  XRO.department_code = XLV.location_code(+)
   AND  LAST_DAY( TO_DATE( XRO.yyyymm || '01', 'YYYYMMDD' ) ) >= XLV.start_date_active(+)  --年月末日付で検索
   AND  LAST_DAY( TO_DATE( XRO.yyyymm || '01', 'YYYYMMDD' ) ) <= XLV.end_date_active(+)    --年月末日付で検索
   --取引先名取得
   AND  XRO.vendor_code = XVV.segment1(+)
   AND  LAST_DAY( TO_DATE( XRO.yyyymm || '01', 'YYYYMMDD' ) ) >= XVV.start_date_active(+)  --年月末日付で検索
   AND  LAST_DAY( TO_DATE( XRO.yyyymm || '01', 'YYYYMMDD' ) ) <= XVV.end_date_active(+)    --年月末日付で検索
GROUP BY  XRO.yyyymm
         ,XRO.department_code
         ,XLV.location_name
         ,XRO.vendor_code
         ,XVV.vendor_name
         ,XRO.prod_class_code
         ,XRO.prod_class_name
         ,XRO.item_class_code
         ,XRO.item_class_name
/
COMMENT ON TABLE APPS.XXSKY_仕入有償相殺明細_基本_V IS 'SKYLINK用仕入有償相殺明細基本VIEW'
/
COMMENT ON COLUMN APPS.XXSKY_仕入有償相殺明細_基本_V.年月           IS '年月'
/
COMMENT ON COLUMN APPS.XXSKY_仕入有償相殺明細_基本_V.成績管理部署   IS '成績管理部署'
/
COMMENT ON COLUMN APPS.XXSKY_仕入有償相殺明細_基本_V.成績管理部署名 IS '成績管理部署名'
/
COMMENT ON COLUMN APPS.XXSKY_仕入有償相殺明細_基本_V.商品区分       IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKY_仕入有償相殺明細_基本_V.商品区分名     IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKY_仕入有償相殺明細_基本_V.品目区分       IS '品目区分'
/
COMMENT ON COLUMN APPS.XXSKY_仕入有償相殺明細_基本_V.品目区分名     IS '品目区分名'
/
COMMENT ON COLUMN APPS.XXSKY_仕入有償相殺明細_基本_V.取引先         IS '取引先'
/
COMMENT ON COLUMN APPS.XXSKY_仕入有償相殺明細_基本_V.取引先名       IS '取引先名'
/
COMMENT ON COLUMN APPS.XXSKY_仕入有償相殺明細_基本_V.仕入金額       IS '仕入金額'
/
COMMENT ON COLUMN APPS.XXSKY_仕入有償相殺明細_基本_V.有償金額_原料  IS '有償金額_原料'
/
COMMENT ON COLUMN APPS.XXSKY_仕入有償相殺明細_基本_V.有償金額_資材  IS '有償金額_資材'
/
COMMENT ON COLUMN APPS.XXSKY_仕入有償相殺明細_基本_V.有償金額_合計  IS '有償金額_合計'
/
COMMENT ON COLUMN APPS.XXSKY_仕入有償相殺明細_基本_V.支払金額       IS '支払金額'
/
