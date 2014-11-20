CREATE OR REPLACE PACKAGE XXCFR004A02C--(変更)
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR004A02C(spec)
 * Description      : 支払通知データダウンロード
 * MD.050           : MD050_CFR_004_A02_支払通知データダウンロード
 * MD.070           : MD050_CFR_004_A02_支払通知データダウンロード
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
 *  2008/11/19    1.00 SCS 中村 博      初回作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                 OUT     VARCHAR2,         --    エラーメッセージ #固定#
    retcode                OUT     VARCHAR2,         --    エラーコード     #固定#
--    ↓IN のﾊﾟﾗﾒｰﾀがある場合は適宜編集して下さい。
    iv_receipt_cust_code   IN      VARCHAR2,         --    入金先顧客
    iv_due_date_from       IN      VARCHAR2,         --    支払年月日(FROM)
    iv_due_date_to         IN      VARCHAR2,         --    支払年月日(TO)
    iv_received_date_from  IN      VARCHAR2,         --    受信日(FROM)
    iv_received_date_to    IN      VARCHAR2          --    受信日(TO)
  );
END XXCFR004A02C;--(変更)
/
