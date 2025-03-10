CREATE OR REPLACE PACKAGE XXCOI004A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI004A03C(spec)
 * Description      : 月次スライド
 * MD.050           : 月次スライド MD050_COI_004_A03
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
 *  2008/12/09    1.0   SCS H.Wada       新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf  OUT VARCHAR2   -- 1.エラーメッセージ #固定#
   ,retcode OUT VARCHAR2   -- 2.エラーコード     #固定#
  );
END XXCOI004A03C;
/
