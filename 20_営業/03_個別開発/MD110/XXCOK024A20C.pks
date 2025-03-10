CREATE OR REPLACE PACKAGE APPS.XXCOK024A20C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A20C (spec)
 * Description      : 控除データアップロード
 * MD.050           : 控除データアップロード MD050_COK_024_A20
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
 *  2020/02/04    1.0   Y.Nakajima       main新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                          OUT    VARCHAR2          -- エラーメッセージ #固定#
   ,retcode                         OUT    VARCHAR2          -- エラーコード     #固定#
   ,iv_file_id                      IN     VARCHAR2          -- 1.ファイルID(必須)
   ,iv_file_format                  IN     VARCHAR2          -- 2.ファイルフォーマット(必須)
  );
END XXCOK024A20C;
/
