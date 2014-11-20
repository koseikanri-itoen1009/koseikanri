-- ************************************************************************************************
-- Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
-- 
-- Control file  : XXCSO015A01D.ctl
-- Description   : 自販機-EBSインタフェース：(IN)作業データ SQL*Loader処理
-- BR.050        : T_BR050_CCO_200_自販_作業データ
-- MD.050        : MD050_CSO_015_A01_自販機-EBSインタフェース：（IN）作業データ
-- MD.070        : なし
-- Version       : 1.4
--
-- Target Table  : XXCSO_IN_WORK_DATA
--
-- Change Record
-- ------------- ------- ---------------- ---------------------------------------------------------
--  Date          Ver.    Editor           Description
-- ------------- ------- ---------------- ---------------------------------------------------------
--  2008/11/28    1.0     kyo              新規作成
--  2009/01/27    1.1     kyo              休止処理済フラグ項目追加
--  2009/03/10    1.1     abe              シーケンス番号の追加
--  2009/05/29    1.2     K.Satomura       システムテスト障害対応(T1_1017,T1_1107)
--  2009/06/04    1.3     K.Satomura       システムテスト障害対応(T1_1107再修正)
--  2009/12/08    1.4     K.Hosoi          E_本稼動_00219対応
-- ************************************************************************************************
--
OPTIONS (SKIP=0, DIRECT=FALSE, ERRORS=99999)
--
LOAD DATA
CHARACTERSET JA16SJIS
INTO TABLE XXCSO_IN_WORK_DATA
APPEND
FIELDS TERMINATED BY "," TRAILING NULLCOLS
  (
    SEQ_NO                         SEQUENCE( MAX ),                         -- シーケンス番号
    SLIP_NO                        INTEGER EXTERNAL,                        -- 伝票No.
    SLIP_BRANCH_NO                 INTEGER EXTERNAL,                        -- 伝票枝番
    LINE_NUMBER                    INTEGER EXTERNAL,                        -- 行番号
    JOB_KBN                        INTEGER EXTERNAL,                        -- 作業区分
    INSTALL_CODE1                  CHAR OPTIONALLY ENCLOSED BY '"' "DECODE(:INSTALL_CODE1, NULL, NULL, 
      SUBSTR(:INSTALL_CODE1, 1, 3) || '-' || SUBSTR(:INSTALL_CODE1, 4))",    -- 物件コード１（設置用）
    INSTALL_CODE2                  CHAR OPTIONALLY ENCLOSED BY '"' "DECODE(:INSTALL_CODE2, NULL, NULL, 
      SUBSTR(:INSTALL_CODE2, 1, 3) || '-' || SUBSTR(:INSTALL_CODE2, 4))",    -- 物件コード２（引揚用）
    WORK_HOPE_DATE                 INTEGER EXTERNAL,                        -- 作業希望日/引取希望日
    WORK_HOPE_TIME_KBN             INTEGER EXTERNAL,                        -- 作業希望時間区分
    WORK_HOPE_TIME                 CHAR OPTIONALLY ENCLOSED BY '"',         -- 作業希望時間
    CURRENT_INSTALL_NAME           CHAR OPTIONALLY ENCLOSED BY '"',         -- 現設置先名
    NEW_INSTALL_NAME               CHAR OPTIONALLY ENCLOSED BY '"',         -- 新設置先名
    WITHDRAWAL_PROCESS_KBN         INTEGER EXTERNAL,                        -- 引揚機処理区分
    ACTUAL_WORK_DATE               INTEGER EXTERNAL,                        -- 実作業日
    ACTUAL_WORK_TIME1              CHAR OPTIONALLY ENCLOSED BY '"',         -- 実作業時間１
    ACTUAL_WORK_TIME2              CHAR OPTIONALLY ENCLOSED BY '"',         -- 実作業時間２
    COMPLETION_KBN                 INTEGER EXTERNAL,                        -- 完了区分
    DELETE_FLAG                    INTEGER EXTERNAL,                        -- 削除フラグ
    COMPLETION_PLAN_DATE           INTEGER EXTERNAL,                        -- 完了予定日/修理完了予定日
    COMPLETION_DATE                INTEGER EXTERNAL,                        -- 完了日/修理完了日
    DISPOSAL_APPROVAL_DATE         INTEGER EXTERNAL,                        -- 廃棄決裁日
    WITHDRAWAL_DATE                INTEGER EXTERNAL,                        -- 実引取日/引取日
    DELIVERY_DATE                  INTEGER EXTERNAL,                        -- 交付日
    LAST_DISPOSAL_END_DATE         INTEGER EXTERNAL,                        -- 最終処分終了年月日
    FWD_ROOT_COMPANY_CODE          CHAR OPTIONALLY ENCLOSED BY '"',         -- （転送元）会社コード
    FWD_ROOT_LOCATION_CODE         CHAR OPTIONALLY ENCLOSED BY '"',         -- （転送元）事業所コード
    FWD_DISTINATION_COMPANY_CODE   CHAR OPTIONALLY ENCLOSED BY '"',         -- （転送先）会社コード
    FWD_DISTINATION_LOCATION_CODE  CHAR OPTIONALLY ENCLOSED BY '"',         -- （転送先）事業所コード
    CREATION_EMPLOYEE_NUMBER       CHAR OPTIONALLY ENCLOSED BY '"',         -- 作成担当者コード
    CREATION_SECTION_NAME          CHAR OPTIONALLY ENCLOSED BY '"',         -- 作成部署コード
    CREATION_PROGRAM_ID            CHAR OPTIONALLY ENCLOSED BY '"',         -- 作成プログラムＩＤ
    UPDATE_EMPLOYEE_NUMBER         CHAR OPTIONALLY ENCLOSED BY '"',         -- 更新担当者コード
    UPDATE_SECTION_NAME            CHAR OPTIONALLY ENCLOSED BY '"',         -- 更新部署コード
    UPDATE_PROGRAM_ID              CHAR OPTIONALLY ENCLOSED BY '"',         -- 更新プログラムＩＤ
    CREATION_DATE_TIME             DATE "yyyymmddhh24miss",                 -- 作成日時時分秒
    UPDATE_DATE_TIME               DATE "yyyymmddhh24miss",                 -- 更新日時時分秒
    PO_NUMBER                      INTEGER EXTERNAL,                        -- 発注番号
    PO_LINE_NUMBER                 INTEGER EXTERNAL,                        -- 発注明細番号
    PO_DISTRIBUTION_NUMBER         INTEGER EXTERNAL,                        -- 発注搬送番号
    PO_REQ_NUMBER                  INTEGER EXTERNAL,                        -- 発注依頼番号
    LINE_NUM                       INTEGER EXTERNAL,                        -- 発注依頼明細番号
    ACCOUNT_NUMBER1                CHAR OPTIONALLY ENCLOSED BY '"',         -- 顧客コード１（新設置先）
    ACCOUNT_NUMBER2                CHAR OPTIONALLY ENCLOSED BY '"',         -- 顧客コード２（現設置先）
    SAFE_SETTING_STANDARD          CHAR OPTIONALLY ENCLOSED BY '"',         -- 安全設置基準
    INSTALL1_PROCESSED_FLAG        CONSTANT 'N',                            -- 物件１処理済フラグ
    INSTALL2_PROCESSED_FLAG        CONSTANT 'N',                            -- 物件２処理済フラグ
    SUSPEND_PROCESSED_FLAG         CONSTANT '0',                            -- 休止処理済フラグ
    -- 2009.06.04 K.Satomura T1_1107再修正対応 START
    -- 2009.05.29 K.Satomura T1_1017,T1_1107対応 START
    --INSTALL1_PROCESSED_DATE        DATE "yyyymmddhh24miss",                 -- 物件１処理済日
    --INSTALL2_PROCESSED_DATE        DATE "yyyymmddhh24miss",                 -- 物件２処理済日
    --VDMS_INTERFACE_FLAG            CHAR OPTIONALLY ENCLOSED BY '"',         -- 自販機S連携フラグ
    --VDMS_INTERFACE_DATE            DATE "yyyymmddhh24miss",                 -- 自販機S連携日
    --PROCESS_NO_TARGET_FLAG         CHAR OPTIONALLY ENCLOSED BY '"',         -- 作業依頼処理対象外フラグ
    -- 2009.05.29 K.Satomura T1_1017,T1_1107対応 END
    INSTALL1_PROCESSED_DATE        CONSTANT "",                           -- 物件１処理済日
    INSTALL2_PROCESSED_DATE        CONSTANT "",                           -- 物件２処理済日
    VDMS_INTERFACE_FLAG            CONSTANT 'N',                          -- 自販機S連携フラグ
    VDMS_INTERFACE_DATE            CONSTANT "",                           -- 自販機S連携日
    INSTALL1_PROCESS_NO_TARGET_FLG CONSTANT 'N',                          -- 物件１作業依頼処理対象外フラグ
    INSTALL2_PROCESS_NO_TARGET_FLG CONSTANT 'N',                          -- 物件２作業依頼処理対象外フラグ
    -- 2009.06.04 K.Satomura T1_1107再修正対応 END
    CREATED_BY                     "FND_GLOBAL.USER_ID",                    -- 作成者
    CREATION_DATE                  SYSDATE,                                 -- 作成日
    LAST_UPDATED_BY                "FND_GLOBAL.USER_ID",                    -- 最終更新者
    LAST_UPDATE_DATE               SYSDATE,                                 -- 最終更新日
    LAST_UPDATE_LOGIN              "FND_GLOBAL.LOGIN_ID",                   -- 最終更新ログイン
    REQUEST_ID                     "FND_GLOBAL.CONC_REQUEST_ID",            -- 要求ID
    PROGRAM_APPLICATION_ID         "FND_GLOBAL.PROG_APPL_ID",     -- コンカレント・プログラム・アプリケーションID
    PROGRAM_ID                     "FND_GLOBAL.CONC_PROGRAM_ID",            -- コンカレント・プログラムID
    PROGRAM_UPDATE_DATE            SYSDATE,                                 -- プログラム更新日
    -- 2009.12.08 K.Hosoi E_本稼動_00219対応 START
    INFOS_INTERFACE_FLAG           CONSTANT 'N',                            -- 情報系連携済フラグ
    INFOS_INTERFACE_DATE           CONSTANT ""                              -- 情報系連携日
    -- 2009.12.08 K.Hosoi E_本稼動_00219対応 END
  )