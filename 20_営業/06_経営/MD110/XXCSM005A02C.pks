CREATE OR REPLACE PACKAGE XXCSM005A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM005A02C(spec)
 * Description      : 速報出力商品ヘッダテーブル、及び速報出力商品明細テーブルのデータを基に、
 *                  : 日次速報帳票(群別販売速報／商品導入速報)に出力する商品情報を
 *                  : 情報系システムに連携するためのI/Fファイルを作成します。
 * MD.050           : MD050_CSM_005_A02_速報出力対象商品データIF
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
 *  2009-01-07    1.0   M.ohtsuki       新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf        OUT NOCOPY VARCHAR2          --   エラーメッセージ #固定#
   ,retcode       OUT NOCOPY VARCHAR2          --   エラーコード     #固定#
  );
END XXCSM005A02C;
/
