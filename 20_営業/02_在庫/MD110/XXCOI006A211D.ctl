-- ****************************************************************************************
-- Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
--
-- Control File  : XXCOI006A211D.ctl
-- Description   : íIâµåãâ çÏê¨ÅiSQLLoaderÅj
-- MD.050        : HHTíIâµåãâ ÉfÅ[É^éÊçû MD050_COI_006_A21
-- Version       : 1.1
--
-- Target Table  : XXCOI_IN_INV_RESULT_FILE_IF
--
-- Change Record
-- ------------- ----- ---------------- -------------------------------------------------
--  Date          Ver.  Editor           Description
-- ------------- ----- ---------------- -------------------------------------------------
--  2009/01/29    1.0   SCS N.Abe        êVãKçÏê¨
--  2009/02/12    1.1   SCS N.Abe        [è·äQCOI_001] ì˙ïtÇÃå^ïsîıëŒâû
--****************************************************************************************
LOAD DATA
INFILE *
APPEND
INTO TABLE "XXCOI_IN_INV_RESULT_FILE_IF"
FIELDS TERMINATED BY ','
(
    INTERFACE_ID
    ,INPUT_ORDER             SEQUENCE(MAX)
    ,BASE_CODE               OPTIONALLY ENCLOSED BY '"'
    ,INVENTORY_KBN           OPTIONALLY ENCLOSED BY '"'
    ,INVENTORY_DATE          DATE(8) "YYYYMMDD"
    ,WAREHOUSE_KBN           OPTIONALLY ENCLOSED BY '"'
    ,WAREHOUSE_KBN_NAME      OPTIONALLY ENCLOSED BY '"'
    ,INVENTORY_PLACE         OPTIONALLY ENCLOSED BY '"'
    ,ITEM_CODE               OPTIONALLY ENCLOSED BY '"'
    ,CASE_QTY                
    ,CASE_IN_QTY             
    ,QUANTITY                
    ,SLIP_NO                 OPTIONALLY ENCLOSED BY '"'
    ,QUALITY_GOODS_KBN       OPTIONALLY ENCLOSED BY '"'
    ,QUALITY_GOODS_KBN_NAME  OPTIONALLY ENCLOSED BY '"'
    ,RECEIVE_DATE            DATE(19) "YYYY/MM/DD HH24:MI:SS" OPTIONALLY ENCLOSED BY '"'
    ,CREATED_BY              CONSTANT "-1"
    ,CREATION_DATE           SYSDATE
    ,LAST_UPDATED_BY         CONSTANT "-1" 
    ,LAST_UPDATE_DATE        SYSDATE
    ,LAST_UPDATE_LOGIN       CONSTANT "-1"
    ,REQUEST_ID              CONSTANT "-1"
    ,PROGRAM_APPLICATION_ID  CONSTANT "-1"
    ,PROGRAM_ID              CONSTANT "-1"
    ,PROGRAM_UPDATE_DATE     SYSDATE
)

