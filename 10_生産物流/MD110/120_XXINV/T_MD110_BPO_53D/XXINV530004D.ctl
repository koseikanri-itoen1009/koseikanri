-- ************************************************************************************************
-- Copyright(c)Oracle Corporation Japan, 2006-2008. All rights reserved.
-- 
-- Control file  : XXINV530004D.ctl
-- Description   : HHT棚卸データ SQL*Loader処理
-- MD.050        : T_MD050_BPO_530_棚卸
-- MD.070        : なし
-- Version       : 1.0
--
-- Target Table  : XXINV_STC_INVENTORY_HHT_WORK
--
-- Change Record
-- ------------- ------- ---------------- ---------------------------------------------------------
--  Date          Ver.    Editor           Description
-- ------------- ------- ---------------- ---------------------------------------------------------
--  2008/03/25    1.0     T.Endou      	   新規作成
--
-- ************************************************************************************************

OPTIONS (SKIP=0, DIRECT=FALSE, ERRORS=99999)

LOAD DATA
CHARACTERSET JA16SJIS
APPEND
INTO TABLE XXINV_STC_INVENTORY_HHT_WORK
FIELDS TERMINATED BY "," OPTIONALLY ENCLOSED BY '"' TRAILING NULLCOLS
  (
    COMPANY_NAME            CHAR,                          -- 会社名
    DATA_KBN                CHAR,                          -- データ種別
    TRANS_NUMBER            CHAR,                          -- 伝送用枝番
    REPORT_POST_CODE        CHAR,                            -- 003 報告部署
    INVENT_DATE             DATE "yyyy/mm/dd hh24:mi:ss",    -- 011 棚卸日
    INVENT_WHSE_CODE        CHAR,                            -- 002 棚卸倉庫
    INVENT_SEQ              CHAR,                            -- 001 棚卸連番
    ITEM_CODE               CHAR,                            -- 004 品目
    LOT_NO                  CHAR,                            -- 005 ロットNo
    MAKER_DATE              CHAR,                            -- 006 製造日
    LIMIT_DATE              CHAR,                            -- 007 賞味期限
    PROPER_MARK             CHAR,                            -- 008 固有記号
    CASE_AMT                INTEGER EXTERNAL,                -- 009 棚卸ケース数
    CONTENT                 INTEGER EXTERNAL,                -- 012 入数
    LOOSE_AMT               INTEGER EXTERNAL,                -- 010 棚卸バラ
    LOCATION                CHAR,                            -- 013 ロケーション
    RACK_NO1                CHAR,                            -- 014 ラックNo１
    RACK_NO2                CHAR,                            -- 015 ラックNo２
    RACK_NO3                CHAR,                            -- 016 ラックNo３
    HHT_UPDATE_DAY          DATE "yyyy/mm/dd hh24:mi:ss",    -- 更新日時
    INVENT_HHT_IF_ID        "xxinv_stc_invt_hht_s1.nextval", -- *** HHT棚卸IF_ID
    CREATED_BY              CONSTANT "-1",                   -- *** 作成者
    CREATION_DATE           SYSDATE,                         -- *** 作成日
    LAST_UPDATED_BY         CONSTANT "-1",                   -- *** 最終更新者
    LAST_UPDATE_DATE        SYSDATE,                         -- *** 最終更新日
    LAST_UPDATE_LOGIN       CONSTANT "-1",                   -- *** 最終更新ログイン
    REQUEST_ID              CONSTANT "-1",                   -- *** 要求ID
    PROGRAM_APPLICATION_ID  CONSTANT "-1",                   -- *** ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
    PROGRAM_ID              CONSTANT "-1",                   -- *** ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
    PROGRAM_UPDATE_DATE     SYSDATE                          -- *** ﾌﾟﾛｸﾞﾗﾑ更新日
  )
