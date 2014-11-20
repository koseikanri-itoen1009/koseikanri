create or replace PACKAGE XXCFR003A19C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR003A19C(spec)
 * Description      : 標準請求書税込(店舗別内訳)
 * MD.050           : MD050_CFR_003_A19_標準請求書税抜(店舗別内訳)
 * MD.070           : MD050_CFR_003_A19_標準請求書税抜(店舗別内訳)
 * Version          : 1.00
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/09/17    1.00 SCS 安川 智博  初回作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                 OUT     VARCHAR2,         -- エラーメッセージ #固定#
    retcode                OUT     VARCHAR2,         -- エラーコード     #固定#
    iv_target_date         IN      VARCHAR2,         -- 締日
    iv_customer_code10     IN      VARCHAR2,         -- 顧客
    iv_customer_code20     IN      VARCHAR2,         -- 請求書用顧客
    iv_customer_code21     IN      VARCHAR2,         -- 統括請求書用顧客
    iv_customer_code14     IN      VARCHAR2          -- 売掛管理先顧客
  );
END XXCFR003A19C;
