CREATE OR REPLACE PACKAGE XXCFR003A21C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2021. All rights reserved.
 *
 * Package Name     : XXCFR003A21C(spec)
 * Description      : 消化VD請求書出力
 * MD.050           : MD050_CFR_003_A21_消化VD請求書出力
 * MD.070           : MD050_CFR_003_A21_消化VD請求書出力
 * Version          : 1.0
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
 *  2021/09/30    1.0   SCSK 二村 悠香   新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                 OUT     VARCHAR2         -- エラーメッセージ #固定#
   ,retcode                OUT     VARCHAR2         -- エラーコード     #固定#
   ,iv_target_date         IN      VARCHAR2         -- 締日
   ,iv_custome_cd          IN      VARCHAR2         -- 顧客番号(顧客)
   ,iv_payment_cd          IN      VARCHAR2         -- 顧客番号(売掛管理先)
   ,iv_bill_pub_cycle      IN      VARCHAR2         -- 請求書発行サイクル
   ,iv_tax_output_type     IN      VARCHAR2         -- 税別内訳出力区分
   ,iv_bill_invoice_type   IN      VARCHAR2         -- 請求書出力形式
  );
END XXCFR003A21C;
/
