CREATE OR REPLACE PACKAGE XXCFO011A01C
AS
/*************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 * 
 * Package Name    : XXCFO011A01C
 * Description     : 人事システムデータ連携
 * MD.050          : MD050_CFO_011_A01_人事システムデータ連携
 * MD.070          : MD050_CFO_011_A01_人事システムデータ連携
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
 *  2008-11-25    1.0  SCS 加藤 忠   初回作成
 ************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf              OUT    VARCHAR2,         --   エラーメッセージ #固定#
    retcode             OUT    VARCHAR2,         --   エラーコード     #固定#
    iv_target_file_name IN     VARCHAR2          --   連携ファイル名
  );
END XXCFO011A01C;
/
