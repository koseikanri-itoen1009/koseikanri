-- ************************************************************************************************
-- Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
-- 
-- Control file  : XXCSO015A06D.ctl
-- Description   : 自販機-EBSインタフェース：(IN)物件マスタ－ SQL*Loader処理
-- BR.050        : T_BR050_CCO_200_自販_物件ファイル
-- MD.050        : なし
-- MD.070        : なし
-- Version       : 1.1
--
-- Target Table  : XXCSO_IN_ITEM_DATA
--
-- Change Record
-- ------------- ------- ---------------- ---------------------------------------------------------
--  Date          Ver.    Editor           Description
-- ------------- ------- ---------------- ---------------------------------------------------------
--  2008/12/1    1.0     kyo              新規作成
--  2016/02/05   1.1     S.Niki           [E_本稼動_13456]自販機管理システム代替対応
--
-- ************************************************************************************************
--
OPTIONS (SKIP=0, DIRECT=FALSE, ERRORS=99999)
--
LOAD DATA
CHARACTERSET JA16SJIS
INTO TABLE XXCSO_IN_ITEM_DATA
APPEND
FIELDS TERMINATED BY "," TRAILING NULLCOLS
  (
    INSTALL_CODE                   CHAR OPTIONALLY ENCLOSED BY '"' "DECODE(:INSTALL_CODE, NULL, NULL, SUBSTR(:INSTALL_CODE, 1, 3) || '-' || SUBSTR(:INSTALL_CODE, 4))",  -- 物件コード
    UN_NUMBER                      CHAR OPTIONALLY ENCLOSED BY '"',     -- 機種
    INSTALL_NUMBER                 CHAR OPTIONALLY ENCLOSED BY '"',     -- 機番
    MACHINERY_KBN                  INTEGER EXTERNAL,                    -- 機器区分
    MANUFACTURER_CODE              CHAR OPTIONALLY ENCLOSED BY '"',     -- メーカー
    AGE_TYPE                       CHAR OPTIONALLY ENCLOSED BY '"',     -- 年式
    SELE_NUMBER                    INTEGER EXTERNAL,                    -- セレ数
    SPECIAL_MACHINE1               CHAR OPTIONALLY ENCLOSED BY '"',     -- 特殊機１
    SPECIAL_MACHINE2               CHAR OPTIONALLY ENCLOSED BY '"',     -- 特殊機２
    SPECIAL_MACHINE3               CHAR OPTIONALLY ENCLOSED BY '"',     -- 特殊機３
    FIRST_INSTALL_DATE             INTEGER EXTERNAL,                    -- 初回設置日
    COUNTER_NO                     INTEGER EXTERNAL,                    -- カウンターNo.
    DIVISION_CODE                  CHAR OPTIONALLY ENCLOSED BY '"',     -- 地区コード
    BASE_CODE                      CHAR OPTIONALLY ENCLOSED BY '"',     -- 拠点コード
    JOB_COMPANY_CODE               CHAR OPTIONALLY ENCLOSED BY '"',     -- 作業会社コード
    LOCATION_CODE                  CHAR OPTIONALLY ENCLOSED BY '"',     -- 事業所コード
    LAST_JOB_SLIP_NO               INTEGER EXTERNAL,                    -- 最終作業伝票No.
    LAST_JOB_KBN                   INTEGER EXTERNAL,                    -- 最終作業区分
    LAST_JOB_GOING                 INTEGER EXTERNAL,                    -- 最終作業進捗
    LAST_JOB_COMPLETION_PLAN_DATE  INTEGER EXTERNAL,                    -- 最終作業完了予定日
    LAST_JOB_COMPLETION_DATE       INTEGER EXTERNAL,                    -- 最終作業完了日
    LAST_MAINTENANCE_CONTENTS      INTEGER EXTERNAL,                    -- 最終整備内容
    LAST_INSTALL_SLIP_NO           INTEGER EXTERNAL,                    -- 最終設置伝票No.
    LAST_INSTALL_KBN               INTEGER EXTERNAL,                    -- 最終設置区分
    LAST_INSTALL_PLAN_DATE         INTEGER EXTERNAL,                    -- 最終設置予定日
    LAST_INSTALL_GOING             INTEGER EXTERNAL,                    -- 最終設置進捗
    MACHINERY_STATUS1              INTEGER EXTERNAL,                    -- 機器状態1（稼動状態）
    MACHINERY_STATUS2              INTEGER EXTERNAL,                    -- 機器状態2（状態詳細）
    MACHINERY_STATUS3              INTEGER EXTERNAL,                    -- 機器状態3（廃棄情報）
    STOCK_DATE                     INTEGER EXTERNAL,                    -- 入庫日
    WITHDRAW_COMPANY_CODE          CHAR OPTIONALLY ENCLOSED BY '"',     -- 引揚会社コード
    WITHDRAW_LOCATION_CODE         CHAR OPTIONALLY ENCLOSED BY '"',     -- 引揚事業所コード
    INSTALL_NAME                   CHAR OPTIONALLY ENCLOSED BY '"',     -- 設置先名
    INSTALL_EMPLOYEE_NAME          CHAR OPTIONALLY ENCLOSED BY '"',     -- 設置先担当者名
    INSTALL_PHONE_NUMBER1          CHAR OPTIONALLY ENCLOSED BY '"',     -- 設置先TEL１
    INSTALL_PHONE_NUMBER2          CHAR OPTIONALLY ENCLOSED BY '"',     -- 設置先TEL２
    INSTALL_PHONE_NUMBER3          CHAR OPTIONALLY ENCLOSED BY '"',     -- 設置先TEL３
    INSTALL_POSTAL_CODE            INTEGER EXTERNAL,                    -- 設置先郵便番号
    INSTALL_ADDRESS1               CHAR OPTIONALLY ENCLOSED BY '"',     -- 設置先住所１
    INSTALL_ADDRESS2               CHAR OPTIONALLY ENCLOSED BY '"',     -- 設置先住所２
    INSTALL_ADDRESS3               CHAR OPTIONALLY ENCLOSED BY '"',     -- 設置先住所３
    INSTALL_ADDRESS4               CHAR OPTIONALLY ENCLOSED BY '"',     -- 設置先住所４
    INSTALL_ADDRESS5               CHAR OPTIONALLY ENCLOSED BY '"',     -- 設置先住所５
    DISPOSAL_APPROVAL_DATE         INTEGER EXTERNAL,                    -- 廃棄決裁日
    RESALE_DISPOSAL_VENDOR         CHAR OPTIONALLY ENCLOSED BY '"',     -- 転売廃棄業者
    RESALE_DISPOSAL_SLIP_NO        INTEGER EXTERNAL,                    -- 転売廃棄伝票№
    OWNER_COMPANY_CODE             CHAR OPTIONALLY ENCLOSED BY '"',     -- 所有者
    LEASE_START_DATE               INTEGER EXTERNAL,                    -- リース開始日
    LEASE_CHARGE                   INTEGER EXTERNAL,                    -- リース料
    ORG_CONTRACT_NUMBER            CHAR OPTIONALLY ENCLOSED BY '"',     -- 原契約番号
    ORG_CONTRACT_LINE_NUMBER       INTEGER EXTERNAL,                    -- 原契約番号-枝番
    CONTRACT_DATE                  INTEGER EXTERNAL,                    -- 現契約日
    CONTRACT_NUMBER                CHAR OPTIONALLY ENCLOSED BY '"',     -- 現契約番号
    CONTRACT_LINE_NUMBER           INTEGER EXTERNAL,                    -- 現契約番号-枝番
    RESALE_DISPOSAL_FLAG           INTEGER EXTERNAL,                    -- 転売廃棄状況フラグ
    RESALE_COMPLETION_KBN          INTEGER EXTERNAL,                    -- 転売完了区分
    DELETE_FLAG                    INTEGER EXTERNAL,                    -- 削除フラグ
    CREATION_EMPLOYEE_NUMBER       CHAR OPTIONALLY ENCLOSED BY '"',     -- 作成担当者コード
    CREATION_SECTION_NAME          CHAR OPTIONALLY ENCLOSED BY '"',     -- 作成部署コード
    CREATION_PROGRAM_ID            CHAR OPTIONALLY ENCLOSED BY '"',     -- 作成プログラムＩＤ
    UPDATE_EMPLOYEE_NUMBER         CHAR OPTIONALLY ENCLOSED BY '"',     -- 更新担当者コード
    UPDATE_SECTION_NAME            CHAR OPTIONALLY ENCLOSED BY '"',     -- 更新部署コード
    UPDATE_PROGRAM_ID              CHAR OPTIONALLY ENCLOSED BY '"',     -- 更新プログラムＩＤ
    CREATION_DATE_TIME             DATE "yyyymmddhh24miss",             -- 作成日時時分秒
    UPDATE_DATE_TIME               DATE "yyyymmddhh24miss",             -- 更新日時時分秒
-- Ver1.1 Add Start
    LEASE_TYPE                     CHAR OPTIONALLY ENCLOSED BY '"',     -- リース区分
    DECLARATION_PLACE              CHAR OPTIONALLY ENCLOSED BY '"',     -- 申告地
    GET_PRICE                      INTEGER EXTERNAL,                    -- 取得価格
-- Ver1.1 Add End
    CREATED_BY                     "FND_GLOBAL.USER_ID",                -- 作成者
    CREATION_DATE                  SYSDATE,                             -- 作成日
    LAST_UPDATED_BY                "FND_GLOBAL.USER_ID",                -- 最終更新者
    LAST_UPDATE_DATE               SYSDATE,                             -- 最終更新日
    LAST_UPDATE_LOGIN              "FND_GLOBAL.LOGIN_ID",               -- 最終更新ログイン
    REQUEST_ID                     "FND_GLOBAL.CONC_REQUEST_ID",        -- 要求ID
    PROGRAM_APPLICATION_ID         "FND_GLOBAL.PROG_APPL_ID",           -- コンカレント・プログラム・アプリケーションID
    PROGRAM_ID                     "FND_GLOBAL.CONC_PROGRAM_ID",        -- コンカレント・プログラムID
    PROGRAM_UPDATE_DATE            SYSDATE                              -- プログラム更新日
  )
