CREATE OR REPLACE PACKAGE APPS.XXCSO019A07C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO019A07C(spec)
 * Description      : 指定した営業員の指定した日の１時間ごとの訪問実績(訪問先)を表示します。
 *                    １週間前の訪問実績を同様に表示して比較の対象とします。
 * MD.050           : MD050_CSO_019_A07_営業員別訪問実績表
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
 *  2009-01-30    1.0   Kazuyo.Hosoi     新規作成
 *  2009-05-01    1.1   Tomoko.Mori      T1_0897対応
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf             OUT NOCOPY VARCHAR2          --   エラーメッセージ #固定#
   ,retcode            OUT NOCOPY VARCHAR2          --   エラーコード     #固定#
   ,iv_visit_date      IN  VARCHAR2                 --   訪問日
   ,iv_employee_number IN  VARCHAR2                 --   従業員コード
  );
END XXCSO019A07C;
/
