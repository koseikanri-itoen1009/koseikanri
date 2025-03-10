CREATE OR REPLACE PACKAGE XXCSM001A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM001A03C(spec)
 * Description      : 販売計画テーブルに登録された処理対象予算年度のデータを抽出し、
 *                  : CSV形式のファイルを作成します。
 *                  : 作成したCSVファイルを所定のフォルダに格納します。
 * MD.050           : MD050_CSM_001_A03_年間計画情報系システムIF
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
 *  2008-12-01    1.0   M.ohtsuki       新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf        OUT NOCOPY VARCHAR2          --   エラーメッセージ #固定#
   ,retcode       OUT NOCOPY VARCHAR2          --   エラーコード     #固定#
  );
END XXCSM001A03C;
/
