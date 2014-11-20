CREATE OR REPLACE PACKAGE XXCFR003A15C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR003A15C(spec)
 * Description      : 標準請求書税込
 * MD.050           : MD050_CFR_003_A15_標準請求書税込
 * MD.070           : MD050_CFR_003_A15_標準請求書税込
 * Version          : 1.7
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
 *  2008/11/28    1.00 SCS 大川 恵      初回作成
 *  2009/09/10    1.3  SCS 廣瀬 真佐人  [共通課題IE535] 請求書問題対応
 *  2010/12/10    1.7  SCS 石渡 賢和    [E_本稼動_05401] パラメータ「請求書発行サイクル」の追加
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                 OUT     VARCHAR2,         -- エラーメッセージ #固定#
    retcode                OUT     VARCHAR2,         -- エラーコード     #固定#
    iv_target_date         IN      VARCHAR2,         -- 締日
-- Modify 2009.09.10 Ver1.3 Start
--    iv_ar_code1            IN      VARCHAR2          -- 売掛コード１(請求書)
    iv_custome_cd          IN      VARCHAR2,         -- 顧客番号(顧客)
    iv_invoice_cd          IN      VARCHAR2,         -- 顧客番号(請求用)
    iv_payment_cd          IN      VARCHAR2          -- 顧客番号(売掛管理先)
-- Modify 2009.09.10 Ver1.3 End
-- Add 2010.12.10 Ver1.7 Start
   ,iv_bill_pub_cycle      IN      VARCHAR2          -- 請求書発行サイクル
-- Add 2010.12.10 Ver1.7 End
  );
END XXCFR003A15C;
/
