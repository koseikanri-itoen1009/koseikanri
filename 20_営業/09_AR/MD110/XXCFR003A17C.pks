CREATE OR REPLACE PACKAGE XXCFR003A17C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR003A17C(spec)
 * Description      : イセトー請求書データ作成
 * MD.050           : MD050_CFR_003_A17_イセトー請求書データ作成
 * MD.070           : MD050_CFR_003_A17_イセトー請求書データ作成
 * Version          : 1.2
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
 *  2009-02-23    1.00  SCS 白砂 幸世     新規作成
 *  2009-09-29    1.10  SCS 安川 智博     共通課題「IE535」対応
 *  2024-03-06    1.2   SCSK 大山 洋介    E_本稼動_19496 グループ会社統合対応
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                 OUT     VARCHAR2,         -- エラーメッセージ #固定#
    retcode                OUT     VARCHAR2,         -- エラーコード     #固定#
    iv_target_date         IN      VARCHAR2,         -- 締日
-- Modify 2009-09-29 Ver1.10 Start
    iv_customer_code10     IN      VARCHAR2,         -- 顧客
    iv_customer_code20     IN      VARCHAR2,         -- 請求書用顧客
    iv_customer_code21     IN      VARCHAR2,         -- 統括請求書用顧客
    iv_customer_code14     IN      VARCHAR2          -- 売掛管理先顧客
-- Modify 2009-09-29 Ver1.10 End
-- Ver1.2 ADD START
   ,iv_company_cd          IN      VARCHAR2          -- 会社コード
-- Ver1.2 ADD END
  );
END XXCFR003A17C;
/
