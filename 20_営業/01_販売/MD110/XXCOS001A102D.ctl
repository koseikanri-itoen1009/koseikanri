-- ************************************************************************************************
-- Copyright(c)SCSK Corporation, 2017. All rights reserved.
-- 
-- Control file  : XXCOS001A102D.ctl
-- Description   : HHT受注明細ワークテーブル取込（明細）
-- MD.050        : MD050_COS_001_A10_HHT受注データ取込 SQL*Loader処理
-- MD.070        : なし
-- Version       : 1.0
--
-- Target Table  : XXCOS_HHT_ORDER_LINES_WORK
--
-- Change Record
-- ------------- ------- ---------------- ---------------------------------------------------------
--  Date          Ver.    Editor           Description
-- ------------- ------- ---------------- ---------------------------------------------------------
--  2017/07/25    1.0     SCSK K.Kiriu      E_本稼動_14486（新規作成）
--
-- ************************************************************************************************
LOAD DATA
INFILE *
APPEND
INTO TABLE XXCOS_HHT_ORDER_LINES_WORK
FIELDS TERMINATED BY "," OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS
  (
    ORDER_NO_HHT                 INTEGER EXTERNAL,                  -- 受注No.(HHT)
    LINE_NO_HHT                  INTEGER EXTERNAL,                  -- 行No.(HHT)
    ITEM_CODE_SELF               CHAR,                              -- 品名コード(自社)
    CASE_NUMBER                  INTEGER EXTERNAL,                  -- ケース数
    QUANTITY                     INTEGER EXTERNAL,                  -- 数量
    SALE_CLASS                   CHAR,                              -- 売上区分
    WHOLESALE_UNIT_PLICE         INTEGER EXTERNAL,                  -- 卸単価
    SELLING_PRICE                INTEGER EXTERNAL,                  -- 売単価
    RECEIVED_DATE                DATE(19) "YYYY/MM/DD HH24:MI:SS",  -- 受信日時
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
