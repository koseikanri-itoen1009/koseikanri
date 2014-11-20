CREATE OR REPLACE PACKAGE XXCFR001A04C
AS
/*************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 * 
 * Package Name    : XXCFR001A04C
 * Description     : AR取引インポートチェック
 * MD.050          : MD050_CFR_001_A04_AR取引インポートチェック
 * MD.070          : MD050_CFR_001_A04_AR取引インポートチェック
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
END XXCFR001A04C;
/
