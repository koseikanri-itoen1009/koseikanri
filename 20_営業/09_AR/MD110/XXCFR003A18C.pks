create or replace PACKAGE XXCFR003A18C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR003A18C(spec)
 * Description      : 標準請求書税抜(店舗別内訳)
 * MD.050           : MD050_CFR_003_A18_標準請求書税込(店舗別内訳)
 * MD.070           : MD050_CFR_003_A18_標準請求書税込(店舗別内訳)
 * Version          : 1.50
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
 *  2009/09/25    1.00 SCS 安川 智博  初回作成
 *  2010/12/10    1.30 SCS 石渡 賢和    障害「E_本稼動_05401」対応
 *  2013/12/02    1.40 SCSK 中野 徹也   障害「E_本稼動_11330」対応
 *  2014/03/27    1.50 SCSK 山下 翔太   障害 [E_本稼動_11617] 対応
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
-- Add 2010.12.10 Ver1.30 Start
   ,iv_bill_pub_cycle      IN      VARCHAR2          -- 請求書発行サイクル
-- Add 2010.12.10 Ver1.30 End
-- Add 2013.12.02 Ver1.40 Start
   ,iv_tax_output_type     IN      VARCHAR2          -- 税別内訳出力区分
-- Add 2013.12.02 Ver1.40 End
-- Add 2014.03.27 Ver1.50 Start
   ,iv_bill_invoice_type   IN      VARCHAR2          -- 請求書出力形式
-- Add 2014.03.27 Ver1.50 End
  );
END XXCFR003A18C;
/
