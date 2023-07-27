CREATE OR REPLACE PACKAGE apps.xxccp_oiccommon_pkg
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2022. All rights reserved.
 *
 * Package Name           : xxccp_oiccommon_pkg(spec)
 * Description            : 
 * MD.070                 : MD070_IPO_CCP_共通関数
 * Version                : 1.1
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
 *  2022-10-21    1.0  Ryo.Kikuchi      新規作成
 *  2023-02-07    1.1  Y.Ooyama         移行障害No.11対応
 *****************************************************************************************/
--
  -- CSVファイル用文字列変換
  FUNCTION to_csv_string(
              iv_string       IN VARCHAR2                   -- 対象文字列
             ,iv_lf_replace   IN VARCHAR2 DEFAULT NULL      -- LF置換単語
           )
    RETURN VARCHAR2;
  --
-- Ver1.1 Add Start
  -- 文字列の前後半角スペース/タブ削除
  FUNCTION trim_space_tab(
              iv_string       IN VARCHAR2                   -- 対象文字列
           )
    RETURN VARCHAR2;
-- Ver1.1 Add End
  --
END xxccp_oiccommon_pkg;
/
