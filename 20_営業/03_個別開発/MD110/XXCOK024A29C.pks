CREATE OR REPLACE PACKAGE APPS.XXCOK024A29C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A29C(spec)
 * Description      : 問屋販売条件請求書Excelアップロード（収益認識）
 * MD.050           : 問屋販売条件請求書Excelアップロード（収益認識） MD050_COK_024_A29
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
 *  2020/06/18    1.0   N.Abe            main新規作成
 *
 *****************************************************************************************/
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf            OUT  VARCHAR2,   --エラーメッセージ #固定#
    retcode           OUT  VARCHAR2,   --エラーコード     #固定#
    iv_file_id        IN   VARCHAR2,   --ファイルID
    iv_format_pattern IN   VARCHAR2    --フォーマットパターン
  );
END XXCOK024A29C;
/
