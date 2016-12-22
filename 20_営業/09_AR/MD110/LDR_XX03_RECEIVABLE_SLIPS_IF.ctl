--********************************************************************
-- 制御ファイル  : LDR_XX034RL001C.ctl
-- 機能概要      : 部門入力（AR）データロード
-- バージョン    : 11.5.10.2.6
-- 作成者        : 野呂祐介
-- 作成日        : 2005-01-12
-- 変更者        : 森澤崇,大草昭人
-- 最終変更日    : 2016-11-29
-- 変更履歴      :
--     2005-01-12 新規作成
--     2005-03-03 LOAD内でのPROFILE取得→SHELLで処理する対応
--     2005-11-29 INTEGER型をINTEGER EXTERNAL型に変更
--     2006-09-05 REQUEST_IDをSHELLの文字変換で処理し、ORG_IDを後続の
--                プログラムでUPDATEで処理する対応に変更
--     2016-11-29 障害対応E_本稼動_13901
--
-- Copyright (c) 2004-2005 Oracle Corporation Japan All Rights Reserved
-- 当プログラム使用に際して一切の保証は行わない
-- 文書による事前承認のない第三者への開示不可
--********************************************************************
OPTIONS (SKIP=1, DIRECT=FALSE, ERRORS=99999)
LOAD DATA
CHARACTERSET JA16SJIS
APPEND
INTO TABLE XX03_RECEIVABLE_SLIPS_IF
FIELDS TERMINATED BY "," OPTIONALLY ENCLOSED BY '"' TRAILING NULLCOLS
       (
    SOURCE                     CHAR          "'EXCEL'"                            -- ソース
  , WF_STATUS                  CHAR          "'00'"                               -- ステータス
  , ENTRY_DATE                 CHAR          "SYSDATE"                            -- 起票日
  , ENTRY_PERSON_NUMBER        CHAR          "'-1'"                               -- 申請者
  , REQUESTOR_PERSON_NUMBER    CHAR          "'-1'"                               -- 伝票入力者
-- ver 1.1 Change Start
--  , ORG_ID                     INTEGER       "XX00_PROFILE_PKG.VALUE('ORG_ID')"   -- オルグID
-- ver 11.5.10.1.6 Change Start
--  , ORG_ID                     INTEGER       "CHG_ORG_ID"   -- オルグID
-- ver 1.1 Change End
--  , CREATED_BY                 INTEGER       "'-1'"
--  , CREATION_DATE              CHAR          "SYSDATE"
--  , LAST_UPDATED_BY            INTEGER       "'-1'"
--  , LAST_UPDATE_DATE           CHAR          "SYSDATE"
--  , LAST_UPDATE_LOGIN          INTEGER       "'-1'"
--  , REQUEST_ID                 INTEGER       "'-1'"
--  , PROGRAM_APPLICATION_ID     INTEGER       "'-1'"
--  , PROGRAM_ID                 INTEGER       "'-1'"
-- ver 11.5.10.2.5 Chg Start
--  , ORG_ID                     INTEGER EXTERNAL       "CHG_ORG_ID"   -- オルグID
  , ORG_ID                     INTEGER EXTERNAL       "'-1'"   -- オルグID
-- ver 11.5.10.2.5 Chg End
  , CREATED_BY                 INTEGER EXTERNAL       "'-1'"
  , CREATION_DATE              CHAR          "SYSDATE"
  , LAST_UPDATED_BY            INTEGER EXTERNAL       "'-1'"
  , LAST_UPDATE_DATE           CHAR          "SYSDATE"
  , LAST_UPDATE_LOGIN          INTEGER EXTERNAL       "'-1'"
-- ver 11.5.10.2.5 Chg Start
--  , REQUEST_ID                 INTEGER EXTERNAL       "'-1'"
  , REQUEST_ID                 INTEGER EXTERNAL       "CHG_REQUEST_ID"
-- ver 11.5.10.2.5 Chg End
  , PROGRAM_APPLICATION_ID     INTEGER EXTERNAL       "'-1'"
  , PROGRAM_ID                 INTEGER EXTERNAL       "'-1'"
-- ver 11.5.10.1.6 Change End
  , PROGRAM_UPDATE_DATE        CHAR          "SYSDATE"
  , INTERFACE_ID               POSITION(1)   INTEGER EXTERNAL                     -- インターフェイスID
  , SLIP_TYPE_NAME             CHAR          TERMINATED BY ","                    -- 伝票種別
  , APPROVER_PERSON_NUMBER     CHAR          TERMINATED BY ","                    -- 承認者

-- ver 1.1 Change Start
--  , TRANS_TYPE_ID              CHAR          TERMINATED BY ","                    -- 取引タイプID
--  , CUSTOMER_ID                CHAR          TERMINATED BY ","                    -- 顧客ID
--  , CUSTOMER_OFFICE_ID         CHAR          TERMINATED BY ","                    -- 顧客事業所ID
  , TRANS_TYPE_NAME            CHAR          TERMINATED BY ","                    -- 取引タイプ
  , CUSTOMER_NUMBER            CHAR          TERMINATED BY ","                    -- 顧客
  , LOCATION                   CHAR          TERMINATED BY ","                    -- 顧客事業所
-- ver 1.1 Change End

  , INVOICE_DATE               DATE          "yyyy/mm/dd" TERMINATED BY ","       -- 請求書日付
  , GL_DATE                    DATE          "yyyy/mm/dd" TERMINATED BY ","       -- 計上日
  , RECEIPT_METHOD_NAME        CHAR          TERMINATED BY ","                    -- 支払方法
  , TERMS_NAME                 CHAR          TERMINATED BY ","                    -- 支払条件
  , CURRENCY_CODE              CHAR          TERMINATED BY ","                    -- 通貨コード
  , CONVERSION_RATE            CHAR          TERMINATED BY "," OPTIONALLY ENCLOSED BY '"' "TO_NUMBER(:CONVERSION_RATE, '999,999,999,999,999.000')"  -- レート
  , CONVERSION_TYPE            CHAR          TERMINATED BY ","                    -- レートタイプ
  , COMMITMENT_NUMBER          CHAR          TERMINATED BY ","                    -- 前受金充当伝票番号
  , DESCRIPTION                CHAR          TERMINATED BY ","                    -- 備考
  , ONETIME_CUSTOMER_NAME      CHAR          TERMINATED BY ","                    -- 一見顧客名称
  , ONETIME_CUSTOMER_KANA_NAME CHAR          TERMINATED BY ","                    -- カナ名
  , ONETIME_CUSTOMER_ADDRESS_1 CHAR          TERMINATED BY ","                    -- 住所１
  , ONETIME_CUSTOMER_ADDRESS_2 CHAR          TERMINATED BY ","                    -- 住所２
  , ONETIME_CUSTOMER_ADDRESS_3 CHAR          TERMINATED BY ","                    -- 住所３
       )

