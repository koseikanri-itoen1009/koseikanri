CREATE OR REPLACE PACKAGE APPS.xxcso_010001j_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcso_010001j_pkg(SPEC)
 * Description      : 権限判定関数(XXCSOユーティリティ）
 * MD.050/070       : 
 * Version          : 1.0
 *
 * Program List
 *  ------------------------- ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  ------------------------- ---- ----- --------------------------------------------------
 *  get_authority               F    V     権限判定関数
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/13    1.0   R.Oikawa          新規作成
 *  2009-05-01    1.1   Tomoko.Mori      T1_0897対応
 *
 *****************************************************************************************/
--
   -- 権限判定関数
  FUNCTION get_authority(
    iv_sp_decision_header_id      IN  NUMBER           -- SP専決ヘッダID
  )
  RETURN VARCHAR2;
--
END xxcso_010001j_pkg;
/
