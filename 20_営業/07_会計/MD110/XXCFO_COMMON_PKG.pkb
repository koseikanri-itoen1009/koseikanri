CREATE OR REPLACE PACKAGE BODY XXCFO_COMMON_PKG
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFO_COMMON_PKG(body)
 * Description      : 共通関数（会計）
 * MD.050           : なし
 * Version          : 1.00
 *
 * Program List
 * --------------------      ---- ----- --------------------------------------------------
 *  Name                     Type  Ret   Description
 * --------------------      ---- ----- --------------------------------------------------
 *  get_special_info_item     F    VAR    添付情報項目値検索取得
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-12-05   1.00   SCS 山口優        新規作成
 *  2008-03-25   1.01   SCS Kayahara      最終行にスラッシュ追加
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
--
  /**********************************************************************************
   * Function Name    : get_special_info_item
   * Description      : 添付情報項目値検索取得
   ***********************************************************************************/
  FUNCTION get_special_info_item(
     il_long_text              IN          LONG         -- 長い文書
    ,iv_serach_char            IN          VARCHAR2     -- 検索文字列
                                )
  RETURN VARCHAR2
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'XXCFO_COMMON_PKG.get_special_info_item'; -- プログラム名
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    ln_long_text_len             NUMBER := 0;            -- 長い文書の長さ
    ln_start_serach_char         NUMBER := 0;            -- 検索対象文字列開始位置
    ln_remainder_cnt             NUMBER := 0;            -- 残文字数
    ln_chr10                     NUMBER := 0;            -- 残文字列の改行コード位置
    ln_serach_char_len           NUMBER := 0;            -- 検索対象文字列の長さ
    ln_remainder_char_len        NUMBER := 0;            -- 残文字列の長さ
    ln_set_value_len             NUMBER := 0;            -- 設定値の長さ
    lv_remainder_char            LONG;                   -- 残文字列
    lv_special_info_item         VARCHAR2(5000) := NULL; -- 特別情報項目
--
  BEGIN
--
    -- 長い文書の長さの取得
    ln_long_text_len   := LENGTHB(il_long_text);
--
    -- 検索対象文字列開始位置
    ln_start_serach_char := INSTRB(il_long_text,iv_serach_char);
--
    IF (  ln_start_serach_char != 0
      AND ln_start_serach_char IS NOT NULL)
    THEN
      -- 残文字数の取得
      ln_remainder_cnt  := ln_long_text_len - ln_start_serach_char + 1;
--
      -- 検索対象文字列の長さの取得
      ln_serach_char_len := LENGTHB(iv_serach_char);
--
      -- 残文字列の取得
      lv_remainder_char := SUBSTRB(il_long_text, ln_start_serach_char, ln_remainder_cnt);
--
      -- 残文字列の改行コード位置の取得
      ln_chr10 := INSTRB(lv_remainder_char,CHR(10));
--
      IF (ln_chr10 = 0) THEN
        -- 残文字列の長さの取得
        ln_remainder_char_len := LENGTHB(lv_remainder_char);
--
        -- 設定値の長さの取得
        ln_set_value_len := ln_remainder_char_len - ln_serach_char_len;
--
        -- 特別情報項目の取得
        lv_special_info_item := SUBSTRB(lv_remainder_char, ln_serach_char_len + 1, ln_set_value_len);
--
      ELSE
        -- 特別情報項目の取得
        lv_special_info_item := SUBSTRB(lv_remainder_char, ln_serach_char_len + 1, ln_chr10 - ln_serach_char_len - 1);
--
      END IF;
--
    END IF;
--
    RETURN lv_special_info_item;
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
      RETURN NULL;
  END get_special_info_item;
--
END XXCFO_COMMON_PKG;
/