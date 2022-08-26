-- **************************************************************************************
-- Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
--
-- Package Name     : xxpo310003c(ctl)
-- Description      : HHT受入実績SQLLoader
-- MD.050           : 受入実績              T_MD050_BPO_310
-- MD.070           : HHT受入実績SQLLoader  T_MD070_BPO_31F
-- Version          : 1.0
--
-- Program List
-- ---------------------- ----------------------------------------------------------
--  Name                   Description
-- ---------------------- ----------------------------------------------------------
--  main                   コンカレント実行ファイル登録プロシージャ
-- Change Record
-- ------------- ----- ---------------- -------------------------------------------------
--  Date          Ver.  Editor           Description
-- ------------- ----- ---------------- -------------------------------------------------
--  2008/04/23    1.0   Oracle 山根 一浩 初回作成
-- **************************************************************************************
LOAD DATA
INFILE *
APPEND
INTO TABLE XXPO_RCV_TXNS_INTERFACE
FIELDS TERMINATED BY ','
TRAILING NULLCOLS
(
TXNS_ID                   SEQUENCE(MAX,1),
SOURCE_DOCUMENT_NUMBER    POSITION(1),
VENDOR_CODE               POSITION(*),
VENDOR_NAME               POSITION(*),
PROMISED_DATE             POSITION(*)   DATE(10) "YYYY/MM/DD",
LOCATION_CODE             POSITION(*),
LOCATION_NAME             POSITION(*),
SOURCE_DOCUMENT_LINE_NUM  POSITION(*),
ITEM_CODE                 POSITION(*),
ITEM_NAME                 POSITION(*),
LOT_NUMBER                POSITION(*),
PRODUCTED_DATE            POSITION(*)   DATE(10) "YYYY/MM/DD",
KOYU_CODE                 POSITION(*),
QUANTITY                  POSITION(*),
PO_LINE_DESCRIPTION       POSITION(*),
RCV_DATE                  POSITION(*)   DATE(10) "YYYY/MM/DD",
RCV_QUANTITY              POSITION(*),
RCV_QUANTITY_UOM          POSITION(*),
RCV_LINE_DESCRIPTION      POSITION(*),
CREATED_BY                CONSTANT 0,
CREATION_DATE             SYSDATE,
LAST_UPDATED_BY           CONSTANT 0,
LAST_UPDATE_DATE          SYSDATE,
LAST_UPDATE_LOGIN         CONSTANT 0,
REQUEST_ID                CONSTANT 0,
PROGRAM_APPLICATION_ID    CONSTANT 0,
PROGRAM_ID                CONSTANT 0,
PROGRAM_UPDATE_DATE       SYSDATE
)
