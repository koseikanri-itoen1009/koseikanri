CREATE OR REPLACE PACKAGE BODY apps.xxccp_oiccommon_pkg
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2022. All rights reserved.
 *
 * Package Name           : xxccp_oiccommon_pkg(body)
 * Description            : 
 * MD.070                 : MD070_IPO_CCP_共通関数
 * Version                : 1.2
 *
 * Program List
 *  --------------------      ---- -----   --------------------------------------------------
 *   Name                     Type  Ret     Description
 *  --------------------      ---- -----   --------------------------------------------------
 *  to_csv_string             F     VAR     CSVファイル用文字列変換
 *  trim_space_tab            F     VAR     文字列の前後半角スペース/タブ削除
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2022-11-07    1.0  Ryo.Kikuchi      新規作成
 *  2023-02-07    1.1  Y.Ooyama         移行障害No.11対応
 *  2023-02-21    1.2  F.Hasebe         移行障害No.29対応
 *****************************************************************************************/
--
  -- ===============================
  -- グローバル定数
  -- ===============================
  cv_pkg_name CONSTANT VARCHAR2(50) := 'XXCCP_OICCOMMON_PKG';
  cv_period   CONSTANT VARCHAR2(1)  := '.';
  cv_msg_part CONSTANT VARCHAR2(3)  := ' : ';
--
  /**********************************************************************************
   * Function Name    : to_csv_string
   * Description      : CSVファイル用文字列変換
   ***********************************************************************************/
  FUNCTION to_csv_string(
              iv_string       IN VARCHAR2                   -- 対象文字列
             ,iv_lf_replace   IN VARCHAR2 DEFAULT NULL      -- LF置換単語
           )
    RETURN VARCHAR2
  IS
  --
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'to_csv_string';
    lv_changed_string   VARCHAR2(3000);           -- 変換後文字列(戻り値)
  --
  BEGIN
    -- 変換後文字列を初期化
    lv_changed_string := iv_string;
--
    -- すべてのLF改行コード「CHR(10)」をINパラメータ「LF置換単語」に置換
    lv_changed_string := REPLACE( lv_changed_string , CHR(10) , iv_lf_replace );
--
-- Ver 1.2 Add Start
    -- すべてのCR改行コード「CHAR(13)」をINパラメータ「LF置換単語」に置換
    lv_changed_string := REPLACE( lv_changed_string , CHR(13) , iv_lf_replace );
--
-- Ver 1.2 Add End
    -- すべてのダブルクォート「"」を連続値「""」に置換
    lv_changed_string := REPLACE( lv_changed_string , '"' , '""' );
--
    -- 先頭と末尾にダブルクォート「"」を追加した値を戻す
    RETURN ('"' || lv_changed_string || '"');
    --
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name||cv_period||cv_prg_name||cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END to_csv_string;
--
--
-- Ver1.1 Add Start
  /**********************************************************************************
   * Function Name    : trim_space_tab
   * Description      : 文字列の前後半角スペース/タブ削除
   ***********************************************************************************/
  FUNCTION trim_space_tab(
              iv_string       IN VARCHAR2                   -- 対象文字列
           )
    RETURN VARCHAR2
  IS
  --
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'trim_space_tab';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_changed_string   VARCHAR2(3000);           -- 変換後文字列(戻り値)
    ln_length           NUMBER;
  --
  BEGIN
    -- NULLの場合はNULLを返却
    IF (iv_string IS NULL) THEN
      RETURN NULL;
    END IF;
    --
    -- 変換後文字列を初期化
    lv_changed_string := iv_string;
    --
    -- 文字列の長さを取得
    ln_length := LENGTH(lv_changed_string);
    --
    FOR i IN 1..ln_length LOOP
      -- 文字列の前後に半角スペース、タブが存在するか確認
      IF ( REGEXP_LIKE(lv_changed_string, '^' || ' ') OR 
           REGEXP_LIKE(lv_changed_string, ' ' || '$') OR
           REGEXP_LIKE(lv_changed_string, '^' || CHR(9)) OR
           REGEXP_LIKE(lv_changed_string, CHR(9) || '$') ) THEN
        --
        -- 半角スペース、タブが存在する場合
        -- 文字列の前後の半角スペース、タブを削除
        lv_changed_string := REGEXP_REPLACE(lv_changed_string, '^' || ' ', NULL);
        lv_changed_string := REGEXP_REPLACE(lv_changed_string, ' ' || '$', NULL);
        lv_changed_string := REGEXP_REPLACE(lv_changed_string, '^' || CHR(9), NULL);
        lv_changed_string := REGEXP_REPLACE(lv_changed_string, CHR(9) || '$', NULL);
      ELSE
        -- 半角スペース、タブが存在しない場合
        EXIT;
      END IF;
    END LOOP;
    --
    RETURN lv_changed_string;
    --
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name||cv_period||cv_prg_name||cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END trim_space_tab;
  --
-- Ver1.1 Add End
--
END xxccp_oiccommon_pkg;
/
