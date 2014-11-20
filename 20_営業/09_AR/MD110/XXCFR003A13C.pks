CREATE OR REPLACE PACKAGE XXCFR003A13C AS
/*************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 * 
 * Package Name    : XXCFR003A13C
 * Description     : 汎用商品（店コラム毎集計）請求データ作成
 * MD.050          : MD050_CFR_003_A13_汎用商品（店コラム毎集計）請求データ作成
 * MD.070          : MD050_CFR_003_A13_汎用商品（店コラム毎集計）請求データ作成
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
 *  2008-12-17    1.0  SCS 濱中 亮一 初回作成
 *  2009-10-05    1.1  SCS 廣瀬真佐人 共通課題IE535対応
 ************************************************************************/

--===============================================================
-- コンカレント実行ファイル登録プロシージャ
--===============================================================
  PROCEDURE main(
    errbuf           OUT VARCHAR2,
    retcode          OUT VARCHAR2,
    iv_target_date   IN  VARCHAR2,    -- 締日
-- Modify 2009.10.05 Ver1.1 Start
--    iv_ar_code1      IN  VARCHAR2     -- 売掛コード１(請求書)
    iv_cust_code     IN  VARCHAR2,    -- 顧客コード
    iv_cust_class    IN  VARCHAR2     -- 顧客区分
-- Modify 2009.10.05 Ver1.1 End
  );
END  XXCFR003A13C;
/
