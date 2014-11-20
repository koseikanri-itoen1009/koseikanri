CREATE OR REPLACE PACKAGE XXCFO010A01C
AS
/*************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 * 
 * Package Name    : XXCFO010A01C
 * Description     : 情報系システムへのデータ連携（勘定科目明細）
 * MD.050          : MD050_CFO_010_A01_情報系システムへのデータ連携（勘定科目明細）
 * MD.070          : MD050_CFO_010_A01_情報系システムへのデータ連携（勘定科目明細）
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
 *  2008-11-18    1.0  SCS 加藤 忠   初回作成
 ************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf          OUT    VARCHAR2,         --   エラーメッセージ #固定#
    retcode         OUT    VARCHAR2,         --   エラーコード     #固定#
    iv_period_name  IN     VARCHAR2          --   会計期間
  );
END XXCFO010A01C;
/
