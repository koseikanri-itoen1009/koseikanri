CREATE OR REPLACE PACKAGE XXCOI006A21C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI006A21C(spec)
 * Description      : 棚卸結果作成
 * MD.050           : HHT棚卸結果データ取込 <MD050_COI_A21>
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
 *  2009/01/15    1.0   N.Abe            新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf            OUT   VARCHAR2,      --   エラーメッセージ #固定#
    retcode           OUT   VARCHAR2,      --   エラーコード     #固定#
    iv_file_id        IN    VARCHAR2,      -- 1.FILE_ID
    iv_format_pattern IN    VARCHAR2       -- 2.フォーマットパターン
  );
END XXCOI006A21C;
/
