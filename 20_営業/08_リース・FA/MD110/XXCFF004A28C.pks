CREATE OR REPLACE PACKAGE XXCFF004A28C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF004A28C(spec)
 * Description      : 営業システム構築プロジェクト
 * MD.050           : 再リース要否ダウンロード 004_A28
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  para_check             p パラメータチェック処理                  (A-2)
 *  csv_buf                p CSV編集処理                             (A-4)
 *  csv_header             p CSVヘッダー作成
 *  submain                p メイン処理プロシージャ
 *  main                   p コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/05    1.0   SCS大井 信幸     新規作成
 *  2009/02/09    1.1   SCS大井 信幸     ログ出力項目追加
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf         OUT NOCOPY   VARCHAR2,   --   エラーメッセージ #固定#
    retcode        OUT NOCOPY   VARCHAR2,   --   エラーコード     #固定#
    iv_date_from   IN  VARCHAR2,            --   1.リース終了日FROM
    iv_date_to     IN  VARCHAR2,            --   2.リース終了日TO
    iv_class_from  IN  VARCHAR2,            --   3.リース種別FROM
    iv_class_to    IN  VARCHAR2             --   4.リース種別TO
  );
END XXCFF004A28C;
/
