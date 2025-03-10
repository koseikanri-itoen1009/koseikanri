CREATE OR REPLACE PACKAGE APPS.XXCOI015A03C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2016. All rights reserved.
 *
 * Package Name     : XXCOI015A03C (spec)
 * Description      : 資材取引シーケンス更新
 * MD.050           : 
 * Version          : 1.0
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
 *  2016/11/10    1.0   S.Yamashita      main新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                 OUT  VARCHAR2,         --   エラーメッセージ #固定#
    retcode                OUT  VARCHAR2          --   エラーコード     #固定#
  );
END XXCOI015A03C;
/
