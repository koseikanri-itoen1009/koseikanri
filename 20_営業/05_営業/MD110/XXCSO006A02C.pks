CREATE OR REPLACE PACKAGE XXCSO006A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO006A02C(spec)
 * Description      : EBS(ファイルアップロードI/F)に取込まれた訪問実績データをタスクに取込みます。
 *                    
 * MD.050           : MD050_CSO_006_A02_訪問実績データ格納
 *                    
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
 *  2008-12-01    1.0   Kichi.Cho        新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf               OUT NOCOPY VARCHAR2          -- エラーメッセージ #固定#
   ,retcode              OUT NOCOPY VARCHAR2          -- エラーコード     #固定#
   ,in_file_id           IN         NUMBER            -- ファイルID
   ,iv_fmt_ptn           IN         VARCHAR2          -- フォーマットパターン
  );
END XXCSO006A02C;
/
