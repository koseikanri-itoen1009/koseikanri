-- ************************************************************************************************
-- Copyright(c)Oracle Corporation Japan, 2006-2008. All rights reserved.
-- 
-- Control file  : XXCOS001A012D.ctl
-- Description   : HHT納品データ取込（明細） SQL*Loader処理
-- MD.050        : 
-- MD.070        : なし
-- Version       : 1.0
--
-- Target Table  : XXCOS_DLV_LINES_WORK
--
-- Change Record
-- ------------- ------- ---------------- ---------------------------------------------------------
--  Date          Ver.    Editor           Description
-- ------------- ------- ---------------- ---------------------------------------------------------
--  2008/10/29    1.0     宮越 翔平        新規作成
--
-- ************************************************************************************************
LOAD DATA
INFILE *
APPEND
INTO TABLE XXCOS_DLV_LINES_WORK
FIELDS TERMINATED BY "," OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS
  (
    ORDER_NO_HHT                 INTEGER EXTERNAL,                  -- 受注No.(HHT)
    LINE_NO_HHT                  INTEGER EXTERNAL,                  -- 行No.(HHT)
    ORDER_NO_EBS                 INTEGER EXTERNAL,                  -- 受注No.(EBS)
    LINE_NUMBER_EBS              INTEGER EXTERNAL,                  -- 明細番号(EBS)
    ITEM_CODE_SELF               CHAR,                              -- 品名コード(自社)
    CASE_NUMBER                  INTEGER EXTERNAL,                  -- ケース数
    QUANTITY                     INTEGER EXTERNAL,                  -- 数量
    SALE_CLASS                   CHAR,                              -- 売上区分
    WHOLESALE_UNIT_PLOCE         INTEGER EXTERNAL,                  -- 卸単価
    SELLING_PRICE                INTEGER EXTERNAL,                  -- 売単価
    COLUMN_NO                    CHAR,                              -- コラムNo.
    H_AND_C                      CHAR,                              -- H/C
    SOLD_OUT_CLASS               CHAR,                              -- 売切区分
    SOLD_OUT_TIME                CHAR,                              -- 売切時間
    REPLENISH_NUMBER             INTEGER EXTERNAL,                  -- 補充数
    CASH_AND_CARD                INTEGER EXTERNAL,                  -- 現金・カード併用額
    RECEIVE_DATE                 DATE(19) "YYYY/MM/DD HH24:MI:SS",  -- 受信日時
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
