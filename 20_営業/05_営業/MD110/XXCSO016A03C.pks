CREATE OR REPLACE PACKAGE APPS.XXCSO016A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO016A03C(spec)
 * Description      : 見積ヘッダ、見積明細データを情報系システムに送信するための
 *                    CSVファイルを作成します。
 * MD.050           :  MD050_CSO_016_A03_情報系-EBSインターフェース：
 *                     (OUT)見積情報データ
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
 *  2008-12-09    1.0   Kazuyo.Hosoi     新規作成
 *  2009-05-01    1.1   Tomoko.Mori      T1_0897対応
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf        OUT NOCOPY VARCHAR2          --   エラーメッセージ #固定#
   ,retcode       OUT NOCOPY VARCHAR2          --   エラーコード     #固定#
   ,iv_from_value IN  VARCHAR2                 --   パラメータ更新日 FROM
   ,iv_to_value   IN  VARCHAR2                 --   パラメータ更新日 TO
  );
END XXCSO016A03C;
/
