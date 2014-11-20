/*************************************************************************
 * 
 * View  Name      : XXSKZ_原価差異_基本_V
 * Description     : XXSKZ_原価差異_基本_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/26    1.0   SCSK M.Nagai 初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_原価差異_基本_V
(
 対象年月
,商品区分
,商品区分名
,品目区分
,品目区分名
,群コード
,取引先コード
,取引先名
,品目コード
,品目名
,品目略称
,費目
,費目名称
,項目
,項目名称
,月間数量
,月間ケース数量
,月間金額
,標準金額
)
AS
SELECT
        XRART.txns_date_ym                                            -- 対象年月
       ,XPCV.prod_class_code                                          -- 商品区分
       ,XPCV.prod_class_name                                          -- 商品区分名
       ,XICV.item_class_code                                          -- 品目区分
       ,XICV.item_class_name                                          -- 品目区分名
       ,XCCV.crowd_code                                               -- 群コード
       ,XVV.segment1                                                  -- 取引先コード
       ,XVV.vendor_name                                               -- 取引先名
       ,XIMV.item_no                                                  -- 品目コード
       ,XIMV.item_name                                                -- 品目名
       ,XIMV.item_short_name                                          -- 品目略称
       ,SMPR.expense_type                                             -- 費目
       ,FLV01.meaning                                                 -- 費目名称
       ,SMPR.expense_d_type                                           -- 項目
       ,FLV02.meaning                                                 -- 項目名称
       ,NVL( XRART.sum_quantity  , 0 )                                -- 月間数量
       ,NVL( XRART.sum_quantity / XIMV.num_of_cases, 0 )              -- 月間ケース数量
       ,NVL( SMPR.sum_month_kin  , 0 )                                -- 月間金額
       ,NVL( SMPR.sum_hyoujun_kin, 0 )                                -- 標準金額
  FROM
        (  -- ==============================================================================
           -- ①対象年月、品目ID、取引先IDで集計した月間数量データ
           -- ==============================================================================
           SELECT  TO_CHAR(txns_date, 'YYYYMM')       txns_date_ym    -- 対象年月
                  ,item_id                            item_id         -- 品目ID
                  ,vendor_id                          vendor_id       -- 取引先ID
                  ,SUM( CASE WHEN txns_type IN ('2','3') THEN quantity * -1  -- 返品はマイナス計上
                             ELSE                             quantity
                        END
                   )                                  sum_quantity    -- 月間数量
             FROM  xxpo_rcv_and_rtn_txns                              -- 受入返品実績アドオン
           GROUP BY TO_CHAR(txns_date, 'YYYYMM')
                   ,item_id
                   ,vendor_id
        )  XRART
       ,(  -- ==============================================================================
           -- ②対象年月、品目ID、取引先ID、費目、項目で集計した月間金額＋標準金額データ
           -- ==============================================================================
           SELECT  PRICE.txns_date_ym                               txns_date_ym    -- 対象年月
                  ,PRICE.item_id                                    item_id         -- 品目ID
                  ,PRICE.vendor_id                                  vendor_id       -- 取引先ID
                  ,PRICE.expense_type                               expense_type    -- 費目
                  ,PRICE.expense_d_type                             expense_d_type  -- 項目
                  ,SUM( PRICE.month_kin   )                         sum_month_kin   -- 月間金額
                  ,SUM( PRICE.hyoujun_kin )                         sum_hyoujun_kin -- 標準金額
             FROM  (  -------------------------------------------------------------------------------
                      -- 対象年月、品目ID、取引先ID、費目、項目で集計した月間金額集計データ【その１】
                      --   ☆発注受入・発注あり返品の場合は発注ヘッダの項目で仕入単価ヘッダと結合する
                      -------------------------------------------------------------------------------
                      SELECT  TO_CHAR( XRARTS.txns_date, 'YYYYMM' )  txns_date_ym    -- 対象年月
                             ,XRARTS.item_id                         item_id         -- 品目ID
                             ,XRARTS.vendor_id                       vendor_id       -- 取引先ID
                             ,XPLS.expense_item_type                 expense_type    -- 費目
                             ,XPLS.expense_item_detail_type          expense_d_type  -- 項目
                             ,ROUND( SUM( CASE WHEN txns_type = '2' THEN (XRARTS.quantity * XPLS.unit_price) * -1
                                               ELSE                       XRARTS.quantity * XPLS.unit_price
                                          END )
                                   )                                 month_kin       -- 月間金額
                             ,0                                      hyoujun_kin     -- 標準金額
                        FROM  xxpo_rcv_and_rtn_txns                  XRARTS          -- 受入返品実績アドオン
                             ,po_headers_all                         PHA             -- 発注ヘッダ
                             ,po_lines_all                           PLA             -- 発注明細
                             ,xxpo_price_headers                     XPHS            -- 仕入/標準単価ヘッダ（仕入）
                             ,xxpo_price_lines                       XPLS            -- 仕入/標準単価明細（仕入）
                       WHERE
                         -- 発注受入･発注あり返品データの抽出条件
                              XRARTS.txns_type IN ( '1', '2' )
                         -- 発注データとの結合
                         AND  NVL( PLA.attribute13, 'N' )  = 'Y'                     --承諾済
                         AND  NVL( PLA.cancel_flag, 'N' ) <> 'Y'                     --キャンセル以外
                         AND  PHA.po_header_id = PLA.po_header_id
                         AND  XRARTS.source_document_number = PHA.segment1
                         AND  XRARTS.source_document_line_num = PLA.line_num
                         -- 仕入単価ヘッダとの結合（品目、取引先、付帯、工場単位で仕入単価を取得）
                         AND  XRARTS.item_id = XPHS.item_id                          -- 品目
                         AND  PLA.attribute3 = XPHS.futai_code                       -- 付帯(発注明細のもので結合)
                         AND  XRARTS.vendor_id = XPHS.vendor_id                      -- 取引先
                         AND  PLA.attribute2 = XPHS.factory_code                     -- 工場(発注明細のもので結合)
                         AND  XRARTS.txns_date >= XPHS.start_date_active
                         AND  XRARTS.txns_date <= XPHS.end_date_active
                         -- 仕入単価明細との結合
                         AND  XPHS.price_type = '1'                                  -- マスタ区分：仕入単価
                         AND  XPHS.price_header_id = XPLS.price_header_id
                      GROUP BY TO_CHAR( XRARTS.txns_date, 'YYYYMM' )
                              ,XRARTS.item_id
                              ,XRARTS.vendor_id
                              ,XPLS.expense_item_type
                              ,XPLS.expense_item_detail_type
                    UNION ALL
                      -------------------------------------------------------------------------------
                      -- 対象年月、品目ID、取引先ID、費目、項目で集計した月間金額集計データ【その２】
                      --   ☆発注なし返品の場合は受入返品アドオンの項目で仕入単価ヘッダと結合する
                      -------------------------------------------------------------------------------
                      SELECT  TO_CHAR( XRARTS.txns_date, 'YYYYMM' )  txns_date_ym    -- 対象年月
                             ,XRARTS.item_id                         item_id         -- 品目ID
                             ,XRARTS.vendor_id                       vendor_id       -- 取引先ID
                             ,XPLS.expense_item_type                 expense_type    -- 費目
                             ,XPLS.expense_item_detail_type          expense_d_type  -- 項目
                             ,ROUND( SUM( (XRARTS.quantity * XPLS.unit_price) * -1 ) )
                                                                     month_kin       -- 月間金額
                             ,0                                      hyoujun_kin     -- 標準金額
                        FROM  xxpo_rcv_and_rtn_txns                  XRARTS          -- 受入返品実績アドオン
                             ,xxpo_price_headers                     XPHS            -- 仕入/標準単価ヘッダ（仕入）
                             ,xxpo_price_lines                       XPLS            -- 仕入/標準単価明細（仕入）
                       WHERE
                         -- 発注なし受入返品データの抽出条件
                              XRARTS.txns_type = '3'
                         -- 仕入単価ヘッダとの結合（品目、取引先、付帯、工場単位で仕入単価を取得）
                         AND  XRARTS.item_id = XPHS.item_id                          -- 品目
                         AND  XRARTS.futai_code = XPHS.futai_code                    -- 付帯
                         AND  XRARTS.vendor_id = XPHS.vendor_id                      -- 取引先
                         AND  XRARTS.factory_id = XPHS.factory_id                    -- 工場
                         AND  XRARTS.txns_date >= XPHS.start_date_active
                         AND  XRARTS.txns_date <= XPHS.end_date_active
                         -- 仕入単価明細との結合
                         AND  XPHS.price_type = '1'                                  -- マスタ区分：仕入単価
                         AND  XPHS.price_header_id = XPLS.price_header_id
                      GROUP BY TO_CHAR( XRARTS.txns_date, 'YYYYMM' )
                              ,XRARTS.item_id
                              ,XRARTS.vendor_id
                              ,XPLS.expense_item_type
                              ,XPLS.expense_item_detail_type
                    UNION ALL
                      -------------------------------------------------------------------------------
                      -- 対象年月、品目ID、取引先ID、費目、項目で集計した標準金額集計データ
                      -------------------------------------------------------------------------------
                      SELECT  TO_CHAR( XRARTS.txns_date, 'YYYYMM' )  txns_date_ym    -- 対象年月
                             ,XRARTS.item_id                         item_id         -- 品目ID
                             ,XRARTS.vendor_id                       vendor_id       -- 取引先ID
                             ,XPLS.expense_item_type                 expense_type    -- 費目
                             ,XPLS.expense_item_detail_type          expense_d_type  -- 項目
                             ,0                                      month_kin       -- 月間金額
                             ,ROUND( SUM( CASE WHEN txns_type IN ('2','3') THEN (XRARTS.quantity * XPLS.unit_price) * -1
                                               ELSE                              XRARTS.quantity * XPLS.unit_price
                                          END )
                                   )                                 hyoujun_kin     -- 標準金額
                        FROM  xxpo_rcv_and_rtn_txns                  XRARTS          -- 受入返品実績アドオン
                             ,xxpo_price_headers                     XPHS            -- 仕入/標準単価ヘッダ（標準）
                             ,xxpo_price_lines                       XPLS            -- 仕入/標準単価明細（標準）
                       WHERE
                         -- 標準単価ヘッダとの結合（品目単位で標準単価を取得）
                              XRARTS.item_id = XPHS.item_id                          -- 品目
                         AND  XRARTS.txns_date >= XPHS.start_date_active
                         AND  XRARTS.txns_date <= XPHS.end_date_active
                         -- 標準単価明細との結合
                         AND  XPHS.price_type = '2'                                  -- マスタ区分：標準単価
                         AND  XPHS.price_header_id = XPLS.price_header_id
                      GROUP BY TO_CHAR( XRARTS.txns_date, 'YYYYMM' )
                              ,XRARTS.item_id
                              ,XRARTS.vendor_id
                              ,XPLS.expense_item_type
                              ,XPLS.expense_item_detail_type
                   )  PRICE
           GROUP BY PRICE.txns_date_ym
                   ,PRICE.item_id
                   ,PRICE.vendor_id
                   ,PRICE.expense_type
                   ,PRICE.expense_d_type
        )  SMPR
       ,xxskz_prod_class_v    XPCV                             -- 商品区分取得用
       ,xxskz_item_class_v    XICV                             -- 品目区分取得用
       ,xxskz_crowd_code_v    XCCV                             -- 群コード
       ,xxskz_item_mst2_v     XIMV                             -- 品目名取得用
       ,xxskz_vendors2_v      XVV                              -- 取引先名取得用
       ,fnd_lookup_values     FLV01                            -- 費目名称取得用
       ,fnd_lookup_values     FLV02                            -- 項目名称取得用
 WHERE
   -- ①と②の結合
        XRART.txns_date_ym = SMPR.txns_date_ym
   AND  XRART.item_id      = SMPR.item_id
   AND  XRART.vendor_id    = SMPR.vendor_id
   -- 支給先返品との集計により月間数量がゼロとなったデータは出力しない
   AND  XRART.sum_quantity <> 0
   -- 商品区分名取得
   AND  XRART.item_id = XPCV.item_id(+)
   -- 品目区分名取得
   AND  XRART.item_id = XICV.item_id(+)
   -- 群コード取得
   AND  XRART.item_id = XCCV.item_id(+)
   -- 品目情報取得
   AND  XRART.item_id = XIMV.item_id(+)
   AND  TRUNC( LAST_DAY( TO_DATE( XRART.txns_date_ym || '01', 'YYYYMMDD' ) ) ) >= XIMV.start_date_active
   AND  TRUNC( LAST_DAY( TO_DATE( XRART.txns_date_ym || '01', 'YYYYMMDD' ) ) ) <= XIMV.end_date_active
   -- 取引先名取得
   AND  XRART.vendor_id = XVV.vendor_id(+)
   AND  TRUNC( LAST_DAY( TO_DATE( XRART.txns_date_ym || '01', 'YYYYMMDD' ) ) ) >= XVV.start_date_active
   AND  TRUNC( LAST_DAY( TO_DATE( XRART.txns_date_ym || '01', 'YYYYMMDD' ) ) ) <= XVV.end_date_active
   -- 費目名称取得
   AND  FLV01.language(+)    = 'JA'                                  --言語
   AND  FLV01.lookup_type(+) = 'XXPO_EXPENSE_ITEM_TYPE'              --クイックコードタイプ
   AND  SMPR.expense_type    = FLV01.attribute1(+)                   --クイックコード
   -- 項目名称取得
   AND  FLV02.language(+)    = 'JA'                                  --言語
   AND  FLV02.lookup_type(+) = 'XXPO_EXPENSE_ITEM_DETAIL_TYPE'       --クイックコードタイプ
   AND  SMPR.expense_d_type  = FLV02.attribute1(+)                   --クイックコード
/
COMMENT ON TABLE APPS.XXSKZ_原価差異_基本_V IS 'SKYLINK用原価差異基本VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_原価差異_基本_V.対象年月       IS '対象年月'
/
COMMENT ON COLUMN APPS.XXSKZ_原価差異_基本_V.商品区分       IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKZ_原価差異_基本_V.商品区分名     IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_原価差異_基本_V.品目区分       IS '品目区分'
/
COMMENT ON COLUMN APPS.XXSKZ_原価差異_基本_V.品目区分名     IS '品目区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_原価差異_基本_V.群コード       IS '群コード'
/
COMMENT ON COLUMN APPS.XXSKZ_原価差異_基本_V.取引先コード   IS '取引先コード'
/
COMMENT ON COLUMN APPS.XXSKZ_原価差異_基本_V.取引先名       IS '取引先名'
/
COMMENT ON COLUMN APPS.XXSKZ_原価差異_基本_V.品目コード     IS '品目コード'
/
COMMENT ON COLUMN APPS.XXSKZ_原価差異_基本_V.品目名         IS '品目名'
/
COMMENT ON COLUMN APPS.XXSKZ_原価差異_基本_V.品目略称       IS '品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_原価差異_基本_V.費目           IS '費目'
/
COMMENT ON COLUMN APPS.XXSKZ_原価差異_基本_V.費目名称       IS '費目名称'
/
COMMENT ON COLUMN APPS.XXSKZ_原価差異_基本_V.項目           IS '項目'
/
COMMENT ON COLUMN APPS.XXSKZ_原価差異_基本_V.項目名称       IS '項目名称'
/
COMMENT ON COLUMN APPS.XXSKZ_原価差異_基本_V.月間数量       IS '月間数量'
/
COMMENT ON COLUMN APPS.XXSKZ_原価差異_基本_V.月間ケース数量 IS '月間ケース数量'
/
COMMENT ON COLUMN APPS.XXSKZ_原価差異_基本_V.月間金額       IS '月間金額'
/
COMMENT ON COLUMN APPS.XXSKZ_原価差異_基本_V.標準金額       IS '標準金額'
/