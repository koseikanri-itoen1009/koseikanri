CREATE OR REPLACE PACKAGE XXCFO010A04C
AS
/*************************************************************************
 * Copyright(c)SCSK Corporation, 2016. All rights reserved.
 * 
 * Package Name    : XXCFO010A04C(spec)
 * Description     : 稟議WF連携
 * MD.050          : MD050_CFO_010_A04_稟議WF連携
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
 *  2016-12-09    1.0  SCSK 小路恭弘  初回作成
 ************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf             OUT    VARCHAR2,         --   エラーメッセージ #固定#
    retcode            OUT    VARCHAR2,         --   エラーコード     #固定#
    iv_coop_date_from  IN     VARCHAR2,         --   1.連携日From
    iv_coop_date_to    IN     VARCHAR2          --   2.連携日To
  );
END XXCFO010A04C;
/
