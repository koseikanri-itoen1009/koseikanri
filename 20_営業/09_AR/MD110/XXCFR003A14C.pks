CREATE OR REPLACE PACKAGE XXCFR003A14C
AS
/*************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 * 
 * Package Name    : XXCFR003A14C
 * Description     : 汎用請求起動処理
 * MD.050          : MD050_CFR_003_A14_汎用請求起動処理
 * MD.070          : MD050_CFR_003_A14_汎用請求起動処理
 * Version         : 1.1
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
 *  2009-10-14    1.0  SCS 安川 智博 初回作成
 *  2009-09-18    1.1  SCS 萱原 伸哉 AR仕様変更IE535対応
 ************************************************************************/

--===============================================================
-- コンカレント実行ファイル登録プロシージャ
--===============================================================
  PROCEDURE main(
    errbuf           OUT VARCHAR2,
    retcode          OUT VARCHAR2,
    iv_target_date   IN  VARCHAR2,    -- 締日
-- Modify 2009.10.14 Ver1.1 Start
--    iv_ar_code1      IN  VARCHAR2,    -- 売掛コード１(請求書)
    iv_cust_code     IN  VARCHAR2,    -- 顧客コード
-- Modify 2009.10.14 Ver1.1 End    
    iv_exec_003A06C  IN  VARCHAR2,    -- 汎用店別請求
    iv_exec_003A07C  IN  VARCHAR2,    -- 汎用伝票別請求
    iv_exec_003A08C  IN  VARCHAR2,    -- 汎用商品（全明細）
    iv_exec_003A09C  IN  VARCHAR2,    -- 汎用商品（単品毎集計）
    iv_exec_003A10C  IN  VARCHAR2,    -- 汎用商品（店単品毎集計）
    iv_exec_003A11C  IN  VARCHAR2,    -- 汎用商品（単価毎集計）
    iv_exec_003A12C  IN  VARCHAR2,    -- 汎用商品（店単価毎集計）
    iv_exec_003A13C  IN  VARCHAR2     -- 汎用（店コラム毎集計）
  );
END  XXCFR003A14C;
/
