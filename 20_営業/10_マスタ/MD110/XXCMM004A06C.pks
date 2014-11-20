CREATE OR REPLACE PACKAGE XXCMM004A06C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM004A06C(spec)
 * Description      : 原価一覧作成
 * MD.050           : 原価一覧作成 MD050_CMM_004_A06
 * Version          : Draft2C
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/11    1.0   N.Nishimura      main新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf               OUT    VARCHAR2,        --   エラーメッセージ #固定#
    retcode              OUT    VARCHAR2,        --   エラーコード     #固定#
    iv_calendar_code     IN     VARCHAR2,        --   標準原価対象年度
    iv_cost_type         IN     VARCHAR2         --   営業原価タイプ
  );
END XXCMM004A06C;
/
