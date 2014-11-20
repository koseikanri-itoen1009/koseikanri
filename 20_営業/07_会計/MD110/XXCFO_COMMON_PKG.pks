create or replace PACKAGE XXCFO_COMMON_PKG
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcfo_common_pkg(spec)
 * Description      : 共通関数（会計）
 * MD.050           : なし
 * Version          : 1.00
 *
 * Program List
 *  --------------------      ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  --------------------      ---- ----- --------------------------------------------------
 *  get_special_info_item     F    VAR    添付情報項目値検索取得
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-12-05   1.00   SCS 山口優       新規作成
 *  2008-03-25   1.01   SCS Kayahara      最終行にスラッシュ追加
 *
 *****************************************************************************************/
--
  --添付情報項目値検索取得
  FUNCTION get_special_info_item(
    il_long_text              IN          LONG,           -- 長い文書
    iv_serach_char            IN          VARCHAR2        -- 検索文字列
  )
  RETURN VARCHAR2;
END XXCFO_COMMON_PKG;
/