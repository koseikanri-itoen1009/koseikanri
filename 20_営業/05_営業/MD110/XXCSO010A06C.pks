CREATE OR REPLACE PACKAGE APPS.XXCSO010A06C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2015. All rights reserved.
 *
 * Package Name     : XXCSO010A06C(spec)
 * Description      : 覚書出力
 * MD.050           : 覚書出力(MD050_CSO_010A06)
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- --------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- --------------------------------------------
 *  2015/02/10    1.0   S.Niki           main新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf             OUT    VARCHAR2     -- エラーメッセージ #固定#
   ,retcode            OUT    VARCHAR2     -- エラーコード     #固定#
   ,iv_report_type     IN     VARCHAR2     -- 帳票区分
   ,iv_contract_number IN     VARCHAR2     -- 契約書番号
   ,in_org_request_id  IN     NUMBER       -- 発行元要求ID
  );
END XXCSO010A06C;
/
