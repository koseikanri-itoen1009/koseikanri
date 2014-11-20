-- **************************************************************************************
-- Copyright(c)Oracle Corporation Japan, 2006-2008. All rights reserved.
--
-- Control File  : XXCMN800010D.ctl
-- Description   : 拠点インタフェースSQLLoader
-- MD.050        : マスタインタフェース         T_MD050_BPO_800
-- MD.070        : 拠点インタフェースSQLLoader  T_MD070_BPO_80J
-- Version       : 1.1
--
-- Target Table  : XXCMN_PARTY_IF
--
-- Change Record
-- ------------- ----- ---------------- -------------------------------------------------
--  Date          Ver.  Editor           Description
-- ------------- ----- ---------------- -------------------------------------------------
--  2008/03/31    1.0   ORACLE 伊東愛美  初回作成
--  2008/06/19    1.1   ORACLE 弓場哲士  VARCHAR項目にRTRIM関数を付加
-- **************************************************************************************
LOAD DATA
INFILE *
APPEND
INTO TABLE XXCMN_PARTY_IF
FIELDS TERMINATED BY ',' 
TRAILING NULLCOLS
(
SEQ_NUMBER,
PROC_CODE,
BASE_CODE                    CHAR "RTRIM(:BASE_CODE, ' 　')",
PARTY_NAME                   CHAR "RTRIM(:PARTY_NAME, ' 　')",
PARTY_SHORT_NAME             CHAR "RTRIM(:PARTY_SHORT_NAME, ' 　')",
PARTY_NAME_ALT               CHAR "RTRIM(:PARTY_NAME_ALT, ' 　')",
ADDRESS                      CHAR "RTRIM(:ADDRESS, ' 　')",
ZIP                          CHAR "RTRIM(:ZIP, ' 　')",
PHONE                        CHAR "RTRIM(:PHONE, ' 　')",
FAX                          CHAR "RTRIM(:FAX, ' 　')",
OLD_DIVISION_CODE            CHAR "RTRIM(:OLD_DIVISION_CODE, ' 　')",
NEW_DIVISION_CODE            CHAR "RTRIM(:NEW_DIVISION_CODE, ' 　')",
DIVISION_START_DATE          DATE(8) "YYYYMMDD",
LOCATION_REL_CODE            CHAR "RTRIM(:LOCATION_REL_CODE, ' 　')",
SHIP_MNG_CODE                CHAR "RTRIM(:SHIP_MNG_CODE, ' 　')",
DISTRICT_CODE                CHAR "RTRIM(:DISTRICT_CODE, ' 　')",
WAREHOUSE_CODE               CHAR "RTRIM(:WAREHOUSE_CODE, ' 　')",
TERMINAL_CODE                CHAR "RTRIM(:TERMINAL_CODE, ' 　')",
ZIP2                         CHAR "RTRIM(:ZIP2, ' 　')",
SPARE                        CHAR "RTRIM(:SPARE, ' 　')"
)
