CREATE OR REPLACE PACKAGE XXCFO007A01C
AS
/*************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 * 
 * Package Name    : XXCFO007A01C
 * Description     : AP請求書インポートチェック
 * MD.050          : MD050_CFO_007_A01_AP請求書インポートチェック
 * MD.070          : MD050_CFO_007_A01_AP請求書インポートチェック
 * Version         : 1.0
 * 
 * Program List
 * --------------- ---- ----- --------------------------------------------
 *  Name           Type  Ret   Description
 * --------------- ---- ----- --------------------------------------------
 *  main            P         コンカレント実行ファイル登録プロシージャ
 * 
 * Change Record
 * ------------- ----- ------------- -------------------------------------
 *  Date          Ver.  Editor        Description
 * ------------- ----- ------------- -------------------------------------
 *  2009-10-01    1.0  SCS 寺内      初回作成
 ************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,         --   エラーメッセージ #固定#
    retcode       OUT    VARCHAR2          --   エラーコード     #固定#
  );
END XXCFO007A01C;
/
