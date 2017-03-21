-- ************************************************************************************************
-- Copyright(c)SCSK Corporation, 2017. All rights reserved.
-- 
-- Control file  : XXCSO006A04D.ctl
-- Description   : eSM-EBSインタフェース：（IN）訪問実績データ（SQL-LOADER-訪問実績情報）
-- MD.050        : MD050_CSO_006_A03_eSM-EBSインタフェース：（IN）訪問実績データ
-- MD.070        : なし
-- Version       : 1.0
--
-- Target Table  : XXCSO_IN_VISIT_DATA
--
-- Change Record
-- ------------- ------- ---------------- ---------------------------------------------------------
--  Date          Ver.    Editor           Description
-- ------------- ------- ---------------- ---------------------------------------------------------
--  2017/03/15    1.0     K.Kiriu          新規作成
--
-- ************************************************************************************************
--
OPTIONS (DIRECT=FALSE, ERRORS=99999)
--
LOAD DATA
CHARACTERSET JA16SJIS
APPEND
INTO TABLE XXCSO_IN_VISIT_DATA
FIELDS TERMINATED BY "," TRAILING NULLCOLS
  (
    BASE_NAME                CHAR(360) OPTIONALLY ENCLOSED BY '"',                            -- 部署名
    EMPLOYEE_NUMBER          CHAR OPTIONALLY ENCLOSED BY '"',                                 -- 社員コード
    ACCOUNT_NUMBER           CHAR OPTIONALLY ENCLOSED BY '"',                                 -- 顧客コード
    BUSINESS_TYPE            CHAR(100) OPTIONALLY ENCLOSED BY '"',                            -- 業務タイプ
    VISIT_DATE               DATE "YYYY/MM/DD" OPTIONALLY ENCLOSED BY '"',                    -- 訪問日
    VISIT_TIME               CHAR OPTIONALLY ENCLOSED BY '"',                                 -- 訪問開始時刻
    VISIT_TIME_END           CHAR OPTIONALLY ENCLOSED BY '"',                                 -- 訪問終了時刻
    DETAIL                   CHAR(4000) OPTIONALLY ENCLOSED BY '"',                           -- 詳細内容
    ACTIVITY_CONTENT1        CHAR OPTIONALLY ENCLOSED BY '"',                                 -- 活動内容１
    ACTIVITY_CONTENT2        CHAR OPTIONALLY ENCLOSED BY '"',                                 -- 活動内容２
    ACTIVITY_CONTENT3        CHAR OPTIONALLY ENCLOSED BY '"',                                 -- 活動内容３
    ACTIVITY_CONTENT4        CHAR OPTIONALLY ENCLOSED BY '"',                                 -- 活動内容４
    ACTIVITY_CONTENT5        CHAR OPTIONALLY ENCLOSED BY '"',                                 -- 活動内容５
    ACTIVITY_CONTENT6        CHAR OPTIONALLY ENCLOSED BY '"',                                 -- 活動内容６
    ACTIVITY_CONTENT7        CHAR OPTIONALLY ENCLOSED BY '"',                                 -- 活動内容７
    ACTIVITY_CONTENT8        CHAR OPTIONALLY ENCLOSED BY '"',                                 -- 活動内容８
    ACTIVITY_CONTENT9        CHAR OPTIONALLY ENCLOSED BY '"',                                 -- 活動内容９
    ACTIVITY_CONTENT10       CHAR OPTIONALLY ENCLOSED BY '"',                                 -- 活動内容１０
    ACTIVITY_CONTENT11       CHAR OPTIONALLY ENCLOSED BY '"',                                 -- 活動内容１１
    ACTIVITY_CONTENT12       CHAR OPTIONALLY ENCLOSED BY '"',                                 -- 活動内容１２
    ACTIVITY_CONTENT13       CHAR OPTIONALLY ENCLOSED BY '"',                                 -- 活動内容１３
    ACTIVITY_CONTENT14       CHAR OPTIONALLY ENCLOSED BY '"',                                 -- 活動内容１４
    ACTIVITY_CONTENT15       CHAR OPTIONALLY ENCLOSED BY '"',                                 -- 活動内容１５
    ACTIVITY_CONTENT16       CHAR OPTIONALLY ENCLOSED BY '"',                                 -- 活動内容１６
    ACTIVITY_CONTENT17       CHAR OPTIONALLY ENCLOSED BY '"',                                 -- 活動内容１７
    ACTIVITY_CONTENT18       CHAR OPTIONALLY ENCLOSED BY '"',                                 -- 活動内容１８
    ACTIVITY_CONTENT19       CHAR OPTIONALLY ENCLOSED BY '"',                                 -- 活動内容１９
    ACTIVITY_CONTENT20       CHAR OPTIONALLY ENCLOSED BY '"',                                 -- 活動内容２０
    ACTIVITY_TIME1           INTEGER EXTERNAL OPTIONALLY ENCLOSED BY '"',                     -- 活動時間１(分）
    ACTIVITY_TIME2           INTEGER EXTERNAL OPTIONALLY ENCLOSED BY '"',                     -- 活動時間２（分）
    ACTIVITY_TIME3           INTEGER EXTERNAL OPTIONALLY ENCLOSED BY '"',                     -- 活動時間３（分）
    ACTIVITY_TIME4           INTEGER EXTERNAL OPTIONALLY ENCLOSED BY '"',                     -- 活動時間４（分）
    ACTIVITY_TIME5           INTEGER EXTERNAL OPTIONALLY ENCLOSED BY '"',                     -- 活動時間５（分）
    ACTIVITY_TIME6           INTEGER EXTERNAL OPTIONALLY ENCLOSED BY '"',                     -- 活動時間６（分）
    ACTIVITY_TIME7           INTEGER EXTERNAL OPTIONALLY ENCLOSED BY '"',                     -- 活動時間７（分）
    ACTIVITY_TIME8           INTEGER EXTERNAL OPTIONALLY ENCLOSED BY '"',                     -- 活動時間８（分）
    ACTIVITY_TIME9           INTEGER EXTERNAL OPTIONALLY ENCLOSED BY '"',                     -- 活動時間９（分）
    ACTIVITY_TIME10          INTEGER EXTERNAL OPTIONALLY ENCLOSED BY '"',                     -- 活動時間１０（分）
    ACTIVITY_TIME11          INTEGER EXTERNAL OPTIONALLY ENCLOSED BY '"',                     -- 活動時間１１（分）
    ACTIVITY_TIME12          INTEGER EXTERNAL OPTIONALLY ENCLOSED BY '"',                     -- 活動時間１２（分）
    ACTIVITY_TIME13          INTEGER EXTERNAL OPTIONALLY ENCLOSED BY '"',                     -- 活動時間１３（分）
    ACTIVITY_TIME14          INTEGER EXTERNAL OPTIONALLY ENCLOSED BY '"',                     -- 活動時間１４（分）
    ACTIVITY_TIME15          INTEGER EXTERNAL OPTIONALLY ENCLOSED BY '"',                     -- 活動時間１５（分）
    ACTIVITY_TIME16          INTEGER EXTERNAL OPTIONALLY ENCLOSED BY '"',                     -- 活動時間１６（分）
    ACTIVITY_TIME17          INTEGER EXTERNAL OPTIONALLY ENCLOSED BY '"',                     -- 活動時間１７（分）
    ACTIVITY_TIME18          INTEGER EXTERNAL OPTIONALLY ENCLOSED BY '"',                     -- 活動時間１８（分）
    ACTIVITY_TIME19          INTEGER EXTERNAL OPTIONALLY ENCLOSED BY '"',                     -- 活動時間１９（分）
    ACTIVITY_TIME20          INTEGER EXTERNAL OPTIONALLY ENCLOSED BY '"',                     -- 活動時間２０（分）
    ESM_INPUT_DATE           DATE "YYYY/MM/DD HH24:MI" OPTIONALLY ENCLOSED BY '"',            -- eSM入力日時
    SEQ_NO                   "XXCSO_IN_VISIT_DATA_S01.NEXTVAL",                               -- シーケンス番号
    CREATED_BY               "FND_GLOBAL.USER_ID",                                            -- *** 作成者
    CREATION_DATE            SYSDATE,                                                         -- *** 作成日
    LAST_UPDATED_BY          "FND_GLOBAL.USER_ID",                                            -- *** 最終更新者
    LAST_UPDATE_DATE         SYSDATE,                                                         -- *** 最終更新日
    LAST_UPDATE_LOGIN        "FND_GLOBAL.LOGIN_ID",                                           -- *** 最終更新ログイン
    REQUEST_ID               "FND_GLOBAL.CONC_REQUEST_ID",                                    -- *** 要求ID
    PROGRAM_APPLICATION_ID   "FND_GLOBAL.PROG_APPL_ID",                                       -- *** ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
    PROGRAM_ID               "FND_GLOBAL.CONC_PROGRAM_ID",                                    -- *** ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
    PROGRAM_UPDATE_DATE      SYSDATE                                                          -- *** ﾌﾟﾛｸﾞﾗﾑ更新日
  )