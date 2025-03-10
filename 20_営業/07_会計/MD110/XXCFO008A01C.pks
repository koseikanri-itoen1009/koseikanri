CREATE OR REPLACE PACKAGE XXCFO008A01C
AS
/*************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 * 
 * Package Name    : XXCFO008A01C
 * Description     : 顧客マスタVD釣銭基準額の更新
 * MD.050          : MD050_CFO_008_A01_顧客マスタVD釣銭基準額の更新
 * MD.070          : MD050_CFO_008_A01_顧客マスタVD釣銭基準額の更新
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
 *  2008-11-07    1.0  SCS 加藤 忠   初回作成
 ************************************************************************/
--
--===============================================================
-- コンカレント実行ファイル登録プロシージャ
--===============================================================
  PROCEDURE main(
    errbuf              OUT     VARCHAR2,         --    エラーメッセージ #固定#
    retcode             OUT     VARCHAR2,         --    エラーコード     #固定#
    iv_operation_date   IN      VARCHAR2          --    運用日
  );
END XXCFO008A01C;
/
