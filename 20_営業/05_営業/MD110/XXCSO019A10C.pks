CREATE OR REPLACE PACKAGE APPS.XXCSO019A10C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO019A10C(spec)
 * Description      : 訪問売上計画管理表（随時実行の帳票）用にサマリテーブルを作成します。
 * MD.050           :  MD050_CSO_019_A10_訪問売上計画管理集計バッチ
 * Version          : 1.2
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
 *  2009-01-13    1.0   Tomoko.Mori      新規作成
 *  2009-05-01    1.1   Tomoko.Mori      T1_0897対応
 *  2012-02-17    1.2   SCSK白川篤史     【E_本稼動_08750】対応
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf        OUT NOCOPY VARCHAR2          --   エラーメッセージ #固定#
   ,retcode       OUT NOCOPY VARCHAR2          --   エラーコード     #固定#
-- 2012/02/17 Ver.1.2 A.Shirakawa ADD Start
   ,iv_process_div IN        VARCHAR2          --   処理区分
-- 2012/02/17 Ver.1.2 A.Shirakawa ADD End
  );
END XXCSO019A10C;
/
