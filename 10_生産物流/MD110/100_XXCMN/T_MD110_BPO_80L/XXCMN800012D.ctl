-- **************************************************************************************
-- Copyright(c)Oracle Corporation Japan, 2006-2008. All rights reserved.
--
-- Control File  : XXCMN800012D.ctl
-- Description   : 品名インタフェースSQLLoader
-- MD.050        : マスタインタフェース         T_MD050_BPO_800
-- MD.070        : 品名インタフェースSQLLoader  T_MD070_BPO_80L
-- Version       : 1.1
--
-- Target Table  : XXCMN_ITEM_IF
--
-- Change Record
-- ------------- ----- ---------------- -------------------------------------------------
--  Date          Ver.  Editor           Description
-- ------------- ----- ---------------- -------------------------------------------------
--  2008/03/31    1.0   ORACLE 伊東愛美  初回作成
--  2008/06/19    1.1   ORACLE 弓場哲士  VARCHAR項目にRTRIM関数を付加
--  2008/11/13    1.2   ORACLE 伊藤      項目追加対応I_S_538
-- **************************************************************************************
LOAD DATA
INFILE *
APPEND
INTO TABLE XXCMN_ITEM_IF
FIELDS TERMINATED BY ','
TRAILING NULLCOLS
(
SEQ_NUMBER,
PROC_CODE,
ITEM_CODE                  CHAR "RTRIM(:ITEM_CODE, ' 　')",
ITEM_NAME                  CHAR "RTRIM(:ITEM_NAME, ' 　')",
ITEM_SHORT_NAME            CHAR "RTRIM(:ITEM_SHORT_NAME, ' 　')",
ITEM_NAME_ALT              CHAR "RTRIM(:ITEM_NAME_ALT, ' 　')",
OLD_CROWD_CODE             CHAR "RTRIM(:OLD_CROWD_CODE, ' 　')",
NEW_CROWD_CODE             CHAR "RTRIM(:NEW_CROWD_CODE, ' 　')",
CROWD_START_DATE           DATE(8)"YYYYMMDD",
POLICY_GROUP_CODE          CHAR "RTRIM(:POLICY_GROUP_CODE, ' 　')",
MARKE_CROWD_CODE           CHAR "RTRIM(:MARKE_CROWD_CODE, ' 　')",
OLD_PRICE                  CHAR "RTRIM(:OLD_PRICE, ' 　')",
NEW_PRICE                  CHAR "RTRIM(:NEW_PRICE, ' 　')",
PRICE_START_DATE           DATE(8)"YYYYMMDD",
OLD_STANDARD_COST          CHAR "RTRIM(:OLD_STANDARD_COST, ' 　')",
NEW_STANDARD_COST          CHAR "RTRIM(:NEW_STANDARD_COST, ' 　')",
STANDARD_START_DATE        DATE(8)"YYYYMMDD",
OLD_BUSINESS_COST          CHAR "RTRIM(:OLD_BUSINESS_COST, ' 　')",
NEW_BUSINESS_COST          CHAR "RTRIM(:NEW_BUSINESS_COST, ' 　')",
BUSINESS_START_DATE        DATE(8)"YYYYMMDD",
OLD_TAX                    CHAR "RTRIM(:OLD_TAX, ' 　')",
NEW_TAX                    CHAR "RTRIM(:NEW_TAX, ' 　')",
TAX_START_DATE             DATE(8)"YYYYMMDD",
RATE_CODE                  CHAR "RTRIM(:RATE_CODE, ' 　')",
CASE_NUM                   CHAR "RTRIM(:CASE_NUM, ' 　')",
PRODUCT_DIV_CODE           CHAR "RTRIM(:PRODUCT_DIV_CODE, ' 　')",
NET                        CHAR "RTRIM(:NET, ' 　')",
WEIGHT_VOLUME              CHAR "RTRIM(:WEIGHT_VOLUME, ' 　')",
ARTI_DIV_CODE              CHAR "RTRIM(:ARTI_DIV_CODE, ' 　')",
DIV_TEA_CODE               CHAR "RTRIM(:DIV_TEA_CODE, ' 　')",
PARENT_ITEM_CODE           CHAR "RTRIM(:PARENT_ITEM_CODE, ' 　')",
SALE_OBJ_CODE              CHAR "RTRIM(:SALE_OBJ_CODE, ' 　')",
JAN_CODE                   CHAR "RTRIM(:JAN_CODE, ' 　')",
SALE_START_DATE            DATE(8)"YYYYMMDD",
ABOLITION_CODE             CHAR "RTRIM(:ABOLITION_CODE, ' 　')",
ABOLITION_DATE             DATE(8)"YYYYMMDD",
RAW_MATE_CONSUMPTION       CHAR "RTRIM(:RAW_MATE_CONSUMPTION, ' 　')",
RAW_MATERIAL_COST          CHAR "RTRIM(:RAW_MATERIAL_COST, ' 　')",
AGEIN_COST                 CHAR "RTRIM(:AGEIN_COST, ' 　')",
MATERIAL_COST              CHAR "RTRIM(:MATERIAL_COST, ' 　')",
PACK_COST                  CHAR "RTRIM(:PACK_COST, ' 　')",
OUT_ORDER_COST             CHAR "RTRIM(:OUT_ORDER_COST, ' 　')",
SAFEKEEP_COST              CHAR "RTRIM(:SAFEKEEP_COST, ' 　')",
OTHER_EXPENSE_COST         CHAR "RTRIM(:OTHER_EXPENSE_COST, ' 　')",
SPARE1                     CHAR "RTRIM(:SPARE1, ' 　')",
SPARE2                     CHAR "RTRIM(:SPARE2, ' 　')",
SPARE3                     CHAR "RTRIM(:SPARE3, ' 　')",
HAISU,
DANSU,
BUNRUI,
NAIYOU,
NAIYOU_TANI,
UTIIRI,
YOKI_GUN_CODE              CHAR "RTRIM(:YOKI_GUN_CODE, ' 　')",
SPARE                      CHAR "RTRIM(:SPARE, ' 　')"
)