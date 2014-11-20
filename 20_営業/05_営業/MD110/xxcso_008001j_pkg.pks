CREATE OR REPLACE PACKAGE APPS.xxcso_008001j_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcso_008001j_pkg(SPEC)
 * Description      : 週次活動状況照会共通関数
 * MD.050/070       : 
 * Version          : 1.0
 *
 * Program List
 *  ------------------------- ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  ------------------------- ---- ----- --------------------------------------------------
 *  get_baseline_base_code   F    V      検索基準拠点コード取得関数
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/13    1.0   N.Yanagitaira    新規作成
 *
 *****************************************************************************************/
--
  -- 検索基準拠点コード拠点コード取得関数
  FUNCTION get_baseline_base_code
  RETURN VARCHAR2;
--
END xxcso_008001j_pkg;
/
