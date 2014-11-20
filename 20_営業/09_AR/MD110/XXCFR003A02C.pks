CREATE OR REPLACE PACKAGE XXCFR003A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR003A02C(spec)
 * Description      : 請求ヘッダデータ作成
 * MD.050           : MD050_CFR_003_A02_請求ヘッダデータ作成
 * MD.070           : MD050_CFR_003_A02_請求ヘッダデータ作成
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
 *  2008/11/11    1.00 SCS 松尾 泰生    初回作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                  OUT     VARCHAR2,         -- エラーメッセージ #固定#
    retcode                 OUT     VARCHAR2,         -- エラーコード     #固定#
    iv_target_date          IN      VARCHAR2,         -- 締日
    iv_bill_acct_code       IN      VARCHAR2,         -- 請求先顧客コード
    iv_batch_on_judge_type  IN      VARCHAR2          -- 夜間手動判断区分
  );
END XXCFR003A02C;--(変更)
/
