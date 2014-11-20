CREATE OR REPLACE PACKAGE APPS.xxcso_005001j_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcso_005001j_pkg(spec)
 * Description      : リソースセキュリティパッケージ
 * MD.050           :  MD050_CSO_005_A01_営業員リソース関連情報のセキュリティ
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 * get_predicate          セキュリティポリシー取得
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-05-08    1.0   Hiroshi.Ogawa    新規作成(T1_0593対応)
 *****************************************************************************************/
  -- セキュリティポリシー取得
  FUNCTION  get_predicate(
    iv_schema            IN   VARCHAR2
   ,iv_object            IN   VARCHAR2
  ) RETURN VARCHAR2;
--
END xxcso_005001j_pkg;
/
