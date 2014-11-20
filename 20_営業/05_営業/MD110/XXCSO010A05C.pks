CREATE OR REPLACE PACKAGE XXCSO010A05C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCSO010A05C (spec)
 * Description      : 契約書確定状況CSV出力
 * MD.050           : 契約書確定状況CSV出力 (MD050_CSO_010A05)
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
 *  2012/08/07    1.0   S.Niki           main新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf        OUT    VARCHAR2     -- エラーメッセージ #固定#
   ,retcode       OUT    VARCHAR2     -- エラーコード     #固定#
   ,iv_base_code  IN     VARCHAR2     -- 売上拠点
   ,iv_status     IN     VARCHAR2     -- 契約状況
   ,iv_date_from  IN     VARCHAR2     -- 抽出対象期間(FROM)
   ,iv_date_to    IN     VARCHAR2     -- 抽出対象期間(TO)
  );
END XXCSO010A05C;
/
