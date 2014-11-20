create or replace PACKAGE XXCFO_COMMON_PKG2
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : xxcfo_common_pkg2(spec)
 * Description      : 共通関数（会計）
 * MD.070           : MD070_IPO_CFO_001_共通関数定義書
 * Version          : 1.00
 *
 * Program List
 *  --------------------      ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  --------------------      ---- ----- --------------------------------------------------
 *  chk_electric_book_item    P           電子帳簿項目チェック関数
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012-08-31   1.00   SCSK T.Osawa     新規作成
 *
 *****************************************************************************************/
--
  --電子帳簿項目チェック関数
  PROCEDURE chk_electric_book_item(
      iv_item_name    IN  VARCHAR2 -- 項目名称
    , iv_item_value   IN  VARCHAR2 -- 項目の値
    , in_item_len     IN  NUMBER   -- 項目の長さ
    , in_item_decimal IN  NUMBER   -- 項目の長さ(小数点以下)
    , iv_item_nullflg IN  VARCHAR2 -- 必須フラグ
    , iv_item_attr    IN  VARCHAR2 -- 項目属性
    , iv_item_cutflg  IN  VARCHAR2 -- 切捨てフラグ
    , ov_item_value   OUT VARCHAR2 -- 項目の値
    , ov_errbuf       OUT VARCHAR2 -- エラーメッセージ
    , ov_retcode      OUT VARCHAR2 -- リターンコード
    , ov_errmsg       OUT VARCHAR2 -- ユーザー・エラーメッセージ
  );
END XXCFO_COMMON_PKG2;
/
