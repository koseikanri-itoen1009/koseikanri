CREATE OR REPLACE PACKAGE APPS.XXCOK024A02C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A02C (spec)
 * Description      : 控除マスタCSV出力
 * MD.050           : 控除マスタCSV出力 MD050_COK_024_A02
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
 *  2020/04/23    1.0   Y.Nakajima       main新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                          OUT    VARCHAR2          -- エラーメッセージ #固定#
   ,retcode                         OUT    VARCHAR2          -- エラーコード     #固定#
   ,iv_order_deduction_no           IN     VARCHAR2          -- 控除番号
   ,iv_corp_code                    IN     VARCHAR2          -- 企業コード
   ,iv_introduction_code            IN     VARCHAR2          -- チェーンコード
   ,iv_ship_cust_code               IN     VARCHAR2          -- 顧客コード
   ,iv_data_type                    IN     VARCHAR2          -- データ種類
   ,iv_tax_code                     IN     VARCHAR2          -- 税コード
   ,iv_order_list_date_from         IN     VARCHAR2          -- 出力開始日
   ,iv_order_list_date_to           IN     VARCHAR2          -- 出力終了日
   ,iv_content                      IN     VARCHAR2          -- 内容
   ,iv_decision_no                  IN     VARCHAR2          -- 決裁No
   ,iv_agreement_no                 IN     VARCHAR2          -- 契約番号
   ,iv_last_update_date             IN     VARCHAR2          -- 最終更新日
  );
END XXCOK024A02C;
/
