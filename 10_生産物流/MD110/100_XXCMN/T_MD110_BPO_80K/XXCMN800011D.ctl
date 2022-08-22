-- **************************************************************************************
-- Copyright(c)Oracle Corporation Japan, 2006-2008. All rights reserved.
--
-- Control File  : XXCMN800011D.ctl
-- Description   : 配送先インタフェースSQLLoader
-- MD.050        : マスタインタフェース           T_MD050_BPO_800
-- MD.070        : 配送先インタフェースSQLLoader  T_MD070_BPO_80K
-- Version       : 1.1
--
-- Target Table  : XXCMN_SITE_IF
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
INTO TABLE XXCMN_SITE_IF
FIELDS TERMINATED BY ','
TRAILING NULLCOLS
(
SEQ_NUMBER,
PROC_CODE,
SHIP_TO_CODE          CHAR "RTRIM(:SHIP_TO_CODE, ' 　')",
BASE_CODE             CHAR "RTRIM(:BASE_CODE, ' 　')",
PARTY_SITE_NAME1      CHAR "RTRIM(:PARTY_SITE_NAME1, ' 　')",
PARTY_SITE_NAME2      CHAR "RTRIM(:PARTY_SITE_NAME2, ' 　')",
PARTY_SITE_ADDR1      CHAR "RTRIM(:PARTY_SITE_ADDR1, ' 　')",
PARTY_SITE_ADDR2      CHAR "RTRIM(:PARTY_SITE_ADDR2, ' 　')",
PHONE                 CHAR "RTRIM(:PHONE, ' 　')",
FAX                   CHAR "RTRIM(:FAX, ' 　')",
ZIP                   CHAR "RTRIM(:ZIP, ' 　')",
PARTY_NUM             CHAR "RTRIM(:PARTY_NUM, ' 　')",
ZIP2                  CHAR "RTRIM(:ZIP2, ' 　')",
CUSTOMER_NAME1        CHAR "RTRIM(:CUSTOMER_NAME1, ' 　')",
CUSTOMER_NAME2        CHAR "RTRIM(:CUSTOMER_NAME2, ' 　')",
SALE_BASE_CODE        CHAR "RTRIM(:SALE_BASE_CODE, ' 　')",
RES_SALE_BASE_CODE    CHAR "RTRIM(:RES_SALE_BASE_CODE, ' 　')",
CHAIN_STORE           CHAR "RTRIM(:CHAIN_STORE, ' 　')",
CHAIN_STORE_NAME      CHAR "RTRIM(:CHAIN_STORE_NAME, ' 　')",
CAL_CUST_APP_FLG      CHAR "RTRIM(:CAL_CUST_APP_FLG, ' 　')",
DIRECT_SHIP_CODE      CHAR "RTRIM(:DIRECT_SHIP_CODE, ' 　')",
SHIFT_JUDG_FLG        CHAR "RTRIM(:SHIFT_JUDG_FLG, ' 　')"
)