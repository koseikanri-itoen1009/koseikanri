CREATE OR REPLACE PACKAGE APPS.xxcso_019003j_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcso_019003j_pkg(SPEC)
 * Description      : 拠点別月別計画テーブル登録
 * MD.050/070       : 
 * Version          : 1.0
 *
 * Program List
 *  ------------------------- ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  ------------------------- ---- ----- --------------------------------------------------
 *  set_dept_monthly_plans     P          拠点別月別計画テーブル登録用プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/28    1.0   R.Oikawa          新規作成
 *  2009-05-01    1.1   Tomoko.Mori      T1_0897対応
 *
 *****************************************************************************************/
--
   -- 拠点別月別計画テーブル登録用プロシージャ
  PROCEDURE set_dept_monthly_plans(
    iv_base_code                 IN  VARCHAR2,           -- 拠点CD
    iv_year_month                IN  VARCHAR2,           -- 年月
    in_dept_monthly_plan_id      IN  NUMBER,             -- 拠点別月別計画ID
    iv_sales_plan_rel_div        IN  VARCHAR2            -- 売上計画開示区分
  );
--
END xxcso_019003j_pkg;
/
