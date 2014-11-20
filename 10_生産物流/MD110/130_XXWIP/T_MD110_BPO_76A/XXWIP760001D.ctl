-- **************************************************************************************
-- Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
--
-- Package Name     : XXWIP760001D(ctl)
-- Description      : 品目別按分運賃明細アドオン SQL*Loader処理
-- Version          : 1.1
--
-- Change Record
-- ------------- ----- ----------------- ------------------------------------------------
--  Date          Ver.  Editor            Description
-- ------------- ----- ----------------- ------------------------------------------------
--  2009/01/13    1.0   KCG 別所 典隆     初回作成
-- **************************************************************************************
LOAD DATA
INFILE *
APPEND
INTO TABLE XXWIP_DELIVERY_ITEM_DETAILS
FIELDS TERMINATED BY ',' 
TRAILING NULLCOLS
(
DELIVERY_ITEM_DETAILS_ID       SEQUENCE(MAX,1),
DELIVERY_NO,
REQUEST_NO,
DELIVERY_ITEM_DETAILS_CLASS,
ORDER_TYPE,
REQ_STATUS,
HEAD_SALES_BRANCH,
FREIGHT_CARRIER_CODE,
SHIP_TO_DELIVER_TO_CODE,
DELIVER_FROM,
SHIPPING_METHOD_CODE,
SHIPPED_DATE                   DATE(21) "YYYY/MM/DD HH24:MI:SS",
ARRIVAL_DATE                   DATE(21) "YYYY/MM/DD HH24:MI:SS",
ITEM_NO,
SHIPPED_QUANTITY,
SHIPPED_CASE_QUANTITY,
SUM_CASE_QUANTITY,
SUM_LOADING_WEIGHT,
CALC_SUM_LOADING_WEIGHT,
ITEM_LOADING_WEIGHT,
CALC_ITEM_LOADING_WEIGHT,
SUM_AMOUNT,
ITEM_AMOUNT,
CREATED_BY                     CONSTANT 1,
CREATION_DATE                  SYSDATE,
LAST_UPDATED_BY                CONSTANT 1,
LAST_UPDATE_DATE               SYSDATE,
LAST_UPDATE_LOGIN              CONSTANT 1,
REQUEST_ID                     CONSTANT 1,
PROGRAM_APPLICATION_ID         CONSTANT 1,
PROGRAM_ID                     CONSTANT 1,
PROGRAM_UPDATE_DATE            SYSDATE
)
