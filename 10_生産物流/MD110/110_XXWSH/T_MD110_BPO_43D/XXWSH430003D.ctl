-- **************************************************************************************
-- Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
--
-- Package Name     : xxwsh430003d(ctl)
-- Description      : 倉替返品情報インターフェース SQL*Loader処理
-- MD.050           : 倉替返品                                    T_MD050_BPO_430
-- MD.070           : 倉替返品情報インターフェース_SQLLoader処理  T_MD070_BPO_43D
-- Version          : 1.1
--
-- Change Record
-- ------------- ----- ----------------- ------------------------------------------------
--  Date          Ver.  Editor            Description
-- ------------- ----- ----------------- ------------------------------------------------
--  2008/02/22    1.0   Oracle 椎名 昭圭 初回作成
--  2008/05/16    1.1   Oracle 椎名 昭圭 内部変更要求#100対応
-- **************************************************************************************
LOAD DATA
INFILE *
APPEND
INTO TABLE XXWSH_RESERVE_INTERFACE
FIELDS TERMINATED BY ','
TRAILING NULLCOLS
(
RESERVE_INTERFACE_ID    SEQUENCE(MAX,1),
DATA_CLASS              POSITION(1),
R_NO                    POSITION(*),
CONTINUE                POSITION(*),
RECORDED_YEAR           POSITION(*),
INPUT_BASE_CODE         POSITION(*),
RECEIVE_BASE_CODE       POSITION(*),
INVOICE_CLASS_1         POSITION(*),
INVOICE_CLASS_2         POSITION(*),
RECORDED_DATE           POSITION(*)   DATE(8)"YYYYMMDD",
SHIP_TO_CODE            POSITION(*),
CUSTOMER_CODE           POSITION(*),
INVOICE_NO              POSITION(*),
ITEM_CODE               POSITION(*),
PARENT_ITEM_CODE        POSITION(*),
CROWD_CODE              POSITION(*),
CASE_AMOUNT_OF_CONTENT  POSITION(*),
QUANTITY_IN_CASE        POSITION(*),
QUANTITY                POSITION(*),
CREATED_BY              CONSTANT 0,
CREATION_DATE           SYSDATE,
LAST_UPDATED_BY         CONSTANT 0,
LAST_UPDATE_DATE        SYSDATE,
LAST_UPDATE_LOGIN       CONSTANT 0,
REQUEST_ID              CONSTANT 0,
PROGRAM_APPLICATION_ID  CONSTANT 0,
PROGRAM_ID              CONSTANT 0,
PROGRAM_UPDATE_DATE     SYSDATE
)
