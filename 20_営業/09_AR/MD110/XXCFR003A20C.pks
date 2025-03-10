CREATE OR REPLACE PACKAGE APPS.XXCFR003A20C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2015. All rights reserved.
 *
 * Package Name     : XXCFR003A20C(spec)
 * Description      : 店舗別明細出力
 * MD.050           : MD050_CFR_003_A20_店舗別明細出力
 * MD.070           : MD050_CFR_003_A20_店舗別明細出力
 * Version          : 1.1
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
 *  2015/07/23    1.0   SCSK 小路 恭弘   新規作成
 *  2023/11/20    1.1   SCSK 大山 洋介   [E_本稼動_19496] グループ会社統合対応
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                 OUT     VARCHAR2          -- エラーメッセージ #固定#
   ,retcode                OUT     VARCHAR2          -- エラーコード     #固定#
   ,iv_report_type         IN      VARCHAR2          -- 帳票区分
   ,iv_bill_type           IN      VARCHAR2          -- 請求書タイプ
   ,in_org_request_id      IN      NUMBER            -- 発行元要求ID
   ,in_target_cnt          IN      NUMBER            -- 対象件数
-- Ver1.1 ADD START
   ,iv_company_cd          IN      VARCHAR2          -- 会社コード
-- Ver1.1 ADD END
  );
END XXCFR003A20C;
/
