CREATE OR REPLACE PACKAGE XXCOK021A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK021A01C(spec)
 * Description      : 問屋販売条件請求書Excelアップロード
 * MD.050           : 問屋販売条件請求書Excelアップロード MD050_COK_021_A01
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
 *  2008/11/11    1.0   S.Sasaki         main新規作成
 *
 *****************************************************************************************/
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf            OUT  VARCHAR2,   --エラーメッセージ #固定#
    retcode           OUT  VARCHAR2,   --エラーコード     #固定#
    iv_file_id        IN   VARCHAR2,   --ファイルID
    iv_format_pattern IN   VARCHAR2    --フォーマットパターン
  );
END XXCOK021A01C;
/
