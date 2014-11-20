-- ************************************************************************************************
-- Copyright(c)Sumisho Corporation Japan, 2006-2008. All rights reserved.
-- 
-- Control file  : XXCSO014A13D.ctl
-- Description   : HHT-EBSインターフェース：(IN)ルート情報(SQL-LOADER-ルート情報)
-- MD.050        : MD050_IPO_CSO_014_A04_HHT-EBSインターフェース：(IN)ルート情報(SQL-LOADER-ルート情報)
-- MD.070        : なし
-- Version       : 1.0
--
-- Target Table  : XXCSO_IN_ROUTE_NO
--
-- Change Record
-- ------------- ------- ---------------- ---------------------------------------------------------
--  Date          Ver.    Editor           Description
-- ------------- ------- ---------------- ---------------------------------------------------------
--  2009/1/16    1.0     Kenji.Sai        新規作成
--  2009/5/7     1.1     Tomoko.Mori      T1_0912対応
--
-- ************************************************************************************************
--
OPTIONS (SKIP=0, DIRECT=FALSE, ERRORS=99999)
--
LOAD DATA
CHARACTERSET JA16SJIS
APPEND
INTO TABLE XXCSO_IN_ROUTE_NO
FIELDS TERMINATED BY "," TRAILING NULLCOLS
  (
    NO_SEQ                  INTEGER EXTERNAL "XXCSO_IN_ROUTE_NO_S01.NEXTVAL",    -- シーケンス番号
    RECORD_NUMBER           POSITION(1) INTEGER EXTERNAL,                        -- レコード番号
    ACCOUNT_NUMBER          POSITION(*) CHAR OPTIONALLY ENCLOSED BY '"' ,        -- 顧客コード
--    /*20090507_mori_T1_0912 START*/
    ROUTE_NO                POSITION(*) CHAR OPTIONALLY ENCLOSED BY '"' "TRIM(' ' from :ROUTE_NO)",        -- ルートコード
--    ROUTE_NO                POSITION(*) CHAR OPTIONALLY ENCLOSED BY '"' ,        -- ルートコード
--    /*20090507_mori_T1_0912 END*/
    INPUT_DATE              POSITION(*) INTEGER EXTERNAL "TO_DATE(:INPUT_DATE,'YYYYMMDD')" , -- 入力日付
    COALITION_TRANCE_DATE   SYSDATE,                                             -- 連携処理日
    CREATED_BY              "FND_GLOBAL.USER_ID",                                -- *** 作成者
    CREATION_DATE           SYSDATE,                                             -- *** 作成日
    LAST_UPDATED_BY         "FND_GLOBAL.USER_ID",                                -- *** 最終更新者
    LAST_UPDATE_DATE        SYSDATE,                                             -- *** 最終更新日
    LAST_UPDATE_LOGIN       "FND_GLOBAL.LOGIN_ID",                               -- *** 最終更新ログイン
    REQUEST_ID              "FND_GLOBAL.CONC_REQUEST_ID",                        -- *** 要求ID
    PROGRAM_APPLICATION_ID  "FND_GLOBAL.CONC_PROGRAM_ID",                        -- *** ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
    PROGRAM_ID              "FND_GLOBAL.CONC_PROGRAM_ID",                        -- *** ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
    PROGRAM_UPDATE_DATE     SYSDATE                                              -- *** ﾌﾟﾛｸﾞﾗﾑ更新日
  )