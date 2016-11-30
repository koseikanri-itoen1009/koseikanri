--********************************************************************
-- 制御ファイル  : LDR_XX034DL002C.ctl
-- 機能概要      : 部門入力（GL）データロード
-- MD.050        : 部門入力バッチ処理(GL)     OCSJ/BFAFIN/MD050/F602
-- MD.070        : 部門入力（GL）データロード OCSJ/BFAFIN/MD070/F602/02
-- バージョン    : 11.5.10.2.6
-- 作成者        : OCSJ BFA-Fin
-- 作成日        : 2004-11-12
-- 変更者        : SCSK渡邊
-- 最終変更日    : 2016-11-11
-- 変更履歴      :
--     2004-11-12 新規作成
--     2005-03-03 LOAD内でのPROFILE取得→SHELLで処理する対応
--     2005-12-02 INTEGER型をINTEGER EXTERNAL型に変更
--     2006-09-05 REQUEST_IDをSHELLの文字変換で処理し、ORG_ID,SET_OF_BKS_IDを
--                後続のプログラムでUPDATEで処理する対応に変更
--     2016-11-01 障害対応E_本稼動_13901
--
-- Copyright (c) 2005 Oracle Corporation Japan All Rights Reserved
-- 当プログラム使用に際して一切の保証は行わない
-- 文書による事前承認のない第三者への開示不可
--********************************************************************
OPTIONS (SKIP=1, DIRECT=FALSE, ERRORS=99999)
LOAD DATA
CHARACTERSET JA16SJIS
APPEND
INTO TABLE XX03_JOURNAL_SLIPS_IF
FIELDS TERMINATED BY "," OPTIONALLY ENCLOSED BY '"' TRAILING NULLCOLS
       (
  SOURCE                    CHAR          "'EXCEL'",
  WF_STATUS                 CHAR          "'00'",
  IGNORE_RATE_FLAG          CHAR          "'N'",
  ENTRY_DATE                CHAR          "SYSDATE",
  ENTRY_PERSON_NUMBER       CHAR          "'-1'",
  REQUESTOR_PERSON_NUMBER   CHAR          "'-1'",
-- ver 1.1 Change Start
--  ORG_ID                    INTEGER       "XX00_PROFILE_PKG.VALUE('ORG_ID')",
--  SET_OF_BOOKS_ID           INTEGER       "XX00_PROFILE_PKG.VALUE('GL_SET_OF_BKS_ID')",
-- ver 11.5.10.1.6 Change Start
--  ORG_ID                    INTEGER       "CHG_ORG_ID",
--  SET_OF_BOOKS_ID           INTEGER       "CHG_SET_OF_BKS_ID",
-- ver 1.1 Change End
--  CREATED_BY                INTEGER       "'-1'",
--  CREATION_DATE             CHAR          "SYSDATE",
--  LAST_UPDATED_BY           INTEGER       "'-1'",
--  LAST_UPDATE_DATE          CHAR          "SYSDATE",
--  LAST_UPDATE_LOGIN         INTEGER       "'-1'",
--  REQUEST_ID                INTEGER       "'-1'",
--  PROGRAM_APPLICATION_ID    INTEGER       "'-1'",
--  PROGRAM_ID                INTEGER       "'-1'",
-- ver 11.5.10.2.5 Chg Start
--  ORG_ID                    INTEGER EXTERNAL       "CHG_ORG_ID",
--  SET_OF_BOOKS_ID           INTEGER EXTERNAL       "CHG_SET_OF_BKS_ID",
  ORG_ID                    INTEGER EXTERNAL       "'-1'",
  SET_OF_BOOKS_ID           INTEGER EXTERNAL       "'-1'",
-- ver 11.5.10.2.5 Chg End
  CREATED_BY                INTEGER EXTERNAL       "'-1'",
  CREATION_DATE             CHAR          "SYSDATE",
  LAST_UPDATED_BY           INTEGER EXTERNAL       "'-1'",
  LAST_UPDATE_DATE          CHAR          "SYSDATE",
  LAST_UPDATE_LOGIN         INTEGER EXTERNAL       "'-1'",
-- ver 11.5.10.2.5 Chg Start
--  REQUEST_ID                INTEGER EXTERNAL       "'-1'",
  REQUEST_ID                INTEGER EXTERNAL       "CHG_REQUEST_ID",
-- ver 11.5.10.2.5 Chg End
  PROGRAM_APPLICATION_ID    INTEGER EXTERNAL       "'-1'",
  PROGRAM_ID                INTEGER EXTERNAL       "'-1'",
-- ver 11.5.10.1.6 Change End
  PROGRAM_UPDATE_DATE       CHAR          "SYSDATE",
  INTERFACE_ID              POSITION(1)   INTEGER EXTERNAL,
  SLIP_TYPE_NAME            CHAR          TERMINATED BY ",",
  APPROVER_PERSON_NUMBER    CHAR          TERMINATED BY ",",
  PERIOD_NAME               CHAR          TERMINATED BY ",",
  GL_DATE                   DATE          "yyyy/mm/dd" TERMINATED BY ",",
  DESCRIPTION               CHAR          TERMINATED BY ",",
  INVOICE_CURRENCY_CODE     CHAR          TERMINATED BY ",",
  EXCHANGE_RATE_TYPE_NAME   CHAR          TERMINATED BY ",",
  EXCHANGE_RATE             CHAR          TERMINATED BY "," OPTIONALLY ENCLOSED BY '"' "TO_NUMBER(:EXCHANGE_RATE, '999,999,999,999,999.000')"
       )

