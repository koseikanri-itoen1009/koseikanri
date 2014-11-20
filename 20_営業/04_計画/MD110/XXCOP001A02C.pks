CREATE OR REPLACE PACKAGE APPS.XXCOP001A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOP001A02C(spec)
 * Description      : 基準計画の取込
 * MD.050           : 基準計画の取込 MD050_COP_001_A02
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
 *  2008/12/16    1.0   Y.Goto           新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,         --   エラーメッセージ #固定#
    retcode       OUT    VARCHAR2,         --   エラーコード     #固定#
    in_file_id    IN     NUMBER,           --   ファイルID
    iv_format     IN     VARCHAR2          --   フォーマットパターン
  );
END XXCOP001A02C;
/
