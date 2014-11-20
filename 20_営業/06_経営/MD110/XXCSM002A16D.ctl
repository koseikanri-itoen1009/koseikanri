-- ************************************************************************************************
-- Copyright(c)Sumisho Corporation Japan, 2010. All rights reserved.
-- 
-- Control file  : XXCSM002A16D.ctl
-- Description   : 情報系-EBSインターフェース：(IN)商品計画販売実績集計（SQL-LOADER-販売実績集計）
-- MD.050        : MD050_CSM_002_A01_商品計画用過年度販売実績集計.doc
-- MD.070        : なし
-- Version       : 1.0
--
-- Target Table  : XXCSM_WK_ITEM_PLAN_RESULT
--
-- Change Record
-- ------------- ------- ---------------- ---------------------------------------------------------
--  Date          Ver.    Editor           Description
-- ------------- ------- ---------------- ---------------------------------------------------------
--  2010/02/03    1.0     T.Tsukino        新規作成
--
-- ************************************************************************************************
--
OPTIONS (SKIP=0, DIRECT=FALSE, ERRORS=99999)
--
LOAD DATA
INFILE * -- *sql*loaderを実行したディレクトリからの相対パスでディレクトリを指定可能。
REPLACE
INTO TABLE XXCSM_WK_ITEM_PLAN_RESULT
FIELDS TERMINATED BY ","
  (
   SUBJECT_YEAR               INTEGER  EXTERNAL(4),              -- 対象年度
   MONTH_NO                   INTEGER  EXTERNAL(2),              -- 月
   YEAR_MONTH                 INTEGER  EXTERNAL(6),              -- 年月
   LOCATION_CD                CHAR(4),                           -- 拠点コード
   ITEM_NO                    CHAR(32),                          -- 商品コード
   ITEM_GROUP_NO              CHAR(4),                           -- 商品群コード
   AMOUNT                     INTEGER  EXTERNAL(17),             -- 数量
   SALES_BUDGET               INTEGER  EXTERNAL(15),             -- 売上金額
   AMOUNT_GROSS_MARGIN        INTEGER  EXTERNAL(15),             -- 粗利益
   DISCRETE_COST              INTEGER  EXTERNAL(1),              -- 営業原価
   CREATED_BY                 CONSTANT "-1",                     -- 作成者
   CREATION_DATE              SYSDATE,                           -- 作成日
   LAST_UPDATED_BY            CONSTANT "-1",                     -- 最終更新者
   LAST_UPDATE_DATE           SYSDATE,                           -- 最終更新日
   LAST_UPDATE_LOGIN          CONSTANT "-1"                      -- 最終更新ログイン
  )