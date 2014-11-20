CREATE OR REPLACE PACKAGE XXCFR003A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR003A04C(spec)
 * Description      : EDI請求書データ作成
 * MD.050           : MD050_CFR_003_A04_EDI請求書データ作成
 * MD.070           : MD050_CFR_003_A04_EDI請求書データ作成
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
 *  2009/01/21    1.00 SCS 大川 恵      初回作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                 OUT    VARCHAR2,         -- エラーメッセージ #固定#
    retcode                OUT    VARCHAR2,         -- エラーコード     #固定#
    iv_target_date         IN     VARCHAR2,         -- 締日
    iv_ar_code1            IN     VARCHAR2,         -- 売掛コード１(請求書)
    iv_start_mode          IN     VARCHAR2          -- 起動区分
  );
END XXCFR003A04C;
/
