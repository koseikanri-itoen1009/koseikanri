CREATE OR REPLACE PACKAGE XXCOK008A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK008A04C(spec)
 * Description      : 売上振替割合の登録
 * MD.050           : 売上振替割合の登録 MD050_COK_008_A04
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                  コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/10/28    1.0   S.Sasaki         新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf            OUT  VARCHAR2,   --エラーメッセージ
    retcode           OUT  VARCHAR2,   --エラーコード
    iv_file_id        IN   VARCHAR2,   --ファイルID
    iv_format_pattern IN   VARCHAR2    --フォーマットパターン
  );
END XXCOK008A04C;
/