INTO TABLE XX03_JOURNAL_SLIP_LINES_IF
FIELDS TERMINATED BY "," OPTIONALLY ENCLOSED BY '"' TRAILING NULLCOLS
       (
  ENTERED_ITEM_AMOUNT_DR       CHAR          TERMINATED BY "," OPTIONALLY ENCLOSED BY '"' "TO_NUMBER(:ENTERED_ITEM_AMOUNT_DR, '999,999,999,999,999.000')",
  TAX_CODE_DR                  CHAR          TERMINATED BY ",",
  AMOUNT_INCLUDES_TAX_FLAG_DR  CHAR          TERMINATED BY ",",
  ENTERED_TAX_AMOUNT_DR        CHAR          TERMINATED BY "," OPTIONALLY ENCLOSED BY '"' "TO_NUMBER(:ENTERED_TAX_AMOUNT_DR, '999,999,999,999,999.000')",
  ACCOUNTED_AMOUNT_DR          CHAR          TERMINATED BY "," OPTIONALLY ENCLOSED BY '"' "TO_NUMBER(:ACCOUNTED_AMOUNT_DR, '999,999,999,999,999.000')",
  ENTERED_ITEM_AMOUNT_CR       CHAR          TERMINATED BY "," OPTIONALLY ENCLOSED BY '"' "TO_NUMBER(:ENTERED_ITEM_AMOUNT_CR, '999,999,999,999,999.000')",
  TAX_CODE_CR                  CHAR          TERMINATED BY ",",
  AMOUNT_INCLUDES_TAX_FLAG_CR  CHAR          TERMINATED BY ",",
  ENTERED_TAX_AMOUNT_CR        CHAR          TERMINATED BY "," OPTIONALLY ENCLOSED BY '"' "TO_NUMBER(:ENTERED_TAX_AMOUNT_CR, '999,999,999,999,999.000')",
  ACCOUNTED_AMOUNT_CR          CHAR          TERMINATED BY "," OPTIONALLY ENCLOSED BY '"' "TO_NUMBER(:ACCOUNTED_AMOUNT_CR, '999,999,999,999,999.000')",
  DESCRIPTION                  CHAR          TERMINATED BY ",",
  SEGMENT1                     CHAR          TERMINATED BY ",",
  SEGMENT2                     CHAR          TERMINATED BY ",",
  SEGMENT3                     CHAR          TERMINATED BY ",",
  SEGMENT4                     CHAR          TERMINATED BY ",",
  SEGMENT5                     CHAR          TERMINATED BY ",",
  SEGMENT6                     CHAR          TERMINATED BY ",",
  SEGMENT7                     CHAR          TERMINATED BY ",",
  SEGMENT8                     CHAR          TERMINATED BY ",",
  INCR_DECR_REASON_CODE        CHAR          TERMINATED BY ",",
  RECON_REFERENCE              CHAR          TERMINATED BY ",",
-- ver 2016-11-11 Change Start
  ATTRIBUTE9                   CHAR          TERMINATED BY ",",
-- ver 2016-11-11 Change End
  SOURCE                       CHAR          "'EXCEL'",
-- ver 1.1 Change Start
--  ORG_ID                       INTEGER       "XX00_PROFILE_PKG.VALUE('ORG_ID')",
-- ver 11.5.10.1.6 Change Start
--  ORG_ID                       INTEGER       "CHG_ORG_ID",
-- ver 1.1 Change End
--  CREATED_BY                   INTEGER       "'-1'",
--  CREATION_DATE                CHAR          "SYSDATE",
--  LAST_UPDATED_BY              INTEGER       "'-1'",
--  LAST_UPDATE_DATE             CHAR          "SYSDATE",
--  LAST_UPDATE_LOGIN            INTEGER       "'-1'",
--  REQUEST_ID                   INTEGER       "'-1'",
--  PROGRAM_APPLICATION_ID       INTEGER       "'-1'",
--  PROGRAM_ID                   INTEGER       "'-1'",
-- ver 11.5.10.2.5 Chg Start
--  ORG_ID                       INTEGER EXTERNAL       "CHG_ORG_ID",
  ORG_ID                       INTEGER EXTERNAL       "'-1'",
-- ver 11.5.10.2.5 Chg End
  CREATED_BY                   INTEGER EXTERNAL       "'-1'",
  CREATION_DATE                CHAR          "SYSDATE",
  LAST_UPDATED_BY              INTEGER EXTERNAL       "'-1'",
  LAST_UPDATE_DATE             CHAR          "SYSDATE",
  LAST_UPDATE_LOGIN            INTEGER EXTERNAL       "'-1'",
-- ver 11.5.10.2.5 Chg Start
--  REQUEST_ID                   INTEGER EXTERNAL       "'-1'",
  REQUEST_ID                   INTEGER EXTERNAL       "CHG_REQUEST_ID",
-- ver 11.5.10.2.5 Chg End
  PROGRAM_APPLICATION_ID       INTEGER EXTERNAL       "'-1'",
  PROGRAM_ID                   INTEGER EXTERNAL       "'-1'",
-- ver 11.5.10.1.6 Change End
  PROGRAM_UPDATE_DATE          CHAR          "SYSDATE",
  LINE_NUMBER                  SEQUENCE(MAX, 1),
  INTERFACE_ID                 POSITION(1)   INTEGER EXTERNAL
       )
