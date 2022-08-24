-- ************************************************************************************************
-- Copyright(c)Sumisho Corporation Japan, 2006-2008. All rights reserved.
-- 
-- Control file  : XXCSO014A11D.ctl
-- Description   : HHT-EBSインターフェース：(IN)売上計画（SQL-LOADER-売上計画日別）
-- MD.050        : MD050_IPO_CSO_014_A01_HHT-EBSインターフェース：(IN)売上計画(SQL-LOADER-売上計画日別)
-- MD.070        : なし
-- Version       : 1.0
--
-- Target Table  : XXCSO_IN_SALES_PLAN_DAY
--
-- Change Record
-- ------------- ------- ---------------- ---------------------------------------------------------
--  Date          Ver.    Editor           Description
-- ------------- ------- ---------------- ---------------------------------------------------------
--  2008/12/22    1.0     Kenji.Sai         新規作成
--
-- ************************************************************************************************
--
OPTIONS (SKIP=0, DIRECT=FALSE, ERRORS=99999)
--
LOAD DATA
CHARACTERSET JA16SJIS
APPEND
INTO TABLE XXCSO_IN_SALES_PLAN_DAY
FIELDS TERMINATED BY "," TRAILING NULLCOLS
  (  
    NO_SEQ                  INTEGER EXTERNAL "XXCSO_IN_SALES_PLAN_DAY_S01.NEXTVAL",    -- シーケンス番号
    RECORD_NUMBER           POSITION(1) INTEGER EXTERNAL,                              -- レコード番号
    ACCOUNT_NUMBER          POSITION(*) CHAR OPTIONALLY ENCLOSED BY '"' ,              -- 顧客コード
    SALES_BASE_CODE         POSITION(*) CHAR OPTIONALLY ENCLOSED BY '"' ,              -- 売上拠点コード
    SALES_PLAN_DAY          POSITION(*) INTEGER EXTERNAL "TO_CHAR(TO_DATE(:SALES_PLAN_DAY,'YYYYMMDD'),'YYYYMMDD')", -- 売上計画年月日
    SALES_PLAN_AMT          POSITION(*) INTEGER EXTERNAL,                              -- 売上計画金額
    COALITION_TRANCE_DATE   SYSDATE,                                                   -- 連携処理日
    CREATED_BY              "FND_GLOBAL.USER_ID",                                      -- *** 作成者
    CREATION_DATE           SYSDATE,                                                   -- *** 作成日
    LAST_UPDATED_BY         "FND_GLOBAL.USER_ID",                                      -- *** 最終更新者
    LAST_UPDATE_DATE        SYSDATE,                                                   -- *** 最終更新日
    LAST_UPDATE_LOGIN       "FND_GLOBAL.LOGIN_ID",                                     -- *** 最終更新ログイン
    REQUEST_ID              "FND_GLOBAL.CONC_REQUEST_ID",                              -- *** 要求ID
    PROGRAM_APPLICATION_ID  "FND_GLOBAL.CONC_PROGRAM_ID",                              -- *** ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
    PROGRAM_ID              "FND_GLOBAL.CONC_PROGRAM_ID",                              -- *** ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
    PROGRAM_UPDATE_DATE     SYSDATE                                                    -- *** ﾌﾟﾛｸﾞﾗﾑ更新日
  )