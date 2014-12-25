CREATE OR REPLACE PACKAGE XXCFR003A05C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR003A05C(spec)
 * Description      : 営業システム構築プロジェクト
 * MD.050           : MD050_FR_003_A05_請求金額一覧表出力
 * MD.070           : MD050_FR_003_A05_請求金額一覧表出力
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
 *  2008/12/17    1.00 SCS 大川 恵      初回作成
 *  2014/10/25    1.1  SCSK 竹下        E_本稼動_12310対応
 *
 *****************************************************************************************/
--
  PROCEDURE main(
    errbuf            OUT    VARCHAR2,         --   エラーメッセージ #固定#
    retcode           OUT    VARCHAR2,         --   エラーコード     #固定#
-- ADD Ver1.1 Start
    iv_output_kbn     IN     VARCHAR2,         --   出力基準
-- ADD Ver1.1 End
    iv_target_date    IN     VARCHAR2,         --   締日
    iv_bill_cust_code IN     VARCHAR2          --   請求先顧客コード
  );
END XXCFR003A05C;
/