INTO TABLE XX03_RECEIVABLE_SLIPS_LINE_IF
FIELDS TERMINATED BY "," OPTIONALLY ENCLOSED BY '"' TRAILING NULLCOLS
       (
    LINE_NUMBER                CHAR          TERMINATED BY ","                    -- No（明細番号）
  , SLIP_LINE_TYPE_NAME        CHAR          TERMINATED BY ","                    -- 請求内容
  , SLIP_LINE_UOM              CHAR          TERMINATED BY ","                    -- 単位
  , SLIP_LINE_QUANTITY         CHAR          TERMINATED BY "," OPTIONALLY ENCLOSED BY '"' "TO_NUMBER(:SLIP_LINE_QUANTITY, '999,999,999,999,999.000')"   -- 数量
  , SLIP_LINE_UNIT_PRICE       CHAR          TERMINATED BY "," OPTIONALLY ENCLOSED BY '"' "TO_NUMBER(:SLIP_LINE_UNIT_PRICE, '999,999,999,999,999.000')"   -- 単価
  , ENTERED_TAX_AMOUNT         CHAR          TERMINATED BY "," OPTIONALLY ENCLOSED BY '"' "TO_NUMBER(:ENTERED_TAX_AMOUNT, '999,999,999,999,999.000')"   -- 税金金額
  , SLIP_LINE_TAX_FLAG         CHAR          TERMINATED BY ","                    -- 内税
  , SLIP_LINE_TAX_CODE         CHAR          TERMINATED BY ","                    -- 税区分
  , SLIP_LINE_RECIEPT_NO       CHAR          TERMINATED BY ","                    -- 納品書番号
  , SLIP_DESCRIPTION           CHAR          TERMINATED BY ","                    -- 備考（明細）
  , SEGMENT1                   CHAR          TERMINATED BY ","                    -- 会社コード
  , SEGMENT2                   CHAR          TERMINATED BY ","                    -- 部門コード
  , SEGMENT3                   CHAR          TERMINATED BY ","                    -- 勘定科目
  , SEGMENT4                   CHAR          TERMINATED BY ","                    -- 補助科目
  , SEGMENT5                   CHAR          TERMINATED BY ","                    -- 相手先
  , SEGMENT6                   CHAR          TERMINATED BY ","                    -- 事業区分
  , SEGMENT7                   CHAR          TERMINATED BY ","                    -- プロジェクト
  , SEGMENT8                   CHAR          TERMINATED BY ","                    -- 予備１
  , JOURNAL_DESCRIPTION        CHAR          TERMINATED BY ","                    -- 備考（仕訳）
  , INCR_DECR_REASON_CODE      CHAR          TERMINATED BY ","                    -- 増減事由
  , RECON_REFERENCE            CHAR          TERMINATED BY ","                    -- 消込参照
-- ver 2016-11-29 Change Start
  , ATTRIBUTE7                 CHAR          TERMINATED BY ","                    -- 稟議決裁番号
-- ver 2016-11-29 Change End
-- ver 1.1 Change Start
--  , ORG_ID                     INTEGER       "XX00_PROFILE_PKG.VALUE('ORG_ID')"   -- オルグID
-- ver 11.5.10.1.6 Change Start
--  , ORG_ID                     INTEGER       "CHG_ORG_ID"   -- オルグID
-- ver 1.1 Change End
--  , SOURCE                     CHAR          "'EXCEL'"
--  , CREATED_BY                 INTEGER       "'-1'"
--  , CREATION_DATE              CHAR          "SYSDATE"
--  , LAST_UPDATED_BY            INTEGER       "'-1'"
--  , LAST_UPDATE_DATE           CHAR          "SYSDATE"
--  , LAST_UPDATE_LOGIN          INTEGER       "'-1'"
--  , REQUEST_ID                 INTEGER       "'-1'"
--  , PROGRAM_APPLICATION_ID     INTEGER       "'-1'"
--  , PROGRAM_ID                 INTEGER       "'-1'"
-- ver 11.5.10.2.5 Chg Start
--  , ORG_ID                     INTEGER EXTERNAL       "CHG_ORG_ID"   -- オルグID
  , ORG_ID                     INTEGER EXTERNAL       "'-1'"   -- オルグID
-- ver 11.5.10.2.5 Chg End
  , SOURCE                     CHAR          "'EXCEL'"
  , CREATED_BY                 INTEGER EXTERNAL       "'-1'"
  , CREATION_DATE              CHAR          "SYSDATE"
  , LAST_UPDATED_BY            INTEGER EXTERNAL       "'-1'"
  , LAST_UPDATE_DATE           CHAR          "SYSDATE"
  , LAST_UPDATE_LOGIN          INTEGER EXTERNAL       "'-1'"
-- ver 11.5.10.2.5 Chg Start
--  , REQUEST_ID                 INTEGER EXTERNAL       "'-1'"
  , REQUEST_ID                 INTEGER EXTERNAL       "CHG_REQUEST_ID"
-- ver 11.5.10.2.5 Chg End
  , PROGRAM_APPLICATION_ID     INTEGER EXTERNAL       "'-1'"
  , PROGRAM_ID                 INTEGER EXTERNAL       "'-1'"
-- ver 11.5.10.1.6 Change End
  , PROGRAM_UPDATE_DATE        CHAR          "SYSDATE"
  , INTERFACE_ID               POSITION(1)   INTEGER EXTERNAL                     -- インターフェイスID
  , RECEIVABLE_LINE_ID         SEQUENCE(MAX, 1)
       )
