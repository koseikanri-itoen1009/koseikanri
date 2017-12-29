-- ************************************************************************************************
-- Copyright(c)SCSK Corporation, 2017. All rights reserved.
-- 
-- Control file  : XXCOS001A101D.ctl
-- Description   : HHT受注ヘッダワークテーブル取込（ヘッダ）
-- MD.050        : MD050_COS_001_A10_HHT受注データ取込 SQL*Loader処理
-- MD.070        : なし
-- Version       : 1.0
--
-- Target Table  : XXCOS_HHT_ORDER_HEADERS_WORK
--
-- Change Record
-- ------------- ------- ---------------- ---------------------------------------------------------
--  Date          Ver.    Editor           Description
-- ------------- ------- ---------------- ---------------------------------------------------------
--  2017/08/15    1.0     SCSK K.Kiriu      E_本稼動_14486（新規作成）
--
-- ************************************************************************************************
LOAD DATA
INFILE *
APPEND
INTO TABLE XXCOS_HHT_ORDER_HEADERS_WORK
FIELDS TERMINATED BY "," OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS
  (
    ORDER_NO_HHT                 INTEGER EXTERNAL,                  -- 受注No.(HHT)
    BASE_CODE                    CHAR,                              -- 拠点コード
    DLV_BY_CODE                  CHAR,                              -- 納品者コード
    INVOICE_NO                   CHAR,                              -- 伝票No.
    DLV_DATE                     DATE(8) "yyyymmdd",                -- 納品予定日
    SALES_CLASSIFICATION         CHAR,                              -- 売上分類区分
    SALES_INVOICE                CHAR,                              -- 売上伝票区分
    DLV_TIME                     CHAR,                              -- 時間
    CUSTOMER_NUMBER              CHAR,                              -- 顧客コード
    CONSUMPTION_TAX_CLASS        CHAR,                              -- 消費税区分
    TOTAL_AMOUNT                 INTEGER EXTERNAL,                  -- 合計金額
    SALES_CONSUMPTION_TAX        INTEGER EXTERNAL,                  -- 売上消費税額
    TAX_INCLUDE                  INTEGER EXTERNAL,                  -- 税込金額
    SYSTEM_DATE                  DATE(8) "yyyymmdd",                -- システム日付
    ORDER_NO                     CHAR,                              -- オーダーNo
    RECEIVED_DATE                DATE(19) "yyyy/mm/dd hh24:mi:ss",  -- 受信日時
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
