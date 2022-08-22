-- **************************************************************************************
-- Copyright(c)Oracle Corporation Japan, 2006-2008. All rights reserved.
--
-- Control File  : XXCMN800013D.ctl
-- Description   : 社員インタフェースSQLLoader
-- MD.050        : マスタインタフェース         T_MD050_BPO_800
-- MD.070        : 社員インタフェースSQLLoader  T_MD070_BPO_80M
-- Version       : 1.1
--
-- Target Table  : XXCMN_EMP_IF
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
INTO TABLE XXCMN_EMP_IF
FIELDS TERMINATED BY ','
TRAILING NULLCOLS
(
SEQ_NUM,
PROC_CODE,
EMPLOYEE_NUM        CHAR "RTRIM(:EMPLOYEE_NUM, ' 　')",
BASE_CODE           CHAR "RTRIM(:BASE_CODE, ' 　')",
USER_NAME           CHAR "RTRIM(:USER_NAME, ' 　')",
USER_NAME_ALT       CHAR "RTRIM(:USER_NAME_ALT, ' 　')",
POSITION_ID         CHAR "RTRIM(:POSITION_ID, ' 　')",
QUALIFICATION_ID    CHAR "RTRIM(:QUALIFICATION_ID, ' 　')",
SPARE               CHAR "RTRIM(:SPARE, ' 　')"
)
