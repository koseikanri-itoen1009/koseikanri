CREATE OR REPLACE PACKAGE XXCOK007A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK007A01C(spec)
 * Description      : 売上実績振替情報作成(EDI)
 * MD.050           : 売上実績振替情報作成(EDI) MD050_COK_007_A01
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                売上実績振替情報作成(EDI)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/25    1.0   S.Sasaki         main新規作成
 *
 *****************************************************************************************/
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
     errbuf            OUT  VARCHAR2     --エラーメッセージ
  ,  retcode           OUT  VARCHAR2     --エラーコード
  ,  iv_file_name      IN   VARCHAR2     --ファイル名
  ,  iv_execution_type IN   VARCHAR2     --実行区分 1:通常 2:リカバリ
  );
END XXCOK007A01C;
/
