-- ************************************************************************************************
-- Copyright(c)Oracle Corporation Japan, 2006-2008. All rights reserved.
-- 
-- Control file  : XXCOS001A02D.ctl
-- Description   : HHT入金データ取込 SQL*Loader処理
-- MD.050        : 
-- MD.070        : なし
-- Version       : 1.0
--
-- Target Table  : XXCOS_PAYMENT_WORK
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
INTO TABLE XXCOS_PAYMENT_WORK
FIELDS TERMINATED BY "," OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS
  (
    LINE_ID                 SEQUENCE(MAX),                   -- 明細ID
    BASE_CODE               CHAR,                            -- 拠点コード
    CUSTOMER_NUMBER         CHAR,                            -- 顧客コード
    HHT_INVOICE_NO          CHAR,                            -- 伝票No
    PAYMENT_AMOUNT          INTEGER EXTERNAL,                -- 入金額
    PAYMENT_DATE            DATE(8) "yyyymmdd",              -- 入金日
    PAYMENT_CLASS           CHAR,                            -- 入金区分
    CREATED_BY              CONSTANT "-1",                   -- 作成者
    CREATION_DATE           SYSDATE,                         -- 作成日
    LAST_UPDATED_BY         CONSTANT "-1",                   -- 最終更新者
    LAST_UPDATE_DATE        SYSDATE,                         -- 最終更新日
    LAST_UPDATE_LOGIN       CONSTANT "-1",                   -- 最終更新ログイン
    REQUEST_ID              CONSTANT "-1",                   -- 要求ID
    PROGRAM_APPLICATION_ID  CONSTANT "-1",                   -- コンカレント・プログラム・アプリケーションID
    PROGRAM_ID              CONSTANT "-1",                   -- コンカレント・プログラムID
    PROGRAM_UPDATE_DATE     SYSDATE                          -- プログラム更新日
  )
