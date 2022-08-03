-- ************************************************************************************************
-- Copyright(c)Oracle Corporation Japan, 2006-2008. All rights reserved.
-- 
-- Control file  : XXCOS001A011D.ctl
-- Description   : HHT納品データ取込（ヘッダ） SQL*Loader処理
-- MD.050        : 
-- MD.070        : なし
-- Version       : 1.5
--
-- Target Table  : XXCOS_DLV_HEADERS_WORK
--
-- Change Record
-- ------------- ------- ---------------- ---------------------------------------------------------
--  Date          Ver.    Editor           Description
-- ------------- ------- ---------------- ---------------------------------------------------------
--  2008/10/29    1.0     宮越 翔平        新規作成
--  2011/03/16    1.1     落合 峻平        [E_本稼動_06590] オーダーNo追加
--  2016/02/15    1.2     仁木 重人        [E_本稼動_13480] 納品書チェックリスト対応
--  2017/04/19    1.3     渡邊 直樹        [E_本稼動_14025] HHTからのシステム日付連携追加
--  2017/12/18    1.4     山下 翔太        [E_本稼動_14486] HHTからの訪問区分連携追加
--  2019/07/26    1.5     桑子 駿介        [E_本稼動_15472] 軽減税率対応(HHT追加対応)
--
-- ************************************************************************************************
LOAD DATA
INFILE *
APPEND
INTO TABLE XXCOS_DLV_HEADERS_WORK
FIELDS TERMINATED BY "," OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS
  (
    ORDER_NO_HHT                 INTEGER EXTERNAL,                  -- 受注No.(HHT)
    ORDER_NO_EBS                 INTEGER EXTERNAL,                  -- 受注No.(EBS)
    BASE_CODE                    CHAR,                              -- 拠点コード
    PERFORMANCE_BY_CODE          CHAR,                              -- 成績者コード
    DLV_BY_CODE                  CHAR,                              -- 納品者コード
    HHT_INVOICE_NO               CHAR,                              -- 伝票No.
    DLV_DATE                     DATE(8) "yyyymmdd",                -- 納品日
    INSPECT_DATE                 DATE(8) "yyyymmdd",                -- 検収日
    SALES_CLASSIFICATION         CHAR,                              -- 売上分類区分
    SALES_INVOICE                CHAR,                              -- 売上伝票区分
    CARD_SALE_CLASS              CHAR,                              -- カード売区分
    VISIT_FLAG                   CHAR,                              -- 訪問フラグ
    EFFECTIVE_FLAG               CHAR,                              -- 有効フラグ
    DLV_TIME                     CHAR,                              -- 時間
    CHANGE_OUT_TIME_100          CHAR,                              -- つり銭切れ時間100円
    CHANGE_OUT_TIME_10           CHAR,                              -- つり銭切れ時間10円
    CUSTOMER_NUMBER              CHAR,                              -- 顧客コード
    INPUT_CLASS                  CHAR,                              -- 入力区分
    CONSUMPTION_TAX_CLASS        CHAR,                              -- 消費税区分
    TOTAL_AMOUNT                 INTEGER EXTERNAL,                  -- 合計金額
    SALE_DISCOUNT_AMOUNT         INTEGER EXTERNAL,                  -- 売上値引額
    SALES_CONSUMPTION_TAX        INTEGER EXTERNAL,                  -- 売上消費税額
    TAX_INCLUDE                  INTEGER EXTERNAL,                  -- 税込金額
    KEEP_IN_CODE                 CHAR,                              -- 預け先コード
    DEPARTMENT_SCREEN_CLASS      CHAR,                              -- 百貨店画面種別
-- 2011/03/16 Ver.1.1 S.Ochiai ADD Start
    ORDER_NUMBER                 CHAR,                              --オーダーNo
-- 2011/03/16 Ver.1.1 S.Ochiai ADD End
-- Ver.1.2 ADD Start
    TOTAL_SALES_AMT              INTEGER EXTERNAL,                  -- 総販売金額
    CASH_TOTAL_SALES_AMT         INTEGER EXTERNAL,                  -- 現金売りトータル販売金額
    PPCARD_TOTAL_SALES_AMT       INTEGER EXTERNAL,                  -- PPカードトータル販売金額
    IDCARD_TOTAL_SALES_AMT       INTEGER EXTERNAL,                  -- IDカードトータル販売金額
-- Ver.1.2 ADD End
-- Ver.1.3 ADD Start
    HHT_INPUT_DATE               DATE(8) "yyyymmdd",                -- HHT入力日
-- Ver.1.3 ADD End
    RECEIVE_DATE                 DATE(19) "yyyy/mm/dd hh24:mi:ss",  -- 受信日時
-- Ver.1.4 ADD Start
    VISIT_CLASS1                 CHAR,                              -- 訪問区分1
    VISIT_CLASS2                 CHAR,                              -- 訪問区分2
    VISIT_CLASS3                 CHAR,                              -- 訪問区分3
    VISIT_CLASS4                 CHAR,                              -- 訪問区分4
    VISIT_CLASS5                 CHAR,                              -- 訪問区分5
-- Ver.1.4 ADD End
-- Ver.1.5 ADD Start
    DISCOUNT_TAX_CLASS           CHAR,                              -- 値引税区分
-- Ver.1.5 ADD End
    CREATED_BY                   CONSTANT "-1",                     -- 作成者
    CREATION_DATE                SYSDATE,                           -- 作成日
    LAST_UPDATED_BY              CONSTANT "-1",                     -- 最終更新者
    LAST_UPDATE_DATE             SYSDATE,                           -- 最終更新日
    LAST_UPDATE_LOGIN            CONSTANT "-1",                     -- 最終更新ログイン
    REQUEST_ID                   CONSTANT "-1",                     -- 要求ID
    PROGRAM_APPLICATION_ID       CONSTANT "-1",                     -- コンカレント・プログラム・アプリケーションID
    PROGRAM_ID                   CONSTANT "-1",                     -- コンカレント・プログラムID
    PROGRAM_UPDATE_DATE          SYSDATE                            -- プログラム更新日
  )
