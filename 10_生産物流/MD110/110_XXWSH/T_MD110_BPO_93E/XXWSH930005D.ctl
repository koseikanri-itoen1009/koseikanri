-- **************************************************************************************
-- Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
--
-- Package Name     : xxwsh930005d(ctl)
-- Description      : HHT入出庫実績インターフェース SQL*Loader処理
-- MD.050           : 生産物流共通（出荷・移動インタフェース）     T_MD050_BPO_930
-- MD.070           : HHT入出庫実績インターフェース_SQLLoader処理  T_MD070_BPO_93E
-- Version          : 1.1
--
-- Change Record
-- ------------- ----- ----------------- ------------------------------------------------
--  Date          Ver.  Editor            Description
-- ------------- ----- ----------------- ------------------------------------------------
--  2008/02/26    1.0   Oracle 椎名 昭圭  初回作成
--  2008/05/19    1.1   Oracle 椎名 昭圭  内部変更要求#100対応
--  2008/06/06    1.2   Oracle 冨田 信    データタイプに値が設定されない不具合対応
--  2008/06/11    1.3   Oracle 冨田 信    明細のHEADER_ID不具合対応
-- **************************************************************************************
LOAD DATA
INFILE *
APPEND
INTO TABLE XXWSH_SHIPPING_HEADERS_IF
WHEN(FILLER02 = '10')
FIELDS TERMINATED BY ','
TRAILING NULLCOLS
(
HEADER_ID                     "APPS.XXWSH_LOADER_ID_FUNC('HEADERS', 'HEADERS', :EOS_DATA_TYPE, :DELIVERY_NO, :ORDER_SOURCE_REF)", -- ヘッダID
FILLER01                      POSITION(1),                                    -- 会社名
EOS_DATA_TYPE                 POSITION(*),                                    -- データ種別
FILLER02                      POSITION(*),                                    -- 伝送用枝番
DELIVERY_NO                   POSITION(*),                                    -- 配送No
ORDER_SOURCE_REF              POSITION(*),                                    -- 依頼No
FILLER03                      POSITION(*),                                    -- 予備
FILLER04                      POSITION(*),                                    -- 拠点コード
FILLER05                      POSITION(*),                                    -- 管轄拠点名称
LOCATION_CODE                 POSITION(*),                                    -- 出庫倉庫コード
FILLER06                      POSITION(*),                                    -- 出庫倉庫名称
SHIP_TO_LOCATION              POSITION(*),                                    -- 入庫倉庫コード
FILLER07                      POSITION(*),                                    -- 入庫倉庫名称
FREIGHT_CARRIER_CODE          POSITION(*),                                    -- 運送業者コード
FILLER08                      POSITION(*),                                    -- 運送業者名
PARTY_SITE_CODE               POSITION(*),                                    -- 配送先コード
FILLER09                      POSITION(*),                                    -- 配送先名
SHIPPED_DATE                  POSITION(*)   DATE(10)"YYYY/MM/DD",             -- 発日
ARRIVAL_DATE                  POSITION(*)   DATE(10)"YYYY/MM/DD",             -- 着日
SHIPPING_METHOD_CODE          POSITION(*),                                    -- 配送区分
FILLER10                      POSITION(*),                                    -- 重量/容積
FILLER11                      POSITION(*),                                    -- 混載元依頼№
COLLECTED_PALLET_QTY          POSITION(*),                                    -- パレット回収枚数
ARRIVAL_TIME_FROM             POSITION(*),                                    -- 着荷時間指定(FROM)
ARRIVAL_TIME_TO               POSITION(*),                                    -- 着荷時間指定(TO)
CUST_PO_NUMBER                POSITION(*),                                    -- 顧客発注番号
FILLER12                      POSITION(*),                                    -- 摘要
FILLER13                      POSITION(*),                                    -- ステータス
FILLER14                      POSITION(*),                                    -- 運賃区分
USED_PALLET_QTY               POSITION(*),                                    -- パレット使用枚数
FILLER15                      POSITION(*),                                    -- 予備①
FILLER16                      POSITION(*),                                    -- 予備②
FILLER17                      POSITION(*),                                    -- 予備③
FILLER18                      POSITION(*),                                    -- 予備④
REPORT_POST_CODE              POSITION(*),                                    -- 報告部署
CREATED_BY                    CONSTANT 0,                                     -- 作成者
CREATION_DATE                 SYSDATE,                                        -- 作成日
LAST_UPDATED_BY               CONSTANT 0,                                     -- 最終更新者
LAST_UPDATE_DATE              SYSDATE,                                        -- 最終更新日
LAST_UPDATE_LOGIN             CONSTANT 0,                                     -- 最終更新ログイン
REQUEST_ID                    CONSTANT 0,                                     -- 要求ID
PROGRAM_APPLICATION_ID        CONSTANT 0,                                     -- コンカレント・プログラム・アプリケーションID
PROGRAM_ID                    CONSTANT 0,                                     -- コンカレント・プログラムID
PROGRAM_UPDATE_DATE           SYSDATE,                                        -- プログラム更新日
DATA_TYPE                     CONSTANT "40"                                   -- データタイプ
)
INTO TABLE XXWSH_SHIPPING_LINES_IF
WHEN(FILLER05 = '20')
FIELDS TERMINATED BY ','
TRAILING NULLCOLS
(
ORDERD_ITEM_CODE              POSITION(*),                                    -- 品目コード
FILLER01                      POSITION(*),                                    -- 品目名
FILLER02                      POSITION(*),                                    -- 品目単位
ORDERD_QUANTITY               POSITION(*),                                    -- 品目数量
LOT_NO                        POSITION(*),                                    -- ロット番号
DESIGNATED_PRODUCTION_DATE    POSITION(*)   DATE(10)"YYYY/MM/DD",             -- 製造日
USE_BY_DATE                   POSITION(*)   DATE(10)"YYYY/MM/DD",             -- 賞味期限
ORIGINAL_CHARACTER            POSITION(*),                                    -- 固有記号
DETAILED_QUANTITY             POSITION(*),                                    -- ロット数量
CREATED_BY                    CONSTANT 0,                                     -- 作成者
CREATION_DATE                 SYSDATE,                                        -- 作成日
LAST_UPDATED_BY               CONSTANT 0,                                     -- 最終更新者
LAST_UPDATE_DATE              SYSDATE,                                        -- 最終更新日
LAST_UPDATE_LOGIN             CONSTANT 0,                                     -- 最終更新ログイン
REQUEST_ID                    CONSTANT 0,                                     -- 要求ID
PROGRAM_APPLICATION_ID        CONSTANT 0,                                     -- コンカレント・プログラム・アプリケーションID
PROGRAM_ID                    CONSTANT 0,                                     -- コンカレント・プログラムID
PROGRAM_UPDATE_DATE           SYSDATE,                                        -- プログラム更新日
FILLER03                      POSITION(1),                                    -- 会社名
FILLER04                      POSITION(*),                                    -- データ種別
FILLER05                      POSITION(*),                                    -- 伝送用枝番
FILLER06                      POSITION(*),                                    -- 配送No
FILLER07                      POSITION(*),                                    -- 依頼No
LINE_ID                       "APPS.XXWSH_LOADER_ID_FUNC('LINES', 'LINES', :FILLER04, :FILLER06, :FILLER07)",  -- 明細ID
HEADER_ID                     "APPS.XXWSH_LOADER_ID_FUNC('LINES', 'HEADERS', :FILLER04, :FILLER06, :FILLER07)" -- ヘッダID
)
