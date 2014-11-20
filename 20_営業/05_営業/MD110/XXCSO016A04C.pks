CREATE OR REPLACE PACKAGE APPS.XXCSO016A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO016A04C(spec)
 * Description      : EBSに登録された訪問実績データを情報系システムに連携するための
 *                    CSVファイルを作成します。
 * MD.050           :  MD050_CSO_016_A04_情報系-EBSインターフェース：
 *                     (OUT)訪問実績データ
 * Version          : 1.1
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
 *  2008-12-19    1.0   Kazuyo.Hosoi     新規作成
 *  2009-02-26    1.1   K.Sai            レビュー結果反映 
 *  2009-03-05    1.1   Mio.Maruyama     販売実績テーブル仕様変更による
 *                                       データ抽出条件変更対応
 *  2009-05-01    1.2   Tomoko.Mori      T1_0897対応
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
END XXCSO016A04C;
/
