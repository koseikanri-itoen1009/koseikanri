CREATE OR REPLACE PACKAGE XXCOK022A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK022A01C(spec)
 * Description      : 販手販協予算Excelアップロード
 * MD.050           : 販手販協予算Excelアップロード MD050_COK_022_A01
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
 *  2009/01/20    1.0   T.Osada          新規作成
 *
 *****************************************************************************************/
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
     errbuf            OUT  VARCHAR2    --エラーメッセージ #固定#
   , retcode           OUT  VARCHAR2    --エラーコード     #固定#
   , iv_file_id        IN   VARCHAR2    --ファイルID
   , iv_format_pattern IN   VARCHAR2    --フォーマットパターン
   );
END XXCOK022A01C;
/
