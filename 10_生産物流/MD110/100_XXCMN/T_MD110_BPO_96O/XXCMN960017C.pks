CREATE OR REPLACE PACKAGE XXCMN960017C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2013. All rights reserved.
 *
 * Package Name     : XXCMN960017C(spec)
 * Description      : OPM手持在庫パージリカバリ
 * MD.050           : T_MD050_BPO_96O_OPM手持在庫パージリカバリ
 * Version          : 1.00
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2013/04/08   1.00  D.Sugahara       新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,         --   エラーメッセージ #固定#
    retcode       OUT    VARCHAR2          --   エラーコード     #固定#
  );
END XXCMN960017C;
/
