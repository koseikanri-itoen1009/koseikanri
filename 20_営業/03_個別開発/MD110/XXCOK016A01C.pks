CREATE OR REPLACE PACKAGE XXCOK016A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK016A01C(spec)
 * Description      : 組み戻し・残高取消・保留情報(CSVファイル)の取込処理
 * MD.050           : 残高更新Excelアップロード MD050_COK_016_A01
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 組み戻し・残高取消・保留情報(CSVファイル)の取込処理
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/25     1.0   K.Ezaki         新規作成
 *  2009/03/25     1.1   S.Kayahara      最終行にスラッシュ追加
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
     errbuf     OUT VARCHAR2 -- エラーメッセージ
    ,retcode    OUT VARCHAR2 -- エラーコード
    ,iv_file_id IN  VARCHAR2 -- ファイルID
    ,iv_format  IN  VARCHAR2 -- フォーマット
  );
END XXCOK016A01C;
/
