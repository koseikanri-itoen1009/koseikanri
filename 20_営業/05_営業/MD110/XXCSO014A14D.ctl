-- ************************************************************************************************
-- Copyright(c)Sumisho Corporation Japan, 2006-2008. All rights reserved.
-- 
-- Control file  : XXCSO014A05D.ctl
-- Description   : 営業システム構築プロジェクトアドオン：HHT-EBSインターフェース：(IN)ノート 
-- MD.050        : MD050_CSO_014_A05_HHT-EBSインターフェース：(IN）ノート_Draft2.0C.doc
-- MD.070        : なし
-- Version       : 1.0
--
-- Target Table  : XXCSO_IN_NOTES
--
-- Change Record
-- ------------- ------- ---------------- ---------------------------------------------------------
--  Date          Ver.    Editor           Description
-- ------------- ------- ---------------- ---------------------------------------------------------
--  2008/12/3     1.0     Seirin.Kin         新規作成
--  2009/03/16    1.1     Kunihiko.Boku      ノートのフィルド長指定
--
-- ************************************************************************************************

OPTIONS (SKIP=0, DIRECT=FALSE, ERRORS=99999)

LOAD DATA
CHARACTERSET JA16SJIS
APPEND
INTO TABLE XXCSO_IN_NOTES
FIELDS TERMINATED BY "," TRAILING NULLCOLS
  (  
    ACCOUNT_NUMBER          CHAR OPTIONALLY ENCLOSED BY '"' ,              -- 顧客コード
    NOTES                   CHAR(2000) OPTIONALLY ENCLOSED BY '"' ,        -- ノート
    EMPLOYEE_NUMBER         CHAR OPTIONALLY ENCLOSED BY '"' ,              -- 営業員コード
    INPUT_DATE              DATE "yyyymmdd",                               -- 入力日付
    INPUT_TIME              CHAR OPTIONALLY ENCLOSED BY '"' ,              -- 入力時刻
    NO_SEQ                  "XXCSO_IN_NOTES_S01.NEXTVAL",                   -- シーケンス番号
    CREATED_BY              "FND_GLOBAL.USER_ID",                          -- *** 作成者
    CREATION_DATE           SYSDATE,                                       -- *** 作成日
    LAST_UPDATED_BY         "FND_GLOBAL.USER_ID",                          -- *** 最終更新者
    LAST_UPDATE_DATE        SYSDATE,                                       -- *** 最終更新日
    LAST_UPDATE_LOGIN       "FND_GLOBAL.LOGIN_ID",                         -- *** 最終更新ログイン
    REQUEST_ID              "FND_GLOBAL.CONC_REQUEST_ID",                  -- *** 要求ID
    PROGRAM_APPLICATION_ID  "FND_GLOBAL.CONC_PROGRAM_ID",                  -- *** ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
    PROGRAM_ID              "FND_GLOBAL.CONC_PROGRAM_ID",                  -- *** ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
    PROGRAM_UPDATE_DATE     SYSDATE                                        -- *** ﾌﾟﾛｸﾞﾗﾑ更新日
  )